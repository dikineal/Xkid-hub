local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- Membuat Jendela Utama (Window)
local Window = OrionLib:MakeWindow({
    Name = "My Roblox Script", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "OrionTest"
})

-- Membuat Tab Baru
local MainTab = Window:MakeTab({
    Name = "Main Features",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Menambahkan Section
local Section = MainTab:AddSection({
    Name = "Karakter"
})

-- Membuat Button (Tombol)
MainTab:AddButton({
    Name = "Print Hello!",
    Callback = function()
        print("Halo dari Orion UI!")
    end    
})

-- Membuat Slider (Misal untuk WalkSpeed)
MainTab:AddSlider({
    Name = "Speed",
    Min = 16,
    Max = 500,
    Default = 16,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end    
})

-- Membuat Toggle (Tombol On/Off)
MainTab:AddToggle({
    Name = "Auto Jump",
    Default = false,
    Callback = function(Value)
        print("Auto Jump status:", Value)
    end    
})

-- Menjalankan Library
OrionLib:Init()
