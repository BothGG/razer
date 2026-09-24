-- Delta Hub
-- Self-contained Roblox UI. No Rayfield, no remote UI library, no external scripts.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("DeltaHub")
if oldGui then oldGui:Destroy() end

-- Prefer the executor's protected UI container when available, with PlayerGui as fallback.
local guiParent = playerGui
if type(gethui) == "function" then
	local ok, protectedGui = pcall(gethui)
	if ok and protectedGui then guiParent = protectedGui end
end

local C = {
	bg = Color3.fromRGB(6, 8, 13),
	panel = Color3.fromRGB(10, 14, 23),
	card = Color3.fromRGB(15, 21, 33),
	line = Color3.fromRGB(29, 51, 79),
	text = Color3.fromRGB(242, 247, 255),
	muted = Color3.fromRGB(130, 148, 174),
	accent = Color3.fromRGB(45, 137, 255),
	accentDark = Color3.fromRGB(22, 77, 155),
	success = Color3.fromRGB(71, 218, 157),
}

local function make(className, props, parent)
	local object = Instance.new(className)
	for key, value in pairs(props or {}) do object[key] = value end
	object.Parent = parent
	return object
end

local function round(object, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, object)
end

local function outline(object, color)
	make("UIStroke", { Color = color or C.line, Thickness = 1, Transparency = 0.1 }, object)
end

local function text(parent, value, size, color, font)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Text = value,
		TextColor3 = color or C.text,
		TextSize = size or 14,
		Font = font or Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
end

local Gui = make("ScreenGui", {
	Name = "DeltaHub",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

-- Boot screen: if construction stops early, this remains visible instead of failing silently.
local Boot = make("Frame", {
	AnchorPoint = Vector2.new(.5, .5),
	Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromOffset(300, 112),
	BackgroundColor3 = C.panel,
	ZIndex = 50,
}, Gui)
round(Boot, 10)
outline(Boot, C.accent)
local bootTitle = text(Boot, "DELTA HUB", 17, C.text, Enum.Font.GothamBold)
bootTitle.Position, bootTitle.Size = UDim2.fromOffset(20, 18), UDim2.new(1, -40, 0, 25)
bootTitle.ZIndex = 51
local bootStatus = text(Boot, "INITIALIZING INTERFACE...", 10, C.muted, Enum.Font.GothamMedium)
bootStatus.Position, bootStatus.Size = UDim2.fromOffset(21, 52), UDim2.new(1, -42, 0, 18)
bootStatus.ZIndex = 51
local bootBar = make("Frame", { Position = UDim2.fromOffset(20, 82), Size = UDim2.new(1, -40, 0, 4), BackgroundColor3 = C.line, BorderSizePixel = 0, ZIndex = 51 }, Boot)
round(bootBar, 4)
local bootProgress = make("Frame", { Size = UDim2.new(.35, 0, 1, 0), BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 52 }, bootBar)
round(bootProgress, 4)

local Main = make("Frame", {
	AnchorPoint = Vector2.new(.5, .5),
	Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromOffset(720, 460),
	BackgroundColor3 = C.bg,
	ClipsDescendants = true,
}, Gui)
round(Main, 12)
outline(Main)

local Top = make("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = C.panel, BorderSizePixel = 0 }, Main)
make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 20, 35)),
		ColorSequenceKeypoint.new(0.55, C.panel),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 12, 20)),
	}),
	Rotation = 0,
}, Top)
make("Frame", { Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 2 }, Top)
local brand = text(Top, "DELTA", 19, C.text, Enum.Font.GothamBold)
brand.Position, brand.Size = UDim2.fromOffset(24, 9), UDim2.fromOffset(130, 25)
local subtitle = text(Top, "CONTROL CENTER", 10, C.muted, Enum.Font.GothamMedium)
subtitle.Position, subtitle.Size = UDim2.fromOffset(25, 34), UDim2.fromOffset(150, 16)
local dot = make("Frame", { Position = UDim2.new(1, -112, 0, 25), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.success }, Top)
round(dot, 8)
local online = text(Top, "ONLINE", 11, C.success, Enum.Font.GothamBold)
online.Position, online.Size = UDim2.new(1, -96, 0, 18), UDim2.fromOffset(70, 22)

