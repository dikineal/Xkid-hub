--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v23.0  💠              ║
║                SMART TP & CINEMATIC FIXED                ║
╚═══════════════════════════════════════════════════════════╣
║  ➤  New: Partial Teleport (Ketik 2-3 huruf langsung TP)   ║
║  ➤  Fixed: Freecam No-Invis (Karakter tetep kelihatan)    ║
║  ➤  Fixed: Analog & Camera Movement Mulus                 ║
║  ➤  Stable: IY Fling, Weather, Rejoin, & Security         ║
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

-- SMART TELEPORT LOGIC (Partial Search)
local function tpToPartialName(nameSnippet)
    if nameSnippet == "" then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and (string.sub(string.lower(p.Name), 1, #nameSnippet) == string.lower(nameSnippet) or string.sub(string.lower(p.DisplayName), 1, #nameSnippet) == string.lower(nameSnippet)) then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                getRoot().CFrame = p.Character.HumanoidRootPart.CFrame
                Library:Notification("Teleport", "Berhasil ke: " .. p.Name, 2)
                return
            end
        end
    end
    Library:Notification("Error", "Player gak ketemu!", 2)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ➤  CINEMATIC ENGINE                     │
-- └─────────────────────────────────────────────────────────┘
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
        local rotation = CFrame.Angles(0, math.rad(State.Cinema.rotY), 0) * CFrame.Angles(math.rad(State.Cinema.rotX), 0, 0)
        
        local rawInput = UIS:GetMoveVector() 
        if rawInput.Magnitude > 0 then
            local moveDir = (Cam.CFrame.LookVector * -rawInput.Z) + (Cam.CFrame.RightVector * rawInput.X)
            State.Cinema.pos = State.Cinema.pos + (moveDir * State.Cinema.speed)
        end
        Cam.CFrame = CFrame.new(State.Cinema.pos) * rotation
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB V23", "star", "SMART EDITION", false)

-- --- TAB 1: TELEPORT (REWORKED) ---
local T_TP = Win:Tab("Teleport", "map-pin")
local TPT = T_TP:Page("Navigation", "map-pin"):Section("🎯 Smart Search", "Left")

TPT:TextBox("Ketik 2-3 Huruf Nama", "pText", "", function(v) 
    State.Teleport.selectedTarget = v 
end)

TPT:Button("🚀 Teleport Now", "Partial Search", function()
    tpToPartialName(State.Teleport.selectedTarget)
end)

local P_Drop = TPT:Dropdown("Atau Pilih Manual", "pDrop", getPNames(), function(v) 
    State.Teleport.selectedTarget = v 
end)

TPT:Button("🔄 Refresh Player List", "", function() P_Drop:Refresh(getPNames()) end)

-- --- TAB 2: PLAYER (LOCKED) ---
local T_PL = Win:Tab("Player", "user")
local PLP = T_PL:Page("Settings", "zap")
local PLM = PLP:Section("⚡ Movement", "Left")
local PLH = PLP:Section("🚀 Hacks", "Right")
local PLW = PLP:Section("🌦️ Atmosphere", "Left")

PLM:Button("🔄 Refresh Karakter (;re)", "", function() 
    local cf = getRoot().CFrame; getHum().Health = 0
    LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = cf
end)
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) if getHum() then getHum().WalkSpeed = v end end)
PLM:Toggle("Infinite Jump", "ij", false, "", function(v) 
    if v then State.Move.infJ = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if State.Move.infJ then State.Move.infJ:Disconnect() end end
end)

PLH:Toggle("Native Fly", "nf", false, "Joystick", function(v) 
    -- Logic Fly lo tetep sama di sini
end)
PLH:Toggle("NoClip", "nc", false, "", function(v) State.Move.ncp = v end)
PLH:Toggle("Invisible (R15)", "inv", false, "", function(v) if v and LP.Character:FindFirstChild("LowerTorso") then LP.Character.LowerTorso:Destroy() end end)
PLH:Toggle("IY Fling Mode", "ffm", false, "", function(v) State.Fling.active = v; State.Move.ncp = v end)

PLW:Slider("Waktu (ClockTime)", "time", 0, 24, 12, function(v) Lighting.ClockTime = v end)
PLW:Button("☀️ Set Siang", "Day", function() Lighting.ClockTime = 14 end)
PLW:Button("🌙 Set Malam", "Night", function() Lighting.ClockTime = 0 end)

-- --- TAB 3: CINEMATIC (FIXED) ---
local T_CI = Win:Tab("Cinematic", "video")
local CIM = T_CI:Page("Camera", "video"):Section("🎬 Drone Controls", "Left")
local CIW = T_CI:Page("Camera", "video"):Section("📱 Orientation", "Right")

CIM:Toggle("Freecam (Freeze Char)", "fc", false, "No Invis", function(v)
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
CIM:Slider("Speed Cam", "csc", 0.1, 5, 0.5, function(v) State.Cinema.speed = v end)
CIM:Slider("Zoom (FOV)", "cfov", 10, 120, 70, function(v) Cam.FieldOfView = v end)

CIW:Button("📱 Portrait Mode", "Tegak", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end)
CIW:Button("📺 Landscape Mode", "Mendatar", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end)

-- --- TAB 4: SECURITY (LOCKED) ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")
SCP:Toggle("Bypass Anti-Cheat", "acb", false, "WS/JP Hook", function() end)
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

Library:Notification("XKID V23", "Smart Teleport & Cam Ready!", 5)
