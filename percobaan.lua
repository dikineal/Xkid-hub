-- @XKID SCRIPT V3.4 (Freecam Fix + Debug Log + ESP Fix)
-- by @WTF.XKID | Roblox Build For Mobile/PC | Tested on Delta X
-- Changelog V3.4:
-- - Freecam: karakter diam berdiri, ga muter (AutoRotate false)
-- - Debug Log section di Settings (Copy & Clear)
-- - ESP: Normal Color Merah, Tracer default Bottom
-- - Informasi: FPS Cap status
-- - Header: XKID_HUB + WTF.XKID + Version Tag V3.4 Gold

repeat task.wait() until game:IsLoaded()

-- ================================ WINDUI LOADER ================================
local WindUI = (function()
    local s, r = pcall(function() return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))() end)
    if s then return r else error("Failed to load WindUI") end
end)()

-- ================================ EXECUTOR DETECTION ================================
local executor = {
    name = "Unknown", has_writefile = false, has_readfile = false, has_listfiles = false,
    has_isfolder = false, has_makefolder = false, is_mobile_executor = false
}
pcall(function()
    local e = identifyexecutor and identifyexecutor() or getexecutorname and getexecutorname() or "Unknown"
    executor.name = e; executor.is_mobile_executor = (string.find(e, "Hydrogen") or string.find(e, "Arceus") or string.find(e, "Vega")) and true or false
end)
executor.has_writefile = type(writefile) == "function"; executor.has_readfile = type(readfile) == "function"
executor.has_listfiles = type(listfiles) == "function"; executor.has_isfolder = type(isfolder) == "function"
executor.has_makefolder = type(makefolder) == "function"
if not executor.has_writefile then getgenv()._XKID_NO_SAVE = true end

-- ================================ HTTP REQUEST ================================
local function httpRequest(options)
    local syn_req = syn and syn.request; local fluxus_req = fluxus and fluxus.request; local http_req = http and http.request
    local request_func = http_request or request or syn_req or fluxus_req or http_req
    if not request_func then local hs = game:GetService("HttpService"); return { StatusCode = 200, Body = hs:GetAsync(options.Url, true), Success = true } end
    return request_func(options)
end
getgenv()._XKID_REQUEST = httpRequest

-- ================================ FPS UNLOCKER ================================
local function setOptimalFPS(targetFPS)
    targetFPS = targetFPS or 120
    pcall(function() if setfpscap then setfpscap(targetFPS) end end)
    pcall(function() local rs = settings():GetService("Rendering") if rs and rs.SetTargetFrameRate then rs:SetTargetFrameRate(targetFPS) end end)
    pcall(function() local ws = game:GetService("Workspace") if ws and ws.SetTargetFrameRate then ws:SetTargetFrameRate(targetFPS) end end)
end
setOptimalFPS(120)

-- ================================ SERVICES ================================
local RunService = game:GetService("RunService"); local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players"); local UserInputService = game:GetService("UserInputService")
local VirtualUser = pcall(function() return game:GetService("VirtualUser") end) and game:GetService("VirtualUser") or nil
local Lighting = game:GetService("Lighting"); local TeleportService = game:GetService("TeleportService")
local StatsService = game:GetService("Stats"); local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService"); local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer; local Camera = workspace.CurrentCamera; local onMobile = not UserInputService.KeyboardEnabled
getgenv()._XKID_UI_LOADING = true

-- ================================ ORIGINAL LIGHTING ================================
local originalLighting = {
    ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows,
    ExposureCompensation = Lighting.ExposureCompensation, FogEnd = Lighting.FogEnd,
}

-- ================================ CLEANUP OLD INSTANCE ================================
if getgenv()._XKID_RUNNING then getgenv()._XKID_RUNNING = false; task.wait(0.5) end
if getgenv()._XKID_ESP_CACHE then for _, c in pairs(getgenv()._XKID_ESP_CACHE) do pcall(function() if c.texts then c.texts:Remove() end; if c.tracer then c.tracer:Remove() end; if c.boxLines then for _, l in ipairs(c.boxLines) do l:Remove() end end; if c.hl then c.hl:Destroy() end end) end end
getgenv()._XKID_ESP_CACHE = {}
if getgenv()._XKID_LOADED then
    pcall(function()
        for _, v in pairs(CoreGui:GetChildren()) do if v.Name == "WindUI" or v.Name == "XKID_FreecamUI" then v:Destroy() end end
        for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" then v:Destroy() end end
        if getgenv()._XKID_CONNS then for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end end
    end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDFreecam") end); pcall(function() RunService:UnbindFromRenderStep("XKIDFly") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDSpec") end); pcall(function() RunService:UnbindFromRenderStep("XKIDSelfSpec") end)
    pcall(function() RunService:UnbindFromRenderStep("XKIDShiftLock") end); pcall(function() RunService:UnbindFromRenderStep("XKIDAutoWalk") end)
end
getgenv()._XKID_LOADED = true; getgenv()._XKID_RUNNING = true; getgenv()._XKID_CONNS = {}
local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

-- ================================ DEBUG LOG SYSTEM ================================
local DebugLog = {}
local function addLog(msg, lt) lt = lt or "INFO"; local e = string.format("[%s] [%s] %s", os.date("%H:%M:%S"), lt, msg); table.insert(DebugLog, e); if #DebugLog > 100 then table.remove(DebugLog, 1) end end
local function notify(title, content, duration, icon)
    pcall(function() WindUI:Notify({ Title = title, Content = content, Duration = duration or 2, Icon = icon or "bell" }) end)
    addLog(content, "INFO")
end
addLog("Script starting...", "INFO")

-- ================================ STATE ================================
local State = {
    Move = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60, autoWalk = false, autoWalkSpeed = 16 },
    Fly = { active = false, bv = nil, bg = nil, _keys = {} },
    HardFling = { active = false, power = 10000, mode = "Spin", currentPower = 0, rampUpActive = false },
    Security = { afkActive = false, shiftLock = false, shiftLockGyro = nil, antiLag = false },
    Cinema = { hideUI = false, cachedGuis = {} }, Avatar = { isRefreshing = false },
    Utility = { chatLog = false, chatTargets = {}, chatHistory = {} },
    AutoLike = { active = false, thread = nil, lastTarget = nil, count = 0, radius = 100, minCD = 2, maxCD = 6 },
    CustomFilter = { tintR = 255, tintG = 255, tintB = 255, saturation = 0, contrast = 0, brightness = 0, exposure = 0, bloomIntensity = 0, bloomSize = 24, clockTime = 14 },
    SelfSpec = { active = false, mode = "Manual", dist = 8, height = 3, orbitYaw = 0, orbitPitch = 20, fpYaw = 0, fpPitch = 0, fov = 70, origFov = 70, roll = 0, radius = 8, speed = 1 },
    ESP = { active = false, cache = getgenv()._XKID_ESP_CACHE, maxDrawDistance = 300, highlightMode = false, boxColor_N = Color3.fromRGB(255, 0, 0), boxColor_S = Color3.fromRGB(220, 20, 60), boxColor_G = Color3.fromRGB(255, 165, 0), tracerColor_N = Color3.fromRGB(255, 0, 0), tracerColor_S = Color3.fromRGB(220, 20, 60), tracerColor_G = Color3.fromRGB(255, 165, 0), nameColor = Color3.fromRGB(255, 255, 255) },
    Spec = { active = false, target = nil, mode = "third", dist = 8, origFov = 70, orbitYaw = 0, orbitPitch = 0, fpYaw = 0, fpPitch = 0, isSelf = false },
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

-- ================================ HELPERS ================================
local function GR() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function GH() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function GDN() local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName) end end; if #t == 0 then table.insert(t, "N/A") end; return t end
local function GDNS() local t = { "[Self]" }; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName) end end; if #t == 1 then table.insert(t, "N/A") end; return t end
local function FPD(s) if s == "[Self]" then return LP end; for _, p in pairs(Players:GetPlayers()) do if p.DisplayName == s or p.Name == s then return p end end; return nil end
local function GCR(c) if not c then return nil end; return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChild("Head") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function FT(s) local m = math.floor(s / 60); local s2 = s % 60; return string.format("%02d:%02d", m, s2) end
local function MB(v, mx, l) local f = math.clamp(math.floor((v / mx) * l), 0, l); return string.rep("█", f) .. string.rep("░", l - f) end
local function GCL() local l = {}; if executor.has_isfolder and executor.has_listfiles then pcall(function() if isfolder and isfolder("XKID_HUB") then for _, f in ipairs(listfiles("XKID_HUB")) do if f:match("%.json$") then local n = f:match("([^/\\]+)%.json$"); if n then table.insert(l, n) end end end end end) end; if #l == 0 then table.insert(l, "No config") end; return l end
local function IOG() local r = GR(); if not r then return false end; local p = RaycastParams.new(); p.FilterType = Enum.RaycastFilterType.Exclude; p.FilterDescendantsInstances = { LP.Character }; return workspace:Raycast(r.Position, Vector3.new(0, -5, 0), p) ~= nil end
local function IUA() if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.MouseButton1) then return true end; if onMobile then if #UserInputService:GetTouchPositions() > 0 then return true end end; local hrp, hum = GR(), GH(); if hrp and hum and hum.MoveDirection.Magnitude > 0.1 then return true end; return false end

-- ================================ GLOBAL VARS ================================
local START_TIME = os.time(); local cachedMapName = nil; local lastMapCheck = 0; local sharedFPS = 60; local sharedPing = 0

-- ================================ FPS & PING TRACKER ================================
TrackC(RunService.RenderStepped:Connect(function(dt) if dt > 0 then sharedFPS = math.floor(1 / dt) end end))
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(0.5); pcall(function() local it = StatsService.Network.ServerStatsItem["Data Ping"]; if it then sharedPing = math.floor(it:GetValue()) end end) end end)
task.spawn(function() while getgenv()._XKID_RUNNING do pcall(function() if tick() - lastMapCheck > 30 or not cachedMapName then cachedMapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name; lastMapCheck = tick() end end); task.wait(5) end end)
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(120); collectgarbage("collect") end end)
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(30); setOptimalFPS(State.FPS.cap) end end)
TrackC(LP.CharacterAdded:Connect(function() task.wait(0.5); setOptimalFPS(State.FPS.cap) end))

