--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   T R A C K E R   V 5              ║
  ║          DENGAN LIST REMOTE & COPY LOG               ║
  ║              FIX UNTUK DELTA EXECUTOR                ║
  ╚═══════════════════════════════════════════════════════╝

  📋 FITUR:
  ✓ LIST REMOTE (bisa lihat semua remote)
  ✓ COPY LOG ke clipboard
  ✓ TRACK pergerakan player
  ✓ TRACK objek baru/hilang
  ✓ SEMUA TOMBOL BERFUNGSI
]]

-- ============================================
--  LOAD UI (VERSI STABIL UNTUK DELTA)
-- ============================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()
local Win = Library:Window("🔍 XKID TRACKER V5", "cpu", "Dengan Copy Log", false)

-- ============================================
--  TABS
-- ============================================
local TabScan   = Win:Tab("📡 SCAN", "search")
local TabMove   = Win:Tab("🚶 MOVE", "activity")
local TabObj    = Win:Tab("📦 OBJEK", "package")
local TabLog    = Win:Tab("📋 LOG", "file-text")

-- ============================================
--  SERVICES
-- ============================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- ============================================
--  GLOBAL STATE
-- ============================================
local allRemotes = {}
local moveLog = {}
local objLog = {}
local allLogs = {}  -- Gabungan semua log

local trackMove = false
local trackObj = false
local moveConn = nil
local objAddedConn = nil
local objRemovedConn = nil

-- UI Pages
local scanPage = 1
local movePage = 1
local objPage = 1
local logPage = 1
local PAGE_SIZE = 10
local MAX_LOG = 100

-- ============================================
--  CLIPBOARD FUNCTION (FIX UNTUK DELTA)
-- ============================================
local function copyToClipboard(text)
    local success = pcall(function()
        -- Method yang work di kebanyakan executor
        setclipboard(text)
    end)
    
    if success then
        Library:Notification("✅ COPY", "Berhasil copy ke clipboard", 2)
    else
        -- Fallback: tampilkan di console
        print("📋 TEXT TO COPY:")
        print(text)
        Library:Notification("⚠️ COPY", "Gagal copy. Lihat di console (F9)", 3)
    end
end

