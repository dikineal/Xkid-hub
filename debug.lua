--====================================================
-- XKID HUB | SAWAH INDO PRO+
--====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "PRO+ EDITION",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKIDHub",
        FileName = "SawahConfig"
    },
    KeySystem = false
})

--====================================================
-- TABS
--====================================================

local FarmingTab    = Window:CreateTab("🌾 Farming", 4483362458)
local ProtectTab    = Window:CreateTab("🛡 Protection", 4483362458)
local TeleportTab   = Window:CreateTab("📍 Teleport", 4483362458)
local UtilityTab    = Window:CreateTab("⚙ Utility", 4483362458)
local ConfigTab     = Window:CreateTab("💾 Config", 4483362458)

--====================================================
-- SETTINGS STATE
--====================================================

local Settings = {
    AutoFarm = false,
    AutoSell = false,
    AutoBuy  = false,
    LightningProtection = true,
    AntiAFK  = true,
    AutoShower = false,
}

local SeedName = "Bibit Padi"
local FarmSpeed = 0.18

--====================================================
-- PLACEHOLDER FUNCTIONS (ISI SESUAI GAME-MU)
--====================================================

local function BuySeeds()
    -- TODO: isi logika beli bibit
end

local function SellCrops()
    -- TODO: isi logika jual hasil
end

local function ScanFarm()
    -- TODO: scan area sawah
end

local function TeleportNPC()
    -- TODO: teleport ke NPC
end

local function TeleportSafe()
    -- TODO: teleport safe zone
end

local function TeleportFarm()
    -- TODO: teleport ke tengah sawah
end

--====================================================
-- 🌾 FARMING TAB
--====================================================

FarmingTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoFarm = v
    end
})

FarmingTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoSell = v
    end
})

FarmingTab:CreateToggle({
    Name = "Auto Buy",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoBuy = v
    end
})

FarmingTab:CreateDropdown({
    Name = "Seed Selector",
    Options = {"Bibit Padi","Bibit Jagung","Bibit Tomat","Bibit Terong"},
    CurrentOption = "Bibit Padi",
    Callback = function(v)
        SeedName = v
    end
})

FarmingTab:CreateSlider({
    Name = "Farm Speed",
    Range = {0.05,0.5},
    Increment = 0.01,
    CurrentValue = 0.18,
    Callback = function(v)
        FarmSpeed = v
    end
})

FarmingTab:CreateButton({
    Name = "Scan Farm Area",
    Callback = function()
        ScanFarm()
    end
})

--====================================================
-- 🛡 PROTECTION TAB
--====================================================

ProtectTab:CreateToggle({
    Name = "Lightning Protection",
    CurrentValue = true,
    Callback = function(v)
        Settings.LightningProtection = v
    end
})

ProtectTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Callback = function(v)
        Settings.AntiAFK = v
    end
})

ProtectTab:CreateToggle({
    Name = "Auto Mandi",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoShower = v
    end
})

--====================================================
-- 📍 TELEPORT TAB
--====================================================

TeleportTab:CreateButton({
    Name = "NPC",
    Callback = function()
        TeleportNPC()
    end
})

TeleportTab:CreateButton({
    Name = "Safe Zone",
    Callback = function()
        TeleportSafe()
    end
})

TeleportTab:CreateButton({
    Name = "Farm Center",
    Callback = function()
        TeleportFarm()
    end
})

--====================================================
-- ⚙ UTILITY TAB
--====================================================

UtilityTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
})

UtilityTab:CreateButton({
    Name = "FPS Boost",
    Callback = function()
        for _,v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
            end
        end
        game:GetService("Lighting").GlobalShadows = false
    end
})

UtilityTab:CreateButton({
    Name = "Lightning Detector",
    Callback = function()
        print("Lightning detector active (implement logic)")
    end
})

--====================================================
-- 💾 CONFIG TAB
--====================================================

ConfigTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        Rayfield:Notify({
            Title = "Config",
            Content = "Config disimpan otomatis oleh Rayfield",
            Duration = 4
        })
    end
})

ConfigTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        Rayfield:Notify({
            Title = "Config",
            Content = "Config akan dimuat saat script dijalankan ulang",
            Duration = 4
        })
    end
})

--====================================================
-- MAIN LOOP
--====================================================

task.spawn(function()
    while task.wait(1) do
        if Settings.AutoFarm then
            if Settings.AutoBuy then
                BuySeeds()
            end

            ScanFarm()

            if Settings.AutoSell then
                SellCrops()
            end
        end
    end
end)