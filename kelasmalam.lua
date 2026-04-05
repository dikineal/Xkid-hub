--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v27.0  💠              ║
║                GHOST DRONE & FULL FEATURES LOCK          ║
╚═══════════════════════════════════════════════════════════╣
║  ➤  Fixed: Drone Movement (No Anchor - Joystick Active)   ║
║  ➤  Fixed: Drone Mode = Ghost Mode (Auto-Invis & Return)  ║
║  ➤  Stable: Smart TP, Fly, Bypass, IY Fling Locked        ║
║  ➤  Stable: Weather Control & Rejoin Locked               ║
╚═══════════════════════════════════════════════════════════╝
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

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ➤  FLY ENGINE (LOCKED)                  │
-- └─────────────────────────────────────────────────────────┘
local function toggleFly(v)
    if not v then
        State.Fly.active = false
        if State.Fly.bv then State.Fly.bv:Destroy() end
        if State.Fly.bg then State.Fly.bg:Destroy() end
        if getHum() then getHum().PlatformStand = false; getHum():ChangeState(1); getHum().WalkSpeed = State.Move.ws end
        return
    end
    State.Fly.active = true; getHum().PlatformStand = true
    local r = getRoot()
    State.Fly.bv = Instance.new("BodyVelocity", r); State.Fly.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    State.Fly.bg = Instance.new("BodyGyro", r); State.Fly.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); State.Fly.bg.P = 1e5
    task.spawn(function()
        while State.Fly.active do
            local cam = workspace.CurrentCamera; local md = getHum().MoveDirection
            if md.Magnitude > 0 then
                local dot = md:Dot(cam.CFrame.LookVector * Vector3.new(1,0,1).Unit)
                State.Fly.bv.Velocity = Vector3.new(md.X * State.Move.flyS, cam.CFrame.LookVector.Y * State.Move.flyS * dot, md.Z * State.Move.flyS)
            else State.Fly.bv.Velocity = Vector3.zero end
            State.Fly.bg.CFrame = cam.CFrame; RS.RenderStepped:Wait()
        end
    end)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │        ➤  GHOST DRONE ENGINE (FREECAM PORT)             │
-- └─────────────────────────────────────────────────────────┘

-- Spring class (ported dari Freecam original)
local Spring = {}
Spring.__index = Spring
function Spring.new(freq, val)
    return setmetatable({F = freq, P = val, V = val * 0}, Spring)
end
function Spring:Update(dt, target)
    local w  = self.F * 2 * math.pi
    local dX = target - self.P
    local eW = math.exp(-w * dt)
    local np = target + (self.V * dt - dX * (w * dt + 1)) * eW
    self.V   = (w * dt * (dX * w - self.V) + self.V) * eW
    self.P   = np
    return np
end
function Spring:Reset(val)
    self.P = val
    self.V = val * 0
end

-- Deadzone helper (sama persis logic Freecam)
local function deadzone(x)
    local s  = math.sign(x)
    local v  = (math.abs(x) - 0.15) / 0.85 * 2
    return s * math.clamp((math.exp(v) - 1) / (math.exp(2) - 1), 0, 1)
end

-- State drone internal
local FC = {
    pos    = Vector3.zero,   -- posisi kamera drone
    angles = Vector2.zero,   -- (pitch, yaw) dalam radian
    fov    = 70,             -- fov saat ini
    speedMul = 1,            -- speed multiplier (Up/Down arrow)
    slow   = false,          -- shift = slow mode 0.25x
}

-- Spring instances: posisi (Vec3), pan (Vec2), fov delta (number)
local spPos = Spring.new(1.5, Vector3.zero)
local spPan = Spring.new(1,   Vector2.zero)
local spFov = Spring.new(4,   0)

-- Input accumulator
local panDelta   = Vector2.zero   -- mouse / touch rotate
local fovDelta   = 0              -- scroll / pinch zoom
local moveKeys   = {w=0,a=0,s=0,d=0,e=0,q=0}  -- keyboard WASD+EQ

-- Touch state (joystick kiri = gerak, satu jari kanan = pan, dua jari = pinch)
local touchMain   = nil   -- objek touch untuk pan (di luar joystick)
local touchPinch  = {}    -- tabel touch untuk pinch
local pinchDist   = nil

