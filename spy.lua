--[[
╔═══════════════════════════════════════════════════════════╗
║           🔍  X K I D   D E B U G   T O O L  🔍         ║
║                  Aurora UI  ·  Dev Edition               ║
╠═══════════════════════════════════════════════════════════╣
║  Scan Workspace  ·  Log Viewer  ·  Remote Inspector      ║
╚═══════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LP        = Players.LocalPlayer

-- ┌─────────────────────────────────────────────────────────┐
-- │                  LOG SYSTEM                             │
-- └─────────────────────────────────────────────────────────┘
local Logs = {}
local MAX_LOG = 200

local function addLog(tag, msg, level)
    level = level or "INFO"
    local entry = {
        tag   = tag,
        msg   = msg,
        level = level,
        time  = os.date("%H:%M:%S"),
        full  = string.format("[%s][%s][%s] %s", os.date("%H:%M:%S"), level, tag, msg)
    }
    table.insert(Logs, 1, entry)
    if #Logs > MAX_LOG then table.remove(Logs) end
    print(entry.full)
end

local function notify(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
    print(string.format("[DEBUG] %s | %s", t, tostring(b)))
end

-- ┌─────────────────────────────────────────────────────────┐
-- │              WORKSPACE SCANNER                          │
-- └─────────────────────────────────────────────────────────┘
local ScanResults = {
    allObjects   = {},
    landObjects  = {},
    baseParts    = {},
    totalScanned = 0,
}

local function doScan()
    ScanResults.allObjects  = {}
    ScanResults.landObjects = {}
    ScanResults.baseParts   = {}

    local allCh = Workspace:GetChildren()
    ScanResults.totalScanned = #allCh

    addLog("SCAN", "Mulai scan "..#allCh.." workspace objects", "INFO")

    for i, obj in ipairs(allCh) do
        local entry = {
            idx       = i,
            name      = obj.Name,
            class     = obj.ClassName,
            pos       = nil,
            size      = nil,
            childCount= 0,
            isLand    = false,
            isBigPart = false,
        }

        -- Cek apakah BasePart
        if obj:IsA("BasePart") then
            entry.pos  = obj.Position
            entry.size = obj.Size
            entry.isBigPart = obj.Size.X > 5 and obj.Size.Z > 5
            if entry.isBigPart then
                table.insert(ScanResults.baseParts, entry)
            end
        else
            entry.childCount = #obj:GetChildren()
            -- Cari BasePart anak untuk posisi
            local p = obj:FindFirstChildOfClass("BasePart")
            if p then entry.pos = p.Position; entry.size = p.Size end
        end

        -- Cek nama = lahan
        local n = obj.Name:lower()
        if n:find("land") or n:find("farm") or n:find("plot") or
           n:find("lahan") or n:find("tanah") or n:find("field") or
           n:find("area") or n:find("tile") or n:find("sawah") then
            entry.isLand = true
            table.insert(ScanResults.landObjects, entry)
        end

        table.insert(ScanResults.allObjects, entry)
    end

    addLog("SCAN", string.format(
        "Selesai: %d total | %d land | %d BasePart besar",
        #ScanResults.allObjects, #ScanResults.landObjects, #ScanResults.baseParts), "INFO")
end

-- ┌─────────────────────────────────────────────────────────┐
-- │              REMOTE INSPECTOR                           │
-- └─────────────────────────────────────────────────────────┘
local RemoteLog = {}
local remoteConn = nil

local function startRemoteListener()
    if remoteConn then remoteConn:Disconnect() end
    local bn = RS:FindFirstChild("BridgeNet2")
    if not bn then addLog("REMOTE","BridgeNet2 tidak ada!","WARN"); return end
    local ev = bn:FindFirstChild("dataRemoteEvent")
    if not ev then addLog("REMOTE","dataRemoteEvent tidak ada!","WARN"); return end

    remoteConn = ev.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        local keys = {}
        for k,_ in pairs(data) do
            table.insert(keys, string.format("\\x%02x(%d)", string.byte(k), string.byte(k)))
        end
        local entry = string.format("Keys: %s", table.concat(keys, ", "))
        table.insert(RemoteLog, 1, {time=os.date("%H:%M:%S"), data=entry, raw=data})
        if #RemoteLog > 50 then table.remove(RemoteLog) end
        addLog("REMOTE", entry, "INFO")

        -- Cek key \3 (inventory)
        if data["\3"] then
            local inv = data["\3"][1]
            if inv then
                for slot, entry2 in ipairs(inv) do
                    if entry2.cropName then
                        addLog("INV", string.format("slot=%d %s x%d",
                            slot, entry2.cropName, entry2.count or 0), "INFO")
                    end
                end
            end
        end

        -- Cek key \13 (harvest)
        if data["\13"] then
            local h = data["\13"][1]
            if h then
                addLog("HARVEST", string.format("crop=%s pos=(%.1f,%.1f,%.1f)",
                    h.cropName or "?",
                    h.cropPos and h.cropPos.X or 0,
                    h.cropPos and h.cropPos.Y or 0,
                    h.cropPos and h.cropPos.Z or 0), "INFO")
            end
        end
    end)
    addLog("REMOTE","Listener aktif — menunggu data...","INFO")
end

-- FishRemotes listener
local fishConns = {}
local function startFishListener()
    for _, conn in pairs(fishConns) do pcall(function() conn:Disconnect() end) end
    fishConns = {}

    local fr = RS:FindFirstChild("FishRemotes")
    if not fr then addLog("FISH","FishRemotes tidak ada!","WARN"); return end

    local evNames = {"CastEvent","MiniGame","NotifyClient"}
    for _, evName in ipairs(evNames) do
        local ev = fr:FindFirstChild(evName)
        if ev then
            local conn = ev.OnClientEvent:Connect(function(...)
                local args = {...}
                local argStr = ""
                for _, a in ipairs(args) do
                    argStr = argStr..tostring(a).." "
                end
                addLog("FISH."..evName, "OnClientEvent: "..argStr, "INFO")
            end)
            table.insert(fishConns, conn)
            addLog("FISH","Listener: "..evName,"INFO")
        end
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                    UI                                   │
-- └─────────────────────────────────────────────────────────┘
local Win   = Library:Window("XKID DEBUG","search","Dev",false)
Win:TabSection("DEBUG")
local T_Scan   = Win:Tab("Scan","search")
local T_Log    = Win:Tab("Log","list")
local T_Remote = Win:Tab("Remote","wifi")
local T_Fish   = Win:Tab("Fishing","anchor")

-- ╔═══════════════════════════════╗
-- ║         TAB SCAN              ║
-- ╚═══════════════════════════════╝
local SP  = T_Scan:Page("Workspace Scanner","search")
local SL  = SP:Section("🔍 Scanner","Left")
local SR  = SP:Section("📊 Hasil","Right")

SL:Button("▶ Scan Workspace","Scan semua workspace children",
    function()
        doScan()
        notify("✅ Scan Selesai",
            ScanResults.totalScanned.." objects\n"..
            #ScanResults.landObjects.." land\n"..
            #ScanResults.baseParts.." BasePart besar", 5)
    end)

SL:Button("📋 Lihat Land Objects","Tampilkan objek bermana Land/Farm/dll",
    function()
        if #ScanResults.landObjects == 0 then
            notify("Scan","Belum scan / tidak ada land object",3); return
        end
        local txt = ""
        for _, e in ipairs(ScanResults.landObjects) do
            local posStr = e.pos and string.format("(%.0f,%.0f,%.0f)",
                e.pos.X, e.pos.Y, e.pos.Z) or "no pos"
            txt = txt..string.format("[%d] %s (%s) %s\n",
                e.idx, e.name, e.class, posStr)
        end
        notify("🏞 Land Objects ("..#ScanResults.landObjects..")", txt, 15)
        print("[XKID LAND SCAN]\n"..txt)
    end)

SL:Button("📋 Lihat BasePart Besar","BasePart Size > 5x5 (kemungkinan lahan)",
    function()
        if #ScanResults.baseParts == 0 then
            notify("Scan","Belum scan / tidak ada BasePart besar",3); return
        end
        local txt = ""
        for _, e in ipairs(ScanResults.baseParts) do
            local posStr = e.pos and string.format("(%.0f,%.0f,%.0f)",
                e.pos.X, e.pos.Y, e.pos.Z) or "?"
            local sizeStr = e.size and string.format("%.0fx%.0f",
                e.size.X, e.size.Z) or "?"
            txt = txt..string.format("[%d] %s %s size=%s\n",
                e.idx, e.name, posStr, sizeStr)
        end
        notify("🧱 BasePart Besar ("..#ScanResults.baseParts..")", txt, 15)
        print("[XKID BASEPART SCAN]\n"..txt)
    end)

SL:Button("📋 Index 50-70","Detail index 50 sampai 70",
    function()
        local allCh = Workspace:GetChildren()
        local txt = ""
        for i = 50, math.min(70, #allCh) do
            local obj = allCh[i]
            if obj then
                local pos = ""
                if obj:IsA("BasePart") then
                    pos = string.format(" (%.0f,%.0f,%.0f)",
                        obj.Position.X, obj.Position.Y, obj.Position.Z)
                else
                    local p = obj:FindFirstChildOfClass("BasePart")
                    if p then pos = string.format(" (%.0f,%.0f,%.0f)",
                        p.Position.X, p.Position.Y, p.Position.Z) end
                end
                txt = txt..string.format("[%d] %s (%s)%s\n",
                    i, obj.Name, obj.ClassName, pos)
                print(string.format("[%d] %s (%s)%s", i, obj.Name, obj.ClassName, pos))
            end
        end
        notify("Index 50-70", txt:sub(1,500), 15)
    end)

SL:Button("📋 SEMUA Index","Print semua ke console (copy dari sana)",
    function()
        local allCh = Workspace:GetChildren()
        print("=== XKID FULL WORKSPACE SCAN ===")
        print("Total: "..#allCh)
        for i, obj in ipairs(allCh) do
            local extra = ""
            if obj:IsA("BasePart") then
                extra = string.format(" pos=(%.1f,%.1f,%.1f) size=(%.1f,%.1f,%.1f)",
                    obj.Position.X, obj.Position.Y, obj.Position.Z,
                    obj.Size.X, obj.Size.Y, obj.Size.Z)
            else
                local p = obj:FindFirstChildOfClass("BasePart")
                if p then extra = string.format(" pos=(%.1f,%.1f,%.1f)",
                    p.Position.X, p.Position.Y, p.Position.Z) end
                extra = extra.." children="..#obj:GetChildren()
            end
            print(string.format("[%d] %s (%s)%s", i, obj.Name, obj.ClassName, extra))
        end
        print("=== SELESAI ===")
        notify("✅ Scan","Selesai! Lihat console executor\n(Copy hasil dari sana)",5)
    end)

SR:Button("📋 workspace.Land Detail","Scan isi workspace.Land",
    function()
        local land = Workspace:FindFirstChild("Land")
        if not land then notify("Land","workspace.Land tidak ada!",3); return end

        print("=== WORKSPACE.LAND DETAIL ===")
        print("ClassName: "..land.ClassName)
        local children = land:GetChildren()
        print("Children: "..#children)

        local txt = "Class: "..land.ClassName.."\nChildren: "..#children.."\n"

        if land:IsA("BasePart") then
            local info = string.format("Pos=(%.1f,%.1f,%.1f) Size=(%.1f,%.1f,%.1f)",
                land.Position.X, land.Position.Y, land.Position.Z,
                land.Size.X, land.Size.Y, land.Size.Z)
            print(info); txt = txt..info.."\n"
        end

        for i, child in ipairs(children) do
            local cinfo = ""
            if child:IsA("BasePart") then
                cinfo = string.format(" pos=(%.1f,%.1f,%.1f)",
                    child.Position.X, child.Position.Y, child.Position.Z)
            end
            local line = string.format("[%d] %s (%s)%s", i, child.Name, child.ClassName, cinfo)
            print(line)
            if i <= 20 then txt = txt..line.."\n" end
        end
        notify("workspace.Land", txt, 15)
    end)

SR:Button("📍 Posisi Karakter","Print posisi player sekarang",
    function()
        local char = LP.Character
        if not char then notify("Pos","Tidak ada karakter",2); return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local p = hrp.Position
            local msg = string.format("X=%.4f\nY=%.4f\nZ=%.4f", p.X, p.Y, p.Z)
            notify("📍 Posisi", msg, 8)
            print(string.format("[POS] X=%.4f Y=%.4f Z=%.4f", p.X, p.Y, p.Z))
        end
    end)

SR:Button("🗂 RS Structure","Scan ReplicatedStorage",
    function()
        print("=== REPLICATED STORAGE ===")
        local txt = ""
        for i, obj in ipairs(RS:GetChildren()) do
            local line = string.format("[%d] %s (%s)", i, obj.Name, obj.ClassName)
            -- Cek anak
            local children = obj:GetChildren()
            if #children > 0 then
                local childNames = {}
                for _, c in ipairs(children) do
                    table.insert(childNames, c.Name)
                end
                line = line.." → ["..table.concat(childNames, ", ").."]"
            end
            print(line); txt = txt..line.."\n"
        end
        notify("RS Structure", txt:sub(1,500), 15)
    end)

-- ╔═══════════════════════════════╗
-- ║         TAB LOG               ║
-- ╚═══════════════════════════════╝
local LP_pg = T_Log:Page("Log Viewer","list")
local LL  = LP_pg:Section("📋 Log","Left")
local LR  = LP_pg:Section("🔧 Controls","Right")

LL:Button("📋 Log Terbaru (10)","Tampilkan 10 log terakhir",
    function()
        if #Logs == 0 then notify("Log","Belum ada log",2); return end
        local txt = ""
        for i = 1, math.min(10, #Logs) do
            txt = txt..Logs[i].full.."\n"
        end
        notify("📋 Log ("..#Logs.." total)", txt, 15)
    end)

LL:Button("📋 Log ERROR saja","Filter hanya level ERROR/WARN",
    function()
        local filtered = {}
        for _, e in ipairs(Logs) do
            if e.level == "ERROR" or e.level == "WARN" then
                table.insert(filtered, e)
            end
        end
        if #filtered == 0 then notify("Log","Tidak ada error/warn",3); return end
        local txt = ""
        for i = 1, math.min(10, #filtered) do
            txt = txt..filtered[i].full.."\n"
        end
        notify("⚠ Error Log ("..#filtered..")", txt, 15)
    end)

LL:Button("📋 Print Semua Log","Print semua ke console",
    function()
        print("=== XKID DEBUG LOG ("..#Logs.." entries) ===")
        for i = #Logs, 1, -1 do
            print(Logs[i].full)
        end
        print("=== END LOG ===")
        notify("Log","Semua log di-print ke console",3)
    end)

LR:Button("🗑 Clear Log","Hapus semua log",
    function() Logs = {}; notify("Log","Dibersihkan",2) end)

LR:Button("📊 Log Stats","Statistik log",
    function()
        local counts = {INFO=0, WARN=0, ERROR=0}
        local tags = {}
        for _, e in ipairs(Logs) do
            counts[e.level] = (counts[e.level] or 0) + 1
            tags[e.tag] = (tags[e.tag] or 0) + 1
        end
        local tagStr = ""
        for tag, count in pairs(tags) do
            tagStr = tagStr..tag.."="..count.." "
        end
        notify("📊 Log Stats",
            string.format("Total: %d\nINFO: %d | WARN: %d | ERROR: %d\n%s",
                #Logs, counts.INFO, counts.WARN, counts.ERROR, tagStr), 8)
    end)

LR:Paragraph("Cara Copy Log",
    "1. Klik 'Print Semua Log'\n"..
    "2. Buka console executor\n"..
    "3. Select all & copy\n"..
    "4. Kirim ke developer")

-- ╔═══════════════════════════════╗
-- ║         TAB REMOTE            ║
-- ╚═══════════════════════════════╝
local RP  = T_Remote:Page("Remote Inspector","wifi")
local RL  = RP:Section("📡 BridgeNet2","Left")
local RR  = RP:Section("📡 FishRemotes","Right")

RL:Toggle("Listen dataRemoteEvent","listenRemote",false,
    "Monitor semua data dari BridgeNet2",
    function(v)
        if v then
            startRemoteListener()
            notify("Remote","Listener ON — cek Log tab",3)
        else
            if remoteConn then remoteConn:Disconnect(); remoteConn=nil end
            notify("Remote","Listener OFF",2)
        end
    end)

RL:Button("📋 Remote Log Terbaru","10 data remote terakhir",
    function()
        if #RemoteLog == 0 then notify("Remote","Belum ada data",3); return end
        local txt = ""
        for i = 1, math.min(10, #RemoteLog) do
            txt = txt..string.format("[%s] %s\n", RemoteLog[i].time, RemoteLog[i].data)
        end
        notify("📡 Remote Log", txt, 15)
        print("=== REMOTE LOG ===")
        for i = 1, math.min(20, #RemoteLog) do
            print(string.format("[%s] %s", RemoteLog[i].time, RemoteLog[i].data))
        end
    end)

RL:Button("🔍 Cek Keys \\ 3 (Inventory)","Tunggu 5s lalu cek inventory data",
    function()
        -- Trigger dummy untuk paksa server kirim inventory
        local bn = RS:FindFirstChild("BridgeNet2")
        local ev = bn and bn:FindFirstChild("dataRemoteEvent")
        if not ev then notify("Remote","dataRemoteEvent tidak ada!",3); return end

        notify("Remote","Menunggu data inventory...",3)
        -- Listen sementara
        local conn
        local received = false
        conn = ev.OnClientEvent:Connect(function(data)
            if type(data) == "table" and data["\3"] then
                received = true
                conn:Disconnect()
                local inv = data["\3"][1]
                if inv then
                    local txt = ""
                    for slot, entry in ipairs(inv) do
                        if entry.cropName then
                            txt = txt..string.format("[%d] %s x%d\n",
                                slot, entry.cropName, entry.count or 0)
                        end
                    end
                    notify("✅ Inventory Data", txt, 10)
                    print("[XKID INV]\n"..txt)
                    addLog("INV","Data diterima: "..txt:gsub("\n"," "),"INFO")
                end
            end
        end)
        task.delay(5, function()
            if not received then
                conn:Disconnect()
                notify("Remote","Tidak ada data \\3 dalam 5s\nCoba beli bibit",4)
            end
        end)
    end)

RR:Toggle("Listen FishRemotes","listenFish",false,
    "Monitor CastEvent, MiniGame, NotifyClient",
    function(v)
        if v then
            startFishListener()
            notify("Fish","Listener ON — cek Log tab",3)
        else
            for _, conn in pairs(fishConns) do
                pcall(function() conn:Disconnect() end)
            end
            fishConns = {}
            notify("Fish","Listener OFF",2)
        end
    end)

RR:Button("📋 Fish Remote Log","Log fishing events",
    function()
        local fishLogs = {}
        for _, e in ipairs(Logs) do
            if e.tag:sub(1,4) == "FISH" then
                table.insert(fishLogs, e)
            end
        end
        if #fishLogs == 0 then notify("Fish","Belum ada fish log",3); return end
        local txt = ""
        for i = 1, math.min(15, #fishLogs) do
            txt = txt..string.format("[%s] %s: %s\n",
                fishLogs[i].time, fishLogs[i].tag, fishLogs[i].msg)
        end
        notify("🎣 Fish Log ("..#fishLogs..")", txt, 15)
        print("=== FISH LOG ===")
        for _, e in ipairs(fishLogs) do print(e.full) end
    end)

RR:Paragraph("Cara Debug Fishing",
    "1. ON Listen FishRemotes\n"..
    "2. Mancing manual 1x\n"..
    "3. Klik Fish Remote Log\n"..
    "4. Lihat urutan event\n"..
    "5. Kirim ke developer")

-- ╔═══════════════════════════════╗
-- ║         TAB FISHING           ║
-- ╚═══════════════════════════════╝
local FP  = T_Fish:Page("Fishing Debug","anchor")
local FL2 = FP:Section("🎣 Fish Events","Left")
local FR2 = FP:Section("📊 Analysis","Right")

local fishEventLog = {}

FL2:Button("▶ Start Fish Monitor","Monitor semua fishing event",
    function()
        local fr = RS:FindFirstChild("FishRemotes")
        if not fr then notify("Fish","FishRemotes tidak ada!",3); return end

        fishEventLog = {}
        local conns = {}

        -- Monitor CastEvent
        local castEv = fr:FindFirstChild("CastEvent")
        if castEv then
            table.insert(conns, castEv.OnClientEvent:Connect(function(...)
                local entry = {time=os.date("%H:%M:%S"), ev="CastEvent.OnClient", args={...}}
                table.insert(fishEventLog, entry)
                print(string.format("[FISH] CastEvent.OnClient: %s", tostring((...))))
            end))
        end

        -- Monitor MiniGame
        local miniEv = fr:FindFirstChild("MiniGame")
        if miniEv then
            table.insert(conns, miniEv.OnClientEvent:Connect(function(...)
                local args = {...}
                local entry = {time=os.date("%H:%M:%S"), ev="MiniGame.OnClient", args=args}
                table.insert(fishEventLog, entry)
                local argStr = ""
                for _, a in ipairs(args) do argStr = argStr..tostring(a).." " end
                print(string.format("[FISH] MiniGame.OnClient: %s", argStr))
                addLog("FISH.MiniGame","Server: "..argStr,"INFO")
            end))
        end

        -- Monitor NotifyClient
        local notifyEv = fr:FindFirstChild("NotifyClient")
        if notifyEv then
            table.insert(conns, notifyEv.OnClientEvent:Connect(function(item)
                local itemName = "?"
                pcall(function()
                    itemName = (type(item)=="userdata") and item.Name or tostring(item)
                end)
                local entry = {time=os.date("%H:%M:%S"), ev="NotifyClient", item=itemName}
                table.insert(fishEventLog, entry)
                print(string.format("[FISH] NotifyClient: %s", itemName))
                addLog("FISH.Notify","Ikan: "..itemName,"INFO")
            end))
        end

        -- Auto stop setelah 5 menit
        task.delay(300, function()
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        end)

        notify("🎣 Fish Monitor","ON — Mancing manual 1x\nlalu cek hasilnya",4)
        addLog("FISH","Monitor aktif","INFO")
    end)

FL2:Button("📋 Lihat Fish Events","Tampilkan semua event yang terekam",
    function()
        if #fishEventLog == 0 then
            notify("Fish","Belum ada event\nMancing manual dulu!",3); return
        end
        local txt = ""
        for i, e in ipairs(fishEventLog) do
            txt = txt..string.format("[%s] %s\n", e.time, e.ev)
            if e.item then txt = txt.."  item="..e.item.."\n" end
            if e.args then
                for _, a in ipairs(e.args) do
                    txt = txt.."  arg="..tostring(a).."\n"
                end
            end
        end
        notify("🎣 Fish Events ("..#fishEventLog..")", txt:sub(1,500), 15)
        print("=== FISH EVENT LOG ===")
        print(txt)
    end)

FL2:Button("🗑 Clear Fish Log","Hapus log fishing",
    function() fishEventLog = {}; notify("Fish","Cleared",2) end)

FR2:Paragraph("Urutan Event Fishing",
    "Yang kita expect:\n\n"..
    "1. cast(true) → SERVER\n"..
    "2. Tunggu...\n"..
    "3. NotifyClient ← SERVER\n"..
    "4. MiniGame 'Start' ← SERVER\n"..
    "5. MiniGame(true) → SERVER\n"..
    "6. MiniGame 'Stop' ← SERVER\n\n"..
    "Catat jika beda!")

FR2:Button("🔍 Cek FishRemotes","Lihat semua event di FishRemotes",
    function()
        local fr = RS:FindFirstChild("FishRemotes")
        if not fr then notify("Fish","FishRemotes tidak ada!",3); return end
        local txt = ""
        print("=== FISHREMOTES ===")
        for _, ev in ipairs(fr:GetChildren()) do
            local line = string.format("%s (%s)", ev.Name, ev.ClassName)
            print(line); txt = txt..line.."\n"
        end
        notify("FishRemotes", txt, 8)
    end)

-- ┌─────────────────────────────────────────────────────────┐
-- │                      INIT                               │
-- └─────────────────────────────────────────────────────────┘
-- Auto scan saat load
task.spawn(function()
    task.wait(1)
    doScan()
end)

Library:Notification("XKID DEBUG","Scan · Log · Remote · Fishing",5)
Library:ConfigSystem(Win)
addLog("SYSTEM","XKID Debug Tool loaded","INFO")
print("[XKID DEBUG] Loaded — "..LP.Name)
