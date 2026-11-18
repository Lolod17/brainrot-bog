-- Cast: the fifteen BRAINROT BOG characters. Each entry has a name, a rarity, a rate (cash a second),
-- one short dry joke line, and a build recipe: a list of parts, each placed relative to the torso
-- (the origin), sized around three studs tall. BrainrotFactory turns the recipe into a Model.

local Config = require(script.Parent.Config)

local Cast = {}

-- One recipe part. n name, s size, o offset from the torso, c colour, sh shape, m material, t transparency.
local function P(n, s, o, c, sh, m, t)
	return {
		Name = n,
		Size = Vector3.new(s[1], s[2], s[3]),
		Offset = Vector3.new(o[1], o[2], o[3]),
		Color = Color3.fromRGB(c[1], c[2], c[3]),
		Shape = sh or "Block",
		Material = m or Enum.Material.SmoothPlastic,
		Transparency = t or 0,
	}
end

local BROWN = {150, 95, 45}
local YELLOW = {250, 210, 70}
local GREY = {130, 130, 135}
local CREAM = {245, 232, 200}
local GREEN = {95, 175, 85}
local RED = {215, 55, 55}
local GOLD = {240, 195, 50}
local DARK = {45, 40, 45}

-- name, rarity, rate, joke, parts, whether it glows
local ENTRIES = {
	{
		Name = "Soggy Waffle Steve", Rarity = "Common", Rate = 1,
		Joke = "Soggy, but he shows up.",
		Parts = {
			P("Torso", {2.2, 2.2, 0.6}, {0, 0, 0}, BROWN, "Block", Enum.Material.Wood),
			P("Butter", {1.1, 0.4, 0.7}, {0, 1.3, 0}, YELLOW),
			P("GridLine", {2.0, 0.08, 0.66}, {0, 0.4, 0}, {120, 72, 32}),
			P("GridLine2", {2.0, 0.08, 0.66}, {0, -0.4, 0}, {120, 72, 32}),
			P("LeftArm", {0.35, 1.2, 0.35}, {-1.45, -0.2, 0}, BROWN),
			P("RightArm", {0.35, 1.2, 0.35}, {1.45, -0.2, 0}, BROWN),
			P("LeftLeg", {0.4, 0.7, 0.4}, {-0.55, -1.4, 0}, {120, 72, 32}),
			P("RightLeg", {0.4, 0.7, 0.4}, {0.55, -1.4, 0}, {120, 72, 32}),
			P("LeftEye", {0.3, 0.3, 0.15}, {-0.45, 0.5, -0.38}, {20, 20, 20}, "Ball"),
			P("RightEye", {0.3, 0.3, 0.15}, {0.45, 0.5, -0.38}, {20, 20, 20}, "Ball"),
		},
	},
	{
		Name = "Taxi Rat", Rarity = "Common", Rate = 2,
		Joke = "Off the meter, never off the clock.",
		Parts = {
			P("Torso", {1.4, 1.2, 1.0}, {0, 0, 0}, GREY, "Block"),
			P("Head", {0.9, 0.8, 0.9}, {0, 0.95, 0}, GREY, "Ball"),
			P("LeftEar", {0.4, 0.45, 0.15}, {-0.45, 1.5, 0}, {170, 150, 160}, "Ball"),
			P("RightEar", {0.4, 0.45, 0.15}, {0.45, 1.5, 0}, {170, 150, 160}, "Ball"),
			P("CabSign", {1.0, 0.45, 0.3}, {0, 1.75, 0}, YELLOW, "Block", Enum.Material.Neon),
			P("CheckerSkirt", {1.5, 0.5, 1.1}, {0, -0.75, 0}, {25, 25, 25}, "Block", Enum.Material.Neon),
			P("CheckerSkirtWhite", {0.4, 0.52, 1.12}, {0.45, -0.75, 0}, {240, 240, 240}, "Block", Enum.Material.Neon),
			P("Tail", {0.18, 0.18, 1.2}, {0, -0.2, 0.9}, {200, 140, 150}, "Cylinder"),
			P("Nose", {0.35, 0.3, 0.35}, {0, 0.85, -0.6}, {225, 150, 170}, "Ball"),
			P("Wheel", {0.9, 0.1, 0.1}, {0, 0.85, -0.62}, {20, 20, 20}, "Ball"),
		},
	},
	{
		Name = "Grandma Cucumber", Rarity = "Common", Rate = 4,
		Joke = "She has seen some brine.",
		Parts = {
			P("Torso", {1.1, 2.2, 1.1}, {0, -0.2, 0}, GREEN, "Cylinder", Enum.Material.SmoothPlastic),
			P("Head", {1.0, 1.0, 1.0}, {0, 1.1, 0}, {120, 195, 110}, "Ball"),
			P("Shawl", {1.7, 0.9, 1.7}, {0, 0.55, 0}, {150, 80, 120}, "Block", Enum.Material.Fabric),
			P("LeftLens", {0.42, 0.42, 0.12}, {-0.28, 1.2, -0.5}, {230, 230, 230}, "Cylinder"),
			P("RightLens", {0.42, 0.42, 0.12}, {0.28, 1.2, -0.5}, {230, 230, 230}, "Cylinder"),
			P("Bridge", {0.2, 0.06, 0.06}, {0, 1.25, -0.5}, {230, 230, 230}),
			P("Cane", {0.12, 1.6, 0.12}, {0.75, -0.9, 0}, {110, 70, 40}, "Cylinder"),
			P("Bun", {0.45, 0.4, 0.45}, {0, 1.65, 0}, {220, 220, 220}, "Ball"),
		},
	},
	{
		Name = "Moth Intern", Rarity = "Uncommon", Rate = 7,
		Joke = "Very into the lamp. Professionally.",
		Parts = {
			P("Torso", {1.1, 1.3, 0.8}, {0, 0, 0}, CREAM, "Block", Enum.Material.Fabric),
			P("Head", {1.0, 0.9, 0.9}, {0, 1.05, 0}, CREAM, "Ball", Enum.Material.Fabric),
			P("LeftEye", {0.5, 0.5, 0.3}, {-0.28, 1.1, -0.5}, {20, 20, 25}, "Ball"),
			P("RightEye", {0.5, 0.5, 0.3}, {0.28, 1.1, -0.5}, {20, 20, 25}, "Ball"),
			P("LeftWing", {1.2, 0.9, 0.12}, {-1.0, 0.4, 0.2}, {250, 240, 215}, "Block", Enum.Material.Fabric),
			P("RightWing", {1.2, 0.9, 0.12}, {1.0, 0.4, 0.2}, {250, 240, 215}, "Block", Enum.Material.Fabric),
			P("LeftAntenna", {0.08, 0.7, 0.08}, {-0.3, 1.7, 0}, DARK, "Cylinder"),
			P("RightAntenna", {0.08, 0.7, 0.08}, {0.3, 1.7, 0}, DARK, "Cylinder"),
			P("Tie", {0.35, 0.6, 0.1}, {0, 0.45, -0.48}, {180, 40, 50}, "Block", Enum.Material.Neon),
		},
	},
	{
		Name = "Skateboard Goat", Rarity = "Uncommon", Rate = 11,
		Joke = "Kicked the board. Board deserved it.",
		Parts = {
			P("Torso", {1.2, 1.2, 0.8}, {0, 0.4, 0}, {235, 232, 225}, "Block"),
			P("Head", {0.8, 0.75, 0.8}, {0, 1.35, 0}, {235, 232, 225}, "Ball"),
			P("LeftHorn", {0.15, 0.5, 0.15}, {-0.3, 1.85, 0}, {110, 80, 50}, "Cylinder"),
			P("RightHorn", {0.15, 0.5, 0.15}, {0.3, 1.85, 0}, {110, 80, 50}, "Cylinder"),
			P("Cap", {0.9, 0.3, 0.9}, {0, 1.75, 0}, {40, 90, 200}, "Block", Enum.Material.Neon),
			P("CapBrim", {0.9, 0.12, 0.5}, {0, 1.62, -0.6}, {40, 90, 200}, "Block", Enum.Material.Neon),
			P("Board", {2.2, 0.15, 0.7}, {0, -1.2, 0}, {200, 60, 140}, "Block", Enum.Material.Wood),
			P("FrontWheel", {0.3, 0.3, 0.3}, {-0.7, -1.45, 0}, {30, 30, 30}, "Ball"),
			P("BackWheel", {0.3, 0.3, 0.3}, {0.7, -1.45, 0}, {30, 30, 30}, "Ball"),
			P("Beard", {0.4, 0.5, 0.3}, {0, 1.05, -0.4}, {235, 232, 225}, "Block"),
		},
	},
	{
		Name = "Toilet Philosopher", Rarity = "Uncommon", Rate = 16,
		Joke = "Has questions. Will not flush them.",
		Parts = {
			P("Torso", {1.3, 0.9, 1.3}, {0, -0.9, 0}, {235, 238, 240}, "Block", Enum.Material.Marble),
			P("Tank", {1.3, 1.3, 0.55}, {0, -0.2, 0.6}, {235, 238, 240}, "Block", Enum.Material.Marble),
			P("Seat", {1.5, 0.2, 1.5}, {0, -0.35, 0}, {250, 250, 250}, "Cylinder", Enum.Material.Marble),
			P("FigureBody", {0.6, 0.8, 0.5}, {0, 0.35, -0.1}, {215, 220, 225}, "Block", Enum.Material.Marble),
			P("Head", {0.6, 0.6, 0.6}, {0, 1.05, -0.1}, {225, 228, 232}, "Ball", Enum.Material.Marble),
			P("ThoughtBubble", {0.7, 0.5, 0.1}, {0.55, 1.7, -0.3}, {255, 255, 255}, "Ball", Enum.Material.Neon),
			P("BubbleSmall", {0.25, 0.25, 0.1}, {0.25, 1.45, -0.3}, {255, 255, 255}, "Ball", Enum.Material.Neon),
			P("Handle", {0.15, 0.15, 0.4}, {0.65, -0.1, 0.6}, {170, 170, 175}, "Block"),
		},
	},
	{
		Name = "Croissant Sorcerer", Rarity = "Rare", Rate = 24,
		Joke = "Baked, then he ascended.",
		Parts = {
			P("Torso", {1.7, 1.0, 1.0}, {0, 0, 0}, {200, 135, 60}, "Block", Enum.Material.Wood),
			P("RollEndL", {0.6, 0.6, 0.6}, {-0.95, 0.15, 0}, {215, 150, 70}, "Ball"),
			P("RollEndR", {0.6, 0.6, 0.6}, {0.95, 0.15, 0}, {215, 150, 70}, "Ball"),
			P("Brim", {1.1, 0.15, 1.1}, {0, 0.7, 0}, {70, 40, 130}, "Cylinder"),
			P("HatCone", {0.75, 1.1, 0.75}, {0, 1.3, 0}, {70, 40, 130}, "Wedge", Enum.Material.Neon),
			P("HatBand", {0.95, 0.15, 0.95}, {0, 0.82, 0}, {230, 200, 80}, "Cylinder", Enum.Material.Neon),
			P("Wand", {0.1, 1.4, 0.1}, {1.1, 0.4, -0.4}, {90, 55, 30}, "Cylinder"),
			P("WandStar", {0.35, 0.35, 0.35}, {1.1, 1.15, -0.4}, {255, 230, 90}, "Ball", Enum.Material.Neon),
			P("LeftArm", {0.25, 0.8, 0.25}, {-0.95, 0.1, 0}, {200, 135, 60}, "Cylinder"),
		},
	},
	{
		Name = "Pigeon Baron", Rarity = "Rare", Rate = 34,
		Joke = "Owns the bench. All of them.",
		Parts = {
			P("Torso", {1.5, 1.3, 1.1}, {0, 0, 0}, {140, 150, 165}, "Ball"),
			P("Head", {0.7, 0.7, 0.7}, {0, 1.0, -0.35}, {150, 160, 175}, "Ball"),
			P("Beak", {0.2, 0.15, 0.45}, {0, 0.95, -0.8}, {230, 190, 70}, "Block"),
			P("TopHatBrim", {1.1, 0.1, 1.1}, {0, 1.35, -0.35}, {20, 20, 25}, "Cylinder"),
			P("TopHatCrown", {0.75, 0.75, 0.75}, {0, 1.75, -0.35}, {20, 20, 25}, "Cylinder"),
			P("Monocle", {0.35, 0.35, 0.1}, {0.2, 1.0, -0.75}, {255, 240, 140}, "Cylinder", Enum.Material.Neon),
			P("LeftWing", {0.3, 1.0, 0.9}, {-0.85, -0.1, 0.1}, {120, 130, 145}, "Block"),
			P("RightWing", {0.3, 1.0, 0.9}, {0.85, -0.1, 0.1}, {120, 130, 145}, "Block"),
			P("Tail", {0.7, 0.2, 0.7}, {0, 0.1, 0.85}, {120, 130, 145}, "Wedge"),
			P("Foot", {0.6, 0.12, 0.2}, {0, -0.75, 0}, {230, 150, 50}, "Block"),
		},
	},
	{
		Name = "Microwave Monk", Rarity = "Rare", Rate = 48,
		Joke = "Dings for enlightenment.",
		Parts = {
			P("Torso", {1.7, 1.6, 1.4}, {0, 0, 0}, {215, 220, 225}, "Block", Enum.Material.Metal),
			P("Door", {0.1, 1.3, 1.1}, {-0.86, 0.05, 0}, {60, 65, 70}, "Block", Enum.Material.Glass),
			P("DoorWindow", {0.05, 0.8, 0.7}, {-0.92, 0.15, 0}, {40, 45, 50}, "Block", Enum.Material.Glass),
			P("Handle", {0.08, 0.7, 0.12}, {-0.95, 0.1, 0.4}, {180, 180, 185}, "Block", Enum.Material.Metal),
			P("BeadNeck", {0.5, 0.5, 0.5}, {0, 1.05, 0}, {235, 225, 200}, "Ball"),
			P("Bead1", {0.22, 0.22, 0.22}, {-0.2, 0.75, -0.55}, {90, 40, 30}, "Ball"),
			P("Bead2", {0.22, 0.22, 0.22}, {0, 0.72, -0.6}, {90, 40, 30}, "Ball"),
			P("Bead3", {0.22, 0.22, 0.22}, {0.2, 0.75, -0.55}, {90, 40, 30}, "Ball"),
			P("Feet", {1.4, 0.2, 1.1}, {0, -0.9, 0}, {70, 70, 75}, "Block"),
			P("BrowLine", {1.2, 0.1, 0.1}, {0, 0.5, -0.72}, {60, 60, 65}, "Block"),
		},
	},
	{
		Name = "Drill Sergeant Duck", Rarity = "Epic", Rate = 72,
		Joke = "Quack means quack. Drop and give him twenty.",
		Parts = {
			P("Torso", {1.5, 1.3, 1.3}, {0, 0, 0}, YELLOW, "Ball"),
			P("Head", {1.0, 0.95, 1.0}, {0, 1.1, -0.1}, YELLOW, "Ball"),
			P("Bill", {0.9, 0.25, 0.7}, {0, 1.0, -0.75}, {250, 170, 40}, "Block"),
			P("Helmet", {1.15, 0.55, 1.15}, {0, 1.5, -0.1}, {70, 100, 60}, "Cylinder", Enum.Material.Metal),
			P("HelmetBrim", {1.2, 0.1, 0.5}, {0, 1.3, -0.55}, {70, 100, 60}, "Block", Enum.Material.Metal),
			P("Whistle", {0.2, 0.2, 0.5}, {0, 0.75, -0.85}, {200, 200, 210}, "Cylinder", Enum.Material.Metal),
			P("LeftLeg", {0.25, 0.7, 0.25}, {-0.4, -1.1, 0}, {250, 170, 40}, "Cylinder"),
			P("RightLeg", {0.25, 0.7, 0.25}, {0.4, -1.1, 0}, {250, 170, 40}, "Cylinder"),
			P("Sash", {0.2, 1.3, 1.5}, {0, 0, 0}, {150, 40, 40}, "Block", Enum.Material.Fabric),
			P("Star", {0.4, 0.4, 0.1}, {0, 0.3, -0.76}, {255, 220, 80}, "Cylinder", Enum.Material.Neon),
		},
	},
	{
		Name = "Cosmic Lobster", Rarity = "Epic", Rate = 110,
		Joke = "Boiled once. Came back weirder.",
		Parts = {
			P("Torso", {1.2, 1.4, 1.6}, {0, 0, 0}, RED, "Block"),
			P("Head", {0.9, 0.8, 0.9}, {0, 0.95, -0.2}, RED, "Ball"),
			P("Helmet", {1.3, 1.1, 1.3}, {0, 1.2, -0.2}, {180, 220, 255}, "Ball", Enum.Material.Glass, 0.55),
			P("HelmetStar", {0.2, 0.2, 0.2}, {0.3, 1.4, -0.4}, {255, 255, 255}, "Ball", Enum.Material.Neon),
			P("HelmetStar2", {0.15, 0.15, 0.15}, {-0.35, 1.1, -0.55}, {255, 240, 120}, "Ball", Enum.Material.Neon),
			P("LeftClaw", {0.6, 0.5, 0.6}, {-0.95, -0.2, -0.4}, RED, "Ball"),
			P("RightClaw", {0.6, 0.5, 0.6}, {0.95, -0.2, -0.4}, RED, "Ball"),
			P("Tail", {0.9, 0.4, 0.9}, {0, -0.2, 1.1}, {180, 40, 40}, "Wedge"),
			P("Antenna", {0.08, 1.0, 0.08}, {0.3, 1.6, 0.3}, {255, 255, 255}, "Cylinder"),
			P("LegL", {0.2, 0.6, 0.2}, {-0.55, -1.0, 0.2}, RED, "Cylinder"),
			P("LegR", {0.2, 0.6, 0.2}, {0.55, -1.0, 0.2}, RED, "Cylinder"),
		},
	},
	{
		Name = "Unicycle Alien", Rarity = "Legendary", Rate = 170,
		Joke = "One wheel. Zero explanation.",
		Parts = {
			P("Wheel", {1.2, 0.25, 1.2}, {0, -1.4, 0}, {40, 40, 45}, "Cylinder", Enum.Material.Metal),
			P("Fork", {0.2, 1.2, 0.2}, {0, -0.6, 0}, {180, 180, 190}, "Cylinder", Enum.Material.Metal),
			P("Seat", {0.7, 0.2, 0.5}, {0, 0.05, 0}, {30, 30, 35}, "Block"),
			P("Torso", {1.0, 1.1, 0.7}, {0, 0.7, 0}, {90, 210, 120}, "Block", Enum.Material.Neon),
			P("Head", {0.9, 0.8, 0.8}, {0, 1.6, 0}, {110, 225, 130}, "Ball", Enum.Material.Neon),
			P("Antenna", {0.07, 0.8, 0.07}, {0, 2.3, 0}, {200, 200, 210}, "Cylinder"),
			P("AntennaBall", {0.25, 0.25, 0.25}, {0, 2.75, 0}, {255, 90, 90}, "Ball", Enum.Material.Neon),
			P("LeftEye", {0.28, 0.28, 0.1}, {-0.25, 1.65, -0.42}, {20, 20, 20}, "Ball"),
			P("RightEye", {0.28, 0.28, 0.1}, {0.25, 1.65, -0.42}, {20, 20, 20}, "Ball"),
			P("LeftArm", {0.2, 0.8, 0.2}, {-0.65, 0.6, 0}, {90, 210, 120}, "Cylinder"),
			P("RightArm", {0.2, 0.8, 0.2}, {0.65, 0.6, 0}, {90, 210, 120}, "Cylinder"),
		},
	},
	{
		Name = "Giga Shrimp", Rarity = "Legendary", Rate = 260,
		Joke = "Enormous. Still counts as a snack.",
		Parts = {
			P("Torso", {1.5, 1.5, 2.2}, {0, 0, 0}, {255, 140, 120}, "Ball"),
			P("Segment", {1.3, 1.3, 1.0}, {0, 0.1, -1.2}, {250, 125, 110}, "Ball"),
			P("Head", {1.2, 1.1, 1.0}, {0, 0.2, -1.95}, {255, 150, 130}, "Ball"),
			P("TailFan", {1.4, 0.3, 1.0}, {0, 0.2, 1.4}, {250, 110, 100}, "Wedge"),
			P("Crown", {0.9, 0.4, 0.9}, {0, 1.0, -1.95}, GOLD, "Cylinder", Enum.Material.Neon),
			P("CrownPoint", {0.3, 0.5, 0.3}, {0, 1.4, -1.95}, GOLD, "Wedge", Enum.Material.Neon),
			P("Sunglasses", {1.1, 0.35, 0.15}, {0, 0.35, -2.7}, {20, 20, 20}, "Block", Enum.Material.Neon),
			P("LegL", {0.2, 0.7, 0.2}, {-0.6, -1.0, 0.3}, {250, 110, 100}, "Cylinder"),
			P("LegR", {0.2, 0.7, 0.2}, {0.6, -1.0, 0.3}, {250, 110, 100}, "Cylinder"),
			P("Whisker", {0.06, 0.06, 1.0}, {-0.4, 0.1, -2.7}, {255, 255, 255}, "Cylinder"),
		},
	},
	{
		Name = "The Investor", Rarity = "Mythic", Rate = 420,
		Joke = "Your money is safe with him. That is the joke.",
		Parts = {
			P("Torso", {1.4, 1.6, 0.8}, {0, 0.3, 0}, GREY, "Block", Enum.Material.Metal),
			P("LeftLeg", {0.45, 1.3, 0.45}, {-0.35, -1.1, 0}, {50, 50, 55}, "Block"),
			P("RightLeg", {0.45, 1.3, 0.45}, {0.35, -1.1, 0}, {50, 50, 55}, "Block"),
			P("Head", {0.8, 0.8, 0.8}, {0, 1.5, 0}, {200, 200, 205}, "Ball", Enum.Material.Metal),
			P("Visor", {0.9, 0.3, 0.2}, {0, 1.55, -0.45}, {80, 255, 120}, "Block", Enum.Material.Neon),
			P("LeftArm", {0.35, 1.3, 0.35}, {-0.9, 0.3, 0}, GREY, "Block"),
			P("RightArm", {0.35, 1.3, 0.35}, {0.9, 0.3, 0}, GREY, "Block"),
			P("Briefcase", {1.1, 0.8, 0.25}, {0.95, -0.75, -0.4}, {70, 45, 30}, "Block", Enum.Material.Wood),
			P("Tie", {0.3, 0.9, 0.1}, {0, 0.5, -0.45}, {40, 40, 120}, "Block", Enum.Material.Neon),
			P("Shoulders", {1.7, 0.3, 0.9}, {0, 1.15, 0}, {110, 110, 115}, "Block", Enum.Material.Metal),
		},
	},
	{
		Name = "Godfather Goldfish", Rarity = "Secret", Rate = 900,
		Joke = "Made them an offer they could not refuse. It was a pebble.",
		Glows = true,
		Parts = {
			P("Torso", {1.4, 1.3, 1.9}, {0, 0, 0}, GOLD, "Ball", Enum.Material.Neon),
			P("Head", {1.1, 1.0, 1.0}, {0, 0.15, -1.2}, GOLD, "Ball", Enum.Material.Neon),
			P("TailFin", {0.4, 1.0, 1.0}, {0, 0.1, 1.4}, {230, 170, 40}, "Wedge", Enum.Material.Neon),
			P("FedoraBrim", {1.6, 0.12, 1.6}, {0, 0.75, -1.2}, {35, 25, 20}, "Cylinder"),
			P("FedoraCrown", {1.0, 0.7, 1.0}, {0, 1.1, -1.2}, {35, 25, 20}, "Cylinder"),
			P("BowTie", {0.7, 0.3, 0.2}, {0, -0.5, -1.55}, {140, 20, 30}, "Block", Enum.Material.Neon),
			P("LeftEye", {0.25, 0.25, 0.15}, {-0.3, 0.2, -1.95}, {20, 20, 20}, "Ball"),
			P("RightEye", {0.25, 0.25, 0.15}, {0.3, 0.2, -1.95}, {20, 20, 20}, "Ball"),
			P("SideFin", {0.15, 0.6, 0.5}, {-0.75, -0.2, 0}, {230, 170, 40}, "Block", Enum.Material.Neon),
			P("Cigar", {0.15, 0.15, 0.6}, {0.45, -0.15, -2.1}, {110, 60, 30}, "Cylinder"),
		},
	},
}

