-- Load DrRay UI
local DrRayLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/DrRay-UI-Library/main/DrRay.lua"))()

-- Services
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer

-- UI
local window = DrRayLibrary:Load("Anti AFK - Chloe Style 🔥", "Default")
local tab = DrRayLibrary.newTab("Controls")

-- Variables
local enabled = false
local interval = 30
local connection = nil

-- Toggle Anti AFK
tab.newToggle("Enable Anti AFK", false, function(state)
    enabled = state

    if enabled then
        DrRayLibrary:Notify("Anti AFK", "Enabled")

        connection = Player.Idled:Connect(function()
            if enabled then
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end
        end)

    else
        if connection then
            connection:Disconnect()
            connection = nil
        end

        DrRayLibrary:Notify("Anti AFK", "Disabled")
    end
end)

-- Slider interval (optional)
tab.newSlider("Interval (detik)", 10, 120, 30, function(value)
    interval = value
end)

-- Test Button
tab.newButton("Test Notification", function()
    DrRayLibrary:Notify("Script Status", "Running normally")
end)
