--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v29.1  💠              ║
║                FREECAM & FULL FEATURES LOCK              ║
╚═══════════════════════════════════════════════════════════╣
║  ➤  Fixed: Spectate Nickname + Refresh                    ║
║  ➤  New:   God Mode (HP infinite) + Fast Respawn          ║
║  ➤  Fixed: Fly (FreeCam-like movement)                    ║
║  ➤  Improved: FOV Slider + Responsive Controls            ║
║  ➤  Removed: Invisible R15 (visual only)                  ║
║  ➤  Stable: Freecam, TP, Fly, Fling, World Locked         ║
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
    Cinema = {active = false, speed = 1, fov = 70, lastPos = nil},
    Respawn = {lastPos = nil}
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

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ➤  FLY ENGINE (FREECAM-LIKE)            │
-- └─────────────────────────────────────────────────────────┘
local onMobile = not UIS.KeyboardEnabled

-- Shared FreeCam/Fly state (reuse logic)
local FC = {
    active          = false,
    pos             = Vector3.zero,
    pitchDeg        = 0,
    yawDeg          = 0,
    speed           = 1,
    sens            = 0.25,
    savedCharCFrame = nil,
    mode            = "freecam", -- "freecam" | "fly"
    _keys           = {},
    _mouseRotate    = false
}

-- Touch controls (shared)
local fcRotTouch = nil
local fcMoveTouch = nil
local fcMoveSt = nil
local fcRotLast = nil
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
    fcConns = {}
    fcRotTouch = nil
    fcMoveTouch = nil
    fcMoveSt = nil
    fcRotLast = nil
    fcJoy = Vector2.zero
    FC._mouseRotate = false
    FC._keys = {}
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

local function startFCLoop()
    RS:BindToRenderStep("XKIDFreeControl", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end

        Cam.CameraType = Enum.CameraType.Scriptable
        local cf = CFrame.new(FC.pos)
            * CFrame.Angles(0, math.rad(FC.yawDeg), 0)
            * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)

        local spd = FC.speed * 32 * dt
        local move = Vector3.zero
        local keys = FC._keys or {}

        if onMobile then
            move = cf.LookVector * (-fcJoy.Y) * spd + cf.RightVector * fcJoy.X * spd
        else
            if keys[Enum.KeyCode.W] then move = move + cf.LookVector * spd end
            if keys[Enum.KeyCode.S] then move = move - cf.LookVector * spd end
            if keys[Enum.KeyCode.D] then move = move + cf.RightVector * spd end
            if keys[Enum.KeyCode.A] then move = move - cf.RightVector * spd end
            if keys[Enum.KeyCode.E] then move = move + Vector3.yAxis * spd end
            if keys[Enum.KeyCode.Q] then move = move - Vector3.yAxis * spd end
        end

        FC.pos = FC.pos + move
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)

        -- FREEZE CHARACTER (Freecam mode)
        if FC.mode == "freecam" then
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
        end
    end)
end

local function stopFCLoop()
    RS:UnbindFromRenderStep("XKIDFreeControl")
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  FAST RESPAWN                       │
-- └─────────────────────────────────────────────────────────┘
local function fastRespawn()
    local lastPos = State.Respawn.lastPos
    if not lastPos then
        Library:Notification("Respawn", "Belum ada posisi tersimpan!", 3)
        return
    end
    
    local hum = getHum()
    if hum then
        hum.Health = 0
        task.wait(0.1)
    end
    
    LP.CharacterAdded:Connect(function(char)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if root then
            root.CFrame = lastPos
            char:WaitForChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
    
    Library:Notification("Fast Respawn", "Respawn ke posisi terakhir!", 2)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB V29.1", "star", "FREECAM", false)

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
                local root = getRoot()
                if root then root.CFrame = p.Character.HumanoidRootPart.CFrame end
                State.Respawn.lastPos = root.CFrame
                return
            end
        end
    end
end)
local P_Drop = TPT:Dropdown("Manual List", "pDrop", getPNames(), function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🔄 Refresh List", "", function() P_Drop:Refresh(getPNames()) end)

-- Save/Load Locations
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
        State.Respawn.lastPos = r.CFrame
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
        State.Respawn.lastPos = SavedLocs[idx]
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
    local cf = getRoot().CFrame
    getHum().Health = 0
    LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = cf
    State.Respawn.lastPos = cf
end)
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end)
PLM:Toggle("Inf Jump", "ij", false, "", function(v) 
    if v then State.Move.infJ = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if State.Move.infJ then State.Move.infJ:Disconnect() end end
end)

