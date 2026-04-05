--[[
╔═══════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.26  🌟              ║
║                  Aurora UI  ·  Pro Edition               ║
╠═══════════════════════════════════════════════════════════╣
║  [ULTIMATE MOBILE FIX] Native Joystick Fly Protocol      ║
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

-- Global Functions
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
local Move = {speed = 16, flySpeed = 60, jumpConn = nil}
local flyFlying = false; local flyConn = nil; local flyBV = nil; local flyBG = nil
local Respawn = {savedPosition = nil}
local chatBypassActive = false
local afkConn = nil

-- ┌─────────────────────────────────────────────────────────┐
-- │             100% NATIVE MOBILE FLY LOGIC                │
-- └─────────────────────────────────────────────────────────┘
local function stopFly()
    flyFlying = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false; hum:ChangeState(1) end
end

local function startFly()
    if flyFlying then stopFly() end
    local root = getRoot(); local hum = getHum()
    if not root or not hum then return end
    flyFlying = true; hum.PlatformStand = true
    
    flyBV = Instance.new("BodyVelocity", root)
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Velocity = Vector3.zero
    
    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.P = 1e5
    
    flyConn = RunService.RenderStepped:Connect(function()
        if not flyFlying or not root.Parent then stopFly(); return end
        hum.PlatformStand = true
        
        local cam = Workspace.CurrentCamera
        local md = hum.MoveDirection -- NATIVE MOBILE JOYSTICK DETECTOR
        
        if md.Magnitude > 0 then
            -- Kalkulasi pergerakan murni berdasarkan arah joystick & kamera
            local pitch = cam.CFrame.LookVector.Y
            local moveX = md.X * Move.flySpeed
            local moveZ = md.Z * Move.flySpeed
            
            -- Deteksi dorongan maju/mundur untuk naik/turun
            local dot = md:Dot(cam.CFrame.LookVector * Vector3.new(1,0,1).Unit)
            local moveY = pitch * Move.flySpeed * dot
            
            flyBV.Velocity = Vector3.new(moveX, moveY, moveZ)
        else
            flyBV.Velocity = Vector3.new(0, 0, 0)
        end
        flyBG.CFrame = cam.CFrame
    end)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ANTI-CHEAT & CHAT BYPASS                │
-- └─────────────────────────────────────────────────────────┘
local function activateBypass()
    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(t, k)
        if not checkcaller() and t:IsA("Humanoid") and (k == "WalkSpeed" or k == "JumpPower") then
            return (k == "WalkSpeed" and 16 or 50)
        end
        return oldIndex(t, k)
    end)
    setreadonly(mt, true)
    notify("Security", "Bypass Hook Active", 2)
end

local function hookChat()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if chatBypassActive and method == "FireServer" and self.Name == "SayMessageRequest" then
            local msg = args[1]; local newMsg = ""
            for i = 1, #msg do newMsg = newMsg .. msg:sub(i,i) .. "\203" end
            args[1] = newMsg
            return oldNamecall(self, unpack(args))
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end
task.spawn(hookChat)

-- ┌─────────────────────────────────────────────────────────┐
-- │                 ESP & SECURITY MODULES                  │
-- └─────────────────────────────────────────────────────────┘
local ESPPl = {active = false, guis = {}, conn = nil}
local function clearESP() for _, g in pairs(ESPPl.guis) do if g then g:Destroy() end end; ESPPl.guis = {} end
local function updateESP()
    clearESP(); if not ESPPl.active then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            local bill = Instance.new("BillboardGui", p.Character.Head); bill.Size = UDim2.new(0, 100, 0, 24); bill.AlwaysOnTop = true; bill.StudsOffset = Vector3.new(0, 2.5, 0)
            local bg = Instance.new("Frame", bill); bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.new(0,0,0); bg.BackgroundTransparency = 0.45; Instance.new("UICorner", bg)
            local lbl = Instance.new("TextLabel", bg); lbl.Size = UDim2.new(1,0,1,0); lbl.TextColor3 = Color3.fromRGB(255, 230, 80); lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold; lbl.Text = p.Name
            table.insert(ESPPl.guis, bill)
        end
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   GUI INITIALIZATION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB", "shield", "v5.26", false)
local T_TP = Win:Tab("Teleport", "map-pin")
local T_Pl = Win:Tab("Player", "user")
local T_Sec = Win:Tab("Security", "shield")

-- Teleport Logic
local TP_P = T_TP:Page("Teleport", "map-pin")
local TPL = TP_P:Section("🎯 Target Player", "Left")
local selectedTarget = ""
local pNames = {}; for _,p in pairs(Players:GetPlayers()) do if p~=LP then table.insert(pNames, p.Name) end end

TPL:Dropdown("Pilih Player", "pDrop", pNames, function(v) selectedTarget = v end)
TPL:TextBox("Ketik Manual", "tpInp", "", function(v) selectedTarget = v end)
TPL:Button("🔍 TP to Target", "Teleport", function() 
    local p = Players:FindFirstChild(selectedTarget)
    if p and p.Character then getRoot().CFrame = p.Character.HumanoidRootPart.CFrame end
end)
TPL:Button("🧲 Bring Target", "Pull", function()
    local p = Players:FindFirstChild(selectedTarget)
    if p and p.Character then p.Character.HumanoidRootPart.CFrame = getRoot().CFrame end
end)

-- Player Hacks
local PL = T_Pl:Page("Player", "user"):Section("⚡ Movement", "Left")
local PR = T_Pl:Page("Player", "user"):Section("🚀 Hacks", "Right")

PL:Slider("Walk Speed", "ws", 16, 500, 16, function(v) Move.speed = v; getHum().WalkSpeed = v end)
PL:Toggle("Infinite Jump", "infj", false, "Jump", function(v) 
    if v then Move.jumpConn = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if Move.jumpConn then Move.jumpConn:Disconnect() end end
end)

PR:Toggle("Fly (Native Mobile)", "fly", false, "Pake Analog", function(v) if v then startFly() else stopFly() end end)
PR:Slider("Fly Speed", "fspd", 10, 500, 60, function(v) Move.flySpeed = v end)
PR:Toggle("Server Invis (R15)", "inv", false, "LowerTorso Destroy", function(v) 
    if v then local r = getChar():FindFirstChild("LowerTorso"); if r then r:Destroy() end end 
end)
PR:Toggle("ESP Player", "esp", false, "Visual", function(v) 
    ESPPl.active = v; if v then updateESP(); ESPPl.conn = Players.PlayerAdded:Connect(updateESP) else clearESP() end 
end)

-- Security
local SL = T_Sec:Page("Security", "shield"):Section("🛡️ Protection", "Left")
SL:Toggle("Anti-Cheat Bypass", "bp", false, "Hooking", function(v) if v then activateBypass() end end)
SL:Toggle("Chat Bypass", "cbp", false, "No Sensor", function(v) chatBypassActive = v end)
SL:Toggle("Anti AFK", "afk", false, "No Kick", function(v)
    if v then afkConn = LP.Idled:Connect(function() VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame) end)
    else if afkConn then afkConn:Disconnect() end end
end)
SL:Button("⚡ Fast Respawn", "TP Back", function()
    local r = getRoot()
    if r then 
        local old = r.CFrame; getHum().Health = 0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = old
    end
end)

notify("XKID HUB", "Native Mobile Fly Activated!")
