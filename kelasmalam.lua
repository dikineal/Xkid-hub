-- XKID HUB UPGRADE - FIXED FOR ANDROID 2026

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualVovabro/Aurora/main/Aurora.lua"))() 
-- Alternatif lain kalau masih error:
-- local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/roblox-aurora/zenui-core/main/init.lua"))()

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
local Win = Library:Window("🌟 XKID HUB", "star", "ANDROID FIX 2026", false)

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
	if p \~= LP then
		TL:Button(p.Name,"Teleport",function()
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local root = getRoot()
				if root then
					root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
				end
			end
		end)
	end
end

--------------------------------------------------
-- PLAYER SECTION + FITUR YANG SUDAH DIPERBAIKI
--------------------------------------------------
local Page = TabPl:Page("Player","user")
local Left = Page:Section("Movement","Left")

-- Speed
local speed = 16
RunService.RenderStepped:Connect(function()
	local hum = getHum()
	if hum then hum.WalkSpeed = speed end
end)

Left:Slider("Speed","speed",16,100,16,function(v)
	speed = v
end)

-- NoClip (Android friendly)
local noclip = false
local noclipConn

Left:Toggle("NoClip","noclip",false,function(v)
	noclip = v
	if noclipConn then noclipConn:Disconnect() end
	if v then
		noclipConn = RunService.Stepped:Connect(function()
			if not noclip then return end
			local char = LP.Character
			if char then
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	end
end)

-- Infinite Jump
local infJump = false
UIS.JumpRequest:Connect(function()
	if infJump then
		local hum = getHum()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

Left:Toggle("Infinite Jump","jump",false,function(v)
	infJump = v
end)

-- Fly (Stabil di Android)
local flying = false
local flySpeed = 60
local alignPos, alignOri, flyConn

local function stopFly()
	flying = false
	if flyConn then flyConn:Disconnect() end
	if alignPos then alignPos:Destroy() end
	if alignOri then alignOri:Destroy() end
end

local function startFly()
	local root = getRoot()
	if not root then return end
	stopFly()
	flying = true

	alignPos = Instance.new("AlignPosition")
	alignPos.MaxForce = 999999999
	alignPos.Responsiveness = 150
	alignPos.Parent = root
	local att = Instance.new("Attachment", root)
	alignPos.Attachment0 = att

	alignOri = Instance.new("AlignOrientation")
	alignOri.MaxTorque = 999999999
	alignOri.Responsiveness = 150
	alignOri.Parent = root
	alignOri.Attachment0 = att

	flyConn = RunService.Heartbeat:Connect(function()
		if not flying then return end
		local cam = Workspace.CurrentCamera
		local hum = getHum()
		if not hum then return end

		local move = hum.MoveDirection
		local forward = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		local dir = forward * move.Z + right * move.X
		local yDir = forward.Y

		local target = root.Position + dir * flySpeed * 0.15 + Vector3.new(0, yDir * flySpeed * 0.1, 0)
		alignPos.Position = target
		alignOri.CFrame = cam.CFrame
	end)
end

Left:Toggle("Fly","fly",false,function(v)
	if v then startFly() else stopFly() end
end)

Left:Slider("Fly Speed","flyspd",10,200,60,function(v)
	flySpeed = v
end)

-- ESP (Clean + Mobile friendly)
local esp = false
local espObjects = {}

local function removeAllESP()
	for _, bill in pairs(espObjects) do
		if bill and bill.Parent then bill:Destroy() end
	end
	espObjects = {}
end

RunService.Heartbeat:Connect(function()
	if not esp then return end
	local myRoot = getRoot()
	if not myRoot then return end

	for _, p in pairs(Players:GetPlayers()) do
		if p \~= LP and p.Character and p.Character:FindFirstChild("Head") then
			if not espObjects[p] then
				local head = p.Character.Head
				if head:FindFirstChild("ESP") then head.ESP:Destroy() end

				local bill = Instance.new("BillboardGui")
				bill.Name = "ESP"
				bill.Size = UDim2.new(0,180,0,40)
				bill.StudsOffset = Vector3.new(0,3,0)
				bill.AlwaysOnTop = true
				bill.Parent = head
				bill.Adornee = head

				local txt = Instance.new("TextLabel")
				txt.Size = UDim2.new(1,0,1,0)
				txt.BackgroundTransparency = 1
				txt.TextColor3 = Color3.new(1,1,1)
				txt.TextStrokeTransparency = 0
				txt.TextScaled = true
				txt.Font = Enum.Font.GothamBold
				txt.Parent = bill

				espObjects[p] = bill
			end

			local bill = espObjects[p]
			if bill and bill:FindFirstChild("TextLabel") then
				local dist = (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
				bill.TextLabel.Text = p.Name .. " [" .. math.floor(dist) .. "m]"
			end
		end
	end
end)

Left:Toggle("ESP Player","esp",false,function(v)
	esp = v
	if not v then removeAllESP() end
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
	local saved = lastPos
	if LP.Character then LP.Character:BreakJoints() end
	local conn
	conn = LP.CharacterAdded:Connect(function(newChar)
		conn:Disconnect()
		task.wait(1.5)
		local hrp = newChar:WaitForChild("HumanoidRootPart",5)
		if hrp and saved then hrp.CFrame = saved end
	end)
end)

PL:Button("Rejoin","Rejoin Server",function()
	TpService:Teleport(game.PlaceId, LP)
end)

Library:Notification("XKID HUB","Loaded for Android ✓ Coba sekarang",5)
Library:ConfigSystem(Win)