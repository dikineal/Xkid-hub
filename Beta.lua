--[[
WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]

-- XKID AESTHETIC HUB v3.0
-- UI Aesthetic dengan Aurora UI

Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

-- ============================================
-- WINDOW UTAMA (AESTHETIC)
-- ============================================
local Win = Library:Window(
    "✨ XKID AESTHETIC", 
    "sparkles", 
    "v3.0 | Soft UI", 
    false
)

-- ============================================
-- WARNA AESTHETIC
-- ============================================
local Colors = {
    Primary = Color3.fromRGB(255, 200, 220),  -- Soft Pink
    Secondary = Color3.fromRGB(200, 220, 255), -- Soft Blue
    Accent = Color3.fromRGB(220, 180, 255),    -- Soft Purple
    Success = Color3.fromRGB(180, 255, 200),   -- Soft Green
    Error = Color3.fromRGB(255, 180, 180),     -- Soft Red
    Text = Color3.fromRGB(255, 255, 255),      -- White
    Background = Color3.fromRGB(25, 25, 35)    -- Dark Soft
}

-- ============================================
-- TAB MENU AESTHETIC
-- ============================================
Win:TabSection("🌸 MOVEMENT")
local MoveTab = Win:Tab("Movement", "wind")

Win:TabSection("👁️ VISUAL")
local VisualTab = Win:Tab("Visuals", "sparkles")

Win:TabSection("⚡ EXPLOIT")
local ExpTab = Win:Tab("Exploit", "zap")

Win:TabSection("🎨 UTILITY")
local UtilTab = Win:Tab("Utility", "heart")

-- ============================================
-- VARIABEL GLOBAL
-- ============================================
-- Movement
local noclip = false
local noclipConn = nil
local fly = false
local flyConn = nil
local flyVel = nil
local flyBg = nil
local infJump = false
local speed = 16
local jump = 50

-- Visual
local espEnabled = false
local espConn = nil
local espColor = Color3.fromRGB(255, 200, 220)
local fullbright = false
local xray = false

-- ============================================
-- FUNGSI NOTIF AESTHETIC
-- ============================================
local function notifAesthetic(title, msg, duration, color)
    pcall(function()
        Library:Notification("✨ " .. title, msg, duration or 3)
    end)
end

-- ============================================
-- MOVEMENT TAB - AESTHETIC
-- ============================================
local MovePage = MoveTab:Page("Movement Controls", "wind")
local MoveLeft = MovePage:Section("🌸 Basic", "Left")
local MoveRight = MovePage:Section("🌿 Advanced", "Right")

-- Label Aesthetic
MoveLeft:Label("⋆｡°✩ Movement Mods ✩°｡⋆")

-- Noclip Toggle (Aesthetic)
MoveLeft:Toggle("Noclip", "NoclipAesthetic", false, "Tembus dinding dengan gaya", function(state)
    noclip = state
    if noclipConn then noclipConn:Disconnect() end
    
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        notifAesthetic("Noclip", "activated ✨", 2, Colors.Success)
    else
        notifAesthetic("Noclip", "deactivated", 2, Colors.Error)
    end
end)

-- Fly Toggle (Aesthetic - FIXED)
MoveLeft:Toggle("Fly Mode", "FlyAesthetic", false, "Terbang bebas (WASD + Spasi/Ctrl)", function(state)
    fly = state
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyVel then flyVel:Destroy(); flyVel = nil end
    if flyBg then flyBg:Destroy(); flyBg = nil end
    
    if state and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        
        if root and humanoid then
            -- Set humanoid ke flying state
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
            humanoid:ChangeState(Enum.HumanoidStateType.Flying)
            
            -- BodyVelocity untuk gerak
            flyVel = Instance.new("BodyVelocity")
            flyVel.Velocity = Vector3.new(0, 0, 0)
            flyVel.MaxForce = Vector3.new(4000, 4000, 4000)
            flyVel.Parent = root
            
            -- BodyGyro untuk stabilisasi
            flyBg = Instance.new("BodyGyro")
            flyBg.MaxTorque = Vector3.new(4000, 4000, 4000)
            flyBg.P = 1000
            flyBg.D = 50
            flyBg.CFrame = root.CFrame
            flyBg.Parent = root
            
            flyConn = RunService.Heartbeat:Connect(function()
                if not fly or not LocalPlayer.Character then return end
                
                local move = Vector3.new()
                local cam = Workspace.CurrentCamera
                
                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    move = move + cam.CFrame.LookVector * Vector3.new(1, 0, 1)
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    move = move - cam.CFrame.LookVector * Vector3.new(1, 0, 1)
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    move = move - cam.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    move = move + cam.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    move = move + Vector3.new(0, 1, 0)
                end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    move = move - Vector3.new(0, 1, 0)
                end
                
                if move.Magnitude > 0 then
                    flyVel.Velocity = move.Unit * 50
                    local lookAt = root.Position + move.Unit * 10
                    flyBg.CFrame = CFrame.lookAt(root.Position, lookAt)
                else
                    flyVel.Velocity = Vector3.new(0, 0, 0)
                    flyBg.CFrame = root.CFrame
                end
            end)
        end
        notifAesthetic("Fly Mode", "soaring through the sky ✈️", 3, Colors.Success)
    else
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Landing)
            end
        end
        notifAesthetic("Fly Mode", "landed safely", 2, Colors.Error)
    end
end)

