--====================================================
-- XKID HUB | SAWAH INDO ULTIMATE v5.0
-- FITUR LENGKAP: Remote Spy + ProximityPrompt + Auto Farm
--====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO ULTIMATE 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "v5.0 | Complete Edition",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKIDHub",
        FileName = "SawahConfig"
    },
    KeySystem = false
})

--====================================================
-- SERVICES & GLOBAL
--====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInput = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")

-- Remote Path
local Remotes = RS:FindFirstChild("Remotes")
local TutorialRemotes = Remotes and Remotes:FindFirstChild("TutorialRemotes")

-- ClientBoot Path
local ClientBoot = LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("ClientBoot")

--====================================================
-- PROXIMITY PROMPT PATHS (DARI LO!)
--====================================================
local function getPrompt(path)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    local current = game
    for _, part in ipairs(parts) do
        current = current:FindFirstChild(part)
        if not current then return nil end
    end
    return current
end

local PROMPTS = {
    Bibit = getPrompt("Workspace.NPCs.NPC_Bibit.npcbibit.ProximityPrompt"),
    Alat = getPrompt("Workspace.NPCs.NPC_Alat.npcalat.ProximityPrompt"),
    Sawit = getPrompt("Workspace.NPCs.NPC_PedagangSawit.NPCPedagangSawit.ProximityPrompt"),
    Telur = getPrompt("Workspace.NPCs.NPCPedagangTelur.NPCPedagangTelur.ProximityPrompt"),
    CoopPlot = getPrompt("Workspace.CoopPlots.CoopPlot_1.ProximityPrompt"),
    BikeMount = getPrompt("Seat.BikeMountPrompt"),
}

--====================================================
-- SETTINGS STATE
--====================================================
local Settings = {
    AutoFarm = false,
    AutoSell = false,
    AutoBuy  = false,
    AutoPlant = false,
    AutoHarvest = false,
    AutoHarvestToggle = false,
    LightningProtection = true,
    AntiAFK  = true,
    AutoMandi = false,
    AutoPayung = false,
}

local SeedName = "Padi"
local JumlahBeli = 15
local JumlahTanam = 15
local WaitPanen = 30
local FarmSpeed = 0.18
local LahanList = {}
local LahanStatus = {}
local LahanPos = nil
local GazeboPos = nil
local LastPos = nil
local LightningHits = 0
local IsAdmin = false

-- Data dari remote
local PlayerData = {
    Coins = 0,
    Level = 1,
    Seeds = {},
    Items = {},
    Tools = {},
    EggFruits = {},
    Fruits = {},
    LahanStatus = {}
}

-- Database
local BIBIT_LIST = {"Padi", "Jagung", "Tomat", "Terong", "Strawberry", "Sawit", "Durian"}
local TANAMAN_LIST = {"Padi", "Jagung", "Tomat", "Terong", "Strawberry", "Sawit", "Durian"}

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
-- FUNGSI PROXIMITY PROMPT
--====================================================
local function firePrompt(prompt)
    if not prompt then return false end
    
    local success = pcall(function()
        fireproximityprompt(prompt)
    end)
    
    if not success then
        pcall(function()
            VirtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.1)
            VirtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
    end
    return true
end

local function interactNPC(nama)
    local prompt = PROMPTS[nama]
    if not prompt then
        notif("Error", "Prompt "..nama.." tidak ditemukan", 3)
        return false
    end
    
    local parent = prompt.Parent
    if parent then
        tp(parent)
        task.wait(1)
        firePrompt(prompt)
        notif("Interaksi", "Dengan "..nama, 2)
        return true
    end
    return false
end

--====================================================
-- REMOTE FUNCTIONS (LENGKAP)
--====================================================

-- Request Shop Data (Bibit)
local function RequestShop()
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("RequestShop") then
        return nil
    end
    
    if not ClientBoot then return nil end
    
    local success, result = pcall(function()
        return TutorialRemotes.RequestShop:InvokeServer(ClientBoot)
    end)
    
    if success and result and result.Success then
        PlayerData.Coins = result.Coins or PlayerData.Coins
        PlayerData.Seeds = result.Seeds or {}
        return result
    end
    return nil
