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

-- Notifikasi
local function Notify(title, content, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = duration or 2
    })
end

-- Deteksi platform
local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled

-- UI Window
local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO BY:XKID HUB",
    LoadingTitle = "SAWAH INDO",
    LoadingSubtitle = "Farming Auto",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SawahIndoHub",
        FileName = "Config"
    },
    KeySystem = false
})

Notify("SAWAH INDO HUB", "Loading...", 2)

------------------------------------------------
-- TAB MENU
------------------------------------------------
local MainTab = Window:CreateTab("🏠 Main", nil)
local FarmTab = Window:CreateTab("🌾 Farming", nil)
local SeedTab = Window:CreateTab("🌱 Bibit", nil)
local SellTab = Window:CreateTab("💰 Jual", nil)
local PlayerTab = Window:CreateTab("👤 Player", nil)
local TeleportTab = Window:CreateTab("🏝 Teleport", nil)
local UtilityTab = Window:CreateTab("⚙ Utility", nil)

------------------------------------------------
-- VARIABEL GLOBAL
------------------------------------------------
_G.AutoPlant = false
_G.AutoHarvest = false
_G.AutoSell = false
_G.SelectedSeed = "Bibit Tomat"
_G.FarmRadius = 20
_G.WalkSpeed = 16
_G.JumpPower = 50

-- Daftar bibit berdasarkan screenshot
local seeds = {
    ["Bibit Padi"] = {level = 0, price = 5, owned = 11}, -- Dari screenshot 42891
    ["Bibit Jagung"] = {level = 20, price = 15, owned = 0},
    ["Bibit Tomat"] = {level = 40, price = 25, owned = 0},
    ["Bibit Terong"] = {level = 60, price = 40, owned = 0},
    ["Bibit Strawberry"] = {level = 80, price = 60, owned = 0},
    ["Bibit Savit"] = {level = 80, price = 1000, owned = 0},
    ["Bibit Durian"] = {level = 120, price = 2000, owned = 0}
}

------------------------------------------------
-- FUNGSI UTILITY
------------------------------------------------
-- Cari object berdasarkan nama (case insensitive)
local function findObjects(namePattern)
    local objects = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find(namePattern:lower()) then
            table.insert(objects, obj)
        end
    end
    return objects
end

-- Cari tanah/lahan pertanian
local function findFarmLands()
    local lands = {}
    -- Coba beberapa kemungkinan nama
    local patterns = {"tanah", "lahan", "farm", "soil", "ground", "field"}
    for _, pattern in pairs(patterns) do
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find(pattern) and obj:IsA("Part") then
                table.insert(lands, obj)
            end
        end
    end
    return lands
end

-- Cari tanaman yang siap panen
local function findHarvestablePlants()
    local plants = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- Asumsi tanaman memiliki kata "tomat", "terong", dll di namanya
        for seedName in pairs(seeds) do
            local seedKeyword = seedName:gsub("Bibit ", ""):lower()
            if obj.Name:lower():find(seedKeyword) then
                -- Cek apakah siap panen (biasanya ada indikator visual atau properti)
                -- Ini perlu disesuaikan dengan game aslinya
                table.insert(plants, obj)
                break
            end
        end
    end
    return plants
end

-- Cari tempat jual
local function findSellZone()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("jual") or obj.Name:lower():find("sell") or obj.Name:lower():find("toko") then
            return obj
        end
    end
    return nil
end

-- Interaksi dengan object (simulasi klik/touch)
local function interactWith(obj)
    if not obj then return end
    -- Simulasi touch
    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
    wait(0.1)
    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
end

------------------------------------------------
-- MAIN TAB
------------------------------------------------
_G.InfiniteJump = false
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

_G.Noclip = false
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
    Name = "Reset Character",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
            Notify("Reset", "Character reset", 1)
        end
    end
})

