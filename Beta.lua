--[[
WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]

-- XKID AESTHETIC v5.0 - ROCKET FLY EDITION + EXTRA FEATURES
-- Fitur: Fly RocketPropulsion (H-G-L-K) + Backdoor Auto + Teleport + ESP + Anti AFK + Rejoin + Reset

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
    "✨ XKID ROCKET FLY", 
    "rocket", 
    "v5.0 | H=Toggle | G=Anchor | L=Fast | K=Slow", 
    false
)

-- ============================================
-- TAB MENU
-- ============================================
Win:TabSection("🚀 ROCKET FLY")
local FlyTab = Win:Tab("Rocket Fly", "rocket")

Win:TabSection("💀 BACKDOOR")
local BackdoorTab = Win:Tab("Backdoor", "skull")

Win:TabSection("🎯 TELEPORT")
local TeleportTab = Win:Tab("Teleport", "map-pin")

Win:TabSection("👁️ ESP")
local ESPTab = Win:Tab("ESP", "eye")

Win:TabSection("🎨 UTILITY")
local UtilTab = Win:Tab("Utility", "heart")

-- ============================================
-- VARIABEL UNTUK RESET DI POSISI SAMA
-- ============================================
local lastPosition = nil
local lastCFrame = nil

-- Fungsi untuk menyimpan posisi sebelum reset
local function savePosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        lastCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        lastPosition = LocalPlayer.Character.HumanoidRootPart.Position
        return true
    end
    return false
end

-- Fungsi reset character dan kembali ke posisi semula
local function resetCharacter()
    if not LocalPlayer.Character then return end
    
    -- Simpan posisi sebelum reset
    local savedCF = nil
    if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        savedCF = LocalPlayer.Character.HumanoidRootPart.CFrame
    end
    
    -- Reset character
    LocalPlayer.Character:BreakJoints()
    
    -- Tunggu character baru spawn
    local charAdded
    charAdded = LocalPlayer.CharacterAdded:Connect(function(newChar)
        charAdded:Disconnect()
        
        -- Tunggu sampai HumanoidRootPart muncul
        task.wait(1)
        local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
        if hrp and savedCF then
            -- Kembalikan ke posisi semula
            hrp.CFrame = savedCF
            Library:Notification("Reset", "Kembali ke posisi semula", 2)
        end
    end)
end

-- ============================================
-- TELEPORT KE PLAYER
-- ============================================
local function teleportToPlayer(targetName)
    if not targetName or targetName == "" then
        Library:Notification("Error", "Masukkan nama player", 2)
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(targetName:lower()) or player.DisplayName:lower():find(targetName:lower()) then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetPos = player.Character.HumanoidRootPart.Position
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos.X, targetPos.Y + 3, targetPos.Z)
                    Library:Notification("Teleport", "Ke " .. player.Name, 2)
                    return
                end
            end
        end
    end
    Library:Notification("Error", "Player tidak ditemukan", 2)
end

-- ============================================
-- ESP SEDERHANA
-- ============================================
local espEnabled = false
local espObjects = {}

local function toggleESP(state)
    espEnabled = state
    
    if state then
        -- Hapus ESP lama
        for _, obj in ipairs(espObjects) do
            pcall(function() obj:Destroy() end)
        end
        espObjects = {}
        
        -- Buat ESP baru untuk setiap player
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local function onChar(char)
                    if not espEnabled then return end
                    task.wait(0.5)
                    
                    local head = char:FindFirstChild("Head")
                    if head then
                        -- Billboard GUI sederhana
                        local bill = Instance.new("BillboardGui")
                        bill.Name = "XKID_ESP"
                        bill.Size = UDim2.new(0, 150, 0, 40)
                        bill.StudsOffset = Vector3.new(0, 2, 0)
                        bill.AlwaysOnTop = true
                        bill.Adornee = head
                        bill.Parent = char
                        
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text = player.Name .. "\n" .. player.DisplayName
                        label.TextColor3 = Color3.new(1, 1, 1)
                        label.TextStrokeTransparency = 0.5
                        label.TextScaled = true
                        label.Font = Enum.Font.GothamBold
                        label.Parent = bill
                        
                        table.insert(espObjects, bill)
                    end
                end
                
                if player.Character then
                    onChar(player.Character)
                end
                
                player.CharacterAdded:Connect(onChar)
            end
        end
        
        Library:Notification("ESP", "Aktif", 2)
    else
        -- Hapus semua ESP
        for _, obj in ipairs(espObjects) do
            pcall(function() obj:Destroy() end)
        end
        espObjects = {}
        Library:Notification("ESP", "Mati", 2)
    end
