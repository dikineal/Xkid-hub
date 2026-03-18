-- XKID HUB MOBILE + FLY GUI

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function getChar()
return LP.Character
end

local function getRoot()
local c = getChar()
return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
local c = getChar()
return c and c:FindFirstChildOfClass("Humanoid")
end

--------------------------------------------------
-- SAVE LAST POSITION
--------------------------------------------------

local lastPos

RunService.Heartbeat:Connect(function()

local root = getRoot()

if root then
lastPos = root.CFrame
end

end)

--------------------------------------------------
-- WINDOW
--------------------------------------------------

local Win = Library:Window("🌟 XKID HUB", "star", "Fly GUI", false)

Win:TabSection("🛠 HUB")

local TabTP   = Win:Tab("📍 Teleport","map-pin")
local TabFly  = Win:Tab("🚀 Fly","rocket")
local TabSpd  = Win:Tab("⚡ Speed","zap")
local TabProt = Win:Tab("🛡 Protect","shield")

--------------------------------------------------
-- TELEPORT PLAYER LIST
--------------------------------------------------

local TPage = TabTP:Page("📍 Teleport Player","map-pin")
local TL = TPage:Section("👥 Player List","Left")

for _,p in pairs(Players:GetPlayers()) do

if p ~= LP then

TL:Button("👤 "..p.Name,"Teleport",function()

if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then

getRoot().CFrame =
p.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)

end

end)

end

end

--------------------------------------------------
-- ESP SYSTEM
--------------------------------------------------

local espEnabled=false
local espList={}

local function clearESP()

for _,v in pairs(espList) do
if v then v:Destroy() end
end

espList={}

end

local function createESP(plr)

if plr == LP then return end

local function setup(char)

if not espEnabled then return end

local head = char:WaitForChild("Head",5)
local root = char:WaitForChild("HumanoidRootPart",5)

local bill = Instance.new("BillboardGui")
bill.Adornee = head
bill.Size = UDim2.new(0,200,0,40)
bill.StudsOffset = Vector3.new(0,2,0)
bill.AlwaysOnTop = true
bill.Parent = head

local txt = Instance.new("TextLabel")
txt.Parent = bill
txt.Size = UDim2.new(1,0,1,0)
txt.BackgroundTransparency = 1
txt.TextColor3 = Color3.new(1,1,1)
txt.TextStrokeTransparency = 0
txt.Font = Enum.Font.SourceSansBold
txt.TextScaled = true

table.insert(espList,bill)

RunService.Heartbeat:Connect(function()

if not espEnabled then return end

if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then

local dist = (root.Position - LP.Character.HumanoidRootPart.Position).Magnitude

txt.Text = plr.Name.." ["..math.floor(dist).."m]"

end

end)

end

if plr.Character then
setup(plr.Character)
end

plr.CharacterAdded:Connect(setup)

end

local function enableESP()

for _,p in pairs(Players:GetPlayers()) do
createESP(p)
end

end

--------------------------------------------------
-- FLY GUI
--------------------------------------------------

local function createFlyGui()

local root = getRoot()

local speed = 50
local flying = false

local bv
local bg

local gui = Instance.new("ScreenGui",game.CoreGui)

local frame = Instance.new("Frame",gui)
frame.Size = UDim2.new(0,220,0,120)
frame.Position = UDim2.new(0.4,0,0.7,0)
frame.BackgroundColor3 = Color3.fromRGB(60,60,60)

local flyBtn = Instance.new("TextButton",frame)
flyBtn.Size = UDim2.new(0.4,0,0.3,0)
flyBtn.Position = UDim2.new(0.3,0,0.1,0)
flyBtn.Text = "FLY"

flyBtn.MouseButton1Click:Connect(function()

flying = not flying

if flying then

bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(9e9,9e9,9e9)
bv.Parent = root

bg = Instance.new("BodyGyro")
bg.MaxTorque = Vector3.new(9e9,9e9,9e9)
bg.Parent = root

RunService.RenderStepped:Connect(function()

if flying then

local cam = Workspace.CurrentCamera
local dir = cam.CFrame.LookVector

bv.Velocity = dir * speed
bg.CFrame = cam.CFrame

end

end)

else

if bv then bv:Destroy() end
if bg then bg:Destroy() end

end

end)

local up = Instance.new("TextButton",frame)
up.Size = UDim2.new(0.4,0,0.2,0)
up.Position = UDim2.new(0.1,0,0.6,0)
up.Text = "UP"

up.MouseButton1Click:Connect(function()
root.Velocity = Vector3.new(0,speed,0)
end)

local down = Instance.new("TextButton",frame)
down.Size = UDim2.new(0.4,0,0.2,0)
down.Position = UDim2.new(0.5,0,0.6,0)
down.Text = "DOWN"

down.MouseButton1Click:Connect(function()
root.Velocity = Vector3.new(0,-speed,0)
end)

end

--------------------------------------------------
-- FLY TAB
--------------------------------------------------

local FlyPage = TabFly:Page("🚀 Fly","rocket")
local FL = FlyPage:Section("Fly Mode","Left")
local FR = FlyPage:Section("Extras","Right")

FL:Button("🚀 Open Fly GUI","Panel Fly seperti gambar",function()

createFlyGui()

end)

FR:Toggle("👁 ESP Player","esp",false,function(v)

espEnabled=v

if v then
enableESP()
else
clearESP()
end

end)

--------------------------------------------------
-- SPEED
--------------------------------------------------

local SPage = TabSpd:Page("⚡ Speed","zap")
local SL = SPage:Section("Speed","Left")
local SR = SPage:Section("Jump","Right")

local speed=16

RunService.RenderStepped:Connect(function()

local hum=getHum()

if hum then
hum.WalkSpeed=speed
end

end)

SL:Slider("⚡ Speed","speed",16,80,16,function(v)
speed=v
end)

--------------------------------------------------
-- INFINITE JUMP
--------------------------------------------------

local infJump=false

UIS.JumpRequest:Connect(function()

if infJump then

local hum=getHum()

if hum then
hum:ChangeState(Enum.HumanoidStateType.Jumping)
end

end

end)

SR:Toggle("♾ Infinite Jump","infjump",false,function(v)
infJump=v
end)

--------------------------------------------------
-- PROTECTION
--------------------------------------------------

local PPage = TabProt:Page("🛡 Protect","shield")
local PL = PPage:Section("Protection","Left")

PL:Toggle("⏰ Anti AFK","afk",false,function(v)

if v then

LP.Idled:Connect(function()

VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())

end)

end

end)

PL:Button("💀 Respawn","Respawn posisi terakhir",function()

local saved = lastPos

local char = LP.Character
if char then
char:BreakJoints()
end

LP.CharacterAdded:Connect(function(newChar)

task.wait(0.8)

local hrp = newChar:WaitForChild("HumanoidRootPart",5)

if hrp and saved then
hrp.CFrame = saved
end

end)

end)

PL:Button("🔄 Rejoin Server","",function()

TpService:Teleport(game.PlaceId,LP)

end)

Library:Notification("XKID HUB","Loaded",5)
Library:ConfigSystem(Win)