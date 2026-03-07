--[[
    SAWAH INDO HUB - REVISION FIX
    - Fixed: Teleport ke semua toko
    - Fixed: Auto plant/harvest/sell
    - Added: NPC Merchant, Farmer, Egg Trader
    - Added: Lahan Sawit
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TPService = game:GetService("TeleportService")

-- Notifikasi
local function Notify(title, content, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = duration or 2
    })
end

-- UI Window
local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO FIXED",
    LoadingTitle = "SAWAH INDO",
    LoadingSubtitle = "All Fixed + New Features",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SawahIndoHub",
        FileName = "Config"
    },
    KeySystem = false
})

Notify("SAWAH INDO FIXED", "Loading...", 2)

------------------------------------------------
-- TAB MENU
------------------------------------------------
local MainTab = Window:CreateTab("🏠 Main", nil)
local FarmTab = Window:CreateTab("🌾 Farming", nil)
local TeleportTab = Window:CreateTab("📍 Teleport", nil)
local MerchantTab = Window:CreateTab("🏪 Merchant", nil)
local PlayerTab = Window:CreateTab("👤 Player", nil)
local UtilityTab = Window:CreateTab("⚙ Utility", nil)

------------------------------------------------
-- VARIABEL GLOBAL
------------------------------------------------
_G.InfiniteJump = false
_G.Noclip = false
_G.AutoPlant = false
_G.AutoHarvest = false
_G.AutoSell = false
_G.WalkSpeed = 16
_G.JumpPower = 50
_G.FarmRadius = 20
_G.SelectedSeed = "Bibit Tomat"

-- Database lokasi (akan diisi auto scan)
local Locations = {
    -- Toko
    tokoBuy = {},
    tokoSell = {},
    tokoTool = {},
    
    -- NPC
    merchantSell = {},
    farmerBuy = {},
    eggTrader = {},
    
    -- Lahan
    lahanBiasa = {},
    lahanSawit = {},
    
    -- Tanaman
    tanaman = {}
}

-- Daftar bibit
local seeds = {
    ["Bibit Padi"] = {level = 0, price = 5, keyword = "padi"},
    ["Bibit Jagung"] = {level = 20, price = 15, keyword = "jagung"},
    ["Bibit Tomat"] = {level = 40, price = 25, keyword = "tomat"},
    ["Bibit Terong"] = {level = 60, price = 40, keyword = "terong|tereng"},
    ["Bibit Strawberry"] = {level = 80, price = 60, keyword = "strawberry|stroberi"},
    ["Bibit Sawit"] = {level = 80, price = 1000, keyword = "sawit|palm"},
    ["Bibit Durian"] = {level = 120, price = 2000, keyword = "durian"}
}

