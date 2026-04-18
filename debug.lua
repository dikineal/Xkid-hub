--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    ✦  X K I D     H U B  ✦   WindUI Edition                 ║
║                                                              ║
║   ✅ Modern ESP (Corner/2D Box) + Dynamic Origin Tracer      ║
║   ✅ Smooth Freecam (Damping + Velocity)                     ║
║   ✅ WindUI - Clean Modern Interface                         ║
║   ✅ Auto Suspect Detection (Anti-Glitcher)                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
]]

-- ┌─────────────────────────────────────────────────────────┐
-- │                ➤  LOAD WIND UI                          │
-- └─────────────────────────────────────────────────────────┘
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Services
local Players       = game:GetService("Players")
local RS            = game:GetService("RunService")
local UIS           = game:GetService("UserInputService")
local VirtualUser   = game:GetService("VirtualUser")
local Lighting      = game:GetService("Lighting")
local TPService     = game:GetService("TeleportService")
local LP            = Players.LocalPlayer
local Cam           = workspace.CurrentCamera

-- ┌─────────────────────────────────────────────────────────┐
-- │                ➤  GLOBAL STATE                          │
-- └─────────────────────────────────────────────────────────┘
local State = {
    Move     = {ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60},
    Fly      = {active = false, bv = nil, bg = nil},
    Fling    = {active = false, power = 1000000},
    SoftFling= {active = false, power = 4000},
    Teleport = {selectedTarget = ""},
    Security = {afkConn = nil},
    Cinema   = {active = false, speed = 1, fov = 70, lastPos = nil},
    Spectate = {hideName = false},
    ESP = {
        active           = false,
        cache            = {},
        boxMode          = "Corner",
        tracerMode       = "Bottom",
        maxDrawDistance  = 300,
        showDistance     = true,
        showNickname     = true,
        boxColor_Normal  = Color3.fromRGB(0, 255, 150),
        boxColor_Suspect = Color3.fromRGB(255, 0, 100),
        tracerColor_Normal  = Color3.fromRGB(0, 200, 255),
        tracerColor_Suspect = Color3.fromRGB(255, 50, 50),
    }
}

-- ┌─────────────────────────────────────────────────────────┐
-- │                ➤  HELPERS                               │
-- └─────────────────────────────────────────────────────────┘
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum()  return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end

local function getPNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    return t
end

local function getDisplayNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    return t
end

local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do
        if str == p.DisplayName .. " (@" .. p.Name .. ")" then return p end
    end
    return nil
end

local function getCharRoot(char)
    if not char then return nil end
    return char.PrimaryPart
        or char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
end

-- Persistent movement on respawn
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then
            hum.UseJumpPower = true
            hum.JumpPower = State.Move.jp
        end
    end
end)

-- Mobile detect
local onMobile = not UIS.KeyboardEnabled

-- ┌─────────────────────────────────────────────────────────┐
-- │              ➤  MODERN ESP ENGINE                       │
-- └─────────────────────────────────────────────────────────┘
local function getESPGui()
    local sg = LP.PlayerGui:FindFirstChild("XKIDEspGui")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "XKIDEspGui"
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.Parent = LP.PlayerGui
    end
    return sg
end

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
    line.Parent = getESPGui()
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
    local width  = height * 0.6
    local tl = Vector2.new(botScreen.X - width/2, topScreen.Y)
    local tr = Vector2.new(botScreen.X + width/2, topScreen.Y)
    local bl = Vector2.new(botScreen.X - width/2, botScreen.Y)
    local br = Vector2.new(botScreen.X + width/2, botScreen.Y)
    local lines = {}
    if isCorner then
        local len = width / 3.5
        table.insert(lines, drawLine2D(tl, tl + Vector2.new(len, 0),  thickness, color))
        table.insert(lines, drawLine2D(tl, tl + Vector2.new(0, len),  thickness, color))
        table.insert(lines, drawLine2D(tr, tr - Vector2.new(len, 0),  thickness, color))
        table.insert(lines, drawLine2D(tr, tr + Vector2.new(0, len),  thickness, color))
        table.insert(lines, drawLine2D(bl, bl + Vector2.new(len, 0),  thickness, color))
        table.insert(lines, drawLine2D(bl, bl - Vector2.new(0, len),  thickness, color))
        table.insert(lines, drawLine2D(br, br - Vector2.new(len, 0),  thickness, color))
        table.insert(lines, drawLine2D(br, br - Vector2.new(0, len),  thickness, color))
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
    if lpRoot and (lpRoot.Position - hrp.Position).Magnitude > State.ESP.maxDrawDistance then return end

    local isSuspect   = isSuspectPlayer(player)
    local boxColor    = isSuspect and State.ESP.boxColor_Suspect    or State.ESP.boxColor_Normal
    local tracerColor = isSuspect and State.ESP.tracerColor_Suspect or State.ESP.tracerColor_Normal

    if not State.ESP.cache[player] then
        State.ESP.cache[player] = {renders = {}, highlight = nil}
    end
    local cache = State.ESP.cache[player]
    for _, render in pairs(cache.renders) do
        if render and render.Parent then render:Destroy() end
    end
    cache.renders = {}

    -- Box / Highlight
    if State.ESP.boxMode == "Corner" or State.ESP.boxMode == "2D Box" then
        if cache.highlight then cache.highlight.Enabled = false end
        local isCorner = (State.ESP.boxMode == "Corner")
        local lines = drawBox2D(hrp, boxColor, 2, isCorner)
        for _, l in ipairs(lines) do table.insert(cache.renders, l) end

    elseif State.ESP.boxMode == "HIGHLIGHT" then
        if not cache.highlight or cache.highlight.Parent ~= char then
            if cache.highlight then cache.highlight:Destroy() end
            local hl = Instance.new("Highlight")
            hl.Parent    = char
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            cache.highlight = hl
        end
        cache.highlight.FillColor           = boxColor
        cache.highlight.OutlineColor        = Color3.new(1, 1, 1)
        cache.highlight.FillTransparency    = 0.5
        cache.highlight.OutlineTransparency = 0
        cache.highlight.Enabled             = true
    else
        if cache.highlight then cache.highlight.Enabled = false end
    end

    -- Tracer
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

    -- Text Info
    local showText = State.ESP.showNickname or State.ESP.showDistance or isSuspect
    if showText then
        local screenPos, onScreen = worldToScreen(hrp.Position)
        if onScreen then
            local label = Instance.new("TextLabel")
            label.Name                  = "ESPInfo"
            label.BackgroundTransparency = 1
            label.TextColor3            = boxColor
            label.TextSize              = 11
            label.Font                  = Enum.Font.GothamBold
            label.Position              = UDim2.new(0, screenPos.X + 10, 0, screenPos.Y - 20)
            label.Size                  = UDim2.new(0, 150, 0, 40)
            label.TextXAlignment        = Enum.TextXAlignment.Left
            label.TextStrokeTransparency = 0.5
            label.TextStrokeColor3      = Color3.new(0, 0, 0)
            local infoText = ""
            if State.ESP.showNickname then infoText = player.DisplayName end
            if State.ESP.showDistance and lpRoot then
                local dist = math.floor((lpRoot.Position - hrp.Position).Magnitude)
                infoText = infoText .. (infoText ~= "" and "\n" or "") .. "📍 " .. dist .. "m"
            end
            if isSuspect then
                infoText = infoText .. (infoText ~= "" and "\n" or "") .. "⚠️ GLITCHER"
            end
            label.Text   = infoText
            label.Parent = getESPGui()
            table.insert(cache.renders, label)
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
        if State.ESP.cache[player].highlight then
            State.ESP.cache[player].highlight:Destroy()
        end
        State.ESP.cache[player] = nil
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │              ➤  FLY ENGINE                              │
-- └─────────────────────────────────────────────────────────┘
local flyMoveTouch = nil
local flyMoveSt    = nil
local flyJoy       = Vector2.zero
local flyConns     = {}

