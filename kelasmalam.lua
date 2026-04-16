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
║   ✦  God Mode + Respawn  ✦  All +/- → Sliders              ║
║   ✦  Auto Reset Karakter ✦  Kembali Posisi Terakhir         ║
╚══════════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

-- Services
local Players    = game:GetService("Players")
local RS         = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local VirtualUser= game:GetService("VirtualUser")
local Lighting   = game:GetService("Lighting")
local TPService  = game:GetService("TeleportService")
local LP         = Players.LocalPlayer
local Cam        = workspace.CurrentCamera

-- Global State
local State = {
    Move = {ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60},
    Fly  = {active = false, bv = nil, bg = nil},
    Fling= {active = false, power = 1000000},
    Teleport = {selectedTarget = ""},
    Security = {afkConn = nil, lastPos = nil, posConn = nil},
    Cinema   = {active = false, speed = 1, fov = 70, lastPos = nil}
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum()  return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end
local function getDisplayNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")") end
    end
    return t
end
local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do
        if str == p.DisplayName .. " (@" .. p.Name .. ")" then return p end
    end
    return nil
end

-- ┌─────────────────────────────────────────────────────────┐
-- │     ➤  MOBILE DETECT                                    │
-- └─────────────────────────────────────────────────────────┘
local onMobile = not UIS.KeyboardEnabled

-- ┌─────────────────────────────────────────────────────────┐
-- │     ➤  FLY ENGINE  (FIXED JOYSTICK ARAH KAMERA)         │
-- └─────────────────────────────────────────────────────────┘
local flyRotTouch  = nil
local flyMoveTouch = nil
local flyMoveSt    = nil
local flyRotLast   = nil
local flyJoy       = Vector2.zero
local flyYaw       = 0
local flyPitch     = 0
local flyConns     = {}
local flyLastPos   = nil

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
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            State.Fly._mouseRot = true
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp)
        keysHeld[inp.KeyCode] = false
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            State.Fly._mouseRot = false
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end))
    table.insert(flyConns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and State.Fly._mouseRot then
            flyYaw   = flyYaw   - inp.Delta.X * 0.3
            flyPitch = math.clamp(flyPitch - inp.Delta.Y * 0.3, -80, 80)
        end
    end))
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local half = Cam.ViewportSize.X / 2
        if inp.Position.X > half then
            if not flyRotTouch then flyRotTouch = inp; flyRotLast = inp.Position end
        else
            if not flyMoveTouch then flyMoveTouch = inp; flyMoveSt = inp.Position end
        end
    end))
    table.insert(flyConns, UIS.TouchMoved:Connect(function(inp)
        if inp == flyRotTouch and flyRotLast then
            flyYaw   = flyYaw   - (inp.Position.X - flyRotLast.X) * 0.3
            flyPitch = math.clamp(flyPitch - (inp.Position.Y - flyRotLast.Y) * 0.3, -80, 80)
            flyRotLast = inp.Position
        end
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
        if inp == flyRotTouch  then flyRotTouch  = nil; flyRotLast  = nil end
        if inp == flyMoveTouch then flyMoveTouch = nil; flyMoveSt   = nil; flyJoy = Vector2.zero end
    end))
    State.Fly._keys = keysHeld
end

