-- Steal: owns theft. Every placed, unlocked character on another player's deck gets a hold-to-steal
-- prompt for anyone who is not its owner. The server holds the timer, checks the lock and cooldown,
-- and alerts both sides.

local Players = game:GetService("Players")

local Config = require(script.Parent.Config)
local World = require(script.Parent.World)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local PlayerState = require(script.Parent.PlayerState)

local Steal = {}

local sendAlert -- injected by init
local onStolen -- injected by init: hands the carried entry to the thief

-- Find the placed entry (and its owner's state and slot) that this model belongs to.
local function findEntry(model)
	local ownerUserId = model:GetAttribute("OwnerUserId") or 0
	if ownerUserId == 0 then return nil end
	for _, other in ipairs(Players:GetPlayers()) do
		if other.UserId == ownerUserId then
			for _, entry in ipairs(PlayerState.GetPlaced(PlayerState.Get(other))) do
				if entry.model == model then
					return entry, PlayerState.Get(other), entry.slot
				end
			end
		end
	end
	return nil
end

local function attachStealPrompt(model, ownerPlayer)
	local old = model.PrimaryPart and model.PrimaryPart:FindFirstChild("StealPrompt")
	if old then old:Destroy() end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = "Hold to steal " .. (model:GetAttribute("Name") or "a brainrot")
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = Config.Steal.HoldTime
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	prompt.Triggered:Connect(function(thief)
		if not thief then return end
		local ownerUserId = model:GetAttribute("OwnerUserId") or 0
		if ownerUserId == 0 then return end -- not a placed, ownable character
		if thief.UserId == ownerUserId then return end
		local entry, ownerState, slot = findEntry(model)
		if not entry then return end
		local thiefState = PlayerState.Get(thief)
		local now = os.clock()
		if now - thiefState.lastStealTime < Config.Steal.Cooldown then
			if sendAlert then sendAlert(thief, "warn", "Too soon", "Wait for your steal cooldown") end
			return
		end
		if thiefState.carried then
			if sendAlert then sendAlert(thief, "warn", "Hands full", "You are already carrying something") end
			return
		end
		if entry.locked then
			if sendAlert then sendAlert(thief, "warn", entry.name .. " is bog-locked", "Its owner bought a Bog Lock") end
			return
		end
		-- Lift it into the thief's hands.
		thiefState.lastStealTime = now
		PlayerState.UnplaceAt(ownerState, slot)
		model:SetAttribute("OwnerUserId", thief.UserId)
		BrainrotFactory.WeldToPlayer(model, thief)
		PlayerState.SetCarried(thiefState, { model = model, name = entry.name, rarity = entry.rarity, rate = entry.rate, joke = entry.joke })
		if onStolen then onStolen(model, entry) end
		local owner = Players:GetPlayerByUserId(ownerUserId)
		if owner and sendAlert then
			sendAlert(owner, "bad", "Stolen!", thief.Name .. " took your " .. entry.name)
		end
		if sendAlert then sendAlert(thief, "good", "Stole " .. entry.name, "Walk it home before the tide") end
	end)
end

local function setAlert(fn) sendAlert = fn end
local function setOnStolen(fn) onStolen = fn end

Steal.AttachStealPrompt = attachStealPrompt
Steal.SetAlert = setAlert
Steal.SetOnStolen = setOnStolen

return Steal
