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

local COLOR_BG       = Color3.fromRGB(9, 17, 33)
local COLOR_PANEL    = Color3.fromRGB(15, 28, 52)
local COLOR_SIDE     = Color3.fromRGB(11, 22, 42)
local COLOR_CARD     = Color3.fromRGB(21, 42, 74)
local COLOR_CARD2    = Color3.fromRGB(28, 55, 92)
local COLOR_BORDER   = Color3.fromRGB(52, 96, 148)
local COLOR_BORDER2  = Color3.fromRGB(96, 152, 212)
local COLOR_ACCENT   = Color3.fromRGB(66, 152, 255)
local COLOR_ACCENT2  = Color3.fromRGB(34, 108, 218)
local COLOR_TEXT     = Color3.fromRGB(244, 249, 255)
local COLOR_DIM      = Color3.fromRGB(178, 204, 232)
local COLOR_MUTED    = Color3.fromRGB(126, 160, 198)
local COLOR_SUCCESS  = Color3.fromRGB(84, 220, 140)

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

-- ==========================================================
-- FLAGS GLOBAIS
-- Declaradas no topo porque vários módulos (API, tags de cargo
-- e monitor de voz) precisam consultá-las.
-- ==========================================================

-- MODO LEVE (interruptor de emergência): true desliga os
-- módulos que reagem à criação de instâncias (monitor da
-- interface de voz + varredura do Anti-Invisível).
local CHOSEN_LIGHT_MODE = false

-- Fica true enquanto um script grande (Infinite Yield / emotes)
-- está carregando. Enquanto isso o painel inteiro fica quieto:
-- sem HTTP, sem tags e sem varreduras.
local CHOSEN_EXT_BUSY = false
local CHOSEN_EXT_BUSY_TOKEN = 0
local CHOSEN_VB_RESCAN_AT = 0

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 748, 0, 480)
MainFrame.Position = UDim2.new(0.5, -374, 0.5, -240)
MainFrame.BackgroundColor3 = COLOR_BG
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = false
MainFrame.Parent = ScreenGui
corner(MainFrame, 10)
stroke(MainFrame, COLOR_BORDER, 1, 0.25)

local MainFrameGradient = Instance.new("UIGradient")
MainFrameGradient.Rotation = 90
MainFrameGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 178, 200))
})
MainFrameGradient.Parent = MainFrame

-- Botão flutuante "C" (borda esquerda da tela): abre/fecha o painel.
-- Fica no ScreenGui (fora do MainFrame) para continuar visível quando o painel fecha.
local PanelToggle = Instance.new("TextButton")
PanelToggle.Name = "PanelToggle"
PanelToggle.Size = UDim2.new(0, 34, 0, 34)
PanelToggle.AnchorPoint = Vector2.new(0, 0.5)
PanelToggle.Position = UDim2.new(0, 10, 0.5, 0)
PanelToggle.BackgroundColor3 = COLOR_PANEL
PanelToggle.AutoButtonColor = false
PanelToggle.Text = "C"
PanelToggle.TextColor3 = COLOR_TEXT
PanelToggle.Font = Enum.Font.LuckiestGuy
PanelToggle.TextSize = 16
PanelToggle.BorderSizePixel = 0
PanelToggle.Parent = ScreenGui
corner(PanelToggle, 9)
stroke(PanelToggle, COLOR_BORDER, 1, 0.35)

PanelToggle.MouseButton1Click:Connect(function()
	MainFrame.Visible = not MainFrame.Visible
end)
PanelToggle.MouseEnter:Connect(function()
	tween(PanelToggle, {BackgroundColor3 = COLOR_CARD}, 0.15)
end)
PanelToggle.MouseLeave:Connect(function()
	tween(PanelToggle, {BackgroundColor3 = COLOR_PANEL}, 0.15)
end)


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
TopBar.BackgroundTransparency = 0.2
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
corner(TopBar, 10)
stroke(TopBar, COLOR_BORDER, 1, 0.35)
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
Brand.Font = Enum.Font.LuckiestGuy
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
StatusText.Font = Enum.Font.FredokaOne
StatusText.TextSize = 9
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = TopBar

local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -20, 1, -70)
Body.Position = UDim2.new(0, 10, 0, 64)
Body.BackgroundTransparency = 1
Body.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 190, 1, 0)
Sidebar.BackgroundColor3 = COLOR_SIDE
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Body
corner(Sidebar, 10)
stroke(Sidebar, COLOR_BORDER, 1, 0.3)

local SidebarGradient = Instance.new("UIGradient")
SidebarGradient.Rotation = 90
SidebarGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 165, 190))
})
SidebarGradient.Parent = Sidebar

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 1, -44)
TabContainer.Position = UDim2.new(0, 10, 0, 8)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabContainer

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(1, -28, 0, 16)
Version.Position = UDim2.new(0, 14, 1, -20)
Version.BackgroundTransparency = 1
Version.Text = "v2.5  •  B ABRE/FECHA"
Version.TextColor3 = COLOR_MUTED
Version.Font = Enum.Font.FredokaOne
Version.TextSize = 9
Version.TextXAlignment = Enum.TextXAlignment.Left
Version.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -198, 1, 0)
ContentArea.Position = UDim2.new(0, 198, 0, 0)
ContentArea.BackgroundColor3 = COLOR_PANEL
ContentArea.BorderSizePixel = 0
ContentArea.Parent = Body
corner(ContentArea, 10)
stroke(ContentArea, COLOR_BORDER, 1, 0.15)

local ContentTitle = Instance.new("TextLabel")
ContentTitle.Size = UDim2.new(1, -30, 0, 28)
ContentTitle.Position = UDim2.new(0, 16, 0, 12)
ContentTitle.BackgroundTransparency = 1
ContentTitle.Text = "Início"
ContentTitle.TextColor3 = COLOR_TEXT
ContentTitle.Font = Enum.Font.LuckiestGuy
ContentTitle.TextSize = 17
ContentTitle.TextXAlignment = Enum.TextXAlignment.Left
ContentTitle.Parent = ContentArea

local ContentHolder = Instance.new("Frame")
ContentHolder.Size = UDim2.new(1, -34, 1, -76)
ContentHolder.Position = UDim2.new(0, 16, 0, 70)
ContentHolder.BackgroundTransparency = 1
ContentHolder.ClipsDescendants = true
ContentHolder.Parent = ContentArea

local Tabs = {}
local ContentFrames = {}
local TabIcons = {
	["Início"] = "🏠",
	["Amigos"] = "👥",
	["Target"] = "🎯",
	["Jogo"] = "🎮",
	["Jogador"] = "🏃",
	ESP = "👁",
	["Diversos"] = "🧰",
	["Moderação"] = "🛡"
}

local function createTab(name, order)
	local btn = Instance.new("TextButton")
	btn.Name = name .. "TabButton"
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.BackgroundColor3 = COLOR_SIDE
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.LayoutOrder = order
	btn.Parent = TabContainer
	corner(btn, 8)
	stroke(btn, COLOR_BORDER, 1, 0.35)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 30, 0, 30)
	icon.Position = UDim2.new(0, 10, 0.5, -15)
	icon.BackgroundTransparency = 1
	icon.Text = TabIcons[name] or "◆"
	icon.TextColor3 = COLOR_MUTED
	icon.Font = Enum.Font.FredokaOne
	icon.TextSize = 17
	icon.TextXAlignment = Enum.TextXAlignment.Center
	icon.TextYAlignment = Enum.TextYAlignment.Center
	icon.Parent = btn

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -56, 1, 0)
	label.Position = UDim2.new(0, 48, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = COLOR_DIM
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = btn

	local activeBar = Instance.new("Frame")
	activeBar.Size = UDim2.new(0, 3, 0, 18)
	activeBar.AnchorPoint = Vector2.new(0, 0.5)
	activeBar.Position = UDim2.new(0, 0, 0.5, 0)
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
			tween(data.button, {BackgroundColor3 = active and COLOR_ACCENT2 or COLOR_SIDE, BackgroundTransparency = active and 0.25 or 0}, 0.22)
			tween(data.icon, {TextColor3 = active and COLOR_TEXT or COLOR_MUTED}, 0.22)
			tween(data.label, {TextColor3 = active and COLOR_TEXT or COLOR_DIM}, 0.22)
			data.activeBar.Visible = active
			ContentFrames[tabName].Visible = active
		end
		ContentTitle.Text = name
	end)
	return content
end

local function createSection(parent, title, subtitle, order)
	local section = Instance.new("Frame")
	section.Size = UDim2.new(1, -4, 0, 26)
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
	t.Font = Enum.Font.LuckiestGuy
	t.TextSize = 13
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = section

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
	row.Size = UDim2.new(1, -4, 0, 66)
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

	-- Separação visual: título em destaque e instrução/atalho em linha inferior.
	-- O texto original continua intacto para preservar nomes e atalhos existentes.
	local displayTitle = labelText
	local instruction = "Clique para ativar ou desativar."
	local splitTitle, splitInstruction = labelText:match("^(.-)%s+•%s+(.+)$")
	if not splitTitle then
		splitTitle, splitInstruction = labelText:match("^(.-)%s*|%s*(.+)$")
	end
	if splitTitle and splitInstruction then
		displayTitle = splitTitle
		instruction = "Atalho: " .. splitInstruction
	end

	local card = Instance.new("Frame")
	card.Size = inRow and UDim2.new(0.5, -8, 1, 0) or UDim2.new(1, -4, 0, 64)
	card.BackgroundColor3 = COLOR_CARD
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.LayoutOrder = order or 1
	card.Parent = parent
	corner(card, 8)
	stroke(card, COLOR_BORDER, 1, 0.25)

	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, 0, 1, 0)
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.AutoButtonColor = false
	hit.Text = ""
	hit.Parent = card

	local statusDot = Instance.new("Frame")
	statusDot.Size = UDim2.new(0, 8, 0, 8)
	statusDot.Position = UDim2.new(0, 12, 0, 14)
	statusDot.BackgroundColor3 = COLOR_MUTED
	statusDot.BorderSizePixel = 0
	statusDot.Parent = card
	corner(statusDot, 4)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -104, 0, 22)
	title.Position = UDim2.new(0, 25, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = displayTitle
	title.TextColor3 = COLOR_TEXT
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = card

	local description = Instance.new("TextLabel")
	description.Size = UDim2.new(1, -104, 0, 17)
	description.Position = UDim2.new(0, 25, 0, 31)
	description.BackgroundTransparency = 1
	description.Text = instruction
	description.TextColor3 = COLOR_MUTED
	description.Font = Enum.Font.FredokaOne
	description.TextSize = 9
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextTruncate = Enum.TextTruncate.AtEnd
	description.Parent = card

	local statePill = Instance.new("Frame")
	statePill.Size = UDim2.new(0, 54, 0, 28)
	statePill.Position = UDim2.new(1, -66, 0.5, -14)
	statePill.BackgroundColor3 = COLOR_SIDE
	statePill.BorderSizePixel = 0
	statePill.Parent = card
	corner(statePill, 9)
	stroke(statePill, COLOR_BORDER, 1, 0.2)

	local stateText = Instance.new("TextLabel")
	stateText.Size = UDim2.new(1, 0, 1, 0)
	stateText.BackgroundTransparency = 1
	stateText.Text = "OFF"
	stateText.TextColor3 = COLOR_DIM
	stateText.Font = Enum.Font.FredokaOne
	stateText.TextSize = 10
	stateText.Parent = statePill

	local function setState(newState)
		state = newState
		tween(statusDot, {BackgroundColor3 = state and COLOR_SUCCESS or COLOR_MUTED}, 0.14)
		stateText.Text = state and "ON" or "OFF"
		stateText.TextColor3 = state and COLOR_SUCCESS or COLOR_DIM
		local pillStroke = statePill:FindFirstChildOfClass("UIStroke")
		if pillStroke then tween(pillStroke, {Color = state and COLOR_SUCCESS or COLOR_BORDER}, 0.14) end
		local st = card:FindFirstChildOfClass("UIStroke")
		if st then tween(st, {Color = state and COLOR_SUCCESS or COLOR_BORDER}, 0.14) end
		-- Fundo permanece escuro; somente o contorno e os indicadores mudam.
		tween(card, {BackgroundColor3 = COLOR_CARD}, 0.12)
		if callback then callback(state) end
	end

	hit.MouseButton1Click:Connect(function() setState(not state) end)
	hit.MouseEnter:Connect(function()
		if not state then
			local st = card:FindFirstChildOfClass("UIStroke")
			if st then tween(st, {Color = COLOR_BORDER2}, 0.10) end
		end
	end)
	hit.MouseLeave:Connect(function()
		local st = card:FindFirstChildOfClass("UIStroke")
		if st then tween(st, {Color = state and COLOR_SUCCESS or COLOR_BORDER}, 0.10) end
	end)
	return card, setState
end

local function createActionButton(parent, text, order, compact)
	local inRow = isControlRow(parent)
	local btn = Instance.new("TextButton")
	btn.Size = inRow and UDim2.new(0.5, -8, 1, 0) or UDim2.new(1, -4, 0, compact and 40 or 46)
	btn.BackgroundColor3 = COLOR_CARD2
	btn.BackgroundTransparency = 0.15
	btn.AutoButtonColor = false
	btn.Text = text
	btn.TextColor3 = COLOR_TEXT
	btn.Font = Enum.Font.FredokaOne
	btn.TextSize = 11
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextTruncate = Enum.TextTruncate.AtEnd
	btn.LayoutOrder = order or 1
	btn.Parent = parent
	corner(btn, 8)
	stroke(btn, COLOR_BORDER, 1, 0.35)

	padding(btn, 14, 10, 0, 0)

	btn.MouseEnter:Connect(function()
		tween(btn, {BackgroundColor3 = Color3.fromRGB(56, 102, 158), BackgroundTransparency = 0.05}, 0.12)
		local st = btn:FindFirstChildOfClass("UIStroke")
		if st then tween(st, {Color = COLOR_ACCENT}, 0.12) end
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {BackgroundColor3 = COLOR_CARD2, BackgroundTransparency = 0.15}, 0.12)
		local st = btn:FindFirstChildOfClass("UIStroke")
		if st then tween(st, {Color = COLOR_BORDER}, 0.12) end
	end)
	return btn
end

local function createInputWithAvatar(parent, placeholder, order)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -4, 0, 64)
	card.BackgroundColor3 = COLOR_CARD
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel = 0
	card.LayoutOrder = order or 1
	card.Parent = parent
	corner(card, 8)
	stroke(card, COLOR_BORDER, 1, 0.3)

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
	box.Font = Enum.Font.FredokaOne
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
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel = 0
	card.LayoutOrder = order or 1
	card.Parent = parent
	corner(card, 8)
	stroke(card, COLOR_BORDER, 1, 0.3)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -90, 0, 22)
	title.Position = UDim2.new(0, 12, 0, 7)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = COLOR_TEXT
	title.Font = Enum.Font.FredokaOne
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
	valueBox.Font = Enum.Font.FredokaOne
	valueBox.TextSize = 12
	valueBox.ClearTextOnFocus = false
	valueBox.TextXAlignment = Enum.TextXAlignment.Center
	valueBox.Parent = card
	corner(valueBox, 8)
	stroke(valueBox, COLOR_BORDER, 1, 0.3)

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

-- Controle combinado (meio a meio): botão ON/OFF à esquerda + slider à direita.
-- Usado na aba Jogador (Fly, Walk Speed, Jump Power) para ocupar menos espaço.
local function createComboControl(parent, labelText, minValue, maxValue, defaultValue, order, onToggled, onChanged)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -4, 0, 44)
	card.BackgroundColor3 = COLOR_CARD
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel = 0
	card.LayoutOrder = order or 1
	card.Parent = parent
	corner(card, 8)
	stroke(card, COLOR_BORDER, 1, 0.3)

	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(0.5, -4, 1, 0)
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.AutoButtonColor = false
	hit.Text = ""
	hit.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.5, -60, 1, 0)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = labelText
	title.TextColor3 = COLOR_TEXT
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = card

	local switchTrack = Instance.new("Frame")
	switchTrack.Size = UDim2.new(0, 36, 0, 18)
	switchTrack.Position = UDim2.new(0.5, -44, 0.5, -9)
	switchTrack.BackgroundColor3 = COLOR_SIDE
	switchTrack.BorderSizePixel = 0
	switchTrack.Parent = card
	corner(switchTrack, 9)
	stroke(switchTrack, COLOR_BORDER, 1, 0.3)

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 12, 0, 12)
	dot.Position = UDim2.new(0, 3, 0.5, -6)
	dot.BackgroundColor3 = COLOR_MUTED
	dot.BorderSizePixel = 0
	dot.Parent = switchTrack
	corner(dot, 6)

	local state = false
	local function setState(newState)
		state = newState
		tween(dot, {
			Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
			BackgroundColor3 = state and COLOR_SUCCESS or COLOR_MUTED
		}, 0.14)
		tween(card, {BackgroundColor3 = state and Color3.fromRGB(26, 86, 60) or COLOR_CARD}, 0.12)
		local st = card:FindFirstChildOfClass("UIStroke")
		if st then tween(st, {Color = state and COLOR_SUCCESS or COLOR_BORDER}, 0.12) end
		if onToggled then onToggled(state) end
	end

	hit.MouseButton1Click:Connect(function() setState(not state) end)

	local track = Instance.new("Frame")
	track.Size = UDim2.new(0.5, -54, 0, 7)
	track.Position = UDim2.new(0.5, 4, 0.5, -3)
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
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.BackgroundColor3 = COLOR_TEXT
	knob.BorderSizePixel = 0
	knob.Active = true
	knob.Parent = track
	corner(knob, 7)
	stroke(knob, COLOR_ACCENT, 1, 0)

	local valueBox = Instance.new("TextBox")
	valueBox.Size = UDim2.new(0, 44, 0, 25)
	valueBox.Position = UDim2.new(1, -50, 0.5, -12)
	valueBox.BackgroundColor3 = COLOR_PANEL
	valueBox.BorderSizePixel = 0
	valueBox.TextColor3 = COLOR_TEXT
	valueBox.PlaceholderColor3 = COLOR_MUTED
	valueBox.Text = tostring(math.clamp(tonumber(defaultValue) or minValue, minValue, maxValue))
	valueBox.Font = Enum.Font.FredokaOne
	valueBox.TextSize = 11
	valueBox.ClearTextOnFocus = false
	valueBox.TextXAlignment = Enum.TextXAlignment.Center
	valueBox.Parent = card
	corner(valueBox, 8)
	stroke(valueBox, COLOR_BORDER, 1, 0.3)

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
	hit.MouseEnter:Connect(function()
		if not state then
			tween(card, {BackgroundColor3 = COLOR_CARD2}, 0.10)
			local st = card:FindFirstChildOfClass("UIStroke")
			if st then tween(st, {Color = COLOR_BORDER2}, 0.10) end
		end
	end)
	hit.MouseLeave:Connect(function()
		if not state then
			tween(card, {BackgroundColor3 = COLOR_CARD}, 0.10)
			local st = card:FindFirstChildOfClass("UIStroke")
			if st then tween(st, {Color = COLOR_BORDER}, 0.10) end
		end
	end)
	setValue(currentValue)
	return {
		card = card,
		setState = setState,
		setValue = setValue,
		getState = function()
			return state
		end,
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
local PlayerTab = createTab("Jogador", 5)
local ESPTab = createTab("ESP", 6)
local MiscTab = createTab("Diversos", 7)

Tabs["Início"].button.BackgroundColor3 = COLOR_ACCENT2
Tabs["Início"].button.BackgroundTransparency = 0.25
Tabs["Início"].icon.TextColor3 = COLOR_TEXT
Tabs["Início"].label.TextColor3 = COLOR_TEXT
Tabs["Início"].activeBar.Visible = true
ContentFrames["Início"].Visible = true

createSection(HomeTab, "CHOSEN PANEL", "Visão geral da sua sessão e acesso rápido.", 1)

local WelcomeCard = Instance.new("Frame")
WelcomeCard.Size = UDim2.new(1, -4, 0, 140)
WelcomeCard.BackgroundColor3 = COLOR_CARD
WelcomeCard.BackgroundTransparency = 0.08
WelcomeCard.BorderSizePixel = 0
WelcomeCard.LayoutOrder = 2
WelcomeCard.Parent = HomeTab
corner(WelcomeCard, 10)
stroke(WelcomeCard, COLOR_BORDER, 1, 0.2)

local WelcomeGradient = Instance.new("UIGradient")
WelcomeGradient.Rotation = 90
WelcomeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 200, 220))
})
WelcomeGradient.Parent = WelcomeCard

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(0, 84, 0, 84)
AvatarImage.Position = UDim2.new(0, 20, 0.5, -42)
AvatarImage.BackgroundColor3 = COLOR_SIDE
pcall(function()
	AvatarImage.Image = Players:GetUserThumbnailAsync(
		LocalPlayer.UserId,
		Enum.ThumbnailType.AvatarBust,
		Enum.ThumbnailSize.Size420x420
	)
end)
AvatarImage.Parent = WelcomeCard
corner(AvatarImage, 42)
stroke(AvatarImage, COLOR_ACCENT, 2, 0.1)

local AvatarBadge = Instance.new("Frame")
AvatarBadge.Size = UDim2.new(0, 16, 0, 16)
AvatarBadge.Position = UDim2.new(1, -7, 1, -7)
AvatarBadge.BackgroundColor3 = COLOR_SUCCESS
AvatarBadge.BorderSizePixel = 0
AvatarBadge.Parent = AvatarImage
corner(AvatarBadge, 8)
stroke(AvatarBadge, COLOR_CARD, 2, 0.2)

local HeroAccent = Instance.new("Frame")
HeroAccent.Size = UDim2.new(0, 3, 1, -32)
HeroAccent.Position = UDim2.new(0, 8, 0, 16)
HeroAccent.BackgroundColor3 = COLOR_ACCENT
HeroAccent.BorderSizePixel = 0
HeroAccent.Parent = WelcomeCard
corner(HeroAccent, 2)

local WelcomeTitle = Instance.new("TextLabel")
WelcomeTitle.Size = UDim2.new(1, -140, 0, 30)
WelcomeTitle.Position = UDim2.new(0, 118, 0, 30)
WelcomeTitle.BackgroundTransparency = 1
WelcomeTitle.Text = "OLÁ, " .. string.upper(LocalPlayer.DisplayName)
WelcomeTitle.TextColor3 = COLOR_TEXT
WelcomeTitle.Font = Enum.Font.LuckiestGuy
WelcomeTitle.TextSize = 23
WelcomeTitle.TextXAlignment = Enum.TextXAlignment.Left
WelcomeTitle.TextTruncate = Enum.TextTruncate.AtEnd
WelcomeTitle.Parent = WelcomeCard

local UserSub = Instance.new("TextLabel")
UserSub.Size = UDim2.new(1, -140, 0, 20)
UserSub.Position = UDim2.new(0, 118, 0, 63)
UserSub.BackgroundTransparency = 1
UserSub.Text = "@" .. LocalPlayer.Name
UserSub.TextColor3 = COLOR_ACCENT
UserSub.Font = Enum.Font.FredokaOne
UserSub.TextSize = 13
UserSub.TextXAlignment = Enum.TextXAlignment.Left
UserSub.TextTruncate = Enum.TextTruncate.AtEnd
UserSub.Parent = WelcomeCard

local UserStatus = Instance.new("TextLabel")
UserStatus.Size = UDim2.new(1, -260, 0, 18)
UserStatus.Position = UDim2.new(0, 118, 0, 101)
UserStatus.BackgroundColor3 = COLOR_SUCCESS
UserStatus.BackgroundTransparency = 0.78
UserStatus.Text = "USUÁRIO LOCAL  -  SESSÃO ATIVA"
UserStatus.TextColor3 = COLOR_DIM
UserStatus.Font = Enum.Font.FredokaOne
UserStatus.TextSize = 9
UserStatus.TextXAlignment = Enum.TextXAlignment.Left
UserStatus.TextTruncate = Enum.TextTruncate.AtEnd
UserStatus.Parent = WelcomeCard
corner(UserStatus, 9)
padding(UserStatus, 9, 6, 0, 0)

local ChosenPermissionLabel = Instance.new("TextLabel")
ChosenPermissionLabel.Name = "ChosenPermissions"
ChosenPermissionLabel.Size = UDim2.new(1, -140, 0, 13)
ChosenPermissionLabel.Position = UDim2.new(0, 118, 0, 122)
ChosenPermissionLabel.BackgroundTransparency = 1
ChosenPermissionLabel.Text = "PREMIUM: carregando..."
ChosenPermissionLabel.TextColor3 = COLOR_MUTED
ChosenPermissionLabel.Font = Enum.Font.FredokaOne
ChosenPermissionLabel.TextSize = 8
ChosenPermissionLabel.TextXAlignment = Enum.TextXAlignment.Left
ChosenPermissionLabel.TextTruncate = Enum.TextTruncate.AtEnd
ChosenPermissionLabel.Parent = WelcomeCard

-- TIPOGRAFIA VISUAL: LuckiestGuy para titulos; FredokaOne para textos menores. Cargos continuam em Creepster.
-- CHOSEN HUB API isolada em um bloco local para evitar conflito de sintaxe e escopo.
-- Ponte para o botão 👁 (fora do bloco): alterna a visibilidade
-- das tags na tela local e devolve o novo estado (true = oculto).
local chosenToggleTagsVisibility = nil
-- Ponte para a lista de servidores (fora do bloco): devolve os
-- usuários online com painel (com servidor atual de cada um),
-- ou nil em caso de falha.
local chosenGetOnlineSessions = nil
-- Ponte para o toast de aviso (fora do bloco): a injeção externa
-- avisa quando o Infinite Yield / emotes terminam de carregar.
local chosenToastBridge = nil
do
-- CHOSEN HUB API: perfil, cargo e presença
-- Substitua apenas o domínio abaixo pelo domínio do seu projeto Supabase.
local CHOSEN_API_URL = "https://mxbwgjqoupnkgdbbigvr.supabase.co/functions/v1/chosen-api" -- Troque SEU-PROJETO pelo ID do seu projeto Supabase.
local CHOSEN_API_VERSION = "1.3.0"

local ChosenRoleLabel = Instance.new("TextLabel")
ChosenRoleLabel.Name = "ChosenRole"
ChosenRoleLabel.Size = UDim2.new(1, -140, 0, 18)
ChosenRoleLabel.Position = UDim2.new(0, 118, 0, 83)
ChosenRoleLabel.BackgroundTransparency = 1
ChosenRoleLabel.Text = "CARGO: carregando..."
ChosenRoleLabel.TextColor3 = COLOR_DIM
ChosenRoleLabel.Font = Enum.Font.FredokaOne
ChosenRoleLabel.TextSize = 10
ChosenRoleLabel.TextXAlignment = Enum.TextXAlignment.Left
ChosenRoleLabel.TextTruncate = Enum.TextTruncate.AtEnd
ChosenRoleLabel.Parent = WelcomeCard

local chosenHttpRequest = request
    or (http and http.request)
    or http_request

local chosenSessionId = HttpService:GenerateGUID(false)
local chosenApiReady = false
local chosenProfile = nil

-- A aba Moderação é construída sob demanda: na primeira carga de
-- perfil bem-sucedida em que o jogador possui alguma permissão de
-- moderação. A variável é declarada aqui para chosenUpdateProfile
-- poder chamá-la (o corpo é atribuído mais abaixo).
local chosenBuildModerationTab = nil
local chosenProfilePermissions = nil
local chosenApplyPermissions = nil
local chosenTemporaryRole = nil

