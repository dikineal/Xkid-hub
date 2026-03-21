--[[
╔═══════════════════════════════════════════════════════════╗
║        🔍  X K I D   D E B U G   T O O L  v4            ║
║         Aurora UI · setclipboard · Delta Ready           ║
╚═══════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LP        = Players.LocalPlayer

local function notif(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  LOG BUFFER                                             │
-- └─────────────────────────────────────────────────────────┘
local LogBuffer = ""

local function log(msg)
    LogBuffer = LogBuffer .. os.date("[%H:%M:%S] ") .. msg .. "\n"
end

local function clearLog()
    LogBuffer = ""
end

local function copyLog()
    if LogBuffer == "" then
        notif("Copy","Log kosong! Jalankan scan dulu.",3)
        return
    end
    local ok = pcall(function()
        setclipboard(LogBuffer)
    end)
    if ok then
        local lineCount = 0
        for _ in LogBuffer:gmatch("\n") do lineCount = lineCount + 1 end
        notif("✅ COPIED!",lineCount.." baris log\nsudah di-copy ke clipboard!\nPaste ke WA / chat",4)
    else
        notif("❌ Copy Gagal",
            "setclipboard tidak didukung\ndi executor ini.\nCoba screenshot notif.",4)
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  WORKSPACE SCANNER                                      │
-- └─────────────────────────────────────────────────────────┘
local function scanRange(a, b)
    local allCh = Workspace:GetChildren()
    log("=== SCAN ["..a.."-"..b.."] | Total WS: "..#allCh.." ===")
    for i = a, math.min(b, #allCh) do
        local obj = allCh[i]
        if not obj then log("["..i.."] nil"); continue end
        local pos, size = "", ""
        if obj:IsA("BasePart") then
            pos  = string.format(" pos=(%.1f,%.1f,%.1f)", obj.Position.X, obj.Position.Y, obj.Position.Z)
            size = string.format(" sz=(%.1f,%.1f,%.1f)",  obj.Size.X, obj.Size.Y, obj.Size.Z)
        else
            local p = obj:FindFirstChildOfClass("BasePart")
            if p then pos = string.format(" pos=(%.1f,%.1f,%.1f)", p.Position.X, p.Position.Y, p.Position.Z) end
            pos = pos .. " ch=" .. #obj:GetChildren()
        end
        log(string.format("[%d] %s (%s)%s%s", i, obj.Name, obj.ClassName, pos, size))
    end
    log("=== SELESAI ===")
    notif("✅ Scan ["..a.."-"..b.."]","Klik COPY LOG untuk copy!",3)
end

local function scanFull()
    local allCh = Workspace:GetChildren()
    log("=== FULL SCAN | Total: "..#allCh.." ===")
    for i, obj in ipairs(allCh) do
        local pos, size, tag = "", "", ""
        if obj:IsA("BasePart") then
            pos  = string.format(" pos=(%.0f,%.0f,%.0f)", obj.Position.X, obj.Position.Y, obj.Position.Z)
            size = string.format(" sz=(%.0f,%.0f,%.0f)",  obj.Size.X, obj.Size.Y, obj.Size.Z)
            if obj.Size.X > 5 and obj.Size.Z > 5 then tag = " [BIGPART]" end
        else
            local p = obj:FindFirstChildOfClass("BasePart")
            if p then
                pos = string.format(" pos=(%.0f,%.0f,%.0f)", p.Position.X, p.Position.Y, p.Position.Z)
                if p.Size.X > 5 and p.Size.Z > 5 then tag = " [BIGPART]" end
            end
            pos = pos .. " ch=" .. #obj:GetChildren()
        end
        local n = obj.Name:lower()
        if n:find("land") or n:find("farm") or n:find("plot") or
           n:find("lahan") or n:find("tanah") or n:find("sawah") then
            tag = tag .. " [LAND]"
        end
        log(string.format("[%d] %s (%s)%s%s%s", i, obj.Name, obj.ClassName, pos, size, tag))
    end
    log("=== SELESAI ===")
    notif("✅ Full Scan","Klik COPY LOG!",3)
end

local function scanLand()
    log("=== workspace.Land ===")
    local land = Workspace:FindFirstChild("Land")
    if not land then log("TIDAK ADA!"); notif("Land","Tidak ada",3); return end
    log("Class: "..land.ClassName)
    if land:IsA("BasePart") then
        log(string.format("Pos=(%.2f,%.2f,%.2f) Size=(%.2f,%.2f,%.2f)",
            land.Position.X, land.Position.Y, land.Position.Z,
            land.Size.X, land.Size.Y, land.Size.Z))
    end
    local ch = land:GetChildren()
    log("Children: "..#ch)
    for i, c in ipairs(ch) do
        local p = ""
        if c:IsA("BasePart") then
            p = string.format(" pos=(%.1f,%.1f,%.1f)", c.Position.X, c.Position.Y, c.Position.Z)
        end
        log(string.format("  [%d] %s (%s)%s", i, c.Name, c.ClassName, p))
    end
    local bps = 0
    for _, d in ipairs(land:GetDescendants()) do
        if d:IsA("BasePart") then
            bps = bps + 1
            if bps <= 10 then
                log(string.format("  BP[%d] %s pos=(%.1f,%.1f,%.1f)",
                    bps, d.Name, d.Position.X, d.Position.Y, d.Position.Z))
            end
        end
    end
    log("Total BasePart: "..bps)
    log("=== SELESAI ===")
    notif("workspace.Land","Klik COPY LOG!",3)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  FISH MONITOR                                           │
-- └─────────────────────────────────────────────────────────┘
local fishConns = {}

local function startFish()
    for _, c in pairs(fishConns) do pcall(function() c:Disconnect() end) end
    fishConns = {}
    local fr = RS:FindFirstChild("FishRemotes")
    if not fr then
        notif("Fish ❌","FishRemotes tidak ada!",4); return false
    end
    log("=== FISH MONITOR START ===")
    for _, evName in ipairs({"CastEvent","MiniGame","NotifyClient"}) do
        local ev = fr:FindFirstChild(evName)
        if ev then
            log("Listen OK: "..evName)
            local conn = ev.OnClientEvent:Connect(function(...)
                local parts = {}
                for _, a in ipairs({...}) do
                    local s = "?"
                    pcall(function()
                        s = (type(a)=="userdata") and (a.Name or tostring(a)) or tostring(a)
                    end)
                    table.insert(parts, s)
                end
                log("← "..evName..": "..table.concat(parts, ", "))
            end)
            table.insert(fishConns, conn)
        else
            log("MISSING: "..evName)
        end
    end
    log("Mancing manual 1x sekarang!")
    notif("🎣 Fish Monitor","ON! Mancing manual 1x\nlalu klik COPY LOG",4)
    return true
end

local function stopFish()
    for _, c in pairs(fishConns) do pcall(function() c:Disconnect() end) end
    fishConns = {}
    log("=== FISH MONITOR STOP ===")
    notif("Fish","OFF — Klik COPY LOG",3)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  INVENTORY MONITOR                                      │
-- └─────────────────────────────────────────────────────────┘
local invConn = nil

local function startInv()
    if invConn then invConn:Disconnect() end
    local bn = RS:FindFirstChild("BridgeNet2")
    local ev = bn and bn:FindFirstChild("dataRemoteEvent")
    if not ev then notif("Inv ❌","dataRemoteEvent tidak ada!",4); return false end
    log("=== INVENTORY MONITOR START ===")
    invConn = ev.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        local keys = {}
        for k in pairs(data) do
            table.insert(keys, string.format("\\x%02x", string.byte(k,1)))
        end
        log("Keys: "..table.concat(keys," "))
        if data["\3"] then
            local list = data["\3"][1]
            if type(list)=="table" then
                log("--- Inventory ---")
                for slot, e in ipairs(list) do
                    if type(e)=="table" and e.cropName then
                        log(string.format("slot[%d] %s x%d", slot, e.cropName, e.count or 0))
                    end
                end
            end
        end
    end)
    notif("📦 Inv Monitor","ON! Beli bibit lalu\nklik COPY LOG",4)
    return true
end

local function stopInv()
    if invConn then invConn:Disconnect(); invConn=nil end
    log("=== INVENTORY MONITOR STOP ===")
    notif("Inv","OFF — Klik COPY LOG",3)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  UI                                                     │
-- └─────────────────────────────────────────────────────────┘
local Win    = Library:Window("XKID DEBUG v4","search","v4",false)
Win:TabSection("DEBUG")
local T_Scan = Win:Tab("Scan","search")
local T_Fish = Win:Tab("Fish","anchor")
local T_Inv  = Win:Tab("Inv","package")

-- ── COPY LOG BUTTON — Ada di semua tab ──────────────────

-- ╔══════════════════╗
-- ║   TAB SCAN       ║
-- ╚══════════════════╝
local SP = T_Scan:Page("Workspace Scan","search")
local SL = SP:Section("🔍 Scan","Left")
local SR = SP:Section("📋 Copy","Right")

SL:Button("★ FULL SCAN","Scan semua workspace objects",
    function() clearLog(); scanFull() end)

SL:Button("Index 40-55","",
    function() clearLog(); scanRange(40,55) end)

SL:Button("Index 50-65","",
    function() clearLog(); scanRange(50,65) end)

SL:Button("Index 60-75","",
    function() clearLog(); scanRange(60,75) end)

SL:Button("Index 70-85","",
    function() clearLog(); scanRange(70,85) end)

SL:Button("workspace.Land","Detail struktur Land",
    function() clearLog(); scanLand() end)

SL:Button("Posisi Karakter","",
    function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            log(string.format("POS X=%.4f Y=%.4f Z=%.4f",
                hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
            notif("Posisi",string.format("X=%.2f Y=%.2f Z=%.2f",
                hrp.Position.X, hrp.Position.Y, hrp.Position.Z),5)
        end
    end)

-- COPY BUTTON
SR:Button("📋 COPY LOG","Salin semua log ke clipboard",
    function() copyLog() end)

SR:Button("🗑 Clear Log","Hapus log",
    function() clearLog(); notif("Log","Cleared",2) end)

SR:Button("📊 Info Log","Lihat info log saat ini",
    function()
        local lines = 0
        for _ in LogBuffer:gmatch("\n") do lines = lines + 1 end
        notif("Log Info","Lines: "..lines.."\nChars: "..#LogBuffer,4)
    end)

SR:Paragraph("Cara Copy",
    "1. Klik tombol scan\n"..
    "2. Klik 📋 COPY LOG\n"..
    "3. Log otomatis masuk\n"..
    "   ke clipboard!\n"..
    "4. Paste di WA/chat")

-- ╔══════════════════╗
-- ║   TAB FISH       ║
-- ╚══════════════════╝
local FP = T_Fish:Page("Fish Monitor","anchor")
local FL = FP:Section("🎣 Monitor","Left")
local FR = FP:Section("📋 Copy","Right")

FL:Toggle("Fish Monitor","fishMon",false,
    "Listen semua FishRemotes events",
    function(v)
        clearLog()
        if v then startFish() else stopFish() end
    end)

FL:Paragraph("Cara",
    "1. ON Fish Monitor\n"..
    "2. Mancing manual 1x\n"..
    "   (sampai dapat ikan!)\n"..
    "3. OFF Fish Monitor\n"..
    "4. Klik COPY LOG")

FR:Button("📋 COPY LOG","Copy hasil fish monitor",
    function() copyLog() end)

FR:Button("🗑 Clear","Hapus log",
    function() clearLog(); notif("Clear","OK",2) end)

-- ╔══════════════════╗
-- ║   TAB INVENTORY  ║
-- ╚══════════════════╝
local IP = T_Inv:Page("Inv Monitor","package")
local IL = IP:Section("📦 Monitor","Left")
local IR = IP:Section("📋 Copy","Right")

IL:Toggle("Inv Monitor","invMon",false,
    "Listen inventory data dari server",
    function(v)
        clearLog()
        if v then startInv() else stopInv() end
    end)

IL:Button("Force Request","Trigger server kirim inventory",
    function()
        local bn = RS:FindFirstChild("BridgeNet2")
        local ev = bn and bn:FindFirstChild("dataRemoteEvent")
        if not ev then notif("Err","Remote tidak ada!",3); return end
        pcall(function()
            ev:FireServer({{ cropName="Sawi", amount=0 }, "\x07"})
        end)
        log("Force request dikirim...")
        notif("Request","Dikirim! Tunggu 2s",3)
    end)

IL:Paragraph("Cara",
    "1. ON Inv Monitor\n"..
    "2. Beli 1 bibit di shop\n"..
    "   ATAU klik Force Request\n"..
    "3. Tunggu 2-3 detik\n"..
    "4. OFF Monitor\n"..
    "5. Klik COPY LOG")

IR:Button("📋 COPY LOG","Copy hasil inventory monitor",
    function() copyLog() end)

IR:Button("🗑 Clear","Hapus log",
    function() clearLog(); notif("Clear","OK",2) end)

-- ┌─────────────────────────────────────────────────────────┐
-- │  INIT                                                   │
-- └─────────────────────────────────────────────────────────┘
Library:Notification("XKID DEBUG v4",
    "Scan · Fish · Inv\nKlik scan → COPY LOG → Paste!",5)
Library:ConfigSystem(Win)

log("XKID Debug v4 loaded | "..LP.Name)
log("WS children: "..#Workspace:GetChildren())
