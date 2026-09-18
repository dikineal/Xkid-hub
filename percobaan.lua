-- @XKID SCRIPT V3.37
-- by @WTF.XKID | Roblox Build For Mobile/PC
-- Changelog V3.37:
-- - FIXED: NoClip getar (aggressive: clear BodyMover + 3-frame delay + state restore)
-- - ADDED: UI Size slider live (min 0.3x)
-- - CHANGED: ESP scan distance max 2000
-- - KEPT: Semua fitur V3.36

repeat task.wait() until game:IsLoaded()

-- ================================ WINDUI LOADER ================================
local WindUI = (function()
    local s, r = pcall(function() return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))() end)
    if s then return r else error("Failed to load WindUI") end
end)()

-- ================================ EXECUTOR DETECTION ================================
local executor = {
    name = "Unknown",
    has_writefile = false, has_readfile = false, has_listfiles = false,
    has_isfolder = false, has_makefolder = false, is_mobile_executor = false
}

pcall(function()
    local e = identifyexecutor and identifyexecutor() or getexecutorname and getexecutorname() or "Unknown"
    executor.name = e
    executor.is_mobile_executor = (string.find(e, "Hydrogen") or string.find(e, "Arceus") or string.find(e, "Vega")) and true or false
end)

executor.has_writefile = type(writefile) == "function"
executor.has_readfile = type(readfile) == "function"
executor.has_listfiles = type(listfiles) == "function"
executor.has_isfolder = type(isfolder) == "function"
executor.has_makefolder = type(makefolder) == "function"

if not executor.has_writefile then
    getgenv()._XKID_NO_SAVE = true
    warn("[XKID] Executor tidak support writefile")
end

-- ================================ HTTP REQUEST ================================
local function httpRequest(options)
    local syn_req = syn and syn.request
    local fluxus_req = fluxus and fluxus.request
    local http_req = http and http.request
    local request_func = http_request or request or syn_req or fluxus_req or http_req
    if not request_func then
        local httpService = game:GetService("HttpService")
        local ok, body = pcall(function() return httpService:GetAsync(options.Url, true) end)
        if ok then
            return { StatusCode = 200, Body = body, Success = true }
        else
            return { StatusCode = 0, Body = "", Success = false }
        end
    end
    return request_func(options)
end
getgenv()._XKID_REQUEST = httpRequest

-- ================================ MAX FPS UNLOCK ================================
pcall(function() if setfpscap then setfpscap(9999) end end)

-- ================================ SERVICES ================================
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = pcall(function() return game:GetService("VirtualUser") end) and game:GetService("VirtualUser") or nil
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local StatsService = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local onMobile = not UserInputService.KeyboardEnabled

getgenv()._XKID_UI_LOADING = true

-- ================================ UI SCALE AUTO-DETECT ================================
local vpX = Camera.ViewportSize.X
local UI_SCALE = 1.0
if vpX < 900 then UI_SCALE = 0.75
elseif vpX < 1200 then UI_SCALE = 0.9
else UI_SCALE = 1.0 end
getgenv()._XKID_UI_SCALE = UI_SCALE

-- ================================ ORIGINAL LIGHTING ================================
local originalLighting = {
    ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows, ExposureCompensation = Lighting.ExposureCompensation,
    FogEnd = Lighting.FogEnd,
}

local defaultLighting = {
    ClockTime = 14, Brightness = 1,
    Ambient = Color3.fromRGB(127, 127, 127), OutdoorAmbient = Color3.fromRGB(127, 127, 127),
    GlobalShadows = true, ExposureCompensation = 0, FogEnd = 100000,
}

-- ================================ CLEANUP OLD INSTANCE ================================
if getgenv()._XKID_RUNNING then getgenv()._XKID_RUNNING = false; task.wait(0.5) end

if getgenv()._XKID_ESP_CACHE then
    for _, c in pairs(getgenv()._XKID_ESP_CACHE) do
        pcall(function()
            if c.texts then c.texts:Remove() end
            if c.tracer then c.tracer:Remove() end
            if c.boxLines then for _, l in ipairs(c.boxLines) do l:Remove() end end
            if c.hl then c.hl:Destroy() end
        end)
    end
end
getgenv()._XKID_ESP_CACHE = {}

if getgenv()._XKID_LOADED then
    pcall(function()
        for _, v in pairs(CoreGui:GetChildren()) do if v.Name == "WindUI" or v.Name == "XKID_FreecamUI" then v:Destroy() end end
        for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" or v.Name == "_XKID_SHADE" or v.Name == "_XKID_WARMTH" or v.Name == "_XKID_VIGNETTE" then v:Destroy() end end
        if getgenv()._XKID_CONNS then for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end end
    end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDFreecam") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDFly") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDSpec") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDSelfSpec") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDShiftLock") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDFreecamLock") end)
end

getgenv()._XKID_LOADED = true
getgenv()._XKID_RUNNING = true
getgenv()._XKID_CONNS = {}

local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

-- ================================ NOTIFY ================================
local function notify(title, content, duration, icon)
    pcall(function() WindUI:Notify({ Title = title, Content = content, Duration = duration or 2, Icon = icon or "bell" }) end)
end

-- ================================ STATE ================================
local State = {
    Move = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly = { active = false, bv = nil, bg = nil, _keys = {} },
    HardFling = { active = false, power = 10000, mode = "Spin", currentPower = 0, rampUpActive = false },
    Security = { afkActive = true, shiftLock = false, shiftLockGyro = nil },
    Cinema = { hideUI = false, cachedGuis = {} },
    Avatar = { isRefreshing = false },
    Utility = { chatLog = false, chatTargets = {}, chatHistory = {} },
    AutoLike = { active = false, thread = nil, lastTarget = nil, count = 0, radius = 100, minCD = 2, maxCD = 6 },
    CustomFilter = {
        tintR = 255, tintG = 255, tintB = 255, saturation = 0, contrast = 0, brightness = 0,
        exposure = 0, bloomIntensity = 0, bloomSize = 24, clockTime = 14, shade = 0, warmth = 0, vignette = 0
    },
    SelfSpec = {
        active = false, mode = "Orbit 360", dist = 8, height = 3, orbitYaw = 0, orbitPitch = 20,
        fov = 70, origFov = 70, roll = 0, radius = 8, speed = 1, distanceMult = 1, heightOffset = 0,
        _crashInit = nil, _crashStartRadius = 8
    },
    ESP = {
        active = false, cache = getgenv()._XKID_ESP_CACHE, maxDrawDistance = 300, highlightMode = false,
        boxColor_N = Color3.fromRGB(255,0,0), boxColor_S = Color3.fromRGB(220,20,60), boxColor_G = Color3.fromRGB(255,165,0),
        tracerColor_N = Color3.fromRGB(255,0,0), tracerColor_S = Color3.fromRGB(220,20,60), tracerColor_G = Color3.fromRGB(255,165,0),
        nameColor = Color3.fromRGB(255,255,255)
    },
    Spec = { active = false, target = nil, mode = "third", dist = 8, origFov = 70, orbitYaw = 0, orbitPitch = 0, isSelf = false }
}

local colorMap = {
    Merah = Color3.fromRGB(255,0,0), Hijau = Color3.fromRGB(0,255,0), Biru = Color3.fromRGB(0,0,255),
    Kuning = Color3.fromRGB(255,255,0), Ungu = Color3.fromRGB(255,0,255), Cyan = Color3.fromRGB(0,255,255),
    Orange = Color3.fromRGB(255,165,0), Pink = Color3.fromRGB(255,105,180), Putih = Color3.fromRGB(255,255,255),
    Hitam = Color3.fromRGB(0,0,0), Crimson = Color3.fromRGB(220,20,60),
}

-- ================================ HELPER FUNCTIONS ================================
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end

local function getDisplayNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName) end end
    if #t == 0 then table.insert(t, "N/A") end; return t
end

local function getDisplayNamesWithSelf()
    local t = { "[Self]" }; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName) end end
    if #t == 1 then table.insert(t, "N/A") end; return t
end

local function findPlayerByDisplay(str)
    if str == "[Self]" then return LP end
    for _, p in pairs(Players:GetPlayers()) do if p.DisplayName == str or p.Name == str then return p end end
    return nil
end

local function getCharRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
end

local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    if hours > 0 then return string.format("%02d:%02d:%02d", hours, mins, secs)
    else return string.format("%02d:%02d", mins, secs) end
end

local function getConfigList()
    local list = {}
    if executor.has_isfolder and executor.has_listfiles then
        pcall(function()
            if isfolder and isfolder("XKID_HUB") then
                for _, file in ipairs(listfiles("XKID_HUB")) do
                    if file:match("%.json$") then local name = file:match("([^/\\]+)%.json$"); if name then table.insert(list, name) end end
                end
            end
        end)
    end
    if #list == 0 then table.insert(list, "No config") end
    return list
end

local function isOnGround()
    local r = getRoot(); if not r then return false end
    local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = { LP.Character }
    return workspace:Raycast(r.Position, Vector3.new(0, -5, 0), params) ~= nil
end

-- ================================ NOCLIP V3.37 AGGRESSIVE ================================
local isRestoring = false

local function clearAllPhysicsForces()
    local hrp = getRoot()
    if not hrp then return end
    for _, v in pairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("BodyPosition")
           or v:IsA("BodyForce") or v:IsA("BodyAngularVelocity") or v:IsA("BodyThrust")
           or v:IsA("VectorForce") or v:IsA("AngularVelocity") or v:IsA("LinearVelocity")
           or v:IsA("AlignOrientation") or v:IsA("AlignPosition") then
            if v.Name ~= "XKID_FlyBV" and v.Name ~= "XKID_FlyBG"
               and v.Name ~= "XKID_FreecamBP" and v.Name ~= "XKID_FreecamBG" then
                pcall(function() v:Destroy() end)
            end
        end
    end
end

