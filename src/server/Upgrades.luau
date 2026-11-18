-- Upgrades: owns the Upgrade Shack prompt. Each press buys the next deck slot at the configured
-- price curve, up to DeckSlotsMax. Exposes DoUpgrade so the same code path runs from tests and
-- Demo as from the key press.

local Config = require(script.Parent.Config)
local World = require(script.Parent.World)
local PlayerState = require(script.Parent.PlayerState)

local Upgrades = {}

local sendAlert -- injected by init
local prompt = nil

local function priceFor(slotsOwned)
	local step = slotsOwned - Config.DeckSlotsStart
	if step < 0 then step = 0 end
	return math.ceil(Config.SlotUpgrade.BasePrice * Config.SlotUpgrade.Growth ^ step)
end

-- One upgrade action: charge the price, add a deck slot. Shared by the prompt handler so tests
-- and Demo drive the same code path the key press uses.
local function doUpgrade(player)
	if not player then return false end
	local s = PlayerState.Get(player)
	if s.deckSlotsOwned >= Config.DeckSlotsMax then
		if sendAlert then sendAlert(player, "warn", "Deck maxed out", "You already own every slot") end
		return false
	end
	local price = priceFor(s.deckSlotsOwned)
	if not PlayerState.SpendCash(s, price) then
		if sendAlert then sendAlert(player, "warn", "Not enough cash", "You need $" .. price .. " for another slot") end
		return false
	end
	s.deckSlotsOwned += 1
	if prompt then
		prompt.ObjectText = "Upgrade Shack - $" .. priceFor(s.deckSlotsOwned)
	end
	if sendAlert then
		sendAlert(player, "good", "Deck slot " .. s.deckSlotsOwned, "One more brainrot fits")
	end
	return true
end

-- Build the upgrade-shack prompt. Call once, after World.Build().
local function setup()
	local counter = World.GetAnchors().UpgradeCounter
	prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UpgradePrompt"
	prompt.ActionText = "Buy Slot"
	prompt.ObjectText = "Upgrade Shack - $" .. priceFor(Config.DeckSlotsStart)
	prompt.KeyboardKeyCode = Enum.KeyCode.U
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter

	prompt.Triggered:Connect(doUpgrade)
end

local function setAlert(fn) sendAlert = fn end
local function getPrice(player) return priceFor(PlayerState.Get(player).deckSlotsOwned) end

Upgrades.SetAlert = setAlert
Upgrades.Setup = setup
Upgrades.GetPrice = getPrice
Upgrades.GetPrompt = function() return prompt end
Upgrades.DoUpgrade = doUpgrade

return Upgrades
