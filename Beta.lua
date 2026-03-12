--[[
WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]

-- XKID BASIC HUB v1.0 (PASTI JALAN)
-- Fitur: Teleport Player, ESP Sederhana, Anti AFK

-- Load Aurora UI (ringan)
Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

local Win = Library:Window(
    "✨ XKID BASIC", 
    "zap", 
    "v1.0 | Lightweight", 
    false
)

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

-- ============================================
-- TELEPORT FUNCTION
-- ============================================
local function teleportToPlayer(name)
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(name:lower()) or player.DisplayName:lower():find(name:lower()) then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetPos = player.Character.HumanoidRootPart.Position
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos.X, targetPos.Y + 5, targetPos.Z)
                    Library:Notification("Teleport", "Ke " .. player.Name, 2)
                    return true
                end
            end
        end
    end
    Library:Notification("Error", "Player tidak ditemukan", 2)
    return false
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
                        bill.Size = UDim2.new(0, 100, 0, 30)
                        bill.StudsOffset = Vector3.new(0, 2, 0)
                        bill.AlwaysOnTop = true
                        bill.Adornee = head
                        bill.Parent = char
                        
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text = player.Name
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
-- UI TABS
-- ============================================
local MainTab = Win:Tab("Main", "zap")
local MainPage = MainTab:Page("Controls", "zap")
local MainLeft = MainPage:Section("🚀 Teleport", "Left")
local MainRight = MainPage:Section("👁️ ESP", "Right")

-- Teleport
MainLeft:TextBox("Nama Player", "PlayerName", "", function(txt)
    _G.targetName = txt
end)

MainLeft:Button("📡 Teleport", "Pindah ke player", function()
    if _G.targetName then
        teleportToPlayer(_G.targetName)
    end
end)

MainLeft:Button("🔄 Rejoin Server", "Koneksi ulang", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

MainLeft:Toggle("Anti AFK", "AntiAFKToggle", false, "Cegah disconnect", function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- ESP
MainRight:Toggle("ESP Player", "ESPToggle", false, "Tampilkan nama player", function(state)
    toggleESP(state)
end)

MainRight:Button("📍 Koordinat Saya", "Lihat posisi", function()
    if LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local p = root.Position
            Library:Notification("Posisi", string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 4)
        end
    end
end)

MainRight:Button("💀 Reset Character", "Mati lalu respawn", function()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
end)

-- ============================================
-- INFO TAB
-- ============================================
local InfoTab = Win:Tab("Info", "info")
local InfoPage = InfoTab:Page("About", "info")
local InfoLeft = InfoPage:Section("ℹ️ Info", "Left")

InfoLeft:Paragraph("XKID BASIC v1.0",
    "Fitur:\n" ..
    "✅ Teleport ke player\n" ..
    "✅ ESP sederhana\n" ..
    "✅ Anti AFK\n" ..
    "✅ Rejoin server\n" ..
    "✅ Koordinat\n" ..
    "✅ Reset character\n\n" ..
    "Lightweight & PASTI JALAN!")

-- ============================================
-- INIT
-- ============================================
Library:Notification("XKID BASIC", "Loaded! ✅", 3)
Library:ConfigSystem(Win)

print("=== XKID BASIC LOADED ===")
print("Fitur: Teleport, ESP, Anti AFK")