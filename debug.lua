--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v24.0  💠              ║
║                REAL-TIME SYNC DRONE LOCK                 ║
╚═══════════════════════════════════════════════════════════╣
║  ➤  Fixed: Drone Cam (Maju Selalu Searah Lensa)           ║
║  ➤  Fixed: Analog Sync (Gak bakal terbalik pas nengok)    ║
║  ➤  Stable: Smart TP (2-3 Huruf), IY Fling, Weather       ║
║  ➤  Stable: Rejoin, Anti-AFK, & Security Locked           ║
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
    Cinema = {active = false, speed = 0.5, fov = 70, rotX = 0, rotY = 0, pos = nil}
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end

-- SMART TELEPORT (Locked from V23)
local function tpToPartialName(nameSnippet)
    if nameSnippet == "" then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and (string.find(string.lower(p.Name), string.lower(nameSnippet)) or string.find(string.lower(p.DisplayName), string.lower(nameSnippet))) then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                getRoot().CFrame = p.Character.HumanoidRootPart.CFrame
                Library:Notification("Teleport", "Melesat ke: " .. p.Name, 2)
                return
            end
        end
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │             ➤  DRONE CAMERA ENGINE (SYNCED)             │
-- └─────────────────────────────────────────────────────────┘
-- Handle nengok (Swipe Layar Kanan)
UIS.InputChanged:Connect(function(input)
    if State.Cinema.active and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Delta
        State.Cinema.rotX = State.Cinema.rotX - delta.Y * 0.4
        State.Cinema.rotY = State.Cinema.rotY - delta.X * 0.4
        State.Cinema.rotX = math.clamp(State.Cinema.rotX, -85, 85)
    end
end)

RS.RenderStepped:Connect(function()
    if State.Cinema.active then
        Cam.CameraType = Enum.CameraType.Scriptable
        
        -- Hitung Rotasi Kamera secara instan
        local rotation = CFrame.Angles(0, math.rad(State.Cinema.rotY), 0) * CFrame.Angles(math.rad(State.Cinema.rotX), 0, 0)
        
        -- Ambil input joystick (Layar Kiri)
        local rawInput = UIS:GetMoveVector() 
        if rawInput.Magnitude > 0 then
            -- SYNC LOGIC: Gunakan CFrame rotasi terbaru untuk menentukan arah gerak
            -- Jadi kemana pun mata nengok, arah joystick tetep sinkron
            local direction = (rotation * CFrame.new(rawInput.X, 0, rawInput.Z)).Position
            State.Cinema.pos = State.Cinema.pos + (direction * State.Cinema.speed)
        end
        
        -- Terapkan ke Kamera
        Cam.CFrame = CFrame.new(State.Cinema.pos) * rotation
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB V24", "camera", "DRONE MASTER", false)

-- --- TAB 1: TELEPORT (SMART) ---
local T_TP = Win:Tab("Teleport", "map-pin")
local TPT = T_TP:Page("Navigation", "map-pin"):Section("🎯 Smart TP", "Left")

TPT:TextBox("Ketik Nama (2-3 Huruf)", "pText", "", function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🚀 Teleport Now", "Fast Search", function() tpToPartialName(State.Teleport.selectedTarget) end)
local P_Drop = TPT:Dropdown("Manual List", "pDrop", getPNames(), function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🔄 Refresh Player", "", function() P_Drop:Refresh(getPNames()) end)

-- --- TAB 2: PLAYER (LOCKED) ---
local T_PL = Win:Tab("Player", "user")
local PLP = T_PL:Page("Settings", "zap")
local PLM = PLP:Section("⚡ Movement", "Left")
local PLH = PLP:Section("🚀 Hacks", "Right")
local PLW = PLP:Section("🌦️ Atmosphere", "Left")

PLM:Button("🔄 Refresh (;re)", "", function() 
    local cf = getRoot().CFrame; getHum().Health = 0
    LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = cf
end)
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) if getHum() then getHum().WalkSpeed = v end end)
PLM:Toggle("Inf Jump", "ij", false, "", function(v) 
    if v then State.Move.infJ = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if State.Move.infJ then State.Move.infJ:Disconnect() end end
end)

PLH:Toggle("NoClip", "nc", false, "", function(v) State.Move.ncp = v end)
PLH:Toggle("Invisible (R15)", "inv", false, "", function(v) if v and LP.Character:FindFirstChild("LowerTorso") then LP.Character.LowerTorso:Destroy() end end)
PLH:Toggle("IY Fling Mode", "ffm", false, "Tabrak Musuh", function(v) State.Fling.active = v; State.Move.ncp = v end)

PLW:Slider("Waktu (ClockTime)", "time", 0, 24, 12, function(v) Lighting.ClockTime = v end)
PLW:Button("☀️ Set Siang", "", function() Lighting.ClockTime = 14 end)
PLW:Button("🌙 Set Malam", "", function() Lighting.ClockTime = 0 end)

-- --- TAB 3: CINEMATIC (SMOOTH SYNC) ---
local T_CI = Win:Tab("Cinematic", "video")
local CIM = T_CI:Page("Drone", "video"):Section("🎬 Pro Controls", "Left")
local CIW = T_CI:Page("Drone", "video"):Section("📱 Orientation", "Right")

CIM:Toggle("Freecam (Freeze Char)", "fc", false, "Synced Analog", function(v)
    State.Cinema.active = v
    if v then
        State.Cinema.pos = Cam.CFrame.Position
        State.Cinema.rotX = 0
        State.Cinema.rotY = 0
        if getRoot() then getRoot().Anchored = true end
    else
        if getRoot() then getRoot().Anchored = false end
        Cam.CameraType = Enum.CameraType.Custom
    end
end)
CIM:Slider("Drone Speed", "csc", 0.1, 5, 0.5, function(v) State.Cinema.speed = v end)
CIM:Slider("Zoom (FOV)", "cfov", 10, 120, 70, function(v) Cam.FieldOfView = v end)

CIW:Button("📱 Portrait Mode", "TikTok", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end)
CIW:Button("📺 Landscape Mode", "YouTube", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end)

-- --- TAB 4: SECURITY (LOCKED) ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")
SCP:Toggle("Anti-AFK", "afk", false, "No Kick", function(v)
    if v then State.Security.afkConn = LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
    else if State.Security.afkConn then State.Security.afkConn:Disconnect() end end
end)
SCP:Button("🔄 Rejoin Server", "", function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)

-- IY FLING LOGIC
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

Library:Notification("XKID V24", "Drone Cam Synced! Sikat Bro!", 5)
