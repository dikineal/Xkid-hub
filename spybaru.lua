--[[
  ╔══════════════════════════════════════════════════════╗
  ║    🌱  BRIDGENET2 SPY  v1.0  🌱                    ║
  ║    Capture semua packet BridgeNet2                  ║
  ╚══════════════════════════════════════════════════════╝
  Cara pakai:
  1. Jalankan script ini
  2. Lakukan aksi di game:
     - Beli bibit
     - Klik lahan untuk tanam
     - Panen tanaman
  3. Tekan tombol di UI untuk lihat hasil
  4. Copy ke clipboard
]]

Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer

local Win = Library:Window("🌱 BN2 SPY", "cpu", "v1.0", false)
Win:TabSection("SPY")
local TabSpy = Win:Tab("Spy", "eye")

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local capturedPackets = {}
local spyConn         = nil
local spyOn           = false
local MAX_PACKETS     = 100
local currentPage     = 1
local PAGE_SIZE       = 3

-- ════════════════════════════════════════
--  SERIALIZE TABLE → STRING
--  Untuk tampilkan isi packet
-- ════════════════════════════════════════
local function serializeValue(v, depth)
    depth = depth or 0
    if depth > 4 then return "..." end
    local t = typeof(v)
    if t == "string" then
        -- Tampilkan hex untuk key pendek/tidak visible
        if #v <= 4 then
            local hex = ""
            for i = 1, #v do
                hex = hex .. string.format("\\x%02X", string.byte(v, i))
            end
            return string.format('"%s"[hex:%s]', v, hex)
        end
        return string.format('"%s"', v)
    elseif t == "number"  then return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "Vector3" then
        return string.format("V3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
    elseif t == "table" then
        local parts = {}
        local count = 0
        for k, val in pairs(v) do
            count = count + 1
            if count > 10 then
                table.insert(parts, "...+"..tostring(select(2,pcall(function()
                    local n=0; for _ in pairs(v) do n=n+1 end; return n
                end)) or "?").." more")
                break
            end
            local ks = serializeValue(k, depth+1)
            local vs = serializeValue(val, depth+1)
            table.insert(parts, string.format("[%s]=%s", ks, vs))
        end
        if #parts == 0 then return "{}" end
        return "{\n"..string.rep("  ", depth+1)..
               table.concat(parts, ",\n"..string.rep("  ", depth+1))..
               "\n"..string.rep("  ", depth).."}"
    elseif t == "Instance" then
        return "Instance:"..v:GetFullName()
    else
        return "["..t.."]"
    end
end

-- ════════════════════════════════════════
--  DETEKSI JENIS AKSI dari isi packet
-- ════════════════════════════════════════
local function detectAction(data)
    local str = serializeValue(data, 0)

    -- Cek pola harvest/panen
    if str:find("cropPos") and str:find("sellPrice") then
        return "🌾 HARVEST/PANEN"
    end
    -- Cek pola beli bibit
    if str:find("cropName") and str:find("count") and str:find("success") then
        return "🛒 BELI BIBIT"
    end
    -- Cek pola tanam
    if str:find("cropName") and str:find("cropPos") and not str:find("sellPrice") then
        return "🌱 TANAM"
    end
    -- Cek pola shop data
    if str:find("seedPrice") and str:find("sellPrice") and str:find("items") then
        return "🏪 DATA TOKO"
    end
    -- Cek pola update coins
    if str:find("coins") then
        return "💰 UPDATE COINS"
    end
    return "❓ UNKNOWN"
end

-- ════════════════════════════════════════
--  START SPY
-- ════════════════════════════════════════
local function startSpy()
    -- Spy dataRemoteEvent (BridgeNet2 utama)
    local dataRE = RS:FindFirstChild("BridgeNet2")
        and RS.BridgeNet2:FindFirstChild("dataRemoteEvent")

    if not dataRE then
        Library:Notification("❌", "BridgeNet2.dataRemoteEvent tidak ditemukan", 3)
        return false
    end

    spyConn = dataRE.OnClientEvent:Connect(function(data)
        local action = detectAction(data)
        local serialized = serializeValue(data, 0)

        local entry = {
            action = action,
            data   = data,
            raw    = serialized,
            time   = os.time(),
        }

        table.insert(capturedPackets, 1, entry)
        if #capturedPackets > MAX_PACKETS then
            table.remove(capturedPackets, #capturedPackets)
        end
    end)

    return true
end

local function stopSpy()
    if spyConn then spyConn:Disconnect(); spyConn = nil end
end

-- ════════════════════════════════════════
--  DISPLAY PACKET
-- ════════════════════════════════════════
local function showPackets(page)
    if #capturedPackets == 0 then
        Library:Notification("📭", "Belum ada packet\nLakukan aksi di game dulu!", 3)
        return
    end

    local totalPages = math.ceil(#capturedPackets / PAGE_SIZE)
    page = math.max(1, math.min(page, totalPages))
    currentPage = page

    local startIdx = (page-1)*PAGE_SIZE + 1
    local endIdx   = math.min(page*PAGE_SIZE, #capturedPackets)

    local text = string.format(
        "📦 Packet %d-%d / %d\n\n",
        startIdx, endIdx, #capturedPackets)

    for i = startIdx, endIdx do
        local p = capturedPackets[i]
        text = text..string.format(
            "━━━ [%d] %s ━━━\n%s\n\n",
            i, p.action, p.raw)
    end

    Library:Notification(
        string.format("🌱 BN2 Spy [%d/%d]", page, totalPages),
        text, 20)
end

-- ════════════════════════════════════════
--  COPY HELPERS
-- ════════════════════════════════════════
local function copyAllPackets()
    if #capturedPackets == 0 then
        Library:Notification("❌", "Belum ada packet", 2); return
    end
    local text = string.format(
        "=== BRIDGENET2 SPY LOG (%d packets) ===\n\n",
        #capturedPackets)
    for i, p in ipairs(capturedPackets) do
        text = text..string.format(
            "[%d] %s\n%s\n\n",
            i, p.action, p.raw)
    end
    pcall(function() setclipboard(text) end)
    Library:Notification("📋 Copied!", #capturedPackets.." packet di-copy", 3)
end

local function copyPacketByIndex(idx)
    if idx < 1 or idx > #capturedPackets then
        Library:Notification("❌", "Nomor tidak valid", 2); return
    end
    local p = capturedPackets[idx]
    local text = string.format("[%d] %s\n%s", idx, p.action, p.raw)
    pcall(function() setclipboard(text) end)
    Library:Notification("📋 Copy #"..idx, p.action, 3)
end

-- Filter hanya aksi tertentu
local function copyFilteredPackets(keyword)
    local filtered = {}
    for _, p in ipairs(capturedPackets) do
        if p.action:lower():find(keyword:lower()) then
            table.insert(filtered, p)
        end
    end
    if #filtered == 0 then
        Library:Notification("❌", "Tidak ada packet '"..keyword.."'", 2); return
    end
    local text = string.format(
        "=== FILTER: %s (%d) ===\n\n", keyword:upper(), #filtered)
    for i, p in ipairs(filtered) do
        text = text..string.format("[%d] %s\n%s\n\n", i, p.action, p.raw)
    end
    pcall(function() setclipboard(text) end)
    Library:Notification("📋 Filter Copy", #filtered.." packet '"..keyword.."'", 3)
end

-- ════════════════════════════════════════
--  BUILD UI
-- ════════════════════════════════════════
local SpyPage  = TabSpy:Page("BN2 Spy", "eye")
local SpyLeft  = SpyPage:Section("👁 Monitor", "Left")
local SpyRight = SpyPage:Section("📋 Hasil", "Right")

SpyLeft:Toggle("🌱 Start Spy", "SpyToggle", false,
    "Monitor semua packet BridgeNet2",
    function(v)
        spyOn = v
        if v then
            local ok = startSpy()
            if ok then
                Library:Notification("👁 Spy ON",
                    "Lakukan aksi di game:\n"..
                    "• Beli bibit\n"..
                    "• Klik lahan → tanam\n"..
                    "• Panen tanaman\n\n"..
                    "Lalu lihat hasil di sini!", 8)
            end
        else
            stopSpy()
            Library:Notification("👁 Spy", "OFF", 2)
        end
    end)

SpyLeft:Button("🗑 Clear Packets", "Hapus semua packet",
    function()
        capturedPackets = {}
        Library:Notification("🗑", "Packet dihapus", 2)
    end)

SpyLeft:Paragraph("📋 Panduan",
    "1. Toggle Spy → ON\n\n"..
    "2. Di game lakukan:\n"..
    "   🛒 Beli bibit\n"..
    "   🌱 Klik lahan tanam\n"..
    "   🌾 Panen tanaman\n\n"..
    "3. Lihat Hasil →\n"..
    "   setiap aksi ke-\n"..
    "   capture otomatis\n\n"..
    "4. Copy packet yang\n"..
    "   diinginkan")

-- Navigasi packet
SpyRight:Button("📄 Lihat Semua Packet", "Tampilkan packet terbaru",
    function()
        showPackets(1)
    end)

SpyRight:Button("▶ Packet Berikutnya", "Halaman berikutnya",
    function()
        showPackets(currentPage + 1)
    end)

SpyRight:Button("◀ Packet Sebelumnya", "Halaman sebelumnya",
    function()
        showPackets(currentPage - 1)
    end)

-- Filter per aksi
SpyRight:Button("🌱 Lihat Packet TANAM", "Filter packet aksi tanam saja",
    function()
        local filtered = {}
        for _, p in ipairs(capturedPackets) do
            if p.action:find("TANAM") then table.insert(filtered, p) end
        end
        if #filtered == 0 then
            Library:Notification("🌱", "Belum ada packet tanam\nCoba klik lahan dulu!", 3)
            return
        end
        local text = string.format("🌱 TANAM (%d packet)\n\n", #filtered)
        for i, p in ipairs(filtered) do
            text = text..string.format("[%d]\n%s\n\n", i, p.raw)
        end
        Library:Notification("🌱 Packet Tanam", text, 20)
    end)

SpyRight:Button("🌾 Lihat Packet PANEN", "Filter packet aksi panen saja",
    function()
        local filtered = {}
        for _, p in ipairs(capturedPackets) do
            if p.action:find("HARVEST") or p.action:find("PANEN") then
                table.insert(filtered, p)
            end
        end
        if #filtered == 0 then
            Library:Notification("🌾", "Belum ada packet panen\nCoba panen dulu!", 3)
            return
        end
        local text = string.format("🌾 PANEN (%d packet)\n\n", #filtered)
        for i, p in ipairs(filtered) do
            text = text..string.format("[%d]\n%s\n\n", i, p.raw)
        end
        Library:Notification("🌾 Packet Panen", text, 20)
    end)

SpyRight:Button("🛒 Lihat Packet BELI", "Filter packet aksi beli bibit",
    function()
        local filtered = {}
        for _, p in ipairs(capturedPackets) do
            if p.action:find("BELI") then table.insert(filtered, p) end
        end
        if #filtered == 0 then
            Library:Notification("🛒", "Belum ada packet beli\nCoba beli bibit dulu!", 3)
            return
        end
        local text = string.format("🛒 BELI (%d packet)\n\n", #filtered)
        for i, p in ipairs(filtered) do
            text = text..string.format("[%d]\n%s\n\n", i, p.raw)
        end
        Library:Notification("🛒 Packet Beli", text, 20)
    end)

-- Copy
SpyRight:Button("📋 Copy Semua", "Copy semua packet ke clipboard",
    function() copyAllPackets() end)

SpyRight:Button("📋 Copy Packet TANAM", "Copy semua packet tanam",
    function() copyFilteredPackets("tanam") end)

SpyRight:Button("📋 Copy Packet PANEN", "Copy semua packet panen",
    function() copyFilteredPackets("harvest") end)

local copyIdx = 1
SpyRight:Slider("Nomor Packet", "CopyIdxSlider", 1, 100, 1,
    function(v) copyIdx = v end, "Nomor packet yang mau di-copy")

SpyRight:Button("📋 Copy Packet #", "Copy 1 packet sesuai nomor",
    function() copyPacketByIndex(copyIdx) end)

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("🌱 BN2 Spy v1.0",
    "Toggle Spy ON\nlalu lakukan aksi di game!", 5)
Library:ConfigSystem(Win)

print("[ BN2 SPY v1.0 ] Ready — " .. LP.Name)
