local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Optimasi: Pre-load services biar ngga lookup berulang
local Services = setmetatable({}, {
    __index = function(t, k)
        local success, service = pcall(game.GetService, game, k)
        if success and service then
            rawset(t, k, service)
            return service
        end
        return nil
    end
})

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local UIS = Services.UserInputService
local RunService = Services.RunService
local Workspace = Services.Workspace
local TPService = Services.TeleportService
local HttpService = Services.HttpService
local Lighting = Services.Lighting
local VirtualUser = Services.VirtualUser
local StarterGui = Services.StarterGui
local CollectionService = Services.CollectionService

-- UI Configuration
local Window = Rayfield:CreateWindow({
    Name = "🔥 XKID HUB PRO 🔥",
    LoadingTitle = "XKID HUB PRO",
    LoadingSubtitle = "Optimized & Stable",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKidHub",
        FileName = "Config"
    },
    KeySystem = false
})

-- Notifikasi startup
local function Notify(title, content, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = duration or 3
    })
end

Notify("XKID HUB PRO", "Loading complete", 2)

------------------------------------------------
-- TAB MENU
------------------------------------------------
local MainTab = Window:CreateTab("🏠 Main", nil)
local PlayerTab = Window:CreateTab("👤 Player", nil)
local ESPTab = Window:CreateTab("👁 ESP", nil)
local TeleportTab = Window:CreateTab("🏝 Teleport", nil)
local UtilityTab = Window:CreateTab("⚙ Utility", nil)
local VisualTab = Window:CreateTab("🎨 Visual", nil)

------------------------------------------------
-- MAIN TAB - FIXED
------------------------------------------------

-- Infinite Jump dengan proper handling
_G.InfiniteJump = false
local infiniteJumpConnection

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        _G.InfiniteJump = v
        
        -- Cleanup old connection
        if infiniteJumpConnection then
            infiniteJumpConnection:Disconnect()
            infiniteJumpConnection = nil
        end
        
        -- Setup new connection if enabled
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

-- Noclip dengan throttle dan error handling
_G.Noclip = false
local noclipHeartbeat

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        _G.Noclip = v
        
        -- Cleanup old connection
        if noclipHeartbeat then
            noclipHeartbeat:Disconnect()
            noclipHeartbeat = nil
        end
        
        -- Setup throttled noclip (update setiap 0.1 detik instead of every frame)
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
-- PLAYER TAB - FIXED
------------------------------------------------

-- WalkSpeed dengan character respawn handling
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

-- Auto-update walkspeed on respawn
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

-- JumpPower dengan properti baru (JumpHeight for newer Roblox)
_G.JumpPower = 50
local jumppowerConnection

local function updateJumpPower(power)
    _G.JumpPower = power
    pcall(function()
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                -- Support both old and new property names
                if humanoid:FindFirstChild("JumpPower") then
                    humanoid.JumpPower = power
                elseif humanoid:FindFirstChild("JumpHeight") then
                    humanoid.JumpHeight = power / 2 -- Convert roughly
                end
            end
        end
    end)
end

-- Auto-update jumppower on respawn
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

-- Gravity control (advanced)
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
-- ESP TAB - FIXED (No memory leak)
------------------------------------------------

_G.ESP = false
local ESPObjects = {}  -- Weak table biar auto cleanup
setmetatable(ESPObjects, {__mode = "v"})

local function createESP(player)
    if player == LocalPlayer then return end
    
    local function onCharacterAdded(char)
        if not _G.ESP then return end
        
        -- Wait for required parts
        local head = char:WaitForChild("Head", 5)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not head or not hrp then return end
        
        -- Create Highlight dengan konfigurasi optimal
        local highlight = Instance.new("Highlight")
        highlight.FillColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255, 50, 50)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.OutlineTransparency = 0
        highlight.Parent = char
        
        -- Billboard dengan nama dan jarak
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
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
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
        
        -- Store references for updating
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

