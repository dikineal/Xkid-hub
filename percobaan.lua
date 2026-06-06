-- @XKID SCRIPT V3.8 (FINAL: Lock Position + Emote Ready)
-- by @WTF.XKID | Roblox Build For Mobile/PC | Tested on Delta X
-- Changelog V3.8:
-- - FIX: Karakter LOCK posisi (tidak turun/tidak terbang) saat freecam ON
-- - FIX: Emote/Dance TETAP BISA dilakukan saat freecam aktif
-- - FIX: Tidak pakai PlatformStand (biar animasi tetap jalan)
-- - Debug Log tetap hanya mencatat ERROR/BUG

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
    warn("[XKID] Executor tidak support writefile. Config tidak akan tersimpan.")
end

-- ================================ HTTP REQUEST ================================
local function httpRequest(options)
    local syn_req = syn and syn.request
    local fluxus_req = fluxus and fluxus.request
    local http_req = http and http.request
    local request_func = http_request or request or syn_req or fluxus_req or http_req

    if not request_func then
        local httpService = game:GetService("HttpService")
        return { StatusCode = 200, Body = httpService:GetAsync(options.Url, true), Success = true }
    end
    return request_func(options)
end
getgenv()._XKID_REQUEST = httpRequest

-- ================================ FPS UNLOCKER ================================
local function setOptimalFPS(targetFPS)
    targetFPS = targetFPS or 120
    pcall(function() if setfpscap then setfpscap(targetFPS) end end)
    pcall(function()
        local rs = settings():GetService("Rendering")
        if rs and rs.SetTargetFrameRate then rs:SetTargetFrameRate(targetFPS) end
    end)
    pcall(function()
        local ws = game:GetService("Workspace")
        if ws and ws.SetTargetFrameRate then ws:SetTargetFrameRate(targetFPS) end
    end)
end
setOptimalFPS(120)

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
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local onMobile = not UserInputService.KeyboardEnabled

getgenv()._XKID_UI_LOADING = true

-- ================================ ORIGINAL LIGHTING ================================
local originalLighting = {
    ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows,
    ExposureCompensation = Lighting.ExposureCompensation, FogEnd = Lighting.FogEnd,
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
        for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" then v:Destroy() end end
        if getgenv()._XKID_CONNS then for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end end
    end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDFreecam") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDFly") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDSpec") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDSelfSpec") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDShiftLock") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDAutoWalk") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDFreecamLock") end)
end

getgenv()._XKID_LOADED = true
getgenv()._XKID_RUNNING = true
getgenv()._XKID_CONNS = {}

local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

-- ================================ DEBUG LOG SYSTEM (ERROR ONLY) ================================
local DebugLog = {}
local function addLog(msg, level)
    if level ~= "ERROR" and level ~= "BUG" then return end
    local e = string.format("[%s] [%s] %s", os.date("%H:%M:%S"), level, msg)
    table.insert(DebugLog, e)
    if #DebugLog > 100 then table.remove(DebugLog, 1) end
end

local function notify(title, content, duration, icon)
    pcall(function() WindUI:Notify({ Title = title, Content = content, Duration = duration or 2, Icon = icon or "bell" }) end)
end

-- ================================ STATE ================================
local State = {
    Move = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60, autoWalk = false, autoWalkSpeed = 16 },
    Fly = { active = false, bv = nil, bg = nil, _keys = {} },
    HardFling = { active = false, power = 10000, mode = "Spin", currentPower = 0, rampUpActive = false },
    Security = { afkActive = false, shiftLock = false, shiftLockGyro = nil, antiLag = false },
    Cinema = { hideUI = false, cachedGuis = {} },
    Avatar = { isRefreshing = false },
    Utility = { chatLog = false, chatTargets = {}, chatHistory = {} },
    AutoLike = { active = false, thread = nil, lastTarget = nil, count = 0, radius = 100, minCD = 2, maxCD = 6 },
    CustomFilter = { tintR = 255, tintG = 255, tintB = 255, saturation = 0, contrast = 0, brightness = 0, exposure = 0, bloomIntensity = 0, bloomSize = 24, clockTime = 14 },
    SelfSpec = { active = false, mode = "Manual", dist = 8, height = 3, orbitYaw = 0, orbitPitch = 20, fov = 70, origFov = 70, roll = 0, radius = 8, speed = 1 },
    ESP = {
        active = false, cache = getgenv()._XKID_ESP_CACHE, maxDrawDistance = 300, highlightMode = false,
        boxColor_N = Color3.fromRGB(255, 0, 0), boxColor_S = Color3.fromRGB(220, 20, 60), boxColor_G = Color3.fromRGB(255, 165, 0),
        tracerColor_N = Color3.fromRGB(255, 0, 0), tracerColor_S = Color3.fromRGB(220, 20, 60), tracerColor_G = Color3.fromRGB(255, 165, 0),
        nameColor = Color3.fromRGB(255, 255, 255)
    },
    Spec = { active = false, target = nil, mode = "third", dist = 8, origFov = 70, orbitYaw = 0, orbitPitch = 0, isSelf = false },
    FPS = { cap = 120 }
}

local colorMap = {
    Merah = Color3.fromRGB(255, 0, 0), Hijau = Color3.fromRGB(0, 255, 0), Biru = Color3.fromRGB(0, 0, 255),
    Kuning = Color3.fromRGB(255, 255, 0), Ungu = Color3.fromRGB(255, 0, 255), Cyan = Color3.fromRGB(0, 255, 255),
    Orange = Color3.fromRGB(255, 165, 0), Pink = Color3.fromRGB(255, 105, 180), Putih = Color3.fromRGB(255, 255, 255),
    Hitam = Color3.fromRGB(0, 0, 0), Crimson = Color3.fromRGB(220, 20, 60),
    Dark = Color3.fromRGB(20, 20, 25), Light = Color3.fromRGB(240, 240, 245),
    Navy = Color3.fromRGB(15, 15, 35), Charcoal = Color3.fromRGB(30, 30, 35)
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
    local m = math.floor(seconds / 60); local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

local function makeBar(val, maxVal, len)
    local fill = math.clamp(math.floor((val / maxVal) * len), 0, len)
    return string.rep("█", fill) .. string.rep("░", len - fill)
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

local function isUserActive()
    if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.MouseButton1) then return true end
    if onMobile then if #UserInputService:GetTouchPositions() > 0 then return true end end
    local hrp, hum = getRoot(), getHum(); if hrp and hum and hum.MoveDirection.Magnitude > 0.1 then return true end
    return false
end

-- ================================ GLOBAL VARS ================================
local START_TIME = os.time(); local cachedMapName = nil; local lastMapCheck = 0; local sharedFPS = 60; local sharedPing = 0

-- ================================ FPS & PING TRACKER ================================
TrackC(RunService.RenderStepped:Connect(function(dt) if dt > 0 then sharedFPS = math.floor(1 / dt) end end))

task.spawn(function()
    while getgenv()._XKID_RUNNING do task.wait(0.5); pcall(function() local item = StatsService.Network.ServerStatsItem["Data Ping"]; if item then sharedPing = math.floor(item:GetValue()) end end) end
end)

task.spawn(function()
    while getgenv()._XKID_RUNNING do pcall(function() if tick() - lastMapCheck > 30 or not cachedMapName then cachedMapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name; lastMapCheck = tick() end end); task.wait(5) end
end)

task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(120); collectgarbage("collect") end end)
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(30); setOptimalFPS(State.FPS.cap) end end)
TrackC(LP.CharacterAdded:Connect(function() task.wait(0.5); setOptimalFPS(State.FPS.cap) end))

-- ================================ ANTI AFK (STEALTH) ================================
local VIM = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil
local AFKSystem = { active = false, thread = nil, lastActive = 0 }

local function sendStealthAntiAFK()
    if FC and FC.active then return end
    if VirtualUser and VirtualUser.ClickButton2 then pcall(function() local vp = Camera.ViewportSize; VirtualUser:ClickButton2(Vector2.new(vp.X - 5, vp.Y - 5)) end); return end
    if VIM and VIM.SendMouseButtonEvent then pcall(function() local vp = Camera.ViewportSize; VIM:SendMouseButtonEvent(vp.X - 5, vp.Y - 5, 0, true, game, 0); task.wait(0.05); VIM:SendMouseButtonEvent(vp.X - 5, vp.Y - 5, 0, false, game, 0) end); return end
    pcall(function() local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if remotes then local sr = remotes:FindFirstChild("Ping") or remotes:FindFirstChild("Heartbeat"); if sr and sr.FireServer then sr:FireServer(); return end end end)
    pcall(function() local cf = Camera.CFrame; Camera.CFrame = cf * CFrame.Angles(0, math.rad(0.5), 0); task.wait(0.05); Camera.CFrame = cf end)
end

local function startAFK()
    if AFKSystem.active then return end; AFKSystem.active = true; State.Security.afkActive = true; AFKSystem.lastActive = tick()
    AFKSystem.thread = task.spawn(function() while AFKSystem.active do task.wait(10); if not AFKSystem.active then break end; if isUserActive() then AFKSystem.lastActive = tick() elseif tick() - AFKSystem.lastActive >= 420 then sendStealthAntiAFK(); AFKSystem.lastActive = tick() end end end)
    notify("Anti AFK", "ON (Stealth)", 1.5, "shield-check")
end

local function stopAFK()
    AFKSystem.active = false; State.Security.afkActive = false
    if AFKSystem.thread then task.cancel(AFKSystem.thread); AFKSystem.thread = nil end
    notify("Anti AFK", "OFF", 1.5, "shield-check")
end

function ToggleAntiAFK() if AFKSystem.active then stopAFK() else startAFK() end end

-- ================================ SHIFT LOCK ================================
TrackC(LP.CharacterAdded:Connect(function(char)
    task.wait(0.5); local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end; if State.Move.jp ~= 50 then hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end end
    if State.Security.shiftLock then task.wait(0.2); local hrp = getRoot()
        if hrp then if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() end; State.Security.shiftLockGyro = Instance.new("BodyGyro", hrp); State.Security.shiftLockGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); State.Security.shiftLockGyro.P = 50000; State.Security.shiftLockGyro.D = 1000 end
    end
end))

local function toggleShiftLock(v)
    State.Security.shiftLock = v
    if v then local hrp = getRoot()
        if hrp then if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() end; State.Security.shiftLockGyro = Instance.new("BodyGyro", hrp); State.Security.shiftLockGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); State.Security.shiftLockGyro.P = 50000; State.Security.shiftLockGyro.D = 1000 end
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
        newHrp.CFrame = pendingRefreshCF + Vector3.new(0, 4, 0); newHrp.AssemblyLinearVelocity = Vector3.zero; newHrp.AssemblyAngularVelocity = Vector3.zero
        newHum.WalkSpeed = pendingRefreshWS; newHum.UseJumpPower = true; newHum.JumpPower = pendingRefreshJP
        Camera.CameraSubject = newHum; Camera.CameraType = Enum.CameraType.Custom; pcall(function() LP.CameraMaxZoomDistance = pendingRefreshZoom end)
        notify("Refresh", "Done", 2, "check-circle")
    end
    State.Avatar.isRefreshing = false; pendingRefreshCF = nil
end))

-- ================================ SMART TP ================================
local Teleport = { clickConn = nil, clickActive = false, toolActive = false, tool = nil }

local function executeTP() local hrp = getRoot(); if not hrp then return end; local m = LP:GetMouse(); if m.Hit then hrp.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3.5, 0)); hrp.AssemblyLinearVelocity = Vector3.zero end end

