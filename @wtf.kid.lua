--[[
========================
      @WTF.XKID
        Script
========================

  ✨ Features:
  • Avatar Refresh (Fast Respawn + Refresh Character)
  • Teleport (Click TP) & Location Saver
  • Movement (Speed / Jump / Fly / NoClip / Soft Fling Ultra)
  • Camera (Freecam / Spectate / Max Zoom Out Toggle)
  • Modern Hybrid ESP (Highlight Mode + Large Glitch Detection)
  • World Control (Custom Bloom/Lighting Filters)
  • Security (Anti-AFK / Anti-Void / Stuck Fix / FPS Boost)
  • Network (Auto Rejoin, Server Hop, True Ping Spike Alert)
  • Settings (Save/Load Config with Dropdown, Built-in Themes)
  • UI (RGB ROG Animated OpenButton)
  
  💎 Created by @WTF.XKID
  📱 Tiktok: @wtf.xkid
  💬 Discord: @4sharken
]]

local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- ══════════════════════════════════════════════════════════════
--  0. AUTO CLEANUP & MEMORY MANAGEMENT
-- ══════════════════════════════════════════════════════════════
if getgenv()._XKID_RUNNING then
    getgenv()._XKID_RUNNING = false 
end

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
        for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
            if v.Name == "WindUI" then v:Destroy() end
        end
        for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
            if v.Name == "_XKID_FILTER" then v:Destroy() end
        end
        if getgenv()._XKID_CONNS then
            for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end
        end
        RS:UnbindFromRenderStep("XKIDFreecam")
        RS:UnbindFromRenderStep("XKIDFly")
        RS:UnbindFromRenderStep("XKIDSpec")
        RS:UnbindFromRenderStep("XKIDShiftLock")
        RS:UnbindFromRenderStep("XKIDESP")
    end)
    task.wait(0.2) 
    collectgarbage("collect")
end

getgenv()._XKID_LOADED = true
getgenv()._XKID_RUNNING = true
getgenv()._XKID_CONNS = {}
local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

local START_TIME = os.time()

task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(60)
        collectgarbage("collect")
    end
end)

-- ══════════════════════════════════════════════════════════════
--  LOAD WINDUI
-- ══════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- ══════════════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════════════
local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting    = game:GetService("Lighting")
local TPService   = game:GetService("TeleportService")
local StatsService= game:GetService("Stats")
local CoreGui     = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP          = Players.LocalPlayer
local Cam         = workspace.CurrentCamera
local onMobile    = not UIS.KeyboardEnabled

local cachedMapName = nil
local lastMapCheck = 0

-- ══════════════════════════════════════════════════════════════
--  STATE MANAGEMENT
-- ══════════════════════════════════════════════════════════════
local State = {
    Move     = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly      = { active = false, bv = nil, bg = nil, noFallConn = nil, _keys = {} },
    SoftFling= { active = false, power = 50000 },
    Teleport = { selectedTarget = "", clickTool = nil, clickConn = nil, clickActive = false },
    Security = { afkConn = nil, antiLag = false, shiftLock = false, shiftLockGyro = nil, voidConn = nil, fallConn = nil, arConn = nil },
    Cinema   = { active = false },
    Avatar   = { isRefreshing = false },
    Utility  = { chatLog = false, chatTarget = nil, chatConn = nil, chatHistory = {} },
    ESP = {
        active          = false,
        cache           = getgenv()._XKID_ESP_CACHE,
        tracerMode      = "Bottom",
        maxDrawDistance = 300,
        highlightMode   = false,
        boxColor_N      = Color3.fromRGB(0, 255, 150),
        boxColor_S      = Color3.fromRGB(220, 20, 60),
        boxColor_G      = Color3.fromRGB(255, 165, 0),
        tracerColor_N   = Color3.fromRGB(0, 200, 255),
        tracerColor_S   = Color3.fromRGB(220, 20, 60),
        tracerColor_G   = Color3.fromRGB(255, 165, 0),
        nameColor       = Color3.fromRGB(255, 255, 255),
    },
}

local colorMap = {
    ["Merah"] = Color3.fromRGB(255, 0, 0), ["Hijau"] = Color3.fromRGB(0, 255, 0),
    ["Biru"]  = Color3.fromRGB(0, 0, 255), ["Kuning"]= Color3.fromRGB(255, 255, 0),
    ["Ungu"]  = Color3.fromRGB(255, 0, 255), ["Cyan"]  = Color3.fromRGB(0, 255, 255),
    ["Orange"]= Color3.fromRGB(255, 165, 0), ["Pink"]  = Color3.fromRGB(255, 105, 180),
    ["Putih"] = Color3.fromRGB(255, 255, 255), ["Hitam"] = Color3.fromRGB(0, 0, 0),
    ["Crimson"] = Color3.fromRGB(220, 20, 60),
}

-- ══════════════════════════════════════════════════════════════
--  HELPER FUNCTIONS
-- ══════════════════════════════════════════════════════════════
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getDisplayNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName) end end
    return t
end
local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do if str == p.DisplayName then return p end end
    return nil
end
local function getCharRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
end
local function notify(title, content, dur) pcall(function() WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 }) end) end

local function formatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

local function getConfigList()
    local list = {}
    pcall(function()
        if isfolder and isfolder("XKID_HUB") then
            local files = listfiles("XKID_HUB")
            for _, file in ipairs(files) do
                if file:match("%.json$") then
                    local name = file:match("([^/]+)%.json$")
                    if name then table.insert(list, name) end
                end
            end
        end
    end)
    if #list == 0 then table.insert(list, "Tidak ada config") end
    return list
end

local function isOnGround()
    local r = getRoot()
    if not r then return false end
    local rayOrigin = r.Position
    local rayDirection = Vector3.new(0, -5, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LP.Character}
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return raycastResult ~= nil
end

TrackC(LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
    end
    if State.Security.shiftLock then
        task.wait(0.2)
        local hrp = getRoot()
        if hrp then
            if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() end
            State.Security.shiftLockGyro = Instance.new("BodyGyro", hrp)
            State.Security.shiftLockGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            State.Security.shiftLockGyro.P = 50000; State.Security.shiftLockGyro.D = 1000
        end
    end
    if State.Teleport.clickActive and State.Teleport.clickTool then
        State.Teleport.clickTool.Parent = LP.Backpack
    end
end))

-- ══════════════════════════════════════════════════════════════
--  SHIFT LOCK ENGINE
-- ══════════════════════════════════════════════════════════════
local function toggleShiftLock(v)
    State.Security.shiftLock = v
    if v then
        local hrp = getRoot()
        if hrp then
            if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() end
            State.Security.shiftLockGyro = Instance.new("BodyGyro", hrp)
            State.Security.shiftLockGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            State.Security.shiftLockGyro.P = 50000; State.Security.shiftLockGyro.D = 1000
        end
        RS:BindToRenderStep("XKIDShiftLock", Enum.RenderPriority.Camera.Value + 2, function()
            if not State.Security.shiftLock then return end
            local hrp, gyro = getRoot(), State.Security.shiftLockGyro
            if hrp and gyro and gyro.Parent == hrp then
                local camCF = Cam.CFrame
                local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
                if flatLook.Magnitude > 0.01 then gyro.CFrame = CFrame.new(hrp.Position, hrp.Position + flatLook) end
            end
        end)
        notify("Shift Lock", "Dikunci 🔒", 2)
    else
        RS:UnbindFromRenderStep("XKIDShiftLock")
        if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy(); State.Security.shiftLockGyro = nil end
        notify("Shift Lock", "Dibuka 🔓", 2)
    end
end

-- ══════════════════════════════════════════════════════════════
--  FAST RESPAWN & REFRESH SYSTEM
-- ══════════════════════════════════════════════════════════════
local function fastRespawn()
    if State.Avatar.isRefreshing then return end
    local char, hrp = LP.Character, getRoot()
    if not char or not hrp then notify("Error", "Karakter gak ada!", 2); return end
    State.Avatar.isRefreshing = true; notify("Respawn", "Respawn aman 💨", 1.5)
    local savedCF, camCF = hrp.CFrame, Cam.CFrame
    local connection; connection = LP.CharacterAdded:Connect(function(newChar)
        connection:Disconnect()
        local newHrp, newHum = newChar:WaitForChild("HumanoidRootPart", 5), newChar:WaitForChild("Humanoid", 5)
        if newHrp and newHum then
            local startTime = tick()
            local holdConn; holdConn = RS.Heartbeat:Connect(function()
                if tick() - startTime > 0.5 then holdConn:Disconnect(); return end
                if newHrp.Parent then newHrp.CFrame = savedCF; newHrp.AssemblyLinearVelocity = Vector3.zero end
            end)
            Cam.CameraSubject = newHum; Cam.CFrame = camCF
        end
        State.Avatar.isRefreshing = false; notify("Sukses", "Respawn berhasil!", 2)
    end)
    char:BreakJoints()
    task.delay(5, function() State.Avatar.isRefreshing = false end)
end

