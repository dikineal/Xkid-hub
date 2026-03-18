--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   U L T I M A T E   V 8            ║
  ║          5 FITUR BARU - LENGKAP!                     ║
  ╚═══════════════════════════════════════════════════════╝

  🔥 FITUR BARU V8:
  [1] REMOTE USAGE TRACKER - Hitung frekuensi remote
  [2] REMOTE PARAMETER DETECTOR - Deteksi parameter yang dibutuhkan
  [3] OBJECT FINDER OTOMATIS - Cari objek berdasarkan keyword
  [4] TELEPORT TOOL - Teleport ke koordinat atau objek
  [5] ANTI SPAM LOG - Filter log biar gak penuh
]]

-- ============================================
--  LOAD UI
-- ============================================
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Win = Library:Window(
    "🔌 XKID ULTIMATE V8",
    "cpu",
    "5 Fitur Baru - Lengkap!",
    false
)

-- ============================================
--  SERVICES
-- ============================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- ============================================
--  TABS (9 TABS!)
-- ============================================
local TabRemote    = Win:Tab("📡 REMOTE", "radio")
local TabUsage     = Win:Tab("📊 USAGE", "bar-chart-2")
local TabParam     = Win:Tab("🔍 PARAM", "search")
local TabObjek     = Win:Tab("🎯 FINDER", "target")
local TabTeleport  = Win:Tab("🚀 TELEPORT", "map-pin")
local TabMove      = Win:Tab("🚶 MOVE", "activity")
local TabFarm      = Win:Tab("🌾 FARM", "sprout")
local TabAll       = Win:Tab("📋 ALL LOG", "file-text")
local TabSetting   = Win:Tab("⚙️ SETTING", "settings")

-- ============================================
--  GLOBAL STATE
-- ============================================
-- Logs
local allLogs = {}
local remoteLog = {}
local moveLog = {}
local farmLog = {}

-- [1] REMOTE USAGE TRACKER
local remoteUsage = {}
local totalRemoteCalls = 0

-- [2] REMOTE PARAMETER DETECTOR
local remoteParams = {}

-- [5] ANTI SPAM LOG
local spamFilter = {
    enabled = false,
    keywords = {},
    minInterval = 1,  -- detik
    lastLog = {}
}

-- Trackers status
local remoteActive = false
local moveActive = false
local farmActive = false

-- Connections
local hook = nil
local moveConn = nil

-- UI Pages
local remotePage = 1
local usagePage = 1
local paramPage = 1
local objekPage = 1
local movePage = 1
local farmPage = 1
local allPage = 1
local PAGE_SIZE = 10
local MAX_LOG = 200

-- Farming keywords
local FARM_KEYWORDS = {
    "plant", "tanam", "harvest", "panen", "sell", "jual",
    "bibit", "seed", "crop", "lahan", "field"
}

-- ============================================
--  UTILITY FUNCTIONS
-- ============================================
local function copyToClipboard(text)
    local success = pcall(function() setclipboard(text) end)
    Library:Notification(
        success and "✅ Copied!" or "❌ Gagal",
        success and "Berhasil copy" or "Gagal copy",
        2
    )
end

local function serializeArg(arg)
    local t = typeof(arg)
    if t == "string" then
        if #arg > 30 then return '"'..arg:sub(1,20)..'..."' end
        return '"'..arg..'"'
    elseif t == "number" then
        return tostring(arg)
    elseif t == "boolean" then
        return tostring(arg)
    elseif t == "Vector3" then
        return string.format("V3(%.1f,%.1f,%.1f)", arg.X, arg.Y, arg.Z)
    elseif t == "Instance" then
        return "["..arg.Name.."]"
    else
        return "["..t.."]"
    end
end

local function formatArgs(args)
    local parts = {}
    for i, a in ipairs(args) do
        table.insert(parts, string.format("[%d]=%s", i, serializeArg(a)))
    end
    return table.concat(parts, " ")
end

local function getArgTypes(args)
    local types = {}
    for i, a in ipairs(args) do
        table.insert(types, typeof(a))
    end
    return table.concat(types, ", ")
end

