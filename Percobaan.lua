local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

-- WINDOW
local Window = Fluent:CreateWindow({
    Title = "DIKI PROJECT",
    SubTitle = "by Diki",
    TabWidth = 130,
    Size = UDim2.fromOffset(480, 360),
    Acrylic = true,
    Theme = "Dark",
})

-- PINK THEME
Fluent:SetTheme({
    Accent = Color3.fromRGB(255,105,180),
    Background = Color3.fromRGB(25,25,25),
    Text = Color3.fromRGB(255,255,255),
})

-- TAB
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- AUTO JUMP
local Toggle = Tabs.Main:AddToggle("AutoJump", {
    Title = "Auto Jump",
    Default = false
})

Toggle:OnChanged(function()
    _G.AutoJump = Fluent.Options.AutoJump.Value

    task.spawn(function()
        while _G.AutoJump do
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char.Humanoid.Jump = true
            end
            task.wait(0.1)
        end
    end)
end)

-- SPEED
Tabs.Main:AddSlider("WalkSpeed", {
    Title = "Speed Hack",
    Default = 16,
    Min = 16,
    Max = 200,
    Callback = function(Value)
        local char = game.Players.LocalPlayer.Character
        if char then
            char.Humanoid.WalkSpeed = Value
        end
    end
})

-- ANTI AFK
Tabs.Main:AddButton({
    Title = "Anti AFK",
    Callback = function()
        local vu = game:GetService("VirtualUser")
        game.Players.LocalPlayer.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)
    end
})

-- MINIMIZE BUTTON DI BAGIAN BAWAH
Tabs.Settings:AddButton({
    Title = "Minimize UI",
    Description = "Sembunyikan UI",

    Callback = function()
        Fluent:Minimize()
    end
})

-- NOTIFY
Fluent:Notify({
    Title = "Success",
    Content = "DIKI PROJECT Loaded",
    Duration = 5
})

Window:SelectTab(1)
