local Vape = loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4/main/main.lua"))()

-- ===== MEMBUAT WINDOW UTAMA =====
local Window = Vape:AddWindow({
    Title = "My Script",
    Icon = "rbxasset://textures/Cursor.png",
    Author = "You",
    HideKeyPress = false,
    KeyPress = Enum.KeyCode.RightControl
})

-- ===== TAB 1: FEATURES =====
local Tab1 = Window:AddTab({
    Name = "Features",
    Icon = "rbxasset://textures/Cursor.png"
})

-- Tombol sederhana
Tab1:AddButton({
    Title = "Click Me",
    Callback = function()
        print("Button clicked!")
    end
})

-- Toggle switch
Tab1:AddToggle({
    Title = "Enable Feature",
    Default = false,
    Callback = function(state)
        print("Toggle state:", state)
    end
})

-- Slider
Tab1:AddSlider({
    Title = "Speed",
    Min = 0,
    Max = 100,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        print("Speed:", value)
    end
})

-- Dropdown/Select
Tab1:AddDropdown({
    Title = "Choose Option",
    Options = {"Option 1", "Option 2", "Option 3"},
    Multi = false,
    Default = 1,
    Callback = function(value)
        print("Selected:", value)
    end
})

-- Text input
Tab1:AddTextbox({
    Title = "Enter Text",
    Default = "",
    PlaceHolder = "Type something...",
    ClearOnFocus = false,
    Callback = function(value)
        print("Typed:", value)
    end
})

-- ===== TAB 2: SETTINGS =====
local Tab2 = Window:AddTab({
    Name = "Settings",
    Icon = "rbxasset://textures/Cursor.png"
})

-- Color picker
Tab2:AddColorpicker({
    Title = "Pick Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        print("Color:", color)
    end
})

-- Keybind
Tab2:AddKeybind({
    Title = "Toggle Keybind",
    Default = Enum.KeyCode.T,
    Hold = false,
    Callback = function()
        print("Keybind pressed!")
    end
})

-- Section/Group
local Section = Tab2:AddSection({
    Name = "Other Settings"
})

Tab2:AddToggle({
    Title = "Another Toggle",
    Default = false,
    Callback = function(state)
        print("State:", state)
    end
})

-- ===== TAB 3: INFO =====
local Tab3 = Window:AddTab({
    Name = "Info",
    Icon = "rbxasset://textures/Cursor.png"
})

Tab3:AddLabel({
    Title = "This is a label",
    Text = "You can put information here"
})

Tab3:AddButton({
    Title = "Destroy UI",
    Callback = function()
        Window:Destroy()
    end
})

print("Vape UI loaded successfully!")
