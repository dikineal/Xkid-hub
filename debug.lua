--====================================================
-- XKID HUB | SAWAH INDO PRO+
--====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "PRO+ EDITION",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKIDHub",
        FileName = "SawahConfig"
    },
    KeySystem = false
})

--====================================================
-- SERVICES
--====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

--====================================================
-- TABS
--====================================================
local FarmingTab    = Window:CreateTab("🌾 Farming", 4483362458)
local ProtectTab    = Window:CreateTab("🛡 Protection", 4483362458)
local TeleportTab   = Window:CreateTab("📍 Teleport", 4483362458)
local UtilityTab    = Window:CreateTab("⚙ Utility", 4483362458)
local ConfigTab     = Window:CreateTab("💾 Config", 4483362458)

--====================================================
-- SETTINGS STATE
--====================================================
local Settings = {
    AutoFarm = false,
    AutoSell = false,
    AutoBuy  = false,
    LightningProtection = true,
    AntiAFK  = true,
    AutoShower = false,
}

local SeedName = "Bibit Padi"
local FarmSpeed = 0.18
local JumlahBeli = 15
local JumlahTanam = 15
local LahanPos = nil
local GazeboPos = nil
local LastPos = nil

--====================================================
-- UTILITY FUNCTIONS
--====================================================
local function notif(judul, isi, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = judul,
            Text = isi,
            Duration = dur or 3
        })
    end)
    print("[XKID] "..judul.." — "..isi)
end

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPos()
    local r = getRoot()
    return r and r.Position
end

local function saveLastPos()
    LastPos = getPos()
end

local function tp(obj)
    if not obj then return false end
    local root = getRoot()
    if not root then return false end
    
    local pos
    if obj:IsA("BasePart") then
        pos = obj.Position
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            pos = obj.PrimaryPart.Position
        elseif obj:FindFirstChild("HumanoidRootPart") then
            pos = obj.HumanoidRootPart.Position
        elseif obj:FindFirstChild("Head") then
            pos = obj.Head.Position
        end
    end
    
    if not pos then return false end
    saveLastPos()
    root.CFrame = CFrame.new(pos.X, pos.Y+5, pos.Z)
    task.wait(0.3)
    return true
end

local function cari(nama)
    nama = nama:lower()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower() == nama then
            return v
        end
    end
end

--====================================================
-- PLACEHOLDER FUNCTIONS (ISI SESUAI GAME-MU)
--====================================================

-- Fungsi Beli Bibit
local function BuySeeds()
    -- TODO: Implementasi beli bibit
    -- Contoh: Fire remote GetBibit, klik GUI, dll
    notif("Buy Seeds", "Fungsi belum diimplementasi", 2)
end

-- Fungsi Jual Hasil
local function SellCrops()
    -- TODO: Implementasi jual hasil
    -- Contoh: Fire remote SellCrop, klik tombol jual
    notif("Sell Crops", "Fungsi belum diimplementasi", 2)
end

-- Fungsi Tanam
local function PlantSeeds()
    -- TODO: Implementasi tanam
    notif("Plant", "Fungsi belum diimplementasi", 2)
end

-- Fungsi Panen
local function Harvest()
    -- TODO: Implementasi panen
    notif("Harvest", "Fungsi belum diimplementasi", 2)
end

-- Fungsi Scan Farm Area
local function ScanFarm()
    -- TODO: Scan area sawah di sekitar
    local count = 0
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:lower():find("tanah") or v.Name:lower():find("lahan")) then
            count = count + 1
        end
    end
    notif("Scan Farm", "Ditemukan "..count.." lahan", 3)
end

-- Fungsi Teleport ke NPC
local function TeleportNPC(nama)
    local obj = cari(nama)
    if obj then
        tp(obj)
        notif("TP", "Ke "..nama, 2)
    else
        notif("Error", nama.." tidak ditemukan", 3)
    end
end

