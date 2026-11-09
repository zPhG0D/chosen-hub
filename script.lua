local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local COLOR_BG       = Color3.fromRGB(12, 22, 40)
local COLOR_PANEL    = Color3.fromRGB(20, 39, 66)
local COLOR_SIDE     = Color3.fromRGB(15, 31, 53)
local COLOR_CARD     = Color3.fromRGB(24, 48, 79)
local COLOR_CARD2    = Color3.fromRGB(31, 61, 98)
local COLOR_BORDER   = Color3.fromRGB(45, 91, 135)
local COLOR_BORDER2  = Color3.fromRGB(66, 120, 168)
local COLOR_ACCENT   = Color3.fromRGB(52, 142, 255)
local COLOR_ACCENT2  = Color3.fromRGB(31, 103, 214)
local COLOR_TEXT     = Color3.fromRGB(242, 248, 255)
local COLOR_DIM      = Color3.fromRGB(175, 201, 229)
local COLOR_MUTED    = Color3.fromRGB(120, 155, 192)
local COLOR_SUCCESS  = Color3.fromRGB(74, 214, 131)

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = obj
	return c
end

local function stroke(obj, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or COLOR_BORDER
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

local function padding(obj, l, r, t, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.Parent = obj
	return p
end

local function tween(obj, props, time)
	TweenService:Create(
		obj,
		TweenInfo.new(time or 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		props
	):Play()
end

pcall(function()
	local oldCore = CoreGui:FindFirstChild("ChosenPanelGui")
	if oldCore then
		oldCore:Destroy()
	end
end)

pcall(function()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui and playerGui:FindFirstChild("ChosenPanelGui") then
		playerGui.ChosenPanelGui:Destroy()
	end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChosenPanelGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
	ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 720, 0, 448)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -224)
MainFrame.BackgroundColor3 = COLOR_BG
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = false
MainFrame.Parent = ScreenGui
corner(MainFrame, 12)
stroke(MainFrame, COLOR_BORDER, 1, 0)

local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1, -28, 0, 2)
AccentLine.Position = UDim2.new(0, 14, 0, 1)
AccentLine.BackgroundColor3 = COLOR_TEXT
AccentLine.BorderSizePixel = 0
AccentLine.Parent = MainFrame
corner(AccentLine, 2)

local AccentLineGradient = Instance.new("UIGradient")
AccentLineGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COLOR_ACCENT),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(120, 190, 255)),
	ColorSequenceKeypoint.new(1, COLOR_PANEL)
})
AccentLineGradient.Parent = AccentLine

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 58)
TopBar.BackgroundColor3 = COLOR_PANEL
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
corner(TopBar, 12)
TopBar.Active = true

do
	local draggingPanel = false
	local dragStart = nil
	local startPosition = nil
	local dragInput = nil
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			draggingPanel = true
			dragStart = input.Position
			startPosition = MainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					draggingPanel = false
				end
			end)
		end
	end)
	TopBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not draggingPanel or input ~= dragInput then return end
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end)
end

local TopMask = Instance.new("Frame")
TopMask.Size = UDim2.new(1, 0, 0, 24)
TopMask.Position = UDim2.new(0, 0, 1, -24)
TopMask.BackgroundColor3 = COLOR_PANEL
TopMask.BorderSizePixel = 0
TopMask.Parent = TopBar

local Brand = Instance.new("TextLabel")
Brand.Name = "ChosenHub"
Brand.Size = UDim2.new(0, 262, 0, 36)
Brand.Position = UDim2.new(0, 18, 0, 10)
Brand.BackgroundTransparency = 1
Brand.Text = "◆  CHOSEN HUB"
Brand.TextColor3 = COLOR_TEXT
Brand.Font = Enum.Font.GothamBlack
Brand.TextSize = 17
Brand.TextXAlignment = Enum.TextXAlignment.Left
Brand.Parent = TopBar

local BrandTextGradient = Instance.new("UIGradient")
BrandTextGradient.Rotation = 90
BrandTextGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COLOR_TEXT),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 195, 250))
})
BrandTextGradient.Parent = Brand

local BrandAccent = Instance.new("Frame")
BrandAccent.Size = UDim2.new(0, 40, 0, 3)
BrandAccent.Position = UDim2.new(0, 20, 1, -8)
BrandAccent.BackgroundColor3 = COLOR_ACCENT
BrandAccent.BorderSizePixel = 0
BrandAccent.Parent = TopBar
corner(BrandAccent, 2)

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(1, -122, 0, 25)
StatusDot.BackgroundColor3 = COLOR_SUCCESS
StatusDot.BorderSizePixel = 0
StatusDot.Parent = TopBar
corner(StatusDot, 8)

task.spawn(function()
	while StatusDot.Parent do
		tween(StatusDot, {BackgroundTransparency = 0.65}, 0.55)
		task.wait(0.55)
		tween(StatusDot, {BackgroundTransparency = 0}, 0.55)
		task.wait(0.55)
	end
end)

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(0, 94, 0, 18)
StatusText.Position = UDim2.new(1, -110, 0, 20)
StatusText.BackgroundTransparency = 1
StatusText.Text = "SISTEMA ONLINE"
StatusText.TextColor3 = COLOR_DIM
StatusText.Font = Enum.Font.Code
StatusText.TextSize = 9
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = TopBar

local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -20, 1, -70)
Body.Position = UDim2.new(0, 10, 0, 64)
Body.BackgroundTransparency = 1
Body.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 168, 1, 0)
Sidebar.BackgroundColor3 = COLOR_SIDE
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Body
corner(Sidebar, 12)
stroke(Sidebar, COLOR_BORDER, 1, 0.15)

local SideTitle = Instance.new("TextLabel")
SideTitle.Size = UDim2.new(1, -28, 0, 18)
SideTitle.Position = UDim2.new(0, 14, 0, 16)
SideTitle.BackgroundTransparency = 1
SideTitle.Text = "◆  CHOSEN HUB"
SideTitle.TextColor3 = COLOR_MUTED
SideTitle.Font = Enum.Font.Code
SideTitle.TextSize = 9
SideTitle.TextXAlignment = Enum.TextXAlignment.Left
SideTitle.Parent = Sidebar

local SideSub = Instance.new("TextLabel")
SideSub.Size = UDim2.new(1, -28, 0, 20)
SideSub.Position = UDim2.new(0, 14, 0, 34)
SideSub.BackgroundTransparency = 1
SideSub.Text = "Escolha uma área"
SideSub.TextColor3 = COLOR_TEXT
SideSub.Font = Enum.Font.GothamBlack
SideSub.TextSize = 13
SideSub.TextXAlignment = Enum.TextXAlignment.Left
SideSub.Parent = Sidebar

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -18, 1, -88)
TabContainer.Position = UDim2.new(0, 9, 0, 64)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 6)
TabLayout.Parent = TabContainer

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(1, -28, 0, 20)
Version.Position = UDim2.new(0, 14, 1, -27)
Version.BackgroundTransparency = 1
Version.Text = "v2.2  •  B ABRE/FECHA"
Version.TextColor3 = COLOR_MUTED
Version.Font = Enum.Font.Code
Version.TextSize = 9
Version.TextXAlignment = Enum.TextXAlignment.Left
Version.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -180, 1, 0)
ContentArea.Position = UDim2.new(0, 180, 0, 0)
ContentArea.BackgroundColor3 = COLOR_PANEL
ContentArea.BorderSizePixel = 0
ContentArea.Parent = Body
corner(ContentArea, 12)
stroke(ContentArea, COLOR_BORDER, 1, 0.15)

local ContentTitle = Instance.new("TextLabel")
ContentTitle.Size = UDim2.new(1, -30, 0, 28)
ContentTitle.Position = UDim2.new(0, 16, 0, 12)
ContentTitle.BackgroundTransparency = 1
ContentTitle.Text = "Início"
ContentTitle.TextColor3 = COLOR_TEXT
ContentTitle.Font = Enum.Font.GothamBlack
ContentTitle.TextSize = 17
ContentTitle.TextXAlignment = Enum.TextXAlignment.Left
ContentTitle.Parent = ContentArea

local ContentHint = Instance.new("TextLabel")
ContentHint.Size = UDim2.new(1, -30, 0, 18)
ContentHint.Position = UDim2.new(0, 16, 0, 38)
ContentHint.BackgroundTransparency = 1
ContentHint.Text = "Um painel simples, organizado e pronto para usar"
ContentHint.TextColor3 = COLOR_MUTED
ContentHint.Font = Enum.Font.Gotham
ContentHint.TextSize = 11
ContentHint.TextXAlignment = Enum.TextXAlignment.Left
ContentHint.Parent = ContentArea

local ContentHolder = Instance.new("Frame")
ContentHolder.Size = UDim2.new(0, 490, 1, -76)
ContentHolder.Position = UDim2.new(0, 16, 0, 70)
ContentHolder.BackgroundTransparency = 1
ContentHolder.ClipsDescendants = true
ContentHolder.Parent = ContentArea

local Tabs = {}
local ContentFrames = {}
local TabIcons = {
	["Início"] = "01",
	["Amigos"] = "02",
	["Target"] = "03",
	["Jogo"] = "04",
	ESP = "05",
	["Diversos"] = "06"
}

