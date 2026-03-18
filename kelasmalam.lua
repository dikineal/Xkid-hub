-- XKID HUB UPGRADE (FIXED FINAL)

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

local function getRoot()
	return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
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
-- UI
--------------------------------------------------

local Win = Library:Window("🌟 XKID HUB", "star", "UPGRADE FIX", false)

Win:TabSection("🛠 HUB")

local TabTP = Win:Tab("📍 Teleport","map-pin")
local TabPl = Win:Tab("👤 Player","user")
local TabProt = Win:Tab("🛡 Protect","shield")

--------------------------------------------------
-- TELEPORT
--------------------------------------------------

local TPage = TabTP:Page("Teleport Player","map-pin")
local TL = TPage:Section("Players","Left")

for _,p in pairs(Players:GetPlayers()) do
	if p ~= LP then
		TL:Button(p.Name,"Teleport",function()
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				getRoot().CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
			end
		end)
	end
end

--------------------------------------------------
-- PLAYER
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
-- NOCLIP (FIX HARD)
--------------------------------------------------

local noclip=false

RunService.Stepped:Connect(function()
	if noclip then
		local char = LP.Character
		if char then
			for _,v in pairs(char:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = false
					v.Velocity = Vector3.new(0,0,0)
				end
			end
		end
	end
end)

Left:Toggle("NoClip","noclip",false,function(v)
	noclip=v
end)

--------------------------------------------------
-- INFINITE JUMP (FIX)
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
-- 🚀 FLY (FIX STABIL)
--------------------------------------------------

local flying=false
local flySpeed=60
local bv,bg,conn

local function stopFly()
	flying=false
	if conn then conn:Disconnect() end
	if bv then bv:Destroy() end
	if bg then bg:Destroy() end
end

local function startFly()
	local root=getRoot()
	local hum=getHum()
	if not root or not hum then return end

	stopFly()
	flying=true

	bv=Instance.new("BodyVelocity",root)
	bv.MaxForce=Vector3.new(1e5,1e5,1e5)

	bg=Instance.new("BodyGyro",root)
	bg.MaxTorque=Vector3.new(1e5,1e5,1e5)
	bg.P=1e4

	conn=RunService.Heartbeat:Connect(function()
		if not flying then return end

		local cam=Workspace.CurrentCamera
		local move=hum.MoveDirection

		local dir = cam.LookVector*move.Z + cam.RightVector*move.X
		local y = cam.LookVector.Y

		bv.Velocity = Vector3.new(dir.X*flySpeed, y*flySpeed, dir.Z*flySpeed)
		bg.CFrame = cam.CFrame
	end)
end

Left:Toggle("Fly","fly",false,function(v)
	if v then startFly() else stopFly() end
end)

Left:Slider("Fly Speed","flyspd",10,200,60,function(v)
	flySpeed=v
end)

--------------------------------------------------
-- 👁 ESP (FIX TOTAL)
--------------------------------------------------

local esp=false

RunService.Heartbeat:Connect(function()
	if not esp then return end

	local myRoot=getRoot()
	if not myRoot then return end

	for _,p in pairs(Players:GetPlayers()) do
		if p~=LP and p.Character and p.Character:FindFirstChild("Head") then

			local head=p.Character.Head

			if not head:FindFirstChild("ESP") then
				local bill=Instance.new("BillboardGui")
				bill.Name="ESP"
				bill.Size=UDim2.new(0,200,0,40)
				bill.StudsOffset=Vector3.new(0,2,0)
				bill.AlwaysOnTop=true
				bill.Parent=head

				local txt=Instance.new("TextLabel")
				txt.Name="TXT"
				txt.Size=UDim2.new(1,0,1,0)
				txt.BackgroundTransparency=1
				txt.TextColor3=Color3.new(1,1,1)
				txt.TextScaled=true
				txt.Parent=bill
			end

			local txt=head.ESP:FindFirstChild("TXT")
			local root=p.Character:FindFirstChild("HumanoidRootPart")

			if txt and root then
				local dist=(root.Position-myRoot.Position).Magnitude
				txt.Text=p.Name.." ["..math.floor(dist).."m]"
			end
		end
	end
end)

Left:Toggle("ESP Player","esp",false,function(v)
	esp=v
end)

--------------------------------------------------
-- PROTECT
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

	local c
	c=LP.CharacterAdded:Connect(function(newChar)
		c:Disconnect()
		task.wait(1)
		local hrp=newChar:WaitForChild("HumanoidRootPart",5)
		if hrp and saved then hrp.CFrame=saved end
	end)
end)

PL:Button("Rejoin","Rejoin Server",function()
	TpService:Teleport(game.PlaceId,LP)
end)

Library:Notification("XKID HUB","FIXED ALL ✓",5)
Library:ConfigSystem(Win)