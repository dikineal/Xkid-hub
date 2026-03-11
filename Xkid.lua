--====================================================
-- XKID_HUB
-- Fluent UI | Resizable | Stable
--====================================================

-- Destroy old UI
pcall(function()
    game.CoreGui:FindFirstChild("Fluent"):Destroy()
end)

-- Load Fluent
local Fluent = loadstring(game:HttpGet(
"https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--====================================================
-- WINDOW
--====================================================

local Window = Fluent:CreateWindow({
    Title = "XKID_HUB",
    SubTitle = "Fluent Interface",
    TabWidth = 160,
    Size = UDim2.fromOffset(620,450), -- resizable
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Player", Icon = "user" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "settings" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "sliders" })
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
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end
end)

--====================================================
-- WALK SPEED
--====================================================

Tabs.Main:AddSlider("Speed", {
    Title = "WalkSpeed",
    Default = 16,
    Min = 10,
    Max = 200,
    Rounding = 0
})

Tabs.Main.Speed:OnChanged(function(v)

    local char = Player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = v
    end

end)

--====================================================
-- JUMP POWER
--====================================================

Tabs.Main:AddSlider("Jump", {
    Title = "JumpPower",
    Default = 50,
    Min = 20,
    Max = 200
})

Tabs.Main.Jump:OnChanged(function(v)

    local char = Player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = v
    end

end)

--====================================================
-- INFINITE JUMP
--====================================================

local InfJump = false

Tabs.Main:AddToggle("InfJump", {
    Title = "Infinite Jump",
    Default = false
})

Tabs.Main.InfJump:OnChanged(function(v)
    InfJump = v
end)

UIS.JumpRequest:Connect(function()

    if InfJump then
        local char = Player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState("Jumping")
        end
    end

end)

--====================================================
-- FLY
--====================================================

local Flying = false
local FlySpeed = 60
local BV

local function StartFly()

    local char = Player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")

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

Tabs.Main:AddToggle("Fly", {
    Title = "Fly",
    Default = false
})

Tabs.Main.Fly:OnChanged(function(v)

    Flying = v

    if v then
        StartFly()
    end

end)

Tabs.Main:AddSlider("FlySpeed", {
    Title = "Fly Speed",
    Default = 60,
    Min = 20,
    Max = 150
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
        game:GetService("TeleportService"):Teleport(game.PlaceId,Player)
    end
})

--====================================================
-- SETTINGS
--====================================================

Tabs.Settings:AddDropdown("Theme", {
    Title = "UI Theme",
    Values = {"Dark","Light","Aqua","Amethyst"},
    Default = "Dark"
})

Tabs.Settings.Theme:OnChanged(function(v)
    Fluent:SetTheme(v)
end)

--====================================================
-- LOADED
--====================================================

Fluent:Notify({
    Title = "XKID_HUB",
    Content = "Hub Loaded Successfully",
    Duration = 5
})