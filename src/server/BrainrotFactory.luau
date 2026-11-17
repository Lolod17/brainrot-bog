-- BrainrotFactory: turns a Cast entry into a labelled Model, and moves it between the pedestal, a
-- player's head, and a deck slot, through named functions.

local Config = require(script.Parent.Config)
local Cast = require(script.Parent.Cast)

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
			model:PivotTo(base + Vector3.new(0, bob, 0))
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

-- ---------- The label ----------
local RARITY_COLORS = Config.RarityColors

local function rainbowColor(t)
	local hue = (t * 0.25) % 1
	return Color3.fromHSV(hue, 1, 1)
end

local function buildLabel(model, entry)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(300, 130)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.Parent = model.PrimaryPart

	local name = Instance.new("TextLabel")
	name.Name = "NameLabel"
	name.Size = UDim2.new(1, 0, 0.34, 0)
	name.Position = UDim2.new(0, 0, 0, 0)
	name.BackgroundTransparency = 1
	name.Text = entry.Name
	name.TextColor3 = RARITY_COLORS[entry.Rarity]
	name.TextScaled = true
	name.Font = Enum.Font.FredokaOne
	name.TextStrokeTransparency = 0.25
	name.Parent = gui

	local rarity = Instance.new("TextLabel")
	rarity.Name = "RarityLabel"
	rarity.Size = UDim2.new(1, 0, 0.2, 0)
	rarity.Position = UDim2.new(0, 0, 0.34, 0)
	rarity.BackgroundTransparency = 1
	rarity.Text = string.upper(entry.Rarity)
	rarity.TextColor3 = RARITY_COLORS[entry.Rarity]
	rarity.TextScaled = true
	rarity.Font = Enum.Font.SourceSansBold
	rarity.TextStrokeTransparency = 0.3
	rarity.Parent = gui

	local rate = Instance.new("TextLabel")
	rate.Name = "RateLabel"
	rate.Size = UDim2.new(1, 0, 0.24, 0)
	rate.Position = UDim2.new(0, 0, 0.54, 0)
	rate.BackgroundTransparency = 1
	rate.Text = "$" .. entry.Rate .. "/s"
	rate.TextColor3 = Color3.fromRGB(120, 255, 160)
	rate.TextScaled = true
	rate.Font = Enum.Font.SourceSansBold
	rate.TextStrokeTransparency = 0.3
	rate.Parent = gui

	local joke = Instance.new("TextLabel")
	joke.Name = "JokeLabel"
	joke.Size = UDim2.new(1, 0, 0.2, 0)
	joke.Position = UDim2.new(0, 0, 0.78, 0)
	joke.BackgroundTransparency = 1
	joke.Text = entry.Joke
	joke.TextColor3 = Color3.fromRGB(190, 190, 190)
	joke.TextScaled = true
	joke.Font = Enum.Font.SourceSans
	joke.TextStrokeTransparency = 0.4
	joke.Parent = gui

	local lock = Instance.new("Frame")
	lock.Name = "LockIcon"
	lock.Size = UDim2.fromOffset(40, 40)
	lock.Position = UDim2.new(1, -34, 0, 0)
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

	-- Show the gold padlock whenever the Locked attribute flips on.
	model:GetAttributeChangedSignal("Locked"):Connect(function()
		lock.Visible = model:GetAttribute("Locked") == true
	end)

	model:SetAttribute("Rarity", entry.Rarity)
	model:SetAttribute("Rate", entry.Rate)
	model:SetAttribute("Joke", entry.Joke)
	model:SetAttribute("Name", entry.Name)
	model:SetAttribute("Secret", entry.Rarity == "Secret")
	return gui
end

local function updateLabelColor(model, t)
	local entry = { Rarity = model:GetAttribute("Rarity"), Name = model:GetAttribute("Name") }
	local label = model.PrimaryPart and model.PrimaryPart:FindFirstChild("BrainrotLabel")
	if not label then return end
	if entry.Rarity == "Secret" then
		local c = rainbowColor(t)
		local n = label:FindFirstChild("NameLabel")
		local r = label:FindFirstChild("RarityLabel")
		if n then n.TextColor3 = c end
		if r then r.TextColor3 = c end
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
-- Stand a model upright in a slot: anchored, uncarried, slowly bobbing.
local function standInSlot(model, slotPosition)
	stopBobbing(model)
	model:PivotTo(CFrame.new(slotPosition) * CFrame.Angles(0, math.rad(180), 0))
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
		end
	end
	local base = CFrame.new(slotPosition) * CFrame.Angles(0, math.rad(180), 0)
	startBobbing(model, function() return base end)
	model:SetAttribute("Placed", true)
end

-- Weld a model above a player's head, slightly tilted, bobbing while carried.
local function weldToPlayer(model, player)
	stopBobbing(model)
	local character = player.Character
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
BrainrotFactory.WeldToPlayer = weldToPlayer
BrainrotFactory.DropModel = dropModel
BrainrotFactory.RemoveModel = removeModel
BrainrotFactory.SetCollide = setCollide
BrainrotFactory.GetContainer = function() return container end

return BrainrotFactory