local function stopFlyCapture()
    for _, c in ipairs(flyConns) do c:Disconnect() end
    flyConns = {}
    flyRotTouch = nil; flyMoveTouch = nil
    flyMoveSt   = nil; flyRotLast   = nil
    flyJoy = Vector2.zero
    State.Fly._mouseRot = false
    State.Fly._keys = {}
    UIS.MouseBehavior = Enum.MouseBehavior.Default
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
            hum.JumpPower = State.Move.jp
        end
        State.Move.ncp = false
        Library:Notification("Fly", "✈️ Fly OFF", 2)
        return
    end

    local hrp = getRoot()
    local hum = getHum()
    if not hrp or not hum then
        Library:Notification("Fly", "❌ Karakter tidak ditemukan!", 2)
        return
    end

    State.Fly.active = true
    hum.PlatformStand = true
    State.Move.ncp = true

    flyLastPos = hrp.CFrame

    if State.Fly.bv then State.Fly.bv:Destroy() end
    if State.Fly.bg then State.Fly.bg:Destroy() end

    State.Fly.bv = Instance.new("BodyVelocity")
    State.Fly.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    State.Fly.bv.Velocity  = Vector3.zero
    State.Fly.bv.Parent    = hrp

    State.Fly.bg = Instance.new("BodyGyro")
    State.Fly.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    State.Fly.bg.P = 1e5
    State.Fly.bg.Parent    = hrp

    local _, ry = Cam.CFrame:ToEulerAnglesYXZ()
    flyYaw   = math.deg(ry)
    flyPitch = 0

    startFlyCapture()

    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not State.Fly.active then return end
        local r = getRoot()
        local h = getHum()
        if not r or not h then return end

        flyLastPos = r.CFrame
        if State.Security.lastPos ~= nil then
            State.Security.lastPos = r.CFrame
        end

        -- PERBAIKAN: arah berdasarkan kamera (sama kaya freecam)
        local camDir = CFrame.new(r.Position)
            * CFrame.Angles(0, math.rad(flyYaw), 0)
            * CFrame.Angles(math.rad(flyPitch), 0, 0)

        local spd  = State.Move.flyS * dt * 60
        local move = Vector3.zero
        local keys = State.Fly._keys or {}

        if onMobile then
            -- Joystick sesuai arah kamera
            move = camDir.LookVector * (-flyJoy.Y) * spd
                 + camDir.RightVector * flyJoy.X * spd
        else
            if keys[Enum.KeyCode.W] then move = move + camDir.LookVector  * spd end
            if keys[Enum.KeyCode.S] then move = move - camDir.LookVector  * spd end
            if keys[Enum.KeyCode.D] then move = move + camDir.RightVector * spd end
            if keys[Enum.KeyCode.A] then move = move - camDir.RightVector * spd end
            if keys[Enum.KeyCode.E] then move = move + Vector3.new(0,1,0) * spd end
            if keys[Enum.KeyCode.Q] then move = move - Vector3.new(0,1,0) * spd end
        end

        if State.Fly.bv and State.Fly.bv.Parent then
            State.Fly.bv.Velocity = move
        end
        if State.Fly.bg and State.Fly.bg.Parent then
            State.Fly.bg.CFrame = camDir
        end
    end)

    Library:Notification("Fly", "✈️ Fly ON — Kiri gerak | Kanan rotate", 3)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │        ➤  FREECAM ENGINE (FIXED & MOBILE READY)         │
-- └─────────────────────────────────────────────────────────┘
local FC = {
    active          = false,
    pos             = Vector3.zero,
    pitchDeg        = 0,
    yawDeg          = 0,
    speed           = 1,
    sens            = 0.25,
    savedCharCFrame = nil,
}

local fcRotTouch   = nil
local fcMoveTouch  = nil
local fcMoveSt     = nil
local fcRotLast    = nil
local fcJoy        = Vector2.zero
local DEAD_X       = 25
local DEAD_Y       = 20
local fcConns      = {}

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
            if not fcRotTouch then fcRotTouch = inp; fcRotLast = inp.Position end
        else
            if not fcMoveTouch then fcMoveTouch = inp; fcMoveSt = inp.Position end
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
        local spd  = FC.speed * 32 * dt
        local move = Vector3.zero
        local keys = FC._keys or {}
        if onMobile then
            move = cf.LookVector * (-fcJoy.Y) * spd + cf.RightVector * fcJoy.X * spd
        else
            if keys[Enum.KeyCode.W] then move = move + cf.LookVector  * spd end
            if keys[Enum.KeyCode.S] then move = move - cf.LookVector  * spd end
            if keys[Enum.KeyCode.D] then move = move + cf.RightVector * spd end
            if keys[Enum.KeyCode.A] then move = move - cf.RightVector * spd end
            if keys[Enum.KeyCode.E] then move = move + Vector3.new(0,1,0) * spd end
            if keys[Enum.KeyCode.Q] then move = move - Vector3.new(0,1,0) * spd end
        end
        FC.pos = FC.pos + move
        Cam.CFrame = CFrame.new(FC.pos)
            * CFrame.Angles(0, math.rad(FC.yawDeg), 0)
            * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local hrp = getRoot()
        local hum = getHum()
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
-- │              ➤  UI CONSTRUCTION                         │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("✦ XKID HUB — FINAL V.2 ✦", "star", "FREECAM", false)

-- ═══════════════════════════════════════════════════════════
-- TAB 1: TELEPORT
-- ═══════════════════════════════════════════════════════════
local T_TP = Win:Tab("Teleport", "map-pin")
local TPT  = T_TP:Page("Navigation", "map-pin"):Section("🎯 Smart Search", "Left")