-- ================================ ANTI AFK (STEALTH) ================================
local VIM = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil
local AFKSystem = { active = false, thread = nil, lastActive = 0 }
local function sendStealthAntiAFK()
    if VirtualUser and VirtualUser.ClickButton2 then pcall(function() local vp = Camera.ViewportSize; VirtualUser:ClickButton2(Vector2.new(vp.X - 5, vp.Y - 5)) end); return end
    if VIM and VIM.SendMouseButtonEvent then pcall(function() local vp = Camera.ViewportSize; VIM:SendMouseButtonEvent(vp.X - 5, vp.Y - 5, 0, true, game, 0); task.wait(0.05); VIM:SendMouseButtonEvent(vp.X - 5, vp.Y - 5, 0, false, game, 0) end); return end
    pcall(function() local r = ReplicatedStorage:FindFirstChild("Remotes"); if r then local sr = r:FindFirstChild("Ping") or r:FindFirstChild("Heartbeat"); if sr and sr.FireServer then sr:FireServer(); return end end end)
    pcall(function() local cf = Camera.CFrame; Camera.CFrame = cf * CFrame.Angles(0, math.rad(0.5), 0); task.wait(0.05); Camera.CFrame = cf end)
end
local function SAFK() if AFKSystem.active then return end; AFKSystem.active = true; State.Security.afkActive = true; AFKSystem.lastActive = tick(); AFKSystem.thread = task.spawn(function() while AFKSystem.active do task.wait(10); if not AFKSystem.active then break end; if IUA() then AFKSystem.lastActive = tick() elseif tick() - AFKSystem.lastActive >= 420 then sendStealthAntiAFK(); AFKSystem.lastActive = tick() end end end); notify("Anti AFK", "ON (Stealth)", 1.5, "shield-check") end
local function STAFK() AFKSystem.active = false; State.Security.afkActive = false; if AFKSystem.thread then task.cancel(AFKSystem.thread); AFKSystem.thread = nil end; notify("Anti AFK", "OFF", 1.5, "shield-check") end
function ToggleAntiAFK() if AFKSystem.active then STAFK() else SAFK() end end

-- ================================ SHIFT LOCK ================================
TrackC(LP.CharacterAdded:Connect(function(char)
    task.wait(0.5); local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end; if State.Move.jp ~= 50 then hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end end
    if State.Security.shiftLock then task.wait(0.2); local hrp = GR(); if hrp then if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() end; State.Security.shiftLockGyro = Instance.new("BodyGyro", hrp); State.Security.shiftLockGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); State.Security.shiftLockGyro.P = 50000; State.Security.shiftLockGyro.D = 1000 end end
end))
local function TSL(v)
    State.Security.shiftLock = v
    if v then local hrp = GR(); if hrp then if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() end; State.Security.shiftLockGyro = Instance.new("BodyGyro", hrp); State.Security.shiftLockGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); State.Security.shiftLockGyro.P = 50000; State.Security.shiftLockGyro.D = 1000 end
        RunService:BindToRenderStep("XKIDShiftLock", Enum.RenderPriority.Camera.Value + 2, function() if not State.Security.shiftLock then return end; local hrp2, gyro = GR(), State.Security.shiftLockGyro; if hrp2 and gyro and gyro.Parent == hrp2 then local fl = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z); if fl.Magnitude > 0.01 then gyro.CFrame = CFrame.new(hrp2.Position, hrp2.Position + fl) end end end); notify("Shift Lock", "ON", 1.5, "lock")
    else RunService:UnbindFromRenderStep("XKIDShiftLock"); if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy(); State.Security.shiftLockGyro = nil end; notify("Shift Lock", "OFF", 1.5, "unlock") end
end

-- ================================ REFRESH CHARACTER ================================
local rCF, rWS, rJP, rZ = nil, 16, 50, 400
local function RC() if State.Avatar.isRefreshing then return end; local c, r = LP.Character, GR(); if not c or not r then notify("Error", "Character not found", 2, "circle-alert"); return end; State.Avatar.isRefreshing = true; rCF = r.CFrame; rWS = State.Move.ws; rJP = State.Move.jp; rZ = LP.CameraMaxZoomDistance; notify("Refresh", "Reloading...", 1.5, "refresh-cw"); pcall(function() c:BreakJoints() end); local w = 0; repeat task.wait(0.1); w = w + 0.1 until not LP.Character or w > 2; if LP.Character then pcall(function() LP.Character:Destroy() end); task.wait(0.3) end; if not LP.Character then pcall(function() LP:LoadCharacter() end) end; task.delay(12, function() if State.Avatar.isRefreshing then State.Avatar.isRefreshing = false; rCF = nil; notify("Error", "Refresh timeout", 3, "circle-alert") end end) end
TrackC(LP.CharacterAdded:Connect(function(nc) if not State.Avatar.isRefreshing or not rCF then return end; task.wait(0.3); local nr = nc:FindFirstChild("HumanoidRootPart") or nc:WaitForChild("HumanoidRootPart", 8); local nh = nc:FindFirstChildOfClass("Humanoid") or nc:WaitForChild("Humanoid", 8); if nr and nh then repeat task.wait() until nh.Health > 0 and nr:IsDescendantOf(workspace); nr.CFrame = rCF + Vector3.new(0, 4, 0); nr.AssemblyLinearVelocity = Vector3.zero; nr.AssemblyAngularVelocity = Vector3.zero; nh.WalkSpeed = rWS; nh.UseJumpPower = true; nh.JumpPower = rJP; Camera.CameraSubject = nh; Camera.CameraType = Enum.CameraType.Custom; pcall(function() LP.CameraMaxZoomDistance = rZ end); notify("Refresh", "Done", 2, "check-circle") end; State.Avatar.isRefreshing = false; rCF = nil end))

-- ================================ SMART TP ================================
local TPt = { cc = nil, ca = false, ta = false, tl = nil }
local function ETP() local r = GR(); if not r then return end; local m = LP:GetMouse(); if m.Hit then r.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3.5, 0)); r.AssemblyLinearVelocity = Vector3.zero end end
local function TSTP(v) TPt.ca = v; if v then pcall(function() local t = Instance.new("Tool"); t.Name = "TP Tool"; t.RequiresHandle = false; t.Parent = LP.Backpack; TPt.tl = t; TPt.ta = false; t.Activated:Connect(function() TPt.ta = not TPt.ta end) end); TPt.cc = TrackC(UserInputService.InputBegan:Connect(function(inp, gp) if gp then return end; if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then if TPt.ta then ETP(); TPt.ta = false end end end)); notify("Smart TP", "ON", 2, "map-pin") else if TPt.cc then TPt.cc:Disconnect(); TPt.cc = nil end; pcall(function() if TPt.tl then TPt.tl:Destroy(); TPt.tl = nil end end); TPt.ta = false; notify("Smart TP", "OFF", 1.5, "map-pin") end end

-- ================================ AUTO WALK ================================
local function SAW() RunService:UnbindFromRenderStep("XKIDAutoWalk"); State.Move.autoWalk = true; local h = GH(); if h then h.WalkSpeed = State.Move.autoWalkSpeed end; RunService:BindToRenderStep("XKIDAutoWalk", Enum.RenderPriority.Character.Value + 1, function() if not State.Move.autoWalk then return end; local r, h = GR(), GH(); if not r or not h then return end; if h.MoveDirection.Magnitude > 0.1 then return end; local cd = Camera.CFrame.LookVector; local md = Vector3.new(cd.X, 0, cd.Z).Unit; r.CFrame = r.CFrame + md * (State.Move.autoWalkSpeed / 60) end); notify("Auto Walk", "ON", 1.5, "play") end
local function STAW() RunService:UnbindFromRenderStep("XKIDAutoWalk"); State.Move.autoWalk = false; local h = GH(); if h then h.WalkSpeed = State.Move.ws end; notify("Auto Walk", "OFF", 1.5, "play") end

