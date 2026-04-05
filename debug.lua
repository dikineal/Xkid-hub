--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v9.3   💠              ║
║                IY-STYLE FLING & LOCK VERSION             ║
╠═══════════════════════════════════════════════════════════╣
║  ➤  Logic: Infinite Yield Fling (Velocity Spike)          ║
║  ➤  Stable: Dual-Mode Teleport & Native Fly               ║
║  ➤  Stable: Rejoin, Weather, & Anti-AFK                   ║
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

-- Global State
local State = {
    Move = {ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60},
    Fly = {active = false, bv = nil, bg = nil},
    Fling = {active = false, power = 1000000}, -- Angka keramat IY
    Teleport = {selectedTarget = ""},
    Security = {afkConn = nil}
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end

-- ┌─────────────────────────────────────────────────────────┐
-- │             ➤  INFINITE YIELD FLING ENGINE              │
-- └─────────────────────────────────────────────────────────┘
task.spawn(function()
    while true do
        if State.Fling.active and getRoot() then
            -- Logic IY: Spike Velocity & RotVelocity secara bergantian
            local oldVel = getRoot().Velocity
            
            -- Spike 1: Rotasi gila
            getRoot().RotVelocity = Vector3.new(0, State.Fling.power, 0)
            -- Spike 2: Daya dorong gila
            getRoot().Velocity = Vector3.new(State.Fling.power, State.Fling.power, State.Fling.power)
            
            RS.RenderStepped:Wait()
            
            -- Balikin normal biar gak mental sendiri (Client-Side)
            getRoot().Velocity = oldVel
        end
        RS.RenderStepped:Wait()
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ➤  CORE FUNCTIONS                       │
-- └─────────────────────────────────────────────────────────┘
local function instantRE()
    if getRoot() then
        local cf = getRoot().CFrame
        getHum().Health = 0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = cf
        Library:Notification("Admin", "Instant Refresh Done!", 2)
    end
end
LP.Chatted:Connect(function(m) if m:lower() == ";re" then instantRE() end end)

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
-- │                   ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB V9.3", "star", "IY FLING LOCK", false)

-- --- TAB 1: TELEPORT ---
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

-- --- TAB 2: PLAYER ---
local T_PL = Win:Tab("Player", "user")
local PLP = T_PL:Page("Settings", "zap")
local PLM = PLP:Section("⚡ Movement", "Left")
local PLH = PLP:Section("🚀 Hacks", "Right")
local PLW = PLP:Section("🌦️ Atmosphere", "Left")

PLM:Button("🔄 Refresh Char (;re)", "Fix Glitch", function() instantRE() end)
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) if getHum() then getHum().WalkSpeed = v end end)
PLM:Toggle("Infinite Jump", "ij", false, "No Jump Cooldown", function(v) 
    if v then State.Move.infJ = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if State.Move.infJ then State.Move.infJ:Disconnect() end end
end)

PLH:Toggle("Native Fly", "nf", false, "Joystick Support", function(v) toggleFly(v) end)
PLH:Slider("Fly Speed", "fs", 10, 500, 60, function(v) State.Move.flyS = v end)
PLH:Toggle("NoClip", "nc", false, "Tembus", function(v) State.Move.ncp = v end)
PLH:Toggle("Invisible (R15)", "inv", false, "Remove Torso", function(v) 
    if v and LP.Character:FindFirstChild("LowerTorso") then LP.Character.LowerTorso:Destroy() end 
end)
PLH:Toggle("IY Fling Mode", "ffm", false, "TABRAK = MENTAL", function(v) 
    State.Fling.active = v 
    State.Move.ncp = v -- Wajib Noclip biar gak mental sendiri
end)

PLW:Slider("Waktu (ClockTime)", "time", 0, 24, 12, function(v) Lighting.ClockTime = v end)
PLW:Button("☀️ Set Siang", "Day Time", function() Lighting.ClockTime = 14 end)

-- --- TAB 3: SECURITY ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")

SCP:Toggle("Anti-AFK Mode", "afk", false, "No Kick", function(v)
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

Library:Notification("XKID MASTER V9.3", "IY Fling Ready! Sikat, Bro!", 5)
