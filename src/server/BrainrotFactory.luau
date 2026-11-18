-- BrainrotFactory: turns a Cast entry into a labelled Model, and moves it between the pedestal, a
-- player's head, and a deck slot, through named functions.

local Config = require(script.Parent.Config)
local Cast = require(script.Parent.Cast)
local World = require(script.Parent.World) -- read-only: pedestal top surface for standing

local BrainrotFactory = {}

local Heartbeat = game:GetService("RunService").Heartbeat
local container = workspace:FindFirstChild("Brainrots")
if not container then
	container = Instance.new("Folder")
	container.Name = "Brainrots"
	container.Parent = workspace
end

-- Bob the model up and down. Each active model gets a Heartbeat connection that drives its bob.
local bobbing = {} -- Model -> { connection, phase, base }

local function startBobbing(model, getBaseCFrame)
	local phase = math.random() * math.pi * 2
	local conn
	conn = Heartbeat:Connect(function(dt)
		if not model.PrimaryPart then
			conn:Disconnect()
			bobbing[model] = nil
			return
		end
		phase += dt * 2
		local bob = math.sin(phase) * 0.35
		local base = getBaseCFrame()
		if base then
			model:PivotTo(base + CFrame.new(0, bob, 0))
		end
	end)
	bobbing[model] = { connection = conn, phase = phase, getBaseCFrame = getBaseCFrame }
end

local function stopBobbing(model)
	local entry = bobbing[model]
	if entry then
		entry.connection:Disconnect()
		bobbing[model] = nil
	end
end

local function setCollide(model, canCollide)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = canCollide end
	end
end

-- The name of the physical sign panel (and its border) so bounding-box math can skip them.
local SIGN_PART_NAMES = { BrainrotLabel = true, SignBorder = true }

local function isSignPart(part)
	return SIGN_PART_NAMES[part.Name] == true
end

-- Measure a model's bounding box from its own parts, excluding the sign panel and border, so the
-- sign's size never skews where the body sits or where the sign is hung. Returns min/max Vector3.
local function measureModel(model)
	local min = nil
	local max = nil
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and not isSignPart(p) then
			local pos = p.Position
			local half = p.Size / 2
			local lo = pos - half
			local hi = pos + half
			if not min then
				min, max = lo, hi
			else
				min = Vector3.new(math.min(min.X, lo.X), math.min(min.Y, lo.Y), math.min(min.Z, lo.Z))
				max = Vector3.new(math.max(max.X, hi.X), math.max(max.Y, hi.Y), math.max(max.Z, hi.Z))
			end
		end
	end
	return min, max
end

local function modelTop(model)
	local _, max = measureModel(model)
	return max and max.Y or nil
end

-- ---------- The label ----------
local RARITY_COLORS = Config.RarityColors

local function rainbowColor(t)
	local hue = (t * 0.25) % 1
	return Color3.fromHSV(hue, 1, 1)
end

-- The label is a physical sign (a BillboardGui is not captured by CaptureService, but a
-- SurfaceGui on a part is). The sign is welded above the character and carries two SurfaceGuis,
-- Front and Back, so a player reads it from either side. Every model is scaled up after build so
-- the sign (welded at the pre-scale offset) rides up with it.
local SIGN_SIZE = Vector3.new(7, 3.4, 0.2)
local SIGN_CANVAS = Vector2.new(900, 440)
local SIGN_LIFT = 8.4 -- studs above the torso centre: the sign's bottom clears the head by ~2
local MODEL_SCALE = 1.4 -- every character model is scaled to this multiple of its built size

