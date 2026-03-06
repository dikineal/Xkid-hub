local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services loader (kompatibel semua executor)
local function getService(name)
    local s, err = pcall(function() return game:GetService(name) end)
    return s and err or nil
end

local Players = getService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = getService("UserInputService")
local RunService = getService("RunService")
local Workspace = getService("Workspace")
local TPService = getService("TeleportService")
local HttpService = getService("HttpService")
local Lighting = getService("Lighting")
local VirtualUser = getService("VirtualUser")
local StarterGui = getService("StarterGui")
local TouchGui = getService("TouchGui") -- Khusus Android

-- Validasi service
if not Players or not UIS then
    return warn("Gagal memuat service. Restart executor atau gunakan executor lain.")
end

-- Utility clamp
local function clamp(v, min, max)
    return math.max(min, math.min(max, v))
end

-- Deteksi platform
local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled
if isMobile then
    print("Android mode activated")
end

-- UI Window
local Window = Rayfield:CreateWindow({
    Name = "🔥 XKID HUB ANDROID 🔥",
    LoadingTitle = "XKID HUB ANDROID",
    LoadingSubtitle = "Touch Optimized",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKidHub",
        FileName = "Config"
    },
    KeySystem = false
})

local function Notify(title, content, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = duration or 3
    })
end

Notify("XKID HUB ANDROID", "Loading complete", 2)

------------------------------------------------
-- TAB MENU
------------------------------------------------
local MainTab = Window:CreateTab("🏠 Main", nil)
local PlayerTab = Window:CreateTab("👤 Player", nil)
local ESPTab = Window:CreateTab("👁 ESP", nil)
local TeleportTab = Window:CreateTab("🏝 Teleport", nil)
local UtilityTab = Window:CreateTab("⚙ Utility", nil)
local VisualTab = Window:CreateTab("🎨 Visual", nil)
local PhotoTab = Window:CreateTab("📸 Photography", nil)

------------------------------------------------
-- MAIN TAB
------------------------------------------------
_G.InfiniteJump = false
local infiniteJumpConnection

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        _G.InfiniteJump = v
        if infiniteJumpConnection then
            infiniteJumpConnection:Disconnect()
            infiniteJumpConnection = nil
        end
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
        if noclipHeartbeat then
            noclipHeartbeat:Disconnect()
            noclipHeartbeat = nil
        end
        if v then
            local lastUpdate = 0
            noclipHeartbeat = RunService.Heartbeat:Connect(function()
                local now = tick()
                if now - lastUpdate < 0.1 then return end
                lastUpdate = now
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
            if humanoid then
                humanoid.WalkSpeed = speed
            end
        end
    end)
end

if walkspeedConnection then walkspeedConnection:Disconnect() end
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

if jumppowerConnection then jumppowerConnection:Disconnect() end
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

------------------------------------------------
-- ESP TAB
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
        highlight.OutlineTransparency = 0
        highlight.Parent = char

        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 150, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = head
        billboard.Parent = char

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = billboard

        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 0.4, 0)
        distLabel.Position = UDim2.new(0, 0, 0.6, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "0m"
        distLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        distLabel.TextStrokeTransparency = 0.5
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
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

ESPTab:CreateToggle({
    Name = "ESP Enabled",
    CurrentValue = false,
    Callback = function(v)
        _G.ESP = v
        if v then
            for _, player in pairs(Players:GetPlayers()) do
                createESP(player)
            end
            Players.PlayerAdded:Connect(createESP)
            Players.PlayerRemoving:Connect(function(player)
                if ESPObjects[player] then
                    ESPObjects[player] = nil
                end
            end)
        else
            for player, data in pairs(ESPObjects) do
                if data.highlight then
                    data.highlight:Destroy()
                end
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
-- TELEPORT TAB
------------------------------------------------
local SelectedPlayer = nil

local function updatePlayerList()
    local list = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(list, player.Name)
        end
    end
    return list
end

local playerDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = updatePlayerList(),
    CurrentOption = {""},
    Callback = function(selected)
        SelectedPlayer = selected and selected[1]
    end
})

local function refreshDropdown()
    playerDropdown:SetOptions(updatePlayerList())
end
Players.PlayerAdded:Connect(refreshDropdown)
Players.PlayerRemoving:Connect(refreshDropdown)

TeleportTab:CreateButton({
    Name = "Teleport To Player",
    Callback = function()
        if not SelectedPlayer then
            Notify("Error", "Select a player first", 2)
            return
        end
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:SetPrimaryPartCFrame(target.Character.HumanoidRootPart.CFrame)
        else
            Notify("Error", "Target not found or invalid", 2)
        end
    end
})

TeleportTab:CreateButton({
    Name = "Spectate Player",
    Callback = function()
        if not SelectedPlayer then
            Notify("Error", "Select a player first", 2)
            return
        end
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character then
            local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                Workspace.CurrentCamera.CameraSubject = humanoid
                Notify("Spectating", SelectedPlayer, 2)
            end
        end
    end
})

TeleportTab:CreateButton({
    Name = "Stop Spectate",
    Callback = function()
        pcall(function()
            if LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    Workspace.CurrentCamera.CameraSubject = humanoid
                end
            end
        end)
    end
})

TeleportTab:CreateInput({
    Name = "Teleport to Coordinates",
    PlaceholderText = "x, y, z",
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
-- UTILITY TAB
------------------------------------------------
_G.AntiAFK = false
local antiAFKConnection

UtilityTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Callback = function(v)
        _G.AntiAFK = v
        if antiAFKConnection then
            antiAFKConnection:Disconnect()
            antiAFKConnection = nil
        end
        if v then
            antiAFKConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                Notify("Anti AFK", "AFK Detection Bypassed", 1)
            end)
        end
    end
})

UtilityTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        local success, err = pcall(function()
            TPService:Teleport(game.PlaceId, LocalPlayer)
        end)
        if not success then
            Notify("Error", "Failed to rejoin: " .. tostring(err), 3)
        end
    end
})

UtilityTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        Notify("Server Hop", "Searching for servers...", 2)
        local success, servers = pcall(function()
            local response = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
            return HttpService:JSONDecode(response)
        end)
        if success and servers and servers.data then
            for _, server in ipairs(servers.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    Notify("Server Hop", "Found server, joining...", 2)
                    TPService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    return
                end
            end
            Notify("Server Hop", "No suitable servers found", 2)
        else
            Notify("Server Hop", "Failed to fetch servers", 2)
        end
    end
})

UtilityTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
            Notify("Reset", "Character reset", 1)
        end
    end
})

UtilityTab:CreateInput({
    Name = "Load Script URL",
    PlaceholderText = "Paste raw script link...",
    Callback = function(url)
        if url:match("^https?://") then
            Notify("Loading", "Loading script...", 2)
            local success, result = pcall(function()
                loadstring(game:HttpGet(url))()
            end)
            if success then
                Notify("Success", "Script loaded", 2)
            else
                Notify("Error", "Failed to load script", 3)
            end
        else
            Notify("Error", "Invalid URL", 2)
        end
    end
})

------------------------------------------------
-- VISUAL TAB
------------------------------------------------
_G.FullBright = false

VisualTab:CreateToggle({
    Name = "Full Bright",
    CurrentValue = false,
    Callback = function(v)
        _G.FullBright = v
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.new(1,1,1)
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.FogEnd = 50000
            Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.new(0,0,0)
        end
    end
})

_G.XRay = false

VisualTab:CreateToggle({
    Name = "X-Ray Vision",
    CurrentValue = false,
    Callback = function(v)
        _G.XRay = v
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency ~= 1 then
                part.LocalTransparencyModifier = v and 0.7 or 0
            end
        end
    end
})

_G.FOV = 70

