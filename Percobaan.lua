local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()

local Window = OrionLib:MakeWindow({
    Name = "Orion Hub v2026",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "OrionTest"
})

local Tab = Window:MakeTab({
    Name = "Main",
    PremiumOnly = false
})

local Section = Tab:AddSection({
    Name = "Test Features"
})

Tab:AddButton({
    Name = "Test Button",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "Success!",
            Content = "Orion Jalan Bro! 🔥",
            Image = "rbxassetid://4483345998",
            Time = 5
        })
    end
})

Tab:AddToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(Value)
        print("Auto Farm:", Value)
        -- Logic kamu di sini
    end
})

Tab:AddSlider({
    Name = "Speed",
    Min = 0,
    Max = 100,
    Default = 50,
    Color = Color3.fromRGB(255,0,0),
    Increment = 1,
    Callback = function(Value)
        print("Speed:", Value)
    end
})

OrionLib:Init()  -- Auto save & ready
