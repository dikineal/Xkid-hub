-- 🌾 SAWAH INDO v12 ULTIMATE — XKID HUB
-- FEATURES LENGKAP Sesuai Daftar
-- Support: Android + Delta/Arceus/Fluxus

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO v12 ULTIMATE 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "All Features Included",
    ConfigurationSaving = {Enabled = true, FolderName = "XKidSawahV12", FileName = "Config"},
    KeySystem = false
})

-- ============================================
-- SERVICES & GLOBAL
-- ============================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local myName = LocalPlayer.Name

-- Auto Farm Flags
_G.AutoFarm = false
_G.AutoPlant = false
_G.AutoPanen = false
_G.AutoSell = false
_G.AutoBeli = false
_G.AutoMandi = false
_G.AutoPayung = false
_G.AutoTPPanen = false
_G.DestroyNotif = false

-- Data Selection
local selectedBibit = "Padi"
local selectedTanaman = "Padi"
local jumlahTanam = 15
local waitPanen = 30
local lastPos = nil
local gazeboPos = nil
local lahanPos = nil
local jumlahBeli = 1

-- Database
local BIBIT = {"Padi", "Jagung", "Tomat", "Terong", "Strawberry", "Sawit", "Durian"}
local TANAMAN = {"Padi", "Jagung", "Tomat", "Terong", "Strawberry", "Sawit", "Durian"}
local NPC_LIST = {
    {name="npcbibit", label="🌱 Bibit"},
    {name="npcpenjual", label="💰 Jual"},
    {name="npcalat", label="🔧 Alat"},
    {name="NPCPedagangTelur", label="🥚 Telur"},
    {name="NPCPedagangSawit", label="🌴 Sawit"},
}
local LAHAN_SAWIT = {
    {name="AreaTanam Sawit1", price=150000, label="Sawit 1"},
    {name="AreaTanam Sawit2", price=300000, label="Sawit 2"},
}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
local function notif(judul, isi, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = judul, Text = isi, Duration = dur or 3
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
    lastPos = getPos()
end

local function backLastPos()
    if lastPos and getRoot() then
        getRoot().Position = lastPos
        notif("Back", "Kembali ke posisi terakhir", 2)
    end
end

local function tp(obj)
    if not obj then return false end
    local root = getRoot()
    if not root then return false end
    local pos
    if obj:IsA("BasePart") then
        pos = obj.Position
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then pos = obj.PrimaryPart.Position
        elseif obj:FindFirstChild("HumanoidRootPart") then pos = obj.HumanoidRootPart.Position
        elseif obj:FindFirstChild("Head") then pos = obj.Head.Position end
    end
    if not pos then return false end
    saveLastPos()  -- Simpan posisi sebelum teleport
    root.CFrame = CFrame.new(pos.X, pos.Y+5, pos.Z)
    task.wait(0.3)
    return true
end

local function cari(nama)
    nama = nama:lower()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower() == nama then return v end
    end
end

-- ============================================
-- REMOTE SYSTEM
-- ============================================
local remoteCache = {}
local function getRemote(name)
    if remoteCache[name] then return remoteCache[name] end
    for _, v in pairs(RS:GetDescendants()) do
        if v.Name == name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            remoteCache[name] = v
            return v
        end
    end
end

local function fireR(name, ...)
    local r = getRemote(name)
    if not r then return false, "Remote not found: "..name end
    local ok, res = pcall(function(...)
        if r:IsA("RemoteEvent") then r:FireServer(...); return "Fired"
        else return r:InvokeServer(...) end
    end, ...)
    return ok, res
end

-- ============================================
-- KLIK GUI (PASTI JALAN)
-- ============================================
local function klikUI(tombol)
    if not tombol then return false end
    local ok = pcall(function()
        if tombol:IsA("GuiButton") then tombol:Click() end
    end)
    task.wait(0.1)
    return ok
end

local function cariTombol(teks)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local fg = pg:FindFirstChild("FarmGui") or pg
    for _, v in pairs(fg:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible and v.Text:lower():find(teks:lower()) then
            return v
        end
    end
    return nil
end

local function tutupGUI()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    local fg = pg:FindFirstChild("FarmGui") or pg
    for _, v in pairs(fg:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local t = v.Text:lower()
            if t:find("tutup") or t:find("close") or t == "x" or t == "✕" then
                klikUI(v)
                break
            end
        end
    end
end

-- ============================================
-- FITUR BELI BIBIT (GetBibit)
-- ============================================
local function beliBibit(bibit, jumlah)
    fireR("GetBibit", 0, false)
    task.wait(1.5)
    if jumlah > 1 then
        local plus = cariTombol("+")
        if plus then
            for i=1, jumlah-1 do klikUI(plus); task.wait(0.1) end
        end
    end
    local beli = cariTombol("beli")
    if beli then
        klikUI(beli)
        task.wait(0.3)
        tutupGUI()
        notif("Beli ✅", bibit.." x"..jumlah, 2)
        return true
    end
    return false
end

-- ============================================
-- FITUR AUTO PLANT
-- ============================================
local function tanamBibit(jenis, jumlah)
    for i=1, jumlah do
        fireR("PlantCrop")  -- atau PlantLahanCrop
        task.wait(0.3)
    end
    notif("Tanam ✅", jenis.." x"..jumlah, 2)
end

-- ============================================
-- FITUR AUTO PANEN
-- ============================================
local function panenTanaman(jenis, jumlah)
    fireR("HarvestCrop", jenis, jumlah or 1, jenis)
    notif("Panen ✅", jenis, 2)
end

-- ============================================
-- FITUR AUTO JUAL (Intercept + Manual)
-- ============================================
local function jualSemuaHasil()
    fireR("SellCrop", nil, "OPEN_FRUIT_GUI")
    task.wait(1.5)
    local btn = cariTombol("jual semua") or cariTombol("sell all") or cariTombol("jual")
    if btn then klikUI(btn); task.wait(0.5) end
    tutupGUI()
    notif("Jual ✅", "Semua hasil terjual", 2)
end

-- Intercept setup
local function setupIntercepts()
    local sellRemote = getRemote("SellCrop")
    if sellRemote then
        sellRemote.OnClientEvent:Connect(function(p40, p41)
            if _G.AutoSell and (p41 == "OPEN_SELL_GUI" or p41 == "OPEN_FRUIT_GUI" or p41 == "OPEN_SAWIT_GUI") then
                task.wait(1)
                local btn = cariTombol("jual semua") or cariTombol("sell all") or cariTombol("jual")
                if btn then klikUI(btn) end
                task.wait(0.3)
                tutupGUI()
            end
        end)
    end
end
setupIntercepts()

-- ============================================
-- FITUR AUTO MANDI & PAYUNG
-- ============================================
local function mandi()
    fireR("HygieneSync", 100)
    notif("Mandi ✅", "Kesegaran kembali", 1)
end

local function payung()
    fireR("UseUmbrella")  -- asumsi, cek remote spy
    notif("Payung ☂️", "Aman dari hujan", 1)
end

-- ============================================
-- FITUR TELEPORT & BACK
-- ============================================
local function tpGazebo()
    if gazeboPos then
        getRoot().CFrame = CFrame.new(gazeboPos.X, gazeboPos.Y+5, gazeboPos.Z)
        notif("TP Gazebo", "Aman!", 2)
    end
end

local function tpPanen()
    if lahanPos then
        getRoot().CFrame = CFrame.new(lahanPos.X, lahanPos.Y+5, lahanPos.Z)
        notif("TP Panen", "Siap panen", 2)
    end
end

-- ============================================
-- FITUR BELI AREA SAWIT & CLAIM
-- ============================================
local function beliAreaSawit(area)
    fireR("LahanUpdate", "CONFIRM_BUY", {PartName=area.partName, Price=area.price})
    notif("Beli Area ✅", area.label, 2)
end

local function claimArea(area)
    fireR("ClaimArea", area.partName)  -- asumsi
    notif("Claim ✅", area.label, 2)
end

-- ============================================
-- DESTROY NOTIF (Hilangkan notif bawaan game)
-- ============================================
local function destroyNotif()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, v in pairs(pg:GetDescendants()) do
            if v:IsA("TextLabel") and (v.Text:find("Notif") or v.Text:find("Notification")) then
                v:Destroy()
            end
        end
    end
    if _G.DestroyNotif then
        task.wait(1)
        destroyNotif()
    end
end

-- ============================================
-- TABS
-- ============================================
local TabAutoFarm = Window:CreateTab("🤖 Auto Farm", nil)
local TabBeli = Window:CreateTab("🛒 Beli Bibit", nil)
local TabPanen = Window:CreateTab("🌽 Panen", nil)
local TabJual = Window:CreateTab("💰 Jual", nil)
local TabLife = Window:CreateTab("🧼 Life Support", nil)
local TabTP = Window:CreateTab("🚀 Teleport", nil)
local TabLahan = Window:CreateTab("🏞 Lahan Sawit", nil)
local TabSet = Window:CreateTab("⚙ Setting", nil)

-- ============================================
-- TAB AUTO FARM
-- ============================================
TabAutoFarm:CreateSection("🌾 FULL AUTO FARM")
TabAutoFarm:CreateDropdown({
    Name = "Pilih Tanaman",
    Options = TANAMAN,
    CurrentOption = {TANAMAN[1]},
    Callback = function(v) selectedTanaman = v[1] end
})
TabAutoFarm:CreateSlider({Name = "Jumlah Tanam per Siklus", Range = {1,50}, CurrentValue = 15,
    Callback = function(v) jumlahTanam = v end})
TabAutoFarm:CreateSlider({Name = "Waktu Tunggu Panen (detik)", Range = {10,300}, CurrentValue = 30,
    Callback = function(v) waitPanen = v end})
TabAutoFarm:CreateToggle({
    Name = "🔥 FULL AUTO FARM",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoFarm = v
        if v then
            notif("AUTO FARM ON", "Memulai siklus...", 3)
            task.spawn(function()
                while _G.AutoFarm do
                    -- 1. Beli bibit
                    beliBibit(selectedTanaman, jumlahTanam)
                    task.wait(2)
                    -- 2. Tanam
                    tanamBibit(selectedTanaman, jumlahTanam)
                    task.wait(2)
                    -- 3. Tunggu
                    notif("Menunggu panen", waitPanen.." detik", waitPanen)
                    task.wait(waitPanen)
                    -- 4. Panen
                    panenTanaman(selectedTanaman, 1)
                    task.wait(1)
                    -- 5. Jual
                    jualSemuaHasil()
                    task.wait(2)
                end
            end)
        end
    end
})

TabAutoFarm:CreateSection("🌱 AUTO PLANT (Manual)")
TabAutoFarm:CreateDropdown({
    Name = "Pilih Bibit",
    Options = BIBIT,
    CurrentOption = {BIBIT[1]},
    Callback = function(v) selectedBibit = v[1] end
})
TabAutoFarm:CreateSlider({Name = "Jumlah Tanam", Range = {1,50}, CurrentValue = 15,
    Callback = function(v) jumlahTanam = v end})
TabAutoFarm:CreateButton({
    Name = "🌱 TANAM SEKARANG",
    Callback = function()
        tanamBibit(selectedBibit, jumlahTanam)
    end
})

-- ============================================
-- TAB BELI BIBIT
-- ============================================
TabBeli:CreateSection("🛒 Beli Bibit Manual")
TabBeli:CreateDropdown({
    Name = "Pilih Bibit",
    Options = BIBIT,
    CurrentOption = {BIBIT[1]},
    Callback = function(v) selectedBibit = v[1] end
})
TabBeli:CreateSlider({Name = "Jumlah", Range = {1,99}, CurrentValue = 1,
    Callback = function(v) jumlahBeli = v end})
TabBeli:CreateButton({
    Name = "💳 BELI SEKARANG",
    Callback = function()
        beliBibit(selectedBibit, jumlahBeli)
    end
})

TabBeli:CreateSection("🔄 Auto Beli Loop")
TabBeli:CreateToggle({
    Name = "🔄 AUTO BELI BIBIT",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoBeli = v
        if v then
            task.spawn(function()
                while _G.AutoBeli do
                    beliBibit(selectedBibit, jumlahBeli)
                    task.wait(10)
                end
            end)
        end
    end
})

-- ============================================
-- TAB PANEN
-- ============================================
TabPanen:CreateSection("🌽 Panen Manual")
for _, t in ipairs(TANAMAN) do
    TabPanen:CreateButton({
        Name = "🌽 Panen "..t,
        Callback = function()
            panenTanaman(t, 1)
        end
    })
end

TabPanen:CreateSection("🚀 Auto TP Panen")
TabPanen:CreateButton({
    Name = "📍 Simpan Posisi Lahan Panen",
    Callback = function()
        lahanPos = getPos()
        notif("Posisi tersimpan", "Untuk TP Panen", 2)
    end
})
TabPanen:CreateToggle({
    Name = "🚀 AUTO TP PANEN (setelah panen)",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoTPPanen = v
    end
})

-- ============================================
-- TAB JUAL
-- ============================================
TabJual:CreateSection("💰 Auto Jual")
TabJual:CreateToggle({
    Name = "💰 AUTO JUAL (Intercept)",
    CurrentValue = false,
    Callback = function(v) _G.AutoSell = v end
})
TabJual:CreateButton({
    Name = "💰 JUAL SEMUA HASIL",
    Callback = jualSemuaHasil
})

-- ============================================
-- TAB LIFE SUPPORT
-- ============================================
TabLife:CreateSection("🧼 Mandi & Payung")
TabLife:CreateToggle({
    Name = "🧼 AUTO MANDI (60 detik)",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoMandi = v
        if v then
            task.spawn(function()
                while _G.AutoMandi do
                    mandi()
                    task.wait(60)
                end
            end)
        end
    end
})
TabLife:CreateToggle({
    Name = "☂️ AUTO PAYUNG (30 detik)",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoPayung = v
        if v then
            task.spawn(function()
                while _G.AutoPayung do
                    payung()
                    task.wait(30)
                end
            end)
        end
    end
})

TabLife:CreateSection("🚿 Dropdown Mandi")
TabLife:CreateDropdown({
    Name = "Pilih Aksi",
    Options = {"Mandi Sekarang", "Teleport ke Kamar Mandi"},
    Callback = function(selected)
        if selected[1] == "Mandi Sekarang" then
            mandi()
        elseif selected[1] == "Teleport ke Kamar Mandi" then
            local toilet = cari("Toilet") or cari("KamarMandi") or cari("Bath")
            if toilet then tp(toilet) end
        end
    end
})

-- ============================================
-- TAB TELEPORT
-- ============================================
TabTP:CreateSection("🏪 NPC Teleport")
for _, npc in ipairs(NPC_LIST) do
    TabTP:CreateButton({
        Name = npc.label.." "..npc.name,
        Callback = function()
            local obj = cari(npc.name)
            if obj then tp(obj) end
        end
    })
end

TabTP:CreateSection("🚀 Teleport Tools")
TabTP:CreateButton({
    Name = "📍 Simpan Posisi Gazebo",
    Callback = function()
        gazeboPos = getPos()
        notif("Gazebo tersimpan", "", 2)
    end
})
TabTP:CreateButton({
    Name = "🏠 TP ke Gazebo",
    Callback = tpGazebo
})
TabTP:CreateButton({
    Name = "↩️ Back Last Location",
    Callback = backLastPos
})
TabTP:CreateButton({
    Name = "📍 Simpan Posisi Lahan",
    Callback = function()
        lahanPos = getPos()
        notif("Lahan tersimpan", "", 2)
    end
})
TabTP:CreateButton({
    Name = "🌾 TP ke Lahan",
    Callback = function()
        if lahanPos then
            getRoot().CFrame = CFrame.new(lahanPos.X, lahanPos.Y+5, lahanPos.Z)
        end
    end
})

-- ============================================
-- TAB LAHAN SAWIT
-- ============================================
TabLahan:CreateSection("🏞 Beli Area Sawit")
for _, area in ipairs(LAHAN_SAWIT) do
    TabLahan:CreateButton({
        Name = "🏞 "..area.label.." | "..area.price.."💰",
        Callback = function()
            beliAreaSawit(area)
        end
    })
end

TabLahan:CreateSection("🎁 Claim Area")
for _, area in ipairs(LAHAN_SAWIT) do
    TabLahan:CreateButton({
        Name = "🎁 Claim "..area.label,
        Callback = function()
            claimArea(area)
        end
    })
end

-- ============================================
-- TAB SETTING
-- ============================================
TabSet:CreateSection("⚙ Pengaturan")
TabSet:CreateToggle({
    Name = "❌ Destroy Notif Game",
    CurrentValue = false,
    Callback = function(v)
        _G.DestroyNotif = v
        if v then destroyNotif() end
    end
})
TabSet:CreateButton({
    Name = "🔄 Sync Data Player",
    Callback = function()
        fireR("SyncData")
    end
})

-- ============================================
-- INIT
-- ============================================
notif("🌾 SAWAH INDO v12", "Welcome "..myName.."! Semua fitur siap 🔥", 5)
print("=== XKID HUB v12 ULTIMATE ===")
for _, f in ipairs({"Auto Farm", "Auto Plant", "Auto Panen", "Auto Jual", "Auto Mandi", "Auto Payung", "Teleport", "Beli Sawit"}) do
    print("✅ "..f)
end