local function resetAllVelocity()
    if not LP.Character then return end
    for _, p in pairs(LP.Character:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function()
                p.AssemblyLinearVelocity = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
                p.Velocity = Vector3.zero
                p.RotVelocity = Vector3.zero
            end)
        end
    end
end

-- ================================ GLOBAL VARS ================================
local START_TIME = os.time()
local cachedMapName = nil
local lastMapCheck = 0
local sharedFPS = 60
local sharedPing = 0

-- ================================ FPS & PING TRACKER ================================
TrackC(RunService.RenderStepped:Connect(function(dt) if dt > 0 then sharedFPS = math.floor(1 / dt) end end))

task.spawn(function()
    while getgenv()._XKID_RUNNING do task.wait(0.5); pcall(function() local item = StatsService.Network.ServerStatsItem["Data Ping"]; if item then sharedPing = math.floor(item:GetValue()) end end) end
end)

task.spawn(function()
    while getgenv()._XKID_RUNNING do pcall(function() if tick() - lastMapCheck > 30 or not cachedMapName then cachedMapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name; lastMapCheck = tick() end end); task.wait(5) end
end)

task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(120); collectgarbage("collect") end end)

-- ================================ ANTI AFK V3.37 ================================
local AFKSystem = {
    active = true, mode = "Original",
    idleConn = nil, backupTimer = nil, inputBegan = nil, inputChanged = nil,
    origTriggers = 0, liteTriggers = 0, _lastInput = nil, _liteJumpCounter = 0
}

local function performAntiAFK()
    if not AFKSystem.active then return end

    if AFKSystem.mode == "Original" then
        AFKSystem.origTriggers = AFKSystem.origTriggers + 1
        pcall(function()
            if VirtualUser then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(-9999, -9999)) end
        end)

    elseif AFKSystem.mode == "Lite" then
        AFKSystem.liteTriggers = AFKSystem.liteTriggers + 1
        AFKSystem._liteJumpCounter = (AFKSystem._liteJumpCounter or 0) + 1

        pcall(function()
            if VirtualUser then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(-9999, -9999)) end
        end)

        task.spawn(function()
            local hrp = getRoot()
            local hum = getHum()
            local inputAge = AFKSystem._lastInput and (tick() - AFKSystem._lastInput) or 999
            local isMoving = hum and hum.MoveDirection.Magnitude > 1
            local isIdle = inputAge > 5 and not isMoving

            if inputAge > 5 and isIdle then
                pcall(function()
                    if hrp and hum and hum.Health > 0 then
                        local originalPos = hrp.Position
                        hrp.CFrame = hrp.CFrame + Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
                        task.wait(0.3)
                        pcall(function() hrp.CFrame = CFrame.new(originalPos) end)
                        if AFKSystem._liteJumpCounter % 4 == 0 then
                            hum.Jump = true
                        end
                    end
                end)
            end
        end)
    end
end

local function startAFKSystem()
    if AFKSystem.idleConn then AFKSystem.idleConn:Disconnect(); AFKSystem.idleConn = nil end
    if AFKSystem.backupTimer then AFKSystem.backupTimer:Disconnect(); AFKSystem.backupTimer = nil end
    if AFKSystem.inputBegan then AFKSystem.inputBegan:Disconnect(); AFKSystem.inputBegan = nil end
    if AFKSystem.inputChanged then AFKSystem.inputChanged:Disconnect(); AFKSystem.inputChanged = nil end

    AFKSystem.idleConn = LP.Idled:Connect(performAntiAFK)

    local function resetInput()
        AFKSystem._lastInput = tick()
    end
    AFKSystem.inputBegan = UserInputService.InputBegan:Connect(resetInput)
    AFKSystem.inputChanged = UserInputService.InputChanged:Connect(resetInput)
    AFKSystem._lastInput = tick()

    local backupDelay = (AFKSystem.mode == "Lite") and 5 or 10

    AFKSystem.backupTimer = task.spawn(function()
        while AFKSystem.active do
            task.wait(backupDelay)
            if not AFKSystem.active then break end
            if AFKSystem._lastInput and tick() - AFKSystem._lastInput > backupDelay then
                performAntiAFK()
                AFKSystem._lastInput = tick()
            end
        end
    end)
end

local function stopAFKSystem()
    if AFKSystem.idleConn then AFKSystem.idleConn:Disconnect(); AFKSystem.idleConn = nil end
    if AFKSystem.backupTimer then pcall(function() task.cancel(AFKSystem.backupTimer) end); AFKSystem.backupTimer = nil end
    if AFKSystem.inputBegan then AFKSystem.inputBegan:Disconnect(); AFKSystem.inputBegan = nil end
    if AFKSystem.inputChanged then AFKSystem.inputChanged:Disconnect(); AFKSystem.inputChanged = nil end
    AFKSystem._lastInput = nil
end

local function setAFKMode(mode)
    AFKSystem.mode = mode
    if AFKSystem.active then
        stopAFKSystem()
        startAFKSystem()
    end
end

local function toggleAntiAFK(v)
    AFKSystem.active = v
    State.Security.afkActive = v
    if v then startAFKSystem(); notify("Anti AFK", "ON", 1.5, "shield-check")
    else stopAFKSystem(); notify("Anti AFK", "OFF", 1.5, "shield-check") end
end

task.spawn(function() task.wait(0.5); startAFKSystem() end)

-- ================================ SHIFT LOCK ================================
TrackC(LP.CharacterAdded:Connect(function(char)
    task.wait(0.5); local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end; if State.Move.jp ~= 50 then hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end end
    if State.Security.shiftLock then task.wait(0.2); local hrp = getRoot()
        if hrp then if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() end; State.Security.shiftLockGyro = Instance.new("BodyGyro", hrp); State.Security.shiftLockGyro.MaxTorque = Vector3.new(9e9,9e9,9e9); State.Security.shiftLockGyro.P = 50000; State.Security.shiftLockGyro.D = 1000 end
    end
end))

local function toggleShiftLock(v)
    State.Security.shiftLock = v
    if v then local hrp = getRoot()
        if hrp then if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() end; State.Security.shiftLockGyro = Instance.new("BodyGyro", hrp); State.Security.shiftLockGyro.MaxTorque = Vector3.new(9e9,9e9,9e9); State.Security.shiftLockGyro.P = 50000; State.Security.shiftLockGyro.D = 1000 end
        RunService:BindToRenderStep("XKIDShiftLock", Enum.RenderPriority.Camera.Value + 2, function() if not State.Security.shiftLock then return end; local hrp2, gyro = getRoot(), State.Security.shiftLockGyro; if hrp2 and gyro and gyro.Parent == hrp2 then local fl = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z); if fl.Magnitude > 0.01 then gyro.CFrame = CFrame.new(hrp2.Position, hrp2.Position + fl) end end end)
        notify("Shift Lock", "ON", 1.5, "lock")
    else RunService:UnbindFromRenderStep("XKIDShiftLock"); if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy(); State.Security.shiftLockGyro = nil end; notify("Shift Lock", "OFF", 1.5, "unlock") end
end

-- ================================ REFRESH CHARACTER ================================
local pendingRefreshCF, pendingRefreshWS, pendingRefreshJP, pendingRefreshZoom = nil, 16, 50, 400

local function refreshCharacter()
    if State.Avatar.isRefreshing then return end; local char = LP.Character; local hrp = getRoot()
    if not char or not hrp then notify("Error", "Character not found", 2, "circle-alert"); return end
    State.Avatar.isRefreshing = true; pendingRefreshCF = hrp.CFrame; pendingRefreshWS = State.Move.ws; pendingRefreshJP = State.Move.jp; pendingRefreshZoom = LP.CameraMaxZoomDistance
    notify("Refresh", "Reloading...", 1.5, "refresh-cw"); pcall(function() char:BreakJoints() end)
    local waited = 0; repeat task.wait(0.1); waited = waited + 0.1 until not LP.Character or waited > 2
    if LP.Character then pcall(function() LP.Character:Destroy() end); task.wait(0.3) end
    if not LP.Character then pcall(function() LP:LoadCharacter() end) end
    task.delay(12, function() if State.Avatar.isRefreshing then State.Avatar.isRefreshing = false; pendingRefreshCF = nil; notify("Error", "Refresh timeout", 3, "circle-alert") end end)
end

TrackC(LP.CharacterAdded:Connect(function(newChar)
    if not State.Avatar.isRefreshing or not pendingRefreshCF then return end; task.wait(0.3)
    local newHrp = newChar:FindFirstChild("HumanoidRootPart") or newChar:WaitForChild("HumanoidRootPart", 8)
    local newHum = newChar:FindFirstChildOfClass("Humanoid") or newChar:WaitForChild("Humanoid", 8)
    if newHrp and newHum then repeat task.wait() until newHum.Health > 0 and newHrp:IsDescendantOf(workspace)
        newHrp.CFrame = pendingRefreshCF + Vector3.new(0,4,0); newHrp.AssemblyLinearVelocity = Vector3.zero; newHrp.AssemblyAngularVelocity = Vector3.zero
        newHum.WalkSpeed = pendingRefreshWS; newHum.UseJumpPower = true; newHum.JumpPower = pendingRefreshJP
        Camera.CameraSubject = newHum; Camera.CameraType = Enum.CameraType.Custom; pcall(function() LP.CameraMaxZoomDistance = pendingRefreshZoom end)
        notify("Refresh", "Done", 2, "check-circle")
    end
    State.Avatar.isRefreshing = false; pendingRefreshCF = nil
end))