local function createTab(name, order)
	local btn = Instance.new("TextButton")
	btn.Name = name .. "TabButton"
	btn.Size = UDim2.new(1, 0, 0, 38)
	btn.BackgroundColor3 = COLOR_SIDE
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.LayoutOrder = order
	btn.Parent = TabContainer
	corner(btn, 19)
	stroke(btn, COLOR_BORDER, 1, 0.35)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 26, 0, 26)
	icon.Position = UDim2.new(0, 6, 0.5, -13)
	icon.BackgroundColor3 = COLOR_SIDE
	icon.BackgroundTransparency = 0
	icon.Text = TabIcons[name] or "00"
	icon.TextColor3 = COLOR_DIM
	icon.Font = Enum.Font.Code
	icon.TextSize = 10
	icon.TextXAlignment = Enum.TextXAlignment.Center
	icon.TextYAlignment = Enum.TextYAlignment.Center
	icon.Parent = btn
	corner(icon, 7)
	stroke(icon, COLOR_BORDER, 1, 0.35)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -46, 1, 0)
	label.Position = UDim2.new(0, 40, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = COLOR_DIM
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = btn

	local activeBar = Instance.new("Frame")
	activeBar.Size = UDim2.new(0, 3, 0, 22)
	activeBar.Position = UDim2.new(0, 4, 0.5, -11)
	activeBar.BackgroundColor3 = COLOR_ACCENT
	activeBar.BorderSizePixel = 0
	activeBar.Visible = false
	activeBar.Parent = btn
	corner(activeBar, 2)

	local content = Instance.new("ScrollingFrame")
	content.Name = name .. "Content"
	content.Size = UDim2.new(1, 0, 1, 0)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 3
	content.ScrollBarImageColor3 = COLOR_ACCENT
	content.ScrollBarImageTransparency = 0.2
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.Visible = false
	content.Parent = ContentHolder
	padding(content, 2, 12, 2, 10)

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = content

	Tabs[name] = {
		button = btn,
		icon = icon,
		label = label,
		activeBar = activeBar
	}
	ContentFrames[name] = content

	btn.MouseEnter:Connect(function()
		if not ContentFrames[name].Visible then
			tween(btn, {BackgroundColor3 = COLOR_PANEL}, 0.10)
			local hs = btn:FindFirstChildOfClass("UIStroke")
			if hs then tween(hs, {Color = COLOR_BORDER2}, 0.10) end
		end
	end)
	btn.MouseLeave:Connect(function()
		if not ContentFrames[name].Visible then
			tween(btn, {BackgroundColor3 = COLOR_SIDE}, 0.10)
			local hs = btn:FindFirstChildOfClass("UIStroke")
			if hs then tween(hs, {Color = COLOR_BORDER}, 0.10) end
		end
	end)
	btn.MouseButton1Click:Connect(function()
		for tabName, data in pairs(Tabs) do
			local active = tabName == name
			data.button.BackgroundColor3 = active and COLOR_CARD or COLOR_SIDE
			data.icon.TextColor3 = active and COLOR_ACCENT or COLOR_DIM
			data.label.TextColor3 = active and COLOR_TEXT or COLOR_DIM
			data.activeBar.Visible = active
			ContentFrames[tabName].Visible = active
		end
		ContentTitle.Text = name
		ContentHint.Text = ({
			["Início"] = "Visão geral rápida",
			["Amigos"] = "Amizades que estão neste servidor",
			["Target"] = "Escolha um jogador e use os controles",
			["Jogo"] = "Movimento e utilidades do jogo",
			["ESP"] = "Informações visuais e aimbot integrado",
			["Diversos"] = "Ferramentas extras e efeitos visuais"
		})[name] or ""
	end)
	return content
end

local function createSection(parent, title, subtitle, order)
	local section = Instance.new("Frame")
	section.Size = UDim2.new(1, -4, 0, 40)
	section.BackgroundTransparency = 1
	section.LayoutOrder = order or 1
	section.Parent = parent

	local tick = Instance.new("Frame")
	tick.Size = UDim2.new(0, 3, 0, 12)
	tick.Position = UDim2.new(0, -6, 0, 4)
	tick.BackgroundColor3 = COLOR_ACCENT
	tick.BorderSizePixel = 0
	tick.Parent = section
	corner(tick, 2)

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 0, 20)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = COLOR_TEXT
	t.Font = Enum.Font.GothamBlack
	t.TextSize = 12
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = section

	local s = Instance.new("TextLabel")
	s.Size = UDim2.new(1, 0, 0, 16)
	s.Position = UDim2.new(0, 0, 0, 21)
	s.BackgroundTransparency = 1
	s.Text = subtitle or ""
	s.TextColor3 = COLOR_MUTED
	s.Font = Enum.Font.Gotham
	s.TextSize = 10
	s.TextXAlignment = Enum.TextXAlignment.Left
	s.Parent = section

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.new(0, 0, 1, -2)
	divider.BackgroundColor3 = COLOR_BORDER
	divider.BackgroundTransparency = 0.45
	divider.BorderSizePixel = 0
	divider.Parent = section
	return section
end

local function isControlRow(parent)
	return parent and parent:GetAttribute("ControlRow") == true
end

local function createControlRow(parent, order)
	local row = Instance.new("Frame")
	row.Name = "ControleDuplo"
	row.Size = UDim2.new(1, -4, 0, 52)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.LayoutOrder = order or 1
	row:SetAttribute("ControlRow", true)
	row.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = row
	return row
end

local function createToggleButton(parent, labelText, callback, order)
	local state = false
	local inRow = isControlRow(parent)
	local card = Instance.new("Frame")
	card.Size = inRow and UDim2.new(0.5, -8, 1, 0) or UDim2.new(1, -4, 0, 50)
	card.BackgroundColor3 = COLOR_CARD
	card.BorderSizePixel = 0
	card.LayoutOrder = order or 1
	card.Parent = parent
	corner(card, 12)
	stroke(card, COLOR_BORDER, 1, 0.15)

	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, 0, 1, 0)
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.AutoButtonColor = false
	hit.Text = ""
	hit.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 1, 0)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = labelText
	title.TextColor3 = COLOR_TEXT
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = card

	local switchTrack = Instance.new("Frame")
	switchTrack.Size = UDim2.new(0, 36, 0, 18)
	switchTrack.Position = UDim2.new(1, -54, 0.5, -9)
	switchTrack.BackgroundColor3 = COLOR_SIDE
	switchTrack.BorderSizePixel = 0
	switchTrack.Parent = card
	corner(switchTrack, 9)
	stroke(switchTrack, COLOR_BORDER, 1, 0.15)

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 14, 0, 14)
	dot.Position = UDim2.new(0, 2, 0.5, -7)
	dot.BackgroundColor3 = COLOR_MUTED
	dot.BorderSizePixel = 0
	dot.Parent = switchTrack
	corner(dot, 7)

	local function setState(newState)
		state = newState
		tween(dot, {
			Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
			BackgroundColor3 = state and COLOR_SUCCESS or COLOR_MUTED
		}, 0.14)
		tween(card, {BackgroundColor3 = state and Color3.fromRGB(28, 76, 52) or COLOR_CARD}, 0.12)
		local st = card:FindFirstChildOfClass("UIStroke")
		if st then tween(st, {Color = state and COLOR_SUCCESS or COLOR_BORDER}, 0.12) end
		if callback then callback(state) end
	end

	hit.MouseButton1Click:Connect(function() setState(not state) end)
	hit.MouseEnter:Connect(function()
		tween(card, {BackgroundColor3 = state and Color3.fromRGB(34, 88, 62) or COLOR_CARD2}, 0.10)
		local st = card:FindFirstChildOfClass("UIStroke")
		if st and not state then tween(st, {Color = COLOR_BORDER2}, 0.10) end
	end)
	hit.MouseLeave:Connect(function()
		tween(card, {BackgroundColor3 = state and Color3.fromRGB(28, 76, 52) or COLOR_CARD}, 0.10)
		local st = card:FindFirstChildOfClass("UIStroke")
		if st and not state then tween(st, {Color = COLOR_BORDER}, 0.10) end
	end)
	return card, setState
end

local function createActionButton(parent, text, order, compact)
	local inRow = isControlRow(parent)
	local btn = Instance.new("TextButton")
	btn.Size = inRow and UDim2.new(0.5, -8, 1, 0) or UDim2.new(1, -4, 0, compact and 40 or 46)
	btn.BackgroundColor3 = COLOR_CARD2
	btn.AutoButtonColor = false
	btn.Text = text
	btn.TextColor3 = COLOR_TEXT
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextTruncate = Enum.TextTruncate.AtEnd
	btn.LayoutOrder = order or 1
	btn.Parent = parent
	corner(btn, 12)
	stroke(btn, COLOR_BORDER, 1, 0.15)

	btn.MouseEnter:Connect(function()
		tween(btn, {BackgroundColor3 = Color3.fromRGB(40, 76, 118)}, 0.12)
		local st = btn:FindFirstChildOfClass("UIStroke")
		if st then tween(st, {Color = COLOR_ACCENT}, 0.12) end
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {BackgroundColor3 = COLOR_CARD2}, 0.12)
		local st = btn:FindFirstChildOfClass("UIStroke")
		if st then tween(st, {Color = COLOR_BORDER}, 0.12) end
	end)
	return btn
end

local function createInputWithAvatar(parent, placeholder, order)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -4, 0, 64)
	card.BackgroundColor3 = COLOR_CARD
	card.BorderSizePixel = 0
	card.LayoutOrder = order or 1
	card.Parent = parent
	corner(card, 12)
	stroke(card, COLOR_BORDER, 1, 0.15)

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 46, 0, 46)
	avatar.Position = UDim2.new(0, 11, 0.5, -23)
	avatar.BackgroundColor3 = COLOR_SIDE
	avatar.Image = "rbxassetid://0"
	avatar.Parent = card
	corner(avatar, 23)
	stroke(avatar, COLOR_ACCENT, 1, 0.3)

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -74, 1, -12)
	box.Position = UDim2.new(0, 68, 0, 6)
	box.BackgroundTransparency = 1
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = COLOR_MUTED
	box.Text = ""
	box.TextColor3 = COLOR_TEXT
	box.Font = Enum.Font.Code
	box.TextSize = 12
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	box.Parent = card
	return box, avatar