-- Cek apakah posisi touch ada di area joystick
local function inJoystickArea(pos)
    local ctrl = LP and LP.PlayerGui and LP.PlayerGui:FindFirstChild("TouchGui")
    if ctrl then
        local frame = ctrl:FindFirstChild("TouchControlFrame")
        local thumb  = frame and frame:FindFirstChild("DynamicThumbstickFrame")
        if thumb then
            local ap = thumb.AbsolutePosition
            local as = thumb.AbsoluteSize
            if pos.X >= ap.X and pos.Y >= ap.Y and pos.X <= ap.X + as.X and pos.Y <= ap.Y + as.Y then
                return true
            end
        end
    end
    return false
end

-- Koneksi input — hanya aktif saat drone nyala
local droneConns = {}

local function startDroneCapture()
    -- Keyboard: WASD gerak, E naik, Q turun, Shift = slow
    table.insert(droneConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode.Name
        if moveKeys[string.lower(k)] ~= nil then moveKeys[string.lower(k)] = 1 end
        if k == "LeftShift" or k == "RightShift" then FC.slow = true end
        if k == "Up"   then FC.speedMul = math.clamp(FC.speedMul + 0.25, 0.25, 4) end
        if k == "Down" then FC.speedMul = math.clamp(FC.speedMul - 0.25, 0.25, 4) end
    end))
    table.insert(droneConns, UIS.InputEnded:Connect(function(inp)
        local k = inp.KeyCode.Name
        if moveKeys[string.lower(k)] ~= nil then moveKeys[string.lower(k)] = 0 end
        if k == "LeftShift" or k == "RightShift" then FC.slow = false end
    end))

    -- Mouse: klik kanan + gerak = pan; scroll = zoom
    table.insert(droneConns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                -- sensitivitas dinamis sesuai FOV (makin sempit = makin lambat)
                local sens = Vector2.new(0.75, 1) * 8
                local fovScale = math.sqrt(0.7002 / math.tan(math.rad(FC.fov / 2)))
                panDelta = panDelta + Vector2.new(-inp.Delta.Y, -inp.Delta.X)
                    * sens * 0.04908 * (1 / fovScale)
            end
        elseif inp.UserInputType == Enum.UserInputType.MouseWheel then
            fovDelta = fovDelta + (-inp.Position.Z)
        end
    end))

    -- Touch: satu jari (bukan joystick) = pan; dua jari = pinch zoom
    table.insert(droneConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if not touchMain and not inJoystickArea(inp.Position) then
            touchMain = inp
        else
            table.insert(touchPinch, inp)
        end
    end))
    table.insert(droneConns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        -- Pan dari touch utama
        if inp == touchMain then
            local fovScale = math.sqrt(0.7002 / math.tan(math.rad(FC.fov / 2)))
            panDelta = panDelta + Vector2.new(-inp.Delta.Y, -inp.Delta.X)
                * 0.19635 * (1 / fovScale)
        end
        -- Pinch zoom dari dua jari
        if #touchPinch >= 2 then
            local d = (touchPinch[1].Position - touchPinch[2].Position).Magnitude
            if pinchDist then
                fovDelta = fovDelta + -(d - pinchDist) * 0.04
            end
            pinchDist = d
        end
    end))
    table.insert(droneConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == touchMain then touchMain = nil end
        for i, v in ipairs(touchPinch) do
            if v == inp then table.remove(touchPinch, i); break end
        end
        if #touchPinch < 2 then pinchDist = nil end
    end))
end

local function stopDroneCapture()
    for _, c in ipairs(droneConns) do c:Disconnect() end
    droneConns = {}
    panDelta  = Vector2.zero
    fovDelta  = 0
    moveKeys  = {w=0,a=0,s=0,d=0,e=0,q=0}
    FC.slow   = false
    FC.speedMul = 1
    touchMain = nil
    touchPinch = {}
    pinchDist = nil
end

-- Render loop drone (hanya aktif saat Cinema.active)
local droneLoop = nil

