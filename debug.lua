--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    ✦  X K I D     H U B  ✦   FINAL WIND-UI UPDATE           ║
║                                                              ║
║   ✅ UI Modern (WindUI) Acrylic & Smooth                     ║
║   ✅ Modern ESP (Corner/Box) + BillboardGui Name (FIXED)     ║
║   ✅ Smooth Freecam (Damping + Velocity)                     ║
║   ✅ Auto Suspect Detection (Anti-Glitcher)                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
]]

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
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
    Fly = {active = false, bv = nil, bg = nil},
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
        tracerMode = "Bottom", -- Bottom, Center, Mouse, OFF
        maxDrawDistance = 300,
        showDistance = true,
        showNickname = true,
        boxColor_Normal = Color3.fromRGB(0, 255, 150),
        boxColor_Suspect = Color3.fromRGB(255, 0, 100),
        tracerColor_Normal = Color3.fromRGB(0, 200, 255),
        tracerColor_Suspect = Color3.fromRGB(255, 50, 50),
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
    return char.PrimaryPart or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

-- Persistent Movement
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- MODERN ESP ENGINE (CORNER, TRACER, BILLBOARDGUI NAME)
-- ═══════════════════════════════════════════════════════════

local function worldToScreen(worldPos)
    local screenPos, onScreen = Cam:WorldToScreenPoint(worldPos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function drawLine2D(p1, p2, thickness, color)
    local distance = (p1 - p2).Magnitude
    if distance == 0 then return nil end
    local direction = (p2 - p1).Unit
    local angle = math.atan2(direction.Y, direction.X)
    local line = Instance.new("Frame")
    line.Name = "ESPLine"
    line.BackgroundColor3 = color
    line.BorderSizePixel = 0
    local midpoint = (p1 + p2) / 2
    line.Position = UDim2.new(0, midpoint.X - distance / 2, 0, midpoint.Y - thickness / 2)
    line.Size = UDim2.new(0, distance, 0, thickness)
    line.Rotation = math.deg(angle)
    local sg = LP.PlayerGui:FindFirstChild("XKID_ESP_GUI") or (function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "XKID_ESP_GUI"
        sg.ResetOnSpawn = false
        sg.Parent = LP.PlayerGui
        return sg
    end)()
    line.Parent = sg
    return line
end

local function drawBox2D(hrp, color, thickness, isCorner)
    if not hrp then return {} end
    local topPos = hrp.Position + Vector3.new(0, 2.5, 0)
    local botPos = hrp.Position - Vector3.new(0, 3, 0)
    local topScreen, topOn = worldToScreen(topPos)
    local botScreen, botOn = worldToScreen(botPos)
    if not topOn and not botOn then return {} end
    
    local height = math.abs(botScreen.Y - topScreen.Y)
    local width = height * 0.6
    local tl = Vector2.new(botScreen.X - width/2, topScreen.Y)
    local tr = Vector2.new(botScreen.X + width/2, topScreen.Y)
    local bl = Vector2.new(botScreen.X - width/2, botScreen.Y)
    local br = Vector2.new(botScreen.X + width/2, botScreen.Y)
    
    local lines = {}
    if isCorner then
        local len = width / 3.5
        table.insert(lines, drawLine2D(tl, tl + Vector2.new(len, 0), thickness, color))
        table.insert(lines, drawLine2D(tl, tl + Vector2.new(0, len), thickness, color))
        table.insert(lines, drawLine2D(tr, tr - Vector2.new(len, 0), thickness, color))
        table.insert(lines, drawLine2D(tr, tr + Vector2.new(0, len), thickness, color))
        table.insert(lines, drawLine2D(bl, bl + Vector2.new(len, 0), thickness, color))
        table.insert(lines, drawLine2D(bl, bl - Vector2.new(0, len), thickness, color))
        table.insert(lines, drawLine2D(br, br - Vector2.new(len, 0), thickness, color))
        table.insert(lines, drawLine2D(br, br - Vector2.new(0, len), thickness, color))
    else
        table.insert(lines, drawLine2D(tl, tr, thickness, color))
        table.insert(lines, drawLine2D(tr, br, thickness, color))
        table.insert(lines, drawLine2D(br, bl, thickness, color))
        table.insert(lines, drawLine2D(bl, tl, thickness, color))
    end
    
    local res = {}
    for _, l in ipairs(lines) do if l then table.insert(res, l) end end
    return res
end

local function isSuspectPlayer(player)
    local char = player.Character
    if not char then return false end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Size.X > 15 or part.Size.Y > 15 or part.Size.Z > 15 then
                return true
            end
        end
    end
    return false
end

local function renderESP(player)
    if not State.ESP.active or player == LP then return end
    local char = player.Character
    if not char then return end
    local hrp = getCharRoot(char)
    if not hrp then return end
    
    local lpRoot = getCharRoot(LP.Character)
    if lpRoot and (lpRoot.Position - hrp.Position).Magnitude > State.ESP.maxDrawDistance then
        -- Hide BillboardGui jika diluar jarak
        if State.ESP.cache[player] and State.ESP.cache[player].bg then
            State.ESP.cache[player].bg.Enabled = false
        end
        return
    end
    
    local isSuspect = isSuspectPlayer(player)
    local boxColor = isSuspect and State.ESP.boxColor_Suspect or State.ESP.boxColor_Normal
    local tracerColor = isSuspect and State.ESP.tracerColor_Suspect or State.ESP.tracerColor_Normal
    
    if not State.ESP.cache[player] then
        State.ESP.cache[player] = {renders = {}, highlight = nil, bg = nil}
    end
    
    local cache = State.ESP.cache[player]
    -- Clear 2D renders from last frame
    for _, render in pairs(cache.renders) do
        if render and render.Parent then render:Destroy() end
    end
    cache.renders = {}
    
    -- 1. Box / Highlight Rendering
    if State.ESP.boxMode == "Corner" or State.ESP.boxMode == "2D Box" then
        if cache.highlight then cache.highlight.Enabled = false end
        local isCorner = (State.ESP.boxMode == "Corner")
        local lines = drawBox2D(hrp, boxColor, 1.5, isCorner)
        for _, l in ipairs(lines) do table.insert(cache.renders, l) end
        
    elseif State.ESP.boxMode == "HIGHLIGHT" then
        if not cache.highlight or cache.highlight.Parent ~= char then
            if cache.highlight then cache.highlight:Destroy() end
            local hl = Instance.new("Highlight")
            hl.Parent = char
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            cache.highlight = hl
        end
        cache.highlight.FillColor = boxColor
        cache.highlight.OutlineColor = Color3.new(1, 1, 1)
        cache.highlight.FillTransparency = 0.5
        cache.highlight.OutlineTransparency = 0
        cache.highlight.Enabled = true
    else
        if cache.highlight then cache.highlight.Enabled = false end
    end
    
    -- 2. Tracer Rendering
    if State.ESP.tracerMode ~= "OFF" then
        local targetPos = hrp.Position - Vector3.new(0, 2.5, 0)
        local screenPos, onScreen = worldToScreen(targetPos)
        if onScreen then
            local origin
            if State.ESP.tracerMode == "Bottom" then
                origin = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
            elseif State.ESP.tracerMode == "Center" then
                origin = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
            elseif State.ESP.tracerMode == "Mouse" then
                local ms = UIS:GetMouseLocation()
                origin = Vector2.new(ms.X, ms.Y)
            end
            if origin then
                local line = drawLine2D(origin, screenPos, 1.5, tracerColor)
                if line then table.insert(cache.renders, line) end
            end
        end
    end
    
    -- 3. BillboardGui Info (FIXED: Lebih Stabil dari Teks 2D biasa)
    local head = char:FindFirstChild("Head") or hrp
    local showText = State.ESP.showNickname or State.ESP.showDistance or isSuspect
    
    if not cache.bg or cache.bg.Parent ~= head then
        if cache.bg then cache.bg:Destroy() end
        local bg = Instance.new("BillboardGui")
        bg.Name = "XKID_ESP_Name"
        bg.Adornee = head
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.StudsOffset = Vector3.new(0, 2, 0)
        bg.AlwaysOnTop = true
        bg.Parent = head
        
        local txt = Instance.new("TextLabel")
        txt.Name = "Info"
        txt.Parent = bg
        txt.BackgroundTransparency = 1
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 10
        txt.TextColor3 = boxColor
        txt.TextStrokeTransparency = 0.2
        txt.TextStrokeColor3 = Color3.new(0,0,0)
        txt.TextYAlignment = Enum.TextYAlignment.Bottom
        txt.RichText = true
        
        cache.bg = bg
    end
    
    if cache.bg then
        cache.bg.Enabled = showText
        if showText then
            local infoText = ""
            if State.ESP.showNickname then
                infoText = "<b>" .. player.DisplayName .. "</b>"
            end
            if State.ESP.showDistance and lpRoot then
                local dist = math.floor((lpRoot.Position - hrp.Position).Magnitude)
                infoText = infoText .. (infoText ~= "" and "\n" or "") .. "📍 " .. dist .. "m"
            end
            if isSuspect then
                infoText = infoText .. (infoText ~= "" and "\n" or "") .. "<font color='#ff0055'>⚠️ GLITCHER</font>"
            end
            
            cache.bg.Info.Text = infoText
            cache.bg.Info.TextColor3 = boxColor
        end
    end
end

RS.RenderStepped:Connect(function()
    if State.ESP.active then
        for _, player in pairs(Players:GetPlayers()) do
            renderESP(player)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if State.ESP.cache[player] then
        for _, render in pairs(State.ESP.cache[player].renders) do
            if render and render.Parent then render:Destroy() end
        end
        if State.ESP.cache[player].highlight then State.ESP.cache[player].highlight:Destroy() end
        if State.ESP.cache[player].bg then State.ESP.cache[player].bg:Destroy() end
        State.ESP.cache[player] = nil
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │        ➤  FLY ENGINE  (LOCK CAMERA DIRECTION)           │
-- └─────────────────────────────────────────────────────────┘

local onMobile = not UIS.KeyboardEnabled
local flyMoveTouch, flyMoveSt, flyJoy = nil, nil, Vector2.zero
local flyConns = {}

local function startFlyCapture()
    local keysHeld = {}
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then keysHeld[k] = true end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp) keysHeld[inp.KeyCode] = false end))
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local half = Cam.ViewportSize.X / 2
        if inp.Position.X <= half then
            if not flyMoveTouch then flyMoveTouch = inp; flyMoveSt = inp.Position end
        end
    end))
    table.insert(flyConns, UIS.TouchMoved:Connect(function(inp)
        if inp == flyMoveTouch and flyMoveSt then
            local dx = inp.Position.X - flyMoveSt.X
            local dy = inp.Position.Y - flyMoveSt.Y
            local nx = math.abs(dx) > 25 and math.clamp((dx - math.sign(dx)*25)/80,-1,1) or 0
            local ny = math.abs(dy) > 20 and math.clamp((dy - math.sign(dy)*20)/80,-1,1) or 0
            flyJoy = Vector2.new(nx, ny)
        end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == flyMoveTouch then flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero end
    end))
    State.Fly._keys = keysHeld
