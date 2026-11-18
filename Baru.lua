
========================
      @WTF.XKID
        Script
========================
  💎 Dibuat oleh @WTF.XKID
  📱 Tiktok: @wtf.xkid
  💬 Discord: @4sharken
]]

local ERROR_NOTIFY_OK, ERROR_MSG = pcall(function()

repeat task.wait() until game:IsLoaded()

-- ============================================================================
-- 1. CENTRALIZED CLEANUP & ANTI-REEXECUTE ENGINE
-- ============================================================================
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

if getgenv()._XKID_CLEANUP then
    pcall(getgenv()._XKID_CLEANUP)
end

local function fullSystemCleanup()
    getgenv()._XKID_RUNNING = false

    -- Putus semua koneksi event yang terdaftar
    if getgenv()._XKID_CONNS then
        for _, conn in ipairs(getgenv()._XKID_CONNS) do
            pcall(function() conn:Disconnect() end)
        end
    end
    getgenv()._XKID_CONNS = {}

    -- Unbind semua RenderStep
    local renderBindings = {
        "XKID_MasterRender", "XKIDFreecam", "XKIDFly",
        "XKIDSpec", "XKIDSelfSpec", "XKIDShiftLock", "XKIDFreecamLock"
    }
    for _, name in ipairs(renderBindings) do
        pcall(function() RunService:UnbindFromRenderStep(name) end)
    end

    -- Bersihkan cache ESP & Drawing
    if getgenv()._XKID_ESP_CACHE then
        for _, c in pairs(getgenv()._XKID_ESP_CACHE) do
            pcall(function()
                if c.texts then c.texts:Remove() end
                if c.tracer then c.tracer:Remove() end
                if c.boxLines then
                    for _, l in ipairs(c.boxLines) do l:Remove() end
                end
                if c.hl then c.hl:Destroy() end
            end)
        end
    end
    getgenv()._XKID_ESP_CACHE = {}

    -- Hapus UI & Efek Lighting lama
    pcall(function()
        for _, v in ipairs(CoreGui:GetChildren()) do
            if v.Name == "WindUI" or v.Name == "XKID_FreecamUI" then
                v:Destroy()
            end
        end
        for _, v in ipairs(Lighting:GetChildren()) do
            if v.Name:find("_XKID_") then
                v:Destroy()
            end
        end
    end)

    -- Bersihkan BodyMovers sisa pada karakter
    local lp = game:GetService("Players").LocalPlayer
    if lp and lp.Character then
        for _, inst in ipairs(lp.Character:GetDescendants()) do
            if inst.Name:find("XKID_") then
                pcall(function() inst:Destroy() end)
            end
        end
    end

    collectgarbage("collect")
end

fullSystemCleanup()
getgenv()._XKID_CLEANUP = fullSystemCleanup
getgenv()._XKID_RUNNING = true
getgenv()._XKID_CONNS = {}

local function TrackC(conn)
    if conn then
        table.insert(getgenv()._XKID_CONNS, conn)
    end
    return conn
end

-- ============================================================================
-- 2. SERVICES & CROSS-PLATFORM DETECTION (ANDROID / PC)
-- ============================================================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local StatsService = game:GetService("Stats")
local TextChatService = game:GetService("TextChatService")
local MarketplaceService = game:GetService("MarketplaceService")

local VIM = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil
local VirtualUser = pcall(function() return game:GetService("VirtualUser") end) and game:GetService("VirtualUser") or nil

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local WindUI = (function()
    local s, r = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    if s then return r else error("Gagal memuat WindUI") end
end)()

local executor = {
    name = "Unknown",
    has_writefile = type(writefile) == "function",
    has_readfile = type(readfile) == "function",
    has_listfiles = type(listfiles) == "function",
    has_isfolder = type(isfolder) == "function",
    has_makefolder = type(makefolder) == "function",
}
pcall(function()
    executor.name = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"
end)

local function httpRequest(options)
    local rf = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request)
    if not rf then
        local ok, body = pcall(function() return HttpService:GetAsync(options.Url, true) end)
        return ok and { StatusCode = 200, Body = body, Success = true } or { StatusCode = 0, Body = "", Success = false }
    end
    return rf(options)
end

pcall(function() if setfpscap then setfpscap(120) end end)

local originalLighting = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    ExposureCompensation = Lighting.ExposureCompensation,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
}

local function notify(title, content, duration, icon)
    pcall(function()
        WindUI:Notify({ Title = title, Content = content, Duration = duration or 2, Icon = icon or "bell" })
    end)
end

-- ============================================================================
-- 3. CENTRALIZED STATE & HELPERS
-- ============================================================================
local State = {
    Move = { ws = 16, jp = 50, ncp = false, infJ = nil, flyS = 60 },
    Fly = { active = false, bv = nil, bg = nil, keys = {} },
    HardFling = { active = false, power = 10000, currentPower = 0, rampUpActive = false },
    Security = { afkActive = true, shiftLock = false, shiftLockGyro = nil },
    Freeze = { active = false, conn = nil, anchorBackup = nil, humBackup = nil },
    Cinema = { hideUI = false, cachedGuis = {} },
    Avatar = { isRefreshing = false },
    Utility = { chatLog = false, chatTargets = {}, chatHistory = {}, lastMsg = "", lastMsgTime = 0 },
    FilterSettings = {
        saturation = 0, contrast = 0, brightness = 0, exposure = 0,
        shade = 0, warmth = 0, vignette = 0, bloomI = 0, bloomS = 24,
        lightB = originalLighting.Brightness, clockTime = originalLighting.ClockTime
    },
    FilterSliders = {},
    SelfSpec = {
        active = false, mode = "Orbit 360", dist = 8, height = 3,
        orbitYaw = 0, orbitPitch = 20, origFov = 70, roll = 0,
        radius = 8, speed = 1, distanceMult = 1, heightOffset = 0,
        _crashInit = nil, _crashStartRadius = 8
    },
    ESP = {
        active = false, cache = getgenv()._XKID_ESP_CACHE, maxDrawDistance = 300,
        highlightMode = false,
        boxColor_N = Color3.fromRGB(255, 0, 0),
        boxColor_S = Color3.fromRGB(220, 20, 60),
        boxColor_G = Color3.fromRGB(255, 165, 0),
        tracerColor_N = Color3.fromRGB(255, 0, 0),
        tracerColor_S = Color3.fromRGB(220, 20, 60),
        tracerColor_G = Color3.fromRGB(255, 165, 0),
        nameColor = Color3.fromRGB(255, 255, 255)
    },
    Spec = { active = false, target = nil, mode = "third", dist = 8, origFov = 70, orbitYaw = 0, orbitPitch = 0, isSelf = false }
}

local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getCharRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
end
local function getDisplayNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.DisplayName) end
    end
    if #t == 0 then table.insert(t, "N/A") end
    return t
end
local function getDisplayNamesWithSelf()
    local t = { "[Self]" }
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.DisplayName) end
    end
    return t
end
local function findPlayerByDisplay(str)
    if str == "[Self]" then return LP end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.DisplayName == str or p.Name == str then return p end
    end
    return nil
end
local function formatTime(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    return h > 0 and string.format("%02d:%02d:%02d", h, m, s) or string.format("%02d:%02d", m, s)
end
local function isOnGround()
    local r = getRoot()
    if not r then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character }
    return workspace:Raycast(r.Position, Vector3.new(0, -5, 0), params) ~= nil
end

-- ============================================================================
-- 4. INDEPENDENT MODULES (ANTI-LEAK & LOW OVERHEAD)
-- ============================================================================

-- [A] ANTI AFK (HYBRID GHOST MODE - ZERO INTERRUPTION)
local AFKSystem = { active = true, mode = "Ghost", triggers = 0, lastInput = tick() }
local function resetAFKActivity() AFKSystem.lastInput = tick() end
TrackC(UserInputService.InputBegan:Connect(resetAFKActivity))
TrackC(UserInputService.InputChanged:Connect(resetAFKActivity))
TrackC(UserInputService.TouchStarted:Connect(resetAFKActivity))

