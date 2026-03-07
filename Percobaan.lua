local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

-- WINDOW
local Window = Fluent:CreateWindow({
    Title = "DIKI PROJECT",
    SubTitle = "by Diki",
    TabWidth = 120,
    Size = UDim2.fromOffset(420, 320),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- PINK THEME
Fluent:SetTheme({
    Accent = Color3.fromRGB(255,105,180),
    Background = Color3.fromRGB(25,25,25),
    Text = Color3.fromRGB(255,255,255)
})

-- TAB
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ANTI AFK
Tabs.Main:AddButton({
    Title = "Anti AFK",
    Description = "Mencegah kick idle",

    Callback = function()
        local vu = game:GetService("VirtualUser")

        LocalPlayer.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)

        Fluent:Notify({
            Title = "Anti AFK",
            Content = "Anti AFK berhasil aktif",
            Duration = 4
        })
    end
})

-- AUTO FLY
local Fly = Tabs.Main:AddToggle("Fly", {
    Title = "Auto Fly",
    Default = false
})

Fly:OnChanged(function()
    local flying = Fluent.Options.Fly.Value
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    if flying then
        
        local BV = Instance.new("BodyVelocity")
        BV.MaxForce = Vector3.new(100000,100000,100000)
        BV.Velocity = Vector3.new(0,50,0)
        BV.Parent = hrp

        _G.FlyBV = BV

    else
        
        if _G.FlyBV then
            _G.FlyBV:Destroy()
        end
        
    end
end)

-- NOTIFY
Fluent:Notify({
    Title = "DIKI PROJECT",
    Content = "Script Loaded",
    Duration = 5
})

Window:SelectTab(1)
