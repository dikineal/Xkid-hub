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
        end
    end
    return nil
end

local function startFarming()
    if farmConnections.plant then farmConnections.plant:Disconnect() end
    if farmConnections.water then farmConnections.water:Disconnect() end
    if farmConnections.harvest then farmConnections.harvest:Disconnect() end
    if farmConnections.sell then farmConnections.sell:Disconnect() end
    if farmConnections.collect then farmConnections.collect:Disconnect() end
    
    farmConnections.plant = RunService.Heartbeat:Connect(function()
        if _G.AutoPlant and LocalPlayer.Character then
            -- Cari tanah kosong atau seed
            -- Implementasi spesifik tergantung game
        end
    end)
    
    farmConnections.water = RunService.Heartbeat:Connect(function()
        if _G.AutoWater and LocalPlayer.Character then
            local waterSource = scanForWater()
            if waterSource then
                -- Arahkan ke water source
            end
        end
    end)
    
    farmConnections.harvest = RunService.Heartbeat:Connect(function()
        if _G.AutoHarvest and LocalPlayer.Character then
            local plants = scanForPlants()
            for _, plant in pairs(plants) do
                -- Cek jika siap panen
            end
        end
    end)
    
    farmConnections.sell = RunService.Heartbeat:Connect(function()
        if _G.AutoSell and LocalPlayer.Character then
            local sellZone = scanForSellZone()
            if sellZone then
                LocalPlayer.Character:SetPrimaryPartCFrame(sellZone.CFrame)
                -- Trigger jual
            end
        end
    end)
    
    farmConnections.collect = RunService.Heartbeat:Connect(function()
        if _G.ItemCollector and LocalPlayer.Character then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Part") and obj.Name:lower():match("item") or obj.Name:lower():match("drop") then
                    if (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 20 then
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
                        wait(0.1)
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
                    end
                end
            end
        end
    end)
end

FarmTab:CreateToggle({
    Name = "Auto Plant",
    CurrentValue = false,
    Callback = function(v) _G.AutoPlant = v startFarming() end
})

FarmTab:CreateToggle({
    Name = "Auto Water",
    CurrentValue = false,
    Callback = function(v) _G.AutoWater = v startFarming() end
})

FarmTab:CreateToggle({
    Name = "Auto Harvest",
    CurrentValue = false,
    Callback = function(v) _G.AutoHarvest = v startFarming() end
})

FarmTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Callback = function(v) _G.AutoSell = v startFarming() end
})

FarmTab:CreateToggle({
    Name = "Item Collector",
    CurrentValue = false,
    Callback = function(v) _G.ItemCollector = v startFarming() end
})

FarmTab:CreateToggle({
    Name = "Growth Boost (Simulated)",
    CurrentValue = false,
    Callback = function(v)
        _G.GrowthBoost = v
        Notify("Growth Boost", v and "Activated (visual only)" or "Deactivated", 2)
    end
})

FarmTab:CreateButton({
    Name = "Teleport to Farm",
    Callback = function()
        local farm = scanForPlants()
        if #farm > 0 then
            LocalPlayer.Character:SetPrimaryPartCFrame(farm[1].CFrame + Vector3.new(0,5,0))
        end
    end
})

FarmTab:CreateButton({
    Name = "Teleport to Shop",
    Callback = function()
        local shop = scanForSellZone()
        if shop then
            LocalPlayer.Character:SetPrimaryPartCFrame(shop.CFrame + Vector3.new(0,5,0))
        end
    end
})

FarmTab:CreateToggle({
    Name = "ESP Plants",
    CurrentValue = false,
    Callback = function(v)
        _G.ESPPlants = v
        if v then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name:lower():match("plant") then
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                    highlight.Parent = obj
                end
            end
        end
    end
})

------------------------------------------------
-- MOUNTAIN TAB (Climb Assist, Anti Fall, Pathfinder)
------------------------------------------------
_G.ClimbAssist = false
_G.AntiFall = false
local climbConnection = nil
local pathfinderWaypoints = {}
local pathfinderActive = false