-- ================================ ESP ENGINE ================================
local function IPC(p) if State.ESP.cache[p] then return end; local c = { texts = nil, tracer = nil, boxLines = {}, hl = nil, isSuspect = false, isGlitch = false, reason = "" }; pcall(function() c.texts = Drawing.new("Text"); if c.texts then c.texts.Center = true; c.texts.Outline = true; c.texts.Font = 2; c.texts.Size = 13; c.texts.ZIndex = 2 end; c.tracer = Drawing.new("Line"); if c.tracer then c.tracer.Thickness = 1.5; c.tracer.ZIndex = 1 end; for i = 1, 4 do local l = Drawing.new("Line"); if l then l.Thickness = 1.5; l.ZIndex = 1; c.boxLines[i] = l end end end); State.ESP.cache[p] = c end
local function CPC(p) local c = State.ESP.cache[p]; if not c then return end; pcall(function() if c.texts then c.texts:Remove() end end); pcall(function() if c.tracer then c.tracer:Remove() end end); for _, l in ipairs(c.boxLines) do pcall(function() if l then l:Remove() end end) end; pcall(function() if c.hl then c.hl:Destroy() end end); State.ESP.cache[p] = nil end
TrackC(Players.PlayerRemoving:Connect(CPC))
local eL = {}
task.spawn(function() while getgenv()._XKID_RUNNING do if State.ESP.active then local tmp = {}; local mh = GCR(LP.Character); for _, p in pairs(Players:GetPlayers()) do if p ~= LP and p.Character then local is, ig, rs = false, false, ""; for _, v in pairs(p.Character:GetChildren()) do if v:IsA("BasePart") and (v.Size.X > 30 or v.Size.Y > 30 or v.Size.Z > 30) then is = true; rs = "Map Blocker"; break elseif v:IsA("Accessory") then local h = v:FindFirstChild("Handle"); if h and h:IsA("BasePart") then if h.Size.Magnitude > 20 then is = true; rs = "Huge Hat"; break elseif h.Size.Magnitude > 10 or (h.Transparency < 0.1 and h.Material == Enum.Material.Neon) then ig = true; rs = "Glitch Acc" end end end end; if not is and not ig then local h = p.Character:FindFirstChildOfClass("Humanoid"); if h then local bw = h:FindFirstChild("BodyWidthScale"); local bh = h:FindFirstChild("BodyHeightScale"); if (bw and bw.Value > 2) or (bh and bh.Value > 2) then is = true; rs = "Glitch Av" end end end; IPC(p); if State.ESP.cache[p] then State.ESP.cache[p].isSuspect = is; State.ESP.cache[p].isGlitch = ig; State.ESP.cache[p].reason = rs end; if mh then local hr = GCR(p.Character); local h = p.Character:FindFirstChildOfClass("Humanoid"); if hr and h and h.Health > 0 then local d = (hr.Position - mh.Position).Magnitude; if d <= State.ESP.maxDrawDistance then table.insert(tmp, { p = p, hr = hr, d = d, c = p.Character }) end end end end end; table.sort(tmp, function(a, b) return a.d < b.d end); eL = tmp end; task.wait(0.5) end end)
TrackC(RunService.RenderStepped:Connect(function() if not State.ESP.active then return end; local mh = GCR(LP.Character); if not mh then return end; local vp = Camera.ViewportSize; for _, c in pairs(State.ESP.cache) do pcall(function() if c.texts then c.texts.Visible = false end; if c.tracer then c.tracer.Visible = false end; for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end; if c.hl then c.hl.Enabled = false end end) end; local hc = 0; for _, d in ipairs(eL) do local p, c, hr, dist = d.p, d.c, d.hr, d.d; local c2 = State.ESP.cache[p]; if not c2 then continue end; local pos, vis = Camera:WorldToViewportPoint(hr.Position); if not vis then continue end; local sus, glitch = c2.is, c2.ig; local uhl = sus or glitch or State.ESP.highlightMode; local txt = string.format("%s\n[%dm]", p.DisplayName, math.floor(dist)); if sus or glitch then txt = txt .. "\n⚠ " .. c2.rs end; local ccol = sus and State.ESP.boxColor_S or (glitch and State.ESP.boxColor_G or State.ESP.nameColor); local tcol = sus and State.ESP.tracerColor_S or (glitch and State.ESP.tracerColor_G or State.ESP.tracerColor_N); local bcol = sus and State.ESP.boxColor_S or (glitch and State.ESP.boxColor_G or State.ESP.boxColor_N); pcall(function() if c2.texts then c2.texts.Text = txt; c2.texts.Color = ccol; c2.texts.Position = Vector2.new(pos.X, pos.Y - 45); c2.texts.Visible = true end; if c2.tracer then local org = Vector2.new(vp.X / 2, vp.Y); c2.tracer.From = org; c2.tracer.To = Vector2.new(pos.X, pos.Y); c2.tracer.Color = tcol; c2.tracer.Visible = true end end); if uhl and hc < 30 then hc = hc + 1; pcall(function() local top, tv = Camera:WorldToViewportPoint(hr.Position + Vector3.new(0, 3, 0)); local bot, bv = Camera:WorldToViewportPoint(hr.Position - Vector3.new(0, 3.5, 0)); if tv and bv and #c2.boxLines == 4 then local bh = math.abs(top.Y - bot.Y); local bw = bh * 0.6; c2.boxLines[1].From = Vector2.new(pos.X - bw / 2, top.Y); c2.boxLines[1].To = Vector2.new(pos.X + bw / 2, top.Y); c2.boxLines[2].From = Vector2.new(pos.X + bw / 2, top.Y); c2.boxLines[2].To = Vector2.new(pos.X + bw / 2, bot.Y); c2.boxLines[3].From = Vector2.new(pos.X + bw / 2, bot.Y); c2.boxLines[3].To = Vector2.new(pos.X - bw / 2, bot.Y); c2.boxLines[4].From = Vector2.new(pos.X - bw / 2, bot.Y); c2.boxLines[4].To = Vector2.new(pos.X - bw / 2, top.Y); for i = 1, 4 do c2.boxLines[i].Color = bcol; c2.boxLines[i].Visible = true end end end); pcall(function() if not c2.hl or c2.hl.Parent ~= c then if c2.hl then c2.hl:Destroy() end; c2.hl = Instance.new("Highlight", c); c2.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end; if c2.hl then c2.hl.FillColor = bcol; c2.hl.OutlineColor = Color3.new(1, 1, 1); c2.hl.Enabled = true end end) end end end end))

-- ================================ FLY ENGINE ================================
local fmt, fts, fj, fcs, fv = nil, nil, Vector2.zero, {}, Vector3.zero
local function SFC() local ks = {}; table.insert(fcs, UserInputService.InputBegan:Connect(function(inp, gp) if gp then return end; local k = inp.KeyCode; if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then ks[k] = true end end)); table.insert(fcs, UserInputService.InputEnded:Connect(function(inp) ks[inp.KeyCode] = nil end)); table.insert(fcs, UserInputService.InputBegan:Connect(function(inp, gp) if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp.Position.X <= Camera.ViewportSize.X / 2 then if not fmt then fmt = inp; fts = inp.Position end end end)); table.insert(fcs, UserInputService.TouchMoved:Connect(function(inp) if inp == fmt and fts then local dx = inp.Position.X - fts.X; local dy = inp.Position.Y - fts.Y; local function ad(v, d, m) if math.abs(v) < d then return 0 end; return math.clamp((v - math.sign(v) * d) / (m - d), -1, 1) end; fj = Vector2.new(ad(dx, 25, 80), ad(dy, 20, 80)) end end)); table.insert(fcs, UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp == fmt then fmt = nil; fts = nil; fj = Vector2.zero end end)); State.Fly._keys = ks end
local function STFC() for _, c in ipairs(fcs) do c:Disconnect() end; fcs = {}; fmt = nil; fts = nil; fj = Vector2.zero; State.Fly._keys = {} end
local function TF(v) if not v then State.Fly.active = false; STFC(); RunService:UnbindFromRenderStep("XKIDFly"); pcall(function() if State.Fly.bv then State.Fly.bv:Destroy() end end); pcall(function() if State.Fly.bg then State.Fly.bg:Destroy() end end); State.Fly.bv = nil; State.Fly.bg = nil; fv = Vector3.zero; local h = GH(); if h then h.PlatformStand = false; h:ChangeState(Enum.HumanoidStateType.GettingUp); h.WalkSpeed = State.Move.ws; h.UseJumpPower = true; h.JumpPower = State.Move.jp; h.AutoRotate = true end; notify("Fly", "OFF", 1.5, "bird"); return end; local r, h = GR(), GH(); if not r or not h then return end; State.Fly.active = true; h.PlatformStand = true; fv = Vector3.zero; h.AutoRotate = false; State.Fly.bv = Instance.new("BodyVelocity", r); State.Fly.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); State.Fly.bg = Instance.new("BodyGyro", r); State.Fly.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); State.Fly.bg.P = 50000; SFC(); notify("Fly", "ON", 2, "bird"); RunService:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value + 1, function() if not State.Fly.active then return end; local r2 = GR(); if not r2 then return end; local cf = Camera.CFrame; local spd = State.Move.flyS; local mv = Vector3.zero; local ks = State.Fly._keys or {}; if onMobile then mv = cf.LookVector * (-fj.Y) + cf.RightVector * fj.X else if ks[Enum.KeyCode.W] then mv = mv + cf.LookVector end; if ks[Enum.KeyCode.S] then mv = mv - cf.LookVector end; if ks[Enum.KeyCode.D] then mv = mv + cf.RightVector end; if ks[Enum.KeyCode.A] then mv = mv - cf.RightVector end; if ks[Enum.KeyCode.E] then mv = mv + Vector3.new(0, 1, 0) end; if ks[Enum.KeyCode.Q] then mv = mv - Vector3.new(0, 1, 0) end end; if mv.Magnitude > 0 then fv = fv:Lerp(mv.Unit * spd, 0.15) else fv = fv:Lerp(IOG() and Vector3.zero or Vector3.new(0, -0.8, 0), 0.08) end; if State.Fly.bv and State.Fly.bv.Parent then State.Fly.bv.Velocity = fv end; if State.Fly.bg and State.Fly.bg.Parent then State.Fly.bg.CFrame = CFrame.new(r2.Position, r2.Position + cf.LookVector) end end) end

