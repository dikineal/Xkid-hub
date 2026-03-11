repeat task.wait() until game:IsLoaded()

--====================================================
-- SETTINGS
--====================================================

getgenv().ToggleUI = Enum.KeyCode.LeftControl
getgenv().Image = "rbxassetid://95816097006870"

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

--====================================================
-- MOBILE FLOAT BUTTON
--====================================================

if UIS.TouchEnabled then

    if not getgenv().MobileButtonLoaded then
        getgenv().MobileButtonLoaded = true

        local gui = Instance.new("ScreenGui",game.CoreGui)
        gui.Name = "XKID_Toggle"

        local button = Instance.new("ImageButton",gui)
        button.Size = UDim2.new(0,55,0,55)
        button.Position = UDim2.new(0.88,0,0.15,0)
        button.Image = getgenv().Image
        button.BackgroundTransparency = 0.2
        button.Draggable = true

        local corner = Instance.new("UICorner",button)
        corner.CornerRadius = UDim.new(0,100)

        button.MouseButton1Click:Connect(function()

            game:GetService("VirtualInputManager"):SendKeyEvent(
                true,
                getgenv().ToggleUI,
                false,
                game
            )

        end)

    end

end

--====================================================
-- LOAD FLUENT
--====================================================

local Fluent = loadstring(game:HttpGet(
"https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

local Window = Fluent:CreateWindow({
    Title = "XKID_HUB",
    SubTitle = "Full Version",
    Size = UDim2.fromOffset(600,450),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

--====================================================
-- TABS
--====================================================

local Tabs = {
Main = Window:AddTab({Title="Main"}),
Player = Window:AddTab({Title="Player"}),
Visual = Window:AddTab({Title="Visual"}),
Utility = Window:AddTab({Title="Utility"}),
Settings = Window:AddTab({Title="Settings"})
}

--====================================================
-- ANTI AFK
--====================================================

local AntiAFK = true

Tabs.Main:AddToggle("AFK",{Title="Anti AFK",Default=true})

Tabs.Main.AFK:OnChanged(function(v)
AntiAFK = v
end)

task.spawn(function()

while task.wait(60) do

if AntiAFK then
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end

end

end)

--====================================================
-- WALK SPEED
--====================================================

Tabs.Player:AddSlider("Speed",{
Title="WalkSpeed",
Min=16,
Max=200,
Default=16
})

Tabs.Player.Speed:OnChanged(function(v)

local char = Player.Character
if char and char:FindFirstChild("Humanoid") then
char.Humanoid.WalkSpeed = v
end

end)

--====================================================
-- JUMP POWER
--====================================================

Tabs.Player:AddSlider("Jump",{
Title="JumpPower",
Min=50,
Max=200,
Default=50
})

Tabs.Player.Jump:OnChanged(function(v)

local char = Player.Character
if char and char:FindFirstChild("Humanoid") then
char.Humanoid.JumpPower = v
end

end)

--====================================================
-- INFINITE JUMP
--====================================================

local InfJump=false

Tabs.Player:AddToggle("InfJump",{Title="Infinite Jump",Default=false})

Tabs.Player.InfJump:OnChanged(function(v)
InfJump=v
end)

UIS.JumpRequest:Connect(function()

if InfJump then
local char=Player.Character
if char then
char:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
end
end

end)

--====================================================
-- FLY
--====================================================

local Flying=false
local FlySpeed=60
local BV

local function StartFly()

local char=Player.Character
if not char then return end

local root=char:FindFirstChild("HumanoidRootPart")

BV=Instance.new("BodyVelocity")
BV.MaxForce=Vector3.new(9e9,9e9,9e9)
BV.Parent=root

RunService.RenderStepped:Connect(function()

if not Flying then
if BV then BV:Destroy() end
return
end

BV.Velocity=workspace.CurrentCamera.CFrame.LookVector*FlySpeed

end)

end

Tabs.Player:AddToggle("Fly",{Title="Fly",Default=false})

Tabs.Player.Fly:OnChanged(function(v)

Flying=v

if v then
StartFly()
end

end)

Tabs.Player:AddSlider("FlySpeed",{
Title="Fly Speed",
Min=20,
Max=150,
Default=60
})

Tabs.Player.FlySpeed:OnChanged(function(v)
FlySpeed=v
end)

--====================================================
-- NOCLIP
--====================================================

local Noclip=false

Tabs.Player:AddToggle("Noclip",{Title="Noclip",Default=false})

Tabs.Player.Noclip:OnChanged(function(v)
Noclip=v
end)

RunService.Stepped:Connect(function()

if Noclip and Player.Character then

for _,v in pairs(Player.Character:GetDescendants()) do
if v:IsA("BasePart") then
v.CanCollide=false
end
end

end

end)

--====================================================
-- ESP PLAYER
--====================================================

local ESP=false

Tabs.Visual:AddToggle("ESP",{Title="Player ESP",Default=false})

Tabs.Visual.ESP:OnChanged(function(v)

ESP=v

for _,plr in pairs(Players:GetPlayers()) do

if plr~=Player and plr.Character then

if v then

local highlight=Instance.new("Highlight")
highlight.Parent=plr.Character
highlight.Name="XKID_ESP"

else

if plr.Character:FindFirstChild("XKID_ESP") then
plr.Character.XKID_ESP:Destroy()
end

end

end

end

end)

--====================================================
-- ADMIN DETECTOR
--====================================================

local AdminWords={"admin","mod","dev","owner"}

Players.PlayerAdded:Connect(function(p)

for _,word in pairs(AdminWords) do

if string.find(string.lower(p.Name),word) then

Fluent:Notify({
Title="ADMIN DETECTED",
Content=p.Name,
Duration=6
})

end

end

end)

--====================================================
-- UTILITY
--====================================================

Tabs.Utility:AddButton({
Title="Rejoin Server",
Callback=function()
game:GetService("TeleportService"):Teleport(game.PlaceId,Player)
end
})

Tabs.Utility:AddButton({
Title="Copy Position",
Callback=function()
setclipboard(tostring(Player.Character.HumanoidRootPart.Position))
end
})

--====================================================
-- THEME
--====================================================

Tabs.Settings:AddDropdown("Theme",{
Title="Theme",
Values={"Dark","Light","Aqua","Amethyst"},
Default="Dark"
})

Tabs.Settings.Theme:OnChanged(function(v)
Fluent:SetTheme(v)
end)

Fluent:Notify({
Title="XKID_HUB",
Content="Full Hub Loaded",
Duration=5
})