-- Validate the cast against the config: every rarity named must have a colour and a weight.
for _, entry in ipairs(ENTRIES) do
	assert(Config.RarityColors[entry.Rarity], "Cast entry " .. entry.Name .. " has an unknown rarity")
	assert(Config.RarityWeights[entry.Rarity], "Cast entry " .. entry.Name .. " has a rarity with no weight")
	assert(Config.RarityRank[entry.Rarity], "Cast entry " .. entry.Name .. " has a rarity with no rank")
end

local byRarity = {}
for _, entry in ipairs(ENTRIES) do
	byRarity[entry.Rarity] = byRarity[entry.Rarity] or {}
	table.insert(byRarity[entry.Rarity], entry)
end

-- The rarity names, ordered best last, plus their normalised weights.
local rarityNames, weights = {}, {}
for name, weight in pairs(Config.RarityWeights) do
	table.insert(rarityNames, name)
	weights[name] = weight
end
table.sort(rarityNames, function(a, b) return Config.RarityRank[a] < Config.RarityRank[b] end)
local totalWeight = 0
for _, name in ipairs(rarityNames) do totalWeight += weights[name] end
local cumulative = {}
local running = 0
for _, name in ipairs(rarityNames) do
	running += weights[name] / totalWeight
	cumulative[name] = running
