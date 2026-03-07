-- 🌾 SAWAH INDO v6.0 ULTIMATE — XKID HUB
-- Support: Android + Delta/Arceus/Fluxus/Fluxus
-- Fix: Full error handling + Live status + Optimized scan

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO v6.0 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "Ultimate Auto Farm 🔥",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local myName = LocalPlayer.Name

-- Status global
_G.AutoFarm = false
_G.AutoBeli = false
_G.AutoTanam = false
_G.AutoJual = false
_G.AutoPanen = false
_G.ScriptRunning = true

-- Data lahan
local savedLahanPos = nil
local lahanRadius = 50
local cachedLahans = {}
local lastCacheTime = 0

-- Notifikasi
local function notif(judul, isi, dur)
    pcall(function()
        Rayfield:Notify({
            Title = judul, 
            Content = isi, 
            Duration = dur or 3, 
            Image = 4483362458
        })
    end)
    print("[XKID] " .. judul .. " - " .. isi)
end

-- Get root part
local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- Teleport to object
local function tp(obj)
    if not obj then return false end
    local root = getRoot()
    if not root then return false end
    
    local pos
    if typeof(obj) == "Vector3" then
        pos = obj
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

-- Teleport to coordinates
local function tpCoord(x, y, z)
    local root = getRoot()
    if not root then return false end
    root.CFrame = CFrame.new(x, y + 5, z)
    task.wait(0.3)
    return true
end

-- Find object by name
local function cari(nama)
    nama = nama:lower()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower() == nama then return v end
    end
    return nil
end

-- Cache lahan untuk performa
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

-- Get all lahan (with cache)
local function getAllLahan()
    return cacheLahans()
end

-- Click UI button
local function klikBeli(tombol)
    if not tombol then return false end
    
    pcall(function()
        -- Method 1: Fire click
        if tombol:IsA("GuiButton") then
            tombol.MouseButton1Click:Fire()
        end
    end)
    
    task.wait(0.05)
    
    -- Method 2: Virtual input
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        local pos = tombol.AbsolutePosition + (tombol.AbsoluteSize / 2)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    
    task.wait(0.1)
    return true
end

-- Get nearby proximity prompt
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

