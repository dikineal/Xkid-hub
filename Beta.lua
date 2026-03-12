--[[
WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]

-- XKID ANDROID HUB v3.0 - STRUKTUR RAPI, PASTI JALAN
-- Semua fungsi didefinisikan dulu, baru UI dibangun

-- ============================================
-- SERVICES (didefinisikan di awal)
-- ============================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("AssetService")
local Lighting = game:GetService("Lighting")

-- ============================================
-- VARIABEL GLOBAL (default values)
-- ============================================
local flyEnabled = false
local flySpeed = 127
local flyKeys = {}
local flyMoveDir = Vector3.new()
local flyHumanoid, flyRootPart, flyRp, flyBg, flyPt
local flyEvents = {}

local espEnabled = false
local espObjects = {}

local freecamEnabled = false
local freecamSpeed = 31
local freecamSprintSpeed = 211
local freecamKeys = {}
local freecamMouse = LocalPlayer:GetMouse()
local freecamCam = Workspace.CurrentCamera
local freecamRot = Vector2.new(0, 0)

local backdoorList = {}
local selectedBackdoor = nil

local waypoints = {}
local waypointSpeed = 139
local waypointTimes = 1
local waypointShuttle = false
local fpRp, fpBg, fpTr = nil, nil, nil

local lastPosition = nil
local lastCFrame = nil

-- ============================================
-- FUNGSI-FUNGSI (didefinisikan semua di sini)
-- ============================================

-- -------------------- FLY SYSTEM --------------------
local function fly_init()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local root = humanoid.RootPart
    if not root then return end
    
    -- Bersihkan yang lama
    if flyRp then flyRp:Destroy() end
    if flyBg then flyBg:Destroy() end
    if flyPt and flyPt.Parent then flyPt.Parent:Destroy() end
    
    flyHumanoid = humanoid
    flyRootPart = root
    
    local rp_h = 1e4
    flyBg = Instance.new("BodyGyro", root)
    flyRp = Instance.new("RocketPropulsion", root)
    
    local md = Instance.new("Model")
    flyPt = Instance.new("Part", md)
    md.Parent = flyPt
    
    flyRp.MaxTorque = Vector3.new(rp_h, rp_h, rp_h)
    flyBg.MaxTorque = Vector3.new()
    md.PrimaryPart = flyPt
    flyPt.Anchored = true
    flyPt.CanCollide = false
    flyPt.Transparency = 1
    flyRp.CartoonFactor = 1
    flyRp.Target = flyPt
    flyRp.MaxSpeed = flySpeed
    flyRp.MaxThrust = 5e5
    flyRp.ThrustP = 1e5
    flyRp.ThrustD = math.huge
    flyRp.TurnP = 1e5
    flyRp.TurnD = 2e2
    flyBg.P = 3e4
    flyEnabled = false
end

local function fly_dir()
    if not flyRootPart then return CFrame.new() end
    local front = Workspace.CurrentCamera:ScreenPointToRay(freecamMouse.X, freecamMouse.Y).Direction
    return CFrame.new(Vector3.new(), front) * flyMoveDir
end

local function fly_toggle(state)
    flyEnabled = state
    if state then
        if flyBg then flyBg.MaxTorque = Vector3.new(3e4, 0, 3e4) end
        if flyRp then flyRp.MaxTorque = Vector3.new(1e4, 1e4, 1e4) end
    else
        if flyBg then flyBg.MaxTorque = Vector3.new() end
        if flyRp then flyRp.MaxTorque = Vector3.new() end
        if flyRp then flyRp:Abort() end
    end
end

local function fly_update(dt)
    if not flyEnabled or not flyRp or not flyRootPart then return end
    local move = Vector3.new()
    if flyKeys.W then move = move + Vector3.new(0,0,-1) end
    if flyKeys.S then move = move + Vector3.new(0,0,1) end
    if flyKeys.A then move = move + Vector3.new(-1,0,0) end
    if flyKeys.D then move = move + Vector3.new(1,0,0) end
    if flyKeys.E then move = move + Vector3.new(0,1,0) end
    if flyKeys.Q then move = move + Vector3.new(0,-1,0) end
    flyMoveDir = move
    
    local doFly = flyEnabled and move.Magnitude > 0
    if flyRp.Parent then
        if doFly then
            flyRp:Fire()
            if flyPt then
                flyPt.Position = flyRootPart.Position + 10000 * fly_dir()
            end
        else
            flyRp:Abort()
        end
    end
end

-- Setup fly events
local function fly_setup_events()
    -- Bersihkan event lama
    for _, e in ipairs(flyEvents) do e:Disconnect() end
    flyEvents = {}
    
    -- Karakter spawn
    table.insert(flyEvents, LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        fly_init()
    end))
    
    -- Input
    table.insert(flyEvents, UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        local key = input.KeyCode
        if key == Enum.KeyCode.H then
            fly_toggle(not flyEnabled)
            Library:Notification("Fly", flyEnabled and "ON" or "OFF", 1)
        elseif key == Enum.KeyCode.G and flyRootPart then
            flyRootPart.Anchored = not flyRootPart.Anchored
            Library:Notification("Anchor", flyRootPart.Anchored and "ON" or "OFF", 1)
        elseif key == Enum.KeyCode.L and flyRp then
            flySpeed = flySpeed * 1.5
            flyRp.MaxSpeed = flySpeed
            Library:Notification("Speed+", string.format("%.1f", flySpeed), 1)
        elseif key == Enum.KeyCode.K and flyRp then
            flySpeed = flySpeed / 1.5
            flyRp.MaxSpeed = flySpeed
            Library:Notification("Speed-", string.format("%.1f", flySpeed), 1)
        elseif key == Enum.KeyCode.W then flyKeys.W = true
        elseif key == Enum.KeyCode.A then flyKeys.A = true
        elseif key == Enum.KeyCode.S then flyKeys.S = true
        elseif key == Enum.KeyCode.D then flyKeys.D = true
        elseif key == Enum.KeyCode.E then flyKeys.E = true
        elseif key == Enum.KeyCode.Q then flyKeys.Q = true
        end
    end))
    
    table.insert(flyEvents, UIS.InputEnded:Connect(function(input, processed)
        if processed then return end
        local key = input.KeyCode
        if key == Enum.KeyCode.W then flyKeys.W = false
        elseif key == Enum.KeyCode.A then flyKeys.A = false
        elseif key == Enum.KeyCode.S then flyKeys.S = false
        elseif key == Enum.KeyCode.D then flyKeys.D = false
        elseif key == Enum.KeyCode.E then flyKeys.E = false
        elseif key == Enum.KeyCode.Q then flyKeys.Q = false
        end
    end))
    
    -- Render step
    table.insert(flyEvents, RunService.RenderStepped:Connect(fly_update))
