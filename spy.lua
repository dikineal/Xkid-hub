--[[
╔═══════════════════════════════════════════════════════════╗
║        🔍  X K I D   D E B U G   T O O L  v3            ║
║           Aurora UI · Copy Log · No Console              ║
╚═══════════════════════════════════════════════════════════╝
  Cara pakai:
  1. Klik tombol scan / monitor
  2. Hasilnya muncul di TextBox bawah
  3. Tap TextBox → Select All → Copy
  4. Kirim ke developer
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
-- │  COPYABLE LOG BUFFER                                    │
-- │  Semua output masuk ke buffer ini                       │
-- │  Ditampilkan di TextBox yang bisa di-select & copy      │
-- └─────────────────────────────────────────────────────────┘
local LogBuffer = ""
local LogCount  = 0

local function addLog(msg)
    LogCount = LogCount + 1
    LogBuffer = LogBuffer..os.date("[%H:%M:%S] ")..msg.."\n"
    -- Batasi ukuran buffer (keep 300 baris terakhir)
    local lines = {}
    for line in LogBuffer:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    if #lines > 300 then
        local trimmed = {}
        for i = #lines - 299, #lines do
            table.insert(trimmed, lines[i])
        end
        LogBuffer = table.concat(trimmed, "\n").."\n"
    end
end

local function clearLog()
    LogBuffer = ""
    LogCount  = 0
end

-- TextBox reference — diisi setelah UI dibuat
local LogTextBox = nil

local function updateTextBox(text)
    if LogTextBox then
        pcall(function()
            LogTextBox.Text = text
        end)
    end
end

local function flushToTextBox()
    updateTextBox(LogBuffer)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  WORKSPACE SCANNER                                      │
-- └─────────────────────────────────────────────────────────┘
local function runScan(indexStart, indexEnd)
    local allCh = Workspace:GetChildren()
    addLog("=== WORKSPACE SCAN ["..indexStart.."-"..indexEnd.."] ===")
    addLog("Total WS children: "..#allCh)
    addLog("")

    for i = indexStart, math.min(indexEnd, #allCh) do
        local obj = allCh[i]
        if obj then
            local pos  = ""
            local size = ""
            local extra= ""

            if obj:IsA("BasePart") then
                pos  = string.format(" pos=(%.1f,%.1f,%.1f)", obj.Position.X, obj.Position.Y, obj.Position.Z)
                size = string.format(" size=(%.1f,%.1f,%.1f)", obj.Size.X, obj.Size.Y, obj.Size.Z)
            else
                local p = obj:FindFirstChildOfClass("BasePart")
                if p then
                    pos = string.format(" pos=(%.1f,%.1f,%.1f)", p.Position.X, p.Position.Y, p.Position.Z)
                end
                local childCount = #obj:GetChildren()
                extra = " children="..childCount
            end

            addLog(string.format("[%d] %s (%s)%s%s%s",
                i, obj.Name, obj.ClassName, pos, size, extra))
        else
            addLog("[%d] (nil)")
        end
    end
    addLog("=== SELESAI ===")
    addLog("")
    flushToTextBox()
    notif("✅ Scan ["..indexStart.."-"..indexEnd.."]","Hasil ada di TextBox\nTap → Select All → Copy",5)
end

local function runFullScan()
    local allCh = Workspace:GetChildren()
    addLog("=== FULL WORKSPACE SCAN ===")
    addLog("Total: "..#allCh)
    addLog("")

    -- Scan semua, filter yang relevan
    for i, obj in ipairs(allCh) do
        local n = obj.Name:lower()
        local pos  = ""
        local size = ""
        local isBig = false

        if obj:IsA("BasePart") then
            pos  = string.format(" pos=(%.1f,%.1f,%.1f)", obj.Position.X, obj.Position.Y, obj.Position.Z)
            size = string.format(" size=(%.1f,%.1f,%.1f)", obj.Size.X, obj.Size.Y, obj.Size.Z)
            isBig = obj.Size.X > 5 and obj.Size.Z > 5
        else
            local p = obj:FindFirstChildOfClass("BasePart")
            if p then
                pos = string.format(" pos=(%.1f,%.1f,%.1f)", p.Position.X, p.Position.Y, p.Position.Z)
                isBig = p.Size.X > 5 and p.Size.Z > 5
            end
        end

        local isLand = n:find("land") or n:find("farm") or n:find("plot")
                    or n:find("lahan") or n:find("tanah") or n:find("field")
                    or n:find("sawah") or n:find("area")

        -- Tampilkan semua tapi tandai yang kemungkinan lahan
        local tag = ""
        if isLand then tag = " ★LAND" end
        if isBig  then tag = tag.." ★BIGPART" end

        addLog(string.format("[%d] %s (%s)%s%s%s",
            i, obj.Name, obj.ClassName, pos, size, tag))
    end

    addLog("")
    addLog("=== SELESAI ===")
    flushToTextBox()
    notif("✅ Full Scan","Hasil ada di TextBox!\nTap TextBox → Select All → Copy",6)
end

local function scanLand()
    addLog("=== workspace.Land DETAIL ===")
    local land = Workspace:FindFirstChild("Land")
    if not land then
        addLog("workspace.Land TIDAK ADA!")
        flushToTextBox()
        notif("Land","workspace.Land tidak ada!",4)
        return
    end

    addLog("ClassName: "..land.ClassName)
    if land:IsA("BasePart") then
        addLog(string.format("Position: (%.2f, %.2f, %.2f)", land.Position.X, land.Position.Y, land.Position.Z))
        addLog(string.format("Size: (%.2f, %.2f, %.2f)", land.Size.X, land.Size.Y, land.Size.Z))
    end

    local ch = land:GetChildren()
    addLog("Children count: "..#ch)
    for i, c in ipairs(ch) do
        local cpos = ""
        if c:IsA("BasePart") then
            cpos = string.format(" pos=(%.1f,%.1f,%.1f)", c.Position.X, c.Position.Y, c.Position.Z)
        end
        addLog(string.format("  [%d] %s (%s)%s", i, c.Name, c.ClassName, cpos))
    end

    -- Cek descendants juga
    local descs = land:GetDescendants()
    addLog("Descendants count: "..#descs)
    local bpCount = 0
    for _, d in ipairs(descs) do
        if d:IsA("BasePart") then
            bpCount = bpCount + 1
            if bpCount <= 20 then
                addLog(string.format("  BP: %s pos=(%.1f,%.1f,%.1f)",
                    d.Name, d.Position.X, d.Position.Y, d.Position.Z))
            end
        end
    end
    addLog("Total BasePart dalam Land: "..bpCount)
    addLog("=== SELESAI ===")
    addLog("")
    flushToTextBox()
    notif("workspace.Land","Hasil di TextBox!",5)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  FISH EVENT MONITOR                                     │
-- └─────────────────────────────────────────────────────────┘
local fishConns = {}
local fishOn    = false

local function startFishMonitor()
    for _, c in pairs(fishConns) do pcall(function() c:Disconnect() end) end
    fishConns = {}

    local fr = RS:FindFirstChild("FishRemotes")
    if not fr then
        addLog("FISH ERROR: FishRemotes tidak ada!")
        flushToTextBox()
        notif("Fish ❌","FishRemotes tidak ada!",4)
        return false
    end

    addLog("=== FISH MONITOR START ===")

    local evList = {"CastEvent","MiniGame","NotifyClient"}
    for _, evName in ipairs(evList) do
        local ev = fr:FindFirstChild(evName)
        if ev then
            addLog("Listen: "..evName.." OK")
            local conn = ev.OnClientEvent:Connect(function(...)
                local args = {...}
                local argParts = {}
                for _, a in ipairs(args) do
                    local s = "?"
                    pcall(function()
                        if type(a) == "userdata" then
                            s = a.Name or tostring(a)
                        else
                            s = tostring(a)
                        end
                    end)
                    table.insert(argParts, s)
                end
                local argStr = table.concat(argParts, ", ")
                addLog("← "..evName..": "..argStr)
                flushToTextBox()
            end)
            table.insert(fishConns, conn)
        else
            addLog("WARN: "..evName.." tidak ada!")
        end
    end

    addLog("Monitor aktif — mancing manual 1x!")
    addLog("")
    flushToTextBox()
    return true
end

local function stopFishMonitor()
    for _, c in pairs(fishConns) do pcall(function() c:Disconnect() end) end
    fishConns = {}
    addLog("=== FISH MONITOR STOP ===")
    addLog("")
    flushToTextBox()
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  INVENTORY MONITOR                                      │
-- └─────────────────────────────────────────────────────────┘
local invConn = nil

local function startInvMonitor()
    if invConn then invConn:Disconnect() end
    local bn = RS:FindFirstChild("BridgeNet2")
    local ev = bn and bn:FindFirstChild("dataRemoteEvent")
    if not ev then
        addLog("INV ERROR: dataRemoteEvent tidak ada!")
        flushToTextBox()
        return false
    end

    addLog("=== INVENTORY MONITOR START ===")
    addLog("Menunggu data \\x03 dari server...")
    flushToTextBox()

    invConn = ev.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end

        -- Log semua keys yang diterima
        local keys = {}
        for k, _ in pairs(data) do
            table.insert(keys, string.format("\\x%02x", string.byte(k)))
        end
        addLog("Remote keys: "..table.concat(keys, " "))

        -- Parse inventory key \x03
        if data["\3"] then
            addLog("=== INVENTORY DATA (\\x03) ===")
            local list = data["\3"][1]
            if type(list) == "table" then
                for slot, entry in ipairs(list) do
                    if type(entry) == "table" and entry.cropName then
                        addLog(string.format("slot[%d] = %s x%d",
                            slot, entry.cropName, entry.count or 0))
                    end
                end
            end
            addLog("")
        end

        flushToTextBox()
    end)

    return true
end

local function stopInvMonitor()
    if invConn then invConn:Disconnect(); invConn = nil end
    addLog("=== INVENTORY MONITOR STOP ===")
    flushToTextBox()
end

-- ┌─────────────────────────────────────────────────────────┐
-- │  UI                                                     │
-- └─────────────────────────────────────────────────────────┘
local Win    = Library:Window("XKID DEBUG v3","search","v3",false)
Win:TabSection("TOOLS")
local T_Scan = Win:Tab("Scan","search")
local T_Fish = Win:Tab("Fishing","anchor")
local T_Inv  = Win:Tab("Inventory","package")
local T_Copy = Win:Tab("📋 COPY","clipboard")

-- ╔══════════════════╗
-- ║   TAB SCAN       ║
-- ╚══════════════════╝
local SP = T_Scan:Page("Workspace Scan","search")
local SL = SP:Section("🔍 Scan Range","Left")
local SR = SP:Section("🔍 Scan Lainnya","Right")

SL:Button("★ FULL SCAN (Semua)","Scan semua workspace — PAKAI INI DULU",
    function()
        clearLog()
        runFullScan()
    end)

SL:Button("Index 40-55","",
    function() clearLog(); runScan(40,55) end)

SL:Button("Index 50-65","",
    function() clearLog(); runScan(50,65) end)

SL:Button("Index 60-75","",
    function() clearLog(); runScan(60,75) end)

SL:Button("Index 70-85","",
    function() clearLog(); runScan(70,85) end)

SR:Button("workspace.Land Detail","",
    function() clearLog(); scanLand() end)

SR:Button("Posisi Karakter","",
    function()
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local p = hrp.Position
            addLog(string.format("POS X=%.4f Y=%.4f Z=%.4f", p.X, p.Y, p.Z))
            flushToTextBox()
            notif("📍 Posisi",string.format("X=%.2f\nY=%.2f\nZ=%.2f",p.X,p.Y,p.Z),5)
        end
    end)

SR:Button("ReplicatedStorage","Scan isi RS",
    function()
        clearLog()
        addLog("=== REPLICATED STORAGE ===")
        for i, obj in ipairs(RS:GetChildren()) do
            local ch = obj:GetChildren()
            local chStr = ""
            if #ch > 0 then
                local names = {}
                for _, c in ipairs(ch) do table.insert(names, c.Name) end
                chStr = " → ["..table.concat(names,", ").."]"
            end
            addLog(string.format("[%d] %s (%s)%s", i, obj.Name, obj.ClassName, chStr))
        end
        addLog("=== SELESAI ===")
        flushToTextBox()
        notif("RS","Hasil di Copy tab",4)
    end)

SR:Paragraph("Cara Copy",
    "1. Klik tombol scan\n"..
    "2. Pergi ke tab 📋 COPY\n"..
    "3. Tap TextBox\n"..
    "4. Select All → Copy\n"..
    "5. Kirim ke developer!")

-- ╔══════════════════╗
-- ║   TAB FISHING    ║
-- ╚══════════════════╝
local FP = T_Fish:Page("Fish Monitor","anchor")
local FL = FP:Section("🎣 Monitor","Left")
local FR = FP:Section("📋 Info","Right")

FL:Toggle("▶ Fish Monitor ON/OFF","fishMon",false,
    "Monitor semua FishRemotes events",
    function(v)
        fishOn = v
        if v then
            clearLog()
            local ok = startFishMonitor()
            if ok then
                notif("🎣 Fish Monitor","ON!\nMancing manual 1x\nlalu lihat tab 📋 COPY",4)
            end
        else
            stopFishMonitor()
            notif("Fish Monitor","OFF | Hasil di Copy tab",3)
        end
    end)

FL:Button("🗑 Clear Log","Hapus semua log",
    function()
        clearLog()
        flushToTextBox()
        notif("Log","Dibersihkan",2)
    end)

FR:Paragraph("Cara Debug Fishing",
    "1. ON Fish Monitor\n"..
    "2. Mancing manual 1x\n"..
    "   (sampai dapat ikan)\n"..
    "3. OFF Fish Monitor\n"..
    "4. Pergi ke tab 📋 COPY\n"..
    "5. Copy hasilnya\n"..
    "6. Kirim ke developer!")

FR:Paragraph("Yang Dicari",
    "Urutan event:\n"..
    "← CastEvent: ?\n"..
    "← MiniGame: Start\n"..
    "← NotifyClient: ikan\n"..
    "← MiniGame: Stop\n\n"..
    "Catat jika berbeda!")

-- ╔══════════════════╗
-- ║   TAB INVENTORY  ║
-- ╚══════════════════╝
local IP = T_Inv:Page("Inventory Monitor","package")
local IL = IP:Section("📦 Monitor","Left")
local IR = IP:Section("📋 Info","Right")

IL:Toggle("▶ Inventory Monitor","invMon",false,
    "Listen data inventory dari server",
    function(v)
        if v then
            clearLog()
            local ok = startInvMonitor()
            if ok then
                notif("📦 Inv Monitor","ON!\nBeli 1 bibit apa saja\nlalu cek Copy tab",4)
            end
        else
            stopInvMonitor()
            notif("Inv Monitor","OFF",2)
        end
    end)

IL:Button("Force Request","Paksa server kirim inventory",
    function()
        local bn = RS:FindFirstChild("BridgeNet2")
        local ev = bn and bn:FindFirstChild("dataRemoteEvent")
        if not ev then notif("Err","dataRemoteEvent tidak ada!",3); return end

        addLog("Force request inventory...")
        flushToTextBox()

        -- Kirim dummy beli untuk trigger server update
        pcall(function()
            ev:FireServer({{ cropName="Sawi", amount=0 }, "\x07"})
        end)
        notif("Request","Dikirim! Tunggu 2-3 detik\nlalu cek Copy tab",4)
    end)

IR:Paragraph("Cara Debug Inventory",
    "1. ON Inventory Monitor\n"..
    "2. Beli 1 bibit (shop)\n"..
    "   ATAU klik Force Request\n"..
    "3. Tunggu 2-3 detik\n"..
    "4. OFF Monitor\n"..
    "5. Pergi tab 📋 COPY\n"..
    "6. Copy & kirim!")

-- ╔══════════════════════════════════╗
-- ║   TAB COPY — INI YANG PENTING!  ║
-- ╚══════════════════════════════════╝
local CP = T_Copy:Page("Copy Log","clipboard")
local CL = CP:Section("📋 Tap TextBox → Copy","Left")
local CR = CP:Section("🔧 Controls","Right")

-- TextBox utama yang bisa di-select dan di-copy
CL:TextBox("📋 LOG OUTPUT (Tap → Select All → Copy)","logOutput",
    "Jalankan scan dulu...",
    function(val)
        -- User bisa edit, tapi kita tidak perlu callback-nya
        -- TextBox ini untuk OUTPUT saja
    end,
    "Tap di sini untuk select & copy")

-- Simpan reference TextBox
-- Aurora biasanya return objek UI, kita pakai workaround
-- dengan update text via callback setelah UI dibuat
task.spawn(function()
    task.wait(0.5)
    -- Cari TextBox di UI
    local playerGui = LP:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("TextBox") and gui.Name == "logOutput" then
                LogTextBox = gui
                gui.Text = "Siap! Klik scan atau monitor dulu."
                break
            end
        end
    end
    -- Kalau tidak ketemu lewat PlayerGui, coba cara lain
    if not LogTextBox then
        -- Polling sampai ketemu
        for attempt = 1, 20 do
            task.wait(0.3)
            local pg = LP:FindFirstChild("PlayerGui")
            if pg then
                for _, obj in ipairs(pg:GetDescendants()) do
                    if obj:IsA("TextBox") and obj.PlaceholderText and
                       obj.PlaceholderText:find("copy") then
                        LogTextBox = obj
                        obj.Text = "Siap! Klik scan dulu."
                        break
                    end
                end
            end
            if LogTextBox then break end
        end
    end
end)

CR:Button("🔄 Refresh TextBox","Update TextBox dengan log terbaru",
    function()
        flushToTextBox()
        notif("TextBox","Updated! ("..LogCount.." entries)",2)
    end)

CR:Button("🗑 Clear Semua","Hapus log dan reset TextBox",
    function()
        clearLog()
        if LogTextBox then LogTextBox.Text = "Log cleared." end
        notif("Clear","Log dihapus",2)
    end)

CR:Button("📊 Statistik","Info log saat ini",
    function()
        local lineCount = 0
        for _ in LogBuffer:gmatch("\n") do lineCount = lineCount + 1 end
        notif("📊 Stats",
            "Entries: "..LogCount.."\n"..
            "Lines: "..lineCount.."\n"..
            "Size: "..#LogBuffer.." chars\n\n"..
            "Tap TextBox di kiri\nlalu Select All → Copy!",8)
    end)

CR:Paragraph("PENTING!",
    "TextBox di kiri = output log\n\n"..
    "Cara copy di mobile:\n"..
    "1. Tap TextBox\n"..
    "2. Tahan beberapa detik\n"..
    "3. Pilih 'Select All'\n"..
    "4. Pilih 'Copy'\n"..
    "5. Paste ke chat/WA/dll\n\n"..
    "Atau screenshot notif!")

-- ┌─────────────────────────────────────────────────────────┐
-- │  INIT                                                   │
-- └─────────────────────────────────────────────────────────┘
Library:Notification("XKID DEBUG v3",
    "Scan · Fish · Inventory · Copy\nSemua output bisa di-copy!",5)
Library:ConfigSystem(Win)

addLog("XKID Debug Tool v3 loaded")
addLog("Player: "..LP.Name)
addLog("Workspace children: "..#Workspace:GetChildren())
addLog("")
addLog("=== QUICK START ===")
addLog("Scan: Tab Scan → FULL SCAN")
addLog("Fish: Tab Fishing → ON Monitor → Mancing")
addLog("Inv : Tab Inventory → ON Monitor → Beli bibit")
addLog("Copy: Tab COPY → Tap TextBox → Select All → Copy")
addLog("")
task.spawn(function()
    task.wait(1)
    flushToTextBox()
end)
