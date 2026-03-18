-- =====================================================
-- ╔═══╗╔═══╗╔══╗╔═══╗╔═══╗     ╔═══╗╔╗  ╔╗╔═══╗
-- ║╔══╝║╔══╝║╔╗║║╔═╗║║╔══╝     ║╔══╝║║  ║║║╔═╗║
-- ║╚══╗║╚══╗║╚╝║║╚═╝║║╚══╗     ║╚══╗║╚╗╔╝║║╚═╝║
-- ║╔══╝║╔══╝║╔╗║║╔╗╔╝║╔══╝     ║╔══╝║╔╗╔╗║║╔╗╔╝
-- ║╚══╗║╚══╗║║║║║║║╚╗║╚══╗     ║╚══╗║║╚╝║║║║║╚╗
-- ╚═══╝╚═══╝╚╝╚╝╚╝╚═╝╚═══╝     ╚═══╝╚╝  ╚╝╚╝╚═╝
-- =====================================================
--              XKID HUB - FIXED VERSION
--     Semua Fitur 100% BERFUNGSI & TERLIHAT
-- =====================================================

-- PAKAI LIBRARY ALTERNATIF YANG STABLE
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("XKID HUB PREMIUM", "DarkTheme")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================
local function getChar()
    return LP.Character
end

local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- Save last position
local lastPos = nil
spawn(function()
    while wait(0.1) do
        local root = getRoot()
        if root then
            lastPos = root.CFrame
        end
    end
end)

-- =====================================================
-- TAB 1: HOME
-- =====================================================
local HomeTab = Window:NewTab("🏠 HOME")
local HomeSection = HomeTab:NewSection("SYSTEM INFO")

HomeSection:NewLabel("✨ XKID HUB PREMIUM - FIXED VERSION