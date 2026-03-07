-- Load WindUI (Modern & Stabil di Android 2026)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"))()

-- Buat Window (ukuran mobile-friendly)
local Window = WindUI:CreateWindow("Anti AFK Mobile 🔥", {
    Size = UDim2.fromOffset(400, 300),  -- Cocok layar HP
    Theme = "Dark"  -- Dark mode biar hemat baterai & enak mata
})

-- Tab Utama
local Tab = Window:AddTab("Anti AFK")

-- Variables
local player = game.Players.LocalPlayer
local vu = game:GetService("VirtualUser")
local rs = game:GetService("RunService")
local connection = nil
local enabled = false
local interval = 30  -- Detik default (bisa slider)
local mode = "Mouse Move"  -- Default mode

-- Toggle Enable
Tab:AddToggle("Enable Anti AFK", {
    Default = false,
    Callback = function(state)
        enabled = state
        if state then
            WindUI:Notify("Anti AFK AKTIF!", "Mode: " .. mode .. " | Interval: " .. interval .. " detik")
            startAntiAfk()
        else
            WindUI:Notify("Anti AFK MATI!", "Aman, stop.")
            stopAntiAfk()
        end
    end
})

-- Dropdown Mode (pilih sentuh layar)
Tab:AddDropdown("Pilih Mode", {
    Options = {"Mouse Move", "Jump", "Hold W"},
    Default = "Mouse Move",
    Callback = function(selected)
        mode = selected
        WindUI:Notify("Mode Diubah!", "Sekarang: " .. selected)
    end
})

-- Slider Interval (sentuh drag mudah di HP)
Tab:AddSlider("Interval (detik)", {
    Min = 10,
    Max = 120,
    Default = 30,
    Increment = 5,
    Callback = function(value)
        interval = value
        WindUI:Notify("Interval Baru", value .. " detik")
    end
})

-- Button Test Cepat (buat cek langsung)
Tab:AddButton("Test 15 Detik", function()
    WindUI:Notify("Test Mulai!", "Spam input 15 detik...")
    spawn(function()
        for i = 1, 15 do
            vu:ClickButton2(Vector2.new(math.random(50, 300), math.random(50, 300)))  -- Random posisi touch
            wait(1)
        end
        WindUI:Notify("Test Selesai!", "Gak kick kan? ✅")
    end)
end)

-- Status Label (update otomatis)
local status = Tab:AddLabel("Status: OFF | Mode: Mouse Move | Interval: 30s")

-- Fungsi utama
function startAntiAfk()
    stopAntiAfk()  -- Bersihin kalau ada koneksi lama
    connection = player.Idled:Connect(function()
        wait(math.random(interval * 0.8, interval * 1.2))  -- Random delay biar natural
        if mode == "Mouse Move" then
            vu:ClickButton2(Vector2.new(math.random(0, 500), math.random(0, 500)))  -- Simulasi touch/mouse
        elseif mode == "Jump" then
            keypress(0x20)  -- Space
            wait(0.05)
            keyrelease(0x20)
        elseif mode == "Hold W" then
            keypress(0x57)  -- W
            wait(0.4)
            keyrelease(0x57)
        end
        vu:CaptureController()
        status:Set("Status: ON | Mode: " .. mode .. " | Interval: " .. interval .. "s")
    end)
end

function stopAntiAfk()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    status:Set("Status: OFF | Mode: " .. mode .. " | Interval: " .. interval .. "s")
end

print("Anti AFK Mobile Loaded! Test di game kosong dulu ya bro. 😎")
