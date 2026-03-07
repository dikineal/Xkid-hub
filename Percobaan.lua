local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

-------------------------------------------------
-- WINDOW
-------------------------------------------------

local Window = Fluent:CreateWindow({
    Title = "DIKI PROJECT",
    SubTitle = "by Diki",
    TabWidth = 120,
    Size = UDim2.fromOffset(420,300),
    Acrylic = true,
    Theme = "Dark"
})

-------------------------------------------------
-- PINK THEME
-------------------------------------------------

Fluent:SetTheme({
    Accent = Color3.fromRGB(255,105,180),
    Background = Color3.fromRGB(30,30,30),
    Text = Color3.fromRGB(255,255,255)
})

-------------------------------------------------
-- TAB
-------------------------------------------------

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-------------------------------------------------
-- ANTI AFK TOGGLE
-------------------------------------------------

local AntiAFK = Tabs.Main:AddToggle("AntiAFK", {
    Title = "Anti AFK",
    Default = false
})

AntiAFK:OnChanged(function()

    if Fluent.Options.AntiAFK.Value then

        local vu = game:GetService("VirtualUser")

        _G.afk = true

        task.spawn(function()
            while _G.afk do
                vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                task.wait(30)
            end
        end)

    else
        _G.afk = false
    end

end)

-------------------------------------------------
-- FLY TOGGLE
-------------------------------------------------

local FlyToggle = Tabs.Main:AddToggle("Fly", {
    Title = "Fly",
    Default = false
})

FlyToggle:OnChanged(function()

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    if Fluent.Options.Fly.Value then

        local BV = Instance.new("BodyVelocity")
        BV.MaxForce = Vector3.new(100000,100000,100000)
        BV.Velocity = Vector3.new(0,50,0)
        BV.Parent = hrp

        _G.fly = BV

    else

        if _G.fly then
            _G.fly:Destroy()
        end

    end

end)

-------------------------------------------------
-- MINIMIZE BUTTON
-------------------------------------------------

Tabs.Main:AddButton({
    Title = "Minimize UI",
    Description = "Sembunyikan UI",
    Callback = function()
        Fluent:Minimize()
    end
})

-------------------------------------------------
-- NOTIFY
-------------------------------------------------

Fluent:Notify({
    Title = "DIKI PROJECT",
    Content = "Loaded Successfully",
    Duration = 5
})

Window:SelectTab(1)
