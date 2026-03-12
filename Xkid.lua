--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🌾  I N D O   F A R M E R  v20.0  🌾           ║
  ║      XKID HUB  ✦  Aurora UI                         ║
  ║      Fix: Scan NPC · Teleport Akurat                 ║
  ╚═══════════════════════════════════════════════════════╝

  CHANGELOG v20.0:
  [1] Fitur Scan NPC — temukan semua NPC di workspace
  [2] Teleport pakai posisi EXACT dari hasil scan (bukan hardcode Y)
  [3] NPC_OVERRIDE: hasil scan override koordinat default
  [4] Tombol Scan NPC di tab Teleport, hasil tampil di console F9
  [5] tpToNPC pakai CFrame exact NPC jika scan berhasil
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
    "v20.0  |  XKID HUB",
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
local lightningHits   = 0
local levelUpCount    = 0
local totalEarned     = 0
local harvestCount    = 0
local SellLoop        = nil
local HarvestLoop     = nil
local selectedBibit   = "Bibit Padi"
local jumlahBeli      = 1
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

local PENJUAL_X, PENJUAL_Z       = -59, -207
local HARVEST_BLACKLIST_RADIUS   = 25

-- Semua tanaman yang bisa di-harvest via firesignal
local CROP_NAMES = {
    "Padi", "Jagung", "Tomat", "Terong", "Strawberry", "Sawit", "Durian"
}

local ITEM_LIST = {
    { name="Padi",       price=10  },
    { name="Jagung",     price=20  },
    { name="Tomat",      price=30  },
    { name="Terong",     price=50  },
    { name="Strawberry", price=75  },
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

-- ════════════════════════════════════════════════
--  [v20] SISTEM SCAN NPC
--
--  scanAllNPC() → cari SEMUA Model di workspace
--  yang punya Humanoid / HumanoidRootPart.
--  Hasil disimpan di NpcScanResult = {
--    { name, x, y, z, model }
--  }
--  NPC_OVERRIDE[label] = CFrame exact hasil scan
--  → tombol TP pakai ini kalau ada, fallback ke hardcode
-- ════════════════════════════════════════════════
local NpcScanResult = {}   -- semua NPC ditemukan
local NPC_OVERRIDE  = {}   -- label → CFrame exact

-- Kata kunci untuk identifikasi NPC target kita
local NPC_KEYWORDS = {
    "npc", "pedagang", "penjual", "bibit", "alat",
    "toko", "shop", "vendor", "seller", "merchant"
}

local function nameMatchNPC(n)
    n = n:lower()
    for _, kw in ipairs(NPC_KEYWORDS) do
        if n:find(kw) then return true end
    end
    return false
end

-- Scan semua NPC di workspace, return list hasil
local function scanAllNPC()
    NpcScanResult = {}
    local seen = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and not seen[v] then
            seen[v] = true
            -- Cek punya Humanoid (NPC sejati)
            local hasHum = v:FindFirstChildOfClass("Humanoid") ~= nil
            local rootPart = v:FindFirstChild("HumanoidRootPart") or v.PrimaryPart
            if (hasHum or nameMatchNPC(v.Name)) and rootPart then
                table.insert(NpcScanResult, {
                    name  = v.Name,
                    x     = math.floor(rootPart.Position.X * 10 + 0.5) / 10,
                    y     = rootPart.Position.Y,
                    z     = math.floor(rootPart.Position.Z * 10 + 0.5) / 10,
                    model = v,
                    cf    = rootPart.CFrame,
                })
            end
        end
    end
    -- Sort by name
    table.sort(NpcScanResult, function(a, b) return a.name < b.name end)
    return NpcScanResult
end

-- Cocokkan NPC_LIST ke hasil scan berdasarkan jarak XZ terdekat
-- radius max 40 studs dari koordinat hardcode
local function buildNPCOverride()
    NPC_OVERRIDE = {}
    if #NpcScanResult == 0 then return end
    for _, npc in ipairs(NPC_LIST) do
        local bestDist, bestCF = math.huge, nil
        for _, found in ipairs(NpcScanResult) do
            local dx = found.x - npc.x
            local dz = found.z - npc.z
            local d  = math.sqrt(dx*dx + dz*dz)
            if d < bestDist then
                bestDist = d
                bestCF   = found.cf
            end
        end
        if bestCF and bestDist <= 40 then
            NPC_OVERRIDE[npc.label] = bestCF
            print(string.format("[ XKID SCAN ] ✅ %s → match dist=%.1f studs", npc.label, bestDist))
        else
            print(string.format("[ XKID SCAN ] ⚠️  %s → tidak match (dist=%.1f)", npc.label, bestDist))
        end
    end
end

-- Fallback Raycast untuk Y jika scan gagal
local function raycastY(x, z)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local ch = getChar(); if ch then rp.FilterDescendantsInstances = {ch} end
    local res = Workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -1000, 0), rp)
    return res and (res.Position.Y + 3) or 42