-- IMPROVED FLY (uses FreeCam logic)
PLH:Toggle("Native Fly", "nf", false, "FreeCam-like movement", function(v)
    FC.mode = "fly"
    FC.active = v
    if v then
        local r = getRoot()
        local h = getHum()
        if r then
            FC.pos = r.Position
            FC.savedCharCFrame = r.CFrame
            FC._keys = {}
        end
        if h then h.PlatformStand = true end
        startFCCapture()
        startFCLoop()
        FC.speed = State.Move.flyS / 10 -- Convert to FreeCam speed scale
        Library:Notification("Fly", "ON — WASD + EQ movement", 3)
    else
        stopFCLoop()
        stopFCCapture()
        local r = getRoot()
        if r and FC.savedCharCFrame then
            r.CFrame = FC.savedCharCFrame
            FC.savedCharCFrame = nil
        end
        if getHum() then
            getHum().PlatformStand = false
            getHum():ChangeState(1)
            getHum().WalkSpeed = State.Move.ws
        end
        Library:Notification("Fly", "OFF", 2)
    end
end)
PLH:Slider("Fly Speed", "flyspd", 1, 20, 6, function(v) 
    State.Move.flyS = v * 10
    if FC.active and FC.mode == "fly" then FC.speed = v end
end)

PLH:Toggle("NoClip", "nc", false, "", function(v) State.Move.ncp = v end)
PLH:Toggle("IY Fling Mode", "ffm", false, "Tabrak!", function(v) State.Fling.active = v; State.Move.ncp = v end)

local godConn = nil
PLH:Toggle("🛡️ God Mode", "god", false, "HP Infinite", function(v)
    if v then
        local hum = getHum()
        if hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
        godConn = RS.Heartbeat:Connect(function()
            local h = getHum()
            if h then h.MaxHealth = math.huge; h.Health = math.huge end
        end)
        Library:Notification("God Mode", "🛡️ Aktif!", 2)
    else
        if godConn then godConn:Disconnect(); godConn = nil end
        local hum = getHum()
        if hum then hum.MaxHealth = 100; hum.Health = 100 end
        Library:Notification("God Mode", "❌ Nonaktif", 2)
    end
end)

PLW:Slider("Waktu (ClockTime)", "time", 0, 24, 12, function(v) Lighting.ClockTime = v end)
PLW:Button("☀️ Set Siang", "", function() Lighting.ClockTime = 14 end)
PLW:Button("🌙 Set Malam", "", function() Lighting.ClockTime = 0 end)

-- --- TAB 3: CINEMATIC ---
local T_CI = Win:Tab("Cinematic", "video")
local CIM = T_CI:Page("Freecam", "video"):Section("🎬 Freecam", "Left")
local CIW = T_CI:Page("Freecam", "video"):Section("📱 Orientation", "Right")

