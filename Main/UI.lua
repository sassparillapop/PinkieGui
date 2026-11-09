-- Main/UI.lua
-- Called by Loader.lua as: loadstring(uiRaw)()(allConfigs)
-- No script.Parent. No require(). Finds GUI through PlayerGui.

local featureConfigs = ...  -- passed in from Loader

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local lp      = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")
local gui     = playerGui:WaitForChild("HomeUI")
local win     = gui:WaitForChild("Window")
local uiScale = win:WaitForChild("WindowScale")
local topBar  = win:WaitForChild("TopBar")
local body    = win:WaitForChild("Body")
local side    = body:WaitForChild("Sidebar")
local content = body:WaitForChild("Content")
local indicator = side:WaitForChild("Indicator")
local toast   = win:WaitForChild("Toast")
local closeBtn = win:WaitForChild("CloseButton")
local minBtn  = topBar:WaitForChild("MinimizeButton")

local DARK      = Color3.fromRGB(38, 22, 52)
local PANEL     = Color3.fromRGB(38, 22, 52)
local ROW_BG    = Color3.fromRGB(30, 16, 42)
local DIM       = Color3.fromRGB(210, 170, 200)
local SOFT      = Color3.fromRGB(255, 160, 210)
local PINK      = Color3.fromRGB(255, 105, 180)
local PINK_DARK = Color3.fromRGB(190, 50, 130)
local OFF       = Color3.fromRGB(70, 50, 85)
local WHITE     = Color3.fromRGB(255, 255, 255)
local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

local globalConns = {}
local function G(signal, fn)
	local c = signal:Connect(fn)
	table.insert(globalConns, c)
	return c
end

local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj,
		TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function hover(btn, normal, over)
	btn.MouseEnter:Connect(function() tween(btn, 0.15, over) end)
	btn.MouseLeave:Connect(function() tween(btn, 0.2, normal) end)
end

local function newInst(cls, props, parent)
	local i = Instance.new(cls)
	for k, v in pairs(props) do i[k] = v end
	if parent then i.Parent = parent end
	return i
end

--------------------------------------------------------------------
-- Window
--------------------------------------------------------------------
local FULL_H = 568

local function fitScale()
	local cam = workspace.CurrentCamera
	local vp  = cam and cam.ViewportSize or Vector2.new(1280, 720)
	return math.clamp(math.min(vp.X * 0.8 / 1160, vp.Y * 0.82 / FULL_H), 0.35, 1.2)
end

local baseScale = fitScale()
local isOpen    = false
local openCount = 0
local unloading = false

local titleLabel = content:WaitForChild("HomePage"):WaitForChild("WelcomeBanner"):WaitForChild("Title")
local function updateGreeting()
	titleLabel.Text = openCount <= 1
		and "Welcome to Pinkie's gui!"
		or  "Welcome back, " .. lp.DisplayName .. "!"
end

local MINI        = gui:WaitForChild("MinimizedButton")
local miniScale   = MINI:WaitForChild("PopScale")
local miniStroke  = MINI:FindFirstChildOfClass("UIStroke")
local placeholder = MINI:FindFirstChild("Placeholder")
local homePos     = win.Position

local function syncPlaceholder()
	if placeholder then placeholder.Visible = (MINI.Image == "") end
end
syncPlaceholder()
MINI:GetPropertyChangedSignal("Image"):Connect(syncPlaceholder)

local function miniCenter()
	local p = MINI.Position
	return UDim2.new(p.X.Scale, p.X.Offset + MINI.Size.X.Offset / 2,
	                 p.Y.Scale, p.Y.Offset + MINI.Size.Y.Offset / 2)
end

local function clampMini()
	local W, H = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
	if W <= 0 or H <= 0 then return end
	local p, s = MINI.Position, MINI.Size.X.Offset
	MINI.Position = UDim2.fromOffset(
		math.clamp(p.X.Scale * W + p.X.Offset, 8, math.max(8, W - s - 8)),
		math.clamp(p.Y.Scale * H + p.Y.Offset, 8, math.max(8, H - s - 8))
	)
end

