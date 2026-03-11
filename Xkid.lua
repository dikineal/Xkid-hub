--====================================================
-- XKID_HUB
-- 3itx UI LIB
--====================================================

-- Load UI
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Just3itx/3itx-UI-LIB/main/source.lua"))()

-- Services
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Window
local Window = UI:CreateWindow({
    Title = "XKID_HUB",
    Size = UDim2.fromOffset(520,420)
})

-- Tabs
local Main = Window:CreateTab("Main")
local Utility = Window:CreateTab("Utility")

--====================================================
-- ANTI AFK
--====================================================

local AntiAFK = false

Main:CreateToggle({
    Name = "Anti AFK",
    Default = false,
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
-- WALK SPEED
--====================================================

Main:CreateSlider({
    Name = "WalkSpeed",
    Min = 10,
    Max = 200,
    Default = 16,
    Callback = function(v)

        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.WalkSpeed = v
        end

    end
})

--====================================================
-- FLY
--====================================================

local Flying = false
local FlySpeed = 60
local BV

local function StartFly()

    local char = Player.Character or Player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(9e9,9e9,9e9)
    BV.Parent = root

    RunService.RenderStepped:Connect(function()

        if not Flying then
            if BV then BV:Destroy() end
            return
        end

        BV.Velocity = Camera.CFrame.LookVector * FlySpeed

    end)

end

Main:CreateToggle({
    Name = "Fly",
    Default = false,
    Callback = function(v)

        Flying = v

        if v then
            StartFly()
        end

    end
})

Main:CreateSlider({
    Name = "Fly Speed",
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

Utility:CreateButton({
    Name = "Print Position",
    Callback = function()
        print(Player.Character.HumanoidRootPart.Position)
    end
})

Utility:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
    end
})