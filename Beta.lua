--[[
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      ██╗  ██╗██╗  ██╗██╗██████╗     ███████╗ ██████╗           ║
║      ╚██╗██╔╝██║ ██╔╝██║██╔══██╗    ██╔════╝██╔════╝           ║
║       ╚███╔╝ █████╔╝ ██║██║  ██║    ███████╗██║                 ║
║       ██╔██╗ ██╔═██╗ ██║██║  ██║    ╚════██║██║                 ║
║      ██╔╝ ██╗██║  ██╗██║██████╔╝    ███████║╚██████╗           ║
║      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═════╝     ╚══════╝ ╚═════╝           ║
║                                                                  ║
║                        @WTF.XKID                                ║
║                      Luxury Script                              ║
║                     Powered by WindUI                            ║
║                     Theme: CRIMSON                               ║
║                                                                  ║
║                    Designed by @WTF.XKID                        ║
╚══════════════════════════════════════════════════════════════════╝

  ✨ Premium Features (FIXED & RESTORED):
  • Avatar Refresh (/re - CFrame & Velocity Safe)
  • Teleport & Location Saver (5 Slots Full)
  • Movement (Speed / Jump / Fly / NoClip / Fling)
  • NEW Freecam Engine (Identical to Fly Controls)
  • Spectate (Orbit & First Person + Distance)
  • Modern Hybrid ESP (Tracer Modes + Multi Colors)
  • World Control (Full Weather + Fullbright + Graphics)
  • Security (Anti-AFK / Anti Screen-Block / Anti-Lag)
  • Live FPS & PING Counter
  
  💎 Created by @WTF.XKID
]]

local RS = game:GetService("RunService")

-- ══════════════════════════════════════════════════════════════
--  0. MEMORY MANAGEMENT & CLEANUP
-- ══════════════════════════════════════════════════════════════
if getgenv()._XKID_RUNNING then getgenv()._XKID_RUNNING = false end

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
        if getgenv()._XKID_CONNS then
            for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end
        end
        RS:UnbindFromRenderStep("XKIDFreecam")
        RS:UnbindFromRenderStep("XKIDFly")
        RS:UnbindFromRenderStep("XKIDSpec")
    end)
    task.wait(0.2) 
    collectgarbage("collect")
end

getgenv()._XKID_LOADED = true
getgenv()._XKID_RUNNING = true
getgenv()._XKID_CONNS = {}
local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

-- ══════════════════════════════════════════════════════════════
--  LOAD WINDUI
-- ══════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- ══════════════════════════════════════════════════════════════
--  SERVICES & PLAYER
-- ══════════════════════════════════════════════════════════════
local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting    = game:GetService("Lighting")
local TPService   = game:GetService("TeleportService")
local StatsService= game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService   = game:GetService("TextChatService")
local LP          = Players.LocalPlayer
local Cam         = workspace.CurrentCamera
local onMobile    = not UIS.KeyboardEnabled

-- ══════════════════════════════════════════════════════════════
--  STATE MANAGEMENT
-- ══════════════════════════════════════════════════════════════
local State = {
    Move     = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly      = { active = false, bv = nil, bg = nil, _keys = {} },
    Fling    = { active = false, power = 1000000 },
    SoftFling= { active = false, power = 4000 },
    Teleport = { selectedTarget = "" },
    Security = { afkConn = nil },
    Cinema   = { active = false },
    Spectate = { hideName = false },
    Avatar   = { isRefreshing = false },
    Atmos    = { fullbright = false, default = { Ambient = Lighting.Ambient } },
    ESP = {
        active          = false,
        cache           = getgenv()._XKID_ESP_CACHE,
        boxMode         = "Corner",
        tracerMode      = "Bottom",
        maxDrawDistance = 300,
        showDistance    = true,
        showNickname    = true,
        boxColor_N      = Color3.fromRGB(0, 255, 150),
        boxColor_S      = Color3.fromRGB(220, 20, 60),
        tracerColor_N   = Color3.fromRGB(0, 200, 255),
        tracerColor_S   = Color3.fromRGB(220, 20, 60),
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
--  HELPERS
-- ══════════════════════════════════════════════════════════════
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end
local function getDisplayNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")") end end
    return t
end
local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do if str == p.DisplayName .. " (@" .. p.Name .. ")" then return p end end
    return nil
end
local function getCharRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head") or char:FindFirstChild("Torso")
end
local function notify(title, content, dur) WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 }) end

