local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
Name = "🔥 XKIDHUB MOBILE 🔥",
LoadingTitle = "XKID HUB",
LoadingSubtitle = "Clean Final",
ConfigurationSaving = {Enabled = false},
KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

------------------------------------------------
-- TAB MENU
------------------------------------------------

local MainTab = Window:CreateTab("🏠 Main", nil)
local PlayerTab = Window:CreateTab("👤 Player", nil)
local ESPTab = Window:CreateTab("👁 ESP", nil)
local TeleportTab = Window:CreateTab("🏝 Teleport", nil)
local UtilityTab = Window:CreateTab("⚙ Utility", nil)

Rayfield:Notify({
Title = "XKID HUB",
Content = "Final Script Loaded",
Duration = 4
})

------------------------------------------------
-- MAIN
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
-- PLAYER
------------------------------------------------

PlayerTab:CreateSlider({
Name = "WalkSpeed",
Range = {16,200},
Increment = 1,
CurrentValue = 16,

Callback = function(v)

local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

if hum then
hum.WalkSpeed = v
end

end
})

PlayerTab:CreateSlider({
Name = "JumpPower",
Range = {50,200},
Increment = 1,
CurrentValue = 50,

Callback = function(v)

local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

if hum then
hum.JumpPower = v
end

end
})

------------------------------------------------
-- ESP BOX + NAME + DISTANCE
------------------------------------------------

_G.ESP = false
local ESPObjects = {}

local function createESP(player)

if player == LocalPlayer then return end

local function onChar(char)

if not _G.ESP then return end

local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255,0,0)
highlight.FillTransparency = 0.5
highlight.Parent = char

local bill = Instance.new("BillboardGui")
bill.Size = UDim2.new(0,120,0,40)
bill.AlwaysOnTop = true
bill.Adornee = char:WaitForChild("Head")
bill.Parent = char

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1,0,1,0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255,0,0)
label.TextScaled = true
label.Parent = bill

ESPObjects[player] = {highlight,label,char}

end

if player.Character then
onChar(player.Character)
end

player.CharacterAdded:Connect(onChar)

end

ESPTab:CreateToggle({
Name = "ESP Box + Name + Distance",
CurrentValue = false,

Callback = function(v)

_G.ESP = v

if v then

for _,p in pairs(Players:GetPlayers()) do
createESP(p)
end

else

for _,data in pairs(ESPObjects) do
if data[1] then data[1]:Destroy() end
end

ESPObjects = {}

end

end
})

RunService.RenderStepped:Connect(function()

if not _G.ESP then return end

for player,data in pairs(ESPObjects) do

local char = data[3]
local label = data[2]

if char and char:FindFirstChild("HumanoidRootPart") then

local dist =
(LocalPlayer.Character.HumanoidRootPart.Position -
char.HumanoidRootPart.Position).Magnitude

label.Text =
player.Name.." ["..math.floor(dist).."m]"

end

end

end)

------------------------------------------------
-- TELEPORT
------------------------------------------------

local function GetPlayers()

local list = {}

for _,p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer then
table.insert(list,p.Name)
end
end

return list

end

local SelectedPlayer = nil

TeleportTab:CreateDropdown({

Name = "Select Player",
Options = GetPlayers(),

Callback = function(opt)

SelectedPlayer = opt[1]

end

})

TeleportTab:CreateButton({

Name = "Teleport To Player",

Callback = function()

if not SelectedPlayer then return end

local target = Players:FindFirstChild(SelectedPlayer)

if target and target.Character then

LocalPlayer.Character.HumanoidRootPart.CFrame =
target.Character.HumanoidRootPart.CFrame

end

end

})

TeleportTab:CreateButton({

Name = "Spectate Player",

Callback = function()

if not SelectedPlayer then return end

local target = Players:FindFirstChild(SelectedPlayer)

if target and target.Character then

Workspace.CurrentCamera.CameraSubject =
target.Character:FindFirstChildOfClass("Humanoid")

end

end

})

TeleportTab:CreateButton({

Name = "Stop Spectate",

Callback = function()

Workspace.CurrentCamera.CameraSubject =
LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

end

})