-- ================================ SMART TP ================================
local Teleport = { clickConn = nil, clickActive = false, toolActive = false, tool = nil }
local function executeTP() local hrp = getRoot(); if not hrp then return end; local m = LP:GetMouse(); if m.Hit then hrp.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0,3.5,0)); hrp.AssemblyLinearVelocity = Vector3.zero end end
local function toggleSmartTP(v)
    Teleport.clickActive = v
    if v then pcall(function() local t = Instance.new("Tool"); t.Name = "TP Tool"; t.RequiresHandle = false; t.Parent = LP.Backpack; Teleport.tool = t; Teleport.toolActive = false; t.Activated:Connect(function() Teleport.toolActive = not Teleport.toolActive end) end)
        Teleport.clickConn = TrackC(UserInputService.InputBegan:Connect(function(inp,gp) if gp then return end; if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then if Teleport.toolActive then executeTP(); Teleport.toolActive = false end end end))
        notify("Smart TP", "ON", 2, "map-pin")
    else if Teleport.clickConn then Teleport.clickConn:Disconnect(); Teleport.clickConn = nil end; pcall(function() if Teleport.tool then Teleport.tool:Destroy(); Teleport.tool = nil end end); Teleport.toolActive = false; notify("Smart TP", "OFF", 1.5, "map-pin") end
end

-- ================================ ESP ENGINE ================================
local function initPlayerCache(player)
    if State.ESP.cache[player] then return end
    local cache = { texts = nil, tracer = nil, boxLines = {}, hl = nil, isSuspect = false, isGlitch = false, reason = "" }
    pcall(function()
        if Drawing then
            cache.texts = Drawing.new("Text"); if cache.texts then cache.texts.Center = true; cache.texts.Outline = true; cache.texts.Font = 2; cache.texts.Size = 13; cache.texts.ZIndex = 2 end
            cache.tracer = Drawing.new("Line"); if cache.tracer then cache.tracer.Thickness = 1.5; cache.tracer.ZIndex = 1 end
            for i = 1,4 do local line = Drawing.new("Line"); if line then line.Thickness = 1.5; line.ZIndex = 1; cache.boxLines[i] = line end end
        end
    end)
    State.ESP.cache[player] = cache
end

local function clearPlayerCache(player)
    local c = State.ESP.cache[player]; if not c then return end
    pcall(function() if c.texts then c.texts:Remove() end end); pcall(function() if c.tracer then c.tracer:Remove() end end)
    for _, l in ipairs(c.boxLines) do pcall(function() if l then l:Remove() end end) end
    pcall(function() if c.hl then c.hl:Destroy() end end); State.ESP.cache[player] = nil
end

TrackC(Players.PlayerRemoving:Connect(clearPlayerCache))

local espsortedPlayers = {}
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if State.ESP.active then local tempSorted = {}; local myHrp = getCharRoot(LP.Character)
            for _, p in pairs(Players:GetPlayers()) do if p ~= LP and p.Character then
                local isSus, isGlitch, reason = false, false, ""
                for _, v in pairs(p.Character:GetChildren()) do
                    if v:IsA("BasePart") and (v.Size.X > 30 or v.Size.Y > 30 or v.Size.Z > 30) then isSus = true; reason = "Map Blocker"; break
                    elseif v:IsA("Accessory") then local h = v:FindFirstChild("Handle"); if h and h:IsA("BasePart") then if h.Size.Magnitude > 20 then isSus = true; reason = "Huge Hat"; break elseif h.Size.Magnitude > 10 or (h.Transparency < 0.1 and h.Material == Enum.Material.Neon) then isGlitch = true; reason = "Glitch Acc" end end
                    end
                end
                if not isSus and not isGlitch then local hum = p.Character:FindFirstChildOfClass("Humanoid"); if hum then local bws = hum:FindFirstChild("BodyWidthScale"); local bhs = hum:FindFirstChild("BodyHeightScale"); if (bws and bws.Value > 2) or (bhs and bhs.Value > 2) then isSus = true; reason = "Glitch Avatar" end end end
                initPlayerCache(p); if State.ESP.cache[p] then State.ESP.cache[p].isSuspect = isSus; State.ESP.cache[p].isGlitch = isGlitch; State.ESP.cache[p].reason = reason end
                if myHrp then local hrp2 = getCharRoot(p.Character); local hum2 = p.Character:FindFirstChildOfClass("Humanoid"); if hrp2 and hum2 and hum2.Health > 0 then local dist = (hrp2.Position - myHrp.Position).Magnitude; if dist <= State.ESP.maxDrawDistance then table.insert(tempSorted, { p = p, hrp = hrp2, dist = dist, char = p.Character }) end end end
            end end
            table.sort(tempSorted, function(a,b) return a.dist < b.dist end); espsortedPlayers = tempSorted
        end; task.wait(0.5)
    end
end)

TrackC(RunService.RenderStepped:Connect(function()
    if not State.ESP.active then return end; local myHrp = getCharRoot(LP.Character); if not myHrp then return end
    local vp = Camera.ViewportSize
    for _, c in pairs(State.ESP.cache) do pcall(function() if c.texts then c.texts.Visible = false end; if c.tracer then c.tracer.Visible = false end; for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end; if c.hl then c.hl.Enabled = false end end) end
    local hlCount = 0
    for _, data in ipairs(espsortedPlayers) do local player, char, hrp, dist = data.p, data.char, data.hrp, data.dist; local c = State.ESP.cache[player]; if not c then continue end
        local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position); if not onScreen then continue end
        local isSus, isGlitch = c.isSuspect, c.isGlitch; local useHl = isSus or isGlitch or State.ESP.highlightMode
        local txt = string.format("%s\n[%dm]", player.DisplayName, math.floor(dist)); if isSus or isGlitch then txt = txt .. "\n⚠ " .. c.reason end
        local cColor = isSus and State.ESP.boxColor_S or (isGlitch and State.ESP.boxColor_G or State.ESP.nameColor)
        local tColor = isSus and State.ESP.tracerColor_S or (isGlitch and State.ESP.tracerColor_G or State.ESP.tracerColor_N)
        local bColor = isSus and State.ESP.boxColor_S or (isGlitch and State.ESP.boxColor_G or State.ESP.boxColor_N)
        pcall(function() if c.texts then c.texts.Text = txt; c.texts.Color = cColor; c.texts.Position = Vector2.new(rootPos.X, rootPos.Y - 45); c.texts.Visible = true end
            if c.tracer then local origin = Vector2.new(vp.X / 2, vp.Y); c.tracer.From = origin; c.tracer.To = Vector2.new(rootPos.X, rootPos.Y); c.tracer.Color = tColor; c.tracer.Visible = true end end)
        if useHl and hlCount < 30 then hlCount = hlCount + 1
            pcall(function() local top, tv = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0,3,0)); local bot, bv = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3.5,0)); if tv and bv and #c.boxLines == 4 then local bh = math.abs(top.Y - bot.Y); local bw = bh * 0.6; c.boxLines[1].From = Vector2.new(rootPos.X - bw/2, top.Y); c.boxLines[1].To = Vector2.new(rootPos.X + bw/2, top.Y); c.boxLines[2].From = Vector2.new(rootPos.X + bw/2, top.Y); c.boxLines[2].To = Vector2.new(rootPos.X + bw/2, bot.Y); c.boxLines[3].From = Vector2.new(rootPos.X + bw/2, bot.Y); c.boxLines[3].To = Vector2.new(rootPos.X - bw/2, bot.Y); c.boxLines[4].From = Vector2.new(rootPos.X - bw/2, bot.Y); c.boxLines[4].To = Vector2.new(rootPos.X - bw/2, top.Y); for i = 1,4 do c.boxLines[i].Color = bColor; c.boxLines[i].Visible = true end end end)
            pcall(function() if not c.hl or c.hl.Parent ~= char then if c.hl then c.hl:Destroy() end; c.hl = Instance.new("Highlight", char); c.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end; if c.hl then c.hl.FillColor = bColor; c.hl.OutlineColor = Color3.new(1,1,1); c.hl.Enabled = true end end)
        end
    end
end))
-- ================================ FILTERS ================================
local FILTER_PRESETS = {
    Mendung_HD = { tint = Color3.fromRGB(180,185,200), sat = -0.3, con = 0.1, bri = -0.15, bloomI = 0.05, bloomS = 24, time = 10, lightB = 0.7 },
    Cool_Blue_HD = { tint = Color3.fromRGB(180,200,255), sat = 0.1, con = 0.15, bri = 0.05, bloomI = 0.2, bloomS = 24, time = 12, lightB = 1.2 },
    Soft_Fade_HD = { tint = Color3.fromRGB(255,240,235), sat = -0.1, con = -0.05, bri = 0.1, bloomI = 0.4, bloomS = 35, time = 15, lightB = 1.3 },
    Adaptif_Langit_HD = { tint = Color3.new(1,1,1), sat = 0.15, con = 0.2, bri = 0.05, bloomI = 0.15, bloomS = 24, time = 13, lightB = 1.5 },
    Edgy_HD = { tint = Color3.fromRGB(200,195,210), sat = -0.5, con = 0.4, bri = -0.1, bloomI = 0.3, bloomS = 20, time = 8, lightB = 0.8 },
    Full_Bright_HD = { tint = Color3.new(1,1,1), sat = 0, con = 0, bri = 0, bloomI = 0, bloomS = 24, time = 12, lightB = 3, shadow = false, ambient = Color3.new(1,1,1), outdoor = Color3.new(1,1,1) },
    Soft_Pastel_HD = { tint = Color3.fromRGB(255,240,245), sat = -0.05, con = 0.05, bri = 0, bloomI = 0.3, bloomS = 24, time = 8, lightB = 1 },
    Cinematic_Soft = { tint = Color3.new(1,1,1), sat = 0.1, con = 0.15, bri = 0.05, bloomI = 0.2, bloomS = 24, time = 17, lightB = 1 },
    Ultra_HD = { tint = Color3.new(1,1,1), sat = 0.2, con = 0.3, bri = 0, bloomI = 0.2, bloomS = 24, time = 14, lightB = 1 },
    Realistic = { tint = Color3.new(1,1,1), sat = 0.1, con = 0.2, bri = 0, bloomI = 0.15, bloomS = 24, time = 15, lightB = 1 },
    Night_HD = { tint = Color3.fromRGB(200,200,255), sat = 0.1, con = 0.2, bri = 0, bloomI = 0.15, bloomS = 24, time = 1, lightB = 1 },
    Senja = { tint = Color3.fromRGB(255,180,120), sat = 0.2, con = 0.1, bri = 0.05, bloomI = 0.5, bloomS = 40, time = 17.5, lightB = 1 },
    Cinematic_Film = { tint = Color3.fromRGB(200,210,230), sat = -0.15, con = 0.25, bri = -0.05, bloomI = 0.15, bloomS = 20, time = 16, lightB = 1 },
    Golden_Hour = { tint = Color3.fromRGB(255,200,100), sat = 0.1, con = 0.15, bri = 0.1, bloomI = 0.4, bloomS = 35, time = 17.5, lightB = 1 },
    Moody_Blue = { tint = Color3.fromRGB(150,170,255), sat = 0.05, con = 0.2, bri = -0.1, bloomI = 0.1, bloomS = 24, time = 2, lightB = 1 },
    Vintage = { tint = Color3.fromRGB(210,180,140), sat = -0.2, con = 0.15, bri = -0.05, bloomI = 0.1, bloomS = 20, time = 16, lightB = 1.1 },
    Cyberpunk = { tint = Color3.fromRGB(255,80,200), sat = 0.4, con = 0.3, bri = 0.05, bloomI = 0.8, bloomS = 40, time = 2, lightB = 1.5 },
    Sunset = { tint = Color3.fromRGB(255,150,80), sat = 0.3, con = 0.1, bri = 0.05, bloomI = 0.6, bloomS = 35, time = 18, lightB = 1.2 },
    Pastel = { tint = Color3.fromRGB(255,220,240), sat = -0.1, con = 0.05, bri = 0.05, bloomI = 0.3, bloomS = 30, time = 13, lightB = 1.2 },
    Noir = { tint = Color3.fromRGB(200,200,200), sat = -0.5, con = 0.4, bri = -0.1, bloomI = 0, bloomS = 24, time = 10, lightB = 0.8 },
    Shade_Soft = { tint = Color3.fromRGB(180,190,210), sat = -0.1, con = 0.1, bri = -0.05, bloomI = 0.1, bloomS = 24, time = 12, lightB = 0.9 },
}

