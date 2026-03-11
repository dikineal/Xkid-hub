--====================================================
-- XKID_HUB
-- Ash-Libs Template + Anti AFK + Mobile Fly
--====================================================

-- UI Library
local GUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodLetters/Ash-Libs/refs/heads/main/source.lua"))()

-- Services
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--====================================================
-- MAIN WINDOW
--====================================================

GUI:CreateMain({
    Name = "XKID_HUB",
    title = "XKID_HUB",
    ToggleUI = "K",
    WindowIcon = "home",
    Theme = {
        Background = Color3.fromRGB(20,20,30),
        Secondary = Color3.fromRGB(30,30,40),
        Accent = Color3.fromRGB(130,80,255),
        Text = Color3.fromRGB(255,255,255),
        TextSecondary = Color3.fromRGB(180,180,180),
        Border = Color3.fromRGB(45,45,60),
        NavBackground = Color3.fromRGB(15,15,25)
    }
})

--====================================================
-- MAIN TAB
--====================================================

local main = GUI:CreateTab("Main","home")

GUI:CreateSection({
    parent = main,
    text = "XKID_HUB Controls"
})

--====================================================
-- ANTI AFK
--====================================================

local AntiAFK = true

GUI:CreateToggle({
    parent = main,
    text = "Anti AFK",
    default = true,
    callback = function(state)
        AntiAFK = state
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
-- MOBILE + PC FLY
--====================================================

local Flying = false
local FlySpeed = 60
local FlyVelocity

local function StartFly()

    local character = Player.Character or Player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")

    FlyVelocity = Instance.new("BodyVelocity")
    FlyVelocity.MaxForce = Vector3.new(9e9,9e9,9e9)
    FlyVelocity.Velocity = Vector3.zero
    FlyVelocity.Parent = root

    RunService.RenderStepped:Connect(function()

        if not Flying then
            if FlyVelocity then
                FlyVelocity:Destroy()
            end
            return
        end

        local direction = Camera.CFrame.LookVector
        FlyVelocity.Velocity = direction * FlySpeed

    end)

end

GUI:CreateToggle({
    parent = main,
    text = "Fly (Mobile + PC)",
    default = false,
    callback = function(state)

        Flying = state

        if state then
            StartFly()
        end

    end
})

GUI:CreateSlider({
    parent = main,
    text = "Fly Speed",
    min = 20,
    max = 150,
    default = 60,
    function(value)
        FlySpeed = value
    end
})

--====================================================
-- UTILITY TAB
--====================================================

local util = GUI:CreateTab("Utility","settings")

GUI:CreateButton({
    parent = util,
    text = "Print Position",
    callback = function()

        local pos = Player.Character.HumanoidRootPart.Position
        print("Position:",pos)

    end
})

GUI:CreateButton({
    parent = util,
    text = "Rejoin Server",
    callback = function()

        game:GetService("TeleportService"):Teleport(game.PlaceId,Player)

    end
})