local function startFlyCapture()
    local keysHeld = {}
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or
           k == Enum.KeyCode.S or k == Enum.KeyCode.D or
           k == Enum.KeyCode.E or k == Enum.KeyCode.Q then
            keysHeld[k] = true
        end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp)
        keysHeld[inp.KeyCode] = false
    end))
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
    flyConns = {}; flyMoveTouch = nil; flyMoveSt = nil
    flyJoy = Vector2.zero; State.Fly._keys = {}
end

local function toggleFly(v)
    if not v then
        State.Fly.active = false
        stopFlyCapture()
        RS:UnbindFromRenderStep("XKIDFly")
        if State.Fly.bv then State.Fly.bv:Destroy(); State.Fly.bv = nil end
        if State.Fly.bg then State.Fly.bg:Destroy(); State.Fly.bg = nil end
        local hum = getHum()
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            hum.WalkSpeed = State.Move.ws
            hum.UseJumpPower = true
            hum.JumpPower = State.Move.jp
        end
        WindUI:Notify({ Title = "Fly", Content = "✈️ Fly OFF", Duration = 2 })
        return
    end
    local hrp = getRoot(); local hum = getHum()
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
        local r = getRoot(); local h = getHum()
        if not r or not h then return end
        local camCF = Cam.CFrame
        local spd   = State.Move.flyS
        local move  = Vector3.zero
        local keys  = State.Fly._keys or {}
        if onMobile then
            move = camCF.LookVector * (-flyJoy.Y) * spd
                 + camCF.RightVector * flyJoy.X   * spd
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
        State.Fly.bg.CFrame   = CFrame.new(r.Position, r.Position + camCF.LookVector)
    end)
    WindUI:Notify({ Title = "Fly", Content = "✈️ Fly ON — Ikut arah kamera", Duration = 3 })
end

-- ┌─────────────────────────────────────────────────────────┐
-- │        ➤  FREECAM ENGINE (SMOOTH + MOBILE READY)        │
-- └─────────────────────────────────────────────────────────┘
local FC = {
    active          = false,
    pos             = Vector3.zero,
    vel             = Vector3.zero,
    pitchDeg        = 0,
    yawDeg          = 0,
    speed           = 1,
    sens            = 0.25,
    savedCharCFrame = nil,
    damping         = 0.85,
    acceleration    = 0.15,
}

local fcRotTouch  = nil; local fcMoveTouch = nil
local fcMoveSt    = nil; local fcRotLast   = nil
local fcJoy       = Vector2.zero
local DEAD_X      = 25;  local DEAD_Y = 20
local fcConns     = {}

local function startFCCapture()
    local keysHeld = {}
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or
           k == Enum.KeyCode.S or k == Enum.KeyCode.D or
           k == Enum.KeyCode.E or k == Enum.KeyCode.Q then
            keysHeld[k] = true
        end
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            FC._mouseRotate = true
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        keysHeld[inp.KeyCode] = false
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            FC._mouseRotate = false
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end))
    table.insert(fcConns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and FC._mouseRotate then
            FC.yawDeg   = FC.yawDeg   - inp.Delta.X * FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg - inp.Delta.Y * FC.sens, -80, 80)
        end
        if inp.UserInputType == Enum.UserInputType.MouseWheel then
            Cam.FieldOfView = math.clamp(Cam.FieldOfView - inp.Position.Z * 5, 10, 120)
        end
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
            FC.yawDeg   = FC.yawDeg   - (inp.Position.X - fcRotLast.X) * FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg - (inp.Position.Y - fcRotLast.Y) * FC.sens, -80, 80)
            fcRotLast = inp.Position
        end
        if inp == fcMoveTouch and fcMoveSt then
            local dx = inp.Position.X - fcMoveSt.X
            local dy = inp.Position.Y - fcMoveSt.Y
            local nx = 0; local ny = 0
            if math.abs(dx) > DEAD_X then nx = math.clamp((dx - math.sign(dx)*DEAD_X)/80,-1,1) end
            if math.abs(dy) > DEAD_Y then ny = math.clamp((dy - math.sign(dy)*DEAD_Y)/80,-1,1) end
            fcJoy = Vector2.new(nx, ny)
        end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == fcRotTouch  then fcRotTouch  = nil; fcRotLast  = nil end
        if inp == fcMoveTouch then fcMoveTouch = nil; fcMoveSt   = nil; fcJoy = Vector2.zero end
    end))
    FC._keys = keysHeld
end

local function stopFCCapture()
    for _, c in ipairs(fcConns) do c:Disconnect() end
    fcConns = {}; fcRotTouch = nil; fcMoveTouch = nil
    fcMoveSt = nil; fcRotLast = nil; fcJoy = Vector2.zero
    FC._mouseRotate = false; FC._keys = {}
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

local function startFCLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable
        local cf = CFrame.new(FC.pos)
            * CFrame.Angles(0, math.rad(FC.yawDeg), 0)
            * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local spd        = FC.speed * 32
        local desiredVel = Vector3.zero
        local keys       = FC._keys or {}
        if onMobile then
            desiredVel = cf.LookVector * (-fcJoy.Y) * spd + cf.RightVector * fcJoy.X * spd
        else
            if keys[Enum.KeyCode.W] then desiredVel = desiredVel + cf.LookVector  * spd end
            if keys[Enum.KeyCode.S] then desiredVel = desiredVel - cf.LookVector  * spd end
            if keys[Enum.KeyCode.D] then desiredVel = desiredVel + cf.RightVector * spd end
            if keys[Enum.KeyCode.A] then desiredVel = desiredVel - cf.RightVector * spd end
            if keys[Enum.KeyCode.E] then desiredVel = desiredVel + Vector3.new(0,1,0) * spd end
            if keys[Enum.KeyCode.Q] then desiredVel = desiredVel - Vector3.new(0,1,0) * spd end
        end
        FC.vel = FC.vel:Lerp(desiredVel, FC.acceleration * dt * 60)
        FC.vel = FC.vel * (FC.damping ^ (dt * 60))
        FC.pos = FC.pos + FC.vel * dt
        Cam.CFrame = CFrame.new(FC.pos)
            * CFrame.Angles(0, math.rad(FC.yawDeg), 0)
            * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local hrp = getRoot(); local hum = getHum()
        if hrp and not hrp.Anchored then hrp.Anchored = true end
        if hum then
            if hum:GetState() ~= Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.Physics)
            end
            hum.WalkSpeed = 0; hum.JumpPower = 0
        end
    end)
end

local function stopFCLoop()
    RS:UnbindFromRenderStep("XKIDFreecam")
end

-- ┌─────────────────────────────────────────────────────────┐
-- │              ➤  WIND UI WINDOW                          │
-- └─────────────────────────────────────────────────────────┘
local Window = WindUI:CreateWindow({
    Title       = "✦ XKID HUB",
    Author      = "WindUI Edition",
    Folder      = "XKIDHub",
    Icon        = "shield",
    Theme       = "Dark",
    Acrylic     = true,
    Transparent = true,
    Size        = UDim2.fromOffset(680, 460),
    MinSize     = Vector2.new(560, 350),
    MaxSize     = Vector2.new(850, 560),
    ToggleKey   = Enum.KeyCode.RightShift,
    Resizable   = true,
    AutoScale   = true,
    NewElements = true,
    OpenButton  = {
        Title        = "XKID",
        Icon         = "shield",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled      = true,
        Draggable    = true,
        OnlyMobile   = false,
        Scale        = 1,
        Color        = ColorSequence.new(
            Color3.fromHex("#00FF96"),
            Color3.fromHex("#0096FF")
        ),
    },
    User = {
        Enabled   = true,
        Anonymous = false,
        Callback  = function() print("user panel clicked") end,
    },
})

