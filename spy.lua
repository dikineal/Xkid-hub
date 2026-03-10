-- ╔══════════════════════════════════════════╗
-- ║   🌾 SAWAH INDO v8.0 ULTIMATE — XKID HUB ║
-- ║   Gabungan v6.0 + v7.0 Pro               ║
-- ║   Support: Android + Delta/Arceus/Fluxus  ║
-- ╚══════════════════════════════════════════╝

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO v8.0 ULTIMATE 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "Ultimate Auto Farm 🔥",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

-- ============================================
-- SERVICES
-- ============================================
local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer
local Workspace      = game:GetService("Workspace")
local RS             = game:GetService("ReplicatedStorage")
local RunService     = game:GetService("RunService")

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
_G.AutoSell        = false  -- alias AutoJual (v7 compat)
_G.AutoBuy         = false  -- alias AutoBeli (v7 compat)
_G.ESP             = false
_G.TeleportPanen   = false
_G.DetectorSawit   = false

-- ============================================
-- DATA
-- ============================================

-- Lahan (v6 system)
local savedLahanPos  = nil
local lahanRadius    = 50
local cachedLahans   = {}
local lastCacheTime  = 0

-- Copy Positions — 3 titik (v7 system)
local CopyPositions = {
    Sawah  = nil,
    Sawit  = nil,
    Ternak = nil
}

-- Tanam positions (v7)
local TanamPositions = {
    Sawit  = nil,
    Durian = nil
}

-- Bibit data (v6)
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
local selectedBibit  = "Padi"
local jumlahBeli     = 1
local autoBeliDelay  = 3
local Cooldown       = 1
local Jarak          = 3
local ModeDepan      = true

-- Auto Farm delays (v6)
local dBeli     = 2
local dTanam    = 2
local dPanen    = 3
local dJual     = 2
local waitPanen = 30

-- Counters
local SiklusCount = 0

-- ESP storage
local ESPObjects = {}

-- Remote test inputs
local testRemoteName = ""
local testArg1       = ""

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function notif(judul, isi, dur)
    pcall(function()
        Rayfield:Notify({
            Title   = judul,
            Content = isi,
            Duration = dur or 3,
            Image   = 4483362458
        })
    end)
    print("[XKID] " .. judul .. " - " .. isi)
end

local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- Unified tp — supports Vector3, CFrame, BasePart, Model (v7 upgraded)
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

local function getPos()
    local root = getRoot()
    if root then return root.Position end
    return nil
end

local function getCF()
    local root = getRoot()
    if root then return root.CFrame end
    return nil
end

-- Find object by exact name (v6)
local function cari(nama)
    nama = nama:lower()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower() == nama then return v end
    end
    return nil
end