end

local function createSliderControl(parent, titleText, minValue, maxValue, defaultValue, order, onChanged)
	local card = Instance.new("Frame")
	card.Name = "SliderControl"
	card.Size = UDim2.new(1, -4, 0, 78)
	card.BackgroundColor3 = COLOR_CARD
	card.BorderSizePixel = 0
	card.LayoutOrder = order or 1
	card.Parent = parent
	corner(card, 12)
	stroke(card, COLOR_BORDER, 1, 0.15)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -90, 0, 22)
	title.Position = UDim2.new(0, 12, 0, 7)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = COLOR_TEXT
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local valueBox = Instance.new("TextBox")
	valueBox.Size = UDim2.new(0, 58, 0, 25)
	valueBox.Position = UDim2.new(1, -70, 0, 5)
	valueBox.BackgroundColor3 = COLOR_PANEL
	valueBox.BorderSizePixel = 0
	valueBox.TextColor3 = COLOR_TEXT
	valueBox.PlaceholderColor3 = COLOR_MUTED
	valueBox.Text = tostring(defaultValue)
	valueBox.Font = Enum.Font.Code
	valueBox.TextSize = 12
	valueBox.ClearTextOnFocus = false
	valueBox.TextXAlignment = Enum.TextXAlignment.Center
	valueBox.Parent = card
	corner(valueBox, 8)
	stroke(valueBox, COLOR_BORDER, 1, 0.15)

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -24, 0, 7)
	track.Position = UDim2.new(0, 12, 0, 48)
	track.BackgroundColor3 = COLOR_BORDER
	track.BorderSizePixel = 0
	track.Parent = card
	corner(track, 3)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = COLOR_ACCENT
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 4)

	local FillGradient = Instance.new("UIGradient")
	FillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLOR_ACCENT2),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 190, 255))
	})
	FillGradient.Parent = fill

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.BackgroundColor3 = COLOR_TEXT
	knob.BorderSizePixel = 0
	knob.Active = true
	knob.Parent = track
	corner(knob, 9)
	stroke(knob, COLOR_ACCENT, 1, 0)

	local currentValue = math.clamp(tonumber(defaultValue) or minValue, minValue, maxValue)
	local dragging = false

	local function setValue(value, updateBox)
		value = tonumber(value) or currentValue
		value = math.clamp(math.floor(value + 0.5), minValue, maxValue)
		currentValue = value
		local alpha = (value - minValue) / (maxValue - minValue)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		if updateBox ~= false then
			valueBox.Text = tostring(value)
		end
		if onChanged then
			onChanged(value)
		end
	end

	local function setFromX(x)
		local left = track.AbsolutePosition.X
		local width = track.AbsoluteSize.X
		if width <= 0 then return end
		local alpha = math.clamp((x - left) / width, 0, 1)
		setValue(minValue + (maxValue - minValue) * alpha)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	valueBox.FocusLost:Connect(function()
		local typed = tonumber(valueBox.Text)
		if typed == nil then
			valueBox.Text = tostring(currentValue)
		else
			setValue(typed)
		end
	end)
	setValue(currentValue)
	return {
		card = card,
		setValue = setValue,
		getValue = function()
			return currentValue
		end
	}
end

