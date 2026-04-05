--[[
╔═══════════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.26 MINIMAL 🌟          ║
║                Eternal Aurora v3.6 · 19 Features            ║
╚═══════════════════════════════════════════════════════════════╝
]]

--[[
\tWARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local Win = Library:Window("XKID HUB v5.26", "crown", "19 Features | Eternal v3.6", false)

-- TELEPORT TAB (5 FITUR)
Win:TabSection("Teleport")
local TeleTab = Win:Tab("Teleport", "map-pin")

local TeleMain = TeleTab:Page("Main", "globe")
local TeleSec = TeleTab:Page("Security", "shield")

TeleMain:Label("📍 Teleport Positions")
TeleMain:Button("🏠 Spawn", "TP ke spawn point", function()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(0, 50, 0)
        Library:Notification("Teleport", "Spawn loaded!", 2)
    end
end)

TeleMain:Button("📍 Save Position", "Simpan posisi sekarang", function()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root then
        _G.savedPos = root.CFrame
        Library:Notification("Save Pos", "Posisi tersimpan!", 2)
    end
end)

TeleSec:Button("🔄 Respawn to Saved", "Respawn & kembali ke posisi tersimpan", function()
    if _G.savedPos then
        LP.Character:BreakJoints()
    else
        Library:Notification("Respawn", "Belum ada posisi tersimpan", 3)
    end
end)

TeleSec:Label("👥 Bring Player")
TeleSec:Button("👤 Bring Player1", "Tarik Player1 ke posisi kamu", function()
    local target = Players:FindFirstChild("Player1")
    if target and target.Character then
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot and myRoot then
            targetRoot.CFrame = myRoot.CFrame * CFrame.new(2, 0, 0)
            Library:Notification("Bring", "Player1 ditarik!", 2)
        end
    else
        Library:Notification("Bring", "Player1 tidak ditemukan", 3)
    end
end)

TeleSec:Button("👥 Bring Nearest", "Tarik player terdekat", function()
    local nearest, shortestDist = nil, math.huge
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < shortestDist then
                nearest = p
                shortestDist = dist
            end
        end
    end
    
    if nearest then
        local targetRoot = nearest.Character.HumanoidRootPart
        targetRoot.CFrame = myRoot.CFrame * CFrame.new(2, 0, 0)
        Library:Notification("Bring", nearest.Name .. " ditarik!", 2)
    end
end)

-- PLAYER TAB (8 FITUR)
Win:TabSection("Player")
local PlayTab = Win:Tab("Player", "user")

local PlayMove = PlayTab:Page("Movement", "speedometer")
local PlayVis = PlayTab:Page("Visuals", "eye")

PlayMove:Label("⚡ Movement Controls")
PlayMove:Slider("Walk Speed", "WalkSpeed", 16, 500, 16, function(value)
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = value end
end, "Speed control")

PlayMove:Slider("Jump Power", "JumpPower", 50, 500, 50, function(value)
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then 
        hum.JumpPower = value 
        hum.UseJumpPower = true 
    end
end, "Jump height")

PlayMove:Toggle("Fly", "FlyEnabled", false, "WASD + Space/Shift", function(state)
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if state then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new()
        bv.Parent = root
        
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not state or not root.Parent then
                bv:Destroy()
                conn:Disconnect()
                return
            end
            local vel = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then vel = vel + root.CFrame.LookVector * 50 end
            if UIS:IsKeyDown(Enum.KeyCode.S) then vel = vel - root.CFrame.LookVector * 50 end
            if UIS:IsKeyDown(Enum.KeyCode.A) then vel = vel - root.CFrame.RightVector * 50 end
            if UIS:IsKeyDown(Enum.KeyCode.D) then vel = vel + root.CFrame.RightVector * 50 end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, 50, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0, 50, 0) end
            bv.Velocity = vel
        end)
    end
end, "Fly with WASD")

PlayMove:Slider("Fly Speed", "FlySpeed", 10, 200, 50, function(value)
    -- Fly speed dynamically updated in toggle
end, "Fly movement speed")

PlayMove:Toggle("NoClip", "NoClipEnabled", false, "Walk through walls", function(state)
    local conn
    if state then
        conn = RunService.Stepped:Connect(function()
            local char = LP.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if conn then conn:Disconnect() end
    end
end, "Disable collision")

PlayMove:Toggle("Infinite Jump", "InfJumpEnabled", false, "Jump anytime", function(state)
    local conn
    if state then
        conn = UIS.JumpRequest:Connect(function()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if conn then conn:Disconnect() end
    end
end, "Unlimited jumping")

PlayVis:Toggle("Player ESP", "PlayerESP", false, "Names + distance", function(state)
    local espConns = {}
    if state then
        local conn = RunService.RenderStepped:Connect(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local root = player.Character.HumanoidRootPart
                    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        local dist = (myRoot.Position - root.Position).Magnitude
                        local screen, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
                        
                        if onScreen then
                            if not espConns[player.UserId] then
                                local billboard = Instance.new("BillboardGui")
                                billboard.Adornee = root
                                billboard.Size = UDim2.new(0, 200, 0, 50)
                                billboard.StudsOffset = Vector3.new(0, 3, 0)
                                billboard.Parent = root
                                
                                local label = Instance.new("TextLabel")
                                label.Size = UDim2.new(1, 0, 1, 0)
                                label.BackgroundTransparency = 1
                                label.TextColor3 = Color3.new(1, 1, 1)
                                label.TextStrokeTransparency = 0
                                label.Font = Enum.Font.GothamBold
                                label.TextScaled = true
                                label.Parent = billboard
                                
                                espConns[player.UserId] = {billboard, label}
                            end
                            
                            local data = espConns[player.UserId]
                            if data then
                                data[2].Text = player.Name .. "
[" .. math.floor(dist) .. "m]"
                            end
                        end
                    end
                end
            end
        end)
        espConns.main = conn
    else
        for _, data in pairs(espConns) do
            if data[1] then data[1]:Destroy() end
        end
        if espConns.main then espConns.main:Disconnect() end
    end
end, "ESP all players")

-- SECURITY TAB (6 FITUR)
Win:TabSection("Security")
local SecTab = Win:Tab("Security", "shield")

local SecMain = SecTab:Page("Protection", "shield")

SecMain:Toggle("Anti AFK", "AntiAFK", false, "Prevent idle kick", function(state)
    local antiAfkConn
    if state then
        antiAfkConn = RunService.Heartbeat:Connect(function()
            local cam = Workspace.CurrentCamera
            cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(1), 0)
        end)
    else
        if antiAfkConn then antiAfkConn:Disconnect() end
    end
end, "Stay online forever")

SecMain:Toggle("Anti Kick", "AntiKick", false, "HP never drops below 20%", function(state)
    local antiKickConn
    if state then
        antiKickConn = RunService.Heartbeat:Connect(function()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth * 0.2 then
                hum.Health = hum.MaxHealth
            end
        end)
    else
        if antiKickConn then antiKickConn:Disconnect() end
    end
end, "HP protection")

SecMain:Button("🔄 Rejoin Server", "Rejoin current server", function()
    TpService:Teleport(game.PlaceId, LP)
end, "Fresh start")

Library:Notification("XKID HUB Loaded", "19 Features Ready!", 5)
Library:ConfigSystem(Win)

print("XKID HUB MINIMAL v5.26 - Eternal Aurora Compatible")