local function toggleClimbAssist(state)
    _G.ClimbAssist = state
    if climbConnection then climbConnection:Disconnect() end
    if state then
        climbConnection = RunService.Heartbeat:Connect(function()
            if not LocalPlayer.Character then return end
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not humanoid or not rootPart then return end
            
            -- Raycast ke depan
            local ray = Ray.new(rootPart.Position, rootPart.CFrame.LookVector * 5)
            local part, pos = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
            
            if part and not part:IsDescendantOf(LocalPlayer.Character) then
                -- Jika ada dinding, bantu lompat
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

local function toggleAntiFall(state)
    _G.AntiFall = state
end

-- Simple anti-fall
RunService.Heartbeat:Connect(function()
    if _G.AntiFall and LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart and rootPart.Position.Y < -50 then
            rootPart.CFrame = CFrame.new(0, 50, 0)
        end
    end
end)

local function findPeak()
    local highest = 0
    local peakPos = nil
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Position.Y > highest then
            highest = part.Position.Y
            peakPos = part.Position
        end
    end
    return peakPos
end

local function findPathToPeak()
    local peak = findPeak()
    if not peak or not LocalPlayer.Character then return end
    
    pathfinderWaypoints = {}
    local currentPos = LocalPlayer.Character.HumanoidRootPart.Position
    local step = (peak - currentPos).Unit * 10
    
    for i = 1, 20 do
        table.insert(pathfinderWaypoints, currentPos + step * i)
    end
    pathfinderActive = true
end

MountainTab:CreateToggle({
    Name = "Climb Assist",
    CurrentValue = false,
    Callback = toggleClimbAssist
})

MountainTab:CreateToggle({
    Name = "Anti Fall Damage",
    CurrentValue = false,
    Callback = function(v)
        _G.AntiFallDamage = v
        if v then
            -- Bisa dengan mengubah property humanoid
            pcall(function()
                if LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.MaxHealth = math.huge
                    end
                end
            end)
        end
    end
})

MountainTab:CreateToggle({
    Name = "Anti Fall (Teleport)",
    CurrentValue = false,
    Callback = toggleAntiFall
})

MountainTab:CreateButton({
    Name = "Teleport to Peak",
    Callback = function()
        local peak = findPeak()
        if peak then
            LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(peak + Vector3.new(0,5,0)))
        end
    end
})

MountainTab:CreateButton({
    Name = "Find Path to Peak",
    Callback = function()
        findPathToPeak()
        Notify("Pathfinder", "Path generated, follow waypoints", 2)
    end
})

MountainTab:CreateToggle({
    Name = "Follow Path",
    CurrentValue = false,
    Callback = function(v)
        if v and #pathfinderWaypoints > 0 then
            spawn(function()
                while v and #pathfinderWaypoints > 0 do
                    local target = pathfinderWaypoints[1]
                    if LocalPlayer.Character then
                        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - target).Magnitude
                        if dist < 5 then
                            table.remove(pathfinderWaypoints, 1)
                        else
                            LocalPlayer.Character.Humanoid:MoveTo(target)
                        end
                    end
                    wait(0.5)
                end
                Notify("Pathfinder", "Destination reached", 2)
            end)
        end
    end
})

MountainTab:CreateInput({
    Name = "Set Waypoint",
    PlaceholderText = "x, y, z",
    Callback = function(input)
        local coords = {}
        for num in input:gmatch("%-?%d+%.?%d*") do
            table.insert(coords, tonumber(num))
        end
        if #coords >= 3 then
            table.insert(pathfinderWaypoints, Vector3.new(coords[1], coords[2], coords[3]))
            Notify("Waypoint", "Added", 1)
        end
    end
})

------------------------------------------------
-- ESP TAB (Player ESP)
------------------------------------------------
_G.ESP = false
local ESPObjects = {}
setmetatable(ESPObjects, {__mode = "v"})

local function createESP(player)
    if player == LocalPlayer then return end
    local function onCharacterAdded(char)
        if not _G.ESP then return end
        local head = char:WaitForChild("Head", 5)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not head or not hrp then return end

        local highlight = Instance.new("Highlight")
        highlight.FillColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255, 50, 50)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.new(1,1,1)
        highlight.Parent = char

        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 150, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = head
        billboard.Parent = char

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = billboard

        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 0.4, 0)
        distLabel.Position = UDim2.new(0, 0, 0.6, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        distLabel.TextScaled = true
        distLabel.Font = Enum.Font.Gotham
        distLabel.Parent = billboard

        ESPObjects[player] = {
            char = char,
            highlight = highlight,
            distLabel = distLabel,
            hrp = hrp
        }
    end
    if player.Character then onCharacterAdded(player.Character) end
    player.CharacterAdded:Connect(onCharacterAdded)
end

ESPTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(v)
        _G.ESP = v
        if v then
            for _, player in pairs(Players:GetPlayers()) do createESP(player) end
            Players.PlayerAdded:Connect(createESP)
        else
            for player, data in pairs(ESPObjects) do
                if data.highlight then data.highlight:Destroy() end
            end
            ESPObjects = {}
        end
    end
})

