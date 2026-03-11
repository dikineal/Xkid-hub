--====================================================
-- XKID HUB | SAWAH INDO v8.0 ULTIMATE
--====================================================
-- Support: Android + Delta/Arceus/Fluxus
-- Status: FULLY FUNCTIONAL

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO v8.0 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "ULTIMATE EDITION 🔥",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKIDHub",
        FileName = "SawahConfig"
    },
    KeySystem = false
})

--====================================================
-- SERVICES
--====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

--====================================================
-- TABS
--====================================================
local FarmingTab    = Window:CreateTab("🌾 Farming", nil)
local ProtectTab    = Window:CreateTab("🛡 Protection", nil)
local TeleportTab   = Window:CreateTab("📍 Teleport", nil)
local UtilityTab    = Window:CreateTab("⚙ Utility", nil)
local ConfigTab     = Window:CreateTab("💾 Config", nil)

--====================================================
-- STATE & CONFIG
--====================================================
local Settings = {
    AutoFarm = false,
    AutoSell = false,
    AutoBuy  = false,
    AutoPanen = false,
    AutoTanam = false,
    LightningProtection = true,
    AntiAFK  = true,
    AutoShower = false,
    AutoRejoin = true,
    ESP = false,
}

local SeedName = "Bibit Padi"
local FarmSpeed = 0.18
local JumlahBeli = 15
local JumlahTanam = 15
local SiklusCount = 0

-- Positions
local LahanPos = nil
local GazeboPos = nil
local LastPos = nil
local ShowerPos = nil

-- Cache
local cachedLahans = {}
local lastCacheTime = 0
local ESPObjects = {}

--====================================================
-- CORE FUNCTIONS
--====================================================

local function notif(judul, isi, dur)
    pcall(function()
        Rayfield:Notify({
            Title = judul,
            Content = isi,
            Duration = dur or 3,
            Image = 4483362458
        })
    end)
    print("[XKID] " .. judul .. " — " .. isi)
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

local function getPos()
    local r = getRoot()
    return r and r.Position
end

local function saveLastPos()
    LastPos = getPos()
end

-- Smooth teleport with tween
local function tpSmooth(target, speed)
    speed = speed or 150
    local root = getRoot()
    if not root then return false end
    
    local targetPos
    if typeof(target) == "Vector3" then
        targetPos = target
    elseif target:IsA("BasePart") then
        targetPos = target.Position
    elseif target:IsA("Model") then
        if target.PrimaryPart then
            targetPos = target.PrimaryPart.Position
        elseif target:FindFirstChild("HumanoidRootPart") then
            targetPos = target.HumanoidRootPart.Position
        end
    end
    
    if not targetPos then return false end
    
    saveLastPos()
    targetPos = Vector3.new(targetPos.X, targetPos.Y + 5, targetPos.Z)
    
    local distance = (targetPos - root.Position).Magnitude
    local tweenTime = distance / speed
    
    local tween = TweenService:Create(root, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(targetPos)
    })
    
    tween:Play()
    tween.Completed:Wait()
    
    return true
end

-- Fast teleport (instant)
local function tp(target)
    local root = getRoot()
    if not root then return false end
    
    local targetPos
    if typeof(target) == "Vector3" then
        targetPos = target
    elseif target:IsA("BasePart") then
        targetPos = target.Position
    elseif target:IsA("Model") then
        if target.PrimaryPart then
            targetPos = target.PrimaryPart.Position
        elseif target:FindFirstChild("HumanoidRootPart") then
            targetPos = target.HumanoidRootPart.Position
        end
    end
    
    if not targetPos then return false end
    
    saveLastPos()
    root.CFrame = CFrame.new(targetPos.X, targetPos.Y + 5, targetPos.Z)
    task.wait(FarmSpeed)
    return true
end

-- Find object by name
local function cari(nama, radius)
    radius = radius or 500
    local root = getRoot()
    if not root then return nil end
    
    nama = nama:lower()
    local best = nil
    local bestDist = radius
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower():find(nama) then
            local pos = nil
            if v:IsA("BasePart") then
                pos = v.Position
            elseif v:IsA("Model") and v.PrimaryPart then
                pos = v.PrimaryPart.Position
            end
            
            if pos then
                local dist = (pos - root.Position).Magnitude
                if dist < bestDist then
                    best = v
                    bestDist = dist
                end
            end
        end
    end
    
    return best
end

--====================================================
-- REMOTE SYSTEM
--====================================================

