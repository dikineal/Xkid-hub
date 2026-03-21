-- XKID HARVEST DEBUG
-- Jalankan ini, tunggu tanaman siap, klik panen manual
-- Copy log → kirim ke developer

local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer

local log = {}
local function L(msg)
    table.insert(log, os.date("[%H:%M:%S] ")..msg)
    print("[HARVEST_DBG] "..msg)
end

L("=== HARVEST DEBUG START ===")

-- ── 1. Intercept OnClientEvent ─────────────────────────────
local bn = RS:FindFirstChild("BridgeNet2")
local ev = bn and bn:FindFirstChild("dataRemoteEvent")

if not ev then L("❌ dataRemoteEvent tidak ada!"); return end

L("✅ Remote ditemukan: "..ev:GetFullName())

-- Log SEMUA data yang masuk
ev.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then
        L("OnClientEvent: bukan table, type="..type(data))
        return
    end

    -- Log semua keys dengan hex
    local keys = {}
    for k, v in pairs(data) do
        local kt = type(k)
        local kstr = ""
        if kt == "string" then
            local hex = ""
            for i = 1, #k do hex = hex..string.format("%02x",k:byte(i)) end
            kstr = "str["..hex.."]"
        elseif kt == "number" then
            kstr = "int["..k.."]"
        end
        -- Value type
        local vt = type(v)
        table.insert(keys, kstr.."="..vt)
    end
    L("OnClientEvent keys: "..table.concat(keys, " | "))

    -- Cek SEMUA kemungkinan crop ready key
    local cropData = nil
    local foundKey = nil

    -- Test setiap kemungkinan
    local candidates = {
        {key="\r",    label="\\r"},
        {key="\13",   label="\\13"},
        {key=string.char(13), label="char(13)"},
        {key=13,      label="int(13)"},
    }
    for _, c in ipairs(candidates) do
        if data[c.key] then
            cropData = data[c.key]
            foundKey = c.label
            break
        end
    end

    if cropData then
        L("✅ CROP DATA FOUND via key: "..foundKey)
        if type(cropData) == "table" then
            for i, crop in ipairs(cropData) do
                if type(crop) == "table" then
                    L(string.format("  crop[%d]: name=%s pos=%s sell=%s",
                        i,
                        tostring(crop.cropName),
                        crop.cropPos and string.format("(%.1f,%.1f,%.1f)",
                            crop.cropPos.X, crop.cropPos.Y, crop.cropPos.Z) or "nil",
                        tostring(crop.sellPrice)
                    ))
                end
            end
        end

        -- Cek timer
        local timerRaw = data["\2"] or data["\x02"] or data[string.char(2)] or data[2]
        if timerRaw then
            L(string.format("  timer: start=%s end=%s",
                tostring(timerRaw[1]), tostring(timerRaw[2])))
        else
            L("  timer: NOT FOUND")
        end
    end

    -- Cek inventory key \x03
    if data["\3"] then
        local list = data["\3"][1]
        if type(list) == "table" then
            L("INV UPDATE:")
            for slot, e in ipairs(list) do
                if type(e)=="table" and e.cropName then
                    L(string.format("  slot[%d]=%s x%d", slot, e.cropName, e.count or 0))
                end
            end
        end
    end
end)

L("Listener aktif — tunggu tanaman tumbuh...")
L("Klik panen manual 1x di game")

-- ── 2. Test FireServer harvest manual ──────────────────────
-- Tunggu 5 detik lalu test kirim harvest
task.delay(5, function()
    L("")
    L("=== TEST HARVEST FIRESERVER ===")
    L("Kirim test harvest ke server...")

    -- Pakai data dari spy log yang confirmed
    local now = math.floor(tick() * 1000)
    local ok, err = pcall(function()
        ev:FireServer({
            ["\13"] = {{
                seedColor = {0.298, 0.600, 0},
                cropName  = "Sawi",
                cropPos   = Vector3.new(93.1, 69.73, -2.8),
                sellPrice = 20,
                drops     = {{
                    name="Biji Sawi Emas",
                    coinReward=50,
                    icon="\226\156\168",
                    rarity="Rare"
                }},
            }},
            ["\2"] = { now, now + 50 }
        })
    end)

    if ok then
        L("✅ FireServer test: SENT (server mungkin accept atau reject)")
        L("Cek apakah inventory berubah / tanaman hilang")
    else
        L("❌ FireServer test ERROR: "..tostring(err))
    end
end)

-- ── 3. Copy log button ─────────────────────────────────────
-- Auto copy setelah 30 detik
task.delay(30, function()
    L("")
    L("=== AUTO COPY LOG ===")
    local fullLog = table.concat(log, "\n")
    local ok = pcall(function() setclipboard(fullLog) end)
    if ok then
        print("[HARVEST_DBG] ✅ Log di-copy ke clipboard!")
    else
        print("[HARVEST_DBG] ❌ setclipboard gagal")
        print(fullLog)
    end
end)

L("Script jalan — tunggu 30 detik untuk auto-copy log")
L("Atau manual copy dari executor output")