-- ESP toggle
ESPTab:CreateToggle({
    Name = "ESP Enabled",
    CurrentValue = false,
    Callback = function(v)
        _G.ESP = v
        
        if v then
            -- Create ESP for all existing players
            for _, player in pairs(Players:GetPlayers()) do
                createESP(player)
            end
            
            -- Handle new players joining
            Players.PlayerAdded:Connect(createESP)
            
            -- Handle players leaving (cleanup)
            Players.PlayerRemoving:Connect(function(player)
                if ESPObjects[player] then
                    ESPObjects[player] = nil
                end
            end)
        else
            -- Destroy all ESP objects
            for player, data in pairs(ESPObjects) do
                if data.highlight then
                    data.highlight:Destroy()
                end
            end
            ESPObjects = {}
        end
    end
})

-- Distance update loop (throttled)
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
-- TELEPORT TAB - FIXED (Dynamic dropdown)
------------------------------------------------

local SelectedPlayer = nil
local playerList = {}

local function updatePlayerList()
    local newList = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(newList, player.Name)
        end
    end
    return newList
end

-- Create dropdown with dynamic update
local playerDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = updatePlayerList(),
    CurrentOption = {""},
    Callback = function(selected)
        SelectedPlayer = selected and selected[1]
    end
})

-- Auto-refresh dropdown when players join/leave
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

-- Teleport to coordinates
TeleportTab:CreateInput({
    Name = "Teleport to Coordinates",
    PlaceholderText = "x, y, z",
    Callback = function(input)
        local coords = {}
        for num in input:gmatch("%-?%d+%.?%d*") do
            table.insert(coords, tonumber(num))
        end
        
        if #coords >= 3 and LocalPlayer.Character then
            LocalPlayer.Character:SetPrimaryPartCFrame(
                CFrame.new(coords[1], coords[2], coords[3])
            )
        end
    end
})

------------------------------------------------
-- UTILITY TAB - FIXED
------------------------------------------------

-- Anti AFK yang bener
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

-- Rejoin dengan error handling
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

-- Server Hop dengan better API handling
UtilityTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        Notify("Server Hop", "Searching for servers...", 2)
        
        local success, servers = pcall(function()
            local response = game:HttpGet(
                "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            )
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

-- Reset Character dengan safety check
UtilityTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
            Notify("Reset", "Character reset", 1)
        end
    end
})

-- Script Loader dengan validasi URL
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
-- VISUAL TAB - NEW
------------------------------------------------

-- Full Bright dengan toggle (bisa revert)
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
            Lighting.Ambient = Color3.new(1, 1, 1)
        else
            -- Revert to default
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.FogEnd = 50000
            Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.new(0, 0, 0)
        end
    end
})

-- X-Ray vision
_G.XRay = false

VisualTab:CreateToggle({
    Name = "X-Ray Vision",
    CurrentValue = false,
    Callback = function(v)
        _G.XRay = v
        
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency ~= 1 then
                if v then
                    part.LocalTransparencyModifier = 0.7
                else
                    part.LocalTransparencyModifier = 0
                end
            end
        end
    end
})

-- FOV Changer
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

-- Cleanup function
local function OnCleanup()
    -- Disable all features
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
end

-- Bind cleanup to game close
game:BindToClose(OnCleanup)

--[[
    XKID HUB PRO - PHOTOGRAPHY MODULE
    Fitur: Free Cam Cinematic + Portrait Mode
    Author: V
    Category: Creative Tools
]]

-- Tambahkan ini di bagian VISUAL TAB atau bikin tab baru

------------------------------------------------
-- PHOTOGRAPHY TAB (NEW)
------------------------------------------------
local PhotoTab = Window:CreateTab("📸 Photography", nil)

------------------------------------------------
-- FREE CAM CINEMATIC
------------------------------------------------
_G.FreeCam = false
_G.FreeCamSpeed = 0.5
_G.FreeCamRotateSpeed = 0.3
_G.CinematicMode = false

-- State management
local freeCamConnection = nil
local freeCamMouseConnection = nil
local freeCamKeyboardConnection = nil
local freeCamMoveConnection = nil
local freeCamRotation = Vector2.new(0, 0)
local freeCamPosition = Vector3.new(0, 10, 0)
local originalCameraSubject = nil
local originalCameraCFrame = nil
local originalCameraFocus = nil
local cameraLocked = false

