-- Fx: the feel of the game, driven entirely by server events. A particle burst in the rarity colour
-- when something is dredged, taken or stolen; a camera shake and a full-screen colour flash when the
-- player is swallowed by the tide. No audio, no wall-clock guesses about game state.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Rarity colours, mirroring the server's Config.RarityColors.
local RARITY_COLORS = {
	Common = Color3.fromRGB(205, 205, 205),
	Uncommon = Color3.fromRGB(85, 175, 80),
	Rare = Color3.fromRGB(70, 140, 255),
	Epic = Color3.fromRGB(175, 80, 255),
	Legendary = Color3.fromRGB(255, 150, 40),
	Mythic = Color3.fromRGB(255, 60, 60),
	Secret = Color3.fromRGB(255, 80, 200),
}

local BURST_COUNT = 18
local BURST_LIFETIME = 0.7 -- seconds a burst particle lives

-- ---------- build ----------
-- Creates the full-screen flash overlay and returns a handle with the effect methods.
local function build()
	local handle = {}

	-- Full-screen colour flash (used for the swallow). Starts invisible.
	local flashGui = Instance.new("ScreenGui")
	flashGui.Name = "BogFx"
	flashGui.ResetOnSpawn = false
	flashGui.IgnoreGuiInset = true
	flashGui.DisplayOrder = 10
	flashGui.Parent = player:WaitForChild("PlayerGui")

	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.AnchorPoint = Vector2.new(0.5, 0.5)
	flash.Position = UDim2.fromScale(0.5, 0.5)
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(110, 75, 40)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 50
	flash.Parent = flashGui

	handle.flash = flash
	handle.flashGui = flashGui
	handle.shake = nil -- set while a shake is running

	-- ---------- burst ----------
	-- A short particle burst in the rarity colour at a world position.
	-- Pass a Vector3 for where the event happened (the character, pedestal, or victim's raft).
	function handle.burst(position, rarity)
		local color = RARITY_COLORS[rarity] or Color3.fromRGB(220, 220, 220)
		local basePart = Instance.new("Part")
		basePart.Name = "BurstBase"
		basePart.Anchored = true
		basePart.CanCollide = false
		basePart.CanQuery = false
		basePart.CanTouch = false
		basePart.Transparency = 1
		basePart.Size = Vector3.new(0.2, 0.2, 0.2)
		basePart.CFrame = CFrame.new(position)
		basePart.Parent = workspace

		for i = 1, BURST_COUNT do
			local p = Instance.new("Part")
			p.Name = "Spark"
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Material = Enum.Material.Neon
			p.Color = color
			p.Size = Vector3.new(0.35, 0.35, 0.35)
			p.CFrame = basePart.CFrame
			p.Parent = workspace

			-- A random outward velocity, biased upward so it reads as a pop.
			local dir = Vector3.new(
				math.random() * 2 - 1,
				math.random() * 1.4 + 0.4,
				math.random() * 2 - 1
			).Unit
			local speed = 8 + math.random() * 8
			local goal = basePart.Position + dir * speed * BURST_LIFETIME * 0.6 + Vector3.new(0, -4, 0)

			local tween = TweenService:Create(
				p,
				TweenInfo.new(BURST_LIFETIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = goal, Transparency = 1, Size = Vector3.new(0.05, 0.05, 0.05) }
			)
			tween:Play()
			tween.Completed:Connect(function()
				p:Destroy()
			end)
		end

		-- Clean the invisible base up once the burst is done.
		task.delay(BURST_LIFETIME + 0.1, function()
			basePart:Destroy()
		end)
	end

	-- ---------- shake + flash (the swallow) ----------
	-- Camera shake plus a full-screen brown flash. Runs entirely off the Swallowed event.
	function handle.swallow()
		-- Flash: snap opaque, then fade out.
		handle.flash.BackgroundTransparency = 0.25
		local fade = TweenService:Create(
			handle.flash,
			TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		)
		fade:Play()

		-- Shake: an offset that decays to zero over ~0.6s, applied every render step.
		local duration = 0.6
		local magnitude = 2.2
		local elapsed = 0
		if handle.shakeConn then
			handle.shakeConn:Disconnect()
			handle.shakeConn = nil
		end
		-- The default camera rewrites camera.CFrame from its own state every frame, so applying a
		-- fresh small offset each RenderStepped does not accumulate into drift.
		handle.shakeConn = RunService.RenderStepped:Connect(function(dt)
			elapsed += dt
			if elapsed >= duration then
				if handle.shakeConn then
					handle.shakeConn:Disconnect()
					handle.shakeConn = nil
				end
				return
			end
			-- The offset shrinks as the shake runs out.
			local strength = magnitude * (1 - elapsed / duration)
			local offset = Vector3.new(
				(math.random() * 2 - 1) * strength,
				(math.random() * 2 - 1) * strength,
				0
			)
			camera.CFrame = camera.CFrame * CFrame.new(offset)
		end)
	end

	return handle
end

-- ---------- update ----------
-- Fx has nothing to redraw from a state table; the handle is provided for symmetry with Hud.
local function update(handle, state)
	-- Intentionally empty: Fx is event-driven only.
end

return {
	build = build,
	update = update,
}