local function getPlayer(nameStr)
	if not nameStr or nameStr == "" then return nil end
	nameStr = string.lower(nameStr)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local username = string.lower(p.Name)
			local display = string.lower(p.DisplayName)
			if username:sub(1, #nameStr) == nameStr
				or display:sub(1, #nameStr) == nameStr then
				return p
			end
		end
	end
	return nil
end

local HomeTab = createTab("Início", 1)
local AmigosTab = createTab("Amigos", 2)
local TargetTab = createTab("Target", 3)
local GameTab = createTab("Jogo", 4)
local ESPTab = createTab("ESP", 5)
local MiscTab = createTab("Diversos", 6)

Tabs["Início"].button.BackgroundColor3 = COLOR_CARD
Tabs["Início"].icon.TextColor3 = COLOR_ACCENT
Tabs["Início"].label.TextColor3 = COLOR_TEXT
Tabs["Início"].activeBar.Visible = true
ContentFrames["Início"].Visible = true

createSection(HomeTab, "CHOSEN PANEL", "Visão geral da sua sessão e acesso rápido.", 1)

local WelcomeCard = Instance.new("Frame")
WelcomeCard.Size = UDim2.new(1, -4, 0, 124)
WelcomeCard.BackgroundColor3 = COLOR_CARD
WelcomeCard.BorderSizePixel = 0
WelcomeCard.LayoutOrder = 2
WelcomeCard.Parent = HomeTab
corner(WelcomeCard, 12)
stroke(WelcomeCard, COLOR_BORDER, 1, 0.1)

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(0, 78, 0, 78)
AvatarImage.Position = UDim2.new(0, 20, 0.5, -39)
AvatarImage.BackgroundColor3 = COLOR_SIDE
pcall(function()
	AvatarImage.Image = Players:GetUserThumbnailAsync(
		LocalPlayer.UserId,
		Enum.ThumbnailType.AvatarBust,
		Enum.ThumbnailSize.Size420x420
	)
end)
AvatarImage.Parent = WelcomeCard
corner(AvatarImage, 39)
stroke(AvatarImage, COLOR_ACCENT, 2, 0.1)

local AvatarBadge = Instance.new("Frame")
AvatarBadge.Size = UDim2.new(0, 14, 0, 14)
AvatarBadge.Position = UDim2.new(1, -6, 1, -6)
AvatarBadge.BackgroundColor3 = COLOR_SUCCESS
AvatarBadge.BorderSizePixel = 0
AvatarBadge.Parent = AvatarImage
corner(AvatarBadge, 7)
stroke(AvatarBadge, COLOR_CARD, 2, 0.2)

local HeroAccent = Instance.new("Frame")
HeroAccent.Size = UDim2.new(0, 3, 1, -24)
HeroAccent.Position = UDim2.new(0, 8, 0, 12)
HeroAccent.BackgroundColor3 = COLOR_ACCENT
HeroAccent.BorderSizePixel = 0
HeroAccent.Parent = WelcomeCard
corner(HeroAccent, 2)

local WelcomeTitle = Instance.new("TextLabel")
WelcomeTitle.Size = UDim2.new(1, -128, 0, 26)
WelcomeTitle.Position = UDim2.new(0, 116, 0, 26)
WelcomeTitle.BackgroundTransparency = 1
WelcomeTitle.Text = "OLÁ, " .. string.upper(LocalPlayer.DisplayName)
WelcomeTitle.TextColor3 = COLOR_TEXT
WelcomeTitle.Font = Enum.Font.GothamBlack
WelcomeTitle.TextSize = 19
WelcomeTitle.TextXAlignment = Enum.TextXAlignment.Left
WelcomeTitle.TextTruncate = Enum.TextTruncate.AtEnd
WelcomeTitle.Parent = WelcomeCard

local UserSub = Instance.new("TextLabel")
UserSub.Size = UDim2.new(1, -128, 0, 22)
UserSub.Position = UDim2.new(0, 116, 0, 55)
UserSub.BackgroundTransparency = 1
UserSub.Text = "@" .. LocalPlayer.Name
UserSub.TextColor3 = COLOR_ACCENT
UserSub.Font = Enum.Font.Code
UserSub.TextSize = 12
UserSub.TextXAlignment = Enum.TextXAlignment.Left
UserSub.TextTruncate = Enum.TextTruncate.AtEnd
UserSub.Parent = WelcomeCard

local UserStatus = Instance.new("TextLabel")
UserStatus.Size = UDim2.new(0, 200, 0, 18)
UserStatus.Position = UDim2.new(0, 116, 0, 84)
UserStatus.BackgroundColor3 = COLOR_SUCCESS
UserStatus.BackgroundTransparency = 0.88
UserStatus.Text = "USUÁRIO LOCAL  •  SESSÃO ATIVA"
UserStatus.TextColor3 = COLOR_DIM
UserStatus.Font = Enum.Font.Code
UserStatus.TextSize = 9
UserStatus.TextXAlignment = Enum.TextXAlignment.Left
UserStatus.Parent = WelcomeCard
corner(UserStatus, 9)
padding(UserStatus, 9, 6, 0, 0)

local StatsCard = Instance.new("Frame")
StatsCard.Size = UDim2.new(1, -4, 0, 92)
StatsCard.BackgroundColor3 = COLOR_CARD
StatsCard.BorderSizePixel = 0
StatsCard.LayoutOrder = 3
StatsCard.Parent = HomeTab
corner(StatsCard, 12)
stroke(StatsCard, COLOR_BORDER, 1, 0.1)

local PingBox = Instance.new("Frame")
PingBox.Size = UDim2.new(0.5, -14, 1, -20)
PingBox.Position = UDim2.new(0, 10, 0, 10)
PingBox.BackgroundColor3 = COLOR_PANEL
PingBox.BorderSizePixel = 0
PingBox.Parent = StatsCard
corner(PingBox, 9)

local PingCaption = Instance.new("TextLabel")
PingCaption.Size = UDim2.new(1, -20, 0, 16)
PingCaption.Position = UDim2.new(0, 10, 0, 9)
PingCaption.BackgroundTransparency = 1
PingCaption.Text = "CONEXÃO"
PingCaption.TextColor3 = COLOR_MUTED
PingCaption.Font = Enum.Font.GothamMedium
PingCaption.TextSize = 9
PingCaption.TextXAlignment = Enum.TextXAlignment.Left
PingCaption.Parent = PingBox

local PingLabel = Instance.new("TextLabel")
PingLabel.Size = UDim2.new(1, -20, 0, 24)
PingLabel.Position = UDim2.new(0, 10, 0, 32)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "PING  •  ..."
PingLabel.TextColor3 = COLOR_SUCCESS
PingLabel.Font = Enum.Font.Code
PingLabel.TextSize = 16
PingLabel.TextXAlignment = Enum.TextXAlignment.Left
PingLabel.Parent = PingBox

local FpsBox = Instance.new("Frame")
FpsBox.Size = UDim2.new(0.5, -14, 1, -20)
FpsBox.Position = UDim2.new(0.5, 4, 0, 10)
FpsBox.BackgroundColor3 = COLOR_PANEL
FpsBox.BorderSizePixel = 0
FpsBox.Parent = StatsCard
corner(FpsBox, 9)

local FpsCaption = Instance.new("TextLabel")
FpsCaption.Size = UDim2.new(1, -20, 0, 16)
FpsCaption.Position = UDim2.new(0, 10, 0, 9)
FpsCaption.BackgroundTransparency = 1
FpsCaption.Text = "DESEMPENHO"
FpsCaption.TextColor3 = COLOR_MUTED
FpsCaption.Font = Enum.Font.GothamMedium
FpsCaption.TextSize = 9
FpsCaption.TextXAlignment = Enum.TextXAlignment.Left
FpsCaption.Parent = FpsBox

local FpsLabel = Instance.new("TextLabel")
FpsLabel.Size = UDim2.new(1, -20, 0, 24)
FpsLabel.Position = UDim2.new(0, 10, 0, 32)
FpsLabel.BackgroundTransparency = 1
FpsLabel.Text = "FPS  •  ..."
FpsLabel.TextColor3 = COLOR_ACCENT
FpsLabel.Font = Enum.Font.Code
FpsLabel.TextSize = 16
FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
FpsLabel.Parent = FpsBox

local safeClock = (type(os) == "table" and type(os.clock) == "function" and os.clock)
	or (type(tick) == "function" and tick)
	or function() return 0 end
local frameCount, lastTime = 0, safeClock()

RunService.RenderStepped:Connect(function()
	frameCount += 1
	local now = safeClock()
	if now - lastTime >= 1 then
		FpsLabel.Text = "FPS  •  " .. frameCount
		frameCount = 0
		lastTime = now
	end
end)

task.spawn(function()
	while task.wait(1) do
		pcall(function()
			local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			PingLabel.Text = "PING  •  " .. math.floor(ping) .. " ms"
		end)
	end
end)

createSection(HomeTab, "Acesso rápido", "Comandos principais da interface.", 4)
local HomeActions = createControlRow(HomeTab, 5)
local HomeRejoinButton = createActionButton(HomeActions, "REJOIN", 1)
HomeRejoinButton.TextSize = 13
HomeRejoinButton.Font = Enum.Font.GothamBlack
HomeRejoinButton.MouseButton1Click:Connect(function()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
end)
local HomeToggleButton = createActionButton(HomeActions, "B  •  ABRIR / FECHAR", 2)
HomeToggleButton.TextSize = 11
HomeToggleButton.Font = Enum.Font.GothamMedium

createSection(HomeTab, "Servidores", "Veja os servidores públicos disponíveis e escolha onde entrar.", 6)
local ServerToolbar = createControlRow(HomeTab, 7)
local RefreshServersButton = createActionButton(ServerToolbar, "Atualizar", 1)
RefreshServersButton.Size = UDim2.new(0, 78, 0, 26)
RefreshServersButton.Position = UDim2.new(0, 0, 0.5, -13)
RefreshServersButton.TextSize = 10
RefreshServersButton.Font = Enum.Font.GothamMedium

local ServerStatusLabel = Instance.new("TextLabel")
ServerStatusLabel.Size = UDim2.new(0.5, -10, 1, 0)
ServerStatusLabel.Position = UDim2.new(0.5, 5, 0, 0)
ServerStatusLabel.BackgroundTransparency = 1
ServerStatusLabel.Text = "Nenhuma lista carregada"
ServerStatusLabel.TextColor3 = COLOR_DIM
ServerStatusLabel.Font = Enum.Font.Code
ServerStatusLabel.TextSize = 10
ServerStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
ServerStatusLabel.Parent = ServerToolbar

local ServerList = Instance.new("ScrollingFrame")
ServerList.Name = "ServerList"
ServerList.Size = UDim2.new(1, -4, 0, 190)
ServerList.BackgroundColor3 = COLOR_CARD
ServerList.BorderSizePixel = 0
ServerList.ScrollBarThickness = 3
ServerList.CanvasSize = UDim2.new(0, 0, 0, 0)
ServerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ServerList.LayoutOrder = 8
ServerList.Parent = HomeTab
corner(ServerList, 10)
stroke(ServerList, COLOR_BORDER, 1, 0.1)

local ServerListLayout = Instance.new("UIListLayout")
ServerListLayout.Padding = UDim.new(0, 6)
ServerListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ServerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ServerListLayout.Parent = ServerList

local ServerListPadding = Instance.new("UIPadding")
ServerListPadding.PaddingTop = UDim.new(0, 8)
ServerListPadding.PaddingBottom = UDim.new(0, 8)
ServerListPadding.PaddingLeft = UDim.new(0, 8)
ServerListPadding.PaddingRight = UDim.new(0, 8)
ServerListPadding.Parent = ServerList

local function clearServerList()
	for _, child in ipairs(ServerList:GetChildren()) do
		if child:IsA("GuiObject") and child ~= ServerListLayout and child ~= ServerListPadding then
			child:Destroy()
		end
	end
end

local function addServerEntry(server, index)
	local maxPlayers = tonumber(server.maxPlayers) or 0
	local playing = tonumber(server.playing) or 0
	local ping = tonumber(server.ping)
	local id = server.id

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 46)
	row.BackgroundColor3 = COLOR_CARD2
	row.BorderSizePixel = 0
	row.LayoutOrder = index
	row.Parent = ServerList
	corner(row, 8)

	local gameThumb = Instance.new("ImageLabel")
	gameThumb.Size = UDim2.new(0, 38, 0, 38)
	gameThumb.Position = UDim2.new(0, 6, 0.5, -19)
	gameThumb.BackgroundTransparency = 1
	gameThumb.Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150"
	gameThumb.ScaleType = Enum.ScaleType.Crop
	gameThumb.Parent = row
	corner(gameThumb, 7)

	local playersLabel = Instance.new("TextLabel")
	playersLabel.Size = UDim2.new(0, 105, 0, 16)
	playersLabel.Position = UDim2.new(0, 52, 0, 25)
	playersLabel.BackgroundTransparency = 1
	playersLabel.Text = string.format("%d / %d jogadores", playing, maxPlayers)
	playersLabel.TextColor3 = COLOR_DIM
	playersLabel.Font = Enum.Font.Code
	playersLabel.TextSize = 10
	playersLabel.TextXAlignment = Enum.TextXAlignment.Left
	playersLabel.Parent = row

	local pingLabel = Instance.new("TextLabel")
	pingLabel.Size = UDim2.new(0, 70, 0, 16)
	pingLabel.Position = UDim2.new(0, 158, 0, 25)
	pingLabel.BackgroundTransparency = 1
	pingLabel.Text = string.format("%s ms", ping and math.floor(ping) or "?")
	pingLabel.TextColor3 = COLOR_SUCCESS
	pingLabel.Font = Enum.Font.Code
	pingLabel.TextSize = 10
	pingLabel.TextXAlignment = Enum.TextXAlignment.Left
	pingLabel.Parent = row

	local join = createActionButton(row, "ENTRAR", 1)
	join.Size = UDim2.new(0, 92, 0, 32)
	join.Position = UDim2.new(1, -100, 0.5, -16)
	join.TextSize = 10
	join.MouseButton1Click:Connect(function()
		if not id then return end
		ServerStatusLabel.Text = "Entrando no servidor..."
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LocalPlayer)
		end)
	end)
end

local function loadPublicServers()
	clearServerList()
	ServerStatusLabel.Text = "Carregando..."
	task.spawn(function()
		local ok, result = pcall(function()
			local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
			local response = game:HttpGet(url)
			return HttpService:JSONDecode(response)
		end)
		if not ok or type(result) ~= "table" or type(result.data) ~= "table" then
			ServerStatusLabel.Text = "Não foi possível carregar os servidores"
			return
		end
		local shown = 0
		for _, server in ipairs(result.data) do
			if server.id ~= game.JobId and (tonumber(server.playing) or 0) < (tonumber(server.maxPlayers) or 0) then
				shown += 1
				addServerEntry(server, shown)
				if shown >= 25 then break end
			end
		end
		ServerStatusLabel.Text = shown > 0 and (shown .. " servidores disponíveis") or "Nenhum servidor disponível"
	end)
end
RefreshServersButton.MouseButton1Click:Connect(loadPublicServers)
task.defer(loadPublicServers)

-- Target Tab
createSection(TargetTab, "Alvo", "Selecione um jogador para usar os recursos.", 1)
local TInput, TAvatarPreview = createInputWithAvatar(TargetTab, "Digite o nome do jogador...", 2)