local function toggleSmartTP(v)
    Teleport.clickActive = v
    if v then pcall(function() local t = Instance.new("Tool"); t.Name = "TP Tool"; t.RequiresHandle = false; t.Parent = LP.Backpack; Teleport.tool = t; Teleport.toolActive = false; t.Activated:Connect(function() Teleport.toolActive = not Teleport.toolActive end) end)
        Teleport.clickConn = TrackC(UserInputService.InputBegan:Connect(function(inp, gp) if gp then return end; if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then if Teleport.toolActive then executeTP(); Teleport.toolActive = false end end end))
        notify("Smart TP", "ON", 2, "map-pin")
    else if Teleport.clickConn then Teleport.clickConn:Disconnect(); Teleport.clickConn = nil end; pcall(function() if Teleport.tool then Teleport.tool:Destroy(); Teleport.tool = nil end end); Teleport.toolActive = false; notify("Smart TP", "OFF", 1.5, "map-pin") end
end

-- ================================ AUTO WALK ================================
local function startAutoWalk()
    RunService:UnbindFromRenderStep("XKIDAutoWalk"); State.Move.autoWalk = true; local hum = getHum(); if hum then hum.WalkSpeed = State.Move.autoWalkSpeed end
    RunService:BindToRenderStep("XKIDAutoWalk", Enum.RenderPriority.Character.Value + 1, function() if not State.Move.autoWalk then return end; local hrp, hum2 = getRoot(), getHum(); if not hrp or not hum2 then return end; if hum2.MoveDirection.Magnitude > 0.1 then return end; local camDir = Camera.CFrame.LookVector; local moveDir = Vector3.new(camDir.X, 0, camDir.Z).Unit; hrp.CFrame = hrp.CFrame + moveDir * (State.Move.autoWalkSpeed / 60) end)
    notify("Auto Walk", "ON", 1.5, "play")
end

local function stopAutoWalk() RunService:UnbindFromRenderStep("XKIDAutoWalk"); State.Move.autoWalk = false; local hum = getHum(); if hum then hum.WalkSpeed = State.Move.ws end; notify("Auto Walk", "OFF", 1.5, "play") end

-- ================================ ESP ENGINE ================================
local function initPlayerCache(player)
    if State.ESP.cache[player] then return end
    local cache = { texts = nil, tracer = nil, boxLines = {}, hl = nil, isSuspect = false, isGlitch = false, reason = "" }
    pcall(function()
        cache.texts = Drawing.new("Text"); if cache.texts then cache.texts.Center = true; cache.texts.Outline = true; cache.texts.Font = 2; cache.texts.Size = 13; cache.texts.ZIndex = 2 end
        cache.tracer = Drawing.new("Line"); if cache.tracer then cache.tracer.Thickness = 1.5; cache.tracer.ZIndex = 1 end
        for i = 1, 4 do local line = Drawing.new("Line"); if line then line.Thickness = 1.5; line.ZIndex = 1; cache.boxLines[i] = line end end
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
            table.sort(tempSorted, function(a, b) return a.dist < b.dist end); espsortedPlayers = tempSorted
        end; task.wait(0.5)
    end
end)

TrackC(RunService.RenderStepped:Connect(function()
    if not State.ESP.active then return end; local myHrp = getCharRoot(LP.Character); if not myHrp then return end
    local vp = Camera.ViewportSize; local center = Vector2.new(vp.X / 2, vp.Y / 2)
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
            if c.tracer then local origin = Vector2.new(vp.X / 2, vp.Y); c.tracer.From = origin; c.tracer.To = Vector2.new(rootPos.X, rootPos.Y); c.tracer.Color = tColor; c.tracer.Visible = true end
        end)
        if useHl and hlCount < 30 then hlCount = hlCount + 1
            pcall(function() local top, tv = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)); local bot, bv = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0)); if tv and bv and #c.boxLines == 4 then local bh = math.abs(top.Y - bot.Y); local bw = bh * 0.6; c.boxLines[1].From = Vector2.new(rootPos.X - bw / 2, top.Y); c.boxLines[1].To = Vector2.new(rootPos.X + bw / 2, top.Y); c.boxLines[2].From = Vector2.new(rootPos.X + bw / 2, top.Y); c.boxLines[2].To = Vector2.new(rootPos.X + bw / 2, bot.Y); c.boxLines[3].From = Vector2.new(rootPos.X + bw / 2, bot.Y); c.boxLines[3].To = Vector2.new(rootPos.X - bw / 2, bot.Y); c.boxLines[4].From = Vector2.new(rootPos.X - bw / 2, bot.Y); c.boxLines[4].To = Vector2.new(rootPos.X - bw / 2, top.Y); for i = 1, 4 do c.boxLines[i].Color = bColor; c.boxLines[i].Visible = true end end end)
            pcall(function() if not c.hl or c.hl.Parent ~= char then if c.hl then c.hl:Destroy() end; c.hl = Instance.new("Highlight", char); c.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end; if c.hl then c.hl.FillColor = bColor; c.hl.OutlineColor = Color3.new(1, 1, 1); c.hl.Enabled = true end end)
        end
    end
end))

-- ================================ FLY ENGINE ================================
local flyMoveTouch, flyMoveSt, flyJoy, flyConns = nil, nil, Vector2.zero, {}
local flyVel = Vector3.zero

local function startFlyCapture()
    local keysHeld = {}
    table.insert(flyConns, UserInputService.InputBegan:Connect(function(inp, gp) if gp then return end; local k = inp.KeyCode; if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then keysHeld[k] = true end end))
    table.insert(flyConns, UserInputService.InputEnded:Connect(function(inp) keysHeld[inp.KeyCode] = nil end))
    table.insert(flyConns, UserInputService.InputBegan:Connect(function(inp, gp) if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp.Position.X <= Camera.ViewportSize.X / 2 then if not flyMoveTouch then flyMoveTouch = inp; flyMoveSt = inp.Position end end end))
    table.insert(flyConns, UserInputService.TouchMoved:Connect(function(inp) if inp == flyMoveTouch and flyMoveSt then local dx = inp.Position.X - flyMoveSt.X; local dy = inp.Position.Y - flyMoveSt.Y; local function ad(v, d, m) if math.abs(v) < d then return 0 end; return math.clamp((v - math.sign(v) * d) / (m - d), -1, 1) end; flyJoy = Vector2.new(ad(dx, 25, 80), ad(dy, 20, 80)) end end))
    table.insert(flyConns, UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp == flyMoveTouch then flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero end end))
    State.Fly._keys = keysHeld
end

local function stopFlyCapture() for _, c in ipairs(flyConns) do c:Disconnect() end; flyConns = {}; flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero; State.Fly._keys = {} end

local function toggleFly(v)
    if not v then 
        State.Fly.active = false; stopFlyCapture(); RunService:UnbindFromRenderStep("XKIDFly"); 
        pcall(function() if State.Fly.bv then State.Fly.bv:Destroy() end end); 
        pcall(function() if State.Fly.bg then State.Fly.bg:Destroy() end end); 
        State.Fly.bv = nil; State.Fly.bg = nil; flyVel = Vector3.zero; 
        local hum = getHum(); 
        if hum then 
            hum.PlatformStand = false; 
            hum:ChangeState(Enum.HumanoidStateType.GettingUp); 
            hum.WalkSpeed = State.Move.ws; 
            hum.UseJumpPower = true; 
            hum.JumpPower = State.Move.jp; 
            hum.AutoRotate = true 
        end; 
        notify("Fly", "OFF", 1.5, "bird"); 
        return 
    end
    local hrp, hum = getRoot(), getHum(); 
    if not hrp or not hum then return end; 
    State.Fly.active = true; 
    hum.PlatformStand = true; 
    flyVel = Vector3.zero; 
    hum.AutoRotate = false
    State.Fly.bv = Instance.new("BodyVelocity", hrp); 
    State.Fly.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); 
    State.Fly.bg = Instance.new("BodyGyro", hrp); 
    State.Fly.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); 
    State.Fly.bg.P = 50000
    startFlyCapture(); 
    notify("Fly", "ON", 2, "bird")
    RunService:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value + 1, function() 
        if not State.Fly.active then return end; 
        local r = getRoot(); 
        if not r then return end; 
        local camCF = Camera.CFrame; 
        local spd = State.Move.flyS; 
        local move = Vector3.zero; 
        local keys = State.Fly._keys or {}; 
        if onMobile then 
            move = camCF.LookVector * (-flyJoy.Y) + camCF.RightVector * flyJoy.X 
        else 
            if keys[Enum.KeyCode.W] then move = move + camCF.LookVector end; 
            if keys[Enum.KeyCode.S] then move = move - camCF.LookVector end; 
            if keys[Enum.KeyCode.D] then move = move + camCF.RightVector end; 
            if keys[Enum.KeyCode.A] then move = move - camCF.RightVector end; 
            if keys[Enum.KeyCode.E] then move = move + Vector3.new(0, 1, 0) end; 
            if keys[Enum.KeyCode.Q] then move = move - Vector3.new(0, 1, 0) end 
        end; 
        if move.Magnitude > 0 then 
            flyVel = flyVel:Lerp(move.Unit * spd, 0.15) 
        else 
            flyVel = flyVel:Lerp(isOnGround() and Vector3.zero or Vector3.new(0, -0.8, 0), 0.08) 
        end; 
        if State.Fly.bv and State.Fly.bv.Parent then State.Fly.bv.Velocity = flyVel end; 
        if State.Fly.bg and State.Fly.bg.Parent then State.Fly.bg.CFrame = CFrame.new(r.Position, r.Position + camCF.LookVector) end 
    end)
end

-- ================================ FREECAM ENGINE (V3.8 - LOCK POSITION + EMOTE READY) ================================
local FC = { active = false, pos = Vector3.zero, pitchDeg = 0, yawDeg = 0, rollDeg = 0, speed = 3, sens = 0.25, origFov = 70, savedWalkSpeed = 16, savedJumpPower = 50 }
local I_CamVel, I_YawVel, I_PitchVel, I_RollVel, heightVelocity = Vector3.zero, 0, 0, 0, 0
local fcMoveTouch, fcMoveSt, fcJoy, fcRotTouch, fcRotLast, fcKeysHeld, fcConns = nil, nil, Vector2.zero, nil, nil, {}, {}
local FC_UI_Btns = { up = false, down = false, rollLeft = false, rollRight = false, zoomIn = false, zoomOut = false }
local FC_UI_Hidden = false; local fcButtons = {}

-- Lock position variables
local freecamLockBP = nil
local freecamLockBG = nil
local lockedPos = nil
local lockedCF = nil
local lockRenderStepConnected = false

local FCUI = Instance.new("ScreenGui"); FCUI.Name = "XKID_FreecamUI"; FCUI.ResetOnSpawn = false; FCUI.ZIndexBehavior = Enum.ZIndexBehavior.Global; FCUI.Enabled = false; FCUI.Parent = CoreGui; getgenv()._XKID_FCUI = FCUI

