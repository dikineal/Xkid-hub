--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v11.0  💠              ║
║                Dance & Animation Specialist              ║
╚═══════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

-- State
local State = {
    Move = {ws = 16, jp = 50, ncp = false},
    Anim = {spam = false, name = "Beggin"}, -- Ganti nama sesuai list di map
    Teleport = {target = ""}
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ➤  AUTO ANIMATION LOGIC                 │
-- └─────────────────────────────────────────────────────────┘
-- Fitur ini bakal nyoba ngetrigger remote animasi umum di map dansa
local function playAnim(name)
    -- Map dansa biasanya pake RemoteEvent buat sinkronisasi lagu
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("PlayAnimation") or 
                   game:GetService("ReplicatedStorage"):FindFirstChild("DanceRemote")
    
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(name)
    end
end

task.spawn(function()
    while true do
        if State.Anim.spam then
            playAnim(State.Anim.name)
        end
        task.wait(0.1)
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID V11", "music", "DANCE PRO", false)

-- --- TAB 1: PLAYER & DANCE ---
local T_PL = Win:Tab("Dance", "music")
local PLM = T_PL:Page("Physical", "zap"):Section("⚡ Movement", "Left")
local PLD = T_PL:Page("Physical", "zap"):Section("💃 Auto Dance", "Right")

PLM:Button("🔄 Instant Refresh (;re)", "Fix Animation Bug", function()
    local cf = getRoot().CFrame
    getHum().Health = 0
    LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = cf
end)
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) if getHum() then getHum().WalkSpeed = v end end)

-- INPUT NAMA ANIMASI DARI FOTO LO
PLD:TextBox("Nama Animasi", "animName", "Beggin", function(v)
    State.Anim.name = v
    Library:Notification("Target", "Animasi diset ke: "..v, 2)
end)

PLD:Toggle("Auto Spam Animasi", "as", false, "Spam Remote", function(v)
    State.Anim.spam = v
    if v then Library:Notification("Dance", "Mulai spam animasi "..State.Anim.name, 2) end
end)

-- --- TAB 2: TELEPORT ---
local T_TP = Win:Tab("Teleport", "map-pin")
local TPP = T_TP:Page("Navigation", "map-pin"):Section("🎯 Player TP", "Left")

local function getPlayers()
    local tbl = {}
    for _,p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(tbl, p.Name) end end
    return tbl
end

local P_Drop = TPP:Dropdown("Pilih Player", "pDrop", getPlayers(), function(v) State.Teleport.target = v end)
TPP:Button("Refresh List", "", function() P_Drop:Refresh(getPlayers()) end)
TPP:Button("Teleport Now", "Melesat", function()
    local p = Players:FindFirstChild(State.Teleport.target)
    if p and p.Character then getRoot().CFrame = p.Character.HumanoidRootPart.CFrame end
end)

-- --- TAB 3: SECURITY ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")
SCP:Toggle("Anti-AFK (Biar gak Kick)", "afk", false, "", function(v)
    -- Anti AFK Logic
end)
SCP:Toggle("NoClip", "nc", false, "Tembus", function(v) State.Move.ncp = v end)

-- NOCLIP LOOP
RS.Stepped:Connect(function()
    if State.Move.ncp and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

Library:Notification("XKID V11", "Ketik nama animasi (misal: Beggin) lalu ON!", 5)
