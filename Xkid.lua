-- WindUI Script untuk xkid_hub
-- Anti AFK + Fly Script
-- Copy-paste ke Roblox Executor

local WindUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main.client.lua'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local humanoid = player.Character:WaitForChild("Humanoid")
local rootPart = player.Character:WaitForChild("HumanoidRootPart")

-- ===== VARIABLES =====
local antiAFKEnabled = false
local flyEnabled = false
local flySpeed = 50
local flyConnection = nil

-- ===== MEMBUAT WINDOW =====
local Window = WindUI:CreateWindow({
    Title = "xkid_hub Script",
    Icon = "rbxasset://textures/Cursor.png",
    Author = "xkid_hub",
    Folder = "xkid_hub_Config",
    HideOnClose = true,
    IntroEnabled = true,
    IntroText = "Welcome to xkid_hub!"
})

-- ===== TAB 1: HOME =====
local TabHome = Window:CreateTab({
    Name = "Home",
    Icon = "rbxasset://textures/Cursor.png"
})

TabHome:CreateLabel("Welcome to xkid_hub Script!")
TabHome:CreateLabel("Features: Anti AFK, Fly")
TabHome:CreateLabel("Version: 1.0")

TabHome:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Window:Destroy()
        print("UI destroyed!")
    end
})

-- ===== TAB 2: ANTI AFK =====
local TabAntiAFK = Window:CreateTab({
    Name = "Anti AFK",
    Icon = "rbxasset://textures/Cursor.png"
})

TabAntiAFK:CreateLabel("Anti AFK Settings")

TabAntiAFK:CreateToggle({
    Name = "Enable Anti AFK",
    StartingToggle = false,
    Callback = function(toggleState)
        antiAFKEnabled = toggleState
        if antiAFKEnabled then
            print("Anti AFK: Enabled")
            -- Mulai anti AFK
            local antiAFKConnection
            antiAFKConnection = RunService.Heartbeat:Connect(function()
                if antiAFKEnabled then
                    -- Gerak karakter agar tidak AFK
                    humanoid:Move(Vector3.new(1, 0, 0), false)
                    wait(2)
                    humanoid:Move(Vector3.new(-1, 0, 0), false)
                    wait(2)
                else
                    if antiAFKConnection then
                        antiAFKConnection:Disconnect()
                    end
                end
            end)
        else
            print("Anti AFK: Disabled")
            humanoid:Move(Vector3.new(0, 0, 0), false)
        end
    end
})

TabAntiAFK:CreateLabel("Anti AFK akan menggerakkan karakter secara otomatis")

-- ===== TAB 3: FLY =====
local TabFly = Window:CreateTab({
    Name = "Fly",
    Icon = "rbxasset://textures/Cursor.png"
})

TabFly:CreateLabel("Fly Settings")

TabFly:CreateToggle({
    Name = "Enable Fly",
    StartingToggle = false,
    Callback = function(toggleState)
        flyEnabled = toggleState
        
        if flyEnabled then
            print("Fly: Enabled")
            
            -- Buat bodyVelocity untuk fly
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
            bodyVelocity.Parent = rootPart
            
            flyConnection = RunService.RenderStepped:Connect(function()
                if flyEnabled then
                    local moveDirection = Vector3.new(0, 0, 0)
                    
                    -- Kontrol dengan WASD
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
                    
                    -- Naik dengan SPACE, turun dengan LSHIFT
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        moveDirection = moveDirection + Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        moveDirection = moveDirection - Vector3.new(0, 1, 0)
                    end
                    
                    -- Set velocity
                    if moveDirection.Magnitude > 0 then
                        moveDirection = moveDirection.Unit
                    end
                    
                    bodyVelocity.Velocity = moveDirection * flySpeed
                else
                    bodyVelocity:Destroy()
                    if flyConnection then
                        flyConnection:Disconnect()
                    end
                end
            end)
        else
            print("Fly: Disabled")
            if flyConnection then
                flyConnection:Disconnect()
            end
        end
    end
})

TabFly:CreateSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 200,
    Decimals = 0,
    StartingValue = 50,
    Callback = function(value)
        flySpeed = value
        print("Fly Speed:", flySpeed)
    end
})

TabFly:CreateLabel("Kontrol Terbang:")
TabFly:CreateLabel("W/A/S/D = Bergerak")
TabFly:CreateLabel("SPACE = Naik")
TabFly:CreateLabel("LSHIFT = Turun")

-- ===== TAB 4: INFO =====
local TabInfo = Window:CreateTab({
    Name = "Info",
    Icon = "rbxasset://textures/Cursor.png"
})

TabInfo:CreateLabel("xkid_hub Script Info")
TabInfo:CreateLabel("Script ini dilengkapi dengan:")
TabInfo:CreateLabel("✓ Anti AFK")
TabInfo:CreateLabel("✓ Fly dengan speed control")
TabInfo:CreateLabel("✓ Config auto-save")

TabInfo:CreateButton({
    Name = "Copy Script Link",
    Callback = function()
        setclipboard("loadstring(game:HttpGet('https://raw.githubusercontent.com/xkid_hub/script/main/windui_script.lua'))()")
        print("Script link copied!")
    end
})

print("xkid_hub Script loaded successfully!")
print("Press RIGHT CONTROL to toggle UI")
