--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        ✦  X  K  I  D     H  U  B  ✦   FINAL  V.2           ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║   🎬  Freecam        👁️  Spectate      🌍  World            ║
║   🗺️  Teleport       ⚡  Player        🛡️  Security         ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║   ✦  Fly Freecam Style   ✦  Lock Rotasi & Kamera            ║
║   ✦  God Mode + Respawn  ✦  JumpPower Control               ║
║   ✦  Preset Cinematic    ✦  All Sliders → Responsive        ║
╚══════════════════════════════════════════════════════════════╝
--]]

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
    Move = {ws = 16, jp = 50, ncp = false, infJ = nil, flyS = 60},
    Fly = {active = false, bv = nil, bg = nil},
    Fling = {active = false, power = 1000000},
    Teleport = {selectedTarget = ""},
    Security = {afkConn = nil},
    Cinema = {active = false, speed = 1, fov = 70, lastPos = nil}
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end

-- Return "Nickname (username)" untuk spectate dropdown
local function getDisplayNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    return t
end

-- Cari player dari string "Nickname (@username)"
local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do
        if str == p.DisplayName .. " (@" .. p.Name .. ")" then
            return p
        end
    end
    return nil
end

-- Mobile detection (lebih akurat)
local onMobile = not UIS.KeyboardEnabled

-- ┌─────────────────────────────────────────────────────────┐
-- │           ➤  FLY ENGINE  (FREECAM STYLE)                │
-- │           SAME MOVEMENT LOGIC AS FREECAM                 │
-- └─────────────────────────────────────────────────────────┘

-- Fly state variables (mirip dengan FreeCam)
local FlyState = {
    active = false,
    bv = nil,
    bg = nil,
    yaw = 0,
    pitch = 0,
    pos = nil,  -- position saat fly start (untuk tracking)
    speed = 60,
    -- Touch state
    rotTouch = nil,
    moveTouch = nil,
    moveStartPos = nil,
    rotLastPos = nil,
    joy = Vector2.zero,
    -- Keyboard state
    keys = {},
    mouseRot = false,
    -- Connections
    conns = {}
}

local function startFlyCapture()
    -- Keyboard handlers
    table.insert(FlyState.conns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or
           k == Enum.KeyCode.S or k == Enum.KeyCode.D or
           k == Enum.KeyCode.E or k == Enum.KeyCode.Q then
            FlyState.keys[k] = true
        end
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            FlyState.mouseRot = true
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end))

    table.insert(FlyState.conns, UIS.InputEnded:Connect(function(inp)
        FlyState.keys[inp.KeyCode] = false
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            FlyState.mouseRot = false
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end))

    -- Mouse rotation (PC)
    table.insert(FlyState.conns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and FlyState.mouseRot then
            FlyState.yaw = FlyState.yaw - inp.Delta.X * 0.3
            FlyState.pitch = math.clamp(FlyState.pitch - inp.Delta.Y * 0.3, -80, 80)
        end
    end))

    -- Touch handlers (Mobile) - split screen: kiri gerak, kanan rotate
    table.insert(FlyState.conns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local half = Cam.ViewportSize.X / 2
        if inp.Position.X > half then
            -- Right side = rotate
            if not FlyState.rotTouch then
                FlyState.rotTouch = inp
                FlyState.rotLastPos = inp.Position
            end
        else
            -- Left side = movement (analog)
            if not FlyState.moveTouch then
                FlyState.moveTouch = inp
                FlyState.moveStartPos = inp.Position
            end
        end
    end))

    table.insert(FlyState.conns, UIS.TouchMoved:Connect(function(inp)
        -- Rotation
        if inp == FlyState.rotTouch and FlyState.rotLastPos then
            local dx = inp.Position.X - FlyState.rotLastPos.X
            local dy = inp.Position.Y - FlyState.rotLastPos.Y
            FlyState.yaw = FlyState.yaw - dx * 0.3
            FlyState.pitch = math.clamp(FlyState.pitch - dy * 0.3, -80, 80)
            FlyState.rotLastPos = inp.Position
        end

        -- Movement analog (left side)
        if inp == FlyState.moveTouch and FlyState.moveStartPos then
            local dx = inp.Position.X - FlyState.moveStartPos.X
            local dy = inp.Position.Y - FlyState.moveStartPos.Y
            local nx = 0
            local ny = 0
            if math.abs(dx) > 25 then
                nx = math.clamp((dx - math.sign(dx) * 25) / 80, -1, 1)
            end
            if math.abs(dy) > 20 then
                ny = math.clamp((dy - math.sign(dy) * 20) / 80, -1, 1)
            end
            FlyState.joy = Vector2.new(nx, ny)
        end
    end))

    table.insert(FlyState.conns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == FlyState.rotTouch then
            FlyState.rotTouch = nil
            FlyState.rotLastPos = nil
        end
        if inp == FlyState.moveTouch then
            FlyState.moveTouch = nil
            FlyState.moveStartPos = nil
            FlyState.joy = Vector2.zero
        end
    end))
