--[[
  ╔══════════════════════════════════════════════════════╗
  ║   🚀  X K I D   R O C K E T   F L Y  v5.1  🚀     ║
  ║   XKID HUB  ✦  Aurora UI                           ║
  ║   Fix: Struktur kode benar · Semua fitur berfungsi  ║
  ╚══════════════════════════════════════════════════════╝

  FITUR:
  [1] Rocket Fly   — H=Toggle · G=Anchor · L=Fast · K=Slow
  [2] Teleport     — ke Player (Simple & Advanced) + ke Game
  [3] ESP          — BillboardGui nama player
  [4] Freecam      — `,` toggle · WASD/E/Q gerak
  [5] Remote Spy   — pantau RemoteEvent di console F9
  [6] Backdoor     — scan remote mencurigakan
  [7] Pathfinding  — waypoint + shuttle mode
  [8] Utility      — Anti AFK · Reset Char · Rejoin · TP Mouse

  CHANGELOG v5.1:
  [FIX] Semua fungsi didefinisikan SEBELUM dipanggil di UI
  [FIX] init_fly() dan setup_fly_events() urutan benar
  [FIX] Freecam tidak crash saat toggle
  [FIX] ESP cleanup proper saat toggle off
]]

-- ════════════════════════════════════════════════
--  LOAD AURORA UI
-- ════════════════════════════════════════════════
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════
local Players        = game:GetService("Players")
local Workspace      = game:GetService("Workspace")
local RS             = game:GetService("ReplicatedStorage")
local UIS            = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local VirtualUser    = game:GetService("VirtualUser")
local TeleportService= game:GetService("TeleportService")
local AssetService   = game:GetService("AssetService")
local LocalPlayer    = Players.LocalPlayer

-- ════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════
local Win = Library:Window(
    "🚀 XKID ROCKET FLY",
    "rocket",
    "v5.1 | H=Fly · G=Anchor · L=Fast · K=Slow",
    false
)

-- ════════════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════════════
Win:TabSection("🚀 ROCKET FLY")
local FlyTab      = Win:Tab("Rocket Fly",  "rocket")

Win:TabSection("🎯 TOOLS")
local TeleportTab = Win:Tab("Teleport",    "map-pin")
local ESPTab      = Win:Tab("ESP",         "eye")
local FreecamTab  = Win:Tab("Freecam",     "video")

Win:TabSection("🔍 ADVANCED")
local SpyTab      = Win:Tab("Remote Spy",  "radio")
local BackdoorTab = Win:Tab("Backdoor",    "skull")
local UtilTab     = Win:Tab("Utility",     "heart")

-- ════════════════════════════════════════════════
--  HELPER
-- ════════════════════════════════════════════════
local function getChar()  return LocalPlayer.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ════════════════════════════════════════════════
--  ① ROCKET FLY SYSTEM
-- ════════════════════════════════════════════════
local SPEED         = 127
local REL_TO_CHAR   = false
local MAX_TORQUE_RP = 1e4
local THRUST_P      = 1e5
local MAX_THRUST    = 5e5
local MAX_TORQUE_BG = 3e4
local THRUST_D      = math.huge
local TURN_D        = 2e2

local keys_dn  = {}
local flying   = false
local enabled  = false
local move_dir = Vector3.new()
local humanoidFly, parentFly
local ms = LocalPlayer:GetMouse()

_G.fly_evts = _G.fly_evts or {}
_G.fly_rp   = nil
_G.fly_bg   = nil
_G.fly_pt   = nil

local FLYK = Enum.KeyCode.H
local ANCK = Enum.KeyCode.G
local FSTK = Enum.KeyCode.L
local SLWK = Enum.KeyCode.K

local MVKS = {
    [Enum.KeyCode.D]        = Vector3.new( 1, 0,  0),
    [Enum.KeyCode.A]        = Vector3.new(-1, 0,  0),
    [Enum.KeyCode.S]        = Vector3.new( 0, 0,  1),
    [Enum.KeyCode.W]        = Vector3.new( 0, 0, -1),
    [Enum.KeyCode.E]        = Vector3.new( 0, 1,  0),
    [Enum.KeyCode.Q]        = Vector3.new( 0,-1,  0),
    [Enum.KeyCode.Right]    = Vector3.new( 1, 0,  0),
    [Enum.KeyCode.Left]     = Vector3.new(-1, 0,  0),
    [Enum.KeyCode.Down]     = Vector3.new( 0, 0,  1),
    [Enum.KeyCode.Up]       = Vector3.new( 0, 0, -1),
    [Enum.KeyCode.PageUp]   = Vector3.new( 0, 1,  0),
    [Enum.KeyCode.PageDown] = Vector3.new( 0,-1,  0),
}

