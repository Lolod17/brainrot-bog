-- init.client: the entry point. It waits for the server's Net folder, builds the HUD and the effects,
-- and subscribes to every remote. The server is the only source of truth; this script keeps no copy
-- of the state of its own - whatever the server last sent is what gets rendered.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Hide Roblox's own chat and player list at startup so they never sit over the game's interface.
local StarterGui = game:GetService("StarterGui")
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local Hud = require(script.Hud)
local Fx = require(script.Fx)

-- ---------- Find the remotes the server opens in ReplicatedStorage.Net ----------
local net = ReplicatedStorage:WaitForChild("Net")

local function remote(name)
	return net:WaitForChild(name)
end

local CashTick = remote("CashTick") -- (player, cash)
local SyncState = remote("SyncState") -- (player, stateTable)
local Alert = remote("Alert") -- (player, kind, title, body)
local TideHorn = remote("TideHorn") -- (phase)
local Swallowed = remote("Swallowed") -- (player)
local BogBaron = remote("BogBaron") -- (player)

-- ---------- Build the interface and the effects ----------
local hud = Hud.build(player)
local fx = Fx.build()

-- The rarity colour the next burst should use, taken only from what the server has already sent.
-- Nothing here is a guess: if the server has not told us a character's rarity yet, the burst is gold.
local lastRarity = nil

-- The position a burst is drawn at: the player's own character, which is where every one of these
-- events physically happens for this client (the pedestal, the victim's raft, or the thief).
local function burstHere(rarity)
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	fx.burst(root.Position + Vector3.new(0, 2, 0), rarity)
end

-- ---------- State ----------
-- SyncState is the truth. CashTick is a lighter intermediate push of just the cash figure; it updates
-- the money label between full syncs without the client ever owning the number.
local function onCashTick(cash)
	if type(cash) ~= "number" then return end
	hud.updateCash(cash)
end

local function onSyncState(state)
	if type(state) ~= "table" then return end
	-- Prime the burst colour from the newest character the server has told us about.
	if state.carried and state.carried.rarity then
		lastRarity = state.carried.rarity
	elseif state.placed and #state.placed > 0 then
		lastRarity = state.placed[#state.placed].rarity
	end
	Hud.update(hud, state)
end

local function onAlert(kind, title, body)
	if type(kind) ~= "string" or type(title) ~= "string" then return end
	hud.showAlert(kind, title, body)
	-- A dredge, a place (taking what you carry to a slot) or a steal surfaces a character; pop a
	-- burst in the rarity colour we last heard about from the server.
	if kind == "good" and (title == "Dredged!" or string.sub(title, 1, 6) == "Stole " or string.sub(title, 1, 6) == "Placed") then
		burstHere(lastRarity)
	end
end

-- TideHorn carries the phase name; the HUD banner and the countdown both follow it.
local function onTideHorn(phase)
	if type(phase) ~= "string" then return end
	hud.setTide(phase)
end

local function onSwallowed()
	fx.swallow()
end

local function onBogBaron()
	hud.showBogBaron()
end

CashTick.OnClientEvent:Connect(onCashTick)
SyncState.OnClientEvent:Connect(onSyncState)
Alert.OnClientEvent:Connect(onAlert)
TideHorn.OnClientEvent:Connect(onTideHorn)
Swallowed.OnClientEvent:Connect(onSwallowed)
BogBaron.OnClientEvent:Connect(onBogBaron)

-- ---------- Handshake ----------
-- The server sends SyncState on join (see init.server.luau onPlayerAdded). The subscription above
-- already receives it: lastRarity is primed and the HUD is drawn. Nothing else to do.

print("[BRAINROT BOG] client up")