local function triggerAntiAFK()
    if not AFKSystem.active then return end
    AFKSystem.triggers = AFKSystem.triggers + 1
    pcall(function()
        if AFKSystem.mode == "Ghost" and VIM and VIM.SendKeyEvent then
            VIM:SendKeyEvent(true, Enum.KeyCode.F24, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.F24, false, game)
        elseif VirtualUser then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end
    end)
end

TrackC(LP.Idled:Connect(function()
    if AFKSystem.active then triggerAntiAFK() end
end))

-- [B] NOCLIP
local noclipConn, savedCollision = nil, {}
local function SetNoclip(state)
    State.Move.ncp = state
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = LP.Character
    if state then
        savedCollision = {}
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then savedCollision[v] = v.CanCollide; v.CanCollide = false end
            end
        end
        noclipConn = TrackC(RunService.Stepped:Connect(function()
            local c = LP.Character
            if not c or not State.Move.ncp then return end
            for _, v in ipairs(c:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
            end
        end))
    else
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") and savedCollision[v] ~= nil then
                    v.CanCollide = savedCollision[v]
                end
            end
        end
        savedCollision = {}
    end
end

-- [C] FREEZE MODE
local function disableFreeze()
    State.Freeze.active = false
    if State.Freeze.conn then State.Freeze.conn:Disconnect(); State.Freeze.conn = nil end
    local hrp, hum = getRoot(), getHum()
    if hrp and State.Freeze.anchorBackup ~= nil then hrp.Anchored = State.Freeze.anchorBackup end
    if hum and State.Freeze.humBackup then
        hum.WalkSpeed = State.Freeze.humBackup.WalkSpeed
        hum.JumpPower = State.Freeze.humBackup.JumpPower
        hum.AutoRotate = State.Freeze.humBackup.AutoRotate
        for _, st in ipairs({ Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Physics, Enum.HumanoidStateType.PlatformStanding }) do
            pcall(function() hum:SetStateEnabled(st, true) end)
        end
    end
    State.Freeze.anchorBackup = nil
    State.Freeze.humBackup = nil
end

local function enableFreeze()
    local hrp, hum = getRoot(), getHum()
    if not hrp or not hum then return end
    State.Freeze.active = true
    State.Freeze.anchorBackup = hrp.Anchored
    State.Freeze.humBackup = { WalkSpeed = hum.WalkSpeed, JumpPower = hum.JumpPower, AutoRotate = hum.AutoRotate }
    hrp.Anchored = true
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hum.WalkSpeed = 0
    hum.JumpPower = 0
    hum.AutoRotate = false
    for _, st in ipairs({ Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Physics, Enum.HumanoidStateType.PlatformStanding }) do
        pcall(function() hum:SetStateEnabled(st, false) end)
    end
    if State.Freeze.conn then State.Freeze.conn:Disconnect() end
    State.Freeze.conn = TrackC(RunService.Heartbeat:Connect(function()
        if not State.Freeze.active then return end
        local r, h = getRoot(), getHum()
        if not r or not h then return end
        if not r.Anchored then r.Anchored = true end
        if r.AssemblyLinearVelocity.Magnitude > 0.1 then
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
        end
        if h.WalkSpeed ~= 0 then h.WalkSpeed = 0 end
        if h.JumpPower ~= 0 then h.JumpPower = 0 end
    end))
end

-- [D] SHIFT LOCK
local function toggleShiftLock(v)
    State.Security.shiftLock = v
    RunService:UnbindFromRenderStep("XKIDShiftLock")
    if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy(); State.Security.shiftLockGyro = nil end
    if v then
        local hrp = getRoot()
        if hrp then
            local gyro = Instance.new("BodyGyro", hrp)
            gyro.Name = "XKID_ShiftLockGyro"
            gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            gyro.P = 50000
            gyro.D = 1000
            State.Security.shiftLockGyro = gyro
        end
        RunService:BindToRenderStep("XKIDShiftLock", Enum.RenderPriority.Camera.Value + 2, function()
            if not State.Security.shiftLock then return end
            local r, g = getRoot(), State.Security.shiftLockGyro
            if r and g and g.Parent == r then
                local fl = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
                if fl.Magnitude > 0.01 then g.CFrame = CFrame.new(r.Position, r.Position + fl) end
            end
        end)
    end
    notify("Shift Lock", v and "ON" or "OFF", 1.5, v and "lock" or "unlock")
end

-- [E] CHARACTER RESPAWN HANDLER (SINGLE CONSOLIDATED LISTENER)
local pendingRefreshCF, pendingRefreshWS, pendingRefreshJP, pendingRefreshZoom = nil, 16, 50, 400
TrackC(LP.CharacterAdded:Connect(function(newChar)
    task.wait(0.3)
    local newHrp = newChar:FindFirstChild("HumanoidRootPart") or newChar:WaitForChild("HumanoidRootPart", 8)
    local newHum = newChar:FindFirstChildOfClass("Humanoid") or newChar:WaitForChild("Humanoid", 8)
    if not newHrp or not newHum then return end

    if State.Avatar.isRefreshing and pendingRefreshCF then
        repeat task.wait() until newHum.Health > 0 and newHrp:IsDescendantOf(workspace)
        newHrp.CFrame = pendingRefreshCF + Vector3.new(0, 4, 0)
        newHrp.AssemblyLinearVelocity = Vector3.zero
        newHrp.AssemblyAngularVelocity = Vector3.zero
        Camera.CameraSubject = newHum
        Camera.CameraType = Enum.CameraType.Custom
        pcall(function() LP.CameraMaxZoomDistance = pendingRefreshZoom end)
        State.Avatar.isRefreshing = false
        pendingRefreshCF = nil
        notify("Refresh", "Done", 2, "check-circle")
    end

    if State.Move.ws ~= 16 then newHum.WalkSpeed = State.Move.ws end
    if State.Move.jp ~= 50 then newHum.UseJumpPower = true; newHum.JumpPower = State.Move.jp end
    if State.Move.ncp then SetNoclip(true) end
    if State.Freeze.active then disableFreeze(); task.wait(0.2); enableFreeze() end
    if State.Security.shiftLock then toggleShiftLock(true) end
end))

local function refreshCharacter()
    if State.Avatar.isRefreshing then return end
    local char, hrp = LP.Character, getRoot()
    if not char or not hrp then notify("Error", "Character not found", 2, "circle-alert"); return end
    State.Avatar.isRefreshing = true
    pendingRefreshCF = hrp.CFrame
    pendingRefreshWS = State.Move.ws
    pendingRefreshJP = State.Move.jp
    pendingRefreshZoom = LP.CameraMaxZoomDistance
    notify("Refresh", "Reloading...", 1.5, "refresh-cw")
    pcall(function() char:BreakJoints() end)
    local waited = 0
    repeat task.wait(0.1); waited = waited + 0.1 until not LP.Character or waited > 2
    if LP.Character then pcall(function() LP.Character:Destroy() end); task.wait(0.3) end
    if not LP.Character then pcall(function() LP:LoadCharacter() end) end
    task.delay(10, function()
        if State.Avatar.isRefreshing then State.Avatar.isRefreshing = false; pendingRefreshCF = nil end
    end)
end

-- [F] FLY ENGINE (CROSS-PLATFORM)
local flyMoveTouch, flyMoveSt, flyJoy, flyConns, flyVel = nil, nil, Vector2.zero, {}, Vector3.zero
local function stopFlyCapture()
    for _, c in ipairs(flyConns) do pcall(function() c:Disconnect() end) end
    flyConns = {}; flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero; State.Fly.keys = {}
end
local function startFlyCapture()
    stopFlyCapture()
    local keys = {}
    table.insert(flyConns, TrackC(UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            keys[inp.KeyCode] = true
        elseif inp.UserInputType == Enum.UserInputType.Touch and inp.Position.X <= Camera.ViewportSize.X * 0.5 then
            if not flyMoveTouch then flyMoveTouch = inp; flyMoveSt = inp.Position end
        end
    end)))
    table.insert(flyConns, TrackC(UserInputService.TouchMoved:Connect(function(inp)
        if inp == flyMoveTouch and flyMoveSt then
            local dx, dy = inp.Position.X - flyMoveSt.X, inp.Position.Y - flyMoveSt.Y
            local function deadzone(v, d, m)
                if math.abs(v) < d then return 0 end
                return math.clamp((v - math.sign(v) * d) / (m - d), -1, 1)
            end
            flyJoy = Vector2.new(deadzone(dx, 20, 75), deadzone(dy, 20, 75))
        end
    end)))
    table.insert(flyConns, TrackC(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            keys[inp.KeyCode] = nil
        elseif inp == flyMoveTouch then
            flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero
        end
    end)))
    State.Fly.keys = keys
