--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    ✦  X K I D     H U B  ✦   v3 WITH SMOOTH ESP             ║
║                                                              ║
║   ✅ Modern 3D ESP + Tracer Real-Time                        ║
║   ✅ Smooth Freecam (Damping + Velocity)                     ║
║   ✅ All Features Kept (Teleport, Player, Cinema, etc)       ║
║   ✅ Auto Suspect Detection                                  ║
║                                                              ║
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
    Fly = {active = false, bv = nil, bg = nil},
    Fling = {active = false, power = 1000000},
    SoftFling = {active = false, power = 4000},
    Teleport = {selectedTarget = ""},
    Security = {afkConn = nil},
    Cinema = {active = false, speed = 1, fov = 70, lastPos = nil},
    ESP = {
        active = false, 
        cache = {},
        boxMode = "3D",
        tracerMode = "ADVANCED",
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
        if str == p.DisplayName .. " (@" .. p.Name .. ")" then
            return p
        end
    end
    return nil
end

-- Persistent Movement
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

-- ═══════════════════════════════════════════════════════════
-- MODERN 3D ESP ENGINE
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
    
    local sg = LP.PlayerGui:FindFirstChild("ScreenGui") or (function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "ScreenGui"
        sg.ResetOnSpawn = false
        sg.Parent = LP.PlayerGui
        return sg
    end)()
    
    line.Parent = sg
    return line
end

local function draw3DBox(hrp, size, color, thickness)
    if not hrp then return {} end
    
    local cf = hrp.CFrame
    local lines = {}
    
    local corners = {
        Vector3.new(-1, -1, -1), Vector3.new(1, -1, -1),
        Vector3.new(1, 1, -1), Vector3.new(-1, 1, -1),
        Vector3.new(-1, -1, 1), Vector3.new(1, -1, 1),
        Vector3.new(1, 1, 1), Vector3.new(-1, 1, 1),
    }
    
    for i = 1, 8 do corners[i] = corners[i] * size / 2 end
    
    local worldCorners = {}
    for i, c in ipairs(corners) do
        worldCorners[i] = cf * c
    end
    
    local edges = {
        {1,2}, {2,3}, {3,4}, {4,1},
        {5,6}, {6,7}, {7,8}, {8,5},
        {1,5}, {2,6}, {3,7}, {4,8},
    }
    
    for _, edge in ipairs(edges) do
        local p1, p2 = worldCorners[edge[1]], worldCorners[edge[2]]
        local screen1, onScreen1 = worldToScreen(p1)
        local screen2, onScreen2 = worldToScreen(p2)
        
        if onScreen1 or onScreen2 then
            local line = drawLine2D(screen1, screen2, thickness, color)
            if line then table.insert(lines, line) end
        end
    end
    
    return lines
end

local function drawSkeleton(char, color, thickness)
    if not char then return {} end
    
    local lines = {}
    local bones = {
        {"HumanoidRootPart", "Head"},
        {"UpperTorso", "Head"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"HumanoidRootPart", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"HumanoidRootPart", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"},
    }
    
    for _, bone in ipairs(bones) do
        local p1, p2 = char:FindFirstChild(bone[1]), char:FindFirstChild(bone[2])
        if p1 and p2 then
            local screen1, onScreen1 = worldToScreen(p1.Position)
            local screen2, onScreen2 = worldToScreen(p2.Position)
            if onScreen1 or onScreen2 then
                local line = drawLine2D(screen1, screen2, thickness, color)
                if line then table.insert(lines, line) end
            end
        end
    end
    
    return lines
end

local function isSuspectPlayer(player)
    local char = player.Character
    if not char then return false end
    local neonCount = 0
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Material == Enum.Material.Neon then
            neonCount = neonCount + 1
        end
    end
    return neonCount > 5
end

local function renderESP(player)
    if not State.ESP.active or player == LP then return end
    
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local lpRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if lpRoot and (lpRoot.Position - hrp.Position).Magnitude > State.ESP.maxDrawDistance then
        return
    end
    
    local isSuspect = isSuspectPlayer(player)
    local boxColor = isSuspect and State.ESP.boxColor_Suspect or State.ESP.boxColor_Normal
    
    if not State.ESP.cache[player] then
        State.ESP.cache[player] = {renders = {}, tracer = {}}
    end
    
    local cache = State.ESP.cache[player]
    for _, render in pairs(cache.renders) do
        if render and render.Parent then render:Destroy() end
    end
    cache.renders = {}
    
    if State.ESP.boxMode == "3D" then
        cache.renders = draw3DBox(hrp, Vector3.new(2, 5, 2), boxColor, 2)
    elseif State.ESP.boxMode == "SKELETON" then
        cache.renders = drawSkeleton(char, Color3.fromRGB(100, 255, 200), 2)
    end
    
    if State.ESP.showDistance or State.ESP.showNickname then
        local screenPos, onScreen = worldToScreen(hrp.Position)
        if onScreen then
            local label = Instance.new("TextLabel")
            label.Name = "ESPInfo"
            label.BackgroundTransparency = 1
            label.TextColor3 = boxColor
            label.TextSize = 14
            label.Font = Enum.Font.GothamBold
            label.Position = UDim2.new(0, screenPos.X + 10, 0, screenPos.Y - 20)
            label.Size = UDim2.new(0, 150, 0, 40)
            
            local infoText = ""
            if State.ESP.showNickname then
                infoText = player.DisplayName
            end
            if State.ESP.showDistance and lpRoot then
                local dist = math.floor((lpRoot.Position - hrp.Position).Magnitude)
                infoText = infoText .. (infoText ~= "" and "\n" or "") .. "📍 " .. dist .. " studs"
            end
            if isSuspect then
                infoText = infoText .. (infoText ~= "" and "\n" or "") .. "⚠️ SUSPECT"
            end
            
            label.Text = infoText
            label.Parent = LP.PlayerGui:FindFirstChild("ScreenGui") or (function()
                local sg = Instance.new("ScreenGui")
                sg.Name = "ScreenGui"
                sg.ResetOnSpawn = false
                sg.Parent = LP.PlayerGui
                return sg
            end)()
            
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
        State.ESP.cache[player] = nil
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │        ➤  FLY ENGINE  (LOCK CAMERA DIRECTION)           │
-- └─────────────────────────────────────────────────────────┘

local onMobile = not UIS.KeyboardEnabled

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
    flyConns = {}
    flyMoveTouch = nil
    flyMoveSt = nil
    flyJoy = Vector2.zero
    State.Fly._keys = {}
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
        Library:Notification("Fly", "✈️ Fly OFF", 2)
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
        local r   = getRoot()
        local h   = getHum()
        if not r or not h then return end

        local camCF = Cam.CFrame
        local spd  = State.Move.flyS
        local move = Vector3.zero
        local keys = State.Fly._keys or {}

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
        State.Fly.bg.CFrame = CFrame.new(r.Position, r.Position + camCF.LookVector)
    end)

    Library:Notification("Fly", "✈️ Fly ON — Ikut arah kamera", 3)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │     ➤  FREECAM ENGINE (SMOOTH + MOBILE READY)           │
-- └─────────────────────────────────────────────────────────┘

local FC = {
    active          = false,
    pos             = Vector3.zero,
    vel             = Vector3.zero,        -- Velocity untuk smooth movement
    pitchDeg        = 0,
    yawDeg          = 0,
    speed           = 1,
    sens            = 0.25,
    savedCharCFrame = nil,
    damping         = 0.85,                -- Friction coefficient (0-1)
    acceleration    = 0.15,                -- Acceleration multiplier
}

local fcRotTouch   = nil
local fcMoveTouch  = nil
local fcMoveSt     = nil
local fcRotLast    = nil
local fcJoy = Vector2.zero

local DEAD_X = 25
local DEAD_Y = 20
local fcConns = {}

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
        local k = inp.KeyCode
        keysHeld[k] = false
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
            if not fcRotTouch then
                fcRotTouch = inp
                fcRotLast  = inp.Position
            end
        else
            if not fcMoveTouch then
                fcMoveTouch = inp
                fcMoveSt    = inp.Position
            end
        end
    end))

    table.insert(fcConns, UIS.TouchMoved:Connect(function(inp)
        if inp == fcRotTouch and fcRotLast then
            local dx = inp.Position.X - fcRotLast.X
            local dy = inp.Position.Y - fcRotLast.Y
            FC.yawDeg   = FC.yawDeg   - dx * FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg - dy * FC.sens, -80, 80)
            fcRotLast = inp.Position
        end

        if inp == fcMoveTouch and fcMoveSt then
            local dx = inp.Position.X - fcMoveSt.X
            local dy = inp.Position.Y - fcMoveSt.Y
            local nx = 0
            local ny = 0
            if math.abs(dx) > DEAD_X then
                nx = math.clamp((dx - math.sign(dx) * DEAD_X) / 80, -1, 1)
            end
            if math.abs(dy) > DEAD_Y then
                ny = math.clamp((dy - math.sign(dy) * DEAD_Y) / 80, -1, 1)
            end
            fcJoy = Vector2.new(nx, ny)
        end
    end))

    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == fcRotTouch then
            fcRotTouch = nil
            fcRotLast  = nil
        end
        if inp == fcMoveTouch then
            fcMoveTouch = nil
            fcMoveSt    = nil
            fcJoy       = Vector2.zero
        end
    end))

    FC._keys = keysHeld