-- Find nearest object by keyword (v7)
local function findNearestCrop(radius, nameFilter)
    radius = radius or 50
    local root = getRoot()
    if not root then return nil end

    local nearest, minDist = nil, radius

    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("BasePart") then
            local n = v.Name:lower()
            if not nameFilter or n:find(nameFilter:lower()) then
                local pos = nil
                if v:IsA("BasePart") then
                    pos = v.Position
                elseif v.PrimaryPart then
                    pos = v.PrimaryPart.Position
                elseif v:FindFirstChild("HumanoidRootPart") then
                    pos = v.HumanoidRootPart.Position
                end

                if pos then
                    local dist = (pos - root.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = v
                    end
                end
            end
        end
    end

    return nearest
end

-- ============================================
-- PROXIMITY PROMPT SYSTEM (v6)
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
                if d < bestD then
                    best = v
                    bestD = d
                end
            end
        end
    end

    return best
end

local function firePrompt(prompt)
    if not prompt then return end

    pcall(function()
        fireproximityprompt(prompt)
    end)

    task.wait(0.1)

    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- ============================================
-- UI CLICK SYSTEM (v6)
-- ============================================

local function klikBeli(tombol)
    if not tombol then return false end

    pcall(function()
        if tombol:IsA("GuiButton") then
            tombol.MouseButton1Click:Fire()
        end
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
-- NPC / TOKO SYSTEM (v6)
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
        if v:IsA("ProximityPrompt") then
            prompt = v
            break
        end
    end

    if not prompt then
        prompt = getPPDekat(15)
    end

    if not prompt then
        notif("Prompt Error", "Tidak ada ProximityPrompt!", 3)
        return false
    end

    firePrompt(prompt)
    task.wait(delayTime)
    return true
end

-- ============================================
-- REMOTE SYSTEM (merged v6+v7)
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
        if r:IsA("RemoteEvent") then
            r:FireServer(...)
            return "Fired"
        else
            return r:InvokeServer(...)
        end
    end, ...)

    return ok, result
end

-- ============================================
-- LAHAN CACHE SYSTEM (v6)
-- ============================================

local function cacheLahans()
    local now = tick()
    if now - lastCacheTime < 5 and #cachedLahans > 0 then
        return cachedLahans
    end

    cachedLahans = {}

    if savedLahanPos then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n = v.Name:lower()
                if n:find("tanah") or n:find("lahan") or n:find("plot") or n:find("sawah") or n:find("farm") then
                    if (v.Position - savedLahanPos).Magnitude <= lahanRadius then
                        table.insert(cachedLahans, v)
                    end
                end
            end
        end
    end

    -- Fallback
    if #cachedLahans == 0 then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v.Name == "Tanah" and v:IsA("BasePart") then
                table.insert(cachedLahans, v)
            end
        end
    end

    lastCacheTime = now
    return cachedLahans
end

local function getAllLahan()
    return cacheLahans()
end

-- ============================================
-- CORE FARM FUNCTIONS (v6 — proximity prompt)
-- ============================================

local function autoBeliBibit()
    if not bukaToko("npcbibit", 1.5) then return false end

    if jumlahBeli > 1 then
        local gui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if gui then
            for _, v in pairs(gui:GetDescendants()) do
                if v:IsA("TextButton") and v.Text == "+" and v.Visible then
                    for i = 1, jumlahBeli - 1 do
                        klikBeli(v)
                        task.wait(0.05)
                    end
                    break
                end
            end
        end
        task.wait(0.2)
    end

    local gui      = LocalPlayer:WaitForChild("PlayerGui", 5)
    local berhasil = false

    if gui then
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and v.Visible then
                local t = v.Text:lower()
                if t:find("beli") or t:find("buy") then
                    klikBeli(v)
                    berhasil = true
                    break
                end
            end
        end
    end

    task.wait(0.3)
    if gui then
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and v.Visible then
                local t = v.Text:lower()
                if t:find("tutup") or t:find("close") then
                    klikBeli(v)
                    break
                end
            end
        end
    end

    return berhasil
end

local function autoJual()
    if not bukaToko("npcpenjual", 1.5) then return false end

    local gui = LocalPlayer:WaitForChild("PlayerGui", 5)
    task.wait(0.3)

    if gui then
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and v.Visible then
                local t = v.Text:lower()
                if (t:find("jual") or t:find("sell")) and not t:find("tutup") then
                    klikBeli(v)
                    task.wait(0.2)
                end
            end
        end
    end

    task.wait(0.3)
    if gui then
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and v.Visible then
                local t = v.Text:lower()
                if t:find("tutup") or t:find("close") then
                    klikBeli(v)
                    break
                end
            end
        end
    end

    return true
end

local function autoPanen()
    local lahans   = getAllLahan()
    local harvested = 0

    for _, lahan in ipairs(lahans) do
        if not _G.AutoPanen and not _G.AutoFarm then break end

        pcall(function()
            tp(lahan)
            task.wait(0.5)

            local prompt = getPPDekat(10)
            if prompt then
                firePrompt(prompt)
                harvested = harvested + 1
            end
        end)

        task.wait(0.3)
    end

    return harvested
end

local function interakLahan(lahanObj, delayTime)
    delayTime = delayTime or 1.5
    if not lahanObj then return false end

    local success = pcall(function()
        tp(lahanObj)
        task.wait(delayTime)

        local prompt = getPPDekat(10)
        if prompt then
            firePrompt(prompt)
        end

        task.wait(0.3)

        local gui = LocalPlayer:WaitForChild("PlayerGui", 3)
        if gui then
            for _, v in pairs(gui:GetDescendants()) do
                if v:IsA("TextButton") and v.Visible then
                    local t = v.Text:lower()
                    if t:find("tanam") or t:find("plant") then
                        klikBeli(v)
                        break
                    end
                end
            end
        end
    end)

    return success
end

-- ============================================
-- ESP SYSTEM (v7)
-- ============================================

local function createESP(obj, color)
    if not obj then return end

    local highlight = Instance.new("Highlight")
    highlight.Name             = "XKIDESP"
    highlight.FillColor        = color or Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor     = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent           = obj

    table.insert(ESPObjects, highlight)
    return highlight
end

local function clearESP()
    for _, esp in pairs(ESPObjects) do
        if esp then pcall(function() esp:Destroy() end) end
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
            end
        end
    end
end

-- ============================================
-- V7 AUTO LOOPS (remote-based — alternative)
-- ============================================

local function teleportPanenLoop()
    local points = {CopyPositions.Sawah, CopyPositions.Sawit, CopyPositions.Ternak}
    local index = 1

    while _G.TeleportPanen do
        local point = points[index]
        if point then
            tp(point)
            task.wait(0.5)
            fireR("HarvestCrop")
            task.wait(Cooldown)
        end

        index = index + 1
        if index > 3 then index = 1 end

        if not _G.TeleportPanen then break end
        task.wait(Jarak)
    end
end

local function detectorSawitLoop()
    while _G.DetectorSawit do
        local sawit = findNearestCrop(100, "sawit") or findNearestCrop(100, "kelapa")

        if sawit then
            notif("Sawit Ditemukan!", "Auto teleport...", 2)
            tp(sawit)
            fireR("HarvestCrop")
            task.wait(Cooldown)
        else
            task.wait(2)
        end

        if not _G.DetectorSawit then break end
    end
end

-- ============================================
-- TAB SETUP
-- ============================================
local TabStatus = Window:CreateTab("📊 Status",       nil)
local TabBibit  = Window:CreateTab("🛒 Beli Bibit",   nil)
local TabFarm   = Window:CreateTab("🤖 Auto Farm",    nil)
local TabCopy   = Window:CreateTab("📋 Copy Pos",     nil)
local TabTanam  = Window:CreateTab("🌴 Tanam",        nil)
local TabTP     = Window:CreateTab("🚀 Teleport",     nil)
local TabLahan  = Window:CreateTab("🌾 Lahan",        nil)
local TabESP    = Window:CreateTab("👁 ESP",          nil)
local TabTools  = Window:CreateTab("🛠 Tools",        nil)
local TabSet    = Window:CreateTab("⚙ Setting",      nil)
local TabTest   = Window:CreateTab("🧪 Test Remote",  nil)

-- ============================================
-- TAB STATUS — Live Monitor (v6)
-- ============================================
TabStatus:CreateSection("📊 Live Status")

local StatusFarm   = TabStatus:CreateParagraph({Title = "Auto Farm",         Content = "Status: OFF"})
local StatusBeli   = TabStatus:CreateParagraph({Title = "Auto Beli",         Content = "Status: OFF"})
local StatusLahan  = TabStatus:CreateParagraph({Title = "Lahan Tersimpan",   Content = "Belum disimpan"})
local StatusCopy   = TabStatus:CreateParagraph({Title = "Copy Positions (3)",Content = "Sawah ❌ | Sawit ❌ | Ternak ❌"})
local StatusSiklus = TabStatus:CreateParagraph({Title = "Siklus Auto Farm",  Content = "0 siklus selesai"})
local StatusESP    = TabStatus:CreateParagraph({Title = "ESP",               Content = "OFF"})

task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            StatusFarm:Set({
                Title   = "Auto Farm",
                Content = _G.AutoFarm and ("🟢 RUNNING (Siklus " .. SiklusCount .. ")") or "🔴 OFF"
            })
            StatusBeli:Set({
                Title   = "Auto Beli",
                Content = (_G.AutoBeli or _G.AutoBuy) and "🟢 RUNNING" or "🔴 OFF"
            })
            if savedLahanPos then
                StatusLahan:Set({
                    Title   = "Lahan Tersimpan",
                    Content = string.format("✅ X=%.1f, Z=%.1f\n📍 %d lahan ditemukan",
                        savedLahanPos.X, savedLahanPos.Z, #getAllLahan())
                })
            else
                StatusLahan:Set({
                    Title   = "Lahan Tersimpan",
                    Content = "❌ Belum disimpan!\nKe tab Lahan > Simpan Posisi"
                })
            end
            StatusCopy:Set({
                Title   = "Copy Positions (3)",
                Content = "Sawah " .. (CopyPositions.Sawah and "✅" or "❌") ..
                          " | Sawit " .. (CopyPositions.Sawit and "✅" or "❌") ..
                          " | Ternak " .. (CopyPositions.Ternak and "✅" or "❌")
            })
            StatusSiklus:Set({
                Title   = "Siklus Auto Farm",
                Content = SiklusCount .. " siklus selesai"
            })
            StatusESP:Set({
                Title   = "ESP",
                Content = _G.ESP and ("🟢 ON — " .. #ESPObjects .. " object") or "🔴 OFF"
            })
        end)
        task.wait(1)
    end
end)

-- ============================================
-- TAB BELI BIBIT (v6)
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
    Name         = "Jumlah Beli",
    Range        = {1, 99},
    Increment    = 1,
    CurrentValue = 1,
    Callback     = function(v) jumlahBeli = v end
})

