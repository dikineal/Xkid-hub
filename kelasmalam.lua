--[[
🌟 XKID HUB FULL
Mobile Aurora UI
]]

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

local Win = Library:Window("🌟 XKID HUB", "star", "Mobile", false)

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

local function teleportToPlayer(plr)

if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then

local root = getRoot()

if root then
root.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
end

end

end

local function buildPlayerList()

for _,p in pairs(Players:GetPlayers()) do

if p ~= LP then

TL:Button("👤 "..p.Name,"Teleport",function()
teleportToPlayer(p)
end)

end

end

end

buildPlayerList()

Players.PlayerAdded:Connect(function()
task.wait(1)
buildPlayerList()
end)

--------------------------------------------------
-- ESP NAME + DISTANCE
--------------------------------------------------

local function createESP(player)

if player == LP then return end

local function setup(character)

local head = character:WaitForChild("Head",5)
local root = character:WaitForChild("HumanoidRootPart",5)

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
txt.TextColor3 = Color3.fromRGB(255,255,255)
txt.TextStrokeTransparency = 0
txt.Font = Enum.Font.SourceSansBold
txt.TextScaled = true

RunService.Heartbeat:Connect(function()

if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then

local myRoot = LP.Character.HumanoidRootPart
local dist = (root.Position - myRoot.Position).Magnitude

txt.Text = player.Name.." ["..math.floor(dist).."m]"

end

end)

end

if player.Character then
setup(player.Character)
end

player.CharacterAdded:Connect(setup)

end

for _,p in pairs(Players:GetPlayers()) do
createESP(p)
end

Players.PlayerAdded:Connect(createESP)

--------------------------------------------------
-- FLY SYSTEM
--------------------------------------------------

local FlyPage = TabFly:Page("🚀 Fly","rocket")
local FL = FlyPage:Section("Fly","Left")
local FR = FlyPage:Section("Extras","Right")

local fly=false
local flySpeed=60
local flyBV
local flyBG
local flyConn

local function startFly()

local root=getRoot()
if not root then return end

flyBV=Instance.new("BodyVelocity")
flyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
flyBV.Parent=root

flyBG=Instance.new("BodyGyro")
flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5)
flyBG.P=1e4
flyBG.Parent=root

flyConn=RunService.Heartbeat:Connect(function()

local cam=Workspace.CurrentCamera
local dir=cam.CFrame.LookVector

flyBV.Velocity=dir*flySpeed
flyBG.CFrame=cam.CFrame

end)

end

local function stopFly()

if flyConn then
flyConn:Disconnect()
end

if flyBV then
flyBV:Destroy()
end

if flyBG then
flyBG:Destroy()
end

end

FL:Toggle("🚀 Fly","fly",false,function(v)

fly=v

if v then
startFly()
else
stopFly()
end

end)

FL:Slider("⚡ Fly Speed","flyspeed",5,200,60,function(v)
flySpeed=v
end)

--------------------------------------------------
-- NOCLIP
--------------------------------------------------

local noclip=false

RunService.Stepped:Connect(function()

if noclip then

local char=getChar()

if char then

for _,p in pairs(char:GetDescendants()) do
if p:IsA("BasePart") then
p.CanCollide=false
end
end

end

end

end)

FR:Toggle("🚶 NoClip","noclip",false,function(v)
noclip=v
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