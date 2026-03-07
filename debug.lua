--====================================================================--
--          XKID SUPER EPIC UNIVERSAL HUB - VERSION 9000             --
--          Auto Detect + Auto Farm + Auto Everything                --
--====================================================================--

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⚡ XKID SUPER EPIC HUB ⚡",
    LoadingTitle = "LOADING SUPER EPIC...",
    LoadingSubtitle = "by XKID | Version 9000",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKidSuperEpic",
        FileName = "Config"
    },
    KeySystem = false
})

--====================================================================--
--                    SERVICES & VARIABLES                           --
--====================================================================--

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TPService = game:GetService("TeleportService")
local Marketplace = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

--====================================================================--
--                    GLOBAL VARIABLES                               --
--====================================================================--

_G.Settings = {
    AutoFarm = false,
    AutoCollect = false,
    AutoSell = false,
    AutoBuy = false,
    AutoQuest = false,
    AutoRebirth = false,
    AutoUpgrade = false,
    WalkSpeed = 16,
    JumpPower = 50,
    Gravity = 196.2,
    FarmRadius = 50,
    CollectionRadius = 30,
    Delay = 1
}

_G.GameInfo = {
    name = "Unknown",
    placeId = game.PlaceId,
    genre = "Unknown",
    type = "Unknown",
    players = #Players:GetPlayers(),
    maxPlayers = Players.MaxPlayers,
    serverTime = 0,
    detectedObjects = {},
    importantNPCs = {},
    farmables = {},
    collectables = {},
    sellZones = {},
    safeZones = {}
}

--====================================================================--
--                    SUPER DETECTOR ENGINE                          --
--====================================================================--

local function notify(title, msg, time)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = msg,
        Duration = time or 3
    })
end

