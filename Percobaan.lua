-- Load Library
local SolarisLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/sol"))()

-- Buat Window Utama (ganti Name & FolderToSave sesuka hati)
local win = SolarisLib:New({
    Name = "My Awesome Hub",  -- Judul GUI
    FolderToSave = "MyHub"    -- Folder buat save settings/config (otomatis dibuat)
})

-- Tab 1: Main
local tab1 = win:Tab("Main")

local sec1 = tab1:Section("Controls")  -- Section = grup elemen

-- Button (jalanin fungsi pas diklik)
sec1:Button("Test Button", function()
    SolarisLib:Notification("Success!", "Button diklik bro!")  -- Notif toast
end)

-- Toggle (on/off switch, callback dapet state true/false)
local myToggle = sec1:Toggle("Auto Farm", false, "autoFarmFlag", function(state)
    print("Auto Farm:", state)  -- Ganti print() sama logic kamu
    -- Contoh: getgenv().AutoFarm = state
end)
-- Update toggle dari luar: myToggle:Set(true)

-- Slider (nilai angka)
local mySlider = sec1:Slider("Speed", 0, 100, 50, 1, "speedFlag", function(value)
    print("Speed:", value)
end)
-- Update: mySlider:Set(75)

-- Dropdown (pilih 1)
local myDrop = sec1:Dropdown("Mode", {"Easy", "Normal", "Hard"}, "Normal", "modeFlag", function(selected)
    print("Mode:", selected)
end)
-- Update: myDrop:Set("Hard") atau myDrop:Refresh({"New1", "New2"}, true)

-- Multi Dropdown (pilih banyak)
local myMulti = sec1:MultiDropdown("Items", {"A", "B", "C", "D"}, {"B"}, "itemsFlag", function(selectedTable)
    print("Selected:", table.concat(selectedTable, ", "))
end)

-- Tab 2: Settings
local tab2 = win:Tab("Settings")

local sec2 = tab2:Section("Other")

-- Colorpicker
sec2:Colorpicker("Accent Color", Color3.fromRGB(255, 0, 0), "colorFlag", function(color)
    print("Color:", color)
end)

-- Textbox (input teks)
sec2:Textbox("Enter Name", true, function(text)  -- true = hilang setelah enter
    print("Input:", text)
end)

-- Keybind
sec2:Bind("Bind Key", Enum.KeyCode.E, false, "bindFlag", function(key)
    print("Bound:", key.Name)
end)

-- Label (teks statis, bisa diupdate)
local myLabel = sec2:Label("Status: Ready")
-- Update: myLabel:Set("Status: Running")

-- Simpan config (opsional, auto save pas close)
SolarisLib:SaveCfg("config1")  -- Simpan ke MyHub/configs/config1.txt
-- Load: SolarisLib:LoadCfg("config1")
