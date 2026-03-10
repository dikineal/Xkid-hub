-- ╔══════════════════════════════════════════╗
-- ║  🌾 SAWAH INDO v8.1 ULTIMATE — XKID HUB  ║
-- ║  Fix: Auto Beli + Lahan Per-Jenis         ║
-- ║  Support: Android + Delta/Arceus/Fluxus   ║
-- ╚══════════════════════════════════════════╝

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO v8.1 ULTIMATE 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "Ultimate Auto Farm 🔥",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

-- ============================================
-- SERVICES
-- ============================================
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")

local myName = LocalPlayer.Name

-- ============================================
-- GLOBAL FLAGS
-- ============================================
_G.ScriptRunning   = true
_G.AutoFarm        = false
_G.AutoBeli        = false
_G.AutoTanam       = false
_G.AutoJual        = false
_G.AutoPanen       = false
_G.ESP             = false
_G.TeleportPanen   = false
_G.DetectorSawit   = false

-- ============================================
-- DATA & CONFIG
-- ============================================

-- ┌─────────────────────────────────────────┐
-- │  SISTEM LAHAN PER-JENIS                  │
-- │  Setiap jenis punya posisi & cache sendiri│
-- └─────────────────────────────────────────┘
local LahanData = {
    Sawah = {
        label    = "🌾 Sawah",
        pos      = nil,
        radius   = 50,
        cache    = {},
        cacheTime = 0,
        keywords = {"sawah", "tanah", "lahan", "plot", "farm", "padi"},
    },
    Sawit = {
        label    = "🌴 Sawit",
        pos      = nil,
        radius   = 50,
        cache    = {},
        cacheTime = 0,
        keywords = {"sawit", "kelapa", "plot_sawit", "lahan_sawit"},
    },
    Ternak = {
        label    = "🐄 Ternak",
        pos      = nil,
        radius   = 50,
        cache    = {},
        cacheTime = 0,
        keywords = {"ternak", "kandang", "peternakan", "hewan"},
    },
}

-- Jenis lahan aktif untuk Auto Farm
local ActiveFarmJenis = "Sawah"

-- Copy Positions — 3 titik teleport
local CopyPositions = {
    Sawah  = nil,
    Sawit  = nil,
    Ternak = nil,
}

-- Tanam manual positions
local TanamPositions = {
    Sawit  = nil,
    Durian = nil,
}

-- Bibit data
local BIBIT = {
    {name = "Padi",       emoji = "🌾", minLv = 1,   harga = 5},
    {name = "Jagung",     emoji = "🌽", minLv = 20,  harga = 15},
    {name = "Tomat",      emoji = "🍅", minLv = 40,  harga = 25},
    {name = "Terong",     emoji = "🍆", minLv = 60,  harga = 40},
    {name = "Strawberry", emoji = "🍓", minLv = 80,  harga = 60},
    {name = "Sawit",      emoji = "🌴", minLv = 80,  harga = 1000},
    {name = "Durian",     emoji = "🥥", minLv = 120, harga = 2000},
}

-- Settings
local selectedBibit = "Padi"
local jumlahBeli    = 1
local Cooldown      = 1
local Jarak         = 3
local ModeDepan     = true

-- Auto Farm delays
local dBeli     = 2
local dTanam    = 2
local dPanen    = 3
local dJual     = 2
local waitPanen = 30

-- Counter & Loop handles
local SiklusCount = 0
local BeliLoop    = nil
local ESPObjects  = {}

-- Remote test
local testRemoteName = ""
local testArg1       = ""

-- ============================================
-- UTILITY
-- ============================================

local function notif(judul, isi, dur)
    pcall(function()
        Rayfield:Notify({
            Title    = judul,
            Content  = isi,
            Duration = dur or 3,
            Image    = 4483362458
        })
    end)
    print("[XKID] " .. judul .. " — " .. isi)
end

local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getPos()
    local r = getRoot()
    return r and r.Position or nil
end

local function getCF()
    local r = getRoot()
    return r and r.CFrame or nil
end

-- Unified teleport: Vector3 / CFrame / BasePart / Model
local function tp(obj)
    if not obj then return false end
    local root = getRoot()
    if not root then return false end

    local pos
    if typeof(obj) == "Vector3" then
        pos = obj
    elseif typeof(obj) == "CFrame" then
        root.CFrame = obj + Vector3.new(0, 5, 0)
        task.wait(0.3)
        return true
    elseif obj:IsA("BasePart") then
        pos = obj.Position
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            pos = obj.PrimaryPart.Position
        elseif obj:FindFirstChild("HumanoidRootPart") then
            pos = obj.HumanoidRootPart.Position
        elseif obj:FindFirstChild("Head") then
            pos = obj.Head.Position
        end
    end

    if not pos then return false end
    root.CFrame = CFrame.new(pos.X, pos.Y + 5, pos.Z)
    task.wait(0.3)
    return true
end

local function tpCoord(x, y, z)
    local root = getRoot()
    if not root then return false end
    root.CFrame = CFrame.new(x, y + 5, z)
    task.wait(0.3)
    return true
end

local function cari(nama)
    nama = nama:lower()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower() == nama then return v end
    end
    return nil
end

local function findNearest(radius, keyword)
    local root = getRoot()
    if not root then return nil end
    local nearest, minDist = nil, radius or 100
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("BasePart") then
            if not keyword or v.Name:lower():find(keyword:lower()) then
                local pos = v:IsA("BasePart") and v.Position
                    or (v.PrimaryPart and v.PrimaryPart.Position)
                    or nil
                if pos then
                    local d = (pos - root.Position).Magnitude
                    if d < minDist then minDist = d; nearest = v end
                end
            end
        end
    end
    return nearest
end