local function resetFilterOnly()
    for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" or v.Name == "_XKID_SHADE" or v.Name == "_XKID_WARMTH" or v.Name == "_XKID_VIGNETTE" then v:Destroy() end end
end

local function resetToDefaultRoblox()
    resetFilterOnly(); Lighting.ClockTime = defaultLighting.ClockTime; Lighting.Brightness = defaultLighting.Brightness
    Lighting.Ambient = defaultLighting.Ambient; Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
    Lighting.GlobalShadows = defaultLighting.GlobalShadows; Lighting.ExposureCompensation = defaultLighting.ExposureCompensation; Lighting.FogEnd = defaultLighting.FogEnd
    for k, v in pairs({tintR=255,tintG=255,tintB=255,saturation=0,contrast=0,brightness=0,exposure=0,bloomIntensity=0,bloomSize=24,clockTime=14,shade=0,warmth=0,vignette=0}) do State.CustomFilter[k] = v end
    notify("Visuals", "Reset to Default Roblox", 1.5, "rotate-ccw")
end

local function applyCustomFilter()
    resetFilterOnly(); Lighting.Brightness = originalLighting.Brightness; Lighting.Ambient = originalLighting.Ambient; Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient; Lighting.GlobalShadows = originalLighting.GlobalShadows; Lighting.FogEnd = originalLighting.FogEnd; Lighting.ExposureCompensation = State.CustomFilter.exposure
    local cc = Instance.new("ColorCorrectionEffect", Lighting); cc.Name = "_XKID_FILTER"; cc.TintColor = Color3.fromRGB(State.CustomFilter.tintR, State.CustomFilter.tintG, State.CustomFilter.tintB); cc.Saturation = State.CustomFilter.saturation; cc.Contrast = State.CustomFilter.contrast; cc.Brightness = State.CustomFilter.brightness
    if State.CustomFilter.shade > 0 then local s = Instance.new("ColorCorrectionEffect", Lighting); s.Name = "_XKID_SHADE"; local sv = 1 - State.CustomFilter.shade; s.TintColor = Color3.fromRGB(sv*255,sv*255,sv*255); s.Brightness = -State.CustomFilter.shade*0.3; s.Contrast = State.CustomFilter.shade*0.2 end
    if State.CustomFilter.warmth ~= 0 then local w = Instance.new("ColorCorrectionEffect", Lighting); w.Name = "_XKID_WARMTH"; local wv = math.clamp(State.CustomFilter.warmth, -0.5, 0.5); if wv > 0 then w.TintColor = Color3.fromRGB(255,255-wv*150,255-wv*200); w.Brightness = wv*0.05 else local w2 = -wv; w.TintColor = Color3.fromRGB(255-w2*150,255-w2*50,255); w.Brightness = -w2*0.03 end end
    if State.CustomFilter.vignette > 0 then local v = Instance.new("BloomEffect", Lighting); v.Name = "_XKID_VIGNETTE"; v.Intensity = State.CustomFilter.vignette*0.3; v.Size = 10; v.Threshold = 0.5 end
    if State.CustomFilter.bloomIntensity > 0 then local b = Instance.new("BloomEffect", Lighting); b.Name = "_XKID_FILTER"; b.Intensity = State.CustomFilter.bloomIntensity; b.Size = State.CustomFilter.bloomSize end
    Lighting.ClockTime = State.CustomFilter.clockTime
end

local function applyFilter(filterName)
    resetFilterOnly(); Lighting.ClockTime = originalLighting.ClockTime; Lighting.Brightness = originalLighting.Brightness; Lighting.Ambient = originalLighting.Ambient; Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient; Lighting.GlobalShadows = originalLighting.GlobalShadows; Lighting.FogEnd = originalLighting.FogEnd; Lighting.ExposureCompensation = originalLighting.ExposureCompensation
    if filterName == "Default" then resetToDefaultRoblox(); return end
    if filterName == "Custom" then applyCustomFilter(); notify("Visuals", "Custom FX", 1.5, "palette"); return end
    local preset = FILTER_PRESETS[filterName:gsub(" ", "_"):gsub(" HD", "_HD")]
    if preset then
        Lighting.ClockTime = preset.time or 14; Lighting.Brightness = preset.lightB or 1; Lighting.ExposureCompensation = preset.exp or 0; Lighting.GlobalShadows = preset.shadow ~= false
        if preset.ambient then Lighting.Ambient = preset.ambient end; if preset.outdoor then Lighting.OutdoorAmbient = preset.outdoor end
        local cc = Instance.new("ColorCorrectionEffect", Lighting); cc.Name = "_XKID_FILTER"; cc.TintColor = preset.tint; cc.Saturation = preset.sat or 0; cc.Contrast = preset.con or 0; cc.Brightness = preset.bri or 0
        if preset.bloomI and preset.bloomI > 0 then local b = Instance.new("BloomEffect", Lighting); b.Name = "_XKID_FILTER"; b.Intensity = preset.bloomI; b.Size = preset.bloomS or 24 end
        State.CustomFilter.tintR = preset.tint.R*255; State.CustomFilter.tintG = preset.tint.G*255; State.CustomFilter.tintB = preset.tint.B*255; State.CustomFilter.saturation = preset.sat or 0; State.CustomFilter.contrast = preset.con or 0; State.CustomFilter.brightness = preset.bri or 0; State.CustomFilter.exposure = preset.exp or 0; State.CustomFilter.bloomIntensity = preset.bloomI or 0; State.CustomFilter.bloomSize = preset.bloomS or 24; State.CustomFilter.clockTime = preset.time or 14
        notify("Visuals", filterName, 2, "palette")
    else notify("Visuals", "Filter not found: " .. filterName, 2, "circle-alert") end
end

-- ================================ AUTO LIKE BACK ENGINE ================================
local AutoLikeEngine = {
    hasRemote = false, likeRemote = nil, getRemote = nil,
    notifHookConn = nil, likedCache = {}
}

local function detectLikeRemotes()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage
    local getRem = remotes:FindFirstChild("GetLikeDataRemote") or remotes:FindFirstChild("GetLikesRemote")
    local likeRem = remotes:FindFirstChild("LikePlayerEvent") or remotes:FindFirstChild("LikePlayer") or remotes:FindFirstChild("LikeRemote")
    if likeRem then
        AutoLikeEngine.hasRemote = true
        AutoLikeEngine.likeRemote = likeRem
        AutoLikeEngine.getRemote = getRem
        return true
    end
    AutoLikeEngine.hasRemote = false
    return false
end

task.spawn(function() task.wait(2); detectLikeRemotes() end)

local function likePlayerBlind(target)
    if AutoLikeEngine.hasRemote and AutoLikeEngine.likeRemote then
        local ok = pcall(function() AutoLikeEngine.likeRemote:FireServer(target) end)
        return ok
    end
    return false
end

