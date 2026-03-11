--====================================================
-- XKID_HUB
-- Fluent UI Template
--====================================================

-- Load Fluent
local Fluent = loadstring(game:HttpGet(
"https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

-- Services
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--====================================================
-- WINDOW
--====================================================

local Window = Fluent:CreateWindow({
    Title = "XKID_HUB",
    SubTitle = "Fluent Interface",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 420), -- resize base
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "settings" })
}

--====================================================
-- ANTI AFK
--====================================================

local AntiAFK = true

Tabs.Main:AddToggle("AntiAFK", {
    Title = "Anti AFK",
    Default = true
})

Tabs.Main.AntiAFK:OnChanged(function(v)
    AntiAFK = v
end)

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

Tabs.Main:AddToggle("FlyToggle", {
    Title = "Fly",
    Default = false
})

Tabs.Main.FlyToggle:OnChanged(function(v)

    Flying = v

    if v then
        StartFly()
    end

end)

Tabs.Main:AddSlider("FlySpeed", {
    Title = "Fly Speed",
    Default = 60,
    Min = 20,
    Max = 150,
    Rounding = 0
})

Tabs.Main.FlySpeed:OnChanged(function(v)
    FlySpeed = v
end)

--====================================================
-- UTILITY
--====================================================

Tabs.Utility:AddButton({
    Title = "Print Position",
    Callback = function()
        print(Player.Character.HumanoidRootPart.Position)
    end
})

Tabs.Utility:AddButton({
    Title = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
    end
})