TabBibit:CreateSection("🛒 Aksi")

TabBibit:CreateButton({
    Name     = "💰 BELI SEKARANG",
    Callback = function()
        task.spawn(function()
            notif("Membeli", jumlahBeli .. "x " .. selectedBibit, 2)
            local ok = autoBeliBibit()
            notif(ok and "Sukses!" or "Gagal", ok and "Pembelian berhasil" or "Coba lagi", 3)
        end)
    end
})

TabBibit:CreateSection("⚡ Beli Cepat")

for _, b in ipairs(BIBIT) do
    TabBibit:CreateButton({
        Name     = b.emoji .. " " .. b.name .. " | " .. b.harga .. "💰",
        Callback = function()
            task.spawn(function()
                selectedBibit = b.name
                autoBeliBibit()
            end)
        end
    })
end

TabBibit:CreateSection("🔄 Auto Beli Loop")

TabBibit:CreateSlider({
    Name         = "Delay Auto Beli (detik)",
    Range        = {2, 30},
    Increment    = 1,
    CurrentValue = 3,
    Callback     = function(v) autoBeliDelay = v end
})

TabBibit:CreateToggle({
    Name         = "Auto Beli Loop",
    CurrentValue = false,
    Callback     = function(v)
        _G.AutoBeli = v
        _G.AutoBuy  = v

        if v then
            notif("Auto Beli", "Loop dimulai", 2)
            task.spawn(function()
                while _G.AutoBeli do
                    pcall(autoBeliBibit)
                    task.wait(autoBeliDelay)
                end
            end)
        else
            notif("Auto Beli", "Stopped", 2)
        end
    end
})

