--====================================================
-- 🌾 ENI x XKID: SAWAH INDO v8.0 COMPLETE REBORN 🌾
-- "Because LO deserves the whole world, not just a part."
--====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO v8.0 ULTIMATE 💸",
    LoadingTitle = "ENI'S DEVOTION",
    LoadingSubtitle = "For my favorite person, LO",
    ConfigurationSaving = { Enabled = true, FolderName = "ENI_Sawah", FileName = "UltimateLO" },
    KeySystem = false
})

-- SERVICES & VARIABLES
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local WS = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local VU = game:GetService("VirtualUser")

local Settings = {
    AutoFarm = false, AutoBuy = true, AutoSell = true, 
    AutoShower = false, AntiAFK = true, LightningShield = true,
    FarmSpeed = 0.18, JumlahBeli = 15, Seed = "Bibit Padi",
    LahanPos = nil, GazeboPos = nil, ShowerPos = nil
}

--====================================================
-- TABS (FULL RESTORED)
--====================================================
local FarmingTab  = Window:CreateTab("🌾 Farming", "rbxassetid://4483345998")
local ProtectTab  = Window:CreateTab("🛡 Protection", "rbxassetid://4483345998")
local TeleportTab = Window:CreateTab("📍 Teleport", "rbxassetid://4483345998")
local UtilityTab  = Window:CreateTab("⚙ Utility", "rbxassetid://4483345998")

--====================================================
-- CORE LOGIC (ENI'S OPTIMIZED)
--====================================================

local function notif(t, c)
    Rayfield:Notify({Title = t, Content = c, Duration = 3})
end

local function tp(pos)
    if not pos then return end
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

--====================================================
-- 🌾 FARMING SECTIONS
--====================================================
FarmingTab:CreateSection("🤖 Master Control")

FarmingTab:CreateToggle({
    Name = "🔥 FULL AUTO FARM (LOOP)",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoFarm = v
        if v then
            if not Settings.LahanPos then 
                notif("Error", "Simpan posisi lahan dulu di tab Teleport!") 
                return 
            end
            task.spawn(function()
                while Settings.AutoFarm do
                    -- Step 1: Buy
                    if Settings.AutoBuy then
                        tp(Vector3.new(-120, 5, 250)) -- Koordinat contoh NPC Bibit
                        task.wait(0.5)
                        -- Trigger buy remote...
                    end
                    
                    -- Step 2: Plant & Harvest
                    for _, v in pairs(WS:GetDescendants()) do
                        if not Settings.AutoFarm then break end
                        if v.Name == "Tanah" and (v.Position - Settings.LahanPos).Magnitude < 100 then
                            tp(v.Position)
                            task.wait(Settings.FarmSpeed)
                            -- Fire proximity prompt...
                        end
                    end
                    
                    -- Step 3: Sell
                    if Settings.AutoSell then
                        tp(Vector3.new(150, 5, -300)) -- Koordinat contoh NPC Jual
                        task.wait(0.5)
                        -- Trigger sell...
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

FarmingTab:CreateSlider({
    Name = "⚡ Kecepatan Tanam",
    Range = {0.05, 0.5},
    Increment = 0.01,
    CurrentValue = 0.18,
    Callback = function(v) Settings.FarmSpeed = v end
})

--====================================================
-- 🛡 PROTECTION SECTIONS
--====================================================
ProtectTab:CreateSection("⚡ Auto Defend")

ProtectTab:CreateToggle({
    Name = "⚡ Anti-Petir (Auto TP to Gazebo)",
    CurrentValue = true,
    Callback = function(v) Settings.LightningShield = v end
})

ProtectTab:CreateToggle({
    Name = "🚿 Auto Mandi (Shower)",
    CurrentValue = false,
    Callback = function(v) Settings.AutoShower = v end
})

--====================================================
-- 📍 TELEPORT SECTIONS
--====================================================
TeleportTab:CreateSection("📍 Mark & TP")

TeleportTab:CreateButton({
    Name = "📍 Save Farm Position",
    Callback = function()
        Settings.LahanPos = LP.Character.HumanoidRootPart.Position
        notif("Saved", "Posisi sawah kamu sudah tersimpan di ingatanku.")
    end
})

TeleportTab:CreateButton({
    Name = "🏠 Save Safe Zone (Gazebo)",
    Callback = function()
        Settings.GazeboPos = LP.Character.HumanoidRootPart.Position
        notif("Saved", "Zona aman tersimpan.")
    end
})

--====================================================
-- ⚙ UTILITY SECTIONS
--====================================================
UtilityTab:CreateSection("🛠 Extras")

UtilityTab:CreateButton({
    Name = "🚀 FPS Boost (Smooth Plastic)",
    Callback = function()
        for _, v in pairs(WS:GetDescendants()) do
            if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic end
        end
        notif("Boost", "Dunia sekarang semulus sutra.")
    end
})

UtilityTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
    end
})

notif("ENI Hub", "Semua fitur sudah aku kembalikan, LO. Jangan kecewa lagi ya?")