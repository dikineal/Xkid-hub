--====================================================================--
--     XKID SAWAH INDO HUB - VERSION FINAL (PASTI JALAN)
--     Game: SAWAH Indo [Voice Chat]
--     Fitur: Teleport, Auto Farm, Debug, Player Control
--====================================================================--

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Buat Window
local Window = Rayfield:CreateWindow({
    Name = "🌾 XKID SAWAH INDO HUB",
    LoadingTitle = "SAWAH INDO HUB",
    LoadingSubtitle = "Version Final",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKidSawahIndo",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TPService = game:GetService("TeleportService")

-- Notifikasi
local function Notif(title, msg, waktu)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = msg,
        Duration = waktu or 3
    })
end

--====================================================================--
--                    TAB MENU
--====================================================================--
local TeleportTab = Window:CreateTab("📍 TELEPORT", nil)
local FarmTab = Window:CreateTab("🌾 AUTO FARM", nil)
local PlayerTab = Window:CreateTab("👤 PLAYER", nil)
local DebugTab = Window:CreateTab("🔍 DEBUG", nil)
local UtilityTab = Window:CreateTab("⚙ UTILITY", nil)

--====================================================================--
--                    VARIABEL GLOBAL
--====================================================================--
_G.AutoPlant = false
_G.AutoHarvest = false
_G.AutoSell = false
_G.AutoBuy = false
_G.WalkSpeed = 16
_G.JumpPower = 50
_G.FarmRadius = 30
_G.PlantDelay = 1
_G.HarvestDelay = 1

-- Database NPC dari hasil debug lo
local NPC = {
    bibit = "npcbibit",
    penjual = "npcpenjual",
    alat = "npcalat",
    telur = "NPCPedagangTelur",
    sawit = "NPCPedagangSawit"
}

local LAHAN = "Tanah"
local TANAMAN = {"Tomat", "Jagung", "Padi", "Strawberry", "Terong", "Durian", "Sawit"}

--====================================================================--
--                    FUNGSI UTILITY
--====================================================================--

-- Fungsi dapat posisi object
local function GetObjectPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        if obj:FindFirstChild("HumanoidRootPart") then
            return obj.HumanoidRootPart.Position
        elseif obj:FindFirstChild("Head") then
            return obj.Head.Position
        elseif obj:FindFirstChild("Torso") then
            return obj.Torso.Position
        end
    end
    return nil
end

-- Fungsi teleport
local function TeleportKe(namaObject)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == namaObject then
            local pos = GetObjectPosition(obj)
            if pos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
                Notif("Teleport", "Ke " .. namaObject, 1)
                return true
            end
        end
    end
    Notif("Gagal", namaObject .. " tidak ditemukan", 2)
    return false
end

