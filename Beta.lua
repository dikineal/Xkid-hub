--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        ✦  X  K  I  D     H  U  B  ✦   FINAL V.3.5          ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║   🎬  Freecam        👁️  Spectate      🌍  World            ║
║   🗺️  Teleport       ⚡  Player        🛡️  Security         ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║   ✦  Modern Corner ESP        ✦  Mobile Shift Lock          ║
║   ✦  Smooth Damping Freecam   ✦  Anti-AFK Bypass            ║
║   ✦  Native Fly Direction     ✦  Anti-Glitcher Detect       ║
╚══════════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TPService = game:GetService("TeleportService")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- Global State
local State = {
    Move = {ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60},
    Fly = {active = false, bv = nil, bg = nil, _keys = {}},
    Fling = {active = false, power = 1000000},
    SoftFling = {active = false, power = 4000},
    Teleport = {selectedTarget = ""},
    Security = {afkConn = nil},
    Cinema = {active = false, speed = 1, fov = 70, lastPos = nil},
    Spectate = {hideName = false},
    ESP = {
        active = false, 
        cache = {},
        boxMode = "Corner", -- Corner, 2D Box, HIGHLIGHT, OFF
        tracerMode = "Bottom", -- Bottom, Center, OFF
        maxDrawDistance = 300,
        showDistance = true,
        showNickname = true,
        colorNormal = Color3.fromRGB(0, 255, 150),
        colorSuspect = Color3.fromRGB(255, 0, 100),
    }
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end
local function getDisplayNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")") end end
    return t
end
local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do if str == p.DisplayName .. " (@" .. p.Name .. ")" then return p end end
    return nil
end
local function getCharRoot(char)
    if not char then return nil end
    return char.PrimaryPart or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

-- Fix Jump Power Persistence
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- MODERN ESP ENGINE (CORNER, 2D BOX, DYNAMIC TRACER)
-- ═══════════════════════════════════════════════════════════