local TargetStatus = Instance.new("TextLabel")
TargetStatus.Size = UDim2.new(1, -4, 0, 24)
TargetStatus.BackgroundTransparency = 1
TargetStatus.Text = "●  NENHUM ALVO SELECIONADO"
TargetStatus.TextColor3 = COLOR_MUTED
TargetStatus.Font = Enum.Font.Code
TargetStatus.TextSize = 9
TargetStatus.TextXAlignment = Enum.TextXAlignment.Left
TargetStatus.LayoutOrder = 3
TargetStatus.Parent = TargetTab

TInput:GetPropertyChangedSignal("Text"):Connect(function()
	local t = getPlayer(TInput.Text)
	if t then
		pcall(function()
			TAvatarPreview.Image = Players:GetUserThumbnailAsync(
				t.UserId,
				Enum.ThumbnailType.AvatarBust,
				Enum.ThumbnailSize.Size420x420
			)
		end)
		TargetStatus.Text = "●  ALVO  •  " .. t.DisplayName
		TargetStatus.TextColor3 = COLOR_SUCCESS
	else
		TAvatarPreview.Image = "rbxassetid://0"
		TargetStatus.Text = "●  NENHUM ALVO SELECIONADO"
		TargetStatus.TextColor3 = COLOR_MUTED
	end
end)

local isSpectating = false
local isFollowing = false
local headsizeEnabled = false
local followConnection = nil
local headsizeConnection = nil

createSection(TargetTab, "Ações do alvo", "movimento e câmera", 4)
local TargetRow1 = createControlRow(TargetTab, 5)
createToggleButton(TargetRow1, "Observar alvo", function(state)
	local t = getPlayer(TInput.Text)
	isSpectating = state
	if isSpectating and t and t.Character and t.Character:FindFirstChild("Humanoid") then
		Camera.CameraSubject = t.Character.Humanoid
		TargetStatus.Text = "●  OBSERVANDO  •  " .. t.DisplayName
	else
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			Camera.CameraSubject = LocalPlayer.Character.Humanoid
		end
		TargetStatus.Text = "●  CÂMERA RESTAURADA"
	end
end, 1)

local tpButton = createActionButton(TargetRow1, "Teleportar até o alvo", 2)
tpButton.MouseButton1Click:Connect(function()
	local t = getPlayer(TInput.Text)
	if t and t.Character
		and t.Character:FindFirstChild("HumanoidRootPart")
		and LocalPlayer.Character
		and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		LocalPlayer.Character.HumanoidRootPart.CFrame =
			t.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
		TargetStatus.Text = "●  TELEPORTADO  •  " .. t.DisplayName
		TargetStatus.TextColor3 = COLOR_SUCCESS
	end
end)

local TargetRow2 = createControlRow(TargetTab, 6)
createToggleButton(TargetRow2, "Seguir alvo", function(state)
	local t = getPlayer(TInput.Text)
	isFollowing = state
	if followConnection then
		followConnection:Disconnect()
		followConnection = nil
	end
	if isFollowing and t then
		TargetStatus.Text = "●  SEGUINDO  •  " .. t.DisplayName
		followConnection = RunService.Heartbeat:Connect(function()
			if not isFollowing then return end
			if t.Character
				and t.Character:FindFirstChild("HumanoidRootPart")
				and LocalPlayer.Character
				and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				LocalPlayer.Character.HumanoidRootPart.CFrame =
					t.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
			end
		end)
	else
		TargetStatus.Text = "●  SEGUIR DESATIVADO"
	end
end, 1)

createToggleButton(TargetRow2, "Headsit", function(state)
	local t = getPlayer(TInput.Text)
	headsizeEnabled = state
	if headsizeConnection then
		headsizeConnection:Disconnect()
		headsizeConnection = nil
	end
	if headsizeEnabled and t then
		TargetStatus.Text = "●  HEADSIZE  •  " .. t.DisplayName
		headsizeConnection = RunService.Heartbeat:Connect(function()
			if not headsizeEnabled then return end
			local targetChar = t.Character
			local localChar = LocalPlayer.Character
			if not targetChar or not localChar then return end
			local targetHead = targetChar:FindFirstChild("Head")
			local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
			local localRoot = localChar:FindFirstChild("HumanoidRootPart")
			local localHumanoid = localChar:FindFirstChildOfClass("Humanoid")
			if targetHead and targetHumanoid and localRoot and localHumanoid
				and targetHumanoid.Health > 0 then
				local localHeight = math.max(localHumanoid.HipHeight, 2)
				local offsetY = localHeight + 0.25
				localRoot.CFrame = targetHead.CFrame * CFrame.new(0, offsetY, 0)
				localRoot.AssemblyLinearVelocity = Vector3.zero
				localRoot.AssemblyAngularVelocity = Vector3.zero
				localHumanoid.Sit = true
			end
		end)
	else
		TargetStatus.Text = "●  HEADSIZE DESATIVADO"
	end
end, 2)

