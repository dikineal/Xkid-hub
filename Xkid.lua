local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🔥 XKID HUB MOBILE v3.0 🔥",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "Ultimate Edition",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MainTab = Window:CreateTab("🏠 Main", nil)
local PlayerTab = Window:CreateTab("👤 Player", nil)
local TPTab = Window:CreateTab("🏝 Teleport", nil)
local MiscTab = Window:CreateTab("🎲 Misc", nil)

Rayfield:Notify({
    Title = "XKID HUB",
    Content = "Ultimate v3.0 Loaded",
    Duration = 5
})

------------------------------------------------
-- ✅ ANTI AFK
------------------------------------------------
_G.AntiAFK = false

MainTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Callback = function(v)
        _G.AntiAFK = v
    end
})

LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end
end)

------------------------------------------------
-- ✅ INFINITE JUMP
------------------------------------------------
_G.InfiniteJump = false

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        _G.InfiniteJump = v
    end
})

UIS.JumpRequest:Connect(function()
    if _G.InfiniteJump then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

------------------------------------------------
-- ✅ FLY 6 ARAH (NAIK TURUN KIRI KANAN DEPAN BELAKANG)
------------------------------------------------
_G.Flying = false
_G.FlySpeed = 50
local FlyBV = nil
local FlyBG = nil

MainTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(v)
        _G.FlySpeed = v
    end
})

MainTab:CreateToggle({
    Name = "Fly 6 Direction",
    CurrentValue = false,
    Callback = function(v)
        _G.Flying = v
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        if v then
            FlyBV = Instance.new("BodyVelocity")
            FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            FlyBV.Velocity = Vector3.zero
            FlyBV.Parent = hrp
            
            FlyBG = Instance.new("BodyGyro")
            FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            FlyBG.P = 9e4
            FlyBG.CFrame = hrp.CFrame
            FlyBG.Parent = hrp
        else
            if FlyBV then FlyBV:Destroy() FlyBV = nil end
            if FlyBG then FlyBG:Destroy() FlyBG = nil end
        end
    end
})

-- Fly control loop
RunService.RenderStepped:Connect(function()
    if not _G.Flying then return end
    if not FlyBV or not FlyBG then return end
    if not LocalPlayer.Character then return end
    
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local cam = Workspace.CurrentCamera
    local moveDir = Vector3.zero
    
    -- WASD / Arrow keys (depan belakang kiri kanan)
    if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up) then
        moveDir = moveDir + cam.CFrame.LookVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down) then
        moveDir = moveDir - cam.CFrame.LookVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then
        moveDir = moveDir - cam.CFrame.RightVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then
        moveDir = moveDir + cam.CFrame.RightVector
    end
    
    -- Naik turun (Space / Shift)
    if UIS:IsKeyDown(Enum.KeyCode.Space) then
        moveDir = moveDir + Vector3.new(0, 1, 0)
    end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        moveDir = moveDir - Vector3.new(0, 1, 0)
    end
    
    -- Apply velocity
    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit * _G.FlySpeed
    end
    
    FlyBV.Velocity = moveDir
    FlyBG.CFrame = cam.CFrame
end)

------------------------------------------------
-- ✅ NOCLIP
------------------------------------------------
_G.Noclip = false

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        _G.Noclip = v
    end
})

RunService.Stepped:Connect(function()
    if _G.Noclip and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

------------------------------------------------
-- ✅ ESP + LINE TRACER (WALLHACK)
------------------------------------------------
_G.ESP = false
_G.ESPLine = true
local ESPHighlights = {}
local ESPLines = {}

local function CreateLine()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(255, 0, 0)
    line.Thickness = 1
    line.Transparency = 1
    return line
end

local function AddESP(player)
    if player == LocalPlayer then return end
    
    -- Highlight box
    local highlight = Instance.new("Highlight")
    highlight.Name = "XKIDESP"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    -- Tracer line
    local line = CreateLine()
    
    ESPHighlights[player] = highlight
    ESPLines[player] = line
    
    -- Parent highlight saat character ada
    local function onCharAdded(char)
        wait(0.5)
        highlight.Parent = char
    end
    
    if player.Character then
        onCharAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(onCharAdded)
end

local function RemoveESP(player)
    if ESPHighlights[player] then
        ESPHighlights[player]:Destroy()
        ESPHighlights[player] = nil
    end
    if ESPLines[player] then
        ESPLines[player]:Remove()
        ESPLines[player] = nil
    end
end

-- ESP Toggle
MainTab:CreateToggle({
    Name = "ESP Box",
    CurrentValue = false,
    Callback = function(v)
        _G.ESP = v
        if v then
            for _, p in pairs(Players:GetPlayers()) do
                AddESP(p)
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                RemoveESP(p)
            end
        end
    end
})

MainTab:CreateToggle({
    Name = "ESP Line Tracer",
    CurrentValue = true,
    Callback = function(v)
        _G.ESPLine = v
    end
})

-- Update ESP lines
RunService.RenderStepped:Connect(function()
    if not _G.ESP or not _G.ESPLine then
        for _, line in pairs(ESPLines) do
            line.Visible = false
        end
        return
    end
    
    local cam = Workspace.CurrentCamera
    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
    
    for player, line in pairs(ESPLines) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                line.From = screenCenter
                line.To = Vector2.new(pos.X, pos.Y)
                line.Visible = true
                line.Color = ESPHighlights[player] and ESPHighlights[player].FillColor or Color3.fromRGB(255, 0, 0)
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    if _G.ESP then
        AddESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

------------------------------------------------
-- ✅ WALKSPEED & JUMPPOWER
------------------------------------------------
PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 500},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
})

PlayerTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 500},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v end
        end
    end
})

------------------------------------------------
-- ✅ TELEPORT & SPECTATE
------------------------------------------------
local SelectedPlayer = ""

TPTab:CreateInput({
    Name = "Player Name",
    PlaceholderText = "Type exact name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        SelectedPlayer = text
    end
})

TPTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if SelectedPlayer == "" then return end
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
        end
    end
})

TPTab:CreateButton({
    Name = "Spectate Player",
    Callback = function()
        if SelectedPlayer == "" then return end
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character then
            Workspace.CurrentCamera.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid")
        end
    end
})

TPTab:CreateButton({
    Name = "Stop Spectate",
    Callback = function()
        if LocalPlayer.Character then
            Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
    end
})

------------------------------------------------
-- ✅ INFINITE YIELD
------------------------------------------------
MiscTab:CreateButton({
    Name = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})

------------------------------------------------
-- ✅ FREECAM + ANALOG VIRTUAL (360° CONTROL)
------------------------------------------------
_G.Freecam = false
_G.FreecamSpeed = 50

-- GUI untuk analog virtual
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FreecamGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = false

-- Analog kiri (gerak)
local LeftFrame = Instance.new("Frame")
LeftFrame.Name = "LeftAnalog"
LeftFrame.Size = UDim2.new(0, 150, 0, 150)
LeftFrame.Position = UDim2.new(0, 50, 1, -200)
LeftFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
LeftFrame.BackgroundTransparency = 0.5
LeftFrame.BorderSizePixel = 0
LeftFrame.Visible = false
LeftFrame.Parent = ScreenGui

local LeftCorner = Instance.new("UICorner")
LeftCorner.CornerRadius = UDim.new(1, 0)
LeftCorner.Parent = LeftFrame

local LeftKnob = Instance.new("Frame")
LeftKnob.Name = "Knob"
LeftKnob.Size = UDim2.new(0, 50, 0, 50)
LeftKnob.Position = UDim2.new(0.5, -25, 0.5, -25)
LeftKnob.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
LeftKnob.BorderSizePixel = 0
LeftKnob.Parent = LeftFrame

local LeftKnobCorner = Instance.new("UICorner")
LeftKnobCorner.CornerRadius = UDim.new(1, 0)
LeftKnobCorner.Parent = LeftKnob

-- Analog kanan (kamera)
local RightFrame = Instance.new("Frame")
RightFrame.Name = "RightAnalog"
RightFrame.Size = UDim2.new(0, 150, 0, 150)
RightFrame.Position = UDim2.new(1, -200, 1, -200)
RightFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
RightFrame.BackgroundTransparency = 0.5
RightFrame.BorderSizePixel = 0
RightFrame.Visible = false
RightFrame.Parent = ScreenGui

local RightCorner = Instance.new("UICorner")
RightCorner.CornerRadius = UDim.new(1, 0)
RightCorner.Parent = RightFrame

local RightKnob = Instance.new("Frame")
RightKnob.Name = "Knob"
RightKnob.Size = UDim2.new(0, 50, 0, 50)
RightKnob.Position = UDim2.new(0.5, -25, 0.5, -25)
RightKnob.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
RightKnob.BorderSizePixel = 0
RightKnob.Parent = RightFrame

local RightKnobCorner = Instance.new("UICorner")
RightKnobCorner.CornerRadius = UDim.new(1, 0)
RightKnobCorner.Parent = RightKnob

-- Label
local LeftLabel = Instance.new("TextLabel")
LeftLabel.Text = "MOVE"
LeftLabel.Size = UDim2.new(1, 0, 0, 20)
LeftLabel.Position = UDim2.new(0, 0, 0, -25)
LeftLabel.BackgroundTransparency = 1
LeftLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
LeftLabel.TextScaled = true
LeftLabel.Parent = LeftFrame

local RightLabel = Instance.new("TextLabel")
RightLabel.Text = "CAMERA"
RightLabel.Size = UDim2.new(1, 0, 0, 20)
RightLabel.Position = UDim2.new(0, 0, 0, -25)
RightLabel.BackgroundTransparency = 1
RightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RightLabel.TextScaled = true
RightLabel.Parent = RightFrame

ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Freecam variables
local FreecamPos = Vector3.zero
local FreecamRot = Vector2.zero
local LeftInput = Vector2.zero
local RightInput = Vector2.zero