-- ============================================
-- TAB AUTO FARM (v6 full cycle + satuan)
-- ============================================
TabFarm:CreateSection("⏱ Delay Setting")

TabFarm:CreateSlider({
    Name = "Delay Beli (s)", Range = {1, 10}, Increment = 0.5, CurrentValue = 2,
    Callback = function(v) dBeli = v end
})
TabFarm:CreateSlider({
    Name = "Delay Tanam (s)", Range = {1, 10}, Increment = 0.5, CurrentValue = 2,
    Callback = function(v) dTanam = v end
})
TabFarm:CreateSlider({
    Name = "Delay Panen (s)", Range = {1, 10}, Increment = 0.5, CurrentValue = 3,
    Callback = function(v) dPanen = v end
})
TabFarm:CreateSlider({
    Name = "Delay Jual (s)", Range = {1, 10}, Increment = 0.5, CurrentValue = 2,
    Callback = function(v) dJual = v end
})
TabFarm:CreateSlider({
    Name = "Waktu Tunggu Panen (s)", Range = {10, 300}, Increment = 5, CurrentValue = 30,
    Callback = function(v) waitPanen = v end
})

TabFarm:CreateSection("🤖 FULL AUTO FARM")

TabFarm:CreateToggle({
    Name         = "🔥 FULL AUTO: Beli → Tanam → Panen → Jual",
    CurrentValue = false,
    Callback     = function(v)
        _G.AutoFarm = v

        if v then
            if not savedLahanPos then
                notif("ERROR!", "Simpan posisi lahan dulu!", 5)
                _G.AutoFarm = false
                return
            end

            SiklusCount = 0
            notif("AUTO FARM", "Started! Good luck 🍀", 3)

            task.spawn(function()
                while _G.AutoFarm do
                    SiklusCount = SiklusCount + 1

                    -- Step 1: Beli
                    pcall(autoBeliBibit)
                    if not _G.AutoFarm then break end
                    task.wait(dBeli)

                    -- Step 2: Tanam
                    local lahans = getAllLahan()
                    for _, lahan in ipairs(lahans) do
                        if not _G.AutoFarm then break end
                        pcall(function() interakLahan(lahan, dTanam) end)
                        task.wait(0.5)
                    end
                    if not _G.AutoFarm then break end

                    -- Step 3: Tunggu panen
                    notif("Menunggu", "Panen dalam " .. waitPanen .. "s", 3)
                    local waited = 0
                    while waited < waitPanen and _G.AutoFarm do
                        task.wait(1)
                        waited = waited + 1
                    end
                    if not _G.AutoFarm then break end

                    -- Step 4: Panen
                    pcall(autoPanen)
                    if not _G.AutoFarm then break end
                    task.wait(dPanen)

                    -- Step 5: Jual
                    pcall(autoJual)
                    if not _G.AutoFarm then break end
                    task.wait(dJual)

                    notif("Siklus #" .. SiklusCount, "Selesai! Next...", 3)
                    task.wait(2)
                end

                notif("AUTO FARM", "Stopped di siklus " .. SiklusCount, 3)
            end)
        else
            notif("AUTO FARM", "Stopped", 2)
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
                    for _, lahan in ipairs(getAllLahan()) do
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
                    pcall(autoPanen)
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
        _G.AutoSell = v
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

TabFarm:CreateSection("🛑 Emergency Stop")

TabFarm:CreateButton({
    Name     = "🛑 STOP SEMUA AUTO",
    Callback = function()
        _G.AutoFarm      = false
        _G.AutoBeli      = false
        _G.AutoBuy       = false
        _G.AutoTanam     = false
        _G.AutoPanen     = false
        _G.AutoJual      = false
        _G.AutoSell      = false
        _G.TeleportPanen = false
        _G.DetectorSawit = false
        notif("STOP!", "Semua auto dimatikan", 3)
    end
})

-- ============================================
-- TAB COPY POSITION — 3 Titik (v7)
-- ============================================
TabCopy:CreateSection("📍 Simpan 3 Titik")

TabCopy:CreateParagraph({
    Title   = "CARA PAKAI",
    Content = "1. Pergi ke lokasi\n2. Tekan COPY\n3. Posisi tersimpan otomatis\n4. Aktifkan Teleport Panen di Tab Auto Farm"
})

TabCopy:CreateButton({
    Name     = "📍 COPY SAWAH (Posisi 1)",
    Callback = function()
        local pos = getPos()
        if pos then
            CopyPositions.Sawah = pos
            notif("Copy Sawah ✅", string.format("X=%.1f, Z=%.1f", pos.X, pos.Z), 3)
        end
    end
})

TabCopy:CreateButton({
    Name     = "🌴 COPY SAWIT (Posisi 2)",
    Callback = function()
        local pos = getPos()
        if pos then
            CopyPositions.Sawit = pos
            notif("Copy Sawit ✅", string.format("X=%.1f, Z=%.1f", pos.X, pos.Z), 3)
        end
    end
})

TabCopy:CreateButton({
    Name     = "🐄 COPY TERNAK (Posisi 3)",
    Callback = function()
        local pos = getPos()
        if pos then
            CopyPositions.Ternak = pos
            notif("Copy Ternak ✅", string.format("X=%.1f, Z=%.1f", pos.X, pos.Z), 3)
        end
    end
})

TabCopy:CreateButton({
    Name     = "📊 Lihat Posisi Tersimpan",
    Callback = function()
        local msg = ""
        msg = msg .. "Sawah:  " .. (CopyPositions.Sawah  and "✅" or "❌") .. "\n"
        msg = msg .. "Sawit:  " .. (CopyPositions.Sawit  and "✅" or "❌") .. "\n"
        msg = msg .. "Ternak: " .. (CopyPositions.Ternak and "✅" or "❌")
        notif("Status Copy", msg, 5)
    end
})

TabCopy:CreateButton({
    Name     = "🗑 Reset Semua Copy",
    Callback = function()
        CopyPositions.Sawah  = nil
        CopyPositions.Sawit  = nil
        CopyPositions.Ternak = nil
        notif("Reset", "Semua copy positions dihapus", 3)
    end
})

TabCopy:CreateSection("🚀 Teleport Panen 3 Titik")

TabCopy:CreateToggle({
    Name         = "🚀 Teleport Panen (Sawah → Sawit → Ternak)",
    CurrentValue = false,
    Callback     = function(v)
        _G.TeleportPanen = v
        if v then
            if not CopyPositions.Sawah and not CopyPositions.Sawit and not CopyPositions.Ternak then
                notif("ERROR!", "Copy minimal 1 posisi dulu!", 4)
                _G.TeleportPanen = false
                return
            end
            task.spawn(teleportPanenLoop)
            notif("Teleport Panen", "ON", 2)
        else
            notif("Teleport Panen", "OFF", 2)
        end
    end
})

-- ============================================
-- TAB TANAM SAWIT / DURIAN (v7)
-- ============================================
TabTanam:CreateSection("🌴 Tanam Sawit")

TabTanam:CreateButton({
    Name     = "📍 COPY POSISI TANAM SAWIT",
    Callback = function()
        local cf = getCF()
        if cf then
            TanamPositions.Sawit = cf
            notif("Copy Tanam Sawit ✅", "Posisi tersimpan", 3)
        end
    end
})

TabTanam:CreateButton({
    Name     = "🌴 TANAM SAWIT DI SINI",
    Callback = function()
        if TanamPositions.Sawit then
            tp(TanamPositions.Sawit)
            task.wait(0.5)
            fireR("PlantCrop", "Sawit")
            notif("Tanam Sawit", "Berhasil!", 2)
        else
            notif("Error", "Copy posisi dulu!", 3)
        end
    end
})

TabTanam:CreateSection("🥥 Tanam Durian")

TabTanam:CreateButton({
    Name     = "📍 COPY POSISI TANAM DURIAN",
    Callback = function()
        local cf = getCF()
        if cf then
            TanamPositions.Durian = cf
            notif("Copy Tanam Durian ✅", "Posisi tersimpan", 3)
        end
    end
})

TabTanam:CreateButton({
    Name     = "🥥 TANAM DURIAN DI SINI",
    Callback = function()
        if TanamPositions.Durian then
            tp(TanamPositions.Durian)
            task.wait(0.5)
            fireR("PlantCrop", "Durian")
            notif("Tanam Durian", "Berhasil!", 2)
        else
            notif("Error", "Copy posisi dulu!", 3)
        end
    end
})

TabTanam:CreateSection("🔍 Detector Sawit")

TabTanam:CreateToggle({
    Name         = "🔍 Detector Sawit (Auto Scan & Panen)",
    CurrentValue = false,
    Callback     = function(v)
        _G.DetectorSawit = v
        if v then
            task.spawn(detectorSawitLoop)
            notif("Detector Sawit", "ON — Auto cari sawit", 3)
        else
            notif("Detector Sawit", "OFF", 2)
        end
    end
})

-- ============================================
-- TAB TELEPORT (v6 NPC list + kembali lahan)
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
        Name     = npc.label,
        Callback = function()
            local o = cari(npc.name)
            if o then
                tp(o)
                notif("Teleport", npc.label .. " ✓", 2)
            else
                notif("Error", npc.name .. " tidak ada", 3)
            end
        end
    })
