--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v28.0  💠              ║
║                GHOST DRONE & FULL FEATURES LOCK          ║
╚═══════════════════════════════════════════════════════════╣
║  ➤  Fixed: Drone Joystick (ThumbstickInner Read)          ║
║  ➤  Fixed: Invisible R15 Restore & Camera Return          ║
║  ➤  New:   Save/Load Location Slot 1-5                    ║
║  ➤  Stable: Smart TP, Fly, Bypass, IY Fling Locked        ║
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
        -- Baca joystick LANGSUNG dari DynamicThumbstick position delta
        -- Ini paling akurat untuk mobile, tidak bergantung pada world-transform
        local rawJoy = Vector3.zero
        local touchGui = LP.PlayerGui:FindFirstChild("TouchGui")
        if touchGui then
            local tcf = touchGui:FindFirstChild("TouchControlFrame")
            local dtf = tcf and tcf:FindFirstChild("DynamicThumbstickFrame")
            -- ThumbstickInner adalah lingkaran yang bergerak mengikuti jari
            local inner = dtf and dtf:FindFirstChild("ThumbstickInner")
            if inner and dtf then
                -- Hitung offset inner dari center frame = raw joystick vector
                local center = dtf.AbsolutePosition + dtf.AbsoluteSize * 0.5
                local pos    = inner.AbsolutePosition + inner.AbsoluteSize * 0.5
                local offset = pos - center
                local radius = dtf.AbsoluteSize.X * 0.5
                if radius > 0 then
                    local nx = math.clamp(offset.X / radius, -1, 1)
                    local ny = math.clamp(offset.Y / radius, -1, 1)
                    -- nx = kanan/kiri, ny = bawah/atas (positif = bawah di screen = maju)
                    rawJoy = Vector3.new(deadzone(nx), 0, deadzone(ny))
                end
            end
        end

        -- Bangun CFrame kamera dari angles saat ini
        local camCF = CFrame.new(FC.pos) * CFrame.fromOrientation(FC.angles.X, FC.angles.Y, 0)

        -- Proyeksikan ke ruang kamera drone:
        -- rawJoy.X = kanan/kiri → RightVector kamera
        -- rawJoy.Z = maju/mundur (positif screen = maju) → LookVector kamera
        -- Pitch ikut kamera (terbang ke bawah kalau kamera nunduk)
        local smoothJoy = spPos:Update(dt, rawJoy)
        local smoothMove = camCF.LookVector * (-smoothJoy.Z) + camCF.RightVector * smoothJoy.X

        local baseSpeed = State.Cinema.speed * 64
        FC.pos = FC.pos + smoothMove * baseSpeed * dt * FC.speedMul

        -- ── TERAPKAN KE KAMERA ────────────────────────────────
        local cf = CFrame.new(FC.pos) * CFrame.fromOrientation(FC.angles.X, FC.angles.Y, 0)
        Cam.CFrame = cf

        -- ── FREEZE BADAN (3 lapis) ─────────────────────────────
        -- Karakter tetap di posisi asli, tidak dipindah ke -9999
        -- Transparansi sudah dihandle saat toggle ON
        local hrp = getRoot()
        local hum = getHum()
        if hrp then
            if not hrp.Anchored then hrp.Anchored = true end
        end
        if hum then
            -- ChangeState Physics = humanoid tidak proses movement sama sekali
            if hum:GetState() ~= Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.Physics)
            end
            hum.WalkSpeed  = 0
            hum.JumpPower  = 0
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
local Win = Library:Window("XKID HUB V28", "star", "GHOST DRONE", false)

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

-- --- SAVE / LOAD LOCATION ---
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
-- Invisible R15: simpan transparency asli lalu restore saat off
local invisSaved = {}
PLH:Toggle("Invisible (R15)", "inv", false, "", function(v)
    local char = LP.Character
    if not char then return end
    if v then
        invisSaved = {}
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                invisSaved[part] = part.Transparency
                part.Transparency = 1
            end
        end
    else
        for part, origTrans in pairs(invisSaved) do
            if part and part.Parent then
                part.Transparency = origTrans
            end
        end
        invisSaved = {}
        -- Pastikan kamera balik ke mode normal
        if Cam.CameraType ~= Enum.CameraType.Custom then
            Cam.CameraType = Enum.CameraType.Custom
        end
    end
end)
PLH:Toggle("IY Fling Mode", "ffm", false, "Tabrak!", function(v) State.Fling.active = v; State.Move.ncp = v end)

