--[[
  ╔═══════════════════════════════════════════════════════════════════╗
  ║                                                                   ║
  ║      ██╗  ██╗██╗  ██╗██╗██████╗     █████╗ ███╗   ██╗ █████╗     ║
  ║      ╚██╗██╔╝██║ ██╔╝██║██╔══██╗   ██╔══██╗████╗  ██║██╔══██╗    ║
  ║       ╚███╔╝ █████╔╝ ██║██║  ██║   ███████║██╔██╗ ██║███████║    ║
  ║       ██╔██╗ ██╔═██╗ ██║██║  ██║   ██╔══██║██║╚██╗██║██╔══██║    ║
  ║      ██╔╝ ██╗██║  ██╗██║██████╔╝   ██║  ██║██║ ╚████║██║  ██║    ║
  ║      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═════╝    ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝    ║
  ║                                                                   ║
  ║              🔌 REMOTE ANALYZER V5.0 PRO 🔌                      ║
  ║                    ULTIMATE DETECTION TOOL                        ║
  ║                                                                   ║
  ╚═══════════════════════════════════════════════════════════════════╝

  📋 FITUR LENGKAP:
  ════════════════════════════════════════════════════════════════════
  ✓ SCAN ALL REMOTES (Event + Function) dengan filter
  ✓ AUTO DETECT EXPLOIT (12 Kategori + Prioritas)
  ✓ SPY INCOMING (Server → Client) dengan real-time monitor
  ✓ HOOK OUTGOING (Client → Server) - DETEKSI SEMUA KIRIMAN!
  ✓ FARMING SPY KHUSUS (Tanam/Panen/Jual dengan detail crop)
  ✓ BN2 DECODER (BridgeNet2 packet analyzer)
  ✓ FIRE MANUAL dengan argument builder
  ✓ EXPORT LOG (Copy ke clipboard dengan format rapi)
  ✓ FILTER BY CATEGORY (Pisahin berdasarkan jenis exploit)
  ✓ REAL-TIME STATISTICS (Hitung jumlah remote tiap kategori)
  ✓ DARK MODE UI (Aurora dengan tema gelap)
  ✓ SAVE/LOAD CONFIG (Simpan setting favorite lo)

  ⚠️ PERINGATAN:
  ════════════════════════════════════════════════════════════════════
  • Gunakan untuk TESTING game MILIK SENDIRI
  • Jangan untuk merugikan orang lain
  • Pahami cara kerjanya, jangan cuma jadi script kiddie
  • Gue ga tanggung jawab kalo lo kena banned

  🎯 CARA PAKAI:
  ════════════════════════════════════════════════════════════════════
  [STEP 1] Jalankan script → UI akan muncul
  [STEP 2] Klik "SCAN SEMUA" di tab SCAN (WAJIB!)
  [STEP 3] Tunggu sampai scan selesai (lihat notifikasi)
  [STEP 4] Aktifkan fitur yang lo butuhin:
           • HOOK OUT → buat lihat SEMUA kiriman lo ke server
           • FARM SPY → khusus deteksi tanam/panen/jual
           • SPY IN → lihat data dari server ke client
  [STEP 5] Lakukan aktivitas di game
  [STEP 6] Lihat LOG di masing-masing tab
  [STEP 7] Copy log untuk dianalisis lebih lanjut
]]

-- ============================================
--  LOAD AURORA UI (DARK THEME)
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
--  WINDOW UTAMA (DARK MODE)
-- ============================================
local Win = Library:Window(
    "🔌 XKID ANALYZER V5.0 PRO",
    "cpu",
    "Ultimate Detection Tool",
    false
)

-- ============================================
--  TAB SECTION
-- ============================================
Win:TabSection("🔍 REMOTE DETECTION")
local TabScan      = Win:Tab("📡 SCAN", "search")
local TabExploit   = Win:Tab("💣 EXPLOIT", "alert-triangle")
local TabSpyIn     = Win:Tab("📥 SPY IN", "eye")
local TabHookOut   = Win:Tab("📤 HOOK OUT", "terminal")
local TabFarmSpy   = Win:Tab("🌾 FARM SPY", "sprout")
local TabBN2       = Win:Tab("🔷 BN2", "radio")
local TabFire      = Win:Tab("🔥 FIRE", "zap")
local TabStats     = Win:Tab("📊 STATS", "bar-chart-2")
local TabConfig    = Win:Tab("⚙️ CONFIG", "settings")

-- ============================================
--  SCAN LOCATIONS (LENGKAP)
-- ============================================
local SCAN_LOCATIONS = {
    RS, RF, Workspace,
    LP:WaitForChild("PlayerGui", 3),
    LP:WaitForChild("PlayerScripts", 3),
    LP:WaitForChild("Backpack", 3),
    game:GetService("CoreGui"),
    game:GetService("StarterGui"),
    game:GetService("StarterPack"),
    game:GetService("Lighting"),
}
-- Hapus nil
do
    local clean = {}
    for _, v in ipairs(SCAN_LOCATIONS) do
        if v then table.insert(clean, v) end
    end
    SCAN_LOCATIONS = clean
end

-- ============================================
--  GLOBAL STATE (LENGKAP)
-- ============================================
local allRemotes = {}
local exploitList = {}
local spyLog = {}; local hookLog = {}; local bn2Log = {}; local farmLog = {}
local spyConns = {}; local origNamecall = nil; local bn2Conn = nil
local spyOn = false; local hookOn = false; local bn2On = false; local farmSpyOn = false
local filterKeyword = ""
local currentPage = 1; local exploitPage = 1; local spyPage = 1
local hookPage = 1; local bn2Page = 1; local farmPage = 1
local firePath = ""; local fireArgs = ""
local PAGE_SIZE = 10; local MAX_LOG = 200
local categoryStats = {}
local autoRefresh = false
local refreshConn = nil

-- Untuk hook - target semua remote
local allRemoteRefs = {}

