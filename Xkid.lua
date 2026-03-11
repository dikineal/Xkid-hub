--====================================================
-- XKID_HUB
-- Nexus UI Template
--====================================================

local Nexus = loadstring(game:HttpGet("https://raw.githubusercontent.com/Carterjam28YT/Nexus-Revamped/main/Nexus.lua"))()

-- Services
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--====================================================
-- WINDOW
--====================================================

local Win = Nexus:Window("XKID_HUB", "crown", "Version 1 | XKID", false)

-- Tabs
Win:TabSection("Player")

local PlayerTab = Win:Tab("Player", "user")
local UtilityTab = Win:Tab("Utility", "settings")

--====================================================
-- PLAYER PAGE
--====================================================

local MainPage = PlayerTab:Page("Main", "user")

local Movement = MainPage:Section("Movement", "Left")
local Utility = MainPage:Section("Utility", "Right")

--====================================================
-- ANTI AFK
--====================================================

local AntiAFK = false

Movement:Toggle("Anti AFK", "AntiAFK", false, "Prevent idle kick", function(state)
AntiAFK = state
end)

task.spawn(function()

while task.wait(60) do

if AntiAFK then
pcall(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)
end

end

end)

--====================================================
-- WALK SPEED
--====================================================

Movement:Slider("WalkSpeed","WalkSpeed",16,200,16,function(v)

if Player.Character and Player.Character:FindFirstChild("Humanoid") then
Player.Character.Humanoid.WalkSpeed = v
end

end,"Change player speed")

--====================================================
-- FLY SYSTEM
--====================================================

local Flying = false
local FlySpeed = 60
local BV

local function StartFly()

local char = Player.Character or Player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

BV = Instance.new("BodyVelocity")
BV.MaxForce = Vector3.new(9e9,9e9,9e9)
BV.Parent = root

RunService.RenderStepped:Connect(function()

if not Flying then
if BV then BV:Destroy() end
return
end

BV.Velocity = Camera.CFrame.LookVector * FlySpeed

end)

end

Movement:Toggle("Fly","FlyToggle",false,"Enable flying",function(state)

Flying = state

if state then
StartFly()
end

end)

Movement:Slider("Fly Speed","FlySpeed",20,150,60,function(v)

FlySpeed = v

end,"Change fly speed")

--====================================================
-- UTILITY TAB
--====================================================

local ToolPage = UtilityTab:Page("Tools","settings")

local Tools = ToolPage:Section("Tools","Left")

Tools:Button("Print Position","Shows character position",function()

print(Player.Character.HumanoidRootPart.Position)

end)

Tools:Button("Rejoin Server","Reconnect to server",function()

game:GetService("TeleportService"):Teleport(game.PlaceId,Player)

end)

--====================================================
-- LOADED
--====================================================

Nexus:Notification("XKID_HUB","Script loaded successfully!",5)

Nexus:ConfigSystem(Win)