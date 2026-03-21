--[[
╔═══════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.24  🌟              ║
║                  Aurora UI  ·  Pro Edition               ║
╠═══════════════════════════════════════════════════════════╣
║  Farming  ·  Shop  ·  Teleport  ·  Player                ║
║  Security  ·  Setting                                    ║
╠═══════════════════════════════════════════════════════════╣
║  CHANGELOG v5.24:                                         ║
║  [FIX] Scan plot: scan semua BasePart + cluster          ║
║  [FIX] ALL_PLOTS global untuk harvest reliable           ║
║  [FIX] Area tidak match → auto fallback ALL_PLOTS        ║
║  [FIX] Grid sort: tanam urut row by row                 ║
║  [FIX] Fishing hold: cast(true)→hold→cast(false,depth)  ║
║  [FIX] Area dropdown auto-set saat scan                 ║
║  [KEEP] Semua fix v5.7 tetap ada                        ║
╚═══════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService   = game:GetService("TeleportService")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")
local LP          = Players.LocalPlayer

local function getChar() return LP.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function notify(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
    print(string.format("[XKID] %s | %s", t, tostring(b)))
end

local lastCFrame
RunService.Heartbeat:Connect(function()
    local r = getRoot(); if r then lastCFrame = r.CFrame end
end)

local function getBridge()
    local bn = RS:FindFirstChild("BridgeNet2")
    return bn and bn:FindFirstChild("dataRemoteEvent")
end
local function getFishEv(name)
    local fr = RS:FindFirstChild("FishRemotes")
    return fr and fr:FindFirstChild(name)
end

local LOG_MAX = 30
local logLines = {}
local function xlog(tag, msg, isError)
    local entry = string.format("[%s][%s] %s", os.date("%H:%M:%S"), tag, msg)
    table.insert(logLines, 1, entry)
    if #logLines > LOG_MAX then table.remove(logLines) end
    print(entry)
    if isError then
        pcall(function() Library:Notification("❌ "..tag, msg:sub(1,80), 5) end)
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   CROP DATA                             │
-- └─────────────────────────────────────────────────────────┘
local CROPS = {
    { name="AppleTree", seed="Bibit Apel",      icon="🍎", price=15,       sell=45,       color={0.8,0.1,0.1}  },
    { name="Padi",      seed="Bibit Padi",      icon="🌾", price=15,       sell=20,       color={0.9,0.8,0.2}  },
    { name="Melon",     seed="Bibit Melon",     icon="🍈", price=15,       sell=20,       color={0.4,0.8,0.2}  },
    { name="Tomat",     seed="Bibit Tomat",     icon="🍅", price=15,       sell=20,       color={0.9,0.2,0.1}  },
    { name="Sawi",      seed="Bibit Sawi",      icon="🥬", price=15,       sell=20,       color={0.298,0.600,0} },
    { name="Coconut",   seed="Bibit Kelapa",    icon="🥥", price=100,      sell=140,      color={0.6,0.4,0.1}  },
    { name="Daisy",     seed="Bibit Daisy",     icon="🌼", price=5000,     sell=6000,     color={1.0,0.95,0.3} },
    { name="FanPalm",   seed="Bibit FanPalm",   icon="🌴", price=100000,   sell=102000,   color={0.1,0.5,0.1}  },
    { name="SunFlower", seed="Bibit SunFlower", icon="🌻", price=2000000,  sell=2010000,  color={1.0,0.8,0.0}  },
    { name="Sawit",     seed="Bibit Sawit",     icon="🪴", price=80000000, sell=80100000, color={0.2,0.4,0.05} },
}
local CROP_VALID = {}
for _, c in ipairs(CROPS) do CROP_VALID[c.name] = true end
local cropDropNames = {}
for _, c in ipairs(CROPS) do table.insert(cropDropNames, c.icon.." "..c.seed) end

-- ┌─────────────────────────────────────────────────────────┐
-- │  [FIX v5.4] SEED INVENTORY CACHE                       │
-- │  Listen OnClientEvent key "\3"                         │
-- │  { ["\3"] = { { {cropName, count}, ... } } }           │
-- │  → SeedInventory[cropName] = { slot, count }           │
-- │  Support 9 slot sesuai data spy log                    │
-- └─────────────────────────────────────────────────────────┘
local SeedInventory = {}

-- ┌─────────────────────────────────────────────────────────┐
-- │  [NEW v5.24] HARVEST CACHE                              │
-- │  Listen OnClientEvent key "\r" (\x0d)                  │
-- │  Server kirim data crop ready:                         │
-- │  cropName, cropPos, sellPrice, seedColor, drops, timer │
-- │  Kita cache lalu kirim balik saat harvest              │
-- └─────────────────────────────────────────────────────────┘
local HarvestCache = {}
-- Format: list of { cropName, cropPos, sellPrice, seedColor, drops, timerStart, timerEnd }

local function updateHarvestCache(data)
    if type(data) ~= "table" then return end

    -- [FIX v5.24] KONFIRMASI dari SimpleSpy:
    -- OnClientEvent pakai key "\r" (carriage return = \x0d)
    -- FireServer pakai key "\13" (octal escape)
    -- Keduanya sama secara byte (ASCII 13) tapi Lua bedakan!
    local cropData = data["\r"] or data["\13"] or data[string.char(13)] or data[13]

    -- Debug: log semua key
    local keyDebug = ""
    for k in pairs(data) do
        if type(k) == "string" then
            local hex = ""
            for i = 1, math.min(#k, 4) do
                hex = hex .. string.format("%02x", k:byte(i))
            end
            keyDebug = keyDebug .. "0x"..hex.." "
        elseif type(k) == "number" then
            keyDebug = keyDebug .. "int"..k.." "
        end
    end
    xlog("BRIDGE_KEYS", keyDebug, false)

    if not cropData then return end

    local timerRaw = data["\2"] or data["\x02"] or data[string.char(2)] or data[2]
    local timerStart = 0
    local timerEnd   = 50
    if type(timerRaw) == "table" then
        timerStart = timerRaw[1] or 0
        timerEnd   = timerRaw[2] or (timerStart + 50)
    end

    for _, crop in ipairs(cropData) do
        if type(crop) == "table" and crop.cropName and crop.cropPos then
            table.insert(HarvestCache, {
                cropName  = crop.cropName,
                cropPos   = crop.cropPos,
                sellPrice = crop.sellPrice or 20,
                seedColor = crop.seedColor or {0.298, 0.600, 0},
                drops     = crop.drops or {},
                timerStart= timerStart,
                timerEnd  = timerEnd,
            })
            xlog("HARVEST", string.format(
                "✅ %s pos=(%.1f,%.1f,%.1f) t=%d-%d",
                crop.cropName, crop.cropPos.X, crop.cropPos.Y, crop.cropPos.Z,
                timerStart, timerEnd), false)
        end
    end

    if #HarvestCache > 0 then
        notify("🌿 Crop Ready!", #HarvestCache.." tanaman siap panen!", 3)
    end
end

local function updateSeedInventory(data)
    if type(data) ~= "table" then return end
    local inv = data["\3"]
    if not inv then return end
    local list = inv[1]
    if type(list) ~= "table" then return end

    SeedInventory = {}
    for slotIdx, entry in ipairs(list) do
        if type(entry) == "table" and entry.cropName then
            SeedInventory[entry.cropName] = {
                slot  = slotIdx,
                count = entry.count or 0,
            }
            xlog("INV", string.format("slot=%d %s x%d", slotIdx, entry.cropName, entry.count or 0), false)
        end
    end
end

local function startInventoryListener()
    local bridge = getBridge()
    if not bridge then task.delay(2, startInventoryListener); return end
    bridge.OnClientEvent:Connect(function(data)
        pcall(updateSeedInventory, data)
        pcall(updateHarvestCache, data)  -- juga cache harvest data
    end)
    xlog("INV", "Listener aktif", false)
end
startInventoryListener()

-- [FIX v5.24] Fallback: baca slot langsung dari SeedPlanter UI
-- SeedPlanter punya frame/slots yang bisa dibaca namanya
-- Dipakai kalau cache dari OnClientEvent belum terisi
local function readSeedPlanterUI()
    local char = getChar()
    local bp   = LP:FindFirstChild("Backpack")

    local sp = nil
    if char then sp = char:FindFirstChild("SeedPlanter") end
    if not sp and bp then sp = bp:FindFirstChild("SeedPlanter") end
    if not sp then return false end

    -- Cari semua TextLabel dalam SeedPlanter yang isinya nama crop
    local found = 0
    for _, desc in ipairs(sp:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Text ~= "" then
            local txt = desc.Text
            -- Cek apakah text cocok dengan nama seed kita
            for _, crop in ipairs(CROPS) do
                if txt == crop.seed or txt == crop.name or
                   txt:lower():find(crop.name:lower(), 1, true) then
                    -- Ambil slot index dari posisi parent frame
                    local slotNum = nil
                    -- Coba baca dari nama parent (Slot1, Slot2, dll)
                    local parent = desc.Parent
                    while parent and parent ~= sp do
                        local num = parent.Name:match("%d+")
                        if num then slotNum = tonumber(num); break end
                        parent = parent.Parent
                    end
                    if slotNum and not SeedInventory[crop.name] then
                        SeedInventory[crop.name] = { slot=slotNum, count=99 }
                        xlog("INV","UI fallback: "..crop.name.." slot="..slotNum,false)
                        found = found + 1
                    end
                end
            end
        end
    end

    -- Fallback ke-2: kalau UI tidak terbaca, paksa request dari server
    -- dengan "beli 0" untuk trigger server kirim ["\3"]
    if found == 0 then
        local ev = getBridge()
        if ev then
            -- Kirim request dummy untuk trigger server update inventory
            pcall(function()
                ev:FireServer({{ cropName="AppleTree", amount=0 }, "\x07"})
            end)
            xlog("INV","Request dummy dikirim untuk trigger server update",false)
        end
    end

    return found > 0
end

-- [FIX v5.24] Force refresh inventory — panggil ini kalau cache kosong
local function forceRefreshInventory()
    -- Coba baca dari UI SeedPlanter dulu
    local uiOk = readSeedPlanterUI()

    -- Kalau UI tidak berhasil, trigger server dengan beli dummy
    if not uiOk then
        local ev = getBridge()
        if ev then
            pcall(function()
                ev:FireServer({{ cropName="Sawi", amount=0 }, "\x07"})
            end)
            xlog("INV","Force request ke server...",false)
            -- Tunggu sebentar lalu cek lagi
            task.delay(2, function()
                if next(SeedInventory) ~= nil then
                    local txt=""
                    for k,v in pairs(SeedInventory) do
                        txt=txt..string.format("[%d]%s ",v.slot,k)
                    end
                    notify("✅ Inventory",txt,5)
                else
                    notify("⚠ Inventory","Server belum kirim data!\nCoba beli 1 bibit dulu.",5)
                end
            end)
        end
    else
        local txt=""
        for k,v in pairs(SeedInventory) do txt=txt..string.format("[%d]%s ",v.slot,k) end
        notify("✅ Inventory (UI)","Slot terdeteksi:\n"..txt,5)
    end
end

local function getSlotIdx(crop)
    local entry = SeedInventory[crop.name]
    if entry then return entry.slot, entry.count end
    return nil, 0
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  [FIX v5.24] AREA / PLOT DATA                          │
-- │  Dari full scan:                                        │
-- │  - 8 Land Part di index 51,52,53,54,64,65,66,67        │
-- │  - Setiap Land = 1 hitPart                             │
-- │  - hitPosition = posisi Land + offset Y sedikit        │
-- │    (player sentuh permukaan lahan dari atas)           │
-- │  - 1 Land bisa tanam berkali2 di posisi sama           │
-- │    (server manage slot internal per lahan)             │
-- └─────────────────────────────────────────────────────────┘

-- Scan otomatis cari semua Part bernama "Land" di workspace
local AREA_NAMES = {}
local AREA_PLOTS = {}
local AREA_PARTS = {}
local ALL_PLOTS  = {}

-- ┌─────────────────────────────────────────────────────────┐
-- │  [v5.24] AREA / PLOT DATA                              │
-- │  Per Land individual + group areas                     │
-- │  Grid aesthetic: zigzag / spiral dari tengah           │
-- └─────────────────────────────────────────────────────────┘
local AREA_NAMES  = {}
local AREA_PLOTS  = {}
local AREA_PARTS  = {}
local ALL_PLOTS   = {}
local LAND_LIST   = {}  -- list Land objects untuk dropdown individual

-- Generate grid positions dalam 1 Land (aesthetic zigzag)
local function generateLandSlots(obj, idx)
    local center = obj.Position
    local sW = math.max(obj.Size.X, obj.Size.Z)  -- lebar (dimensi besar)
    local sD = math.min(obj.Size.X, obj.Size.Z)  -- dalam (dimensi kecil)

    -- Hitung grid 5x4 = 20 slot dengan padding 15%
    local COLS   = 5
    local ROWS   = 4
    local padW   = sW * 0.15
    local padD   = sD * 0.15
    local useW   = sW - padW * 2
    local useD   = sD - padD * 2
    local spaceW = COLS > 1 and useW / (COLS - 1) or 0
    local spaceD = ROWS > 1 and useD / (ROWS - 1) or 0
    if spaceW < 1.5 then spaceW = 2 end
    if spaceD < 1.5 then spaceD = 2 end

    local startW = center.X - useW / 2
    local startD = center.Z - useD / 2
    local hitY   = center.Y + 0.5

    -- Aesthetic: zigzag (baris genap = kanan ke kiri)
    local slots = {}
    for row = 0, ROWS - 1 do
        local cols = {}
        for col = 0, COLS - 1 do
            table.insert(cols, col)
        end
        -- Balik kolom di baris genap (zigzag)
        if row % 2 == 1 then
            local reversed = {}
            for i = #cols, 1, -1 do table.insert(reversed, cols[i]) end
            cols = reversed
        end
        for _, col in ipairs(cols) do
            local slotNum = row * COLS + col + 1
            local hitPos = Vector3.new(
                startW + col * spaceW,
                hitY,
                startD + row * spaceD
            )
            table.insert(slots, {
                part    = obj,
                obj     = obj,
                pos     = hitPos,
                idx     = idx,
                slot    = slotNum,
                name    = string.format("Land[%d]s[%d]", idx, slotNum),
                landIdx = idx,
            })
        end
    end
    return slots
end

local function buildAreaData()
    AREA_NAMES = {}
    AREA_PLOTS = {}
    AREA_PARTS = {}
    ALL_PLOTS  = {}
    LAND_LIST  = {}

    local allCh = Workspace:GetChildren()
    local lands  = {}

    -- Cari semua Part bernama "Land"
    for i, obj in ipairs(allCh) do
        if obj.Name == "Land" and obj:IsA("BasePart") then
            table.insert(lands, {idx=i, obj=obj})
        end
    end

    -- Sort: Z negatif (Area Utama) dulu, dalam area sort by X
    table.sort(lands, function(a, b)
        local az, bz = a.obj.Position.Z, b.obj.Position.Z
        if math.abs(az - bz) > 20 then return az < bz end
        return a.obj.Position.X < b.obj.Position.X
    end)

    -- Nomori ulang secara berurutan (Land 1, Land 2, ...)
    local allUtama = {}
    local allJauh  = {}

    for num, land in ipairs(lands) do
        local obj  = land.obj
        local idx  = land.idx
        local slots = generateLandSlots(obj, idx)
        local area  = obj.Position.Z < 50 and "Utama" or "Jauh"
        local label = string.format("🌱 Land %d (%s)", num, area)

        table.insert(LAND_LIST, {
            num   = num,
            label = label,
            obj   = obj,
            idx   = idx,
            slots = slots,
            area  = area,
        })

        -- Add ke AREA_PLOTS per Land
        table.insert(AREA_NAMES, label)
        AREA_PLOTS[label] = slots
        AREA_PARTS[label] = {obj}

        -- Kumpulkan per area
        if area == "Utama" then
            for _, s in ipairs(slots) do table.insert(allUtama, s) end
        else
            for _, s in ipairs(slots) do table.insert(allJauh, s) end
        end

        -- ALL_PLOTS
        for _, s in ipairs(slots) do table.insert(ALL_PLOTS, s) end

        xlog("Scan", string.format(
            "%s idx=%d pos=(%.0f,%.0f,%.0f) %d slots",
            label, idx, obj.Position.X, obj.Position.Y, obj.Position.Z, #slots), false)
    end

    -- Group areas
    if #allUtama > 0 then
        local lbl = "🏡 Semua Utama ("..#lands.." Land)"
        -- hitung hanya land utama
        local countUtama = 0
        for _, l in ipairs(LAND_LIST) do if l.area=="Utama" then countUtama=countUtama+1 end end
        lbl = "🏡 Semua Utama ("..countUtama.." Land)"
        table.insert(AREA_NAMES, lbl)
        AREA_PLOTS[lbl] = allUtama
        AREA_PARTS[lbl] = {}
        for _, l in ipairs(LAND_LIST) do
            if l.area=="Utama" then table.insert(AREA_PARTS[lbl], l.obj) end
        end
    end

    if #allJauh > 0 then
        local countJauh = 0
        for _, l in ipairs(LAND_LIST) do if l.area=="Jauh" then countJauh=countJauh+1 end end
        local lbl = "🌿 Semua Jauh ("..countJauh.." Land)"
        table.insert(AREA_NAMES, lbl)
        AREA_PLOTS[lbl] = allJauh
        AREA_PARTS[lbl] = {}
        for _, l in ipairs(LAND_LIST) do
            if l.area=="Jauh" then table.insert(AREA_PARTS[lbl], l.obj) end
        end
    end

    if #ALL_PLOTS > 0 then
        local lbl = "🌍 Semua Lahan ("..#lands.." Land)"
        table.insert(AREA_NAMES, lbl)
        AREA_PLOTS[lbl] = ALL_PLOTS
        AREA_PARTS[lbl] = {}
        for _, l in ipairs(LAND_LIST) do table.insert(AREA_PARTS[lbl], l.obj) end
    end

    xlog("Scan", string.format(
        "Total: %d Land → %d slot (Utama:%d Jauh:%d)",
        #lands, #ALL_PLOTS, #allUtama, #allJauh), false)
end

local function filterPlots(plotList, jumlah, fullMode)
    if fullMode then
        -- Full: pakai semua slot
        return {table.unpack(plotList)}
    end
    local max = math.min(jumlah, #plotList, 20)
    local result = {}
    for i = 1, max do table.insert(result, plotList[i]) end
    return result
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  HELPER: Cari Land Part terdekat dari posisi tertentu   │
-- │  Dipakai untuk tanam (dari posisi player)               │
-- │  dan harvest (dari cropPos yang server kirim)           │
-- └─────────────────────────────────────────────────────────┘
local function findClosestLand(targetPos)
    local closest, minDist = nil, math.huge
    -- Cari dari LAND_LIST yang sudah kita scan
    for _, land in ipairs(LAND_LIST) do
        local d = (land.obj.Position - targetPos).Magnitude
        if d < minDist then
            minDist = d
            closest = land
        end
    end
    return closest, minDist
end

-- Cari BasePart paling dekat dari posisi (generic, semua workspace)
local function findClosestBasePart(targetPos, maxDist)
    maxDist = maxDist or 50
    local closest, minDist = nil, math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local d = (v.Position - targetPos).Magnitude
            if d < minDist and d <= maxDist then
                minDist = d
                closest = v
            end
        end
    end
    return closest, minDist
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  FARM STATE                                             │
-- └─────────────────────────────────────────────────────────┘
local Farm = {
    selectedCrop=CROPS[1], selectedArea="", selectedPola="Normal",
    jumlahTanam=5, fullMode=false,
    autoCycleOn=false, autoCycleTask=nil,
    autoBeli=false, jumlahAutoBeli=10, growDelay=60,
    autoPanen=false, autoPanenTask=nil,
}

local function beliBibit(crop, qty)
    local ev = getBridge()
    if not ev then notify("Farm ❌","BridgeNet2 tidak ada!",5); return false end
    local ok, err = pcall(function()
        ev:FireServer({{ cropName=crop.name, amount=qty }, "\x07"})
    end)
    if not ok then
        notify("Farm ❌","Beli gagal: "..tostring(err):sub(1,60),5)
        xlog("Beli","Error: "..tostring(err):sub(1,60),true)
    else xlog("Beli","OK: "..crop.name.." x"..qty,false) end
    return ok
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  [FIX v5.4] TANAM — slotIdx dari cache server          │
-- └─────────────────────────────────────────────────────────┘
local function tanamPlots()
    local ev = getBridge()
    if not ev then notify("Farm ❌","BridgeNet2 tidak ada!",5); return 0 end

    local slotIdx, stockCount = getSlotIdx(Farm.selectedCrop)

    -- [FIX v5.24] Auto force refresh kalau cache kosong
    if not slotIdx then
        xlog("Tanam","SlotIdx nil, coba force refresh...",false)
        notify("Farm ⏳","Cek inventory...",2)
        forceRefreshInventory()
        task.wait(2.5)
        -- Coba lagi setelah refresh
        slotIdx, stockCount = getSlotIdx(Farm.selectedCrop)
    end

    if not slotIdx then
        notify("Farm ⚠",
            Farm.selectedCrop.seed.." tidak terdeteksi!\n"..
            "Klik 🔄 Refresh Inventory di Farming tab.", 6)
        xlog("Tanam","SlotIdx nil setelah refresh: "..Farm.selectedCrop.name,true)
        return 0
    end

    if stockCount <= 0 then
        notify("Farm ❌", Farm.selectedCrop.seed.." stok habis!\nBeli dulu.", 5)
        xlog("Tanam","Stok 0: "..Farm.selectedCrop.name,true)
        return 0
    end

    local plotList = AREA_PLOTS[Farm.selectedArea]
    -- [FIX v5.24] Fallback ke ALL_PLOTS kalau area tidak match
    if not plotList or #plotList == 0 then
        if #ALL_PLOTS > 0 then
            notify("Farm ⚠","Area tidak match → pakai semua ("..#ALL_PLOTS.." plot)",3)
            plotList = ALL_PLOTS
        else
            notify("Farm ❌","Area kosong! Scan Ulang.",5); return 0
        end
    end

    local maxTanam = Farm.fullMode and stockCount or math.min(Farm.jumlahTanam, stockCount)
    if not Farm.fullMode and maxTanam < Farm.jumlahTanam then
        notify("Farm ⚠","Stok "..stockCount.." → tanam "..maxTanam,3)
    end

    -- [v5.24] Grid zigzag aesthetic + fullMode support
    local filtered = filterPlots(plotList, maxTanam, Farm.fullMode)
    if #filtered == 0 then notify("Farm ❌","0 plot setelah filter",4); return 0 end

    -- Batasi juga oleh stok
    if #filtered > stockCount then
        local tmp = {}
        for i=1,stockCount do table.insert(tmp, filtered[i]) end
        filtered = tmp
    end

    xlog("Tanam",string.format("crop=%s slot=%d stok=%d plot=%d full=%s",
        Farm.selectedCrop.name, slotIdx, stockCount, #filtered,
        tostring(Farm.fullMode)), false)

    local count, failed = 0, 0
    for _, pl in ipairs(filtered) do
        local ok, err = pcall(function()
            -- [FIX v5.24] hitPart = Land Part dari pl.obj (sudah benar)
            -- hitPosition = posisi grid di dalam Land (pl.pos)
            -- Server pakai hitPosition untuk tau slot mana dalam Land
            ev:FireServer({
                { slotIdx=slotIdx, hitPosition=pl.pos, hitPart=pl.obj },
                "\x04"
            })
        end)
        if ok then count=count+1
        else
            failed=failed+1
            xlog("Tanam","Error: "..tostring(err):sub(1,50), failed>=3)
            if failed>=3 then notify("Farm ⚠","3+ error, dihentikan",5); break end
        end
        task.wait(0.2)
    end

    if count>0 then notify("Tanam","✅ "..count.." plot | "..Farm.selectedCrop.seed,3) end
    if failed>0 then notify("Farm","❌ "..failed.." gagal",4) end
    return count
end

local function harvestAll()
    local ev = getBridge()
    if not ev then notify("Farm ❌","BridgeNet2 tidak ada!",5); return 0 end

    local toHarvest = {}

    -- 1. Pakai HarvestCache (data valid dari server \r event)
    if #HarvestCache > 0 then
        toHarvest = {table.unpack(HarvestCache)}
        HarvestCache = {}
        xlog("Harvest","Cache: "..#toHarvest.." tanaman",false)

    else
        -- 2. Fallback: scan workspace untuk tanaman yang ada
        -- Cari semua objek yang namanya = crop kita di workspace
        xlog("Harvest","Cache kosong → scan workspace untuk crop",false)

        local crop = Farm.selectedCrop
        local sc   = crop.color or {0.298,0.600,0}
        local now  = math.floor(tick() * 1000)
        local found = 0

        for _, v in ipairs(Workspace:GetDescendants()) do
            local nm = v.Name:lower()
            if v.Name == crop.name or nm:find(crop.name:lower(),1,true) then
                local cropPart = nil
                if v:IsA("BasePart") then
                    cropPart = v
                elseif v:IsA("Model") then
                    cropPart = v.PrimaryPart or v:FindFirstChildOfClass("BasePart")
                end

                if cropPart then
                    local cropPos = cropPart.Position
                    -- Cari Land Part terdekat dari tanaman ini
                    local closestLand = findClosestLand(cropPos)
                    local hitPart = closestLand and closestLand.obj or cropPart

                    found = found + 1
                    table.insert(toHarvest, {
                        cropName  = crop.name,
                        cropPos   = cropPos,  -- posisi TANAMAN yang real
                        sellPrice = crop.sell,
                        seedColor = sc,
                        drops     = {{
                            name       = "Biji "..crop.seed,
                            coinReward = math.floor(crop.sell * 0.15),
                            icon       = crop.icon or "✨",
                            rarity     = "Common"
                        }},
                        timerStart = now + (found * 70),
                        timerEnd   = now + (found * 70) + 50,
                        hitPart    = hitPart,  -- Land terdekat
                    })
                end
            end
        end

        if found == 0 then
            notify("Panen ⚠",
                "Tidak ada tanaman '"..crop.name.."' di workspace!\n"..
                "Tunggu tanaman tumbuh dulu.", 5)
            return 0
        end
        notify("Panen 🔄","Harvest "..found.." "..crop.name.."...",3)
    end

    local count, failed = 0, 0
    for _, entry in ipairs(toHarvest) do
        local ok, err = pcall(function()
            -- [FIX v5.24] Format persis dari SimpleSpy
            ev:FireServer({
                ["\13"] = {{
                    seedColor = entry.seedColor,
                    cropName  = entry.cropName,
                    cropPos   = entry.cropPos,
                    sellPrice = entry.sellPrice,
                    drops     = entry.drops,
                }},
                ["\2"] = { entry.timerStart, entry.timerEnd }
            })
        end)
        if ok then
            count = count + 1
            xlog("Harvest","✅ "..entry.cropName.." pos=("..
                string.format("%.1f,%.1f,%.1f",
                entry.cropPos.X, entry.cropPos.Y, entry.cropPos.Z)..")",false)
        else
            failed = failed + 1
            xlog("Harvest","❌ "..tostring(err):sub(1,50),false)
        end
        task.wait(0.05)
    end

    if count > 0 then notify("Panen","✅ "..count.." dipanen!",3) end
    if failed > 0 then notify("Farm","❌ "..failed.." gagal",3) end
    return count
end


-- ┌─────────────────────────────────────────────────────────┐
-- │  AUTO PLANT LOOP                                        │
-- │  Tanam semua lahan → tunggu cache/timeout → panen loop │
-- └─────────────────────────────────────────────────────────┘
local AutoLoop = {
    active   = false,
    task     = nil,
    timeout  = 120,   -- max tunggu panen (detik)
    delay    = 2,     -- jeda antar cycle (detik)
    total    = 0,     -- total cycle selesai
}

local function runAutoLoop()
    while AutoLoop.active do
        AutoLoop.total = AutoLoop.total + 1
        notify("🔄 Auto Loop","Cycle #"..AutoLoop.total,2)

        -- Step 1: Beli bibit kalau Auto Beli ON
        if Farm.autoBeli then
            notify("Auto Loop [1/3]","Beli "..Farm.selectedCrop.seed.." x"..Farm.jumlahAutoBeli,2)
            beliBibit(Farm.selectedCrop, Farm.jumlahAutoBeli)
            task.wait(1.5)
        end

        -- Step 2: Tanam semua lahan
        notify("Auto Loop [2/3]","Tanam semua lahan...",2)
        local oldArea = Farm.selectedArea
        local oldFull = Farm.fullMode

        -- Set ke semua lahan
        for _, name in ipairs(AREA_NAMES) do
            if name:find("Semua") then
                Farm.selectedArea = name
                break
            end
        end
        Farm.fullMode = false
        Farm.jumlahTanam = #LAND_LIST  -- 1 per Land = 8 total

        local planted = tanamPlots()
        Farm.selectedArea = oldArea
        Farm.fullMode = oldFull

        if planted == 0 then
            notify("Auto Loop ⚠","Tanam gagal! Retry dalam 10s",4)
            task.wait(10)
        else
            notify("Auto Loop [2/3]","✅ "..planted.." ditanam",2)

            -- Step 3: Tunggu crop ready (cache + timeout)
            notify("Auto Loop [3/3]","Tunggu tanaman tumbuh...",2)
            local waited = 0
            local timeout = AutoLoop.timeout

            while #HarvestCache == 0 and waited < timeout and AutoLoop.active do
                task.wait(1)
                waited = waited + 1
                -- Progress notif tiap 30 detik
                if waited % 30 == 0 then
                    notify("Menunggu...",waited.."s / "..timeout.."s",2)
                end
            end

            if not AutoLoop.active then break end

            -- Step 4: Panen
            notify("Auto Loop [3/3]","Panen sekarang...",2)
            local harvested = harvestAll()
            notify("✅ Cycle #"..AutoLoop.total,
                "Tanam: "..planted.."
Panen: "..harvested.."
Tunggu: "..waited.."s",4)
        end

        -- Jeda sebelum cycle berikutnya
        if AutoLoop.active then
            task.wait(AutoLoop.delay)
        end
    end
    notify("Auto Loop","STOP — Total cycle: "..AutoLoop.total,4)
end

local function runCycle()
    if Farm.autoBeli then
        notify("Cycle [1/4]","Beli "..Farm.selectedCrop.seed.." x"..Farm.jumlahAutoBeli,2)
        beliBibit(Farm.selectedCrop, Farm.jumlahAutoBeli)
        task.wait(1.5)
    end
    notify("Cycle [2/4]","Tanam...",2)
    local planted = tanamPlots()
    if planted==0 then notify("Cycle ⚠","0 plot! Cycle batal.",5); return end
    notify("Cycle [2/4]",planted.." plot",3); task.wait(1)
    notify("Cycle [3/4]","Tunggu "..Farm.growDelay.."s...",3)
    task.wait(Farm.growDelay)
    notify("Cycle [4/4]","Panen...",2)
    local harvested = harvestAll()
    notify("✅ Selesai","Tanam:"..planted.." Panen:"..harvested,4)
    task.wait(1)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  SEND LIKE                                              │
-- └─────────────────────────────────────────────────────────┘
local function sendLike(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        notify("Like","Player tidak valid",2); return false
    end
    local evFolder = RS:FindFirstChild("Events")
    if not evFolder then notify("Like","RS.Events tidak ada",3); return false end
    local likeEv = evFolder:FindFirstChild("SendLike")
    if not likeEv then notify("Like","SendLike tidak ada",3); return false end
    local ok,err = pcall(function() likeEv:FireServer(targetPlayer) end)
    if ok then notify("❤ Like","→ "..targetPlayer.Name,2)
    else xlog("Like","Error: "..tostring(err):sub(1,60),true) end
    return ok
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  ESP PLAYER                                             │
-- └─────────────────────────────────────────────────────────┘
local ESPPl={active=false,data={},conn=nil}
local function _mkPlBill(p)
    if p==LP or ESPPl.data[p] then return end
    if not p.Character then return end
    local head=p.Character:FindFirstChild("Head"); if not head then return end
    local bill=Instance.new("BillboardGui")
    bill.Name="XKID_PESP"; bill.Size=UDim2.new(0,100,0,24)
    bill.StudsOffset=Vector3.new(0,2.5,0); bill.AlwaysOnTop=true
    bill.Adornee=head; bill.Parent=head
    local bg=Instance.new("Frame",bill)
    bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency=0.45; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,4)
    local lbl=Instance.new("TextLabel",bg)
    lbl.Size=UDim2.new(1,-4,1,-4); lbl.Position=UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.fromRGB(255,230,80)
    lbl.TextStrokeColor3=Color3.fromRGB(0,0,0); lbl.TextStrokeTransparency=0.35
    lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold; lbl.Text=p.Name
    ESPPl.data[p]={bill=bill,lbl=lbl}
end
local function _rmPlBill(p)
    if ESPPl.data[p] then pcall(function() ESPPl.data[p].bill:Destroy() end); ESPPl.data[p]=nil end
end
local function startESPPlayer()
    for _,p in pairs(Players:GetPlayers()) do _mkPlBill(p) end
    ESPPl.conn=RunService.Heartbeat:Connect(function()
        if not ESPPl.active then return end
        local myR=getRoot()
        for p,d in pairs(ESPPl.data) do
            if not d.bill or not d.bill.Parent then ESPPl.data[p]=nil
            else
                if myR and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist=math.floor((p.Character.HumanoidRootPart.Position-myR.Position).Magnitude)
                    d.lbl.Text=p.Name.."\n"..dist.."m"
                else d.lbl.Text=p.Name end
            end
        end
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character and not ESPPl.data[p] then _mkPlBill(p) end
        end
    end)
end
local function stopESPPlayer()
    if ESPPl.conn then ESPPl.conn:Disconnect(); ESPPl.conn=nil end
    for p in pairs(ESPPl.data) do _rmPlBill(p) end; ESPPl.data={}
end
Players.PlayerRemoving:Connect(_rmPlBill)
for _,p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        task.wait(0.5); if ESPPl.active then _rmPlBill(p); _mkPlBill(p) end
    end)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  MOVEMENT                                               │
-- └─────────────────────────────────────────────────────────┘
local Move={speed=16,flySpeed=60,noclip=false,noclipConn=nil,jumpConn=nil}
local flyFlying=false; local flyConn=nil; local flyBV=nil; local flyBG=nil

RunService.RenderStepped:Connect(function()
    if flyFlying then return end
    local h=getHum(); if h then h.WalkSpeed=Move.speed end
end)

local function setNoclip(v)
    Move.noclip=v
    if v then
        if Move.noclipConn then Move.noclipConn:Disconnect() end
        Move.noclipConn=RunService.Stepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end)
    else
        if Move.noclipConn then Move.noclipConn:Disconnect(); Move.noclipConn=nil end
        local c=getChar()
        if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
    end
end
local function setInfJump(v)
    if v then
        if Move.jumpConn then Move.jumpConn:Disconnect() end
        Move.jumpConn=UIS.JumpRequest:Connect(function()
            local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else if Move.jumpConn then Move.jumpConn:Disconnect(); Move.jumpConn=nil end end
end

local ControlModule=nil
pcall(function()
    ControlModule=require(LP:WaitForChild("PlayerScripts")
        :WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
end)
local function getMoveVector()
    if ControlModule then
        local ok,result=pcall(function() return ControlModule:GetMoveVector() end)
        if ok and result then return result end
    end
    return Vector3.new(
        (UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0)-(UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
        0,
        (UIS:IsKeyDown(Enum.KeyCode.W) and -1 or 0)+(UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0))
end

local function startFly()
    if flyFlying then return end
    local root=getRoot(); if not root then return end
    local hum=getHum(); if not hum then return end
    flyFlying=true; hum.PlatformStand=true
    flyBV=Instance.new("BodyVelocity",root)
    flyBV.MaxForce=Vector3.new(1e6,1e6,1e6); flyBV.Velocity=Vector3.zero
    flyBG=Instance.new("BodyGyro",root)
    flyBG.MaxTorque=Vector3.new(1e6,1e6,1e6); flyBG.P=1e5; flyBG.D=1e3
    flyConn=RunService.RenderStepped:Connect(function(dt)
        local r2=getRoot(); if not r2 then return end
        local h2=getHum(); if not h2 then return end
        local cam=Workspace.CurrentCamera; local cf=cam.CFrame
        h2.PlatformStand=true; h2:ChangeState(Enum.HumanoidStateType.Physics)
        local md=getMoveVector()
        local look=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
        local right=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z)
        if look.Magnitude>0 then look=look.Unit end
        if right.Magnitude>0 then right=right.Unit end
        local move=right*md.X+look*(-md.Z)
        if move.Magnitude>1 then move=move.Unit end
        local pitch=cf.LookVector.Y; local vVel=0
        if math.abs(pitch)>0.25 then
            local t=math.clamp((math.abs(pitch)-0.25)/(1-0.25),0,1)
            vVel=math.sign(pitch)*t*Move.flySpeed*0.6
        end
        local target=Vector3.new(move.X*Move.flySpeed,vVel,move.Z*Move.flySpeed)
        target=target+Vector3.new(0,Workspace.Gravity*dt,0)
        if move.Magnitude>0 or math.abs(vVel)>0.1 then flyBV.Velocity=target
        else flyBV.Velocity=Vector3.new(0,Workspace.Gravity*dt,0) end
        local flatLook=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
        if flatLook.Magnitude>0.01 then flyBG.CFrame=CFrame.lookAt(r2.Position,r2.Position+flatLook) end
    end)
end
local function stopFly()
    flyFlying=false
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV=nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG=nil end
    local hum=getHum()
    if hum then
        hum.PlatformStand=false; hum.AutoRotate=true; hum.WalkSpeed=Move.speed
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        task.defer(function()
            local h=getHum(); if h then
                h.PlatformStand=false; h.WalkSpeed=Move.speed
                h:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end
end
LP.CharacterAdded:Connect(function()
    task.wait(0.6)
    if flyFlying then
        flyFlying=false
        if flyConn then flyConn:Disconnect(); flyConn=nil end
        if flyBV then pcall(function() flyBV:Destroy() end); flyBV=nil end
        if flyBG then pcall(function() flyBG:Destroy() end); flyBG=nil end
        task.wait(0.3); startFly()
    end
    if Move.noclip and not Move.noclipConn then
        Move.noclipConn=RunService.Stepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end)
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │  TELEPORT                                               │
-- └─────────────────────────────────────────────────────────┘
local function inferPlayer(prefix)
    if not prefix or prefix=="" then return nil end
    local best,bestScore=nil,math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP then
            local score=math.huge
            if p.Name:lower():sub(1,#prefix)==prefix:lower() then score=#p.Name-#prefix
            elseif p.DisplayName:lower():sub(1,#prefix)==prefix:lower() then score=(#p.DisplayName-#prefix)+0.5 end
            if score<bestScore then best=p; bestScore=score end
        end
    end
    return best
end
local function tpToPlayer(prefix)
    if not prefix or prefix=="" then notify("TP","Ketik nama dulu!",2); return end
    local p=inferPlayer(prefix)
    if not p then notify("TP","'"..prefix.."' tidak ditemukan",3); return end
    if not p.Character then notify("TP",p.Name.." tidak ada karakter",2); return end
    local hrp=p.Character:FindFirstChild("HumanoidRootPart"); local root=getRoot()
    if hrp and root then root.CFrame=hrp.CFrame*CFrame.new(0,0,3); notify("TP","→ "..p.Name,2) end
end
local SavedLoc={nil,nil,nil,nil,nil}

-- ┌─────────────────────────────────────────────────────────┐
-- │  RESPAWN CEPAT                                          │
-- │  Mati → spawn ulang → TP ke posisi semula              │
-- └─────────────────────────────────────────────────────────┘
local Respawn = {savedPosition=nil, busy=false}

-- Simpan posisi terus menerus
RunService.Heartbeat:Connect(function()
    local root=getRoot()
    if root then Respawn.savedPosition=root.CFrame end
end)

local function doRespawn()
    if Respawn.busy then notify("Respawn","Sedang proses...",2); return end
    if not Respawn.savedPosition then
        notify("Respawn","Posisi belum tersimpan!",2); return
    end

    Respawn.busy = true
    local savedCF = Respawn.savedPosition

    notify("Respawn","Ganti karakter...",2)

    -- Bunuh karakter sekarang
    local hum = getHum()
    if hum then
        hum.Health = 0
    end

    -- Tunggu karakter baru spawn
    local newChar = LP.CharacterAdded:Wait()
    task.wait(1)  -- tunggu karakter fully loaded

    -- TP ke posisi semula
    local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
    if hrp then
        hrp.CFrame = savedCF
        notify("✅ Respawn","Kembali ke posisi!",2)
    end

    Respawn.busy = false
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  [FIX v5.24] FISHING SYSTEM                            │
-- │  Dari debug log, urutan event server:                  │
-- │  ← MiniGame: Start  (bar muncul = saatnya complete!)  │
-- │  ← MiniGame: Start  (kadang 2x)                       │
-- │  ← MiniGame: Stop   (selesai)                         │
-- │  ← NotifyClient: ikan  (ikan didapat)                 │
-- │                                                        │
-- │  Flow kita:                                            │
-- │  cast(true) → hold → cast(false,100)                  │
-- │  → tunggu MiniGame "Start" dari server                │
-- │  → FireServer MiniGame(true) = auto complete          │
-- └─────────────────────────────────────────────────────────┘
local Fish = {
    autoOn       = false,
    fishTask     = nil,
    waitDelay    = 120,   -- timeout tunggu MiniGame Start (detik)
    instantDelay = 2,     -- durasi hold tombol cast (detik)
    rodEquipped  = false,
    totalFished  = 0,
}

-- Listen MiniGame OnClientEvent "Start" — ini trigger utama
local Fish_miniConn  = nil
local Fish_miniReady = false  -- true saat server kirim "Start"

local function startMiniGameListener()
    local miniEv = getFishEv("MiniGame")
    if not miniEv then task.delay(2, startMiniGameListener); return end
    if Fish_miniConn then Fish_miniConn:Disconnect() end
    Fish_miniConn = miniEv.OnClientEvent:Connect(function(state)
        local s = tostring(state)
        xlog("Fish","MiniGame OnClient: "..s,false)
        if s == "Start" then
            Fish_miniReady = true
        end
    end)
    xlog("Fish","MiniGame listener aktif",false)
end
startMiniGameListener()

-- equipRod — cari di karakter dulu, baru backpack
local function equipRod()
    local char = getChar()
    local bp   = LP:FindFirstChild("Backpack")
    if char then
        local rod = char:FindFirstChild("AdvanceRod")
        if not rod then
            for _,t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and (t.Name:lower():find("rod") or
                   t.Name:lower():find("pancing")) then rod=t; break end
            end
        end
        if rod then
            Fish.rodEquipped=true
            notify("Fishing","AdvanceRod ready!",2); return true
        end
    end
    if bp then
        local rod = bp:FindFirstChild("AdvanceRod")
        if not rod then
            for _,t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and (t.Name:lower():find("rod") or
                   t.Name:lower():find("pancing")) then rod=t; break end
            end
        end
        if rod then
            rod.Parent=char; task.wait(0.5)
            Fish.rodEquipped=true
            notify("Fishing","AdvanceRod equipped!",2); return true
        end
    end
    notify("Fishing","AdvanceRod tidak ditemukan!",4); return false
end

local function unequipRod()
    local char=getChar(); if not char then return end
    local bp=LP:FindFirstChild("Backpack"); if not bp then return end
    local rod=char:FindFirstChild("AdvanceRod")
    if rod then rod.Parent=bp end; Fish.rodEquipped=false
end

-- castOnce — flow berdasarkan debug log
local function castOnce()
    local castEv = getFishEv("CastEvent")
    local miniEv = getFishEv("MiniGame")
    if not castEv then notify("Fishing","CastEvent tidak ada!",4); return false end

    -- 1. Reset flag
    Fish_miniReady = false

    -- 2. Tahan tombol cast (simulasi hold power bar)
    pcall(function() castEv:FireServer(true) end)
    task.wait(Fish.instantDelay)  -- hold sesuai slider

    -- 3. Lepas dengan power 100
    pcall(function() castEv:FireServer(false, 100) end)
    task.wait(0.3)

    -- 4. Tunggu server kirim MiniGame "Start" (bar muncul)
    local waited  = 0
    local timeout = Fish.waitDelay
    while not Fish_miniReady and waited < timeout and Fish.autoOn do
        task.wait(0.1); waited = waited + 0.1
    end

    if not Fish.autoOn then return false end

    -- 5. Auto complete bar — FireServer(true) langsung
    if miniEv then
        pcall(function() miniEv:FireServer(true) end)
    end

    -- 6. Tunggu sedikit agar server proses
    task.wait(0.5)

    Fish_miniReady = false
    Fish.totalFished = Fish.totalFished + 1
    xlog("Fish","Cast #"..Fish.totalFished.." waited="..
        string.format("%.1f",waited).."s",false)
    return true
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  SCAN AREA — Farm sudah dideklarasi di atas             │
-- └─────────────────────────────────────────────────────────┘
local _t=tick()
repeat task.wait(0.1)
until #Workspace:GetChildren()>=50 or (tick()-_t)>8
buildAreaData()
-- Set default area ke "Semua Lahan" kalau ada
if #AREA_NAMES > 0 then
    -- Cari label "Semua Lahan" dulu
    for _, name in ipairs(AREA_NAMES) do
        if name:find("Semua") then
            Farm.selectedArea = name; break
        end
    end
    -- Fallback ke area pertama
    if Farm.selectedArea == "" then
        Farm.selectedArea = AREA_NAMES[1]
    end
    xlog("Scan","Default area: "..Farm.selectedArea,false)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  WINDOW & TABS                                          │
-- └─────────────────────────────────────────────────────────┘
local Win=Library:Window("XKID HUB","sprout","v5.24",false)
Win:TabSection("MAIN")
local T_Farm=Win:Tab("Farming","leaf")
local T_Shop=Win:Tab("Shop","shopping-cart")
local T_TP  =Win:Tab("Teleport","map-pin")
local T_Pl  =Win:Tab("Player","user")
local T_Sec =Win:Tab("Security","shield")
local T_Set =Win:Tab("Setting","settings")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB FARMING                         ║
-- ╚═══════════════════════════════════════════════════════╝
local FP=T_Farm:Page("Farming","leaf")
local FL=FP:Section("🌱 Farming","Left")
local FR=FP:Section("🔄 Auto & Fitur","Right")

FL:Label("📍 Pilih Tanaman & Lahan")
FL:Dropdown("Pilih Tanaman","cropSel",cropDropNames,
    function(val)
        for _,c in ipairs(CROPS) do
            if val:find(c.seed,1,true) then
                Farm.selectedCrop=c
                local slot,stok=getSlotIdx(c)
                if slot then notify("Tanaman",c.seed.." | Slot "..slot.." | Stok "..stok,3)
                else notify("Tanaman ⚠",c.seed.."\nBeli dulu agar slot terdeteksi",4) end
                break
            end
        end
    end,"Pilih jenis tanaman")

FL:Dropdown("Pilih Lahan","areaSel",
    #AREA_NAMES>0 and AREA_NAMES or {"(Scan dulu)"},
    function(val)
        Farm.selectedArea=val
        local plots = AREA_PLOTS[val]
        local count = plots and #plots or 0
        notify("Lahan",val.."\n"..count.." slot tersedia",2)
    end,"Land 1-8 / Semua Utama / Semua Jauh / Semua")

FL:Label("🌱 Jumlah & Mode")
FL:Toggle("🔥 Full Lahan","fullMode",false,
    "ON = tanam semua slot lahan yang dipilih\nOFF = pakai slider jumlah",
    function(v)
        Farm.fullMode=v
        local plots = AREA_PLOTS[Farm.selectedArea]
        local total = plots and #plots or 0
        if v then
            notify("Full Mode","ON — semua "..total.." slot akan ditanam!",3)
        else
            notify("Full Mode","OFF — pakai slider jumlah",2)
        end
    end)

FL:Slider("Jumlah Plot","plantQty",1,20,5,
    function(v) Farm.jumlahTanam=v end,
    "Aktif saat Full Mode OFF | 1-20 slot per aksi")

FL:Button("🌱 Mulai Tanam","Tanam sesuai setting",
    function()
        task.spawn(function()
            if Farm.selectedArea=="" or not AREA_PLOTS[Farm.selectedArea] then
                if #AREA_NAMES > 0 then
                    Farm.selectedArea = AREA_NAMES[1]
                    notify("Farm","Auto pilih: "..AREA_NAMES[1],2)
                else
                    notify("Farm","Scan ulang dulu!",3); return
                end
            end
            local plots  = AREA_PLOTS[Farm.selectedArea]
            local jumlah = Farm.fullMode and #plots or Farm.jumlahTanam
            notify("Tanam","🌱 "..Farm.selectedCrop.seed..
                "\n📍 "..Farm.selectedArea..
                "\n🔢 "..jumlah.." slot"..(Farm.fullMode and " (FULL)" or ""),3)
            tanamPlots()
        end)
    end)

FL:Button("🔍 Cek Slot & Stok","Lihat semua slot inventory",
    function()
        if next(SeedInventory)==nil then
            notify("Inventory","Belum ada data!\nBeli bibit dulu.",5); return
        end
        local txt=""
        for cropName,data in pairs(SeedInventory) do
            local mark=(cropName==Farm.selectedCrop.name) and " ◄" or ""
            txt=txt..string.format("[%d] %s x%d%s\n",data.slot,cropName,data.count,mark)
        end
        local invCount = 0
        for _ in pairs(SeedInventory) do invCount = invCount + 1 end
        notify("🌱 SeedPlanter ("..invCount.." slot)", txt, 12)
    end)

FL:Button("🔄 Refresh Inventory","Paksa server kirim data slot bibit",
    function()
        task.spawn(function()
            notify("Inventory","Mengambil data slot...",2)
            SeedInventory = {}
            forceRefreshInventory()
        end)
    end)

FL:Button("🔄 Scan Ulang Lahan","Refresh semua Land Part",
    function()
        buildAreaData()
        local nLand = #LAND_LIST
        local total = #ALL_PLOTS
        if nLand > 0 then
            Farm.selectedArea = AREA_NAMES[1]
            notify("✅ Scan",
                nLand.." Land | "..total.." total slot\nAktif: "..AREA_NAMES[1],5)
        else
            Farm.selectedArea = ""
            notify("⚠ Scan","Tidak ada Land!\nPastikan dekat lahan.",5)
        end
    end)

FR:Label("🔄 Auto Loop")
FR:Toggle("🔁 Auto Plant Loop","autoLoop",false,
    "Tanam semua lahan → tunggu tumbuh → panen → ulangi",
    function(v)
        AutoLoop.active = v
        if v then
            if #LAND_LIST == 0 then
                notify("Auto Loop ❌","Scan lahan dulu!",3)
                AutoLoop.active = false; return
            end
            if AutoLoop.task then
                pcall(function() task.cancel(AutoLoop.task) end)
            end
            AutoLoop.total = 0
            AutoLoop.task = task.spawn(runAutoLoop)
            notify("🔁 Auto Loop","ON!
"..#LAND_LIST.." lahan | timeout "..AutoLoop.timeout.."s",3)
        else
            if AutoLoop.task then
                pcall(function() task.cancel(AutoLoop.task) end)
                AutoLoop.task = nil
            end
            notify("Auto Loop","STOP",2)
        end
    end)

FR:Slider("Timeout Tunggu (s)","loopTimeout",30,300,120,
    function(v) AutoLoop.timeout=v end,
    "Max tunggu tumbuh sebelum panen paksa")

FR:Label("🔄 Auto Cycle")
FR:Toggle("Auto Farm","autoCycle",false,"Beli→Tanam→Tunggu→Panen→Ulangi",
    function(v)
        Farm.autoCycleOn=v
        if v then
            if Farm.selectedArea=="" then
                notify("Farm ❌","Pilih area dulu!",3); Farm.autoCycleOn=false; return end
            if Farm.autoCycleTask then
                pcall(function() task.cancel(Farm.autoCycleTask) end)
                Farm.autoCycleTask=nil; task.wait(0.3)
            end
            Farm.autoCycleTask=task.spawn(function()
                while Farm.autoCycleOn do
                    local ok,err=pcall(runCycle)
                    if not ok then
                        notify("Cycle ❌","Error: "..tostring(err):sub(1,60),5)
                        xlog("Cycle","CRASH: "..tostring(err):sub(1,80),true); task.wait(5)
                    else task.wait(2) end
                end
            end)
            notify("Auto Farm","ON — "..Farm.selectedCrop.seed,3)
        else
            if Farm.autoCycleTask then
                pcall(function() task.cancel(Farm.autoCycleTask) end); Farm.autoCycleTask=nil end
            notify("Auto Farm","OFF",2)
        end
    end)

FR:Toggle("Auto Beli","autoBeli",false,"Beli sebelum cycle",
    function(v) Farm.autoBeli=v; notify("Auto Beli",v and "ON" or "OFF",2) end)
FR:Slider("Jumlah Auto Beli","autoBeliQty",1,99,10,
    function(v) Farm.jumlahAutoBeli=v end,"Per transaksi")

FR:Label("✨ Fitur Tambahan")
FR:Toggle("🌾 Auto Panen","autoPanen",false,
    "Panen otomatis saat ada tanaman siap\n(cache dari server + fallback paksa)",
    function(v)
        Farm.autoPanen=v
        if v then
            Farm.autoPanenTask=task.spawn(function()
                while Farm.autoPanen do
                    local n=harvestAll()
                    if n>0 then notify("Auto Panen","✅ "..n.." dipanen!",2) end
                    task.wait(15)  -- cek tiap 15 detik
                end
            end)
            notify("Auto Panen","ON — cek tiap 15s",3)
        else
            if Farm.autoPanenTask then
                pcall(function() task.cancel(Farm.autoPanenTask) end)
                Farm.autoPanenTask=nil
            end
            notify("Auto Panen","OFF",2)
        end
    end)

FR:Button("▶ 1 Cycle Manual","Beli→Tanam→Tunggu→Panen",
    function()
        if Farm.selectedArea=="" then notify("Farm","Pilih lahan dulu!",3); return end
        task.spawn(runCycle)
    end)

FR:Button("✂ Panen Sekarang","Harvest semua (cache + paksa)",
    function()
        task.spawn(function()
            local n=harvestAll()
            if n>0 then notify("Panen","✅ "..n.." dipanen!",3) end
        end)
    end)

FR:Button("🌿 Cek Crop Ready","Lihat tanaman siap dari server",
    function()
        local count = #HarvestCache
        if count == 0 then
            notify("Crop Ready",
                "Cache kosong\nServer belum kirim notif\n\nPakai 'Panen Sekarang' untuk\nfallback paksa harvest",5)
            return
        end
        local txt = count.." tanaman siap (cache):\n"
        for i, e in ipairs(HarvestCache) do
            txt = txt..string.format("[%d] %s\n", i, e.cropName)
            if i >= 8 then txt = txt.."..."; break end
        end
        notify("🌿 Cache ("..count..")", txt, 8)
    end)

-- ╔═══════════════════════════════════════════════════════╗
-- ║                    TAB SHOP                           ║
-- ╚═══════════════════════════════════════════════════════╝
local SP=T_Shop:Page("Shop","shopping-cart")
local SL=SP:Section("🎒 Tas & Like","Left")
local SR=SP:Section("🌾 Beli Bibit","Right")

SL:Button("🔄 Refresh Isi Tas","Lihat backpack",
    function()
        local bp=LP:FindFirstChild("Backpack"); if not bp then notify("Tas","Tidak ada!",3); return end
        local items=bp:GetChildren(); local txt=""
        for i,item in ipairs(items) do txt=txt..string.format("[%d] %s\n",i,item.Name) end
        notify("🎒 Tas ("..#items..")", #items>0 and txt or "Kosong", 10)
    end)

SL:Label("❤ Send Like")
local likeInput=""
SL:TextBox("Nama Player","likeInput","",function(v) likeInput=v end,"Ketik nama")
SL:Button("❤ Send Like","Kirim like",
    function()
        local p=inferPlayer(likeInput)
        if not p then notify("Like","'"..likeInput.."' tidak ditemukan",3); return end
        sendLike(p)
    end)
SL:Button("❤ Like Semua","Like semua player",
    function()
        local count=0
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP then if sendLike(p) then count=count+1 end; task.wait(0.3) end
        end
        notify("Like","Terkirim ke "..count.." player",3)
    end)

SR:Label("🌾 Beli Bibit")
local shopCrop=CROPS[1]; local shopQty=1
SR:Dropdown("Pilih Bibit","shopCropSel",cropDropNames,
    function(val)
        for _,c in ipairs(CROPS) do if val:find(c.seed,1,true) then shopCrop=c; break end end
        notify("Pilih",shopCrop.seed,2)
    end,"Pilih bibit")
SR:Slider("Jumlah","shopQtySel",1,99,1,function(v) shopQty=v end,"Per beli")
SR:Button("🛒 Beli","Beli sekarang",
    function()
        task.spawn(function()
            local ok=beliBibit(shopCrop,shopQty)
            notify(ok and "✅ OK" or "❌ Gagal",shopCrop.seed.." x"..shopQty,3)
        end)
    end)
SR:Label("─── Quick Buy ───")
for _,c in ipairs(CROPS) do
    local cc=c
    SR:Button(cc.icon.." "..cc.seed,"Harga "..cc.price.." | Jual "..cc.sell,
        function()
            task.spawn(function()
                local ok=beliBibit(cc,shopQty)
                notify(ok and "✅" or "❌",cc.seed.." x"..shopQty,2)
            end)
        end)
end

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB TELEPORT                         ║
-- ╚═══════════════════════════════════════════════════════╝
local TPG=T_TP:Page("Teleport","map-pin")
local TPL=TPG:Section("👥 Player","Left")
local TPR=TPG:Section("🔍 Nama & 📍 Lokasi","Right")

local playerBtns={}
local function addPlayerBtn(p)
    if p==LP or playerBtns[p] then return end
    playerBtns[p]=TPL:Button("🚀 "..p.Name,"TP ke "..p.Name,
        function()
            local root=getRoot(); if not root then return end
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                root.CFrame=p.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,3)
                notify("TP","→ "..p.Name,2)
            else notify("TP",p.Name.." tidak ada karakter",2) end
        end)
end
for _,p in pairs(Players:GetPlayers()) do addPlayerBtn(p) end
Players.PlayerAdded:Connect(function(p) task.wait(0.5); addPlayerBtn(p) end)
Players.PlayerRemoving:Connect(function(p) playerBtns[p]=nil end)
TPL:Button("👥 Semua Player","Daftar + jarak",
    function()
        local list,n="",0
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP then n=n+1
                local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local myR=getRoot()
                local d=(hrp and myR) and math.floor((hrp.Position-myR.Position).Magnitude) or "?"
                list=list.."• "..p.Name.." — "..tostring(d).."m\n"
            end
        end
        notify(n.." Player",n>0 and list or "Tidak ada",10)
    end)

local tpInput=""
TPR:TextBox("Nama / Prefix","tpInput","",function(v) tpInput=v end,"Ketik nama")
TPR:Button("🔍 TP via Nama","Cari & TP",function() tpToPlayer(tpInput) end)
TPR:Label("💾 Save & Load")
for i=1,5 do
    local idx=i
    TPR:Button("💾 Save "..idx,"Simpan slot "..idx,
        function()
            local cf=lastCFrame; if not cf then notify("Save","Tidak ada karakter!",2); return end
            SavedLoc[idx]=cf; local p=cf.Position
            notify("Slot "..idx,string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z),4)
        end)
    TPR:Button("📍 Load "..idx,"TP slot "..idx,
        function()
            if not SavedLoc[idx] then notify("Load","Slot "..idx.." kosong!",2); return end
            local root=getRoot(); if root then
                root.CFrame=SavedLoc[idx]; local p=SavedLoc[idx].Position
                notify("Slot "..idx,string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z),3)
            end
        end)
end
TPR:Button("📌 Posisi Saya","Koordinat sekarang",
    function()
        local r=getRoot(); if r then
            local p=r.Position
            notify("Posisi",string.format("X=%.2f\nY=%.2f\nZ=%.2f",p.X,p.Y,p.Z),8)
            print(string.format("[XKID] X=%.4f Y=%.4f Z=%.4f",p.X,p.Y,p.Z))
        end
    end)

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB PLAYER                          ║
-- ╚═══════════════════════════════════════════════════════╝
local PP=T_Pl:Page("Player","user")
local PL=PP:Section("⚡ Speed & Jump","Left")
local PR=PP:Section("🚀 Fly & ESP","Right")

PL:Slider("Walk Speed","ws",16,500,16,
    function(v) Move.speed=v; if not flyFlying then local h=getHum(); if h then h.WalkSpeed=v end end end,"Default 16")
PL:Button("Reset Speed","Ke 16",
    function()
        Move.speed=16; if not flyFlying then local h=getHum(); if h then h.WalkSpeed=16 end end
        notify("Speed","Reset 16",2)
    end)
PL:Slider("Jump Power","jp",50,500,50,
    function(v) local h=getHum(); if h then h.JumpPower=v; h.UseJumpPower=true end end,"Default 50")
PL:Toggle("Infinite Jump","infJump",false,"Lompat terus",
    function(v) setInfJump(v); notify("Inf Jump",v and "ON" or "OFF",2) end)
PL:Toggle("NoClip","noclip",false,"Tembus dinding",
    function(v) setNoclip(v); notify("NoClip",v and "ON" or "OFF",2) end)
PR:Toggle("Fly","fly",false,"Terbang bebas",
    function(v) if v then startFly() else stopFly() end; notify("Fly",v and "ON" or "OFF",2) end)
PR:Slider("Fly Speed","flySpd",10,300,60,function(v) Move.flySpeed=v end,"Kecepatan")
PR:Toggle("ESP Player","espPl",false,"Nama + jarak",
    function(v)
        ESPPl.active=v
        if v then startESPPlayer() else stopESPPlayer() end
        notify("ESP Player",v and "ON" or "OFF",2)
    end)
PR:Paragraph("Cara Fly",
    "Mobile: Joystick=gerak\nKamera atas=naik | bawah=turun\n\n"..
    "PC: W/A/S/D=gerak\nKamera atas/bawah=naik/turun")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB SECURITY                         ║
-- ╚═══════════════════════════════════════════════════════╝
local SecP=T_Sec:Page("Security","shield")
local SecL=SecP:Section("🛡 Perlindungan","Left")
local SecR=SecP:Section("ℹ Info","Right")

local afkConn=nil
SecL:Toggle("Anti AFK","antiAfk",false,"Cegah disconnect idle",
    function(v)
        if v then
            if afkConn then afkConn:Disconnect() end
            afkConn=LP.Idled:Connect(function()
                VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
            end)
        else if afkConn then afkConn:Disconnect(); afkConn=nil end end
        notify("Anti AFK",v and "ON" or "OFF",2)
    end)

local antiKickConn=nil
SecL:Toggle("Anti Kick","antiKick",false,"HP dikunci < 15%",
    function(v)
        if v then
            if antiKickConn then antiKickConn:Disconnect() end
            antiKickConn=RunService.Heartbeat:Connect(function()
                local h=getHum()
                if h and h.Health>0 and h.Health<h.MaxHealth*0.15 then h.Health=h.MaxHealth end
            end)
        else if antiKickConn then antiKickConn:Disconnect(); antiKickConn=nil end end
        notify("Anti Kick",v and "ON" or "OFF",2)
    end)

-- [v5.24] Respawn Cepat — mati + TP balik
SecL:Label("⚡ Respawn Cepat")
SecL:Button("⚡ Respawn Sekarang","Mati → ganti karakter → TP balik",
    function() task.spawn(doRespawn) end)
SecL:Button("📍 Simpan Posisi","Simpan posisi sekarang manual",
    function()
        local root=getRoot()
        if root then
            Respawn.savedPosition=root.CFrame; local p=root.Position
            notify("📍 Tersimpan",string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z),3)
        end
    end)

SecL:Button("🔄 Rejoin","Koneksi ulang ke server",
    function()
        notify("Rejoin","Menghubungkan ulang...",3)
        task.wait(1); TpService:Teleport(game.PlaceId,LP)
    end)

SecR:Paragraph("Anti AFK","Simulasi input saat idle")
SecR:Paragraph("Anti Kick","HP < 15% → dikunci penuh")
SecR:Paragraph("⚡ Respawn Cepat",
    "Klik → mati sebentar\n→ karakter baru spawn\n→ otomatis TP ke posisi semula\n\nPosisi tersimpan otomatis tiap detik")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB SETTING                         ║
-- ╚═══════════════════════════════════════════════════════╝
local SetP=T_Set:Page("Setting","settings")
local SetL=SetP:Section("🎣 Fishing","Left")
local SetR=SetP:Section("ℹ Log & Info","Right")

SetR:Button("📋 Log Terbaru","5 log terakhir",
    function()
        if #logLines==0 then notify("Log","Belum ada log",3); return end
        local txt=""
        for i=1,math.min(5,#logLines) do txt=txt..logLines[i].."\n" end
        notify("Log ("..#logLines..")",txt,12)
    end)
SetR:Button("📋 Semua Log","10 log terakhir",
    function()
        if #logLines==0 then notify("Log","Belum ada log",3); return end
        local txt=""
        for i=1,math.min(10,#logLines) do txt=txt..logLines[i].."\n" end
        notify("Log Lengkap",txt,15)
    end)
SetR:Button("🗑 Bersihkan Log","Hapus semua",
    function() logLines={}; notify("Log","Dibersihkan",2) end)

SetL:Label("🎣 Fishing Settings")
SetL:Slider("Hold Duration (detik)","fishHoldDelay",1,10,2,
    function(v) Fish.instantDelay=v end,
    "Lama tahan tombol lempar (1-10 detik)\nDefault 2s — naikkan kalau gagal dapat ikan")

SetL:Slider("Timeout Tunggu Bar (detik)","fishWait",10,180,120,
    function(v) Fish.waitDelay=v end,
    "Maks tunggu MiniGame Start dari server")

SetL:Label("🎣 Auto Fishing")
SetL:Toggle("Auto Fishing","autoFish",false,
    "Auto equip rod + cast loop otomatis",
    function(v)
        Fish.autoOn=v
        if v then
            task.spawn(function()
                if not Fish.rodEquipped then
                    local ok = equipRod()
                    if not ok then Fish.autoOn=false; return end
                    task.wait(0.3)
                end
                notify("Fishing 🎣","ON! Hold="..Fish.instantDelay.."s\nLangsung casting!",3)
                local attempts=0
                Fish.fishTask=task.spawn(function()
                    while Fish.autoOn do
                        local ok,err=pcall(castOnce)
                        if ok then
                            attempts=0
                        else
                            attempts=attempts+1
                            xlog("Fish","Error: "..tostring(err):sub(1,60),true)
                            if attempts>=3 then
                                notify("Fishing","Auto stop — 3x error",5)
                                Fish.autoOn=false; break
                            end
                            task.wait(3)
                        end
                    end
                end)
            end)
        else
            if Fish.fishTask then
                pcall(function() task.cancel(Fish.fishTask) end)
                Fish.fishTask=nil
            end
            notify("Fishing","OFF | Total: "..Fish.totalFished,2)
        end
    end)

SetL:Button("🎣 Cast Sekali","1x cast manual",
    function()
        task.spawn(function()
            if not Fish.rodEquipped then
                local ok=equipRod(); if not ok then return end
                task.wait(0.5)
            end
            local wasAuto = Fish.autoOn
            Fish.autoOn = true
            castOnce()
            Fish.autoOn = wasAuto
            notify("Fishing","Cast selesai! Total: "..Fish.totalFished,2)
        end)
    end)
SetL:Button("📦 Equip Rod","Cari & equip AdvanceRod",function() equipRod() end)
SetL:Button("📤 Unequip Rod","Kembalikan rod ke backpack",
    function() unequipRod(); notify("Rod","Dikembalikan",2) end)

SetR:Paragraph("XKID HUB v5.24",
    "CHANGELOG:\n"..
    "✅ Scan: cari Part name=Land\n"..
    "✅ 8 lahan terdeteksi (51-67)\n"..
    "✅ Fishing: tunggu MiniGame Start\n"..
    "✅ MiniGame(true) = auto complete\n"..
    "✅ Hold duration slider\n"..
    "✅ slotIdx cache realtime")

SetR:Paragraph("Fishing Flow",
    "cast(true) → tahan Xs\n"..
    "cast(false,100) → lempar\n"..
    "← MiniGame: Start  (bar muncul)\n"..
    "→ MiniGame(true)   (auto tap)\n"..
    "← NotifyClient: ikan didapat!\n\n"..
    "Slider Hold Duration:\n"..
    "Naikkan jika gagal dapat ikan")

SetR:Paragraph("Cara Tanam",
    "1. Shop → Beli bibit dulu\n"..
    "2. Farming → Pilih Tanaman\n"..
    "   (notif otomatis cek slot)\n"..
    "3. Cek Slot & Stok\n"..
    "4. Pilih Area + Pola + Jumlah\n"..
    "5. Mulai Tanam!")

-- ┌─────────────────────────────────────────────────────────┐
-- │                      INIT                               │
-- └─────────────────────────────────────────────────────────┘
local _totalPl=0
for _,v in pairs(AREA_PARTS) do _totalPl=_totalPl+#v end

if _totalPl>0 then
    notify("✅ XKID HUB v5.24 Ready",
        #AREA_NAMES.." area | ".._totalPl.." plot\nBeli bibit dulu agar slot terdeteksi!",6)
else
    notify("⚠ XKID HUB v5.24",
        "Plot belum ditemukan!\nFarming → Scan Ulang Area",6)
end

Library:Notification("XKID HUB v5.24",
    "Farming · Shop · Teleport · Player · Security · Setting",6)
Library:ConfigSystem(Win)
print("[XKID HUB] v5.24 loaded — "..LP.Name)
print("[v5.24] equipRod=char+bp | castOnce=NotifyClient | MiniGame=1x | timeout=60s")