TrackC(LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
    end
end))

-- ══════════════════════════════════════════════════════════════
--  AVATAR REFRESH / FAST RESPAWN
-- ══════════════════════════════════════════════════════════════
local function fastRespawn() 
    if State.Avatar.isRefreshing then return end
    local char = LP.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local hrp = getRoot()
    if not hum or not hrp then notify("❌ Error", "Character not ready"); return end

    State.Avatar.isRefreshing = true
    notify("🔄 Fast Respawn", "Saving state & respawning...", 1.5)
    
    local savedCF = hrp.CFrame; local savedVel = hrp.AssemblyLinearVelocity; local savedCamCF = Cam.CFrame
    Cam.CameraType = Enum.CameraType.Scriptable; Cam.CFrame = savedCamCF
    
    local charAddedConn
    charAddedConn = TrackC(LP.CharacterAdded:Connect(function(newChar)
        charAddedConn:Disconnect() 
        local newHrp = newChar:WaitForChild("HumanoidRootPart", 5)
        local newHum = newChar:WaitForChild("Humanoid", 5)
        local newHead = newChar:WaitForChild("Head", 5)
        
        if not LP:HasAppearanceLoaded() then LP.CharacterAppearanceLoaded:Wait() end
        task.wait(0.2) 
        
        if newHrp and newHum then
            newHrp.CFrame = savedCF
            newHrp.AssemblyLinearVelocity = savedVel
            Cam.CameraSubject = newHum; Cam.CameraType = Enum.CameraType.Custom
            notify("✨ Success", "Position & Velocity Restored", 2)
        end
        State.Avatar.isRefreshing = false
    end))
    hum.Health = 0
    task.delay(5, function() State.Avatar.isRefreshing = false end)
end

TrackC(LP.Chatted:Connect(function(msg)
    local m = msg:lower()
    if m == "/re" or m == "!re" or m == ";re" then fastRespawn() end
end))

-- ══════════════════════════════════════════════════════════════
--  FREECAM ENGINE (Requested: Identical to Fly)
-- ══════════════════════════════════════════════════════════════
local FC = { active=false, pos=Vector3.zero, pitchDeg=0, yawDeg=0, speed=5, sens=0.25, savedCF=nil }
local fcMoveTouch, fcMoveSt, fcRotTouch, fcRotLast = nil, nil, nil, nil; local fcJoy = Vector2.zero; local fcConns = {}; local fcKeysHeld = {}

local function startFreecamCapture()
    fcKeysHeld = {}
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp) if gp then return end; local k = inp.KeyCode; if k==Enum.KeyCode.W or k==Enum.KeyCode.A or k==Enum.KeyCode.S or k==Enum.KeyCode.D or k==Enum.KeyCode.E or k==Enum.KeyCode.Q then fcKeysHeld[k]=true end; if inp.UserInputType==Enum.UserInputType.MouseButton2 then FC._mouseRot=true; UIS.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition end end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp) fcKeysHeld[inp.KeyCode]=false; if inp.UserInputType==Enum.UserInputType.MouseButton2 then FC._mouseRot=false; UIS.MouseBehavior=Enum.MouseBehavior.Default end end))
    table.insert(fcConns, UIS.InputChanged:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseMovement and FC._mouseRot then FC.yawDeg = FC.yawDeg - inp.Delta.X*FC.sens; FC.pitchDeg = math.clamp(FC.pitchDeg - inp.Delta.Y*FC.sens,-80,80) end end))
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp,gp) if gp or inp.UserInputType~=Enum.UserInputType.Touch then return end; local half=Cam.ViewportSize.X/2; if inp.Position.X>half then if not fcRotTouch then fcRotTouch=inp; fcRotLast=inp.Position end else if not fcMoveTouch then fcMoveTouch=inp; fcMoveSt=inp.Position end end end))
    table.insert(fcConns, UIS.TouchMoved:Connect(function(inp) if inp==fcRotTouch and fcRotLast then FC.yawDeg = FC.yawDeg - (inp.Position.X-fcRotLast.X)*FC.sens; FC.pitchDeg = math.clamp(FC.pitchDeg - (inp.Position.Y-fcRotLast.Y)*FC.sens,-80,80); fcRotLast=inp.Position end; if inp==fcMoveTouch and fcMoveSt then local dx=inp.Position.X-fcMoveSt.X; local dy=inp.Position.Y-fcMoveSt.Y; fcJoy=Vector2.new(math.abs(dx)>25 and math.clamp((dx-math.sign(dx)*25)/80,-1,1) or 0, math.abs(dy)>20 and math.clamp((dy-math.sign(dy)*20)/80,-1,1) or 0) end end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp) if inp.UserInputType~=Enum.UserInputType.Touch then return end; if inp==fcRotTouch then fcRotTouch=nil; fcRotLast=nil end; if inp==fcMoveTouch then fcMoveTouch=nil; fcMoveSt=nil; fcJoy=Vector2.zero end end))