end

local function toggleFly(v)
    RunService:UnbindFromRenderStep("XKIDFly")
    stopFlyCapture()
    pcall(function() if State.Fly.bv then State.Fly.bv:Destroy() end end)
    pcall(function() if State.Fly.bg then State.Fly.bg:Destroy() end end)
    State.Fly.bv = nil; State.Fly.bg = nil; flyVel = Vector3.zero

    if not v then
        State.Fly.active = false
        local hum = getHum()
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            hum.WalkSpeed = State.Move.ws
            hum.AutoRotate = true
        end
        notify("Fly", "OFF", 1.5, "bird")
        return
    end

    local hrp, hum = getRoot(), getHum()
    if not hrp or not hum then return end
    State.Fly.active = true
    hum.PlatformStand = true
    hum.AutoRotate = false
    local bv = Instance.new("BodyVelocity", hrp); bv.Name = "XKID_FlyBV"; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    local bg = Instance.new("BodyGyro", hrp); bg.Name = "XKID_FlyBG"; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.P = 50000
    State.Fly.bv = bv; State.Fly.bg = bg
    startFlyCapture()
    notify("Fly", "ON", 2, "bird")

    RunService:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value + 1, function()
        if not State.Fly.active then return end
        local r = getRoot(); if not r then return end
        local camCF = Camera.CFrame
        local move = Vector3.zero
        local keys = State.Fly.keys

        if flyJoy.Magnitude > 0 then
            move = camCF.LookVector * (-flyJoy.Y) + camCF.RightVector * flyJoy.X
        else
            if keys[Enum.KeyCode.W] then move = move + camCF.LookVector end
            if keys[Enum.KeyCode.S] then move = move - camCF.LookVector end
            if keys[Enum.KeyCode.D] then move = move + camCF.RightVector end
            if keys[Enum.KeyCode.A] then move = move - camCF.RightVector end
            if keys[Enum.KeyCode.E] then move = move + Vector3.new(0, 1, 0) end
            if keys[Enum.KeyCode.Q] then move = move - Vector3.new(0, 1, 0) end
        end

        if move.Magnitude > 0 then
            flyVel = flyVel:Lerp(move.Unit * State.Move.flyS, 0.18)
        else
            flyVel = flyVel:Lerp(isOnGround() and Vector3.zero or Vector3.new(0, -0.5, 0), 0.12)
        end
        if bv.Parent then bv.Velocity = flyVel end
        if bg.Parent then bg.CFrame = CFrame.new(r.Position, r.Position + camCF.LookVector) end
    end)
end

-- [G] HARD FLING
local hardFlingConn, hardFlingBAV = nil, nil
local function stopHardFling()
    if hardFlingConn then hardFlingConn:Disconnect(); hardFlingConn = nil end
    if hardFlingBAV then hardFlingBAV:Destroy(); hardFlingBAV = nil end
    local r = getRoot()
    if r then pcall(function() r.AssemblyAngularVelocity = Vector3.zero; r.AssemblyLinearVelocity = Vector3.zero end) end
    State.HardFling.active = false
    notify("Hard Fling", "OFF", 1.5, "rotate-cw")
end
local function startHardFling()
    if State.HardFling.active then return end
    local hrp = getRoot(); if not hrp then return end
    State.HardFling.active = true
    SetNoclip(true)
    hardFlingBAV = Instance.new("BodyAngularVelocity", hrp)
    hardFlingBAV.Name = "XKID_FlingBAV"
    hardFlingBAV.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    hardFlingBAV.P = 100000
    local startT = tick()
    hardFlingConn = TrackC(RunService.Heartbeat:Connect(function()
        if not State.HardFling.active then return end
        local r = getRoot(); if not r then stopHardFling(); return end
        local mult = math.clamp((tick() - startT) / 1.5, 0, 1)
        if hardFlingBAV and hardFlingBAV.Parent then
            hardFlingBAV.AngularVelocity = Vector3.new(0, State.HardFling.power * mult, 0)
        end
    end))
    notify("Hard Fling", "ON", 2, "rotate-cw")
end

-- [H] SMART TELEPORT
local Teleport = { clickConn = nil, toolActive = false, tool = nil }
local function toggleSmartTP(v)
    if Teleport.clickConn then Teleport.clickConn:Disconnect(); Teleport.clickConn = nil end
    pcall(function() if Teleport.tool then Teleport.tool:Destroy(); Teleport.tool = nil end end)
    Teleport.toolActive = false
    if v then
        pcall(function()
            local t = Instance.new("Tool")
            t.Name = "XKID_TPTool"
            t.RequiresHandle = false
            t.Parent = LP.Backpack
            Teleport.tool = t
            t.Activated:Connect(function() Teleport.toolActive = not Teleport.toolActive end)
        end)
        Teleport.clickConn = TrackC(UserInputService.InputBegan:Connect(function(inp, gp)
            if gp or not Teleport.toolActive then return end
            if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                local hrp = getRoot()
                local m = LP:GetMouse()
                if hrp and m.Hit then
                    hrp.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3.5, 0))
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    Teleport.toolActive = false
                end
            end
        end))
    end
    notify("Smart TP", v and "ON" or "OFF", 1.5, "map-pin")
end

-- [I] ESP ENGINE (PRE-INITIALIZED CACHE + HIGHLIGHT CAP)
local function initPlayerCache(player)
    if player == LP or State.ESP.cache[player] then return end
    local cache = { texts = nil, tracer = nil, boxLines = {}, hl = nil, isSuspect = false, isGlitch = false, reason = "" }
    pcall(function()
        if Drawing then
            cache.texts = Drawing.new("Text")
            if cache.texts then cache.texts.Center = true; cache.texts.Outline = true; cache.texts.Font = 2; cache.texts.Size = 13; cache.texts.ZIndex = 2 end
            cache.tracer = Drawing.new("Line")
            if cache.tracer then cache.tracer.Thickness = 1.5; cache.tracer.ZIndex = 1 end
            for i = 1, 4 do
                local l = Drawing.new("Line")
                if l then l.Thickness = 1.5; l.ZIndex = 1; cache.boxLines[i] = l end
            end
        end
    end)
    State.ESP.cache[player] = cache
