--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🌾  I N D O   F A R M E R  v18.0  🌾           ║
  ║      XKID HUB  ✦  Aurora UI — All Bugs Fixed        ║
  ║      Fix: Harvest·Petir·Inventory·Tanam·Jual        ║
  ╚═══════════════════════════════════════════════════════╝

  SEMUA BUG YANG DIFIX DI v18:
  [1] Harvest punya orang → filter radius dari LahanCache
  [2] Penangkal petir → HP set langsung sebelum yield
  [3] Menu jual saat harvest → blacklist radius NPC Penjual
  [4] Auto Tanam double loop → cancel handle dulu
  [5] Tanam tanpa TP → TP ke lahan sebelum PlantCrop
  [6] Cache lahan terlalu pendek → 300 detik
  [7] dTanam slider tidak sinkron → fix default
  [8] Inventory salah → parse Items bukan Coins saja
  [9] SellCrop intercept terlalu lebar → hapus, pakai manual

  NPC CONFIRMED:
  Penjual X=-59 Z=-207 | Bibit X=-42 Z=-207
  Alat    X=-41 Z=-100 | Sawit X= 56 Z=-208
  Telur   X=-98 Z=-176 | Mandi X=137 Z=-235
]]

-- ════════════════════════════════════════════════
--  LOAD AURORA UI
-- ════════════════════════════════════════════════
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Win = Library:Window(
    "Indo Farmer",
    "sprout",
    "v18.0  |  XKID HUB  |  All Bugs Fixed",
    false
)

-- ════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")
local RunService  = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ════════════════════════════════════════════════
--  FLAGS
-- ════════════════════════════════════════════════
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

-- ════════════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════════════
local PlayerData      = { Coins=0, Level=1, XP=0, Needed=50 }
local SiklusCount     = 0
local lightningHits   = 0
local levelUpCount    = 0
local totalEarned     = 0
local harvestCount    = 0
local LahanCache      = {}
local LahanCacheTime  = 0
local SellLoop        = nil
local HarvestLoop     = nil
local TanamLoop       = nil   -- [FIX-4] handle untuk cancel
local selectedBibit   = "Bibit Padi"
local jumlahBeli      = 1
local dTanam          = 0.5   -- detik, sync dengan slider default=5 → 0.5
local waitPanen       = 60
local harvestInterval = 10
local isPetirActive   = false
local savedPositions  = { nil, nil, nil, nil, nil }
local fleePos         = nil
local petirReturnCF   = nil
local godConn         = nil

-- ════════════════════════════════════════════════
--  DATA
-- ════════════════════════════════════════════════
local NPC_LIST = {
    { label="NPC Penjual",        x=-59, z=-207 },
    { label="NPC Bibit",          x=-42, z=-207 },
    { label="NPC Alat",           x=-41, z=-100 },
    { label="NPC Pedagang Sawit", x= 56, z=-208 },
    { label="NPC Pedagang Telur", x=-98, z=-176 },
}
local MANDI = { x=137, z=-235 }

-- [FIX-3] koordinat NPC Penjual untuk blacklist saat harvest
local PENJUAL_X, PENJUAL_Z = -59, -207
local HARVEST_BLACKLIST_RADIUS = 25  -- studs

local ITEM_LIST = {
    { name="Padi",       price=10 },
    { name="Jagung",     price=20 },
    { name="Tomat",      price=30 },
    { name="Terong",     price=50 },
    { name="Strawberry", price=75 },
}

local BIBIT_LIST = {
    { name="Bibit Padi",       price=5,    minLv=1   },
    { name="Bibit Jagung",     price=15,   minLv=20  },
    { name="Bibit Tomat",      price=25,   minLv=40  },
    { name="Bibit Terong",     price=40,   minLv=60  },
    { name="Bibit Strawberry", price=60,   minLv=80  },
    { name="Bibit Sawit",      price=1000, minLv=80  },
    { name="Bibit Durian",     price=2000, minLv=120 },
}
local bibitNames = {}
for _, b in ipairs(BIBIT_LIST) do table.insert(bibitNames, b.name) end

-- ════════════════════════════════════════════════
--  NOTIF
-- ════════════════════════════════════════════════
local function notif(title, body, dur)
    pcall(function() Library:Notification(title, body, dur or 3) end)
    print(string.format("[ XKID ] %s | %s", title, tostring(body)))
end

-- ════════════════════════════════════════════════
--  CHARACTER HELPERS
-- ════════════════════════════════════════════════
local function getChar()  return LocalPlayer.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function getPos()  local r = getRoot(); return r and r.Position end
local function getCF()   local r = getRoot(); return r and r.CFrame  end

-- ════════════════════════════════════════════════
--  TELEPORT
-- ════════════════════════════════════════════════
local function tpCFrame(cf)
    local root = getRoot(); if not root then return false end
    root.CFrame = cf; task.wait(0.35); return true
end

local function findNpcY(x, z)
    local bestY, bestDist = nil, math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("npc") or n:find("pedagang") or n:find("penjual")
            or n:find("bibit") or n:find("alat") then
                local d = math.sqrt((v.Position.X-x)^2 + (v.Position.Z-z)^2)
                if d < bestDist then bestDist=d; bestY=v.Position.Y end
            end
        end
    end
    if bestY and bestDist < 30 then return bestY + 2 end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local ch = getChar(); if ch then rp.FilterDescendantsInstances = {ch} end
    local res = Workspace:Raycast(Vector3.new(x,500,z), Vector3.new(0,-1000,0), rp)
    return res and (res.Position.Y + 3) or 42
