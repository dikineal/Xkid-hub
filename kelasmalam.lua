--[[
╔═══════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.7  🌟              ║
║                  Aurora UI  ·  Pro Edition               ║
╠═══════════════════════════════════════════════════════════╣
║  Farming  ·  Shop  ·  Teleport  ·  Player                ║
║  Security  ·  Setting                                    ║
╠═══════════════════════════════════════════════════════════╣
║  CHANGELOG v5.7:                                         ║
║  [FIX] SeedInventory auto force refresh saat nil        ║
║  [FIX] Fallback baca slot dari SeedPlanter UI           ║
║  [NEW] Tombol Refresh Inventory di Farming tab          ║
║  [FIX] Auto Fishing: auto equip + langsung cast         ║
║  [KEEP] Dual mode: Instant + Normal                     ║
║  [KEEP] Semua fix v5.6 tetap ada                        ║
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
    end)
    xlog("INV", "Listener aktif", false)
end
startInventoryListener()

-- [FIX v5.7] Fallback: baca slot langsung dari SeedPlanter UI
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

-- [FIX v5.7] Force refresh inventory — panggil ini kalau cache kosong
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
-- │                  AREA / PLOT DATA                       │
-- └─────────────────────────────────────────────────────────┘
local LAND_ZONES = {
    { name="Area Utama", center=Vector3.new(24.0, 9.3, 0.18),     radius=15 },
    { name="Area Jauh",  center=Vector3.new(33.31, 15.82, 40.51), radius=15 },
}
local SCAN_RANGE_START = 40
local SCAN_RANGE_END   = 120
local AREA_NAMES = {}
local AREA_PLOTS = {}
local AREA_PARTS = {}

local function isInZone(pos, zone)
    return (Vector3.new(pos.X, zone.center.Y, pos.Z) - zone.center).Magnitude <= zone.radius
end

local function buildAreaData()
    AREA_NAMES = {}; AREA_PLOTS = {}; AREA_PARTS = {}
    local zoneData = {}
    for _, z in ipairs(LAND_ZONES) do zoneData[z.name] = {zone=z, plots={}} end
    local uncategorized = {}
    local allCh = Workspace:GetChildren()

    for idx = SCAN_RANGE_START, math.min(SCAN_RANGE_END, #allCh) do
        local obj = allCh[idx]
        if obj then
            local pos
            if obj:IsA("BasePart") then pos = obj.Position
            else local p = obj:FindFirstChildOfClass("BasePart"); if p then pos = p.Position end end
            if pos then
                local matched = false
                for _, z in ipairs(LAND_ZONES) do
                    if isInZone(pos, z) then
                        table.insert(zoneData[z.name].plots, {
                            part = obj:IsA("BasePart") and obj or (obj:FindFirstChildOfClass("BasePart") or obj),
                            obj=obj, pos=pos, idx=idx,
                        })
                        matched=true; break
                    end
                end
                if not matched then
                    table.insert(uncategorized, {
                        part = obj:IsA("BasePart") and obj or (obj:FindFirstChildOfClass("BasePart") or obj),
                        obj=obj, pos=pos, idx=idx,
                    })
                end
            end
        end
    end

    for _, z in ipairs(LAND_ZONES) do
        local d = zoneData[z.name]
        if #d.plots > 0 then
            local label = z.name.." ("..#d.plots.." plot)"
            table.insert(AREA_NAMES, label)
            AREA_PLOTS[label] = d.plots
            local parts = {}
            for _, pl in ipairs(d.plots) do table.insert(parts, pl.part) end
            AREA_PARTS[label] = parts
        end
    end

    if #AREA_NAMES == 0 then
        local land = Workspace:FindFirstChild("Land")
        if land then
            local parts = {}
            for _, p in ipairs(land:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    table.insert(parts, {part=p, obj=land, pos=p.Position, idx=0})
                end
            end
            if #parts > 0 then
                local label = "Land ("..#parts.." plot)"
                table.insert(AREA_NAMES, label); AREA_PLOTS[label] = parts
                local pp = {}; for _,pl in ipairs(parts) do table.insert(pp, pl.part) end
                AREA_PARTS[label] = pp
            end
        end
    end

    if #AREA_NAMES == 0 and #uncategorized > 0 then
        local label = "Auto Scan ("..#uncategorized.." plot)"
        table.insert(AREA_NAMES, label); AREA_PLOTS[label] = uncategorized
        local pp = {}; for _,pl in ipairs(uncategorized) do table.insert(pp, pl.part) end
        AREA_PARTS[label] = pp
    end

    print(string.format("[XKID v5.4] Scan: %d area", #AREA_NAMES))
    for _, name in ipairs(AREA_NAMES) do
        print(string.format("  → %s: %d plot", name, AREA_PARTS[name] and #AREA_PARTS[name] or 0))
    end
end

local POLA_NAMES = {"Normal","Rapat (terdekat)","Selang-seling Lebar","Selang-seling Panjang"}
local function filterByPola(plotList, pola, jumlah)
    local max = math.min(jumlah, #plotList, 20)
    local result = {}
    if pola == "Normal" then
        for i=1,max do table.insert(result, plotList[i]) end
    elseif pola == "Rapat (terdekat)" then
        local root = getRoot()
        if root then
            local sorted = {}
            for _,pl in ipairs(plotList) do
                table.insert(sorted, {pl=pl, dist=(pl.part.Position-root.Position).Magnitude})
            end
            table.sort(sorted, function(a,b) return a.dist<b.dist end)
            for i=1,math.min(max,#sorted) do table.insert(result, sorted[i].pl) end
        else for i=1,max do table.insert(result, plotList[i]) end end
    elseif pola == "Selang-seling Lebar" then
        local sorted = {table.unpack(plotList)}
        table.sort(sorted, function(a,b) return a.part.Position.X<b.part.Position.X end)
        local lastX, skip = nil, false
        for _,pl in ipairs(sorted) do
            if lastX==nil then lastX=pl.part.Position.X; skip=false
            elseif math.abs(pl.part.Position.X-lastX)>6 then lastX=pl.part.Position.X; skip=not skip end
            if not skip then table.insert(result,pl); if #result>=max then break end end
        end
        if #result==0 then for i=1,max do table.insert(result,plotList[i]) end end
    elseif pola == "Selang-seling Panjang" then
        local sorted = {table.unpack(plotList)}
        table.sort(sorted, function(a,b) return a.part.Position.Z<b.part.Position.Z end)
        local lastZ, skip = nil, false
        for _,pl in ipairs(sorted) do
            if lastZ==nil then lastZ=pl.part.Position.Z; skip=false
            elseif math.abs(pl.part.Position.Z-lastZ)>6 then lastZ=pl.part.Position.Z; skip=not skip end
            if not skip then table.insert(result,pl); if #result>=max then break end end
        end
        if #result==0 then for i=1,max do table.insert(result,plotList[i]) end end
    end
    return result
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                  FARM STATE                             │
-- └─────────────────────────────────────────────────────────┘
local Farm = {
    selectedCrop=CROPS[1], selectedArea="", selectedPola="Normal",
    jumlahTanam=5, autoCycleOn=false, autoCycleTask=nil,
    autoBeli=false, jumlahAutoBeli=10, growDelay=60,
    autoPanen=false, autoPanenTask=nil, espKematangan=false,
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

    -- [FIX v5.7] Auto force refresh kalau cache kosong
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
    if not plotList or #plotList == 0 then
        notify("Farm ❌","Area kosong! Scan Ulang.",5); return 0
    end

    local maxTanam = math.min(Farm.jumlahTanam, stockCount)
    if maxTanam < Farm.jumlahTanam then
        notify("Farm ⚠","Stok "..stockCount.." — tanam disesuaikan ke "..maxTanam,3)
    end

    local filtered = filterByPola(plotList, Farm.selectedPola, maxTanam)
    if #filtered == 0 then notify("Farm ❌","0 plot setelah filter",4); return 0 end

    xlog("Tanam",string.format("crop=%s slot=%d stok=%d plot=%d",
        Farm.selectedCrop.name, slotIdx, stockCount, #filtered), false)

    local count, failed = 0, 0
    for _, pl in ipairs(filtered) do
        local ok, err = pcall(function()
            ev:FireServer({
                { slotIdx=slotIdx, hitPosition=pl.part.Position, hitPart=pl.obj },
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
    local allPlots = {}
    for _, plotList in pairs(AREA_PLOTS) do
        for _, pl in ipairs(plotList) do table.insert(allPlots, pl) end
    end
    if #allPlots == 0 then notify("Farm ❌","Tidak ada plot! Scan ulang.",5); return 0 end

    local count, failed = 0, 0
    local crop = Farm.selectedCrop
    local sc = crop.color or {0.298,0.600,0}

    for _, pl in ipairs(allPlots) do
        local ok, err = pcall(function()
            ev:FireServer({
                ["\13"] = {{
                    cropName  = crop.name,
                    cropPos   = pl.part.Position,
                    sellPrice = crop.sell,
                    seedColor = {sc[1], sc[2], sc[3]},
                    drops     = {{
                        name="Biji "..crop.seed,
                        coinReward=math.floor(crop.sell*0.15),
                        icon=crop.icon, rarity="Rare"
                    }}
                }},
                ["\2"] = {
                    math.floor(os.clock()*1000),
                    math.floor(os.clock()*1000)+50
                }
            })
        end)
        if ok then count=count+1
        else failed=failed+1; xlog("Harvest","Error: "..tostring(err):sub(1,50),false) end
        task.wait(0.1)
    end
    if failed>0 then notify("Farm","Harvest: "..count.." OK "..failed.." gagal",4) end
    return count
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

-- ESP Kematangan
local ESPCr={active=false,bills={},tagged={},loopTask=nil,lastScan=0,sizeData={}}
local function _pct(part,name)
    local mag=part.Size.Magnitude; local sd=ESPCr.sizeData[name]
    if not sd then ESPCr.sizeData[name]={min=mag,max=mag}; return 0 end
    if mag<sd.min then sd.min=mag end; if mag>sd.max then sd.max=mag end
    if sd.max==sd.min then return 50 end
    return math.floor(math.clamp((mag-sd.min)/(sd.max-sd.min)*100,0,100))
end
local function _pctCol(pct)
    if pct>=80 then return Color3.fromRGB(80,255,80) end
    if pct>=40 then return Color3.fromRGB(255,200,50) end
    return Color3.fromRGB(255,80,80)
end
local function _mkCropBill(part,name)
    if ESPCr.tagged[part] then return end; ESPCr.tagged[part]=true
    local bill=Instance.new("BillboardGui")
    bill.Name="XKID_CESP"; bill.Size=UDim2.new(0,100,0,28)
    bill.StudsOffset=Vector3.new(0,3.5,0); bill.AlwaysOnTop=true
    bill.Adornee=part; bill.Parent=part
    local bg=Instance.new("Frame",bill)
    bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(5,20,5)
    bg.BackgroundTransparency=0.3; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,5)
    local lbl=Instance.new("TextLabel",bg)
    lbl.Size=UDim2.new(1,-4,1,-4); lbl.Position=UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency=1; lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold
    lbl.TextXAlignment=Enum.TextXAlignment.Center; lbl.TextStrokeTransparency=0.3
    lbl.Text=name.."\n0%"; lbl.TextColor3=Color3.fromRGB(255,80,80)
    table.insert(ESPCr.bills,{bill=bill,lbl=lbl,part=part,name=name})
end
local _espCropMaster,_espCropLastUpd=nil,0
local function _startESPMaster()
    if _espCropMaster then return end
    _espCropMaster=RunService.Heartbeat:Connect(function()
        local now=tick(); if now-_espCropLastUpd<0.5 then return end
        _espCropLastUpd=now
        for _,e in ipairs(ESPCr.bills) do
            if e.bill and e.bill.Parent and e.part and e.part.Parent then
                local pct=_pct(e.part,e.name)
                e.lbl.Text=e.name.."\n"..pct.."%"
                e.lbl.TextColor3=_pctCol(pct); e.lbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
            end
        end
    end)
end
local function _stopESPMaster()
    if _espCropMaster then _espCropMaster:Disconnect(); _espCropMaster=nil end
end
local function clearESPCrop()
    _stopESPMaster()
    for _,e in ipairs(ESPCr.bills) do pcall(function() e.bill:Destroy() end) end
    ESPCr.bills={}; ESPCr.tagged={}
end
local function scanESPCrop()
    local now=tick(); if now-ESPCr.lastScan<5 then return end
    ESPCr.lastScan=now; local count=0
    for _,v in pairs(Workspace:GetDescendants()) do
        if CROP_VALID[v.Name] then
            if v:IsA("BasePart") and not ESPCr.tagged[v] then _mkCropBill(v,v.Name); count=count+1
            elseif v:IsA("Model") then
                local p=v.PrimaryPart or v:FindFirstChildOfClass("BasePart")
                if p and not ESPCr.tagged[p] then _mkCropBill(p,v.Name); count=count+1 end
            end
        end
    end
    if count>0 then notify("ESP Tanaman","+"..count,2) end
end
local function startESPCrop()
    clearESPCrop(); ESPCr.lastScan=0; scanESPCrop(); _startESPMaster()
    ESPCr.loopTask=task.spawn(function()
        while ESPCr.active do task.wait(5); if ESPCr.active then scanESPCrop() end end
    end)
end
local function stopESPCrop()
    clearESPCrop()
    if ESPCr.loopTask then pcall(function() task.cancel(ESPCr.loopTask) end); ESPCr.loopTask=nil end
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
-- │  [NEW v5.4] FAST RESPAWN SYSTEM                        │
-- └─────────────────────────────────────────────────────────┘
local Respawn={savedPosition=nil, autoRespawn=false, respawnTask=nil}

RunService.Heartbeat:Connect(function()
    local root=getRoot(); if root then Respawn.savedPosition=root.CFrame end
end)

local function fastRespawn()
    if not Respawn.savedPosition then notify("Respawn","Posisi belum tersimpan!",2); return end
    local root=getRoot()
    if root then root.CFrame=Respawn.savedPosition; notify("✅ Respawn","Kembali ke posisi",1) end
end

local function startAutoRespawn()
    if Respawn.respawnTask then return end
    Respawn.respawnTask=task.spawn(function()
        while Respawn.autoRespawn do
            local h=getHum()
            if h and h.Health<=0 then
                task.wait(0.5); LP.CharacterAdded:Wait(); task.wait(0.3)
                local newRoot=getRoot()
                if newRoot and Respawn.savedPosition then
                    newRoot.CFrame=Respawn.savedPosition
                    notify("↩ Auto Respawn","Kembali ke posisi",2)
                end
            end
            task.wait(0.1)
        end
    end)
end
local function stopAutoRespawn()
    if Respawn.respawnTask then
        pcall(function() task.cancel(Respawn.respawnTask) end); Respawn.respawnTask=nil
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  FISHING                                                │
-- └─────────────────────────────────────────────────────────┘
-- ┌─────────────────────────────────────────────────────────┐
-- │  FISHING SYSTEM                                         │
-- │  Mode 1: INSTANT — bypass timer, cast→tarik langsung   │
-- │  Mode 2: NORMAL  — tunggu NotifyClient dari server     │
-- └─────────────────────────────────────────────────────────┘
local Fish = {
    autoOn       = false,
    fishTask     = nil,
    waitDelay    = 60,     -- timeout mode normal (detik)
    instantDelay = 1,      -- delay sebelum tarik mode instant (detik)
    instantDepth = 999,    -- depth dikirim saat instant mode
    rodEquipped  = false,
    totalFished  = 0,
    instantMode  = false,  -- toggle: true=instant, false=normal
}

-- Listen NotifyClient — dipakai mode NORMAL
local Fish_notifyConn = nil
local Fish_fishReady  = false

local function startNotifyListener()
    local notifyEv = getFishEv("NotifyClient")
    if not notifyEv then task.delay(2, startNotifyListener); return end
    if Fish_notifyConn then Fish_notifyConn:Disconnect() end
    Fish_notifyConn = notifyEv.OnClientEvent:Connect(function(item)
        Fish_fishReady = true
        local itemName = "unknown"
        pcall(function()
            itemName = (type(item)=="userdata") and item.Name or tostring(item)
        end)
        xlog("Fish","NotifyClient: "..itemName,false)
    end)
    xlog("Fish","NotifyClient listener aktif",false)
end
startNotifyListener()

-- equipRod — cari di karakter dulu, baru backpack
local function equipRod()
    local char = getChar()
    local bp   = LP:FindFirstChild("Backpack")
    if char then
        local rod = char:FindFirstChild("AdvanceRod")
        if not rod then
            for _,t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and (t.Name:lower():find("rod") or t.Name:lower():find("pancing")) then
                    rod=t; break
                end
            end
        end
        if rod then Fish.rodEquipped=true; notify("Fishing","AdvanceRod ready!",2); return true end
    end
    if bp then
        local rod = bp:FindFirstChild("AdvanceRod")
        if not rod then
            for _,t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and (t.Name:lower():find("rod") or t.Name:lower():find("pancing")) then
                    rod=t; break
                end
            end
        end
        if rod then
            rod.Parent=char; task.wait(0.5)
            Fish.rodEquipped=true; notify("Fishing","AdvanceRod equipped!",2); return true
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

-- ── MODE INSTANT ─────────────────────────────────────────
-- cast(true) → delay singkat → cast(false, depth besar) → MiniGame(true)
-- Power bar = clientside only, server tidak validasi
-- Server mungkin validasi waktu minimal → gunakan instantDelay
local function castInstant()
    local castEv = getFishEv("CastEvent")
    local miniEv = getFishEv("MiniGame")
    if not castEv then notify("Fishing","CastEvent tidak ada!",4); return false end

    -- 1. Lempar kail
    pcall(function() castEv:FireServer(true) end)

    -- 2. Tunggu minimal delay (test: 1s, naikkan kalau server reject)
    task.wait(Fish.instantDelay)

    -- 3. Tarik paksa dengan depth besar
    pcall(function() castEv:FireServer(false, Fish.instantDepth) end)
    task.wait(0.3)

    -- 4. Complete minigame (power bar = clientside, server terima langsung)
    if miniEv then
        pcall(function() miniEv:FireServer(true) end)
    end

    Fish.totalFished = Fish.totalFished + 1
    xlog("Fish","[INSTANT] Cast #"..Fish.totalFished,false)
    task.wait(0.5)
    return true
end

-- ── MODE NORMAL ──────────────────────────────────────────
-- cast(true) → tunggu NotifyClient → cast(false, depth) → MiniGame(true)
local function castNormal()
    local castEv = getFishEv("CastEvent")
    local miniEv = getFishEv("MiniGame")
    if not castEv then notify("Fishing","CastEvent tidak ada!",4); return false end

    Fish_fishReady = false

    -- 1. Lempar kail
    pcall(function() castEv:FireServer(true) end)

    -- 2. Tunggu NotifyClient (server signal ikan kena)
    local waited  = 0
    local timeout = Fish.waitDelay
    while not Fish_fishReady and waited < timeout and Fish.autoOn do
        task.wait(0.1); waited = waited + 0.1
    end

    if not Fish.autoOn then return false end

    -- 3. Tarik dengan depth = waktu tunggu aktual
    pcall(function() castEv:FireServer(false, waited) end)
    task.wait(0.3)

    -- 4. Complete minigame
    if miniEv then
        pcall(function() miniEv:FireServer(true) end)
    end

    Fish_fishReady = false
    Fish.totalFished = Fish.totalFished + 1
    xlog("Fish","[NORMAL] Cast #"..Fish.totalFished.." waited="..string.format("%.1f",waited).."s",false)
    task.wait(1)
    return true
end

-- castOnce — router ke mode yang aktif
local function castOnce()
    if Fish.instantMode then
        return castInstant()
    else
        return castNormal()
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  SCAN AREA                                              │
-- └─────────────────────────────────────────────────────────┘
local _t=tick()
repeat task.wait(0.1)
until Workspace:FindFirstChild("Land")~=nil or #Workspace:GetChildren()>=50 or (tick()-_t)>8
buildAreaData()
if #AREA_NAMES>0 then Farm.selectedArea=AREA_NAMES[1] end

-- ┌─────────────────────────────────────────────────────────┐
-- │  WINDOW & TABS                                          │
-- └─────────────────────────────────────────────────────────┘
local Win=Library:Window("XKID HUB","sprout","v5.7",false)
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

FL:Label("📍 Penempatan Lahan")
FL:Dropdown("Pilih Tanaman","cropSel",cropDropNames,
    function(val)
        for _,c in ipairs(CROPS) do
            if val:find(c.seed,1,true) then
                Farm.selectedCrop=c
                local slot,stok=getSlotIdx(c)
                if slot then notify("Tanaman",c.seed.." | Slot "..slot.." | Stok "..stok,3)
                else notify("Tanaman",c.seed.."\n⚠ Belum di SeedPlanter! Beli dulu.",4) end
                break
            end
        end
    end,"Pilih jenis tanaman")

FL:Dropdown("Pilih Area","areaSel",
    #AREA_NAMES>0 and AREA_NAMES or {"(Scan dulu)"},
    function(val) Farm.selectedArea=val
        notify("Area",val.." | "..(AREA_PARTS[val] and #AREA_PARTS[val] or 0).." plot",2)
    end,"Pilih area lahan")

FL:Dropdown("Pola Tanam","polaSel",POLA_NAMES,
    function(val) Farm.selectedPola=val; notify("Pola",val,2) end,"Pola penanaman")

FL:Label("🌱 Eksekusi")
FL:Slider("Jumlah Plot","plantQty",1,20,5,function(v) Farm.jumlahTanam=v end,"Max 20")

FL:Button("🌱 Mulai Tanam","Tanam sesuai setting",
    function()
        task.spawn(function()
            if Farm.selectedArea=="" then notify("Farm","Pilih area dulu!",3); return end
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
        print("[XKID SLOT]\n"..txt)
    end)

-- [FIX v5.7] Tombol force refresh inventory
FL:Button("🔄 Refresh Inventory","Paksa server kirim data slot bibit",
    function()
        task.spawn(function()
            notify("Inventory","Mengambil data slot...",2)
            SeedInventory = {}  -- reset dulu
            forceRefreshInventory()
        end)
    end)

FL:Button("🔄 Scan Ulang Area","Refresh lahan",
    function()
        buildAreaData()
        local total=0; for _,v in pairs(AREA_PARTS) do total=total+#v end
        -- [FIX v5.5] Auto-set selectedArea ke area pertama setelah scan
        if #AREA_NAMES > 0 then
            Farm.selectedArea = AREA_NAMES[1]
            notify("✅ Scan","Area:"..#AREA_NAMES.." | Plot:"..total.."\nArea aktif: "..AREA_NAMES[1],5)
        else
            Farm.selectedArea = ""
            notify("⚠ Scan","Tidak ada area ditemukan!\nCoba pindah ke dekat lahan.",5)
        end
    end)

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
FR:Slider("Waktu Tumbuh (s)","growDly",15,300,60,
    function(v) Farm.growDelay=v end,"Tunggu setelah tanam")

FR:Label("✨ Fitur Tambahan")
FR:Toggle("Auto Panen","autoPanen",false,"Harvest tiap 30s",
    function(v)
        Farm.autoPanen=v
        if v then
            Farm.autoPanenTask=task.spawn(function()
                while Farm.autoPanen do
                    local n=harvestAll(); if n>0 then notify("Auto Panen",n.." plot",2) end
                    task.wait(30)
                end
            end)
            notify("Auto Panen","ON",3)
        else
            if Farm.autoPanenTask then
                pcall(function() task.cancel(Farm.autoPanenTask) end); Farm.autoPanenTask=nil end
            notify("Auto Panen","OFF",2)
        end
    end)
FR:Toggle("ESP Kematangan","espMatang",false,"% pertumbuhan tanaman",
    function(v)
        Farm.espKematangan=v; ESPCr.active=v
        if v then startESPCrop() else stopESPCrop() end
        notify("ESP Kematangan",v and "ON" or "OFF",2)
    end)
FR:Button("▶ 1 Cycle Manual","Satu cycle penuh",
    function()
        if Farm.selectedArea=="" then notify("Farm","Pilih area dulu!",3); return end
        task.spawn(runCycle)
    end)
FR:Button("✂ Panen Sekarang","Harvest semua",
    function() task.spawn(function() local n=harvestAll(); notify("Panen",n.." plot!",3) end) end)

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

-- [NEW v5.4] Fast Respawn
SecL:Label("⏪ Fast Respawn")
SecL:Button("⏪ Respawn Instant","TP ke posisi terakhir (tanpa mati)",
    function() fastRespawn() end)
SecL:Toggle("Auto Respawn","autoResp",false,"Otomatis TP setelah mati",
    function(v)
        Respawn.autoRespawn=v
        if v then startAutoRespawn(); notify("Auto Respawn","ON",3)
        else stopAutoRespawn(); notify("Auto Respawn","OFF",2) end
    end)
SecL:Button("📍 Update Posisi","Simpan posisi saat ini",
    function()
        local root=getRoot()
        if root then
            Respawn.savedPosition=root.CFrame; local p=root.Position
            notify("📍 Tersimpan",string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z),3)
        end
    end)
SecL:Button("🗑 Clear Posisi","Hapus posisi",
    function() Respawn.savedPosition=nil; notify("Posisi","Dihapus",2) end)

SecL:Button("🔄 Rejoin","Koneksi ulang",
    function()
        notify("Rejoin","Menghubungkan ulang...",3)
        task.wait(1); TpService:Teleport(game.PlaceId,LP)
    end)

SecR:Paragraph("Anti AFK","Simulasi input saat idle")
SecR:Paragraph("Anti Kick","HP < 15% → dikunci penuh")
SecR:Paragraph("Fast Respawn",
    "Instant: TP ke posisi terakhir\nAuto: aktif otomatis setelah mati\nPosisi disimpan tiap frame")

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

SetL:Label("🎣 Mode Fishing")
SetL:Toggle("⚡ Instant Mode","fishInstant",false,
    "Bypass timer server — tarik langsung tanpa tunggu ikan\nOFF = normal tunggu NotifyClient",
    function(v)
        Fish.instantMode = v
        if v then
            notify("Fishing ⚡","INSTANT MODE ON\ncast→tarik dalam "..Fish.instantDelay.."s",3)
        else
            notify("Fishing 🎣","NORMAL MODE ON\nTunggu NotifyClient server",3)
        end
    end)

SetL:Slider("Delay Instant (detik)","fishInstantDelay",1,10,1,
    function(v) Fish.instantDelay=v end,
    "Jeda sebelum tarik (instant mode)\nNaikkan kalau server reject/tidak dapat ikan")

SetL:Slider("Depth Instant","fishInstantDepth",10,999,999,
    function(v) Fish.instantDepth=v end,
    "Nilai depth dikirim ke server (instant mode)\nDefault 999 = maksimal")

SetL:Label("🎣 Auto Fishing")
SetL:Toggle("Auto Fishing","autoFish",false,"Auto equip rod + langsung cast loop",
    function(v)
        Fish.autoOn=v
        if v then
            -- [FIX v5.7] Auto equip rod dulu, lalu langsung mulai cast
            task.spawn(function()
                -- 1. Auto equip rod (cari di karakter + backpack)
                if not Fish.rodEquipped then
                    local ok = equipRod()
                    if not ok then
                        Fish.autoOn=false; return
                    end
                    task.wait(0.3)  -- sedikit jeda setelah equip
                end

                -- 2. Langsung mulai cast loop tanpa nunggu konfirmasi
                local attempts=0
                local modeStr = Fish.instantMode and "⚡ INSTANT" or "🎣 NORMAL"
                notify("Fishing 🎣","ON — "..modeStr.."\nLangsung casting!",3)

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
            if Fish.fishTask then pcall(function() task.cancel(Fish.fishTask) end); Fish.fishTask=nil end
            notify("Fishing","OFF | Total: "..Fish.totalFished,2)
        end
    end)

SetL:Button("🎣 Cast Sekali","1x cast (pakai mode aktif)",
    function()
        task.spawn(function()
            if not Fish.rodEquipped then
                local ok=equipRod(); if not ok then return end; task.wait(0.5)
            end
            -- Untuk cast sekali, set autoOn sementara
            local wasAuto = Fish.autoOn
            Fish.autoOn = true
            castOnce()
            Fish.autoOn = wasAuto
            notify("Fishing","Cast selesai | Total: "..Fish.totalFished,2)
        end)
    end)
SetL:Button("📦 Equip Rod","Cari & equip AdvanceRod",function() equipRod() end)
SetL:Button("📤 Unequip Rod","Kembalikan rod ke backpack",
    function() unequipRod(); notify("Rod","Dikembalikan",2) end)
SetL:Slider("Timeout Normal (detik)","fishWait",10,120,60,
    function(v) Fish.waitDelay=v end,"Maks tunggu ikan — mode NORMAL saja")

SetR:Paragraph("XKID HUB v5.7",
    "CHANGELOG:\n"..
    "✅ Instant Mode fishing\n"..
    "✅ Normal Mode (NotifyClient)\n"..
    "✅ equipRod cari char+bp\n"..
    "✅ Area fix + slotIdx cache\n"..
    "✅ Fast Respawn system")

SetR:Paragraph("Fishing Guide",
    "⚡ INSTANT MODE:\n"..
    "cast → delay 1s → tarik paksa\n"..
    "Power bar skip otomatis\n"..
    "Kalau tidak dapat ikan:\n"..
    "→ Naikkan Delay Instant\n\n"..
    "🎣 NORMAL MODE:\n"..
    "Tunggu server kirim NotifyClient\n"..
    "→ Tarik otomatis saat ikan kena")

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
    notify("✅ XKID HUB v5.7 Ready",
        #AREA_NAMES.." area | ".._totalPl.." plot\nBeli bibit dulu agar slot terdeteksi!",6)
else
    notify("⚠ XKID HUB v5.7",
        "Plot belum ditemukan!\nFarming → Scan Ulang Area",6)
end

Library:Notification("XKID HUB v5.7",
    "Farming · Shop · Teleport · Player · Security · Setting",6)
Library:ConfigSystem(Win)
print("[XKID HUB] v5.7 loaded — "..LP.Name)
print("[v5.7] equipRod=char+bp | castOnce=NotifyClient | MiniGame=1x | timeout=60s")
