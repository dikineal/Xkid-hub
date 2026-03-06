local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TPService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local MarketplaceService = game:GetService("MarketplaceService")

-- Notifikasi
local function Notify(title, content, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = duration or 2
    })
end

-- Deteksi platform
local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled

-- UI Window
local Window = Rayfield:CreateWindow({
    Name = "🔥 XKID MEGA HUB 🔥",
    LoadingTitle = "XKID MEGA HUB",
    LoadingSubtitle = "All-in-One",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKidMega",
        FileName = "Config"
    },
    KeySystem = false
})

Notify("XKID MEGA HUB", "Loading...", 2)

------------------------------------------------
-- TAB MENU
------------------------------------------------
local MainTab = Window:CreateTab("🏠 Main", nil)
local PlayerTab = Window:CreateTab("👤 Player", nil)
local CameraTab = Window:CreateTab("🎥 Camera", nil)
local FlyTab = Window:CreateTab("🦅 Fly", nil)
local FarmTab = Window:CreateTab("🌾 Farming", nil)
local MountainTab = Window:CreateTab("⛰️ Mountain", nil)
local ESPTab = Window:CreateTab("👁 ESP", nil)
local TeleportTab = Window:CreateTab("🏝 Teleport", nil)
local UtilityTab = Window:CreateTab("⚙ Utility", nil)
local VisualTab = Window:CreateTab("🎨 Visual", nil)

------------------------------------------------
-- MAIN TAB (Fitur Dasar)
------------------------------------------------
_G.InfiniteJump = false
local infiniteJumpConnection

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        _G.InfiniteJump = v
        if infiniteJumpConnection then infiniteJumpConnection:Disconnect() end
        if v then
            infiniteJumpConnection = UIS.JumpRequest:Connect(function()
                if _G.InfiniteJump and LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
    end
})

_G.Noclip = false
local noclipHeartbeat

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        _G.Noclip = v
        if noclipHeartbeat then noclipHeartbeat:Disconnect() end
        if v then
            local lastUpdate = 0
            noclipHeartbeat = RunService.Heartbeat:Connect(function()
                if tick() - lastUpdate < 0.1 then return end
                lastUpdate = tick()
                pcall(function()
                    if LocalPlayer.Character then
                        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            end)
        end
    end
})

MainTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
            Notify("Reset", "Character reset", 1)
        end
    end
})

------------------------------------------------
-- PLAYER TAB
------------------------------------------------
_G.WalkSpeed = 16
local walkspeedConnection

local function updateWalkSpeed(speed)
    _G.WalkSpeed = speed
    pcall(function()
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = speed end
        end
    end)
end

walkspeedConnection = LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    updateWalkSpeed(_G.WalkSpeed)
end)

PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Callback = updateWalkSpeed
})

_G.JumpPower = 50
local jumppowerConnection

local function updateJumpPower(power)
    _G.JumpPower = power
    pcall(function()
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid:FindFirstChild("JumpPower") then
                    humanoid.JumpPower = power
                elseif humanoid:FindFirstChild("JumpHeight") then
                    humanoid.JumpHeight = power / 2
                end
            end
        end
    end)
end

jumppowerConnection = LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    updateJumpPower(_G.JumpPower)
end)

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Callback = updateJumpPower
})

_G.Gravity = 196.2
PlayerTab:CreateSlider({
    Name = "Gravity",
    Range = {0, 500},
    Increment = 5,
    CurrentValue = 196.2,
    Callback = function(v)
        _G.Gravity = v
        Workspace.Gravity = v
    end
})

PlayerTab:CreateSlider({
    Name = "Hip Height",
    Range = {0, 10},
    Increment = 0.1,
    CurrentValue = 0,
    Callback = function(v)
        pcall(function()
            if LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.HipHeight = v end
            end
        end)
    end
})

------------------------------------------------
-- CAMERA TAB (Freecam, Cinematic, Zoom)
------------------------------------------------
_G.FreeCam = false
_G.CinematicMode = false
_G.ZoomLevel = 70
_G.FreeCamSpeed = 0.5
_G.FreeCamRotateSpeed = 0.3

local freeCamMouseConnection = nil
local freeCamMoveConnection = nil
local freeCamRotation = Vector2.new(0, 0)
local freeCamPosition = Vector3.new(0, 10, 0)
local originalCameraSubject = nil
local originalCameraCFrame = nil
local cameraLocked = false
local cinematicShake = 0
local touchStartPos = nil

-- Virtual joystick untuk mobile
local joystickFrame = nil
local joystickKnob = nil
local joystickActive = false
local joystickDirection = Vector2.new(0, 0)

