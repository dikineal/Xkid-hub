--[[
  ╔══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   R E M O T E  v3.0  🔌          ║
  ║      Aurora UI  ✦  Auto Exploit Detector           ║
  ╚══════════════════════════════════════════════════════╝
  Fitur:
  [1] Scan + Auto Detect   — Kategorikan remote otomatis
  [2] Exploit Candidates   — Remote yang berpotensi exploit
  [3] Remote Spy           — Monitor fire real-time + log
  [4] Fire Remote          — FireServer / InvokeServer
  [5] Copy hasil           — setclipboard() ke clipboard HP
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst   = game:GetService("ReplicatedFirst")
local Workspace         = game:GetService("Workspace")
local LP                = Players.LocalPlayer

-- ════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════
local Win = Library:Window("🔌 XKID REMOTE", "cpu", "v3.0 Detector", false)

-- ════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════
Win:TabSection("REMOTE")
local TabScan    = Win:Tab("Scan",    "search")
local TabExploit = Win:Tab("Exploit", "alert-triangle")
local TabSpy     = Win:Tab("Spy",     "eye")
local TabFire    = Win:Tab("Fire",    "zap")

-- ════════════════════════════════════════
--  KATEGORI EXPLOIT
--  Setiap kategori punya:
--  - keywords : kata kunci nama remote
--  - priority : 1=Tinggi 2=Sedang 3=Rendah
--  - desc     : keterangan
--  - tip      : saran exploit
-- ════════════════════════════════════════
local CATEGORIES = {
    {
        name     = "💰 Economy",
        priority = 1,
        keywords = {
            "givemoney","addmoney","addcash","addcoin","givecoin",
            "addgold","givegold","updatecurrency","rewardmoney",
            "earnmoney","collectmoney","getcoin","getmoney",
            "purchase","buycoin","reward","payout","transfer",
        },
        tip = "Coba fire dengan nilai besar\n(999999 atau -1)",
    },
    {
        name     = "🎁 Item / Inventory",
        priority = 1,
        keywords = {
            "giveitem","additem","equipitem","spawnitem",
            "dropitem","pickupitem","rewarditem","collectitem",
            "getitem","receiveitem","addtoinventory","giveweapon",
            "addweapon","givegear","addgear","unlocktool",
        },
        tip = "Fire dengan item ID yang diinginkan",
    },
    {
        name     = "⚔️ Combat / Damage",
        priority = 1,
        keywords = {
            "dealdamage","takedamage","killplayer","hitremote",
            "attackevent","damageevent","hitplayer","dealfire",
            "dealexplosion","instantkill","overkill",
        },
        tip = "Fire ke target player dengan damage tinggi",
    },
    {
        name     = "🔓 Admin / Privilege",
        priority = 1,
        keywords = {
            "setadmin","giverank","promoteplayer","setrole",
            "givevip","updatepermission","setlevel","givepower",
            "makeadmin","addadmin","setowner","givemod",
        },
        tip = "Fire dengan nama player sendiri",
    },
    {
        name     = "🏆 Progress / XP",
        priority = 2,
        keywords = {
            "addxp","levelup","updatelevel","completequest",
            "finishmission","addexp","gainxp","rewardxp",
            "questcomplete","missiondone","stageclear",
            "addpoint","updatepoint","addscore",
        },
        tip = "Fire dengan nilai XP/level besar",
    },
    {
        name     = "🚀 Teleport / Position",
        priority = 2,
        keywords = {
            "teleportplayer","movetoposition","setposition",
            "updateposition","warpplayer","tpplayer",
            "setcframe","updatecframe","moveplayer",
        },
        tip = "Fire dengan koordinat tujuan",
    },
    {
        name     = "🛡️ Status / Buff",
        priority = 2,
        keywords = {
            "sethealth","addhealth","giveshield","addshield",
            "setspeed","addspeed","givebuff","addbuff",
            "setinvincible","godmode","nohit","heal",
            "regenerate","revive","respawn",
        },
        tip = "Fire untuk ubah status karakter",
    },
    {
        name     = "🔑 Unlock / Access",
        priority = 2,
        keywords = {
            "unlockitem","unlockarea","opendoor","accessroom",
            "opengate","unlockfeature","enablefeature",
            "purchaseaccess","buyaccess","entervip",
        },
        tip = "Fire untuk buka area/item terkunci",
    },
    {
        name     = "📊 Data / Save",
        priority = 3,
        keywords = {
            "savedata","updatedata","setdata","writedata",
            "syncdata","saveprogress","updateprogress",
            "setstats","updatestats","saveprofile",
        },
        tip = "Hati-hati — bisa corrupt save data",
    },
    {
        name     = "🔧 Utility / Other",
        priority = 3,
        keywords = {
            "notify","notification","message","broadcast",
            "chat","sendmessage","log","track","analytics",
        },
        tip = "Potensi rendah tapi coba saja",
    },
}

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local allRemotes      = {}   -- semua remote hasil scan
local exploitList     = {}   -- remote yang terdeteksi exploit
local currentPage     = 1
local exploitPage     = 1
local PAGE_SIZE       = 6
local filterKeyword   = ""
local spyConns        = {}
local spyLog          = {}
local spyOn           = false
local firePath        = ""
local fireArgs        = ""
local pasteIndex      = 1
local copyIndex       = 1

local scanLocations = {
    Workspace,
    ReplicatedStorage,
    ReplicatedFirst,
}

-- ════════════════════════════════════════
--  CLIPBOARD
-- ════════════════════════════════════════
local function copyToClipboard(text)
    local ok = pcall(function() setclipboard(text) end)
    Library:Notification(
        ok and "📋 Copied!" or "❌ Gagal",
        ok and "Berhasil copy ke clipboard"
           or "Executor tidak support setclipboard", 3)
end

-- ════════════════════════════════════════
--  CORE — SCAN
-- ════════════════════════════════════════
local function scanRemotes(root, targetClass, results)
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA(targetClass) then
            table.insert(results, {
                name  = child.Name,
                path  = child:GetFullName(),
                rtype = targetClass == "RemoteEvent" and "EVENT" or "FUNC",
                ref   = child,
                cat   = nil,   -- diisi oleh detector
                prio  = 99,    -- default prioritas rendah
                tip   = "",
            })
        end
        scanRemotes(child, targetClass, results)
    end
end

local function scanAll(targetClass)
    local results = {}
    for _, loc in ipairs(scanLocations) do
        scanRemotes(loc, targetClass, results)
    end
    return results
end

local function applyFilter(list, keyword)
    if not keyword or keyword == "" then return list end
    local filtered = {}
    local kl = keyword:lower()
    for _, r in ipairs(list) do
        if r.path:lower():find(kl, 1, true)
        or r.name:lower():find(kl, 1, true) then
            table.insert(filtered, r)
        end
    end
    return filtered
end

-- ════════════════════════════════════════
--  AUTO DETECT — Kategorikan remote
-- ════════════════════════════════════════
local function detectCategory(remote)
    local nl = remote.name:lower()
    for _, cat in ipairs(CATEGORIES) do
        for _, kw in ipairs(cat.keywords) do
            -- Cek apakah nama remote mengandung keyword
            if nl:find(kw, 1, true) then
                return cat.name, cat.priority, cat.tip
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
    -- Sort: prioritas tinggi dulu, lalu nama
    table.sort(detected, function(a, b)
        if a.prio ~= b.prio then return a.prio < b.prio end
        return a.name < b.name
    end)
    return detected
end

-- ════════════════════════════════════════
--  DISPLAY — Halaman
-- ════════════════════════════════════════
local function showPage(list, page, title)
    if #list == 0 then
        Library:Notification("⚠️", "Tidak ada remote ditemukan", 3)
        return
    end
    local totalPages = math.ceil(#list / PAGE_SIZE)
    page = math.max(1, math.min(page, totalPages))

    local startIdx = (page - 1) * PAGE_SIZE + 1
    local endIdx   = math.min(page * PAGE_SIZE, #list)

    local text = string.format(
        "📄 Hal %d/%d  |  Total: %d\n\n", page, totalPages, #list)

    for i = startIdx, endIdx do
        local r = list[i]
        if r.cat then
            -- Exploit list: tampil kategori + tip
            text = text .. string.format(
                "[%d] %s\n%s\n[%s] %s\n💡 %s\n\n",
                i, r.cat, r.name, r.rtype, r.path, r.tip)
        else
            -- Normal list: nama + path + tipe
            text = text .. string.format(
                "[%d] [%s] %s\n%s\n\n",
                i, r.rtype, r.name, r.path)
        end
    end

    if totalPages > 1 then
        text = text .. string.format("▶ Hal %d/%d tersedia",
            math.min(page+1, totalPages), totalPages)
    end

    Library:Notification(
        string.format("%s [%d-%d]", title, startIdx, endIdx),
        text, 15)

    return page
end

-- ════════════════════════════════════════
--  SPY
-- ════════════════════════════════════════
local function startSpy()
    local events = scanAll("RemoteEvent")
    local count  = 0
    spyLog = {}

    for _, r in ipairs(events) do
        local ok, conn = pcall(function()
            return r.ref.OnClientEvent:Connect(function(...)
                local args = {...}
                local argStr = ""
                for j, a in ipairs(args) do
                    argStr = argStr .. tostring(a)
                    if j < #args then argStr = argStr .. ", " end
                end
                -- Cek apakah remote ini terdeteksi exploit
                local catName, _, _ = detectCategory(r)
                local flag = catName and ("⚠️ " .. catName) or ""
                local entry = string.format(
                    "%s\n[%s]\nArgs: %s",
                    flag, r.path,
                    argStr == "" and "(none)" or argStr)
                table.insert(spyLog, 1, entry)
                if #spyLog > 50 then table.remove(spyLog, #spyLog) end
            end)
        end)
        if ok and conn then
            table.insert(spyConns, conn)
            count = count + 1
        end
    end
    Library:Notification("👁 Spy ON",
        string.format("Memantau %d RemoteEvent\n⚠️ Remote exploit ditandai otomatis", count), 5)
    return count
end

local function stopSpy()
    for _, c in ipairs(spyConns) do pcall(function() c:Disconnect() end) end
    spyConns = {}
end

local function showSpyLog(page)
    if #spyLog == 0 then
        Library:Notification("👁 Log", "Belum ada event ter-fire", 3); return
    end
    local totalPages = math.ceil(#spyLog / PAGE_SIZE)
    page = math.max(1, math.min(page or 1, totalPages))
    local startIdx = (page-1)*PAGE_SIZE+1
    local endIdx   = math.min(page*PAGE_SIZE, #spyLog)
    local text = string.format("📄 Log Hal %d/%d\n\n", page, totalPages)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, spyLog[i])
    end
    Library:Notification("👁 Spy Log", text, 15)
    return page
end

-- ════════════════════════════════════════
--  FIRE
-- ════════════════════════════════════════
local function findRemoteByPath(path)
    path = path:gsub("^game%.", "")
    local parts = {}
    for part in path:gmatch("[^%.]+") do table.insert(parts, part) end
    local current = game
    for _, part in ipairs(parts) do
        local found = current:FindFirstChild(part)
        if not found then return nil end
        current = found
    end
    return current
end

local function parseArgs(argsStr)
    local args = {}
    if not argsStr or argsStr == "" then return args end
    for token in argsStr:gmatch("[^,]+") do
        token = token:match("^%s*(.-)%s*$")
        local num = tonumber(token)
        if num then table.insert(args, num)
        elseif token:lower() == "true"  then table.insert(args, true)
        elseif token:lower() == "false" then table.insert(args, false)
        else table.insert(args, token) end
    end
    return args
end

local function fireRemote(path, argsStr)
    if not path or path == "" then
        Library:Notification("❌", "Path kosong!", 2); return
    end
    local remote = findRemoteByPath(path)
    if not remote then
        Library:Notification("❌", "Tidak ditemukan:\n"..path, 4); return
    end
    local args = parseArgs(argsStr)
    if remote:IsA("RemoteEvent") then
        local ok, err = pcall(function() remote:FireServer(table.unpack(args)) end)
        Library:Notification(
            ok and "✅ FireServer" or "❌ Error",
            ok and (remote.Name.."\nArgs: "..(argsStr=="" and "(none)" or argsStr))
               or tostring(err), 4)
    elseif remote:IsA("RemoteFunction") then
        local ok, res = pcall(function() return remote:InvokeServer(table.unpack(args)) end)
        Library:Notification(
            ok and "✅ InvokeServer" or "❌ Error",
            ok and (remote.Name.."\nResult: "..tostring(res)) or tostring(res), 5)
    else
        Library:Notification("❌", "Bukan Remote", 3)
    end
end

-- ════════════════════════════════════════
--  BUILD UI — TAB SCAN
-- ════════════════════════════════════════
local ScanPage  = TabScan:Page("Scan Remote", "search")
local ScanLeft  = ScanPage:Section("🔍 Scanner", "Left")
local ScanRight = ScanPage:Section("📋 Hasil", "Right")

ScanLeft:TextBox("Filter", "FilterBox", "",
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
                string.format("%d ditemukan\n⚠️ %d exploit candidate\n\nLihat tab Exploit!",
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

ScanLeft:Button("⚡ Scan SEMUA + Auto Detect", "Scan semua & deteksi exploit otomatis",
    function()
        task.spawn(function()
            Library:Notification("🔍", "Scanning + detecting...", 2)
            local events = scanAll("RemoteEvent")
            local funcs  = scanAll("RemoteFunction")
            local all    = {}
            for _, r in ipairs(events) do table.insert(all, r) end
            for _, r in ipairs(funcs)  do table.insert(all, r) end
            allRemotes  = applyFilter(all, filterKeyword)
            exploitList = runAutoDetect(allRemotes)

            -- Hitung per prioritas
            local p1, p2, p3 = 0, 0, 0
            for _, r in ipairs(exploitList) do
                if r.prio == 1 then p1 = p1+1
                elseif r.prio == 2 then p2 = p2+1
                else p3 = p3+1 end
            end

            Library:Notification("⚡ Scan Selesai",
                string.format(
                    "Total Remote: %d\n"..
                    "🔴 Event: %d | 🔵 Func: %d\n\n"..
                    "⚠️ Exploit Candidate: %d\n"..
                    "🔴 Prioritas Tinggi : %d\n"..
                    "🟡 Prioritas Sedang : %d\n"..
                    "🟢 Prioritas Rendah : %d\n\n"..
                    "Buka tab [Exploit] sekarang!",
                    #allRemotes, #events, #funcs,
                    #exploitList, p1, p2, p3), 12)
        end)
    end)

-- Navigasi semua remote
ScanRight:Button("📄 Lihat Semua Remote", "Tampilkan semua hasil scan",
    function()
        currentPage = showPage(allRemotes, 1, "🔌 Remote") or 1
    end)

ScanRight:Button("▶ Halaman Berikutnya", "Halaman berikutnya",
    function()
        currentPage = showPage(allRemotes, currentPage+1, "🔌 Remote") or currentPage
    end)

ScanRight:Button("◀ Halaman Sebelumnya", "Halaman sebelumnya",
    function()
        currentPage = showPage(allRemotes, currentPage-1, "🔌 Remote") or currentPage
    end)

ScanRight:Button("📋 Copy Semua Path", "Copy semua remote ke clipboard",
    function()
        if #allRemotes == 0 then
            Library:Notification("❌", "Scan dulu!", 2); return
        end
        local text = string.format("=== XKID REMOTE SCAN (%d) ===\n", #allRemotes)
        for i, r in ipairs(allRemotes) do
            text = text..string.format("[%d][%s] %s\n", i, r.rtype, r.path)
        end
        copyToClipboard(text)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB EXPLOIT
-- ════════════════════════════════════════
local ExPage  = TabExploit:Page("Exploit Candidates", "alert-triangle")
local ExLeft  = ExPage:Section("⚠️ Kandidat Exploit", "Left")
local ExRight = ExPage:Section("📋 Copy & Detail", "Right")

ExLeft:Button("📄 Lihat Exploit Candidates", "Tampilkan remote yang berpotensi exploit",
    function()
        if #exploitList == 0 then
            Library:Notification("⚠️", "Scan dulu di tab Scan!\nTekan Scan SEMUA", 3); return
        end
        exploitPage = showPage(exploitList, 1, "⚠️ Exploit") or 1
    end)

ExLeft:Button("▶ Halaman Berikutnya", "Halaman exploit berikutnya",
    function()
        exploitPage = showPage(exploitList, exploitPage+1, "⚠️ Exploit") or exploitPage
    end)

ExLeft:Button("◀ Halaman Sebelumnya", "Halaman exploit sebelumnya",
    function()
        exploitPage = showPage(exploitList, exploitPage-1, "⚠️ Exploit") or exploitPage
    end)

ExLeft:Button("🔴 Lihat Prioritas Tinggi Saja", "Filter hanya yang prioritas tinggi",
    function()
        if #exploitList == 0 then
            Library:Notification("❌", "Scan dulu!", 2); return
        end
        local high = {}
        for _, r in ipairs(exploitList) do
            if r.prio == 1 then table.insert(high, r) end
        end
        if #high == 0 then
            Library:Notification("⚠️", "Tidak ada prioritas tinggi", 3); return
        end
        showPage(high, 1, "🔴 High Priority")
    end)

ExRight:Button("📋 Copy Semua Exploit", "Copy semua exploit candidate ke clipboard",
    function()
        if #exploitList == 0 then
            Library:Notification("❌", "Scan dulu!", 2); return
        end
        local text = string.format(
            "=== XKID EXPLOIT CANDIDATES (%d) ===\n\n", #exploitList)
        for i, r in ipairs(exploitList) do
            local pLabel = r.prio==1 and "[HIGH]" or r.prio==2 and "[MED]" or "[LOW]"
            text = text..string.format(
                "[%d] %s %s\nKategori: %s\nPath: %s\nTipe: %s\nTip: %s\n\n",
                i, pLabel, r.name, r.cat, r.path, r.rtype, r.tip)
        end
        copyToClipboard(text)
    end)

-- Copy by nomor
local exCopyIdx = 1
ExRight:Slider("Nomor Exploit", "ExCopySlider", 1, 100, 1,
    function(v) exCopyIdx = v end, "Nomor dari daftar exploit")

ExRight:Button("📋 Copy Exploit #", "Copy 1 exploit sesuai nomor",
    function()
        if #exploitList == 0 then
            Library:Notification("❌", "Scan dulu!", 2); return
        end
        if exCopyIdx > #exploitList then
            Library:Notification("❌", "Max: "..#exploitList, 2); return
        end
        local r = exploitList[exCopyIdx]
        local text = string.format(
            "[%s] %s\nKategori: %s\nPath: %s\nTipe: %s\nTip: %s",
            r.prio==1 and "HIGH" or r.prio==2 and "MED" or "LOW",
            r.name, r.cat, r.path, r.rtype, r.tip)
        copyToClipboard(text)
    end)

ExRight:Button("🔥 Kirim ke Tab Fire", "Paste path exploit ke tab Fire",
    function()
        if #exploitList == 0 then
            Library:Notification("❌", "Scan dulu!", 2); return
        end
        if exCopyIdx > #exploitList then
            Library:Notification("❌", "Max: "..#exploitList, 2); return
        end
        local r = exploitList[exCopyIdx]
        firePath = r.path:gsub("^game%.", "")
        Library:Notification("🔥 Siap di-Fire",
            string.format("%s\n%s\n\n💡 %s\n\nBuka tab Fire!", r.name, r.cat, r.tip), 8)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB SPY
-- ════════════════════════════════════════
local SpyPage  = TabSpy:Page("Remote Spy", "eye")
local SpyLeft  = SpyPage:Section("👁 Monitor", "Left")
local SpyRight = SpyPage:Section("📋 Log", "Right")

local spyLogPage = 1

SpyLeft:Toggle("Remote Spy", "SpyToggle", false,
    "Monitor semua RemoteEvent real-time",
    function(v)
        spyOn = v
        if v then startSpy() else stopSpy()
            Library:Notification("👁 Spy", "OFF", 2)
        end
    end)

SpyLeft:Button("🔄 Restart Spy", "Scan ulang & restart spy",
    function()
        if spyOn then
            stopSpy(); task.wait(0.2); startSpy()
        else
            Library:Notification("❌", "Aktifkan Spy dulu", 2)
        end
    end)

SpyLeft:Button("🗑 Clear Log", "Hapus semua log",
    function() spyLog = {}; Library:Notification("🗑", "Log dihapus", 2) end)

SpyLeft:Paragraph("Info",
    "⚠️ Remote exploit\nditandai otomatis\ndi log spy\n\n"..
    "Mainkan game →\nlihat event yang\nter-fire")

SpyRight:Button("📄 Lihat Log", "Tampilkan log spy",
    function()
        spyLogPage = showSpyLog(1) or 1
    end)

SpyRight:Button("▶ Log Berikutnya", "Halaman log berikutnya",
    function()
        spyLogPage = showSpyLog(spyLogPage+1) or spyLogPage
    end)

SpyRight:Button("📋 Copy Log", "Copy semua log ke clipboard",
    function()
        if #spyLog == 0 then
            Library:Notification("❌", "Belum ada log", 2); return
        end
        local text = string.format("=== XKID SPY LOG (%d) ===\n\n", #spyLog)
        for i, entry in ipairs(spyLog) do
            text = text..string.format("[%d] %s\n\n", i, entry)
        end
        copyToClipboard(text)
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
    function() fireRemote(firePath, fireArgs) end)

local pasteIdx = 1
FireLeft:Slider("Nomor dari Scan", "PasteSlider", 1, 100, 1,
    function(v) pasteIdx = v end, "Nomor remote dari tab Scan")

FireLeft:Button("📋 Paste dari Scan", "Isi path dari hasil scan",
    function()
        if #allRemotes == 0 then
            Library:Notification("❌", "Scan dulu!", 3); return
        end
        if pasteIdx > #allRemotes then
            Library:Notification("❌", "Max: "..#allRemotes, 2); return
        end
        local r = allRemotes[pasteIdx]
        firePath = r.path:gsub("^game%.", "")
        Library:Notification("📋 Paste",
            string.format("[%s] %s\nPath siap!", r.rtype, r.name), 4)
    end)

FireRight:Paragraph("Cara Pakai",
    "1. Tab Exploit →\n"..
    "   pilih nomor remote\n"..
    "   → Kirim ke Fire\n\n"..
    "2. Atau Scan → Paste\n"..
    "   dari nomor\n\n"..
    "3. Isi argumen\n\n"..
    "4. Tekan Fire!")

FireRight:Paragraph("Tips Argumen",
    "Economy → 999999\n"..
    "Item ID  → nama item\n"..
    "Player   → nama sendiri\n"..
    "Bool     → true/false\n\n"..
    "Lihat tip di tab\nExploit untuk saran\nargumen per kategori")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("🔌 XKID Remote v3.0",
    "Auto Exploit Detector!\nScan SEMUA → tab Exploit", 5)
Library:ConfigSystem(Win)

print("[ XKID REMOTE v3.0 ] Loaded — " .. LP.Name)
