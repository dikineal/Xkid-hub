--====================================================
-- XKID HUB | SAWAH INDO
--====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "GABUT EDITION 🔥",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local MainTab = Window:CreateTab("🌾 Farming", 4483362458)

--====================================================
-- SERVICES
--====================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer

--====================================================
-- REMOTES
--====================================================

local Remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TutorialRemotes")

local PlantCrop = Remotes:WaitForChild("PlantCrop")
local RequestShop = Remotes:WaitForChild("RequestShop")
local RequestSell = Remotes:WaitForChild("RequestSell")
local LightningStrike = Remotes:WaitForChild("LightningStrike")

--====================================================
-- SETTINGS
--====================================================

local Settings = {
    AutoFarm = false,
    AutoSell = true,
    AutoBuy = true,
    LightningProtection = true,
    AntiAFK = true
}

local SeedName = "Bibit Padi"
local BuyAmount = 10

local FarmMin = Vector3.new(-125,39,-275)
local FarmMax = Vector3.new(-95,39,-250)

local GridStep = 2
local PlantDelay = 0.18

local NPCPosition = Vector3.new(-110,39,-260)

local SafePositions = {
    Vector3.new(-80,50,-200),
    Vector3.new(-75,50,-205),
    Vector3.new(-85,50,-195)
}

local DangerRadius = 40

--====================================================
-- UTIL
--====================================================

local function GetCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function GetRoot()
    return GetCharacter():WaitForChild("HumanoidRootPart")
end

local function Teleport(pos)
    GetRoot().CFrame = CFrame.new(pos)
end

local function GetSafePosition()
    return SafePositions[math.random(1,#SafePositions)]
end

--====================================================
-- ANTI AFK
--====================================================

if Settings.AntiAFK then
    Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

--====================================================
-- LIGHTNING PROTECTION
--====================================================

LightningStrike.OnClientEvent:Connect(function(data)

    if not Settings.LightningProtection then return end
    if not data then return end
    if not data.Position then return end

    local playerPos = GetRoot().Position
    local distance = (playerPos - data.Position).Magnitude

    if distance <= DangerRadius then

        Teleport(GetSafePosition())

        task.wait(3)

        Teleport(NPCPosition)

    end

end)

--====================================================
-- FUNCTIONS
--====================================================

local function BuySeeds()

    if not Settings.AutoBuy then return end

    RequestShop:InvokeServer(
        "BUY",
        SeedName,
        BuyAmount
    )

end

local function SellCrops()

    if not Settings.AutoSell then return end

    local result = RequestSell:InvokeServer("GET_LIST")

    if result and result.Items then

        for _,item in ipairs(result.Items) do

            if item.Owned and item.Owned > 0 then

                RequestSell:InvokeServer(
                    "SELL",
                    item.Name,
                    item.Owned
                )

            end

        end

    end

end

local function ScanFarm()

    for x = FarmMin.X, FarmMax.X, GridStep do
        for z = FarmMin.Z, FarmMax.Z, GridStep do

            if not Settings.AutoFarm then return end

            local pos = Vector3.new(x, FarmMin.Y, z)

            PlantCrop:FireServer(pos)

            task.wait(PlantDelay)

        end
    end

end

--====================================================
-- UI CONTROLS
--====================================================

MainTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Callback = function(Value)
        Settings.AutoFarm = Value
    end
})

MainTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = true,
    Callback = function(Value)
        Settings.AutoSell = Value
    end
})

MainTab:CreateToggle({
    Name = "Lightning Protection",
    CurrentValue = true,
    Callback = function(Value)
        Settings.LightningProtection = Value
    end
})

--====================================================
-- MAIN LOOP
--====================================================

task.spawn(function()

    while true do

        task.wait(1)

        if Settings.AutoFarm then

            Teleport(NPCPosition)

            task.wait(1)

            BuySeeds()

            task.wait(1)

            ScanFarm()

            task.wait(2)

            SellCrops()

        end

    end

end)