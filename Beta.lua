--[[
WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]

-- XKID ULTIMATE v6.1 (CLEAN - TANPA BACKDOOR)
-- Fitur: Teleport, Freecam, Remote Spy, ESP, Pathfinding, Anti-Kick

Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("AssetService")
local VirtualUser = game:GetService("VirtualUser")

-- ============================================
-- WINDOW AESTHETIC
-- ============================================
local Win = Library:Window(
    "✨ XKID ULTIMATE v6.1", 
    "crown", 
    "Teleport · Freecam · Remote Spy · ESP", 
    false
)

-- ============================================
-- TAB MENU
-- ============================================
Win:TabSection("🚀 TELEPORT")
local TeleportTab = Win:Tab("Teleport", "map-pin")

Win:TabSection("🎥 CAMERA")
local CameraTab = Win:Tab("Camera", "video")

Win:TabSection("🔍 REMOTE SPY")
local SpyTab = Win:Tab("Remote Spy", "radio")

Win:TabSection("👁️ ESP")
local ESPTab = Win:Tab("ESP", "eye")

Win:TabSection("🛡️ PROTECTION")
local ProtectTab = Win:Tab("Protection", "shield")

Win:TabSection("⚙ UTILITY")
local UtilityTab = Win:Tab("Utility", "settings")

-- ============================================
-- GLOBAL VARIABLES
-- ============================================
_G.fly_evts = _G.fly_evts or {}
_G.ESP_Objects = {}
_G.ESP_Events = {}
_G.zm_h = {}

-- ============================================
-- TELEPORT FUNCTIONS
-- ============================================
local function teleportToPlace(id, instance)
    if instance then
        TeleportService:TeleportToPlaceInstance(id, instance)
    else
        TeleportService:Teleport(id)
    end
end

local function teleportToPlayer(pl_ref)
    local function findPlayer(ref)
        if typeof(ref) == 'string' then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name:lower():find(ref:lower()) or p.DisplayName:lower():find(ref:lower()) then
                    return p
                end
            end
        end
        return nil
    end
    
    local target = findPlayer(pl_ref)
    if not target or not target.Character then return end
    
    local hrp = target.Character:FindFirstChild('HumanoidRootPart')
    if hrp and LocalPlayer.Character then
        LocalPlayer.Character:SetPrimaryPartCFrame(hrp.CFrame + Vector3.new(0, 5, 0))
        Library:Notification("Teleport", "Ke " .. target.Name, 2)
    end
end

-- ============================================
-- PATHFINDING / WAYPOINT
-- ============================================
local waypoints = {}
local waypointSpeed = 139
local waypointTimes = 1
local waypointShuttle = false

local function cleanup_path()
    if _G.fp_rp then _G.fp_rp:Destroy() end
    if _G.fp_bg then _G.fp_bg:Destroy() end
    if _G.fp_tr then _G.fp_tr:Destroy() end
    _G.fp_rp = nil; _G.fp_bg = nil; _G.fp_tr = nil
end

local function moveToWaypoint(v, p)
    if typeof(v) == 'Vector3' then
        p.CFrame = CFrame.new(v)
    elseif typeof(v) == 'Instance' and v:IsA('BasePart') then
        p.CFrame = v.CFrame
    elseif typeof(v) == 'CFrame' then
        p.CFrame = v
    end
end

local function startWaypoints()
    cleanup_path()
    if #waypoints == 0 then
        Library:Notification("Error", "Tidak ada waypoint", 3)
        return
    end
    
    local ch = LocalPlayer.Character
    if not ch then return end
    
    local hum = ch:FindFirstChildWhichIsA('Humanoid')
    if not hum then return end
    
    local root = hum.RootPart
    if not root then return end
    
    _G.fp_rp = Instance.new('RocketPropulsion', root)
    _G.fp_bg = Instance.new('BodyGyro', root)
    _G.fp_rp.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    _G.fp_tr = Instance.new('Part', _G.fp_rp)
    _G.fp_tr.Transparency = 1
    _G.fp_tr.Anchored = true
    _G.fp_tr.CanCollide = false
    _G.fp_rp.CartoonFactor = 1
    _G.fp_rp.MaxSpeed = waypointSpeed
    _G.fp_rp.MaxThrust = 1e5
    _G.fp_rp.ThrustP = 1e7
    _G.fp_rp.TurnP = 5e3
    _G.fp_rp.TurnD = 2e3
    _G.fp_rp.Target = _G.fp_tr
    _G.fp_rp:Fire()
    
    task.spawn(function()
        local times = waypointTimes
        while _G.fp_rp and _G.fp_rp.Parent do
            if times == 0 then break end
            for i, wp in ipairs(waypoints) do
                moveToWaypoint(wp, _G.fp_tr)
                task.wait(0.5)
                _G.fp_rp.ReachedTarget:Wait()
                if not _G.fp_rp then break end
            end
            times = times - 1
            if waypointShuttle and _G.fp_rp then
                for i = #waypoints, 1, -1 do
                    moveToWaypoint(waypoints[i], _G.fp_tr)
                    task.wait(0.5)
                    _G.fp_rp.ReachedTarget:Wait()
                    if not _G.fp_rp then break end
                end
            end
        end
        cleanup_path()
        Library:Notification("Waypoint", "Selesai", 2)
    end)
end

-- ============================================
-- FREECAM SYSTEM
-- ============================================
local freecamEnabled = false
local freecamSpeed = 31
local freecamSprintSpeed = 211
local freecamKeys = {}
local freecamFov = 70
local freecamCurrentSpeed = freecamSpeed
local cam = Workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

local moveVectors = {
    [Enum.KeyCode.W] = Vector3.new(0, 0, -1),
    [Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.S] = Vector3.new(0, 0, 1),
    [Enum.KeyCode.D] = Vector3.new(1, 0, 0),
    [Enum.KeyCode.E] = Vector3.new(0, 1, 0),
    [Enum.KeyCode.Q] = Vector3.new(0, -1, 0),
}

local function setFreecam(state)
    freecamEnabled = state
    if state then
        cam.CameraType = Enum.CameraType.Scriptable
        Library:Notification("Freecam", "ON (Mouse look, Scroll zoom)", 2)
    else
        cam.CameraType = Enum.CameraType.Custom
        if LocalPlayer.Character then
            cam.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
        end
        Library:Notification("Freecam", "OFF", 2)
    end
end

UIS.InputBegan:Connect(function(key, processed)
    if processed then return end
    
    if key.KeyCode == Enum.KeyCode.Comma then
        setFreecam(not freecamEnabled)
    elseif freecamEnabled then
        if key.UserInputType == Enum.UserInputType.MouseButton2 then
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        elseif key.KeyCode == Enum.KeyCode.LeftBracket then
            freecamCurrentSpeed = freecamSprintSpeed
        elseif key.KeyCode == Enum.KeyCode.RightBracket then
            freecamFov = 20
        elseif moveVectors[key.KeyCode] then
            freecamKeys[key.KeyCode] = true
        end
    end
end)

UIS.InputEnded:Connect(function(key, processed)
    if processed then return end
    
    if freecamEnabled then
        if key.UserInputType == Enum.UserInputType.MouseButton2 then
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        elseif key.KeyCode == Enum.KeyCode.LeftBracket then
            freecamCurrentSpeed = freecamSpeed
        elseif key.KeyCode == Enum.KeyCode.RightBracket then
            freecamFov = 70
        elseif moveVectors[key.KeyCode] then
            freecamKeys[key.KeyCode] = nil
        end
    end
end)

UIS.WheelForward:Connect(function()
    if freecamEnabled then
        cam.CFrame = cam.CFrame * CFrame.new(0, 0, -5)
    end
end)

UIS.WheelBackward:Connect(function()
    if freecamEnabled then
        cam.CFrame = cam.CFrame * CFrame.new(0, 0, 5)
    end
end)

RunService:BindToRenderStep("FreecamStep", Enum.RenderPriority.Camera.Value, function(dt)
    if not freecamEnabled then return end
    
    -- Mouse look
    local delta = UIS:GetMouseDelta()
    local rotX = -delta.Y * 0.002
    local rotY = -delta.X * 0.002
    cam.CFrame = CFrame.new(cam.CFrame.Position) * CFrame.Angles(rotX, rotY, 0)
    
    -- Movement
    local move = Vector3.new()
    for k, v in pairs(freecamKeys) do
        move = move + moveVectors[k]
    end
    
    if move.Magnitude > 0 then
        move = move.Unit
        cam.CFrame = cam.CFrame + (cam.CFrame:VectorToWorldSpace(move) * freecamCurrentSpeed * dt)
    end
    
    cam.FieldOfView = freecamFov
end)

-- ============================================
-- REMOTE SPY (SEDERHANA)
-- ============================================
local spyActive = false
local spyConnections = {}

local function startSpy()
    if spyActive then
        Library:Notification("Remote Spy", "Sudah aktif", 2)
        return
    end
    
    spyActive = true
    local count = 0
    
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            count = count + 1
            local conn = v.OnClientEvent:Connect(function(...)
                print("\n[REMOTE] " .. v.Name)
                print("Path: " .. v:GetFullName())
                print("Args: ", ...)
            end)
            table.insert(spyConnections, conn)
        end
    end
    
    Library:Notification("Remote Spy", string.format("%d remote di-spy", count), 3)
end

local function stopSpy()
    spyActive = false
    for _, conn in ipairs(spyConnections) do
        conn:Disconnect()
    end
    spyConnections = {}
    Library:Notification("Remote Spy", "Dimatikan", 2)
end

-- ============================================
-- ESP SYSTEM
-- ============================================
local espEnabled = false
local espObjects = {}
local espConnections = {}

local function createESP(player)
    if player == LocalPlayer then return end
    
    local function onCharAdded(char)
        if not espEnabled then return end
        task.wait(0.5)
        
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if head and hrp then
            local bill = Instance.new("BillboardGui")
            bill.Name = "XKID_ESP"
            bill.Size = UDim2.new(0, 150, 0, 50)
            bill.StudsOffset = Vector3.new(0, 3, 0)
            bill.AlwaysOnTop = true
            bill.Adornee = head
            bill.Parent = char
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = player.Team and player.Team.TeamColor.Color or Color3.new(1,1,1)
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = bill
            
            local distLabel = Instance.new("TextLabel")
            distLabel.Size = UDim2.new(1, 0, 0.4, 0)
            distLabel.Position = UDim2.new(0, 0, 0.6, 0)
            distLabel.BackgroundTransparency = 1
            distLabel.TextColor3 = Color3.fromRGB(100,255,100)
            distLabel.TextScaled = true
            distLabel.Font = Enum.Font.Gotham
            distLabel.Parent = bill
            
            table.insert(espObjects, bill)
            
            local conn = RunService.RenderStepped:Connect(function()
                if not bill or not bill.Parent then
                    conn:Disconnect()
                    return
                end
                if LocalPlayer.Character and hrp then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    distLabel.Text = string.format("%.1f m", dist)
                end
            end)
            table.insert(espConnections, conn)
        end
    end
    
    if player.Character then
        onCharAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharAdded)
