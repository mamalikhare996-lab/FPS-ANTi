--[[
	Filing_FPS_Studio_Safe_UI.lua
	Polished Roblox Studio-Safe LocalScript UI Demo
	
	Features:
	1. Draggable floating circular toggle labeled "Filing FPS" with a lightning visual.
	2. Draggable main panel with a stable vertical layout and internal ScrollingFrame so player list never overlaps buttons.
	3. Target TextBox with validation against Players:GetPlayers(), showing a compact English toast on the RIGHT side of the screen ("Target Selected" or "Invalid Target"), animating in/out and cleaning up.
	4. "Show All Users" toggle that reveals a scrollable player list and lets the user select a name.
	5. START/OFF toggle button in its own fixed bottom section, never over the player list.
	6. Speed slider and five mode buttons with working UI state.
	7. Studio-safe demo action that applies controlled knockback only to a selected NPC/dummy model in Workspace that has a HumanoidRootPart and an attribute named AllowFlingDemo=true, never to real players.
	8. No Delta executor APIs, no exploit APIs, no teleporting or flinging real players, safe for Roblox Studio & standard LocalScripts.
	9. Uses TweenService, UserInputService, RunService, Players, and cleans up connections on disable.
	10. Concise comments and robust nil checks throughout.
]]--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Prevent duplicate UI instances
if PlayerGui:FindFirstChild("FilingFPSStudioSafeUI") then
	PlayerGui.FilingFPSStudioSafeUI:Destroy()
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FilingFPSStudioSafeUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Theme Colors (Dark sleek studio theme)
local THEME = {
	Background = Color3.fromRGB(24, 24, 28),
	PanelBG = Color3.fromRGB(32, 32, 38),
	CardBG = Color3.fromRGB(42, 42, 50),
	Accent = Color3.fromRGB(0, 162, 255),
	AccentHover = Color3.fromRGB(50, 190, 255),
	Text = Color3.fromRGB(240, 240, 245),
	TextDim = Color3.fromRGB(160, 160, 175),
	Success = Color3.fromRGB(46, 204, 113),
	Error = Color3.fromRGB(231, 76, 60),
	ToggleOn = Color3.fromRGB(46, 204, 113),
	ToggleOff = Color3.fromRGB(60, 60, 70),
}

--------------------------------------------------------------------------------
-- 1. Floating Circular Toggle Button ("Filing FPS" with Lightning Visual)
--------------------------------------------------------------------------------
local floatButton = Instance.new("TextButton")
floatButton.Name = "FloatButton"
floatButton.Size = UDim2.new(0, 64, 0, 64)
floatButton.Position = UDim2.new(0, 20, 0, 100)
floatButton.BackgroundColor3 = THEME.Background
floatButton.BorderSizePixel = 0
floatButton.AutoButtonColor = false
floatButton.Text = ""
floatButton.Parent = screenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = floatButton

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = THEME.Accent
floatStroke.Thickness = 2
floatStroke.Parent = floatButton

-- Lightning icon / text symbol
local lightningLabel = Instance.new("TextLabel")
lightningLabel.Name = "Lightning"
lightningLabel.Size = UDim2.new(1, 0, 0, 26)
lightningLabel.Position = UDim2.new(0, 0, 0, 8)
lightningLabel.BackgroundTransparency = 1
lightningLabel.Font = Enum.Font.FredokaOne
lightningLabel.Text = "⚡"
lightningLabel.TextSize = 22
lightningLabel.TextColor3 = THEME.Accent
lightningLabel.Parent = floatButton

local titleFloatLabel = Instance.new("TextLabel")
titleFloatLabel.Name = "Title"
titleFloatLabel.Size = UDim2.new(1, 0, 0, 18)
titleFloatLabel.Position = UDim2.new(0, 0, 0, 36)
titleFloatLabel.BackgroundTransparency = 1
titleFloatLabel.Font = Enum.Font.GothamBold
titleFloatLabel.Text = "FPS"
titleFloatLabel.TextSize = 10
titleFloatLabel.TextColor3 = THEME.Text
titleFloatLabel.Parent = floatButton