TPT:TextBox("Ketik 2-3 Huruf Nama", "pText", "", function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🚀 Teleport Now", "Fast TP", function()
    local snippet = State.Teleport.selectedTarget
    if snippet == "" then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and (string.find(string.lower(p.Name), string.lower(snippet)) or string.find(string.lower(p.DisplayName), string.lower(snippet))) then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                getRoot().CFrame = p.Character.HumanoidRootPart.CFrame; return
            end
        end
    end
end)
local P_Drop = TPT:Dropdown("Manual List", "pDrop", getPNames(), function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🔄 Refresh List", "", function() P_Drop:Refresh(getPNames()) end)

local LocPage = T_TP:Page("Locations", "bookmark")
local TPP2    = LocPage:Section("💾 Save Location", "Left")
local TPP3    = LocPage:Section("📍 Load Location", "Right")
local SavedLocs = {}

for i = 1, 5 do
    local idx = i
    TPP2:Button("💾 Slot " .. idx, "Simpan posisi sini", function()
        local r = getRoot()
        if not r then Library:Notification("Location", "Karakter tidak ditemukan!", 2); return end
        SavedLocs[idx] = r.CFrame
        Library:Notification("✅ Saved", "Slot " .. idx .. " tersimpan!", 2)
    end)
end

for i = 1, 5 do
    local idx = i
    TPP3:Button("📍 Slot " .. idx, "Teleport ke slot", function()
        if not SavedLocs[idx] then Library:Notification("❌ Kosong", "Slot " .. idx .. " belum di-save!", 2); return end
        local r = getRoot()
        if not r then return end
        r.CFrame = SavedLocs[idx]
        Library:Notification("📍 Loaded", "Teleport ke Slot " .. idx, 2)
    end)
end

-- ═══════════════════════════════════════════════════════════
-- TAB 2: PLAYER
-- ═══════════════════════════════════════════════════════════
local T_PL   = Win:Tab("Player", "user")
local PLPage1 = T_PL:Page("Movement", "zap")
local PLM     = PLPage1:Section("⚡ Movement", "Left")
local PLH     = PLPage1:Section("🚀 Abilities", "Right")

PLM:Button("🔄 Refresh POV", "Reset kamera & karakter", function()
    local r = getRoot(); local h = getHum()
    if not r or not h then Library:Notification("Refresh", "❌ Karakter tidak ditemukan!", 2); return end
    Cam.CameraType = Enum.CameraType.Custom; task.wait(0.05)
    Cam.CameraType = Enum.CameraType.Scriptable; task.wait(0.05)
    Cam.CameraType = Enum.CameraType.Custom
    pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    Library:Notification("✅ Refresh", "POV & kamera sudah di-reset!", 2)
end)

PLM:Slider("🏃 WalkSpeed", "ws", 16, 500, 16, function(v)
    State.Move.ws = v
    if getHum() then getHum().WalkSpeed = v end
end)
PLM:Button("🔄 Reset Speed", "Kembali default 16", function()
    State.Move.ws = 16
    if getHum() then getHum().WalkSpeed = 16 end
    Library:Notification("Speed", "WalkSpeed: 16 (default)", 1)
end)

PLM:Slider("🦘 JumpPower", "jp", 50, 500, 50, function(v)
    State.Move.jp = v
    if getHum() then getHum().JumpPower = v end
end)
PLM:Button("🔄 Reset Jump", "Kembali default 50", function()
    State.Move.jp = 50
    if getHum() then getHum().JumpPower = 50 end
    Library:Notification("Jump", "JumpPower: 50 (default)", 1)
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

PLH:Toggle("✈️  Native Fly", "nf", false, "Freecam style", function(v) toggleFly(v) end)
PLH:Slider("✈️ Fly Speed", "flyspd", 10, 300, 60, function(v) State.Move.flyS = v end)
PLH:Toggle("👻 NoClip", "nc", false, "Tembus dinding", function(v) State.Move.ncp = v end)
PLH:Toggle("💥 IY Fling", "ffm", false, "Tabrak!", function(v) State.Fling.active = v; State.Move.ncp = v end)

-- God Mode
local godConn    = nil
local godRespawn = nil
local godLastPos = nil
PLH:Toggle("🛡️ God Mode", "god", false, "HP Infinite + Respawn", function(v)
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
        Library:Notification("God Mode", "🛡️ Aktif! HP Infinite + Auto Respawn", 3)
    else
        if godConn    then godConn:Disconnect();    godConn    = nil end
        if godRespawn then godRespawn:Disconnect(); godRespawn = nil end
        local hum = getHum()
        if hum then hum.MaxHealth = 100; hum.Health = 100 end
        Library:Notification("God Mode", "❌ Nonaktif", 2)
    end
end)

-- PAGE 2: LOCK (DENGAN FITUR UNLOCK SEMENTARA)
local PLPage2 = T_PL:Page("Lock", "lock")
local PLLock  = PLPage2:Section("🔒 Lock Karakter", "Left")
local PLLockR = PLPage2:Section("📷 Lock Kamera", "Right")

local lockRotConn = nil
local lockedYaw = 0
local tempUnlock = false

PLLock:Toggle("🔒 Lock Rotasi", "lockrot", false, "Karakter tidak berputar", function(v)
    if v then
        local hrp = getRoot()
        if not hrp then Library:Notification("Lock", "❌ Karakter tidak ditemukan!", 2); return end
        local _, ry, _ = hrp.CFrame:ToEulerAnglesYXZ()
        lockedYaw = ry
        lockRotConn = RS.Heartbeat:Connect(function()
            local r = getRoot()
            if r and not tempUnlock then
                r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, lockedYaw, 0)
            end
        end)
        Library:Notification("Lock", "🔒 Rotasi dikunci!", 2)
    else
        if lockRotConn then lockRotConn:Disconnect(); lockRotConn = nil end
        Library:Notification("Lock", "🔓 Rotasi bebas", 2)
    end
end)

PLLock:Button("🔓 UNLOCK SEMENTARA (Tekan buat muter)", "Sementara buka lock", function()
    tempUnlock = true
    task.wait(0.5)
    tempUnlock = false
    Library:Notification("Lock", "🔓 Unlock 0.5 detik, sekarang lock lagi!", 1)
end)

PLLock:Button("📌 Simpan Arah Lock Sekarang", "Update arah kunci", function()
    local hrp = getRoot()
    if hrp then
        local _, ry, _ = hrp.CFrame:ToEulerAnglesYXZ()
        lockedYaw = ry
        Library:Notification("Lock", "📌 Arah lock di-update!", 2)
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
            if r and lockedCF then r.CFrame = lockedCF end
        end)
        Library:Notification("Lock", "📍 Posisi dikunci!", 2)
    else
        if lockPosConn then lockPosConn:Disconnect(); lockPosConn = nil end
        local hrp = getRoot()
        if hrp then hrp.Anchored = false end
        Library:Notification("Lock", "🔓 Posisi bebas", 2)
    end
end)
PLLock:Button("📌 Update Posisi Kunci", "Kunci di posisi baru", function()
    local hrp = getRoot()
    if hrp then lockedCF = hrp.CFrame; Library:Notification("Lock", "📌 Posisi baru dikunci!", 2) end
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
            local camPos  = hrp.Position + CFrame.Angles(0, ry, 0) * Vector3.new(0, 2, lockCamDist)
            local focusPos= hrp.Position + Vector3.new(0, 1, 0)
            Cam.CFrame = CFrame.new(camPos, focusPos)
        end)
        Library:Notification("Kamera", "📷 Kamera dikunci ke karakter!", 2)
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
local PLW     = PLPage3:Section("🌦️ Waktu & Cahaya", "Left")
PLW:Slider("Waktu (ClockTime)", "time", 0, 24, 12, function(v) Lighting.ClockTime = v end)
PLW:Button("☀️ Set Siang", "", function() Lighting.ClockTime = 14 end)
PLW:Button("🌙 Set Malam", "", function() Lighting.ClockTime = 0 end)