local function scanAllObjects()
    print("🔍 MULAI SCAN SUPER EPIC...")
    notify("SUPER EPIC", "Memindai game...", 2)
    
    local startTime = tick()
    local totalObjects = 0
    local categories = {
        farming = {"tanah", "lahan", "bibit", "seed", "crop", "plant", "farm", "sawah", "padi", "tomat", "jagung", "terong", "strawberry", "durian", "sawit", "palm"},
        fighting = {"sword", "weapon", "enemy", "boss", "battle", "fight", "pvp", "arena", "monster", "zombie", "dungeon"},
        simulator = {"simulator", "coin", "money", "cash", "pet", "egg", "hatch", "breed", "evolve"},
        tycoon = {"tycoon", "generator", "dropper", "conveyor", "upgrade", "sell", "button", "press"},
        obby = {"obby", "jump", "checkpoint", "stage", "level", "platform", "finish", "start"},
        racing = {"car", "vehicle", "race", "track", "speed", "drive", "wheel", "nitro"},
        rpg = {"quest", "npc", "shop", "merchant", "guild", "dungeon", "king", "guard"},
        building = {"brick", "block", "build", "structure", "house", "base", "wall", "door"}
    }
    
    -- Reset data
    _G.GameInfo.detectedObjects = {}
    _G.GameInfo.importantNPCs = {}
    _G.GameInfo.farmables = {}
    _G.GameInfo.collectables = {}
    _G.GameInfo.sellZones = {}
    
    -- Scan semua object
    for _, obj in pairs(Workspace:GetDescendants()) do
        totalObjects = totalObjects + 1
        
        -- Skip yang ngga penting
        if not obj:IsA("BasePart") and not obj:IsA("Model") then continue end
        
        local objName = obj.Name:lower()
        local objClass = obj.ClassName
        local objPos = nil
        
        -- Dapatkan posisi
        if obj:IsA("BasePart") then
            objPos = obj.Position
        elseif obj:IsA("Model") then
            if obj:FindFirstChild("HumanoidRootPart") then
                objPos = obj.HumanoidRootPart.Position
            elseif obj:FindFirstChild("Head") then
                objPos = obj.Head.Position
            elseif obj:FindFirstChild("Torso") then
                objPos = obj.Torso.Position
            end
        end
        
        if not objPos then continue end
        
        -- Kategorisasi
        for cat, keywords in pairs(categories) do
            for _, kw in ipairs(keywords) do
                if objName:find(kw) then
                    table.insert(_G.GameInfo.detectedObjects, {
                        name = obj.Name,
                        class = objClass,
                        category = cat,
                        position = objPos,
                        object = obj
                    })
                    
                    -- Khusus untuk farming
                    if cat == "farming" then
                        table.insert(_G.GameInfo.farmables, obj)
                    end
                    
                    -- Cari NPC (model dengan Humanoid)
                    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= LocalPlayer.Character then
                        table.insert(_G.GameInfo.importantNPCs, obj)
                        
                        if objName:find("sell") or objName:find("jual") or objName:find("merchant") then
                            table.insert(_G.GameInfo.sellZones, obj)
                        end
                    end
                    
                    break
                end
            end
        end
        
        -- Cari collectables (coins, eggs, etc)
        if objName:find("coin") or objName:find("egg") or objName:find("gem") or objName:find("crystal") then
            table.insert(_G.GameInfo.collectables, obj)
        end
    end
    
    -- Deteksi tipe game
    local scores = {}
    for cat, keywords in pairs(categories) do
        scores[cat] = 0
    end
    
    for _, obj in ipairs(_G.GameInfo.detectedObjects) do
        scores[obj.category] = (scores[obj.category] or 0) + 1
    end
    
    local bestType = "unknown"
    local bestScore = 0
    for cat, score in pairs(scores) do
        if score > bestScore then
            bestScore = score
            bestType = cat
        end
    end
    
    _G.GameInfo.type = bestType
    _G.GameInfo.serverTime = tick() - startTime
    
    print("✅ SCAN SELESAI dalam " .. math.floor(_G.GameInfo.serverTime * 1000) .. "ms")
    print("📊 Tipe Game: " .. bestType)
    print("📊 Total Object: " .. totalObjects)
    print("📊 Detected: " .. #_G.GameInfo.detectedObjects)
    print("📊 NPC: " .. #_G.GameInfo.importantNPCs)
    print("📊 Farmables: " .. #_G.GameInfo.farmables)
    print("📊 Collectables: " .. #_G.GameInfo.collectables)
    
    notify("SUPER EPIC", "Game: " .. bestType .. " | NPC: " .. #_G.GameInfo.importantNPCs, 3)
    
    return _G.GameInfo
end

--====================================================================--
--                    AUTO FARM ENGINE                               --
--====================================================================--

local farmConnections = {}

local function teleportTo(obj)
    if not obj or not LocalPlayer.Character then return false end
    
    local pos = nil
    if obj:IsA("BasePart") then
        pos = obj.Position
    elseif obj:IsA("Model") then
        if obj:FindFirstChild("HumanoidRootPart") then
            pos = obj.HumanoidRootPart.Position
        elseif obj:FindFirstChild("Head") then
            pos = obj.Head.Position
        end
    end
    
    if pos then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
        return true
    end
    return false
end

local function interactWith(obj)
    if not obj then return end
    
    pcall(function()
        -- Touch
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
        wait(0.1)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
    end)
    
    pcall(function()
        -- ClickDetector
        for _, d in pairs(obj:GetDescendants()) do
            if d:IsA("ClickDetector") then
                d:MouseClick()
            end
        end
    end)
    
    pcall(function()
        -- ProximityPrompt
        for _, p in pairs(obj:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                p:InputHoldBegin()
                wait(0.2)
                p:InputHoldEnd()
            end
        end
    end)
end

local function startAutoFarm()
    -- Bersihkan koneksi lama
    for _, conn in pairs(farmConnections) do
        pcall(function() conn:Disconnect() end)
    end
    farmConnections = {}
    
    if not _G.Settings.AutoFarm then return end
    
    -- Auto Farm berdasarkan tipe game
    if _G.GameInfo.type == "farming" then
        farmConnections.farm = RunService.Heartbeat:Connect(function()
            if not _G.Settings.AutoFarm then return end
            
            -- Auto tanam
            if #_G.GameInfo.farmables > 0 then
                for _, farmObj in ipairs(_G.GameInfo.farmables) do
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - farmObj.Position).Magnitude
                    if dist < _G.Settings.FarmRadius then
                        LocalPlayer.Character.Humanoid:MoveTo(farmObj.Position)
                        if dist < 5 then
                            interactWith(farmObj)
                            wait(_G.Settings.Delay)
                        end
                        break
                    end
                end
            end
        end)
    elseif _G.GameInfo.type == "simulator" then
        farmConnections.farm = RunService.Heartbeat:Connect(function()
            if not _G.Settings.AutoFarm then return end
            
            -- Auto collect coins/eggs
            if #_G.GameInfo.collectables > 0 then
                for _, collectable in ipairs(_G.GameInfo.collectables) do
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - collectable.Position).Magnitude
                    if dist < _G.Settings.CollectionRadius then
                        LocalPlayer.Character.Humanoid:MoveTo(collectable.Position)
                        if dist < 5 then
                            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, collectable, 0)
                            wait(0.1)
                            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, collectable, 1)
                        end
                        break
                    end
                end
            end
        end)
    end
    
    -- Auto sell
    if _G.Settings.AutoSell and #_G.GameInfo.sellZones > 0 then
        farmConnections.sell = RunService.Heartbeat:Connect(function()
            if not _G.Settings.AutoSell then return end
            
            local sellZone = _G.GameInfo.sellZones[1]
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - sellZone.Position).Magnitude
            
            if dist > 5 then
                LocalPlayer.Character.Humanoid:MoveTo(sellZone.Position)
            else
                interactWith(sellZone)
                wait(2)
            end
        end)
    end
end

--====================================================================--
--                    TELEPORT ENGINE                                --
--====================================================================--

local function teleportToNearest(category)
    local nearest = nil
    local nearestDist = math.huge
    
    for _, obj in ipairs(_G.GameInfo.detectedObjects) do
        if obj.category == category then
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - obj.position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = obj.object
            end
        end
    end
    
    if nearest then
        teleportTo(nearest)
        return true
    end
    return false
end

--====================================================================--
--                    GUI CREATION                                   --
--====================================================================--

-- TAB: INFO
local InfoTab = Window:CreateTab("📊 INFO", nil)

InfoTab:CreateButton({
    Name = "🔍 SCAN GAME (SUPER EPIC)",
    Callback = function()
        scanAllObjects()
    end
})

InfoTab:CreateButton({
    Name = "📋 TAMPILKAN HASIL SCAN",
    Callback = function()
        print("\n=== SUPER EPIC SCAN RESULTS ===")
        print("Game: " .. _G.GameInfo.name)
        print("Type: " .. _G.GameInfo.type)
        print("Place ID: " .. _G.GameInfo.placeId)
        print("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
        print("\n📌 NPC Ditemukan: " .. #_G.GameInfo.importantNPCs)
        for i, npc in ipairs(_G.GameInfo.importantNPCs) do
            print("  " .. i .. ". " .. npc.Name)
        end
        print("\n🌾 Farmables: " .. #_G.GameInfo.farmables)
        print("💰 Sell Zones: " .. #_G.GameInfo.sellZones)
        print("💎 Collectables: " .. #_G.GameInfo.collectables)
        print("================================")
    end
})

InfoTab:CreateButton({
    Name = "🎮 INFO GAME DARI ROBLOX",
    Callback = function()
        local info = Marketplace:GetProductInfo(game.PlaceId)
        print("\n=== ROBLOX GAME INFO ===")
        print("Name: " .. info.Name)
        print("Description: " .. info.Description)
        print("Creator: " .. info.Creator.Name)
        print("Created: " .. info.Created)
        print("Updated: " .. info.Updated)
        print("Visits: " .. (info.Visits or "Unknown"))
        print("Genre: " .. info.Genre)
        print("Price: " .. (info.PriceInRobux or "Free"))
    end
})

-- TAB: AUTO FARM
local AutoTab = Window:CreateTab("⚡ AUTO FARM", nil)

AutoTab:CreateToggle({
    Name = "🌾 AUTO FARM (Otomatis)",
    CurrentValue = false,
    Callback = function(v)
        _G.Settings.AutoFarm = v
        startAutoFarm()
        notify("AUTO FARM", v and "AKTIF" or "MATI", 1)
    end
})

AutoTab:CreateToggle({
    Name = "💰 AUTO SELL (Otomatis Jual)",
    CurrentValue = false,
    Callback = function(v)
        _G.Settings.AutoSell = v
        startAutoFarm()
    end
})

AutoTab:CreateSlider({
    Name = "📏 Radius Farm",
    Range = {10, 100},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(v) _G.Settings.FarmRadius = v end
})

AutoTab:CreateSlider({
    Name = "⏱️ Delay (detik)",
    Range = {0.5, 5},
    Increment = 0.5,
    CurrentValue = 1,
    Callback = function(v) _G.Settings.Delay = v end
})

-- TAB: TELEPORT
local TeleportTab = Window:CreateTab("📍 TELEPORT", nil)

TeleportTab:CreateButton({
    Name = "🏃 KE NPC TERDEKAT",
    Callback = function()
        if #_G.GameInfo.importantNPCs > 0 then
            teleportTo(_G.GameInfo.importantNPCs[1])
        else
            notify("ERROR", "Tidak ada NPC", 2)
        end
    end
})

TeleportTab:CreateButton({
    Name = "🌾 KE FARMABLE TERDEKAT",
    Callback = function()
        teleportToNearest("farming")
    end
})

TeleportTab:CreateButton({
    Name = "💰 KE SELL ZONE TERDEKAT",
    Callback = function()
        if #_G.GameInfo.sellZones > 0 then
            teleportTo(_G.GameInfo.sellZones[1])
        end
    end
})

TeleportTab:CreateButton({
    Name = "💎 KE COLLECTABLE TERDEKAT",
    Callback = function()
        if #_G.GameInfo.collectables > 0 then
            teleportTo(_G.GameInfo.collectables[1])
        end
    end
})

-- TAB: PLAYER
local PlayerTab = Window:CreateTab("👤 PLAYER", nil)

PlayerTab:CreateSlider({
    Name = "🚶 WalkSpeed",
    Range = {16, 350},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        _G.Settings.WalkSpeed = v
        pcall(function()
            if LocalPlayer.Character then
                LocalPlayer.Character.Humanoid.WalkSpeed = v
            end
        end)
    end
})

PlayerTab:CreateSlider({
    Name = "🦘 JumpPower",
    Range = {50, 500},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        _G.Settings.JumpPower = v
        pcall(function()
            if LocalPlayer.Character then
                LocalPlayer.Character.Humanoid.JumpPower = v
            end
        end)
    end
})

PlayerTab:CreateSlider({
    Name = "🌍 Gravity",
    Range = {0, 500},
    Increment = 5,
    CurrentValue = 196.2,
    Callback = function(v)
        _G.Settings.Gravity = v
        Workspace.Gravity = v
    end
})

PlayerTab:CreateToggle({
    Name = "🔄 Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        _G.InfiniteJump = v
        if v then
            UIS.JumpRequest:Connect(function()
                if _G.InfiniteJump and LocalPlayer.Character then
                    LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end
})

PlayerTab:CreateToggle({
    Name = "🛡️ Anti AFK",
    CurrentValue = false,
    Callback = function(v)
        if v then
            LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
})

PlayerTab:CreateButton({
    Name = "💀 Reset Character",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end
})

-- TAB: VISUAL
local VisualTab = Window:CreateTab("🎨 VISUAL", nil)

VisualTab:CreateToggle({
    Name = "☀️ Full Bright",
    CurrentValue = false,
    Callback = function(v)
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.new(1,1,1)
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.FogEnd = 50000
            Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.new(0,0,0)
        end
    end
})

VisualTab:CreateToggle({
    Name = "👁️ X-Ray Vision",
    CurrentValue = false,
    Callback = function(v)
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = v and 0.7 or 0
            end
        end
    end
})

VisualTab:CreateSlider({
    Name = "🎥 Field of View",
    Range = {40, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(v)
        Workspace.CurrentCamera.FieldOfView = v
    end
})

-- TAB: UTILITY
local UtilityTab = Window:CreateTab("⚙ UTILITY", nil)

UtilityTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        TPService:Teleport(game.PlaceId, LocalPlayer)
    end
})

UtilityTab:CreateButton({
    Name = "🌐 Server Hop",
    Callback = function()
        notify("Server Hop", "Mencari server...", 2)
        local success, servers = pcall(function()
            local res = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")
            return HttpService:JSONDecode(res)
        end)
        if success and servers and servers.data then
            for _, server in ipairs(servers.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TPService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    return
                end
            end
        end
    end
})

UtilityTab:CreateInput({
    Name = "📥 Load Script",
    PlaceholderText = "URL script...",
    Callback = function(url)
        if url:match("^https?://") then
            pcall(function() loadstring(game:HttpGet(url))() end)
        end
    end
})

-- TAB: SCRIPT RECOMMENDATIONS
local ScriptTab = Window:CreateTab("💡 REKOMENDASI", nil)

ScriptTab:CreateButton({
    Name = "📋 REKOMENDASI SCRIPT UNTUK GAME INI",
    Callback = function()
        print("\n=== REKOMENDASI SCRIPT UNTUK " .. _G.GameInfo.type .. " GAME ===")
        
        if _G.GameInfo.type == "farming" then
            print("🌾 GAME FARMING:")
            print("1. Auto Plant/Harvest/Sell")
            print("2. Auto Buy Seeds")
            print("3. ESP Tanaman")
            print("4. Teleport ke NPC")
            print("\n🔗 Link Script Farming:")
            print("https://pastebin.com/raw/FarmingScript1")
            
        elseif _G.GameInfo.type == "simulator" then
            print("🎮 GAME SIMULATOR:")
            print("1. Auto Collect Coins/Eggs")
            print("2. Auto Hatch Pets")
            print("3. Auto Upgrade")
            print("4. Auto Rebirth")
            print("\n🔗 Link Script Simulator:")
            print("https://pastebin.com/raw/SimulatorScript1")
            
        elseif _G.GameInfo.type == "fighting" then
            print("⚔️ GAME FIGHTING:")
            print("1. Auto Attack Enemies")
            print("2. Auto Farm Boss")
            print("3. ESP Enemies")
            print("4. Auto Collect Drops")
            print("\n🔗 Link Script Fighting:")
            print("https://pastebin.com/raw/FightingScript1")
            
        else
            print("❓ GAME TIDAK TERDETEKSI")
            print("Coba jalankan SCAN GAME dulu")
        end
        
        print("\n📌 Untuk script spesifik, cari di:")
        print("- V3rmillion.net")
        print("- Robloxscripts.com")
        print("- Pastebin.com")
    end
})

ScriptTab:CreateButton({
    Name = "🎯 SCRIPT FARMING UNIVERSAL",
    Callback = function()
        print("\n=== SCRIPT FARMING UNIVERSAL ===")
        print([[
loadstring(game:HttpGet('https://raw.githubusercontent.com/SomeUser/FarmingHub/main/script.lua'))()
        ]])
    end
})

ScriptTab:CreateButton({
    Name = "⚡ SCRIPT SIMULATOR UNIVERSAL",
    Callback = function()
        print("\n=== SCRIPT SIMULATOR UNIVERSAL ===")
        print([[
loadstring(game:HttpGet('https://raw.githubusercontent.com/SomeUser/SimHub/main/script.lua'))()
        ]])
    end
})

--====================================================================--
--                    INITIAL SCAN                                   --
--====================================================================--

-- Auto scan saat pertama kali load
spawn(function()
    wait(3)
    scanAllObjects()
    notify("SUPER EPIC HUB", "Scan otomatis selesai!", 2)
end)

--====================================================================--
--                    CLEANUP                                        --
--====================================================================--

local function OnCleanup()
    for _, conn in pairs(farmConnections) do
        pcall(function() conn:Disconnect() end)
    end
    Workspace.Gravity = 196.2
end

game:BindToClose(OnCleanup)

print("⚡⚡⚡ SUPER EPIC HUB LOADED ⚡⚡⚡")
print("📌 Klik SCAN GAME untuk mulai")
