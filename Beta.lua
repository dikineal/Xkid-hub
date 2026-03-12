-- AFK + FLIGHT MENU

local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--========================
-- ANTI AFK
--========================
local antiAFK = true

local function getHum()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

RunService.Heartbeat:Connect(function()
    if antiAFK then
        if tick() % 120 < 0.03 then
            local hum = getHum()
            if hum then
                hum.Jump = true
            end
        end
    end
end)

--========================
-- GUI
--========================
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")
gui.Name = "FlightMenu"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0,200,0,100)
frame.Position = UDim2.new(0.5,-100,0.5,-50)
frame.BackgroundColor3 = Color3.fromRGB(25,25,30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

Instance.new("UICorner",frame)

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1,0,0,30)
title.BackgroundColor3 = Color3.fromRGB(35,35,45)
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Text = "✈️ Flight Menu"

local button = Instance.new("TextButton")
button.Parent = frame
button.Size = UDim2.new(0.8,0,0,40)
button.Position = UDim2.new(0.1,0,0.45,0)
button.BackgroundColor3 = Color3.fromRGB(45,45,55)
button.TextColor3 = Color3.fromRGB(255,255,255)
button.Font = Enum.Font.Gotham
button.TextSize = 16
button.Text = "Enable Flight"

Instance.new("UICorner",button)

--========================
-- FLIGHT SYSTEM
--========================
local flying = false
local speed = 50
local bodyVelocity

local function toggleFlight()

    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flying then

        flying = false
        button.Text = "Enable Flight"

        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end

    else

        flying = true
        button.Text = "Disable Flight"

        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(9e9,9e9,9e9)
        bodyVelocity.Velocity = Vector3.new()
        bodyVelocity.Parent = hrp

    end
end

button.MouseButton1Click:Connect(toggleFlight)

--========================
-- MOVEMENT
--========================
RunService.RenderStepped:Connect(function()

    if not flying then return end

    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local cam = workspace.CurrentCamera
    local move = Vector3.new()

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        move += cam.CFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        move -= cam.CFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        move -= cam.CFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        move += cam.CFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        move += Vector3.new(0,1,0)
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        move -= Vector3.new(0,1,0)
    end

    if bodyVelocity then
        bodyVelocity.Velocity = move * speed
    end

end)

--========================
-- TOGGLE GUI
--========================
local visible = true

UserInputService.InputBegan:Connect(function(input,gp)

    if gp then return end

    if input.KeyCode == Enum.KeyCode.RightControl then
        visible = not visible
        frame.Visible = visible
    end

end)