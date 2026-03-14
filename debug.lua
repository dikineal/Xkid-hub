--[[
╔══════════════════════════════════════════════════════╗
║ 🌐 BRIDGENET2 SPY + HOOK v2.0 🌐 ║
║ Capture semua packet BridgeNet2 (Incoming & Outgoing) ║
║ Spy → dataRemoteEvent.OnClientEvent ║
║ Hook → FireServer / InvokeServer (namecall) ║
╚══════════════════════════════════════════════════════╝
]]

Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local RS = game:GetService("ReplicatedStorage")
local LP = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")

-- ============================================
-- MAIN WINDOW
-- ============================================
local Win = Library:Window("🌐 BN2 SPY+HOOK", "cpu", "v2.0 Incoming+Outgoing", false)

Win:TabSection("📥 INCOMING (Spy)")
local SpyTab = Win:Tab("Spy", "eye")

Win:TabSection("📤 OUTGOING (Hook)")
local HookTab = Win:Tab("Hook", "zap")

Win:TabSection("📊 ANALYZER")
local AnalyzerTab = Win:Tab("Analyzer", "chart")

-- ============================================
-- SHARED UTILITIES
-- ============================================
local MAX_PACKETS = 100
local PAGE_SIZE = 3
local currentSpyPage = 1
local currentHookPage = 1