------------------------------------------------
-- UTILITY
------------------------------------------------

_G.AntiAFK = false

UtilityTab:CreateToggle({

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

UtilityTab:CreateButton({

Name = "Rejoin Server",

Callback = function()

game:GetService("TeleportService")
:Teleport(game.PlaceId,LocalPlayer)

end

})

UtilityTab:CreateButton({

Name = "Server Hop",

Callback = function()

local Http = game:GetService("HttpService")
local TPS = game:GetService("TeleportService")

local servers = Http:JSONDecode(game:HttpGet(
"https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
))

for _,s in pairs(servers.data) do

if s.playing < s.maxPlayers then
TPS:TeleportToPlaceInstance(game.PlaceId,s.id)
break
end

end

end

})

UtilityTab:CreateButton({

Name = "Full Bright",

Callback = function()

local L = game.Lighting

L.Brightness = 2
L.ClockTime = 14
L.FogEnd = 100000
L.GlobalShadows = false

end

})

UtilityTab:CreateButton({

Name = "Reset Character",

Callback = function()

if LocalPlayer.Character then
LocalPlayer.Character:BreakJoints()
end

end

})

------------------------------------------------
-- SCRIPT LOADER
------------------------------------------------

UtilityTab:CreateInput({
Name = "Load Script URL",
PlaceholderText = "Paste raw script link...",
RemoveTextAfterFocusLost = false,

Callback = function(url)

pcall(function()

loadstring(game:HttpGet(url))()

end)

end
})

------------------------------------------------
-- FLY
------------------------------------------------

_G.Flying = false
_G.FlySpeed = 50

local FlyBV
local FlyBG

MainTab:CreateSlider({
Name = "Fly Speed",
Range = {20,200},
Increment = 5,
CurrentValue = 50,

Callback = function(v)
_G.FlySpeed = v
end
})

MainTab:CreateToggle({

Name = "Fly",

CurrentValue = false,

Callback = function(v)

_G.Flying = v

local char = LocalPlayer.Character
if not char then return end

local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return end

if v then

FlyBV = Instance.new("BodyVelocity")
FlyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
FlyBV.Parent = hrp

FlyBG = Instance.new("BodyGyro")
FlyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
FlyBG.Parent = hrp

else

if FlyBV then FlyBV:Destroy() end
if FlyBG then FlyBG:Destroy() end

end

end

})

RunService.RenderStepped:Connect(function()

if not _G.Flying then return end
if not LocalPlayer.Character then return end

local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
if not hrp then return end

local cam = Workspace.CurrentCamera
local dir = Vector3.zero

if UIS:IsKeyDown(Enum.KeyCode.W) then
dir += cam.CFrame.LookVector
end

if UIS:IsKeyDown(Enum.KeyCode.S) then
dir -= cam.CFrame.LookVector
end

if UIS:IsKeyDown(Enum.KeyCode.A) then
dir -= cam.CFrame.RightVector
end

if UIS:IsKeyDown(Enum.KeyCode.D) then
dir += cam.CFrame.RightVector
end

if UIS:IsKeyDown(Enum.KeyCode.Space) then
dir += Vector3.new(0,1,0)
end

if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
dir -= Vector3.new(0,1,0)
end

FlyBV.Velocity = dir * _G.FlySpeed
FlyBG.CFrame = cam.CFrame

end)
------------------------------------------------
-- FREECAM
------------------------------------------------

_G.Freecam = false

UtilityTab:CreateToggle({

Name = "Freecam",

CurrentValue = false,

Callback = function(v)

_G.Freecam = v

local cam = Workspace.CurrentCamera

if v then

cam.CameraType = Enum.CameraType.Scriptable

RunService:BindToRenderStep("FreecamMove",0,function()

local move = LocalPlayer.Character.Humanoid.MoveDirection

cam.CFrame = cam.CFrame + move * 2

end)

else

RunService:UnbindFromRenderStep("FreecamMove")

cam.CameraType = Enum.CameraType.Custom
cam.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

end

end
})

print("XKID HUB FINAL CLEAN LOADED")