end

local function stopFlyCapture()
    for _, c in ipairs(FlyState.conns) do
        pcall(function() c:Disconnect() end)
    end
    FlyState.conns = {}
    FlyState.rotTouch = nil
    FlyState.moveTouch = nil
    FlyState.moveStartPos = nil
    FlyState.rotLastPos = nil
    FlyState.joy = Vector2.zero
    FlyState.mouseRot = false
    FlyState.keys = {}
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

local function stopFly()
    if not FlyState.active then return end
    
    FlyState.active = false
    stopFlyCapture()
    RS:UnbindFromRenderStep("XKIDFly")
    
    if FlyState.bv then 
        pcall(function() FlyState.bv:Destroy() end)
        FlyState.bv = nil
    end
    if FlyState.bg then 
        pcall(function() FlyState.bg:Destroy() end)
        FlyState.bg = nil
    end
    
    local hum = getHum()
    if hum then
        hum.PlatformStand = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        hum.WalkSpeed = State.Move.ws
    end
    
    -- Disable noclip that was activated by fly
    State.Move.ncp = false
    
    Library:Notification("Fly", "✈️ Fly OFF", 2)
end

local function startFly()
    local hrp = getRoot()
    local hum = getHum()
    if not hrp or not hum then
        Library:Notification("Fly", "❌ Character not found!", 2)
        return false
    end
    
    -- Clean up previous fly state
    if FlyState.bv then pcall(function() FlyState.bv:Destroy() end) end
    if FlyState.bg then pcall(function() FlyState.bg:Destroy() end) end
    stopFlyCapture()
    
    FlyState.active = true
    FlyState.speed = State.Move.flyS
    FlyState.pos = hrp.Position
    
    -- Get current camera orientation for initial yaw/pitch
    local cf = Cam.CFrame
    local _, ry, _ = cf:ToEulerAnglesYXZ()
    local rx = math.asin(cf.LookVector.Y)
    FlyState.yaw = math.deg(ry)
    FlyState.pitch = math.deg(rx)
    
    -- Reset input states
    FlyState.keys = {}
    FlyState.joy = Vector2.zero
    FlyState.mouseRot = false
    FlyState.rotTouch = nil
    FlyState.moveTouch = nil
    
    -- Setup character
    hum.PlatformStand = true
    
    -- Auto NoClip saat fly ON
    State.Move.ncp = true
    
    -- BodyVelocity + BodyGyro (sama seperti freecam style)
    FlyState.bv = Instance.new("BodyVelocity", hrp)
    FlyState.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    FlyState.bv.Velocity = Vector3.zero
    
    FlyState.bg = Instance.new("BodyGyro", hrp)
    FlyState.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    FlyState.bg.P = 1e5
    FlyState.bg.CFrame = hrp.CFrame
    
    -- Start input capture
    startFlyCapture()
    
    -- Render loop (sama persis dengan freecam movement logic)
    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FlyState.active then
            RS:UnbindFromRenderStep("XKIDFly")
            return
        end
        
        local r = getRoot()
        local h = getHum()
        if not r or not h then
            -- Character died or respawned
            stopFly()
            return
        end
        
        -- Update position tracking
        FlyState.pos = r.Position
        
        -- Build movement CFrame from yaw and pitch (sama dengan freecam)
        local moveCF = CFrame.new(r.Position)
            * CFrame.Angles(0, math.rad(FlyState.yaw), 0)
            * CFrame.Angles(math.rad(FlyState.pitch), 0, 0)
        
        local spd = FlyState.speed * dt * 60
        local move = Vector3.zero
        local keys = FlyState.keys
        
        if onMobile then
            -- Mobile: analog joystick (kiri layar)
            -- Y axis = forward/backward, X axis = left/right
            move = moveCF.LookVector * (-FlyState.joy.Y) * spd
                 + moveCF.RightVector * FlyState.joy.X * spd
        else
            -- PC: WASD + E/Q
            if keys[Enum.KeyCode.W] then move = move + moveCF.LookVector * spd end
            if keys[Enum.KeyCode.S] then move = move - moveCF.LookVector * spd end
            if keys[Enum.KeyCode.D] then move = move + moveCF.RightVector * spd end
            if keys[Enum.KeyCode.A] then move = move - moveCF.RightVector * spd end
            if keys[Enum.KeyCode.E] then move = move + Vector3.new(0, 1, 0) * spd end
            if keys[Enum.KeyCode.Q] then move = move - Vector3.new(0, 1, 0) * spd end
        end
        
        -- Apply velocity
        if FlyState.bv then
            FlyState.bv.Velocity = move
        end
        
        -- Update gyro to face movement direction (atau maintain orientation)
        if move.Magnitude > 0.1 and FlyState.bg then
            local lookDir = move.Unit
            if lookDir.Y > 0.9 then lookDir = Vector3.new(0, 1, 0) end
            FlyState.bg.CFrame = CFrame.lookAt(r.Position, r.Position + lookDir)
        elseif FlyState.bg then
            FlyState.bg.CFrame = moveCF
        end
    end)
    
    Library:Notification("Fly", "✈️ Fly ON — " .. (onMobile and "Kiri gerak | Kanan rotate" or "WASD + Mouse"), 3)
    return true