local function fly_dir()
    if REL_TO_CHAR and parentFly then
        return CFrame.new(Vector3.new(), parentFly.CFrame.LookVector) * move_dir
    else
        local front = Workspace.CurrentCamera:ScreenPointToRay(ms.X, ms.Y).Direction
        return CFrame.new(Vector3.new(), front) * move_dir
    end
end

local function init_fly()
    local ch = getChar(); if not ch then return end
    humanoidFly = ch:FindFirstChildOfClass("Humanoid"); if not humanoidFly then return end
    parentFly   = humanoidFly.RootPart;                 if not parentFly   then return end

    if _G.fly_rp then pcall(function() _G.fly_rp:Destroy() end) end
    if _G.fly_bg then pcall(function() _G.fly_bg:Destroy() end) end
    if _G.fly_pt and _G.fly_pt.Parent then
        pcall(function() _G.fly_pt.Parent:Destroy() end)
    end

    _G.fly_bg = Instance.new("BodyGyro",       parentFly)
    _G.fly_rp = Instance.new("RocketPropulsion",parentFly)

    local md  = Instance.new("Model")
    _G.fly_pt = Instance.new("Part", md)
    md.Parent = _G.fly_pt

    _G.fly_rp.MaxTorque  = Vector3.new(MAX_TORQUE_RP, MAX_TORQUE_RP, MAX_TORQUE_RP)
    _G.fly_bg.MaxTorque  = Vector3.new()
    md.PrimaryPart       = _G.fly_pt
    _G.fly_pt.Anchored   = true
    _G.fly_pt.CanCollide = false
    _G.fly_pt.Transparency = 1
    _G.fly_rp.CartoonFactor = 1
    _G.fly_rp.Target    = _G.fly_pt
    _G.fly_rp.MaxSpeed  = SPEED
    _G.fly_rp.MaxThrust = MAX_THRUST
    _G.fly_rp.ThrustP   = THRUST_P
    _G.fly_rp.ThrustD   = THRUST_D
    _G.fly_rp.TurnP     = THRUST_P
    _G.fly_rp.TurnD     = TURN_D
    _G.fly_bg.P         = 3e4
    enabled = false
    print("[FLY v5.1] Initialized ✅")
end

local function setup_fly_events()
    for _, e in ipairs(_G.fly_evts) do pcall(function() e:Disconnect() end) end
    _G.fly_evts = {}

    -- Re-init on respawn
    table.insert(_G.fly_evts, LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1); init_fly()
    end))

    -- KeyDown
    table.insert(_G.fly_evts, UIS.InputBegan:Connect(function(i, p)
        if p then return end

        if i.KeyCode == FLYK then
            enabled = not enabled
            if enabled then
                if _G.fly_bg then _G.fly_bg.MaxTorque = Vector3.new(MAX_TORQUE_BG, 0, MAX_TORQUE_BG) end
                if _G.fly_rp then _G.fly_rp.MaxTorque = Vector3.new(MAX_TORQUE_RP, MAX_TORQUE_RP, MAX_TORQUE_RP) end
                Library:Notification("🚀 Fly", "ON  (H = toggle)", 2)
            else
                if _G.fly_bg then _G.fly_bg.MaxTorque = Vector3.new() end
                if _G.fly_rp then _G.fly_rp.MaxTorque = Vector3.new() end
                Library:Notification("🚀 Fly", "OFF", 2)
            end

        elseif i.KeyCode == ANCK and parentFly then
            parentFly.Anchored = not parentFly.Anchored
            Library:Notification("Anchor", parentFly.Anchored and "ON" or "OFF", 1)

        elseif i.KeyCode == FSTK and _G.fly_rp then
            SPEED = SPEED * 1.5
            _G.fly_rp.MaxSpeed = SPEED
            Library:Notification("Speed ⬆", string.format("%.0f", SPEED), 1)

        elseif i.KeyCode == SLWK and _G.fly_rp then
            SPEED = math.max(10, SPEED / 1.5)
            _G.fly_rp.MaxSpeed = SPEED
            Library:Notification("Speed ⬇", string.format("%.0f", SPEED), 1)

        elseif MVKS[i.KeyCode] and not keys_dn[i.KeyCode] then
            move_dir = move_dir + MVKS[i.KeyCode]
            keys_dn[i.KeyCode] = true
        end
    end))

    -- KeyUp
    table.insert(_G.fly_evts, UIS.InputEnded:Connect(function(i, p)
        if p then return end
        if MVKS[i.KeyCode] and keys_dn[i.KeyCode] then
            move_dir = move_dir - MVKS[i.KeyCode]
            keys_dn[i.KeyCode] = nil
        end
    end))

    -- RenderStepped
    table.insert(_G.fly_evts, RunService.RenderStepped:Connect(function()
        if not _G.fly_rp or not parentFly then return end
        local do_fly = enabled and move_dir.Magnitude > 0
        if flying ~= do_fly then
            flying = do_fly
            if humanoidFly then humanoidFly.AutoRotate = not do_fly end
            if not do_fly then
                parentFly.Velocity = Vector3.new()
                _G.fly_rp:Abort()
                return
            end
            _G.fly_rp:Fire()
        end
        if _G.fly_pt then
            _G.fly_pt.Position = parentFly.Position + 10000 * fly_dir()
        end
    end))