end

local function stopFlyCapture()
    for _, c in ipairs(flyConns) do c:Disconnect() end
    flyConns = {}; flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero; State.Fly._keys = {}
end

local function toggleFly(v)
    if not v then
        State.Fly.active = false
        stopFlyCapture()
        RS:UnbindFromRenderStep("XKIDFly")
        if State.Fly.bv then State.Fly.bv:Destroy(); State.Fly.bv = nil end
        if State.Fly.bg then State.Fly.bg:Destroy(); State.Fly.bg = nil end
        local hum = getHum()
        if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.WalkSpeed = State.Move.ws; hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
        WindUI:Notify({Title = "Fly", Content = "✈️ Fly OFF", Duration = 2})
        return
    end

    local hrp = getRoot()
    local hum = getHum()
    if not hrp or not hum then return end

    State.Fly.active = true
    hum.PlatformStand = true
    State.Fly.bv = Instance.new("BodyVelocity", hrp)
    State.Fly.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    State.Fly.bv.Velocity  = Vector3.zero
    State.Fly.bg = Instance.new("BodyGyro", hrp)
    State.Fly.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    State.Fly.bg.P = 1e5

    startFlyCapture()
    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not State.Fly.active then return end
        local r, h = getRoot(), getHum()
        if not r or not h then return end

        local camCF = Cam.CFrame
        local spd  = State.Move.flyS
        local move = Vector3.zero
        local keys = State.Fly._keys or {}

        if onMobile then
            move = camCF.LookVector * (-flyJoy.Y) * spd + camCF.RightVector * flyJoy.X * spd
        else
            if keys[Enum.KeyCode.W] then move = move + camCF.LookVector end
            if keys[Enum.KeyCode.S] then move = move - camCF.LookVector end
            if keys[Enum.KeyCode.D] then move = move + camCF.RightVector end
            if keys[Enum.KeyCode.A] then move = move - camCF.RightVector end
            if keys[Enum.KeyCode.E] then move = move + Vector3.new(0,1,0) end
            if keys[Enum.KeyCode.Q] then move = move - Vector3.new(0,1,0) end
            if move.Magnitude > 0 then move = move.Unit * spd end
        end

        State.Fly.bv.Velocity = move
        State.Fly.bg.CFrame = CFrame.new(r.Position, r.Position + camCF.LookVector)
    end)
    WindUI:Notify({Title = "Fly", Content = "✈️ Fly ON — Ikut arah kamera", Duration = 3})