local function toggleFreeCam(state)
    if state == _G.FreeCam then return end
    _G.FreeCam = state
    
    local camera = Workspace.CurrentCamera
    
    if state then
        -- Save original camera state
        originalCameraSubject = camera.CameraSubject
        originalCameraCFrame = camera.CFrame
        originalCameraFocus = camera.Focus
        
        -- Initialize free cam position at current camera location
        freeCamPosition = camera.CFrame.Position
        freeCamRotation = Vector2.new(
            camera.CFrame:ToEulerAnglesYXZ()
        )
        
        -- Detach camera
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CameraSubject = nil
        
        -- Input handling
        freeCamMouseConnection = UIS.InputChanged:Connect(function(input)
            if not _G.FreeCam or cameraLocked then return end
            
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Delta
                freeCamRotation = freeCamRotation + Vector2.new(
                    -delta.Y * _G.FreeCamRotateSpeed,
                    -delta.X * _G.FreeCamRotateSpeed
                )
                -- Clamp vertical rotation
                freeCamRotation = Vector2.new(
                    math.clamp(freeCamRotation.X, -80, 80),
                    freeCamRotation.Y
                )
            end
        end)
        
        -- Movement handling
        freeCamMoveConnection = RunService.RenderStepped:Connect(function()
            if not _G.FreeCam then return end
            
            local moveDir = Vector3.new()
            
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
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end
            if UIS:IsKeyDown(Enum.KeyCode.E) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            
            if moveDir.Magnitude > 0 then
                freeCamPosition = freeCamPosition + moveDir.Unit * _G.FreeCamSpeed
            end
            
            -- Update camera
            local rotationCF = CFrame.Angles(
                math.rad(freeCamRotation.X),
                math.rad(freeCamRotation.Y),
                0
            )
            camera.CFrame = rotationCF + freeCamPosition
        end)
        
        Notify("Free Cam", "Active - WASD+QE to move, mouse to look", 3)
        
    else
        -- Restore original camera
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = originalCameraSubject
        camera.CFrame = originalCameraCFrame
        camera.Focus = originalCameraFocus
        
        -- Cleanup connections
        if freeCamMouseConnection then
            freeCamMouseConnection:Disconnect()
            freeCamMouseConnection = nil
        end
        if freeCamMoveConnection then
            freeCamMoveConnection:Disconnect()
            freeCamMoveConnection = nil
        end
        
        Notify("Free Cam", "Deactivated", 2)
    end
end

-- Free Cam Toggle
PhotoTab:CreateToggle({
    Name = "Free Cam Mode",
    CurrentValue = false,
    Callback = toggleFreeCam
})

-- Free Cam Speed Slider
PhotoTab:CreateSlider({
    Name = "Camera Speed",
    Range = {0.1, 3},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(v)
        _G.FreeCamSpeed = v
    end
})

-- Free Cam Rotation Speed
PhotoTab:CreateSlider({
    Name = "Rotation Speed",
    Range = {0.1, 1},
    Increment = 0.05,
    CurrentValue = 0.3,
    Callback = function(v)
        _G.FreeCamRotateSpeed = v
    end
})

-- Lock Camera Toggle (biar ngga gerak)
PhotoTab:CreateToggle({
    Name = "Lock Camera Position",
    CurrentValue = false,
    Callback = function(v)
        cameraLocked = v
    end
})

-- Reset Camera Position
PhotoTab:CreateButton({
    Name = "Reset Camera",
    Callback = function()
        if _G.FreeCam then
            freeCamPosition = originalCameraCFrame.Position
            freeCamRotation = Vector2.new(0, 0)
        end
    end
})

------------------------------------------------
-- PORTRAIT MODE (LAYAR ON)
------------------------------------------------
_G.PortraitMode = false
_G.UIVisibility = true
_G.HideGUI = false

local portraitConnection = nil