local function likeRandomPlayer()
    local myRoot = getRoot()
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and not AutoLikeEngine.likedCache[p] then
            if State.AutoLike.radius > 0 and myRoot then
                local theirRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if theirRoot then
                    local dist = (theirRoot.Position - myRoot.Position).Magnitude
                    if dist <= State.AutoLike.radius then table.insert(targets, p) end
                end
            else
                table.insert(targets, p)
            end
        end
    end
    if #targets == 0 then
        AutoLikeEngine.likedCache = {}
        for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(targets, p) end end
    end
    if #targets == 0 then return false, "No players" end
    local target = targets[math.random(1, #targets)]
    State.AutoLike.lastTarget = target
    local ok = likePlayerBlind(target)
    if ok then
        AutoLikeEngine.likedCache[target] = true
        State.AutoLike.count = State.AutoLike.count + 1
        return true, target.DisplayName
    end
    return false, "Failed"
end

local function startAutoLike()
    if State.AutoLike.active then return end
    State.AutoLike.active = true
    State.AutoLike.thread = task.spawn(function()
        while State.AutoLike.active and getgenv()._XKID_RUNNING do
            local ok, result = likeRandomPlayer()
            if ok then notify("Auto Like", result .. " | Total: " .. State.AutoLike.count, 1.5, "heart") end
            local cd = math.random(State.AutoLike.minCD * 10, State.AutoLike.maxCD * 10) / 10
            task.wait(cd)
        end
        State.AutoLike.thread = nil
    end)
    notify("Auto Like", "ON", 2, "heart")
end

local function stopAutoLike()
    State.AutoLike.active = false
    if State.AutoLike.thread then
        pcall(function() task.cancel(State.AutoLike.thread) end)
        State.AutoLike.thread = nil
    end
    notify("Auto Like", "OFF", 1.5, "heart")
end

local function hookNotifications()
    pcall(function()
        if not StarterGui.SetCore then return end
        if AutoLikeEngine.notifHookConn then return end
        AutoLikeEngine.notifHookConn = true
        local mt = getrawmetatable and getrawmetatable(game)
        if not mt or not setreadonly then return end
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if self == StarterGui and method == "SetCore" and args[1] == "SendNotification" and type(args[2]) == "table" then
                local title = args[2].Title or ""
                local text = args[2].Text or ""
                local combined = (title .. " " .. text):lower()
                if combined:find("like") then
                    task.spawn(function()
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LP and p.Character then
                                local root = p.Character:FindFirstChild("HumanoidRootPart")
                                if root and getRoot() then
                                    local dist = (root.Position - getRoot().Position).Magnitude
                                    if dist < 50 then
                                        likePlayerBlind(p)
                                        AutoLikeEngine.likedCache[p] = true
                                        State.AutoLike.count = State.AutoLike.count + 1
                                        notify("Auto Like Back", p.DisplayName, 1.5, "heart")
                                    end
                                end
                            end
                        end
                    end)
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

task.spawn(function() task.wait(3); hookNotifications() end)

-- ================================ UI WINDOW ================================
local baseWidth = math.floor(360 * UI_SCALE)
local baseHeight = math.floor(320 * UI_SCALE)
local sidebarWidth = math.floor(160 * UI_SCALE)

local Window = WindUI:CreateWindow({
    Title = "XKID_HUB V3.37", Icon = "bluetooth", Author = "@WTF.XKID", Folder = "XKIDHub",
    Size = UDim2.fromOffset(baseWidth, baseHeight), Transparent = true, Theme = "Crimson", SideBarWidth = sidebarWidth,
    User = { Enabled = true, Anonymous = false }, Topbar = { Height = math.floor(40 * UI_SCALE), ButtonsType = "Default" },
})
pcall(function() WindUI:SetFont("rbxassetid://12187376357") end)
pcall(function() WindUI:SetNotificationLower(true) end)
pcall(function() Window.User:SetDisplayName(LP.DisplayName) Window.User:SetUsername("@" .. LP.Name) end)
Window:EditOpenButton({ Title = "WTF.XKID", Icon = "github", CornerRadius = UDim.new(1,0), StrokeThickness = 2, StrokeColor = Color3.fromRGB(255,70,120), Enabled = true, Draggable = true, Scale = 0.72 * UI_SCALE })
local FpsTag = Window:Tag({ Title = "FPS: -- | Ping: --", Color = Color3.fromRGB(255,215,0), Icon = "activity" })
local VerTag = Window:Tag({ Title = "V3.37", Color = Color3.fromRGB(255,215,0), Icon = "tag" })
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(1) if FpsTag and FpsTag.SetTitle then FpsTag:SetTitle("FPS: " .. sharedFPS .. " | Ping: " .. sharedPing .. "ms") end end end)

-- ================================ UI FORCE RESIZE FUNCTION ================================
local function forceResizeWindow(scale)
    local w = math.floor(280 * scale)
    local h = math.floor(240 * scale)
    pcall(function()
        for _, v in pairs(CoreGui:GetChildren()) do
            if v.Name == "WindUI" or v.Name:lower():find("windui") then
                for _, frame in pairs(v:GetDescendants()) do
                    if frame:IsA("Frame") and (frame.Name == "Main" or frame.Name == "Root") then
                        frame.Size = UDim2.fromOffset(w, h)
                        for _, c in pairs(frame:GetChildren()) do
                            if c:IsA("UISizeConstraint") then
                                c.MinSize = Vector2.new(50, 50)
                            end
                        end
                    end
                end
            end
        end
    end)
end
getgenv()._XKID_FORCE_RESIZE = forceResizeWindow

-- ================================ TAB: INFORMASI ================================
local TabInfo = Window:Tab({ Title = "Informasi", Icon = "activity" })
local function getExecutor() pcall(function() local e = identifyexecutor() if e and e ~= "" then return e end end) pcall(function() local e = getexecutorname() if e and e ~= "" then return e end end) return executor.name end
local execName = getExecutor(); local accountAge = LP.AccountAge .. " days"
local avatarImage = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=420&h=420"

local afkStatusParagraph = TabInfo:Paragraph({
    Title = "YooWssp!!, " .. LP.DisplayName,
    Desc = "Executor: " .. execName .. "\nAccount Age: " .. accountAge .. "\nUserID: " .. LP.UserId .. "\nFPS: " .. sharedFPS,
    Image = avatarImage, ImageSize = 80
})
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(1); pcall(function() afkStatusParagraph:SetDesc("Executor: " .. execName .. "\nAccount Age: " .. accountAge .. "\nUserID: " .. LP.UserId .. "\nFPS: " .. sharedFPS) end) end end)

local infoParagraph = TabInfo:Paragraph({ Title = "💀 " .. LP.DisplayName, Desc = "Loading..." })

task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(1)
        pcall(function()
            local elapsed = os.difftime(os.time(), START_TIME)
            local uptime = formatTime(elapsed)
            local currentExecName = getExecutor()
            local afkStatus = AFKSystem.active and ("✅ " .. AFKSystem.mode) or "❌ INACTIVE"
            local triggerCount = (AFKSystem.mode == "Original") and AFKSystem.origTriggers or AFKSystem.liteTriggers
            local triggerMod = triggerCount % 100
            local fill = math.floor(triggerMod / 5)
            local bar = string.rep("█", fill) .. string.rep("░", 20 - fill)

            infoParagraph:SetTitle("💀 " .. LP.DisplayName)
            infoParagraph:SetDesc(string.format(
                "⏳ AFK Triggers [%s]\n%s %d%%\nTriggers: %d | Status: %s\n\n⏱ Uptime: %s\n📱 %s | 🚀 %s\n🎮 %s\n👥 %d/%d Players",
                AFKSystem.mode, bar, triggerMod, triggerCount, afkStatus,
                uptime,
                (onMobile and "Mobile" or "PC"), currentExecName,
                (cachedMapName or "Loading..."),
                #Players:GetPlayers(), Players.MaxPlayers
            ))
        end)
    end
end)

TabInfo:Section({ Title = "🔗 Discord", Icon = "message-circle", Box = true }):Button({ Title = "Copy Discord Link", Desc = "discord.gg/bzumc2u96", Callback = function() pcall(function() setclipboard("https://discord.gg/bzumc2u96") end) notify("System", "Link copied", 2, "copy") end })

-- ================================ TAB: CHARACTER ================================
local TabChar = Window:Tab({ Title = "Character", Icon = "fingerprint" })
TabChar:Button({ Title = "Refresh Character 🔄", Desc = "Reload character like /re", Callback = refreshCharacter })
local secMov = TabChar:Section({ Title = "Movement", Icon = "activity", Box = true })
secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end })
secMov:Toggle({ Title = "Infinite Jump", Default = false, Callback = function(v) if v then State.Move.infJ = TrackC(UserInputService.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end)) else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end end; notify("Infinite Jump", v and "ON" or "OFF", 1.5, "arrow-big-up") end })

local secAbi = TabChar:Section({ Title = "Abilities", Icon = "zap", Box = true })
secAbi:Toggle({ Title = "Fly", Default = false, Callback = function(v) toggleFly(v) end })
secAbi:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(v) State.Move.flyS = v end })

-- NOCLIP V3.37 AGGRESSIVE
local noclipConn = nil
secAbi:Toggle({
    Title = "NoClip",
    Default = false,
    Callback = function(v)
        State.Move.ncp = v
        if v then
            if not noclipConn then
                noclipConn = TrackC(RunService.Stepped:Connect(function()
                    if not State.Move.ncp then return end
                    if LP.Character then
                        for _, p in pairs(LP.Character:GetDescendants()) do
                            if p:IsA("BasePart") then p.CanCollide = false end
                        end
                    end
                end))
            end
            notify("NoClip", "ON", 1.5, "ghost")
        else
            if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
            if isRestoring then return end
            isRestoring = true
            task.spawn(function()
                local hrp = getRoot()
                local hum = getHum()
                local savedWS = hum and hum.WalkSpeed or 16
                local savedJP = hum and hum.JumpPower or 50
                if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum.AutoRotate = false; hum.PlatformStand = false end
                clearAllPhysicsForces()
                resetAllVelocity()
                RunService.Stepped:Wait()
                RunService.Stepped:Wait()
                RunService.Stepped:Wait()
                if LP.Character then
                    for _, p in pairs(LP.Character:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.CanCollide = (p.Name ~= "HumanoidRootPart")
                        end
                    end
                end
                resetAllVelocity()
                if hum then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Landed) end)
                    task.wait(0.05)
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                end
                task.wait(0.15)
                resetAllVelocity()
                if hum then hum.WalkSpeed = savedWS; hum.JumpPower = savedJP; hum.AutoRotate = true end
                isRestoring = false
                notify("NoClip", "OFF", 1.5, "ghost")
            end)
        end
    end
})