-- Cargo temporário por jogador (UserId em texto → cargo) e estado
-- visual das tags. Usados pelo bloco de tags e pela aba Moderação.
-- chosenApplyTempRole(userId, role) aplica/remove o temporário e
-- atualiza a tag na hora (o corpo é atribuído no bloco de tags).
local chosenTempRoles = {}
local chosenTagsHidden = false
local chosenApplyTempRole = nil
local chosenRoleTags = {}

local function chosenApiCall(options)
    if type(chosenHttpRequest) ~= "function" then
        return false, "HTTP não disponível neste executor"
    end

    local ok, response = pcall(function()
        return chosenHttpRequest(options)
    end)

    if not ok then
        if type(response) == "table" then
            local message = response.Message or response.message or response.Error or response.error
            return false, tostring(message or "Falha interna na requisição HTTP")
        end
        return false, tostring(response or "Falha na requisição HTTP")
    end

    if type(response) ~= "table" then
        return false, "Formato de resposta HTTP inesperado: " .. type(response)
    end

    local body = response.Body or response.body or response.ResponseBody
    if type(body) ~= "string" then
        local status = response.StatusCode or response.Status or response.status_code or "desconhecido"
        local message = response.StatusMessage or response.StatusMessage or response.Error or response.error
        return false, "Resposta HTTP sem Body (status " .. tostring(status) .. "): " .. tostring(message or "sem detalhe")
    end

    local decodedOk, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not decodedOk or type(decoded) ~= "table" then
        return false, "Resposta da API inválida"
    end

    local statusCode = tonumber(response.StatusCode or response.Status or 200)
    if statusCode and statusCode >= 400 then
        return false, decoded.error or ("HTTP " .. tostring(statusCode))
    end

    return true, decoded
end

local function chosenUpdateProfile()
    local url = CHOSEN_API_URL
        .. "/profile?user_id="
        .. HttpService:UrlEncode(tostring(LocalPlayer.UserId))

    local ok, data = chosenApiCall({
        Url = url,
        Method = "GET",
        Headers = {
            ["Accept"] = "application/json"
        }
    })

    if not ok then
        ChosenRoleLabel.Text = "CARGO: indisponível"
        UserStatus.Text = "API OFFLINE  -  " .. tostring(data)
        UserStatus.BackgroundColor3 = Color3.fromRGB(170, 90, 55)
        return false
    end

    if not data.success or type(data.profile) ~= "table" then
        ChosenRoleLabel.Text = "CARGO: não encontrado"
        ChosenPermissionLabel.Text = "PREMIUM: indisponível"
        UserStatus.Text = "PERFIL NÃO LOCALIZADO"
        UserStatus.BackgroundColor3 = Color3.fromRGB(170, 90, 55)
        return false
    end

    if type(data.permissions) ~= "table" then
        ChosenRoleLabel.Text = "CARGO: permissões indisponíveis"
        ChosenPermissionLabel.Text = "PREMIUM: API não retornou os dados"
        UserStatus.Text = "PERFIL ENCONTRADO • PERMISSÕES OFFLINE"
        UserStatus.BackgroundColor3 = Color3.fromRGB(170, 90, 55)
        return false
    end

    chosenProfile = data.profile
    chosenProfilePermissions = data.permissions
    local role = tostring(data.profile.role or "Member")
    local banned = data.profile.is_banned == true
    local permissions = type(data.permissions) == "table" and data.permissions or {}

    -- Aplica cargo + permissões (atributos e rótulos da Home).
    -- Enquanto um cargo temporário estiver ativo para VOCÊ, mantém
    -- as permissões dele na sessão; o cargo real volta ao restaurar.
    local selfTempRole = chosenTempRoles[tostring(LocalPlayer.UserId)]
    if type(selfTempRole) == "string"
        and type(chosenApplyPermissions) == "function" then
        pcall(chosenApplyPermissions, selfTempRole, nil, true)
    elseif type(chosenApplyPermissions) == "function" then
        pcall(chosenApplyPermissions, role, permissions, false)
    end

    if type(chosenBuildModerationTab) == "function" then
        pcall(chosenBuildModerationTab)
    end

    if banned then
        UserStatus.Text = "CONTA MARCADA COMO BANIDA"
        UserStatus.BackgroundColor3 = Color3.fromRGB(190, 55, 65)
    else
        UserStatus.Text = "API ONLINE  -  ACESSO LIVRE"
        UserStatus.BackgroundColor3 = COLOR_SUCCESS
    end

    chosenApiReady = true
    return true
end

local function chosenHeartbeat()
    local ok, data = chosenApiCall({
        Url = CHOSEN_API_URL .. "/heartbeat",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            session_id = chosenSessionId,
            roblox_user_id = tostring(LocalPlayer.UserId),
            username = LocalPlayer.Name,
            version = CHOSEN_API_VERSION,
            -- Servidor atual: usado pela lista de servidores para
            -- mostrar amigos que estão no mesmo servidor.
            place_id = game.PlaceId,
            job_id = game.JobId
        })
    })

    if not ok then
        warn("[CHOSEN API] Heartbeat falhou: " .. tostring(data))
        return false
    end

    return data.success == true
end

-- Referências antecipadas: o loop abaixo busca o anúncio para
-- todos os usuários e refresca as estatísticas da aba Moderação
-- (os corpos são atribuídos adiante, nos blocos respectivos).
local chosenFetchAnnouncement = nil
local chosenRefreshModStats = nil

-- ==========================================================
-- MENSAGEM INSTANTÂNEA (LIVE)
-- Diferente do anúncio (que fica salvo e aparece no cartão da
-- aba Início), a mensagem instantânea é um aviso do momento:
-- desliza no canto da tela, fica 10 segundos e some. Nova
-- mensagem substitui o toast anterior.
-- ==========================================================

local chosenLastLiveKey = nil

local function chosenShowLiveToast(message, author)
    local old = ScreenGui:FindFirstChild("ChosenLiveMessageToast")
    if old then
        old:Destroy()
    end

    -- Altura dinâmica: mensagens longas pedem um toast maior
    -- (cada linha comporta ~34 caracteres no TextSize 12)
    local estLines = math.max(1, math.ceil(#message / 34))
    local textH = math.min(estLines * 16 + 4, 380)
    local toastH = 66 + textH + 8

    local toast = Instance.new("Frame")
    toast.Name = "ChosenLiveMessageToast"
    toast.AnchorPoint = Vector2.new(1, 0)
    toast.Position = UDim2.new(1, 340, 0, 18) -- fora da tela; entra deslizando
    toast.Size = UDim2.new(0, 316, 0, toastH)
    toast.BackgroundColor3 = COLOR_PANEL
    toast.BackgroundTransparency = 0.03
    toast.BorderSizePixel = 0
    toast.ZIndex = 60
    toast.Parent = ScreenGui
    corner(toast, 10)
    stroke(toast, COLOR_SUCCESS, 1.2, 0.35)

    -- Barra lateral de destaque (verde)
    local toastBar = Instance.new("Frame")
    toastBar.Size = UDim2.new(0, 4, 1, 0)
    toastBar.BackgroundColor3 = COLOR_SUCCESS
    toastBar.BorderSizePixel = 0
    toastBar.ZIndex = 61
    toastBar.Parent = toast
    corner(toastBar, 2)

    local toastTitle = Instance.new("TextLabel")
    toastTitle.Size = UDim2.new(1, -64, 0, 16)
    toastTitle.Position = UDim2.new(0, 18, 0, 10)
    toastTitle.BackgroundTransparency = 1
    toastTitle.Text = "💬  AVISO"
    toastTitle.TextColor3 = COLOR_SUCCESS
    toastTitle.Font = Enum.Font.LuckiestGuy
    toastTitle.TextSize = 11
    toastTitle.TextXAlignment = Enum.TextXAlignment.Left
    toastTitle.ZIndex = 60
    toastTitle.Parent = toast

    local toastAuthor = Instance.new("TextLabel")
    toastAuthor.Size = UDim2.new(1, -64, 0, 13)
    toastAuthor.Position = UDim2.new(0, 18, 0, 27)
    toastAuthor.BackgroundTransparency = 1
    toastAuthor.Text = (type(author) == "string" and author ~= "")
        and ("por " .. author) or ""
    toastAuthor.TextColor3 = COLOR_MUTED
    toastAuthor.Font = Enum.Font.FredokaOne
    toastAuthor.TextSize = 9
    toastAuthor.TextXAlignment = Enum.TextXAlignment.Left
    toastAuthor.TextTruncate = Enum.TextTruncate.AtEnd
    toastAuthor.ZIndex = 60
    toastAuthor.Parent = toast

    local toastText = Instance.new("TextLabel")
    toastText.Size = UDim2.new(1, -36, 0, textH)
    toastText.Position = UDim2.new(0, 18, 0, 46)
    toastText.BackgroundTransparency = 1
    toastText.Text = message
    toastText.TextColor3 = COLOR_TEXT
    toastText.Font = Enum.Font.FredokaOne
    toastText.TextSize = 12
    toastText.TextXAlignment = Enum.TextXAlignment.Left
    toastText.TextYAlignment = Enum.TextYAlignment.Top
    toastText.TextWrapped = true
    toastText.TextTruncate = Enum.TextTruncate.AtEnd
    toastText.ZIndex = 60
    toastText.Parent = toast

    local toastClose = Instance.new("TextButton")
    toastClose.Size = UDim2.new(0, 24, 0, 24)
    toastClose.Position = UDim2.new(1, -32, 0, 9)
    toastClose.BackgroundColor3 = COLOR_CARD2
    toastClose.BackgroundTransparency = 0.2
    toastClose.Text = "X"
    toastClose.TextColor3 = COLOR_TEXT
    toastClose.Font = Enum.Font.FredokaOne
    toastClose.TextSize = 12
    toastClose.ZIndex = 61
    toastClose.Parent = toast
    corner(toastClose, 8)

    -- Barra de contagem: o tempo restante (10s) esvazia da direita
    local toastTimer = Instance.new("Frame")
    toastTimer.Name = "ToastTimer"
    toastTimer.AnchorPoint = Vector2.new(1, 0.5)
    toastTimer.Position = UDim2.new(1, -8, 1, -7)
    toastTimer.Size = UDim2.new(1, -16, 0, 3)
    toastTimer.BackgroundColor3 = COLOR_SUCCESS
    toastTimer.BackgroundTransparency = 0.3
    toastTimer.BorderSizePixel = 0
    toastTimer.ZIndex = 61
    toastTimer.Parent = toast
    corner(toastTimer, 2)

    tween(toast, {Position = UDim2.new(1, -16, 0, 18)}, 0.35)
    tween(toastTimer, {Size = UDim2.new(0, 0, 0, 3)}, 10)

    local function dismiss()
        if not toast.Parent then return end
        tween(toast, {Position = UDim2.new(1, 340, 0, 18)}, 0.35)
        task.delay(0.4, function()
            pcall(function() toast:Destroy() end)
        end)
    end

    toastClose.MouseButton1Click:Connect(dismiss)

    task.delay(10, dismiss)
end

-- Ponte para fora do bloco: o retorno da injeção externa (aba
-- Diversos) usa este aviso para confirmar que o script carregou.
chosenToastBridge = chosenShowLiveToast

-- Consulta a mensagem instantânea a cada 8s (é um aviso do
-- momento, então a checagem é mais frequente que a do anúncio).
task.spawn(function()
    while ScreenGui.Parent do
        local ok, data = false, nil
        if not CHOSEN_EXT_BUSY then
            ok, data = chosenApiCall({
                Url = CHOSEN_API_URL .. "/live-message",
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json"
                }
            })
        end

        if ok and type(data.message) == "table" then
            local m = data.message
            local createdAt = tostring(m.created_at or "")

            if m.kind == "kick" then
                -- Kick via painel: só o alvo executa (expulsa a si
                -- mesmo). Ninguém vê toast; não mistura com a dedup
                -- das mensagens normais.
                if tostring(m.target_id or "") == tostring(LocalPlayer.UserId) then
                    local kickKey = "kick|" .. createdAt
                    if kickKey ~= chosenLastLiveKey then
                        chosenLastLiveKey = kickKey
                        local kickReason = tostring(m.text or m.reason or "")
                        local kicker = tostring(m.author_username or "moderação")
                        pcall(function()
                            LocalPlayer:Kick(
                                "Chosen Hub — você foi expulso por " .. kicker
                                .. (#kickReason > 0
                                    and (".\nMotivo: " .. kickReason)
                                    or ".")
                            )
                        end)
                    end
                end
            else
                local text = m.text or m.message
                if type(text) == "string" and text ~= "" then
                    local key = createdAt .. "|" .. text
                    if key ~= chosenLastLiveKey then
                        chosenLastLiveKey = key
                        chosenShowLiveToast(
                            text,
                            m.author_username
                        )
                    end
                end
            end
        end

        task.wait(8)
    end
end)

-- ==========================================================
-- ANÚNCIO GLOBAL
-- GET /announcement a cada ciclo: todos os usuários veem o
-- cartão na aba Início. Sem rota na API ou sem anúncio
-- publicado, o cartão permanece oculto.
-- A publicação (POST /announcement) fica na aba Moderação e
-- é permitida para Owner e Moderador (validado no servidor).
-- ==========================================================

local AnnouncementCard = Instance.new("Frame")
AnnouncementCard.Name = "ChosenAnnouncement"
AnnouncementCard.Size = UDim2.new(1, -4, 0, 84)
AnnouncementCard.BackgroundColor3 = COLOR_CARD
AnnouncementCard.BackgroundTransparency = 0.08
AnnouncementCard.BorderSizePixel = 0
AnnouncementCard.LayoutOrder = 9
AnnouncementCard.Visible = false
AnnouncementCard.Parent = HomeTab
corner(AnnouncementCard, 10)
stroke(AnnouncementCard, COLOR_BORDER, 1, 0.2)

local AnnBannerTitle = Instance.new("TextLabel")
AnnBannerTitle.Size = UDim2.new(1, -28, 0, 18)
AnnBannerTitle.Position = UDim2.new(0, 14, 0, 8)
AnnBannerTitle.BackgroundTransparency = 1
AnnBannerTitle.Text = "📣  ANÚNCIO"
AnnBannerTitle.TextColor3 = COLOR_ACCENT
AnnBannerTitle.Font = Enum.Font.LuckiestGuy
AnnBannerTitle.TextSize = 11
AnnBannerTitle.TextXAlignment = Enum.TextXAlignment.Left
AnnBannerTitle.Parent = AnnouncementCard

local AnnBannerAuthor = Instance.new("TextLabel")
AnnBannerAuthor.Size = UDim2.new(1, -28, 0, 14)
AnnBannerAuthor.Position = UDim2.new(0, 14, 0, 27)
AnnBannerAuthor.BackgroundTransparency = 1
AnnBannerAuthor.Text = ""
AnnBannerAuthor.TextColor3 = COLOR_MUTED
AnnBannerAuthor.Font = Enum.Font.FredokaOne
AnnBannerAuthor.TextSize = 9
AnnBannerAuthor.TextXAlignment = Enum.TextXAlignment.Left
AnnBannerAuthor.TextTruncate = Enum.TextTruncate.AtEnd
AnnBannerAuthor.Parent = AnnouncementCard

local AnnBannerText = Instance.new("TextLabel")
AnnBannerText.Size = UDim2.new(1, -28, 0, 38)
AnnBannerText.Position = UDim2.new(0, 14, 0, 43)
AnnBannerText.BackgroundTransparency = 1
AnnBannerText.Text = ""
AnnBannerText.TextColor3 = COLOR_TEXT
AnnBannerText.Font = Enum.Font.FredokaOne
AnnBannerText.TextSize = 12
AnnBannerText.TextXAlignment = Enum.TextXAlignment.Left
AnnBannerText.TextYAlignment = Enum.TextYAlignment.Top
AnnBannerText.TextWrapped = true
AnnBannerText.TextTruncate = Enum.TextTruncate.AtEnd
AnnBannerText.Parent = AnnouncementCard

chosenFetchAnnouncement = function()
    local ok, data = chosenApiCall({
        Url = CHOSEN_API_URL .. "/announcement",
        Method = "GET",
        Headers = {
            ["Accept"] = "application/json"
        }
    })

    -- Rota inexistente ou falha: cartão some silenciosamente.
    if not ok then
        AnnouncementCard.Visible = false
        return
    end

    local ann = (type(data.announcement) == "table" and data.announcement)
        or (type(data.data) == "table" and data.data)
        or data

    local message
    if type(ann) == "table" then
        message = ann.message or ann.text
    elseif type(ann) == "string" then
        message = ann
    end

    if type(message) ~= "string" or message == "" then
        AnnouncementCard.Visible = false
        return
    end

    AnnBannerText.Text = message

    local meta = {}
    local author = type(ann) == "table" and (ann.author_username or ann.author) or nil
    local createdAt = type(ann) == "table" and (ann.created_at or ann.date) or nil

    if type(author) == "string" and author ~= "" then
        table.insert(meta, "por " .. author)
    end
    if type(createdAt) == "string" and createdAt ~= "" then
        table.insert(meta, (createdAt:sub(1, 16):gsub("T", " ")))
    end
    AnnBannerAuthor.Text = table.concat(meta, "   •   ")

    AnnouncementCard.Visible = true
end

-- ==========================================================
-- TAGS DE CARGO (BILLBOARD)
-- Mostra o nome do cargo flutuando acima da cabeça de cada
-- jogador que tenha o script registrado (incluindo o próprio).
-- Consulta o cargo via /profile e REPETE a consulta: quem entra
-- depois (ou se registra depois) ganha a tag assim que o registro
-- existir, e mudanças de cargo aparecem em até ~15s.
-- O cargo temporário da sessão (aplicado na aba Moderação)
-- sobrepõe o cargo real na tag do jogador alvo.
-- Efeitos suaves (senoidais, sem trocas bruscas de cor):
-- Owner (vermelho pulsante), Moderador (azul pulsante),
-- Premium (amarelo pulsante) e Membro (cinza transparente).
-- O botão 👁 da aba Início esconde as tags só na sua tela.
-- ==========================================================

local chosenTagClock = 0
local chosenTagPending = {} -- jogadores consultados sem registro ainda

-- PRESENÇA: a tag só aparece se o DONO dela também estiver com o
-- painel aberto (heartbeat recente — janela de 90s do servidor).
-- O conjunto guarda os user_ids online no momento.
local chosenOnlineNow = {}

-- Sessões online (para a lista de servidores da aba Início):
-- devolve data.users da rota /online (user_id, username, place_id,
-- job_id...) ou nil se falhar. Usa cache de ~20s pra não martelar
-- a API quando a lista é redesenhada.
local chosenSessionsCache = nil
local chosenSessionsCacheAt = 0

chosenGetOnlineSessions = function()
    if chosenSessionsCache
        and (os.clock() - chosenSessionsCacheAt) < 20 then
        return chosenSessionsCache
    end

    local ok, data = chosenApiCall({
        Url = CHOSEN_API_URL .. "/online",
        Method = "GET",
        Headers = {
            ["Accept"] = "application/json"
        }
    })

    if ok and type(data.users) == "table" then
        chosenSessionsCache = data.users
        chosenSessionsCacheAt = os.clock()
        return chosenSessionsCache
    end

    return nil
end

local function chosenRefreshOnlineSet()
    task.spawn(function()
        local ok, data = chosenApiCall({
            Url = CHOSEN_API_URL .. "/online",
            Method = "GET",
            Headers = {
                ["Accept"] = "application/json"
            }
        })

        if ok and type(data.users) == "table" then
            local fresh = {}
            for _, user in ipairs(data.users) do
                if type(user) == "table" and user.user_id then
                    fresh[tostring(user.user_id)] = true
                end
            end
            -- Só substitui em caso de sucesso (falha mantém o estado)
            chosenOnlineNow = fresh
        end
    end)
end

-- Tag visível? Precisa: olho aberto + dono com painel aberto.
-- Você mesmo vê sempre (obviamente está com o painel).
local function chosenTagShouldShow(player)
    if chosenTagsHidden then return false end
    if player == LocalPlayer then return true end
    return chosenOnlineNow[tostring(player.UserId)] == true
end

local CHOSEN_TAG_BASE = {
    Owner = Color3.fromRGB(255, 70, 70),
    Moderator = Color3.fromRGB(80, 150, 255),
    Premium = Color3.fromRGB(255, 210, 60),
    Member = Color3.fromRGB(195, 202, 214)
}

-- Cor do glow (aura) de cada cargo
local CHOSEN_TAG_GLOW = {
    Owner = Color3.fromRGB(255, 115, 115),
    Moderator = Color3.fromRGB(120, 195, 255),
    Premium = Color3.fromRGB(255, 235, 150),
    Member = Color3.fromRGB(185, 195, 215)
}

-- Tamanho do texto por cargo (Membro é menor e mais discreto)
local CHOSEN_TAG_SIZE = {
    Owner = 30,
    Moderator = 30,
    Premium = 30,
    Member = 26
}

local function chosenRoleTagText(role)
    if role == "Owner" then return "OWNER" end
    if role == "Moderator" then return "MODERADOR" end
    if role == "Premium" then return "PREMIUM" end
    if role == "Member" then return "MEMBRO" end
    return string.upper(role)
end

-- Pulso do cargo (igual à versão original)
local function chosenTagPulseColor(role, pulse)
    if role == "Owner" then
        return Color3.fromHSV(0, 0.85, 0.72 + 0.28 * pulse),
            0.25 * (1 - pulse)
    elseif role == "Moderator" then
        return Color3.fromHSV(0.58, 0.85, 0.72 + 0.28 * pulse),
            0.25 * (1 - pulse)
    elseif role == "Premium" then
        return Color3.fromHSV(0.13, 1, 0.78 + 0.22 * pulse),
            0.25 * (1 - pulse)
    end
    return CHOSEN_TAG_BASE.Member, 0.35
end

-- Monta a tag igual à versão ORIGINAL (texto único anexado na
-- cabeça, sombra projetada, degradê de volume e contorno suave) —
-- com fonte nativa Creepster e GLOW por cargo.
local function chosenBuildTagChars(tag)
    local billboard = tag.billboard
    if not billboard then return end

    for _, child in ipairs(billboard:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("Frame") then
            child:Destroy()
        end
    end

    local text = chosenRoleTagText(tag.role)
    local size = CHOSEN_TAG_SIZE[tag.role] or 28
    local glowColor = CHOSEN_TAG_GLOW[tag.role] or CHOSEN_TAG_GLOW.Member

    -- Glow: o mesmo texto desenhado em camadas maiores e bem
    -- transparentes ATRÁS da letra principal — vira uma aura
    -- suave na cor do cargo (respira junto com o pulso).
    local glows = {}
    local glowBase = { 0.78, 0.87, 0.93 }
    local glowSizes = { size + 2, size + 6, size + 12 }
    for gi = 1, 3 do
        local g = Instance.new("TextLabel")
        g.Size = UDim2.new(1, 0, 1, 0)
        g.BackgroundTransparency = 1
        g.Text = text
        g.Font = Enum.Font.Creepster
        g.TextSize = glowSizes[gi]
        g.TextColor3 = glowColor
        g.TextTransparency = glowBase[gi]
        g.TextStrokeTransparency = 1
        g.ZIndex = 1
        g.Parent = billboard
        glows[gi] = g
    end

    -- Sombra projetada atrás do texto (dá profundidade)
    local shadow = Instance.new("TextLabel")
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.Position = UDim2.new(0, 1, 0, 3)
    shadow.BackgroundTransparency = 1
    shadow.Text = text
    shadow.Font = Enum.Font.Creepster
    shadow.TextSize = size
    shadow.TextColor3 = Color3.new(0, 0, 0)
    shadow.TextTransparency = 0.6
    shadow.ZIndex = 1
    shadow.Parent = billboard

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Size = UDim2.new(1, 0, 1, 0)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = text
    roleLabel.Font = Enum.Font.Creepster
    roleLabel.TextSize = size
    roleLabel.TextColor3 = CHOSEN_TAG_BASE[tag.role] or CHOSEN_TAG_BASE.Member
    roleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    roleLabel.TextStrokeTransparency = 0.4
    roleLabel.ZIndex = 2
    roleLabel.Parent = billboard

    -- Sombreado suave no texto (volume, como no original)
    local labelGradient = Instance.new("UIGradient")
    labelGradient.Rotation = 90
    labelGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
    })
    labelGradient.Parent = roleLabel

    tag.glows = glows
    tag.glowBase = glowBase
    tag.fronts = { roleLabel }
end

-- Atualiza o cargo exibido na tag de um jogador.
local function chosenSetTagRole(player, role)
    local tag = chosenRoleTags[player]
    if not tag then return end

    tag.role = role
    chosenBuildTagChars(tag)
end

-- Consulta o cargo real de um jogador na API (assíncrono).
local function chosenQueryTagRole(player, callback)
    task.spawn(function()
        local ok, data = chosenApiCall({
            Url = CHOSEN_API_URL .. "/profile?user_id=" .. tostring(player.UserId),
            Method = "GET",
            Headers = {
                ["Accept"] = "application/json"
            }
        })

        if ok
            and type(data.profile) == "table"
            and data.profile.is_banned ~= true then
            callback(tostring(data.profile.role or "Member"))
        end
    end)
end

-- Cargo temporário da sessão para QUALQUER jogador (incluindo
-- você). role nil restaura o cargo real do jogador.
chosenApplyTempRole = function(userId, role)
    userId = tostring(userId)

    if role ~= nil then
        chosenTempRoles[userId] = role
    else
        chosenTempRoles[userId] = nil
    end

    -- Atualiza a tag do jogador alvo imediatamente, se ela existir.
    for player in pairs(chosenRoleTags) do
        if tostring(player.UserId) == userId then
            if role ~= nil then
                chosenSetTagRole(player, role)
            else
                -- Restaura o cargo real reconsultando a API
                chosenQueryTagRole(player, function(realRole)
                    if chosenTempRoles[userId] == nil then
                        chosenSetTagRole(player, realRole)
                    end
                end)
            end
        end
    end
end

