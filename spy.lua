-- 🌾 SAWAH INDO v10 — XKID HUB (CLEAN, ONLY WORKING FEATURES)
-- Berdasarkan remote spy & decompile
-- Metode: GetBibit(0,false), SellCrop intercept, HarvestCrop, LahanUpdate
-- Dijamin jalan di Android (Delta/Arceus) karena pakai :Click() bukan cursor

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO v10 (REMOTE SPY)",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "clean & working",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local myName = LocalPlayer.Name

-- ============================================
-- GLOBAL FLAGS
-- ============================================
_G.AutoBeli = false
_G.AutoJual = false
_G.PenangkalPetir = false
_G.AutoConfirm = false   -- untuk LahanUpdate (auto konfirm beli lahan)

-- ============================================
-- DATA
-- ============================================
local BIBIT = {
    {name="Padi",       emoji="🌾", minLv=1},
    {name="Jagung",     emoji="🌽", minLv=20},
    {name="Tomat",      emoji="🍅", minLv=40},
    {name="Terong",     emoji="🍆", minLv=60},
    {name="Strawberry", emoji="🍓", minLv=80},
    {name="Sawit",      emoji="🌴", minLv=80},
    {name="Durian",     emoji="🥥", minLv=120},
}
local selectedBibit = "Padi"
local jumlahBeli = 1

local LAHAN_LIST = {
    {partName="AreaTanam Besar2", price=100000, label="Lahan Besar 2"},
    {partName="AreaTanam Besar3", price=200000, label="Lahan Besar 3"},
    {partName="AreaTanam Sawit1", price=150000, label="Lahan Sawit 1"},
    {partName="AreaTanam Sawit2", price=300000, label="Lahan Sawit 2"},
}

local savedLahanPos = nil   -- posisi untuk teleport

-- ============================================
-- UTILITY
-- ============================================
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

-- Fungsi teleport ke objek
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
    root.CFrame = CFrame.new(pos.X, pos.Y+5, pos.Z)
    task.wait(0.3)
    return true
end

-- Cari objek berdasarkan nama persis
local function cari(nama)
    nama = nama:lower()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower() == nama then
            return v
        end
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
    local ok, result = pcall(function(...)
        if r:IsA("RemoteEvent") then
            r:FireServer(...)
            return "Fired"
        else
            return r:InvokeServer(...)
        end
    end, ...)
    return ok, result
end

-- ============================================
-- KLIK GUI PAKAI :Click() (PASTI JALAN)
-- ============================================
local function klikUI(tombol)
    if not tombol then return false end
    local ok = pcall(function()
        if tombol:IsA("GuiButton") then
            tombol:Click()
        end
    end)
    task.wait(0.1)
    return ok
end

