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
    Cinema = {active = false, speed = 0.5, fov = 70, rotX = 0, rotY = 0, pos = nil, smoothPos = nil, lastPos = nil}
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
-- │             ➤  GHOST DRONE ENGINE (FIXED)               │
-- └─────────────────────────────────────────────────────────┘
-- Touch drag state
local touchDragging = false
local lastTouchPos = nil

UIS.InputChanged:Connect(function(input)
    if not State.Cinema.active then return end

    -- TOUCH: seret untuk rotate kamera
    if input.UserInputType == Enum.UserInputType.Touch then
        if lastTouchPos then
            local delta = input.Position - lastTouchPos
            State.Cinema.rotY = State.Cinema.rotY - delta.X * 0.25
            State.Cinema.rotX = State.Cinema.rotX - delta.Y * 0.25
            State.Cinema.rotX = math.clamp(State.Cinema.rotX, -85, 85)
        end
        lastTouchPos = input.Position
    end

    -- MOUSE: drag klik kiri untuk rotate kamera
    if input.UserInputType == Enum.UserInputType.MouseMovement and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local delta = input.Delta
        State.Cinema.rotY = State.Cinema.rotY - delta.X * 0.3
        State.Cinema.rotX = State.Cinema.rotX - delta.Y * 0.3
        State.Cinema.rotX = math.clamp(State.Cinema.rotX, -85, 85)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        lastTouchPos = nil
    end
end)

RS.RenderStepped:Connect(function(dt)
    if State.Cinema.active then
        Cam.CameraType = Enum.CameraType.Scriptable

        -- Bangun rotasi dari sudut accumulated
        local rotation = CFrame.Angles(0, math.rad(State.Cinema.rotY), 0)
                       * CFrame.Angles(math.rad(State.Cinema.rotX), 0, 0)

        -- Ambil MoveDirection dari joystick (X/Z) = maju/mundur/kiri/kanan
        local md = getHum() and getHum().MoveDirection or Vector3.zero

        if md.Magnitude > 0 then
            -- Hitung arah berdasarkan rotasi kamera saat ini (bukan world axis)
            local camCF = CFrame.new(Vector3.zero) * rotation
            local forward = camCF.LookVector
            local right   = camCF.RightVector

            -- Joystick X/Z -> proyeksikan ke kamera forward & right
            -- Naik/turun: jika kamera miring, forward.Y sudah handle otomatis
            local flatForward = Vector3.new(forward.X, forward.Y, forward.Z) -- full 3D, termasuk pitch
            local flatRight   = Vector3.new(right.X,   0,         right.Z).Unit

            local moveVec = (flatForward * (-md.Z)) + (flatRight * md.X)
            State.Cinema.pos = State.Cinema.pos + moveVec * State.Cinema.speed
        end

        -- Smooth interpolation posisi supaya gerak sinematik (tidak patah-patah)
        if State.Cinema.smoothPos == nil then
            State.Cinema.smoothPos = State.Cinema.pos
        end
        local lerpAlpha = math.min(1, dt * 12)
        State.Cinema.smoothPos = State.Cinema.smoothPos:Lerp(State.Cinema.pos, lerpAlpha)

        Cam.CFrame = CFrame.new(State.Cinema.smoothPos) * rotation

        -- Sembunyikan badan jauh di bawah map supaya tidak terlihat di rekaman
        if getRoot() then
            getRoot().CFrame = CFrame.new(State.Cinema.smoothPos.X, -9999, State.Cinema.smoothPos.Z)
        end
    end
end)

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
        State.Cinema.pos = Cam.CFrame.Position
        State.Cinema.smoothPos = Cam.CFrame.Position  -- sync supaya tidak lompat

        -- Ambil rotasi awal dari orientasi kamera sekarang, bukan reset ke 0
        local _, ry, _ = Cam.CFrame:ToEulerAnglesYXZ()
        local rx = math.asin(Cam.CFrame.LookVector.Y)
        State.Cinema.rotX = math.deg(rx)
        State.Cinema.rotY = math.deg(ry)

        if getHum() then getHum().WalkSpeed = 0 end
    else
        -- KEMBALIKAN BADAN KE POSISI KAMERA
        if getRoot() then getRoot().CFrame = Cam.CFrame end
        if getHum() then getHum().WalkSpeed = State.Move.ws end
        Cam.CameraType = Enum.CameraType.Custom
        Library:Notification("Drone", "Badan lo udah balik ke posisi kamera!", 3)
    end
end)
CIM:Slider("Drone Speed", "csc", 0.1, 5, 0.5, function(v) State.Cinema.speed = v end)
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
