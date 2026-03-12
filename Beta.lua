--[[
WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]

-- XKID EXPLOIT UNIVERSAL v2.0
-- Fitur: Movement Exploits, Remote Scanner, Teleport, ESP

Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

-- Buat window
local Win = Library:Window("XKID EXPLOIT", "skull", "Universal v2.0 | by XKID", false)

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

-- ============================================
-- TAB MENU
-- ============================================
Win:TabSection("MOVEMENT")
local MovementTab = Win:Tab("Movement", "zap")

Win:TabSection("VISUAL")
local VisualTab = Win:Tab("Visual", "eye")

Win:TabSection("EXPLOIT")
local ExploitTab = Win:Tab("Exploit", "skull")

Win:TabSection("UTILITY")
local UtilityTab = Win:Tab("Utility", "settings")

-- ============================================
-- MOVEMENT TAB
-- ============================================
local MovePage = MovementTab:Page("Exploits", "zap")
local MoveLeft = MovePage:Section("Movement Hacks", "Left")
local MoveRight = MovePage:Section("Info", "Right")

-- Variabel untuk movement
local noclip = false
local noclipConn = nil
local fly = false
local flyConn = nil
local flyVel = nil
local infJump = false
local speed = 16
local jump = 50

-- Noclip Toggle
MoveLeft:Toggle("Noclip", "NoclipToggle", false, "Tembus dinding/wallhack", function(state)
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
        Library:Notification("Noclip", "Aktif!", 2)
    else
        Library:Notification("Noclip", "Mati", 2)
    end
end)

-- Fly Toggle
MoveLeft:Toggle("Fly", "FlyToggle", false, "Terbang bebas (WASD + Spasi/Ctrl)", function(state)
    fly = state
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyVel then flyVel:Destroy(); flyVel = nil end
    
    if state and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            flyVel = Instance.new("BodyVelocity")
            flyVel.Velocity = Vector3.new(0, 0, 0)
            flyVel.MaxForce = Vector3.new(4000, 4000, 4000)
            flyVel.Parent = root
            
            flyConn = RunService.Heartbeat:Connect(function()
                if not fly or not LocalPlayer.Character then return end
                local move = Vector3.new()
                local cam = Workspace.CurrentCamera
                
                if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
                
                if move.Magnitude > 0 then
                    flyVel.Velocity = move.Unit * 50
                else
                    flyVel.Velocity = Vector3.new(0, 0, 0)
                end
            end)
        end
        Library:Notification("Fly", "Aktif! (WASD + Spasi/Ctrl)", 3)
    else
        Library:Notification("Fly", "Mati", 2)
    end
end)

-- Speed Slider
MoveLeft:Slider("WalkSpeed", "SpeedSlider", 16, 500, 16, function(val)
    speed = val
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end, "Kecepatan jalan")

-- Jump Slider
MoveLeft:Slider("Jump Power", "JumpSlider", 50, 500, 50, function(val)
    jump = val
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = val end
    end
end, "Kekuatan lompat")

-- Infinite Jump Toggle
MoveLeft:Toggle("Infinite Jump", "InfJumpToggle", false, "Lompat terus di udara", function(state)
    infJump = state
    if state then
        UIS.JumpRequest:Connect(function()
            if infJump and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
        Library:Notification("Infinite Jump", "Aktif!", 2)
    else
        Library:Notification("Infinite Jump", "Mati", 2)
    end
end)

-- Gravity Slider
MoveLeft:Slider("Gravity", "GravitySlider", 0, 500, 196.2, function(val)
    Workspace.Gravity = val
end, "Ubah gravitasi dunia")

-- Info Paragraph
MoveRight:Paragraph("Info Movement", 
    "🟢 Noclip: Tembus dinding\n" ..
    "🟢 Fly: Terbang bebas\n" ..
    "🟢 Speed: Jalan lebih cepat\n" ..
    "🟢 Jump: Lompat lebih tinggi\n" ..
    "🟢 Infinite Jump: Lompat di udara\n" ..
    "🟢 Gravity: Ubah gravitasi\n\n" ..
    "Pastikan karakter sudah spawn!")

-- ============================================
-- VISUAL TAB
-- ============================================
local VisPage = VisualTab:Page("Visual Effects", "eye")
local VisLeft = VisPage:Section("Enhancements", "Left")
local VisRight = VisPage:Section("ESP", "Right")

-- Fullbright Toggle
VisLeft:Toggle("Fullbright", "FullbrightToggle", false, "Terang seperti siang", function(state)
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 50000
        Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.new(0, 0, 0)
    end
end)

-- X-Ray Toggle
VisLeft:Toggle("X-Ray Vision", "XRayToggle", false, "Lihat tembus dinding", function(state)
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = state and 0.7 or 0
        end
    end
end)

-- FOV Slider
VisLeft:Slider("Field of View", "FOVSlider", 40, 120, 70, function(val)
    Workspace.CurrentCamera.FieldOfView = val
end, "Ubah sudut pandang camera")

-- ESP Toggle
local espEnabled = false
local espConn = nil

VisRight:Toggle("ESP Player", "ESPPlayerToggle", false, "Tampilkan nama & jarak player", function(state)
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
                        -- Gambar ESP sederhana (console saja untuk demo)
                        local dist = (myPos.Position - hrp.Position).Magnitude
                        -- Di sini bisa ditambahkan Drawing API jika executor support
                    end
                end
            end
        end)
    end
end)

-- ESP Color Picker
VisRight:ColorPicker("ESP Color", "ESPColor", Color3.fromRGB(255, 0, 0), 0, function(col)
    -- Warna untuk ESP
end, "Warna highlight ESP")

-- ============================================
-- EXPLOIT TAB
-- ============================================
local ExpPage = ExploitTab:Page("Remote Tools", "skull")
local ExpLeft = ExpPage:Section("Remote Scanner", "Left")
local ExpRight = ExpPage:Section("Backdoor", "Right")

-- Remote Scanner
local remotes = {}

ExpLeft:Button("🔍 Scan All Remotes", "Cari semua remote di game", function()
    remotes = {}
    print("\n=== REMOTE DI REPLICATEDSTORAGE ===")
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(remotes, v)
            print(string.format("[%s] %s", v.ClassName, v.Name))
        end
    end
    
    print("\n=== REMOTE DI WORKSPACE ===")
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(remotes, v)
            print(string.format("[%s] %s", v.ClassName, v.Name))
        end
    end
    
    Library:Notification("Scanner", string.format("Ditemukan %d remote (cek console)", #remotes), 4)
end)

-- Backdoor Scanner
ExpLeft:Button("🔎 Scan Backdoor", "Cari remote mencurigakan", function()
    local backdoors = {}
    local patterns = {"Admin", "Backdoor", "Server", "Execute", "Loadstring", "Run", "Command"}
    
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            for _, pattern in ipairs(patterns) do
                if v.Name:find(pattern, 1, true) then
                    table.insert(backdoors, v)
                    print(string.format("[BACKDOOR?] %s - %s", v.ClassName, v.Name))
                    break
                end
            end
        end
    end
    
    Library:Notification("Backdoor", string.format("Ditemukan %d remote mencurigakan", #backdoors), 4)
end)

-- Execute Server Code
ExpRight:TextBox("Server Code", "ServerCode", "", function(txt)
    -- Simpan code untuk dieksekusi
    _G.serverCode = txt
end, "Masukkan kode Lua untuk server")

ExpRight:Button("💀 Execute on Server", "Jalankan kode di server (jika ada backdoor)", function()
    if not _G.serverCode then
        Library:Notification("Error", "Masukkan kode dulu!", 3)
        return
    end
    
    -- Coba cari backdoor pertama
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:find("Admin") or v.Name:find("Server") then
            pcall(function()
                v:FireServer(_G.serverCode)
                Library:Notification("Sukses", "Kode dikirim via " .. v.Name, 3)
            end)
            return
        end
    end
    
    Library:Notification("Gagal", "Tidak menemukan backdoor", 3)
end)

-- ============================================
-- UTILITY TAB
-- ============================================
local UtilPage = UtilityTab:Page("Tools", "settings")
local UtilLeft = UtilPage:Section("Player", "Left")
local UtilRight = UtilPage:Section("Server", "Right")

-- Anti AFK Toggle
UtilLeft:Toggle("Anti AFK", "AntiAFKToggle", false, "Cegah disconnect", function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        Library:Notification("Anti AFK", "Aktif", 2)
    end
end)

-- Reset Character
UtilLeft:Button("💀 Reset Character", "Mati lalu respawn", function()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
end)

-- Teleport to Mouse
UtilLeft:Button("📍 Teleport ke Mouse", "Pindah ke posisi kursor", function()
    local mouse = LocalPlayer:GetMouse()
    if mouse and mouse.Hit and LocalPlayer.Character then
        LocalPlayer.Character:SetPrimaryPartCFrame(mouse.Hit + Vector3.new(0, 3, 0))
        Library:Notification("Teleport", "Pindah ke mouse", 2)
    end
end)

-- Rejoin Server
UtilRight:Button("🔄 Rejoin Server", "Koneksi ulang ke server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- Server Hop
UtilRight:Button("🌐 Server Hop", "Cari server lain", function()
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
        Library:Notification("Server Hop", "Tidak ada server tersedia", 3)
    end
end)

-- Get Coordinates
UtilRight:Button("📍 Koordinat Saya", "Lihat posisi saat ini", function()
    if LocalPlayer.Character then
        local pos = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if pos then
            local p = pos.Position
            Library:Notification("Koordinat", string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 5)
        end
    end
end)

-- FPS Boost
UtilRight:Button("🚀 FPS Boost", "Tingkatkan performa", function()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
        end
    end
    Lighting.GlobalShadows = false
    Library:Notification("FPS Boost", "Aktif!", 2)
end)

-- ============================================
-- LOADING CONFIG
-- ============================================
Library:Notification("XKID EXPLOIT", "Universal v2.0 Loaded!", 5)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   XKID EXPLOIT UNIVERSAL v2.0           ║")
print("║   Fitur: Movement, Visual, Exploit      ║")
print("║   Player: " .. tostring(LocalPlayer and LocalPlayer.Name or "Unknown"))
print("╚══════════════════════════════════════════╝")