-- ================================ FREECAM ENGINE ================================
local FC = { ac = false, pos = Vector3.zero, pi = 0, ya = 0, ro = 0, sp = 3, se = 0.25, of = 70, sWS = 16, sJP = 16, wa = false }
local cV, yV, pV, rV, hV = Vector3.zero, 0, 0, 0, 0; local fmT, fmS, fmJ, frT, frL, fKH, fCs = nil, nil, Vector2.zero, nil, nil, {}, {}
local FC_UB = { up = false, dn = false, rl = false, rr = false, zi = false, zo = false }; local FC_UH = false; local fB = {}
local FCUI = Instance.new("ScreenGui"); FCUI.Name = "XKID_FreecamUI"; FCUI.ResetOnSpawn = false; FCUI.ZIndexBehavior = Enum.ZIndexBehavior.Global; FCUI.Enabled = false; FCUI.Parent = CoreGui; getgenv()._XKID_FCUI = FCUI
local function MFB(n, t, p, a) local b = Instance.new("TextButton", FCUI); b.Name = n; b.Size = UDim2.new(0, 44, 0, 44); b.Position = p; b.BackgroundColor3 = Color3.fromRGB(15, 15, 15); b.BackgroundTransparency = 0.4; b.Text = t; b.TextColor3 = Color3.fromRGB(255, 255, 255); b.TextSize = 18; b.Font = Enum.Font.GothamBold; b.AutoButtonColor = false; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10); local us = Instance.new("UIStroke", b); us.Color = Color3.fromRGB(220, 20, 60); us.Thickness = 2; us.Transparency = 0.3; local ind = Instance.new("Frame", b); ind.Name = "Indicator"; ind.Size = UDim2.new(0, 6, 0, 6); ind.Position = UDim2.new(0, 4, 0, 4); ind.BackgroundColor3 = Color3.fromRGB(60, 60, 60); Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0); local function pr(d) FC_UB[a] = d; b.BackgroundTransparency = d and 0.05 or 0.4; ind.BackgroundColor3 = d and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(60, 60, 60) end; b.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then pr(true) end end); b.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then pr(false) end end); b.MouseLeave:Connect(function() pr(false) end); table.insert(fB, b); return b end
MFB("BtnRollL", "L", UDim2.new(1, -156, 0.5, -66), "rl"); MFB("BtnRollR", "R", UDim2.new(1, -58, 0.5, -66), "rr"); MFB("BtnUp", "↑", UDim2.new(1, -107, 0.5, -110), "up"); MFB("BtnDown", "↓", UDim2.new(1, -107, 0.5, -22), "dn"); MFB("BtnZIn", "+", UDim2.new(1, -156, 0.5, -22), "zi"); MFB("BtnZOut", "-", UDim2.new(1, -58, 0.5, -22), "zo")
local eBtn = Instance.new("TextButton", FCUI); eBtn.Name = "BtnEye"; eBtn.Size = UDim2.new(0, 44, 0, 44); eBtn.Position = UDim2.new(1, -107, 0.5, -66); eBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15); eBtn.BackgroundTransparency = 0.6; eBtn.Text = "👁"; eBtn.TextColor3 = Color3.fromRGB(255, 255, 255); eBtn.TextSize = 18; eBtn.Font = Enum.Font.GothamBold; eBtn.AutoButtonColor = false; Instance.new("UICorner", eBtn).CornerRadius = UDim.new(0, 10); Instance.new("UIStroke", eBtn)
local function TFE() FC_UH = not FC_UH; eBtn.Text = FC_UH and "👁‍🗨" or "👁"; for _, b in ipairs(fB) do b.Visible = not FC_UH end end
eBtn.MouseButton1Click:Connect(TFE); eBtn.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch then TFE() end end)
local function SFCC() fKH = {}; table.insert(fCs, UserInputService.InputBegan:Connect(function(inp, gp) if gp then return end; fKH[inp.KeyCode] = true; if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mr = true; UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition end end)); table.insert(fCs, UserInputService.InputEnded:Connect(function(inp) fKH[inp.KeyCode] = false; if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mr = false; UserInputService.MouseBehavior = Enum.MouseBehavior.Default end end)); table.insert(fCs, UserInputService.InputChanged:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseMovement and FC._mr then yV = yV - inp.Delta.X * FC.se * 120; pV = pV - inp.Delta.Y * FC.se * 120 end end)); table.insert(fCs, UserInputService.InputBegan:Connect(function(inp, gp) if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp.Position.X > Camera.ViewportSize.X / 2 then if not frT then frT = inp; frL = inp.Position end else if not fmT then fmT = inp; fmS = inp.Position; fmJ = Vector2.zero end end end)); table.insert(fCs, UserInputService.TouchMoved:Connect(function(inp) if inp == frT and frL then local dx = inp.Position.X - frL.X; local dy = inp.Position.Y - frL.Y; frL = inp.Position; yV = yV - dx * FC.se * 80; pV = pV - dy * FC.se * 80 end; if inp == fmT and fmS then local dx = inp.Position.X - fmS.X; local dy = inp.Position.Y - fmS.Y; local function ad(v, d, m) if math.abs(v) < d then return 0 end; return math.clamp((v - math.sign(v) * d) / (m - d), -1, 1) end; fmJ = Vector2.new(ad(dx, 15, 70), ad(dy, 15, 70)) end end)); table.insert(fCs, UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp == frT then frT = nil; frL = nil end; if inp == fmT then fmT = nil; fmS = nil; fmJ = Vector2.zero end end)) end
local function STFCC() for _, c in ipairs(fCs) do c:Disconnect() end; fCs = {}; fKH = {}; FC._mr = false; UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
local function SFCL() RunService:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt) if not FC.ac then return end; Camera.CameraType = Enum.CameraType.Scriptable; local sdt = math.clamp(dt, 0.001, 0.05); yV = yV * math.max(0, 1 - sdt * 14); pV = pV * math.max(0, 1 - sdt * 14); FC.ya = FC.ya + yV * sdt; FC.pi = math.clamp(FC.pi + pV * sdt, -80, 80); local rt = 0; if FC_UB.rl then rt = -100 elseif FC_UB.rr then rt = 100 end; rV = rV + (rt - rV) * math.clamp(sdt * 5, 0, 1); FC.ro = math.clamp(FC.ro + rV * sdt, -100, 100); local cf = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.ya), 0) * CFrame.Angles(math.rad(FC.pi), 0, 0); local jx, jy = fmJ.X, fmJ.Y; if not MO then if fKH[Enum.KeyCode.W] then jy = jy - 1 end; if fKH[Enum.KeyCode.S] then jy = jy + 1 end; if fKH[Enum.KeyCode.D] then jx = jx + 1 end; if fKH[Enum.KeyCode.A] then jx = jx - 1 end end; local rm = Vector2.new(jx, jy); if rm.Magnitude > 1 then rm = rm.Unit end; cV = cV:Lerp((cf.LookVector * (-rm.Y) + cf.RightVector * rm.X) * (FC.sp * 60), math.clamp(sdt * 3.5, 0, 1)); local ht = 0; if fKH[Enum.KeyCode.E] or FC_UB.up then ht = FC.sp * 60 end; if fKH[Enum.KeyCode.Q] or FC_UB.dn then ht = -FC.sp * 60 end; if ht == 0 then hV = hV * math.max(0, 1 - sdt * 10) else hV = hV + (ht - hV) * math.clamp(sdt * 3, 0, 1) end; if FC_UB.zi then Camera.FieldOfView = math.clamp(Camera.FieldOfView - 1.2, 10, 120) end; if FC_UB.zo then Camera.FieldOfView = math.clamp(Camera.FieldOfView + 1.2, 10, 120) end; FC.pos = FC.pos + (cV + Vector3.new(0, hV, 0)) * sdt; Camera.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.ya), 0) * CFrame.Angles(math.rad(FC.pi), 0, 0) * CFrame.Angles(0, 0, math.rad(FC.ro)) end) end
local function STFCL() RunService:UnbindFromRenderStep("XKIDFreecam") end
local function FCFC() STFCL(); STFCC(); local h, r = GH(), GR(); if h then h.WalkSpeed = FC.sWS; h.UseJumpPower = true; h.JumpPower = FC.sJP; h.AutoRotate = true end; if FC.wa and r then r.Anchored = false; FC.wa = false end; Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = FC.of; if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = false end; for k in pairs(FC_UB) do FC_UB[k] = false end; FC_UH = false; eBtn.Text = "👁"; for _, b in ipairs(fB) do b.Visible = true end end

