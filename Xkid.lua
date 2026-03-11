--====================================================
-- XKID_HUB
-- 3itx UI LIB
--====================================================

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Just3itx/3itx-UI-LIB/refs/heads/main/Lib"))()
local FlagsManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Just3itx/3itx-UI-LIB/refs/heads/main/ConfigManager"))()

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--====================================================
-- WINDOW
--====================================================

local main = lib:Load({
    Title = "XKID_HUB",
    ToggleButton = "rbxassetid://7733658504",
    BindGui = Enum.KeyCode.RightControl
})

local Main = main:AddTab("Main")
main:SelectTab()

--====================================================
-- SECTION
--====================================================

local MainSection = Main:AddSection({
    Title = "Player Controls",
    Description = "Movement & Utility",
    Defualt = false,
    Locked = false
})

--====================================================
-- ANTI AFK
--====================================================

local AntiAFK = false

MainSection:AddToggle("AntiAFK",{
    Title = "Anti AFK",
    Default = false,
    Callback = function(state)
        AntiAFK = state
    end
})

task.spawn(function()
    while task.wait(60) do
        if AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

--====================================================
-- WALK SPEED
--====================================================

MainSection:AddSlider("WalkSpeed",{
    Title = "WalkSpeed",
    Default = 16,
    Min = 10,
    Max = 200,
    Increment = 1,
    Callback = function(value)

        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.WalkSpeed = value
        end

    end
})

--====================================================
-- FLY
--====================================================

local Flying = false
local FlySpeed = 60
local BV

local function StartFly()

    local char = Player.Character or Player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(9e9,9e9,9e9)
    BV.Parent = root

    RunService.RenderStepped:Connect(function()

        if not Flying then
            if BV then BV:Destroy() end
            return
        end

        BV.Velocity = Camera.CFrame.LookVector * FlySpeed

    end)

end

MainSection:AddToggle("Fly",{
    Title = "Fly",
    Default = false,
    Callback = function(state)

        Flying = state

        if state then
            StartFly()
        end

    end
})

MainSection:AddSlider("FlySpeed",{
    Title = "Fly Speed",
    Default = 60,
    Min = 20,
    Max = 150,
    Increment = 1,
    Callback = function(value)
        FlySpeed = value
    end
})

--====================================================
-- CONFIG TAB
--====================================================

local Config = main:AddTab("Config")

FlagsManager:SetLibrary(lib)
FlagsManager:SetIgnoreIndexes({})
FlagsManager:SetFolder("XKID_HUB")
FlagsManager:InitSaveSystem(Config)

--====================================================
-- NOTIFICATION
--====================================================

lib:Notification("XKID_HUB","Loaded Successfully!",3)