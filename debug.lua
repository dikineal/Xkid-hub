--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v3.0   💠              ║
║                  Aurora UI  ·  Refresh Update            ║
╠═══════════════════════════════════════════════════════════╣
║  ➤  UI CACHE BYPASS (Forced Render)                       ║
║  ➤  Refresh Button Relocated to Right Column              ║
╚═══════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- Services
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService   = game:GetService("TeleportService")
local Workspace   = game:GetService("Workspace")
local LP          = Players.LocalPlayer

-- Global State
local State = {
    Move = {speed = 16, jump = 50, flySpeed = 60, noclip = false},
    Fly = {active = false, conn = nil, bv = nil, bg = nil},
    ESP = {active = false, guis = {}, conn = nil},
    Security = {afk = nil, lastCF = nil},
    Teleport = {target = "", slots = {}}
}

local function getChar() return LP.Character end
local function getHum() return getChar() and getChar():FindFirstChildOfClass("Humanoid") end
local function getRoot() return getChar() and getChar():FindFirstChild("HumanoidRootPart") end
local function notify(t, b, d) pcall(function() Library:Notification(t, b, d or 3) end) end

-- ┌─────────────────────────────────────────────────────────┐
-- │             ➤  CORE ENGINE (STABILITY)                  │
-- └─────────────────────────────────────────────────────────┘

RunService.Heartbeat:Connect(function()
    local r, h = getRoot(), getHum()
    if r and h and h.Health > 0 then
        State.Security.lastCF = r.CFrame
    end
end)

RunService.Stepped:Connect(function()
    if State.Move.noclip and getChar() then
        for _, v in pairs(getChar():GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

local function toggleFly(v)
    if not v then
        State.Fly.active = false
        if State.Fly.conn then State.Fly.conn:Disconnect() end
        if State.Fly.bv then State.Fly.bv:Destroy() end
        if State.Fly.bg then State.Fly.bg:Destroy() end
        if getHum() then getHum().PlatformStand = false; getHum():ChangeState(1) end
        return
    end
    local r, h = getRoot(), getHum()
    if not r or not h then return end
    State.Fly.active = true; h.PlatformStand = true
    State.Fly.bv = Instance.new("BodyVelocity", r); State.Fly.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    State.Fly.bg = Instance.new("BodyGyro", r); State.Fly.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); State.Fly.bg.P = 1e5
    State.Fly.conn = RunService.RenderStepped:Connect(function()
        if not State.Fly.active or not r.Parent then toggleFly(false); return end
        h.PlatformStand = true
        local cam = Workspace.CurrentCamera; local md = h.MoveDirection
        if md.Magnitude > 0 then
            local pitch = cam.CFrame.LookVector.Y
            local dot = md:Dot(cam.CFrame.LookVector * Vector3.new(1,0,1).Unit)
            State.Fly.bv.Velocity = Vector3.new(md.X * State.Move.flySpeed, pitch * State.Move.flySpeed * dot, md.Z * State.Move.flySpeed)
        else
            State.Fly.bv.Velocity = Vector3.new(0, 0, 0)
        end
        State.Fly.bg.CFrame = cam.CFrame
    end)
end

local function updateESP()
    for _, g in pairs(State.ESP.guis) do if g then g:Destroy() end end
    State.ESP.guis = {}
    if not State.ESP.active then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            local b = Instance.new("BillboardGui", p.Character.Head); b.Size = UDim2.new(0,100,0,24); b.AlwaysOnTop = true; b.StudsOffset = Vector3.new(0,3,0)
            local f = Instance.new("Frame", b); f.Size = UDim2.new(1,0,1,0); f.BackgroundColor3 = Color3.new(0,0,0); f.BackgroundTransparency = 0.5; Instance.new("UICorner", f)
            local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1,0,1,0); l.TextColor3 = Color3.fromRGB(255, 220, 50); l.TextScaled = true; l.Font = Enum.Font.Code; l.Text = p.Name
            table.insert(State.ESP.guis, b)
        end
    end
end

local function executeRefresh()
    local r = getRoot()
    if r then
        local oldCF = r.CFrame
        getHum().Health = 0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = oldCF
        notify("Refresh", "Karakter diperbarui!", 2)
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   ➤  UI SETUP (AESTHETIC)               │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID V3", "diamond", "REFRESH UPDATE", false)
local T_TP = Win:Tab("Teleport", "map-pin")
local T_PL = Win:Tab("Player", "user")
local T_SC = Win:Tab("Security", "shield")