local function startDroneLoop()
    droneLoop = RS:BindToRenderStep("XKIDDrone", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not State.Cinema.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable

        -- ── FOV ───────────────────────────────────────────────
        local fovScale = math.sqrt(0.7002 / math.tan(math.rad(FC.fov / 2)))
        local fovTarget = spFov:Update(dt, fovDelta)
        fovDelta = 0
        FC.fov = math.clamp(FC.fov + fovTarget * 300 * (dt / fovScale), 1, 120)
        Cam.FieldOfView = FC.fov

        -- ── PAN (rotasi kamera) ────────────────────────────────
        local panTarget = spPan:Update(dt, panDelta)
        panDelta = Vector2.zero
        FC.angles = FC.angles + panTarget * (dt / fovScale)
        -- Clamp pitch, wrap yaw
        FC.angles = Vector2.new(
            math.clamp(FC.angles.X, -math.pi / 2 + 0.001, math.pi / 2 - 0.001),
            FC.angles.Y % (2 * math.pi)
        )

        -- ── VELOCITY (gerak drone) ─────────────────────────────
        -- Keyboard
        local kbVel = Vector3.new(
            moveKeys.d - moveKeys.a,
            moveKeys.e - moveKeys.q,
            moveKeys.s - moveKeys.w
        )
        -- Joystick (touch/mobile)
        local md = getHum() and getHum().MoveDirection or Vector3.zero
        local touchVel = Vector3.new(deadzone(md.X), 0, deadzone(-md.Z))
        -- Gabung: prioritas keyboard, fallback touch
        local rawVel = kbVel.Magnitude > 0 and kbVel or touchVel
        -- Terapkan spring + speed
        local baseSpeed = State.Cinema.speed * 64  -- skala sama dg Freecam (64 studs/s base)
        local velTarget = spPos:Update(dt, rawVel) * (FC.speedMul * (FC.slow and 0.25 or 1))

        -- Konversi ke arah kamera (pitch + yaw)
        local camOri = CFrame.fromOrientation(FC.angles.X, FC.angles.Y, 0)
        local worldVel = camOri * Vector3.new(velTarget.X, velTarget.Y, velTarget.Z)
        FC.pos = FC.pos + worldVel * baseSpeed * dt

        -- ── TERAPKAN KE KAMERA ────────────────────────────────
        local cf = CFrame.new(FC.pos) * CFrame.fromOrientation(FC.angles.X, FC.angles.Y, 0)
        Cam.CFrame = cf

        -- ── SEMBUNYIKAN BADAN ─────────────────────────────────
        if getRoot() then
            getRoot().CFrame = CFrame.new(FC.pos.X, -9999, FC.pos.Z)
        end
    end)
end

local function stopDroneLoop()
    RS:UnbindFromRenderStep("XKIDDrone")
    droneLoop = nil
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB V27", "star", "GHOST DRONE", false)

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
                getRoot().CFrame = p.Character.HumanoidRootPart.CFrame
                return
            end
        end
    end
end)
local P_Drop = TPT:Dropdown("Manual List", "pDrop", getPNames(), function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🔄 Refresh List", "", function() P_Drop:Refresh(getPNames()) end)

-- --- TAB 2: PLAYER ---
local T_PL = Win:Tab("Player", "user")
local PLP = T_PL:Page("Settings", "zap")
local PLM = PLP:Section("⚡ Movement", "Left")
local PLH = PLP:Section("🚀 Hacks", "Right")
local PLW = PLP:Section("🌦️ Atmosphere", "Left")

PLM:Button("🔄 Refresh (;re)", "", function() 
    local cf = getRoot().CFrame; getHum().Health = 0
    LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = cf
end)
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end)
PLM:Toggle("Inf Jump", "ij", false, "", function(v) 
    if v then State.Move.infJ = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if State.Move.infJ then State.Move.infJ:Disconnect() end end
end)

