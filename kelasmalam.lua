--[[
🌟 XKID HUB v5 MOBILE
Aurora UI
]]

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

-- helpers
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

-- WINDOW
local Win = Library:Window("🌟 XKID HUB", "star", "v5 Mobile", false)

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
            Library:Notification("📍 Teleport","→ "..plr.Name,2)
        end

    end

end


local function buildPlayerList()

    for _,p in pairs(Players:GetPlayers()) do

        if p ~= LP then

            TL:Button("👤 "..p.Name,"Teleport ke "..p.Name,function()

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
-- PLAYER ESP
--------------------------------------------------

local espOn=false
local espObjects={}

local function clearESP()

for _,v in pairs(espObjects) do
pcall(function()
v:Destroy()
end)
end

espObjects={}

end


local function addESP(plr)

if plr==LP then return end

local function apply(char)

local head=char:FindFirstChild("Head")
if not head then return end

local bill=Instance.new("BillboardGui")
bill.Size=UDim2.new(0,150,0,40)
bill.AlwaysOnTop=true
bill.Adornee=head
bill.Parent=char

local txt=Instance.new("TextLabel",bill)
txt.Size=UDim2.new(1,0,1,0)
txt.BackgroundTransparency=1
txt.TextColor3=Color3.fromRGB(255,230,80)
txt.TextStrokeTransparency=0.3
txt.TextScaled=true
txt.Font=Enum.Font.GothamBold

RunService.Heartbeat:Connect(function()

local root=getRoot()

if root then

local dist=(head.Position-root.Position).Magnitude

txt.Text=plr.Name.." ["..math.floor(dist).."m]"

end

end)

table.insert(espObjects,bill)

end

if plr.Character then
apply(plr.Character)
end

plr.CharacterAdded:Connect(apply)

end


local function toggleESP(v)

espOn=v
clearESP()

if v then

for _,p in pairs(Players:GetPlayers()) do
addESP(p)
end

Players.PlayerAdded:Connect(addESP)

end

end

--------------------------------------------------
-- FLY
--------------------------------------------------

local FlyPage = TabFly:Page("🚀 Fly","rocket")
local FL = FlyPage:Section("Fly","Left")
local FR = FlyPage:Section("Extras","Right")

local fly=false
local flySpeed=60
local flyConn

local function startFly()

local root=getRoot()
if not root then return end

flyConn=RunService.Heartbeat:Connect(function()

if not fly then return end

local cam=Workspace.CurrentCamera
local dir=cam.CFrame.LookVector

root.Velocity=dir*flySpeed

end)

end


local function stopFly()

if flyConn then
flyConn:Disconnect()
end

local root=getRoot()

if root then
root.Velocity=Vector3.new()
end

end


FL:Toggle("🚀 Fly Smooth","fly",false,function(v)

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


FR:Toggle("👁 Player ESP","esp",false,function(v)

toggleESP(v)

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

local infjump

SR:Toggle("♾ Infinite Jump","infjump",false,function(v)

if v then

infjump=UIS.JumpRequest:Connect(function()

local hum=getHum()

if hum then
hum:ChangeState(Enum.HumanoidStateType.Jumping)
end

end)

else

if infjump then
infjump:Disconnect()
end

end

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

-- RESPAWN
PL:Button("💀 Respawn","Respawn karakter",function()

local char = LP.Character

if char then
char:BreakJoints()
end

end)

-- REJOIN
PL:Button("🔄 Rejoin Server","",function()

TpService:Teleport(game.PlaceId,LP)

end)

Library:Notification("🌟 XKID HUB","Loaded Successfully",5)
Library:ConfigSystem(Win)