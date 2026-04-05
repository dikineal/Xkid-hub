--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   V 5 . 0   💠                  ║
║                  VIP Admin Command Edition               ║
╠═══════════════════════════════════════════════════════════╣
║  ➤  Fitur VIP Gratis: Ketik ;re di chat untuk Refresh    ║
║  ➤  UI Refresh Button tetap ada di tab Player            ║
╚═══════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService   = game:GetService("TeleportService")
local Workspace   = game:GetService("Workspace")
local LP          = Players.LocalPlayer

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

-- Tracker Posisi Presisi
RunService.Heartbeat:Connect(function()
    local r, h = getRoot(), getHum()
    if r and h and h.Health > 0 then State.Security.lastCF = r.CFrame end
end)

-- NoClip
RunService.Stepped:Connect(function()
    if State.Move.noclip and getChar() then
        for _, v in pairs(getChar():GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

-- FUNGSI REFRESH UTAMA
local function executeRefresh()
    local r = getRoot()
    if r then
        local oldCF = r.CFrame
        getHum().Health = 0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = oldCF
        notify("Admin", "Karakter Di-refresh!", 2)
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │             ➤  ADMIN COMMAND LISTENER                   │
-- └─────────────────────────────────────────────────────────┘
LP.Chatted:Connect(function(msg)
    if msg:lower() == ";re" then
        executeRefresh()
    end
end)

-- Fly Logic
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

-- UI Setup
local Win = Library:Window("XKID V5", "diamond", "VIP ADMIN", false)
local T_TP = Win:Tab("Teleport", "map-pin")
local T_PL = Win:Tab("Player", "user")
local T_SC = Win:Tab("Security", "shield")

-- TAB PLAYER
local PL_P = T_PL:Page("Movement", "zap")
local PLM = PL_P:Section("⚡ Physical", "Left")
local PLV = PL_P:Section("🚀 Hacks & Utility", "Right")

PLM:Slider("Walk Speed", "ws", 16, 500, 16, function(v) if getHum() then getHum().WalkSpeed = v end end)
PLM:Slider("Jump Power", "jp", 50, 500, 50, function(v) if getHum() then getHum().JumpPower = v; getHum().UseJumpPower = true end end)
PLM:Toggle("Infinite Jump", "infj", false, "Jump", function(v)
    if v then State.Move.jumpConn = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if State.Move.jumpConn then State.Move.jumpConn:Disconnect() end end
end)

PLV:Button("🔄 Refresh Character", "Fix Glitch/Stun", function() executeRefresh() end)
PLV:Toggle("Native Fly", "nfly", false, "Joystick Support", function(v) toggleFly(v) end)
PLV:Slider("Fly Speed", "fs", 10, 500, 60, function(v) State.Move.flySpeed = v end)
PLV:Toggle("NoClip", "ncp", false, "Tembus Dinding", function(v) State.Move.noclip = v end)

-- TAB SECURITY
local SCS = T_SC:Page("Security", "shield"):Section("🛡️ Protection", "Left")
SCS:Button("⚡ Fast Respawn", "TP Back", function()
    if State.Security.lastCF then
        local t = State.Security.lastCF; getHum().Health = 0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = t
    end
end)
SCS:Toggle("Anti AFK", "afk", false, "Anti Kick", function(v)
    if v then State.Security.afk = LP.Idled:Connect(function() VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame) end)
    else if State.Security.afk then State.Security.afk:Disconnect() end end
end)

notify("XKID V5", "Ketik ;re di chat untuk refresh!", 5)
