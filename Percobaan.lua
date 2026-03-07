local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/R3TH-PRIV/R3THPRIV/main/RedzLibV2.lua"))()

-- Membuat Window Utama
local Window = Lib:MakeWindow({
  Title = "DIKI HUB",
  SubTitle = "Mobile Edition",
  SaveFolder = "DikiConfig.json"
})

-- Menambahkan Tab (Kategori)
Window:AddTab({
  Name = "Main",
  Icon = "rbxassetid://4483345998" -- Ikon Rumah
})

-- Membuat Section (Pemisah)
Window:AddSection({
  Name = "Player Menu"
})

-- Tombol (Button)
Window:AddButton({
  Name = "Anti-AFK",
  Callback = function()
      local vu = game:GetService("VirtualUser")
      game:GetService("Players").LocalPlayer.Idled:Connect(function()
          vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
          wait(1)
          vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
      end)
      print("Anti-AFK Aktif")
  end
})

-- On/Off (Toggle)
Window:AddToggle({
  Name = "Auto Jump",
  Default = false,
  Callback = function(Value)
      _G.AutoJump = Value
      while _G.AutoJump do
          game:GetService("Players").LocalPlayer.Character.Humanoid.Jump = true
          wait(0.1)
      end
  end
})

-- Pengaturan Angka (Slider)
Window:AddSlider({
  Name = "Speed",
  Min = 16,
  Max = 300,
  Increase = 1,
  Default = 16,
  Callback = function(Value)
      game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
  end
})

-- Pilihan (Dropdown)
Window:AddDropdown({
  Name = "Pilih Senjata",
  Options = {"Melee", "Sword", "Gun"},
  Default = "Melee",
  Callback = function(Value)
      print("Kamu memilih: " .. Value)
  end
})
