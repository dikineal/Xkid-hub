-- Load WindUI dengan proteksi
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/library/windui"))()
end)

if not success or not WindUI then
    warn("WindUI gagal dimuat")
    return
end

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Window
local Window = WindUI:CreateWindow({
    Title = "Diki Project",
    Author = "by Diki",
    Folder = "DikiConfig",
    Size = UDim2.fromOffset(580,460),
    Transparent = true,
    Theme = "Dark",
    AccentColor = Color3.fromRGB(0,102,255)
})

local MainTab = Window:Tab({
    Name = "Main",
    Icon = "house"
})

MainTab:Section({
    Name = "Karakter Control",
    TextSize = 18
})

-- Button
MainTab:Button({
    Title = "Print Status",
    Desc = "Klik untuk cek status",
    Callback = function()
        print("Script berhasil dijalankan")
    end
})

-- Infinite Jump
local InfJump = false

MainTab:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(v)
        InfJump = v
    end
})

UIS.JumpRequest:Connect(function()
    if InfJump then
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- WalkSpeed
MainTab:Slider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 200,
    Step = 1,
    Value = 16,
    Callback = function(v)
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = v
            end
        end
    end
})