-- Fire proximity prompt
local function firePrompt(prompt)
    if not prompt then return end
    
    pcall(function()
        fireproximityprompt(prompt)
    end)
    
    task.wait(0.1)
    
    -- Backup: Key press E
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- Open NPC shop
local function bukaToko(npcName, delayTime)
    delayTime = delayTime or 1.5
    
    local npc = cari(npcName)
    if not npc then
        notif("NPC Error", npcName .. " tidak ditemukan!", 3)
        return false
    end
    
    tp(npc)
    task.wait(0.8)
    
    -- Find prompt
    local prompt = nil
    local searchIn = npc:IsA("Model") and npc or npc.Parent
    
    for _, v in pairs(searchIn:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            prompt = v
            break
        end
    end
    
    -- Fallback: nearby search
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

-- Auto buy bibit
local selectedBibit = "Padi"
local jumlahBeli = 1

local function autoBeliBibit()
    if not bukaToko("npcbibit", 1.5) then return false end
    
    -- Adjust quantity
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
    
    -- Click buy
    local gui = LocalPlayer:WaitForChild("PlayerGui", 5)
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
    
    -- Close shop
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

-- Auto sell
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
    
    -- Close
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

-- Auto harvest
local function autoPanen()
    local lahans = getAllLahan()
    local harvested = 0
    
    for _, lahan in ipairs(lahans) do
        if not _G.AutoPanen and not _G.AutoFarm then break end
        
        local success = pcall(function()
            tp(lahan)
            task.wait(0.5)
            
            local prompt = getPPDekat(10)
            if prompt then
                firePrompt(prompt)
                harvested = harvested + 1
            end
        end)
        
        if not success then
            warn("Error panen: " .. tostring(lahan))
        end
        
        task.wait(0.3)
    end
    
    return harvested
end

-- Interact with lahan (plant)
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
        
        -- Click plant button
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

-- Remote system
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

-- Bibit data
local BIBIT = {
    {name = "Padi", emoji = "🌾", minLv = 1, harga = 5},
    {name = "Jagung", emoji = "🌽", minLv = 20, harga = 15},
    {name = "Tomat", emoji = "🍅", minLv = 40, harga = 25},
    {name = "Terong", emoji = "🍆", minLv = 60, harga = 40},
    {name = "Strawberry", emoji = "🍓", minLv = 80, harga = 60},
    {name = "Sawit", emoji = "🌴", minLv = 80, harga = 1000},
    {name = "Durian", emoji = "🥥", minLv = 120, harga = 2000},
}

-- ============================================
-- GUI SETUP
-- ============================================
local TabStatus = Window:CreateTab("📊 Status", nil)
local TabBibit = Window:CreateTab("🛒 Beli Bibit", nil)
local TabFarm = Window:CreateTab("🤖 Auto Farm", nil)
local TabTP = Window:CreateTab("🚀 Teleport", nil)
local TabLahan = Window:CreateTab("🌾 Lahan", nil)
local TabTools = Window:CreateTab("🛠 Tools", nil)
local TabTest = Window:CreateTab("🧪 Test Remote", nil)

-- Status variables
local StatusLabels = {}
local SiklusCount = 0

-- Live status update
TabStatus:CreateSection("📊 Live Status")

local StatusFarm = TabStatus:CreateParagraph({
    Title = "Auto Farm",
    Content = "Status: OFF"
})

local StatusBeli = TabStatus:CreateParagraph({
    Title = "Auto Beli",
    Content = "Status: OFF"
})

local StatusLahan = TabStatus:CreateParagraph({
    Title = "Lahan Tersimpan",
    Content = "Belum disimpan"
})

local StatusSiklus = TabStatus:CreateParagraph({
    Title = "Siklus Auto Farm",
    Content = "0 siklus selesai"
})

-- Update status loop
task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            StatusFarm:Set({
                Title = "Auto Farm",
                Content = _G.AutoFarm and "🟢 RUNNING (Siklus " .. SiklusCount .. ")" or "🔴 OFF"
            })
            
            StatusBeli:Set({
                Title = "Auto Beli",
                Content = _G.AutoBeli and "🟢 RUNNING" or "🔴 OFF"
            })
            
            if savedLahanPos then
                StatusLahan:Set({
                    Title = "Lahan Tersimpan",
                    Content = string.format("✅ X=%.1f, Z=%.1f\n📍 %d lahan ditemukan", 
                        savedLahanPos.X, savedLahanPos.Z, #getAllLahan())
                })
            else
                StatusLahan:Set({
                    Title = "Lahan Tersimpan",
                    Content = "❌ Belum disimpan!\nKe tab Lahan > Simpan Posisi"
                })
            end
            
            StatusSiklus:Set({
                Title = "Siklus Auto Farm",
                Content = SiklusCount .. " siklus selesai"
            })
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
    Name = "Jenis Bibit",
    Options = opsiBibit,
    CurrentOption = {opsiBibit[1]},
    Callback = function(v)
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
    Name = "Jumlah Beli",
    Range = {1, 99},
    Increment = 1,
    CurrentValue = 1,
    Callback = function(v)
        jumlahBeli = v
    end
})

TabBibit:CreateSection("🛒 Aksi")

TabBibit:CreateButton({
    Name = "💰 BELI SEKARANG",
    Callback = function()
        task.spawn(function()
            notif("Membeli", jumlahBeli .. "x " .. selectedBibit, 2)
            local ok = autoBeliBibit()
            notif(ok and "Sukses!" or "Gagal", ok and "Pembelian berhasil" or "Coba lagi", 3)
        end)
    end
})

-- Quick buy buttons
TabBibit:CreateSection("⚡ Beli Cepat")

for _, b in ipairs(BIBIT) do
    TabBibit:CreateButton({
        Name = b.emoji .. " " .. b.name .. " | " .. b.harga .. "💰",
        Callback = function()
            task.spawn(function()
                selectedBibit = b.name
                autoBeliBibit()
            end)
        end
    })
end

-- Auto buy toggle
TabBibit:CreateSection("🔄 Auto Beli")

local autoBeliDelay = 3

TabBibit:CreateSlider({
    Name = "Delay (detik)",
    Range = {2, 30},
    Increment = 1,
    CurrentValue = 3,
    Callback = function(v)
        autoBeliDelay = v
    end
})