end

local function stopFCCapture()
    for _, c in ipairs(fcConns) do c:Disconnect() end
    fcConns      = {}
    fcRotTouch   = nil
    fcMoveTouch  = nil
    fcMoveSt     = nil
    fcRotLast    = nil
    fcJoy        = Vector2.zero
    FC._mouseRotate = false
    FC._keys     = {}
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

local function startFCLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable

        -- Build CFrame with smooth rotation
        local cf = CFrame.new(FC.pos)
            * CFrame.Angles(0, math.rad(FC.yawDeg), 0)
            * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)

        -- Calculate desired velocity dari input
        local spd  = FC.speed * 32
        local desiredVel = Vector3.zero
        local keys = FC._keys or {}

        if onMobile then
            desiredVel = cf.LookVector * (-fcJoy.Y) * spd
                      + cf.RightVector * fcJoy.X   * spd
        else
            if keys[Enum.KeyCode.W] then desiredVel = desiredVel + cf.LookVector  * spd end
            if keys[Enum.KeyCode.S] then desiredVel = desiredVel - cf.LookVector  * spd end
            if keys[Enum.KeyCode.D] then desiredVel = desiredVel + cf.RightVector * spd end
            if keys[Enum.KeyCode.A] then desiredVel = desiredVel - cf.RightVector * spd end
            if keys[Enum.KeyCode.E] then desiredVel = desiredVel + Vector3.new(0,1,0) * spd end
            if keys[Enum.KeyCode.Q] then desiredVel = desiredVel - Vector3.new(0,1,0) * spd end
        end

        -- Smooth acceleration (tidak langsung jump ke target velocity)
        FC.vel = FC.vel:Lerp(desiredVel, FC.acceleration * dt * 60)
        
        -- Apply damping (smooth deceleration saat input release)
        FC.vel = FC.vel * (FC.damping ^ (dt * 60))
        
        -- Update position with smoothed velocity
        FC.pos = FC.pos + FC.vel * dt

        -- Apply camera
        Cam.CFrame = CFrame.new(FC.pos)
            * CFrame.Angles(0, math.rad(FC.yawDeg), 0)
            * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)

        -- Freeze karakter (3 lapis)
        local hrp = getRoot()
        local hum = getHum()
        if hrp and not hrp.Anchored then hrp.Anchored = true end
        if hum then
            if hum:GetState() ~= Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.Physics)
            end
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end
    end)
end

local function stopFCLoop()
    RS:UnbindFromRenderStep("XKIDFreecam")
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘

local Win = Library:Window("✦ XKID HUB — v3 ✦", "star", "FREECAM", false)

-- TAB 1: TELEPORT
local T_TP = Win:Tab("Teleport", "map-pin")
local TPT = T_TP:Page("Navigation", "map-pin"):Section("🎯 Smart Search", "Left")