end

-- -------------------- TELEPORT FUNCTIONS --------------------
local function teleportToPlayer(name)
    if not name or name == "" then
        Library:Notification("Error", "Masukkan nama player", 2)
        return
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():find(name:lower()) or p.DisplayName:lower():find(name:lower()) then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local target = p.Character.HumanoidRootPart.Position
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(target.X, target.Y + 3, target.Z)
                    Library:Notification("Teleport", "Ke " .. p.Name, 2)
                end
                return
            end
        end
    end
    Library:Notification("Error", "Player tidak ditemukan", 2)
end

local function teleportToPlace(id)
    TeleportService:Teleport(id, LocalPlayer)
end

local function teleportToNextGame()
    local pages = AssetService:GetGamePlacesAsync()
    while true do
        local passed = false
        for _, place in pairs(pages:GetCurrentPage()) do
            if game.PlaceId == place.PlaceId then
                passed = true
            elseif passed then
                teleportToPlace(place.PlaceId)
                return
            end
        end
        if pages.IsFinished then break end
        pages:AdvanceToNextPageAsync()
    end
    Library:Notification("Error", "Tidak ada game berikutnya", 2)
end

-- -------------------- ESP FUNCTIONS --------------------
local function esp_toggle(state)
    espEnabled = state
    if state then
        -- Hapus ESP lama
        for _, obj in ipairs(espObjects) do
            pcall(function() obj:Destroy() end)
        end
        espObjects = {}
        
        -- Buat ESP baru
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local function onChar(char)
                    if not espEnabled then return end
                    task.wait(0.5)
                    local head = char:FindFirstChild("Head")
                    if head then
                        local bill = Instance.new("BillboardGui")
                        bill.Name = "XKID_ESP"
                        bill.Size = UDim2.new(0, 120, 0, 30)
                        bill.StudsOffset = Vector3.new(0, 2, 0)
                        bill.AlwaysOnTop = true
                        bill.Adornee = head
                        bill.Parent = char
                        
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1,0,1,0)
                        label.BackgroundTransparency = 1
                        label.Text = p.Name
                        label.TextColor3 = Color3.new(1,1,1)
                        label.TextStrokeTransparency = 0.5
                        label.TextScaled = true
                        label.Font = Enum.Font.GothamBold
                        label.Parent = bill
                        
                        table.insert(espObjects, bill)
                    end
                end
                if p.Character then onChar(p.Character) end
                p.CharacterAdded:Connect(onChar)
            end
        end
        Library:Notification("ESP", "Aktif", 2)
    else
        for _, obj in ipairs(espObjects) do
            pcall(function() obj:Destroy() end)
        end
        espObjects = {}
        Library:Notification("ESP", "Mati", 2)
    end
