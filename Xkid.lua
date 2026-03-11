--====================================================
-- XKID_HUB
-- BSMTUI Template
--====================================================

-- Load Library
local library = loadstring(game:HttpGet("https://thebasement.ink/BSMTUI"))()

-- Services
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Window
local window = library:Create("XKID_HUB", UDim2.new(0, 500, 0, 400))

--====================================================
-- MAIN TAB
--====================================================

local Main = window:Tab("Main", "rbxassetid://10734950309")
local Controls = Main:Section("Player Controls")

--====================================================
-- ANTI AFK
--====================================================

local AntiAFK = false

Controls:Toggle("Anti AFK", false, function(state)
    AntiAFK = state
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
-- WALK SPEED
--====================================================

Controls:Slider("WalkSpeed", 10, 200, 16, function(val)
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.WalkSpeed = val
    end
end)

--====================================================
-- FLY SYSTEM
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

Controls:Toggle("Fly", false, function(state)

    Flying = state

    if state then
        StartFly()
    end

end)

Controls:Slider("Fly Speed", 20, 150, 60, function(val)
    FlySpeed = val
end)

--====================================================
-- UTILITY TAB
--====================================================

local Utility = window:Tab("Utility", "rbxassetid://10734950309")
local Tools = Utility:Section("Tools")

Tools:Button("Print Position", function()
    local pos = Player.Character.HumanoidRootPart.Position
    print("Position:", pos)
end)

Tools:Button("Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
end)

--====================================================
-- NOTIFY TEST
--====================================================

Controls:Button("Test Notification", function()
    library:Notify({
        Title = "XKID_HUB",
        Text = "Hub Loaded Successfully!",
        Type = "Info"
    })
end)