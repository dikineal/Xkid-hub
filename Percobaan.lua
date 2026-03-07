local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

local Window = Fluent:CreateWindow({
    Title = "DIKI PROJECT",
    SubTitle = "by Diki",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, -- Efek blur transparan (sangat modern)
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Keybind untuk sembunyiin UI
})

-- Membuat Tab
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Menambahkan Toggle (On/Off)
local Toggle = Tabs.Main:AddToggle("MyToggle", {Title = "Auto Jump", Default = false })

Toggle:OnChanged(function()
    _G.AutoJump = Fluent.Options.MyToggle.Value
    spawn(function()
        while _G.AutoJump do
            if game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Jump = true
            end
            task.wait(0.1)
        end
    end)
end)

-- Menambahkan Slider
local Slider = Tabs.Main:AddSlider("WalkSpeed", {
    Title = "Speed Hack",
    Description = "Atur kecepatan lari",
    Default = 16,
    Min = 16,
    Max = 300,
    Rounding = 1,
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end
})

-- Menambahkan Button
Tabs.Main:AddButton({
    Title = "Anti-AFK",
    Description = "Cegah Disconnect",
    Callback = function()
        print("Anti-AFK Aktif!")
        -- Kode Anti-AFK kamu di sini
    end
})

-- Notifikasi saat berhasil load
Fluent:Notify({
    Title = "Success",
    Content = "Fluent Renewed Loaded!",
    Duration = 5
})

Window:SelectTab(1)
