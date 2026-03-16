-- ── Services ──────────────────────────────────────────────────────────────────
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local CoreGui      = game:GetService("CoreGui")
local UIS          = game:GetService("UserInputService")
local StarterGui   = game:GetService("StarterGui")
local Lighting     = game:GetService("Lighting")

local LP      = Players.LocalPlayer
local TI_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_SLOW = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MOBILE  = UIS.TouchEnabled and not UIS.KeyboardEnabled

local Library = {}
Library.Version = "3.1"

-- ── VenturaUI Icon System ─────────────────────────────────────────────
-- All icons are emoji — full color, render in Roblox TextLabels.
-- Usage:  icon = Library.Icons.sword
--         icon = "⚔️"   (direct emoji also works)
Library.Icons = {
	-- Navigation & UI
	home        = "🏠",
	settings    = "⚙️",
	gear        = "⚙️",
	menu        = "📋",
	search      = "🔍",
	close       = "❌",
	back        = "◀️",
	forward     = "▶️",
	up          = "⬆️",
	down        = "⬇️",
	refresh     = "🔄",
	check       = "✅",
	tick        = "✅",
	cross       = "❌",
	plus        = "➕",
	minus       = "➖",
	star        = "⭐",
	heart       = "❤️",
	diamond     = "💠",
	dot         = "🔵",
	edit        = "✏️",
	send        = "📨",
	reply       = "↩️",
	share       = "📤",
	warning_sym = "⚠️",
	info_sym    = "ℹ️",
	bolt        = "⚡",
	zap         = "⚡",
	sun         = "☀️",
	moon        = "🌙",
	music_sym   = "🎵",
	crown       = "👑",
	rank        = "🏅",
	ban         = "🚫",
	sliders     = "🎚️",
	grid        = "📊",

	-- People
	user        = "👤",
	player      = "👤",
	users       = "👥",
	group       = "👥",
	avatar      = "🧑",

	-- Files & Media
	folder      = "📁",
	folder2     = "📂",
	file        = "📄",
	document    = "📄",
	image       = "🖼️",
	photo       = "📷",
	video       = "🎥",
	music       = "🎵",
	sound       = "🔊",
	mute        = "🔇",
	volume      = "🔉",
	download    = "📥",
	upload      = "📤",
	save        = "💾",
	calendar    = "📅",
	clock       = "🕐",
	timer       = "⏱️",

	-- Communication
	bell        = "🔔",
	notif       = "🔔",
	belloff     = "🔕",
	bookmark    = "🔖",
	pin         = "📌",
	link        = "🔗",
	inbox       = "📨",
	mail        = "📧",

	-- Status
	info        = "ℹ️",
	warning     = "⚠️",
	alert       = "⚠️",
	success     = "✅",
	error2      = "❌",
	question    = "❓",
	help        = "❓",
	loading     = "⏳",

	-- Dev & Code
	bug         = "🐛",
	package     = "📦",
	plugin      = "🔌",
	database    = "🗄️",
	server      = "🖥️",
	mobile      = "📱",
	monitor     = "🖥️",
	console     = "⌨️",
	wrench      = "🔧",
	hammer      = "🔨",
	magnet      = "🧲",

	-- Themes & UI
	palette     = "🎨",
	theme       = "🎨",
	color       = "🖌️",
	fire        = "🔥",
	ice         = "❄️",
	leaf        = "🌿",
	world       = "🌐",
	earth       = "🌍",
	map         = "🗺️",
	compass     = "🧭",
	location    = "📍",

	-- Security
	lock        = "🔒",
	unlock      = "🔓",
	key         = "🔑",
	shield      = "🛡️",
	eye         = "👁️",
	password    = "🔐",

	-- Misc
	trash       = "🗑️",
	delete      = "🗑️",
	pencil      = "✏️",
	copy        = "📋",
	sparkle     = "✨",
	aura        = "✨",
	target      = "🎯",
	gift        = "🎁",
	chart       = "📊",
	trophy      = "🏆",
	medal       = "🥇",
	ribbon      = "🏅",
	crown2      = "👑",
	robot       = "🤖",

	-- Game / Roblox specific
	sword       = "⚔️",
	gun         = "🔫",
	shop        = "🛒",
	coins       = "🪙",
	gem         = "💎",
	map2        = "🗺️",
	chest       = "📦",
	speed       = "💨",
	fly         = "✈️",
	invisible   = "👻",
	skull       = "💀",
	explosion   = "💥",
	alien       = "👽",
	zombie      = "🧟",
	ninja       = "🥷",
	detective   = "🕵️",
	esp         = "◎",
	aimbot      = "⊕",
	tp          = "⊛",
}

local function destroyExistingVenturaGUI()
	local containers = {}
	pcall(function() table.insert(containers, CoreGui) end)
	pcall(function()
		local pg = LP:FindFirstChild("PlayerGui")
		if pg then table.insert(containers, pg) end
	end)
	for _, container in ipairs(containers) do
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("ScreenGui") and child.Name == "VenturaUI" then
				pcall(function() child:Destroy() end)
			end
		end
	end
end

-- Returns {kind="text"|"image", value=string}
local function resolveIcon(icon)
	if not icon or icon == "" then return {kind="none", value=""} end
	if type(icon) == "string" then
		if icon:match("^rbxasset") then return {kind="image", value=icon} end
		if icon:match("^%d+$") then return {kind="image", value="rbxassetid://"..icon} end
		-- anything else is a text/unicode icon
		return {kind="text", value=icon}
	end
	return {kind="none", value=""}
end

Library.Theme = {
	Accent        = Color3.fromRGB(100, 150, 255),
	Background    = Color3.fromRGB(22, 22, 22),
	Surface       = Color3.fromRGB(28, 28, 28),
	SurfaceHover  = Color3.fromRGB(36, 36, 36),
	Nav           = Color3.fromRGB(18, 18, 18),
	Topbar        = Color3.fromRGB(16, 16, 16),
	Border        = Color3.fromRGB(50, 50, 50),
	BorderHover   = Color3.fromRGB(82, 82, 82),
	TextPrimary   = Color3.fromRGB(220, 220, 220),
	TextSecondary = Color3.fromRGB(130, 130, 130),
	TextDisabled  = Color3.fromRGB(75, 75, 75),
}

local function tw(obj, goal, ti, cb)
	local t = TweenService:Create(obj, ti or TI_FAST, goal)
	if cb then t.Completed:Once(cb) end
	t:Play(); return t
end
local function corner(p, r)
	local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 5); return c
end
local function stroke(p, col, thick)
	local s = Instance.new("UIStroke", p)
	s.Color = col or Color3.fromRGB(50,50,50)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Thickness = thick or 1; return s
end
local function pad(p, t, r, b, l)
	local u = Instance.new("UIPadding", p)
	u.PaddingTop=UDim.new(0,t or 0); u.PaddingRight=UDim.new(0,r or 0)
	u.PaddingBottom=UDim.new(0,b or 0); u.PaddingLeft=UDim.new(0,l or 0)
	return u
end
local function lbl(p, text, size, color, font, xalign)
	local l = Instance.new("TextLabel", p)
	l.BorderSizePixel=0; l.BackgroundTransparency=1
	l.TextSize=size or 13
	l.TextXAlignment=xalign or Enum.TextXAlignment.Left
	l.FontFace=font or Font.new("rbxasset://fonts/families/Ubuntu.json")
	l.TextColor3=color or Color3.fromRGB(210,210,210)
	l.Text=text or ""; l.TextTruncate=Enum.TextTruncate.AtEnd
	l.Size=UDim2.new(1,0,1,0); return l
end
local function validate(defaults, opts)
	opts = opts or {}
	for k,v in pairs(defaults) do if opts[k]==nil then opts[k]=v end end
	return opts
end
local function safeLighting(prop, value)
	local ok = pcall(function() Lighting[prop]=value end)
	if not ok then task.defer(function() pcall(function() Lighting[prop]=value end) end) end
end

local _ttFrame, _ttLabel
local function setupTooltip(sg)
	_ttFrame=Instance.new("Frame",sg); _ttFrame.Name="_Tooltip"
	_ttFrame.BackgroundColor3=Color3.fromRGB(14,14,14); _ttFrame.BorderSizePixel=0
	_ttFrame.Size=UDim2.new(0,150,0,24); _ttFrame.Visible=false; _ttFrame.ZIndex=9999
	corner(_ttFrame,4); stroke(_ttFrame,Color3.fromRGB(55,55,55))
	_ttLabel=Instance.new("TextLabel",_ttFrame); _ttLabel.BackgroundTransparency=1
	_ttLabel.TextSize=11; _ttLabel.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json")
	_ttLabel.TextColor3=Color3.fromRGB(195,195,195); _ttLabel.Size=UDim2.new(1,0,1,0)
	_ttLabel.TextXAlignment=Enum.TextXAlignment.Center; _ttLabel.ZIndex=10000
	RunService.RenderStepped:Connect(function()
		if _ttFrame and _ttFrame.Visible then
			local mp=UIS:GetMouseLocation()
			_ttFrame.Position=UDim2.new(0,mp.X+14,0,mp.Y+14)
		end
	end)