local function refreshCharacter()
    if State.Avatar.isRefreshing then return end
    local char, hrp = LP.Character, getRoot()
    if not char or not hrp then notify("Error", "Karakter gak ada!", 2); return end
    State.Avatar.isRefreshing = true; notify("Refresh", "Refresh karakter 🔁", 1.5)
    local savedCF, camCF = hrp.CFrame, Cam.CFrame
    Cam.CameraType = Enum.CameraType.Scriptable; Cam.CFrame = camCF
    local connection; connection = LP.CharacterAdded:Connect(function(newChar)
        connection:Disconnect()
        local newHrp, newHum = newChar:WaitForChild("HumanoidRootPart", 5), newChar:WaitForChild("Humanoid", 5)
        if newHrp and newHum then
            local startTime = tick()
            local holdConn; holdConn = RS.Heartbeat:Connect(function()
                if tick() - startTime > 0.5 then holdConn:Disconnect(); return end
                if newHrp.Parent then newHrp.CFrame = savedCF; newHrp.AssemblyLinearVelocity = Vector3.zero end
            end)
            Cam.CameraSubject = newHum; Cam.CameraType = Enum.CameraType.Custom
        end
        State.Avatar.isRefreshing = false; notify("Sukses", "Karakter direfresh!", 2)
    end)
    local success = pcall(function() LP:LoadCharacter() end)
    if not success then char:BreakJoints() end
    task.delay(3, function()
        if State.Avatar.isRefreshing or Cam.CameraType == Enum.CameraType.Scriptable then
            State.Avatar.isRefreshing = false; Cam.CameraType = Enum.CameraType.Custom; if getHum() then Cam.CameraSubject = getHum() end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  HYBRID ESP ENGINE (Optimized)
-- ══════════════════════════════════════════════════════════════
local function initPlayerCache(player)
    if State.ESP.cache[player] then return end
    local cache = { texts=nil, tracer=nil, boxLines={}, hl=nil, isSuspect=false, isGlitch=false, reason="" }
    
    pcall(function()
        cache.texts = Drawing.new("Text")
        if cache.texts then
            cache.texts.Center = true; cache.texts.Outline = true; cache.texts.Font = 2; cache.texts.Size = 13; cache.texts.ZIndex = 2
        end
        cache.tracer = Drawing.new("Line")
        if cache.tracer then
            cache.tracer.Thickness = 1.5; cache.tracer.ZIndex = 1
        end
        for i = 1, 4 do 
            local line = Drawing.new("Line")
            if line then line.Thickness = 1.5; line.ZIndex = 1; cache.boxLines[i] = line end
        end
    end)
    State.ESP.cache[player] = cache
end

local function clearPlayerCache(player)
    local c = State.ESP.cache[player]
    if c then
        pcall(function() if c.texts then c.texts:Remove() end end)
        pcall(function() if c.tracer then c.tracer:Remove() end end)
        for _, l in ipairs(c.boxLines) do pcall(function() if l then l:Remove() end end) end
        pcall(function() if c.hl then c.hl:Destroy() end end)
        State.ESP.cache[player] = nil
    end
end
TrackC(Players.PlayerRemoving:Connect(clearPlayerCache))

task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if State.ESP.active then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local isSus, isGlitch, reason = false, false, ""
                    for _, v in pairs(p.Character:GetChildren()) do
                        if v:IsA("BasePart") and (v.Size.X > 30 or v.Size.Y > 30 or v.Size.Z > 30) then isSus=true; reason="Map Blocker" break
                        elseif v:IsA("Accessory") then
                            local h = v:FindFirstChild("Handle")
                            if h and h:IsA("BasePart") then
                                if h.Size.Magnitude > 20 then isSus=true; reason="Huge Hat" break
                                elseif h.Size.Magnitude > 10 or (h.Transparency < 0.1 and h.Material == Enum.Material.Neon) then isGlitch=true; reason="Glitch Acc" end
                            end
                        end
                    end
                    if not isSus and not isGlitch then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local bws, bhs = hum:FindFirstChild("BodyWidthScale"), hum:FindFirstChild("BodyHeightScale")
                            if (bws and bws.Value > 2.0) or (bhs and bhs.Value > 2.0) then isSus=true; reason="Glitch Avatar" end
                        end
                    end
                    initPlayerCache(p)
                    if State.ESP.cache[p] then
                        State.ESP.cache[p].isSuspect = isSus; State.ESP.cache[p].isGlitch = isGlitch; State.ESP.cache[p].reason = reason
                    end
                end
            end
        end
        task.wait(1)
    end
end)

RS:BindToRenderStep("XKIDESP", Enum.RenderPriority.Camera.Value + 1, function()
    if not State.ESP.active then return end
    local myHrp = getCharRoot(LP.Character)
    if not myHrp then return end
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            local hrp = getCharRoot(char)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then clearPlayerCache(player); continue end
            
            initPlayerCache(player); local c = State.ESP.cache[player]
            if not c then continue end

            local active = hum.Health > 0
            local dist = active and (hrp.Position - myHrp.Position).Magnitude or 9999
            
            if not active or dist > State.ESP.maxDrawDistance then
                pcall(function()
                    if c.texts then c.texts.Visible = false end
                    if c.tracer then c.tracer.Visible = false end
                    for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end
                    if c.hl then c.hl.Enabled = false end
                end)
                continue
            end
            
            local rootPos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
            if not onScreen then
                pcall(function()
                    if c.texts then c.texts.Visible = false end
                    if c.tracer then c.tracer.Visible = false end
                    for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end
                    if c.hl then c.hl.Enabled = false end
                end)
                continue
            end
            
            local isSus, isGlitch = c.isSuspect, c.isGlitch
            local useHighlight = isSus or isGlitch or State.ESP.highlightMode
            
            local txt = player.DisplayName .. "\n[" .. math.floor(dist) .. "m]"
            if isSus or isGlitch then txt = txt .. "\n⚠ " .. c.reason .. " ⚠" end
            
            local cColor = isSus and State.ESP.boxColor_S or (isGlitch and State.ESP.boxColor_G or State.ESP.nameColor)
            local tColor = isSus and State.ESP.tracerColor_S or (isGlitch and State.ESP.tracerColor_G or State.ESP.tracerColor_N)
            local bColor = isSus and State.ESP.boxColor_S or (isGlitch and State.ESP.boxColor_G or State.ESP.boxColor_N)

            pcall(function()
                if c.texts then
                    c.texts.Text = txt
                    c.texts.Color = cColor
                    c.texts.Position = Vector2.new(rootPos.X, rootPos.Y - 45)
                    c.texts.Visible = true
                end
                
                if State.ESP.tracerMode ~= "OFF" and c.tracer then
                    local origin = center
                    if State.ESP.tracerMode == "Bottom" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
                    elseif State.ESP.tracerMode == "Mouse" then local m = UIS:GetMouseLocation(); origin = Vector2.new(m.X, m.Y) end
                    c.tracer.From = origin; c.tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                    c.tracer.Color = tColor; c.tracer.Visible = true
                elseif c.tracer then 
                    c.tracer.Visible = false 
                end
            end)
            
            if useHighlight then
                local top, topOn = Cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local bot, botOn = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                pcall(function()
                    if topOn and botOn and #c.boxLines == 4 then
                        local h = math.abs(top.Y - bot.Y); local w = h * 0.6
                        local tl, tr = Vector2.new(rootPos.X - w/2, top.Y), Vector2.new(rootPos.X + w/2, top.Y)
                        local bl, br = Vector2.new(rootPos.X - w/2, bot.Y), Vector2.new(rootPos.X + w/2, bot.Y)
                        c.boxLines[1].From=tl; c.boxLines[1].To=tr; c.boxLines[2].From=tr; c.boxLines[2].To=br
                        c.boxLines[3].From=br; c.boxLines[3].To=bl; c.boxLines[4].From=bl; c.boxLines[4].To=tl
                        for i=1, 4 do if c.boxLines[i] then c.boxLines[i].Color = bColor; c.boxLines[i].Visible = true end end
                    else
                        for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end
                    end
                end)
                pcall(function()
                    if not c.hl or c.hl.Parent ~= char then
                        if c.hl then c.hl:Destroy() end
                        c.hl = Instance.new("Highlight", char)
                        c.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    end
                    if c.hl then c.hl.FillColor = bColor; c.hl.OutlineColor = Color3.new(1,1,1); c.hl.Enabled = true end
                end)
            else
                pcall(function()
                    for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end
                    if c.hl then c.hl.Enabled = false end
                end)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  FLY ENGINE (MOMENTUM + SOFT LANDING)
-- ══════════════════════════════════════════════════════════════
local flyMoveTouch, flyMoveSt, flyJoy, flyConns = nil, nil, Vector2.zero, {}
local flyVel = Vector3.zero

local function startFlyCapture()
    local keysHeld = {}
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode; if k==Enum.KeyCode.W or k==Enum.KeyCode.A or k==Enum.KeyCode.S or k==Enum.KeyCode.D or k==Enum.KeyCode.E or k==Enum.KeyCode.Q then keysHeld[k] = true end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp) keysHeld[inp.KeyCode] = nil end))
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp.Position.X <= Cam.ViewportSize.X/2 then if not flyMoveTouch then flyMoveTouch = inp; flyMoveSt = inp.Position end end
    end))
    table.insert(flyConns, UIS.TouchMoved:Connect(function(inp)
        if inp == flyMoveTouch and flyMoveSt then
            local dx, dy = inp.Position.X - flyMoveSt.X, inp.Position.Y - flyMoveSt.Y
            flyJoy = Vector2.new(math.abs(dx)>25 and math.clamp((dx-math.sign(dx)*25)/80,-1,1) or 0, math.abs(dy)>20 and math.clamp((dy-math.sign(dy)*20)/80,-1,1) or 0)
        end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == flyMoveTouch then flyMoveTouch=nil; flyMoveSt=nil; flyJoy=Vector2.zero end
    end))
    State.Fly._keys = keysHeld
