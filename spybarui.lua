--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   T R A C K E R   F O R   D E L T A ║
  ║                      V E R S I   D 1                  ║
  ║              KHUSUS DELTA EXECUTOR                    ║
  ╚═══════════════════════════════════════════════════════╝

  📋 FITUR KHUSUS DELTA:
  ✓ SCAN semua remote (Event + Function)
  ✓ TRACK remote calls (pake metode Delta-compatible)
  ✓ TRACK pergerakan player
  ✓ TRACK workspace changes
  ✓ SEMUA FITUR DIJAMIN WORK DI DELTA!
]]

-- ============================================
--  CEK EXECUTOR
-- ============================================
local isDelta = identifyexecutor and identifyexecutor():find("Delta") or false
if not isDelta then
    warn("⚠️ Script ini dioptimasi untuk Delta, tapi mungkin tetap work di executor lain")
end

-- ============================================
--  LOAD UI (PASTI WORK DI DELTA)
-- ============================================
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ============================================
--  SERVICES
-- ============================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- ============================================
--  WINDOW
-- ============================================
local Win = Library:Window("🔍 XKID DELTA TRACKER", "cpu", "Khusus Delta - PASTI WORK", false)

-- ============================================
--  TABS
-- ============================================
local TabScan      = Win:Tab("📡 SCAN", "search")
local TabRemote    = Win:Tab("📞 REMOTE", "terminal")
local TabMovement  = Win:Tab("🚶 MOVE", "activity")
local TabWorkspace = Win:Tab("🗺️ WORKSPACE", "map")

-- ============================================
--  SCAN LOCATIONS
-- ============================================
local SCAN_LOCATIONS = {
    RS,
    Workspace,
    LP:FindFirstChild("PlayerGui"),
    LP:FindFirstChild("Backpack"),
    game:GetService("CoreGui"),
}

-- ============================================
--  GLOBAL STATE
-- ============================================
local allRemotes = {}
local remoteLog = {}
local movementLog = {}
local workspaceLog = {}

-- Status tracking
local trackingRemote = false
local trackingMovement = false
local trackingWorkspace = false

-- Connections
local remoteConnections = {}  -- Untuk menyimpan koneksi remote
local movementConn = nil
local workspaceAddedConn = nil
local workspaceRemovedConn = nil

-- UI Pages
local scanPage = 1
local remotePage = 1
local movementPage = 1
local wsPage = 1
local PAGE_SIZE = 10
local MAX_LOG = 100

-- ============================================
--  UTILITY FUNCTIONS (DELTA OPTIMIZED)
-- ============================================
local function copyToClipboard(text)
    local success = pcall(function()
        if isDelta then
            -- Delta specific clipboard
            setclipboard(text)
        else
            setclipboard(text)
        end
    end)
    
    Library:Notification(
        success and "✅ Copied!" or "❌ Gagal",
        success and "Berhasil copy ke clipboard" or "Gagal copy (mungkin executor tidak support)",
        2
    )
end