local function createVirtualJoystick()
    if joystickFrame then return end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlyJoystick"
    screenGui.Parent = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer.WaitForChild(LocalPlayer, "PlayerGui")
    screenGui.ResetOnSpawn = false
    
    joystickFrame = Instance.new("Frame")
    joystickFrame.Size = UDim2.new(0, 120, 0, 120)
    joystickFrame.Position = UDim2.new(0.15, 0, 0.7, 0)
    joystickFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    joystickFrame.BackgroundTransparency = 0.5
    joystickFrame.Active = true
    joystickFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 60)
    corner.Parent = joystickFrame
    
    joystickKnob = Instance.new("Frame")
    joystickKnob.Size = UDim2.new(0, 50, 0, 50)
    joystickKnob.Position = UDim2.new(0.5, -25, 0.5, -25)
    joystickKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    joystickKnob.BackgroundTransparency = 0.3
    joystickKnob.Parent = joystickFrame
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 25)
    knobCorner.Parent = joystickKnob
    
    local moveTouchStart = nil
    joystickFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joystickActive = true
            moveTouchStart = input.Position
        end
    end)
    
    joystickFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and joystickActive and moveTouchStart then
            local delta = input.Position - moveTouchStart
            local dist = math.min(delta.Magnitude, 40)
            if dist > 5 then
                local dir = delta.Unit * dist
                joystickKnob.Position = UDim2.new(0.5, dir.X - 25, 0.5, dir.Y - 25)
                joystickDirection = Vector2.new(dir.X/40, dir.Y/40)
            else
                joystickKnob.Position = UDim2.new(0.5, -25, 0.5, -25)
                joystickDirection = Vector2.new(0, 0)
            end
        end
    end)
    
    joystickFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joystickActive = false
            joystickKnob.Position = UDim2.new(0.5, -25, 0.5, -25)
            joystickDirection = Vector2.new(0, 0)
        end
    end)
end

local function destroyJoystick()
    if joystickFrame and joystickFrame.Parent then
        joystickFrame.Parent:Destroy()
        joystickFrame = nil
        joystickKnob = nil
    end
end

local function toggleFreeCam(state)
    if state == _G.FreeCam then return end
    _G.FreeCam = state
    local camera = Workspace.CurrentCamera
    if not camera then return end

    if state then
        originalCameraSubject = camera.CameraSubject
        originalCameraCFrame = camera.CFrame
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CameraSubject = nil

        local rx, ry = camera.CFrame:ToEulerAnglesYXZ()
        freeCamRotation = Vector2.new(math.deg(rx), math.deg(ry))
        freeCamPosition = camera.CFrame.Position

        if isMobile then
            createVirtualJoystick()
            freeCamMouseConnection = UIS.InputChanged:Connect(function(input)
                if not _G.FreeCam or cameraLocked then return end
                if input.UserInputType == Enum.UserInputType.Touch then
                    if touchStartPos then
                        local delta = input.Position - touchStartPos
                        freeCamRotation = freeCamRotation + Vector2.new(-delta.Y * 0.2, -delta.X * 0.2)
                        freeCamRotation = Vector2.new(math.clamp(freeCamRotation.X, -80, 80), freeCamRotation.Y)
                        touchStartPos = input.Position
                    else
                        touchStartPos = input.Position
                    end
                end
            end)
            UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    touchStartPos = nil
                end
            end)
        else
            freeCamMouseConnection = UIS.InputChanged:Connect(function(input)
                if not _G.FreeCam or cameraLocked then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = input.Delta
                    freeCamRotation = freeCamRotation + Vector2.new(-delta.Y * _G.FreeCamRotateSpeed, -delta.X * _G.FreeCamRotateSpeed)
                    freeCamRotation = Vector2.new(math.clamp(freeCamRotation.X, -80, 80), freeCamRotation.Y)
                end
            end)
        end

        freeCamMoveConnection = RunService.RenderStepped:Connect(function()
            if not _G.FreeCam then return end
            
            local moveDir = Vector3.new()
            
            if isMobile and _G.UseJoystick then
                moveDir = camera.CFrame.LookVector * joystickDirection.Y + camera.CFrame.RightVector * joystickDirection.X
            else
                if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir - Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + Vector3.new(0,1,0) end
            end

            if moveDir.Magnitude > 0 then
                freeCamPosition = freeCamPosition + moveDir.Unit * _G.FreeCamSpeed
            end

            camera.CFrame = CFrame.Angles(math.rad(freeCamRotation.X), math.rad(freeCamRotation.Y), 0) + freeCamPosition
        end)

        Notify("FreeCam", isMobile and "Touch to look, joystick to move" or "WASD+QE to move", 2)
    else
        if freeCamMouseConnection then freeCamMouseConnection:Disconnect() end
        if freeCamMoveConnection then freeCamMoveConnection:Disconnect() end
        destroyJoystick()
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = originalCameraSubject
        camera.CFrame = originalCameraCFrame
        Notify("FreeCam", "Deactivated", 1)
    end
end

CameraTab:CreateToggle({
    Name = "Freecam Mode",
    CurrentValue = false,
    Callback = toggleFreeCam
})

_G.UseJoystick = true
if isMobile then
    CameraTab:CreateToggle({
        Name = "Virtual Joystick",
        CurrentValue = true,
        Callback = function(v)
            _G.UseJoystick = v
            if not v then destroyJoystick() end
        end
    })
end