end

-- ┌─────────────────────────────────────────────────────────┐
-- │     ➤  FREECAM ENGINE (SMOOTH + MOBILE READY)           │
-- └─────────────────────────────────────────────────────────┘

local FC = {
    active = false, pos = Vector3.zero, vel = Vector3.zero,
    pitchDeg = 0, yawDeg = 0, speed = 1, sens = 0.25,
    savedCharCFrame = nil, damping = 0.85, acceleration = 0.15,
}

local fcRotTouch, fcMoveTouch, fcMoveSt, fcRotLast = nil, nil, nil, nil
local fcJoy = Vector2.zero
local DEAD_X, DEAD_Y = 25, 20
local fcConns = {}

local function startFCCapture()
    local keysHeld = {}
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then keysHeld[k] = true end
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mouseRotate = true; UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        keysHeld[inp.KeyCode] = false
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mouseRotate = false; UIS.MouseBehavior = Enum.MouseBehavior.Default end
    end))
    table.insert(fcConns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and FC._mouseRotate then
            FC.yawDeg = FC.yawDeg - inp.Delta.X * FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg - inp.Delta.Y * FC.sens, -80, 80)
        end
        if inp.UserInputType == Enum.UserInputType.MouseWheel then Cam.FieldOfView = math.clamp(Cam.FieldOfView - inp.Position.Z * 5, 10, 120) end
    end))
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local half = Cam.ViewportSize.X / 2
        if inp.Position.X > half then
            if not fcRotTouch then fcRotTouch = inp; fcRotLast = inp.Position end
        else
            if not fcMoveTouch then fcMoveTouch = inp; fcMoveSt = inp.Position end
        end
    end))
    table.insert(fcConns, UIS.TouchMoved:Connect(function(inp)
        if inp == fcRotTouch and fcRotLast then
            local dx = inp.Position.X - fcRotLast.X
            local dy = inp.Position.Y - fcRotLast.Y
            FC.yawDeg = FC.yawDeg - dx * FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg - dy * FC.sens, -80, 80)
            fcRotLast = inp.Position
        end
        if inp == fcMoveTouch and fcMoveSt then
            local dx = inp.Position.X - fcMoveSt.X
            local dy = inp.Position.Y - fcMoveSt.Y
            local nx = math.abs(dx) > DEAD_X and math.clamp((dx - math.sign(dx) * DEAD_X) / 80, -1, 1) or 0
            local ny = math.abs(dy) > DEAD_Y and math.clamp((dy - math.sign(dy) * DEAD_Y) / 80, -1, 1) or 0
            fcJoy = Vector2.new(nx, ny)
        end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == fcRotTouch then fcRotTouch = nil; fcRotLast = nil end
        if inp == fcMoveTouch then fcMoveTouch = nil; fcMoveSt = nil; fcJoy = Vector2.zero end
    end))
    FC._keys = keysHeld