-- Fungsi Teleport Safe Zone
local function TeleportSafe()
    if GazeboPos then
        getRoot().CFrame = CFrame.new(GazeboPos.X, GazeboPos.Y+5, GazeboPos.Z)
        notif("TP Safe", "Ke Gazebo", 2)
    else
        notif("Error", "Simpan posisi Gazebo dulu", 3)
    end
end

-- Fungsi Teleport ke Farm Center
local function TeleportFarm()
    if LahanPos then
        getRoot().CFrame = CFrame.new(LahanPos.X, LahanPos.Y+5, LahanPos.Z)
        notif("TP Farm", "Ke tengah lahan", 2)
    else
        notif("Error", "Simpan posisi lahan dulu", 3)
    end
end

--====================================================
-- ANTI AFK
--====================================================
if Settings.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

--====================================================
-- 🌾 FARMING TAB
--====================================================
FarmingTab:CreateSection("🌱 Auto Controls")

FarmingTab:CreateToggle({
    Name = "🔥 Auto Farm",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoFarm = v
        if v then
            notif("Auto Farm", "ON", 2)
            -- TODO: Tambah loop auto farm di sini
        end
    end
})

FarmingTab:CreateToggle({
    Name = "💰 Auto Sell",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoSell = v
    end
})

FarmingTab:CreateToggle({
    Name = "🛒 Auto Buy",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoBuy = v
    end
})

FarmingTab:CreateSection("🌾 Manual Actions")

FarmingTab:CreateDropdown({
    Name = "🌱 Seed Selector",
    Options = {"Bibit Padi","Bibit Jagung","Bibit Tomat","Bibit Terong","Bibit Strawberry","Bibit Sawit","Bibit Durian"},
    CurrentOption = "Bibit Padi",
    Callback = function(v)
        SeedName = v
    end
})

FarmingTab:CreateSlider({
    Name = "⚡ Farm Speed",
    Range = {0.05, 0.5},
    Increment = 0.01,
    CurrentValue = 0.18,
    Callback = function(v)
        FarmSpeed = v
    end
})

FarmingTab:CreateSlider({
    Name = "📦 Jumlah Beli",
    Range = {1, 99},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(v)
        JumlahBeli = v
    end
})

FarmingTab:CreateSlider({
    Name = "🌱 Jumlah Tanam",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(v)
        JumlahTanam = v
    end
})

FarmingTab:CreateButton({
    Name = "💳 Buy Seeds",
    Callback = BuySeeds
})

FarmingTab:CreateButton({
    Name = "🌱 Plant Seeds",
    Callback = PlantSeeds
})

FarmingTab:CreateButton({
    Name = "🌽 Harvest",
    Callback = Harvest
})

FarmingTab:CreateButton({
    Name = "💰 Sell Crops",
    Callback = SellCrops
})

FarmingTab:CreateButton({
    Name = "🔍 Scan Farm Area",
    Callback = ScanFarm
})

--====================================================
-- 🛡 PROTECTION TAB
--====================================================
ProtectTab:CreateSection("⚡ Protection")

ProtectTab:CreateToggle({
    Name = "⚡ Lightning Protection",
    CurrentValue = true,
    Callback = function(v)
        Settings.LightningProtection = v
        -- TODO: Implementasi lightning detector
    end
})

ProtectTab:CreateToggle({
    Name = "💤 Anti AFK",
    CurrentValue = true,
    Callback = function(v)
        Settings.AntiAFK = v
    end
})

ProtectTab:CreateToggle({
    Name = "🚿 Auto Mandi",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoShower = v
        -- TODO: Implementasi auto mandi
    end
})

--====================================================
-- 📍 TELEPORT TAB
--====================================================
TeleportTab:CreateSection("🏪 NPC Teleport")

TeleportTab:CreateButton({
    Name = "🌱 NPC Bibit",
    Callback = function() TeleportNPC("npcbibit") end
})

TeleportTab:CreateButton({
    Name = "💰 NPC Jual",
    Callback = function() TeleportNPC("npcpenjual") end
})

