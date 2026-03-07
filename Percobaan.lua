local Mercury = loadstring(game:HttpGet("https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"))()

local Window = Mercury:Create{
    Name = "DIKI PROJECT",
    Size = UDim2.fromOffset(600, 400),
    Theme = Mercury.Themes.Dark,
    Link = "https://github.com/deeeity/mercury-lib"
}

-- Membuat Tab Utama
local MainTab = Window:Tab{
    Name = "Main Features",
    Icon = "rbxassetid://4370698314" -- Ikon Home
}

-- Menambahkan Label (Teks Info)
MainTab:Label{
    Text = "Selamat datang, " .. game.Players.LocalPlayer.Name
}

-- Tombol (Button)
MainTab:Button{
    Name = "Anti-AFK",
    Description = "Mencegah kamu terputus dari server",
    Callback = function()
        local vu = game:GetService("VirtualUser")
        game:GetService("Players").LocalPlayer.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            wait(1)
            vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)
        Mercury:Notify{
            Title = "Anti-AFK",
            Content = "Anti-AFK Berhasil diaktifkan!",
            Time = 3
        }
    end
}

-- Saklar (Toggle)
MainTab:Toggle{
    Name = "Auto Jump",
    StartingState = false,
    Description = "Lompat otomatis terus menerus",
    Callback = function(state)
        _G.AutoJump = state
        spawn(function()
            while _G.AutoJump do
                game:GetService("Players").LocalPlayer.Character.Humanoid.Jump = true
                wait(0.1)
            end
        end)
    end
}

-- Geser (Slider)
MainTab:Slider{
    Name = "WalkSpeed",
    Variant = "Standard", -- Bisa "Standard" atau "Precise"
    Default = 16,
    Min = 16,
    Max = 250,
    Description = "Atur kecepatan lari karakter",
    Callback = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
}

-- Pilihan (Dropdown)
MainTab:Dropdown{
    Name = "Teleport Area",
    StartingText = "Pilih Lokasi...",
    Description = "Pilih tempat untuk berpindah",
    Items = {"Lobby", "Farm", "Shop", "Boss"},
    Callback = function(item)
        print("Teleport ke: " .. item)
    end
}

-- Kotak Input (Textbox)
MainTab:Textbox{
    Name = "Jump Power",
    Callback = function(text)
        local num = tonumber(text)
        if num then
            game.Players.LocalPlayer.Character.Humanoid.JumpPower = num
        end
    end
}

-- Tab Pengaturan
local SettingsTab = Window:Tab{
    Name = "Settings",
    Icon = "rbxassetid://4370698314"
}

SettingsTab:Button{
    Name = "Destroy UI",
    Callback = function()
        Window:Notification{
            Title = "Shutdown",
            Content = "Menghapus UI...",
            Time = 2
        }
        wait(2)
        game:GetService("CoreGui"):FindFirstChild("Mercury"):Destroy()
    end
}
