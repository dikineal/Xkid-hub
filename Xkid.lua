repeat task.wait() until game:IsLoaded()

--====================================================
-- MOBILE TOGGLE BUTTON
--====================================================

getgenv().Image = "rbxassetid://95816097006870"
getgenv().ToggleUI = Enum.KeyCode.E

if not getgenv().LoadedMobileUI then
    getgenv().LoadedMobileUI = true

    local OpenUI = Instance.new("ScreenGui")
    local Button = Instance.new("ImageButton")
    local Corner = Instance.new("UICorner")

    OpenUI.Name = "XKID_MobileToggle"
    OpenUI.Parent = game.CoreGui

    Button.Parent = OpenUI
    Button.Size = UDim2.new(0,50,0,50)
    Button.Position = UDim2.new(0.9,0,0.2,0)
    Button.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Button.BackgroundTransparency = 0.3
    Button.Image = getgenv().Image
    Button.Draggable = true

    Corner.Parent = Button
    Corner.CornerRadius = UDim.new(0,100)

    Button.MouseButton1Click:Connect(function()
        game:GetService("VirtualInputManager"):SendKeyEvent(
            true,
            getgenv().ToggleUI,
            false,
            game
        )
    end)
end

--====================================================
-- LOAD FLUENT
--====================================================

local Fluent = loadstring(game:HttpGet(
"https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

--====================================================
-- WINDOW
--====================================================

local Window = Fluent:CreateWindow({
    Title = "XKID_HUB",
    SubTitle = "Fluent Interface",
    TabWidth = 160,
    Size = UDim2.fromOffset(580,460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.E
})

--====================================================
-- TABS
--====================================================

local Tabs = {
    Main = Window:AddTab({Title="Main",Icon="home"}),
    Player = Window:AddTab({Title="Player",Icon="user"}),
    Utility = Window:AddTab({Title="Utility",Icon="settings"})
}

--====================================================
-- MAIN TAB
--====================================================

Tabs.Main:AddParagraph({
    Title = "XKID HUB",
    Content = "Welcome to XKID Hub.\nUI supports mobile toggle and resize."
})

--====================================================
-- PLAYER FEATURES
--====================================================

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

Tabs.Player:AddSlider("WalkSpeed",{
    Title="WalkSpeed",
    Min=16,
    Max=200,
    Default=16
})

Tabs.Player.WalkSpeed:OnChanged(function(v)

    local char = Player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = v
    end

end)

Tabs.Player:AddSlider("JumpPower",{
    Title="JumpPower",
    Min=50,
    Max=200,
    Default=50
})

Tabs.Player.JumpPower:OnChanged(function(v)

    local char = Player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = v
    end

end)

--====================================================
-- UTILITY
--====================================================

Tabs.Utility:AddButton({
    Title="Rejoin Server",
    Callback=function()
        game:GetService("TeleportService"):Teleport(game.PlaceId,Player)
    end
})

Tabs.Utility:AddButton({
    Title="Copy Position",
    Callback=function()
        local pos = Player.Character.HumanoidRootPart.Position
        setclipboard(tostring(pos))
    end
})

--====================================================
-- NOTIFY
--====================================================

Fluent:Notify({
    Title="XKID_HUB",
    Content="Script Loaded Successfully",
    Duration=5
})