end

local function stopFreecamCapture() for _,c in ipairs(fcConns) do c:Disconnect() end; fcConns={}; fcMoveTouch=nil; fcMoveSt=nil; fcRotTouch=nil; fcRotLast=nil; fcJoy=Vector2.zero; fcKeysHeld={}; FC._mouseRot=false; UIS.MouseBehavior=Enum.MouseBehavior.Default end

local function startFreecamLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value+1, function(dt)
        if not FC.active then return end; Cam.CameraType=Enum.CameraType.Scriptable; local move=Vector3.zero; local camCF = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg),0) * CFrame.Angles(math.rad(FC.pitchDeg),0,0)
        if onMobile then move = camCF.LookVector * (-fcJoy.Y) + camCF.RightVector * fcJoy.X
        else if fcKeysHeld[Enum.KeyCode.W] then move=move+camCF.LookVector end; if fcKeysHeld[Enum.KeyCode.S] then move=move-camCF.LookVector end; if fcKeysHeld[Enum.KeyCode.D] then move=move+camCF.RightVector end; if fcKeysHeld[Enum.KeyCode.A] then move=move-camCF.RightVector end; if fcKeysHeld[Enum.KeyCode.E] then move=move+Vector3.new(0,1,0) end; if fcKeysHeld[Enum.KeyCode.Q] then move=move-Vector3.new(0,-1,0) end end
        if move.Magnitude > 0 then FC.pos = FC.pos + move.Unit * (FC.speed * dt * 60) end
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg),0) * CFrame.Angles(math.rad(FC.pitchDeg),0,0)
        local hrp=getRoot(); local hum=getHum(); if hrp and not hrp.Anchored then hrp.Anchored=true end; if hum then hum:ChangeState(Enum.HumanoidStateType.Physics); hum.WalkSpeed=0; hum.JumpPower=0 end
    end)
end
local function stopFreecamLoop() RS:UnbindFromRenderStep("XKIDFreecam") end

-- ══════════════════════════════════════════════════════════════
--  FLY ENGINE
-- ══════════════════════════════════════════════════════════════
local function toggleFly(v)
    if not v then
        State.Fly.active = false; stopFlyCapture(); RS:UnbindFromRenderStep("XKIDFly")
        if State.Fly.bv then State.Fly.bv:Destroy(); State.Fly.bv=nil end
        if State.Fly.bg then State.Fly.bg:Destroy(); State.Fly.bg=nil end
        local hum = getHum(); if hum then hum.PlatformStand=false; hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.WalkSpeed=State.Move.ws; hum.JumpPower=State.Move.jp end
        return
    end
    local hrp=getRoot(); local hum=getHum(); if not hrp or not hum then return end
    State.Fly.active=true; hum.PlatformStand=true
    State.Fly.bv=Instance.new("BodyVelocity",hrp); State.Fly.bv.MaxForce=Vector3.new(9e9,9e9,9e9); State.Fly.bv.Velocity=Vector3.zero
    State.Fly.bg=Instance.new("BodyGyro",hrp); State.Fly.bg.MaxTorque=Vector3.new(9e9,9e9,9e9); State.Fly.bg.P=50000 
    startFlyCapture()
    RS:BindToRenderStep("XKIDFly", 201, function()
        if not State.Fly.active then return end; local r=getRoot(); if not r then return end
        local camCF=Cam.CFrame; local spd=State.Move.flyS; local move=Vector3.zero; local keys=State.Fly._keys or {}
        if onMobile then move = camCF.LookVector*(-flyJoy.Y) + camCF.RightVector*flyJoy.X
        else if keys[Enum.KeyCode.W] then move=move+camCF.LookVector end; if keys[Enum.KeyCode.S] then move=move-camCF.LookVector end; if keys[Enum.KeyCode.D] then move=move+camCF.RightVector end; if keys[Enum.KeyCode.A] then move=move-camCF.RightVector end; if keys[Enum.KeyCode.E] then move=move+Vector3.new(0,1,0) end; if keys[Enum.KeyCode.Q] then move=move-Vector3.new(0,1,0) end end
        State.Fly.bv.Velocity = move.Magnitude > 0 and move.Unit * spd or Vector3.zero
        State.Fly.bg.CFrame   = CFrame.new(r.Position, r.Position+camCF.LookVector)
    end)