local function chosenEnsureRoleTag(player)
    -- Tag já existe (e não está pendente de nova consulta): nada a fazer.
    if chosenRoleTags[player] and not chosenTagPending[player] then return end
    chosenTagPending[player] = nil

    task.spawn(function()
        -- Proteção: outra consulta pode ter criado a tag em paralelo
        if chosenRoleTags[player] and not chosenTagPending[player] then
            return
        end

        local ok, data = chosenApiCall({
            Url = CHOSEN_API_URL .. "/profile?user_id=" .. tostring(player.UserId),
            Method = "GET",
            Headers = {
                ["Accept"] = "application/json"
            }
        })

        -- Sem registro ou banido: nenhuma tag ainda (reconsulta depois).
        if not ok or type(data.profile) ~= "table" then
            chosenTagPending[player] = true
            return
        end
        if data.profile.is_banned == true then
            return
        end

        -- Cargo temporário da sessão sobrepõe o cargo real.
        local role = chosenTempRoles[tostring(player.UserId)]
            or tostring(data.profile.role or "Member")

        -- Guarda anti-duplicação: outra consulta concorrente pode
        -- ter criado a tag enquanto esta esperava a resposta.
        if chosenRoleTags[player] then return end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ChosenRoleTag"
        billboard.Size = UDim2.new(0, 210, 0, 44)
        billboard.StudsOffset = Vector3.new(0, 2.7, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 140
        -- Visibilidade inicial já respeita presença + olho
        billboard.Enabled = chosenTagShouldShow(player)

        chosenRoleTags[player] = {
            role = role,
            billboard = billboard,
            -- Referência do jogador (a manutenção usa para reanexar)
            player = player,
            -- Fase própria de flutuação (cada tag sobe/desce fora de sync)
            phase = (player.UserId % 314) / 50
        }
        chosenBuildTagChars(chosenRoleTags[player])

        -- Anexa na cabeça atual. O respawn/morph é tratado pelo loop
        -- de manutenção (0.25s), sem criar uma conexão nova por
        -- respawn — isso vazava conexões e pesava com o tempo.
        local char = player.Character or player.CharacterAdded:Wait()
        local head = char:WaitForChild("Head", 8)
        if head then
            billboard.Parent = head
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    chosenEnsureRoleTag(player)
end
Players.PlayerAdded:Connect(chosenEnsureRoleTag)

Players.PlayerRemoving:Connect(function(player)
    local tag = chosenRoleTags[player]
    if tag then
        pcall(function() tag.billboard:Destroy() end)
        chosenRoleTags[player] = nil
    end
    chosenTagPending[player] = nil
end)

-- Loop de efeitos: um único laço atualiza todas as tags com
-- transições senoidais, sem "pulos" de cor. A cada ~15s também
-- reconsulta os cargos (jogadores que se registraram depois
-- ganham a tag; mudanças de cargo aparecem sozinhas).
task.spawn(function()
    local refreshClock = 0
    local maintClock = 0

    -- Primeira carga: descobre quem está online já no arranque
    chosenRefreshOnlineSet()

    while ScreenGui.Parent do
        chosenTagClock = (chosenTagClock + 0.03) % 1000
        refreshClock = refreshClock + 0.05
        maintClock = maintClock + 0.05

        local extQuiet = CHOSEN_EXT_BUSY

        for _, tag in pairs(chosenRoleTags) do
            if not extQuiet then
            pcall(function()
                -- Visibilidade: dono com painel aberto + olho aberto
                tag.billboard.Enabled = chosenTagShouldShow(tag.player)

                local fronts = tag.fronts
                if not fronts or not fronts[1] or not fronts[1].Parent then
                    return
                end

                -- Flutuação suave: sobe e desce alguns centésimos,
                -- com fase própria por jogador (não fica em sync)
                tag.billboard.StudsOffset = Vector3.new(
                    0,
                    2.7 + 0.14 * math.sin(chosenTagClock * 2 + (tag.phase or 0)),
                    0
                )

                -- Respiração fluida: atualiza a cada tick (0.05s),
                -- sem saltos — cor e glow pulsam juntos
                local pulse = 0.5 + 0.5 * math.sin(chosenTagClock * 2.2)
                local color, trans = chosenTagPulseColor(tag.role, pulse)
                for i = 1, #fronts do
                    local lbl = fronts[i]
                    if lbl.Parent then
                        lbl.TextColor3 = color
                        lbl.TextTransparency = trans
                    end
                end
                if tag.glows then
                    for gi = 1, #tag.glows do
                        local g = tag.glows[gi]
                        if g.Parent then
                            g.TextTransparency = math.clamp(
                                tag.glowBase[gi] - 0.1 * pulse, 0, 1)
                        end
                    end
                end
            end)
            end
        end

        -- Manutenção anti-morph (a cada 0.25s): skins/morphs (ex: item
        -- do mushyo) trocam a cabeça ou destróem a tag junto com ela,
        -- sem disparar CharacterAdded. Aqui a tag é reanexada à cabeça
        -- nova — ou recriada do zero se foi destruída — mantendo o
        -- cargo (temporário ou real) que ela já tinha.
        if not extQuiet and maintClock >= 0.25 then
            maintClock = 0

            local toRecreate = {}
            for player, tag in pairs(chosenRoleTags) do
                pcall(function()
                    local char = player.Character
                    if not char or not player.Parent then return end

                    if not tag.billboard or not tag.billboard.Parent then
                        table.insert(toRecreate, player)
                        return
                    end

                    local head = char:FindFirstChild("Head")
                    if head and tag.billboard.Parent ~= head then
                        tag.billboard.Parent = head
                    end
                end)
            end

            for _, player in ipairs(toRecreate) do
                pcall(function()
                    local old = chosenRoleTags[player]
                    if old then
                        pcall(function() old.billboard:Destroy() end)
                        chosenRoleTags[player] = nil
                    end
                    chosenTagPending[player] = true
                    chosenEnsureRoleTag(player)
                end)
            end
        end

        -- Reconsulta periódica: tags que faltam + cargos atualizados
        -- + quem está com o painel aberto (presença).
        if not extQuiet and refreshClock >= 15 then
            refreshClock = 0
            chosenRefreshOnlineSet()

            for _, player in ipairs(Players:GetPlayers()) do
                if not chosenRoleTags[player] then
                    chosenEnsureRoleTag(player)
                elseif chosenTempRoles[tostring(player.UserId)] == nil then
                    chosenQueryTagRole(player, function(newRole)
                        if chosenRoleTags[player]
                            and chosenTempRoles[tostring(player.UserId)] == nil then
                            chosenSetTagRole(player, newRole)
                        end
                    end)
                end
            end
        end

        task.wait(0.05)
    end
end)

-- Ponte do botão 👁 (declarado fora do bloco da API):
-- alterna a visibilidade das tags e devolve o novo estado.
chosenToggleTagsVisibility = function()
    chosenTagsHidden = not chosenTagsHidden

    for player, tag in pairs(chosenRoleTags) do
        pcall(function()
            tag.billboard.Enabled = chosenTagShouldShow(player)
        end)
    end

    return chosenTagsHidden
end

-- ==========================================================
-- ABA MODERAÇÃO
-- Construída sob demanda: só aparece para quem tem alguma
-- permissão de moderação (can_view_online, can_moderate_users,
-- can_manage_roles ou can_manage_announcements). Seções sem
-- permissão ficam com 🔒 + aviso ao interagir.
--
-- As rotas /online, /role, /moderate e /announcement ainda não
-- existem na Edge Function: enquanto isso o status mostra o erro
-- real da API (ex.: "Route not found") e os recursos passam a
-- funcionar automaticamente quando as rotas forem adicionadas
-- ao backend.
-- ==========================================================

local chosenModTab = nil
local chosenModRefs = nil

local function chosenHasPerm(flag)
    return ScreenGui:GetAttribute(flag) == true
end

local function chosenHasAnyModeration()
    return chosenHasPerm("CHOSEN_CanViewOnline")
        or chosenHasPerm("CHOSEN_CanModerateUsers")
        or chosenHasPerm("CHOSEN_CanManageRoles")
        or chosenHasPerm("CHOSEN_CanManageAnnouncements")
end

local CHOSEN_ROLE_COLORS = {
    Owner = Color3.fromRGB(255, 170, 60),
    Moderator = Color3.fromRGB(90, 170, 255),
    Premium = Color3.fromRGB(200, 120, 255),
    Member = Color3.fromRGB(150, 165, 185)
}

local CHOSEN_WARN = Color3.fromRGB(255, 170, 60)

local function chosenLockNotice(statusLabel, permissionText)
    statusLabel.Text = "🔒  Requer " .. permissionText
    statusLabel.TextColor3 = CHOSEN_WARN
end

-- Permissões aproximadas usadas pelo cargo temporário da sessão
-- (o cargo real e as permissões verdadeiras vêm sempre da API).
local CHOSEN_TEMP_PERMISSIONS = {
    Owner = {
        can_use_panel = true,
        can_use_premium = true,
        can_moderate_users = true,
        can_manage_roles = true,
        can_manage_announcements = true,
        can_view_online = true
    },
    Moderator = {
        can_use_panel = true,
        can_use_premium = true,
        can_moderate_users = true,
        can_manage_roles = false,
        can_manage_announcements = true,
        can_view_online = true
    },
    Premium = {
        can_use_panel = true,
        can_use_premium = true,
        can_moderate_users = false,
        can_manage_roles = false,
        can_manage_announcements = false,
        can_view_online = false
    },
    Member = {
        can_use_panel = true,
        can_use_premium = false,
        can_moderate_users = false,
        can_manage_roles = false,
        can_manage_announcements = false,
        can_view_online = false
    }
}

-- Aplica cargo + permissões como atributos do ScreenGui e
-- atualiza os rótulos da Home. Usado pelo perfil real (vindo da
-- API) e pelo cargo temporário da sessão.
chosenApplyPermissions = function(role, permissions, isTemporary)
    permissions = (type(permissions) == "table" and permissions)
        or CHOSEN_TEMP_PERMISSIONS[role]
        or {}

    ScreenGui:SetAttribute("CHOSEN_Role", role)
    ScreenGui:SetAttribute("CHOSEN_CanUsePanel", permissions.can_use_panel == true)
    ScreenGui:SetAttribute("CHOSEN_CanUsePremium", permissions.can_use_premium == true)
    ScreenGui:SetAttribute("CHOSEN_CanModerateUsers", permissions.can_moderate_users == true)
    ScreenGui:SetAttribute("CHOSEN_CanManageRoles", permissions.can_manage_roles == true)
    ScreenGui:SetAttribute("CHOSEN_CanManageAnnouncements", permissions.can_manage_announcements == true)
    ScreenGui:SetAttribute("CHOSEN_CanViewOnline", permissions.can_view_online == true)

    if isTemporary then
        ChosenRoleLabel.Text = "CARGO: " .. string.upper(role) .. "  •  TEMPORÁRIO"
    else
        local whitelisted = chosenProfile ~= nil and chosenProfile.is_whitelisted == true
        ChosenRoleLabel.Text = "CARGO: " .. string.upper(role)
            .. "  •  WHITELIST: " .. (whitelisted and "SIM" or "NÃO")
    end

    ChosenPermissionLabel.Text = "PREMIUM: "
        .. (permissions.can_use_premium == true and "SIM" or "NÃO")
    ChosenPermissionLabel.TextColor3 = permissions.can_use_premium == true
        and COLOR_SUCCESS or COLOR_MUTED
end

chosenBuildModerationTab = function()
    if chosenModTab then return end
    if not chosenHasAnyModeration() then return end

    chosenModTab = createTab("Moderação", 8)

    -- A sidebar já comporta as 8 abas no tamanho padrão:
    -- mantém a mesma altura e o mesmo espaçamento das demais.
    TabLayout.Padding = UDim.new(0, 5)
    for _, data in pairs(Tabs) do
        data.button.Size = UDim2.new(1, 0, 0, 40)
    end

    local refs = {}
    chosenModRefs = refs

    local modOrder = 0
    local function nextOrder()
        modOrder += 1
        return modOrder
    end

    -- Status curto (dentro de uma control row, alinhado à direita).
    local function createModStatus(parentRow)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, -10, 1, 0)
        label.Position = UDim2.new(0.5, 5, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = "—"
        label.TextColor3 = COLOR_DIM
        label.Font = Enum.Font.FredokaOne
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Right
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Parent = parentRow
        return label
    end

    -- Status largo (linha própria na lista, alinhado à esquerda).
    local function createModStatusWide()
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -4, 0, 16)
        label.BackgroundTransparency = 1
        label.Text = "—"
        label.TextColor3 = COLOR_DIM
        label.Font = Enum.Font.FredokaOne
        label.TextSize = 9
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.LayoutOrder = nextOrder()
        label.Parent = chosenModTab
        return label
    end

    -- Compositor compacto: caixa de texto, botão de envio e status
    -- DENTRO do mesmo card — a aba fica coesa, sem blocos soltos
    -- espalhados pela lista.
    local function createModComposer(placeholder, buttonText, order)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 104)
        card.BackgroundColor3 = COLOR_CARD
        card.BackgroundTransparency = 0.1
        card.BorderSizePixel = 0
        card.LayoutOrder = order
        card.Parent = chosenModTab
        corner(card, 8)
        stroke(card, COLOR_BORDER, 1, 0.3)

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -28, 0, 46)
        box.Position = UDim2.new(0, 14, 0, 10)
        box.BackgroundTransparency = 1
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = COLOR_MUTED
        box.Text = ""
        box.TextColor3 = COLOR_TEXT
        box.Font = Enum.Font.FredokaOne
        box.TextSize = 12
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.TextYAlignment = Enum.TextYAlignment.Center
        box.ClearTextOnFocus = false
        box.TextWrapped = true
        box.Parent = card

        local send = createActionButton(card, buttonText, 1)
        send.Size = UDim2.new(0, 158, 0, 34)
        send.Position = UDim2.new(0, 14, 1, -44)
        send.TextSize = 11

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -190, 0, 34)
        status.Position = UDim2.new(0, 182, 1, -44)
        status.BackgroundTransparency = 1
        status.Text = "—"
        status.TextColor3 = COLOR_DIM
        status.Font = Enum.Font.FredokaOne
        status.TextSize = 10
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.TextYAlignment = Enum.TextYAlignment.Center
        status.TextTruncate = Enum.TextTruncate.AtEnd
        status.Parent = card

        return box, send, status
    end

    -- ------------------------------------------------------
    -- ESTATÍSTICAS (GET /stats)
    -- ------------------------------------------------------
    createSection(chosenModTab, "📊 Estatísticas", "Usuários registrados e presença agora.", nextOrder())

    local StatsRow = Instance.new("Frame")
    StatsRow.Size = UDim2.new(1, -4, 0, 86)
    StatsRow.BackgroundColor3 = COLOR_CARD
    StatsRow.BackgroundTransparency = 0.08
    StatsRow.BorderSizePixel = 0
    StatsRow.LayoutOrder = nextOrder()
    StatsRow.Parent = chosenModTab
    corner(StatsRow, 10)
    stroke(StatsRow, COLOR_BORDER, 1, 0.2)

    local RegisteredBox = Instance.new("Frame")
    RegisteredBox.Size = UDim2.new(0.5, -14, 1, -20)
    RegisteredBox.Position = UDim2.new(0, 10, 0, 10)
    RegisteredBox.BackgroundColor3 = COLOR_PANEL
    RegisteredBox.BackgroundTransparency = 0.25
    RegisteredBox.BorderSizePixel = 0
    RegisteredBox.Parent = StatsRow
    corner(RegisteredBox, 8)
    stroke(RegisteredBox, COLOR_BORDER, 1, 0.35)

    local RegisteredCaption = Instance.new("TextLabel")
    RegisteredCaption.Size = UDim2.new(1, -20, 0, 16)
    RegisteredCaption.Position = UDim2.new(0, 10, 0, 10)
    RegisteredCaption.BackgroundTransparency = 1
    RegisteredCaption.Text = "👥 CADASTRO"
    RegisteredCaption.TextColor3 = COLOR_MUTED
    RegisteredCaption.Font = Enum.Font.FredokaOne
    RegisteredCaption.TextSize = 10
    RegisteredCaption.TextXAlignment = Enum.TextXAlignment.Left
    RegisteredCaption.Parent = RegisteredBox

    local RegisteredLabel = Instance.new("TextLabel")
    RegisteredLabel.Size = UDim2.new(1, -20, 0, 28)
    RegisteredLabel.Position = UDim2.new(0, 10, 0, 36)
    RegisteredLabel.BackgroundTransparency = 1
    RegisteredLabel.Text = "👥 Carregando..."
    RegisteredLabel.TextColor3 = COLOR_DIM
    RegisteredLabel.Font = Enum.Font.FredokaOne
    RegisteredLabel.TextSize = 17
    RegisteredLabel.TextXAlignment = Enum.TextXAlignment.Left
    RegisteredLabel.Parent = RegisteredBox

    local OnlineNowBox = Instance.new("Frame")
    OnlineNowBox.Size = UDim2.new(0.5, -14, 1, -20)
    OnlineNowBox.Position = UDim2.new(0.5, 4, 0, 10)
    OnlineNowBox.BackgroundColor3 = COLOR_PANEL
    OnlineNowBox.BackgroundTransparency = 0.25
    OnlineNowBox.BorderSizePixel = 0
    OnlineNowBox.Parent = StatsRow
    corner(OnlineNowBox, 8)
    stroke(OnlineNowBox, COLOR_BORDER, 1, 0.35)

    local OnlineNowCaption = Instance.new("TextLabel")
    OnlineNowCaption.Size = UDim2.new(1, -20, 0, 16)
    OnlineNowCaption.Position = UDim2.new(0, 10, 0, 10)
    OnlineNowCaption.BackgroundTransparency = 1
    OnlineNowCaption.Text = "🟢 PRESENÇA"
    OnlineNowCaption.TextColor3 = COLOR_MUTED
    OnlineNowCaption.Font = Enum.Font.FredokaOne
    OnlineNowCaption.TextSize = 10
    OnlineNowCaption.TextXAlignment = Enum.TextXAlignment.Left
    OnlineNowCaption.Parent = OnlineNowBox

    local OnlineNowLabel = Instance.new("TextLabel")
    OnlineNowLabel.Size = UDim2.new(1, -20, 0, 28)
    OnlineNowLabel.Position = UDim2.new(0, 10, 0, 36)
    OnlineNowLabel.BackgroundTransparency = 1
    OnlineNowLabel.Text = "🟢 Carregando..."
    OnlineNowLabel.TextColor3 = COLOR_SUCCESS
    OnlineNowLabel.Font = Enum.Font.FredokaOne
    OnlineNowLabel.TextSize = 17
    OnlineNowLabel.TextXAlignment = Enum.TextXAlignment.Left
    OnlineNowLabel.Parent = OnlineNowBox

    local function loadModStats()
        task.spawn(function()
            local ok, data = chosenApiCall({
                Url = CHOSEN_API_URL .. "/stats",
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json"
                }
            })

            if not ok then
                RegisteredLabel.Text = "👥 —"
                OnlineNowLabel.Text = "🟢 —"
                return
            end

            local total = tonumber(data.total_users)
                or tonumber(data.users_total)
                or tonumber(data.registered)
                or (type(data.registered_users) == "table" and #data.registered_users)
                or nil

            local onlineNow = tonumber(data.online_now)
                or tonumber(data.online)
                or tonumber(data.active_sessions)
                or nil

            RegisteredLabel.Text = total and ("👥 " .. total) or "👥 —"
            OnlineNowLabel.Text = onlineNow and ("🟢 " .. onlineNow) or "🟢 —"
        end)
    end

    -- O loop principal chama isto a cada ciclo (atualiza sozinho).
    chosenRefreshModStats = loadModStats

    -- ------------------------------------------------------
    -- USUÁRIOS ONLINE (can_view_online)
    -- ------------------------------------------------------
    createSection(chosenModTab, "👥 Usuários online", "Sessões ativas reportadas pelo heartbeat.", nextOrder())

    local OnlineRow = createControlRow(chosenModTab, nextOrder())
    local OnlineRefresh = createActionButton(OnlineRow, "🔄 Atualizar", 1)
    OnlineRefresh.Size = UDim2.new(0, 104, 0, 26)
    OnlineRefresh.Position = UDim2.new(0, 0, 0.5, -13)
    OnlineRefresh.TextSize = 10

    local OnlineStatus = createModStatus(OnlineRow)
    refs.OnlineStatus = OnlineStatus

    local OnlineList = Instance.new("ScrollingFrame")
    OnlineList.Size = UDim2.new(1, -4, 0, 150)
    OnlineList.BackgroundColor3 = COLOR_CARD
    OnlineList.BackgroundTransparency = 0.08
    OnlineList.BorderSizePixel = 0
    OnlineList.ScrollBarThickness = 3
    OnlineList.CanvasSize = UDim2.new(0, 0, 0, 0)
    OnlineList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    OnlineList.LayoutOrder = nextOrder()
    OnlineList.Parent = chosenModTab
    corner(OnlineList, 8)
    stroke(OnlineList, COLOR_BORDER, 1, 0.3)

    local OnlineListLayout = Instance.new("UIListLayout")
    OnlineListLayout.Padding = UDim.new(0, 6)
    OnlineListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    OnlineListLayout.Parent = OnlineList

    local OnlineListPadding = Instance.new("UIPadding")
    OnlineListPadding.PaddingTop = UDim.new(0, 8)
    OnlineListPadding.PaddingBottom = UDim.new(0, 8)
    OnlineListPadding.PaddingLeft = UDim.new(0, 8)
    OnlineListPadding.PaddingRight = UDim.new(0, 8)
    OnlineListPadding.Parent = OnlineList

    local function clearOnlineList()
        for _, child in ipairs(OnlineList:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
    end

    local function addOnlineEntry(user, index)
        local userId = tostring(user.user_id or user.id or "")
        local username = tostring(user.username or ("User " .. userId))
        local role = tostring(user.role or "Member")

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 48)
        row.BackgroundColor3 = COLOR_CARD2
        row.BackgroundTransparency = 0.12
        row.BorderSizePixel = 0
        row.LayoutOrder = index
        row.Parent = OnlineList
        corner(row, 8)
        stroke(row, COLOR_BORDER, 1, 0.3)

        local avatar = Instance.new("ImageLabel")
        avatar.Size = UDim2.new(0, 34, 0, 34)
        avatar.Position = UDim2.new(0, 8, 0.5, -17)
        avatar.BackgroundColor3 = COLOR_SIDE
        avatar.Image = "rbxassetid://0"
        avatar.Parent = row
        corner(avatar, 17)
        stroke(avatar, COLOR_ACCENT, 1, 0.3)

        local idNumber = tonumber(userId)
        if idNumber then
            pcall(function()
                avatar.Image = Players:GetUserThumbnailAsync(
                    idNumber,
                    Enum.ThumbnailType.AvatarBust,
                    Enum.ThumbnailSize.Size420x420
                )
            end)
        end

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 170, 0, 18)
        nameLabel.Position = UDim2.new(0, 52, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = username
        nameLabel.TextColor3 = COLOR_TEXT
        nameLabel.Font = Enum.Font.FredokaOne
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = row

        local idLabel = Instance.new("TextLabel")
        idLabel.Size = UDim2.new(0, 170, 0, 14)
        idLabel.Position = UDim2.new(0, 52, 0, 27)
        idLabel.BackgroundTransparency = 1
        idLabel.Text = "UserID " .. userId
        idLabel.TextColor3 = COLOR_MUTED
        idLabel.Font = Enum.Font.FredokaOne
        idLabel.TextSize = 9
        idLabel.TextXAlignment = Enum.TextXAlignment.Left
        idLabel.TextTruncate = Enum.TextTruncate.AtEnd
        idLabel.Parent = row

        local roleLabel = Instance.new("TextLabel")
        roleLabel.Size = UDim2.new(0, 120, 0, 20)
        roleLabel.Position = UDim2.new(1, -130, 0.5, -10)
        roleLabel.BackgroundColor3 = COLOR_SIDE
        roleLabel.BackgroundTransparency = 0.25
        roleLabel.Text = string.upper(role)
        roleLabel.TextColor3 = CHOSEN_ROLE_COLORS[role] or COLOR_DIM
        roleLabel.Font = Enum.Font.FredokaOne
        roleLabel.TextSize = 10
        roleLabel.TextXAlignment = Enum.TextXAlignment.Center
        roleLabel.Parent = row
        corner(roleLabel, 10)
    end

    local function loadOnline()
        if not chosenHasPerm("CHOSEN_CanViewOnline") then
            chosenLockNotice(OnlineStatus, "can_view_online")
            return
        end
        clearOnlineList()
        OnlineStatus.Text = "Carregando..."
        OnlineStatus.TextColor3 = COLOR_DIM
        task.spawn(function()
            local ok, data = chosenApiCall({
                Url = CHOSEN_API_URL .. "/online",
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json"
                }
            })

            if not ok then
                OnlineStatus.Text = "⚠  " .. tostring(data):sub(1, 44)
                OnlineStatus.TextColor3 = CHOSEN_WARN
                return
            end

            local users = (type(data.users) == "table" and data.users)
                or (type(data.data) == "table" and data.data)
                or {}

            local shown = 0
            for _, user in ipairs(users) do
                if type(user) == "table" then
                    shown += 1
                    addOnlineEntry(user, shown)
                end
            end

            OnlineStatus.Text = shown > 0
                and (shown .. " usuário(s) online")
                or "Nenhum usuário online"
            OnlineStatus.TextColor3 = COLOR_DIM
        end)
    end
    OnlineRefresh.MouseButton1Click:Connect(loadOnline)

    -- ------------------------------------------------------
    -- ANÚNCIO (Owner e Moderador)
    -- ------------------------------------------------------
    createSection(chosenModTab, "📣 Anúncio global",
        "Mensagem permanente • todos veem no Início • Owner e Moderador.", nextOrder())

    local AnnBox, AnnSend, AnnStatus = createModComposer(
        "Digite o anúncio para os usuários...", "📣  Enviar", nextOrder())
    refs.AnnStatus = AnnStatus

    AnnSend.MouseButton1Click:Connect(function()
        -- Owner e Moderador podem anunciar (o servidor valida o cargo real).
        local role = ScreenGui:GetAttribute("CHOSEN_Role")
        if role ~= "Owner" and role ~= "Moderator" then
            chosenLockNotice(AnnStatus, "cargo Owner ou Moderador")
            return
        end
        local message = AnnBox.Text
        if message == "" then
            AnnStatus.Text = "⚠  Escreva o anúncio primeiro"
            AnnStatus.TextColor3 = CHOSEN_WARN
            return
        end
        AnnStatus.Text = "Enviando..."
        AnnStatus.TextColor3 = COLOR_DIM
        task.spawn(function()
            local ok, data = chosenApiCall({
                Url = CHOSEN_API_URL .. "/announcement",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Accept"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    message = message,
                    author_id = tostring(LocalPlayer.UserId)
                })
            })

            if ok and data.success then
                AnnStatus.Text = "✅  Anúncio publicado"
                AnnStatus.TextColor3 = COLOR_SUCCESS
                AnnBox.Text = ""
            else
                AnnStatus.Text = "⚠  " .. tostring(data):sub(1, 100)
                AnnStatus.TextColor3 = CHOSEN_WARN
            end
        end)
    end)

    -- ------------------------------------------------------
    -- AVISO (Owner e Moderador)
    -- ------------------------------------------------------
    createSection(chosenModTab, "💬 Aviso",
        "Aviso do momento • aparece no canto e some em 10s • Owner e Moderador.", nextOrder())

    local LiveBox, LiveSend, LiveStatus = createModComposer(
        "Digite o aviso do momento...", "💬  Enviar", nextOrder())
    refs.LiveStatus = LiveStatus

    -- Cooldown: 10 segundos entre um envio e outro
    local liveCooldownUntil = 0

    LiveSend.MouseButton1Click:Connect(function()
        local role = ScreenGui:GetAttribute("CHOSEN_Role")
        if role ~= "Owner" and role ~= "Moderator" then
            chosenLockNotice(LiveStatus, "cargo Owner ou Moderador")
            return
        end

        local nowClock = os.clock()
        if nowClock < liveCooldownUntil then
            LiveStatus.Text = "⏳  Aguarde "
                .. math.ceil(liveCooldownUntil - nowClock)
                .. "s para enviar de novo"
            LiveStatus.TextColor3 = CHOSEN_WARN
            return
        end

        local message = LiveBox.Text
        if message == "" then
            LiveStatus.Text = "⚠  Escreva o aviso primeiro"
            LiveStatus.TextColor3 = CHOSEN_WARN
            return
        end
        LiveStatus.Text = "Enviando..."
        LiveStatus.TextColor3 = COLOR_DIM
        task.spawn(function()
            local ok, data = chosenApiCall({
                Url = CHOSEN_API_URL .. "/live-message",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Accept"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    message = message,
                    author_id = tostring(LocalPlayer.UserId)
                })
            })

            -- Cooldown conta a partir da tentativa
            liveCooldownUntil = os.clock() + 10

            if ok and data.success then
                LiveStatus.Text = "✅  Aviso enviado (aparece por 10s)"
                LiveStatus.TextColor3 = COLOR_SUCCESS
                LiveBox.Text = ""
            else
                LiveStatus.Text = "⚠  " .. tostring(data):sub(1, 100)
                LiveStatus.TextColor3 = CHOSEN_WARN
            end
        end)
    end)

    -- ------------------------------------------------------
    -- KICK DO SERVIDOR (Owner e Moderador)
    -- Expulsa o jogador da sessão: tenta o Kick direto e, em
    -- paralelo, avisa pelo canal ao vivo — o painel do alvo
    -- expulsa ele mesmo ao receber. Funciona em quem está
    -- online com o painel aberto naquele momento.
    -- ------------------------------------------------------
    createSection(chosenModTab, "🚪 Kick",
        "Expulsa um jogador desta sessão • motivo opcional.", nextOrder())

    local KickTargetInput, KickTargetAvatar = createInputWithAvatar(
        chosenModTab, "Nome do jogador...", nextOrder())

    KickTargetInput:GetPropertyChangedSignal("Text"):Connect(function()
        local player = nil
        local lower = KickTargetInput.Text:lower()
        if lower ~= "" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Name:lower():sub(1, #lower) == lower then
                    player = p
                    break
                end
            end
        end

        if player then
            pcall(function()
                KickTargetAvatar.Image = Players:GetUserThumbnailAsync(
                    player.UserId,
                    Enum.ThumbnailType.AvatarBust,
                    Enum.ThumbnailSize.Size420x420
                )
            end)
        else
            KickTargetAvatar.Image = "rbxassetid://0"
        end
    end)

    local KickReasonBox, KickSend, KickStatus = createModComposer(
        "Motivo do kick (opcional)...", "🚪  Expulsar", nextOrder())
    refs.KickStatus = KickStatus

    -- Anti-spam: 5 segundos entre um kick e outro
    local kickCooldownUntil = 0

    local function resolveKickTarget()
        local lower = KickTargetInput.Text:lower()
        if lower == "" then return nil end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Name:lower():sub(1, #lower) == lower then
                return p
            end
        end
        return nil
    end

    KickSend.MouseButton1Click:Connect(function()
        local role = ScreenGui:GetAttribute("CHOSEN_Role")
        if role ~= "Owner" and role ~= "Moderator" then
            chosenLockNotice(KickStatus, "cargo Owner ou Moderador")
            return
        end

        local nowClock = os.clock()
        if nowClock < kickCooldownUntil then
            KickStatus.Text = "⏳  Aguarde "
                .. math.ceil(kickCooldownUntil - nowClock)
                .. "s para kickar de novo"
            KickStatus.TextColor3 = CHOSEN_WARN
            return
        end

        local target = resolveKickTarget()
        if not target then
            KickStatus.Text = "⚠  Digite o nome de um jogador da sessão"
            KickStatus.TextColor3 = CHOSEN_WARN
            return
        end

        local reason = KickReasonBox.Text
        kickCooldownUntil = os.clock() + 5
        KickStatus.Text = "Expulsando " .. target.Name .. "..."
        KickStatus.TextColor3 = COLOR_DIM

        task.spawn(function()
            -- 1) Kick direto (funciona em alguns jogos/executores)
            local directOk = pcall(function()
                target:Kick(#reason > 0 and reason or "Expulso da experiência")
            end)

            -- 2) Kick via painel: o alvo recebe pelo canal ao vivo e
            -- se expulsa com o motivo (só Owner/Moderador podem enviar;
            -- o servidor valida o cargo real de quem mandou).
            local ok, data = chosenApiCall({
                Url = CHOSEN_API_URL .. "/live-message",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Accept"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    message = #reason > 0 and reason or "kick",
                    kind = "kick",
                    target_id = tostring(target.UserId),
                    author_id = tostring(LocalPlayer.UserId)
                })
            })

            if directOk then
                KickStatus.Text = "✅  " .. target.Name .. " expulso"
                KickStatus.TextColor3 = COLOR_SUCCESS
            elseif ok and data.success then
                KickStatus.Text = "✅  Kick enviado (expulsa quem está com o painel)"
                KickStatus.TextColor3 = COLOR_SUCCESS
            else
                KickStatus.Text = "⚠  " .. tostring(data):sub(1, 80)
                KickStatus.TextColor3 = CHOSEN_WARN
            end
            KickTargetInput.Text = ""
            KickTargetAvatar.Image = "rbxassetid://0"
            KickReasonBox.Text = ""
        end)
    end)

    -- ------------------------------------------------------
    -- CARGO TEMPORÁRIO (SÓ NESTA SESSÃO • QUALQUER JOGADOR)
    -- ------------------------------------------------------
    createSection(chosenModTab, "🎭 Cargo temporário",
        "Aplica a um jogador da sessão • só muda na SUA tela.", nextOrder())

    local TempTargetInput, TempTargetAvatar = createInputWithAvatar(chosenModTab, "Nome do jogador (vazio = você)", nextOrder())

    TempTargetInput:GetPropertyChangedSignal("Text"):Connect(function()
        local player = nil
        local text = TempTargetInput.Text
        if text ~= "" then
            local lower = text:lower()
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():sub(1, #lower) == lower then
                    player = p
                    break
                end
            end
        else
            player = LocalPlayer
        end

        if player then
            pcall(function()
                TempTargetAvatar.Image = Players:GetUserThumbnailAsync(
                    player.UserId,
                    Enum.ThumbnailType.AvatarBust,
                    Enum.ThumbnailSize.Size420x420
                )
            end)
        else
            TempTargetAvatar.Image = "rbxassetid://0"
        end
    end)

    local TempStatus = createModStatusWide()
    refs.TempStatus = TempStatus

    local function resolveTempTarget()
        local text = TempTargetInput.Text
        if text == "" or text:lower() == LocalPlayer.Name:lower() then
            return LocalPlayer
        end

        local lower = text:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Name:lower():sub(1, #lower) == lower then
                return p
            end
        end

        return nil
    end

    local function setTemporaryRole(role)
        local target = resolveTempTarget()

        if not target then
            TempStatus.Text = "⚠  Jogador não está nesta sessão"
            TempStatus.TextColor3 = CHOSEN_WARN
            return
        end

        -- Aplica o temporário na tag do alvo (na sua tela).
        pcall(chosenApplyTempRole, target.UserId, role)

        if target == LocalPlayer then
            chosenTemporaryRole = role
            pcall(chosenApplyPermissions, role, CHOSEN_TEMP_PERMISSIONS[role], true)
            TempStatus.Text = "✅  Cargo temporário: " .. role .. " → você (só nesta sessão)"
        else
            TempStatus.Text = "✅  Cargo temporário: " .. role .. " → " .. target.Name .. " (só na sua tela)"
        end
        TempStatus.TextColor3 = COLOR_SUCCESS
    end

    local TempRowA = createControlRow(chosenModTab, nextOrder())
    createActionButton(TempRowA, "👑 Owner", 1).MouseButton1Click:Connect(function()
        setTemporaryRole("Owner")
    end)
    createActionButton(TempRowA, "🛡 Moderador", 2).MouseButton1Click:Connect(function()
        setTemporaryRole("Moderator")
    end)

    local TempRowB = createControlRow(chosenModTab, nextOrder())
    createActionButton(TempRowB, "⭐ Premium", 1).MouseButton1Click:Connect(function()
        setTemporaryRole("Premium")
    end)
    createActionButton(TempRowB, "👤 Membro", 2).MouseButton1Click:Connect(function()
        setTemporaryRole("Member")
    end)

    local TempRowC = createControlRow(chosenModTab, nextOrder())
    createActionButton(TempRowC, "↩ Restaurar todos os cargos reais", 1).MouseButton1Click:Connect(function()
        -- Remove todos os temporários da sessão (seu + dos outros)
        local userIds = {}
        for userId in pairs(chosenTempRoles) do
            table.insert(userIds, userId)
        end
        for _, userId in ipairs(userIds) do
            pcall(chosenApplyTempRole, userId, nil)
        end

        chosenTemporaryRole = nil

        if chosenProfile and chosenProfilePermissions then
            pcall(chosenApplyPermissions,
                tostring(chosenProfile.role or "Member"),
                chosenProfilePermissions,
                false
            )
        end

        TempStatus.Text = "✅  Cargos reais restaurados"
        TempStatus.TextColor3 = COLOR_SUCCESS
    end)

    -- Primeira carga: estatísticas e lista de online sem esperar o ciclo.
    loadModStats()
    task.defer(loadOnline)
end

task.spawn(function()
    if CHOSEN_API_URL:find("SEU%-PROJETO") then
        ChosenRoleLabel.Text = "CONFIGURE A URL DA API"
        UserStatus.Text = "API NÃO CONFIGURADA"
        UserStatus.BackgroundColor3 = Color3.fromRGB(170, 90, 55)
        warn("[CHOSEN API] Configure CHOSEN_API_URL com o domínio do seu Supabase.")
        return
    end

    while ScreenGui.Parent do
        -- Sem requisições durante a injeção de um script grande:
        -- as chamadas HTTP do painel competem com o download/compilação.
        if not CHOSEN_EXT_BUSY then
            chosenHeartbeat()
            chosenUpdateProfile()

            -- Anúncio: todos os usuários buscam a cada ciclo.
            if type(chosenFetchAnnouncement) == "function" then
                pcall(chosenFetchAnnouncement)
            end

            -- Estatísticas: só refresca se a aba Moderação existir.
            if type(chosenRefreshModStats) == "function" then
                pcall(chosenRefreshModStats)
            end
        end

        task.wait(30)
    end
end)

end

-- ==========================================================
-- BAN DE VOZ
-- (as flags de carga externa agora ficam no topo do arquivo)
-- ==========================================================

-- Módulo isolado numa função própria: o chunk principal deste
-- arquivo já está perto do limite de 200 variáveis locais do Luau,
-- e declarar mais ~35 aqui em cima impede o script de compilar.
local function chosenInstallVoiceBan()
	-- ==========================================================
	-- BAN DE VOZ (ROBLOX)
	-- O Roblox não informa motivo nem duração de um ban de voz.
	-- O painel apenas LÊ a interface: quando o aviso
	-- "Conversa por voz suspensa" aparece, começa uma contagem de
	-- 5 min no botão do topo. Ao terminar, o botão fica verde e
	-- libera o rejoin. Nada aqui altera voz ou moderação.
	-- ==========================================================

	local COLOR_WARN = Color3.fromRGB(245, 178, 82)
	local VOICE_BAN_SECONDS = 5 * 60

	-- Se o jogo começar a crashar ao abrir scripts grandes, troque para
	-- false: desliga só a varredura da interface. O botão manual e a
	-- detecção pelo chat continuam funcionando normalmente.
	local VOICE_BAN_UI_WATCH = not CHOSEN_LIGHT_MODE

	local voiceBanPhase = "idle" -- idle | active | released
	local voiceBanRemaining = VOICE_BAN_SECONDS
	local voiceBanStart = 0
	local voiceBanToast = nil

	local function voiceBanFormat(seconds)
		local s = math.max(0, math.floor(seconds + 0.999))
		return string.format("%02d:%02d", math.floor(s / 60), s % 60)
	end

	local function voiceBanRejoin()
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end)
	end

	-- ---------- botão no topo, ao lado de SISTEMA ONLINE ----------

	local VoiceBanButton = Instance.new("TextButton")
	VoiceBanButton.Name = "ChosenVoiceBanButton"
	VoiceBanButton.Size = UDim2.new(0, 104, 0, 26)
	VoiceBanButton.Position = UDim2.new(1, -228, 0, 16)
	VoiceBanButton.BackgroundColor3 = COLOR_CARD
	VoiceBanButton.BackgroundTransparency = 0.35
	VoiceBanButton.AutoButtonColor = false
	VoiceBanButton.Text = "🎙  MEU BAN"
	VoiceBanButton.TextColor3 = COLOR_MUTED
	VoiceBanButton.Font = Enum.Font.FredokaOne
	VoiceBanButton.TextSize = 9
	VoiceBanButton.BorderSizePixel = 0
	VoiceBanButton.Parent = TopBar
	corner(VoiceBanButton, 8)
	local VoiceBanButtonStroke = stroke(VoiceBanButton, COLOR_BORDER, 1, 0.4)

	local function voiceBanPaint()
		if voiceBanPhase == "active" then
			VoiceBanButton.Text = "🎙  " .. voiceBanFormat(voiceBanRemaining)
			VoiceBanButton.TextColor3 = COLOR_WARN
			VoiceBanButtonStroke.Color = COLOR_WARN
		elseif voiceBanPhase == "released" then
			VoiceBanButton.Text = "🎙  REJOIN"
			VoiceBanButton.TextColor3 = COLOR_SUCCESS
			VoiceBanButtonStroke.Color = COLOR_SUCCESS
		else
			VoiceBanButton.Text = "🎙  MEU BAN"
			VoiceBanButton.TextColor3 = COLOR_MUTED
			VoiceBanButtonStroke.Color = COLOR_BORDER
		end
	end

	VoiceBanButton.MouseEnter:Connect(function()
		tween(VoiceBanButton, {BackgroundTransparency = 0.1}, 0.12)
		local target = voiceBanPhase == "released" and COLOR_SUCCESS
			or voiceBanPhase == "active" and COLOR_WARN
			or COLOR_ACCENT
		tween(VoiceBanButtonStroke, {Color = target}, 0.12)
	end)
	VoiceBanButton.MouseLeave:Connect(function()
		tween(VoiceBanButton, {BackgroundTransparency = 0.35}, 0.12)
		voiceBanPaint()
	end)

	-- ---------- aviso no canto, na altura do meio da tela ----------

	local function voiceBanCloseToast()
		local old = voiceBanToast
		voiceBanToast = nil
		local stray = ScreenGui:FindFirstChild("ChosenVoiceBanToast")
		if stray and stray ~= old then
			stray:Destroy()
		end
		if not old or not old.Parent then return end
		tween(old, {Position = UDim2.new(1, 360, 0.5, 0)}, 0.3)
		task.delay(0.35, function()
			pcall(function() old:Destroy() end)
		end)
	end

	local function voiceBanShowToast()
		voiceBanCloseToast()

		local toast = Instance.new("Frame")
		toast.Name = "ChosenVoiceBanToast"
		toast.AnchorPoint = Vector2.new(1, 0.5)
		toast.Position = UDim2.new(1, 360, 0.5, 0) -- fora da tela; entra deslizando
		toast.Size = UDim2.new(0, 316, 0, 128)
		toast.BackgroundColor3 = COLOR_PANEL
		toast.BackgroundTransparency = 0.03
		toast.BorderSizePixel = 0
		toast.ZIndex = 60
		toast.Parent = ScreenGui
		corner(toast, 10)
		stroke(toast, COLOR_SUCCESS, 1.2, 0.35)
		voiceBanToast = toast

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 4, 1, 0)
		bar.BackgroundColor3 = COLOR_SUCCESS
		bar.BorderSizePixel = 0
		bar.ZIndex = 61
		bar.Parent = toast
		corner(bar, 2)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -60, 0, 16)
		title.Position = UDim2.new(0, 18, 0, 10)
		title.BackgroundTransparency = 1
		title.Text = "🎙  BAN DE VOZ"
		title.TextColor3 = COLOR_SUCCESS
		title.Font = Enum.Font.LuckiestGuy
		title.TextSize = 11
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 60
		title.Parent = toast

		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.new(1, -60, 0, 14)
		sub.Position = UDim2.new(0, 18, 0, 27)
		sub.BackgroundTransparency = 1
		sub.Text = "SEU BAN PASSOU"
		sub.TextColor3 = COLOR_TEXT
		sub.Font = Enum.Font.FredokaOne
		sub.TextSize = 10
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.ZIndex = 60
		sub.Parent = toast

		local body = Instance.new("TextLabel")
		body.Size = UDim2.new(1, -36, 0, 32)
		body.Position = UDim2.new(0, 18, 0, 44)
		body.BackgroundTransparency = 1
		body.Text = "Já pode relogar para voltar a usar a voz."
		body.TextColor3 = COLOR_MUTED
		body.Font = Enum.Font.FredokaOne
		body.TextSize = 10
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.TextWrapped = true
		body.ZIndex = 60
		body.Parent = toast

		local close = Instance.new("TextButton")
		close.Size = UDim2.new(0, 24, 0, 24)
		close.Position = UDim2.new(1, -32, 0, 9)
		close.BackgroundColor3 = COLOR_CARD2
		close.BackgroundTransparency = 0.2
		close.AutoButtonColor = false
		close.Text = "X"
		close.TextColor3 = COLOR_TEXT
		close.Font = Enum.Font.FredokaOne
		close.TextSize = 12
		close.ZIndex = 61
		close.Parent = toast
		corner(close, 8)

		local rejoin = Instance.new("TextButton")
		rejoin.Size = UDim2.new(0, 132, 0, 26)
		rejoin.Position = UDim2.new(0, 18, 1, -40)
		rejoin.BackgroundColor3 = COLOR_CARD2
		rejoin.BackgroundTransparency = 0.15
		rejoin.AutoButtonColor = false
		rejoin.Text = "🔁  REJOIN"
		rejoin.TextColor3 = COLOR_SUCCESS
		rejoin.Font = Enum.Font.LuckiestGuy
		rejoin.TextSize = 11
		rejoin.ZIndex = 61
		rejoin.Parent = toast
		corner(rejoin, 8)
		local rejoinStroke = stroke(rejoin, COLOR_SUCCESS, 1, 0.25)

		tween(toast, {Position = UDim2.new(1, -16, 0.5, 0)}, 0.35)

		close.MouseEnter:Connect(function()
			tween(close, {BackgroundColor3 = COLOR_CARD}, 0.12)
		end)
		close.MouseLeave:Connect(function()
			tween(close, {BackgroundColor3 = COLOR_CARD2}, 0.12)
		end)
		close.MouseButton1Click:Connect(voiceBanCloseToast)

		rejoin.MouseEnter:Connect(function()
			tween(rejoin, {BackgroundColor3 = Color3.fromRGB(56, 102, 158), BackgroundTransparency = 0.05}, 0.12)
			tween(rejoinStroke, {Color = COLOR_ACCENT}, 0.12)
		end)
		rejoin.MouseLeave:Connect(function()
			tween(rejoin, {BackgroundColor3 = COLOR_CARD2, BackgroundTransparency = 0.15}, 0.12)
			tween(rejoinStroke, {Color = COLOR_SUCCESS}, 0.12)
		end)
		rejoin.MouseButton1Click:Connect(function()
			voiceBanRejoin()
		end)
	end

	-- ---------- contagem ----------

	local function voiceBanBegin(source)
		voiceBanPhase = "active"
		voiceBanStart = os.clock()
		voiceBanRemaining = VOICE_BAN_SECONDS
		VoiceBanButton.TextColor3 = COLOR_WARN
		voiceBanPaint()
		print("[CHOSEN VOZ] contagem iniciada (" .. tostring(source) .. ")")
	end

	local function voiceBanRelease()
		if voiceBanPhase == "released" then return end
		voiceBanPhase = "released"
		voiceBanRemaining = 0
		voiceBanPaint()
		voiceBanShowToast()
		print("[CHOSEN VOZ] contagem concluída: rejoin liberado")
	end

	local function voiceBanCancel()
		voiceBanPhase = "idle"
		voiceBanRemaining = VOICE_BAN_SECONDS
		voiceBanPaint()
		voiceBanCloseToast()
	end

	VoiceBanButton.MouseButton1Click:Connect(function()
		if voiceBanPhase == "active" then
			voiceBanCancel()
		elseif voiceBanPhase == "released" then
			voiceBanRejoin()
		else
			voiceBanBegin("manual")
		end
	end)

	-- Relógio local: atualiza o texto sem chamadas extras.
	task.spawn(function()
		while VoiceBanButton.Parent do
			if voiceBanPhase == "active" then
				voiceBanRemaining = VOICE_BAN_SECONDS - (os.clock() - voiceBanStart)
				if voiceBanRemaining <= 0 then
					voiceBanRelease()
				else
					voiceBanPaint()
				end
			end
			task.wait(0.5)
		end
	end)

	-- Textos do próprio painel/console nunca contam como aviso do Roblox
	-- (o console do F9 repete as nossas mensagens e gera falso positivo).
	local function voiceBanNoiseText(text)
		if #text > 90 then return true end
		local t = string.lower(text)
		if text:find("\n", 1, true) then return true end
		if t:find("[chosen", 1, true) then return true end
		if t:find("chosen voz", 1, true) then return true end
		if t:find("-- ", 1, true) then return true end
		-- Nomes de comando de scripts/menus (ex.: Infinity Yield:
		-- "muteallvoices / muteallvcs") não são aviso de ban.
		if t:find("mute", 1, true) then return true end
		if t:find("unmute", 1, true) then return true end
		if t:find("vcs", 1, true) then return true end
		if t:find("bypass", 1, true) then return true end
		if t:find("anti voice", 1, true) then return true end
		if t:find("anti-voz", 1, true) then return true end
		-- Texto com cara de código/lista não é frase de aviso.
		if text:find("[\\/%(%)%[%]{}_=<>|]", 1) then return true end
		return false
	end

	local function voiceBanTextMatches(text)
		if voiceBanNoiseText(text) then return false end
		local t = string.lower(text)

		-- Exige falar de voz/microfone...
		if not (t:find("voz", 1, true)
			or t:find("voice", 1, true)
			or t:find("microfone", 1, true)) then
			return false
		end

		-- ...e de suspensão/bloqueio. Nada de "mute", "block" ou
		-- "cooldown" soltos: aparecem em menus de script e davam falso positivo.
		return t:find("suspens", 1, true) ~= nil
			or t:find("suspend", 1, true) ~= nil
			or t:find("banid", 1, true) ~= nil
			or t:find("banido", 1, true) ~= nil
			or t:find("banned", 1, true) ~= nil
			or t:find("indispon", 1, true) ~= nil
			or t:find("unavailable", 1, true) ~= nil
			or t:find("restrit", 1, true) ~= nil
			or t:find("restrict", 1, true) ~= nil
			or t:find("bloquead", 1, true) ~= nil
			-- "ban" isolado, mas só como palavra inteira
			or t:find("%f[%a]ban%f[%A]") ~= nil
	end

	-- Evita que o mesmo aviso reinicie a contagem várias vezes.
	local voiceBanIgnore = {}

	local function voiceBanNotice(text, source)
		if voiceBanPhase == "active" then return end
		local key = (string.lower(text):gsub("%s+", " "))
		local now = os.clock()
		local untilAt = voiceBanIgnore[key]
		if untilAt and now < untilAt then
			return
		end
		voiceBanIgnore[key] = now + 180
		print("[CHOSEN VOZ] ban detectado " .. source .. ": " .. text)
		voiceBanBegin("interface")
	end

	-- 1) Aviso no chat.
	pcall(function()
		local TextChatService = game:GetService("TextChatService")
		TextChatService.MessageReceived:Connect(function(message)
			if voiceBanPhase == "active" then return end
			local text = type(message.Text) == "string" and message.Text or ""
			if voiceBanTextMatches(text) then
				voiceBanNotice(text, "pelo chat")
			end
		end)
	end)

	-- 2) Aviso na interface (o caso real: "Conversa por voz suspensa").
	local function voiceBanScanRobloxUI()
		local roots = {}
		local okHui, hui = pcall(function()
			if type(gethui) == "function" then
				return gethui()
			end
		end)
		if okHui and hui then table.insert(roots, hui) end
		local okCore, core = pcall(function()
			return game:GetService("CoreGui")
		end)
		if okCore and core then table.insert(roots, core) end
		local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
		if playerGui then table.insert(roots, playerGui) end

		for _, root in ipairs(roots) do
			local ok, items = pcall(function()
				return root:GetDescendants()
			end)
			if ok then
				local checked = 0
				for _, obj in ipairs(items) do
					if checked >= 600 then break end
					if obj.ClassName == "TextLabel" or obj.ClassName == "TextButton" then
						local okText, text = pcall(function()
							return obj.Text
						end)
						if okText and type(text) == "string"
							and #text > 3 and #text <= 90
							and obj.Visible then
							checked += 1
							if voiceBanTextMatches(text)
								and not obj:IsDescendantOf(ScreenGui) then
								return text
							end
						end
					end
				end
			end
		end
		return nil
	end

	local voiceBanDiagSeen = {}
	local voiceBanDiagKeys = 0

	local function voiceBanInspect(obj)
		if obj.ClassName ~= "TextLabel" and obj.ClassName ~= "TextButton" then
			return
		end
		local okText, text = pcall(function()
			return obj.Text
		end)
		if not okText or type(text) ~= "string" then return end
		if #text < 4 or #text > 90 then return end
		local okSelf, mine = pcall(function()
			return obj:IsDescendantOf(ScreenGui)
		end)
		if okSelf and mine then return end
		if voiceBanTextMatches(text) then
			voiceBanNotice(text, "na interface")
			return
		end
		-- Diagnóstico: mostra no F9 textos com "voz/voice" que foram
		-- ignorados. Ajuda a identificar novos falsos positivos.
		local lower = string.lower(text)
		if not voiceBanDiagSeen[text]
			and (lower:find("voz", 1, true) or lower:find("voice", 1, true)) then
			if voiceBanDiagKeys >= 8 then return end
			voiceBanDiagKeys += 1
			voiceBanDiagSeen[text] = true
			print("[CHOSEN VOZ] ignorado: " .. text)
		end
	end

	local voiceBanRoots = {}
	local voiceBanConnections = {}
	local voiceBanAttached = false
	-- Pausa automática: se uma enxurrada de instâncias chegar (script
	-- externo injetado por fora), o monitor se desconecta sozinho e
	-- volta alguns segundos depois.
	local voiceBanPausedUntil = 0
	local voiceBanDetachAll

	-- Fila: quando um script grande (Infinite Yield, emotes) monta a
	-- interface, centenas de TextLabels nascem no mesmo frame. Ler o
	-- texto de todos na hora travava o cliente. Agora só empilhamos e
	-- o processamento acontece em lotes pequenos, fora do frame.
	local voiceBanQueue = {}
	local voiceBanQueueIndex = 1
	local VOICE_BAN_QUEUE_MAX = 300
	local VOICE_BAN_BATCH = 10

	-- Orçamento de eventos por segundo. Um script grande cria
	-- milhares de objetos; sem esse teto o DescendantAdded vira uma
	-- enxurrada de callbacks e o executor fecha. Ao estourar, a
	-- gente para de enfileirar e resolve tudo numa varredura só.
	local VOICE_BAN_EVENT_BUDGET = 120
	local voiceBanBudget = 0
	local voiceBanBudgetReset = 0

	local function voiceBanRequestRescan(delay)
		local at = os.clock() + (delay or 2)
		if at > CHOSEN_VB_RESCAN_AT then
			CHOSEN_VB_RESCAN_AT = at
		end
	end

	local function voiceBanEnqueue(obj)
		if #voiceBanQueue - (voiceBanQueueIndex - 1) >= VOICE_BAN_QUEUE_MAX then
			voiceBanRequestRescan(3)
			return
		end
		voiceBanQueue[#voiceBanQueue + 1] = obj
	end

	local function voiceBanOnDescendant(obj)
		local class = obj.ClassName
		if class ~= "TextLabel" and class ~= "TextButton" then return end

		-- O painel também mora no CoreGui: ignora a própria interface.
		local okSelf, mine = pcall(function()
			return obj:IsDescendantOf(ScreenGui)
		end)
		if okSelf and mine then return end

		-- Injeção externa em andamento: não processa nada agora.
		if CHOSEN_EXT_BUSY then
			voiceBanRequestRescan(4)
			return
		end

		local now = os.clock()
		if now > voiceBanBudgetReset then
			voiceBanBudgetReset = now + 1
			voiceBanBudget = 0
		end
		voiceBanBudget += 1
		if voiceBanBudget > VOICE_BAN_EVENT_BUDGET then
			-- Enxurrada: desconecta na hora em vez de só ignorar.
			-- Ignorar ainda paga uma chamada Lua por instância criada.
			voiceBanPausedUntil = now + 6
			voiceBanRequestRescan(7)
			if voiceBanDetachAll then voiceBanDetachAll() end
			return
		end

		voiceBanEnqueue(obj)
	end

	local function voiceBanAddRoot(root)
		if not root then return end
		for _, existing in ipairs(voiceBanRoots) do
			if existing == root then return end
		end
		table.insert(voiceBanRoots, root)

		local conn
		local ok = pcall(function()
			conn = root.DescendantAdded:Connect(voiceBanOnDescendant)
		end)
		if ok and conn then
			table.insert(voiceBanConnections, conn)
		end
	end

	local function voiceBanAttachAll()
		if voiceBanAttached then return end
		voiceBanAttached = true
		voiceBanAddRoot(LocalPlayer:FindFirstChild("PlayerGui"))
		pcall(function() voiceBanAddRoot(game:GetService("CoreGui")) end)
		pcall(function()
			if type(gethui) == "function" then voiceBanAddRoot(gethui()) end
		end)
	end

	-- Desconecta de verdade durante uma injeção externa. Só ignorar o
	-- evento ainda custa uma chamada Lua por instância criada, e o IY
	-- cria milhares. Desconectado, o custo é zero.
	voiceBanDetachAll = function()
		if not voiceBanAttached then return end
		voiceBanAttached = false
		for _, conn in ipairs(voiceBanConnections) do
			pcall(function() conn:Disconnect() end)
		end
		voiceBanConnections = {}
		voiceBanRoots = {}
		voiceBanQueue = {}
		voiceBanQueueIndex = 1
		voiceBanBudget = 0
	end

	task.spawn(function()
		while VoiceBanButton.Parent do
			-- Pausa durante carga externa/enxurrada e retoma depois.
			if CHOSEN_EXT_BUSY or CHOSEN_LIGHT_MODE or os.clock() < voiceBanPausedUntil then
				voiceBanDetachAll()
			elseif VOICE_BAN_UI_WATCH and not voiceBanAttached then
				voiceBanAttachAll()
			end

			local processed = 0
			while voiceBanQueueIndex <= #voiceBanQueue and processed < VOICE_BAN_BATCH do
				local obj = voiceBanQueue[voiceBanQueueIndex]
				voiceBanQueue[voiceBanQueueIndex] = nil
				voiceBanQueueIndex += 1
				processed += 1

				if obj and obj.Parent then
					pcall(voiceBanInspect, obj)
				end
			end

			if voiceBanQueueIndex > #voiceBanQueue then
				voiceBanQueue = {}
				voiceBanQueueIndex = 1
			end

			-- Depois de uma enxurrada (ou de uma injeção externa),
			-- uma única varredura lê o estado final da interface.
			-- Isso substitui as centenas de retentativas por objeto.
			if CHOSEN_VB_RESCAN_AT > 0
				and not CHOSEN_EXT_BUSY
				and os.clock() >= CHOSEN_VB_RESCAN_AT then
				CHOSEN_VB_RESCAN_AT = 0
				if voiceBanPhase ~= "active" then
					local found = voiceBanScanRobloxUI()
					if found then
						voiceBanNotice(found, "na interface")
					end
				end
			end

			task.wait(0.1)
		end
	end)

	if VOICE_BAN_UI_WATCH then
		voiceBanAttachAll()
		print("[CHOSEN VOZ] monitor de interface ativo")
	else
		print("[CHOSEN VOZ] monitor de interface desligado (VOICE_BAN_UI_WATCH = false)")
	end

	-- Religa o monitor caso o PlayerGui seja recriado (respawn).
	task.spawn(function()
		while VoiceBanButton.Parent do
			task.wait(5)
			if VOICE_BAN_UI_WATCH
				and not CHOSEN_EXT_BUSY
				and not CHOSEN_LIGHT_MODE then
				voiceBanAddRoot(LocalPlayer:FindFirstChild("PlayerGui"))
			end
		end
	end)

	-- Varredura única: se o ban já estava na tela ao injetar, pega o início.
	task.spawn(function()
		task.wait(2)
		if not VOICE_BAN_UI_WATCH then return end
		if CHOSEN_EXT_BUSY then return end
		if voiceBanPhase == "active" then return end
		local found = voiceBanScanRobloxUI()
		if found then
			voiceBanNotice(found, "na tela")
		end
	end)

	-- 3) API de voz: só serve como registro. Durante o ban ela continua
	-- dizendo "disponível", então não é usada para encerrar a contagem.
	do
		local okService, VoiceChatService = pcall(function()
			return game:GetService("VoiceChatService")
		end)
		if okService and VoiceChatService then
			task.spawn(function()
				local wasEnabled = nil
				while VoiceBanButton.Parent do
					local ok, enabled = pcall(function()
						return VoiceChatService:IsVoiceEnabledForUserIdAsync(LocalPlayer.UserId)
					end)
					if ok and type(enabled) == "boolean" and enabled ~= wasEnabled then
						print("[CHOSEN VOZ] voz " .. (enabled and "disponível" or "indisponível"))
						wasEnabled = enabled
					end
					task.wait(10)
				end
			end)
		end
	end