end

-- Public toggle function
local function toggleFly(active)
    if active then
        if FlyState.active then stopFly() end
        startFly()
    else
        stopFly()
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │        ➤  FREECAM ENGINE (FIXED & MOBILE READY)         │
-- └─────────────────────────────────────────────────────────┘

-- State freecam
local FC = {
    active          = false,
    pos             = Vector3.zero,
    pitchDeg        = 0,
    yawDeg          = 0,
    speed           = 5,
    sens            = 0.25,
    savedCharCFrame = nil,
}

-- Touch state — split layar kiri gerak, kanan rotate
local fcRotTouch   = nil
local fcMoveTouch  = nil
local fcMoveSt     = nil
local fcRotLast    = nil
local fcJoy        = Vector2.zero
local fcConns      = {}
local fcKeys       = {}
local fcMouseRot   = false

local function startFCCapture()
    -- Keyboard (PC)
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or
           k == Enum.KeyCode.S or k == Enum.KeyCode.D or
           k == Enum.KeyCode.E or k == Enum.KeyCode.Q then
            fcKeys[k] = true
        end
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            fcMouseRot = true
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end))

    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        fcKeys[inp.KeyCode] = false
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            fcMouseRot = false
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end))

    -- Mouse move (PC rotate)
    table.insert(fcConns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and fcMouseRot then
            FC.yawDeg   = FC.yawDeg   - inp.Delta.X * FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg - inp.Delta.Y * FC.sens, -80, 80)
        end
        if inp.UserInputType == Enum.UserInputType.MouseWheel then
            Cam.FieldOfView = math.clamp(Cam.FieldOfView - inp.Position.Z * 5, 10, 120)
        end
    end))

    -- Touch (Mobile)
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
            if math.abs(dx) > 25 then
                nx = math.clamp((dx - math.sign(dx) * 25) / 80, -1, 1)
            end
            if math.abs(dy) > 20 then
                ny = math.clamp((dy - math.sign(dy) * 20) / 80, -1, 1)
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
end

local function stopFCCapture()
    for _, c in ipairs(fcConns) do pcall(function() c:Disconnect() end) end
    fcConns      = {}
    fcRotTouch   = nil
    fcMoveTouch  = nil
    fcMoveSt     = nil
    fcRotLast    = nil
    fcJoy        = Vector2.zero
    fcMouseRot   = false
    fcKeys       = {}
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

local fcInvisSaved = {}

local function startFCLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable

        local cf = CFrame.new(FC.pos)
            * CFrame.Angles(0, math.rad(FC.yawDeg), 0)
            * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)

        local spd  = FC.speed * 32 * dt
        local move = Vector3.zero

        if onMobile then
            move = cf.LookVector * (-fcJoy.Y) * spd
                 + cf.RightVector * fcJoy.X   * spd
        else
            if fcKeys[Enum.KeyCode.W] then move = move + cf.LookVector  * spd end
            if fcKeys[Enum.KeyCode.S] then move = move - cf.LookVector  * spd end
            if fcKeys[Enum.KeyCode.D] then move = move + cf.RightVector * spd end
            if fcKeys[Enum.KeyCode.A] then move = move - cf.RightVector * spd end
            if fcKeys[Enum.KeyCode.E] then move = move + Vector3.new(0,1,0) * spd end
            if fcKeys[Enum.KeyCode.Q] then move = move - Vector3.new(0,1,0) * spd end
        end

        FC.pos = FC.pos + move

        Cam.CFrame = CFrame.new(FC.pos)
            * CFrame.Angles(0, math.rad(FC.yawDeg), 0)
            * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)

        -- Freeze karakter
        local hrp = getRoot()
        local hum = getHum()
        if hrp and not hrp.Anchored then hrp.Anchored = true end
        if hum then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end
    end)
end

local function stopFCLoop()
    RS:UnbindFromRenderStep("XKIDFreecam")
end