local function buildLabelFace(gui, entry)
	gui.CanvasSize = SIGN_CANVAS
	gui.LightInfluence = 0
	gui.Brightness = 1.5
	gui.AlwaysOnTop = false

	-- A solid dark plate filling the canvas so the words always sit on black, never on the world
	-- showing through, and so the panel reads as self-lit at night (with LightInfluence 0 above).
	local plate = Instance.new("Frame")
	plate.Name = "BackgroundPlate"
	plate.Size = UDim2.fromScale(1, 1)
	plate.Position = UDim2.fromScale(0, 0)
	plate.BackgroundColor3 = Color3.fromRGB(18, 17, 20)
	plate.BackgroundTransparency = 0
	plate.BorderSizePixel = 0
	plate.Parent = gui

	local NAME_H = 140
	local ROW_H = 70
	local SPACING = 85 -- even distance between row centres: 220, 305, 390
	local PADDING = 20

	local function makeText(name, text, color, font, textSize)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = color
		-- TextScaled does not survive on the labels this engine build creates, so size each row
		-- with an explicit TextSize instead.
		label.TextScaled = false
		label.TextSize = textSize
		label.Font = font
		label.TextStrokeTransparency = 1
		label.TextWrapped = false
		label.TextXAlignment = Enum.TextXAlignment.Center
		return label
	end

	-- Three rows only: name, rarity, rate. (The joke stays on the model as an attribute.)
	-- The name sits in the vertical middle of the canvas; rarity and rate sit under it with even
	-- spacing. Every row spans the full canvas width less a little padding on each side.
	local name = makeText("NameLabel", entry.Name, Color3.fromRGB(255, 255, 255), Enum.Font.FredokaOne, 104)
	name.Size = UDim2.new(1, -PADDING * 2, 0, NAME_H)
	name.Position = UDim2.new(0, PADDING, 0.5, -NAME_H / 2)
	name.Parent = gui

	local rarity = makeText("RarityLabel", string.upper(entry.Rarity), RARITY_COLORS[entry.Rarity], Enum.Font.SourceSansBold, 68)
	rarity.Size = UDim2.new(1, -PADDING * 2, 0, ROW_H)
	rarity.Position = UDim2.new(0, PADDING, 0.5, SPACING - ROW_H / 2)
	rarity.Parent = gui

	local rate = makeText("RateLabel", "$" .. entry.Rate .. "/s", Color3.fromRGB(120, 255, 160), Enum.Font.SourceSansBold, 68)
	rate.Size = UDim2.new(1, -PADDING * 2, 0, ROW_H)
	rate.Position = UDim2.new(0, PADDING, 0.5, SPACING * 2 - ROW_H / 2)
	rate.Parent = gui

	-- The "LOCKED" strip across the very top of the canvas, visible only while locked.
	local lock = Instance.new("Frame")
	lock.Name = "LockIcon"
	lock.Size = UDim2.fromOffset(280, 44)
	lock.Position = UDim2.new(0.5, -140, 0, 0)
	lock.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
	lock.BackgroundTransparency = 0.1
	lock.Visible = false
	lock.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = lock
	local lockText = Instance.new("TextLabel")
	lockText.Name = "LockText"
	lockText.Size = UDim2.fromScale(1, 1)
	lockText.BackgroundTransparency = 1
	lockText.Text = "LOCKED"
	lockText.TextScaled = true
	lockText.TextColor3 = Color3.fromRGB(60, 40, 0)
	lockText.Font = Enum.Font.SourceSansBold
	lockText.Parent = lock

	return gui
end

