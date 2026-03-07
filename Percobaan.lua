local SolarisLib = loadstring(game:HttpGet("https://solarishub.dev/SolarisLib.lua"))()

local win = SolarisLib:New({
    Name = "Test Hub",
    FolderToSave = "TestHub"
})

local tab = win:Tab("Main")
local section = tab:Section("Player")

section:Toggle("Anti AFK", false, function(state)
    if state then
        local vu = game:GetService("VirtualUser")
        game:GetService("Players").LocalPlayer.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            wait(1)
            vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)
    end
end)
