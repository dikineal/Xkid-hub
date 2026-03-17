--[[
  ╔══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   U L T I M A T E  v3.1          ║
  ║      FARMING SPY FIXED - KHUSUS GAME FARMING       ║
  ╚══════════════════════════════════════════════════════╝
]]

-- ============================================
--  AURORA UI
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
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================
--  WINDOW & TABS
-- ============================================
local Win = Library:Window("🔌 XKID ULTIMATE v3.1", "cpu", "Farming Spy Fixed", false)
Win:TabSection("REMOTE")

local TabScan     = Win:Tab("Scan", "search")
local TabExploit  = Win:Tab("Exploit", "alert-triangle")
local TabSpy      = Win:Tab("Spy", "eye")
local TabHook     = Win:Tab("Hook", "terminal")
local TabBN2      = Win:Tab("BN2", "radio")
local TabFire     = Win:Tab("Fire", "zap")
local TabFarmSpy  = Win:Tab("🌾 Farm Spy", "eye")  -- FIXED!
local TabAutoFarm = Win:Tab("🚜 Auto Farm", "tractor")
local TabMap      = Win:Tab("🗺️ Map", "map")

-- ============================================
--  SCAN LOCATIONS
-- ============================================
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

-- ============================================
--  GLOBAL STATE
-- ============================================
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

-- Farming Spy State (FIXED)
local farmSpyActive = false
local farmSpyHook = nil  -- Ini pake hook, bukan connections biasa
local farmSpyLog = {}
local farmSpyFilter = "Semua"
local farmSpyPage = 1

-- Auto Farm State
local autoFarmActive = false
local autoFarmConn = nil
local farmMode = "Keduanya"
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

-- ============================================
--  UTILITY FUNCTIONS
-- ============================================
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

-- ============================================
--  SCAN FUNCTIONS
-- ============================================
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