local function showWindow()
	if isOpen then return end
	isOpen = true; openCount += 1
	updateGreeting()
	local fromIcon = MINI.Visible
	if fromIcon then win.Position = miniCenter() end
	win.Visible = true
	if fromIcon then tween(win, 0.5, {Position = homePos}) end
	tween(uiScale, 0.5, {Scale = baseScale}, Enum.EasingStyle.Back)
	tween(miniScale, 0.18, {Scale = 0}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		.Completed:Once(function() if isOpen then MINI.Visible = false end end)
end

local function hideToIcon()
	if not isOpen then return end
	isOpen = false
	MINI.Visible = true; miniScale.Scale = 0
	tween(win, 0.35, {Position = miniCenter()}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(uiScale, 0.35, {Scale = 0}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		.Completed:Once(function()
			if not isOpen then
				win.Visible = false; win.Position = homePos
				tween(miniScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
			end
		end)
end

local function unloadUI()
	if unloading then return end
	unloading = true; isOpen = false; MINI.Visible = false
	tween(uiScale, 0.3, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		.Completed:Once(function()
			for _, c in ipairs(globalConns) do c:Disconnect() end
			gui:Destroy()
		end)
end

local cam = workspace.CurrentCamera
if cam then
	G(cam:GetPropertyChangedSignal("ViewportSize"), function()
		baseScale = fitScale()
		if isOpen then uiScale.Scale = baseScale end
		clampMini()
	end)
end

closeBtn.Activated:Connect(unloadUI)
minBtn.Activated:Connect(hideToIcon)

G(UserInputService.InputBegan, function(input, gp)
	if gp or unloading then return end
	if input.KeyCode == Enum.KeyCode.P then
		if isOpen then hideToIcon() else showWindow() end
	end
end)

local miniDragging, miniMoved, miniStart, miniOrigin = false, false, nil, nil
MINI.InputBegan:Connect(function(input)
	if isPress(input) then
		miniDragging, miniMoved = true, false
		miniStart = input.Position
		local W, H = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
		local p = MINI.Position
		miniOrigin = Vector2.new(p.X.Scale * W + p.X.Offset, p.Y.Scale * H + p.Y.Offset)
		tween(miniScale, 0.1, {Scale = 0.92})
	end
end)
G(UserInputService.InputChanged, function(input)
	if miniDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
	                  or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - miniStart
		if d.Magnitude > 6 then miniMoved = true end
		if miniMoved then
			local W, H = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
			local s = MINI.Size.X.Offset
			MINI.Position = UDim2.fromOffset(
				math.clamp(miniOrigin.X + d.X, 8, math.max(8, W - s - 8)),
				math.clamp(miniOrigin.Y + d.Y, 8, math.max(8, H - s - 8))
			)
		end
	end
end)
G(UserInputService.InputEnded, function(input)
	if miniDragging and isPress(input) then
		miniDragging = false
		tween(miniScale, 0.2, {Scale = 1}, Enum.EasingStyle.Back)
		if not miniMoved then showWindow() end
	end
end)

hover(closeBtn, {BackgroundColor3 = PANEL, TextColor3 = SOFT}, {BackgroundColor3 = PINK, TextColor3 = DARK})
hover(minBtn,   {BackgroundColor3 = PANEL},                    {BackgroundColor3 = Color3.fromRGB(70, 36, 92)})
MINI.MouseEnter:Connect(function() if miniStroke then tween(miniStroke, 0.15, {Color = SOFT}) end end)
MINI.MouseLeave:Connect(function() if miniStroke then tween(miniStroke, 0.2,  {Color = PINK}) end end)

local dragging, dragStart, startPos
topBar.InputBegan:Connect(function(input)
	if isPress(input) then dragging = true; dragStart = input.Position; startPos = win.Position end
end)
G(UserInputService.InputChanged, function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
	              or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
		                         startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
G(UserInputService.InputEnded, function(input)
	if isPress(input) then
		if dragging then homePos = win.Position end
		dragging = false
	end
end)

--------------------------------------------------------------------
-- Tab system
--------------------------------------------------------------------
local tabs, buttons, labels = {}, {}, {}
do
	local list = {}
	for _, c in ipairs(side:GetChildren()) do
		if c:IsA("TextButton") and c.Name:match("Button$") then table.insert(list, c) end
	end
	table.sort(list, function(a, b) return a.Position.Y.Offset < b.Position.Y.Offset end)
	for _, b in ipairs(list) do
		local n = b.Name:gsub("Button$", "")
		table.insert(tabs, n); buttons[n] = b; labels[n] = b:FindFirstChild("Text")
	end
end

local order = {}
for i, n in ipairs(tabs) do order[n] = i end
order.Updates = (order.Home or 1) + 0.5

local pageNames = table.clone(tabs)
table.insert(pageNames, "Updates")
local pages, stagger = {}, {}
for _, n in ipairs(pageNames) do
	local pg = content:FindFirstChild(n .. "Page")
	if pg then
		pages[n] = pg; stagger[n] = {}
		for _, d in ipairs(pg:GetDescendants()) do
			if d:GetAttribute("Stagger") then
				table.insert(stagger[n], {obj = d, pos = d.Position})
			end
		end
	end
end

local current    = pages.Home and "Home" or tabs[1]
local currentTab = current
local BASE       = UDim2.fromOffset(-4, -4)

for _, n in ipairs(tabs) do
	local b = buttons[n]; local active = (n == currentTab)
	labels[n].TextColor3 = active and DARK or DIM
	b.Icon.Position      = UDim2.fromOffset(active and 14 or 10, 0)
end
indicator.Position = UDim2.fromOffset(12, buttons[currentTab].Position.Y.Offset)
for n, pg in pairs(pages) do
	pg.Visible = (n == current); pg.GroupTransparency = 0; pg.Position = BASE
end

local function playEnter(name)
	for i, e in ipairs(stagger[name] or {}) do
		e.obj.Position = e.pos + UDim2.fromOffset(0, 26)
		task.delay(0.06 * (i - 1) + 0.05, function() tween(e.obj, 0.5, {Position = e.pos}) end)
	end
	if name == "Stats" and pages.Stats then
		local fb = pages.Stats:FindFirstChild("XPFill", true)
		if fb then
			fb.Size = UDim2.new(0, 0, 1, 0)
			task.delay(0.35, function() tween(fb, 0.9, {Size = UDim2.new(0.65, 0, 1, 0)}) end)
		end
	end
end

local function switchTo(name)
	if name == current or not pages[name] then return end
	local prev = current; current = name
	local old, new = pages[prev], pages[name]
	local dir = (order[name] > order[prev]) and 1 or -1
	local tab = (name == "Updates") and "Home" or name
	if tab ~= currentTab and buttons[tab] then
		local prevTab = currentTab; currentTab = tab
		tween(indicator,             0.45, {Position = UDim2.fromOffset(12, buttons[tab].Position.Y.Offset)}, Enum.EasingStyle.Back)
		tween(labels[prevTab],       0.25, {TextColor3 = DIM})
		tween(labels[tab],           0.25, {TextColor3 = DARK})
		tween(buttons[prevTab].Icon, 0.3,  {Position = UDim2.fromOffset(10, 0)})
		tween(buttons[tab].Icon,     0.3,  {Position = UDim2.fromOffset(14, 0)}, Enum.EasingStyle.Back)
	end
	tween(old, 0.2, {GroupTransparency = 1, Position = BASE + UDim2.fromOffset(0, -20 * dir)},
		Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		.Completed:Once(function() if pages[current] ~= old then old.Visible = false end end)
	new.Position = BASE + UDim2.fromOffset(0, 26 * dir)
	new.GroupTransparency = 1; new.Visible = true
	task.delay(0.12, function()
		if current ~= name then return end
		tween(new, 0.45, {GroupTransparency = 0, Position = BASE}); playEnter(name)
	end)
end

for _, n in ipairs(tabs) do
	local b = buttons[n]
	b.Activated:Connect(function() switchTo(n) end)
	b.MouseEnter:Connect(function() if n ~= currentTab then tween(labels[n], 0.15, {TextColor3 = SOFT}) end end)
	b.MouseLeave:Connect(function() if n ~= currentTab then tween(labels[n], 0.2,  {TextColor3 = DIM})  end end)
end

if pages.Home and pages.Updates then
	local seeAll = pages.Home:FindFirstChild("SeeAllButton", true)
	if seeAll then seeAll.Activated:Connect(function() switchTo("Updates") end) end
	local cardBtn = pages.Home:FindFirstChild("CardButton", true)
	if cardBtn then
		local card = cardBtn.Parent
		cardBtn.Activated:Connect(function() switchTo("Updates") end)
		cardBtn.MouseEnter:Connect(function() tween(card, 0.15, {BackgroundColor3 = Color3.fromRGB(42, 24, 58)}) end)
		cardBtn.MouseLeave:Connect(function() tween(card, 0.2,  {BackgroundColor3 = Color3.fromRGB(30, 16, 42)}) end)
	end
	local back = pages.Updates:FindFirstChild("BackButton", true)
	if back then back.Activated:Connect(function() switchTo("Home") end) end
end

local toastClose = toast:FindFirstChild("CloseButton")
if toastClose then
	toastClose.Activated:Connect(function()
		tween(toast, 0.35,
			{Position = toast.Position + UDim2.fromOffset(-40, 0), BackgroundTransparency = 1},
			Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			.Completed:Once(function() toast.Visible = false end)
	end)
end

--------------------------------------------------------------------
-- Widget builders
--------------------------------------------------------------------
local ROW_H, ROW_W, ROW_X, PAD_Y = 68, 790, 20, 60

local function makeRow(panel, rowOrder)
	local row = newInst("Frame", {
		Name = "Row_" .. rowOrder, Size = UDim2.fromOffset(ROW_W, ROW_H),
		Position = UDim2.fromOffset(ROW_X, PAD_Y + (rowOrder - 1) * (ROW_H + 8)),
		BackgroundColor3 = ROW_BG, BorderSizePixel = 0, ZIndex = 2,
	}, panel)
	newInst("UICorner", {CornerRadius = UDim.new(0, 10)}, row)
	newInst("UIStroke", {Color = PINK_DARK, Thickness = 1.5}, row)
	row:SetAttribute("Stagger", true)
	return row
end

local function makeLabel(parent, text)
	return newInst("TextLabel", {
		Size = UDim2.fromOffset(360, ROW_H), Position = UDim2.fromOffset(24, 0),
		BackgroundTransparency = 1, Text = text, TextColor3 = WHITE,
		FontFace = FONT_BOLD, TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
end

local function buildToggle(panel, cfg)
	local row = makeRow(panel, cfg.order)
	makeLabel(row, cfg.label)

	local stateLbl = newInst("TextLabel", {
		Size = UDim2.fromOffset(60, ROW_H), Position = UDim2.fromOffset(ROW_W - 160, 0),
		BackgroundTransparency = 1, Text = "Off", TextColor3 = DIM,
		FontFace = FONT_BOLD, TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center,
	}, row)

	local toggleBtn = newInst("TextButton", {
		Size = UDim2.fromOffset(64, 32), Position = UDim2.fromOffset(ROW_W - 86, (ROW_H - 32) / 2),
		BackgroundColor3 = OFF, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 3,
	}, row)
	newInst("UICorner", {CornerRadius = UDim.new(1, 0)}, toggleBtn)
	toggleBtn:SetAttribute("On", cfg.default == true)

	local knob = newInst("Frame", {
		Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(4, 4),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4,
	}, toggleBtn)
	newInst("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

	local function render(animate)
		local on = toggleBtn:GetAttribute("On") == true
		local kp = UDim2.fromOffset(on and 36 or 4, 4)
		if animate then
			tween(knob, 0.3, {Position = kp}, Enum.EasingStyle.Back)
			tween(toggleBtn, 0.25, {BackgroundColor3 = on and PINK or OFF})
		else
			knob.Position = kp; toggleBtn.BackgroundColor3 = on and PINK or OFF
		end
		stateLbl.Text = on and "On" or "Off"
		tween(stateLbl, 0.2, {TextColor3 = on and SOFT or DIM})
	end

	toggleBtn.Activated:Connect(function()
		local newState = not (toggleBtn:GetAttribute("On") == true)
		toggleBtn:SetAttribute("On", newState)
		render(true)
		if cfg.onChange then cfg.onChange(newState) end
	end)
	render(false)
	return toggleBtn
end

local function buildDropdown(panel, cfg)
	local row = makeRow(panel, cfg.order)
	makeLabel(row, cfg.label)
	local options = cfg.options or {}
	local selected = options[1] or "Select..."

	local dropBtn = newInst("TextButton", {
		Size = UDim2.fromOffset(220, 36), Position = UDim2.fromOffset(ROW_W - 240, (ROW_H - 36) / 2),
		BackgroundColor3 = Color3.fromRGB(50, 28, 70), BorderSizePixel = 0,
		Text = selected .. "  ▾", TextColor3 = SOFT, FontFace = FONT_BOLD, TextSize = 18,
		AutoButtonColor = false, ZIndex = 5,
	}, row)
	newInst("UICorner", {CornerRadius = UDim.new(0, 8)}, dropBtn)
	newInst("UIStroke", {Color = PINK_DARK, Thickness = 1.5}, dropBtn)

	local listFrame = newInst("Frame", {
		Size = UDim2.fromOffset(220, 0),
		Position = UDim2.fromOffset(ROW_W - 240, (ROW_H - 36) / 2 + 40),
		BackgroundColor3 = Color3.fromRGB(40, 20, 58), BorderSizePixel = 0,
		Visible = false, ZIndex = 10, ClipsDescendants = true,
	}, row)
	newInst("UICorner",     {CornerRadius = UDim.new(0, 8)},      listFrame)
	newInst("UIStroke",     {Color = PINK_DARK, Thickness = 1.5}, listFrame)
	newInst("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, listFrame)

	local ddOpen = false
	local fullH  = #options * 38 + 8

	local function closeList()
		ddOpen = false
		tween(listFrame, 0.18, {Size = UDim2.fromOffset(220, 0)},
			Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			.Completed:Once(function() listFrame.Visible = false end)
	end
	local function openList()
		ddOpen = true; listFrame.Visible = true
		tween(listFrame, 0.22, {Size = UDim2.fromOffset(220, fullH)}, Enum.EasingStyle.Back)
	end

	for idx, opt in ipairs(options) do
		local item = newInst("TextButton", {
			Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(40, 20, 58),
			BorderSizePixel = 0, Text = opt, TextColor3 = DIM,
			FontFace = FONT_BOLD, TextSize = 17, AutoButtonColor = false,
			LayoutOrder = idx, ZIndex = 11,
		}, listFrame)
		item.MouseEnter:Connect(function() tween(item, 0.12, {BackgroundColor3 = Color3.fromRGB(80, 40, 100), TextColor3 = WHITE}) end)
		item.MouseLeave:Connect(function() tween(item, 0.15, {BackgroundColor3 = Color3.fromRGB(40, 20, 58), TextColor3 = DIM})   end)
		item.Activated:Connect(function()
			selected = opt; dropBtn.Text = opt .. "  ▾"; closeList()
			if cfg.onChange then cfg.onChange(opt) end
		end)
	end

	dropBtn.Activated:Connect(function() if ddOpen then closeList() else openList() end end)
	hover(dropBtn, {BackgroundColor3 = Color3.fromRGB(50, 28, 70)}, {BackgroundColor3 = Color3.fromRGB(70, 40, 95)})
	return dropBtn
end

local function buildTextInput(panel, cfg)
	local row = makeRow(panel, cfg.order)
	makeLabel(row, cfg.label)

	local box = newInst("TextBox", {
		Size = UDim2.fromOffset(300, 36), Position = UDim2.fromOffset(ROW_W - 320, (ROW_H - 36) / 2),
		BackgroundColor3 = Color3.fromRGB(30, 14, 44), BorderSizePixel = 0,
		PlaceholderText = cfg.placeholder or "Enter value...",
		PlaceholderColor3 = Color3.fromRGB(140, 100, 150),
		Text = "", TextColor3 = WHITE, FontFace = FONT_BOLD, TextSize = 17,
		ClearTextOnFocus = false, ZIndex = 5,
	}, row)
	newInst("UICorner", {CornerRadius = UDim.new(0, 8)}, box)
	local stroke = newInst("UIStroke", {Color = PINK_DARK, Thickness = 1.5}, box)

	box.Focused:Connect(function()  tween(stroke, 0.2, {Color = PINK}) end)
	box.FocusLost:Connect(function()
		tween(stroke, 0.2, {Color = PINK_DARK})
		if cfg.onSubmit then cfg.onSubmit(box.Text) end
	end)
	return box
end

local function buildSlider(panel, cfg)
	local row = makeRow(panel, cfg.order)
	makeLabel(row, cfg.label)
	local minVal, maxVal = cfg.min or 0, cfg.max or 100

	local valueLbl = newInst("TextLabel", {
		Size = UDim2.fromOffset(50, ROW_H), Position = UDim2.fromOffset(ROW_W - 310, 0),
		BackgroundTransparency = 1, Text = tostring(minVal), TextColor3 = SOFT,
		FontFace = FONT_BOLD, TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center,
	}, row)

	local hit = newInst("TextButton", {
		Size = UDim2.fromOffset(240, ROW_H), Position = UDim2.fromOffset(ROW_W - 256, 0),
		BackgroundTransparency = 1, Text = "", ZIndex = 5, AutoButtonColor = false,
	}, row)

	local track = newInst("Frame", {
		Size = UDim2.fromOffset(220, 6), Position = UDim2.new(0, 10, 0.5, -3),
		BackgroundColor3 = OFF, BorderSizePixel = 0, ZIndex = 3,
	}, hit)
	newInst("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
	local fill = newInst("Frame", {
		Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = PINK, BorderSizePixel = 0, ZIndex = 4,
	}, track)
	newInst("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
	local knob = newInst("Frame", {
		Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 5,
	}, track)
	newInst("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

	local sliderDragging = false
	local function setFromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		fill.Size = UDim2.new(rel, 0, 1, 0); knob.Position = UDim2.new(rel, 0, 0.5, 0)
		local v = math.floor(rel * (maxVal - minVal) + minVal + 0.5)
		valueLbl.Text = tostring(v); hit:SetAttribute("Value", v)
		if cfg.onChange then cfg.onChange(v) end
	end

	hit.InputBegan:Connect(function(input)
		if isPress(input) then
			sliderDragging = true; setFromX(input.Position.X)
			tween(knob, 0.15, {Size = UDim2.fromOffset(28, 28)}, Enum.EasingStyle.Back)
		end
	end)
	G(UserInputService.InputChanged, function(input)
		if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		                    or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	G(UserInputService.InputEnded, function(input)
		if sliderDragging and isPress(input) then
			sliderDragging = false; tween(knob, 0.2, {Size = UDim2.fromOffset(22, 22)})
		end
	end)
	return hit
end

local function buildButton(panel, cfg)
	local row = makeRow(panel, cfg.order)
	makeLabel(row, cfg.label)

	local btn = newInst("TextButton", {
		Size = UDim2.fromOffset(160, 38), Position = UDim2.fromOffset(ROW_W - 180, (ROW_H - 38) / 2),
		BackgroundColor3 = PINK_DARK, BorderSizePixel = 0,
		Text = cfg.buttonText or "Run", TextColor3 = WHITE,
		FontFace = FONT_BOLD, TextSize = 18, AutoButtonColor = false, ZIndex = 5,
	}, row)
	newInst("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
	local sc = newInst("UIScale", {Scale = 1}, btn)
	hover(btn, {BackgroundColor3 = PINK_DARK}, {BackgroundColor3 = PINK})
	btn.Activated:Connect(function()
		sc.Scale = 0.92; tween(sc, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
		if cfg.onActivate then cfg.onActivate() end
	end)
	return btn
end

--------------------------------------------------------------------
-- Inject features
--------------------------------------------------------------------
for _, cfg in ipairs(featureConfigs) do
	local page = content:FindFirstChild(cfg.page .. "Page")
	if not page then
		warn("UI: no page '" .. cfg.page .. "Page' for '" .. tostring(cfg.label) .. "'")
		continue
	end
	local panel = page:FindFirstChild(cfg.page .. "Panel")
	if not panel then
		warn("UI: no panel '" .. cfg.page .. "Panel'")
		continue
	end

	if     cfg.type == "toggle"    then buildToggle(panel, cfg)
	elseif cfg.type == "dropdown"  then buildDropdown(panel, cfg)
	elseif cfg.type == "textinput" then buildTextInput(panel, cfg)
	elseif cfg.type == "slider"    then buildSlider(panel, cfg)
	elseif cfg.type == "button"    then buildButton(panel, cfg)
	else   warn("UI: unknown type '" .. tostring(cfg.type) .. "'")
	end
end

--------------------------------------------------------------------
-- Boot
--------------------------------------------------------------------
uiScale.Scale = 0
showWindow()
playEnter(current)