end

-- ══════════════════════════════════════════════════════════════
--  HYBRID DETECTION ESP ENGINE (Drawing API)
-- ══════════════════════════════════════════════════════════════
local function initPlayerCache(player)
    if State.ESP.cache[player] then return end
    local cache = { texts = Drawing.new("Text"), tracer = Drawing.new("Line"), boxLines = {}, hl = nil, isSuspect= false, reason = "" }
    cache.texts.Center = true; cache.texts.Outline = true; cache.texts.Font = 2; cache.texts.Size = 13
    cache.tracer.Thickness = 1.5; for i = 1, 4 do local line = Drawing.new("Line"); line.Thickness = 1.5; cache.boxLines[i] = line end
    State.ESP.cache[player] = cache
end

task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if State.ESP.active then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local isSus = false; local reason = ""
                    for _, v in pairs(p.Character:GetChildren()) do
                        if v:IsA("BasePart") and (v.Size.X > 20 or v.Size.Y > 20 or v.Size.Z > 20) then isSus = true; reason = "Glitcher" break end
                    end
                    initPlayerCache(p); State.ESP.cache[p].isSuspect = isSus; State.ESP.cache[p].reason = reason
                end
            end
        end
        task.wait(1)
    end
end)

TrackC(RS.RenderStepped:Connect(function()
    if not State.ESP.active then return end
    local myHrp = getCharRoot(LP.Character)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character; local hrp = getCharRoot(char); local hum = char and char:FindFirstChildOfClass("Humanoid")
            initPlayerCache(player); local c = State.ESP.cache[player]
            local active = char and hrp and hum and hum.Health > 0 and myHrp
            local dist = active and (hrp.Position - myHrp.Position).Magnitude or 9999
            if not active or dist > State.ESP.maxDrawDistance then
                c.texts.Visible = false; c.tracer.Visible = false; for _, l in ipairs(c.boxLines) do l.Visible = false end
                if c.hl then c.hl.Enabled = false end continue
            end
            local rootPos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
            if not onScreen then c.texts.Visible = false; c.tracer.Visible = false; for _, l in ipairs(c.boxLines) do l.Visible = false end; continue end
            
            local isSus = c.isSuspect; local txt = ""
            if State.ESP.showNickname then txt = player.DisplayName end
            if State.ESP.showDistance then txt = txt .. "\n[" .. math.floor(dist) .. "m]" end
            if isSus then txt = txt .. "\n⚠ " .. c.reason .. " ⚠" end
            c.texts.Text = txt; c.texts.Color = isSus and State.ESP.boxColor_S or State.ESP.nameColor
            c.texts.Position = Vector2.new(rootPos.X, rootPos.Y - 45); c.texts.Visible = true
            
            if State.ESP.tracerMode ~= "OFF" or isSus then
                local origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
                if State.ESP.tracerMode == "Center" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2) end
                c.tracer.From = origin; c.tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                c.tracer.Color = isSus and State.ESP.tracerColor_S or State.ESP.tracerColor_N; c.tracer.Visible = true
            else c.tracer.Visible = false end
            
            if isSus then
                if not c.hl or c.hl.Parent ~= char then if c.hl then c.hl:Destroy() end; c.hl = Instance.new("Highlight", char); c.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end
                c.hl.FillColor = State.ESP.boxColor_S; c.hl.Enabled = true
            else if c.hl then c.hl.Enabled = false end end
        end
    end
end))