-- ═══════════════════════════════════════════════════════════
-- TAB 3: CINEMATIC
-- ═══════════════════════════════════════════════════════════
local T_CI   = Win:Tab("Cinematic", "video")
local CIPage1 = T_CI:Page("Freecam", "video")
local CIM     = CIPage1:Section("🎬 Freecam", "Left")
local CIW     = CIPage1:Section("📱 Display", "Right")

local fcInvisSaved = {}
CIM:Toggle("🎬 Freecam ON/OFF", "fc", false, "Kiri=Gerak | Kanan=Rotate", function(v)
    FC.active = v; State.Cinema.active = v
    if v then
        local cf = Cam.CFrame
        FC.pos = cf.Position
        local rx, ry = cf:ToEulerAnglesYXZ()
        FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry)
        FC._keys = {}; FC._mouseRotate = false
        local hrp = getRoot(); local hum = getHum()
        if hrp then FC.savedCharCFrame = hrp.CFrame; hrp.Anchored = true end
        if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum:ChangeState(Enum.HumanoidStateType.Physics) end
        fcInvisSaved = {}
        local char = LP.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then fcInvisSaved[part] = part.Transparency; part.Transparency = 1 end
            end
        end
        startFCCapture(); startFCLoop()
        Library:Notification("Freecam", "ON — Kiri gerak | Kanan rotate", 3)
    else
        stopFCLoop(); stopFCCapture()
        for part, t in pairs(fcInvisSaved) do if part and part.Parent then part.Transparency = t end end
        fcInvisSaved = {}
        local hrp = getRoot(); local hum = getHum()
        if hrp then
            hrp.Anchored = false
            if FC.savedCharCFrame then hrp.CFrame = FC.savedCharCFrame; FC.savedCharCFrame = nil end
        end
        if hum then
            hum.WalkSpeed = State.Move.ws; hum.JumpPower = State.Move.jp
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        Cam.FieldOfView = 70; Cam.CameraType = Enum.CameraType.Custom
        Library:Notification("Freecam", "OFF — Balik ke posisi karakter", 3)
    end
