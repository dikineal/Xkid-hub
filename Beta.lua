--[[
╔═══════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.26  🌟              ║
║                  Aurora UI  ·  Pro Edition               ║
╠═══════════════════════════════════════════════════════════╣
║  [HOTFIX] Fly Logic, ESP Cleanup, Anti-AFK Restored      ║
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

RunService.Heartbeat:Connect(function()
    local r = getRoot()
    if r then Respawn.savedPosition = r.CFrame end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │                 FIXED FLY SYSTEM                        │
-- └─────────────────────────────────────────────────────────┘
local function stopFly()
    flyFlying = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local hum = getHum()
    if hum then 
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
end

local function startFly()
    if flyFlying then stopFly() end -- Cegah double run
    local root = getRoot(); local hum = getHum()
    if not root or not hum then return end
    
    flyFlying = true
    hum.PlatformStand = true
    
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
        local moveDir = Vector3.new(0,0,0)
        
        -- Deteksi Input (WASD)
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
            flyBV.Velocity = moveDir * Move.flySpeed
        else
            flyBV.Velocity = Vector3.new(0, 0, 0) -- Berhenti nge-drift
        end
        flyBG.CFrame = cam.CFrame
    end)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                 FIXED ESP SYSTEM                        │
-- └─────────────────────────────────────────────────────────┘
local ESPPl = {active = false, guis = {}, conn = nil}

local function clearESP()
    for _, gui in pairs(ESPPl.guis) do
        if gui then gui:Destroy() end
    end
    ESPPl.guis = {}
end

local function updateESP()
    clearESP() -- Bersihkan yang lama sebelum buat baru
    if not ESPPl.active then return end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            local bill = Instance.new("BillboardGui", head)
            bill.Name = "XKID_ESP"; bill.Size = UDim2.new(0, 150, 0, 20)
            bill.StudsOffset = Vector3.new(0, 3, 0); bill.AlwaysOnTop = true
            
            local lbl = Instance.new("TextLabel", bill)
            lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.fromRGB(0, 255, 128); lbl.TextStrokeTransparency = 0
            lbl.Font = Enum.Font.Code; lbl.TextSize = 14
            
            table.insert(ESPPl.guis, bill)
            
            -- Update jarak realtime
            task.spawn(function()
                while ESPPl.active and bill.Parent do
                    if getRoot() and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = math.floor((p.Character.HumanoidRootPart.Position - getRoot().Position).Magnitude)
                        lbl.Text = p.Name .. " [" .. dist .. "m]"
                    end
                    task.wait(0.1)
                end
            end)
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

-- TAB TELEPORT
local TP_P = T_TP:Page("Teleport", "map-pin")
local TPL = TP_P:Section("🎯 Target Player", "Left")
local selectedTarget = ""
local pNames = {}; for _,p in pairs(Players:GetPlayers()) do if p~=LP then table.insert(pNames, p.Name) end end

TPL:Dropdown("Pilih Player", "pDrop", pNames, function(v) selectedTarget = v end)
TPL:TextBox("Ketik Manual", "tpInp", "", function(v) selectedTarget = v end)
TPL:Button("🔍 TP to Target", "Teleport", function() 
    local p = Players:FindFirstChild(selectedTarget)
    if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then 
        getRoot().CFrame = p.Character.HumanoidRootPart.CFrame 
    else notify("TP", "Gagal menemukan player", 2) end
end)

-- TAB PLAYER
local PL = T_Pl:Page("Player", "user"):Section("⚡ Movement", "Left")
local PR = T_Pl:Page("Player", "user"):Section("🚀 Hacks", "Right")

PL:Slider("Walk Speed", "ws", 16, 500, 16, function(v) Move.speed = v; getHum().WalkSpeed = v end)
PL:Toggle("Infinite Jump", "infj", false, "Jump", function(v) 
    if v then Move.jumpConn = UIS.JumpRequest:Connect(function() getHum():ChangeState(3) end)
    else if Move.jumpConn then Move.jumpConn:Disconnect() end end
end)

PR:Toggle("Fly", "fly", false, "Terbang WASD", function(v) 
    if v then startFly() else stopFly() end 
end)
PR:Slider("Fly Speed", "fspd", 10, 500, 60, function(v) Move.flySpeed = v end)

PR:Toggle("ESP Player", "esp", false, "Visual Info", function(v) 
    ESPPl.active = v
    if v then 
        updateESP()
        -- Auto update pas ada yang join/spawn
        ESPPl.conn = Players.PlayerAdded:Connect(updateESP)
    else 
        clearESP()
        if ESPPl.conn then ESPPl.conn:Disconnect(); ESPPl.conn = nil end
    end
end)

-- TAB SECURITY (RESTORED)
local SL = T_Sec:Page("Security", "shield"):Section("🛡️ Protection", "Left")

SL:Toggle("Anti AFK", "afk", false, "Cegah Kick Idle", function(v)
    if v then 
        afkConn = LP.Idled:Connect(function() 
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame) 
        end)
        notify("Anti AFK", "Aktif", 2)
    else 
        if afkConn then afkConn:Disconnect(); afkConn = nil end 
        notify("Anti AFK", "Mati", 2)
    end
end)

SL:Button("⚡ Fast Respawn", "TP Back", function()
    if Respawn.savedPosition then
        local old = Respawn.savedPosition; getHum().Health = 0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = old
    end
end)

SL:Button("🔄 Rejoin Server", "Masuk ulang", function()
    TpService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end)

notify("XKID HUB", "Hotfix Loaded Successfully!")
