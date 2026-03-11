--====================================================
-- XKIDHUB SAWAH ULTIMATE
-- AI Farm + Remote Engine
--====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "XKIDHUB SAWAH ULTIMATE",
    LoadingTitle = "XKID Development",
    LoadingSubtitle = "AI Farm Engine",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKIDHUB",
        FileName = "Ultimate"
    },
    KeySystem = false
})

-- SERVICES

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer

-- REMOTES

local Remotes = RS.Remotes.TutorialRemotes

local PlantRemote = Remotes.PlantCrop
local HarvestRemote = Remotes.HarvestCrop
local SellRemote = Remotes.SellCrop
local ShopRemote = Remotes.RequestShop

local ClientBoot = Player.PlayerScripts.ClientBoot

-- SETTINGS

local Settings = {

AutoPlant=false,
InstantPlant=false,
AutoHarvest=false,
AutoSell=false,
AutoBuy=false,
RemoteSpy=false,

Delay=0.25

}

--====================================================
-- AI PLOT SCAN
--====================================================

local PlotCache = {}

local function scanPlots()

PlotCache={}

local folder = Workspace:FindFirstChild("CoopPlots")

if not folder then return end

for _,v in pairs(folder:GetDescendants()) do

if v:IsA("BasePart") then
table.insert(PlotCache,v)
end

end

print("Plots detected:",#PlotCache)

end

--====================================================
-- INSTANT PLANT
--====================================================

local function instantPlant()

for _,plot in pairs(PlotCache) do

pcall(function()

PlantRemote:FireServer(plot.Position)

end)

end

end

--====================================================
-- AUTO PLANT LOOP
--====================================================

local function plantLoop()

while Settings.AutoPlant do

for _,plot in pairs(PlotCache) do

if not Settings.AutoPlant then break end

pcall(function()

PlantRemote:FireServer(plot.Position)

end)

task.wait(Settings.Delay)

end

task.wait(1)

end

end

--====================================================
-- HARVEST
--====================================================

local function harvestLoop()

while Settings.AutoHarvest do

pcall(function()

HarvestRemote:FireServer()

end)

task.wait(1)

end

end

--====================================================
-- AUTO SELL
--====================================================

local function sellLoop()

while Settings.AutoSell do

pcall(function()

SellRemote:FireServer()

end)

task.wait(10)

end

end

--====================================================
-- AUTO BUY
--====================================================

local function buyLoop()

while Settings.AutoBuy do

pcall(function()

ShopRemote:InvokeServer(ClientBoot)

end)

task.wait(30)

end

end

--====================================================
-- ADMIN DETECTOR
--====================================================

local function isAdmin(name)

name=name:lower()

if name:find("admin") or name:find("mod") or name:find("dev") then
return true
end

end

Players.PlayerAdded:Connect(function(p)

if isAdmin(p.Name) then

Rayfield:Notify({
Title="ADMIN DETECTED",
Content=p.Name,
Duration=10
})

end

end)

--====================================================
-- REMOTE SPY
--====================================================

local function enableSpy()

for _,remote in pairs(RS:GetDescendants()) do

if remote:IsA("RemoteEvent") then

remote.OnClientEvent:Connect(function(...)

print("[REMOTE EVENT]",remote.Name,...)

end)

end

end

end

--====================================================
-- ANTI AFK
--====================================================

task.spawn(function()

while task.wait(60) do

VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())

end

end)

--====================================================
-- UI
--====================================================

local FarmTab = Window:CreateTab("Farm")
local UtilityTab = Window:CreateTab("Utility")

FarmTab:CreateButton({
Name="Scan Plots",
Callback=scanPlots
})

FarmTab:CreateToggle({
Name="Auto Plant",
CurrentValue=false,
Callback=function(v)
Settings.AutoPlant=v
if v then task.spawn(plantLoop) end
end
})

FarmTab:CreateButton({
Name="Instant Plant",
Callback=instantPlant
})

FarmTab:CreateToggle({
Name="Auto Harvest",
CurrentValue=false,
Callback=function(v)
Settings.AutoHarvest=v
if v then task.spawn(harvestLoop) end
end
})

FarmTab:CreateToggle({
Name="Auto Sell",
CurrentValue=false,
Callback=function(v)
Settings.AutoSell=v
if v then task.spawn(sellLoop) end
end
})

FarmTab:CreateToggle({
Name="Auto Buy Seeds",
CurrentValue=false,
Callback=function(v)
Settings.AutoBuy=v
if v then task.spawn(buyLoop) end
end
})

UtilityTab:CreateToggle({
Name="Remote Spy",
CurrentValue=false,
Callback=function(v)
Settings.RemoteSpy=v
if v then enableSpy() end
end
})

UtilityTab:CreateButton({
Name="Rejoin Server",
Callback=function()
TeleportService:Teleport(game.PlaceId,Player)
end
})

Rayfield:Notify({
Title="XKIDHUB SAWAH ULTIMATE",
Content="Loaded",
Duration=5
})