local function togglePortraitMode(state)
    _G.PortraitMode = state
    
    local camera = Workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    
    if state then
        -- Force viewport to portrait orientation (9:16 aspect ratio)
        local targetWidth = viewportSize.Y * 9/16
        local targetHeight = viewportSize.Y
        
        -- Calculate letterboxing
        local offsetX = (viewportSize.X - targetWidth) / 2
        
        -- Create letterbox bars
        local leftBar = Instance.new("Frame")
        leftBar.Name = "PortraitLeftBar"
        leftBar.Size = UDim2.new(0, offsetX, 1, 0)
        leftBar.Position = UDim2.new(0, 0, 0, 0)
        leftBar.BackgroundColor3 = Color3.new(0, 0, 0)
        leftBar.BackgroundTransparency = 0.5
        leftBar.BorderSizePixel = 0
        leftBar.Parent = camera:FindFirstChildOfClass("PlayerGui") or LocalPlayer.PlayerGui
        
        local rightBar = Instance.new("Frame")
        rightBar.Name = "PortraitRightBar"
        rightBar.Size = UDim2.new(0, offsetX, 1, 0)
        rightBar.Position = UDim2.new(1, -offsetX, 0, 0)
        rightBar.BackgroundColor3 = Color3.new(0, 0, 0)
        rightBar.BackgroundTransparency = 0.5
        rightBar.BorderSizePixel = 0
        rightBar.Parent = camera:FindFirstChildOfClass("PlayerGui") or LocalPlayer.PlayerGui
        
        -- Create viewport guide
        local guide = Instance.new("Frame")
        guide.Name = "PortraitGuide"
        guide.Size = UDim2.new(0, targetWidth, 0, targetHeight)
        guide.Position = UDim2.new(0.5, -targetWidth/2, 0.5, -targetHeight/2)
        guide.BackgroundTransparency = 1
        guide.BorderSizePixel = 2
        guide.BorderColor3 = Color3.fromRGB(255, 255, 255)
        guide.BorderMode = Enum.BorderMode.Inset
        guide.Parent = LocalPlayer.PlayerGui
        
        -- Rule of thirds grid
        local gridFrame = Instance.new("Frame")
        gridFrame.Name = "GridOverlay"
        gridFrame.Size = UDim2.new(1, 0, 1, 0)
        gridFrame.BackgroundTransparency = 1
        gridFrame.Parent = guide
        
        local function createGridLine(pos, horizontal)
            local line = Instance.new("Frame")
            line.Size = horizontal and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 1, 1, 0)
            line.Position = horizontal and UDim2.new(0, 0, pos, 0) or UDim2.new(pos, 0, 0, 0)
            line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            line.BackgroundTransparency = 0.7
            line.BorderSizePixel = 0
            line.Parent = gridFrame
        end
        
        -- Create rule of thirds lines
        createGridLine(0.333, true)  -- Horizontal top
        createGridLine(0.666, true)  -- Horizontal bottom
        createGridLine(0.333, false) -- Vertical left
        createGridLine(0.666, false) -- Vertical right
        
        Notify("Portrait Mode", "Active - 9:16 aspect ratio", 2)
        
    else
        -- Remove UI elements
        for _, v in pairs(LocalPlayer.PlayerGui:GetChildren()) do
            if v.Name == "PortraitLeftBar" or v.Name == "PortraitRightBar" or v.Name == "PortraitGuide" then
                v:Destroy()
            end
        end
    end
end

PhotoTab:CreateToggle({
    Name = "Portrait Mode (9:16)",
    CurrentValue = false,
    Callback = togglePortraitMode
})

------------------------------------------------
-- HUD TOGGLE (buat screenshot bersih)
------------------------------------------------

PhotoTab:CreateToggle({
    Name = "Hide All UI",
    CurrentValue = false,
    Callback = function(v)
        _G.HideGUI = v
        
        local playerGui = LocalPlayer.PlayerGui
        
        -- Hide/show all screen GUIs
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "PortraitGuide" then
                gui.Enabled = not v
            end
        end
        
        -- Hide/show core GUI
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not v)
        
        Notify("UI Visibility", v and "Hidden" or "Visible", 1)
    end
})

-- Individual UI element toggle
PhotoTab:CreateDropdown({
    Name = "Toggle UI Elements",
    Options = {"Health Bar", "Toolbar", "Chat", "Backpack", "Player List"},
    Callback = function(selected)
        -- Implementation for individual element toggling
        -- (simplified - will affect all for demo)
    end
})

------------------------------------------------
-- CINEMATIC CAMERA MOVEMENTS
------------------------------------------------

_G.CameraShake = false
_G.DollyZoom = false

-- Camera Shake Effect
PhotoTab:CreateToggle({
    Name = "Camera Shake (Cinematic)",
    CurrentValue = false,
    Callback = function(v)
        _G.CameraShake = v
        
        if v then
            -- Simple camera shake effect
            spawn(function()
                while _G.CameraShake do
                    if _G.FreeCam then
                        local camera = Workspace.CurrentCamera
                        local shake = Vector3.new(
                            math.random(-10, 10)/50,
                            math.random(-10, 10)/50,
                            math.random(-10, 10)/50
                        ) * 0.1
                        camera.CFrame = camera.CFrame * CFrame.new(shake)
                    end
                    wait(0.05)
                end
            end)
        end
    end
})