end

-- ============================================
-- ROCKET FLY SYSTEM (DARI SCRIPT LO)
-- ============================================

-- Keybind sesuai script
local FLYK = Enum.KeyCode.H  -- Toggle fly
local ANCK = Enum.KeyCode.G  -- Toggle anchor
local FSTK = Enum.KeyCode.L  -- Speed up (x1.5)
local SLWK = Enum.KeyCode.K  -- Speed down (/1.5)

-- Movement key vectors
local MVKS = {
    [Enum.KeyCode.D] = Vector3.new(1, 0, 0),
    [Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.S] = Vector3.new(0, 0, 1),
    [Enum.KeyCode.W] = Vector3.new(0, 0, -1),
    [Enum.KeyCode.E] = Vector3.new(0, 1, 0),
    [Enum.KeyCode.Q] = Vector3.new(0, -1, 0),
    
    [Enum.KeyCode.Right] = Vector3.new(1, 0, 0),
    [Enum.KeyCode.Left] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.Down] = Vector3.new(0, 0, 1),
    [Enum.KeyCode.Up] = Vector3.new(0, 0, -1),
    [Enum.KeyCode.PageUp] = Vector3.new(0, 1, 0),
    [Enum.KeyCode.PageDown] = Vector3.new(0, -1, 0),
}

-- Variabel fly
local SPEED = 127
local REL_TO_CHAR = false
local MAX_TORQUE_RP = 1e4
local THRUST_P = 1e5
local MAX_THRUST = 5e5
local MAX_TORQUE_BG = 3e4
local THRUST_D = math.huge
local TURN_D = 2e2
local ROOT_PART = nil

local keys_dn = {}
local flying = false
local enabled = false
local move_dir = Vector3.new()
local humanoid
local parent
local ms = LocalPlayer:GetMouse()

-- Cleanup global
_G.fly_evts = _G.fly_evts or {}
_G.fly_rp = nil
_G.fly_bg = nil
_G.fly_pt = nil

-- Fungsi inisialisasi fly
local function init_fly()
    if ROOT_PART then
        parent = ROOT_PART
        local model = parent:FindFirstAncestorWhichIsA('Model')
        if model then humanoid = model:FindFirstChildOfClass('Humanoid') end
    else
        local ch = LocalPlayer.Character
        if not ch then return end
        humanoid = ch:FindFirstChildOfClass('Humanoid')
        if not humanoid then return end
        parent = humanoid.RootPart
        if not parent then return end
    end
    
    -- Cleanup existing
    if _G.fly_rp then pcall(function() _G.fly_rp:Destroy() end) end
    if _G.fly_bg then pcall(function() _G.fly_bg:Destroy() end) end
    if _G.fly_pt and _G.fly_pt.Parent then pcall(function() _G.fly_pt.Parent:Destroy() end) end
    
    -- Create new instances
    local rp_h = MAX_TORQUE_RP
    _G.fly_bg = Instance.new('BodyGyro', parent)
    _G.fly_rp = Instance.new('RocketPropulsion', parent)
    
    local md = Instance.new('Model')
    _G.fly_pt = Instance.new('Part', md)
    md.Parent = _G.fly_pt
    
    _G.fly_rp.MaxTorque = Vector3.new(rp_h, rp_h, rp_h)
    _G.fly_bg.MaxTorque = Vector3.new()
    md.PrimaryPart = _G.fly_pt
    _G.fly_pt.Anchored = true
    _G.fly_pt.CanCollide = false
    _G.fly_pt.Transparency = 1
    _G.fly_rp.CartoonFactor = 1
    _G.fly_rp.Target = _G.fly_pt
    _G.fly_rp.MaxSpeed = SPEED
    _G.fly_rp.MaxThrust = MAX_THRUST
    _G.fly_rp.ThrustP = THRUST_P
    _G.fly_rp.ThrustD = THRUST_D
    _G.fly_rp.TurnP = THRUST_P
    _G.fly_rp.TurnD = TURN_D
    _G.fly_bg.P = 3e4
    enabled = false
    
    print("[FLY] RocketPropulsion initialized")