end

-- ════════════════════════════════════════════════
--  ② ESP
-- ════════════════════════════════════════════════
local espEnabled = false
local espObjects  = {}
local espConns    = {}

local function clearESP()
    for _, obj in ipairs(espObjects) do pcall(function() obj:Destroy() end) end
    espObjects = {}
    for _, c in ipairs(espConns)   do pcall(function() c:Disconnect()  end) end
    espConns = {}
end

local function makeESPFor(player)
    if player == LocalPlayer then return end
    local function onChar(char)
        if not espEnabled then return end
        task.wait(0.5)
        local head = char:FindFirstChild("Head")
        if not head then return end
        local bill = Instance.new("BillboardGui")
        bill.Name           = "XKID_ESP"
        bill.Size           = UDim2.new(0, 160, 0, 40)
        bill.StudsOffset    = Vector3.new(0, 2.5, 0)
        bill.AlwaysOnTop    = true
        bill.Adornee        = head
        bill.Parent         = char
        local lbl = Instance.new("TextLabel", bill)
        lbl.Size                  = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency= 1
        lbl.Text                  = player.Name .. "\n" .. player.DisplayName
        lbl.TextColor3            = Color3.new(1,1,1)
        lbl.TextStrokeTransparency= 0.4
        lbl.TextScaled            = true
        lbl.Font                  = Enum.Font.GothamBold
        table.insert(espObjects, bill)
    end
    if player.Character then onChar(player.Character) end
    table.insert(espConns, player.CharacterAdded:Connect(onChar))
end

local function toggleESP(state)
    espEnabled = state
    clearESP()
    if state then
        for _, p in pairs(Players:GetPlayers()) do makeESPFor(p) end
        table.insert(espConns, Players.PlayerAdded:Connect(makeESPFor))
        Library:Notification("ESP", "ON", 2)
    else
        Library:Notification("ESP", "OFF", 2)
    end
end

-- ════════════════════════════════════════════════
--  ③ TELEPORT
-- ════════════════════════════════════════════════
local function teleportToPlayer(name)
    if not name or name == "" then
        Library:Notification("Error", "Masukkan nama player", 2); return
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():find(name:lower()) or p.DisplayName:lower():find(name:lower()) then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local root = getRoot()
                if root then
                    root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
                    Library:Notification("TP", "→ " .. p.Name, 2); return
                end
            end
        end
    end
    Library:Notification("Error", "Player tidak ditemukan", 2)
end

