-- XKID HUB - Single File

local XKID = {}

function XKID:CreateOrion(Name)

Name = Name or "XKID_HUB"

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XKID_HUB"
ScreenGui.Parent = game.CoreGui

local Main = Instance.new("Frame")
Main.Parent = ScreenGui
Main.Size = UDim2.new(0,520,0,320)
Main.Position = UDim2.new(.35,0,.3,0)
Main.BackgroundColor3 = Color3.fromRGB(25,25,25)

local Title = Instance.new("TextLabel")
Title.Parent = Main
Title.Size = UDim2.new(1,0,0,40)
Title.BackgroundColor3 = Color3.fromRGB(180,0,30)
Title.Text = Name
Title.TextColor3 = Color3.new(1,1,1)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold

local TabButtons = Instance.new("Frame")
TabButtons.Parent = Main
TabButtons.Size = UDim2.new(0,120,1,-40)
TabButtons.Position = UDim2.new(0,0,0,40)
TabButtons.BackgroundColor3 = Color3.fromRGB(30,30,30)

local TabList = Instance.new("UIListLayout",TabButtons)

local Pages = Instance.new("Folder",Main)

local Window = {}

function Window:CreateSection(tabName)

local Button = Instance.new("TextButton")
Button.Parent = TabButtons
Button.Size = UDim2.new(1,0,0,35)
Button.Text = tabName
Button.BackgroundColor3 = Color3.fromRGB(40,40,40)
Button.TextColor3 = Color3.new(1,1,1)

local Page = Instance.new("ScrollingFrame")
Page.Parent = Pages
Page.Size = UDim2.new(1,-120,1,-40)
Page.Position = UDim2.new(0,120,0,40)
Page.BackgroundTransparency = 1
Page.Visible = false
Page.ScrollBarThickness = 4

local Layout = Instance.new("UIListLayout",Page)
Layout.Padding = UDim.new(0,6)

Button.MouseButton1Click:Connect(function()

for _,v in pairs(Pages:GetChildren()) do
v.Visible = false
end

Page.Visible = true

end)

local Section = {}

function Section:TextLabel(text)

local Label = Instance.new("TextLabel")
Label.Parent = Page
Label.Size = UDim2.new(1,-10,0,35)
Label.BackgroundColor3 = Color3.fromRGB(35,35,35)
Label.Text = text
Label.TextColor3 = Color3.new(1,1,1)

end

function Section:TextButton(text,info,callback)

callback = callback or function() end

local Button = Instance.new("TextButton")
Button.Parent = Page
Button.Size = UDim2.new(1,-10,0,35)
Button.BackgroundColor3 = Color3.fromRGB(180,0,30)
Button.Text = text
Button.TextColor3 = Color3.new(1,1,1)

Button.MouseButton1Click:Connect(function()
callback()
end)

end

function Section:Toggle(text,callback)

callback = callback or function() end

local Toggle = Instance.new("TextButton")
Toggle.Parent = Page
Toggle.Size = UDim2.new(1,-10,0,35)
Toggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
Toggle.Text = text.." : OFF"
Toggle.TextColor3 = Color3.new(1,1,1)

local state = false

Toggle.MouseButton1Click:Connect(function()

state = not state

Toggle.Text = text.." : "..(state and "ON" or "OFF")

callback(state)

end)

end

function Section:Slider(text,min,max,callback)

callback = callback or function() end

local value = min

local Slider = Instance.new("TextButton")
Slider.Parent = Page
Slider.Size = UDim2.new(1,-10,0,35)
Slider.BackgroundColor3 = Color3.fromRGB(40,40,40)
Slider.Text = text.." : "..value
Slider.TextColor3 = Color3.new(1,1,1)

Slider.MouseButton1Click:Connect(function()

value += 1

if value > max then
value = min
end

Slider.Text = text.." : "..value

callback(value)

end)

end

return Section

end

return Window

end

------------------------------------------------
-- SCRIPT EXAMPLE (langsung jalan)
------------------------------------------------

local Window = XKID:CreateOrion("XKID HUB")

local Player = Window:CreateSection("Player")

Player:TextLabel("Welcome to XKID HUB")

Player:TextButton("Reset Character","",function()

game.Players.LocalPlayer.Character:BreakJoints()

end)

Player:Toggle("Auto Jump",function(state)

_G.AutoJump = state

while _G.AutoJump do
local char = game.Players.LocalPlayer.Character
if char then
local hum = char:FindFirstChildOfClass("Humanoid")
if hum then
hum.Jump = true
end
end
task.wait(0.1)
end

end)

Player:Slider("Speed",16,200,function(v)

local char = game.Players.LocalPlayer.Character
if char then
local hum = char:FindFirstChildOfClass("Humanoid")
if hum then
hum.WalkSpeed = v
end
end

end)