local function worldToScreen(worldPos)
    local screenPos, onScreen = Cam:WorldToScreenPoint(worldPos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function drawLine2D(p1, p2, thickness, color)
    local distance = (p1 - p2).Magnitude
    if distance == 0 then return nil end
    local direction = (p2 - p1).Unit
    local line = Instance.new("Frame")
    line.Name = "ESPLine"; line.BackgroundColor3 = color; line.BorderSizePixel = 0
    line.Position = UDim2.new(0, ((p1 + p2) / 2).X - distance / 2, 0, ((p1 + p2) / 2).Y - thickness / 2)
    line.Size = UDim2.new(0, distance, 0, thickness)
    line.Rotation = math.deg(math.atan2(direction.Y, direction.X))
    line.Parent = LP.PlayerGui:FindFirstChild("Aurora_ESP") or (function() local sg = Instance.new("ScreenGui", LP.PlayerGui); sg.Name = "Aurora_ESP"; sg.IgnoreGuiInset = true; return sg end)()
    return line
end

local function drawBox2D(hrp, color, isCorner)
    local topPos = hrp.Position + Vector3.new(0, 2.5, 0)
    local botPos = hrp.Position - Vector3.new(0, 3, 0)
    local tS, tO = worldToScreen(topPos); local bS, bO = worldToScreen(botPos)
    if not tO and not bO then return {} end
    local h = math.abs(bS.Y - tS.Y); local w = h * 0.6
    local tl = Vector2.new(bS.X - w/2, tS.Y); local tr = Vector2.new(bS.X + w/2, tS.Y)
    local bl = Vector2.new(bS.X - w/2, bS.Y); local br = Vector2.new(bS.X + w/2, bS.Y)
    local lines = {}
    if isCorner then
        local l = w/4
        table.insert(lines, drawLine2D(tl, tl+Vector2.new(l,0), 2, color)); table.insert(lines, drawLine2D(tl, tl+Vector2.new(0,l), 2, color))
        table.insert(lines, drawLine2D(tr, tr-Vector2.new(l,0), 2, color)); table.insert(lines, drawLine2D(tr, tr+Vector2.new(0,l), 2, color))
        table.insert(lines, drawLine2D(bl, bl+Vector2.new(l,0), 2, color)); table.insert(lines, drawLine2D(bl, bl-Vector2.new(0,l), 2, color))
        table.insert(lines, drawLine2D(br, br-Vector2.new(l,0), 2, color)); table.insert(lines, drawLine2D(br, br-Vector2.new(0,l), 2, color))
    else
        table.insert(lines, drawLine2D(tl, tr, 2, color)); table.insert(lines, drawLine2D(tr, br, 2, color))
        table.insert(lines, drawLine2D(br, bl, 2, color)); table.insert(lines, drawLine2D(bl, tl, 2, color))
    end
    return lines
end

local function isSuspectPlayer(player)
    local char = player.Character
    if not char then return false end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and (part.Size.X > 15 or part.Size.Y > 15 or part.Size.Z > 15) then return true end
    end
    return false
end

local function renderESP(player)
    if not State.ESP.active or player == LP then return end
    local char = player.Character; if not char then return end
    local hrp = getCharRoot(char); if not hrp then return end
    local lpRoot = getCharRoot(LP.Character)
    if lpRoot and (lpRoot.Position - hrp.Position).Magnitude > State.ESP.maxDrawDistance then
        if State.ESP.cache[player] and State.ESP.cache[player].label then State.ESP.cache[player].label.Enabled = false end
        return
    end
    
    local isSuspect = isSuspectPlayer(player)
    local color = isSuspect and State.ESP.colorSuspect or State.ESP.colorNormal
    
    if not State.ESP.cache[player] then State.ESP.cache[player] = {renders = {}, highlight = nil, label = nil} end
    local cache = State.ESP.cache[player]
    for _, r in pairs(cache.renders) do if r and r.Parent then r:Destroy() end end
    cache.renders = {}

    -- Box Render
    if State.ESP.boxMode == "Corner" or State.ESP.boxMode == "2D Box" then
        if cache.highlight then cache.highlight.Enabled = false end
        local boxLines = drawBox2D(hrp, color, (State.ESP.boxMode == "Corner"))
        for _, l in ipairs(boxLines) do table.insert(cache.renders, l) end
    elseif State.ESP.boxMode == "HIGHLIGHT" then
        if not cache.highlight then cache.highlight = Instance.new("Highlight", char); cache.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end
        cache.highlight.FillColor = color; cache.highlight.Enabled = true
    else
        if cache.highlight then cache.highlight.Enabled = false end
    end

    -- Tracer
    if State.ESP.tracerMode ~= "OFF" then
        local origin = (State.ESP.tracerMode == "Bottom") and Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y) or Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
        local tS, tO = worldToScreen(hrp.Position - Vector3.new(0, 2.5, 0))
        if tO then local l = drawLine2D(origin, tS, 1.5, color); if l then table.insert(cache.renders, l) end end
    end

    -- Text Info (BillboardGui)
    local head = char:FindFirstChild("Head") or hrp
    if not cache.label then
        local bg = Instance.new("BillboardGui", head); bg.Size = UDim2.new(0,200,0,50); bg.StudsOffset = Vector3.new(0,2,0); bg.AlwaysOnTop = true
        local txt = Instance.new("TextLabel", bg); txt.BackgroundTransparency = 1; txt.Size = UDim2.new(1,0,1,0); txt.Font = Enum.Font.GothamBold; txt.TextSize = 11; txt.RichText = true
        cache.label = bg
    end
    cache.label.Enabled = (State.ESP.showNickname or State.ESP.showDistance or isSuspect)
    local distText = (lpRoot and State.ESP.showDistance) and "\n📍 "..math.floor((lpRoot.Position - hrp.Position).Magnitude).."m" or ""
    local suspText = isSuspect and "\n<font color='#ff0055'>⚠️ GLITCHER</font>" or ""
    cache.label.TextLabel.Text = (State.ESP.showNickname and "<b>"..player.DisplayName.."</b>" or "") .. distText .. suspText
    cache.label.TextLabel.TextColor3 = color
end

RS.RenderStepped:Connect(function() if State.ESP.active then for _, p in pairs(Players:GetPlayers()) do renderESP(p) end end end)
Players.PlayerRemoving:Connect(function(p) if State.ESP.cache[p] then if State.ESP.cache[p].highlight then State.ESP.cache[p].highlight:Destroy() end if State.ESP.cache[p].label then State.ESP.cache[p].label:Destroy() end State.ESP.cache[p] = nil end end)

-- ═══════════════════════════════════════════════════════════
-- PLAYER ABILITIES (FLY, MOVEMENT, LOCK)
-- ═══════════════════════════════════════════════════════════