local TargetRow3 = createControlRow(TargetTab, 7)
local copyButton = createActionButton(TargetRow3, "Copiar ferramentas", 1, true)
copyButton.MouseButton1Click:Connect(function()
	local t = getPlayer(TInput.Text)
	if t and t:FindFirstChild("Backpack") and LocalPlayer:FindFirstChild("Backpack") then
		local count = 0
		for _, tool in ipairs(t.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Clone().Parent = LocalPlayer.Backpack
				count += 1
			end
		end
		TargetStatus.Text = "●  COPIADO  •  " .. count .. " FERRAMENTAS"
	end
end)

local clearTargetButton = createActionButton(TargetRow3, "Limpar alvo", 2, true)
clearTargetButton.MouseButton1Click:Connect(function()
	TInput.Text = ""
	TAvatarPreview.Image = "rbxassetid://0"
	TargetStatus.Text = "●  NENHUM ALVO SELECIONADO"
	TargetStatus.TextColor3 = COLOR_MUTED
end)

-- Amigos Tab
pcall(function()
	createSection(AmigosTab, "Amigos no servidor", "Amizades do Roblox que estão neste servidor.", 1)
	local AmigosToolbar = createControlRow(AmigosTab, 2)
	local SearchFriendsBox = Instance.new("TextBox")
	SearchFriendsBox.Name = "SearchFriendsBox"
	SearchFriendsBox.Size = UDim2.new(0.5, -12, 1, 0)
	SearchFriendsBox.BackgroundColor3 = COLOR_CARD
	SearchFriendsBox.BorderSizePixel = 0
	SearchFriendsBox.PlaceholderText = "Buscar por nome ou @user"
	SearchFriendsBox.PlaceholderColor3 = COLOR_MUTED
	SearchFriendsBox.Text = ""
	SearchFriendsBox.TextColor3 = COLOR_TEXT
	SearchFriendsBox.Font = Enum.Font.Gotham
	SearchFriendsBox.TextSize = 12
	SearchFriendsBox.TextXAlignment = Enum.TextXAlignment.Left
	SearchFriendsBox.ClearTextOnFocus = false
	SearchFriendsBox.Parent = AmigosToolbar
	corner(SearchFriendsBox, 8)
	stroke(SearchFriendsBox, COLOR_BORDER, 1, 0.2)
	padding(SearchFriendsBox, 10, 8, 0, 0)

	local RefreshFriendsButton = createActionButton(AmigosToolbar, "ATUALIZAR", 2)
	local FriendsStatusLabel = Instance.new("TextLabel")
	FriendsStatusLabel.Name = "FriendsStatusLabel"
	FriendsStatusLabel.Size = UDim2.new(1, -4, 0, 16)
	FriendsStatusLabel.BackgroundTransparency = 1
	FriendsStatusLabel.Text = "Nenhuma busca feita ainda"
	FriendsStatusLabel.TextColor3 = COLOR_MUTED
	FriendsStatusLabel.Font = Enum.Font.Code
	FriendsStatusLabel.TextSize = 9
	FriendsStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	FriendsStatusLabel.LayoutOrder = 3
	FriendsStatusLabel.Parent = AmigosTab

	local FriendsList = Instance.new("ScrollingFrame")
	FriendsList.Name = "FriendsList"
	FriendsList.Size = UDim2.new(1, -4, 0, 300)
	FriendsList.BackgroundColor3 = COLOR_CARD
	FriendsList.BorderSizePixel = 0
	FriendsList.ScrollBarThickness = 3
	FriendsList.CanvasSize = UDim2.new(0, 0, 0, 0)
	FriendsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	FriendsList.LayoutOrder = 4
	FriendsList.Parent = AmigosTab
	corner(FriendsList, 10)
	stroke(FriendsList, COLOR_BORDER, 1, 0.15)

	local FriendsListLayout = Instance.new("UIListLayout")
	FriendsListLayout.Padding = UDim.new(0, 6)
	FriendsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	FriendsListLayout.Parent = FriendsList

	local FriendsListPadding = Instance.new("UIPadding")
	FriendsListPadding.PaddingTop = UDim.new(0, 8)
	FriendsListPadding.PaddingBottom = UDim.new(0, 8)
	FriendsListPadding.PaddingLeft = UDim.new(0, 8)
	FriendsListPadding.PaddingRight = UDim.new(0, 8)
	FriendsListPadding.Parent = FriendsList

	local friendEntries = {}
	local selectedFriendStroke = nil

	local function applyFriendFilter()
		local query = string.lower(SearchFriendsBox.Text or "")
		query = query:gsub("^@", "")
		for _, entry in pairs(friendEntries) do
			local match = query == ""
				or string.find(string.lower(entry.username), query, 1, true)
				or string.find(string.lower(entry.display), query, 1, true)
			entry.row.Visible = match
		end
	end
	SearchFriendsBox:GetPropertyChangedSignal("Text"):Connect(applyFriendFilter)

	local function clearFriendList()
		for _, child in ipairs(FriendsList:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end
		end
		friendEntries = {}
		selectedFriendStroke = nil
	end

	local function markFriendAsTarget(player, row)
		TInput.Text = player.Name
		FriendsStatusLabel.Text = "● ALVO • " .. player.DisplayName
		FriendsStatusLabel.TextColor3 = COLOR_SUCCESS
		if selectedFriendStroke then
			tween(selectedFriendStroke, {Color = COLOR_BORDER}, 0.10)
		end
		selectedFriendStroke = row:FindFirstChildOfClass("UIStroke")
		if selectedFriendStroke then
			tween(selectedFriendStroke, {Color = COLOR_SUCCESS}, 0.12)
		end
	end

	local function addFriendEntry(player, index)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -4, 0, 64)
		row.BackgroundColor3 = COLOR_CARD2
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = FriendsList
		corner(row, 10)
		stroke(row, COLOR_BORDER, 1, 0.15)

		local avatar = Instance.new("ImageLabel")
		avatar.Size = UDim2.new(0, 44, 0, 44)
		avatar.Position = UDim2.new(0, 10, 0.5, -22)
		avatar.BackgroundColor3 = COLOR_SIDE
		pcall(function()
			avatar.Image = Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.AvatarBust,
				Enum.ThumbnailSize.Size420x420
			)
		end)
		avatar.Parent = row
		corner(avatar, 22)
		stroke(avatar, COLOR_ACCENT, 1, 0.3)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0, 190, 0, 18)
		nameLabel.Position = UDim2.new(0, 66, 0, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = player.DisplayName
		nameLabel.TextColor3 = COLOR_TEXT
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = row

		local userLabel = Instance.new("TextLabel")
		userLabel.Size = UDim2.new(0, 190, 0, 14)
		userLabel.Position = UDim2.new(0, 66, 0, 27)
		userLabel.BackgroundTransparency = 1
		userLabel.Text = "@" .. player.Name
		userLabel.TextColor3 = COLOR_MUTED
		userLabel.Font = Enum.Font.Code
		userLabel.TextSize = 10
		userLabel.TextXAlignment = Enum.TextXAlignment.Left
		userLabel.TextTruncate = Enum.TextTruncate.AtEnd
		userLabel.Parent = row

		local onlineLabel = Instance.new("TextLabel")
		onlineLabel.Size = UDim2.new(0, 190, 0, 14)
		onlineLabel.Position = UDim2.new(0, 66, 0, 44)
		onlineLabel.BackgroundTransparency = 1
		onlineLabel.Text = "Neste servidor"
		onlineLabel.TextColor3 = COLOR_SUCCESS
		onlineLabel.Font = Enum.Font.Code
		onlineLabel.TextSize = 9
		onlineLabel.TextXAlignment = Enum.TextXAlignment.Left
		onlineLabel.Parent = row

		local alvoBtn = createActionButton(row, "ALVO", 1)
		alvoBtn.Size = UDim2.new(0, 64, 0, 28)
		alvoBtn.Position = UDim2.new(1, -214, 0.5, -14)
		alvoBtn.TextSize = 10
		alvoBtn.MouseButton1Click:Connect(function()
			markFriendAsTarget(player, row)
		end)

		local obsBtn = createActionButton(row, "OBS", 2)
		obsBtn.Size = UDim2.new(0, 64, 0, 28)
		obsBtn.Position = UDim2.new(1, -142, 0.5, -14)
		obsBtn.TextSize = 10
		obsBtn.MouseButton1Click:Connect(function()
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end
			if isSpectating and Camera.CameraSubject == humanoid then
				isSpectating = false
				local myHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
				if myHumanoid then Camera.CameraSubject = myHumanoid end
				FriendsStatusLabel.Text = "● CÂMERA RESTAURADA"
			else
				isSpectating = true
				Camera.CameraSubject = humanoid
				FriendsStatusLabel.Text = "● OBSERVANDO • " .. player.DisplayName
			end
		end)

		local tpBtn = createActionButton(row, "TP", 3)
		tpBtn.Size = UDim2.new(0, 64, 0, 28)
		tpBtn.Position = UDim2.new(1, -70, 0.5, -14)
		tpBtn.TextSize = 10
		tpBtn.MouseButton1Click:Connect(function()
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				pcall(function()
					LocalPlayer.Character.HumanoidRootPart.CFrame =
						player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
				end)
				FriendsStatusLabel.Text = "● TELEPORTADO • " .. player.DisplayName
			end
		end)

		friendEntries[player.UserId] = {
			row = row,
			username = player.Name,
			display = player.DisplayName
		}
	end

	local function loadFriendsInServer()
		clearFriendList()
		FriendsStatusLabel.Text = "Buscando amizades..."
		task.spawn(function()
			local friendsFound = 0
			local ok, pages = pcall(function()
				return Players:GetFriendsAsync(LocalPlayer.UserId)
			end)
			if not ok or not pages then
				FriendsStatusLabel.Text = "Falha ao carregar amigos"
				return
			end
			repeat
				local okPage, page = pcall(function() return pages:GetCurrentPage() end)
				if not okPage or not page then break end
				for _, friend in ipairs(page) do
					local friendPlayer = Players:GetPlayerByUserId(friend.Id)
					if friendPlayer then
						friendsFound += 1
						addFriendEntry(friendPlayer, friendsFound)
						applyFriendFilter()
					end
				end
				local advanced = pcall(function() pages:AdvanceToNextPageAsync() end)
			until (not advanced) or pages.IsFinished
			FriendsStatusLabel.Text = friendsFound > 0 and (friendsFound .. " amigo(s) neste servidor") or "Nenhum amigo neste servidor"
		end)
	end
	RefreshFriendsButton.MouseButton1Click:Connect(loadFriendsInServer)
	task.defer(loadFriendsInServer)
end)

-- Jogo Tab
createSection(GameTab, "Jogo", "Movimento, atalhos e utilidades.", 1)
local noclip = false
local noclipHotkeyEnabled = false
local noclipSetState
local clickTp = false
local flashback = false
local flyHotkeyEnabled = false
local flying = false
local flyConnection = nil
local flyVelocity = nil
local flyGyro = nil
local flySpeed = 55
local stopFly
local startFly
local animationSpeedEnabled = false
local animationSpeed = 1
local impulseHotkeyEnabled = false
local impulseIsImpulsing = false
local impulseSavedCFrame = nil
local impulseLoopConnection = nil
local impulseCharacter = nil
local impulseHRP = nil
local stopImpulseLoop
local restoreImpulse

stopImpulseLoop = function()
	if impulseLoopConnection then
		impulseLoopConnection:Disconnect()
		impulseLoopConnection = nil
	end
end

restoreImpulse = function()
	impulseIsImpulsing = false
	stopImpulseLoop()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		impulseSavedCFrame = nil
		return
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	if impulseSavedCFrame then
		root.CFrame = impulseSavedCFrame
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum.PlatformStand = false
			hum.AutoRotate = true
			hum.Sit = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			task.defer(function()
				if hum and hum.Parent then
					hum.PlatformStand = false
					hum.AutoRotate = true
					hum:ChangeState(Enum.HumanoidStateType.Running)
				end
			end)
		end)
	end
end

local function startImpulse()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not char or not root then return end
	impulseCharacter = char
	impulseHRP = root
	if impulseIsImpulsing then
		restoreImpulse()
		return
	end
	impulseIsImpulsing = true
	impulseSavedCFrame = root.CFrame
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum.PlatformStand = true
			hum.AutoRotate = false
			hum:ChangeState(Enum.HumanoidStateType.Physics)
		end)
	end
	impulseLoopConnection = RunService.Heartbeat:Connect(function()
		if not impulseIsImpulsing then return end
		if not impulseHRP or not impulseHRP.Parent then
			restoreImpulse()
			return
		end
		local camera = workspace.CurrentCamera
		local look = camera and camera.CFrame.LookVector or Vector3.new(0, 0, -1)
		local horizontal = Vector3.new(look.X, 0, look.Z)
		if horizontal.Magnitude < 0.05 then
			horizontal = Vector3.new(0, 0, -1)
		else
			horizontal = horizontal.Unit
		end
		local side = Vector3.new(-horizontal.Z, 0, horizontal.X)
		local forwardSpeed = math.random(300, 600)
		local sideSpeed = math.random(-350, 350)
		local verticalSpeed = math.random(-250, 450)
		impulseHRP.AssemblyLinearVelocity =
			horizontal * forwardSpeed +
			side * sideSpeed +
			Vector3.new(0, verticalSpeed, 0)
		impulseHRP.AssemblyAngularVelocity = Vector3.new(
			math.random(-50, 50),
			math.random(-50, 50),
			math.random(-50, 50)
		)
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if UserInputService:GetFocusedTextBox() then return end
	if impulseHotkeyEnabled and input.KeyCode == Enum.KeyCode.M then
		startImpulse()
	end
end)

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
	stopImpulseLoop()
	impulseIsImpulsing = false
	impulseSavedCFrame = nil
	impulseCharacter = newCharacter
	impulseHRP = newCharacter:WaitForChild("HumanoidRootPart")
end)

local history = {}
local maxHistory = 300
local isRewinding = false

local GameRow1 = createControlRow(GameTab, 2)
local _, setNoclipState = createToggleButton(GameRow1, "Noclip  •  N = alternar", function(state)
	noclip = state
	noclipHotkeyEnabled = state
end, 1)
noclipSetState = setNoclipState

