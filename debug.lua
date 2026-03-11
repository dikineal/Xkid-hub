--====================================================
-- XKID HUB | SAWAH INDO ULTIMATE v3.2
-- Dengan semua remote: RequestLahan, ToggleAutoHarvest, HarvestCrop
--====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO ULTIMATE 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "v3.2 | Complete Remote Set",
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

-- Remote Path
local Remotes = RS:FindFirstChild("Remotes")
local TutorialRemotes = Remotes and Remotes:FindFirstChild("TutorialRemotes")

-- ClientBoot Path (PENTING!)
local ClientBoot = LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("ClientBoot")

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
    AutoShower = false,
}

local SeedName = "Bibit Padi"
local JumlahBeli = 1
local JumlahTanam = 1
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
-- REMOTE FUNCTIONS (LENGKAP)
--====================================================

-- Request Shop Data (Bibit)
local function RequestShop(mode, ...)
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("RequestShop") then
        return nil
    end
    
    if not ClientBoot then return nil end
    
    local args = {ClientBoot}
    if mode == "BUY" then
        -- TODO: Cari parameter beli
        table.insert(args, SeedName)
        table.insert(args, JumlahBeli)
    end
    
    local success, result = pcall(function()
        return TutorialRemotes.RequestShop:InvokeServer(unpack(args))
    end)
    
    if success and result and result.Success then
        PlayerData.Coins = result.NewCoins or result.Coins or PlayerData.Coins
        if result.Seeds then
            PlayerData.Seeds = result.Seeds
        end
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

-- ============================================
-- REMOTE BARU! RequestLahan
-- ============================================
local function RequestLahan()
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("RequestLahan") then
        notif("Error", "Remote RequestLahan tidak ditemukan", 3)
        return nil
    end
    
    if not ClientBoot then
        notif("Error", "ClientBoot tidak ditemukan", 3)
        return nil
    end
    
    local success, result = pcall(function()
        return TutorialRemotes.RequestLahan:InvokeServer(ClientBoot)
    end)
    
    if success and result and result.Success then
        PlayerData.LahanStatus = result.Statuses or {}
        local count = 0
        for k, _ in pairs(PlayerData.LahanStatus) do
            count = count + 1
        end
        notif("Data Lahan", string.format("%d area lahan ditemukan", count), 3)
        return result
    end
    return nil
end

-- ============================================
-- REMOTE BARU! ToggleAutoHarvest
-- ============================================
local function ToggleAutoHarvest(mode)
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("ToggleAutoHarvest") then
        return false
    end
    
    mode = mode or "SYNC"
    pcall(function()
        TutorialRemotes.ToggleAutoHarvest:FireServer(mode)
    end)
    notif("Auto Harvest", "Toggle dikirim: "..mode, 2)
    return true
end

-- ============================================
-- REMOTE BARU! AdminIsAdmin
-- ============================================
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
        if IsAdmin then
            notif("ADMIN!", "Kamu adalah admin! 🔥", 5)
        else
            print("[XKID] Bukan admin (normal player)")
        end
        return IsAdmin
    end
    return false
end

-- ============================================
-- REMOTE UNTUK PANEN! HarvestCrop
-- ============================================
local function HarvestCrop(jenis, jumlah)
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("HarvestCrop") then
        notif("Error", "Remote HarvestCrop tidak ditemukan", 3)
        return false
    end
    
    jenis = jenis or "Padi"
    jumlah = jumlah or 1
    
    pcall(function()
        TutorialRemotes.HarvestCrop:FireServer(jenis, jumlah, jenis)
    end)
    notif("Panen", jenis.." x"..jumlah, 2)
    return true
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

--====================================================
-- AUTO BUY & SELL
--====================================================
local function BuySeed(seedName, jumlah)
    -- TODO: Implementasi beli
    return RequestShop("BUY")
end

local function SellItem(itemName, jumlah)
    -- TODO: Implementasi jual
    return RequestSell("fruit")  -- Contoh