end

local function stopFlyCapture()
    for _, c in ipairs(flyConns) do c:Disconnect() end
    flyConns = {}; flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero; State.Fly._keys = {}
end

local function toggleFly(v)
    if not v then
        State.Fly.active = false; stopFlyCapture(); RS:UnbindFromRenderStep("XKIDFly")
        pcall(function() if State.Fly.bv then State.Fly.bv:Destroy() end end)
        pcall(function() if State.Fly.bg then State.Fly.bg:Destroy() end end)
        State.Fly.bv = nil; State.Fly.bg = nil; flyVel = Vector3.zero
        local hum = getHum()
        if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.WalkSpeed = State.Move.ws; hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
        if State.Fly.noFallConn then State.Fly.noFallConn:Disconnect(); State.Fly.noFallConn = nil end
        notify("Fly", "Fly dimatikan 👋", 2)
        return
    end
    local hrp = getRoot(); local hum = getHum()
    if not hrp or not hum then return end
    State.Fly.active = true; hum.PlatformStand = true; flyVel = Vector3.zero
    State.Fly.bv = Instance.new("BodyVelocity", hrp); State.Fly.bv.MaxForce = Vector3.new(9e9,9e9,9e9); State.Fly.bv.Velocity = Vector3.zero
    State.Fly.bg = Instance.new("BodyGyro", hrp); State.Fly.bg.MaxTorque = Vector3.new(9e9,9e9,9e9); State.Fly.bg.P = 50000
    
    if not State.Fly.noFallConn then
        State.Fly.noFallConn = TrackC(RS.Heartbeat:Connect(function()
            local r = getRoot()
            if r and r.Velocity.Y < -30 then r.Velocity = Vector3.new(r.Velocity.X, -10, r.Velocity.Z) end
        end))
    end
    
    startFlyCapture()
    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value+1, function()
        if not State.Fly.active then return end
        local r = getRoot(); if not r then return end
        local camCF = Cam.CFrame; local spd = State.Move.flyS; local move = Vector3.zero; local keys = State.Fly._keys or {}
        
        if onMobile then
            move = camCF.LookVector*(-flyJoy.Y) + camCF.RightVector*flyJoy.X
            if move.Magnitude > 0 then spd = spd * 1.15 end
        else
            if keys[Enum.KeyCode.W] then move = move + camCF.LookVector end
            if keys[Enum.KeyCode.S] then move = move - camCF.LookVector end
            if keys[Enum.KeyCode.D] then move = move + camCF.RightVector end
            if keys[Enum.KeyCode.A] then move = move - camCF.RightVector end
            if keys[Enum.KeyCode.E] then move = move + Vector3.new(0,1,0) end
            if keys[Enum.KeyCode.Q] then move = move - Vector3.new(0,1,0) end
        end
        
        local targetVel
        if move.Magnitude > 0 then
            targetVel = move.Unit * spd
            flyVel = flyVel:Lerp(targetVel, 0.15)
        else
            if isOnGround() then
                targetVel = Vector3.zero
                flyVel = flyVel:Lerp(targetVel, 0.1)
            else
                -- Turun SANGAT perlahan agar animasi jatuh mulus
                targetVel = Vector3.new(0, -0.8, 0) 
                flyVel = flyVel:Lerp(targetVel, 0.08)
            end
        end
        
        if State.Fly.bv and State.Fly.bv.Parent then State.Fly.bv.Velocity = flyVel end
        if State.Fly.bg and State.Fly.bg.Parent then State.Fly.bg.CFrame = CFrame.new(r.Position, r.Position + camCF.LookVector) end
    end)
    notify("Fly", "Fly menyala ✈️", 2)
end

-- ══════════════════════════════════════════════════════════════
--  FREECAM ENGINE
-- ══════════════════════════════════════════════════════════════
local FC = { active=false, pos=Vector3.zero, pitchDeg=0, yawDeg=0, speed=3, sens=0.25, savedCF=nil }
local fcMoveTouch, fcMoveSt, fcRotTouch, fcRotLast, fcJoy, fcConns, fcKeysHeld = nil, nil, nil, nil, Vector2.zero, {}, {}

local function startFreecamCapture()
    fcKeysHeld = {}
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode; if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then fcKeysHeld[k] = true end
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mouseRot = true; UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        fcKeysHeld[inp.KeyCode] = false
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mouseRot = false; UIS.MouseBehavior = Enum.MouseBehavior.Default end
    end))
    table.insert(fcConns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and FC._mouseRot then
            FC.yawDeg = FC.yawDeg - inp.Delta.X * FC.sens; FC.pitchDeg = math.clamp(FC.pitchDeg - inp.Delta.Y * FC.sens, -80, 80)
        end
    end))
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp.Position.X > Cam.ViewportSize.X / 2 then if not fcRotTouch then fcRotTouch = inp; fcRotLast = inp.Position end
        else if not fcMoveTouch then fcMoveTouch = inp; fcMoveSt = inp.Position end end
    end))
    table.insert(fcConns, UIS.TouchMoved:Connect(function(inp)
        if inp == fcRotTouch and fcRotLast then
            FC.yawDeg = FC.yawDeg - (inp.Position.X - fcRotLast.X) * FC.sens; FC.pitchDeg = math.clamp(FC.pitchDeg - (inp.Position.Y - fcRotLast.Y) * FC.sens, -80, 80); fcRotLast = inp.Position
        end
        if inp == fcMoveTouch and fcMoveSt then
            local dx, dy = inp.Position.X - fcMoveSt.X, inp.Position.Y - fcMoveSt.Y
            fcJoy = Vector2.new(math.abs(dx) > 25 and math.clamp((dx - math.sign(dx) * 25) / 80, -1, 1) or 0, math.abs(dy) > 20 and math.clamp((dy - math.sign(dy) * 20) / 80, -1, 1) or 0)
        end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == fcRotTouch then fcRotTouch = nil; fcRotLast = nil end
        if inp == fcMoveTouch then fcMoveTouch = nil; fcMoveSt = nil; fcJoy = Vector2.zero end
    end))
end
local function stopFreecamCapture()
    for _, c in ipairs(fcConns) do c:Disconnect() end
    fcConns = {}; fcMoveTouch = nil; fcMoveSt = nil; fcRotTouch = nil; fcRotLast = nil; fcJoy = Vector2.zero; fcKeysHeld = {}; FC._mouseRot = false; UIS.MouseBehavior = Enum.MouseBehavior.Default
end
local function startFreecamLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable
        local camCF = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local move = Vector3.zero
        if onMobile then move = camCF.LookVector * (-fcJoy.Y) + camCF.RightVector * fcJoy.X
        else
            if fcKeysHeld[Enum.KeyCode.W] then move = move + camCF.LookVector end
            if fcKeysHeld[Enum.KeyCode.S] then move = move - camCF.LookVector end
            if fcKeysHeld[Enum.KeyCode.D] then move = move + camCF.RightVector end
            if fcKeysHeld[Enum.KeyCode.A] then move = move - camCF.RightVector end
            if fcKeysHeld[Enum.KeyCode.E] then move = move + Vector3.new(0, 1, 0) end
            if fcKeysHeld[Enum.KeyCode.Q] then move = move - Vector3.new(0, 1, 0) end
        end
        if move.Magnitude > 0 then FC.pos = FC.pos + move.Unit * (FC.speed * dt * 60) end
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local hrp, hum = getRoot(), getHum()
        if hrp and not hrp.Anchored then hrp.Anchored = true end
        if hum then hum:ChangeState(Enum.HumanoidStateType.Physics); hum.WalkSpeed = 0; hum.JumpPower = 0 end
    end)
end
local function stopFreecamLoop() RS:UnbindFromRenderStep("XKIDFreecam") end

-- ══════════════════════════════════════════════════════════════
--  SPECTATE ENGINE
-- ══════════════════════════════════════════════════════════════
local function inJoystick(pos)
    local ctrl = LP and LP.PlayerGui and LP.PlayerGui:FindFirstChild("TouchGui")
    if ctrl then
        local frame = ctrl:FindFirstChild("TouchControlFrame"); local thumb = frame and frame:FindFirstChild("DynamicThumbstickFrame")
        if thumb then
            local ap, as = thumb.AbsolutePosition, thumb.AbsoluteSize
            if pos.X>=ap.X and pos.Y>=ap.Y and pos.X<=ap.X+as.X and pos.Y<=ap.Y+as.Y then return true end
        end
    end
    return false