end

-- -------------------- FREECAM FUNCTIONS --------------------
local function freecam_toggle(state)
    freecamEnabled = state
    if state then
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 0 end
        end
        freecamCam.CameraType = Enum.CameraType.Scriptable
        Library:Notification("Freecam", "ON", 2)
    else
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 16
                freecamCam.CameraSubject = hum
            end
        end
        freecamCam.CameraType = Enum.CameraType.Custom
        Library:Notification("Freecam", "OFF", 2)
    end
end

-- Setup freecam events
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Comma then
        freecam_toggle(not freecamEnabled)
    elseif freecamEnabled then
        if input.KeyCode == Enum.KeyCode.W then freecamKeys.W = true end
        if input.KeyCode == Enum.KeyCode.A then freecamKeys.A = true end
        if input.KeyCode == Enum.KeyCode.S then freecamKeys.S = true end
        if input.KeyCode == Enum.KeyCode.D then freecamKeys.D = true end
        if input.KeyCode == Enum.KeyCode.E then freecamKeys.E = true end
        if input.KeyCode == Enum.KeyCode.Q then freecamKeys.Q = true end
        if input.KeyCode == Enum.KeyCode.LeftBracket then freecamSpeed = freecamSprintSpeed end
        if input.KeyCode == Enum.KeyCode.RightBracket then freecamCam.FieldOfView = 20 end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end
end)

UIS.InputEnded:Connect(function(input, processed)
    if processed then return end
    if freecamEnabled then
        if input.KeyCode == Enum.KeyCode.W then freecamKeys.W = false end
        if input.KeyCode == Enum.KeyCode.A then freecamKeys.A = false end
        if input.KeyCode == Enum.KeyCode.S then freecamKeys.S = false end
        if input.KeyCode == Enum.KeyCode.D then freecamKeys.D = false end
        if input.KeyCode == Enum.KeyCode.E then freecamKeys.E = false end
        if input.KeyCode == Enum.KeyCode.Q then freecamKeys.Q = false end
        if input.KeyCode == Enum.KeyCode.LeftBracket then freecamSpeed = 31 end
        if input.KeyCode == Enum.KeyCode.RightBracket then freecamCam.FieldOfView = 70 end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
end)

UIS.InputChanged:Connect(function(input)
    if freecamEnabled and input.UserInputType == Enum.UserInputType.MouseMovement then
        freecamRot = freecamRot + Vector2.new(input.Delta.X, input.Delta.Y)
    end
end)

UIS.WheelForward:Connect(function()
    if freecamEnabled then freecamCam.CFrame = freecamCam.CFrame * CFrame.new(0,0,-5) end
end)