-- ================================ SELF-SPECTATE ================================
local SS = State.SelfSpec; local stm, spin, spinD, span, scns = nil, {}, nil, Vector2.zero, {}
local function SSSG() scns = {}; table.insert(scns, UserInputService.InputBegan:Connect(function(inp, gp) if gp or not SS.ac or inp.UserInputType ~= Enum.UserInputType.Touch then return end; table.insert(spin, inp); stm = #spin == 1 and inp or nil end)); table.insert(scns, UserInputService.InputChanged:Connect(function(inp) if not SS.ac or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if #spin == 1 and inp == stm then span = span + Vector2.new(inp.Delta.X, inp.Delta.Y) elseif #spin >= 2 then local d = (spin[1].Position - spin[2].Position).Magnitude; if spinD then local diff = d - spinD; Camera.FieldOfView = math.clamp(Camera.FieldOfView - diff * 0.15, 10, 120); SS.rd = math.clamp(SS.rd - diff * 0.03, 3, 30) end; spinD = d end end)); table.insert(scns, UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; for i, v in ipairs(spin) do if v == inp then table.remove(spin, i); break end end; spinD = nil; stm = #spin == 1 and spin[1] or nil end)) end
local function STSSG() for _, c in ipairs(scns) do c:Disconnect() end; scns = {}; stm = nil; spin = {}; spinD = nil; span = Vector2.zero end
local function SSSL() RunService:UnbindFromRenderStep("XKIDSelfSpec"); RunService:BindToRenderStep("XKIDSelfSpec", Enum.RenderPriority.Camera.Value + 1, function() if not SS.ac then return end; pcall(function() local tc = LP.Character; local tr = GCR(tc); if not tr then return end; Camera.CameraType = Enum.CameraType.Scriptable; local pn, sn = span, MO and 0.2 or 0.3; span = Vector2.zero; if SS.md == "First Person" then local hd = tc:FindFirstChild("Head"); local og = hd and hd.Position or tr.Position + Vector3.new(0, 1.5, 0); SS.fy = SS.fy - pn.X * sn; SS.fp = math.clamp(SS.fp - pn.Y * sn, -85, 85); Camera.CFrame = CFrame.new(og) * CFrame.Angles(0, math.rad(SS.fy), 0) * CFrame.Angles(math.rad(SS.fp), 0, 0) else if #spin == 0 and pn.Magnitude < 0.01 then local dt = 0.016; if SS.md == "Slow Orbit" then SS.oy = SS.oy + dt * 25 * SS.sp elseif SS.md == "Vertical Swing" then SS.op = 20 + math.sin(tick() * SS.sp * 1.5) * 40; SS.oy = SS.oy + dt * 10 * SS.sp elseif SS.md == "Figure 8" then SS.oy = math.sin(tick() * SS.sp * 0.8) * 80; SS.op = 20 + math.sin(tick() * SS.sp * 1.2) * 35 elseif SS.md == "Cinematic Drift" then SS.oy = SS.oy + dt * 15 * SS.sp; SS.op = 20 + math.sin(tick() * SS.sp * 0.7) * 15 elseif SS.md == "Top Down" then SS.op = -75; SS.oy = SS.oy + dt * 8 * SS.sp end end; SS.oy = SS.oy + pn.X * sn; SS.op = math.clamp(SS.op + pn.Y * sn, -75, 75); local h = (SS.md == "Top Down") and 15 or (SS.he or 3); Camera.CFrame = CFrame.new((CFrame.new(tr.Position + Vector3.new(0, h, 0)) * CFrame.Angles(0, math.rad(-SS.oy), 0) * CFrame.Angles(math.rad(-SS.op), 0, 0) * CFrame.new(0, 0, SS.rd)).Position, tr.Position + Vector3.new(0, h, 0)) end end) end) end
local function STSSL() RunService:UnbindFromRenderStep("XKIDSelfSpec"); Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = SS.of; SS.ac = false; SS.oy = 0; SS.op = 20; SS.fy = 0; SS.fp = 0; SS.rd = 8; SS.he = 3; span = Vector2.zero end
local function TSS(v) if v then if FC.ac then FCFC() end; if State.Fly.ac then STFC() end; if State.Spec.ac then STSPC() end; if TPt.cc then TPt.cc:Disconnect(); TPt.cc = nil end; SS.ac = true; SS.of = Camera.FieldOfView; SS.oy = 0; SS.op = 20; SS.fy = 0; SS.fp = 0; SS.rd = SS.rd or 8; SS.he = SS.he or 3; SSSG(); SSSL(); notify("Self-Spectate", "ON — " .. (SS.md or "Manual"), 2, "camera") else SS.ac = false; STSSG(); STSSL(); notify("Self-Spectate", "OFF", 1.5, "camera") end end

-- ================================ SPECTATE ================================
local Sp = State.Spec; local stm2, spin2, spinD2, span2, scns2 = nil, {}, nil, Vector2.zero, {}
local function SSPC() table.insert(scns2, UserInputService.InputBegan:Connect(function(inp, gp) if gp or not Sp.ac or inp.UserInputType ~= Enum.UserInputType.Touch then return end; table.insert(spin2, inp); stm2 = #spin2 == 1 and inp or nil end)); table.insert(scns2, UserInputService.InputChanged:Connect(function(inp) if not Sp.ac or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if #spin2 == 1 and inp == stm2 then span2 = span2 + Vector2.new(inp.Delta.X, inp.Delta.Y) elseif #spin2 >= 2 then local d = (spin2[1].Position - spin2[2].Position).Magnitude; if spinD2 then local diff = d - spinD2; Camera.FieldOfView = math.clamp(Camera.FieldOfView - diff * 0.15, 10, 120); if Sp.md == "third" then Sp.ds = math.clamp(Sp.ds - diff * 0.03, 3, 30) end end; spinD2 = d end end)); table.insert(scns2, UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; for i, v in ipairs(spin2) do if v == inp then table.remove(spin2, i); break end end; spinD2 = nil; stm2 = #spin2 == 1 and spin2[1] or nil end)) end
local function STSPC() for _, c in ipairs(scns2) do c:Disconnect() end; scns2 = {}; stm2 = nil; spin2 = {}; spinD2 = nil; span2 = Vector2.zero end
local function SSPL() RunService:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value + 1, function() if not Sp.ac then return end; pcall(function() local tc, tr; if Sp.is then tc = LP.Character; tr = GCR(tc) else if not Sp.tg or not Sp.tg.Character then Sp.ac = false; STSPL(); STSPC(); Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = Sp.of; return end; tc = Sp.tg.Character; tr = tc:FindFirstChild("HumanoidRootPart") end; if not tr then if not Sp.is then Sp.ac = false; STSPL(); STSPC(); Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = Sp.of end; return end; Camera.CameraType = Enum.CameraType.Scriptable; local pn, sn = span2, 0.3; span2 = Vector2.zero; if Sp.md == "third" then Sp.oy = Sp.oy + pn.X * sn; Sp.op = math.clamp(Sp.op + pn.Y * sn, -75, 75); Camera.CFrame = CFrame.new((CFrame.new(tr.Position) * CFrame.Angles(0, math.rad(-Sp.oy), 0) * CFrame.Angles(math.rad(-Sp.op), 0, 0) * CFrame.new(0, 0, Sp.ds)).Position, tr.Position + Vector3.new(0, 1, 0)) else local hd = tc:FindFirstChild("Head"); local og = hd and hd.Position or tr.Position + Vector3.new(0, 1.5, 0); Sp.fy = Sp.fy - pn.X * sn; Sp.fp = math.clamp(Sp.fp - pn.Y * sn, -85, 85); Camera.CFrame = CFrame.new(og) * CFrame.Angles(0, math.rad(Sp.fy), 0) * CFrame.Angles(math.rad(Sp.fp), 0, 0) end end) end) end
local function STSPL() RunService:UnbindFromRenderStep("XKIDSpec") end

-- ================================ HARD FLING ================================
local hfC, hfRC, hfBAV = nil, nil, nil
local function SHF() if State.HardFling.active then return end; State.HardFling.active = true; State.Move.ncp = true; State.HardFling.currentPower = 0; State.HardFling.rampUpActive = true; local r = GR(); if r then hfBAV = Instance.new("BodyAngularVelocity", r); hfBAV.MaxTorque = Vector3.new(9e9, 9e9, 9e9); hfBAV.P = 100000 end; local rs = tick(); hfRC = TrackC(RunService.Heartbeat:Connect(function() if not State.HardFling.rampUpActive then return end; local t = math.clamp((tick() - rs) / 2, 0, 1); State.HardFling.currentPower = State.HardFling.power * t; if t >= 1 then State.HardFling.currentPower = State.HardFling.power; State.HardFling.rampUpActive = false end end)); hfC = TrackC(RunService.Heartbeat:Connect(function() if not State.HardFling.active then return end; local r2 = GR(); if not r2 then return end; if State.HardFling.mode == "Spin" then if hfBAV and hfBAV.Parent then hfBAV.AngularVelocity = Vector3.new(0, State.HardFling.currentPower, 0) end elseif State.HardFling.mode == "Shake" then if hfBAV and hfBAV.Parent then local sx = (math.random() - 0.5) * State.HardFling.currentPower * 0.5; local sy = (math.random() - 0.5) * State.HardFling.currentPower * 0.3; local sz = (math.random() - 0.5) * State.HardFling.currentPower * 0.5; hfBAV.AngularVelocity = Vector3.new(sx, sy, sz) end end; if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)); notify("Hard Fling", "ON — " .. State.HardFling.mode, 2, "zap") end
local function STHF() State.HardFling.active = false; State.HardFling.rampUpActive = false; State.HardFling.currentPower = 0; if hfC then hfC:Disconnect(); hfC = nil end; if hfRC then hfRC:Disconnect(); hfRC = nil end; if hfBAV then hfBAV:Destroy(); hfBAV = nil end; local r = GR(); if r then pcall(function() r.AssemblyAngularVelocity = Vector3.zero; r.AssemblyLinearVelocity = Vector3.zero end) end; if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end; notify("Hard Fling", "OFF", 1.5, "zap") end

-- ================================ AUTO LIKE ================================
local function GLR() local r = ReplicatedStorage:FindFirstChild("Remotes"); if not r then return nil, nil end; return r:FindFirstChild("GetLikeDataRemote"), r:FindFirstChild("LikePlayerEvent") end
local function LRP() local _, lp = GLR(); if not lp then return false, "Remote not found" end; local mr = GR(); local tg = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then if State.AutoLike.radius > 0 and mr then local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if tr then local d = (tr.Position - mr.Position).Magnitude; if d <= State.AutoLike.radius then table.insert(tg, p) end end else table.insert(tg, p) end end end; if #tg == 0 then return false, "No players" end; local t; if #tg == 1 then t = tg[1] else repeat t = tg[math.random(1, #tg)] until t ~= State.AutoLike.lastTarget or #tg <= 1 end; State.AutoLike.lastTarget = t; local s = pcall(function() lp:FireServer(t) end); if s then State.AutoLike.count = State.AutoLike.count + 1; return true, t.DisplayName end; return false, "Failed" end
local function SAL() if State.AutoLike.active then return end; State.AutoLike.active = true; State.AutoLike.thread = task.spawn(function() while State.AutoLike.active and getgenv()._XKID_RUNNING do local o, r = LRP(); if o then notify("Auto Like", r .. " | Total: " .. State.AutoLike.count, 1.5, "heart") end; local cd = math.random(State.AutoLike.minCD * 10, State.AutoLike.maxCD * 10) / 10; task.wait(cd) end; State.AutoLike.thread = nil end); notify("Auto Like", "ON", 2, "heart") end
local function STAL() State.AutoLike.active = false; if State.AutoLike.thread then task.cancel(State.AutoLike.thread); State.AutoLike.thread = nil end; notify("Auto Like", "OFF", 1.5, "heart") end

-- ================================ FILTERS ================================
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
local function RFL() for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" then v:Destroy() end end end
local function ACF() RFL(); Lighting.Brightness = originalLighting.Brightness; Lighting.Ambient = originalLighting.Ambient; Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient; Lighting.GlobalShadows = originalLighting.GlobalShadows; Lighting.FogEnd = originalLighting.FogEnd; Lighting.ExposureCompensation = State.CustomFilter.exposure; local cc = Instance.new("ColorCorrectionEffect", Lighting); cc.Name = "_XKID_FILTER"; cc.TintColor = Color3.fromRGB(State.CustomFilter.tintR, State.CustomFilter.tintG, State.CustomFilter.tintB); cc.Saturation = State.CustomFilter.saturation; cc.Contrast = State.CustomFilter.contrast; cc.Brightness = State.CustomFilter.brightness; local bl = Instance.new("BloomEffect", Lighting); bl.Name = "_XKID_FILTER"; bl.Intensity = State.CustomFilter.bloomIntensity; bl.Size = State.CustomFilter.bloomSize; Lighting.ClockTime = State.CustomFilter.clockTime end
local function AF(n) RFL(); Lighting.ClockTime = originalLighting.ClockTime; Lighting.Brightness = originalLighting.Brightness; Lighting.Ambient = originalLighting.Ambient; Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient; Lighting.GlobalShadows = originalLighting.GlobalShadows; Lighting.FogEnd = originalLighting.FogEnd; Lighting.ExposureCompensation = originalLighting.ExposureCompensation; if n == "Default" then State.CustomFilter.tintR = 255; State.CustomFilter.tintG = 255; State.CustomFilter.tintB = 255; State.CustomFilter.saturation = 0; State.CustomFilter.contrast = 0; State.CustomFilter.brightness = 0; State.CustomFilter.exposure = 0; State.CustomFilter.bloomIntensity = 0; State.CustomFilter.bloomSize = 24; State.CustomFilter.clockTime = 14; notify("Visuals", "Default", 1.5, "palette"); return end; if n == "Custom" then ACF(); notify("Visuals", "Custom FX", 1.5, "palette"); return end; local key = n:gsub(" ", "_"):gsub(" HD", "_HD"); local p = FILTER_PRESETS[key]; if p then Lighting.ClockTime = p.time or 14; Lighting.Brightness = p.lightB or 1; Lighting.ExposureCompensation = p.exp or 0; Lighting.GlobalShadows = p.shadow ~= false; if p.ambient then Lighting.Ambient = p.ambient end; if p.outdoor then Lighting.OutdoorAmbient = p.outdoor end; local cc = Instance.new("ColorCorrectionEffect", Lighting); cc.Name = "_XKID_FILTER"; cc.TintColor = p.tint; cc.Saturation = p.sat or 0; cc.Contrast = p.con or 0; cc.Brightness = p.bri or 0; local bl = Instance.new("BloomEffect", Lighting); bl.Name = "_XKID_FILTER"; bl.Intensity = p.bloomI or 0; bl.Size = p.bloomS or 24; for k, v in pairs(p) do if State.CustomFilter[k] ~= nil then State.CustomFilter[k] = v end end; notify("Visuals", n, 2, "palette") else notify("Visuals", "Filter not found", 2, "circle-alert") end end

-- ================================ MAIN WINDOW ================================
local Win = W:CreateWindow({ Title = "XKID_HUB", Icon = "bluetooth", Author = "@WTF.XKID", Folder = "XKIDHub", Size = UDim2.fromOffset(360, 320), Transparent = true, Theme = "Crimson", SideBarWidth = 160, User = { Enabled = true, Anonymous = false }, Topbar = { Height = 40, ButtonsType = "Default" } })
pcall(function() W:SetFont("rbxassetid://12187376357"); W:SetNotificationLower(true); Win.User:SetDisplayName(LP.DisplayName); Win.User:SetUsername("@" .. LP.Name) end)
Win:EditOpenButton({ Title = "WTF.XKID", Icon = "github", CornerRadius = UDim.new(1, 0), StrokeThickness = 2, StrokeColor = Color3.fromRGB(255, 70, 120), Enabled = true, Draggable = true, Scale = 0.72 })
local FpsTag = Win:Tag({ Title = "FPS: -- | Ping: --", Color = Color3.fromRGB(255, 215, 0), Icon = "activity" })
local VerTag = Win:Tag({ Title = "V3.4", Color = Color3.fromRGB(255, 215, 0), Icon = "tag" })
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(1); if FpsTag and FpsTag.SetTitle then FpsTag:SetTitle("FPS: " .. sharedFPS .. " | Ping: " .. sharedPing .. "ms") end end end)

-- ================================ TAB: INFORMASI ================================
local tInfo = Win:Tab({ Title = "Informasi", Icon = "activity" })
local function GE() pcall(function() local e = identifyexecutor(); if e and e ~= "" then return e end end); pcall(function() local e = getexecutorname(); if e and e ~= "" then return e end end); return executor.name end
local eN = GE(); local aA = LP.AccountAge .. " days"; local aI = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=420&h=420"
local aP = tInfo:Paragraph({ Title = "YooWssp!!, " .. LP.DisplayName, Desc = "Executor: " .. eN .. "\nAccount Age: " .. aA .. "\nUserID: " .. LP.UserId .. "\nStatus: " .. (LP.MembershipType == Enum.MembershipType.Premium and "Premium" or "Normal") .. "\nAnti AFK: ON ✅\nFPS Cap: " .. State.FPS.cap, Image = aI, ImageSize = 80 })
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(1); pcall(function() aP:SetDesc("Executor: " .. eN .. "\nAccount Age: " .. aA .. "\nUserID: " .. LP.UserId .. "\nStatus: " .. (LP.MembershipType == Enum.MembershipType.Premium and "Premium" or "Normal") .. "\nAnti AFK: " .. (State.Security.afkActive and "ON ✅" or "OFF ❌") .. "\nFPS Cap: " .. State.FPS.cap) end) end end)
local iP = tInfo:Paragraph({ Title = "💀 " .. LP.DisplayName .. "\n⚡ " .. MB(sharedFPS, 120, 10) .. " " .. sharedFPS .. " FPS\n📡 " .. MB(math.max(1, 200 - sharedPing), 200, 10) .. " " .. sharedPing .. "ms\n🕐 " .. MB(os.difftime(os.time(), START_TIME) % 3600, 3600, 10) .. " " .. FT(os.difftime(os.time(), START_TIME)), Desc = "👤 " .. LP.DisplayName .. "\n📱 " .. (onMobile and "Mobile" or "PC") .. " | 🚀 " .. eN .. "\n\n🎮 " .. (cachedMapName or "Loading...") .. "\n👥 " .. MB(#Players:GetPlayers(), Players.MaxPlayers, 10) .. " " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. " Players\n\n🌐 discord.gg/bzumc2u96" })
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(1); pcall(function() iP:SetTitle("💀 " .. LP.DisplayName .. "\n⚡ " .. MB(sharedFPS, 120, 10) .. " " .. sharedFPS .. " FPS\n📡 " .. MB(math.max(1, 200 - sharedPing), 200, 10) .. " " .. sharedPing .. "ms\n🕐 " .. MB(os.difftime(os.time(), START_TIME) % 3600, 3600, 10) .. " " .. FT(os.difftime(os.time(), START_TIME))) end) end end)
tInfo:Section({ Title = "🔗 Discord", Icon = "message-circle", Box = true }):Button({ Title = "Copy Discord Link", Desc = "discord.gg/bzumc2u96", Callback = function() pcall(function() setclipboard("https://discord.gg/bzumc2u96") end); notify("System", "Link copied", 2, "copy") end })

-- ================================ TAB: CHARACTER ================================
local tChar = Win:Tab({ Title = "Character", Icon = "fingerprint" })
tChar:Button({ Title = "Refresh Character 🔄", Desc = "Reload character like /re", Callback = RC })
local sMov = tChar:Section({ Title = "Movement", Icon = "activity", Box = true })
sMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v; if GH() then GH().WalkSpeed = v end end })
sMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v; local h = GH(); if h then h.UseJumpPower = true; h.JumpPower = v end end })
sMov:Toggle({ Title = "Infinite Jump", Default = false, Callback = function(v) if v then State.Move.infJ = TrackC(UserInputService.JumpRequest:Connect(function() if GH() then GH():ChangeState(Enum.HumanoidStateType.Jumping) end end)) else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end end; notify("Infinite Jump", v and "ON" or "OFF", 1.5, "arrow-big-up") end })
local sAW = tChar:Section({ Title = "Auto Walk", Icon = "play", Box = true })
sAW:Toggle({ Title = "Auto Walk", Default = false, Callback = function(v) if v then SAW() else STAW() end end })
sAW:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 1, Max = 100, Default = 16 }, Callback = function(v) State.Move.autoWalkSpeed = v; if State.Move.autoWalk then local hum = GH(); if hum then hum.WalkSpeed = v end end end })
sAW:Paragraph({ Title = "Info", Desc = "Character walks forward automatically\nMove manually to override" })
local sAbi = tChar:Section({ Title = "Abilities", Icon = "zap", Box = true })
sAbi:Toggle({ Title = "Fly", Default = false, Callback = function(v) TF(v) end })
sAbi:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(v) State.Move.flyS = v end })
local ncC = nil
sAbi:Toggle({ Title = "NoClip", Default = false, Callback = function(v) State.Move.ncp = v; if v then if not ncC then ncC = TrackC(RunService.Heartbeat:Connect(function() if not State.Move.ncp then return end; if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)) end else if ncC then ncC:Disconnect(); ncC = nil end; if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end end; notify("NoClip", v and "ON" or "OFF", 1.5, "ghost") end })
local sFling = tChar:Section({ Title = "Hard Fling (Safe)", Icon = "rotate-cw", Box = true })
sFling:Toggle({ Title = "Hard Fling", Default = false, Callback = function(v) if v then SHF() else STHF() end end })
sFling:Dropdown({ Title = "Fling Mode", Values = { "Spin", "Shake" }, Default = "Spin", Callback = function(v) State.HardFling.mode = v; notify("Fling Mode", v, 1.5, "rotate-cw") end })
sFling:Slider({ Title = "Fling Power", Step = 500, Value = { Min = 1000, Max = 50000, Default = 10000 }, Callback = function(v) State.HardFling.power = v end })

