-- ╔══════════════════════════════════════════════════╗
-- ║   🌾 SAWAH INDO v10.0 ULTIMATE — XKID HUB       ║
-- ║   Based on Cobalt Spy Log (Confirmed)            ║
-- ║   Support: Android + Delta / Arceus / Fluxus     ║
-- ╚══════════════════════════════════════════════════╝

--[[
    REMOTE MAP (dikonfirmasi dari Cobalt spy):

    SERVER → CLIENT (kita intercept, bukan kita fire):
    ├── GetBibit.OnClientEvent      (0, false)           → server buka GUI bibit
    ├── SellCrop.OnClientEvent      (nil, "OPEN_*_GUI")  → server buka GUI jual
    ├── HarvestCrop.OnClientEvent   ("Padi", 1, "Padi")  → server play sound panen
    ├── UpdateLevel.OnClientEvent   ({Level,XP,...})     → server update level
    ├── Notification.OnClientEvent  ("string")           → server kirim notif
    ├── HygieneSync.OnClientEvent   (number)             → sync hygiene
    ├── RainSync.OnClientEvent      (bool, number)       → sync cuaca
    └── LightningStrike.OnClientEvent ({Reason,Hit,Pos}) → ⚡ KENA PETIR

    CLIENT → SERVER (kita yang fire/invoke):
    ├── PlantCrop:FireServer(Vector3)          → tanam
    ├── RequestSell:InvokeServer()             → jual semua
    ├── RequestShop:InvokeServer(name, qty)    → beli bibit
    ├── RequestToolShop:InvokeServer()         → lihat/beli alat
    ├── SyncData:InvokeServer()                → sync data player
    ├── SummonRain:FireServer()                → panggil hujan
    └── LahanUpdate:FireServer("CONFIRM_BUY", {PartName, Price}) → beli lahan
]]

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name            = "🌾 SAWAH INDO v10.0 💸",
    LoadingTitle    = "XKID HUB",
    LoadingSubtitle = "Cobalt Spy Edition 🔥",
    ConfigurationSaving = { Enabled = false },
    KeySystem       = false,
})

-- ══════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════
-- FLAGS
-- ══════════════════════════════════════════
_G.ScriptRunning  = true
_G.AutoFarm       = false
_G.AutoBeli       = false
_G.AutoJual       = false
_G.AutoTanam      = false
_G.AutoRain       = false
_G.PenangkalPetir = false
_G.AutoConfirm    = false
_G.NotifLevelUp   = true

-- ══════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════
local PlayerData = {
    Coins   = 0,
    Level   = 1,
    XP      = 0,
    Needed  = 50,
    LastSync = 0,
}

local SiklusCount  = 0
local lightningHits = 0
local levelUpCount  = 0
local BeliLoop      = nil
local SafePos       = nil
local LahanCache    = {}   -- list of Vector3 posisi lahan
local LahanCacheTime = 0

-- Setting
local selectedBibit = "Bibit Padi"
local jumlahBeli    = 1
local dTanam        = 0.5   -- delay antar PlantCrop
local waitPanen     = 60    -- detik tunggu panen
local rainInterval  = 150   -- detik auto rain

-- Bibit list (dari RequestShop spy sebelumnya)
local BIBIT_LIST = {
    { name = "Bibit Padi",       icon = "🌾", price = 5,    minLv = 1   },
    { name = "Bibit Jagung",     icon = "🌽", price = 15,   minLv = 20  },
    { name = "Bibit Tomat",      icon = "🍅", price = 25,   minLv = 40  },
    { name = "Bibit Terong",     icon = "🍆", price = 40,   minLv = 60  },
    { name = "Bibit Strawberry", icon = "🍓", price = 60,   minLv = 80  },
    { name = "Bibit Sawit",      icon = "🌴", price = 1000, minLv = 80  },
    { name = "Bibit Durian",     icon = "🍈", price = 2000, minLv = 120 },
}

-- ══════════════════════════════════════════
-- NOTIF
-- ══════════════════════════════════════════
local function notif(title, body, dur)
    pcall(function()
        Rayfield:Notify({ Title=title, Content=body, Duration=dur or 3, Image=4483362458 })
    end)
    print("[XKID] "..title.." — "..body)
end

-- ══════════════════════════════════════════
-- CHARACTER
-- ══════════════════════════════════════════
local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPos()
    local r = getRoot(); return r and r.Position
end

-- ══════════════════════════════════════════
-- REMOTE HELPER
-- Path: RS.Remotes.TutorialRemotes.<name>
-- ══════════════════════════════════════════
local remoteCache = {}

local function getRemote(name)
    if remoteCache[name] then return remoteCache[name] end
    local folder = RS:FindFirstChild("Remotes")
    folder = folder and folder:FindFirstChild("TutorialRemotes")
    if not folder then return nil end
    local r = folder:FindFirstChild(name)
    if r then remoteCache[name] = r end
    return r
end

-- FireServer ke RemoteEvent
local function fireEv(name, ...)
    local r = getRemote(name)
    if not r or not r:IsA("RemoteEvent") then
        return false, "RemoteEvent '"..name.."' tidak ditemukan"
    end
    local ok, err = pcall(function(...) r:FireServer(...) end, ...)
    return ok, err