PLH:Toggle("Native Fly", "nf", false, "Joystick", function(v) toggleFly(v) end)
PLH:Toggle("NoClip", "nc", false, "", function(v) State.Move.ncp = v end)
PLH:Toggle("Invisible (R15)", "inv", false, "", function(v) 
    if v and LP.Character:FindFirstChild("LowerTorso") then LP.Character.LowerTorso:Destroy() end 
end)
PLH:Toggle("IY Fling Mode", "ffm", false, "Tabrak!", function(v) State.Fling.active = v; State.Move.ncp = v end)

PLW:Slider("Waktu (ClockTime)", "time", 0, 24, 12, function(v) Lighting.ClockTime = v end)
PLW:Button("☀️ Set Siang", "", function() Lighting.ClockTime = 14 end)
PLW:Button("🌙 Set Malam", "", function() Lighting.ClockTime = 0 end)

-- --- TAB 3: CINEMATIC ---
local T_CI = Win:Tab("Cinematic", "video")
local CIM = T_CI:Page("Drone", "video"):Section("🎬 Drone Mode", "Left")
local CIW = T_CI:Page("Drone", "video"):Section("📱 Orientation", "Right")

CIM:Toggle("Ghost Drone", "fc", false, "Auto-Invis & Return", function(v)
    State.Cinema.active = v
    if v then
        State.Cinema.lastPos = getRoot().CFrame

        -- Ambil posisi & sudut dari kamera sekarang (tidak lompat)
        local cf = Cam.CFrame
        local rx, ry = cf:ToEulerAnglesYXZ()
        FC.pos    = cf.Position
        FC.angles = Vector2.new(rx, ry)
        FC.fov    = Cam.FieldOfView
        FC.speedMul = 1
        FC.slow   = false

        -- Reset spring ke zero (bukan ke posisi, karena spring mengukur delta kecepatan)
        spPos:Reset(Vector3.zero)
        spPan:Reset(Vector2.zero)
        spFov:Reset(0)

        if getHum() then getHum().WalkSpeed = 0 end
        startDroneCapture()
        startDroneLoop()
    else
        stopDroneLoop()
        stopDroneCapture()

        -- KEMBALIKAN BADAN KE POSISI KAMERA
        if getRoot() then getRoot().CFrame = Cam.CFrame end
        if getHum() then getHum().WalkSpeed = State.Move.ws end
        Cam.FieldOfView = 70
        Cam.CameraType = Enum.CameraType.Custom
        Library:Notification("Drone", "Badan lo udah balik ke posisi kamera!", 3)
    end
end)
CIM:Slider("Drone Speed", "csc", 0.1, 5, 1, function(v) State.Cinema.speed = v end)
CIM:Slider("Zoom (FOV)", "cfov", 10, 120, 70, function(v) Cam.FieldOfView = v end)

CIW:Button("📱 Portrait", "Tegak", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end)
CIW:Button("📺 Landscape", "Mendatar", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end)

-- --- TAB 4: SECURITY ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")

SCP:Toggle("Bypass Anti-Cheat", "acb", false, "WS/JP Hook", function(v)
    if v then 
        local mt = getrawmetatable(game); setreadonly(mt, false); local old = mt.__index
        mt.__index = newcclosure(function(t, k)
            if not checkcaller() and t:IsA("Humanoid") and (k == "WalkSpeed" or k == "JumpPower") then return (k == "WalkSpeed" and 16 or 50) end
            return old(t, k)
        end); setreadonly(mt, true)
    end
end)
SCP:Toggle("Anti-AFK", "afk", false, "", function(v)
    if v then State.Security.afkConn = LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
    else if State.Security.afkConn then State.Security.afkConn:Disconnect() end end
end)
SCP:Button("🔄 Rejoin Server", "", function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)

-- IY FLING LOOP
task.spawn(function()
    while true do
        if State.Fling.active and getRoot() then
            local oldVel = getRoot().Velocity
            getRoot().RotVelocity = Vector3.new(0, State.Fling.power, 0)
            getRoot().Velocity = Vector3.new(State.Fling.power, State.Fling.power, State.Fling.power)
            RS.RenderStepped:Wait()
            getRoot().Velocity = oldVel
        end
        RS.RenderStepped:Wait()
    end
end)

-- NOCLIP LOOP
RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

Library:Notification("XKID V27", "Ghost Drone Ready! Sikat Bro!", 5)