-- Fungsi serialize untuk berbagai tipe data
local function serializeValue(v, depth)
    depth = depth or 0
    if depth > 5 then return "..." end
    local t = typeof(v)
    
    if t == "string" then
        if #v <= 4 then
            local hex = ""
            for i = 1, #v do
                hex = hex .. string.format("\\x%02X", string.byte(v, i))
            end
            return string.format('"%s" [hex:%s]', v, hex)
        end
        return string.format('"%s"', v)
    elseif t == "number" then return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "Vector3" then
        return string.format("V3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
    elseif t == "CFrame" then
        local p = v.Position
        return string.format("CF(%.2f,%.2f,%.2f)", p.X, p.Y, p.Z)
    elseif t == "table" then
        local parts = {}
        local count = 0
        for k, val in pairs(v) do
            count = count + 1
            if count > 8 then
                table.insert(parts, "...more")
                break
            end
            local ks = serializeValue(k, depth+1)
            local vs = serializeValue(val, depth+1)
            table.insert(parts, string.format("[%s]=%s", ks, vs))
        end
        if #parts == 0 then return "{}" end
        return "{\n"..string.rep(" ", depth+1)..
               table.concat(parts, ",\n"..string.rep(" ", depth+1))..
               "\n"..string.rep(" ", depth).."}"
    elseif t == "Instance" then
        return "Inst:"..(pcall(function() return v:GetFullName() end) and v:GetFullName() or v.Name)
    else
        return "["..t..":"..tostring(v).."]"
    end
end

-- Fungsi copy ke clipboard
local function doCopy(text)
    local ok = pcall(function() setclipboard(text) end)
    Library:Notification(
        ok and "📋 Copied!" or "❌ Gagal",
        ok and "Berhasil copy!" or "Executor tidak support setclipboard", 3)
end

-- Fungsi format waktu
local function formatTime(ts)
    return os.date("%H:%M:%S", ts)
end

-- ============================================
-- SPY SYSTEM (INCOMING)
-- ============================================
local spyEnabled = false
local spyConn = nil
local spyPackets = {}

-- Deteksi aksi untuk incoming packet
local function detectIncomingAction(data)
    local str = serializeValue(data, 0)
    
    if str:find("cropPos") and str:find("sellPrice") then
        return "🌾 HARVEST/PANEN (incoming)"
    elseif str:find("cropName") and str:find("count") and str:find("success") then
        return "🛒 BELI BIBIT (incoming)"
    elseif str:find("cropName") and str:find("cropPos") and not str:find("sellPrice") then
        return "🌱 TANAM (incoming)"
    elseif str:find("seedPrice") and str:find("sellPrice") and str:find("items") then
        return "🏪 DATA TOKO (incoming)"
    elseif str:find("coins") then
        return "💰 UPDATE COINS (incoming)"
    elseif str:find("level") and str:find("xp") then
        return "📊 UPDATE LEVEL (incoming)"
    elseif str:find("error") or str:find("failed") then
        return "❌ ERROR (incoming)"
    else
        return "📦 UNKNOWN (incoming)"
    end
end

-- Start spy
local function startSpy()
    local dataRE = RS:FindFirstChild("BridgeNet2") and RS.BridgeNet2:FindFirstChild("dataRemoteEvent")
    
    if not dataRE then
        Library:Notification("❌ Error", "BridgeNet2.dataRemoteEvent tidak ditemukan", 3)
        return false
    end
    
    if spyConn then spyConn:Disconnect() end
    
    spyConn = dataRE.OnClientEvent:Connect(function(data)
        local action = detectIncomingAction(data)
        local serialized = serializeValue(data, 0)
        local entry = {
            action = action,
            data = data,
            raw = serialized,
            time = os.time(),
            timeStr = os.date("%H:%M:%S")
        }
        table.insert(spyPackets, 1, entry)
        if #spyPackets > MAX_PACKETS then
            table.remove(spyPackets, #spyPackets)
        end
    end)
    
    return true
end

-- Stop spy
local function stopSpy()
    if spyConn then spyConn:Disconnect(); spyConn = nil end
end

-- ============================================
-- HOOK SYSTEM (OUTGOING)
-- ============================================
local hookEnabled = false
local origNamecall = nil
local hookPackets = {}

-- Deteksi aksi untuk outgoing packet
local function detectOutgoingAction(args)
    local str = ""
    for _, a in ipairs(args) do
        str = str .. serializeValue(a, 0)
    end
    
    if str:find("cropName") and str:find("count") then
        return "🛒 BELI BIBIT (outgoing)"
    elseif str:find("cropName") and str:find("cropPos") then
        return "🌱 TANAM (outgoing)"
    elseif str:find("cropName") and not str:find("count") then
        return "🌾 HARVEST (outgoing)"
    elseif str:find("request") or str:find("Request") then
        return "📤 REQUEST (outgoing)"
    elseif str == "" or str:find("EMPTY") then
        return "📦 EMPTY (outgoing)"
    else
        return "❓ UNKNOWN (outgoing)"
    end
end

-- Dapatkan remote target
local function getTargetRemotes()
    local bn2 = RS:FindFirstChild("BridgeNet2")
    local net = RS:FindFirstChild("Networking")
    local targets = {}
    
    if bn2 then
        local dataRE = bn2:FindFirstChild("dataRemoteEvent")
        local metaRE = bn2:FindFirstChild("metaRemoteEvent")
        if dataRE then table.insert(targets, dataRE) end
        if metaRE then table.insert(targets, metaRE) end
    end
    
    if net then
        local re = net:FindFirstChild("RemoteEvent")
        if re then table.insert(targets, re) end
    end
    
    -- Tambah semua RemoteEvent di RS root
    for _, child in ipairs(RS:GetChildren()) do
        if child:IsA("RemoteEvent") then
            table.insert(targets, child)
        end
    end
    
    return targets
end

-- Start hook
local function startHook()
    local targets = getTargetRemotes()
    local targetSet = {}
    for _, r in ipairs(targets) do
        targetSet[r] = true
    end
    
    origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if (method == "FireServer" or method == "InvokeServer") then
            local isTarget = targetSet[self]
            
            if not isTarget then
                local path = (pcall(function() return self:GetFullName() end)) and self:GetFullName() or ""
                isTarget = path:find("BridgeNet") or path:find("Networking") or path:find("Packet")
            end
            
            if isTarget then
                local argStrs = {}
                for i, a in ipairs(args) do
                    table.insert(argStrs, string.format(" [arg%d] %s", i, serializeValue(a, 0)))
                end
                
                local action = detectOutgoingAction(args)
                local remotePath = pcall(function() return self:GetFullName() end) and self:GetFullName() or tostring(self)
                
                local entry = {
                    action = action,
                    method = method,
                    remote = remotePath,
                    raw = table.concat(argStrs, "\n"),
                    args = args,
                    time = os.time(),
                    timeStr = os.date("%H:%M:%S")
                }
                
                table.insert(hookPackets, 1, entry)
                if #hookPackets > MAX_PACKETS then
                    table.remove(hookPackets, #hookPackets)
                end
            end
        end
        
        return origNamecall(self, ...)
    end)
    
    return true
end

-- Stop hook
local function stopHook()
    if origNamecall then
        hookmetamethod(game, "__namecall", origNamecall)
        origNamecall = nil
    end
end

-- ============================================
-- DISPLAY FUNCTIONS
-- ============================================
local function showPackets(list, page, title, callback)
    if #list == 0 then
        Library:Notification("📭", "Belum ada packet", 3)
        return page
    end
    
    local totalPages = math.ceil(#list / PAGE_SIZE)
    page = math.max(1, math.min(page, totalPages))
    
    local startIdx = (page-1)*PAGE_SIZE + 1
    local endIdx = math.min(page*PAGE_SIZE, #list)
    local text = string.format("📦 %d-%d / %d\n\n", startIdx, endIdx, #list)
    
    for i = startIdx, endIdx do
        local p = list[i]
        text = text..string.format(
            "━[%d] %s━\n⏱️ %s\n%s\n\n",
            i,
            p.action,
            p.timeStr,
            p.raw:len() > 200 and p.raw:sub(1,200).."..." or p.raw
        )
    end
    
    if totalPages > 1 then
        text = text..string.format("\n📄 Halaman %d/%d", page, totalPages)
    end
    
    Library:Notification(title or "📊 Packet View", text, 20)
    
    if callback then
        callback(page)
    end
    
    return page
end

local function filterPackets(list, keyword)
    local filtered = {}
    for _, p in ipairs(list) do
        if p.action:lower():find(keyword:lower()) then
            table.insert(filtered, p)
        end
    end
    return filtered
end

local function copyPackets(list, title)
    if #list == 0 then
        Library:Notification("❌", "Tidak ada packet", 2)
        return
    end
    
    local text = string.format("=== %s (%d packet) ===\n\n", title, #list)
    for i, p in ipairs(list) do
        text = text..string.format(
            "[%d] %s\n⏱️ %s\nRemote: %s\n%s\n\n",
            i,
            p.action,
            p.timeStr or "?",
            p.remote or "N/A",
            p.raw
        )
    end
    
    doCopy(text)
end

-- ============================================
-- SPY TAB UI
-- ============================================
local SpyPage = SpyTab:Page("Incoming Spy", "eye")
local SpyLeft = SpyPage:Section("📥 Monitor", "Left")
local SpyRight = SpyPage:Section("📋 Hasil", "Right")

SpyLeft:Toggle("📥 Start Spy", "SpyToggle", false,
    "Monitor semua incoming packet (BridgeNet2)",
    function(v)
        spyEnabled = v
        if v then
            local ok = startSpy()
            if ok then
                Library:Notification("👁 Spy ON",
                    "Lakukan aksi di game:\n"..
                    "• Beli bibit\n"..
                    "• Klik lahan → tanam\n"..
                    "• Panen tanaman\n\n"..
                    "Lalu lihat hasil di sini!", 6)
            end
        else
            stopSpy()
            Library:Notification("👁 Spy", "OFF", 2)
        end
    end)

SpyLeft:Button("🗑 Clear Spy Packets", "Hapus semua packet incoming",
    function()
        spyPackets = {}
        Library:Notification("🗑", "Spy packets dihapus", 2)
    end)

SpyLeft:Paragraph("📋 Panduan Spy",
    "1. Toggle Spy → ON\n\n"..
    "2. Di game lakukan:\n"..
    "   🛒 Beli bibit\n"..
    "   🌱 Klik lahan tanam\n"..
    "   🌾 Panen tanaman\n\n"..
    "3. Lihat hasil di kanan\n"..
    "4. Copy untuk analisa")

SpyRight:Button("📄 Lihat Semua Spy", "Tampilkan semua incoming packet",
    function()
        currentSpyPage = showPackets(spyPackets, 1, "📥 Incoming Spy", function(p) currentSpyPage = p end)
    end)

SpyRight:Button("▶ Spy Berikutnya", "Halaman berikutnya",
    function()
        currentSpyPage = showPackets(spyPackets, currentSpyPage+1, "📥 Incoming Spy", function(p) currentSpyPage = p end)
    end)

SpyRight:Button("◀ Spy Sebelumnya", "Halaman sebelumnya",
    function()
        currentSpyPage = showPackets(spyPackets, currentSpyPage-1, "📥 Incoming Spy", function(p) currentSpyPage = p end)
    end)

SpyRight:Button("🌱 Spy TANAM", "Filter packet tanam",
    function()
        local filtered = filterPackets(spyPackets, "tanam")
        showPackets(filtered, 1, "🌱 Tanam (Spy)")
    end)

SpyRight:Button("🛒 Spy BELI", "Filter packet beli",
    function()
        local filtered = filterPackets(spyPackets, "beli")
        showPackets(filtered, 1, "🛒 Beli (Spy)")
    end)

SpyRight:Button("🌾 Spy PANEN", "Filter packet panen",
    function()
        local filtered = filterPackets(spyPackets, "harvest")
        showPackets(filtered, 1, "🌾 Panen (Spy)")
    end)

SpyRight:Button("📋 Copy Semua Spy", "Copy semua spy packet",
    function() copyPackets(spyPackets, "SPY LOG") end)

-- ============================================
-- HOOK TAB UI
-- ============================================
local HookPage = HookTab:Page("Outgoing Hook", "zap")
local HookLeft = HookPage:Section("📤 Hook Control", "Left")
local HookRight = HookPage:Section("📋 Hasil", "Right")

HookLeft:Toggle("📤 Start Hook", "HookToggle", false,
    "Intercept semua FireServer outgoing",
    function(v)
        hookEnabled = v
        if v then
            local ok, err = pcall(startHook)
            if not ok then
                Library:Notification("❌ Hook Error",
                    "hookmetamethod tidak support!\n"..tostring(err), 5)
                hookEnabled = false
            else
                local targets = getTargetRemotes()
                Library:Notification("🔌 Hook ON",
                    string.format("Monitoring %d remote\n\nLakukan aksi:\n🌱 Klik lahan tanam\n🛒 Beli bibit\n🌾 Panen", #targets), 6)
            end
        else
            stopHook()
            Library:Notification("📤 Hook", "OFF", 2)
        end
    end)

HookLeft:Button("🗑 Clear Hook Packets", "Hapus semua packet outgoing",
    function()
        hookPackets = {}
        Library:Notification("🗑", "Hook packets dihapus", 2)
    end)

HookLeft:Paragraph("📋 Panduan Hook",
    "1. Toggle Hook → ON\n\n"..
    "2. Lakukan di game:\n"..
    "   🌱 Klik lahan TANAM\n"..
    "   🛒 Beli bibit\n"..
    "   🌾 Panen\n\n"..
    "3. Lihat hasil di kanan\n"..
    "4. Copy packet untuk analisa")

HookRight:Button("📄 Lihat Semua Hook", "Tampilkan semua outgoing packet",
    function()
        currentHookPage = showPackets(hookPackets, 1, "📤 Outgoing Hook", function(p) currentHookPage = p end)
    end)

HookRight:Button("▶ Hook Berikutnya", "Halaman berikutnya",
    function()
        currentHookPage = showPackets(hookPackets, currentHookPage+1, "📤 Outgoing Hook", function(p) currentHookPage = p end)
    end)

HookRight:Button("◀ Hook Sebelumnya", "Halaman sebelumnya",
    function()
        currentHookPage = showPackets(hookPackets, currentHookPage-1, "📤 Outgoing Hook", function(p) currentHookPage = p end)
    end)

HookRight:Button("🌱 Hook TANAM", "Filter packet tanam",
    function()
        local filtered = filterPackets(hookPackets, "tanam")
        showPackets(filtered, 1, "🌱 Tanam (Hook)")
    end)

HookRight:Button("🛒 Hook BELI", "Filter packet beli",
    function()
        local filtered = filterPackets(hookPackets, "beli")
        showPackets(filtered, 1, "🛒 Beli (Hook)")
    end)

HookRight:Button("🌾 Hook PANEN", "Filter packet panen",
    function()
        local filtered = filterPackets(hookPackets, "harvest")
        showPackets(filtered, 1, "🌾 Panen (Hook)")
    end)

HookRight:Button("📋 Copy Semua Hook", "Copy semua hook packet",
    function() copyPackets(hookPackets, "HOOK LOG") end)

-- ============================================
-- ANALYZER TAB
-- ============================================
local AnalyzerPage = AnalyzerTab:Page("Packet Analyzer", "chart")
local AnaLeft = AnalyzerPage:Section("📊 Statistik", "Left")
local AnaRight = AnalyzerPage:Section("🔄 Perbandingan", "Right")

AnaLeft:Button("📊 Hitung Statistik", "Analisis semua packet",
    function()
        local totalSpy = #spyPackets
        local totalHook = #hookPackets
        
        local spyCounts = {}
        for _, p in ipairs(spyPackets) do
            spyCounts[p.action] = (spyCounts[p.action] or 0) + 1
        end
        
        local hookCounts = {}
        for _, p in ipairs(hookPackets) do
            hookCounts[p.action] = (hookCounts[p.action] or 0) + 1
        end
        
        local text = string.format(
            "📊 STATISTIK PACKET\n\n"..
            "📥 INCOMING (Spy): %d packet\n", totalSpy)
        
        for action, count in pairs(spyCounts) do
            text = text..string.format("   %s: %d\n", action, count)
        end
        
        text = text..string.format("\n📤 OUTGOING (Hook): %d packet\n", totalHook)
        
        for action, count in pairs(hookCounts) do
            text = text..string.format("   %s: %d\n", action, count)
        end
        
        Library:Notification("📊 Statistik", text, 15)
    end)

AnaLeft:Button("🔄 Match Incoming-Outgoing", "Coba cocokkan request-response",
    function()
        -- Ini hanya estimasi sederhana
        local matches = 0
        for _, hook in ipairs(hookPackets) do
            for _, spy in ipairs(spyPackets) do
                if math.abs(hook.time - spy.time) < 3 then -- beda waktu < 3 detik
                    if (hook.action:find("BELI") and spy.action:find("BELI")) or
                       (hook.action:find("TANAM") and spy.action:find("TANAM")) or
                       (hook.action:find("HARVEST") and spy.action:find("HARVEST")) then
                        matches = matches + 1
                        break
                    end
                end
            end
        end
        
        Library:Notification("🔄 Matching",
            string.format("Estimasi pasangan request-response: %d", matches), 5)
    end)

AnaLeft:Button("🗑 Reset Semua", "Hapus semua packet spy & hook",
    function()
        spyPackets = {}
        hookPackets = {}
        Library:Notification("🗑", "Semua packet dihapus", 2)
    end)

AnaRight:Paragraph("📝 Cara Analisis",
    "1. Kumpulkan packet dengan:\n"..
    "   • Spy (incoming)\n"..
    "   • Hook (outgoing)\n\n"..
    "2. Lihat statistik untuk\n"..
    "   melihat pola packet\n\n"..
    "3. Cocokkan request-response\n"..
    "   untuk memahami alur data\n\n"..
    "4. Copy packet yang ditemukan\n"..
    "   untuk dianalisis lebih lanjut")

AnaRight:Paragraph("🎯 Tips",
    "• Packet BELI biasanya:\n"..
    "  OUT: minta beli\n"..
    "  IN: konfirmasi + update coins\n\n"..
    "• Packet TANAM:\n"..
    "  OUT: posisi lahan + jenis\n"..
    "  IN: update tanaman\n\n"..
    "• Packet PANEN:\n"..
    "  OUT: posisi tanaman\n"..
    "  IN: hasil + coins")

-- ============================================
-- SHORTCUT KEYS
-- ============================================
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    -- Ctrl+1 = Lihat Spy
    if input.KeyCode == Enum.KeyCode.One and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        showPackets(spyPackets, 1, "📥 Incoming Spy (Ctrl+1)")
    end
    
    -- Ctrl+2 = Lihat Hook
    if input.KeyCode == Enum.KeyCode.Two and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        showPackets(hookPackets, 1, "📤 Outgoing Hook (Ctrl+2)")
    end
    
    -- Ctrl+3 = Statistik
    if input.KeyCode == Enum.KeyCode.Three and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        -- Panggil statistik
        local text = string.format("📥 Spy: %d | 📤 Hook: %d", #spyPackets, #hookPackets)
        Library:Notification("📊 Statistik Cepat", text, 3)
    end
    
    -- Ctrl+C = Copy semua jika ada yang aktif
    if input.KeyCode == Enum.KeyCode.C and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        if #spyPackets > 0 or #hookPackets > 0 then
            local text = string.format(
                "=== BN2 SPY+HOOK LOG ===\n\n📥 INCOMING (%d):\n", #spyPackets)
            for i, p in ipairs(spyPackets) do
                text = text..string.format("[%d] %s\n", i, p.action)
            end
            text = text..string.format("\n📤 OUTGOING (%d):\n", #hookPackets)
            for i, p in ipairs(hookPackets) do
                text = text..string.format("[%d] %s\n", i, p.action)
            end
            doCopy(text)
        end
    end
end)

-- ============================================
-- INIT
-- ============================================
Library:Notification("🌐 BN2 SPY+HOOK v2.0",
    "Spy = Incoming | Hook = Outgoing\n\n"..
    "Shortcuts:\n"..
    "Ctrl+1 = Lihat Spy\n"..
    "Ctrl+2 = Lihat Hook\n"..
    "Ctrl+3 = Statistik Cepat\n"..
    "Ctrl+C = Copy semua\n\n"..
    "Toggle ON di tab masing-masing!", 8)

Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   🌐 BN2 SPY+HOOK v2.0                  ║")
print("║   Incoming + Outgoing Packet Capture    ║")
print("║   Player: " .. LP.Name)
print("╚══════════════════════════════════════════╝")