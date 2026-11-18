-- World: builds the whole BRAINROT BOG swamp out of parts and returns named anchors the rest of the
-- server uses (pedestal, spawn, deck pads, counters, deck slot centres). Everything is anchored.

local Config = require(script.Parent.Config)

local World = {}

local raftNames = { "Cattail", "Reed", "Bogwood", "Sluice" }
local raftBannerColors = {
	Color3.fromRGB(230, 70, 70),
	Color3.fromRGB(70, 120, 230),
	Color3.fromRGB(80, 200, 110),
	Color3.fromRGB(190, 90, 230),
}
local raftCenters = {
	Vector3.new(-125, 2, -125),
	Vector3.new(125, 2, -125),
	Vector3.new(-125, 2, 125),
	Vector3.new(125, 2, 125),
}
local raftHalf = 18 -- half the 36 stud raft
local islandCenter = Vector3.new(0, 1, 0)
local tollIslandCenter = Vector3.new(95, 1, 0)

-- Ownership of the four rafts, kept here so a leaving player can be freed.
local deckOwners = {} -- raftIndex -> Player

local anchors = {
	DeckPadCenters = {},
	DeckOwners = {},
	DeckSlotCenters = {},
	DeckSigns = {},
	DeckBounds = {},
}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.fromRGB(120, 120, 120)
	p.Size = props.Size or Vector3.new(1, 1, 1)
	if props.Shape then
		p.Shape = props.Shape
	end
	p.Transparency = props.Transparency or 0
	p.CastShadow = props.CastShadow ~= false
	if props.CFrame then
		p.CFrame = props.CFrame
	else
		p.Position = props.Position or Vector3.new()
	end
	p.Name = props.Name or "Part"
	if props.Reflectance then p.Reflectance = props.Reflectance end
	p.Parent = props.Parent or workspace
	return p
end

local function cylinder(props)
	props.Shape = Enum.PartType.Cylinder
	return part(props)
end

local function signBoard(props)
	-- A post with a board that carries text on both faces.
	local board = part({
		Name = props.Name,
		Size = props.Size or Vector3.new(8, 3, 0.4),
		Color = props.BoardColor or Color3.fromRGB(90, 60, 35),
		Material = Enum.Material.Wood,
		Position = props.Position,
	})
	local text = Instance.new("SurfaceGui")
	text.Face = Enum.NormalId.Front
	text.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	text.PixelsPerStud = 30
	text.CanvasSize = Vector2.new(100, 100)
	text.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = props.Text
	label.TextColor3 = props.TextColor or Color3.fromRGB(255, 240, 200)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextStrokeTransparency = 0.3
	label.Parent = text
	local back = text:Clone()
	back.Face = Enum.NormalId.Back
	back.Parent = board
	return board
end

local function lantern(position)
	-- A post with a warm glowing lantern head.
	local post = part({
		Name = "LanternPost",
		Size = Vector3.new(0.4, 5, 0.4),
		Color = Color3.fromRGB(70, 50, 35),
		Material = Enum.Material.Wood,
		Position = position + Vector3.new(0, 2.5, 0),
	})
	local head = part({
		Name = "LanternHead",
		Size = Vector3.new(0.9, 1.1, 0.9),
		Color = Color3.fromRGB(255, 190, 90),
		Material = Enum.Material.Neon,
		Position = position + Vector3.new(0, 5.4, 0),
		CanCollide = false,
	})
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 180, 90)
	light.Brightness = 2.5
	light.Range = 16
	light.Parent = head
	return post
end

-- ---------- The water and the floor ----------
local function buildWater()
	part({
		Name = "BogFloor",
		Size = Vector3.new(520, 4, 520),
		Color = Color3.fromRGB(28, 30, 22),
		Material = Enum.Material.Mud,
		Position = Vector3.new(0, -8, 0),
	})
	local water = part({
		Name = "BogWater",
		Size = Vector3.new(520, 2, 520),
		Color = Color3.fromRGB(50, 92, 62),
		Material = Enum.Material.Grass,
		Transparency = 0.25,
		Position = Vector3.new(0, -1, 0),
	})
	-- The water swallows anyone standing on it: a touch sensor on its top.
	return water
