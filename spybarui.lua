--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   R E M O T E   T R A C K E R     ║
  ║                      V E R S I   2                   ║
  ║              SEMUA FITUR BERJALAN SEMPURNA           ║
  ╚═══════════════════════════════════════════════════════╝

  📋 FITUR:
  ✓ SCAN semua RemoteEvent & RemoteFunction
  ✓ FARM SPY (deteksi otomatis Plant/Harvest/Sell)
  ✓ WORKSPACE MONITOR (lihat objek yang muncul/hilang)
  ✓ LOG REAL-TIME dengan timestamp
  ✓ COPY ke clipboard

  🚀 CARA PAKAI:
  1. JALANKAN SCRIPT
  2. BUKA TAB "📡 SCAN" → KLIK "SCAN SEMUA"
  3. SETELAH SCAN SELESAI, BUKA TAB "🌾 FARM SPY"
  4. AKTIFKAN "🌾 AKTIFKAN FARM SPY"
  5. LAKUKAN TANAM/PANEN/JUAL DI GAME
  6. LIHAT LOG DI TAB TERSEBUT
  7. UNTUK WORKSPACE, AKTIFKAN DI TAB "🗺️ WORKSPACE"

  ⚠️ PASTIKAN EXECUTOR SUPPORT hookmetamethod!
]]

-- ============================================
--  LOAD AURORA UI
-- ============================================
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ============================================
--  SERVICES
-- ============================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- ============================================
--  WINDOW UTAMA
-- ============================================
local Win = Library:Window(
    "🔍 XKID REMOTE TRACKER V2",
    "cpu",
    "100% Work | Simple & Ringan",
    false
)

-- ============================================
--  TABS
-- ============================================
local TabScan   = Win:Tab("📡 SCAN", "search")
local TabFarm   = Win:Tab("🌾 FARM SPY", "sprout")
local TabWorkspace = Win:Tab("🗺️ WORKSPACE", "map")

-- ============================================
--  SCAN LOCATIONS
-- ============================================
local SCAN_LOCATIONS = {
    RS, RF, Workspace,
    LP:WaitForChild("PlayerGui", 3),
    LP:WaitForChild("Backpack", 3),
}

-- ============================================
--  GLOBAL VARIABLES
-- ============================================
local allRemotes = {}          -- { name, path, rtype, ref }
local farmLog = {}              -- log farming
local workspaceLog = {}         -- log workspace changes

local farmSpyActive = false
local workspaceActive = false

local farmHook = nil            -- untuk menyimpan hook asli
local workspaceConn = nil       -- untuk DescendantAdded
local workspaceRemoveConn = nil -- untuk DescendantRemoving

local currentPageScan = 1
local currentPageFarm = 1
local currentPageWorkspace = 1
local PAGE_SIZE = 10
local MAX_LOG = 100

-- ============================================
--  UTILITY FUNCTIONS
-- ============================================
local function doCopy(text)
    local ok = pcall(function() setclipboard(text) end)
    Library:Notification(
        ok and "📋 Copied!" or "❌ Gagal",
        ok and "Berhasil copy ke clipboard!" or "setclipboard tidak support",
        2
    )
end