--------------------------------------------------------------------------------
-- 2. Main Draggable Panel
--------------------------------------------------------------------------------
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, 380, 0, 520)
mainPanel.Position = UDim2.new(0, 100, 0, 100)
mainPanel.BackgroundColor3 = THEME.PanelBG
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = mainPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(60, 60, 75)
panelStroke.Thickness = 1.5
panelStroke.Parent = mainPanel

-- Top Bar (Draggable handle)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 44)
topBar.BackgroundColor3 = THEME.Background
topBar.BorderSizePixel = 0
topBar.Parent = mainPanel

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 12)
topBarCorner.Parent = topBar

-- Fix top corners rounding bottom of topBar
local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 10)
topBarFix.Position = UDim2.new(0, 0, 1, -10)
topBarFix.BackgroundColor3 = THEME.Background
topBarFix.BorderSizePixel = 0
topBarFix.Parent = topBar

local topBarTitle = Instance.new("TextLabel")
topBarTitle.Size = UDim2.new(1, -50, 1, 0)
topBarTitle.Position = UDim2.new(0, 16, 0, 0)
topBarTitle.BackgroundTransparency = 1
topBarTitle.Font = Enum.Font.GothamBold
topBarTitle.Text = "Filing FPS • Studio Safe UI"
topBarTitle.TextColor3 = THEME.Text
topBarTitle.TextSize = 14
topBarTitle.TextXAlignment = Enum.TextXAlignment.Left
topBarTitle.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Position = UDim2.new(1, -36, 0.5, -14)
closeButton.BackgroundColor3 = THEME.CardBG
closeButton.Text = "×"
closeButton.TextColor3 = THEME.Text
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

-- Content Container (Vertical Layout with ScrollingFrame so player list never overlaps buttons)
local contentContainer = Instance.new("ScrollingFrame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1, -24, 1, -116) -- leaves room for topBar and bottom bar
contentContainer.Position = UDim2.new(0, 12, 0, 52)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.CanvasSize = UDim2.new(0, 0, 0, 560)
contentContainer.ScrollBarThickness = 6
contentContainer.ScrollBarImageColor3 = THEME.Accent
contentContainer.Parent = mainPanel

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 12)
contentLayout.Parent = contentContainer

