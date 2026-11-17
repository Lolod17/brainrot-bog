-- Demo: the developer loadout tool. It gives a player a preset of cash, placed characters and
-- carried state so a reviewer (or a screenshot) can reach a moment without playing the whole loop.
-- It is a development and review tool: it only touches the server's own state through the same
-- functions the normal loop uses, so it cannot do anything a player could not.

local Players = game:GetService("Players")

local Cast = require(script.Parent.Cast)
local Config = require(script.Parent.Config)
local World = require(script.Parent.World)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local PlayerState = require(script.Parent.PlayerState)
local Dredge = require(script.Parent.Dredge)
local Steal = require(script.Parent.Steal)
local MudTide = require(script.Parent.MudTide)

local Demo = {}

local function firstPlayer()
	local list = Players:GetPlayers()
	return list[1]
end

-- Clear a player's placed and carried models and reset their life (without a rebirth).
local function resetLife(player)
	local s = PlayerState.Get(player)
	for _, entry in ipairs(PlayerState.GetPlaced(s)) do
		BrainrotFactory.RemoveModel(entry.model)
	end
	table.clear(s.placed)
	if s.carried then
		BrainrotFactory.RemoveModel(s.carried.model)
		PlayerState.SetCarried(s, nil)
	end
end

-- Place one character of a named rarity into a slot on a player's deck.
local function placeOne(player, entry, slot)
	local s = PlayerState.Get(player)
	local deckIndex = World.GetDeckIndex(player) or 1
	local slotPos = World.GetAnchors().DeckSlotCenters[deckIndex][slot]
	local model = BrainrotFactory.CreateBrainrot(entry, slotPos, player.UserId)
	BrainrotFactory.StandInSlot(model, slotPos)
	Steal.AttachStealPrompt(model, player)
	table.insert(s.placed, {
		model = model,
		name = entry.Name,
		rarity = entry.Rarity,
		rate = entry.Rate,
		joke = entry.Joke,
		slot = slot,
		locked = false,
	})
	if entry.Rate > s.bestRate then
		s.bestRate = entry.Rate
		s.bestName = entry.Name
		s.bestRarity = entry.Rarity
	end
	return model
end

-- Cover shot: on the raft, three placed characters around the player, pedestal glowing behind,
-- tide under fifteen seconds, cash in the thousands, rate above a hundred.
local function presetCover(player)
	player = player or firstPlayer()
	if not player then return "no player" end
	resetLife(player)
	PlayerState.AddCash(PlayerState.Get(player), 3200)
	placeOne(player, Cast.GetByName("Giga Shrimp"), 1)
	placeOne(player, Cast.GetByName("Unicycle Alien"), 2)
	placeOne(player, Cast.GetByName("Cosmic Lobster"), 3)
	local s = PlayerState.Get(player)
	s.nextTideOverride = nil
	-- Walk the player onto their own raft so the shot reads as theirs.
	local character = player.Character
	if character and character.PrimaryPart then
		local bounds = World.GetAnchors().DeckBounds[World.GetDeckIndex(player) or 1]
		character:PivotTo(CFrame.new(bounds.center + Vector3.new(0, 6, 0)))
	end
	return "cover preset on " .. player.Name
end

-- Dredge shot: a rare-or-better character standing on the glowing pedestal, prompt visible.
local function presetDredge(player)
	player = player or firstPlayer()
	if not player then return "no player" end
	local entry = Cast.GetByName("Croissant Sorcerer")
	local model = BrainrotFactory.CreateBrainrot(entry, World.GetAnchors().PedestalPosition, 0)
	BrainrotFactory.StandInSlot(model, World.GetAnchors().PedestalPosition)
	-- Park the player near the pedestal so the prompt is on screen.
	local character = player.Character
	if character and character.PrimaryPart then
		character:PivotTo(CFrame.new(World.GetAnchors().PedestalPosition + Vector3.new(0, 3, 6)))
	end
	return "dredge preset on " .. player.Name
end

-- Base shot: four placed characters, one of them Bog-Locked, deck slot count on screen.
local function presetBase(player)
	player = player or firstPlayer()
	if not player then return "no player" end
	resetLife(player)
	PlayerState.AddCash(PlayerState.Get(player), 6400)
	placeOne(player, Cast.GetByName("Drill Sergeant Duck"), 1)
	placeOne(player, Cast.GetByName("Microwave Monk"), 2)
	placeOne(player, Cast.GetByName("Pigeon Baron"), 3)
	local locked = placeOne(player, Cast.GetByName("The Investor"), 4)
	locked:SetAttribute("Locked", true)
	for _, entry in ipairs(PlayerState.GetPlaced(PlayerState.Get(player))) do
		if entry.model == locked then entry.locked = true end
	end
	local character = player.Character
	if character and character.PrimaryPart then
		local bounds = World.GetAnchors().DeckBounds[World.GetDeckIndex(player) or 1]
		character:PivotTo(CFrame.new(bounds.center + Vector3.new(0, 6, -2)))
	end
	return "base preset on " .. player.Name
end

-- Tide shot: the wall sweeping in, banner up, player out on the boardwalk about to be swallowed.
local function presetTide(player)
	player = player or firstPlayer()
	if not player then return "no player" end
	resetLife(player)
	-- Put the player out on the boardwalk toward their raft.
	local deckIndex = World.GetDeckIndex(player) or 1
	local bounds = World.GetAnchors().DeckBounds[deckIndex]
	local center = World.GetAnchors().IslandCenter
	local toward = (bounds.center - center)
	toward = Vector3.new(toward.X, 0, toward.Z).Unit
	local stand = center + toward * 40 + Vector3.new(0, 3, 0)
	local character = player.Character
	if character and character.PrimaryPart then
		character:PivotTo(CFrame.new(stand))
	end
	MudTide.TriggerTideNow()
	return "tide preset on " .. player.Name
end

-- Buy a deck slot for a player, paying the price (used by the tour and by hand-testing).
local function demoBuySlot(player)
	player = player or firstPlayer()
	local s = PlayerState.Get(player)
	local price = math.ceil(Config.SlotUpgrade.BasePrice * Config.SlotUpgrade.Growth ^ (s.deckSlotsOwned - Config.DeckSlotsStart))
	if s.deckSlotsOwned >= Config.DeckSlotsMax then return "deck maxed" end
	if not PlayerState.SpendCash(s, price) then return "cannot afford" end
	s.deckSlotsOwned += 1
	return "bought slot, now " .. s.deckSlotsOwned
end

Demo.PresetCover = presetCover
Demo.PresetDredge = presetDredge
Demo.PresetBase = presetBase
Demo.PresetTide = presetTide
Demo.BuySlot = demoBuySlot
Demo.PlaceOne = placeOne
Demo.ResetLife = resetLife

return Demo