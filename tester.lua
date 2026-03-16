local library = loadstring(game:HttpGet("https://thebasement.ink/BSMTUI"))()
local window = library:Create("BSMT Hub", UDim2.new(0, 500, 0, 400))

local Tab = window:Tab("Main", "rbxassetid://10734950309")
local Section = Tab:Section("Controls")

Section:Button("Notify Me", function()
    library:Notify({ Title = "Yo!", Text = "It works!", Type = "Info" })
end)

Section:Slider("WalkSpeed", 10, 100, 16, function(val)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
end)

Section:Dropdown("Mode", {"Classic", "Pro", "Insane"}, "Classic", function(mode)
    print("Selected:", mode)
end)

Section:Toggle("WallHack", false, function(state)
    print("WallHack active?", state)
end)

Section:TextBox("FOV Size", "90", function(text)
    print("FOV:", text)
end)