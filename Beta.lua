local Aurora = loadstring(game:HttpGet("https://raw.githubusercontent.com/whatever/aurora-ui/main/source.lua"))()

-- WINDOW
local Window = Aurora:CreateWindow({
    Name = "XKID.HUB",
    Theme = "Dark"
})

local PlayerTab = Window:CreateTab("Player")

-- SERVICES
local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- VARIABLES
local flying = false
local speed = 60
local boost = 2

local bodyVelocity
local bodyGyro

-- START FLIGHT
local function startFlight()

	local char = player.Character
	if not char then return end

	local hrp = char:WaitForChild("HumanoidRootPart")

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(9e9,9e9,9e9)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = hrp

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
	bodyGyro.P = 10000
	bodyGyro.CFrame = hrp.CFrame
	bodyGyro.Parent = hrp

end

-- STOP FLIGHT
local function stopFlight()

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end

end

-- TOGGLE
PlayerTab:CreateToggle({
	Name = "Flight",
	CurrentValue = false,
	Callback = function(Value)

		flying = Value

		if flying then
			startFlight()
		else
			stopFlight()
		end

	end
})

-- SPEED SLIDER
PlayerTab:CreateSlider({
	Name = "Flight Speed",
	Range = {20,200},
	Increment = 5,
	CurrentValue = 60,
	Callback = function(Value)
		speed = Value
	end
})

-- MOVEMENT
RunService.RenderStepped:Connect(function()

	if not flying then return end

	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local cam = workspace.CurrentCamera
	local move = Vector3.zero

	local currentSpeed = speed

	if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
		currentSpeed *= boost
	end

	if UIS:IsKeyDown(Enum.KeyCode.W) then
		move += cam.CFrame.LookVector
	end

	if UIS:IsKeyDown(Enum.KeyCode.S) then
		move -= cam.CFrame.LookVector
	end

	if UIS:IsKeyDown(Enum.KeyCode.A) then
		move -= cam.CFrame.RightVector
	end

	if UIS:IsKeyDown(Enum.KeyCode.D) then
		move += cam.CFrame.RightVector
	end

	if UIS:IsKeyDown(Enum.KeyCode.E) then
		move += Vector3.new(0,1,0)
	end

	if UIS:IsKeyDown(Enum.KeyCode.Q) then
		move -= Vector3.new(0,1,0)
	end

	if bodyVelocity then
		bodyVelocity.Velocity = move * currentSpeed
	end

	if bodyGyro then
		bodyGyro.CFrame = cam.CFrame
	end

end)

-- RESPAWN FIX
player.CharacterAdded:Connect(function()
	flying = false
	stopFlight()
end)