end

local function stopFCCapture()
    for _, c in ipairs(fcConns) do c:Disconnect() end
    fcConns = {}; fcRotTouch = nil; fcMoveTouch = nil; fcMoveSt = nil; fcRotLast = nil; fcJoy = Vector2.zero; FC._mouseRotate = false; FC._keys = {}
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

local function startFCLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable
        local cf = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local spd = FC.speed * 32
        local desiredVel = Vector3.zero
        local keys = FC._keys or {}

        if onMobile then
            desiredVel = cf.LookVector * (-fcJoy.Y) * spd + cf.RightVector * fcJoy.X * spd
        else
            if keys[Enum.KeyCode.W] then desiredVel = desiredVel + cf.LookVector * spd end
            if keys[Enum.KeyCode.S] then desiredVel = desiredVel - cf.LookVector * spd end
            if keys[Enum.KeyCode.D] then desiredVel = desiredVel + cf.RightVector * spd end
            if keys[Enum.KeyCode.A] then desiredVel = desiredVel - cf.RightVector * spd end
            if keys[Enum.KeyCode.E] then desiredVel = desiredVel + Vector3.new(0,1,0) * spd end
            if keys[Enum.KeyCode.Q] then desiredVel = desiredVel - Vector3.new(0,1,0) * spd end
        end

        FC.vel = FC.vel:Lerp(desiredVel, FC.acceleration * dt * 60)
        FC.vel = FC.vel * (FC.damping ^ (dt * 60))
        FC.pos = FC.pos + FC.vel * dt

        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)

        local hrp, hum = getRoot(), getHum()
        if hrp and not hrp.Anchored then hrp.Anchored = true end
        if hum then
            if hum:GetState() ~= Enum.HumanoidStateType.Physics then hum:ChangeState(Enum.HumanoidStateType.Physics) end
            hum.WalkSpeed = 0; hum.JumpPower = 0
        end
    end)
end

local function stopFCLoop() RS:UnbindFromRenderStep("XKIDFreecam") end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  WIND-UI CREATION                   │
-- └─────────────────────────────────────────────────────────┘

