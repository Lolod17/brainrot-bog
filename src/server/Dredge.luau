-- Dredge: owns the pedestal prompt, the price curve, spawning a rolled character on it, and taking
-- it home. A second loop watches for a player walking onto their own deck pad while carrying.

local Players = game:GetService("Players")

local Config = require(script.Parent.Config)
local Cast = require(script.Parent.Cast)
local World = require(script.Parent.World)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local PlayerState = require(script.Parent.PlayerState)
local Steal = require(script.Parent.Steal)

local Dredge = {}

-- Anchors are read lazily: this module can be required before World.Build() has run.
local prompt = nil
local pedCore = nil
local pedestalPos = nil

local state = {
	standing = nil, -- the model sitting on the pedestal waiting to be taken
	standingEntry = nil, -- the Cast entry for the standing model (needed by the take action)
}

local function priceFor(dredgeCount)
	return math.ceil(Config.Dredge.BasePrice * Config.Dredge.Growth ^ dredgeCount)
end

local function setPromptPrice(player)
	local s = PlayerState.Get(player)
	local price = priceFor(s.dredgeCount)
	prompt.ObjectText = "Dredge - $" .. price
end

local sendAlert -- injected by init

local spawnOnPedestal -- forward-declared: setup's prompt handler calls it

-- One dredge action: charge the price, roll and stand a character on the pedestal. Exposed so
-- the loop can be driven from outside the prompt handler (tests, Demo) with the same code path
-- the key press uses.
local function doDredge(player)
	if not player then return end
	local s = PlayerState.Get(player)
	local price = priceFor(s.dredgeCount)
	if not PlayerState.SpendCash(s, price) then
		if sendAlert then sendAlert(player, "warn", "Not enough cash", "You need $" .. price .. " to dredge") end
		return
	end
	s.dredgeCount += 1
	setPromptPrice(player)
	spawnOnPedestal()
	if sendAlert then sendAlert(player, "info", "Dredged!", "Something surfaced on the pedestal") end
end

-- Build the pedestal prompt. Call once, after World.Build().
local function setup()
	local anchors = World.GetAnchors()
	pedCore = anchors.PedestalCore
	pedestalPos = anchors.PedestalPosition

	prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DredgePrompt"
	prompt.ActionText = "Dredge"
	prompt.ObjectText = "Dredge Pedestal"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = pedCore

	prompt.Triggered:Connect(doDredge)
end

local function setStanding(model, entry)
	if state.standing then
		BrainrotFactory.RemoveModel(state.standing)
	end
	state.standing = model
	state.standingEntry = entry
end

-- One take-home action: lifts the model off the pedestal and welds it above the player's head.
-- Shared by the prompt handler so tests can drive the same code path the key press uses.
local function doTake(model, entry, player)
	if not player then return false end
	if state.standing ~= model then return false end
	if not player.Character then return false end
	local s = PlayerState.Get(player)
	if s.carried then
		if sendAlert then sendAlert(player, "warn", "Hands full", "Drop what you carry first") end
		return false
	end
	state.standing = nil
	state.standingEntry = nil
	local existingTakePrompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("TakePrompt")
	if existingTakePrompt then
		existingTakePrompt:Destroy()
	end
	PlayerState.SetCarried(s, {
		model = model,
		name = entry.Name,
		rarity = entry.Rarity,
		rate = entry.Rate,
		joke = entry.Joke,
	})
	BrainrotFactory.WeldToPlayer(model, player)
	return true
end

-- Spawn a rolled character standing on the pedestal for anyone to take.
spawnOnPedestal = function()
	local entry = Cast.RollCharacter()
	local model = BrainrotFactory.CreateBrainrot(entry, pedestalPos, 0)
	BrainrotFactory.StandOnPedestal(model, pedestalPos)
	setStanding(model, entry)

	-- A take prompt on the character itself.
	local takePrompt = Instance.new("ProximityPrompt")
	takePrompt.Name = "TakePrompt"
	takePrompt.ActionText = "Take it home"
	takePrompt.ObjectText = entry.Name .. " (" .. entry.Rarity .. ")"
	takePrompt.KeyboardKeyCode = Enum.KeyCode.E
	takePrompt.HoldDuration = 0
	takePrompt.MaxActivationDistance = 8
	takePrompt.RequiresLineOfSight = false
	takePrompt.Parent = model.PrimaryPart

	takePrompt.Triggered:Connect(function(player)
		doTake(model, entry, player)
	end)
	return model, entry
end

-- Watch for a player walking onto their own deck pad while carrying; place in the first free slot.
local function watchPlacement()
	task.spawn(function()
		while true do
			task.wait(Config.TickRate)
			for _, player in ipairs(Players:GetPlayers()) do
				local s = PlayerState.Get(player)
				if s.carried and player.Character and player.Character.PrimaryPart then
					local pos = player.Character.PrimaryPart.Position
					if World.IsOnOwnDeck(player, pos) then
						local entry = PlayerState.PlaceCarried(s)
					if entry then
						local deckIndex = World.GetDeckIndex(player)
						if not deckIndex then return end -- cannot place without a deck
						local slotPos = World.GetAnchors().DeckSlotCenters[deckIndex][entry.slot]
						BrainrotFactory.StandInSlot(entry.model, slotPos)
						entry.model:SetAttribute("OwnerUserId", player.UserId)
						Steal.AttachStealPrompt(entry.model, player)
						if sendAlert then
							sendAlert(player, "good", "Placed " .. entry.name, "$" .. entry.rate .. "/s")
						end
						else
							if sendAlert then
								sendAlert(player, "warn", "Deck full", "Buy another slot at the Upgrade Shack")
							end
						end
					end
				end
			end
		end
	end)
end

local function setAlert(fn) sendAlert = fn end
local function getPrice(player) return priceFor(PlayerState.Get(player).dredgeCount) end

-- Directly hand a specific character to a player (used by Demo).
local function giveCharacter(player, entry)
	local model = BrainrotFactory.CreateBrainrot(entry, pedestalPos, player.UserId)
	local s = PlayerState.Get(player)
	PlayerState.SetCarried(s, { model = model, name = entry.Name, rarity = entry.Rarity, rate = entry.Rate, joke = entry.Joke })
	BrainrotFactory.WeldToPlayer(model, player)
	return model
end

Dredge.SetAlert = setAlert
Dredge.Setup = setup
Dredge.GetPrice = getPrice
Dredge.SpawnOnPedestal = spawnOnPedestal
Dredge.WatchPlacement = watchPlacement
Dredge.GiveCharacter = giveCharacter
Dredge.GetStanding = function() return state.standing end
Dredge.GetPrompt = function() return prompt end
Dredge.RegisterStanding = setStanding
Dredge.DoDredge = doDredge
Dredge.TakeStanding = function(player)
	if not state.standing or not state.standingEntry then return false end
	return doTake(state.standing, state.standingEntry, player)
end

return Dredge