RunService.RenderStepped:Connect(function()
    if not _G.ESP or not LocalPlayer.Character then return end
    local myPos = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myPos then return end
    for player, data in pairs(ESPObjects) do
        pcall(function()
            if data.hrp and data.distLabel then
                local dist = (myPos.Position - data.hrp.Position).Magnitude
                data.distLabel.Text = string.format("%.1fm", dist)
            end
        end)
    end
end)

------------------------------------------------
-- TELEPORT TAB (Ringkas)
------------------------------------------------
local SelectedPlayer = nil

local function updatePlayerList()
    local list = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(list, player.Name) end
    end
    return list
end

local playerDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = updatePlayerList(),
    CurrentOption = {""},
    Callback = function(selected) SelectedPlayer = selected and selected[1] end
})

Players.PlayerAdded:Connect(function() playerDropdown:SetOptions(updatePlayerList()) end)
Players.PlayerRemoving:Connect(function() playerDropdown:SetOptions(updatePlayerList()) end)

TeleportTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if not SelectedPlayer then Notify("Error", "Select player first", 2) return end
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:SetPrimaryPartCFrame(target.Character.HumanoidRootPart.CFrame)
        end
    end
})

TeleportTab:CreateInput({
    Name = "Teleport to XYZ",
    PlaceholderText = "x y z",
    Callback = function(input)
        local coords = {}
        for num in input:gmatch("%-?%d+%.?%d*") do
            table.insert(coords, tonumber(num))
        end
        if #coords >= 3 and LocalPlayer.Character then
            LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(coords[1], coords[2], coords[3]))
        end
    end
})

------------------------------------------------
-- UTILITY TAB (Ringkas)
------------------------------------------------
_G.AntiAFK = false
local antiAFKConnection

UtilityTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Callback = function(v)
        _G.AntiAFK = v
        if antiAFKConnection then antiAFKConnection:Disconnect() end
        if v then
            antiAFKConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
})

UtilityTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        pcall(function() TPService:Teleport(game.PlaceId, LocalPlayer) end)
    end
})

UtilityTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        Notify("Server Hop", "Searching...", 2)
        local success, servers = pcall(function()
            local res = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")
            return HttpService:JSONDecode(res)
        end)
        if success and servers and servers.data then
            for _, server in ipairs(servers.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TPService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    return
                end
            end
        end
    end
})

UtilityTab:CreateInput({
    Name = "Load Script",
    PlaceholderText = "URL...",
    Callback = function(url)
        if url:match("^https?://") then
            pcall(function() loadstring(game:HttpGet(url))() end)
        end
    end
})

------------------------------------------------
-- VISUAL TAB (Ringkas)
------------------------------------------------
_G.FullBright = false

VisualTab:CreateToggle({
    Name = "Full Bright",
    CurrentValue = false,
    Callback = function(v)
        _G.FullBright = v
        Lighting.Brightness = v and 2 or 1
        Lighting.ClockTime = v and 14 or 12
        Lighting.FogEnd = v and 100000 or 50000
        Lighting.GlobalShadows = not v
    end
})

VisualTab:CreateToggle({
    Name = "X-Ray Vision",
    CurrentValue = false,
    Callback = function(v)
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = v and 0.7 or 0
            end
        end
    end
})

VisualTab:CreateSlider({
    Name = "FOV",
    Range = {40, 120},
    CurrentValue = 70,
    Callback = function(v) Workspace.CurrentCamera.FieldOfView = v end
})

------------------------------------------------
-- CLEANUP
------------------------------------------------
local function OnCleanup()
    _G.InfiniteJump = false
    if infiniteJumpConnection then infiniteJumpConnection:Disconnect() end
    _G.Noclip = false
    if noclipHeartbeat then noclipHeartbeat:Disconnect() end
    _G.Fly = false
    if flyConnection then flyConnection:Disconnect() end
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end
    _G.FreeCam = false
    if freeCamMouseConnection then freeCamMouseConnection:Disconnect() end
    if freeCamMoveConnection then freeCamMoveConnection:Disconnect() end
    destroyJoystick()
    _G.ESP = false
    for _, data in pairs(ESPObjects) do
        if data.highlight then data.highlight:Destroy() end
    end
    if antiAFKConnection then antiAFKConnection:Disconnect() end
    Workspace.Gravity = 196.2
end

game:BindToClose(OnCleanup)

Notify("XKID MEGA HUB", "All features ready", 2)
print("XKID MEGA HUB loaded")