-- ════════════════════════════════════════════════════════════
-- TAB 1: TELEPORT
-- ════════════════════════════════════════════════════════════
local T_TP     = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local TPNav    = T_TP:Section({ Title = "🎯 Smart Search" })

local tpTarget = ""
TPNav:Input({
    Title       = "Ketik Nama / 2-3 Huruf",
    Placeholder = "nama player...",
    Callback    = function(v) tpTarget = v end,
})
TPNav:Button({
    Title    = "🚀 Teleport Now",
    Desc     = "Cari & teleport otomatis",
    Callback = function()
        if tpTarget == "" then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                local nameMatch = string.find(string.lower(p.Name), string.lower(tpTarget))
                local dispMatch = string.find(string.lower(p.DisplayName), string.lower(tpTarget))
                if (nameMatch or dispMatch) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    getRoot().CFrame = p.Character.HumanoidRootPart.CFrame
                    WindUI:Notify({ Title = "Teleport", Content = "✅ TP ke " .. p.DisplayName, Duration = 2 })
                    return
                end
            end
        end
        WindUI:Notify({ Title = "Teleport", Content = "❌ Player tidak ditemukan!", Duration = 2 })
    end,
})

local pDropOptions = getPNames()
local pDropSelected = ""
TPNav:Dropdown({
    Title    = "Manual List",
    Values   = pDropOptions,
    Callback = function(v) pDropSelected = v; tpTarget = v end,
})
TPNav:Button({
    Title    = "🔄 Refresh List",
    Callback = function()
        pDropOptions = getPNames()
        WindUI:Notify({ Title = "Teleport", Content = "List diperbarui!", Duration = 2 })
    end,
})

-- Save / Load Locations
local LocSection = T_TP:Section({ Title = "📍 Save & Load Location" })
local SavedLocs  = {}

for i = 1, 5 do
    local idx = i
    LocSection:Button({
        Title    = "💾 Save Slot " .. idx,
        Desc     = "Simpan posisi sekarang ke slot " .. idx,
        Callback = function()
            local r = getRoot()
            if not r then WindUI:Notify({ Title = "Location", Content = "❌ Karakter tidak ditemukan!", Duration = 2 }); return end
            SavedLocs[idx] = r.CFrame
            WindUI:Notify({ Title = "✅ Saved", Content = "Slot " .. idx .. " tersimpan!", Duration = 2 })
        end,
    })
end
for i = 1, 5 do
    local idx = i
    LocSection:Button({
        Title    = "📍 Load Slot " .. idx,
        Desc     = "Teleport ke slot " .. idx,
        Callback = function()
            if not SavedLocs[idx] then WindUI:Notify({ Title = "❌ Kosong", Content = "Slot " .. idx .. " belum di-save!", Duration = 2 }); return end
            local r = getRoot()
            if not r then return end
            r.CFrame = SavedLocs[idx]
            WindUI:Notify({ Title = "📍 Loaded", Content = "Teleport ke Slot " .. idx, Duration = 2 })
        end,
    })
end

-- ════════════════════════════════════════════════════════════
-- TAB 2: PLAYER
-- ════════════════════════════════════════════════════════════
local T_PL  = Window:Tab({ Title = "Player", Icon = "user" })

-- Movement Section
local PLMov = T_PL:Section({ Title = "⚡ Movement" })

PLMov:Button({
    Title    = "🔄 Refresh POV",
    Desc     = "Reset kamera & karakter",
    Callback = function()
        local r = getRoot(); local h = getHum()
        if not r or not h then WindUI:Notify({ Title = "Refresh", Content = "❌ Karakter tidak ditemukan!", Duration = 2 }); return end
        Cam.CameraType = Enum.CameraType.Custom; task.wait(0.05)
        Cam.CameraType = Enum.CameraType.Scriptable; task.wait(0.05)
        Cam.CameraType = Enum.CameraType.Custom
        pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        WindUI:Notify({ Title = "✅ Refresh", Content = "POV & kamera di-reset!", Duration = 2 })
    end,
})

PLMov:Slider({
    Title    = "🏃 WalkSpeed",
    Desc     = "16 - 500",
    Min      = 16,
    Max      = 500,
    Default  = 16,
    Callback = function(v)
        State.Move.ws = v
        if getHum() then getHum().WalkSpeed = v end
    end,
})

PLMov:Slider({
    Title    = "🦘 JumpPower",
    Desc     = "50 - 500",
    Min      = 50,
    Max      = 500,
    Default  = 50,
    Callback = function(v)
        State.Move.jp = v
        local hum = getHum()
        if hum then hum.UseJumpPower = true; hum.JumpPower = v end
    end,
})