local Sidebar = make("Frame", { Position = UDim2.fromOffset(0, 64), Size = UDim2.fromOffset(174, 396), BackgroundColor3 = C.panel, BorderSizePixel = 0 }, Main)
local Content = make("Frame", { Position = UDim2.fromOffset(174, 64), Size = UDim2.new(1, -174, 1, -64), BackgroundColor3 = C.bg, BorderSizePixel = 0 }, Main)
local navLabel = text(Sidebar, "WORKSPACE", 9, C.muted, Enum.Font.GothamBold)
navLabel.Position, navLabel.Size = UDim2.fromOffset(18, 12), UDim2.fromOffset(130, 18)
navLabel.TextTransparency = 0.15

local pages = {}
local tabs = {}
local function page(name)
	local result = make("ScrollingFrame", {
		Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0), Visible = false,
	}, Content)
	make("UIPadding", { PaddingTop = UDim.new(0, 24), PaddingBottom = UDim.new(0, 24), PaddingLeft = UDim.new(0, 28), PaddingRight = UDim.new(0, 28) }, result)
	make("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, result)
	pages[name] = result
	return result
end

local function selectTab(name)
	for pageName, item in pairs(pages) do item.Visible = pageName == name end
	for tabName, item in pairs(tabs) do
		item.BackgroundColor3 = tabName == name and C.accentDark or C.panel
		item.TextColor3 = tabName == name and C.text or C.muted
	end
end

local function tab(name, caption, order)
	local item = make("TextButton", {
		Name = name, Position = UDim2.fromOffset(12, 42 + (order - 1) * 48), Size = UDim2.new(1, -24, 0, 40),
		BackgroundColor3 = C.panel, BorderSizePixel = 0, Text = "  " .. caption,
		TextColor3 = C.muted, TextSize = 13, Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
	}, Sidebar)
	round(item, 7)
	item.MouseButton1Click:Connect(function() selectTab(name) end)
	tabs[name] = item
end

local function section(parent, title, description)
	local header = make("Frame", { Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1 }, parent)
	local titleLabel = text(header, title, 19, C.text, Enum.Font.GothamBold)
	titleLabel.Size = UDim2.new(1, 0, 0, 25)
	local desc = text(header, description or "", 12, C.muted)
	desc.Position, desc.Size = UDim2.fromOffset(0, 25), UDim2.new(1, 0, 0, 18)
end

local function card(parent, title, description)
	local result = make("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = C.card }, parent)
	round(result, 8); outline(result)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 28, 45)),
			ColorSequenceKeypoint.new(1, C.card),
		}),
		Rotation = 25,
	}, result)
	make("Frame", { Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(2, 42), BackgroundColor3 = C.accent, BorderSizePixel = 0 }, result)
	local titleLabel = text(result, title, 13, C.text, Enum.Font.GothamMedium)
	titleLabel.Position, titleLabel.Size = UDim2.fromOffset(16, 8), UDim2.new(1, -150, 0, 22)
	local desc = text(result, description or "", 11, C.muted)
	desc.Position, desc.Size = UDim2.fromOffset(16, 31), UDim2.new(1, -150, 0, 18)
	return result
end