end

local function toggleESP(state)
    espEnabled = state
    
    if state then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                createESP(p)
            end
        end
        Players.PlayerAdded:Connect(createESP)
        Library:Notification("ESP", "Aktif", 2)
    else
        for _, obj in ipairs(espObjects) do
            pcall(function() obj:Destroy() end)
        end
        for _, conn in ipairs(espConnections) do
            pcall(function() conn:Disconnect() end)
        end
        espObjects = {}
        espConnections = {}
        Library:Notification("ESP", "Mati", 2)
    end
end

-- ============================================
-- ANTI-KICK
-- ============================================
local antiKickActive = false

local function toggleAntiKick(state)
    antiKickActive = state
    
    if state then
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and (method == "Kick" or method == "kick" or method == "Destroy") then
                print("[ANTI-KICK] Blocked:", method)
                return
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        Library:Notification("Anti-Kick", "Aktif", 2)
    else
        Library:Notification("Anti-Kick", "Mati", 2)
    end
end

-- ============================================
-- PLAYER SETTINGS
-- ============================================
local function applyPlayerSettings()
    local setProp = function(o, prop, val)
        o[prop] = val
    end
    
    setProp(LocalPlayer, 'CameraMaxZoomDistance', 1e5)
    setProp(LocalPlayer, 'CameraMinZoomDistance', 0)
    setProp(LocalPlayer, 'CameraMode', Enum.CameraMode.Classic)
    
    local function onChar(ch)
        if not ch then return end
        local h = ch:WaitForChild('Humanoid', 5)
        if h then
            setProp(h, 'DisplayDistanceType', Enum.HumanoidDisplayDistanceType.Subject)
            setProp(h, 'HealthDisplayDistance', math.huge)
            setProp(h, 'NameDisplayDistance', math.huge)
        end
    end
    
    LocalPlayer.CharacterAdded:Connect(onChar)
    onChar(LocalPlayer.Character)