end

-- InvokeServer ke RemoteFunction
local function invokeRF(name, ...)
    local r = getRemote(name)
    if not r or not r:IsA("RemoteFunction") then
        return false, nil, "RemoteFunction '"..name.."' tidak ditemukan"
    end
    local ok, res = pcall(function(...) return r:InvokeServer(...) end, ...)
    return ok, res
end

-- Ambil table data dari hasil invoke (handle array wrapper)
local function unwrap(result)
    if type(result) == "table" then
        return (type(result[1]) == "table") and result[1] or result
    end
    return nil
end

-- ══════════════════════════════════════════
-- SCAN LAHAN
-- Cari semua BasePart AreaTanam* di Workspace
-- Simpan sebagai Vector3 → dipakai di PlantCrop
-- ══════════════════════════════════════════
local function scanLahan()
    if tick() - LahanCacheTime < 10 and #LahanCache > 0 then
        return LahanCache
    end
    LahanCache = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("areatanambesar") or n:find("areatanampadi")
            or n:find("areatanamsawah") or n:find("areatanamsawit") then
                table.insert(LahanCache, v.Position)
            end
        end
    end
    LahanCacheTime = tick()
    return LahanCache
end

-- ══════════════════════════════════════════
-- BELI BIBIT
-- RequestShop:InvokeServer(name, qty)
-- Return: {Success, Message, NewCoins}
-- ══════════════════════════════════════════
local function beliBibit(nama, qty)
    nama = nama or selectedBibit
    qty  = qty  or jumlahBeli
    local ok, res = invokeRF("RequestShop", nama, qty)
    if not ok then return false, "RequestShop gagal" end
    local data = unwrap(res)
    if data and data.Success then
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        return true, data.Message or "Berhasil"
    end
    return false, (data and data.Message) or "Gagal"
end

-- ══════════════════════════════════════════
-- TANAM
-- PlantCrop:FireServer(Vector3)
-- Server tau sendiri bibit apa yg dipunya
-- ══════════════════════════════════════════
local function tanamSemua()
    local lahans = scanLahan()
    if #lahans == 0 then return 0, "Tidak ada lahan" end
    local count = 0
    for _, pos in ipairs(lahans) do
        if not _G.AutoTanam and not _G.AutoFarm then break end
        local ok = fireEv("PlantCrop", pos)
        if ok then count = count + 1 end
        task.wait(dTanam)
    end
    return count
end

-- ══════════════════════════════════════════
-- JUAL
-- RequestSell:InvokeServer() — tanpa args
-- Return: {Success, Message, NewCoins}
-- ══════════════════════════════════════════
local function jualSemua()
    local ok, res = invokeRF("RequestSell")
    if not ok then return false, "RequestSell gagal" end
    local data = unwrap(res)
    if data and data.Success then
        PlayerData.Coins = data.NewCoins or data.Coins or PlayerData.Coins
        return true, data.Message or ("+"..tostring(data.Coins or 0).." Coins")
    end
    return false, (data and data.Message) or "Gagal"
end

-- ══════════════════════════════════════════
-- HUJAN
-- SummonRain:FireServer()
-- ══════════════════════════════════════════
local function summonRain()
    return fireEv("SummonRain")
end

-- ══════════════════════════════════════════
-- SYNC DATA
-- SyncData:InvokeServer()
-- ══════════════════════════════════════════
local function syncData()
    local ok, res = invokeRF("SyncData")
    if not ok then return false end
    local data = unwrap(res)
    if not data then return false end
    PlayerData.Coins  = data.Coins  or PlayerData.Coins
    PlayerData.Level  = data.Level  or PlayerData.Level
    PlayerData.XP     = data.XP     or PlayerData.XP
    PlayerData.Needed = data.Needed or PlayerData.Needed
    PlayerData.LastSync = tick()
    return true
end

-- ══════════════════════════════════════════
-- STOP ALL
-- ══════════════════════════════════════════
local function stopSemua()
    _G.AutoFarm = false; _G.AutoBeli  = false
    _G.AutoJual = false; _G.AutoTanam = false
    _G.AutoRain = false
    if BeliLoop then
        pcall(function() task.cancel(BeliLoop) end)
        BeliLoop = nil
    end
    notif("⛔ STOP SEMUA", "Semua auto dimatikan", 3)
end

