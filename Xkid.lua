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

print("XKID HUB PRO - Loaded successfully")
Notify("XKID HUB PRO", "Ready to use", 2)