local function toggleFly(v)
    if not v then
        State.Fly.active = false; RS:UnbindFromRenderStep("AuroraFly")
        if State.Fly.bv then State.Fly.bv:Destroy(); State.Fly.bv = nil end
        if State.Fly.bg then State.Fly.bg:Destroy(); State.Fly.bg = nil end
        local hum = getHum(); if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.WalkSpeed = State.Move.ws end
        return
    end
    local hrp, hum = getRoot(), getHum(); if not hrp or not hum then return end
    State.Fly.active = true; hum.PlatformStand = true
    State.Fly.bv = Instance.new("BodyVelocity", hrp); State.Fly.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); State.Fly.bv.Velocity = Vector3.zero
    State.Fly.bg = Instance.new("BodyGyro", hrp); State.Fly.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); State.Fly.bg.P = 1e5
    
    local keys = {}; UIS.InputBegan:Connect(function(i,g) if not g then keys[i.KeyCode] = true end end)
    UIS.InputEnded:Connect(function(i) keys[i.KeyCode] = false end)

    RS:BindToRenderStep("AuroraFly", 201, function()
        local r = getRoot(); if not r or not State.Fly.active then return end
        local move = Vector3.zero; local cf = Cam.CFrame
        if keys[Enum.KeyCode.W] then move = move + cf.LookVector end
        if keys[Enum.KeyCode.S] then move = move - cf.LookVector end
        if keys[Enum.KeyCode.D] then move = move + cf.RightVector end
        if keys[Enum.KeyCode.A] then move = move - cf.RightVector end
        if keys[Enum.KeyCode.E] then move = move + Vector3.new(0,1,0) end
        if keys[Enum.KeyCode.Q] then move = move - Vector3.new(0,1,0) end
        State.Fly.bv.Velocity = move.Magnitude > 0 and move.Unit * State.Move.flyS or Vector3.zero
        State.Fly.bg.CFrame = CFrame.new(r.Position, r.Position + cf.LookVector)
    end)
end

-- ═══════════════════════════════════════════════════════════
-- SMOOTH FREECAM ENGINE
-- ═══════════════════════════════════════════════════════════

local FC = {active=false, pos=Vector3.zero, vel=Vector3.zero, pitch=0, yaw=0, speed=5, damp=0.85, accel=0.15, keys={}}
UIS.InputBegan:Connect(function(i,g) if not g then FC.keys[i.KeyCode] = true end end)
UIS.InputEnded:Connect(function(i) FC.keys[i.KeyCode] = false end)
UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then FC.yaw = FC.yaw - i.Delta.X*0.25; FC.pitch = math.clamp(FC.pitch - i.Delta.Y*0.25, -80, 80) end end)

local function toggleFreecam(v)
    FC.active = v; if not v then Cam.CameraType = Enum.CameraType.Custom; local r = getRoot(); if r then r.Anchored = false end return end
    FC.pos = Cam.CFrame.Position; local r = getRoot(); if r then r.Anchored = true end
    RS:BindToRenderStep("AuroraFreecam", 201, function(dt)
        if not FC.active then RS:UnbindFromRenderStep("AuroraFreecam") return end
        Cam.CameraType = Enum.CameraType.Scriptable; local cf = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yaw), 0) * CFrame.Angles(math.rad(FC.pitch), 0, 0)
        local dV = Vector3.zero
        if FC.keys[Enum.KeyCode.W] then dV = dV + cf.LookVector end
        if FC.keys[Enum.KeyCode.S] then dV = dV - cf.LookVector end
        if FC.keys[Enum.KeyCode.D] then dV = dV + cf.RightVector end
        if FC.keys[Enum.KeyCode.A] then dV = dV - cf.RightVector end
        if FC.keys[Enum.KeyCode.E] then dV = dV + Vector3.new(0,1,0) end
        if FC.keys[Enum.KeyCode.Q] then dV = dV - Vector3.new(0,1,0) end
        FC.vel = FC.vel:Lerp(dV.Magnitude > 0 and dV.Unit*FC.speed*10 or Vector3.zero, FC.accel); FC.vel = FC.vel * FC.damp
        FC.pos = FC.pos + FC.vel; Cam.CFrame = cf
    end)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘

local Win = Library:Window("✦ XKID HUB — FINAL ✦", "star", "FREECAM", false)

