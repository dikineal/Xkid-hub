-- Fluent UI Library - Contoh Dasar
-- Copy-paste ke Roblox Executor

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ===== MEMBUAT WINDOW =====
local Window = Fluent:CreateWindow({
    Title = "My Fluent Script",
    SubTitle = "v1.0 - Made with Fluent",
    TabWidth = 160,
    Size = UDim2.new(0, 580, 0, 460),
    Acrylic = true, -- Blur effect
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- ===== TAB 1: HOME =====
local Tabs = {}
Tabs.Home = Window:AddTab({ Icon = "rbxasset://textures/Cursor.png", Title = "Home" })

Tabs.Home:AddParagraph({
    Title = "Welcome!",
    Content = "Ini adalah contoh script menggunakan Fluent UI Library."
})

Tabs.Home:AddButton({
    Title = "Click Me",
    Description = "Tombol yang bisa di-click",
    Callback = function()
        print("Button clicked!")
    end
})

Tabs.Home:AddToggle("Toggle1", {
    Title = "Enable Feature",
    Default = false,
    Callback = function(Value)
        print("Toggle state:", Value)
    end
})

-- ===== TAB 2: FEATURES =====
Tabs.Features = Window:AddTab({ Icon = "rbxasset://textures/Cursor.png", Title = "Features" })

-- Slider
Tabs.Features:AddSlider("Slider1", {
    Title = "Speed",
    Description = "Ubah kecepatan",
    Min = 0,
    Max = 100,
    Rounding = 1,
    Default = 50,
    Callback = function(Value)
        print("Speed:", Value)
    end
})

-- Input Box
Tabs.Features:AddInput("Input1", {
    Title = "Text Input",
    Default = "",
    Placeholder = "Enter text here...",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        print("Input:", Value)
    end
})

-- Dropdown
Tabs.Features:AddDropdown("Dropdown1", {
    Title = "Choose Option",
    Values = {"Option 1", "Option 2", "Option 3", "Option 4"},
    Multi = false,
    Default = 1,
    Callback = function(Value)
        print("Selected:", Value)
    end
})

-- Multi Select Dropdown
Tabs.Features:AddMultiselect("Multiselect1", {
    Title = "Multi Select",
    Values = {"Item 1", "Item 2", "Item 3"},
    Default = {},
    Callback = function(Value)
        print("Selected items:", Value)
    end
})

-- ===== TAB 3: SETTINGS =====
Tabs.Settings = Window:AddTab({ Icon = "rbxasset://textures/Cursor.png", Title = "Settings" })

-- Color Picker
Tabs.Settings:AddColorpicker("Colorpicker1", {
    Title = "Pick Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        print("Color:", Value)
    end
})

-- Keybind
Tabs.Settings:AddKeybind("Keybind1", {
    Title = "Toggle Keybind",
    Default = Enum.KeyCode.T,
    Hold = false,
    Callback = function()
        print("Keybind activated!")
    end
})

-- Section
local Section = Tabs.Settings:AddSection("Other Settings")

Tabs.Settings:AddToggle("Toggle2", {
    Title = "Auto Save",
    Default = true,
    Callback = function(Value)
        print("Auto save:", Value)
    end
})

Tabs.Settings:AddButton({
    Title = "Reset Settings",
    Description = "Reset semua setting ke default",
    Callback = function()
        print("Settings reset!")
    end
})

-- ===== TAB 4: INFO =====
Tabs.Info = Window:AddTab({ Icon = "rbxasset://textures/Cursor.png", Title = "Info" })

Tabs.Info:AddParagraph({
    Title = "About This Script",
    Content = "Script ini dibuat menggunakan Fluent UI Library. Fluent adalah library UI modern dengan desain yang bagus dan banyak fitur."
})

Tabs.Info:AddButton({
    Title = "Destroy UI",
    Description = "Tutup script ini",
    Callback = function()
        Window:Destroy()
        print("UI destroyed!")
    end
})

-- ===== KONFIGURASI PENYIMPANAN =====
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Menambahkan ignore list untuk SaveManager
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

-- Membuat folder config
SaveManager:BuildConfigSection(Tabs.Settings)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

-- Load config jika ada
SaveManager:LoadAutoloadConfig()

print("Fluent UI loaded successfully!")
print("Press LEFT CTRL to minimize/maximize")