-- Dolly Zoom Effect (Vertigo effect)
PhotoTab:CreateButton({
    Name = "Dolly Zoom Preview",
    Callback = function()
        spawn(function()
            local camera = Workspace.CurrentCamera
            local originalFOV = camera.FieldOfView
            local originalPos = camera.CFrame.Position
            
            for i = 1, 100 do
                camera.FieldOfView = originalFOV + i * 0.3
                if _G.FreeCam then
                    camera.CFrame = CFrame.new(originalPos - camera.CFrame.LookVector * i * 0.5)
                end
                wait(0.01)
            end
            
            wait(1)
            
            for i = 100, 1, -1 do
                camera.FieldOfView = originalFOV + i * 0.3
                if _G.FreeCam then
                    camera.CFrame = CFrame.new(originalPos - camera.CFrame.LookVector * i * 0.5)
                end
                wait(0.01)
            end
            
            camera.FieldOfView = originalFOV
        end)
    end
})

------------------------------------------------
-- PHOTO BURST MODE
------------------------------------------------

_G.BurstMode = false
_G.BurstInterval = 0.5

PhotoTab:CreateToggle({
    Name = "Burst Mode",
    CurrentValue = false,
    Callback = function(v)
        _G.BurstMode = v
        
        if v then
            spawn(function()
                while _G.BurstMode do
                    -- Take screenshot (simulated)
                    Notify("Burst", "Photo " .. math.random(100,999), 0.3)
                    
                    -- Flash effect
                    local flash = Instance.new("Frame")
                    flash.Size = UDim2.new(1, 0, 1, 0)
                    flash.BackgroundColor3 = Color3.new(1, 1, 1)
                    flash.BackgroundTransparency = 0.5
                    flash.Parent = LocalPlayer.PlayerGui
                    
                    wait(0.1)
                    flash:Destroy()
                    
                    wait(_G.BurstInterval)
                end
            end)
        end
    end
})

PhotoTab:CreateSlider({
    Name = "Burst Interval (s)",
    Range = {0.1, 2},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(v)
        _G.BurstInterval = v
    end
})

------------------------------------------------
-- DEPTH OF FIELD (Simulasi)
------------------------------------------------

_G.DepthOfField = false
_G.DOFStrength = 0.5
_G.DOFFocusDistance = 50

local dofConnection = nil

PhotoTab:CreateToggle({
    Name = "Depth of Field (Blur)",
    CurrentValue = false,
    Callback = function(v)
        _G.DepthOfField = v
        
        if dofConnection then
            dofConnection:Disconnect()
            dofConnection = nil
        end
        
        if v then
            -- Simple DOF simulation by blurring distant objects
            -- Note: This is a visual simulation, not true post-processing
            dofConnection = RunService.RenderStepped:Connect(function()
                if not _G.DepthOfField then return end
                
                -- Apply blur to parts based on distance
                for _, part in pairs(Workspace:GetDescendants()) do
                    if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character) then
                        local dist = (part.Position - Workspace.CurrentCamera.CFrame.Position).Magnitude
                        if dist > _G.DOFFocusDistance then
                            -- Apply blur through transparency (simplified)
                            part.LocalTransparencyModifier = math.min(0.5, (dist - _G.DOFFocusDistance) / 100 * _G.DOFStrength)
                        else
                            part.LocalTransparencyModifier = 0
                        end
                    end
                end
            end)
        else
            -- Reset transparency
            for _, part in pairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0
                end
            end
        end
    end
})

PhotoTab:CreateSlider({
    Name = "DOF Strength",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(v)
        _G.DOFStrength = v
    end
})

PhotoTab:CreateSlider({
    Name = "Focus Distance",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(v)
        _G.DOFFocusDistance = v
    end
})

------------------------------------------------
-- FILTERS (Color Grading)
------------------------------------------------

_G.CurrentFilter = "None"
local filterConnection = nil