end

-- Fungsi arah fly
local function fly_dir()
    if REL_TO_CHAR then
        return CFrame.new(Vector3.new(), parent.CFrame.LookVector) * move_dir
    else
        local front = Workspace.CurrentCamera:ScreenPointToRay(ms.X, ms.Y).Direction
        return CFrame.new(Vector3.new(), front) * move_dir
    end
end

-- Setup events
local function setup_fly_events()
    -- Cleanup old events
    for _, e in ipairs(_G.fly_evts) do
        pcall(function() e:Disconnect() end)
    end
    _G.fly_evts = {}
    
    -- Character added event
    table.insert(_G.fly_evts, LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        init_fly()
    end))
    
    -- Input began
    table.insert(_G.fly_evts, UIS.InputBegan:Connect(function(i, p)
        if p then return end
        
        if i.KeyCode == FLYK then
            enabled = not enabled
            if enabled then
                if _G.fly_bg then
                    local bg_h = MAX_TORQUE_BG
                    _G.fly_bg.MaxTorque = Vector3.new(bg_h, 0, bg_h)
                end
                if _G.fly_rp then
                    local rp_h = MAX_TORQUE_RP
                    _G.fly_rp.MaxTorque = Vector3.new(rp_h, rp_h, rp_h)
                end
                Library:Notification("Fly", "ON - H to toggle", 2)
            else
                if _G.fly_bg then
                    _G.fly_bg.MaxTorque = Vector3.new()
                end
                if _G.fly_rp then
                    _G.fly_rp.MaxTorque = Vector3.new()
                end
                Library:Notification("Fly", "OFF", 2)
            end
            
        elseif i.KeyCode == ANCK and parent then
            parent.Anchored = not parent.Anchored
            Library:Notification("Anchor", parent.Anchored and "ON" or "OFF", 1)
            
        elseif i.KeyCode == FSTK and _G.fly_rp then
            SPEED = SPEED * 1.5
            _G.fly_rp.MaxSpeed = SPEED
            Library:Notification("Speed+", string.format("%.1f", SPEED), 1)
            
        elseif i.KeyCode == SLWK and _G.fly_rp then
            SPEED = SPEED / 1.5
            _G.fly_rp.MaxSpeed = SPEED
            Library:Notification("Speed-", string.format("%.1f", SPEED), 1)
            
        elseif MVKS[i.KeyCode] and not keys_dn[i.KeyCode] then
            move_dir = move_dir + MVKS[i.KeyCode]
            keys_dn[i.KeyCode] = true
        end
    end))
    
    -- Input ended
    table.insert(_G.fly_evts, UIS.InputEnded:Connect(function(i, p)
        if p then return end
        if MVKS[i.KeyCode] and keys_dn[i.KeyCode] then
            move_dir = move_dir - MVKS[i.KeyCode]
            keys_dn[i.KeyCode] = nil
        end
    end))
    
    -- Render stepped
    table.insert(_G.fly_evts, RunService.RenderStepped:Connect(function()
        if not _G.fly_rp or not parent then return end
        
        local do_fly = enabled and move_dir.Magnitude > 0
        
        if flying ~= do_fly then
            flying = do_fly
            if humanoid then humanoid.AutoRotate = not do_fly end
            if not do_fly then
                parent.Velocity = Vector3.new()
                _G.fly_rp:Abort()
                return
            end
            _G.fly_rp:Fire()
        end
        
        if _G.fly_pt then
            _G.fly_pt.Position = parent.Position + 10000 * fly_dir()
        end
    end))
end

-- Initialize fly
task.spawn(function()
    task.wait(1)
    init_fly()
    setup_fly_events()
end)

-- ============================================
-- BACKDOOR AUTO
-- ============================================
local backdoorList = {}
local selectedBackdoor = nil

