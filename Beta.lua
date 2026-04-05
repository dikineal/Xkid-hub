--[[
╔═══════════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.26  🌟              ║
║                  Aurora UI  ·  Pro Edition               ║
╠═══════════════════════════════════════════════════════════════╣
║  Teleport  ·  Player  ·  Security  ·  Setting                ║
║  [FIXED] Delta Executor Compatibility Optimized          ║
╚═══════════════════════════════════════════════════════════════╝
]]

local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()
end)

if not success or not Library then 
    warn("XKID ERROR: Gagal memuat UI Library!")
    return 
end

-- Service Dasar
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService   = game:GetService("TeleportService")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")
local LP          = Players.LocalPlayer

-- Fungsi Helper
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end

local function notify(t, b, d)
    pcall(function() 
        if Library and Library.Notification then
            Library:Notification(t, b, d or 3) 
        end
    end)
    print(string.format("[XKID] %s | %s", t, b))
end

-- Variabel State
local lastCFrame
local Fish = { autoOn = false, fishTask = nil, waitDelay = 2, rodEquipped = false, totalFished = 0, instantDelay = 2 }
local Move = { flying = false, flySpeed = 60, speed = 16 }
local Respawn = { savedPosition = nil }
local ESPPl = { active = false, uis = {}, conn = nil }
local logLines = {}

-- Koneksi Event (Heartbeat & Fly)
local flyConn, noclipConn, infJumpConn, afkConn, antiKickConn

RunService.Heartbeat:Connect(function()
    local r = getRoot(); if r then lastCFrame = r.CFrame end
end)

-- Fishing Logic
local function getFishEv(name)
    local fr = RS:FindFirstChild("FishRemotes")
    return fr and fr:FindFirstChild(name)
end

local function equipRod()
    local bp = LP:FindFirstChildOfClass("Backpack")
    if not bp then return false end
    local rod = bp:FindFirstChild("AdvanceRod") or bp:FindFirstChild("Rod")
    if not rod then return false end
    pcall(function() rod.Parent = LP.Character end)
    task.wait(0.5)
    Fish.rodEquipped = true
    return true
end

local function castOnce()
    local castEv = getFishEv("CastEvent")
    if not castEv then return false end
    pcall(function() castEv:FireServer(true) end)
    task.wait(0.8)
    pcall(function() castEv:FireServer(false, Fish.instantDelay) end)
    task.wait(Fish.instantDelay)
    local miniEv = getFishEv("MiniGame")
    if miniEv then
        pcall(function() miniEv:FireServer(true) end)
        task.wait(0.2)
        pcall(function() miniEv:FireServer(true) end)
    end
    Fish.totalFished = Fish.totalFished + 1
    return true
end

-- Player Movement Functions
local function startFly()
    if Move.flying then return end
    Move.flying = true
    local r = getRoot()
    if not r then return end
    local bd = Instance.new("BodyVelocity")
    bd.Name = "XKID_Fly"
    bd.Parent = r
    bd.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyConn = RunService.RenderStepped:Connect(function()
        if not Move.flying or not r or not r.Parent then
            if bd then bd:Destroy() end
            if flyConn then flyConn:Disconnect() end
            return
        end
        local vel = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then vel = vel + r.CFrame.LookVector * Move.flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.S) then vel = vel - r.CFrame.LookVector * Move.flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.A) then vel = vel - r.CFrame.RightVector * Move.flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.D) then vel = vel + r.CFrame.RightVector * Move.flySpeed end
        bd.Velocity = vel
    end)
end

local function bringPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local tr = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local mr = getRoot()
    if tr and mr then
        tr.CFrame = mr.CFrame + Vector3.new(0, 3, 0)
        notify("Bring", "Pulled " .. targetPlayer.Name, 2)
    end
end

-- MAIN UI WINDOW
local Win = Library:CreateWindow("XKID HUB v5.26", false, 3)

-- Tabs
local T_Tele = Win:Tab("Teleport", "map-pin")
local T_Play = Win:Tab("Player", "user")
local T_Sec  = Win:Tab("Security", "shield")
local T_Set  = Win:Tab("Setting", "sliders")

-- PAGE: Teleport
local TeleP = T_Tele:Page("Teleport", "map-pin")
local TeleL = TeleP:Section("📍 Lokasi", "Left")
local TeleR = TeleP:Section("👥 Bring Player", "Right")

TeleL:Button("Spawn", "Balik ke awal", function()
    local r = getRoot()
    if r then r.CFrame = CFrame.new(0, 100, 0) end
end)

TeleR:Button("Pull Player 1", "Bring P1", function()
    local p = Players:FindFirstChild("Player1")
    if p then bringPlayer(p) else notify("Error", "Player1 tidak ada", 2) end
end)

-- PAGE: Player
local PlayP = T_Play:Page("Player", "user")
local PlayL = PlayP:Section("⚡ Movement", "Left")
local PlayR = PlayP:Section("🚀 Special", "Right")

PlayL:Slider("Speed", "ws", 16, 500, 16, function(v)
    local h = getHum()
    if h then h.WalkSpeed = v end
end)

PlayR:Toggle("Fly", "fly", false, "Terbang", function(v)
    if v then startFly() else Move.flying = false end
end)

-- PAGE: Setting (Auto Fish)
local SetP = T_Set:Page("Setting", "settings")
local SetL = SetP:Section("🎣 Auto Fishing", "Left")

SetL:Toggle("Auto Fish", "af", false, "Cast Loop", function(v)
    Fish.autoOn = v
    if v then
        task.spawn(function()
            while Fish.autoOn do
                if not Fish.rodEquipped then equipRod() end
                castOnce()
                task.wait(Fish.waitDelay)
            end
        end)
    end
end)

-- Finalize
notify("XKID Loaded", "Siap digunakan!", 4)
Library:ConfigSystem(Win)
