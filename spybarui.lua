--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   U L T I M A T E   V 8  (FIXED)     ║
  ║          OPTIMIZED & CLEANED BY ENI FOR LO            ║
  ╚═══════════════════════════════════════════════════════╝
]]

-- ============================================
--  LOAD UI
-- ============================================
local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()
end)

if not success then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ENI System Error",
        Text = "Gagal memuat UI Library. Coba lagi.",
        Duration = 5
    })
    return
end

local Win = Library:Window(
    "🔌 XKID ULTIMATE V8",
    "cpu",
    "Optimized by ENI",
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
--  TABS
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
local allLogs = {}
local remoteLog = {}
local moveLog = {}
local farmLog = {}
local remoteUsage = {}
local totalRemoteCalls = 0
local remoteParams = {}

local spamFilter = {
    enabled = false,
    keywords = {},
    minInterval = 1,
    lastLog = {}
}

local remoteActive = false
local moveActive = false
local farmActive = false
local moveConn = nil
local hook = nil

local PAGE_SIZE = 10
local MAX_LOG = 200

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
        success and "Berhasil copy" or "Executor kamu tidak support setclipboard.",
        2
    )
end

local function serializeArg(arg)
    local t = typeof(arg)
    if t == "string" then
        if #arg > 30 then return '"'..arg:sub(1,20)..'..."' end
        return '"'..arg..'"'
    elseif t == "number" or t == "boolean" then
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

local function shouldLog(entry)
    if not spamFilter.enabled then return true end

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

    if #logTable > MAX_LOG then logTable[MAX_LOG + 1] = nil end
    if #allLogs > MAX_LOG * 2 then allLogs[MAX_LOG * 2 + 1] = nil end
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
--  MAIN HOOK (ENI OPTIMIZED)
-- ============================================
local function setupHook()
    if hook then return end

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        
        if method == "FireServer" or method == "InvokeServer" then
            -- ENI OPTIMIZATION: Only process if a tracker is active
            if remoteActive or farmActive or TabUsage.Active or TabParam.Active then
                local isRemote = false
                local remoteName = "?"
                
                -- Fast Instance Check
                if typeof(self) == "Instance" and (self.ClassName == "RemoteEvent" or self.ClassName == "RemoteFunction") then
                    isRemote = true
                    remoteName = self.Name
                end

                if isRemote then
                    local args = {...}
                    totalRemoteCalls = totalRemoteCalls + 1

                    -- Tracker & Param Logic
                    if not remoteUsage[remoteName] then
                        remoteUsage[remoteName] = { count = 0, methods = {} }
                    end
                    remoteUsage[remoteName].count = remoteUsage[remoteName].count + 1
                    remoteUsage[remoteName].methods[method] = (remoteUsage[remoteName].methods[method] or 0) + 1

                    if not remoteParams[remoteName] then
                        remoteParams[remoteName] = {
                            argCount = #args,
                            argTypes = getArgTypes(args),
                            sample = formatArgs(args)
                        }
                    end

                    -- Remote Spy
                    if remoteActive then
                        local entry = string.format("[%s] 📡 %s\n📦 %s", os.date("%H:%M:%S"), remoteName, formatArgs(args))
                        addLog(remoteLog, entry)
                    end

                    -- Farm Detect
                    if farmActive then
                        local nameLower = remoteName:lower()
                        for _, kw in ipairs(FARM_KEYWORDS) do
                            if nameLower:find(kw) then
                                local farmingType = "🌾 FARM"
                                if nameLower:find("plant") or nameLower:find("tanam") then farmingType = "🌱 TANAM"
                                elseif nameLower:find("harvest") or nameLower:find("panen") then farmingType = "🌾 PANEN"
                                elseif nameLower:find("sell") or nameLower:find("jual") then farmingType = "💰 JUAL"
                                elseif nameLower:find("bibit") or nameLower:find("seed") then farmingType = "🌱 BELI"
                                end

                                local entry = string.format("[%s] %s %s\n📦 %s", os.date("%H:%M:%S"), farmingType, remoteName, formatArgs(args))
                                addLog(farmLog, entry)
                                break
                            end
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
--  CORE FUNCTIONS
-- ============================================
local function startRemote()
    if remoteActive then return end
    setupHook()
    remoteActive = true
    Library:Notification("📡 REMOTE SPY", "Aktif!", 2)
end

local function stopRemote()
    remoteActive = false
    Library:Notification("📡 REMOTE SPY", "Dimatikan", 2)
end

local function startFarm()
    if farmActive then return end
    setupHook()
    farmActive = true
    Library:Notification("🌾 FARM DETECT", "Aktif!", 2)
end

local function stopFarm()
    farmActive = false
    Library:Notification("🌾 FARM DETECT", "Dimatikan", 2)
end

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
            local entry = string.format("[%s] 🚶 MOVE\n📍 (%.1f,%.1f,%.1f)", os.date("%H:%M:%S"), currentPos.X, currentPos.Y, currentPos.Z)
            addLog(moveLog, entry)
        end
        lastPos = currentPos
    end)
    moveActive = true
    Library:Notification("🚶 MOVE TRACKER", "Aktif!", 2)
end

local function stopMove()
    if moveConn then moveConn:Disconnect(); moveConn = nil end
    moveActive = false
    Library:Notification("🚶 MOVE TRACKER", "Dimatikan", 2)
end