end

-- ---------- The central island, pedestal and spawn ----------
local function buildIsland()
	local c = islandCenter
	part({
		Name = "IslandMud",
		Size = Vector3.new(46, 5, 46),
		Color = Color3.fromRGB(96, 70, 44),
		Material = Enum.Material.Mud,
		Position = c + Vector3.new(0, -1.5, 0),
	})
	part({
		Name = "IslandTop",
		Size = Vector3.new(44, 0.6, 44),
		Color = Color3.fromRGB(112, 84, 52),
		Material = Enum.Material.Mud,
		Position = c + Vector3.new(0, 0.6, 0),
	})
	-- A few mud lumps so the edge is not a perfect square.
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		part({
			Name = "IslandLump",
			Size = Vector3.new(10, 3, 10),
			Color = Color3.fromRGB(88, 64, 40),
			Material = Enum.Material.Mud,
			Position = c + Vector3.new(math.cos(a) * 22, 0.2, math.sin(a) * 22),
		})
	end
end

local function buildPedestal()
	local c = islandCenter + Vector3.new(0, 0, -6)
	-- A ring of eight stones around a glowing green core.
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		part({
			Name = "PedestalStone",
			Size = Vector3.new(1.6, 3.2, 1.6),
			Color = Color3.fromRGB(120, 120, 128),
			Material = Enum.Material.Slate,
			Position = c + Vector3.new(math.cos(a) * 4, 1.6, math.sin(a) * 4),
		})
	end
	local base = cylinder({
		Name = "PedestalBase",
		Size = Vector3.new(0.5, 6, 6),
		Color = Color3.fromRGB(100, 100, 108),
		Material = Enum.Material.Slate,
		CFrame = CFrame.new(c + Vector3.new(0, 1.25, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	local core = cylinder({
		Name = "PedestalCore",
		Size = Vector3.new(2.6, 1.8, 1.8),
		Color = Color3.fromRGB(90, 255, 140),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(c + Vector3.new(0, 2.8, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		CanCollide = false,
	})
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(90, 255, 140)
	light.Brightness = 4
	light.Range = 22
	light.Parent = core
	anchors.PedestalCore = core
	anchors.PedestalBase = base
	anchors.PedestalPosition = c + Vector3.new(0, 3.0, 0) -- where a dredged character stands
	return core
end

local function buildSpawn()
	local pos = islandCenter + Vector3.new(0, 1.3, 12)
	local pad = Instance.new("SpawnLocation")
	pad.Anchored = true
	pad.Size = Vector3.new(12, 0.6, 12)
	pad.Color = Color3.fromRGB(70, 130, 90)
	pad.Material = Enum.Material.Grass
	pad.Position = pos
	pad.Name = "SpawnPad"
	pad.Neutral = true
	pad.Duration = 0
	pad.Parent = workspace
	signBoard({
		Name = "BogTitleSign",
		Text = "BRAINROT BOG",
		Size = Vector3.new(14, 3.4, 0.5),
		BoardColor = Color3.fromRGB(50, 40, 30),
		TextColor = Color3.fromRGB(140, 255, 160),
		Position = pos + Vector3.new(0, 6, 1.5),
	})
	-- The smaller line under the title, telling a new player what to do first.
	signBoard({
		Name = "BogHintSign",
		Text = "DREDGE at the green pedestal, TAKE IT HOME, walk it onto your deck",
		Size = Vector3.new(18, 1.6, 0.4),
		BoardColor = Color3.fromRGB(50, 40, 30),
		TextColor = Color3.fromRGB(230, 230, 230),
		Position = pos + Vector3.new(0, 3.4, 1.6),
	})
	anchors.SpawnPoint = pad
	anchors.SpawnPosition = pos + Vector3.new(0, 0.5, 0)
end

-- ---------- The fifth island: Toll Booth and Upgrade Shack ----------
local function buildTollIsland()
	local c = tollIslandCenter
	part({
		Name = "TollIslandMud",
		Size = Vector3.new(36, 5, 34),
		Color = Color3.fromRGB(96, 70, 44),
		Material = Enum.Material.Mud,
		Position = c + Vector3.new(0, -1.5, 0),
	})
	part({
		Name = "TollIslandTop",
		Size = Vector3.new(34, 0.6, 32),
		Color = Color3.fromRGB(108, 80, 50),
		Material = Enum.Material.Mud,
		Position = c + Vector3.new(0, 0.6, 0),
	})

	-- Toll Booth: a wooden hut with a big REBIRTH sign and a counter in front.
	local booth = c + Vector3.new(-9, 0, -6)
	part({ Name = "BoothFloor", Size = Vector3.new(10, 0.4, 8), Color = Color3.fromRGB(96, 66, 40), Material = Enum.Material.Wood, Position = booth + Vector3.new(0, 1, 0) })
	part({ Name = "BoothWallL", Size = Vector3.new(0.5, 7, 8), Color = Color3.fromRGB(120, 84, 50), Material = Enum.Material.Wood, Position = booth + Vector3.new(-5, 4.5, 0) })
	part({ Name = "BoothWallR", Size = Vector3.new(0.5, 7, 8), Color = Color3.fromRGB(120, 84, 50), Material = Enum.Material.Wood, Position = booth + Vector3.new(5, 4.5, 0) })
	part({ Name = "BoothWallB", Size = Vector3.new(10, 7, 0.5), Color = Color3.fromRGB(120, 84, 50), Material = Enum.Material.Wood, Position = booth + Vector3.new(0, 4.5, 4) })
	part({ Name = "BoothRoof", Size = Vector3.new(12, 0.6, 10), Color = Color3.fromRGB(70, 46, 28), Material = Enum.Material.Wood, Position = booth + Vector3.new(0, 8.4, 0) })
	signBoard({ Name = "RebirthSign", Text = "REBIRTH", Size = Vector3.new(10, 3, 0.4), BoardColor = Color3.fromRGB(60, 40, 25), TextColor = Color3.fromRGB(255, 210, 90), Position = booth + Vector3.new(0, 10.5, 0) })
	local tollCounter = part({ Name = "TollBoothCounter", Size = Vector3.new(8, 1.2, 1.5), Color = Color3.fromRGB(150, 110, 66), Material = Enum.Material.Wood, Position = booth + Vector3.new(0, 1.6, -5.4) })

	-- Upgrade Shack: next to the booth.
	local shack = c + Vector3.new(9, 0, -6)
	part({ Name = "ShackFloor", Size = Vector3.new(10, 0.4, 8), Color = Color3.fromRGB(96, 66, 40), Material = Enum.Material.Wood, Position = shack + Vector3.new(0, 1, 0) })
	part({ Name = "ShackWallL", Size = Vector3.new(0.5, 7, 8), Color = Color3.fromRGB(108, 74, 44), Material = Enum.Material.Wood, Position = shack + Vector3.new(-5, 4.5, 0) })
	part({ Name = "ShackWallR", Size = Vector3.new(0.5, 7, 8), Color = Color3.fromRGB(108, 74, 44), Material = Enum.Material.Wood, Position = shack + Vector3.new(5, 4.5, 0) })
	part({ Name = "ShackWallB", Size = Vector3.new(10, 7, 0.5), Color = Color3.fromRGB(108, 74, 44), Material = Enum.Material.Wood, Position = shack + Vector3.new(0, 4.5, 4) })
	part({ Name = "ShackRoof", Size = Vector3.new(12, 0.6, 10), Color = Color3.fromRGB(64, 42, 26), Material = Enum.Material.Wood, Position = shack + Vector3.new(0, 8.4, 0) })
	signBoard({ Name = "UpgradesSign", Text = "UPGRADES", Size = Vector3.new(10, 3, 0.4), BoardColor = Color3.fromRGB(60, 40, 25), TextColor = Color3.fromRGB(120, 255, 200), Position = shack + Vector3.new(0, 10.5, 0) })
	local upCounter = part({ Name = "UpgradeCounter", Size = Vector3.new(8, 1.2, 1.5), Color = Color3.fromRGB(150, 110, 66), Material = Enum.Material.Wood, Position = shack + Vector3.new(0, 1.6, -5.4) })

	anchors.TollBoothCounter = tollCounter
	anchors.UpgradeCounter = upCounter
	anchors.TollBoothPosition = booth + Vector3.new(0, 3, -6.5)
	anchors.UpgradeShackPosition = shack + Vector3.new(0, 3, -6.5)
end

-- ---------- The four raft bases ----------
local function buildRaft(index)
	local center = raftCenters[index]
	local half = raftHalf
	local deckColor = Color3.fromRGB(150, 108, 62)
	-- The plank deck.
	for i = 0, 8 do
		part({
			Name = "RaftDeck",
			Size = Vector3.new(half * 2, 0.6, 3.9),
			Color = i % 2 == 0 and deckColor or Color3.fromRGB(140, 100, 56),
			Material = Enum.Material.WoodPlanks,
			Position = center + Vector3.new(0, 2, -half + 2 + i * 4),
		})
	end
	-- A low rim.
	local rimColor = Color3.fromRGB(96, 66, 38)
	part({ Name = "RaftRim", Size = Vector3.new(half * 2 + 1, 1.2, 1), Color = rimColor, Material = Enum.Material.Wood, Position = center + Vector3.new(0, 2.6, -half) })
	part({ Name = "RaftRim", Size = Vector3.new(half * 2 + 1, 1.2, 1), Color = rimColor, Material = Enum.Material.Wood, Position = center + Vector3.new(0, 2.6, half) })
	part({ Name = "RaftRim", Size = Vector3.new(1, 1.2, half * 2), Color = rimColor, Material = Enum.Material.Wood, Position = center + Vector3.new(-half, 2.6, 0) })
	part({ Name = "RaftRim", Size = Vector3.new(1, 1.2, half * 2), Color = rimColor, Material = Enum.Material.Wood, Position = center + Vector3.new(half, 2.6, 0) })
	-- The painted deck pad under the slot rows. Light warm slate so the middle of a shot reads as
	-- a floor, not a void. It is anchored and collidable: it is the ground the characters stand on.
	-- Top face lands on the deck top (deck planks centre y=2, half thickness 0.3 -> top y=2.3).
	local padCenter = Vector3.new(center.X, 2.2, center.Z + 2.5)
	local padTopY = padCenter.Y + 0.1
	part({
		Name = "DeckPad",
		Size = Vector3.new(32, 0.2, 17),
		Color = Color3.fromRGB(120, 112, 104),
		Material = Enum.Material.Slate,
		Position = padCenter,
	})
	-- The four first-row slot squares glow pale cyan; further rows sit behind them.
	for i = 0, 3 do
		local slotPos = Vector3.new(padCenter.X + (i - 1.5) * 7.2, padTopY + 0.01, padCenter.Z - 4.5)
		part({
			Name = "DeckSlotGlow",
			Size = Vector3.new(3.2, 0.04, 3.2),
			Color = Color3.fromRGB(170, 240, 255),
			Material = Enum.Material.Neon,
			Position = slotPos,
			CanCollide = false,
		})
	end
	-- A crooked little shack with a warm lantern on one corner.
	local shackCorner = center + Vector3.new(half - 5, 0, -half + 5)
	part({ Name = "RaftShackWall", Size = Vector3.new(6, 6, 0.4), Color = Color3.fromRGB(118, 80, 48), Material = Enum.Material.Wood, Position = shackCorner + Vector3.new(0, 5, 3) })
	part({ Name = "RaftShackWall", Size = Vector3.new(6, 6, 0.4), Color = Color3.fromRGB(118, 80, 48), Material = Enum.Material.Wood, Position = shackCorner + Vector3.new(-3, 5, 0), CFrame = CFrame.new(shackCorner + Vector3.new(-3, 5, 0)) * CFrame.Angles(0, math.rad(90), 0) })
	part({ Name = "RaftShackRoof", Size = Vector3.new(7, 0.5, 7), Color = Color3.fromRGB(66, 44, 26), Material = Enum.Material.Wood, CFrame = CFrame.new(shackCorner + Vector3.new(-1.5, 8.3, 1.5)) * CFrame.Angles(math.rad(6), math.rad(8), 0) })
	local lanternPos = shackCorner + Vector3.new(-3, 0, 3)
	lantern(lanternPos)

	-- A coloured banner on a pole so players can tell whose raft is whose.
	local pole = part({ Name = "BannerPole", Size = Vector3.new(0.4, 12, 0.4), Color = Color3.fromRGB(80, 58, 36), Material = Enum.Material.Wood, Position = center + Vector3.new(half - 1, 7, half - 1) })
	local banner = part({ Name = "Banner", Size = Vector3.new(5, 3.4, 0.3), Color = raftBannerColors[index], Material = Enum.Material.Neon, Position = center + Vector3.new(half - 3.2, 10.5, half - 1), CanCollide = false })
	local bannerText = Instance.new("SurfaceGui")
	bannerText.Face = Enum.NormalId.Front
	bannerText.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	bannerText.PixelsPerStud = 30
	bannerText.Parent = banner
	local bt = Instance.new("TextLabel")
	bt.Size = UDim2.fromScale(1, 1)
	bt.BackgroundTransparency = 1
	bt.Text = raftNames[index] .. " RAFT"
	bt.TextColor3 = Color3.fromRGB(255, 255, 255)
	bt.TextScaled = true
	bt.Font = Enum.Font.FredokaOne
	bt.TextStrokeTransparency = 0.2
	bt.Parent = bannerText

	-- A small, muted wooden owner sign at the deck's outer edge toward open water (away from the
	-- island), facing the deck. Muted wood with dark text (not a bright banner) so it never blocks
	-- the characters; it carries the raft's number so the four rafts differ.
	local away = Vector3.new(center.X - islandCenter.X, 0, center.Z - islandCenter.Z).Unit
	local signPos = Vector3.new(center.X, 2.3 + 6, center.Z) + away * 15
	local ownerSign = part({
		Name = "DeckOwnerSign",
		Size = Vector3.new(6, 1.6, 0.3),
		Color = Color3.fromRGB(110, 82, 52),
		Material = Enum.Material.Wood,
		CFrame = CFrame.lookAt(signPos, Vector3.new(center.X, 8.3, center.Z)),
		CanCollide = false,
	})
	local ownerGui = Instance.new("SurfaceGui")
	ownerGui.Name = "OwnerLabel"
	ownerGui.Face = Enum.NormalId.Front
	ownerGui.CanvasSize = Vector2.new(600, 160)
	ownerGui.LightInfluence = 0
	ownerGui.Enabled = false
	ownerGui.Parent = ownerSign
	local backGui = ownerGui:Clone()
	backGui.Name = "OwnerLabelBack"
	backGui.Face = Enum.NormalId.Back
	backGui.Parent = ownerSign
	for _, g in ipairs({ ownerGui, backGui }) do
		local ownerLabel = Instance.new("TextLabel")
		ownerLabel.Size = UDim2.fromScale(1, 1)
		ownerLabel.BackgroundTransparency = 1
		ownerLabel.Text = raftNames[index] .. " " .. index -- the raft's own name+number until claimed
		ownerLabel.TextColor3 = Color3.fromRGB(45, 32, 20)
		ownerLabel.TextScaled = true
		ownerLabel.Font = Enum.Font.FredokaOne
		ownerLabel.TextStrokeTransparency = 1
		ownerLabel.Parent = g
	end
	ownerGui.Enabled = true
	backGui.Enabled = true

	anchors.DeckPadCenters[index] = padCenter
	anchors.DeckBounds[index] = { center = center, half = half, padHalfX = 16, padHalfZ = 8.5, padTopY = padTopY }
	anchors.DeckSigns[index] = ownerSign
	-- The raft's own name is already on the owner sign (set inline above) so the four rafts differ
	-- even before anyone claims one; a claiming player replaces the text through SetDeckOwnerLabel.
	-- Deck slot centres: row one (slots 1-4) at the pad front, row two behind it.
	local slotCenters = {}
	for i = 1, Config.DeckSlotsMax do
		local col = (i - 1) % 4
		local row = math.floor((i - 1) / 4)
		slotCenters[i] = Vector3.new(
			padCenter.X + (col - 1.5) * 7.2,
			padTopY,
			padCenter.Z - 4.5 - row * 7
		)
	end
	anchors.DeckSlotCenters[index] = slotCenters

	-- A raft deck pad touch sensor is not needed: ownership is checked by position.
	return index
end

-- ---------- Boardwalks ----------
local function boardwalk(from, to, width)
	width = width or 4
	local flatFrom = Vector3.new(from.X, 1.2, from.Z)
	local flatTo = Vector3.new(to.X, 1.2, to.Z)
	local delta = flatTo - flatFrom
	local distance = delta.Magnitude
	local steps = math.max(1, math.floor(distance / 4))
	local stepSize = distance / steps
	local yaw = math.atan2(-delta.X, -delta.Z)
	local mid = (flatFrom + flatTo) / 2
	local plankRun = part({
		Name = "Boardwalk",
		Size = Vector3.new(width, 0.5, distance + width),
		Color = Color3.fromRGB(122, 88, 52),
		Material = Enum.Material.WoodPlanks,
		CFrame = CFrame.new(mid) * CFrame.Angles(0, yaw, 0),
	})
	-- Plank lines and posts, plus a lantern every so often.
	for i = 1, steps do
		local t = (i - 0.5) / steps
		local p = flatFrom:Lerp(flatTo, t)
		if i % 2 == 0 then
			part({
				Name = "BoardwalkPlank",
				Size = Vector3.new(width + 0.3, 0.12, 0.25),
				Color = Color3.fromRGB(96, 68, 40),
				Material = Enum.Material.Wood,
				CFrame = CFrame.new(p + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, yaw, 0),
				CanCollide = false,
			})
		end
		if i % 6 == 3 then
			lantern(p + Vector3.new(width / 2 + 0.6, 0, 0))
		end
	end
	return plankRun
end

-- ---------- Scenery ----------
local function cypress(position, height)
	height = height or 14
	local trunk = part({
		Name = "CypressTrunk",
		Size = Vector3.new(1.6, height, 1.6),
		Color = Color3.fromRGB(70, 52, 38),
		Material = Enum.Material.Wood,
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(math.rad(4), 0, math.rad(-3)),
	})
	local leafColor = Color3.fromRGB(58, 96, 58)
	part({ Name = "CypressLeaves", Size = Vector3.new(5, 4, 5), Color = leafColor, Material = Enum.Material.Grass, Position = position + Vector3.new(0, height + 1.5, 0), Shape = Enum.PartType.Ball, CanCollide = false })
	part({ Name = "CypressLeaves", Size = Vector3.new(3.4, 3, 3.4), Color = leafColor, Material = Enum.Material.Grass, Position = position + Vector3.new(0.6, height + 4, -0.3), Shape = Enum.PartType.Ball, CanCollide = false })
	return trunk
end

local function lilyPad(position)
	local pad = cylinder({
		Name = "LilyPad",
		Size = Vector3.new(0.15, 3, 3),
		Color = Color3.fromRGB(90, 200, 120),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
		CanCollide = false,
	})
	local flower = part({
		Name = "LilyFlower",
		Size = Vector3.new(0.6, 0.5, 0.6),
		Color = Color3.fromRGB(240, 180, 220),
		Material = Enum.Material.Neon,
		Position = position + Vector3.new(0, 0.35, 0),
		Shape = Enum.PartType.Ball,
		CanCollide = false,
	})
	return pad, flower
end

local function mushroom(position)
	local stem = part({ Name = "MushroomStem", Size = Vector3.new(0.6, 1.6, 0.6), Color = Color3.fromRGB(225, 215, 195), Material = Enum.Material.SmoothPlastic, Position = position + Vector3.new(0, 0.8, 0) })
	local cap = part({ Name = "MushroomCap", Size = Vector3.new(2, 1, 2), Color = Color3.fromRGB(170, 90, 200), Material = Enum.Material.Neon, Position = position + Vector3.new(0, 2, 0), Shape = Enum.PartType.Ball, CanCollide = false })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(200, 130, 255)
	light.Brightness = 1.2
	light.Range = 9
	light.Parent = cap
	return stem
end

local function fogBank(position, size)
	local bank = part({
		Name = "FogBank",
		Size = size,
		Color = Color3.fromRGB(150, 175, 180),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.7,
		Position = position,
		CanCollide = false,
		CastShadow = false,
	})
	return bank
end

local function buildScenery()
	-- Crooked cypresses ringing the bog.
	local spots = {
		Vector3.new(-40, 0, -60), Vector3.new(48, 0, -52), Vector3.new(-70, 0, 30),
		Vector3.new(66, 0, 44), Vector3.new(-30, 0, 72), Vector3.new(30, 0, -84),
		Vector3.new(-92, 0, -70), Vector3.new(96, 0, 76), Vector3.new(-160, 0, 10),
		Vector3.new(160, 0, -14), Vector3.new(10, 0, 160), Vector3.new(-14, 0, -160),
	}
	for _, s in ipairs(spots) do
		cypress(s + Vector3.new(0, 0, 0), 12 + math.random(0, 8))
	end
	-- Glowing lily pads scattered on the water.
	for i = 1, 26 do
		local a = math.random() * math.pi * 2
		local r = 40 + math.random() * 150
		lilyPad(Vector3.new(math.cos(a) * r, 0.05, math.sin(a) * r))
	end
	-- Mushrooms with a dim point light, on the island edges and near rafts.
	local mush = {
		Vector3.new(-16, 1, 8), Vector3.new(14, 1, 14), Vector3.new(18, 1, -18),
		Vector3.new(-150, 2, -110), Vector3.new(110, 2, -110), Vector3.new(-110, 2, 110), Vector3.new(150, 2, 110),
	}
	for _, m in ipairs(mush) do
		mushroom(m)
	end
	-- Fog banks.
	fogBank(Vector3.new(-170, 6, -170), Vector3.new(90, 16, 40))
	fogBank(Vector3.new(170, 6, 170), Vector3.new(90, 16, 40))
	fogBank(Vector3.new(170, 6, -170), Vector3.new(50, 14, 90))
	fogBank(Vector3.new(-170, 6, 170), Vector3.new(50, 14, 90))
	fogBank(Vector3.new(0, 4, -150), Vector3.new(160, 12, 30))
end

-- ---------- Lighting ----------
local function buildLighting()
	local Lighting = game:GetService("Lighting")
	-- A readable early evening: the sun is low, the world is lit, and the sky is visible.
	Lighting.ClockTime = 16.2
	Lighting.Ambient = Color3.fromRGB(120, 130, 144)
	Lighting.OutdoorAmbient = Color3.fromRGB(134, 146, 160)
	Lighting.Brightness = 4.5
	Lighting.GlobalShadows = true
	Lighting.FogColor = Color3.fromRGB(120, 140, 160)
	Lighting.FogEnd = 500
	Lighting.FogStart = 180
	-- Lighting.Technology is set by the place file; the live DataModel does not permit a
	-- script to rewrite it, so leave it alone here.

	-- A low sun and a default skybox so the horizon reads.
	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.22
	atmo.Offset = 0.3
	atmo.Color = Color3.fromRGB(170, 190, 210)
	atmo.Decay = Color3.fromRGB(110, 130, 155)
	atmo.Glare = 0.12
	atmo.Haze = 0.9
	atmo.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "BogGrade"
	cc.Saturation = 0.18
	cc.Contrast = 0.08
	cc.TintColor = Color3.fromRGB(230, 245, 245)
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "BogBloom"
	bloom.Intensity = 0.6
	bloom.Size = 40
	bloom.Threshold = 0.85
	bloom.Parent = Lighting
end

-- ---------- Ownership ----------
local function claimDeck(player)
	-- First free raft becomes this player's base.
	for i = 1, #raftCenters do
		if deckOwners[i] == nil then
			deckOwners[i] = player
			return i
		end
	end
	return nil
end

local function freeDeck(player)
	for i = 1, #raftCenters do
		if deckOwners[i] == player then
			deckOwners[i] = nil
			return i
		end
	end
	return nil
end

local function getDeckIndex(player)
	for i = 1, #raftCenters do
		if deckOwners[i] == player then return i end
	end
	return nil
end

local function getDeckOwner(index)
	return deckOwners[index]
end

-- Is this player's character standing on their own deck pad (either slot row)?
local function isOnOwnDeck(player, position)
	local index = getDeckIndex(player)
	if not index then return false end
	local bounds = anchors.DeckBounds[index]
	local pad = anchors.DeckPadCenters[index]
	if not bounds or not pad then return false end
	local d = position - pad
	return math.abs(d.X) <= bounds.padHalfX and math.abs(d.Z) <= bounds.padHalfZ and math.abs(d.Y) <= 4
end

local function setDeckOwnerLabel(index, text)
	local sign = anchors.DeckSigns[index]
	if not sign then return end
	local visible = text ~= nil and text ~= ""
	for _, faceName in ipairs({ "OwnerLabel", "OwnerLabelBack" }) do
		local gui = sign:FindFirstChild(faceName)
		if gui then
			local label = gui:FindFirstChildOfClass("TextLabel")
			if label then label.Text = text or "" end
			gui.Enabled = visible
		end
	end
end

-- ---------- Build it all ----------
local function build()
	buildLighting()
	buildWater()
	buildIsland()
	buildPedestal()
	buildSpawn()
	buildTollIsland()
	for i = 1, #raftCenters do
		buildRaft(i)
	end
	-- Boardwalks from the island edge to each raft's island-facing corner.
	local islandHalf = 23
	boardwalk(Vector3.new(-islandHalf, 0, -islandHalf), Vector3.new(-raftHalf, 0, -raftHalf) + raftCenters[1])
	boardwalk(Vector3.new(islandHalf, 0, -islandHalf), Vector3.new(raftHalf, 0, -raftHalf) + raftCenters[2])
	boardwalk(Vector3.new(-islandHalf, 0, islandHalf), Vector3.new(-raftHalf, 0, raftHalf) + raftCenters[3])
	boardwalk(Vector3.new(islandHalf, 0, islandHalf), Vector3.new(raftHalf, 0, raftHalf) + raftCenters[4])
	boardwalk(Vector3.new(islandHalf, 0, 0), Vector3.new(-raftHalf, 0, 0) + tollIslandCenter)
	buildScenery()

	anchors.RaftCenters = raftCenters
	anchors.RaftHalf = raftHalf
	anchors.IslandCenter = islandCenter
	anchors.RaftNames = raftNames
	anchors.RaftBannerColors = raftBannerColors
	return anchors
end

World.Build = build
World.ClaimDeck = claimDeck
World.FreeDeck = freeDeck
World.GetDeckIndex = getDeckIndex
World.GetDeckOwner = getDeckOwner
World.IsOnOwnDeck = isOnOwnDeck
World.SetDeckOwnerLabel = setDeckOwnerLabel
World.GetRaftName = function(index) return raftNames[index] end
World.GetAnchors = function() return anchors end

return World