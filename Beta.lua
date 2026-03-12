--[[
WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]

-- XKID SIMPLE AFK - HANYA ANTI AFK
-- Fitur: Anti AFK (cegah disconnect otomatis)

-- Load Aurora UI
Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- ============================================
-- WINDOW SEDERHANA
-- ============================================
local Win = Library:Window(
    "⏰ XKID AFK",
    "clock",
    "Hanya Anti AFK",
    false
)

-- ============================================
-- TAB MENU
-- ============================================
local MainTab = Win:Tab("Anti AFK", "clock")
local MainPage = MainTab:Page("Controls", "clock")
local MainSection = MainPage:Section("⏰ Anti AFK", "Left")

-- ============================================
-- ANTI AFK TOGGLE
-- ============================================
MainSection:Toggle("Anti AFK", "AntiAFKToggle", false, "Cegah disconnect otomatis", function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        Library:Notification("Anti AFK", "Aktif", 2)
    else
        Library:Notification("Anti AFK", "Mati", 2)
    end
end)

-- ============================================
-- INITIALISASI
-- ============================================
Library:Notification("XKID AFK", "Hanya fitur Anti AFK", 3)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   ⏰ XKID AFK                           ║")
print("║   Hanya fitur Anti AFK                  ║")
print("╚══════════════════════════════════════════╝")