local function buildLabel(model, entry)
	local torso = model.PrimaryPart
	if not torso then return nil end

	local sign = Instance.new("Part")
	sign.Name = "BrainrotLabel"
	sign.Size = SIGN_SIZE
	sign.Color = Color3.fromRGB(38, 36, 42) -- dark charcoal panel
	sign.Material = Enum.Material.SmoothPlastic
	sign.Transparency = 0
	sign.CanCollide = false
	sign.Anchored = true
	sign.CFrame = torso.CFrame * CFrame.new(0, SIGN_LIFT, 0)
	sign.Parent = model

	-- A thin rarity-coloured border strip along the top edge of the panel.
	local border = Instance.new("Part")
	border.Name = "SignBorder"
	border.Size = Vector3.new(SIGN_SIZE.X + 0.1, 0.18, SIGN_SIZE.Z + 0.06)
	border.Color = RARITY_COLORS[entry.Rarity]
	border.Material = Enum.Material.Neon
	border.CanCollide = false
	border.Anchored = true
	border.CFrame = sign.CFrame * CFrame.new(0, SIGN_SIZE.Y / 2 + 0.09, 0)
	border.Parent = model

	-- A slight glow so the panel reads in the evening.
	local glow = Instance.new("PointLight")
	glow.Name = "SignGlow"
	glow.Color = RARITY_COLORS[entry.Rarity]
	glow.Range = 7
	glow.Brightness = 1.2
	glow.Parent = sign

	local front = Instance.new("SurfaceGui")
	front.Name = "BrainrotLabelFront"
	front.Face = Enum.NormalId.Front
	front.Parent = sign
	buildLabelFace(front, entry)

	local back = Instance.new("SurfaceGui")
	back.Name = "BrainrotLabelBack"
	back.Face = Enum.NormalId.Back
	back.Parent = sign
	buildLabelFace(back, entry)

	-- Weld the sign to the torso so it moves with the model when carried.
	local weld = Instance.new("Weld")
	weld.Name = "SignWeld"
	weld.Part0 = torso
	weld.Part1 = sign
	weld.C0 = CFrame.new(0, SIGN_LIFT, 0)
	weld.Parent = torso
	sign.Anchored = false
	-- The border strip rides on the sign through its own weld (the sign itself is unanchored).
	local borderWeld = Instance.new("Weld")
	borderWeld.Name = "SignBorderWeld"
	borderWeld.Part0 = sign
	borderWeld.Part1 = border
	borderWeld.C0 = CFrame.new(0, SIGN_SIZE.Y / 2 + 0.09, 0)
	borderWeld.Parent = sign
	border.Anchored = false

	-- Show the gold strip whenever the Locked attribute flips on.
	local function applyLock(visible)
		local frontLock = front:FindFirstChild("LockIcon")
		local backLock = back:FindFirstChild("LockIcon")
		if frontLock then frontLock.Visible = visible end
		if backLock then backLock.Visible = visible end
	end
	applyLock(model:GetAttribute("Locked") == true)
	model:GetAttributeChangedSignal("Locked"):Connect(function()
		applyLock(model:GetAttribute("Locked") == true)
	end)

	model:SetAttribute("Rarity", entry.Rarity)
	model:SetAttribute("Rate", entry.Rate)
	model:SetAttribute("Joke", entry.Joke)
	model:SetAttribute("Name", entry.Name)
	model:SetAttribute("Secret", entry.Rarity == "Secret")
	return sign
end

-- Hang the sign so its bottom clears the model's highest body part by SIGN_CLEARANCE, measured
-- from the body alone (the sign's own box is excluded by measureModel). Keeps the torso's X, Z and
-- rotation and only lifts along the torso's up axis; the weld is retargeted so the sign still rides
-- with the model when carried.
local SIGN_CLEARANCE = 1.2

local function rehangLabel(model)
	local sign = model:FindFirstChild("BrainrotLabel")
	local torso = model.PrimaryPart
	if not sign or not torso then return end
	local top = modelTop(model)
	if not top then return end
	local weld = torso:FindFirstChild("SignWeld")
	if not weld then return end
	local desiredCentreY = top + SIGN_CLEARANCE + SIGN_SIZE.Y / 2
	-- How far along the torso's up axis the sign centre currently sits.
	local currentLift = (torso.CFrame:ToObjectSpace(sign.CFrame)).Position.Y
	local newLift = currentLift + (desiredCentreY - sign.Position.Y)
	sign.CFrame = torso.CFrame * CFrame.new(0, newLift, 0)
	weld.C0 = CFrame.new(0, newLift, 0)
end

local function updateLabelColor(model, t)
	local entry = { Rarity = model:GetAttribute("Rarity"), Name = model:GetAttribute("Name") }
	local sign = model:FindFirstChild("BrainrotLabel")
	if not sign then return end
	if entry.Rarity == "Secret" then
		local c = rainbowColor(t)
		for _, faceName in ipairs({ "BrainrotLabelFront", "BrainrotLabelBack" }) do
			local gui = sign:FindFirstChild(faceName)
			if gui then
				local n = gui:FindFirstChild("NameLabel")
				local r = gui:FindFirstChild("RarityLabel")
				if n then n.TextColor3 = c end
				if r then r.TextColor3 = c end
			end
		end
		local glow = sign:FindFirstChild("SignGlow")
		if glow then glow.Color = c end
	end
end

local function addParticles(model, entry)
	local color = RARITY_COLORS[entry.Rarity]
	local emit = Instance.new("ParticleEmitter")
	emit.Name = "SpawnBurst"
	emit.Color = ColorSequence.new(color)
	emit.Size = NumberSequence.new(0.6)
	emit.Lifetime = NumberRange.new(0.5, 1.0)
	emit.Rate = 6
	emit.Speed = NumberRange.new(1, 2)
	emit.SpreadAngle = Vector2.new(180, 180)
	emit.Parent = model.PrimaryPart
	-- A small one-time burst then a slow idle sparkle.
	emit:Emit(25)
	return emit
end

local function addRainbowTrail(model)
	local a = Instance.new("Attachment")
	a.Name = "TrailA"
	a.Position = Vector3.new(0, 0.5, 0)
	a.Parent = model.PrimaryPart
	local b = Instance.new("Attachment")
	b.Name = "TrailB"
	b.Position = Vector3.new(0, -0.5, 0)
	b.Parent = model.PrimaryPart
	local trail = Instance.new("Trail")
	trail.Name = "RainbowTrail"
	trail.Attachment0 = a
	trail.Attachment1 = b
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 255, 120)),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 120, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 255)),
	})
	trail.Lifetime = 0.6
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Parent = model.PrimaryPart
	return trail
