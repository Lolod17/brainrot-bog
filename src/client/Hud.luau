-- Hud: builds and owns the whole ScreenGui for one player. It renders only what the server sends.
-- Two functions leave this module: build(player) returns a handle, update(handle, state) redraws it.
-- Everything the server can send (tide phase, alerts, the Bog Baron panel) hangs off the handle.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ---------- Local constants (mirror the server's Config; the client cannot require it) ----------
local RARITY_COLORS = {
	Common = Color3.fromRGB(205, 205, 205),
	Uncommon = Color3.fromRGB(85, 175, 80),
	Rare = Color3.fromRGB(70, 140, 255),
	Epic = Color3.fromRGB(175, 80, 255),
	Legendary = Color3.fromRGB(255, 150, 40),
	Mythic = Color3.fromRGB(255, 60, 60),
	Secret = Color3.fromRGB(255, 80, 200),
}

local TIDE = {
	Interval = 110, -- seconds between tides (the drain countdown restarts from this)
	Warning = 10,
	SweepDuration = 8,
}

-- Alert kinds -> card colour. The server sends: good, bad, info, warn, tide.
local ALERT_COLORS = {
	good = Color3.fromRGB(70, 170, 90),
	bad = Color3.fromRGB(200, 70, 70),
	info = Color3.fromRGB(80, 140, 220),
	warn = Color3.fromRGB(220, 170, 60),
	tide = Color3.fromRGB(150, 105, 60),
}

local ALERT_LIFETIME = 4 -- seconds an alert card stays before fading
local ALERT_FADE = 0.6 -- seconds the fade takes

local FONT = Enum.Font.GothamBold
local MONEY_TEXT_SIZE = 48 -- the big cash figure, at the bottom centre

-- ---------- Helpers ----------
-- Format a whole number with a dollar sign and comma thousands separators.
local function money(n)
	n = math.floor(tonumber(n) or 0)
	local whole = tostring(n)
	local neg = string.sub(whole, 1, 1) == "-"
	if neg then whole = string.sub(whole, 2) end
	local out = ""
	local count = 0
	for i = #whole, 1, -1 do
		out = string.sub(whole, i, i) .. out
		count += 1
		if count % 3 == 0 and i > 1 then
			out = "," .. out
		end
	end
	return (neg and "-$" or "$") .. out
end

-- A plain TextLabel with the common defaults filled in.
local function label(name, parent, text, color, size)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color
	t.Font = FONT
	t.TextSize = size or 20
	t.TextStrokeTransparency = 0.6
	t.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	t.Parent = parent
	return t
end

-- A black panel with rounded corners, used as a card or overlay base.
local function panel(name, parent, color)
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = color or Color3.fromRGB(20, 20, 24)
	f.BackgroundTransparency = 0.25
	f.BorderSizePixel = 0
	f.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = f
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(0, 0, 0)
	s.Thickness = 2
	s.Transparency = 0.4
	s.Parent = f
	return f
end

-- ---------- build ----------
-- Builds the interface for a player and returns a handle. The handle carries every sub-widget plus
-- the small methods the other modules call (alerts, tide phase, Bog Baron, cash flashes).
local function build(player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "BogHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	local handle = {}
	handle.gui = gui

	-- ===== Bottom centre: cash + earnings rate =====
	local cashHolder = Instance.new("Frame")
	cashHolder.Name = "CashHolder"
	cashHolder.AnchorPoint = Vector2.new(0.5, 1)
	cashHolder.Position = UDim2.new(0.5, 0, 1, -24)
	cashHolder.Size = UDim2.fromOffset(460, 110)
	cashHolder.BackgroundTransparency = 1
	cashHolder.Parent = gui

	handle.cashLabel = label("Cash", cashHolder, "$0", Color3.fromRGB(120, 255, 140), MONEY_TEXT_SIZE)
	handle.cashLabel.AnchorPoint = Vector2.new(0.5, 0)
	handle.cashLabel.Position = UDim2.new(0.5, 0, 0, 0)
	handle.cashLabel.Size = UDim2.fromOffset(460, 60)

	handle.rateLabel = label("Rate", cashHolder, "$0 / second", Color3.fromRGB(200, 230, 200), 22)
	handle.rateLabel.AnchorPoint = Vector2.new(0.5, 0)
	handle.rateLabel.Position = UDim2.new(0.5, 0, 0, 62)
	handle.rateLabel.Size = UDim2.fromOffset(460, 26)

	-- ===== Top right: next Mud Tide countdown (kept clear of Roblox's top-left buttons) =====
	local tideBox = panel("TideBox", gui)
	tideBox.AnchorPoint = Vector2.new(1, 0)
	tideBox.Position = UDim2.new(1, -16, 0, 16)
	tideBox.Size = UDim2.fromOffset(220, 60)
	tideBox.BackgroundColor3 = Color3.fromRGB(30, 24, 18)
	tideBox.BackgroundTransparency = 0.15
	handle.tideBox = tideBox

	handle.tideTitle = label("TideTitle", tideBox, "NEXT MUD TIDE", Color3.fromRGB(220, 190, 150), 15)
	handle.tideTitle.Position = UDim2.new(0, 12, 0, 6)
	handle.tideTitle.Size = UDim2.fromOffset(196, 18)

	handle.tideCountdown = label("TideCountdown", tideBox, "--:--", Color3.fromRGB(255, 220, 170), 28)
	handle.tideCountdown.Position = UDim2.new(0, 12, 0, 26)
	handle.tideCountdown.Size = UDim2.fromOffset(196, 28)

	-- ===== Right column: deck slots and rebirth (under the tide box, clear of Roblox's top-left buttons) =====
	local statsBox = panel("StatsBox", gui)
	statsBox.AnchorPoint = Vector2.new(1, 0)
	statsBox.Position = UDim2.new(1, -16, 0, 88)
	statsBox.Size = UDim2.fromOffset(240, 96)
	statsBox.BackgroundColor3 = Color3.fromRGB(20, 24, 20)
	statsBox.BackgroundTransparency = 0.2
	handle.statsBox = statsBox

	handle.deckLabel = label("Deck", statsBox, "Deck 0 / 0", Color3.fromRGB(220, 230, 240), 20)
	handle.deckLabel.Position = UDim2.new(0, 12, 0, 10)
	handle.deckLabel.Size = UDim2.fromOffset(216, 24)

	handle.rebirthLabel = label("Rebirth", statsBox, "Rebirths 0  (+0%)", Color3.fromRGB(255, 200, 120), 20)
	handle.rebirthLabel.Position = UDim2.new(0, 12, 0, 44)
	handle.rebirthLabel.Size = UDim2.fromOffset(216, 24)

	handle.rebirthReady = label("RebirthReady", statsBox, "", Color3.fromRGB(255, 235, 120), 16)
	handle.rebirthReady.Position = UDim2.new(0, 12, 0, 70)
	handle.rebirthReady.Size = UDim2.fromOffset(216, 20)

	-- ===== Top middle: alert stack =====
	local alertStack = Instance.new("Frame")
	alertStack.Name = "AlertStack"
	alertStack.AnchorPoint = Vector2.new(0.5, 0)
	alertStack.Position = UDim2.new(0.5, 0, 0, 16)
	alertStack.Size = UDim2.fromOffset(420, 320)
	alertStack.BackgroundTransparency = 1
	alertStack.Parent = gui

	local alertLayout = Instance.new("UIListLayout")
	alertLayout.FillDirection = Enum.FillDirection.Vertical
	alertLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	alertLayout.SortOrder = Enum.SortOrder.LayoutOrder
	alertLayout.Padding = UDim.new(0, 8)
	alertLayout.Parent = alertStack

	handle.alertStack = alertStack
	handle.alerts = {} -- array of active alert frames, oldest first

	-- ===== Middle: Mud Tide banner + shrinking bar (hidden until a phase) =====
	local tideBanner = Instance.new("Frame")
	tideBanner.Name = "TideBanner"
	tideBanner.AnchorPoint = Vector2.new(0.5, 0.5)
	tideBanner.Position = UDim2.fromScale(0.5, 0.5)
	tideBanner.Size = UDim2.fromOffset(560, 92)
	tideBanner.BackgroundColor3 = Color3.fromRGB(70, 48, 26)
	tideBanner.BackgroundTransparency = 0.12
	tideBanner.BorderSizePixel = 0
	tideBanner.Visible = false
	tideBanner.Parent = gui
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 12)
	bc.Parent = tideBanner
	local bs = Instance.new("UIStroke")
	bs.Color = Color3.fromRGB(150, 110, 60)
	bs.Thickness = 3
	bs.Parent = tideBanner

	handle.tideBannerTitle = label("TideBannerTitle", tideBanner, "MUD TIDE", Color3.fromRGB(255, 230, 180), 34)
	handle.tideBannerTitle.AnchorPoint = Vector2.new(0.5, 0)
	handle.tideBannerTitle.Position = UDim2.new(0.5, 0, 0, 8)
	handle.tideBannerTitle.Size = UDim2.fromOffset(540, 40)

	local barBack = Instance.new("Frame")
	barBack.Name = "BarBack"
	barBack.AnchorPoint = Vector2.new(0.5, 0)
	barBack.Position = UDim2.new(0.5, 0, 0, 56)
	barBack.Size = UDim2.fromOffset(520, 18)
	barBack.BackgroundColor3 = Color3.fromRGB(40, 28, 16)
	barBack.BorderSizePixel = 0
	barBack.Parent = tideBanner
	local bbc = Instance.new("UICorner")
	bbc.CornerRadius = UDim.new(0, 8)
	bbc.Parent = barBack

	handle.tideBar = Instance.new("Frame")
	handle.tideBar.Name = "TideBar"
	handle.tideBar.Size = UDim2.fromScale(1, 1)
	handle.tideBar.BackgroundColor3 = Color3.fromRGB(200, 140, 60)
	handle.tideBar.BorderSizePixel = 0
	handle.tideBar.Parent = barBack
	local tbrc = Instance.new("UICorner")
	tbrc.CornerRadius = UDim.new(0, 8)
	tbrc.Parent = handle.tideBar

	handle.tideBanner = tideBanner
	handle.tidePhase = nil -- "warning" | "sweep" | "drain"
	handle.tideDeadline = nil -- os.clock() time the current phase ends
	handle.tideDuration = 1

	-- ===== Bog Baron full-screen overlay (hidden until fired) =====
	local baron = Instance.new("Frame")
	baron.Name = "BogBaron"
	baron.AnchorPoint = Vector2.new(0.5, 0.5)
	baron.Position = UDim2.fromScale(0.5, 0.5)
	baron.Size = UDim2.fromScale(1, 1)
	baron.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
	baron.BackgroundTransparency = 0.15
	baron.BorderSizePixel = 0
	baron.Visible = false
	baron.Parent = gui

	local baronCard = panel("BaronCard", baron, Color3.fromRGB(28, 22, 44))
	baronCard.AnchorPoint = Vector2.new(0.5, 0.5)
	baronCard.Position = UDim2.fromScale(0.5, 0.5)
	baronCard.Size = UDim2.fromOffset(560, 420)
	baronCard.BackgroundTransparency = 0.1

	local baronTitle = label("BaronTitle", baronCard, "BOG BARON", Color3.fromRGB(255, 215, 130), 44)
	baronTitle.AnchorPoint = Vector2.new(0.5, 0)
	baronTitle.Position = UDim2.new(0.5, 0, 0, 24)
	baronTitle.Size = UDim2.fromOffset(520, 54)
	baronTitle.TextScaled = true -- must fit a fixed box

	handle.baronSubtitle = label("BaronSubtitle", baronCard, "You dredged the bog dry.", Color3.fromRGB(220, 210, 240), 22)
	handle.baronSubtitle.AnchorPoint = Vector2.new(0.5, 0)
	handle.baronSubtitle.Position = UDim2.new(0.5, 0, 0, 86)
	handle.baronSubtitle.Size = UDim2.fromOffset(520, 28)

	handle.baronRebirths = label("BaronRebirths", baronCard, "Rebirths: 0", Color3.fromRGB(255, 200, 120), 26)
	handle.baronRebirths.AnchorPoint = Vector2.new(0.5, 0)
	handle.baronRebirths.Position = UDim2.new(0.5, 0, 0, 140)
	handle.baronRebirths.Size = UDim2.fromOffset(520, 32)

	handle.baronEarned = label("BaronEarned", baronCard, "Total earned: $0", Color3.fromRGB(140, 255, 160), 26)
	handle.baronEarned.AnchorPoint = Vector2.new(0.5, 0)
	handle.baronEarned.Position = UDim2.new(0.5, 0, 0, 184)
	handle.baronEarned.Size = UDim2.fromOffset(520, 32)

	handle.baronBest = label("BaronBest", baronCard, "Best catch: none", Color3.fromRGB(210, 200, 255), 24)
	handle.baronBest.AnchorPoint = Vector2.new(0.5, 0)
	handle.baronBest.Position = UDim2.new(0.5, 0, 0, 240)
	handle.baronBest.Size = UDim2.fromOffset(520, 60)
	handle.baronBest.TextWrapped = true

	-- Close button.
	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(0.5, 0)
	close.Position = UDim2.new(0.5, 0, 0, 330)
	close.Size = UDim2.fromOffset(220, 48)
	close.BackgroundColor3 = Color3.fromRGB(90, 60, 140)
	close.Text = "Close"
	close.TextColor3 = Color3.fromRGB(255, 240, 220)
	close.Font = FONT
	close.TextSize = 24
	close.Parent = baronCard
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 10)
	cc.Parent = close
	close.Activated:Connect(function()
		baron.Visible = false
	end)

	handle.baron = baron
	handle.baronCard = baronCard

	-- ---------- handle methods ----------
	-- A lighter cash update between full syncs; the server's CashTick sends just the number.
	function handle.updateCash(cash)
		if type(cash) ~= "number" then return end
		handle.cashLabel.Text = money(cash)
	end

	-- One alert card: colour-coded by kind, fades out, stacked by the UIListLayout.
	function handle.showAlert(kind, title, body)
		local color = ALERT_COLORS[kind] or ALERT_COLORS.info
		local card = panel("Alert", alertStack, Color3.fromRGB(16, 16, 20))
		card.Size = UDim2.fromOffset(400, 64)
		card.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
		card.BackgroundTransparency = 0.2

		local accent = Instance.new("Frame")
		accent.Name = "Accent"
		accent.Position = UDim2.new(0, 0, 0, 0)
		accent.Size = UDim2.new(0, 8, 1, 0)
		accent.BackgroundColor3 = color
		accent.BorderSizePixel = 0
		accent.Parent = card
		local ac = Instance.new("UICorner")
		ac.CornerRadius = UDim.new(0, 10)
		ac.Parent = accent

		local t = label("Title", card, title, color, 20)
		t.Position = UDim2.new(0, 18, 0, 8)
		t.Size = UDim2.fromOffset(372, 24)

		local b = label("Body", card, body or "", Color3.fromRGB(220, 220, 220), 17)
		b.Position = UDim2.new(0, 18, 0, 34)
		b.Size = UDim2.fromOffset(372, 22)
		b.TextWrapped = true

		local entry = { frame = card, born = os.clock(), fading = false }
		table.insert(handle.alerts, entry)
		-- Cap the stack so a burst of alerts cannot fill the screen.
		while #handle.alerts > 5 do
			local old = table.remove(handle.alerts, 1)
			if old.frame then old.frame:Destroy() end
		end
	end

	-- The Mud Tide banner across the middle. phase = "warning" | "sweep" | "drain".
	-- The server drives this entirely through the TideHorn phase event; no wall-clock guess.
	function handle.setTide(phase)
		handle.tidePhase = phase
		if phase == "warning" then
			handle.tideBanner.Visible = true
			handle.tideBannerTitle.Text = "MUD TIDE INCOMING - GET TO A RAFT"
			handle.tideBannerTitle.TextColor3 = Color3.fromRGB(255, 200, 120)
			handle.tideDuration = TIDE.Warning
			handle.tideDeadline = os.clock() + TIDE.Warning
		elseif phase == "sweep" then
			handle.tideBanner.Visible = true
			handle.tideBannerTitle.Text = "THE MUD TIDE SWEEPS"
			handle.tideBannerTitle.TextColor3 = Color3.fromRGB(255, 120, 90)
			handle.tideDuration = TIDE.SweepDuration
			handle.tideDeadline = os.clock() + TIDE.SweepDuration
		elseif phase == "drain" then
			-- The tide is over: hide the banner and restart the calm countdown.
			handle.tideBanner.Visible = false
			handle.tideDuration = TIDE.Interval
			handle.tideDeadline = os.clock() + TIDE.Interval
			handle.tideCountdown.TextColor3 = Color3.fromRGB(255, 220, 170)
		end
	end

	-- The Bog Baron full-screen overlay, filled from the latest state the server sent.
	function handle.showBogBaron()
		local s = handle.lastState
		handle.baronRebirths.Text = "Rebirths: " .. tostring(s and s.rebirths or 0)
		handle.baronEarned.Text = "Total earned: " .. money(s and s.totalEarned or 0)
		local bestText = "Best catch: none yet"
		if s and s.bestName then
			local rc = RARITY_COLORS[s.bestRarity] or Color3.fromRGB(210, 210, 210)
			handle.baronBest.TextColor3 = rc
			bestText = "Best catch: " .. s.bestName .. " (" .. tostring(s.bestRarity) .. ")"
		else
			handle.baronBest.TextColor3 = Color3.fromRGB(210, 210, 210)
		end
		handle.baronBest.Text = bestText
		handle.baron.Visible = true
	end

	-- ---------- the per-frame countdown + alert fade loop ----------
	local conns = {}
	conns[1] = RunService.Heartbeat:Connect(function()
		local now = os.clock()

		-- Tide countdown: only counts while a calm deadline is set (drain phase or startup).
		if handle.tideDeadline then
			local remain = handle.tideDeadline - now
			if handle.tidePhase == "drain" or handle.tidePhase == nil then
				if remain <= 0 then
					handle.tideCountdown.Text = "ANY MOMENT"
				else
					local secs = math.ceil(remain)
					handle.tideCountdown.Text = string.format("%d:%02d", math.floor(secs / 60), secs % 60)
				end
			end
		end

		-- Tide banner shrinking bar.
		if handle.tideBanner.Visible and handle.tideDeadline then
			local remain = handle.tideDeadline - now
			local frac = remain / handle.tideDuration
			frac = math.clamp(frac, 0, 1)
			handle.tideBar.Size = UDim2.fromScale(frac, 1)
			if remain <= 0 then
				handle.tideBanner.Visible = false
			end
		end

		-- Alert fade-out.
		for i = #handle.alerts, 1, -1 do
			local a = handle.alerts[i]
			local age = now - a.born
			if not a.fading and age >= ALERT_LIFETIME then
				a.fading = true
			end
			if a.fading then
				local t = math.clamp((age - ALERT_LIFETIME) / ALERT_FADE, 0, 1)
				a.frame.BackgroundTransparency = 0.2 + 0.8 * t
				for _, d in ipairs(a.frame:GetDescendants()) do
					if d:IsA("TextLabel") then
						d.TextTransparency = t
						d.TextStrokeTransparency = 0.6 + 0.4 * t
					elseif d:IsA("Frame") then
						d.BackgroundTransparency = t
					end
				end
				if t >= 1 then
					a.frame:Destroy()
					table.remove(handle.alerts, i)
				end
			end
		end
	end)

	handle.connections = conns
	return handle
end

-- ---------- update ----------
-- Takes a handle and a state table (exactly what the server sent) and redraws everything.
local function update(handle, state)
	if not handle or not state then return end
	handle.lastState = state

	handle.cashLabel.Text = money(state.cash)
	handle.rateLabel.Text = money(state.perSecond) .. " / second"

	local used = state.placed and #state.placed or 0
	handle.deckLabel.Text = "Deck " .. tostring(used) .. " / " .. tostring(state.deckSlotsOwned or 0)

	local rebirths = state.rebirths or 0
	local pct = math.floor(((state.multiplier or 1) - 1) * 100 + 0.5)
	handle.rebirthLabel.Text = "Rebirths " .. tostring(rebirths) .. "  (+" .. tostring(pct) .. "%)"

	if state.rebirthReady then
		handle.rebirthReady.Text = "REBIRTH READY at the Toll Booth"
		handle.rebirthReady.TextColor3 = Color3.fromRGB(255, 235, 120)
	else
		handle.rebirthReady.Text = ""
	end
end

return {
	build = build,
	update = update,
}
