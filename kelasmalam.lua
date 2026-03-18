-- XKID HUB AURORA FIX (ANDROID)

local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService = game:GetService("TeleportService")

local LP = Players.LocalPlayer

local function getRoot()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end

--------------------------------------------------
-- WINDOW
--------------------------------------------------

local Win = Library:Window("🌟 XKID HUB", "star", "Fixed", false)

local Tab = Win:Tab("Main","user")
local Sec = Tab:Section("Player","Left")

--------------------------------------------------
-- SPEED
--------------------------------------------------

local speed = 16

RunService.RenderStepped:Connect(function()
    local h = getHum()
    if h then h.WalkSpeed = speed end
end)

Sec:Slider("Speed","spd",16,100,16,function(v)
    speed = v
end)

--------------------------------------------------
-- NOCLIP
--------------------------------------------------

local noclip = false

RunService.Stepped:Connect(function()
    if noclip then
        local c = LP.Character
        if c then
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end
end)

Sec:Toggle("NoClip","noclip",false,function(v)
    noclip = v
end)

--------------------------------------------------
-- INFINITE JUMP
--------------------------------------------------

local infJump = false

UIS.JumpRequest:Connect(function()
    if infJump then
        local h = getHum()
        if h then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

Sec:Toggle("Infinite Jump","jump",false,function(v)
    infJump = v
end)

--------------------------------------------------
-- FLY (ANDROID FIX)
--------------------------------------------------

local flying = false
local flySpeed = 60
local bv, bg

local function stopFly()
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
end

local function startFly()
    local root = getRoot()
    local hum = getHum()
    if not root or not hum then return end

    stopFly()

    bv = Instance.new("BodyVelocity", root)
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)

    bg = Instance.new("BodyGyro", root)
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.P = 1e4

    RunService.Heartbeat:Connect(function()
        if not flying then return end

        local cam = workspace.CurrentCamera
        local move = hum.MoveDirection

        local look = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector

        local dir = (look * move.Z) + (right * move.X)
        local y = look.Y

        bv.Velocity = Vector3.new(
            dir.X * flySpeed,
            y * flySpeed,
            dir.Z * flySpeed
        )

        bg.CFrame = cam.CFrame
    end)
end

Sec:Toggle("Fly","fly",false,function(v)
    flying = v
    if v then startFly() else stopFly() end
end)

Sec:Slider("Fly Speed","fspd",10,200,60,function(v)
    flySpeed = v
end)

--------------------------------------------------
-- ESP (TOGGLE FIX)
--------------------------------------------------

local esp = false

RunService.Heartbeat:Connect(function()
    if not esp then return end

    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then

            if not p.Character.Head:FindFirstChild("ESP") then

                local bill = Instance.new("BillboardGui")
                bill.Name = "ESP"
                bill.Size = UDim2.new(0,200,0,40)
                bill.StudsOffset = Vector3.new(0,2,0)
                bill.AlwaysOnTop = true
                bill.Parent = p.Character.Head

                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(1,0,1,0)
                txt.BackgroundTransparency = 1
                txt.TextColor3 = Color3.new(1,1,1)
                txt.TextScaled = true
                txt.Parent = bill
            end

            local txt = p.Character.Head.ESP.TextLabel
            local myRoot = getRoot()

            if myRoot then
                local dist = (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
                txt.Text = p.Name.." ["..math.floor(dist).."m]"
            end

        end
    end
end)

Sec:Toggle("ESP Player","esp",false,function(v)
    esp = v
end)

--------------------------------------------------
-- TELEPORT (FIX TANPA CLEAR)
--------------------------------------------------

local TPsec = Tab:Section("Teleport","Right")

for _,p in pairs(Players:GetPlayers()) do
    if p ~= LP then
        TPsec:Button(p.Name,"TP",function()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                getRoot().CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
            end
        end)
    end
end

--------------------------------------------------
-- PROTECT
--------------------------------------------------

local Prot = Tab:Section("Protect","Right")

Prot:Toggle("Anti AFK","afk",false,function(v)
    if v then
        LP.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

Prot:Button("Rejoin","",function()
    TpService:Teleport(game.PlaceId, LP)
end)

Library:Notification("XKID HUB","Loaded ✓",5)
Library:ConfigSystem(Win)