end

local Spec = { active=false, target=nil, mode="third", dist=8, origFov=70, orbitYaw=0, orbitPitch=0, fpYaw=0, fpPitch=0 }
local specTM,specPinch,specPinchD,specPan,specConns = nil,{},nil,Vector2.zero,{}
local function startSpecCapture()
    table.insert(specConns, UIS.InputBegan:Connect(function(inp,gp)
        if gp or not Spec.active or inp.UserInputType~=Enum.UserInputType.Touch or inJoystick(inp.Position) then return end
        table.insert(specPinch,inp); specTM = #specPinch==1 and inp or nil
    end))
    table.insert(specConns, UIS.InputChanged:Connect(function(inp)
        if not Spec.active or inp.UserInputType~=Enum.UserInputType.Touch then return end
        if #specPinch==1 and inp==specTM then specPan = specPan+Vector2.new(inp.Delta.X,inp.Delta.Y)
        elseif #specPinch>=2 then
            local d=(specPinch[1].Position-specPinch[2].Position).Magnitude
            if specPinchD then
                local diff=d-specPinchD
                Cam.FieldOfView=math.clamp(Cam.FieldOfView-diff*0.15,10,120)
                if Spec.mode=="third" then Spec.dist=math.clamp(Spec.dist-diff*0.03,3,30) end
            end
            specPinchD=d
        end
    end))
    table.insert(specConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.Touch then return end
        for i,v in ipairs(specPinch) do if v==inp then table.remove(specPinch,i); break end end
        specPinchD=nil; specTM = #specPinch==1 and specPinch[1] or nil
    end))
end
local function stopSpecCapture()
    for _,c in ipairs(specConns) do c:Disconnect() end
    specConns={}; specTM=nil; specPinch={}; specPinchD=nil; specPan=Vector2.zero
end
local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value+1, function()
        if not Spec.active then return end
        pcall(function()
            if not Spec.target or not Spec.target.Parent or not Spec.target.Character or not Spec.target.Character:FindFirstChild("HumanoidRootPart") then
                notify("Spectate", "Target gak valid!", 2); Spec.active = false; stopSpecLoop(); stopSpecCapture()
                Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov
                return
            end
            local hrp = Spec.target.Character.HumanoidRootPart
            Cam.CameraType = Enum.CameraType.Scriptable; local pan, sens = specPan, 0.3; specPan = Vector2.zero
            if Spec.mode == "third" then
                Spec.orbitYaw = Spec.orbitYaw + pan.X * sens; Spec.orbitPitch = math.clamp(Spec.orbitPitch + pan.Y * sens, -75, 75)
                local oCF = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(-Spec.orbitYaw), 0) * CFrame.Angles(math.rad(-Spec.orbitPitch), 0, 0) * CFrame.new(0, 0, Spec.dist)
                Cam.CFrame = CFrame.new(oCF.Position, hrp.Position + Vector3.new(0, 1, 0))
            else
                local head = Spec.target.Character:FindFirstChild("Head")
                local origin = head and head.Position or hrp.Position + Vector3.new(0, 1.5, 0)
                Spec.fpYaw = Spec.fpYaw - pan.X * sens; Spec.fpPitch = math.clamp(Spec.fpPitch - pan.Y * sens, -85, 85)
                Cam.CFrame = CFrame.new(origin) * CFrame.Angles(0, math.rad(Spec.fpYaw), 0) * CFrame.Angles(math.rad(Spec.fpPitch), 0, 0)
            end
        end)
    end)
end
local function stopSpecLoop() RS:UnbindFromRenderStep("XKIDSpec") end

-- ══════════════════════════════════════════════════════════════
--  CHAT LOGGER ENGINE (DUAL-LISTENER)
-- ══════════════════════════════════════════════════════════════
local chatLogPanel = nil

local function logMsg(speakerName, msg)
    if not State.Utility.chatLog then return end
    if State.Utility.chatTarget and State.Utility.chatTarget.Name ~= speakerName and State.Utility.chatTarget.DisplayName ~= speakerName then return end
    
    local timestamp = os.date("%H:%M:%S")
    local entry = string.format("[%s] %s: %s", timestamp, speakerName, msg)
    table.insert(State.Utility.chatHistory, entry)
    if #State.Utility.chatHistory > 50 then table.remove(State.Utility.chatHistory, 1) end
    
    if chatLogPanel then
        local logText = table.concat(State.Utility.chatHistory, "\n")
        if #logText > 2000 then logText = logText:sub(-2000) end
        pcall(function() chatLogPanel:SetDesc(logText) end)
    end
    notify("💬 " .. speakerName, msg, 3)
end

-- TextChatService (Chat Baru)
pcall(function()
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        if textChatMessage.TextSource then
            logMsg(textChatMessage.TextSource.Name, textChatMessage.Text)
        end
    end)
end)

-- Legacy Chat (Chat Lama)
for _, p in ipairs(Players:GetPlayers()) do pcall(function() p.Chatted:Connect(function(msg) logMsg(p.Name, msg) end) end) end
Players.PlayerAdded:Connect(function(p) pcall(function() p.Chatted:Connect(function(msg) logMsg(p.Name, msg) end) end) end)

-- ══════════════════════════════════════════════════════════════
--  MAIN WINDOW
-- ══════════════════════════════════════════════════════════════
task.wait(0.3)

local Window = WindUI:CreateWindow({
    Title       = "@WTF.XKID",
    Subtitle    = "Script",
    Author      = "by @WTF.XKID",
    Folder      = "XKIDScript",
    Icon        = "ghost",
    Theme       = "Crimson",
    Acrylic     = true,
    Transparent = true,
    Size        = UDim2.fromOffset(540, 460),
    MinSize     = Vector2.new(440, 360),
    MaxSize     = Vector2.new(680, 540),
    ToggleKey   = Enum.KeyCode.RightShift,
    Resizable   = true,
    AutoScale   = true,
    NewElements = true,
    SideBarWidth= 150,
    Topbar = { Height = 40, ButtonsType = "Default" },
    OpenButton  = {
        Title           = "@WTF.XKID",
        Icon            = "ghost",
        CornerRadius    = UDim.new(1, 0),
        StrokeThickness = 4,
        Enabled         = true,
        Draggable       = true,
        OnlyMobile      = false,
        Scale           = 0.75,
        Color = ColorSequence.new(Color3.fromRGB(225, 0, 120), Color3.fromRGB(0, 255, 255)),
    },
    User = {
        Enabled   = true,
        Anonymous = false,
        UserId    = LP.UserId,
        Callback  = function()
            notify("XKID", "Dibuat oleh @WTF.XKID", 3)
        end,
    },
})

getgenv()._XKID_INSTANCE = Window.Instance
WindUI:SetTheme("Crimson")

-- ══════════════════════════════════════════════════════════════
--  AUTO CLEANUP ON WINDOW CLOSE
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(1)
        local wind = CoreGui:FindFirstChild("WindUI")
        if not wind or not wind:FindFirstChild("XKIDScript", true) then
            getgenv()._XKID_RUNNING = false
            
            if State.Fly.active then
                RS:UnbindFromRenderStep("XKIDFly")
                pcall(function() if State.Fly.bv then State.Fly.bv:Destroy() end end)
                pcall(function() if State.Fly.bg then State.Fly.bg:Destroy() end end)
                local hum = getHum()
                if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end
            
            RS:UnbindFromRenderStep("XKIDFreecam")
            RS:UnbindFromRenderStep("XKIDSpec")
            RS:UnbindFromRenderStep("XKIDShiftLock")
            RS:UnbindFromRenderStep("XKIDESP")
            
            if getgenv()._XKID_ESP_CACHE then
                for _, c in pairs(getgenv()._XKID_ESP_CACHE) do
                    pcall(function()
                        if c.texts then c.texts:Remove() end
                        if c.tracer then c.tracer:Remove() end
                        if c.hl then c.hl:Destroy() end
                    end)
                end
            end
            getgenv()._XKID_ESP_CACHE = {}
            
            local hrp = getRoot(); local hum = getHum()
            if hrp then hrp.Anchored = false end
            if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.UseJumpPower = true end
            
            if getgenv()._XKID_CONNS then
                for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end
            end
            getgenv()._XKID_CONNS = {}
            
            getgenv()._XKID_LOADED = false
            getgenv()._XKID_RUNNING = false
            
            for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" then v:Destroy() end end
            
            notify("Cleanup", "Semua fitur mati, aman re-execute 🧹", 3)
            break
        end
    end
end)

