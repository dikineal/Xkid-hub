-- Vape Script untuk xkid_hub
-- Anti AFK + Fly Script
-- Copy-paste ke Roblox Executor

local Vape = loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4/main/main.lua"))()

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
local Window = Vape:AddWindow({
    Title = "xkid_hub Script",
    Icon = "rbxasset://textures/Cursor.png",
    Author = "xkid_hub",
    HideKeyPress = false,
    KeyPress = Enum.KeyCode.RightControl
})

-- ===== TAB 1: HOME =====
local HomeTab = Window:AddTab({
    Name = "Home",
    Icon = "rbxasset://textures/Cursor.png"
})

HomeTab:AddLabel({
    Title = "Welcome!",
    Text = "Selamat datang di xkid_hub Script"
})

HomeTab:AddLabel({
    Title = "Features",
    Text = "✓ Anti AFK\n✓ Fly dengan speed control\n✓ Auto config save"
})

HomeTab:AddButton({
    Title = "Destroy UI",
    Callback = function()
        Window:Destroy()
        print("UI destroyed!")
    end
})

-- ===== TAB 2: ANTI AFK =====
local AntiAFKTab = Window:AddTab({
    Name = "Anti AFK",
    Icon = "rbxasset://textures/Cursor.png"
})

AntiAFKTab:AddLabel({
    Title = "Anti AFK Settings",
    Text = "Aktifkan untuk mencegah AFK kick"
})

AntiAFKTab:AddToggle({
    Title = "Enable Anti AFK",
    Default = false,
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

AntiAFKTab:AddLabel({
    Title = "Info",
    Text = "Karakter akan bergerak otomatis setiap 3 detik"
})

-- ===== TAB 3: FLY =====
local FlyTab = Window:AddTab({
    Name = "Fly",
    Icon = "rbxasset://textures/Cursor.png"
})

FlyTab:AddLabel({
    Title = "Fly Settings",
    Text = "Aktifkan untuk terbang"
})

FlyTab:AddToggle({
    Title = "Enable Fly",
    Default = false,
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

FlyTab:AddSlider({
    Title = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        flySpeed = value
        print("Fly Speed set to:", flySpeed)
    end
})

FlyTab:AddLabel({
    Title = "Kontrol Terbang",
    Text = "W/A/S/D = Bergerak\nSPACE = Naik\nLSHIFT = Turun"
})

-- ===== TAB 4: INFO =====
local InfoTab = Window:AddTab({
    Name = "Info",
    Icon = "rbxasset://textures/Cursor.png"
})

InfoTab:AddLabel({
    Title = "xkid_hub Script",
    Text = "Version: 1.0\nUI Library: Vape"
})

InfoTab:AddLabel({
    Title = "Features",
    Text = "✓ Anti AFK - Cegah AFK kick\n✓ Fly - Terbang dengan kontrol penuh\n✓ Speed Control - Atur kecepatan terbang"
})

InfoTab:AddButton({
    Title = "GitHub Repository",
    Callback = function()
        setclipboard("https://github.com/dikineal/Xkid-hub")
        print("GitHub link copied!")
    end
})

print("xkid_hub Script (Vape) loaded successfully!")
print("Press RIGHT CONTROL to toggle UI")