PLW:Slider("Waktu (ClockTime)", "time", 0, 24, 12, function(v) Lighting.ClockTime = v end)
PLW:Button("☀️ Set Siang", "", function() Lighting.ClockTime = 14 end)
PLW:Button("🌙 Set Malam", "", function() Lighting.ClockTime = 0 end)

-- --- TAB 3: CINEMATIC ---
local T_CI = Win:Tab("Cinematic", "video")
local CIM = T_CI:Page("Drone", "video"):Section("🎬 Drone Mode", "Left")
local CIW = T_CI:Page("Drone", "video"):Section("📱 Orientation", "Right")

-- Simpan transparency karakter saat drone aktif
local droneInvisSaved = {}

CIM:Toggle("Ghost Drone", "fc", false, "Auto-Invis & Return", function(v)
    State.Cinema.active = v
    if v then
        State.Cinema.lastPos = getRoot() and getRoot().CFrame

        -- Ambil posisi & sudut dari kamera sekarang (tidak lompat)
        local cf = Cam.CFrame
        local rx, ry = cf:ToEulerAnglesYXZ()
        FC.pos    = cf.Position
        FC.angles = Vector2.new(rx, ry)
        FC.fov    = Cam.FieldOfView
        FC.speedMul = 1
        FC.slow   = false

        -- Reset spring
        spPos:Reset(Vector3.zero)
        spPan:Reset(Vector2.zero)
        spFov:Reset(0)

        -- ── FREEZE KARAKTER (3 lapis) ──────────────────────────
        local hrp = getRoot()
        local hum = getHum()
        if hrp then hrp.Anchored = true end
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end

        -- ── SEMBUNYIKAN KARAKTER (transparansi) ────────────────
        -- Karakter tetap di posisi asli, hanya tidak kelihatan
        droneInvisSaved = {}
        local char = LP.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    droneInvisSaved[part] = part.Transparency
                    part.Transparency = 1
                end
            end
        end

        startDroneCapture()
        startDroneLoop()
    else
        stopDroneLoop()
        stopDroneCapture()

        -- ── RESTORE KARAKTER ───────────────────────────────────
        local hrp = getRoot()
        local hum = getHum()

        -- Restore transparency
        for part, origTrans in pairs(droneInvisSaved) do
            if part and part.Parent then
                part.Transparency = origTrans
            end
        end
        droneInvisSaved = {}

        -- Unanchor + pindah ke posisi kamera
        if hrp then
            hrp.Anchored = false
            hrp.CFrame = Cam.CFrame
        end

        -- Restore humanoid state normal
        if hum then
            hum.WalkSpeed = State.Move.ws
            hum.JumpPower = State.Move.jp
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        Cam.FieldOfView = 70
        Cam.CameraType = Enum.CameraType.Custom
        Library:Notification("Drone", "Badan lo udah balik ke posisi kamera!", 3)
    end
end)
CIM:Slider("Drone Speed", "csc", 0.1, 5, 1, function(v) State.Cinema.speed = v end)
CIM:Slider("Zoom (FOV)", "cfov", 10, 120, 70, function(v) Cam.FieldOfView = v end)

CIW:Button("📱 Portrait", "Tegak", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end)
CIW:Button("📺 Landscape", "Mendatar", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end)

-- --- TAB 4: SPECTATE ---
local T_SP = Win:Tab("Spectate", "eye")
local SPP  = T_SP:Page("Viewer", "eye")
local SPS  = SPP:Section("👁️ Spectate Player", "Left")
local SPF  = SPP:Section("🔍 FOV Zoom", "Right")

-- ── SPECTATE STATE ─────────────────────────────────────────
local Spec = {
    active  = false,
    target  = nil,
    mode    = "third",   -- "third" | "first"
    dist    = 8,
    origFov = 70,
    -- orbit angles (third person)
    orbitYaw   = 0,
    orbitPitch = 0,
    -- free rotate angles (first person, seperti drone)
    fpYaw   = 0,
    fpPitch = 0,
}

-- Touch input untuk spectate (terpisah dari drone)
local specTouchMain  = nil
local specTouchPinch = {}
local specPinchDist  = nil
local specPanDelta   = Vector2.zero
local specConns      = {}

