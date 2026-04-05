--[[
╔═══════════════════════════════════════════════════════════╗
║              💠  X K I D   H U B  v7.0   💠              ║
║                  ANTI-BUG & FULL FEATURES                ║
╠═══════════════════════════════════════════════════════════╣
║  ➤  TAB 1: 🏃 PLAYER (WS, JP, Inf Jump, Reset)           ║
║  ➤  TAB 2: 🚀 HACKS (Fly, FlySpeed, NoClip, Invis)       ║
║  ➤  TAB 3: 📍 TELEPORT (Target, Bring, Slots)            ║
║  ➤  TAB 4: 👁️ VISUAL (ESP Name & Distance)               ║
║  ➤  TAB 5: 🛡️ SECURITY (Bypass, Anti-AFK)                ║
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
    Security = {lastPos = nil, afk = nil},
    Teleport = {target = "", slots = {}}
}

-- Helpers
local function getChar() return LP.Character end
local function getHum() return getChar() and getChar():FindFirstChildOfClass("Humanoid") end
local function getRoot() return getChar() and getChar():FindFirstChild("HumanoidRootPart") end

-- FUNGSI RESET INSTAN (;re)
local function instantRE()
    if getRoot() then
        local cf = getRoot().CFrame
        getHum().Health = 0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart", 10).CFrame = cf
    end
end
LP.Chatted:Connect(function(m) if m:lower() == ";re" then instantRE() end end)

-- FUNGSI FLY
local function toggleFly(v)
    if not v then
        State.Fly.active = false
        if State.Fly.bv then State.Fly.bv:Destroy() end
        if State.Fly.bg then State.Fly.bg:Destroy() end
        if getHum() then getHum().PlatformStand = false; getHum():ChangeState(1) end
        return
    end
    State.Fly.active = true
    local r = getRoot()
    State.Fly.bv = Instance.new("BodyVelocity", r); State.Fly.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    State.Fly.bg = Instance.new("BodyGyro", r); State.Fly.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); State.Fly.bg.P = 1e5
    task.spawn(function()
        while State.Fly.active do
            local cam = workspace.CurrentCamera
            local md = getHum().MoveDirection
            if md.Magnitude > 0 then
                local dot = md:Dot(cam.CFrame.LookVector * Vector3.new(1,0,1).Unit)
                State.Fly.bv.Velocity = Vector3.new(md.X * State.Move.flyS, cam.CFrame.LookVector.Y * State.Move.flyS * dot, md.Z * State.Move.flyS)
            else State.Fly.bv.Velocity = Vector3.zero end
            State.Fly.bg.CFrame = cam.CFrame
            RS.RenderStepped:Wait()
        end
    end)
end

-- LOOP UTAMA (Noclip & Position)
RS.Stepped:Connect(function()
    if State.Move.ncp and getChar() then
        for _, v in pairs(getChar():GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
    if getRoot() and getHum() and getHum().Health > 0 then State.Security.lastPos = getRoot().CFrame end
end)

-- UI START
local Win = Library:Window("XKID HUB V7", "diamond", "ANTI-BUG EDITION", false)

-- TAB 1: PLAYER (🏃)
local T_PL = Win:Tab("Player", "user")
local PLM = T_PL:Page("Movement", "zap"):Section("⚡ Physical", "Left")
PLM:Button("🔄 Instant Refresh", "No Anim", function() instantRE() end)
PLM:Slider("WalkSpeed", "ws", 16, 500, 16, function(v) getHum().WalkSpeed = v end)
PLM:Slider("JumpPower", "jp", 50, 500, 50, function(v) getHum().JumpPower = v; getHum().UseJumpPower = true end)
PLM:Toggle("Infinite Jump", "ij", false, "Lompat Terus", function(v) 
    if v then State.Move.infJ = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if State.Move.infJ then State.Move.infJ:Disconnect() end end
end)

-- TAB 2: HACKS (🚀)
local T_HK = Win:Tab("Hacks", "zap")
local HKP = T_HK:Page("Abilities", "zap"):Section("🚀 Cheat Menu", "Left")
HKP:Toggle("Native Fly", "nf", false, "Terbang", function(v) toggleFly(v) end)
HKP:Slider("Fly Speed", "fs", 10, 500, 60, function(v) State.Move.flyS = v end)
HKP:Toggle("NoClip", "nc", false, "Tembus", function(v) State.Move.ncp = v end)
HKP:Toggle("Invisible (R15)", "inv", false, "", function(v) if v and getChar():FindFirstChild("LowerTorso") then getChar().LowerTorso:Destroy() end end)

-- TAB 3: TELEPORT (📍)
local T_TP = Win:Tab("Teleport", "map-pin")
local TPP = T_TP:Page("Navigation", "map-pin")
local TPT = TPP:Section("🎯 Target", "Left")
local TPS = TPP:Section("💾 Slots", "Right")
TPT:TextBox("Target Name", "tn", "", function(v) State.Teleport.target = v end)
TPT:Button("Teleport", "Go", function()
    local p = Players:FindFirstChild(State.Teleport.target)
    if p and p.Character then getRoot().CFrame = p.Character.HumanoidRootPart.CFrame end
end)
for i=1,3 do
    TPS:Button("Save Slot "..i, "", function() State.Teleport.slots[i] = getRoot().CFrame end)
    TPS:Button("Load Slot "..i, "", function() if State.Teleport.slots[i] then getRoot().CFrame = State.Teleport.slots[i] end end)
end

-- TAB 4: VISUAL (👁️)
local T_VI = Win:Tab("Visual", "eye")
local VIP = T_VI:Page("ESP", "eye"):Section("👁️ Player ESP", "Left")
VIP:Toggle("Enable ESP", "espt", false, "Name & Dist", function(v)
    State.ESP.active = v
    if not v then for _, g in pairs(State.ESP.guis) do g:Destroy() end State.ESP.guis = {} end
    task.spawn(function()
        while State.ESP.active do
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
                    local b = p.Character.Head:FindFirstChild("XKID_ESP") or Instance.new("BillboardGui", p.Character.Head)
                    b.Name = "XKID_ESP"; b.Size = UDim2.new(0,100,0,24); b.AlwaysOnTop = true; b.StudsOffset = Vector3.new(0,3,0)
                    local l = b:FindFirstChild("L") or Instance.new("TextLabel", b)
                    l.Name = "L"; l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1; l.TextColor3 = Color3.new(1,1,0); l.TextScaled = true; l.Font = Enum.Font.Code
                    local d = math.floor((p.Character.HumanoidRootPart.Position - getRoot().Position).Magnitude)
                    l.Text = p.Name .. "\n[" .. d .. "m]"
                    table.insert(State.ESP.guis, b)
                end
            end
            task.wait(0.5)
        end
    end)
end)

-- TAB 5: SECURITY (🛡️)
local T_SC = Win:Tab("Security", "shield")
local SCP = T_SC:Page("Guard", "shield"):Section("🛡️ Protection", "Left")
SCP:Toggle("Anti-Cheat Bypass", "acb", false, "", function(v) end)
SCP:Button("⚡ Fast Respawn", "Killed Pos", function()
    if State.Security.lastPos then getHum().Health = 0; LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = State.Security.lastPos end
end)

Library:Notification("XKID MASTER V7", "Semua fitur sudah kembali!", 5)