-- Animasi RGB ROG
task.spawn(function()
    local hue = 0
    while getgenv()._XKID_RUNNING do
        hue = (hue + 0.005) % 1
        local c1 = Color3.fromHSV(hue, 1, 1)
        local c2 = Color3.fromHSV((hue + 0.5) % 1, 1, 1)
        local seq = ColorSequence.new(c1, c2)
        pcall(function()
            local wind = CoreGui:FindFirstChild("WindUI")
            if wind then
                local openBtn = wind:FindFirstChild("OpenButton", true)
                if openBtn then
                    local stroke = openBtn:FindFirstChildOfClass("UIStroke")
                    if stroke then
                        local grad = stroke:FindFirstChildOfClass("UIGradient")
                        if not grad then grad = Instance.new("UIGradient", stroke) end
                        grad.Color = seq; grad.Rotation = (grad.Rotation + 5) % 360
                    end
                    local bgGrad = openBtn:FindFirstChildOfClass("UIGradient")
                    if bgGrad then bgGrad.Color = seq; bgGrad.Rotation = (bgGrad.Rotation + 2) % 360 end
                end
            end
        end)
        task.wait(0.03)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 1: HOME SCREEN
-- ══════════════════════════════════════════════════════════════
local T_HOME = Window:Tab({ Title = "Home", Icon = "home" })

T_HOME:Section({ Title = "⚡ XKID HUB", Opened = true }):Paragraph({
    Title = "Welcome",
    Desc = "Script loaded successfully!\n\n📱 Tiktok: @wtf.xkid\n💬 Discord: @4sharken"
})

T_HOME:Section({ Title = "🔗 Discord", Opened = true }):Button({
    Title = "Copy Discord Link",
    Desc = "discord.gg/bzumc2u96",
    Callback = function()
        pcall(function() setclipboard("https://discord.gg/bzumc2u96") end)
        notify("Discord", "Link dicopy ke clipboard!", 2)
    end
})

local secStatus = T_HOME:Section({ Title = "📊 Live Monitor", Opened = true })
local srvLabel = secStatus:Paragraph({ Title = "🌐 Server Info", Desc = "Memuat..." })
local netLabel = secStatus:Paragraph({ Title = "⚡ Network & Perf", Desc = "Memuat..." })

local secSecurity = T_HOME:Section({ Title = "🛡️ Security Status", Opened = true })
local securityLabel = secSecurity:Paragraph({ Title = "Status", Desc = "Script Protected\nAnti-Crash Enabled" })

-- Cache map name
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        pcall(function()
            if tick() - lastMapCheck > 30 or not cachedMapName then
                cachedMapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
                lastMapCheck = tick()
            end
        end)
        task.wait(5)
    end
end)

-- Unified stats loop (Ganda Pcall untuk Anti-Freeze)
local fpsSamples = {}
local sharedPing = 0
local sharedFPS = 60

task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(1)
        pcall(function()
            local ping = game:GetService("Stats").PerformanceStats.Ping:GetValue()
            if ping and ping > 0 then sharedPing = math.floor(ping) end
        end)
    end
end)

task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(0.3)
        
        pcall(function()
            if srvLabel and cachedMapName then
                local pCount = #Players:GetPlayers()
                local mCount = Players.MaxPlayers
                local uptime = formatTime(os.difftime(os.time(), START_TIME))
                local job = game.JobId:sub(1, 8).."..."
                srvLabel:SetDesc(string.format("🗺️ Map: %s\n🆔 Job: %s\n👥 Pemain: %d/%d\n⏳ Uptime: %s", cachedMapName, job, pCount, mCount, uptime))
            end
        end)
        
        pcall(function()
            if netLabel then
                local fc = sharedFPS >= 60 and "🟢" or (sharedFPS >= 30 and "🟡" or "🔴")
                local pc = sharedPing < 100 and "🟢" or (sharedPing < 200 and "🟡" or "🔴")
                local fBar = string.rep("█", math.clamp(math.floor(sharedFPS/12), 0, 10)) .. string.rep("░", 10 - math.clamp(math.floor(sharedFPS/12), 0, 10))
                local pBar = string.rep("█", math.clamp(math.floor((200-sharedPing)/20), 0, 10)) .. string.rep("░", 10 - math.clamp(math.floor((200-sharedPing)/20), 0, 10))
                
                netLabel:SetDesc(string.format("%s %d FPS\n[%s]\n\n%s %d ms\n[%s]", fc, sharedFPS, fBar, pc, sharedPing, pBar))
            end
        end)
        
        pcall(function()
            if securityLabel then
                local afk = State.Security.afkConn and "✅ Aktif" or "⭕ Mati"
                local lag = State.Security.antiLag and "⚡ Aktif" or "⭕ Mati"
                local sl = State.Security.shiftLock and "🔒 Aktif" or "🔓 Mati"
                local vd = State.Security.voidConn and "✅ Aktif" or "⭕ Mati"
                securityLabel:SetDesc(string.format("⏰ Anti-AFK: %s\n🔒 Shift Lock: %s\n🕳️ Anti-Void: %s\n⚡ FPS Boost: %s", afk, sl, vd, lag))
            end
        end)
    end
end)

TrackC(RS.RenderStepped:Connect(function(dt)
    table.insert(fpsSamples, dt)
    if #fpsSamples > 30 then table.remove(fpsSamples, 1) end
    local sum = 0
    for _, s in ipairs(fpsSamples) do sum = sum + s end
    sharedFPS = math.floor(1 / (sum / #fpsSamples))
end))

-- ══════════════════════════════════════════════════════════════
--  TAB 2: AVATAR & PLAYER
-- ══════════════════════════════════════════════════════════════
local T_AV = Window:Tab({ Title = "Player", Icon = "user" })

T_AV:Section({ Title = "🔄 Avatar Refresh", Opened = true }):Button({ Title = "💀 Fast Respawn", Desc = "Respawn ke posisi kematian", Callback = function() fastRespawn() end })
T_AV:Section({ Title = "🔄 Avatar Refresh", Opened = true }):Button({ Title = "🔄 Refresh Character", Desc = "Reload tanpa kill", Callback = function() refreshCharacter() end })

local secMov = T_AV:Section({ Title = "🏃 Movement", Opened = true })
secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end; notify("Gerak", "Speed jadi "..v, 2) end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end; notify("Gerak", "Loncat jadi "..v, 2) end })
secMov:Toggle({ Title = "🦘 Infinite Jump", Value = false, Callback = function(v)
    if v then State.Move.infJ = TrackC(UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end))
    else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end end
    notify("Gerak", v and "Inf Jump Aktif 🦘" or "Inf Jump Mati", 2)
end})

local secAbi = T_AV:Section({ Title = "⚡ Abilities", Opened = true })
secAbi:Toggle({ Title = "✈️ Fly", Value = false, Callback = function(v) toggleFly(v) end })
secAbi:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(v) State.Move.flyS = v; notify("Fly", "Speed terbang: "..v, 2) end })
secAbi:Toggle({ Title = "👻 NoClip", Value = false, Callback = function(v) State.Move.ncp = v; notify("Kemampuan", v and "Noclip Tembus Dinding 🔥" or "Noclip mati", 2) end })
secAbi:Toggle({ Title = "💫 Soft Fling", Value = false, Callback = function(v) State.SoftFling.active = v; State.Move.ncp = v; notify("Fling", v and "Soft Fling siap nabrak 💫" or "Fling mati", 2) end })

-- ══════════════════════════════════════════════════════════════
--  TAB 3: TELEPORT
-- ══════════════════════════════════════════════════════════════
local T_TP = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

T_TP:Section({ Title = "🖱️ Click Teleport", Opened = true }):Toggle({ Title = "Click TP Tool", Value = false, Callback = function(v)
    if v then
        if State.Teleport.clickTool then State.Teleport.clickTool:Destroy() end
        if State.Teleport.clickConn then State.Teleport.clickConn:Disconnect() end
        local tool = Instance.new("Tool"); tool.Name = "Click TP"; tool.RequiresHandle = false; tool.Parent = LP.Backpack
        State.Teleport.clickTool = tool; State.Teleport.clickActive = true
        State.Teleport.clickConn = tool.Activated:Connect(function()
            local m = LP:GetMouse(); local r = getRoot()
            if r and m and m.Hit then r.CFrame = m.Hit + Vector3.new(0, 3, 0) end
        end)
        notify("Click TP", "✅ Tool 'Click TP' di Backpack!", 2)
    else
        State.Teleport.clickActive = false
        if State.Teleport.clickTool then State.Teleport.clickTool:Destroy(); State.Teleport.clickTool = nil end
        if State.Teleport.clickConn then State.Teleport.clickConn:Disconnect(); State.Teleport.clickConn = nil end
        notify("Click TP", "❌ Tool dihapus", 2)
    end
end})

local secTP = T_TP:Section({ Title = "👥 Player Teleport", Opened = true })
local tpTarget = ""
secTP:Input({ Title = "Cari Player", Placeholder = "ketik nama...", Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "🚀 Teleport", Callback = function()
    pcall(function()
        if tpTarget == "" then notify("Teleport", "❌ Masukkan nama player!", 2); return end
        local targetPlayer = nil
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and (string.find(string.lower(p.Name), string.lower(tpTarget)) or string.find(string.lower(p.DisplayName), string.lower(tpTarget))) then targetPlayer = p; break end
        end
        if not targetPlayer or not targetPlayer.Parent or not targetPlayer.Character then notify("Teleport", "❌ Player tidak valid!", 2); return end
        local tHrp, tHum, myHrp = getCharRoot(targetPlayer.Character), targetPlayer.Character:FindFirstChildOfClass("Humanoid"), getRoot()
        if not tHrp or not tHum or not myHrp or tHum.Health <= 0 then notify("Teleport", "❌ Target mati/posisi gagal!", 2); return end
        myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3) + Vector3.new(0, 2, 0); myHrp.AssemblyLinearVelocity = Vector3.zero
        notify("Teleport", "✅ TP ke "..targetPlayer.DisplayName, 2)
    end)
end})