local function setFreecam(active)
    FC.active = active
    State.Cinema.active = active
    
    if active then
        local cf = Cam.CFrame
        FC.pos = cf.Position
        local rx, ry = cf:ToEulerAnglesYXZ()
        FC.pitchDeg = math.deg(rx)
        FC.yawDeg   = math.deg(ry)
        fcKeys = {}
        fcMouseRot = false
        
        local hrp = getRoot()
        local hum = getHum()
        if hrp then
            FC.savedCharCFrame = hrp.CFrame
            hrp.Anchored = true
        end
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
        end
        
        -- Sembunyikan karakter
        local char = LP.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    fcInvisSaved[part] = part.Transparency
                    part.Transparency = 1
                end
            end
        end
        
        startFCCapture()
        startFCLoop()
        Library:Notification("Freecam", "ON — " .. (onMobile and "Kiri gerak | Kanan rotate" or "WASD + Mouse"), 3)
    else
        stopFCLoop()
        stopFCCapture()
        
        for part, t in pairs(fcInvisSaved) do
            pcall(function() if part and part.Parent then part.Transparency = t end end)
        end
        fcInvisSaved = {}
        
        local hrp = getRoot()
        local hum = getHum()
        if hrp then
            hrp.Anchored = false
            if FC.savedCharCFrame then
                pcall(function() hrp.CFrame = FC.savedCharCFrame end)
                FC.savedCharCFrame = nil
            end
        end
        if hum then
            hum.WalkSpeed = State.Move.ws
            hum.JumpPower = State.Move.jp
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        
        Cam.FieldOfView = 70
        Cam.CameraType = Enum.CameraType.Custom
        Library:Notification("Freecam", "OFF", 2)
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘

local Win = Library:Window("✦ XKID HUB — FINAL V.2 ✦", "star", "FREECAM", false)

-- --- TAB 1: TELEPORT ---
local T_TP = Win:Tab("Teleport", "map-pin")
local TPT = T_TP:Page("Navigation", "map-pin"):Section("🎯 Smart Search", "Left")

