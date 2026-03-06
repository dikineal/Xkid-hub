local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
Name = "🔥 XKID HUB MOBILE 🔥",
LoadingTitle = "XKID HUB",
LoadingSubtitle = "Mobile Edition",
ConfigurationSaving = {Enabled = false},
Discord = {Enabled = false},
KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local MainTab = Window:CreateTab("🏠 Main", nil)
local TPTab = Window:CreateTab("🏝 Teleport", nil)
local MiscTab = Window:CreateTab("🎲 Misc", nil)

Rayfield:Notify({
Title = "XKID HUB",
Content = "Mobile Hub Loaded",
Duration = 5
})

-- Anti AFK
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
task.wait(1)
vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

-- Infinite Jump
_G.InfiniteJump = false

MainTab:CreateToggle({
Name = "Infinite Jump",
CurrentValue = false,
Callback = function(v)
_G.InfiniteJump = v
end
})

UIS.JumpRequest:Connect(function()
if _G.InfiniteJump then
LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
end
end)

-- Fly Mobile
local FlyConnection

MainTab:CreateToggle({
Name = "Fly (Mobile)",
CurrentValue = false,
Callback = function(v)

local char = LocalPlayer.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")

if v and hrp then

local bv = Instance.new("BodyVelocity")
local bg = Instance.new("BodyGyro")

bv.MaxForce = Vector3.new(9e9,9e9,9e9)
bv.Parent = hrp

bg.MaxTorque = Vector3.new(9e9,9e9,9e9)
bg.Parent = hrp

FlyConnection = RunService.RenderStepped:Connect(function()

local cam = workspace.CurrentCamera
bg.CFrame = cam.CFrame

local dir = Vector3.zero

if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end

bv.Velocity = dir * 60

end)

else

if FlyConnection then
FlyConnection:Disconnect()
end

if hrp then
for _,v in pairs(hrp:GetChildren()) do
if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
v:Destroy()
end
end
end

end
end
})

-- Noclip
_G.Noclip = false

MainTab:CreateToggle({
Name = "Noclip",
CurrentValue = false,
Callback = function(v)
_G.Noclip = v
end
})

RunService.Stepped:Connect(function()
if _G.Noclip and LocalPlayer.Character then
for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
if v:IsA("BasePart") then
v.CanCollide = false
end
end
end
end)

-- ESP
_G.ESP = false

local function createESP(player)
if player ~= LocalPlayer and player.Character then

local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.new(1,0,0)
highlight.FillTransparency = 0.5
highlight.Parent = player.Character

end
end

MainTab:CreateToggle({
Name = "Player ESP",
CurrentValue = false,
Callback = function(v)

_G.ESP = v

if v then
for _,p in pairs(Players:GetPlayers()) do
createESP(p)
end
else
for _,p in pairs(Players:GetPlayers()) do
if p.Character then
for _,h in pairs(p.Character:GetChildren()) do
if h:IsA("Highlight") then
h:Destroy()
end
end
end
end
end

end
})

-- WalkSpeed
MainTab:CreateSlider({
Name = "WalkSpeed",
Range = {16,200},
Increment = 1,
CurrentValue = 16,
Callback = function(v)
LocalPlayer.Character.Humanoid.WalkSpeed = v
end
})

-- JumpPower
MainTab:CreateSlider({
Name = "JumpPower",
Range = {50,200},
Increment = 1,
CurrentValue = 50,
Callback = function(v)
LocalPlayer.Character.Humanoid.JumpPower = v
end
})

-- Teleport to Player
TPTab:CreateInput({
Name = "Teleport To Player",
PlaceholderText = "Player Name",
Callback = function(name)

local target = Players:FindFirstChild(name)

if target and target.Character then
LocalPlayer.Character.HumanoidRootPart.CFrame =
target.Character.HumanoidRootPart.CFrame
end

end
})

-- Infinite Yield
MiscTab:CreateButton({
Name = "Infinite Yield",
Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end
})

-- Freecam Mobile
MiscTab:CreateToggle({
Name = "Freecam",
CurrentValue = false,
Callback = function(v)

local cam = workspace.CurrentCamera

if v then
cam.CameraType = Enum.CameraType.Scriptable
else
cam.CameraType = Enum.CameraType.Custom
cam.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

end
})

-- Rejoin
MiscTab:CreateButton({
Name = "Rejoin Server",
Callback = function()
game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end
})

-- Server Hop
MiscTab:CreateButton({
Name = "Server Hop",
Callback = function()

local Http = game:GetService("HttpService")
local TPS = game:GetService("TeleportService")

local servers = Http:JSONDecode(game:HttpGet(
"https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
))

for _,s in pairs(servers.data) do
if s.playing < s.maxPlayers then
TPS:TeleportToPlaceInstance(game.PlaceId, s.id)
break
end
end

end
})

-- Full Bright
MiscTab:CreateButton({
Name = "Full Bright",
Callback = function()

local L = game.Lighting
L.Brightness = 2
L.ClockTime = 14
L.FogEnd = 100000
L.GlobalShadows = false

end
})

print("XKID HUB MOBILE LOADED")