end

-- ---------- Build the model ----------
-- Create the model standing at a position, fully built and labelled.
local function createBrainrot(entry, position, ownerUserId)
	local model = Instance.new("Model")
	model.Name = entry.Name

	local primary = nil
	for i, recipe in ipairs(entry.Parts) do
		local p = Instance.new("Part")
		p.Name = recipe.Name
		p.Size = recipe.Size
		p.Color = recipe.Color
		p.Material = recipe.Material
		p.Transparency = recipe.Transparency
		p.CanCollide = false
		p.Anchored = true
		p.CFrame = CFrame.new(position + recipe.Offset)
		if recipe.Shape == "Ball" then
			p.Shape = Enum.PartType.Ball
		elseif recipe.Shape == "Cylinder" then
			p.Shape = Enum.PartType.Cylinder
		elseif recipe.Shape == "Wedge" then
			p.Shape = Enum.PartType.Wedge
		end
		if recipe.Name == "Torso" or i == 1 then
			primary = primary or p
		end
		p.Parent = model
	end
	-- Promote the part named Torso to primary; fall back to the first part.
	local torso = model:FindFirstChild("Torso")
	model.PrimaryPart = torso or primary

	-- Weld every part to the primary so the model can move as one when carried.
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p ~= model.PrimaryPart then
			local weld = Instance.new("Weld")
			weld.Part0 = model.PrimaryPart
			weld.Part1 = p
			weld.C0 = CFrame.new(p.Position - model.PrimaryPart.Position)
			weld.Parent = model.PrimaryPart
		end
	end

	-- Scale the whole model up so a character reads at a distance (built size ~3 studs is too small).
	model:ScaleTo(MODEL_SCALE)

	buildLabel(model, entry)
	addParticles(model, entry)
	if entry.Rarity == "Secret" then
		addRainbowTrail(model)
	end
	model:SetAttribute("OwnerUserId", ownerUserId or 0)
	model.Parent = container
	updateLabelColor(model, os.clock())
	return model
end

-- ---------- Placement helpers ----------
-- Stand a model upright on a surface whose top is at surfaceTopY, centred at (x, z): anchored,
-- uncarried, slowly bobbing. surfaceTopY comes from the deck pad or the pedestal, so the same
-- resting math serves both.
local function standOnSurface(model, position, surfaceTopY)
	stopBobbing(model)
	local yaw = CFrame.Angles(0, math.rad(180), 0)
	local anchor = CFrame.new(position.X, surfaceTopY, position.Z) * yaw
	model:PivotTo(anchor)
	-- Rest the body on the surface: measure from the model's own parts (never the sign), then lift
	-- so the lowest body point sits on the surface plus a small clearance. The sign, hung above the
	-- body, is re-hung to match.
	local min, _ = measureModel(model)
	local offsetY = 0
	if min then
		offsetY = (surfaceTopY + 0.01) - min.Y
		if offsetY ~= 0 then
			model:PivotTo(CFrame.new(position.X, surfaceTopY + offsetY, position.Z) * yaw)
		end
	end
	rehangLabel(model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
		end
	end
	local base = CFrame.new(position.X, surfaceTopY + offsetY, position.Z) * yaw
	startBobbing(model, function() return base end)
	model:SetAttribute("Placed", true)
	return offsetY
end

-- Stand a model in a deck slot, resting on the pad's top surface (the slot centre's Y).
local function standInSlot(model, slotPosition)
	return standOnSurface(model, slotPosition, slotPosition.Y)
