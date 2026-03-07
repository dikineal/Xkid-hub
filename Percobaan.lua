-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"))()

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Window
local Window = WindUI:CreateWindow({
    Title = "Diki Project",
    Author = "by Diki",
    Folder = "DikiConfig",
    Size = UDim2.fromOffset(580,460),
    Transparent = true,
    Theme = "Dark",
    AccentColor = Color3.fromRGB(0,102,255)
})

-- Tab
local MainTab = Window:Tab({
    Name = "Main",
    Icon = "house"
})

-- Section
MainTab:Section({
    Name = "Character Control"
})

-- Button
MainTab:Button({
    Title = "Test Script",
    Desc = "Cek apakah script berjalan",
    Callback = function()
        WindUI:Notify({
            Title = "Success",
            Content = "Script berhasil di execute!",
            Duration = 3
        })
    end
})

-- Infinite Jump
local InfJump = false

MainTab:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(v)
        InfJump = v
    end
})

UIS.JumpRequest:Connect(function()
    if InfJump then
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- WalkSpeed
MainTab:Slider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 200,
    Step = 1,
    Value = 16,
    Callback = function(v)
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = v
            end
        end
    end
})

-- Jump Power
MainTab:Slider({
    Title = "JumpPower",
    Min = 50,
    Max = 300,
    Step = 5,
    Value = 50,
    Callback = function(v)
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.JumpPower = v
            end
        end
    end
})
