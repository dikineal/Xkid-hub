-- Load UI library
local Library = loadstring(game:HttpGet('https://gist.githubusercontent.com/MjContiga1/6e2c779299e9bf3d3f9edb5bff97b2fb/raw/29b9f1cc215ad4e583271d1ad229f34c921553a8/Lib%2520ui%2520test.lua'))()

-- Create window
local window = Library:Window('XKID.HUB')

-- Tabs
local mainTab = window:Tab('Main')
local playerTab = window:Tab('Player')
local settingsTab = window:Tab('Settings')

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-------------------------------------------------
-- CREATE OPEN BUTTON
-------------------------------------------------

local OpenGui = Instance.new("ScreenGui")
OpenGui.Parent = game.CoreGui

local OpenButton = Instance.new("ImageButton")
OpenButton.Parent = OpenGui
OpenButton.Size = UDim2.new(0,50,0,50)
OpenButton.Position = UDim2.new(0.9,0,0.2,0)
OpenButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
OpenButton.Image = "rbxassetid://95816097006870"
OpenButton.Draggable = true
OpenButton.Visible = false

-------------------------------------------------
-- HIDE SYSTEM
-------------------------------------------------

local function HideUI()

    for _,v in pairs(game.CoreGui:GetChildren()) do
        if v:IsA("ScreenGui") and v ~= OpenGui then
            v.Enabled = false
        end
    end

    OpenButton.Visible = true

end

OpenButton.MouseButton1Click:Connect(function()

    for _,v in pairs(game.CoreGui:GetChildren()) do
        if v:IsA("ScreenGui") then
            v.Enabled = true
        end
    end

    OpenButton.Visible = false

end)

-------------------------------------------------
-- MAIN
-------------------------------------------------

mainTab:Label("Welcome to XKID.HUB")

mainTab:Button("Hide UI", function()
    HideUI()
end)

-------------------------------------------------
-- ANTI AFK
-------------------------------------------------

mainTab:Toggle("Anti AFK", false, function(state)

    if state then
        local vu = game:GetService("VirtualUser")

        LocalPlayer.Idled:Connect(function()

            vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)

        end)
    end

end)

-------------------------------------------------
-- SPEED
-------------------------------------------------

playerTab:Slider("Walk Speed",16,200,16,function(value)

    if LocalPlayer.Character then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = value
    end

end)

-------------------------------------------------
-- JUMP
-------------------------------------------------

playerTab:Slider("Jump Power",50,200,50,function(value)

    if LocalPlayer.Character then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = value
    end

end)

-------------------------------------------------
-- FLY
-------------------------------------------------

local flying = false

playerTab:Toggle("Fly",false,function(state)

    flying = state

    if flying then

        local char = LocalPlayer.Character
        local hrp = char:WaitForChild("HumanoidRootPart")

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(100000,100000,100000)
        bv.Parent = hrp

        while flying do
            bv.Velocity = workspace.CurrentCamera.CFrame.LookVector * 60
            task.wait()
        end

        bv:Destroy()

    end

end)

-------------------------------------------------
-- SETTINGS
-------------------------------------------------

settingsTab:Label("XKID HUB SETTINGS")