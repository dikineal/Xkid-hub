-- UI LIBRARY
local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-------------------------------------------------
-- WINDOW
-------------------------------------------------

local Window = Fluent:CreateWindow({
    Title = "DIKI PROJECT",
    SubTitle = "Mobile Edition",
    TabWidth = 90,
    Size = UDim2.fromOffset(260,200),
    Acrylic = true,
    Theme = "Dark"
})

Fluent:SetTheme({
    Accent = Color3.fromRGB(255,105,180)
})

-------------------------------------------------
-- TAB
-------------------------------------------------

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

-------------------------------------------------
-- ANTI AFK
-------------------------------------------------

local AntiAFK = Tabs.Main:AddToggle("AntiAFK",{Title="Anti AFK",Default=false})

AntiAFK:OnChanged(function(v)

    if v then

        local vu = game:GetService("VirtualUser")

        _G.AFK = true

        task.spawn(function()

            while _G.AFK do
                vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                task.wait(30)
            end

        end)

    else

        _G.AFK = false

    end

end)

-------------------------------------------------
-- MOBILE FLY
-------------------------------------------------

local FlyToggle = Tabs.Main:AddToggle("Fly",{Title="Fly (Mobile)",Default=false})

FlyToggle:OnChanged(function(state)

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")

    if state then

        local speed = 60

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e9,1e9,1e9)
        bv.Parent = hrp

        _G.fly = true
        _G.flybv = bv

        _G.flyloop = RunService.Heartbeat:Connect(function()

            if not _G.fly then return end

            local move = hum.MoveDirection

            bv.Velocity = Vector3.new(
                move.X * speed,
                25,
                move.Z * speed
            )

        end)

    else

        _G.fly = false

        if _G.flybv then
            _G.flybv:Destroy()
        end

        if _G.flyloop then
            _G.flyloop:Disconnect()
        end

    end

end)

-------------------------------------------------
-- MINIMIZE
-------------------------------------------------

Tabs.Main:AddButton({
    Title = "Minimize UI",
    Callback = function()
        Fluent:Minimize()
    end
})

-------------------------------------------------
-- NOTIFY
-------------------------------------------------

Fluent:Notify({
    Title = "DIKI PROJECT",
    Content = "Mobile Script Loaded",
    Duration = 5
})

Window:SelectTab(1)