PLMov:Toggle({
    Title    = "∞ Inf Jump",
    Desc     = "Lompat terus menerus",
    Default  = false,
    Callback = function(v)
        if v then
            State.Move.infJ = UIS.JumpRequest:Connect(function()
                if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end
        end
    end,
})

-- Abilities Section
local PLAbi = T_PL:Section({ Title = "🚀 Abilities" })

PLAbi:Toggle({
    Title    = "✈️ Native Fly",
    Desc     = "Terbang mengikuti arah kamera",
    Default  = false,
    Callback = function(v) toggleFly(v) end,
})

PLAbi:Slider({
    Title    = "✈️ Fly Speed",
    Desc     = "10 - 300",
    Min      = 10,
    Max      = 300,
    Default  = 60,
    Callback = function(v) State.Move.flyS = v end,
})

PLAbi:Toggle({
    Title    = "👻 NoClip",
    Desc     = "Tembus dinding",
    Default  = false,
    Callback = function(v) State.Move.ncp = v end,
})

PLAbi:Toggle({
    Title    = "💥 IY Fling (Brutal)",
    Desc     = "Fling kencang + noclip",
    Default  = false,
    Callback = function(v) State.Fling.active = v; State.Move.ncp = v end,
})

PLAbi:Toggle({
    Title    = "💫 Soft Fling",
    Desc     = "Fling pelan (jatuh)",
    Default  = false,
    Callback = function(v) State.SoftFling.active = v; State.Move.ncp = v end,
})

local noFallConn = nil
PLAbi:Toggle({
    Title    = "🛡️ No Fall Damage",
    Desc     = "Anti mati saat jatuh",
    Default  = false,
    Callback = function(v)
        if v then
            noFallConn = RS.Heartbeat:Connect(function()
                local hrp = getRoot()
                if hrp and hrp.Velocity.Y < -30 then
                    hrp.Velocity = Vector3.new(hrp.Velocity.X, -10, hrp.Velocity.Z)
                end
            end)
        else
            if noFallConn then noFallConn:Disconnect(); noFallConn = nil end
        end
    end,
})

local godConn = nil; local godRespawn = nil; local godLastPos = nil
PLAbi:Toggle({
    Title    = "🛡️ God Mode",
    Desc     = "HP Infinite + Auto Respawn ke posisi terakhir",
    Default  = false,
    Callback = function(v)
        if v then
            local hum = getHum()
            if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
            godLastPos = getRoot() and getRoot().CFrame
            godRespawn = RS.Heartbeat:Connect(function()
                local r = getRoot()
                if r then godLastPos = r.CFrame end
            end)
            godConn = RS.Heartbeat:Connect(function()
                local h = getHum()
                if h then
                    if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
                    if h.MaxHealth ~= math.huge then h.MaxHealth = math.huge end
                end
            end)
            LP.CharacterAdded:Connect(function(char)
                task.wait(0.2)
                local hrp = char:WaitForChild("HumanoidRootPart", 5)
                if hrp and godLastPos then hrp.CFrame = godLastPos end
                local h = char:WaitForChild("Humanoid", 5)
                if h then h.MaxHealth = math.huge; h.Health = math.huge end
            end)
            WindUI:Notify({ Title = "God Mode", Content = "🛡️ HP Infinite + Auto Respawn aktif!", Duration = 3 })
        else
            if godConn    then godConn:Disconnect();    godConn    = nil end
            if godRespawn then godRespawn:Disconnect(); godRespawn = nil end
            local hum = getHum()
            if hum then hum.MaxHealth = 100; hum.Health = 100 end
            WindUI:Notify({ Title = "God Mode", Content = "❌ Nonaktif", Duration = 2 })
        end
    end,
})

-- Shift Lock Section
local PLLock = T_PL:Section({ Title = "🎯 Shift Lock" })
local shiftLockConn = nil
PLLock:Toggle({
    Title    = "🎯 Enable Shift Lock",
    Desc     = "Karakter selalu hadap arah kamera",
    Default  = false,
    Callback = function(v)
        local hum = getHum(); local hrp = getRoot()
        if not hum or not hrp then WindUI:Notify({ Title = "Shift Lock", Content = "❌ Karakter tidak ditemukan!", Duration = 2 }); return end
        if v then
            hum.CameraOffset = Vector3.new(1.75, 0, 0)
            hum.AutoRotate   = false
            shiftLockConn = RS.RenderStepped:Connect(function()
                local r = getRoot()
                if r then
                    local camLook = Cam.CFrame.LookVector
                    r.CFrame = CFrame.new(r.Position, r.Position + Vector3.new(camLook.X, 0, camLook.Z))
                end
            end)
            WindUI:Notify({ Title = "Shift Lock", Content = "🎯 Aktif!", Duration = 2 })
        else
            if shiftLockConn then shiftLockConn:Disconnect(); shiftLockConn = nil end
            local h = getHum()
            if h then h.CameraOffset = Vector3.zero; h.AutoRotate = true end
            WindUI:Notify({ Title = "Shift Lock", Content = "🔓 Nonaktif", Duration = 2 })
        end
    end,
})

-- Atmosphere Section
local PLAtmos = T_PL:Section({ Title = "🌦️ Waktu & Cahaya" })
PLAtmos:Slider({
    Title    = "🕐 ClockTime",
    Min      = 0, Max = 24, Default = 12,
    Callback = function(v) Lighting.ClockTime = v end,
})
PLAtmos:Button({ Title = "☀️ Set Siang", Callback = function() Lighting.ClockTime = 14 end })
PLAtmos:Button({ Title = "🌙 Set Malam", Callback = function() Lighting.ClockTime = 0 end })

-- ════════════════════════════════════════════════════════════
-- TAB 3: CINEMATIC
-- ════════════════════════════════════════════════════════════
local T_CI  = Window:Tab({ Title = "Cinematic", Icon = "video" })
local CISec = T_CI:Section({ Title = "🎬 Freecam Controls" })

CISec:Toggle({
    Title    = "🎬 Freecam ON/OFF",
    Desc     = "PC: RMB rotate | Mobile: Kiri gerak, Kanan rotate",
    Default  = false,
    Callback = function(v)
        FC.active = v; State.Cinema.active = v
        if v then
            local cf = Cam.CFrame
            FC.pos = cf.Position; FC.vel = Vector3.zero
            local rx, ry = cf:ToEulerAnglesYXZ()
            FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry)
            FC._keys = {}; FC._mouseRotate = false
            local hrp = getRoot(); local hum = getHum()
            if hrp then FC.savedCharCFrame = hrp.CFrame; hrp.Anchored = true end
            if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum:ChangeState(Enum.HumanoidStateType.Physics) end
            startFCCapture(); startFCLoop()
            WindUI:Notify({ Title = "Freecam", Content = "ON — Kiri gerak | Kanan rotate", Duration = 3 })
        else
            stopFCLoop(); stopFCCapture()
            local hrp = getRoot(); local hum = getHum()
            if hrp then
                hrp.Anchored = false
                if FC.savedCharCFrame then hrp.CFrame = FC.savedCharCFrame; FC.savedCharCFrame = nil end
            end
            if hum then
                hum.WalkSpeed = State.Move.ws
                hum.UseJumpPower = true
                hum.JumpPower = State.Move.jp
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            Cam.FieldOfView = 70; Cam.CameraType = Enum.CameraType.Custom
            WindUI:Notify({ Title = "Freecam", Content = "OFF — Balik ke posisi karakter", Duration = 3 })
        end
    end,
})

CISec:Slider({ Title = "⚡ Speed",        Min = 1,    Max = 30,  Default = 5,    Callback = function(v) FC.speed        = v end })
CISec:Slider({ Title = "🎯 Sensitivity",  Min = 1,    Max = 20,  Default = 5,    Callback = function(v) FC.sens         = v * 0.05 end })
CISec:Slider({ Title = "📊 Damping",      Min = 50,   Max = 100, Default = 85,   Callback = function(v) FC.damping      = v * 0.01 end })
CISec:Slider({ Title = "⚙️ Acceleration", Min = 5,    Max = 50,  Default = 15,   Callback = function(v) FC.acceleration = v * 0.01 end })
CISec:Slider({ Title = "🔍 FOV",          Min = 10,   Max = 120, Default = 70,   Callback = function(v) Cam.FieldOfView = v end })

local CIDisp = T_CI:Section({ Title = "📱 Display" })
CIDisp:Button({ Title = "📱 Portrait",  Desc = "Layar tegak",    Callback = function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end })
CIDisp:Button({ Title = "📺 Landscape", Desc = "Layar mendatar", Callback = function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end })

-- Cinematic Presets
local CIPre = T_CI:Section({ Title = "🎬 Preset Sinematik" })

local function applyPreset(fov, speed, clock, bright, fogEnd, fogR, fogG, fogB, ambR, ambG, ambB, density, offset, glare, halo, gfxLevel)
    Cam.FieldOfView = fov; FC.speed = speed
    Lighting.ClockTime = clock; Lighting.Brightness = bright; Lighting.FogEnd = fogEnd
    Lighting.FogColor = Color3.fromRGB(fogR, fogG, fogB)
    Lighting.Ambient  = Color3.fromRGB(ambR, ambG, ambB)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Density = density; atm.Offset = offset; atm.Glare = glare; atm.Halo = halo
    pcall(function() settings().Rendering.QualityLevel = gfxLevel end)
end