local filters = {
    None = function() end,
    Sepia = function(r, g, b, a)
        local gray = 0.3 * r + 0.6 * g + 0.1 * b
        return gray, gray * 0.8, gray * 0.5, a
    end,
    Vintage = function(r, g, b, a)
        return r * 1.2, g * 0.9, b * 0.7, a
    end,
    Cool = function(r, g, b, a)
        return r * 0.9, g * 1.1, b * 1.3, a
    end,
    Warm = function(r, g, b, a)
        return r * 1.3, g * 1.1, b * 0.8, a
    end,
    NightVision = function(r, g, b, a)
        return g * 1.5, g * 1.5, g * 0.8, a
    end
}

PhotoTab:CreateDropdown({
    Name = "Color Filter",
    Options = {"None", "Sepia", "Vintage", "Cool", "Warm", "NightVision"},
    Callback = function(selected)
        _G.CurrentFilter = selected[1]
    end
})

-- Apply filters (simulated through GUI overlay)
local function createFilterOverlay()
    local filterFrame = Instance.new("Frame")
    filterFrame.Name = "ColorFilter"
    filterFrame.Size = UDim2.new(1, 0, 1, 0)
    filterFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    filterFrame.BackgroundTransparency = 0.7
    filterFrame.BorderSizePixel = 0
    filterFrame.Parent = LocalPlayer.PlayerGui
    
    -- Color overlay based on filter
    if _G.CurrentFilter == "Sepia" then
        filterFrame.BackgroundColor3 = Color3.fromRGB(210, 180, 140)
        filterFrame.BackgroundTransparency = 0.5
    elseif _G.CurrentFilter == "Vintage" then
        filterFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 150)
        filterFrame.BackgroundTransparency = 0.6
    elseif _G.CurrentFilter == "Cool" then
        filterFrame.BackgroundColor3 = Color3.fromRGB(200, 220, 255)
        filterFrame.BackgroundTransparency = 0.7
    elseif _G.CurrentFilter == "Warm" then
        filterFrame.BackgroundColor3 = Color3.fromRGB(255, 220, 180)
        filterFrame.BackgroundTransparency = 0.6
    elseif _G.CurrentFilter == "NightVision" then
        filterFrame.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        filterFrame.BackgroundTransparency = 0.8
    else
        filterFrame:Destroy()
        return
    end
    
    return filterFrame
end

-- Update filter when changed
_G.CurrentFilterChanged = false
spawn(function()
    while true do
        wait(0.5)
        if _G.CurrentFilter then
            -- Remove old filter
            for _, v in pairs(LocalPlayer.PlayerGui:GetChildren()) do
                if v.Name == "ColorFilter" then
                    v:Destroy()
                end
            end
            -- Apply new filter
            if _G.CurrentFilter ~= "None" then
                createFilterOverlay()
            end
        end
    end
end)

------------------------------------------------
-- TIMELAPSE MODE
------------------------------------------------

_G.Timelapse = false
_G.TimelapseInterval = 5
_G.TimelapseDuration = 60
_G.TimelapseFrames = {}

PhotoTab:CreateToggle({
    Name = "Timelapse Mode",
    CurrentValue = false,
    Callback = function(v)
        _G.Timelapse = v
        
        if v then
            _G.TimelapseFrames = {}
            Notify("Timelapse", "Recording started", 2)
            
            spawn(function()
                local startTime = tick()
                while _G.Timelapse and (tick() - startTime) < _G.TimelapseDuration do
                    -- Save camera position (simulated)
                    table.insert(_G.TimelapseFrames, {
                        time = tick() - startTime,
                        cframe = Workspace.CurrentCamera.CFrame
                    })
                    Notify("Timelapse", "Frame " .. #_G.TimelapseFrames, 0.5)
                    wait(_G.TimelapseInterval)
                end
                
                if _G.Timelapse then
                    _G.Timelapse = false
                    Notify("Timelapse", "Recording complete: " .. #_G.TimelapseFrames .. " frames", 3)
                end
            end)
        else
            Notify("Timelapse", "Recording stopped: " .. #_G.TimelapseFrames .. " frames", 2)
        end
    end
})

PhotoTab:CreateSlider({
    Name = "Timelapse Interval (s)",
    Range = {1, 30},
    Increment = 1,
    CurrentValue = 5,
    Callback = f
print("XKID HUB PRO - Loaded successfully")
Notify("XKID HUB PRO", "Ready to use", 2)