end)

CIM:Slider("⚡ FC Speed", "fcspd", 1, 30, 1, function(v) FC.speed = v end)
CIM:Slider("🎯 FC Sensitivity", "fcsens", 1, 20, 5, function(v) FC.sens = v * 0.05 end)
CIM:Slider("🔍 FOV", "fcfov", 10, 120, 70, function(v) Cam.FieldOfView = v end)
CIM:Button("🔄 Reset FOV", "FOV normal 70", function()
    Cam.FieldOfView = 70; Library:Notification("Freecam", "FOV: 70 (Normal)", 1)
end)

CIW:Button("📱 Portrait",  "Tegak",    function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end)
CIW:Button("📺 Landscape", "Mendatar", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end)

-- PAGE 2: CINEMATIC PRESETS
local CIPage2 = T_CI:Page("Presets", "film")
local CIPre   = CIPage2:Section("🎬 Preset Sinematik", "Left")
local CIFine  = CIPage2:Section("🎛️ Fine-Tune", "Right")

local function applyPreset(fov, speed, clock, bright, fogEnd, fogR, fogG, fogB, ambR, ambG, ambB, density, offset, glare, halo, gfxLevel)
    Cam.FieldOfView = fov; FC.speed = speed
    Lighting.ClockTime  = clock; Lighting.Brightness = bright; Lighting.FogEnd = fogEnd
    Lighting.FogColor   = Color3.fromRGB(fogR, fogG, fogB)
    Lighting.Ambient    = Color3.fromRGB(ambR, ambG, ambB)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Density = density; atm.Offset = offset; atm.Glare = glare; atm.Halo = halo
    pcall(function() settings().Rendering.QualityLevel = gfxLevel end)
end

CIPre:Button("☀️  Cinematic Day", "Film siang hari cerah", function()
    applyPreset(50, 3, 14, 2, 10000, 200,220,255, 120,120,120, 0.05, 0.1, 0.3, 0.2, Enum.QualityLevel.Level10)
    Library:Notification("🎬 Preset", "☀️ Cinematic Day", 3)
end)
CIPre:Button("🌆  Golden Hour", "Sore sinematik hangat", function()
    applyPreset(55, 3, 18, 1.5, 4000, 255,180,100, 180,100,60, 0.2, 0.3, 0.8, 0.5, Enum.QualityLevel.Level10)
    Library:Notification("🎬 Preset", "🌆 Golden Hour", 3)
end)
CIPre:Button("🌃  Night Cinematic", "Drama malam gelap", function()
    applyPreset(45, 2, 0, 0.3, 20000, 10,10,30, 20,20,40, 0.02, 0.0, 0.0, 0.1, Enum.QualityLevel.Level10)
    Library:Notification("🎬 Preset", "🌃 Night Cinematic", 3)
end)
CIPre:Button("🌫️  Fog Drama", "Kabut misterius", function()
    applyPreset(55, 2, 12, 0.8, 300, 200,200,200, 150,150,150, 0.6, 0.5, 0.0, 0.1, Enum.QualityLevel.Level08)
    Library:Notification("🎬 Preset", "🌫️ Fog Drama", 3)
end)
CIPre:Button("❄️  Snow Scene", "Salju bersih putih", function()
    applyPreset(50, 2, 10, 1.2, 500, 220,230,255, 180,190,210, 0.4, 0.4, 0.0, 0.3, Enum.QualityLevel.Level10)
    Library:Notification("🎬 Preset", "❄️ Snow Scene", 3)
end)
CIPre:Button("🎭  Dark Thriller", "Gelap intens dramatis", function()
    applyPreset(40, 2, 12, 0.1, 200, 40,40,50, 30,30,40, 0.8, 0.1, 0.0, 0.0, Enum.QualityLevel.Level08)
    Library:Notification("🎬 Preset", "🎭 Dark Thriller", 3)
end)
CIPre:Button("📺  Vlog Style", "Casual natural cerah", function()
    applyPreset(75, 5, 14, 1.5, 8000, 210,225,255, 110,110,110, 0.1, 0.1, 0.1, 0.15, Enum.QualityLevel.Level05)
    Library:Notification("🎬 Preset", "📺 Vlog Style", 3)
end)
CIPre:Button("🔄  Reset Semua", "Kembalikan default", function()
    applyPreset(70, 5, 14, 1, 100000, 191,191,191, 70,70,70, 0.35, 0.0, 0.0, 0.25, Enum.QualityLevel.Level05)
    Library:Notification("🎬 Preset", "🔄 Reset Default", 2)
end)