TPT:TextBox("Ketik 2-3 Huruf Nama", "pText", "", function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🚀 Teleport Now", "Fast TP", function()
    local snippet = State.Teleport.selectedTarget
    if snippet == "" then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and (string.find(string.lower(p.Name), string.lower(snippet)) or string.find(string.lower(p.DisplayName), string.lower(snippet))) then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = getRoot()
                if hrp then hrp.CFrame = p.Character.HumanoidRootPart.CFrame end
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
        Library:Notification("✅ Saved", "Slot " .. idx .. " tersimpan!", 2)
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

-- --- TAB 2: PLAYER ---
local T_PL = Win:Tab("Player", "user")

-- PAGE 1: MOVEMENT
local PLPage1 = T_PL:Page("Movement", "zap")
local PLM = PLPage1:Section("⚡ Movement", "Left")
local PLH = PLPage1:Section("🚀 Abilities", "Right")

-- Refresh POV
PLM:Button("🔄 Refresh POV", "Reset kamera & karakter", function()
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
    Library:Notification("✅ Refresh", "POV & kamera sudah di-reset!", 2)
end)

-- WalkSpeed Slider (Responsive)
PLM:Slider("🏃 Walk Speed", "ws", 16, 500, 16, function(v)
    State.Move.ws = v
    local hum = getHum()
    if hum and not FlyState.active then
        hum.WalkSpeed = v
    end
end)

-- JumpPower Slider (Responsive)
PLM:Slider("🦘 Jump Power", "jp", 50, 500, 50, function(v)
    State.Move.jp = v
    local hum = getHum()
    if hum then
        hum.JumpPower = v
    end
end)

PLM:Toggle("∞  Inf Jump", "ij", false, "Lompat terus", function(v)
    if v then
        State.Move.infJ = UIS.JumpRequest:Connect(function()
            local hum = getHum()
            if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
        end)
    else
        if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end
    end
end)

-- Fly Section
PLH:Toggle("✈️  Freecam Fly", "nf", false, "Smooth movement", function(v)
    toggleFly(v)
end)

-- Fly Speed Slider (Responsive)
PLH:Slider("✈️ Fly Speed", "flys", 10, 300, 60, function(v)
    State.Move.flyS = v
    if FlyState.active then
        FlyState.speed = v
    end
end)

PLH:Toggle("👻 NoClip", "nc", false, "Tembus dinding", function(v)
    State.Move.ncp = v
end)

PLH:Toggle("💥 IY Fling", "ffm", false, "Tabrak!", function(v)
    State.Fling.active = v
    if v then State.Move.ncp = true end
end)

-- God Mode dengan Fast Respawn
local godConn = nil
local godRespawnConn = nil
local godLastPos = nil
local godActive = false

PLH:Toggle("🛡️ God Mode", "god", false, "HP Infinite + Fast Respawn", function(v)
    godActive = v
    if v then
        local hum = getHum()
        if hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
        
        godLastPos = getRoot() and getRoot().CFrame
        
        godRespawnConn = RS.Heartbeat:Connect(function()
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
        
        -- Fast Respawn handler
        LP.CharacterAdded:Connect(function(char)
            if not godActive then return end
            task.wait(0.1)
            local hrp = char:WaitForChild("HumanoidRootPart", 3)
            local hum = char:WaitForChild("Humanoid", 3)
            if hrp and godLastPos then
                hrp.CFrame = godLastPos
            end
            if hum then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
            end
            -- Re-apply noclip if needed
            if State.Move.ncp then
                task.wait(0.05)
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        
        Library:Notification("God Mode", "🛡️ Aktif! Fast Respawn siap", 3)
    else
        if godConn then godConn:Disconnect(); godConn = nil end
        if godRespawnConn then godRespawnConn:Disconnect(); godRespawnConn = nil end
        local hum = getHum()
        if hum then hum.MaxHealth = 100; hum.Health = 100 end
        Library:Notification("God Mode", "❌ Nonaktif", 2)
    end
end)

-- PAGE 2: LOCK
local PLPage2 = T_PL:Page("Lock", "lock")
local PLLock  = PLPage2:Section("🔒 Lock Karakter", "Left")
local PLLockR = PLPage2:Section("📷 Lock Kamera", "Right")

local lockRotConn = nil
local lockedYaw = 0

PLLock:Toggle("🔒 Lock Rotasi", "lockrot", false, "Karakter tidak berputar", function(v)
    if v then
        local hrp = getRoot()
        if not hrp then
            Library:Notification("Lock", "❌ Karakter tidak ditemukan!", 2)
            return
        end
        local _, ry, _ = hrp.CFrame:ToEulerAnglesYXZ()
        lockedYaw = ry
        lockRotConn = RS.Heartbeat:Connect(function()
            local r = getRoot()
            if r then
                r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, lockedYaw, 0)
            end
        end)
        Library:Notification("Lock", "🔒 Rotasi dikunci!", 2)
    else
        if lockRotConn then lockRotConn:Disconnect(); lockRotConn = nil end
        Library:Notification("Lock", "🔓 Rotasi bebas", 2)
    end
end)

PLLock:Button("📌 Simpan Arah Sekarang", "", function()
    local hrp = getRoot()
    if hrp then
        local _, ry, _ = hrp.CFrame:ToEulerAnglesYXZ()
        lockedYaw = ry
        Library:Notification("Lock", "📌 Arah baru disimpan!", 2)
    end
end)

local lockPosConn = nil
local lockedCF = nil

PLLock:Toggle("📍 Lock Posisi", "lockpos", false, "Karakter diam total", function(v)
    if v then
        local hrp = getRoot()
        if not hrp then return end
        lockedCF = hrp.CFrame
        hrp.Anchored = true
        lockPosConn = RS.Heartbeat:Connect(function()
            local r = getRoot()
            if r and lockedCF then
                r.CFrame = lockedCF
            end
        end)
        Library:Notification("Lock", "📍 Posisi dikunci!", 2)
    else
        if lockPosConn then lockPosConn:Disconnect(); lockPosConn = nil end
        local hrp = getRoot()
        if hrp then hrp.Anchored = false end
        Library:Notification("Lock", "🔓 Posisi bebas", 2)
    end
end)

PLLock:Button("📌 Update Posisi Kunci", "", function()
    local hrp = getRoot()
    if hrp then
        lockedCF = hrp.CFrame
        Library:Notification("Lock", "📌 Posisi baru dikunci!", 2)
    end
end)

local lockCamConn = nil
local lockCamDist = 8

PLLockR:Toggle("📷 Lock Kamera", "lockcam", false, "Kamera follow karakter", function(v)
    if v then
        Cam.CameraType = Enum.CameraType.Scriptable
        lockCamConn = RS.RenderStepped:Connect(function()
            local hrp = getRoot()
            if not hrp then return end
            local _, ry, _ = hrp.CFrame:ToEulerAnglesYXZ()
            local camPos = hrp.Position + CFrame.Angles(0, ry, 0) * Vector3.new(0, 2, lockCamDist)
            local focusPos = hrp.Position + Vector3.new(0, 1, 0)
            Cam.CFrame = CFrame.new(camPos, focusPos)
        end)
        Library:Notification("Kamera", "📷 Kamera dikunci!", 2)
    else
        if lockCamConn then lockCamConn:Disconnect(); lockCamConn = nil end
        Cam.CameraType = Enum.CameraType.Custom
        Library:Notification("Kamera", "🔓 Kamera bebas", 2)
    end
end)

PLLockR:Slider("📷 Jarak Kamera", "camdist", 3, 30, 8, function(v)
    lockCamDist = v
end)

-- PAGE 3: ATMOSPHERE
local PLPage3 = T_PL:Page("Atmosphere", "cloud")
local PLW = PLPage3:Section("🌦️ Waktu & Cahaya", "Left")

PLW:Slider("🕐 Waktu (ClockTime)", "time", 0, 24, 12, function(v)
    Lighting.ClockTime = v
end)
PLW:Button("☀️ Set Siang", "", function() Lighting.ClockTime = 14 end)
PLW:Button("🌙 Set Malam", "", function() Lighting.ClockTime = 0 end)

-- --- TAB 3: CINEMATIC ---
local T_CI = Win:Tab("Cinematic", "video")
local CIPage1 = T_CI:Page("Freecam", "video")
local CIM = CIPage1:Section("🎬 Freecam", "Left")
local CIW = CIPage1:Section("📱 Display", "Right")

CIM:Toggle("🎬 Freecam ON/OFF", "fc", false, onMobile and "Kiri gerak | Kanan rotate" or "WASD + Mouse", function(v)
    setFreecam(v)
end)

CIM:Slider("⚡ Freecam Speed", "fcspeed", 1, 30, 5, function(v)
    FC.speed = v
end)

CIM:Slider("🎯 Sensitivity", "fcsens", 0.05, 1, 0.25, function(v)
    FC.sens = v
end)

CIM:Slider("🔍 FOV", "fcfov", 10, 120, 70, function(v)
    Cam.FieldOfView = v
end)

CIM:Button("🔄 Reset FOV", "FOV normal 70", function()
    Cam.FieldOfView = 70
    Library:Notification("Freecam", "FOV: 70 (Normal)", 1)
end)

CIW:Button("📱 Portrait", "Tegak", function()
    pcall(function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end)
end)
CIW:Button("📺 Landscape", "Mendatar", function()
    pcall(function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end)
end)

-- PAGE 2: CINEMATIC PRESETS
local CIPage2 = T_CI:Page("Presets", "film")
local CIPre = CIPage2:Section("🎬 Preset Sinematik", "Left")
local CIFine = CIPage2:Section("🎛️ Fine-Tune", "Right")

local function applyPreset(fov, speed, clock, bright, fogEnd, fogR, fogG, fogB, ambR, ambG, ambB, density, offset, glare, halo, gfxLevel)
    Cam.FieldOfView = fov
    FC.speed = speed
    Lighting.ClockTime = clock
    Lighting.Brightness = bright
    Lighting.FogEnd = fogEnd
    Lighting.FogColor = Color3.fromRGB(fogR, fogG, fogB)
    Lighting.Ambient = Color3.fromRGB(ambR, ambG, ambB)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Density = density
    atm.Offset = offset
    atm.Glare = glare
    atm.Halo = halo
    pcall(function() settings().Rendering.QualityLevel = gfxLevel end)
end

CIPre:Button("☀️ Cinematic Day", "Siang cerah", function()
    applyPreset(50, 3, 14, 2, 10000, 200,220,255, 120,120,120, 0.05, 0.1, 0.3, 0.2, Enum.QualityLevel.Level10)
    Library:Notification("🎬 Preset", "☀️ Cinematic Day", 2)
end)
CIPre:Button("🌆 Golden Hour", "Sore hangat", function()
    applyPreset(55, 3, 18, 1.5, 4000, 255,180,100, 180,100,60, 0.2, 0.3, 0.8, 0.5, Enum.QualityLevel.Level10)
    Library:Notification("🎬 Preset", "🌆 Golden Hour", 2)
end)
CIPre:Button("🌃 Night Cinematic", "Malam dramatis", function()
    applyPreset(45, 2, 0, 0.3, 20000, 10,10,30, 20,20,40, 0.02, 0.0, 0.0, 0.1, Enum.QualityLevel.Level10)
    Library:Notification("🎬 Preset", "🌃 Night Cinematic", 2)
end)
CIPre:Button("🌫️ Fog Drama", "Kabut misterius", function()
    applyPreset(55, 2, 12, 0.8, 300, 200,200,200, 150,150,150, 0.6, 0.5, 0.0, 0.1, Enum.QualityLevel.Level08)
    Library:Notification("🎬 Preset", "🌫️ Fog Drama", 2)
end)
CIPre:Button("❄️ Snow Scene", "Salju putih", function()
    applyPreset(50, 2, 10, 1.2, 500, 220,230,255, 180,190,210, 0.4, 0.4, 0.0, 0.3, Enum.QualityLevel.Level10)
    Library:Notification("🎬 Preset", "❄️ Snow Scene", 2)
end)
CIPre:Button("🎭 Dark Thriller", "Gelap intens", function()
    applyPreset(40, 2, 12, 0.1, 200, 40,40,50, 30,30,40, 0.8, 0.1, 0.0, 0.0, Enum.QualityLevel.Level08)
    Library:Notification("🎬 Preset", "🎭 Dark Thriller", 2)
end)
CIPre:Button("📺 Vlog Style", "Casual natural", function()
    applyPreset(75, 5, 14, 1.5, 8000, 210,225,255, 110,110,110, 0.1, 0.1, 0.1, 0.15, Enum.QualityLevel.Level05)
    Library:Notification("🎬 Preset", "📺 Vlog Style", 2)
end)
CIPre:Button("🔄 Reset Semua", "Kembalikan default", function()
    applyPreset(70, 5, 14, 1, 100000, 191,191,191, 70,70,70, 0.35, 0.0, 0.0, 0.25, Enum.QualityLevel.Level05)
    Library:Notification("🎬 Preset", "🔄 Reset Default", 2)
end)

-- Fine-tune sliders
CIFine:Slider("☀️ Brightness", "bright", 0, 5, 1, function(v)
    Lighting.Brightness = v
end)
CIFine:Slider("🕐 Waktu", "waktu", 0, 24, 14, function(v)
    Lighting.ClockTime = v
end)
CIFine:Slider("🌫️ Fog Density", "fogdens", 0, 1, 0.35, function(v)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Density = v
end)
CIFine:Slider("✨ Glare", "glare", 0, 1, 0, function(v)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Glare = v
end)
CIFine:Slider("🌟 Halo", "halo", 0, 1, 0.25, function(v)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Halo = v
end)

-- --- TAB 4: SPECTATE ---
local T_SP = Win:Tab("Spectate", "eye")
local SPP = T_SP:Page("Viewer", "eye")
local SPS = SPP:Section("👁️ Spectate Player", "Left")
local SPF = SPP:Section("🔍 FOV Zoom", "Right")

local Spec = {
    active = false,
    target = nil,
    mode = "third",
    dist = 8,
    origFov = 70,
    orbitYaw = 0,
    orbitPitch = 0,
    fpYaw = 0,
    fpPitch = 0,
}

local specTouchPinch = {}
local specPinchDist = nil
local specPanDelta = Vector2.zero
local specConns = {}

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

local function startSpecCapture()
    table.insert(specConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or not Spec.active then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inJoystickArea(inp.Position) then return end
        table.insert(specTouchPinch, inp)
    end))

    table.insert(specConns, UIS.InputChanged:Connect(function(inp)
        if not Spec.active then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end

        if #specTouchPinch == 1 and inp == specTouchPinch[1] then
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
    end))
end

local function stopSpecCapture()
    for _, c in ipairs(specConns) do pcall(function() c:Disconnect() end) end
    specConns = {}
    specTouchPinch = {}
    specPinchDist = nil
    specPanDelta = Vector2.zero
end

local specLoop = nil

local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not Spec.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable

        local char = Spec.target and Spec.target.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local pan = specPanDelta
        specPanDelta = Vector2.zero
        local sens = 0.3

        if Spec.mode == "third" then
            Spec.orbitYaw = Spec.orbitYaw + pan.X * sens
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

            Spec.fpYaw = Spec.fpYaw - pan.X * sens
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
            Spec.orbitYaw = math.deg(ry)
            Spec.orbitPitch = 20
            Spec.fpYaw = math.deg(ry)
            Spec.fpPitch = 0
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
            Library:Notification("Spectate", "Pilih target dulu!", 2)
            Spec.active = false
            return
        end
        Spec.origFov = Cam.FieldOfView
        startSpecCapture()
        startSpecLoop()
        Library:Notification("Spectate", "Nonton: " .. Spec.target.DisplayName, 2)
    else
        stopSpecLoop()
        stopSpecCapture()
        Cam.CameraType = Enum.CameraType.Custom
        Cam.FieldOfView = Spec.origFov
        Library:Notification("Spectate", "Spectate off!", 2)
    end
end)

