-- XKID.HUB

Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

local Win = Library:Window("XKID.HUB", "crown", "Version 1.0 | by XKID", false)

Win:TabSection("XKID HUB")

local Main = Win:Tab("Main", "home")
local Player = Win:Tab("Player", "user")

local MainPage = Main:Page("Main", "menu")
local PlayerPage = Player:Page("Player Mods", "zap")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

------------------------------------------------
-- INFO
------------------------------------------------

MainPage:Paragraph("Welcome","Welcome to XKID.HUB Script")

------------------------------------------------
-- ANTI AFK
------------------------------------------------

MainPage:Toggle("Anti AFK","antiafk",false,"Prevent AFK kick","Left",function(state)

if state then

local vu = game:GetService("VirtualUser")

LocalPlayer.Idled:Connect(function()

vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
task.wait(1)
vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)

end)

end

end)

------------------------------------------------
-- SPEED
------------------------------------------------

PlayerPage:Slider("WalkSpeed","speed",16,200,16,function(val)

if LocalPlayer.Character then
LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
end

end,"Change player speed")

------------------------------------------------
-- JUMP
------------------------------------------------

PlayerPage:Slider("JumpPower","jump",50,200,50,function(val)

if LocalPlayer.Character then
LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
end

end,"Change jump power")

------------------------------------------------
-- INFINITE JUMP
------------------------------------------------

local infjump = false

PlayerPage:Toggle("Infinite Jump","infjump",false,"Jump unlimited times","Right",function(state)

infjump = state

end)

game:GetService("UserInputService").JumpRequest:Connect(function()

if infjump then

local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
humanoid:ChangeState("Jumping")

end

end)

------------------------------------------------
-- FLY
------------------------------------------------

local flying = false

PlayerPage:Toggle("Fly","fly",false,"Fly around the map","Right",function(state)

flying = state

if flying then

local char = LocalPlayer.Character
local hrp = char:WaitForChild("HumanoidRootPart")

local bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(100000,100000,100000)
bv.Parent = hrp

while flying do

bv.Velocity = workspace.CurrentCamera.CFrame.LookVector * 60
task.wait()

end

bv:Destroy()

end

end)

------------------------------------------------
-- NOTIFICATION
------------------------------------------------

Library:Notification("XKID.HUB","Loaded Successfully!",5)

Library:ConfigSystem(Win)