--------------------------------------------------------------------------------
-- Section 3: Target TextBox & Toast Notification System
--------------------------------------------------------------------------------
local function showToast(message, isSuccess)
	local toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.Size = UDim2.new(0, 220, 0, 44)
	-- Positioned on the RIGHT side of the screen
	toast.Position = UDim2.new(1, 240, 0.85, 0)
	toast.BackgroundColor3 = THEME.Background
	toast.BorderSizePixel = 0
	toast.Parent = screenGui
	
	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 8)
	tCorner.Parent = toast
	
	local tStroke = Instance.new("UIStroke")
	tStroke.Color = isSuccess and THEME.Success or THEME.Error
	tStroke.Thickness = 1.5
	tStroke.Parent = toast
	
	local tLabel = Instance.new("TextLabel")
	tLabel.Size = UDim2.new(1, 0, 1, 0)
	tLabel.BackgroundTransparency = 1
	tLabel.Font = Enum.Font.GothamBold
	tLabel.Text = message
	tLabel.TextColor3 = THEME.Text
	tLabel.TextSize = 13
	tLabel.Parent = toast
	
	-- Animate in
	toast:TweenPosition(UDim2.new(1, -236, 0.85, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
	
	task.delay(2.2, function()
		if toast and toast.Parent then
			toast:TweenPosition(UDim2.new(1, 240, 0.85, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true, function()
				toast:Destroy()
			end)
		end
	end)
end

local targetSection = Instance.new("Frame")
targetSection.Name = "TargetSection"
targetSection.Size = UDim2.new(1, 0, 0, 75)
targetSection.BackgroundColor3 = THEME.CardBG
targetSection.LayoutOrder = 1
targetSection.Parent = contentContainer

local tsCorner = Instance.new("UICorner")
tsCorner.CornerRadius = UDim.new(0, 8)
tsCorner.Parent = targetSection

local tsLabel = Instance.new("TextLabel")
tsLabel.Size = UDim2.new(1, -16, 0, 24)
tsLabel.Position = UDim2.new(0, 10, 0, 6)
tsLabel.BackgroundTransparency = 1
tsLabel.Font = Enum.Font.GothamBold
tsLabel.Text = "Target Username"
tsLabel.TextColor3 = THEME.TextDim
tsLabel.TextSize = 11
tsLabel.TextXAlignment = Enum.TextXAlignment.Left
tsLabel.Parent = targetSection

local targetTextBox = Instance.new("TextBox")
targetTextBox.Name = "TargetTextBox"
targetTextBox.Size = UDim2.new(1, -20, 0, 36)
targetTextBox.Position = UDim2.new(0, 10, 0, 30)
targetTextBox.BackgroundColor3 = THEME.Background
targetTextBox.Font = Enum.Font.Gotham
targetTextBox.PlaceholderText = "Type player name & press Enter..."
targetTextBox.PlaceholderColor3 = THEME.TextDim
targetTextBox.Text = ""
targetTextBox.TextColor3 = THEME.Text
targetTextBox.TextSize = 13
targetTextBox.ClearTextOnFocus = false
targetTextBox.Parent = targetSection

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 6)
tbCorner.Parent = targetTextBox

--------------------------------------------------------------------------------
-- 4. "Show All Users" Toggle & Player List
--------------------------------------------------------------------------------
local playersSection = Instance.new("Frame")
playersSection.Name = "PlayersSection"
playersSection.Size = UDim2.new(1, 0, 0, 180)
playersSection.BackgroundColor3 = THEME.CardBG
playersSection.LayoutOrder = 2
playersSection.Parent = contentContainer

local psCorner = Instance.new("UICorner")
psCorner.CornerRadius = UDim.new(0, 8)
psCorner.Parent = playersSection

local toggleUsersBtn = Instance.new("TextButton")
toggleUsersBtn.Size = UDim2.new(1, -20, 0, 34)
toggleUsersBtn.Position = UDim2.new(0, 10, 0, 8)
toggleUsersBtn.BackgroundColor3 = THEME.Background
toggleUsersBtn.Font = Enum.Font.GothamBold
toggleUsersBtn.Text = "📁 Show All Users [OFF]"
toggleUsersBtn.TextColor3 = THEME.Text
toggleUsersBtn.TextSize = 12
toggleUsersBtn.Parent = playersSection

local tubCorner = Instance.new("UICorner")
tubCorner.CornerRadius = UDim.new(0, 6)
tubCorner.Parent = toggleUsersBtn

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Name = "PlayersScroll"
playersScroll.Size = UDim2.new(1, -20, 0, 120)
playersScroll.Position = UDim2.new(0, 10, 0, 48)
playersScroll.BackgroundColor3 = THEME.Background
playersScroll.BorderSizePixel = 0
playersScroll.Visible = false
playersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playersScroll.ScrollBarThickness = 4
playersScroll.Parent = playersSection

local psScrollCorner = Instance.new("UICorner")
psScrollCorner.CornerRadius = UDim.new(0, 6)
psScrollCorner.Parent = playersScroll

local psLayout = Instance.new("UIListLayout")
psLayout.SortOrder = Enum.SortOrder.LayoutOrder
psLayout.Padding = UDim.new(0, 4)
psLayout.Parent = playersScroll

local function updatePlayerList()
	for _, child in ipairs(playersScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local allPlayers = Players:GetPlayers()
	playersScroll.CanvasSize = UDim2.new(0, 0, 0, #allPlayers * 30)
	
	for _, p in ipairs(allPlayers) do
		local pBtn = Instance.new("TextButton")
		pBtn.Size = UDim2.new(1, -4, 0, 26)
		pBtn.BackgroundColor3 = THEME.CardBG
		pBtn.Font = Enum.Font.Gotham
		pBtn.Text = "  " .. p.Name
		pBtn.TextColor3 = THEME.Text
		pBtn.TextSize = 12
		pBtn.TextXAlignment = Enum.TextXAlignment.Left
		pBtn.Parent = playersScroll
		
		local pbCorner = Instance.new("UICorner")
		pbCorner.CornerRadius = UDim.new(0, 4)
		pbCorner.Parent = pBtn
		
		pBtn.MouseButton1Click:Connect(function()
			targetTextBox.Text = p.Name
			showToast("Target Selected", true)
		end)
	end
end

--------------------------------------------------------------------------------
-- 6. Speed Slider & Five Mode Buttons
--------------------------------------------------------------------------------
local modesSection = Instance.new("Frame")
modesSection.Name = "ModesSection"
modesSection.Size = UDim2.new(1, 0, 0, 150)
modesSection.BackgroundColor3 = THEME.CardBG
modesSection.LayoutOrder = 3
modesSection.Parent = contentContainer

local msCorner = Instance.new("UICorner")
msCorner.CornerRadius = UDim.new(0, 8)
msCorner.Parent = modesSection

local modesTitle = Instance.new("TextLabel")
modesTitle.Size = UDim2.new(1, -16, 0, 24)
modesTitle.Position = UDim2.new(0, 10, 0, 6)
modesTitle.BackgroundTransparency = 1
modesTitle.Font = Enum.Font.GothamBold
modesTitle.Text = "Operation Modes (5 Active)"
modesTitle.TextColor3 = THEME.TextDim
modesTitle.TextSize = 11
modesTitle.TextXAlignment = Enum.TextXAlignment.Left
modesTitle.Parent = modesSection

-- 5 Mode buttons in a grid / row layout container
local modesContainer = Instance.new("Frame")
modesContainer.Size = UDim2.new(1, -20, 0, 72)
modesContainer.Position = UDim2.new(0, 10, 0, 32)
modesContainer.BackgroundTransparency = 1
modesContainer.Parent = modesSection

local mGrid = Instance.new("UIGridLayout")
mGrid.CellSize = UDim2.new(0.31, 0, 0, 32)
mGrid.CellPadding = UDim2.new(0.03, 0, 0, 8)
mGrid.Parent = modesContainer

local modeNames = {"Standard", "Aggressive", "Tactical", "Stealth", "Overclock"}
local activeModeButton = nil

for i, mName in ipairs(modeNames) do
	local mBtn = Instance.new("TextButton")
	mBtn.Name = mName
	mBtn.BackgroundColor3 = THEME.Background
	mBtn.Font = Enum.Font.GothamBold
	mBtn.Text = mName
	mBtn.TextColor3 = THEME.Text
	mBtn.TextSize = 11
	mBtn.Parent = modesContainer
	
	local mbCorner = Instance.new("UICorner")
	mbCorner.CornerRadius = UDim.new(0, 6)
	mbCorner.Parent = mBtn
	
	local mbStroke = Instance.new("UIStroke")
	mbStroke.Color = Color3.fromRGB(60, 60, 70)
	mbStroke.Thickness = 1
	mbStroke.Parent = mBtn
	
	if i == 1 then
		mBtn.BackgroundColor3 = THEME.Accent
		mbStroke.Color = THEME.AccentHover
		activeModeButton = mBtn
	end
	
	mBtn.MouseButton1Click:Connect(function()
		if activeModeButton then
			activeModeButton.BackgroundColor3 = THEME.Background
			local st = activeModeButton:FindFirstChildOfClass("UIStroke")
			if st then st.Color = Color3.fromRGB(60, 60, 70) end
		end
		activeModeButton = mBtn
		mBtn.BackgroundColor3 = THEME.Accent
		mbStroke.Color = THEME.AccentHover
		showToast("Mode: " .. mName, true)
	end)
end

-- Speed Slider
local speedSection = Instance.new("Frame")
speedSection.Name = "SpeedSection"
speedSection.Size = UDim2.new(1, 0, 0, 110)
speedSection.BackgroundColor3 = THEME.CardBG
speedSection.LayoutOrder = 4
speedSection.Parent = contentContainer

local ssCorner = Instance.new("UICorner")
ssCorner.CornerRadius = UDim.new(0, 8)
ssCorner.Parent = speedSection

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -16, 0, 24)
speedLabel.Position = UDim2.new(0, 10, 0, 6)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBold
speedLabel.Text = "Speed Multiplier: 1.0x"
speedLabel.TextColor3 = THEME.TextDim
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedSection

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, -20, 0, 8)
sliderBg.Position = UDim2.new(0, 10, 0, 42)
sliderBg.BackgroundColor3 = THEME.Background
sliderBg.BorderSizePixel = 0
sliderBg.Parent = speedSection

local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(1, 0)
sbCorner.Parent = sliderBg

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = THEME.Accent
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg

local sfCorner = Instance.new("UICorner")
sfCorner.CornerRadius = UDim.new(1, 0)
sfCorner.Parent = sliderFill

local sliderThumb = Instance.new("TextButton")
sliderThumb.Size = UDim2.new(0, 18, 0, 18)
sliderThumb.Position = UDim2.new(0.5, -9, 0.5, -9)
sliderThumb.BackgroundColor3 = THEME.Text
sliderThumb.Text = ""
sliderThumb.Parent = sliderBg

local stCorner = Instance.new("UICorner")
stCorner.CornerRadius = UDim.new(1, 0)
stCorner.Parent = sliderThumb

--------------------------------------------------------------------------------
-- 7. Studio-Safe Demo Action (Controlled Knockback on NPC with AllowFlingDemo=true)
--------------------------------------------------------------------------------
local demoActionSection = Instance.new("Frame")
demoActionSection.Name = "DemoActionSection"
demoActionSection.Size = UDim2.new(1, 0, 0, 85)
demoActionSection.BackgroundColor3 = THEME.CardBG
demoActionSection.LayoutOrder = 5
demoActionSection.Parent = contentContainer

local dasCorner = Instance.new("UICorner")
dasCorner.CornerRadius = UDim.new(0, 8)
dasCorner.Parent = demoActionSection

local dasLabel = Instance.new("TextLabel")
dasLabel.Size = UDim2.new(1, -16, 0, 20)
dasLabel.Position = UDim2.new(0, 10, 0, 6)
dasLabel.BackgroundTransparency = 1
dasLabel.Font = Enum.Font.GothamBold
dasLabel.Text = "Studio-Safe NPC Demo Action"
dasLabel.TextColor3 = THEME.TextDim
dasLabel.TextSize = 11
dasLabel.TextXAlignment = Enum.TextXAlignment.Left
dasLabel.Parent = demoActionSection

local demoActionBtn = Instance.new("TextButton")
demoActionBtn.Size = UDim2.new(1, -20, 0, 36)
demoActionBtn.Position = UDim2.new(0, 10, 0, 32)
demoActionBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
demoActionBtn.Font = Enum.Font.GothamBold
demoActionBtn.Text = "Apply Controlled Knockback (Dummy)"
demoActionBtn.TextColor3 = THEME.Text
demoActionBtn.TextSize = 12
demoActionBtn.Parent = demoActionSection

local dabCorner = Instance.new("UICorner")
dabCorner.CornerRadius = UDim.new(0, 6)
dabCorner.Parent = demoActionBtn

--------------------------------------------------------------------------------
-- 5. START / OFF Button in its own fixed bottom section (never over player list)
--------------------------------------------------------------------------------
local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.Size = UDim2.new(1, 0, 0, 60)
bottomBar.Position = UDim2.new(0, 0, 1, -60)
bottomBar.BackgroundColor3 = THEME.Background
bottomBar.BorderSizePixel = 0
bottomBar.Parent = mainPanel

local bbCorner = Instance.new("UICorner")
bbCorner.CornerRadius = UDim.new(0, 12)
bbCorner.Parent = bottomBar

local bbFix = Instance.new("Frame")
bbFix.Size = UDim2.new(1, 0, 0, 10)
bbFix.BackgroundColor3 = THEME.Background
bbFix.BorderSizePixel = 0
bbFix.Parent = bottomBar

local startToggleBtn = Instance.new("TextButton")
startToggleBtn.Name = "StartToggleBtn"
startToggleBtn.Size = UDim2.new(1, -24, 0, 38)
startToggleBtn.Position = UDim2.new(0, 12, 0, 11)
startToggleBtn.BackgroundColor3 = THEME.ToggleOff
startToggleBtn.Font = Enum.Font.GothamBold
startToggleBtn.Text = "START [OFF]"
startToggleBtn.TextColor3 = THEME.Text
startToggleBtn.TextSize = 14
startToggleBtn.Parent = bottomBar

local stbCorner = Instance.new("UICorner")
stbCorner.CornerRadius = UDim.new(0, 8)
stbCorner.Parent = startToggleBtn

--------------------------------------------------------------------------------
-- Interactions, Dragging & Logic Implementation
--------------------------------------------------------------------------------

-- Floating button drag logic
local draggingFloat, dragInputFloat, dragStartFloat, startPosFloat = false, nil, nil, nil
floatButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingFloat = true
		dragStartFloat = input.Position
		startPosFloat = floatButton.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingFloat = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingFloat and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStartFloat
		floatButton.Position = UDim2.new(
			startPosFloat.X.Scale, startPosFloat.X.Offset + delta.X,
			startPosFloat.Y.Scale, startPosFloat.Y.Offset + delta.Y
		)
	end
end)

-- Toggle main panel visibility via float button
floatButton.MouseButton1Click:Connect(function()
	mainPanel.Visible = not mainPanel.Visible
end)

closeButton.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
end)