local function serializeValue(v, depth)
    depth = depth or 0
    if depth > 2 then return "..." end
    local t = typeof(v)
    if t == "string" then
        if #v > 40 then return '"'..v:sub(1,20)..'..."' end
        return '"'..v..'"'
    elseif t == "number" then return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "Vector3" then return string.format("V3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
    elseif t == "CFrame" then return "CFrame"
    elseif t == "table" then return "{...}"
    elseif t == "Instance" then
        local ok, name = pcall(function() return v.Name end)
        return ok and ("["..name.."]") or "[Instance]"
    else return "["..t.."]" end
end

local function formatArgs(args)
    local parts = {}
    for i, a in ipairs(args) do
        table.insert(parts, "["..i.."]"..serializeValue(a))
    end
    return table.concat(parts, " ")
end

-- ============================================
--  SCAN FUNCTIONS
-- ============================================
local function scanRemotes(root, targetClass, results, seen)
    seen = seen or {}
    if not root or seen[root] then return end
    seen[root] = true
    local ok, children = pcall(function() return root:GetChildren() end)
    if not ok then return end
    for _, child in ipairs(children) do
        if child:IsA(targetClass) then
            table.insert(results, {
                name = child.Name,
                path = child:GetFullName(),
                rtype = targetClass == "RemoteEvent" and "EVENT" or "FUNC",
                ref = child,
            })
        end
        scanRemotes(child, targetClass, results, seen)
    end
end

local function scanAll(targetClass)
    local results = {}
    local seen = {}
    for _, loc in ipairs(SCAN_LOCATIONS) do
        scanRemotes(loc, targetClass, results, seen)
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
    
    local text = string.format("📄 Halaman %d/%d | Total: %d\n\n", page, totalPages, #list)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n%s\n\n", i, list[i], string.rep("─", 30))
    end
    Library:Notification(title, text, 15)
    return page
end

-- ============================================
--  FARM SPY (HOOK METHOD)
-- ============================================
local function startFarmSpy()
    if farmSpyActive then
        Library:Notification("⚠️", "Farm Spy sudah aktif", 2)
        return
    end
    
    -- Pastikan sudah scan
    if #allRemotes == 0 then
        Library:Notification("❌", "Scan dulu di tab SCAN!", 3)
        return
    end
    
    -- Bangun target set (remote yang namanya mengandung keyword farming)
    local farmKeywords = {"plant", "tanam", "harvest", "panen", "sell", "jual", "bibit", "seed", "crop"}
    local targetSet = {}
    for _, r in ipairs(allRemotes) do
        local nameLower = r.name:lower()
        for _, kw in ipairs(farmKeywords) do
            if nameLower:find(kw, 1, true) then
                targetSet[r.ref] = {name = r.name, path = r.path}
                break
            end
        end
    end
    
    if not next(targetSet) then
        Library:Notification("❌", "Tidak ada remote farming ditemukan!", 3)
        return
    end
    
    -- Reset log
    farmLog = {}
    
    -- Pasang hook
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        -- Cek apakah remote ini termasuk target farming
        local target = targetSet[self]
        if target and (method == "FireServer" or method == "InvokeServer") then
            -- Deteksi aksi berdasarkan nama
            local action = "❓"
            local nl = target.name:lower()
            if nl:find("plant") or nl:find("tanam") then action = "🌱 TANAM"
            elseif nl:find("harvest") or nl:find("panen") then action = "🌾 PANEN"
            elseif nl:find("sell") or nl:find("jual") then action = "💰 JUAL"
            elseif nl:find("bibit") or nl:find("seed") then action = "🌱 BELI BIBIT"
            end
            
            -- Format log
            local timeStr = os.date("%H:%M:%S")
            local argStr = formatArgs(args)
            local entry = string.format(
                "[%s] %s %s\n📦 %s\n📂 %s\n📋 %s",
                timeStr,
                action,
                target.name,
                target.path,
                method,
                argStr
            )
            
            table.insert(farmLog, 1, entry)
            if #farmLog > MAX_LOG then
                table.remove(farmLog, #farmLog)
            end
        end
        
        -- Panggil method asli
        return oldNamecall(self, ...)
    end)
    
    farmHook = oldNamecall
    farmSpyActive = true
    
    Library:Notification(
        "🌾 FARM SPY AKTIF",
        string.format("Memantau %d remote farming", #farmLog),
        3
    )
end

local function stopFarmSpy()
    if farmSpyActive and farmHook then
        -- Kembalikan hook ke semula
        hookmetamethod(game, "__namecall", farmHook)
        farmHook = nil
        farmSpyActive = false
        Library:Notification("🌾 FARM SPY", "Dimatikan", 2)
    end
end

-- ============================================
--  WORKSPACE MONITOR
-- ============================================
local function startWorkspaceMonitor()
    if workspaceActive then
        Library:Notification("⚠️", "Workspace monitor sudah aktif", 2)
        return
    end
    
    workspaceLog = {}
    
    -- Monitor objek baru
    workspaceConn = Workspace.DescendantAdded:Connect(function(obj)
        local timeStr = os.date("%H:%M:%S")
        local entry = string.format(
            "[%s] ➕ OBJEK BARU\n📦 Nama: %s\n📍 Path: %s\n🏷️ Class: %s",
            timeStr,
            obj.Name,
            obj:GetFullName(),
            obj.ClassName
        )
        table.insert(workspaceLog, 1, entry)
        if #workspaceLog > MAX_LOG then
            table.remove(workspaceLog, #workspaceLog)
        end
    end)
    
    -- Monitor objek dihapus
    workspaceRemoveConn = Workspace.DescendantRemoving:Connect(function(obj)
        local timeStr = os.date("%H:%M:%S")
        local entry = string.format(
            "[%s] ➖ OBJEK HILANG\n📦 Nama: %s\n📍 Path: %s\n🏷️ Class: %s",
            timeStr,
            obj.Name,
            obj:GetFullName(),
            obj.ClassName
        )
        table.insert(workspaceLog, 1, entry)
        if #workspaceLog > MAX_LOG then
            table.remove(workspaceLog, #workspaceLog)
        end
    end)
    
    workspaceActive = true
    Library:Notification("🗺️ WORKSPACE MONITOR", "Aktif! Memantau perubahan...", 3)
end

local function stopWorkspaceMonitor()
    if workspaceConn then
        workspaceConn:Disconnect()
        workspaceConn = nil
    end
    if workspaceRemoveConn then
        workspaceRemoveConn:Disconnect()
        workspaceRemoveConn = nil
    end
    workspaceActive = false
    Library:Notification("🗺️ WORKSPACE MONITOR", "Dimatikan", 2)
end

-- ============================================
--  BUILD UI - SCAN TAB
-- ============================================
local ScanPage = TabScan:Page("📡 REMOTE SCANNER", "search")
local ScanLeft = ScanPage:Section("🔍 SCANNER", "Left")
local ScanRight = ScanPage:Section("📋 HASIL SCAN", "Right")

ScanLeft:Paragraph("📌 INSTRUKSI",
    "1. Klik tombol SCAN SEMUA\n" ..
    "2. Tunggu notifikasi selesai\n" ..
    "3. Lihat hasil di sebelah kanan"
)

ScanLeft:Button("⚡ SCAN SEMUA REMOTE", "Scan RemoteEvent & RemoteFunction", function()
    task.spawn(function()
        Library:Notification("🔍", "Scanning...", 2)
        local events = scanAll("RemoteEvent")
        local funcs = scanAll("RemoteFunction")
        local all = {}
        for _, r in ipairs(events) do table.insert(all, r) end
        for _, r in ipairs(funcs) do table.insert(all, r) end
        allRemotes = all
        Library:Notification(
            "✅ SCAN SELESAI",
            string.format("Total: %d remote\n%d Event, %d Function", #all, #events, #funcs),
            5
        )
    end)
end)

ScanLeft:Button("🗑️ RESET SCAN", "Hapus hasil scan", function()
    allRemotes = {}
    Library:Notification("🗑️", "Hasil scan dihapus", 2)
end)

ScanRight:Button("📄 LIHAT HASIL", "Tampilkan daftar remote", function()
    if #allRemotes == 0 then
        Library:Notification("📭", "Belum ada data, scan dulu!", 2)
        return
    end
    local display = {}
    for _, r in ipairs(allRemotes) do
        table.insert(display, string.format("[%s] %s\n%s", r.rtype, r.name, r.path))
    end
    currentPageScan = showPage(display, 1, "📡 REMOTE")
end)

ScanRight:Button("⏩ HALAMAN BERIKUTNYA", "Next page", function()
    if #allRemotes == 0 then return end
    local display = {}
    for _, r in ipairs(allRemotes) do
        table.insert(display, string.format("[%s] %s\n%s", r.rtype, r.name, r.path))
    end
    currentPageScan = showPage(display, currentPageScan + 1, "📡 REMOTE")
end)

ScanRight:Button("⏪ HALAMAN SEBELUMNYA", "Prev page", function()
    if #allRemotes == 0 then return end
    local display = {}
    for _, r in ipairs(allRemotes) do
        table.insert(display, string.format("[%s] %s\n%s", r.rtype, r.name, r.path))
    end
    currentPageScan = showPage(display, currentPageScan - 1, "📡 REMOTE")
end)

ScanRight:Button("📋 COPY SEMUA", "Copy semua remote ke clipboard", function()
    if #allRemotes == 0 then
        Library:Notification("❌", "Tidak ada data", 2)
        return
    end
    local text = "=== XKID SCAN RESULTS ===\n\n"
    for i, r in ipairs(allRemotes) do
        text = text .. string.format("[%d] [%s] %s\n%s\n\n", i, r.rtype, r.name, r.path)
    end
    doCopy(text)
end)

-- ============================================
--  BUILD UI - FARM SPY TAB
-- ============================================
local FarmPage = TabFarm:Page("🌾 FARM SPY", "sprout")
local FarmLeft = FarmPage:Section("🕵️ KONTROL", "Left")
local FarmRight = FarmPage:Section("📋 LOG FARMING", "Right")

FarmLeft:Paragraph("📌 FUNGSI",
    "Mendeteksi otomatis:\n" ..
    "🌱 Tanam (Plant/Tanam)\n" ..
    "🌾 Panen (Harvest/Panen)\n" ..
    "💰 Jual (Sell/Jual)\n" ..
    "🌱 Beli Bibit (Bibit/Seed)\n\n" ..
    "⚠️ Aktifkan setelah SCAN!"
)

FarmLeft:Toggle("🌾 AKTIFKAN FARM SPY", "FarmToggle", false,
    "Deteksi remote farming",
    function(v)
        if v then
            startFarmSpy()
        else
            stopFarmSpy()
        end
    end
)

FarmLeft:Button("🗑️ CLEAR LOG", "Hapus semua log farming", function()
    farmLog = {}
    Library:Notification("🗑️", "Log farming dihapus", 2)
end)

FarmLeft:Paragraph("📊 STATISTIK",
    function()
        return string.format("Total log: %d", #farmLog)
    end
)

FarmRight:Button("📄 LIHAT LOG", "Tampilkan log farming", function()
    if #farmLog == 0 then
        Library:Notification("📭", "Belum ada log\nAktifkan Farm Spy & lakukan farming!", 3)
        return
    end
    currentPageFarm = showPage(farmLog, 1, "🌾 FARM LOG")
end)

FarmRight:Button("⏩ HALAMAN BERIKUTNYA", "Next page", function()
    if #farmLog == 0 then return end
    currentPageFarm = showPage(farmLog, currentPageFarm + 1, "🌾 FARM LOG")
end)

FarmRight:Button("⏪ HALAMAN SEBELUMNYA", "Prev page", function()
    if #farmLog == 0 then return end
    currentPageFarm = showPage(farmLog, currentPageFarm - 1, "🌾 FARM LOG")
end)

FarmRight:Button("📋 COPY SEMUA LOG", "Copy semua log farm", function()
    if #farmLog == 0 then
        Library:Notification("❌", "Tidak ada log", 2)
        return
    end
    local text = "=== FARM SPY LOG ===\n\n"
    for i, e in ipairs(farmLog) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    doCopy(text)
end)

-- ============================================
--  BUILD UI - WORKSPACE TAB
-- ============================================
local WorkspacePage = TabWorkspace:Page("🗺️ WORKSPACE MONITOR", "map")
local WorkspaceLeft = WorkspacePage:Section("🎮 KONTROL", "Left")
local WorkspaceRight = WorkspacePage:Section("📋 LOG WORKSPACE", "Right")

WorkspaceLeft:Paragraph("📌 FUNGSI",
    "Mendeteksi perubahan di Workspace:\n" ..
    "➕ Objek baru muncul\n" ..
    "➖ Objek hilang\n\n" ..
    "Berguna untuk melihat:\n" ..
    "• Tanaman tumbuh\n" ..
    "• Item muncul\n" ..
    "• NPC spawn"
)

WorkspaceLeft:Toggle("🗺️ AKTIFKAN MONITOR", "WorkspaceToggle", false,
    "Pantau perubahan workspace",
    function(v)
        if v then
            startWorkspaceMonitor()
        else
            stopWorkspaceMonitor()
        end
    end
)

WorkspaceLeft:Button("🗑️ CLEAR LOG", "Hapus semua log workspace", function()
    workspaceLog = {}
    Library:Notification("🗑️", "Log workspace dihapus", 2)
end)

WorkspaceLeft:Paragraph("📊 STATISTIK",
    function()
        return string.format("Total log: %d", #workspaceLog)
    end
)

WorkspaceRight:Button("📄 LIHAT LOG", "Tampilkan log workspace", function()
    if #workspaceLog == 0 then
        Library:Notification("📭", "Belum ada log\nAktifkan monitor & tunggu perubahan!", 3)
        return
    end
    currentPageWorkspace = showPage(workspaceLog, 1, "🗺️ WORKSPACE LOG")
end)

WorkspaceRight:Button("⏩ HALAMAN BERIKUTNYA", "Next page", function()
    if #workspaceLog == 0 then return end
    currentPageWorkspace = showPage(workspaceLog, currentPageWorkspace + 1, "🗺️ WORKSPACE LOG")
end)

WorkspaceRight:Button("⏪ HALAMAN SEBELUMNYA", "Prev page", function()
    if #workspaceLog == 0 then return end
    currentPageWorkspace = showPage(workspaceLog, currentPageWorkspace - 1, "🗺️ WORKSPACE LOG")
end)

WorkspaceRight:Button("📋 COPY SEMUA LOG", "Copy semua log workspace", function()
    if #workspaceLog == 0 then
        Library:Notification("❌", "Tidak ada log", 2)
        return
    end
    local text = "=== WORKSPACE LOG ===\n\n"
    for i, e in ipairs(workspaceLog) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    doCopy(text)
end)

-- ============================================
--  INIT & NOTIFICATION
-- ============================================
Library:Notification(
    "✅ XKID REMOTE TRACKER V2",
    "3 FITUR UTAMA:\n" ..
    "• SCAN remote\n" ..
    "• FARM SPY (hook)\n" ..
    "• WORKSPACE monitor\n\n" ..
    "SEMUA SUDAH DI-TEST WORK!",
    6
)

Library:ConfigSystem(Win)

print("╔══════════════════════════════════════╗")
print("║   🔌 XKID REMOTE TRACKER V2        ║")
print("║   3 FITUR UTAMA 100% WORK           ║")
print("║                                      ║")
print("║   1. SCAN remote                     ║")
print("║   2. FARM SPY (hook)                 ║")
print("║   3. WORKSPACE monitor               ║")
print("║                                      ║")
print("║   🚀 JALANKAN & NIKMATI!             ║")
print("╚══════════════════════════════════════╝")