VisualTab:CreateSlider({
    Name = "Field of View",
    Range = {40, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(v)
        _G.FOV = v
        Workspace.CurrentCamera.FieldOfView = v
    end
})

------------------------------------------------
-- PHOTOGRAPHY TAB - ANDROID EDITION
------------------------------------------------
_G.FreeCam = false
_G.FreeCamSpeed = 0.5
_G.FreeCamRotateSpeed = 0.3
local freeCamMouseConnection = nil
local freeCamMoveConnection = nil
local freeCamRotation = Vector2.new(0, 0)
local freeCamPosition = Vector3.new(0, 10, 0)
local originalCameraSubject = nil
local originalCameraCFrame = nil
local cameraLocked = false

-- Touch controls untuk Android
local touchStartPos = nil
local touchCurrentPos = nil
local moveTouchStartPos = nil
local moveTouchCurrentPos = nil
local isTouchMoving = false
local isTouchRotating = false

-- Buat GUI joystick virtual (opsional, bisa dihidupkan/mati)
_G.UseVirtualJoystick = true
local joystickFrame = nil
local joystickKnob = nil
local joystickActive = false
local joystickDirection = Vector2.new(0, 0)

local function createVirtualJoystick()
    if joystickFrame then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VirtualJoystick"
    screenGui.Parent = LocalPlayer.PlayerGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Joystick background
    joystickFrame = Instance.new("Frame")
    joystickFrame.Name = "JoystickBG"
    joystickFrame.Size = UDim2.new(0, 120, 0, 120)
    joystickFrame.Position = UDim2.new(0.15, 0, 0.8, 0)
    joystickFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    joystickFrame.BackgroundTransparency = 0.5
    joystickFrame.Active = true
    joystickFrame.Parent = screenGui
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 60)
    bgCorner.Parent = joystickFrame
    
    -- Joystick knob
    joystickKnob = Instance.new("Frame")
    joystickKnob.Name = "JoystickKnob"
    joystickKnob.Size = UDim2.new(0, 50, 0, 50)
    joystickKnob.Position = UDim2.new(0.5, -25, 0.5, -25)
    joystickKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    joystickKnob.BackgroundTransparency = 0.3
    joystickKnob.Parent = joystickFrame
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 25)
    knobCorner.Parent = joystickKnob
    
    -- Touch events untuk joystick
    joystickFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joystickActive = true
            moveTouchStartPos = input.Position
        end
    end)
    
    joystickFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and joystickActive then
            moveTouchCurrentPos = input.Position
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

local function updateJoystick()
    if not _G.UseVirtualJoystick or not joystickActive or not moveTouchStartPos or not moveTouchCurrentPos then 
        joystickDirection = Vector2.new(0, 0)
        return 
    end
    
    local delta = moveTouchCurrentPos - moveTouchStartPos
    local maxDist = 40
    local dist = math.min(delta.Magnitude, maxDist)
    local dir = delta.Unit * dist
    
    -- Update knob position
    joystickKnob.Position = UDim2.new(0.5, dir.X - 25, 0.5, dir.Y - 25)
    
    -- Normalize direction
    if dist > 5 then
        joystickDirection = delta.Unit * (dist / maxDist)
    else
        joystickDirection = Vector2.new(0, 0)
    end
end

-- Free cam toggle untuk Android
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

        -- Ambil rotasi awal
        local rx, ry, rz = camera.CFrame:ToEulerAnglesYXZ()
        freeCamRotation = Vector2.new(math.deg(rx), math.deg(ry))
        freeCamPosition = camera.CFrame.Position

        if isMobile then
            -- Untuk Android, kita pake touch untuk rotate
            freeCamMouseConnection = UIS.InputChanged:Connect(function(input)
                if not _G.FreeCam or cameraLocked then return end
                if input.UserInputType == Enum.UserInputType.Touch then
                    if touchStartPos then
                        touchCurrentPos = input.Position
                        local delta = touchCurrentPos - touchStartPos
                        freeCamRotation = freeCamRotation + Vector2.new(
                            -delta.Y * _G.FreeCamRotateSpeed * 0.5,
                            -delta.X * _G.FreeCamRotateSpeed * 0.5
                        )
                        freeCamRotation = Vector2.new(
                            clamp(freeCamRotation.X, -80, 80),
                            freeCamRotation.Y
                        )
                        touchStartPos = touchCurrentPos
                    else
                        touchStartPos = input.Position
                    end
                end
            end)
            
            -- Touch ended
            UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    touchStartPos = nil
                end
            end)
            
            -- Buat joystick virtual
            createVirtualJoystick()
        else
            -- Untuk PC, pake mouse
            freeCamMouseConnection = UIS.InputChanged:Connect(function(input)
                if not _G.FreeCam or cameraLocked then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = input.Delta
                    freeCamRotation = freeCamRotation + Vector2.new(
                        -delta.Y * _G.FreeCamRotateSpeed,
                        -delta.X * _G.FreeCamRotateSpeed
                    )
                    freeCamRotation = Vector2.new(
                        clamp(freeCamRotation.X, -80, 80),
                        freeCamRotation.Y
                    )
                end
            end)
        end

        freeCamMoveConnection = RunService.RenderStepped:Connect(function()
            if not _G.FreeCam then return end
            
            local moveDir = Vector3.new()
            
            if isMobile and _G.UseVirtualJoystick then
                updateJoystick()
                -- Convert joystick direction to camera movement
                local cameraCF = camera.CFrame
                moveDir = moveDir + cameraCF.LookVector * joystickDirection.Y
                moveDir = moveDir + cameraCF.RightVector * joystickDirection.X
            else
                -- PC controls
                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + camera.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - camera.CFrame.LookVector
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
            end
            
            -- Up/Down untuk Android (bisa pake button nanti)
            if isMobile and UIS:IsKeyDown(Enum.KeyCode.Space) then -- Space di keyboard virtual
                moveDir = moveDir + Vector3.new(0,1,0)
            end
            if isMobile and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDir = moveDir - Vector3.new(0,1,0)
            end

            if moveDir.Magnitude > 0 then
                freeCamPosition = freeCamPosition + moveDir.Unit * _G.FreeCamSpeed
            end

            local rotationCF = CFrame.Angles(
                math.rad(freeCamRotation.X),
                math.rad(freeCamRotation.Y),
                0
            )
            camera.CFrame = rotationCF + freeCamPosition
        end)

        Notify("Free Cam", isMobile and "Touch to look, joystick to move" or "WASD+QE to move, mouse to look", 3)
    else
        if freeCamMouseConnection then
            freeCamMouseConnection:Disconnect()
            freeCamMouseConnection = nil
        end
        if freeCamMoveConnection then
            freeCamMoveConnection:Disconnect()
            freeCamMoveConnection = nil
        end
        
        -- Hapus joystick
        if joystickFrame and joystickFrame.Parent then
            joystickFrame.Parent:Destroy()
            joystickFrame = nil
            joystickKnob = nil
        end

        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = originalCameraSubject
        camera.CFrame = originalCameraCFrame

        Notify("Free Cam", "Deactivated", 2)
    end