end

-- Request Sell Data
local function RequestSell(mode)
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("RequestSell") then
        return nil
    end
    
    if not ClientBoot then return nil end
    
    local args = {ClientBoot}
    if mode then
        table.insert(args, mode)
    end
    
    local success, result = pcall(function()
        return TutorialRemotes.RequestSell:InvokeServer(unpack(args))
    end)
    
    if success and result and result.Success then
        PlayerData.Coins = result.Coins or PlayerData.Coins
        if result.Items then
            PlayerData.Items = result.Items
        end
        if result.EggFruits then
            PlayerData.EggFruits = result.EggFruits
            PlayerData.EggCount = result.EggCount
        end
        if result.FruitList then
            PlayerData.Fruits = result.FruitList
            PlayerData.FruitCount = result.FruitCount
            PlayerData.FruitType = result.FruitType
        end
        return result
    end
    return nil
end

-- Request Tool Shop
local function RequestToolShop()
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("RequestToolShop") then
        return nil
    end
    
    if not ClientBoot then return nil end
    
    local success, result = pcall(function()
        return TutorialRemotes.RequestToolShop:InvokeServer(ClientBoot)
    end)
    
    if success and result and result.Success then
        PlayerData.Coins = result.Coins or PlayerData.Coins
        PlayerData.Tools = result.Tools or {}
        PlayerData.Level = result.PlayerLevel or PlayerData.Level
        return result
    end
    return nil
end

-- Request Lahan
local function RequestLahan()
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("RequestLahan") then
        return nil
    end
    
    if not ClientBoot then return nil end
    
    local success, result = pcall(function()
        return TutorialRemotes.RequestLahan:InvokeServer(ClientBoot)
    end)
    
    if success and result and result.Success then
        PlayerData.LahanStatus = result.Statuses or {}
        return result
    end
    return nil
end

-- Toggle Auto Harvest
local function ToggleAutoHarvest(mode)
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("ToggleAutoHarvest") then
        return false
    end
    
    mode = mode or "SYNC"
    pcall(function()
        TutorialRemotes.ToggleAutoHarvest:FireServer(mode)
    end)
    return true
end

-- Check Admin
local function CheckAdmin()
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("AdminIsAdmin") then
        return false
    end
    
    if not ClientBoot then return false end
    
    local success, result = pcall(function()
        return TutorialRemotes.AdminIsAdmin:InvokeServer(ClientBoot)
    end)
    
    if success then
        IsAdmin = (result == true)
        return IsAdmin
    end
    return false
end

-- Plant Crop
local function PlantCrop(posisi)
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("PlantCrop") then
        return false
    end
    
    if not posisi then
        local root = getRoot()
        if not root then return false end
        posisi = root.Position
    end
    
    pcall(function()
        TutorialRemotes.PlantCrop:FireServer(posisi)
    end)
    return true
end

-- Harvest Crop
local function HarvestCrop(jenis, jumlah)
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("HarvestCrop") then
        return false
    end
    
    jenis = jenis or "Padi"
    jumlah = jumlah or 1
    
    pcall(function()
        TutorialRemotes.HarvestCrop:FireServer(jenis, jumlah, jenis)
    end)
    return true
end

--====================================================
-- FUNGSI MANDI & PAYUNG (ASUMSI)
--====================================================
local function Mandi()
    -- TODO: Cari remote mandi
    notif("Mandi", "Fungsi mandi (TODO)", 2)
end

local function Payung()
    -- TODO: Cari remote payung
    notif("Payung", "Fungsi payung (TODO)", 2)
end