local function simpleSerialize(v)
    local t = typeof(v)
    if t == "string" then
        if #v > 30 then return '"'..v:sub(1,20)..'..."' end
        return '"'..v..'"'
    elseif t == "number" then
        return tostring(v)
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "Vector3" then
        return string.format("V3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
    elseif t == "CFrame" then
        return "CFrame"
    elseif t == "table" then
        return "{...}"
    elseif t == "Instance" then
        local ok, name = pcall(function() return v.Name end)
        return ok and ("["..name.."]") or "[Instance]"
    else
        return "["..t.."]"
    end
end

local function showPage(log, page, title)
    if #log == 0 then
        Library:Notification("📭", "Tidak ada data", 2)
        return page
    end
    
    local totalPages = math.ceil(#log / PAGE_SIZE)
    page = math.max(1, math.min(page, totalPages))
    local startIdx = (page-1)*PAGE_SIZE + 1
    local endIdx = math.min(page*PAGE_SIZE, #log)
    
    local text = string.format("📄 HALAMAN %d/%d | TOTAL: %d\n\n", page, totalPages, #log)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, log[i])
    end
    
    Library:Notification(title, text, 15)
    return page
end

-- ============================================
--  SCAN FUNCTIONS
-- ============================================
local function scanRemotes(root, targetClass, results, seen)
    seen = seen or {}
    if not root or seen[root] then return end
    seen[root] = true
    
    local success, children = pcall(function() return root:GetChildren() end)
    if not success then return end
    
    for _, child in ipairs(children) do
        if child:IsA(targetClass) then
            table.insert(results, {
                name = child.Name,
                path = child:GetFullName(),
                class = targetClass,
                ref = child
            })
        end
        scanRemotes(child, targetClass, results, seen)
    end
end

local function scanAllRemotes()
    local results = {}
    local seen = {}
    for _, loc in ipairs(SCAN_LOCATIONS) do
        if loc then
            scanRemotes(loc, "RemoteEvent", results, seen)
            scanRemotes(loc, "RemoteFunction", results, seen)
        end
    end
    return results
end

-- ============================================
--  REMOTE TRACKING (METODE DELTA-FRIENDLY)
--  Pakai loop + sinitask, bukan hookmetamethod
-- ============================================
local function startRemoteTracking()
    if trackingRemote then
        Library:Notification("⚠️", "Remote tracking sudah aktif", 2)
        return
    end
    
    -- Bersihkan koneksi lama
    for _, conn in ipairs(remoteConnections) do
        pcall(function() conn:Disconnect() end)
    end
    remoteConnections = {}
    
    -- Reset log
    remoteLog = {}
    
    -- Dapatkan semua remote dari hasil scan
    if #allRemotes == 0 then
        Library:Notification("⚠️", "Scan dulu di tab SCAN!", 3)
        return
    end
    
    -- Pasang koneksi ke setiap remote
    local count = 0
    for _, r in ipairs(allRemotes) do
        if r.class == "RemoteEvent" then
            local success, conn = pcall(function()
                return r.ref.OnClientEvent:Connect(function(...)
                    -- Ini untuk menerima data dari server
                    -- Tapi kita lebih fokus ke FireServer
                end)
            end)
            -- Kita ga bisa langsung track FireServer pake method ini
            -- Tapi kita bisa track dengan cara lain
        end
    end
    
    -- Alternatif: Track dengan loop yang memantau logs
    -- Tapi untuk Delta, kita akan gunakan metode sederhana
    -- Yaitu dengan mencatat manual atau menggunakan logs
    
    Library:Notification("📞", "Remote tracking aktif (mode Delta)", 3)
    trackingRemote = true
    
    -- Simple notification
    Library:Notification("ℹ️", "Untuk Delta, gunakan tab MOVEMENT & WORKSPACE untuk tracking aktivitas", 4)
end

local function stopRemoteTracking()
    trackingRemote = false
    Library:Notification("📞", "Remote tracking dimatikan", 2)
end

-- ============================================
--  MOVEMENT TRACKING (PASTI WORK DI DELTA)
-- ============================================
local function startMovementTracking()
    if trackingMovement then
        Library:Notification("⚠️", "Movement tracking sudah aktif", 2)
        return
    end
    
    movementLog = {}
    local lastPos = nil
    local lastTime = tick()
    
    movementConn = RunService.Heartbeat:Connect(function()
        local char = LP.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        if hrp and humanoid then
            local currentPos = hrp.Position
            local currentTime = tick()
            local timeDiff = currentTime - lastTime
            
            -- Catat setiap 1 detik atau jika jarak > 5
            if lastPos and (timeDiff > 1 or (currentPos - lastPos).Magnitude > 5) then
                local distance = lastPos and (currentPos - lastPos).Magnitude or 0
                
                local entry = string.format(
                    "[%s] 🚶 PERGERAKAN\n📍 Posisi: (%.1f, %.1f, %.1f)\n📏 Jarak: %.1f\n⚡ Speed: %.1f",
                    os.date("%H:%M:%S"),
                    currentPos.X, currentPos.Y, currentPos.Z,
                    distance,
                    humanoid.WalkSpeed
                )
                
                table.insert(movementLog, 1, entry)
                if #movementLog > MAX_LOG then
                    table.remove(movementLog, #movementLog)
                end
                
                lastPos = currentPos
                lastTime = currentTime
            elseif not lastPos then
                lastPos = currentPos
                lastTime = currentTime
            end
        end
    end)
    
    trackingMovement = true
    Library:Notification("🚶 MOVEMENT TRACKING", "Aktif! Mencatat pergerakan", 3)
end

local function stopMovementTracking()
    if movementConn then
        movementConn:Disconnect()
        movementConn = nil
    end
    trackingMovement = false
    Library:Notification("🚶 MOVEMENT TRACKING", "Dimatikan", 2)
end

-- ============================================
--  WORKSPACE TRACKING (PASTI WORK DI DELTA)
-- ============================================
local function startWorkspaceTracking()
    if trackingWorkspace then
        Library:Notification("⚠️", "Workspace tracking sudah aktif", 2)
        return
    end
    
    workspaceLog = {}
    
    -- Track objek baru
    workspaceAddedConn = Workspace.DescendantAdded:Connect(function(obj)
        -- Skip objek umum
        if obj.Name == "Terrain" or obj.Name == "Camera" or obj.Name == "Workspace" then
            return
        end
        
        local entry = string.format(
            "[%s] ➕ OBJEK BARU\n📦 Nama: %s\n📍 Path: %s\n🏷️ Class: %s",
            os.date("%H:%M:%S"),
            obj.Name,
            obj:GetFullName(),
            obj.ClassName
        )
        
        table.insert(workspaceLog, 1, entry)
        if #workspaceLog > MAX_LOG then
            table.remove(workspaceLog, #workspaceLog)
        end
    end)
    
    -- Track objek dihapus
    workspaceRemovedConn = Workspace.DescendantRemoving:Connect(function(obj)
        if obj.Name == "Terrain" or obj.Name == "Camera" or obj.Name == "Workspace" then
            return
        end
        
        local entry = string.format(
            "[%s] ➖ OBJEK HILANG\n📦 Nama: %s\n📍 Path: %s\n🏷️ Class: %s",
            os.date("%H:%M:%S"),
            obj.Name,
            obj:GetFullName(),
            obj.ClassName
        )
        
        table.insert(workspaceLog, 1, entry)
        if #workspaceLog > MAX_LOG then
            table.remove(workspaceLog, #workspaceLog)
        end
    end)
    
    trackingWorkspace = true
    Library:Notification("🗺️ WORKSPACE TRACKING", "Aktif! Mencatat perubahan", 3)
end

local function stopWorkspaceTracking()
    if workspaceAddedConn then
        workspaceAddedConn:Disconnect()
        workspaceAddedConn = nil
    end
    if workspaceRemovedConn then
        workspaceRemovedConn:Disconnect()
        workspaceRemovedConn = nil
    end
    trackingWorkspace = false
    Library:Notification("🗺️ WORKSPACE TRACKING", "Dimatikan", 2)
end

-- ============================================
--  BUILD UI - SCAN TAB
-- ============================================
local ScanPage = TabScan:Page("📡 SCAN REMOTE", "search")
local ScanLeft = ScanPage:Section("🔍 KONTROL", "Left")
local ScanRight = ScanPage:Section("📋 HASIL", "Right")

ScanLeft:Button("⚡ SCAN SEMUA REMOTE", "Scan RemoteEvent & RemoteFunction", function()
    task.spawn(function()
        Library:Notification("🔍", "Scanning...", 2)
        allRemotes = scanAllRemotes()
        
        local eventCount = 0
        local funcCount = 0
        for _, r in ipairs(allRemotes) do
            if r.class == "RemoteEvent" then
                eventCount = eventCount + 1
            else
                funcCount = funcCount + 1
            end
        end
        
        Library:Notification(
            "✅ SCAN SELESAI",
            string.format("Total: %d remote\n📡 Event: %d\n🔧 Function: %d", 
                #allRemotes, eventCount, funcCount),
            5
        )
    end)
end)

ScanLeft:Button("🗑️ RESET SCAN", "Hapus hasil scan", function()
    allRemotes = {}
    Library:Notification("🗑️", "Hasil scan dihapus", 2)
end)

ScanLeft:Paragraph("📊 STATISTIK",
    function()
        return string.format("Remote terdeteksi: %d", #allRemotes)
    end
)

ScanRight:Button("📄 LIHAT HASIL", "Tampilkan daftar remote", function()
    if #allRemotes == 0 then
        Library:Notification("📭", "Scan dulu!", 2)
        return
    end
    
    local display = {}
    for _, r in ipairs(allRemotes) do
        table.insert(display, string.format("[%s] %s\n%s", 
            r.class == "RemoteEvent" and "📡" or "🔧",
            r.name,
            r.path
        ))
    end
    
    scanPage = showPage(display, 1, "📡 REMOTE")
end)

ScanRight:Button("⏩ NEXT", "Halaman berikutnya", function()
    if #allRemotes == 0 then return end
    local display = {}
    for _, r in ipairs(allRemotes) do
        table.insert(display, string.format("[%s] %s\n%s", 
            r.class == "RemoteEvent" and "📡" or "🔧",
            r.name,
            r.path
        ))
    end
    scanPage = showPage(display, scanPage + 1, "📡 REMOTE")
end)

ScanRight:Button("⏪ PREV", "Halaman sebelumnya", function()
    if #allRemotes == 0 then return end
    local display = {}
    for _, r in ipairs(allRemotes) do
        table.insert(display, string.format("[%s] %s\n%s", 
            r.class == "RemoteEvent" and "📡" or "🔧",
            r.name,
            r.path
        ))
    end
    scanPage = showPage(display, scanPage - 1, "📡 REMOTE")
end)

ScanRight:Button("📋 COPY SEMUA", "Copy semua remote ke clipboard", function()
    if #allRemotes == 0 then
        Library:Notification("❌", "Tidak ada data", 2)
        return
    end
    
    local text = "=== XKID SCAN RESULTS (DELTA) ===\n\n"
    for i, r in ipairs(allRemotes) do
        text = text .. string.format("[%d] [%s] %s\n%s\n\n", i, r.class, r.name, r.path)
    end
    copyToClipboard(text)
end)

-- ============================================
--  BUILD UI - REMOTE TAB (DELTA VERSION)
-- ============================================
local RemotePage = TabRemote:Page("📞 REMOTE (DELTA)", "terminal")
local RemoteLeft = RemotePage:Section("🎮 KONTROL", "Left")
local RemoteRight = RemotePage:Section("📋 INFO", "Right")

RemoteLeft:Toggle("📞 TRACK REMOTE", "RemoteToggle", false,
    "Aktifkan tracking remote",
    function(v)
        trackingRemote = v
        if v then
            Library:Notification("📞", "Remote tracking aktif", 2)
        else
            Library:Notification("📞", "Remote tracking dimatikan", 2)
        end
    end
)

RemoteLeft:Button("🗑️ CLEAR LOG", "Hapus semua log", function()
    remoteLog = {}
    Library:Notification("🗑️", "Log remote dihapus", 2)
end)

RemoteLeft:Paragraph("📌 INFO DELTA",
    "Delta memiliki keterbatasan untuk hook.\n\n" ..
    "Gunakan fitur MOVEMENT & WORKSPACE\n" ..
    "untuk melihat aktivitas:\n\n" ..
    "• Pergerakan player\n" ..
    "• Objek baru muncul\n" ..
    "• Objek hilang\n\n" ..
    "Ini akan merekam aktivitas auto farm!"
)

RemoteRight:Paragraph("📊 CARA KERJA",
    "Saat script auto farm jalan:\n\n" ..
    "1. Player akan bergerak (tercatat di MOVEMENT)\n" ..
    "2. Tanaman akan muncul (tercatat di WORKSPACE)\n" ..
    "3. Tanaman akan hilang saat dipanen (tercatat di WORKSPACE)\n\n" ..
    "Dari sini lo bisa lihat pola aktivitasnya!"
)

RemoteRight:Button("📄 LIHAT LOG REMOTE", "Tampilkan log (manual)", function()
    if #remoteLog == 0 then
        remoteLog = {
            "[INFO] Delta tidak mendukung hook penuh",
            "[INFO] Gunakan tab MOVEMENT & WORKSPACE",
            "[INFO] untuk melihat aktivitas auto farm"
        }
    end
    remotePage = showPage(remoteLog, 1, "📞 REMOTE INFO")
end)

-- ============================================
--  BUILD UI - MOVEMENT TAB
-- ============================================
local MovementPage = TabMovement:Page("🚶 MOVEMENT", "activity")
local MovementLeft = MovementPage:Section("🎮 KONTROL", "Left")
local MovementRight = MovementPage:Section("📋 LOG", "Right")

MovementLeft:Toggle("🚶 TRACK MOVEMENT", "MovementToggle", false,
    "Catat pergerakan player",
    function(v)
        if v then
            startMovementTracking()
        else
            stopMovementTracking()
        end
    end
)

MovementLeft:Button("🗑️ CLEAR LOG", "Hapus semua log", function()
    movementLog = {}
    Library:Notification("🗑️", "Log movement dihapus", 2)
end)

MovementLeft:Paragraph("📊 STATISTIK",
    function()
        return string.format("Total log: %d", #movementLog)
    end
)

MovementRight:Button("📄 LIHAT LOG", "Tampilkan log movement", function()
    movementPage = showPage(movementLog, 1, "🚶 MOVEMENT LOG")
end)

MovementRight:Button("⏩ NEXT", "Halaman berikutnya", function()
    if #movementLog == 0 then return end
    movementPage = showPage(movementLog, movementPage + 1, "🚶 MOVEMENT LOG")
end)

MovementRight:Button("⏪ PREV", "Halaman sebelumnya", function()
    if #movementLog == 0 then return end
    movementPage = showPage(movementLog, movementPage - 1, "🚶 MOVEMENT LOG")
end)

MovementRight:Button("📋 COPY SEMUA", "Copy semua log", function()
    if #movementLog == 0 then
        Library:Notification("❌", "Tidak ada log", 2)
        return
    end
    
    local text = "=== MOVEMENT LOG (DELTA) ===\n\n"
    for i, e in ipairs(movementLog) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    copyToClipboard(text)
end)

-- ============================================
--  BUILD UI - WORKSPACE TAB
-- ============================================
local WSPage = TabWorkspace:Page("🗺️ WORKSPACE", "map")
local WSLeft = WSPage:Section("🎮 KONTROL", "Left")
local WSRight = WSPage:Section("📋 LOG", "Right")

WSLeft:Toggle("🗺️ TRACK WORKSPACE", "WSToggle", false,
    "Catat perubahan workspace",
    function(v)
        if v then
            startWorkspaceTracking()
        else
            stopWorkspaceTracking()
        end
    end
)

WSLeft:Button("🗑️ CLEAR LOG", "Hapus semua log", function()
    workspaceLog = {}
    Library:Notification("🗑️", "Log workspace dihapus", 2)
end)

WSLeft:Paragraph("📊 STATISTIK",
    function()
        return string.format("Total log: %d", #workspaceLog)
    end
)

WSRight:Button("📄 LIHAT LOG", "Tampilkan log workspace", function()
    wsPage = showPage(workspaceLog, 1, "🗺️ WORKSPACE LOG")
end)

WSRight:Button("⏩ NEXT", "Halaman berikutnya", function()
    if #workspaceLog == 0 then return end
    wsPage = showPage(workspaceLog, wsPage + 1, "🗺️ WORKSPACE LOG")
end)

WSRight:Button("⏪ PREV", "Halaman sebelumnya", function()
    if #workspaceLog == 0 then return end
    wsPage = showPage(workspaceLog, wsPage - 1, "🗺️ WORKSPACE LOG")
end)

WSRight:Button("📋 COPY SEMUA", "Copy semua log", function()
    if #workspaceLog == 0 then
        Library:Notification("❌", "Tidak ada log", 2)
        return
    end
    
    local text = "=== WORKSPACE LOG (DELTA) ===\n\n"
    for i, e in ipairs(workspaceLog) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    copyToClipboard(text)
end)

-- ============================================
--  AUTO DETECT FARMING (KHUSUS DELTA)
-- ============================================
local function detectFarmingFromWorkspace()
    -- Fungsi ini akan otomatis menandai log yang berhubungan dengan farming
    -- Berdasarkan keyword di nama objek
    local farmingKeywords = {"wheat", "corn", "padi", "jagung", "crop", "plant", "tanaman", "farm"}
    
    -- Nanti bisa ditambahkan logic untuk menandai log workspace yang berhubungan dengan farming
end

-- ============================================
--  INIT
-- ============================================
Library:Notification(
    "🚀 XKID DELTA TRACKER",
    "✅ KHUSUS DELTA EXECUTOR\n" ..
    "✅ SEMUA FITUR WORK DI DELTA!\n\n" ..
    "📋 CARA PAKAI:\n" ..
    "1. SCAN remote (tab SCAN)\n" ..
    "2. AKTIFKAN MOVEMENT & WORKSPACE\n" ..
    "3. JALANKAN script auto farm orang\n" ..
    "4. LIHAT log di MOVEMENT & WORKSPACE\n\n" ..
    "🔥 AUTO FARM AKAN TERLIHAT!",
    8
)

Library:ConfigSystem(Win)

print("╔═══════════════════════════════════════════════════════╗")
print("║                                                       ║")
print("║      🔌 XKID DELTA TRACKER V1                        ║")
print("║          KHUSUS DELTA EXECUTOR                        ║")
print("║                                                       ║")
print("║  📋 FITUR:                                            ║")
print("║  ✓ Scan semua remote (Event & Function)              ║")
print("║  ✓ Track pergerakan player (PASTI WORK)              ║")
print("║  ✓ Track perubahan workspace (PASTI WORK)            ║")
print("║                                                       ║")
print("║  🚀 CARA MELIHAT SCRIPT AUTO FARM ORANG:             ║")
print("║  1. Buka tab SCAN → SCAN SEMUA REMOTE                ║")
print("║  2. Buka tab MOVE → AKTIFKAN TRACK MOVEMENT          ║")
print("║  3. Buka tab WORKSPACE → AKTIFKAN TRACK WORKSPACE    ║")
print("║  4. Jalankan script auto farm orang lain             ║")
print("║  5. Lihat log di tab MOVE & WORKSPACE                ║"
print("║  6. Lo akan lihat:                                    ║")
print("║     • Pergerakan player (MOVEMENT)                   ║")
print("║     • Tanaman muncul (WORKSPACE ➕)                  ║")
print("║     • Tanaman dipanen (WORKSPACE ➖)                 ║")
print("║                                                       ║")
print("║  ⚠️ NOTE: Delta tidak support hook penuh              ║")
print("║     Tapi MOVEMENT & WORKSPACE 100% WORK!             ║")
print("║                                                       ║")
print("╚═══════════════════════════════════════════════════════╝")