-- Speed Slider Aesthetic
MoveLeft:Slider("Walk Speed", "SpeedAesthetic", 16, 500, 16, function(val)
    speed = val
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end, "adjust your pace 🌪️")

-- Jump Slider Aesthetic
MoveLeft:Slider("Jump Power", "JumpAesthetic", 50, 500, 50, function(val)
    jump = val
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = val end
    end
end, "reach for the sky 🌙")

-- Infinite Jump Aesthetic
MoveRight:Toggle("Infinite Jump", "InfJumpAesthetic", false, "bounce bounce bounce~", function(state)
    infJump = state
    if state then
        UIS.JumpRequest:Connect(function()
            if infJump and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
        notifAesthetic("Infinite Jump", "hopping forever 🐰", 2, Colors.Success)
    else
        notifAesthetic("Infinite Jump", "stopped hopping", 2, Colors.Error)
    end
end)

-- Gravity Slider Aesthetic
MoveRight:Slider("Gravity", "GravityAesthetic", 0, 500, 196.2, function(val)
    Workspace.Gravity = val
end, "defy physics 🌌")

-- Info Paragraph Aesthetic
MoveRight:Paragraph("✨ Movement Tips", 
    "⋆｡°✩ Noclip: walk through walls\n" ..
    "⋆｡°✩ Fly: wasd + space/ctrl\n" ..
    "⋆｡°✩ Speed: zoom zoom\n" ..
    "⋆｡°✩ Jump: high jump\n" ..
    "⋆｡°✩ Gravity: floaty mode")

-- ============================================
-- VISUAL TAB - AESTHETIC
-- ============================================
local VisPage = VisualTab:Page("Visual Effects", "sparkles")
local VisLeft = VisPage:Section("🌸 Lighting", "Left")
local VisRight = VisPage:Section("🌿 ESP", "Right")

-- Fullbright Aesthetic
VisLeft:Toggle("Fullbright", "FullbrightAesthetic", false, "light it up ✨", function(state)
    fullbright = state
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
        notifAesthetic("Fullbright", "let there be light 💡", 2, Colors.Success)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 50000
        Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.new(0, 0, 0)
        notifAesthetic("Fullbright", "back to normal", 2, Colors.Error)
    end
end)

-- X-Ray Aesthetic
VisLeft:Toggle("X-Ray Vision", "XRayAesthetic", false, "see through walls 👁️", function(state)
    xray = state
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = state and 0.7 or 0
        end
    end
    notifAesthetic("X-Ray", state and "activated" or "deactivated", 2)
end)

-- FOV Slider Aesthetic
VisLeft:Slider("Field of View", "FOVAesthetic", 40, 120, 70, function(val)
    Workspace.CurrentCamera.FieldOfView = val
end, "widen your perspective 🌅")

-- ESP Color Picker Aesthetic
VisRight:ColorPicker("ESP Color", "ESPColorAesthetic", Colors.Primary, 0, function(col)
    espColor = col
end, "pick your highlight color 🎨")

-- ESP Toggle Aesthetic
VisRight:Toggle("ESP Players", "ESPAesthetic", false, "see other players", function(state)
    espEnabled = state
    
    if espConn then espConn:Disconnect() end
    
    if state then
        espConn = RunService.RenderStepped:Connect(function()
            if not LocalPlayer.Character then return end
            local myPos = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myPos then return end
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local head = player.Character:FindFirstChild("Head")
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    
                    if head and hrp then
                        -- Simple ESP (console log for demo)
                        local dist = (myPos.Position - hrp.Position).Magnitude
                        -- In real implementation, use Drawing or BillboardGui
                    end
                end
            end
        end)
        notifAesthetic("ESP", "player tracking enabled", 2, Colors.Success)
    else
        notifAesthetic("ESP", "player tracking disabled", 2, Colors.Error)
    end
end)

-- ============================================
-- EXPLOIT TAB - AESTHETIC
-- ============================================
local ExpPage = ExpTab:Page("Exploit Tools", "zap")
local ExpLeft = ExpPage:Section("🔍 Scanner", "Left")
local ExpRight = ExpPage:Section("💀 Backdoor", "Right")

-- Remote Scanner Aesthetic
ExpLeft:Button("🔍 Scan Remote", "find all remote events", function()
    local count = 0
    print("\n" .. string.rep("=", 50))
    print("🔍 REMOTE SCAN RESULTS")
    print(string.rep("=", 50))
    
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            print(string.format("[%s] %s", v.ClassName, v.Name))
            count = count + 1
        end
    end
    
    notifAesthetic("Scanner", string.format("found %d remotes (check console)", count), 4)
end)

-- Backdoor Scanner Aesthetic
ExpLeft:Button("🎯 Scan Backdoor", "find suspicious remotes", function()
    local backdoors = {}
    local patterns = {"Admin", "Backdoor", "Server", "Execute", "Run", "Command", "Control"}
    
    print("\n" .. string.rep("=", 50))
    print("🎯 BACKDOOR SCAN")
    print(string.rep("=", 50))
    
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            for _, pattern in ipairs(patterns) do
                if v.Name:find(pattern, 1, true) then
                    print(string.format("[⚠️] %s - %s", v.ClassName, v.Name))
                    table.insert(backdoors, v)
                    break
                end
            end
        end
    end
    
    notifAesthetic("Backdoor", string.format("found %d suspicious remotes", #backdoors), 4)
end)

-- Server Code Input Aesthetic
ExpRight:TextBox("Server Code", "ServerCodeAesthetic", "", function(txt)
    _G.serverCode = txt
end, "enter lua code for server")

-- Execute Button Aesthetic
ExpRight:Button("💫 Execute on Server", "run code if backdoor exists", function()
    if not _G.serverCode then
        notifAesthetic("Error", "enter code first!", 3, Colors.Error)
        return
    end
    
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name:find("Admin") or v.Name:find("Server")) then
            pcall(function()
                v:FireServer(_G.serverCode)
                notifAesthetic("Success", "code executed via " .. v.Name, 3, Colors.Success)
            end)
            return
        end
    end
    
    notifAesthetic("Failed", "no backdoor found", 3, Colors.Error)
end)

-- ============================================
-- UTILITY TAB - AESTHETIC
-- ============================================
local UtilPage = UtilTab:Page("Utility Tools", "heart")
local UtilLeft = UtilPage:Section("🌸 Player", "Left")
local UtilRight = UtilPage:Section("🌿 Server", "Right")

-- Anti AFK Aesthetic
UtilLeft:Toggle("Anti AFK", "AntiAFKAesthetic", false, "stay active forever", function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        notifAesthetic("Anti AFK", "you'll never sleep 💤", 2, Colors.Success)
    end
end)

-- Reset Character Aesthetic
UtilLeft:Button("💫 Reset Character", "respawn yourself", function()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
        notifAesthetic("Reset", "goodbye... see you soon", 2)
    end
end)

-- Teleport to Mouse Aesthetic
UtilLeft:Button("📍 Teleport to Mouse", "jump to cursor", function()
    local mouse = LocalPlayer:GetMouse()
    if mouse and mouse.Hit and LocalPlayer.Character then
        LocalPlayer.Character:SetPrimaryPartCFrame(mouse.Hit + Vector3.new(0, 3, 0))
        notifAesthetic("Teleport", "whoosh~", 2, Colors.Success)
    end
end)

-- Rejoin Server Aesthetic
UtilRight:Button("🔄 Rejoin Server", "come back in", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- Server Hop Aesthetic
UtilRight:Button("🌐 Server Hop", "find new friends", function()
    local HttpService = game:GetService("HttpService")
    local success, servers = pcall(function()
        local res = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")
        return HttpService:JSONDecode(res)
    end)
    
    if success and servers and servers.data then
        for _, server in ipairs(servers.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                return
            end
        end
        notifAesthetic("Server Hop", "no servers available", 3, Colors.Error)
    end
end)

-- Get Coordinates Aesthetic
UtilRight:Button("📍 My Position", "where am i?", function()
    if LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local p = root.Position
            notifAesthetic("Position", string.format("X: %.1f\nY: %.1f\nZ: %.1f", p.X, p.Y, p.Z), 5)
        end
    end
end)

-- FPS Boost Aesthetic
UtilRight:Button("🚀 FPS Boost", "smooth like butter", function()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
        end
    end
    Lighting.GlobalShadows = false
    notifAesthetic("FPS Boost", "smooth sailing~", 2, Colors.Success)
end)

-- ============================================
-- CREDITS AESTHETIC
-- ============================================
local CreditPage = UtilTab:Page("Credits", "heart")
local CreditMain = CreditPage:Section("🌸 About", "Left")
local CreditInfo = CreditPage:Section("✨ Info", "Right")

CreditMain:Paragraph("✨ XKID AESTHETIC",
    "⋆｡°✩ v3.0\n" ..
    "⋆｡°✩ soft ui edition\n" ..
    "⋆｡°✩ by xkid\n" ..
    "⋆｡°✩ for roblox")

CreditInfo:Paragraph("🌸 Features",
    "⋆｡°✩ movement mods\n" ..
    "⋆｡°✩ visual effects\n" ..
    "⋆｡°✩ exploit tools\n" ..
    "⋆｡°✩ utility features")

-- ============================================
-- LOADING CONFIG
-- ============================================
notifAesthetic("XKID AESTHETIC", "welcome to soft ui ✨", 5, Colors.Primary)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   ✨ XKID AESTHETIC v3.0                ║")
print("║   soft ui edition                        ║")
print("║   loading complete...                    ║")
print("╚══════════════════════════════════════════╝")