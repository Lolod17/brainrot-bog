-- PlayerState: owns every player's state in one place and serialises it for the client. The server
-- owns all of it; the client only renders what it is told.

local Config = require(script.Parent.Config)
local World = require(script.Parent.World)

local PlayerState = {}

local states = {} -- Player -> state table (reused in place on reset, never replaced)

local function newState(player)
	return {
		player = player,
		cash = Config.StartingCash,
		totalEarned = 0,
		rebirths = 0,
		deckSlotsOwned = Config.DeckSlotsStart,
		placed = {}, -- array of entries: { model, name, rarity, rate, joke, slot }
		carried = nil, -- one entry or nil
		dredgeCount = 0,
		legsBought = 0,
		lastStealTime = 0,
		bestName = nil,
		bestRarity = nil,
		bestRate = 0,
	}
end

local function get(player)
	local s = states[player]
	if not s then
		s = newState(player)
		states[player] = s
	end
	return s
end

local function clear(player)
	local s = states[player]
	if not s then return end
	-- Remove every model this player owns before dropping the state.
	for _, entry in ipairs(s.placed) do
		if entry.model then entry.model:Destroy() end
	end
	if s.carried and s.carried.model then s.carried.model:Destroy() end
	World.FreeDeck(player)
	-- Reset in place so a stale reference cannot point at a dead player's old table.
	local fresh = newState(player)
	for k in pairs(s) do s[k] = nil end
	for k, v in pairs(fresh) do s[k] = v end
end

local function rebirthMultiplier(s)
	return 1 + s.rebirths * Config.Rebirth.Multiplier
end

-- The sum of placed rates, times the rebirth multiplier.
local function incomePerSecond(s)
	local sum = 0
	for _, entry in ipairs(s.placed) do
		sum += entry.rate
	end
	return sum * rebirthMultiplier(s)
end

local function addCash(s, amount)
	if not s then return end
	s.cash += amount
	if amount > 0 then
		s.totalEarned += amount
	end
end

local function spendCash(s, amount)
	if not s then return false end
	if s.cash < amount then return false end
	s.cash -= amount
	return true
end

-- Place a carried entry in the first free slot. Returns the entry or nil.
local function placeCarried(s)
	local entry = s.carried
	if not entry then return nil end
	local used = {}
	for _, e in ipairs(s.placed) do used[e.slot] = true end
	local slot = nil
	for i = 1, s.deckSlotsOwned do
		if not used[i] then
			slot = i
			break
		end
	end
	if not slot then return nil end
	if not entry.model then return nil end -- a destroyed model cannot be placed
	entry.slot = slot
	entry.model:SetAttribute("Placed", true)
	entry.model:SetAttribute("CarriedBy", nil)
	table.insert(s.placed, entry)
	s.carried = nil
	-- Track the best character ever owned.
	if entry.rate > s.bestRate then
		s.bestRate = entry.rate
		s.bestName = entry.name
		s.bestRarity = entry.rarity
	end
	return entry
end

local function unplaceAt(s, slot)
	for i, entry in ipairs(s.placed) do
		if entry.slot == slot then
			table.remove(s.placed, i)
			return entry
		end
	end
	return nil
end

local function setCarried(s, entry)
	s.carried = entry
end

local function setLegsBought(s, n)
	s.legsBought = n
end

-- The whole state as one plain table for the client to render.
local function serialise(s)
	local placed = {}
	for _, entry in ipairs(s.placed) do
		table.insert(placed, {
			name = entry.name,
			rarity = entry.rarity,
			rate = entry.rate,
			joke = entry.joke,
			slot = entry.slot,
			locked = entry.locked or false,
		})
	end
	local carried = nil
	if s.carried then
		carried = {
			name = s.carried.name,
			rarity = s.carried.rarity,
			rate = s.carried.rate,
		}
	end
	local deckIndex = World.GetDeckIndex(s.player)
	return {
		cash = math.floor(s.cash),
		totalEarned = math.floor(s.totalEarned),
		rebirths = s.rebirths,
		perSecond = math.floor(incomePerSecond(s) * 100) / 100,
		multiplier = rebirthMultiplier(s),
		deckSlotsOwned = s.deckSlotsOwned,
		deckSlotsMax = Config.DeckSlotsMax,
		deckIndex = deckIndex,
		placed = placed,
		carried = carried,
		dredgePrice = nil, -- filled by Dredge
		rebirthReady = s.totalEarned >= Config.Rebirth.Threshold,
		rebirthThreshold = Config.Rebirth.Threshold,
		nextTideIn = nil, -- filled by MudTide
		legsBought = s.legsBought,
		walkSpeed = Config.LegsUpgrade.WalkSpeedBase + s.legsBought * Config.LegsUpgrade.WalkSpeedStep,
		bestName = s.bestName,
		bestRarity = s.bestRarity,
	}
end

local function getCarried(s)
	return s.carried
end

local function getPlaced(s)
	return s.placed
end

local function getRebirths(s)
	return s.rebirths
end

local function getMultiplier(s)
	return rebirthMultiplier(s)
end

PlayerState.Get = get
PlayerState.Clear = clear
PlayerState.AddCash = addCash
PlayerState.SpendCash = spendCash
PlayerState.PlaceCarried = placeCarried
PlayerState.UnplaceAt = unplaceAt
PlayerState.SetCarried = setCarried
PlayerState.GetCarried = getCarried
PlayerState.GetPlaced = getPlaced
PlayerState.GetRebirths = getRebirths
PlayerState.GetMultiplier = getMultiplier
PlayerState.SetLegsBought = setLegsBought
PlayerState.Serialise = serialise
PlayerState.IncomePerSecond = incomePerSecond
PlayerState.RebirthMultiplier = rebirthMultiplier

return PlayerState