CIPre:Button({ Title = "☀️ Cinematic Day",   Desc = "Film siang cerah",       Callback = function() applyPreset(50,3,14,2,10000,200,220,255,120,120,120,0.05,0.1,0.3,0.2,Enum.QualityLevel.Level10);   WindUI:Notify({Title="🎬",Content="☀️ Cinematic Day",Duration=3}) end })
CIPre:Button({ Title = "🌆 Golden Hour",     Desc = "Sore sinematik hangat",  Callback = function() applyPreset(55,3,18,1.5,4000,255,180,100,180,100,60,0.2,0.3,0.8,0.5,Enum.QualityLevel.Level10);   WindUI:Notify({Title="🎬",Content="🌆 Golden Hour",Duration=3}) end })
CIPre:Button({ Title = "🌃 Night Cinematic", Desc = "Drama malam gelap",      Callback = function() applyPreset(45,2,0,0.3,20000,10,10,30,20,20,40,0.02,0.0,0.0,0.1,Enum.QualityLevel.Level10);        WindUI:Notify({Title="🎬",Content="🌃 Night Cinematic",Duration=3}) end })
CIPre:Button({ Title = "🌫️ Fog Drama",       Desc = "Kabut misterius",        Callback = function() applyPreset(55,2,12,0.8,300,200,200,200,150,150,150,0.6,0.5,0.0,0.1,Enum.QualityLevel.Level08);  WindUI:Notify({Title="🎬",Content="🌫️ Fog Drama",Duration=3}) end })
CIPre:Button({ Title = "❄️ Snow Scene",      Desc = "Salju bersih putih",     Callback = function() applyPreset(50,2,10,1.2,500,220,230,255,180,190,210,0.4,0.4,0.0,0.3,Enum.QualityLevel.Level10);  WindUI:Notify({Title="🎬",Content="❄️ Snow Scene",Duration=3}) end })
CIPre:Button({ Title = "🎭 Dark Thriller",   Desc = "Gelap intens dramatis",  Callback = function() applyPreset(40,2,12,0.1,200,40,40,50,30,30,40,0.8,0.1,0.0,0.0,Enum.QualityLevel.Level08);         WindUI:Notify({Title="🎬",Content="🎭 Dark Thriller",Duration=3}) end })
CIPre:Button({ Title = "📺 Vlog Style",      Desc = "Casual natural cerah",   Callback = function() applyPreset(75,5,14,1.5,8000,210,225,255,110,110,110,0.1,0.1,0.1,0.15,Enum.QualityLevel.Level05); WindUI:Notify({Title="🎬",Content="📺 Vlog Style",Duration=3}) end })
CIPre:Button({ Title = "🔄 Reset Semua",     Desc = "Kembalikan default",     Callback = function() applyPreset(70,5,14,1,100000,191,191,191,70,70,70,0.35,0.0,0.0,0.25,Enum.QualityLevel.Level05);   WindUI:Notify({Title="🎬",Content="🔄 Reset Default",Duration=2}) end })

-- Fine Tune
local CIFine = T_CI:Section({ Title = "🎛️ Fine-Tune" })
local function getAtmos2()
    return Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
end
CIFine:Slider({ Title = "☀️ Brightness",  Min = 0, Max = 5,   Default = 1,  Callback = function(v) Lighting.Brightness = v end })
CIFine:Slider({ Title = "🕐 ClockTime",   Min = 0, Max = 24,  Default = 14, Callback = function(v) Lighting.ClockTime  = v end })
CIFine:Slider({ Title = "🌫️ Fog Density", Min = 0, Max = 100, Default = 0,  Callback = function(v) getAtmos2().Density = v * 0.01 end })
CIFine:Slider({ Title = "🌅 Offset/Haze", Min = 0, Max = 100, Default = 0,  Callback = function(v) getAtmos2().Offset  = v * 0.01 end })
CIFine:Slider({ Title = "✨ Glare",       Min = 0, Max = 100, Default = 0,  Callback = function(v) getAtmos2().Glare   = v * 0.01 end })
CIFine:Slider({ Title = "🌟 Halo",        Min = 0, Max = 100, Default = 0,  Callback = function(v) getAtmos2().Halo    = v * 0.01 end })
CIFine:Slider({ Title = "📊 Grafik Level",Min = 1, Max = 10,  Default = 5,  Callback = function(v) pcall(function() settings().Rendering.QualityLevel = math.floor(v) end) end })

-- ════════════════════════════════════════════════════════════
-- TAB 4: SPECTATE
-- ════════════════════════════════════════════════════════════
local T_SP  = Window:Tab({ Title = "Spectate", Icon = "eye" })
local SPSec = T_SP:Section({ Title = "👁️ Spectate Player" })

local function inJoystickArea(pos)
    local ctrl = LP and LP.PlayerGui and LP.PlayerGui:FindFirstChild("TouchGui")
    if ctrl then
        local frame = ctrl:FindFirstChild("TouchControlFrame")
        local thumb = frame and frame:FindFirstChild("DynamicThumbstickFrame")
        if thumb then
            local ap = thumb.AbsolutePosition; local as = thumb.AbsoluteSize
            if pos.X >= ap.X and pos.Y >= ap.Y and pos.X <= ap.X+as.X and pos.Y <= ap.Y+as.Y then return true end
        end
    end
    return false
end

local Spec = {
    active = false, target = nil, mode = "third",
    dist = 8, origFov = 70, orbitYaw = 0, orbitPitch = 0, fpYaw = 0, fpPitch = 0,
}
local specTouchMain = nil; local specTouchPinch = {}
local specPinchDist = nil; local specPanDelta   = Vector2.zero
local specConns     = {}

local function startSpecCapture()
    table.insert(specConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or not Spec.active then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inJoystickArea(inp.Position) then return end
        table.insert(specTouchPinch, inp)
        if #specTouchPinch == 1 then specTouchMain = inp else specTouchMain = nil end
    end))
    table.insert(specConns, UIS.InputChanged:Connect(function(inp)
        if not Spec.active then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if #specTouchPinch == 1 and inp == specTouchMain then
            specPanDelta = specPanDelta + Vector2.new(inp.Delta.X, inp.Delta.Y)
        elseif #specTouchPinch >= 2 then
            local d = (specTouchPinch[1].Position - specTouchPinch[2].Position).Magnitude
            if specPinchDist then
                local diff = d - specPinchDist
                Cam.FieldOfView = math.clamp(Cam.FieldOfView - diff * 0.15, 10, 120)
                if Spec.mode == "third" then Spec.dist = math.clamp(Spec.dist - diff * 0.03, 3, 30) end
            end
            specPinchDist = d
        end
    end))
    table.insert(specConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        for i, v in ipairs(specTouchPinch) do if v == inp then table.remove(specTouchPinch, i); break end end
        specPinchDist = nil
        if #specTouchPinch == 1 then specTouchMain = specTouchPinch[1] else specTouchMain = nil end
    end))
end

local function stopSpecCapture()
    for _, c in ipairs(specConns) do c:Disconnect() end
    specConns = {}; specTouchMain = nil; specTouchPinch = {}; specPinchDist = nil; specPanDelta = Vector2.zero
end

local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not Spec.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable
        local char = Spec.target and Spec.target.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local pan = specPanDelta; specPanDelta = Vector2.zero; local sens = 0.3
        if Spec.mode == "third" then
            Spec.orbitYaw   = Spec.orbitYaw   + pan.X * sens
            Spec.orbitPitch = math.clamp(Spec.orbitPitch + pan.Y * sens, -75, 75)
            local orbitCF = CFrame.new(hrp.Position)
                * CFrame.Angles(0, math.rad(-Spec.orbitYaw), 0)
                * CFrame.Angles(math.rad(-Spec.orbitPitch), 0, 0)
                * CFrame.new(0, 0, Spec.dist)
            Cam.CFrame = CFrame.new(orbitCF.Position, hrp.Position + Vector3.new(0, 1, 0))
        else
            local head   = char:FindFirstChild("Head")
            local origin = head and head.Position or hrp.Position + Vector3.new(0, 1.5, 0)
            Spec.fpYaw   = Spec.fpYaw   - pan.X * sens
            Spec.fpPitch = math.clamp(Spec.fpPitch - pan.Y * sens, -85, 85)
            Cam.CFrame   = CFrame.new(origin)
                * CFrame.Angles(0, math.rad(Spec.fpYaw), 0)
                * CFrame.Angles(math.rad(Spec.fpPitch), 0, 0)
        end
    end)
