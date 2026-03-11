-- ╔═══════════════════════════════════════════════════════╗
-- ║                                                       ║
-- ║      🌾  I N D O   F A R M E R  v14.0  🌾           ║
-- ║      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━          ║
-- ║      XKID HUB  ✦  Cobalt Confirmed Edition           ║
-- ║      Flee⚡  AutoFarm 🌱  AutoSell 💰                ║
-- ╚═══════════════════════════════════════════════════════╝

--[[
  ╭──────────────────────────────────────────────────────╮
  │  REMOTE CONFIRMED  ✦  Cobalt Spy v14                 │
  ├──────────────────────────────────────────────────────┤
  │  RequestShop  → BUY, GET_LIST                        │
  │  RequestSell  → GET_LIST, SELL (nama, qty) ✅        │
  │  PlantCrop    → FireServer(Vector3) ✅               │
  │  HarvestCrop  → OnClientEvent(crop, qty) ✅          │
  ├──────────────────────────────────────────────────────┤
  │  NPC COORDS  (Scan Confirmed)                        │
  │  NPC Penjual       X=-59   Z=-207                    │
  │  NPC Bibit         X=-42   Z=-207                    │
  │  NPC Alat          X=-41   Z=-100                    │
  │  NPC PedagangSawit X= 56   Z=-208                    │
  │  NPCPedagangTelur  X=-98   Z=-176                    │
  │  🚿 Mandi          X= 137  Z=-235                    │
  ╰──────────────────────────────────────────────────────╯
]]

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  RAYFIELD UI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name            = "🌾 INDO FARMER  v14.0",
    LoadingTitle    = "✦ XKID HUB ✦",
    LoadingSubtitle = "Cobalt Confirmed  ·  Flee Edition",
    ConfigurationSaving = { Enabled = false },
    KeySystem       = false,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SERVICES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")
local RunService  = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  FLAGS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
_G.ScriptRunning  = true
_G.AutoFarm       = false
_G.AutoTanam      = false
_G.AutoSell       = false
_G.AutoHarvest    = false
_G.PenangkalPetir = false
_G.AntiAFK        = false
_G.AutoConfirm    = false
_G.NotifLevelUp   = true
_G.AutoMandi      = false

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  STATE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local PlayerData     = { Coins=0, Level=1, XP=0, Needed=50 }
local SiklusCount    = 0
local lightningHits  = 0
local levelUpCount   = 0
local totalEarned    = 0
local harvestCount   = 0
local LahanCache     = {}
local LahanCacheTime = 0
local SellLoop       = nil
local HarvestLoop    = nil
local selectedBibit  = "Bibit Padi"
local jumlahBeli     = 1
local dTanam         = 0.5
local waitPanen      = 60
local harvestInterval= 5
local isPetirFleeing = false  -- flag sedang kabur dari petir

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  NPC COORDS — hardcoded, Y otomatis via raycast
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local NPC_LIST = {
    { id="penjual", label="🛒  NPC Penjual",        x=-59,  z=-207 },
    { id="bibit",   label="🌱  NPC Bibit",           x=-42,  z=-207 },
    { id="alat",    label="🔧  NPC Alat",            x=-41,  z=-100 },
    { id="sawit",   label="🌴  NPC Pedagang Sawit",  x= 56,  z=-208 },
    { id="telur",   label="🥚  NPC Pedagang Telur",  x=-98,  z=-176 },
}
local MANDI = { x=137, z=-235 }

local ITEM_LIST = {
    { name="Padi",       icon="🌾", price=10 },
    { name="Jagung",     icon="🌽", price=20 },
    { name="Tomat",      icon="🍅", price=30 },
    { name="Terong",     icon="🍆", price=50 },
    { name="Strawberry", icon="🍓", price=75 },
}