end

-- [v20] tpToNPC: pakai override CFrame jika ada, fallback raycast
local function tpToNPC(x, z, label)
    local root = getRoot(); if not root then return false, 0 end
    -- Cek override dari hasil scan
    if label and NPC_OVERRIDE[label] then
        local cf = NPC_OVERRIDE[label]
        -- Offset sedikit agar tidak stuck di dalam NPC
        local offsetCF = cf * CFrame.new(0, 0, 3)
        root.CFrame = offsetCF
        task.wait(0.35)
        return true, offsetCF.Position.Y
    end
    -- Fallback: raycast Y dari koordinat hardcode
    local y = raycastY(x, z)
    root.CFrame = CFrame.new(x, y, z)
    task.wait(0.35)
    return true, y
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
--  [v19] HARVEST via firesignal
--  Kirim firesignal ke HarvestCrop.OnClientEvent
--  untuk setiap jenis tanaman, delay 0.3s antar tanaman
-- ════════════════════════════════════════════════
local function harvestViaSignal()
    local Event = getR("HarvestCrop")
    if not Event then
        notif("❌ Harvest", "HarvestCrop remote tidak ditemukan", 4)
        return 0
    end
    local count = 0
    for _, cropName in ipairs(CROP_NAMES) do
        pcall(function()
            firesignal(Event.OnClientEvent, cropName, 1, cropName)
        end)
        harvestCount = harvestCount + 1
        count = count + 1
        task.wait(0.3)
    end
    return count
end

-- ════════════════════════════════════════════════
--  ⚡ PENANGKAL PETIR
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
    local hum = getHum()
    if hum then hum.Health = hum.MaxHealth end
    petirReturnCF = root.CFrame
    startHpLock(8)
    if fleePos then
        root.CFrame = fleePos
        notif("⚡ Kabur! #"..lightningHits, "→ Titik aman | kembali 5s", 5)
    else
        local pos = root.Position
        root.CFrame = CFrame.new(pos.X, pos.Y + 350, pos.Z)
        notif("⚡ Kabur! #"..lightningHits, "→ Naik awan | kembali 5s", 5)
    end
    task.wait(5)
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

local function getInventoryDisplay()
    local ok, res = invokeRF("RequestSell", "GET_LIST")
    if not ok then return nil, "Remote gagal" end
    local data = res
    if type(res) == "table" and type(res[1]) == "table" then
        data = res[1]
    end
    if type(data) ~= "table" then return nil, "Data bukan table" end
    if data.Coins then PlayerData.Coins = data.Coins end
    local items = data.Items or data.items or data.Inventory
        or data.inventory or data.Products or data.products
    if not items then
        for k, v in pairs(data) do
            if type(v) == "table" and #v > 0 then
                local first = v[1]
                if type(first) == "table" then
                    if first.Name or first.name or first.Price or first.price then
                        items = v; break
                    end
                end
            end
        end
    end
    return data, items
end

-- ════════════════════════════════════════════════
--  MANDI
-- ════════════════════════════════════════════════
local function goMandi()
    tpToNPC(MANDI.x, MANDI.z)
    notif("🚿 Mandi", string.format("X=%d Z=%d", MANDI.x, MANDI.z), 3)