-- Input handling
local UserInputService = game:GetService("UserInputService")
local TouchingLeft = false
local TouchingRight = false

LeftFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        TouchingLeft = true
    end
end)

LeftFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        TouchingLeft = false
        LeftKnob.Position = UDim2.new(0.5, -25, 0.5, -25)
        LeftInput = Vector2.zero
    end
end)

RightFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        TouchingRight = true
    end
end)

RightFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        TouchingRight = false
        RightKnob.Position = UDim2.new(0.5, -25, 0.5, -25)
        RightInput = Vector2.zero
    end
end)

UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
    if gameProcessed then return end
    
    local pos = touch.Position
    
    -- Left analog (move)
    if TouchingLeft then
        local center = LeftFrame.AbsolutePosition + (LeftFrame.AbsoluteSize / 2)
        local delta = (pos - center)
        local maxDist = 50
        
        if delta.Magnitude > maxDist then
            delta = delta.Unit * maxDist
        end
        
        LeftKnob.Position = UDim2.new(0.5, delta.X - 25, 0.5, delta.Y - 25)
        LeftInput = Vector2.new(delta.X / maxDist, -delta.Y / maxDist)
    end
    
    -- Right analog (camera)
    if TouchingRight then
        local center = RightFrame.AbsolutePosition + (RightFrame.AbsoluteSize / 2)
        local delta = (pos - center)
        local maxDist = 50
        
        if delta.Magnitude > maxDist then
            delta = delta.Unit * maxDist
        end
        
        RightKnob.Position = UDim2.new(0.5, delta.X - 25, 0.5, delta.Y - 25)
        RightInput = Vector2.new(delta.X / maxDist, delta.Y / maxDist)
    end
end)

-- Freecam toggle
MiscTab:CreateToggle({
    Name = "Freecam + Analog",
    CurrentValue = false,
    Callback = function(v)
        _G.Freecam = v
        ScreenGui.Enabled = v
        LeftFrame.Visible = v
        RightFrame.Visible = v
        
        local cam = Workspace.CurrentCamera
        
        if v then
            -- Save original
            _G.OriginalCameraType = cam.CameraType
            _G.OriginalSubject = cam.CameraSubject
            
            -- Set freecam
            cam.CameraType = Enum.CameraType.Scriptable
            FreecamPos = cam.CFrame.Position
            FreecamRot = Vector2.new(cam.CFrame.Rotation.Y, cam.CFrame.Rotation.X)
            
        else
            -- Restore
            cam.CameraType = _G.OriginalCameraType or Enum.CameraType.Custom
            cam.CameraSubject = _G.OriginalSubject or LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
    end
})

MiscTab:CreateSlider({
    Name = "Freecam Speed",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(v)
        _G.FreecamSpeed = v
    end
})

-- Freecam update loop
RunService.RenderStepped:Connect(function(dt)
    if not _G.Freecam then return end
    
    local cam = Workspace.CurrentCamera
    local speed = _G.FreecamSpeed or 50
    
    -- Rotate camera (right analog)
    FreecamRot = FreecamRot + (RightInput * 2 * dt * 60)
    FreecamRot = Vector2.new(
        math.clamp(FreecamRot.Y, -80, 80),
        FreecamRot.X % 360
    )
    
    -- Calculate rotation
    local rotCFrame = CFrame.Angles(0, math.rad(FreecamRot.X), 0) 
        * CFrame.Angles(math.rad(FreecamRot.Y), 0, 0)
    
    -- Move position (left analog + up/down)
    local moveInput = Vector3.new(LeftInput.X, 0, -LeftInput.Y)
    local moveDir = rotCFrame * moveInput
    
    -- Apply movement
    FreecamPos = FreecamPos + (moveDir * speed * dt)
    
    -- Update camera
    cam.CFrame = CFrame.new(FreecamPos) * rotCFrame
end)

------------------------------------------------
-- ✅ REJOIN & SERVER HOP
------------------------------------------------
MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end
})

MiscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local Http = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local servers = Http:JSONDecode(game:HttpGet(url))
        
        for _, s in pairs(servers.data) do
            if s.playing < s.maxPlayers then
                TPS:TeleportToPlaceInstance(game.PlaceId, s.id)
                break
            end
        end
    end
})

------------------------------------------------
-- ✅ FULL BRIGHT
------------------------------------------------
MiscTab:CreateButton({
    Name = "Full Bright",
    Callback = function()
        local L = game.Lighting
        L.Brightness = 2
        L.ClockTime = 14
        L.FogEnd = 100000
        L.GlobalShadows = false
    end
})

------------------------------------------------
-- ✅ RESET CHARACTER
------------------------------------------------
MiscTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end
})

print("XKID HUB MOBILE v3.0 ULTIMATE LOADED")