local function startSpecCapture()
    table.insert(specConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or not Spec.active then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inJoystickArea(inp.Position) then return end -- abaikan joystick area
        -- Masukkan semua touch non-joystick ke tabel pinch
        table.insert(specTouchPinch, inp)
        -- Touch pertama = kandidat pan, touch kedua = pinch mode aktif
        if #specTouchPinch == 1 then
            specTouchMain = inp
        else
            -- Dua jari atau lebih = pinch mode, batalkan pan
            specTouchMain = nil
        end
    end))

    table.insert(specConns, UIS.InputChanged:Connect(function(inp)
        if not Spec.active then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end

        if #specTouchPinch == 1 and inp == specTouchMain then
            -- Satu jari = rotate orbit / FP
            specPanDelta = specPanDelta + Vector2.new(inp.Delta.X, inp.Delta.Y)

        elseif #specTouchPinch >= 2 then
            -- Dua jari = pinch zoom (hitung jarak antara dua jari aktif)
            local d = (specTouchPinch[1].Position - specTouchPinch[2].Position).Magnitude
            if specPinchDist then
                local diff = d - specPinchDist
                -- Jauh = zoom out (FOV naik), dekat = zoom in (FOV turun)
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
        -- Kalau tinggal satu jari, lanjut pan dari jari yang tersisa
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

-- ── RENDER LOOP SPECTATE ───────────────────────────────────
local specLoop = nil

local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not Spec.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable

        local char = Spec.target and Spec.target.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Ambil pan delta frame ini
        local pan  = specPanDelta
        specPanDelta = Vector2.zero
        local sens = 0.3

        if Spec.mode == "third" then
            -- ── ORBIT CAMERA ──────────────────────────────
            -- drag X = putar kiri/kanan (yaw)
            -- drag Y = putar atas/bawah (pitch)
            Spec.orbitYaw   = Spec.orbitYaw   + pan.X * sens
            Spec.orbitPitch = math.clamp(Spec.orbitPitch + pan.Y * sens, -75, 75)

            local orbitCF = CFrame.new(hrp.Position)
                * CFrame.Angles(0, math.rad(-Spec.orbitYaw), 0)
                * CFrame.Angles(math.rad(-Spec.orbitPitch), 0, 0)
                * CFrame.new(0, 0, Spec.dist)

            -- Kamera lihat ke HRP (sedikit di atas pusat badan)
            local focusPos = hrp.Position + Vector3.new(0, 1, 0)
            Cam.CFrame = CFrame.new(orbitCF.Position, focusPos)

        else
            -- ── FIRST PERSON FREE ROTATE (seperti drone) ──
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

-- ── UI SPECTATE ────────────────────────────────────────────
local specDrop = SPS:Dropdown("Pilih Target", "spDrop", getPNames(), function(v)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name == v then
            Spec.target = p
            -- Reset angles ke arah belakang target saat ini supaya tidak lompat
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ()
                Spec.orbitYaw   = math.deg(ry)
                Spec.orbitPitch = 20   -- sedikit dari atas
                Spec.fpYaw      = math.deg(ry)
                Spec.fpPitch    = 0
            end
            break
        end
    end
end)
SPS:Button("🔄 Refresh", "", function() specDrop:Refresh(getPNames()) end)

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
        Library:Notification("Spectate", "Nonton: " .. Spec.target.Name, 3)
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
    -- Reset FP angles dari posisi kamera orbit sekarang supaya tidak lompat
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

-- FOV Zoom — tombol +/- lebih mudah disentuh di mobile
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

-- --- TAB 5: WORLD ---
local T_WO = Win:Tab("World", "globe")

-- PAGE 1: WEATHER
local WOP1  = T_WO:Page("Weather", "cloud")
local WOW   = WOP1:Section("🌤️ Preset Cuaca", "Left")
local WOA   = WOP1:Section("🌈 Atmosphere", "Right")

-- Helper: pastikan Atmosphere instance ada
local function getAtmos()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atm then
        atm = Instance.new("Atmosphere", Lighting)
    end
    return atm
end

-- Helper: set cuaca lengkap sekaligus
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

-- Preset cuaca
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

-- Atmosphere fine-tune
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

-- PAGE 2: GRAPHICS
local WOP2  = T_WO:Page("Graphics", "monitor")
local WOG   = WOP2:Section("📱 Mode Grafik", "Left")
local WOGF  = WOP2:Section("⚙️ Level Manual", "Right")

-- Helper set grafik
local function setGfx(level)
    local ok, err = pcall(function()
        settings().Rendering.QualityLevel = level
    end)
    if not ok then
        -- fallback via UserGameSettings
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

-- Level manual 1-10 via tombol +/-
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

-- --- TAB 6: SECURITY ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")
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

Library:Notification("XKID V28", "Ghost Drone Ready! Sikat Bro!", 5)