-- CAMERA LOCK (PINDAH DARI PROTECTION)
local secCamLock = TabChar:Section({ Title = "Camera Lock", Icon = "lock", Box = true })
secCamLock:Toggle({ Title = "Force Shift Lock", Default = false, Callback = function(v) toggleShiftLock(v) end })

-- HARD FLING (SPIN ONLY)
local secFling = TabChar:Section({ Title = "Hard Fling (Safe)", Icon = "rotate-cw", Box = true })
secFling:Toggle({ Title = "Hard Fling", Default = false, Callback = function(v) if v then startHardFling() else stopHardFling() end end })
secFling:Slider({ Title = "Fling Power", Step = 500, Value = { Min = 1000, Max = 50000, Default = 10000 }, Callback = function(v) State.HardFling.power = v end })

-- ================================ TAB: TELEPORT ================================
local TabTP = Window:Tab({ Title = "Teleport", Icon = "map-pin-x-inside" })
TabTP:Section({ Title = "Direct Teleport", Icon = "map-pin", Box = true }):Toggle({ Title = "Smart TP", Desc = "Equip tool → tap to toggle mode → tap to TP", Default = false, Callback = toggleSmartTP })
local secTargetTP = TabTP:Section({ Title = "Target Teleport", Icon = "crosshair", Box = true })
local tpTarget = ""
secTargetTP:Input({ Title = "Search Player", Placeholder = "Type name...", Callback = function(v) tpTarget = v end })
secTargetTP:Button({ Title = "Execute TP", Desc = "Teleport to target", Callback = function() pcall(function() if tpTarget == "" then notify("Teleport", "Input target!", 2, "circle-alert"); return end; local t = nil; for _, p in pairs(Players:GetPlayers()) do if p ~= LP and (string.find(string.lower(p.Name), string.lower(tpTarget)) or string.find(string.lower(p.DisplayName), string.lower(tpTarget))) then t = p; break end end; if not t or not t.Parent or not t.Character then notify("Teleport", "Invalid Target", 2, "circle-alert"); return end; local thr = getCharRoot(t.Character); local mhr = getRoot(); if not thr or not mhr then return end; mhr.CFrame = thr.CFrame * CFrame.new(0,0,3) + Vector3.new(0,2,0); notify("Teleport", t.DisplayName, 2, "map-pin") end) end })
secTargetTP:Dropdown({ Title = "Player List", Values = getDisplayNames(), Callback = function(v) tpTarget = tostring(v) end })
secTargetTP:Button({ Title = "Refresh List", Callback = function() notify("Teleport", "List refreshed", 1.5, "map-pin") end })
local secCache = TabTP:Section({ Title = "Coordinates Cache", Icon = "save", Box = true })
local SavedLocs = {}
for i = 1,3 do local idx = i; local hc = secCache:HStack({ Columns = 2 })
    hc:Button({ Title = "💾 Save " .. idx, Callback = function() local r = getRoot(); if not r then return end; SavedLocs[idx] = r.CFrame; notify("Slot " .. idx, "Saved", 1.5, "save") end })
    hc:Button({ Title = "📍 Load " .. idx, Callback = function() if not SavedLocs[idx] then notify("Slot " .. idx, "Empty", 1.5, "save"); return end; local r = getRoot(); if not r then return end; r.CFrame = SavedLocs[idx]; notify("Slot " .. idx, "Loaded", 1.5, "map-pin") end })
end

-- ================================ TAB: SPECTATOR ================================
local TabSpec = Window:Tab({ Title = "Spectator", Icon = "cctv" })
TabSpec:Section({ Title = "Zoom Override", Icon = "zoom-in", Box = true }):Toggle({ Title = "Max Zoom Out", Default = false, Callback = function(v) pcall(function() LP.CameraMaxZoomDistance = v and 100000 or 400 end); notify("Zoom", v and "Max" or "Default", 1.5, "zoom-in") end })
local secSP = TabSpec:Section({ Title = "Spectator Mode", Icon = "eye", Box = true })
secSP:Dropdown({ Title = "Select Target", Values = getDisplayNamesWithSelf(), Callback = function(v) local s = tostring(v); if s == "[Self]" then State.Spec.target = LP; State.Spec.isSelf = true; State.Spec.orbitYaw = 0; State.Spec.orbitPitch = 20; notify("Spectator", "Self", 1.5, "eye") else local p = findPlayerByDisplay(s); if p then State.Spec.target = p; State.Spec.isSelf = false; if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ(); State.Spec.orbitYaw = math.deg(ry); State.Spec.orbitPitch = 20 end; notify("Spectator", p.DisplayName, 1.5, "eye") end end end })
secSP:Button({ Title = "Refresh Target List", Callback = function() notify("Spectator", "List refreshed", 1.5, "eye") end })
secSP:Toggle({ Title = "Enable Spectate", Default = false, Callback = function(v) if SS.active then toggleSelfSpec(false) end; State.Spec.active = v; if v then if not State.Spec.target or not State.Spec.target.Character then if State.Spec.isSelf and LP.Character then else State.Spec.active = false; notify("Error", "No target", 2, "circle-alert"); return end end; State.Spec.origFov = Camera.FieldOfView; startSpecCapture(); startSpecLoop(); notify("Spectator", "ON", 2, "eye") else stopSpecLoop(); stopSpecCapture(); Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = State.Spec.origFov; notify("Spectator", "OFF", 1.5, "eye") end end })
secSP:Slider({ Title = "Distance", Step = 1, Value = { Min = 3, Max = 30, Default = 8 }, Callback = function(v) State.Spec.dist = v end })

-- ================================ TAB: CAMERA & VISUAL ================================
local TabCamVis = Window:Tab({ Title = "Camera & Visual", Icon = "aperture" })

local secSelfSpec = TabCamVis:Section({ Title = "Cinematic Director", Icon = "clapperboard", Box = true })
secSelfSpec:Toggle({ Title = "Enable Cinematic Director", Desc = "Aktifkan kamera sinematik", Default = false, Callback = function(v) toggleSelfSpec(v) end })
secSelfSpec:Dropdown({ Title = "Preset Mode", Values = { "Orbit 360", "Floating", "Hyperlapse", "Orbit Vertical", "Fisheye", "Wave Orbit", "Dual Axis", "Action Cam", "Cinematic Drift", "FPV Drone", "Crash Zoom", "Smear Cam", "Whip Snap", "Bounce Beat", "Vertigo Effect" }, Default = "Orbit 360", Callback = function(v) SS.mode = v; SS._crashInit = nil; notify("Cinematic", "Preset: " .. v, 1.5, "camera") end })
secSelfSpec:Slider({ Title = "Speed", Step = 0.1, Value = { Min = 0.1, Max = 5, Default = 1 }, Callback = function(v) SS.speed = v end })
secSelfSpec:Slider({ Title = "Distance Mult", Step = 0.1, Value = { Min = 0.5, Max = 3, Default = 1 }, Callback = function(v) SS.distanceMult = v end })
secSelfSpec:Slider({ Title = "Height Offset", Step = 0.5, Value = { Min = -5, Max = 10, Default = 0 }, Callback = function(v) SS.heightOffset = v end })

local secFC = TabCamVis:Section({ Title = "Drone Engine", Icon = "video", Box = true })
secFC:Toggle({ Title = "Enable Freecam", Desc = "Karakter LOCK posisi + Bisa Emote/Dance", Default = false, Callback = toggleFreecam })
secFC:Slider({ Title = "Camera Speed", Step = 0.5, Value = { Min = 1, Max = 20, Default = 3 }, Callback = function(v) FC.speed = v end })
secFC:Slider({ Title = "Sensitivity", Step = 0.05, Value = { Min = 0.1, Max = 1.0, Default = 0.25 }, Callback = function(v) FC.sens = v end })
secFC:Toggle({ Title = "Hide All UI (Cinematic)", Default = false, Callback = function(v) if getgenv()._XKID_UI_LOADING then return end
    if v then State.Cinema.hideUI = true; State.Cinema.cachedGuis = {}; for _, gui in pairs(LP.PlayerGui:GetChildren()) do if gui:IsA("ScreenGui") and gui.Enabled then table.insert(State.Cinema.cachedGuis, gui); gui.Enabled = false end end; pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end); if FCUI then FCUI.Enabled = false end
    else State.Cinema.hideUI = false; for _, gui in pairs(State.Cinema.cachedGuis) do if gui and gui.Parent then gui.Enabled = true end end; State.Cinema.cachedGuis = {}; pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end); if FC.active and FCUI then FCUI.Enabled = true end end; notify("Cinematic", v and "UI Hidden" or "UI Shown", 1.5, "film") end })

local secPresets = TabCamVis:Section({ Title = "Presets Filter", Icon = "palette", Box = true })
secPresets:Dropdown({ Title = "Select Filter", Values = { "Default", "Custom", "Mendung HD", "Cool Blue HD", "Soft Fade HD", "Adaptif Langit HD", "Edgy HD", "Full Bright HD", "Soft Pastel HD", "Cinematic Soft", "Ultra HD", "Realistic", "Night HD", "Senja", "Cinematic Film", "Golden Hour", "Moody Blue", "Vintage", "Cyberpunk", "Sunset", "Pastel", "Noir", "Shade Soft" }, Default = "Default", Callback = applyFilter })

