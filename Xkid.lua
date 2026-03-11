--====================================================
-- XKID_HUB
-- Modal UI + Resize + Anti AFK + Fly
--====================================================

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- UI
local Modal = loadstring(game:HttpGet("https://github.com/BloxCrypto/Modal/releases/download/v1.0-beta/main.lua"))()

local Window = Modal:CreateWindow({
    Title = "XKID_HUB",
    SubTitle = "Modal Interface",
    Size = UDim2.fromOffset(500, 420),
    MinimumSize = Vector2.new(300, 250), -- resize limit
    Transparency = 0,
    Icon = "rbxassetid://68073547",
})

--====================================================
-- MAIN TAB
--====================================================

local Main = Window:AddTab("Main")

Main:New("Title")({
    Title = "Player Controls"
})

--====================================================
-- ANTI AFK
--====================================================

local AntiAFK = false

Main:New("Toggle")({
    Title = "Anti AFK",
    DefaultValue = false,
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

Main:New("Slider")({
    Title = "WalkSpeed",
    Default = 16,
    Minimum = 10,
    Maximum = 200,
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

Main:New("Toggle")({
    Title = "Fly",
    DefaultValue = false,
    Callback = function(v)

        Flying = v

        if v then
            StartFly()
        end

    end
})

Main:New("Slider")({
    Title = "Fly Speed",
    Default = 60,
    Minimum = 20,
    Maximum = 150,
    Callback = function(v)
        FlySpeed = v
    end
})

--====================================================
-- UTILITY TAB
--====================================================

local Utility = Window:AddTab("Utility")

Utility:New("Button")({
    Title = "Print Position",
    Callback = function()
        print(Player.Character.HumanoidRootPart.Position)
    end
})

Utility:New("Button")({
    Title = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
    end
})

--====================================================
-- SETTINGS TAB
--====================================================

local Settings = Window:AddTab("Settings")

Settings:New("Dropdown")({
    Title = "Theme",
    Options = { "Light", "Dark", "Midnight", "Rose", "Emerald" },
    Default = "Rose",
    Callback = function(theme)
        Window:SetTheme(theme)
    end
})

Settings:New("Button")({
    Title = "Destroy GUI",
    Callback = function()
        Window:Destroy()
    end
})

Window:SetTheme("Rose")
Window:SetTab("Main")