local pDropOpts = getDisplayNames()
local tpDropdown = secTP:Dropdown({ Title = "Daftar Player", Values = pDropOpts, Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "🔄 Refresh List", Callback = function()
    pDropOpts = getDisplayNames(); pcall(function() tpDropdown:Refresh(pDropOpts, true) end); notify("List", "List diupdate!", 2)
end})

local secLoc = T_TP:Section({ Title = "💾 Location Slots", Opened = true })
local SavedLocs = {}
for i = 1, 3 do
    secLoc:Button({ Title = "💾 Save Slot "..i, Callback = function()
        local r = getRoot(); if not r then notify("Error", "Karakter gak ada!", 2); return end
        SavedLocs[i] = r.CFrame; notify("Slot", "Slot "..i.." tersimpan!", 2)
    end})
    secLoc:Button({ Title = "📍 Load Slot "..i, Callback = function()
        if not SavedLocs[i] then notify("Error", "Slot kosong!", 2); return end
        local r = getRoot(); if not r then return end
        r.CFrame = SavedLocs[i]; notify("Slot", "Ke slot "..i.."!", 2)
    end})
end

-- ══════════════════════════════════════════════════════════════
--  TAB 4: CAMERA
-- ══════════════════════════════════════════════════════════════
local T_CAM = Window:Tab({ Title = "Camera", Icon = "eye" })

T_CAM:Section({ Title = "🔍 Camera Zoom", Opened = true }):Toggle({ Title = "Max Zoom Out", Value = false, Callback = function(v)
    pcall(function() LP.CameraMaxZoomDistance = v and 100000 or 400 end)
    notify("Camera", v and "Zoom jauh aktif 🔭" or "Zoom dinormalkan", 2)
end})

local secFC = T_CAM:Section({ Title = "🎥 Freecam", Opened = true })
secFC:Toggle({ Title = "Freecam", Value = false, Callback = function(v)
    FC.active = v; State.Cinema.active = v
    if v then
        local cf = Cam.CFrame; FC.pos = cf.Position; local rx, ry = cf:ToEulerAnglesYXZ(); FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry)
        local hrp = getRoot(); local hum = getHum()
        if hrp then FC.savedCF = hrp.CFrame; hrp.Anchored = true end
        if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum:ChangeState(Enum.HumanoidStateType.Physics) end
        startFreecamCapture(); startFreecamLoop(); notify("Freecam", "Freecam nyala 🎥", 2)
    else
        stopFreecamLoop(); stopFreecamCapture()
        local hrp = getRoot(); local hum = getHum()
        if hrp then hrp.Anchored = false; if FC.savedCF then hrp.CFrame = FC.savedCF end end
        if hum then hum.WalkSpeed = State.Move.ws; hum.UseJumpPower = true; hum.JumpPower = State.Move.jp; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        Cam.CameraType = Enum.CameraType.Custom; notify("Freecam", "Freecam mati 👁️", 2)
    end
end})
secFC:Slider({ Title = "Speed", Step = 0.5, Value = {Min = 1, Max = 20, Default = 3}, Callback = function(v) FC.speed = v; notify("Freecam", "Speed diubah: "..v, 2) end })

local secSP = T_CAM:Section({ Title = "👁️ Spectate", Opened = true })
local specDropOpts = getDisplayNames()
local specDropdown = secSP:Dropdown({ Title = "Target", Values = specDropOpts, Callback = function(v)
    local p = findPlayerByDisplay(v)
    if p then
        Spec.target = p
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ(); Spec.orbitYaw = math.deg(ry); Spec.orbitPitch = 20; Spec.fpYaw = math.deg(ry)
        end
        notify("Spectate", "Target diset: "..p.DisplayName, 2)
    end
end})
secSP:Button({ Title = "🔄 Refresh", Callback = function()
    specDropOpts = getDisplayNames(); pcall(function() specDropdown:Refresh(specDropOpts, true) end); notify("Spectate", "List diperbarui!", 2)
end})
secSP:Toggle({ Title = "Spectate ON", Value = false, Callback = function(v)
    Spec.active = v
    if v then
        if not Spec.target or not Spec.target.Parent or not Spec.target.Character or not Spec.target.Character:FindFirstChild("HumanoidRootPart") then
            notify("Spectate", "Pilih target dulu!", 2); Spec.active = false; return
        end
        Spec.origFov = Cam.FieldOfView; startSpecCapture(); startSpecLoop(); notify("Spectate", "Ngawasin "..Spec.target.DisplayName.." 👀", 2)
    else
        stopSpecLoop(); stopSpecCapture(); Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov; notify("Spectate", "Selesai ✌️", 2)
    end
end})
secSP:Toggle({ Title = "🎯 First Person", Value = false, Callback = function(v) Spec.mode = v and "first" or "third"; notify("Spectate", v and "POV Orang Pertama" or "POV Orang Ketiga", 2) end })
secSP:Slider({ Title = "Jarak", Step = 1, Value = {Min = 3, Max = 30, Default = 8}, Callback = function(v) Spec.dist = v end })

-- ══════════════════════════════════════════════════════════════
--  TAB 5: WORLD
-- ══════════════════════════════════════════════════════════════
local T_WO = Window:Tab({ Title = "World", Icon = "globe" })

local secFilter = T_WO:Section({ Title = "🎨 HD Filters", Opened = true })
local function resetLighting()
    for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" then v:Destroy() end end
    Lighting.ClockTime = 14; Lighting.Brightness = 1; Lighting.ExposureCompensation = 0
    Lighting.Ambient = Color3.fromRGB(127, 127, 127); Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    Lighting.ColorShift_Bottom = Color3.new(0, 0, 0); Lighting.ColorShift_Top = Color3.new(0, 0, 0)
    Lighting.FogEnd = 100000; notify("Filter", "Lighting direset 🌤️", 2)
end

local function applyFilter(filter)
    for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" then v:Destroy() end end
    if filter == "Default" then resetLighting(); return end
    local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "_XKID_FILTER"; cc.Parent = Lighting
    local bloom = Instance.new("BloomEffect"); bloom.Name = "_XKID_FILTER"; bloom.Parent = Lighting

    if filter == "Dark Map HD" then cc.Saturation = -0.2; cc.Contrast = 0.35; cc.Brightness = -0.05; bloom.Intensity = 0.15; Lighting.ClockTime = 5
    elseif filter == "Ultra HD" then cc.Saturation = 0.2; cc.Contrast = 0.3; cc.Brightness = 0.1; bloom.Intensity = 0.2; Lighting.ClockTime = 14
    elseif filter == "Sharp Visual HD" then cc.Saturation = 0.1; cc.Contrast = 0.4; cc.Brightness = 0; bloom.Intensity = 0; Lighting.ClockTime = 12
    elseif filter == "Realistic HD" then cc.Saturation = 0.1; cc.Contrast = 0.2; cc.Brightness = 0.1; bloom.Intensity = 0.15; Lighting.ClockTime = 15
    elseif filter == "Night HD" then cc.TintColor = Color3.fromRGB(200, 200, 255); cc.Saturation = 0.1; cc.Contrast = 0.2; cc.Brightness = 0.1; bloom.Intensity = 0.15; Lighting.ClockTime = 1
    elseif filter == "Luxury HD" then cc.TintColor = Color3.fromRGB(255, 230, 200); cc.Saturation = 0.3; cc.Contrast = 0.3; cc.Brightness = 0.1; bloom.Intensity = 0.4; Lighting.ClockTime = 17
    elseif filter == "Pastel HD" then cc.TintColor = Color3.fromRGB(255, 225, 235); cc.Saturation = -0.1; cc.Contrast = -0.1; bloom.Intensity = 0.6; bloom.Size = 40; Lighting.ClockTime = 8 end
    notify("Filter", filter .. " dipasang 🌈", 2)
end

secFilter:Button({ Title = "🎬 Dark Map HD", Callback = function() applyFilter("Dark Map HD") end })
secFilter:Button({ Title = "💎 Ultra HD", Callback = function() applyFilter("Ultra HD") end })
secFilter:Button({ Title = "👁 Sharp Visual HD", Callback = function() applyFilter("Sharp Visual HD") end })
secFilter:Button({ Title = "🌍 Realistic HD", Callback = function() applyFilter("Realistic HD") end })
secFilter:Button({ Title = "🌃 Night HD", Callback = function() applyFilter("Night HD") end })
secFilter:Button({ Title = "✨ Luxury HD", Callback = function() applyFilter("Luxury HD") end })
secFilter:Button({ Title = "☁ Pastel HD", Callback = function() applyFilter("Pastel HD") end })

local secAtmos = T_WO:Section({ Title = "🎚️ Atmosphere", Opened = false })
local function getEff(className)
    for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" and v:IsA(className) then return v end end
    local e = Instance.new(className); e.Name = "_XKID_FILTER"; e.Parent = Lighting; return e