end
chosenInstallVoiceBan()

local StatsCard = Instance.new("Frame")
StatsCard.Size = UDim2.new(0, 112, 0, 94)
StatsCard.BackgroundColor3 = COLOR_CARD
StatsCard.BackgroundTransparency = 0.08
StatsCard.BorderSizePixel = 0
StatsCard.LayoutOrder = 0
StatsCard.Position = UDim2.new(1, -124, 0.5, -47)
StatsCard.Parent = WelcomeCard
corner(StatsCard, 10)
stroke(StatsCard, COLOR_BORDER, 1, 0.2)

local PingBox = Instance.new("Frame")
PingBox.Size = UDim2.new(1, -12, 0.5, -6)
PingBox.Position = UDim2.new(0, 6, 0, 4)
PingBox.BackgroundColor3 = COLOR_PANEL
PingBox.BackgroundTransparency = 0.25
PingBox.BorderSizePixel = 0
PingBox.Parent = StatsCard
corner(PingBox, 8)
stroke(PingBox, COLOR_BORDER, 1, 0.35)

local PingCaption = Instance.new("TextLabel")
PingCaption.Size = UDim2.new(1, -12, 0, 11)
PingCaption.Position = UDim2.new(0, 7, 0, 5)
PingCaption.BackgroundTransparency = 1
PingCaption.Text = "PING"
PingCaption.TextColor3 = COLOR_MUTED
PingCaption.Font = Enum.Font.FredokaOne
PingCaption.TextSize = 8
PingCaption.TextXAlignment = Enum.TextXAlignment.Left
PingCaption.Parent = PingBox