-- --- TELEPORT PAGE ---
local TP_P = T_TP:Page("Navigation", "map-pin")
local TPT = TP_P:Section("🎯 Target Player", "Left")
local TPS = TP_P:Section("💾 Locations", "Right")

TPT:Dropdown("Select Player", "pSelect", {}, function(v) State.Teleport.target = v end)
TPT:TextBox("Manual Search", "pText", "", function(v) State.Teleport.target = v end)
TPT:Button("🚀 Teleport to Target", "Exec TP", function()
    local p = Players:FindFirstChild(State.Teleport.target)
    if p and p.Character then getRoot().CFrame = p.Character.HumanoidRootPart.CFrame end
end)
TPT:Button("🏠 Back to Spawn", "Reset Posisi", function()
    local spawns = {}
    for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("SpawnLocation") then table.insert(spawns, v) end end
    if #spawns > 0 then getRoot().CFrame = spawns[math.random(1, #spawns)].CFrame + Vector3.new(0, 5, 0) end
end)

for i = 1, 3 do
    TPS:Button("💾 Save Slot "..i, "Store Slot "..i, function() State.Teleport.slots[i] = getRoot().CFrame; notify("Slot "..i, "Tersimpan!") end)
    TPS:Button("📍 Load Slot "..i, "TP Slot "..i, function() if State.Teleport.slots[i] then getRoot().CFrame = State.Teleport.slots[i] end end)
end

-- --- PLAYER PAGE ---
local PL_P = T_PL:Page("Movement", "zap")
local PLM = PL_P:Section("⚡ Physical", "Left")
local PLV = PL_P:Section("🚀 Hacks & Utility", "Right")

-- FUNGSI FISIK (KIRI)
PLM:Slider("Walk Speed", "ws", 16, 500, 16, function(v) State.Move.speed = v; if getHum() then getHum().WalkSpeed = v end end)
PLM:Slider("Jump Power", "jp", 50, 500, 50, function(v) State.Move.jump = v; if getHum() then getHum().JumpPower = v; getHum().UseJumpPower = true end end)
PLM:Toggle("Infinite Jump", "infj", false, "Lompat Terus", function(v)
    if v then State.Move.jumpConn = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if State.Move.jumpConn then State.Move.jumpConn:Disconnect() end end
end)

-- FUNGSI HACKS (KANAN) - TOMBOL REFRESH DI SINI
PLV:Button("🔄 Refresh Character", "Reset & Restore", function() executeRefresh() end)
PLV:Toggle("Native Fly", "nfly", false, "Joystick Support", function(v) toggleFly(v) end)
PLV:Slider("Fly Speed", "fs", 10, 500, 60, function(v) State.Move.flySpeed = v end)
PLV:Toggle("NoClip", "ncp", false, "Tembus Dinding", function(v) State.Move.noclip = v end)
PLV:Toggle("Pro ESP", "pesp", false, "Visual Pro", function(v) State.ESP.active = v; updateESP() end)

-- --- SECURITY PAGE ---
local SC_P = T_SC:Page("Security", "shield")
local SCS = SC_P:Section("🛡️ Protection", "Left")

SCS:Toggle("Anti-Cheat Bypass", "hbp", false, "Hook Metatable", function(v)
    if v then 
        local mt = getrawmetatable(game); setreadonly(mt, false); local old = mt.__index
        mt.__index = newcclosure(function(t, k)
            if not checkcaller() and t:IsA("Humanoid") and (k == "WalkSpeed" or k == "JumpPower") then return (k == "WalkSpeed" and 16 or 50) end
            return old(t, k)
        end); setreadonly(mt, true)
    end
end)
SCS:Toggle("Anti AFK", "aafk", false, "No Kick", function(v)
    if v then State.Security.afk = LP.Idled:Connect(function() VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame) end)
    else if State.Security.afk then State.Security.afk:Disconnect() end end
end)

SCS:Button("⚡ Fast Respawn", "Instant TP Back", function()
    if State.Security.lastCF then
        local target = State.Security.lastCF; getHum().Health = 0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = target
        notify("Respawn", "Sukses kembali!", 2)
    end
end)

notify("XKID V3", "Skrip Berhasil Diperbarui!", 5)

