-- XKID HUB WindUI Full Starter
-- Ready-to-copy foundation with tabs and core settings.
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Window = WindUI:CreateWindow({Title="XKID HUB FINAL",Author="XKID",Folder="xkid",Icon="zap",Theme="Dark",Acrylic=false,Transparent=true,Size=UDim2.fromOffset(700,480),ToggleKey=Enum.KeyCode.RightShift,Resizable=true,AutoScale=true})
local tabs={
tele=Window:Tab({Title="Teleport",Icon="map-pin"}),
player=Window:Tab({Title="Player",Icon="user"}),
cin=Window:Tab({Title="Cinematic",Icon="video"}),
spec=Window:Tab({Title="Spectate",Icon="eye"}),
world=Window:Tab({Title="World",Icon="globe"}),
sec=Window:Tab({Title="Security",Icon="shield"}),
set=Window:Tab({Title="Settings",Icon="settings"}),}

-- Teleport
 tabs.tele:Input({Title="Player Name",Placeholder="type name",Callback=function() end})
 tabs.tele:Button({Title="Teleport Now",Callback=function() end})
-- Player
 tabs.player:Slider({Title="WalkSpeed",Value={Min=16,Max=500,Default=16},Callback=function(v) local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed=v end end})
 tabs.player:Slider({Title="JumpPower",Value={Min=50,Max=500,Default=50},Callback=function(v) local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") if h then h.UseJumpPower=true h.JumpPower=v end end})
 tabs.player:Toggle({Title="Fly",Value=false,Callback=function(s) end})
 tabs.player:Toggle({Title="NoClip",Value=false,Callback=function(s) _G.noclip=s end})
-- Cinematic
 tabs.cin:Toggle({Title="Freecam",Value=false,Callback=function(s) end})
 tabs.cin:Slider({Title="FOV",Value={Min=10,Max=120,Default=70},Callback=function(v) workspace.CurrentCamera.FieldOfView=v end})
-- Spectate
 tabs.spec:Button({Title="Refresh Players",Callback=function() end})
 tabs.spec:Toggle({Title="Spectate",Value=false,Callback=function(s) end})
-- World
 tabs.world:Button({Title="Day",Callback=function() game:GetService("Lighting").ClockTime=14 end})
 tabs.world:Button({Title="Night",Callback=function() game:GetService("Lighting").ClockTime=0 end})
-- Security
 tabs.sec:Toggle({Title="ESP",Value=false,Callback=function(s) _G.esp=s end})
 tabs.sec:Button({Title="Rejoin",Callback=function() game:GetService("TeleportService"):Teleport(game.PlaceId,LP) end})
-- Settings
 tabs.set:Button({Title="Destroy UI",Callback=function() Window:Destroy() end})
-- Extended feature placeholders + integrated loops
spawn(function() while task.wait() do if _G.noclip and LP.Character then for _,v in pairs(LP.Character:GetDescendants()) do if v:IsA('BasePart') then v.CanCollide=false end end end end end)
WindUI:Notify({Title="XKID HUB",Content="WindUI Full Extended Loaded"})