end

local function stopSpecLoop()
    RS:UnbindFromRenderStep("XKIDSpec")
end

local specDropOptions = getDisplayNames()
SPSec:Dropdown({
    Title    = "Pilih Target",
    Values   = specDropOptions,
    Callback = function(v)
        local p = findPlayerByDisplay(v)
        if p then
            Spec.target = p
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ()
                Spec.orbitYaw = math.deg(ry); Spec.orbitPitch = 20
                Spec.fpYaw    = math.deg(ry); Spec.fpPitch = 0
            end
        end
    end,
})

SPSec:Button({
    Title    = "🔄 Refresh List",
    Callback = function()
        Spec.target = nil; specDropOptions = getDisplayNames()
        WindUI:Notify({ Title = "Spectate", Content = "List diperbarui!", Duration = 2 })
    end,
})

SPSec:Toggle({
    Title    = "🙈 Hide Target Name",
    Desc     = "Sensor nama di notifikasi",
    Default  = false,
    Callback = function(v) State.Spectate.hideName = v end,
})

SPSec:Toggle({
    Title    = "👁️ Spectate ON/OFF",
    Desc     = "Nonton target yang dipilih",
    Default  = false,
    Callback = function(v)
        Spec.active = v
        if v then
            if not Spec.target then
                WindUI:Notify({ Title = "Spectate", Content = "Pilih target dulu!", Duration = 3 })
                Spec.active = false; return
            end
            Spec.origFov = Cam.FieldOfView
            startSpecCapture(); startSpecLoop()
            local name = State.Spectate.hideName and "[HIDDEN]" or Spec.target.DisplayName
            WindUI:Notify({ Title = "Spectate", Content = "Nonton: " .. name, Duration = 3 })
        else
            stopSpecLoop(); stopSpecCapture()
            Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov
            WindUI:Notify({ Title = "Spectate", Content = "Spectate off!", Duration = 2 })
        end
    end,
})

SPSec:Toggle({
    Title    = "🎥 First Person",
    Desc     = "ON = FP Drone | OFF = Orbit",
    Default  = false,
    Callback = function(v)
        Spec.mode = v and "first" or "third"
        if v and Spec.target and Spec.target.Character then
            local _, ry, _ = Cam.CFrame:ToEulerAnglesYXZ()
            local rx = math.asin(Cam.CFrame.LookVector.Y)
            Spec.fpYaw = math.deg(ry); Spec.fpPitch = math.deg(rx)
        end
    end,
})

SPSec:Slider({ Title = "Jarak Orbit", Min = 3, Max = 30, Default = 8, Callback = function(v) Spec.dist = v end })

local SPCam = T_SP:Section({ Title = "🔍 Camera / FOV" })
SPCam:Button({
    Title    = "🔄 Refresh POV Camera",
    Desc     = "Reset bug kamera/karakter",
    Callback = function()
        local r = getRoot(); local h = getHum()
        if not r or not h then WindUI:Notify({ Title = "Refresh", Content = "❌ Karakter tidak ditemukan!", Duration = 2 }); return end
        Cam.CameraType = Enum.CameraType.Custom; task.wait(0.05)
        Cam.CameraType = Enum.CameraType.Scriptable; task.wait(0.05)
        Cam.CameraType = Enum.CameraType.Custom
        pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        WindUI:Notify({ Title = "✅ Refresh", Content = "Kamera sudah di-reset normal!", Duration = 2 })
    end,
})
SPCam:Slider({ Title = "🔍 FOV Zoom", Min = 10, Max = 120, Default = 70, Callback = function(v) Cam.FieldOfView = v end })
SPCam:Button({ Title = "👁️ Reset FOV (70)", Callback = function() Cam.FieldOfView = 70 end })

-- ════════════════════════════════════════════════════════════
-- TAB 5: WORLD
-- ════════════════════════════════════════════════════════════
local T_WO  = Window:Tab({ Title = "World", Icon = "globe" })

local function getAtmos()
    return Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
end
local function setWeather(clock, bright, fogStart, fogEnd, fogR, fogG, fogB, ambR, ambG, ambB, density, offset, glare, halo)
    Lighting.ClockTime = clock; Lighting.Brightness = bright
    Lighting.FogStart  = fogStart; Lighting.FogEnd = fogEnd
    Lighting.FogColor  = Color3.fromRGB(fogR, fogG, fogB)
    Lighting.Ambient   = Color3.fromRGB(ambR, ambG, ambB)
    local atm = getAtmos()
    atm.Density = density; atm.Offset = offset; atm.Glare = glare; atm.Halo = halo
end

local WOWeather = T_WO:Section({ Title = "🌤️ Preset Cuaca" })
WOWeather:Button({ Title = "☀️ Cerah",               Callback = function() setWeather(14,2,1000,10000,200,220,255,120,120,120,0.05,0.1,0.3,0.2);   WindUI:Notify({Title="Weather",Content="☀️ Cerah!",Duration=2}) end })
WOWeather:Button({ Title = "🌅 Sunset / Golden Hour", Callback = function() setWeather(18,1.5,500,4000,255,180,100,180,100,60,0.2,0.3,0.8,0.5);    WindUI:Notify({Title="Weather",Content="🌅 Golden Hour!",Duration=2}) end })
WOWeather:Button({ Title = "🌃 Malam Bintang",        Callback = function() setWeather(0,0.3,2000,20000,10,10,30,20,20,40,0.02,0.0,0.0,0.1);       WindUI:Notify({Title="Weather",Content="🌃 Malam Bintang!",Duration=2}) end })
WOWeather:Button({ Title = "🌫️ Berkabut",             Callback = function() setWeather(12,0.8,20,300,200,200,200,150,150,150,0.6,0.5,0.0,0.1);     WindUI:Notify({Title="Weather",Content="🌫️ Berkabut!",Duration=2}) end })
WOWeather:Button({ Title = "🌧️ Mendung Gelap",        Callback = function() setWeather(12,0.4,100,800,80,80,100,60,60,80,0.5,0.2,0.0,0.0);         WindUI:Notify({Title="Weather",Content="🌧️ Mendung Gelap!",Duration=2}) end })
WOWeather:Button({ Title = "❄️ Salju",                Callback = function() setWeather(10,1.2,50,500,220,230,255,180,190,210,0.4,0.4,0.0,0.3);     WindUI:Notify({Title="Weather",Content="❄️ Salju!",Duration=2}) end })
WOWeather:Button({ Title = "🌪️ Badai",                Callback = function() setWeather(12,0.1,30,200,40,40,50,30,30,40,0.8,0.1,0.0,0.0);           WindUI:Notify({Title="Weather",Content="🌪️ Badai!",Duration=2}) end })
WOWeather:Button({ Title = "🔄 Reset Default",        Callback = function() setWeather(14,1,0,100000,191,191,191,70,70,70,0.35,0.0,0.0,0.25);     WindUI:Notify({Title="Weather",Content="🔄 Reset!",Duration=2}) end })

