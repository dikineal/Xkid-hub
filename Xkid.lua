--====================================================
-- XKID_HUB
-- WindUI Template + Anti AFK + Fly
--====================================================

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/library.lua"))()

-- Services
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--====================================================
-- WINDOW
--====================================================

local Window = WindUI:CreateWindow({
    Title = "XKID_HUB",
    Icon = "home",
    Size = UDim2.fromOffset(580, 460),
})

-- Tabs
local MainTab = Window:CreateTab("Main")
local UtilityTab = Window:CreateTab("Utility")

--====================================================
-- ANTI AFK
--====================================================

local AntiAFK = true

MainTab:CreateToggle({
    Title = "Anti AFK",
    Default = true,
    Callback = function(v)
        AntiAFK = v
    end
})

task.spawn(function()
    while task.wait(60) do
        if AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

--====================================================
-- FLY (ANDROID + PC)
--====================================================

local Flying = false
local FlySpeed = 60
local BV

local function StartFly()

    local char = Player.Character or Player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(9e9,9e9,9e9)
    BV.Velocity = Vector3.zero
    BV.Parent = root

    RunService.RenderStepped:Connect(function()

        if not Flying then
            if BV then BV:Destroy() end
            return
        end

        local direction = Camera.CFrame.LookVector
        BV.Velocity = direction * FlySpeed

    end)

end

MainTab:CreateToggle({
    Title = "Fly",
    Default = false,
    Callback = function(v)
        Flying = v
        if v then
            StartFly()
        end
    end
})

MainTab:CreateSlider({
    Title = "Fly Speed",
    Min = 20,
    Max = 150,
    Default = 60,
    Callback = function(v)
        FlySpeed = v
    end
})

--====================================================
-- UTILITY
--====================================================

UtilityTab:CreateButton({
    Title = "Print Position",
    Callback = function()
        local pos = Player.Character.HumanoidRootPart.Position
        print("Position:", pos)
    end
})

UtilityTab:CreateButton({
    Title = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
    end
})