local Window = WindUI:CreateWindow({
    Title   = "✦ XKID HUB ✦",
    Author  = "Final Version v4",
    Folder  = "xkid_hub_v4",
    Icon    = "paint-bucket",
    Theme   = "Dark",
    Acrylic = true,
    Transparent = true,
    Size    = UDim2.fromOffset(680, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey  = Enum.KeyCode.RightShift,
    Resizable  = true,
    AutoScale  = true,
    NewElements = true,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    SideBarWidth = 200,
    Topbar = { Height = 44, ButtonsType = "Default" },
    OpenButton = {
        Title = "My Hub", Icon = "zap", CornerRadius = UDim.new(1, 0), StrokeThickness = 3,
        Enabled = true, Draggable = true, OnlyMobile = false, Scale = 1,
        Color = ColorSequence.new(Color3.fromHex("#000000"), Color3.fromHex("#000000")),
    },
})

-- ==================== TAB: TELEPORT ====================
local T_TP = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
T_TP:Section({Title = "🎯 Smart Search"})
T_TP:TextBox({
    Title = "Ketik 2-3 Huruf Nama",
    Callback = function(v) State.Teleport.selectedTarget = v end
})
T_TP:Button({
    Title = "🚀 Teleport Now",
    Callback = function()
        local snippet = State.Teleport.selectedTarget
        if snippet == "" then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and (string.find(string.lower(p.Name), string.lower(snippet)) or string.find(string.lower(p.DisplayName), string.lower(snippet))) then
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    getRoot().CFrame = p.Character.HumanoidRootPart.CFrame
                    return
                end
            end
        end
    end
})
local pDropList = T_TP:Dropdown({
    Title = "Manual List",
    Values = getPNames(),
    Value = "",
    Callback = function(v) State.Teleport.selectedTarget = v end
})
T_TP:Button({
    Title = "🔄 Refresh List",
    Callback = function() pcall(function() pDropList:Refresh(getPNames()) end) end
})

T_TP:Section({Title = "💾 Locations"})
local SavedLocs = {}
for i = 1, 3 do
    T_TP:Button({
        Title = "💾 Save Position -> Slot " .. i,
        Callback = function()
            local r = getRoot()
            if r then SavedLocs[i] = r.CFrame; WindUI:Notify({Title="Saved", Content="Slot "..i, Duration=2}) end
        end
    })
    T_TP:Button({
        Title = "📍 Load Position -> Slot " .. i,
        Callback = function()
            if SavedLocs[i] and getRoot() then getRoot().CFrame = SavedLocs[i]; WindUI:Notify({Title="Loaded", Content="Slot "..i, Duration=2}) end
        end
    })
end

-- ==================== TAB: PLAYER ====================
local T_PL = Window:Tab({ Title = "Player", Icon = "user" })

T_PL:Section({Title = "⚡ Movement"})
T_PL:Slider({ Title = "🏃 WalkSpeed", Min = 16, Max = 500, Value = 16, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
T_PL:Slider({ Title = "🦘 JumpPower", Min = 50, Max = 500, Value = 50, Callback = function(v) State.Move.jp = v; local hum = getHum(); if hum then hum.UseJumpPower = true; hum.JumpPower = v end end })
T_PL:Toggle({
    Title = "∞ Inf Jump", Value = false,
    Callback = function(v)
        if v then State.Move.infJ = UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end)
        else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end end
    end
})

T_PL:Section({Title = "🚀 Abilities"})
T_PL:Toggle({ Title = "✈️ Native Fly", Value = false, Callback = toggleFly })
T_PL:Slider({ Title = "✈️ Fly Speed", Min = 10, Max = 300, Value = 60, Callback = function(v) State.Move.flyS = v end })
T_PL:Toggle({ Title = "👻 NoClip", Value = false, Callback = function(v) State.Move.ncp = v end })
T_PL:Toggle({ Title = "💥 IY Fling (Brutal)", Value = false, Callback = function(v) State.Fling.active = v; State.Move.ncp = v end })
T_PL:Toggle({ Title = "💫 Soft Fling", Value = false, Callback = function(v) State.SoftFling.active = v; State.Move.ncp = v end })

local noFallConn = nil
T_PL:Toggle({
    Title = "🛡️ No Fall Damage", Value = false,
    Callback = function(v)
        if v then noFallConn = RS.Heartbeat:Connect(function() local hrp = getRoot(); if hrp and hrp.Velocity.Y < -30 then hrp.Velocity = Vector3.new(hrp.Velocity.X, -10, hrp.Velocity.Z) end end)
        else if noFallConn then noFallConn:Disconnect(); noFallConn = nil end end
    end
})

local godConn, godRespawn, godLastPos = nil, nil, nil
T_PL:Toggle({
    Title = "🛡️ God Mode (Auto Respawn)", Value = false,
    Callback = function(v)
        if v then
            local hum = getHum(); if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
            godLastPos = getRoot() and getRoot().CFrame
            godRespawn = RS.Heartbeat:Connect(function() local r = getRoot(); if r then godLastPos = r.CFrame end end)
            godConn = RS.Heartbeat:Connect(function() local h = getHum(); if h then if h.Health < h.MaxHealth then h.Health = h.MaxHealth end; if h.MaxHealth ~= math.huge then h.MaxHealth = math.huge end end end)
            WindUI:Notify({Title="God Mode", Content="Aktif!", Duration=3})
        else
            if godConn then godConn:Disconnect(); godConn = nil end
            if godRespawn then godRespawn:Disconnect(); godRespawn = nil end
            local hum = getHum(); if hum then hum.MaxHealth = 100; hum.Health = 100 end
            WindUI:Notify({Title="God Mode", Content="Nonaktif", Duration=2})
        end
    end
})
-- Listener God Mode untuk auto respawn di inject di main script

T_PL:Section({Title = "🎯 Lock"})
local shiftLockConn = nil
T_PL:Toggle({
    Title = "🎯 Enable Shift Lock", Value = false,
    Callback = function(v)
        local hum, hrp = getHum(), getRoot()
        if not hum or not hrp then WindUI:Notify({Title="Error", Content="Karakter tidak ada!", Duration=2}); return end
        if v then
            hum.CameraOffset = Vector3.new(1.75, 0, 0); hum.AutoRotate = false
            shiftLockConn = RS.RenderStepped:Connect(function() local curHrp = getRoot(); if curHrp then local camLook = Cam.CFrame.LookVector; curHrp.CFrame = CFrame.new(curHrp.Position, curHrp.Position + Vector3.new(camLook.X, 0, camLook.Z)) end end)
        else
            if shiftLockConn then shiftLockConn:Disconnect(); shiftLockConn = nil end
            hum.CameraOffset = Vector3.zero; hum.AutoRotate = true
        end
    end
})

-- ==================== TAB: CINEMATIC ====================
local T_CI = Window:Tab({ Title = "Cinematic", Icon = "video" })

T_CI:Section({Title = "🎬 Smooth Freecam"})
T_CI:Toggle({
    Title = "🎬 Freecam ON/OFF", Value = false,
    Callback = function(v)
        FC.active = v; State.Cinema.active = v
        if v then
            FC.pos = Cam.CFrame.Position; FC.vel = Vector3.zero
            local rx, ry = Cam.CFrame:ToEulerAnglesYXZ(); FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry)
            FC._keys = {}; FC._mouseRotate = false
            local hrp, hum = getRoot(), getHum()
            if hrp then FC.savedCharCFrame = hrp.CFrame; hrp.Anchored = true end
            if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum:ChangeState(Enum.HumanoidStateType.Physics) end
            startFCCapture(); startFCLoop()
            WindUI:Notify({Title="Freecam", Content="Kiri Gerak | Kanan Rotate", Duration=3})
        else
            stopFCLoop(); stopFCCapture()
            local hrp, hum = getRoot(), getHum()
            if hrp then hrp.Anchored = false; if FC.savedCharCFrame then hrp.CFrame = FC.savedCharCFrame; FC.savedCharCFrame = nil end end
            if hum then hum.WalkSpeed = State.Move.ws; hum.UseJumpPower = true; hum.JumpPower = State.Move.jp; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            Cam.FieldOfView = 70; Cam.CameraType = Enum.CameraType.Custom
        end
    end
})
T_CI:Slider({ Title = "⚡ Speed", Min = 1, Max = 30, Value = 5, Callback = function(v) FC.speed = v end })
T_CI:Slider({ Title = "🎯 Sensitivity", Min = 1, Max = 20, Value = 5, Callback = function(v) FC.sens = v * 0.05 end })
T_CI:Slider({ Title = "📊 Damping (Smoothness)", Min = 0.5, Max = 1, Value = 0.85, Callback = function(v) FC.damping = v end })
T_CI:Slider({ Title = "⚙️ Acceleration", Min = 0.05, Max = 0.5, Value = 0.15, Callback = function(v) FC.acceleration = v end })
T_CI:Slider({ Title = "🔍 FOV", Min = 10, Max = 120, Value = 70, Callback = function(v) Cam.FieldOfView = v end })

T_CI:Section({Title = "📱 Display"})
T_CI:Button({ Title = "📱 Screen: Portrait", Callback = function() pcall(function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end) end })
T_CI:Button({ Title = "📺 Screen: Landscape", Callback = function() pcall(function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end) end })

T_CI:Section({Title = "🎬 Presets"})
local function applyPreset(fov, speed, clock, bright, fogEnd, fogR, fogG, fogB, ambR, ambG, ambB, density, offset, glare, halo, gfxLevel)
    Cam.FieldOfView = fov; FC.speed = speed; Lighting.ClockTime = clock; Lighting.Brightness = bright; Lighting.FogEnd = fogEnd
    Lighting.FogColor = Color3.fromRGB(fogR, fogG, fogB); Lighting.Ambient = Color3.fromRGB(ambR, ambG, ambB)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Density = density; atm.Offset = offset; atm.Glare = glare; atm.Halo = halo
    pcall(function() settings().Rendering.QualityLevel = gfxLevel end)
end
T_CI:Button({ Title = "☀️ Cinematic Day", Callback = function() applyPreset(50,3,14,2,10000,200,220,255,120,120,120,0.05,0.1,0.3,0.2,Enum.QualityLevel.Level10) end })
T_CI:Button({ Title = "🌃 Night Cinematic", Callback = function() applyPreset(45,2,0,0.3,20000,10,10,30,20,20,40,0.02,0.0,0.0,0.1,Enum.QualityLevel.Level10) end })
T_CI:Button({ Title = "🔄 Reset Semua Default", Callback = function() applyPreset(70,5,14,1,100000,191,191,191,70,70,70,0.35,0.0,0.0,0.25,Enum.QualityLevel.Level05) end })

-- ==================== TAB: SPECTATE ====================
local T_SP = Window:Tab({ Title = "Spectate", Icon = "eye" })

T_SP:Section({Title = "👁️ Target Selection"})
local specDrop = T_SP:Dropdown({ Title = "Pilih Target", Values = getDisplayNames(), Value = "", Callback = function(v)
    local p = findPlayerByDisplay(v)
    if p then Spec.target = p; if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ(); Spec.orbitYaw = math.deg(ry); Spec.orbitPitch = 20; Spec.fpYaw = math.deg(ry); Spec.fpPitch = 0 end end
end})
T_SP:Button({ Title = "🔄 Refresh List", Callback = function() Spec.target = nil; pcall(function() specDrop:Refresh(getDisplayNames()) end) end })

T_SP:Section({Title = "⚙️ Controls"})
T_SP:Toggle({ Title = "🙈 Hide Target Name", Value = false, Callback = function(v) State.Spectate.hideName = v end })
T_SP:Toggle({ Title = "👁️ Spectate ON/OFF", Value = false, Callback = function(v)
    Spec.active = v
    if v then
        if not Spec.target then WindUI:Notify({Title="Error", Content="Pilih target dulu!", Duration=2}); Spec.active = false; return end
        Spec.origFov = Cam.FieldOfView; startSpecCapture(); startSpecLoop()
        local dispName = State.Spectate.hideName and "[HIDDEN]" or Spec.target.DisplayName
        WindUI:Notify({Title="Spectating", Content="Nonton: " .. dispName, Duration=3})
    else
        stopSpecLoop(); stopSpecCapture(); Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov
    end
end})
T_SP:Toggle({ Title = "🎥 First Person Drone", Value = false, Callback = function(v)
    Spec.mode = v and "first" or "third"
    if v and Spec.target and Spec.target.Character then local _, ry, _ = Cam.CFrame:ToEulerAnglesYXZ(); local rx = math.asin(Cam.CFrame.LookVector.Y); Spec.fpYaw = math.deg(ry); Spec.fpPitch = math.deg(rx) end
end})
T_SP:Slider({ Title = "📏 Jarak Orbit", Min = 3, Max = 30, Value = 8, Callback = function(v) Spec.dist = v end })
T_SP:Button({ Title = "🔄 Reset POV Camera (Fix Bug)", Callback = function()
    local r, h = getRoot(), getHum()
    if not r or not h then return end
    Cam.CameraType = Enum.CameraType.Custom; task.wait(0.05); Cam.CameraType = Enum.CameraType.Scriptable; task.wait(0.05); Cam.CameraType = Enum.CameraType.Custom
    pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
end})

-- ==================== TAB: WORLD & PERFORMANCE ====================
local T_WO = Window:Tab({ Title = "World & Perf", Icon = "globe" })

T_WO:Section({Title = "🌦️ Weather & Light"})
local function setWeather(clock, bright, fogStart, fogEnd, fogR, fogG, fogB, ambR, ambG, ambB, density, offset, glare, halo)
    Lighting.ClockTime = clock; Lighting.Brightness = bright; Lighting.FogStart = fogStart; Lighting.FogEnd = fogEnd
    Lighting.FogColor = Color3.fromRGB(fogR, fogG, fogB); Lighting.Ambient = Color3.fromRGB(ambR, ambG, ambB)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Density = density; atm.Offset = offset; atm.Glare = glare; atm.Halo = halo
end
T_WO:Button({ Title = "☀️ Cerah", Callback = function() setWeather(14, 2, 1000, 10000, 200,220,255, 120,120,120, 0.05, 0.1, 0.3, 0.2) end })
T_WO:Button({ Title = "🌃 Malam Bintang", Callback = function() setWeather(0, 0.3, 2000, 20000, 10,10,30, 20,20,40, 0.02, 0.0, 0.0, 0.1) end })
T_WO:Slider({ Title = "🕐 ClockTime", Min = 0, Max = 24, Value = 14, Callback = function(v) Lighting.ClockTime = v end })

T_WO:Section({Title = "🚀 Performance"})
T_WO:Button({ Title = "🚀 60 FPS", Callback = function() if setfpscap then setfpscap(60) end end })
T_WO:Button({ Title = "🚀 Max FPS (999)", Callback = function() if setfpscap then setfpscap(999) end end })
local AntiLagState = { materials = {}, textures = {}, shadows = true }
T_WO:Toggle({ Title = "🗑️ Anti Lag Mode (Delete Textures)", Value = false, Callback = function(v)
    if v then
        AntiLagState.shadows = Lighting.GlobalShadows; Lighting.GlobalShadows = false
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then AntiLagState.materials[obj] = obj.Material; obj.Material = Enum.Material.SmoothPlastic
            elseif obj:IsA("Texture") or obj:IsA("Decal") then AntiLagState.textures[obj] = obj.Parent; obj.Parent = nil end
        end
    else
        Lighting.GlobalShadows = AntiLagState.shadows
        for obj, mat in pairs(AntiLagState.materials) do if obj and obj.Parent then obj.Material = mat end end
        for obj, parent in pairs(AntiLagState.textures) do if obj and parent and parent.Parent then obj.Parent = parent end end
        AntiLagState.materials = {}; AntiLagState.textures = {}
    end
end})

-- ==================== TAB: SECURITY & ESP ====================
local T_SC = Window:Tab({ Title = "Security & ESP", Icon = "shield" })

T_SC:Section({Title = "🛡️ Protection"})
T_SC:Toggle({ Title = "Anti-AFK (Bypass)", Value = false, Callback = function(v)
    if v then
        State.Security.afkConn = LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); VirtualUser:Button2Down(Vector2.new(0,0), Cam.CFrame); task.wait(1); VirtualUser:Button2Up(Vector2.new(0,0), Cam.CFrame) end)
        pcall(function() for _, conn in pairs(getconnections(LP.Idled)) do conn:Disable() end end)
    else
        if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn = nil end
        pcall(function() for _, conn in pairs(getconnections(LP.Idled)) do conn:Enable() end end)
    end
end})