end
local function clearPlayerCache(player)
    local c = State.ESP.cache[player]; if not c then return end
    pcall(function() if c.texts then c.texts:Remove() end end)
    pcall(function() if c.tracer then c.tracer:Remove() end end)
    for _, l in ipairs(c.boxLines) do pcall(function() if l then l:Remove() end end) end
    pcall(function() if c.hl then c.hl:Destroy() end end)
    State.ESP.cache[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do initPlayerCache(p) end
TrackC(Players.PlayerAdded:Connect(initPlayerCache))
TrackC(Players.PlayerRemoving:Connect(clearPlayerCache))

local espsortedPlayers = {}
local function updateESPScan()
    if not State.ESP.active then return end
    local tempSorted = {}
    local myHrp = getCharRoot(LP.Character)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            initPlayerCache(p)
            local isSus, isGlitch, reason = false, false, ""
            for _, v in ipairs(p.Character:GetChildren()) do
                if v:IsA("BasePart") and (v.Size.X > 30 or v.Size.Y > 30 or v.Size.Z > 30) then
                    isSus = true; reason = "Map Blocker"; break
                elseif v:IsA("Accessory") then
                    local h = v:FindFirstChild("Handle")
                    if h and h:IsA("BasePart") then
                        if h.Size.Magnitude > 20 then isSus = true; reason = "Huge Hat"; break
                        elseif h.Size.Magnitude > 10 or (h.Transparency < 0.1 and h.Material == Enum.Material.Neon) then
                            isGlitch = true; reason = "Glitch Acc"
                        end
                    end
                end
            end
            local c = State.ESP.cache[p]
            if c then c.isSuspect = isSus; c.isGlitch = isGlitch; c.reason = reason end
            if myHrp then
                local hrp2 = getCharRoot(p.Character)
                local hum2 = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp2 and hum2 and hum2.Health > 0 then
                    local dist = (hrp2.Position - myHrp.Position).Magnitude
                    if dist <= State.ESP.maxDrawDistance then
                        table.insert(tempSorted, { p = p, hrp = hrp2, dist = dist, char = p.Character })
                    end
                end
            end
        end
    end
    table.sort(tempSorted, function(a, b) return a.dist < b.dist end)
    espsortedPlayers = tempSorted
end

-- [J] FREECAM, SPECTATOR & CINEMATIC DIRECTOR
local FC = { active = false, pos = Vector3.zero, pitchDeg = 0, yawDeg = 0, rollDeg = 0, speed = 3, sens = 0.25, origFov = 70, savedWS = 16, savedJP = 50 }
local I_CamVel, I_YawVel, I_PitchVel, I_RollVel, heightVelocity = Vector3.zero, 0, 0, 0, 0
local fcMoveTouch, fcMoveSt, fcJoy, fcRotTouch, fcRotLast, fcKeysHeld, fcConns = nil, nil, Vector2.zero, nil, nil, {}, {}
local FC_UI_Btns = { up = false, down = false, rollLeft = false, rollRight = false, zoomIn = false, zoomOut = false }
local FC_UI_Hidden, fcButtons = false, {}

local FCUI = Instance.new("ScreenGui")
FCUI.Name = "XKID_FreecamUI"; FCUI.ResetOnSpawn = false; FCUI.ZIndexBehavior = Enum.ZIndexBehavior.Global; FCUI.Enabled = false; FCUI.Parent = CoreGui

local function makeFCBtn(name, txt, pos, actionKey)
    local b = Instance.new("TextButton", FCUI)
    b.Name = name; b.Size = UDim2.new(0, 44, 0, 44); b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(15, 15, 15); b.BackgroundTransparency = 0.4
    b.Text = txt; b.TextColor3 = Color3.new(1, 1, 1); b.TextSize = 18; b.Font = Enum.Font.GothamBold; b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    local uis = Instance.new("UIStroke", b); uis.Color = Color3.fromRGB(220, 20, 60); uis.Thickness = 2; uis.Transparency = 0.3
    local function press(down) FC_UI_Btns[actionKey] = down; b.BackgroundTransparency = down and 0.05 or 0.4 end
    b.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then press(true) end end)
    b.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then press(false) end end)
    table.insert(fcButtons, b)
end
makeFCBtn("BtnRollL", "L", UDim2.new(1, -156, 0.5, -66), "rollLeft")
makeFCBtn("BtnRollR", "R", UDim2.new(1, -58, 0.5, -66), "rollRight")
makeFCBtn("BtnUp", "↑", UDim2.new(1, -107, 0.5, -110), "up")
makeFCBtn("BtnDown", "↓", UDim2.new(1, -107, 0.5, -22), "down")
makeFCBtn("BtnZIn", "+", UDim2.new(1, -156, 0.5, -22), "zoomIn")
makeFCBtn("BtnZOut", "-", UDim2.new(1, -58, 0.5, -22), "zoomOut")

local eyeBtn = Instance.new("TextButton", FCUI)
eyeBtn.Size = UDim2.new(0, 20, 0, 20); eyeBtn.Position = UDim2.new(1, -107, 0.5, -66)
eyeBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15); eyeBtn.BackgroundTransparency = 0.6
eyeBtn.Text = "👁"; eyeBtn.TextColor3 = Color3.new(1, 1, 1); eyeBtn.TextSize = 18; eyeBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", eyeBtn).CornerRadius = UDim.new(0, 10)
eyeBtn.MouseButton1Click:Connect(function()
    FC_UI_Hidden = not FC_UI_Hidden
    eyeBtn.Text = FC_UI_Hidden and "👁‍🗨" or "👁"
    for _, b in ipairs(fcButtons) do b.Visible = not FC_UI_Hidden end
end)

local function stopFreecamCapture()
    for _, c in ipairs(fcConns) do pcall(function() c:Disconnect() end) end
    fcConns = {}; fcKeysHeld = {}; FC._mr = false; UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end
local function startFreecamCapture()
    stopFreecamCapture()
    table.insert(fcConns, TrackC(UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        fcKeysHeld[inp.KeyCode] = true
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            FC._mr = true; UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            if inp.Position.X > Camera.ViewportSize.X * 0.5 then
                if not fcRotTouch then fcRotTouch = inp; fcRotLast = inp.Position end
            else
                if not fcMoveTouch then fcMoveTouch = inp; fcMoveSt = inp.Position; fcJoy = Vector2.zero end
            end
        end
    end)))
    table.insert(fcConns, TrackC(UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and FC._mr then
            I_YawVel = I_YawVel - inp.Delta.X * FC.sens * 120
            I_PitchVel = I_PitchVel - inp.Delta.Y * FC.sens * 120
        end
    end)))
    table.insert(fcConns, TrackC(UserInputService.TouchMoved:Connect(function(inp)
        if inp == fcRotTouch and fcRotLast then
            local dx, dy = inp.Position.X - fcRotLast.X, inp.Position.Y - fcRotLast.Y
            fcRotLast = inp.Position
            I_YawVel = I_YawVel - dx * FC.sens * 80
            I_PitchVel = I_PitchVel - dy * FC.sens * 80
        elseif inp == fcMoveTouch and fcMoveSt then
            local dx, dy = inp.Position.X - fcMoveSt.X, inp.Position.Y - fcMoveSt.Y
            local function ad(v, d, m) if math.abs(v) < d then return 0 end; return math.clamp((v - math.sign(v) * d) / (m - d), -1, 1) end
            fcJoy = Vector2.new(ad(dx, 15, 70), ad(dy, 15, 70))
        end
    end)))
    table.insert(fcConns, TrackC(UserInputService.InputEnded:Connect(function(inp)
        fcKeysHeld[inp.KeyCode] = false
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            FC._mr = false; UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        elseif inp == fcRotTouch then
            fcRotTouch = nil; fcRotLast = nil
        elseif inp == fcMoveTouch then
            fcMoveTouch = nil; fcMoveSt = nil; fcJoy = Vector2.zero
        end
    end)))
end

