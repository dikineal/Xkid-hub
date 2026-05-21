repeat task.wait() until game:IsLoaded()

----------------------------------------------------
-- SERVICES
----------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------
-- WINDUI
----------------------------------------------------
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

WindUI:SetTheme("Dark")

----------------------------------------------------
-- WINDOW
----------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "XKID HUB",
    Icon = "rbxassetid://129260712070456",
    Author = "XKID",
    Folder = "XKIDHub",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 200,
    User = {
        Enabled = true,
        Anonymous = false
    }
})

----------------------------------------------------
-- USER PROFILE
----------------------------------------------------
Window.User:SetDisplayName(LocalPlayer.DisplayName)
Window.User:SetUsername("@" .. LocalPlayer.Name)

Window.User:SetAvatar(
    "https://www.roblox.com/headshot-thumbnail/image?userId="
    .. LocalPlayer.UserId ..
    "&width=420&height=420&format=png"
)

----------------------------------------------------
-- TABS
----------------------------------------------------
local Main = Window:Tab({
    Title = "Main",
    Icon = "house"
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user"
})

local Settings = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

----------------------------------------------------
-- INFO
----------------------------------------------------
Main:Paragraph({
    Title = "Information",
    Desc = "Welcome to XKID HUB using latest WindUI."
})

----------------------------------------------------
-- BUTTON
----------------------------------------------------
Main:Button({
    Title = "Send Notification",
    Desc = "Test notification",
    Callback = function()
        WindUI:Notify({
            Title = "XKID HUB",
            Content = "Notification works perfectly.",
            Duration = 3,
            Icon = "bell"
        })
    end
})

----------------------------------------------------
-- INFINITE JUMP
----------------------------------------------------
getgenv().InfJump = false

PlayerTab:Toggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(state)
        getgenv().InfJump = state

        WindUI:Notify({
            Title = "Infinite Jump",
            Content = state and "Enabled" or "Disabled",
            Duration = 2
        })
    end
})

UserInputService.JumpRequest:Connect(function()
    if getgenv().InfJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

        if hum then
            hum:ChangeState("Jumping")
        end
    end
end)

----------------------------------------------------
-- WALKSPEED
----------------------------------------------------
PlayerTab:Slider({
    Title = "WalkSpeed",
    Step = 1,
    Value = {
        Min = 16,
        Max = 200,
        Default = 16
    },
    Callback = function(v)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

        if hum then
            hum.WalkSpeed = v
        end
    end
})

----------------------------------------------------
-- JUMPPOWER
----------------------------------------------------
PlayerTab:Slider({
    Title = "JumpPower",
    Step = 1,
    Value = {
        Min = 50,
        Max = 300,
        Default = 50
    },
    Callback = function(v)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

        if hum then
            hum.JumpPower = v
        end
    end
})

----------------------------------------------------
-- THEME DROPDOWN
----------------------------------------------------
Settings:Dropdown({
    Title = "Select Theme",
    Values = {
        "Dark",
        "Light",
        "Rose",
        "Sky",
        "Emerald",
        "Violet",
        "Red"
    },
    Callback = function(theme)
        WindUI:SetTheme(theme)

        WindUI:Notify({
            Title = "Theme Changed",
            Content = theme,
            Duration = 2
        })
    end
})

----------------------------------------------------
-- KEYBIND
----------------------------------------------------
Settings:Keybind({
    Title = "Toggle UI",
    Value = "RightControl",
    Callback = function(v)
        Window:SetToggleKey(v)
    end
})

----------------------------------------------------
-- OPEN BUTTON
----------------------------------------------------
Window:EditOpenButton({
    Title = "XKID",
    Icon = "monitor",
    CornerRadius = UDim.new(0,12),
    StrokeThickness = 2,
    Enabled = true,
    Draggable = true
})

----------------------------------------------------
-- TAGS
----------------------------------------------------
Window:Tag({
    Title = "WindUI Latest",
    Color = Color3.fromRGB(0,170,255)
})

local FpsTag = Window:Tag({
    Title = "FPS: ... | Ping: ...",
    Color = Color3.fromRGB(0,170,255)
})

----------------------------------------------------
-- FPS / PING
----------------------------------------------------
task.spawn(function()

    local lastTime = os.clock()
    local frames = 0

    RunService.RenderStepped:Connect(function()
        frames += 1
    end)

    while task.wait(1) do

        local now = os.clock()

        local fps = math.floor(
            frames / (now - lastTime)
        )

        frames = 0
        lastTime = now

        local ping = 0

        pcall(function()
            ping = math.floor(
                StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
            )
        end)

        FpsTag:SetTitle(
            string.format(
                "FPS: %d | Ping: %d ms",
                fps,
                ping
            )
        )
    end
end)

----------------------------------------------------
-- STARTUP
----------------------------------------------------
WindUI:Notify({
    Title = "XKID HUB",
    Content = "Successfully Loaded",
    Duration = 4,
    Icon = "check"
})