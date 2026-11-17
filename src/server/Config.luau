-- Config: every number the game tunes, in one table each, so nothing is hard-coded twice.

local Config = {}

-- Money and the money tick.
Config.StartingCash = 25
Config.TickRate = 0.25 -- seconds between money ticks (four times a second)

-- Deck slots.
Config.DeckSlotsStart = 4
Config.DeckSlotsMax = 12

-- The Dredge Pedestal price curve.
Config.Dredge = {
	BasePrice = 15,
	Growth = 1.12, -- price grows by this factor each dredge, rounded up
}

-- Upgrades (bought at the Upgrade Shack).
Config.SlotUpgrade = {
	BasePrice = 300,
	Growth = 1.6,
}
Config.LegsUpgrade = {
	BasePrice = 250,
	WalkSpeedBase = 16,
	WalkSpeedStep = 2,
	Steps = 4, -- four buys, 16 -> 18 -> 20 -> 22 -> 24
}
Config.BogLock = {
	BasePrice = 900,
	Growth = 1.5,
}

-- Stealing.
Config.Steal = {
	HoldTime = 2.5, -- seconds holding the prompt to steal
	Cooldown = 5, -- seconds between steals, per thief
}

-- Rebirth (at the Toll Booth).
Config.Rebirth = {
	Threshold = 7500, -- total cash earned in this life needed
	Multiplier = 0.30, -- +30% earnings per rebirth, permanent
	ResetCash = 25,
}
Config.BogBaronRebirths = 6 -- rebirths at which the Bog Baron panel fires

-- The Mud Tide.
Config.Tide = {
	Interval = 110, -- seconds between tides
	Warning = 10, -- seconds of warning banner
	SweepDuration = 8, -- seconds the wall takes to cross the map
	CashLossFraction = 0.10, -- a tenth of cash lost when swallowed
	WallHeight = 14,
	WallThickness = 6,
	StartDistance = 240, -- how far out the wall starts
	EndDistance = 10, -- how close to the island centre it sweeps
}

-- Rarity roll weights (percent). They are normalised, so they always sum to one hundred.
Config.RarityWeights = {
	Common = 45,
	Uncommon = 27,
	Rare = 16,
	Epic = 8,
	Legendary = 3,
	Mythic = 0.85,
	Secret = 0.15,
}

-- Rarity display colours (label text and pedestal glow).
Config.RarityColors = {
	Common = Color3.fromRGB(205, 205, 205),
	Uncommon = Color3.fromRGB(85, 175, 80),
	Rare = Color3.fromRGB(70, 140, 255),
	Epic = Color3.fromRGB(175, 80, 255),
	Legendary = Color3.fromRGB(255, 150, 40),
	Mythic = Color3.fromRGB(255, 60, 60),
	Secret = Color3.fromRGB(255, 80, 200),
}

-- Rarity rank (higher is better); used to find a player's best character.
Config.RarityRank = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
	Secret = 7,
}

return Config