RunService.Stepped:Connect(function()
	if noclip and LocalPlayer.Character then
		for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end
end)

createToggleButton(GameRow1, "Click TP  •  Ctrl + M1", function(state)
	clickTp = state
end, 2)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if clickTp and not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			and Mouse.Hit then
			LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
		end
	end
end)

local GameRow2 = createControlRow(GameTab, 3)
createToggleButton(GameRow2, "Flashback  •  Segure V", function(state)
	flashback = state
	if not state then history = {} isRewinding = false end
end, 1)

createToggleButton(GameRow2, "Fly  •  Tecla F", function(state)
	flyHotkeyEnabled = state
	if not state and flying then stopFly() end
end, 2)

stopFly = function()
	flying = false
	if flyConnection then flyConnection:Disconnect() flyConnection = nil end
	if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
	if flyGyro then flyGyro:Destroy() flyGyro = nil end
end

startFly = function()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	stopFly()
	flying = true
	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyVelocity.Velocity = Vector3.zero
	flyVelocity.Parent = hrp

	flyGyro = Instance.new("BodyGyro")
	flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyGyro.P = 1e4
	flyGyro.CFrame = hrp.CFrame
	flyGyro.Parent = hrp

	flyConnection = RunService.RenderStepped:Connect(function()
		if not flying or not flyVelocity or not flyGyro then return end
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not root then stopFly() return end
		local move = Vector3.zero
		local cf = Camera.CFrame
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.yAxis end
		flyVelocity.Velocity = move.Magnitude > 0 and move.Unit * flySpeed or Vector3.zero
		flyGyro.CFrame = CFrame.new(root.Position, root.Position + cf.LookVector)
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and flyHotkeyEnabled and input.KeyCode == Enum.KeyCode.F then
		if flying then stopFly() else startFly() end
	end
end)

createSection(GameTab, "Velocidade do Fly", "Ajuste de 1 até 300.", 6)
createSliderControl(GameTab, "Velocidade do voo", 1, 300, flySpeed, 7, function(value)
	flySpeed = value
end)

local GameRow3 = createControlRow(GameTab, 4)
createToggleButton(GameRow3, "Anim Speed  •  Q|E", function(state)
	animationSpeedEnabled = state
	animationSpeed = 1
end, 1)
createToggleButton(GameRow3, "Impulse  •  Tecla M", function(state)
	impulseHotkeyEnabled = state
	if not state then
		if impulseIsImpulsing then
			restoreImpulse()
		else
			stopImpulseLoop()
		end
	end
end, 2)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() or not animationSpeedEnabled then return end
	if input.KeyCode == Enum.KeyCode.Q then
		animationSpeed = (animationSpeed == 4) and 1.35 or 4
	elseif input.KeyCode == Enum.KeyCode.E then
		animationSpeed = (animationSpeed == 0.5) and 1.35 or 0.5
	end
end)

RunService.RenderStepped:Connect(function()
	if not animationSpeedEnabled then return end
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		pcall(function() track:AdjustSpeed(animationSpeed) end)
	end
end)

RunService.Heartbeat:Connect(function()
	if not flashback then return end
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if not isRewinding then
		table.insert(history, {cframe = hrp.CFrame})
		if #history > maxHistory then table.remove(history, 1) end
	elseif #history > 0 then
		local snapshot = table.remove(history, #history)
		hrp.CFrame = snapshot.cframe
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == Enum.KeyCode.N and noclipHotkeyEnabled and not UserInputService:GetFocusedTextBox() then
		noclip = not noclip
	end
	if flashback and not gp and input.KeyCode == Enum.KeyCode.V then isRewinding = true end
end)
UserInputService.InputEnded:Connect(function(input, gp)
	if flashback and not gp and input.KeyCode == Enum.KeyCode.V then isRewinding = false end
end)

--------------------------------------------------------------------------------
-- ABA ESP INTEGRADA
--------------------------------------------------------------------------------
createSection(ESPTab, "VISUALIZAÇÃO", "Role ESP: Box, Nome, Distância e Inocentes", 1)

local roleEspEnabled = false
local teamCheck = false
local wallCheck = false

local aimbotEnabled = false
local showFov = false
local fovRainbow = false
local targetPart = "Head"
local fovRadius = 150
local smoothingFactor = 0.5
local hue = 0

local espObjects = {}

local Roles = {}

local function UpdateRoles()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local role = 

			if p.Character then
				if p.Character:FindFirstChild("Knife") or p.Character:FindFirstChild("Combat") then
					role = "Murderer"
				elseif p.Character:FindFirstChild("Gun") or p.Character:FindFirstChild("Revolver") then
					role = "Sheriff"
				end
			end

			if role ==  and p:FindFirstChild("Backpack") then
				if p.Backpack:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Combat") then
					role = "Murderer"
				elseif p.Backpack:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Revolver") then
					role = "Sheriff"
				end
			end

			Roles[p] = role
		end
	end
end

local function GetRoleColor(role)
	if role == "Murderer" then return Color3.fromRGB(255, 50, 50) end
	if role == "Sheriff" or role == "Hero" then return Color3.fromRGB(50, 100, 255) end
	return Color3.fromRGB(50, 255, 50)
end

createToggleButton(ESPTab, "ESP  •  wallhack", function(state)
	roleEspEnabled = state
end, 2)

createSection(ESPTab, "AIMBOT", "Mira automática com FOV ajustável", 4)

local AimbotRow1 = createControlRow(ESPTab, 5)
createToggleButton(AimbotRow1, "Aimbot (Segure M2)", function(state) aimbotEnabled = state end, 1)
createToggleButton(AimbotRow1, "Exibir FOV", function(state) showFov = state end, 2)

local AimbotRow2 = createControlRow(ESPTab, 6)
createToggleButton(AimbotRow2, "FOV RGB", function(state) fovRainbow = state end, 1)

createSliderControl(ESPTab, "Raio do FOV", 50, 500, fovRadius, 7, function(value)
	fovRadius = value
end)

createSliderControl(ESPTab, "Suavização Aimbot", 0, 10, smoothingFactor * 10, 8, function(value)
	smoothingFactor = value / 10
end)

createSection(ESPTab, "PARTE ALVO", "Selecionar parte do corpo para mira", 9)
local PartRow = createControlRow(ESPTab, 10)
local partButton = createActionButton(PartRow, "Parte: " .. targetPart, 1)
partButton.MouseButton1Click:Connect(function()
	local parts = {"Head", "HumanoidRootPart", "Torso"}
	local idx = 1
	for i, p in ipairs(parts) do
		if p == targetPart then idx = i break end
	end
	idx = idx % #parts + 1
	targetPart = parts[idx]
	partButton.Text = "Parte: " .. targetPart
end)

local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Thickness = 2
fovCircle.Radius = fovRadius
fovCircle.Transparency = 1
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local function createESP(player)
	if player == LocalPlayer or espObjects[player] then return end

	local box = Drawing.new("Square")
	box.Filled = false
	box.Thickness = 1
	box.Visible = false

	local boxOutline = Drawing.new("Square")
	boxOutline.Filled = false
	boxOutline.Thickness = 3
	boxOutline.Color = Color3.new(0, 0, 0)
	boxOutline.Visible = false

	local nameTag = Drawing.new("Text")
	nameTag.Center = true
	nameTag.Outline = true
	nameTag.Size = 14
	nameTag.Font = 2
	nameTag.Visible = false

	local distanceText = Drawing.new("Text")
	distanceText.Center = true
	distanceText.Outline = true
	distanceText.Size = 12
	distanceText.Font = 2
	distanceText.Color = Color3.new(1, 1, 1)
	distanceText.Visible = false

	espObjects[player] = {
		box = box,
		boxOutline = boxOutline,
		nameTag = nameTag,
		distanceText = distanceText
	}
end

local function removeESP(player)
	if espObjects[player] then
		for _, drawing in pairs(espObjects[player]) do
			pcall(function()
				drawing.Visible = false
				drawing:Remove()
			end)
		end
		espObjects[player] = nil
	end
end

for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

local function isVisible(part)
	if not wallCheck then return true end
	local origin = Camera.CFrame.Position
	local direction = (part.Position - origin)
	local ray = Ray.new(origin, direction.Unit * math.min(direction.Magnitude, 1000))
	local hitPart = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character}, false, true)
	if hitPart then
		return hitPart:IsDescendantOf(part.Parent)
	end
	return false
end

local function getClosestPart()
	local closestPart = nil
	local shortestDist = fovRadius
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(targetPart) then
			if teamCheck and player.Team == LocalPlayer.Team then continue end
			local part = player.Character[targetPart]
			local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
			local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
			if onScreen and dist < shortestDist and isVisible(part) then
				shortestDist = dist
				closestPart = part
			end
		end
	end
	return closestPart
end

local function smoothLookAt(target)
	local startCFrame = Camera.CFrame
	local endCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
	Camera.CFrame = startCFrame:Lerp(endCFrame, 1 - smoothingFactor)
end