local respawnLastPos = nil
task.spawn(function() while true do task.wait(1); local r = getRoot(); local h = getHum(); if r and h and h.Health > 0 then respawnLastPos = r.CFrame end end end)
T_SC:Button({ Title = "💀 Fast Respawn", Callback = function()
    if not respawnLastPos or not getHum() then return end
    local savedCF = respawnLastPos; getHum().Health = 0
    task.spawn(function() local char = LP.CharacterAdded:Wait(); task.wait(0.3); local hrp = char:WaitForChild("HumanoidRootPart", 10); if hrp then hrp.CFrame = savedCF end end)
end})

T_SC:Section({Title = "🎯 Modern ESP Tracker"})
T_SC:Toggle({ Title = "🎬 ESP Master ON/OFF", Value = false, Callback = function(v)
    State.ESP.active = v
    if not v then
        for _, cache in pairs(State.ESP.cache) do
            for _, render in pairs(cache.renders) do if render and render.Parent then render:Destroy() end end
            if cache.highlight then cache.highlight:Destroy() end
            if cache.bg then cache.bg:Destroy() end
        end; State.ESP.cache = {}
    end
end})
T_SC:Dropdown({ Title = "📦 Box Mode", Values = {"Corner", "2D Box", "HIGHLIGHT", "OFF"}, Value = "Corner", Callback = function(v) State.ESP.boxMode = v end })
T_SC:Dropdown({ Title = "🔴 Tracer Mode", Values = {"Bottom", "Center", "Mouse", "OFF"}, Value = "Bottom", Callback = function(v) State.ESP.tracerMode = v end })
T_SC:Toggle({ Title = "📍 Show Distance", Value = true, Callback = function(v) State.ESP.showDistance = v end })
T_SC:Toggle({ Title = "👤 Show Nickname", Value = true, Callback = function(v) State.ESP.showNickname = v end })
T_SC:Slider({ Title = "📏 Draw Distance", Min = 50, Max = 1000, Value = 300, Callback = function(v) State.ESP.maxDrawDistance = v end })