TeleportTab:CreateButton({
    Name = "🔧 NPC Alat",
    Callback = function() TeleportNPC("npcalat") end
})

TeleportTab:CreateButton({
    Name = "🥚 NPC Telur",
    Callback = function() TeleportNPC("NPCPedagangTelur") end
})

TeleportTab:CreateButton({
    Name = "🌴 NPC Sawit",
    Callback = function() TeleportNPC("NPCPedagangSawit") end
})

TeleportTab:CreateSection("📍 Location Marks")

TeleportTab:CreateButton({
    Name = "📍 Save Farm Position",
    Callback = function()
        LahanPos = getPos()
        if LahanPos then
            notif("Farm Position Saved", "", 2)
        end
    end
})

TeleportTab:CreateButton({
    Name = "🌾 Teleport to Farm",
    Callback = TeleportFarm
})

TeleportTab:CreateButton({
    Name = "📍 Save Safe Zone",
    Callback = function()
        GazeboPos = getPos()
        if GazeboPos then
            notif("Safe Zone Saved", "", 2)
        end
    end
})

TeleportTab:CreateButton({
    Name = "🏠 Teleport to Safe Zone",
    Callback = TeleportSafe
})

TeleportTab:CreateButton({
    Name = "↩️ Back to Last Position",
    Callback = function()
        if LastPos and getRoot() then
            getRoot().Position = LastPos
            notif("Back", "Kembali", 2)
        end
    end
})

--====================================================
-- ⚙ UTILITY TAB
--====================================================
UtilityTab:CreateSection("🛠 Tools")

UtilityTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end
})

UtilityTab:CreateButton({
    Name = "🚀 FPS Boost",
    Callback = function()
        for _,v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
            end
        end
        game:GetService("Lighting").GlobalShadows = false
        notif("FPS Boost", "Aktif!", 2)
    end
})

UtilityTab:CreateButton({
    Name = "📍 My Coordinates",
    Callback = function()
        local pos = getPos()
        if pos then
            notif("Position", string.format("X: %.1f\nY: %.1f\nZ: %.1f", pos.X, pos.Y, pos.Z), 5)
        end
    end
})

UtilityTab:CreateButton({
    Name = "💀 Reset Character",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end
})

--====================================================
-- 💾 CONFIG TAB
--====================================================
ConfigTab:CreateSection("⚙ Configuration")

ConfigTab:CreateParagraph({
    Title = "Info",
    Content = "Config akan tersimpan otomatis oleh Rayfield.\nSettings akan diingat setiap kali script dijalankan."
})

ConfigTab:CreateButton({
    Name = "💾 Save Config Now",
    Callback = function()
        notif("Config", "Tersimpan otomatis", 2)
    end
})

ConfigTab:CreateButton({
    Name = "⛔ STOP ALL AUTOS",
    Callback = function()
        Settings.AutoFarm = false
        Settings.AutoBuy = false
        Settings.AutoSell = false
        Settings.AutoShower = false
        notif("STOP", "Semua auto dimatikan", 3)
    end
})

--====================================================
-- MAIN LOOP (TEMPLATE)
--====================================================
task.spawn(function()
    while task.wait(1) do
        if Settings.AutoFarm then
            -- TODO: Implement auto farm logic
            -- Contoh: Beli -> Tanam -> Tunggu -> Panen -> Jual
        end
        
        if Settings.AutoBuy then
            -- TODO: Auto buy logic
        end
        
        if Settings.AutoSell then
            -- TODO: Auto sell logic
        end
        
        if Settings.AutoShower then
            -- TODO: Auto shower logic
        end
    end
end)

--====================================================
-- INIT
--====================================================
notif("🌾 SAWAH INDO PRO+", "Welcome! Script siap digunakan 🔥", 4)
print("=== XKID HUB PRO+ LOADED ===")
print("📌 Fitur: Auto Farm, Teleport, Protection")
print("📌 Isi placeholder functions sesuai game Anda")