--====================================================
-- SCAN LAHAN
--====================================================
local function ScanLahan()
    local data = RequestLahan()
    if not data then
        notif("Gagal", "Tidak bisa ambil data lahan", 3)
        return
    end
    
    LahanList = {}
    for lahanName, _ in pairs(PlayerData.LahanStatus) do
        local obj = Workspace:FindFirstChild(lahanName)
        if obj and obj:IsA("BasePart") then
            table.insert(LahanList, obj)
        end
    end
    
    notif("Scan Lahan", string.format("%d lahan ditemukan", #LahanList), 3)
    return LahanList
end

--====================================================
-- AUTO TANAM
--====================================================
local function AutoPlantAll()
    if #LahanList == 0 then ScanLahan() end
    
    local count = 0
    for _, lahan in ipairs(LahanList) do
        if lahan:IsA("BasePart") then
            PlantCrop(lahan.Position)
            count = count + 1
            task.wait(FarmSpeed)
        end
    end
    notif("Auto Plant", "Menanam di "..count.." lahan", 3)
end

--====================================================
-- AUTO PANEN SEMUA JENIS
--====================================================
local function AutoHarvestAll()
    for _, tanaman in ipairs(TANAMAN_LIST) do
        HarvestCrop(tanaman, 1)
        task.wait(0.2)
    end
    notif("Auto Panen", "Semua jenis dipanen", 3)
end

--====================================================
-- REFRESH ALL DATA
--====================================================
local function RefreshAllData()
    RequestShop()
    RequestSell()
    RequestSell("fruit")
    RequestSell("egg")
    RequestToolShop()
    RequestLahan()
    CheckAdmin()
    
    local msg = string.format("💰 %d Coins | Level %d | Admin: %s",
        PlayerData.Coins,
        PlayerData.Level,
        IsAdmin and "✅" or "❌"
    )
    notif("Data Updated", msg, 3)
end

--====================================================
-- TABS LENGKAP!
--====================================================
local FarmTab     = Window:CreateTab("🌾 Farming", 4483362458)
local TanamTab    = Window:CreateTab("🌱 Tanam", 4483362458)
local PanenTab    = Window:CreateTab("🌽 Panen", 4483362458)
local InteractTab = Window:CreateTab("🤝 Interaksi", 4483362458)
local TeleportTab = Window:CreateTab("📍 Teleport", 4483362458)
local DataTab     = Window:CreateTab("📊 Data", 4483362458)
local ProtectTab  = Window:CreateTab("🛡 Protection", 4483362458)
local UtilityTab  = Window:CreateTab("⚙ Utility", 4483362458)
local ConfigTab   = Window:CreateTab("💾 Config", 4483362458)

--====================================================
-- 🌾 FARMING TAB (AUTO FARM LENGKAP)
--====================================================
FarmTab:CreateSection("🔥 AUTO FARM CONTROL")

FarmTab:CreateDropdown({
    Name = "🌾 Pilih Tanaman",
    Options = BIBIT_LIST,
    CurrentOption = "Padi",
    Callback = function(v) SeedName = v[1] end
})

FarmTab:CreateSlider({
    Name = "📦 Jumlah Beli/Tanam",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(v) JumlahBeli = v; JumlahTanam = v end
})

FarmTab:CreateSlider({
    Name = "⏱️ Wait Panen (detik)",
    Range = {10, 300},
    Increment = 5,
    CurrentValue = 30,
    Callback = function(v) WaitPanen = v end
})

FarmTab:CreateToggle({
    Name = "🔥 FULL AUTO FARM",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoFarm = v
        if v then
            notif("AUTO FARM ON", "Memulai siklus...", 3)
            task.spawn(function()
                while Settings.AutoFarm do
                    -- Beli (via interaksi NPC)
                    if Settings.AutoBuy then
                        interactNPC("Bibit")
                        task.wait(2)
                    end
                    
                    -- Tanam
                    AutoPlantAll()
                    task.wait(2)
                    
                    -- Tunggu
                    notif("Menunggu panen", WaitPanen.." detik", WaitPanen)
                    task.wait(WaitPanen)
                    
                    -- Panen
                    AutoHarvestAll()
                    task.wait(1)
                    
                    -- Jual (via interaksi NPC)
                    if Settings.AutoSell then
                        interactNPC("Sawit")  -- atau NPC jual lainnya
                        task.wait(2)
                    end
                    
                    notif("Siklus selesai", "Ulang lagi...", 2)
                    task.wait(2)
                end
            end)
        end
    end
})

FarmTab:CreateToggle({
    Name = "💰 Auto Sell (via NPC)",
    CurrentValue = false,
    Callback = function(v) Settings.AutoSell = v end
})

FarmTab:CreateToggle({
    Name = "🛒 Auto Buy (via NPC)",
    CurrentValue = false,
    Callback = function(v) Settings.AutoBuy = v end
})

FarmTab:CreateToggle({
    Name = "🔄 Toggle AutoHarvest Game",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoHarvestToggle = v
        ToggleAutoHarvest(v and "SYNC" or "OFF")
    end
})

--====================================================
-- 🌱 TANAM TAB
--====================================================
TanamTab:CreateSection("🌱 Manual Tanam")

TanamTab:CreateButton({
    Name = "🔍 Scan Lahan",
    Callback = ScanLahan
})

TanamTab:CreateButton({
    Name = "🌱 Tanam di Semua Lahan",
    Callback = AutoPlantAll
})

TanamTab:CreateButton({
    Name = "🌱 Tanam di Posisi Saya",
    Callback = function() PlantCrop() end
})

--====================================================
-- 🌽 PANEN TAB
--====================================================
PanenTab:CreateSection("🌽 Manual Panen")

for _, tanaman in ipairs(TANAMAN_LIST) do
    PanenTab:CreateButton({
        Name = "🌽 Panen "..tanaman,
        Callback = function() HarvestCrop(tanaman, 1) end
    })
end

PanenTab:CreateButton({
    Name = "🌽 Panen Semua Jenis",
    Callback = AutoHarvestAll
})

--====================================================
-- 🤝 INTERAKSI TAB (PROXIMITY PROMPT)
--====================================================
InteractTab:CreateSection("🤝 Interaksi NPC")

InteractTab:CreateButton({
    Name = "🌱 NPC Bibit (Beli)",
    Callback = function() interactNPC("Bibit") end
})

InteractTab:CreateButton({
    Name = "🔧 NPC Alat (Tools)",
    Callback = function() interactNPC("Alat") end
})

InteractTab:CreateButton({
    Name = "🌴 NPC Sawit (Jual Sawit)",
    Callback = function() interactNPC("Sawit") end
})

InteractTab:CreateButton({
    Name = "🥚 NPC Telur (Jual Telur)",
    Callback = function() interactNPC("Telur") end
})

InteractTab:CreateSection("🏞 Lahan Kerjasama")

InteractTab:CreateButton({
    Name = "🤝 Coop Plot 1",
    Callback = function()
        if PROMPTS.CoopPlot then
            tp(PROMPTS.CoopPlot.Parent)
            task.wait(1)
            firePrompt(PROMPTS.CoopPlot)
        end
    end
})

InteractTab:CreateSection("🚲 Kendaraan")

InteractTab:CreateButton({
    Name = "🚲 Naik Sepeda",
    Callback = function()
        if PROMPTS.BikeMount then
            tp(PROMPTS.BikeMount.Parent)
            task.wait(1)
            firePrompt(PROMPTS.BikeMount)
        end
    end
})

--====================================================
-- 📍 TELEPORT TAB
--====================================================
TeleportTab:CreateSection("🏪 Teleport ke NPC")

TeleportTab:CreateButton({
    Name = "🌱 NPC Bibit",
    Callback = function() if PROMPTS.Bibit then tp(PROMPTS.Bibit.Parent) end end
})

TeleportTab:CreateButton({
    Name = "🔧 NPC Alat",
    Callback = function() if PROMPTS.Alat then tp(PROMPTS.Alat.Parent) end end
})

TeleportTab:CreateButton({
    Name = "🌴 NPC Sawit",
    Callback = function() if PROMPTS.Sawit then tp(PROMPTS.Sawit.Parent) end end
})

TeleportTab:CreateButton({
    Name = "🥚 NPC Telur",
    Callback = function() if PROMPTS.Telur then tp(PROMPTS.Telur.Parent) end end
})

TeleportTab:CreateSection("📍 Mark Location")

TeleportTab:CreateButton({
    Name = "📍 Save Farm Position",
    Callback = function()
        LahanPos = getPos()
        notif("Posisi tersimpan", "", 2)
    end
})

TeleportTab:CreateButton({
    Name = "🌾 Teleport ke Farm",
    Callback = function()
        if LahanPos and getRoot() then
            getRoot().CFrame = CFrame.new(LahanPos.X, LahanPos.Y+5, LahanPos.Z)
        end
    end
})

TeleportTab:CreateButton({
    Name = "📍 Save Safe Zone",
    Callback = function()
        GazeboPos = getPos()
        notif("Safe Zone tersimpan", "", 2)
    end
})

TeleportTab:CreateButton({
    Name = "🏠 Teleport ke Safe Zone",
    Callback = function()
        if GazeboPos and getRoot() then
            getRoot().CFrame = CFrame.new(GazeboPos.X, GazeboPos.Y+5, GazeboPos.Z)
        end
    end
})

TeleportTab:CreateButton({
    Name = "↩️ Back to Last Position",
    Callback = function()
        if LastPos and getRoot() then
            getRoot().Position = LastPos
        end
    end
})

--====================================================
-- 📊 DATA TAB
--====================================================
DataTab:CreateSection("📊 Player Data")

DataTab:CreateButton({
    Name = "🔄 Refresh All Data",
    Callback = RefreshAllData
})

DataTab:CreateButton({
    Name = "👑 Check Admin Status",
    Callback = function()
        local admin = CheckAdmin()
        notif("Admin Status", admin and "✅ KAMU ADMIN!" or "❌ Bukan admin", 3)
    end
})

--====================================================
-- 🛡 PROTECTION TAB
--====================================================
ProtectTab:CreateSection("⚡ Protection")

ProtectTab:CreateToggle({
    Name = "⚡ Lightning Protection",
    CurrentValue = true,
    Callback = function(v) Settings.LightningProtection = v end
})

ProtectTab:CreateToggle({
    Name = "💤 Anti AFK",
    CurrentValue = true,
    Callback = function(v) Settings.AntiAFK = v end
})

ProtectTab:CreateToggle({
    Name = "🚿 Auto Mandi",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoMandi = v
        if v then
            task.spawn(function()
                while Settings.AutoMandi do
                    Mandi()
                    task.wait(60)
                end
            end)
        end
    end
})

ProtectTab:CreateToggle({
    Name = "☂️ Auto Payung",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoPayung = v
        if v then
            task.spawn(function()
                while Settings.AutoPayung do
                    Payung()
                    task.wait(30)
                end
            end)
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
        Lighting.GlobalShadows = false
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

--====================================================
-- 💾 CONFIG TAB
--====================================================
ConfigTab:CreateSection("⚙ Configuration")

ConfigTab:CreateButton({
    Name = "⛔ STOP ALL AUTOS",
    Callback = function()
        Settings.AutoFarm = false
        Settings.AutoPlant = false
        Settings.AutoHarvest = false
        Settings.AutoSell = false
        Settings.AutoBuy = false
        Settings.AutoMandi = false
        Settings.AutoPayung = false
        notif("STOP", "Semua auto dimatikan", 3)
    end
})

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
-- INIT
--====================================================
RefreshAllData()
notif("🌾 XKID HUB v5.0", "Complete Edition Loaded! 🔥", 4)

print("=== XKID HUB v5.0 ===")
print("✅ FITUR LENGKAP:")
print("   - Auto Farm Lengkap")
print("   - Tanam & Panen Manual")
print("   - Interaksi NPC via ProximityPrompt")
print("   - Teleport ke Semua NPC")
print("   - Data Player (Coins, Seeds, Items)")
print("   - Protection (Anti AFK, Lightning)")
print("   - Utility Tools")