-- ══════════════════════════════════════════
-- INTERCEPT SERVER→CLIENT EVENTS
-- Semua event ini dikirim server ke client
-- ══════════════════════════════════════════
local function setupIntercepts()

    -- ┌──────────────────────────────────────┐
    -- │ ⚡ LightningStrike — PENANGKAL PETIR  │
    -- │ Data: {Reason="EXPOSED",Hit,Position} │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r
        for i = 1, 15 do r = getRemote("LightningStrike"); if r then break end; task.wait(1) end
        if not r then print("[XKID] LightningStrike tidak ditemukan"); return end

        r.OnClientEvent:Connect(function(data)
            print("[XKID⚡] LightningStrike! Reason="..tostring(data and data.Reason))
            if not _G.PenangkalPetir then return end

            lightningHits = lightningHits + 1
            local root = getRoot()
            if not root then return end

            if SafePos then
                -- TP ke safe pos sebelum damage dihitung
                root.CFrame = CFrame.new(SafePos.X, SafePos.Y + 5, SafePos.Z)
                notif("⚡ PETIR DITANGKAL ✅", "Safe! #"..lightningHits, 3)
            else
                -- Fallback: loncat ke atas
                root.CFrame = root.CFrame + Vector3.new(0, 80, 0)
                notif("⚡ PETIR!", "Set Safe Pos dulu!", 3)
            end
        end)
        print("[XKID] ✅ LightningStrike intercept aktif")
    end)

    -- ┌──────────────────────────────────────┐
    -- │ 📈 UpdateLevel — track level up       │
    -- │ {Level, XP, Needed, TotalXP, LeveledUp}│
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r
        for i = 1, 15 do r = getRemote("UpdateLevel"); if r then break end; task.wait(1) end
        if not r then return end

        r.OnClientEvent:Connect(function(data)
            if type(data) ~= "table" then return end
            PlayerData.Level  = data.Level  or PlayerData.Level
            PlayerData.XP     = data.XP     or PlayerData.XP
            PlayerData.Needed = data.Needed or PlayerData.Needed
            print(string.format("[XKID📈] Lv.%d | XP %d/%d | TotalXP %d",
                data.Level or 0, data.XP or 0, data.Needed or 0, data.TotalXP or 0))

            if data.LeveledUp and _G.NotifLevelUp then
                levelUpCount = levelUpCount + 1
                notif("🎉 LEVEL UP! #"..levelUpCount,
                    "Level "..data.Level.." 🔥\nXP: "..data.XP.."/"..data.Needed, 6)
            end
        end)
        print("[XKID] ✅ UpdateLevel intercept aktif")
    end)

    -- ┌──────────────────────────────────────┐
    -- │ 🔔 Notification — log notif server   │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r
        for i = 1, 15 do r = getRemote("Notification"); if r then break end; task.wait(1) end
        if not r then return end

        r.OnClientEvent:Connect(function(msg)
            print("[XKID🔔] "..tostring(msg))
            -- Deteksi hujan dari notif
            if type(msg) == "string" then
                if msg:lower():find("hujan mulai") then
                    notif("🌧 Hujan!", "Tanaman tumbuh 1.5x lebih cepat!", 5)
                elseif msg:lower():find("petir") or msg:lower():find("gosong") then
                    notif("⚡ PETIR!", msg, 4)
                end
            end
        end)
        print("[XKID] ✅ Notification intercept aktif")
    end)

    -- ┌──────────────────────────────────────┐
    -- │ 🌾 HarvestCrop — log hasil panen     │
    -- │ ("Padi", 1, "Padi") — sound only     │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r
        for i = 1, 15 do r = getRemote("HarvestCrop"); if r then break end; task.wait(1) end
        if not r then return end

        r.OnClientEvent:Connect(function(cropName, qty, cropName2)
            print(string.format("[XKID🌾] Panen: %s x%d", tostring(cropName), tonumber(qty) or 1))
        end)
        print("[XKID] ✅ HarvestCrop intercept aktif")
    end)

    -- ┌──────────────────────────────────────┐
    -- │ 🌧 RainSync — deteksi hujan          │
    -- │ (false, 5) = hujan berhenti          │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r
        for i = 1, 15 do r = getRemote("RainSync"); if r then break end; task.wait(1) end
        if not r then return end

        r.OnClientEvent:Connect(function(isRaining, duration)
            print(string.format("[XKID🌧] RainSync: raining=%s duration=%s",
                tostring(isRaining), tostring(duration)))
        end)
        print("[XKID] ✅ RainSync intercept aktif")
    end)

    -- ┌──────────────────────────────────────┐
    -- │ ✅ ConfirmAction — auto confirm       │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r
        for i = 1, 15 do r = getRemote("ConfirmAction"); if r then break end; task.wait(1) end
        if not r or not r:IsA("RemoteFunction") then return end

        r.OnClientInvoke = function(data)
            if _G.AutoConfirm then
                notif("✅ Auto Confirm", tostring(data), 2)
                return true
            end
            return nil
        end
        print("[XKID] ✅ ConfirmAction intercept aktif")
    end)

    print("[XKID] === SEMUA INTERCEPT SIAP ===")
end

-- ══════════════════════════════════════════
-- TABS
-- ══════════════════════════════════════════
local TabStatus = Window:CreateTab("📊 Status",      nil)
local TabFarm   = Window:CreateTab("🤖 Auto Farm",   nil)
local TabBibit  = Window:CreateTab("🛒 Beli Bibit",  nil)
local TabJual   = Window:CreateTab("💰 Jual",        nil)
local TabTanam  = Window:CreateTab("🌱 Tanam",       nil)
local TabLahan  = Window:CreateTab("🌾 Lahan",       nil)
local TabHujan  = Window:CreateTab("🌧 Hujan",       nil)
local TabPetir  = Window:CreateTab("⚡ Petir",       nil)
local TabSet    = Window:CreateTab("⚙ Setting",     nil)
local TabTest   = Window:CreateTab("🧪 Test Remote", nil)