-- ================================ TAB: TELEPORT ================================
local tTP = Win:Tab({ Title = "Teleport", Icon = "map-pin-x-inside" })
local sDTP = tTP:Section({ Title = "Direct Teleport", Icon = "map-pin", Box = true })
sDTP:Toggle({ Title = "Smart TP", Desc = "Equip tool → tap to toggle mode → tap to TP", Default = false, Callback = TSTP })
local sTTP = tTP:Section({ Title = "Target Teleport", Icon = "crosshair", Box = true })
local tpT = ""
sTTP:Input({ Title = "Search Player", Placeholder = "Type name...", Callback = function(v) tpT = v end })
sTTP:Button({ Title = "Execute TP", Desc = "Teleport to target", Callback = function() pcall(function() if tpT == "" then notify("Teleport", "Input target!", 2, "circle-alert"); return end; local t = nil; for _, p in pairs(Players:GetPlayers()) do if p ~= LP and (string.find(string.lower(p.Name), string.lower(tpT)) or string.find(string.lower(p.DisplayName), string.lower(tpT))) then t = p; break end end; if not t or not t.Parent or not t.Character then notify("Teleport", "Invalid Target", 2, "circle-alert"); return end; local thr = GCR(t.Character); local mhr = GR(); if not thr or not mhr then return end; mhr.CFrame = thr.CFrame * CFrame.new(0, 0, 3) + Vector3.new(0, 2, 0); notify("Teleport", t.DisplayName, 2, "map-pin") end) end })
sTTP:Dropdown({ Title = "Player List", Values = GDN(), Callback = function(v) tpT = tostring(v) end })
sTTP:Button({ Title = "Refresh List", Callback = function() notify("Teleport", "List refreshed", 1.5, "map-pin") end })
local sCache = tTP:Section({ Title = "Coordinates Cache", Icon = "save", Box = true })
local SL = {}
for i = 1, 3 do local ix = i; local hc = sCache:HStack({ Columns = 2 }); hc:Button({ Title = "💾 Save " .. ix, Callback = function() local r = GR(); if not r then return end; SL[ix] = r.CFrame; notify("Slot " .. ix, "Saved", 1.5, "save") end }); hc:Button({ Title = "📍 Load " .. ix, Callback = function() if not SL[ix] then notify("Slot " .. ix, "Empty", 1.5, "save"); return end; local r = GR(); if not r then return end; r.CFrame = SL[ix]; notify("Slot " .. ix, "Loaded", 1.5, "map-pin") end }) end

-- ================================ TAB: SPECTATOR ================================
local tSpec = Win:Tab({ Title = "Spectator", Icon = "cctv" })
local sZoom = tSpec:Section({ Title = "Zoom Override", Icon = "zoom-in", Box = true })
sZoom:Toggle({ Title = "Max Zoom Out", Default = false, Callback = function(v) pcall(function() LP.CameraMaxZoomDistance = v and 100000 or 400 end); notify("Zoom", v and "Max" or "Default", 1.5, "zoom-in") end })
local sSP = tSpec:Section({ Title = "Spectator Mode", Icon = "eye", Box = true })
sSP:Dropdown({ Title = "Select Target", Values = GDNS(), Callback = function(v) local s = tostring(v); if s == "[Self]" then Sp.tg = LP; Sp.is = true; Sp.oy = 0; Sp.op = 20; Sp.fy = 0; notify("Spectator", "Self", 1.5, "eye") else local p = FPD(s); if p then Sp.tg = p; Sp.is = false; if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ(); Sp.oy = math.deg(ry); Sp.op = 20; Sp.fy = math.deg(ry) end; notify("Spectator", p.DisplayName, 1.5, "eye") end end end })
sSP:Button({ Title = "Refresh Target List", Callback = function() notify("Spectator", "List refreshed", 1.5, "eye") end })
sSP:Toggle({ Title = "Enable Spectate", Default = false, Callback = function(v) if SS.ac then TSS(false) end; Sp.ac = v; if v then if not Sp.tg or not Sp.tg.Character then if Sp.is and LP.Character then else Sp.ac = false; notify("Error", "No target", 2, "circle-alert"); return end end; Sp.of = Camera.FieldOfView; SSPC(); SSPL(); notify("Spectator", "ON", 2, "eye") else STSPL(); STSPC(); Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = Sp.of; notify("Spectator", "OFF", 1.5, "eye") end end })
sSP:Toggle({ Title = "First Person View", Default = false, Callback = function(v) Sp.md = v and "first" or "third"; notify("Spectator", v and "First Person" or "Third Person", 1.5, "eye") end })
sSP:Slider({ Title = "Distance", Step = 1, Value = { Min = 3, Max = 30, Default = 8 }, Callback = function(v) Sp.ds = v end })

-- ================================ TAB: CINEMATIC ================================
local tCine = Win:Tab({ Title = "Cinematic", Icon = "aperture" })
local sSS = tCine:Section({ Title = "🎥 Self-Spectate", Icon = "camera", Box = true })
sSS:Toggle({ Title = "Enable Self-Spectate", Desc = "1-finger orbit | 2-finger zoom | Mouse right-drag", Default = false, Callback = TSS })
sSS:Dropdown({ Title = "Preset Mode", Values = { "Manual", "Slow Orbit", "Vertical Swing", "Figure 8", "Cinematic Drift", "Top Down", "First Person" }, Default = "Manual", Callback = function(v) SS.md = v; notify("Self-Spec", "Mode: " .. v, 1.5, "camera") end })
sSS:Slider({ Title = "Distance / Radius", Step = 0.5, Value = { Min = 3, Max = 30, Default = 8 }, Callback = function(v) SS.rd = v; SS.ds = v end })
sSS:Slider({ Title = "Height", Step = 0.5, Value = { Min = -10, Max = 20, Default = 3 }, Callback = function(v) SS.he = v end })
sSS:Slider({ Title = "Speed", Step = 0.1, Value = { Min = 0.1, Max = 5, Default = 1 }, Callback = function(v) SS.sp = v end })

