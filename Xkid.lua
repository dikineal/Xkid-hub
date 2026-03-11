--====================================================
-- XKID_HUB MODAL TEMPLATE
-- Clean UI • Anti AFK
--====================================================

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer

-- UI Library
local Modal = loadstring(game:HttpGet("https://github.com/BloxCrypto/Modal/releases/download/v1.0-beta/main.lua"))()

local Window = Modal:CreateWindow({
    Title = "XKID_HUB",
    SubTitle = "Script Hub",
    Size = UDim2.fromOffset(420, 420),
    MinimumSize = Vector2.new(300, 250),
    Transparency = 0,
    Icon = "rbxassetid://68073547",
})

--====================================================
-- HOME TAB
--====================================================

local Home = Window:AddTab("Home")

Home:New("Title")({
    Title = "Welcome to XKID_HUB"
})

Home:New("Button")({
    Title = "Show Notification",
    Description = "Test notification system",
    Callback = function()

        Window:Notify({
            Title = "XKID_HUB",
            Description = "Hub working successfully",
            Duration = 5,
            Type = "Success"
        })

    end
})

--====================================================
-- SCRIPTS TAB
--====================================================

local Scripts = Window:AddTab("Scripts")

Scripts:New("Title")({
    Title = "Script Loader"
})

Scripts:New("Button")({
    Title = "Example Script",
    Description = "Run test script",
    Callback = function()
        print("Example script executed")
    end
})

--====================================================
-- UTILITY TAB
--====================================================

local Utility = Window:AddTab("Utility")

Utility:New("Title")({
    Title = "Utility Tools"
})

Utility:New("Button")({
    Title = "Print Position",
    Description = "Print player position",
    Callback = function()

        local pos = Player.Character.HumanoidRootPart.Position
        print("Position:", pos)

    end
})

Utility:New("Button")({
    Title = "Rejoin Server",
    Description = "Reconnect to server",
    Callback = function()

        game:GetService("TeleportService"):Teleport(game.PlaceId, Player)

    end
})

--====================================================
-- ANTI AFK
--====================================================

task.spawn(function()

    while task.wait(60) do

        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)

    end

end)

--====================================================
-- SETTINGS TAB
--====================================================

local Settings = Window:AddTab("Settings")

Settings:New("Dropdown")({
    Title = "Theme",
    Description = "Select UI theme",
    Options = { "Light", "Dark", "Midnight", "Rose", "Emerald" },
    Callback = function(Theme)
        Window:SetTheme(Theme)
    end,
})

Settings:New("Button")({
    Title = "Destroy GUI",
    Description = "Remove UI",
    Callback = function()
        Window:Destroy()
    end
})

-- Default UI settings
Window:SetTab("Home")
Window:SetTheme("Midnight")