-- ============================================
-- PROXIMITY PROMPT
-- ============================================

local function getPPDekat(radius)
    radius = radius or 15
    local root = getRoot()
    if not root then return nil end
    local best, bestD = nil, radius
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local par = v.Parent
            if par and par:IsA("BasePart") then
                local d = (par.Position - root.Position).Magnitude
                if d < bestD then best = v; bestD = d end
            end
        end
    end
    return best
end

local function firePrompt(prompt)
    if not prompt then return end
    pcall(function() fireproximityprompt(prompt) end)
    task.wait(0.1)
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- ============================================
-- UI CLICK
-- ============================================

local function klikBeli(tombol)
    if not tombol then return false end
    pcall(function()
        if tombol:IsA("GuiButton") then tombol.MouseButton1Click:Fire() end
    end)
    task.wait(0.05)
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        local pos = tombol.AbsolutePosition + (tombol.AbsoluteSize / 2)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true,  game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    task.wait(0.1)
    return true
end

-- ============================================
-- NPC / TOKO
-- ============================================

local function bukaToko(npcName, delayTime)
    delayTime = delayTime or 1.5
    local npc = cari(npcName)
    if not npc then
        notif("NPC Error", npcName .. " tidak ditemukan!", 3)
        return false
    end
    tp(npc)
    task.wait(0.8)
    local prompt  = nil
    local searchIn = npc:IsA("Model") and npc or npc.Parent
    for _, v in pairs(searchIn:GetDescendants()) do
        if v:IsA("ProximityPrompt") then prompt = v; break end
    end
    if not prompt then prompt = getPPDekat(15) end
    if not prompt then
        notif("Prompt Error", "Tidak ada ProximityPrompt!", 3)
        return false
    end
    firePrompt(prompt)
    task.wait(delayTime)
    return true
end

-- ============================================
-- REMOTE SYSTEM
-- ============================================

local function getRemote(name)
    for _, v in pairs(RS:GetDescendants()) do
        if v.Name == name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            return v
        end
    end
    return nil
end

local function fireR(name, ...)
    local r = getRemote(name)
    if not r then return false, "Remote not found: " .. name end
    local ok, result = pcall(function(...)
        if r:IsA("RemoteEvent") then r:FireServer(...); return "Fired"
        else return r:InvokeServer(...) end
    end, ...)
    return ok, result
end

-- ============================================
-- LAHAN CACHE — PER JENIS
-- ============================================

local function cacheLahan(jenis)
    local data = LahanData[jenis]
    if not data then return {} end

    local now = tick()
    if now - data.cacheTime < 5 and #data.cache > 0 then
        return data.cache
    end

    data.cache = {}

    if data.pos then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n = v.Name:lower()
                local match = false
                for _, kw in ipairs(data.keywords) do
                    if n:find(kw) then match = true; break end
                end
                if match then
                    if (v.Position - data.pos).Magnitude <= data.radius then
                        table.insert(data.cache, v)
                    end
                end
            end
        end
    end

    -- Fallback
    if #data.cache == 0 and data.pos then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n = v.Name:lower()
                for _, kw in ipairs(data.keywords) do
                    if n:find(kw) then
                        table.insert(data.cache, v)
                        break
                    end
                end
            end
        end
    end

    data.cacheTime = now
    return data.cache
end

local function getLahan(jenis)
    return cacheLahan(jenis or ActiveFarmJenis)
end