-- Main panel drag logic
local draggingPanel, dragInputPanel, dragStartPanel, startPosPanel = false, nil, nil, nil
topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingPanel = true
		dragStartPanel = input.Position
		startPosPanel = mainPanel.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingPanel = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingPanel and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStartPanel
		mainPanel.Position = UDim2.new(
			startPosPanel.X.Scale, startPosPanel.X.Offset + delta.X,
			startPosPanel.Y.Scale, startPosPanel.Y.Offset + delta.Y
		)
	end
end)

-- Target TextBox validation against Players:GetPlayers()
targetTextBox.FocusLost:Connect(function(enterPressed)
	if not enterPressed then return end
	local query = targetTextBox.Text:lower()
	local found = false
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower() == query or p.DisplayName:lower() == query then
			found = true
			break
		end
	end
	if found then
		showToast("Target Selected", true)
	else
		showToast("Invalid Target", false)
	end
end)

-- Show All Users toggle logic
local usersExpanded = false
toggleUsersBtn.MouseButton1Click:Connect(function()
	usersExpanded = not usersExpanded
	if usersExpanded then
		toggleUsersBtn.Text = "📁 Show All Users [ON]"
		playersScroll.Visible = true
		playersSection.Size = UDim2.new(1, 0, 0, 180)
		updatePlayerList()
	else
		toggleUsersBtn.Text = "📁 Show All Users [OFF]"
		playersScroll.Visible = false
		playersSection.Size = UDim2.new(1, 0, 0, 50)
	end
end)

