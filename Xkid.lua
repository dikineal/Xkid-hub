-- MacLib Script untuk xkid_hub
-- Anti AFK + Fly Script
-- Copy-paste ke Roblox Executor

local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

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
local bodyVelocity = nil
local flyConnection = nil
local antiAFKConnection = nil

-- ===== MEMBUAT WINDOW =====
local Window = MacLib:CreateWindow({
    Title = "xkid_hub Script",
    Subtitle = "v1.0 - MacLib UI",
    Size = UDim2.new(0, 520, 0, 400),
    HasExitButton = true,
    Icon = "rbxasset://textures/Cursor.png",
    ShowDragBar = true
})

-- ===== TAB 1: HOME =====
local HomeTab = Window:CreateTab({
    Name = "Home",
    Icon = "🏠"
})

HomeTab:CreateLabel({
    Text = "Welcome to xkid_hub Script!",
    TextSize = 16
})

HomeTab:CreateLabel({
    Text = "Features:",
    TextSize = 14
})

HomeTab:CreateLabel({
    Text = "✓ Anti AFK",
    TextSize = 12
})

HomeTab:CreateLabel({
    Text = "✓ Fly dengan speed control",
    TextSize = 12
})

HomeTab:CreateLabel({
    Text = "✓ MacOS Style UI",
    TextSize = 12
})

HomeTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Window:Destroy()
        print("UI destroyed!")
    end
})

-- ===== TAB 2: ANTI AFK =====
local AntiAFKTab = Window:CreateTab({
    Name = "Anti AFK",
    Icon = "⏱️"
})

AntiAFKTab:CreateLabel({
    Text = "Anti AFK Settings"
})

AntiAFKTab:CreateToggle({
    Name = "Enable Anti AFK",
    State = false,
    Callback = function(state)
        antiAFKEnabled = state
        
        if antiAFKEnabled then
            print("Anti AFK: Enabled")
            
            -- Disconnect existing connection
            if antiAFKConnection then
                antiAFKConnection:Disconnect()
            end
            
            -- Anti AFK loop
            antiAFKConnection = RunService.Heartbeat:Connect(function()
                if antiAFKEnabled and humanoid then
                    -- Gerak karakter maju mundur
                    humanoid:Move(Vector3.new(1, 0, 0), false)
                    wait(3)
                    
                    if antiAFKEnabled then
                        humanoid:Move(Vector3.new(-1, 0, 0), false)
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
            humanoid:Move(Vector3.new(0, 0, 0), false)
        end
    end
})

AntiAFKTab:CreateLabel({
    Text = "Karakter akan bergerak otomatis"
})

AntiAFKTab:CreateLabel({
    Text = "Cegah AFK kick dari server"
})

-- ===== TAB 3: FLY =====
local FlyTab = Window:CreateTab({
    Name = "Fly",
    Icon = "🚀"
})

FlyTab:CreateLabel({
    Text = "Fly Settings"
})

FlyTab:CreateToggle({
    Name = "Enable Fly",
    State = false,
    Callback = function(state)
        flyEnabled = state
        
        if flyEnabled then
            print("Fly: Enabled")
            
            -- Hapus bodyVelocity lama jika ada
            if bodyVelocity then
                bodyVelocity:Destroy()
            end
            
            -- Buat bodyVelocity baru
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
            bodyVelocity.Parent = rootPart
            
            -- Disconnect fly connection lama
            if flyConnection then
                flyConnection:Disconnect()
            end
            
            -- Fly loop
            flyConnection = RunService.RenderStepped:Connect(function()
                if flyEnabled and bodyVelocity and bodyVelocity.Parent then
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
                    
                    -- Normalize direction
                    if moveDirection.Magnitude > 0 then
                        moveDirection = moveDirection.Unit
                    end
                    
                    -- Set velocity
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
    Increment = 5,
    ValueChanged = function(value)
        flySpeed = value
        print("Fly Speed:", flySpeed)
    end
})

FlyTab:CreateLabel({
    Text = "Kontrol Terbang:"
})

FlyTab:CreateLabel({
    Text = "W/A/S/D = Bergerak"
})

FlyTab:CreateLabel({
    Text = "SPACE = Naik"
})

FlyTab:CreateLabel({
    Text = "LSHIFT = Turun"
})

-- ===== TAB 4: INFO =====
local InfoTab = Window:CreateTab({
    Name = "Info",
    Icon = "ℹ️"
})

InfoTab:CreateLabel({
    Text = "xkid_hub Script"
})

InfoTab:CreateLabel({
    Text = "Version: 1.0"
})

InfoTab:CreateLabel({
    Text = "UI Library: MacLib"
})

InfoTab:CreateLabel({
    Text = ""
})

InfoTab:CreateLabel({
    Text = "Features:"
})

InfoTab:CreateLabel({
    Text = "• Anti AFK"
})

InfoTab:CreateLabel({
    Text = "• Fly dengan kontrol penuh"
})

InfoTab:CreateLabel({
    Text = "• Speed control slider"
})

InfoTab:CreateLabel({
    Text = "• MacOS style interface"
})

InfoTab:CreateButton({
    Name = "Copy GitHub Link",
    Callback = function()
        setclipboard("https://github.com/dikineal/Xkid-hub")
        print("GitHub link copied!")
    end
})

print("xkid_hub Script (MacLib) loaded successfully!")
print("Enjoy your script!")
