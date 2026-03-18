-- XKID HUB UPGRADE (BASED ON YOUR SCRIPT)

local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

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
if root then lastPos = root.CFrame end
end)

--------------------------------------------------
-- WINDOW
--------------------------------------------------

local Win = Library:Window("🌟 XKID HUB", "star", "UPGRADE", false)

Win:TabSection("🛠 HUB")

local TabTP = Win:Tab("📍 Teleport","map-pin")
local TabPl = Win:Tab("👤 Player","user")
local TabProt = Win:Tab("🛡 Protect","shield")

--------------------------------------------------
-- TELEPORT (AUTO UPDATE TANPA CLEAR)
--------------------------------------------------

local TPage = TabTP:Page("Teleport Player","map-pin")
local TL = TPage:Section("Players","Left")

local playerButtons = {}

local function addPlayer(p)
if p == LP then return end

local btn = TL:Button(p.Name,"Teleport",function()
if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
getRoot().CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
end
end)

playerButtons[p] = btn
end

for _,p in pairs(Players:GetPlayers()) do
addPlayer(p)
end

Players.PlayerAdded:Connect(addPlayer)

--------------------------------------------------
-- PLAYER FEATURES
--------------------------------------------------

local Page = TabPl:Page("Player","user")
local Left = Page:Section("Movement","Left")

--------------------------------------------------
-- SPEED
--------------------------------------------------

local speed=16

RunService.RenderStepped:Connect(function()
local hum=getHum()
if hum then hum.WalkSpeed=speed end
end)

Left:Slider("Speed","speed",16,100,16,function(v)
speed=v
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
if p:IsA("BasePart") then p.CanCollide=false end
end
end
end
end)

Left:Toggle("NoClip","noclip",false,function(v)
noclip=v
end)

--------------------------------------------------
-- INFINITE JUMP
--------------------------------------------------

local infJump=false

UIS.JumpRequest:Connect(function()
if infJump then
local hum=getHum()
if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end
end)

Left:Toggle("Infinite Jump","jump",false,function(v)
infJump=v
end)

--------------------------------------------------
-- 🚀 FLY ANDROID FIX (NEW)
--------------------------------------------------

local flying=false
local flySpeed=60
local bv,bg,flyConn

local function stopFly()
if flyConn then flyConn:Disconnect() end
if bv then bv:Destroy() end
if bg then bg:Destroy() end
end

local function startFly()
local root=getRoot()
local hum=getHum()
if not root or not hum then return end

stopFly()

bv=Instance.new("BodyVelocity",root)
bv.MaxForce=Vector3.new(1e5,1e5,1e5)

bg=Instance.new("BodyGyro",root)
bg.MaxTorque=Vector3.new(1e5,1e5,1e5)
bg.P=1e4

flyConn=RunService.Heartbeat:Connect(function()
if not flying then return end

local cam=Workspace.CurrentCamera
local move=hum.MoveDirection

local look=cam.CFrame.LookVector
local right=cam.CFrame.RightVector

local dir=(look*move.Z)+(right*move.X)
local y=look.Y

bv.Velocity=Vector3.new(dir.X*flySpeed,y*flySpeed,dir.Z*flySpeed)
bg.CFrame=cam.CFrame

end)
end

Left:Toggle("Fly","fly",false,function(v)
flying=v
if v then startFly() else stopFly() end
end)

Left:Slider("Fly Speed","flyspd",10,200,60,function(v)
flySpeed=v
end)

--------------------------------------------------
-- 👁 ESP (OPTIMIZED - 1 LOOP)
--------------------------------------------------

local esp=false

RunService.Heartbeat:Connect(function()
if not esp then return end

for _,p in pairs(Players:GetPlayers()) do
if p~=LP and p.Character and p.Character:FindFirstChild("Head") then

if not p.Character.Head:FindFirstChild("ESP") then
local bill=Instance.new("BillboardGui")
bill.Name="ESP"
bill.Size=UDim2.new(0,200,0,40)
bill.StudsOffset=Vector3.new(0,2,0)
bill.AlwaysOnTop=true
bill.Parent=p.Character.Head

local txt=Instance.new("TextLabel")
txt.Size=UDim2.new(1,0,1,0)
txt.BackgroundTransparency=1
txt.TextColor3=Color3.new(1,1,1)
txt.TextScaled=true
txt.Parent=bill
end

local txt=p.Character.Head.ESP.TextLabel
local myRoot=getRoot()

if myRoot then
local dist=(p.Character.HumanoidRootPart.Position-myRoot.Position).Magnitude
txt.Text=p.Name.." ["..math.floor(dist).."m]"
end

end
end
end)

Left:Toggle("ESP Player","esp",false,function(v)
esp=v
end)

--------------------------------------------------
-- PROTECTION (FIXED)
--------------------------------------------------

local PPage = TabProt:Page("Protection","shield")
local PL = PPage:Section("Safety","Left")

PL:Toggle("Anti AFK","afk",false,function(v)
if v then
LP.Idled:Connect(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)
end
end)

PL:Button("Respawn","Respawn posisi terakhir",function()

local saved=lastPos
local char=LP.Character

if char then char:BreakJoints() end

local conn
conn=LP.CharacterAdded:Connect(function(newChar)
conn:Disconnect()
task.wait(1)
local hrp=newChar:WaitForChild("HumanoidRootPart",5)
if hrp and saved then hrp.CFrame=saved end
end)

end)

PL:Button("Rejoin","Rejoin Server",function()
TpService:Teleport(game.PlaceId,LP)
end)

Library:Notification("XKID HUB","UPGRADE SUCCESS ✓",5)
Library:ConfigSystem(Win)