local sFC = tCine:Section({ Title = "Drone Engine", Icon = "video", Box = true })
sFC:Toggle({ Title = "Enable Freecam", Default = false, Callback = function(v)
    if v and SS.ac then TSS(false) end
    FC.ac = v
    if v then
        local cf = Camera.CFrame; FC.pos = cf.Position; FC.pi = 0; FC.ya = 0; FC.ro = 0
        cV = Vector3.zero; yV = 0; pV = 0; rV = 0; hV = 0; fmJ = Vector2.zero
        local h, r = GH(), GR()
        if h then FC.sWS = h.WalkSpeed; FC.sJP = h.JumpPower; h.WalkSpeed = 0; h.JumpPower = 0; h.AutoRotate = false end
        if r then r.Anchored = true; FC.wa = true end
        FC.of = Camera.FieldOfView; SFCC(); SFCL()
        if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = true end
        FC_UH = false; eBtn.Text = "👁"; for _, b in ipairs(fB) do b.Visible = true end
        notify("Freecam", "ON", 2, "video")
    else
        FCFC(); local h = GH(); if h then h.AutoRotate = true end
        notify("Freecam", "OFF", 1.5, "video")
    end
end })
sFC:Slider({ Title = "Camera Speed", Step = 0.5, Value = { Min = 1, Max = 20, Default = 3 }, Callback = function(v) FC.sp = v end })
sFC:Slider({ Title = "Sensitivity", Step = 0.05, Value = { Min = 0.1, Max = 1.0, Default = 0.25 }, Callback = function(v) FC.se = v end })
sFC:Toggle({ Title = "Hide All UI (Cinematic)", Default = false, Callback = function(v) if getgenv()._XKID_UI_LOADING then return end; if v then State.Cinema.hideUI = true; State.Cinema.cachedGuis = {}; for _, g in pairs(LP.PlayerGui:GetChildren()) do if g:IsA("ScreenGui") and g.Enabled then table.insert(State.Cinema.cachedGuis, g); g.Enabled = false end end; pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end) else State.Cinema.hideUI = false; for _, g in pairs(State.Cinema.cachedGuis) do if g and g.Parent then g.Enabled = true end end; State.Cinema.cachedGuis = {}; pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end) end; notify("Cinematic", v and "UI Hidden" or "UI Shown", 1.5, "film") end })

-- ================================ TAB: VISUALS ================================
local tVis = Win:Tab({ Title = "Visuals", Icon = "moon-star" })
local sPres = tVis:Section({ Title = "Presets", Icon = "palette", Box = true })
sPres:Dropdown({ Title = "Select Filter", Values = { "Default", "Custom", "Mendung HD", "Cool Blue HD", "Soft Fade HD", "Adaptif Langit HD", "Edgy HD", "Full Bright HD", "Soft Pastel HD", "Cinematic Soft", "Ultra HD", "Realistic", "Night HD", "Senja", "Cinematic Film", "Golden Hour", "Moody Blue" }, Default = "Default", Callback = AF })
local sFX = tVis:Section({ Title = "Custom FX", Icon = "sliders", Box = true })
sFX:Slider({ Title = "Saturation", Step = 0.05, Value = { Min = -1, Max = 1, Default = 0 }, Callback = function(v) State.CustomFilter.saturation = v; ACF() end })
sFX:Slider({ Title = "Contrast", Step = 0.05, Value = { Min = -1, Max = 1, Default = 0 }, Callback = function(v) State.CustomFilter.contrast = v; ACF() end })
sFX:Slider({ Title = "Brightness", Step = 0.05, Value = { Min = -1, Max = 1, Default = 0 }, Callback = function(v) State.CustomFilter.brightness = v; ACF() end })
sFX:Slider({ Title = "Exposure", Step = 0.1, Value = { Min = -5, Max = 5, Default = 0 }, Callback = function(v) State.CustomFilter.exposure = v; ACF() end })
sFX:Slider({ Title = "Bloom Intensity", Step = 0.1, Value = { Min = 0, Max = 2, Default = 0 }, Callback = function(v) State.CustomFilter.bloomIntensity = v; ACF() end })
sFX:Slider({ Title = "ClockTime", Step = 0.5, Value = { Min = 0, Max = 24, Default = 14 }, Callback = function(v) State.CustomFilter.clockTime = v; ACF() end })
sFX:Button({ Title = "Reset Custom FX", Callback = function() State.CustomFilter.saturation = 0; State.CustomFilter.contrast = 0; State.CustomFilter.brightness = 0; State.CustomFilter.exposure = 0; State.CustomFilter.bloomIntensity = 0; State.CustomFilter.clockTime = 14; ACF(); notify("Visuals", "FX Reset", 2, "rotate-ccw") end })

-- ================================ TAB: ESP ================================
local tESP = Win:Tab({ Title = "ESP", Icon = "scan-search" })
local sDet = tESP:Section({ Title = "Detection System", Icon = "radar", Box = true })
sDet:Toggle({ Title = "Enable Radar", Default = false, Callback = function(v) State.ESP.active = v; if not v and State.ESP.cache then for _, c in pairs(State.ESP.cache) do pcall(function() if c.texts then c.texts.Visible = false end; if c.tracer then c.tracer.Visible = false end; for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end; if c.hl then c.hl.Enabled = false end end) end end; notify("ESP", v and "ON" or "OFF", 1.5, "radar") end })
sDet:Toggle({ Title = "Highlight Entity", Default = false, Callback = function(v) State.ESP.highlightMode = v; notify("ESP", "Highlight " .. (v and "ON" or "OFF"), 1.5, "radar") end })
sDet:Slider({ Title = "Scan Distance", Step = 10, Value = { Min = 50, Max = 500, Default = 300 }, Callback = function(v) State.ESP.maxDrawDistance = v end })
local sCol = tESP:Section({ Title = "Color Config", Icon = "palette", Box = true })
sCol:Dropdown({ Title = "Normal Color", Values = { "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam" }, Default = "Merah", Callback = function(v) if colorMap[v] then State.ESP.tracerColor_N = colorMap[v]; State.ESP.boxColor_N = colorMap[v] end; notify("ESP", "Normal: " .. v, 1.5, "palette") end })
sCol:Dropdown({ Title = "Suspect Color", Values = { "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam", "Crimson" }, Default = "Crimson", Callback = function(v) if colorMap[v] then State.ESP.tracerColor_S = colorMap[v]; State.ESP.boxColor_S = colorMap[v] end; notify("ESP", "Suspect: " .. v, 1.5, "palette") end })
sCol:Dropdown({ Title = "Glitch Acc Color", Values = { "Orange", "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Pink", "Putih", "Hitam" }, Default = "Orange", Callback = function(v) if colorMap[v] then State.ESP.tracerColor_G = colorMap[v]; State.ESP.boxColor_G = colorMap[v] end; notify("ESP", "Glitch: " .. v, 1.5, "palette") end })