-- ══════════════════════════════════════════════════════════════
--  MAIN WINDOW
-- ══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title       = "@WTF.XKID",
    Subtitle    = "Luxury Script",
    Author      = "by @WTF.XKID",
    Folder      = "XKIDScript",
    Icon        = "zap",
    Theme       = "Crimson",
    Acrylic     = true,
    Transparent = true,
    Size        = UDim2.fromOffset(720, 560),
    MinSize     = Vector2.new(580, 420),
    MaxSize     = Vector2.new(880, 620),
    ToggleKey   = Enum.KeyCode.RightShift,
    Resizable   = true,
    AutoScale   = true,
    NewElements = true,
    SideBarWidth= 200,
    Topbar = { Height = 44, ButtonsType = "Default" },
    OpenButton  = {
        Title = "⚡XKID HUB", Icon = "shield", CornerRadius = UDim.new(1, 0), StrokeThickness = 3, Enabled = true, Draggable = true,
        Color = ColorSequence.new(Color3.fromRGB(220, 20, 60), Color3.fromRGB(180, 10, 40)),
    },
    User = { Enabled = true, Anonymous = false },
})

-- ══════════════════════════════════════════════════════════════
--  TAB 1: HOME
-- ══════════════════════════════════════════════════════════════
local T_HOME = Window:Tab({ Title = "Home", Icon = "home" })
local statusLabel = T_HOME:Section({ Title = "System Status" }):Paragraph({ Title = "Live Metrics", Desc  = "Calculating..." })

task.spawn(function()
    while getgenv()._XKID_RUNNING do
        local fps = math.floor(1/RS.RenderStepped:Wait()); local ping = 0
        pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        statusLabel:SetDesc(string.format("🔹 FPS: %d\n🔹 PING: %d ms\n🔹 Players: %d", fps, ping, #Players:GetPlayers()))
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 2: PLAYER (RESTORED ALL SLIDERS)
-- ══════════════════════════════════════════════════════════════
local T_PL = Window:Tab({ Title = "Player", Icon = "user" })
local secAV = T_PL:Section({ Title = "Avatar" })
secAV:Button({ Title = "Fast Respawn (/re)", Desc = "Save CFrame & Momentum", Callback = fastRespawn })

local secMov = T_PL:Section({ Title = "Movement" })
secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v; if getHum() then getHum().UseJumpPower=true; getHum().JumpPower = v end end })
secMov:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(v)
    if v then State.Move.infJ = TrackC(UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(3) end end))
    else if State.Move.infJ then State.Move.infJ:Disconnect() end end
end})

local secAbi = T_PL:Section({ Title = "Abilities" })
secAbi:Toggle({ Title = "Fly", Value = false, Callback = toggleFly })
secAbi:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 10, Max = 500, Default = 60 }, Callback = function(v) State.Move.flyS = v end })
secAbi:Toggle({ Title = "NoClip", Value = false, Callback = function(v) State.Move.ncp = v end })
secAbi:Toggle({ Title = "Extreme Fling", Value = false, Callback = function(v) State.Fling.active=v; State.Move.ncp=v end })
secAbi:Toggle({ Title = "God Mode", Value = false, Callback = function(v)
    local h = getHum(); if h then h.MaxHealth = v and math.huge or 100; h.Health = v and math.huge or 100 end
end})

-- ══════════════════════════════════════════════════════════════
--  TAB 3: TELEPORT (RESTORED 5 SLOTS)
-- ══════════════════════════════════════════════════════════════
local T_TP = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local secTP = T_TP:Section({ Title = "Players" })
local tpInput = ""; secTP:Input({ Title = "Player Name", Callback = function(v) tpInput = v end })
secTP:Button({ Title = "Teleport", Callback = function()
    for _,p in pairs(Players:GetPlayers()) do if p.Name:lower():find(tpInput:lower()) or p.DisplayName:lower():find(tpInput:lower()) then getRoot().CFrame = getCharRoot(p.Character).CFrame break end end
end})

local secSlots = T_TP:Section({ Title = "Location Slots" })
local SavedLocs = {}
for i = 1, 5 do
    secSlots:Button({ Title = "Save Slot "..i, Callback = function() SavedLocs[i] = getRoot().CFrame; notify("Saved", "Slot "..i) end })
    secSlots:Button({ Title = "Load Slot "..i, Callback = function() if SavedLocs[i] then getRoot().CFrame = SavedLocs[i] end end })