local function toggleFreecam(v)
    RunService:UnbindFromRenderStep("XKIDFreecam")
    stopFreecamCapture()
    if not v then
        FC.active = false
        local hrp, hum = getRoot(), getHum()
        if hrp then hrp.Anchored = false end
        if hum then hum.WalkSpeed = FC.savedWS; hum.JumpPower = FC.savedJP; hum.AutoRotate = true end
        Camera.CameraType = Enum.CameraType.Custom
        Camera.FieldOfView = FC.origFov
        FCUI.Enabled = false
        notify("Freecam", "OFF", 1.5, "video")
        return
    end

    if State.Fly.active then toggleFly(false) end
    if State.Security.shiftLock then toggleShiftLock(false) end
    FC.active = true
    local hrp, hum = getRoot(), getHum()
    if hrp then hrp.Anchored = true end
    if hum then FC.savedWS = hum.WalkSpeed; FC.savedJP = hum.JumpPower; hum.WalkSpeed = 0; hum.JumpPower = 0 end
    FC.pos = Camera.CFrame.Position
    FC.pitchDeg, FC.yawDeg, FC.rollDeg = 0, 0, 0
    FC.origFov = Camera.FieldOfView
    FCUI.Enabled = not State.Cinema.hideUI
    startFreecamCapture()
    notify("Freecam", "ON", 2, "video")

    RunService:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end
        Camera.CameraType = Enum.CameraType.Scriptable
        local safeDt = math.clamp(dt, 0.001, 0.05)
        I_YawVel = I_YawVel * math.max(0, 1 - safeDt * 14)
        I_PitchVel = I_PitchVel * math.max(0, 1 - safeDt * 14)
        FC.yawDeg = FC.yawDeg + I_YawVel * safeDt
        FC.pitchDeg = math.clamp(FC.pitchDeg + I_PitchVel * safeDt, -80, 80)

        local rollTarget = (FC_UI_Btns.rollLeft and -100) or (FC_UI_Btns.rollRight and 100) or 0
        I_RollVel = I_RollVel + (rollTarget - I_RollVel) * math.clamp(safeDt * 5, 0, 1)
        FC.rollDeg = math.clamp(FC.rollDeg + I_RollVel * safeDt, -100, 100)

        local camCF = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local joyX, joyY = fcJoy.X, fcJoy.Y
        if fcKeysHeld[Enum.KeyCode.W] then joyY = joyY - 1 end
        if fcKeysHeld[Enum.KeyCode.S] then joyY = joyY + 1 end
        if fcKeysHeld[Enum.KeyCode.D] then joyX = joyX + 1 end
        if fcKeysHeld[Enum.KeyCode.A] then joyX = joyX - 1 end

        local rawMove = Vector2.new(joyX, joyY)
        if rawMove.Magnitude > 1 then rawMove = rawMove.Unit end
        I_CamVel = I_CamVel:Lerp((camCF.LookVector * (-rawMove.Y) + camCF.RightVector * rawMove.X) * (FC.speed * 60), math.clamp(safeDt * 3.5, 0, 1))

        local hTarget = ((fcKeysHeld[Enum.KeyCode.E] or FC_UI_Btns.up) and FC.speed * 60) or ((fcKeysHeld[Enum.KeyCode.Q] or FC_UI_Btns.down) and -FC.speed * 60) or 0
        heightVelocity = (hTarget == 0) and heightVelocity * math.max(0, 1 - safeDt * 10) or heightVelocity + (hTarget - heightVelocity) * math.clamp(safeDt * 3, 0, 1)

        if FC_UI_Btns.zoomIn then Camera.FieldOfView = math.clamp(Camera.FieldOfView - 1.2, 10, 120) end
        if FC_UI_Btns.zoomOut then Camera.FieldOfView = math.clamp(Camera.FieldOfView + 1.2, 10, 120) end

        FC.pos = FC.pos + (I_CamVel + Vector3.new(0, heightVelocity, 0)) * safeDt
        Camera.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0) * CFrame.Angles(0, 0, math.rad(FC.rollDeg))
    end)
end

-- [K] SPECTATOR & CINEMATIC DIRECTOR
local SS = State.SelfSpec
local ssConns, ssPan, ssPinch, ssPinchD, ssTM = {}, Vector2.zero, {}, nil, nil
local function stopSSGesture()
    for _, c in ipairs(ssConns) do pcall(function() c:Disconnect() end) end
    ssConns = {}; ssPan = Vector2.zero; ssPinch = {}; ssPinchD = nil; ssTM = nil
end
local function startSSGesture()
    stopSSGesture()
    table.insert(ssConns, TrackC(UserInputService.InputBegan:Connect(function(inp, gp)
        if gp or not SS.active or inp.UserInputType ~= Enum.UserInputType.Touch then return end
        table.insert(ssPinch, inp); ssTM = #ssPinch == 1 and inp or nil
    end)))
    table.insert(ssConns, TrackC(UserInputService.InputChanged:Connect(function(inp)
        if not SS.active or inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if #ssPinch == 1 and inp == ssTM then
            ssPan = ssPan + Vector2.new(inp.Delta.X, inp.Delta.Y)
        elseif #ssPinch >= 2 then
            local d = (ssPinch[1].Position - ssPinch[2].Position).Magnitude
            if ssPinchD then
                local diff = d - ssPinchD
                Camera.FieldOfView = math.clamp(Camera.FieldOfView - diff * 0.15, 10, 120)
                SS.radius = math.clamp(SS.radius - diff * 0.03, 3, 30)
            end
            ssPinchD = d
        end
    end)))
    table.insert(ssConns, TrackC(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        for i, v in ipairs(ssPinch) do if v == inp then table.remove(ssPinch, i); break end end
        ssPinchD = nil; ssTM = #ssPinch == 1 and ssPinch[1] or nil
    end)))
end

local function toggleSelfSpec(v)
    RunService:UnbindFromRenderStep("XKIDSelfSpec")
    stopSSGesture()
    if not v then
        SS.active = false
        Camera.CameraType = Enum.CameraType.Custom
        Camera.FieldOfView = SS.origFov
        notify("Cinematic Director", "OFF", 1.5, "clapperboard")
        return
    end
    if FC.active then toggleFreecam(false) end
    SS.active = true; SS.origFov = Camera.FieldOfView; SS.orbitYaw = 0; SS.orbitPitch = 20
    startSSGesture()
    notify("Cinematic Director", "ON", 2, "clapperboard")
    RunService:BindToRenderStep("XKIDSelfSpec", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not SS.active then return end
        local targetHrp = getCharRoot(LP.Character); if not targetHrp then return end
        Camera.CameraType = Enum.CameraType.Scriptable
        local pan, sens = ssPan, isMobile and 0.2 or 0.3; ssPan = Vector2.zero
        local radius = (SS.radius or 8) * (SS.distanceMult or 1)
        local height = (SS.height or 3) + (SS.heightOffset or 0)
        local speed, mode = SS.speed or 1, SS.mode or "Orbit 360"

        if #ssPinch == 0 and pan.Magnitude < 0.01 then
            if mode == "Orbit 360" then SS.orbitYaw = SS.orbitYaw + dt * 45 * speed
            elseif mode == "Floating" then SS.orbitYaw = SS.orbitYaw + dt * 15 * speed; height = height + math.sin(tick() * 0.4 * speed) * 1.5
            elseif mode == "Hyperlapse" then SS.orbitYaw = SS.orbitYaw + dt * 120 * speed; radius = radius + math.sin(tick() * 1.5 * speed) * 2
            elseif mode == "FPV Drone" then SS.orbitYaw = SS.orbitYaw + dt * 50 * speed; radius = 4
            elseif mode == "Vertigo Effect" then SS.orbitYaw = SS.orbitYaw + dt * 20 * speed; Camera.FieldOfView = 70 + math.sin(tick() * 0.5) * 20 end
        end
        SS.orbitYaw = SS.orbitYaw + pan.X * sens
        SS.orbitPitch = math.clamp(SS.orbitPitch + pan.Y * sens, -85, 85)
        local targetFinal = targetHrp.Position + Vector3.new(0, height, 0)
        Camera.CFrame = CFrame.new((CFrame.new(targetFinal) * CFrame.Angles(0, math.rad(-SS.orbitYaw), 0) * CFrame.Angles(math.rad(-SS.orbitPitch), 0, 0) * CFrame.new(0, 0, radius)).Position, targetFinal)
    end)