-- ================================ TAB: LOGGER ================================
local tLog = Win:Tab({ Title = "Logger", Icon = "square-terminal" })
local sChat = tLog:Section({ Title = "Chat Logger", Icon = "message-square", Box = true })
sChat:Toggle({ Title = "Enable Logger", Default = false, Callback = function(v) State.Utility.chatLog = v; if not v then pcall(function() cLP:SetDesc("Logger disabled") end) end; notify("Logger", v and "ON" or "OFF", 1.5, "terminal") end })
local cTL = sChat:Paragraph({ Title = "Targets", Desc = "None" })
local cTD = sChat:Dropdown({ Title = "Select Targets", Multi = true, AllowNone = true, Values = GDN(), Callback = function(s) State.Utility.chatTargets = {}; if s and typeof(s) == "table" then for _, n in ipairs(s) do table.insert(State.Utility.chatTargets, tostring(n)) end end; if #State.Utility.chatTargets > 0 then pcall(function() cTL:SetDesc("Tracking: " .. table.concat(State.Utility.chatTargets, ", ")) end) else pcall(function() cTL:SetDesc("None") end) end end })
sChat:Button({ Title = "Clear Targets", Callback = function() State.Utility.chatTargets = {}; pcall(function() cTL:SetDesc("None") end); pcall(function() cTD:SetValues({}); task.wait(0.05); cTD:SetValues(GDN()) end); notify("Logger", "Targets cleared", 1.5, "terminal") end })
sChat:Button({ Title = "Refresh List", Callback = function() pcall(function() cTD:Refresh(GDN(), true) end); notify("Logger", "List refreshed", 1.5, "terminal") end })
local cLP = sChat:Paragraph({ Title = "Console", Desc = "Belum ada chat..." })
sChat:Button({ Title = "Clear Log", Callback = function() State.Utility.chatHistory = {}; pcall(function() cLP:SetDesc("Belum ada chat...") end); notify("Logger", "Log cleared", 1.5, "terminal") end })
task.spawn(function() local function OC(sn, msg) if not State.Utility.chatLog then return end; if #State.Utility.chatTargets == 0 then return end; local cs = sn:lower():match("^%s*(.-)%s*$"); for _, t in ipairs(State.Utility.chatTargets) do local ct = t:lower():match("^%s*(.-)%s*$"); if cs == ct then local e = string.format("[%s] %s: %s", os.date("%H:%M:%S"), sn, msg); table.insert(State.Utility.chatHistory, e); if #State.Utility.chatHistory > 50 then table.remove(State.Utility.chatHistory, 1) end; notify("Chat", sn .. ": " .. msg, 2, "message-circle"); break end end end; if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then pcall(function() TrackC(TextChatService.MessageReceived:Connect(function(m) if m.TextSource then OC(m.TextSource.Name, m.Text) end end)) end) end; local function CLC(p) pcall(function() TrackC(p.Chatted:Connect(function(m) OC(p.DisplayName, m) end)) end) end; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CLC(p) end end; TrackC(Players.PlayerAdded:Connect(function(p) if p ~= LP then CLC(p) end end)) end)
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(0.5); if cLP and State.Utility.chatLog then pcall(function() local t = table.concat(State.Utility.chatHistory, "\n"); if #t > 2000 then t = t:sub(-2000) end; if #t == 0 then t = "Belum ada chat..." end; cLP:SetDesc(t) end) end end end)

-- ================================ TAB: PROTECTION ================================
local tProt = Win:Tab({ Title = "Protection", Icon = "shield-half" })
local sProt = tProt:Section({ Title = "Protection Protocols", Icon = "shield-check", Box = true })
sProt:Toggle({ Title = "Anti AFK (Stealth)", Default = false, Callback = function(v) if v then SAFK() else STAFK() end end })
sProt:Button({ Title = "Stuck Fix", Desc = "Get unstuck from walls/ground", Callback = function() local r, h = GR(), GH(); if r then r.Anchored = false; r.CFrame = r.CFrame + Vector3.new(0, 3, 0) end; if h then h.Sit = false; h:ChangeState(Enum.HumanoidStateType.Jumping) end; notify("Protection", "Stuck fix applied", 2, "wrench") end })
local sSrv = tProt:Section({ Title = "Server Control", Icon = "server", Box = true })
sSrv:Button({ Title = "Force Rejoin", Desc = "Rejoin current server", Callback = function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end); notify("Server", "Rejoining...", 2, "log-in") end })
sSrv:Button({ Title = "Server Hop", Desc = "Find a new server", Callback = function() pcall(function() local req = getgenv()._XKID_REQUEST or httpRequest; if not req then notify("Error", "HTTP not supported", 2, "circle-alert"); return end; local res = req({ Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100", Method = "GET" }); if res.StatusCode == 200 then local b = HttpService:JSONDecode(res.Body); if b and b.data then for _, v in ipairs(b.data) do if v.playing > 0 and v.playing < v.maxPlayers and v.id ~= game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LP); notify("Server", "Hopping...", 2, "shuffle"); return end end end end end) end })
local sPerf = tProt:Section({ Title = "Performance", Icon = "gauge", Box = true })
local gfxM = { [1] = "Level01", [2] = "Level02", [3] = "Level03", [4] = "Level04", [5] = "Level05", [6] = "Level06", [7] = "Level07", [8] = "Level08", [9] = "Level09", [10] = "Level10" }
sPerf:Slider({ Title = "Quality Level", Step = 1, Value = { Min = 1, Max = 10, Default = 2 }, Callback = function(v) if gfxM[v] then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel[gfxM[v]] end) end; notify("Graphics", gfxM[v], 1.5, "gauge") end })
sPerf:Dropdown({ Title = "FPS Cap", Values = { "30", "60", "120", "144", "240", "Unlimited" }, Default = "120", Callback = function(v) if v == "Unlimited" then setOptimalFPS(9999); State.FPS.cap = 9999 else setOptimalFPS(tonumber(v)); State.FPS.cap = tonumber(v) end; notify("Graphics", v .. " FPS", 1.5, "gauge") end })
local aCache = { lvl = nil, sh = true, br = 5, ct = 14, fe = 100000, mats = {}, txs = {} }
sPerf:Toggle({ Title = "FPS Boost", Default = false, Callback = function(v) State.Security.antiLag = v; if v then pcall(function() aCache.lvl = settings().Rendering.QualityLevel end); aCache.sh = Lighting.GlobalShadows; aCache.br = Lighting.Brightness; aCache.ct = Lighting.ClockTime; aCache.fe = Lighting.FogEnd; pcall(function() settings().Rendering.QualityLevel = 1 end); Lighting.GlobalShadows = false; Lighting.Brightness = 1; Lighting.FogEnd = 100000; for _, o in pairs(workspace:GetDescendants()) do if o:IsA("BasePart") then aCache.mats[o] = o.Material; o.Material = Enum.Material.SmoothPlastic elseif o:IsA("Decal") or o:IsA("Texture") or o:IsA("ParticleEmitter") or o:IsA("Trail") then aCache.txs[o] = o.Enabled; o.Enabled = false end end; notify("Performance", "FPS Boost ON", 2, "zap") else pcall(function() if aCache.lvl then settings().Rendering.QualityLevel = aCache.lvl end end); Lighting.GlobalShadows = aCache.sh; Lighting.Brightness = aCache.br; Lighting.ClockTime = aCache.ct; Lighting.FogEnd = aCache.fe; for o, mat in pairs(aCache.mats) do if o and o.Parent then o.Material = mat end end; for o, en in pairs(aCache.txs) do if o and o.Parent then o.Enabled = en end end; aCache.mats = {}; aCache.txs = {}; notify("Performance", "Graphics restored", 2, "zap") end end })
local sCam = tProt:Section({ Title = "Camera Lock", Icon = "lock", Box = true })
sCam:Toggle({ Title = "Force Shift Lock", Default = false, Callback = function(v) TSL(v) end })

-- ================================ TAB: SETTINGS ================================
local tSet = Win:Tab({ Title = "Settings", Icon = "panels-top-left" })
local sTheme = tSet:Section({ Title = "🎨 Theme", Icon = "palette", Box = true })
sTheme:Dropdown({ Title = "UI Theme", Values = { "Dark", "Light", "Rose", "Sky", "Emerald", "Violet", "Red", "Amber", "Indigo", "Midnight", "Crimson" }, Default = "Crimson", Callback = function(v) WindUI:SetTheme(v) end })

local sDebug = tSet:Section({ Title = "🐛 Debug Log", Icon = "bug", Box = true })
local dP = sDebug:Paragraph({ Title = "Log", Desc = "No entries yet..." })
sDebug:Button({ Title = "📋 Copy Log", Callback = function() local t = table.concat(DebugLog, "\n"); pcall(function() setclipboard(t) end); notify("Debug", "Log copied to clipboard", 2, "copy") end })
sDebug:Button({ Title = "🗑 Clear Log", Callback = function() DebugLog = {}; pcall(function() dP:SetDesc("No entries yet...") end); notify("Debug", "Log cleared", 1.5, "trash-2") end })
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(0.5); if dP then pcall(function() local t = table.concat(DebugLog, "\n"); if #t == 0 then t = "No entries yet..." elseif #t > 2000 then t = t:sub(-2000) end; dP:SetDesc(t) end) end end end)

local sFile = tSet:Section({ Title = "File Management", Icon = "folder", Box = true })
local cfgN = "XKID_Config_V3"; local curCfg = "No config"
sFile:Input({ Title = "Config Name", Value = "XKID_Config_V3", Callback = function(v) cfgN = v end })
local function SCF() if executor.has_writefile then pcall(function() if not isfolder("XKID_HUB") then makefolder("XKID_HUB") end; local d = { Move = { ws = State.Move.ws, jp = State.Move.jp, flyS = State.Move.flyS, aws = State.Move.autoWalkSpeed }, ESP = { md = State.ESP.maxDrawDistance, hl = State.ESP.highlightMode }, Sec = { sl = State.Security.shiftLock, al = State.Security.antiLag }, HF = { pw = State.HardFling.power, md = State.HardFling.mode }, SS = { md = SS.md, rd = SS.rd, he = SS.he, sp = SS.sp }, CF = { tr = State.CustomFilter.tintR, tg = State.CustomFilter.tintG, tb = State.CustomFilter.tintB, st = State.CustomFilter.saturation, ct = State.CustomFilter.contrast, br = State.CustomFilter.brightness, ex = State.CustomFilter.exposure, bl = State.CustomFilter.bloomIntensity, bs = State.CustomFilter.bloomSize, ti = State.CustomFilter.clockTime } }; writefile("XKID_HUB/" .. cfgN .. ".json", HttpService:JSONEncode(d)); notify("Config", "Saved: " .. cfgN, 2, "save"); addLog("Config saved: " .. cfgN, "INFO") end) else notify("Config", "Executor tidak support save", 2, "circle-alert"); addLog("Config save failed", "ERROR") end end
local function LCF(s) if s == "No config" then return end; pcall(function() if executor.has_readfile and isfile and isfile("XKID_HUB/" .. s .. ".json") then local d = HttpService:JSONDecode(readfile("XKID_HUB/" .. s .. ".json")); if d then if d.Move then State.Move.ws = d.Move.ws or 16; State.Move.jp = d.Move.jp or 50; State.Move.flyS = d.Move.flyS or 60; State.Move.autoWalkSpeed = d.Move.aws or 16; local h = GH(); if h then h.WalkSpeed = State.Move.ws; h.UseJumpPower = true; h.JumpPower = State.Move.jp end end; if d.ESP then State.ESP.maxDrawDistance = d.ESP.md or 300; State.ESP.highlightMode = d.ESP.hl or false end; if d.Sec and d.Sec.sl ~= State.Security.shiftLock then TSL(d.Sec.sl) end; if d.HF then State.HardFling.power = d.HF.pw or 10000; State.HardFling.mode = d.HF.md or "Spin" end; if d.SS then SS.md = d.SS.md or "Manual"; SS.rd = d.SS.rd or 8; SS.he = d.SS.he or 3; SS.sp = d.SS.sp or 1 end; if d.CF then for k, v in pairs(d.CF) do State.CustomFilter[k] = v end; ACF() end; notify("Config", "Loaded: " .. s, 2, "folder-open"); addLog("Config loaded: " .. s, "INFO") end end end) end
sFile:Button({ Title = "Save Config", Callback = SCF })
local cfgD = sFile:Dropdown({ Title = "Load Config", Values = GCL(), Callback = function(s) curCfg = s; LCF(s) end })
sFile:Button({ Title = "Delete Config", Callback = function() if curCfg ~= "No config" and curCfg ~= "" and executor.has_listfiles then pcall(function() if isfile and delfile and isfile("XKID_HUB/" .. curCfg .. ".json") then delfile("XKID_HUB/" .. curCfg .. ".json"); pcall(function() cfgD:Refresh(GCL(), true) end); curCfg = "No config"; notify("Config", "Deleted", 2, "trash-2"); addLog("Config deleted: " .. curCfg, "INFO") end end) end end })
sFile:Button({ Title = "Refresh Files", Callback = function() pcall(function() cfgD:Refresh(GCL(), true) end); notify("Config", "Files refreshed", 1.5, "folder") end })
local sLike = tSet:Section({ Title = "Auto Like (Smart)", Icon = "heart", Box = true })
sLike:Toggle({ Title = "Auto Like", Default = false, Callback = function(v) if v then SAL() else STAL() end end })
sLike:Slider({ Title = "Like Radius", Desc = "0 = all", Step = 10, Value = { Min = 0, Max = 500, Default = 100 }, Callback = function(v) State.AutoLike.radius = v end })
sLike:Slider({ Title = "Min Cooldown", Step = 0.5, Value = { Min = 0.5, Max = 10, Default = 2 }, Callback = function(v) State.AutoLike.minCD = v end })
sLike:Slider({ Title = "Max Cooldown", Step = 0.5, Value = { Min = 1, Max = 15, Default = 6 }, Callback = function(v) State.AutoLike.maxCD = v end })
local ali = sLike:Paragraph({ Title = "Info", Desc = "Total likes sent: 0" })
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(2); pcall(function() ali:SetDesc("Total likes sent: " .. State.AutoLike.count) end) end end)

-- ================================ INITIAL SETTINGS ================================
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level02 end); setOptimalFPS(120)
task.spawn(function() task.wait(0.5); SAFK(); task.wait(2); getgenv()._XKID_UI_LOADING = false; notify("System", "XKID_HUB V3.4 AKTIF — Ready", 3, "rocket"); notify("Anti AFK", "AUTO ACTIVATED (Stealth)", 2, "shield-check"); addLog("XKID_HUB V3.4 loaded successfully", "INFO") end)