------------------------------------------------
-- SCANNER SUPER LENGKAP
------------------------------------------------
local function scanAllLocations()
    -- Reset lokasi
    Locations = {
        tokoBuy = {}, tokoSell = {}, tokoTool = {},
        merchantSell = {}, farmerBuy = {}, eggTrader = {},
        lahanBiasa = {}, lahanSawit = {}, tanaman = {}
    }
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if not obj then continue end
        local name = obj.Name:lower()
        local class = obj.ClassName
        
        -- ========== TOKO ==========
        if name:find("buy") or (name:find("toko") and name:find("beli")) then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                table.insert(Locations.tokoBuy, obj)
            end
        end
        
        if name:find("sell") or (name:find("toko") and name:find("jual")) then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                table.insert(Locations.tokoSell, obj)
            end
        end
        
        if name:find("tool") or name:find("alat") or (name:find("toko") and name:find("alat")) then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                table.insert(Locations.tokoTool, obj)
            end
        end
        
        -- ========== NPC ==========
        if class == "Model" and obj:FindFirstChild("Humanoid") and obj ~= LocalPlayer.Character then
            -- Merchant (jual hasil panen)
            if name:find("merchant") or name:find("pedagang") or name:find("sell") then
                table.insert(Locations.merchantSell, obj)
            end
            
            -- Farmer (beli bibit)
            if name:find("farmer") or name:find("petani") or name:find("buy") or name:find("bibit") then
                table.insert(Locations.farmerBuy, obj)
            end
            
            -- Egg Trader (jual telur)
            if name:find("egg") or name:find("telur") or name:find("ayam") then
                table.insert(Locations.eggTrader, obj)
            end
            
            -- NPC umum (jika tidak terdeteksi spesifik)
            if #Locations.merchantSell == 0 and #Locations.farmerBuy == 0 and #Locations.eggTrader == 0 then
                -- Masukkan ke kategori berdasarkan keyword
                if name:find("jual") or name:find("sell") then
                    table.insert(Locations.merchantSell, obj)
                elseif name:find("beli") or name:find("buy") or name:find("bibit") then
                    table.insert(Locations.farmerBuy, obj)
                elseif name:find("telur") or name:find("egg") then
                    table.insert(Locations.eggTrader, obj)
                end
            end
        end
        
        -- ========== LAHAN ==========
        if obj:IsA("BasePart") and (name:find("tanah") or name:find("lahan") or name:find("field") or name:find("soil") or name:find("farm")) then
            if name:find("sawit") or name:find("palm") then
                table.insert(Locations.lahanSawit, obj)
            else
                table.insert(Locations.lahanBiasa, obj)
            end
        end
        
        -- ========== TANAMAN ==========
        for seedName, data in pairs(seeds) do
            local keywords = data.keyword:split("|")
            for _, kw in ipairs(keywords) do
                if name:find(kw) and (obj:IsA("BasePart") or obj:IsA("Model")) then
                    table.insert(Locations.tanaman, {
                        obj = obj,
                        jenis = seedName,
                        pos = obj:IsA("BasePart") and obj.Position or (obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position or nil)
                    })
                    break
                end
            end
        end
    end
    
    -- Hapus duplikat
    local function unique(tbl)
        local seen = {}
        local result = {}
        for _, item in ipairs(tbl) do
            if not seen[item] then
                seen[item] = true
                table.insert(result, item)
            end
        end
        return result
    end
    
    Locations.tokoBuy = unique(Locations.tokoBuy)
    Locations.tokoSell = unique(Locations.tokoSell)
    Locations.tokoTool = unique(Locations.tokoTool)
    Locations.merchantSell = unique(Locations.merchantSell)
    Locations.farmerBuy = unique(Locations.farmerBuy)
    Locations.eggTrader = unique(Locations.eggTrader)
    Locations.lahanBiasa = unique(Locations.lahanBiasa)
    Locations.lahanSawit = unique(Locations.lahanSawit)
    
    -- Tampilkan hasil
    print("=== SCAN RESULTS ===")
    print("Toko Buy:", #Locations.tokoBuy)
    print("Toko Sell:", #Locations.tokoSell)
    print("Toko Tool:", #Locations.tokoTool)
    print("Merchant (Jual Hasil):", #Locations.merchantSell)
    print("Farmer (Beli Bibit):", #Locations.farmerBuy)
    print("Egg Trader:", #Locations.eggTrader)
    print("Lahan Biasa:", #Locations.lahanBiasa)
    print("Lahan Sawit:", #Locations.lahanSawit)
    print("Tanaman Ditemukan:", #Locations.tanaman)
    
    return Locations
end

-- Fungsi teleport aman
local function safeTeleport(target)
    if not target then return false end
    
    local cframe
    if target:IsA("BasePart") then
        cframe = target.CFrame
    elseif target:IsA("Model") then
        if target:FindFirstChild("HumanoidRootPart") then
            cframe = target.HumanoidRootPart.CFrame
        elseif target:FindFirstChild("Head") then
            cframe = target.Head.CFrame
        elseif target:FindFirstChild("Torso") then
            cframe = target.Torso.CFrame
        else
            -- Coba cari part pertama
            for _, child in pairs(target:GetChildren()) do
                if child:IsA("BasePart") then
                    cframe = child.CFrame
                    break
                end
            end
        end
    end
    
    if cframe and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe + Vector3.new(0, 3, 0)
        return true
    end
    return false
end

-- Fungsi interaksi
local function interactWith(obj)
    if not obj then return end
    
    -- Approach object
    if obj:IsA("BasePart") then
        LocalPlayer.Character.Humanoid:MoveTo(obj.Position)
        wait(0.5)
    end
    
    -- Metode 1: Touch
    pcall(function()
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
        wait(0.1)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
    end)
    
    -- Metode 2: ClickDetector
    pcall(function()
        for _, detector in pairs(obj:GetDescendants()) do
            if detector:IsA("ClickDetector") then
                detector:MouseClick()
                wait(0.1)
            end
        end
    end)
    
    -- Metode 3: ProximityPrompt
    pcall(function()
        for _, prompt in pairs(obj:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt:InputHoldBegin()
                wait(0.3)
                prompt:InputHoldEnd()
            end
        end
    end)
end

------------------------------------------------
-- MAIN TAB
------------------------------------------------
local infiniteJumpConnection
MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        _G.InfiniteJump = v
        if infiniteJumpConnection then infiniteJumpConnection:Disconnect() end
        if v then
            infiniteJumpConnection = UIS.JumpRequest:Connect(function()
                if _G.InfiniteJump and LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
    end
})

local noclipHeartbeat
MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        _G.Noclip = v
        if noclipHeartbeat then noclipHeartbeat:Disconnect() end
        if v then
            local lastUpdate = 0
            noclipHeartbeat = RunService.Heartbeat:Connect(function()
                if tick() - lastUpdate < 0.1 then return end
                lastUpdate = tick()
                pcall(function()
                    if LocalPlayer.Character then
                        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            end)
        end
    end
})

MainTab:CreateButton({
    Name = "🔄 Scan Ulang Semua Lokasi",
    Callback = function()
        scanAllLocations()
        Notify("Scan", "Lokasi telah diupdate", 2)
    end
})

------------------------------------------------
-- FARMING TAB (FIXED AUTO PLANT/HARVEST/SELL)
------------------------------------------------
local farmingConnections = {}

local function startFarming()
    -- Cleanup koneksi lama
    for _, conn in pairs(farmingConnections) do
        pcall(function() conn:Disconnect() end)
    end
    farmingConnections = {}
    
    -- AUTO PLANT
    if _G.AutoPlant then
        farmingConnections.plant = RunService.Heartbeat:Connect(function()
            if not _G.AutoPlant or not LocalPlayer.Character then return end
            
            local lahan = Locations.lahanBiasa
            if _G.SelectedSeed == "Bibit Sawit" then
                lahan = Locations.lahanSawit
            end
            
            if #lahan == 0 then
                scanAllLocations()
                return
            end
            
            -- Cari lahan terdekat
            local closestLand = nil
            local closestDist = math.huge
            local myPos = LocalPlayer.Character.HumanoidRootPart.Position
            
            for _, land in ipairs(lahan) do
                local landPos = land:IsA("BasePart") and land.Position or (land:FindFirstChild("HumanoidRootPart") and land.HumanoidRootPart.Position)
                if landPos then
                    local dist = (myPos - landPos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestLand = land
                    end
                end
            end
            
            if closestLand and closestDist < _G.FarmRadius then
                -- Gerak ke lahan
                local landPos = closestLand:IsA("BasePart") and closestLand.Position or closestLand.HumanoidRootPart.Position
                LocalPlayer.Character.Humanoid:MoveTo(landPos)
                
                -- Jika sudah dekat, interaksi
                if closestDist < 5 then
                    interactWith(closestLand)
                    wait(0.3)
                end
            end
        end)
    end
    
    -- AUTO HARVEST
    if _G.AutoHarvest then
        farmingConnections.harvest = RunService.Heartbeat:Connect(function()
            if not _G.AutoHarvest or not LocalPlayer.Character then return end
            
            if #Locations.tanaman == 0 then
                scanAllLocations()
                return
            end
            
            local myPos = LocalPlayer.Character.HumanoidRootPart.Position
            local harvested = 0
            
            for i, plant in ipairs(Locations.tanaman) do
                if plant.pos then
                    local dist = (myPos - plant.pos).Magnitude
                    if dist < 10 then
                        LocalPlayer.Character.Humanoid:MoveTo(plant.pos)
                        if dist < 4 then
                            interactWith(plant.obj)
                            harvested = harvested + 1
                            wait(0.2)
                        end
                    end
                end
            end
            
            if harvested > 0 then
                Notify("Panen", "Memanen " .. harvested .. " tanaman", 1)
            end
        end)
    end
    
    -- AUTO SELL (ke merchant)
    if _G.AutoSell then
        farmingConnections.sell = RunService.Heartbeat:Connect(function()
            if not _G.AutoSell or not LocalPlayer.Character then return end
            
            if #Locations.merchantSell == 0 and #Locations.tokoSell == 0 then
                scanAllLocations()
                return
            end
            
            local target = #Locations.merchantSell > 0 and Locations.merchantSell[1] or (#Locations.tokoSell > 0 and Locations.tokoSell[1] or nil)
            if not target then return end
            
            local targetPos = target:IsA("BasePart") and target.Position or (target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Position)
            if not targetPos then return end
            
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - targetPos).Magnitude
            
            if dist > 5 then
                LocalPlayer.Character.Humanoid:MoveTo(targetPos)
            else
                interactWith(target)
                wait(1)
            end
        end)
    end
end

FarmTab:CreateToggle({
    Name = "🌱 Auto Plant",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoPlant = v
        startFarming()
    end
})

FarmTab:CreateToggle({
    Name = "🌽 Auto Harvest",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoHarvest = v
        startFarming()
    end
})

FarmTab:CreateToggle({
    Name = "💰 Auto Sell (ke Merchant)",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoSell = v
        startFarming()
    end
})

FarmTab:CreateDropdown({
    Name = "Pilih Bibit",
    Options = {"Bibit Padi", "Bibit Jagung", "Bibit Tomat", "Bibit Terong", "Bibit Strawberry", "Bibit Sawit", "Bibit Durian"},
    CurrentOption = {"Bibit Tomat"},
    Callback = function(selected)
        _G.SelectedSeed = selected[1]
    end
})

FarmTab:CreateSlider({
    Name = "Radius Farming",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 20,
    Callback = function(v) _G.FarmRadius = v end
})

------------------------------------------------
-- TELEPORT TAB (FIXED - SEMUA BEKERJA)
------------------------------------------------
TeleportTab:CreateButton({
    Name = "🏪 Toko BUY (Beli Bibit)",
    Callback = function()
        if #Locations.tokoBuy == 0 then scanAllLocations() end
        if #Locations.tokoBuy > 0 then
            safeTeleport(Locations.tokoBuy[1])
            Notify("Teleport", "Ke Toko Buy", 1)
        else
            -- Fallback ke farmer
            if #Locations.farmerBuy > 0 then
                safeTeleport(Locations.farmerBuy[1])
                Notify("Teleport", "Ke Farmer (Buy)", 1)
            else
                Notify("Error", "Toko Buy tidak ditemukan", 2)
            end
        end
    end
})

TeleportTab:CreateButton({
    Name = "💰 Toko SELL (Jual Hasil)",
    Callback = function()
        if #Locations.tokoSell == 0 then scanAllLocations() end
        if #Locations.tokoSell > 0 then
            safeTeleport(Locations.tokoSell[1])
            Notify("Teleport", "Ke Toko Sell", 1)
        else
            -- Fallback ke merchant
            if #Locations.merchantSell > 0 then
                safeTeleport(Locations.merchantSell[1])
                Notify("Teleport", "Ke Merchant", 1)
            else
                Notify("Error", "Toko Sell tidak ditemukan", 2)
            end
        end
    end
})

TeleportTab:CreateButton({
    Name = "🔧 Toko TOOL (Alat)",
    Callback = function()
        if #Locations.tokoTool == 0 then scanAllLocations() end
        if #Locations.tokoTool > 0 then
            safeTeleport(Locations.tokoTool[1])
            Notify("Teleport", "Ke Toko Tool", 1)
        else
            Notify("Error", "Toko Tool tidak ditemukan", 2)
        end
    end
})

TeleportTab:CreateButton({
    Name = "👨‍🌾 Farmer (Beli Bibit)",
    Callback = function()
        if #Locations.farmerBuy == 0 then scanAllLocations() end
        if #Locations.farmerBuy > 0 then
            safeTeleport(Locations.farmerBuy[1])
            Notify("Teleport", "Ke Farmer", 1)
        else
            Notify("Error", "Farmer tidak ditemukan", 2)
        end
    end
})

TeleportTab:CreateButton({
    Name = "💰 Merchant (Jual Hasil)",
    Callback = function()
        if #Locations.merchantSell == 0 then scanAllLocations() end
        if #Locations.merchantSell > 0 then
            safeTeleport(Locations.merchantSell[1])
            Notify("Teleport", "Ke Merchant", 1)
        else
            Notify("Error", "Merchant tidak ditemukan", 2)
        end
    end
})

TeleportTab:CreateButton({
    Name = "🥚 Egg Trader (Jual Telur)",
    Callback = function()
        if #Locations.eggTrader == 0 then scanAllLocations() end
        if #Locations.eggTrader > 0 then
            safeTeleport(Locations.eggTrader[1])
            Notify("Teleport", "Ke Egg Trader", 1)
        else
            Notify("Error", "Egg Trader tidak ditemukan", 2)
        end
    end
})

TeleportTab:CreateButton({
    Name = "🌾 Lahan Biasa",
    Callback = function()
        if #Locations.lahanBiasa == 0 then scanAllLocations() end
        if #Locations.lahanBiasa > 0 then
            safeTeleport(Locations.lahanBiasa[1])
            Notify("Teleport", "Ke Lahan Biasa", 1)
        else
            Notify("Error", "Lahan tidak ditemukan", 2)
        end
    end
})

TeleportTab:CreateButton({
    Name = "🌴 Lahan Sawit",
    Callback = function()
        if #Locations.lahanSawit == 0 then scanAllLocations() end
        if #Locations.lahanSawit > 0 then
            safeTeleport(Locations.lahanSawit[1])
            Notify("Teleport", "Ke Lahan Sawit", 1)
        else
            Notify("Error", "Lahan Sawit tidak ditemukan", 2)
        end
    end
})

TeleportTab:CreateInput({
    Name = "Teleport ke Koordinat",
    PlaceholderText = "x y z",
    Callback = function(input)
        local coords = {}
        for num in input:gmatch("%-?%d+%.?%d*") do
            table.insert(coords, tonumber(num))
        end
        if #coords >= 3 and LocalPlayer.Character then
            LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(coords[1], coords[2], coords[3]))
        end
    end
})

------------------------------------------------
-- MERCHANT TAB (INFORMASI)
------------------------------------------------
MerchantTab:CreateButton({
    Name = "👨‍🌾 Farmer - Beli Bibit",
    Callback = function()
        if #Locations.farmerBuy > 0 then
            safeTeleport(Locations.farmerBuy[1])
        else
            Notify("Info", "Scan dulu atau cek di Teleport tab", 2)
        end
    end
})

MerchantTab:CreateButton({
    Name = "💰 Merchant - Jual Hasil Panen",
    Callback = function()
        if #Locations.merchantSell > 0 then
            safeTeleport(Locations.merchantSell[1])
        else
            Notify("Info", "Scan dulu atau cek di Teleport tab", 2)
        end
    end
})

MerchantTab:CreateButton({
    Name = "🥚 Egg Trader - Jual Telur",
    Callback = function()
        if #Locations.eggTrader > 0 then
            safeTeleport(Locations.eggTrader[1])
        else
            Notify("Info", "Scan dulu atau cek di Teleport tab", 2)
        end
    end
})

MerchantTab:CreateButton({
    Name = "🔧 Toko Tool - Beli Alat",
    Callback = function()
        if #Locations.tokoTool > 0 then
            safeTeleport(Locations.tokoTool[1])
        else
            Notify("Info", "Scan dulu atau cek di Teleport tab", 2)
        end
    end
})

MerchantTab:CreateButton({
    Name = "📋 Lihat Hasil Scan",
    Callback = function()
        local msg = string.format(
            "Toko Buy: %d\nToko Sell: %d\nToko Tool: %d\nFarmer: %d\nMerchant: %d\nEgg Trader: %d\nLahan: %d\nLahan Sawit: %d",
            #Locations.tokoBuy, #Locations.tokoSell, #Locations.tokoTool,
            #Locations.farmerBuy, #Locations.merchantSell, #Locations.eggTrader,
            #Locations.lahanBiasa, #Locations.lahanSawit
        )
        Notify("Scan Results", msg, 5)
    end
})

------------------------------------------------
-- PLAYER TAB
------------------------------------------------
local walkspeedConnection
local function updateWalkSpeed(speed)
    _G.WalkSpeed = speed
    pcall(function()
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = speed end
        end
    end)
end

walkspeedConnection = LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    updateWalkSpeed(_G.WalkSpeed)
end)

PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Callback = updateWalkSpeed
})

local jumppowerConnection
local function updateJumpPower(power)
    _G.JumpPower = power
    pcall(function()
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid:FindFirstChild("JumpPower") then
                    humanoid.JumpPower = power
                elseif humanoid:FindFirstChild("JumpHeight") then
                    humanoid.JumpHeight = power / 2
                end
            end
        end
    end)
end

jumppowerConnection = LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    updateJumpPower(_G.JumpPower)
end)

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Callback = updateJumpPower
})

PlayerTab:CreateSlider({
    Name = "Gravity",
    Range = {0, 500},
    Increment = 5,
    CurrentValue = 196.2,
    Callback = function(v) Workspace.Gravity = v end
})

------------------------------------------------
-- UTILITY TAB
------------------------------------------------
_G.AntiAFK = false
local antiAFKConnection

UtilityTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Callback = function(v)
        _G.AntiAFK = v
        if antiAFKConnection then antiAFKConnection:Disconnect() end
        if v then
            antiAFKConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
})

UtilityTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TPService:Teleport(game.PlaceId, LocalPlayer)
    end
})

UtilityTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        Notify("Server Hop", "Mencari server...", 2)
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
            Notify("Server Hop", "Tidak ada server tersedia", 2)
        end
    end
})

------------------------------------------------
-- INITIAL SCAN
------------------------------------------------
wait(2)
scanAllLocations()
Notify("SAWAH INDO FIXED", string.format("Ditemukan: %d Lahan, %d NPC", #Locations.lahanBiasa + #Locations.lahanSawit, #Locations.farmerBuy + #Locations.merchantSell + #Locations.eggTrader), 4)

------------------------------------------------
-- CLEANUP
------------------------------------------------
local function OnCleanup()
    _G.InfiniteJump = false
    if infiniteJumpConnection then infiniteJumpConnection:Disconnect() end
    _G.Noclip = false
    if noclipHeartbeat then noclipHeartbeat:Disconnect() end
    _G.AutoPlant = false
    _G.AutoHarvest = false
    _G.AutoSell = false
    for _, conn in pairs(farmingConnections) do
        pcall(function() conn:Disconnect() end)
    end
    if antiAFKConnection then antiAFKConnection:Disconnect() end
    Workspace.Gravity = 196.2
end

game:BindToClose(OnCleanup)

print("SAWAH INDO HUB - FIXED VERSION LOADED")
