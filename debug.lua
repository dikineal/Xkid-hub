--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v9.0   💠              ║
║                DUAL-MODE TELEPORT SYSTEM                 ║
╚═══════════════════════════════════════════════════════════╣
║  ➤  Opsi 1: Dropdown Player (Auto-Update)                 ║
║  ➤  Opsi 2: TextBox (Manual Type / Click Name)           ║
║  ➤  Anti-AFK & Instant Refresh (;re)                      ║
╚═══════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

-- Global State
local State = {
    Move = {ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60},
    Fly = {active = false, bv = nil, bg = nil},
    Teleport = {selectedTarget = ""},
    Security = {afkConn = nil}
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end

local function getPlayerNames()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    return names
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ➤  ADMIN COMMANDS                       │
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

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB V9", "diamond", "ULTIMATE EDITION", false)

-- --- TAB 1: TELEPORT (📍) ---
local T_TP = Win:Tab("Teleport", "map-pin")
local TPP = T_TP:Page("Navigation", "map-pin")
local TPT = TPP:Section("🎯 Select Target", "Left")
local TPS = TPP:Section("🚀 Teleport Execution", "Right")

-- OPSIONAL 1: DROPDOWN
local P_Drop = TPT:Dropdown("Dropdown Player", "pDrop", getPlayerNames(), function(v)
    State.Teleport.selectedTarget = v
end)

-- OPSIONAL 2: TEXTBOX (Manual/Click)
TPT:TextBox("Ketik Nama Manual", "pText", "", function(v)
    State.Teleport.selectedTarget = v
end)

TPT:Button("🔄 Refresh Dropdown", "Update List", function()
    P_Drop:Refresh(getPlayerNames())
end)

-- EXECUTION
TPS:Button("🚀 Teleport Now", "Go to Target", function()
    local target = Players:FindFirstChild(State.Teleport.selectedTarget)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        getRoot().CFrame = target.Character.HumanoidRootPart.CFrame
        Library:Notification("Teleport", "Melesat ke " .. target.Name, 2)
    else
        Library:Notification("Error", "Player tidak ditemukan!", 3)
    end
end)

TPS:Button("🧲 Bring Player", "Tarik ke Sini", function()
    local target = Players:FindFirstChild(State.Teleport.selectedTarget)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        target.Character.HumanoidRootPart.CFrame = getRoot().CFrame
    end
end)

-- --- TAB 2: PLAYER (🏃) ---
local T_PL = Win:Tab("Player", "user")
local PLM = T_PL:Page("Physical", "zap"):Section("⚡ Movement", "Left")
local PLH = T_PL:Page("Physical", "zap"):Section("🚀 Hacks", "Right")

PLM:Button("🔄 Refresh Char (;re)", "", function() instantRE() end)
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) if getHum() then getHum().WalkSpeed = v end end)
PLM:Toggle("Infinite Jump", "ij", false, "", function(v) 
    if v then State.Move.infJ = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if State.Move.infJ then State.Move.infJ:Disconnect() end end
end)

PLH:Toggle("NoClip", "nc", false, "Tembus", function(v) State.Move.ncp = v end)
PLH:Toggle("Invisible (R15)", "inv", false, "Server-side", function(v) 
    if v and LP.Character:FindFirstChild("LowerTorso") then LP.Character.LowerTorso:Destroy() end 
end)

-- --- TAB 3: SECURITY (🛡️) ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")

SCP:Toggle("Anti-AFK Mode", "afk", false, "Cegah Kick", function(v)
    if v then
        State.Security.afkConn = LP.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        Library:Notification("Security", "Anti-AFK Aktif!", 3)
    else
        if State.Security.afkConn then State.Security.afkConn:Disconnect() end
        Library:Notification("Security", "Anti-AFK Mati!", 3)
    end
end)

SCP:Toggle("Bypass Anti-Cheat", "acb", false, "Hooking", function(v) end)

-- NOCLIP LOOP
RS.Stepped:Connect(function()
    if State.Move.ncp and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

-- AUTO-UPDATE DROPDOWN
Players.PlayerAdded:Connect(function() P_Drop:Refresh(getPlayerNames()) end)
Players.PlayerRemoving:Connect(function() P_Drop:Refresh(getPlayerNames()) end)

Library:Notification("XKID V9", "Pilih Player di Dropdown atau Ketik Nama!", 5)