local PingLabel = Instance.new("TextLabel")
PingLabel.Size = UDim2.new(1, -12, 0, 18)
PingLabel.Position = UDim2.new(0, 7, 0, 17)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "..."
PingLabel.TextColor3 = COLOR_SUCCESS
PingLabel.Font = Enum.Font.FredokaOne
PingLabel.TextSize = 15
PingLabel.TextXAlignment = Enum.TextXAlignment.Left
PingLabel.Parent = PingBox

local FpsBox = Instance.new("Frame")
FpsBox.Size = UDim2.new(1, -12, 0.5, -6)
FpsBox.Position = UDim2.new(0, 6, 0.5, 2)
FpsBox.BackgroundColor3 = COLOR_PANEL
FpsBox.BackgroundTransparency = 0.25
FpsBox.BorderSizePixel = 0
FpsBox.Parent = StatsCard
corner(FpsBox, 8)
stroke(FpsBox, COLOR_BORDER, 1, 0.35)

local FpsCaption = Instance.new("TextLabel")
FpsCaption.Size = UDim2.new(1, -12, 0, 11)
FpsCaption.Position = UDim2.new(0, 7, 0, 5)
FpsCaption.BackgroundTransparency = 1
FpsCaption.Text = "FPS"
FpsCaption.TextColor3 = COLOR_MUTED
FpsCaption.Font = Enum.Font.FredokaOne
FpsCaption.TextSize = 8
FpsCaption.TextXAlignment = Enum.TextXAlignment.Left
FpsCaption.Parent = FpsBox

local FpsLabel = Instance.new("TextLabel")
FpsLabel.Size = UDim2.new(1, -12, 0, 18)
FpsLabel.Position = UDim2.new(0, 7, 0, 17)
FpsLabel.BackgroundTransparency = 1
FpsLabel.Text = "..."
FpsLabel.TextColor3 = COLOR_ACCENT
FpsLabel.Font = Enum.Font.FredokaOne
FpsLabel.TextSize = 15
FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
FpsLabel.Parent = FpsBox

local safeClock = (type(os) == "table" and type(os.clock) == "function" and os.clock)
	or (type(tick) == "function" and tick)
	or function() return 0 end
local frameCount, lastTime = 0, safeClock()

RunService.RenderStepped:Connect(function()
	-- Silêncio durante injeção externa (o frame é do IY/emotes).
	if CHOSEN_EXT_BUSY then return end
	frameCount += 1
	local now = safeClock()
	if now - lastTime >= 1 then
		FpsLabel.Text = tostring(frameCount)
		frameCount = 0
		lastTime = now
	end
end)

task.spawn(function()
	while task.wait(1) do
		pcall(function()
			local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			PingLabel.Text = math.floor(ping) .. " ms"
		end)
	end
end)

createSection(HomeTab, "Acesso rápido", "Seus comandos principais em um só lugar.", 4)
local HomeActions = createControlRow(HomeTab, 5)

-- Card agrupado: REJOIN + visibilidade dos cargos ocupam juntos metade da linha.
local HomeQuickCard = Instance.new("Frame")
HomeQuickCard.Name = "HomeQuickActionsCard"
HomeQuickCard.Size = UDim2.new(0.5, -8, 1, 0)
HomeQuickCard.BackgroundColor3 = COLOR_CARD
HomeQuickCard.BackgroundTransparency = 0.04
HomeQuickCard.BorderSizePixel = 0
HomeQuickCard.LayoutOrder = 1
HomeQuickCard.Parent = HomeActions
corner(HomeQuickCard, 8)
stroke(HomeQuickCard, COLOR_BORDER, 1, 0.25)

local HomeRejoinButton = createActionButton(HomeQuickCard, "🔁 REJOIN", 1)
HomeRejoinButton.Size = UDim2.new(0.5, -9, 1, -12)
HomeRejoinButton.Position = UDim2.new(0, 6, 0, 6)
HomeRejoinButton.TextSize = 11
HomeRejoinButton.Font = Enum.Font.LuckiestGuy
HomeRejoinButton.TextXAlignment = Enum.TextXAlignment.Center
HomeRejoinButton.MouseButton1Click:Connect(function()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
end)

local HomeTagsButton = createActionButton(HomeQuickCard, "👁  CARGOS", 2)
HomeTagsButton.Size = UDim2.new(0.5, -9, 1, -12)
HomeTagsButton.Position = UDim2.new(0.5, 3, 0, 6)
HomeTagsButton.TextSize = 10
HomeTagsButton.Font = Enum.Font.FredokaOne
HomeTagsButton.TextXAlignment = Enum.TextXAlignment.Center
HomeTagsButton.MouseButton1Click:Connect(function()
	local nowHidden = false
	if type(chosenToggleTagsVisibility) == "function" then
		nowHidden = chosenToggleTagsVisibility() == true
	end

	HomeTagsButton.Text = nowHidden
		and "👁  MOSTRAR"
		or "👁  OCULTAR"
end)

-- Botão de servidores: ocupa a outra metade da linha e abre a janela dedicada.
local OpenServersButton = createActionButton(HomeActions, "🌐  SERVIDORES", 2)
OpenServersButton.TextSize = 13
OpenServersButton.Font = Enum.Font.LuckiestGuy
OpenServersButton.TextXAlignment = Enum.TextXAlignment.Center

-- Janela interna no mesmo espaço das abas, sem alterar a navegação nem as chamadas da API.
local ServerWindow = Instance.new("Frame")
ServerWindow.Name = "ServerWindow"
ServerWindow.Size = UDim2.new(1, 0, 1, 0)
ServerWindow.Position = UDim2.new(0, 0, 0, 0)
ServerWindow.BackgroundColor3 = COLOR_PANEL
ServerWindow.BorderSizePixel = 0
ServerWindow.Visible = false
ServerWindow.ZIndex = 20
ServerWindow.Parent = ContentArea
corner(ServerWindow, 10)
stroke(ServerWindow, COLOR_BORDER2, 1, 0.12)

local ServerWindowHeader = Instance.new("Frame")
ServerWindowHeader.Size = UDim2.new(1, -20, 0, 46)
ServerWindowHeader.Position = UDim2.new(0, 10, 0, 8)
ServerWindowHeader.BackgroundColor3 = COLOR_CARD
ServerWindowHeader.BorderSizePixel = 0
ServerWindowHeader.ZIndex = 21
ServerWindowHeader.Parent = ServerWindow
corner(ServerWindowHeader, 10)
stroke(ServerWindowHeader, COLOR_BORDER, 1, 0.3)

local ServerWindowTitle = Instance.new("TextLabel")
ServerWindowTitle.Size = UDim2.new(1, -112, 1, 0)
ServerWindowTitle.Position = UDim2.new(0, 13, 0, 0)
ServerWindowTitle.BackgroundTransparency = 1
ServerWindowTitle.Text = "🌐  SERVIDORES DISPONÍVEIS"
ServerWindowTitle.TextColor3 = COLOR_TEXT
ServerWindowTitle.Font = Enum.Font.LuckiestGuy
ServerWindowTitle.TextSize = 14
ServerWindowTitle.TextXAlignment = Enum.TextXAlignment.Left
ServerWindowTitle.ZIndex = 22
ServerWindowTitle.Parent = ServerWindowHeader

local CloseServersButton = Instance.new("TextButton")
CloseServersButton.Size = UDim2.new(0, 34, 0, 30)
CloseServersButton.Position = UDim2.new(1, -42, 0.5, -15)
CloseServersButton.BackgroundColor3 = COLOR_CARD2
CloseServersButton.BorderSizePixel = 0
CloseServersButton.AutoButtonColor = false
CloseServersButton.Text = "✕"
CloseServersButton.TextColor3 = COLOR_TEXT
CloseServersButton.Font = Enum.Font.FredokaOne
CloseServersButton.TextSize = 14
CloseServersButton.ZIndex = 22
CloseServersButton.Parent = ServerWindowHeader
corner(CloseServersButton, 8)
stroke(CloseServersButton, COLOR_BORDER, 1, 0.3)

local function closeServerWindow()
	ServerWindow.Visible = false
end

OpenServersButton.MouseButton1Click:Connect(function()
	ServerWindow.Visible = true
end)

CloseServersButton.MouseButton1Click:Connect(closeServerWindow)

ContentFrames["Início"]:GetPropertyChangedSignal("Visible"):Connect(function()
	if not ContentFrames["Início"].Visible then
		ServerWindow.Visible = false
	end
end)

local ServerToolbar = Instance.new("Frame")
ServerToolbar.Name = "ServerToolbar"
ServerToolbar.Size = UDim2.new(1, -20, 0, 34)
ServerToolbar.Position = UDim2.new(0, 10, 0, 62)
ServerToolbar.BackgroundTransparency = 1
ServerToolbar.ZIndex = 21
ServerToolbar.Parent = ServerWindow

local RefreshServersButton = createActionButton(ServerToolbar, "↻  ATUALIZAR LISTA", 1)
RefreshServersButton.Size = UDim2.new(0, 142, 0, 30)
RefreshServersButton.Position = UDim2.new(0, 0, 0, 2)
RefreshServersButton.TextSize = 10
RefreshServersButton.Font = Enum.Font.FredokaOne
RefreshServersButton.TextXAlignment = Enum.TextXAlignment.Center

local ServerStatusLabel = Instance.new("TextLabel")
ServerStatusLabel.Size = UDim2.new(1, -154, 1, 0)
ServerStatusLabel.Position = UDim2.new(0, 154, 0, 0)
ServerStatusLabel.BackgroundTransparency = 1
ServerStatusLabel.Text = "Nenhuma lista carregada"
ServerStatusLabel.TextColor3 = COLOR_DIM
ServerStatusLabel.Font = Enum.Font.FredokaOne
ServerStatusLabel.TextSize = 10
ServerStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
ServerStatusLabel.ZIndex = 22
ServerStatusLabel.Parent = ServerToolbar

local ServerList = Instance.new("ScrollingFrame")
ServerList.Name = "ServerList"
ServerList.Size = UDim2.new(1, -20, 1, -112)
ServerList.Position = UDim2.new(0, 10, 0, 104)
ServerList.ZIndex = 21
ServerList.BackgroundColor3 = COLOR_CARD
ServerList.BackgroundTransparency = 0.08
ServerList.BorderSizePixel = 0
ServerList.ScrollBarThickness = 3
ServerList.CanvasSize = UDim2.new(0, 0, 0, 0)
ServerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ServerList.LayoutOrder = 1
ServerList.Parent = ServerWindow
corner(ServerList, 8)
stroke(ServerList, COLOR_BORDER, 1, 0.3)

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

-- Ícones de amigos que usam o painel, agrupados por servidor
-- (job_id). Vem da NOSSA API: o heartbeat de cada usuário envia
-- place_id/job_id e a rota /online devolve. Só aparecem amigos
-- que também estão com o painel aberto (limitação: Roblox não
-- libera a lista de occupants de servidores alheios).
local FriendsIconByServer = {}

