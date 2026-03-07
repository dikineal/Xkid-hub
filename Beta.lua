-- 🌾 SAWAH INDO v5.0 — Auto Beli Bibit FULL GUI
-- ProximityPrompt: "Buy Seeds" (Farmer NPC)
-- GUI: Toko Bibit → tombol Beli + jumlah
-- Support: Android + Delta Executor

local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not ok or not Rayfield then warn("❌ Gagal load UI!") return end

local Window = Rayfield:CreateWindow({
    Name          = "🌾 SAWAH INDO [BETA] BY:XKID 💸",
    LoadingTitle  = "XKID_HUB",
    LoadingSubtitle = "auto cuan, no cap 🔥",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- ===== SERVICES =====
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ===== FLAGS =====
_G.AutoFarm  = false
_G.AutoBeli  = false
_G.AutoTanam = false
_G.AutoJual  = false

-- ===== NOTIF =====
local function notif(judul, isi, dur)
    pcall(function()
        Rayfield:Notify({ Title=judul, Content=isi, Duration=dur or 3, Image=4483362458 })
    end)
    print("[SAWAH] "..judul.." » "..isi)
end

-- ===== ROOT =====
local function getRoot()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char and char:WaitForChild("HumanoidRootPart", 3)
end

-- ===== TELEPORT =====
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
    root.CFrame = CFrame.new(pos.X, pos.Y + 4, pos.Z)
    task.wait(0.5)
    return true
end

-- ===== CARI OBJECT =====
local function cari(nama)
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower() == nama:lower() then return v end
    end
    return nil
end

-- ===== CARI LAHAN =====
local function getAllLahan()
    local t = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "Tanah" and v:IsA("BasePart") then
            table.insert(t, v)
        end
    end
    return t
end

-- ================================================
-- ✅ BUKA TOKO BIBIT via ProximityPrompt "Buy Seeds"
-- ================================================
local function bukaTokoBibit()
    -- Step 1: Temukan NPC npcbibit
    local npc = cari("npcbibit")
    if not npc then
        notif("❌ NPC", "npcbibit kagak ketemu bro!", 3)
        return false
    end

    -- Step 2: Teleport ke NPC
    tp(npc)
    task.wait(0.8)

    -- Step 3: Cari ProximityPrompt "Buy Seeds" atau ActionText apapun di NPC
    local prompt = nil
    local searchTarget = npc:IsA("Model") and npc or (npc.Parent or npc)
    for _, v in pairs(searchTarget:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            prompt = v
            break
        end
    end

    -- Fallback: cari PP terdekat di workspace
    if not prompt then
        local root = getRoot()
        if root then
            local nearDist = 15
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    local par = v.Parent
                    if par and par:IsA("BasePart") then
                        local d = (par.Position - root.Position).Magnitude
                        if d < nearDist then
                            -- Prioritaskan yang ActionText-nya "Buy Seeds"
                            if v.ActionText:lower():find("seed") or v.ActionText:lower():find("bibit") or v.ActionText:lower():find("buy") then
                                prompt = v
                                nearDist = d
                            elseif not prompt then
                                prompt = v
                                nearDist = d
                            end
                        end
                    end
                end
            end
        end
    end

    if not prompt then
        notif("❌ Prompt", "ProximityPrompt 'Buy Seeds' kagak ketemu!", 3)
        return false
    end

    -- Step 4: Fire prompt buat buka GUI Toko
    pcall(function() fireproximityprompt(prompt) end)
    task.wait(0.3)
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.15)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)

    -- Tunggu GUI muncul (max 3 detik)
    local timeout = 0
    while timeout < 3 do
        local gui = LocalPlayer.PlayerGui
        for _, v in pairs(gui:GetDescendants()) do
            local n = v.Name:lower()
            if n:find("toko") or n:find("bibit") or n:find("shop") or n:find("seed") then
                return true -- GUI berhasil terbuka
            end
        end
        task.wait(0.3)
        timeout = timeout + 0.3
    end

    -- Mungkin GUI sudah terbuka tapi namanya beda, lanjut saja
    return true
end

-- ================================================
-- ✅ KLIK TOMBOL BELI DI GUI TOKO BIBIT
-- ================================================

-- Pilih bibit berdasarkan nama (scan semua TextLabel di GUI)
local function pilihBibitDiGUI(namaBibit)
    local gui = LocalPlayer.PlayerGui
    for _, label in pairs(gui:GetDescendants()) do
        if label:IsA("TextLabel") or label:IsA("TextButton") then
            local teks = label.Text or ""
            if teks:lower():find(namaBibit:lower()) then
                -- Cari tombol Beli di parent yang sama
                local container = label.Parent
                for _, sibling in pairs(container:GetChildren()) do
                    if sibling:IsA("TextButton") then
                        local st = sibling.Text:lower()
                        if st == "beli" or st == "buy" then
                            return sibling -- return tombol Beli
                        end
                    end
                end
                -- Cek parent satu level di atas
                if container.Parent then
                    for _, cousin in pairs(container.Parent:GetChildren()) do
                        if cousin ~= container then
                            for _, btn in pairs(cousin:GetDescendants()) do
                                if btn:IsA("TextButton") then
                                    local bt = btn.Text:lower()
                                    if bt == "beli" or bt == "buy" then
                                        return btn
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Set jumlah beli dengan klik tombol +
local function setJumlah(namaBibit, jumlah)
    local gui = LocalPlayer.PlayerGui
    for _, label in pairs(gui:GetDescendants()) do
        if (label:IsA("TextLabel") or label:IsA("TextButton")) and (label.Text or ""):lower():find(namaBibit:lower()) then
            local container = label.Parent
            -- Cari tombol + di area ini
            local function cariPlus(frame)
                for _, v in pairs(frame:GetDescendants()) do
                    if v:IsA("TextButton") and (v.Text == "+" or v.Text == "▲") then
                        return v
                    end
                end
                return nil
            end
            local plusBtn = cariPlus(container) or (container.Parent and cariPlus(container.Parent))
            if plusBtn then
                -- Klik + sebanyak (jumlah - 1) kali (default sudah 1)
                for i = 1, jumlah - 1 do
                    pcall(function()
                        local mt = getmetatable(plusBtn).__index
                        plusBtn.MouseButton1Click:Fire()
                    end)
                    pcall(function() fireclickdetector(plusBtn) end)
                    pcall(function()
                        -- Simulasi klik GUI
                        local pos = plusBtn.AbsolutePosition + (plusBtn.AbsoluteSize / 2)
                        game:GetService("VirtualInputManager"):SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                        task.wait(0.05)
                        game:GetService("VirtualInputManager"):SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                    end)
                    task.wait(0.1)
                end
                return true
            end
        end
    end
    return false
end

-- Klik tombol Beli
local function klikBeli(tombolBeli)
    if not tombolBeli then return false end
    -- 3 cara klik tombol GUI
    pcall(function() tombolBeli.MouseButton1Click:Fire() end)
    task.wait(0.05)
    pcall(function()
        local pos = tombolBeli.AbsolutePosition + (tombolBeli.AbsoluteSize / 2)
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    task.wait(0.1)
    return true
end

-- ================================================
-- ✅ FUNGSI UTAMA: AUTO BELI BIBIT
-- ================================================
local function autoBeliBibit(namaBibit, jumlahBeli, delay)
    delay = delay or 1

    -- Buka toko
    if not bukaTokoBibit() then return false end
    task.wait(delay)

    -- Set jumlah kalau > 1
    if jumlahBeli and jumlahBeli > 1 then
        setJumlah(namaBibit, jumlahBeli)
        task.wait(0.3)
    end

    -- Cari dan klik tombol Beli
    local tombol = pilihBibitDiGUI(namaBibit)
    if not tombol then
        -- Fallback: klik semua tombol yang teksnya "Beli"
        local gui = LocalPlayer.PlayerGui
        local fallback = false
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and (v.Text:lower() == "beli" or v.Text:lower() == "buy") then
                -- Pastiin tombolnya visible dan bukan "Tutup"
                if v.Visible then
                    klikBeli(v)
                    fallback = true
                    break
                end
            end
        end
        if not fallback then
            notif("❌ Tombol", "Tombol Beli '"..namaBibit.."' kagak ketemu!", 3)
            return false
        end
    else
        klikBeli(tombol)
    end

    task.wait(0.5)

    -- Tutup GUI biar bersih
    local gui = LocalPlayer.PlayerGui
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and (v.Text:lower() == "tutup" or v.Text:lower() == "close") then
            pcall(function() v.MouseButton1Click:Fire() end)
            pcall(function()
                local pos = v.AbsolutePosition + (v.AbsoluteSize / 2)
                local VIM = game:GetService("VirtualInputManager")
                VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                task.wait(0.05)
                VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
            end)
            break
        end
    end

    return true
end

-- ===== INTERAKSI NPC JUAL =====
local function interakJual(delay)
    delay = delay or 2
    local npc = cari("npcpenjual")
    if not npc then notif("❌", "npcpenjual kagak ada!", 3) return false end
    tp(npc)
    task.wait(delay)
    -- Cari PP terdekat
    local root = getRoot()
    if not root then return false end
    local best, bestD = nil, 15
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local par = v.Parent
            if par and par:IsA("BasePart") then
                local d = (par.Position - root.Position).Magnitude
                if d < bestD then best = v; bestD = d end
            end
        end
    end
    if best then
        pcall(function() fireproximityprompt(best) end)
        task.wait(0.3)
    end
    -- Klik tombol Jual kalau ada GUI
    task.wait(0.5)
    local gui = LocalPlayer.PlayerGui
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and (v.Text:lower():find("jual") or v.Text:lower():find("sell")) and v.Visible then
            klikBeli(v)
            task.wait(0.3)
        end
    end
    return true
end

-- ===== INTERAKSI LAHAN =====
local function interakLahan(lahanObj, delay)
    delay = delay or 1.5
    if not lahanObj then return false end
    tp(lahanObj)
    task.wait(delay)
    local root = getRoot()
    if not root then return false end
    -- Cari PP di lahan
    local best, bestD = nil, 10
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local par = v.Parent
            if par and par:IsA("BasePart") then
                local d = (par.Position - root.Position).Magnitude
                if d < bestD then best = v; bestD = d end
            end
        end
    end
    if best then
        pcall(function() fireproximityprompt(best) end)
        task.wait(0.2)
    end
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.15)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    return true
end

-- ========================================
-- DAFTAR BIBIT (sesuai screenshot game)
-- ========================================
local BIBIT = {
    { name = "Padi",       emoji = "⚡", minLv = 1,   harga = 5    },
    { name = "Jagung",     emoji = "🌽", minLv = 20,  harga = 15   },
    { name = "Tomat",      emoji = "🍅", minLv = 40,  harga = 25   },
    { name = "Terong",     emoji = "🍆", minLv = 60,  harga = 40   },
    { name = "Strawberry", emoji = "🍓", minLv = 80,  harga = 60   },
    { name = "Sawit",      emoji = "🌴", minLv = 80,  harga = 1000 },
    { name = "Durian",     emoji = "🟢", minLv = 120, harga = 2000 },
}

-- ========== TABS ==========
local TabBibit = Window:CreateTab("🛒 Beli Bibit",  nil)
local TabFarm  = Window:CreateTab("🤖 Auto Farm",   nil)
local TabTP    = Window:CreateTab("📍 Teleport",    nil)
local TabScan  = Window:CreateTab("🔍 Scan",        nil)
local TabTools = Window:CreateTab("🛠️ Tools",       nil)

-- ==========================================
-- TAB BELI BIBIT — Pilih Jenis + Jumlah
-- ==========================================
TabBibit:CreateSection("🌱 Pilih Bibit & Jumlah")

-- Dropdown pilih bibit
local pilihanBibit = {}
for _, b in ipairs(BIBIT) do
    table.insert(pilihanBibit, b.emoji .. " " .. b.name .. " (Lv." .. b.minLv .. " | " .. b.harga .. "/bibit)")
end

local selectedBibit = BIBIT[1].name
local jumlahBeli = 1

TabBibit:CreateDropdown({
    Name    = "🌱  Pilih Jenis Bibit",
    Options = pilihanBibit,
    CurrentOption = { pilihanBibit[1] },
    Callback = function(v)
        -- Ambil nama bibit dari pilihan
        for _, b in ipairs(BIBIT) do
            if v[1]:find(b.name) then
                selectedBibit = b.name
                notif("✅ Dipilih", "Bibit: " .. b.emoji .. " " .. b.name, 2)
                break
            end
        end
    end
})

TabBibit:CreateSlider({
    Name         = "🔢  Jumlah Beli per Sesi",
    Range        = {1, 50},
    Increment    = 1,
    CurrentValue = 1,
    Callback     = function(v) jumlahBeli = v end
})

TabBibit:CreateSection("🚀 Aksi Beli")

TabBibit:CreateButton({
    Name = "🛒  BELI SEKARANG — " .. "Bibit Pilihan",
    Callback = function()
        notif("🛒 Beli", "Gas beli " .. jumlahBeli .. "x " .. selectedBibit .. "!", 3)
        task.spawn(function()
            local result = autoBeliBibit(selectedBibit, jumlahBeli, 1.2)
            if result then
                notif("✅ Berhasil!", "Beli " .. jumlahBeli .. "x " .. selectedBibit .. " sukses 🎉", 3)
            end
        end)
    end
})

TabBibit:CreateSection("⚡ Beli Cepat Per Bibit")

for _, b in ipairs(BIBIT) do
    TabBibit:CreateButton({
        Name = b.emoji .. "  Beli " .. b.name .. "  (Lv." .. b.minLv .. " | " .. b.harga .. " coin/bibit)",
        Callback = function()
            task.spawn(function()
                notif("🛒", "Gas beli " .. jumlahBeli .. "x Bibit " .. b.name .. "!", 2)
                autoBeliBibit(b.name, jumlahBeli, 1.2)
            end)
        end
    })
end

TabBibit:CreateSection("🔁 Auto Beli Loop")

local autoBibitDelay = 3
TabBibit:CreateSlider({
    Name = "⏱️  Delay Auto Beli (detik)",
    Range = {2, 15}, Increment = 1, CurrentValue = 3,
    Callback = function(v) autoBibitDelay = v end
})

TabBibit:CreateToggle({
    Name         = "🔁  Auto Beli Bibit Terus (Bibit Pilihan)",
    CurrentValue = false,
    Callback     = function(v)
        _G.AutoBeli = v
        if v then
            notif("🔁 Auto Beli ON", "Loop beli " .. selectedBibit .. " tiap " .. autoBibitDelay .. "s", 3)
            task.spawn(function()
                while _G.AutoBeli do
                    autoBeliBibit(selectedBibit, jumlahBeli, 1.2)
                    task.wait(autoBibitDelay)
                end
            end)
        else
            notif("⛔ Auto Beli", "Distop!", 2)
        end
    end
})

-- ==========================================
-- TAB AUTO FARM
-- ==========================================
TabFarm:CreateSection("⚙️ Setting Delay")

local dBeli  = 1.2
local dTanam = 1.5
local dJual  = 2
local dPanen = 10

TabFarm:CreateSlider({ Name="⏱️ Delay Beli",  Range={1,6},  Increment=0.5, CurrentValue=1.2, Callback=function(v) dBeli=v  end })
TabFarm:CreateSlider({ Name="⏱️ Delay Tanam", Range={1,5},  Increment=0.5, CurrentValue=1.5, Callback=function(v) dTanam=v end })
TabFarm:CreateSlider({ Name="⏱️ Delay Jual",  Range={1,6},  Increment=0.5, CurrentValue=2,   Callback=function(v) dJual=v  end })
TabFarm:CreateSlider({ Name="⏳ Tunggu Panen",Range={3,60}, Increment=1,   CurrentValue=10,  Callback=function(v) dPanen=v end })

TabFarm:CreateSection("🤖 Auto Farm Full")

TabFarm:CreateToggle({
    Name         = "🌾  AUTO FARM — Beli » Tanam » Panen » Jual",
    CurrentValue = false,
    Callback     = function(v)
        _G.AutoFarm = v
        if v then
            notif("🚀 AUTO FARM ON", "Gas brooo! Cuan incoming 💸", 4)
            task.spawn(function()
                local siklus = 0
                while _G.AutoFarm do
                    siklus += 1
                    print("\n🔄 ===== SIKLUS #"..siklus.." =====")

                    -- 1. Beli bibit
                    print("  🛒 Beli bibit "..selectedBibit.."...")
                    autoBeliBibit(selectedBibit, jumlahBeli, dBeli)
                    if not _G.AutoFarm then break end
                    task.wait(0.5)

                    -- 2. Tanam semua lahan
                    print("  🌱 Tanam di semua lahan...")
                    local lahans = getAllLahan()
                    local ok2 = 0
                    for i, lahan in ipairs(lahans) do
                        if not _G.AutoFarm then break end
                        print("    Lahan "..i.."/"..#lahans)
                        if interakLahan(lahan, dTanam) then ok2 += 1 end
                        task.wait(0.2)
                    end
                    print("  ✅ Tanam "..ok2.."/"..#lahans.." lahan")
                    if not _G.AutoFarm then break end

                    -- 3. Tunggu panen
                    print("  ⏳ Nunggu panen "..dPanen.."s...")
                    notif("⏳ Nunggu", "Panen dalam "..dPanen.."s...", dPanen)
                    task.wait(dPanen)
                    if not _G.AutoFarm then break end

                    -- 4. Jual
                    print("  💰 Jual hasil...")
                    interakJual(dJual)
                    task.wait(0.5)

                    notif("✅ Siklus #"..siklus, "Done! Auto loop lagi 🔁", 3)
                    task.wait(1)
                end
                notif("⛔ AUTO FARM", "Distop, santai dulu 😴", 3)
            end)
        else
            notif("⛔ AUTO FARM", "Off!", 2)
        end
    end
})

TabFarm:CreateSection("🎛️ Auto Satuan")

TabFarm:CreateToggle({
    Name="🌱  Auto Tanam Semua Lahan", CurrentValue=false,
    Callback=function(v)
        _G.AutoTanam = v
        if v then
            task.spawn(function()
                while _G.AutoTanam do
                    for _, l in ipairs(getAllLahan()) do
                        if not _G.AutoTanam then break end
                        interakLahan(l, dTanam)
                    end
                    task.wait(3)
                end
            end)
            notif("🌱 Auto Tanam ON","Loop tanam aktif~",3)
        else notif("⛔ Auto Tanam","Distop",2) end
    end
})

TabFarm:CreateToggle({
    Name="💰  Auto Jual Aja", CurrentValue=false,
    Callback=function(v)
        _G.AutoJual = v
        if v then
            task.spawn(function()
                while _G.AutoJual do interakJual(dJual) task.wait(dJual+1) end
            end)
            notif("💰 Auto Jual ON","Selling machine 🤑",3)
        else notif("⛔ Auto Jual","Distop",2) end
    end
})

TabFarm:CreateSection("🔴 Kill Switch")
TabFarm:CreateButton({
    Name="⛔  STOP SEMUA — Panik Mode",
    Callback=function()
        _G.AutoFarm=false _G.AutoBeli=false _G.AutoTanam=false _G.AutoJual=false
        notif("🛑 STOP SEMUA","Semua auto dimatiin, aman bro!",3)
    end
})

-- ==========================================
-- TAB TELEPORT
-- ==========================================
TabTP:CreateSection("NPC 🏪")
local npcList = {
    {icon="🛒", name="npcbibit",          label="Beli Bibit"},
    {icon="💰", name="npcpenjual",         label="Jual Hasil"},
    {icon="🔧", name="npcalat",            label="Beli Alat"},
    {icon="🥚", name="NPCPedagangTelur",   label="Jual Telur"},
    {icon="🌴", name="NPCPedagangSawit",   label="Jual Sawit"},
}
for _, npc in ipairs(npcList) do
    TabTP:CreateButton({
        Name = npc.icon.."  "..npc.name.." — "..npc.label,
        Callback = function()
            local o = cari(npc.name)
            if o then tp(o) notif("📍",npc.name.." ✅",2)
            else notif("❌ Zonk",npc.name.." kagak ada",3) end
        end
    })
end
TabTP:CreateSection("Lahan 🌾")
TabTP:CreateButton({
    Name="🌾  Lahan Pertama",
    Callback=function()
        local l=getAllLahan()
        if #l>0 then tp(l[1]) notif("📍","Di lahan pertama!",2)
        else notif("❌","Lahan kagak ada",3) end
    end
})

-- ==========================================
-- TAB SCAN
-- ==========================================
TabScan:CreateSection("Deteksi 🔍")
TabScan:CreateButton({
    Name="🔍  Scan GUI PlayerGui (Toko Bibit)",
    Callback=function()
        local gui = LocalPlayer.PlayerGui
        print("=== GUI SCAN ===")
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") or v:IsA("TextLabel") then
                if (v.Text or "") ~= "" then
                    print(v.ClassName.." | Name:"..v.Name.." | Text:"..v.Text.." | Path:"..v:GetFullName())
                end
            end
        end
        notif("🔍 GUI Scan","Selesai! Cek console F9",4)
    end
})
TabScan:CreateButton({
    Name="🔍  Scan ProximityPrompt",
    Callback=function()
        local n=0
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                n+=1
                print("PP: "..v:GetFullName().." | Action: "..v.ActionText.." | Object: "..(v.ObjectText or ""))
            end
        end
        notif("🔍 PP Scan",n.." ProximityPrompt ketemu!",4)
    end
})
TabScan:CreateButton({
    Name="📡  Scan RemoteEvent",
    Callback=function()
        local n=0
        for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                n+=1 print(v.ClassName..": "..v:GetFullName())
            end
        end
        notif("📡 Remote",n.." remote ketemu!",4)
    end
})
TabScan:CreateButton({
    Name="🌾  Hitung Lahan",
    Callback=function()
        notif("🌾 Lahan","Ada "..#getAllLahan().." lahan Tanah!",4)
    end
})

-- ==========================================
-- TAB TOOLS
-- ==========================================
TabTools:CreateSection("Utilitas 🛠️")
TabTools:CreateButton({
    Name="📍  Koordinat Gue",
    Callback=function()
        local r=getRoot()
        if r then
            local p=r.Position
            notif("📍 Posisi",("X=%.1f  Y=%.1f  Z=%.1f"):format(p.X,p.Y,p.Z),5)
        end
    end
})
TabTools:CreateButton({
    Name="🔄  Reset Karakter",
    Callback=function()
        local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.Health=0 notif("🔄","Respawn~",2) end
    end
})
TabTools:CreateButton({
    Name="🧪  Test Buka Toko Bibit",
    Callback=function()
        task.spawn(function()
            local r = bukaTokoBibit()
            notif(r and "✅ Toko Terbuka!" or "❌ Gagal Buka Toko",
                  r and "GUI Toko Bibit berhasil dibuka!" or "Coba scan PP dulu bro", 4)
        end)
    end
})
TabTools:CreateButton({
    Name="💡  Cara Pakai",
    Callback=function()
        print("=== CARA PAKAI SAWAH INDO v5.0 ===")
        print("1. Tab SCAN → Scan PP & GUI dulu")
        print("2. Tab TOOLS → Test Buka Toko Bibit")
        print("3. Tab BELI BIBIT → Pilih bibit + jumlah → Beli!")
        print("4. Tab AUTO FARM → Setting delay → ON")
        notif("💡 Tips","Scan dulu → Test → Baru Auto Farm! 🚀",6)
    end
})

-- ===== READY =====
print("╔══════════════════════════════════╗")
print("║  🌾 SAWAH INDO v5.0  💸          ║")
print("║  Auto Beli Bibit via GUI Toko    ║")
print("║  ProximityPrompt: Buy Seeds ✅   ║")
print("║  Android + Delta Ready ✅        ║")
print("╚══════════════════════════════════╝")
notif("🌾 SAWAH INDO v5.0","Siap gas! Auto cuan mode: ON 💸🔥",5)
