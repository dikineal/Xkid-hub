local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
Name = "🔥 XKID HUB MOBILE V4 🔥",
LoadingTitle = "XKID HUB",
LoadingSubtitle = "Mobile Edition",
ConfigurationSaving = {Enabled = false},
KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local MainTab = Window:CreateTab("🏠 Main", nil)
local PlayerTab = Window:CreateTab("👤 Player", nil)
local TPTab = Window:CreateTab("🏝 Teleport", nil)
local MiscTab = Window:CreateTab("🎲 Misc", nil)

------------------------------------------------
-- NOTIFY
------------------------------------------------

Rayfield:Notify({
Title = "XKID HUB",
Content = "V4 Loaded",
Duration = 5
})

------------------------------------------------
-- ANTI AFK
------------------------------------------------

local VirtualUser = game:GetService("VirtualUser")

LocalPlayer.Idled:Connect(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)

------------------------------------------------
-- INFINITE JUMP
------------------------------------------------

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

------------------------------------------------
-- FLY SPEED
------------------------------------------------

_G.FlySpeed = 3

MainTab:CreateSlider({
Name = "Fly Speed",
Range = {1,10},
Increment = 1,
CurrentValue = 3,
Callback = function(v)
_G.FlySpeed = v
end
})

------------------------------------------------
-- FLY
------------------------------------------------

local FlyConnection

MainTab:CreateToggle({
Name = "Fly",
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

bv.Velocity = dir * (30 * _G.FlySpeed)

end)

else

if FlyConnection then
FlyConnection:Disconnect()
end

end
end
})

------------------------------------------------
-- NOCLIP
------------------------------------------------

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

------------------------------------------------
-- ESP BOX + NAME + DISTANCE
------------------------------------------------

_G.ESP = false

local function CreateESP(player)

if player ~= LocalPlayer then

player.CharacterAdded:Connect(function(char)

if _G.ESP then

local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.new(1,0,0)
highlight.FillTransparency = 0.5
highlight.Parent = char

local billboard = Instance.new("BillboardGui")
billboard.Size = UDim2.new(0,100,0,40)
billboard.AlwaysOnTop = true
billboard.Adornee = char:WaitForChild("Head")
billboard.Parent = char

local text = Instance.new("TextLabel")
text.Size = UDim2.new(1,0,1,0)
text.BackgroundTransparency = 1
text.TextColor3 = Color3.new(1,0,0)
text.Text = player.Name
text.Parent = billboard

end

end)

end

end

for _,p in pairs(Players:GetPlayers()) do
CreateESP(p)
end

Players.PlayerAdded:Connect(CreateESP)

MainTab:CreateToggle({
Name = "ESP Player",
CurrentValue = false,
Callback = function(v)
_G.ESP = v
end
})

------------------------------------------------
-- WALK SPEED
------------------------------------------------

PlayerTab:CreateSlider({
Name = "WalkSpeed",
Range = {16,200},
Increment = 1,
CurrentValue = 16,
Callback = function(v)
LocalPlayer.Character.Humanoid.WalkSpeed = v
end
})

------------------------------------------------
-- JUMP POWER
------------------------------------------------

PlayerTab:CreateSlider({
Name = "JumpPower",
Range = {50,200},
Increment = 1,
CurrentValue = 50,
Callback = function(v)
LocalPlayer.Character.Humanoid.JumpPower = v
end
})

------------------------------------------------
-- PLAYER LIST
------------------------------------------------

local PlayerList = {}

for _,p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer then
table.insert(PlayerList,p.Name)
end
end

Players.PlayerAdded:Connect(function(p)
table.insert(PlayerList,p.Name)
end)

------------------------------------------------
-- TELEPORT PLAYER
------------------------------------------------

TPTab:CreateDropdown({
Name = "Teleport Player",
Options = PlayerList,
CurrentOption = {},
MultipleOptions = false,
Callback = function(selected)

local target = Players:FindFirstChild(selected[1])

if target and target.Character then

LocalPlayer.Character.HumanoidRootPart.CFrame =
target.Character.HumanoidRootPart.CFrame

end

end
})

------------------------------------------------
-- SPECTATE
------------------------------------------------

TPTab:CreateDropdown({
Name = "Spectate Player",
Options = PlayerList,
CurrentOption = {},
MultipleOptions = false,
Callback = function(selected)

local target = Players:FindFirstChild(selected[1])

if target and target.Character then

workspace.CurrentCamera.CameraSubject =
target.Character:FindFirstChildOfClass("Humanoid")

end

end
})

------------------------------------------------
-- FOLLOW PLAYER
------------------------------------------------

TPTab:CreateDropdown({
Name = "Follow Player",
Options = PlayerList,
CurrentOption = {},
MultipleOptions = false,
Callback = function(selected)

local target = Players:FindFirstChild(selected[1])

if target and target.Character then

LocalPlayer.Character.HumanoidRootPart.CFrame =
target.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)

end

end
})

------------------------------------------------
-- INFINITE YIELD
------------------------------------------------

MiscTab:CreateButton({
Name = "Infinite Yield",
Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end
})

------------------------------------------------
-- FREECAM
------------------------------------------------

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

------------------------------------------------
-- REJOIN
------------------------------------------------

MiscTab:CreateButton({
Name = "Rejoin Server",
Callback = function()
game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end
})

------------------------------------------------
-- SERVER HOP
------------------------------------------------

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

------------------------------------------------
-- FULL BRIGHT
------------------------------------------------

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

------------------------------------------------

print("XKID HUB MOBILE V4 LOADED")