local secFX = TabCamVis:Section({ Title = "Custom FX", Icon = "sliders", Box = true })
secFX:Slider({ Title = "Saturation", Step = 0.05, Value = { Min = -1, Max = 1, Default = 0 }, Callback = function(v) State.CustomFilter.saturation = v; applyCustomFilter() end })
secFX:Slider({ Title = "Contrast", Step = 0.05, Value = { Min = -1, Max = 1, Default = 0 }, Callback = function(v) State.CustomFilter.contrast = v; applyCustomFilter() end })
secFX:Slider({ Title = "Brightness", Step = 0.05, Value = { Min = -1, Max = 1, Default = 0 }, Callback = function(v) State.CustomFilter.brightness = v; applyCustomFilter() end })
secFX:Slider({ Title = "Exposure", Step = 0.1, Value = { Min = -5, Max = 5, Default = 0 }, Callback = function(v) State.CustomFilter.exposure = v; applyCustomFilter() end })
secFX:Slider({ Title = "Bloom Intensity", Step = 0.1, Value = { Min = 0, Max = 2, Default = 0 }, Callback = function(v) State.CustomFilter.bloomIntensity = v; applyCustomFilter() end })
secFX:Slider({ Title = "ClockTime", Step = 0.5, Value = { Min = 0, Max = 24, Default = 14 }, Callback = function(v) State.CustomFilter.clockTime = v; applyCustomFilter() end })
secFX:Slider({ Title = "Shade (Bayangan)", Step = 0.05, Value = { Min = 0, Max = 1, Default = 0 }, Callback = function(v) State.CustomFilter.shade = v; applyCustomFilter() end })
secFX:Slider({ Title = "Warmth (Suhu Warna)", Step = 0.05, Value = { Min = -0.5, Max = 0.5, Default = 0 }, Callback = function(v) State.CustomFilter.warmth = v; applyCustomFilter() end })
secFX:Slider({ Title = "Vignette (Pinggiran Gelap)", Step = 0.05, Value = { Min = 0, Max = 1, Default = 0 }, Callback = function(v) State.CustomFilter.vignette = v; applyCustomFilter() end })
secFX:Button({ Title = "Reset Custom FX", Callback = function() for k, v in pairs({saturation=0,contrast=0,brightness=0,exposure=0,bloomIntensity=0,clockTime=14,shade=0,warmth=0,vignette=0}) do State.CustomFilter[k] = v end; applyCustomFilter(); notify("Visuals", "Custom FX Reset", 2, "rotate-ccw") end })
secFX:Button({ Title = "Reset to Default Roblox", Desc = "Kembalikan lighting ke bawaan Roblox", Callback = function() resetToDefaultRoblox() end })

-- ================================ TAB: ESP ================================
local TabESP = Window:Tab({ Title = "ESP", Icon = "scan-search" })
local secDetect = TabESP:Section({ Title = "Detection System", Icon = "radar", Box = true })
secDetect:Toggle({ Title = "Enable Radar", Default = false, Callback = function(v) State.ESP.active = v; if not v and State.ESP.cache then for _, c in pairs(State.ESP.cache) do pcall(function() if c.texts then c.texts.Visible = false end; if c.tracer then c.tracer.Visible = false end; for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end; if c.hl then c.hl.Enabled = false end end) end end; notify("ESP", v and "ON" or "OFF", 1.5, "radar") end })
secDetect:Toggle({ Title = "Highlight Entity", Default = false, Callback = function(v) State.ESP.highlightMode = v; notify("ESP", "Highlight " .. (v and "ON" or "OFF"), 1.5, "radar") end })
secDetect:Slider({ Title = "Scan Distance", Step = 10, Value = { Min = 50, Max = 2000, Default = 300 }, Callback = function(v) State.ESP.maxDrawDistance = v end })
local secESPCol = TabESP:Section({ Title = "Color Config", Icon = "palette", Box = true })
secESPCol:Dropdown({ Title = "Normal Color", Values = { "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam" }, Default = "Merah", Callback = function(v) if colorMap[v] then State.ESP.tracerColor_N = colorMap[v]; State.ESP.boxColor_N = colorMap[v] end; notify("ESP", "Normal: " .. v, 1.5, "palette") end })
secESPCol:Dropdown({ Title = "Suspect Color", Values = { "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam", "Crimson" }, Default = "Crimson", Callback = function(v) if colorMap[v] then State.ESP.tracerColor_S = colorMap[v]; State.ESP.boxColor_S = colorMap[v] end; notify("ESP", "Suspect: " .. v, 1.5, "palette") end })
secESPCol:Dropdown({ Title = "Glitch Acc Color", Values = { "Orange", "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Pink", "Putih", "Hitam" }, Default = "Orange", Callback = function(v) if colorMap[v] then State.ESP.tracerColor_G = colorMap[v]; State.ESP.boxColor_G = colorMap[v] end; notify("ESP", "Glitch: " .. v, 1.5, "palette") end })

-- ================================ TAB: LOGGER ================================
local TabLog = Window:Tab({ Title = "Logger", Icon = "square-terminal" })
local secChat = TabLog:Section({ Title = "Chat Logger", Icon = "message-square", Box = true })
local chatLogPanel = nil
secChat:Toggle({ Title = "Enable Logger", Default = false, Callback = function(v)
    State.Utility.chatLog = v
    if not v and chatLogPanel then pcall(function() chatLogPanel:SetDesc("Logger disabled") end) end
    notify("Logger", v and "ON" or "OFF", 1.5, "terminal")
end })

local chatTargetLabel = secChat:Paragraph({ Title = "Targets", Desc = "None" })
local chatTargetDrop = secChat:Dropdown({ Title = "Select Targets", Multi = true, AllowNone = true, Values = getDisplayNames(), Callback = function(selected)
    State.Utility.chatTargets = {}
    if selected and typeof(selected) == "table" then
        for _, name in ipairs(selected) do table.insert(State.Utility.chatTargets, tostring(name)) end
    end
    if #State.Utility.chatTargets > 0 then
        pcall(function() chatTargetLabel:SetDesc("Tracking: " .. table.concat(State.Utility.chatTargets, ", ")) end)
    else
        pcall(function() chatTargetLabel:SetDesc("None") end)
    end
end })

secChat:Button({ Title = "Clear Targets", Callback = function()
    State.Utility.chatTargets = {}
    pcall(function() chatTargetLabel:SetDesc("None") end)
    pcall(function() chatTargetDrop:SetValues({}); task.wait(0.05); chatTargetDrop:SetValues(getDisplayNames()) end)
    notify("Logger", "Targets cleared", 1.5, "terminal")
end })

secChat:Button({ Title = "Refresh List", Callback = function()
    pcall(function() chatTargetDrop:Refresh(getDisplayNames(), true) end)
    notify("Logger", "List refreshed", 1.5, "terminal")
end })

chatLogPanel = secChat:Paragraph({ Title = "Console", Desc = "Belum ada chat..." })
secChat:Button({ Title = "Clear Log", Callback = function()
    State.Utility.chatHistory = {}
    pcall(function() chatLogPanel:SetDesc("Belum ada chat...") end)
    notify("Logger", "Log cleared", 1.5, "terminal")
end })

task.spawn(function()
    local function onChat(senderName, senderDisplay, message)
        if not State.Utility.chatLog then return end
        if #State.Utility.chatTargets == 0 then return end
        local cleanSenderN = senderName:lower():match("^%s*(.-)%s*$")
        local cleanSenderD = senderDisplay and senderDisplay:lower():match("^%s*(.-)%s*$") or ""
        for _, target in ipairs(State.Utility.chatTargets) do
            local cleanTarget = target:lower():match("^%s*(.-)%s*$")
            if cleanSenderN == cleanTarget or cleanSenderD == cleanTarget then
                local entry = string.format("[%s] %s: %s", os.date("%H:%M:%S"), senderDisplay or senderName, message)
                table.insert(State.Utility.chatHistory, entry)
                if #State.Utility.chatHistory > 50 then table.remove(State.Utility.chatHistory, 1) end
                notify("Chat", (senderDisplay or senderName) .. ": " .. message, 2, "message-circle")
                break
            end
        end
    end

    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        pcall(function()
            TrackC(TextChatService.MessageReceived:Connect(function(msg)
                if msg.TextSource then
                    local player = Players:GetPlayerByUserId(msg.TextSource.UserId)
                    if player then onChat(player.Name, player.DisplayName, msg.Text) end
                end
            end))
        end)
    end

    local function connectLegacyChat(player)
        pcall(function() TrackC(player.Chatted:Connect(function(msg) onChat(player.Name, player.DisplayName, msg) end)) end)
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then connectLegacyChat(p) end
    end
    TrackC(Players.PlayerAdded:Connect(function(p) if p ~= LP then connectLegacyChat(p) end end))
end)

task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(0.5)
        if chatLogPanel and State.Utility.chatLog then
            pcall(function()
                local t = table.concat(State.Utility.chatHistory, "\n")
                if #t > 2000 then t = t:sub(-2000) end
                if #t == 0 then t = "Belum ada chat..." end
                chatLogPanel:SetDesc(t)
            end)
        end
    end
end)

-- ================================ TAB: PROTECTION ================================
local TabProt = Window:Tab({ Title = "Protection", Icon = "shield-half" })
local secProt = TabProt:Section({ Title = "Protection Protocols", Icon = "shield-check", Box = true })

local afkMainToggle = secProt:Toggle({ Title = "Anti AFK", Default = true, Callback = function(v)
    toggleAntiAFK(v)
    task.wait(0.2)
    pcall(function() afkMainToggle:SetState(v) end)
    pcall(function() afkMainToggle:SetValue(v) end)
end })
task.spawn(function()
    task.wait(1)
    pcall(function() afkMainToggle:SetState(true) end)
    pcall(function() afkMainToggle:SetValue(true) end)
end)

local origToggle = secProt:Toggle({ Title = "AFK Original Mode", Default = true, Callback = function(v)
    if v then
        setAFKMode("Original")
        pcall(function() liteToggle:SetState(false) end)
        pcall(function() liteToggle:SetValue(false) end)
    end
    notify("AFK Mode", v and "Original" or "Lite", 1.5, "shield-check")
end })

local liteToggle = secProt:Toggle({ Title = "AFK Lite Mode", Default = false, Callback = function(v)
    if v then
        setAFKMode("Lite")
        pcall(function() origToggle:SetState(false) end)
        pcall(function() origToggle:SetValue(false) end)
    end
    notify("AFK Mode", v and "Lite" or "Original", 1.5, "zap")
end })