end

-- [L] VISUAL FILTERS
local FILTER_PRESETS = {
    Mendung_HD = { tint = Color3.fromRGB(180,185,200), sat = -0.3, con = 0.1, bri = -0.15, bloomI = 0.05, bloomS = 24, time = 10, lightB = 0.7 },
    Cool_Blue_HD = { tint = Color3.fromRGB(180,200,255), sat = 0.1, con = 0.15, bri = 0.05, bloomI = 0.2, bloomS = 24, time = 12, lightB = 1.2 },
    Full_Bright_HD = { tint = Color3.new(1,1,1), sat = 0, con = 0, bri = 0, bloomI = 0, bloomS = 24, time = 12, lightB = 3, shadow = false, ambient = Color3.new(1,1,1), outdoor = Color3.new(1,1,1) },
    Senja = { tint = Color3.fromRGB(255,180,120), sat = 0.2, con = 0.1, bri = 0.05, bloomI = 0.5, bloomS = 40, time = 17.5, lightB = 1 },
    Cyberpunk = { tint = Color3.fromRGB(255,80,200), sat = 0.4, con = 0.3, bri = 0.05, bloomI = 0.8, bloomS = 40, time = 2, lightB = 1.5 },
    Reshade_RTX = { tint = Color3.fromRGB(210,215,235), sat = 0.25, con = 0.35, bri = 0.06, bloomI = 0.7, bloomS = 36, time = 14, lightB = 2.0, shadow = true, envSpecular = 1, envDiffuse = 1, atmosphere = true, sunRays = true },
}

local function resetFilterOnly()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v.Name:find("_XKID_") then v:Destroy() end
    end
    pcall(function()
        Lighting.EnvironmentSpecularScale = originalLighting.EnvironmentSpecularScale
        Lighting.EnvironmentDiffuseScale = originalLighting.EnvironmentDiffuseScale
    end)
end

local function applyFilter(filterName)
    resetFilterOnly()
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.Brightness = originalLighting.Brightness
    Lighting.Ambient = originalLighting.Ambient
    Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.ExposureCompensation = originalLighting.ExposureCompensation

    if filterName == "Default" then
        notify("Visuals", "Default (Original)", 1.5, "palette")
        return
    end
    local preset = FILTER_PRESETS[filterName:gsub(" ", "_")]
    if preset then
        Lighting.ClockTime = preset.time or 14
        Lighting.Brightness = preset.lightB or 1
        Lighting.GlobalShadows = preset.shadow ~= false
        if preset.ambient then Lighting.Ambient = preset.ambient end
        if preset.outdoor then Lighting.OutdoorAmbient = preset.outdoor end
        if preset.envSpecular then pcall(function() Lighting.EnvironmentSpecularScale = preset.envSpecular end) end
        if preset.envDiffuse then pcall(function() Lighting.EnvironmentDiffuseScale = preset.envDiffuse end) end
        if preset.atmosphere then
            local atmo = Instance.new("Atmosphere", Lighting); atmo.Name = "_XKID_ATMO"; atmo.Density = 0.3; atmo.Haze = 0.5
        end
        if preset.sunRays then
            local sr = Instance.new("SunRaysEffect", Lighting); sr.Name = "_XKID_RAYS"; sr.Intensity = 0.15; sr.Spread = 0.5
        end
        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Name = "_XKID_FILTER"; cc.TintColor = preset.tint; cc.Saturation = preset.sat or 0; cc.Contrast = preset.con or 0; cc.Brightness = preset.bri or 0
        if preset.bloomI and preset.bloomI > 0 then
            local b = Instance.new("BloomEffect", Lighting); b.Name = "_XKID_FILTER"; b.Intensity = preset.bloomI; b.Size = preset.bloomS or 24
        end
        notify("Visuals", filterName, 2, "palette")
    end
end

-- ============================================================================
-- 5. SINGLE CONSOLIDATED RENDER & SCHEDULER LOOP (LOW CPU / RAM)
-- ============================================================================
local START_TIME = os.time()
local sharedFPS, sharedPing, cachedMapName = 60, 0, "Loading..."
local frameCounter, lastSecTick, last10SecTick, last60SecTick = 0, tick(), tick(), tick()
local chatLogPanel, afkStatusParagraph, infoParagraph, FpsTag = nil, nil, nil, nil

-- Master RenderStep: FPS Counter & ESP Drawing
RunService:BindToRenderStep("XKID_MasterRender", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not getgenv()._XKID_RUNNING then return end
    if dt > 0 then sharedFPS = math.floor(1 / dt) end

    if not State.ESP.active then return end
    local myHrp = getCharRoot(LP.Character); if not myHrp then return end
    local vp = Camera.ViewportSize

    for _, c in pairs(State.ESP.cache) do
        pcall(function()
            if c.texts then c.texts.Visible = false end
            if c.tracer then c.tracer.Visible = false end
            for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end
            if c.hl then c.hl.Enabled = false end
        end)
    end

    local hlCount = 0
    for _, data in ipairs(espsortedPlayers) do
        local player, char, hrp, dist = data.p, data.char, data.hrp, data.dist
        local c = State.ESP.cache[player]; if not c then continue end
        local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position); if not onScreen then continue end

        local isSus, isGlitch = c.isSuspect, c.isGlitch
        local useHl = isSus or isGlitch or State.ESP.highlightMode
        local txt = string.format("%s\n[%dm]", player.DisplayName, math.floor(dist))
        if isSus or isGlitch then txt = txt .. "\n⚠ " .. c.reason end

        local cColor = isSus and State.ESP.boxColor_S or (isGlitch and State.ESP.boxColor_G or State.ESP.nameColor)
        local tColor = isSus and State.ESP.tracerColor_S or (isGlitch and State.ESP.tracerColor_G or State.ESP.tracerColor_N)
        local bColor = isSus and State.ESP.boxColor_S or (isGlitch and State.ESP.boxColor_G or State.ESP.boxColor_N)

        pcall(function()
            if c.texts then c.texts.Text = txt; c.texts.Color = cColor; c.texts.Position = Vector2.new(rootPos.X, rootPos.Y - 45); c.texts.Visible = true end
            if c.tracer then c.tracer.From = Vector2.new(vp.X / 2, vp.Y); c.tracer.To = Vector2.new(rootPos.X, rootPos.Y); c.tracer.Color = tColor; c.tracer.Visible = true end
        end)

        if useHl and hlCount < 30 then
            hlCount = hlCount + 1
            pcall(function()
                if not c.hl or c.hl.Parent ~= char then
                    if c.hl then c.hl:Destroy() end
                    c.hl = Instance.new("Highlight", char); c.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
                if c.hl then c.hl.FillColor = bColor; c.hl.OutlineColor = Color3.new(1, 1, 1); c.hl.Enabled = true end
            end)
        end
    end
end)