TabBibit:CreateToggle({
    Name = "Auto Beli Loop",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoBeli = v
        
        if v then
            notif("Auto Beli", "Loop started", 2)
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
-- TAB AUTO FARM
-- ============================================
TabFarm:CreateSection("⏱ Setting Delay")

local dBeli = 2
local dTanam = 2
local dPanen = 3
local dJual = 2
local waitPanen = 30

TabFarm:CreateSlider({
    Name = "Delay Beli (s)",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = 2,
    Callback = function(v) dBeli = v end
})

TabFarm:CreateSlider({
    Name = "Delay Tanam (s)",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = 2,
    Callback = function(v) dTanam = v end
})

TabFarm:CreateSlider({
    Name = "Delay Panen (s)",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = 3,
    Callback = function(v) dPanen = v end
})

TabFarm:CreateSlider({
    Name = "Delay Jual (s)",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = 2,
    Callback = function(v) dJual = v end
})

TabFarm:CreateSlider({
    Name = "Waktu Tunggu Panen (s)",
    Range = {10, 300},
    Increment = 5,
    CurrentValue = 30,
    Callback = function(v) waitPanen = v end
})

TabFarm:CreateSection("🤖 Auto Farm Utama")

TabFarm:CreateToggle({
    Name = "🔥 FULL AUTO: Beli > Tanam > Panen > Jual",
    CurrentValue = false,
    Callback = function(v)
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
                    local step = 0
                    
                    -- Step 1: Beli
                    step = 1
                    pcall(autoBeliBibit)
                    if not _G.AutoFarm then break end
                    task.wait(dBeli)
                    
                    -- Step 2: Tanam
                    step = 2
                    local lahans = getAllLahan()
                    for _, lahan in ipairs(lahans) do
                        if not _G.AutoFarm then break end
                        pcall(function()
                            interakLahan(lahan, dTanam)
                        end)
                        task.wait(0.5)
                    end
                    if not _G.AutoFarm then break end
                    
                    -- Step 3: Tunggu panen
                    step = 3
                    notif("Menunggu", "Panen dalam " .. waitPanen .. "s", 3)
                    
                    local waited = 0
                    while waited < waitPanen and _G.AutoFarm do
                        task.wait(1)
                        waited = waited + 1
                    end
                    if not _G.AutoFarm then break end
                    
                    -- Step 4: Panen
                    step = 4
                    pcall(autoPanen)
                    if not _G.AutoFarm then break end
                    task.wait(dPanen)
                    
                    -- Step 5: Jual
                    step = 5
                    pcall(autoJual)
                    if not _G.AutoFarm then break end
                    task.wait(dJual)
                    
                    notif("Siklus #" .. SiklusCount, "Selesai! Next...", 3)
                    task.wait(2)
                end
                
                notif("AUTO FARM", "Stopped at siklus " .. SiklusCount, 3)
            end)
        else
            notif("AUTO FARM", "Stopped", 2)
        end
    end
})

TabFarm:CreateSection("🎯 Auto Satuan")

TabFarm:CreateToggle({
    Name = "Auto Tanam Saja",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoTanam = v
        if v then
            task.spawn(function()
                while _G.AutoTanam do
                    for _, lahan in ipairs(getAllLahan()) do
                        if not _G.AutoTanam then break end
                        pcall(function()
                            interakLahan(lahan, dTanam)
                        end)
                        task.wait(0.5)
                    end
                    task.wait(3)
                end
            end)
        end
    end
})

TabFarm:CreateToggle({
    Name = "Auto Panen Saja",
    CurrentValue = false,
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
    Name = "Auto Jual Saja",
    CurrentValue = false,
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

TabFarm:CreateSection("🛑 Emergency Stop")

TabFarm:CreateButton({
    Name = "🛑 STOP SEMUA AUTO",
    Callback = function()
        _G.AutoFarm = false
        _G.AutoBeli = false
        _G.AutoTanam = false
        _G.AutoPanen = false
        _G.AutoJual = false
        notif("STOP!", "Semua auto dimatikan", 3)
    end
})

-- ============================================
-- TAB TELEPORT
-- ============================================
TabTP:CreateSection("🏪 NPC Toko")

local npcList = {
    {name = "npcbibit", label = "🌱 Beli Bibit"},
    {name = "npcpenjual", label = "💰 Jual Hasil"},
    {name = "npcalat", label = "🔧 Beli Alat"},
    {name = "NPCPedagangTelur", label = "🥚 Jual Telur"},
    {name = "NPCPedagangSawit", label = "🌴 Jual Sawit"},
}

for _, npc in ipairs(npcList) do
    TabTP:CreateButton({
        Name = npc.label,
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
    Name = "🏠 Teleport ke Lahan",
    Callback = function()
        if savedLahanPos then
            tpCoord(savedLahanPos.X, savedLahanPos.Y, savedLahanPos.Z)
            notif("Teleport", "Di lahan kamu!", 2)
        else
            notif("Error", "Simpan posisi dulu!", 3)
        end
    end
})

-- ============================================
-- TAB LAHAN
-- ============================================
TabLahan:CreateSection("📍 Simpan Posisi Lahan")

TabLahan:CreateParagraph({
    Title = "Cara Simpan",
    Content = "1. Berdiri di TENGAH lahan kamu\n2. Tekan tombol SIMPAN di bawah\n3. Auto scan akan mencari lahan di radius tertentu"
})

TabLahan:CreateButton({
    Name = "💾 SIMPAN POSISI SEKARANG",
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
    Name = "📊 Info Lahan",
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
    Name = "Radius Scan (stud)",
    Range = {10, 200},
    Increment = 10,
    CurrentValue = 50,
    Callback = function(v)
        lahanRadius = v
        cacheLahans()
    end
})

TabLahan:CreateButton({
    Name = "🔄 Refresh Scan",
    Callback = function()
        cacheLahans()
        notif("Refresh", #cachedLahans .. " lahan ditemukan", 3)
    end
})

TabLahan:CreateButton({
    Name = "🗑 Hapus Posisi",
    Callback = function()
        savedLahanPos = nil
        cachedLahans = {}
        notif("Reset", "Posisi dihapus", 2)
    end
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
            notif("Posisi", string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 5)
        end
    end
})

TabTools:CreateButton({
    Name = "🔄 Respawn",
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

TabTools:CreateSection("🧪 Test")

TabTools:CreateButton({
    Name = "Test Buka Toko Bibit",
    Callback = function()
        task.spawn(function()
            local ok = bukaToko("npcbibit", 2)
            notif(ok and "Sukses" or "Gagal", ok and "Toko terbuka" or "Coba lagi", 3)
        end)
    end
})

TabTools:CreateButton({
    Name = "Test Jual",
    Callback = function()
        task.spawn(function()
            local ok = autoJual()
            notif(ok and "Sukses" or "Gagal", ok and "Terjual" or "Gagal jual", 3)
        end)
    end
})

-- ============================================
-- TAB TEST REMOTE
-- ============================================
TabTest:CreateSection("🔥 Fire Remote")

local testRemoteName = ""
local testArg1 = ""
local testArg2 = ""

TabTest:CreateInput({
    Name = "Nama Remote",
    PlaceholderText = "contoh: PlantCrop",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        testRemoteName = v
    end
})

TabTest:CreateInput({
    Name = "Argumen 1 (opsional)",
    PlaceholderText = "string/number/bool",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        testArg1 = v
    end
})

TabTest:CreateButton({
    Name = "🔥 FIRE REMOTE",
    Callback = function()
        if testRemoteName == "" then
            notif("Error", "Masukkan nama remote!", 3)
            return
        end
        
        -- Parse args
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
        
        local ok, result = fireR(testRemoteName, unpack(args))
        notif(ok and "Sukses" or "Gagal", tostring(result), 4)
    end
})

-- Quick test buttons
TabTest:CreateSection("⚡ Quick Test")

local quickTests = {
    {"PlantCrop", "🌱 PlantCrop"},
    {"HarvestCrop", "🌿 HarvestCrop"},
    {"SellCrop", "💰 SellCrop"},
    {"GetBibit", "🛒 GetBibit"},
    {"RequestLahan", "🌾 RequestLahan"},
}

for _, test in ipairs(quickTests) do
    TabTest:CreateButton({
        Name = test[2],
        Callback = function()
            local ok, result = fireR(test[1])
            notif(test[1], ok and "OK: " .. tostring(result) or "ERROR: " .. tostring(result), 3)
        end
    })
end

-- ============================================
-- INIT
-- ============================================
notif("SAWAH INDO v6.0", "Welcome " .. myName .. "! 🌾", 5)
task.wait(1)
notif("Langkah Pertama", "Ke tab Lahan > Simpan Posisi!", 6)

print("=" .. string.rep("=", 30))
print("SAWAH INDO v6.0 ULTIMATE")
print("by XKID HUB")
print("=" .. string.rep("=", 30))