end

-- Stand a model on the dredge pedestal, resting on the pedestal's top surface. The pedestal is
-- built from a flat-topped cylinder; read its top Y from the anchor part so the body never sinks in.
local function standOnPedestal(model, pedestalPosition)
	local core = World.GetAnchors().PedestalCore
	local topY = pedestalPosition.Y
	if core and core:IsA("BasePart") then
		-- A cylinder rotated onto its side: the top face is the max world Y across its corners.
		local half = core.Size / 2
		local max = nil
		for i = 0, 7 do
			local sx = (i % 2 == 0) and half.X or -half.X
			local sy = (math.floor(i / 2) % 2 == 0) and half.Y or -half.Y
			local sz = (math.floor(i / 4) % 2 == 0) and half.Z or -half.Z
			local wy = core.CFrame:PointToWorldSpace(Vector3.new(sx, sy, sz)).Y
			if not max or wy > max then max = wy end
		end
		topY = max
	end
	return standOnSurface(model, pedestalPosition, topY)
end

-- Weld a model above a player's head, slightly tilted, bobbing while carried.
local function weldToPlayer(model, player)
	stopBobbing(model)
	if not model.PrimaryPart then return false end
	local character = player and player.Character
	if not character then return false end
	local head = character:FindFirstChild("Head") or character.PrimaryPart
	if not head then return false end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
		end
	end
	-- A carriage weld from the head to the primary, offset above and tilted.
	local existing = model.PrimaryPart:FindFirstChild("CarryWeld")
	if existing then existing:Destroy() end
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = head
	weld.Part1 = model.PrimaryPart
	weld.C0 = CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(8))
	weld.C1 = CFrame.new(0, -1.2, 0)
	weld.Parent = model.PrimaryPart
	model:PivotTo(head.CFrame * CFrame.new(0, 2.5, 0))
	model:SetAttribute("Placed", false)
	model:SetAttribute("CarriedBy", player.UserId)
	-- Bob by nudging the carry weld's C0.
	local phase = math.random() * math.pi * 2
	local conn
	conn = Heartbeat:Connect(function(dt)
		if not model.PrimaryPart or not model.PrimaryPart:FindFirstChild("CarryWeld") then
			conn:Disconnect()
			bobbing[model] = nil -- clear so a dropped model does not leak a dead entry
			return
		end
		phase += dt * 2.5
		weld.C0 = CFrame.new(0, 1.6 + math.sin(phase) * 0.3, 0) * CFrame.Angles(0, 0, math.rad(8))
		updateLabelColor(model, os.clock())
	end)
	bobbing[model] = { connection = conn }
	return true
end

-- Drop a carried model onto the ground where the player stands (used when a tide swallows them).
local function dropModel(model, position)
	stopBobbing(model)
	local carry = model.PrimaryPart and model.PrimaryPart:FindFirstChild("CarryWeld")
	if carry then carry:Destroy() end
	model:SetAttribute("CarriedBy", nil)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
		end
	end
	model:PivotTo(CFrame.new(position + Vector3.new(0, 0.5, 0)))
end

local function removeModel(model)
	if not model then return end
	stopBobbing(model)
	model:Destroy()
end

BrainrotFactory.CreateBrainrot = createBrainrot
BrainrotFactory.StandInSlot = standInSlot
BrainrotFactory.StandOnPedestal = standOnPedestal
BrainrotFactory.WeldToPlayer = weldToPlayer
BrainrotFactory.DropModel = dropModel
BrainrotFactory.RemoveModel = removeModel
BrainrotFactory.SetCollide = setCollide
BrainrotFactory.GetContainer = function() return container end

return BrainrotFactory