local function makeFCBtn(name, txt, pos, actionKey)
    local b = Instance.new("TextButton", FCUI); b.Name = name; b.Size = UDim2.new(0, 44, 0, 44); b.Position = pos; b.BackgroundColor3 = Color3.fromRGB(15, 15, 15); b.BackgroundTransparency = 0.4; b.Text = txt; b.TextColor3 = Color3.fromRGB(255, 255, 255); b.TextSize = 18; b.Font = Enum.Font.GothamBold; b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10); local uis = Instance.new("UIStroke", b); uis.Color = Color3.fromRGB(220, 20, 60); uis.Thickness = 2; uis.Transparency = 0.3
    local indicator = Instance.new("Frame", b); indicator.Name = "Indicator"; indicator.Size = UDim2.new(0, 6, 0, 6); indicator.Position = UDim2.new(0, 4, 0, 4); indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 60); Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    local function press(down) FC_UI_Btns[actionKey] = down; b.BackgroundTransparency = down and 0.05 or 0.4; indicator.BackgroundColor3 = down and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(60, 60, 60) end
    b.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then press(true) end end)
    b.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then press(false) end end)
    b.MouseLeave:Connect(function() press(false) end); table.insert(fcButtons, b); return b
end

makeFCBtn("BtnRollL", "L", UDim2.new(1, -156, 0.5, -66), "rollLeft"); makeFCBtn("BtnRollR", "R", UDim2.new(1, -58, 0.5, -66), "rollRight")
makeFCBtn("BtnUp", "↑", UDim2.new(1, -107, 0.5, -110), "up"); makeFCBtn("BtnDown", "↓", UDim2.new(1, -107, 0.5, -22), "down")
makeFCBtn("BtnZIn", "+", UDim2.new(1, -156, 0.5, -22), "zoomIn"); makeFCBtn("BtnZOut", "-", UDim2.new(1, -58, 0.5, -22), "zoomOut")

local eyeBtn = Instance.new("TextButton", FCUI); eyeBtn.Name = "BtnEye"; eyeBtn.Size = UDim2.new(0, 44, 0, 44); eyeBtn.Position = UDim2.new(1, -107, 0.5, -66); eyeBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15); eyeBtn.BackgroundTransparency = 0.6; eyeBtn.Text = "👁"; eyeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); eyeBtn.TextSize = 18; eyeBtn.Font = Enum.Font.GothamBold; eyeBtn.AutoButtonColor = false
Instance.new("UICorner", eyeBtn).CornerRadius = UDim.new(0, 10); local eyeStroke = Instance.new("UIStroke", eyeBtn); eyeStroke.Color = Color3.fromRGB(220, 20, 60); eyeStroke.Thickness = 2; eyeStroke.Transparency = 0.5

local function toggleFCEye() FC_UI_Hidden = not FC_UI_Hidden; eyeBtn.Text = FC_UI_Hidden and "👁‍🗨" or "👁"; for _, b in ipairs(fcButtons) do b.Visible = not FC_UI_Hidden end end
eyeBtn.MouseButton1Click:Connect(toggleFCEye); eyeBtn.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch then toggleFCEye() end end)

local function startFreecamCapture()
    fcKeysHeld = {}
    table.insert(fcConns, UserInputService.InputBegan:Connect(function(inp, gp) if gp then return end; fcKeysHeld[inp.KeyCode] = true; if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mr = true; UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition end end))
    table.insert(fcConns, UserInputService.InputEnded:Connect(function(inp) fcKeysHeld[inp.KeyCode] = false; if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mr = false; UserInputService.MouseBehavior = Enum.MouseBehavior.Default end end))
    table.insert(fcConns, UserInputService.InputChanged:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseMovement and FC._mr then I_YawVel = I_YawVel - inp.Delta.X * FC.sens * 120; I_PitchVel = I_PitchVel - inp.Delta.Y * FC.sens * 120 end end))
    table.insert(fcConns, UserInputService.InputBegan:Connect(function(inp, gp) if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp.Position.X > Camera.ViewportSize.X / 2 then if not fcRotTouch then fcRotTouch = inp; fcRotLast = inp.Position end else if not fcMoveTouch then fcMoveTouch = inp; fcMoveSt = inp.Position; fcJoy = Vector2.zero end end end))
    table.insert(fcConns, UserInputService.TouchMoved:Connect(function(inp) if inp == fcRotTouch and fcRotLast then local dx = inp.Position.X - fcRotLast.X; local dy = inp.Position.Y - fcRotLast.Y; fcRotLast = inp.Position; I_YawVel = I_YawVel - dx * FC.sens * 80; I_PitchVel = I_PitchVel - dy * FC.sens * 80 end; if inp == fcMoveTouch and fcMoveSt then local dx = inp.Position.X - fcMoveSt.X; local dy = inp.Position.Y - fcMoveSt.Y; local function ad(v, d, m) if math.abs(v) < d then return 0 end; return math.clamp((v - math.sign(v) * d) / (m - d), -1, 1) end; fcJoy = Vector2.new(ad(dx, 15, 70), ad(dy, 15, 70)) end end))
    table.insert(fcConns, UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp == fcRotTouch then fcRotTouch = nil; fcRotLast = nil end; if inp == fcMoveTouch then fcMoveTouch = nil; fcMoveSt = nil; fcJoy = Vector2.zero end end))
end

local function stopFreecamCapture() for _, c in ipairs(fcConns) do c:Disconnect() end; fcConns = {}; fcKeysHeld = {}; FC._mr = false; UserInputService.MouseBehavior = Enum.MouseBehavior.Default end

-- V3.8: Lock position WITHOUT breaking emote
local function lockCharacterPosition(lock)
    local hrp = getRoot()
    local hum = getHum()
    
    if lock then
        if hrp then
            -- Simpan posisi dan rotasi AWAL
            lockedPos = hrp.Position
            lockedCF = hrp.CFrame
            
            -- BodyPosition untuk lock posisi (cegah turun/terbang)
            freecamLockBP = Instance.new("BodyPosition", hrp)
            freecamLockBP.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            freecamLockBP.P = 50000
            freecamLockBP.D = 5000
            freecamLockBP.Position = lockedPos
            
            -- BodyGyro untuk lock rotasi (biar tidak muter sendiri)
            freecamLockBG = Instance.new("BodyGyro", hrp)
            freecamLockBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            freecamLockBG.P = 50000
            freecamLockBG.CFrame = lockedCF
            
            -- Zero-kan velocity
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        
        if hum then
            -- SIMPAN setting asli
            FC.savedWalkSpeed = hum.WalkSpeed
            FC.savedJumpPower = hum.JumpPower
            
            -- JANGAN set PlatformStand = true (biar emote jalan)
            -- JANGAN set AutoRotate = false
            -- Cuma kecilkan walk speed (tapi posisi tetap lock karena BodyPosition)
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            -- Biarkan AutoRotate tetap true agar emote bisa rotate
        end
        
        -- Render step untuk menjaga posisi tetap
        if not lockRenderStepConnected then
            RunService:BindToRenderStep("XKIDFreecamLock", Enum.RenderPriority.Last.Value, function()
                if not FC.active then return end
                local currentHrp = getRoot()
                if currentHrp and lockedPos then
                    -- Refresh posisi BodyPosition
                    if freecamLockBP then
                        freecamLockBP.Position = lockedPos
                    end
                    if freecamLockBG and lockedCF then
                        freecamLockBG.CFrame = lockedCF
                    end
                    -- Zero-kan velocity setiap frame (cegah drift)
                    currentHrp.AssemblyLinearVelocity = Vector3.zero
                    currentHrp.AssemblyAngularVelocity = Vector3.zero
                    -- Cek posisi Y, kalau meleset sedikit, koreksi
                    local currentPos = currentHrp.Position
                    if math.abs(currentPos.Y - lockedPos.Y) > 0.05 then
                        currentHrp.CFrame = CFrame.new(lockedPos.X, lockedPos.Y, lockedPos.Z) * CFrame.Angles(0, currentHrp.Orientation.Y, 0)
                    end
                end
            end)
            lockRenderStepConnected = true
        end
    else
        -- UNLOCK: hapus semua
        if freecamLockBP then
            freecamLockBP:Destroy()
            freecamLockBP = nil
        end
        if freecamLockBG then
            freecamLockBG:Destroy()
            freecamLockBG = nil
        end
        if lockRenderStepConnected then
            RunService:UnbindFromRenderStep("XKIDFreecamLock")
            lockRenderStepConnected = false
        end
        
        local currentHrp = getRoot()
        local currentHum = getHum()
        
        if currentHum then
            currentHum.WalkSpeed = FC.savedWalkSpeed
            currentHum.JumpPower = FC.savedJumpPower
            -- AutoRotate sudah true dari awal
        end
        
        if currentHrp then
            currentHrp.AssemblyLinearVelocity = Vector3.zero
            currentHrp.AssemblyAngularVelocity = Vector3.zero
        end
        
        lockedPos = nil
        lockedCF = nil
    end
end

local function startFreecamLoop()
    RunService:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt) 
        if not FC.active then return end
        
        Camera.CameraType = Enum.CameraType.Scriptable
        local safeDt = math.clamp(dt, 0.001, 0.05)
        I_YawVel = I_YawVel * math.max(0, 1 - safeDt * 14)
        I_PitchVel = I_PitchVel * math.max(0, 1 - safeDt * 14)
        FC.yawDeg = FC.yawDeg + I_YawVel * safeDt
        FC.pitchDeg = math.clamp(FC.pitchDeg + I_PitchVel * safeDt, -80, 80)
        local rollTarget = 0
        if FC_UI_Btns.rollLeft then rollTarget = -100 elseif FC_UI_Btns.rollRight then rollTarget = 100 end
        I_RollVel = I_RollVel + (rollTarget - I_RollVel) * math.clamp(safeDt * 5, 0, 1)
        FC.rollDeg = math.clamp(FC.rollDeg + I_RollVel * safeDt, -100, 100)
        local camCF = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local joyX, joyY = fcJoy.X, fcJoy.Y
        if not onMobile then
            if fcKeysHeld[Enum.KeyCode.W] then joyY = joyY - 1 end
            if fcKeysHeld[Enum.KeyCode.S] then joyY = joyY + 1 end
            if fcKeysHeld[Enum.KeyCode.D] then joyX = joyX + 1 end
            if fcKeysHeld[Enum.KeyCode.A] then joyX = joyX - 1 end
        end
        local rawMove = Vector2.new(joyX, joyY)
        if rawMove.Magnitude > 1 then rawMove = rawMove.Unit end
        I_CamVel = I_CamVel:Lerp((camCF.LookVector * (-rawMove.Y) + camCF.RightVector * rawMove.X) * (FC.speed * 60), math.clamp(safeDt * 3.5, 0, 1))
        local heightTarget = 0
        if fcKeysHeld[Enum.KeyCode.E] or FC_UI_Btns.up then heightTarget = FC.speed * 60 end
        if fcKeysHeld[Enum.KeyCode.Q] or FC_UI_Btns.down then heightTarget = -FC.speed * 60 end
        if heightTarget == 0 then
            heightVelocity = heightVelocity * math.max(0, 1 - safeDt * 10)
        else
            heightVelocity = heightVelocity + (heightTarget - heightVelocity) * math.clamp(safeDt * 3, 0, 1)
        end
        if FC_UI_Btns.zoomIn then Camera.FieldOfView = math.clamp(Camera.FieldOfView - 1.2, 10, 120) end
        if FC_UI_Btns.zoomOut then Camera.FieldOfView = math.clamp(Camera.FieldOfView + 1.2, 10, 120) end
        FC.pos = FC.pos + (I_CamVel + Vector3.new(0, heightVelocity, 0)) * safeDt
        Camera.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0) * CFrame.Angles(0, 0, math.rad(FC.rollDeg))
    end)
end

local function stopFreecamLoop()
    RunService:UnbindFromRenderStep("XKIDFreecam")
end