-- --- TAB: TELEPORT ---
local T_TP = Win:Tab("Teleport", "map-pin")
local TPT = T_TP:Page("Navigation", "map-pin"):Section("🎯 Smart Search", "Left")
TPT:TextBox("Ketik Nama Player", "pText", "", function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🚀 Teleport Sekarang", "", function()
    local target = State.Teleport.selectedTarget; if target == "" then return end
    for _, p in pairs(Players:GetPlayers()) do if p ~= LP and (string.find(p.Name:lower(), target:lower()) or string.find(p.DisplayName:lower(), target:lower())) then if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then getRoot().CFrame = p.Character.HumanoidRootPart.CFrame; return end end end
end)
local P_Drop = TPT:Dropdown("Daftar Player", "pDrop", getPNames(), function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🔄 Refresh Daftar", "", function() P_Drop:Refresh(getPNames()) end)

-- --- TAB: PLAYER ---
local T_PL = Win:Tab("Player", "user")
local PLM = T_PL:Page("Movement", "zap"):Section("⚡ Movement", "Left")
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end)
PLM:Slider("JumpPower", "jp", 50, 500, 50, function(v) State.Move.jp = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end)
PLM:Toggle("Inf Jump", "ij", false, "", function(v)
    if v then State.Move.infJ = UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end)
    else if State.Move.infJ then State.Move.infJ:Disconnect() end end
end)
local PLH = T_PL:Page("Movement", "zap"):Section("🚀 Abilities", "Right")
PLH:Toggle("Fly", "nf", false, "", toggleFly)
PLH:Slider("Fly Speed", "flyspd", 10, 300, 60, function(v) State.Move.flyS = v end)
PLH:Toggle("Shift Lock", "sl", false, "", function(v)
    local h = getHum(); if not h then return end
    if v then h.CameraOffset = Vector3.new(1.75, 0, 0); h.AutoRotate = false; _G.SL = RS.RenderStepped:Connect(function() local r = getRoot(); if r then r.CFrame = CFrame.new(r.Position, r.Position + Vector3.new(Cam.CFrame.LookVector.X, 0, Cam.CFrame.LookVector.Z)) end end)
    else if _G.SL then _G.SL:Disconnect() end; h.CameraOffset = Vector3.zero; h.AutoRotate = true end
end)

-- --- TAB: CINEMATIC ---
local T_CI = Win:Tab("Cinematic", "video")
local CIM = T_CI:Page("Freecam", "video"):Section("🎬 Smooth Freecam", "Left")
CIM:Toggle("Freecam ON/OFF", "fc", false, "", toggleFreecam)
CIM:Slider("Speed", "fcspd", 1, 30, 5, function(v) FC.speed = v end)
CIM:Slider("Damping (Smooth)", "fcdamp", 0, 1, 0.85, function(v) FC.damp = v end)
CIM:Slider("Acceleration", "fcacc", 0, 1, 0.15, function(v) FC.accel = v end)
CIM:Button("🔄 Reset POV Camera", "", function() Cam.CameraType = Enum.CameraType.Custom; task.wait(0.1); Cam.CameraType = Enum.CameraType.Custom end)

-- --- TAB: SECURITY & ESP ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")
SCP:Toggle("Anti-AFK Bypass", "afk", false, "", function(v)
    if v then _G.AFK = LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end); pcall(function() for _,c in pairs(getconnections(LP.Idled)) do c:Disable() end end)
    else if _G.AFK then _G.AFK:Disconnect() end; pcall(function() for _,c in pairs(getconnections(LP.Idled)) do c:Enable() end end) end
end)
SCP:Button("💀 Fast Respawn", "", function()
    local r = getRoot(); if not r then return end
    local cp = r.CFrame; getHum().Health = 0; LP.CharacterAdded:Wait(); task.wait(0.5); getRoot().CFrame = cp
end)

local ESPM = T_SC:Page("ESP", "radar"):Section("🎯 ESP Settings", "Left")
ESPM:Toggle("ESP Master", "esp_m", false, "", function(v) State.ESP.active = v; if not v then clearESP() end end)
ESPM:Dropdown("Box Mode", "esp_b", {"Corner", "2D Box", "HIGHLIGHT", "OFF"}, function(v) State.ESP.boxMode = v end)
ESPM:Dropdown("Tracer Mode", "esp_t", {"Bottom", "Center", "OFF"}, function(v) State.ESP.tracerMode = v end)
ESPM:Toggle("Show Nickname", "esp_n", true, "", function(v) State.ESP.showNickname = v end)
ESPM:Toggle("Show Distance", "esp_d", true, "", function(v) State.ESP.showDistance = v end)
ESPM:Slider("Draw Distance", "esp_dist", 50, 1000, 300, function(v) State.ESP.maxDrawDistance = v end)

-- Background Loops
RS.Stepped:Connect(function()
    if State.Move.ncp and LP.Character then for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
end)

Library:Notification("✦ XKID HUB", "Balik ke Aurora Library! Ready Bro! 🚀", 5)
