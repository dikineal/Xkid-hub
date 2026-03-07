--// LOAD LIBRARY
local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/main/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/main/Addons/InterfaceManager.lua"))()

--// SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

--// WINDOW
local Window = Fluent:CreateWindow({
    Title = "DIKI PROJECT",
    SubTitle = "Premium",
    TabWidth = 160,
    Size = UDim2.fromOffset(600,470),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

--// TABS
local Tabs = {
    Main = Window:AddTab({Title="Main",Icon="home"}),
    Player = Window:AddTab({Title="Player",Icon="user"}),
    Troll = Window:AddTab({Title="Troll",Icon="zap"}),
    Misc = Window:AddTab({Title="Misc",Icon="box"}),
    Settings = Window:AddTab({Title="Settings",Icon="settings"})
}

------------------------------------------------
-- AUTO JUMP
------------------------------------------------

local AutoJump=false

Tabs.Player:AddToggle("AutoJump",{Title="Auto Jump",Default=false}):OnChanged(function(v)
AutoJump=v

task.spawn(function()
while AutoJump do
pcall(function()
local hum=LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if hum then
hum.Jump=true
end
end)
task.wait(.1)
end
end)

end)

------------------------------------------------
-- SPEED
------------------------------------------------

Tabs.Player:AddSlider("Speed",{
Title="WalkSpeed",
Default=16,
Min=16,
Max=200,
Rounding=1,

Callback=function(v)

pcall(function()
LocalPlayer.Character.Humanoid.WalkSpeed=v
end)

end
})

------------------------------------------------
-- JUMP POWER
------------------------------------------------

Tabs.Player:AddSlider("Jump",{
Title="Jump Power",
Default=50,
Min=50,
Max=200,
Rounding=1,

Callback=function(v)

pcall(function()
LocalPlayer.Character.Humanoid.JumpPower=v
end)

end
})

------------------------------------------------
-- INFINITE JUMP
------------------------------------------------

local InfiniteJump=false

Tabs.Player:AddToggle("InfJump",{Title="Infinite Jump"}):OnChanged(function(v)
InfiniteJump=v
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
if InfiniteJump then
local hum=LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if hum then
hum:ChangeState("Jumping")
end
end
end)

------------------------------------------------
-- NOCLIP
------------------------------------------------

local noclip=false

Tabs.Player:AddToggle("Noclip",{Title="Noclip"}):OnChanged(function(v)
noclip=v
end)

RunService.Stepped:Connect(function()
if noclip then
for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
if v:IsA("BasePart") then
v.CanCollide=false
end
end
end
end)

------------------------------------------------
-- FLY
------------------------------------------------

local flying=false

Tabs.Player:AddToggle("Fly",{Title="Fly"}):OnChanged(function(v)

flying=v

if flying then

local char=LocalPlayer.Character
local hrp=char:WaitForChild("HumanoidRootPart")

local bg=Instance.new("BodyGyro",hrp)
local bv=Instance.new("BodyVelocity",hrp)

bg.P=9e4
bg.maxTorque=Vector3.new(9e9,9e9,9e9)

bv.maxForce=Vector3.new(9e9,9e9,9e9)

task.spawn(function()

while flying do

local cam=workspace.CurrentCamera

bg.CFrame=cam.CFrame
bv.Velocity=cam.CFrame.LookVector*100

task.wait()

end

bg:Destroy()
bv:Destroy()

end)

end

end)

------------------------------------------------
-- FLING PLAYER
------------------------------------------------

Tabs.Troll:AddInput("FlingPlayer",{
Title="Fling Player",
Placeholder="Player Name",

Callback=function(name)

local target=nil

for _,v in pairs(Players:GetPlayers()) do
if string.find(string.lower(v.Name),string.lower(name)) then
target=v
end
end

if target then

local hrp=LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local thrp=target.Character:WaitForChild("HumanoidRootPart")

local bav=Instance.new("BodyAngularVelocity")
bav.AngularVelocity=Vector3.new(999999,999999,999999)
bav.MaxTorque=Vector3.new(999999,999999,999999)
bav.Parent=hrp

hrp.CFrame=thrp.CFrame

task.wait(1)

bav:Destroy()

else

Fluent:Notify({
Title="Error",
Content="Player not found",
Duration=3
})

end

end
})

------------------------------------------------
-- ANTI AFK
------------------------------------------------

Tabs.Misc:AddButton({
Title="Anti AFK",

Callback=function()

local vu=game:GetService("VirtualUser")

LocalPlayer.Idled:Connect(function()

vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
task.wait(1)
vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)

end)

Fluent:Notify({
Title="Anti AFK",
Content="Activated",
Duration=3
})

end
})

------------------------------------------------
-- REJOIN
------------------------------------------------

Tabs.Misc:AddButton({
Title="Rejoin Server",

Callback=function()

game:GetService("TeleportService"):Teleport(game.PlaceId,LocalPlayer)

end
})

------------------------------------------------
-- SAVE CONFIG
------------------------------------------------

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("DikiProject")
SaveManager:SetFolder("DikiProject/saves")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

------------------------------------------------
-- NOTIFICATION
------------------------------------------------

Fluent:Notify({
Title="DIKI PROJECT",
Content="Script Loaded Successfully",
Duration=5
})

Window:SelectTab(1)