TPT:TextBox("Ketik 2-3 Huruf Nama", "pText", "", function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🚀 Teleport Now", "Fast TP", function()
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
end)
local P_Drop = TPT:Dropdown("Manual List", "pDrop", getPNames(), function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🔄 Refresh List", "", function() P_Drop:Refresh(getPNames()) end)

-- SAVE / LOAD LOCATION
local LocPage = T_TP:Page("Locations", "bookmark")
local TPP2 = LocPage:Section("💾 Save Location", "Left")
local TPP3 = LocPage:Section("📍 Load Location", "Right")

local SavedLocs = {}

for i = 1, 5 do
    local idx = i
    TPP2:Button("💾 Slot " .. idx, "Simpan posisi sini", function()
        local r = getRoot()
        if not r then
            Library:Notification("Location", "Karakter tidak ditemukan!", 2)
            return
        end
        SavedLocs[idx] = r.CFrame
        Library:Notification("✅ Saved", "Slot " .. idx .. " tersimpan di sini!", 2)
    end)
end

for i = 1, 5 do
    local idx = i
    TPP3:Button("📍 Slot " .. idx, "Teleport ke slot", function()
        if not SavedLocs[idx] then
            Library:Notification("❌ Kosong", "Slot " .. idx .. " belum di-save!", 2)
            return
        end
        local r = getRoot()
        if not r then return end
        r.CFrame = SavedLocs[idx]
        Library:Notification("📍 Loaded", "Teleport ke Slot " .. idx, 2)
    end)
end

-- TAB 2: PLAYER
local T_PL = Win:Tab("Player", "user")

local PLPage1 = T_PL:Page("Movement", "zap")
local PLM = PLPage1:Section("⚡ Movement", "Left")
local PLH = PLPage1:Section("🚀 Abilities", "Right")

PLM:Slider("🏃 WalkSpeed", "ws", 16, 500, 16, function(v)
    State.Move.ws = v
    if getHum() then getHum().WalkSpeed = v end
end)

PLM:Slider("🦘 JumpPower", "jp", 50, 500, 50, function(v)
    State.Move.jp = v
    local hum = getHum()
    if hum then 
        hum.UseJumpPower = true
        hum.JumpPower = v 
    end
end)

PLM:Toggle("∞  Inf Jump", "ij", false, "Lompat terus", function(v)
    if v then
        State.Move.infJ = UIS.JumpRequest:Connect(function()
            if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end
    end
end)

PLH:Toggle("✈️  Native Fly", "nf", false, "Mengikuti arah kamera", function(v) toggleFly(v) end)
PLH:Slider("✈️ Fly Speed", "flyspd", 10, 300, 60, function(v)
    State.Move.flyS = v
end)
PLH:Toggle("👻 NoClip", "nc", false, "Tembus dinding", function(v) State.Move.ncp = v end)
PLH:Toggle("💥 IY Fling (Brutal)", "ffm", false, "Tabrak terbang!", function(v) State.Fling.active = v; State.Move.ncp = v end)
PLH:Toggle("💫 Soft Fling", "sfm", false, "Tabrak pelan (jatuh)", function(v) State.SoftFling.active = v; State.Move.ncp = v end)

local noFallConn = nil
PLH:Toggle("🛡️ No Fall Damage", "nofall", false, "Anti mati saat jatuh", function(v)
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
end)

local godConn    = nil
local godRespawn = nil
local godLastPos = nil
PLH:Toggle("🛡️ God Mode", "god", false, "HP Infinite + Respawn", function(v)
    if v then
        local hum = getHum()
        if hum then
            hum.MaxHealth = math.huge
            hum.Health    = math.huge
        end
        godLastPos = getRoot() and getRoot().CFrame
        godRespawn = RS.Heartbeat:Connect(function()
            local r = getRoot()
            if r then godLastPos = r.CFrame end
        end)
        godConn = RS.Heartbeat:Connect(function()
            local h = getHum()
            if h then
                if h.Health < h.MaxHealth then
                    h.Health = h.MaxHealth
                end
                if h.MaxHealth ~= math.huge then
                    h.MaxHealth = math.huge
                end
            end
        end)
        LP.CharacterAdded:Connect(function(char)
            if not State.Move.ncp then return end
            task.wait(0.2)
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if hrp and godLastPos then
                hrp.CFrame = godLastPos
            end
            local h = char:WaitForChild("Humanoid", 5)
            if h then
                h.MaxHealth = math.huge
                h.Health    = math.huge
            end
        end)
        Library:Notification("God Mode", "🛡️ Aktif! HP Infinite + Auto Respawn", 3)
    else
        if godConn    then godConn:Disconnect();    godConn    = nil end
        if godRespawn then godRespawn:Disconnect(); godRespawn = nil end
        local hum = getHum()
        if hum then hum.MaxHealth = 100; hum.Health = 100 end
        Library:Notification("God Mode", "❌ Nonaktif", 2)
    end
end)

local PLPage2 = T_PL:Page("Lock", "lock")
local PLLock  = PLPage2:Section("🎯 Shift Lock", "Left")

local shiftLockConn = nil
PLLock:Toggle("🎯 Enable Shift Lock", "shiftlock", false, "Karakter hadap kamera", function(v)
    local hum = getHum()
    local hrp = getRoot()
    
    if not hum or not hrp then
        Library:Notification("Shift Lock", "❌ Karakter tidak ditemukan!", 2)
        return
    end

    if v then
        hum.CameraOffset = Vector3.new(1.75, 0, 0)
        hum.AutoRotate = false
        
        shiftLockConn = RS.RenderStepped:Connect(function()
            local currentHrp = getRoot()
            if currentHrp then
                local camLook = Cam.CFrame.LookVector
                currentHrp.CFrame = CFrame.new(currentHrp.Position, currentHrp.Position + Vector3.new(camLook.X, 0, camLook.Z))
            end
        end)
        Library:Notification("Shift Lock", "🎯 Aktif!", 2)
    else
        if shiftLockConn then shiftLockConn:Disconnect(); shiftLockConn = nil end
        local curHum = getHum()
        if curHum then
            curHum.CameraOffset = Vector3.zero
            curHum.AutoRotate = true
        end
        Library:Notification("Shift Lock", "🔓 Nonaktif", 2)
    end
end)

local PLPage3 = T_PL:Page("Atmosphere", "cloud")
local PLW = PLPage3:Section("🌦️ Waktu & Cahaya", "Left")

PLW:Slider("Waktu (ClockTime)", "time", 0, 24, 12, function(v) Lighting.ClockTime = v end)
PLW:Button("☀️ Set Siang", "", function() Lighting.ClockTime = 14 end)
PLW:Button("🌙 Set Malam", "", function() Lighting.ClockTime = 0 end)

-- TAB 3: CINEMATIC
local T_CI  = Win:Tab("Cinematic", "video")
local CIPage1 = T_CI:Page("Freecam", "video")
local CIM   = CIPage1:Section("🎬 Freecam", "Left")
local CIW   = CIPage1:Section("📱 Display", "Right")

CIM:Toggle("🎬 Freecam ON/OFF", "fc", false, "Kiri=Gerak | Kanan=Rotate", function(v)
    FC.active = v
    State.Cinema.active = v
    if v then
        local cf = Cam.CFrame
        FC.pos = cf.Position
        FC.vel = Vector3.zero  -- Reset velocity saat mulai
        local rx, ry = cf:ToEulerAnglesYXZ()
        FC.pitchDeg = math.deg(rx)
        FC.yawDeg   = math.deg(ry)
        FC._keys    = {}
        FC._mouseRotate = false

        local hrp = getRoot()
        local hum = getHum()
        if hrp then
            FC.savedCharCFrame = hrp.CFrame
            hrp.Anchored = true
        end
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end

        startFCCapture()
        startFCLoop()
        Library:Notification("Freecam", "ON — Kiri gerak | Kanan rotate", 3)
    else
        stopFCLoop()
        stopFCCapture()

        local hrp = getRoot()
        local hum = getHum()
        if hrp then
            hrp.Anchored = false
            if FC.savedCharCFrame then
                hrp.CFrame = FC.savedCharCFrame
                FC.savedCharCFrame = nil
            end
        end
        if hum then
            hum.WalkSpeed = State.Move.ws
            hum.UseJumpPower = true
            hum.JumpPower = State.Move.jp
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        Cam.FieldOfView = 70
        Cam.CameraType  = Enum.CameraType.Custom
        Library:Notification("Freecam", "OFF — Balik ke posisi karakter", 3)
    end
end)

CIM:Slider("⚡ Speed", "fcspd", 1, 30, 5, function(v) FC.speed = v end)
CIM:Slider("🎯 Sensitivity", "fcsens", 1, 20, 5, function(v) FC.sens = v * 0.05 end)
CIM:Slider("📊 Damping", "fcdamp", 0.5, 1, 0.85, function(v) FC.damping = v end)
CIM:Slider("⚙️ Acceleration", "fcaccel", 0.05, 0.5, 0.15, function(v) FC.acceleration = v end)
CIM:Slider("🔍 FOV", "fcfov", 10, 120, 70, function(v) Cam.FieldOfView = v end)

CIW:Button("📱 Portrait",  "Tegak",    function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end)
CIW:Button("📺 Landscape", "Mendatar", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end)

-- PAGE 2: CINEMATIC PRESETS
local CIPage2  = T_CI:Page("Presets", "film")
local CIPre    = CIPage2:Section("🎬 Preset Sinematik", "Left")
local CIFine   = CIPage2:Section("🎛️ Fine-Tune", "Right")

local function applyPreset(fov, speed, clock, bright, fogEnd, fogR, fogG, fogB, ambR, ambG, ambB, density, offset, glare, halo, gfxLevel)
    Cam.FieldOfView    = fov
    FC.speed           = speed
    Lighting.ClockTime = clock
    Lighting.Brightness= bright
    Lighting.FogEnd    = fogEnd
    Lighting.FogColor  = Color3.fromRGB(fogR, fogG, fogB)
    Lighting.Ambient   = Color3.fromRGB(ambR, ambG, ambB)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Density = density
    atm.Offset  = offset
    atm.Glare   = glare
    atm.Halo    = halo
    pcall(function() settings().Rendering.QualityLevel = gfxLevel end)
end

CIPre:Button("☀️  Cinematic Day",   "Film siang hari cerah",  function() applyPreset(50,3,14,2,10000,200,220,255,120,120,120,0.05,0.1,0.3,0.2,Enum.QualityLevel.Level10); Library:Notification("🎬","☀️ Cinematic Day",3) end)
CIPre:Button("🌆  Golden Hour",     "Sore sinematik hangat",  function() applyPreset(55,3,18,1.5,4000,255,180,100,180,100,60,0.2,0.3,0.8,0.5,Enum.QualityLevel.Level10);  Library:Notification("🎬","🌆 Golden Hour",3) end)
CIPre:Button("🌃  Night Cinematic", "Drama malam gelap",      function() applyPreset(45,2,0,0.3,20000,10,10,30,20,20,40,0.02,0.0,0.0,0.1,Enum.QualityLevel.Level10);      Library:Notification("🎬","🌃 Night Cinematic",3) end)
CIPre:Button("🌫️  Fog Drama",       "Kabut misterius",        function() applyPreset(55,2,12,0.8,300,200,200,200,150,150,150,0.6,0.5,0.0,0.1,Enum.QualityLevel.Level08);  Library:Notification("🎬","🌫️ Fog Drama",3) end)
CIPre:Button("❄️  Snow Scene",      "Salju bersih putih",     function() applyPreset(50,2,10,1.2,500,220,230,255,180,190,210,0.4,0.4,0.0,0.3,Enum.QualityLevel.Level10);  Library:Notification("🎬","❄️ Snow Scene",3) end)
CIPre:Button("🎭  Dark Thriller",   "Gelap intens dramatis",  function() applyPreset(40,2,12,0.1,200,40,40,50,30,30,40,0.8,0.1,0.0,0.0,Enum.QualityLevel.Level08);        Library:Notification("🎬","🎭 Dark Thriller",3) end)
CIPre:Button("📺  Vlog Style",      "Casual natural cerah",   function() applyPreset(75,5,14,1.5,8000,210,225,255,110,110,110,0.1,0.1,0.1,0.15,Enum.QualityLevel.Level05); Library:Notification("🎬","📺 Vlog Style",3) end)
CIPre:Button("🔄  Reset Semua",     "Kembalikan default",     function() applyPreset(70,5,14,1,100000,191,191,191,70,70,70,0.35,0.0,0.0,0.25,Enum.QualityLevel.Level05);   Library:Notification("🎬","🔄 Reset Default",2) end)

CIFine:Slider("☀️ Brightness",  "ftbright",  0,   5,   1,    function(v) Lighting.Brightness = v end)
CIFine:Slider("🕐 ClockTime",   "ftclock",   0,   24,  14,   function(v) Lighting.ClockTime  = v end)
CIFine:Slider("🌫️ Fog Density", "ftdensity", 0,   1,   0,    function(v) local a = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",Lighting); a.Density = v end)
CIFine:Slider("🌅 Offset/Haze", "ftoffset",  0,   1,   0,    function(v) local a = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",Lighting); a.Offset  = v end)
CIFine:Slider("✨ Glare",       "ftglare",   0,   1,   0,    function(v) local a = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",Lighting); a.Glare   = v end)
CIFine:Slider("🌟 Halo",        "fthalo",    0,   1,   0,    function(v) local a = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",Lighting); a.Halo    = v end)
CIFine:Slider("📊 Grafik Level","ftgfx",     1,   10,  5,    function(v) pcall(function() settings().Rendering.QualityLevel = math.floor(v) end) end)

-- TAB 4: SPECTATE
local T_SP = Win:Tab("Spectate", "eye")
local SPP  = T_SP:Page("Viewer", "eye")
local SPS  = SPP:Section("👁️ Spectate Player", "Left")
local SPF  = SPP:Section("🔍 Camera / Zoom", "Right")

local function inJoystickArea(pos)
    local ctrl = LP and LP.PlayerGui and LP.PlayerGui:FindFirstChild("TouchGui")
    if ctrl then
        local frame = ctrl:FindFirstChild("TouchControlFrame")
        local thumb = frame and frame:FindFirstChild("DynamicThumbstickFrame")
        if thumb then
            local ap = thumb.AbsolutePosition
            local as = thumb.AbsoluteSize
            if pos.X >= ap.X and pos.Y >= ap.Y and pos.X <= ap.X+as.X and pos.Y <= ap.Y+as.Y then
                return true
            end
        end
    end
    return false
end

local Spec = {
    active  = false,
    target  = nil,
    mode    = "third",
    dist    = 8,
    origFov = 70,
    orbitYaw   = 0,
    orbitPitch = 0,
    fpYaw   = 0,
    fpPitch = 0,
}

local specTouchMain  = nil
local specTouchPinch = {}
local specPinchDist  = nil
local specPanDelta   = Vector2.zero
local specConns      = {}

local function startSpecCapture()
    table.insert(specConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or not Spec.active then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inJoystickArea(inp.Position) then return end
        table.insert(specTouchPinch, inp)
        if #specTouchPinch == 1 then
            specTouchMain = inp
        else
            specTouchMain = nil
        end
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
                if Spec.mode == "third" then
                    Spec.dist = math.clamp(Spec.dist - diff * 0.03, 3, 30)
                end
            end
            specPinchDist = d
        end
    end))

    table.insert(specConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        for i, v in ipairs(specTouchPinch) do
            if v == inp then table.remove(specTouchPinch, i); break end
        end
        specPinchDist = nil
        if #specTouchPinch == 1 then
            specTouchMain = specTouchPinch[1]
        else
            specTouchMain = nil
        end
    end))
end

local function stopSpecCapture()
    for _, c in ipairs(specConns) do c:Disconnect() end
    specConns      = {}
    specTouchMain  = nil
    specTouchPinch = {}
    specPinchDist  = nil
    specPanDelta   = Vector2.zero
end

local specLoop = nil

local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not Spec.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable

        local char = Spec.target and Spec.target.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local pan  = specPanDelta
        specPanDelta = Vector2.zero
        local sens = 0.3

        if Spec.mode == "third" then
            Spec.orbitYaw   = Spec.orbitYaw   + pan.X * sens
            Spec.orbitPitch = math.clamp(Spec.orbitPitch + pan.Y * sens, -75, 75)

            local orbitCF = CFrame.new(hrp.Position)
                * CFrame.Angles(0, math.rad(-Spec.orbitYaw), 0)
                * CFrame.Angles(math.rad(-Spec.orbitPitch), 0, 0)
                * CFrame.new(0, 0, Spec.dist)

            local focusPos = hrp.Position + Vector3.new(0, 1, 0)
            Cam.CFrame = CFrame.new(orbitCF.Position, focusPos)

        else
            local head = char:FindFirstChild("Head")
            local origin = head and head.Position or hrp.Position + Vector3.new(0, 1.5, 0)

            Spec.fpYaw   = Spec.fpYaw   - pan.X * sens
            Spec.fpPitch = math.clamp(Spec.fpPitch - pan.Y * sens, -85, 85)

            Cam.CFrame = CFrame.new(origin)
                * CFrame.Angles(0, math.rad(Spec.fpYaw), 0)
                * CFrame.Angles(math.rad(Spec.fpPitch), 0, 0)
        end
    end)
    specLoop = true
end

local function stopSpecLoop()
    RS:UnbindFromRenderStep("XKIDSpec")
    specLoop = nil
end

local specDrop = SPS:Dropdown("Pilih Target", "spDrop", getDisplayNames(), function(v)
    local p = findPlayerByDisplay(v)
    if p then
        Spec.target = p
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ()
            Spec.orbitYaw   = math.deg(ry)
            Spec.orbitPitch = 20
            Spec.fpYaw      = math.deg(ry)
            Spec.fpPitch    = 0
        end
    end
end)
SPS:Button("🔄 Refresh", "", function()
    Spec.target = nil
    specDrop:Refresh(getDisplayNames())
    Library:Notification("Spectate", "List diperbarui!", 2)
end)

SPS:Toggle("👁️ Spectate ON/OFF", "spec", false, "Nonton target", function(v)
    Spec.active = v
    if v then
        if not Spec.target then
            Library:Notification("Spectate", "Pilih target dulu!", 3)
            Spec.active = false
            return
        end
        Spec.origFov = Cam.FieldOfView
        startSpecCapture()
        startSpecLoop()
        Library:Notification("Spectate", "Nonton: " .. Spec.target.DisplayName, 3)
    else
        stopSpecLoop()
        stopSpecCapture()
        Cam.CameraType = Enum.CameraType.Custom
        Cam.FieldOfView = Spec.origFov
        Library:Notification("Spectate", "Spectate off!", 2)
    end
end)

SPS:Toggle("🎥 First Person", "specfp", false, "ON=FP Drone | OFF=Orbit", function(v)
    Spec.mode = v and "first" or "third"
    if v and Spec.target and Spec.target.Character then
        local _, ry, _ = Cam.CFrame:ToEulerAnglesYXZ()
        local rx = math.asin(Cam.CFrame.LookVector.Y)
        Spec.fpYaw   = math.deg(ry)
        Spec.fpPitch = math.deg(rx)
    end
end)

SPS:Slider("Jarak Orbit", "specdist", 3, 30, 8, function(v)
    Spec.dist = v
end)

SPF:Button("🔄 Refresh POV Camera", "Reset bug kamera/karakter", function()
    local r = getRoot()
    local h = getHum()
    if not r or not h then
        Library:Notification("Refresh", "❌ Karakter tidak ditemukan!", 2)
        return
    end
    Cam.CameraType = Enum.CameraType.Custom
    task.wait(0.05)
    Cam.CameraType = Enum.CameraType.Scriptable
    task.wait(0.05)
    Cam.CameraType = Enum.CameraType.Custom
    pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    Library:Notification("✅ Refresh", "Kamera sudah di-reset normal!", 2)
end)

SPF:Button("🔭 Zoom In  [ FOV - ]", "Makin sempit", function()
    local newFov = math.clamp(Cam.FieldOfView - 10, 10, 120)
    Cam.FieldOfView = newFov
    Library:Notification("FOV", "FOV: " .. newFov, 1)
end)
SPF:Button("🔭 Zoom In  [ FOV -- ]", "Makin sempit cepat", function()
    local newFov = math.clamp(Cam.FieldOfView - 30, 10, 120)
    Cam.FieldOfView = newFov
    Library:Notification("FOV", "FOV: " .. newFov, 1)
end)
SPF:Button("👁️ Reset Normal (70)", "", function()
    Cam.FieldOfView = 70
    Library:Notification("FOV", "FOV: 70 (Normal)", 1)
end)
SPF:Button("🌐 Zoom Out [ FOV + ]", "Makin lebar", function()
    local newFov = math.clamp(Cam.FieldOfView + 10, 10, 120)
    Cam.FieldOfView = newFov
    Library:Notification("FOV", "FOV: " .. newFov, 1)
end)
SPF:Button("🌐 Zoom Out [ FOV ++ ]", "Makin lebar cepat", function()
    local newFov = math.clamp(Cam.FieldOfView + 30, 10, 120)
    Cam.FieldOfView = newFov
    Library:Notification("FOV", "FOV: " .. newFov, 1)
end)

-- TAB 5: WORLD
local T_WO = Win:Tab("World", "globe")

local WOP1  = T_WO:Page("Weather", "cloud")
local WOW   = WOP1:Section("🌤️ Preset Cuaca", "Left")
local WOA   = WOP1:Section("🌈 Atmosphere", "Right")

local function getAtmos()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atm then
        atm = Instance.new("Atmosphere", Lighting)
    end
    return atm
end

local function setWeather(clock, bright, fogStart, fogEnd, fogR, fogG, fogB, ambR, ambG, ambB, density, offset, glare, halo)
    Lighting.ClockTime        = clock
    Lighting.Brightness       = bright
    Lighting.FogStart         = fogStart
    Lighting.FogEnd           = fogEnd
    Lighting.FogColor         = Color3.fromRGB(fogR, fogG, fogB)
    Lighting.Ambient          = Color3.fromRGB(ambR, ambG, ambB)
    local atm                 = getAtmos()
    atm.Density               = density
    atm.Offset                = offset
    atm.Glare                 = glare
    atm.Halo                  = halo
end

WOW:Button("☀️ Cerah", "Siang terang", function()
    setWeather(14, 2, 1000, 10000, 200,220,255, 120,120,120, 0.05, 0.1, 0.3, 0.2)
    Library:Notification("Weather", "☀️ Cerah!", 2)
end)
WOW:Button("🌅 Sunset / Golden Hour", "Sore hari", function()
    setWeather(18, 1.5, 500, 4000, 255,180,100, 180,100,60, 0.2, 0.3, 0.8, 0.5)
    Library:Notification("Weather", "🌅 Golden Hour!", 2)
end)
WOW:Button("🌃 Malam Bintang", "Malam cerah", function()
    setWeather(0, 0.3, 2000, 20000, 10,10,30, 20,20,40, 0.02, 0.0, 0.0, 0.1)
    Library:Notification("Weather", "🌃 Malam Bintang!", 2)
end)
WOW:Button("🌫️ Berkabut", "Kabut tebal", function()
    setWeather(12, 0.8, 20, 300, 200,200,200, 150,150,150, 0.6, 0.5, 0.0, 0.1)
    Library:Notification("Weather", "🌫️ Berkabut!", 2)
end)
WOW:Button("🌧️ Mendung Gelap", "Awan gelap", function()
    setWeather(12, 0.4, 100, 800, 80,80,100, 60,60,80, 0.5, 0.2, 0.0, 0.0)
    Library:Notification("Weather", "🌧️ Mendung Gelap!", 2)
end)
WOW:Button("❄️ Salju", "Putih bersih", function()
    setWeather(10, 1.2, 50, 500, 220,230,255, 180,190,210, 0.4, 0.4, 0.0, 0.3)
    Library:Notification("Weather", "❄️ Salju!", 2)
end)
WOW:Button("🌪️ Badai", "Gelap & berat", function()
    setWeather(12, 0.1, 30, 200, 40,40,50, 30,30,40, 0.8, 0.1, 0.0, 0.0)
    Library:Notification("Weather", "🌪️ Badai!", 2)
end)
WOW:Button("🔄 Reset Default", "Kembalikan normal", function()
    setWeather(14, 1, 0, 100000, 191,191,191, 70,70,70, 0.35, 0.0, 0.0, 0.25)
    Library:Notification("Weather", "🔄 Reset!", 2)
end)

WOA:Slider("🕐 ClockTime", "wtime", 0, 24, 14, function(v)
    Lighting.ClockTime = v
end)
WOA:Slider("☀️ Brightness", "wbright", 0, 5, 1, function(v)
    Lighting.Brightness = v
end)
WOA:Slider("🌫️ Fog Jarak", "wfog", 0, 5000, 100000, function(v)
    Lighting.FogEnd = v
end)
WOA:Slider("💨 Density", "wdens", 0, 1, 0, function(v)
    getAtmos().Density = v
end)
WOA:Slider("🌅 Offset (Haze)", "woffset", 0, 1, 0, function(v)
    getAtmos().Offset = v
end)
WOA:Slider("✨ Glare", "wglare", 0, 1, 0, function(v)
    getAtmos().Glare = v
end)
WOA:Slider("🌟 Halo", "whalo", 0, 1, 0, function(v)
    getAtmos().Halo = v
end)

local WOP2  = T_WO:Page("Graphics", "monitor")
local WOG   = WOP2:Section("📱 Mode Grafik", "Left")
local WOGF  = WOP2:Section("⚙️ Level Manual", "Right")

local function setGfx(level)
    local ok, err = pcall(function()
        settings().Rendering.QualityLevel = level
    end)
    if not ok then
        pcall(function()
            UserSettings():GetService("UserGameSettings").SavedQualityLevel = level
        end)
    end
end

WOG:Button("🥔 Potato (Level 1)", "Paling hemat", function()
    setGfx(Enum.QualityLevel.Level01)
    Library:Notification("Graphics", "🥔 Potato — Level 1", 2)
end)
WOG:Button("📉 Low (Level 3)", "Ringan", function()
    setGfx(Enum.QualityLevel.Level03)
    Library:Notification("Graphics", "📉 Low — Level 3", 2)
end)
WOG:Button("📊 Medium (Level 5)", "Seimbang", function()
    setGfx(Enum.QualityLevel.Level05)
    Library:Notification("Graphics", "📊 Medium — Level 5", 2)
end)
WOG:Button("📈 High (Level 8)", "Bagus", function()
    setGfx(Enum.QualityLevel.Level08)
    Library:Notification("Graphics", "📈 High — Level 8", 2)
end)
WOG:Button("💎 Ultra (Level 10)", "Maksimal", function()
    setGfx(Enum.QualityLevel.Level10)
    Library:Notification("Graphics", "💎 Ultra — Level 10", 2)
end)
WOG:Button("🎬 Cinematic (Ultra+Atmos)", "Terbaik untuk rekam", function()
    setGfx(Enum.QualityLevel.Level10)
    setWeather(14, 2, 1000, 10000, 200,220,255, 120,120,120, 0.05, 0.1, 0.3, 0.2)
    Library:Notification("Graphics", "🎬 Cinematic Mode!", 3)
end)

WOGF:Button("▲ Naik Level", "Grafik lebih tinggi", function()
    local cur = settings().Rendering.QualityLevel.Value
    local next = math.clamp(cur + 1, 1, 10)
    setGfx(next)
    Library:Notification("Graphics", "Level: " .. next, 1)
end)
WOGF:Button("▼ Turun Level", "Grafik lebih rendah", function()
    local cur = settings().Rendering.QualityLevel.Value
    local next = math.clamp(cur - 1, 1, 10)
    setGfx(next)
    Library:Notification("Graphics", "Level: " .. next, 1)
end)
WOGF:Button("🔄 Cek Level Sekarang", "", function()
    local cur = settings().Rendering.QualityLevel.Value
    Library:Notification("Graphics", "Level Sekarang: " .. cur, 3)
end)

-- ═══════════════════════════════════════════════════════════
-- TAB 6: SECURITY (dengan Modern 3D ESP)
-- ═══════════════════════════════════════════════════════════

local T_SC  = Win:Tab("Security", "shield")

local SCPage = T_SC:Page("Guard", "shield")
local SCP   = SCPage:Section("🛡️ Protection", "Left")
local SCR   = SCPage:Section("💀 Respawn", "Right")

SCP:Toggle("Anti-AFK", "afk", false, "Cegah kick diam (Bypass)", function(v)
    if v then
        State.Security.afkConn = LP.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            VirtualUser:Button2Down(Vector2.new(0,0), Cam.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), Cam.CFrame)
        end)
        pcall(function()
            for _, conn in pairs(getconnections(LP.Idled)) do
                conn:Disable()
            end
        end)
        Library:Notification("Anti-AFK", "🛡️ Bypass aktif, aman AFK lama!", 2)
    else
        if State.Security.afkConn then 
            State.Security.afkConn:Disconnect() 
            State.Security.afkConn = nil
        end
        pcall(function()
            for _, conn in pairs(getconnections(LP.Idled)) do
                conn:Enable()
            end
        end)
        Library:Notification("Anti-AFK", "❌ Bypass mati", 2)
    end
end)

-- ESP TRACKER PAGE
local ESPTracker = T_SC:Page("ESP Tracker", "radar")
local ESPM = ESPTracker:Section("🎯 Mode", "Left")
local ESPO = ESPTracker:Section("⚙️ Options", "Right")

ESPM:Toggle("🎬 ESP ON/OFF", "esp_toggle", false, "Master toggle", function(v)
    State.ESP.active = v
    if v then
        Library:Notification("ESP", "🎬 ESP Enabled!", 2)
    else
        Library:Notification("ESP", "🎬 ESP Disabled", 2)
        for _, cache in pairs(State.ESP.cache) do
            for _, render in pairs(cache.renders) do
                if render and render.Parent then render:Destroy() end
            end
        end
        State.ESP.cache = {}
    end
end)

ESPM:Dropdown("📦 Box Mode", "esp_boxmode", {"3D", "SKELETON", "OFF"}, function(v)
    State.ESP.boxMode = v
    Library:Notification("ESP", "Box Mode: " .. v, 2)
end)

ESPM:Dropdown("🔴 Tracer Type", "esp_tracer", {"ADVANCED", "SIMPLE", "OFF"}, function(v)
    State.ESP.tracerMode = v
    Library:Notification("ESP", "Tracer: " .. v, 2)
end)

ESPO:Toggle("📍 Show Distance", "esp_dist", true, "Tampilkan jarak", function(v)
    State.ESP.showDistance = v
end)

ESPO:Toggle("👤 Show Nickname", "esp_nick", true, "Tampilkan nama", function(v)
    State.ESP.showNickname = v
end)

ESPO:Slider("🎯 Draw Distance", "esp_maxdist", 50, 500, 300, function(v)
    State.ESP.maxDrawDistance = v
    Library:Notification("ESP", "Distance: " .. v, 1)
end)

local ESPPreset = ESPTracker:Section("💾 Presets", "Left")

ESPPreset:Button("🎮 Gameplay", "3D+Tracer", function()
    State.ESP.boxMode = "3D"
    State.ESP.tracerMode = "ADVANCED"
    State.ESP.maxDrawDistance = 300
    Library:Notification("ESP", "🎮 Gameplay Mode", 2)
end)

ESPPreset:Button("💀 Skeleton", "Bones only", function()
    State.ESP.boxMode = "SKELETON"
    State.ESP.tracerMode = "SIMPLE"
    State.ESP.maxDrawDistance = 200
    Library:Notification("ESP", "💀 Skeleton", 2)
end)

ESPPreset:Button("🔍 Scout", "Far range", function()
    State.ESP.boxMode = "OFF"
    State.ESP.tracerMode = "SIMPLE"
    State.ESP.maxDrawDistance = 500
    Library:Notification("ESP", "🔍 Scout", 2)
end)

SCP:Button("🔄 Rejoin Server", "Masuk ulang", function()
    TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end)

-- Fast Respawn
local respawnLastPos = nil

task.spawn(function()
    while true do
        task.wait(1)
        local r = getRoot()
        local h = getHum()
        if r and h and h.Health > 0 then
            respawnLastPos = r.CFrame
        end
    end
end)

SCR:Button("💀 Fast Respawn", "Mati & balik ke posisi terakhir", function()
    if not respawnLastPos then
        Library:Notification("Respawn", "❌ Posisi belum direkam!", 2)
        return
    end
    local savedCF = respawnLastPos
    local hum = getHum()
    if not hum then
        Library:Notification("Respawn", "❌ Karakter tidak ditemukan!", 2)
        return
    end
    hum.Health = 0
    task.spawn(function()
        local char = LP.CharacterAdded:Wait()
        task.wait(0.3)
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        if hrp then
            hrp.CFrame = savedCF
            Library:Notification("Respawn", "✅ Balik ke posisi terakhir!", 3)
        end
    end)
end)

-- PERFORMANCE PAGE
local SCPerf = T_SC:Page("Performance", "zap")
local SCFPS  = SCPerf:Section("🚀 FPS Cap", "Left")
local SCLAG  = SCPerf:Section("🗑️ Anti Lag", "Right")

SCFPS:Button("🚀 60 FPS", "Standard", function()
    if setfpscap then setfpscap(60); Library:Notification("FPS", "Cap: 60 FPS", 2) else Library:Notification("Error", "Executor tidak support setfpscap!", 2) end
end)
SCFPS:Button("🚀 90 FPS", "Smooth", function()
    if setfpscap then setfpscap(90); Library:Notification("FPS", "Cap: 90 FPS", 2) else Library:Notification("Error", "Executor tidak support setfpscap!", 2) end
end)
SCFPS:Button("🚀 120 FPS", "Pro Player", function()
    if setfpscap then setfpscap(120); Library:Notification("FPS", "Cap: 120 FPS", 2) else Library:Notification("Error", "Executor tidak support setfpscap!", 2) end
end)
SCFPS:Button("🚀 Max FPS (999)", "Unlock", function()
    if setfpscap then setfpscap(999); Library:Notification("FPS", "FPS Terbuka Maksimal (999)", 2) else Library:Notification("Error", "Executor tidak support setfpscap!", 2) end
end)
SCFPS:Button("🔄 Reset FPS", "Balik Normal", function()
    if setfpscap then setfpscap(0); Library:Notification("FPS", "Reset ke Default Roblox", 2) else Library:Notification("Error", "Executor tidak support setfpscap!", 2) end
end)

local AntiLagState = {
    materials = {},
    textures = {},
    shadows = true
}

SCLAG:Toggle("🗑️ Anti Lag Mode", "antilag", false, "Hapus tekstur", function(v)
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
        Library:Notification("Anti Lag", "🚀 Aktif! Tekstur & Shadow dihilangkan.", 3)
    else
        Lighting.GlobalShadows = AntiLagState.shadows
        
        for obj, mat in pairs(AntiLagState.materials) do
            if obj and obj.Parent then
                obj.Material = mat
            end
        end
        for obj, parent in pairs(AntiLagState.textures) do
            if obj and parent and parent.Parent then
                obj.Parent = parent
            end
        end
        
        AntiLagState.materials = {}
        AntiLagState.textures = {}
        Library:Notification("Anti Lag", "🔄 Reset! Grafik kembali normal.", 3)
    end
end)

-- IY FLING & SOFT FLING LOOP
task.spawn(function()
    while true do
        if (State.Fling.active or State.SoftFling.active) and getRoot() then
            local r = getRoot()
            local isBrutal = State.Fling.active
            local pwr = isBrutal and State.Fling.power or State.SoftFling.power
            local ok = pcall(function()
                r.AssemblyAngularVelocity = Vector3.new(0, pwr, 0)
                if isBrutal then
                    r.AssemblyLinearVelocity  = Vector3.new(pwr, pwr, pwr)
                end
            end)
            if not ok then
                pcall(function()
                    r.RotVelocity = Vector3.new(0, pwr, 0)
                    if isBrutal then
                        r.Velocity    = Vector3.new(pwr, pwr, pwr)
                    end
                end)
            end
        end
        RS.RenderStepped:Wait()
    end
end)

-- NOCLIP LOOP
RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active or State.SoftFling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

Library:Notification("✦ XKID HUB v3", "Modern 3D ESP + Smooth Freecam Ready! 🚀", 5)