end

local function tpToNPC(x, z)
    local root = getRoot(); if not root then return false, 0 end
    local y = findNpcY(x, z)
    root.CFrame = CFrame.new(x, y, z)
    task.wait(0.35); return true, y
end

-- ════════════════════════════════════════════════
--  REMOTE HELPERS
-- ════════════════════════════════════════════════
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
    if not r or not r:IsA("RemoteEvent") then return false end
    return pcall(function(...) r:FireServer(...) end, ...)
end
local function invokeRF(name, ...)
    local r = getR(name)
    if not r or not r:IsA("RemoteFunction") then return false, nil end
    return pcall(function(...) return r:InvokeServer(...) end, ...)
end
local function unwrap(res)
    if type(res) == "table" then
        return type(res[1]) == "table" and res[1] or res
    end
    return nil
end

-- ════════════════════════════════════════════════
--  ⚡ PENANGKAL PETIR v18 — FIX TOTAL
--
--  [FIX-2] HP di-set LANGSUNG di baris pertama
--  (bukan via Heartbeat yang telat 1 frame)
--  Baru setelah itu HP lock Heartbeat diaktifkan
--  dan TP dilakukan.
-- ════════════════════════════════════════════════
local function startHpLock(dur)
    if godConn then godConn:Disconnect(); godConn = nil end
    local deadline = tick() + dur
    godConn = RunService.Heartbeat:Connect(function()
        if tick() > deadline then godConn:Disconnect(); godConn=nil; return end
        local h = getHum()
        if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
    end)
end

local function fleePetir()
    if isPetirActive then return end
    isPetirActive = true
    lightningHits = lightningHits + 1

    local root = getRoot()
    if not root then isPetirActive=false; return end

    -- [FIX-2] Set HP LANGSUNG sebelum apapun
    local hum = getHum()
    if hum then hum.Health = hum.MaxHealth end

    -- Simpan posisi sebelum kabur
    petirReturnCF = root.CFrame

    -- [FIX-2] HP lock heartbeat 8 detik
    startHpLock(8)

    -- TP kabur
    if fleePos then
        root.CFrame = fleePos
        notif("⚡ Kabur! #"..lightningHits, "→ Titik aman | kembali 5 detik", 5)
    else
        local pos = root.Position
        root.CFrame = CFrame.new(pos.X, pos.Y + 350, pos.Z)
        notif("⚡ Kabur! #"..lightningHits, "→ Naik awan | kembali 5 detik", 5)
    end

    task.wait(5)

    -- Balik ke posisi asal
    local r2 = getRoot()
    if r2 and petirReturnCF then
        r2.CFrame = petirReturnCF
        notif("✅ Kembali", "Balik ke posisi semula", 2)
    end

    task.wait(0.5)
    isPetirActive = false
end

-- ════════════════════════════════════════════════
--  ANTI AFK
-- ════════════════════════════════════════════════
local antiAFKConn = nil
local function startAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect() end
    local last = tick()
    antiAFKConn = RunService.Heartbeat:Connect(function()
        if not _G.AntiAFK then antiAFKConn:Disconnect(); antiAFKConn=nil; return end
        if tick()-last >= 120 then
            last=tick(); local h=getHum(); if h then h.Jump=true end
        end
    end)
end

-- ════════════════════════════════════════════════
--  SCAN LAHAN
--  [FIX-6] Cache 300 detik, refresh manual saja
-- ════════════════════════════════════════════════
local function scanLahan(force)
    if not force and tick()-LahanCacheTime < 300 and #LahanCache > 0 then
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

-- ════════════════════════════════════════════════
--  CEK APAKAH POSISI DEKAT LAHAN KITA
--  [FIX-1] Hanya harvest tanaman di atas lahan kita
-- ════════════════════════════════════════════════
local LAHAN_RADIUS = 15  -- studs dari titik lahan

local function isPosDekatLahan(pos)
    for _, lahanPos in ipairs(LahanCache) do
        local dx = pos.X - lahanPos.X
        local dz = pos.Z - lahanPos.Z
        if math.sqrt(dx*dx + dz*dz) <= LAHAN_RADIUS then
            return true
        end
    end
    return false
end

-- [FIX-3] Cek apakah posisi terlalu dekat NPC Penjual
local function isPosDekatPenjual(pos)
    local dx = pos.X - PENJUAL_X
    local dz = pos.Z - PENJUAL_Z
    return math.sqrt(dx*dx + dz*dz) < HARVEST_BLACKLIST_RADIUS
end

-- ════════════════════════════════════════════════
--  FARMING FUNCTIONS
-- ════════════════════════════════════════════════
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

-- ════════════════════════════════════════════════
--  JUAL
-- ════════════════════════════════════════════════
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
        -- [FIX-10] skip item price=0
        if item.Owned and item.Owned > 0 and (item.Price or 0) > 0 then
            local ok = jualItem(item.Name, item.Owned)
            if ok then
                totalItem = totalItem + item.Owned
                totalCoin = totalCoin + ((item.Price or 0) * item.Owned)
            end
            task.wait(0.3)
        end
    end
    if totalItem == 0 then return false,"Tidak ada item untuk dijual" end
    return true, totalItem.." item | +"..totalCoin.."💰"
