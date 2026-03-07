-- Load Linoria Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

-- Window
local Window = Library:CreateWindow({
    Title = "Diki Hub",
    Center = true,
    AutoShow = true,
})

-- Tabs
local Tabs = {
    Main = Window:AddTab("Main"),
    Player = Window:AddTab("Player"),
    Settings = Window:AddTab("Settings")
}

-- Button
Tabs.Main:AddButton("Print Hello", function()
    print("Hello dari Linoria GUI")
end)

-- Toggle
local InfiniteJump = false

Tabs.Player:AddToggle("InfJump", {
    Text = "Infinite Jump",
    Default = false,
    Callback = function(Value)
        InfiniteJump = Value
    end
})

-- Slider WalkSpeed
Tabs.Player:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 1,
    Callback = function(Value)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = Value
            end
        end
    end
})

-- Infinite Jump Logic
game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJump then
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Theme + Save
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

ThemeManager:SetFolder("DikiHub")
SaveManager:SetFolder("DikiHub/config")

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
