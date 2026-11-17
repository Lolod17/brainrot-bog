-- MudTide: owns the tide cycle. Every interval the swamp rises: a warning, a horn flash, a brown wall
-- of parts sweeping in from the map edge toward the island, then it drains. Anyone on water, the
-- boardwalks or the mud islands when the wall passes them is swallowed.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = require(script.Parent.Config)
local World = require(script.Parent.World)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local PlayerState = require(script.Parent.PlayerState)

local MudTide = {}

local sendAlert -- injected by init
local onSwallowed -- injected by init: client-side shake and flash for one player

local tideState = {
	nextTideAt = 0,
	warning = false,
	sweeping = false,
	wall = nil,
	remaining = 0,
}

-- The wall is built once and parked far out of the way between tides.
local function ensureWall()
	if tideState.wall then return tideState.wall end
	local center = World.GetAnchors().IslandCenter
	local model = Instance.new("Model")
	model.Name = "MudTideWall"
	local T = Config.Tide
	local thickness = T.WallThickness
	for i = -2, 2 do
		local part = Instance.new("Part")
		part.Name = "TideWall"
		part.Anchored = true
		part.CanCollide = false
		part.Size = Vector3.new(thickness, T.WallHeight + i, 520)
		part.Color = Color3.fromRGB(110 - i * 6, 72 - i * 4, 38 - i * 2)
		part.Material = Enum.Material.Mud
		part.Transparency = 0.1 + math.abs(i) * 0.08
		part.Position = center + Vector3.new(-T.StartDistance, T.WallHeight / 2, 0)
		part.Parent = model
	end
	-- Foam on the leading face.
	local foam = Instance.new("Part")
	foam.Name = "TideFoam"
	foam.Anchored = true
	foam.CanCollide = false
	foam.Size = Vector3.new(1, 1.5, 520)
	foam.Color = Color3.fromRGB(190, 150, 100)
	foam.Material = Enum.Material.Neon
	foam.Transparency = 0.2
	foam.Position = center + Vector3.new(-T.StartDistance - thickness / 2, T.WallHeight + 1, 0)
	foam.Parent = model
	local emit = Instance.new("ParticleEmitter")
	emit.Color = ColorSequence.new(Color3.fromRGB(150, 105, 60))
	emit.Size = NumberSequence.new(1.6)
	emit.Lifetime = NumberRange.new(0.6, 1.2)
	emit.Rate = 60
	emit.Speed = NumberRange.new(2, 5)
	emit.SpreadAngle = Vector2.new(40, 40)
	emit.Parent = foam
	model.Parent = workspace
	tideState.wall = model
	return model
end

local function moveWallTo(x)
	local wall = tideState.wall
	if not wall then return end
	local center = World.GetAnchors().IslandCenter
	for _, part in ipairs(wall:GetChildren()) do
		if part:IsA("BasePart") then
			part.Position = Vector3.new(x, part.Position.Y, center.Z)
		end
	end
end

local function parkWall()
	local center = World.GetAnchors().IslandCenter
	moveWallTo(center.X - 600)
end

-- Is this player standing on solid raft deck (safe), or out on water/boardwalk/mud (exposed)?
local function isExposed(player)
	local character = player.Character
	if not character or not character.PrimaryPart then return false end
	local pos = character.PrimaryPart.Position
	for i = 1, 4 do
		local bounds = World.GetAnchors().DeckBounds[i]
		local d = pos - bounds.center
		if math.abs(d.X) <= bounds.half and math.abs(d.Z) <= bounds.half then
			return false
		end
	end
	return true
end

local function swallow(player)
	local s = PlayerState.Get(player)
	local character = player.Character
	local carriedName = s.carried and s.carried.name or nil
	if s.carried then
		local pos = character and character.PrimaryPart and character.PrimaryPart.Position or World.GetAnchors().SpawnPosition
		BrainrotFactory.RemoveModel(s.carried.model)
		PlayerState.SetCarried(s, nil)
	end
	local lost = math.floor(s.cash * Config.Tide.CashLossFraction)
	PlayerState.SpendCash(s, lost)
	if onSwallowed then onSwallowed(player) end
	if sendAlert then
		sendAlert(player, "bad", "The bog swallowed you", "Lost " .. (carriedName or "your catch") .. " and $" .. lost)
	end
end

local function runTide()
	local center = World.GetAnchors().IslandCenter
	local T = Config.Tide
	-- Warning.
	tideState.warning = true
	if sendAlert then
		for _, player in ipairs(Players:GetPlayers()) do
			sendAlert(player, "tide", "MUD TIDE INCOMING", "Get to a raft")
		end
	end
	task.wait(T.Warning)
	-- Sweep.
	tideState.warning = false
	tideState.sweeping = true
	ensureWall()
	local startX = center.X - T.StartDistance
	local endX = center.X - T.EndDistance
	moveWallTo(startX)
	local elapsed = 0
	while elapsed < T.SweepDuration do
		local dt = task.wait(0.05)
		elapsed += dt
		local t = math.clamp(elapsed / T.SweepDuration, 0, 1)
		local eased = t * t * (3 - 2 * t)
		local x = startX + (endX - startX) * eased
		moveWallTo(x)
		-- The wall swallows anyone it passes.
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if character and character.PrimaryPart and isExposed(player) then
				local px = character.PrimaryPart.Position.X
				if px >= x - 4 and px <= x + 4 then
					swallow(player)
				end
			end
		end
	end
	-- Drain: the wall retreats back out quickly.
	tideState.sweeping = false
	local drain = TweenService:Create(tideState.wall:FindFirstChild("TideWall"), TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = Vector3.new(center.X - 600, Config.Tide.WallHeight / 2, center.Z),
	})
	-- Tween the whole model's parts by moving them each.
	task.spawn(function()
		local startX2 = endX
		local targetX = center.X - 600
		for i = 1, 40 do
			local t = i / 40
			moveWallTo(startX2 + (targetX - startX2) * t)
			task.wait(0.05)
		end
		parkWall()
	end)
	if sendAlert then
		for _, player in ipairs(Players:GetPlayers()) do
			sendAlert(player, "info", "The tide drains", "The bog is quiet again")
		end
	end
end

local function startCycle()
	tideState.nextTideAt = os.clock() + Config.Tide.Interval
	tideState.remaining = Config.Tide.Interval
	parkWall()
	task.spawn(function()
		while true do
			local waitTime = tideState.nextTideAt - os.clock()
			if waitTime > 0 then task.wait(math.min(waitTime, 1)) end
			if os.clock() >= tideState.nextTideAt then
				runTide()
				tideState.nextTideAt = os.clock() + Config.Tide.Interval
			end
			tideState.remaining = math.max(0, tideState.nextTideAt - os.clock())
		end
	end)
end

local function getTimeRemaining()
	return tideState.remaining
end

local function isWarning() return tideState.warning end
local function isSweeping() return tideState.sweeping end

local function setAlert(fn) sendAlert = fn end
local function setOnSwallowed(fn) onSwallowed = fn end

-- Force a tide now (used by Demo to reach the tide screenshot).
local function triggerTideNow()
	tideState.nextTideAt = os.clock()
end

MudTide.StartCycle = startCycle
MudTide.GetTimeRemaining = getTimeRemaining
MudTide.IsWarning = isWarning
MudTide.IsSweeping = isSweeping
MudTide.SetAlert = setAlert
MudTide.SetOnSwallowed = setOnSwallowed
MudTide.TriggerTideNow = triggerTideNow

return MudTide