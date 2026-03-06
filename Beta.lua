--[[
    SAWAH INDO HUB - FULL VERSION
    Fitur: Auto Farming, Teleport, Player Control
    Game: SAWAH Indo [Voice Chat]
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

-- Deteksi platform
local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled

-- UI Window
local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO BY:XKID_BELUM_TIDUR HUB",
    LoadingTitle = "SAWAH INDO",
    LoadingSubtitle = "Full Features",
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
local TeleportTab = Window:CreateTab("📍 Teleport", nil)
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

-- Daftar bibit
local seeds = {
    ["Bibit Padi"] = {level = 0, price = 5},
    ["Bibit Jagung"] = {level = 20, price = 15},
    ["Bibit Tomat"] = {level = 40, price = 25},
    ["Bibit Terong"] = {level = 60, price = 40},
    ["Bibit Strawberry"] = {level = 80, price = 60},
    ["Bibit Savit"] = {level = 80, price = 1000},
    ["Bibit Durian"] = {level = 120, price = 2000}
}

-- Lokasi-lokasi penting (akan diisi auto scan)
local Locations = {
    tokoBibit = nil,
    tempatJual = nil,
    npcs = {},
    lahan = {}
}

------------------------------------------------
-- FUNGSI SCANNER OTOMATIS
------------------------------------------------
local function scanLocations()
    Locations = {tokoBibit = nil, tempatJual = nil, npcs = {}, lahan = {}}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        
        -- Cari toko bibit
        if (name:find("toko") and name:find("bibit")) or name:find("seed") then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                Locations.tokoBibit = obj
            end
        end
        
        -- Cari tempat jual
        if name:find("jual") or name:find("sell") or name:find("market") then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                Locations.tempatJual = obj
            end
        end
        
        -- Cari NPC
        if obj.ClassName == "Model" and obj:FindFirstChild("Humanoid") and obj ~= LocalPlayer.Character then
            table.insert(Locations.npcs, obj)
        end
        
        -- Cari lahan/tanah
        if (name:find("tanah") or name:find("lahan") or name:find("field") or name:find("soil")) and obj:IsA("BasePart") then
            table.insert(Locations.lahan, obj)
        end
    end
    
    -- Tampilkan hasil
    print("=== HASIL SCAN LOKASI ===")
    print("Toko Bibit:", Locations.tokoBibit and Locations.tokoBibit.Name or "Tidak ditemukan")
    print("Tempat Jual:", Locations.tempatJual and Locations.tempatJual.Name or "Tidak ditemukan")
    print("NPC Ditemukan:", #Locations.npcs)
    print("Lahan Ditemukan:", #Locations.lahan)
    
    return Locations
end

-- Fungsi teleport aman
local function safeTeleport(target)
    if not target then return false end
    
    local cframe
    if target:IsA("BasePart") then
        cframe = target.CFrame
    elseif target:IsA("Model") and target:FindFirstChild("HumanoidRootPart") then
        cframe = target.HumanoidRootPart.CFrame
    elseif target:IsA("Model") and target:FindFirstChild("Head") then
        cframe = target.Head.CFrame
    else
        return false
    end
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe + Vector3.new(0, 3, 0)
        return true
    end
    return false
end

-- Fungsi interaksi dengan object
local function interactWith(obj)
    if not obj then return end
    
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
            end
        end
    end)
    
    -- Metode 3: ProximityPrompt
    pcall(function()
        for _, prompt in pairs(obj:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt:InputHoldBegin()
                wait(0.2)
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
    Name = "🔄 Scan Ulang Lokasi",
    Callback = function()
        scanLocations()
        Notify("Scan", "Lokasi telah diupdate", 2)
    end
})

MainTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end
})

------------------------------------------------
-- FARMING TAB
------------------------------------------------
local farmingConnections = {}

local function startFarming()
    for _, conn in pairs(farmingConnections) do
        if conn then conn:Disconnect() end
    end
    
    -- Auto Plant
    if _G.AutoPlant then
        farmingConnections.plant = RunService.Heartbeat:Connect(function()
            if not _G.AutoPlant or not LocalPlayer.Character then return end
            if #Locations.lahan == 0 then scanLocations() end
            
            for _, land in pairs(Locations.lahan) do
                local dist = (land.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist < _G.FarmRadius then
                    LocalPlayer.Character.Humanoid:MoveTo(land.Position)
                    if dist < 5 then
                        interactWith(land)
                        wait(0.3)
                    end
                    break
                end
            end
        end)
    end
    
    -- Auto Harvest
    if _G.AutoHarvest then
        farmingConnections.harvest = RunService.Heartbeat:Connect(function()
            if not _G.AutoHarvest or not LocalPlayer.Character then return end
            
            for seedName in pairs(seeds) do
                local keyword = seedName:gsub("Bibit ", ""):lower()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name:lower():find(keyword) and obj:IsA("BasePart") then
                        local dist = (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        if dist < 10 then
                            LocalPlayer.Character.Humanoid:MoveTo(obj.Position)
                            if dist < 5 then
                                interactWith(obj)
                                wait(0.2)
                            end
                        end
                    end
                end
            end
        end)
    end
end

-- Auto Sell
local sellConnection
local function startAutoSell()
    if sellConnection then sellConnection:Disconnect() end
    if not _G.AutoSell then return end
    
    sellConnection = RunService.Heartbeat:Connect(function()
        if not _G.AutoSell or not LocalPlayer.Character then return end
        if not Locations.tempatJual then scanLocations() end
        
        if Locations.tempatJual then
            local dist = (Locations.tempatJual.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if dist > 5 then
                LocalPlayer.Character.Humanoid:MoveTo(Locations.tempatJual.Position)
            else
                interactWith(Locations.tempatJual)
                wait(1)
            end
        end
    end)
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

FarmTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoSell = v
        startAutoSell()
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

------------------------------------------------
-- TELEPORT TAB
------------------------------------------------
-- Fungsi teleport dengan pilihan
TeleportTab:CreateButton({
    Name = "🏪 Teleport ke Toko Bibit",
    Callback = function()
        if not Locations.tokoBibit then scanLocations() end
        if Locations.tokoBibit then
            safeTeleport(Locations.tokoBibit)
            Notify("Teleport", "Ke toko bibit", 1)
        else
            Notify("Error", "Toko bibit tidak ditemukan", 2)
        end
    end
})

TeleportTab:CreateButton({
    Name = "💰 Teleport ke Tempat Jual",
    Callback = function()
        if not Locations.tempatJual then scanLocations() end
        if Locations.tempatJual then
            safeTeleport(Locations.tempatJual)
            Notify("Teleport", "Ke tempat jual", 1)
        else
            Notify("Error", "Tempat jual tidak ditemukan", 2)
        end
    end
})

-- Dropdown NPC
local npcDropdown = TeleportTab:CreateDropdown({
    Name = "Pilih NPC",
    Options = {},
    CurrentOption = {""},
    Callback = function(selected)
        if selected and #selected > 0 then
            for _, npc in pairs(Locations.npcs) do
                if npc.Name == selected[1] then
                    safeTeleport(npc)
                    break
                end
            end
        end
    end
})

local function updateNPCDropdown()
    local npcNames = {}
    for _, npc in pairs(Locations.npcs) do
        table.insert(npcNames, npc.Name)
    end
    npcDropdown:SetOptions(npcNames)
end

TeleportTab:CreateButton({
    Name = "🔄 Refresh NPC List",
    Callback = function()
        scanLocations()
        updateNPCDropdown()
        Notify("NPC", #Locations.npcs .. " ditemukan", 2)
    end
})

-- Teleport ke lahan
TeleportTab:CreateButton({
    Name = "🌱 Teleport ke Lahan Pertama",
    Callback = function()
        if #Locations.lahan > 0 then
            safeTeleport(Locations.lahan[1])
        else
            scanLocations()
            if #Locations.lahan > 0 then
                safeTeleport(Locations.lahan[1])
            else
                Notify("Error", "Tidak ada lahan", 2)
            end
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

UtilityTab:CreateInput({
    Name = "Load Script",
    PlaceholderText = "URL script...",
    Callback = function(url)
        if url:match("^https?://") then
            pcall(function() loadstring(game:HttpGet(url))() end)
        end
    end
})

------------------------------------------------
-- INITIAL SCAN
------------------------------------------------
wait(1)
scanLocations()
updateNPCDropdown()
Notify("SAWAH INDO HUB", "Siap digunakan! " .. #Locations.lahan .. " lahan ditemukan", 3)

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

print("SAWAH INDO HUB - FULL VERSION LOADED")
