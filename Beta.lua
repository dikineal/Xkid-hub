--[[
╔═══════════════════════════════════════════════════════════╗
║        🔍  X K I D   D E B U G   T O O L  v5            ║
║     Aurora UI · setclipboard · Delta Ready               ║
║     + FARMING SPY (harvest, tanam, inventory)            ║
╚═══════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LP        = Players.LocalPlayer

local function notif(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  LOG BUFFER                                             │
-- └─────────────────────────────────────────────────────────┘
local LogBuffer = ""

local function log(msg)
    LogBuffer = LogBuffer .. os.date("[%H:%M:%S] ") .. msg .. "\n"
end

local function clearLog()
    LogBuffer = ""
end

local function copyLog()
    if LogBuffer == "" then
        notif("Copy","Log kosong! Jalankan scan dulu.",3)
        return
    end
    local ok = pcall(function()
        setclipboard(LogBuffer)
    end)
    if ok then
        local lineCount = 0
        for _ in LogBuffer:gmatch("\n") do lineCount = lineCount + 1 end
        notif("✅ COPIED!",lineCount.." baris\ndi clipboard!\nPaste ke WA/chat",4)
    else
        notif("❌ Copy Gagal","setclipboard tidak support\nCoba screenshot notif.",4)
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  WORKSPACE SCANNER                                      │
-- └─────────────────────────────────────────────────────────┘
local function scanRange(a, b)
    local allCh = Workspace:GetChildren()
    log("=== SCAN ["..a.."-"..b.."] | Total WS: "..#allCh.." ===")
    for i = a, math.min(b, #allCh) do
        local obj = allCh[i]
        if not obj then log("["..i.."] nil"); continue end
        local pos, size = "", ""
        if obj:IsA("BasePart") then
            pos  = string.format(" pos=(%.1f,%.1f,%.1f)", obj.Position.X, obj.Position.Y, obj.Position.Z)
            size = string.format(" sz=(%.1f,%.1f,%.1f)",  obj.Size.X, obj.Size.Y, obj.Size.Z)
        else
            local p = obj:FindFirstChildOfClass("BasePart")
            if p then pos = string.format(" pos=(%.1f,%.1f,%.1f)", p.Position.X, p.Position.Y, p.Position.Z) end
            pos = pos .. " ch=" .. #obj:GetChildren()
        end
        log(string.format("[%d] %s (%s)%s%s", i, obj.Name, obj.ClassName, pos, size))
    end
    log("=== SELESAI ===")
    notif("✅ Scan ["..a.."-"..b.."]","Klik COPY LOG!",3)
end

local function scanFull()
    local allCh = Workspace:GetChildren()
    log("=== FULL SCAN | Total: "..#allCh.." ===")
    for i, obj in ipairs(allCh) do
        local pos, size, tag = "", "", ""
        if obj:IsA("BasePart") then
            pos  = string.format(" pos=(%.0f,%.0f,%.0f)", obj.Position.X, obj.Position.Y, obj.Position.Z)
            size = string.format(" sz=(%.0f,%.0f,%.0f)",  obj.Size.X, obj.Size.Y, obj.Size.Z)
            if obj.Size.X > 5 and obj.Size.Z > 5 then tag = " [BIGPART]" end
        else
            local p = obj:FindFirstChildOfClass("BasePart")
            if p then
                pos = string.format(" pos=(%.0f,%.0f,%.0f)", p.Position.X, p.Position.Y, p.Position.Z)
                if p.Size.X > 5 and p.Size.Z > 5 then tag = " [BIGPART]" end
            end
            pos = pos .. " ch=" .. #obj:GetChildren()
        end
        local n = obj.Name:lower()
        if n:find("land") or n:find("farm") or n:find("plot") or
           n:find("lahan") or n:find("tanah") or n:find("sawah") then
            tag = tag .. " [LAND]"
        end
        log(string.format("[%d] %s (%s)%s%s%s", i, obj.Name, obj.ClassName, pos, size, tag))
    end
    log("=== SELESAI ===")
    notif("✅ Full Scan","Klik COPY LOG!",3)
end

local function scanLand()
    log("=== workspace.Land ===")
    local land = Workspace:FindFirstChild("Land")
    if not land then log("TIDAK ADA!"); notif("Land","Tidak ada",3); return end
    log("Class: "..land.ClassName)
    if land:IsA("BasePart") then
        log(string.format("Pos=(%.2f,%.2f,%.2f) Size=(%.2f,%.2f,%.2f)",
            land.Position.X, land.Position.Y, land.Position.Z,
            land.Size.X, land.Size.Y, land.Size.Z))
    end
    local ch = land:GetChildren()
    log("Children: "..#ch)
    for i, c in ipairs(ch) do
        local p = ""
        if c:IsA("BasePart") then
            p = string.format(" pos=(%.1f,%.1f,%.1f)", c.Position.X, c.Position.Y, c.Position.Z)
        end
        log(string.format("  [%d] %s (%s)%s", i, c.Name, c.ClassName, p))
    end
    local bps = 0
    for _, d in ipairs(land:GetDescendants()) do
        if d:IsA("BasePart") then
            bps = bps + 1
            if bps <= 10 then
                log(string.format("  BP[%d] %s pos=(%.1f,%.1f,%.1f)",
                    bps, d.Name, d.Position.X, d.Position.Y, d.Position.Z))
            end
        end
    end
    log("Total BasePart: "..bps)
    log("=== SELESAI ===")
    notif("workspace.Land","Klik COPY LOG!",3)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  FISH MONITOR                                           │
-- └─────────────────────────────────────────────────────────┘
local fishConns = {}

local function startFish()
    for _, c in pairs(fishConns) do pcall(function() c:Disconnect() end) end
    fishConns = {}
    local fr = RS:FindFirstChild("FishRemotes")
    if not fr then notif("Fish ❌","FishRemotes tidak ada!",4); return false end
    log("=== FISH MONITOR START ===")
    for _, evName in ipairs({"CastEvent","MiniGame","NotifyClient"}) do
        local ev = fr:FindFirstChild(evName)
        if ev then
            log("Listen OK: "..evName)
            local conn = ev.OnClientEvent:Connect(function(...)
                local parts = {}
                for _, a in ipairs({...}) do
                    local s = "?"
                    pcall(function()
                        s = (type(a)=="userdata") and (a.Name or tostring(a)) or tostring(a)
                    end)
                    table.insert(parts, s)
                end
                log("← "..evName..": "..table.concat(parts, ", "))
            end)
            table.insert(fishConns, conn)
        else
            log("MISSING: "..evName)
        end
    end
    log("Mancing manual 1x sekarang!")
    notif("🎣 Fish Monitor","ON! Mancing manual 1x\nlalu klik COPY LOG",4)
    return true
end

local function stopFish()
    for _, c in pairs(fishConns) do pcall(function() c:Disconnect() end) end
    fishConns = {}
    log("=== FISH MONITOR STOP ===")
    notif("Fish","OFF — Klik COPY LOG",3)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  INVENTORY MONITOR                                      │
-- └─────────────────────────────────────────────────────────┘
local invConn = nil

local function startInv()
    if invConn then invConn:Disconnect() end
    local bn = RS:FindFirstChild("BridgeNet2")
    local ev = bn and bn:FindFirstChild("dataRemoteEvent")
    if not ev then notif("Inv ❌","dataRemoteEvent tidak ada!",4); return false end
    log("=== INVENTORY MONITOR START ===")
    invConn = ev.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        local keys = {}
        for k in pairs(data) do
            table.insert(keys, string.format("\\x%02x", string.byte(k,1)))
        end
        log("Keys: "..table.concat(keys," "))
        if data["\3"] then
            local list = data["\3"][1]
            if type(list)=="table" then
                log("--- Inventory ---")
                for slot, e in ipairs(list) do
                    if type(e)=="table" and e.cropName then
                        log(string.format("slot[%d] %s x%d", slot, e.cropName, e.count or 0))
                    end
                end
            end
        end
    end)
    notif("📦 Inv Monitor","ON! Beli bibit lalu\nklik COPY LOG",4)
    return true
end

local function stopInv()
    if invConn then invConn:Disconnect(); invConn=nil end
    log("=== INVENTORY MONITOR STOP ===")
    notif("Inv","OFF — Klik COPY LOG",3)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  [NEW] FARMING SPY                                      │
-- │  Monitor semua event farming:                           │
-- │  - OnClientEvent: harvest ready (\r), inventory (\3)   │
-- │  - Timer data (\x02)                                   │
-- │  - Semua outgoing FireServer (tanam, beli, harvest)     │
-- └─────────────────────────────────────────────────────────┘
local farmConn    = nil
local farmSpyOn   = false

local function deepSerialize(val, depth)
    depth = depth or 0
    if depth > 4 then return "..." end
    local t = type(val)
    if t == "nil" then return "nil"
    elseif t == "boolean" or t == "number" then return tostring(val)
    elseif t == "string" then
        -- Print hex untuk kontrol karakter
        if #val <= 4 then
            local hex = ""
            for i = 1, #val do
                hex = hex .. string.format("\\x%02x", val:byte(i))
            end
            return '"'..hex..'"'
        end
        return '"'..val:sub(1,50)..'"'
    elseif t == "userdata" then
        local s = "?"
        pcall(function()
            if val.X then -- Vector3
                s = string.format("V3(%.2f,%.2f,%.2f)", val.X, val.Y, val.Z)
            else
                s = tostring(val)
            end
        end)
        return s
    elseif t == "table" then
        local parts = {}
        local count = 0
        for k, v in pairs(val) do
            count = count + 1
            if count > 20 then
                table.insert(parts, "..."); break
            end
            local keyStr = ""
            if type(k) == "string" and #k <= 4 then
                local hex = ""
                for i = 1, #k do hex = hex .. string.format("\\x%02x", k:byte(i)) end
                keyStr = "["..hex.."]"
            else
                keyStr = "["..tostring(k).."]"
            end
            table.insert(parts, keyStr.."="..deepSerialize(v, depth+1))
        end
        return "{"..table.concat(parts,", ").."}"
    end
    return tostring(val)
end

local function startFarmSpy()
    if farmConn then farmConn:Disconnect() end
    local bn = RS:FindFirstChild("BridgeNet2")
    local ev = bn and bn:FindFirstChild("dataRemoteEvent")
    if not ev then notif("Farm ❌","dataRemoteEvent tidak ada!",4); return false end

    log("=== FARMING SPY START ===")
    log("Lakukan: tanam, tunggu tumbuh, panen manual")
    log("Semua event akan ter-log di sini")
    log("")

    farmConn = ev.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end

        -- Identifikasi jenis event
        local keys = {}
        for k in pairs(data) do
            table.insert(keys, string.format("\\x%02x(%d)", string.byte(k,1), string.byte(k,1)))
        end
        log("── OnClientEvent keys: "..table.concat(keys," "))

        -- Key \x03 = inventory update
        if data["\3"] then
            local list = data["\3"][1]
            if type(list) == "table" then
                log("  [\\x03 INVENTORY UPDATE]")
                for slot, e in ipairs(list) do
                    if type(e) == "table" and e.cropName then
                        log(string.format("    slot[%d] %s x%d", slot, e.cropName, e.count or 0))
                    end
                end
            end
        end

        -- Key \r (\x0d) = crop ready / harvest data
        if data["\r"] then
            log("  [\\x0d CROP READY/HARVEST DATA] ← PENTING!")
            for i, crop in ipairs(data["\r"]) do
                if type(crop) == "table" then
                    log(string.format("    [%d] cropName=%s", i, tostring(crop.cropName)))
                    if crop.cropPos then
                        log(string.format("    [%d] cropPos=(%.4f,%.4f,%.4f)",
                            i, crop.cropPos.X, crop.cropPos.Y, crop.cropPos.Z))
                    end
                    log(string.format("    [%d] sellPrice=%s", i, tostring(crop.sellPrice)))
                    if crop.seedColor then
                        log(string.format("    [%d] seedColor=(%.4f,%.4f,%.4f)",
                            i, crop.seedColor[1] or 0, crop.seedColor[2] or 0, crop.seedColor[3] or 0))
                    end
                    if crop.drops then
                        for di, drop in ipairs(crop.drops) do
                            log(string.format("    [%d] drop[%d]: name=%s rarity=%s coin=%s",
                                i, di,
                                tostring(drop.name),
                                tostring(drop.rarity),
                                tostring(drop.coinReward)))
                        end
                    end
                end
            end
        end

        -- Key \x02 = timer data
        if data["\2"] then
            local timer = data["\2"]
            log(string.format("  [\\x02 TIMER] start=%s end=%s diff=%s",
                tostring(timer[1]),
                tostring(timer[2]),
                (timer[1] and timer[2]) and tostring(timer[2]-timer[1]) or "?"))
        end

        -- Key \x0b (\v) = transaksi sukses
        if data["\11"] then
            local tx = data["\11"][1]
            if type(tx) == "table" then
                log(string.format("  [\\x0b TRANSAKSI] success=%s count=%s",
                    tostring(tx.success), tostring(tx.count)))
            end
        end

        -- Key \x08 = unknown, log raw
        if data["\8"] then
            log("  [\\x08] "..deepSerialize(data["\8"], 0))
        end

        log("")
    end)

    notif("🌱 Farm Spy","ON!\nLakukan tanam → tunggu → panen manual\nSemua event ter-log",5)
    return true
end

local function stopFarmSpy()
    if farmConn then farmConn:Disconnect(); farmConn=nil end
    farmSpyOn = false
    log("=== FARMING SPY STOP ===")
    notif("Farm Spy","OFF — Klik COPY LOG",3)
end

-- Scan tanaman di workspace
local function scanCrops()
    log("=== SCAN TANAMAN DI WORKSPACE ===")
    local cropNames = {
        "AppleTree","Padi","Melon","Tomat","Sawi",
        "Coconut","Daisy","FanPalm","SunFlower","Sawit",
        -- Kemungkinan nama lain:
        "Apple","Rice","Corn","Wheat","Carrot",
    }
    local found = 0

    -- Scan semua descendants workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local n = obj.Name
        -- Cek exact match dulu
        local isKnown = false
        for _, cn in ipairs(cropNames) do
            if n == cn then isKnown = true; break end
        end

        if isKnown or obj:IsA("BasePart") and obj.Size.Y > 0.5 and obj.Size.Y < 5 then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local pos = nil
                if obj:IsA("BasePart") then pos = obj.Position
                else
                    local p = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                    if p then pos = p.Position end
                end
                if pos then
                    found = found + 1
                    if found <= 30 then
                        log(string.format("  CROP[%d] name=%s class=%s pos=(%.1f,%.1f,%.1f)",
                            found, n, obj.ClassName, pos.X, pos.Y, pos.Z))
                    end
                end
            end
        end
    end

    if found == 0 then
        log("  Tidak ada tanaman ditemukan")
        log("  Pastikan ada tanaman yang sudah ditanam!")
    end
    log(string.format("Total: %d objek", found))
    log("=== SELESAI ===")
    notif("Scan Tanaman",found.." tanaman\nKlik COPY LOG!",4)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  UI                                                     │
-- └─────────────────────────────────────────────────────────┘
local Win    = Library:Window("XKID DEBUG v6","search","v6",false)
Win:TabSection("DEBUG")
local T_Scan    = Win:Tab("Scan","search")
local T_Farm    = Win:Tab("Farm","leaf")
local T_Fish    = Win:Tab("Fish","anchor")
local T_Inv     = Win:Tab("Inv","package")
local T_Harvest = Win:Tab("Harvest","box")

-- ╔══════════════════╗
-- ║   TAB SCAN       ║
-- ╚══════════════════╝
local SP = T_Scan:Page("Workspace Scan","search")
local SL = SP:Section("🔍 Scan","Left")
local SR = SP:Section("📋 Copy","Right")

SL:Button("★ FULL SCAN","Scan semua workspace objects",
    function() clearLog(); scanFull() end)

SL:Button("Index 40-55","",
    function() clearLog(); scanRange(40,55) end)

SL:Button("Index 50-65","",
    function() clearLog(); scanRange(50,65) end)

SL:Button("Index 60-75","",
    function() clearLog(); scanRange(60,75) end)

SL:Button("Index 70-85","",
    function() clearLog(); scanRange(70,85) end)

SL:Button("workspace.Land","Detail struktur Land",
    function() clearLog(); scanLand() end)

SL:Button("Posisi Karakter","",
    function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            log(string.format("POS X=%.4f Y=%.4f Z=%.4f",
                hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
            notif("Posisi",string.format("X=%.2f Y=%.2f Z=%.2f",
                hrp.Position.X, hrp.Position.Y, hrp.Position.Z),5)
        end
    end)

SR:Button("📋 COPY LOG","Salin semua log ke clipboard",
    function() copyLog() end)

SR:Button("🗑 Clear Log","Hapus log",
    function() clearLog(); notif("Log","Cleared",2) end)

SR:Button("📊 Info Log","",
    function()
        local lines = 0
        for _ in LogBuffer:gmatch("\n") do lines = lines + 1 end
        notif("Log Info","Lines: "..lines.."\nChars: "..#LogBuffer,4)
    end)

SR:Paragraph("Cara Copy",
    "1. Klik tombol scan\n"..
    "2. Klik 📋 COPY LOG\n"..
    "3. Paste di WA/chat")

-- ╔══════════════════════════════════╗
-- ║   TAB FARM (BARU!)               ║
-- ╚══════════════════════════════════╝
local FarmP = T_Farm:Page("Farming Spy","leaf")
local FarmL = FarmP:Section("🌱 Farm Spy","Left")
local FarmR = FarmP:Section("📋 Copy","Right")

FarmL:Toggle("🌱 Farm Spy ON/OFF","farmSpy",false,
    "Monitor SEMUA event farming dari server\n(harvest ready, timer, inventory)",
    function(v)
        farmSpyOn = v
        clearLog()
        if v then
            startFarmSpy()
        else
            stopFarmSpy()
        end
    end)

FarmL:Paragraph("Cara Debug Harvest",
    "1. ON Farm Spy\n"..
    "2. Tanam 1 tanaman manual\n"..
    "3. Tunggu sampai besar\n"..
    "4. Klik tombol panen manual\n"..
    "5. OFF Farm Spy\n"..
    "6. Klik COPY LOG\n"..
    "7. Kirim ke developer!\n\n"..
    "Yang dicari:\n"..
    "- Data \\x0d (crop ready)\n"..
    "- cropPos yang valid\n"..
    "- seedColor\n"..
    "- Timer \\x02")

FarmL:Button("🔍 Scan Tanaman WS","Cari tanaman di workspace",
    function() clearLog(); scanCrops() end)

FarmL:Button("🔍 Scan Crop Names","Cari nama unik tanaman",
    function()
        clearLog()
        log("=== SCAN NAMA UNIK TANAMAN ===")
        local names = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local n = obj.Name
                if not names[n] then
                    -- Filter: kemungkinan nama tanaman
                    local nl = n:lower()
                    if nl:find("crop") or nl:find("plant") or nl:find("tree") or
                       nl:find("flower") or nl:find("seed") or nl:find("sawi") or
                       nl:find("padi") or nl:find("melon") or nl:find("tomat") or
                       nl:find("apple") or nl:find("kelapa") or nl:find("palm") or
                       nl:find("sun") or nl:find("sawit") or nl:find("daisy") then
                        names[n] = true
                        log("  FOUND: "..n.." ("..obj.ClassName..")")
                    end
                end
            end
        end
        local count = 0
        for _ in pairs(names) do count = count + 1 end
        if count == 0 then log("  Tidak ada tanaman ditemukan") end
        log("Total: "..count.." nama unik")
        log("=== SELESAI ===")
        notif("Crop Names",count.." nama\nKlik COPY LOG!",4)
    end)

FarmR:Button("📋 COPY LOG","Copy hasil farm spy",
    function() copyLog() end)

FarmR:Button("🗑 Clear","Hapus log",
    function() clearLog(); notif("Clear","OK",2) end)

FarmR:Paragraph("Yang Dicari",
    "Dari log, kita butuh:\n\n"..
    "1. \\x0d = crop ready\n"..
    "   → cropName\n"..
    "   → cropPos (X,Y,Z)\n"..
    "   → sellPrice\n"..
    "   → seedColor\n"..
    "   → drops\n\n"..
    "2. \\x02 = timer\n"..
    "   → [start, end]\n\n"..
    "Ini data untuk harvest!")

-- ╔══════════════════╗
-- ║   TAB FISH       ║
-- ╚══════════════════╝
local FP2 = T_Fish:Page("Fish Monitor","anchor")
local FL2 = FP2:Section("🎣 Monitor","Left")
local FR2 = FP2:Section("📋 Copy","Right")

FL2:Toggle("Fish Monitor","fishMon",false,
    "Listen semua FishRemotes events",
    function(v)
        clearLog()
        if v then startFish() else stopFish() end
    end)

FL2:Paragraph("Cara",
    "1. ON Fish Monitor\n"..
    "2. Mancing manual 1x\n"..
    "3. OFF Fish Monitor\n"..
    "4. Klik COPY LOG")

FR2:Button("📋 COPY LOG","Copy hasil fish monitor",
    function() copyLog() end)

FR2:Button("🗑 Clear","",
    function() clearLog(); notif("Clear","OK",2) end)

-- ╔══════════════════╗
-- ║   TAB INVENTORY  ║
-- ╚══════════════════╝
local IP = T_Inv:Page("Inv Monitor","package")
local IL = IP:Section("📦 Monitor","Left")
local IR = IP:Section("📋 Copy","Right")

IL:Toggle("Inv Monitor","invMon",false,
    "Listen inventory data dari server",
    function(v)
        clearLog()
        if v then startInv() else stopInv() end
    end)

IL:Button("Force Request","Trigger server kirim inventory",
    function()
        local bn = RS:FindFirstChild("BridgeNet2")
        local ev = bn and bn:FindFirstChild("dataRemoteEvent")
        if not ev then notif("Err","Remote tidak ada!",3); return end
        pcall(function()
            ev:FireServer({{ cropName="Sawi", amount=0 }, "\x07"})
        end)
        log("Force request dikirim...")
        notif("Request","Dikirim! Tunggu 2s",3)
    end)

IL:Paragraph("Cara",
    "1. ON Inv Monitor\n"..
    "2. Beli 1 bibit\n"..
    "   ATAU Force Request\n"..
    "3. Tunggu 2-3 detik\n"..
    "4. OFF Monitor\n"..
    "5. Klik COPY LOG")

IR:Button("📋 COPY LOG","Copy hasil inventory",
    function() copyLog() end)

IR:Button("🗑 Clear","",
    function() clearLog(); notif("Clear","OK",2) end)


-- ╔══════════════════════════════════════════════════════════╗
-- ║   TAB HARVEST DEBUG                                      ║
-- ╚══════════════════════════════════════════════════════════╝
local HP  = T_Harvest:Page("Harvest Debug","box")
local HL  = HP:Section("🌾 Harvest Test","Left")
local HR  = HP:Section("📋 Copy","Right")

local harvestConn = nil
local harvestOn   = false

-- Intercept semua OnClientEvent dari BridgeNet2
local function startHarvestMonitor()
    if harvestConn then harvestConn:Disconnect() end
    local bn = RS:FindFirstChild("BridgeNet2")
    local ev = bn and bn:FindFirstChild("dataRemoteEvent")
    if not ev then notif("Harvest ❌","dataRemoteEvent tidak ada!",4); return false end

    log("=== HARVEST MONITOR START ===")
    log("Tunggu tanaman siap lalu panen manual 1x")
    log("")

    harvestConn = ev.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end

        -- Log semua keys dengan hex
        local keys = {}
        for k in pairs(data) do
            if type(k) == "string" then
                local hex = ""
                for i = 1, math.min(#k,4) do hex=hex..string.format("%02x",k:byte(i)) end
                table.insert(keys, "str["..hex.."]")
            elseif type(k) == "number" then
                table.insert(keys, "int["..k.."]")
            end
        end
        log("Keys: "..table.concat(keys," | "))

        -- Cek semua kemungkinan crop key
        local cropData = nil
        local foundKey = nil
        local candidates = {
            {k="\r",           label="\\r"},
            {k="\13",          label="\\13"},
            {k=string.char(13), label="char(13)"},
            {k=13,              label="int(13)"},
        }
        for _, c in ipairs(candidates) do
            if data[c.k] then
                cropData = data[c.k]
                foundKey = c.label
                break
            end
        end

        if cropData then
            log("✅ CROP DATA → key: "..foundKey)
            if type(cropData) == "table" then
                for i, crop in ipairs(cropData) do
                    if type(crop) == "table" then
                        local posStr = crop.cropPos and
                            string.format("(%.2f,%.2f,%.2f)",
                                crop.cropPos.X,crop.cropPos.Y,crop.cropPos.Z) or "nil"
                        log(string.format("  [%d] %s pos=%s sell=%s",
                            i, tostring(crop.cropName), posStr,
                            tostring(crop.sellPrice)))
                        if crop.seedColor then
                            log(string.format("  [%d] seedColor=(%.4f,%.4f,%.4f)",
                                i, crop.seedColor[1] or 0,
                                crop.seedColor[2] or 0,
                                crop.seedColor[3] or 0))
                        end
                        if crop.drops then
                            for di, d in ipairs(crop.drops) do
                                log(string.format("  [%d] drop[%d] name=%s rarity=%s coin=%s",
                                    i, di, tostring(d.name),
                                    tostring(d.rarity), tostring(d.coinReward)))
                            end
                        end
                    end
                end
            end

            -- Timer
            local timerRaw = data["\2"] or data["\x02"]
                          or data[string.char(2)] or data[2]
            if timerRaw and type(timerRaw)=="table" then
                log(string.format("  timer: start=%s end=%s diff=%s",
                    tostring(timerRaw[1]), tostring(timerRaw[2]),
                    tostring((timerRaw[2] or 0)-(timerRaw[1] or 0))))
            else
                log("  timer: NOT FOUND")
            end
        end
        log("")
    end)

    notif("🌾 Harvest Monitor","ON!\nPanen manual 1x sekarang",4)
    return true
end

local function stopHarvestMonitor()
    if harvestConn then harvestConn:Disconnect(); harvestConn=nil end
    log("=== HARVEST MONITOR STOP ===")
    notif("Harvest","OFF — Klik COPY LOG",3)
end

HL:Toggle("🌾 Harvest Monitor","harvestMon",false,
    "Intercept semua data dari server\nPanen manual 1x setelah ON",
    function(v)
        harvestOn = v
        clearLog()
        if v then startHarvestMonitor() else stopHarvestMonitor() end
    end)

-- Cache crop data dari monitor untuk dipakai test
local lastCropData = nil

-- Override monitor untuk simpan data
local _origStart = startHarvestMonitor
startHarvestMonitor = function()
    if harvestConn then harvestConn:Disconnect() end
    local bn = RS:FindFirstChild("BridgeNet2")
    local ev = bn and bn:FindFirstChild("dataRemoteEvent")
    if not ev then notif("Harvest ❌","dataRemoteEvent tidak ada!",4); return false end

    log("=== HARVEST MONITOR START ===")
    log("Tunggu tanaman siap lalu panen manual 1x")
    log("")

    harvestConn = ev.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end

        local keys = {}
        for k in pairs(data) do
            if type(k) == "string" then
                local hex = ""
                for i = 1, math.min(#k,4) do hex=hex..string.format("%02x",k:byte(i)) end
                table.insert(keys, "str["..hex.."]")
            elseif type(k) == "number" then
                table.insert(keys, "int["..k.."]")
            end
        end
        log("Keys: "..table.concat(keys," | "))

        local cropData = data["\r"] or data["\13"]
                      or data[string.char(13)] or data[13]
        local timerRaw = data["\2"] or data["\x02"]
                      or data[string.char(2)] or data[2]

        if cropData then
            local tStart = (type(timerRaw)=="table" and timerRaw[1]) or 0
            local tEnd   = (type(timerRaw)=="table" and timerRaw[2]) or (tStart+50)

            log("✅ CROP DATA FOUND!")
            for i, crop in ipairs(cropData) do
                if type(crop)=="table" and crop.cropName then
                    local posStr = crop.cropPos and
                        string.format("(%.2f,%.2f,%.2f)",
                            crop.cropPos.X,crop.cropPos.Y,crop.cropPos.Z) or "nil"
                    log(string.format("  [%d] %s pos=%s",i,crop.cropName,posStr))
                    if crop.seedColor then
                        log(string.format("  [%d] color=(%.4f,%.4f,%.4f)",
                            i,crop.seedColor[1] or 0,
                            crop.seedColor[2] or 0,crop.seedColor[3] or 0))
                    end
                    -- Simpan untuk test
                    lastCropData = {
                        crop=crop, tStart=tStart, tEnd=tEnd
                    }
                end
            end
            log(string.format("  timer: %s → %s (diff=%s)",
                tostring(tStart),tostring(tEnd),tostring(tEnd-tStart)))
            log("  ← Siap untuk TEST FIRESERVER!")
        end
        log("")
    end)

    notif("🌾 Harvest Monitor","ON! Panen manual 1x",4)
    return true
end

HL:Button("🔥 Test FireServer (pakai data real)","Harvest pakai data dari monitor",
    function()
        local bn = RS:FindFirstChild("BridgeNet2")
        local ev = bn and bn:FindFirstChild("dataRemoteEvent")
        if not ev then notif("Err","Remote tidak ada!",3); return end

        if not lastCropData then
            notif("Test ❌","Belum ada data!\nON Monitor dulu,\nlalu panen manual 1x",4)
            return
        end

        local crop   = lastCropData.crop
        local tStart = lastCropData.tStart
        local tEnd   = lastCropData.tEnd

        log("=== TEST FIRESERVER (DATA REAL) ===")
        log(string.format("Crop: %s pos=(%.2f,%.2f,%.2f)",
            crop.cropName,
            crop.cropPos and crop.cropPos.X or 0,
            crop.cropPos and crop.cropPos.Y or 0,
            crop.cropPos and crop.cropPos.Z or 0))
        log(string.format("Timer: %d → %d", tStart, tEnd))

        local ok, err = pcall(function()
            ev:FireServer({
                ["\13"] = {{
                    seedColor = crop.seedColor or {0.298,0.600,0},
                    cropName  = crop.cropName,
                    cropPos   = crop.cropPos,
                    sellPrice = crop.sellPrice or 20,
                    drops     = crop.drops or {},
                }},
                ["\2"] = { tStart, tEnd }
            })
        end)

        if ok then
            log("✅ FireServer SENT dengan data real!")
            log("Cek: inventory bertambah? Tanaman hilang?")
            notif("Test ✅","Sent dengan timer real!\nCek inventory & lahan",4)
        else
            log("❌ ERROR: "..tostring(err))
            notif("Test ❌",tostring(err):sub(1,60),4)
        end
    end)

HL:Paragraph("Cara Debug Harvest",
    "1. ON Harvest Monitor\n"..
    "2. Panen MANUAL 1x di game\n"..
    "   (klik tombol Panen yg muncul)\n"..
    "3. OFF Monitor\n"..
    "4. COPY LOG → kirim ke dev\n\n"..
    "ATAU:\n"..
    "Klik Test FireServer Harvest\n"..
    "Lihat apakah inventory berubah")

HR:Button("📋 COPY LOG","Copy hasil harvest debug",
    function() copyLog() end)

HR:Button("🗑 Clear","",
    function() clearLog(); notif("Clear","OK",2) end)

HR:Paragraph("Yang dicari di log",
    "✅ Keys: str[0d] atau int[13]\n"..
    "✅ CROP DATA FOUND\n"..
    "✅ cropName, cropPos, timer\n\n"..
    "❌ Kalau tidak ada CROP DATA\n"..
    "   berarti key tidak match\n"..
    "   → kirim log ke developer!")

-- ┌─────────────────────────────────────────────────────────┐
-- │  INIT                                                   │
-- └─────────────────────────────────────────────────────────┘
Library:Notification("XKID DEBUG v6",
    "Scan · Farm · Fish · Inv · Harvest\n★ Tab Harvest = harvest debug!",5)
Library:ConfigSystem(Win)

log("XKID Debug v5 loaded | "..LP.Name)
log("WS children: "..#Workspace:GetChildren())