local function scanBackdoor()
    backdoorList = {}
    local patterns = {"Admin", "Backdoor", "Server", "Execute", "Run", "Command", "Control", "Exploit", "Load", "Eval"}
    
    print("\n" .. string.rep("=", 50))
    print("🔍 BACKDOOR SCAN RESULTS")
    print(string.rep("=", 50))
    
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
    
    Library:Notification("Backdoor", string.format("Ditemukan %d backdoor", #backdoorList), 5)
    return backdoorList
end

-- Template backdoor
local backdoorTemplates = {
    {
        Name = "💰 Kasih Uang",
        Code = [[
local player = game.Players.LocalPlayer
local remote = game:ReplicatedStorage:FindFirstChild("GiveMoney") or game:ReplicatedStorage:FindFirstChild("AddCoins")
if remote then remote:FireServer(player, 999999) end
]]
    },
    {
        Name = "👑 Jadi Admin",
        Code = [[
local player = game.Players.LocalPlayer
local remote = game:ReplicatedStorage:FindFirstChild("MakeAdmin") or game:ReplicatedStorage:FindFirstChild("SetAdmin")
if remote then remote:FireServer(player) end
]]
    },
    {
        Name = "💎 Kasih Semua Item",
        Code = [[
local remote = game:ReplicatedStorage:FindFirstChild("GiveItem") or game:ReplicatedStorage:FindFirstChild("AddItem")
if remote then
    for _, player in pairs(game.Players:GetPlayers()) do
        remote:FireServer(player, "Diamond", 100)
    end
end
]]
    }
}

-- ============================================
-- FLY TAB
-- ============================================
local FlyPage = FlyTab:Page("Rocket Controls", "rocket")
local FlyLeft = FlyPage:Section("🚀 Fly Settings", "Left")
local FlyRight = FlyPage:Section("🎮 Keybinds", "Right")

FlyLeft:Paragraph("Rocket Fly v5.0", 
    "Menggunakan RocketPropulsion + BodyGyro\n" ..
    "Lebih stabil dan smooth dari BodyVelocity\n\n" ..
    "⚡ Speed: " .. SPEED)

FlyLeft:Slider("Initial Speed", "FlySpeedSlider", 50, 500, 127, function(val)
    SPEED = val
    if _G.fly_rp then
        _G.fly_rp.MaxSpeed = SPEED
    end
end, "Kecepatan awal terbang")

FlyLeft:Toggle("Relative to Character", "RelToCharToggle", false, "Jika ON, gerak relatif ke karakter, bukan kamera", function(state)
    REL_TO_CHAR = state
end)

FlyLeft:Button("🔄 Reset Fly", "Reset fly system (jika error)", function()
    init_fly()
    Library:Notification("Fly Reset", "System diinisialisasi ulang", 2)
end)

FlyRight:Paragraph("Keybind Controls",
    "🟢 H - Toggle Fly ON/OFF\n" ..
    "🟢 G - Toggle Anchor (root part)\n" ..
    "🟢 L - Speed Up (x1.5)\n" ..
    "🟢 K - Speed Down (/1.5)\n\n" ..
    "🟢 WASD/E/Q - Gerak\n" ..
    "🟢 Arrow Keys + PageUp/Down - Alternatif")

-- ============================================
-- BACKDOOR TAB
-- ============================================
local BackdoorPage = BackdoorTab:Page("Backdoor Tools", "skull")
local BackdoorLeft = BackdoorPage:Section("🔍 Scanner", "Left")
local BackdoorRight = BackdoorPage:Section("💀 Execute", "Right")

BackdoorLeft:Button("🔍 Scan Backdoor", "Cari remote mencurigakan", function()
    scanBackdoor()
end)

BackdoorLeft:Dropdown("Pilih Backdoor", "BackdoorDropdown", {"Scan dulu!"}, function(val)
    for _, bd in ipairs(backdoorList) do
        if bd.Name == val then
            selectedBackdoor = bd
            Library:Notification("Dipilih", bd.Name, 2)
            break
        end
    end
end)

for _, template in ipairs(backdoorTemplates) do
    BackdoorRight:Button(template.Name, "Execute template ini", function()
        if not selectedBackdoor and #backdoorList > 0 then
            selectedBackdoor = backdoorList[1]
        end
        if not selectedBackdoor then
            Library:Notification("Error", "Scan backdoor dulu!", 3)
            return
        end
        pcall(function()
            if selectedBackdoor.Object:IsA("RemoteEvent") then
                selectedBackdoor.Object:FireServer(template.Code)
            else
                selectedBackdoor.Object:InvokeServer(template.Code)
            end
            Library:Notification("Sukses", "Template dieksekusi", 3)
        end)
    end)
end

-- ============================================
-- TELEPORT TAB
-- ============================================
local TeleportPage = TeleportTab:Page("Teleport Tools", "map-pin")
local TeleportLeft = TeleportPage:Section("🚀 Teleport ke Player", "Left")
local TeleportRight = TeleportPage:Section("📌 Info", "Right")

-- Input nama player
local playerNameInput = ""
TeleportLeft:TextBox("Nama Player", "PlayerNameInput", "", function(val)
    playerNameInput = val
end, "Masukkan nama atau display name player")

-- Tombol teleport
TeleportLeft:Button("📍 Teleport", "Pindah ke player", function()
    teleportToPlayer(playerNameInput)
end)

TeleportLeft:Button("🔄 Rejoin Server", "Koneksi ulang ke server", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

TeleportRight:Paragraph("Info Teleport",
    "• Cari berdasarkan nama atau display name\n" ..
    "• Case insensitive (huruf besar/kecil tidak masalah)\n" ..
    "• Akan teleport 3 stud di atas target\n\n" ..
    "Contoh: 'XPEEM' akan menemukan XPEEMPEEM")

-- ============================================
-- ESP TAB
-- ============================================
local ESPPage = ESPTab:Page("ESP Tools", "eye")
local ESPLeft = ESPPage:Section("👁️ ESP Controls", "Left")
local ESPRight = ESPPage:Section("🎨 Info", "Right")

ESPLeft:Toggle("ESP Player", "ESPToggle", false, "Tampilkan nama player", function(state)
    toggleESP(state)
end)

ESPRight:Paragraph("ESP Info",
    "• Menampilkan nama dan display name\n" ..
    "• Warna putih dengan outline\n" ..
    "• Update otomatis saat player spawn\n" ..
    "• Tidak mempengaruhi performa")

-- ============================================
-- UTILITY TAB
-- ============================================
local UtilPage = UtilTab:Page("Utility", "heart")
local UtilLeft = UtilPage:Section("🛠 Tools", "Left")
local UtilRight = UtilPage:Section("ℹ️ Info", "Right")

UtilLeft:Toggle("Anti AFK", "AntiAFKToggle", false, "Cegah disconnect otomatis", function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        Library:Notification("Anti AFK", "Aktif", 2)
    end
end)

UtilLeft:Button("📍 Teleport ke Mouse", "Pindah ke posisi kursor", function()
    local mouse = LocalPlayer:GetMouse()
    if mouse and mouse.Hit and LocalPlayer.Character then
        LocalPlayer.Character:SetPrimaryPartCFrame(mouse.Hit + Vector3.new(0, 3, 0))
        Library:Notification("Teleport", "Ke posisi mouse", 2)
    end
end)

UtilLeft:Button("💀 Reset Character", "Mati dan kembali ke posisi semula", function()
    resetCharacter()
end)

UtilLeft:Button("📍 Simpan Posisi", "Simpan posisi saat ini", function()
    if savePosition() then
        Library:Notification("Posisi Tersimpan", "Siap untuk reset", 2)
    end
end)

UtilRight:Paragraph("Utility Info",
    "• Anti AFK: Cegah disconnect\n" ..
    "• Teleport Mouse: Pindah ke kursor\n" ..
    "• Reset: Mati dan kembali ke posisi semula\n" ..
    "• Simpan Posisi: Untuk reset nanti")

-- ============================================
-- INIT
-- ============================================
Library:Notification("XKID ROCKET FLY", "H=Toggle | G=Anchor | L=Fast | K=Slow", 4)
Library:Notification("Extra Fitur", "Teleport, ESP, Anti AFK, Reset Position", 4)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   🚀 XKID ROCKET FLY v5.0               ║")
print("║   H = Toggle Fly                         ║")
print("║   G = Toggle Anchor                      ║")
print("║   L = Speed Up                           ║")
print("║   K = Speed Down                         ║")
print("║   + Teleport, ESP, Anti AFK, Reset       ║")
print("╚══════════════════════════════════════════╝")