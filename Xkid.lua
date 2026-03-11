repeat task.wait() until game:IsLoaded()

getgenv().Image = "rbxassetid://95816097006870"

-- Load Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "XKID.HUB",
    SubTitle = "by XKID",
    TabWidth = 160,
    Size = UDim2.fromOffset(580,460),
    Acrylic = true,
    Theme = "Dark"
})

local Main = Window:AddTab({ Title = "Main", Icon = "" })

Main:AddParagraph({
    Title = "XKID HUB",
    Content = "Script Loaded Successfully"
})

------------------------------------------------
-- MOBILE OPEN BUTTON
------------------------------------------------

local OpenUI = Instance.new("ScreenGui")
local ImageButton = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")

OpenUI.Name = "XKID_UI"
OpenUI.Parent = game.CoreGui

ImageButton.Parent = OpenUI
ImageButton.BackgroundColor3 = Color3.fromRGB(105,105,105)
ImageButton.BackgroundTransparency = 0.2
ImageButton.Position = UDim2.new(0.9,0,0.2,0)
ImageButton.Size = UDim2.new(0,50,0,50)
ImageButton.Image = getgenv().Image
ImageButton.Draggable = true

UICorner.CornerRadius = UDim.new(0,200)
UICorner.Parent = ImageButton

-- TOGGLE UI (WORKS ON MOBILE)
ImageButton.MouseButton1Click:Connect(function()
    Fluent:Toggle()
end)

------------------------------------------------
-- ANTI AFK
------------------------------------------------

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

Main:AddButton({
    Title = "Anti AFK",
    Callback = function()
        local vu = game:GetService("VirtualUser")

        LocalPlayer.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)
    end
})

------------------------------------------------
-- SPEED
------------------------------------------------

Main:AddSlider("Speed",{
    Title = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 200,
    Callback = function(Value)
        if LocalPlayer.Character then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
        end
    end
})

------------------------------------------------
-- JUMP
------------------------------------------------

Main:AddSlider("Jump",{
    Title = "JumpPower",
    Default = 50,
    Min = 50,
    Max = 200,
    Callback = function(Value)
        if LocalPlayer.Character then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = Value
        end
    end
})

Fluent:Notify({
    Title = "XKID.HUB",
    Content = "Loaded Successfully",
    Duration = 5
})