end
secAtmos:Slider({ Title = "Brightness", Step = 0.1, Value = {Min = 0, Max = 10, Default = 1}, Callback = function(v) Lighting.Brightness = v; notify("Atmosfer", "Ubah kecerahan", 1) end })
secAtmos:Slider({ Title = "Exposure", Step = 0.1, Value = {Min = -5, Max = 5, Default = 0}, Callback = function(v) Lighting.ExposureCompensation = v; notify("Atmosfer", "Ubah exposure", 1) end })
secAtmos:Slider({ Title = "ClockTime", Step = 0.1, Value = {Min = 0, Max = 24, Default = 14}, Callback = function(v) Lighting.ClockTime = v; notify("Atmosfer", "Ubah waktu", 1) end })
secAtmos:Slider({ Title = "Contrast", Step = 0.1, Value = {Min = -2, Max = 2, Default = 0}, Callback = function(v) getEff("ColorCorrectionEffect").Contrast = v; notify("Atmosfer", "Ubah contrast", 1) end })
secAtmos:Slider({ Title = "Bloom", Step = 0.1, Value = {Min = 0, Max = 5, Default = 0}, Callback = function(v) getEff("BloomEffect").Intensity = v; notify("Atmosfer", "Ubah glow/bloom", 1) end })
secAtmos:Button({ Title = "🔄 Reset Semua", Callback = function() applyFilter("Default") end })

local secGfx = T_WO:Section({ Title = "🖥️ Graphics", Opened = false })
local gfxMap = { [1]="Level01", [2]="Level03", [3]="Level05", [4]="Level07", [5]="Level09", [6]="Level11", [7]="Level13", [8]="Level15", [9]="Level17", [10]="Level21" }
secGfx:Slider({ Title = "Kualitas", Step = 1, Value = {Min = 1, Max = 10, Default = 5}, Callback = function(v)
    if gfxMap[v] then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel[gfxMap[v]]; notify("Graphics", "Quality ke "..v, 2) end) end
end})

-- ══════════════════════════════════════════════════════════════
--  TAB 6: ESP
-- ══════════════════════════════════════════════════════════════
local T_ESP = Window:Tab({ Title = "ESP", Icon = "radar" })
local secESP = T_ESP:Section({ Title = "Hybrid Detection ESP", Opened = true })

secESP:Toggle({ Title="Enable ESP", Value=false, Callback=function(v)
    State.ESP.active = v
    if not v and getgenv()._XKID_ESP_CACHE then
        for _,c in pairs(getgenv()._XKID_ESP_CACHE) do pcall(function() c.texts.Visible=false; c.tracer.Visible=false; for _,l in ipairs(c.boxLines) do l.Visible=false end; c.hl.Enabled=false end) end
    end
    notify("ESP", v and "✅ ESP Aktif" or "❌ ESP Mati", 2)
end})

secESP:Dropdown({ Title="Tracer Mode", Values={"Bottom","Center","Mouse","OFF"}, Value="Bottom", Callback=function(v) State.ESP.tracerMode=v; notify("ESP", "Tracer: "..v, 2) end })
secESP:Toggle({ Title="Highlight Mode (All Players)", Desc="Enable box & highlight for ALL players", Value=false, Callback=function(v) State.ESP.highlightMode=v; notify("ESP", v and "Highlight Semua ON" or "Highlight Semua OFF", 2) end })
secESP:Slider({ Title="Draw Distance", Step=10, Value={Min=50,Max=500,Default=300}, Callback=function(v) State.ESP.maxDrawDistance=tonumber(v) or 300; notify("ESP", "Jarak render: "..v.."m", 2) end })