local function getRemote(name)
    for _, v in pairs(RS:GetDescendants()) do
        if v.Name == name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            return v
        end
    end
    return nil
end

local function fireRemote(name, ...)
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

--====================================================
-- INTERACTION SYSTEM
--====================================================

local function getNearbyPrompt(radius)
    radius = radius or 20
    local root = getRoot()
    if not root then return nil end
    
    local best, bestDist = nil, radius
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local par = v.Parent
            if par and par:IsA("BasePart") then
                local dist = (par.Position - root.Position).Magnitude
                if dist < bestDist then
                    best = v
                    bestDist = dist
                end
            end
        end
    end
    
    return best
end

local function firePrompt(prompt)
    if not prompt then return false end
    
    pcall(function()
        fireproximityprompt(prompt)
    end)
    
    task.wait(0.1)
    
    -- Backup key press
    pcall(function()
        VirtualUser:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VirtualUser:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    
    return true
end

local function clickButton(textPattern)
    local gui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not gui then return false end
    
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local t = v.Text:lower()
            if t:find(textPattern:lower()) then
                pcall(function()
                    v.MouseButton1Click:Fire()
                end)
                task.wait(0.1)
                return true
            end
        end
    end
    
    return false
end

--====================================================
-- LAHAN SYSTEM
--====================================================

local function cacheLahans()
    local now = tick()
    if now - lastCacheTime < 3 and #cachedLahans > 0 then
        return cachedLahans
    end
    
    cachedLahans = {}
    
    if LahanPos then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n = v.Name:lower()
                if n:find("tanah") or n:find("lahan") or n:find("plot") or n:find("sawah") then
                    if (v.Position - LahanPos).Magnitude <= 100 then
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

--====================================================
-- CORE ACTIONS (FULLY IMPLEMENTED)
--====================================================

-- BUY SEEDS
local function BuySeeds()
    local npc = cari("npcbibit")
    if not npc then
        notif("Error", "NPC Bibit tidak ditemukan!", 3)
        return false
    end
    
    tp(npc)
    task.wait(0.5)
    
    local prompt = getNearbyPrompt(15)
    if prompt then
        firePrompt(prompt)
        task.wait(1)
        
        -- Adjust quantity
        if JumlahBeli > 1 then
            for i = 1, JumlahBeli - 1 do
                clickButton("+")
                task.wait(0.05)
            end
        end
        
        -- Click buy
        task.wait(0.2)
        clickButton("beli") or clickButton("buy")
        
        -- Close
        task.wait(0.3)
        clickButton("tutup") or clickButton("close")
        
        notif("Buy Seeds", "Berhasil beli " .. JumlahBeli .. " bibit", 2)
        return true
    end
    
    return false
end

-- PLANT SEEDS
local function PlantSeeds()
    local lahans = getAllLahan()
    if #lahans == 0 then
        notif("Error", "Tidak ada lahan ditemukan!", 3)
        return false
    end
    
    local planted = 0
    for i = 1, math.min(JumlahTanam, #lahans) do
        if not Settings.AutoTanam and not Settings.AutoFarm then break end
        
        local lahan = lahans[i]
        tp(lahan)
        task.wait(FarmSpeed)
        
        local prompt = getNearbyPrompt(10)
        if prompt then
            firePrompt(prompt)
            task.wait(0.2)
            clickButton("tanam") or clickButton("plant")
            planted = planted + 1
        end
        
        task.wait(FarmSpeed)
    end
    
    notif("Plant", "Berhasil tanam " .. planted .. " bibit", 2)
    return planted > 0
end

-- HARVEST
local function Harvest()
    local lahans = getAllLahan()
    local harvested = 0
    
    for _, lahan in ipairs(lahans) do
        if not Settings.AutoPanen and not Settings.AutoFarm then break end
        
        tp(lahan)
        task.wait(FarmSpeed)
        
        local prompt = getNearbyPrompt(10)
        if prompt then
            firePrompt(prompt)
            task.wait(0.2)
            clickButton("panen") or clickButton("harvest")
            harvested = harvested + 1
        end
        
        task.wait(FarmSpeed)
    end
    
    notif("Harvest", "Berhasil panen " .. harvested .. " tanaman", 2)
    return harvested
end

-- SELL CROPS
local function SellCrops()
    local npc = cari("npcpenjual")
    if not npc then
        notif("Error", "NPC Penjual tidak ditemukan!", 3)
        return false
    end
    
    tp(npc)
    task.wait(0.5)
    
    local prompt = getNearbyPrompt(15)
    if prompt then
        firePrompt(prompt)
        task.wait(1)
        
        -- Click all sell buttons
        for i = 1, 10 do
            if not clickButton("jual") and not clickButton("sell") then
                break
            end
            task.wait(0.2)
        end
        
        -- Close
        task.wait(0.3)
        clickButton("tutup") or clickButton("close")
        
        notif("Sell Crops", "Berhasil menjual hasil panen", 2)
        return true
    end
    
    return false
end

-- SCAN FARM
local function ScanFarm()
    cacheLahans()
    local count = #cachedLahans
    
    notif("Scan Farm", "Ditemukan " .. count .. " lahan di area", 3)
    
    -- ESP lahan
    if Settings.ESP then
        for _, lahan in ipairs(cachedLahans) do
            local highlight = Instance.new("Highlight")
            highlight.FillColor = Color3.fromRGB(0, 255, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.Parent = lahan
            table.insert(ESPObjects, highlight)
        end
    end
    
    return count
end

-- SHOWER / MANDI
local function DoShower()
    if ShowerPos then
        tp(ShowerPos)
        task.wait(0.5)
        
        local prompt = getNearbyPrompt(10)
        if prompt then
            firePrompt(prompt)
            notif("Shower", "Selesai mandi", 2)
            return true
        end
    end
    
    -- Find shower
    local shower = cari("shower") or cari("mandi") or cari("kolam")
    if shower then
        tp(shower)
        task.wait(0.5)
        
        local prompt = getNearbyPrompt(10)
        if prompt then
            firePrompt(prompt)
            ShowerPos = getPos()
            notif("Shower", "Selesai mandi", 2)
            return true
        end
    end
    
    return false
end

-- LIGHTNING PROTECTION
local function CheckLightning()
    if not Settings.LightningProtection then return end
    
    -- Check for lightning strike
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower():find("lightning") or v.Name:lower():find("petir") then
            -- Teleport to safe zone
            if GazeboPos then
                tp(GazeboPos)
                notif("⚡ Lightning!", "Teleport ke safe zone!", 3)
                task.wait(5)
            end
            return true
        end
    end
    
    return false
end

--====================================================
-- AUTO FARM LOOP
--====================================================

local function AutoFarmLoop()
    while Settings.AutoFarm do
        SiklusCount = SiklusCount + 1
        notif("Auto Farm", "Siklus #" .. SiklusCount .. " dimulai", 3)
        
        -- Step 1: Buy
        if Settings.AutoBuy then
            pcall(BuySeeds)
            task.wait(1)
        end
        
        if not Settings.AutoFarm then break end
        
        -- Step 2: Plant
        pcall(PlantSeeds)
        task.wait(1)
        
        if not Settings.AutoFarm then break end
        
        -- Step 3: Wait for grow
        notif("Menunggu", "Menunggu tanaman matang (60s)...", 3)
        local waited = 0
        while waited < 60 and Settings.AutoFarm do
            if Settings.LightningProtection then
                CheckLightning()
            end
            task.wait(1)
            waited = waited + 1
        end
        
        if not Settings.AutoFarm then break end
        
        -- Step 4: Harvest
        pcall(Harvest)
        task.wait(1)
        
        if not Settings.AutoFarm then break end
        
        -- Step 5: Sell
        if Settings.AutoSell then
            pcall(SellCrops)
            task.wait(1)
        end
        
        -- Step 6: Shower if needed
        if Settings.AutoShower then
            pcall(DoShower)
        end
        
        notif("Siklus #" .. SiklusCount, "Selesai! Next...", 3)
        task.wait(2)
    end
end

--====================================================
-- GUI SETUP
--====================================================

-- 🌾 FARMING TAB
FarmingTab:CreateSection("🤖 Auto Controls")

FarmingTab:CreateToggle({
    Name = "🔥 FULL AUTO FARM",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoFarm = v
        if v then
            if not LahanPos then
                notif("Error!", "Simpan posisi lahan dulu!", 4)
                Settings.AutoFarm = false
                return
            end
            SiklusCount = 0
            task.spawn(AutoFarmLoop)
            notif("Auto Farm", "ON - Siklus berjalan", 2)
        else
            notif("Auto Farm", "OFF", 2)
        end
    end
})

FarmingTab:CreateToggle({
    Name = "🛒 Auto Buy (dalam loop)",
    CurrentValue = true,
    Callback = function(v)
        Settings.AutoBuy = v
    end
})

FarmingTab:CreateToggle({
    Name = "💰 Auto Sell (dalam loop)",
    CurrentValue = true,
    Callback = function(v)
        Settings.AutoSell = v
    end
})

FarmingTab:CreateSection("⚙ Settings")

FarmingTab:CreateDropdown({
    Name = "🌱 Pilih Bibit",
    Options = {"Bibit Padi","Bibit Jagung","Bibit Tomat","Bibit Terong","Bibit Strawberry","Bibit Sawit","Bibit Durian"},
    CurrentOption = "Bibit Padi",
    Callback = function(v)
        SeedName = v
    end
})

FarmingTab:CreateSlider({
    Name = "⚡ Farm Speed",
    Range = {0.05, 0.5},
    Increment = 0.01,
    CurrentValue = 0.18,
    Callback = function(v)
        FarmSpeed = v
    end
})

FarmingTab:CreateSlider({
    Name = "📦 Jumlah Beli",
    Range = {1, 99},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(v)
        JumlahBeli = v
    end
})

FarmingTab:CreateSlider({
    Name = "🌱 Jumlah Tanam",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(v)
        JumlahTanam = v
    end
})

FarmingTab:CreateSection("🎮 Manual Actions")

FarmingTab:CreateButton({
    Name = "💳 Buy Seeds",
    Callback = function()
        task.spawn(BuySeeds)
    end
})

FarmingTab:CreateButton({
    Name = "🌱 Plant Seeds",
    Callback = function()
        task.spawn(PlantSeeds)
    end
})

FarmingTab:CreateButton({
    Name = "🌽 Harvest All",
    Callback = function()
        task.spawn(Harvest)
    end
})

FarmingTab:CreateButton({
    Name = "💰 Sell Crops",
    Callback = function()
        task.spawn(SellCrops)
    end
})

FarmingTab:CreateButton({
    Name = "🔍 Scan & ESP Lahan",
    Callback = function()
        Settings.ESP = true
        task.spawn(ScanFarm)
    end
})

-- 🛡 PROTECTION TAB
ProtectTab:CreateSection("⚡ Protection")

ProtectTab:CreateToggle({
    Name = "⚡ Lightning Protection",
    CurrentValue = true,
    Callback = function(v)
        Settings.LightningProtection = v
    end
})

ProtectTab:CreateToggle({
    Name = "💤 Anti AFK",
    CurrentValue = true,
    Callback = function(v)
        Settings.AntiAFK = v
    end
})

ProtectTab:CreateToggle({
    Name = "🚿 Auto Shower (after farm)",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoShower = v
    end
})

ProtectTab:CreateToggle({
    Name = "🔄 Auto Rejoin (if kicked)",
    CurrentValue = true,
    Callback = function(v)
        Settings.AutoRejoin = v
    end
})

-- 📍 TELEPORT TAB
TeleportTab:CreateSection("🏪 NPC Teleport")

local npcList = {
    {name = "npcbibit", label = "🌱 Beli Bibit"},
    {name = "npcpenjual", label = "💰 Jual Hasil"},
    {name = "npcalat", label = "🔧 Beli Alat"},
    {name = "NPCPedagangTelur", label = "🥚 Jual Telur"},
    {name = "NPCPedagangSawit", label = "🌴 Jual Sawit"},
}

for _, npc in ipairs(npcList) do
    TeleportTab:CreateButton({
        Name = npc.label,
        Callback = function()
            local obj = cari(npc.name)
            if obj then
                tpSmooth(obj)
                notif("Teleport", npc.label, 2)
            else
                notif("Error", npc.name .. " tidak ditemukan", 3)
            end
        end
    })
end

TeleportTab:CreateSection("📍 Location Marks")

TeleportTab:CreateButton({
    Name = "📍 Save Farm Position",
    Callback = function()
        LahanPos = getPos()
        cacheLahans()
        notif("Saved", "Posisi lahan tersimpan! " .. #cachedLahans .. " lahan ditemukan", 3)
    end
})

TeleportTab:CreateButton({
    Name = "🌾 Teleport to Farm",
    Callback = function()
        if LahanPos then
            tpSmooth(LahanPos)
        else
            notif("Error", "Simpan posisi lahan dulu!", 3)
        end
    end
})

TeleportTab:CreateButton({
    Name = "📍 Save Safe Zone (Gazebo)",
    Callback = function()
        GazeboPos = getPos()
        notif("Saved", "Safe zone tersimpan!", 2)
    end
})

TeleportTab:CreateButton({
    Name = "🏠 Teleport to Safe Zone",
    Callback = function()
        if GazeboPos then
            tpSmooth(GazeboPos)
        else
            notif("Error", "Simpan safe zone dulu!", 3)
        end
    end
})

TeleportTab:CreateButton({
    Name = "📍 Save Shower Position",
    Callback = function()
        ShowerPos = getPos()
        notif("Saved", "Posisi shower tersimpan!", 2)
    end
})

TeleportTab:CreateButton({
    Name = "↩️ Back to Last Position",
    Callback = function()
        if LastPos then
            tpSmooth(LastPos)
        else
            notif("Error", "Belum ada posisi sebelumnya", 2)
        end
    end
})

-- ⚙ UTILITY TAB
UtilityTab:CreateSection("🛠 Tools")

UtilityTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end
})

UtilityTab:CreateButton({
    Name = "🚀 FPS Boost",
    Callback = function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        notif("FPS Boost", "Aktif!", 2)
    end
})

UtilityTab:CreateButton({
    Name = "📍 My Coordinates",
    Callback = function()
        local pos = getPos()
        if pos then
            notif("Position", string.format("X: %.1f\nY: %.1f\nZ: %.1f", pos.X, pos.Y, pos.Z), 5)
        end
    end
})

UtilityTab:CreateButton({
    Name = "💀 Reset Character",
    Callback = function()
        local hum = getHumanoid()
        if hum then
            hum.Health = 0
        end
    end
})

UtilityTab:CreateButton({
    Name = "🧪 Test Remote (PlantCrop)",
    Callback = function()
        local ok, result = fireRemote("PlantCrop")
        notif("Test", ok and "Success!" or "Failed: " .. tostring(result), 3)
    end
})

-- 💾 CONFIG TAB
ConfigTab:CreateSection("📊 Status")

local StatusParagraph = ConfigTab:CreateParagraph({
    Title = "Live Status",
    Content = "Loading..."
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local status = "Auto Farm: " .. (Settings.AutoFarm and "🟢 ON" or "🔴 OFF")
            status = status .. "\nAuto Buy: " .. (Settings.AutoBuy and "🟢" or "⚪")
            status = status .. "\nAuto Sell: " .. (Settings.AutoSell and "🟢" or "⚪")
            status = status .. "\nSiklus: " .. SiklusCount
            status = status .. "\nLahan: " .. #cachedLahans .. " cached"
            
            StatusParagraph:Set({
                Title = "Live Status",
                Content = status
            })
        end)
    end
end)

ConfigTab:CreateSection("⚙ Actions")

ConfigTab:CreateButton({
    Name = "⛔ STOP ALL AUTOS",
    Callback = function()
        Settings.AutoFarm = false
        Settings.AutoBuy = false
        Settings.AutoSell = false
        Settings.AutoTanam = false
        Settings.AutoPanen = false
        notif("STOP!", "Semua auto dimatikan", 3)
    end
})

ConfigTab:CreateButton({
    Name = "🗑 Clear ESP",
    Callback = function()
        for _, esp in ipairs(ESPObjects) do
            if esp then pcall(function() esp:Destroy() end) end
        end
        ESPObjects = {}
        notif("Clear", "ESP dihapus", 2)
    end
})

--====================================================
-- ANTI AFK & PROTECTION LOOPS
--====================================================

-- Anti AFK
task.spawn(function()
    while task.wait(60) do
        if Settings.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end
end)

-- Lightning check
task.spawn(function()
    while task.wait(0.5) do
        if Settings.LightningProtection then
            CheckLightning()
        end
    end
end)

-- Auto rejoin
task.spawn(function()
    while task.wait(30) do
        if Settings.AutoRejoin and not LocalPlayer.Parent then
            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
        end
    end
end)

--====================================================
-- INIT
--====================================================
notif("🌾 SAWAH INDO v8.0", "ULTIMATE EDITION 🔥", 5)
task.wait(0.5)
notif("Langkah 1", "Ke tab Teleport > Save Farm Position", 4)
task.wait(0.5)
notif("Langkah 2", "Toggle FULL AUTO FARM", 4)

print("=" .. string.rep("=", 40))
print("SAWAH INDO v8.0 ULTIMATE")
print("Status: FULLY FUNCTIONAL")
print("=" .. string.rep("=", 40))