CIFine:Slider("☀️ Brightness", "ftbright", 0, 50, 10, function(v)
    Lighting.Brightness = v * 0.1
end)
CIFine:Slider("🕐 ClockTime", "ftclock", 0, 24, 14, function(v)
    Lighting.ClockTime = v
end)
CIFine:Slider("🌫️ Fog Density", "ftdensity", 0, 20, 7, function(v)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Density = v * 0.05
end)
CIFine:Slider("✨ Glare", "ftglare", 0, 20, 0, function(v)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Glare = v * 0.05
end)
CIFine:Slider("📊 Grafik Level", "ftgfx", 1, 10, 5, function(v)
    pcall(function() settings().Rendering.QualityLevel = v end)
end)

-- ═══════════════════════════════════════════════════════════
-- TAB 4: SPECTATE
-- ═══════════════════════════════════════════════════════════
local T_SP = Win:Tab("Spectate", "eye")
local SPP  = T_SP:Page("Viewer", "eye")
local SPS  = SPP:Section("👁️ Spectate Player", "Left")
local SPF  = SPP:Section("🔍 FOV Zoom", "Right")

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

local Spec = {active=false, target=nil, mode="third", dist=8, origFov=70, orbitYaw=0, orbitPitch=0, fpYaw=0, fpPitch=0}
local specTouchMain  = nil; local specTouchPinch = {}; local specPinchDist = nil
local specPanDelta   = Vector2.zero; local specConns = {}

local function startSpecCapture()
    table.insert(specConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or not Spec.active then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inJoystickArea(inp.Position) then return end
        table.insert(specTouchPinch, inp)
        if #specTouchPinch == 1 then specTouchMain = inp
        else specTouchMain = nil end
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
            local head = char:FindFirstChild("Head")
            local origin = head and head.Position or hrp.Position + Vector3.new(0, 1.5, 0)
            Spec.fpYaw   = Spec.fpYaw   - pan.X * sens
            Spec.fpPitch = math.clamp(Spec.fpPitch - pan.Y * sens, -85, 85)
            Cam.CFrame = CFrame.new(origin)
                * CFrame.Angles(0, math.rad(Spec.fpYaw), 0)
                * CFrame.Angles(math.rad(Spec.fpPitch), 0, 0)
        end
    end)
end

local function stopSpecLoop()
    RS:UnbindFromRenderStep("XKIDSpec")
end

local specDrop = SPS:Dropdown("Pilih Target", "spDrop", getDisplayNames(), function(v)
    local p = findPlayerByDisplay(v)
    if p then
        Spec.target = p
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ()
            Spec.orbitYaw = math.deg(ry); Spec.orbitPitch = 20
            Spec.fpYaw    = math.deg(ry); Spec.fpPitch = 0
        end
    end
end)
SPS:Button("🔄 Refresh", "", function()
    Spec.target = nil; specDrop:Refresh(getDisplayNames()); Library:Notification("Spectate", "List diperbarui!", 2)
end)
SPS:Toggle("👁️ Spectate ON/OFF", "spec", false, "Nonton target", function(v)
    Spec.active = v
    if v then
        if not Spec.target then Library:Notification("Spectate", "Pilih target dulu!", 3); Spec.active = false; return end
        Spec.origFov = Cam.FieldOfView; startSpecCapture(); startSpecLoop()
        Library:Notification("Spectate", "Nonton: " .. Spec.target.DisplayName, 3)
    else
        stopSpecLoop(); stopSpecCapture()
        Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov
        Library:Notification("Spectate", "Spectate off!", 2)
    end
end)
SPS:Toggle("🎥 First Person", "specfp", false, "ON=FP Drone | OFF=Orbit", function(v)
    Spec.mode = v and "first" or "third"
    if v and Spec.target and Spec.target.Character then
        local _, ry, _ = Cam.CFrame:ToEulerAnglesYXZ()
        local rx = math.asin(Cam.CFrame.LookVector.Y)
        Spec.fpYaw = math.deg(ry); Spec.fpPitch = math.deg(rx)
    end
end)

SPS:Slider("Jarak Orbit", "specdist", 3, 30, 8, function(v) Spec.dist = v end)
SPF:Slider("🔍 FOV Zoom", "specfov", 10, 120, 70, function(v) Cam.FieldOfView = v end)
SPF:Button("👁️ Reset FOV Normal (70)", "", function()
    Cam.FieldOfView = 70; Library:Notification("FOV", "FOV: 70 (Normal)", 1)
end)

-- ═══════════════════════════════════════════════════════════
-- TAB 5: WORLD
-- ═══════════════════════════════════════════════════════════
local T_WO = Win:Tab("World", "globe")
local WOP1 = T_WO:Page("Weather", "cloud")
local WOW  = WOP1:Section("🌤️ Preset Cuaca", "Left")
local WOA  = WOP1:Section("🌈 Atmosphere", "Right")