-- [5] ANTI SPAM LOG
local function shouldLog(entry)
    if not spamFilter.enabled then return true end
    
    -- Filter berdasarkan keyword
    if #spamFilter.keywords > 0 then
        local match = false
        for _, kw in ipairs(spamFilter.keywords) do
            if entry:lower():find(kw:lower()) then
                match = true
                break
            end
        end
        if not match then return false end
    end
    
    -- Filter berdasarkan interval
    local now = tick()
    if spamFilter.lastLog[entry] and now - spamFilter.lastLog[entry] < spamFilter.minInterval then
        return false
    end
    spamFilter.lastLog[entry] = now
    
    return true
end

local function addLog(logTable, entry)
    if not shouldLog(entry) then return end
    
    table.insert(logTable, 1, entry)
    table.insert(allLogs, 1, entry)
    
    -- Batasi ukuran log
    if #logTable > MAX_LOG then 
        for i = MAX_LOG + 1, #logTable do
            logTable[i] = nil
        end
    end
    if #allLogs > MAX_LOG * 2 then 
        for i = MAX_LOG * 2 + 1, #allLogs do
            allLogs[i] = nil
        end
    end
end

local function showPage(log, page, title)
    if #log == 0 then
        Library:Notification("📭", "Belum ada data", 2)
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
--  MAIN HOOK - UNTUK SEMUA REMOTE FEATURES
-- ============================================
local function setupHook()
    if hook then return end
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "FireServer" or method == "InvokeServer" then
            local isRemote = false
            local remoteName = "?"
            local remotePath = "?"
            
            pcall(function()
                if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                    isRemote = true
                    remoteName = self.Name
                    remotePath = self:GetFullName()
                end
            end)
            
            if isRemote then
                totalRemoteCalls = totalRemoteCalls + 1
                
                -- [1] REMOTE USAGE TRACKER
                if not remoteUsage[remoteName] then
                    remoteUsage[remoteName] = {
                        count = 0,
                        lastCall = os.date("%H:%M:%S"),
                        methods = {}
                    }
                end
                remoteUsage[remoteName].count = remoteUsage[remoteName].count + 1
                remoteUsage[remoteName].lastCall = os.date("%H:%M:%S")
                remoteUsage[remoteName].methods[method] = (remoteUsage[remoteName].methods[method] or 0) + 1
                
                -- [2] REMOTE PARAMETER DETECTOR
                if not remoteParams[remoteName] then
                    remoteParams[remoteName] = {
                        argCount = #args,
                        argTypes = getArgTypes(args),
                        sample = formatArgs(args)
                    }
                end
                
                -- REMOTE SPY
                if remoteActive then
                    local entry = string.format(
                        "[%s] 📡 %s\n📦 %s",
                        os.date("%H:%M:%S"),
                        remoteName,
                        formatArgs(args)
                    )
                    addLog(remoteLog, entry)
                end
                
                -- FARM DETECT
                if farmActive then
                    local nameLower = remoteName:lower()
                    for _, kw in ipairs(FARM_KEYWORDS) do
                        if nameLower:find(kw) then
                            local farmingType = "🌾 FARM"
                            if nameLower:find("plant") then farmingType = "🌱 TANAM"
                            elseif nameLower:find("harvest") then farmingType = "🌾 PANEN"
                            elseif nameLower:find("sell") then farmingType = "💰 JUAL"
                            elseif nameLower:find("bibit") then farmingType = "🌱 BELI"
                            end
                            
                            local entry = string.format(
                                "[%s] %s %s\n📦 %s",
                                os.date("%H:%M:%S"),
                                farmingType,
                                remoteName,
                                formatArgs(args)
                            )
                            addLog(farmLog, entry)
                            break
                        end
                    end
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)
    
    hook = oldNamecall
end

-- ============================================
--  REMOTE SPY
-- ============================================
local function startRemote()
    if remoteActive then return end
    setupHook()
    remoteActive = true
    remoteLog = {}
    Library:Notification("📡 REMOTE SPY", "Aktif!", 2)
end

local function stopRemote()
    remoteActive = false
    Library:Notification("📡 REMOTE SPY", "Dimatikan", 2)
end

-- ============================================
--  FARM DETECT
-- ============================================
local function startFarm()
    if farmActive then return end
    setupHook()
    farmActive = true
    farmLog = {}
    Library:Notification("🌾 FARM DETECT", "Aktif!", 2)
end

local function stopFarm()
    farmActive = false
    Library:Notification("🌾 FARM DETECT", "Dimatikan", 2)
end

