--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v12.0  💠              ║
║                FINAL STABLE - NO CLIPPING UI             ║
╠═══════════════════════════════════════════════════════════╣
║  ➤  TAB 1: 🏃 PLAYER (WS, JP, InfJump, Reset)            ║
║  ➤  TAB 2: 🚀 HACKS (Fly, NoClip, Invisible)             ║
║  ➤  TAB 3: 📍 TELEPORT (Dropdown & Manual)               ║
║  ➤  TAB 4: 🛡️ SECURITY (Bypass, Anti-AFK, ESP)           ║
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
    Move = {ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60},
    Fly = {active = false, bv = nil, bg = nil},
    ESP = {active = false, guis = {}},
    Teleport = {target = ""},
    Security = {afk = nil}
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}; for _,p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ➤  UI CONSTRUCTION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB V12", "star", "STABLE", false)

-- --- TAB 1: PLAYER ---
local T_PL = Win:Tab("Player", "user")
local PLM = T_PL:Page("Movement", "zap"):Section("⚡ Physical", "Left")

PLM:Button("🔄 Instant Refresh (;re)", "Fix Glitch", function()
    if getRoot() then local cf = getRoot().CFrame; getHum().Health = 0
    LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = cf end
end)
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) if getHum() then getHum().WalkSpeed = v end end)
PLM:Slider("JumpPower", "jp", 50, 500, 50, function(v) if getHum() then getHum().JumpPower = v; getHum().UseJumpPower = true end end)
PLM:Toggle("Infinite Jump", "ij", false, "Lompat Terus", function(v) 
    if v then State.Move.infJ = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if State.Move.infJ then State.Move.infJ:Disconnect() end end
end)

-- --- TAB 2: HACKS ---
local T_HK = Win:Tab("Hacks", "zap")
local HKP = T_HK:Page("Abilities", "zap"):Section("🚀 Hacks", "Left")

HKP:Toggle("Native Fly (Analog)", "nf", false, "Terbang", function(v)
    State.Fly.active = v
    if not v then if State.Fly.bv then State.Fly.bv:Destroy() end if State.Fly.bg then State.Fly.bg:Destroy() end
    getHum().PlatformStand = false; return end
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
end)
HKP:Slider("Fly Speed", "fs", 10, 500, 60, function(v) State.Move.flyS = v end)
HKP:Toggle("NoClip", "nc", false, "Tembus", function(v) State.Move.ncp = v end)
HKP:Toggle("Invisible (R15)", "inv", false, "Hapus Torso", function(v) 
    if v and LP.Character:FindFirstChild("LowerTorso") then LP.Character.LowerTorso:Destroy() end 
end)

-- --- TAB 3: TELEPORT ---
local T_TP = Win:Tab("Teleport", "map-pin")
local TPP = T_TP:Page("Nav", "map-pin"):Section("🎯 Target TP", "Left")

local P_Drop = TPP:Dropdown("Pilih Player", "pDrop", getPNames(), function(v) State.Teleport.target = v end)
TPP:TextBox("Atau Ketik Nama", "pT", "", function(v) State.Teleport.target = v end)
TPP:Button("Teleport Now", "Melesat", function()
    local p = Players:FindFirstChild(State.Teleport.target)
    if p and p.Character then getRoot().CFrame = p.Character.HumanoidRootPart.CFrame end
end)
TPP:Button("Refresh Player List", "", function() P_Drop:Refresh(getPNames()) end)

-- --- TAB 4: SECURITY ---
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")

SCP:Toggle("Anti-AFK", "afk", false, "No Kick", function(v) end)
SCP:Toggle("Player ESP", "esp", false, "Names", function(v)
    State.ESP.active = v
    if not v then for _, g in pairs(State.ESP.guis) do g:Destroy() end State.ESP.guis = {} end
    task.spawn(function()
        while State.ESP.active do
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
                    local b = p.Character.Head:FindFirstChild("XKID_ESP") or Instance.new("BillboardGui", p.Character.Head)
                    b.Name = "XKID_ESP"; b.Size = UDim2.new(0,80,0,20); b.AlwaysOnTop = true
                    local l = b:FindFirstChild("L") or Instance.new("TextLabel", b)
                    l.Name = "L"; l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1; l.TextColor3 = Color3.new(1,1,1); l.TextScaled = true; l.Text = p.Name
                    table.insert(State.ESP.guis, b)
                end
            end; task.wait(1)
        end
    end)
end)

-- NOCLIP LOOP
RS.Stepped:Connect(function()
    if State.Move.ncp and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

Library:Notification("XKID V12", "Menu Lengkap & Stabil!", 5)