-- Master Heartbeat Scheduler (1s, 10s, 60s tasks in ONE connection)
TrackC(RunService.Heartbeat:Connect(function()
    if not getgenv()._XKID_RUNNING then return end
    local now = tick()

    -- Tugas per 1 detik: Ping, ESP Scan, UI Status
    if now - lastSecTick >= 1 then
        lastSecTick = now
        pcall(function()
            local item = StatsService.Network.ServerStatsItem["Data Ping"]
            if item then sharedPing = math.floor(item:GetValue()) end
        end)

        updateESPScan()

        if FpsTag and FpsTag.SetTitle then
            pcall(function() FpsTag:SetTitle("FPS: " .. sharedFPS .. " | Ping: " .. sharedPing .. "ms") end)
        end
        if afkStatusParagraph then
            pcall(function()
                afkStatusParagraph:SetDesc(string.format("Executor: %s\nAccount Age: %d days\nUserID: %d\nFPS: %d | Ping: %dms", executor.name, LP.AccountAge, LP.UserId, sharedFPS, sharedPing))
            end)
        end
        if infoParagraph then
            pcall(function()
                local uptime = formatTime(os.difftime(os.time(), START_TIME))
                local afkStatus = AFKSystem.active and ("✅ " .. AFKSystem.mode) or "❌ OFF"
                infoParagraph:SetDesc(string.format("⏳ Anti AFK: %s (Triggers: %d)\n⏱ Uptime: %s\n📱 Platform: %s | 🚀 %s\n🎮 Map: %s\n👥 Players: %d/%d", afkStatus, AFKSystem.triggers, uptime, (isMobile and "Android/Mobile" or "PC"), executor.name, cachedMapName, #Players:GetPlayers(), Players.MaxPlayers))
            end)
        end
        if chatLogPanel and State.Utility.chatLog then
            pcall(function()
                local t = table.concat(State.Utility.chatHistory, "\n")
                if #t > 2000 then t = t:sub(-2000) end
                chatLogPanel:SetDesc(#t > 0 and t or "Belum ada chat...")
            end)
        end
    end

    -- Tugas per 30 detik: Map Name & Proactive Anti-AFK Check
    if now - last10SecTick >= 30 then
        last10SecTick = now
        pcall(function()
            cachedMapName = MarketplaceService:GetProductInfo(game.PlaceId).Name
        end)
        if AFKSystem.active and (now - AFKSystem.lastInput >= 55) then
            triggerAntiAFK()
            AFKSystem.lastInput = now
        end
    end

    -- Tugas per 120 detik: Garbage Collection untuk RAM rendah
    if now - last60SecTick >= 120 then
        last60SecTick = now
        collectgarbage("collect")
    end
end))

-- ============================================================================
-- 6. WINDUI INTERFACE (CLEAN & NO VERSION TAGS)
-- ============================================================================
local Window = WindUI:CreateWindow({
    Title = "XKID_HUB", Icon = "bluetooth", Author = "@WTF.XKID", Folder = "XKIDHub",
    Size = isMobile and UDim2.fromOffset(360, 320) or UDim2.fromOffset(480, 400),
    Transparent = true, Theme = "Crimson", SideBarWidth = isMobile and 140 or 160,
    User = { Enabled = true, Anonymous = false },
})
pcall(function() WindUI:SetNotificationLower(true) end)
pcall(function() Window.User:SetDisplayName(LP.DisplayName); Window.User:SetUsername("@" .. LP.Name) end)
Window:EditOpenButton({
    Title = "WTF.XKID", Icon = "github", CornerRadius = UDim.new(1, 0),
    StrokeThickness = 2, StrokeColor = Color3.fromRGB(255, 70, 120),
    Enabled = true, Draggable = true, Scale = isMobile and 0.72 or 0.85
})
FpsTag = Window:Tag({ Title = "FPS: -- | Ping: --", Color = Color3.fromRGB(255, 215, 0), Icon = "activity" })

-- TAB: INFORMASI
local TabInfo = Window:Tab({ Title = "Informasi", Icon = "activity" })
afkStatusParagraph = TabInfo:Paragraph({
    Title = "YooWssp!!, " .. LP.DisplayName,
    Desc = "Loading stats...",
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=420&h=420",
    ImageSize = 70
})
infoParagraph = TabInfo:Paragraph({ Title = "💀 " .. LP.DisplayName, Desc = "Loading..." })
TabInfo:Section({ Title = "🔗 Discord", Icon = "message-circle", Box = true }):Button({
    Title = "Copy Discord Link", Desc = "discord.gg/bzumc2u96",
    Callback = function() pcall(function() setclipboard("https://discord.gg/bzumc2u96") end); notify("System", "Link copied", 2, "copy") end
})

-- TAB: CHARACTER
local TabChar = Window:Tab({ Title = "Character", Icon = "fingerprint" })
TabChar:Button({ Title = "Refresh Character 🔄", Desc = "Reload character safely", Callback = refreshCharacter })

local secMov = TabChar:Section({ Title = "Movement", Icon = "activity", Box = true })
secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end })
secMov:Toggle({ Title = "Infinite Jump", Default = false, Callback = function(v)
    if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end
    if v then
        State.Move.infJ = TrackC(UserInputService.JumpRequest:Connect(function()
            local h = getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end))
    end
    notify("Infinite Jump", v and "ON" or "OFF", 1.5, "arrow-big-up")
end })

local secAbi = TabChar:Section({ Title = "Abilities", Icon = "zap", Box = true })
secAbi:Toggle({ Title = "Fly", Default = false, Callback = toggleFly })
secAbi:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(v) State.Move.flyS = v end })
secAbi:Toggle({ Title = "NoClip", Default = false, Callback = function(v) SetNoclip(v); notify("NoClip", v and "ON" or "OFF", 1.5, "ghost") end })
secAbi:Toggle({ Title = "Freeze Mode (Statue)", Default = false, Callback = function(v) if v then enableFreeze() else disableFreeze() end; notify("Freeze Mode", v and "ON" or "OFF", 1.5, "snowflake") end })
secAbi:Toggle({ Title = "Force Shift Lock", Default = false, Callback = toggleShiftLock })
secAbi:Toggle({ Title = "Hard Fling", Default = false, Callback = function(v) if v then startHardFling() else stopHardFling() end end })
secAbi:Slider({ Title = "Fling Power", Step = 500, Value = { Min = 1000, Max = 50000, Default = 10000 }, Callback = function(v) State.HardFling.power = v end })

-- TAB: TELEPORT
local TabTP = Window:Tab({ Title = "Teleport", Icon = "map-pin-x-inside" })
TabTP:Section({ Title = "Direct Teleport", Icon = "map-pin", Box = true }):Toggle({ Title = "Smart TP", Desc = "Equip tool -> tap to TP", Default = false, Callback = toggleSmartTP })
local secTargetTP = TabTP:Section({ Title = "Target Teleport", Icon = "crosshair", Box = true })
local tpTarget = ""
secTargetTP:Input({ Title = "Search Player", Placeholder = "Type name...", Callback = function(v) tpTarget = v end })
secTargetTP:Button({ Title = "Execute TP", Callback = function()
    if tpTarget == "" then notify("Teleport", "Input target!", 2, "circle-alert"); return end
    local t = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (p.Name:lower():find(tpTarget:lower(), 1, true) or p.DisplayName:lower():find(tpTarget:lower(), 1, true)) then
            t = p; break
        end
    end
    if not t or not t.Character then notify("Teleport", "Invalid Target", 2, "circle-alert"); return end
    local thr, mhr = getCharRoot(t.Character), getRoot()
    if thr and mhr then mhr.CFrame = thr.CFrame * CFrame.new(0, 0, 3) + Vector3.new(0, 2, 0); notify("Teleport", t.DisplayName, 2, "crosshair") end
end })
local tpDropdown = secTargetTP:Dropdown({ Title = "Player List", Values = getDisplayNames(), Callback = function(v) tpTarget = tostring(v) end })
secTargetTP:Button({ Title = "Refresh List", Callback = function() pcall(function() tpDropdown:Refresh(getDisplayNames()) end); notify("Teleport", "List refreshed", 1.5, "map-pin") end })

