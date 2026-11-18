-- Rebirth: owns the Toll Booth. The prompt reads the price and what it gives; taking it resets the
-- life and adds a permanent earnings multiplier. At six rebirths the Bog Baron panel fires.

local Players = game:GetService("Players")

local Config = require(script.Parent.Config)
local World = require(script.Parent.World)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local PlayerState = require(script.Parent.PlayerState)

local Rebirth = {}

local sendAlert -- injected by init
local onBogBaron -- injected by init: tells the client to show the Bog Baron panel

local prompt = nil
local tollCounter = nil

local function describeReward()
	return "+" .. math.floor(Config.Rebirth.Multiplier * 100) .. "% earnings forever, reset to $" .. Config.Rebirth.ResetCash
end-- One rebirth action: reset the life, add a permanent multiplier, fire the Bog Baron at threshold.
-- Exposed so the loop can be driven with the same code path the key press uses.
local function doRebirth(player)
	if not player then return end
	local s = PlayerState.Get(player)
	if s.totalEarned < Config.Rebirth.Threshold then
		if sendAlert then sendAlert(player, "warn", "Not yet", "Earn $" .. Config.Rebirth.Threshold .. " this life first") end
		return false
	end
	-- Reset in place: clear the deck, drop the carried one, reset cash and dredge price.
	for _, entry in ipairs(PlayerState.GetPlaced(s)) do
		BrainrotFactory.RemoveModel(entry.model)
	end
	table.clear(s.placed)
	if s.carried then
		BrainrotFactory.RemoveModel(s.carried.model)
		PlayerState.SetCarried(s, nil)
	end
	s.cash = Config.Rebirth.ResetCash
	s.totalEarned = 0
	s.dredgeCount = 0
	s.deckSlotsOwned = Config.DeckSlotsStart
	s.rebirths += 1
	World.SetDeckOwnerLabel(World.GetDeckIndex(player), player.Name .. "'s Raft")
	if sendAlert then
		sendAlert(player, "good", "Rebirth " .. s.rebirths, describeReward())
	end
	if s.rebirths >= Config.BogBaronRebirths and onBogBaron then
		onBogBaron(player)
	end
	return true
end

-- Build the toll booth prompt. Call once, after World.Build().
local function setup()
	tollCounter = World.GetAnchors().TollBoothCounter
	prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RebirthPrompt"
	prompt.ActionText = "Rebirth"
	prompt.ObjectText = "Toll Booth"
	prompt.KeyboardKeyCode = Enum.KeyCode.R
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = tollCounter

	prompt.Triggered:Connect(doRebirth)
end

local function totalEarned(player)
	return PlayerState.Get(player).totalEarned
end

local function updatePrompt(player)
	if not prompt then return end
	local s = PlayerState.Get(player)
	local earned = s.totalEarned
	local ready = earned >= Config.Rebirth.Threshold
	prompt.ObjectText = ready and ("REBIRTH - " .. describeReward()) or ("Rebirth at $" .. Config.Rebirth.Threshold .. " earned (" .. math.floor(earned) .. ")")
end

local function setAlert(fn) sendAlert = fn end
local function setOnBogBaron(fn) onBogBaron = fn end

Rebirth.SetAlert = setAlert
Rebirth.Setup = setup
Rebirth.SetOnBogBaron = setOnBogBaron
Rebirth.UpdatePrompt = updatePrompt
Rebirth.GetPrompt = function() return prompt end
Rebirth.DescribeReward = describeReward
Rebirth.DoRebirth = doRebirth

return Rebirth