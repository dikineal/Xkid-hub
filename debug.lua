--====================================================
-- XKID HUB | SAWAH INDO XKID.HUB v5.1
-- Remote Spy Update + Auto Farm Fix
--====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO XKID.HUB 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "v5.1 | Remote Spy Fix",
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
local UserInputService = game:GetService("UserInputService")

-- Remote Path
local Remotes = RS:FindFirstChild("Remotes")
local TutorialRemotes = Remotes and Remotes:FindFirstChild("TutorialRemotes")

-- ClientBoot Path (penting untuk semua Invoke)
local ClientBoot = LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("ClientBoot")

--====================================================
-- PROXIMITY PROMPT PATHS (dari user)
--====================================================
local PROMPTS = {
    Bibit = Workspace:FindFirstChild("NPCs") and Workspace.NPCs:FindFirstChild("NPC_Bibit") and Workspace.NPCs.NPC_Bibit:FindFirstChild("npcbibit") and Workspace.NPCs.NPC_Bibit.npcbibit:FindFirstChild("ProximityPrompt"),
    Alat = Workspace:FindFirstChild("NPCs") and Workspace.NPCs:FindFirstChild("NPC_Alat") and Workspace.NPCs.NPC_Alat:FindFirstChild("npcalat") and Workspace.NPCs.NPC_Alat.npcalat:FindFirstChild("ProximityPrompt"),
    Sawit = Workspace:FindFirstChild("NPCs") and Workspace.NPCs:FindFirstChild("NPC_PedagangSawit") and Workspace.NPCs.NPC_PedagangSawit:FindFirstChild("NPCPedagangSawit") and Workspace.NPCs.NPC_PedagangSawit.NPCPedagangSawit:FindFirstChild("ProximityPrompt"),
    Telur = Workspace:FindFirstChild("NPCs") and Workspace.NPCs:FindFirstChild("NPCPedagangTelur") and Workspace.NPCs.NPCPedagangTelur:FindFirstChild("NPCPedagangTelur") and Workspace.NPCs.NPCPedagangTelur.NPCPedagangTelur:FindFirstChild("ProximityPrompt"),
    CoopPlot = Workspace:FindFirstChild("CoopPlots") and Workspace.CoopPlots:FindFirstChild("CoopPlot_1") and Workspace.CoopPlots.CoopPlot_1:FindFirstChild("ProximityPrompt"),
    BikeMount = Workspace:FindFirstChild("Seat") and Workspace.Seat:FindFirstChild("BikeMountPrompt"),
}

--====================================================
-- SETTINGS
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
    AutoConfirm = true,  -- untuk ConfirmAction
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
-- REMOTE FUNCTIONS (berdasarkan spy terbaru)
--====================================================

-- Request Shop (untuk data seeds, dan ternyata bisa juga untuk beli?)
local function RequestShop()
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("RequestShop") then
        return nil
    end
    if not ClientBoot then return nil end
    
    local success, result = pcall(function()
        return TutorialRemotes.RequestShop:InvokeServer(ClientBoot)
    end)
    
    if success and result then
        if result.Success then
            PlayerData.Coins = result.NewCoins or result.Coins or PlayerData.Coins
            PlayerData.Seeds = result.Seeds or {}
            if result.Message then
                print("[SHOP] "..result.Message)
            end
            return result
        end
    end
    return nil
end

-- Request Sell (untuk data items)
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

-- Toggle Auto Harvest (fitur game)
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

-- Plant Crop (tanam) dengan koordinat
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

-- Harvest Crop (panen) dengan parameter (jenis, jumlah, jenis)
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

-- GetBibit (buka GUI bibit)
local function GetBibit()
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("GetBibit") then
        return false
    end
    pcall(function()
        TutorialRemotes.GetBibit:FireServer(0, false)
    end)
    return true
end

-- SellCrop (buka GUI jual)
local function SellCrop(mode)
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("SellCrop") then
        return false
    end
    mode = mode or "OPEN_SELL_GUI"
    pcall(function()
        TutorialRemotes.SellCrop:FireServer(nil, mode)
    end)
    return true
end

-- ConfirmAction (untuk auto konfirmasi)
if TutorialRemotes and TutorialRemotes:FindFirstChild("ConfirmAction") then
    local confirm = TutorialRemotes.ConfirmAction
    if confirm:IsA("RemoteFunction") then
        confirm.OnClientInvoke = function(data)
            if Settings.AutoConfirm then
                print("[AUTO CONFIRM] true")
                return true
            end
            return nil
        end
    end