-- ══════════════════════════════════════════
-- TAB STATUS
-- ══════════════════════════════════════════
TabStatus:CreateSection("📊 Live Monitor")

local St = {
    farm   = TabStatus:CreateParagraph({Title="🤖 Auto Farm",  Content="🔴 OFF"}),
    beli   = TabStatus:CreateParagraph({Title="🛒 Auto Beli",  Content="🔴 OFF"}),
    jual   = TabStatus:CreateParagraph({Title="💰 Auto Jual",  Content="🔴 OFF"}),
    player = TabStatus:CreateParagraph({Title="👤 Player",     Content="..."}),
    lahan  = TabStatus:CreateParagraph({Title="🌾 Lahan",      Content="Belum scan"}),
    petir  = TabStatus:CreateParagraph({Title="⚡ Petir",      Content="🔴 OFF"}),
    siklus = TabStatus:CreateParagraph({Title="🔄 Siklus",     Content="0"}),
}

task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            St.farm:Set({Title="🤖 Auto Farm",
                Content=_G.AutoFarm and ("🟢 RUNNING — Siklus "..SiklusCount) or "🔴 OFF"})
            St.beli:Set({Title="🛒 Auto Beli",
                Content=_G.AutoBeli and ("🟢 "..selectedBibit.." x"..jumlahBeli) or "🔴 OFF"})
            St.jual:Set({Title="💰 Auto Jual",
                Content=_G.AutoJual and "🟢 RUNNING" or "🔴 OFF"})
            St.player:Set({Title="👤 "..LocalPlayer.Name,
                Content="💰 "..PlayerData.Coins
                    .."  ⭐ Lv."..PlayerData.Level
                    .."  📊 "..PlayerData.XP.."/"..PlayerData.Needed
                    .."\n🎉 Level up: "..levelUpCount.."x"})
            St.lahan:Set({Title="🌾 Lahan Cache",
                Content=#LahanCache.." plot"
                    ..(LahanCacheTime > 0 and (" | scan "..string.format("%.0fs",tick()-LahanCacheTime).." ago") or "")})
            St.petir:Set({Title="⚡ Penangkal Petir",
                Content=(_G.PenangkalPetir and "🟢 AKTIF" or "🔴 OFF")
                    .." | "..lightningHits.."x ditangkal"
                    ..(SafePos and " | ✅ Safe Pos" or " | ❌ Belum set")})
            St.siklus:Set({Title="🔄 Siklus Farm", Content=SiklusCount.." siklus"})
        end)
        task.wait(1)
    end
end)

-- ══════════════════════════════════════════
-- TAB AUTO FARM
-- ══════════════════════════════════════════
TabFarm:CreateSection("🤖 Full Auto Farm")

TabFarm:CreateParagraph({Title="Flow Auto Farm",
    Content="1️⃣  Beli bibit   → RequestShop(nama, qty)\n"
         .."2️⃣  Tanam lahan  → PlantCrop(Vector3) per plot\n"
         .."3️⃣  Tunggu panen → X detik\n"
         .."4️⃣  Jual semua   → RequestSell()\n"
         .."↩️  Ulangi dari awal\n\n"
         .."⚠️ Scan Lahan dulu di tab 🌾 Lahan!"})

TabFarm:CreateSection("⏱ Delay")
TabFarm:CreateSlider({Name="Delay antar Tanam (s)", Range={0.1,3}, Increment=0.1, CurrentValue=0.5,
    Callback=function(v) dTanam=v end})
TabFarm:CreateSlider({Name="Tunggu Panen (s)", Range={10,300}, Increment=5, CurrentValue=60,
    Callback=function(v) waitPanen=v end})

TabFarm:CreateSection("🔥 START / STOP")