local function fullCleanupFreecam()
    stopFreecamLoop()
    stopFreecamCapture()
    lockCharacterPosition(false)
    local hum = getHum()
    local hrp = getRoot()
    if hum then
        hum.WalkSpeed = FC.savedWalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = FC.savedJumpPower
        hum.AutoRotate = true
    end
    Camera.CameraType = Enum.CameraType.Custom
    Camera.FieldOfView = FC.origFov
    if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = false end
    for k in pairs(FC_UI_Btns) do FC_UI_Btns[k] = false end
    FC_UI_Hidden = false
    eyeBtn.Text = "👁"
    for _, b in ipairs(fcButtons) do b.Visible = true end
end

local function toggleFreecam(v)
    if v then
        -- Matikan semua fitur yang bisa konflik
        if State.Fly.active then toggleFly(false) end
        if State.Security.shiftLock then toggleShiftLock(false) end
        if State.Move.autoWalk then stopAutoWalk() end
        if State.SelfSpec.active then toggleSelfSpec(false) end
        if State.Spec.active then
            State.Spec.active = false
            stopSpecLoop()
            stopSpecCapture()
        end
        if Teleport.clickConn then
            Teleport.clickConn:Disconnect()
            Teleport.clickConn = nil
        end
        
        FC.active = true
        local cf = Camera.CFrame
        FC.pos = cf.Position
        FC.pitchDeg = 0
        FC.yawDeg = 0
        FC.rollDeg = 0
        I_CamVel = Vector3.zero
        I_YawVel = 0
        I_PitchVel = 0
        I_RollVel = 0
        heightVelocity = 0
        fcJoy = Vector2.zero
        
        -- Lock karakter di posisi saat ini
        lockCharacterPosition(true)
        
        FC.origFov = Camera.FieldOfView
        startFreecamCapture()
        startFreecamLoop()
        if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = true end
        FC_UI_Hidden = false
        eyeBtn.Text = "👁"
        for _, b in ipairs(fcButtons) do b.Visible = true end
        
        if State.Cinema.hideUI then
            FCUI.Enabled = false
        end
        
        notify("Freecam", "ON (Karakter LOCK, Bisa Emote)", 2, "video")
    else
        FC.active = false
        fullCleanupFreecam()
        notify("Freecam", "OFF", 1.5, "video")
    end
end

-- ================================ SELF-SPECTATE ================================
local SS = State.SelfSpec
local ssTM, ssPinch, ssPinchD, ssPan, ssConns = nil, {}, nil, Vector2.zero, {}