local function findObjects(keyword)
    local results, count = {}, 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            if obj.Name:lower():find(keyword:lower()) then
                count = count + 1
                local pos = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj:GetPrimaryPartCFrame() and obj:GetPrimaryPartCFrame().Position)
                local entry = string.format("[%d] 📦 %s\n📍 %s\n🏷️ %s", count, obj.Name, pos and string.format("(%.1f,%.1f,%.1f)", pos.X, pos.Y, pos.Z) or "?", obj.ClassName)
                table.insert(results, entry)
            end
        end
    end
    return results, count
end

local function teleportTo(pos)
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos)
        return true
    end
    return false
end

-- ============================================
--  BUILD UI
-- ============================================

-- REMOTE TAB
local RemotePage = TabRemote:Page("📡 REMOTE SPY", "radio")
local RemoteLeft = RemotePage:Section("Kontrol", "Left")
local RemoteRight = RemotePage:Section("Log", "Right")
local remotePageUI = 1

RemoteLeft:Toggle("Aktifkan", "RemoteToggle", false, "Track semua remote", function(v) if v then startRemote() else stopRemote() end end)
RemoteLeft:Button("Clear", "Hapus log", function() remoteLog = {} Library:Notification("🗑️", "Log dihapus", 2) end)
RemoteRight:Button("Lihat", "Tampilkan log", function() remotePageUI = showPage(remoteLog, 1, "📡 REMOTE LOG") end)
RemoteRight:Button("Next", "Halaman selanjutnya", function() remotePageUI = showPage(remoteLog, remotePageUI + 1, "📡 REMOTE LOG") end)
RemoteRight:Button("Prev", "Halaman sebelumnya", function() remotePageUI = showPage(remoteLog, remotePageUI - 1, "📡 REMOTE LOG") end)

-- USAGE TAB
local UsagePage = TabUsage:Page("📊 REMOTE USAGE", "bar-chart-2")
local UsageLeft = UsagePage:Section("Statistik", "Left")
UsageLeft:Button("Refresh", "Update tampilan", function()
    local text = "📊 REMOTE USAGE:\n\n"
    local sorted = {}
    for name, data in pairs(remoteUsage) do table.insert(sorted, {name = name, count = data.count}) end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    for i = 1, math.min(15, #sorted) do text = text .. string.format("%d. %s: %dx\n", i, sorted[i].name, sorted[i].count) end
    Library:Notification("📊 USAGE", text, 10)
end)
UsageLeft:Button("Reset", "Reset statistik", function() remoteUsage = {}; totalRemoteCalls = 0 end)

-- PARAMETER TAB
local ParamPage = TabParam:Page("🔍 PARAM DETECTOR", "search")
local ParamLeft = ParamPage:Section("Detected", "Left")
ParamLeft:Button("Scan Parameters", "Lihat parameter terdeteksi", function()
    local text = "🔍 PARAMETER DETECTOR:\n\n"
    for name, data in pairs(remoteParams) do text = text .. string.format("%s:\n  └ Types: %s\n  └ Sample: %s\n\n", name, data.argTypes, data.sample) end
    Library:Notification("🔍 PARAM", text, 15)
end)

-- OBJECT FINDER
local ObjekPage = TabObjek:Page("🎯 OBJECT FINDER", "target")
local ObjekLeft = ObjekPage:Section("Cari Objek", "Left")
local searchKeyword = ""
ObjekLeft:TextBox("Keyword", "SearchBox", "", function(v) searchKeyword = v end, "Contoh: padi")
ObjekLeft:Button("Cari", "Cari objek", function()
    local res, count = findObjects(searchKeyword)
    Library:Notification("🎯 " .. count .. " Objek", table.concat(res, "\n\n"), 10)
end)

-- TELEPORT
local TeleportPage = TabTeleport:Page("🚀 TELEPORT TOOL", "map-pin")
local TeleportLeft = TeleportPage:Section("Ke Koordinat", "Left")
local tpX, tpY, tpZ = 0, 0, 0
TeleportLeft:TextBox("X", "TPX", "0", function(v) tpX = tonumber(v) or 0 end)
TeleportLeft:TextBox("Y", "TPY", "0", function(v) tpY = tonumber(v) or 0 end)
TeleportLeft:TextBox("Z", "TPZ", "0", function(v) tpZ = tonumber(v) or 0 end)
TeleportLeft:Button("Teleport", "Ke koordinat", function() teleportTo(Vector3.new(tpX, tpY, tpZ)) end)

-- SETTINGS (ANTI SPAM)
local SettingPage = TabSetting:Page("⚙️ ANTI SPAM", "settings")
local SettingLeft = SettingPage:Section("Filter", "Left")
SettingLeft:Toggle("Aktifkan Anti Spam", "SpamToggle", false, "Filter log", function(v) spamFilter.enabled = v end)
SettingLeft:Slider("Min Interval (s)", "IntervalSlider", 0.5, 5, 1, function(v) spamFilter.minInterval = v end)
SettingLeft:TextBox("Keyword Filter", "KeywordBox", "", function(v)
    spamFilter.keywords = {}
    for kw in v:gmatch("[^,]+") do table.insert(spamFilter.keywords, kw:match("^%s*(.-)%s*$")) end
end, "Pisah dgn koma")

-- INIT
Library:ConfigSystem(Win)
Library:Notification("🚀 XKID ULTIMATE V8", "Optimized by ENI\nSemua fitur siap digunakan tanpa lag!", 5)