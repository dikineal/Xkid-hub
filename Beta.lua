-- 🌾 SAWAH INDO v5.1 — BASE v5 + FILTER LAHAN SENDIRI
-- Support: Android + Delta Executor

local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('://sirius.menu/rayfield'))()
end)
if not ok or not Rayfield then warn("❌ Gagal load UI!") return end

local Window = Rayfield:CreateWindow({
    Name          = "🌾 SAWAH INDO v5.1 💸",
    LoadingTitle  = "SAWAH INDO HUB",
    LoadingSubtitle = "auto cuan, no cap 🔥",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- ===== SERVICES =====
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local myName      = LocalPlayer.Name

-- ===== FLAGS =====
_G.AutoFarm  = false
_G.AutoBeli  = false
_G.AutoTanam = false
_G.AutoJual  = false

-- Hasil scan lahan
local lahanOwnerAttr = nil
local lahanNamaObj   = nil

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

-- ===== SCAN LAHAN MILIK SENDIRI =====
local function scanLahan()
    local keywords = {"tanah","lahan","plot","farm","field","sawah","land"}
    local attrList = {"Owner","owner","PlayerName","playername","Username","username","Player","player","OwnedBy","ownedby"}

    for _, v in pairs(workspace:GetDescendants()) do
        local namaLower = v.Name:lower()
        local isLahan = false
        for _, kw in ipairs(keywords) do
            if namaLower:find(kw) then isLahan = true; break end
        end

        if isLahan and (v:IsA("BasePart") or v:IsA("Model")) then
            for _, aName in ipairs(attrList) do
                local val = v:GetAttribute(aName)
                if val and tostring(val):lower() == myName:lower() then
                    lahanOwnerAttr = aName
                    lahanNamaObj   = v.Name
                    print("✅ Lahan ketemu: "..v.Name.." | "..aName.."="..tostring(val))
                    return true
                end
            end
            if v.Name:lower():find(myName:lower()) then
                lahanNamaObj = v.Name
                print("✅ Lahan ketemu by name: "..v.Name)
                return true
            end
        end
    end
    return false
end

-- ===== AMBIL LAHAN =====
-- Kalau sudah scan → pakai lahan sendiri
-- Kalau belum scan → fallback semua "Tanah"
local function getAllLahan()
    local lahans = {}

    if lahanNamaObj then
        -- Sudah scan, filter by owner
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == lahanNamaObj and (v:IsA("BasePart") or v:IsA("Model")) then
                if lahanOwnerAttr then
                    local val = v:GetAttribute(lahanOwnerAttr)
                    if val and tostring(val):lower() == myName:lower() then
                        table.insert(lahans, v)
                    end
                else
                    table.insert(lahans, v)
                end
            end
        end
    end

    -- Fallback ke semua "Tanah" kalau hasil scan kosong
    if #lahans == 0 then
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "Tanah" and v:IsA("BasePart") then
                table.insert(lahans, v)
            end
        end
    end

    return lahans
end

-- ================================================
-- ✅ BUKA TOKO BIBIT via ProximityPrompt
-- ================================================
local function bukaTokoBibit()
    local npc = cari("npcbibit")
    if not npc then
        notif("❌ NPC", "npcbibit kagak ketemu bro!", 3)
        return false
    end

    tp(npc)
    task.wait(0.8)

    local prompt = nil
    local searchTarget = npc:IsA("Model") and npc or (npc.Parent or npc)
    for _, v in pairs(searchTarget:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            prompt = v
            break
        end
    end

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
        notif("❌ Prompt", "ProximityPrompt kagak ketemu!", 3)
        return false
    end

    pcall(function() fireproximityprompt(prompt) end)
    task.wait(0.3)
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.15)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)

    local timeout = 0
    while timeout < 3 do
        local gui = LocalPlayer.PlayerGui
        for _, v in pairs(gui:GetDescendants()) do
            local n = v.Name:lower()
            if n:find("toko") or n:find("bibit") or n:find("shop") or n:find("seed") then
                return true
            end
        end
        task.wait(0.3)
        timeout = timeout + 0.3
    end

    return true
end

-- ================================================
-- ✅ KLIK TOMBOL GUI
-- ================================================
local function klikBeli(tombolBeli)
    if not tombolBeli then return false end
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

local function setJumlah(namaBibit, jumlah)
    local gui = LocalPlayer.PlayerGui
    for _, label in pairs(gui:GetDescendants()) do
        if (label:IsA("TextLabel") or label:IsA("TextButton")) and (label.Text or ""):lower():find(namaBibit:lower()) then
            local container = label.Parent
            local function cariPlus(frame)
                for _, v in pairs(frame:GetDescendants()) do
                    if v:IsA("TextButton") and (v.Text == "+" or v.Text == "▲") then return v end
                end
                return nil
            end
            local plusBtn = cariPlus(container) or (container.Parent and cariPlus(container.Parent))
            if plusBtn then
                for i = 1, jumlah - 1 do
                    pcall(function() plusBtn.MouseButton1Click:Fire() end)
                    pcall(function()
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

local function pilihBibitDiGUI(namaBibit)
    local gui = LocalPlayer.PlayerGui
    for _, label in pairs(gui:GetDescendants()) do
        if label:IsA("TextLabel") or label:IsA("TextButton") then
            local teks = label.Text or ""
            if teks:lower():find(namaBibit:lower()) then
                local container = label.Parent
                for _, sibling in pairs(container:GetChildren()) do
                    if sibling:IsA("TextButton") then
                        local st = sibling.Text:lower()
                        if st == "beli" or st == "buy" then return sibling end
                    end
                end
                if container.Parent then
                    for _, cousin in pairs(container.Parent:GetChildren()) do
                        if cousin ~= container then
                            for _, btn in pairs(cousin:GetDescendants()) do
                                if btn:IsA("TextButton") then
                                    local bt = btn.Text:lower()
                                    if bt == "beli" or bt == "buy" then return btn end
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

-- ================================================
-- ✅ AUTO BELI BIBIT
-- ================================================
local function autoBeliBibit(namaBibit, jumlahBeli, delay)
    delay = delay or 1
    if not bukaTokoBibit() then return false end
    task.wait(delay)

    if jumlahBeli and jumlahBeli > 1 then
        setJumlah(namaBibit, jumlahBeli)
        task.wait(0.3)
    end

    local tombol = pilihBibitDiGUI(namaBibit)
    if not tombol then
        local gui = LocalPlayer.PlayerGui
        local fallback = false
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and (v.Text:lower() == "beli" or v.Text:lower() == "buy") and v.Visible then
                klikBeli(v)
                fallback = true
                break
            end
        end
        if not fallback then
            notif("❌ Tombol", "Tombol Beli kagak ketemu!", 3)
            return false
        end
    else
        klikBeli(tombol)
    end

    task.wait(0.5)
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

    task.wait(0.5)
    local gui = LocalPlayer.PlayerGui
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and (v.Text:lower():find("jual") or v.Text:lower():find("sell")) and v.Visible then
            klikBeli(v)
            task.wait(0.3)
        end
    end

    -- Tutup GUI
    task.wait(0.3)
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and (v.Text:lower() == "tutup" or v.Text:lower() == "close") and v.Visible then
            klikBeli(v) break
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

    -- Klik tombol Tanam kalau ada GUI
    task.wait(0.3)
    local gui = LocalPlayer.PlayerGui
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local t = v.Text:lower()
            if t:find("tanam") or t:find("plant") then
                klikBeli(v) break
            end
        end
    end
    return true
end

-- ========================================
-- DAFTAR BIBIT
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
local TabBibit = Window:CreateTab("🛒 Beli Bibit", nil)
local TabFarm  = Window:CreateTab("🤖 Auto Farm",  nil)
local TabTP    = Window:CreateTab("📍 Teleport",   nil)
local TabScan  = Window:CreateTab("🔍 Scan",       nil)
local TabTools = Window:CreateTab("🛠️ Tools",      nil)

-- ==========================================
-- TAB BELI BIBIT
-- ==========================================
TabBibit:CreateSection("🌱 Pilih Bibit & Jumlah")

local pilihanBibit = {}
for _, b in ipairs(BIBIT) do
    table.insert(pilihanBibit, b.emoji.." "..b.name.." (Lv."..b.minLv.." | "..b.harga.."/bibit)")
end

local selectedBibit = BIBIT[1].name
local jumlahBeli = 1

TabBibit:CreateDropdown({
    Name = "🌱  Pilih Jenis Bibit",
    Options = pilihanBibit,
    CurrentOption = { pilihanBibit[1] },
    Callback = function(v)
        for _, b in ipairs(BIBIT) do
            if v[1]:find(b.name) then
                selectedBibit = b.name
                notif("✅ Dipilih", "Bibit: "..b.emoji.." "..b.name, 2)
                break
            end
        end
    end
})

TabBibit:CreateSlider({
    Name = "🔢  Jumlah Beli per Sesi",
    Range = {1, 50}, Increment = 1, CurrentValue = 1,
    Callback = function(v) jumlahBeli = v end
})

TabBibit:CreateSection("🚀 Aksi Beli")

TabBibit:CreateButton({
    Name = "🛒  BELI SEKARANG",
    Callback = function()
        notif("🛒 Beli", "Gas beli "..jumlahBeli.."x "..selectedBibit.."!", 3)
        task.spawn(function()
            local result = autoBeliBibit(selectedBibit, jumlahBeli, 1.2)
            if result then notif("✅ Berhasil!", "Beli "..jumlahBeli.."x "..selectedBibit.." sukses 🎉", 3) end
        end)
    end
})

TabBibit:CreateSection("⚡ Beli Cepat Per Bibit")
for _, b in ipairs(BIBIT) do
    TabBibit:CreateButton({
        Name = b.emoji.."  Beli "..b.name.."  (Lv."..b.minLv.." | "..b.harga.." coin/bibit)",
        Callback = function()
            task.spawn(function()
                notif("🛒", "Gas beli "..jumlahBeli.."x "..b.name.."!", 2)
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
    Name = "🔁  Auto Beli Bibit Terus",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoBeli = v
        if v then
            notif("🔁 Auto Beli ON", "Loop beli "..selectedBibit.." tiap "..autoBibitDelay.."s", 3)
            task.spawn(function()
                while _G.AutoBeli do
                    autoBeliBibit(selectedBibit, jumlahBeli, 1.2)
                    task.wait(autoBibitDelay)
                end
            end)
        else notif("⛔ Auto Beli", "Distop!", 2) end
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

TabFarm:CreateSlider({Name="⏱️ Delay Beli",   Range={1,6},  Increment=0.5, CurrentValue=1.2, Callback=function(v) dBeli=v  end})
TabFarm:CreateSlider({Name="⏱️ Delay Tanam",  Range={1,5},  Increment=0.5, CurrentValue=1.5, Callback=function(v) dTanam=v end})
TabFarm:CreateSlider({Name="⏱️ Delay Jual",   Range={1,6},  Increment=0.5, CurrentValue=2,   Callback=function(v) dJual=v  end})
TabFarm:CreateSlider({Name="⏳ Tunggu Panen", Range={3,60}, Increment=1,   CurrentValue=10,  Callback=function(v) dPanen=v end})

TabFarm:CreateSection("🤖 Auto Farm Full")
TabFarm:CreateToggle({
    Name = "🌾  AUTO FARM — Beli » Tanam » Panen » Jual",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoFarm = v
        if v then
            notif("🚀 AUTO FARM ON", "Gas brooo! Cuan incoming 💸", 4)
            task.spawn(function()
                local siklus = 0
                while _G.AutoFarm do
                    siklus += 1
                    print("\n🔄 SIKLUS #"..siklus)

                    print("  🛒 Beli "..selectedBibit.."...")
                    autoBeliBibit(selectedBibit, jumlahBeli, dBeli)
                    if not _G.AutoFarm then break end
                    task.wait(0.5)

                    print("  🌱 Tanam...")
                    local lahans = getAllLahan()
                    local ok2 = 0
                    for i, lahan in ipairs(lahans) do
                        if not _G.AutoFarm then break end
                        if interakLahan(lahan, dTanam) then ok2 += 1 end
                        task.wait(0.2)
                    end
                    print("  ✅ Tanam "..ok2.."/"..#lahans)
                    if not _G.AutoFarm then break end

                    print("  ⏳ Nunggu panen "..dPanen.."s...")
                    notif("⏳ Nunggu", "Panen dalam "..dPanen.."s...", dPanen)
                    task.wait(dPanen)
                    if not _G.AutoFarm then break end

                    print("  💰 Jual...")
                    interakJual(dJual)
                    task.wait(0.5)

                    notif("✅ Siklus #"..siklus, "Done! Loop lagi 🔁", 3)
                    task.wait(1)
                end
                notif("⛔ AUTO FARM", "Distop, santai dulu 😴", 3)
            end)
        else notif("⛔ AUTO FARM", "Off!", 2) end
    end
})

TabFarm:CreateSection("🎛️ Auto Satuan")
TabFarm:CreateToggle({
    Name = "🌱  Auto Tanam Lahan Sendiri",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoTanam = v
        if v then
            task.spawn(function()
                while _G.AutoTanam do
                    local lahans = getAllLahan()
                    for _, lahan in ipairs(lahans) do
                        if not _G.AutoTanam then break end
                        interakLahan(lahan, dTanam)
                    end
                    task.wait(3)
                end
            end)
            notif("🌱 Auto Tanam ON", "Loop tanam lahan sendiri~", 3)
        else notif("⛔ Auto Tanam", "Off", 2) end
    end
})
TabFarm:CreateToggle({
    Name = "💰  Auto Jual Aja",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoJual = v
        if v then
            task.spawn(function()
                while _G.AutoJual do interakJual(dJual) task.wait(dJual+1) end
            end)
            notif("💰 Auto Jual ON", "Selling machine 🤑", 3)
        else notif("⛔ Auto Jual", "Off", 2) end
    end
})

TabFarm:CreateSection("🔴 Kill Switch")
TabFarm:CreateButton({
    Name = "⛔  STOP SEMUA",
    Callback = function()
        _G.AutoFarm=false _G.AutoBeli=false _G.AutoTanam=false _G.AutoJual=false
        notif("🛑 STOP", "Semua auto dimatiin!", 3)
    end
})

-- ==========================================
-- TAB TELEPORT
-- ==========================================
TabTP:CreateSection("NPC 🏪")
local npcList = {
    {icon="🛒", name="npcbibit",         label="Beli Bibit"},
    {icon="💰", name="npcpenjual",        label="Jual Hasil"},
    {icon="🔧", name="npcalat",           label="Beli Alat"},
    {icon="🥚", name="NPCPedagangTelur",  label="Jual Telur"},
    {icon="🌴", name="NPCPedagangSawit",  label="Jual Sawit"},
}
for _, npc in ipairs(npcList) do
    TabTP:CreateButton({
        Name = npc.icon.."  "..npc.name.." — "..npc.label,
        Callback = function()
            local o = cari(npc.name)
            if o then tp(o) notif("📍", npc.name.." ✅", 2)
            else notif("❌", npc.name.." kagak ada", 3) end
        end
    })
end
TabTP:CreateSection("Lahan 🌾")
TabTP:CreateButton({
    Name = "🌾  Teleport ke Lahan Kamu",
    Callback = function()
        local lahans = getAllLahan()
        if #lahans > 0 then
            tp(lahans[1])
            notif("📍", "Di lahan kamu!", 2)
        else
            notif("❌", "Lahan kagak ketemu, scan dulu!", 3)
        end
    end
})

-- ==========================================
-- TAB SCAN — PENTING UNTUK FILTER LAHAN
-- ==========================================
TabScan:CreateSection("🔍 Scan Lahan Milik Kamu")
TabScan:CreateLabel("⚠️ Berdiri di LAHAN KAMU dulu sebelum scan!")
TabScan:CreateButton({
    Name = "🔍  SCAN LAHAN SEKARANG",
    Callback = function()
        notif("🔍 Scanning...", "Nyari lahan milik "..myName.."...", 3)
        task.spawn(function()
            local found = scanLahan()
            if found then
                notif("✅ Ketemu!", "Lahan: "..(lahanNamaObj or "?").." siap dipakai! Auto Farm sekarang hanya ke lahan kamu 🎉", 6)
            else
                notif("⚠️ Belum Ketemu", "Jalan ke lahan kamu lalu scan lagi! Sekarang pakai semua lahan 'Tanah'", 6)
            end
        end)
    end
})
TabScan:CreateButton({
    Name = "📋  Lihat Hasil Scan",
    Callback = function()
        notif("📋 Hasil", "Lahan: "..(lahanNamaObj or "belum scan").." | Attr: "..(lahanOwnerAttr or "-"), 6)
        print("Nama Lahan : "..(lahanNamaObj   or "BELUM SCAN"))
        print("Attr Owner : "..(lahanOwnerAttr  or "BELUM SCAN"))
    end
})
TabScan:CreateButton({
    Name = "🌾  Hitung Lahan Kamu",
    Callback = function()
        local n = #getAllLahan()
        notif("🌾 Lahan", "Ditemukan "..n.." lahan", 4)
    end
})
TabScan:CreateButton({
    Name = "🔍  Scan Semua ProximityPrompt",
    Callback = function()
        local n = 0
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                n += 1
                print("PP: ["..v.ActionText.."] | "..v:GetFullName())
            end
        end
        notif("🔍 PP", n.." ProximityPrompt ketemu!", 4)
    end
})

-- ==========================================
-- TAB TOOLS
-- ==========================================
TabTools:CreateSection("Utilitas 🛠️")
TabTools:CreateButton({
    Name = "📍  Koordinat Gue",
    Callback = function()
        local r = getRoot()
        if r then
            local p = r.Position
            notif("📍 Posisi", ("X=%.1f Y=%.1f Z=%.1f"):format(p.X, p.Y, p.Z), 5)
        end
    end
})
TabTools:CreateButton({
    Name = "🔄  Reset Karakter",
    Callback = function()
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.Health = 0 notif("🔄", "Respawn~", 2) end
    end
})
TabTools:CreateButton({
    Name = "🧪  Test Buka Toko Bibit",
    Callback = function()
        task.spawn(function()
            local r = bukaTokoBibit()
            notif(r and "✅ Toko Terbuka!" or "❌ Gagal",
                  r and "GUI Toko Bibit berhasil!" or "PP kagak ketemu", 4)
        end)
    end
})
TabTools:CreateButton({
    Name = "🧪  Test Jual Manual",
    Callback = function()
        task.spawn(function()
            local r = interakJual(2)
            notif(r and "✅ Jual OK!" or "❌ Gagal Jual", "", 4)
        end)
    end
})

-- ===== INIT =====
print("🌾 SAWAH INDO v5.1 | User: "..myName)
notif("🌾 SAWAH INDO v5.1", "Halo "..myName.."! Scan lahan dulu di tab 🔍 Scan ya!", 6)