SPS:Toggle("🎥 First Person", "specfp", false, "FP Drone mode", function(v)
    Spec.mode = v and "first" or "third"
    if v and Spec.target and Spec.target.Character then
        local _, ry, _ = Cam.CFrame:ToEulerAnglesYXZ()
        local rx = math.asin(Cam.CFrame.LookVector.Y)
        Spec.fpYaw = math.deg(ry)
        Spec.fpPitch = math.deg(rx)
    end
end)

SPS:Slider("Jarak Orbit", "specdist", 3, 30, 8, function(v)
    Spec.dist = v
end)

-- FOV Zoom
SPF:Slider("🔭 FOV Zoom", "specfov", 10, 120, 70, function(v)
    Cam.FieldOfView = v
end)
SPF:Button("👁️ Reset Normal (70)", "", function()
    Cam.FieldOfView = 70
    Library:Notification("FOV", "FOV: 70 (Normal)", 1)
end)

-- --- TAB 5: WORLD ---
local T_WO = Win:Tab("World", "globe")

-- PAGE 1: WEATHER
local WOP1 = T_WO:Page("Weather", "cloud")
local WOW = WOP1:Section("🌤️ Preset Cuaca", "Left")
local WOA = WOP1:Section("🌈 Atmosphere", "Right")

local function getAtmos()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atm then
        atm = Instance.new("Atmosphere", Lighting)
    end
    return atm
