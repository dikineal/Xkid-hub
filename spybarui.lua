--[[
  ╔══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   R E M O T E  F U L L  v2.1     ║
  ║      + FARMING SPY + AUTO DETECT TANAM/PANEN      ║
  ╚══════════════════════════════════════════════════════╝
]]

-- ════════════════════════════════════════
--  TAMBAHAN TAB FARMING SPY
-- ════════════════════════════════════════
local TabFarmSpy = Win:Tab("🌾 Farming Spy", "eye")  -- Ikon mata untuk spy

-- ════════════════════════════════════════
--  STATE FARMING SPY
-- ════════════════════════════════════════
local farmSpyActive = false
local farmSpyConns = {}
local farmSpyLog = {}  -- Format: { time, action, remote, args, cropType, position }
local farmSpyFilter = "Semua"  -- Semua / Tanam / Panen
local farmSpyPage = 1

-- ════════════════════════════════════════
--  DETEKSI TANAM vs PANEN (LEBIH PINTAR)
-- ════════════════════════════════════════
local FARM_KEYWORDS = {
    tanam = {
        -- Nama remote yang umum buat tanam
        remotes = {"plant", "tanam", "grow", "seed", "sow", "cultivate", "tabur"},
        -- Pola argumen yang umum (serialized)
        args = {
            "cropName", "seedType", "plot", "position", " tanah",
            "\\x06",  -- BridgeNet2 identifier tanam
            "seed"
        }
    },
    panen = {
        remotes = {"harvest", "panen", "collect", "pick", "petik", "gather", "cut", "pangkas"},
        args = {
            "crop", "plant", "ready", "harvest", "\\x0F",  -- BN2 harvest
            "sellPrice", "cropPos"
        }
    }
}

-- Fungsi deteksi apakah ini aksi tanam
local function isPlantAction(remoteName, argsSerialized)
    remoteName = remoteName:lower()
    
    -- Cek dari nama remote
    for _, kw in ipairs(FARM_KEYWORDS.tanam.remotes) do
        if remoteName:find(kw, 1, true) then
            return true, "🌱 TANAM"
        end
    end
    
    -- Cek dari pola argumen
    for _, pattern in ipairs(FARM_KEYWORDS.tanam.args) do
        if argsSerialized:find(pattern, 1, true) then
            return true, "🌱 TANAM (arg)"
        end
    end
    
    return false, nil
end

-- Fungsi deteksi apakah ini aksi panen
local function isHarvestAction(remoteName, argsSerialized)
    remoteName = remoteName:lower()
    
    -- Cek dari nama remote
    for _, kw in ipairs(FARM_KEYWORDS.panen.remotes) do
        if remoteName:find(kw, 1, true) then
            return true, "🌾 PANEN"
        end
    end
    
    -- Cek dari pola argumen
    for _, pattern in ipairs(FARM_KEYWORDS.panen.args) do
        if argsSerialized:find(pattern, 1, true) then
            return true, "🌾 PANEN (arg)"
        end
    end
    
    return false, nil
end

-- ════════════════════════════════════════
--  EKSTRAK INFO TANAMAN DARI ARGUMEN
-- ════════════════════════════════════════
local function extractCropInfo(args)
    local cropType = "unknown"
    local position = nil
    
    for _, arg in ipairs(args) do
        if type(arg) == "string" then
            -- Coba deteksi nama tanaman dari string
            if arg:len() > 2 and arg:len() < 30 then
                -- String pendek kemungkinan nama crop
                cropType = arg
            end
        elseif type(arg) == "table" then
            -- Coba cari di tabel
            if arg.cropName then
                cropType = arg.cropName
            elseif arg.seedType then
                cropType = arg.seedType
            elseif arg.plant then
                cropType = arg.plant
            end
            
            -- Cari posisi
            if arg.position then
                position = arg.position
            elseif arg.cropPos then
                position = arg.cropPos
            elseif arg.hitPosition then
                position = arg.hitPosition
            end
        elseif typeof(arg) == "Vector3" then
            position = arg
        elseif typeof(arg) == "CFrame" then
            position = arg.Position
        elseif typeof(arg) == "Instance" then
            -- Mungkin ini objek tanaman
            cropType = arg.Name
            if arg:IsA("BasePart") then
                position = arg.Position
            end
        end
    end
    
    return cropType, position