local BIBIT_LIST = {
    { name="Bibit Padi",       icon="🌾", price=5,    minLv=1   },
    { name="Bibit Jagung",     icon="🌽", price=15,   minLv=20  },
    { name="Bibit Tomat",      icon="🍅", price=25,   minLv=40  },
    { name="Bibit Terong",     icon="🍆", price=40,   minLv=60  },
    { name="Bibit Strawberry", icon="🍓", price=60,   minLv=80  },
    { name="Bibit Sawit",      icon="🌴", price=1000, minLv=80  },
    { name="Bibit Durian",     icon="🍈", price=2000, minLv=120 },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  NOTIF
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function notif(title, body, dur)
    pcall(function()
        Rayfield:Notify({ Title=title, Content=body, Duration=dur or 3, Image=4483362458 })
    end)
    print(string.format("[ XKID ✦ ] %s  |  %s", title, tostring(body)))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  RAYCAST — cari Y tanah yang benar
--  Tembak dari atas (Y+500) ke bawah, ambil hit Y
--  Ini mencegah TP nembus tanah / melayang
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function getGroundY(x, z, startY)
    startY = startY or 500
    local origin    = Vector3.new(x, startY, z)
    local direction = Vector3.new(0, -1000, 0)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    -- exclude karakter sendiri biar tidak nge-hit diri sendiri
    local char = LocalPlayer.Character
    if char then rayParams.FilterDescendantsInstances = {char} end

    local result = Workspace:Raycast(origin, direction, rayParams)
    if result then
        -- +3 supaya karakter berdiri di atas tanah, tidak nyemplung
        return result.Position.Y + 3
    end
    -- fallback Y kalau raycast miss (area kosong/void)
    return 42
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TELEPORT — pakai raycast Y
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function tpXZ(x, z)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local y = getGroundY(x, z)
    root.CFrame = CFrame.new(x, y, z)
    task.wait(0.35)
    return true
end

local function tpVec(vec3)
    -- Untuk Vector3 yang sudah ada Y — tetap raycast ulang X/Z-nya
    return tpXZ(vec3.X, vec3.Z)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  CHARACTER HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getPos()
    local r = getRoot(); return r and r.Position
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  REMOTE HELPER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local remoteCache = {}
local function getR(name)
    if remoteCache[name] then return remoteCache[name] end
    local folder = RS:FindFirstChild("Remotes")
    folder = folder and folder:FindFirstChild("TutorialRemotes")
    if not folder then return nil end
    local r = folder:FindFirstChild(name)
    if r then remoteCache[name] = r end
    return r
end
local function fireEv(name, ...)
    local r = getR(name)
    if not r or not r:IsA("RemoteEvent") then return false, "not found" end
    return pcall(function(...) r:FireServer(...) end, ...)
end
local function invokeRF(name, ...)
    local r = getR(name)
    if not r or not r:IsA("RemoteFunction") then return false, nil end
    local ok, res = pcall(function(...) return r:InvokeServer(...) end, ...)
    return ok, res
end
local function unwrap(res)
    if type(res)=="table" then
        return type(res[1])=="table" and res[1] or res
    end
    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ⚡ PENANGKAL PETIR — FLEE & RETURN  v14
--
--  Cara kerja:
--  1. Saat LightningStrike event masuk:
--     → Simpan posisi saat ini (returnPos)
--     → TP kabur ke titik aman jauh (fleePos)
--     → Tunggu 4 detik (petir selesai)
--     → TP balik ke returnPos
--  2. fleePos = posisi saat ini + offset acak
--     agar server tidak bisa predict
--  3. Jika sedang kabur (isPetirFleeing),
--     event baru diabaikan agar tidak loop
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Titik aman default (dalam bangunan / jauh dari sawah)
-- User bisa set via tombol "Set Titik Aman"
local fleeBase = nil  -- diisi user, atau auto pakai offset

local function fleePetir()
    if isPetirFleeing then return end  -- sudah kabur, abaikan
    isPetirFleeing = true

    local currentPos = getPos()
    if not currentPos then isPetirFleeing=false; return end

    -- Simpan posisi sebelum kabur
    local returnX = currentPos.X
    local returnZ = currentPos.Z

    -- Tentukan titik kabur:
    -- Pakai fleeBase jika sudah diset user
    -- Kalau belum, kabur ke offset +100 dari posisi sekarang
    local fX, fZ
    if fleeBase then
        fX = fleeBase.x
        fZ = fleeBase.z
    else
        -- Kabur ke arah acak sejauh ~80 studs
        local angle = math.random() * math.pi * 2
        fX = currentPos.X + math.cos(angle) * 80
        fZ = currentPos.Z + math.sin(angle) * 80
    end

    -- TP kabur
    tpXZ(fX, fZ)
    notif("⚡  KABUR!",
        string.format("Petir #%d — menjauh!\nKembali dalam 4 detik...", lightningHits), 4)

    -- Tunggu petir selesai
    task.wait(4)

    -- TP balik ke posisi semula
    tpXZ(returnX, returnZ)
    notif("✅  Kembali",
        string.format("Balik ke X=%.0f Z=%.0f", returnX, returnZ), 3)

    task.wait(0.5)
    isPetirFleeing = false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ANTI AFK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local antiAFKConn = nil
local function startAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect() end
    local last = tick()
    antiAFKConn = RunService.Heartbeat:Connect(function()
        if not _G.AntiAFK then antiAFKConn:Disconnect(); antiAFKConn=nil; return end
        if tick()-last >= 120 then
            last=tick()
            local h=getHum(); if h then h.Jump=true end
        end
    end)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SCAN LAHAN
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function scanLahan()
    if tick()-LahanCacheTime < 10 and #LahanCache>0 then return LahanCache end
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

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  BELI BIBIT ✅
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function beliBibit(nama, qty)
    nama = nama or selectedBibit; qty = qty or jumlahBeli
    local ok, res = invokeRF("RequestShop","BUY",nama,qty)
    if not ok then return false,"RequestShop gagal" end
    local data = unwrap(res)
    if data and data.Success then
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        return true, data.Message or "Berhasil"
    end
    return false, (data and data.Message) or "Gagal"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  JUAL ✅ CONFIRMED
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function getInventoryJual()
    local ok, res = invokeRF("RequestSell","GET_LIST")
    if not ok then return nil end
    local data = unwrap(res)
    if data then PlayerData.Coins = data.Coins or PlayerData.Coins end
    return data
end

local function jualItem(nama, qty)
    local ok, res = invokeRF("RequestSell","SELL",nama,qty or 1)
    if not ok then return false,"Remote gagal",0 end
    local data = unwrap(res)
    if data and data.Success then
        local earned = data.Earned or 0
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        totalEarned = totalEarned + earned
        return true, data.Message or "Terjual", earned
    end
    if type(res)=="number" then PlayerData.Coins=res; return true,"Terjual",0 end
    return false, (data and data.Message) or "Gagal", 0
end

local function jualSemua()
    local data = getInventoryJual()
    if not data or not data.Items then return false,"GET_LIST gagal" end
    local totalItem, totalCoin = 0, 0
    for _, item in ipairs(data.Items) do
        if item.Owned and item.Owned > 0 then
            local ok, _, _ = jualItem(item.Name, item.Owned)
            if ok then
                totalItem = totalItem + item.Owned
                totalCoin = totalCoin + (item.Price * item.Owned)
            end
            task.wait(0.3)
        end
    end
    if totalItem == 0 then return false,"Tidak ada item" end
    return true, totalItem.." item  ·  +"..totalCoin.."💰"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  AUTO HARVEST
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function autoHarvestTick()
    local harvested = 0
    local myPos = getPos(); if not myPos then return 0 end
    for _, v in pairs(Workspace:GetDescendants()) do
        local n = v.Name:lower()
        local isCrop = n:find("crop") or n:find("plant") or n:find("padi")
            or n:find("jagung") or n:find("tomat") or n:find("terong")
            or n:find("sawit") or n:find("durian") or n:find("strawberry")
        if isCrop then
            local pp = v:FindFirstChildWhichIsA("ProximityPrompt", true)
            if pp then
                local partPos
                if v:IsA("BasePart") then partPos=v.Position
                elseif v.PrimaryPart then partPos=v.PrimaryPart.Position end
                if partPos and (partPos-myPos).Magnitude < 20 then
                    pcall(function() fireproximityprompt(pp) end)
                    harvested = harvested+1; task.wait(0.1)
                end
            end
        end
    end
    return harvested
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  MANDI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function goMandi()
    tpXZ(MANDI.x, MANDI.z)
    notif("🚿  Mandi", string.format("TP  X=%.0f  Z=%.0f", MANDI.x, MANDI.z), 3)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  STOP ALL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function stopSemua()
    _G.AutoFarm=false; _G.AutoTanam=false
    _G.AutoSell=false; _G.AutoHarvest=false; _G.AutoMandi=false
    if SellLoop    then pcall(function() task.cancel(SellLoop)    end); SellLoop=nil    end
    if HarvestLoop then pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil end
    notif("⛔  STOP ALL","Semua fitur dimatikan",3)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  INTERCEPTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function setupIntercepts()

    -- ⚡ LIGHTNING STRIKE — Flee & Return
    task.spawn(function()
        local r
        for i=1,20 do r=getR("LightningStrike"); if r then break end; task.wait(1) end
        if not r then
            print("[ XKID ⚠️ ] LightningStrike remote tidak ditemukan")
            return
        end
        r.OnClientEvent:Connect(function(data)
            lightningHits = lightningHits + 1
            print(string.format("[ XKID ⚡ ] Petir #%d | Reason=%s",
                lightningHits, tostring(data and data.Reason)))
            if not _G.PenangkalPetir then return end
            -- Spawn biar tidak block thread lain
            task.spawn(fleePetir)
        end)
        print("[ XKID ✦ ] ⚡ LightningStrike intercept ready")
    end)

    -- 📊 LEVEL UP
    task.spawn(function()
        local r
        for i=1,15 do r=getR("UpdateLevel"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
            if type(data)~="table" then return end
            PlayerData.Level  = data.Level  or PlayerData.Level
            PlayerData.XP     = data.XP     or PlayerData.XP
            PlayerData.Needed = data.Needed or PlayerData.Needed
            if data.LeveledUp and _G.NotifLevelUp then
                levelUpCount=levelUpCount+1
                notif("🎉  Level Up!  #"..levelUpCount,
                    "Level "..data.Level.."  ·  XP "..data.XP.."/"..data.Needed, 6)
            end
        end)
    end)

    -- 🔔 NOTIFICATION
    task.spawn(function()
        local r
        for i=1,15 do r=getR("Notification"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(msg)
            if type(msg)~="string" then return end
            local ml = msg:lower()
            if ml:find("hujan") then
                notif("🌧  Hujan!","Tanaman tumbuh lebih cepat",4)
            elseif ml:find("petir") or ml:find("gosong") then
                notif("⚡  Petir!",msg,4)
            elseif ml:find("mandi") or ml:find("segar") or ml:find("kotor") then
                notif("🚿  Perlu Mandi!",msg,4)
                if _G.AutoMandi then task.delay(0.5, goMandi) end
            end
        end)
    end)

    -- 🌾 HARVEST COUNT
    task.spawn(function()
        local r
        for i=1,15 do r=getR("HarvestCrop"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(cropName, qty)
            harvestCount = harvestCount+(tonumber(qty) or 1)
            print(string.format("[ XKID 🌾 ] Panen: %s x%d  ·  Total: %d",
                tostring(cropName), tonumber(qty) or 1, harvestCount))
        end)
    end)

    -- 💰 SELL CROP (GUI open intercept)
    task.spawn(function()
        local r
        for i=1,15 do r=getR("SellCrop"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(_, p41)
            if _G.AutoSell and type(p41)=="string" and p41:find("OPEN") then
                task.delay(0.6, function()
                    local ok,msg=jualSemua()
                    notif(ok and "💰  Auto Sell ✅" or "❌  Sell", msg, 3)
                end)
            end
        end)
    end)

    -- ✅ CONFIRM
    task.spawn(function()
        local r
        for i=1,15 do r=getR("ConfirmAction"); if r then break end; task.wait(1) end
        if not r or not r:IsA("RemoteFunction") then return end
        r.OnClientInvoke = function(data)
            if _G.AutoConfirm then notif("✅  Auto Confirm",tostring(data),2); return true end
            return nil
        end
    end)

    print("[ XKID ✦ ] ══ ALL INTERCEPTS READY ══")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TABS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local TabStatus  = Window:CreateTab("📊  Status",     nil)
local TabFarm    = Window:CreateTab("🤖  Auto Farm",  nil)
local TabBibit   = Window:CreateTab("🛒  Bibit",      nil)
local TabJual    = Window:CreateTab("💰  Jual",       nil)
local TabHarvest = Window:CreateTab("🌾  Harvest",    nil)
local TabTP      = Window:CreateTab("📍  Teleport",   nil)
local TabPetir   = Window:CreateTab("⚡  Petir",      nil)
local TabSet     = Window:CreateTab("⚙  Setting",   nil)
local TabTest    = Window:CreateTab("🧪  Debug",      nil)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB STATUS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabStatus:CreateSection("✦  Live Monitor")
local St = {
    farm    = TabStatus:CreateParagraph({Title="🤖  Auto Farm",     Content="○  Offline"}),
    harvest = TabStatus:CreateParagraph({Title="🌾  Auto Harvest",  Content="○  Offline"}),
    sell    = TabStatus:CreateParagraph({Title="💰  Auto Sell",     Content="○  Offline"}),
    petir   = TabStatus:CreateParagraph({Title="⚡  Penangkal Petir",Content="○  Offline"}),
    player  = TabStatus:CreateParagraph({Title="👤  Player",        Content="..."}),
    lahan   = TabStatus:CreateParagraph({Title="🗺  Lahan",         Content="Belum scan"}),
    afk     = TabStatus:CreateParagraph({Title="🛡  Anti AFK",      Content="○  Offline"}),
    stats   = TabStatus:CreateParagraph({Title="💸  Session",       Content="—"}),
}

task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            St.farm:Set({Title="🤖  Auto Farm",
                Content=_G.AutoFarm and ("●  Running  ·  Siklus "..SiklusCount) or "○  Offline"})
            St.harvest:Set({Title="🌾  Auto Harvest",
                Content=_G.AutoHarvest and ("●  Active  ·  "..harvestCount.."×") or ("○  Offline  ·  Total "..harvestCount.."×")})
            St.sell:Set({Title="💰  Auto Sell",
                Content=_G.AutoSell and "●  Active" or "○  Offline"})
            St.petir:Set({Title="⚡  Penangkal Petir",
                Content=(_G.PenangkalPetir and "●  ACTIVE" or "○  Offline")
                    .."  ·  "..lightningHits.."× tangkal"
                    ..(isPetirFleeing and "  ·  🏃 Kabur!" or "")
                    ..(fleeBase and "  ·  ✅ Titik aman set" or "  ·  ⚠️ Auto flee")})
            St.player:Set({Title="👤  "..LocalPlayer.Name,
                Content="💰 "..PlayerData.Coins
                    .."   ⭐ Lv."..PlayerData.Level
                    .."   📊 "..PlayerData.XP.."/"..PlayerData.Needed
                    .."\n🎉 Level Up: "..levelUpCount.."×"})
            St.lahan:Set({Title="🗺  Lahan",
                Content=#LahanCache.." plot"
                    ..(LahanCacheTime>0 and ("  ·  "..string.format("%.0f",tick()-LahanCacheTime).."s ago") or "")})
            St.afk:Set({Title="🛡  Anti AFK", Content=_G.AntiAFK and "●  Active" or "○  Offline"})
            St.stats:Set({Title="💸  Session Stats",
                Content="Earned: "..totalEarned.."💰  ·  Panen: "..harvestCount.."×  ·  Siklus: "..SiklusCount})
        end)
        task.wait(1)
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB AUTO FARM
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabFarm:CreateSection("✦  Full Auto Farm")
TabFarm:CreateParagraph({Title="Flow",
    Content="① Beli Bibit\n② Tanam ke semua lahan\n③ Tunggu panen\n④ Harvest\n⑤ Mandi (opsional)\n⑥ Jual semua\n\n— Scan Lahan dulu di tab 📍"})