end
local function addTooltip(frame, text)
	if not text or text=="" then return end
	frame.MouseEnter:Connect(function()
		if not _ttLabel then return end
		_ttLabel.Text=text; _ttFrame.Size=UDim2.new(0,math.max(#text*7+16,80),0,24); _ttFrame.Visible=true
	end)
	frame.MouseLeave:Connect(function() if _ttFrame then _ttFrame.Visible=false end end)
end

function Library:new(options)
	options=validate({
		name            = "Ventura UI",
		subtitle        = nil,
		toggleKey       = Enum.KeyCode.Insert,
		minimizeKey     = Enum.KeyCode.K,
		loadingTime     = 1.5,
		accent          = nil,
		onClose         = nil,
		watermark       = nil,
		destroyOnRespawn= false,
		key             = nil,
		keyEnabled      = false,
		onKeySuccess    = nil,
		onKeyFail       = nil,
		aiEnabled       = false,   -- set true for a free built-in AI assistant (no key needed)
	}, options)

	if options.accent then Library.Theme.Accent=options.accent end

	destroyExistingVenturaGUI()

	local keys            = {toggle=options.toggleKey, minimize=options.minimizeKey}
	local keybindListening= false
	local currentScale    = 100
	local _destroyed      = false
	local _connections    = {}

	local GUI = {CurrentTab=nil, _tabs={}, _open=true}

	local function track(c) table.insert(_connections,c) end

	local SG=Instance.new("ScreenGui",
		RunService:IsStudio() and LP:WaitForChild("PlayerGui") or CoreGui)
	SG.Name="VenturaUI"; SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	SG.IgnoreGuiInset=true; SG.ResetOnSpawn=false
	SG.DisplayOrder=999
	GUI._sg=SG; setupTooltip(SG)

	if options.destroyOnRespawn then
		local char = LP.Character
		local function onChar()
			if not _destroyed then GUI:Destroy() end
		end
		if char then
			local death = char:FindFirstChild("Humanoid")
			if death then track(death.Died:Connect(onChar)) end
		end
		track(LP.CharacterAdded:Connect(function(c)
			local h = c:WaitForChild("Humanoid", 5)
			if h and not _destroyed then track(h.Died:Connect(onChar)) end
		end))
	end

	if options.watermark then
		local wmFrame = Instance.new("Frame", SG)
		wmFrame.Name = "Watermark"
		wmFrame.BackgroundColor3 = Color3.fromRGB(12,12,12)
		wmFrame.BorderSizePixel = 0
		wmFrame.Size = UDim2.new(0, #options.watermark*7+20, 0, 22)
		wmFrame.Position = UDim2.new(0, 14, 0, 14)
		wmFrame.ZIndex = 50
		corner(wmFrame, 4); stroke(wmFrame, Library.Theme.Border)
		local wmAccent = Instance.new("Frame", wmFrame)
		wmAccent.BackgroundColor3 = Library.Theme.Accent
		wmAccent.BorderSizePixel = 0
		wmAccent.Size = UDim2.new(0, 2, 1, 0)
		wmAccent.ZIndex = 51; corner(wmAccent, 2)
		local wmLbl = Instance.new("TextLabel", wmFrame)
		wmLbl.BackgroundTransparency = 1
		wmLbl.Size = UDim2.new(1,-10,1,0); wmLbl.Position = UDim2.new(0,8,0,0)
		wmLbl.TextSize = 11; wmLbl.ZIndex = 51
		wmLbl.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
		wmLbl.TextColor3 = Library.Theme.TextSecondary
		wmLbl.Text = options.watermark
		wmLbl.TextXAlignment = Enum.TextXAlignment.Left
		local wmDrag, wmDragStart, wmDragPos = false, nil, nil
		wmFrame.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				wmDrag=true; wmDragStart=i.Position; wmDragPos=wmFrame.Position
			end
		end)
		wmFrame.InputChanged:Connect(function(i)
			if wmDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
				local d = i.Position - wmDragStart
				wmFrame.Position = UDim2.new(0, wmDragPos.X.Offset+d.X, 0, wmDragPos.Y.Offset+d.Y)
			end
		end)
		wmFrame.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then wmDrag=false end
		end)
		GUI._watermark = wmFrame
	end

	local Loader=Instance.new("Frame",SG)
	Loader.Name="Loader"; Loader.BorderSizePixel=0
	Loader.BackgroundColor3=Color3.fromRGB(10,10,10)
	Loader.Size=UDim2.fromScale(1,1); Loader.ZIndex=100

	local lTitle=Instance.new("TextLabel",Loader)
	lTitle.BackgroundTransparency=1; lTitle.ZIndex=101; lTitle.TextSize=24
	lTitle.FontFace=Font.new("rbxasset://fonts/families/RobotoMono.json",Enum.FontWeight.Bold)
	lTitle.TextColor3=Library.Theme.Accent; lTitle.AnchorPoint=Vector2.new(0.5,0.5)
	lTitle.Size=UDim2.new(0,320,0,32); lTitle.Position=UDim2.fromScale(0.5,0.43)
	lTitle.Text=options.name; lTitle.TextXAlignment=Enum.TextXAlignment.Center

	local lSub=Instance.new("TextLabel",Loader)
	lSub.BackgroundTransparency=1; lSub.ZIndex=101; lSub.TextSize=12
	lSub.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json")
	lSub.TextColor3=Library.Theme.TextSecondary; lSub.AnchorPoint=Vector2.new(0.5,0.5)
	lSub.Size=UDim2.new(0,300,0,18); lSub.Position=UDim2.fromScale(0.5,0.5)
	lSub.TextXAlignment=Enum.TextXAlignment.Center

	local subtitleMsgs
	if type(options.subtitle)=="table" then
		subtitleMsgs = options.subtitle
	elseif type(options.subtitle)=="string" then
		subtitleMsgs = {options.subtitle}
	else
		subtitleMsgs = {"Initialising...","Loading components...","Almost ready...","Applying theme..."}
	end
	lSub.Text=subtitleMsgs[1]
	local _subIdx=1; local _subLoop=true
	task.spawn(function()
		while _subLoop do
			task.wait(0.55)
			if not _subLoop then break end
			_subIdx=(_subIdx % #subtitleMsgs)+1
			pcall(function() lSub.Text=subtitleMsgs[_subIdx] end)
		end
	end)

	local barBg=Instance.new("Frame",Loader)
	barBg.BackgroundColor3=Color3.fromRGB(35,35,35); barBg.BorderSizePixel=0
	barBg.AnchorPoint=Vector2.new(0.5,0.5); barBg.Size=UDim2.new(0,200,0,4)
	barBg.Position=UDim2.fromScale(0.5,0.565); barBg.ZIndex=101; corner(barBg,2)

	local barFill=Instance.new("Frame",barBg)
	barFill.BackgroundColor3=Library.Theme.Accent; barFill.BorderSizePixel=0
	barFill.Size=UDim2.new(0,0,1,0); barFill.ZIndex=102; corner(barFill,2)
	tw(barFill,{Size=UDim2.new(1,0,1,0)},TweenInfo.new(options.loadingTime,Enum.EasingStyle.Quad))

	local vp   = workspace.CurrentCamera.ViewportSize
	local winW = MOBILE and math.min(vp.X-20,440) or 480
	local winH = 330
	local WIN_MIN_W = 340
	local WIN_MIN_H = 220
	local WIN_MAX_W = 800
	local WIN_MAX_H = 600

	local Main=Instance.new("Frame",SG)
	Main.Name="Main"; Main.BorderSizePixel=0
	Main.BackgroundColor3=Library.Theme.Background
	Main.AnchorPoint=Vector2.new(0.5,0.5)
	Main.Size=UDim2.new(0,winW,0,0)
	Main.Position=UDim2.fromScale(0.5,0.5)
	Main.ClipsDescendants=true; Main.Visible=false
	corner(Main,8)
	GUI._main=Main
	local MainWrap=Main -- alias so existing MainWrap refs still work

	-- Inner border: child of Main, fills 100%, transparent bg, UIStroke clips with Main's corners
	local _borderFrame=Instance.new("Frame",Main)
	_borderFrame.Name="MainBorder"; _borderFrame.BorderSizePixel=0
	_borderFrame.BackgroundTransparency=1
	_borderFrame.Size=UDim2.new(1,0,1,0); _borderFrame.Position=UDim2.new(0,0,0,0)
	_borderFrame.ZIndex=9; _borderFrame.Active=false
	corner(_borderFrame,8)
	local _mainStroke=Instance.new("UIStroke",_borderFrame)
	_mainStroke.Color=Library.Theme.Border; _mainStroke.Thickness=1
	_mainStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
	local _borderOverlay=_borderFrame -- alias so refs below still compile

	local _doTypewriter = false  -- set true once titleLabel exists

	local function showMainWindow()
		MainWrap.Visible=true
		tw(MainWrap,{Size=UDim2.new(0,winW,0,winH)},TI_SLOW)
		_doTypewriter = true
	end

	local function runKeyGate(onPass)
		if not (options.keyEnabled and options.key) then onPass(); return end
		local validKeys = type(options.key)=="table" and options.key or {options.key}

		local chatWasEnabled = true
		pcall(function()
			chatWasEnabled = game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
			game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
		end)
		local function restoreChat()
			pcall(function()
				game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, chatWasEnabled)
			end)
		end

		local KeyFrame=Instance.new("ImageButton",SG)
		KeyFrame.Name="KeyGate"; KeyFrame.Size=UDim2.fromScale(1,1)
		KeyFrame.BackgroundColor3=Color3.fromRGB(8,8,8)
		KeyFrame.BackgroundTransparency=1; KeyFrame.ZIndex=200
		KeyFrame.Image=""; KeyFrame.AutoButtonColor=false
		tw(KeyFrame,{BackgroundTransparency=0.15},TweenInfo.new(0.3))

		local kPanel=Instance.new("Frame",KeyFrame)
		kPanel.Size=UDim2.new(0,320,0,200); kPanel.AnchorPoint=Vector2.new(0.5,0.5)
		kPanel.Position=UDim2.fromScale(0.5,0.5)
		kPanel.BackgroundColor3=Color3.fromRGB(14,14,14)
		kPanel.BorderSizePixel=0; kPanel.ZIndex=201
		corner(kPanel,8); stroke(kPanel,Library.Theme.Border)
		tw(kPanel,{Size=UDim2.new(0,340,0,220)},TI_SLOW)

		local kAccentBar=Instance.new("Frame",kPanel)
		kAccentBar.Size=UDim2.new(1,0,0,3); kAccentBar.BackgroundColor3=Library.Theme.Accent
		kAccentBar.BorderSizePixel=0; kAccentBar.ZIndex=202; corner(kAccentBar,3)

		local kTitle=Instance.new("TextLabel",kPanel)
		kTitle.BackgroundTransparency=1; kTitle.ZIndex=202
		kTitle.Size=UDim2.new(1,-24,0,28); kTitle.Position=UDim2.new(0,12,0,14)
		kTitle.Text=options.name; kTitle.TextXAlignment=Enum.TextXAlignment.Center
		kTitle.TextSize=16; kTitle.TextColor3=Color3.fromRGB(220,220,220)
		kTitle.FontFace=Font.new("rbxasset://fonts/families/RobotoMono.json",Enum.FontWeight.Bold)

		local kSub=Instance.new("TextLabel",kPanel)
		kSub.BackgroundTransparency=1; kSub.ZIndex=202
		kSub.Size=UDim2.new(1,-24,0,18); kSub.Position=UDim2.new(0,12,0,44)
		kSub.Text="Click the box below, then type your key"
		kSub.TextXAlignment=Enum.TextXAlignment.Center
		kSub.TextSize=11; kSub.TextColor3=Color3.fromRGB(100,100,100)
		kSub.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json")

		local kInputBg=Instance.new("Frame",kPanel)
		kInputBg.Size=UDim2.new(1,-32,0,36); kInputBg.Position=UDim2.new(0,16,0,72)
		kInputBg.BackgroundColor3=Color3.fromRGB(22,22,22)
		kInputBg.BorderSizePixel=0; kInputBg.ZIndex=202
		corner(kInputBg,6); stroke(kInputBg,Library.Theme.Border)

		local kInput=Instance.new("TextBox",kInputBg)
		kInput.Size=UDim2.new(1,-16,1,0); kInput.Position=UDim2.new(0,8,0,0)
		kInput.BackgroundTransparency=1; kInput.BorderSizePixel=0; kInput.ZIndex=203
		kInput.PlaceholderText="Click here and type your key..."
		kInput.PlaceholderColor3=Color3.fromRGB(60,60,60)
		kInput.Text=""; kInput.TextColor3=Color3.fromRGB(210,210,210)
		kInput.TextSize=13; kInput.ClearTextOnFocus=false
		kInput.FontFace=Font.new("rbxasset://fonts/families/RobotoMono.json")
		kInput.TextXAlignment=Enum.TextXAlignment.Left
		task.defer(function() pcall(function() kInput:ReleaseFocus() end) end)
		kInput.Focused:Connect(function()
			tw(kInputBg,{BackgroundColor3=Color3.fromRGB(28,28,28)})
			tw(kInputBg:FindFirstChildOfClass("UIStroke"),{Color=Library.Theme.Accent})
		end)
		kInput.FocusLost:Connect(function()
			tw(kInputBg,{BackgroundColor3=Color3.fromRGB(22,22,22)})
			tw(kInputBg:FindFirstChildOfClass("UIStroke"),{Color=Library.Theme.Border})
		end)

		local kStatus=Instance.new("TextLabel",kPanel)
		kStatus.BackgroundTransparency=1; kStatus.ZIndex=202
		kStatus.Size=UDim2.new(1,-32,0,16); kStatus.Position=UDim2.new(0,16,0,114)
		kStatus.Text=""; kStatus.TextXAlignment=Enum.TextXAlignment.Center
		kStatus.TextSize=11; kStatus.TextColor3=Color3.fromRGB(200,80,80)
		kStatus.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json")

		local kBtn=Instance.new("TextButton",kPanel)
		kBtn.Size=UDim2.new(1,-32,0,34); kBtn.Position=UDim2.new(0,16,0,136)
		kBtn.BackgroundColor3=Library.Theme.Accent; kBtn.BorderSizePixel=0
		kBtn.TextColor3=Color3.fromRGB(255,255,255); kBtn.TextSize=13
		kBtn.Text="Confirm Key"; kBtn.ZIndex=202; corner(kBtn,6)
		kBtn.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json",Enum.FontWeight.Bold)
		kBtn.MouseEnter:Connect(function() tw(kBtn,{BackgroundColor3=Color3.fromRGB(
			math.clamp(Library.Theme.Accent.R*255+22,0,255),
			math.clamp(Library.Theme.Accent.G*255+22,0,255),
			math.clamp(Library.Theme.Accent.B*255+22,0,255))},TI_FAST) end)
		kBtn.MouseLeave:Connect(function() tw(kBtn,{BackgroundColor3=Library.Theme.Accent},TI_FAST) end)

		local kAttempts=Instance.new("TextLabel",kPanel)
		kAttempts.BackgroundTransparency=1; kAttempts.ZIndex=202
		kAttempts.Size=UDim2.new(1,-32,0,14); kAttempts.Position=UDim2.new(0,16,0,177)
		kAttempts.Text="3 attempts remaining"; kAttempts.TextXAlignment=Enum.TextXAlignment.Center
		kAttempts.TextSize=10; kAttempts.TextColor3=Color3.fromRGB(55,55,55)
		kAttempts.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json")

		local _keyDone = false
		local attempts = 3

		local function submitKey()
			if _keyDone then return end
			local entered = (kInput.Text or ""):gsub("^%s+",""):gsub("%s+$","")
			local valid = false
			for _,k in ipairs(validKeys) do if entered==k then valid=true; break end end

			if valid then
				_keyDone=true
				pcall(function() kInput:ReleaseFocus() end)
				kStatus.TextColor3=Color3.fromRGB(60,200,90); kStatus.Text="✓  Key accepted!"
				kBtn.Active=false
				if options.onKeySuccess then pcall(options.onKeySuccess) end
				task.spawn(function()
					task.wait(0.55)
					for _,d in ipairs(KeyFrame:GetDescendants()) do
						pcall(function() tw(d,{TextTransparency=1,ImageTransparency=1},TweenInfo.new(0.3)) end)
					end
					tw(KeyFrame,{BackgroundTransparency=1},TweenInfo.new(0.35),function()
						restoreChat()
						pcall(function() KeyFrame:Destroy() end)
						onPass()
					end)
				end)
			else
				attempts=attempts-1
				kInput.Text=""
				if attempts<=0 then
					_keyDone=true
					pcall(function() kInput:ReleaseFocus() end)
					kStatus.TextColor3=Color3.fromRGB(200,60,60); kStatus.Text="✗  Too many failed attempts."
					kBtn.Active=false; kAttempts.Text="Script locked."
					if options.onKeyFail then pcall(options.onKeyFail) end
					restoreChat()
					task.delay(2.5,function() pcall(function() SG:Destroy() end) end)
				else
					kStatus.TextColor3=Color3.fromRGB(200,60,60); kStatus.Text="✗  Wrong key — try again."
					kAttempts.Text=attempts.." attempt"..(attempts==1 and "" or "s").." remaining"
					tw(kInputBg,{BackgroundColor3=Color3.fromRGB(42,16,16)},TI_FAST)
					task.delay(0.4,function()
						if not _keyDone then tw(kInputBg,{BackgroundColor3=Color3.fromRGB(22,22,22)},TI_FAST) end
					end)
				end
			end
		end

		kBtn.MouseButton1Click:Connect(submitKey)
		kInput.FocusLost:Connect(function(enter) if enter then submitKey() end end)
	end

	task.delay(options.loadingTime+0.1,function()
		_subLoop=false
		for _,d in ipairs(Loader:GetDescendants()) do
			pcall(function() tw(d,{TextTransparency=1,ImageTransparency=1},TweenInfo.new(0.3)) end)
		end
		tw(Loader,{BackgroundTransparency=1},TweenInfo.new(0.4),function()
			pcall(function() Loader:Destroy() end)
			runKeyGate(showMainWindow)
		end)
	end)

	local Topbar=Instance.new("Frame",Main)
	Topbar.Name="Topbar"; Topbar.BorderSizePixel=0
	Topbar.BackgroundColor3=Library.Theme.Topbar
	Topbar.Size=UDim2.new(1,0,0,28); corner(Topbar,8)

	-- topExt removed: Main's UICorner handles corner squaring cleanly

	local accentLine=Instance.new("Frame",Topbar)
	accentLine.BackgroundColor3=Library.Theme.Accent; accentLine.BorderSizePixel=0
	accentLine.AnchorPoint=Vector2.new(0,1); accentLine.Size=UDim2.new(1,0,0,1)
	accentLine.Position=UDim2.new(0,0,1,0); accentLine.BackgroundTransparency=0.45

	local titleLabel=lbl(Topbar,options.name,13,Library.Theme.TextPrimary,
		Font.new("rbxasset://fonts/families/RobotoMono.json",Enum.FontWeight.SemiBold))
	titleLabel.Size=UDim2.new(1,-90,1,0); pad(titleLabel,0,0,0,10)

	-- Typewriter loop: type forward then delete back, on repeat
	task.spawn(function()
		repeat task.wait(0.05) until _doTypewriter
		local full = tostring(options.name or "")
		task.wait(0.2)
		while not _destroyed do
			-- Type forward
			for i = 1, #full do
				if _destroyed then return end
				titleLabel.Text = string.sub(full, 1, i)
				task.wait(0.075)
			end
			task.wait(1.4) -- pause at full text
			-- Delete backward
			for i = #full - 1, 0, -1 do
				if _destroyed then return end
				titleLabel.Text = string.sub(full, 1, i)
				task.wait(0.045)
			end
			task.wait(0.35) -- pause before retyping
		end
	end)

	local function makeTopBtn(img,xOff)
		-- Larger invisible hit frame so clicks register reliably even when minimized
		local hit=Instance.new("TextButton",Topbar)
		hit.BackgroundTransparency=1; hit.BorderSizePixel=0
		hit.AnchorPoint=Vector2.new(1,0.5)
		hit.Size=UDim2.new(0,26,0,26)
		hit.Position=UDim2.new(1,xOff+6,0.5,0)
		hit.Text=""; hit.ZIndex=5; hit.AutoButtonColor=false

		local b=Instance.new("ImageLabel",hit)
		b.BackgroundTransparency=1; b.BorderSizePixel=0
		b.AnchorPoint=Vector2.new(0.5,0.5)
		b.Image=img; b.ImageColor3=Library.Theme.TextSecondary
		b.Size=UDim2.new(0,14,0,14); b.Position=UDim2.fromScale(0.5,0.5)
		b.ZIndex=6

		hit.MouseEnter:Connect(function() tw(b,{ImageColor3=Library.Theme.TextPrimary}) end)
		hit.MouseLeave:Connect(function() tw(b,{ImageColor3=Library.Theme.TextSecondary}) end)
		return hit
	end
	local exitBtn = makeTopBtn("rbxassetid://11419709766",-8)
	local minBtn  = makeTopBtn("rbxassetid://11422141677",-28)

	-- Version badge in topbar (auto-reads Library.Version)
	local verLabel = Instance.new("TextLabel", Topbar)
	verLabel.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
	verLabel.BorderSizePixel  = 0
	verLabel.AnchorPoint      = Vector2.new(1, 0.5)
	verLabel.Position         = UDim2.new(1, -52, 0.5, 0)
	verLabel.Size             = UDim2.new(0, 0, 0, 16)  -- auto-sized below
	verLabel.Text             = "v" .. Library.Version
	verLabel.TextColor3       = Library.Theme.TextSecondary
	verLabel.TextSize         = 10
	verLabel.FontFace         = Font.new("rbxasset://fonts/families/RobotoMono.json")
	verLabel.TextXAlignment   = Enum.TextXAlignment.Center
	verLabel.ZIndex           = 2
	corner(verLabel, 4)
	-- Auto-size width to text; AnchorPoint=(1,0.5) so Position.X = right edge of label
	-- minBtn right edge = -28, width=14 → left edge = -42; gap of 8 → label right edge = -50
	local verPad = 6
	local ts = game:GetService("TextService")
	local tsize = ts:GetTextSize(verLabel.Text, 10,
		Enum.Font.RobotoMono, Vector2.new(200, 20))
	verLabel.Size = UDim2.new(0, tsize.X + verPad * 2, 0, 16)
	verLabel.Position = UDim2.new(1, -50, 0.5, 0)

	local topLine=Instance.new("Frame",Topbar)
	topLine.BackgroundColor3=Library.Theme.Border; topLine.BorderSizePixel=0
	topLine.AnchorPoint=Vector2.new(0,1); topLine.Size=UDim2.new(1,0,0,1); topLine.Position=UDim2.new(0,0,1,0)

	local navW=115
	local Nav=Instance.new("Frame",Main)
	Nav.Name="Nav"; Nav.BorderSizePixel=0
	Nav.BackgroundColor3=Library.Theme.Nav
	Nav.Size=UDim2.new(0,navW,1,-28); Nav.Position=UDim2.new(0,0,0,28)
	Nav.ClipsDescendants=true; corner(Nav,8)

	local navPatches={}
	for i,a in ipairs({{1,0,1,0},{1,1,1,1}}) do
		local f=Instance.new("Frame",Nav); f.BackgroundColor3=Library.Theme.Nav
		f.BorderSizePixel=0; f.AnchorPoint=Vector2.new(a[1],a[2])
		f.Size=UDim2.new(0,8,0,8); f.Position=UDim2.new(a[3],0,a[4],0); navPatches[i]=f
	end

	local navBorder=Instance.new("Frame",Nav)
	navBorder.BackgroundColor3=Library.Theme.Border; navBorder.BorderSizePixel=0
	navBorder.AnchorPoint=Vector2.new(1,0); navBorder.Size=UDim2.new(0,1,1,0); navBorder.Position=UDim2.new(1,0,0,0)

	local searchBar=Instance.new("Frame",Nav)
	searchBar.BackgroundColor3=Color3.fromRGB(24,24,24); searchBar.BorderSizePixel=0
	searchBar.Size=UDim2.new(1,-12,0,22); searchBar.Position=UDim2.new(0,6,0,6)
	corner(searchBar,4); stroke(searchBar,Library.Theme.Border)

	local searchBox=Instance.new("TextBox",searchBar)
	searchBox.BackgroundTransparency=1; searchBox.BorderSizePixel=0
	searchBox.TextSize=11; searchBox.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json")
	searchBox.TextColor3=Library.Theme.TextPrimary
	searchBox.PlaceholderText="Search tabs..."; searchBox.PlaceholderColor3=Library.Theme.TextDisabled
	searchBox.Text=""; searchBox.ClearTextOnFocus=false
	searchBox.Size=UDim2.new(1,-8,1,0); searchBox.Position=UDim2.new(0,6,0,0)
	searchBox.TextXAlignment=Enum.TextXAlignment.Left

	local BtnHolder=Instance.new("Frame",Nav)
	BtnHolder.BackgroundTransparency=1; BtnHolder.BorderSizePixel=0
	BtnHolder.Size=UDim2.new(1,0,1,-100); BtnHolder.Position=UDim2.new(0,0,0,32)
	BtnHolder.ClipsDescendants=true; pad(BtnHolder,4,6,4,6)
	local bhLayout=Instance.new("UIListLayout",BtnHolder)
	bhLayout.Padding=UDim.new(0,2); bhLayout.SortOrder=Enum.SortOrder.LayoutOrder

	track(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q=searchBox.Text:lower()
		for _,tab in ipairs(GUI._tabs) do
			if tab._navBtn then tab._navBtn.Visible=(q=="" or tab._name:lower():find(q,1,true)~=nil) end
		end
	end))

	local userSep=Instance.new("Frame",Nav)
	userSep.BackgroundColor3=Library.Theme.Border; userSep.BorderSizePixel=0
	userSep.AnchorPoint=Vector2.new(0,1); userSep.Size=UDim2.new(1,0,0,1); userSep.Position=UDim2.new(0,0,1,-62)

	local UserBox=Instance.new("Frame",Nav)
	UserBox.Name="UserBox"; UserBox.BorderSizePixel=0
	UserBox.BackgroundColor3=Color3.fromRGB(20,20,20)
	UserBox.AnchorPoint=Vector2.new(0,1); UserBox.Size=UDim2.new(1,0,0,61)
	UserBox.Position=UDim2.new(0,0,1,0); pad(UserBox,0,6,0,8)
	corner(UserBox,6)

	-- Avatar: ring frame acts as border (UIStroke bleeds through UICorner in Roblox)
	-- Avatar: no UIStroke, just UICorner directly on the ImageLabel
	local avtr=Instance.new("ImageLabel",UserBox)
	avtr.BackgroundColor3=Library.Theme.Nav; avtr.BackgroundTransparency=0; avtr.BorderSizePixel=0
	avtr.AnchorPoint=Vector2.new(0,0.5); avtr.Size=UDim2.new(0,36,0,36)
	avtr.Position=UDim2.new(0,6,0.5,0); avtr.ScaleType=Enum.ScaleType.Crop
	avtr.Image=("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png"):format(LP.UserId)
	corner(avtr,50)

	local usStack=Instance.new("Frame",UserBox)
	usStack.BackgroundTransparency=1; usStack.BorderSizePixel=0
	usStack.AnchorPoint=Vector2.new(0,0.5); usStack.Size=UDim2.new(1,-50,0,36); usStack.Position=UDim2.new(0,50,0.5,0)
	local usL=Instance.new("UIListLayout",usStack); usL.SortOrder=Enum.SortOrder.LayoutOrder; usL.Padding=UDim.new(0,1)

	local dispLbl=lbl(usStack,LP.DisplayName,11,Library.Theme.TextPrimary,
		Font.new("rbxasset://fonts/families/Ubuntu.json",Enum.FontWeight.Bold))
	dispLbl.Size=UDim2.new(1,0,0,17); dispLbl.LayoutOrder=1
	local unLbl=lbl(usStack,"@"..LP.Name,10,Library.Theme.TextSecondary)
	unLbl.Size=UDim2.new(1,0,0,15); unLbl.LayoutOrder=2

	local Content=Instance.new("Frame",Main)
	Content.Name="Content"; Content.BackgroundTransparency=1; Content.BorderSizePixel=0
	Content.Position=UDim2.new(0,navW+6,0,34); Content.ClipsDescendants=true
	Content.Size=UDim2.new(1,-(navW+12),1,-40)
	GUI._content=Content

	local NOTIF_W      = 260
	local NOTIF_H      = 56
	local NOTIF_PAD    = 8
	local NOTIF_RIGHT  = 14
	local NOTIF_BOTTOM = 14
	local _notifStack  = {}

	local function _notifReflow()
		local yOff = NOTIF_BOTTOM
		for i = 1, #_notifStack do
			local card = _notifStack[i]
			local targetY = -(yOff)
			tw(card, { Position = UDim2.new(1, -(NOTIF_W + NOTIF_RIGHT), 1, targetY) }, TI_FAST)
			yOff = yOff + NOTIF_H + NOTIF_PAD
		end
	end

	local function _removeCard(card)
		for i, c in ipairs(_notifStack) do
			if c == card then table.remove(_notifStack, i); break end
		end
		_notifReflow()
	end

	function GUI.notify(title, text, duration, ntype)
		duration = duration or 3
		-- Color the accent bar based on notification type
		local accentCol = ntype == "success" and Color3.fromRGB(60,200,100)
			or ntype == "warning" and Color3.fromRGB(230,180,0)
			or ntype == "error"   and Color3.fromRGB(220,60,60)
			or ntype == "info"    and Color3.fromRGB(80,160,255)
			or Library.Theme.Accent
		local card = Instance.new("Frame", SG)
		card.Name             = "_Notif"
		card.Size             = UDim2.new(0, NOTIF_W, 0, NOTIF_H)
		card.BackgroundColor3 = Library.Theme.Surface
		card.BorderSizePixel  = 0
		card.Position = UDim2.new(1, NOTIF_RIGHT + NOTIF_W + 40, 1, -(NOTIF_BOTTOM))
		card.AnchorPoint      = Vector2.new(0, 1)
		card.ZIndex           = 600
		corner(card, 6); stroke(card, Library.Theme.Border)
		local accent = Instance.new("Frame", card)
		accent.Size             = UDim2.new(0, 3, 1, 0)
		accent.BackgroundColor3 = accentCol
		accent.BorderSizePixel  = 0
		accent.ZIndex           = 601; corner(accent, 2)
		local progBg = Instance.new("Frame", card)
		progBg.Size             = UDim2.new(1, 0, 0, 2)
		progBg.Position         = UDim2.new(0, 0, 1, -2)
		progBg.BackgroundColor3 = Library.Theme.Border
		progBg.BorderSizePixel  = 0; progBg.ZIndex = 601
		local progFill = Instance.new("Frame", progBg)
		progFill.Size             = UDim2.new(1, 0, 1, 0)
		progFill.BackgroundColor3 = accentCol
		progFill.BorderSizePixel  = 0; progFill.ZIndex = 602
		local tTitle = lbl(card, title or "VenturaUI", 12, Library.Theme.TextPrimary,
			Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold))
		tTitle.Size     = UDim2.new(1, -18, 0, 16)
		tTitle.Position = UDim2.new(0, 12, 0, 8); tTitle.ZIndex = 601
		local tText = lbl(card, text or "", 11, Library.Theme.TextSecondary)
		tText.Size     = UDim2.new(1, -18, 0, 24)
		tText.Position = UDim2.new(0, 12, 0, 26); tText.ZIndex = 601
		tText.TextWrapped = true; tText.TextYAlignment = Enum.TextYAlignment.Top
		table.insert(_notifStack, 1, card)
		_notifReflow()
		local targetPos = UDim2.new(1, -(NOTIF_W + NOTIF_RIGHT), 1, -(NOTIF_BOTTOM))
		card.Position = UDim2.new(1, NOTIF_W + NOTIF_RIGHT + 40, 1, -(NOTIF_BOTTOM))
		tw(card, { Position = targetPos }, TI_FAST)
		local TI_DRAIN = TweenInfo.new(duration, Enum.EasingStyle.Linear)
		tw(progFill, { Size = UDim2.new(0, 0, 1, 0) }, TI_DRAIN)
		card.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				_removeCard(card)
				tw(card, { Position = UDim2.new(1, NOTIF_W + NOTIF_RIGHT + 40, 1, -(NOTIF_BOTTOM)),
					BackgroundTransparency = 1 }, TI_FAST, function()
					pcall(function() card:Destroy() end)
				end)
			end
		end)
		task.delay(duration, function()
			if not card or not card.Parent then return end
			_removeCard(card)
			tw(card, { Position = UDim2.new(1, NOTIF_W + NOTIF_RIGHT + 40, 1, card.Position.Y.Offset),
				BackgroundTransparency = 1 }, TI_FAST, function()
				pcall(function() card:Destroy() end)
			end)
		end)
	end

	local minimized=false
	local _mainTween = nil  -- tracks active tween on Main so we can cancel it

	local function doMinimize()
		local sw=winW*(currentScale/100); local sh=winH*(currentScale/100)
		minimized=not minimized
		if _mainTween then _mainTween:Cancel() end
		if minimized then
			Nav.Visible=false; Content.Visible=false
			_mainTween = tw(MainWrap,{Size=UDim2.new(0,sw,0,28)},TI_FAST)
		else
			_mainTween = tw(MainWrap,{Size=UDim2.new(0,sw,0,sh)},TI_SLOW,function()
				Nav.Visible=true; Content.Visible=true
			end)
		end
	end

	function GUI:Destroy()
		if _destroyed then return end
		_destroyed=true; keybindListening=false
		for _,c in ipairs(_connections) do pcall(function() c:Disconnect() end) end
		_connections={}
		if _mainTween then _mainTween:Cancel(); _mainTween = nil end
		local sw = winW*(currentScale/100)
		local sh = winH*(currentScale/100)
		if minimized then
			minimized = false
			Nav.Visible = true; Content.Visible = true
			MainWrap.Size = UDim2.new(0, sw, 0, 28)
			_mainTween = tw(MainWrap, {Size=UDim2.new(0,sw,0,sh)}, TI_SLOW, function()
				task.wait(0.08)
				tw(MainWrap, {Size=UDim2.new(0,sw,0,0)}, TI_FAST, function()
					pcall(function() SG:Destroy() end)
				end)
			end)
		else
			tw(MainWrap, {Size=UDim2.new(0,sw,0,0)}, TI_FAST, function()
				pcall(function() SG:Destroy() end)
			end)
		end
	end

	function GUI:SetTitle(text) titleLabel.Text = tostring(text or "") end
	function GUI:SetSubtitle(text) pcall(function() lSub.Text=tostring(text or "") end) end
	function GUI:SelectTab(name)
		for _,tab in ipairs(GUI._tabs) do
			if tab._name==name and not tab._disabled then tab:Activate(); return true end
		end
		return false
	end

	minBtn.MouseButton1Click:Connect(doMinimize)
	exitBtn.MouseButton1Click:Connect(function()
		if _destroyed then return end
		if options.onClose then pcall(options.onClose) end
		-- Goodbye notification lives in its own ScreenGui so it survives GUI:Destroy()
		task.spawn(function()
			local byeDur = 3
			local notifSG = Instance.new("ScreenGui",
				RunService:IsStudio() and LP:WaitForChild("PlayerGui") or CoreGui)
			notifSG.Name = "VenturaUI_Goodbye"
			notifSG.IgnoreGuiInset = true
			notifSG.DisplayOrder = 1000
			notifSG.ResetOnSpawn = false
			local NW, NH, NR, NB = 220, 56, 14, 14
			local card = Instance.new("Frame", notifSG)
			card.Size = UDim2.new(0, NW, 0, NH)
			card.BackgroundColor3 = Library.Theme.Surface
			card.BorderSizePixel = 0
			card.AnchorPoint = Vector2.new(0, 1)
			card.Position = UDim2.new(1, NW + NR + 40, 1, -NB)
			card.ZIndex = 600
			corner(card, 6); stroke(card, Library.Theme.Border)
			local acc = Instance.new("Frame", card)
			acc.Size = UDim2.new(0,3,1,0); acc.BackgroundColor3 = Library.Theme.Accent
			acc.BorderSizePixel = 0; acc.ZIndex = 601; corner(acc, 2)
			local pb = Instance.new("Frame", card)
			pb.Size = UDim2.new(1,0,0,2); pb.Position = UDim2.new(0,0,1,-2)
			pb.BackgroundColor3 = Library.Theme.Border; pb.BorderSizePixel = 0; pb.ZIndex = 601
			local pf = Instance.new("Frame", pb)
			pf.Size = UDim2.new(1,0,1,0); pf.BackgroundColor3 = Library.Theme.Accent
			pf.BorderSizePixel = 0; pf.ZIndex = 602
			local t1 = lbl(card, "Ventura UI", 12, Library.Theme.TextPrimary,
				Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold))
			t1.Size = UDim2.new(1,-18,0,16); t1.Position = UDim2.new(0,12,0,8); t1.ZIndex = 601
			local t2 = lbl(card, "Thanks for using Ventura UI — see you! 👋", 11, Library.Theme.TextSecondary)
			t2.Size = UDim2.new(1,-18,0,24); t2.Position = UDim2.new(0,12,0,26)
			t2.TextWrapped = true; t2.TextYAlignment = Enum.TextYAlignment.Top; t2.ZIndex = 601
			tw(card, { Position = UDim2.new(1, -(NW+NR), 1, -NB) }, TI_FAST)
			tw(pf, { Size = UDim2.new(0,0,1,0) }, TweenInfo.new(byeDur, Enum.EasingStyle.Linear))
			task.delay(byeDur, function()
				tw(card, { Position = UDim2.new(1, NW+NR+40, 1, -NB),
					BackgroundTransparency = 1 }, TI_FAST, function()
					pcall(function() notifSG:Destroy() end)
				end)
			end)
		end)
		GUI:Destroy()
	end)

	track(UIS.InputBegan:Connect(function(input,gpe)
		if _destroyed or gpe or keybindListening then return end
		if input.UserInputType~=Enum.UserInputType.Keyboard then return end
		if input.KeyCode==keys.toggle then
			GUI._open=not GUI._open; MainWrap.Visible=GUI._open
		elseif input.KeyCode==keys.minimize and GUI._open then
			doMinimize()
		end
	end))

	local dragging,dragStart,startPos
	Topbar.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			-- Don't start drag if clicking in the buttons zone (rightmost 70px of topbar)
			local relX = i.Position.X - Main.AbsolutePosition.X
			if relX >= Main.AbsoluteSize.X - 70 then return end
			dragging=true; dragStart=i.Position; startPos=MainWrap.Position
		end
	end)
	Topbar.InputChanged:Connect(function(i)
		if not dragging then return end
		if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
		local d   = i.Position - dragStart
		local vps = workspace.CurrentCamera.ViewportSize
		local sw  = winW*(currentScale/100)
		local sh  = minimized and 28 or winH*(currentScale/100)  -- use real height when minimized
		local newX = math.clamp(startPos.X.Offset+d.X, sw/2, vps.X-sw/2)
		local newY = math.clamp(startPos.Y.Offset+d.Y, sh/2, vps.Y-sh/2)
		MainWrap.Position=UDim2.new(0,newX,0,newY)
	end)
	Topbar.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
	end)

	-- ── Resize Handle ────────────────────────────────────────────────────
	-- Invisible resize hotspot (bottom-right 20x20, no visual)
	local resizeHandle = Instance.new("TextButton", Main)
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.new(0, 20, 0, 20)
	resizeHandle.AnchorPoint = Vector2.new(1, 1)
	resizeHandle.Position = UDim2.new(1, 0, 1, 0)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.BorderSizePixel = 0
	resizeHandle.Text = ""
	resizeHandle.ZIndex = 10
	resizeHandle.Active = true
	resizeHandle.Selectable = false
	resizeHandle.AutoButtonColor = false

	local resizeDragging = false
	local resizeDragStart, resizeStartSize

	resizeHandle.InputBegan:Connect(function(i)
		if minimized then return end  -- no resize while minimized
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			resizeDragging = true
			resizeDragStart = i.Position
			resizeStartSize = Vector2.new(winW, winH)  -- use logical size, not AbsoluteSize
		end
	end)

	track(UIS.InputChanged:Connect(function(i)
		if not resizeDragging then return end
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = i.Position - resizeDragStart
		local newW  = math.clamp(resizeStartSize.X + delta.X, WIN_MIN_W, WIN_MAX_W)
		local newH  = math.clamp(resizeStartSize.Y + delta.Y, WIN_MIN_H, WIN_MAX_H)
		winW = newW; winH = newH
		currentScale = 100  -- reset scale to 100 when manually resizing
		MainWrap.Size = UDim2.new(0, newW, 0, newH)
	end))

	track(UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if resizeDragging then
				resizeDragging = false
				GUI:SaveConfig()  -- auto-save after resize
			end
		end
	end))

	-- ══════════════════════════════════════════════════════════════════════
	-- CreateTab
	-- ══════════════════════════════════════════════════════════════════════
	function GUI:CreateTab(opts)
		opts=validate({name="Tab", icon="🏠", badge=nil, badgeColor=nil},opts)
		local Tab={Active=false, _name=opts.name, _disabled=false}
		local isFirst=(#GUI._tabs==0)
		table.insert(GUI._tabs,Tab)
		if isFirst then GUI.CurrentTab=Tab; Tab.Active=true end

		Tab._scroll=Instance.new("ScrollingFrame",Content)
		Tab._scroll.Name=opts.name.."_Content"
		Tab._scroll.BackgroundTransparency=1; Tab._scroll.BorderSizePixel=0
		Tab._scroll.Size=UDim2.new(1,0,1,0); Tab._scroll.ClipsDescendants=true
		Tab._scroll.ScrollBarThickness=2; Tab._scroll.ScrollBarImageColor3=Color3.fromRGB(62,62,62)
		Tab._scroll.CanvasSize=UDim2.new(0,0,0,0)
		Tab._scroll.Position=isFirst and UDim2.new(0,0,0,0) or UDim2.new(0,99999,0,0)
		Tab._scroll.Visible=true
		pad(Tab._scroll,4,4,6,2)
		local sL=Instance.new("UIListLayout",Tab._scroll)
		sL.Padding=UDim.new(0,5); sL.SortOrder=Enum.SortOrder.LayoutOrder
		sL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Tab._scroll.CanvasSize=UDim2.new(0,0,0,sL.AbsoluteContentSize.Y+10)
		end)

		Tab._navBtn=Instance.new("Frame",BtnHolder)
		Tab._navBtn.Name=opts.name.."_Btn"; Tab._navBtn.BorderSizePixel=0
		Tab._navBtn.BackgroundColor3=Library.Theme.Border
		Tab._navBtn.BackgroundTransparency=isFirst and 0.4 or 1
		Tab._navBtn.Size=UDim2.new(1,0,0,22)
		corner(Tab._navBtn,4)

		local indicator=Instance.new("Frame",Tab._navBtn)
		indicator.BackgroundColor3=Library.Theme.Accent; indicator.BorderSizePixel=0
		indicator.AnchorPoint=Vector2.new(0,0.5)
		indicator.Size=UDim2.new(0,isFirst and 2 or 0,0.65,0)
		indicator.Position=UDim2.new(0,0,0.5,0); indicator.ZIndex=1; corner(indicator,2)
		Tab._indicator=indicator

		-- Smart icon: TextLabel for unicode glyphs, ImageLabel for asset IDs
		local iconInfo = resolveIcon(opts.icon)
		local navIcon
		if iconInfo.kind == "text" then
			navIcon = Instance.new("TextLabel", Tab._navBtn)
			navIcon.BackgroundTransparency = 1
			navIcon.BorderSizePixel = 0
			navIcon.AnchorPoint = Vector2.new(0, 0.5)
			navIcon.Size = UDim2.new(0, 16, 0, 16)
			navIcon.Position = UDim2.new(0, 4, 0.5, 0)
			navIcon.ZIndex = 2
			navIcon.Text = iconInfo.value
			navIcon.TextSize = 13
			navIcon.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
			navIcon.TextColor3 = isFirst and Library.Theme.TextPrimary or Library.Theme.TextSecondary
			navIcon.TextXAlignment = Enum.TextXAlignment.Center
			navIcon.TextYAlignment = Enum.TextYAlignment.Center
		else
			navIcon = Instance.new("ImageLabel", Tab._navBtn)
			navIcon.BackgroundTransparency = 1
			navIcon.BorderSizePixel = 0
			navIcon.AnchorPoint = Vector2.new(0, 0.5)
			navIcon.Image = iconInfo.kind == "image" and iconInfo.value or ""
			navIcon.ImageColor3 = isFirst and Library.Theme.TextPrimary or Library.Theme.TextSecondary
			navIcon.Size = UDim2.new(0, 13, 0, 13)
			navIcon.Position = UDim2.new(0, 5, 0.5, 0)
			navIcon.ZIndex = 2
		end
		Tab._navIcon = navIcon
		Tab._navIconKind = iconInfo.kind

		local navText=Instance.new("TextLabel",Tab._navBtn)
		navText.BackgroundTransparency=1; navText.BorderSizePixel=0
		navText.TextSize=12; navText.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json")
		navText.TextColor3=isFirst and Library.Theme.TextPrimary or Library.Theme.TextSecondary
		navText.Text=opts.name; navText.TextTruncate=Enum.TextTruncate.AtEnd
		navText.TextXAlignment=Enum.TextXAlignment.Left
		navText.Size=UDim2.new(1,-22,1,0); navText.Position=UDim2.new(0,22,0,0); navText.ZIndex=2
		Tab._navText=navText

		if opts.badge then
			local badgeFrame=Instance.new("Frame",Tab._navBtn)
			badgeFrame.BackgroundColor3=opts.badgeColor or Color3.fromRGB(255,80,80)
			badgeFrame.BorderSizePixel=0; badgeFrame.AnchorPoint=Vector2.new(1,0.5)
			badgeFrame.Size=UDim2.new(0,math.max(#opts.badge*6+8,24),0,13)
			badgeFrame.Position=UDim2.new(1,-2,0.5,0); badgeFrame.ZIndex=3; corner(badgeFrame,3)
			local badgeLbl=Instance.new("TextLabel",badgeFrame)
			badgeLbl.BackgroundTransparency=1; badgeLbl.Size=UDim2.new(1,0,1,0)
			badgeLbl.TextSize=9; badgeLbl.TextXAlignment=Enum.TextXAlignment.Center
			badgeLbl.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json",Enum.FontWeight.Bold)
			badgeLbl.TextColor3=Color3.fromRGB(255,255,255); badgeLbl.Text=opts.badge; badgeLbl.ZIndex=4
		end

		local navClickBtn=Instance.new("TextButton",Tab._navBtn)
		navClickBtn.BackgroundTransparency=1; navClickBtn.BorderSizePixel=0
		navClickBtn.Size=UDim2.new(1,0,1,0); navClickBtn.Text=""; navClickBtn.ZIndex=3
		navClickBtn.AutoButtonColor=false

		navClickBtn.MouseEnter:Connect(function()
			if not Tab.Active and not Tab._disabled then
				tw(Tab._navBtn,{BackgroundTransparency=0.85})
				tw(navText,{TextColor3=Library.Theme.TextPrimary})
				if Tab._navIconKind=="text" then tw(navIcon,{TextColor3=Library.Theme.TextPrimary}) else tw(navIcon,{ImageColor3=Library.Theme.TextPrimary}) end
			end
		end)
		navClickBtn.MouseLeave:Connect(function()
			if not Tab.Active and not Tab._disabled then
				tw(Tab._navBtn,{BackgroundTransparency=1})
				tw(navText,{TextColor3=Library.Theme.TextSecondary})
				if Tab._navIconKind=="text" then tw(navIcon,{TextColor3=Library.Theme.TextSecondary}) else tw(navIcon,{ImageColor3=Library.Theme.TextSecondary}) end
			end
		end)
		navClickBtn.MouseButton1Click:Connect(function()
			if not Tab._disabled then Tab:Activate() end
		end)

		function Tab:Activate()
			if Tab.Active or Tab._disabled then return end
			if GUI.CurrentTab then GUI.CurrentTab:Deactivate() end
			Tab.Active=true; Tab._scroll.Position=UDim2.new(0,0,0,0); GUI.CurrentTab=Tab
			tw(Tab._navBtn,{BackgroundTransparency=0.4})
			tw(navText,{TextColor3=Library.Theme.TextPrimary})
			if Tab._navIconKind == "text" then
				tw(navIcon,{TextColor3=Library.Theme.TextPrimary})
			else
				tw(navIcon,{ImageColor3=Library.Theme.TextPrimary})
			end
			tw(Tab._indicator,{Size=UDim2.new(0,2,0.65,0)})
		end
		function Tab:Deactivate()
			if not Tab.Active then return end
			Tab.Active=false; Tab._scroll.Position=UDim2.new(0,99999,0,0)
			tw(Tab._navBtn,{BackgroundTransparency=1})
			tw(navText,{TextColor3=Library.Theme.TextSecondary})
			if Tab._navIconKind == "text" then
				tw(navIcon,{TextColor3=Library.Theme.TextSecondary})
			else
				tw(navIcon,{ImageColor3=Library.Theme.TextSecondary})
			end
			tw(Tab._indicator,{Size=UDim2.new(0,0,0.65,0)})
		end
		function Tab:Disable()
			Tab._disabled=true; navClickBtn.Active=false
			tw(navText,{TextColor3=Library.Theme.TextDisabled})
			if Tab._navIconKind == "text" then
				tw(navIcon,{TextColor3=Library.Theme.TextDisabled})
			else
				tw(navIcon,{ImageColor3=Library.Theme.TextDisabled})
			end
			tw(Tab._navBtn,{BackgroundTransparency=1})
		end
		function Tab:Enable()
			Tab._disabled=false; navClickBtn.Active=true
			tw(navText,{TextColor3=Tab.Active and Library.Theme.TextPrimary or Library.Theme.TextSecondary})
			if Tab._navIconKind == "text" then
				tw(navIcon,{TextColor3=Tab.Active and Library.Theme.TextPrimary or Library.Theme.TextSecondary})
			else
				tw(navIcon,{ImageColor3=Tab.Active and Library.Theme.TextPrimary or Library.Theme.TextSecondary})
			end
		end

		local function base(name,h)
			local f=Instance.new("Frame",Tab._scroll)
			f.Name=name; f.BorderSizePixel=0; f.BackgroundColor3=Library.Theme.Surface
			f.Size=UDim2.new(1,0,0,h or 32); corner(f); stroke(f,Library.Theme.Border); return f
		end

		function Tab:Section(opts)
			opts=validate({name="Section"},opts)
			local f=Instance.new("Frame",Tab._scroll)
			f.Name="Section"; f.BackgroundTransparency=1; f.BorderSizePixel=0; f.Size=UDim2.new(1,0,0,20)
			local line=Instance.new("Frame",f)
			line.BackgroundColor3=Library.Theme.Border; line.BorderSizePixel=0
			line.AnchorPoint=Vector2.new(0,0.5); line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,0.5,0)
			local sLbl=lbl(f,opts.name:upper(),10,Library.Theme.TextDisabled,
				Font.new("rbxasset://fonts/families/Ubuntu.json",Enum.FontWeight.Bold))
			sLbl.BackgroundColor3=Library.Theme.Background; sLbl.BackgroundTransparency=0
			sLbl.Size=UDim2.new(0,#opts.name*7+10,1,0); sLbl.ZIndex=2; sLbl.TextXAlignment=Enum.TextXAlignment.Center
			return f
		end

		function Tab:Separator()
			local f=Instance.new("Frame",Tab._scroll)
			f.BackgroundColor3=Library.Theme.Border; f.BorderSizePixel=0; f.Size=UDim2.new(1,0,0,1); return f
		end

		function Tab:Label(opts)
			opts=validate({text="Label",color=nil},opts)
			local f=Instance.new("Frame",Tab._scroll)
			f.BackgroundTransparency=1; f.BorderSizePixel=0; f.Size=UDim2.new(1,0,0,22)
			local l2=lbl(f,opts.text,12,opts.color or Library.Theme.TextSecondary); pad(l2,0,0,0,4); return f
		end

		function Tab:Paragraph(opts)
			opts=validate({title="",text="Paragraph text here.",color=nil},opts)
			local FONT=Font.new("rbxasset://fonts/families/Ubuntu.json")
			local charsPerLine = math.max(1, math.floor(320/7))
			local lines = math.max(1, math.ceil(#opts.text / charsPerLine))
			local bodyH = lines*16 + 6
			local titleH = opts.title~="" and 18 or 0
			local totalH = titleH + bodyH + 14
			local f=base("Paragraph", totalH); pad(f,8,8,8,10)
			local yOff=0
			if opts.title~="" then
				local tl=Instance.new("TextLabel",f)
				tl.BackgroundTransparency=1; tl.BorderSizePixel=0
				tl.TextSize=13; tl.TextXAlignment=Enum.TextXAlignment.Left
				tl.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json",Enum.FontWeight.Bold)
				tl.TextColor3=Library.Theme.TextPrimary; tl.Text=opts.title
				tl.Size=UDim2.new(1,0,0,18); tl.Position=UDim2.new(0,0,0,0)
				yOff=20
			end
			local bl=Instance.new("TextLabel",f)
			bl.BackgroundTransparency=1; bl.BorderSizePixel=0
			bl.TextSize=12; bl.TextXAlignment=Enum.TextXAlignment.Left
			bl.TextWrapped=true; bl.TextTruncate=Enum.TextTruncate.None
			bl.FontFace=FONT
			bl.TextColor3=opts.color or Library.Theme.TextSecondary; bl.Text=opts.text
			bl.Size=UDim2.new(1,0,0,bodyH); bl.Position=UDim2.new(0,0,0,yOff)
			bl:GetPropertyChangedSignal("TextBounds"):Once(function()
				local realH = math.ceil(bl.TextBounds.Y) + titleH + 14
				f.Size=UDim2.new(1,0,0,realH)
				bl.Size=UDim2.new(1,0,0,math.ceil(bl.TextBounds.Y))
			end)
			return f
		end

		function Tab:Badge(opts)
			opts=validate({text="NEW", color=nil, textColor=nil},opts)
			local bgCol  = opts.color     or Library.Theme.Accent
			local txtCol = opts.textColor or Color3.fromRGB(255,255,255)
			local w      = math.max(#opts.text*8+16, 40)
			local f=Instance.new("Frame",Tab._scroll)
			f.BackgroundTransparency=1; f.BorderSizePixel=0; f.Size=UDim2.new(1,0,0,26)
			local pill=Instance.new("Frame",f)
			pill.BackgroundColor3=bgCol; pill.BorderSizePixel=0
			pill.Size=UDim2.new(0,w,0,20); pill.Position=UDim2.new(0,4,0.5,-10); corner(pill,4)
			local bl=Instance.new("TextLabel",pill)
			bl.BackgroundTransparency=1; bl.Size=UDim2.new(1,0,1,0)
			bl.TextSize=11; bl.TextXAlignment=Enum.TextXAlignment.Center
			bl.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json",Enum.FontWeight.Bold)
			bl.TextColor3=txtCol; bl.Text=opts.text
			return f
		end

		function Tab:Image(opts)
			opts=validate({url="",width=nil,height=80,tooltip=""},opts)
			local imgId = resolveIcon(opts.url)
			local h = opts.height or 80
			local f=base("Image", h+8); f.BackgroundTransparency=1; f.BorderSizePixel=0
			f:FindFirstChildOfClass("UIStroke"):Destroy()
			local img=Instance.new("ImageLabel",f)
			img.BackgroundTransparency=1; img.BorderSizePixel=0
			img.Image=imgId.value; img.ScaleType=Enum.ScaleType.Fit
			img.Size=opts.width and UDim2.new(0,opts.width,0,h) or UDim2.new(1,0,0,h)
			img.Position=UDim2.new(0,4,0,4)
			addTooltip(f,opts.tooltip)
			return f
		end

		function Tab:ProgressBar(opts)
			opts=validate({name="Progress",default=0,suffix="%",color=nil,tooltip=""},opts)
			local PB={Value=math.clamp(opts.default,0,100)}
			PB.frame=base("ProgressBar",46); pad(PB.frame,6,10,8,10)
			local nl=lbl(PB.frame,opts.name,13,Library.Theme.TextPrimary); nl.Size=UDim2.new(1,-40,0,18)
			local vl=lbl(PB.frame,tostring(PB.Value)..opts.suffix,12,Library.Theme.TextSecondary,nil,Enum.TextXAlignment.Right)
			vl.AnchorPoint=Vector2.new(1,0); vl.Size=UDim2.new(0,36,0,18); vl.Position=UDim2.new(1,0,0,0)
			local trackF=Instance.new("Frame",PB.frame)
			trackF.BackgroundColor3=Color3.fromRGB(13,13,13); trackF.BorderSizePixel=0
			trackF.AnchorPoint=Vector2.new(0,1); trackF.Size=UDim2.new(1,0,0,7)
			trackF.Position=UDim2.new(0,0,1,0); corner(trackF,4); stroke(trackF,Color3.fromRGB(42,42,42))
			local fillF=Instance.new("Frame",trackF)
			fillF.BackgroundColor3=opts.color or Library.Theme.Accent
			fillF.BorderSizePixel=0; corner(fillF,4)
			fillF.Size=UDim2.new(math.clamp(opts.default/100,0,1),0,1,0)
			addTooltip(PB.frame,opts.tooltip)
			function PB:Set(v)
				v=math.clamp(v,0,100); PB.Value=v
				tw(fillF,{Size=UDim2.new(v/100,0,1,0)},TI_FAST)
				vl.Text=tostring(v)..opts.suffix
			end
			return PB
		end

		function Tab:Button(opts)
			opts=validate({name="Button",description="",tooltip="",badge=nil,badgeColor=nil,callback=function()end},opts)
			local h=opts.description~="" and 46 or 32
			local Btn={}; Btn.frame=base("Button",h); pad(Btn.frame,0,8,0,10)
			local bStroke=Btn.frame:FindFirstChildOfClass("UIStroke")
			local nl=lbl(Btn.frame,opts.name,13,Library.Theme.TextPrimary)
			nl.Size=UDim2.new(1,-26,0,18); nl.Position=UDim2.new(0,0,0,h==46 and 6 or 7)
			if opts.description~="" then
				local dl=lbl(Btn.frame,opts.description,11,Library.Theme.TextSecondary)
				dl.Size=UDim2.new(1,-26,0,14); dl.Position=UDim2.new(0,0,0,26)
			end
			if opts.badge then
				local bpf=Instance.new("Frame",Btn.frame)
				bpf.BackgroundColor3=opts.badgeColor or Color3.fromRGB(255,80,80)
				bpf.BorderSizePixel=0; bpf.AnchorPoint=Vector2.new(1,0.5)
				bpf.Size=UDim2.new(0,math.max(#opts.badge*6+8,24),0,14)
				bpf.Position=UDim2.new(1,-16,0.5,0); corner(bpf,3)
				local bpl=Instance.new("TextLabel",bpf)
				bpl.BackgroundTransparency=1; bpl.Size=UDim2.new(1,0,1,0)
				bpl.TextSize=9; bpl.TextXAlignment=Enum.TextXAlignment.Center
				bpl.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json",Enum.FontWeight.Bold)
				bpl.TextColor3=Color3.fromRGB(255,255,255); bpl.Text=opts.badge
			end
			local arr=Instance.new("ImageLabel",Btn.frame)
			arr.BackgroundTransparency=1; arr.AnchorPoint=Vector2.new(1,0.5)
			arr.Image="rbxassetid://12974428978"; arr.ImageColor3=Library.Theme.TextDisabled
			arr.Size=UDim2.new(0,11,0,11); arr.Position=UDim2.new(1,0,0.5,0); arr.Rotation=-90
			addTooltip(Btn.frame,opts.tooltip)
			Btn.frame.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 then opts.callback() end
			end)
			Btn.frame.MouseEnter:Connect(function()
				tw(Btn.frame,{BackgroundColor3=Library.Theme.SurfaceHover}); tw(bStroke,{Color=Library.Theme.BorderHover})
			end)
			Btn.frame.MouseLeave:Connect(function()
				tw(Btn.frame,{BackgroundColor3=Library.Theme.Surface}); tw(bStroke,{Color=Library.Theme.Border})
			end)
			return Btn
		end

		function Tab:Toggle(opts)
			opts=validate({name="Toggle",description="",tooltip="",default=false,callback=function()end},opts)
			local h=opts.description~="" and 46 or 32
			local Toggle={Value=opts.default}
			Toggle.frame=base("Toggle",h); pad(Toggle.frame,0,8,0,10)
			local nl=lbl(Toggle.frame,opts.name,13,Library.Theme.TextPrimary)
			nl.Size=UDim2.new(1,-38,0,18); nl.Position=UDim2.new(0,0,0,h==46 and 6 or 7)
			if opts.description~="" then
				local dl=lbl(Toggle.frame,opts.description,11,Library.Theme.TextSecondary)
				dl.Size=UDim2.new(1,-38,0,14); dl.Position=UDim2.new(0,0,0,26)
			end
			local pill=Instance.new("Frame",Toggle.frame)
			pill.BackgroundColor3=opts.default and Library.Theme.Accent or Color3.fromRGB(48,48,48)
			pill.BorderSizePixel=0; pill.AnchorPoint=Vector2.new(1,0.5)
			pill.Size=UDim2.new(0,30,0,16); pill.Position=UDim2.new(1,0,0.5,0); corner(pill,8)
			local knob=Instance.new("Frame",pill)
			knob.BackgroundColor3=Color3.fromRGB(215,215,215); knob.BorderSizePixel=0
			knob.AnchorPoint=Vector2.new(0,0.5); knob.Size=UDim2.new(0,12,0,12)
			knob.Position=opts.default and UDim2.new(1,-14,0.5,0) or UDim2.new(0,2,0.5,0)
			corner(knob,6); addTooltip(Toggle.frame,opts.tooltip)
			Toggle.frame.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 then
					Toggle.Value=not Toggle.Value
					tw(pill,{BackgroundColor3=Toggle.Value and Library.Theme.Accent or Color3.fromRGB(48,48,48)})
					tw(knob,{Position=Toggle.Value and UDim2.new(1,-14,0.5,0) or UDim2.new(0,2,0.5,0)})
					opts.callback(Toggle.Value)
				end
			end)
			function Toggle:Set(v, silent)
				Toggle.Value=v
				tw(pill,{BackgroundColor3=v and Library.Theme.Accent or Color3.fromRGB(48,48,48)})
				tw(knob,{Position=v and UDim2.new(1,-14,0.5,0) or UDim2.new(0,2,0.5,0)})
				if not silent then opts.callback(v) end
			end
			return Toggle
		end

		function Tab:Slider(opts)
			opts=validate({name="Slider",tooltip="",min=0,max=100,default=50,suffix="",callback=function()end},opts)
			local Slider={Value=opts.default,Dragging=false}
			Slider.frame=base("Slider",50); pad(Slider.frame,6,10,9,10)
			local nl=lbl(Slider.frame,opts.name,13,Library.Theme.TextPrimary); nl.Size=UDim2.new(1,-45,0,18)
			local vl=lbl(Slider.frame,tostring(opts.default)..opts.suffix,12,Library.Theme.TextSecondary,nil,Enum.TextXAlignment.Right)
			vl.AnchorPoint=Vector2.new(1,0); vl.Size=UDim2.new(0,42,0,18); vl.Position=UDim2.new(1,0,0,0)
			local track=Instance.new("Frame",Slider.frame)
			track.BackgroundColor3=Color3.fromRGB(13,13,13); track.BorderSizePixel=0
			track.AnchorPoint=Vector2.new(0,1); track.Size=UDim2.new(1,0,0,5)
			track.Position=UDim2.new(0,0,1,0); corner(track,3); stroke(track,Color3.fromRGB(42,42,42))
			local fill=Instance.new("Frame",track)
			fill.BackgroundColor3=Library.Theme.Accent; fill.BorderSizePixel=0
			fill.Size=UDim2.new((opts.default-opts.min)/(opts.max-opts.min),0,1,0); corner(fill,3)
			local thumb=Instance.new("Frame",track)
			thumb.BackgroundColor3=Color3.fromRGB(225,225,225); thumb.BorderSizePixel=0
			thumb.AnchorPoint=Vector2.new(0.5,0.5); thumb.Size=UDim2.new(0,10,0,10)
			thumb.Position=UDim2.new((opts.default-opts.min)/(opts.max-opts.min),0,0.5,0); corner(thumb,5)
			addTooltip(Slider.frame,opts.tooltip)
			local function upd(x)
				local a=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
				Slider.Value=math.floor(opts.min+(opts.max-opts.min)*a)
				fill.Size=UDim2.new(a,0,1,0); thumb.Position=UDim2.new(a,0,0.5,0)
				vl.Text=tostring(Slider.Value)..opts.suffix; opts.callback(Slider.Value)
			end
			track.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
					Slider.Dragging=true; upd(i.Position.X)
				end
			end)
			local c1=UIS.InputChanged:Connect(function(i)
				if Slider.Dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end
			end)
			local c2=UIS.InputEnded:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then Slider.Dragging=false end
			end)
			Slider.frame.AncestryChanged:Connect(function()
				if not Slider.frame:IsDescendantOf(game) then c1:Disconnect(); c2:Disconnect() end
			end)
			function Slider:Set(v, silent)
				v=math.clamp(v, opts.min, opts.max)
				local a=math.clamp((v-opts.min)/(opts.max-opts.min),0,1)
				Slider.Value=v; fill.Size=UDim2.new(a,0,1,0)
				thumb.Position=UDim2.new(a,0,0.5,0); vl.Text=tostring(v)..opts.suffix
				if not silent then opts.callback(v) end
			end
			return Slider
		end

		function Tab:Dropdown(opts)
			opts=validate({name="Dropdown",tooltip="",items={},default=nil,multi=false,callback=function()end},opts)
			local DD={Open=false,Selected=opts.default,Multi={}}
			DD.frame=base("Dropdown",32); DD.frame.ClipsDescendants=true
			DD.frame.BackgroundTransparency=1; DD.frame:FindFirstChildOfClass("UIStroke"):Destroy()
			local header=Instance.new("TextButton",DD.frame)
			header.Name="DDHeader"; header.AutoButtonColor=false
			header.BackgroundColor3=Library.Theme.Surface; header.BorderSizePixel=0
			header.Size=UDim2.new(1,0,0,32); header.Position=UDim2.new(0,0,0,0)
			header.Text=""; header.ZIndex=2; corner(header,5); stroke(header,Library.Theme.Border)
			local selLbl=lbl(header,opts.default or opts.name,13,Library.Theme.TextPrimary)
			selLbl.Size=UDim2.new(1,-20,1,0); selLbl.ZIndex=3; pad(selLbl,0,0,0,10)
			local arrowImg=Instance.new("ImageLabel",header)
			arrowImg.BackgroundTransparency=1; arrowImg.AnchorPoint=Vector2.new(1,0.5)
			arrowImg.Image="rbxassetid://12974428978"; arrowImg.ImageColor3=Library.Theme.TextSecondary
			arrowImg.Size=UDim2.new(0,13,0,13); arrowImg.Position=UDim2.new(1,-8,0.5,0); arrowImg.ZIndex=3
			addTooltip(header,opts.tooltip)
			local optHolder=Instance.new("Frame",DD.frame)
			optHolder.BackgroundTransparency=1; optHolder.BorderSizePixel=0
			optHolder.Size=UDim2.new(1,0,0,0); optHolder.Position=UDim2.new(0,0,0,34)
			optHolder.Visible=false; optHolder.ZIndex=4
			local ol=Instance.new("UIListLayout",optHolder)
			ol.Padding=UDim.new(0,3); ol.SortOrder=Enum.SortOrder.LayoutOrder
			local function refresh()
				for _,c in ipairs(optHolder:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
				local total=0
				for _,item in ipairs(opts.items) do
					local isSel=(opts.multi and DD.Multi[item]) or (not opts.multi and DD.Selected==item)
					local opt=Instance.new("TextButton",optHolder)
					opt.AutoButtonColor=false; opt.BorderSizePixel=0
					opt.BackgroundColor3=isSel and Color3.fromRGB(52,52,52) or Color3.fromRGB(32,32,32)
					opt.TextSize=12; opt.TextXAlignment=Enum.TextXAlignment.Left
					opt.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json")
					opt.TextColor3=isSel and Library.Theme.TextPrimary or Library.Theme.TextSecondary
					opt.Size=UDim2.new(1,0,0,22); opt.Text=item; opt.ZIndex=5
					corner(opt,3); stroke(opt,isSel and Library.Theme.BorderHover or Library.Theme.Border); pad(opt,0,0,0,8)
					opt.MouseEnter:Connect(function()
						local nowSel=(opts.multi and DD.Multi[item]) or (not opts.multi and DD.Selected==item)
						if not nowSel then tw(opt,{BackgroundColor3=Color3.fromRGB(42,42,42),TextColor3=Library.Theme.TextPrimary}) end
					end)
					opt.MouseLeave:Connect(function()
						local nowSel=(opts.multi and DD.Multi[item]) or (not opts.multi and DD.Selected==item)
						if not nowSel then tw(opt,{BackgroundColor3=Color3.fromRGB(32,32,32),TextColor3=Library.Theme.TextSecondary}) end
					end)
					opt.MouseButton1Click:Connect(function()
						if opts.multi then
							DD.Multi[item]=not DD.Multi[item]
							local s={}; for k,v in pairs(DD.Multi) do if v then table.insert(s,k) end end
							selLbl.Text=#s>0 and table.concat(s,", ") or opts.name; opts.callback(s); refresh()
						else
							DD.Selected=item; selLbl.Text=item; opts.callback(item)
							DD.Open=false; optHolder.Visible=false; tw(arrowImg,{Rotation=0})
							DD.frame.Size=UDim2.new(1,0,0,32); refresh()
						end
					end)
					total=total+25
				end
				optHolder.Size=UDim2.new(1,0,0,total)
				DD.frame.Size=UDim2.new(1,0,0,DD.Open and (34+total+4) or 32)
			end
			header.MouseButton1Click:Connect(function()
				DD.Open=not DD.Open; optHolder.Visible=DD.Open
				tw(arrowImg,{Rotation=DD.Open and 180 or 0})
				if DD.Open then refresh() else DD.frame.Size=UDim2.new(1,0,0,32) end
			end)
			refresh()
			function DD:Set(v) DD.Selected=v; selLbl.Text=v; refresh() end
			function DD:SetItems(newItems)
				opts.items=newItems; DD.Selected=nil; selLbl.Text=opts.name
				if DD.Open then refresh() end
			end
			return DD
		end

		function Tab:TextInput(opts)
			opts=validate({name="Input",placeholder="Type here...",tooltip="",default="",numeric=false,callback=function()end},opts)
			local TIc={Value=opts.default}
			TIc.frame=base("TextInput",48); pad(TIc.frame,5,8,5,10)
			local nl=lbl(TIc.frame,opts.name,12,Library.Theme.TextSecondary); nl.Size=UDim2.new(1,0,0,15)
			local ibg=Instance.new("Frame",TIc.frame)
			ibg.BackgroundColor3=Color3.fromRGB(17,17,17); ibg.BorderSizePixel=0
			ibg.AnchorPoint=Vector2.new(0,1); ibg.Size=UDim2.new(1,0,0,22); ibg.Position=UDim2.new(0,0,1,0); corner(ibg,3)
			local ibStroke=stroke(ibg,Library.Theme.Border)
			local box=Instance.new("TextBox",ibg)
			box.BackgroundTransparency=1; box.BorderSizePixel=0
			box.TextSize=12; box.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json")
			box.TextColor3=Library.Theme.TextPrimary
			box.PlaceholderText=opts.placeholder; box.PlaceholderColor3=Library.Theme.TextDisabled
			box.Text=opts.default; box.ClearTextOnFocus=false
			box.Size=UDim2.new(1,-8,1,0); box.Position=UDim2.new(0,6,0,0); box.TextXAlignment=Enum.TextXAlignment.Left
			box.Focused:Connect(function() tw(ibStroke,{Color=Library.Theme.Accent}) end)
			box.FocusLost:Connect(function()
				tw(ibStroke,{Color=Library.Theme.Border})
				if opts.numeric then local n=tonumber(box.Text); box.Text=n and tostring(n) or opts.default end
				TIc.Value=box.Text; opts.callback(box.Text)
			end)
			addTooltip(TIc.frame,opts.tooltip)
			function TIc:Set(v) box.Text=tostring(v); TIc.Value=tostring(v) end
			return TIc
		end

		function Tab:ColorPicker(opts)
			opts=validate({name="Color",tooltip="",default=Color3.fromRGB(255,100,100),callback=function()end},opts)
			local CP={Value=opts.default,Open=false}
			CP.frame=base("ColorPicker",32); CP.frame.ClipsDescendants=true; pad(CP.frame,0,8,0,10)
			local header=Instance.new("TextButton",CP.frame)
			header.BackgroundTransparency=1; header.BorderSizePixel=0
			header.Size=UDim2.new(1,0,0,32); header.Position=UDim2.new(0,0,0,0)
			header.Text=""; header.AutoButtonColor=false; header.ZIndex=5
			local nl=lbl(CP.frame,opts.name,13,Library.Theme.TextPrimary); nl.Size=UDim2.new(1,-34,0,32); nl.ZIndex=4
			local preview=Instance.new("Frame",CP.frame)
			preview.BackgroundColor3=opts.default; preview.BorderSizePixel=0
			preview.AnchorPoint=Vector2.new(1,0); preview.Size=UDim2.new(0,24,0,16)
			preview.Position=UDim2.new(1,0,0,8); preview.ZIndex=4; corner(preview,3); stroke(preview,Library.Theme.Border)
			addTooltip(CP.frame,opts.tooltip)
			local picker=Instance.new("Frame",CP.frame)
			picker.BackgroundColor3=Color3.fromRGB(20,20,20); picker.BorderSizePixel=0
			picker.Size=UDim2.new(1,0,0,82); picker.Position=UDim2.new(0,0,0,32)
			picker.Visible=false; corner(picker,4); pad(picker,6,8,6,8)
			local pL=Instance.new("UIListLayout",picker)
			pL.Padding=UDim.new(0,4); pL.SortOrder=Enum.SortOrder.LayoutOrder
			local h_v,s_v,v_v=Color3.toHSV(opts.default)
			local function rebuild()
				local c=Color3.fromHSV(h_v,s_v,v_v)
				CP.Value=c; preview.BackgroundColor3=c; opts.callback(c)
			end
			local _hsvConns={}
			local function makeHSVSlider(name,init,cb)
				local row=Instance.new("Frame",picker)
				row.BackgroundTransparency=1; row.BorderSizePixel=0; row.Size=UDim2.new(1,0,0,17)
				local rl=lbl(row,name,10,Library.Theme.TextSecondary); rl.Size=UDim2.new(0,12,1,0)
				local tr=Instance.new("Frame",row)
				tr.BackgroundColor3=Color3.fromRGB(13,13,13); tr.BorderSizePixel=0
				tr.AnchorPoint=Vector2.new(0,0.5); tr.Size=UDim2.new(1,-18,0,5); tr.Position=UDim2.new(0,16,0.5,0); corner(tr,2)
				local fl=Instance.new("Frame",tr)
				fl.BackgroundColor3=Library.Theme.Accent; fl.BorderSizePixel=0; fl.Size=UDim2.new(init,0,1,0); corner(fl,2)
				local drag2=false
				local function upd2(x)
					local a=math.clamp((x-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
					fl.Size=UDim2.new(a,0,1,0); cb(a); rebuild()
				end
				tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag2=true; upd2(i.Position.X) end end)
				local ca=UIS.InputChanged:Connect(function(i) if drag2 and i.UserInputType==Enum.UserInputType.MouseMovement then upd2(i.Position.X) end end)
				local cb2=UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag2=false end end)
				table.insert(_hsvConns,ca); table.insert(_hsvConns,cb2)
			end
			makeHSVSlider("H",h_v,function(a) h_v=a end)
			makeHSVSlider("S",s_v,function(a) s_v=a end)
			makeHSVSlider("V",v_v,function(a) v_v=a end)
			CP.frame.AncestryChanged:Connect(function()
				if not CP.frame:IsDescendantOf(game) then
					for _,c in ipairs(_hsvConns) do pcall(function() c:Disconnect() end) end
				end
			end)
			header.MouseButton1Click:Connect(function()
				CP.Open=not CP.Open; picker.Visible=CP.Open
				CP.frame.Size=UDim2.new(1,0,0,CP.Open and 118 or 32)
			end)
			function CP:Set(c) CP.Value=c; preview.BackgroundColor3=c; h_v,s_v,v_v=Color3.toHSV(c) end
			return CP
		end

		function Tab:Keybind(opts)
			opts=validate({name="Keybind",tooltip="",default=Enum.KeyCode.E,callback=function()end},opts)
			local KB={Value=opts.default,Listening=false}
			KB.frame=base("Keybind",32); pad(KB.frame,0,8,0,10)
			local nl=lbl(KB.frame,opts.name,13,Library.Theme.TextPrimary); nl.Size=UDim2.new(1,-72,1,0)
			local kBg=Instance.new("Frame",KB.frame)
			kBg.BackgroundColor3=Color3.fromRGB(18,18,18); kBg.BorderSizePixel=0
			kBg.AnchorPoint=Vector2.new(1,0.5); kBg.Size=UDim2.new(0,62,0,20)
			kBg.Position=UDim2.new(1,0,0.5,0); corner(kBg,3); stroke(kBg,Library.Theme.Border)
			local kLbl=lbl(kBg,opts.default.Name,11,Library.Theme.TextSecondary,nil,Enum.TextXAlignment.Center)
			addTooltip(KB.frame,opts.tooltip)
			kBg.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 then
					KB.Listening=true; keybindListening=true
					kLbl.Text="..."; tw(kBg,{BackgroundColor3=Color3.fromRGB(28,28,28)})
				end
			end)
			track(UIS.InputBegan:Connect(function(i,gpe)
				if not KB.Listening then return end
				if i.UserInputType==Enum.UserInputType.Keyboard then
					KB.Listening=false; keybindListening=false
					KB.Value=i.KeyCode; kLbl.Text=i.KeyCode.Name
					tw(kBg,{BackgroundColor3=Color3.fromRGB(18,18,18)}); opts.callback(i.KeyCode)
				end
			end))
			function KB:Set(k) KB.Value=k; kLbl.Text=k.Name end
			return KB
		end

		function Tab:Warning(opts)
			opts=validate({text="Warning"},opts)
			local f=base("Warning",28); f.BackgroundColor3=Color3.fromRGB(25,20,4)
			f:FindFirstChildOfClass("UIStroke").Color=Color3.fromRGB(62,52,0); pad(f,0,8,0,10)
			local l2=lbl(f,opts.text,12,Color3.fromRGB(215,195,120)); l2.Size=UDim2.new(1,0,1,0); pad(l2,0,0,0,20)
			local ic=Instance.new("ImageLabel",f); ic.BackgroundTransparency=1
			ic.ImageColor3=Color3.fromRGB(220,185,0); ic.AnchorPoint=Vector2.new(0,0.5)
			ic.Image="rbxassetid://11419713314"; ic.Size=UDim2.new(0,14,0,14); ic.Position=UDim2.new(0,0,0.5,0)
			return f
		end

		function Tab:Info(opts)
			opts=validate({text="Info"},opts)
			local f=base("Info",28); f.BackgroundColor3=Color3.fromRGB(0,18,28)
			f:FindFirstChildOfClass("UIStroke").Color=Color3.fromRGB(0,46,70); pad(f,0,8,0,10)
			local l2=lbl(f,opts.text,12,Color3.fromRGB(148,200,224)); l2.Size=UDim2.new(1,0,1,0); pad(l2,0,0,0,20)
			local ic=Instance.new("ImageLabel",f); ic.BackgroundTransparency=1
			ic.ImageColor3=Color3.fromRGB(0,165,215); ic.AnchorPoint=Vector2.new(0,0.5)
			ic.Image="rbxassetid://11422155687"; ic.Size=UDim2.new(0,14,0,14); ic.Position=UDim2.new(0,0,0.5,0)
			return f
		end

		-- ── NEW: Tab:Success ─────────────────────────────────────────────────────────
		function Tab:Success(opts)
			opts=validate({text="Success!"},opts)
			local f=base("Success",28); f.BackgroundColor3=Color3.fromRGB(8,28,14)
			f:FindFirstChildOfClass("UIStroke").Color=Color3.fromRGB(0,70,30); pad(f,0,8,0,10)
			local l2=lbl(f,opts.text,12,Color3.fromRGB(80,210,120))
			l2.Size=UDim2.new(1,0,1,0); pad(l2,0,0,0,20)
			local ic=Instance.new("ImageLabel",f); ic.BackgroundTransparency=1
			ic.ImageColor3=Color3.fromRGB(60,200,100); ic.AnchorPoint=Vector2.new(0,0.5)
			ic.Image="rbxassetid://11419709766"; ic.Size=UDim2.new(0,14,0,14); ic.Position=UDim2.new(0,0,0.5,0)
			return f
		end

		-- ── NEW: Tab:Divider ──────────────────────────────────────────────────────────
		-- A thin horizontal rule with optional centered label
		function Tab:Divider(opts)
			opts=validate({text="",color=nil},opts)
			local h = opts.text~="" and 20 or 5
			local f=Instance.new("Frame",Tab._scroll)
			f.Name="Divider"; f.BackgroundTransparency=1; f.BorderSizePixel=0
			f.Size=UDim2.new(1,0,0,h)
			local line=Instance.new("Frame",f)
			line.BackgroundColor3=opts.color or Library.Theme.Border
			line.BorderSizePixel=0; line.AnchorPoint=Vector2.new(0,0.5)
			line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,0.5,0)
			if opts.text~="" then
				local bg=Instance.new("Frame",f)
				bg.BackgroundColor3=Library.Theme.Surface; bg.BorderSizePixel=0
				bg.AnchorPoint=Vector2.new(0.5,0.5)
				bg.Position=UDim2.new(0.5,0,0.5,0)
				bg.Size=UDim2.new(0,#opts.text*7+14,1,0)
				local dl=lbl(bg,opts.text,10,opts.color or Library.Theme.TextDisabled,
					Font.new("rbxasset://fonts/families/Ubuntu.json",Enum.FontWeight.Bold))
				dl.TextXAlignment=Enum.TextXAlignment.Center
			end
			return f
		end

		function Tab:Hyperlink(opts)
			opts=validate({text="Link",url="",tooltip=""},opts)
			local f=base("Hyperlink",32); pad(f,0,8,0,10)
			local bStroke=f:FindFirstChildOfClass("UIStroke")
			local ic=Instance.new("ImageLabel",f); ic.BackgroundTransparency=1
			ic.ImageColor3=Library.Theme.Accent; ic.AnchorPoint=Vector2.new(0,0.5)
			ic.Image="rbxassetid://11422141677"; ic.Size=UDim2.new(0,13,0,13); ic.Position=UDim2.new(0,0,0.5,0)
			local nl=lbl(f,opts.text,13,Library.Theme.Accent)
			nl.Size=UDim2.new(1,-44,1,0); nl.Position=UDim2.new(0,18,0,0)
			local tag=Instance.new("TextLabel",f)
			tag.BackgroundTransparency=1; tag.AnchorPoint=Vector2.new(1,0.5)
			tag.Size=UDim2.new(0,38,0,16); tag.Position=UDim2.new(1,0,0.5,0)
			tag.TextSize=10; tag.TextXAlignment=Enum.TextXAlignment.Right
			tag.FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json")
			tag.TextColor3=Library.Theme.TextDisabled; tag.Text="copy"
			addTooltip(f, opts.tooltip~="" and opts.tooltip or opts.url)
			f.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 then
					pcall(function() setclipboard(opts.url) end)
					tag.TextColor3=Color3.fromRGB(60,200,90); tag.Text="copied!"
					task.delay(2,function()
						pcall(function() tag.TextColor3=Library.Theme.TextDisabled; tag.Text="copy" end)
					end)
				end
			end)
			f.MouseEnter:Connect(function()
				tw(f,{BackgroundColor3=Library.Theme.SurfaceHover}); tw(bStroke,{Color=Library.Theme.BorderHover})
				tw(nl,{TextColor3=Color3.fromRGB(180,200,255)})
			end)
			f.MouseLeave:Connect(function()
				tw(f,{BackgroundColor3=Library.Theme.Surface}); tw(bStroke,{Color=Library.Theme.Border})
				tw(nl,{TextColor3=Library.Theme.Accent})
			end)
			return f
		end

		return Tab
	end -- GUI:CreateTab

	-- ══════════════════════════════════════════════════════════════════════
	-- Config save / load
	-- ══════════════════════════════════════════════════════════════════════
	local _cfgFolder = "VenturaUI"
	local _cfgFile   = _cfgFolder .. "/" .. options.name:gsub("[^%w%-%_]","_") .. ".json"

	local THEMES = {
		Dark    = { bg=Color3.fromRGB(22,22,22),  nav=Color3.fromRGB(18,18,18),  top=Color3.fromRGB(16,16,16),  ub=Color3.fromRGB(20,20,20) },
		Crimson = { bg=Color3.fromRGB(42,18,18),  nav=Color3.fromRGB(34,12,12),  top=Color3.fromRGB(30,10,10),  ub=Color3.fromRGB(38,14,14) },
		Magenta = { bg=Color3.fromRGB(36,16,38),  nav=Color3.fromRGB(28,10,30),  top=Color3.fromRGB(24,8,26),   ub=Color3.fromRGB(32,12,34) },
		Teal    = { bg=Color3.fromRGB(14,34,34),  nav=Color3.fromRGB(10,26,26),  top=Color3.fromRGB(8,22,22),   ub=Color3.fromRGB(12,30,30) },
	}

	local function _applyTheme(val)
		local t = THEMES[val]; if not t then return end
		tw(Main,    { BackgroundColor3 = t.bg  }, TI_SLOW)
		tw(Nav,     { BackgroundColor3 = t.nav }, TI_SLOW)
		tw(Topbar,  { BackgroundColor3 = t.top }, TI_SLOW)
		tw(UserBox, { BackgroundColor3 = t.ub  }, TI_SLOW)
		tw(userSep, { BackgroundColor3 = t.nav }, TI_SLOW)
		tw(_mainStroke, { Color = Library.Theme.Border }, TI_SLOW)
		for _, p in ipairs(navPatches) do tw(p, { BackgroundColor3 = t.nav }, TI_SLOW) end
		Library.Theme.Background = t.bg
		Library.Theme.Nav        = t.nav
		Library.Theme.Topbar     = t.top
		GUI._savedTheme = val
	end

	local function _c3ToHex(c)
		return string.format("%02X%02X%02X",
			math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
	end
	local function _hexToC3(h)
		h = (h or ""):gsub("#","")
		if #h < 6 then return Library.Theme.Accent end
		return Color3.fromRGB(
			tonumber(h:sub(1,2),16) or 0,
			tonumber(h:sub(3,4),16) or 0,
			tonumber(h:sub(5,6),16) or 0)
	end
	local function _encodeConfig(t)
		local lines = {}
		for k,v in pairs(t) do
			if type(v) == "string" then
				table.insert(lines, k .. "=" .. v)
			else
				table.insert(lines, k .. "=" .. tostring(v))
			end
		end
		table.sort(lines)
		return table.concat(lines, "\n")
	end
	local function _decodeConfig(s)
		local t = {}
		for line in (s.."\n"):gmatch("([^\n]*)\n") do
			local k, v = line:match("^([^=]+)=(.*)$")
			if k and v then
				k = k:match("^%s*(.-)%s*$"); v = v:match("^%s*(.-)%s*$")
				if v == "true" then t[k] = true
				elseif v == "false" then t[k] = false
				elseif tonumber(v) then t[k] = tonumber(v)
				else t[k] = v end
			end
		end
		return t
	end

	function GUI:SaveConfig()
		local ok, err = pcall(function()
			if not isfolder(_cfgFolder) then makefolder(_cfgFolder) end
			local data = _encodeConfig({
				accent    = _c3ToHex(Library.Theme.Accent),
				theme     = GUI._savedTheme or "Dark",
				scale     = currentScale,
				winW      = math.floor(winW),
				winH      = math.floor(winH),
				toggleKey = keys.toggle.Name,
				minKey    = keys.minimize.Name,
			})
			writefile(_cfgFile, data)
		end)
		if not ok then warn("[VenturaUI] SaveConfig failed: " .. tostring(err)) end
	end

	function GUI:LoadConfig()
		local ok, raw = pcall(readfile, _cfgFile)
		if not ok or not raw or raw == "" then return nil end
		local ok2, data = pcall(_decodeConfig, raw)
		if not ok2 or not data or not next(data) then return nil end
		return data
	end

	GUI._cfgSyncCallbacks = {}

	function GUI:ApplyConfig(data)
		if not data then return end
		if data.theme and THEMES[data.theme] then
			_applyTheme(data.theme)
			if GUI._cfgSyncCallbacks.theme then pcall(GUI._cfgSyncCallbacks.theme, data.theme) end
		end
		if data.accent then
			local c = _hexToC3(data.accent)
			Library.Theme.Accent = c
			accentLine.BackgroundColor3 = c
			if GUI._cfgSyncCallbacks.accent then pcall(GUI._cfgSyncCallbacks.accent, c) end
		end
		if data.winW and data.winH then
			winW = math.clamp(tonumber(data.winW) or winW, WIN_MIN_W, WIN_MAX_W)
			winH = math.clamp(tonumber(data.winH) or winH, WIN_MIN_H, WIN_MAX_H)
			Main.Size = UDim2.new(0, winW, 0, winH)
		elseif data.scale then
			currentScale = tonumber(data.scale) or 100
			local sw = winW*(currentScale/100); local sh = winH*(currentScale/100)
			Main.Size = UDim2.new(0,sw,0,sh)
		end
		if data.scale then
			currentScale = tonumber(data.scale) or 100
			if GUI._cfgSyncCallbacks.scale then pcall(GUI._cfgSyncCallbacks.scale, currentScale) end
		end
		if data.toggleKey then
			local ok, k = pcall(function() return Enum.KeyCode[data.toggleKey] end)
			if ok and k and k ~= Enum.KeyCode.Unknown then keys.toggle = k end
		end
		if data.minKey then
			local ok, k = pcall(function() return Enum.KeyCode[data.minKey] end)
			if ok and k and k ~= Enum.KeyCode.Unknown then keys.minimize = k end
		end
	end

	task.delay(0.5, function()
		local data = GUI:LoadConfig()
		if data then GUI:ApplyConfig(data) end
	end)

	-- ══════════════════════════════════════════════════════════════════════
	-- AI Assistant tab (FIXED: now properly inside Library:new)
	-- ══════════════════════════════════════════════════════════════════════
	if options.aiEnabled then
		task.defer(function()
			local HS    = game:GetService("HttpService")
			local _busy = false
			local _cooldownUntil = 0  -- tick() time when cooldown expires
			local _history = {}
			local _msgN    = 0

			local AI = GUI:CreateTab({ name = "AI", icon = "🤖" })

			AI:Paragraph({
				title = "AI Assistant",
				text  = "Ask anything about Roblox scripting, exploiting, or VenturaUI. "
					.. "Free — no key or signup needed.",
			})

			AI:Separator()

			local tabList = AI._scroll

			local wrapper = Instance.new("Frame")
			wrapper.Name                = "AIChatWrapper"
			wrapper.BackgroundTransparency = 1
			wrapper.Size               = UDim2.new(1, -8, 0, 190)
			wrapper.BorderSizePixel    = 0
			wrapper.LayoutOrder        = 9000
			wrapper.Parent             = tabList

			local chatScroll = Instance.new("ScrollingFrame")
			chatScroll.Name                 = "AIChat"
			chatScroll.BackgroundColor3     = Library.Theme.Nav
			chatScroll.BorderSizePixel      = 0
			chatScroll.Size                 = UDim2.new(1, 0, 1, 0)
			chatScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
			chatScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
			chatScroll.ScrollBarThickness   = 2
			chatScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
			chatScroll.ClipsDescendants     = true
			chatScroll.Parent               = wrapper
			Instance.new("UICorner", chatScroll).CornerRadius = UDim.new(0, 6)

			local chatList = Instance.new("UIListLayout", chatScroll)
			chatList.Padding       = UDim.new(0, 5)
			chatList.SortOrder     = Enum.SortOrder.LayoutOrder
			chatList.FillDirection = Enum.FillDirection.Vertical

			local chatPad = Instance.new("UIPadding", chatScroll)
			chatPad.PaddingTop    = UDim.new(0, 6)
			chatPad.PaddingBottom = UDim.new(0, 6)
			chatPad.PaddingLeft   = UDim.new(0, 7)
			chatPad.PaddingRight  = UDim.new(0, 7)

			local function _bubble(role, text)
				_msgN = _msgN + 1
				local isUser = (role == "user")
				local row = Instance.new("Frame", chatScroll)
				row.BackgroundTransparency = 1
				row.BorderSizePixel        = 0
				row.Size                   = UDim2.new(1, 0, 0, 0)
				row.AutomaticSize          = Enum.AutomaticSize.Y
				row.LayoutOrder            = _msgN
				local bub = Instance.new("TextLabel", row)
				bub.BackgroundColor3  = isUser and Library.Theme.Accent or Library.Theme.Surface
				bub.BorderSizePixel   = 0
				bub.TextWrapped       = true
				bub.RichText          = false
				bub.TextSize          = 11
				bub.TextXAlignment    = Enum.TextXAlignment.Left
				bub.TextYAlignment    = Enum.TextYAlignment.Top
				bub.FontFace          = Font.new("rbxasset://fonts/families/Ubuntu.json")
				bub.TextColor3        = isUser and Color3.fromRGB(255,255,255) or Library.Theme.TextPrimary
				bub.Text              = (isUser and "You: " or "AI: ") .. tostring(text)
				bub.AutomaticSize     = Enum.AutomaticSize.Y
				bub.Size              = UDim2.new(0.84, 0, 0, 0)
				bub.AnchorPoint       = Vector2.new(isUser and 1 or 0, 0)
				bub.Position          = UDim2.new(isUser and 1 or 0, isUser and -4 or 4, 0, 0)
				local bPad = Instance.new("UIPadding", bub)
				bPad.PaddingTop    = UDim.new(0, 5)
				bPad.PaddingBottom = UDim.new(0, 5)
				bPad.PaddingLeft   = UDim.new(0, 7)
				bPad.PaddingRight  = UDim.new(0, 7)
				Instance.new("UICorner", bub).CornerRadius = UDim.new(0, 6)
				task.defer(function()
					pcall(function()
						chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
					end)
				end)
				return bub
			end

			local function _send(userText)
				userText = tostring(userText or ""):match("^%s*(.-)%s*$")
				if userText == "" then return end
				if _busy then
					GUI.notify("AI", "Still waiting for a reply...", 2)
					return
				end
				local remaining = math.ceil(_cooldownUntil - tick())
				if remaining > 0 then
					GUI.notify("AI", "Please wait " .. remaining .. "s before next message.", 2)
					return
				end
				_busy = true
				table.insert(_history, { role = "user", content = userText })
				_bubble("user", userText)
				local thinkBub = _bubble("assistant", "...")
				task.spawn(function()
					-- Build message history
					local contextMsgs = {}
					for _, m in ipairs(_history) do
						table.insert(contextMsgs, m.role .. ": " .. m.content)
					end
					local context = table.concat(contextMsgs, "\n")

					local systemPrompt = "You are a helpful Roblox scripting assistant inside VenturaUI. "
						.. "Answer questions about Roblox Lua, game development, exploiting, and VenturaUI. "
						.. "Be concise and use plain text only, no markdown."

					local fullPrompt = systemPrompt .. "\n\nConversation so far:\n" .. context

					-- Executor-compatible HTTP
					local function httpReq(opts)
						if syn and syn.request then return syn.request(opts)
						elseif request then return request(opts)
						elseif http and http.request then return http.request(opts)
						elseif http_request then return http_request(opts)
						else return HS:RequestAsync(opts) end
					end

					-- URL encode
					local function enc(s)
						return s:gsub("[^%w%-%.%_%~]", function(c)
							return string.format("%%%02X", string.byte(c))
						end)
					end

					-- Get body if response is success
					local function getBody(ok, res)
						if not ok or not res then return nil end
						local body = res.Body or res.body or ""
						local status = res.StatusCode or res.status_code or 0
						if (res.Success or res.success or status == 200) and body ~= "" then
							return body
						end
						return nil
					end

					local reply = ""

					-- Provider 1: Pollinations openai (JSON, more reliable than plain GET)
					if reply == "" then
						local ok1, res1 = pcall(httpReq, {
							Url    = "https://text.pollinations.ai/openai",
							Method = "POST",
							Headers = { ["Content-Type"] = "application/json" },
							Body = HS:JSONEncode({
								model    = "openai",
								private  = true,
								messages = {
									{ role = "system", content = systemPrompt },
									{ role = "user",   content = context },
								},
							}),
						})
						local b1 = getBody(ok1, res1)
						if b1 then
							local ok2, data = pcall(HS.JSONDecode, HS, b1)
							if ok2 and data and data.choices and data.choices[1] then
								reply = (data.choices[1].message or {}).content or ""
							end
						end
					end

					-- Provider 2: Pollinations plain GET with mistral model
					if reply == "" then
						local ok3, res3 = pcall(httpReq, {
							Url    = "https://text.pollinations.ai/" .. enc(fullPrompt) .. "?model=mistral&private=true",
							Method = "GET",
						})
						local b3 = getBody(ok3, res3)
						if b3 then reply = b3:match("^%s*(.-)%s*$") end
					end

					-- Provider 3: Pollinations plain GET default model
					if reply == "" then
						local ok4, res4 = pcall(httpReq, {
							Url    = "https://text.pollinations.ai/" .. enc(fullPrompt),
							Method = "GET",
						})
						local b4 = getBody(ok4, res4)
						if b4 then reply = b4:match("^%s*(.-)%s*$") end
					end

					if reply == "" then
						reply = "AI is busy right now, try again in a moment!"
					end

					pcall(function() thinkBub.Text = "AI: " .. reply end)
					if not reply:find("^AI is busy") then
						table.insert(_history, { role = "assistant", content = reply })
					end
					while #_history > 20 do table.remove(_history, 1) end

					-- Start 15s cooldown to respect rate limits
					local COOLDOWN = 15
					_cooldownUntil = tick() + COOLDOWN
					local cdBub = _bubble("assistant", "⏳ Next message in " .. COOLDOWN .. "s...")
					task.spawn(function()
						for t = COOLDOWN, 1, -1 do
							pcall(function() cdBub.Text = "⏳ Next message in " .. t .. "s..." end)
							task.wait(1)
						end
						pcall(function() cdBub.Text = "✓ Ready — send your next message!" end)
					end)

					task.defer(function()
						pcall(function()
							chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
						end)
					end)
					_busy = false
				end)
			end

			AI:TextInput({
				name        = "Message",
				placeholder = "Ask about Roblox scripting or VenturaUI...",
				callback    = _send,
			})

			AI:Button({
				name        = "Clear Chat",
				description = "Wipe all messages and conversation history",
				callback    = function()
					_history = {}; _msgN = 0
					for _, c in ipairs(chatScroll:GetChildren()) do
						if c:IsA("Frame") then c:Destroy() end
					end
					GUI.notify("AI", "Chat cleared.", 2)
				end,
			})
		end) -- task.defer (AI)
	end -- if options.aiEnabled

	-- ══════════════════════════════════════════════════════════════════════
	-- Settings tab (deferred so user tabs appear first)
	-- ══════════════════════════════════════════════════════════════════════
	task.defer(function()
		local S = GUI:CreateTab({ name = "Settings", icon = "⚙️" })

		S:Section({ name = "Theme" })

		local themeDrop = S:Dropdown({
			name     = "Theme",
			tooltip  = "Change the window colour scheme",
			items    = { "Dark","Crimson","Magenta","Teal" },
			default  = GUI._savedTheme or "Dark",
			callback = function(val)
				_applyTheme(val)
				GUI:SaveConfig()
			end,
		})
		GUI._cfgSyncCallbacks.theme = function(val)
			pcall(function() themeDrop:Set(val, true) end)
		end

		S:Section({ name = "Accent Color" })

		local function applyAccent(c)
			Library.Theme.Accent = c
			accentLine.BackgroundColor3 = c
			GUI:SaveConfig()
		end

		local rSlider, gSlider, bSlider
		local _syncing = false
		local function syncSlidersFromColor(c)
			if _syncing then return end; _syncing = true
			if rSlider then rSlider:Set(math.floor(c.R*255+0.5), true) end
			if gSlider then gSlider:Set(math.floor(c.G*255+0.5), true) end
			if bSlider then bSlider:Set(math.floor(c.B*255+0.5), true) end
			_syncing = false
		end

		local accentCP = S:ColorPicker({
			name     = "Accent Picker",
			tooltip  = "HSV picker",
			default  = Library.Theme.Accent,
			callback = function(c) applyAccent(c); syncSlidersFromColor(c) end,
		})
		GUI._cfgSyncCallbacks.accent = function(c)
			syncSlidersFromColor(c)
			pcall(function() accentCP:Set(c, true) end)
		end

		local function onSliderChange()
			if _syncing then return end
			local c = Color3.fromRGB(
				rSlider and rSlider.Value or 100,
				gSlider and gSlider.Value or 150,
				bSlider and bSlider.Value or 255)
			_syncing = true; accentCP:Set(c); _syncing = false
			applyAccent(c)
		end

		rSlider = S:Slider({ name="Red",   min=0, max=255, default=math.floor(Library.Theme.Accent.R*255+0.5), tooltip="Red (0-255)",   callback=onSliderChange })
		gSlider = S:Slider({ name="Green", min=0, max=255, default=math.floor(Library.Theme.Accent.G*255+0.5), tooltip="Green (0-255)", callback=onSliderChange })
		bSlider = S:Slider({ name="Blue",  min=0, max=255, default=math.floor(Library.Theme.Accent.B*255+0.5), tooltip="Blue (0-255)",  callback=onSliderChange })

		local function parseRGB(s)
			local r,g,b = s:match("(%d+)[,%s]+(%d+)[,%s]+(%d+)")
			if r then return Color3.fromRGB(
				math.clamp(tonumber(r) or 0, 0, 255),
				math.clamp(tonumber(g) or 0, 0, 255),
				math.clamp(tonumber(b) or 0, 0, 255)) end
		end
		S:TextInput({
			name        = "RGB value (e.g. 100,150,255)",
			placeholder = "R,G,B  — 0 to 255",
			default     = math.floor(Library.Theme.Accent.R*255+0.5)..","..math.floor(Library.Theme.Accent.G*255+0.5)..","..math.floor(Library.Theme.Accent.B*255+0.5),
			tooltip     = "Type R,G,B then press Enter",
			callback    = function(s)
				local c = parseRGB(s)
				if c then accentCP:Set(c); syncSlidersFromColor(c); applyAccent(c) end
			end,
		})

		S:Section({ name = "Keybinds" })
		S:Info({ text = "Click a badge, then press any key to rebind." })
		S:Keybind({ name="Toggle UI",   tooltip="Show / hide the window", default=keys.toggle,   callback=function(k) keys.toggle=k;   GUI:SaveConfig() end })
		S:Keybind({ name="Minimize UI", tooltip="Collapse to titlebar",   default=keys.minimize, callback=function(k) keys.minimize=k; GUI:SaveConfig() end })

		S:Section({ name = "Window" })

		local scaleSlider = S:Slider({
			name     = "UI Scale",
			min      = 80, max = 120, default = 100, suffix = "%",
			tooltip  = "Scale the window relative to its current size. Drag the bottom-right corner to freely resize.",
			callback = function(v)
				currentScale = v
				local sw = winW*(v/100); local sh = winH*(v/100)
				tw(Main, { Size = UDim2.new(0,sw,0,sh) }, TI_SLOW)
				GUI:SaveConfig()
			end,
		})
		GUI._cfgSyncCallbacks.scale = function(v)
			pcall(function() scaleSlider:Set(v, true) end)
		end

		S:Section({ name = "Config" })
		S:Info({ text = "Auto-saves on every change. File: VenturaUI/" .. options.name:gsub("[^%w%-%_]","_") .. ".json" })

		S:Button({
			name        = "Save Config",
			description = "Manually write current settings to file",
			callback    = function()
				GUI:SaveConfig()
				GUI.notify("Config Saved", "Settings written to file.", 3)
			end,
		})

		S:Button({
			name        = "Load Config",
			description = "Read and apply settings from file",
			callback    = function()
				local data = GUI:LoadConfig()
				if data then
					GUI:ApplyConfig(data)
					GUI.notify("Config Loaded", "Settings restored from file.", 3)
				else
					GUI.notify("Config", "No saved config found.", 3)
				end
			end,
		})

		S:Button({
			name        = "Reset Config",
			description = "Delete saved config file",
			callback    = function()
				pcall(function() if isfile(_cfgFile) then delfile(_cfgFile) end end)
				GUI.notify("Config Reset", "Saved config deleted.", 3)
			end,
		})

		S:Section({ name = "Info" })
		S:Label({ text = "VenturaUI v" .. Library.Version .. "  •  codeberg.org/VenomVent/Ventura-UI" })
		S:Label({ text = "Logged in as: " .. LP.Name .. "  (UserId: " .. LP.UserId .. ")" })
		S:Label({ text = "Toggle: " .. keys.toggle.Name .. "   |   Minimize: " .. keys.minimize.Name })
		S:Divider()
		S:Button({
			name        = "Copy UserId",
			description = "Copy your Roblox UserId to clipboard",
			callback    = function()
				pcall(function() setclipboard(tostring(LP.UserId)) end)
				GUI.notify("Copied!", "UserId: " .. LP.UserId, 2, "success")
			end,
		})
	end) -- task.defer (Settings)

	return GUI
end -- Library:new

return Library