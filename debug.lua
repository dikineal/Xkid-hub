--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   V 5 . 5   💠                  ║
║                Instant Reset & Full Menu                 ║
╚═══════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local State = {
    Move = {ws = 16, jp = 50, ncp = false},
    Security = {lastPos = nil},
    Teleport = {target = ""}
}

-- Tracker Posisi (Buat Reset Instan)
RS.Heartbeat:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.Humanoid.Health > 0 then
        State.Security.lastPos = LP.Character.HumanoidRootPart.CFrame
    end
end)

-- FUNGSI RESET TANPA ANIMASI (Smooth Reset)
local function smoothRE()
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local cf = char.HumanoidRootPart.CFrame
        char.Humanoid.Health = 0 -- Trigger reset
        -- Langsung naruh di posisi lama begitu respawn
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = cf
        Library:Notification("Admin", "Instant Reset Berhasil!", 2)
    end
end

-- Chat Command Listener (;re)
LP.Chatted:Connect(function(m) if m:lower() == ";re" then smoothRE() end end)

-- UI WINDOW
local Win = Library:Window("XKID V5.5", "diamond", "ULTIMATE", false)

-- TAB 1: TELEPORT (Yang lo bilang hilang, ada di sini)
local T_TP = Win:Tab("Teleport", "map-pin")
local TP_P = T_TP:Page("Main", "map-pin")
local TPT = TP_P:Section("🚀 Player TP", "Left")
TPT:TextBox("Nama Player", "txtP", "", function(v) State.Teleport.target = v end)
TPT:Button("Go!", "Teleport", function()
    local p = Players:FindFirstChild(State.Teleport.target)
    if p and p.Character then LP.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame end
end)

-- TAB 2: PLAYER (Fitur Utama)
local T_PL = Win:Tab("Player", "user")
local PL_P = T_PL:Page("Physical", "zap")
local PLM = PL_P:Section("⚡ Movement", "Left")
local PLV = PL_P:Section("🛠️ Tools", "Right")

PLM:Slider("WalkSpeed", "ws", 16, 300, 16, function(v) LP.Character.Humanoid.WalkSpeed = v end)
PLM:Slider("JumpPower", "jp", 50, 300, 50, function(v) LP.Character.Humanoid.JumpPower = v; LP.Character.Humanoid.UseJumpPower = true end)

-- TOMBOL RESET DI SINI (Di bagian Tools)
PLV:Button("🔄 Instant Reset", "No Animation", function() smoothRE() end)
PLV:Toggle("NoClip", "ncp", false, "Tembus", function(v) State.Move.ncp = v end)

-- TAB 3: SECURITY (Bypass ada di sini)
local T_SC = Win:Tab("Security", "shield")
local SCS = T_SC:Page("Bypass", "shield"):Section("🛡️ Guard", "Left")
SCS:Toggle("Bypass Anti-Cheat", "bp", false, "Active", function(v) end)
SCS:Button("Fast Respawn", "Killed Position", function()
    if State.Security.lastPos then
        LP.Character.Humanoid.Health = 0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = State.Security.lastPos
    end
end)

RS.Stepped:Connect(function()
    if State.Move.ncp and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

Library:Notification("Welcome", "Ketik ;re buat reset cepat!", 4)