end

TabTP:CreateSection("🌾 Ke Lahan Kamu")

TabTP:CreateButton({
    Name     = "🏠 Teleport ke Lahan Tersimpan",
    Callback = function()
        if savedLahanPos then
            tpCoord(savedLahanPos.X, savedLahanPos.Y, savedLahanPos.Z)
            notif("Teleport", "Di lahan kamu!", 2)
        else
            notif("Error", "Simpan posisi lahan dulu!", 3)
        end
    end
})

-- ============================================
-- TAB LAHAN — Scan & Cache (v6)
-- ============================================
TabLahan:CreateSection("📍 Simpan Posisi Lahan")

TabLahan:CreateParagraph({
    Title   = "Cara Simpan",
    Content = "1. Berdiri di TENGAH lahan kamu\n2. Tekan tombol SIMPAN\n3. Auto scan akan mencari lahan di radius tertentu"
})

TabLahan:CreateButton({
    Name     = "💾 SIMPAN POSISI SEKARANG",
    Callback = function()
        local root = getRoot()
        if not root then
            notif("Error", "Karakter belum ready!", 3)
            return
        end

        savedLahanPos = root.Position
        cacheLahans()

        local p = savedLahanPos
        local n = #cachedLahans

        notif("Tersimpan!", string.format("X=%.1f, Z=%.1f\n%d lahan ditemukan", p.X, p.Z, n), 5)
    end
})