local function infer_plr(ref)
    if typeof(ref) ~= "string" then return ref end
    local best, min = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local nv = math.huge
            if p.Name:find("^"..ref)            then nv = 1.0*(#p.Name-#ref)
            elseif p.DisplayName:find("^"..ref) then nv = 1.5*(#p.DisplayName-#ref)
            elseif p.Name:lower():find("^"..ref:lower())            then nv = 2.0*(#p.Name-#ref)
            elseif p.DisplayName:lower():find("^"..ref:lower())     then nv = 2.5*(#p.DisplayName-#ref)
            end
            if nv < min then best=p; min=nv end
        end
    end
    return best
end

local function teleportToPlayerAdvanced(ref)
    local p = infer_plr(ref)
    if not p or not p.Character then
        Library:Notification("Error", "Player tidak ditemukan", 2); return
    end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
    if hrp and getChar() then
        getChar():PivotTo(hrp.CFrame * CFrame.new(0,3,0))
        Library:Notification("TP Advanced", "→ " .. p.Name, 2)
    end
end

local function teleportToGame(id)
    TeleportService:Teleport(id)
end

local function teleportToPlaceByIndex(idx)
    local pages = AssetService:GetGamePlacesAsync()
    local val = idx
    while true do
        for _, place in next, pages:GetCurrentPage() do
            val = val - 1
            if val == 0 then teleportToGame(place.PlaceId); return end
        end
        if pages.IsFinished then break end
        pages:AdvanceToNextPageAsync()
    end
    Library:Notification("Error", "Place tidak ditemukan", 2)
end

local function teleportToNextGame()
    local pages = AssetService:GetGamePlacesAsync()
    while true do
        local passed = false
        for _, place in next, pages:GetCurrentPage() do
            if game.PlaceId == place.PlaceId then passed = true
            elseif passed then teleportToGame(place.PlaceId); return end
        end
        if pages.IsFinished then break end
        pages:AdvanceToNextPageAsync()
    end
    Library:Notification("Error", "Tidak ada game berikutnya", 2)
end

-- ════════════════════════════════════════════════
--  ④ FREECAM
-- ════════════════════════════════════════════════
local freecamEnabled      = false
local freecamNormalSpeed  = 31
local freecamSprintSpeed  = 211
local freecamCurrentSpeed = freecamNormalSpeed
local freecamSensitivity  = Vector2.new(1/128, 1/128)
local freecamFov          = 70
local freecamCam          = Workspace.CurrentCamera
local freecamMouse        = LocalPlayer:GetMouse()
local freecamCurrRot      = Vector2.new()
local freecamPrevRot      = Vector2.new()
local freecamButton2Ref   = Vector2.new()
local freecamButton2Dn    = false
local freecamKeysDn       = {}

local WASD_MULT  = 2
local ARROW_MULT = 1
local freecamMoveKeys = {
    [Enum.KeyCode.D]        = Vector3.new( WASD_MULT,  0,          0),
    [Enum.KeyCode.A]        = Vector3.new(-WASD_MULT,  0,          0),
    [Enum.KeyCode.S]        = Vector3.new( 0,          0,  WASD_MULT),
    [Enum.KeyCode.W]        = Vector3.new( 0,          0, -WASD_MULT),
    [Enum.KeyCode.E]        = Vector3.new( 0,  WASD_MULT,          0),
    [Enum.KeyCode.Q]        = Vector3.new( 0, -WASD_MULT,          0),
    [Enum.KeyCode.Right]    = Vector3.new( ARROW_MULT, 0,          0),
    [Enum.KeyCode.Left]     = Vector3.new(-ARROW_MULT, 0,          0),
    [Enum.KeyCode.Down]     = Vector3.new( 0,          0, ARROW_MULT),
    [Enum.KeyCode.Up]       = Vector3.new( 0,          0,-ARROW_MULT),
    [Enum.KeyCode.PageUp]   = Vector3.new( 0, ARROW_MULT,          0),
    [Enum.KeyCode.PageDown] = Vector3.new( 0,-ARROW_MULT,          0),
}

local function setFreecamEnabled(state)
    if freecamEnabled == state then return end
    freecamEnabled = state
    local hum = getHum()
    if state then
        if hum then hum.WalkSpeed = 0 end
        freecamCam.CameraType = Enum.CameraType.Scriptable
        Library:Notification("Freecam", "ON  (',' = toggle)", 2)
    else
        if hum then
            hum.WalkSpeed = 16
            freecamCam.CameraSubject = hum
        end
        freecamCam.CameraType = Enum.CameraType.Custom
        Library:Notification("Freecam", "OFF", 2)
    end
end

-- Freecam input events
UIS.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement then
        freecamCurrRot = freecamCurrRot + Vector2.new(i.Delta.X, i.Delta.Y)
    end
end)

UIS.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.Comma then
        setFreecamEnabled(not freecamEnabled)
    elseif freecamEnabled then
        if freecamMoveKeys[i.KeyCode] then
            freecamKeysDn[i.KeyCode] = true
        elseif i.UserInputType == Enum.UserInputType.MouseButton2 then
            freecamButton2Dn  = true
            freecamButton2Ref = Vector2.new(freecamMouse.X, freecamMouse.Y)
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        elseif i.KeyCode == Enum.KeyCode.LeftBracket  then
            freecamCurrentSpeed = freecamSprintSpeed
        elseif i.KeyCode == Enum.KeyCode.RightBracket then
            freecamFov = 20
        end
    end
end)

UIS.InputEnded:Connect(function(i, p)
    if p then return end
    if freecamEnabled then
        if freecamMoveKeys[i.KeyCode] then
            freecamKeysDn[i.KeyCode] = nil
        elseif i.UserInputType == Enum.UserInputType.MouseButton2 then
            freecamButton2Dn  = false
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        elseif i.KeyCode == Enum.KeyCode.LeftBracket  then
            freecamCurrentSpeed = freecamNormalSpeed
        elseif i.KeyCode == Enum.KeyCode.RightBracket then
            freecamFov = 70
        end
    end
end)

UIS.WheelForward:Connect(function()
    if freecamEnabled then freecamCam.CFrame = freecamCam.CFrame * CFrame.new(0,0,-5) end
end)
UIS.WheelBackward:Connect(function()
    if freecamEnabled then freecamCam.CFrame = freecamCam.CFrame * CFrame.new(0,0, 5) end
end)

local function freecamCalcMove(keys, mult)
    local v = Vector3.new()
    for k in pairs(keys) do v = v + (freecamMoveKeys[k] or Vector3.new()) end
    return CFrame.new(v * mult)
end

RunService:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value, function(dt)
    if not freecamEnabled then return end
    freecamPrevRot = freecamCurrRot
    local eu = CFrame.fromEulerAnglesYXZ(
        -freecamPrevRot.Y * freecamSensitivity.Y,
        -freecamPrevRot.X * freecamSensitivity.X, 0)
    local mv = freecamCalcMove(freecamKeysDn, freecamCurrentSpeed * dt)
    freecamCam.CFrame       = CFrame.new(freecamCam.CFrame.Position) * eu * mv
    freecamCam.FieldOfView  = freecamFov
    if freecamButton2Dn then
        UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        local rv = Vector2.new(freecamMouse.X, freecamMouse.Y)
        freecamCurrRot   = freecamCurrRot - (freecamButton2Ref - rv)
        freecamButton2Ref = rv
    end
end)

-- ════════════════════════════════════════════════
--  ⑤ REMOTE SPY
-- ════════════════════════════════════════════════
local spyActive      = false
local spyConnections = {}

local function startRemoteSpy()
    if spyActive then Library:Notification("Remote Spy","Sudah aktif",2); return end
    spyActive = true
    local count = 0
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            count = count + 1
            local c = v.OnClientEvent:Connect(function(...)
                print("\n📡 [REMOTE] " .. v.Name)
                print("   Path : " .. v:GetFullName())
                local args = {...}
                for i, a in ipairs(args) do
                    print(string.format("   Arg%d : %s", i, tostring(a)))
                end
            end)
            table.insert(spyConnections, c)
        end
    end
    Library:Notification("Remote Spy", count.." remote di-spy | Lihat F9", 4)
end

local function stopRemoteSpy()
    spyActive = false
    for _, c in ipairs(spyConnections) do pcall(function() c:Disconnect() end) end
    spyConnections = {}
    Library:Notification("Remote Spy", "Dimatikan", 2)
end

-- ════════════════════════════════════════════════
--  ⑥ BACKDOOR SCANNER
-- ════════════════════════════════════════════════
local backdoorList     = {}
local selectedBackdoor = nil
local BD_PATTERNS      = {"Admin","Backdoor","Server","Execute","Run","Command","Control","Exploit","Load","Eval"}

local function scanBackdoor()
    backdoorList = {}
    print("\n" .. string.rep("=",50))
    print("🔍 BACKDOOR SCAN RESULTS")
    print(string.rep("=",50))
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            for _, pat in ipairs(BD_PATTERNS) do
                if v.Name:find(pat, 1, true) then
                    table.insert(backdoorList, { Name=v.Name, Type=v.ClassName, Object=v })
                    print(string.format("[✅] %-20s  %s", v.ClassName, v.Name))
                    break
                end
            end
        end
    end
    Library:Notification("Backdoor Scan", #backdoorList.." ditemukan | F9 untuk detail", 4)
    return backdoorList
end

local backdoorTemplates = {
    { Name="💰 Kasih Uang",    Args={"GiveMoney","AddCoins"},    Extra={999999} },
    { Name="👑 Jadi Admin",     Args={"MakeAdmin","SetAdmin"},    Extra={} },
    { Name="💎 Kasih Item",     Args={"GiveItem","AddItem"},      Extra={"Diamond",100} },
}

-- ════════════════════════════════════════════════
--  ⑦ PATHFINDING / WAYPOINT
-- ════════════════════════════════════════════════
local waypoints     = {}
local waypointSpeed = 139
local waypointTimes = 1
local waypointDist  = 13
local waypointSkip  = 0
local waypointShuttle = false

local function cleanup_path()
    if _G.fp_rp then _G.fp_rp:Abort(); _G.fp_rp:Destroy(); _G.fp_rp=nil end
    if _G.fp_bg then _G.fp_bg:Destroy(); _G.fp_bg=nil end
    if _G.fp_tr then _G.fp_tr:Destroy(); _G.fp_tr=nil end
end

local function move_part(v, p)
    if typeof(v)=="Vector3"  then p.CFrame = CFrame.new(v)
    elseif typeof(v)=="CFrame" then p.CFrame = v
    elseif typeof(v)=="Instance" then
        p.CFrame = v:IsA("BasePart") and v.CFrame or v:IsA("Model") and v:GetPivot() or p.CFrame
    end
end

local function task_step(rp, p, dist)
    task.delay(0.25, function() rp.TargetRadius = tick()%0.5 + dist end)
    rp.ReachedTarget:Wait()
end

local function step_waypoint(rp, p, v)
    if typeof(v)=="table" then
        move_part(v[1], p); task_step(rp,p,waypointDist)
        rp:Abort(); task.wait(v[2]); rp:Fire()
    elseif typeof(v)=="CFrame" then
        move_part(v,p); task_step(rp,p,waypointDist)
    end
end

local function startWaypoints()
    cleanup_path()
    if #waypoints==0 then Library:Notification("Error","Tidak ada waypoint",3); return end
    local ch=getChar(); if not ch then return end
    local hum=ch:FindFirstChildWhichIsA("Humanoid"); if not hum then return end
    local root=hum.RootPart; if not root then return end

    _G.fp_rp = Instance.new("RocketPropulsion", root)
    _G.fp_bg = Instance.new("BodyGyro",          root)
    _G.fp_tr = Instance.new("Part", _G.fp_rp)
    _G.fp_rp.MaxTorque   = Vector3.new(1e9,1e9,1e9)
    _G.fp_tr.Transparency= 1; _G.fp_tr.Anchored=true; _G.fp_tr.CanCollide=false
    _G.fp_rp.CartoonFactor=1
    _G.fp_rp.MaxSpeed    = waypointSpeed
    _G.fp_rp.MaxThrust   = 1e5
    _G.fp_rp.ThrustP     = 1e7
    _G.fp_rp.TurnP       = 5e3
    _G.fp_rp.TurnD       = 2e3
    _G.fp_rp.Target      = _G.fp_tr

    task.spawn(function()
        _G.fp_rp:Fire()
        local times = waypointTimes
        while _G.fp_rp and _G.fp_rp.Parent do
            if times==0 then break end
            for i=1+waypointSkip, #waypoints do
                if not _G.fp_rp or not _G.fp_rp.Parent then break end
                step_waypoint(_G.fp_rp, _G.fp_tr, waypoints[i])
            end
            times = times - 1
            if waypointShuttle then
                for i=#waypoints-waypointSkip, 1, -1 do
                    if not _G.fp_rp or not _G.fp_rp.Parent then break end
                    step_waypoint(_G.fp_rp, _G.fp_tr, waypoints[i])
                end
            end
        end
        cleanup_path()
        Library:Notification("Waypoint","Selesai",2)
    end)
end

-- ════════════════════════════════════════════════
--  ⑧ UTILITY
-- ════════════════════════════════════════════════
local lastCF = nil

local function savePosition()
    local root = getRoot()
    if root then lastCF = root.CFrame; return true end
    return false
end

local function resetCharacter()
    local ch = getChar(); if not ch then return end
    local savedCF = getRoot() and getRoot().CFrame or nil
    ch:BreakJoints()
    local conn
    conn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        conn:Disconnect()
        task.wait(1)
        local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
        if hrp and savedCF then
            hrp.CFrame = savedCF
            Library:Notification("Reset","Kembali ke posisi semula",2)
        end
    end)
end

-- ════════════════════════════════════════════════
--  INIT FLY (setelah semua fungsi didefinisikan)
-- ════════════════════════════════════════════════
task.spawn(function()
    task.wait(1)
    init_fly()
    setup_fly_events()
end)

-- ════════════════════════════════════════════════
--  BUILD UI
-- ════════════════════════════════════════════════

-- ── TAB: FLY ──────────────────────────────────
local FlyPage  = FlyTab:Page("Rocket Controls", "rocket")
local FlyLeft  = FlyPage:Section("⚙ Settings", "Left")
local FlyRight = FlyPage:Section("🎮 Keybinds", "Right")

FlyLeft:Slider("Kecepatan", "FlySpeedSlider", 10, 500, 127,
    function(v)
        SPEED = v
        if _G.fly_rp then _G.fly_rp.MaxSpeed = SPEED end
    end, "Kecepatan terbang awal")

FlyLeft:Toggle("Relatif ke Karakter", "RelCharToggle", false,
    "Gerak relatif karakter, bukan kamera",
    function(v) REL_TO_CHAR = v end)

FlyLeft:Button("🔄 Reset Fly System", "Inisialisasi ulang jika error",
    function()
        init_fly()
        Library:Notification("Fly Reset","System diinit ulang",2)
    end)

FlyRight:Paragraph("Keybinds",
    "H  — Toggle Fly ON/OFF\n"..
    "G  — Toggle Anchor\n"..
    "L  — Speed ×1.5\n"..
    "K  — Speed ÷1.5\n\n"..
    "WASD / E / Q — Gerak\n"..
    "Arrow + PageUp/Down — Alternatif")

-- ── TAB: TELEPORT ─────────────────────────────
local TpPage   = TeleportTab:Page("Teleport Tools", "map-pin")
local TpLeft   = TpPage:Section("👤 Ke Player", "Left")
local TpMiddle = TpPage:Section("🌍 Ke Game", "Middle")
local TpRight  = TpPage:Section("📌 Info", "Right")

local plrNameSimple = ""
TpLeft:TextBox("Nama Player", "TPNameSimple", "", function(v) plrNameSimple=v end,
    "Nama atau display name")
TpLeft:Button("📍 Teleport (Sederhana)", "TP ke player",
    function() teleportToPlayer(plrNameSimple) end)

local plrNameAdv = ""
TpLeft:TextBox("Nama Player (Advanced)", "TPNameAdv", "", function(v) plrNameAdv=v end,
    "Prefix nama player")
TpLeft:Button("📍 Teleport (Advanced)", "TP dengan algoritma pencocokan",
    function() teleportToPlayerAdvanced(plrNameAdv) end)

local placeIdx = 1
TpMiddle:Slider("Index Place", "PlaceIdxSlider", 1, 100, 1,
    function(v) placeIdx=v end, "Nomor urut game dalam universe")
TpMiddle:Button("🌍 TP ke Index", "Pindah ke game sesuai nomor urut",
    function() teleportToPlaceByIndex(placeIdx) end)
TpMiddle:Button("⏭ TP ke Game Berikutnya", "Pindah ke game selanjutnya",
    function() teleportToNextGame() end)

local placeIDInput = nil
TpMiddle:TextBox("Place ID", "PlaceIDBox", "", function(v) placeIDInput=tonumber(v) end,
    "Masukkan Place ID")
TpMiddle:Button("🌍 TP ke Place ID", "Pindah ke game via Place ID",
    function()
        if placeIDInput then teleportToGame(placeIDInput)
        else Library:Notification("Error","Masukkan Place ID dulu",2) end
    end)

TpRight:Paragraph("Info",
    "Sederhana: cari nama/display\n"..
    "Advanced: prefix matching\n"..
    "TP 3 stud di atas target\n\n"..
    "Index: nomor urut game\n"..
    "Place ID: ID unik game")

-- ── TAB: ESP ──────────────────────────────────
local ESPPage  = ESPTab:Page("ESP Tools", "eye")
local ESPLeft  = ESPPage:Section("👁 Controls", "Left")
local ESPRight = ESPPage:Section("ℹ Info", "Right")

ESPLeft:Toggle("ESP Player", "ESPToggle", false,
    "Tampilkan nama player di atas kepala",
    function(v) toggleESP(v) end)

ESPRight:Paragraph("Info",
    "Nama + display name\n"..
    "Warna putih, selalu di depan\n"..
    "Auto update saat respawn")

-- ── TAB: FREECAM ──────────────────────────────
local FCPage  = FreecamTab:Page("Freecam", "video")
local FCLeft  = FCPage:Section("🎥 Controls", "Left")
local FCRight = FCPage:Section("⚙ Settings", "Right")

FCLeft:Paragraph("Kontrol",
    "','  — Toggle Freecam\n"..
    "WASD / E / Q  — Gerak\n"..
    "Mouse Kanan + Gerak  — Lihat\n"..
    "'['  — Sprint\n"..
    "']'  — Zoom In\n"..
    "Scroll  — Maju/Mundur")

FCLeft:Button("🎥 Toggle Freecam", "Aktifkan/matikan freecam",
    function() setFreecamEnabled(not freecamEnabled) end)

FCRight:Slider("Kecepatan Normal", "FCSpeedNorm", 5, 200, 31,
    function(v) freecamNormalSpeed=v; if not freecamEnabled then freecamCurrentSpeed=v end end)
FCRight:Slider("Kecepatan Sprint", "FCSpeedSprint", 50, 500, 211,
    function(v) freecamSprintSpeed=v end)

-- ── TAB: REMOTE SPY ───────────────────────────
local SpyPage  = SpyTab:Page("Remote Spy", "radio")
local SpyLeft  = SpyPage:Section("🔍 Controls", "Left")
local SpyRight = SpyPage:Section("📋 Info", "Right")

SpyLeft:Button("▶ Start Remote Spy", "Mulai pantau remote events",
    function() startRemoteSpy() end)
SpyLeft:Button("⏹ Stop Remote Spy", "Hentikan pemantauan",
    function() stopRemoteSpy() end)

SpyRight:Paragraph("Info",
    "Pantau semua RemoteEvent\n"..
    "Tampil nama, path, argumen\n"..
    "Lihat hasil di console F9")

-- ── TAB: BACKDOOR ─────────────────────────────
local BDPage  = BackdoorTab:Page("Backdoor Tools", "skull")
local BDLeft  = BDPage:Section("🔍 Scanner", "Left")
local BDRight = BDPage:Section("💀 Execute", "Right")

BDLeft:Button("🔍 Scan Backdoor", "Cari remote mencurigakan",
    function() scanBackdoor() end)

BDLeft:Dropdown("Pilih Backdoor", "BDDropdown", {"Scan dulu!"},
    function(val)
        for _, bd in ipairs(backdoorList) do
            if bd.Name==val then
                selectedBackdoor=bd
                Library:Notification("Dipilih", bd.Name, 2); break
            end
        end
    end)

for _, tmpl in ipairs(backdoorTemplates) do
    local t = tmpl
    BDRight:Button(t.Name, "Execute template via backdoor terpilih",
        function()
            if not selectedBackdoor and #backdoorList>0 then selectedBackdoor=backdoorList[1] end
            if not selectedBackdoor then
                Library:Notification("Error","Scan & pilih backdoor dulu",3); return
            end
            pcall(function()
                local obj = selectedBackdoor.Object
                local args = {}
                for _, a in ipairs(t.Extra) do table.insert(args, a) end
                if obj:IsA("RemoteEvent") then obj:FireServer(table.unpack(args))
                else obj:InvokeServer(table.unpack(args)) end
                Library:Notification("Execute","Template dikirim",2)
            end)
        end)
end

-- ── TAB: UTILITY ──────────────────────────────
local UtilPage  = UtilTab:Page("Pathfinding", "map")
local PathLeft  = UtilPage:Section("📍 Waypoint", "Left")
local PathRight = UtilPage:Section("⚙ Settings", "Right")

PathLeft:Button("➕ Tambah Waypoint", "Simpan posisi saat ini sebagai waypoint",
    function()
        local root = getRoot()
        if root then
            table.insert(waypoints, root.CFrame)
            Library:Notification("Waypoint","#"..#waypoints.." ditambahkan",2)
        end
    end)
PathLeft:Button("🗑 Hapus Semua Waypoint", "Reset semua waypoint",
    function() waypoints={}; Library:Notification("Waypoint","Semua dihapus",2) end)
PathLeft:Button("🚀 Mulai Waypoint", "Jalankan path",
    function() startWaypoints() end)
PathLeft:Button("⏹ Stop Waypoint", "Hentikan path",
    function() cleanup_path(); Library:Notification("Waypoint","Dihentikan",2) end)

PathRight:Slider("Kecepatan", "PathSpeed", 20, 500, 139,
    function(v) waypointSpeed=v end)
PathRight:Slider("Jumlah Loop", "PathTimes", 1, 20, 1,
    function(v) waypointTimes=v end)
PathRight:Slider("Skip Awal", "PathSkip", 0, 10, 0,
    function(v) waypointSkip=v end)
PathRight:Toggle("Shuttle Mode", "PathShuttle", false, "Bolak-balik",
    function(v) waypointShuttle=v end)

-- ── Utility sub-page ──
local UtilSub  = UtilTab:Page("Utility", "heart")
local ULeft    = UtilSub:Section("🛠 Tools", "Left")
local URight   = UtilSub:Section("ℹ Info", "Right")

ULeft:Toggle("Anti AFK", "AntiAFKToggle", false, "Cegah disconnect otomatis",
    function(v)
        if v then
            LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            Library:Notification("Anti AFK","ON",2)
        else
            Library:Notification("Anti AFK","OFF (perlu re-toggle untuk aktif lagi)",3)
        end
    end)

ULeft:Button("📍 Teleport ke Mouse", "TP ke posisi kursor",
    function()
        local mouse = LocalPlayer:GetMouse()
        if mouse and mouse.Hit and getChar() then
            getChar():SetPrimaryPartCFrame(mouse.Hit + Vector3.new(0,3,0))
            Library:Notification("TP","Ke posisi mouse",2)
        end
    end)

ULeft:Button("💀 Reset Character", "Mati dan kembali ke posisi semula",
    function() resetCharacter() end)

ULeft:Button("📍 Simpan Posisi", "Simpan posisi saat ini",
    function()
        if savePosition() then Library:Notification("Posisi","Tersimpan",2) end
    end)

ULeft:Button("🔄 Rejoin Server", "Koneksi ulang ke server",
    function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

URight:Paragraph("Info",
    "Anti AFK: Cegah kick\n"..
    "TP Mouse: Pindah ke kursor\n"..
    "Reset: Mati & kembali ke posisi\n"..
    "Rejoin: Koneksi ulang")

-- ════════════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════════════
Library:Notification("🚀 XKID Rocket Fly v5.1", "H=Fly · G=Anchor · L=Fast · K=Slow", 5)
Library:Notification("✅ Semua Fitur Aktif", "Teleport · ESP · Freecam · Spy · Path", 5)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   🚀  XKID ROCKET FLY v5.1             ║")
print("║   H = Toggle Fly                        ║")
print("║   G = Toggle Anchor                     ║")
print("║   L = Speed Up  |  K = Speed Down       ║")
print("║   ',' = Toggle Freecam                  ║")
print("║   Fitur: Fly·TP·ESP·Cam·Spy·BD·Path     ║")
print("╚══════════════════════════════════════════╝")