local function getAtmos()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atm then atm = Instance.new("Atmosphere", Lighting) end
    return atm
end
local function setWeather(clock, bright, fogStart, fogEnd, fogR, fogG, fogB, ambR, ambG, ambB, density, offset, glare, halo)
    Lighting.ClockTime = clock; Lighting.Brightness = bright
    Lighting.FogStart  = fogStart; Lighting.FogEnd = fogEnd
    Lighting.FogColor  = Color3.fromRGB(fogR, fogG, fogB)
    Lighting.Ambient   = Color3.fromRGB(ambR, ambG, ambB)
    local atm = getAtmos()
    atm.Density = density; atm.Offset = offset; atm.Glare = glare; atm.Halo = halo
end

WOW:Button("☀️ Cerah",               "Siang terang",   function() setWeather(14,2,1000,10000,200,220,255,120,120,120,0.05,0.1,0.3,0.2);   Library:Notification("Weather","☀️ Cerah!",2) end)
WOW:Button("🌅 Sunset / Golden Hour","Sore hari",       function() setWeather(18,1.5,500,4000,255,180,100,180,100,60,0.2,0.3,0.8,0.5);    Library:Notification("Weather","🌅 Golden Hour!",2) end)
WOW:Button("🌃 Malam Bintang",       "Malam cerah",     function() setWeather(0,0.3,2000,20000,10,10,30,20,20,40,0.02,0.0,0.0,0.1);       Library:Notification("Weather","🌃 Malam Bintang!",2) end)
WOW:Button("🌫️ Berkabut",            "Kabut tebal",     function() setWeather(12,0.8,20,300,200,200,200,150,150,150,0.6,0.5,0.0,0.1);     Library:Notification("Weather","🌫️ Berkabut!",2) end)
WOW:Button("🌧️ Mendung Gelap",       "Awan gelap",      function() setWeather(12,0.4,100,800,80,80,100,60,60,80,0.5,0.2,0.0,0.0);         Library:Notification("Weather","🌧️ Mendung Gelap!",2) end)
WOW:Button("❄️ Salju",               "Putih bersih",    function() setWeather(10,1.2,50,500,220,230,255,180,190,210,0.4,0.4,0.0,0.3);     Library:Notification("Weather","❄️ Salju!",2) end)
WOW:Button("🌪️ Badai",               "Gelap & berat",   function() setWeather(12,0.1,30,200,40,40,50,30,30,40,0.8,0.1,0.0,0.0);           Library:Notification("Weather","🌪️ Badai!",2) end)
WOW:Button("🔄 Reset Default",       "Kembalikan normal",function() setWeather(14,1,0,100000,191,191,191,70,70,70,0.35,0.0,0.0,0.25);     Library:Notification("Weather","🔄 Reset!",2) end)

WOA:Slider("🕐 ClockTime",    "wtime",   0,  24,   14, function(v) Lighting.ClockTime  = v end)
WOA:Slider("☀️ Brightness",   "wbright", 0,  50,   10, function(v) Lighting.Brightness = v * 0.1 end)
WOA:Slider("🌫️ Fog Jarak",    "wfog",    0,  5000, 100000, function(v) Lighting.FogEnd = v end)
WOA:Slider("💨 Density",      "wdens",   0,  20,   0,  function(v) getAtmos().Density  = v * 0.05 end)
WOA:Slider("🌅 Offset (Haze)","woffset", 0,  20,   0,  function(v) getAtmos().Offset   = v * 0.05 end)
WOA:Slider("✨ Glare",        "wglare",  0,  20,   0,  function(v) getAtmos().Glare    = v * 0.05 end)
WOA:Slider("🌟 Halo",         "whalo",   0,  20,   0,  function(v) getAtmos().Halo     = v * 0.05 end)

-- PAGE 2: GRAPHICS
local WOP2  = T_WO:Page("Graphics", "monitor")
local WOG   = WOP2:Section("📱 Mode Grafik", "Left")
local WOGF  = WOP2:Section("⚙️ Level Manual", "Right")

local function setGfx(level)
    local ok = pcall(function() settings().Rendering.QualityLevel = level end)
    if not ok then pcall(function() UserSettings():GetService("UserGameSettings").SavedQualityLevel = level end) end
end