TabFarm:CreateSlider({Name="Delay Tanam  (detik)", Range={0.1,3}, Increment=0.1, CurrentValue=0.5,
    Callback=function(v) dTanam=v end})
TabFarm:CreateSlider({Name="Tunggu Panen  (detik)", Range={10,300}, Increment=5, CurrentValue=60,
    Callback=function(v) waitPanen=v end})
TabFarm:CreateToggle({Name="🚿  Auto Mandi tiap siklus", CurrentValue=false,
    Callback=function(v) _G.AutoMandi=v end})

TabFarm:CreateToggle({Name="🔥  FULL AUTO FARM", CurrentValue=false,
    Callback=function(v)
        _G.AutoFarm=v
        if not v then notif("🤖  Auto Farm","Dihentikan",2); return end
        if #LahanCache==0 then scanLahan() end
        if #LahanCache==0 then
            notif("⚠️","Scan Lahan dulu!",5); _G.AutoFarm=false; return
        end
        SiklusCount=0
        notif("🔥  Auto Farm ON","Lahan: "..#LahanCache.."  ·  Bibit: "..selectedBibit,4)
        task.spawn(function()
            while _G.AutoFarm do
                SiklusCount=SiklusCount+1
                -- Beli
                local ok,msg=beliBibit(selectedBibit,jumlahBeli)
                notif(ok and "🛒  Beli ✅" or "🛒  Beli ❌",msg,2)
                if not _G.AutoFarm then break end; task.wait(1)
                -- Tanam
                local planted=0
                for _,pos in ipairs(LahanCache) do
                    if not _G.AutoFarm then break end
                    if fireEv("PlantCrop",pos) then planted=planted+1 end
                    task.wait(dTanam)
                end
                notif("🌱  Tanam ✅",planted.."/"..#LahanCache.." plot",2)
                if not _G.AutoFarm then break end
                -- Tunggu panen
                local w=0
                while w<waitPanen and _G.AutoFarm do task.wait(1); w=w+1 end
                if not _G.AutoFarm then break end
                -- Harvest
                local h=autoHarvestTick()
                if h>0 then notif("🌾  Harvest ✅",h.." tanaman",2) end
                task.wait(1)
                -- Mandi
                if _G.AutoMandi then goMandi(); task.wait(3) end
                -- Jual
                local sOk,sMsg=jualSemua()
                notif(sOk and "💰  Jual ✅" or "💰  Jual ❌",sMsg,3)
                task.wait(2)
            end
            notif("⛔  Farm Stop","Siklus: "..SiklusCount.."  ·  Earned: "..totalEarned.."💰",4)
        end)
    end})

TabFarm:CreateToggle({Name="🌱  Auto Tanam Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoTanam=v
        if v then
            task.spawn(function()
                while _G.AutoTanam do
                    if #LahanCache==0 then scanLahan() end
                    local c=0
                    for _,pos in ipairs(LahanCache) do
                        if not _G.AutoTanam then break end
                        if fireEv("PlantCrop",pos) then c=c+1 end
                        task.wait(dTanam)
                    end
                    notif("🌱  Tanam ✅",c.." plot",2); task.wait(5)
                end
            end)
            notif("🌱  Auto Tanam","ON ✅",3)
        else notif("🌱  Auto Tanam","OFF",2) end
    end})

TabFarm:CreateButton({Name="⛔  STOP SEMUA", Callback=stopSemua})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB BIBIT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabBibit:CreateSection("✦  Beli Bibit")
local opsiB={}
for _,b in ipairs(BIBIT_LIST) do
    table.insert(opsiB, b.icon.."  "..b.name.."  ·  Lv."..b.minLv.."  ·  "..b.price.."💰")
end
TabBibit:CreateDropdown({Name="Pilih Bibit", Options=opsiB, CurrentOption={opsiB[1]},
    Callback=function(v)
        for _,b in ipairs(BIBIT_LIST) do
            if v[1]:find(b.name,1,true) then
                selectedBibit=b.name; notif("✅  Dipilih",b.name,2); break
            end
        end
    end})
TabBibit:CreateSlider({Name="Jumlah", Range={1,99}, Increment=1, CurrentValue=1,
    Callback=function(v) jumlahBeli=v end})
TabBibit:CreateButton({Name="🛒  Beli Sekarang",
    Callback=function()
        task.spawn(function()
            local ok,msg=beliBibit(selectedBibit,jumlahBeli)
            notif(ok and "🛒  Beli ✅" or "❌",msg,4)
        end)
    end})

TabBibit:CreateSection("✦  Beli Cepat")
for _,b in ipairs(BIBIT_LIST) do
    local bb=b
    TabBibit:CreateButton({Name=bb.icon.."  "..bb.name.."  ·  "..bb.price.."💰",
        Callback=function()
            task.spawn(function()
                selectedBibit=bb.name
                local ok,msg=beliBibit(bb.name,jumlahBeli)
                notif(ok and "✅" or "❌",msg,3)
            end)
        end})
end

TabBibit:CreateSection("✦  Stok")
TabBibit:CreateButton({Name="📋  Lihat Stok Bibit",
    Callback=function()
        task.spawn(function()
            local ok,res=invokeRF("RequestShop","GET_LIST")
            if not ok then notif("❌","Gagal",3); return end
            local data=unwrap(res)
            if not data or not data.Seeds then notif("❌","Kosong",3); return end
            PlayerData.Coins=data.Coins or PlayerData.Coins
            local txt="💰 "..tostring(data.Coins).."\n\n"
            for _,s in ipairs(data.Seeds) do
                txt=txt..(s.Locked and "🔒" or "✅").."  "..s.Name
                    .."  x"..s.Owned.."  ·  "..s.Price.."💰\n"
            end
            notif("🛒  Bibit Shop",txt,10)
        end)
    end})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB JUAL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabJual:CreateSection("✦  Jual  —  Confirmed")
TabJual:CreateParagraph({Title="Method ✅",
    Content="RequestSell:InvokeServer('SELL', nama, qty)\n\n"
        .."Harga confirmed:\n"
        .."🌾 Padi 10💰  ·  🌽 Jagung 20💰\n"
        .."🍅 Tomat 30💰  ·  🍆 Terong 50💰\n"
        .."🍓 Strawberry 75💰"})

TabJual:CreateButton({Name="💰  Jual Semua",
    Callback=function()
        task.spawn(function()
            local ok,msg=jualSemua()
            notif(ok and "💰  Jual ✅" or "❌",msg,4)
        end)
    end})

TabJual:CreateToggle({Name="🔄  Auto Sell Loop  (30s)", CurrentValue=false,
    Callback=function(v)
        _G.AutoSell=v
        if v then
            SellLoop=task.spawn(function()
                while _G.AutoSell do
                    local ok,msg=jualSemua()
                    notif(ok and "💰  Auto Sell ✅" or "❌",msg,3)
                    task.wait(30)
                end
            end)
            notif("💰  Auto Sell","ON  ·  tiap 30s",3)
        else
            if SellLoop then pcall(function() task.cancel(SellLoop) end); SellLoop=nil end
            notif("💰  Auto Sell","OFF",2)
        end
    end})

TabJual:CreateSection("✦  Preview Inventory")
TabJual:CreateButton({Name="📋  Lihat Inventory",
    Callback=function()
        task.spawn(function()
            local data=getInventoryJual()
            if not data or not data.Items then notif("❌","Gagal",3); return end
            local txt="SellMult: "..tostring(data.SellMult).."  ·  💰 "..tostring(data.Coins).."\n\n"
            for _,item in ipairs(data.Items) do
                txt=txt..(item.Owned>0 and "✅" or "⬜").."  "
                    ..item.DisplayName.."  x"..item.Owned.."  ·  "..item.Price.."💰\n"
            end
            notif("📦  Inventory",txt,10)
        end)
    end})

TabJual:CreateSection("✦  Jual Cepat Per Item")
for _,item in ipairs(ITEM_LIST) do
    local it=item
    TabJual:CreateButton({Name=it.icon.."  "..it.name.."  ·  "..it.price.."💰/pcs",
        Callback=function()
            task.spawn(function()
                local data=getInventoryJual()
                local owned=0
                if data and data.Items then
                    for _,i in ipairs(data.Items) do
                        if i.Name==it.name then owned=i.Owned; break end
                    end
                end
                if owned==0 then notif("⬜  "..it.name,"Stok kosong",3); return end
                local ok,msg,earned=jualItem(it.name,owned)
                notif(ok and "💰  Jual ✅" or "❌",
                    it.name.."  x"..owned..(ok and "  +"..earned.."💰" or "  ·  "..msg),4)
            end)
        end})
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB HARVEST
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabHarvest:CreateSection("✦  Auto Harvest")
TabHarvest:CreateParagraph({Title="Cara Kerja",
    Content="Scan ProximityPrompt tanaman\ndi radius 20 studs dari karakter\n→ fireproximityprompt() otomatis\n\nConfirmed: HarvestCrop.OnClientEvent"})
TabHarvest:CreateSlider({Name="Interval  (detik)", Range={1,30}, Increment=1, CurrentValue=5,
    Callback=function(v) harvestInterval=v end})
TabHarvest:CreateToggle({Name="🌾  AUTO HARVEST", CurrentValue=false,
    Callback=function(v)
        _G.AutoHarvest=v
        if v then
            HarvestLoop=task.spawn(function()
                while _G.AutoHarvest do
                    local h=autoHarvestTick()
                    if h>0 then notif("🌾  Harvest ✅",h.." tanaman",2) end
                    task.wait(harvestInterval)
                end
            end)
            notif("🌾  Auto Harvest","ON  ·  tiap "..harvestInterval.."s",3)
        else
            if HarvestLoop then pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil end
            notif("🌾  Auto Harvest","OFF  ·  Total: "..harvestCount.."×",3)
        end
    end})
TabHarvest:CreateButton({Name="🌾  Harvest Sekali",
    Callback=function()
        task.spawn(function()
            local h=autoHarvestTick()
            notif("🌾  Harvest", h>0 and h.." tanaman" or "Tidak ada tanaman dekat",3)
        end)
    end})
TabHarvest:CreateButton({Name="🗑  Reset Counter",
    Callback=function() harvestCount=0; notif("✅  Reset","Counter panen di-reset",2) end})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB TELEPORT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabTP:CreateSection("✦  Teleport NPC  —  5 NPC Confirmed")
TabTP:CreateParagraph({Title="📌  Koordinat Confirmed",
    Content="Y otomatis via Raycast — tidak nembus tanah\n\n"
        .."🛒  Penjual      X=-59   Z=-207\n"
        .."🌱  Bibit        X=-42   Z=-207\n"
        .."🔧  Alat         X=-41   Z=-100\n"
        .."🌴  Sawit        X= 56   Z=-208\n"
        .."🥚  Telur        X=-98   Z=-176\n"
        .."🚿  Mandi        X=137   Z=-235"})

for _,npc in ipairs(NPC_LIST) do
    local n=npc
    TabTP:CreateButton({Name="🚀  "..n.label,
        Callback=function()
            tpXZ(n.x, n.z)
            notif("📍  TP",n.label..string.format("  ·  X=%.0f  Z=%.0f",n.x,n.z),3)
        end})
end

TabTP:CreateSection("✦  Mandi")
TabTP:CreateButton({Name="🚿  TP ke Tempat Mandi",
    Callback=function() goMandi() end})
TabTP:CreateToggle({Name="🚿  Auto Mandi  (saat notif kotor)", CurrentValue=false,
    Callback=function(v) _G.AutoMandi=v; notif("🚿  Auto Mandi",v and "ON ✅" or "OFF",2) end})

TabTP:CreateSection("✦  Scan Lahan")
local LahanPara = TabTP:CreateParagraph({Title="🗺  Lahan", Content="Belum scan"})
TabTP:CreateButton({Name="🔍  Scan Lahan",
    Callback=function()
        LahanCacheTime=0; local l=scanLahan()
        LahanPara:Set({Title="🗺  Lahan",
            Content=#l.." plot  "..(#l>0 and "✅  Siap!" or "❌  Tidak ada")})
        notif("🔍  Scan",#l.." plot ditemukan",3)
    end})

TabTP:CreateSection("✦  Manual Koordinat  (Y otomatis)")
local tpX,tpZ2=0,0
TabTP:CreateInput({Name="X", PlaceholderText="-59",
    RemoveTextAfterFocusLost=false, Callback=function(v) tpX=tonumber(v) or 0 end})
TabTP:CreateInput({Name="Z", PlaceholderText="-207",
    RemoveTextAfterFocusLost=false, Callback=function(v) tpZ2=tonumber(v) or 0 end})
TabTP:CreateButton({Name="🚀  TP ke Koordinat",
    Callback=function()
        tpXZ(tpX, tpZ2)
        notif("📍  TP",string.format("X=%.1f  Z=%.1f  (Y otomatis)",tpX,tpZ2),3)
    end})
TabTP:CreateButton({Name="📍  Print Posisi Saya",
    Callback=function()
        local pos=getPos()
        if pos then
            notif("📍  Posisi Saya",
                string.format("X=%.2f\nY=%.2f\nZ=%.2f",pos.X,pos.Y,pos.Z),5)
            print(string.format("[ XKID 📍 ] X=%.4f  Y=%.4f  Z=%.4f",pos.X,pos.Y,pos.Z))
        end
    end})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB PENANGKAL PETIR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabPetir:CreateSection("⚡  Penangkal Petir  —  Flee & Return")
TabPetir:CreateParagraph({Title="Cara Kerja  v14",
    Content="Saat LightningStrike event masuk:\n\n"
        .."① Simpan posisi sekarang\n"
        .."② TP kabur ke titik aman\n"
        .."   (set manual atau auto-acak)\n"
        .."③ Tunggu 4 detik (petir selesai)\n"
        .."④ TP balik ke posisi semula\n\n"
        .."✅ Set Titik Aman = lebih akurat\n"
        .."⚠️ Auto-acak = offset random ~80 studs"})

TabPetir:CreateToggle({Name="⚡  Penangkal Petir  AKTIF", CurrentValue=false,
    Callback=function(v)
        _G.PenangkalPetir=v
        notif("⚡  Penangkal Petir",
            v and "●  AKTIF  —  Akan kabur saat petir" or "○  OFF", 3)
    end})

TabPetir:CreateSection("✦  Titik Aman  (opsional tapi direkomendasikan)")
TabPetir:CreateParagraph({Title="Tips",
    Content="Set titik aman di dalam bangunan\natau area yang tidak kena petir\n\nKalau tidak di-set, script auto kabur\nke arah acak sejauh ~80 studs"})

TabPetir:CreateButton({Name="📍  Set Titik Aman  (posisi saya)",
    Callback=function()
        local pos=getPos()
        if pos then
            fleeBase = { x=pos.X, z=pos.Z }
            notif("✅  Titik Aman Set",
                string.format("X=%.1f  Z=%.1f\nAkan kabur ke sini saat petir",pos.X,pos.Z),5)
        end
    end})

TabPetir:CreateButton({Name="🗑  Hapus Titik Aman  (pakai auto-acak)",
    Callback=function()
        fleeBase=nil
        notif("🗑  Titik Aman Dihapus","Sekarang pakai auto-acak offset",3)
    end})

TabPetir:CreateButton({Name="⚡  Test Flee Sekarang  (manual)",
    Callback=function()
        if not getRoot() then notif("❌","Karakter tidak ada",3); return end
        task.spawn(function()
            lightningHits=lightningHits+1
            fleePetir()
        end)
    end})

TabPetir:CreateButton({Name="🗑  Reset Counter Petir",
    Callback=function() lightningHits=0; notif("✅  Reset","Counter petir di-reset",2) end})

-- Live stats petir
local petirPara = TabPetir:CreateParagraph({Title="📊  Stats",Content="—"})
task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            petirPara:Set({Title="📊  Stats Petir",
                Content="Total petir: "..lightningHits.."×\n"
                    .."Status: "..(_G.PenangkalPetir and "●  AKTIF" or "○  OFF").."\n"
                    .."Sedang kabur: "..(isPetirFleeing and "🏃  YA" or "—").."\n"
                    .."Titik aman: "..(fleeBase
                        and string.format("✅  X=%.0f Z=%.0f",fleeBase.x,fleeBase.z)
                        or "⚠️  Auto-acak")})
        end)
        task.wait(1)
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB SETTING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabSet:CreateSection("✦  Anti AFK")
TabSet:CreateToggle({Name="🛡  Anti AFK", CurrentValue=false,
    Callback=function(v)
        _G.AntiAFK=v
        if v then startAntiAFK() end
        notif("🛡  Anti AFK",v and "ON  ·  Jump tiap 2 menit" or "OFF",3)
    end})

TabSet:CreateSection("✦  Farm Timing")
TabSet:CreateSlider({Name="Delay Tanam  (s)", Range={0.1,3}, Increment=0.1, CurrentValue=0.5,
    Callback=function(v) dTanam=v end})
TabSet:CreateSlider({Name="Tunggu Panen  (s)", Range={10,300}, Increment=5, CurrentValue=60,
    Callback=function(v) waitPanen=v end})
TabSet:CreateSlider({Name="Harvest Interval  (s)", Range={1,30}, Increment=1, CurrentValue=5,
    Callback=function(v) harvestInterval=v end})

TabSet:CreateSection("✦  Misc")
TabSet:CreateToggle({Name="✅  Auto Confirm", CurrentValue=false,
    Callback=function(v) _G.AutoConfirm=v; notif("✅  Auto Confirm",v and "ON" or "OFF",2) end})
TabSet:CreateToggle({Name="🎉  Notif Level Up", CurrentValue=true,
    Callback=function(v) _G.NotifLevelUp=v end})
TabSet:CreateButton({Name="⛔  STOP SEMUA", Callback=stopSemua})
TabSet:CreateButton({Name="🔄  Reset Session Stats",
    Callback=function()
        totalEarned=0; harvestCount=0; SiklusCount=0; levelUpCount=0; lightningHits=0
        notif("✅  Reset","Semua stats di-reset",2)
    end})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB DEBUG
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabTest:CreateSection("✦  Remote Confirmed")
TabTest:CreateParagraph({Title="Cobalt ✅",
    Content="✅  RequestShop('BUY', nama, qty)\n"
        .."✅  RequestShop('GET_LIST')\n"
        .."✅  RequestSell('GET_LIST')\n"
        .."✅  RequestSell('SELL', nama, qty)\n"
        .."✅  PlantCrop:FireServer(Vector3)\n"
        .."✅  HarvestCrop.OnClientEvent"})

TabTest:CreateSection("✦  Test SELL")
local sellCmd,sellArg,sellQty2="SELL","Padi","7"
TabTest:CreateInput({Name="Command", PlaceholderText="SELL / GET_LIST",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellCmd=v end})
TabTest:CreateInput({Name="Nama Item", PlaceholderText="Padi",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellArg=v end})
TabTest:CreateInput({Name="Qty", PlaceholderText="7",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellQty2=v end})
TabTest:CreateButton({Name="🔥  Test RequestSell",
    Callback=function()
        task.spawn(function()
            local qty=tonumber(sellQty2)
            local ok,res
            if qty and sellArg~="" then ok,res=invokeRF("RequestSell",sellCmd,sellArg,qty)
            elseif sellArg~="" then ok,res=invokeRF("RequestSell",sellCmd,sellArg)
            else ok,res=invokeRF("RequestSell",sellCmd) end
            notif("RequestSell("..sellCmd..")",ok and "✅  Lihat console" or "❌  "..tostring(res),5)
            if ok then
                local d=unwrap(res) or res
                if type(d)=="table" then
                    for k,v in pairs(d) do
                        if type(v)~="table" then
                            print(string.format("[ XKID SELL ] %s = %s",tostring(k),tostring(v)))
                        end
                    end
                end
            end
        end)
    end})

TabTest:CreateSection("✦  Quick Test")
for _,q in ipairs({
    {"SummonRain",   "🌧  SummonRain"},
    {"SkipTutorial", "📖  SkipTutorial"},
    {"RefreshShop",  "🔄  RefreshShop"},
}) do
    local qq=q
    TabTest:CreateButton({Name=qq[2],
        Callback=function()
            task.spawn(function()
                local ok,err=fireEv(qq[1])
                notif(qq[1],ok and "Fired ✅" or "❌  "..tostring(err),3)
            end)
        end})
end

TabTest:CreateButton({Name="🔍  Test Raycast Y  (posisi saya)",
    Callback=function()
        local pos=getPos()
        if not pos then notif("❌","Karakter tidak ada",3); return end
        local y=getGroundY(pos.X, pos.Z)
        notif("🔍  Raycast Y",
            string.format("X=%.2f  Z=%.2f\nGround Y = %.4f",pos.X,pos.Z,y),5)
        print(string.format("[ XKID RAYCAST ] X=%.2f Z=%.2f → Y=%.4f",pos.X,pos.Z,y))
    end})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  INIT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
setupIntercepts()

task.spawn(function()
    task.wait(3)
    scanLahan()
    notif("🔍  Auto Scan", #LahanCache.." lahan ditemukan", 4)
end)

notif("🌾  INDO FARMER  v14.0","Welcome,  "..LocalPlayer.Name.."  ✦",5)
task.wait(1.5)
notif("✦  v14  Fix",
    "✅ TP tidak nembus tanah (Raycast Y)\n"
    .."✅ Penangkal petir Flee & Return\n"
    .."✅ 5 NPC hardcoded\n"
    .."✅ Backpack dihapus", 8)

print("╔═══════════════════════════════════════════╗")
print("║   🌾  INDO FARMER  v14.0  —  XKID HUB   ║")
print("║   Flee⚡  RaycastTP  ·  5 NPC Confirmed  ║")
print("║   Player: "..LocalPlayer.Name)
print("╚═══════════════════════════════════════════╝")