task.spawn(function()
    task.wait(1.2)
    pcall(function() origToggle:SetState(true) end)
    pcall(function() origToggle:SetValue(true) end)
    pcall(function() liteToggle:SetState(false) end)
    pcall(function() liteToggle:SetValue(false) end)
end)

secProt:Button({ Title = "Stuck Fix", Desc = "Get unstuck from walls/ground", Callback = function() local r, h = getRoot(), getHum(); if r then r.Anchored = false; r.CFrame = r.CFrame + Vector3.new(0,3,0) end; if h then h.Sit = false; h:ChangeState(Enum.HumanoidStateType.Jumping) end; notify("Protection", "Stuck fix applied", 2, "wrench") end })

-- AUTO LIKE BACK
local secAutoLike = TabProt:Section({ Title = "Auto Like Back", Icon = "heart", Box = true })
secAutoLike:Toggle({ Title = "Enable Auto Like Back", Default = false, Callback = function(v) if v then startAutoLike() else stopAutoLike() end end })
secAutoLike:Slider({ Title = "Like Radius", Desc = "0 = semua player", Step = 10, Value = { Min = 0, Max = 500, Default = 100 }, Callback = function(v) State.AutoLike.radius = v end })
secAutoLike:Slider({ Title = "Min Cooldown", Step = 0.5, Value = { Min = 0.5, Max = 10, Default = 2 }, Callback = function(v) State.AutoLike.minCD = v end })
secAutoLike:Slider({ Title = "Max Cooldown", Step = 0.5, Value = { Min = 1, Max = 15, Default = 6 }, Callback = function(v) State.AutoLike.maxCD = v end })

local likeStatusParagraph = secAutoLike:Paragraph({ Title = "Status", Desc = "Mode: Blind Loop\nTotal likes sent: 0" })
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(2)
        pcall(function()
            local mode = AutoLikeEngine.hasRemote and "Event-Based + Blind" or "Blind Loop"
            likeStatusParagraph:SetDesc("Mode: " .. mode .. "\nTotal likes sent: " .. State.AutoLike.count)
        end)
    end
end)

-- SERVER CONTROL
local secSrv = TabProt:Section({ Title = "Server Control", Icon = "server", Box = true })
secSrv:Button({ Title = "Force Rejoin", Desc = "Rejoin current server", Callback = function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end); notify("Server", "Rejoining...", 2, "log-in") end })

secSrv:Button({ Title = "Server Hop", Desc = "Find a new server", Callback = function()
    pcall(function()
        local req = getgenv()._XKID_REQUEST or httpRequest
        if not req then notify("Error", "HTTP not supported", 2, "circle-alert"); return end
        local ok, res = pcall(function()
            return req({ Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100", Method = "GET" })
        end)
        if not ok or not res then notify("Error", "Request failed", 2, "circle-alert"); return end

        local body = nil
        if type(res) == "table" then
            if res.StatusCode and res.StatusCode ~= 200 then
                notify("Server Hop", "HTTP " .. tostring(res.StatusCode), 2, "circle-alert")
                return
            end
            body = res.Body
        elseif type(res) == "string" then
            body = res
        end
        if not body or body == "" then notify("Error", "Empty response", 2, "circle-alert"); return end

        local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, body)
        if not decodeOk or not data or not data.data then notify("Error", "Decode failed", 2, "circle-alert"); return end

        local candidates = {}
        for _, v in ipairs(data.data) do
            if v.playing and v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(candidates, v)
            end
        end
        if #candidates == 0 then notify("Server Hop", "No available server", 2, "circle-alert"); return end
        local picked = candidates[math.random(1, #candidates)]
        TeleportService:TeleportToPlaceInstance(game.PlaceId, picked.id, LP)
        notify("Server", "Hopping...", 2, "shuffle")
    end)
end })

-- ================================ TAB: SETTINGS ================================
local TabSet = Window:Tab({ Title = "Settings", Icon = "panels-top-left" })

TabSet:Section({ Title = "🎨 Theme", Icon = "palette", Box = true }):Dropdown({ Title = "UI Theme", Values = { "Dark", "Light", "Rose", "Sky", "Emerald", "Violet", "Red", "Amber", "Indigo", "Midnight", "Crimson" }, Default = "Crimson", Callback = function(v) WindUI:SetTheme(v) end })

-- UI SIZE LIVE RESIZE
local secUIScale = TabSet:Section({ Title = "UI Size (Live)", Icon = "maximize-2", Box = true })
local currentScale = UI_SCALE
secUIScale:Slider({
    Title = "UI Scale",
    Desc = "Live resize — sekecil yang kau mau",
    Step = 0.05,
    Value = { Min = 0.3, Max = 1.5, Default = UI_SCALE },
    Callback = function(v)
        currentScale = v
        forceResizeWindow(v)
    end
})
secUIScale:Button({
    Title = "Reset UI Size",
    Callback = function()
        currentScale = UI_SCALE
        forceResizeWindow(UI_SCALE)
        notify("UI Scale", "Reset ke " .. UI_SCALE .. "x", 1.5, "maximize-2")
    end
})

-- FILE MANAGEMENT
local secFile = TabSet:Section({ Title = "File Management", Icon = "folder", Box = true })
local cfgName = "XKID_Config_V3"; local currentConfig = "No config"
secFile:Input({ Title = "Config Name", Value = "XKID_Config_V3", Callback = function(v) cfgName = v end })
local function saveConfig() if executor.has_writefile then pcall(function() if not isfolder("XKID_HUB") then makefolder("XKID_HUB") end; local d = { Move = { ws = State.Move.ws, jp = State.Move.jp, flyS = State.Move.flyS }, ESP = { maxDrawDistance = State.ESP.maxDrawDistance, highlightMode = State.ESP.highlightMode }, Security = { shiftLock = State.Security.shiftLock }, HardFling = { power = State.HardFling.power }, SelfSpec = { mode = SS.mode, radius = SS.radius, height = SS.height, speed = SS.speed, distanceMult = SS.distanceMult, heightOffset = SS.heightOffset }, AutoLike = { radius = State.AutoLike.radius, minCD = State.AutoLike.minCD, maxCD = State.AutoLike.maxCD }, CustomFilter = { tintR = State.CustomFilter.tintR, tintG = State.CustomFilter.tintG, tintB = State.CustomFilter.tintB, saturation = State.CustomFilter.saturation, contrast = State.CustomFilter.contrast, brightness = State.CustomFilter.brightness, exposure = State.CustomFilter.exposure, bloomIntensity = State.CustomFilter.bloomIntensity, bloomSize = State.CustomFilter.bloomSize, clockTime = State.CustomFilter.clockTime, shade = State.CustomFilter.shade, warmth = State.CustomFilter.warmth, vignette = State.CustomFilter.vignette } }; writefile("XKID_HUB/" .. cfgName .. ".json", HttpService:JSONEncode(d)); notify("Config", "Saved: " .. cfgName, 2, "save") end) else notify("Config", "Executor tidak support save file", 2, "circle-alert") end end
local function loadConfig(selected) if selected == "No config" then return end; pcall(function() if executor.has_readfile and isfile and isfile("XKID_HUB/" .. selected .. ".json") then local d = HttpService:JSONDecode(readfile("XKID_HUB/" .. selected .. ".json")); if d then if d.Move then State.Move.ws = d.Move.ws or 16; State.Move.jp = d.Move.jp or 50; State.Move.flyS = d.Move.flyS or 60; local h = getHum(); if h then h.WalkSpeed = State.Move.ws; h.UseJumpPower = true; h.JumpPower = State.Move.jp end end; if d.ESP then State.ESP.maxDrawDistance = d.ESP.maxDrawDistance or 300; State.ESP.highlightMode = d.ESP.highlightMode or false end; if d.Security and d.Security.shiftLock ~= State.Security.shiftLock then toggleShiftLock(d.Security.shiftLock) end; if d.HardFling then State.HardFling.power = d.HardFling.power or 10000 end; if d.SelfSpec then SS.mode = d.SelfSpec.mode or "Orbit 360"; SS.radius = d.SelfSpec.radius or 8; SS.height = d.SelfSpec.height or 3; SS.speed = d.SelfSpec.speed or 1; SS.distanceMult = d.SelfSpec.distanceMult or 1; SS.heightOffset = d.SelfSpec.heightOffset or 0 end; if d.AutoLike then State.AutoLike.radius = d.AutoLike.radius or 100; State.AutoLike.minCD = d.AutoLike.minCD or 2; State.AutoLike.maxCD = d.AutoLike.maxCD or 6 end; if d.CustomFilter then for k, v in pairs(d.CustomFilter) do State.CustomFilter[k] = v end; applyCustomFilter() end; notify("Config", "Loaded: " .. selected, 2, "folder-open") end end end) end
secFile:Button({ Title = "Save Config", Callback = saveConfig })
local configDrop = secFile:Dropdown({ Title = "Load Config", Values = getConfigList(), Callback = function(selected) currentConfig = selected; loadConfig(selected) end })
secFile:Button({ Title = "Delete Config", Callback = function() if currentConfig ~= "No config" and currentConfig ~= "" and executor.has_listfiles then pcall(function() if isfile and delfile and isfile("XKID_HUB/" .. currentConfig .. ".json") then delfile("XKID_HUB/" .. currentConfig .. ".json"); pcall(function() configDrop:Refresh(getConfigList(), true) end); currentConfig = "No config"; notify("Config", "Deleted", 2, "trash-2") end end) end end })
secFile:Button({ Title = "Refresh Files", Callback = function() pcall(function() configDrop:Refresh(getConfigList(), true) end); notify("Config", "Files refreshed", 1.5, "folder") end })

-- ================================ INIT ================================
getgenv()._XKID_UI_LOADING = false
notify("System", "XKID_HUB V3.37 AKTIF — NoClip Aggressive + UI Live Resize", 3, "rocket")