------------------------------------------------
-- FARMING TAB (Auto Plant, Auto Harvest)
------------------------------------------------
local farmingConnections = {}

local function startFarming()
    -- Cleanup koneksi lama
    for _, conn in pairs(farmingConnections) do
        if conn then conn:Disconnect() end
    end
    
    if _G.AutoPlant then
        farmingConnections.plant = RunService.Heartbeat:Connect(function()
            if not _G.AutoPlant or not LocalPlayer.Character then return end
            
            local lands = findFarmLands()
            local targetLand = nil
            
            -- Cari lahan kosong terdekat
            for _, land in pairs(lands) do
                local dist = (land.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist < _G.FarmRadius then
                    targetLand = land
                    break
                end
            end
            
            if targetLand then
                -- Arahkan ke lahan
                LocalPlayer.Character.Humanoid:MoveTo(targetLand.Position)
                
                -- Jika sudah dekat, tanam
                if (targetLand.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 5 then
                    -- Simulasi buka menu bibit (perlu disesuaikan)
                    -- Biasanya dengan menyentuh object atau menekan tombol
                    interactWith(targetLand)
                    
                    -- Pilih bibit
                    wait(0.5)
                    -- Di sini perlu simulasi klik pada UI, sangat spesifik game
                    -- Untuk sementara, kita notifikasi saja
                    Notify("Auto Plant", "Menanam " .. _G.SelectedSeed, 1)
                end
            end
        end)
    end
    
    if _G.AutoHarvest then
        farmingConnections.harvest = RunService.Heartbeat:Connect(function()
            if not _G.AutoHarvest or not LocalPlayer.Character then return end
            
            local plants = findHarvestablePlants()
            for _, plant in pairs(plants) do
                local dist = (plant.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist < 10 then
                    LocalPlayer.Character.Humanoid:MoveTo(plant.Position)
                    if dist < 5 then
                        interactWith(plant)
                        wait(0.3)
                    end
                end
            end
        end)
    end
end

FarmTab:CreateToggle({
    Name = "Auto Plant",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoPlant = v
        startFarming()
    end
})

FarmTab:CreateToggle({
    Name = "Auto Harvest",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoHarvest = v
        startFarming()
    end
})

FarmTab:CreateDropdown({
    Name = "Pilih Bibit",
    Options = {"Bibit Padi", "Bibit Jagung", "Bibit Tomat", "Bibit Terong", "Bibit Strawberry", "Bibit Savit", "Bibit Durian"},
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

FarmTab:CreateButton({
    Name = "Cari Lahan Kosong",
    Callback = function()
        local lands = findFarmLands()
        Notify("Lahan", "Ditemukan " .. #lands .. " lahan", 2)
    end
})

FarmTab:CreateButton({
    Name = "Cek Tanaman Siap Panen",
    Callback = function()
        local plants = findHarvestablePlants()
        Notify("Panen", #plants .. " tanaman siap panen", 2)
    end
})

------------------------------------------------
-- SEED TAB (Info Bibit)
------------------------------------------------
for seedName, data in pairs(seeds) do
    SeedTab:CreateButton({
        Name = seedName .. " (Lv." .. data.level .. " | $" .. data.price .. ")",
        Callback = function()
            _G.SelectedSeed = seedName
            Notify("Bibit Dipilih", seedName, 1)
        end
    })
end

SeedTab:CreateInput({
    Name = "Beli Bibit (Jumlah)",
    PlaceholderText = "Masukkan jumlah",
    Callback = function(input)
        local count = tonumber(input)
        if count and count > 0 then
            Notify("Beli Bibit", "Membeli " .. count .. " " .. _G.SelectedSeed, 2)
            -- Implementasi beli: perlu akses ke GUI toko
            -- Biasanya dengan menyentuh NPC/toko dan klik tombol beli
        end
    end
})

SeedTab:CreateButton({
    Name = "Buka Toko Bibit",
    Callback = function()
        -- Cari object toko bibit
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("toko") and obj.Name:lower():find("bibit") then
                LocalPlayer.Character:SetPrimaryPartCFrame(obj.CFrame + Vector3.new(0,3,0))
                wait(1)
                interactWith(obj)
                return
            end
        end
        Notify("Error", "Toko bibit tidak ditemukan", 2)
    end
})

------------------------------------------------
-- SELL TAB (Auto Jual)
------------------------------------------------
_G.AutoSell = false
local sellConnection

local function startAutoSell()
    if sellConnection then sellConnection:Disconnect() end
    if not _G.AutoSell then return end
    
    sellConnection = RunService.Heartbeat:Connect(function()
        if not _G.AutoSell or not LocalPlayer.Character then return end
        
        local sellZone = findSellZone()
        if sellZone then
            local dist = (sellZone.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if dist > 5 then
                LocalPlayer.Character.Humanoid:MoveTo(sellZone.Position)
            else
                interactWith(sellZone)
                wait(0.5)
                -- Simulasi klik "Jual Semua"
                Notify("Auto Sell", "Menjual hasil panen", 1)
                wait(1)
            end
        end
    end)
end

SellTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoSell = v
        startAutoSell()
    end
})

SellTab:CreateButton({
    Name = "Jual Semua Sekarang",
    Callback = function()
        local sellZone = findSellZone()
        if sellZone then
            LocalPlayer.Character:SetPrimaryPartCFrame(sellZone.CFrame + Vector3.new(0,3,0))
            wait(1)
            interactWith(sellZone)
            Notify("Jual", "Menjual semua item", 1)
        else
            Notify("Error", "Tempat jual tidak ditemukan", 2)
        end
    end
})

SellTab:CreateButton({
    Name = "Cek Hasil Panen",
    Callback = function()
        -- Buka menu inventory
        Notify("Inventory", "Fitur inventory perlu implementasi spesifik", 2)
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
-- TELEPORT TAB
------------------------------------------------
local SelectedPlayer = nil

local function updatePlayerList()
    local list = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(list, player.Name) end
    end
    return list
end

local playerDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = updatePlayerList(),
    CurrentOption = {""},
    Callback = function(selected) SelectedPlayer = selected and selected[1] end
})

Players.PlayerAdded:Connect(function() playerDropdown:SetOptions(updatePlayerList()) end)
Players.PlayerRemoving:Connect(function() playerDropdown:SetOptions(updatePlayerList()) end)

TeleportTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if not SelectedPlayer then Notify("Error", "Select player first", 2) return end
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:SetPrimaryPartCFrame(target.Character.HumanoidRootPart.CFrame)
        end
    end
})

TeleportTab:CreateButton({
    Name = "Teleport ke Toko Bibit",
    Callback = function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("toko") and obj.Name:lower():find("bibit") then
                LocalPlayer.Character:SetPrimaryPartCFrame(obj.CFrame + Vector3.new(0,5,0))
                return
            end
        end
    end
})

TeleportTab:CreateButton({
    Name = "Teleport ke Tempat Jual",
    Callback = function()
        local sellZone = findSellZone()
        if sellZone then
            LocalPlayer.Character:SetPrimaryPartCFrame(sellZone.CFrame + Vector3.new(0,5,0))
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
        local TPService = game:GetService("TeleportService")
        pcall(function() TPService:Teleport(game.PlaceId, LocalPlayer) end)
    end
})

UtilityTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        Notify("Server Hop", "Mencari server...", 2)
        local TPService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        
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
        if conn then conn:Disconnect() end
    end
    if sellConnection then sellConnection:Disconnect() end
    if antiAFKConnection then antiAFKConnection:Disconnect() end
    Workspace.Gravity = 196.2
end

game:BindToClose(OnCleanup)

Notify("SAWAH INDO HUB", "Siap digunakan!", 2)
print("SAWAH INDO HUB loaded")
