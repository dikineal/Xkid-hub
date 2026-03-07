-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"))()  -- Main lib

-- Buat Window
local Window = WindUI:CreateWindow("WindUI Hub 🔥", "Default")  -- Nama & theme

-- Tab
local Tab = Window:AddTab("Main")

-- Toggle
Tab:AddToggle("Auto Farm", false, function(state)
    print("Farm:", state)
end)

-- Slider
Tab:AddSlider("Speed", 16, 500, 50, function(value)
    print("Speed:", value)
end)

-- Button
Tab:AddButton("Test", function()
    WindUI:Notify("Success!", "WindUI Work Bro!")
end)

print("WindUI Loaded! Docs: footagesus.github.io/WindUI-Docs")