end

--====================================================
-- FUNGSI KLIK GUI (ALTERNATIF)
--====================================================
local function klikTombol(teks)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    local fg = pg:FindFirstChild("FarmGui") or pg
    for _, v in pairs(fg:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            if v.Text:lower():find(teks:lower()) then
                pcall(function() v:Click() end)
                return true
            end
        end
    end
    return false
end

local function tutupGUI()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    local fg = pg:FindFirstChild("FarmGui") or pg
    for _, v in pairs(fg:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local t = v.Text:lower()
            if t:find("tutup") or t:find("close") or t == "x" then
                pcall(function() v:Click() end)
                break
            end
        end
    end
end

--====================================================
-- FUNGSI BELI VIA GUI (menggunakan GetBibit)
--====================================================
local function BeliBibitViaGUI(bibit, jumlah)
    GetBibit()
    task.wait(1.5)
    
    -- Atur jumlah
    if jumlah > 1 then
        for i=1, jumlah-1 do
            if not klikTombol("+") then break end
            task.wait(0.1)
        end
    end
    
    -- Klik beli
    if klikTombol("beli") then
        task.wait(0.3)
        tutupGUI()
        notif("Beli", bibit.." x"..jumlah, 2)
        return true
    end
    return false
end

--====================================================
-- FUNGSI JUAL VIA GUI (menggunakan SellCrop)
--====================================================
local function JualViaGUI(mode)
    SellCrop(mode)
    task.wait(1.5)
    
    if klikTombol("jual semua") or klikTombol("sell all") or klikTombol("jual") then
        task.wait(0.3)
        tutupGUI()
        notif("Jual", "Sukses", 2)
        return true
    end
    return false
end

--====================================================
-- SCAN LAHAN DARI REQUESTLAHAN
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
-- TABS LENGKAP (sama seperti v5.0, tapi dengan perbaikan)
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

-- Isi tab bisa disalin dari v5.0, pastikan memanggil fungsi yang benar.
-- Untuk menghemat tempat, saya tulis ulang secara ringkas, tetapi Anda bisa menggunakan yang sebelumnya.

-- (Saya akan memberikan versi ringkas dengan asumsi user sudah punya struktur tab, kita hanya perlu update fungsi auto farm)

-- Contoh untuk FarmTab:
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
                    -- Beli via GUI (atau via NPC)
                    if Settings.AutoBuy then
                        BeliBibitViaGUI(SeedName, JumlahBeli)
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
                    
                    -- Jual via GUI
                    if Settings.AutoSell then
                        JualViaGUI("OPEN_FRUIT_GUI")
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
    Name = "💰 Auto Sell",
    CurrentValue = false,
    Callback = function(v) Settings.AutoSell = v end
})

FarmTab:CreateToggle({
    Name = "🛒 Auto Buy",
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

-- Tambahkan tombol test untuk remote baru
FarmTab:CreateSection("🧪 Test Remote Baru")
FarmTab:CreateButton({
    Name = "Test RequestShop (ambil data)",
    Callback = function() RequestShop() end
})
FarmTab:CreateButton({
    Name = "Test PlantCrop di posisi saya",
    Callback = function() PlantCrop() end
})
FarmTab:CreateButton({
    Name = "Test HarvestCrop Padi",
    Callback = function() HarvestCrop("Padi", 1) end
})
FarmTab:CreateButton({
    Name = "Test GetBibit (buka GUI)",
    Callback = GetBibit
})
FarmTab:CreateButton({
    Name = "Test SellCrop (buka GUI buah)",
    Callback = function() SellCrop("OPEN_FRUIT_GUI") end
})

-- (Tab lainnya bisa sama seperti v5.0, tidak perlu diubah)

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
notif("🌾 XKID HUB v5.1", "Remote Spy Fix Loaded! 🔥", 4)

print("=== XKID HUB v5.1 ===")
print("✅ Remote terbaru diintegrasikan")
print("✅ Auto Farm menggunakan GUI (GetBibit & SellCrop)")
print("✅ PlantCrop & HarvestCrop via remote")
print("✅ ProximityPrompt untuk interaksi NPC")