local function startSSGesture()
    ssConns = {}
    table.insert(ssConns, UserInputService.InputBegan:Connect(function(inp, gp) if gp or not SS.active or inp.UserInputType ~= Enum.UserInputType.Touch then return end; table.insert(ssPinch, inp); ssTM = #ssPinch == 1 and inp or nil end))
    table.insert(ssConns, UserInputService.InputChanged:Connect(function(inp) if not SS.active or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if #ssPinch == 1 and inp == ssTM then ssPan = ssPan + Vector2.new(inp.Delta.X, inp.Delta.Y) elseif #ssPinch >= 2 then local d = (ssPinch[1].Position - ssPinch[2].Position).Magnitude; if ssPinchD then local diff = d - ssPinchD; Camera.FieldOfView = math.clamp(Camera.FieldOfView - diff * 0.15, 10, 120); SS.radius = math.clamp(SS.radius - diff * 0.03, 3, 30) end; ssPinchD = d end end))
    table.insert(ssConns, UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; for i, v in ipairs(ssPinch) do if v == inp then table.remove(ssPinch, i); break end end; ssPinchD = nil; ssTM = #ssPinch == 1 and ssPinch[1] or nil end))
end

local function stopSSGesture() for _, c in ipairs(ssConns) do c:Disconnect() end; ssConns = {}; ssTM = nil; ssPinch = {}; ssPinchD = nil; ssPan = Vector2.zero end

local function startSelfSpecLoop()
    RunService:UnbindFromRenderStep("XKIDSelfSpec"); RunService:BindToRenderStep("XKIDSelfSpec", Enum.RenderPriority.Camera.Value + 1, function() if not SS.active then return end; pcall(function() local targetChar = LP.Character; local targetHrp = getCharRoot(targetChar); if not targetHrp then return end; Camera.CameraType = Enum.CameraType.Scriptable; local pan, sens = ssPan, onMobile and 0.2 or 0.3; ssPan = Vector2.zero
        if #ssPinch == 0 and pan.Magnitude < 0.01 then
            local dt = 0.016
            if SS.mode == "Slow Orbit" then
                SS.orbitYaw = SS.orbitYaw + dt * 25 * SS.speed
            elseif SS.mode == "Vertical Swing" then
                SS.orbitPitch = 20 + math.sin(tick() * SS.speed * 1.5) * 40
                SS.orbitYaw = SS.orbitYaw + dt * 10 * SS.speed
            elseif SS.mode == "Figure 8" then
                SS.orbitYaw = math.sin(tick() * SS.speed * 0.8) * 80
                SS.orbitPitch = 20 + math.sin(tick() * SS.speed * 1.2) * 35
            elseif SS.mode == "Cinematic Drift" then
                SS.orbitYaw = SS.orbitYaw + dt * 15 * SS.speed
                SS.orbitPitch = 20 + math.sin(tick() * SS.speed * 0.7) * 15
            elseif SS.mode == "Orbit Steady" then
                SS.orbitYaw = SS.orbitYaw + dt * 25 * SS.speed
                SS.orbitPitch = 20
            elseif SS.mode == "Tilt Drift" then
                SS.orbitYaw = SS.orbitYaw + dt * 30 * SS.speed
                SS.orbitPitch = 20 + math.sin(tick() * SS.speed * 0.5) * 10
                SS.roll = math.sin(tick() * SS.speed * 0.8) * 5
            end
        end
        SS.orbitYaw = SS.orbitYaw + pan.X * sens
        SS.orbitPitch = math.clamp(SS.orbitPitch + pan.Y * sens, -75, 75)
        local h = SS.height or 3
        local camCF = CFrame.new((CFrame.new(targetHrp.Position + Vector3.new(0, h, 0)) * CFrame.Angles(0, math.rad(-SS.orbitYaw), 0) * CFrame.Angles(math.rad(-SS.orbitPitch), 0, 0) * CFrame.new(0, 0, SS.radius)).Position, targetHrp.Position + Vector3.new(0, h, 0))
        if SS.mode == "Tilt Drift" then
            camCF = camCF * CFrame.Angles(0, 0, math.rad(SS.roll or 0))
        end
        Camera.CFrame = camCF
    end) end)
end

local function stopSelfSpecLoop() RunService:UnbindFromRenderStep("XKIDSelfSpec"); Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = SS.origFov; SS.active = false; SS.orbitYaw = 0; SS.orbitPitch = 20; SS.radius = 8; SS.height = 3; ssPan = Vector2.zero end

local function toggleSelfSpec(v)
    if v then
        if FC.active then toggleFreecam(false) end
        if State.Fly.active then toggleFly(false) end
        if State.Spec.active then
            State.Spec.active = false
            stopSpecLoop()
            stopSpecCapture()
        end
        if Teleport.clickConn then Teleport.clickConn:Disconnect(); Teleport.clickConn = nil end
        SS.active = true
        SS.origFov = Camera.FieldOfView
        SS.orbitYaw = 0
        SS.orbitPitch = 20
        SS.radius = SS.radius or 8
        SS.height = SS.height or 3
        startSSGesture()
        startSelfSpecLoop()
        notify("Self-Spectate", "ON — " .. (SS.mode or "Manual"), 2, "camera")
    else
        SS.active = false
        stopSSGesture()
        stopSelfSpecLoop()
        notify("Self-Spectate", "OFF", 1.5, "camera")
    end
end

-- ================================ SPECTATE ================================
local specTM, specPinch, specPinchD, specPan, specConns = nil, {}, nil, Vector2.zero, {}

local function startSpecCapture()
    table.insert(specConns, UserInputService.InputBegan:Connect(function(inp, gp) if gp or not State.Spec.active or inp.UserInputType ~= Enum.UserInputType.Touch then return end; table.insert(specPinch, inp); specTM = #specPinch == 1 and inp or nil end))
    table.insert(specConns, UserInputService.InputChanged:Connect(function(inp) if not State.Spec.active or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if #specPinch == 1 and inp == specTM then specPan = specPan + Vector2.new(inp.Delta.X, inp.Delta.Y) elseif #specPinch >= 2 then local d = (specPinch[1].Position - specPinch[2].Position).Magnitude; if specPinchD then local diff = d - specPinchD; Camera.FieldOfView = math.clamp(Camera.FieldOfView - diff * 0.15, 10, 120); State.Spec.dist = math.clamp(State.Spec.dist - diff * 0.03, 3, 30) end; specPinchD = d end end))
    table.insert(specConns, UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; for i, v in ipairs(specPinch) do if v == inp then table.remove(specPinch, i); break end end; specPinchD = nil; specTM = #specPinch == 1 and specPinch[1] or nil end))
end

local function stopSpecCapture() for _, c in ipairs(specConns) do c:Disconnect() end; specConns = {}; specTM = nil; specPinch = {}; specPinchD = nil; specPan = Vector2.zero end

local function startSpecLoop()
    RunService:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value + 1, function() if not State.Spec.active then return end; pcall(function() local targetChar, targetHrp; if State.Spec.isSelf then targetChar = LP.Character; targetHrp = getCharRoot(targetChar) else if not State.Spec.target or not State.Spec.target.Character then State.Spec.active = false; stopSpecLoop(); stopSpecCapture(); Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = State.Spec.origFov; return end; targetChar = State.Spec.target.Character; targetHrp = targetChar:FindFirstChild("HumanoidRootPart") end; if not targetHrp then if not State.Spec.isSelf then State.Spec.active = false; stopSpecLoop(); stopSpecCapture(); Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = State.Spec.origFov end; return end; Camera.CameraType = Enum.CameraType.Scriptable; local pan, sens = specPan, 0.3; specPan = Vector2.zero
        State.Spec.orbitYaw = State.Spec.orbitYaw + pan.X * sens
        State.Spec.orbitPitch = math.clamp(State.Spec.orbitPitch + pan.Y * sens, -75, 75)
        Camera.CFrame = CFrame.new((CFrame.new(targetHrp.Position) * CFrame.Angles(0, math.rad(-State.Spec.orbitYaw), 0) * CFrame.Angles(math.rad(-State.Spec.orbitPitch), 0, 0) * CFrame.new(0, 0, State.Spec.dist)).Position, targetHrp.Position + Vector3.new(0, 1, 0))
    end) end)
end

local function stopSpecLoop() RunService:UnbindFromRenderStep("XKIDSpec") end

-- ================================ AUTO LIKE ================================
local function getLikeRemotes() local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if not remotes then return nil, nil end; return remotes:FindFirstChild("GetLikeDataRemote"), remotes:FindFirstChild("LikePlayerEvent") end

local function likeRandomPlayer()
    if not LP.Character or not getRoot() then return false, "No character" end
    local _, likePlayer = getLikeRemotes(); if not likePlayer then return false, "Remote not found" end
    local myRoot = getRoot(); local targets = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then if State.AutoLike.radius > 0 and myRoot then local theirRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if theirRoot then local dist = (theirRoot.Position - myRoot.Position).Magnitude; if dist <= State.AutoLike.radius then table.insert(targets, p) end end else table.insert(targets, p) end end end
    if #targets == 0 then return false, "No players in range" end
    local target; if #targets == 1 then target = targets[1] else repeat target = targets[math.random(1, #targets)] until target ~= State.AutoLike.lastTarget or #targets <= 1 end
    State.AutoLike.lastTarget = target; local success = pcall(function() likePlayer:FireServer(target) end)
    if success then State.AutoLike.count = State.AutoLike.count + 1; return true, target.DisplayName end
    return false, "Failed"
end

local function startAutoLike() if State.AutoLike.active then return end; State.AutoLike.active = true; State.AutoLike.thread = task.spawn(function() while State.AutoLike.active and getgenv()._XKID_RUNNING do
    local ok, result = likeRandomPlayer()
    if ok then notify("Auto Like", result .. " | Total: " .. State.AutoLike.count, 1.5, "heart") end
    local cd = math.random(State.AutoLike.minCD * 10, State.AutoLike.maxCD * 10) / 10
    task.wait(cd)
end; State.AutoLike.thread = nil end); notify("Auto Like", "ON", 2, "heart") end
local function stopAutoLike() State.AutoLike.active = false; if State.AutoLike.thread then task.cancel(State.AutoLike.thread); State.AutoLike.thread = nil end; notify("Auto Like", "OFF", 1.5, "heart") end

-- ================================ HARD FLING ================================
local hardFlingConn, hardFlingRampConn, hardFlingBAV = nil, nil, nil

local function stopHardFlingInternal()
    if hardFlingConn then hardFlingConn:Disconnect(); hardFlingConn = nil end
    if hardFlingRampConn then hardFlingRampConn:Disconnect(); hardFlingRampConn = nil end
    if hardFlingBAV then hardFlingBAV:Destroy(); hardFlingBAV = nil end
    local r = getRoot(); if r then pcall(function() r.AssemblyAngularVelocity = Vector3.zero; r.AssemblyLinearVelocity = Vector3.zero end) end
    if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    State.HardFling.active = false
    State.HardFling.rampUpActive = false
    State.HardFling.currentPower = 0
end

local function startHardFling()
    if State.HardFling.active then return end
    State.HardFling.active = true
    State.Move.ncp = true
    State.HardFling.currentPower = 0
    State.HardFling.rampUpActive = true
    local hrp = getRoot()
    if hrp then
        hardFlingBAV = Instance.new("BodyAngularVelocity", hrp)
        hardFlingBAV.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        hardFlingBAV.P = 100000
    end
    local rampStart = tick()
    hardFlingRampConn = TrackC(RunService.Heartbeat:Connect(function()
        if not State.HardFling.rampUpActive then return end
        local t = math.clamp((tick() - rampStart) / 2, 0, 1)
        State.HardFling.currentPower = State.HardFling.power * t
        if t >= 1 then
            State.HardFling.currentPower = State.HardFling.power
            State.HardFling.rampUpActive = false
        end
    end))
    hardFlingConn = TrackC(RunService.Heartbeat:Connect(function()
        if not State.HardFling.active then return end
        local r = getRoot()
        if not r then
            stopHardFlingInternal()
            return
        end
        if State.HardFling.mode == "Spin" then
            if hardFlingBAV and hardFlingBAV.Parent then
                hardFlingBAV.AngularVelocity = Vector3.new(0, State.HardFling.currentPower, 0)
            end
        elseif State.HardFling.mode == "Shake" then
            if hardFlingBAV and hardFlingBAV.Parent then
                local shakeX = (math.random() - 0.5) * State.HardFling.currentPower * 0.5
                local shakeY = (math.random() - 0.5) * State.HardFling.currentPower * 0.3
                local shakeZ = (math.random() - 0.5) * State.HardFling.currentPower * 0.5
                hardFlingBAV.AngularVelocity = Vector3.new(shakeX, shakeY, shakeZ)
            end
        end
        if LP.Character then
            for _, p in pairs(LP.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end))
    notify("Hard Fling", "ON — " .. State.HardFling.mode, 2, "zap")
end

local function stopHardFling()
    stopHardFlingInternal()
    notify("Hard Fling", "OFF", 1.5, "zap")
end

TrackC(LP.CharacterAdded:Connect(function()
    if State.HardFling.active then
        stopHardFlingInternal()
    end
end))

-- ================================ FILTERS (PRESETS) ================================
local FILTER_PRESETS = {
    Mendung_HD = { tint = Color3.fromRGB(180, 185, 200), sat = -0.3, con = 0.1, bri = -0.15, bloomI = 0.05, bloomS = 24, time = 10, lightB = 0.7 },
    Cool_Blue_HD = { tint = Color3.fromRGB(180, 200, 255), sat = 0.1, con = 0.15, bri = 0.05, bloomI = 0.2, bloomS = 24, time = 12, lightB = 1.2 },
    Soft_Fade_HD = { tint = Color3.fromRGB(255, 240, 235), sat = -0.1, con = -0.05, bri = 0.1, bloomI = 0.4, bloomS = 35, time = 15, lightB = 1.3 },
    Adaptif_Langit_HD = { tint = Color3.new(1, 1, 1), sat = 0.15, con = 0.2, bri = 0.05, bloomI = 0.15, bloomS = 24, time = 13, lightB = 1.5 },
    Edgy_HD = { tint = Color3.fromRGB(200, 195, 210), sat = -0.5, con = 0.4, bri = -0.1, bloomI = 0.3, bloomS = 20, time = 8, lightB = 0.8 },
    Full_Bright_HD = { tint = Color3.new(1, 1, 1), sat = 0, con = 0, bri = 0, bloomI = 0, bloomS = 24, time = 12, lightB = 3, shadow = false, ambient = Color3.new(1, 1, 1), outdoor = Color3.new(1, 1, 1) },
    Soft_Pastel_HD = { tint = Color3.fromRGB(255, 240, 245), sat = -0.05, con = 0.05, bri = 0, bloomI = 0.3, bloomS = 24, time = 8, lightB = 1 },
    Cinematic_Soft = { tint = Color3.new(1, 1, 1), sat = 0.1, con = 0.15, bri = 0.05, bloomI = 0.2, bloomS = 24, time = 17, lightB = 1 },
    Ultra_HD = { tint = Color3.new(1, 1, 1), sat = 0.2, con = 0.3, bri = 0, bloomI = 0.2, bloomS = 24, time = 14, lightB = 1 },
    Realistic = { tint = Color3.new(1, 1, 1), sat = 0.1, con = 0.2, bri = 0, bloomI = 0.15, bloomS = 24, time = 15, lightB = 1 },
    Night_HD = { tint = Color3.fromRGB(200, 200, 255), sat = 0.1, con = 0.2, bri = 0, bloomI = 0.15, bloomS = 24, time = 1, lightB = 1 },
    Senja = { tint = Color3.fromRGB(255, 180, 120), sat = 0.2, con = 0.1, bri = 0.05, bloomI = 0.5, bloomS = 40, time = 17.5, lightB = 1 },
    Cinematic_Film = { tint = Color3.fromRGB(200, 210, 230), sat = -0.15, con = 0.25, bri = -0.05, bloomI = 0.15, bloomS = 20, time = 16, lightB = 1 },
    Golden_Hour = { tint = Color3.fromRGB(255, 200, 100), sat = 0.1, con = 0.15, bri = 0.1, bloomI = 0.4, bloomS = 35, time = 17.5, lightB = 1 },
    Moody_Blue = { tint = Color3.fromRGB(150, 170, 255), sat = 0.05, con = 0.2, bri = -0.1, bloomI = 0.1, bloomS = 24, time = 2, lightB = 1 },
}

local function resetFilterOnly() for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" then v:Destroy() end end end

local function applyCustomFilter()
    resetFilterOnly(); Lighting.Brightness = originalLighting.Brightness; Lighting.Ambient = originalLighting.Ambient; Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient; Lighting.GlobalShadows = originalLighting.GlobalShadows; Lighting.FogEnd = originalLighting.FogEnd; Lighting.ExposureCompensation = State.CustomFilter.exposure
    local cc = Instance.new("ColorCorrectionEffect", Lighting); cc.Name = "_XKID_FILTER"; cc.TintColor = Color3.fromRGB(State.CustomFilter.tintR, State.CustomFilter.tintG, State.CustomFilter.tintB); cc.Saturation = State.CustomFilter.saturation; cc.Contrast = State.CustomFilter.contrast; cc.Brightness = State.CustomFilter.brightness
    local bloom = Instance.new("BloomEffect", Lighting); bloom.Name = "_XKID_FILTER"; bloom.Intensity = State.CustomFilter.bloomIntensity; bloom.Size = State.CustomFilter.bloomSize; Lighting.ClockTime = State.CustomFilter.clockTime
end

local function applyFilter(filterName)
    resetFilterOnly(); Lighting.ClockTime = originalLighting.ClockTime; Lighting.Brightness = originalLighting.Brightness; Lighting.Ambient = originalLighting.Ambient; Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient; Lighting.GlobalShadows = originalLighting.GlobalShadows; Lighting.FogEnd = originalLighting.FogEnd; Lighting.ExposureCompensation = originalLighting.ExposureCompensation
    if filterName == "Default" then State.CustomFilter.tintR = 255; State.CustomFilter.tintG = 255; State.CustomFilter.tintB = 255; State.CustomFilter.saturation = 0; State.CustomFilter.contrast = 0; State.CustomFilter.brightness = 0; State.CustomFilter.exposure = 0; State.CustomFilter.bloomIntensity = 0; State.CustomFilter.bloomSize = 24; State.CustomFilter.clockTime = 14; notify("Visuals", "Default", 1.5, "palette"); return end
    if filterName == "Custom" then applyCustomFilter(); notify("Visuals", "Custom FX", 1.5, "palette"); return end
    local key = filterName:gsub(" ", "_"):gsub(" HD", "_HD"); local preset = FILTER_PRESETS[key]
    if preset then Lighting.ClockTime = preset.time or 14; Lighting.Brightness = preset.lightB or 1; Lighting.ExposureCompensation = preset.exp or 0; Lighting.GlobalShadows = preset.shadow ~= false; if preset.ambient then Lighting.Ambient = preset.ambient end; if preset.outdoor then Lighting.OutdoorAmbient = preset.outdoor end; local cc = Instance.new("ColorCorrectionEffect", Lighting); cc.Name = "_XKID_FILTER"; cc.TintColor = preset.tint; cc.Saturation = preset.sat or 0; cc.Contrast = preset.con or 0; cc.Brightness = preset.bri or 0; local bloom = Instance.new("BloomEffect", Lighting); bloom.Name = "_XKID_FILTER"; bloom.Intensity = preset.bloomI or 0; bloom.Size = preset.bloomS or 24; State.CustomFilter.tintR = preset.tint.R * 255; State.CustomFilter.tintG = preset.tint.G * 255; State.CustomFilter.tintB = preset.tint.B * 255; for k, v in pairs(preset) do if State.CustomFilter[k] ~= nil then State.CustomFilter[k] = v end end; notify("Visuals", filterName, 2, "palette") else notify("Visuals", "Filter not found: " .. filterName, 2, "circle-alert") end
end

-- ================================ MAIN WINDOW UI ================================
local Window = WindUI:CreateWindow({
    Title = "XKID_HUB V3.8", Icon = "bluetooth", Author = "@WTF.XKID", Folder = "XKIDHub",
    Size = UDim2.fromOffset(360, 320), Transparent = true, Theme = "Crimson", SideBarWidth = 160,
    User = { Enabled = true, Anonymous = false }, Topbar = { Height = 40, ButtonsType = "Default" },
})

pcall(function() WindUI:SetFont("rbxassetid://12187376357") end)
pcall(function() WindUI:SetNotificationLower(true) end)
pcall(function() Window.User:SetDisplayName(LP.DisplayName); Window.User:SetUsername("@" .. LP.Name) end)

Window:EditOpenButton({
    Title = "WTF.XKID", Icon = "github", CornerRadius = UDim.new(1, 0),
    StrokeThickness = 2, StrokeColor = Color3.fromRGB(255, 70, 120),
    Enabled = true, Draggable = true, Scale = 0.72,
})

local FpsTag = Window:Tag({ Title = "FPS: -- | Ping: --", Color = Color3.fromRGB(255, 215, 0), Icon = "activity" })
local VerTag = Window:Tag({ Title = "V3.8", Color = Color3.fromRGB(255, 215, 0), Icon = "tag" })

task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(1); if FpsTag and FpsTag.SetTitle then FpsTag:SetTitle("FPS: " .. sharedFPS .. " | Ping: " .. sharedPing .. "ms") end end end)

-- ================================ TAB: INFORMASI ================================
local TabInfo = Window:Tab({ Title = "Informasi", Icon = "activity" })

local function getExecutor() pcall(function() local e = identifyexecutor(); if e and e ~= "" then return e end end); pcall(function() local e = getexecutorname(); if e and e ~= "" then return e end end); return executor.name end

local execName = getExecutor(); local accountAge = LP.AccountAge .. " days"
local avatarImage = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=420&h=420"

local afkStatusParagraph = TabInfo:Paragraph({ Title = "YooWssp!!, " .. LP.DisplayName, Desc = "Executor: " .. execName .. "\nAccount Age: " .. accountAge .. "\nUserID: " .. LP.UserId .. "\nStatus: " .. (LP.MembershipType == Enum.MembershipType.Premium and "Premium" or "Normal") .. "\nAnti AFK: ON ✅\nFPS Cap: " .. State.FPS.cap, Image = avatarImage, ImageSize = 80 })

task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(1); pcall(function() afkStatusParagraph:SetDesc("Executor: " .. execName .. "\nAccount Age: " .. accountAge .. "\nUserID: " .. LP.UserId .. "\nStatus: " .. (LP.MembershipType == Enum.MembershipType.Premium and "Premium" or "Normal") .. "\nAnti AFK: " .. (State.Security.afkActive and "ON ✅" or "OFF ❌") .. "\nFPS Cap: " .. State.FPS.cap) end) end end)

local infoParagraph = TabInfo:Paragraph({ Title = "💀 " .. LP.DisplayName .. "\n⚡ " .. makeBar(sharedFPS, 120, 10) .. " " .. sharedFPS .. " FPS\n📡 " .. makeBar(math.max(1, 200 - sharedPing), 200, 10) .. " " .. sharedPing .. "ms\n🕐 " .. makeBar(os.difftime(os.time(), START_TIME) % 3600, 3600, 10) .. " " .. formatTime(os.difftime(os.time(), START_TIME)), Desc = "👤 " .. LP.DisplayName .. "\n📱 " .. (onMobile and "Mobile" or "PC") .. " | 🚀 " .. execName .. "\n\n🎮 " .. (cachedMapName or "Loading...") .. "\n👥 " .. makeBar(#Players:GetPlayers(), Players.MaxPlayers, 10) .. " " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. " Players\n\n🌐 discord.gg/bzumc2u96" })

task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(1); pcall(function() infoParagraph:SetTitle("💀 " .. LP.DisplayName .. "\n⚡ " .. makeBar(sharedFPS, 120, 10) .. " " .. sharedFPS .. " FPS\n📡 " .. makeBar(math.max(1, 200 - sharedPing), 200, 10) .. " " .. sharedPing .. "ms\n🕐 " .. makeBar(os.difftime(os.time(), START_TIME) % 3600, 3600, 10) .. " " .. formatTime(os.difftime(os.time(), START_TIME))) end) end end)

TabInfo:Section({ Title = "🔗 Discord", Icon = "message-circle", Box = true }):Button({ Title = "Copy Discord Link", Desc = "discord.gg/bzumc2u96", Callback = function() pcall(function() setclipboard("https://discord.gg/bzumc2u96") end); notify("System", "Link copied", 2, "copy") end })

-- ================================ TAB: CHARACTER ================================
local TabChar = Window:Tab({ Title = "Character", Icon = "fingerprint" })
TabChar:Button({ Title = "Refresh Character 🔄", Desc = "Reload character like /re", Callback = refreshCharacter })

local secMov = TabChar:Section({ Title = "Movement", Icon = "activity", Box = true })
secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end })
secMov:Toggle({ Title = "Infinite Jump", Default = false, Callback = function(v) if v then State.Move.infJ = TrackC(UserInputService.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end)) else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end end; notify("Infinite Jump", v and "ON" or "OFF", 1.5, "arrow-big-up") end })

local secAutoWalk = TabChar:Section({ Title = "Auto Walk", Icon = "play", Box = true })
secAutoWalk:Toggle({ Title = "Auto Walk", Default = false, Callback = function(v) if v then startAutoWalk() else stopAutoWalk() end end })
secAutoWalk:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 1, Max = 100, Default = 16 }, Callback = function(v) State.Move.autoWalkSpeed = v; if State.Move.autoWalk then local hum = getHum(); if hum then hum.WalkSpeed = v end end end })
secAutoWalk:Paragraph({ Title = "Info", Desc = "Character walks forward automatically\nMove manually to override" })

local secAbi = TabChar:Section({ Title = "Abilities", Icon = "zap", Box = true })
secAbi:Toggle({ Title = "Fly", Default = false, Callback = function(v) toggleFly(v) end })
secAbi:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(v) State.Move.flyS = v end })

local noclipConn = nil
secAbi:Toggle({ Title = "NoClip", Default = false, Callback = function(v) State.Move.ncp = v; if v then if not noclipConn then noclipConn = TrackC(RunService.Heartbeat:Connect(function() if not State.Move.ncp then return end; if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)) end else if noclipConn then noclipConn:Disconnect(); noclipConn = nil end; if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end end; notify("NoClip", v and "ON" or "OFF", 1.5, "ghost") end })

local secFling = TabChar:Section({ Title = "Hard Fling (Safe)", Icon = "rotate-cw", Box = true })
secFling:Toggle({ Title = "Hard Fling", Default = false, Callback = function(v) if v then startHardFling() else stopHardFling() end end })
secFling:Dropdown({ Title = "Fling Mode", Values = { "Spin", "Shake" }, Default = "Spin", Callback = function(v) State.HardFling.mode = v; notify("Fling Mode", v, 1.5, "rotate-cw") end })
secFling:Slider({ Title = "Fling Power", Step = 500, Value = { Min = 1000, Max = 50000, Default = 10000 }, Callback = function(v) State.HardFling.power = v end })

-- ================================ TAB: TELEPORT ================================
local TabTP = Window:Tab({ Title = "Teleport", Icon = "map-pin-x-inside" })
local secDirTP = TabTP:Section({ Title = "Direct Teleport", Icon = "map-pin", Box = true })
secDirTP:Toggle({ Title = "Smart TP", Desc = "Equip tool → tap to toggle mode → tap to TP", Default = false, Callback = toggleSmartTP })

local secTargetTP = TabTP:Section({ Title = "Target Teleport", Icon = "crosshair", Box = true })
local tpTarget = ""
secTargetTP:Input({ Title = "Search Player", Placeholder = "Type name...", Callback = function(v) tpTarget = v end })
secTargetTP:Button({ Title = "Execute TP", Desc = "Teleport to target", Callback = function() pcall(function() if tpTarget == "" then notify("Teleport", "Input target!", 2, "circle-alert"); return end; local t = nil; for _, p in pairs(Players:GetPlayers()) do if p ~= LP and (string.find(string.lower(p.Name), string.lower(tpTarget)) or string.find(string.lower(p.DisplayName), string.lower(tpTarget))) then t = p; break end end; if not t or not t.Parent or not t.Character then notify("Teleport", "Invalid Target", 2, "circle-alert"); return end; local thr = getCharRoot(t.Character); local mhr = getRoot(); if not thr or not mhr then return end; mhr.CFrame = thr.CFrame * CFrame.new(0, 0, 3) + Vector3.new(0, 2, 0); notify("Teleport", t.DisplayName, 2, "map-pin") end) end })
secTargetTP:Dropdown({ Title = "Player List", Values = getDisplayNames(), Callback = function(v) tpTarget = tostring(v) end })
secTargetTP:Button({ Title = "Refresh List", Callback = function() notify("Teleport", "List refreshed", 1.5, "map-pin") end })

local secCache = TabTP:Section({ Title = "Coordinates Cache", Icon = "save", Box = true })
local SavedLocs = {}
for i = 1, 3 do local idx = i; local hc = secCache:HStack({ Columns = 2 })
    hc:Button({ Title = "💾 Save " .. idx, Callback = function() local r = getRoot(); if not r then return end; SavedLocs[idx] = r.CFrame; notify("Slot " .. idx, "Saved", 1.5, "save") end })
    hc:Button({ Title = "📍 Load " .. idx, Callback = function() if not SavedLocs[idx] then notify("Slot " .. idx, "Empty", 1.5, "save"); return end; local r = getRoot(); if not r then return end; r.CFrame = SavedLocs[idx]; notify("Slot " .. idx, "Loaded", 1.5, "map-pin") end })
end

-- ================================ TAB: SPECTATOR ================================
local TabSpec = Window:Tab({ Title = "Spectator", Icon = "cctv" })
local secZoom = TabSpec:Section({ Title = "Zoom Override", Icon = "zoom-in", Box = true })
secZoom:Toggle({ Title = "Max Zoom Out", Default = false, Callback = function(v) pcall(function() LP.CameraMaxZoomDistance = v and 100000 or 400 end); notify("Zoom", v and "Max" or "Default", 1.5, "zoom-in") end })

local secSP = TabSpec:Section({ Title = "Spectator Mode", Icon = "eye", Box = true })
secSP:Dropdown({ Title = "Select Target", Values = getDisplayNamesWithSelf(), Callback = function(v) local s = tostring(v); if s == "[Self]" then State.Spec.target = LP; State.Spec.isSelf = true; State.Spec.orbitYaw = 0; State.Spec.orbitPitch = 20; notify("Spectator", "Self", 1.5, "eye") else local p = findPlayerByDisplay(s); if p then State.Spec.target = p; State.Spec.isSelf = false; if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ(); State.Spec.orbitYaw = math.deg(ry); State.Spec.orbitPitch = 20 end; notify("Spectator", p.DisplayName, 1.5, "eye") end end end })
secSP:Button({ Title = "Refresh Target List", Callback = function() notify("Spectator", "List refreshed", 1.5, "eye") end })
secSP:Toggle({ Title = "Enable Spectate", Default = false, Callback = function(v) if SS.active then toggleSelfSpec(false) end; State.Spec.active = v; if v then if not State.Spec.target or not State.Spec.target.Character then if State.Spec.isSelf and LP.Character then else State.Spec.active = false; notify("Error", "No target", 2, "circle-alert"); return end end; State.Spec.origFov = Camera.FieldOfView; startSpecCapture(); startSpecLoop(); notify("Spectator", "ON", 2, "eye") else stopSpecLoop(); stopSpecCapture(); Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = State.Spec.origFov; notify("Spectator", "OFF", 1.5, "eye") end end })
secSP:Slider({ Title = "Distance", Step = 1, Value = { Min = 3, Max = 30, Default = 8 }, Callback = function(v) State.Spec.dist = v end })

-- ================================ TAB: CINEMATIC ================================
local TabCine = Window:Tab({ Title = "Cinematic", Icon = "aperture" })
local secSelfSpec = TabCine:Section({ Title = "🎥 Self-Spectate", Icon = "camera", Box = true })
secSelfSpec:Toggle({ Title = "Enable Self-Spectate", Desc = "1-finger orbit | 2-finger zoom | Mouse right-drag", Default = false, Callback = toggleSelfSpec })
secSelfSpec:Dropdown({ Title = "Preset Mode", Values = { "Manual", "Slow Orbit", "Vertical Swing", "Figure 8", "Cinematic Drift", "Orbit Steady", "Tilt Drift" }, Default = "Manual", Callback = function(v) SS.mode = v; notify("Self-Spec", "Mode: " .. v, 1.5, "camera") end })
secSelfSpec:Slider({ Title = "Distance / Radius", Step = 0.5, Value = { Min = 3, Max = 30, Default = 8 }, Callback = function(v) SS.radius = v; SS.dist = v end })
secSelfSpec:Slider({ Title = "Height", Step = 0.5, Value = { Min = -10, Max = 20, Default = 3 }, Callback = function(v) SS.height = v end })
secSelfSpec:Slider({ Title = "Speed", Step = 0.1, Value = { Min = 0.1, Max = 5, Default = 1 }, Callback = function(v) SS.speed = v end })

local secFC = TabCine:Section({ Title = "Drone Engine", Icon = "video", Box = true })
secFC:Toggle({ Title = "Enable Freecam", Desc = "Karakter LOCK posisi + Bisa Emote/Dance", Default = false, Callback = toggleFreecam })
secFC:Slider({ Title = "Camera Speed", Step = 0.5, Value = { Min = 1, Max = 20, Default = 3 }, Callback = function(v) FC.speed = v end })
secFC:Slider({ Title = "Sensitivity", Step = 0.05, Value = { Min = 0.1, Max = 1.0, Default = 0.25 }, Callback = function(v) FC.sens = v end })

local cinematicHideActive = false
secFC:Toggle({ Title = "Hide All UI (Cinematic)", Default = false, Callback = function(v) if getgenv()._XKID_UI_LOADING then return end; cinematicHideActive = v
    if v then
        State.Cinema.hideUI = true
        State.Cinema.cachedGuis = {}
        for _, gui in pairs(LP.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                table.insert(State.Cinema.cachedGuis, gui)
                gui.Enabled = false
            end
        end
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
        if FCUI then FCUI.Enabled = false end
    else
        State.Cinema.hideUI = false
        for _, gui in pairs(State.Cinema.cachedGuis) do
            if gui and gui.Parent then gui.Enabled = true end
        end
        State.Cinema.cachedGuis = {}
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
        if FC.active and FCUI then FCUI.Enabled = true end
    end
    notify("Cinematic", v and "UI Hidden" or "UI Shown", 1.5, "film") end })

-- ================================ TAB: VISUALS ================================
local TabVis = Window:Tab({ Title = "Visuals", Icon = "moon-star" })
local secPresets = TabVis:Section({ Title = "Presets", Icon = "palette", Box = true })
secPresets:Dropdown({ Title = "Select Filter", Values = { "Default", "Custom", "Mendung HD", "Cool Blue HD", "Soft Fade HD", "Adaptif Langit HD", "Edgy HD", "Full Bright HD", "Soft Pastel HD", "Cinematic Soft", "Ultra HD", "Realistic", "Night HD", "Senja", "Cinematic Film", "Golden Hour", "Moody Blue" }, Default = "Default", Callback = applyFilter })

local secFX = TabVis:Section({ Title = "Custom FX", Icon = "sliders", Box = true })
secFX:Slider({ Title = "Saturation", Step = 0.05, Value = { Min = -1, Max = 1, Default = 0 }, Callback = function(v) State.CustomFilter.saturation = v; applyCustomFilter() end })
secFX:Slider({ Title = "Contrast", Step = 0.05, Value = { Min = -1, Max = 1, Default = 0 }, Callback = function(v) State.CustomFilter.contrast = v; applyCustomFilter() end })
secFX:Slider({ Title = "Brightness", Step = 0.05, Value = { Min = -1, Max = 1, Default = 0 }, Callback = function(v) State.CustomFilter.brightness = v; applyCustomFilter() end })
secFX:Slider({ Title = "Exposure", Step = 0.1, Value = { Min = -5, Max = 5, Default = 0 }, Callback = function(v) State.CustomFilter.exposure = v; applyCustomFilter() end })
secFX:Slider({ Title = "Bloom Intensity", Step = 0.1, Value = { Min = 0, Max = 2, Default = 0 }, Callback = function(v) State.CustomFilter.bloomIntensity = v; applyCustomFilter() end })
secFX:Slider({ Title = "ClockTime", Step = 0.5, Value = { Min = 0, Max = 24, Default = 14 }, Callback = function(v) State.CustomFilter.clockTime = v; applyCustomFilter() end })
secFX:Button({ Title = "Reset Custom FX", Callback = function() State.CustomFilter.saturation = 0; State.CustomFilter.contrast = 0; State.CustomFilter.brightness = 0; State.CustomFilter.exposure = 0; State.CustomFilter.bloomIntensity = 0; State.CustomFilter.clockTime = 14; applyCustomFilter(); notify("Visuals", "FX Reset", 2, "rotate-ccw") end })

-- ================================ TAB: ESP ================================
local TabESP = Window:Tab({ Title = "ESP", Icon = "scan-search" })
local secDetect = TabESP:Section({ Title = "Detection System", Icon = "radar", Box = true })
secDetect:Toggle({ Title = "Enable Radar", Default = false, Callback = function(v) State.ESP.active = v; if not v and State.ESP.cache then for _, c in pairs(State.ESP.cache) do pcall(function() if c.texts then c.texts.Visible = false end; if c.tracer then c.tracer.Visible = false end; for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end; if c.hl then c.hl.Enabled = false end end) end end; notify("ESP", v and "ON" or "OFF", 1.5, "radar") end })
secDetect:Toggle({ Title = "Highlight Entity", Default = false, Callback = function(v) State.ESP.highlightMode = v; notify("ESP", "Highlight " .. (v and "ON" or "OFF"), 1.5, "radar") end })
secDetect:Slider({ Title = "Scan Distance", Step = 10, Value = { Min = 50, Max = 500, Default = 300 }, Callback = function(v) State.ESP.maxDrawDistance = v end })

local secESPCol = TabESP:Section({ Title = "Color Config", Icon = "palette", Box = true })
secESPCol:Dropdown({ Title = "Normal Color", Values = { "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam" }, Default = "Merah", Callback = function(v) if colorMap[v] then State.ESP.tracerColor_N = colorMap[v]; State.ESP.boxColor_N = colorMap[v] end; notify("ESP", "Normal: " .. v, 1.5, "palette") end })
secESPCol:Dropdown({ Title = "Suspect Color", Values = { "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam", "Crimson" }, Default = "Crimson", Callback = function(v) if colorMap[v] then State.ESP.tracerColor_S = colorMap[v]; State.ESP.boxColor_S = colorMap[v] end; notify("ESP", "Suspect: " .. v, 1.5, "palette") end })
secESPCol:Dropdown({ Title = "Glitch Acc Color", Values = { "Orange", "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Pink", "Putih", "Hitam" }, Default = "Orange", Callback = function(v) if colorMap[v] then State.ESP.tracerColor_G = colorMap[v]; State.ESP.boxColor_G = colorMap[v] end; notify("ESP", "Glitch: " .. v, 1.5, "palette") end })

-- ================================ TAB: LOGGER ================================
local TabLog = Window:Tab({ Title = "Logger", Icon = "square-terminal" })
local secChat = TabLog:Section({ Title = "Chat Logger", Icon = "message-square", Box = true })
secChat:Toggle({ Title = "Enable Logger", Default = false, Callback = function(v) State.Utility.chatLog = v; if not v then pcall(function() chatLogPanel:SetDesc("Logger disabled") end) end; notify("Logger", v and "ON" or "OFF", 1.5, "terminal") end })

local chatTargetLabel = secChat:Paragraph({ Title = "Targets", Desc = "None" })
local chatTargetDrop = secChat:Dropdown({ Title = "Select Targets", Multi = true, AllowNone = true, Values = getDisplayNames(), Callback = function(selected) State.Utility.chatTargets = {}; if selected and typeof(selected) == "table" then for _, name in ipairs(selected) do table.insert(State.Utility.chatTargets, tostring(name)) end end; if #State.Utility.chatTargets > 0 then pcall(function() chatTargetLabel:SetDesc("Tracking: " .. table.concat(State.Utility.chatTargets, ", ")) end) else pcall(function() chatTargetLabel:SetDesc("None") end) end end })
secChat:Button({ Title = "Clear Targets", Callback = function() State.Utility.chatTargets = {}; pcall(function() chatTargetLabel:SetDesc("None") end); pcall(function() chatTargetDrop:SetValues({}); task.wait(0.05); chatTargetDrop:SetValues(getDisplayNames()) end); notify("Logger", "Targets cleared", 1.5, "terminal") end })
secChat:Button({ Title = "Refresh List", Callback = function() pcall(function() chatTargetDrop:Refresh(getDisplayNames(), true) end); notify("Logger", "List refreshed", 1.5, "terminal") end })

local chatLogPanel = secChat:Paragraph({ Title = "Console", Desc = "Belum ada chat..." })
secChat:Button({ Title = "Clear Log", Callback = function() State.Utility.chatHistory = {}; pcall(function() chatLogPanel:SetDesc("Belum ada chat...") end); notify("Logger", "Log cleared", 1.5, "terminal") end })

task.spawn(function() local function OC(sn, msg) if not State.Utility.chatLog then return end; if #State.Utility.chatTargets == 0 then return end; local cs = sn:lower():match("^%s*(.-)%s*$"); for _, t in ipairs(State.Utility.chatTargets) do local ct = t:lower():match("^%s*(.-)%s*$"); if cs == ct then local e = string.format("[%s] %s: %s", os.date("%H:%M:%S"), sn, msg); table.insert(State.Utility.chatHistory, e); if #State.Utility.chatHistory > 50 then table.remove(State.Utility.chatHistory, 1) end; notify("Chat", sn .. ": " .. msg, 2, "message-circle"); break end end end; if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then pcall(function() TrackC(TextChatService.MessageReceived:Connect(function(m) if m.TextSource then OC(m.TextSource.Name, m.Text) end end)) end) end; local function CLC(p) pcall(function() TrackC(p.Chatted:Connect(function(m) OC(p.DisplayName, m) end)) end) end; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CLC(p) end end; TrackC(Players.PlayerAdded:Connect(function(p) if p ~= LP then CLC(p) end end)) end)
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(0.5); if chatLogPanel and State.Utility.chatLog then pcall(function() local t = table.concat(State.Utility.chatHistory, "\n"); if #t > 2000 then t = t:sub(-2000) end; if #t == 0 then t = "Belum ada chat..." end; chatLogPanel:SetDesc(t) end) end end end)

-- ================================ TAB: PROTECTION ================================
local TabProt = Window:Tab({ Title = "Protection", Icon = "shield-half" })
local secProt = TabProt:Section({ Title = "Protection Protocols", Icon = "shield-check", Box = true })
secProt:Toggle({ Title = "Anti AFK (Stealth)", Default = false, Callback = function(v) if v then startAFK() else stopAFK() end end })
secProt:Button({ Title = "Stuck Fix", Desc = "Get unstuck from walls/ground", Callback = function() local r, h = getRoot(), getHum(); if r then r.Anchored = false; r.CFrame = r.CFrame + Vector3.new(0, 3, 0) end; if h then h.Sit = false; h:ChangeState(Enum.HumanoidStateType.Jumping) end; notify("Protection", "Stuck fix applied", 2, "wrench") end })

local secSrv = TabProt:Section({ Title = "Server Control", Icon = "server", Box = true })
secSrv:Button({ Title = "Force Rejoin", Desc = "Rejoin current server", Callback = function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end); notify("Server", "Rejoining...", 2, "log-in") end })
secSrv:Button({ Title = "Server Hop", Desc = "Find a new server", Callback = function() pcall(function() local req = getgenv()._XKID_REQUEST or httpRequest; if not req then notify("Error", "HTTP not supported", 2, "circle-alert"); return end; local res = req({ Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100", Method = "GET" }); if res.StatusCode == 200 then local body = HttpService:JSONDecode(res.Body); if body and body.data then for _, v in ipairs(body.data) do if v.playing > 0 and v.playing < v.maxPlayers and v.id ~= game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LP); notify("Server", "Hopping...", 2, "shuffle"); return end end end end end) end })

local secPerf = TabProt:Section({ Title = "Performance", Icon = "gauge", Box = true })
local gfxMap = { [1] = "Level01", [2] = "Level02", [3] = "Level03", [4] = "Level04", [5] = "Level05", [6] = "Level06", [7] = "Level07", [8] = "Level08", [9] = "Level09", [10] = "Level10" }
secPerf:Slider({ Title = "Quality Level", Step = 1, Value = { Min = 1, Max = 10, Default = 2 }, Callback = function(v) if gfxMap[v] then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel[gfxMap[v]] end) end; notify("Graphics", gfxMap[v], 1.5, "gauge") end })
secPerf:Dropdown({ Title = "FPS Cap", Values = { "30", "60", "120", "144", "240", "Unlimited" }, Default = "120", Callback = function(v) if v == "Unlimited" then setOptimalFPS(9999); State.FPS.cap = 9999 else setOptimalFPS(tonumber(v)); State.FPS.cap = tonumber(v) end; notify("Graphics", v .. " FPS", 1.5, "gauge") end })

local advCache = { level = nil, shadows = true, brightness = 5, clockTime = 14, fogEnd = 100000, mats = {}, texs = {} }
secPerf:Toggle({ Title = "FPS Boost", Default = false, Callback = function(v) State.Security.antiLag = v; if v then pcall(function() advCache.level = settings().Rendering.QualityLevel end); advCache.shadows = Lighting.GlobalShadows; advCache.brightness = Lighting.Brightness; advCache.clockTime = Lighting.ClockTime; advCache.fogEnd = Lighting.FogEnd; pcall(function() settings().Rendering.QualityLevel = 1 end); Lighting.GlobalShadows = false; Lighting.Brightness = 1; Lighting.FogEnd = 100000; for _, obj in pairs(workspace:GetDescendants()) do if obj:IsA("BasePart") then advCache.mats[obj] = obj.Material; obj.Material = Enum.Material.SmoothPlastic elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then advCache.texs[obj] = obj.Enabled; obj.Enabled = false end end; notify("Performance", "FPS Boost ON", 2, "zap") else pcall(function() if advCache.level then settings().Rendering.QualityLevel = advCache.level end end); Lighting.GlobalShadows = advCache.shadows; Lighting.Brightness = advCache.brightness; Lighting.ClockTime = advCache.clockTime; Lighting.FogEnd = advCache.fogEnd; for obj, mat in pairs(advCache.mats) do if obj and obj.Parent then pcall(function() obj.Material = mat end) end end; for obj, enb in pairs(advCache.texs) do if obj and obj.Parent then pcall(function() obj.Enabled = enb end) end end; advCache.mats = {}; advCache.texs = {}; notify("Performance", "Graphics restored", 2, "zap") end end })

local secCam = TabProt:Section({ Title = "Camera Lock", Icon = "lock", Box = true })
secCam:Toggle({ Title = "Force Shift Lock", Default = false, Callback = function(v) toggleShiftLock(v) end })

-- ================================ TAB: SETTINGS ================================
local TabSet = Window:Tab({ Title = "Settings", Icon = "panels-top-left" })

local secTheme = TabSet:Section({ Title = "🎨 Theme", Icon = "palette", Box = true })
secTheme:Dropdown({ Title = "UI Theme", Values = { "Dark", "Light", "Rose", "Sky", "Emerald", "Violet", "Red", "Amber", "Indigo", "Midnight", "Crimson" }, Default = "Crimson", Callback = function(v) WindUI:SetTheme(v) end })

local secDebug = TabSet:Section({ Title = "🐛 Debug Log (Error Only)", Icon = "bug", Box = true })
local debugPara = secDebug:Paragraph({ Title = "Log", Desc = "No errors yet..." })
secDebug:Button({ Title = "📋 Copy Log", Callback = function() local t = table.concat(DebugLog, "\n"); pcall(function() setclipboard(t) end); notify("Debug", "Log copied to clipboard", 2, "copy") end })
secDebug:Button({ Title = "🗑 Clear Log", Callback = function() DebugLog = {}; pcall(function() debugPara:SetDesc("No errors yet...") end); notify("Debug", "Log cleared", 1.5, "trash-2") end })
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(0.5); if debugPara then pcall(function() local t = table.concat(DebugLog, "\n"); if #t == 0 then t = "No errors yet..." elseif #t > 2000 then t = t:sub(-2000) end; debugPara:SetDesc(t) end) end end end)

local secFile = TabSet:Section({ Title = "File Management", Icon = "folder", Box = true })
local cfgName = "XKID_Config_V3"; local currentConfig = "No config"
secFile:Input({ Title = "Config Name", Value = "XKID_Config_V3", Callback = function(v) cfgName = v end })

local function saveConfig()
    if executor.has_writefile then pcall(function() if not isfolder("XKID_HUB") then makefolder("XKID_HUB") end; local d = { Move = { ws = State.Move.ws, jp = State.Move.jp, flyS = State.Move.flyS, autoWalkSpeed = State.Move.autoWalkSpeed }, ESP = { maxDrawDistance = State.ESP.maxDrawDistance, highlightMode = State.ESP.highlightMode }, Security = { shiftLock = State.Security.shiftLock, antiLag = State.Security.antiLag }, AutoLike = { radius = State.AutoLike.radius, minCD = State.AutoLike.minCD, maxCD = State.AutoLike.maxCD }, HardFling = { power = State.HardFling.power, mode = State.HardFling.mode }, SelfSpec = { mode = SS.mode, radius = SS.radius, height = SS.height, speed = SS.speed }, CustomFilter = { tintR = State.CustomFilter.tintR, tintG = State.CustomFilter.tintG, tintB = State.CustomFilter.tintB, saturation = State.CustomFilter.saturation, contrast = State.CustomFilter.contrast, brightness = State.CustomFilter.brightness, exposure = State.CustomFilter.exposure, bloomIntensity = State.CustomFilter.bloomIntensity, bloomSize = State.CustomFilter.bloomSize, clockTime = State.CustomFilter.clockTime } }; writefile("XKID_HUB/" .. cfgName .. ".json", HttpService:JSONEncode(d)); notify("Config", "Saved: " .. cfgName, 2, "save") end) else notify("Config", "Executor tidak support save file", 2, "circle-alert") end
end

local function loadConfig(selected)
    if selected == "No config" then return end; pcall(function() if executor.has_readfile and isfile and isfile("XKID_HUB/" .. selected .. ".json") then local d = HttpService:JSONDecode(readfile("XKID_HUB/" .. selected .. ".json")); if d then if d.Move then State.Move.ws = d.Move.ws or 16; State.Move.jp = d.Move.jp or 50; State.Move.flyS = d.Move.flyS or 60; State.Move.autoWalkSpeed = d.Move.autoWalkSpeed or 16; local h = getHum(); if h then h.WalkSpeed = State.Move.ws; h.UseJumpPower = true; h.JumpPower = State.Move.jp end end; if d.ESP then State.ESP.maxDrawDistance = d.ESP.maxDrawDistance or 300; State.ESP.highlightMode = d.ESP.highlightMode or false end; if d.Security and d.Security.shiftLock ~= State.Security.shiftLock then toggleShiftLock(d.Security.shiftLock) end; if d.AutoLike then State.AutoLike.radius = d.AutoLike.radius or 100; State.AutoLike.minCD = d.AutoLike.minCD or 2; State.AutoLike.maxCD = d.AutoLike.maxCD or 6 end; if d.HardFling then State.HardFling.power = d.HardFling.power or 5000; State.HardFling.mode = d.HardFling.mode or "Spin" end; if d.SelfSpec then SS.mode = d.SelfSpec.mode or "Manual"; SS.radius = d.SelfSpec.radius or 8; SS.height = d.SelfSpec.height or 3; SS.speed = d.SelfSpec.speed or 1 end; if d.CustomFilter then for k, v in pairs(d.CustomFilter) do State.CustomFilter[k] = v end; applyCustomFilter() end; notify("Config", "Loaded: " .. selected, 2, "folder-open") end end end)
end

secFile:Button({ Title = "Save Config", Callback = saveConfig })
local configDrop = secFile:Dropdown({ Title = "Load Config", Values = getConfigList(), Callback = function(selected) currentConfig = selected; loadConfig(selected) end })
secFile:Button({ Title = "Delete Config", Callback = function() if currentConfig ~= "No config" and currentConfig ~= "" and executor.has_listfiles then pcall(function() if isfile and delfile and isfile("XKID_HUB/" .. currentConfig .. ".json") then delfile("XKID_HUB/" .. currentConfig .. ".json"); pcall(function() configDrop:Refresh(getConfigList(), true) end); currentConfig = "No config"; notify("Config", "Deleted", 2, "trash-2") end end) end end })
secFile:Button({ Title = "Refresh Files", Callback = function() pcall(function() configDrop:Refresh(getConfigList(), true) end); notify("Config", "Files refreshed", 1.5, "folder") end })

local secLike = TabSet:Section({ Title = "Auto Like (Smart)", Icon = "heart", Box = true })
secLike:Toggle({ Title = "Auto Like", Default = false, Callback = function(v) if v then startAutoLike() else stopAutoLike() end end })
secLike:Slider({ Title = "Like Radius", Desc = "0 = all", Step = 10, Value = { Min = 0, Max = 500, Default = 100 }, Callback = function(v) State.AutoLike.radius = v end })
secLike:Slider({ Title = "Min Cooldown", Step = 0.5, Value = { Min = 0.5, Max = 10, Default = 2 }, Callback = function(v) State.AutoLike.minCD = v end })
secLike:Slider({ Title = "Max Cooldown", Step = 0.5, Value = { Min = 1, Max = 15, Default = 6 }, Callback = function(v) State.AutoLike.maxCD = v end })

local autoLikeInfo = secLike:Paragraph({ Title = "Info", Desc = "Total likes sent: 0" })
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(2); pcall(function() autoLikeInfo:SetDesc("Total likes sent: " .. State.AutoLike.count) end) end end)

-- ================================ INITIAL SETTINGS ================================
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level02 end)
setOptimalFPS(120)

-- ================================ AUTO START ANTI AFK ================================
task.spawn(function()
    task.wait(0.5); startAFK(); task.wait(2)
    getgenv()._XKID_UI_LOADING = false
    notify("System", "XKID_HUB V3.8 AKTIF — Lock Position + Emote Ready", 3, "rocket")
    notify("Anti AFK", "AUTO ACTIVATED (Stealth)", 2, "shield-check")
end)