local function loadServerFriends()
	FriendsIconByServer = {}

	if type(chosenGetOnlineSessions) ~= "function" then return end

	local ok, sessions = pcall(chosenGetOnlineSessions)
	if not ok or type(sessions) ~= "table" then return end

	for _, user in ipairs(sessions) do
		local uid = type(user) == "table"
			and tonumber(user.user_id) or nil
		if uid
			and tostring(uid) ~= tostring(LocalPlayer.UserId)
			and user.place_id ~= nil
			and tonumber(user.place_id) == game.PlaceId
			and type(user.job_id) == "string"
			and user.job_id ~= ""
			and pcall(function()
				return LocalPlayer:IsFriendsWith(uid)
			end) then
			FriendsIconByServer[user.job_id] =
				FriendsIconByServer[user.job_id] or {}
			table.insert(FriendsIconByServer[user.job_id], {
				id = uid,
				name = tostring(user.username or "")
			})
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
	row.BackgroundTransparency = 0.12
	row.BorderSizePixel = 0
	row.LayoutOrder = index
	row.Parent = ServerList
	corner(row, 8)
	local rowStroke = stroke(row, COLOR_BORDER, 1, 0.3)

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
	playersLabel.Text = string.format("👥 %d / %d jogadores", playing, maxPlayers)
	playersLabel.TextColor3 = COLOR_DIM
	playersLabel.Font = Enum.Font.FredokaOne
	playersLabel.TextSize = 10
	playersLabel.TextXAlignment = Enum.TextXAlignment.Left
	playersLabel.Parent = row

	local pingLabel = Instance.new("TextLabel")
	pingLabel.Size = UDim2.new(0, 70, 0, 16)
	pingLabel.Position = UDim2.new(0, 158, 0, 25)
	pingLabel.BackgroundTransparency = 1
	pingLabel.Text = string.format("📶 %s ms", ping and math.floor(ping) or "?")
	pingLabel.TextColor3 = COLOR_SUCCESS
	pingLabel.Font = Enum.Font.FredokaOne
	pingLabel.TextSize = 10
	pingLabel.TextXAlignment = Enum.TextXAlignment.Left
	pingLabel.Parent = row

	-- Ícones dos amigos (com painel) neste servidor: logo após
	-- o ping, até 3 avatares sobrepostos, +N quando passa disso.
	local friends = id and FriendsIconByServer[id] or nil
	if type(friends) == "table" and #friends > 0 then
		rowStroke.Color = COLOR_SUCCESS

		local shown = math.min(#friends, 3)
		for i = 1, shown do
			local av = Instance.new("ImageLabel")
			av.Size = UDim2.new(0, 22, 0, 22)
			av.Position = UDim2.new(0, 230 + (i - 1) * 15, 0.5, -11)
			av.BackgroundColor3 = COLOR_SIDE
			av.ZIndex = 2 + i
			av.Parent = row
			corner(av, 11)
			pcall(function()
				av.Image = Players:GetUserThumbnailAsync(
					friends[i].id,
					Enum.ThumbnailType.AvatarBust,
					Enum.ThumbnailSize.Size100x100
				)
			end)
		end

		if #friends > 3 then
			local extra = Instance.new("TextLabel")
			extra.Size = UDim2.new(0, 24, 0, 16)
			extra.Position = UDim2.new(0, 230 + shown * 15, 0.5, -8)
			extra.BackgroundTransparency = 1
			extra.Text = "+" .. (#friends - shown)
			extra.TextColor3 = COLOR_DIM
			extra.Font = Enum.Font.FredokaOne
			extra.TextSize = 9
			extra.TextXAlignment = Enum.TextXAlignment.Left
			extra.Parent = row
		end
	end

	local join = createActionButton(row, "🚪 ENTRAR", 1)
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
		-- Amigos por servidor primeiro (usa a mesma API já
		-- consultada pelas tags; em falha, lista segue normal).
		pcall(loadServerFriends)

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
TargetStatus.Font = Enum.Font.FredokaOne
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
createToggleButton(TargetRow1, "👁 Observar alvo", function(state)
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

local tpButton = createActionButton(TargetRow1, "🌀 Teleportar até o alvo", 2)
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
createToggleButton(TargetRow2, "👣 Seguir alvo", function(state)
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

createToggleButton(TargetRow2, "🪑 Headsit", function(state)
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
local copyButton = createActionButton(TargetRow3, "🛠 Copiar ferramentas", 1, true)
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

local clearTargetButton = createActionButton(TargetRow3, "🧹 Limpar alvo", 2, true)
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
	SearchFriendsBox.BackgroundTransparency = 0.1
	SearchFriendsBox.BorderSizePixel = 0
	SearchFriendsBox.PlaceholderText = "Buscar por nome ou @user"
	SearchFriendsBox.PlaceholderColor3 = COLOR_MUTED
	SearchFriendsBox.Text = ""
	SearchFriendsBox.TextColor3 = COLOR_TEXT
	SearchFriendsBox.Font = Enum.Font.FredokaOne
	SearchFriendsBox.TextSize = 12
	SearchFriendsBox.TextXAlignment = Enum.TextXAlignment.Left
	SearchFriendsBox.ClearTextOnFocus = false
	SearchFriendsBox.Parent = AmigosToolbar
	corner(SearchFriendsBox, 10)
	stroke(SearchFriendsBox, COLOR_BORDER, 1, 0.3)
	padding(SearchFriendsBox, 10, 8, 0, 0)

	local RefreshFriendsButton = createActionButton(AmigosToolbar, "🔄 ATUALIZAR", 2)
	local FriendsStatusLabel = Instance.new("TextLabel")
	FriendsStatusLabel.Name = "FriendsStatusLabel"
	FriendsStatusLabel.Size = UDim2.new(1, -4, 0, 16)
	FriendsStatusLabel.BackgroundTransparency = 1
	FriendsStatusLabel.Text = "Nenhuma busca feita ainda"
	FriendsStatusLabel.TextColor3 = COLOR_MUTED
	FriendsStatusLabel.Font = Enum.Font.FredokaOne
	FriendsStatusLabel.TextSize = 9
	FriendsStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	FriendsStatusLabel.LayoutOrder = 3
	FriendsStatusLabel.Parent = AmigosTab

	local FriendsList = Instance.new("ScrollingFrame")
	FriendsList.Name = "FriendsList"
	FriendsList.Size = UDim2.new(1, -4, 0, 300)
	FriendsList.BackgroundColor3 = COLOR_CARD
	FriendsList.BackgroundTransparency = 0.08
	FriendsList.BorderSizePixel = 0
	FriendsList.ScrollBarThickness = 3
	FriendsList.CanvasSize = UDim2.new(0, 0, 0, 0)
	FriendsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	FriendsList.LayoutOrder = 4
	FriendsList.Parent = AmigosTab
	corner(FriendsList, 8)
	stroke(FriendsList, COLOR_BORDER, 1, 0.3)

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
	local obsButtons = {}

	-- Destaque do botão OBS: fica verde enquanto observa aquele amigo e
	-- volta ao normal ao desativar. Atualiza somente ao clicar (sem loops).
	local function updateObsColors()
		for _, item in pairs(obsButtons) do
			pcall(function()
				local hum = item.player.Character and item.player.Character:FindFirstChildOfClass("Humanoid")
				local active = isSpectating and hum ~= nil and Camera.CameraSubject == hum
				tween(item.btn, {BackgroundColor3 = active and Color3.fromRGB(26, 86, 60) or COLOR_CARD2}, 0.12)
				local st = item.btn:FindFirstChildOfClass("UIStroke")
				if st then tween(st, {Color = active and COLOR_SUCCESS or COLOR_BORDER}, 0.12) end
			end)
		end
	end

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
		obsButtons = {}
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
		row.BackgroundTransparency = 0.12
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = FriendsList
		corner(row, 8)
		stroke(row, COLOR_BORDER, 1, 0.3)

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
		nameLabel.Font = Enum.Font.FredokaOne
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
		userLabel.Font = Enum.Font.FredokaOne
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
		onlineLabel.Font = Enum.Font.FredokaOne
		onlineLabel.TextSize = 9
		onlineLabel.TextXAlignment = Enum.TextXAlignment.Left
		onlineLabel.Parent = row

		local alvoBtn = createActionButton(row, "🎯 ALVO", 1)
		alvoBtn.Size = UDim2.new(0, 64, 0, 28)
		alvoBtn.Position = UDim2.new(1, -214, 0.5, -14)
		alvoBtn.TextSize = 10
		alvoBtn.MouseButton1Click:Connect(function()
			markFriendAsTarget(player, row)
		end)

		local obsBtn = createActionButton(row, "👁 OBS", 2)
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
			updateObsColors()
		end)
		-- Garante que o destaque verde sobrevive ao hover do botão
		obsBtn.MouseEnter:Connect(function()
			pcall(function()
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if isSpectating and hum and Camera.CameraSubject == hum then
					tween(obsBtn, {BackgroundColor3 = Color3.fromRGB(32, 96, 68)}, 0.12)
				end
			end)
		end)
		obsBtn.MouseLeave:Connect(function()
			pcall(function()
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if isSpectating and hum and Camera.CameraSubject == hum then
					tween(obsBtn, {BackgroundColor3 = Color3.fromRGB(26, 86, 60)}, 0.12)
					local st = obsBtn:FindFirstChildOfClass("UIStroke")
					if st then tween(st, {Color = COLOR_SUCCESS}, 0.12) end
				end
			end)
		end)
		table.insert(obsButtons, {btn = obsBtn, player = player})

		local tpBtn = createActionButton(row, "🌀 TP", 3)
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

-- ==========================================================
-- PERSISTÊNCIA DE ESTADO (vale para todas as abas)
-- Fica no escopo principal porque os blocos de aba são "do ... end"
-- e um "local" criado dentro de um deles não é visível no outro.
-- ==========================================================
local PERSIST_PATH = "7yd7/ChosenPanelConfig.json"
local PERSIST_STATE = {
	noclip = false,
	clickTp = false,
	antiAfk = false,
	flashback = false,
	impulse = false,
	animSpeed = false,
	antiInvis = true, -- padrão antigo: nasce ligado
}
local antiAfkEnabled = false
local antiAfkConnection = nil

-- Guarda as funções de arquivo ORIGINAIS. O Infinite Yield sobrescreve
-- os globais writefile/readfile/isfile quando carrega; capturadas uma
-- única vez aqui, a persistência continua funcionando depois dele.
local PERSIST_FS = {
	write = type(writefile) == "function" and writefile or nil,
	read = type(readfile) == "function" and readfile or nil,
	isfile = type(isfile) == "function" and isfile or nil,
	mkdir = type(makefolder) == "function" and makefolder or nil,
}

-- Rastreamento da injeção de scripts externos (IY / emotes).
-- Grava a etapa atual em 7yd7/ChosenInjectionTrace.txt. Se o cliente
-- fechar, o último registro mostra exatamente onde ele parou.
local function chosenTrace(stage)
	pcall(function()
		print("[CHOSEN EXT] etapa: " .. stage)
		if type(PERSIST_FS.write) ~= "function" then return end
		if type(PERSIST_FS.mkdir) == "function" then
			pcall(PERSIST_FS.mkdir, "7yd7")
		end
		local now = (type(os) == "table" and type(os.clock) == "function")
			and os.clock() or 0
		PERSIST_FS.write(
			"7yd7/ChosenInjectionTrace.txt",
			string.format("%.1f | %s", now, stage)
		)
	end)
end

local function persistWrite()
	pcall(function()
		if type(PERSIST_FS.write) ~= "function" then return end
		local http = game:GetService("HttpService")
		pcall(function()
			if type(PERSIST_FS.mkdir) == "function" then PERSIST_FS.mkdir("7yd7") end
		end)
		PERSIST_FS.write(PERSIST_PATH, http:JSONEncode(PERSIST_STATE))
	end)
end

local function persistRead()
	pcall(function()
		if type(PERSIST_FS.read) ~= "function"
			or type(PERSIST_FS.isfile) ~= "function" then
			return
		end
		if not PERSIST_FS.isfile(PERSIST_PATH) then return end
		local http = game:GetService("HttpService")
		local decoded = http:JSONDecode(PERSIST_FS.read(PERSIST_PATH))
		if type(decoded) ~= "table" then return end
		if type(decoded.noclip) == "boolean" then PERSIST_STATE.noclip = decoded.noclip end
		if type(decoded.clickTp) == "boolean" then PERSIST_STATE.clickTp = decoded.clickTp end
		if type(decoded.antiAfk) == "boolean" then PERSIST_STATE.antiAfk = decoded.antiAfk end
		if type(decoded.flashback) == "boolean" then PERSIST_STATE.flashback = decoded.flashback end
		if type(decoded.impulse) == "boolean" then PERSIST_STATE.impulse = decoded.impulse end
		if type(decoded.animSpeed) == "boolean" then PERSIST_STATE.animSpeed = decoded.animSpeed end
		if type(decoded.antiInvis) == "boolean" then PERSIST_STATE.antiInvis = decoded.antiInvis end
	end)
end

persistRead()

-- Jogo Tab (bloco autocontido: libera os registros locais ao fim)
do
-- Jogo Tab
createSection(GameTab, "Jogo", "Movimento, atalhos e utilidades.", 1)

-- Variáveis locais (inicialização)
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
	PERSIST_STATE.noclip = state
	persistWrite()
end, 1)
noclipSetState = setNoclipState
-- Reaplica o estado salvo no próprio botão (nasce desligado).
if PERSIST_STATE.noclip then
	noclip = true
	noclipHotkeyEnabled = true
	setNoclipState(true)
end

RunService.Stepped:Connect(function()
	if CHOSEN_EXT_BUSY then return end
	if noclip and LocalPlayer.Character then
		for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end
end)

local _, setClickTpState = createToggleButton(GameRow1, "Click TP  •  Ctrl + M1", function(state)
	clickTp = state
	PERSIST_STATE.clickTp = state
	persistWrite()
end, 2)
-- Reaplica o estado salvo no próprio botão (nasce desligado).
if PERSIST_STATE.clickTp then
	clickTp = true
	setClickTpState(true)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if clickTp and not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			and Mouse.Hit then
			LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
		end
	end
end)

-- Flashback em meia-linha, com Impulse ao lado
local GameRow2 = createControlRow(GameTab, 3)
local _, setFlashbackState = createToggleButton(GameRow2, "Flashback  •  Segure V", function(state)
	flashback = state
	if not state then history = {} isRewinding = false end
	PERSIST_STATE.flashback = state
	persistWrite()
end, 1)
if PERSIST_STATE.flashback then
	flashback = true
	setFlashbackState(true)
end

local _, setImpulseState = createToggleButton(GameRow2, "Impulse  •  Tecla M", function(state)
	impulseHotkeyEnabled = state
	if not state then
		if impulseIsImpulsing then
			restoreImpulse()
		else
			stopImpulseLoop()
		end
	end
	PERSIST_STATE.impulse = state
	persistWrite()
end, 2)
if PERSIST_STATE.impulse then
	impulseHotkeyEnabled = true
	setImpulseState(true)
end

-- Fly movido para a aba Jogador (mesma lógica/callback), com ajuste na mesma linha
createSection(PlayerTab, "Fly", "Ligue o voo e ajuste a velocidade na mesma linha.", 3)
createComboControl(PlayerTab, "✈️ Fly  •  Tecla F", 1, 1000, flySpeed, 4, function(state)
	flyHotkeyEnabled = state
	if not state and flying then stopFly() end
end, function(value)
	flySpeed = value
end)

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

-- Aba Jogador: seção Character — caixas de Walk/Jump com botões
-- APPLY (coluna esquerda) e cards Respawn/Checkpoint com RUN
-- (coluna direita). O spawn da aba Diversos veio pra cá.
local okPlayerMove, errPlayerMove = pcall(function()
	local MOVE_walkSpeed = 16
	local MOVE_jumpPower = 50
	local MOVE_walkOn = false
	local MOVE_jumpOn = false
	local savedSpawnCFrame = nil

	-- Valores ORIGINAIS do jogo, capturados só na primeira vez que
	-- você clica em APPLY. 16 é apenas o padrão do Roblox: muitos
	-- jogos usam outro valor (ex.: 24, 32) e o painel não pode
	-- sobrescrever isso sem você pedir.
	local MOVE_savedWalk = nil
	local MOVE_savedJump = nil
	local MOVE_savedUseJumpPower = nil

	local function MOVE_capture(humanoid)
		if MOVE_savedWalk == nil then
			MOVE_savedWalk = humanoid.WalkSpeed
		end
		if MOVE_savedJump == nil then
			MOVE_savedUseJumpPower = humanoid.UseJumpPower
			MOVE_savedJump = humanoid.UseJumpPower
				and humanoid.JumpPower
				or humanoid.JumpHeight
		end
	end

	local function MOVE_apply()
		-- Nada foi aplicado: não toca no personagem. Era aqui que a
		-- velocidade do jogo virava 16 só por injetar o painel.
		if not MOVE_walkOn and not MOVE_jumpOn then return end

		local char = LocalPlayer.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		pcall(function()
			MOVE_capture(humanoid)
			if MOVE_walkOn then
				humanoid.WalkSpeed = MOVE_walkSpeed
			end
			if MOVE_jumpOn then
				humanoid.UseJumpPower = true
				humanoid.JumpPower = MOVE_jumpPower
			end
		end)
	end

	createSection(PlayerTab, "Character", "Velocidade, pulo, respawn e checkpoint.", 1)

	local CharacterGrid = Instance.new("Frame")
	CharacterGrid.Size = UDim2.new(1, -4, 0, 168)
	CharacterGrid.BackgroundTransparency = 1
	CharacterGrid.BorderSizePixel = 0
	CharacterGrid.LayoutOrder = 2
	CharacterGrid.Parent = PlayerTab

	-- Coluna esquerda: card com Walk Speed e Jump Power
	local MoveCard = Instance.new("Frame")
	MoveCard.Size = UDim2.new(0.48, -4, 0, 128)
	MoveCard.BackgroundColor3 = COLOR_CARD
	MoveCard.BackgroundTransparency = 0.08
	MoveCard.BorderSizePixel = 0
	MoveCard.Parent = CharacterGrid
	corner(MoveCard, 8)
	stroke(MoveCard, COLOR_BORDER, 1, 0.3)

	local function moveCaption(text, y)
		local cap = Instance.new("TextLabel")
		cap.Size = UDim2.new(1, -24, 0, 14)
		cap.Position = UDim2.new(0, 12, 0, y)
		cap.BackgroundTransparency = 1
		cap.Text = text
		cap.TextColor3 = COLOR_MUTED
		cap.Font = Enum.Font.FredokaOne
		cap.TextSize = 9
		cap.TextXAlignment = Enum.TextXAlignment.Left
		cap.Parent = MoveCard
	end

	local function moveBox(y)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -24, 0, 36)
		box.Position = UDim2.new(0, 12, 0, y)
		box.BackgroundColor3 = COLOR_SIDE
		box.BackgroundTransparency = 0.15
		box.Text = ""
		box.PlaceholderColor3 = COLOR_MUTED
		box.TextColor3 = COLOR_TEXT
		box.Font = Enum.Font.FredokaOne
		box.TextSize = 14
		box.TextXAlignment = Enum.TextXAlignment.Center
		box.TextYAlignment = Enum.TextYAlignment.Center
		box.ClearTextOnFocus = false
		box.Parent = MoveCard
		corner(box, 10)
		stroke(box, COLOR_ACCENT, 1, 0.55)
		return box
	end

	moveCaption("WALK SPEED", 10)
	local WalkBox = moveBox(26)
	WalkBox.Text = "16"
	moveCaption("JUMP POWER", 68)
	local JumpBox = moveBox(84)
	JumpBox.Text = "50"

	-- RESET: devolve WalkSpeed/JumpPower exatamente como estavam
	-- antes do primeiro APPLY e limpa os valores capturados. Depois
	-- disso o painel não mexe mais no personagem sozinho.
	local function MOVE_reset()
		local char = LocalPlayer.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		MOVE_walkOn = false
		MOVE_jumpOn = false
		if humanoid then
			pcall(function()
				if MOVE_savedWalk ~= nil then
					humanoid.WalkSpeed = MOVE_savedWalk
				end
				if MOVE_savedJump ~= nil then
					if MOVE_savedUseJumpPower then
						humanoid.UseJumpPower = true
						humanoid.JumpPower = MOVE_savedJump
					else
						humanoid.UseJumpPower = false
						humanoid.JumpHeight = MOVE_savedJump
					end
				end
			end)
			WalkBox.Text = tostring(math.floor(humanoid.WalkSpeed + 0.5))
			if humanoid.UseJumpPower then
				JumpBox.Text = tostring(math.floor(humanoid.JumpPower + 0.5))
			else
				JumpBox.Text = tostring(math.floor(humanoid.JumpHeight + 0.5))
			end
		end
		MOVE_savedWalk = nil
		MOVE_savedJump = nil
		MOVE_savedUseJumpPower = nil
	end

	-- Botões APPLY (abaixo do card, alinhados à coluna esquerda)
	local function applyButton(text, x, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.24, -5, 0, 32)
		btn.Position = UDim2.new(x, 0, 0, 136)
		btn.BackgroundColor3 = COLOR_ACCENT
		btn.BackgroundTransparency = 0.85
		btn.Text = text
		btn.TextColor3 = COLOR_ACCENT
		btn.Font = Enum.Font.FredokaOne
		btn.TextSize = 10
		btn.Parent = CharacterGrid
		corner(btn, 10)
		stroke(btn, COLOR_ACCENT, 1, 0.25)
		btn.MouseButton1Click:Connect(callback)
		return btn
	end

	local ApplyWalk = applyButton("APPLY WALK", 0, function()
		local value = tonumber(WalkBox.Text)
		if value and value >= 0 and value <= 500 then
			MOVE_walkSpeed = math.floor(value + 0.5)
			MOVE_walkOn = true
			MOVE_apply()
			ApplyWalk.Text = "✓ APLICADO"
		else
			ApplyWalk.Text = "✗ NÚMERO?"
		end
		task.delay(1, function()
			if ApplyWalk and ApplyWalk.Parent then ApplyWalk.Text = "APPLY WALK" end
		end)
	end)

	local ApplyJump = applyButton("APPLY JUMP", 0.24, function()
		local value = tonumber(JumpBox.Text)
		if value and value >= 0 and value <= 500 then
			MOVE_jumpPower = math.floor(value + 0.5)
			MOVE_jumpOn = true
			MOVE_apply()
			ApplyJump.Text = "✓ APLICADO"
		else
			ApplyJump.Text = "✗ NÚMERO?"
		end
		task.delay(1, function()
			if ApplyJump and ApplyJump.Parent then ApplyJump.Text = "APPLY JUMP" end
		end)
	end)

	-- Coluna direita: card com Respawn (executar) e Checkpoint
	-- (salvar o ponto de spawn — antigo "Definir Spawn")
	local ActionCard = Instance.new("Frame")
	ActionCard.Position = UDim2.new(0.52, 0, 0, 0)
	ActionCard.Size = UDim2.new(0.48, -4, 1, 0)
	ActionCard.BackgroundColor3 = COLOR_CARD
	ActionCard.BackgroundTransparency = 0.08
	ActionCard.BorderSizePixel = 0
	ActionCard.Parent = CharacterGrid
	corner(ActionCard, 8)
	stroke(ActionCard, COLOR_ACCENT, 1, 0.45)

	local function actionRow(y, title, subtitleText, dotColor)
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 6, 0, 6)
		dot.Position = UDim2.new(0, 14, 0, y + 11)
		dot.BackgroundColor3 = dotColor
		dot.BorderSizePixel = 0
		dot.Parent = ActionCard
		corner(dot, 3)

		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -170, 0, 16)
		t.Position = UDim2.new(0, 28, 0, y + 3)
		t.BackgroundTransparency = 1
		t.Text = title
		t.TextColor3 = COLOR_TEXT
		t.Font = Enum.Font.FredokaOne
		t.TextSize = 12
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Parent = ActionCard

		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.new(1, -170, 0, 12)
		sub.Position = UDim2.new(0, 28, 0, y + 19)
		sub.BackgroundTransparency = 1
		sub.Text = subtitleText
		sub.TextColor3 = COLOR_DIM
		sub.Font = Enum.Font.FredokaOne
		sub.TextSize = 9
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.TextTruncate = Enum.TextTruncate.AtEnd
		sub.Parent = ActionCard

		local run = Instance.new("TextButton")
		run.Size = UDim2.new(0, 56, 0, 26)
		run.Position = UDim2.new(1, -68, 0, y + 7)
		run.BackgroundColor3 = COLOR_ACCENT
		run.BackgroundTransparency = 0.85
		run.Text = "RUN"
		run.TextColor3 = COLOR_ACCENT
		run.Font = Enum.Font.FredokaOne
		run.TextSize = 10
		run.Parent = ActionCard
		corner(run, 13)
		stroke(run, COLOR_ACCENT, 1, 0.25)

		return sub, run
	end

	local RespawnSub, RespawnRun = actionRow(
		0, "Respawn", "Clique para executar", Color3.fromRGB(255, 90, 90))
	RespawnRun.MouseButton1Click:Connect(function()
		local char = LocalPlayer.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			pcall(function() humanoid.Health = 0 end)
		end
	end)

	local ActionDivider = Instance.new("Frame")
	ActionDivider.Size = UDim2.new(1, -24, 0, 1)
	ActionDivider.Position = UDim2.new(0, 12, 0, 84)
	ActionDivider.BackgroundColor3 = COLOR_BORDER
	ActionDivider.BackgroundTransparency = 0.45
	ActionDivider.BorderSizePixel = 0
	ActionDivider.Parent = ActionCard

	local CheckpointSub, CheckpointRun = actionRow(
		84, "Checkpoint", "Clique para salvar", COLOR_ACCENT)
	CheckpointRun.MouseButton1Click:Connect(function()
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			savedSpawnCFrame = root.CFrame
			CheckpointSub.Text = "Checkpoint salvo ✓"
			CheckpointSub.TextColor3 = COLOR_SUCCESS
		end
	end)

	-- Mini lixeira: remove o checkpoint salvo (antigo "Remover Spawn")
	local ClearSpawn = Instance.new("TextButton")
	ClearSpawn.Size = UDim2.new(0, 26, 0, 26)
	ClearSpawn.Position = UDim2.new(1, -100, 0, 84 + 7)
	ClearSpawn.BackgroundTransparency = 1
	ClearSpawn.Text = "🗑"
	ClearSpawn.TextColor3 = COLOR_MUTED
	ClearSpawn.Font = Enum.Font.FredokaOne
	ClearSpawn.TextSize = 12
	ClearSpawn.Parent = ActionCard
	ClearSpawn.MouseButton1Click:Connect(function()
		savedSpawnCFrame = nil
		CheckpointSub.Text = "Clique para salvar"
		CheckpointSub.TextColor3 = COLOR_DIM
	end)

	-- Reset: devolve speed e pulo ao que o jogo usava.
	local ResetSub, ResetRun = actionRow(
		124, "Resetar Speed/Jump", "Volta ao normal do jogo", Color3.fromRGB(120, 190, 255))
	ResetRun.MouseButton1Click:Connect(function()
		MOVE_reset()
		ResetSub.Text = "Restaurado ✓"
		ResetSub.TextColor3 = COLOR_SUCCESS
		task.delay(2, function()
			if ResetSub and ResetSub.Parent then
				ResetSub.Text = "Volta ao normal do jogo"
				ResetSub.TextColor3 = COLOR_DIM
			end
		end)
	end)

	-- Respawn: reaplica Walk/Jump aplicados e devolve ao checkpoint
	LocalPlayer.CharacterAdded:Connect(function(newCharacter)
		task.spawn(function()
			task.wait(0.4)
			MOVE_apply()
		end)
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
end)

if not okPlayerMove then
	warn("[Jogador] erro ao iniciar movimento: " .. tostring(errPlayerMove))
end

local GameRow3 = createControlRow(GameTab, 4)
local _, setAnimSpeedState = createToggleButton(GameRow3, "Anim Speed  •  Q|E", function(state)
	animationSpeedEnabled = state
	animationSpeed = 1
	PERSIST_STATE.animSpeed = state
	persistWrite()
end, 1)
if PERSIST_STATE.animSpeed then
	animationSpeedEnabled = true
	animationSpeed = 1
	setAnimSpeedState(true)
end

-- Jerkoff (animação FE clássica — funciona em R6 e R15)
local okJerkoff, errJerkoff = pcall(function()
	local JO_ANIM_R6 = "rbxassetid://72042024"
	local JO_ANIM_R15 = "rbxassetid://698251653"

	local jerkoffFeatureOn = false
	local jerkoffEnabled = false
	local jerkoffSession = 0
	local jerkoffTrack = nil

	local function JO_stop()
		jerkoffEnabled = false
		jerkoffSession += 1
		if jerkoffTrack then
			pcall(function() jerkoffTrack:Stop(0.1) end)
			jerkoffTrack = nil
		end
	end

	local function JO_start()
		if jerkoffEnabled then return end
		jerkoffEnabled = true
		jerkoffSession += 1
		local mySession = jerkoffSession
		task.spawn(function()
			local myTrack = nil
			local myTrackHumanoid = nil
			while mySession == jerkoffSession do
				local char = LocalPlayer.Character
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				if not humanoid or humanoid.Health <= 0 then
					if myTrack then
						pcall(function() myTrack:Stop(0.1) end)
						myTrack = nil
						myTrackHumanoid = nil
					end
					task.wait(0.4)
				else
					local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
					if myTrackHumanoid ~= humanoid then
						if myTrack then
							pcall(function() myTrack:Stop(0.1) end)
						end
						myTrack = nil
						myTrackHumanoid = nil
						local okT, loaded = pcall(function()
							local anim = Instance.new("Animation")
							anim.AnimationId = isR15 and JO_ANIM_R15 or JO_ANIM_R6
							local animator = humanoid:FindFirstChildOfClass("Animator")
							if animator then
								return animator:LoadAnimation(anim)
							end
							return humanoid:LoadAnimation(anim)
						end)
						if okT and loaded then
							loaded.Priority = Enum.AnimationPriority.Action4
							myTrack = loaded
							myTrackHumanoid = humanoid
							jerkoffTrack = loaded
						end
					end
					local track = myTrack
					if not track then
						task.wait(0.4)
					else
						local speed = isR15 and 0.7 or 0.65
						local limit = isR15 and 0.7 or 0.65
						local okP = pcall(function()
							track:Play(0.1)
							track:AdjustSpeed(speed)
							track.TimePosition = 0.6
						end)
						if okP then
							local guard = 0
							while mySession == jerkoffSession
								and track.IsPlaying
								and track.TimePosition < limit
								and guard < 60 do
								task.wait(0.05)
								guard += 1
							end
						end
						pcall(function() track:Stop(0.1) end)
						if jerkoffTrack == track then
							jerkoffTrack = nil
						end
					end
				end
			end
			if myTrack then
				pcall(function() myTrack:Stop(0.1) end)
			end
		end)
	end

	createToggleButton(GameRow3, "Jerkoff  •  X", function(state)
		jerkoffFeatureOn = state
		if state then JO_start() else JO_stop() end
	end, 2)

	-- X apenas alterna a animação (começa/para), sem mudar o estado do botão
	-- e só funciona enquanto o botão estiver ligado.
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.X
			and not UserInputService:GetFocusedTextBox() then
			if not jerkoffFeatureOn then return end
			if jerkoffEnabled then
				JO_stop()
			else
				JO_start()
			end
		end
	end)

	LocalPlayer.CharacterAdded:Connect(function()
		jerkoffTrack = nil
	end)
end)

if not okJerkoff then
	warn("[Jogo] erro ao iniciar Jerkoff: " .. tostring(errJerkoff))
end

-- Linha compartilhada da aba Jogo: Bang e Anti-Invisível lado a lado
local GameRow4 = createControlRow(GameTab, 5)

-- Bang (portado dos BangScript e BangScript_Atras, R6 recomendado)
-- Botão desligado: nada acontece. Botão ligado: Z ativa o bang
-- FRONTAL (na frente do rosto do jogador mais próximo) e C ativa
-- o bang ATRÁS (atrás das costas). A mesma tecla de novo para;
-- trocar de tecla muda de posição.
local okBang, errBang = pcall(function()
	local bangFeatureOn = false
	local bangActive = false
	local bangThrust = 0
	local bangDirection = 1
	local bangTargetHRP = nil
	-- "front" = Z (na frente do rosto) • "back" = C (atrás das costas)
	local bangMode = "front"
	local bangChar, bangHRP

	local BANG_OFFSET_BACK = 1.3
	local BANG_SPEED = 1

	local function BANG_setupCharacter(character)
		bangChar = character
		bangHRP = character:WaitForChild("HumanoidRootPart", 8)
		if bangHRP then
			pcall(function() bangHRP.Anchored = false end)
		end
	end

	-- Congela/libera as animações do personagem (os outros veem o
	-- boneco estático enquanto o bang está em andamento)
	local function BANG_freeze(frozen)
		if not bangChar then return end
		local humanoid = bangChar:FindFirstChildOfClass("Humanoid")
		local animate = bangChar:FindFirstChild("Animate")
		if animate then
			pcall(function() animate.Disabled = frozen end)
		end
		if not humanoid then return end
		for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
			if frozen then
				pcall(function() track:AdjustSpeed(0) end)
			else
				pcall(function() track:Stop(0) end)
			end
		end
	end

	local function BANG_stop()
		bangActive = false
		bangThrust = 0
		bangDirection = 1
		bangTargetHRP = nil
		BANG_freeze(false)
	end

	local function BANG_start()
		if bangActive or not bangHRP then return end

		-- Jogador mais próximo da sessão vira o alvo
		local closest, dist = nil, math.huge
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character
				and p.Character:FindFirstChild("HumanoidRootPart") then
				local d = (bangHRP.Position
					- p.Character.HumanoidRootPart.Position).Magnitude
				if d < dist then
					dist = d
					closest = p
				end
			end
		end

		local targetHRP = closest and closest.Character
			and closest.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			bangTargetHRP = targetHRP
			bangActive = true
			bangThrust = 0
			bangDirection = 1
			BANG_freeze(true)
		end
	end

	BANG_setupCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

	LocalPlayer.CharacterAdded:Connect(function(newChar)
		BANG_setupCharacter(newChar)
		-- Respawn encerra o bang em andamento (o botão continua ligado)
		bangActive = false
		bangThrust = 0
		bangDirection = 1
		bangTargetHRP = nil
		if bangFeatureOn then
			task.delay(0.5, function()
				BANG_freeze(false)
			end)
		end
	end)

	-- SEM Anchored: âncora não replica ao servidor. O movimento usa
	-- interpolação suave + velocidade zerada por frame (o cliente tem
	-- network ownership do próprio personagem — replica normal).
	RunService.RenderStepped:Connect(function(dt)
		if bangActive and bangHRP and bangTargetHRP then
			-- independente de FPS (mobile tem FPS variável)
			bangThrust += 0.06 * BANG_SPEED * bangDirection * (dt * 60)

			if bangThrust > 0.6 then bangDirection = -1 end
			if bangThrust < -0.6 then bangDirection = 1 end

			local goal
			if bangMode == "back" then
				-- POSIÇÃO ATRÁS: Z positivo (atrás das costas do alvo)
				goal = bangTargetHRP.CFrame
					* CFrame.new(0, 0, BANG_OFFSET_BACK + bangThrust)
					* CFrame.Angles(0, 0, 0)
			else
				-- POSIÇÃO FRONTAL: na frente do rosto do alvo
				goal = bangTargetHRP.CFrame
					* CFrame.new(0, 2.5, -(BANG_OFFSET_BACK + bangThrust))
					* CFrame.Angles(0, math.rad(180), 0)
			end
			bangHRP.CFrame = bangHRP.CFrame:Lerp(
				goal, math.clamp(dt * 20, 0, 1))

			-- trava física sem ancorar: mata o flicker da gravidade
			bangHRP.AssemblyLinearVelocity = Vector3.zero
			bangHRP.AssemblyAngularVelocity = Vector3.zero

			-- mantém qualquer track que comece depois também congelado
			local humanoid = bangChar and bangChar:FindFirstChildOfClass("Humanoid")
			if humanoid then
				for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
					if track.Speed ~= 0 then
						pcall(function() track:AdjustSpeed(0) end)
					end
				end
			end
		end
	end)

	createToggleButton(GameRow4, "Bang  •  Z frente | C atrás", function(state)
		bangFeatureOn = state
		-- Ligar/desligar o botão nunca ativa o bang por si só:
		-- Z ativa a versão frontal, C a versão atrás.
		BANG_stop()
	end, 1)

	-- Z = bang frontal • C = bang atrás (só com o botão da aba ligado).
	-- A mesma tecla com o bang ativo para; a outra tecla troca de
	-- posição no alvo mais próximo.
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not bangFeatureOn then return end
		if UserInputService:GetFocusedTextBox() then return end

		local mode = nil
		if input.KeyCode == Enum.KeyCode.Z then
			mode = "front"
		elseif input.KeyCode == Enum.KeyCode.C then
			mode = "back"
		end
		if not mode then return end

		if bangActive and bangMode == mode then
			BANG_stop()
		else
			BANG_stop()
			bangMode = mode
			BANG_start()
		end
	end)
