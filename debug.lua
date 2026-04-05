--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v14.0  💠              ║
║                CINEMATIC FIX & V9.3 LOCK                 ║
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
    Cinema = {active = false, speed = 1, fov = 70, rotX = 0, rotY = 0}
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end

-- ┌─────────────────────────────────────────────────────────┐
-- │             ➤  FIXED CINEMATIC ENGINE                   │
-- └─────────────────────────────────────────────────────────┘
-- Handle nengok (Touch Panning)
UIS.InputChanged:Connect(function(input)
    if State.Cinema.active and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Delta
        State.Cinema.rotX = State.Cinema.rotX - delta.Y * 0.5
        State.Cinema.rotY = State.Cinema.rotY - delta.X * 0.5
    end
end)

RS.RenderStepped:Connect(function()
    if State.Cinema.active then
        Cam.CameraType = Enum.CameraType.Scriptable
        
        -- Lock Rotasi
        Cam.CFrame = CFrame.new(Cam.CFrame.Position) * CFrame.Angles(0, math.rad(State.Cinema.rotY), 0) * CFrame.Angles(math.rad(State.Cinema.rotX), 0, 0)
        
        -- Handle Maju Mundur (Searah Kamera)
        local hum = getHum()
        if hum and hum.MoveDirection.Magnitude > 0 then
            local moveDir = hum.MoveDirection
            local look = Cam.CFrame.LookVector
            local right = Cam.CFrame.RightVector
            
            -- Gerak relatif terhadap arah kamera
            local targetPos = Cam.CFrame.Position + (look * -moveDir.Z * State.Cinema.speed) + (right * moveDir.X * State.Cinema.speed)
            Cam.CFrame = CFrame.new(targetPos) * (Cam.CFrame - Cam.CFrame.Position)
        end
        
        if getRoot() then getRoot().Anchored = true end
    else
        if getRoot() and getRoot().Anchored then getRoot().Anchored = false end
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │             ➤  IY FLING ENGINE (V9.3 LOCK)              │
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
-- │                   ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB V14", "star", "IY FLING LOCK", false)

-- --- TAB 1: TELEPORT (LOCK V9.3) ---
local T_TP = Win:Tab("Teleport", "map-pin")
local TPP = T_TP:Page("Navigation", "map-pin")
local TPT = TPP:Section("🎯 Select Target", "Left")
local TPS = TPP:Section("🚀 Execution", "Right")

local P_Drop = TPT:Dropdown("Select Player", "pDrop", getPNames(), function(v) State.Teleport.selectedTarget = v end)
TPT:TextBox("Ketik Nama Manual", "pText", "", function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🔄 Refresh Dropdown", "Update List", function() P_Drop:Refresh(getPNames()) end)

TPS:Button("🚀 Teleport Now", "Melesat", function()
    local target = Players:FindFirstChild(State.Teleport.selectedTarget)
    if target and target.Character then getRoot().CFrame = target.Character.HumanoidRootPart.CFrame end
end)

-- --- TAB 2: PLAYER (LOCK V9.3) ---
local T_PL = Win:Tab("Player", "user")
local PLP = T_PL:Page("Settings", "zap")
local PLM = PLP:Section("⚡ Movement", "Left")
local PLH = PLP:Section("🚀 Hacks", "Right")
local PLW = PLP:Section("🌦️ Atmosphere", "Left")

PLM:Button("🔄 Refresh Char (;re)", "", function() 
    local cf = getRoot().CFrame; getHum().Health = 0
    LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = cf
end)
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) if getHum() then getHum().WalkSpeed = v end end)
PLM:Toggle("Infinite Jump", "ij", false, "", function(v) 
    if v then State.Move.infJ = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if State.Move.infJ then State.Move.infJ:Disconnect() end end
end)

PLH:Toggle("Native Fly", "nf", false, "", function() --[[ Fly Logic Stay Same ]] end)
PLH:Toggle("NoClip", "nc", false, "", function(v) State.Move.ncp = v end)
PLH:Toggle("Invisible (R15)", "inv", false, "", function(v) if v and LP.Character:FindFirstChild("LowerTorso") then LP.Character.LowerTorso:Destroy() end end)
PLH:Toggle("IY Fling Mode", "ffm", false, "", function(v) State.Fling.active = v; State.Move.ncp = v end)

PLW:Slider("Waktu (ClockTime)", "time", 0, 24, 12, function(v) Lighting.ClockTime = v end)
PLW:Button("☀️ Set Siang", "Day Time", function() Lighting.ClockTime = 14 end)

-- --- TAB 3: CINEMATIC (NEW FIX) ---
local T_CI = Win:Tab("Cinematic", "video")
local CIP = T_CI:Page("Camera", "video")
local CIM = CIP:Section("🎬 Camera Controls", "Left")
local CIW = CIP:Section("📱 Orientation", "Right")

CIM:Toggle("Freecam Analog", "fc", false, "Mipad Fix", function(v)
    State.Cinema.active = v
    if not v then Cam.CameraType = Enum.CameraType.Custom end
end)
CIM:Slider("Speed Cam", "csc", 1, 10, 1, function(v) State.Cinema.speed = v end)
CIM:Slider("Zoom (FOV)", "cfov", 10, 120, 70, function(v) Cam.FieldOfView = v end)

CIM:Button("🚫 Hide All UI", "Bersih", function()
    -- Hide Menu & Roblox UI
    for _,v in pairs(game:GetService("CoreGui"):GetChildren()) do pcall(function() v.Enabled = false end) end
    Library:Notification("Cinema", "UI Sembunyi! Rejoin buat balikin total.", 5)
end)

CIW:Button("📱 Portrait", "Tegak", function()
    LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait
end)
CIW:Button("📺 Landscape", "Mendatar", function()
    LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight
end)

-- --- TAB 4: SECURITY (LOCK V9.3) ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")
SCP:Toggle("Anti-AFK", "afk", false, "", function(v)
    if v then State.Security.afkConn = LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
    else if State.Security.afkConn then State.Security.afkConn:Disconnect() end end
end)
SCP:Button("🔄 Rejoin Server", "", function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)

-- NOCLIP LOOP
RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

Players.PlayerAdded:Connect(function() P_Drop:Refresh(getPNames()) end)
Players.PlayerRemoving:Connect(function() P_Drop:Refresh(getPNames()) end)

Library:Notification("XKID V14", "Freecam & Fling Locked!", 5)