end

-- ════════════════════════════════════════════════
--  [FIX-8] CEK INVENTORY — hanya tampilkan Items
--  bukan raw response yang berisi Coins saja
-- ════════════════════════════════════════════════
-- ════════════════════════════════════════════════
--  getInventoryDisplay — FIX TOTAL
--
--  Masalah lama: tampil Coins saja karena
--  Items tidak ditemukan di dalam response.
--
--  Fix: unwrap manual berlapis, lalu auto-detect
--  key yang berisi array item (Name + Price).
--  Debug log ke console F9 agar mudah diagnosa.
-- ════════════════════════════════════════════════
local function getInventoryDisplay()
    local ok, res = invokeRF("RequestSell", "GET_LIST")
    if not ok then return nil, "Remote gagal" end

    -- ── Debug: cetak seluruh struktur raw ke console ──
    local function debugTable(t, prefix)
        prefix = prefix or ""
        for k, v in pairs(t) do
            if type(v) == "table" then
                print(string.format("[ XKID INV ] %s[%s] = table (len=%d)", prefix, tostring(k), #v))
                if #v > 0 and type(v[1]) == "table" then
                    -- Cetak key dari item pertama saja
                    local keys = {}
                    for ik in pairs(v[1]) do table.insert(keys, tostring(ik)) end
                    print(string.format("[ XKID INV ] %s  └─ item[1] keys: {%s}", prefix, table.concat(keys, ", ")))
                end
            else
                print(string.format("[ XKID INV ] %s[%s] = %s", prefix, tostring(k), tostring(v)))
            end
        end
    end

    if type(res) == "table" then
        print("[ XKID INV ] ── RAW RESPONSE ──")
        debugTable(res)
    else
        print("[ XKID INV ] res bukan table: " .. type(res) .. " = " .. tostring(res))
    end

    -- ── Unwrap: cek apakah res adalah array wrapper ──
    -- Server bisa kirim: {Items=..., Coins=...}
    -- atau wrapper:      { {Items=..., Coins=...} }
    local data = res
    if type(res) == "table" and type(res[1]) == "table" then
        data = res[1]  -- unwrap array wrapper
        print("[ XKID INV ] Unwrapped array wrapper")
    end

    if type(data) ~= "table" then
        return nil, "Data bukan table"
    end

    -- Update coins
    if data.Coins then
        PlayerData.Coins = data.Coins
    end

    -- ── Cari items: coba semua kemungkinan key ──
    local items = data.Items or data.items or data.Inventory
        or data.inventory or data.Products or data.products

    -- Kalau masih nil, scan semua key cari array of {Name, Price}
    if not items then
        for k, v in pairs(data) do
            if type(v) == "table" and #v > 0 then
                local first = v[1]
                if type(first) == "table" then
                    local hasName  = first.Name  or first.name  or first.ItemName
                    local hasPrice = first.Price or first.price or first.SellPrice
                    if hasName or hasPrice then
                        items = v
                        print("[ XKID INV ] Items ditemukan di key: " .. tostring(k))
                        break
                    end
                end
            end
        end
    end

    if items then
        print(string.format("[ XKID INV ] Items count: %d", #items))
        -- Cetak tiap item untuk debug
        for i, item in ipairs(items) do
            local nm  = item.Name or item.name or "?"
            local own = item.Owned or item.owned or item.Amount or 0
            local pr  = item.Price or item.price or item.SellPrice or 0
            print(string.format("[ XKID INV ]   [%d] %s  owned=%s  price=%s", i, nm, tostring(own), tostring(pr)))
        end
    else
        print("[ XKID INV ] ⚠️ Items tidak ditemukan di response!")
        print("[ XKID INV ] Kirim screenshot console F9 ke developer")
    end

    return data, items
end

-- ════════════════════════════════════════════════
--  AUTO HARVEST v18
--  [FIX-1] Filter: hanya tanaman di atas LahanCache kita
--  [FIX-3] Skip area dekat NPC Penjual
-- ════════════════════════════════════════════════
local function autoHarvestAll()
    if #LahanCache == 0 then
        notif("⚠️ Harvest", "LahanCache kosong, scan dulu!", 4)
        return 0
    end

    local root = getRoot(); if not root then return 0 end
    local startCF = root.CFrame
    local harvested, skipped, visited = 0, 0, {}

    for _, v in pairs(Workspace:GetDescendants()) do
        if not _G.AutoHarvest and not _G.AutoFarm then break end

        local n = v.Name:lower()
        local isCrop = n:find("crop") or n:find("plant")
            or n:find("padi") or n:find("jagung") or n:find("tomat")
            or n:find("terong") or n:find("sawit") or n:find("durian")
            or n:find("strawberry")

        if isCrop and not visited[v] then
            visited[v] = true
            local pp = v:FindFirstChildWhichIsA("ProximityPrompt", true)
            if pp then
                local partPos
                if v:IsA("BasePart") then
                    partPos = v.Position
                elseif v:IsA("Model") and v.PrimaryPart then
                    partPos = v.PrimaryPart.Position
                end

                if partPos then
                    -- [FIX-1] Cek apakah tanaman ini di atas lahan kita
                    if not isPosDekatLahan(partPos) then
                        skipped = skipped + 1
                        continue  -- bukan lahan kita, skip
                    end

                    -- [FIX-3] Cek blacklist area NPC Penjual
                    if isPosDekatPenjual(partPos) then
                        skipped = skipped + 1
                        continue  -- terlalu dekat penjual, skip
                    end

                    -- TP ke tanaman
                    local r = getRoot()
                    if r then
                        r.CFrame = CFrame.new(partPos.X, partPos.Y + 3, partPos.Z)
                        task.wait(0.2)
                    end

                    pcall(function() fireproximityprompt(pp) end)
                    harvested = harvested + 1
                    task.wait(0.25)
                end
            end
        end
    end

    if skipped > 0 then
        print(string.format("[ XKID 🌾 ] Harvest: %d dipanen, %d diskip (bukan punya kita)", harvested, skipped))
    end

    -- Balik ke posisi awal
    if harvested > 0 then
        task.wait(0.3)
        local r2 = getRoot(); if r2 then r2.CFrame = startCF end
    end

    return harvested
end

-- ════════════════════════════════════════════════
--  MANDI
-- ════════════════════════════════════════════════
local function goMandi()
    local _, y = tpToNPC(MANDI.x, MANDI.z)
    notif("🚿 Mandi", string.format("X=%d Z=%d", MANDI.x, MANDI.z), 3)
end

-- ════════════════════════════════════════════════
--  STOP ALL
-- ════════════════════════════════════════════════
local function stopSemua()
    _G.AutoFarm=false; _G.AutoTanam=false
    _G.AutoSell=false; _G.AutoHarvest=false; _G.AutoMandi=false
    if SellLoop    then pcall(function() task.cancel(SellLoop)    end); SellLoop=nil    end
    if HarvestLoop then pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil end
    if TanamLoop   then pcall(function() task.cancel(TanamLoop)   end); TanamLoop=nil   end
    notif("⛔ Stop Semua", "Semua fitur dimatikan", 3)
end

-- ════════════════════════════════════════════════
--  INTERCEPTS
--  [FIX-9] Hapus SellCrop intercept auto-jual
--  (penyebab menu jual muncul sendiri)
-- ════════════════════════════════════════════════
local function setupIntercepts()

    -- ⚡ Petir
    task.spawn(function()
        local r
        for i=1,25 do r=getR("LightningStrike"); if r then break end; task.wait(1) end
        if not r then
            print("[ XKID ⚠️ ] LightningStrike remote tidak ditemukan setelah 25 detik")
            return
        end
        r.OnClientEvent:Connect(function(data)
            print(string.format("[ XKID ⚡ ] Petir! Reason=%s | PenangkalAktif=%s",
                tostring(data and data.Reason), tostring(_G.PenangkalPetir)))
            if not _G.PenangkalPetir then return end
            task.spawn(fleePetir)
        end)
        print("[ XKID ] ⚡ LightningStrike intercept ready")
    end)

    -- 📊 Level
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
                levelUpCount = levelUpCount + 1
                notif("🎉 Level Up! #"..levelUpCount,
                    "Level "..data.Level.." | XP "..data.XP.."/"..data.Needed, 6)
            end
        end)
    end)

    -- 🔔 Notifikasi game
    task.spawn(function()
        local r
        for i=1,15 do r=getR("Notification"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(msg)
            if type(msg)~="string" then return end
            local ml = msg:lower()
            if ml:find("hujan") then
                notif("🌧 Hujan!", "Tanaman tumbuh lebih cepat", 4)
            elseif ml:find("petir") or ml:find("gosong") then
                notif("⚡ Petir!", msg, 4)
            elseif ml:find("mandi") or ml:find("kotor") or ml:find("segar") then
                notif("🚿 Perlu Mandi!", msg, 4)
                if _G.AutoMandi then task.delay(0.5, goMandi) end
            end
        end)
    end)

    -- 🌾 Harvest count
    task.spawn(function()
        local r
        for i=1,15 do r=getR("HarvestCrop"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(cropName, qty)
            harvestCount = harvestCount + (tonumber(qty) or 1)
            print(string.format("[ XKID 🌾 ] Server confirm panen: %s x%d | Total: %d",
                tostring(cropName), tonumber(qty) or 1, harvestCount))
        end)
    end)

    -- ✅ Auto Confirm
    task.spawn(function()
        local r
        for i=1,15 do r=getR("ConfirmAction"); if r then break end; task.wait(1) end
        if not r or not r:IsA("RemoteFunction") then return end
        r.OnClientInvoke = function(data)
            if _G.AutoConfirm then
                print("[ XKID ✅ ] Auto Confirm: " .. tostring(data))
                return true
            end
            return nil
        end
    end)

    print("[ XKID ] ══ ALL INTERCEPTS READY ══")
end

-- ════════════════════════════════════════════════
--  BUILD UI — AURORA v18
-- ════════════════════════════════════════════════

Win:TabSection("Farming")
local TabFarm    = Win:Tab("Farm",    "wheat")
local TabBibit   = Win:Tab("Bibit",   "shopping-cart")
local TabJual    = Win:Tab("Jual",    "coins")
local TabHarvest = Win:Tab("Harvest", "scissors")

Win:TabSection("Utility")
local TabTP    = Win:Tab("Teleport", "map-pin")
local TabPetir = Win:Tab("Petir",    "zap")
local TabSet   = Win:Tab("Setting",  "settings")

-- ════════════════════════════════════════════════
--  TAB: FARM
-- ════════════════════════════════════════════════
local FarmPage = TabFarm:Page("Auto Farm", "wheat")
local FarmSec  = FarmPage:Section("Kontrol", "Left")
local FarmCfg  = FarmPage:Section("Konfigurasi", "Right")

FarmSec:Label("Scan Lahan dulu sebelum mulai!")

FarmSec:Toggle("Full Auto Farm", "AutoFarmToggle", false,
    "Siklus lengkap: Beli → Tanam → Tunggu → Harvest → Jual",
    function(v)
        _G.AutoFarm = v
        if not v then notif("Auto Farm", "Dihentikan", 2); return end
        if #LahanCache == 0 then scanLahan(true) end
        if #LahanCache == 0 then
            notif("⚠️ Error", "Scan Lahan dulu di tab Teleport!", 5)
            _G.AutoFarm = false; return
        end
        SiklusCount = 0
        notif("🔥 Auto Farm ON", #LahanCache.." lahan | "..selectedBibit, 4)
        task.spawn(function()
            while _G.AutoFarm do
                SiklusCount = SiklusCount + 1
                -- Beli
                local ok, msg = beliBibit(selectedBibit, jumlahBeli)
                notif(ok and "🛒 Beli ✅" or "🛒 ❌", msg, 2)
                if not _G.AutoFarm then break end
                task.wait(1)

                -- [FIX-5] Tanam: TP ke tiap lahan dulu, baru PlantCrop
                local planted = 0
                for _, pos in ipairs(LahanCache) do
                    if not _G.AutoFarm then break end
                    -- TP ke dekat lahan
                    local root = getRoot()
                    if root then
                        root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
                        task.wait(0.2)
                    end
                    if fireEv("PlantCrop", pos) then planted = planted + 1 end
                    task.wait(dTanam)
                end
                notif("🌱 Tanam", planted.."/"..#LahanCache.." plot", 2)
                if not _G.AutoFarm then break end

                -- Tunggu panen
                local w = 0
                while w < waitPanen and _G.AutoFarm do task.wait(1); w = w + 1 end
                if not _G.AutoFarm then break end

                -- Harvest
                local h = autoHarvestAll()
                if h > 0 then notif("🌾 Harvest", h.." tanaman punya kita", 2) end
                task.wait(1)

                -- Mandi
                if _G.AutoMandi then goMandi(); task.wait(3) end

                -- Jual
                local sOk, sMsg = jualSemua()
                notif(sOk and "💰 Jual ✅" or "💰 ❌", sMsg or "", 3)
                task.wait(2)
            end
            notif("⛔ Farm Stop", "Siklus: "..SiklusCount.." | Earned: "..totalEarned.."💰", 4)
        end)
    end)

FarmSec:Toggle("Auto Tanam Loop", "AutoTanamToggle", false,
    "Tanam terus ke semua lahan, TP ke tiap plot",
    function(v)
        _G.AutoTanam = v
        -- [FIX-4] Cancel handle lama sebelum spawn baru
        if TanamLoop then pcall(function() task.cancel(TanamLoop) end); TanamLoop=nil end
        if v then
            TanamLoop = task.spawn(function()
                while _G.AutoTanam do
                    if #LahanCache == 0 then scanLahan(true) end
                    local c = 0
                    for _, pos in ipairs(LahanCache) do
                        if not _G.AutoTanam then break end
                        -- [FIX-5] TP ke lahan dulu
                        local root = getRoot()
                        if root then
                            root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
                            task.wait(0.2)
                        end
                        if fireEv("PlantCrop", pos) then c = c + 1 end
                        task.wait(dTanam)
                    end
                    notif("🌱 Tanam", c.." plot", 2)
                    task.wait(5)
                end
            end)
            notif("Auto Tanam", "ON — TP ke tiap lahan", 3)
        else
            notif("Auto Tanam", "OFF", 2)
        end
    end)

FarmSec:Toggle("Auto Mandi Tiap Siklus", "AutoMandiToggle", false,
    "Pergi mandi otomatis setiap selesai satu siklus farm",
    function(v) _G.AutoMandi = v end)

FarmSec:Button("⛔ STOP SEMUA", "Matikan semua fitur sekarang", stopSemua)

-- [FIX-7] Slider sync: default 5, callback v*0.1 → dTanam=0.5
FarmCfg:Slider("Delay Tanam (x0.1 dtk)", "SliderTanam", 1, 30, 5,
    function(v) dTanam = v * 0.1 end,
    "5 = 0.5 detik | 10 = 1.0 detik | 30 = 3.0 detik")

FarmCfg:Slider("Tunggu Panen (detik)", "SliderPanen", 10, 300, 60,
    function(v) waitPanen = v end,
    "Waktu tunggu sebelum harvest dimulai")

FarmCfg:Label("Radius deteksi lahan: 15 studs")
FarmCfg:Label("Blacklist NPC Penjual: 25 studs")

-- ════════════════════════════════════════════════
--  TAB: BIBIT
-- ════════════════════════════════════════════════
local BibitPage  = TabBibit:Page("Beli Bibit", "shopping-cart")
local BibitLeft  = BibitPage:Section("Pilih & Beli", "Left")
local BibitRight = BibitPage:Section("Beli Cepat", "Right")

BibitLeft:Dropdown("Pilih Bibit", "BibitDropdown", bibitNames,
    function(val) selectedBibit = val; notif("Bibit Dipilih", val, 2) end,
    "Pilih jenis bibit yang akan dibeli")

BibitLeft:Slider("Jumlah Beli", "SliderBeli", 1, 99, 1,
    function(v) jumlahBeli = v end,
    "Jumlah bibit per transaksi beli")

BibitLeft:Button("🛒 Beli Sekarang", "Beli bibit dipilih sejumlah slider",
    function()
        task.spawn(function()
            local ok, msg = beliBibit(selectedBibit, jumlahBeli)
            notif(ok and "🛒 Beli ✅" or "❌ Gagal", msg, 4)
        end)
    end)

BibitLeft:Button("📋 Cek Stok Bibit", "Lihat stok bibit di toko",
    function()
        task.spawn(function()
            local ok, res = invokeRF("RequestShop","GET_LIST")
            if not ok then notif("❌","Gagal",3); return end
            local data = unwrap(res)
            if not data or not data.Seeds then notif("❌","Data kosong",3); return end
            PlayerData.Coins = data.Coins or PlayerData.Coins
            local txt = "💰 Coins: "..tostring(data.Coins).."\n\n"
            for _, s in ipairs(data.Seeds) do
                txt = txt .. (s.Locked and "🔒 " or "✅ ")
                    ..s.Name.."  x"..s.Owned.."  ("..s.Price.."💰)\n"
            end
            notif("🛒 Bibit Shop", txt, 10)
        end)
    end)

for _, b in ipairs(BIBIT_LIST) do
    local bb = b
    BibitRight:Button(bb.name.."  "..bb.price.."💰",
        "Min Level "..bb.minLv,
        function()
            task.spawn(function()
                selectedBibit = bb.name
                local ok, msg = beliBibit(bb.name, jumlahBeli)
                notif(ok and "✅ Beli" or "❌", msg, 3)
            end)
        end)
end

-- ════════════════════════════════════════════════
--  TAB: JUAL
-- ════════════════════════════════════════════════
local JualPage  = TabJual:Page("Jual Hasil", "coins")
local JualLeft  = JualPage:Section("Jual Semua", "Left")
local JualRight = JualPage:Section("Jual Per Item", "Right")

JualLeft:Label("RequestSell:InvokeServer SELL — Cobalt ✅")

JualLeft:Button("💰 Jual Semua Sekarang", "Jual semua item di inventori",
    function()
        task.spawn(function()
            local ok, msg = jualSemua()
            notif(ok and "💰 Jual ✅" or "❌ Gagal", msg, 4)
        end)
    end)

JualLeft:Toggle("Auto Sell Loop (30s)", "AutoSellToggle", false,
    "Jual semua item otomatis tiap 30 detik",
    function(v)
        _G.AutoSell = v
        if v then
            SellLoop = task.spawn(function()
                while _G.AutoSell do
                    local ok, msg = jualSemua()
                    notif(ok and "💰 Auto Sell ✅" or "❌", msg, 3)
                    task.wait(30)
                end
            end)
            notif("Auto Sell", "ON — tiap 30 detik", 3)
        else
            if SellLoop then pcall(function() task.cancel(SellLoop) end); SellLoop=nil end
            notif("Auto Sell", "OFF", 2)
        end
    end)

-- [FIX-8] Lihat Inventory — tampilkan Items, bukan raw response
JualLeft:Button("📋 Lihat Inventory Hasil Panen", "Cek item hasil panen yang bisa dijual",
    function()
        task.spawn(function()
            local data, items = getInventoryDisplay()
            if not data then
                notif("❌ Gagal", items or "Tidak ada response", 4)
                return
            end

            if not items or #items == 0 then
                notif("📦 Inventory Kosong",
                    "Coins: "..tostring(data.Coins).."\n\nTidak ada hasil panen.\nLihat console F9 untuk debug.", 6)
                return
            end

            local txt = "💰 Coins: "..tostring(data.Coins).."\n\n"
            local adaItem = false
            for _, item in ipairs(items) do
                local nama    = item.Name or item.name or "?"
                local display = item.DisplayName or item.displayName or nama
                local owned   = item.Owned or item.owned or item.Amount or item.amount or 0
                local price   = item.Price or item.price or item.SellPrice or 0
                if owned > 0 then
                    txt = txt .. "✅ "..display.."  x"..owned.."  ("..price.."💰/pcs)\n"
                    adaItem = true
                else
                    txt = txt .. "⬜ "..display.."  (kosong)\n"
                end
            end

            if not adaItem then
                txt = txt .. "\n— Semua item kosong —"
            end

            notif("📦 Inventory Panen", txt, 12)
        end)
    end)

for _, item in ipairs(ITEM_LIST) do
    local it = item
    JualRight:Button("Jual "..it.name.."  "..it.price.."💰/pcs",
        "Jual semua stok "..it.name,
        function()
            task.spawn(function()
                local data, items = getInventoryDisplay()
                local owned = 0
                if items then
                    for _, i in ipairs(items) do
                        local nm = i.Name or i.name or ""
                        if nm == it.name then
                            owned = i.Owned or i.owned or i.Amount or 0
                            break
                        end
                    end
                end
                if owned == 0 then notif("⬜ "..it.name,"Stok kosong",3); return end
                local ok, msg, earned = jualItem(it.name, owned)
                notif(ok and "💰 Jual ✅" or "❌",
                    it.name.." x"..owned..(ok and " | +"..earned.."💰" or " | "..(msg or "")), 4)
            end)
        end)
end

-- ════════════════════════════════════════════════
--  TAB: HARVEST
-- ════════════════════════════════════════════════
local HarvPage  = TabHarvest:Page("Auto Harvest", "scissors")
local HarvLeft  = HarvPage:Section("Harvest Control", "Left")
local HarvRight = HarvPage:Section("Info & Fix", "Right")

HarvLeft:Toggle("Auto Harvest", "AutoHarvToggle", false,
    "Harvest hanya tanaman di atas lahan kita",
    function(v)
        _G.AutoHarvest = v
        if v then
            if #LahanCache == 0 then
                notif("⚠️", "Scan Lahan dulu di tab Teleport!", 5)
                _G.AutoHarvest = false; return
            end
            HarvestLoop = task.spawn(function()
                while _G.AutoHarvest do
                    local h = autoHarvestAll()
                    if h > 0 then notif("🌾 Harvest", h.." tanaman punya kita", 2) end
                    task.wait(harvestInterval)
                end
            end)
            notif("Auto Harvest", "ON — tiap "..harvestInterval.."s", 3)
        else
            if HarvestLoop then
                pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil
            end
            notif("Auto Harvest", "OFF | Total: "..harvestCount.."×", 3)
        end
    end)

HarvLeft:Slider("Interval (detik)", "SliderHarv", 5, 60, 10,
    function(v) harvestInterval = v end,
    "Jeda antar sesi harvest otomatis")

HarvLeft:Button("🌾 Harvest Sekali Sekarang", "Harvest semua tanaman punya kita",
    function()
        task.spawn(function()
            if #LahanCache == 0 then
                notif("⚠️", "Scan Lahan dulu!", 4); return
            end
            notif("🌾 Harvest", "Memulai...", 2)
            local h = autoHarvestAll()
            notif("✅ Harvest Selesai",
                h > 0 and h.." tanaman dipanen" or "Tidak ada tanaman matang", 3)
        end)
    end)

HarvLeft:Button("🗑 Reset Counter Panen", "Reset hitungan total panen",
    function() harvestCount = 0; notif("Reset", "Counter panen di-reset", 2) end)

HarvRight:Paragraph("Fix v18",
    "[FIX-1] Hanya harvest tanaman dalam radius 15 studs dari LahanCache (punya kita)\n\n[FIX-3] Skip tanaman dekat NPC Penjual (radius 25 studs) agar menu jual tidak muncul")

HarvRight:Paragraph("Tips",
    "Scan Lahan dulu sebelum harvest.\nAktifkan Penangkal Petir saat harvest.\nLihat console F9 untuk log detail.")

-- ════════════════════════════════════════════════
--  TAB: TELEPORT
-- ════════════════════════════════════════════════
local TpPage  = TabTP:Page("NPC & Posisi", "map-pin")
local TpLeft  = TpPage:Section("Teleport NPC", "Left")
local TpRight = TpPage:Section("Save & Load Posisi", "Right")

TpLeft:Label("5 NPC — Y otomatis dari workspace")

for _, npc in ipairs(NPC_LIST) do
    local n = npc
    TpLeft:Button("🚀 "..n.label,
        string.format("X=%.0f  Z=%.0f", n.x, n.z),
        function()
            local _, y = tpToNPC(n.x, n.z)
            notif("📍 TP", n.label..string.format(" | Y=%.1f", y or 0), 3)
        end)
end

TpLeft:Button("🚿 TP ke Tempat Mandi",
    string.format("X=%d  Z=%d", MANDI.x, MANDI.z), goMandi)

TpLeft:Toggle("Auto Mandi (notif kotor)", "AutoMandiToggle2", false,
    "TP ke mandi saat server kirim notifikasi kotor",
    function(v) _G.AutoMandi = v; notif("Auto Mandi", v and "ON" or "OFF", 2) end)

TpLeft:Button("🔍 Scan Lahan", "Refresh cache posisi lahan (force)",
    function()
        local l = scanLahan(true)
        notif("Scan Lahan", #l.." plot ditemukan", 3)
    end)

TpLeft:Button("📍 Print Posisi Saya", "Cetak koordinat karakter ke console",
    function()
        local pos = getPos()
        if pos then
            notif("📍 Posisi",
                string.format("X=%.2f\nY=%.2f\nZ=%.2f", pos.X, pos.Y, pos.Z), 6)
            print(string.format("[ XKID 📍 ] X=%.4f  Y=%.4f  Z=%.4f", pos.X, pos.Y, pos.Z))
        end
    end)

TpRight:Label("Berdiri di posisi → Save → Load kapanpun")

for i = 1, 5 do
    local idx = i
    TpRight:Button("💾 Save Slot "..idx, "Simpan posisi sekarang ke slot "..idx,
        function()
            local cf = getCF()
            if not cf then notif("❌","Karakter tidak ada",3); return end
            savedPositions[idx] = cf
            local p = cf.Position
            notif("💾 Slot "..idx.." Saved",
                string.format("X=%.1f  Y=%.1f  Z=%.1f", p.X, p.Y, p.Z), 3)
        end)
    TpRight:Button("🚀 Load Slot "..idx, "TP ke posisi tersimpan di slot "..idx,
        function()
            if not savedPositions[idx] then
                notif("❌","Slot "..idx.." kosong! Save dulu",3); return
            end
            tpCFrame(savedPositions[idx])
            local p = savedPositions[idx].Position
            notif("📍 Load Slot "..idx,
                string.format("X=%.1f  Y=%.1f  Z=%.1f", p.X, p.Y, p.Z), 3)
        end)
end

-- ════════════════════════════════════════════════
--  TAB: PETIR
-- ════════════════════════════════════════════════
local PetirPage  = TabPetir:Page("Petir Shield", "zap")
local PetirLeft  = PetirPage:Section("Perlindungan", "Left")
local PetirRight = PetirPage:Section("Titik Aman", "Right")

PetirLeft:Toggle("Penangkal Petir AKTIF", "PenangkalToggle", false,
    "HP lock + flee saat LightningStrike event masuk",
    function(v)
        _G.PenangkalPetir = v
        if v then
            notif("⚡ Penangkal AKTIF",
                fleePos and "Mode: Titik Aman" or "Mode: Naik Awan Y+350", 4)
        else
            notif("⚡ Penangkal", "OFF", 2)
        end
    end)

PetirLeft:Paragraph("Fix v18 — 3 Lapis",
    "[FIX-2] HP di-set LANGSUNG saat event masuk\n(bukan tunggu Heartbeat)\n\n① HP = MaxHP (instant)\n② HP lock Heartbeat 8 detik\n③ TP kabur → tunggu 5 detik → kembali")

PetirLeft:Button("⚡ Test Petir Manual", "Simulasi flee petir untuk test",
    function()
        if not getRoot() then notif("❌","Karakter tidak ada",3); return end
        task.spawn(function()
            notif("⚡ Test", "Simulasi dimulai...", 2)
            fleePetir()
        end)
    end)

PetirLeft:Button("🗑 Reset Counter", "Reset hitungan tangkalan ke 0",
    function() lightningHits = 0; notif("Reset","Counter petir di-reset",2) end)

PetirRight:Label("Titik aman = di dalam bangunan tertutup")

PetirRight:Button("📍 Set Titik Aman (posisi saya)", "Simpan posisi sebagai titik flee",
    function()
        local cf = getCF()
        if cf then
            fleePos = cf
            local p = cf.Position
            notif("✅ Titik Aman Set",
                string.format("X=%.1f  Y=%.1f  Z=%.1f", p.X, p.Y, p.Z), 5)
        else
            notif("❌","Karakter tidak ada",3)
        end
    end)

PetirRight:Button("🗑 Hapus Titik Aman (naik awan)", "Kembali ke mode Y+350",
    function() fleePos=nil; notif("Mode Naik Awan","Titik aman dihapus",3) end)

PetirRight:Paragraph("Info",
    "Counter petir dan status kabur\ntercetak di console F9 setiap event.")

-- ════════════════════════════════════════════════
--  TAB: SETTING
-- ════════════════════════════════════════════════
local SetPage  = TabSet:Page("Setting", "settings")
local SetLeft  = SetPage:Section("Umum", "Left")
local SetRight = SetPage:Section("Info", "Right")

SetLeft:Toggle("Anti AFK", "AntiAFKToggle", false,
    "Jump kecil tiap 2 menit agar tidak di-kick",
    function(v)
        _G.AntiAFK = v
        if v then startAntiAFK() end
        notif("Anti AFK", v and "ON" or "OFF", 3)
    end)

SetLeft:Toggle("Notif Level Up", "NLvUpToggle", true,
    "Tampilkan notifikasi saat level naik",
    function(v) _G.NotifLevelUp = v end)

SetLeft:Toggle("Auto Confirm", "AutoConfirmToggle", false,
    "Auto klik konfirmasi dialog server",
    function(v) _G.AutoConfirm = v; notif("Auto Confirm", v and "ON" or "OFF", 2) end)

SetLeft:Button("⛔ STOP SEMUA", "Matikan semua fitur sekarang", stopSemua)

SetLeft:Button("🔄 Reset Stats", "Reset semua hitungan sesi ke 0",
    function()
        totalEarned=0; harvestCount=0; SiklusCount=0; levelUpCount=0; lightningHits=0
        notif("Reset", "Semua stats di-reset", 2)
    end)

SetRight:Paragraph("Indo Farmer v18.0",
    "XKID HUB — Aurora UI\nSawah Indo — All Bugs Fixed\n\nFix: Harvest filter lahan,\nPetir HP instant, Inventory parse,\nTanam TP, Cache 300s, No double loop")

SetRight:Paragraph("NPC Coords",
    "Penjual  X=-59  Z=-207\nBibit    X=-42  Z=-207\nAlat     X=-41  Z=-100\nSawit    X= 56  Z=-208\nTelur    X=-98  Z=-176\nMandi    X=137  Z=-235")

-- ════════════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════════════
setupIntercepts()

task.spawn(function()
    task.wait(3)
    local l = scanLahan(true)
    notif("🔍 Auto Scan", #l.." lahan ditemukan", 4)
end)

Library:Notification("Indo Farmer v18", "Welcome, "..LocalPlayer.Name.."! All bugs fixed.", 6)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   🌾  INDO FARMER v18.0  — XKID HUB    ║")
print("║   Aurora UI  ·  All Bugs Fixed          ║")
print("║   Player: "..LocalPlayer.Name)
print("╚══════════════════════════════════════════╝")