end)

if not okBang then
	warn("[Jogo] erro ao iniciar Bang: " .. tostring(errBang))
end

-- =========================================================
-- ANTI-INVISÍVEL (ao lado do Bang): revela personagens
-- TOTALMENTE invisíveis. Contorno roxo + contador de studs
-- no pé, apenas em quem está invisível.
-- =========================================================
local okAntiInvis, errAntiInvis = pcall(function()
	local AI_enabled = false
	-- Revelação com VALOR-ASSINATURA: a gente nunca escreve 0 nem
	-- 1 — escreve 0.03125 (2^-5, exato em float32 e visualmente
	-- IDÊNTICO a visível). Esse valor é a nossa assinatura: se uma
	-- parte revelada mostra um valor visível DIFERENTE dele, só
	-- pode ter sido o JOGO escrevendo — ou seja, a pessoa voltou
	-- ao normal e a marca cai na hora. Desligar restaura o
	-- original apenas nas partes que o jogo NÃO já tornou visíveis.
	local AI_PROBE = 0.03125
	local AI_revealed = {}   -- [part] = {plr, origT, origLTM, conns}
	local AI_highlights = {} -- [player] = Highlight (contorno + preenchimento)
	local AI_labels = {}     -- [player] = {gui, text} contador de studs
	local AI_marked = {}     -- [player] = {char} invisibilidade total confirmada

	local AI_OUTLINE = Color3.fromRGB(170, 85, 255)
	local AI_INVISIBLE = 0.99 -- transparência acima disso conta como invisível

	-- Parte "do corpo": fora o root (sempre invisível), fora
	-- acessórios (Handle invisível é normal em roupas) e fora
	-- ferramentas/itens (Tool)
	local function AI_isCorePart(part)
		if part.Name == "HumanoidRootPart" or part.Name == "Handle" then
			return false
		end
		local node = part.Parent
		while node and node ~= workspace do
			if node:IsA("Accessory") or node:IsA("Tool") then
				return false
			end
			node = node.Parent
		end
		return true
	end

	-- Re-escreve a assinatura SÓ quando o jogo escondeu a parte
	-- (chamado pelos sinais abaixo — zero custo por frame).
	local function AI_forcePart(part, entry)
		if AI_revealed[part] ~= entry then return end
		local t = part.Transparency
		if t >= AI_INVISIBLE then
			part.Transparency = AI_PROBE
		end
		local ltm = part.LocalTransparencyModifier
		if ltm >= AI_INVISIBLE then
			part.LocalTransparencyModifier = AI_PROBE
		end
	end

	local function AI_disconnect(entry)
		if entry.conns then
			for _, c in ipairs(entry.conns) do
				pcall(function() c:Disconnect() end)
			end
			entry.conns = nil
		end
	end

	-- Revela uma parte escondida: guarda o original UMA VEZ,
	-- escreve o valor-assinatura (nunca 0 — senão o servidor
	-- escreveria 0 por cima sem a gente conseguir distinguir) e
	-- fica ESCUTANDO a parte: se o jogo re-esconder, o sinal
	-- devolve a assinatura na hora (sem varredura por frame).
	local function AI_revealPart(part, plr)
		local entry = AI_revealed[part]
		if not entry then
			entry = { plr = plr }
			AI_revealed[part] = entry
			pcall(function()
				entry.conns = {
					part:GetPropertyChangedSignal("Transparency"):Connect(function()
						AI_forcePart(part, entry)
					end),
					part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
						AI_forcePart(part, entry)
					end),
				}
			end)
		end
		pcall(function()
			local t = part.Transparency
			if t >= AI_INVISIBLE then
				if entry.origT == nil then
					entry.origT = t
				end
				part.Transparency = AI_PROBE
			end
			local ltm = part.LocalTransparencyModifier
			if ltm >= AI_INVISIBLE then
				if entry.origLTM == nil then
					entry.origLTM = ltm
				end
				part.LocalTransparencyModifier = AI_PROBE
			end
		end)
	end

	local function AI_removeVisual(plr)
		local hl = AI_highlights[plr]
		if hl then pcall(function() hl:Destroy() end) end
		AI_highlights[plr] = nil
		local lb = AI_labels[plr]
		if lb and lb.gui then pcall(function() lb.gui:Destroy() end) end
		AI_labels[plr] = nil
	end

	-- Devolve o original de uma parte APENAS se ela ainda está
	-- escondida ou carrega a nossa assinatura — quem o JOGO já
	-- tornou visível fica exatamente como está (é isso que
	-- impede de esconder de novo quem voltou ao normal).
	local function AI_restorePart(part, entry)
		pcall(function()
			local t = part.Transparency
			if entry.origT ~= nil
				and (t >= AI_INVISIBLE or t == AI_PROBE) then
				part.Transparency = entry.origT
			end
			local ltm = part.LocalTransparencyModifier
			if entry.origLTM ~= nil
				and (ltm >= AI_INVISIBLE or ltm == AI_PROBE) then
				part.LocalTransparencyModifier = entry.origLTM
			end
		end)
	end

	-- Largar um player. restore=true (desligar o recurso) devolve
	-- os originais; restore=false (voltou ao normal / saiu /
	-- respawn) confia nos valores que o jogo deixou.
	local function AI_release(plr, restore)
		for part, entry in pairs(AI_revealed) do
			if entry.plr == plr then
				if restore then
					AI_restorePart(part, entry)
				end
				AI_disconnect(entry)
				AI_revealed[part] = nil
			end
		end
		AI_removeVisual(plr)
		AI_marked[plr] = nil
	end

	-- Desligar: larga todo mundo devolvendo os originais
	local function AI_clear()
		for _, plr in ipairs(Players:GetPlayers()) do
			AI_release(plr, true)
		end
		-- sobras de players que já saíram do server
		for part, entry in pairs(AI_revealed) do
			AI_restorePart(part, entry)
			AI_disconnect(entry)
		end
		table.clear(AI_revealed)
		table.clear(AI_marked)
		for _, hl in pairs(AI_highlights) do
			pcall(function() hl:Destroy() end)
		end
		table.clear(AI_highlights)
		for _, lb in pairs(AI_labels) do
			if lb and lb.gui then pcall(function() lb.gui:Destroy() end) end
		end
		table.clear(AI_labels)
	end

	-- Contorno + preenchimento só no invisível
	local function AI_ensureHighlight(plr, char)
		local hl = AI_highlights[plr]
		if hl and hl.Parent ~= char then
			pcall(function() hl:Destroy() end)
			hl = nil
		end
		if not hl then
			hl = Instance.new("Highlight")
			hl.FillColor = AI_OUTLINE
			hl.FillTransparency = 0.7
			hl.OutlineColor = AI_OUTLINE
			hl.OutlineTransparency = 0
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = char
			AI_highlights[plr] = hl
		end
	end

	-- Contador de studs ancorado NO PÉ do invisível
	local function AI_ensureLabel(plr, root)
		local lb = AI_labels[plr]
		if lb and (not lb.gui.Parent or lb.gui.Adornee ~= root) then
			pcall(function() lb.gui:Destroy() end)
			lb = nil
		end
		if not lb then
			local gui = Instance.new("BillboardGui")
			gui.Name = "AI_Studs"
			gui.Adornee = root
			gui.Size = UDim2.new(0, 90, 0, 18)
			gui.StudsOffset = Vector3.new(0, -2.8, 0) -- no pé
			gui.AlwaysOnTop = true
			gui.MaxDistance = 600

			local text = Instance.new("TextLabel")
			text.Size = UDim2.new(1, 0, 1, 0)
			text.BackgroundTransparency = 1
			text.Font = Enum.Font.FredokaOne
			text.TextSize = 12
			text.TextColor3 = AI_OUTLINE
			text.TextStrokeTransparency = 0.35
			text.Text = "..."
			text.Parent = gui

			gui.Parent = root
			lb = { gui = gui, text = text }
			AI_labels[plr] = lb
		end
		return lb
	end

	-- Partes do corpo com CAMINHO RÁPIDO: em rigs normais o corpo
	-- é filho DIRETO do modelo — GetChildren é ~20 itens (barato)
	-- e já exclui acessórios/ferramentas naturalmente. Só cai no
	-- GetDescendants (caro, em jogo pesado) se o rig for fora do
	-- padrão (corpo dentro de pasta), o que é raro.
	local AI_partBuf = {}
	local function AI_collectCoreParts(char)
		local list = AI_partBuf
		table.clear(list)
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart")
				and part.Name ~= "HumanoidRootPart"
				and part.Name ~= "Handle" then
				list[#list + 1] = part
			end
		end
		if #list >= 3 then
			return list
		end
		table.clear(list)
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and AI_isCorePart(part) then
				list[#list + 1] = part
			end
		end
		return list
	end

	local AI_tickCount = 0

	local function AI_tick()
		local myRoot = LocalPlayer.Character
			and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

		AI_tickCount += 1
		-- A cada ~2s: limpeza de partes destruídas/trocadas e
		-- re-varredura de quem está marcado (caso o jogo recrie
		-- partes no meio do personagem).
		local deepScan = (AI_tickCount % 8) == 0

		-- Uma passada só em todas as partes reveladas: quem teve
		-- valor VISÍVEL diferente da assinatura devolvida pelo
		-- jogo entra aqui (evita o custo O(jogadores × partes)).
		local returnedFor = {}
		for part, entry in pairs(AI_revealed) do
			local t = part.Transparency
			if t < AI_INVISIBLE and t ~= AI_PROBE then
				returnedFor[entry.plr] = true
			end
		end

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer then
				local char = plr.Character
				local ev = AI_marked[plr]

				if not plr.Parent or not char or not char.Parent then
					-- Saiu / sem personagem no momento
					if ev or AI_highlights[plr] or AI_labels[plr] then
						AI_release(plr, false)
					end
				else
					if ev and ev.char ~= char then
						-- respawn/morph: solta e re-avalia
						AI_release(plr, false)
						ev = nil
					end

					if ev then
						if returnedFor[plr] then
							-- O JOGO devolveu a visibilidade: solta
							-- SEM restaurar — os valores dele mandam
							AI_release(plr, false)
						else
							-- Segue invisível pro jogo: mantém o
							-- contorno e atualiza o contador. O
							-- re-esconder já é tratado pelo sinal de
							-- cada parte (sem varredura por frame).
							AI_ensureHighlight(plr, char)
							local root = char:FindFirstChild("HumanoidRootPart")
							if root then
								local lb = AI_ensureLabel(plr, root)
								local newText = "? studs"
								if myRoot then
									local dist = (myRoot.Position
										- root.Position).Magnitude
									newText = string.format(
										"%d studs", math.floor(dist + 0.5))
								end
								if lb.text.Text ~= newText then
									lb.text.Text = newText
								end
							end

							if deepScan then
								for part, entry in pairs(AI_revealed) do
									if entry.plr == plr
										and (not part.Parent
											or not part:IsDescendantOf(char)) then
										AI_disconnect(entry)
										AI_revealed[part] = nil
									end
								end
								for _, part in ipairs(AI_collectCoreParts(char)) do
									if part.LocalTransparencyModifier >= AI_INVISIBLE
										or part.Transparency >= AI_INVISIBLE then
										AI_revealPart(part, plr)
									end
								end
							end
						end
					else
						-- Não marcado: varre SÓ ele em busca de
						-- invisibilidade total (caminho rápido por
						-- filhos diretos — custo baixo até em jogo
						-- pesado como Mushyo)
						local coreParts = AI_collectCoreParts(char)
						local totalCore = #coreParts
						local hiddenCore = 0
						local hiddenParts
						for _, part in ipairs(coreParts) do
							if part.LocalTransparencyModifier >= AI_INVISIBLE
								or part.Transparency >= AI_INVISIBLE then
								hiddenCore += 1
								if not hiddenParts then
									hiddenParts = {}
								end
								hiddenParts[part] = true
							end
						end

						if totalCore >= 3 and hiddenCore >= totalCore then
							AI_marked[plr] = { char = char }
							for part in pairs(hiddenParts) do
								AI_revealPart(part, plr)
							end
							AI_ensureHighlight(plr, char)
							local root = char:FindFirstChild("HumanoidRootPart")
							if root then
								local lb = AI_ensureLabel(plr, root)
								if myRoot then
									local dist = (myRoot.Position
										- root.Position).Magnitude
									lb.text.Text = string.format(
										"%d studs", math.floor(dist + 0.5))
								else
									lb.text.Text = "? studs"
								end
							end
						end
					end
				end
			end
		end
	end

	-- O re-esconder de cada parte é tratado pelo SINAL da própria
	-- parte (AI_forcePart) — não existe mais varredura por frame,
	-- o que elimina o lag em jogos pesados.

	-- Varredura contínua: pega quem ficou invisível depois de ligar
	-- (spawn, morph, etc). 0.3s é rápido o bastante e, com o
	-- caminho rápido por filhos diretos, barato até em jogo pesado.
	task.spawn(function()
		while true do
			task.wait(0.3)
			if AI_enabled and not CHOSEN_EXT_BUSY and not CHOSEN_LIGHT_MODE then
				pcall(AI_tick)
			end
		end
	end)

	local AIToggleCard, AISetState = createToggleButton(GameRow4, "👁 Anti-Invisível", function(state)
		AI_enabled = state
		if not state then
			AI_clear()
		end
		PERSIST_STATE.antiInvis = state
		persistWrite()
	end, 2)

	-- Restaura o estado salvo (padrão: ligado, igual ao comportamento antigo)
	AI_enabled = PERSIST_STATE.antiInvis
	AISetState(AI_enabled)

	-- Toast de inicialização (mesmo estilo do Aviso): entra
	-- deslizando no canto, fica 10s, tem o X pra fechar e um
	-- botão que DESATIVA a função na hora.
	local function AIShowStartupToast()
		local old = ScreenGui:FindFirstChild("ChosenAIStartupToast")
		if old then
			old:Destroy()
		end

		local toast = Instance.new("Frame")
		toast.Name = "ChosenAIStartupToast"
		toast.AnchorPoint = Vector2.new(1, 0)
		toast.Position = UDim2.new(1, 340, 0, 18) -- fora da tela; entra deslizando
		toast.Size = UDim2.new(0, 316, 0, 104)
		toast.BackgroundColor3 = COLOR_PANEL
		toast.BackgroundTransparency = 0.03
		toast.BorderSizePixel = 0
		toast.ZIndex = 60
		toast.Parent = ScreenGui
		corner(toast, 10)
		stroke(toast, AI_OUTLINE, 1.2, 0.35)

		-- Barra lateral de destaque (roxo)
		local toastBar = Instance.new("Frame")
		toastBar.Size = UDim2.new(0, 4, 1, 0)
		toastBar.BackgroundColor3 = AI_OUTLINE
		toastBar.BorderSizePixel = 0
		toastBar.ZIndex = 61
		toastBar.Parent = toast
		corner(toastBar, 2)

		local toastTitle = Instance.new("TextLabel")
		toastTitle.Size = UDim2.new(1, -64, 0, 16)
		toastTitle.Position = UDim2.new(0, 18, 0, 10)
		toastTitle.BackgroundTransparency = 1
		toastTitle.Text = "👁  ANTI-INVISÍVEL"
		toastTitle.TextColor3 = AI_OUTLINE
		toastTitle.Font = Enum.Font.LuckiestGuy
		toastTitle.TextSize = 11
		toastTitle.TextXAlignment = Enum.TextXAlignment.Left
		toastTitle.ZIndex = 60
		toastTitle.Parent = toast

		local toastText = Instance.new("TextLabel")
		toastText.Size = UDim2.new(1, -36, 0, 30)
		toastText.Position = UDim2.new(0, 18, 0, 30)
		toastText.BackgroundTransparency = 1
		toastText.Text = "A função está ATIVA — revelando jogadores invisíveis do servidor."
		toastText.TextColor3 = COLOR_TEXT
		toastText.Font = Enum.Font.FredokaOne
		toastText.TextSize = 12
		toastText.TextXAlignment = Enum.TextXAlignment.Left
		toastText.TextYAlignment = Enum.TextYAlignment.Top
		toastText.TextWrapped = true
		toastText.ZIndex = 60
		toastText.Parent = toast

		-- Botão que desativa a função direto do toast
		local toastOff = Instance.new("TextButton")
		toastOff.Size = UDim2.new(0, 148, 0, 26)
		toastOff.Position = UDim2.new(0, 18, 1, -34)
		toastOff.BackgroundColor3 = COLOR_CARD2
		toastOff.BackgroundTransparency = 0.15
		toastOff.Text = "Desativar"
		toastOff.TextColor3 = COLOR_TEXT
		toastOff.Font = Enum.Font.FredokaOne
		toastOff.TextSize = 13
		toastOff.ZIndex = 61
		toastOff.Parent = toast
		corner(toastOff, 13)

		local toastClose = Instance.new("TextButton")
		toastClose.Size = UDim2.new(0, 24, 0, 24)
		toastClose.Position = UDim2.new(1, -32, 0, 9)
		toastClose.BackgroundColor3 = COLOR_CARD2
		toastClose.BackgroundTransparency = 0.2
		toastClose.Text = "X"
		toastClose.TextColor3 = COLOR_TEXT
		toastClose.Font = Enum.Font.FredokaOne
		toastClose.TextSize = 12
		toastClose.ZIndex = 61
		toastClose.Parent = toast
		corner(toastClose, 8)

		-- Barra de contagem: o tempo restante (10s) esvazia da direita
		local toastTimer = Instance.new("Frame")
		toastTimer.AnchorPoint = Vector2.new(1, 0.5)
		toastTimer.Position = UDim2.new(1, -8, 1, -7)
		toastTimer.Size = UDim2.new(1, -16, 0, 3)
		toastTimer.BackgroundColor3 = AI_OUTLINE
		toastTimer.BackgroundTransparency = 0.3
		toastTimer.BorderSizePixel = 0
		toastTimer.ZIndex = 61
		toastTimer.Parent = toast
		corner(toastTimer, 2)

		tween(toast, {Position = UDim2.new(1, -16, 0, 18)}, 0.35)
		tween(toastTimer, {Size = UDim2.new(0, 0, 0, 3)}, 10)

		local function dismiss()
			if not toast.Parent then return end
			tween(toast, {Position = UDim2.new(1, 340, 0, 18)}, 0.35)
			task.delay(0.4, function()
				pcall(function() toast:Destroy() end)
			end)
		end

		toastOff.MouseButton1Click:Connect(function()
			AISetState(false) -- desliga a função (estado + visual do botão)
			dismiss()
		end)

		toastClose.MouseButton1Click:Connect(dismiss)

		task.delay(10, dismiss)
	end

	-- Aviso no canto só aparece quando a função já está ativa.
	if AI_enabled then
		AIShowStartupToast()
	end
end)

if not okAntiInvis then
	warn("[Jogo] erro ao iniciar Anti-Invisível: " .. tostring(errAntiInvis))
end

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
end -- fim do bloco Jogo

--------------------------------------------------------------------------------
-- ABA ESP INTEGRADA (bloco autocontido: libera registros ao fim)
--------------------------------------------------------------------------------
do
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

-- Declaradas antes do toggle para que o botão possa criar/remover
-- os desenhos sob demanda (nada é criado com o ESP desligado).
local createESP, removeESP

local Roles = {}

local function UpdateRoles()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local role = ""

			if p.Character then
				if p.Character:FindFirstChild("Knife") or p.Character:FindFirstChild("Combat") then
					role = "Murderer"
				elseif p.Character:FindFirstChild("Gun") or p.Character:FindFirstChild("Revolver") then
					role = "Sheriff"
				end
			end

			if role == "" and p:FindFirstChild("Backpack") then
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

createToggleButton(ESPTab, "👁 ESP  •  wallhack", function(state)
	roleEspEnabled = state
	if state then
		-- Cria os desenhos só agora (economiza memória com o ESP off).
		for _, player in ipairs(Players:GetPlayers()) do
			if createESP then createESP(player) end
		end
	else
		-- Remove de verdade: zero Drawing em uso enquanto desligado.
		for _, player in ipairs(Players:GetPlayers()) do
			if removeESP then removeESP(player) end
		end
	end
end, 2)

createSection(ESPTab, "AIMBOT", "Ligue a mira e arraste o raio do FOV na mesma linha.", 4)

createComboControl(ESPTab, "🎯 Aimbot  •  Segure M2", 50, 500, fovRadius, 5, function(state)
	aimbotEnabled = state
end, function(value)
	fovRadius = value
end)

local AimbotRow1 = createControlRow(ESPTab, 6)
createToggleButton(AimbotRow1, "⭕ Exibir FOV", function(state) showFov = state end, 1)
createToggleButton(AimbotRow1, "🌈 FOV RGB", function(state) fovRainbow = state end, 2)

createSliderControl(ESPTab, "🎚 Suavização Aimbot", 0, 10, smoothingFactor * 10, 7, function(value)
	smoothingFactor = value / 10
end)

createSection(ESPTab, "PARTE ALVO", "Selecionar parte do corpo para mira", 8)
local PartRow = createControlRow(ESPTab, 9)
local partButton = createActionButton(PartRow, "🦴 Parte: " .. targetPart, 1)
partButton.MouseButton1Click:Connect(function()
	local parts = {"Head", "HumanoidRootPart", "Torso"}
	local idx = 1
	for i, p in ipairs(parts) do
		if p == targetPart then idx = i break end
	end
	idx = idx % #parts + 1
	targetPart = parts[idx]
	partButton.Text = "🦴 Parte: " .. targetPart
end)

local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Thickness = 2
fovCircle.Radius = fovRadius
fovCircle.Transparency = 1
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

createESP = function(player)
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

removeESP = function(player)
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

-- Nada é criado com o ESP desligado: zero Drawing em uso.
Players.PlayerAdded:Connect(function(player)
	if roleEspEnabled then
		createESP(player)
	end
end)
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
	-- FOV só é tocado quando o aimbot está ligado.
	if aimbotEnabled and showFov then
		fovCircle.Visible = true
		fovCircle.Radius = fovRadius
		fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

		if fovRainbow then
			hue = (hue + 0.005) % 1
			fovCircle.Color = Color3.fromHSV(hue, 1, 1)
		else
			fovCircle.Color = COLOR_ACCENT
		end
	elseif fovCircle.Visible then
		fovCircle.Visible = false
	end

	-- Sem ESP ligado não há nada para atualizar. Antes, UpdateRoles()
	-- rodava todo frame mesmo com a função desligada.
	if not roleEspEnabled then return end

	UpdateRoles()

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
end -- fim do bloco ESP

--------------------------------------------------------------------------------
-- Diversos Tab (bloco autocontido: libera registros ao fim)
--------------------------------------------------------------------------------
do
createSection(MiscTab, "Extras", "Ferramentas adicionais e efeitos visuais.", 1)
local MiscRow1 = createControlRow(MiscTab, 2)
local _, setAntiAfkState = createToggleButton(MiscRow1, "💤 Anti-AFK", function(state)
	antiAfkEnabled = state
	PERSIST_STATE.antiAfk = state
	persistWrite()
	if antiAfkConnection then antiAfkConnection:Disconnect() antiAfkConnection = nil end
	if state then
		antiAfkConnection = LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	end
end, 1)

-- Reaplica o estado salvo no próprio botão (nasce desligado).
if PERSIST_STATE.antiAfk then
	antiAfkEnabled = true
	setAntiAfkState(true)
end

-- ==========================================================
-- SCRIPTS EXTERNOS (Infinite Yield / Free Emotes)
-- Carregados fora do thread do clique, com checagem de download
-- e trava curta contra duplo clique. Sem isso, dois cliques
-- abrem duas copias do mesmo script e pesam no executor.
-- ==========================================================

local chosenExternalLast = {}

-- ==========================================================
-- JANELA DE CONFIRMAÇÃO (injeção externa)
-- Antes de esconder o painel para carregar o IY/emotes, explica o
-- que vai acontecer. Mesmo estilo do Aviso (toast), mas centralizada
-- e com botão de confirmar — acaba o susto de "o painel sumiu".
-- ==========================================================
local chosenExtDialog = nil

local function chosenConfirmInject(title, message, onConfirm)
	if chosenExtDialog then
		pcall(function() chosenExtDialog:Destroy() end)
		chosenExtDialog = nil
	end

	-- Fundo escurecido: cobre o painel e segura os cliques.
	local overlay = Instance.new("Frame")
	overlay.Name = "ChosenInjectConfirm"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Active = true
	overlay.ZIndex = 90
	overlay.Parent = ScreenGui
	chosenExtDialog = overlay

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.Size = UDim2.new(0, 420, 0, 198)
	card.BackgroundColor3 = COLOR_PANEL
	card.BackgroundTransparency = 0.02
	card.BorderSizePixel = 0
	card.Active = true
	card.ZIndex = 91
	card.Parent = overlay
	corner(card, 12)
	stroke(card, COLOR_ACCENT, 1.4, 0.2)

	-- Faixa de destaque no topo (mesma linguagem do toast de Aviso)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -24, 0, 3)
	bar.Position = UDim2.new(0, 12, 0, 8)
	bar.BackgroundColor3 = COLOR_ACCENT
	bar.BorderSizePixel = 0
	bar.ZIndex = 92
	bar.Parent = card
	corner(bar, 2)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -40, 0, 20)
	titleLabel.Position = UDim2.new(0, 20, 0, 22)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = COLOR_TEXT
	titleLabel.Font = Enum.Font.LuckiestGuy
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 92
	titleLabel.Parent = card

	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -40, 0, 76)
	msg.Position = UDim2.new(0, 20, 0, 50)
	msg.BackgroundTransparency = 1
	msg.Text = message
	msg.TextColor3 = COLOR_DIM
	msg.Font = Enum.Font.FredokaOne
	msg.TextSize = 12
	msg.TextXAlignment = Enum.TextXAlignment.Left
	msg.TextYAlignment = Enum.TextYAlignment.Top
	msg.TextWrapped = true
	msg.ZIndex = 92
	msg.Parent = card

	local function close()
		pcall(function() overlay:Destroy() end)
		if chosenExtDialog == overlay then
			chosenExtDialog = nil
		end
	end

	local cancel = Instance.new("TextButton")
	cancel.Size = UDim2.new(0.5, -26, 0, 38)
	cancel.Position = UDim2.new(0, 20, 1, -54)
	cancel.BackgroundColor3 = COLOR_CARD2
	cancel.BackgroundTransparency = 0.15
	cancel.AutoButtonColor = false
	cancel.Text = "CANCELAR"
	cancel.TextColor3 = COLOR_MUTED
	cancel.Font = Enum.Font.FredokaOne
	cancel.TextSize = 11
	cancel.ZIndex = 92
	cancel.Parent = card
	corner(cancel, 8)
	stroke(cancel, COLOR_BORDER, 1, 0.35)

	local go = Instance.new("TextButton")
	go.Size = UDim2.new(0.5, -26, 0, 38)
	go.Position = UDim2.new(0.5, 6, 1, -54)
	go.BackgroundColor3 = COLOR_SUCCESS
	go.BackgroundTransparency = 0.08
	go.AutoButtonColor = false
	go.Text = "INJETAR AGORA"
	go.TextColor3 = Color3.fromRGB(8, 30, 18)
	go.Font = Enum.Font.FredokaOne
	go.TextSize = 11
	go.ZIndex = 92
	go.Parent = card
	corner(go, 8)
	stroke(go, COLOR_SUCCESS, 1, 0.45)

	cancel.MouseEnter:Connect(function()
		tween(cancel, { BackgroundColor3 = Color3.fromRGB(56, 102, 158) }, 0.12)
	end)
	cancel.MouseLeave:Connect(function()
		tween(cancel, { BackgroundColor3 = COLOR_CARD2 }, 0.12)
	end)
	go.MouseEnter:Connect(function()
		tween(go, { BackgroundColor3 = Color3.fromRGB(120, 245, 170) }, 0.12)
	end)
	go.MouseLeave:Connect(function()
		tween(go, { BackgroundColor3 = COLOR_SUCCESS }, 0.12)
	end)

	cancel.MouseButton1Click:Connect(close)

	local busy = false
	go.MouseButton1Click:Connect(function()
		if busy then return end
		busy = true
		close()
		-- Só depois que a janela sai da tela a injeção começa.
		task.defer(onConfirm)
	end)