local WOAtmos = T_WO:Section({ Title = "🌈 Atmosphere Fine-Tune" })
WOAtmos:Slider({ Title = "🕐 ClockTime",    Min = 0,  Max = 24,   Default = 14, Callback = function(v) Lighting.ClockTime  = v end })
WOAtmos:Slider({ Title = "☀️ Brightness",   Min = 0,  Max = 5,    Default = 1,  Callback = function(v) Lighting.Brightness = v end })
WOAtmos:Slider({ Title = "🌫️ Fog Jarak",    Min = 0,  Max = 5000, Default = 500,Callback = function(v) Lighting.FogEnd    = v end })
WOAtmos:Slider({ Title = "💨 Density",      Min = 0,  Max = 100,  Default = 0,  Callback = function(v) getAtmos().Density  = v * 0.01 end })
WOAtmos:Slider({ Title = "🌅 Offset/Haze",  Min = 0,  Max = 100,  Default = 0,  Callback = function(v) getAtmos().Offset   = v * 0.01 end })
WOAtmos:Slider({ Title = "✨ Glare",        Min = 0,  Max = 100,  Default = 0,  Callback = function(v) getAtmos().Glare    = v * 0.01 end })
WOAtmos:Slider({ Title = "🌟 Halo",         Min = 0,  Max = 100,  Default = 0,  Callback = function(v) getAtmos().Halo     = v * 0.01 end })

-- Graphics
local function setGfx(level)
    local ok = pcall(function() settings().Rendering.QualityLevel = level end)
    if not ok then pcall(function() UserSettings():GetService("UserGameSettings").SavedQualityLevel = level end) end
end

local WOGfx = T_WO:Section({ Title = "📱 Mode Grafik" })
WOGfx:Button({ Title = "🥔 Potato (Lv1)", Callback = function() setGfx(Enum.QualityLevel.Level01); WindUI:Notify({Title="Graphics",Content="🥔 Potato — Level 1",Duration=2}) end })
WOGfx:Button({ Title = "📉 Low (Lv3)",    Callback = function() setGfx(Enum.QualityLevel.Level03); WindUI:Notify({Title="Graphics",Content="📉 Low — Level 3",Duration=2}) end })
WOGfx:Button({ Title = "📊 Medium (Lv5)", Callback = function() setGfx(Enum.QualityLevel.Level05); WindUI:Notify({Title="Graphics",Content="📊 Medium — Level 5",Duration=2}) end })
WOGfx:Button({ Title = "📈 High (Lv8)",   Callback = function() setGfx(Enum.QualityLevel.Level08); WindUI:Notify({Title="Graphics",Content="📈 High — Level 8",Duration=2}) end })
WOGfx:Button({ Title = "💎 Ultra (Lv10)", Callback = function() setGfx(Enum.QualityLevel.Level10); WindUI:Notify({Title="Graphics",Content="💎 Ultra — Level 10",Duration=2}) end })
WOGfx:Slider({ Title = "📊 Level Manual", Min = 1, Max = 10, Default = 5, Callback = function(v)
    pcall(function() settings().Rendering.QualityLevel = math.floor(v) end)
    WindUI:Notify({ Title = "Graphics", Content = "Level: " .. math.floor(v), Duration = 1 })
end })

-- ════════════════════════════════════════════════════════════
-- TAB 6: SECURITY
-- ════════════════════════════════════════════════════════════
local T_SC  = Window:Tab({ Title = "Security", Icon = "shield" })

-- Protection Section
local SCProt = T_SC:Section({ Title = "🛡️ Protection" })

SCProt:Toggle({
    Title    = "Anti-AFK",
    Desc     = "Cegah kick diam (Bypass)",
    Default  = false,
    Callback = function(v)
        if v then
            State.Security.afkConn = LP.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                VirtualUser:Button2Down(Vector2.new(0,0), Cam.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), Cam.CFrame)
            end)
            pcall(function()
                for _, conn in pairs(getconnections(LP.Idled)) do conn:Disable() end
            end)
            WindUI:Notify({ Title = "Anti-AFK", Content = "🛡️ Bypass aktif, aman AFK lama!", Duration = 2 })
        else
            if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn = nil end
            pcall(function()
                for _, conn in pairs(getconnections(LP.Idled)) do conn:Enable() end
            end)
            WindUI:Notify({ Title = "Anti-AFK", Content = "❌ Bypass mati", Duration = 2 })
        end
    end,
})

SCProt:Button({
    Title    = "🔄 Rejoin Server",
    Desc     = "Masuk ulang ke server",
    Callback = function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end,
})

-- Fast Respawn Section
local SCResp = T_SC:Section({ Title = "💀 Fast Respawn" })
local respawnLastPos = nil

task.spawn(function()
    while true do
        task.wait(1)
        local r = getRoot(); local h = getHum()
        if r and h and h.Health > 0 then respawnLastPos = r.CFrame end
    end
end)

SCResp:Button({
    Title    = "💀 Fast Respawn",
    Desc     = "Mati & balik ke posisi terakhir",
    Callback = function()
        if not respawnLastPos then WindUI:Notify({ Title = "Respawn", Content = "❌ Posisi belum direkam!", Duration = 2 }); return end
        local savedCF = respawnLastPos
        local hum = getHum()
        if not hum then WindUI:Notify({ Title = "Respawn", Content = "❌ Karakter tidak ditemukan!", Duration = 2 }); return end
        hum.Health = 0
        task.spawn(function()
            local char = LP.CharacterAdded:Wait()
            task.wait(0.3)
            local hrp = char:WaitForChild("HumanoidRootPart", 10)
            if hrp then hrp.CFrame = savedCF; WindUI:Notify({ Title = "Respawn", Content = "✅ Balik ke posisi terakhir!", Duration = 3 }) end
        end)
    end,
})

-- ESP Tracker Section
local ESPSec = T_SC:Section({ Title = "🎯 ESP Tracker" })

ESPSec:Toggle({
    Title    = "🎬 ESP ON/OFF",
    Desc     = "Master toggle ESP",
    Default  = false,
    Callback = function(v)
        State.ESP.active = v
        if not v then
            for _, cache in pairs(State.ESP.cache) do
                for _, render in pairs(cache.renders) do if render and render.Parent then render:Destroy() end end
                if cache.highlight then cache.highlight:Destroy() end
            end
            State.ESP.cache = {}
        end
        WindUI:Notify({ Title = "ESP", Content = v and "🎬 ESP Enabled!" or "🎬 ESP Disabled", Duration = 2 })
    end,
})

ESPSec:Dropdown({
    Title    = "📦 Box Mode",
    Values   = {"Corner", "2D Box", "HIGHLIGHT", "OFF"},
    Value    = "Corner",
    Callback = function(v) State.ESP.boxMode = v; WindUI:Notify({ Title = "ESP", Content = "Box Mode: " .. v, Duration = 2 }) end,
})

ESPSec:Dropdown({
    Title    = "🔴 Tracer Mode",
    Values   = {"Bottom", "Center", "Mouse", "OFF"},
    Value    = "Bottom",
    Callback = function(v) State.ESP.tracerMode = v; WindUI:Notify({ Title = "ESP", Content = "Tracer: " .. v, Duration = 2 }) end,
})

ESPSec:Dropdown({
    Title    = "🎨 ESP Color",
    Values   = {"Green", "Red", "Blue", "White", "Yellow", "Purple"},
    Value    = "Green",
    Callback = function(v)
        local c = ({
            Green = Color3.fromRGB(0,255,150), Red = Color3.fromRGB(255,50,50),
            Blue  = Color3.fromRGB(0,150,255), White  = Color3.fromRGB(255,255,255),
            Yellow= Color3.fromRGB(255,255,0), Purple = Color3.fromRGB(150,0,255),
        })[v] or Color3.fromRGB(0,255,150)
        State.ESP.boxColor_Normal    = c
        State.ESP.tracerColor_Normal = c
        WindUI:Notify({ Title = "ESP Color", Content = "Berubah jadi " .. v, Duration = 2 })
    end,
})