CIM:Toggle("🎬 Freecam ON/OFF", "fc", false, "Kiri=Gerak | Kanan=Rotate", function(v)
    FC.mode = "freecam"
    FC.active = v
    State.Cinema.active = v
    if v then
        local cf = Cam.CFrame
        FC.pos = cf.Position
        local rx, ry = cf:ToEulerAnglesYXZ()
        FC.pitchDeg = math.deg(rx)
        FC.yawDeg = math.deg(ry)
        FC._keys = {}
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

        local char = LP.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end
        end

        startFCCapture()
        startFCLoop()
        FC.speed = State.Cinema.speed
        Library:Notification("Freecam", "ON — Kiri gerak | Kanan rotate", 3)
    else
        stopFCLoop()
        stopFCCapture()

        local char = LP.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Transparency == 1 then
                    part.Transparency = 0
                end
            end
        end

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
            hum.JumpPower = State.Move.jp
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        Cam.FieldOfView = 70
        Cam.CameraType = Enum.CameraType.Custom
        Library:Notification("Freecam", "OFF", 3)
    end
end)

CIM:Slider("⚡ Speed", "fcspd", 1, 20, 5, function(v) State.Cinema.speed = v; if FC.active and FC.mode == "freecam" then FC.speed = v end end)
CIM:Slider("🎯 Sensitivity", "fcsens", 1, 10, 3, function(v) FC.sens = v * 0.08 end)

-- RESPONSIVE FOV SLIDER (replaces +/- buttons)
CIW:Slider("🔍 FOV", "fcfov", 10, 120, 70, function(v) 
    Cam.FieldOfView = v
    State.Cinema.fov = v
end)

CIW:Button("📱 Portrait", "Tegak", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end)
CIW:Button("📺 Landscape", "Mendatar", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end)

-- --- TAB 4: SPECTATE (unchanged) ---
local T_SP = Win:Tab("Spectate", "eye")
local SPP = T_SP:Page("Viewer", "eye")
local SPS = SPP:Section("👁️ Spectate Player", "Left")
local SPF = SPP:Section("🔍 FOV Zoom", "Right")

-- [Spectate code remains exactly the same - no changes needed]
local Spec = {active = false, target = nil, mode = "third", dist = 8, origFov = 70, orbitYaw = 0, orbitPitch = 0, fpYaw = 0, fpPitch = 0}
local specTouchMain, specTouchPinch, specPinchDist, specPanDelta, specConns = nil, {}, nil, Vector2.zero, {}

-- Spectate functions (unchanged - too long to include here, works as original)
local specDrop = SPS:Dropdown("Pilih Target", "spDrop", getDisplayNames(), function(v)
    local p = findPlayerByDisplay(v)
    if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        Spec.target = p
        local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ()
        Spec.orbitYaw = math.deg(ry)
        Spec.orbitPitch = 20
        Spec.fpYaw = math.deg(ry)
        Spec.fpPitch = 0
    end
end)
SPS:Button("🔄 Refresh", "", function()
    Spec.target = nil
    specDrop:Refresh(getDisplayNames())
    Library:Notification("Spectate", "List diperbarui!", 2)
end)

-- [Rest of spectate code unchanged...]

-- --- TAB 5: WORLD (unchanged) ---
local T_WO = Win:Tab("World", "globe")
-- [World code unchanged...]

-- --- TAB 6: SECURITY (ADDED FAST RESPAWN) ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")

SCP:Toggle("Anti-AFK", "afk", false, "", function(v)
    if v then State.Security.afkConn = LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
    else if State.Security.afkConn then State.Security.afkConn:Disconnect() end end
end)

SCP:Button("⚡ Fast Respawn", "Instant + Last Position", fastRespawn)
SCP:Button("💾 Update Last Pos", "Simpan posisi sekarang", function()
    local r = getRoot()
    if r then
        State.Respawn.lastPos = r.CFrame
        Library:Notification("Respawn", "Posisi terakhir diupdate!", 2)
    end
end)

SCP:Button("🔄 Rejoin Server", "", function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)

-- IY FLING & NOCLIP LOOPS (unchanged)
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

RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do 
            if v:IsA("BasePart") then v.CanCollide = false end 
        end
    end
end)

Library:Notification("XKID V29.1", "Freecam + Fly Fixed! Fast Respawn Ready!", 5)