-- ============================================
--  SCAN FUNCTIONS
-- ============================================
local function scanAllRemotes()
    local results = {}
    local locations = {
        RS,
        Workspace,
        LP:FindFirstChild("PlayerGui"),
        LP:FindFirstChild("Backpack"),
        game:GetService("CoreGui")
    }
    
    for _, loc in ipairs(locations) do
        if loc then
            for _, obj in ipairs(loc:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    table.insert(results, {
                        name = obj.Name,
                        path = obj:GetFullName(),
                        class = obj.ClassName,
                        ref = obj
                    })
                end
            end
        end
    end
    return results
end

-- ============================================
--  DISPLAY PAGE
-- ============================================
local function showPage(list, page, title)
    if #list == 0 then
        Library:Notification("📭", "Tidak ada data", 2)
        return page
    end
    
    local totalPages = math.ceil(#list / PAGE_SIZE)
    page = math.max(1, math.min(page, totalPages))
    local startIdx = (page-1)*PAGE_SIZE + 1
    local endIdx = math.min(page*PAGE_SIZE, #list)
    
    local text = string.format("📄 HALAMAN %d/%d | TOTAL: %d\n\n", page, totalPages, #list)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, list[i])
        text = text .. string.format("─" .. string.rep("─", 30) .. "\n\n")
    end
    
    Library:Notification(title, text, 15)
    return page
end

-- ============================================
--  MOVEMENT TRACKER
-- ============================================
local function startMoveTrack()
    if trackMove then return end
    moveLog = {}
    local lastPos = nil
    local lastTime = tick()
    
    moveConn = RunService.Heartbeat:Connect(function()
        if not trackMove then return end
        
        local char = LP.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local pos = hrp.Position
        local currentTime = tick()
        
        if lastPos and (currentTime - lastTime) > 1 then
            local jarak = (pos - lastPos).Magnitude
            if jarak > 1 then
                local entry = string.format(
                    "[%s] 🚶 PERGERAKAN\n📍 Posisi: (%.1f, %.1f, %.1f)\n📏 Jarak: %.1f",
                    os.date("%H:%M:%S"),
                    pos.X, pos.Y, pos.Z,
                    jarak
                )
                table.insert(moveLog, 1, entry)
                table.insert(allLogs, 1, "[MOVE] " .. entry)
                
                if #moveLog > MAX_LOG then table.remove(moveLog, #moveLog) end
                if #allLogs > MAX_LOG * 3 then table.remove(allLogs, #allLogs) end
            end
            lastPos = pos
            lastTime = currentTime
        elseif not lastPos then
            lastPos = pos
            lastTime = currentTime
        end
    end)
    
    trackMove = true
    Library:Notification("✅", "Movement tracking ON", 2)
end

local function stopMoveTrack()
    if moveConn then
        moveConn:Disconnect()
        moveConn = nil
    end
    trackMove = false
    Library:Notification("✅", "Movement tracking OFF", 2)
end

-- ============================================
--  OBJECT TRACKER
-- ============================================
local function startObjTrack()
    if trackObj then return end
    objLog = {}
    
    objAddedConn = Workspace.DescendantAdded:Connect(function(obj)
        if not trackObj then return end
        
        -- Filter objek yang relevan
        if obj:IsA("BasePart") and #obj.Name > 1 and obj.Name ~= "Terrain" then
            local entry = string.format(
                "[%s] ➕ OBJEK BARU\n📦 Nama: %s\n📍 Posisi: (%.1f, %.1f, %.1f)\n🏷️ Class: %s",
                os.date("%H:%M:%S"),
                obj.Name,
                obj.Position.X, obj.Position.Y, obj.Position.Z,
                obj.ClassName
            )
            table.insert(objLog, 1, entry)
            table.insert(allLogs, 1, "[OBJ] " .. entry)
            
            if #objLog > MAX_LOG then table.remove(objLog, #objLog) end
            if #allLogs > MAX_LOG * 3 then table.remove(allLogs, #allLogs) end
        end
    end)
    
    objRemovedConn = Workspace.DescendantRemoving:Connect(function(obj)
        if not trackObj then return end
        
        if obj:IsA("BasePart") and #obj.Name > 1 and obj.Name ~= "Terrain" then
            local entry = string.format(
                "[%s] ➖ OBJEK HILANG\n📦 Nama: %s",
                os.date("%H:%M:%S"),
                obj.Name
            )
            table.insert(objLog, 1, entry)
            table.insert(allLogs, 1, "[OBJ] " .. entry)
            
            if #objLog > MAX_LOG then table.remove(objLog, #objLog) end
            if #allLogs > MAX_LOG * 3 then table.remove(allLogs, #allLogs) end
        end
    end)
    
    trackObj = true
    Library:Notification("✅", "Object tracking ON", 2)
end

local function stopObjTrack()
    if objAddedConn then
        objAddedConn:Disconnect()
        objAddedConn = nil
    end
    if objRemovedConn then
        objRemovedConn:Disconnect()
        objRemovedConn = nil
    end
    trackObj = false
    Library:Notification("✅", "Object tracking OFF", 2)
end

-- ============================================
--  BUILD UI - SCAN TAB (DENGAN LIST REMOTE)
-- ============================================
local ScanPage = TabScan:Page("📡 SCAN REMOTE", "search")
local ScanLeft = ScanPage:Section("🔍 KONTROL", "Left")
local ScanRight = ScanPage:Section("📋 LIST REMOTE", "Right")

-- LEFT SECTION
ScanLeft:Button("🔍 SCAN SEMUA REMOTE", "Scan RemoteEvent & Function", function()
    task.spawn(function()
        Library:Notification("⏳", "Scanning...", 2)
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
            4
        )
    end)
end)

ScanLeft:Button("🗑️ RESET SCAN", "Hapus hasil scan", function()
    allRemotes = {}
    Library:Notification("🗑️", "Hasil scan dihapus", 2)
end)

ScanLeft:Paragraph("📊 STATISTIK",
    function()
        return string.format("Remote: %d", #allRemotes)
    end
)

-- RIGHT SECTION - LIST REMOTE
ScanRight:Button("📋 TAMPILKAN LIST", "Lihat daftar remote", function()
    if #allRemotes == 0 then
        Library:Notification("📭", "Scan dulu!", 2)
        return
    end
    
    local display = {}
    for i, r in ipairs(allRemotes) do
        table.insert(display, string.format("[%d] [%s] %s\n%s", 
            i,
            r.class == "RemoteEvent" and "EVENT" or "FUNC",
            r.name,
            r.path
        ))
    end
    
    scanPage = showPage(display, 1, "📡 LIST REMOTE")
end)

ScanRight:Button("⏩ NEXT", "Halaman berikutnya", function()
    if #allRemotes == 0 then return end
    local display = {}
    for i, r in ipairs(allRemotes) do
        table.insert(display, string.format("[%d] [%s] %s\n%s", 
            i,
            r.class == "RemoteEvent" and "EVENT" or "FUNC",
            r.name,
            r.path
        ))
    end
    scanPage = showPage(display, scanPage + 1, "📡 LIST REMOTE")
end)

ScanRight:Button("⏪ PREV", "Halaman sebelumnya", function()
    if #allRemotes == 0 then return end
    local display = {}
    for i, r in ipairs(allRemotes) do
        table.insert(display, string.format("[%d] [%s] %s\n%s", 
            i,
            r.class == "RemoteEvent" and "EVENT" or "FUNC",
            r.name,
            r.path
        ))
    end
    scanPage = showPage(display, scanPage - 1, "📡 LIST REMOTE")
end)

ScanRight:Button("📋 COPY SEMUA REMOTE", "Copy semua remote ke clipboard", function()
    if #allRemotes == 0 then
        Library:Notification("❌", "Tidak ada data", 2)
        return
    end
    
    local text = "=== XKID REMOTE LIST ===\n\n"
    for i, r in ipairs(allRemotes) do
        text = text .. string.format("[%d] [%s] %s\n%s\n\n", 
            i, 
            r.class == "RemoteEvent" and "EVENT" or "FUNC",
            r.name, 
            r.path
        )
    end
    
    copyToClipboard(text)
end)

-- ============================================
--  BUILD UI - MOVE TAB (DENGAN COPY)
-- ============================================
local MovePage = TabMove:Page("🚶 MOVEMENT", "activity")
local MoveLeft = MovePage:Section("🎮 KONTROL", "Left")
local MoveRight = MovePage:Section("📋 LOG MOVE", "Right")

MoveLeft:Toggle("🚶 TRACK MOVE", "MoveToggle", false, "Track pergerakan player", function(v)
    if v then startMoveTrack() else stopMoveTrack() end
end)

MoveLeft:Button("🗑️ CLEAR MOVE LOG", "Hapus log movement", function()
    moveLog = {}
    Library:Notification("🗑️", "Move log cleared", 2)
end)

MoveLeft:Paragraph("📊 STAT MOVE",
    function()
        return string.format("Total log: %d", #moveLog)
    end
)

MoveRight:Button("📋 LIHAT MOVE LOG", "Tampilkan log movement", function()
    if #moveLog == 0 then
        Library:Notification("📭", "Belum ada log", 2)
        return
    end
    movePage = showPage(moveLog, 1, "🚶 MOVE LOG")
end)

MoveRight:Button("⏩ NEXT", "Halaman berikutnya", function()
    if #moveLog == 0 then return end
    movePage = showPage(moveLog, movePage + 1, "🚶 MOVE LOG")
end)

MoveRight:Button("⏪ PREV", "Halaman sebelumnya", function()
    if #moveLog == 0 then return end
    movePage = showPage(moveLog, movePage - 1, "🚶 MOVE LOG")
end)

MoveRight:Button("📋 COPY MOVE LOG", "Copy semua log movement", function()
    if #moveLog == 0 then
        Library:Notification("❌", "Tidak ada log", 2)
        return
    end
    
    local text = "=== MOVEMENT LOG ===\n\n"
    for i, e in ipairs(moveLog) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    
    copyToClipboard(text)
end)

-- ============================================
--  BUILD UI - OBJEK TAB (DENGAN COPY)
-- ============================================
local ObjPage = TabObj:Page("📦 OBJEK", "package")
local ObjLeft = ObjPage:Section("🎮 KONTROL", "Left")
local ObjRight = ObjPage:Section("📋 LOG OBJEK", "Right")

ObjLeft:Toggle("📦 TRACK OBJEK", "ObjToggle", false, "Track objek baru/hilang", function(v)
    if v then startObjTrack() else stopObjTrack() end
end)

ObjLeft:Button("🗑️ CLEAR OBJ LOG", "Hapus log objek", function()
    objLog = {}
    Library:Notification("🗑️", "Obj log cleared", 2)
end)

ObjLeft:Paragraph("📊 STAT OBJEK",
    function()
        return string.format("Total log: %d", #objLog)
    end
)

ObjRight:Button("📋 LIHAT OBJ LOG", "Tampilkan log objek", function()
    if #objLog == 0 then
        Library:Notification("📭", "Belum ada log", 2)
        return
    end
    objPage = showPage(objLog, 1, "📦 OBJEK LOG")
end)

ObjRight:Button("⏩ NEXT", "Halaman berikutnya", function()
    if #objLog == 0 then return end
    objPage = showPage(objLog, objPage + 1, "📦 OBJEK LOG")
end)

ObjRight:Button("⏪ PREV", "Halaman sebelumnya", function()
    if #objLog == 0 then return end
    objPage = showPage(objLog, objPage - 1, "📦 OBJEK LOG")
end)

ObjRight:Button("📋 COPY OBJ LOG", "Copy semua log objek", function()
    if #objLog == 0 then
        Library:Notification("❌", "Tidak ada log", 2)
        return
    end
    
    local text = "=== OBJEK LOG ===\n\n"
    for i, e in ipairs(objLog) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    
    copyToClipboard(text)
end)

-- ============================================
--  BUILD UI - LOG TAB (GABUNGAN SEMUA LOG)
-- ============================================
local LogPage = TabLog:Page("📋 SEMUA LOG", "file-text")
local LogLeft = LogPage:Section("🎮 KONTROL", "Left")
local LogRight = LogPage:Section("📋 LOG GABUNGAN", "Right")

LogLeft:Button("🗑️ CLEAR ALL LOGS", "Hapus semua log", function()
    moveLog = {}
    objLog = {}
    allLogs = {}
    Library:Notification("🗑️", "Semua log dihapus", 2)
end)

LogLeft:Paragraph("📊 STAT TOTAL",
    function()
        return string.format("Move: %d\nObjek: %d\nTotal: %d", 
            #moveLog, #objLog, #allLogs)
    end
)

LogRight:Button("📋 LIHAT SEMUA LOG", "Tampilkan semua log", function()
    if #allLogs == 0 then
        Library:Notification("📭", "Belum ada log", 2)
        return
    end
    logPage = showPage(allLogs, 1, "📋 SEMUA LOG")
end)

LogRight:Button("⏩ NEXT", "Halaman berikutnya", function()
    if #allLogs == 0 then return end
    logPage = showPage(allLogs, logPage + 1, "📋 SEMUA LOG")
end)

LogRight:Button("⏪ PREV", "Halaman sebelumnya", function()
    if #allLogs == 0 then return end
    logPage = showPage(allLogs, logPage - 1, "📋 SEMUA LOG")
end)

LogRight:Button("📋 COPY SEMUA LOG", "Copy semua log ke clipboard", function()
    if #allLogs == 0 then
        Library:Notification("❌", "Tidak ada log", 2)
        return
    end
    
    local text = "=== XKID ALL LOGS ===\n\n"
    for i, e in ipairs(allLogs) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    
    copyToClipboard(text)
end)

LogRight:Button("📋 COPY 20 TERAKHIR", "Copy 20 log terbaru", function()
    if #allLogs == 0 then
        Library:Notification("❌", "Tidak ada log", 2)
        return
    end
    
    local text = "=== XKID LAST 20 LOGS ===\n\n"
    for i = 1, math.min(20, #allLogs) do
        text = text .. string.format("[%d] %s\n\n", i, allLogs[i])
    end
    
    copyToClipboard(text)
end)

-- ============================================
--  INIT
-- ============================================
Library:Notification(
    "🚀 XKID TRACKER V5",
    "✅ LIST REMOTE\n" ..
    "✅ COPY LOG\n" ..
    "✅ TRACK MOVE & OBJEK\n\n" ..
    "🔥 SEMUA TOMBOL BERFUNGSI!",
    5
)

Library:ConfigSystem(Win)

print("╔═══════════════════════════════════════════════════════╗")
print("║                                                       ║")
print("║      🔌 XKID TRACKER V5                              ║")
print("║          DENGAN LIST REMOTE & COPY LOG               ║")
print("║                                                       ║")
print("║  📋 FITUR:                                            ║")
print("║  ✓ LIST REMOTE (lihat semua remote)                  ║")
print("║  ✓ COPY LOG ke clipboard                             ║")
print("║  ✓ TRACK pergerakan player                           ║")
print("║  ✓ TRACK objek baru/hilang                           ║")
print("║                                                       ║")
print("║  🚀 CARA PAKAI:                                       ║")
print("║  1. Buka tab SCAN → SCAN SEMUA REMOTE                ║")
print("║  2. Lihat LIST REMOTE (tombol TAMPILKAN LIST)        ║")
print("║  3. Aktifkan TRACK MOVE & TRACK OBJEK                ║")
print("║  4. Jalankan auto farm orang                         ║")
print("║  5. Lihat LOG di masing-masing tab                   ║")
print("║  6. COPY LOG dengan tombol COPY                      ║")
print("║                                                       ║")
print("║  ✅ SEMUA TOMBOL BERFUNGSI DI DELTA!                 ║")
print("║                                                       ║")
print("╚═══════════════════════════════════════════════════════╝")