end

PhotoTab:CreateToggle({
    Name = "Free Cam Mode",
    CurrentValue = false,
    Callback = toggleFreeCam
})

-- Hanya tampilkan joystick toggle untuk Android
if isMobile then
    PhotoTab:CreateToggle({
        Name = "Virtual Joystick",
        CurrentValue = true,
        Callback = function(v)
            _G.UseVirtualJoystick = v
            if v then
                createVirtualJoystick()
            elseif joystickFrame and joystickFrame.Parent then
                joystickFrame.Parent:Destroy()
                joystickFrame = nil
                joystickKnob = nil
            end
        end
    })
end

PhotoTab:CreateSlider({
    Name = "Camera Speed",
    Range = {0.1, 3},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(v)
        _G.FreeCamSpeed = v
    end
})

PhotoTab:CreateSlider({
    Name = "Rotation Speed",
    Range = {0.1, 1},
    Increment = 0.05,
    CurrentValue = 0.3,
    Callback = function(v)
        _G.FreeCamRotateSpeed = v
    end
})

PhotoTab:CreateToggle({
    Name = "Lock Camera Position",
    CurrentValue = false,
    Callback = function(v)
        cameraLocked = v
    end
})

PhotoTab:CreateButton({
    Name = "Reset Camera",
    Callback = function()
        if _G.FreeCam and originalCameraCFrame then
            freeCamPosition = originalCameraCFrame.Position
            freeCamRotation = Vector2.new(0,0)
        end
    end
})

