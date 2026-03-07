-- Load Library
local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/library/windui"))()

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

-- Tab
local MainTab = Window:Tab({
    Name = "Main",
    Icon = "house"
})

-- Section
MainTab:Section({
    Name = "Karakter Control",
    TextSize = 18
})

-- Button
MainTab:Button({
    Title = "Print Status",
    Desc = "Klik untuk cek status",
    Callback = function()
        print("WindUI Berhasil di Execute!")
        WindUI:Notify({
            Title = "Success",
            Content = "Script berjalan dengan lancar!",
            Duration = 3
        })
    end
})

-- Infinite Jump
local InfJump = false

MainTab:Toggle({
    Title = "Infinite Jump",
    Desc = "Lompat tanpa batas",
    Value = false,
    Callback = function(state)
        InfJump = state
    end
})

UIS.JumpRequest:Connect(function()
    if InfJump then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- WalkSpeed
MainTab:Slider({
    Title = "WalkSpeed",
    Desc = "Atur kecepatan lari",
    Min = 16,
    Max = 200,
    Step = 1,
    Value = 16,
    Callback = function(v)
        Humanoid.WalkSpeed = v
    end
})

-- Jump Power
MainTab:Input({
    Title = "Jump Power",
    Placeholder = "Masukkan angka...",
    Callback = function(v)
        local num = tonumber(v)
        if num then
            Humanoid.JumpPower = num
        end
    end
})

-- Teleport Dropdown
MainTab:Dropdown({
    Title = "Pilih Lokasi TP",
    Multi = false,
    Options = {"Lobby","Farm Zone","Shop"},
    Callback = function(v)

        local root = Character:WaitForChild("HumanoidRootPart")

        if v == "Lobby" then
            root.CFrame = CFrame.new(0,5,0)

        elseif v == "Farm Zone" then
            root.CFrame = CFrame.new(100,5,100)

        elseif v == "Shop" then
            root.CFrame = CFrame.new(-50,5,200)
        end

    end
})