local function simpanPosLahan(jenis)
    local root = getRoot()
    if not root then notif("Error", "Karakter belum ready!", 3); return false end

    local data    = LahanData[jenis]
    data.pos      = root.Position
    data.cache    = {}
    data.cacheTime = 0
    cacheLahan(jenis)

    local p = data.pos
    notif(data.label .. " Tersimpan ✅",
        string.format("X=%.1f Z=%.1f\n%d lahan ditemukan", p.X, p.Z, #data.cache), 4)
    return true
end

-- ============================================
-- AUTO BELI BIBIT — SKEMA BARU (FIX)
-- ============================================

local function autoBeliBibit(bibit, jumlah)
    bibit  = bibit  or selectedBibit
    jumlah = jumlah or jumlahBeli

    -- 1. Teleport ke NPC bibit
    local npc = cari("npcbibit")
    if npc then
        tp(npc)
        task.wait(0.8)
    else
        notif("NPC Error ❌", "npcbibit tidak ditemukan!", 3)
        return false
    end

    -- 2. Buka toko (fire prompt)
    local prompt   = nil
    local searchIn = npc:IsA("Model") and npc or npc.Parent
    for _, v in pairs(searchIn:GetDescendants()) do
        if v:IsA("ProximityPrompt") then prompt = v; break end
    end
    if not prompt then prompt = getPPDekat(15) end
    if prompt then firePrompt(prompt); task.wait(1.5) end

    -- 3. Atur jumlah (tombol +)
    local gui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if gui and jumlah > 1 then
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and v.Text == "+" and v.Visible then
                for i = 1, jumlah - 1 do
                    klikBeli(v); task.wait(0.05)
                end
                break
            end
        end
        task.wait(0.2)
    end

    -- 4. Klik Beli
    local berhasil = false
    gui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if gui then
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and v.Visible then
                local t = v.Text:lower()
                if t:find("beli") or t:find("buy") then
                    klikBeli(v); berhasil = true; break
                end
            end
        end
    end

    -- 5. Tutup toko
    task.wait(0.3)
    gui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if gui then
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and v.Visible then
                local t = v.Text:lower()
                if t:find("tutup") or t:find("close") then
                    klikBeli(v); break
                end
            end
        end
    end

    return berhasil
end

-- ============================================
-- AUTO JUAL
-- ============================================

local function autoJual()
    if not bukaToko("npcpenjual", 1.5) then return false end

    local gui = LocalPlayer:WaitForChild("PlayerGui", 5)
    task.wait(0.3)
    if gui then
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and v.Visible then
                local t = v.Text:lower()
                if (t:find("jual") or t:find("sell")) and not t:find("tutup") then
                    klikBeli(v); task.wait(0.2)
                end
            end
        end
    end

    task.wait(0.3)
    gui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if gui then
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and v.Visible then
                local t = v.Text:lower()
                if t:find("tutup") or t:find("close") then klikBeli(v); break end
            end
        end
    end
    return true
end

-- ============================================
-- AUTO PANEN — pakai lahan per-jenis
-- ============================================

local function autoPanen(jenis)
    local lahans    = getLahan(jenis)
    local harvested = 0

    for _, lahan in ipairs(lahans) do
        if not _G.AutoPanen and not _G.AutoFarm then break end
        pcall(function()
            tp(lahan)
            task.wait(0.5)
            local prompt = getPPDekat(10)
            if prompt then firePrompt(prompt); harvested = harvested + 1 end
        end)
        task.wait(0.3)
    end
    return harvested
end

-- ============================================
-- INTERAK LAHAN (tanam via UI)
-- ============================================

local function interakLahan(lahanObj, delayTime)
    delayTime = delayTime or 1.5
    if not lahanObj then return false end

    local success = pcall(function()
        tp(lahanObj)
        task.wait(delayTime)
        local prompt = getPPDekat(10)
        if prompt then firePrompt(prompt) end
        task.wait(0.3)

        local gui = LocalPlayer:WaitForChild("PlayerGui", 3)
        if gui then
            for _, v in pairs(gui:GetDescendants()) do
                if v:IsA("TextButton") and v.Visible then
                    local t = v.Text:lower()
                    if t:find("tanam") or t:find("plant") then
                        klikBeli(v); break
                    end
                end
            end
        end
    end)
    return success
end

-- ============================================
-- TELEPORT PANEN 3 TITIK
-- ============================================

local function teleportPanenLoop()
    local points = {CopyPositions.Sawah, CopyPositions.Sawit, CopyPositions.Ternak}
    local index  = 1

    while _G.TeleportPanen do
        local point = points[index]
        if point then
            tp(point); task.wait(0.5)
            local prompt = getPPDekat(10)
            if prompt then firePrompt(prompt) end
            fireR("HarvestCrop")
            task.wait(Cooldown)
        end
        index = index + 1
        if index > 3 then index = 1 end
        if not _G.TeleportPanen then break end
        task.wait(Jarak)
    end
end

-- ============================================
-- DETECTOR SAWIT
-- ============================================

local function detectorSawitLoop()
    while _G.DetectorSawit do
        local sawit = findNearest(100, "sawit") or findNearest(100, "kelapa")
        if sawit then
            notif("Sawit Ditemukan!", "Auto teleport...", 2)
            tp(sawit)
            local prompt = getPPDekat(10)
            if prompt then firePrompt(prompt) end
            fireR("HarvestCrop")
            task.wait(Cooldown)
        else
            task.wait(2)
        end
        if not _G.DetectorSawit then break end
    end
end

-- ============================================
-- ESP SYSTEM
-- ============================================

local function createESP(obj, color)
    if not obj then return end
    local hl = Instance.new("Highlight")
    hl.Name                = "XKIDESP"
    hl.FillColor           = color or Color3.fromRGB(0, 255, 0)
    hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency    = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent              = obj
    table.insert(ESPObjects, hl)
end

local function clearESP()
    for _, esp in pairs(ESPObjects) do
        pcall(function() esp:Destroy() end)
    end
    ESPObjects = {}
end

local function updateESP()
    clearESP()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("crop") or n:find("tanaman") or n:find("padi") or n:find("sawit") then
                createESP(v, Color3.fromRGB(0, 255, 0))
            elseif n:find("npc") or n:find("toko") then
                createESP(v, Color3.fromRGB(255, 255, 0))
            elseif n:find("tanah") or n:find("lahan") or n:find("plot") then
                createESP(v, Color3.fromRGB(0, 170, 255))
            elseif n:find("ternak") or n:find("kandang") then
                createESP(v, Color3.fromRGB(255, 128, 0))
            end
        end
    end
end

-- ============================================
-- STOP ALL
-- ============================================

local function stopSemua()
    _G.AutoFarm      = false
    _G.AutoBeli      = false
    _G.AutoTanam     = false
    _G.AutoPanen     = false
    _G.AutoJual      = false
    _G.TeleportPanen = false
    _G.DetectorSawit = false
    if BeliLoop then
        pcall(function() task.cancel(BeliLoop) end)
        BeliLoop = nil
    end
    notif("⛔ STOP SEMUA!", "Semua auto dimatikan", 3)
end

-- ============================================
-- TAB SETUP
-- ============================================
local TabStatus = Window:CreateTab("📊 Status",       nil)
local TabBibit  = Window:CreateTab("🛒 Beli Bibit",   nil)
local TabFarm   = Window:CreateTab("🤖 Auto Farm",    nil)
local TabLahan  = Window:CreateTab("🌾 Posisi Lahan", nil)
local TabCopy   = Window:CreateTab("📋 Copy TP",      nil)
local TabTanam  = Window:CreateTab("🌴 Tanam",        nil)
local TabTP     = Window:CreateTab("🚀 Teleport",     nil)
local TabESP    = Window:CreateTab("👁 ESP",          nil)
local TabTools  = Window:CreateTab("🛠 Tools",        nil)
local TabSet    = Window:CreateTab("⚙ Setting",      nil)
local TabTest   = Window:CreateTab("🧪 Test Remote",  nil)

-- ============================================
-- TAB STATUS — Live Monitor
-- ============================================
TabStatus:CreateSection("📊 Live Status")

local StFarm   = TabStatus:CreateParagraph({Title = "Auto Farm",          Content = "🔴 OFF"})
local StBeli   = TabStatus:CreateParagraph({Title = "Auto Beli",          Content = "🔴 OFF"})
local StLahan  = TabStatus:CreateParagraph({Title = "Posisi Lahan",       Content = "Belum disimpan"})
local StCopy   = TabStatus:CreateParagraph({Title = "Copy Positions (TP)",Content = "Sawah ❌ | Sawit ❌ | Ternak ❌"})
local StSiklus = TabStatus:CreateParagraph({Title = "Siklus Farm",        Content = "0 siklus"})
local StESP    = TabStatus:CreateParagraph({Title = "ESP",                Content = "🔴 OFF"})

task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            StFarm:Set({Title = "Auto Farm",
                Content = _G.AutoFarm
                    and ("🟢 RUNNING — Siklus " .. SiklusCount .. " — Jenis: " .. ActiveFarmJenis)
                    or  "🔴 OFF"})

            StBeli:Set({Title = "Auto Beli",
                Content = _G.AutoBeli and ("🟢 RUNNING — " .. selectedBibit .. " x" .. jumlahBeli) or "🔴 OFF"})

            local lahanInfo = ""
            for jenis, data in pairs(LahanData) do
                if data.pos then
                    lahanInfo = lahanInfo .. data.label .. " ✅ " .. #data.cache .. " lahan\n"
                else
                    lahanInfo = lahanInfo .. data.label .. " ❌ belum simpan\n"
                end
            end
            StLahan:Set({Title = "Posisi Lahan (per jenis)", Content = lahanInfo})

            StCopy:Set({Title = "Copy Positions (TP)",
                Content = "Sawah "  .. (CopyPositions.Sawah  and "✅" or "❌") ..
                          " | Sawit "  .. (CopyPositions.Sawit  and "✅" or "❌") ..
                          " | Ternak " .. (CopyPositions.Ternak and "✅" or "❌")})

            StSiklus:Set({Title = "Siklus Farm",
                Content = SiklusCount .. " siklus — Aktif: " .. ActiveFarmJenis})

            StESP:Set({Title = "ESP",
                Content = _G.ESP and ("🟢 ON — " .. #ESPObjects .. " obj") or "🔴 OFF"})
        end)
        task.wait(1)
    end
end)

-- ============================================
-- TAB BELI BIBIT
-- ============================================
TabBibit:CreateSection("🌱 Pilih Bibit")

local opsiBibit = {}
for _, b in ipairs(BIBIT) do
    table.insert(opsiBibit, b.emoji .. " " .. b.name .. " Lv." .. b.minLv .. " | " .. b.harga .. "💰")
end

TabBibit:CreateDropdown({
    Name          = "Jenis Bibit",
    Options       = opsiBibit,
    CurrentOption = {opsiBibit[1]},
    Callback      = function(v)
        for _, b in ipairs(BIBIT) do
            if v[1]:find(b.name) then
                selectedBibit = b.name
                notif("Dipilih", b.emoji .. " " .. b.name, 2)
                break
            end
        end
    end
})

TabBibit:CreateSlider({
    Name = "Jumlah Beli", Range = {1, 99}, Increment = 1, CurrentValue = 1,
    Callback = function(v) jumlahBeli = v end
})

TabBibit:CreateSection("🛒 Beli Sekarang")

TabBibit:CreateButton({
    Name = "💰 BELI SEKARANG",
    Callback = function()
        task.spawn(function()
            notif("Membeli", jumlahBeli .. "x " .. selectedBibit, 2)
            local ok = autoBeliBibit(selectedBibit, jumlahBeli)
            notif(ok and "Sukses! ✅" or "Gagal ❌", ok and "Pembelian berhasil" or "Coba lagi", 3)
        end)
    end
})

TabBibit:CreateSection("⚡ Beli Cepat")

for _, b in ipairs(BIBIT) do
    TabBibit:CreateButton({
        Name = b.emoji .. " " .. b.name .. " | " .. b.harga .. "💰",
        Callback = function()
            task.spawn(function()
                selectedBibit = b.name
                autoBeliBibit(b.name, jumlahBeli)
            end)
        end
    })
end

TabBibit:CreateSection("🔄 Auto Beli Loop")

TabBibit:CreateParagraph({
    Title   = "Info Auto Beli",
    Content = "Auto teleport ke NPC → beli → tunggu 10 detik → ulangi"
})

-- ┌─────────────────────────────────────────┐
-- │  AUTO BELI — SKEMA BARU (FIX)            │
-- └─────────────────────────────────────────┘
TabBibit:CreateToggle({
    Name         = "🛒 Auto Beli Bibit",
    CurrentValue = false,
    Callback     = function(v)
        _G.AutoBeli = v
        if v then
            notif("Auto Beli ON ✅", selectedBibit .. " x" .. jumlahBeli, 3)

            BeliLoop = task.spawn(function()
                while _G.AutoBeli do
                    -- Teleport ke NPC dulu
                    local npc = cari("npcbibit")
                    if npc then tp(npc) end
                    task.wait(1)

                    -- Panggil fungsi beli
                    local ok = autoBeliBibit(selectedBibit, jumlahBeli)
                    if ok then
                        notif("Auto Beli ✅", selectedBibit .. " x" .. jumlahBeli, 2)
                    end

                    -- Tunggu sebelum beli lagi
                    task.wait(10)
                end
            end)
        else
            if BeliLoop then
                pcall(function() task.cancel(BeliLoop) end)
                BeliLoop = nil
            end
            notif("Auto Beli OFF", "Dihentikan", 2)
        end
    end
})

-- ============================================
-- TAB AUTO FARM
-- ============================================
TabFarm:CreateSection("🎯 Pilih Jenis Lahan Farm")

TabFarm:CreateDropdown({
    Name          = "Lahan yang dipakai Auto Farm",
    Options       = {"🌾 Sawah", "🌴 Sawit", "🐄 Ternak"},
    CurrentOption = {"🌾 Sawah"},
    Callback      = function(v)
        if v[1]:find("Sawah")  then ActiveFarmJenis = "Sawah"  end
        if v[1]:find("Sawit")  then ActiveFarmJenis = "Sawit"  end
        if v[1]:find("Ternak") then ActiveFarmJenis = "Ternak" end
        notif("Lahan Farm Aktif", ActiveFarmJenis, 2)
    end
})

TabFarm:CreateParagraph({
    Title   = "⚠️ PENTING — Baca Dulu!",
    Content = "Sebelum Auto Farm:\n1. Pergi ke lahan yang BENAR\n2. Tab 🌾 Posisi Lahan → Simpan posisi\n3. Pilih jenis lahan di dropdown atas\n4. Baru aktifkan Auto Farm\n\n❌ Jangan campur posisi Sawah & Sawit!"
})

TabFarm:CreateSection("⏱ Delay Setting")

TabFarm:CreateSlider({Name="Delay Beli (s)",   Range={1,10}, Increment=0.5, CurrentValue=2, Callback=function(v) dBeli=v end})
TabFarm:CreateSlider({Name="Delay Tanam (s)",  Range={1,10}, Increment=0.5, CurrentValue=2, Callback=function(v) dTanam=v end})
TabFarm:CreateSlider({Name="Delay Panen (s)",  Range={1,10}, Increment=0.5, CurrentValue=3, Callback=function(v) dPanen=v end})
TabFarm:CreateSlider({Name="Delay Jual (s)",   Range={1,10}, Increment=0.5, CurrentValue=2, Callback=function(v) dJual=v end})
TabFarm:CreateSlider({Name="Waktu Tunggu Panen (s)", Range={10,300}, Increment=5, CurrentValue=30, Callback=function(v) waitPanen=v end})

TabFarm:CreateSection("🔥 FULL AUTO FARM")

TabFarm:CreateToggle({
    Name         = "🔥 FULL AUTO: Beli → Tanam → Panen → Jual",
    CurrentValue = false,
    Callback     = function(v)
        _G.AutoFarm = v

        if v then
            -- Cek posisi lahan sudah tersimpan
            if not LahanData[ActiveFarmJenis].pos then
                notif("⚠️ ERROR!", "Simpan posisi lahan " .. ActiveFarmJenis
                    .. " dulu!\nTab 🌾 Posisi Lahan → SIMPAN", 7)
                _G.AutoFarm = false
                return
            end

            SiklusCount = 0
            notif("AUTO FARM ON ✅", "Jenis: " .. ActiveFarmJenis .. " 🔥", 3)

            task.spawn(function()
                while _G.AutoFarm do
                    SiklusCount = SiklusCount + 1

                    -- Step 1: Beli bibit
                    notif("Siklus #"..SiklusCount, "Step 1: Beli bibit...", 2)
                    pcall(function() autoBeliBibit(selectedBibit, jumlahBeli) end)
                    if not _G.AutoFarm then break end
                    task.wait(dBeli)

                    -- Step 2: Tanam di lahan YANG BENAR sesuai jenis
                    notif("Siklus #"..SiklusCount, "Step 2: Tanam di "..ActiveFarmJenis.."...", 2)
                    local lahans = getLahan(ActiveFarmJenis)
                    if #lahans == 0 then
                        notif("⚠️ Lahan Kosong!", "Tidak ada lahan "..ActiveFarmJenis
                            .."\nRefresh di tab Posisi Lahan", 5)
                    end
                    for _, lahan in ipairs(lahans) do
                        if not _G.AutoFarm then break end
                        pcall(function() interakLahan(lahan, dTanam) end)
                        task.wait(0.5)
                    end
                    if not _G.AutoFarm then break end

                    -- Step 3: Tunggu panen
                    notif("Siklus #"..SiklusCount, "Step 3: Tunggu "..waitPanen.."s...", 3)
                    local waited = 0
                    while waited < waitPanen and _G.AutoFarm do
                        task.wait(1); waited = waited + 1
                    end
                    if not _G.AutoFarm then break end

                    -- Step 4: Panen di lahan YANG SAMA
                    notif("Siklus #"..SiklusCount, "Step 4: Panen "..ActiveFarmJenis.."...", 2)
                    pcall(function() autoPanen(ActiveFarmJenis) end)
                    if not _G.AutoFarm then break end
                    task.wait(dPanen)

                    -- Step 5: Jual
                    notif("Siklus #"..SiklusCount, "Step 5: Jual hasil...", 2)
                    pcall(autoJual)
                    if not _G.AutoFarm then break end
                    task.wait(dJual)

                    notif("✅ Siklus #"..SiklusCount, "Selesai! Lanjut...", 3)
                    task.wait(2)
                end

                notif("AUTO FARM", "Stopped di siklus "..SiklusCount, 3)
            end)
        else
            notif("AUTO FARM OFF", "Dihentikan", 2)
        end
    end
})

TabFarm:CreateSection("🎯 Auto Satuan")

TabFarm:CreateToggle({
    Name = "Auto Tanam Saja", CurrentValue = false,
    Callback = function(v)
        _G.AutoTanam = v
        if v then
            task.spawn(function()
                while _G.AutoTanam do
                    for _, lahan in ipairs(getLahan(ActiveFarmJenis)) do
                        if not _G.AutoTanam then break end
                        pcall(function() interakLahan(lahan, dTanam) end)
                        task.wait(0.5)
                    end
                    task.wait(3)
                end
            end)
        end
    end
})

TabFarm:CreateToggle({
    Name = "Auto Panen Saja", CurrentValue = false,
    Callback = function(v)
        _G.AutoPanen = v
        if v then
            task.spawn(function()
                while _G.AutoPanen do
                    pcall(function() autoPanen(ActiveFarmJenis) end)
                    task.wait(5)
                end
            end)
        end
    end
})

TabFarm:CreateToggle({
    Name = "Auto Jual Saja", CurrentValue = false,
    Callback = function(v)
        _G.AutoJual = v
        if v then
            task.spawn(function()
                while _G.AutoJual do
                    pcall(autoJual)
                    task.wait(dJual + 5)
                end
            end)
        end
    end
})

TabFarm:CreateSection("🛑 Emergency")

TabFarm:CreateButton({
    Name = "🛑 STOP SEMUA AUTO",
    Callback = function() stopSemua() end
})

-- ============================================
-- TAB POSISI LAHAN — PER JENIS (BARU!)
-- ============================================
TabLahan:CreateSection("💾 Simpan Posisi Per Jenis Lahan")

TabLahan:CreateParagraph({
    Title   = "📌 Cara Pakai",
    Content = "1. Berdiri di TENGAH lahan yang tepat\n2. Tekan SIMPAN sesuai jenisnya\n3. Scan hanya mencari di area itu\n4. Sawit TIDAK akan nyasar ke Ternak!"
})

-- Sawah
TabLahan:CreateButton({
    Name = "💾 SIMPAN POSISI LAHAN SAWAH 🌾",
    Callback = function() simpanPosLahan("Sawah") end
})

TabLahan:CreateSlider({
    Name = "Radius Scan Sawah (stud)", Range = {10, 200}, Increment = 10, CurrentValue = 50,
    Callback = function(v)
        LahanData.Sawah.radius    = v
        LahanData.Sawah.cacheTime = 0
        cacheLahan("Sawah")
    end
})

-- Sawit
TabLahan:CreateButton({
    Name = "💾 SIMPAN POSISI LAHAN SAWIT 🌴",
    Callback = function() simpanPosLahan("Sawit") end
})

TabLahan:CreateSlider({
    Name = "Radius Scan Sawit (stud)", Range = {10, 200}, Increment = 10, CurrentValue = 50,
    Callback = function(v)
        LahanData.Sawit.radius    = v
        LahanData.Sawit.cacheTime = 0
        cacheLahan("Sawit")
    end
})

-- Ternak
TabLahan:CreateButton({
    Name = "💾 SIMPAN POSISI LAHAN TERNAK 🐄",
    Callback = function() simpanPosLahan("Ternak") end
})

TabLahan:CreateSlider({
    Name = "Radius Scan Ternak (stud)", Range = {10, 200}, Increment = 10, CurrentValue = 50,
    Callback = function(v)
        LahanData.Ternak.radius    = v
        LahanData.Ternak.cacheTime = 0
        cacheLahan("Ternak")
    end
})

TabLahan:CreateSection("📊 Info & Tools")

TabLahan:CreateButton({
    Name = "📊 Info Semua Lahan",
    Callback = function()
        local msg = ""
        for jenis, data in pairs(LahanData) do
            if data.pos then
                msg = msg .. data.label .. " ✅\n"
                msg = msg .. string.format("  X=%.1f Z=%.1f — %d lahan\n", data.pos.X, data.pos.Z, #data.cache)
            else
                msg = msg .. data.label .. " ❌ belum disimpan\n"
            end
        end
        notif("Info Lahan", msg, 8)
    end
})

TabLahan:CreateButton({
    Name = "🔄 Refresh Semua Cache Lahan",
    Callback = function()
        for jenis, data in pairs(LahanData) do
            data.cacheTime = 0
            cacheLahan(jenis)
        end
        local msg = ""
        for jenis, data in pairs(LahanData) do
            msg = msg .. jenis .. ": " .. #data.cache .. " lahan\n"
        end
        notif("Refresh ✅", msg, 4)
    end
})

TabLahan:CreateButton({
    Name = "🗑 Hapus SEMUA Posisi Lahan",
    Callback = function()
        for jenis, data in pairs(LahanData) do
            data.pos       = nil
            data.cache     = {}
            data.cacheTime = 0
        end
        notif("Reset", "Semua posisi lahan dihapus", 3)
    end
})

-- ============================================
-- TAB COPY POSITION — 3 Titik TP
-- ============================================
TabCopy:CreateSection("📍 Simpan 3 Titik Teleport Panen")

TabCopy:CreateParagraph({
    Title   = "CARA PAKAI",
    Content = "1. Pergi ke lokasi\n2. Tekan COPY\n3. Aktifkan Teleport Panen di bawah\n\n(Berbeda dengan Posisi Lahan!)\nCopy Pos = titik TP untuk panen keliling\nPosisi Lahan = area scan Auto Farm"
})

TabCopy:CreateButton({
    Name = "📍 COPY SAWAH (Titik 1)",
    Callback = function()
        local pos = getPos()
        if pos then
            CopyPositions.Sawah = pos
            notif("Copy Sawah ✅", string.format("X=%.1f, Z=%.1f", pos.X, pos.Z), 3)
        end
    end
})

TabCopy:CreateButton({
    Name = "🌴 COPY SAWIT (Titik 2)",
    Callback = function()
        local pos = getPos()
        if pos then
            CopyPositions.Sawit = pos
            notif("Copy Sawit ✅", string.format("X=%.1f, Z=%.1f", pos.X, pos.Z), 3)
        end
    end
})

TabCopy:CreateButton({
    Name = "🐄 COPY TERNAK (Titik 3)",
    Callback = function()
        local pos = getPos()
        if pos then
            CopyPositions.Ternak = pos
            notif("Copy Ternak ✅", string.format("X=%.1f, Z=%.1f", pos.X, pos.Z), 3)
        end
    end
})

TabCopy:CreateButton({
    Name = "📊 Lihat Status Copy",
    Callback = function()
        local msg  = "Sawah:  " .. (CopyPositions.Sawah  and "✅" or "❌") .. "\n"
        msg = msg .. "Sawit:  " .. (CopyPositions.Sawit  and "✅" or "❌") .. "\n"
        msg = msg .. "Ternak: " .. (CopyPositions.Ternak and "✅" or "❌")
        notif("Status Copy", msg, 5)
    end
})

TabCopy:CreateButton({
    Name = "🗑 Reset Semua Copy",
    Callback = function()
        CopyPositions.Sawah  = nil
        CopyPositions.Sawit  = nil
        CopyPositions.Ternak = nil
        notif("Reset", "Semua copy positions dihapus", 3)
    end
})

TabCopy:CreateSection("🚀 Teleport Panen 3 Titik")

TabCopy:CreateToggle({
    Name = "🚀 Teleport Panen Loop", CurrentValue = false,
    Callback = function(v)
        _G.TeleportPanen = v
        if v then
            if not CopyPositions.Sawah and not CopyPositions.Sawit and not CopyPositions.Ternak then
                notif("ERROR! ❌", "Copy minimal 1 titik dulu!", 4)
                _G.TeleportPanen = false
                return
            end
            task.spawn(teleportPanenLoop)
            notif("Teleport Panen ON ✅", "Loop berjalan", 2)
        else
            notif("Teleport Panen", "OFF", 2)
        end
    end
})

-- ============================================
-- TAB TANAM MANUAL
-- ============================================
TabTanam:CreateSection("🌴 Tanam Sawit Manual")

TabTanam:CreateButton({
    Name = "📍 COPY POSISI TANAM SAWIT",
    Callback = function()
        local cf = getCF()
        if cf then TanamPositions.Sawit = cf; notif("Copy Sawit ✅", "Tersimpan", 3) end
    end
})

TabTanam:CreateButton({
    Name = "🌴 TANAM SAWIT",
    Callback = function()
        if TanamPositions.Sawit then
            tp(TanamPositions.Sawit); task.wait(0.5)
            fireR("PlantCrop", "Sawit")
            notif("Tanam Sawit ✅", "Berhasil!", 2)
        else
            notif("Error ❌", "Copy posisi dulu!", 3)
        end
    end
})

TabTanam:CreateSection("🥥 Tanam Durian Manual")

TabTanam:CreateButton({
    Name = "📍 COPY POSISI TANAM DURIAN",
    Callback = function()
        local cf = getCF()
        if cf then TanamPositions.Durian = cf; notif("Copy Durian ✅", "Tersimpan", 3) end
    end
})

TabTanam:CreateButton({
    Name = "🥥 TANAM DURIAN",
    Callback = function()
        if TanamPositions.Durian then
            tp(TanamPositions.Durian); task.wait(0.5)
            fireR("PlantCrop", "Durian")
            notif("Tanam Durian ✅", "Berhasil!", 2)
        else
            notif("Error ❌", "Copy posisi dulu!", 3)
        end
    end
})

TabTanam:CreateSection("🔍 Detector Sawit")

TabTanam:CreateToggle({
    Name = "🔍 Detector Sawit (Auto Scan & Panen)", CurrentValue = false,
    Callback = function(v)
        _G.DetectorSawit = v
        if v then
            task.spawn(detectorSawitLoop)
            notif("Detector ON ✅", "Auto cari & panen sawit...", 3)
        else
            notif("Detector OFF", "", 2)
        end
    end
})

-- ============================================
-- TAB TELEPORT NPC
-- ============================================
TabTP:CreateSection("🏪 NPC Toko")

local npcList = {
    {name = "npcbibit",         label = "🌱 Beli Bibit"},
    {name = "npcpenjual",       label = "💰 Jual Hasil"},
    {name = "npcalat",          label = "🔧 Beli Alat"},
    {name = "NPCPedagangTelur", label = "🥚 Jual Telur"},
    {name = "NPCPedagangSawit", label = "🌴 Jual Sawit"},
}

for _, npc in ipairs(npcList) do
    TabTP:CreateButton({
        Name = npc.label,
        Callback = function()
            local o = cari(npc.name)
            if o then tp(o); notif("Teleport ✅", npc.label, 2)
            else notif("Error ❌", npc.name .. " tidak ada", 3) end
        end
    })
end

TabTP:CreateSection("🌾 Ke Lahan Tersimpan")

for jenis, data in pairs(LahanData) do
    TabTP:CreateButton({
        Name = "🏠 Ke Lahan " .. jenis,
        Callback = function()
            if data.pos then
                tpCoord(data.pos.X, data.pos.Y, data.pos.Z)
                notif("Teleport ✅", "Di lahan " .. jenis, 2)
            else
                notif("Error ❌", "Simpan posisi " .. jenis .. " dulu!", 3)
            end
        end
    })
end

-- ============================================
-- TAB ESP
-- ============================================
TabESP:CreateSection("👁 ESP System")

TabESP:CreateParagraph({
    Title   = "Warna ESP",
    Content = "🟢 Hijau = Tanaman/Crop\n🟡 Kuning = NPC/Toko\n🔵 Biru = Tanah/Lahan\n🟠 Oranye = Ternak/Kandang"
})

TabESP:CreateToggle({
    Name = "👁 ESP Aktif", CurrentValue = false,
    Callback = function(v)
        _G.ESP = v
        if v then updateESP(); notif("ESP ON ✅", #ESPObjects .. " obj highlight", 2)
        else clearESP(); notif("ESP OFF", "", 2) end
    end
})

TabESP:CreateButton({
    Name = "🔄 Refresh ESP",
    Callback = function()
        if _G.ESP then updateESP(); notif("Refresh ✅", #ESPObjects .. " obj", 3)
        else notif("ESP", "Aktifkan ESP dulu!", 3) end
    end
})

TabESP:CreateButton({
    Name = "🗑 Clear ESP",
    Callback = function() clearESP(); _G.ESP = false; notif("ESP Cleared ✅", "", 2) end
})

-- ============================================
-- TAB TOOLS
-- ============================================
TabTools:CreateSection("📍 Info")

TabTools:CreateButton({
    Name = "📍 Koordinat Saya",
    Callback = function()
        local r = getRoot()
        if r then
            local p = r.Position
            notif("Posisi Saya", string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 5)
        end
    end
})

TabTools:CreateButton({
    Name = "🔄 Respawn",
    Callback = function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0; notif("Respawn", "Tunggu...", 2) end
        end
    end
})

TabTools:CreateSection("🧪 Quick Test")

TabTools:CreateButton({
    Name = "Test Buka Toko Bibit",
    Callback = function()
        task.spawn(function()
            local ok = bukaToko("npcbibit", 2)
            notif(ok and "Sukses ✅" or "Gagal ❌", ok and "Toko terbuka" or "Coba lagi", 3)
        end)
    end
})

TabTools:CreateButton({
    Name = "Test Auto Jual",
    Callback = function()
        task.spawn(function()
            local ok = autoJual()
            notif(ok and "Sukses ✅" or "Gagal ❌", ok and "Terjual" or "Gagal", 3)
        end)
    end
})

-- ============================================
-- TAB SETTING
-- ============================================
TabSet:CreateSection("⏱ Cooldown Remote")

TabSet:CreateSlider({
    Name = "Cooldown Remote (s)", Range = {0.5, 5}, Increment = 0.5, CurrentValue = 1,
    Callback = function(v) Cooldown = v end
})

TabSet:CreateSection("📏 Jarak Teleport Panen")

TabSet:CreateSlider({
    Name = "Jarak antar TP (s)", Range = {1, 10}, Increment = 1, CurrentValue = 3,
    Callback = function(v) Jarak = v end
})

TabSet:CreateSection("🧭 Mode Arah")

TabSet:CreateToggle({
    Name = "Mode Depan (ON) / Belakang (OFF)", CurrentValue = true,
    Callback = function(v)
        ModeDepan = v
        notif("Mode", v and "Depan aktif" or "Belakang aktif", 2)
    end
})

TabSet:CreateSection("🛑 Emergency")

TabSet:CreateButton({
    Name = "🛑 STOP SEMUA AUTO",
    Callback = function() stopSemua() end
})

-- ============================================
-- TAB TEST REMOTE
-- ============================================
TabTest:CreateSection("🔥 Fire Remote Manual")

TabTest:CreateInput({
    Name = "Nama Remote", PlaceholderText = "contoh: PlantCrop",
    RemoveTextAfterFocusLost = false,
    Callback = function(v) testRemoteName = v end
})

TabTest:CreateInput({
    Name = "Argumen 1 (opsional)", PlaceholderText = "string / number / bool",
    RemoveTextAfterFocusLost = false,
    Callback = function(v) testArg1 = v end
})

TabTest:CreateButton({
    Name = "🔥 FIRE REMOTE",
    Callback = function()
        if testRemoteName == "" then notif("Error", "Masukkan nama remote!", 3); return end
        local args = {}
        if testArg1 ~= "" then
            local num = tonumber(testArg1)
            if num then table.insert(args, num)
            elseif testArg1 == "true"  then table.insert(args, true)
            elseif testArg1 == "false" then table.insert(args, false)
            else table.insert(args, testArg1) end
        end
        local ok, result = fireR(testRemoteName, table.unpack(args))
        notif(ok and "Sukses ✅" or "Gagal ❌", tostring(result), 4)
    end
})

TabTest:CreateSection("⚡ Quick Test")

local quickTests = {
    {"PlantCrop",    "🌱 PlantCrop"},
    {"HarvestCrop",  "🌿 HarvestCrop"},
    {"SellCrop",     "💰 SellCrop"},
    {"GetBibit",     "🛒 GetBibit"},
    {"RequestLahan", "🌾 RequestLahan"},
}

for _, test in ipairs(quickTests) do
    TabTest:CreateButton({
        Name = test[2],
        Callback = function()
            local ok, result = fireR(test[1])
            notif(test[1], ok and ("OK: "..tostring(result)) or ("ERROR: "..tostring(result)), 3)
        end
    })
end

-- ============================================
-- INIT
-- ============================================
notif("🌾 SAWAH INDO v8.1", "Welcome " .. myName .. "!", 5)
task.wait(1)
notif("Langkah 1", "Tab 🌾 Posisi Lahan → Simpan posisi SAWAH", 5)
task.wait(1.3)
notif("Langkah 2", "Tab 🤖 Auto Farm → Pilih jenis lahan → ON", 5)
task.wait(1.3)
notif("Langkah 3", "Tab 🛒 Beli Bibit → Pilih bibit → Auto Beli ON", 5)

print(string.rep("=", 44))
print("  SAWAH INDO v8.1 ULTIMATE — XKID HUB")
print("  Fix: Auto Beli Skema Baru + Lahan Per-Jenis")
print("  Player: " .. myName)
print(string.rep("=", 44))