-- ============================================
--  MOVE TRACKER
-- ============================================
local function startMove()
    if moveActive then return end
    
    moveLog = {}
    local lastPos = nil
    
    moveConn = RunService.Heartbeat:Connect(function()
        local char = LP.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local currentPos = hrp.Position
        
        if lastPos and (currentPos - lastPos).Magnitude > 2 then
            local entry = string.format(
                "[%s] 🚶 MOVE\n📍 (%.1f,%.1f,%.1f)",
                os.date("%H:%M:%S"),
                currentPos.X, currentPos.Y, currentPos.Z
            )
            addLog(moveLog, entry)
        end
        lastPos = currentPos
    end)
    
    moveActive = true
    Library:Notification("🚶 MOVE TRACKER", "Aktif!", 2)
end

local function stopMove()
    if moveConn then
        moveConn:Disconnect()
        moveConn = nil
    end
    moveActive = false
    Library:Notification("🚶 MOVE TRACKER", "Dimatikan", 2)
end

-- ============================================
--  [3] OBJECT FINDER OTOMATIS
-- ============================================
local function findObjects(keyword)
    local results = {}
    local count = 0
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            if obj.Name:lower():find(keyword:lower()) then
                count = count + 1
                local pos = obj:IsA("BasePart") and obj.Position or 
                           (obj:IsA("Model") and obj:GetPrimaryPartCFrame() and obj:GetPrimaryPartCFrame().Position)
                
                local entry = string.format(
                    "[%d] 📦 %s\n📍 %s\n🏷️ %s",
                    count,
                    obj.Name,
                    pos and string.format("(%.1f,%.1f,%.1f)", pos.X, pos.Y, pos.Z) or "?",
                    obj.ClassName
                )
                table.insert(results, entry)
            end
        end
    end
    
    return results, count
end

-- ============================================
--  [4] TELEPORT TOOL
-- ============================================
local function teleportTo(pos)
    local char = LP.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    hrp.CFrame = CFrame.new(pos)
    return true
end

local function teleportToObject(objName)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find(objName:lower()) then
            local pos = obj:IsA("BasePart") and obj.Position or 
                       (obj:IsA("Model") and obj:GetPrimaryPartCFrame() and obj:GetPrimaryPartCFrame().Position)
            if pos then
                teleportTo(pos)
                return true, obj.Name, pos
            end
        end
    end
    return false
end

-- ============================================
--  STOP ALL
-- ============================================
local function stopAll()
    stopRemote()
    stopFarm()
    stopMove()
    Library:Notification("⏹️", "Semua tracker dimatikan", 3)
end

-- ============================================
--  BUILD UI - REMOTE TAB
-- ============================================
local RemotePage = TabRemote:Page("📡 REMOTE SPY", "radio")
local RemoteLeft = RemotePage:Section("Kontrol", "Left")
local RemoteRight = RemotePage:Section("Log", "Right")

RemoteLeft:Toggle("Aktifkan", "RemoteToggle", false,
    "Track semua remote",
    function(v)
        if v then startRemote() else stopRemote() end
    end)

RemoteLeft:Button("Clear", "Hapus log", function()
    remoteLog = {}
    Library:Notification("🗑️", "Log remote dihapus", 2)
end)

RemoteRight:Button("Lihat", "Tampilkan log", function()
    remotePage = showPage(remoteLog, 1, "📡 REMOTE LOG")
end)

RemoteRight:Button("Next", "Halaman berikutnya", function()
    remotePage = showPage(remoteLog, remotePage + 1, "📡 REMOTE LOG")
end)

RemoteRight:Button("Prev", "Halaman sebelumnya", function()
    remotePage = showPage(remoteLog, remotePage - 1, "📡 REMOTE LOG")
end)

RemoteRight:Button("Copy", "Copy ke clipboard", function()
    if #remoteLog == 0 then return end
    copyToClipboard(table.concat(remoteLog, "\n\n"))
end)

-- ============================================
--  BUILD UI - USAGE TAB [1]
-- ============================================
local UsagePage = TabUsage:Page("📊 REMOTE USAGE", "bar-chart-2")
local UsageLeft = UsagePage:Section("Statistik", "Left")
local UsageRight = UsagePage:Section("Detail", "Right")

UsageLeft:Paragraph("Total Calls",
    function()
        return "Total: " .. totalRemoteCalls .. " remote calls"
    end
)