-- TAB: CAMERA & VISUAL
local TabCamVis = Window:Tab({ Title = "Camera & Visual", Icon = "aperture" })
local secSelfSpec = TabCamVis:Section({ Title = "Cinematic Director", Icon = "clapperboard", Box = true })
secSelfSpec:Toggle({ Title = "Enable Cinematic Director", Default = false, Callback = toggleSelfSpec })
secSelfSpec:Dropdown({ Title = "Preset Mode", Values = { "Orbit 360", "Floating", "Hyperlapse", "FPV Drone", "Vertigo Effect" }, Default = "Orbit 360", Callback = function(v) SS.mode = v end })
secSelfSpec:Slider({ Title = "Speed", Step = 0.1, Value = { Min = 0.1, Max = 5, Default = 1 }, Callback = function(v) SS.speed = v end })
secSelfSpec:Slider({ Title = "Distance Mult", Step = 0.1, Value = { Min = 0.5, Max = 3, Default = 1 }, Callback = function(v) SS.distanceMult = v end })

local secFC = TabCamVis:Section({ Title = "Drone Engine", Icon = "video", Box = true })
secFC:Toggle({ Title = "Enable Freecam", Default = false, Callback = toggleFreecam })
secFC:Slider({ Title = "Camera Speed", Step = 0.5, Value = { Min = 1, Max = 20, Default = 3 }, Callback = function(v) FC.speed = v end })
secFC:Slider({ Title = "Sensitivity", Step = 0.05, Value = { Min = 0.1, Max = 1.0, Default = 0.25 }, Callback = function(v) FC.sens = v end })

local secPresets = TabCamVis:Section({ Title = "Presets Filter", Icon = "palette", Box = true })
secPresets:Dropdown({ Title = "Select Filter", Values = { "Default", "Mendung HD", "Cool Blue HD", "Full Bright HD", "Senja", "Cyberpunk", "Reshade RTX" }, Default = "Default", Callback = applyFilter })

-- TAB: ESP
local TabESP = Window:Tab({ Title = "ESP", Icon = "scan-search" })
local secDetect = TabESP:Section({ Title = "Detection System", Icon = "radar", Box = true })
secDetect:Toggle({ Title = "Enable Radar", Default = false, Callback = function(v)
    State.ESP.active = v
    if not v then
        for _, c in pairs(State.ESP.cache) do
            pcall(function() if c.texts then c.texts.Visible = false end; if c.tracer then c.tracer.Visible = false end; if c.hl then c.hl.Enabled = false end end)
        end
    end
    notify("ESP", v and "ON" or "OFF", 1.5, "scan-eye")
end })
secDetect:Toggle({ Title = "Highlight Entity", Default = false, Callback = function(v) State.ESP.highlightMode = v end })
secDetect:Slider({ Title = "Scan Distance", Step = 10, Value = { Min = 50, Max = 2000, Default = 300 }, Callback = function(v) State.ESP.maxDrawDistance = v end })

-- TAB: LOGGER
local TabLog = Window:Tab({ Title = "Logger", Icon = "square-terminal" })
local secChat = TabLog:Section({ Title = "Chat Logger", Icon = "message-square", Box = true })
secChat:Toggle({ Title = "Enable Logger", Default = false, Callback = function(v) State.Utility.chatLog = v end })
local chatTargetDrop = secChat:Dropdown({ Title = "Select Targets", Multi = true, AllowNone = true, Values = getDisplayNames(), Callback = function(selected)
    State.Utility.chatTargets = {}
    if type(selected) == "table" then
        for _, name in ipairs(selected) do table.insert(State.Utility.chatTargets, tostring(name)) end
    end
end })
secChat:Button({ Title = "Refresh List", Callback = function() pcall(function() chatTargetDrop:Refresh(getDisplayNames()) end); notify("Logger", "List refreshed", 1.5, "message-square") end })
chatLogPanel = secChat:Paragraph({ Title = "Console", Desc = "Belum ada chat..." })
secChat:Button({ Title = "Clear Log", Callback = function() State.Utility.chatHistory = {}; if chatLogPanel then pcall(function() chatLogPanel:SetDesc("Belum ada chat...") end) end end })

local function onChatReceived(senderName, senderDisplay, message)
    if not State.Utility.chatLog or #State.Utility.chatTargets == 0 then return end
    local now = tick()
    if State.Utility.lastMsg == (senderName .. message) and (now - State.Utility.lastMsgTime) < 0.5 then return end
    State.Utility.lastMsg = senderName .. message
    State.Utility.lastMsgTime = now

    local csN = senderName:lower()
    local csD = senderDisplay and senderDisplay:lower() or ""
    for _, target in ipairs(State.Utility.chatTargets) do
        local ct = target:lower()
        if csN == ct or csD == ct then
            local entry = string.format("[%s] %s: %s", os.date("%H:%M:%S"), senderDisplay or senderName, message)
            table.insert(State.Utility.chatHistory, entry)
            if #State.Utility.chatHistory > 50 then table.remove(State.Utility.chatHistory, 1) end
            notify("Chat", (senderDisplay or senderName) .. ": " .. message, 2, "message-square")
            break
        end
    end
end

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    pcall(function()
        TrackC(TextChatService.MessageReceived:Connect(function(msg)
            if msg.TextSource then
                local p = Players:GetPlayerByUserId(msg.TextSource.UserId)
                if p then onChatReceived(p.Name, p.DisplayName, msg.Text) end
            end
        end))
    end)
else
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then TrackC(p.Chatted:Connect(function(m) onChatReceived(p.Name, p.DisplayName, m) end)) end
    end
    TrackC(Players.PlayerAdded:Connect(function(p)
        if p ~= LP then TrackC(p.Chatted:Connect(function(m) onChatReceived(p.Name, p.DisplayName, m) end)) end
    end))
end

-- TAB: PROTECTION & SETTINGS
local TabProt = Window:Tab({ Title = "Protection", Icon = "shield-half" })
local secProt = TabProt:Section({ Title = "Protection Protocols", Icon = "shield-check", Box = true })
secProt:Toggle({ Title = "Anti AFK (Ghost Mode)", Default = true, Callback = function(v) AFKSystem.active = v; notify("Anti AFK", v and "ON" or "OFF", 1.5, "shield") end })
secProt:Button({ Title = "Stuck Fix", Callback = function()
    local r, h = getRoot(), getHum()
    if r then r.Anchored = false; r.CFrame = r.CFrame + Vector3.new(0, 3, 0) end
    if h then h.Sit = false; h:ChangeState(Enum.HumanoidStateType.Jumping) end
    notify("Protection", "Stuck fix applied", 2, "wrench")
end })

local secSrv = TabProt:Section({ Title = "Server Control", Icon = "server", Box = true })
secSrv:Button({ Title = "Force Rejoin", Callback = function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end) end })
secSrv:Button({ Title = "Server Hop", Callback = function()
    pcall(function()
        local res = httpRequest({ Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100", Method = "GET" })
        if res and res.Body then
            local data = HttpService:JSONDecode(res.Body)
            if data and data.data then
                local candidates = {}
                for _, v in ipairs(data.data) do
                    if v.playing and v.playing < v.maxPlayers and v.id ~= game.JobId then table.insert(candidates, v) end
                end
                if #candidates > 0 then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, candidates[math.random(1, #candidates)].id, LP)
                end
            end
        end
    end)
end })

local TabSet = Window:Tab({ Title = "Settings", Icon = "panels-top-left" })
TabSet:Section({ Title = "🎨 Theme", Icon = "palette", Box = true }):Dropdown({
    Title = "UI Theme",
    Values = { "Dark", "Light", "Rose", "Sky", "Emerald", "Violet", "Red", "Amber", "Indigo", "Midnight", "Crimson" },
    Default = "Crimson",
    Callback = function(v) WindUI:SetTheme(v) end
})

notify("System", "XKID_HUB Ready", 3, "rocket")

end)

if not ERROR_NOTIFY_OK and ERROR_MSG then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "❌ XKID ERROR",
            Text = tostring(ERROR_MSG):sub(1, 300),
            Duration = 15
        })
    end)
    warn("[XKID] Script error: " .. tostring(ERROR_MSG))
end