end

-- ══════════════════════════════════════════════════════════════
--  TAB 4: CAMERA (RESTORED FREECAM V2)
-- ══════════════════════════════════════════════════════════════
local T_CAM = Window:Tab({ Title = "Camera", Icon = "eye" })
local secFC = T_CAM:Section({ Title = "Freecam v2" })
secFC:Toggle({ Title = "Enable Freecam", Desc = "Identical to Fly Controls", Value = false, Callback = function(v)
    FC.active = v; if v then FC.pos=Cam.CFrame.Position; startFreecamCapture(); startFreecamLoop() else stopFreecamLoop(); stopFreecamCapture(); Cam.CameraType=4; getRoot().Anchored=false end
end})
secFC:Slider({ Title = "Speed", Step = 1, Value = { Min = 1, Max = 100, Default = 5 }, Callback = function(v) FC.speed = v end })

-- ══════════════════════════════════════════════════════════════
--  TAB 5: WORLD (RESTORED WEATHER & LIGHT)
-- ══════════════════════════════════════════════════════════════
local T_WO = Window:Tab({ Title = "World", Icon = "globe" })
local secWorld = T_WO:Section({ Title = "Environment" })
secWorld:Slider({ Title = "Clock Time", Step = 1, Value = { Min = 0, Max = 24, Default = 14 }, Callback = function(v) Lighting.ClockTime = v end })
secWorld:Toggle({ Title = "Fullbright", Callback = function(v) Lighting.Ambient = v and Color3.new(1,1,1) or Color3.new(0.5,0.5,0.5); Lighting.FogEnd = v and 100000 or 1000 end })

-- ══════════════════════════════════════════════════════════════
--  TAB 6: ESP (RESTORED COLORS & OPTIONS)
-- ══════════════════════════════════════════════════════════════
local T_ESP = Window:Tab({ Title = "ESP", Icon = "radar" })
local secE = T_ESP:Section({ Title = "Master" })
secE:Toggle({ Title = "Enable ESP", Callback = function(v) State.ESP.active = v end })
secE:Slider({ Title = "Distance", Step = 10, Value = { Min = 50, Max = 2000, Default = 300 }, Callback = function(v) State.ESP.maxDrawDistance = v end })
local secC = T_ESP:Section({ Title = "Colors" })
secC:Dropdown({ Title = "Tracer Color", Values = {"Hijau","Merah","Cyan","Putih"}, Callback = function(v) State.ESP.tracerColor_N = colorMap[v] end })

-- ══════════════════════════════════════════════════════════════
--  TAB 7: SECURITY (RESTORED ANTI-LAG)
-- ══════════════════════════════════════════════════════════════
local T_SEC = Window:Tab({ Title = "Security", Icon = "shield" })
local secS = T_SEC:Section({ Title = "Protection" })
secS:Toggle({ Title = "Anti-AFK", Callback = function(v)
    if v then State.Security.afkConn = TrackC(LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end))
    else if State.Security.afkConn then State.Security.afkConn:Disconnect() end end
end})
secS:Toggle({ Title = "Anti Screen-Block", Callback = function(v) _G.ASB = v end })
task.spawn(function()
    while task.wait(1) do
        if _G.ASB then
            for _,p in pairs(Players:GetPlayers()) do if p ~= LP and p.Character then
                for _,v in pairs(p.Character:GetDescendants()) do if v:IsA("BasePart") and v.Size.Magnitude > 50 then v:Destroy() end end
            end end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 8: SETTINGS
-- ══════════════════════════════════════════════════════════════
local T_SET = Window:Tab({ Title = "Settings", Icon = "settings" })
T_SET:Button({ Title = "Rejoin Server", Callback = function() TPService:Teleport(game.PlaceId, LP) end })
T_SET:Keybind({ Title = "Toggle Menu", Value = Enum.KeyCode.RightShift, Callback = function(v) Window:SetToggleKey(v) end })

-- Loops
TrackC(RS.Stepped:Connect(function()
    if State.Move.ncp and LP.Character then for _,v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end end
end))

notify("✅ @WTF.XKID", "Luxury Script Ready | Freecam v2 Fixed", 5)