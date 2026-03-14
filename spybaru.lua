--[[
  ╔══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   R E M O T E  F U L L  v1.0     ║
  ║      Aurora UI  ✦  Mobile  ✦  All Features         ║
  ╚══════════════════════════════════════════════════════╝
  Tab Scan    : Scan semua remote dari semua service
  Tab Exploit : Auto detect + 10 kategori + priority
  Tab Spy     : Incoming OnClientEvent + monitor
  Tab Hook    : Outgoing FireServer __namecall
  Tab BN2     : BridgeNet2 decoder khusus
  Tab Fire    : Fire/Invoke manual + paste dari scan
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
local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local RF                = game:GetService("ReplicatedFirst")
local Workspace         = game:GetService("Workspace")
local LP                = Players.LocalPlayer

-- ════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════
local Win = Library:Window("🔌 XKID REMOTE", "cpu", "v1.0 Full", false)

-- ════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════
Win:TabSection("REMOTE")
local TabScan    = Win:Tab("Scan",    "search")
local TabExploit = Win:Tab("Exploit", "alert-triangle")
local TabSpy     = Win:Tab("Spy",     "eye")
local TabHook    = Win:Tab("Hook",    "terminal")
local TabBN2     = Win:Tab("BN2",     "radio")
local TabFire    = Win:Tab("Fire",    "zap")

-- ════════════════════════════════════════
--  SCAN LOCATIONS — Semua service
-- ════════════════════════════════════════
local SCAN_LOCATIONS = {
    RS,
    RF,
    Workspace,
    LP:WaitForChild("PlayerGui",    3),
    LP:WaitForChild("PlayerScripts",3),
    LP:WaitForChild("Backpack",     3),
    game:GetService("CoreGui"),
}
-- Hapus nil
do
    local clean = {}
    for _, v in ipairs(SCAN_LOCATIONS) do
        if v then table.insert(clean, v) end
    end
    SCAN_LOCATIONS = clean
end

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local allRemotes     = {}
local exploitList    = {}
local spyLog         = {}
local hookLog        = {}
local bn2Log         = {}
local spyConns       = {}
local origNamecall   = nil
local bn2Conn        = nil
local spyOn          = false
local hookOn         = false
local bn2On          = false
local filterKeyword  = ""
local currentPage    = 1
local exploitPage    = 1
local spyPage        = 1
local hookPage       = 1
local bn2Page        = 1
local firePath       = ""
local fireArgs       = ""
local PAGE_SIZE      = 5
local MAX_LOG        = 80

-- ════════════════════════════════════════
--  CLIPBOARD
-- ════════════════════════════════════════
local function doCopy(text)
    local ok = pcall(function() setclipboard(text) end)
    Library:Notification(
        ok and "📋 Copied!" or "❌ Gagal",
        ok and "Berhasil copy ke clipboard!"
           or "setclipboard tidak support", 3)
end

-- ════════════════════════════════════════
--  SERIALIZE
-- ════════════════════════════════════════
local function serializeValue(v, depth)
    depth = depth or 0
    if depth > 4 then return "..." end
    local t = typeof(v)
    if t == "string" then
        if #v <= 4 then
            local hex = ""
            for i = 1, #v do
                hex = hex..string.format("\\x%02X", string.byte(v, i))
            end
            return string.format('STR[%s]', hex)
        end
        return string.format('"%s"', v:sub(1, 60))
    elseif t == "number"  then return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "Vector3" then
        return string.format("V3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
    elseif t == "CFrame"  then
        return string.format("CF(%.2f,%.2f,%.2f)",
            v.Position.X, v.Position.Y, v.Position.Z)
    elseif t == "table"   then
        local parts = {}
        local count = 0
        for k, val in pairs(v) do
            count = count + 1
            if count > 6 then
                table.insert(parts, "..."); break
            end
            table.insert(parts, string.format("[%s]=%s",
                serializeValue(k, depth+1),
                serializeValue(val, depth+1)))
        end
        return "{"..table.concat(parts, ", ").."}"
    elseif t == "Instance" then
        return pcall(function() return v:GetFullName() end)
            and v:GetFullName() or "Instance"
    else
        return "["..t.."]"
    end
end

-- ════════════════════════════════════════
--  CORE — SCAN REMOTE
-- ════════════════════════════════════════
local function scanRemotes(root, targetClass, results, seen)
    seen = seen or {}
    if not root or seen[root] then return end
    seen[root] = true
    local ok, children = pcall(function()
        return root:GetChildren()
    end)
    if not ok then return end
    for _, child in ipairs(children) do
        if child:IsA(targetClass) then
            table.insert(results, {
                name  = child.Name,
                path  = child:GetFullName(),
                rtype = targetClass == "RemoteEvent" and "EVENT" or "FUNC",
                ref   = child,
                cat   = nil,
                prio  = 99,
                tip   = "",
            })
        end
        scanRemotes(child, targetClass, results, seen)
    end
end

local function scanAll(targetClass)
    local results = {}
    local seen    = {}
    for _, loc in ipairs(SCAN_LOCATIONS) do
        scanRemotes(loc, targetClass, results, seen)
    end
    return results
end

local function applyFilter(list, kw)
    if not kw or kw == "" then return list end
    local filtered = {}
    local kl = kw:lower()
    for _, r in ipairs(list) do
        if r.path:lower():find(kl, 1, true)
        or r.name:lower():find(kl, 1, true) then
            table.insert(filtered, r)
        end
    end
    return filtered
end

-- ════════════════════════════════════════
--  AUTO DETECT EXPLOIT
-- ════════════════════════════════════════
local CATEGORIES = {
    { name="💰 Economy",   prio=1,
      keys={"givemoney","addmoney","addcash","addcoin","givecoin","addgold",
            "updatecurrency","rewardmoney","earnmoney","collectmoney",
            "getcoin","getmoney","purchase","buycoin","reward","payout",
            "transfer","earn","claim","collect"},
      tip="Fire dengan nilai besar (999999 atau -1)" },
    { name="🎁 Item",      prio=1,
      keys={"giveitem","additem","equipitem","spawnitem","dropitem",
            "pickupitem","rewarditem","collectitem","getitem","receiveitem",
            "addtoinventory","giveweapon","addweapon","givegear","unlocktool"},
      tip="Fire dengan item ID yang diinginkan" },
    { name="⚔️ Combat",   prio=1,
      keys={"dealdamage","takedamage","killplayer","hitremote","attackevent",
            "damageevent","hitplayer","dealfire","instantkill","overkill"},
      tip="Fire ke target dengan damage tinggi" },
    { name="🔓 Admin",     prio=1,
      keys={"setadmin","giverank","promoteplayer","setrole","givevip",
            "updatepermission","setlevel","givepower","makeadmin",
            "addadmin","setowner","givemod","rank","role","admin","vip"},
      tip="Fire dengan nama player sendiri" },
    { name="🏆 XP/Level",  prio=2,
      keys={"addxp","levelup","updatelevel","completequest","finishmission",
            "addexp","gainxp","rewardxp","questcomplete","missiondone",
            "stageclear","addpoint","updatepoint","addscore"},
      tip="Fire dengan nilai XP/level besar" },
    { name="🚀 Teleport",  prio=2,
      keys={"teleportplayer","movetoposition","setposition","updateposition",
            "warpplayer","tpplayer","setcframe","updatecframe","moveplayer"},
      tip="Fire dengan koordinat tujuan" },
    { name="🛡️ Status",   prio=2,
      keys={"sethealth","addhealth","giveshield","addshield","setspeed",
            "addspeed","givebuff","addbuff","setinvincible","godmode",
            "nohit","heal","regenerate","revive","respawn"},
      tip="Fire untuk ubah status karakter" },
    { name="🔑 Unlock",    prio=2,
      keys={"unlockitem","unlockarea","opendoor","accessroom","opengate",
            "unlockfeature","enablefeature","purchaseaccess","buyaccess",
            "entervip","unlock","open","access"},
      tip="Fire untuk buka area/item terkunci" },
    { name="📊 Data/Save", prio=3,
      keys={"savedata","updatedata","setdata","writedata","syncdata",
            "saveprogress","updateprogress","setstats","updatestats",
            "saveprofile"},
      tip="Hati-hati — bisa corrupt save data" },
    { name="🔧 Utility",   prio=3,
      keys={"notify","notification","message","broadcast","chat",
            "sendmessage","log","track","analytics","announce"},
      tip="Potensi rendah tapi coba saja" },
}

local function detectCategory(remote)
    local nl = remote.name:lower()
    for _, cat in ipairs(CATEGORIES) do
        for _, kw in ipairs(cat.keys) do
            if nl:find(kw, 1, true) then
                return cat.name, cat.prio, cat.tip
            end
        end
    end
    return nil, 99, ""
end

local function runAutoDetect(list)
    local detected = {}
    for _, r in ipairs(list) do
        local catName, prio, tip = detectCategory(r)
        if catName then
            r.cat  = catName
            r.prio = prio
            r.tip  = tip
            table.insert(detected, r)
        end
    end
    table.sort(detected, function(a, b)
        if a.prio ~= b.prio then return a.prio < b.prio end
        return a.name < b.name
    end)
    return detected
end

-- ════════════════════════════════════════
--  DISPLAY — Navigasi halaman
-- ════════════════════════════════════════
local function showPage(list, page, title, isExploit)
    if #list == 0 then
        Library:Notification("📭", "Tidak ada data\nScan dulu!", 3)
        return page
    end
    local totalPages = math.ceil(#list / PAGE_SIZE)
    page = math.max(1, math.min(page, totalPages))
    local startIdx = (page-1)*PAGE_SIZE + 1
    local endIdx   = math.min(page*PAGE_SIZE, #list)

    local text = string.format("📄 Hal %d/%d | Total: %d\n\n",
        page, totalPages, #list)

    for i = startIdx, endIdx do
        local r = list[i]
        if isExploit then
            local prioLabel = r.prio==1 and "🔴HIGH"
                           or r.prio==2 and "🟡MED" or "🟢LOW"
            text = text..string.format(
                "[%d] %s %s\n%s\n[%s] %s\n💡 %s\n\n",
                i, prioLabel, r.cat,
                r.name, r.rtype,
                r.path:match("([^.]+)$") or r.name,
                r.tip)
        else
            text = text..string.format(
                "[%d] [%s] %s\n%s\n\n",
                i, r.rtype, r.name, r.path)
        end
    end

    if totalPages > 1 then
        text = text..string.format("▶ Hal %d/%d",
            math.min(page+1, totalPages), totalPages)
    end

    Library:Notification(
        string.format("%s [%d-%d]", title, startIdx, endIdx),
        text, 18)
    return page
end

-- ════════════════════════════════════════
--  SPY — Incoming OnClientEvent
-- ════════════════════════════════════════
local function detectSpyAction(data)
    local s = serializeValue(data, 0)
    if s:find("cropPos") and s:find("sellPrice") then return "🌾 HARVEST"
    elseif s:find("seedPrice") and s:find("items")  then return "🏪 SHOP DATA"
    elseif s:find("cropName") and s:find("count")   then return "🛒 BELI"
    elseif s:find("coins")                          then return "💰 COINS"
    elseif s:find("success")                        then return "✅ RESPONSE"
    elseif s:find("health") or s:find("damage")     then return "⚔️ COMBAT"
    elseif s:find("rank") or s:find("role")         then return "🏆 RANK"
    else return "❓ UNKNOWN" end
end

local function startSpy()
    for _, c in ipairs(spyConns) do pcall(function() c:Disconnect() end) end
    spyConns = {}
    local events = scanAll("RemoteEvent")
    local count  = 0
    for _, r in ipairs(events) do
        local ok, conn = pcall(function()
            return r.ref.OnClientEvent:Connect(function(...)
                local args    = {...}
                local action  = detectSpyAction(args[1] or args)
                local argStrs = {}
                for _, a in ipairs(args) do
                    table.insert(argStrs, serializeValue(a, 0))
                end
                -- Tandai exploit candidate
                local catName, _, _ = detectCategory(r)
                local flag = catName and ("⚠️ "..catName) or ""
                local entry = string.format(
                    "%s %s\n[%s]\nArgs: %s",
                    flag, action, r.path,
                    table.concat(argStrs, ", "))
                table.insert(spyLog, 1, entry)
                if #spyLog > MAX_LOG then
                    table.remove(spyLog, #spyLog)
                end
            end)
        end)
        if ok and conn then
            table.insert(spyConns, conn)
            count = count + 1
        end
    end
    Library:Notification("👁 Spy ON",
        string.format("Memantau %d RemoteEvent\n⚠️ Exploit ditandai otomatis", count), 5)
    return count
end

local function stopSpy()
    for _, c in ipairs(spyConns) do pcall(function() c:Disconnect() end) end
    spyConns = {}
end

-- ════════════════════════════════════════
--  HOOK — Outgoing FireServer __namecall
-- ════════════════════════════════════════
local function buildTargetSet()
    local set = {}
    for _, r in ipairs(allRemotes) do
        if r.ref then set[r.ref] = true end
    end
    -- Tambah BN2 manual
    local bn2 = RS:FindFirstChild("BridgeNet2")
    if bn2 then
        for _, v in pairs(bn2:GetChildren()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                set[v] = true
            end
        end
    end
    local net = RS:FindFirstChild("Networking")
    if net then
        for _, v in pairs(net:GetChildren()) do
            set[v] = true
        end
    end
    return set
end

local function detectHookAction(args)
    local s = ""
    for _, a in ipairs(args) do s = s..serializeValue(a, 0) end
    if s:find("hitPosition") or s:find("hitPart")   then return "🌱 TANAM"
    elseif s:find("cropName") and s:find("count")   then return "🛒 BELI"
    elseif s:find("cropName")                       then return "🌾 HARVEST"
    elseif s:find("damage") or s:find("hit")        then return "⚔️ COMBAT"
    elseif s:find("EMPTY") or s == ""               then return "📦 KOSONG"
    else return "❓ UNKNOWN" end
end

local function startHook()
    local targetSet = buildTargetSet()
    origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            local isTarget = targetSet[self]
            if not isTarget then
                local ok, path = pcall(function() return self:GetFullName() end)
                if ok then
                    isTarget = path:find("BridgeNet") or path:find("Networking")
                            or path:find("Packet")    or path:find("Remote")
                end
            end
            if isTarget then
                local args = {...}
                local argStrs = {}
                for i, a in ipairs(args) do
                    table.insert(argStrs,
                        string.format("  [%d] %s", i, serializeValue(a, 0)))
                end
                local action = detectHookAction(args)
                local ok, path = pcall(function() return self:GetFullName() end)
                local entry = string.format(
                    "%s [%s]\nMethod: %s\n%s",
                    action,
                    ok and path or "?",
                    method,
                    table.concat(argStrs, "\n"))
                table.insert(hookLog, 1, entry)
                if #hookLog > MAX_LOG then
                    table.remove(hookLog, #hookLog)
                end
            end
        end
        return origNamecall(self, ...)
    end)
    Library:Notification("🔌 Hook ON",
        "FireServer intercepted!\nLakukan aksi di game", 4)
end

local function stopHook()
    if origNamecall then
        pcall(function()
            hookmetamethod(game, "__namecall", origNamecall)
        end)
        origNamecall = nil
    end
end

-- ════════════════════════════════════════
--  BN2 — BridgeNet2 Decoder
-- ════════════════════════════════════════
local function detectBN2Action(data)
    if type(data) ~= "table" then return "❓ NON-TABLE" end
    local s = serializeValue(data, 0)
    if s:find("cropPos") and s:find("sellPrice") then return "🌾 HARVEST incoming"
    elseif s:find("seedPrice") and s:find("items") then return "🏪 SHOP DATA"
    elseif s:find("cropName") and s:find("count")  then return "🛒 BELI response"
    elseif s:find("success")                       then return "✅ SUCCESS response"
    elseif s:find("coins")                         then return "💰 COINS update"
    elseif s:find("\\x06") or s:find("hitPosition") then return "🌱 TANAM outgoing"
    elseif s:find("\\x05") then return "📦 REQUEST \\x05"
    else return "❓ UNKNOWN BN2" end
end

local function startBN2Spy()
    if bn2Conn then pcall(function() bn2Conn:Disconnect() end) end

    local bn2   = RS:FindFirstChild("BridgeNet2")
    local dataRE = bn2 and bn2:FindFirstChild("dataRemoteEvent")
    local metaRE = bn2 and bn2:FindFirstChild("metaRemoteEvent")
    local netRE  = RS:FindFirstChild("Networking")
        and RS.Networking:FindFirstChild("RemoteEvent")

    local targets = {}
    if dataRE then table.insert(targets, dataRE) end
    if metaRE then table.insert(targets, metaRE) end
    if netRE  then table.insert(targets, netRE)  end

    if #targets == 0 then
        Library:Notification("❌ BN2",
            "BridgeNet2 tidak ditemukan\nGame ini mungkin tidak pakai BN2", 4)
        return false
    end

    local conns = {}
    for _, re in ipairs(targets) do
        local ok, conn = pcall(function()
            return re.OnClientEvent:Connect(function(data)
                local action = detectBN2Action(data)
                local raw    = serializeValue(data, 0)
                local entry  = string.format(
                    "%s\n[%s]\n%s",
                    action, re.Name, raw)
                table.insert(bn2Log, 1, entry)
                if #bn2Log > MAX_LOG then
                    table.remove(bn2Log, #bn2Log)
                end
            end)
        end)
        if ok and conn then table.insert(conns, conn) end
    end

    -- Simpan semua koneksi BN2
    bn2Conn = {
        Disconnect = function()
            for _, c in ipairs(conns) do
                pcall(function() c:Disconnect() end)
            end
        end
    }

    Library:Notification("📡 BN2 Spy ON",
        string.format("Monitoring %d BN2 remote\ndataRE + metaRE + Networking", #targets), 4)
    return true
end

local function stopBN2Spy()
    if bn2Conn then
        pcall(function() bn2Conn:Disconnect() end)
        bn2Conn = nil
    end
end

-- ════════════════════════════════════════
--  FIRE REMOTE
-- ════════════════════════════════════════
local function findByPath(path)
    path = path:gsub("^game%.", "")
    local parts = {}
    for p in path:gmatch("[^%.]+") do table.insert(parts, p) end
    local cur = game
    for _, p in ipairs(parts) do
        local found = cur:FindFirstChild(p)
        if not found then return nil end
        cur = found
    end
    return cur
end

local function parseArgs(str)
    local args = {}
    if not str or str == "" then return args end
    for token in str:gmatch("[^,]+") do
        token = token:match("^%s*(.-)%s*$")
        local num = tonumber(token)
        if     num                      then table.insert(args, num)
        elseif token:lower() == "true"  then table.insert(args, true)
        elseif token:lower() == "false" then table.insert(args, false)
        else                                 table.insert(args, token) end
    end
    return args
end

local function doFire(path, argsStr)
    if not path or path == "" then
        Library:Notification("❌", "Path kosong!", 2); return
    end
    local remote = findByPath(path)
    if not remote then
        Library:Notification("❌", "Tidak ditemukan:\n"..path, 4); return
    end
    local args = parseArgs(argsStr)
    if remote:IsA("RemoteEvent") then
        local ok, err = pcall(function()
            remote:FireServer(table.unpack(args))
        end)
        Library:Notification(
            ok and "✅ FireServer" or "❌ Error",
            ok and (remote.Name.."\nArgs: "..(argsStr=="" and "(none)" or argsStr))
               or tostring(err), 4)
    elseif remote:IsA("RemoteFunction") then
        local ok, res = pcall(function()
            return remote:InvokeServer(table.unpack(args))
        end)
        Library:Notification(
            ok and "✅ InvokeServer" or "❌ Error",
            ok and (remote.Name.."\nResult: "..serializeValue(res, 0))
               or tostring(res), 5)
    else
        Library:Notification("❌", "Bukan Remote", 3)
    end
end

-- ════════════════════════════════════════
--  BUILD UI — TAB SCAN
-- ════════════════════════════════════════
local ScanPage  = TabScan:Page("Scan Remote", "search")
local ScanLeft  = ScanPage:Section("🔍 Scanner", "Left")
local ScanRight = ScanPage:Section("📋 Hasil & Copy", "Right")

ScanLeft:TextBox("Filter Nama/Path", "FilterBox", "",
    function(v) filterKeyword = v end, "Kosong = semua")

ScanLeft:Button("🔴 Scan RemoteEvent", "Scan semua RemoteEvent",
    function()
        task.spawn(function()
            Library:Notification("🔍", "Scanning...", 2)
            local r = scanAll("RemoteEvent")
            allRemotes = applyFilter(r, filterKeyword)
            exploitList = runAutoDetect(allRemotes)
            currentPage = 1
            Library:Notification("🔴 RemoteEvent",
                string.format(
                    "%d ditemukan\n⚠️ %d exploit candidate\n\nBuka tab Exploit!",
                    #allRemotes, #exploitList), 6)
        end)
    end)

ScanLeft:Button("🔵 Scan RemoteFunction", "Scan semua RemoteFunction",
    function()
        task.spawn(function()
            Library:Notification("🔍", "Scanning...", 2)
            local r = scanAll("RemoteFunction")
            allRemotes = applyFilter(r, filterKeyword)
            exploitList = runAutoDetect(allRemotes)
            currentPage = 1
            Library:Notification("🔵 RemoteFunction",
                string.format("%d ditemukan\n⚠️ %d exploit candidate",
                    #allRemotes, #exploitList), 6)
        end)
    end)

ScanLeft:Button("⚡ Scan SEMUA + Auto Detect", "Scan Event+Function + detect exploit",
    function()
        task.spawn(function()
            Library:Notification("🔍", "Scanning semua service...", 2)
            local events = scanAll("RemoteEvent")
            local funcs  = scanAll("RemoteFunction")
            local all    = {}
            for _, r in ipairs(events) do table.insert(all, r) end
            for _, r in ipairs(funcs)  do table.insert(all, r) end
            allRemotes  = applyFilter(all, filterKeyword)
            exploitList = runAutoDetect(allRemotes)
            local p1,p2,p3 = 0,0,0
            for _, r in ipairs(exploitList) do
                if r.prio==1 then p1=p1+1
                elseif r.prio==2 then p2=p2+1
                else p3=p3+1 end
            end
            Library:Notification("⚡ Scan Selesai",
                string.format(
                    "Total: %d remote\n"..
                    "🔴 Event: %d | 🔵 Func: %d\n\n"..
                    "⚠️ Exploit: %d total\n"..
                    "🔴 HIGH: %d\n"..
                    "🟡 MED : %d\n"..
                    "🟢 LOW : %d\n\n"..
                    "Buka tab [Exploit]!",
                    #allRemotes, #events, #funcs,
                    #exploitList, p1, p2, p3), 12)
        end)
    end)

ScanRight:Button("📄 Lihat Hasil", "Tampilkan halaman pertama",
    function()
        currentPage = showPage(allRemotes, 1, "🔌 Remote", false)
    end)
ScanRight:Button("▶ Berikutnya", "Halaman berikutnya",
    function()
        currentPage = showPage(allRemotes, currentPage+1, "🔌 Remote", false)
    end)
ScanRight:Button("◀ Sebelumnya", "Halaman sebelumnya",
    function()
        currentPage = showPage(allRemotes, currentPage-1, "🔌 Remote", false)
    end)
ScanRight:Button("📋 Copy Semua Path", "Copy semua remote ke clipboard",
    function()
        if #allRemotes == 0 then
            Library:Notification("❌", "Scan dulu!", 2); return
        end
        local text = string.format("=== SCAN (%d) ===\n", #allRemotes)
        for i, r in ipairs(allRemotes) do
            text = text..string.format("[%d][%s] %s\n", i, r.rtype, r.path)
        end
        doCopy(text)
    end)

local copyIdx = 1
ScanRight:Slider("Nomor Remote", "CopyIdxSlider", 1, 200, 1,
    function(v) copyIdx = v end, "Nomor yang mau di-copy")
ScanRight:Button("📋 Copy Remote #", "Copy 1 remote sesuai nomor",
    function()
        if copyIdx > #allRemotes then
            Library:Notification("❌","Max: "..#allRemotes,2); return
        end
        local r = allRemotes[copyIdx]
        doCopy(string.format("[%s] %s", r.rtype, r.path))
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB EXPLOIT
-- ════════════════════════════════════════
local ExPage  = TabExploit:Page("Exploit Candidates", "alert-triangle")
local ExLeft  = ExPage:Section("⚠️ Kandidat", "Left")
local ExRight = ExPage:Section("📋 Copy & Fire", "Right")

ExLeft:Button("📄 Lihat Semua Exploit", "Tampilkan exploit candidates",
    function()
        exploitPage = showPage(exploitList, 1, "⚠️ Exploit", true)
    end)
ExLeft:Button("▶ Berikutnya", "Halaman berikutnya",
    function()
        exploitPage = showPage(exploitList, exploitPage+1, "⚠️ Exploit", true)
    end)
ExLeft:Button("◀ Sebelumnya", "Halaman sebelumnya",
    function()
        exploitPage = showPage(exploitList, exploitPage-1, "⚠️ Exploit", true)
    end)
ExLeft:Button("🔴 HIGH Priority Saja", "Filter prioritas tinggi",
    function()
        local high = {}
        for _, r in ipairs(exploitList) do
            if r.prio == 1 then table.insert(high, r) end
        end
        showPage(high, 1, "🔴 HIGH", true)
    end)

ExRight:Button("📋 Copy Semua Exploit", "Copy semua exploit ke clipboard",
    function()
        if #exploitList == 0 then
            Library:Notification("❌","Scan dulu!",2); return
        end
        local text = string.format("=== EXPLOIT (%d) ===\n\n", #exploitList)
        for i, r in ipairs(exploitList) do
            local pl = r.prio==1 and "[HIGH]" or r.prio==2 and "[MED]" or "[LOW]"
            text = text..string.format(
                "[%d] %s %s\nKat: %s\nPath: %s\nTipe: %s\nTip: %s\n\n",
                i, pl, r.name, r.cat, r.path, r.rtype, r.tip)
        end
        doCopy(text)
    end)

local exIdx = 1
ExRight:Slider("Nomor Exploit", "ExIdxSlider", 1, 100, 1,
    function(v) exIdx = v end, "Pilih nomor exploit")
ExRight:Button("📋 Copy Exploit #", "Copy 1 exploit sesuai nomor",
    function()
        if exIdx > #exploitList then
            Library:Notification("❌","Max: "..#exploitList,2); return
        end
        local r = exploitList[exIdx]
        doCopy(string.format(
            "[%s][%s] %s\nKat: %s\nPath: %s\nTip: %s",
            r.prio==1 and "HIGH" or r.prio==2 and "MED" or "LOW",
            r.rtype, r.name, r.cat, r.path, r.tip))
    end)
ExRight:Button("🔥 Kirim ke Tab Fire", "Paste path exploit ke Fire",
    function()
        if exIdx > #exploitList then
            Library:Notification("❌","Max: "..#exploitList,2); return
        end
        local r = exploitList[exIdx]
        firePath = r.path:gsub("^game%.","")
        Library:Notification("🔥 Siap Fire",
            string.format("%s\n%s\n💡 %s\n\nBuka tab Fire!", r.name, r.cat, r.tip), 6)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB SPY
-- ════════════════════════════════════════
local SpyPage  = TabSpy:Page("Remote Spy", "eye")
local SpyLeft  = SpyPage:Section("👁 Monitor", "Left")
local SpyRight = SpyPage:Section("📋 Log", "Right")

SpyLeft:Toggle("👁 Spy Incoming", "SpyToggle", false,
    "Monitor semua OnClientEvent",
    function(v)
        spyOn = v
        if v then startSpy()
        else stopSpy(); Library:Notification("👁 Spy","OFF",2) end
    end)
SpyLeft:Button("🔄 Restart Spy", "Scan ulang & restart",
    function()
        if spyOn then
            stopSpy(); task.wait(0.2); startSpy()
        else Library:Notification("❌","Aktifkan Spy dulu",2) end
    end)
SpyLeft:Button("🗑 Clear Log", "Hapus log spy",
    function() spyLog={}; Library:Notification("🗑","Cleared",2) end)
SpyLeft:Paragraph("Info",
    "Monitor server → client\n\n"..
    "⚠️ Remote exploit\nditandai otomatis\n\n"..
    "Mainkan game\n→ lihat log")

SpyRight:Button("📄 Lihat Log", "Tampilkan log spy",
    function()
        if #spyLog == 0 then
            Library:Notification("📭","Belum ada log",2); return
        end
        local total = math.ceil(#spyLog/PAGE_SIZE)
        local text  = string.format("📄 Log 1/%d (%d total)\n\n", total, #spyLog)
        for i = 1, math.min(PAGE_SIZE, #spyLog) do
            text = text..string.format("[%d] %s\n\n", i, spyLog[i])
        end
        Library:Notification("👁 Spy Log", text, 18)
        spyPage = 1
    end)
SpyRight:Button("▶ Log Berikutnya", "Halaman log berikutnya",
    function()
        spyPage = spyPage + 1
        local total = math.ceil(#spyLog/PAGE_SIZE)
        if spyPage > total then spyPage = total end
        local startIdx = (spyPage-1)*PAGE_SIZE+1
        local endIdx   = math.min(spyPage*PAGE_SIZE, #spyLog)
        local text = string.format("📄 Log Hal %d/%d\n\n", spyPage, total)
        for i = startIdx, endIdx do
            text = text..string.format("[%d] %s\n\n", i, spyLog[i])
        end
        Library:Notification("👁 Spy Log", text, 18)
    end)
SpyRight:Button("📋 Copy Log Spy", "Copy semua log ke clipboard",
    function()
        if #spyLog == 0 then
            Library:Notification("❌","Belum ada log",2); return
        end
        local text = string.format("=== SPY LOG (%d) ===\n\n", #spyLog)
        for i, e in ipairs(spyLog) do
            text = text..string.format("[%d] %s\n\n", i, e)
        end
        doCopy(text)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB HOOK
-- ════════════════════════════════════════
local HookPage  = TabHook:Page("FireServer Hook", "terminal")
local HookLeft  = HookPage:Section("🔌 Hook Control", "Left")
local HookRight = HookPage:Section("📋 Log", "Right")

HookLeft:Toggle("🔌 Hook FireServer", "HookToggle", false,
    "Intercept semua FireServer outgoing",
    function(v)
        hookOn = v
        if v then
            local ok, err = pcall(startHook)
            if not ok then
                Library:Notification("❌ Error",
                    "hookmetamethod tidak support!\n"..tostring(err), 5)
                hookOn = false
            end
        else
            stopHook()
            Library:Notification("🔌 Hook","OFF",2)
        end
    end)
HookLeft:Button("🗑 Clear Hook Log", "Hapus log hook",
    function() hookLog={}; Library:Notification("🗑","Cleared",2) end)
HookLeft:Paragraph("Panduan",
    "Hook intercept:\nClient → Server\n\n"..
    "Lakukan aksi:\n🌱 Tanam\n🛒 Beli\n🌾 Panen\n⚔️ Attack\n\n"..
    "Lihat log →\nketahui packet")

HookRight:Button("📄 Lihat Log", "Tampilkan log hook",
    function()
        if #hookLog == 0 then
            Library:Notification("📭","Belum ada log\nLakukan aksi dulu!",3); return
        end
        local text = string.format("📄 Hook Log (%d)\n\n", #hookLog)
        for i = 1, math.min(PAGE_SIZE, #hookLog) do
            text = text..string.format("[%d] %s\n\n", i, hookLog[i])
        end
        Library:Notification("🔌 Hook Log", text, 18)
        hookPage = 1
    end)
HookRight:Button("▶ Log Berikutnya","Halaman berikutnya",
    function()
        hookPage = hookPage + 1
        local total = math.ceil(#hookLog/PAGE_SIZE)
        if hookPage > total then hookPage = total end
        local si = (hookPage-1)*PAGE_SIZE+1
        local ei = math.min(hookPage*PAGE_SIZE, #hookLog)
        local text = string.format("📄 Hal %d/%d\n\n", hookPage, total)
        for i = si, ei do
            text = text..string.format("[%d] %s\n\n", i, hookLog[i])
        end
        Library:Notification("🔌 Hook Log", text, 18)
    end)
HookRight:Button("📋 Copy Log Hook","Copy semua hook log",
    function()
        if #hookLog == 0 then
            Library:Notification("❌","Belum ada log",2); return
        end
        local text = string.format("=== HOOK LOG (%d) ===\n\n", #hookLog)
        for i, e in ipairs(hookLog) do
            text = text..string.format("[%d] %s\n\n", i, e)
        end
        doCopy(text)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB BN2
-- ════════════════════════════════════════
local BN2Page  = TabBN2:Page("BridgeNet2", "radio")
local BN2Left  = BN2Page:Section("📡 BN2 Spy", "Left")
local BN2Right = BN2Page:Section("📋 Log", "Right")

BN2Left:Toggle("📡 BN2 Spy", "BN2Toggle", false,
    "Monitor BridgeNet2 dataRemoteEvent",
    function(v)
        bn2On = v
        if v then
            local ok = startBN2Spy()
            if not ok then bn2On = false end
        else
            stopBN2Spy()
            Library:Notification("📡 BN2","OFF",2)
        end
    end)
BN2Left:Button("🗑 Clear BN2 Log","Hapus log BN2",
    function() bn2Log={}; Library:Notification("🗑","Cleared",2) end)
BN2Left:Paragraph("Info BN2",
    "BridgeNet2 =\nFramework yang bungkus\nsemua remote jadi 1\n\n"..
    "Identifier key:\n\\x05 = Beli/Request\n\\x06 = Tanam\n"..
    "\\x0D = Response\n\\x0F = Harvest data\n\\x04 = Coins update\n\n"..
    "Untuk game lain\nidentifier bisa beda!")

BN2Right:Button("📄 Lihat Log BN2","Tampilkan log BN2",
    function()
        if #bn2Log == 0 then
            Library:Notification("📭","Belum ada log\nLakukan aksi dulu!",3); return
        end
        local text = string.format("📄 BN2 Log (%d)\n\n", #bn2Log)
        for i = 1, math.min(PAGE_SIZE, #bn2Log) do
            text = text..string.format("[%d] %s\n\n", i, bn2Log[i])
        end
        Library:Notification("📡 BN2 Log", text, 18)
        bn2Page = 1
    end)
BN2Right:Button("▶ Log Berikutnya","Halaman berikutnya",
    function()
        bn2Page = bn2Page + 1
        local total = math.ceil(#bn2Log/PAGE_SIZE)
        if bn2Page > total then bn2Page = total end
        local si = (bn2Page-1)*PAGE_SIZE+1
        local ei = math.min(bn2Page*PAGE_SIZE, #bn2Log)
        local text = string.format("📄 Hal %d/%d\n\n", bn2Page, total)
        for i = si, ei do
            text = text..string.format("[%d] %s\n\n", i, bn2Log[i])
        end
        Library:Notification("📡 BN2 Log", text, 18)
    end)
BN2Right:Button("📋 Copy BN2 Log","Copy semua log BN2",
    function()
        if #bn2Log == 0 then
            Library:Notification("❌","Belum ada log",2); return
        end
        local text = string.format("=== BN2 LOG (%d) ===\n\n", #bn2Log)
        for i, e in ipairs(bn2Log) do
            text = text..string.format("[%d] %s\n\n", i, e)
        end
        doCopy(text)
    end)
BN2Right:Button("📋 Copy Log HARVEST","Filter & copy harvest saja",
    function()
        local filtered = {}
        for _, e in ipairs(bn2Log) do
            if e:find("HARVEST") then table.insert(filtered, e) end
        end
        if #filtered == 0 then
            Library:Notification("❌","Tidak ada log harvest",2); return
        end
        local text = string.format("=== BN2 HARVEST (%d) ===\n\n", #filtered)
        for i, e in ipairs(filtered) do
            text = text..string.format("[%d] %s\n\n", i, e)
        end
        doCopy(text)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB FIRE
-- ════════════════════════════════════════
local FirePage  = TabFire:Page("Fire Remote", "zap")
local FireLeft  = FirePage:Section("🔥 Fire / Invoke", "Left")
local FireRight = FirePage:Section("ℹ Panduan", "Right")

FireLeft:TextBox("Path Remote", "FirePathBox", "",
    function(v) firePath = v end,
    "Contoh: ReplicatedStorage.Remotes.X")
FireLeft:TextBox("Argumen (pisah koma)", "FireArgsBox", "",
    function(v) fireArgs = v end,
    "Contoh: Hello, 123, true")
FireLeft:Button("🔥 Fire / Invoke", "Kirim remote ke server",
    function() doFire(firePath, fireArgs) end)

local pasteIdx = 1
FireLeft:Slider("Nomor dari Scan", "PasteSlider", 1, 200, 1,
    function(v) pasteIdx = v end, "Nomor remote dari tab Scan")
FireLeft:Button("📋 Paste dari Scan", "Isi path dari hasil scan",
    function()
        if #allRemotes == 0 then
            Library:Notification("❌","Scan dulu!",3); return
        end
        if pasteIdx > #allRemotes then
            Library:Notification("❌","Max: "..#allRemotes,2); return
        end
        local r = allRemotes[pasteIdx]
        firePath = r.path:gsub("^game%.","")
        Library:Notification("📋 Paste",
            string.format("[%s] %s\nPath siap!", r.rtype, r.name), 4)
    end)

FireRight:Paragraph("Cara Pakai",
    "1. Scan → Exploit\n"..
    "   → Kirim ke Fire\n\n"..
    "2. Atau Scan → Paste\n"..
    "   dari nomor\n\n"..
    "3. Isi argumen\n\n"..
    "4. 🔥 Fire!")
FireRight:Paragraph("Format Argumen",
    "String  → Hello\n"..
    "Number  → 123\n"..
    "Bool    → true/false\n\n"..
    "Multiple:\n"..
    "Hello, 123, true\n\n"..
    "Tips per kategori:\n"..
    "Economy → 999999\n"..
    "Item    → nama item\n"..
    "Admin   → nama kamu")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("🔌 XKID Remote Full v1.0",
    "Scan · Exploit · Spy\nHook · BN2 · Fire\nSiap digunakan!", 5)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════╗")
print("║   🔌  XKID REMOTE FULL  v1.0        ║")
print("║   Scan·Exploit·Spy·Hook·BN2·Fire    ║")
print("║   Player: "..LP.Name)
print("╚══════════════════════════════════════╝")
