--[[
WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]

-- XKID ULTIMATE MEGA HUB v6.0
-- Fitur: Teleport, Pathfinding, Freecam, Remote Spy, ESP, Anti-Kick, dan banyak lagi!

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
    "✨ XKID ULTIMATE v6.0", 
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
_G.RSpy_Settings = nil
_G.ESP_Settings = nil
_G.ESP_Objects = {}
_G.ESP_Events = {}
_G.zm_h = {}

-- ============================================
-- TELEPORT FUNCTIONS (DARI SCRIPT)
-- ============================================
local function teleport(id, instance)
    if instance then
        TeleportService:TeleportToPlaceInstance(id, instance)
    else
        TeleportService:Teleport(id)
    end
end

local function teleportToPlayer(pl_ref)
    local function infer_plr(pl_ref)
        local to_pl
        local lp = LocalPlayer
        if typeof(pl_ref) == 'string' then
            local min = math.huge
            for _, p in next, Players:GetPlayers() do
                if p ~= lp then
                    local nv = math.huge
                    local un = p.Name
                    local dn = p.DisplayName
                    
                    if un:find('^' .. pl_ref) then
                        nv = 1.0 * (#un - #pl_ref)
                    elseif dn:find('^' .. pl_ref) then
                        nv = 1.5 * (#dn - #pl_ref)
                    elseif un:lower():find('^' .. pl_ref:lower()) then
                        nv = 2.0 * (#un - #pl_ref)
                    elseif dn:lower():find('^' .. pl_ref:lower()) then
                        nv = 2.5 * (#dn - #pl_ref)
                    end
                    if nv < min then
                        to_pl = p
                        min = nv
                    end
                end
            end
            return to_pl
        else
            return pl_ref
        end
    end
    
    local to_pl = infer_plr(pl_ref)
    if not to_pl or not to_pl.Character then return end
    local hrp = to_pl.Character:FindFirstChild('HumanoidRootPart')
    local trs = to_pl.Character:FindFirstChild('Torso')
    local to_part = hrp or trs
    
    if LocalPlayer.Character and to_part then
        LocalPlayer.Character:PivotTo(to_part.CFrame)
        Library:Notification("Teleport", "Ke " .. to_pl.Name, 2)
    end
end

-- ============================================
-- PATHFINDING / WAYPOINT (RocketPropulsion)
-- ============================================
local function cleanup_path()
    if _G.fp_rp then
        _G.fp_rp:Abort()
        _G.fp_rp:Destroy()
        _G.fp_rp = nil
    end
    if _G.fp_bg then
        _G.fp_bg:Destroy()
        _G.fp_bg = nil
    end
    if _G.fp_tr then
        _G.fp_tr:Destroy()
        _G.fp_tr = nil
    end
end

local waypoints = {}
local waypointSpeed = 139
local waypointTimes = 1
local waypointDist = 13
local waypointShuttle = false

local function move_part(v, p)
    if typeof(v) == 'Vector3' then
        p.CFrame = CFrame.new(v)
    elseif typeof(v) == 'Instance' then
        if v:IsA('BasePart') then
            p.CFrame = v.CFrame
        elseif v:IsA('Model') then
            p.CFrame = v:GetPivot()
        end
    elseif typeof(v) == 'CFrame' then
        p.CFrame = v
    end
end

local function task_step(rp, p, dist)
    task.delay(0.25, function() rp.TargetRadius = tick() % 0.5 + dist end)
    rp.ReachedTarget:Wait()
end

local function step_waypoint(rp, p, v)
    if typeof(v) == 'table' then
        move_part(v[1], p)
        task_step(rp, p, waypointDist)
        rp:Abort()
        task.wait(v[2])
        rp:Fire()
    elseif typeof(v) == 'CFrame' then
        move_part(v, p)
        task_step(rp, p, waypointDist)
    end
end

local function loop_waypoints(rp, p)
    rp:Fire()
    local times = waypointTimes
    while rp.Parent do
        if times == 0 then break end
        for i = 1, #waypoints do
            step_waypoint(rp, p, waypoints[i])
        end
        times = times - 1
        if waypointShuttle then
            for i = #waypoints, 1, -1 do
                step_waypoint(rp, p, waypoints[i])
            end
        end
    end
    rp:Abort()
end

local function startWaypoints()
    cleanup_path()
    if #waypoints == 0 then
        Library:Notification("Error", "Tidak ada waypoint", 3)
        return
    end
    
    local ch = LocalPlayer.Character
    if not ch then return end
    
    local root = ch:FindFirstChildWhichIsA('Humanoid').RootPart
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
    task.wait()
    loop_waypoints(_G.fp_rp, _G.fp_tr)
    cleanup_path()
end

-- ============================================
-- FREECAM SYSTEM
-- ============================================
local freecamEnabled = false
local freecamSpeed = 31
local freecamSprintSpeed = 211
local freecamSensitivity = Vector2.new(1/128, 1/128)
local freecamMoveKeys = {
    [Enum.KeyCode.D] = Vector3.new(2, 0, 0),
    [Enum.KeyCode.A] = Vector3.new(-2, 0, 0),
    [Enum.KeyCode.S] = Vector3.new(0, 0, 2),
    [Enum.KeyCode.W] = Vector3.new(0, 0, -2),
    [Enum.KeyCode.E] = Vector3.new(0, 2, 0),
    [Enum.KeyCode.Q] = Vector3.new(0, -2, 0),
    [Enum.KeyCode.Right] = Vector3.new(1, 0, 0),
    [Enum.KeyCode.Left] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.Down] = Vector3.new(0, 0, 1),
    [Enum.KeyCode.Up] = Vector3.new(0, 0, -1),
    [Enum.KeyCode.PageUp] = Vector3.new(0, 1, 0),
    [Enum.KeyCode.PageDown] = Vector3.new(0, -1, 0),
}

local currMouseRot = Vector2.new(0, 0)
local prevMouseRot = currMouseRot
local button2Ref = Vector2.new(0, 0)
local button2Dn = false
local freecamKeysDn = {}
local freecamFov = 70
local freecamCurrentSpeed = freecamSpeed

local function setFreecamEnabled(state)
    if freecamEnabled == state then return end
    freecamEnabled = state
    if freecamEnabled then
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')
            if hum then hum.WalkSpeed = 0 end
        end
        Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        Library:Notification("Freecam", "ON (mouse look, wheel zoom)", 2)
    else
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')
            if hum then hum.WalkSpeed = 16 end
        end
        Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')
        Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        Library:Notification("Freecam", "OFF", 2)
    end
end

-- Freecam events
UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = Vector2.new(input.Delta.X, input.Delta.Y)
        currMouseRot = currMouseRot + d
    end
end)

UIS.InputBegan:Connect(function(i, processed)
    if processed then return end
    
    if i.KeyCode == Enum.KeyCode.Comma then -- ','
        setFreecamEnabled(not freecamEnabled)
    elseif freecamEnabled and i.UserInputType == Enum.UserInputType.MouseButton2 then
        button2Dn = true
        button2Ref = Vector2.new(UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y)
        UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    elseif freecamEnabled and i.KeyCode == Enum.KeyCode.LeftBracket then -- '['
        freecamCurrentSpeed = freecamSprintSpeed
    elseif freecamEnabled and i.KeyCode == Enum.KeyCode.RightBracket then -- ']'
        freecamFov = 20
    elseif freecamMoveKeys[i.KeyCode] then
        freecamKeysDn[i.KeyCode] = true
    end
end)

UIS.InputEnded:Connect(function(i, processed)
    if processed then return end
    
    if freecamEnabled and i.UserInputType == Enum.UserInputType.MouseButton2 then
        button2Dn = false
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    elseif freecamEnabled and i.KeyCode == Enum.KeyCode.LeftBracket then
        freecamCurrentSpeed = freecamSpeed
    elseif freecamEnabled and i.KeyCode == Enum.KeyCode.RightBracket then
        freecamFov = 70
    elseif freecamMoveKeys[i.KeyCode] then
        freecamKeysDn[i.KeyCode] = nil
    end
end)

-- Mouse wheel
UIS.WheelForward:Connect(function()
    if freecamEnabled then
        Workspace.CurrentCamera.CFrame = Workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -5)
    end
end)

UIS.WheelBackward:Connect(function()
    if freecamEnabled then
        Workspace.CurrentCamera.CFrame = Workspace.CurrentCamera.CFrame * CFrame.new(0, 0, 5)
    end
end)

-- Freecam render step
local function freecamCalcMove(keys, mult)
    local v = Vector3.new()
    for k, _ in pairs(keys) do
        v = v + (freecamMoveKeys[k] or Vector3.new())
    end
    return CFrame.new(v * mult)
end

RunService:BindToRenderStep("FreecamStep", Enum.RenderPriority.Camera.Value, function(dt)
    if not freecamEnabled then return end
    
    prevMouseRot = currMouseRot
    local ty = -prevMouseRot.Y * freecamSensitivity.Y
    local tx = -prevMouseRot.X * freecamSensitivity.X
    local eu = CFrame.fromEulerAnglesYXZ(ty, tx, 0)
    local mv = freecamCalcMove(freecamKeysDn, freecamCurrentSpeed * dt)
    
    Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position) * eu * mv
    Workspace.CurrentCamera.FieldOfView = freecamFov
    
    if button2Dn then
        UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        local rv = Vector2.new(UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y)
        currMouseRot = currMouseRot - (button2Ref - rv)
        button2Ref = rv
    end
end)

-- ============================================
-- REMOTE SPY (SEDERHANA)
-- ============================================
local spyActive = false
local spyConnections = {}

local function startRemoteSpy()
    if spyActive then
        Library:Notification("Remote Spy", "Sudah aktif", 2)
        return
    end
    
    spyActive = true
    Library:Notification("Remote Spy", "Mencari remote...", 3)
    
    local count = 0
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            count = count + 1
            local conn = v.OnClientEvent:Connect(function(...)
                local args = {...}
                print("\n📡 REMOTE:", v.Name)
                print("   Path:", v:GetFullName())
                print("   Args:", unpack(args))
            end)
            table.insert(spyConnections, conn)
        elseif v:IsA("RemoteFunction") then
            count = count + 1
            -- RemoteFunction lebih kompleks, kita skip dulu
        end
    end
    
    Library:Notification("Remote Spy", string.format("%d remote di-spy", count), 4)
end

local function stopRemoteSpy()
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
    
    local function onCharacterAdded(char)
        if not espEnabled then return end
        task.wait(0.5)
        
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if head and hrp then
            -- Billboard GUI
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
            nameLabel.Text = player.Name .. "\n" .. player.DisplayName
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
            
            -- Update jarak
            local conn = RunService.RenderStepped:Connect(function()
                if not bill or not bill.Parent then
                    conn:Disconnect()
                    return
                end
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    distLabel.Text = string.format("%.1f m", dist)
                end
            end)
            table.insert(espConnections, conn)
        end
    end
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
end

local function toggleESP(state)
    espEnabled = state
    
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                createESP(player)
            end
        end
        
        local conn = Players.PlayerAdded:Connect(createESP)
        table.insert(espConnections, conn)
        
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
-- ANTI-KICK / PROTECTION
-- ============================================
local antiKickActive = false
local antiKickConnections = {}

local function toggleAntiKick(state)
    antiKickActive = state
    
    if state then
        -- Block kick/destroy methods
        local mt = getrawmetatable(game)
        local old_namecall = mt.__namecall
        
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and (method == "Kick" or method == "kick" or method == "Destroy" or method == "destroy") then
                print("[ANTI-KICK] Blocked:", method)
                return
            end
            return old_namecall(self, ...)
        end)
        setreadonly(mt, true)
        
        Library:Notification("Anti-Kick", "Aktif", 2)
    else
        -- Restore original
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        mt.__namecall = nil
        setreadonly(mt, true)
        Library:Notification("Anti-Kick", "Mati", 2)
    end
