-- LOAD UI LIBRARY
local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-------------------------------------------------
-- WINDOW
-------------------------------------------------

local Window = Fluent:CreateWindow({
    Title = "DIKI PROJECT",
    SubTitle = "by Diki",
    TabWidth = 90,
    Size = UDim2.fromOffset(260,200),
    Acrylic = true,
    Theme = "Dark"
})

Fluent:SetTheme({
    Accent = Color3.fromRGB(255,105,180)
})

-------------------------------------------------
-- TAB
-------------------------------------------------

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

-------------------------------------------------
-- ANTI AFK
-------------------------------------------------

local AntiAFK = Tabs.Main:AddToggle("AntiAFK",{
    Title = "Anti AFK",
    Default = false
})

AntiAFK:OnChanged(function(v)

    if v then

        local vu = game:GetService("VirtualUser")

        _G.AFK = true

        task.spawn(function()

            while _G.AFK do

                vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)

                task.wait(30)

            end

        end)

    else

        _G.AFK = false

    end

end)

-------------------------------------------------
-- FLY (INFINITE YIELD STYLE)
-------------------------------------------------

local Fly = Tabs.Main:AddToggle("Fly",{
    Title = "Fly",
    Default = false
})

Fly:OnChanged(function(state)

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    if state then

        local speed = 70
        local flying = true

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9,9e9,9e9)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp

        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(9e9,9e9,9e9)
        bg.CFrame = workspace.CurrentCamera.CFrame
        bg.Parent = hrp

        _G.FlyBV = bv
        _G.FlyBG = bg

        _G.FlyLoop = RunService.RenderStepped:Connect(function()

            if not flying then return end

            local cam = workspace.CurrentCamera
            local move = Vector3.zero

            if UIS:IsKeyDown(Enum.KeyCode.W) then
                move += cam.CFrame.LookVector
            end

            if UIS:IsKeyDown(Enum.KeyCode.S) then
                move -= cam.CFrame.LookVector
            end

            if UIS:IsKeyDown(Enum.KeyCode.A) then
                move -= cam.CFrame.RightVector
            end

            if UIS:IsKeyDown(Enum.KeyCode.D) then
                move += cam.CFrame.RightVector
            end

            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                move += cam.CFrame.UpVector
            end

            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                move -= cam.CFrame.UpVector
            end

            bv.Velocity = move * speed
            bg.CFrame = cam.CFrame

        end)

    else

        if _G.FlyBV then
            _G.FlyBV:Destroy()
        end

        if _G.FlyBG then
            _G.FlyBG:Destroy()
        end

        if _G.FlyLoop then
            _G.FlyLoop:Disconnect()
        end

    end

end)

-------------------------------------------------
-- MINIMIZE BUTTON
-------------------------------------------------

Tabs.Main:AddButton({
    Title = "Minimize UI",
    Description = "Hide UI",
    Callback = function()
        Fluent:Minimize()
    end
})

-------------------------------------------------
-- RESIZE HANDLE (pojok kanan bawah)
-------------------------------------------------

task.wait(1)

local gui = game.CoreGui:FindFirstChild("Fluent")

if gui then

    local main = gui:FindFirstChildWhichIsA("Frame",true)

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0,16,0,16)
    handle.Position = UDim2.new(1,-16,1,-16)
    handle.BackgroundColor3 = Color3.fromRGB(255,105,180)
    handle.BorderSizePixel = 0
    handle.Parent = main

    local dragging = false

    handle.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end

    end)

    UIS.InputEnded:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end

    end)

    UIS.InputChanged:Connect(function(input)

        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then

            local newX = main.Size.X.Offset + input.Delta.X
            local newY = main.Size.Y.Offset + input.Delta.Y

            main.Size = UDim2.fromOffset(newX,newY)

        end

    end)

end

-------------------------------------------------
-- NOTIFY
-------------------------------------------------

Fluent:Notify({
    Title = "DIKI PROJECT",
    Content = "Script Loaded",
    Duration = 5
})

Window:SelectTab(1)