UIS.WheelBackward:Connect(function()
    if freecamEnabled then freecamCam.CFrame = freecamCam.CFrame * CFrame.new(0,0,5) end
end)

RunService:BindToRenderStep("FreecamStep", Enum.RenderPriority.Camera.Value, function(dt)
    if not freecamEnabled then return end
    local rotX = -freecamRot.Y * (1/256)
    local rotY = -freecamRot.X * (1/256)
    local move = Vector3.new()
    if freecamKeys.W then move = move + freecamCam.CFrame.LookVector end
    if freecamKeys.S then move = move - freecamCam.CFrame.LookVector end
    if freecamKeys.A then move = move - freecamCam.CFrame.RightVector end
    if freecamKeys.D then move = move + freecamCam.CFrame.RightVector end
    if freecamKeys.E then move = move + Vector3.new(0,1,0) end
    if freecamKeys.Q then move = move - Vector3.new(0,1,0) end
    if move.Magnitude > 0 then
        freecamCam.CFrame = freecamCam.CFrame + move.Unit * freecamSpeed * dt
    end
    freecamCam.CFrame = CFrame.new(freecamCam.CFrame.Position) * CFrame.Angles(rotX, rotY, 0)
end)

-- -------------------- BACKDOOR SCAN --------------------
local function scanBackdoor()
    backdoorList = {}
    local patterns = {"Admin","Backdoor","Server","Execute","Run","Command","Control"}
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            for _, pat in ipairs(patterns) do
                if v.Name:find(pat,1,true) then
                    table.insert(backdoorList, {Name=v.Name, Object=v})
                    break
                end
            end
        end
    end
    Library:Notification("Backdoor", string.format("Ditemukan %d", #backdoorList), 3)
end

-- -------------------- UTILITY FUNCTIONS --------------------
local function savePosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        lastCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        lastPosition = lastCFrame.Position
        return true
    end
    return false
end

local function resetCharacter()
    if not LocalPlayer.Character then return end
    local saved = nil
    if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        saved = LocalPlayer.Character.HumanoidRootPart.CFrame
    end
    LocalPlayer.Character:BreakJoints()
    local conn
    conn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        conn:Disconnect()
        task.wait(1)
        local hrp = newChar:WaitForChild("HumanoidRootPart",5)
        if hrp and saved then
            hrp.CFrame = saved
        end
    end)
end

-- -------------------- WAYPOINT FUNCTIONS --------------------
local function waypoint_cleanup()
    if fpRp then fpRp:Destroy() end
    if fpBg then fpBg:Destroy() end
    if fpTr then fpTr:Destroy() end
    fpRp, fpBg, fpTr = nil, nil, nil
end

local function waypoint_start()
    waypoint_cleanup()
    if #waypoints == 0 then
        Library:Notification("Error", "Tidak ada waypoint", 2)
        return
    end
    local ch = LocalPlayer.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local root = hum.RootPart
    if not root then return end
    fpRp = Instance.new("RocketPropulsion", root)
    fpBg = Instance.new("BodyGyro", root)
    fpRp.MaxTorque = Vector3.new(1e9,1e9,1e9)
    fpTr = Instance.new("Part", fpRp)
    fpTr.Transparency = 1
    fpTr.Anchored = true
    fpTr.CanCollide = false
    fpRp.CartoonFactor = 1
    fpRp.MaxSpeed = waypointSpeed
    fpRp.MaxThrust = 1e5
    fpRp.ThrustP = 1e7
    fpRp.TurnP = 5e3
    fpRp.TurnD = 2e3
    fpRp.Target = fpTr
    fpRp:Fire()
    task.spawn(function()
        local times = waypointTimes
        while fpRp and fpRp.Parent do
            if times == 0 then break end
            for _, wp in ipairs(waypoints) do
                if typeof(wp) == "CFrame" then
                    fpTr.CFrame = wp
                elseif typeof(wp) == "Vector3" then
                    fpTr.CFrame = CFrame.new(wp)
                end
                task.wait(0.5)
                fpRp.ReachedTarget:Wait()
            end
            times = times - 1
            if waypointShuttle and fpRp then
                for i = #waypoints, 1, -1 do
                    local wp = waypoints[i]
                    if typeof(wp) == "CFrame" then
                        fpTr.CFrame = wp
                    elseif typeof(wp) == "Vector3" then
                        fpTr.CFrame = CFrame.new(wp)
                    end
                    task.wait(0.5)
                    fpRp.ReachedTarget:Wait()
                end
            end
        end
        waypoint_cleanup()
        Library:Notification("Waypoint", "Selesai", 2)
    end)
end

-- ============================================
-- INISIALISASI FLY (setelah fungsi didefinisikan)
-- ============================================
task.spawn(function()
    task.wait(1)
    fly_init()
    fly_setup_events()
end)

-- ============================================
-- LOAD AURORA UI (sekarang baru kita load)
-- ============================================
Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

-- ============================================
-- WINDOW UTAMA
-- ============================================
local Win = Library:Window(
    "📱 XKID ANDROID v3.0",
    "smartphone",
    "Struktur Rapi | Semua Fitur",
    false
)

-- ============================================
-- TAB MENU (7 TAB)
-- ============================================
Win:TabSection("🚀 FLY")
local FlyTab = Win:Tab("Fly", "rocket")

Win:TabSection("💀 BACKDOOR")
local BackdoorTab = Win:Tab("Backdoor", "skull")

Win:TabSection("🎯 TELEPORT")
local TeleportTab = Win:Tab("Teleport", "map-pin")

Win:TabSection("👁️ ESP")
local ESPTab = Win:Tab("ESP", "eye")

Win:TabSection("🎥 FREECAM")
local FreecamTab = Win:Tab("Freecam", "video")

Win:TabSection("📍 WAYPOINT")
local WaypointTab = Win:Tab("Waypoint", "map")

Win:TabSection("🎨 UTILITY")
local UtilTab = Win:Tab("Utility", "heart")

-- ============================================
-- FLY TAB
-- ============================================
local FlyPage = FlyTab:Page("Fly Controls", "rocket")
local FlySection = FlyPage:Section("🦅 Rocket Fly", "Left")

FlySection:Paragraph("Keybinds",
    "H - Toggle Fly\nG - Toggle Anchor\nL - Speed+\nK - Speed-\nWASD/E/Q - Gerak")

FlySection:Slider("Speed", "FlySpeed", 50, 500, 127, function(val)
    flySpeed = val
    if flyRp then flyRp.MaxSpeed = val end
end)

FlySection:Button("🔄 Reset Fly", "Reset system", function()
    fly_init()
    Library:Notification("Fly", "Reset", 2)
end)

-- ============================================
-- BACKDOOR TAB
-- ============================================
local BackdoorPage = BackdoorTab:Page("Backdoor Tools", "skull")
local BackdoorSection = BackdoorPage:Section("💀 Backdoor", "Left")

BackdoorSection:Button("🔍 Scan Backdoor", "Cari remote mencurigakan", function()
    scanBackdoor()
end)

BackdoorSection:Dropdown("Pilih Backdoor", "BackdoorDropdown", {"Scan dulu"}, function(val)
    for _, bd in ipairs(backdoorList) do
        if bd.Name == val then
            selectedBackdoor = bd
            Library:Notification("Dipilih", bd.Name, 1)
            break
        end
    end
end)

BackdoorSection:Button("💰 Kasih Uang (Template)", "Execute", function()
    if not selectedBackdoor then Library:Notification("Error", "Pilih backdoor dulu", 2) return end
    pcall(function()
        selectedBackdoor.Object:FireServer("print('Uang ditambah')")
    end)
end)

BackdoorSection:Button("👑 Jadi Admin (Template)", "Execute", function()
    if not selectedBackdoor then Library:Notification("Error", "Pilih backdoor dulu", 2) return end
    pcall(function()
        selectedBackdoor.Object:FireServer("game.Players.LocalPlayer:SetAttribute('Admin',true)")
    end)
end)

-- ============================================
-- TELEPORT TAB
-- ============================================
local TeleportPage = TeleportTab:Page("Teleport Tools", "map-pin")
local TeleportSection = TeleportPage:Section("📍 Teleport", "Left")

local playerInput = ""
TeleportSection:TextBox("Nama Player", "PlayerName", "", function(val)
    playerInput = val
end)

TeleportSection:Button("📡 Teleport ke Player", "", function()
    teleportToPlayer(playerInput)
end)

TeleportSection:Button("⏭️ Teleport ke Game Berikutnya", "", function()
    teleportToNextGame()
end)

TeleportSection:Button("🔄 Rejoin Server", "", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

-- ============================================
-- ESP TAB
-- ============================================
local ESPPage = ESPTab:Page("ESP Tools", "eye")
local ESPSection = ESPPage:Section("👁️ ESP", "Left")

ESPSection:Toggle("ESP Player", "ESPToggle", false, "Tampilkan nama player", function(state)
    esp_toggle(state)
end)

-- ============================================
-- FREECAM TAB
-- ============================================
local FreecamPage = FreecamTab:Page("Freecam", "video")
local FreecamSection = FreecamPage:Section("🎥 Freecam", "Left")

FreecamSection:Paragraph("Controls",
    "Koma (,) - Toggle\nWASD/E/Q - Gerak\n[ - Sprint\n] - Zoom\nMouse Kiri + Gerak - Lihat")

FreecamSection:Button("🎥 Toggle Freecam", "", function()
    freecam_toggle(not freecamEnabled)
end)

FreecamSection:Slider("Normal Speed", "FreecamSpeed", 10, 200, 31, function(val)
    freecamSpeed = val
end)

FreecamSection:Slider("Sprint Speed", "FreecamSprint", 50, 500, 211, function(val)
    freecamSprintSpeed = val
end)

-- ============================================
-- WAYPOINT TAB
-- ============================================
local WaypointPage = WaypointTab:Page("Waypoint", "map")
local WaypointSection = WaypointPage:Section("📍 Waypoint", "Left")

WaypointSection:Button("➕ Tambah Waypoint", "Simpan posisi saat ini", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = LocalPlayer.Character.HumanoidRootPart.Position
        table.insert(waypoints, CFrame.new(pos))
        Library:Notification("Waypoint", string.format("Waypoint %d ditambahkan", #waypoints), 2)
    end
end)

WaypointSection:Button("🗑️ Hapus Semua", "Reset", function()
    waypoints = {}
    Library:Notification("Waypoint", "Semua dihapus", 2)
end)

WaypointSection:Button("🚀 Mulai Waypoint", "Jalankan", function()
    waypoint_start()
end)

WaypointSection:Slider("Kecepatan", "WPSpeed", 50, 500, 139, function(val)
    waypointSpeed = val
end)

WaypointSection:Slider("Jumlah Loop", "WPLoop", 1, 10, 1, function(val)
    waypointTimes = val
end)

WaypointSection:Toggle("Shuttle Mode", "WPShuttle", false, "Bolak-balik", function(val)
    waypointShuttle = val
end)

-- ============================================
-- UTILITY TAB
-- ============================================
local UtilPage = UtilTab:Page("Utility", "heart")
local UtilSection = UtilPage:Section("🛠 Tools", "Left")

UtilSection:Toggle("Anti AFK", "AntiAFK", false, "Cegah disconnect", function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

UtilSection:Button("📍 Simpan Posisi", "", function()
    if savePosition() then
        Library:Notification("Posisi Tersimpan", "", 1)
    end
end)

UtilSection:Button("💀 Reset Character", "Mati dan kembali ke posisi semula", function()
    resetCharacter()
end)

UtilSection:Button("📍 Koordinat Saya", "", function()
    if LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local p = root.Position
            Library:Notification("Posisi", string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 4)
        end
    end
end)

-- ============================================
-- INITIALISASI AKHIR
-- ============================================
Library:Notification("XKID ANDROID v3.0", "Semua fitur siap!", 4)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   📱 XKID ANDROID v3.0                  ║")
print("║   Struktur rapi, semua fitur ada        ║")
print("╚══════════════════════════════════════════╝")