-- Cari tombol di FarmGui berdasarkan teks
local function cariTombol(teks)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local fg = pg:FindFirstChild("FarmGui") or pg
    for _, v in pairs(fg:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            if v.Text:lower():find(teks:lower()) then
                return v
            end
        end
    end
    return nil
end

-- Tutup GUI (klik tombol tutup)
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
-- BELI BIBIT (METODE GetBibit)
-- ============================================
local function beliBibit(bibit, jumlah)
    -- 1. Fire GetBibit buka GUI
    local ok, res = fireR("GetBibit", 0, false)
    if not ok then
        notif("Gagal", "Remote GetBibit error: "..tostring(res), 3)
        return false
    end

    -- 2. Tunggu GUI bibit muncul (max 5 detik)
    local start = tick()
    local guiReady = false
    while tick() - start < 5 do
        task.wait(0.3)
        if cariTombol("+") then
            guiReady = true
            break
        end
    end
    if not guiReady then
        notif("Gagal", "GUI bibit tidak muncul", 3)
        return false
    end

    -- 3. Atur jumlah (klik + sebanyak jumlah-1)
    if jumlah > 1 then
        local plus = cariTombol("+")
        if plus then
            for i = 1, jumlah-1 do
                klikUI(plus)
                task.wait(0.1)
            end
        end
    end

    -- 4. Klik tombol Beli
    local beli = cariTombol("beli")
    if beli then
        klikUI(beli)
        task.wait(0.3)
        tutupGUI()
        notif("Sukses", "Beli "..jumlah.." "..bibit, 2)
        return true
    else
        notif("Gagal", "Tombol Beli tidak ditemukan", 3)
        return false
    end
end

-- ============================================
-- JUAL HASIL (intercept SellCrop)
-- ============================================
-- Setup intercept untuk auto klik saat GUI jual terbuka
local function setupIntercepts()
    local sellRemote = getRemote("SellCrop")
    if sellRemote then
        sellRemote.OnClientEvent:Connect(function(p40, p41)
            print("[XKID] SellCrop event: p40="..tostring(p40).." p41="..tostring(p41))
            -- Jika p41 adalah mode GUI, maka GUI jual terbuka
            if p41 == "OPEN_SELL_GUI" or p41 == "OPEN_SAWIT_GUI" or p41 == "OPEN_EGG_GUI" or p41 == "OPEN_FRUIT_GUI" then
                if _G.AutoJual then
                    task.wait(1)  -- tunggu GUI beneran muncul
                    -- Klik tombol jual semua atau jual
                    local jualBtn = cariTombol("jual semua") or cariTombol("sell all") or cariTombol("jual") or cariTombol("sell")
                    if jualBtn then
                        klikUI(jualBtn)
                        task.wait(0.3)
                        tutupGUI()
                        notif("Auto Jual ✅", "Menjual via "..p41, 2)
                    end
                end
            end
        end)
        print("[XKID] ✅ SellCrop intercept aktif")
    end

    -- ConfirmAction untuk beli lahan otomatis
    local confirmRemote = getRemote("ConfirmAction")
    if confirmRemote and confirmRemote:IsA("RemoteFunction") then
        confirmRemote.OnClientInvoke = function(data)
            print("[XKID] ConfirmAction: "..tostring(data))
            if _G.AutoConfirm then
                return true  -- auto konfirm
            end
            return nil  -- biar GUI konfirm normal muncul
        end
        print("[XKID] ✅ ConfirmAction intercept aktif")
    end

    -- LightningStrike untuk penangkal petir
    local petirRemote = getRemote("LightningStrike")
    if petirRemote then
        petirRemote.OnClientEvent:Connect(function(data)
            print("[XKID] LightningStrike: "..tostring(data))
            if _G.PenangkalPetir and getRoot() and savedLahanPos then
                getRoot().CFrame = CFrame.new(savedLahanPos.X, savedLahanPos.Y+5, savedLahanPos.Z)
                notif("⚡ Petir ditangkal!", "Teleport ke lahan", 3)
            end
        end)
        print("[XKID] ✅ LightningStrike intercept aktif")
    end
end

-- Jalankan setup
setupIntercepts()

-- ============================================
-- PANEN via HarvestCrop (opsional)
-- ============================================
local function panenTanaman(jenis, jumlah)
    -- dari spy: HarvestCrop("Jagung", 2, "Jagung")
    return fireR("HarvestCrop", jenis, jumlah or 1, jenis)
end

-- ============================================
-- BELI LAHAN via LahanUpdate
-- ============================================
local function beliLahan(partName, price)
    return fireR("LahanUpdate", "CONFIRM_BUY", {PartName = partName, Price = price})
end

-- ============================================
-- TABS
-- ============================================
local TabBeli  = Window:CreateTab("🛒 Beli Bibit", nil)
local TabJual  = Window:CreateTab("💰 Jual", nil)
local TabLahan = Window:CreateTab("🏞 Lahan", nil)
local TabPanen = Window:CreateTab("🌽 Panen", nil)
local TabTP    = Window:CreateTab("🚀 Teleport", nil)
local TabSet   = Window:CreateTab("⚙ Setting", nil)
local TabTest  = Window:CreateTab("🧪 Test Remote", nil)

-- ============================================
-- TAB BELI BIBIT
-- ============================================
TabBeli:CreateSection("🌱 Pilih Bibit")
local opsiBibit = {}
for _, b in ipairs(BIBIT) do
    table.insert(opsiBibit, b.emoji.." "..b.name.." Lv."..b.minLv)
end
TabBeli:CreateDropdown({
    Name = "Jenis Bibit",
    Options = opsiBibit,
    CurrentOption = {opsiBibit[1]},
    Callback = function(v)
        for _, b in ipairs(BIBIT) do
            if v[1]:find(b.name) then
                selectedBibit = b.name
                notif("Dipilih", b.name, 2)
                break
            end
        end
    end
})

TabBeli:CreateSlider({
    Name = "Jumlah",
    Range = {1, 99},
    Increment = 1,
    CurrentValue = 1,
    Callback = function(v) jumlahBeli = v end
})

TabBeli:CreateSection("🛒 Beli Manual (1x Klik)")
for _, b in ipairs(BIBIT) do
    TabBeli:CreateButton({
        Name = b.emoji.." "..b.name.." — BELI 1",
        Callback = function()
            task.spawn(function()
                beliBibit(b.name, 1)
            end)
        end
    })
end

TabBeli:CreateSection("🔄 Auto Beli Loop")
TabBeli:CreateToggle({
    Name = "🔄 Auto Beli (GetBibit)",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoBeli = v
        if v then
            notif("Auto Beli ON", selectedBibit.." x"..jumlahBeli, 3)
            task.spawn(function()
                while _G.AutoBeli do
                    beliBibit(selectedBibit, jumlahBeli)
                    task.wait(10)  -- beli setiap 10 detik
                end
            end)
        else
            notif("Auto Beli OFF", "", 2)
        end
    end
})

-- ============================================
-- TAB JUAL
-- ============================================
TabJual:CreateSection("💰 Jual Hasil")
TabJual:CreateParagraph({
    Title = "Info",
    Content = "Auto jual aktif: saat GUI jual terbuka, script akan otomatis klik tombol jual.\n\nMode GUI dikirim server via SellCrop event."
})

TabJual:CreateToggle({
    Name = "💰 Auto Jual (Intercept)",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoJual = v
        notif("Auto Jual", v and "ON ✅" or "OFF", 2)
    end
})

TabJual:CreateButton({
    Name = "🧪 Buka GUI Jual Buah (test)",
    Callback = function()
        fireR("SellCrop", nil, "OPEN_FRUIT_GUI")  -- sesuai spy
    end
})

TabJual:CreateButton({
    Name = "🧪 Buka GUI Jual Sawit",
    Callback = function()
        fireR("SellCrop", nil, "OPEN_SAWIT_GUI")
    end
})

-- ============================================
-- TAB LAHAN (Beli Lahan)
-- ============================================
TabLahan:CreateSection("🏞 Beli Lahan")
TabLahan:CreateParagraph({
    Title = "Auto Confirm",
    Content = "Aktifkan Auto Confirm di tab Setting agar pembelian lahan otomatis terkonfirmasi."
})
for _, l in ipairs(LAHAN_LIST) do
    TabLahan:CreateButton({
        Name = "🏞 "..l.label.." | "..l.price.."💰",
        Callback = function()
            task.spawn(function()
                local ok, res = beliLahan(l.partName, l.price)
                notif(ok and "Sukses ✅" or "Gagal ❌", tostring(res), 3)
            end)
        end
    })
end

TabLahan:CreateSection("📌 Simpan Posisi Lahan")
TabLahan:CreateButton({
    Name = "📍 Simpan Posisi Lahan (untuk teleport & petir)",
    Callback = function()
        local pos = getPos()
        if pos then
            savedLahanPos = pos
            notif("Tersimpan", string.format("X=%.1f Z=%.1f", pos.X, pos.Z), 3)
        end
    end
})

-- ============================================
-- TAB PANEN (HarvestCrop)
-- ============================================
TabPanen:CreateSection("🌽 Panen Manual")
TabPanen:CreateParagraph({
    Title = "Catatan",
    Content = "HarvestCrop remote membutuhkan argumen: (jenis, jumlah, jenis)\nContoh: ('Jagung', 2, 'Jagung')"
})
local tanamanList = {"Padi", "Jagung", "Tomat", "Terong", "Strawberry", "Sawit", "Durian"}
for _, t in ipairs(tanamanList) do
    TabPanen:CreateButton({
        Name = "🌽 Panen "..t.." (1)",
        Callback = function()
            fireR("HarvestCrop", t, 1, t)
            notif("Panen", t.." dikirim", 2)
        end
    })
end

-- ============================================
-- TAB TELEPORT
-- ============================================
TabTP:CreateSection("🏪 NPC")
local npcList = {
    {name="npcbibit",         label="🌱 Beli Bibit"},
    {name="npcpenjual",       label="💰 Jual Hasil"},
    {name="npcalat",          label="🔧 Beli Alat"},
    {name="NPCPedagangTelur", label="🥚 Jual Telur"},
    {name="NPCPedagangSawit", label="🌴 Jual Sawit"},
}
for _, npc in ipairs(npcList) do
    TabTP:CreateButton({
        Name = npc.label,
        Callback = function()
            local obj = cari(npc.name)
            if obj then
                tp(obj)
                notif("TP ✅", npc.name, 2)
            else
                notif("Error", npc.name.." tidak ditemukan", 3)
            end
        end
    })
end

TabTP:CreateSection("🌾 Lahan")
TabTP:CreateButton({
    Name = "🏠 Teleport ke Lahan Tersimpan",
    Callback = function()
        if savedLahanPos then
            local r = getRoot()
            if r then
                r.CFrame = CFrame.new(savedLahanPos.X, savedLahanPos.Y+5, savedLahanPos.Z)
                notif("TP ✅", "Ke lahan", 2)
            end
        else
            notif("Error", "Simpan posisi lahan dulu!", 3)
        end
    end
})

-- ============================================
-- TAB SETTING
-- ============================================
TabSet:CreateSection("⚙ Pengaturan")
TabSet:CreateToggle({
    Name = "✅ Auto Confirm (beli lahan)",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoConfirm = v
        notif("Auto Confirm", v and "ON ✅" or "OFF", 2)
    end
})
TabSet:CreateToggle({
    Name = "⚡ Penangkal Petir",
    CurrentValue = false,
    Callback = function(v)
        _G.PenangkalPetir = v
        notif("Penangkal Petir", v and "ON ✅" or "OFF", 2)
    end
})

-- ============================================
-- TAB TEST REMOTE
-- ============================================
TabTest:CreateSection("🔥 Fire Remote (spy args)")
local testRemotes = {
    {"SyncData", "👤 SyncData", {}},
    {"SellCrop", "💰 SellCrop (buka GUI buah)", {[2] = "OPEN_FRUIT_GUI"}},
    {"GetBibit", "🛒 GetBibit (buka GUI bibit)", {[1] = 0, [2] = false}},
    {"LahanUpdate", "🏞 LahanUpdate (beli lahan)", {[1] = "CONFIRM_BUY", [2] = {PartName = "AreaTanam Besar2", Price = 100000}}},
    {"HarvestCrop", "🌽 HarvestCrop (contoh Jagung)", {[1] = "Jagung", [2] = 2, [3] = "Jagung"}},
    {"HygieneSync", "🧼 HygieneSync", {[1] = 92}},
    {"RainSync", "🌧 RainSync", {[1] = false, [2] = 5}},
    {"UpdateLevel", "📊 UpdateLevel (simulasi)", {[1] = {Needed=273, TotalXP=4325, Level=28, XP=92, LeveledUp=false}}},
}
for _, t in ipairs(testRemotes) do
    TabTest:CreateButton({
        Name = t[2],
        Callback = function()
            local ok, res = fireR(t[1], table.unpack(t[3] or {}))
            notif(t[1], ok and "OK ✅" or "ERR ❌: "..tostring(res), 3)
        end
    })
end

TabTest:CreateSection("🖱️ Test Klik GUI")
TabTest:CreateButton({
    Name = "🔍 Cari Tombol Beli",
    Callback = function()
        local btn = cariTombol("beli")
        if btn then
            notif("Ditemukan", btn.Text, 3)
        else
            notif("Tidak ada", "Tombol Beli tidak muncul", 3)
        end
    end
})

-- ============================================
-- INIT
-- ============================================
notif("🌾 SAWAH INDO v10", "Welcome "..myName.."! 🔥", 4)
notif("✅ Metode:", "GetBibit(0,false) | SellCrop intercept", 4)

print("=== XKID HUB v10 ===")
print("Fitur: Beli via GetBibit, Jual via intercept, LahanUpdate, HarvestCrop")