end

local chosenExternalActive = false

local function chosenRunExternal(key, url, label)
	local now = os.clock()

	-- Uma única injeção externa por vez, mesmo se forem botões diferentes.
	if chosenExternalActive or CHOSEN_EXT_BUSY then
		warn("[CHOSEN EXT] " .. label .. ": já existe uma carga externa em andamento.")
		return
	end

	if chosenExternalLast[key] and (now - chosenExternalLast[key]) < 6 then
		warn("[CHOSEN EXT] " .. label .. ": aguarde alguns segundos (carregando).")
		return
	end

	chosenExternalLast[key] = now
	chosenExternalActive = true

	task.spawn(function()
		local panelWasEnabled = nil
		local panelStateCaptured = false
		local finished = false
		local executionReturned = false

		-- Restaura o painel e libera a trava em qualquer falha anterior
		-- à execução. A função é idempotente para evitar restaurações duplicadas.
		local function restorePanel()
			if panelStateCaptured then
				pcall(function()
					if ScreenGui and ScreenGui.Parent then
						ScreenGui.Enabled = panelWasEnabled
					end
				end)
			end
		end

		local function abortBeforeRun(reason)
			if finished then return end
			finished = true
			restorePanel()
			CHOSEN_EXT_BUSY = false
			chosenExternalActive = false
			chosenExternalLast[key] = nil
			CHOSEN_VB_RESCAN_AT = os.clock() + 1
			chosenTrace(label .. ": " .. reason)
			warn("[CHOSEN EXT] " .. label .. ": " .. reason)
		end

		-- PRIMEIRO desativa o painel e pausa os workers; só depois baixa
		-- ou compila o código externo. Não destrói o ScreenGui.
		CHOSEN_EXT_BUSY = true
		local okPanel, panelErr = pcall(function()
			panelWasEnabled = ScreenGui.Enabled
			panelStateCaptured = true
			ScreenGui.Enabled = false
		end)
		if not okPanel then
			abortBeforeRun("não foi possível desativar o painel: " .. tostring(panelErr))
			return
		end

		chosenTrace(label .. ": painel desativado; iniciando download")
		task.wait(0.35)
		pcall(function() collectgarbage("collect") end)

		local okFetch, source = pcall(function()
			return game:HttpGet(url)
		end)
		if not okFetch or type(source) ~= "string" or #source < 8 then
			abortBeforeRun("falha ao baixar o script.")
			return
		end
		chosenTrace(label .. ": baixado (" .. tostring(#source) .. " bytes)")

		-- Impede que uma página de erro HTML seja compilada como Luau.
		local head = string.lower(source:sub(1, 80))
		if head:find("<!doctype", 1, true) or head:find("<html", 1, true) then
			abortBeforeRun("o link devolveu uma página HTML, não um script.")
			return
		end

		local loader = loadstring or load
		if type(loader) ~= "function" then
			abortBeforeRun("executor sem suporte a loadstring/load.")
			return
		end

		task.wait(0.2)
		pcall(function() collectgarbage("collect") end)

		local okCompile, chunk = pcall(loader, source)
		source = nil
		if not okCompile or type(chunk) ~= "function" then
			abortBeforeRun("script inválido ou bloqueado na compilação.")
			return
		end
		chosenTrace(label .. ": compilado; iniciando execução")

		-- Mantém o mesmo ambiente global que o carregador anterior utilizava.
		pcall(function()
			if type(setfenv) == "function" and type(getgenv) == "function" then
				setfenv(chunk, getgenv())
			end
		end)

		-- Se o código externo não retornar, o painel será restaurado após
		-- 150 segundos. Isso não cancela o código externo já iniciado.
		task.spawn(function()
			local elapsed = 0
			while not executionReturned and elapsed < 150 do
				task.wait(0.5)
				elapsed += 0.5
			end
			if not executionReturned then
				restorePanel()
				-- Mantém os workers pausados enquanto o chunk ainda estiver ativo.
				chosenTrace(label .. ": tempo limite; painel restaurado")
				warn("[CHOSEN EXT] " .. label .. ": excedeu 150s. O painel foi restaurado, mas o script externo pode continuar executando.")
			end
		end)

		local okRun, err = pcall(chunk)
		executionReturned = true
		restorePanel()
		chosenTrace(okRun and (label .. ": script retornou")
			or (label .. ": ERRO -> " .. tostring(err)))
		pcall(function() collectgarbage("collect") end)

		-- Dá tempo para a interface externa terminar de se estabilizar.
		-- O painel já pode voltar, mas os workers do CHOSEN HUB ficam pausados.
		if not finished then
			task.wait(8)
			finished = true
			CHOSEN_EXT_BUSY = false
			CHOSEN_VB_RESCAN_AT = os.clock() + 1
			chosenExternalActive = false
		end

		if not okRun then
			chosenExternalLast[key] = nil
			warn("[CHOSEN EXT] " .. label .. ": erro ao executar -> " .. tostring(err))
			return
		end

		print("[CHOSEN EXT] " .. label .. " carregado.")
		if type(chosenToastBridge) == "function" then
			pcall(chosenToastBridge, label .. " carregado com sucesso.", "CHOSEN HUB")
		end
	end)
end

local infinityButton = createActionButton(MiscRow1, "📜 Infinite Yield", 2)
infinityButton.MouseButton1Click:Connect(function()
	chosenConfirmInject(
		"📜  INFINITE YIELD",
		"O painel vai fechar por alguns segundos enquanto o Infinite Yield é carregado. Ele volta sozinho logo depois — nada do que você ligou é perdido.",
		function()
			chosenRunExternal("iy",
				"https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
				"Infinite Yield")
		end
	)
end)

local MiscRow2 = createControlRow(MiscTab, 3)
local emoteButton = createActionButton(MiscRow2, "💃 Free emotes", 1)
emoteButton.MouseButton1Click:Connect(function()
	chosenConfirmInject(
		"💃  FREE EMOTES",
		"O painel vai fechar por alguns segundos enquanto o script de emotes é carregado. Ele volta sozinho logo depois — nada do que você ligou é perdido.",
		function()
			chosenRunExternal("emotes",
				"https://rawscripts.net/raw/Universal-Script-7yd7-I-Emote-Script-48024",
				"Free Emotes")
		end
	)
end)

local rejoinButton = createActionButton(MiscRow2, "🔄 Rejoin", 2)
rejoinButton.MouseButton1Click:Connect(function()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
end)

-- Shader (Tokyowami)
-- Credits to Instance Serializer for helping me convert the Tokyowami shrine whatever thing to luau
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
		ColorShift_Bottom = Lighting.ColorShift_Bottom,
		ColorShift_Top = Lighting.ColorShift_Top,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		ClockTime = Lighting.ClockTime,
		FogColor = Lighting.FogColor,
		FogEnd = Lighting.FogEnd,
		FogStart = Lighting.FogStart,
		ExposureCompensation = Lighting.ExposureCompensation,
		ShadowSoftness = Lighting.ShadowSoftness,
		Ambient = Lighting.Ambient
	}
end

local function restoreLighting()
	if not shaderLightingBackup then return end
	for property, value in pairs(shaderLightingBackup) do
		pcall(function() Lighting[property] = value end)
	end
	shaderLightingBackup = nil
end

local function addShaderObject(obj)
	table.insert(shadersObj, obj)
	return obj
end

local function applyTokyowamiShader()
	backupLighting()
	destroyShaderObjects()

	local Bloom = Instance.new("BloomEffect")
	Bloom.Intensity = 0.1
	Bloom.Threshold = 0
	Bloom.Size = 100

	local Tropic = Instance.new("Sky")
	Tropic.Name = "Tropic"
	Tropic.SkyboxUp = "http://www.roblox.com/asset/?id=169210149"
	Tropic.SkyboxLf = "http://www.roblox.com/asset/?id=169210133"
	Tropic.SkyboxBk = "http://www.roblox.com/asset/?id=169210090"
	Tropic.SkyboxFt = "http://www.roblox.com/asset/?id=169210121"
	Tropic.StarCount = 100
	Tropic.SkyboxDn = "http://www.roblox.com/asset/?id=169210108"
	Tropic.SkyboxRt = "http://www.roblox.com/asset/?id=169210143"
	Tropic.Parent = Bloom

	local Sky = Instance.new("Sky")
	Sky.SkyboxUp = "http://www.roblox.com/asset/?id=196263782"
	Sky.SkyboxLf = "http://www.roblox.com/asset/?id=196263721"
	Sky.SkyboxBk = "http://www.roblox.com/asset/?id=196263721"
	Sky.SkyboxFt = "http://www.roblox.com/asset/?id=196263721"
	Sky.CelestialBodiesShown = false
	Sky.SkyboxDn = "http://www.roblox.com/asset/?id=196263643"
	Sky.SkyboxRt = "http://www.roblox.com/asset/?id=196263721"
	Sky.Parent = Bloom

	addShaderObject(Bloom)
	Bloom.Parent = Lighting

	local Bloom = Instance.new("BloomEffect")
	Bloom.Enabled = false
	Bloom.Intensity = 0.35
	Bloom.Threshold = 0.2
	Bloom.Size = 56

	local Tropic = Instance.new("Sky")
	Tropic.Name = "Tropic"
	Tropic.SkyboxUp = "http://www.roblox.com/asset/?id=169210149"
	Tropic.SkyboxLf = "http://www.roblox.com/asset/?id=169210133"
	Tropic.SkyboxBk = "http://www.roblox.com/asset/?id=169210090"
	Tropic.SkyboxFt = "http://www.roblox.com/asset/?id=169210121"
	Tropic.StarCount = 100
	Tropic.SkyboxDn = "http://www.roblox.com/asset/?id=169210108"
	Tropic.SkyboxRt = "http://www.roblox.com/asset/?id=169210143"
	Tropic.Parent = Bloom

	local Sky = Instance.new("Sky")
	Sky.SkyboxUp = "http://www.roblox.com/asset/?id=196263782"
	Sky.SkyboxLf = "http://www.roblox.com/asset/?id=196263721"
	Sky.SkyboxBk = "http://www.roblox.com/asset/?id=196263721"
	Sky.SkyboxFt = "http://www.roblox.com/asset/?id=196263721"
	Sky.CelestialBodiesShown = false
	Sky.SkyboxDn = "http://www.roblox.com/asset/?id=196263643"
	Sky.SkyboxRt = "http://www.roblox.com/asset/?id=196263721"
	Sky.Parent = Bloom

	addShaderObject(Bloom)
	Bloom.Parent = Lighting

	local Blur = Instance.new("BlurEffect")
	Blur.Size = 2
	addShaderObject(Blur)
	Blur.Parent = Lighting

	local Efecto = Instance.new("BlurEffect")
	Efecto.Name = "Efecto"
	Efecto.Enabled = false
	Efecto.Size = 2
	addShaderObject(Efecto)
	Efecto.Parent = Lighting

	local Inaritaisha = Instance.new("ColorCorrectionEffect")
	Inaritaisha.Name = "Inari taisha"
	Inaritaisha.Saturation = 0.05
	Inaritaisha.TintColor = Color3.fromRGB(255, 224, 219)
	addShaderObject(Inaritaisha)
	Inaritaisha.Parent = Lighting

	local Normal = Instance.new("ColorCorrectionEffect")
	Normal.Name = "Normal"
	Normal.Enabled = false
	Normal.Saturation = -0.2
	Normal.TintColor = Color3.fromRGB(255, 232, 215)
	addShaderObject(Normal)
	Normal.Parent = Lighting

	local SunRays = Instance.new("SunRaysEffect")
	SunRays.Intensity = 0.05
	addShaderObject(SunRays)
	SunRays.Parent = Lighting

	local Sunset = Instance.new("Sky")
	Sunset.Name = "Sunset"
	Sunset.SkyboxUp = "rbxassetid://323493360"
	Sunset.SkyboxLf = "rbxassetid://323494252"
	Sunset.SkyboxBk = "rbxassetid://323494035"
	Sunset.SkyboxFt = "rbxassetid://323494130"
	Sunset.SkyboxDn = "rbxassetid://323494368"
	Sunset.SunAngularSize = 14
	Sunset.SkyboxRt = "rbxassetid://323494067"
	addShaderObject(Sunset)
	Sunset.Parent = Lighting

	local Takayama = Instance.new("ColorCorrectionEffect")
	Takayama.Name = "Takayama"
	Takayama.Enabled = false
	Takayama.Saturation = -0.3
	Takayama.Contrast = 0.1
	Takayama.TintColor = Color3.fromRGB(235, 214, 204)
	addShaderObject(Takayama)
	Takayama.Parent = Lighting

	pcall(function()
		Lighting.Brightness = 2.14
		Lighting.ColorShift_Bottom = Color3.fromRGB(11, 0, 20)
		Lighting.ColorShift_Top = Color3.fromRGB(240, 127, 14)
		Lighting.OutdoorAmbient = Color3.fromRGB(34, 0, 49)
		Lighting.ClockTime = 6.7
		Lighting.FogColor = Color3.fromRGB(94, 76, 106)
		Lighting.FogEnd = 1000
		Lighting.FogStart = 0
		Lighting.ExposureCompensation = 0.24
		Lighting.ShadowSoftness = 0
		Lighting.Ambient = Color3.fromRGB(59, 33, 27)
	end)
end

local function disableShader()
	destroyShaderObjects()
	restoreLighting()
end

createSection(MiscTab, "Shaders", "shader visual com efeitos de pós-processamento", 4)
local MiscShaderRow1 = createControlRow(MiscTab, 5)
createToggleButton(MiscShaderRow1, "🎨 Shader  •  Tokyowami", function(state)
	if state then applyTokyowamiShader() else disableShader() end
end, 1)
createActionButton(MiscShaderRow1, "🚫 Desativar shader", 2, true).MouseButton1Click:Connect(function()
	disableShader()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.B and not UserInputService:GetFocusedTextBox() then
		MainFrame.Visible = not MainFrame.Visible
	end
end)

end -- fim do bloco Diversos/Shaders

--------------------------------------------------------------------------------
-- WALKFLING (ABA JOGO)
-- Bloco essencial e auto-contido, no fim do script: se falhar, o painel
-- já está montado e o erro aparece no console (F9) via warn.
-- Lógica do "Noir/NextFling": densidade pesada no próprio personagem +
-- multiplicação da velocidade do HRP; amigos com Skip Friends atravessam.
--------------------------------------------------------------------------------
local okWalkFling, errWalkFling = pcall(function()
	local WF_walkfling = false
	local WF_power = 10000
	local WF_skipFriends = true
	local WF_antiFling = false
	local WF_active = false
	local WF_prepared = false
	local WF_saved = {}
	local WF_friendCache = {}

	local function WF_isFriend(p)
		if p == LocalPlayer then return false end
		if WF_friendCache[p.UserId] == nil then
			local ok, result = pcall(function() return LocalPlayer:IsFriendsWith(p.UserId) end)
			WF_friendCache[p.UserId] = ok and result or false
		end
		return WF_friendCache[p.UserId]
	end

	local function WF_prepareSelf()
		if WF_prepared then return end
		local char = LocalPlayer.Character
		if not char then return end
		WF_prepared = true
		WF_saved = {}
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then
				WF_saved[d] = { cpp = d.CustomPhysicalProperties, cc = d.CanCollide, ml = d.Massless }
				pcall(function() d.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5) end)
			end
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local okHr = pcall(function() hrp.CustomPhysicalProperties = PhysicalProperties.new(math.huge, 0.3, 0.5) end)
			if not okHr then
				pcall(function() hrp.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5) end)
			end
			hrp.Massless = false
			hrp.CanCollide = true
		end
	end

	local function WF_releaseSelf()
		if not WF_prepared then return end
		WF_prepared = false
		for part, s in pairs(WF_saved) do
			if part.Parent then
				pcall(function()
					part.CustomPhysicalProperties = s.cpp
					part.CanCollide = s.cc
					part.Massless = s.ml
				end)
			end
		end
		WF_saved = {}
	end

	RunService.Stepped:Connect(function()
		if not (WF_prepared and WF_walkfling) then return end
		for part in pairs(WF_saved) do
			if part.Parent and part.Name ~= "HumanoidRootPart" then
				part.CanCollide = false
			end
		end
		if WF_skipFriends then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character and WF_isFriend(p) then
					for _, d in ipairs(p.Character:GetDescendants()) do
						if d:IsA("BasePart") then d.CanCollide = false end
					end
				end
			end
		end
	end)

	local function WF_start()
		if WF_active then return end
		WF_active = true
		task.spawn(function()
			while WF_walkfling do
				local char = LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					if not WF_prepared then WF_prepareSelf() end
					RunService.Heartbeat:Wait()
					if hrp.Parent then
						local vel = hrp.AssemblyLinearVelocity
						hrp.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, WF_power, 0)
						RunService.RenderStepped:Wait()
						if hrp.Parent then hrp.AssemblyLinearVelocity = vel end
						RunService.Stepped:Wait()
						if hrp.Parent then hrp.AssemblyLinearVelocity = vel + Vector3.new(0, 0.1, 0) end
					end
				else
					task.wait(0.1)
				end
			end
			WF_active = false
			WF_releaseSelf()
		end)
	end

	-- Controles na aba Jogo (mesmos helpers visuais dos outros widgets)
	createSection(GameTab, "Fling", "Arremesse encostando; antifling te protege.", 6)

	-- PERMISSÃO: a seção Fling é exclusiva de Premium, Moderator e Owner.
	-- O cargo real vem da API via atributos do ScreenGui (pode levar
	-- alguns segundos após executar o painel — a checagem é no clique).
	local function WF_hasPermission()
		if ScreenGui:GetAttribute("CHOSEN_CanUsePremium") == true then
			return true
		end
		local role = ScreenGui:GetAttribute("CHOSEN_Role")
		return role == "Owner" or role == "Moderator" or role == "Premium"
	end

	-- Aviso "🔒 sem permissão": toast flutuante no topo da tela
	-- (independente do layout da aba, impossível passar despercebido).
	local WF_noticeToken = 0
	local function WF_showNotice()
		warn("[Chosen] Fling bloqueado: requer Premium ou superior")
		WF_noticeToken += 1
		local token = WF_noticeToken

		local old = ScreenGui:FindFirstChild("WFLockNotice")
		if old then
			old:Destroy()
		end

		local notice = Instance.new("Frame")
		notice.Name = "WFLockNotice"
		notice.AnchorPoint = Vector2.new(0.5, 0)
		notice.Position = UDim2.new(0.5, 0, 0, 14)
		notice.Size = UDim2.new(0, 330, 0, 58)
		notice.BackgroundColor3 = Color3.fromRGB(30, 22, 8)
		notice.BackgroundTransparency = 0.03
		notice.BorderSizePixel = 0
		notice.ZIndex = 90
		notice.Parent = ScreenGui
		corner(notice, 10)
		stroke(notice, Color3.fromRGB(255, 170, 60), 1.2, 0.35)

		-- Barra lateral de destaque (âmbar)
		local noticeBar = Instance.new("Frame")
		noticeBar.Size = UDim2.new(0, 4, 1, 0)
		noticeBar.BackgroundColor3 = Color3.fromRGB(255, 170, 60)
		noticeBar.BorderSizePixel = 0
		noticeBar.ZIndex = 91
		noticeBar.Parent = notice
		corner(noticeBar, 2)

		local noticeTitle = Instance.new("TextLabel")
		noticeTitle.Size = UDim2.new(1, -30, 0, 16)
		noticeTitle.Position = UDim2.new(0, 18, 0, 9)
		noticeTitle.BackgroundTransparency = 1
		noticeTitle.Text = "🔒  ACESSO NEGADO"
		noticeTitle.TextColor3 = Color3.fromRGB(255, 190, 90)
		noticeTitle.Font = Enum.Font.LuckiestGuy
		noticeTitle.TextSize = 11
		noticeTitle.TextXAlignment = Enum.TextXAlignment.Left
		noticeTitle.ZIndex = 91
		noticeTitle.Parent = notice

		local noticeText = Instance.new("TextLabel")
		noticeText.Size = UDim2.new(1, -30, 0, 26)
		noticeText.Position = UDim2.new(0, 18, 0, 27)
		noticeText.BackgroundTransparency = 1
		noticeText.Text = "Fling é exclusivo de Premium\nou cargo superior"
		noticeText.TextColor3 = Color3.fromRGB(240, 235, 225)
		noticeText.Font = Enum.Font.FredokaOne
		noticeText.TextSize = 11
		noticeText.TextXAlignment = Enum.TextXAlignment.Left
		noticeText.TextYAlignment = Enum.TextYAlignment.Top
		noticeText.ZIndex = 91
		noticeText.Parent = notice

		-- Barra de contagem: o tempo restante (2.5s) esvazia
		local noticeTimer = Instance.new("Frame")
		noticeTimer.AnchorPoint = Vector2.new(1, 0.5)
		noticeTimer.Position = UDim2.new(1, -8, 1, -7)
		noticeTimer.Size = UDim2.new(1, -16, 0, 3)
		noticeTimer.BackgroundColor3 = Color3.fromRGB(255, 170, 60)
		noticeTimer.BackgroundTransparency = 0.3
		noticeTimer.BorderSizePixel = 0
		noticeTimer.ZIndex = 91
		noticeTimer.Parent = notice
		corner(noticeTimer, 2)

		-- Entra deslizando do topo
		notice.Position = UDim2.new(0.5, 0, 0, -66)
		tween(notice, {Position = UDim2.new(0.5, 0, 0, 14)}, 0.25)
		tween(noticeTimer, {Size = UDim2.new(0, 0, 0, 3)}, 2.5)

		task.delay(2.5, function()
			if token == WF_noticeToken and notice.Parent then
				notice:Destroy()
			end
		end)
	end

	local WFCombo
	WFCombo = createComboControl(GameTab, "WalkFling", 1000, 100000, WF_power, 7, function(state)
		if state and not WF_hasPermission() then
			WF_showNotice()
			WFCombo.setState(false)
			return
		end
		WF_walkfling = state
		if state then
			WF_start()
		else
			WF_releaseSelf()
		end
	end, function(value)
		WF_power = value
	end)
	local WFComboCard = WFCombo.card

	-- Antifling: zera velocidades absurdas aplicadas por outros flings.
	-- Pausa automaticamente enquanto o próprio WalkFling está ativo para
	-- não brigar com o efeito que ele cria.
	RunService.Heartbeat:Connect(function()
		if not WF_antiFling then return end
		if WF_walkfling then return end
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp then return end
		local vel = hrp.AssemblyLinearVelocity
		if vel.Magnitude > 300 then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		else
			local av = hrp.AssemblyAngularVelocity
			if av.Magnitude > 150 then
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end)

	local WFRow2 = createControlRow(GameTab, 8)
	local WFAntiCard, WFAntiSet = createToggleButton(WFRow2, "Antifling", function(state)
		if state and not WF_hasPermission() then
			WF_showNotice()
			WFAntiSet(false)
			return
		end
		WF_antiFling = state
	end, 1)

	local WFSkipCard, WFSkipSet = createToggleButton(WFRow2, "Skip Friends", function(state)
		if state and not WF_hasPermission() then
			WF_showNotice()
			WFSkipSet(false)
			return
		end
		WF_skipFriends = state
	end, 2)

	-- BLOQUEIO VISUAL: sem Premium ou superior, os cards ficam
	-- escurecidos e cobertos por um escudo não-clicável (a checagem
	-- no callback continua valendo como segunda barreira).
	local WF_shields = {}
	for _, card in ipairs({ WFComboCard, WFAntiCard, WFSkipCard }) do
		local shield = Instance.new("TextButton")
		shield.Name = "WFLockShield"
		shield.Size = UDim2.new(1, 0, 1, 0)
		shield.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
		shield.BackgroundTransparency = 0.55
		shield.Text = "🔒"
		shield.TextColor3 = Color3.fromRGB(255, 170, 60)
		shield.Font = Enum.Font.FredokaOne
		shield.TextSize = 16
		shield.AutoButtonColor = false
		shield.ZIndex = 10
		shield.Visible = false
		-- Clicar no escudo (nada responde embaixo) mostra o aviso
		-- de que o Fling exige Premium ou superior.
		shield.MouseButton1Click:Connect(WF_showNotice)
		shield.Parent = card
		WF_shields[card] = shield
	end

	local function WF_updateLock()
		local locked = not WF_hasPermission()
		for card, shield in pairs(WF_shields) do
			shield.Visible = locked
			tween(card, {
				BackgroundTransparency = locked and 0.5 or 0.1
			}, 0.15)
		end
	end
	WF_updateLock()

	-- Cargo carregado ou rebaixado? Atualiza o bloqueio e desliga
	-- o WalkFling na hora se a permissão foi perdida.
	local function WF_revokeIfNeeded()
		WF_updateLock()
		if not WF_hasPermission() and WF_walkfling then
			WF_walkfling = false
			WF_showNotice()
			WFCombo.setState(false)
		end
	end
	ScreenGui:GetAttributeChangedSignal("CHOSEN_Role"):Connect(WF_revokeIfNeeded)
	ScreenGui:GetAttributeChangedSignal("CHOSEN_CanUsePremium"):Connect(WF_revokeIfNeeded)

	LocalPlayer.CharacterAdded:Connect(function()
		WF_prepared = false
		WF_saved = {}
		task.wait(0.5)
		if WF_walkfling then
			WF_prepareSelf()
		end
	end)
end)

if not okWalkFling then
	warn("[WalkFling] erro ao iniciar: " .. tostring(errWalkFling))
end
