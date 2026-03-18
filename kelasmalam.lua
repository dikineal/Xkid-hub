-- XKID HUB STABLE

local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService = game:GetService("TeleportService")

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

local Win = Library:Window("🌟 XKID HUB", "star", "Stable", false)

Win:TabSection("🛠 HUB")

local TabTP = Win:Tab("📍 Teleport","map-pin")
local TabPl = Win:Tab("👤 Player","user")
local TabProt = Win:Tab("🛡 Protect","shield")

--------------------------------------------------
-- TELEPORT PLAYER
--------------------------------------------------

local TPage = TabTP:Page("Teleport Player","map-pin")
local TL = TPage:Section("Players","Left")

for _,p in pairs(Players:GetPlayers()) do

if p ~= LP then

TL:Button(p.Name,"Teleport",function()

if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then

getRoot().CFrame =
p.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)

end

end)

end

end

--------------------------------------------------
-- ESP
--------------------------------------------------

local espEnabled=false
local espObjects={}

local function clearESP()

for _,v in pairs(espObjects) do
if v then v:Destroy() end
end

espObjects={}

end

local function createESP(plr)

if plr==LP then return end

local function setup(char)

if not espEnabled then return end

local head = char:WaitForChild("Head",5)
local root = char:WaitForChild("HumanoidRootPart",5)

local gui = Instance.new("BillboardGui")
gui.Size = UDim2.new(0,200,0,40)
gui.StudsOffset = Vector3.new(0,2,0)
gui.AlwaysOnTop = true
gui.Adornee = head
gui.Parent = head

local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1,0,1,0)
txt.BackgroundTransparency = 1
txt.TextColor3 = Color3.new(1,1,1)
txt.TextStrokeTransparency = 0
txt.Font = Enum.Font.SourceSansBold
txt.TextScaled = true
txt.Parent = gui

table.insert(espObjects,gui)

RunService.Heartbeat:Connect(function()

if not espEnabled then return end

if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then

local dist =
(root.Position - LP.Character.HumanoidRootPart.Position).Magnitude

txt.Text =
plr.Name.." ["..math.floor(dist).."m]"

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

if hum then
hum.WalkSpeed=speed
end

end)

Left:Slider("Speed","speed",16,80,16,function(v)
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

if p:IsA("BasePart") then
p.CanCollide=false
end

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

if hum then
hum:ChangeState(Enum.HumanoidStateType.Jumping)
end

end

end)

Left:Toggle("Infinite Jump","jump",false,function(v)
infJump=v
end)

--------------------------------------------------
-- ESP TOGGLE
--------------------------------------------------

Left:Toggle("ESP Player","esp",false,function(v)

espEnabled=v

if v then
enableESP()
else
clearESP()
end

end)

--------------------------------------------------
-- PROTECTION
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

if char then
char:BreakJoints()
end

LP.CharacterAdded:Connect(function(newChar)

task.wait(1)

local hrp=newChar:WaitForChild("HumanoidRootPart",5)

if hrp and saved then
hrp.CFrame=saved
end

end)

end)

PL:Button("Rejoin","Rejoin Server",function()

TpService:Teleport(game.PlaceId,LP)

end)

Library:Notification("XKID HUB","Loaded",5)
Library:ConfigSystem(Win)