TabLahan:CreateButton({
    Name     = "📊 Info Lahan",
    Callback = function()
        if not savedLahanPos then
            notif("Belum Simpan", "Simpan posisi dulu!", 3)
            return
        end

        local p = savedLahanPos
        local n = #getAllLahan()

        notif("Info Lahan", string.format("Posisi: X=%.1f, Z=%.1f\nJumlah lahan: %d\nRadius: %d stud",
            p.X, p.Z, n, lahanRadius), 5)
    end
})

TabLahan:CreateSlider({
    Name         = "Radius Scan (stud)",
    Range        = {10, 200},
    Increment    = 10,
    CurrentValue = 50,
    Callback     = function(v)
        lahanRadius = v
        cacheLahans()
    end
})

TabLahan:CreateButton({
    Name     = "🔄 Refresh Scan",
    Callback = function()
        lastCacheTime = 0
        cacheLahans()
        notif("Refresh", #cachedLahans .. " lahan ditemukan", 3)
    end
})

TabLahan:CreateButton({
    Name     = "🗑 Hapus Posisi Lahan",
    Callback = function()
        savedLahanPos = nil
        cachedLahans  = {}
        notif("Reset", "Posisi lahan dihapus", 2)
    end
})

-- ============================================
-- TAB ESP (v7 — expanded)
-- ============================================
TabESP:CreateSection("👁 ESP System")

TabESP:CreateParagraph({
    Title   = "Info ESP",
    Content = "🟢 Hijau = Tanaman/Crop\n🟡 Kuning = NPC/Toko\n🔵 Biru = Tanah/Lahan"
})

TabESP:CreateToggle({
    Name         = "👁 ESP Aktif",
    CurrentValue = false,
    Callback     = function(v)
        _G.ESP = v
        if v then
            updateESP()
            notif("ESP", "ON — " .. #ESPObjects .. " object", 2)
        else
            clearESP()
            notif("ESP", "OFF", 2)
        end
    end
})

TabESP:CreateButton({
    Name     = "🔄 Refresh ESP",
    Callback = function()
        if _G.ESP then
            updateESP()
            notif("ESP Refresh", #ESPObjects .. " object ditemukan", 3)
        else
            notif("ESP", "Aktifkan ESP dulu!", 3)
        end
    end
})

TabESP:CreateButton({
    Name     = "🗑 Clear ESP",
    Callback = function()
        clearESP()
        _G.ESP = false
        notif("ESP", "Cleared", 2)
    end
})

-- ============================================
-- TAB TOOLS (v6)
-- ============================================
TabTools:CreateSection("📍 Info Posisi")

TabTools:CreateButton({
    Name     = "📍 Koordinat Saya",
    Callback = function()
        local r = getRoot()
        if r then
            local p = r.Position
            notif("Posisi Saya", string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 5)
        end
    end
})

TabTools:CreateButton({
    Name     = "🔄 Respawn Karakter",
    Callback = function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = 0
                notif("Respawn", "Tunggu sebentar...", 2)
            end
        end
    end
})

TabTools:CreateSection("🧪 Quick Test")

TabTools:CreateButton({
    Name     = "Test Buka Toko Bibit",
    Callback = function()
        task.spawn(function()
            local ok = bukaToko("npcbibit", 2)
            notif(ok and "Sukses" or "Gagal", ok and "Toko terbuka" or "Coba lagi", 3)
        end)
    end
})

TabTools:CreateButton({
    Name     = "Test Jual",
    Callback = function()
        task.spawn(function()
            local ok = autoJual()
            notif(ok and "Sukses" or "Gagal", ok and "Terjual" or "Gagal jual", 3)
        end)
    end
})

-- ============================================
-- TAB SETTING (merged v6 + v7)
-- ============================================
TabSet:CreateSection("⏱ Cooldown (v7 mode)")

TabSet:CreateSlider({
    Name         = "Cooldown Remote (detik)",
    Range        = {0.5, 5},
    Increment    = 0.5,
    CurrentValue = 1,
    Callback     = function(v)
        Cooldown = v
        notif("Cooldown", "Set ke " .. v .. "s", 2)
    end
})

TabSet:CreateSection("📏 Jarak Teleport Panen")

TabSet:CreateSlider({
    Name         = "Jarak antar TP (detik)",
    Range        = {1, 10},
    Increment    = 1,
    CurrentValue = 3,
    Callback     = function(v)
        Jarak = v
        notif("Jarak", "Set ke " .. v .. "s", 2)
    end
})

TabSet:CreateSection("🧭 Mode Arah Tanam")

TabSet:CreateToggle({
    Name         = "Mode Depan (ON) / Belakang (OFF)",
    CurrentValue = true,
    Callback     = function(v)
        ModeDepan = v
        notif("Mode", v and "Depan aktif" or "Belakang aktif", 2)
    end
})

TabSet:CreateSection("🛑 Emergency Stop")

TabSet:CreateButton({
    Name     = "🛑 STOP SEMUA AUTO",
    Callback = function()
        _G.AutoFarm      = false
        _G.AutoBeli      = false
        _G.AutoBuy       = false
        _G.AutoTanam     = false
        _G.AutoPanen     = false
        _G.AutoJual      = false
        _G.AutoSell      = false
        _G.TeleportPanen = false
        _G.DetectorSawit = false
        notif("STOP!", "Semua auto dimatikan", 3)
    end
})

-- ============================================
-- TAB TEST REMOTE (v6 — full tester)
-- ============================================
TabTest:CreateSection("🔥 Fire Remote Manual")

TabTest:CreateInput({
    Name                   = "Nama Remote",
    PlaceholderText        = "contoh: PlantCrop",
    RemoveTextAfterFocusLost = false,
    Callback               = function(v) testRemoteName = v end
})

TabTest:CreateInput({
    Name                   = "Argumen 1 (opsional)",
    PlaceholderText        = "string / number / bool",
    RemoveTextAfterFocusLost = false,
    Callback               = function(v) testArg1 = v end
})

TabTest:CreateButton({
    Name     = "🔥 FIRE REMOTE",
    Callback = function()
        if testRemoteName == "" then
            notif("Error", "Masukkan nama remote!", 3)
            return
        end

        local args = {}
        if testArg1 ~= "" then
            local num = tonumber(testArg1)
            if num then
                table.insert(args, num)
            elseif testArg1 == "true" then
                table.insert(args, true)
            elseif testArg1 == "false" then
                table.insert(args, false)
            else
                table.insert(args, testArg1)
            end
        end

        local ok, result = fireR(testRemoteName, table.unpack(args))
        notif(ok and "Sukses" or "Gagal", tostring(result), 4)
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
        Name     = test[2],
        Callback = function()
            local ok, result = fireR(test[1])
            notif(test[1], ok and ("OK: " .. tostring(result)) or ("ERROR: " .. tostring(result)), 3)
        end
    })
end

-- ============================================
-- INIT NOTIFICATIONS
-- ============================================
notif("SAWAH INDO v8.0 ULTIMATE", "Welcome " .. myName .. "! 🌾", 5)
task.wait(1)
notif("Langkah 1", "Tab Lahan → Simpan posisi lahan kamu", 5)
task.wait(1.2)
notif("Langkah 2", "Tab Copy Pos → Copy 3 titik (Sawah/Sawit/Ternak)", 5)
task.wait(1.2)
notif("Langkah 3", "Tab Auto Farm → Aktifkan FULL AUTO 🔥", 5)

print(string.rep("=", 40))
print("  SAWAH INDO v8.0 ULTIMATE — XKID HUB")
print("  Gabungan v6.0 + v7.0 Pro")
print("  Player: " .. myName)
print(string.rep("=", 40))