-- ============================================
--  AUTO DETECT EXPLOIT
-- ============================================
local CATEGORIES = {
    { name="💰 Economy", prio=1, keys={"givemoney","addmoney","addcash","addcoin","givecoin","addgold","updatecurrency","rewardmoney","earnmoney","collectmoney","getcoin","getmoney","purchase","buycoin","reward","payout","transfer","earn","claim","collect","sell"}, tip="Fire dengan nilai besar (999999 atau -1)" },
    { name="🎁 Item", prio=1, keys={"giveitem","additem","equipitem","spawnitem","dropitem","pickupitem","rewarditem","collectitem","getitem","receiveitem","addtoinventory","giveweapon","addweapon","givegear","unlocktool","getbibit"}, tip="Fire dengan item ID yang diinginkan" },
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

-- ============================================
--  DISPLAY FUNCTION
-- ============================================
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

-- ============================================
--  FARMING SPY - FIXED VERSION (PAKE HOOK)
-- ============================================
local farmingTargets = {}  -- Remote yang akan di-spy

local function detectFarmingAction(remoteName)
    remoteName = remoteName:lower()
    
    if remoteName:find("plant") or remoteName:find("tanam") or remoteName:find("bibit") or remoteName:find("seed") then
        return "🌱 TANAM", 1
    end
    
    if remoteName:find("harvest") or remoteName:find("panen") or remoteName:find("collect") or remoteName:find("petik") then
        return "🌾 PANEN", 2
    end
    
    if remoteName:find("sell") or remoteName:find("jual") then
        return "💰 JUAL", 3
    end
    
    if remoteName:find("get") or remoteName:find("beli") or remoteName:find("buy") or remoteName:find("purchase") then
        return "🛒 BELI", 4
    end
    
    if remoteName:find("lahan") or remoteName:find("field") or remoteName:find("plot") then
        return "🏞️ LAHAN", 5
    end
    
    if remoteName:find("rain") or remoteName:find("hujan") or remoteName:find("weather") or remoteName:find("cuaca") then
        return "🌧️ WEATHER", 6
    end
    
    return nil, nil
end

local function buildFarmingTargets()
    farmingTargets = {}
    
    -- Daftar keyword remote farming
    local farmingKeywords = {
        "Plant", "Tanam", "Harvest", "Panen", "Sell", "Jual",
        "Bibit", "Seed", "Crop", "Lahan", "Field", "Rain", "Hujan",
        "Weather", "Cuaca", "Collect", "Petik", "Get", "Beli"
    }
    
    -- Cari di semua remotes hasil scan
    for _, r in ipairs(allRemotes) do
        local name = r.name
        for _, kw in ipairs(farmingKeywords) do
            if name:find(kw, 1, true) then
                farmingTargets[r.ref] = {
                    name = name,
                    path = r.path
                }
                break
            end
        end
    end
    
    -- Tambah manual dari hasil scan lo
    local manualTargets = {
        "PlantCrop", "HarvestCrop", "SellCrop", "GetBibit",
        "PlantLahanCrop", "LahanUpdate", "ToggleAutoHarvest",
        "RainSync", "SummonRain", "WeatherSync"
    }
    
    for _, targetName in ipairs(manualTargets) do
        local remote = RS:FindFirstChild("Remotes") and 
                      RS.Remotes:FindFirstChild("TutorialRemotes") and 
                      RS.Remotes.TutorialRemotes:FindFirstChild(targetName)
        if remote then
            farmingTargets[remote] = {
                name = targetName,
                path = remote:GetFullName()
            }
        end
    end
    
    return farmingTargets
end

local function startFarmingSpy()
    if farmSpyHook then
        Library:Notification("⚠️", "Farming Spy sudah aktif", 2)
        return
    end
    
    -- Bangun target farming
    buildFarmingTargets()
    
    if not next(farmingTargets) then
        Library:Notification("❌", "Tidak ada remote farming ditemukan!\nScan dulu di tab Scan", 4)
        return false
    end
    
    -- Reset log
    farmSpyLog = {}
    
    -- Pasang hook
    local oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        -- Cek apakah ini remote yang kita targetkan
        local target = farmingTargets[self]
        if target and (method == "FireServer" or method == "InvokeServer") then
            -- Deteksi aksi
            local action, priority = detectFarmingAction(target.name)
            if not action then action = "❓ FARM" end
            
            -- Format argumen
            local argStrs = {}
            for i, a in ipairs(args) do
                table.insert(argStrs, string.format("[%d] %s", i, serializeValue(a, 0)))
            end
            
            -- Format waktu
            local timeStr = os.date("%H:%M:%S")
            
            -- Ekstrak info crop kalo ada
            local cropInfo = ""
            for _, a in ipairs(args) do
                if type(a) == "string" and #a < 30 then
                    cropInfo = a
                    break
                elseif type(a) == "table" then
                    if a.crop then cropInfo = a.crop
                    elseif a.cropName then cropInfo = a.cropName
                    elseif a.seed then cropInfo = a.seed end
                end
            end
            
            -- Buat entry
            local entry = string.format(
                "[%s] %s %s\nCrop: %s\nArgs: %s\nPath: %s",
                timeStr,
                action,
                target.name,
                cropInfo ~= "" and cropInfo or "?",
                table.concat(argStrs, ", "),
                target.path
            )
            
            -- Simpan ke log
            table.insert(farmSpyLog, 1, entry)
            if #farmSpyLog > 50 then
                table.remove(farmSpyLog, #farmSpyLog)
            end
            
            -- Notifikasi (opsional, bisa dimatiin)
            Library:Notification("🌾 FARM", action .. " " .. target.name, 1.5)
        end
        
        return oldNamecall(self, ...)
    end)
    
    farmSpyHook = oldNamecall
    farmSpyActive = true
    
    Library:Notification("🌾 FARMING SPY FIXED", 
        string.format("Memantau %d remote farming\nLakukan tanam/panen sekarang!", 
        #farmingTargets), 5)
    
    return true
end

local function stopFarmingSpy()
    if farmSpyHook then
        -- Kembalikan hook ke semula
        hookmetamethod(game, "__namecall", farmSpyHook)
        farmSpyHook = nil
    end
    farmSpyActive = false
    Library:Notification("🌾 Farming Spy", "OFF", 2)
end

local function showFarmLogs(page)
    if #farmSpyLog == 0 then
        Library:Notification("📭", "Belum ada log farming\nLakukan tanam/panen dulu!", 3)
        return
    end
    
    -- Filter berdasarkan pilihan
    local displayLogs = farmSpyLog
    if farmSpyFilter ~= "Semua" then
        displayLogs = {}
        for _, entry in ipairs(farmSpyLog) do
            if (farmSpyFilter == "Tanam" and entry:find("🌱")) or
               (farmSpyFilter == "Panen" and entry:find("🌾")) or
               (farmSpyFilter == "Jual" and entry:find("💰")) then
                table.insert(displayLogs, entry)
            end
        end
    end
    
    if #displayLogs == 0 then
        Library:Notification("📭", "Tidak ada log dengan filter: " .. farmSpyFilter, 2)
        return
    end
    
    local totalPages = math.ceil(#displayLogs / PAGE_SIZE)
    page = math.max(1, math.min(page, totalPages))
    local startIdx = (page-1)*PAGE_SIZE + 1
    local endIdx = math.min(page*PAGE_SIZE, #displayLogs)
    
    local text = string.format("🌾 FARM SPY [Hal %d/%d]\nFilter: %s | Total: %d\n\n", 
        page, totalPages, farmSpyFilter, #displayLogs)
    
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, displayLogs[i])
    end
    
    Library:Notification("🌾 Farming Spy Log", text, 20)
    farmSpyPage = page
end

local function copyFarmLogs()
    if #farmSpyLog == 0 then
        Library:Notification("❌", "Tidak ada log untuk di-copy", 2)
        return
    end
    
    local text = "=== FARMING SPY LOG ===\n\n"
    for i, entry in ipairs(farmSpyLog) do
        text = text .. string.format("[%d] %s\n\n", i, entry)
    end
    
    doCopy(text)
end

-- ============================================
--  AUTO FARM FUNCTIONS (SEDERHANA)
-- ============================================
local function findPlantRemote()
    for _, r in ipairs(allRemotes) do
        if r.name:find("Plant") or r.name:find("Tanam") then
            return r.ref
        end
    end
    return nil
end

local function findHarvestRemote()
    for _, r in ipairs(allRemotes) do
        if r.name:find("Harvest") or r.name:find("Panen") then
            return r.ref
        end
    end
    return nil
end

local function findSellRemote()
    for _, r in ipairs(allRemotes) do
        if r.name:find("Sell") or r.name:find("Jual") then
            return r.ref
        end
    end
    return nil
end

local function startAutoFarm()
    if autoFarmConn then autoFarmConn:Disconnect() end
    
    local plantRemote = findPlantRemote()
    local harvestRemote = findHarvestRemote()
    local sellRemote = findSellRemote()
    
    autoFarmConn = RunService.Heartbeat:Connect(function()
        if not autoFarmActive then return end
        
        if farmMode == "Tanam" or farmMode == "Keduanya" then
            if plantRemote then
                pcall(function() plantRemote:FireServer(farmCrop, "Lahan1") end)
            end
        end
        
        if farmMode == "Panen" or farmMode == "Keduanya" then
            if harvestRemote then
                pcall(function() harvestRemote:FireServer("Lahan1") end)
            end
        end
        
        if autoSell and sellRemote then
            pcall(function() sellRemote:FireServer("all") end)
        end
        
        task.wait(2)
    end)
end

-- ============================================
--  MAP EXPLOIT FUNCTIONS
-- ============================================
local function teleportTo(position)
    local char = getCharacter()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(position)
        Library:Notification("📌 Teleport", string.format("Ke (%.1f, %.1f, %.1f)", position.X, position.Y, position.Z), 3)
    end
end

local function toggleNoclip(enable)
    noclipActive = enable
    if noclipConn then noclipConn:Disconnect() end
    if enable then
        noclipConn = RunService.Stepped:Connect(function()
            if noclipActive then
                local char = getCharacter()
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
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

-- ============================================
--  BUILD UI - SCAN TAB
-- ============================================
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
        Library:Notification("🔴 RemoteEvent", string.format("%d ditemukan\n⚠️ %d exploit candidate", #allRemotes, #exploitList), 6)
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
        Library:Notification("⚡ Scan Selesai", string.format("Total: %d remote\n🔴 Event: %d | 🔵 Func: %d\n\n⚠️ Exploit: %d total\n🔴 HIGH: %d\n🟡 MED : %d\n🟢 LOW : %d", #allRemotes, #events, #funcs, #exploitList, p1, p2, p3), 12)
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

-- ============================================
--  BUILD UI - EXPLOIT TAB
-- ============================================
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