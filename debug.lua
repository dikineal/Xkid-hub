--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v13.0  💠              ║
║                CINEMATIC & PORTRAIT UPDATE               ║
╠═══════════════════════════════════════════════════════════╣
║  ➤  New: Cinematic Freecam (Analog Support)               ║
║  ➤  New: Force Portrait / Landscape Toggle                ║
║  ➤  New: Zoom (FOV) & Cam Speed Controller                ║
║  ➤  Stable: IY Fling, Weather, Rejoin, & Anti-AFK         ║
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
local Mouse = LP:GetMouse()
local Cam = workspace.CurrentCamera

-- Global State
local State = {
    Move = {ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60},
    Fly = {active = false, bv = nil, bg = nil},
    Fling = {active = false, power = 1000000},
    Teleport = {selectedTarget = ""},
    Security = {afkConn = nil},
    Cinema = {freecam = false, speed = 1, fov = 70, hideUI = false}
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ➤  CINEMATIC ENGINE                     │
-- └─────────────────────────────────────────────────────────┘
-- Freecam Analog Logic
RS.RenderStepped:Connect(function(dt)
    if State.Cinema.freecam then
        Cam.CameraType = Enum.CameraType.Scriptable
        local md = getHum() and getHum().MoveDirection or Vector3.zero
        if md.Magnitude > 0 then
            -- Gerakan kamera berdasarkan arah analog
            Cam.CFrame = Cam.CFrame * CFrame.new(md.X * State.Cinema.speed, 0, -md.Z * State.Cinema.speed)
        end
        -- Bekukan karakter biar ga jalan pas kamera lepas
        if getRoot() then getRoot().Anchored = true end
    else
        if getRoot() then getRoot().Anchored = false end
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ➤  IY FLING ENGINE                      │
-- └─────────────────────────────────────────────────────────┘
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

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID V13", "video", "CINEMATIC PRO", false)

-- --- TAB 1: CINEMATIC (🎥) ---
local T_CI = Win:Tab("Cinematic", "video")
local CIP = T_CI:Page("Camera", "video")
local CIM = CIP:Section("🎬 Camera Controls", "Left")
local CIW = CIP:Section("📱 Orientation", "Right")

CIM:Toggle("Freecam (Analog)", "fc", false, "Kamera Lepas", function(v)
    State.Cinema.freecam = v
    if not v then Cam.CameraType = Enum.CameraType.Custom end
end)

CIM:Slider("Camera Speed", "cs", 1, 10, 1, function(v) State.Cinema.speed = v end)
CIM:Slider("Zoom (FOV)", "fov", 10, 120, 70, function(v) Cam.FieldOfView = v end)

CIM:Button("🚫 Clean Screen (Hide UI)", "Tekan RightControl buat balikin", function()
    -- Fitur buat ngumpetin UI Roblox & Script pas ngerekam
    for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do pcall(function() v.Enabled = false end) end
    for _, v in pairs(LP.PlayerGui:GetChildren()) do pcall(function() v.Enabled = false end) end
    Library:Notification("Cinema", "UI Tersembunyi! Tekan tombol toggle UI buat balikin.", 5)
end)

CIW:Button("📱 Force Portrait", "Tegak (TikTok)", function()
    game:GetService("GuiService").ScreenOrientation = Enum.ScreenOrientation.Portrait
end)

CIW:Button("📺 Force Landscape", "Mendatar", function()
    game:GetService("GuiService").ScreenOrientation = Enum.ScreenOrientation.LandscapeRight
end)

CIW:Button("📐 Tilt Camera 90°", "Miringin Kamera", function()
    Cam.CFrame = Cam.CFrame * CFrame.Angles(0, 0, math.rad(90))
end)

-- --- TAB 2: TELEPORT (📍) ---
local T_TP = Win:Tab("Teleport", "map-pin")
local TPT = T_TP:Page("Nav", "map-pin"):Section("🎯 Target", "Left")
local P_Drop = TPT:Dropdown("Select Player", "pD", getPNames(), function(v) State.Teleport.selectedTarget = v end)
TPT:TextBox("Ketik Nama", "pT", "", function(v) State.Teleport.selectedTarget = v end)
TPT:Button("Teleport Now", "", function()
    local t = Players:FindFirstChild(State.Teleport.selectedTarget)
    if t and t.Character then getRoot().CFrame = t.Character.HumanoidRootPart.CFrame end
end)

-- --- TAB 3: PLAYER (🏃) ---
local T_PL = Win:Tab("Player", "user")
local PLP = T_PL:Page("Settings", "zap")
local PLM = PLP:Section("⚡ Movement", "Left")
local PLW = PLP:Section("🌦️ Weather", "Right")

PLM:Button("🔄 Refresh (;re)", "", function() 
    local cf = getRoot().CFrame; getHum().Health = 0
    LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = cf
end)
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) if getHum() then getHum().WalkSpeed = v end end)
PLW:Slider("Waktu (Weather)", "time", 0, 24, 12, function(v) Lighting.ClockTime = v end)

-- --- TAB 4: HACKS (🚀) ---
local T_HK = Win:Tab("Hacks", "zap")
local HKP = T_HK:Page("Troll", "zap"):Section("🚀 Hacks", "Left")
HKP:Toggle("Native Fly", "nf", false, "", function(v) 
    -- Native Fly Logic
end)
HKP:Toggle("IY Fling Mode", "ffm", false, "Mentalin Orang", function(v) 
    State.Fling.active = v; State.Move.ncp = v 
end)
HKP:Toggle("Invisible (R15)", "inv", false, "", function(v) 
    if v and LP.Character:FindFirstChild("LowerTorso") then LP.Character.LowerTorso:Destroy() end 
end)

-- --- TAB 5: SECURITY (🛡️) ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")
SCP:Button("🔄 Rejoin Server", "", function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
SCP:Toggle("Anti-AFK", "afk", false, "", function(v)
    if v then State.Security.afkConn = LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
    else if State.Security.afkConn then State.Security.afkConn:Disconnect() end end
end)

-- NOCLIP LOOP
RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

Library:Notification("XKID V13", "Mode Sinematik & Portrait Aktif!", 5)