end

-- ============================================
-- CAMERA MESSAGE PARSER
-- ============================================
_G.msg_cc = Workspace.CurrentCamera
_G.msg = function(m)
    print(m)
    local s = m:split(' ')
    if #s ~= 6 then return end
    for i, v in next, s do
        local n = tonumber(v)
        if not n then return end
        s[i] = n
    end
    local v1, v2, v3, v4, v5, v6 = unpack(s)
    _G.msg_cc.CFrame = CFrame.new(Vector3.new(v1, v2, v3), Vector3.new(v4, v5, v6))
end

-- ============================================
-- PLAYER SETTINGS (Zoom, Camera, etc)
-- ============================================
local function applyPlayerSettings()
    setmetatable(_G.zm_h, {__mode = "v"})
    
    local function setProp(o, prop, val)
        local k = prop .. math.random(100, 999)
        if _G.zm_h[k] then _G.zm_h[k]:Disconnect() end
        o[prop] = val
        _G.zm_h[k] = o:GetPropertyChangedSignal(prop):Connect(function()
            if o[prop] ~= val then o[prop] = val end
        end)
    end
    
    setProp(LocalPlayer, 'CameraMaxZoomDistance', 1e5)
    setProp(LocalPlayer, 'CameraMinZoomDistance', 0)
    setProp(LocalPlayer, 'CameraMode', Enum.CameraMode.Classic)
    setProp(LocalPlayer, 'DevComputerCameraMode', Enum.DevComputerCameraMovementMode.UserChoice)
    
    local function doChar(ch)
        if not ch then return end
        local h = ch:WaitForChild('Humanoid', 7)
        if not h then return end
        setProp(h, 'DisplayDistanceType', Enum.HumanoidDisplayDistanceType.Subject)
        setProp(h, 'HealthDisplayDistance', math.huge)
        setProp(h, 'NameDisplayDistance', math.huge)
    end
    
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(doChar)
    end)
    
    for _, p in next, Players:GetPlayers() do
        p.CharacterAdded:Connect(doChar)
        doChar(p.Character)
    end