ESPSec:Toggle({ Title = "📍 Show Distance", Desc = "Tampilkan jarak ke player", Default = true,  Callback = function(v) State.ESP.showDistance  = v end })
ESPSec:Toggle({ Title = "👤 Show Nickname", Desc = "Tampilkan nama player",     Default = true,  Callback = function(v) State.ESP.showNickname  = v end })
ESPSec:Slider({ Title = "🎯 Draw Distance", Min = 50, Max = 500, Default = 300, Callback = function(v) State.ESP.maxDrawDistance = v end })

-- ESP Presets
local ESPPresetSec = T_SC:Section({ Title = "💾 ESP Presets" })
ESPPresetSec:Button({ Title = "🕵️ Legit",         Desc = "Text only",            Callback = function() State.ESP.boxMode="OFF"; State.ESP.tracerMode="OFF"; State.ESP.showDistance=true; State.ESP.showNickname=true; State.ESP.maxDrawDistance=250; WindUI:Notify({Title="ESP",Content="🕵️ Legit Preset",Duration=2}) end })
ESPPresetSec:Button({ Title = "💢 Rage",           Desc = "Corner + Center Tracer",Callback = function() State.ESP.boxMode="Corner"; State.ESP.tracerMode="Center"; State.ESP.showDistance=true; State.ESP.showNickname=true; State.ESP.maxDrawDistance=400; WindUI:Notify({Title="ESP",Content="💢 Rage Preset",Duration=2}) end })
ESPPresetSec:Button({ Title = "🧼 Clean",          Desc = "Minimalist Corner Box", Callback = function() State.ESP.boxMode="Corner"; State.ESP.tracerMode="OFF"; State.ESP.showDistance=false; State.ESP.showNickname=false; State.ESP.maxDrawDistance=200; WindUI:Notify({Title="ESP",Content="🧼 Clean Preset",Duration=2}) end })
ESPPresetSec:Button({ Title = "🚨 Anti-Glitcher",  Desc = "Find Exploiters",       Callback = function() State.ESP.boxMode="HIGHLIGHT"; State.ESP.tracerMode="Bottom"; State.ESP.showDistance=true; State.ESP.showNickname=true; State.ESP.maxDrawDistance=500; WindUI:Notify({Title="ESP",Content="🚨 Anti-Glitcher Preset",Duration=2}) end })

-- Performance Section
local SCPerf = T_SC:Section({ Title = "🚀 Performance" })
SCPerf:Button({ Title = "🚀 60 FPS",       Callback = function() if setfpscap then setfpscap(60);  WindUI:Notify({Title="FPS",Content="Cap: 60 FPS",Duration=2})  else WindUI:Notify({Title="Error",Content="Executor tidak support setfpscap!",Duration=2}) end end })
SCPerf:Button({ Title = "🚀 90 FPS",       Callback = function() if setfpscap then setfpscap(90);  WindUI:Notify({Title="FPS",Content="Cap: 90 FPS",Duration=2})  else WindUI:Notify({Title="Error",Content="Executor tidak support setfpscap!",Duration=2}) end end })
SCPerf:Button({ Title = "🚀 120 FPS",      Callback = function() if setfpscap then setfpscap(120); WindUI:Notify({Title="FPS",Content="Cap: 120 FPS",Duration=2}) else WindUI:Notify({Title="Error",Content="Executor tidak support setfpscap!",Duration=2}) end end })
SCPerf:Button({ Title = "🚀 Max FPS (999)",Callback = function() if setfpscap then setfpscap(999); WindUI:Notify({Title="FPS",Content="Max FPS Unlocked!",Duration=2}) else WindUI:Notify({Title="Error",Content="Executor tidak support setfpscap!",Duration=2}) end end })
SCPerf:Button({ Title = "🔄 Reset FPS",   Callback = function() if setfpscap then setfpscap(0);   WindUI:Notify({Title="FPS",Content="Reset ke Default Roblox",Duration=2}) else WindUI:Notify({Title="Error",Content="Executor tidak support setfpscap!",Duration=2}) end end })

local AntiLagState = { materials = {}, textures = {}, shadows = true }
SCPerf:Toggle({
    Title    = "🗑️ Anti Lag Mode",
    Desc     = "Hapus tekstur & shadow untuk FPS lebih tinggi",
    Default  = false,
    Callback = function(v)
        if v then
            AntiLagState.shadows = Lighting.GlobalShadows
            Lighting.GlobalShadows = false
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    AntiLagState.materials[obj] = obj.Material
                    obj.Material = Enum.Material.SmoothPlastic
                elseif obj:IsA("Texture") or obj:IsA("Decal") then
                    AntiLagState.textures[obj] = obj.Parent
                    obj.Parent = nil
                end
            end
            WindUI:Notify({ Title = "Anti Lag", Content = "🚀 Aktif! Tekstur & Shadow dihilangkan.", Duration = 3 })
        else
            Lighting.GlobalShadows = AntiLagState.shadows
            for obj, mat in pairs(AntiLagState.materials) do if obj and obj.Parent then obj.Material = mat end end
            for obj, parent in pairs(AntiLagState.textures) do if obj and parent and parent.Parent then obj.Parent = parent end end
            AntiLagState.materials = {}; AntiLagState.textures = {}
            WindUI:Notify({ Title = "Anti Lag", Content = "🔄 Reset! Grafik kembali normal.", Duration = 3 })
        end
    end,
})

-- ════════════════════════════════════════════════════════════
-- TAB 7: SETTINGS
-- ════════════════════════════════════════════════════════════
local T_SET = Window:Tab({ Title = "Settings", Icon = "settings" })

T_SET:Dropdown({
    Title    = "🎨 Theme",
    Values   = (function()
        local names = {}
        for name in pairs(WindUI:GetThemes()) do table.insert(names, name) end
        table.sort(names); return names
    end)(),
    Value    = WindUI:GetCurrentTheme(),
    Callback = function(selected) WindUI:SetTheme(selected) end,
})

T_SET:Toggle({
    Title    = "Acrylic",
    Default  = true,
    Callback = function()
        local isOn = WindUI.Window.Acrylic
        WindUI:ToggleAcrylic(not isOn)
    end,
})

T_SET:Toggle({
    Title    = "Transparent",
    Default  = true,
    Callback = function(state) Window:ToggleTransparency(state) end,
})

local currentKey = Enum.KeyCode.RightShift
T_SET:Keybind({
    Title    = "Toggle UI Key",
    Value    = currentKey,
    Callback = function(v)
        currentKey = (typeof(v) == "EnumItem") and v or Enum.KeyCode[v]
        Window:SetToggleKey(currentKey)
    end,
})

-- ════════════════════════════════════════════════════════════
-- BACKGROUND LOOPS
-- ════════════════════════════════════════════════════════════

-- IY FLING & SOFT FLING LOOP
task.spawn(function()
    while true do
        if (State.Fling.active or State.SoftFling.active) and getRoot() then
            local r = getRoot()
            local isBrutal = State.Fling.active
            local pwr      = isBrutal and State.Fling.power or State.SoftFling.power
            local ok = pcall(function()
                r.AssemblyAngularVelocity = Vector3.new(0, pwr, 0)
                if isBrutal then r.AssemblyLinearVelocity = Vector3.new(pwr, pwr, pwr) end
            end)
            if not ok then
                pcall(function()
                    r.RotVelocity = Vector3.new(0, pwr, 0)
                    if isBrutal then r.Velocity = Vector3.new(pwr, pwr, pwr) end
                end)
            end
        end
        RS.RenderStepped:Wait()
    end
end)

-- NOCLIP LOOP
RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active or State.SoftFling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- READY
-- ════════════════════════════════════════════════════════════
WindUI:SetNotificationLower(true)
WindUI:Notify({
    Title    = "✦ XKID HUB",
    Content  = "WindUI Edition — Ready! 🚀",
    Duration = 5,
})