local secESPColor = T_ESP:Section({ Title = "🎨 ESP Colors", Opened = false })
secESPColor:Dropdown({ Title="Normal Player Color", Values={"Hijau", "Merah", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam"}, Value="Hijau", Callback=function(v) if colorMap[v] then State.ESP.tracerColor_N = colorMap[v] end; notify("Color", "Warna normal: "..v, 2) end })
secESPColor:Dropdown({ Title="Suspect Color (Glitcher)", Values={"Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam", "Crimson"}, Value="Crimson", Callback=function(v) if colorMap[v] then State.ESP.tracerColor_S = colorMap[v]; State.ESP.boxColor_S = colorMap[v] end; notify("Color", "Warna suspect: "..v, 2) end })
secESPColor:Dropdown({ Title="Large Glitch Acc Color", Values={"Orange", "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Pink", "Putih", "Hitam"}, Value="Orange", Callback=function(v) if colorMap[v] then State.ESP.tracerColor_G = colorMap[v]; State.ESP.boxColor_G = colorMap[v] end; notify("Color", "Warna glitch: "..v, 2) end })

-- ══════════════════════════════════════════════════════════════
--  TAB 7: UTILITY 
-- ══════════════════════════════════════════════════════════════
local T_UTIL = Window:Tab({ Title = "Utility", Icon = "smartphone" })

local secChat = T_UTIL:Section({ Title = "💬 Chat Logger", Opened = true })
secChat:Toggle({ Title = "Chat Log ON/OFF", Value = false, Callback = function(v)
    State.Utility.chatLog = v
    if not v then
        notify("Chat Log", "Logger dimatikan", 2)
    else
        notify("Chat Log", "Pilih target di dropdown!", 2)
    end
end})

local chatLogPanel = secChat:Paragraph({ Title = "Log Chat", Desc = "Menunggu chat..." })

local chatTargetDropdown = secChat:Dropdown({
    Title = "Pilih Target",
    Values = getDisplayNames(),
    Callback = function(v)
        local p = findPlayerByDisplay(v)
        if p and State.Utility.chatLog then
            State.Utility.chatTarget = p
            State.Utility.chatHistory = {}
            pcall(function() chatLogPanel:SetDesc("Target: " .. p.DisplayName) end)
            notify("Chat Log", "Ngikutin chat "..p.DisplayName, 2)
        end
    end
})

secChat:Button({ Title = "🔄 Refresh List", Callback = function()
    pcall(function() chatTargetDropdown:Refresh(getDisplayNames(), true) end); notify("Chat Log", "List target diupdate", 2)
end})
secChat:Button({ Title = "🗑️ Clear Log", Callback = function()
    State.Utility.chatHistory = {}
    pcall(function() chatLogPanel:SetDesc("Menunggu chat...") end); notify("Chat Log", "Log dibersihkan", 2)
end})

local secMisc = T_UTIL:Section({ Title = "🛠️ Misc Utility", Opened = true })
secMisc:Button({ Title = "📋 Copy JobID", Desc = "Salin ID Server untuk invite teman", Callback = function()
    pcall(function() setclipboard(game.JobId) end)
    notify("Utilitas", "JobID tersalin!", 2)
end})
secMisc:Slider({ Title="FPS Capper", Desc="Buka batas FPS", Step=5, Value={Min=30, Max=240, Default=60}, Callback=function(v) 
    pcall(function() setfpscap(v) end); notify("Utilitas", "Batas FPS: "..v, 2) 
end})

-- ══════════════════════════════════════════════════════════════
--  TAB 8: SECURITY
-- ══════════════════════════════════════════════════════════════
local T_SEC = Window:Tab({ Title = "Security", Icon = "shield" })

local secProt = T_SEC:Section({ Title = "🛡️ Protection", Opened = true })
secProt:Toggle({ Title = "🕳️ Anti Void", Value = false, Callback = function(v)
    if v then
        State.Security.voidConn = TrackC(RS.Heartbeat:Connect(function()
            local hrp = getRoot()
            if hrp and hrp.Position.Y <= workspace.FallenPartsDestroyHeight + 50 then hrp.Velocity = Vector3.zero; hrp.CFrame = hrp.CFrame + Vector3.new(0, 300, 0); notify("Anti Void", "Terselamatkan dari void!", 2) end
        end))
        notify("Protection", "Anti Void nyala", 2)
    else
        if State.Security.voidConn then State.Security.voidConn:Disconnect(); State.Security.voidConn = nil end
        notify("Protection", "Anti Void mati", 2)
    end
end})
secProt:Toggle({ Title = "⏰ Anti AFK", Value = true, Callback = function(v)
    if v then
        if not State.Security.afkConn then State.Security.afkConn = TrackC(LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); task.wait(1) end)) end
        notify("Protection", "Anti AFK nyala", 2)
    else
        if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn = nil end
        notify("Protection", "Anti AFK mati", 2)
    end
end})
secProt:Button({ Title = "🔧 Stuck Fix", Callback = function()
    local hrp, hum = getRoot(), getHum()
    if hrp then hrp.Anchored = false; hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
    if hum then hum.Sit = false; hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    notify("Stuck Fix", "Karakter dilepasin 🛠️", 2)
end})

local secSrv = T_SEC:Section({ Title = "🌐 Server", Opened = true })
secSrv:Toggle({ Title = "🔄 Auto Rejoin", Value = false, Callback = function(v)
    if v then
        State.Security.arConn = TrackC(CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then notify("Auto Rejoin", "Kena kick, rejoin...", 3); task.wait(1); TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end
        end))
        local lastHb = tick()
        State.Security.arFallback = TrackC(RS.Heartbeat:Connect(function() lastHb = tick() end))
        task.spawn(function()
            while State.Security.arConn do task.wait(10)
                if tick() - lastHb > 15 then notify("Auto Rejoin", "Koneksi putus, rejoin...", 3); task.wait(2); pcall(function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end); break end
            end
        end)
        notify("Server", "Auto Rejoin siaga", 2)
    else
        if State.Security.arConn then State.Security.arConn:Disconnect(); State.Security.arConn = nil end
        if State.Security.arFallback then State.Security.arFallback:Disconnect(); State.Security.arFallback = nil end
        notify("Server", "Auto Rejoin mati", 2)
    end
end})
secSrv:Button({ Title = "🔁 Rejoin", Callback = function() notify("Rejoin", "Masuk ulang server sama...", 2); TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end })
secSrv:Button({ Title = "🏃 Server Hop", Callback = function()
    notify("Server Hop", "Nyari server sepi...", 2)
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if req then
            local res = req({Url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100", Method = "GET"})
            if res.StatusCode == 200 then
                local body = HttpService:JSONDecode(res.Body)
                if body and body.data then for _, v in ipairs(body.data) do if v.playing < v.maxPlayers and v.id ~= game.JobId then TPService:TeleportToPlaceInstance(game.PlaceId, v.id, LP); return end end end
            end
        end
    end)
end})

local secPerf = T_SEC:Section({ Title = "⚡ Performance", Opened = true })
local advCache = {mats={}, texs={}, shadows=true, level=10, brightness=0, clockTime=0, fogEnd=0}
secPerf:Toggle({ Title = "FPS Boost (No Textures)", Value = false, Callback = function(v)
    State.Security.antiLag = v
    if v then
        pcall(function() advCache.level = settings().Rendering.QualityLevel end)
        advCache.shadows = Lighting.GlobalShadows; advCache.brightness = Lighting.Brightness
        advCache.clockTime = Lighting.ClockTime; advCache.fogEnd = Lighting.FogEnd
        pcall(function() settings().Rendering.QualityLevel = 1 end)
        Lighting.GlobalShadows = false; Lighting.Brightness = 1; Lighting.FogEnd = 100000
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then advCache.mats[obj] = obj.Material; obj.Material = Enum.Material.SmoothPlastic
            elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then advCache.texs[obj] = obj.Enabled; obj.Enabled = false end
        end
        notify("FPS Boost", "FPS boost nyala ⚡", 2)
    else
        pcall(function() if advCache.level then settings().Rendering.QualityLevel = advCache.level end end)
        if advCache.shadows ~= nil then Lighting.GlobalShadows = advCache.shadows end
        if advCache.brightness then Lighting.Brightness = advCache.brightness end
        if advCache.clockTime then Lighting.ClockTime = advCache.clockTime end
        if advCache.fogEnd then Lighting.FogEnd = advCache.fogEnd end
        for obj, mat in pairs(advCache.mats) do if obj and obj.Parent then obj.Material = mat end end
        for obj, enb in pairs(advCache.texs) do if obj and obj.Parent then obj.Enabled = enb end end
        advCache.mats = {}; advCache.texs = {}
        notify("FPS Boost", "FPS boost mati 🌿", 2)
    end
end})

T_SEC:Section({ Title = "🔒 Camera Lock", Opened = true }):Toggle({ Title = "Shift Lock", Value = false, Callback = function(v) toggleShiftLock(v) end })

-- ══════════════════════════════════════════════════════════════
--  TAB 9: SETTINGS
-- ══════════════════════════════════════════════════════════════
local T_SET = Window:Tab({ Title = "Settings", Icon = "settings" })

local secCfg = T_SET:Section({ Title = "⚙️ Config", Opened = true })
local cfgName = "XKID_Config"
secCfg:Input({ Title = "Nama Config", Default = "XKID_Config", Callback = function(v) cfgName = v end })
secCfg:Button({ Title = "💾 Simpan Config", Callback = function()
    pcall(function()
        if makefolder and writefile then
            if not isfolder("XKID_HUB") then makefolder("XKID_HUB") end
            local data = {
                Move = {ws = State.Move.ws, jp = State.Move.jp, flyS = State.Move.flyS},
                ESP = {active = State.ESP.active, tracerMode = State.ESP.tracerMode, maxDrawDistance = State.ESP.maxDrawDistance, highlightMode = State.ESP.highlightMode},
                Security = {shiftLock = State.Security.shiftLock, antiLag = State.Security.antiLag}
            }
            writefile("XKID_HUB/"..cfgName..".json", HttpService:JSONEncode(data))
            notify("Config", "Config tersimpan 💾", 2)
            pcall(function() configDropdown:Refresh(getConfigList(), true) end)
        end
    end)
end})

local configDropdown = secCfg:Dropdown({ Title = "📂 Load Config", Values = getConfigList(), Callback = function(selected)
    if selected == "Tidak ada config" then return end
    cfgName = selected
    pcall(function()
        if isfile and readfile and isfile("XKID_HUB/"..selected..".json") then
            local data = HttpService:JSONDecode(readfile("XKID_HUB/"..selected..".json"))
            if data then
                if data.Move then State.Move.ws = data.Move.ws or 16; State.Move.jp = data.Move.jp or 50; State.Move.flyS = data.Move.flyS or 60; local h = getHum(); if h then h.WalkSpeed = State.Move.ws; h.UseJumpPower = true; h.JumpPower = State.Move.jp end end
                if data.ESP then State.ESP.tracerMode = data.ESP.tracerMode or "Bottom"; State.ESP.maxDrawDistance = data.ESP.maxDrawDistance or 300; State.ESP.highlightMode = data.ESP.highlightMode or false end
                if data.Security and data.Security.shiftLock ~= State.Security.shiftLock then toggleShiftLock(data.Security.shiftLock) end
                notify("Config", "Config dimuat 🔓", 2)
            end
        end
    end)
end})
secCfg:Button({ Title = "🔄 Refresh List", Callback = function() pcall(function() configDropdown:Refresh(getConfigList(), true) end); notify("Config", "List diupdate!", 2) end })

local secTheme = T_SET:Section({ Title = "🎨 Theme", Opened = true })
secTheme:Dropdown({ Title = "Theme", Values = (function() local n = {}; for name in pairs(WindUI:GetThemes()) do table.insert(n, name) end; table.sort(n); if not table.find(n, "Crimson") then table.insert(n, 1, "Crimson") end; return n end)(), Value = "Crimson", Callback = function(s) pcall(function() WindUI:SetTheme(s) end); notify("Theme", "Ganti ke "..s, 2) end })
secTheme:Toggle({ Title = "Acrylic", Value = true, Callback = function() pcall(function() WindUI:ToggleAcrylic(not WindUI.Window.Acrylic) end); notify("Theme", "Acrylic ditoggle", 2) end })
secTheme:Toggle({ Title = "Transparent", Value = true, Callback = function(s) pcall(function() Window:ToggleTransparency(s) end); notify("Theme", "Transparansi: "..tostring(s), 2) end })
secTheme:Keybind({ Title = "Toggle Key", Value = Enum.KeyCode.RightShift, Callback = function(v) Window:SetToggleKey(typeof(v) == "EnumItem" and v or Enum.KeyCode[v]); notify("Keybind", "Tombol menu diubah", 2) end })

-- ══════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if State.SoftFling.active and getRoot() then
            local r = getRoot()
            pcall(function() r.AssemblyAngularVelocity = Vector3.new(0, State.SoftFling.power, 0); r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, 50, r.AssemblyLinearVelocity.Z) end)
        end
        RS.RenderStepped:Wait()
    end
end)
TrackC(RS.Stepped:Connect(function()
    if (State.Move.ncp or State.SoftFling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end))

task.spawn(function()
    local dropTime = 0
    while getgenv()._XKID_RUNNING do
        task.wait(2)
        local fps = 60
        if #fpsSamples > 0 then local avg = 0; for _, s in ipairs(fpsSamples) do avg = avg + s end; fps = math.floor(1 / (avg / #fpsSamples)) end
        if fps < 15 then dropTime = dropTime + 1 else dropTime = 0 end
        if dropTime >= 5 and not State.Security.antiLag then
            notify("Warning", "FPS rendah, auto boost...", 4)
            State.Security.antiLag = true; pcall(function() advCache.level = settings().Rendering.QualityLevel end)
            advCache.shadows = Lighting.GlobalShadows; Lighting.GlobalShadows = false; pcall(function() settings().Rendering.QualityLevel = 1 end)
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then advCache.mats[obj] = obj.Material; obj.Material = Enum.Material.SmoothPlastic
                elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then advCache.texs[obj] = obj.Enabled; obj.Enabled = false end
            end
            dropTime = 0
        end
    end
end)

if not State.Security.afkConn then
    State.Security.afkConn = TrackC(LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); task.wait(1) end))
end

WindUI:SetNotificationLower(true)

task.spawn(function() pcall(function() cachedMapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name; lastMapCheck = tick() end) end)

-- Default ke Home tab
task.wait(0.2)
pcall(function() Window:SelectTab(T_HOME) end)

print("XKID Script Siap 💎")