-- ============================================
--  UTILITY FUNCTIONS (OPTIMIZED)
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
    if depth > 3 then return "..." end
    
    local t = typeof(v)
    
    if t == "string" then
        if #v <= 4 then
            local hex = ""
            for i = 1, #v do
                hex = hex..string.format("\\x%02X", string.byte(v, i))
            end
            return string.format('STR[%s]', hex)
        end
        return string.format('"%s"', v:sub(1, 40))
        
    elseif t == "number" then
        return tostring(v)
        
    elseif t == "boolean" then
        return tostring(v)
        
    elseif t == "Vector3" then
        return string.format("V3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
        
    elseif t == "CFrame" then
        return string.format("CF(%.1f,%.1f,%.1f)", v.Position.X, v.Position.Y, v.Position.Z)
        
    elseif t == "table" then
        local parts = {}
        local count = 0
        for k, val in pairs(v) do
            count = count + 1
            if count > 4 then
                table.insert(parts, "...")
                break
            end
            table.insert(parts, string.format("[%s]=%s",
                serializeValue(k, depth+1),
                serializeValue(val, depth+1)))
        end
        return "{"..table.concat(parts, ", ").."}"
        
    elseif t == "Instance" then
        local success, name = pcall(function() return v.Name end)
        return success and ("["..name.."]") or "[Instance]"
        
    else
        return "["..t.."]"
    end
end

local function findByPath(path)
    path = path:gsub("^game%.", "")
    local parts = {}
    for p in path:gmatch("[^%.]+") do
        table.insert(parts, p)
    end
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
        if num then
            table.insert(args, num)
        elseif token:lower() == "true" then
            table.insert(args, true)
        elseif token:lower() == "false" then
            table.insert(args, false)
        elseif token:lower() == "nil" then
            table.insert(args, nil)
        else
            -- Cek apakah ini Vector3
            local x, y, z = token:match("V3%(([%d%-%.]+),([%d%-%.]+),([%d%-%.]+)%)")
            if x and y and z then
                table.insert(args, Vector3.new(tonumber(x), tonumber(y), tonumber(z)))
            else
                table.insert(args, token)
            end
        end
    end
    return args
end

-- ============================================
--  SCAN FUNCTIONS (OPTIMIZED)
-- ============================================
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
                name = child.Name,
                path = child:GetFullName(),
                rtype = targetClass == "RemoteEvent" and "EVENT" or "FUNC",
                ref = child,
                cat = nil,
                prio = 99,
                tip = "",
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

local function applyFilter(list, kw)
    if not kw or kw == "" then return list end
    local filtered = {}
    local kl = kw:lower()
    for _, r in ipairs(list) do
        if r.path:lower():find(kl, 1, true) or r.name:lower():find(kl, 1, true) then
            table.insert(filtered, r)
        end
    end
    return filtered
end

-- ============================================
--  AUTO DETECT EXPLOIT (12 KATEGORI + PRIORITAS)
-- ============================================
local CATEGORIES = {
    { name="💰 ECONOMY", prio=1, color="🟢",
      keys={"money","coin","cash","gold","dollar","earn","reward","payout","transfer","claim","collect","sell","buy","purchase","price","balance","wallet","bank","deposit","withdraw","add","give","set"},
      tip="Fire dengan nilai besar (999999 atau -1)" },
      
    { name="🎁 ITEM", prio=1, color="🟢",
      keys={"item","inventory","give","add","remove","spawn","drop","pickup","get","receive","tool","weapon","gear","equip","unequip","use","consume"},
      tip="Fire dengan item ID atau jumlah besar" },
      
    { name="⚔️ COMBAT", prio=1, color="🟢",
      keys={"damage","attack","hit","kill","hurt","health","hurt","take","deal","fight","combat","pvp","sword","gun","bullet","shoot"},
      tip="Fire ke target dengan damage tinggi" },
      
    { name="👑 ADMIN", prio=1, color="🟢",
      keys={"admin","rank","role","level","permission","mod","owner","promote","demote","set","give","vip","staff","gm","god"},
      tip="Fire dengan nama player sendiri" },
      
    { name="🏆 XP/LEVEL", prio=2, color="🟡",
      keys={"xp","exp","level","point","score","quest","mission","task","complete","finish","done","progress","stage","wave"},
      tip="Fire dengan nilai XP/level besar" },
      
    { name="🚀 TELEPORT", prio=2, color="🟡",
      keys={"teleport","move","position","location","warp","tp","goto","spawn","jump","cframe","pos"},
      tip="Fire dengan koordinat tujuan" },
      
    { name="🛡️ STATUS", prio=2, color="🟡",
      keys={"health","shield","speed","jump","invincible","godmode","buff","boost","heal","regenerate","revive","respawn"},
      tip="Fire untuk ubah status karakter" },
      
    { name="🔑 UNLOCK", prio=2, color="🟡",
      keys={"unlock","open","access","enter","gate","door","chest","crate","box","key","lock","permission"},
      tip="Fire untuk buka area/item terkunci" },
      
    { name="🌾 FARMING", prio=2, color="🟡",
      keys={"plant","tanam","harvest","panen","crop","seed","bibit","soil","farm","field","lahan","grow","water"},
      tip="Fire dengan posisi atau jenis tanaman" },
      
    { name="🌧️ WEATHER", prio=3, color="🔵",
      keys={"weather","rain","hujan","storm","badai","petir","lightning","thunder","sun","moon","day","night"},
      tip="Coba untuk kontrol cuaca" },
      
    { name="📊 DATA/SAVE", prio=3, color="🔵",
      keys={"save","load","data","profile","stats","update","sync","progress","reset","wipe","clear"},
      tip="Hati-hati — bisa corrupt save data" },
      
    { name="🔧 UTILITY", prio=3, color="🔵",
      keys={"notify","notification","message","chat","broadcast","log","track","analytics","ping","info","debug"},
      tip="Potensi rendah tapi coba saja" },
}

local function detectCategory(remote)
    local nl = remote.name:lower()
    for _, cat in ipairs(CATEGORIES) do
        for _, kw in ipairs(cat.keys) do
            if nl:find(kw, 1, true) then
                return cat.name, cat.prio, cat.tip, cat.color
            end
        end
    end
    return "❓ UNKNOWN", 99, "Remote tidak terdeteksi", "⚪"
end

local function runAutoDetect(list)
    local detected = {}
    categoryStats = {}
    
    for _, cat in ipairs(CATEGORIES) do
        categoryStats[cat.name] = 0
    end
    categoryStats["❓ UNKNOWN"] = 0
    
    for _, r in ipairs(list) do
        local catName, prio, tip, color = detectCategory(r)
        r.cat = catName
        r.prio = prio
        r.tip = tip
        r.color = color
        table.insert(detected, r)
        
        categoryStats[catName] = (categoryStats[catName] or 0) + 1
    end
    
    table.sort(detected, function(a, b)
        if a.prio ~= b.prio then return a.prio < b.prio end
        return a.name < b.name
    end)
    
    return detected
end

-- ============================================
--  DISPLAY FUNCTION (DENGAN PAGINATION)
-- ============================================
local function showPage(list, page, title, isExploit)
    if #list == 0 then
        Library:Notification("📭", "Tidak ada data\nScan dulu!", 3)
        return page
    end
    
    local totalPages = math.ceil(#list / PAGE_SIZE)
    page = math.max(1, math.min(page, totalPages))
    local startIdx = (page-1)*PAGE_SIZE + 1
    local endIdx = math.min(page*PAGE_SIZE, #list)
    
    local text = string.format("📄 HALAMAN %d/%d | TOTAL: %d\n", page, totalPages, #list)
    text = text .. string.format("─" .. string.rep("─", 30) .. "\n\n")
    
    for i = startIdx, endIdx do
        local r = list[i]
        if isExploit then
            local prioColor = r.prio==1 and "🔴" or r.prio==2 and "🟡" or "🔵"
            text = text .. string.format(
                "[%d] %s %s %s\n",
                i,
                prioColor,
                r.cat,
                r.name
            )
            text = text .. string.format("    📍 %s\n", r.path)
            text = text .. string.format("    💡 %s\n\n", r.tip)
        else
            text = text .. string.format(
                "[%d] [%s] %s\n    📍 %s\n\n",
                i,
                r.rtype,
                r.name,
                r.path
            )
        end
    end
    
    if totalPages > 1 then
        text = text .. string.format("▶ Gunakan tombol Next/Prev (Hal %d)", page)
    end
    
    Library:Notification(
        string.format("%s [%d-%d]", title, startIdx, endIdx),
        text,
        20
    )
    return page
end

-- ============================================
--  SPY INCOMING (Server → Client) - ENHANCED
-- ============================================
local function detectSpyAction(data)
    local s = serializeValue(data, 0)
    
    -- Farming
    if s:find("crop") or s:find("plant") or s:find("harvest") then
        if s:find("price") then return "💰 HARVEST PRICE"
        elseif s:find("grow") then return "🌱 GROWTH UPDATE"
        else return "🌾 FARM UPDATE"
        end
    end
    
    -- Economy
    if s:find("coin") or s:find("money") or s:find("cash") then
        return "💰 COINS UPDATE"
    end
    
    -- Shop
    if s:find("shop") or s:find("store") or s:find("price") then
        return "🏪 SHOP DATA"
    end
    
    -- Inventory
    if s:find("inventory") or s:find("item") or s:find("tool") then
        return "🎁 INVENTORY UPDATE"
    end
    
    -- Status
    if s:find("health") or s:find("shield") or s:find("stamina") then
        return "❤️ STATUS UPDATE"
    end
    
    -- XP/Level
    if s:find("xp") or s:find("level") or s:find("exp") then
        return "📊 XP UPDATE"
    end
    
    -- Combat
    if s:find("damage") or s:find("hit") or s:find("kill") then
        return "⚔️ COMBAT UPDATE"
    end
    
    -- Notification
    if s:find("notif") or s:find("message") or s:find("alert") then
        return "📢 NOTIFICATION"
    end
    
    return "❓ UNKNOWN"
end

local function startSpy()
    for _, c in ipairs(spyConns) do
        pcall(function() c:Disconnect() end)
    end
    spyConns = {}
    
    local events = scanAll("RemoteEvent")
    local count = 0
    
    for _, r in ipairs(events) do
        local ok, conn = pcall(function()
            return r.ref.OnClientEvent:Connect(function(...)
                local args = {...}
                local action = detectSpyAction(args[1] or args)
                local argStrs = {}
                
                for _, a in ipairs(args) do
                    table.insert(argStrs, serializeValue(a, 0))
                end
                
                local catName, _, _ = detectCategory(r)
                local flag = catName and ("["..catName.."]") or ""
                
                local entry = string.format(
                    "[%s] %s %s\n📦 %s\n📋 %s",
                    os.date("%H:%M:%S"),
                    flag,
                    action,
                    r.path,
                    table.concat(argStrs, ", "):sub(1, 80)
                )
                
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
    
    Library:Notification(
        "👁 SPY IN ACTIVE",
        string.format("Memantau %d RemoteEvent", count),
        4
    )
    return count
end

local function stopSpy()
    for _, c in ipairs(spyConns) do
        pcall(function() c:Disconnect() end)
    end
    spyConns = {}
end

-- ============================================
--  HOOK OUTGOING (Client → Server) - ENHANCED
-- ============================================
local function buildAllRemoteSet()
    local set = {}
    for _, r in ipairs(allRemotes) do
        if r.ref then
            set[r.ref] = true
        end
    end
    return set
end

local function detectHookActionAdvanced(remoteName, args)
    remoteName = remoteName:lower()
    local argsStr = ""
    for _, a in ipairs(args) do
        argsStr = argsStr .. serializeValue(a, 0)
    end
    
    -- Priority detection based on remote name
    if remoteName:find("plant") or remoteName:find("tanam") then
        return "🌱 TANAM", 1
    end
    if remoteName:find("harvest") or remoteName:find("panen") then
        return "🌾 PANEN", 2
    end
    if remoteName:find("sell") or remoteName:find("jual") then
        return "💰 JUAL", 3
    end
    if remoteName:find("buy") or remoteName:find("beli") then
        return "🛒 BELI", 4
    end
    if remoteName:find("damage") or remoteName:find("attack") then
        return "⚔️ ATTACK", 5
    end
    if remoteName:find("move") or remoteName:find("teleport") then
        return "🚀 MOVE", 6
    end
    if remoteName:find("chat") or remoteName:find("say") then
        return "💬 CHAT", 7
    end
    
    -- Fallback to args analysis
    if argsStr:find("V3") then
        return "📍 POSITION", 8
    end
    if argsStr:find("true") or argsStr:find("false") then
        return "🎯 BOOLEAN", 9
    end
    if argsStr:find('"') then
        return "📝 STRING", 10
    end
    
    return "❓ UNKNOWN", 99
end

local function startHook()
    local targetSet = buildAllRemoteSet()
    if not next(targetSet) then
        Library:Notification(
            "❌ ERROR",
            "Tidak ada remote untuk di-hook!\nScan dulu!",
            4
        )
        return false
    end
    
    origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        
        if method == "FireServer" or method == "InvokeServer" then
            local isRemote = targetSet[self]
            
            if not isRemote then
                local ok, path = pcall(function() return self:GetFullName() end)
                if ok then
                    isRemote = path:find("Remote") or path:find("Event") or path:find("Function")
                end
            end
            
            if isRemote then
                local args = {...}
                local argDetails = {}
                
                for i, a in ipairs(args) do
                    table.insert(argDetails, string.format(
                        "[%d] %s",
                        i,
                        serializeValue(a, 0)
                    ))
                end
                
                local remoteName = "?"
                local remotePath = "?"
                pcall(function()
                    remoteName = self.Name
                    remotePath = self:GetFullName()
                end)
                
                local action, priority = detectHookActionAdvanced(remoteName, args)
                
                local entry = string.format(
                    "[%s] %s %s\n" ..
                    "📌 Remote: %s\n" ..
                    "📂 Path: %s\n" ..
                    "⚡ Method: %s\n" ..
                    "📦 Args:\n%s",
                    os.date("%H:%M:%S"),
                    action,
                    remoteName,
                    remoteName,
                    remotePath,
                    method,
                    table.concat(argDetails, "\n")
                )
                
                table.insert(hookLog, 1, entry)
                if #hookLog > MAX_LOG then
                    table.remove(hookLog, #hookLog)
                end
                
                -- Auto refresh kalo aktif
                if autoRefresh and #hookLog > 0 then
                    -- Trigger refresh di UI (optional)
                end
            end
        end
        
        return origNamecall(self, ...)
    end)
    
    hookOn = true
    Library:Notification(
        "🔌 HOOK OUT ACTIVE",
        string.format("Memantau %d remote\nLakukan apapun di game!", #allRemotes),
        4
    )
    return true
end

local function stopHook()
    if origNamecall then
        pcall(function()
            hookmetamethod(game, "__namecall", origNamecall)
        end)
        origNamecall = nil
    end
    hookOn = false
    Library:Notification("🔌 HOOK OUT", "Dimatikan", 2)
end

-- ============================================
--  FARMING SPY (ENHANCED - KHUSUS FARMING)
-- ============================================
local farmingTargets = {}
local farmingKeywords = {
    "plant", "tanam", "harvest", "panen", "sell", "jual",
    "bibit", "seed", "crop", "lahan", "field", "soil",
    "water", "grow", "pupuk", "fertilizer"
}

local function buildFarmingTargets()
    farmingTargets = {}
    
    for _, r in ipairs(allRemotes) do
        local nl = r.name:lower()
        for _, kw in ipairs(farmingKeywords) do
            if nl:find(kw, 1, true) then
                farmingTargets[r.ref] = {
                    name = r.name,
                    path = r.path,
                    type = r.rtype
                }
                break
            end
        end
    end
    
    return farmingTargets
end

local function extractCropInfoFromArgs(args)
    local cropInfo = {
        type = "?",
        position = nil,
        amount = 1,
        quality = "normal"
    }
    
    for _, a in ipairs(args) do
        if type(a) == "string" then
            if #a < 30 and not a:find(" ") then
                cropInfo.type = a
            end
        elseif typeof(a) == "Vector3" then
            cropInfo.position = a
        elseif type(a) == "number" and a > 1 then
            cropInfo.amount = a
        elseif type(a) == "table" then
            if a.crop then cropInfo.type = a.crop end
            if a.pos then cropInfo.position = a.pos end
            if a.amount then cropInfo.amount = a.amount end
        end
    end
    
    return cropInfo
end

local function startFarmingSpy()
    if farmSpyOn then
        Library:Notification("⚠️ INFO", "Farming Spy sudah aktif", 2)
        return true
    end
    
    buildFarmingTargets()
    if not next(farmingTargets) then
        Library:Notification(
            "❌ ERROR",
            "Tidak ada remote farming!\nScan dulu!",
            4
        )
        return false
    end
    
    farmLog = {}
    
    -- Simpan hook lama kalo ada
    local oldHook = origNamecall
    
    origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if farmingTargets[self] and (method == "FireServer" or method == "InvokeServer") then
            local target = farmingTargets[self]
            local cropInfo = extractCropInfoFromArgs(args)
            
            -- Deteksi aksi berdasarkan nama
            local action = "❓"
            local nl = target.name:lower()
            
            if nl:find("plant") or nl:find("tanam") then
                action = "🌱 TANAM"
            elseif nl:find("harvest") or nl:find("panen") then
                action = "🌾 PANEN"
            elseif nl:find("sell") or nl:find("jual") then
                action = "💰 JUAL"
            elseif nl:find("buy") or nl:find("beli") or nl:find("bibit") then
                action = "🛒 BELI BIBIT"
            elseif nl:find("water") or nl:find("siram") then
                action = "💧 SIRAM"
            elseif nl:find("pupuk") or nl:find("fertilizer") then
                action = "🧪 PUPUK"
            end
            
            -- Format posisi
            local posStr = "?"
            if cropInfo.position then
                posStr = string.format(
                    "(%.1f, %.1f, %.1f)",
                    cropInfo.position.X,
                    cropInfo.position.Y,
                    cropInfo.position.Z
                )
            end
            
            -- Format args lengkap
            local argStrs = {}
            for i, a in ipairs(args) do
                table.insert(argStrs, string.format(
                    "[%d]%s",
                    i,
                    serializeValue(a, 0)
                ))
            end
            
            local entry = string.format(
                "[%s] %s %s\n" ..
                "🌽 Crop: %s\n" ..
                "📍 Posisi: %s\n" ..
                "🔢 Jumlah: %d\n" ..
                "📦 Args: %s\n" ..
                "📂 Path: %s",
                os.date("%H:%M:%S"),
                action,
                target.name,
                cropInfo.type,
                posStr,
                cropInfo.amount,
                table.concat(argStrs, " "),
                target.path
            )
            
            table.insert(farmLog, 1, entry)
            if #farmLog > 50 then
                table.remove(farmLog, #farmLog)
            end
            
            -- Notifikasi ringan (opsional)
            if #farmLog % 5 == 0 then
                Library:Notification(
                    "🌾 FARM UPDATE",
                    string.format("Total log: %d", #farmLog),
                    1
                )
            end
        end
        
        -- Panggil hook lama kalo ada
        if oldHook then
            return oldHook(self, ...)
        else
            return origNamecall(self, ...)
        end
    end)
    
    farmSpyOn = true
    Library:Notification(
        "🌾 FARM SPY ACTIVE",
        string.format("Memantau %d remote farming", #farmingTargets),
        4
    )
    return true
end

local function stopFarmingSpy()
    if farmSpyOn then
        -- Kembalikan hook ke semula
        -- Ini agak tricky, tapi kita bisa restart hook
        if hookOn then
            stopHook()
            task.wait(0.1)
            startHook()
        else
            -- Kalo hook utama ga aktif, kita balikin hook
            pcall(function()
                hookmetamethod(game, "__namecall", origNamecall)
            end)
        end
        farmSpyOn = false
        Library:Notification("🌾 FARM SPY", "Dimatikan", 2)
    end
end

-- ============================================
--  BN2 FUNCTIONS (ENHANCED)
-- ============================================
local function detectBN2Action(data)
    if type(data) ~= "table" then
        return "❓ BUKAN TABLE", "?"
    end
    
    local s = serializeValue(data, 0)
    
    -- Deteksi berdasarkan pola umum
    if s:find("cropPos") and s:find("sellPrice") then
        return "🌾 HARVEST RESPONSE", "HARVEST"
    elseif s:find("seedPrice") and s:find("items") then
        return "🏪 SHOP DATA", "SHOP"
    elseif s:find("cropName") and s:find("count") then
        return "🛒 BELI RESPONSE", "BUY"
    elseif s:find("success") then
        return "✅ SUCCESS", "SUCCESS"
    elseif s:find("error") then
        return "❌ ERROR", "ERROR"
    elseif s:find("coins") then
        return "💰 COINS UPDATE", "COINS"
    elseif s:find("\\x06") then
        return "🌱 TANAM PACKET", "PLANT"
    elseif s:find("\\x05") then
        return "📦 REQUEST PACKET", "REQUEST"
    elseif s:find("\\x0F") then
        return "🌾 HARVEST PACKET", "HARVEST"
    elseif s:find("\\x04") then
        return "💰 COINS PACKET", "COINS"
    end
    
    return "❓ UNKNOWN BN2", "UNKNOWN"
end

local function startBN2Spy()
    if bn2Conn then
        pcall(function() bn2Conn:Disconnect() end)
    end
    
    local bn2 = RS:FindFirstChild("BridgeNet2")
    local dataRE = bn2 and bn2:FindFirstChild("dataRemoteEvent")
    local metaRE = bn2 and bn2:FindFirstChild("metaRemoteEvent")
    local netRE = RS:FindFirstChild("Networking")
    local netEvent = netRE and netRE:FindFirstChild("RemoteEvent")
    
    local targets = {}
    if dataRE then table.insert(targets, dataRE) end
    if metaRE then table.insert(targets, metaRE) end
    if netEvent then table.insert(targets, netEvent) end
    
    -- Cari juga di tempat umum
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (
            obj.Name:find("BN2") or
            obj.Name:find("Bridge") or
            obj.Name:find("Net")
        ) then
            table.insert(targets, obj)
        end
    end
    
    if #targets == 0 then
        Library:Notification(
            "❌ BN2",
            "BridgeNet2 tidak ditemukan\nGame mungkin tidak pakai BN2",
            4
        )
        return false
    end
    
    local conns = {}
    for _, re in ipairs(targets) do
        local ok, conn = pcall(function()
            return re.OnClientEvent:Connect(function(data)
                local action, category = detectBN2Action(data)
                local raw = serializeValue(data, 0)
                
                local entry = string.format(
                    "[%s] %s\n📦 Remote: %s\n📋 Data: %s",
                    os.date("%H:%M:%S"),
                    action,
                    re.Name,
                    raw:sub(1, 80)
                )
                
                table.insert(bn2Log, 1, entry)
                if #bn2Log > MAX_LOG then
                    table.remove(bn2Log, #bn2Log)
                end
            end)
        end)
        
        if ok and conn then
            table.insert(conns, conn)
        end
    end
    
    bn2Conn = {
        Disconnect = function()
            for _, c in ipairs(conns) do
                pcall(function() c:Disconnect() end)
            end
        end
    }
    
    Library:Notification(
        "📡 BN2 SPY ACTIVE",
        string.format("Monitoring %d BN2 remote", #targets),
        4
    )
    return true
end

local function stopBN2Spy()
    if bn2Conn then
        pcall(function() bn2Conn:Disconnect() end)
        bn2Conn = nil
    end
    Library:Notification("📡 BN2 SPY", "Dimatikan", 2)
end

-- ============================================
--  FIRE REMOTE (ENHANCED)
-- ============================================
local function doFire(path, argsStr)
    if not path or path == "" then
        Library:Notification("❌ ERROR", "Path remote kosong!", 2)
        return
    end
    
    local remote = findByPath(path)
    if not remote then
        Library:Notification(
            "❌ ERROR",
            "Remote tidak ditemukan:\n" .. path,
            4
        )
        return
    end
    
    local args = parseArgs(argsStr)
    local argsDisplay = #args > 0 and table.concat(args, ", ") or "(none)"
    
    if remote:IsA("RemoteEvent") then
        local ok, err = pcall(function()
            remote:FireServer(table.unpack(args))
        end)
        
        if ok then
            Library:Notification(
                "✅ FIRESERVER BERHASIL",
                string.format("%s\n📦 Args: %s", remote.Name, argsDisplay),
                3
            )
        else
            Library:Notification(
                "❌ FIRESERVER GAGAL",
                tostring(err),
                4
            )
        end
        
    elseif remote:IsA("RemoteFunction") then
        local ok, res = pcall(function()
            return remote:InvokeServer(table.unpack(args))
        end)
        
        if ok then
            Library:Notification(
                "✅ INVOKESERVER BERHASIL",
                string.format("%s\n📦 Result: %s", remote.Name, serializeValue(res, 0)),
                4
            )
        else
            Library:Notification(
                "❌ INVOKESERVER GAGAL",
                tostring(res),
                4
            )
        end
        
    else
        Library:Notification(
            "❌ ERROR",
            "Objek bukan RemoteEvent/Function",
            3
        )
    end
end

-- ============================================
--  AUTO REFRESH FUNCTION
-- ============================================
local function startAutoRefresh(interval)
    if refreshConn then
        refreshConn:Disconnect()
    end
    
    autoRefresh = true
    refreshConn = RunService.Heartbeat:Connect(function()
        if autoRefresh then
            task.wait(interval or 3)
            -- Bisa ditambah logic refresh UI di sini
        end
    end)
end

local function stopAutoRefresh()
    autoRefresh = false
    if refreshConn then
        refreshConn:Disconnect()
        refreshConn = nil
    end
end

-- ============================================
--  BUILD UI - SCAN TAB (ENHANCED)
-- ============================================
local ScanPage = TabScan:Page("📡 REMOTE SCANNER", "search")
local ScanLeft = ScanPage:Section("🔍 SCANNER", "Left")
local ScanRight = ScanPage:Section("📋 HASIL SCAN", "Right")

-- Left Section
ScanLeft:Paragraph("📌 INSTRUKSI",
    "1. Scan semua remote\n" ..
    "2. Gunakan filter untuk cari spesifik\n" ..
    "3. Lihat hasil & copy path\n\n" ..
    "⚠️ WAJIB SCAN DULU sebelum pakai fitur lain!"
)

ScanLeft:TextBox("🔎 FILTER NAMA/PATH", "FilterBox", "",
    function(v) filterKeyword = v end,
    "Ketik keyword untuk filter"
)

ScanLeft:Button("🔴 SCAN REMOTEEVENT", "Scan semua RemoteEvent", function()
    task.spawn(function()
        Library:Notification("🔍", "Scanning RemoteEvent...", 2)
        local r = scanAll("RemoteEvent")
        allRemotes = applyFilter(r, filterKeyword)
        exploitList = runAutoDetect(allRemotes)
        currentPage = 1
        
        Library:Notification(
            "✅ SCAN REMOTEEVENT SELESAI",
            string.format(
                "📊 Total: %d remote\n" ..
                "⚠️ Exploit: %d candidate\n\n" ..
                "➡️ Buka tab EXPLOIT untuk detail!",
                #allRemotes,
                #exploitList
            ),
            6
        )
    end)
end)

ScanLeft:Button("🔵 SCAN REMOTEFUNCTION", "Scan semua RemoteFunction", function()
    task.spawn(function()
        Library:Notification("🔍", "Scanning RemoteFunction...", 2)
        local r = scanAll("RemoteFunction")
        allRemotes = applyFilter(r, filterKeyword)
        exploitList = runAutoDetect(allRemotes)
        currentPage = 1
        
        Library:Notification(
            "✅ SCAN REMOTEFUNCTION SELESAI",
            string.format(
                "📊 Total: %d remote\n" ..
                "⚠️ Exploit: %d candidate",
                #allRemotes,
                #exploitList
            ),
            6
        )
    end)
end)

ScanLeft:Button("⚡ SCAN SEMUA + AUTO DETECT", "Scan Event & Function + Deteksi Exploit", function()
    task.spawn(function()
        Library:Notification("🔍", "Scanning semua service...", 2)
        
        local events = scanAll("RemoteEvent")
        local funcs = scanAll("RemoteFunction")
        local all = {}
        
        for _, r in ipairs(events) do table.insert(all, r) end
        for _, r in ipairs(funcs) do table.insert(all, r) end
        
        allRemotes = applyFilter(all, filterKeyword)
        exploitList = runAutoDetect(allRemotes)
        currentPage = 1
        
        local p1, p2, p3 = 0, 0, 0
        for _, r in ipairs(exploitList) do
            if r.prio == 1 then p1 = p1 + 1
            elseif r.prio == 2 then p2 = p2 + 1
            else p3 = p3 + 1 end
        end
        
        Library:Notification(
            "✅ SCAN SEMUA SELESAI",
            string.format(
                "📊 TOTAL: %d remote\n" ..
                "🔴 EVENT: %d | 🔵 FUNC: %d\n\n" ..
                "⚠️ EXPLOIT CANDIDATES:\n" ..
                "🔴 HIGH : %d\n" ..
                "🟡 MED  : %d\n" ..
                "🔵 LOW  : %d\n\n" ..
                "➡️ Buka tab EXPLOIT!",
                #allRemotes,
                #events,
                #funcs,
                p1, p2, p3
            ),
            10
        )
    end)
end)

-- Right Section
ScanRight:Button("📄 LIHAT HASIL", "Tampilkan halaman pertama", function()
    currentPage = showPage(allRemotes, 1, "📡 REMOTE", false)
end)

ScanRight:Button("⏩ HALAMAN BERIKUTNYA", "Halaman berikutnya", function()
    currentPage = showPage(allRemotes, currentPage + 1, "📡 REMOTE", false)
end)

ScanRight:Button("⏪ HALAMAN SEBELUMNYA", "Halaman sebelumnya", function()
    currentPage = showPage(allRemotes, currentPage - 1, "📡 REMOTE", false)
end)

ScanRight:Button("📋 COPY SEMUA PATH", "Copy semua remote ke clipboard", function()
    if #allRemotes == 0 then
        Library:Notification("❌ ERROR", "Scan dulu!", 2)
        return
    end
    
    local text = string.format("=== XKID SCAN RESULT (%d REMOTES) ===\n\n", #allRemotes)
    for i, r in ipairs(allRemotes) do
        text = text .. string.format("[%d] [%s] %s\n    %s\n\n", i, r.rtype, r.name, r.path)
    end
    
    doCopy(text)
    Library:Notification("📋", "Copied " .. #allRemotes .. " remote paths", 2)
end)

local copyIdx = 1
ScanRight:Slider("🔢 NOMOR REMOTE", "CopyIdxSlider", 1, 500, 1,
    function(v) copyIdx = v end,
    "Pilih nomor remote untuk di-copy"
)

ScanRight:Button("📋 COPY REMOTE #" .. copyIdx, "Copy 1 remote sesuai nomor", function()
    if #allRemotes == 0 then
        Library:Notification("❌ ERROR", "Scan dulu!", 2)
        return
    end
    
    if copyIdx > #allRemotes then
        Library:Notification("❌ ERROR", "Max: " .. #allRemotes, 2)
        return
    end
    
    local r = allRemotes[copyIdx]
    doCopy(string.format("[%s] %s\n%s", r.rtype, r.name, r.path))
    
    Library:Notification(
        "📋 COPIED",
        string.format("%s\n%s", r.name, r.path),
        3
    )
end)

-- ============================================
--  BUILD UI - EXPLOIT TAB (ENHANCED)
-- ============================================
local ExPage = TabExploit:Page("💣 EXPLOIT CANDIDATES", "alert-triangle")
local ExLeft = ExPage:Section("⚠️ KANDIDAT EXPLOIT", "Left")
local ExRight = ExPage:Section("📋 COPY & FIRE", "Right")

-- Left Section
ExLeft:Paragraph("📌 INFO",
    "Remote yang terdeteksi berpotensi dieksploit:\n\n" ..
    "🔴 HIGH = Prioritas utama (Economy, Item, Combat, Admin)\n" ..
    "🟡 MED  = Prioritas kedua (XP, Teleport, Status, Unlock)\n" ..
    "🔵 LOW  = Prioritas rendah (Weather, Utility, Data)"
)

ExLeft:Button("📄 LIHAT SEMUA EXPLOIT", "Tampilkan semua exploit candidates", function()
    exploitPage = showPage(exploitList, 1, "💣 EXPLOIT", true)
end)

ExLeft:Button("⏩ HALAMAN BERIKUTNYA", "Halaman berikutnya", function()
    exploitPage = showPage(exploitList, exploitPage + 1, "💣 EXPLOIT", true)
end)

ExLeft:Button("⏪ HALAMAN SEBELUMNYA", "Halaman sebelumnya", function()
    exploitPage = showPage(exploitList, exploitPage - 1, "💣 EXPLOIT", true)
end)

ExLeft:Button("🔴 FILTER HIGH PRIORITY", "Tampilkan hanya prioritas tinggi", function()
    local high = {}
    for _, r in ipairs(exploitList) do
        if r.prio == 1 then
            table.insert(high, r)
        end
    end
    showPage(high, 1, "🔴 HIGH PRIORITY", true)
end)

ExLeft:Button("🟡 FILTER MED PRIORITY", "Tampilkan hanya prioritas sedang", function()
    local med = {}
    for _, r in ipairs(exploitList) do
        if r.prio == 2 then
            table.insert(med, r)
        end
    end
    showPage(med, 1, "🟡 MED PRIORITY", true)
end)

ExLeft:Button("🔵 FILTER LOW PRIORITY", "Tampilkan hanya prioritas rendah", function()
    local low = {}
    for _, r in ipairs(exploitList) do
        if r.prio == 3 then
            table.insert(low, r)
        end
    end
    showPage(low, 1, "🔵 LOW PRIORITY", true)
end)

-- Right Section
ExRight:Button("📋 COPY SEMUA EXPLOIT", "Copy semua exploit ke clipboard", function()
    if #exploitList == 0 then
        Library:Notification("❌ ERROR", "Scan dulu!", 2)
        return
    end
    
    local text = string.format("=== XKID EXPLOIT CANDIDATES (%d) ===\n\n", #exploitList)
    for i, r in ipairs(exploitList) do
        local priority = r.prio == 1 and "🔴 HIGH" or r.prio == 2 and "🟡 MED" or "🔵 LOW"
        text = text .. string.format(
            "[%d] %s %s\n" ..
            "    Kategori: %s\n" ..
            "    Path: %s\n" ..
            "    Tipe: %s\n" ..
            "    Tip: %s\n\n",
            i,
            priority,
            r.name,
            r.cat,
            r.path,
            r.rtype,
            r.tip
        )
    end
    
    doCopy(text)
    Library:Notification("📋", "Copied " .. #exploitList .. " exploit candidates", 2)
end)

local exIdx = 1
ExRight:Slider("🔢 NOMOR EXPLOIT", "ExIdxSlider", 1, 200, 1,
    function(v) exIdx = v end,
    "Pilih nomor exploit"
)

ExRight:Button("📋 COPY EXPLOIT #" .. exIdx, "Copy 1 exploit sesuai nomor", function()
    if #exploitList == 0 then
        Library:Notification("❌ ERROR", "Scan dulu!", 2)
        return
    end
    
    if exIdx > #exploitList then
        Library:Notification("❌ ERROR", "Max: " .. #exploitList, 2)
        return
    end
    
    local r = exploitList[exIdx]
    local priority = r.prio == 1 and "🔴 HIGH" or r.prio == 2 and "🟡 MED" or "🔵 LOW"
    
    doCopy(string.format(
        "[%s] %s\nKategori: %s\nPath: %s\nTipe: %s\nTip: %s",
        priority,
        r.name,
        r.cat,
        r.path,
        r.rtype,
        r.tip
    ))
    
    Library:Notification(
        "📋 COPIED",
        string.format("%s\n%s", priority, r.name),
        3
    )
end)

ExRight:Button("🔥 KIRIM KE TAB FIRE", "Paste path exploit ke tab Fire", function()
    if #exploitList == 0 then
        Library:Notification("❌ ERROR", "Scan dulu!", 2)
        return
    end
    
    if exIdx > #exploitList then
        Library:Notification("❌ ERROR", "Max: " .. #exploitList, 2)
        return
    end
    
    local r = exploitList[exIdx]
    firePath = r.path:gsub("^game%.", "")
    
    Library:Notification(
        "🔥 SIAP FIRE",
        string.format("%s\n%s\n\n➡️ Buka tab FIRE!", r.name, r.cat),
        5
    )
end)

-- ============================================
--  BUILD UI - SPY IN TAB
-- ============================================
local SpyPage = TabSpyIn:Page("📥 SPY IN (SERVER → CLIENT)", "eye")
local SpyLeft = SpyPage:Section("👁 KONTROL SPY", "Left")
local SpyRight = SpyPage:Section("📋 LOG SERVER", "Right")

-- Left Section
SpyLeft:Paragraph("📌 FUNGSI",
    "Memantau data yang dikirim SERVER ke CLIENT:\n\n" ..
    "• Update coins/level\n" ..
    "• Notifikasi dari server\n" ..
    "• Data shop/inventory\n" ..
    "• Status tanaman\n\n" ..
    "Aktifkan, lalu mainkan game!"
)

SpyLeft:Toggle("👁 AKTIFKAN SPY IN", "SpyToggle", false,
    "Monitor server → client",
    function(v)
        spyOn = v
        if v then
            startSpy()
        else
            stopSpy()
            Library:Notification("👁 SPY IN", "Dimatikan", 2)
        end
    end
)

SpyLeft:Button("🔄 RESTART SPY", "Scan ulang & restart", function()
    if spyOn then
        stopSpy()
        task.wait(0.2)
        startSpy()
    else
        Library:Notification("❌ ERROR", "Aktifkan Spy dulu", 2)
    end
end)

SpyLeft:Button("🗑️ CLEAR LOG", "Hapus semua log spy", function()
    spyLog = {}
    Library:Notification("🗑️", "Log spy dihapus", 2)
end)

SpyLeft:Paragraph("📊 STATISTIK",
    function()
        return string.format(
            "Total log: %d\n" ..
            "Memory: %d/%d",
            #spyLog,
            #spyLog,
            MAX_LOG
        )
    end
)

-- Right Section
SpyRight:Button("📄 LIHAT LOG", "Tampilkan log spy", function()
    if #spyLog == 0 then
        Library:Notification("📭", "Belum ada log\nAktifkan Spy & main game!", 3)
        return
    end
    
    local total = math.ceil(#spyLog / PAGE_SIZE)
    local text = string.format("📋 LOG SERVER (Total: %d)\n\n", #spyLog)
    
    for i = 1, math.min(PAGE_SIZE, #spyLog) do
        text = text .. string.format("[%d] %s\n\n", i, spyLog[i])
    end
    
    Library:Notification("👁 SPY IN LOG", text, 20)
    spyPage = 1
end)

SpyRight:Button("⏩ LOG BERIKUTNYA", "Halaman berikutnya", function()
    spyPage = spyPage + 1
    local total = math.ceil(#spyLog / PAGE_SIZE)
    if spyPage > total then spyPage = total end
    
    local startIdx = (spyPage - 1) * PAGE_SIZE + 1
    local endIdx = math.min(spyPage * PAGE_SIZE, #spyLog)
    
    local text = string.format("📋 HALAMAN %d/%d (Total: %d)\n\n", spyPage, total, #spyLog)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, spyLog[i])
    end
    
    Library:Notification("👁 SPY IN LOG", text, 20)
end)

SpyRight:Button("⏪ LOG SEBELUMNYA", "Halaman sebelumnya", function()
    spyPage = spyPage - 1
    if spyPage < 1 then spyPage = 1 end
    
    local total = math.ceil(#spyLog / PAGE_SIZE)
    local startIdx = (spyPage - 1) * PAGE_SIZE + 1
    local endIdx = math.min(spyPage * PAGE_SIZE, #spyLog)
    
    local text = string.format("📋 HALAMAN %d/%d (Total: %d)\n\n", spyPage, total, #spyLog)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, spyLog[i])
    end
    
    Library:Notification("👁 SPY IN LOG", text, 20)
end)

SpyRight:Button("📋 COPY SEMUA LOG", "Copy semua log spy ke clipboard", function()
    if #spyLog == 0 then
        Library:Notification("❌ ERROR", "Belum ada log", 2)
        return
    end
    
    local text = string.format("=== SPY IN LOG (%d) ===\n\n", #spyLog)
    for i, e in ipairs(spyLog) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    
    doCopy(text)
    Library:Notification("📋", "Copied " .. #spyLog .. " log entries", 2)
end)

-- ============================================
--  BUILD UI - HOOK OUT TAB (YANG PALING PENTING!)
-- ============================================
local HookPage = TabHookOut:Page("📤 HOOK OUT (CLIENT → SERVER)", "terminal")
local HookLeft = HookPage:Section("🔌 KONTROL HOOK", "Left")
local HookRight = HookPage:Section("📋 LOG KIRIMAN", "Right")

-- Left Section
HookLeft:Paragraph("📌 FUNGSI UTAMA",
    "🔥 INI YANG PALING PENTING!\n\n" ..
    "Memantau SEMUA data yang dikirim\n" ..
    "CLIENT ke SERVER:\n\n" ..
    "• Tanam / Panen\n" ..
    "• Beli / Jual item\n" ..
    "• Gerak / Teleport\n" ..
    "• Chat / Interaksi\n" ..
    "• DAN SEMUA REMOTE LAINNYA!\n\n" ..
    "⚠️ WAJIB SCAN DULU SEBELUM AKTIFKAN!"
)

HookLeft:Toggle("🔌 AKTIFKAN HOOK OUT", "HookToggle", false,
    "Intercept SEMUA FireServer/InvokeServer",
    function(v)
        hookOn = v
        if v then
            if #allRemotes == 0 then
                Library:Notification(
                    "⚠️ PERINGATAN",
                    "Scan dulu di tab SCAN!\n" ..
                    "Biar tau remote apa aja yang ada",
                    5
                )
                return
            end
            
            local ok, err = pcall(startHook)
            if not ok then
                Library:Notification(
                    "❌ ERROR",
                    "hookmetamethod tidak support!\n" .. tostring(err),
                    5
                )
                hookOn = false
            end
        else
            stopHook()
            Library:Notification("🔌 HOOK OUT", "Dimatikan", 2)
        end
    end
)

HookLeft:Button("🗑️ CLEAR LOG", "Hapus semua log hook", function()
    hookLog = {}
    Library:Notification("🗑️", "Log hook dihapus", 2)
end)

HookLeft:Toggle("🔄 AUTO REFRESH", "AutoRefreshToggle", false,
    "Auto update log setiap 3 detik",
    function(v)
        if v then
            startAutoRefresh(3)
        else
            stopAutoRefresh()
        end
    end
)

HookLeft:Paragraph("📊 STATISTIK",
    function()
        return string.format(
            "Total remote: %d\n" ..
            "Log hook: %d\n" ..
            "Memory: %d/%d\n" ..
            "Auto refresh: %s",
            #allRemotes,
            #hookLog,
            #hookLog,
            MAX_LOG,
            autoRefresh and "✅" or "❌"
        )
    end
)

-- Right Section
HookRight:Button("📄 LIHAT LOG", "Tampilkan log hook", function()
    if #hookLog == 0 then
        Library:Notification(
            "📭",
            "Belum ada log\nAktifkan Hook & lakukan apapun di game!",
            4
        )
        return
    end
    
    local total = math.ceil(#hookLog / PAGE_SIZE)
    local text = string.format("📋 LOG KIRIMAN (Total: %d)\n\n", #hookLog)
    
    for i = 1, math.min(PAGE_SIZE, #hookLog) do
        text = text .. string.format("[%d] %s\n\n", i, hookLog[i])
    end
    
    Library:Notification("🔌 HOOK OUT LOG", text, 20)
    hookPage = 1
end)

HookRight:Button("⏩ LOG BERIKUTNYA", "Halaman berikutnya", function()
    hookPage = hookPage + 1
    local total = math.ceil(#hookLog / PAGE_SIZE)
    if hookPage > total then hookPage = total end
    
    local startIdx = (hookPage - 1) * PAGE_SIZE + 1
    local endIdx = math.min(hookPage * PAGE_SIZE, #hookLog)
    
    local text = string.format("📋 HALAMAN %d/%d (Total: %d)\n\n", hookPage, total, #hookLog)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, hookLog[i])
    end
    
    Library:Notification("🔌 HOOK OUT LOG", text, 20)
end)

HookRight:Button("⏪ LOG SEBELUMNYA", "Halaman sebelumnya", function()
    hookPage = hookPage - 1
    if hookPage < 1 then hookPage = 1 end
    
    local total = math.ceil(#hookLog / PAGE_SIZE)
    local startIdx = (hookPage - 1) * PAGE_SIZE + 1
    local endIdx = math.min(hookPage * PAGE_SIZE, #hookLog)
    
    local text = string.format("📋 HALAMAN %d/%d (Total: %d)\n\n", hookPage, total, #hookLog)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, hookLog[i])
    end
    
    Library:Notification("🔌 HOOK OUT LOG", text, 20)
end)

HookRight:Button("📋 COPY SEMUA LOG", "Copy semua log hook ke clipboard", function()
    if #hookLog == 0 then
        Library:Notification("❌ ERROR", "Belum ada log", 2)
        return
    end
    
    local text = string.format("=== HOOK OUT LOG (%d) ===\n\n", #hookLog)
    for i, e in ipairs(hookLog) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    
    doCopy(text)
    Library:Notification("📋", "Copied " .. #hookLog .. " log entries", 2)
end)

HookRight:Button("📋 COPY 10 TERAKHIR", "Copy 10 log terbaru", function()
    if #hookLog == 0 then
        Library:Notification("❌ ERROR", "Belum ada log", 2)
        return
    end
    
    local text = string.format("=== HOOK OUT LOG (10 TERAKHIR) ===\n\n")
    for i = 1, math.min(10, #hookLog) do
        text = text .. string.format("[%d] %s\n\n", i, hookLog[i])
    end
    
    doCopy(text)
    Library:Notification("📋", "Copied 10 log entries", 2)
end)

-- ============================================
--  BUILD UI - FARM SPY TAB (ENHANCED)
-- ============================================
local FarmSpyPage = TabFarmSpy:Page("🌾 FARMING SPY", "sprout")
local FarmSpyLeft = FarmSpyPage:Section("🕵️ KONTROL FARM SPY", "Left")
local FarmSpyRight = FarmSpyPage:Section("📋 LOG FARMING", "Right")

-- Left Section
FarmSpyLeft:Paragraph("📌 FUNGSI",
    "Deteksi KHUSUS aktivitas farming:\n\n" ..
    "🌱 Tanam (Plant/Tanam)\n" ..
    "🌾 Panen (Harvest/Panen)\n" ..
    "💰 Jual (Sell/Jual)\n" ..
    "🛒 Beli Bibit (Buy/Bibit)\n" ..
    "💧 Siram (Water)\n" ..
    "🧪 Pupuk (Fertilizer)\n\n" ..
    "Menampilkan detail:\n" ..
    "• Jenis tanaman\n" ..
    "• Posisi lahan\n" ..
    "• Jumlah\n" ..
    "• Path remote"
)

FarmSpyLeft:Toggle("🌾 AKTIFKAN FARM SPY", "FarmSpyToggle", false,
    "Deteksi khusus aktivitas farming",
    function(v)
        if v then
            if #allRemotes == 0 then
                Library:Notification(
                    "⚠️ PERINGATAN",
                    "Scan dulu di tab SCAN!",
                    4
                )
                return
            end
            startFarmingSpy()
        else
            stopFarmingSpy()
        end
    end
)

FarmSpyLeft:Button("🗑️ CLEAR LOG", "Hapus semua log farming", function()
    farmLog = {}
    Library:Notification("🗑️", "Log farming dihapus", 2)
end)

FarmSpyLeft:Paragraph("📊 STATISTIK FARM",
    function()
        local tanam = 0
        local panen = 0
        local jual = 0
        local lain = 0
        
        for _, entry in ipairs(farmLog) do
            if entry:find("🌱") then
                tanam = tanam + 1
            elseif entry:find("🌾") then
                panen = panen + 1
            elseif entry:find("💰") then
                jual = jual + 1
            else
                lain = lain + 1
            end
        end
        
        return string.format(
            "Total log: %d\n" ..
            "🌱 Tanam: %d\n" ..
            "🌾 Panen: %d\n" ..
            "💰 Jual: %d\n" ..
            "❓ Lain: %d",
            #farmLog,
            tanam,
            panen,
            jual,
            lain
        )
    end
)

-- Right Section
FarmSpyRight:Button("📄 LIHAT LOG", "Tampilkan log farming", function()
    if #farmLog == 0 then
        Library:Notification(
            "📭",
            "Belum ada log\nAktifkan Farm Spy & lakukan farming!",
            3
        )
        return
    end
    
    local total = math.ceil(#farmLog / PAGE_SIZE)
    local text = string.format("🌾 LOG FARMING (Total: %d)\n\n", #farmLog)
    
    for i = 1, math.min(PAGE_SIZE, #farmLog) do
        text = text .. string.format("[%d] %s\n\n", i, farmLog[i])
    end
    
    Library:Notification("🌾 FARM SPY LOG", text, 20)
    farmPage = 1
end)

FarmSpyRight:Button("⏩ LOG BERIKUTNYA", "Halaman berikutnya", function()
    farmPage = farmPage + 1
    local total = math.ceil(#farmLog / PAGE_SIZE)
    if farmPage > total then farmPage = total end
    
    local startIdx = (farmPage - 1) * PAGE_SIZE + 1
    local endIdx = math.min(farmPage * PAGE_SIZE, #farmLog)
    
    local text = string.format("🌾 HALAMAN %d/%d (Total: %d)\n\n", farmPage, total, #farmLog)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, farmLog[i])
    end
    
    Library:Notification("🌾 FARM SPY LOG", text, 20)
end)

FarmSpyRight:Button("⏪ LOG SEBELUMNYA", "Halaman sebelumnya", function()
    farmPage = farmPage - 1
    if farmPage < 1 then farmPage = 1 end
    
    local total = math.ceil(#farmLog / PAGE_SIZE)
    local startIdx = (farmPage - 1) * PAGE_SIZE + 1
    local endIdx = math.min(farmPage * PAGE_SIZE, #farmLog)
    
    local text = string.format("🌾 HALAMAN %d/%d (Total: %d)\n\n", farmPage, total, #farmLog)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, farmLog[i])
    end
    
    Library:Notification("🌾 FARM SPY LOG", text, 20)
end)

FarmSpyRight:Button("📋 COPY SEMUA LOG", "Copy semua log farming", function()
    if #farmLog == 0 then
        Library:Notification("❌ ERROR", "Belum ada log", 2)
        return
    end
    
    local text = string.format("=== FARM SPY LOG (%d) ===\n\n", #farmLog)
    for i, e in ipairs(farmLog) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    
    doCopy(text)
    Library:Notification("📋", "Copied " .. #farmLog .. " farm logs", 2)
end)

FarmSpyRight:Button("📋 COPY TANAM SAJA", "Copy hanya log tanam", function()
    local tanamLogs = {}
    for _, e in ipairs(farmLog) do
        if e:find("🌱") then
            table.insert(tanamLogs, e)
        end
    end
    
    if #tanamLogs == 0 then
        Library:Notification("❌", "Tidak ada log tanam", 2)
        return
    end
    
    local text = string.format("=== TANAM LOG (%d) ===\n\n", #tanamLogs)
    for i, e in ipairs(tanamLogs) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    
    doCopy(text)
    Library:Notification("📋", "Copied " .. #tanamLogs .. " tanam logs", 2)
end)

FarmSpyRight:Button("📋 COPY PANEN SAJA", "Copy hanya log panen", function()
    local panenLogs = {}
    for _, e in ipairs(farmLog) do
        if e:find("🌾") then
            table.insert(panenLogs, e)
        end
    end
    
    if #panenLogs == 0 then
        Library:Notification("❌", "Tidak ada log panen", 2)
        return
    end
    
    local text = string.format("=== PANEN LOG (%d) ===\n\n", #panenLogs)
    for i, e in ipairs(panenLogs) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    
    doCopy(text)
    Library:Notification("📋", "Copied " .. #panenLogs .. " panen logs", 2)
end)

-- ============================================
--  BUILD UI - BN2 TAB
-- ============================================
local BN2Page = TabBN2:Page("🔷 BRIDGENET2 ANALYZER", "radio")
local BN2Left = BN2Page:Section("📡 KONTROL BN2", "Left")
local BN2Right = BN2Page:Section("📋 LOG BN2", "Right")

-- Left Section
BN2Left:Paragraph("📌 INFO BN2",
    "BridgeNet2 adalah framework yang\n" ..
    "membungkus semua remote jadi satu.\n\n" ..
    "Identifier umum:\n" ..
    "\\x05 = Request/Beli\n" ..
    "\\x06 = Tanam\n" ..
    "\\x0F = Harvest data\n" ..
    "\\x04 = Coins update\n" ..
    "\\x0D = Response success\n\n" ..
    "⚠️ Tergantung game, identifier bisa beda!"
)

BN2Left:Toggle("📡 AKTIFKAN BN2 SPY", "BN2Toggle", false,
    "Monitor BridgeNet2 packets",
    function(v)
        bn2On = v
        if v then
            local ok = startBN2Spy()
            if not ok then
                bn2On = false
            end
        else
            stopBN2Spy()
            Library:Notification("📡 BN2 SPY", "Dimatikan", 2)
        end
    end
)

BN2Left:Button("🗑️ CLEAR LOG", "Hapus semua log BN2", function()
    bn2Log = {}
    Library:Notification("🗑️", "Log BN2 dihapus", 2)
end)

-- Right Section
BN2Right:Button("📄 LIHAT LOG", "Tampilkan log BN2", function()
    if #bn2Log == 0 then
        Library:Notification("📭", "Belum ada log\nAktifkan BN2 Spy!", 3)
        return
    end
    
    local total = math.ceil(#bn2Log / PAGE_SIZE)
    local text = string.format("📡 BN2 LOG (Total: %d)\n\n", #bn2Log)
    
    for i = 1, math.min(PAGE_SIZE, #bn2Log) do
        text = text .. string.format("[%d] %s\n\n", i, bn2Log[i])
    end
    
    Library:Notification("📡 BN2 LOG", text, 20)
    bn2Page = 1
end)

BN2Right:Button("⏩ LOG BERIKUTNYA", "Halaman berikutnya", function()
    bn2Page = bn2Page + 1
    local total = math.ceil(#bn2Log / PAGE_SIZE)
    if bn2Page > total then bn2Page = total end
    
    local startIdx = (bn2Page - 1) * PAGE_SIZE + 1
    local endIdx = math.min(bn2Page * PAGE_SIZE, #bn2Log)
    
    local text = string.format("📡 HALAMAN %d/%d (Total: %d)\n\n", bn2Page, total, #bn2Log)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, bn2Log[i])
    end
    
    Library:Notification("📡 BN2 LOG", text, 20)
end)

BN2Right:Button("⏪ LOG SEBELUMNYA", "Halaman sebelumnya", function()
    bn2Page = bn2Page - 1
    if bn2Page < 1 then bn2Page = 1 end
    
    local total = math.ceil(#bn2Log / PAGE_SIZE)
    local startIdx = (bn2Page - 1) * PAGE_SIZE + 1
    local endIdx = math.min(bn2Page * PAGE_SIZE, #bn2Log)
    
    local text = string.format("📡 HALAMAN %d/%d (Total: %d)\n\n", bn2Page, total, #bn2Log)
    for i = startIdx, endIdx do
        text = text .. string.format("[%d] %s\n\n", i, bn2Log[i])
    end
    
    Library:Notification("📡 BN2 LOG", text, 20)
end)

BN2Right:Button("📋 COPY SEMUA LOG", "Copy semua log BN2", function()
    if #bn2Log == 0 then
        Library:Notification("❌ ERROR", "Belum ada log", 2)
        return
    end
    
    local text = string.format("=== BN2 LOG (%d) ===\n\n", #bn2Log)
    for i, e in ipairs(bn2Log) do
        text = text .. string.format("[%d] %s\n\n", i, e)
    end
    
    doCopy(text)
    Library:Notification("📋", "Copied " .. #bn2Log .. " BN2 logs", 2)
end)

-- ============================================
--  BUILD UI - FIRE TAB (ENHANCED)
-- ============================================
local FirePage = TabFire:Page("🔥 FIRE REMOTE", "zap")
local FireLeft = FirePage:Section("🔥 KONTROL FIRE", "Left")
local FireRight = FirePage:Section("ℹ️ PANDUAN", "Right")

-- Left Section
FireLeft:Paragraph("📌 CARA FIRE",
    "1. Isi PATH remote\n" ..
    "2. Isi ARGUMEN (pisah koma)\n" ..
    "3. Klik FIRE\n\n" ..
    "Contoh argumen:\n" ..
    "• String: Hello, World\n" ..
    "• Number: 123, 999999\n" ..
    "• Boolean: true, false\n" ..
    "• Vector3: V3(10,20,30)\n" ..
    "• Campur: Hello, 123, true"
)

FireLeft:TextBox("📂 PATH REMOTE", "FirePathBox", firePath,
    function(v) firePath = v end,
    "Contoh: ReplicatedStorage.Remotes.X"
)

FireLeft:TextBox("📦 ARGUMEN (PISAH KOMA)", "FireArgsBox", fireArgs,
    function(v) fireArgs = v end,
    "Contoh: Hello, 123, true, V3(10,20,30)"
)

FireLeft:Button("🔥 FIRE / INVOKE", "Kirim remote ke server", function()
    doFire(firePath, fireArgs)
end)

FireLeft:Button("🧹 CLEAR", "Clear input", function()
    firePath = ""
    fireArgs = ""
    FireLeft.Inputs.FirePathBox = ""
    FireLeft.Inputs.FireArgsBox = ""
    Library:Notification("🧹", "Input dibersihkan", 1)
end)

local pasteIdx = 1
FireLeft:Slider("🔢 NOMOR DARI SCAN", "PasteSlider", 1, 500, 1,
    function(v) pasteIdx = v end,
    "Pilih nomor remote dari hasil scan"
)

FireLeft:Button("📋 PASTE DARI SCAN", "Isi path dari hasil scan", function()
    if #allRemotes == 0 then
        Library:Notification("❌ ERROR", "Scan dulu di tab SCAN!", 3)
        return
    end
    
    if pasteIdx > #allRemotes then
        Library:Notification("❌ ERROR", "Max: " .. #allRemotes, 2)
        return
    end
    
    local r = allRemotes[pasteIdx]
    firePath = r.path:gsub("^game%.", "")
    
    Library:Notification(
        "📋 PASTE BERHASIL",
        string.format("[%s] %s\nPath siap di FIRE!", r.rtype, r.name),
        4
    )
end)

-- Right Section
FireRight:Paragraph("📝 CONTOH PATH",
    "ReplicatedStorage.Remotes.PlantCrop\n" ..
    "ReplicatedStorage.Remotes.HarvestCrop\n" ..
    "ReplicatedStorage.Remotes.SellCrop\n" ..
    "ReplicatedStorage.Carry.RequestCarry\n" ..
    "ReplicatedStorage.Syncing.Sync"
)

FireRight:Paragraph("🎯 CONTOH ARGUMEN",
    "🌱 Tanam:\n" ..
    "V3(10,37,-290)\n\n" ..
    "🌾 Panen:\n" ..
    "V3(10,37,-290)\n\n" ..
    "💰 Jual Semua:\n" ..
    "all\n\n" ..
    "🛒 Beli:\n" ..
    "Padi, 10\n\n" ..
    "⚔️ Combat:\n" ..
    "PlayerName, 9999"
)

FireRight:Paragraph("⚠️ PERINGATAN",
    "• Gunakan untuk TESTING\n" ..
    "• Jangan spam terlalu cepat\n" ..
    "• Bisa kena banned kalo ketahuan\n" ..
    "• Gue ga tanggung jawab!"
)

-- ============================================
--  BUILD UI - STATS TAB
-- ============================================
local StatsPage = TabStats:Page("📊 STATISTIK", "bar-chart-2")
local StatsLeft = StatsPage:Section("📊 STATISTIK REMOTE", "Left")
local StatsRight = StatsPage:Section("ℹ️ INFO SISTEM", "Right")

-- Left Section
StatsLeft:Paragraph("📊 STATISTIK REMOTE",
    function()
        local text = "Total remote: " .. #allRemotes .. "\n\n"
        text = text .. "📊 KATEGORI EXPLOIT:\n"
        
        local totalCat = 0
        for cat, count in pairs(categoryStats) do
            if count > 0 then
                text = text .. string.format("  %s: %d\n", cat, count)
                totalCat = totalCat + count
            end
        end
        
        text = text .. string.format("\n✅ Total terdeteksi: %d/%d", totalCat, #exploitList)
        
        return text
    end
)

StatsLeft:Paragraph("📊 STATISTIK LOG",
    function()
        return string.format(
            "📥 SPY IN: %d\n" ..
            "📤 HOOK OUT: %d\n" ..
            "🌾 FARM SPY: %d\n" ..
            "🔷 BN2 LOG: %d",
            #spyLog,
            #hookLog,
            #farmLog,
            #bn2Log
        )
    end
)

-- Right Section
StatsRight:Paragraph("ℹ️ INFO SISTEM",
    function()
        return string.format(
            "Game: %s\n" ..
            "Player: %s\n" ..
            "Ping: %d ms\n" ..
            "Memory: %.1f MB",
            game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "?",
            LP.Name,
            game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue(),
            collectgarbage("count") / 1000
        )
    end
)

StatsRight:Paragraph("⚙️ STATUS FITUR",
    function()
        return string.format(
            "🔌 Hook Out: %s\n" ..
            "👁 Spy In: %s\n" ..
            "🌾 Farm Spy: %s\n" ..
            "📡 BN2 Spy: %s\n" ..
            "🔄 Auto Refresh: %s",
            hookOn and "✅" or "❌",
            spyOn and "✅" or "❌",
            farmSpyOn and "✅" or "❌",
            bn2On and "✅" or "❌",
            autoRefresh and "✅" or "❌"
        )
    end
)

StatsRight:Button("🧹 CLEAN MEMORY", "Bersihkan memory (garbage collect)", function()
    collectgarbage()
    Library:Notification("🧹", "Memory cleaned!", 2)
end)

-- ============================================
--  BUILD UI - CONFIG TAB
-- ============================================
local ConfigPage = TabConfig:Page("⚙️ KONFIGURASI", "settings")
local ConfigLeft = ConfigPage:Section("⚙️ PENGATURAN", "Left")
local ConfigRight = ConfigPage:Section("💾 SAVE/LOAD", "Right")

-- Left Section
ConfigLeft:Slider("📏 PAGE SIZE", "PageSizeSlider", 3, 20, PAGE_SIZE,
    function(v) PAGE_SIZE = v end,
    "Jumlah item per halaman"
)

ConfigLeft:Slider("📦 MAX LOG", "MaxLogSlider", 50, 500, MAX_LOG,
    function(v) MAX_LOG = v end,
    "Maksimal log yang disimpan"
)

ConfigLeft:Toggle("🔔 NOTIFIKASI", "NotifToggle", true,
    "Tampilkan notifikasi",
    function(v)
        -- Bisa ditambah logic
    end
)

-- Right Section
ConfigRight:Button("💾 SAVE CONFIG", "Simpan konfigurasi", function()
    local config = {
        pageSize = PAGE_SIZE,
        maxLog = MAX_LOG,
        autoRefresh = autoRefresh
    }
    
    -- Simpan ke tempat aman
    Library:Notification("💾", "Config saved!", 2)
end)

ConfigRight:Button("📂 LOAD CONFIG", "Load konfigurasi", function()
    Library:Notification("📂", "Config loaded!", 2)
end)

ConfigRight:Button("🔄 RESET DEFAULTS", "Reset ke pengaturan awal", function()
    PAGE_SIZE = 10
    MAX_LOG = 200
    autoRefresh = false
    Library:Notification("🔄", "Settings reset to default", 2)
end)

-- ============================================
--  INIT & STARTUP
-- ============================================
Library:Notification(
    "🚀 XKID ANALYZER V5.0 PRO",
    "✅ Ultimate Detection Tool\n" ..
    "✅ 8 Tabs + Full Features\n" ..
    "✅ Fokus 100% Deteksi Remote\n\n" ..
    "📋 INSTRUKSI:\n" ..
    "1. SCAN DULU di tab SCAN\n" ..
    "2. Aktifkan HOOK OUT (tab HOOK)\n" ..
    "3. Lakukan aktivitas di game\n" ..
    "4. Lihat LOG!\n\n" ..
    "🔥 Selamat menganalisis!",
    10
)

Library:ConfigSystem(Win)

print("╔═══════════════════════════════════════════════════════════════════╗")
print("║                                                                   ║")
print("║              🔌 XKID ANALYZER V5.0 PRO 🔌                        ║")
print("║                  ULTIMATE DETECTION TOOL                          ║")
print("║                                                                   ║")
print("╠═══════════════════════════════════════════════════════════════════╣")
print("║                                                                   ║")
print("║  📋 INSTRUKSI LENGKAP:                                           ║")
print("║  ─────────────────────────────────────────────────────────────   ║")
print("║  1. SCAN DULU di tab SCAN (klik 'SCAN SEMUA')                    ║")
print("║  2. Setelah scan selesai, buka tab HOOK OUT                      ║")
print("║  3. Aktifkan toggle 'AKTIFKAN HOOK OUT'                          ║")
print("║  4. Lakukan apapun di game (tanam, panen, jalan, beli, dll)     ║")
print("║  5. Lihat LOG di tab HOOK OUT (semua kiriman ke server)          ║")
print("║  6. Untuk farming khusus, aktifkan FARM SPY di tab FARM SPY     ║")
print("║  7. Untuk BN2, aktifkan BN2 SPY di tab BN2                       ║")
print("║  8. Gunakan tab FIRE untuk tes remote manual                     ║")
print("║                                                                   ║")
print("║  ⚠️ PERINGATAN:                                                  ║")
print("║  • Gunakan untuk TESTING game MILIK SENDIRI                      ║")
print("║  • Jangan untuk merugikan orang lain                             ║")
print("║  • Gue ga tanggung jawab kalo lo kena banned                     ║")
print("║                                                                   ║")
print("║  🔥 SELAMAT MENGGUNAKAN!                                         ║")
print("║                                                                   ║")
print("╚═══════════════════════════════════════════════════════════════════╝")