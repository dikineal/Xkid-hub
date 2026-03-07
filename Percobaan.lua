-- Load Visual UI (mirip Chloe style)
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/VisualRoblox/Roblox/main/UI-Libraries/Visual%20UI%20Library/Source.lua'))()

-- Buat Window
local Window = Library:CreateWindow("Anti AFK Hub - Chloe Style 🔥", {
    MainColor = Color3.fromRGB(30, 30, 35),  -- Dark theme
    AccentColor = Color3.fromRGB(0, 170, 255),
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Tab
local Tab = Window:CreateTab("Anti AFK")

-- Variables
local player = game.Players.LocalPlayer
local vu = game:GetService("VirtualUser")
local connection = nil
local enabled = false
local interval = 30

-- Toggle
Tab:CreateToggle("Enable Anti AFK", false, function(state)
    enabled = state
    if state then
        Library:Notify("Anti AFK ON!", "Interval: " .. interval .. "s", 5)
        connection = player.Idled:Connect(function()
            wait(interval + math.random(-5,5))
            vu:ClickButton2(Vector2.new())  -- Mouse move safe
            vu:CaptureController()
        end)
    else
        Library:Notify("Anti AFK OFF!", "Stopped", 5)
        if connection then connection:Disconnect() end
    end
end)

-- Slider
Tab:CreateSlider("Interval (detik)", 10, 120, 30, function(value)
    interval = value
end)

-- Button Test
Tab:CreateButton("Test 10s", function()
    Library:Notify("Test Mulai!", "Spam input 10 detik...", 5)
    for i=1,10 do
        vu:ClickButton2(Vector2.new(math.random(100,400), math.random(100,400)))
        wait(1)
    end
    Library:Notify("Test Selesai!", "No kick? ✅", 5)
end)

print("Visual UI Loaded - Mirip Chloe! Test di Baseplate ya bro.")