end

-- Jalankan
applyPlayerSettings()

-- ============================================
-- TELEPORT TAB
-- ============================================
local TeleportPage = TeleportTab:Page("Teleport Tools", "map-pin")
local TeleportLeft = TeleportPage:Section("🚀 Teleport ke Player", "Left")
local TeleportRight = TeleportPage:Section("📍 Waypoints", "Right")

TeleportLeft:TextBox("Nama Player", "PlayerNameInput", "", function(txt)
    _G.targetPlayer = txt
end, "Masukkan nama player")

TeleportLeft:Button("📡 Teleport ke Player", "Pindah ke player", function()
    if _G.targetPlayer then
        teleportToPlayer(_G.targetPlayer)
    end
end)

TeleportLeft:TextBox("Place ID", "PlaceIDInput", "", function(txt)
    _G.placeID = tonumber(txt)
end, "Masukkan Place ID")

TeleportLeft:Button("🌍 Teleport ke Game", "Pindah ke game lain", function()
    if _G.placeID then
        teleport(_G.placeID)
    end
end)

TeleportRight:Paragraph("Waypoint Controls",
    "Tambahkan posisi sekarang sebagai waypoint\n" ..
    "Lalu jalankan untuk bergerak otomatis")

TeleportRight:Button("➕ Tambah Waypoint (Posisi Saat Ini)", "Simpan posisi", function()
    if LocalPlayer.Character then
        local pos = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if pos then
            table.insert(waypoints, pos.CFrame)
            Library:Notification("Waypoint", string.format("Waypoint %d ditambahkan", #waypoints), 2)
        end
    end
end)

TeleportRight:Button("🗑️ Hapus Semua Waypoint", "Reset waypoints", function()
    waypoints = {}
    Library:Notification("Waypoint", "Semua waypoint dihapus", 2)
end)

TeleportRight:Slider("Kecepatan", "WaypointSpeed", 50, 500, 139, function(val)
    waypointSpeed = val
end)

TeleportRight:Slider("Jumlah Loop", "WaypointTimes", 1, 10, 1, function(val)
    waypointTimes = val
end)

TeleportRight:Toggle("Shuttle Mode", "ShuttleToggle", false, "Bolak-balik", function(val)
    waypointShuttle = val
end)

TeleportRight:Button("🚀 Mulai Waypoint", "Jalankan path", startWaypoints)

-- ============================================
-- CAMERA TAB
-- ============================================
local CameraPage = CameraTab:Page("Camera Controls", "video")
local CameraLeft = CameraPage:Section("🎥 Freecam", "Left")
local CameraRight = CameraPage:Section("⚙ Settings", "Right")

CameraLeft:Paragraph("Freecam Controls",
    "',' (koma) - Toggle Freecam\n" ..
    "Mouse Kiri + Gerak - Lihat\n" ..
    "WASD/E/Q - Gerak\n" ..
    "'[' - Sprint (cepat)\n" ..
    "']' - Zoom In (FOV)\n" ..
    "Scroll - Zoom Kamera")

CameraLeft:Button("🎥 Toggle Freecam", "Aktifkan/Matikan freecam", function()
    setFreecamEnabled(not freecamEnabled)
end)

CameraLeft:Slider("Kecepatan Normal", "FreecamSpeed", 10, 200, 31, function(val)
    freecamSpeed = val
    freecamCurrentSpeed = val
end)

CameraLeft:Slider("Kecepatan Sprint", "FreecamSprint", 50, 500, 211, function(val)
    freecamSprintSpeed = val
end)

CameraRight:TextBox("Camera CFrame (x y z x y z)", "CameraInput", "", function(txt)
    _G.msg(txt)
end, "Contoh: 0 10 0 0 0 1")

CameraRight:Button("📷 Ambil CFrame Sekarang", "Copy posisi kamera", function()
    local cf = Workspace.CurrentCamera.CFrame
    local pos = cf.Position
    local look = cf.LookVector
    local str = string.format("%.1f %.1f %.1f %.1f %.1f %.1f", 
        pos.X, pos.Y, pos.Z, look.X, look.Y, look.Z)
    setclipboard and setclipboard(str)
    Library:Notification("CFrame", "Tersalin ke clipboard", 2)
end)

-- ============================================
-- REMOTE SPY TAB
-- ============================================
local SpyPage = SpyTab:Page("Remote Spy", "radio")
local SpyLeft = SpyPage:Section("🔍 Controls", "Left")
local SpyRight = SpyPage:Section("📋 Info", "Right")

SpyLeft:Button("🔍 Start Remote Spy", "Mulai spy remote event", startRemoteSpy)
SpyLeft:Button("⏹️ Stop Remote Spy", "Hentikan spy", stopRemoteSpy)

SpyRight:Paragraph("Remote Spy Info",
    "Remote Spy akan:\n" ..
    "• Menampilkan semua remote event\n" ..
    "• Menunjukkan argumen yang dikirim\n" ..
    "• Hasil di console (F9)\n\n" ..
    "Berguna untuk mencari celah exploit")

-- ============================================
-- ESP TAB
-- ============================================
local ESPPage = ESPTab:Page("ESP Tools", "eye")
local ESPLeft = ESPPage:Section("👁️ ESP Controls", "Left")
local ESPRight = ESPPage:Section("🎨 Info", "Right")

ESPLeft:Toggle("ESP Player", "ESPToggle", false, "Tampilkan nama & jarak player", toggleESP)

ESPRight:Paragraph("ESP Info",
    "• Menampilkan nama player\n" ..
    "• Menampilkan jarak\n" ..
    "• Warna sesuai tim\n" ..
    "• Update realtime")

-- ============================================
-- PROTECTION TAB
-- ============================================
local ProtectPage = ProtectTab:Page("Protection", "shield")
local ProtectLeft = ProtectPage:Section("🛡️ Anti", "Left")
local ProtectRight = ProtectPage:Section("⚙ Settings", "Right")

ProtectLeft:Toggle("Anti-Kick", "AntiKickToggle", false, "Cegah kick/destroy", toggleAntiKick)

ProtectLeft:Paragraph("Fitur Anti",
    "• Anti Kick\n" ..
    "• Anti Destroy\n" ..
    "• Anti Admin Kick\n" ..
    "• Zoom tak terbatas\n" ..
    "• Name/Health selalu terlihat")

-- ============================================
-- UTILITY TAB
-- ============================================
local UtilPage = UtilityTab:Page("Utility", "settings")
local UtilLeft = UtilPage:Section("🛠 Tools", "Left")
local UtilRight = UtilPage:Section("ℹ️ Info", "Right")

UtilLeft:Toggle("Anti AFK", "AntiAFKToggle", false, "Cegah disconnect", function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

UtilLeft:Button("🔄 Rejoin Server", "Koneksi ulang", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

UtilLeft:Button("📍 Koordinat Saya", "Lihat posisi", function()
    if LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local p = root.Position
            Library:Notification("Posisi", string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 5)
        end
    end
end)

UtilLeft:Button("💀 Reset Character", "Mati lalu respawn", function()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
end)

UtilRight:Paragraph("XKID ULTIMATE v6.0",
    "✨ Fitur Lengkap:\n" ..
    "🚀 Teleport ke Player/Game\n" ..
    "📍 Waypoint Pathfinding\n" ..
    "🎥 Freecam + Sprint\n" ..
    "🔍 Remote Spy\n" ..
    "👁️ ESP Player\n" ..
    "🛡️ Anti-Kick\n" ..
    "⚙ Utility Tools\n\n" ..
    "By XKID | All-in-One")

-- ============================================
-- INIT
-- ============================================
Library:Notification("XKID ULTIMATE v6.0", "All features loaded! 🔥", 5)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   ✨ XKID ULTIMATE v6.0                 ║")
print("║   Teleport · Freecam · Remote Spy · ESP ║")
print("║   All-in-One Mega Hub                    ║")
print("╚══════════════════════════════════════════╝")