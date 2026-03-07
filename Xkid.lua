--[[
    xkid_hub Script
    WindUI Library - Anti AFK + Fly
    
    GitHub:
    - https://github.com/dikineal/Xkid-hub
    
    WindUI:
    - https://github.com/Footagesus/WindUI
]]

local WindUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main.client.lua'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- Player info
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Variables
local antiAFKEnabled = false
local flyEnabled = false
local flySpeed = 50
local bodyVelocity = nil
local antiAFKConnection = nil
local flyConnection = nil

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "xkid_hub Script",
    Icon = "rbxasset://textures/Cursor.png",
    Author = "xkid_hub",
    Folder = "xkid_hub",
    Size = UDim2.new(0, 500, 0, 400)
})

-- ===== HOME TAB =====
local HomeTab = Window:CreateTab({
    Name = "Home",
    Icon = "rbxasset://textures/Cursor.png"
})

HomeTab:CreateLabel("Welcome to xkid_hub Script!")
HomeTab:CreateLabel("Version: 1.0")
HomeTab:CreateLabel("")
HomeTab:CreateLabel("Features:")
HomeTab:CreateLabel("✓ Anti AFK")
HomeTab:CreateLabel("✓ Fly")
HomeTab:CreateLabel("✓ Speed Control")

HomeTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Window:Destroy()
        print("UI Destroyed!")
    end
})

-- ===== ANTI AFK TAB =====
local AntiAFKTab = Window:CreateTab({
    Name = "Anti AFK",
    Icon = "rbxasset://textures/Cursor.png"
})

AntiAFKTab:CreateLabel("Anti AFK Settings")
AntiAFKTab:CreateLabel("Karakter akan bergerak otomatis")
AntiAFKTab:CreateLabel("")

AntiAFKTab:CreateToggle({
    Name = "Enable Anti AFK",
    Default = false,
    Callback = function(value)
        antiAFKEnabled = value
        
        if antiAFKEnabled then
            print("Anti AFK: Enabled")
            
            if antiAFKConnection then
                antiAFKConnection:Disconnect()
            end
            
            -- Anti AFK loop
            antiAFKConnection = RunService.Heartbeat:Connect(function()
                if antiAFKEnabled and Humanoid then
                    -- Move forward
                    Humanoid:Move(Vector3.new(1, 0, 0), false)
                    wait(3)
                    
                    if antiAFKEnabled then
                        -- Move backward
                        Humanoid:Move(Vector3.new(-1, 0, 0), false)
                        wait(3)
                    end
                else
                    if antiAFKConnection then
                        antiAFKConnection:Disconnect()
                    end
                end
            end)
        else
            print("Anti AFK: Disabled")
            if antiAFKConnection then
                antiAFKConnection:Disconnect()
            end
            Humanoid:Move(Vector3.new(0, 0, 0), false)
        end
    end
})

-- ===== FLY TAB =====
local FlyTab = Window:CreateTab({
    Name = "Fly",
    Icon = "rbxasset://textures/Cursor.png"
})

FlyTab:CreateLabel("Fly Settings")
FlyTab:CreateLabel("")

FlyTab:CreateToggle({
    Name = "Enable Fly",
    Default = false,
    Callback = function(value)
        flyEnabled = value
        
        if flyEnabled then
            print("Fly: Enabled")
            
            -- Remove old BodyVelocity
            if bodyVelocity then
                bodyVelocity:Destroy()
            end
            
            -- Create new BodyVelocity
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
            bodyVelocity.Parent = RootPart
            
            -- Disconnect old connection
            if flyConnection then
                flyConnection:Disconnect()
            end
            
            -- Fly loop
            flyConnection = RunService.RenderStepped:Connect(function()
                if flyEnabled and bodyVelocity and bodyVelocity.Parent then
                    local moveDirection = Vector3.new(0, 0, 0)
                    
                    -- WASD Controls
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        moveDirection = moveDirection + (Camera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        moveDirection = moveDirection - (Camera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        moveDirection = moveDirection - Camera.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        moveDirection = moveDirection + Camera.CFrame.RightVector
                    end
                    
                    -- Up/Down
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        moveDirection = moveDirection + Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        moveDirection = moveDirection - Vector3.new(0, 1, 0)
                    end
                    
                    -- Normalize
                    if moveDirection.Magnitude > 0 then
                        moveDirection = moveDirection.Unit
                    end
                    
                    bodyVelocity.Velocity = moveDirection * flySpeed
                else
                    if bodyVelocity then
                        bodyVelocity:Destroy()
                        bodyVelocity = nil
                    end
                    if flyConnection then
                        flyConnection:Disconnect()
                    end
                end
            end)
        else
            print("Fly: Disabled")
            if bodyVelocity then
                bodyVelocity:Destroy()
                bodyVelocity = nil
            end
            if flyConnection then
                flyConnection:Disconnect()
            end
        end
    end
})

FlyTab:CreateSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        flySpeed = value
        print("Fly Speed: " .. value)
    end
})

FlyTab:CreateLabel("")
FlyTab:CreateLabel("Kontrol Terbang:")
FlyTab:CreateLabel("W/A/S/D = Bergerak")
FlyTab:CreateLabel("SPACE = Naik")
FlyTab:CreateLabel("LSHIFT = Turun")

-- ===== INFO TAB =====
local InfoTab = Window:CreateTab({
    Name = "Info",
    Icon = "rbxasset://textures/Cursor.png"
})

InfoTab:CreateLabel("xkid_hub Script")
InfoTab:CreateLabel("Version: 1.0")
InfoTab:CreateLabel("")
InfoTab:CreateLabel("UI Library: WindUI")
InfoTab:CreateLabel("")
InfoTab:CreateLabel("Features:")
InfoTab:CreateLabel("• Anti AFK Prevention")
InfoTab:CreateLabel("• Fly with Full Control")
InfoTab:CreateLabel("• Adjustable Speed")
InfoTab:CreateLabel("")

InfoTab:CreateButton({
    Name = "Copy Repository Link",
    Callback = function()
        setclipboard("https://github.com/dikineal/Xkid-hub")
        print("Repository link copied!")
    end
})

print("xkid_hub Script loaded successfully!")
print("Made with WindUI - https://github.com/Footagesus/WindUI")