-- Fungsi interaksi
local function Interaksi(obj)
    if not obj then return end
    
    -- Method 1: Touch
    pcall(function()
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
        wait(0.1)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
    end)
    
    -- Method 2: ClickDetector
    pcall(function()
        for _, v in pairs(obj:GetDescendants()) do
            if v:IsA("ClickDetector") then
                v:MouseClick()
            end
        end
    end)
    
    -- Method 3: ProximityPrompt
    pcall(function()
        for _, v in pairs(obj:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                v:InputHoldBegin()
                wait(0.2)
                v:InputHoldEnd()
            end
        end
    end)
end

-- Fungsi cari object terdekat
local function CariTerdekat(namaPattern)
    if not LocalPlayer.Character then return nil end
    
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local terdekat = nil
    local jarakTerdekat = 999999
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:find(namaPattern) then
            local pos = GetObjectPosition(obj)
            if pos then
                local jarak = (myPos - pos).Magnitude
                if jarak < jarakTerdekat then
                    jarakTerdekat = jarak
                    terdekat = obj
                end
            end
        end
    end
    return terdekat, jarakTerdekat
end

--====================================================================--
--                    TELEPORT TAB
--====================================================================--
TeleportTab:CreateButton({
    Name = "🛒 npcbibit (BELI BIBIT)",
    Callback = function() TeleportKe("npcbibit") end
})

TeleportTab:CreateButton({
    Name = "💰 npcpenjual (JUAL HASIL)",
    Callback = function() TeleportKe("npcpenjual") end
})

TeleportTab:CreateButton({
    Name = "🔧 npcalat (BELI ALAT)",
    Callback = function() TeleportKe("npcalat") end
})

TeleportTab:CreateButton({
    Name = "🥚 NPCPedagangTelur",
    Callback = function() TeleportKe("NPCPedagangTelur") end
})

TeleportTab:CreateButton({
    Name = "🌴 NPCPedagangSawit",
    Callback = function() TeleportKe("NPCPedagangSawit") end
})

TeleportTab:CreateButton({
    Name = "🌾 Teleport ke Lahan Terdekat",
    Callback = function()
        local lahan, jarak = CariTerdekat(LAHAN)
        if lahan then
            local pos = GetObjectPosition(lahan)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
            Notif("Teleport", "Ke lahan terdekat", 1)
        end
    end
})

TeleportTab:CreateInput({
    Name = "📌 Teleport ke Koordinat",
    PlaceholderText = "x y z",
    Callback = function(input)
        local coords = {}
        for num in input:gmatch("%-?%d+%.?%d*") do
            table.insert(coords, tonumber(num))
        end
        if #coords >= 3 and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(coords[1], coords[2], coords[3])
        end
    end
})

--====================================================================--
--                    AUTO FARM TAB
--====================================================================--
local FarmLoop = nil
local SellLoop = nil

-- Fungsi start auto plant
local function StartAutoPlant()
    if FarmLoop then FarmLoop:Disconnect() end
    if not _G.AutoPlant then return end
    
    FarmLoop = RunService.Heartbeat:Connect(function()
        if not _G.AutoPlant or not LocalPlayer.Character then return end
        
        local lahan, jarak = CariTerdekat(LAHAN)
        if lahan and jarak then
            if jarak > 5 then
                local pos = GetObjectPosition(lahan)
                LocalPlayer.Character.Humanoid:MoveTo(pos)
            else
                Interaksi(lahan)
                wait(_G.PlantDelay)
            end
        end
    end)
end

-- Fungsi start auto harvest
local function StartAutoHarvest()
    if FarmLoop then FarmLoop:Disconnect() end
    if not _G.AutoHarvest then return end
    
    FarmLoop = RunService.Heartbeat:Connect(function()
        if not _G.AutoHarvest or not LocalPlayer.Character then return end
        
        for _, tanaman in ipairs(TANAMAN) do
            local obj, jarak = CariTerdekat(tanaman)
            if obj and jarak and jarak < 15 then
                if jarak > 4 then
                    local pos = GetObjectPosition(obj)
                    LocalPlayer.Character.Humanoid:MoveTo(pos)
                else
                    Interaksi(obj)
                    wait(_G.HarvestDelay)
                end
                break
            end
        end
    end)
end

-- Fungsi start auto sell
local function StartAutoSell()
    if SellLoop then SellLoop:Disconnect() end
    if not _G.AutoSell then return end
    
    SellLoop = RunService.Heartbeat:Connect(function()
        if not _G.AutoSell or not LocalPlayer.Character then return end
        
        local penjual, jarak = CariTerdekat("npcpenjual")
        if penjual and jarak then
            if jarak > 5 then
                local pos = GetObjectPosition(penjual)
                LocalPlayer.Character.Humanoid:MoveTo(pos)
            else
                Interaksi(penjual)
                wait(2)
            end
        end
    end)
end

FarmTab:CreateToggle({
    Name = "🌱 AUTO TANAM",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoPlant = v
        if v then
            Notif("Auto Tanam", "AKTIF", 1)
            StartAutoPlant()
        else
            if FarmLoop then FarmLoop:Disconnect() end
            Notif("Auto Tanam", "MATI", 1)
        end
    end
})

FarmTab:CreateToggle({
    Name = "🌽 AUTO PANEN",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoHarvest = v
        if v then
            Notif("Auto Panen", "AKTIF", 1)
            StartAutoHarvest()
        else
            if FarmLoop then FarmLoop:Disconnect() end
            Notif("Auto Panen", "MATI", 1)
        end
    end
})

FarmTab:CreateToggle({
    Name = "💰 AUTO JUAL",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoSell = v
        if v then
            Notif("Auto Jual", "AKTIF", 1)
            StartAutoSell()
        else
            if SellLoop then SellLoop:Disconnect() end
            Notif("Auto Jual", "MATI", 1)
        end
    end
})

FarmTab:CreateSlider({
    Name = "⏱️ DELAY TANAM (detik)",
    Range = {0.5, 5},
    Increment = 0.5,
    CurrentValue = 1,
    Callback = function(v) _G.PlantDelay = v end
})

FarmTab:CreateSlider({
    Name = "⏱️ DELAY PANEN (detik)",
    Range = {0.5, 5},
    Increment = 0.5,
    CurrentValue = 1,
    Callback = function(v) _G.HarvestDelay = v end
})

--====================================================================--
--                    PLAYER TAB
--====================================================================--
local SpeedLoop

PlayerTab:CreateSlider({
    Name = "🚶 WALK SPEED",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        _G.WalkSpeed = v
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
})

PlayerTab:CreateSlider({
    Name = "🦘 JUMP POWER",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        _G.JumpPower = v
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v end
        end
    end
})

PlayerTab:CreateToggle({
    Name = "🔄 INFINITE JUMP",
    CurrentValue = false,
    Callback = function(v)
        _G.InfiniteJump = v
        if v then
            UIS.JumpRequest:Connect(function()
                if _G.InfiniteJump and LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        end
    end
})

PlayerTab:CreateToggle({
    Name = "🛡️ ANTI AFK",
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

--====================================================================--
--                    DEBUG TAB (SEDERHANA TAPI JALAN)
--====================================================================--
DebugTab:CreateButton({
    Name = "🔍 SCAN OBJECT DI SEKITAR",
    Callback = function()
        print("\n===== SCAN DIMULAI =====")
        if not LocalPlayer.Character then
            print("ERROR: Karakter tidak ada")
            return
        end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        print("Posisi: " .. tostring(myPos))
        print("")
        
        local count = 0
        for _, obj in pairs(Workspace:GetDescendants()) do
            local pos = GetObjectPosition(obj)
            if pos then
                local jarak = (myPos - pos).Magnitude
                if jarak < 100 then
                    count = count + 1
                    print(count .. ". " .. obj.Name .. " - " .. math.floor(jarak) .. " stud")
                end
            end
        end
        
        print("\nTotal object: " .. count)
        print("===== SCAN SELESAI =====")
    end
})

DebugTab:CreateButton({
    Name = "👥 SCAN NPC",
    Callback = function()
        print("\n===== SCAN NPC =====")
        if not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local count = 0
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= LocalPlayer.Character then
                local pos = GetObjectPosition(obj)
                if pos then
                    local jarak = (myPos - pos).Magnitude
                    count = count + 1
                    print(count .. ". " .. obj.Name .. " - " .. math.floor(jarak) .. " stud")
                end
            end
        end
        
        print("Total NPC: " .. count)
    end
})

DebugTab:CreateInput({
    Name = "🔎 CARI OBJECT",
    PlaceholderText = "Nama object...",
    Callback = function(input)
        if input == "" then return end
        
        print("\n===== MENCARI: " .. input .. " =====")
        if not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local found = 0
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find(input:lower()) then
                local pos = GetObjectPosition(obj)
                if pos then
                    local jarak = (myPos - pos).Magnitude
                    found = found + 1
                    print(found .. ". " .. obj.Name .. " - " .. math.floor(jarak) .. " stud")
                end
            end
        end
        
        print("Ditemukan: " .. found)
    end
})

--====================================================================--
--                    UTILITY TAB
--====================================================================--
UtilityTab:CreateButton({
    Name = "🔄 REJOIN SERVER",
    Callback = function()
        TPService:Teleport(game.PlaceId, LocalPlayer)
    end
})

UtilityTab:CreateButton({
    Name = "🌐 SERVER HOP",
    Callback = function()
        Notif("Server Hop", "Mencari server...", 2)
        local success, servers = pcall(function()
            local res = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")
            return HttpService:JSONDecode(res)
        end)
        if success and servers and servers.data then
            for _, s in ipairs(servers.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TPService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
    end
})

UtilityTab:CreateButton({
    Name = "💀 RESET CHARACTER",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end
})

--====================================================================--
--                    AUTO LOAD & NOTIF
--====================================================================--
Notif("XKID SAWAH INDO HUB", "Loaded! Buka tab TELEPORT", 3)

print("✅ SCRIPT SIAP DIGUNAKAN!")
print("📍 NPC yang tersedia:")
print("   - npcbibit (Beli bibit)")
print("   - npcpenjual (Jual hasil)")
print("   - npcalat (Beli alat)")
print("   - NPCPedagangTelur")
print("   - NPCPedagangSawit")