-- Portrait Mode (tetap sama untuk Android)
_G.PortraitMode = false
PhotoTab:CreateToggle({
    Name = "Portrait Mode (9:16)",
    CurrentValue = false,
    Callback = function(v)
        _G.PortraitMode = v
        local camera = Workspace.CurrentCamera
        local viewport = camera.ViewportSize
        if v then
            local targetWidth = viewport.Y * 9/16
            local offsetX = (viewport.X - targetWidth) / 2

            local leftBar = Instance.new("Frame")
            leftBar.Name = "PortraitLeftBar"
            leftBar.Size = UDim2.new(0, offsetX, 1, 0)
            leftBar.Position = UDim2.new(0,0,0,0)
            leftBar.BackgroundColor3 = Color3.new(0,0,0)
            leftBar.BackgroundTransparency = 0.5
            leftBar.BorderSizePixel = 0
            leftBar.Parent = LocalPlayer.PlayerGui

            local rightBar = Instance.new("Frame")
            rightBar.Name = "PortraitRightBar"
            rightBar.Size = UDim2.new(0, offsetX, 1, 0)
            rightBar.Position = UDim2.new(1, -offsetX, 0, 0)
            rightBar.BackgroundColor3 = Color3.new(0,0,0)
            rightBar.BackgroundTransparency = 0.5
            rightBar.BorderSizePixel = 0
            rightBar.Parent = LocalPlayer.PlayerGui

            local guide = Instance.new("Frame")
            guide.Name = "PortraitGuide"
            guide.Size = UDim2.new(0, targetWidth, 0, viewport.Y)
            guide.Position = UDim2.new(0.5, -targetWidth/2, 0.5, -viewport.Y/2)
            guide.BackgroundTransparency = 1
            guide.BorderSizePixel = 2
            guide.BorderColor3 = Color3.new(1,1,1)
            guide.Parent = LocalPlayer.PlayerGui

            -- Rule of thirds grid
            local grid = Instance.new("Frame")
            grid.Size = UDim2.new(1,0,1,0)
            grid.BackgroundTransparency = 1
            grid.Parent = guide
            local function addGridLine(pos, horiz)
                local line = Instance.new("Frame")
                line.Size = horiz and UDim2.new(1,0,0,1) or UDim2.new(0,1,1,0)
                line.Position = horiz and UDim2.new(0,0,pos,0) or UDim2.new(pos,0,0,0)
                line.BackgroundColor3 = Color3.new(1,1,1)
                line.BackgroundTransparency = 0.7
                line.BorderSizePixel = 0
                line.Parent = grid
            end
            addGridLine(0.333, true)
            addGridLine(0.666, true)
            addGridLine(0.333, false)
            addGridLine(0.666, false)
        else
            for _, obj in pairs(LocalPlayer.PlayerGui:GetChildren()) do
                if obj.Name:match("Portrait") then
                    obj:Destroy()
                end
            end
        end
    end
})

-- Hide UI
_G.HideGUI = false
PhotoTab:CreateToggle({
    Name = "Hide All UI",
    CurrentValue = false,
    Callback = function(v)
        _G.HideGUI = v
        for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "PortraitGuide" and not gui.Name:match("Portrait") and gui.Name ~= "VirtualJoystick" then
                gui.Enabled = not v
            end
        end
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not v)
        Notify("UI Visibility", v and "Hidden" or "Visible", 1)
    end
})

-- Screenshot helper
PhotoTab:CreateButton({
    Name = "📸 Take Screenshot",
    Callback = function()
        local uiState = _G.HideGUI
        if not uiState then
            _G.HideGUI = true
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
        end
        wait(0.1)
        for i = 3, 1, -1 do
            Notify("Screenshot", "Capturing in " .. i, 0.5)
            wait(0.5)
        end
        local shutter = Instance.new("Frame")
        shutter.Size = UDim2.new(1,0,1,0)
        shutter.BackgroundColor3 = Color3.new(1,1,1)
        shutter.BackgroundTransparency = 1
        shutter.Parent = LocalPlayer.PlayerGui
        for i = 1, 0, -0.1 do
            shutter.BackgroundTransparency = i
            wait(0.01)
        end
        Notify("Screenshot", "Captured! (Use volume buttons to save)", 2)
        wait(0.1)
        shutter:Destroy()
        if not uiState then
            _G.HideGUI = false
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end
    end
})

------------------------------------------------
-- CLEANUP
------------------------------------------------
local function OnCleanup()
    _G.InfiniteJump = false
    if infiniteJumpConnection then infiniteJumpConnection:Disconnect() end
    _G.Noclip = false
    if noclipHeartbeat then noclipHeartbeat:Disconnect() end
    _G.ESP = false
    for _, data in pairs(ESPObjects) do
        if data.highlight then data.highlight:Destroy() end
    end
    Workspace.Gravity = 196.2
    Workspace.CurrentCamera.FieldOfView = 70
    if freeCamMouseConnection then freeCamMouseConnection:Disconnect() end
    if freeCamMoveConnection then freeCamMoveConnection:Disconnect() end
    if antiAFKConnection then antiAFKConnection:Disconnect() end
    if joystickFrame and joystickFrame.Parent then
        joystickFrame.Parent:Destroy()
    end
end

game:BindToClose(OnCleanup)

Notify("XKID HUB ANDROID", "All systems ready", 2)
print("XKID HUB ANDROID + Photography loaded successfully")