end

-- ════════════════════════════════════════════════
--  STOP ALL
-- ════════════════════════════════════════════════
local function stopSemua()
    _G.AutoSell=false; _G.AutoHarvest=false; _G.AutoMandi=false
    if SellLoop    then pcall(function() task.cancel(SellLoop)    end); SellLoop=nil    end
    if HarvestLoop then pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil end
    notif("⛔ Stop Semua", "Semua fitur dimatikan", 3)
end

-- ════════════════════════════════════════════════
--  INTERCEPTS
-- ════════════════════════════════════════════════
local function setupIntercepts()

    -- ⚡ Petir
    task.spawn(function()
        local r
        for i=1,25 do r=getR("LightningStrike"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
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

    -- ✅ Auto Confirm
    task.spawn(function()
        local r
        for i=1,15 do r=getR("ConfirmAction"); if r then break end; task.wait(1) end
        if not r or not r:IsA("RemoteFunction") then return end
        r.OnClientInvoke = function(data)
            if _G.AutoConfirm then return true end
            return nil
        end
    end)

    print("[ XKID ] ══ ALL INTERCEPTS READY ══")
end

-- ════════════════════════════════════════════════
--  BUILD UI — AURORA v19
-- ════════════════════════════════════════════════

Win:TabSection("Farming")
local TabBibit   = Win:Tab("Bibit",   "shopping-cart")
local TabJual    = Win:Tab("Jual",    "coins")
local TabHarvest = Win:Tab("Harvest", "scissors")

Win:TabSection("Utility")
local TabTP    = Win:Tab("Teleport", "map-pin")
local TabPetir = Win:Tab("Petir",    "zap")
local TabSet   = Win:Tab("Setting",  "settings")

-- ════════════════════════════════════════════════
--  TAB: BIBIT
-- ════════════════════════════════════════════════
local BibitPage  = TabBibit:Page("Beli Bibit", "shopping-cart")
local BibitLeft  = BibitPage:Section("Pilih & Beli", "Left")
local BibitRight = BibitPage:Section("Beli Cepat", "Right")

BibitLeft:Dropdown("Pilih Bibit", "BibitDropdown", bibitNames,
    function(val) selectedBibit = val; notif("Bibit Dipilih", val, 2) end,
    "Pilih jenis bibit")

BibitLeft:Slider("Jumlah Beli", "SliderBeli", 1, 99, 1,
    function(v) jumlahBeli = v end,
    "Jumlah bibit per transaksi")

BibitLeft:Button("🛒 Beli Sekarang", "Beli bibit dipilih",
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
            local txt = "💰 "..tostring(data.Coins).."\n\n"
            for _, s in ipairs(data.Seeds) do
                txt = txt..(s.Locked and "🔒 " or "✅ ")
                    ..s.Name.."  x"..s.Owned.."  ("..s.Price.."💰)\n"
            end
            notif("🛒 Bibit Shop", txt, 10)
        end)
    end)

for _, b in ipairs(BIBIT_LIST) do
    local bb = b
    BibitRight:Button(bb.name.."  "..bb.price.."💰",
        "Min Lv "..bb.minLv,
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

JualLeft:Button("💰 Jual Semua Sekarang", "Jual semua item di inventori",
    function()
        task.spawn(function()
            local ok, msg = jualSemua()
            notif(ok and "💰 Jual ✅" or "❌ Gagal", msg, 4)
        end)
    end)

JualLeft:Toggle("Auto Sell (30s)", "AutoSellToggle", false,
    "Jual otomatis tiap 30 detik",
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

JualLeft:Button("📋 Lihat Inventory", "Cek item hasil panen",
    function()
        task.spawn(function()
            local data, items = getInventoryDisplay()
            if not data then notif("❌ Gagal", items or "Tidak ada response", 4); return end
            if not items or #items == 0 then
                notif("📦 Inventory Kosong", "Coins: "..tostring(data.Coins), 5)
                return
            end
            local txt = "💰 "..tostring(data.Coins).."\n\n"
            for _, item in ipairs(items) do
                local nama  = item.Name or item.name or "?"
                local owned = item.Owned or item.owned or item.Amount or 0
                local price = item.Price or item.price or 0
                txt = txt..(owned>0 and "✅ " or "⬜ ")..nama.."  x"..owned.."  ("..price.."💰)\n"
            end
            notif("📦 Inventory", txt, 10)
        end)
    end)

for _, item in ipairs(ITEM_LIST) do
    local it = item
    JualRight:Button("Jual "..it.name.."  "..it.price.."💰",
        "Jual semua stok "..it.name,
        function()
            task.spawn(function()
                local data, items = getInventoryDisplay()
                local owned = 0
                if items then
                    for _, i in ipairs(items) do
                        local nm = i.Name or i.name or ""
                        if nm == it.name then
                            owned = i.Owned or i.owned or i.Amount or 0; break
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
local HarvRight = HarvPage:Section("Info", "Right")

HarvLeft:Toggle("Auto Harvest (tiap 10s)", "AutoHarvToggle", false,
    "Harvest semua tanaman via firesignal tiap 10 detik",
    function(v)
        _G.AutoHarvest = v
        if v then
            HarvestLoop = task.spawn(function()
                while _G.AutoHarvest do
                    local count = harvestViaSignal()
                    if count > 0 then
                        notif("🌾 Harvest", count.." sinyal dikirim", 2)
                    end
                    task.wait(10)
                end
            end)
            notif("Auto Harvest", "ON — tiap 10 detik", 3)
        else
            if HarvestLoop then
                pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil
            end
            notif("Auto Harvest", "OFF | Total: "..harvestCount.."×", 3)
        end
    end)

HarvLeft:Button("🌾 Harvest Sekali Sekarang", "Kirim firesignal harvest semua tanaman",
    function()
        task.spawn(function()
            notif("🌾 Harvest", "Mengirim sinyal...", 2)
            local count = harvestViaSignal()
            notif("✅ Harvest Selesai", count.." tanaman di-signal", 3)
        end)
    end)

HarvLeft:Button("🗑 Reset Counter", "Reset hitungan total panen",
    function() harvestCount = 0; notif("Reset", "Counter panen di-reset", 2) end)

HarvRight:Paragraph("Tanaman Didukung",
    "Padi · Jagung · Tomat · Terong\nStrawberry · Sawit · Durian\n\nDelay antar tanaman: 0.3 detik")

HarvRight:Paragraph("Info",
    "Harvest via firesignal ke\nHarvestCrop.OnClientEvent\nInterval auto: 10 detik")

-- ════════════════════════════════════════════════
--  TAB: TELEPORT
-- ════════════════════════════════════════════════
local TpPage   = TabTP:Page("NPC & Posisi", "map-pin")
local TpLeft   = TpPage:Section("Teleport NPC", "Left")
local TpRight  = TpPage:Section("Save & Load", "Right")
local TpScan   = TpPage:Section("🔍 Scan NPC", "Right")

-- ── Scan NPC Button ──
TpScan:Label("Scan dulu agar TP akurat ke NPC")

TpScan:Button("🔍 Scan Semua NPC", "Cari semua NPC di workspace & update posisi TP",
    function()
        task.spawn(function()
            notif("🔍 Scan NPC", "Sedang scan workspace...", 2)
            local found = scanAllNPC()
            buildNPCOverride()

            if #found == 0 then
                notif("⚠️ Scan NPC", "Tidak ada NPC ditemukan!\nCoba scan saat sudah masuk game penuh.", 5)
                return
            end

            -- Tampilkan semua NPC ditemukan ke notif
            local txt = "#NPC ditemukan: "..#found.."\n\n"
            for i, n in ipairs(found) do
                txt = txt..string.format("[%d] %s\n    X=%.1f  Y=%.1f  Z=%.1f\n", i, n.name, n.x, n.y, n.z)
                -- Print ke console F9 juga
                print(string.format("[ XKID NPC #%d ] %-30s  X=%-8.1f Y=%-6.1f Z=%-8.1f", i, n.name, n.x, n.y, n.z))
            end

            -- Hitung berapa NPC target yang berhasil di-match
            local matched = 0
            for _, npc in ipairs(NPC_LIST) do
                if NPC_OVERRIDE[npc.label] then matched = matched + 1 end
            end

            notif("✅ Scan Selesai",
                #found.." NPC ditemukan\n"..matched.."/"..#NPC_LIST.." target ter-match\nLihat detail di console F9", 8)
        end)
    end)

TpScan:Button("📋 Status Override NPC", "Cek NPC mana yang sudah ter-match scan",
    function()
        local txt = ""
        for _, npc in ipairs(NPC_LIST) do
            if NPC_OVERRIDE[npc.label] then
                local p = NPC_OVERRIDE[npc.label].Position
                txt = txt..string.format("✅ %s\n   X=%.1f Y=%.1f Z=%.1f\n", npc.label, p.X, p.Y, p.Z)
            else
                txt = txt.."❌ "..npc.label.." (belum scan)\n"
            end
        end
        if txt == "" then txt = "Belum scan. Klik Scan Semua NPC dulu!" end
        notif("📋 Status NPC Override", txt, 12)
    end)

TpScan:Button("🗑 Reset Override", "Hapus hasil scan, kembali ke koordinat hardcode",
    function()
        NPC_OVERRIDE = {}
        NpcScanResult = {}
        notif("Reset Override", "Semua override dihapus, pakai koordinat default", 3)
    end)

-- ── Tombol TP per NPC ──
TpLeft:Label("Scan dulu → TP otomatis ke posisi exact NPC")

for _, npc in ipairs(NPC_LIST) do
    local n = npc
    TpLeft:Button("🚀 "..n.label,
        string.format("Hardcode: X=%.0f  Z=%.0f", n.x, n.z),
        function()
            task.spawn(function()
                local _, y = tpToNPC(n.x, n.z, n.label)
                local src = NPC_OVERRIDE[n.label] and "📡 Scan" or "📌 Hardcode"
                notif("📍 TP", n.label.."\n"..src..string.format(" | Y=%.1f", y or 0), 3)
            end)
        end)
end

TpLeft:Button("🚿 TP ke Mandi",
    string.format("X=%d  Z=%d", MANDI.x, MANDI.z), goMandi)

TpLeft:Toggle("Auto Mandi", "AutoMandiToggle2", false,
    "TP mandi saat server kirim notif kotor",
    function(v) _G.AutoMandi = v; notif("Auto Mandi", v and "ON" or "OFF", 2) end)

TpLeft:Button("📍 Posisi Saya", "Cetak koordinat ke notif & console",
    function()
        local pos = getPos()
        if pos then
            notif("📍 Posisi",
                string.format("X=%.1f  Y=%.1f  Z=%.1f", pos.X, pos.Y, pos.Z), 6)
            print(string.format("[ XKID 📍 ] X=%.4f  Y=%.4f  Z=%.4f", pos.X, pos.Y, pos.Z))
        end
    end)

-- ── Save & Load ──
TpRight:Label("Save posisi → Load kapanpun")

for i = 1, 5 do
    local idx = i
    TpRight:Button("💾 Save Slot "..idx, "Simpan posisi ke slot "..idx,
        function()
            local cf = getCF()
            if not cf then notif("❌","Karakter tidak ada",3); return end
            savedPositions[idx] = cf
            local p = cf.Position
            notif("💾 Slot "..idx, string.format("X=%.1f  Y=%.1f  Z=%.1f", p.X, p.Y, p.Z), 3)
        end)
    TpRight:Button("🚀 Load Slot "..idx, "TP ke posisi slot "..idx,
        function()
            if not savedPositions[idx] then
                notif("❌","Slot "..idx.." kosong",3); return
            end
            tpCFrame(savedPositions[idx])
            local p = savedPositions[idx].Position
            notif("📍 Slot "..idx, string.format("X=%.1f  Y=%.1f  Z=%.1f", p.X, p.Y, p.Z), 3)
        end)
end

-- ════════════════════════════════════════════════
--  TAB: PETIR
-- ════════════════════════════════════════════════
local PetirPage  = TabPetir:Page("Petir Shield", "zap")
local PetirLeft  = PetirPage:Section("Perlindungan", "Left")
local PetirRight = PetirPage:Section("Titik Aman", "Right")

PetirLeft:Toggle("Penangkal Petir", "PenangkalToggle", false,
    "HP lock + flee saat petir",
    function(v)
        _G.PenangkalPetir = v
        notif("⚡ Penangkal", v and (fleePos and "ON — Titik Aman" or "ON — Naik Awan") or "OFF", 3)
    end)

PetirLeft:Paragraph("Cara Kerja",
    "① HP = MaxHP (instant)\n② HP lock 8 detik\n③ Kabur → tunggu 5s → kembali")

PetirLeft:Button("⚡ Test Petir", "Simulasi flee untuk test",
    function()
        if not getRoot() then notif("❌","Karakter tidak ada",3); return end
        task.spawn(fleePetir)
    end)

PetirLeft:Button("🗑 Reset Counter", "Reset hitungan petir",
    function() lightningHits = 0; notif("Reset","Counter petir di-reset",2) end)

PetirRight:Label("Titik aman = di dalam bangunan")

PetirRight:Button("📍 Set Titik Aman", "Simpan posisi sebagai titik flee",
    function()
        local cf = getCF()
        if cf then
            fleePos = cf
            local p = cf.Position
            notif("✅ Titik Aman",
                string.format("X=%.1f  Y=%.1f  Z=%.1f", p.X, p.Y, p.Z), 5)
        else
            notif("❌","Karakter tidak ada",3)
        end
    end)

PetirRight:Button("🗑 Hapus Titik Aman", "Kembali ke mode naik awan Y+350",
    function() fleePos=nil; notif("Mode Naik Awan","Titik aman dihapus",3) end)

-- ════════════════════════════════════════════════
--  TAB: SETTING
-- ════════════════════════════════════════════════
local SetPage  = TabSet:Page("Setting", "settings")
local SetLeft  = SetPage:Section("Umum", "Left")
local SetRight = SetPage:Section("Info", "Right")

SetLeft:Toggle("Anti AFK", "AntiAFKToggle", false,
    "Jump kecil tiap 2 menit",
    function(v)
        _G.AntiAFK = v
        if v then startAntiAFK() end
        notif("Anti AFK", v and "ON" or "OFF", 3)
    end)

SetLeft:Toggle("Notif Level Up", "NLvUpToggle", true,
    "Tampilkan notif saat level naik",
    function(v) _G.NotifLevelUp = v end)

SetLeft:Toggle("Auto Confirm", "AutoConfirmToggle", false,
    "Auto klik konfirmasi dialog",
    function(v) _G.AutoConfirm = v; notif("Auto Confirm", v and "ON" or "OFF", 2) end)

SetLeft:Button("⛔ STOP SEMUA", "Matikan semua fitur", stopSemua)

SetLeft:Button("🔄 Reset Stats", "Reset semua hitungan sesi",
    function()
        totalEarned=0; harvestCount=0; levelUpCount=0; lightningHits=0
        notif("Reset", "Stats di-reset", 2)
    end)

SetRight:Paragraph("Indo Farmer v20.0",
    "XKID HUB — Aurora UI\nSawah Indo")

SetRight:Paragraph("NPC Coords",
    "Penjual  X=-59  Z=-207\nBibit    X=-42  Z=-207\nAlat     X=-41  Z=-100\nSawit    X= 56  Z=-208\nTelur    X=-98  Z=-176\nMandi    X=137  Z=-235")

-- ════════════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════════════
setupIntercepts()

Library:Notification("Indo Farmer v20", "Welcome, "..LocalPlayer.Name.."! Scan NPC dulu di tab Teleport.", 6)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   🌾  INDO FARMER v20.0  — XKID HUB    ║")
print("║   Aurora UI  ·  Scan NPC System         ║")
print("║   Fix: TP Akurat + Harvest Signal       ║")
print("║   Player: "..LocalPlayer.Name)
print("╚══════════════════════════════════════════╝")