UsageLeft:Button("Refresh", "Update tampilan", function()
    local text = "📊 REMOTE USAGE:\n\n"
    local sorted = {}
    for name, data in pairs(remoteUsage) do
        table.insert(sorted, {name = name, count = data.count})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    for i = 1, math.min(15, #sorted) do
        text = text .. string.format("%d. %s: %dx\n", i, sorted[i].name, sorted[i].count)
    end
    
    Library:Notification("📊 USAGE", text, 10)
end)

UsageLeft:Button("Reset", "Reset statistik", function()
    remoteUsage = {}
    totalRemoteCalls = 0
    Library:Notification("🔄", "Statistik direset", 2)
end)

UsageRight:Button("Lihat Detail", "Detail per remote", function()
    local text = "📊 DETAIL USAGE:\n\n"
    for name, data in pairs(remoteUsage) do
        text = text .. string.format("%s: %dx\n", name, data.count)
        for method, count in pairs(data.methods) do
            text = text .. string.format("  └ %s: %dx\n", method, count)
        end
        text = text .. "\n"
    end
    Library:Notification("📊 DETAIL", text, 15)
end)

-- ============================================
--  BUILD UI - PARAM TAB [2]
-- ============================================
local ParamPage = TabParam:Page("🔍 PARAM DETECTOR", "search")
local ParamLeft = ParamPage:Section("Detected", "Left")
local ParamRight = ParamPage:Section("Info", "Right")

ParamLeft:Button("Scan Parameters", "Deteksi parameter remote", function()
    local text = "🔍 PARAMETER DETECTOR:\n\n"
    for name, data in pairs(remoteParams) do
        text = text .. string.format("%s:\n", name)
        text = text .. string.format("  └ Arg Count: %d\n", data.argCount)
        text = text .. string.format("  └ Arg Types: %s\n", data.argTypes)
        text = text .. string.format("  └ Sample: %s\n\n", data.sample)
    end
    Library:Notification("🔍 PARAM", text, 15)
end)

ParamLeft:Button("Reset", "Reset data", function()
    remoteParams = {}
    Library:Notification("🔄", "Data parameter direset", 2)
end)

ParamRight:Paragraph("Cara Kerja",
    "Mendeteksi otomatis:\n" ..
    "• Jumlah argumen\n" ..
    "• Tipe data argumen\n" ..
    "• Contoh nilai\n\n" ..
    "Berguna untuk:\n" ..
    "• Membuat script auto farm\n" ..
    "• Memahami struktur remote"
)

-- ============================================
--  BUILD UI - OBJEK FINDER TAB [3]
-- ============================================
local ObjekPage = TabObjek:Page("🎯 OBJECT FINDER", "target")
local ObjekLeft = ObjekPage:Section("Cari Objek", "Left")
local ObjekRight = ObjekPage:Section("Hasil", "Right")

local searchKeyword = ""

ObjekLeft:TextBox("Keyword", "SearchBox", "",
    function(v) searchKeyword = v end,
    "Contoh: padi, wheat, tree"
)

ObjekLeft:Button("Cari", "Cari objek", function()
    if searchKeyword == "" then
        Library:Notification("❌", "Masukkan keyword!", 2)
        return
    end
    
    local results, count = findObjects(searchKeyword)
    local text = "🎯 HASIL PENCARIAN:\n\n" .. table.concat(results, "\n\n")
    Library:Notification("🎯 " .. count .. " Objek", text, 15)
end)

ObjekLeft:Button("Scan Semua", "Scan semua objek", function()
    local results, count = findObjects("")
    local text = "🎯 SEMUA OBJEK:\n\n" .. table.concat(results, "\n\n")
    Library:Notification("🎯 " .. count .. " Objek", text, 15)
end)

-- ============================================
--  BUILD UI - TELEPORT TAB [4]
-- ============================================
local TeleportPage = TabTeleport:Page("🚀 TELEPORT TOOL", "map-pin")
local TeleportLeft = TeleportPage:Section("Ke Koordinat", "Left")
local TeleportRight = TeleportPage:Section("Ke Objek", "Right")

local tpX, tpY, tpZ = 0, 0, 0

TeleportLeft:TextBox("X", "TPX", "0", function(v) tpX = tonumber(v) or 0 end)
TeleportLeft:TextBox("Y", "TPY", "0", function(v) tpY = tonumber(v) or 0 end)
TeleportLeft:TextBox("Z", "TPZ", "0", function(v) tpZ = tonumber(v) or 0 end)

TeleportLeft:Button("Teleport", "Ke koordinat", function()
    local success = teleportTo(Vector3.new(tpX, tpY, tpZ))
    Library:Notification(
        success and "✅ Berhasil" or "❌ Gagal",
        string.format("Ke (%.1f, %.1f, %.1f)", tpX, tpY, tpZ),
        3
    )
end)

TeleportLeft:Button("Ke Spawn", "Teleport ke spawn", function()
    local spawn = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn")
    if spawn then
        teleportTo(spawn.Position)
        Library:Notification("✅", "Ke spawn", 2)
    end
end)

local tpObjKeyword = ""

TeleportRight:TextBox("Nama Objek", "TPObj", "",
    function(v) tpObjKeyword = v end,
    "Contoh: Wheat, Tree"
)

TeleportRight:Button("Cari & TP", "Teleport ke objek", function()
    if tpObjKeyword == "" then
        Library:Notification("❌", "Masukkan nama objek!", 2)
        return
    end
    
    local success, name, pos = teleportToObject(tpObjKeyword)
    if success then
        Library:Notification("✅ Berhasil", string.format("Ke %s\n(%.1f,%.1f,%.1f)", name, pos.X, pos.Y, pos.Z), 4)
    else
        Library:Notification("❌ Gagal", "Objek '" .. tpObjKeyword .. "' tidak ditemukan", 3)
    end
end)

-- ============================================
--  BUILD UI - MOVE TAB
-- ============================================
local MovePage = TabMove:Page("🚶 MOVE", "activity")
local MoveLeft = MovePage:Section("Kontrol", "Left")
local MoveRight = MovePage:Section("Log", "Right")

MoveLeft:Toggle("Aktifkan", "MoveToggle", false,
    "Track pergerakan player",
    function(v)
        if v then startMove() else stopMove() end
    end)

MoveLeft:Button("Clear", "Hapus log", function()
    moveLog = {}
    Library:Notification("🗑️", "Log move dihapus", 2)
end)

MoveRight:Button("Lihat", "Tampilkan log", function()
    movePage = showPage(moveLog, 1, "🚶 MOVE LOG")
end)

MoveRight:Button("Next", "Halaman berikutnya", function()
    movePage = showPage(moveLog, movePage + 1, "🚶 MOVE LOG")
end)

MoveRight:Button("Prev", "Halaman sebelumnya", function()
    movePage = showPage(moveLog, movePage - 1, "🚶 MOVE LOG")
end)

MoveRight:Button("Copy", "Copy ke clipboard", function()
    if #moveLog == 0 then return end
    copyToClipboard(table.concat(moveLog, "\n\n"))
end)

-- ============================================
--  BUILD UI - FARM TAB
-- ============================================
local FarmPage = TabFarm:Page("🌾 FARM", "sprout")
local FarmLeft = FarmPage:Section("Kontrol", "Left")
local FarmRight = FarmPage:Section("Log", "Right")

FarmLeft:Toggle("Aktifkan", "FarmToggle", false,
    "Deteksi remote farming",
    function(v)
        if v then startFarm() else stopFarm() end
    end)

FarmLeft:Button("Clear", "Hapus log", function()
    farmLog = {}
    Library:Notification("🗑️", "Log farm dihapus", 2)
end)

FarmRight:Button("Lihat", "Tampilkan log", function()
    farmPage = showPage(farmLog, 1, "🌾 FARM LOG")
end)

FarmRight:Button("Next", "Halaman berikutnya", function()
    farmPage = showPage(farmLog, farmPage + 1, "🌾 FARM LOG")
end)

FarmRight:Button("Prev", "Halaman sebelumnya", function()
    farmPage = showPage(farmLog, farmPage - 1, "🌾 FARM LOG")
end)

FarmRight:Button("Copy", "Copy ke clipboard", function()
    if #farmLog == 0 then return end
    copyToClipboard(table.concat(farmLog, "\n\n"))
end)

-- ============================================
--  BUILD UI - ALL LOG TAB
-- ============================================
local AllPage = TabAll:Page("📋 ALL LOG", "file-text")
local AllLeft = AllPage:Section("Kontrol", "Left")
local AllRight = AllPage:Section("Log", "Right")

AllLeft:Button("Stop All", "Matikan semua", function()
    stopAll()
end)

AllLeft:Button("Clear All", "Hapus semua log", function()
    remoteLog = {}
    moveLog = {}
    farmLog = {}
    allLogs = {}
    Library:Notification("🗑️", "Semua log dihapus", 2)
end)

AllRight:Button("Lihat", "Tampilkan semua log", function()
    allPage = showPage(allLogs, 1, "📋 ALL LOG")
end)

AllRight:Button("Next", "Halaman berikutnya", function()
    allPage = showPage(allLogs, allPage + 1, "📋 ALL LOG")
end)

AllRight:Button("Prev", "Halaman sebelumnya", function()
    allPage = showPage(allLogs, allPage - 1, "📋 ALL LOG")
end)

AllRight:Button("Copy All", "Copy semua log", function()
    if #allLogs == 0 then return end
    copyToClipboard(table.concat(allLogs, "\n\n"))
end)

-- ============================================
--  BUILD UI - SETTING TAB [5]
-- ============================================
local SettingPage = TabSetting:Page("⚙️ ANTI SPAM", "settings")
local SettingLeft = SettingPage:Section("Filter", "Left")
local SettingRight = SettingPage:Section("Info", "Right")

SettingLeft:Toggle("Aktifkan Anti Spam", "SpamToggle", false,
    "Filter log berulang",
    function(v)
        spamFilter.enabled = v
        Library:Notification("🛡️", v and "Anti spam ON" or "Anti spam OFF", 2)
    end)

SettingLeft:Slider("Min Interval (detik)", "IntervalSlider", 0.5, 5, 1,
    function(v) spamFilter.minInterval = v end)

SettingLeft:TextBox("Keyword Filter", "KeywordBox", "",
    function(v)
        spamFilter.keywords = {}
        for kw in v:gmatch("[^,]+") do
            table.insert(spamFilter.keywords, kw:match("^%s*(.-)%s*$"))
        end
    end,
    "Pisah dengan koma. Contoh: plant, harvest"
)

SettingLeft:Button("Reset Filter", "Hapus semua filter", function()
    spamFilter.keywords = {}
    spamFilter.lastLog = {}
    Library:Notification("🔄", "Filter direset", 2)
end)

SettingRight:Paragraph("Cara Kerja",
    "Anti spam akan:\n" ..
    "• Mencegah log yang sama dalam interval tertentu\n" ..
    "• Hanya mencatat log dengan keyword tertentu\n\n" ..
    "Contoh keyword:\n" ..
    "plant, harvest, sell\n\n" ..
    "Interval minimum:\n" ..
    "0.5s = sangat ketat\n" ..
    "5s = sangat longgar"
)

-- ============================================
--  INIT
-- ============================================
Library:Notification(
    "🚀 XKID ULTIMATE V8",
    "✅ 5 FITUR BARU:\n" ..
    "[1] Remote Usage Tracker\n" ..
    "[2] Remote Parameter Detector\n" ..
    "[3] Object Finder Otomatis\n" ..
    "[4] Teleport Tool\n" ..
    "[5] Anti Spam Log\n\n" ..
    "🔥 TOTAL 9 TABS!",
    8
)

Library:ConfigSystem(Win)

print("╔═══════════════════════════════════════════════════════╗")
print("║                                                       ║")
print("║      🔌 XKID ULTIMATE V8                             ║")
print("║          5 FITUR BARU - LENGKAP!                      ║")
print("║                                                       ║")
print("║  ✅ FITUR BARU:                                       ║")
print("║  [1] REMOTE USAGE TRACKER                            ║")
print("║  [2] REMOTE PARAMETER DETECTOR                       ║")
print("║  [3] OBJECT FINDER OTOMATIS                          ║")
print("║  [4] TELEPORT TOOL                                   ║")
print("║  [5] ANTI SPAM LOG                                   ║")
print("║                                                       ║")
print("║  📋 TOTAL 9 TABS!                                     ║")
print("║                                                       ║")
print("║  🚀 CARA PAKAI:                                       ║")
print("║  1. Aktifkan tracker yang diinginkan                 ║")
print("║  2. Gunakan fitur baru di tab masing-masing          ║")
print("║  3. Atur anti spam di tab SETTING                    ║")
print("║                                                       ║")
print("╚═══════════════════════════════════════════════════════╝")