--[[
  ╔══════════════════════════════════════════════════════╗
  ║    🔌  BN2 FIRESERVER HOOK  v1.0  🔌               ║
  ║    Tangkap semua packet OUTGOING BridgeNet2         ║
  ╚══════════════════════════════════════════════════════╝
  Cara pakai:
  1. Jalankan script ini
  2. Toggle Hook ON
  3. Lakukan aksi di game:
     - Klik lahan untuk TANAM
     - Beli bibit
     - Panen
  4. Lihat hasil & copy
]]

Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local RS = game:GetService("ReplicatedStorage")
local LP = game:GetService("Players").LocalPlayer

local Win = Library:Window("🔌 BN2 HOOK", "cpu", "v1.0 FireServer", false)
Win:TabSection("HOOK")
local TabHook = Win:Tab("Hook", "eye")

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local hookOn       = false
local origNamecall = nil
local captured     = {}   -- semua packet outgoing
local MAX_CAP      = 100
local currentPage  = 1
local PAGE_SIZE    = 3

-- ════════════════════════════════════════
--  SERIALIZE
-- ════════════════════════════════════════
local function serializeValue(v, depth)
    depth = depth or 0
    if depth > 5 then return "..." end
    local t = typeof(v)
    if t == "string" then
        if #v <= 4 then
            local hex = ""
            for i = 1, #v do
                hex = hex .. string.format("\\x%02X", string.byte(v, i))
            end
            return string.format('STR[hex:%s]', hex)
        end
        return string.format('"%s"', v)
    elseif t == "number"  then return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "Vector3" then
        return string.format("V3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
    elseif t == "CFrame"  then
        local p = v.Position
        return string.format("CF(%.2f,%.2f,%.2f)", p.X, p.Y, p.Z)
    elseif t == "table"   then
        local parts = {}
        local count = 0
        for k, val in pairs(v) do
            count = count + 1
            if count > 8 then
                table.insert(parts, "...more")
                break
            end
            local ks = serializeValue(k, depth+1)
            local vs = serializeValue(val, depth+1)
            table.insert(parts, string.format("[%s]=%s", ks, vs))
        end
        if #parts == 0 then return "{EMPTY}" end
        return "{\n"..string.rep("  ", depth+1)..
               table.concat(parts, ",\n"..string.rep("  ", depth+1))..
               "\n"..string.rep("  ", depth).."}"
    elseif t == "Instance" then
        return "Inst:"..v:GetFullName()
    else
        return "["..t..":"..tostring(v).."]"
    end
end

-- ════════════════════════════════════════
--  DETEKSI AKSI dari packet outgoing
-- ════════════════════════════════════════
local function detectOutgoingAction(args)
    -- args = semua argumen yang dikirim ke FireServer
    local str = ""
    for _, a in ipairs(args) do
        str = str .. serializeValue(a, 0)
    end

    if str:find("cropName") and str:find("count") then
        return "🛒 BELI BIBIT (outgoing)"
    elseif str:find("cropName") and str:find("cropPos") then
        return "🌱 TANAM (outgoing)"
    elseif str:find("cropName") and not str:find("count") then
        return "🌾 HARVEST (outgoing)"
    elseif str:find("EMPTY") or str == "" then
        return "📦 REQUEST KOSONG"
    else
        return "❓ UNKNOWN OUTGOING"
    end
end

-- ════════════════════════════════════════
--  HOOK __namecall
-- ════════════════════════════════════════

-- Remote yang di-hook
local function getTargetRemotes()
    local bn2 = RS:FindFirstChild("BridgeNet2")
    local net  = RS:FindFirstChild("Networking")
    local targets = {}

    if bn2 then
        local dataRE = bn2:FindFirstChild("dataRemoteEvent")
        local metaRE = bn2:FindFirstChild("metaRemoteEvent")
        if dataRE then table.insert(targets, dataRE) end
        if metaRE then table.insert(targets, metaRE) end
    end
    if net then
        local re = net:FindFirstChild("RemoteEvent")
        if re then table.insert(targets, re) end
    end

    -- Tambah semua RemoteEvent di RS root
    for _, child in ipairs(RS:GetChildren()) do
        if child:IsA("RemoteEvent") then
            table.insert(targets, child)
        end
    end

    return targets
end

local function startHook()
    local targets = getTargetRemotes()
    local targetSet = {}
    for _, r in ipairs(targets) do
        targetSet[r] = true
    end

    origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}

        -- Hanya tangkap FireServer / InvokeServer
        if (method == "FireServer" or method == "InvokeServer") then
            -- Cek apakah self adalah remote yang kita target
            local isTarget = targetSet[self]

            -- Atau cek nama path mengandung BridgeNet / Networking
            if not isTarget then
                local path = (pcall(function() return self:GetFullName() end))
                    and self:GetFullName() or ""
                isTarget = path:find("BridgeNet") or path:find("Networking")
                        or path:find("Packet")
            end

            if isTarget then
                -- Serialize semua argumen
                local argStrs = {}
                for i, a in ipairs(args) do
                    table.insert(argStrs, string.format(
                        "  [arg%d] %s", i, serializeValue(a, 0)))
                end

                local action = detectOutgoingAction(args)
                local remotePath = pcall(function() return self:GetFullName() end)
                    and self:GetFullName() or tostring(self)

                local entry = {
                    action = action,
                    method = method,
                    remote = remotePath,
                    raw    = table.concat(argStrs, "\n"),
                    args   = args,
                    time   = os.clock(),
                }

                table.insert(captured, 1, entry)
                if #captured > MAX_CAP then
                    table.remove(captured, #captured)
                end
            end
        end

        return origNamecall(self, ...)
    end)

    Library:Notification("🔌 Hook ON",
        string.format("Monitoring %d remote\n\nLakukan aksi:\n🌱 Klik lahan tanam\n🛒 Beli bibit\n🌾 Panen", #targets), 6)
end

local function stopHook()
    if origNamecall then
        hookmetamethod(game, "__namecall", origNamecall)
        origNamecall = nil
    end
    Library:Notification("🔌 Hook", "OFF", 2)
end

-- ════════════════════════════════════════
--  DISPLAY
-- ════════════════════════════════════════
local function showPackets(list, page, title)
    if #list == 0 then
        Library:Notification("📭", "Belum ada packet", 3)
        return page
    end
    local totalPages = math.ceil(#list / PAGE_SIZE)
    page = math.max(1, math.min(page, totalPages))

    local startIdx = (page-1)*PAGE_SIZE + 1
    local endIdx   = math.min(page*PAGE_SIZE, #list)

    local text = string.format("📦 %d-%d / %d\n\n", startIdx, endIdx, #list)

    for i = startIdx, endIdx do
        local p = list[i]
        text = text..string.format(
            "━[%d] %s━\n"..
            "Remote: %s\n"..
            "Method: %s\n"..
            "%s\n\n",
            i, p.action,
            p.remote:match("[^.]+$") or p.remote,  -- nama terakhir saja
            p.method,
            p.raw ~= "" and p.raw or "(no args)")
    end

    if totalPages > 1 then
        text = text..string.format("Hal %d/%d", page, totalPages)
    end

    Library:Notification(
        string.format("%s [%d-%d]", title, startIdx, endIdx),
        text, 20)
    return page
end

-- ════════════════════════════════════════
--  COPY
-- ════════════════════════════════════════
local function doCopy(text)
    local ok = pcall(function() setclipboard(text) end)
    Library:Notification(
        ok and "📋 Copied!" or "❌ Gagal",
        ok and "Berhasil copy!" or "Executor tidak support setclipboard", 3)
end

local function copyFiltered(list, keyword)
    local filtered = {}
    for _, p in ipairs(list) do
        if p.action:lower():find(keyword:lower()) then
            table.insert(filtered, p)
        end
    end
    if #filtered == 0 then
        Library:Notification("❌", "Tidak ada packet '"..keyword.."'", 2)
        return
    end
    local text = string.format("=== %s (%d) ===\n\n", keyword:upper(), #filtered)
    for i, p in ipairs(filtered) do
        text = text..string.format(
            "[%d] %s\nRemote: %s\nMethod: %s\n%s\n\n",
            i, p.action, p.remote, p.method, p.raw)
    end
    doCopy(text)
end

-- ════════════════════════════════════════
--  BUILD UI
-- ════════════════════════════════════════
local HookPage  = TabHook:Page("FireServer Hook", "eye")
local HookLeft  = HookPage:Section("🔌 Hook Control", "Left")
local HookRight = HookPage:Section("📋 Hasil", "Right")

HookLeft:Toggle("🔌 Hook FireServer", "HookToggle", false,
    "Intercept semua FireServer outgoing",
    function(v)
        hookOn = v
        if v then
            local ok, err = pcall(startHook)
            if not ok then
                Library:Notification("❌ Hook Error",
                    "hookmetamethod tidak support!\n"..tostring(err), 5)
                hookOn = false
            end
        else
            stopHook()
        end
    end)

HookLeft:Button("🗑 Clear Packets", "Hapus semua packet",
    function()
        captured = {}
        Library:Notification("🗑", "Cleared", 2)
    end)

HookLeft:Paragraph("Panduan",
    "1. Toggle Hook → ON\n\n"..
    "2. Lakukan di game:\n"..
    "   🌱 Klik lahan TANAM\n"..
    "   🛒 Beli bibit\n"..
    "   🌾 Panen\n\n"..
    "3. Tekan filter di\n"..
    "   kanan untuk lihat\n"..
    "   packet per aksi\n\n"..
    "4. Copy untuk analisa")

-- Navigasi
HookRight:Button("📄 Lihat Semua", "Tampilkan semua packet",
    function()
        currentPage = showPackets(captured, 1, "🔌 Hook")
    end)

HookRight:Button("▶ Berikutnya", "Halaman berikutnya",
    function()
        currentPage = showPackets(captured, currentPage+1, "🔌 Hook")
    end)

HookRight:Button("◀ Sebelumnya", "Halaman sebelumnya",
    function()
        currentPage = showPackets(captured, currentPage-1, "🔌 Hook")
    end)

-- Filter per aksi
HookRight:Button("🌱 Lihat TANAM", "Filter packet tanam saja",
    function()
        local filtered = {}
        for _, p in ipairs(captured) do
            if p.action:find("TANAM") or p.action:find("KOSONG") then
                table.insert(filtered, p)
            end
        end
        showPackets(filtered, 1, "🌱 Tanam")
    end)

HookRight:Button("🛒 Lihat BELI", "Filter packet beli bibit",
    function()
        local filtered = {}
        for _, p in ipairs(captured) do
            if p.action:find("BELI") then
                table.insert(filtered, p)
            end
        end
        showPackets(filtered, 1, "🛒 Beli")
    end)

HookRight:Button("🌾 Lihat HARVEST", "Filter packet panen",
    function()
        local filtered = {}
        for _, p in ipairs(captured) do
            if p.action:find("HARVEST") then
                table.insert(filtered, p)
            end
        end
        showPackets(filtered, 1, "🌾 Harvest")
    end)

-- Copy
HookRight:Button("📋 Copy SEMUA", "Copy semua packet",
    function()
        if #captured == 0 then
            Library:Notification("❌", "Belum ada packet", 2); return
        end
        local text = string.format("=== BN2 HOOK LOG (%d) ===\n\n", #captured)
        for i, p in ipairs(captured) do
            text = text..string.format(
                "[%d] %s\nRemote: %s\nMethod: %s\n%s\n\n",
                i, p.action, p.remote, p.method, p.raw)
        end
        doCopy(text)
    end)

HookRight:Button("📋 Copy TANAM", "Copy packet tanam saja",
    function() copyFiltered(captured, "tanam") end)

HookRight:Button("📋 Copy BELI", "Copy packet beli saja",
    function() copyFiltered(captured, "beli") end)

local copyIdx = 1
HookRight:Slider("Nomor Packet", "CopySlider", 1, 100, 1,
    function(v) copyIdx = v end, "Pilih nomor packet")

HookRight:Button("📋 Copy Packet #", "Copy 1 packet sesuai nomor",
    function()
        if copyIdx > #captured then
            Library:Notification("❌", "Max: "..#captured, 2); return
        end
        local p = captured[copyIdx]
        local text = string.format(
            "[%d] %s\nRemote: %s\nMethod: %s\n%s",
            copyIdx, p.action, p.remote, p.method, p.raw)
        doCopy(text)
    end)

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("🔌 BN2 Hook v1.0",
    "Toggle Hook ON\nlalu lakukan aksi tanam!", 5)
Library:ConfigSystem(Win)

print("[ BN2 HOOK v1.0 ] Ready — " .. LP.Name)