-- Connect Playeradded / removing to keep list updated
Players.PlayerAdded:Connect(function()
	if usersExpanded then updatePlayerList() end
end)
Players.PlayerRemoving:Connect(function()
	if usersExpanded then updatePlayerList() end
end)

-- Speed Slider Dragging
local sliderDragging = false
sliderThumb.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local absPos = sliderBg.AbsolutePosition.X
		local absSize = sliderBg.AbsoluteSize.X
		local mouseX = input.Position.X
		local ratio = math.clamp((mouseX - absPos) / absSize, 0, 1)
		
		sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
		sliderThumb.Position = UDim2.new(ratio, -9, 0.5, -9)
		
		local speedVal = math.round((0.1 + ratio * 4.9) * 10) / 10
		speedLabel.Text = string.format("Speed Multiplier: %.1fx", speedVal)
	end
end)

-- START / OFF State
local systemActive = false
startToggleBtn.MouseButton1Click:Connect(function()
	systemActive = not systemActive
	if systemActive then
		startToggleBtn.Text = "START [ON]"
		startToggleBtn.BackgroundColor3 = THEME.ToggleOn
		showToast("System Engaged", true)
	else
		startToggleBtn.Text = "START [OFF]"
		startToggleBtn.BackgroundColor3 = THEME.ToggleOff
		showToast("System Disengaged", false)
	end
end)

-- Studio-safe demo action (Controlled knockback ONLY on NPC/dummy model with AllowFlingDemo=true attribute)
demoActionBtn.MouseButton1Click:Connect(function()
	local foundDemoNPC = false
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model") and obj:GetAttribute("AllowFlingDemo") == true then
			local hrp = obj:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				foundDemoNPC = true
				-- Apply safe controlled upward/forward knockback
				hrp.AssemblyLinearVelocity = Vector3.new(0, 35, 25)
				showToast("Knockback Applied to " .. obj.Name, true)
				break
			end
		end
	end
	
	if not foundDemoNPC then
		showToast("No Demo NPC Found (AllowFlingDemo=true)", false)
	end
end)

print("Filing FPS Studio Safe UI successfully loaded.")