local function notify(title, message, color)
	local toast = make("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -24), Size = UDim2.fromOffset(300, 64), BackgroundColor3 = C.card, ZIndex = 10 }, Gui)
	round(toast, 10); outline(toast, color or C.accent)
	make("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = color or C.accent, BorderSizePixel = 0, ZIndex = 11 }, toast)
	local heading = text(toast, title, 13, C.text, Enum.Font.GothamBold); heading.Position, heading.Size = UDim2.fromOffset(18, 8), UDim2.new(1, -28, 0, 18); heading.ZIndex = 11
	local body = text(toast, message, 12, C.muted); body.Position, body.Size = UDim2.fromOffset(18, 29), UDim2.new(1, -28, 0, 22); body.ZIndex = 11
	task.delay(3.5, function() if toast.Parent then toast:Destroy() end end)
end

local buttonCounts = {}
local function button(parent, caption, callback, width)
	width = width or 86
	buttonCounts[parent] = (buttonCounts[parent] or 0) + 1
	local offset = 14 + (buttonCounts[parent] - 1) * (width + 6)
	local item = make("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -offset, .5, 0), Size = UDim2.fromOffset(width, 34), BackgroundColor3 = C.accentDark, Text = caption, TextColor3 = C.text, TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false }, parent)
	round(item, 6)
	make("UIGradient", {
		Color = ColorSequence.new(C.accent, C.accentDark),
		Rotation = 90,
	}, item)
	item.MouseEnter:Connect(function() item.BackgroundColor3 = C.accent end)
	item.MouseLeave:Connect(function() item.BackgroundColor3 = C.accentDark end)
	item.MouseButton1Click:Connect(callback); return item
end

local function humanoid()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local Home = page("Home")
section(Home, "Welcome back.", "A focused workspace for your local utilities.")
local ready = card(Home, "Delta Hub is ready", "Everything here is built into this script and stays lightweight.")
button(ready, "Got it", function() notify("Delta Hub", "You are all set.", C.success) end)
local quick = card(Home, "Quick start", "Use the Player tab to adjust movement and flight.")
button(quick, "Player", function() selectTab("Player") end)
local expedition = card(Home, "Expedition status", "Meadow Zone  •  No egg carried  •  Returned 0 / Collected 0")
button(expedition, "Preview", function()
	notify("Expedition status", "No active expedition. This is a UI preview.", C.accent)
end, 76)

local Player = page("Player")
section(Player, "Player utilities", "Changes apply to your current character.")
local speed = card(Player, "Walk speed", "Default Roblox speed is 16.")
button(speed, "16", function() local h = humanoid(); if h then h.WalkSpeed = 16; notify("Walk speed", "Reset to default.") end end, 54)
button(speed, "32", function() local h = humanoid(); if h then h.WalkSpeed = 32; notify("Walk speed", "Set to 32.", C.success) end end, 54)
local jump = card(Player, "Jump power", "Default Roblox jump power is 50.")
button(jump, "50", function() local h = humanoid(); if h then h.JumpPower = 50; notify("Jump power", "Reset to default.") end end, 54)
button(jump, "100", function() local h = humanoid(); if h then h.JumpPower = 100; notify("Jump power", "Set to 100.", C.success) end end, 54)

local flying = false
local flyConnection
local flyObjects = {}
local flight = card(Player, "Flight mode", "Use WASD and Space / LeftControl while active.")
button(flight, "Toggle", function()
	flying = not flying
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local h = humanoid()
	if not root or not h then flying = false; return end
	if flying then
		local gyro = make("BodyGyro", { P = 90000, MaxTorque = Vector3.new(9e9, 9e9, 9e9), CFrame = root.CFrame }, root)
		local velocity = make("BodyVelocity", { MaxForce = Vector3.new(9e9, 9e9, 9e9), Velocity = Vector3.zero }, root)
		flyObjects = { gyro, velocity }
		flyConnection = RunService.RenderStepped:Connect(function()
			if not root.Parent then return end
			local vertical = 0
			if UIS:IsKeyDown(Enum.KeyCode.Space) then vertical += 1 end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vertical -= 1 end
			velocity.Velocity = (h.MoveDirection + Vector3.new(0, vertical, 0)) * 55
			gyro.CFrame = workspace.CurrentCamera.CFrame
		end)
		notify("Flight mode", "Enabled.", C.success)
	else
		if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
		for _, object in ipairs(flyObjects) do if object.Parent then object:Destroy() end end
		flyObjects = {}
		notify("Flight mode", "Disabled.")
	end
end, 72)

local Server = page("Server")
section(Server, "Server controls", "Quick session actions.")
local rejoin = card(Server, "Rejoin current server", "Reconnect to this experience.")
button(rejoin, "Rejoin", function() TeleportService:Teleport(game.PlaceId, player) end)
local leave = card(Server, "Leave session", "Return to the Roblox home screen.")
button(leave, "Leave", function() player:Kick("Delta Hub session closed.") end)

local Settings = page("Settings")
section(Settings, "Settings", "Manage the interface.")
local hide = card(Settings, "Toggle interface", "Press RightShift at any time.")
button(hide, "Hide", function() Main.Visible = false end)
local close = card(Settings, "Close Delta Hub", "Remove the interface from this session.")
button(close, "Close", function() Gui:Destroy() end)

tab("Home", "Overview", 1)
tab("Player", "Player", 2)
tab("Server", "Server", 3)
tab("Settings", "Settings", 4)
selectTab("Home")

-- Drag the window from the top bar.
local dragging, dragStart, startPosition
Top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPosition = true, input.Position, Main.Position
	end
end)
Top.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
	end
end)

UIS.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.RightShift then Main.Visible = not Main.Visible end
end)

player.CharacterAdded:Connect(function()
	flying = false
	if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
	for _, object in ipairs(flyObjects) do if object.Parent then object:Destroy() end end
	flyObjects = {}
end)

bootStatus.Text = "READY  •  PRESS RIGHTSHIFT TO HIDE"
bootStatus.TextColor3 = C.success
bootProgress.Size = UDim2.fromScale(1, 1)
task.wait(0.25)
Boot:Destroy()
notify("Delta Hub", "Ready. Press RightShift to hide or show.", C.success)
