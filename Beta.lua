--[[
╔═══════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.26  🌟              ║
║                  Aurora UI  ·  Pro Edition               ║
╠═══════════════════════════════════════════════════════════╣
║  Teleport  ·  Player  ·  Security  ·  Setting                ║
║  [UPDATE] Pro ESP, Inf Jump, Rejoin, TP Player           ║
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

-- Helper Functions
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function notify(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
end

-- State Management
local lastCFrame
local SavedLoc = {nil, nil, nil, nil, nil}
local Respawn = {savedPosition = nil, busy = false}
local Move = {speed = 16, flySpeed = 60, noclip = false, noclipConn = nil, jumpConn = nil}
local flyFlying = false; local flyConn = nil; local flyBV = nil; local flyBG = nil
local ESPPl = {active = false, data = {}, conn = nil}

-- Heartbeat Position Tracker
RunService.Heartbeat:Connect(function()
    local r = getRoot()
    if r then 
        lastCFrame = r.CFrame 
        Respawn.savedPosition = r.CFrame
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │                   PLAYER UTILITIES                      │
-- └─────────────────────────────────────────────────────────┘
local function setNoclip(v)
    Move.noclip = v
    if v then
        if Move.noclipConn then Move.noclipConn:Disconnect() end
        Move.noclipConn = RunService.Stepped:Connect(function()
            local c = getChar(); if not c then return end
            for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
        end)
    else
        if Move.noclipConn then Move.noclipConn:Disconnect(); Move.noclipConn = nil end
        local c = getChar()
        if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    end
end

local function setInfJump(v)
    if v then
        if Move.jumpConn then Move.jumpConn:Disconnect() end
        Move.jumpConn = UIS.JumpRequest:Connect(function()
            local h = getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else 
        if Move.jumpConn then Move.jumpConn:Disconnect(); Move.jumpConn = nil end 
    end
end

-- Fly Logic
local ControlModule = nil
pcall(function()
    ControlModule = require(LP:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
end)

local function getMoveVector()
    if ControlModule then
        local ok, result = pcall(function() return ControlModule:GetMoveVector() end)
        if ok and result then return result end
    end
    return Vector3.new(
        (UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
        0,
        (UIS:IsKeyDown(Enum.KeyCode.W) and -1 or 0) + (UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0))
end

local function startFly()
    if flyFlying then return end
    local root = getRoot(); if not root then return end
    local hum = getHum(); if not hum then return end
    flyFlying = true; hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity", root)
    flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6); flyBV.Velocity = Vector3.zero
    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6); flyBG.P = 1e5; flyBG.D = 1e3
    flyConn = RunService.RenderStepped:Connect(function(dt)
        local r2 = getRoot(); local h2 = getHum()
        if not r2 or not h2 then return end
        local cam = Workspace.CurrentCamera; local cf = cam.CFrame
        h2.PlatformStand = true; h2:ChangeState(Enum.HumanoidStateType.Physics)
        local md = getMoveVector()
        local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        if look.Magnitude > 0 then look = look.Unit end
        local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
        if right.Magnitude > 0 then right = right.Unit end
        local move = right * md.X + look * (-md.Z)
        local pitch = cf.LookVector.Y; local vVel = 0
        if math.abs(pitch) > 0.25 then vVel = math.sign(pitch) * Move.flySpeed * 0.6 end
        flyBV.Velocity = Vector3.new(move.X * Move.flySpeed, vVel, move.Z * Move.flySpeed)
        flyBG.CFrame = CFrame.lookAt(r2.Position, r2.Position + Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z))
    end)
end

local function stopFly()
    flyFlying = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.Running) end
end

-- PRO ESP Player
local function _mkPlBill(p)
    if p == LP or ESPPl.data[p] then return end
    if not p.Character then return end
    local head = p.Character:FindFirstChild("Head"); if not head then return end
    local bill = Instance.new("BillboardGui", head)
    bill.Name = "XKID_ESP"; bill.Size = UDim2.new(0, 150, 0, 15); bill.AlwaysOnTop = true; bill.StudsOffset = Vector3.new(0, 3, 0)
    local lbl = Instance.new("TextLabel", bill)
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(0, 255, 128); lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); lbl.TextStrokeTransparency = 0
    lbl.TextSize = 12; lbl.Font = Enum.Font.Code -- Tampilan Pro/Hacker
    ESPPl.data[p] = {bill = bill, lbl = lbl}
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   GUI INITIALIZATION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB", "shield", "v5.26", false)
local T_TP = Win:Tab("Teleport", "map-pin")
local T_Pl = Win:Tab("Player", "user")
local T_Sec = Win:Tab("Security", "shield")

-- TAB TELEPORT
local TP_P = T_TP:Page("Teleport", "map-pin")
local TPR = TP_P:Section("💾 Save & Load", "Left")
local TPL = TP_P:Section("🎯 Teleport Player", "Right")

-- Teleport Player Logic
local targetName = ""
TPL:TextBox("Nama Player", "tpP", "", function(v) targetName = v end, "Ketik awalan nama")
TPL:Button("🚀 TP ke Player", "Teleport sekarang", function()
    if targetName == "" then notify("TP", "Ketik nama dulu!", 2); return end
    local best = nil
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Name:lower():sub(1, #targetName) == targetName:lower() then best = p; break end
    end
    if best and best.Character and best.Character:FindFirstChild("HumanoidRootPart") then
        getRoot().CFrame = best.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
        notify("TP", "Sukses TP ke " .. best.Name, 2)
    else
        notify("TP", "Player tidak ditemukan!", 2)
    end
end)

for i = 1, 3 do
    TPR:Button("💾 Save Slot " .. i, "Simpan posisi", function() SavedLoc[i] = getRoot().CFrame; notify("Save", "Slot " .. i .. " tersimpan") end)
    TPR:Button("📍 Load Slot " .. i, "Teleport", function() if SavedLoc[i] then getRoot().CFrame = SavedLoc[i]; notify("Load", "TP ke Slot " .. i) end end)
end

-- TAB PLAYER
local PL = T_Pl:Page("Movement", "user"):Section("⚡ Speed & Jump", "Left")
local PR = T_Pl:Page("Movement", "user"):Section("🚀 Fly & Visual", "Right")

PL:Slider("Walk Speed", "ws", 16, 500, 16, function(v) Move.speed = v; getHum().WalkSpeed = v end)
PL:Slider("Jump Power", "jp", 50, 500, 50, function(v) getHum().JumpPower = v; getHum().UseJumpPower = true end)
PL:Toggle("Infinite Jump", "infj", false, "Lompat di udara", function(v) setInfJump(v) end)
PR:Toggle("Fly", "fly", false, "Terbang", function(v) if v then startFly() else stopFly() end end)
PR:Toggle("NoClip", "nc", false, "Tembus Dinding", function(v) setNoclip(v) end)

PR:Toggle("Pro ESP", "esp", false, "Nama & Jarak", function(v)
    ESPPl.active = v
    if v then 
        for _, p in pairs(Players:GetPlayers()) do _mkPlBill(p) end
        ESPPl.conn = RunService.Heartbeat:Connect(function()
            local myRoot = getRoot()
            for p, d in pairs(ESPPl.data) do
                if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
                    d.lbl.Visible = false
                else
                    d.lbl.Visible = true
                    if myRoot then
                        local dist = math.floor((p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude)
                        d.lbl.Text = string.format("%s [%dm]", p.Name, dist)
                    else
                        d.lbl.Text = p.Name
                    end
                end
            end
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and not ESPPl.data[p] then _mkPlBill(p) end
            end
        end)
    else 
        if ESPPl.conn then ESPPl.conn:Disconnect(); ESPPl.conn = nil end 
        for p, d in pairs(ESPPl.data) do if d.bill then d.bill:Destroy() end end
        ESPPl.data = {}
    end
end)

-- TAB SECURITY
local SL = T_Sec:Page("Security", "shield"):Section("🛡️ Protection", "Left")
local SR = T_Sec:Page("Security", "shield"):Section("🔄 System", "Right")

SL:Toggle("Anti AFK", "afk", false, "Cegah Kick Idle", function(v)
    if v then LP.Idled:Connect(function() VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame) end) end
end)

SL:Button("⚡ Fast Respawn", "Mati & TP balik", function()
    if Respawn.savedPosition then
        local old = Respawn.savedPosition
        getHum().Health = 0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = old
        notify("Respawn", "Sukses kembali!")
    end
end)

SR:Button("🔄 Rejoin Server", "Masuk ulang ke game", function()
    notify("Rejoin", "Menyambung ulang...")
    TpService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end)

notify("XKID HUB", "Pro Update Loaded!")