TabFarm:CreateToggle({Name="🔥 FULL AUTO FARM", CurrentValue=false,
    Callback=function(v)
        _G.AutoFarm = v
        if not v then notif("AUTO FARM OFF","",2); return end

        -- Validasi lahan
        if #LahanCache == 0 then
            scanLahan()
            if #LahanCache == 0 then
                notif("⚠️ Lahan 0!","Tab 🌾 Lahan → Scan dulu!",6)
                _G.AutoFarm = false; return
            end
        end

        SiklusCount = 0
        notif("AUTO FARM ON 🔥", #LahanCache.." lahan | Bibit: "..selectedBibit, 4)

        task.spawn(function()
            while _G.AutoFarm do
                SiklusCount = SiklusCount + 1

                -- STEP 1: Beli bibit
                notif("Siklus #"..SiklusCount, "Beli "..selectedBibit.."...", 2)
                local ok, msg = beliBibit(selectedBibit, jumlahBeli)
                if ok then
                    notif("Beli ✅", msg, 2)
                else
                    notif("Beli ❌", msg, 2)
                end
                if not _G.AutoFarm then break end
                task.wait(1)

                -- STEP 2: Tanam
                notif("Siklus #"..SiklusCount, "Tanam "..#LahanCache.." plot...", 2)
                _G.AutoTanam = true
                local planted = 0
                for _, pos in ipairs(LahanCache) do
                    if not _G.AutoFarm then break end
                    local ok2 = fireEv("PlantCrop", pos)
                    if ok2 then planted = planted + 1 end
                    task.wait(dTanam)
                end
                _G.AutoTanam = false
                notif("Tanam ✅", planted.."/"..#LahanCache.." plot", 2)
                if not _G.AutoFarm then break end

                -- STEP 3: Tunggu panen
                notif("Siklus #"..SiklusCount, "Tunggu "..waitPanen.."s...", 3)
                local w = 0
                while w < waitPanen and _G.AutoFarm do
                    task.wait(1); w = w + 1
                end
                if not _G.AutoFarm then break end

                -- STEP 4: Jual
                notif("Siklus #"..SiklusCount, "Jual semua...", 2)
                local ok3, msg3 = jualSemua()
                notif(ok3 and "Jual ✅" or "Jual ❌",
                    ok3 and (msg3.."\n💰 "..PlayerData.Coins) or msg3, 3)

                if not _G.AutoFarm then break end
                task.wait(2)
            end
            notif("AUTO FARM STOP","Total: "..SiklusCount.." siklus",3)
        end)
    end})

TabFarm:CreateSection("🎯 Auto Satuan")

TabFarm:CreateToggle({Name="🛒 Auto Beli Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoBeli = v
        if v then
            BeliLoop = task.spawn(function()
                while _G.AutoBeli do
                    local ok, msg = beliBibit(selectedBibit, jumlahBeli)
                    notif(ok and "Beli ✅" or "Beli ❌",
                        ok and msg or (msg.." | "..selectedBibit), 2)
                    task.wait(10)
                end
            end)
            notif("Auto Beli ON ✅", selectedBibit.." x"..jumlahBeli, 3)
        else
            if BeliLoop then pcall(function() task.cancel(BeliLoop) end); BeliLoop=nil end
            notif("Auto Beli OFF","",2)
        end
    end})

TabFarm:CreateToggle({Name="🌱 Auto Tanam Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoTanam = v
        if v then
            task.spawn(function()
                while _G.AutoTanam do
                    if #LahanCache == 0 then scanLahan() end
                    local count = 0
                    for _, pos in ipairs(LahanCache) do
                        if not _G.AutoTanam then break end
                        local ok = fireEv("PlantCrop", pos)
                        if ok then count=count+1 end
                        task.wait(dTanam)
                    end
                    notif("Tanam ✅", count.." plot", 2)
                    task.wait(5)
                end
            end)
            notif("Auto Tanam ON ✅", #LahanCache.." plot", 3)
        else notif("Auto Tanam OFF","",2) end
    end})

TabFarm:CreateToggle({Name="💰 Auto Jual Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoJual = v
        if v then
            task.spawn(function()
                while _G.AutoJual do
                    local ok, msg = jualSemua()
                    notif(ok and "Jual ✅" or "Jual ❌", msg, 2)
                    task.wait(15)
                end
            end)
            notif("Auto Jual ON ✅","",3)
        else notif("Auto Jual OFF","",2) end
    end})

TabFarm:CreateSection("🛑 Emergency")
TabFarm:CreateButton({Name="🛑 STOP SEMUA", Callback=function() stopSemua() end})

-- ══════════════════════════════════════════
-- TAB BELI BIBIT
-- ══════════════════════════════════════════
TabBibit:CreateSection("🌱 Pilih Bibit")

TabBibit:CreateParagraph({Title="Cara Kerja",
    Content="RequestShop:InvokeServer(nama, qty)\n"
        .."Return: {Success, Message, NewCoins}\n\n"
        .."Contoh: 'Membeli 1x Bibit Jagung! -15 Coins'"})

local opsiB = {}
for _, b in ipairs(BIBIT_LIST) do
    table.insert(opsiB, b.icon.." "..b.name.." | Lv."..b.minLv.." | "..b.price.."💰")
end

TabBibit:CreateDropdown({Name="Pilih Bibit", Options=opsiB, CurrentOption={opsiB[1]},
    Callback=function(v)
        for _, b in ipairs(BIBIT_LIST) do
            if v[1]:find(b.name, 1, true) then
                selectedBibit = b.name
                notif("Dipilih", b.icon.." "..b.name, 2); break
            end
        end
    end})

TabBibit:CreateSlider({Name="Jumlah Beli", Range={1,99}, Increment=1, CurrentValue=1,
    Callback=function(v) jumlahBeli=v end})

TabBibit:CreateButton({Name="🛒 BELI SEKARANG",
    Callback=function()
        task.spawn(function()
            local ok, msg = beliBibit(selectedBibit, jumlahBeli)
            notif(ok and "Beli ✅" or "Beli ❌", msg, 3)
        end)
    end})

TabBibit:CreateSection("⚡ Beli Cepat")
for _, b in ipairs(BIBIT_LIST) do
    local bb = b
    TabBibit:CreateButton({Name=bb.icon.." "..bb.name.." | "..bb.price.."💰",
        Callback=function()
            task.spawn(function()
                selectedBibit = bb.name
                local ok, msg = beliBibit(bb.name, jumlahBeli)
                notif(ok and "✅ "..bb.name or "❌ Gagal", msg, 3)
            end)
        end})
end

-- ══════════════════════════════════════════
-- TAB JUAL
-- ══════════════════════════════════════════
TabJual:CreateSection("💰 Jual Hasil Panen")

TabJual:CreateParagraph({Title="Cara Kerja",
    Content="RequestSell:InvokeServer() — tanpa args!\n"
        .."Server jual SEMUA inventori otomatis\n\n"
        .."Return: {Success, Message, NewCoins}\n"
        .."Contoh: 'Menjual 8x Padi! +80 Coins'"})

TabJual:CreateButton({Name="💰 JUAL SEMUA SEKARANG",
    Callback=function()
        task.spawn(function()
            local ok, msg = jualSemua()
            notif(ok and "Jual ✅" or "Jual ❌",
                ok and (msg.."\n💰 Total: "..PlayerData.Coins) or msg, 4)
        end)
    end})

-- ══════════════════════════════════════════
-- TAB TANAM
-- ══════════════════════════════════════════
TabTanam:CreateSection("🌱 Tanam Manual")

TabTanam:CreateParagraph({Title="Cara Kerja",
    Content="PlantCrop:FireServer(Vector3)\n"
        .."Arg: posisi lahan (Vector3)\n"
        .."Server tau sendiri bibit apa yg dipunya!\n\n"
        .."Scan lahan dulu di tab 🌾 Lahan"})

TabTanam:CreateButton({Name="🌱 TANAM SEMUA LAHAN",
    Callback=function()
        task.spawn(function()
            if #LahanCache == 0 then
                scanLahan()
                if #LahanCache == 0 then
                    notif("❌","Scan lahan dulu! Tab 🌾 Lahan",4); return
                end
            end
            notif("Tanam...", #LahanCache.." lahan...", 2)
            local count = 0
            for _, pos in ipairs(LahanCache) do
                local ok = fireEv("PlantCrop", pos)
                if ok then count=count+1 end
                task.wait(dTanam)
            end
            notif("Tanam ✅", count.."/"..#LahanCache.." plot berhasil", 3)
        end)
    end})

TabTanam:CreateButton({Name="📍 PlantCrop di Posisi Saya",
    Callback=function()
        local pos = getPos()
        if not pos then notif("❌","Posisi tidak valid",3); return end
        task.spawn(function()
            local ok, err = fireEv("PlantCrop", pos)
            notif(ok and "Tanam ✅" or "Tanam ❌",
                ok and string.format("X=%.1f Z=%.1f",pos.X,pos.Z) or tostring(err), 3)
        end)
    end})

-- ══════════════════════════════════════════
-- TAB LAHAN
-- ══════════════════════════════════════════
TabLahan:CreateSection("🌾 Scan Lahan")

TabLahan:CreateParagraph({Title="Info",
    Content="Scan semua BasePart 'AreaTanam*'\nSimpan posisi → dipakai di PlantCrop\n\n"
        .."Scan otomatis saat load,\ntapi bisa manual juga."})

local LahanPara = TabLahan:CreateParagraph({Title="Status", Content="Belum scan"})

TabLahan:CreateButton({Name="🔍 SCAN LAHAN",
    Callback=function()
        LahanCacheTime = 0
        local lahans = scanLahan()
        LahanPara:Set({Title="Status",
            Content=#lahans.." plot ditemukan\n"..(#lahans>0 and "✅ Siap!" or "❌ Tidak ada")})
        notif("Scan ✅", #lahans.." plot ditemukan", 3)
    end})

TabLahan:CreateButton({Name="📊 Lihat Posisi",
    Callback=function()
        if #LahanCache == 0 then notif("❌","Scan dulu!",3); return end
        local txt = #LahanCache.." plot:\n"
        for i, pos in ipairs(LahanCache) do
            if i > 8 then txt=txt.."... dan "..(#LahanCache-8).." lainnya"; break end
            txt = txt..string.format("#%d X=%.0f Z=%.0f\n", i, pos.X, pos.Z)
        end
        notif("Posisi Lahan", txt, 8)
    end})

TabLahan:CreateButton({Name="🗑 Reset Cache",
    Callback=function()
        LahanCache={}; LahanCacheTime=0
        notif("Reset ✅","",2)
    end})

TabLahan:CreateSection("🏞 Beli Lahan")

TabLahan:CreateParagraph({Title="LahanUpdate Remote",
    Content="FireServer('CONFIRM_BUY', {PartName, Price})\n"
        .."Aktifkan Auto Confirm di Tab ⚙ Setting"})

TabLahan:CreateToggle({Name="✅ Auto Confirm (beli lahan dll)", CurrentValue=false,
    Callback=function(v)
        _G.AutoConfirm = v
        notif("Auto Confirm", v and "ON ✅" or "OFF", 2)
    end})

local LAHAN_LIST = {
    {partName="AreaTanam Besar2", price=100000, label="Besar 2"},
    {partName="AreaTanam Besar3", price=200000, label="Besar 3"},
    {partName="AreaTanam Sawit1", price=150000, label="Sawit 1"},
    {partName="AreaTanam Sawit2", price=300000, label="Sawit 2"},
}

for _, l in ipairs(LAHAN_LIST) do
    local ll = l
    TabLahan:CreateButton({Name="🏞 Beli "..ll.label.." | "..ll.price.."💰",
        Callback=function()
            task.spawn(function()
                local ok, err = fireEv("LahanUpdate", "CONFIRM_BUY",
                    {["PartName"]=ll.partName, ["Price"]=ll.price})
                notif(ok and "Beli Lahan ✅" or "Gagal ❌",
                    ok and ll.label or tostring(err), 4)
            end)
        end})
end

-- ══════════════════════════════════════════
-- TAB HUJAN
-- ══════════════════════════════════════════
TabHujan:CreateSection("🌧 Summon Rain")

TabHujan:CreateParagraph({Title="Kegunaan",
    Content="GrowthSpeedMultiplier = 1.5x saat hujan\n"
        .."Tanaman tumbuh 50% LEBIH CEPAT!\n\n"
        .."Server kirim Notification:\n"
        .."→ 'Hujan mulai turun!'\n"
        .."→ 'Hujan berhenti.'\n\n"
        .."Remote: SummonRain:FireServer()"})

TabHujan:CreateButton({Name="🌧 SUMMON RAIN SEKARANG",
    Callback=function()
        task.spawn(function()
            local ok, err = summonRain()
            notif(ok and "🌧 Hujan! ✅" or "Gagal ❌",
                ok and "1.5x growth aktif! 🔥" or tostring(err), 4)
        end)
    end})

TabHujan:CreateSlider({Name="Auto Rain Interval (s)", Range={30,600}, Increment=30, CurrentValue=150,
    Callback=function(v) rainInterval=v end})

TabHujan:CreateToggle({Name="🌧 Auto Rain Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoRain = v
        if v then
            task.spawn(function()
                while _G.AutoRain do
                    local ok = pcall(summonRain)
                    if ok then notif("🌧 Rain!", "1.5x growth!", 3) end
                    task.wait(rainInterval)
                end
            end)
            notif("Auto Rain ON ✅", "Interval "..rainInterval.."s", 3)
        else
            notif("Auto Rain OFF","",2)
        end
    end})

-- ══════════════════════════════════════════
-- TAB PETIR
-- ══════════════════════════════════════════
TabPetir:CreateSection("⚡ Penangkal Petir")

TabPetir:CreateParagraph({Title="Cara Kerja (dari Cobalt spy)",
    Content="Server kirim:\n"
        .."LightningStrike.OnClientEvent(\n"
        .."  {Reason='EXPOSED', Hit=true, Position=V3}\n"
        ..")\n\n"
        .."Script intercept event ini →\nTP ke Safe Pos sebelum damage!\n\n"
        .."⚠️ Set Safe Pos di dalam bangunan/atap"})

TabPetir:CreateButton({Name="📍 SET SAFE POSITION",
    Callback=function()
        local p = getPos()
        if p then
            SafePos = p
            notif("Safe Pos ✅", string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z), 4)
        end
    end})

TabPetir:CreateButton({Name="📊 Cek Safe Pos",
    Callback=function()
        if SafePos then
            notif("Safe Pos", string.format("X=%.1f\nY=%.1f\nZ=%.1f",SafePos.X,SafePos.Y,SafePos.Z), 4)
        else
            notif("Safe Pos ❌", "Belum diset!", 3)
        end
    end})

TabPetir:CreateToggle({Name="⚡ Penangkal Petir AKTIF", CurrentValue=false,
    Callback=function(v)
        _G.PenangkalPetir = v
        if v and not SafePos then
            notif("⚠️ Warning!", "Safe Pos belum diset!\nWill jump up as fallback", 4)
        end
        notif("Penangkal Petir", v and "ON ✅" or "OFF", 2)
    end})

TabPetir:CreateButton({Name="🗑 Reset Counter",
    Callback=function() lightningHits=0; notif("Reset ✅","",2) end})

-- ══════════════════════════════════════════
-- TAB SETTING
-- ══════════════════════════════════════════
TabSet:CreateSection("⚙ Setting")

TabSet:CreateSlider({Name="Delay PlantCrop (s)", Range={0.1,3}, Increment=0.1, CurrentValue=0.5,
    Callback=function(v) dTanam=v end})
TabSet:CreateSlider({Name="Tunggu Panen (s)", Range={10,300}, Increment=5, CurrentValue=60,
    Callback=function(v) waitPanen=v end})
TabSet:CreateSlider({Name="Auto Rain Interval (s)", Range={30,600}, Increment=30, CurrentValue=150,
    Callback=function(v) rainInterval=v end})

TabSet:CreateSection("📍 Info")
TabSet:CreateButton({Name="📍 Koordinat Saya",
    Callback=function()
        local p = getPos()
        if p then notif("Posisi",string.format("X=%.2f\nY=%.2f\nZ=%.2f",p.X,p.Y,p.Z),5) end
    end})

TabSet:CreateSection("🔄 Sync")
TabSet:CreateButton({Name="🔄 Sync Data Player (SyncData)",
    Callback=function()
        task.spawn(function()
            local ok = syncData()
            notif(ok and "Sync ✅" or "Sync ❌",
                ok and ("Lv."..PlayerData.Level.." | "..PlayerData.Coins.." Coins") or "Gagal", 3)
        end)
    end})

TabSet:CreateToggle({Name="🎉 Notif Level Up", CurrentValue=true,
    Callback=function(v) _G.NotifLevelUp=v end})

TabSet:CreateSection("🛑 Emergency")
TabSet:CreateButton({Name="🛑 STOP SEMUA AUTO", Callback=function() stopSemua() end})

-- ══════════════════════════════════════════
-- TAB TEST REMOTE
-- ══════════════════════════════════════════
TabTest:CreateSection("🧪 Quick Test")

TabTest:CreateParagraph({Title="Remote Dikonfirmasi",
    Content="CLIENT → SERVER:\n"
        .."PlantCrop, RequestSell, RequestShop\n"
        .."RequestToolShop, SummonRain, SyncData\n\n"
        .."SERVER → CLIENT (intercept):\n"
        .."LightningStrike, UpdateLevel\n"
        .."Notification, HarvestCrop, RainSync"})

local quickList = {
    {"RequestSell",     "RF", "💰 RequestSell → jual semua"},
    {"RequestShop",     "RF", "🛒 RequestShop → data bibit"},
    {"RequestToolShop", "RF", "🔧 RequestToolShop → tools"},
    {"SyncData",        "RF", "👤 SyncData → data player"},
    {"SummonRain",      "EV", "🌧 SummonRain → panggil hujan"},
    {"SkipTutorial",    "EV", "📖 SkipTutorial"},
    {"RefreshShop",     "EV", "🔄 RefreshShop"},
}

for _, qt in ipairs(quickList) do
    local q = qt
    TabTest:CreateButton({Name=q[3],
        Callback=function()
            task.spawn(function()
                if q[2] == "RF" then
                    local ok, res = invokeRF(q[1])
                    notif(q[1], ok and "OK → cek console" or "❌ "..tostring(res), 4)
                    if ok and type(res)=="table" then
                        local d = unwrap(res) or res
                        for k,v in pairs(d) do
                            print(string.format("[XKID %s] %s = %s", q[1], tostring(k), tostring(v)))
                        end
                    end
                else
                    local ok, err = fireEv(q[1])
                    notif(q[1], ok and "Fired ✅" or "❌ "..tostring(err), 3)
                end
            end)
        end})
end

TabTest:CreateSection("🔥 Fire Manual")

local tName, tArg = "", ""
TabTest:CreateInput({Name="Nama Remote", PlaceholderText="RequestSell / PlantCrop / ...",
    RemoveTextAfterFocusLost=false, Callback=function(v) tName=v end})
TabTest:CreateInput({Name="Arg 1 (opsional)", PlaceholderText="string / number / bool",
    RemoveTextAfterFocusLost=false, Callback=function(v) tArg=v end})
TabTest:CreateButton({Name="🔥 FIRE / INVOKE",
    Callback=function()
        if tName=="" then notif("❌","Masukkan nama remote!",3); return end
        task.spawn(function()
            local args = {}
            if tArg ~= "" then
                local n = tonumber(tArg)
                if     n            then table.insert(args, n)
                elseif tArg=="true" then table.insert(args, true)
                elseif tArg=="false"then table.insert(args, false)
                else                     table.insert(args, tArg) end
            end
            local r = getRemote(tName)
            if not r then notif("❌","'"..tName.."' tidak ditemukan",3); return end
            if r:IsA("RemoteFunction") then
                local ok, res = invokeRF(tName, table.unpack(args))
                notif(ok and "Invoke ✅" or "❌", tostring(res), 5)
            else
                local ok, err = fireEv(tName, table.unpack(args))
                notif(ok and "Fire ✅" or "❌", ok and "OK" or tostring(err), 3)
            end
        end)
    end})

-- ══════════════════════════════════════════
-- INIT
-- ══════════════════════════════════════════
setupIntercepts()

task.spawn(function()
    task.wait(3)
    -- Auto scan lahan
    scanLahan()
    if #LahanCache > 0 then
        notif("Scan ✅", #LahanCache.." lahan ditemukan!", 4)
    end
    -- Auto sync data
    syncData()
end)

notif("🌾 SAWAH INDO v10.0","Welcome "..LocalPlayer.Name.."! 🔥", 5)
task.wait(1.2)
notif("📋 Remote Confirmed",
    "Tanam:  PlantCrop(Vector3)\n"
    .."Jual:  RequestSell()\n"
    .."Beli:  RequestShop(nama,qty)\n"
    .."Petir: LightningStrike intercept ✅", 8)

print(string.rep("═",50))
print("  🌾 SAWAH INDO v10.0 — XKID HUB")
print("  Cobalt Spy Edition — All Remotes Confirmed")
print("  Player: "..LocalPlayer.Name)
print(string.rep("═",50))