end

-- Roll one rarity by the configured weights, then pick uniformly inside it.
local function rollRarity()
	local roll = math.random() * totalWeight
	for _, name in ipairs(rarityNames) do
		if roll <= cumulative[name] then
			return name
		end
	end
	return rarityNames[1]
end

-- Roll one random character: rarity first, then a uniform pick inside that rarity.
local function rollCharacter()
	local rarity = rollRarity()
	local pool = byRarity[rarity]
	if not pool or #pool == 0 then
		-- Fall back to the whole cast rather than indexing an empty pool.
		return ENTRIES[math.random(#ENTRIES)]
	end
	return pool[math.random(#pool)]
end

-- Every character of one rarity. Returns an empty table rather than erroring when the config names a
-- rarity that the cast does not carry.
local function charactersOfRarity(rarity)
	local pool = byRarity[rarity] or {}
	local copy = {}
	for _, entry in ipairs(pool) do table.insert(copy, entry) end
	return copy
end

Cast.Entries = ENTRIES
Cast.RollCharacter = rollCharacter
Cast.RollRarity = rollRarity
Cast.CharactersOfRarity = charactersOfRarity
Cast.GetByName = function(name)
	for _, entry in ipairs(ENTRIES) do
		if entry.Name == name then return entry end
	end
	return nil
end

return Cast