end

local function setWeather(clock, bright, fogStart, fogEnd, fogR, fogG, fogB, ambR, ambG, ambB, density, offset, glare, halo)
    Lighting.ClockTime = clock
    Lighting.Brightness = bright
    Lighting.FogStart = fogStart
    Lighting.FogEnd = fogEnd
    Lighting.FogColor = Color3.fromRGB(fogR, fogG, fogB)
    Lighting.Ambient = Color3.fromRGB(ambR, ambG, ambB)
    local atm = getAtmos()
    atm.Density = density
    atm.Offset = offset
    atm.Glare = glare
    atm.Halo = halo
end

WOW:Button("☀️ Cerah", "Siang terang", function()
    setWeather(14, 2, 1000, 10000, 200,220,255, 120,120,120, 0.05, 0.1, 0.3, 0.2)
    Library:Notification("Weather", "☀️ Cerah!", 2)
end)
WOW:Button("🌅 Sunset", "Sore hari", function()
    setWeather(18, 1.5, 500, 4000, 255,180,100, 180,100,60, 0.2, 0.3, 0.8, 0.5)
    Library:Notification("Weather", "🌅 Sunset!", 2)
end)
WOW:Button("🌃 Malam", "Malam cerah", function()
    setWeather(0, 0.3, 2000, 20000, 10,10,30, 20,20,40, 0.02, 0.0, 0.0, 0.1)
    Library:Notification("Weather", "🌃 Malam!", 2)
end)
WOW:Button("🌫️ Berkabut", "Kabut tebal", function()
    setWeather(12, 0.8, 20, 300, 200,200,200, 150,150,150, 0.6, 0.5, 0.0, 0.1)
    Library:Notification("Weather", "🌫️ Berkabut!", 2)
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
WOA:Slider("💨 Density", "wdens", 0, 1, 0.35, function(v)
    getAtmos().Density = v
end)
WOA:Slider("✨ Glare", "wglare", 0, 1, 0, function(v)
    getAtmos().Glare = v
end)
WOA:Slider("🌟 Halo", "whalo", 0, 1, 0.25, function(v)
    getAtmos().Halo = v
end)

-- PAGE 2: GRAPHICS
local WOP2 = T_WO:Page("Graphics", "monitor")
local WOG = WOP2:Section("📱 Mode Grafik", "Left")
local WOGF = WOP2:Section("⚙️ Level Manual", "Right")

local function setGfx(level)
    pcall(function() settings().Rendering.QualityLevel = level end)
    pcall(function() UserSettings():GetService("UserGameSettings").SavedQualityLevel = level end)
end

WOG:Button("🥔 Potato (Lv1)", "Paling hemat", function()
    setGfx(Enum.QualityLevel.Level01)
    Library:Notification("Graphics", "🥔 Potato — Level 1", 2)
end)
WOG:Button("📉 Low (Lv3)", "Ringan", function()
    setGfx(Enum.QualityLevel.Level03)
    Library:Notification("Graphics", "📉 Low — Level 3", 2)
end)
WOG:Button("📊 Medium (Lv5)", "Seimbang", function()
    setGfx(Enum.QualityLevel.Level05)
    Library:Notification("Graphics", "📊 Medium — Level 5", 2)
end)
WOG:Button("📈 High (Lv8)", "Bagus", function()
    setGfx(Enum.QualityLevel.Level08)
    Library:Notification("Graphics", "📈 High — Level 8", 2)
end)
WOG:Button("💎 Ultra (Lv10)", "Maksimal", function()
    setGfx(Enum.QualityLevel.Level10)
    Library:Notification("Graphics", "💎 Ultra — Level 10", 2)
end)

WOGF:Slider("Level Manual", "gfxlvl", 1, 10, 5, function(v)
    setGfx(v)
    Library:Notification("Graphics", "Level: " .. v, 1)
end)

-- --- TAB 6: SECURITY ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")

SCP:Toggle("Anti-AFK", "afk", false, "", function(v)
    if v then
        State.Security.afkConn = LP.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    else
        if State.Security.afkConn then
            State.Security.afkConn:Disconnect()
            State.Security.afkConn = nil
        end
    end
end)

-- Fast Respawn Button (manual)
SCP:Button("⚡ Fast Respawn", "Respawn ke posisi terakhir", function()
    if godLastPos then
        LP.CharacterAdded:Wait()
        task.wait(0.1)
        local hrp = getRoot()
        if hrp then
            hrp.CFrame = godLastPos
            Library:Notification("Respawn", "✅ Kembali ke posisi terakhir!", 2)
        end
    else
        Library:Notification("Respawn", "❌ Belum ada posisi tersimpan!", 2)
    end
end)

SCP:Button("🔄 Rejoin Server", "", function()
    pcall(function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
end)

-- IY FLING LOOP
task.spawn(function()
    while true do
        if State.Fling.active then
            local r = getRoot()
            if r then
                pcall(function()
                    r.AssemblyAngularVelocity = Vector3.new(0, State.Fling.power, 0)
                    r.AssemblyLinearVelocity = Vector3.new(State.Fling.power, State.Fling.power, State.Fling.power)
                end)
            end
        end
        RS.RenderStepped:Wait()
    end
end)

-- NOCLIP LOOP
RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

Library:Notification("✦ XKID HUB", "FINAL V.2 — Ready! 🚀", 5)
```