RunService.RenderStepped:Connect(function()
	UpdateRoles()

	fovCircle.Visible = showFov and aimbotEnabled
	fovCircle.Radius = fovRadius
	fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	if fovRainbow then
		hue = (hue + 0.005) % 1
		fovCircle.Color = Color3.fromHSV(hue, 1, 1)
	else
		fovCircle.Color = COLOR_ACCENT
	end

	for player, esp in pairs(espObjects) do
		local role = Roles[player]
		local char = player.Character

		local function hideAll()
			esp.box.Visible = false
			esp.boxOutline.Visible = false
			esp.nameTag.Visible = false
			esp.distanceText.Visible = false
		end

		if player == LocalPlayer or not player.Parent or not roleEspEnabled then
			hideAll()
		elseif not char
			or not char:FindFirstChild("HumanoidRootPart")
			or not char:FindFirstChildOfClass("Humanoid")
			or char:FindFirstChildOfClass("Humanoid").Health <= 0 then
			hideAll()
		else
			local torso = char.HumanoidRootPart
			local dist = (Camera.CFrame.Position - torso.Position).Magnitude

			local pos, onScreen = Camera:WorldToViewportPoint(torso.Position)
			if not onScreen then
				hideAll()
			else
				local topPos = Camera:WorldToViewportPoint(torso.Position + Vector3.new(0, 2.5, 0))
				local botPos = Camera:WorldToViewportPoint(torso.Position - Vector3.new(0, 3.0, 0))
				local h = math.abs(topPos.Y - botPos.Y)
				if h < 1 then
					hideAll()
				else
					local w = h / 1.5
					local col = GetRoleColor(role)

					esp.box.Size = Vector2.new(w, h)
					esp.box.Position = Vector2.new(pos.X - w/2, topPos.Y)
					esp.box.Color = col
					esp.box.Visible = true

					esp.boxOutline.Size = Vector2.new(w + 2, h + 2)
					esp.boxOutline.Position = Vector2.new(pos.X - w/2 - 1, topPos.Y - 1)
					esp.boxOutline.Visible = true

					esp.nameTag.Text = player.Name .. " [" .. role .. "]"
					esp.nameTag.Position = Vector2.new(pos.X, topPos.Y - 18)
					esp.nameTag.Color = col
					esp.nameTag.Visible = true

					esp.distanceText.Text = "[" .. math.floor(dist) .. "m]"
					esp.distanceText.Position = Vector2.new(pos.X, botPos.Y + 2)
					esp.distanceText.Visible = true
				end
			end
		end
	end

	if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		local target = getClosestPart()
		if target then
			smoothLookAt(target)
		end
	end
end)

--------------------------------------------------------------------------------
-- Diversos Tab
--------------------------------------------------------------------------------
createSection(MiscTab, "Extras", "Ferramentas adicionais e efeitos visuais.", 1)
local MiscRow1 = createControlRow(MiscTab, 2)
local antiAfkEnabled = false
local antiAfkConnection = nil
createToggleButton(MiscRow1, "Anti-AFK", function(state)
	antiAfkEnabled = state
	if antiAfkConnection then antiAfkConnection:Disconnect() antiAfkConnection = nil end
	if antiAfkEnabled then
		antiAfkConnection = LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	end
end, 1)

local infinityButton = createActionButton(MiscRow1, "Infinite Yield", 2)
infinityButton.MouseButton1Click:Connect(function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
	end)
end)

local MiscRow2 = createControlRow(MiscTab, 3)
local emoteButton = createActionButton(MiscRow2, "Free emotes", 1)
emoteButton.MouseButton1Click:Connect(function()
	pcall(function()
		loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-7yd7-I-Emote-Script-48024"))()
	end)
end)

local rejoinButton = createActionButton(MiscRow2, "Rejoin", 2)
rejoinButton.MouseButton1Click:Connect(function()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
end)

local savedSpawnCFrame = nil
createSection(MiscTab, "Spawn", "Defina um ponto para retornar automaticamente depois do reset.", 4)
local SpawnRow = createControlRow(MiscTab, 5)
local setSpawnButton = createActionButton(SpawnRow, "Definir Spawn", 1)
setSpawnButton.MouseButton1Click:Connect(function()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		savedSpawnCFrame = root.CFrame
		setSpawnButton.Text = "Spawn definido"
		task.delay(1.2, function()
			if setSpawnButton and setSpawnButton.Parent then
				setSpawnButton.Text = "Definir Spawn"
			end
		end)
	end
end)

local removeSpawnButton = createActionButton(SpawnRow, "Remover Spawn", 2, true)
removeSpawnButton.MouseButton1Click:Connect(function()
	savedSpawnCFrame = nil
	removeSpawnButton.Text = "Spawn removido"
	task.delay(1.2, function()
		if removeSpawnButton and removeSpawnButton.Parent then
			removeSpawnButton.Text = "Remover Spawn"
		end
	end)
end)

-- Shaders
local shadersObj = {}
local shaderLightingBackup = nil

local function destroyShaderObjects()
	for _, obj in ipairs(shadersObj) do pcall(function() obj:Destroy() end) end
	shadersObj = {}
end

local function backupLighting()
	if shaderLightingBackup then return end
	shaderLightingBackup = {
		Brightness = Lighting.Brightness,
		ExposureCompensation = Lighting.ExposureCompensation,
		GlobalShadows = Lighting.GlobalShadows,
		ShadowSoftness = Lighting.ShadowSoftness,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient
	}
end

local function restoreLighting()
	if not shaderLightingBackup then return end
	for property, value in pairs(shaderLightingBackup) do
		pcall(function() Lighting[property] = value end)
	end
	shaderLightingBackup = nil
end

local function addEffect(className, name, properties)
	local obj = Instance.new(className)
	obj.Name = name
	for property, value in pairs(properties or {}) do
		pcall(function() obj[property] = value end)
	end
	obj.Parent = Lighting
	table.insert(shadersObj, obj)
	return obj
end

local function applyShaderPreset(presetName)
	backupLighting()
	destroyShaderObjects()
	if presetName == "OLED" then
		pcall(function()
			Lighting.Brightness = 2
			Lighting.ExposureCompensation = -0.05
			Lighting.GlobalShadows = true
			Lighting.ShadowSoftness = 0.35
		end)
		addEffect("ColorCorrectionEffect", "Chosen_OLED_Color", {Brightness = -0.02, Contrast = 0.30, Saturation = 0.12, TintColor = Color3.fromRGB(255, 248, 242)})
		addEffect("BloomEffect", "Chosen_Soft_HDR", {Intensity = 0.12, Size = 22, Threshold = 1.20})
	elseif presetName == "Cinematic" then
		pcall(function()
			Lighting.Brightness = 2
			Lighting.ExposureCompensation = -0.10
			Lighting.GlobalShadows = true
			Lighting.ShadowSoftness = 0.20
		end)
		addEffect("ColorCorrectionEffect", "Chosen_Cinematic_Color", {Brightness = -0.03, Contrast = 0.25, Saturation = -0.05, TintColor = Color3.fromRGB(255, 244, 232)})
		addEffect("BloomEffect", "Chosen_Cinematic_Bloom", {Intensity = 0.18, Size = 28, Threshold = 1.05})
	elseif presetName == "Vibrant" then
		pcall(function()
			Lighting.Brightness = 2
			Lighting.ExposureCompensation = 0.05
			Lighting.GlobalShadows = true
		end)
		addEffect("ColorCorrectionEffect", "Chosen_Vibrant_Color", {Brightness = 0.02, Contrast = 0.18, Saturation = 0.30, TintColor = Color3.fromRGB(255, 255, 255)})
		addEffect("BloomEffect", "Chosen_Vibrant_Bloom", {Intensity = 0.22, Size = 20, Threshold = 0.90})
	elseif presetName == "Soft" then
		pcall(function()
			Lighting.ExposureCompensation = 0
			Lighting.GlobalShadows = true
			Lighting.ShadowSoftness = 0.50
		end)
		addEffect("ColorCorrectionEffect", "Chosen_Soft_Color", {Brightness = 0.03, Contrast = 0.08, Saturation = 0.05, TintColor = Color3.fromRGB(255, 250, 246)})
		addEffect("BloomEffect", "Chosen_Soft_Bloom", {Intensity = 0.08, Size = 30, Threshold = 1.40})
	end
end

local function disableShader()
	destroyShaderObjects()
	restoreLighting()
end

createSection(MiscTab, "Shaders", "presets visuais com efeitos de pós-processamento", 6)
local MiscShaderRow1 = createControlRow(MiscTab, 7)
createToggleButton(MiscShaderRow1, "Shader  •  OLED", function(state)
	if state then applyShaderPreset("OLED") else disableShader() end
end, 1)
createActionButton(MiscShaderRow1, "Shader Preset  •  Cinematic", 2).MouseButton1Click:Connect(function()
	applyShaderPreset("Cinematic")
end)

local MiscShaderRow2 = createControlRow(MiscTab, 8)
createActionButton(MiscShaderRow2, "Shader Preset  •  Vibrant", 1).MouseButton1Click:Connect(function()
	applyShaderPreset("Vibrant")
end)
createActionButton(MiscShaderRow2, "Shader Preset  •  Realistic", 2).MouseButton1Click:Connect(function()
	applyShaderPreset("Realistic")
end)

local MiscShaderRow3 = createControlRow(MiscTab, 9)
createActionButton(MiscShaderRow3, "Shader Preset  •  Soft", 1).MouseButton1Click:Connect(function()
	applyShaderPreset("Soft")
end)
createActionButton(MiscShaderRow3, "Desativar shaders", 2, true).MouseButton1Click:Connect(function()
	disableShader()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.B and not UserInputService:GetFocusedTextBox() then
		MainFrame.Visible = not MainFrame.Visible
	end
end)

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
	if savedSpawnCFrame then
		task.spawn(function()
			local root = newCharacter:WaitForChild("HumanoidRootPart", 8)
			if not root or not savedSpawnCFrame then return end
			task.wait(0.15)
			if newCharacter.Parent and savedSpawnCFrame then
				newCharacter:PivotTo(savedSpawnCFrame)
			end
		end)
	end
end)
