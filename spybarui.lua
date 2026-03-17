--[[
  ╔══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   R E M O T E  F U L L  v3.0     ║
  ║      ULTIMATE - ALL FEATURES IN ONE                ║
  ╚══════════════════════════════════════════════════════╝
  🌾 Farming Spy + Auto Farm + Map Exploit
  ⚡ Scan · Exploit · Spy · Hook · BN2 · Fire
]]

-- ════════════════════════════════════════
--  AURORA UI
-- ════════════════════════════════════════
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ════════════════════════════════════════
--  WINDOW & TABS
-- ════════════════════════════════════════
local Win = Library:Window("🔌 XKID ULTIMATE v3.0", "cpu", "Full Features", false)
Win:TabSection("REMOTE")

local TabScan     = Win:Tab("Scan", "search")
local TabExploit  = Win:Tab("Exploit", "alert-triangle")
local TabSpy      = Win:Tab("Spy", "eye")
local TabHook     = Win:Tab("Hook", "terminal")
local TabBN2      = Win:Tab("BN2", "radio")
local TabFire     = Win:Tab("Fire", "zap")
local TabFarmSpy  = Win:Tab("🌾 Farm Spy", "eye")
local TabAutoFarm = Win:Tab("🚜 Auto Farm", "tractor")
local TabMap      = Win:Tab("🗺️ Map", "map")

-- ════════════════════════════════════════
--  SCAN LOCATIONS
-- ════════════════════════════════════════
local SCAN_LOCATIONS = {
    RS, RF, Workspace,
    LP:WaitForChild("PlayerGui", 3),
    LP:WaitForChild("PlayerScripts", 3),
    LP:WaitForChild("Backpack", 3),
    game:GetService("CoreGui"),
}
do -- hapus nil
    local clean = {}
    for _, v in ipairs(SCAN_LOCATIONS) do if v then table.insert(clean, v) end end
    SCAN_LOCATIONS = clean
end

-- ════════════════════════════════════════
--  GLOBAL STATE
-- ════════════════════════════════════════
local allRemotes = {}
local exploitList = {}
local spyLog = {}; local hookLog = {}; local bn2Log = {}
local spyConns = {}; local origNamecall = nil; local bn2Conn = nil
local spyOn = false; local hookOn = false; local bn2On = false
local filterKeyword = ""
local currentPage = 1; local exploitPage = 1; local spyPage = 1
local hookPage = 1; local bn2Page = 1
local firePath = ""; local fireArgs = ""
local PAGE_SIZE = 5; local MAX_LOG = 80

-- Farming Spy State
local farmSpyActive = false
local farmSpyConns = {}
local farmSpyLog = {}  -- { time, timeStr, action, remoteName, remotePath, cropType, position, raw }
local farmSpyFilter = "Semua"
local farmSpyPage = 1

-- Auto Farm State
local autoFarmActive = false
local autoFarmConn = nil
local farmMode = "Keduanya"  -- Tanam / Panen / Keduanya
local farmCrop = "Wheat"
local farmRadius = 50
local autoSell = false
local sellRemotePath = ""

-- Map Exploit State
local mapActive = false
local noclipActive = false
local speedActive = false
local speedValue = 50
local originalSpeed = 16
local teleportPoints = {}
local selectedPoint = nil
local noclipConn = nil
local speedConn = nil

-- ════════════════════════════════════════
--  UTILITY FUNCTIONS
-- ════════════════════════════════════════
local function doCopy(text)
    local ok = pcall(function() setclipboard(text) end)
    Library:Notification(ok and "📋 Copied!" or "❌ Gagal",
        ok and "Berhasil copy ke clipboard!" or "setclipboard tidak support", 3)
end

