-- init.server: the one place that owns the whole server. It requires every module, builds the world
-- once, opens the Net folder of RemoteEvents the other modules expect, wires the alert sink and the
-- shared money tick, and owns the player lifecycle (join/leave) through PlayerState.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules are required before the world is built: none of them may read anchors at load time.
local Config = require(script.Config)
local Cast = require(script.Cast)
local World = require(script.World)
local BrainrotFactory = require(script.BrainrotFactory)
local PlayerState = require(script.PlayerState)
local Dredge = require(script.Dredge)
local Upgrades = require(script.Upgrades)
local Steal = require(script.Steal)
local MudTide = require(script.MudTide)
local Rebirth = require(script.Rebirth)
local Demo = require(script.Demo)

-- ---------- Net ----------
-- One folder in ReplicatedStorage holding every RemoteEvent the server sends. The client finds them
-- by name here, so nothing is hard-coded twice.
local net = ReplicatedStorage:FindFirstChild("Net")
if not net then
	net = Instance.new("Folder")
	net.Name = "Net"
	net.Parent = ReplicatedStorage
end

local function remote(name)
	local r = net:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = net
	end
	return r
end

local CashTick = remote("CashTick") -- server -> client: (player, cash)
local SyncState = remote("SyncState") -- server -> client: (player, stateTable)
local Alert = remote("Alert") -- server -> client: (player, kind, title, body)
local TideHorn = remote("TideHorn") -- server -> all: (phase) phase = "warning" | "sweep" | "drain"
local Swallowed = remote("Swallowed") -- server -> client: (player)
local BogBaron = remote("BogBaron") -- server -> client: (player)

-- ---------- World ----------
World.Build()

-- The prompt-bearing modules build their prompts from anchors, so they set up after Build.
Dredge.Setup()
Upgrades.Setup()
Rebirth.Setup()

-- The loop that places a carried character on the deck pad when the player walks onto it.
Dredge.WatchPlacement()

-- ---------- Shared alert sink ----------
local function sendAlert(player, kind, title, body)
	if not player then return end
	Alert:FireClient(player, kind, title, body)
end

Dredge.SetAlert(sendAlert)
Steal.SetAlert(sendAlert)
MudTide.SetAlert(sendAlert)
Rebirth.SetAlert(sendAlert)
Rebirth.SetOnBogBaron(function(player)
	BogBaron:FireClient(player)
end)

-- ---------- Character placement ----------
local function onCharacterAdded(player, character)
	local s = PlayerState.Get(player)
	if not s then return end
	character:WaitForChild("Humanoid")
	-- Place them at the island spawn once the character is fully built.
	local root = character:WaitForChild("HumanoidRootPart")
	root.CFrame = CFrame.new(World.GetAnchors().SpawnPosition)
end

local function onPlayerAdded(player)
	local deckIndex = World.ClaimDeck(player)
	if not deckIndex then
		-- No raft free; drop them back at spawn (they can still watch the bog).
		player:Kick("The bog is full - try again soon")
		return
	end
	World.SetDeckOwnerLabel(deckIndex, player.Name .. "'s Raft")
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
	SyncState:FireClient(player, PlayerState.Serialise(PlayerState.Get(player)))
end

local function onPlayerRemoving(player)
	local deckIndex = World.GetDeckIndex(player)
	if deckIndex then
		World.SetDeckOwnerLabel(deckIndex, nil)
	end
	World.FreeDeck(player)
	PlayerState.Clear(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- ---------- Money tick (four times a second) ----------
local function broadcastCash()
	for _, player in ipairs(Players:GetPlayers()) do
		local s = PlayerState.Get(player)
		if s then
			local income = PlayerState.IncomePerSecond(s) * Config.TickRate
			if income > 0 then
				PlayerState.AddCash(s, income)
			end
			CashTick:FireClient(player, math.floor(s.cash))
		end
	end
end

task.spawn(function()
	while true do
		task.wait(Config.TickRate)
		broadcastCash()
	end
end)

-- ---------- Mud Tide cycle ----------
MudTide.SetOnSwallowed(function(player)
	Swallowed:FireClient(player)
end)
-- Every phase change fans out to every client so the banner and horn stay in step.
MudTide.SetOnPhase(function(phase)
	TideHorn:FireAllClients(phase)
end)
MudTide.StartCycle()

-- ---------- Demo presets keep the client in sync ----------
-- Demo only touches server state through the normal loop, so re-serialising a player after a preset
-- is enough to keep their screen honest.
local function syncPlayer(player)
	if not player then return end
	SyncState:FireClient(player, PlayerState.Serialise(PlayerState.Get(player)))
end
Demo.SetSync(syncPlayer)

print("[BRAINROT BOG] server up")
