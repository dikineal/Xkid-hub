local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
Name = "🔥 XKID HUB MOBILE 🔥",
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

Rayfield:Notify({
Title = "XKID HUB",
Content = "Final Version Loaded",
Duration = 5
})

------------------------------------------------
-- Anti AFK
------------------------------------------------

_G.AntiAFK = false

MainTab:CreateToggle({
Name = "Anti AFK",
CurrentValue = false,
Callback = function(v)
_G.AntiAFK = v
end
})

LocalPlayer.Idled:Connect(function()

if _G.AntiAFK then
local vu = game:GetService("VirtualUser")
vu:CaptureController()
vu:ClickButton2(Vector2.new())
end

end)

------------------------------------------------
-- Infinite Jump
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
-- Fly Speed
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
-- Fly Mobile
------------------------------------------------

_G.Flying = false

MainTab:CreateToggle({
Name = "Fly",
CurrentValue = false,
Callback = function(v)

_G.Flying = v

local char = LocalPlayer.Character
local hrp = char:WaitForChild("HumanoidRootPart")

local bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(9e9,9e9,9e9)
bv.Parent = hrp

RunService.RenderStepped:Connect(function()

if _G.Flying then

local moveDir = char.Humanoid.MoveDirection
bv.Velocity = moveDir * (40 * _G.FlySpeed)

else

bv:Destroy()

end

end)

end
})

------------------------------------------------
-- Noclip
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
-- ESP PLAYER
------------------------------------------------

_G.ESP = false

MainTab:CreateToggle({
Name = "ESP Player",
CurrentValue = false,
Callback = function(v)

_G.ESP = v

for _,player in pairs(Players:GetPlayers()) do

if player ~= LocalPlayer and player.Character then

if v then

local highlight = Instance.new("Highlight")
highlight.Name = "XKIDESP"
highlight.FillColor = Color3.fromRGB(255,0,0)
highlight.FillTransparency = 0.5
highlight.Parent = player.Character

else

if player.Character:FindFirstChild("XKIDESP") then
player.Character.XKIDESP:Destroy()
end

end

end

end

end
})

------------------------------------------------
-- WalkSpeed
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
-- JumpPower
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
-- Player List
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
-- Teleport Player
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
-- Spectate Player
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

TPTab:CreateButton({
Name = "Stop Spectate",
Callback = function()

workspace.CurrentCamera.CameraSubject =
LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

end
})

------------------------------------------------
-- Infinite Yield
------------------------------------------------

MiscTab:CreateButton({
Name = "Infinite Yield",
Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end
})

------------------------------------------------
-- Freecam Mobile
------------------------------------------------

MiscTab:CreateToggle({
Name = "Freecam Mobile",
CurrentValue = false,
Callback = function(v)

local cam = workspace.CurrentCamera

if v then

cam.CameraType = Enum.CameraType.Scriptable

RunService:BindToRenderStep("Freecam",0,function()

local move = LocalPlayer.Character.Humanoid.MoveDirection
cam.CFrame = cam.CFrame + move * 2

end)

else

RunService:UnbindFromRenderStep("Freecam")
cam.CameraType = Enum.CameraType.Custom
cam.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

end

end
})

------------------------------------------------
-- Rejoin
------------------------------------------------

MiscTab:CreateButton({
Name = "Rejoin Server",
Callback = function()
game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end
})

------------------------------------------------
-- Server Hop
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
-- Full Bright
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

print("XKID HUB FINAL LOADED")