WOG:Button("🥔 Potato (Level 1)",         "Paling hemat",          function() setGfx(Enum.QualityLevel.Level01); Library:Notification("Graphics","🥔 Potato — Level 1",2) end)
WOG:Button("📉 Low (Level 3)",            "Ringan",                function() setGfx(Enum.QualityLevel.Level03); Library:Notification("Graphics","📉 Low — Level 3",2) end)
WOG:Button("📊 Medium (Level 5)",         "Seimbang",              function() setGfx(Enum.QualityLevel.Level05); Library:Notification("Graphics","📊 Medium — Level 5",2) end)
WOG:Button("📈 High (Level 8)",           "Bagus",                 function() setGfx(Enum.QualityLevel.Level08); Library:Notification("Graphics","📈 High — Level 8",2) end)
WOG:Button("💎 Ultra (Level 10)",         "Maksimal",              function() setGfx(Enum.QualityLevel.Level10); Library:Notification("Graphics","💎 Ultra — Level 10",2) end)
WOG:Button("🎬 Cinematic (Ultra+Atmos)",  "Terbaik untuk rekam",   function()
    setGfx(Enum.QualityLevel.Level10)
    setWeather(14,2,1000,10000,200,220,255,120,120,120,0.05,0.1,0.3,0.2)
    Library:Notification("Graphics","🎬 Cinematic Mode!",3)
end)

WOGF:Slider("📊 Level Grafik", "gfxlvl", 1, 10, 5, function(v)
    pcall(function() settings().Rendering.QualityLevel = v end)
    Library:Notification("Graphics", "Level: " .. v, 1)
end)
WOGF:Button("🔄 Cek Level Sekarang", "", function()
    local cur = settings().Rendering.QualityLevel.Value
    Library:Notification("Graphics", "Level Sekarang: " .. cur, 3)
end)

-- ═══════════════════════════════════════════════════════════
-- TAB 6: SECURITY (DENGAN RESET KARAKTER LANGSUNG)
-- ═══════════════════════════════════════════════════════════
local T_SC  = Win:Tab("Security", "shield")
local SCPage= T_SC:Page("Guard", "shield")
local SCP   = SCPage:Section("🛡️ Protection", "Left")
local SCR   = SCPage:Section("💀 Reset Karakter", "Right")

-- Simpan posisi terakhir otomatis
local lastPosReset = nil
RS.Heartbeat:Connect(function()
    local r = getRoot()
    if r then lastPosReset = r.CFrame end
end)

-- Anti-AFK
SCP:Toggle("Anti-AFK", "afk", false, "", function(v)
    if v then
        State.Security.afkConn = LP.Idled:Connect(function()
            VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn = nil end
    end
end)

SCP:Button("🔄 Rejoin Server", "", function()
    TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end)

-- Tombol reset: langsung matiin karakter, respawn, balik ke posisi
SCR:Button("💀 RESET KARAKTER (Kembali ke posisi)", "", function()
    local savedPos = lastPosReset
    if not savedPos then
        local r = getRoot()
        if r then savedPos = r.CFrame end
    end
    if not savedPos then
        Library:Notification("Reset", "❌ Gak ada posisi yang tersimpan!", 2)
        return
    end

    local targetPos = savedPos

    LP.CharacterAdded:Wait()
    LP:LoadCharacter()

    task.wait(0.1)
    local char = LP.Character
    if not char then
        char = LP.CharacterAdded:Wait()
    end

    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then animator:Destroy() end
        for _, track in pairs(hum:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
        hum.PlatformStand = true
    end

    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.05)
    if hrp then
        hrp.CFrame = targetPos
    end

    task.wait(0.1)
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    Library:Notification("💀 Reset", "Karakter di-reset, balik ke posisi!", 2)
end)

-- Tombol tambahan: cuma balik posisi (tanpa reset)
SCR:Button("📍 TELEPORT KE POSISI TERAKHIR", "", function()
    local r = getRoot()
    if not r then
        Library:Notification("Posisi", "❌ Karakter gak ditemukan!", 2)
        return
    end
    if not lastPosReset then
        Library:Notification("Posisi", "❌ Belum ada posisi tersimpan!", 2)
        return
    end
    r.CFrame = lastPosReset
    Library:Notification("📍 Posisi", "Balik ke posisi terakhir!", 2)
end)

-- ═══════════════════════════════════════════════════════════
-- BACKGROUND LOOPS
-- ═══════════════════════════════════════════════════════════

-- IY FLING LOOP
task.spawn(function()
    while true do
        if State.Fling.active and getRoot() then
            local r = getRoot()
            local ok = pcall(function()
                r.AssemblyAngularVelocity = Vector3.new(0, State.Fling.power, 0)
                r.AssemblyLinearVelocity  = Vector3.new(State.Fling.power, State.Fling.power, State.Fling.power)
            end)
            if not ok then
                pcall(function()
                    r.RotVelocity = Vector3.new(0, State.Fling.power, 0)
                    r.Velocity    = Vector3.new(State.Fling.power, State.Fling.power, State.Fling.power)
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
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

Library:Notification("✦ XKID HUB", "FINAL V.2 — Ready! Let's Go! 🚀", 5)