CameraTab:CreateSlider({
    Name = "Camera Speed",
    Range = {0.1, 3},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(v) _G.FreeCamSpeed = v end
})

CameraTab:CreateSlider({
    Name = "Rotation Speed",
    Range = {0.1, 1},
    Increment = 0.05,
    CurrentValue = 0.3,
    Callback = function(v) _G.FreeCamRotateSpeed = v end
})

CameraTab:CreateToggle({
    Name = "Lock Camera",
    CurrentValue = false,
    Callback = function(v) cameraLocked = v end
})

CameraTab:CreateToggle({
    Name = "Cinematic Mode",
    CurrentValue = false,
    Callback = function(v)
        _G.CinematicMode = v
        if v then
            spawn(function()
                while _G.CinematicMode do
                    cinematicShake = (math.sin(tick()*10) * 0.02)
                    wait(0.05)
                end
            end)
        end
    end
})

CameraTab:CreateSlider({
    Name = "Zoom Control",
    Range = {10, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(v)
        _G.ZoomLevel = v
        if not _G.FreeCam then
            Workspace.CurrentCamera.FieldOfView = v
        end
    end
})

CameraTab:CreateButton({
    Name = "Reset Camera",
    Callback = function()
        if _G.FreeCam and originalCameraCFrame then
            freeCamPosition = originalCameraCFrame.Position
            freeCamRotation = Vector2.new(0,0)
        end
    end
})

------------------------------------------------
-- FLY TAB (Auto Fly Universal)
------------------------------------------------
_G.Fly = false
_G.FlySpeed = 25
_G.FlyMode = "Normal" -- Normal, Freecam

local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil

local function toggleFly(state)
    _G.Fly = state
    if not LocalPlayer.Character then return end
    
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    if state then
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Physics) end)
        
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0,0,0)
        flyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        flyBodyVelocity.Parent = rootPart
        
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
        flyBodyGyro.P = 1000
        flyBodyGyro.D = 50
        flyBodyGyro.CFrame = rootPart.CFrame
        flyBodyGyro.Parent = rootPart
        
        flyConnection = RunService.Heartbeat:Connect(function()
            if not _G.Fly or not LocalPlayer.Character then return end
            
            local moveDir = Vector3.new()
            local camera = Workspace.CurrentCamera
            
            if UIS:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + (_G.FlyMode == "Freecam" and camera.CFrame.LookVector or camera.CFrame.LookVector * Vector3.new(1,0,1))
            end
            if UIS:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - (_G.FlyMode == "Freecam" and camera.CFrame.LookVector or camera.CFrame.LookVector * Vector3.new(1,0,1))
            end
            if UIS:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - camera.CFrame.RightVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + camera.CFrame.RightVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.Q) then
                moveDir = moveDir - Vector3.new(0,1,0)
            end
            if UIS:IsKeyDown(Enum.KeyCode.E) then
                moveDir = moveDir + Vector3.new(0,1,0)
            end
            
            if moveDir.Magnitude > 0 then
                flyBodyVelocity.Velocity = moveDir.Unit * _G.FlySpeed
                flyBodyGyro.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + moveDir.Unit)
            else
                flyBodyVelocity.Velocity = Vector3.new(0,0,0)
            end
        end)
        
        Notify("Fly", "Activated - Speed: " .. _G.FlySpeed, 2)
    else
        if flyConnection then flyConnection:Disconnect() end
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        if flyBodyGyro then flyBodyGyro:Destroy() end
        Notify("Fly", "Deactivated", 1)
    end
end

FlyTab:CreateToggle({
    Name = "Auto Fly",
    CurrentValue = false,
    Callback = toggleFly
})

FlyTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = 25,
    Callback = function(v) _G.FlySpeed = v end
})

FlyTab:CreateDropdown({
    Name = "Fly Mode",
    Options = {"Normal", "Freecam"},
    CurrentOption = {"Normal"},
    Callback = function(selected)
        _G.FlyMode = selected[1]
    end
})

FlyTab:CreateButton({
    Name = "Stop Flying",
    Callback = function()
        if _G.Fly then toggleFly(false) end
    end
})

------------------------------------------------
-- FARMING TAB (Auto Plant, Water, Harvest, Sell)
------------------------------------------------
_G.AutoPlant = false
_G.AutoWater = false
_G.AutoHarvest = false
_G.AutoSell = false
_G.GrowthBoost = false
_G.ItemCollector = false

-- Simulasi farming (perlu disesuaikan dengan game tertentu)
-- Ini adalah template universal, user harus menyesuaikan dengan nama object di game masing-masing

local farmConnections = {}

local function scanForPlants()
    local plants = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():match("plant") or obj.Name:lower():match("crop") or obj:IsA("Tool") then
            table.insert(plants, obj)
        end
    end
    return plants
end

local function scanForWater()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():match("water") or obj.Name:lower():match("irrigation") then
            return obj
        end
    end
    return nil
end

local function scanForSellZone()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():match("sell") or obj.Name:lower():match("market") or obj.Name:lower():match("shop") then
            return obj
 