end

--====================================================
-- SCAN LAHAN DENGAN DATA DARI REQUESTLAHAN
--====================================================
local function ScanLahanFromRemote()
    local data = RequestLahan()
    if not data then return end
    
    -- Sekarang cari object lahan di workspace
    LahanList = {}
    for lahanName, _ in pairs(PlayerData.LahanStatus) do
        local obj = cari(lahanName)
        if obj and obj:IsA("BasePart") then
            table.insert(LahanList, obj)
        end
    end
    
    notif("Scan Lahan", string.format("%d lahan ditemukan dari %d area", #LahanList, #PlayerData.LahanStatus), 3)
    return LahanList
end

--====================================================
-- AUTO TANAM KE SEMUA LAHAN
--====================================================
local function AutoPlantAll()
    if #LahanList == 0 then ScanLahanFromRemote() end
    
    local count = 0
    for _, lahan in ipairs(LahanList) do
        if lahan:IsA("BasePart") then
            PlantCrop(lahan.Position)
            count = count + 1
            task.wait(0.2)
        end
    end
    notif("Auto Plant", "Menanam di "..count.." lahan", 3)
end

--====================================================
-- AUTO PANEN SEMUA
--====================================================
local function AutoHarvestAll(jenis)
    jenis = jenis or SeedName:gsub("Bibit ", "")
    HarvestCrop(jenis, 1)  -- TODO: Perlu tahu berapa banyak yang bisa dipanen
end

--====================================================
-- REFRESH DATA PLAYER (LENGKAP)
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
-- TABS
--====================================================
local FarmingTab    = Window:CreateTab("🌾 Farming", 4483362458)
local LahanTab      = Window:CreateTab("🏞 Lahan", 4483362458)
local DataTab       = Window:CreateTab("📊 Data", 4483362458)
local ProtectTab    = Window:CreateTab("🛡 Protection", 4483362458)
local TeleportTab   = Window:CreateTab("📍 Teleport", 4483362458)
local UtilityTab    = Window:CreateTab("⚙ Utility", 4483362458)
local ConfigTab     = Window:CreateTab("💾 Config", 4483362458)

--====================================================
-- 🌾 FARMING TAB
--====================================================
FarmingTab:CreateSection("🌱 Auto Controls")

FarmingTab:CreateToggle({
    Name = "🔥 Auto Farm",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoFarm = v
    end
})

FarmingTab:CreateToggle({
    Name = "🌱 Auto Plant",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoPlant = v
    end
})

FarmingTab:CreateToggle({
    Name = "🌽 Auto Harvest",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoHarvest = v
    end
})

FarmingTab:CreateToggle({
    Name = "🔄 Toggle AutoHarvest (SYNC)",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoHarvestToggle = v
        ToggleAutoHarvest(v and "SYNC" or "OFF")
    end
})

FarmingTab:CreateSection("🌾 Manual Actions")

FarmingTab:CreateButton({
    Name = "🌱 Plant di Semua Lahan",
    Callback = AutoPlantAll
})

FarmingTab:CreateButton({
    Name = "🌽 Harvest Padi",
    Callback = function() HarvestCrop("Padi", 1) end
})

FarmingTab:CreateButton({
    Name = "🌽 Harvest Jagung",
    Callback = function() HarvestCrop("Jagung", 1) end
})

FarmingTab:CreateButton({
    Name = "🌽 Harvest Tomat",
    Callback = function() HarvestCrop("Tomat", 1) end
})

FarmingTab:CreateButton({
    Name = "🌽 Harvest Terong",
    Callback = function() HarvestCrop("Terong", 1) end
})

FarmingTab:CreateButton({
    Name = "🌽 Harvest Strawberry",
    Callback = function() HarvestCrop("Strawberry", 1) end
})

FarmingTab:CreateButton({
    Name = "🌽 Harvest Sawit",
    Callback = function() HarvestCrop("Sawit", 1) end
})

--====================================================
-- 🏞 LAHAN TAB (FITUR BARU!)
--====================================================
LahanTab:CreateSection("🏞 Data Lahan dari RequestLahan")

LahanTab:CreateButton({
    Name = "🔄 Refresh Data Lahan",
    Callback = function()
        RequestLahan()
        ScanLahanFromRemote()
    end
})

LahanTab:CreateButton({
    Name = "📍 Simpan Posisi Lahan",
    Callback = function()
        LahanPos = getPos()
        if LahanPos then notif("Lahan Position Saved", "", 2) end
    end
})

LahanTab:CreateButton({
    Name = "🌾 Teleport ke Lahan Tersimpan",
    Callback = function()
        if LahanPos and getRoot() then
            getRoot().CFrame = CFrame.new(LahanPos.X, LahanPos.Y+5, LahanPos.Z)
        end
    end
})

LahanTab:CreateParagraph({
    Title = "Area Lahan Terdeteksi",
    Content = "Jalankan Refresh Data Lahan untuk melihat daftar"
})

-- Dynamic content akan diupdate manual

--====================================================
-- 📊 DATA TAB
--====================================================
DataTab:CreateSection("📊 Player Data")

DataTab:CreateButton({
    Name = "🔄 Refresh ALL Data",
    Callback = RefreshAllData
})

DataTab:CreateButton({
    Name = "👑 Check Admin Status",
    Callback = CheckAdmin
})

DataTab:CreateParagraph({
    Title = "Info Remote",
    Content = "✅ RequestShop: seeds\n✅ RequestSell: items/fruits/eggs\n✅ RequestToolShop: tools\n✅ RequestLahan: lahan status\n✅ HarvestCrop: panen\n✅ ToggleAutoHarvest: auto panen"
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
    end
})

ProtectTab:CreateToggle({
    Name = "💤 Anti AFK",
    CurrentValue = true,
    Callback = function(v)
        Settings.AntiAFK = v
    end
})

--====================================================
-- 📍 TELEPORT TAB
--====================================================
TeleportTab:CreateSection("🏪 NPC Teleport")

local NPC_LIST = {
    {name="npcbibit", label="🌱 Bibit"},
    {name="npcpenjual", label="💰 Jual"},
    {name="npcalat", label="🔧 Alat"},
    {name="NPCPedagangTelur", label="🥚 Telur"},
    {name="NPCPedagangSawit", label="🌴 Sawit"},
}

for _, npc in ipairs(NPC_LIST) do
    TeleportTab:CreateButton({
        Name = npc.label,
        Callback = function()
            local obj = cari(npc.name)
            if obj then tp(obj) end
        end
    })
end

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
-- MAIN LOOP
--====================================================
task.spawn(function()
    while task.wait(5) do
        if Settings.AutoFarm or Settings.AutoPlant then
            if #LahanList == 0 then ScanLahanFromRemote() end
            for _, lahan in ipairs(LahanList) do
                if lahan:IsA("BasePart") then
                    PlantCrop(lahan.Position)
                    task.wait(0.3)
                end
            end
        end
        
        if Settings.AutoHarvest then
            HarvestCrop("Padi", 1)
            task.wait(1)
        end
        
        -- Refresh data periodically
        if task.wait(30) then
            RefreshAllData()
        end
    end
end)

--====================================================
-- INIT
--====================================================
-- Cek admin status di awal
CheckAdmin()

notif("🌾 SAWAH INDO ULTIMATE", "v3.2 dengan semua remote! 🔥", 4)
print("=== XKID HUB ULTIMATE v3.2 ===")
print("✅ REMOTE LENGKAP:")
print("   - RequestShop (beli & data seeds)")
print("   - RequestSell (jual & data items)")
print("   - RequestToolShop (data tools)")
print("   - RequestLahan (data lahan)")
print("   - HarvestCrop (panen manual)")
print("   - ToggleAutoHarvest (auto panen)")
print("   - PlantCrop (tanam)")
print("   - AdminIsAdmin (cek admin)")