end

-- ════════════════════════════════════════
--  FARMING SPY (SPESIALISASI)
-- ════════════════════════════════════════
local function startFarmingSpy()
    -- Bersihkan koneksi lama
    for _, conn in ipairs(farmSpyConns) do
        pcall(function() conn:Disconnect() end)
    end
    farmSpyConns = {}
    
    -- Scan semua RemoteEvent
    local events = scanAll("RemoteEvent")
    local count = 0
    
    for _, r in ipairs(events) do
        -- Pasang spy di setiap remote
        local ok, conn = pcall(function()
            return r.ref.OnClientEvent:Connect(function(...)
                local args = {...}
                local argsSerialized = serializeValue(args, 0)
                local remoteName = r.name
                local remotePath = r.path
                
                -- Deteksi apakah ini tanam atau panen
                local isPlant, plantLabel = isPlantAction(remoteName, argsSerialized)
                local isHarvest, harvestLabel = isHarvestAction(remoteName, argsSerialized)
                
                if isPlant or isHarvest then
                    local action = isPlant and plantLabel or harvestLabel
                    local cropType, position = extractCropInfo(args)
                    
                    -- Format posisi
                    local posStr = "unknown"
                    if position then
                        if typeof(position) == "Vector3" then
                            posStr = string.format("(%.1f, %.1f, %.1f)", 
                                position.X, position.Y, position.Z)
                        else
                            posStr = tostring(position)
                        end
                    end
                    
                    -- Buat entry log yang terstruktur
                    local entry = {
                        time = os.time(),
                        timeStr = os.date("%H:%M:%S"),
                        action = action,
                        remoteName = remoteName,
                        remotePath = remotePath,
                        cropType = cropType,
                        position = posStr,
                        raw = argsSerialized
                    }
                    
                    -- Simpan log
                    table.insert(farmSpyLog, 1, entry)
                    if #farmSpyLog > 100 then
                        table.remove(farmSpyLog, #farmSpyLog)
                    end
                    
                    count = count + 1
                end
            end)
        end)
        
        if ok and conn then
            table.insert(farmSpyConns, conn)
        end
    end
    
    -- Pasang juga hook untuk outgoing (FireServer)
    local targetSet = buildTargetSet()
    local hookConn
    hookConn = game:GetService("RunService").Heartbeat:Connect(function() end) -- dummy, nanti diganti hook
    
    -- Sebenernya pakai hookmetamethod, tapi kita sederhanakan dulu
    -- Untuk demo, kita pakai pendekatan sederhana
    
    Library:Notification("🌾 Farming Spy ON", 
        string.format("Memantau %d remote\nDeteksi otomatis tanam/panen", #events), 5)
    
    return #events
end

local function stopFarmingSpy()
    for _, conn in ipairs(farmSpyConns) do
        pcall(function() conn:Disconnect() end)
    end
    farmSpyConns = {}
end

-- ════════════════════════════════════════
--  FILTER LOG FARMING
-- ════════════════════════════════════════
local function getFilteredFarmLogs()
    if farmSpyFilter == "Semua" then
        return farmSpyLog
    elseif farmSpyFilter == "Tanam" then
        local filtered = {}
        for _, entry in ipairs(farmSpyLog) do
            if entry.action:find("TANAM") then
                table.insert(filtered, entry)
            end
        end
        return filtered
    elseif farmSpyFilter == "Panen" then
        local filtered = {}
        for _, entry in ipairs(farmSpyLog) do
            if entry.action:find("PANEN") then
                table.insert(filtered, entry)
            end
        end
        return filtered
    end
    return {}
end

-- ════════════════════════════════════════
--  DISPLAY FARMING LOG
-- ════════════════════════════════════════
local function showFarmLogs(page)
    local logs = getFilteredFarmLogs()
    if #logs == 0 then
        Library:Notification("📭", "Belum ada log farming\nLakukan tanam/panen dulu!", 3)
        return
    end
    
    local totalPages = math.ceil(#logs / PAGE_SIZE)
    page = math.max(1, math.min(page, totalPages))
    local startIdx = (page-1)*PAGE_SIZE + 1
    local endIdx = math.min(page*PAGE_SIZE, #logs)
    
    local text = string.format("🌾 FARMING LOG [Hal %d/%d]\n", page, totalPages)
    text = text .. string.format("Filter: %s | Total: %d\n\n", farmSpyFilter, #logs)
    
    for i = startIdx, endIdx do
        local e = logs[i]
        text = text .. string.format("[%d] %s %s\n", i, e.timeStr, e.action)
        text = text .. string.format("    Remote: %s\n", e.remoteName)
        text = text .. string.format("    Crop: %s\n", e.cropType)
        text = text .. string.format("    Pos: %s\n", e.position)
        text = text .. string.format("    Path: %s\n\n", e.remotePath:match("([^.]+)$") or e.remotePath)
    end
    
    Library:Notification("🌾 Farming Spy", text, 20)
    farmSpyPage = page
end

-- ════════════════════════════════════════
--  COPY FARMING LOG (DENGAN FORMAT BERSTRUKTUR)
-- ════════════════════════════════════════
local function copyFarmLogs(formatType)
    local logs = getFilteredFarmLogs()
    if #logs == 0 then
        Library:Notification("❌", "Tidak ada log untuk di-copy", 2)
        return
    end
    
    local text = ""
    
    if formatType == "simple" then
        -- Format sederhana: action, crop, waktu
        text = "=== FARMING LOG (SIMPLE) ===\n\n"
        for i, e in ipairs(logs) do
            text = text .. string.format("%d. [%s] %s - %s\n", 
                i, e.timeStr, e.action, e.cropType)
        end
        
    elseif formatType == "detail" then
        -- Format detail: semua info
        text = "=== FARMING LOG (DETAIL) ===\n\n"
        for i, e in ipairs(logs) do
            text = text .. string.format("[LOG #%d]\n", i)
            text = text .. string.format("Waktu  : %s\n", e.timeStr)
            text = text .. string.format("Aksi   : %s\n", e.action)
            text = text .. string.format("Remote : %s\n", e.remoteName)
            text = text .. string.format("Path   : %s\n", e.remotePath)
            text = text .. string.format("Crop   : %s\n", e.cropType)
            text = text .. string.format("Posisi : %s\n", e.position)
            text = text .. string.format("Raw    : %s\n\n", e.raw:sub(1, 100))
        end
        
    elseif formatType == "csv" then
        -- Format CSV buat diimport excel
        text = "No,Waktu,Aksi,Remote,Crop,Posisi\n"
        for i, e in ipairs(logs) do
            text = text .. string.format("%d,%s,%s,%s,%s,%s\n",
                i, e.timeStr, e.action, e.remoteName, e.cropType, e.position)
        end
    end
    
    doCopy(text)
end

-- ════════════════════════════════════════
--  BUILD UI - TAB FARMING SPY
-- ════════════════════════════════════════
local FarmSpyPage = TabFarmSpy:Page("🌾 Farming Spy", "eye")
local FarmSpyLeft = FarmSpyPage:Section("🕵️ Spy Control", "Left")
local FarmSpyRight = FarmSpyPage:Section("📋 Log & Copy", "Right")

-- Left Section
FarmSpyLeft:Toggle("🌾 Aktifkan Farming Spy", "FarmSpyToggle", false,
    "Deteksi otomatis tanam dan panen",
    function(v)
        farmSpyActive = v
        if v then
            if #allRemotes == 0 then
                Library:Notification("⚠️", "Scan remote dulu di tab Scan!\nSupaya bisa detect remote farm", 4)
                farmSpyActive = false
                return
            end
            startFarmingSpy()
        else
            stopFarmingSpy()
            Library:Notification("🌾 Farming Spy", "OFF", 2)
        end
    end)

FarmSpyLeft:Dropdown("🔍 Filter Log", "FarmSpyFilter", 
    {"Semua", "Tanam", "Panen"}, 
    function(v) farmSpyFilter = v end, 
    "Pilih jenis aksi yang ditampilkan")

FarmSpyLeft:Button("🔄 Reset Log", "Hapus semua log farming",
    function()
        farmSpyLog = {}
        Library:Notification("🗑️", "Log farming dihapus", 2)
    end)

FarmSpyLeft:Paragraph("📊 Statistik", 
    function()
        local total = #farmSpyLog
        local tanam = 0
        local panen = 0
        for _, e in ipairs(farmSpyLog) do
            if e.action:find("TANAM") then tanam = tanam + 1 end
            if e.action:find("PANEN") then panen = panen + 1 end
        end
        
        return string.format("Total: %d\n🌱 Tanam: %d\n🌾 Panen: %d", 
            total, tanam, panen)
    end)

-- Right Section - Navigation
FarmSpyRight:Button("📄 Lihat Log", "Tampilkan log farming",
    function()
        showFarmLogs(1)
    end)

FarmSpyRight:Button("▶ Log Berikutnya", "Halaman berikutnya",
    function()
        showFarmLogs(farmSpyPage + 1)
    end)

FarmSpyRight:Button("◀ Log Sebelumnya", "Halaman sebelumnya",
    function()
        showFarmLogs(farmSpyPage - 1)
    end)

-- Right Section - Copy Options
FarmSpyRight:Button("📋 Copy Simple", "Copy format sederhana",
    function()
        copyFarmLogs("simple")
    end)

FarmSpyRight:Button("📋 Copy Detail", "Copy dengan info lengkap",
    function()
        copyFarmLogs("detail")
    end)

FarmSpyRight:Button("📊 Copy CSV", "Copy format CSV (Excel)",
    function()
        copyFarmLogs("csv")
    end)

FarmSpyRight:Button("🌱 Copy Tanam Saja", "Copy hanya log tanam",
    function()
        local oldFilter = farmSpyFilter
        farmSpyFilter = "Tanam"
        copyFarmLogs("detail")
        farmSpyFilter = oldFilter
    end)

FarmSpyRight:Button("🌾 Copy Panen Saja", "Copy hanya log panen",
    function()
        local oldFilter = farmSpyFilter
        farmSpyFilter = "Panen"
        copyFarmLogs("detail")
        farmSpyFilter = oldFilter
    end)

-- Right Section - Export berdasarkan crop
local cropToExport = ""
FarmSpyRight:TextBox("🌽 Filter Crop", "CropExportFilter", "",
    function(v) cropToExport = v end,
    "Nama crop untuk diexport")

FarmSpyRight:Button("📋 Copy by Crop", "Copy log berdasarkan nama crop",
    function()
        if cropToExport == "" then
            Library:Notification("❌", "Masukkan nama crop dulu!", 2)
            return
        end
        
        local filtered = {}
        for _, e in ipairs(farmSpyLog) do
            if e.cropType:lower():find(cropToExport:lower()) then
                table.insert(filtered, e)
            end
        end
        
        if #filtered == 0 then
            Library:Notification("❌", "Tidak ada log untuk crop: " .. cropToExport, 2)
            return
        end
        
        local text = string.format("=== FARMING LOG: %s (%d) ===\n\n", 
            cropToExport, #filtered)
        for i, e in ipairs(filtered) do
            text = text .. string.format("[%d] %s %s\n", i, e.timeStr, e.action)
            text = text .. string.format("    Remote: %s\n", e.remoteName)
            text = text .. string.format("    Posisi: %s\n\n", e.position)
        end
        
        doCopy(text)
    end)

-- Right Section - Auto refresh
FarmSpyRight:Toggle("🔄 Auto Refresh", "AutoRefreshFarm", false,
    "Auto update log setiap 3 detik",
    function(v)
        if v then
            -- Simple auto refresh loop
            task.spawn(function()
                while v do
                    task.wait(3)
                    if farmSpyActive and v then
                        showFarmLogs(farmSpyPage)
                    end
                end
            end)
        end
    end)

-- ════════════════════════════════════════
--  PANDUAN DI KONSOLE
-- ════════════════════════════════════════
print("╔══════════════════════════════════════╗")
print("║   🌾 FARMING SPY ADDED v2.1         ║")
print("║   Fitur baru:                        ║")
print("║   • Deteksi otomatis tanam/panen    ║")
print("║   • Filter berdasarkan aksi          ║")
print("║   • Copy format SIMPLE/DETAIL/CSV   ║")
print("║   • Export berdasarkan nama crop    ║")
print("║   • Auto refresh log                ║")
print("╚══════════════════════════════════════╝")