--[[
  ╔══════════════════════════════════════════════════════╗
  ║      🔍  XKID REMOTE SCANNER  v1.0                  ║
  ║      Aurora UI  ✦  Spy BridgeNet2 + FishRemotes     ║
  ╚══════════════════════════════════════════════════════╝
  Cara pakai:
  1. Jalankan script ini
  2. Aktifkan hook yang diinginkan
  3. Lakukan aksi di game (tanam, panen, mancing)
  4. Lihat log → Copy → Paste ke chat
]]

-- ════════════════════════════════════════
--  AURORA UI
-- ════════════════════════════════════════
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════
local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local LP        = Players.LocalPlayer

-- ════════════════════════════════════════
--  LOG SYSTEM
-- ════════════════════════════════════════
local LOGS     = {}
local LOG_MAX  = 50

local function addLog(remote, args)
    local t = os.date("%H:%M:%S")

    -- Serialize args to string
    local function serialize(v, depth)
        depth = depth or 0
        if depth > 4 then return "..." end
        local tp = typeof(v)
        if tp == "string" then
            -- show escape sequences for special chars
            local escaped = v:gsub(".", function(c)
                local b = c:byte()
                if b < 32 then return "\\"..b end
                return c
            end)
            return '"'..escaped..'"'
        elseif tp == "number"  then return tostring(v)
        elseif tp == "boolean" then return tostring(v)
        elseif tp == "Vector3" then
            return string.format("V3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
        elseif tp == "CFrame"  then
            local p = v.Position
            return string.format("CF(%.2f,%.2f,%.2f)", p.X, p.Y, p.Z)
        elseif tp == "Instance" then
            return "["..v.ClassName.."] "..v:GetFullName()
        elseif tp == "table" then
            local parts = {}
            local isArr = #v > 0
            for k, val in pairs(v) do
                local key = isArr and "" or ("["..serialize(k, depth+1).."]= ")
                table.insert(parts, key..serialize(val, depth+1))
            end
            return "{"..table.concat(parts, ", ").."}"
        else
            return "("..tp..")"..tostring(v)
        end
    end

    local argStr = serialize(args)
    local entry  = string.format("[%s] %s\n%s", t, remote, argStr)

    table.insert(LOGS, 1, entry)
    if #LOGS > LOG_MAX then table.remove(LOGS) end
    print("[XKID SPY] "..entry)
end

-- ════════════════════════════════════════
--  HOOK SYSTEM
-- ════════════════════════════════════════
local hooked = {}

local function hookFireServer(remote, label)
    if hooked[label] then return end
    if not remote then
        print("[XKID SPY] Remote tidak ditemukan: "..label)
        return
    end

    local oldFire = remote.FireServer
    remote.FireServer = function(self, ...)
        local args = {...}
        addLog(label, args)
        return oldFire(self, ...)
    end

    hooked[label] = true
    print("[XKID SPY] Hooked: "..label)
end

local function hookOnClientEvent(remote, label)
    if hooked[label.."_client"] then return end
    if not remote then return end

    remote.OnClientEvent:Connect(function(...)
        local args = {...}
        addLog(label.." [OnClientEvent]", args)
    end)

    hooked[label.."_client"] = true
    print("[XKID SPY] Hooked OnClientEvent: "..label)
end

local function unhook(label)
    hooked[label] = false
    print("[XKID SPY] Unhooked: "..label)
end

-- ════════════════════════════════════════
--  REMOTE GETTERS
-- ════════════════════════════════════════
local function getBridge()
    local bn = RS:FindFirstChild("BridgeNet2")
    return bn and bn:FindFirstChild("dataRemoteEvent")
end

local function getFish(name)
    local fr = RS:FindFirstChild("FishRemotes")
    return fr and fr:FindFirstChild(name)
end

-- ════════════════════════════════════════
--  COPY TO CLIPBOARD
-- ════════════════════════════════════════
local function copyLogs(n)
    if #LOGS == 0 then
        pcall(function() Library:Notification("Log","Belum ada log!",3) end)
        return
    end
    local limit = math.min(n or #LOGS, #LOGS)
    local text  = "=== XKID SPY LOG ("..limit.."/"..#LOGS..") ===\n\n"
    for i = 1, limit do
        text = text..LOGS[i].."\n\n"
    end
    pcall(function() setclipboard(text) end)
    pcall(function() Library:Notification("✅ Copy OK", limit.." log di-copy!", 3) end)
    print("[XKID SPY] Copied "..limit.." logs")
end

-- ════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════
local Win  = Library:Window("XKID Scanner","search","v1.0",false)
Win:TabSection("SPY")
local TH   = Win:Tab("Hook",  "search")
local TL   = Win:Tab("Log",   "file-text")

-- ════════════════════════════════════════
--  TAB HOOK
-- ════════════════════════════════════════
local HP   = TH:Page("Remote Hook","search")
local HL   = HP:Section("BridgeNet2","Left")
local HR   = HP:Section("FishRemotes","Right")

-- Hook semua sekaligus
HL:Button("🔗 Hook SEMUA","Aktifkan semua hook sekaligus",
    function()
        hookFireServer(getBridge(),        "BridgeNet2.dataRemote")
        hookOnClientEvent(getBridge(),     "BridgeNet2.dataRemote")
        hookFireServer(getFish("CastEvent"),  "Fish.CastEvent")
        hookFireServer(getFish("MiniGame"),   "Fish.MiniGame")
        hookOnClientEvent(getFish("MiniGame"),"Fish.MiniGame")
        hookOnClientEvent(getFish("NotifyClient"),"Fish.NotifyClient")
        Library:Notification("Hook","Semua remote di-hook!",3)
    end)

-- BridgeNet2
HL:Toggle("Hook dataRemoteEvent FireServer","hookBridge",false,
    "Spy semua FireServer ke BridgeNet2",
    function(v)
        if v then hookFireServer(getBridge(), "BridgeNet2.dataRemote")
        else unhook("BridgeNet2.dataRemote") end
        Library:Notification("BridgeNet2", v and "Hooked!" or "Unhooked",2)
    end)

HL:Toggle("Hook dataRemote OnClientEvent","hookBridgeClient",false,
    "Spy event yang diterima dari server",
    function(v)
        if v then hookOnClientEvent(getBridge(), "BridgeNet2.dataRemote") end
        Library:Notification("BridgeNet2 Client", v and "Hooked!" or "N/A",2)
    end)

-- FishRemotes
HR:Toggle("Hook CastEvent","hookCast",false,
    "Spy saat lempar/tarik kail",
    function(v)
        if v then hookFireServer(getFish("CastEvent"), "Fish.CastEvent")
        else unhook("Fish.CastEvent") end
        Library:Notification("CastEvent", v and "Hooked!" or "Unhooked",2)
    end)

HR:Toggle("Hook MiniGame FireServer","hookMiniFS",false,
    "Spy MiniGame FireServer",
    function(v)
        if v then hookFireServer(getFish("MiniGame"), "Fish.MiniGame")
        else unhook("Fish.MiniGame") end
        Library:Notification("MiniGame FS", v and "Hooked!" or "Unhooked",2)
    end)

HR:Toggle("Hook MiniGame OnClientEvent","hookMiniCE",false,
    "Spy MiniGame dari server",
    function(v)
        if v then hookOnClientEvent(getFish("MiniGame"), "Fish.MiniGame") end
        Library:Notification("MiniGame CE", v and "Hooked!" or "N/A",2)
    end)

HR:Toggle("Hook NotifyClient","hookNotify",false,
    "Spy notif dapat ikan",
    function(v)
        if v then hookOnClientEvent(getFish("NotifyClient"), "Fish.NotifyClient") end
        Library:Notification("NotifyClient", v and "Hooked!" or "N/A",2)
    end)

HR:Paragraph("Cara Pakai",
    "1. Klik Hook SEMUA\n"..
    "2. Lakukan aksi:\n"..
    "   - Tanam manual\n"..
    "   - Panen manual\n"..
    "   - Mancing\n"..
    "3. Buka tab Log\n"..
    "4. Copy → Paste ke chat!")

-- ════════════════════════════════════════
--  TAB LOG
-- ════════════════════════════════════════
local LP2  = TL:Page("Log Viewer","file-text")
local LL   = LP2:Section("Actions","Left")
local LR   = LP2:Section("Info","Right")

LL:Button("📋 Copy 5 Log Terbaru","Copy 5 log terakhir ke clipboard",
    function() copyLogs(5) end)

LL:Button("📋 Copy 10 Log","Copy 10 log ke clipboard",
    function() copyLogs(10) end)

LL:Button("📋 Copy SEMUA Log","Copy semua log ke clipboard",
    function() copyLogs() end)

LL:Button("👁 Lihat 3 Terbaru","Tampilkan 3 log di notif",
    function()
        if #LOGS == 0 then
            Library:Notification("Log","Belum ada log!",3); return
        end
        local txt = ""
        for i = 1, math.min(3, #LOGS) do
            txt = txt..LOGS[i].."\n---\n"
        end
        Library:Notification("Log ("..#LOGS.." total)", txt, 12)
    end)

LL:Button("🗑 Bersihkan Log","Hapus semua log",
    function()
        LOGS = {}
        Library:Notification("Log","Dibersihkan!",2)
    end)

LR:Paragraph("Total Log", "0 / "..LOG_MAX.." max")

LR:Paragraph("Format Output",
    "[HH:MM:SS] RemoteName\n"..
    "{args...}\n\n"..
    "V3 = Vector3\n"..
    "CF = CFrame\n"..
    "\\13 = char(13)\n"..
    "\\4 = char(4)\n\n"..
    "Copy lalu paste\nke chat semuanya!")

LR:Paragraph("Tips Tanam",
    "Untuk dapat posisi plot:\n"..
    "1. Hook SEMUA\n"..
    "2. Tanam manual 1 per 1\n"..
    "   di semua 20 slot\n"..
    "3. Copy semua log\n"..
    "4. Paste ke chat\n\n"..
    "Cari data dengan key\n"..
    "\"\\4\" = tanam\n"..
    "\"\\13\" = panen")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("XKID Scanner","Hook remote lalu lakukan aksi!",5)
Library:ConfigSystem(Win)
print("[XKID SCANNER] v1.0 loaded — "..LP.Name)