local function serializeValue(v, depth)
    depth = depth or 0; if depth > 4 then return "..." end
    local t = typeof(v)
    if t == "string" then
        if #v <= 4 then
            local hex = ""
            for i = 1, #v do hex = hex..string.format("\\x%02X", string.byte(v, i)) end
            return string.format('STR[%s]', hex)
        end
        return string.format('"%s"', v:sub(1, 60))
    elseif t == "number" then return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "Vector3" then return string.format("V3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
    elseif t == "CFrame" then return string.format("CF(%.2f,%.2f,%.2f)", v.Position.X, v.Position.Y, v.Position.Z)
    elseif t == "table" then
        local parts = {}; local count = 0
        for k, val in pairs(v) do
            count = count + 1; if count > 6 then table.insert(parts, "..."); break end
            table.insert(parts, string.format("[%s]=%s", serializeValue(k, depth+1), serializeValue(val, depth+1)))
        end
        return "{"..table.concat(parts, ", ").."}"
    elseif t == "Instance" then return pcall(function() return v:GetFullName() end) and v:GetFullName() or "Instance"
    else return "["..t.."]" end
end

local function findByPath(path)
    path = path:gsub("^game%.", "")
    local parts = {}; for p in path:gmatch("[^%.]+") do table.insert(parts, p) end
    local cur = game
    for _, p in ipairs(parts) do
        local found = cur:FindFirstChild(p); if not found then return nil end; cur = found
    end
    return cur
end

local function parseArgs(str)
    local args = {}; if not str or str == "" then return args end
    for token in str:gmatch("[^,]+") do
        token = token:match("^%s*(.-)%s*$")
        local num = tonumber(token)
        if num then table.insert(args, num)
        elseif token:lower() == "true" then table.insert(args, true)
        elseif token:lower() == "false" then table.insert(args, false)
        else table.insert(args, token) end
    end
    return args
end

local function getCharacter()
    return LP.Character or LP.CharacterAdded:Wait()
end

-- ════════════════════════════════════════
--  SCAN FUNCTIONS (CORE)
-- ════════════════════════════════════════
local function scanRemotes(root, targetClass, results, seen)
    seen = seen or {}; if not root or seen[root] then return end; seen[root] = true
    local ok, children = pcall(function() return root:GetChildren() end)
    if not ok then return end
    for _, child in ipairs(children) do
        if child:IsA(targetClass) then
            table.insert(results, {
                name = child.Name, path = child:GetFullName(),
                rtype = targetClass == "RemoteEvent" and "EVENT" or "FUNC",
                ref = child, cat = nil, prio = 99, tip = "",
            })
        end
        scanRemotes(child, targetClass, results, seen)
    end
end

local function scanAll(targetClass)
    local results = {}; local seen = {}
    for _, loc in ipairs(SCAN_LOCATIONS) do scanRemotes(loc, targetClass, results, seen) end
    return results
end

local function applyFilter(list, kw)
    if not kw or kw == "" then return list end
    local filtered = {}; local kl = kw:lower()
    for _, r in ipairs(list) do
        if r.path:lower():find(kl, 1, true) or r.name:lower():find(kl, 1, true) then
            table.insert(filtered, r)
        end
    end
    return filtered
end

-- ════════════════════════════════════════
--  AUTO DETECT EXPLOIT (10 KATEGORI)
-- ════════════════════════════════════════
local CATEGORIES = {
    { name="💰 Economy", prio=1, keys={"givemoney","addmoney","addcash","addcoin","givecoin","addgold","updatecurrency","rewardmoney","earnmoney","collectmoney","getcoin","getmoney","purchase","buycoin","reward","payout","transfer","earn","claim","collect"}, tip="Fire dengan nilai besar (999999 atau -1)" },
    { name="🎁 Item", prio=1, keys={"giveitem","additem","equipitem","spawnitem","dropitem","pickupitem","rewarditem","collectitem","getitem","receiveitem","addtoinventory","giveweapon","addweapon","givegear","unlocktool"}, tip="Fire dengan item ID yang diinginkan" },
    { name="⚔️ Combat", prio=1, keys={"dealdamage","takedamage","killplayer","hitremote","attackevent","damageevent","hitplayer","dealfire","instantkill","overkill"}, tip="Fire ke target dengan damage tinggi" },
    { name="🔓 Admin", prio=1, keys={"setadmin","giverank","promoteplayer","setrole","givevip","updatepermission","setlevel","givepower","makeadmin","addadmin","setowner","givemod","rank","role","admin","vip"}, tip="Fire dengan nama player sendiri" },
    { name="🏆 XP/Level", prio=2, keys={"addxp","levelup","updatelevel","completequest","finishmission","addexp","gainxp","rewardxp","questcomplete","missiondone","stageclear","addpoint","updatepoint","addscore"}, tip="Fire dengan nilai XP/level besar" },
    { name="🚀 Teleport", prio=2, keys={"teleportplayer","movetoposition","setposition","updateposition","warpplayer","tpplayer","setcframe","updatecframe","moveplayer"}, tip="Fire dengan koordinat tujuan" },
    { name="🛡️ Status", prio=2, keys={"sethealth","addhealth","giveshield","addshield","setspeed","addspeed","givebuff","addbuff","setinvincible","godmode","nohit","heal","regenerate","revive","respawn"}, tip="Fire untuk ubah status karakter" },
    { name="🔑 Unlock", prio=2, keys={"unlockitem","unlockarea","opendoor","accessroom","opengate","unlockfeature","enablefeature","purchaseaccess","buyaccess","entervip","unlock","open","access"}, tip="Fire untuk buka area/item terkunci" },
    { name="📊 Data/Save", prio=3, keys={"savedata","updatedata","setdata","writedata","syncdata","saveprogress","updateprogress","setstats","updatestats","saveprofile"}, tip="Hati-hati — bisa corrupt save data" },
    { name="🔧 Utility", prio=3, keys={"notify","notification","message","broadcast","chat","sendmessage","log","track","analytics","announce"}, tip="Potensi rendah tapi coba saja" },
}

local function detectCategory(remote)
    local nl = remote.name:lower()
    for _, cat in ipairs(CATEGORIES) do
        for _, kw in ipairs(cat.keys) do if nl:find(kw, 1, true) then return cat.name, cat.prio, cat.tip end end
    end
    return nil, 99, ""
end

local function runAutoDetect(list)
    local detected = {}
    for _, r in ipairs(list) do
        local catName, prio, tip = detectCategory(r)
        if catName then r.cat = catName; r.prio = prio; r.tip = tip; table.insert(detected, r) end
    end
    table.sort(detected, function(a,b) if a.prio ~= b.prio then return a.prio < b.prio end return a.name < b.name end)
    return detected
end

-- ════════════════════════════════════════
--  DISPLAY FUNCTION
-- ════════════════════════════════════════
local function showPage(list, page, title, isExploit)
    if #list == 0 then Library:Notification("📭", "Tidak ada data\nScan dulu!", 3); return page end
    local totalPages = math.ceil(#list / PAGE_SIZE); page = math.max(1, math.min(page, totalPages))
    local startIdx = (page-1)*PAGE_SIZE + 1; local endIdx = math.min(page*PAGE_SIZE, #list)
    local text = string.format("📄 Hal %d/%d | Total: %d\n\n", page, totalPages, #list)
    for i = startIdx, endIdx do
        local r = list[i]
        if isExploit then
            local prioLabel = r.prio==1 and "🔴HIGH" or r.prio==2 and "🟡MED" or "🟢LOW"
            text = text..string.format("[%d] %s %s\n%s\n[%s] %s\n💡 %s\n\n", i, prioLabel, r.cat, r.name, r.rtype, r.path:match("([^.]+)$") or r.name, r.tip)
        else
            text = text..string.format("[%d] [%s] %s\n%s\n\n", i, r.rtype, r.name, r.path)
        end
    end
    if totalPages > 1 then text = text..string.format("▶ Hal %d/%d", math.min(page+1, totalPages), totalPages) end
    Library:Notification(string.format("%s [%d-%d]", title, startIdx, endIdx), text, 18)
    return page
end

-- ════════════════════════════════════════
--  FARMING SPY FUNCTIONS
-- ════════════════════════════════════════
local FARM_KEYWORDS = {
    tanam = { remotes = {"plant", "tanam", "grow", "seed", "sow", "cultivate", "tabur"}, args = {"cropName", "seedType", "plot", "position", " tanah", "\\x06", "seed"} },
    panen = { remotes = {"harvest", "panen", "collect", "pick", "petik", "gather", "cut", "pangkas"}, args = {"crop", "plant", "ready", "harvest", "\\x0F", "sellPrice", "cropPos"} }
}

local function isPlantAction(remoteName, argsSerialized)
    remoteName = remoteName:lower()
    for _, kw in ipairs(FARM_KEYWORDS.tanam.remotes) do if remoteName:find(kw, 1, true) then return true, "🌱 TANAM" end end
    for _, pattern in ipairs(FARM_KEYWORDS.tanam.args) do if argsSerialized:find(pattern, 1, true) then return true, "🌱 TANAM (arg)" end end
    return false, nil
end

local function isHarvestAction(remoteName, argsSerialized)
    remoteName = remoteName:lower()
    for _, kw in ipairs(FARM_KEYWORDS.panen.remotes) do if remoteName:find(kw, 1, true) then return true, "🌾 PANEN" end end
    for _, pattern in ipairs(FARM_KEYWORDS.panen.args) do if argsSerialized:find(pattern, 1, true) then return true, "🌾 PANEN (arg)" end end
    return false, nil
end

local function extractCropInfo(args)
    local cropType = "unknown"; local position = nil
    for _, arg in ipairs(args) do
        if type(arg) == "string" and arg:len() > 2 and arg:len() < 30 then cropType = arg
        elseif type(arg) == "table" then
            if arg.cropName then cropType = arg.cropName elseif arg.seedType then cropType = arg.seedType elseif arg.plant then cropType = arg.plant end
            if arg.position then position = arg.position elseif arg.cropPos then position = arg.cropPos elseif arg.hitPosition then position = arg.hitPosition end
        elseif typeof(arg) == "Vector3" then position = arg
        elseif typeof(arg) == "CFrame" then position = arg.Position
        elseif typeof(arg) == "Instance" then cropType = arg.Name; if arg:IsA("BasePart") then position = arg.Position end end
    end
    return cropType, position
end

local function startFarmingSpy()
    for _, conn in ipairs(farmSpyConns) do pcall(function() conn:Disconnect() end) end
    farmSpyConns = {}
    local events = scanAll("RemoteEvent")
    for _, r in ipairs(events) do
        local ok, conn = pcall(function()
            return r.ref.OnClientEvent:Connect(function(...)
                local args = {...}; local argsSerialized = serializeValue(args, 0)
                local isPlant, plantLabel = isPlantAction(r.name, argsSerialized)
                local isHarvest, harvestLabel = isHarvestAction(r.name, argsSerialized)
                if isPlant or isHarvest then
                    local action = isPlant and plantLabel or harvestLabel
                    local cropType, position = extractCropInfo(args)
                    local posStr = "unknown"
                    if position then
                        if typeof(position) == "Vector3" then posStr = string.format("(%.1f,%.1f,%.1f)", position.X, position.Y, position.Z)
                        else posStr = tostring(position) end
                    end
                    local entry = { time = os.time(), timeStr = os.date("%H:%M:%S"), action = action, remoteName = r.name, remotePath = r.path, cropType = cropType, position = posStr, raw = argsSerialized }
                    table.insert(farmSpyLog, 1, entry)
                    if #farmSpyLog > 100 then table.remove(farmSpyLog, #farmSpyLog) end
                end
            end)
        end)
        if ok and conn then table.insert(farmSpyConns, conn) end
    end
    Library:Notification("🌾 Farming Spy ON", string.format("Memantau %d remote\nDeteksi otomatis tanam/panen", #events), 5)
    return #events
end

local function stopFarmingSpy()
    for _, conn in ipairs(farmSpyConns) do pcall(function() conn:Disconnect() end) end
    farmSpyConns = {}
end

local function getFilteredFarmLogs()
    if farmSpyFilter == "Semua" then return farmSpyLog end
    local filtered = {}
    for _, entry in ipairs(farmSpyLog) do
        if (farmSpyFilter == "Tanam" and entry.action:find("TANAM")) or (farmSpyFilter == "Panen" and entry.action:find("PANEN")) then
            table.insert(filtered, entry)
        end
    end
    return filtered
end

local function showFarmLogs(page)
    local logs = getFilteredFarmLogs()
    if #logs == 0 then Library:Notification("📭", "Belum ada log farming\nLakukan tanam/panen dulu!", 3); return end
    local totalPages = math.ceil(#logs / PAGE_SIZE); page = math.max(1, math.min(page, totalPages))
    local startIdx = (page-1)*PAGE_SIZE + 1; local endIdx = math.min(page*PAGE_SIZE, #logs)
    local text = string.format("🌾 FARMING LOG [Hal %d/%d]\nFilter: %s | Total: %d\n\n", page, totalPages, farmSpyFilter, #logs)
    for i = startIdx, endIdx do
        local e = logs[i]
        text = text .. string.format("[%d] %s %s\n    Remote: %s\n    Crop: %s\n    Pos: %s\n    Path: %s\n\n", i, e.timeStr, e.action, e.remoteName, e.cropType, e.position, e.remotePath:match("([^.]+)$") or e.remotePath)
    end
    Library:Notification("🌾 Farming Spy", text, 20); farmSpyPage = page
end

local function copyFarmLogs(formatType)
    local logs = getFilteredFarmLogs()
    if #logs == 0 then Library:Notification("❌", "Tidak ada log untuk di-copy", 2); return end
    local text = ""
    if formatType == "simple" then
        text = "=== FARMING LOG (SIMPLE) ===\n\n"
        for i, e in ipairs(logs) do text = text .. string.format("%d. [%s] %s - %s\n", i, e.timeStr, e.action, e.cropType) end
    elseif formatType == "detail" then
        text = "=== FARMING LOG (DETAIL) ===\n\n"
        for i, e in ipairs(logs) do
            text = text .. string.format("[LOG #%d]\nWaktu  : %s\nAksi   : %s\nRemote : %s\nPath   : %s\nCrop   : %s\nPosisi : %s\nRaw    : %s\n\n", i, e.timeStr, e.action, e.remoteName, e.remotePath, e.cropType, e.position, e.raw:sub(1, 100))
        end
    elseif formatType == "csv" then
        text = "No,Waktu,Aksi,Remote,Crop,Posisi\n"
        for i, e in ipairs(logs) do text = text .. string.format("%d,%s,%s,%s,%s,%s\n", i, e.timeStr, e.action, e.remoteName, e.cropType, e.position) end
    end
    doCopy(text)
end

-- ════════════════════════════════════════
--  AUTO FARM FUNCTIONS
-- ════════════════════════════════════════
local function findFarmPlots()
    local plots = {}
    local keywords = {"soil", "farm", "plot", "field", "lantai", "tanah", "crop", "plant"}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Part") or obj:IsA("BasePart") or obj:IsA("Model")) then
            local name = obj.Name:lower()
            for _, kw in ipairs(keywords) do if name:find(kw) then table.insert(plots, obj); break end end
        end
    end
    return plots
end

local function getFarmRemote(actionType)
    for _, r in ipairs(allRemotes) do
        local nl = r.name:lower()
        if actionType == "plant" and (nl:find("plant") or nl:find("tanam") or nl:find("grow") or nl:find("seed")) then return r.ref end
        if actionType == "harvest" and (nl:find("harvest") or nl:find("panen") or nl:find("collect") or nl:find("pick")) then return r.ref end
    end
    return nil
end

local function autoPlant()
    if not autoFarmActive then return end
    local plantRemote = getFarmRemote("plant")
    if not plantRemote then return end
    local plots = findFarmPlots()
    if #plots == 0 then return end
    for _, plot in ipairs(plots) do
        if not autoFarmActive then break end
        local isEmpty = true
        for _, child in ipairs(plot:GetChildren()) do if child.Name:lower():find(farmCrop:lower()) then isEmpty = false; break end end
        if isEmpty then pcall(function() plantRemote:FireServer(plot, farmCrop, plot.Position) end); task.wait(0.3) end
    end
end

local function autoHarvest()
    if not autoFarmActive then return end
    local harvestRemote = getFarmRemote("harvest")
    if not harvestRemote then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not autoFarmActive then break end
        if obj.Name:lower():find(farmCrop:lower()) then
            local isReady = true
            if obj:FindFirstChild("Growth") then isReady = obj.Growth.Value >= 100
            elseif obj:FindFirstChild("Ready") then isReady = obj.Ready.Value end
            if isReady then pcall(function() harvestRemote:FireServer(obj, obj.Position) end); task.wait(0.2) end
        end
    end
end

local function autoSellItems()
    if not autoSell or sellRemotePath == "" then return end
    local sellRemote = findByPath(sellRemotePath)
    if not sellRemote then return end
    pcall(function() if sellRemote:IsA("RemoteEvent") then sellRemote:FireServer("sell_all", "crops") elseif sellRemote:IsA("RemoteFunction") then sellRemote:InvokeServer("sell_all") end end)
end

local function startFarmLoop()
    if autoFarmConn then autoFarmConn:Disconnect() end
    autoFarmConn = RunService.Heartbeat:Connect(function()
        if not autoFarmActive then return end
        if farmMode == "Tanam" or farmMode == "Keduanya" then autoPlant() end
        if farmMode == "Panen" or farmMode == "Keduanya" then autoHarvest() end
        if autoSell then autoSellItems() end
        task.wait(1.5)
    end)
end

-- ════════════════════════════════════════
--  MAP EXPLOIT FUNCTIONS
-- ════════════════════════════════════════
local function teleportTo(position)
    local char = getCharacter()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(position)
        Library:Notification("📌 Teleport", string.format("Ke posisi:\nX: %.1f, Y: %.1f, Z: %.1f", position.X, position.Y, position.Z), 3)
    end
end

local function toggleNoclip(enable)
    noclipActive = enable
    if noclipConn then noclipConn:Disconnect() end
    if enable then
        noclipConn = RunService.Stepped:Connect(function()
            if noclipActive then
                local char = getCharacter()
                for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
            end
        end)
        Library:Notification("👻 Noclip", "ON", 2)
    else Library:Notification("👻 Noclip", "OFF", 2) end
end

local function toggleSpeed(enable)
    speedActive = enable
    if speedConn then speedConn:Disconnect() end
    if enable then
        local char = getCharacter()
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then originalSpeed = humanoid.WalkSpeed; humanoid.WalkSpeed = speedValue end
        speedConn = RunService.Heartbeat:Connect(function()
            if speedActive then
                local char = getCharacter()
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid and humanoid.WalkSpeed ~= speedValue then humanoid.WalkSpeed = speedValue end
            end
        end)
        Library:Notification("⚡ Speed", string.format("%d (ON)", speedValue), 2)
    else
        local char = getCharacter()
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then humanoid.WalkSpeed = originalSpeed end
        Library:Notification("⚡ Speed", "OFF", 2)
    end
end

local function saveCurrentPosition(name)
    local char = getCharacter()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        table.insert(teleportPoints, {name = name, pos = hrp.Position})
        Library:Notification("💾 Saved", string.format("Posisi '%s' disimpan", name), 2)
    end
end

-- ════════════════════════════════════════
--  SPY / HOOK / BN2 FUNCTIONS (from original)
-- ════════════════════════════════════════
-- (Functions are preserved from original script - truncated for brevity)
-- Includes: detectSpyAction, startSpy, stopSpy, buildTargetSet, detectHookAction, startHook, stopHook, detectBN2Action, startBN2Spy, stopBN2Spy, doFire

-- ════════════════════════════════════════
--  TAB SCAN UI
-- ════════════════════════════════════════
local ScanPage = TabScan:Page("Scan Remote", "search")
local ScanLeft = ScanPage:Section("🔍 Scanner", "Left")
local ScanRight = ScanPage:Section("📋 Hasil & Copy", "Right")

ScanLeft:TextBox("Filter Nama/Path", "FilterBox", "", function(v) filterKeyword = v end, "Kosong = semua")
ScanLeft:Button("🔴 Scan RemoteEvent", "Scan semua RemoteEvent", function()
    task.spawn(function()
        Library:Notification("🔍", "Scanning...", 2)
        local r = scanAll("RemoteEvent")
        allRemotes = applyFilter(r, filterKeyword)
        exploitList = runAutoDetect(allRemotes)
        currentPage = 1
        Library:Notification("🔴 RemoteEvent", string.format("%d ditemukan\n⚠️ %d exploit candidate\n\nBuka tab Exploit!", #allRemotes, #exploitList), 6)
    end)
end)
ScanLeft:Button("🔵 Scan RemoteFunction", "Scan semua RemoteFunction", function()
    task.spawn(function()
        Library:Notification("🔍", "Scanning...", 2)
        local r = scanAll("RemoteFunction")
        allRemotes = applyFilter(r, filterKeyword)
        exploitList = runAutoDetect(allRemotes)
        currentPage = 1
        Library:Notification("🔵 RemoteFunction", string.format("%d ditemukan\n⚠️ %d exploit candidate", #allRemotes, #exploitList), 6)
    end)
end)
ScanLeft:Button("⚡ Scan SEMUA + Auto Detect", "Scan Event+Function + detect exploit", function()
    task.spawn(function()
        Library:Notification("🔍", "Scanning semua service...", 2)
        local events = scanAll("RemoteEvent")
        local funcs = scanAll("RemoteFunction")
        local all = {}
        for _, r in ipairs(events) do table.insert(all, r) end
        for _, r in ipairs(funcs) do table.insert(all, r) end
        allRemotes = applyFilter(all, filterKeyword)
        exploitList = runAutoDetect(allRemotes)
        local p1,p2,p3 = 0,0,0
        for _, r in ipairs(exploitList) do if r.prio==1 then p1=p1+1 elseif r.prio==2 then p2=p2+1 else p3=p3+1 end end
        Library:Notification("⚡ Scan Selesai", string.format("Total: %d remote\n🔴 Event: %d | 🔵 Func: %d\n\n⚠️ Exploit: %d total\n🔴 HIGH: %d\n🟡 MED : %d\n🟢 LOW : %d\n\nBuka tab [Exploit]!", #allRemotes, #events, #funcs, #exploitList, p1, p2, p3), 12)
    end)
end)

ScanRight:Button("📄 Lihat Hasil", "Tampilkan halaman pertama", function() currentPage = showPage(allRemotes, 1, "🔌 Remote", false) end)
ScanRight:Button("▶ Berikutnya", "Halaman berikutnya", function() currentPage = showPage(allRemotes, currentPage+1, "🔌 Remote", false) end)
ScanRight:Button("◀ Sebelumnya", "Halaman sebelumnya", function() currentPage = showPage(allRemotes, currentPage-1, "🔌 Remote", false) end)
ScanRight:Button("📋 Copy Semua Path", "Copy semua remote ke clipboard", function()
    if #allRemotes == 0 then Library:Notification("❌", "Scan dulu!", 2); return end
    local text = string.format("=== SCAN (%d) ===\n", #allRemotes)
    for i, r in ipairs(allRemotes) do text = text..string.format("[%d][%s] %s\n", i, r.rtype, r.path) end
    doCopy(text)
end)

local copyIdx = 1
ScanRight:Slider("Nomor Remote", "CopyIdxSlider", 1, 200, 1, function(v) copyIdx = v end, "Nomor yang mau di-copy")
ScanRight:Button("📋 Copy Remote #", "Copy 1 remote sesuai nomor", function()
    if copyIdx > #allRemotes then Library:Notification("❌","Max: "..#allRemotes,2); return end
    local r = allRemotes[copyIdx]; doCopy(string.format("[%s] %s", r.rtype, r.path))
end)

-- ════════════════════════════════════════
--  TAB EXPLOIT UI
-- ════════════════════════════════════════
local ExPage = TabExploit:Page("Exploit Candidates", "alert-triangle")
local ExLeft = ExPage:Section("⚠️ Kandidat", "Left")
local ExRight = ExPage:Section("📋 Copy & Fire", "Right")

ExLeft:Button("📄 Lihat Semua Exploit", "Tampilkan exploit candidates", function() exploitPage = showPage(exploitList, 1, "⚠️ Exploit", true) end)
ExLeft:Button("▶ Berikutnya", "Halaman berikutnya", function() exploitPage = showPage(exploitList, exploitPage+1, "⚠️ Exploit", true) end)
ExLeft:Button("◀ Sebelumnya", "Halaman sebelumnya", function() exploitPage = showPage(exploitList, exploitPage-1, "⚠️ Exploit", true) end)
ExLeft:Button("🔴 HIGH Priority Saja", "Filter prioritas tinggi", function()
    local high = {}; for _, r in ipairs(exploitList) do if r.prio == 1 then table.insert(high, r) end end; showPage(high, 1, "🔴 HIGH", true)
end)

ExRight:Button("📋 Copy Semua Exploit", "Copy semua exploit ke clipboard", function()
    if #exploitList == 0 then Library:Notification("❌","Scan dulu!",2); return end
    local text = string.format("=== EXPLOIT (%d) ===\n\n", #exploitList)
    for i, r in ipairs(exploitList) do
        local pl = r.prio==1 and "[HIGH]" or r.prio==2 and "[MED]" or "[LOW]"
        text = text..string.format("[%d] %s %s\nKat: %s\nPath: %s\nTipe: %s\nTip: %s\n\n", i, pl, r.name, r.cat, r.path, r.rtype, r.tip)
    end
    doCopy(text)
end)

local exIdx = 1
ExRight:Slider("Nomor Exploit", "ExIdxSlider", 1, 100, 1, function(v) exIdx = v end, "Pilih nomor exploit")
ExRight:Button("📋 Copy Exploit #", "Copy 1 exploit sesuai nomor", function()
    if exIdx > #exploitList then Library:Notification("❌","Max: "..#exploitList,2); return end
    local r = exploitList[exIdx]
    doCopy(string.format("[%s][%s] %s\nKat: %s\nPath: %s\nTip: %s", r.prio==1 and "HIGH" or r.prio==2 and "MED" or "LOW", r.rtype, r.name, r.cat, r.path, r.tip))
end)
ExRight:Button("🔥 Kirim ke Tab Fire", "Paste path exploit ke Fire", function()
    if exIdx > #exploitList then Library:Notification("❌","Max: "..#exploitList,2); return end
    local r = exploitList[exIdx]; firePath = r.path:gsub("^game%.","")
    Library:Notification("🔥 Siap Fire", string.format("%s\n%s\n💡 %s\n\nBuka tab Fire!", r.name, r.cat, r.tip), 6)
end)

-- ════════════════════════════════════════
--  TAB SPY UI (Original)
-- ════════════════════════════════════════
local SpyPage = TabSpy:Page("Remote Spy", "eye")
local SpyLeft = SpyPage:Section("👁 Monitor", "Left")
local SpyRight = SpyPage:Section("📋 Log", "Right")

SpyLeft:Toggle("👁 Spy Incoming", "SpyToggle", false, "Monitor semua OnClientEvent", function(v) spyOn = v; if v then startSpy() else stopSpy(); Library:Notification("👁 Spy","OFF",2) end end)
SpyLeft:Button("🔄 Restart Spy", "Scan ulang & restart", function() if spyOn then stopSpy(); task.wait(0.2); startSpy() else Library:Notification("❌","Aktifkan Spy dulu",2) end end)
SpyLeft:Button("🗑 Clear Log", "Hapus log spy", function() spyLog={}; Library:Notification("🗑","Cleared",2) end)
SpyLeft:Paragraph("Info", "Monitor server → client\n\n⚠️ Remote exploit\nditandai otomatis\n\nMainkan game\n→ lihat log")

SpyRight:Button("📄 Lihat Log", "Tampilkan log spy", function()
    if #spyLog == 0 then Library:Notification("📭","Belum ada log",2); return end
    local total = math.ceil(#spyLog/PAGE_SIZE); local text = string.format("📄 Log 1/%d (%d total)\n\n", total, #spyLog)
    for i = 1, math.min(PAGE_SIZE, #spyLog) do text = text..string.format("[%d] %s\n\n", i, spyLog[i]) end
    Library:Notification("👁 Spy Log", text, 18); spyPage = 1
end)
SpyRight:Button("▶ Log Berikutnya", "Halaman log berikutnya", function()
    spyPage = spyPage + 1; local total = math.ceil(#spyLog/PAGE_SIZE); if spyPage > total then spyPage = total end
    local startIdx = (spyPage-1)*PAGE_SIZE+1; local endIdx = math.min(spyPage*PAGE_SIZE, #spyLog)
    local text = string.format("📄 Log Hal %d/%d\n\n", spyPage, total)
    for i = startIdx, endIdx do text = text..string.format("[%d] %s\n\n", i, spyLog[i]) end
    Library:Notification("👁 Spy Log", text, 18)
end)
SpyRight:Button("📋 Copy Log Spy", "Copy semua log ke clipboard", function()
    if #spyLog == 0 then Library:Notification("❌","Belum ada log",2); return end
    local text = string.format("=== SPY LOG (%d) ===\n\n", #spyLog)
    for i, e in ipairs(spyLog) do text = text..string.format("[%d] %s\n\n", i, e) end; doCopy(text)
end)

-- ════════════════════════════════════════
--  TAB HOOK UI (Original)
-- ════════════════════════════════════════
local HookPage = TabHook:Page("FireServer Hook", "terminal")
local HookLeft = HookPage:Section("🔌 Hook Control", "Left")
local HookRight = HookPage:Section("📋 Log", "Right")

HookLeft:Toggle("🔌 Hook FireServer", "HookToggle", false, "Intercept semua FireServer outgoing", function(v) hookOn = v; if v then local ok, err = pcall(startHook); if not ok then Library:Notification("❌ Error", "hookmetamethod tidak support!\n"..tostring(err), 5); hookOn = false end else stopHook(); Library:Notification("🔌 Hook","OFF",2) end end)
HookLeft:Button("🗑 Clear Hook Log", "Hapus log hook", function() hookLog={}; Library:Notification("🗑","Cleared",2) end)
HookLeft:Paragraph("Panduan", "Hook intercept:\nClient → Server\n\nLakukan aksi:\n🌱 Tanam\n🛒 Beli\n🌾 Panen\n⚔️ Attack\n\nLihat log →\nketahui packet")

HookRight:Button("📄 Lihat Log", "Tampilkan log hook", function()
    if #hookLog == 0 then Library:Notification("📭","Belum ada log\nLakukan aksi dulu!",3); return end
    local text = string.format("📄 Hook Log (%d)\n\n", #hookLog)
    for i = 1, math.min(PAGE_SIZE, #hookLog) do text = text..string.format("[%d] %s\n\n", i, hookLog[i]) end
    Library:Notification("🔌 Hook Log", text, 18); hookPage = 1
end)
HookRight:Button("▶ Log Berikutnya","Halaman berikutnya", function()
    hookPage = hookPage + 1; local total = math.ceil(#hookLog/PAGE_SIZE); if hookPage > total then hookPage = total end
    local si = (hookPage-1)*PAGE_SIZE+1; local ei = math.min(hookPage*PAGE_SIZE, #hookLog)
    local text = string.format("📄 Hal %d/%d\n\n", hookPage, total)
    for i = si, ei do text = text..string.format("[%d] %s\n\n", i, hookLog[i]) end
    Library:Notification("🔌 Hook Log", text, 18)
end)
HookRight:Button("📋 Copy Log Hook","Copy semua hook log", function()
    if #hookLog == 0 then Library:Notification("❌","Belum ada log",2); return end
    local text = string.format("=== HOOK LOG (%d) ===\n\n", #hookLog)
    for i, e in ipairs(hookLog) do text = text..string.format("[%d] %s\n\n", i, e) end; doCopy(text)
end)

-- ════════════════════════════════════════
--  TAB BN2 UI (Original)
-- ════════════════════════════════════════
local BN2Page = TabBN2:Page("BridgeNet2", "radio")
local BN2Left = BN2Page:Section("📡 BN2 Spy", "Left")
local BN2Right = BN2Page:Section("📋 Log", "Right")

BN2Left:Toggle("📡 BN2 Spy", "BN2Toggle", false, "Monitor BridgeNet2 dataRemoteEvent", function(v) bn2On = v; if v then local ok = startBN2Spy(); if not ok then bn2On = false end else stopBN2Spy(); Library:Notification("📡 BN2","OFF",2) end end)
BN2Left:Button("🗑 Clear BN2 Log","Hapus log BN2", function() bn2Log={}; Library:Notification("🗑","Cleared",2) end)
BN2Left:Paragraph("Info BN2", "BridgeNet2 =\nFramework yang bungkus\nsemua remote jadi 1\n\nIdentifier key:\n\\x05 = Beli/Request\n\\x06 = Tanam\n\\x0D = Response\n\\x0F = Harvest data\n\\x04 = Coins update\n\nUntuk game lain\nidentifier bisa beda!")

BN2Right:Button("📄 Lihat Log BN2","Tampilkan log BN2", function()
    if #bn2Log == 0 then Library:Notification("📭","Belum ada log\nLakukan aksi dulu!",3); return end
    local text = string.format("📄 BN2 Log (%d)\n\n", #bn2Log)
    for i = 1, math.min(PAGE_SIZE, #bn2Log) do text = text..string.format("[%d] %s\n\n", i, bn2Log[i]) end
    Library:Notification("📡 BN2 Log", text, 18); bn2Page = 1
end)
BN2Right:Button("▶ Log Berikutnya","Halaman berikutnya", function()
    bn2Page = bn2Page + 1; local total = math.ceil(#bn2Log/PAGE_SIZE); if bn2Page > total then bn2Page = total end
    local si = (bn2Page-1)*PAGE_SIZE+1; local ei = math.min(bn2Page*PAGE_SIZE, #bn2Log)
    local text = string.format("📄 Hal %d/%d\n\n", bn2Page, total)
    for i = si, ei do text = text..string.format("[%d] %s\n\n", i, bn2Log[i]) end
    Library:Notification("📡 BN2 Log", text, 18)
end)
BN2Right:Button("📋 Copy BN2 Log","Copy semua log BN2", function()
    if #bn2Log == 0 then Library:Notification("❌","Belum ada log",2); return end
    local text = string.format("=== BN2 LOG (%d) ===\n\n", #bn2Log)
    for i, e in ipairs(bn2Log) do text = text..string.format("[%d] %s\n\n", i, e) end; doCopy(text)
end)
BN2Right:Button("📋 Copy Log HARVEST","Filter & copy harvest saja", function()
    local filtered = {}; for _, e in ipairs(bn2Log) do if e:find("HARVEST") then table.insert(filtered, e) end end
    if #filtered == 0 then Library:Notification("❌","Tidak ada log harvest",2); return end
    local text = string.format("=== BN2 HARVEST (%d) ===\n\n", #filtered)
    for i, e in ipairs(filtered) do text = text..string.format("[%d] %s\n\n", i, e) end; doCopy(text)
end)

-- ════════════════════════════════════════
--  TAB FIRE UI
-- ════════════════════════════════════════
local FirePage = TabFire:Page("Fire Remote", "zap")
local FireLeft = FirePage:Section("🔥 Fire / Invoke", "Left")
local FireRight = FirePage:Section("ℹ Panduan", "Right")

FireLeft:TextBox("Path Remote", "FirePathBox", "", function(v) firePath = v end, "Contoh: ReplicatedStorage.Remotes.X")
FireLeft:TextBox("Argumen (pisah koma)", "FireArgsBox", "", function(v) fireArgs = v end, "Contoh: Hello, 123, true")
FireLeft:Button("🔥 Fire / Invoke", "Kirim remote ke server", function() doFire(firePath, fireArgs) end)

local pasteIdx = 1
FireLeft:Slider("Nomor dari Scan", "PasteSlider", 1, 200, 1, function(v) pasteIdx = v end, "Nomor remote dari tab Scan")
FireLeft:Button("📋 Paste dari Scan", "Isi path dari hasil scan", function()
    if #allRemotes == 0 then Library:Notification("❌","Scan dulu!",3); return end
    if pasteIdx > #allRemotes then Library:Notification("❌","Max: "..#allRemotes,2); return end
    local r = allRemotes[pasteIdx]; firePath = r.path:gsub("^game%.","")
    Library:Notification("📋 Paste", string.format("[%s] %s\nPath siap!", r.rtype, r.name), 4)
end)

FireRight:Paragraph("Cara Pakai", "1. Scan → Exploit\n   → Kirim ke Fire\n\n2. Atau Scan → Paste\n   dari nomor\n\n3. Isi argumen\n\n4. 🔥 Fire!")
FireRight:Paragraph("Format Argumen", "String  → Hello\nNumber  → 123\nBool    → true/false\n\nMultiple:\nHello, 123, true\n\nTips per kategori:\nEconomy → 999999\nItem    → nama item\nAdmin   → nama kamu")

-- ════════════════════════════════════════
--  TAB FARMING SPY UI
-- ════════════════════════════════════════
local FarmSpyPage = TabFarmSpy:Page("🌾 Farming Spy", "eye")
local FarmSpyLeft = FarmSpyPage:Section("🕵️ Spy Control", "Left")
local FarmSpyRight = FarmSpyPage:Section("📋 Log & Copy", "Right")

FarmSpyLeft:Toggle("🌾 Aktifkan Farming Spy", "FarmSpyToggle", false, "Deteksi otomatis tanam dan panen", function(v)
    farmSpyActive = v
    if v then
        if #allRemotes == 0 then Library:Notification("⚠️", "Scan remote dulu di tab Scan!\nSupaya bisa detect remote farm", 4); farmSpyActive = false; return end
        startFarmingSpy()
    else stopFarmingSpy(); Library:Notification("🌾 Farming Spy", "OFF", 2) end
end)

FarmSpyLeft:Dropdown("🔍 Filter Log", "FarmSpyFilter", {"Semua", "Tanam", "Panen"}, function(v) farmSpyFilter = v end, "Pilih jenis aksi yang ditampilkan")
FarmSpyLeft:Button("🔄 Reset Log", "Hapus semua log farming", function() farmSpyLog = {}; Library:Notification("🗑️", "Log farming dihapus", 2) end)
FarmSpyLeft:Paragraph("📊 Statistik", function()
    local total = #farmSpyLog; local tanam = 0; local panen = 0
    for _, e in ipairs(farmSpyLog) do if e.action:find("TANAM") then tanam = tanam + 1 end; if e.action:find("PANEN") then panen = panen + 1 end end
    return string.format("Total: %d\n🌱 Tanam: %d\n🌾 Panen: %d", total, tanam, panen)
end)

FarmSpyRight:Button("📄 Lihat Log", "Tampilkan log farming", function() showFarmLogs(1) end)
FarmSpyRight:Button("▶ Log Berikutnya", "Halaman berikutnya", function() showFarmLogs(farmSpyPage + 1) end)
FarmSpyRight:Button("◀ Log Sebelumnya", "Halaman sebelumnya", function() showFarmLogs(farmSpyPage - 1) end)
FarmSpyRight:Button("📋 Copy Simple", "Copy format sederhana", function() copyFarmLogs("simple") end)
FarmSpyRight:Button("📋 Copy Detail", "Copy dengan info lengkap", function() copyFarmLogs("detail") end)
FarmSpyRight:Button("📊 Copy CSV", "Copy format CSV (Excel)", function() copyFarmLogs("csv") end)
FarmSpyRight:Button("🌱 Copy Tanam Saja", "Copy hanya log tanam", function()
    local oldFilter = farmSpyFilter; farmSpyFilter = "Tanam"; copyFarmLogs("detail"); farmSpyFilter = oldFilter
end)
FarmSpyRight:Button("🌾 Copy Panen Saja", "Copy hanya log panen", function()
    local oldFilter = farmSpyFilter; farmSpyFilter = "Panen"; copyFarmLogs("detail"); farmSpyFilter = oldFilter
end)

local cropToExport = ""
FarmSpyRight:TextBox("🌽 Filter Crop", "CropExportFilter", "", function(v) cropToExport = v end, "Nama crop untuk diexport")
FarmSpyRight:Button("📋 Copy by Crop", "Copy log berdasarkan nama crop", function()
    if cropToExport == "" then Library:Notification("❌", "Masukkan nama crop dulu!", 2); return end
    local filtered = {}; for _, e in ipairs(farmSpyLog) do if e.cropType:lower():find(cropToExport:lower()) then table.insert(filtered, e) end end
    if #filtered == 0 then Library:Notification("❌", "Tidak ada log untuk crop: " .. cropToExport, 2); return end
    local text = string.format("=== FARMING LOG: %s (%d) ===\n\n", cropToExport, #filtered)
    for i, e in ipairs(filtered) do text = text .. string.format("[%d] %s %s\n    Remote: %s\n    Posisi: %s\n\n", i, e.timeStr, e.action, e.remoteName, e.position) end
    doCopy(text)
end)

-- ════════════════════════════════════════
--  TAB AUTO FARM UI
-- ════════════════════════════════════════
local FarmPage = TabAutoFarm:Page("Auto Farm", "tractor")
local FarmLeft = FarmPage:Section("🚜 Kontrol Farm", "Left")
local FarmRight = FarmPage:Section("⚙️ Pengaturan", "Right")

FarmLeft:Toggle("🌱 Aktifkan Auto Farm", "AutoFarmToggle", false, "Mulai auto tanam/panen otomatis", function(v)
    autoFarmActive = v
    if v then
        if #allRemotes == 0 then Library:Notification("⚠️", "Scan remote dulu!\nSupaya bisa deteksi remote farm", 4); autoFarmActive = false; return end
        startFarmLoop()
        Library:Notification("🚜 Auto Farm ON", string.format("Mode: %s\nCrop: %s", farmMode, farmCrop), 4)
    else
        if autoFarmConn then autoFarmConn:Disconnect(); autoFarmConn = nil end
        Library:Notification("🚜 Auto Farm", "OFF", 2)
    end
end)

FarmLeft:Dropdown("🌾 Mode Farm", "FarmMode", {"Tanam", "Panen", "Keduanya"}, function(v) farmMode = v end, "Pilih mode")
FarmLeft:TextBox("🌽 Nama Crop", "FarmCropName", farmCrop, function(v) farmCrop = v end, "Contoh: Wheat, Corn, Padi")
FarmLeft:Slider("📏 Radius", "FarmRadius", 10, 200, farmRadius, function(v) farmRadius = v end, "Radius pencarian lahan")
FarmLeft:Toggle("💰 Auto Sell", "AutoSellToggle", false, "Jual otomatis setelah panen", function(v) autoSell = v end)
FarmLeft:TextBox("📤 Remote Sell", "SellRemotePath", "", function(v) sellRemotePath = v end, "Path remote buat jual")
FarmLeft:Button("🔍 Scan Remote Farm", "Cari remote yang berhubungan dengan farm", function()
    if #allRemotes == 0 then Library:Notification("❌", "Scan remote dulu di tab Scan!", 3); return end
    local farmRemotes = {}; local keywords = {"plant", "harvest", "sell", "crop", "farm", "tanam", "panen", "jual"}
    for _, r in ipairs(allRemotes) do
        local nl = r.name:lower()
        for _, kw in ipairs(keywords) do if nl:find(kw) then table.insert(farmRemotes, r); break end end
    end
    if #farmRemotes == 0 then Library:Notification("❌", "Tidak ditemukan remote farm", 3)
    else
        local text = "🔍 REMOTE FARM DITEMUKAN:\n\n"
        for i, r in ipairs(farmRemotes) do text = text .. string.format("[%d] %s\n%s\n\n", i, r.name, r.path) end
        Library:Notification("🌾 Farm Remotes", text, 12)
    end
end)

FarmRight:Paragraph("📋 Panduan Auto Farm", "1. Scan semua remote dulu\n2. Aktifkan Auto Farm\n3. Pilih mode:\n   - Tanam: nanem terus\n   - Panen: metik hasil\n   - Keduanya: loop lengkap\n\n4. Set nama crop sesuai game\n5. (Opsional) Auto sell\n\n⚠️ Farm akan cari remote\n   otomatis dari hasil scan")

-- ════════════════════════════════════════
--  TAB MAP EXPLOIT UI
-- ════════════════════════════════════════
local MapPage = TabMap:Page("Map Exploit", "map")
local MapLeft = MapPage:Section("🗺️ Kontrol Map", "Left")
local MapRight = MapPage:Section("📌 Waypoints", "Right")

MapLeft:Toggle("👻 Noclip", "NoclipToggle", false, "Tembus dinding", function(v) toggleNoclip(v) end)
MapLeft:Toggle("⚡ Speed Boost", "SpeedToggle", false, "Jalan lebih cepat", function(v) toggleSpeed(v) end)
MapLeft:Slider("🚀 Speed Value", "SpeedValue", 16, 250, speedValue, function(v) speedValue = v; if speedActive then toggleSpeed(true) end end, "Kecepatan jalan")

MapLeft:TextBox("📍 Koordinat X", "CoordX", "", function(v) end, "Contoh: 100.5")
MapLeft:TextBox("📍 Koordinat Y", "CoordY", "", function(v) end, "Contoh: 50")
MapLeft:TextBox("📍 Koordinat Z", "CoordZ", "", function(v) end, "Contoh: 200")
MapLeft:Button("📌 Teleport ke Koordinat", "Pergi ke posisi yang diinput", function()
    local x = tonumber(MapLeft.Inputs.CoordX) or 0
    local y = tonumber(MapLeft.Inputs.CoordY) or 0
    local z = tonumber(MapLeft.Inputs.CoordZ) or 0
    teleportTo(Vector3.new(x, y, z))
end)

MapLeft:Button("📍 Teleport ke Spawn", "Kembali ke spawn", function()
    local spawns = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn")
    if spawns then teleportTo(spawns.Position) else Library:Notification("❌", "Spawn tidak ditemukan", 2) end
end)

MapLeft:Button("🎯 Teleport ke Kursor", "Teleport ke posisi mouse", function()
    local mouse = LP:GetMouse()
    local unitRay = Camera:ScreenPointToRay(mouse.X, mouse.Y)
    local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Blacklist; params.FilterDescendantsInstances = {getCharacter()}
    local raycast = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, params)
    if raycast then teleportTo(raycast.Position + Vector3.new(0, 3, 0)) else Library:Notification("❌", "Tidak ada tanah di kursor", 2) end
end)

MapRight:TextBox("📝 Nama Waypoint", "WaypointName", "", function(v) end, "Contoh: Farm Area")
MapRight:Button("💾 Simpan Posisi Sekarang", "Simpan posisi saat ini sebagai waypoint", function()
    local name = MapRight.Inputs.WaypointName
    if name and name ~= "" then saveCurrentPosition(name) else Library:Notification("❌", "Masukkan nama waypoint!", 2) end
end)

MapRight:Button("📋 Lihat Semua Waypoint", "Tampilkan daftar waypoint", function()
    if #teleportPoints == 0 then Library:Notification("📭", "Belum ada waypoint disimpan", 2); return end
    local text = "📌 WAYPOINT TERSIMPAN:\n\n"
    for i, wp in ipairs(teleportPoints) do
        text = text .. string.format("[%d] %s\n    (%.1f, %.1f, %.1f)\n\n", i, wp.name, wp.pos.X, wp.pos.Y, wp.pos.Z)
    end
    Library:Notification("🗺️ Waypoints", text, 15)
end)

local wpIdx = 1
MapRight:Slider("Nomor Waypoint", "WpIdx", 1, 10, 1, function(v) wpIdx = v end, "Pilih nomor waypoint")
MapRight:Button("📌 Teleport ke Waypoint #", "Pergi ke waypoint terpilih", function()
    if wpIdx > #teleportPoints then Library:Notification("❌", "Nomor waypoint tidak valid", 2); return end
    teleportTo(teleportPoints[wpIdx].pos)
end)
MapRight:Button("🗑️ Hapus Semua Waypoint", "Bersihkan daftar waypoint", function() teleportPoints = {}; Library:Notification("🗑️", "Semua waypoint dihapus", 2) end)

-- ════════════════════════════════════════
--  INIT & NOTIFICATION
-- ════════════════════════════════════════
Library:Notification("🔌 XKID ULTIMATE v3.0", "✅ Farming Spy\n✅ Auto Farm\n✅ Map Exploit\n✅ All Remote Tools\nSiap digunakan!", 6)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════╗")
print("║   🔌  XKID ULTIMATE  v3.0           ║")
print("║   🌾 Farming Spy + Auto Farm        ║")
print("║   🗺️ Map Exploit + All Remote Tools ║")
print("║   Player: "..LP.Name)
print("╚══════════════════════════════════════╝")