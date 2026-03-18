--[[
  ╔══════════════════════════════════════════════════════╗
  ║      🔍  XKID SPY TOOL  v1.0                       ║
  ║      Aurora UI  ✦  Remote Logger                   ║
  ╚══════════════════════════════════════════════════════╝
]]

-- ════════════════════════════════════════
--  LOAD AURORA UI
-- ════════════════════════════════════════
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Win = Library:Window("XKID Spy", "search", "v1.0 Remote Logger", false)

-- ════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════
local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer

-- ════════════════════════════════════════
--  REMOTE TARGET
-- ════════════════════════════════════════
local TUT = RS:WaitForChild("Remotes"):WaitForChild("TutorialRemotes")

-- ════════════════════════════════════════
--  LOG STORAGE
-- ════════════════════════════════════════
local logs = {}
local maxLogs = 30

local function addLog(name, args)
    local argsStr = ""
    for i, v in ipairs(args) do
        local t = typeof(v)
        if t == "Vector3" then
            argsStr = argsStr .. string.format("Vector3(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
        elseif t == "CFrame" then
            local p = v.Position
            argsStr = argsStr .. string.format("CFrame(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
        elseif t == "table" then
            argsStr = argsStr .. "table{...}"
        else
            argsStr = argsStr .. tostring(v)
        end
        if i < #args then argsStr = argsStr .. ", " end
    end
    if argsStr == "" then argsStr = "(no args)" end

    local entry = string.format("[%s] %s | Args: %s", os.date("%H:%M:%S"), name, argsStr)
    table.insert(logs, 1, entry)
    if #logs > maxLogs then table.remove(logs) end

    print("[ SPY ] " .. entry)
    pcall(function() Library:Notification("SPY: "..name, argsStr, 4) end)
end

-- ════════════════════════════════════════
--  HOOK FUNCTION
-- ════════════════════════════════════════
local hooked = {}

local function hookRemote(name)
    if hooked[name] then return end
    local r = TUT:FindFirstChild(name)
    if not r then
        print("[ SPY ] Remote tidak ditemukan: " .. name)
        return
    end

    if r:IsA("RemoteEvent") then
        local orig = r.FireServer
        r.FireServer = function(self, ...)
            local args = {...}
            addLog(name, args)
            return orig(self, ...)
        end
        hooked[name] = true
        print("[ SPY ] Hooked RemoteEvent: " .. name)

    elseif r:IsA("RemoteFunction") then
        local orig = r.InvokeServer
        r.InvokeServer = function(self, ...)
            local args = {...}
            addLog(name, args)
            return orig(self, ...)
        end
        hooked[name] = true
        print("[ SPY ] Hooked RemoteFunction: " .. name)
    end
end

local function unhookRemote(name)
    -- unhook dengan refresh cache
    hooked[name] = false
    print("[ SPY ] Unhooked: " .. name)
end

-- ════════════════════════════════════════
--  COPY TO CLIPBOARD
-- ════════════════════════════════════════
local function copyLogs()
    if #logs == 0 then
        pcall(function() Library:Notification("SPY", "Belum ada log!", 3) end)
        return
    end
    local text = "=== XKID SPY LOG ===\n"
    for _, entry in ipairs(logs) do
        text = text .. entry .. "\n"
    end
    pcall(function() setclipboard(text) end)
    pcall(function() Library:Notification("Copy OK", #logs .. " log di-copy!", 3) end)
    print("[ SPY ] Logs copied to clipboard")
end

local function clearLogs()
    logs = {}
    pcall(function() Library:Notification("SPY", "Log dibersihkan", 2) end)
    print("[ SPY ] Logs cleared")
end

local function showLogs()
    if #logs == 0 then
        pcall(function() Library:Notification("SPY", "Belum ada log!", 3) end)
        return
    end
    local txt = ""
    for i = 1, math.min(5, #logs) do
        txt = txt .. logs[i] .. "\n"
    end
    pcall(function() Library:Notification("Log Terbaru ("..#logs.." total)", txt, 10) end)
end

-- ════════════════════════════════════════
--  MANUAL FIRE TEST
-- ════════════════════════════════════════
local function testFire(name, ...)
    local r = TUT:FindFirstChild(name)
    if not r then
        pcall(function() Library:Notification("ERROR", name .. " tidak ada", 3) end)
        return
    end
    local args = {...}
    pcall(function()
        if r:IsA("RemoteEvent") then
            r:FireServer(table.unpack(args))
        elseif r:IsA("RemoteFunction") then
            local res = r:InvokeServer(table.unpack(args))
            print("[ SPY ] InvokeServer result:", res)
        end
    end)
    pcall(function()
        Library:Notification("Fire: "..name,
            #args>0 and tostring(args[1]) or "(no args)", 3)
    end)
end

-- ════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════
Win:TabSection("SPY")
local TabHook  = Win:Tab("Hook",  "search")
local TabTest  = Win:Tab("Test",  "play")
local TabLog   = Win:Tab("Log",   "file-text")

-- ════════════════════════════════════════
--  TAB HOOK
-- ════════════════════════════════════════
local HookPage  = TabHook:Page("Remote Hook", "search")
local HookLeft  = HookPage:Section("Farming Remotes", "Left")
local HookRight = HookPage:Section("Shop Remotes", "Right")

-- PlantCrop
HookLeft:Toggle("Hook PlantCrop", "HookPlant", false,
    "Spy args saat PlantCrop dikirim",
    function(v)
        if v then hookRemote("PlantCrop")
        else unhookRemote("PlantCrop") end
        Library:Notification("Hook PlantCrop", v and "ON" or "OFF", 2)
    end)

-- HarvestCrop
HookLeft:Toggle("Hook HarvestCrop", "HookHarvest", false,
    "Spy args saat HarvestCrop dikirim",
    function(v)
        if v then hookRemote("HarvestCrop")
        else unhookRemote("HarvestCrop") end
        Library:Notification("Hook HarvestCrop", v and "ON" or "OFF", 2)
    end)

-- GetBibit
HookLeft:Toggle("Hook GetBibit", "HookBibit", false,
    "Spy args saat GetBibit dikirim",
    function(v)
        if v then hookRemote("GetBibit")
        else unhookRemote("GetBibit") end
        Library:Notification("Hook GetBibit", v and "ON" or "OFF", 2)
    end)

-- SellCrop
HookLeft:Toggle("Hook SellCrop", "HookSell", false,
    "Spy args saat SellCrop dikirim",
    function(v)
        if v then hookRemote("SellCrop")
        else unhookRemote("SellCrop") end
        Library:Notification("Hook SellCrop", v and "ON" or "OFF", 2)
    end)

-- PlantLahanCrop
HookLeft:Toggle("Hook PlantLahanCrop", "HookLahan", false,
    "Spy args saat PlantLahanCrop dikirim",
    function(v)
        if v then hookRemote("PlantLahanCrop")
        else unhookRemote("PlantLahanCrop") end
        Library:Notification("Hook PlantLahanCrop", v and "ON" or "OFF", 2)
    end)

HookLeft:Button("Hook SEMUA Sekarang", "Aktifkan semua hook sekaligus",
    function()
        local remotes = {
            "PlantCrop", "HarvestCrop", "GetBibit",
            "SellCrop", "PlantLahanCrop"
        }
        for _, name in ipairs(remotes) do hookRemote(name) end
        Library:Notification("Hook Semua", "Semua remote di-hook!", 3)
    end)

-- RequestShop
HookRight:Toggle("Hook RequestShop", "HookShop", false,
    "Spy args saat RequestShop dipanggil",
    function(v)
        if v then hookRemote("RequestShop")
        else unhookRemote("RequestShop") end
        Library:Notification("Hook RequestShop", v and "ON" or "OFF", 2)
    end)

-- RequestSell
HookRight:Toggle("Hook RequestSell", "HookReqSell", false,
    "Spy args saat RequestSell dipanggil",
    function(v)
        if v then hookRemote("RequestSell")
        else unhookRemote("RequestSell") end
        Library:Notification("Hook RequestSell", v and "ON" or "OFF", 2)
    end)

-- RequestLahan
HookRight:Toggle("Hook RequestLahan", "HookReqLahan", false,
    "Spy args saat RequestLahan dipanggil",
    function(v)
        if v then hookRemote("RequestLahan")
        else unhookRemote("RequestLahan") end
        Library:Notification("Hook RequestLahan", v and "ON" or "OFF", 2)
    end)

HookRight:Paragraph("Cara Pakai",
    "1. ON kan hook remote\n"..
    "2. Lakukan aksi di game\n"..
    "   (tanam, panen, beli)\n"..
    "3. Lihat log di tab Log\n"..
    "4. Copy log ke clipboard\n"..
    "5. Paste dan kirim ke saya!")

-- ════════════════════════════════════════
--  TAB TEST
-- ════════════════════════════════════════
local TestPage  = TabTest:Page("Manual Fire Test", "play")
local TestLeft  = TestPage:Section("Test Fire", "Left")
local TestRight = TestPage:Section("Test Invoke", "Right")

TestLeft:Button("Test PlantCrop (no args)", "FireServer tanpa args",
    function() testFire("PlantCrop") end)

TestLeft:Button("Test PlantCrop (arg=1)", "FireServer(1)",
    function() testFire("PlantCrop", 1) end)

TestLeft:Button("Test PlantCrop (Vector3)", "FireServer(Vector3 posisi kamu)",
    function()
        local root = game:GetService("Players").LocalPlayer.Character
            and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then
            Library:Notification("ERROR", "Karakter tidak ada", 3); return
        end
        testFire("PlantCrop", root.Position)
    end)

TestLeft:Button("Test HarvestCrop (no args)", "FireServer tanpa args",
    function() testFire("HarvestCrop") end)

TestLeft:Button("Test HarvestCrop (arg=1)", "FireServer(1)",
    function() testFire("HarvestCrop", 1) end)

TestLeft:Button("Test GetBibit (no args)", "FireServer tanpa args",
    function() testFire("GetBibit") end)

TestLeft:Button("Test GetBibit (0, false)", "FireServer(0, false) dari spy log lama",
    function() testFire("GetBibit", 0, false) end)

TestLeft:Button("Test SellCrop (no args)", "FireServer tanpa args",
    function() testFire("SellCrop") end)

TestRight:Button("Test RequestShop GET_LIST", "InvokeServer('GET_LIST')",
    function() testFire("RequestShop", "GET_LIST") end)

TestRight:Button("Test RequestSell GET_LIST", "InvokeServer('GET_LIST')",
    function() testFire("RequestSell", "GET_LIST") end)

TestRight:Button("Test RequestLahan", "InvokeServer()",
    function() testFire("RequestLahan") end)

TestRight:Paragraph("Lihat hasil di",
    "Console F9\ndan tab Log\n\nCoba satu-satu\nlalu lihat mana\nyang berhasil!")

-- ════════════════════════════════════════
--  TAB LOG
-- ════════════════════════════════════════
local LogPage  = TabLog:Page("Log Viewer", "file-text")
local LogLeft  = LogPage:Section("Actions", "Left")
local LogRight = LogPage:Section("Info", "Right")

LogLeft:Button("Lihat 5 Log Terbaru", "Tampilkan log di notif",
    function() showLogs() end)

LogLeft:Button("Copy Semua Log", "Salin ke clipboard lalu kirim ke saya",
    function() copyLogs() end)

LogLeft:Button("Bersihkan Log", "Hapus semua log",
    function() clearLogs() end)

LogLeft:Button("Print Semua ke Console", "Tampilkan di F9",
    function()
        if #logs == 0 then
            Library:Notification("SPY", "Belum ada log!", 3); return
        end
        print("=== XKID SPY LOG ("..#logs.." entries) ===")
        for _, entry in ipairs(logs) do print(entry) end
        print("=== END LOG ===")
        Library:Notification("Console", #logs.." log dicetak ke F9", 3)
    end)

LogRight:Paragraph("Format Log",
    "[HH:MM:SS] Remote | Args: ...\n\nContoh:\n[01:12:37] PlantCrop | Args: (no args)\n[01:12:38] HarvestCrop | Args: 1\n[01:12:40] GetBibit | Args: 0, false\n\nMax 30 log tersimpan")

LogRight:Paragraph("Tips",
    "Setelah copy log,\npaste dan kirim ke saya\nagar saya bisa fix\nscript Indo Farmer!")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("XKID Spy v1.0",
    "Hook remote lalu lakukan aksi di game!", 5)

print("[ XKID SPY ] v1.0 loaded — " .. LP.Name)
print("[ XKID SPY ] Siap hook: PlantCrop, HarvestCrop, GetBibit, SellCrop")