end

applyPlayerSettings()

-- ============================================
-- TELEPORT TAB
-- ============================================
local TPage = TeleportTab:Page("Teleport", "map-pin")
local TLeft = TPage:Section("🚀 Ke Player", "Left")
local TRight = TPage:Section("📍 Waypoint", "Right")

TLeft:TextBox("Nama Player", "PlayerName", "", function(txt)
    _G.targetPlayer = txt
end)

TLeft:Button("📡 Teleport", "Pindah ke player", function()
    if _G.targetPlayer then
        teleportToPlayer(_G.targetPlayer)
    end
end)

TLeft:TextBox("Place ID", "PlaceID", "", function(txt)
    _G.placeID = tonumber(txt)
end)

TLeft:Button("🌍 Teleport ke Game", "", function()
    if _G.placeID then
        teleportToPlace(_G.placeID)
    end
end)

TRight:Button("➕ Tambah Waypoint", "", function()
    if LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            table.insert(waypoints, root.CFrame)
            Library:Notification("Waypoint", string.format("Waypoint %d ditambahkan", #waypoints), 2)
        end
    end
end)

TRight:Button("🗑️ Hapus Semua", "", function()
    waypoints = {}
    Library:Notification("Waypoint", "Semua dihapus", 2)
end)

TRight:Slider("Kecepatan", "WPSpeed", 50, 500, 139, function(v)
    waypointSpeed = v
end)

TRight:Slider("Loop", "WPLoop", 1, 10, 1, function(v)
    waypointTimes = v
end)

TRight:Toggle("Shuttle", "WPShuttle", false, "Bolak-balik", function(v)
    waypointShuttle = v
end)

TRight:Button("🚀 Mulai", "", startWaypoints)

-- ============================================
-- CAMERA TAB
-- ============================================
local CPage = CameraTab:Page("Camera", "video")
local CLeft = CPage:Section("🎥 Freecam", "Left")
local CRight = CPage:Section("⚙ Info", "Right")

CLeft:Paragraph("Controls",
    "',' (koma) - Toggle\n" ..
    "Mouse Kiri + Gerak - Lihat\n" ..
    "WASD/E/Q - Gerak\n" ..
    "'[' - Sprint\n" ..
    "']' - Zoom In\n" ..
    "Scroll - Zoom Kamera")

CLeft:Button("🎥 Toggle Freecam", "", function()
    setFreecam(not freecamEnabled)
end)

CLeft:Slider("Normal Speed", "FCSpeed", 10, 200, 31, function(v)
    freecamSpeed = v
    freecamCurrentSpeed = v
end)

CLeft:Slider("Sprint Speed", "FCSprint", 50, 500, 211, function(v)
    freecamSprintSpeed = v
end)

CRight:Button("📍 Posisi Kamera", "", function()
    local cf = cam.CFrame
    local pos = cf.Position
    Library:Notification("Camera", string.format("X=%.1f Y=%.1f Z=%.1f", pos.X, pos.Y, pos.Z), 3)
end)

-- ============================================
-- REMOTE SPY TAB
-- ============================================
local SPage = SpyTab:Page("Remote Spy", "radio")
local SLeft = SPage:Section("🔍 Controls", "Left")
local SRight = SPage:Section("📋 Info", "Right")

SLeft:Button("▶️ Start Spy", "", startSpy)
SLeft:Button("⏹️ Stop Spy", "", stopSpy)

SRight:Paragraph("Info",
    "Remote Spy akan menampilkan:\n" ..
    "• Nama remote\n" ..
    "• Path lengkap\n" ..
    "• Argumen\n\n" ..
    "Hasil di console (F9)")

-- ============================================
-- ESP TAB
-- ============================================
local EPage = ESPTab:Page("ESP", "eye")
var ELeft = EPage:Section("👁️ ESP", "Left")
var ERight = EPage:Section("🎨 Info", "Right")

ELeft:Toggle("ESP Player", "ESPToggle", false, "", toggleESP)

ERight:Paragraph("Info",
    "• Nama player\n" ..
    "• Jarak realtime\n" ..
    "• Warna sesuai tim")

-- ============================================
-- PROTECTION TAB
-- ============================================
local PPage = ProtectTab:Page("Protection", "shield")
var PLeft = PPage:Section("🛡️ Anti", "Left")
var PRight = PPage:Section("⚙ Settings", "Right")

PLeft:Toggle("Anti-Kick", "AntiKick", false, "", toggleAntiKick)

PRight:Paragraph("Fitur",
    "• Anti Kick\n" ..
    "• Anti Destroy\n" ..
    "• Zoom tak terbatas\n" ..
    "• Name/Health selalu terlihat")

-- ============================================
-- UTILITY TAB
-- ============================================
local UPage = UtilityTab:Page("Utility", "settings")
var ULeft = UPage:Section("🛠 Tools", "Left")
var URight = UPage:Section("ℹ️ Info", "Right")

ULeft:Toggle("Anti AFK", "AntiAFK", false, "", function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

ULeft:Button("🔄 Rejoin", "", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

ULeft:Button("📍 Koordinat", "", function()
    if LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local p = root.Position
            Library:Notification("Posisi", string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 4)
        end
    end
end)

ULeft:Button("💀 Reset", "", function()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
end)

URight:Paragraph("XKID ULTIMATE v6.1",
    "✨ CLEAN VERSION\n" ..
    "✅ Tanpa Backdoor\n" ..
    "✅ Semua fitur aman\n" ..
    "✅ Lightweight")

-- ============================================
-- INIT
-- ============================================
Library:Notification("XKID ULTIMATE v6.1", "Clean version loaded! 🔥", 4)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   ✨ XKID ULTIMATE v6.1                 ║")
print("║   CLEAN VERSION - NO BACKDOOR           ║")
print("╚══════════════════════════════════════════╝")