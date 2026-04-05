--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v19.0  💠              ║
║                CINEMATIC RAW-LOCK EDITION                ║
╚═══════════════════════════════════════════════════════════╣
║  ➤  Fixed: Analog Maju = Selalu Maju (Searah Lensa)       ║
║  ➤  Fixed: Speed Cam (0.1 - 5) buat Slow-Mo Pro          ║
║  ➤  Fixed: Atmosfir Malam & Security Lengkap              ║
║  ➤  Stable: IY Fling & Native Fly Locked                  ║
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
    Cinema = {active = false, speed = 0.5, fov = 70, rotX = 0, rotY = 0}
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ➤  FLY ENGINE (STABLE)                  │
-- └─────────────────────────────────────────────────────────┘
local function toggleFly(v)
    if not v then
        State.Fly.active = false
        if State.Fly.bv then State.Fly.bv:Destroy() end
        if State.Fly.bg then State.Fly.bg:Destroy() end
        if getHum() then getHum().PlatformStand = false; getHum():ChangeState(1) end
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
-- │             ➤  CINEMATIC ENGINE (RAW-LOCK)              │
-- └─────────────────────────────────────────────────────────┘
-- Touch Panning (Nengok/Swipe)
UIS.InputChanged:Connect(function(input)
    if State.Cinema.active and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Delta
        State.Cinema.rotX = State.Cinema.rotX - delta.Y * 0.35
        State.Cinema.rotY = State.Cinema.rotY - delta.X * 0.35
        State.Cinema.rotX = math.clamp(State.Cinema.rotX, -85, 85)
    end
end)

RS.RenderStepped:Connect(function()
    if State.Cinema.active then
        Cam.CameraType = Enum.CameraType.Scriptable
        
        -- Apply Rotasi dari Swipe Jari
        Cam.CFrame = CFrame.new(Cam.CFrame.Position) * CFrame.Angles(0, math.rad(State.Cinema.rotY), 0) * CFrame.Angles(math.rad(State.Cinema.rotX), 0, 0)
        
        -- FIXED MOVEMENT: Pakai Raw MoveVector (Joystick Asli)
        local rawInput = UIS:GetMoveVector() 
        if rawInput.Magnitude > 0 then
            -- LOGIKA FIX: Maju selalu searah LookVector Kamera (Gak bakal kebalik)
            local moveDir = (Cam.CFrame.LookVector * -rawInput.Z) + (Cam.CFrame.RightVector * rawInput.X)
            Cam.CFrame = Cam.CFrame + (moveDir * State.Cinema.speed)
        end
        
        if getRoot() then getRoot().Anchored = true end
    else
        if getRoot() and getRoot().Anchored then getRoot().Anchored = false end
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │             ➤  IY FLING ENGINE (LOCKED)                 │
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
local Win = Library:Window("XKID HUB V19", "star", "CINEMATIC PRO", false)

-- --- TAB 1: TELEPORT ---
local T_TP = Win:Tab("Teleport", "map-pin")
local TPT = T_TP:Page("Navigation", "map-pin"):Section("🎯 Target", "Left")
local P_Drop = TPT:Dropdown("Select Player", "pDrop", getPNames(), function(v) State.Teleport.selectedTarget = v end)
TPT:TextBox("Ketik Nama Manual", "pText", "", function(v) State.Teleport.selectedTarget = v end)
TPT:Button("🚀 Teleport Now", "", function()
    local target = Players:FindFirstChild(State.Teleport.selectedTarget)
    if target and target.Character then getRoot().CFrame = target.Character.HumanoidRootPart.CFrame end
end)
TPT:Button("🔄 Refresh List", "", function() P_Drop:Refresh(getPNames()) end)

-- --- TAB 2: PLAYER ---
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

PLH:Toggle("Native Fly", "nf", false, "Joystick Support", function(v) toggleFly(v) end)
PLH:Toggle("NoClip", "nc", false, "", function(v) State.Move.ncp = v end)
PLH:Toggle("Invisible (R15)", "inv", false, "", function(v) if v and LP.Character:FindFirstChild("LowerTorso") then LP.Character.LowerTorso:Destroy() end end)
PLH:Toggle("IY Fling Mode", "ffm", false, "", function(v) State.Fling.active = v; State.Move.ncp = v end)

PLW:Slider("Waktu (ClockTime)", "time", 0, 24, 12, function(v) Lighting.ClockTime = v end)
PLW:Button("☀️ Set Siang", "Day", function() Lighting.ClockTime = 14 end)
PLW:Button("🌙 Set Malam", "Night", function() Lighting.ClockTime = 0 end)

-- --- TAB 3: CINEMATIC ---
local T_CI = Win:Tab("Cinematic", "video")
local CIM = T_CI:Page("Camera", "video"):Section("🎬 Controls", "Left")
local CIW = T_CI:Page("Camera", "video"):Section("📱 Orientation", "Right")

CIM:Toggle("Freecam Raw Analog", "fc", false, "UP = Selalu Maju", function(v)
    State.Cinema.active = v
    if not v then Cam.CameraType = Enum.CameraType.Custom end
end)
CIM:Slider("Speed Cam (Slow-mo)", "csc", 0.1, 5, 0.5, function(v) State.Cinema.speed = v end)
CIM:Slider("Zoom (FOV)", "cfov", 10, 120, 70, function(v) Cam.FieldOfView = v end)

CIW:Button("📱 Portrait Mode", "Tegak", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end)
CIW:Button("📺 Landscape Mode", "Mendatar", function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end)

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
SCP:Button("🔄 Rejoin Server", "Masuk Ulang", function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)

-- NOCLIP LOOP
RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

Players.PlayerAdded:Connect(function() P_Drop:Refresh(getPNames()) end)
Players.PlayerRemoving:Connect(function() P_Drop:Refresh(getPNames()) end)

Library:Notification("XKID V19", "Freecam Raw-Lock Aktif! Sikat Bro!", 5)