T_SC:Section({Title = "💾 ESP Presets"})
T_SC:Button({ Title = "🕵️ Legit (Text Only)", Callback = function() State.ESP.boxMode="OFF"; State.ESP.tracerMode="OFF"; State.ESP.showDistance=true; State.ESP.showNickname=true end })
T_SC:Button({ Title = "🧼 Clean (Corner Only)", Callback = function() State.ESP.boxMode="Corner"; State.ESP.tracerMode="OFF"; State.ESP.showDistance=false; State.ESP.showNickname=false end })
T_SC:Button({ Title = "🚨 Anti-Glitcher (Highlight)", Callback = function() State.ESP.boxMode="HIGHLIGHT"; State.ESP.tracerMode="Bottom"; State.ESP.showDistance=true; State.ESP.showNickname=true end })

-- ==================== TAB: SETTINGS (WINDUI) ====================
local ThemeTab = Window:Tab({ Title = "Settings", Icon = "settings" })
ThemeTab:Dropdown({
    Title  = "Theme",
    Values = (function() local names = {}; for name in pairs(WindUI:GetThemes()) do table.insert(names, name) end; table.sort(names); return names end)(),
    Value    = WindUI:GetCurrentTheme(),
    Callback = function(selected) WindUI:SetTheme(selected) end,
})
ThemeTab:Toggle({ Title = "Acrylic Glass", Value = WindUI:GetTransparency(), Callback = function() WindUI:ToggleAcrylic(not WindUI.Window.Acrylic) end })
ThemeTab:Toggle({ Title = "Transparent Background", Value = WindUI:GetTransparency(), Callback = function(state) Window:ToggleTransparency(state) end })
local currentKey = Enum.KeyCode.RightShift
ThemeTab:Keybind({
    Title = "Toggle UI Key", Value = currentKey,
    Callback = function(v) currentKey = (typeof(v) == "EnumItem") and v or Enum.KeyCode[v]; Window:SetToggleKey(currentKey) end,
})
UIS.InputBegan:Connect(function(input) if input.KeyCode == currentKey then Window:Toggle() end end)

-- BACKGROUND LOOPS (Fling, Noclip)
task.spawn(function()
    while true do
        if (State.Fling.active or State.SoftFling.active) and getRoot() then
            local r = getRoot()
            local isBrutal = State.Fling.active
            local pwr = isBrutal and State.Fling.power or State.SoftFling.power
            pcall(function() r.AssemblyAngularVelocity = Vector3.new(0, pwr, 0); if isBrutal then r.AssemblyLinearVelocity = Vector3.new(pwr, pwr, pwr) end end)
        end
        RS.RenderStepped:Wait()
    end
end)

RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active or State.SoftFling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

WindUI:Notify({Title = "✦ XKID HUB v4 ✦", Content = "Modern Update & ESP Fixed. Ready! 🚀", Duration = 5})
