--====================================================
-- XKID_HUB
-- Luna Interface Suite
--====================================================

-- Load Library
local Luna = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/main/source.lua"
))()

-- Services
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Window
local Window = Luna:CreateWindow({
    Name = "XKID_HUB",
    Subtitle = "Luna Interface",
    LoadingEnabled = true
})

-- Tabs
local Main = Window:CreateTab({
    Name = "Main",
    Icon = "home"
})

local Utility = Window:CreateTab({
    Name = "Utility",
    Icon = "settings"
})

--====================================================
-- ANTI AFK
--====================================================

local AntiAFK = true

Main:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
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
    CurrentValue = false,
    Callback = function(v)
        Flying = v
        if v then
            StartFly()
        end
    end
})

Main:CreateSlider({
    Name = "Fly Speed",
    Range = {20,150},
    Increment = 5,
    CurrentValue = 60,
    Callback = function(v)
        FlySpeed = v
    end
})

--====================================================
-- UTILITY
--====================================================

Utility:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId,Player)
    end
})