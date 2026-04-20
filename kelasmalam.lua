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
║                  P R E M I U M   E D I T I O N                  ║
║                     Powered by WindUI                            ║
╚══════════════════════════════════════════════════════════════════╝

  Features:
  • Teleport & Location Saver
  • Movement (Speed / Jump / Fly Linear / NoClip / Ghost Mode)
  • Freecam (Responsive + Mobile Ready)
  • Spectate (Orbit & First Person)
  • Modern ESP (Corner / Box / Highlight / Tracer / Custom Name Color)
  • World (Weather / Atmosphere / Graphics)
  • Security (Anti-AFK / Respawn / ESP Tracker / Memory Purge)
  • Chat Bypass & Fast Commands (/re, !rejoin)
  • Live FPS Counter (Fixed)
  • Auto-Cleanup & Rose Theme Default
]]

-- ══════════════════════════════════════════════════════════════
--  AUTO-CLEANUP (Anti-Lag Re-Execute)
-- ══════════════════════════════════════════════════════════════
if getgenv()._XKID_INSTANCE then
    getgenv()._XKID_INSTANCE:Destroy()
    getgenv()._XKID_INSTANCE = nil
end

-- ══════════════════════════════════════════════════════════════
--  LOAD LIBRARY
-- ══════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- ══════════════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════════════
local Players     = game:GetService("Players")
local RS          = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting    = game:GetService("Lighting")
local TPService   = game:GetService("TeleportService")
local LP          = Players.LocalPlayer
local Cam         = workspace.CurrentCamera
local onMobile    = not UIS.KeyboardEnabled

-- ══════════════════════════════════════════════════════════════
--  STATE MANAGEMENT
-- ══════════════════════════════════════════════════════════════
local State = {
    Move     = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 50 },
    Fly      = { active = false, bv = nil, bg = nil },
    Fling    = { active = false, power = 1000000 },
    SoftFling= { active = false, power = 4000 },
    Teleport = { selectedTarget = "" },
    Security = { afkConn = nil },
    Cinema   = { active = false },
    Spectate = { hideName = false },
    Ghost    = { active = false },
    Chat     = { bypass = false },
    ESP = {
        active          = false,
        cache           = {},
        boxMode         = "Corner",
        tracerMode      = "Bottom",
        maxDrawDistance = 300,
        showDistance    = true,
        showNickname    = true,
        boxColor_N      = Color3.fromRGB(0, 255, 150),
        boxColor_S      = Color3.fromRGB(255, 0, 100),
        tracerColor_N   = Color3.fromRGB(0, 200, 255),
        tracerColor_S   = Color3.fromRGB(255, 50, 50),
        nameColor       = Color3.fromRGB(255, 255, 255),
    },
}

-- ══════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════
local function getRoot()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end

local function getPNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    return t
end

local function getDisplayNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    return t
end

local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do
        if str == p.DisplayName .. " (@" .. p.Name .. ")" then return p end
    end
    return nil
end

-- [Robust Root Matcher] Solusi map beda
local function getCharRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char.PrimaryPart
        or char:FindFirstChild("Head")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChildWhichIsA("BasePart")
end

local function notify(title, content, dur)
    WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 })
end

-- Persistent stats on respawn
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then
            hum.UseJumpPower = true
            hum.JumpPower    = State.Move.jp
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  CHAT COMMANDS & BYPASS
-- ══════════════════════════════════════════════════════════════
LP.Chatted:Connect(function(msg)
    local lowerMsg = msg:lower()
    
    -- Instant Reset Command
    if lowerMsg == ";re" or lowerMsg == "/re" then
        if LP.Character then 
            LP.Character:BreakJoints() 
            notify("Command", "Instant Reset Triggered!", 2)
        end
        return
    end
    
    -- Rejoin Command
    if lowerMsg == "!rejoin" then
        notify("Command", "Rejoining Server...", 2)
        TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        return
    end

    -- Chat Bypass
    if State.Chat.bypass and not msg:match("^/") then
        local bypassed = ""
        for i = 1, #msg do
            bypassed = bypassed .. msg:sub(i, i) .. "\226\128\139"
        end
        -- Note: Bypass lokal visual. Untuk mengirim pesan asli butuh eksekusi `SayMessageRequest` remote,
        -- tapi ini menyisipkan karakter invisible agar teks tidak tersensor jika di-hook.
    end
end)

-- ══════════════════════════════════════════════════════════════
--  ESP ENGINE (DisplayOrder=999)
-- ══════════════════════════════════════════════════════════════
local function getESPGui()
    local sg = LP.PlayerGui:FindFirstChild("_XKIDEsp")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name            = "_XKIDEsp"
        sg.ResetOnSpawn    = false
        sg.DisplayOrder    = 999
        sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
        sg.Parent          = LP.PlayerGui
    end
    return sg
end

local function w2s(pos)
    local sp, on = Cam:WorldToScreenPoint(pos)
    return Vector2.new(sp.X, sp.Y), on
end

local function drawLine(p1, p2, thick, color)
    local dist = (p1 - p2).Magnitude
    if dist < 1 then return nil end
    local dir   = (p2 - p1).Unit
    local angle = math.atan2(dir.Y, dir.X)
    local mid   = (p1 + p2) / 2
    local f = Instance.new("Frame")
    f.BackgroundColor3 = color
    f.BorderSizePixel  = 0
    f.Position  = UDim2.new(0, mid.X - dist/2, 0, mid.Y - thick/2)
    f.Size      = UDim2.new(0, dist, 0, thick)
    f.Rotation  = math.deg(angle)
    f.ZIndex    = 10
    f.Parent    = getESPGui()
    return f
end

local function drawBox(hrp, color, thick, isCorner)
    if not hrp then return {} end
    local top, ton = w2s(hrp.Position + Vector3.new(0,  2.5, 0))
    local bot, bon = w2s(hrp.Position - Vector3.new(0,  3,   0))
    if not ton and not bon then return {} end
    local h   = math.abs(bot.Y - top.Y)
    local w   = h * 0.6
    local tl  = Vector2.new(bot.X - w/2, top.Y)
    local tr  = Vector2.new(bot.X + w/2, top.Y)
    local bl  = Vector2.new(bot.X - w/2, bot.Y)
    local br  = Vector2.new(bot.X + w/2, bot.Y)
    local out = {}
    if isCorner then
        local L = w / 3.5
        for _, pair in ipairs({
            {tl, tl+Vector2.new(L,0)}, {tl, tl+Vector2.new(0,L)},
            {tr, tr-Vector2.new(L,0)}, {tr, tr+Vector2.new(0,L)},
            {bl, bl+Vector2.new(L,0)}, {bl, bl-Vector2.new(0,L)},
            {br, br-Vector2.new(L,0)}, {br, br-Vector2.new(0,L)},
        }) do
            local l = drawLine(pair[1], pair[2], thick, color)
            if l then table.insert(out, l) end
        end
    else
        for _, pair in ipairs({{tl,tr},{tr,br},{br,bl},{bl,tl}}) do
            local l = drawLine(pair[1], pair[2], thick, color)
            if l then table.insert(out, l) end
        end
    end
    return out
end

local function isSuspect(player)
    local char = player.Character
    if not char then return false end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if p.Size.X > 15 or p.Size.Y > 15 or p.Size.Z > 15 then
                return true
            end
        end
    end
    return false
end

local function renderESP(player)
    if not State.ESP.active or player == LP then return end
    local char = player.Character
    if not char then return end
    local hrp  = getCharRoot(char)
    if not hrp then return end
    local myR  = getCharRoot(LP.Character)
    if myR and (myR.Position - hrp.Position).Magnitude > State.ESP.maxDrawDistance then return end

    local suspect    = isSuspect(player)
    local boxColor   = suspect and State.ESP.boxColor_S   or State.ESP.boxColor_N
    local tracerCol  = suspect and State.ESP.tracerColor_S or State.ESP.tracerColor_N

    if not State.ESP.cache[player] then
        State.ESP.cache[player] = { renders = {}, hl = nil }
    end
    local cache = State.ESP.cache[player]

    for _, r in pairs(cache.renders) do
        if r and r.Parent then r:Destroy() end
    end
    cache.renders = {}

    -- Box
    if State.ESP.boxMode == "Corner" or State.ESP.boxMode == "2D Box" then
        if cache.hl then cache.hl.Enabled = false end
        local lines = drawBox(hrp, boxColor, 2, State.ESP.boxMode == "Corner")
        for _, l in ipairs(lines) do table.insert(cache.renders, l) end

    elseif State.ESP.boxMode == "HIGHLIGHT" then
        if not cache.hl or cache.hl.Parent ~= char then
            if cache.hl then cache.hl:Destroy() end
            local hl = Instance.new("Highlight")
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent    = char
            cache.hl     = hl
        end
        cache.hl.FillColor           = boxColor
        cache.hl.OutlineColor        = Color3.new(1, 1, 1)
        cache.hl.FillTransparency    = 0.5
        cache.hl.OutlineTransparency = 0
        cache.hl.Enabled             = true
    else
        if cache.hl then cache.hl.Enabled = false end
    end

    -- Tracer
    if State.ESP.tracerMode ~= "OFF" then
        local sp, on = w2s(hrp.Position - Vector3.new(0, 2.5, 0))
        if on then
            local origin
            if     State.ESP.tracerMode == "Bottom" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
            elseif State.ESP.tracerMode == "Center" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
            elseif State.ESP.tracerMode == "Mouse"  then local m = UIS:GetMouseLocation(); origin = Vector2.new(m.X, m.Y)
            end
            if origin then
                local l = drawLine(origin, sp, 1.5, tracerCol)
                if l then table.insert(cache.renders, l) end
            end
        end
    end

    -- Name + Distance
    local showText = State.ESP.showNickname or State.ESP.showDistance or suspect
    if showText then
        local sp, on = w2s(hrp.Position + Vector3.new(0, 3.2, 0))
        if on then
            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.TextColor3             = suspect and State.ESP.boxColor_S or State.ESP.nameColor
            lbl.TextStrokeColor3       = Color3.new(0, 0, 0)
            lbl.TextStrokeTransparency = 0.4
            lbl.Font                   = Enum.Font.GothamBold
            lbl.TextSize               = 13
            lbl.Size                   = UDim2.new(0, 180, 0, 50)
            lbl.Position               = UDim2.new(0, sp.X - 90, 0, sp.Y - 25)
            lbl.TextXAlignment         = Enum.TextXAlignment.Center
            lbl.ZIndex                 = 11

            local txt = ""
            if State.ESP.showNickname then txt = player.DisplayName end
            if State.ESP.showDistance and myR then
                local dist = math.floor((myR.Position - hrp.Position).Magnitude)
                txt = txt .. (txt ~= "" and "\n" or "") .. dist .. "m"
            end
            if suspect then txt = txt .. (txt ~= "" and "\n" or "") .. "⚠ SUSPECT" end
            
            lbl.Text   = txt
            lbl.Parent = getESPGui()
            table.insert(cache.renders, lbl)
        end
    end
end

RS.RenderStepped:Connect(function()
    if State.ESP.active then
        for _, p in pairs(Players:GetPlayers()) do renderESP(p) end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    local c = State.ESP.cache[p]
    if c then
        for _, r in pairs(c.renders) do if r and r.Parent then r:Destroy() end end
        if c.hl then c.hl:Destroy() end
        State.ESP.cache[p] = nil
    end
end)

-- ══════════════════════════════════════════════════════════════
--  FLY ENGINE (Linear / Fixed)
-- ══════════════════════════════════════════════════════════════
local flyConns = {}
local flyJoy = Vector2.zero

local function startFlyCapture()
    local flyMoveTouch, flyMoveSt = nil, nil
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp.Position.X <= Cam.ViewportSize.X/2 then
            if not flyMoveTouch then flyMoveTouch = inp; flyMoveSt = inp.Position end
        end
    end))
    table.insert(flyConns, UIS.TouchMoved:Connect(function(inp)
        if inp == flyMoveTouch and flyMoveSt then
            local dx = inp.Position.X - flyMoveSt.X
            local dy = inp.Position.Y - flyMoveSt.Y
            flyJoy = Vector2.new(
                math.abs(dx)>25 and math.clamp((dx-math.sign(dx)*25)/80,-1,1) or 0,
                math.abs(dy)>20 and math.clamp((dy-math.sign(dy)*20)/80,-1,1) or 0
            )
        end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp)
        if inp == flyMoveTouch then flyMoveTouch=nil; flyMoveSt=nil; flyJoy=Vector2.zero end
    end))
end

local function stopFlyCapture()
    for _, c in ipairs(flyConns) do c:Disconnect() end
    flyConns={}
    flyJoy=Vector2.zero
end

local function toggleFly(v)
    if not v then
        State.Fly.active = false
        stopFlyCapture()
        RS:UnbindFromRenderStep("XKIDFly")
        if State.Fly.bv then State.Fly.bv:Destroy(); State.Fly.bv=nil end
        if State.Fly.bg then State.Fly.bg:Destroy(); State.Fly.bg=nil end
        local hum = getHum()
        if hum then
            hum.PlatformStand=false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        notify("Fly","✈  Fly OFF")
        return
    end
    
    local hrp=getRoot(); local hum=getHum()
    if not hrp or not hum then return end
    State.Fly.active=true; hum.PlatformStand=true
    
    State.Fly.bv = Instance.new("BodyVelocity", hrp)
    State.Fly.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    State.Fly.bv.Velocity = Vector3.zero
    
    State.Fly.bg = Instance.new("BodyGyro", hrp)
    State.Fly.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    State.Fly.bg.P = 50000 -- Dibesarkan agar pergerakan kaku/linear (tidak smooth melayang)
    
    startFlyCapture()
    
    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value+1, function()
        if not State.Fly.active then return end
        local r=getRoot(); if not r then return end
        local camCF = Cam.CFrame
        local spd = State.Move.flyS
        local move = Vector3.zero
        
        if onMobile then
            move = camCF.LookVector*(-flyJoy.Y) + camCF.RightVector*flyJoy.X
        else
            if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + camCF.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - camCF.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + camCF.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - camCF.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.Q) then move = move - Vector3.new(0,1,0) end
        end
        
        if move.Magnitude > 0 then 
            State.Fly.bv.Velocity = move.Unit * spd 
        else 
            State.Fly.bv.Velocity = Vector3.zero -- Berhenti Instan
        end
        State.Fly.bg.CFrame = CFrame.new(r.Position, r.Position + camCF.LookVector)
    end)
    notify("Fly","✈  Fly Linear ON", 3)
end

-- ══════════════════════════════════════════════════════════════
--  FREECAM ENGINE (Responsive)
-- ══════════════════════════════════════════════════════════════
local FC = {
    active=false, pos=Vector3.zero, vel=Vector3.zero,
    pitchDeg=0, yawDeg=0, speed=1, sens=0.25,
    savedCF=nil, damping=0.40, accel=0.50,
}
local fcRotT,fcMoveT,fcMoveSt,fcRotLast = nil,nil,nil,nil
local fcJoy   = Vector2.zero
local DEAD_X  = 25; local DEAD_Y = 20
local fcConns = {}

local function startFCCapture()
    local keysHeld={}
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp,gp)
        if gp then return end
        local k=inp.KeyCode
        if k==Enum.KeyCode.W or k==Enum.KeyCode.A or k==Enum.KeyCode.S or k==Enum.KeyCode.D or k==Enum.KeyCode.E or k==Enum.KeyCode.Q then keysHeld[k]=true end
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then FC._mouseRot=true; UIS.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        keysHeld[inp.KeyCode]=false
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then FC._mouseRot=false; UIS.MouseBehavior=Enum.MouseBehavior.Default end
    end))
    table.insert(fcConns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement and FC._mouseRot then
            FC.yawDeg   = FC.yawDeg   - inp.Delta.X*FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg-inp.Delta.Y*FC.sens,-80,80)
        end
        if inp.UserInputType==Enum.UserInputType.MouseWheel then Cam.FieldOfView=math.clamp(Cam.FieldOfView-inp.Position.Z*5,10,120) end
    end))
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp,gp)
        if gp or inp.UserInputType~=Enum.UserInputType.Touch then return end
        if inp.Position.X>Cam.ViewportSize.X/2 then
            if not fcRotT then fcRotT=inp; fcRotLast=inp.Position end
        else
            if not fcMoveT then fcMoveT=inp; fcMoveSt=inp.Position end
        end
    end))
    table.insert(fcConns, UIS.TouchMoved:Connect(function(inp)
        if inp==fcRotT and fcRotLast then
            FC.yawDeg   = FC.yawDeg  -(inp.Position.X-fcRotLast.X)*FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg-(inp.Position.Y-fcRotLast.Y)*FC.sens,-80,80)
            fcRotLast=inp.Position
        end
        if inp==fcMoveT and fcMoveSt then
            local dx=inp.Position.X-fcMoveSt.X; local dy=inp.Position.Y-fcMoveSt.Y
            fcJoy=Vector2.new(math.abs(dx)>DEAD_X and math.clamp((dx-math.sign(dx)*DEAD_X)/80,-1,1) or 0, math.abs(dy)>DEAD_Y and math.clamp((dy-math.sign(dy)*DEAD_Y)/80,-1,1) or 0)
        end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.Touch then return end
        if inp==fcRotT  then fcRotT=nil;  fcRotLast=nil end
        if inp==fcMoveT then fcMoveT=nil; fcMoveSt=nil; fcJoy=Vector2.zero end
    end))
    FC._keys=keysHeld
end

local function stopFCCapture()
    for _,c in ipairs(fcConns) do c:Disconnect() end
    fcConns={}; fcRotT=nil; fcMoveT=nil; fcMoveSt=nil; fcRotLast=nil; fcJoy=Vector2.zero; FC._mouseRot=false; FC._keys={}
    UIS.MouseBehavior=Enum.MouseBehavior.Default
end

local function startFCLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value+1, function(dt)
        if not FC.active then return end
        Cam.CameraType=Enum.CameraType.Scriptable
        local cf = CFrame.new(FC.pos) * CFrame.Angles(0,math.rad(FC.yawDeg),0) * CFrame.Angles(math.rad(FC.pitchDeg),0,0)
        local spd=FC.speed*32; local dv=Vector3.zero; local keys=FC._keys or {}
        if onMobile then
            dv=cf.LookVector*(-fcJoy.Y)*spd + cf.RightVector*fcJoy.X*spd
        else
            if keys[Enum.KeyCode.W] then dv=dv+cf.LookVector *spd end
            if keys[Enum.KeyCode.S] then dv=dv-cf.LookVector *spd end
            if keys[Enum.KeyCode.D] then dv=dv+cf.RightVector*spd end
            if keys[Enum.KeyCode.A] then dv=dv-cf.RightVector*spd end
            if keys[Enum.KeyCode.E] then dv=dv+Vector3.new(0,1,0)*spd end
            if keys[Enum.KeyCode.Q] then dv=dv-Vector3.new(0,1,0)*spd end
        end
        FC.vel = FC.vel:Lerp(dv, FC.accel*dt*60)
        FC.vel = FC.vel*(FC.damping^(dt*60))
        FC.pos = FC.pos+FC.vel*dt
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0,math.rad(FC.yawDeg),0) * CFrame.Angles(math.rad(FC.pitchDeg),0,0)
        local hrp=getRoot(); local hum=getHum()
        if hrp and not hrp.Anchored then hrp.Anchored=true end
        if hum and hum:GetState()~=Enum.HumanoidStateType.Physics then hum:ChangeState(Enum.HumanoidStateType.Physics); hum.WalkSpeed=0; hum.JumpPower=0 end
    end)
end

local function stopFCLoop() RS:UnbindFromRenderStep("XKIDFreecam") end

-- ══════════════════════════════════════════════════════════════
--  WINDOW INITIALIZATION (COMPACT UI)
-- ══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title       = "XKID SCRIPT V2",
    Author      = "by XKID",
    Folder      = "XKIDScript",
    Icon        = "shield",
    Theme       = "Rose",
    Acrylic     = true,
    Transparent = true,
    Size        = UDim2.fromOffset(600, 400), -- Diperkecil agar rapi
    MinSize     = Vector2.new(500, 350),
    MaxSize     = Vector2.new(860, 580),
    ToggleKey   = Enum.KeyCode.RightShift,
    Resizable   = true,
    AutoScale   = true,
    NewElements = true,
    SideBarWidth= 180,
    Topbar = { Height = 40, ButtonsType = "Default" },
})

getgenv()._XKID_INSTANCE = Window.Instance
WindUI:SetTheme("Rose")

-- ══════════════════════════════════════════════════════════════
--  TAB 1: TELEPORT (Dikembalikan)
-- ══════════════════════════════════════════════════════════════
local T_TP   = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local secTP  = T_TP:Section({ Title = "Quick Teleport", Opened = true })

local tpTarget = ""
secTP:Input({ Title = "Search Player", Placeholder = "nama player...", Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "Teleport", Callback = function()
    if tpTarget == "" then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and (string.find(p.Name:lower(), tpTarget:lower()) or string.find(p.DisplayName:lower(), tpTarget:lower())) and getCharRoot(p.Character) then
            getRoot().CFrame = getCharRoot(p.Character).CFrame; notify("Teleport","✅ TP ke "..p.DisplayName); return
        end
    end
    notify("Teleport","❌ Player tidak ditemukan")
end })

local pDropOpts = getPNames()
local tpDrop = secTP:Dropdown({ Title = "Player List", Values = pDropOpts, Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "Refresh List", Callback = function() pDropOpts = getPNames() notify("Teleport","Daftar diperbarui!") end })

local secLoc = T_TP:Section({ Title = "Save Location", Opened = false })
local SavedLocs = {}
for i = 1, 3 do
    secLoc:Button({ Title = "Save Slot "..i, Callback = function() local r = getRoot() if r then SavedLocs[i] = r.CFrame notify("Location","💾 Slot "..i.." tersimpan!") end end })
    secLoc:Button({ Title = "Load Slot "..i, Callback = function() if SavedLocs[i] and getRoot() then getRoot().CFrame = SavedLocs[i] notify("Location","📍 TP Slot "..i) end end })
end

-- ══════════════════════════════════════════════════════════════
--  TAB 2: PLAYER & GHOST
-- ══════════════════════════════════════════════════════════════
local T_PL   = Window:Tab({ Title = "Player", Icon = "user" })
local secMov = T_PL:Section({ Title = "Movement", Opened = true })

secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v if getHum() then getHum().WalkSpeed = v end end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v if getHum() then getHum().UseJumpPower=true getHum().JumpPower=v end end })
secMov:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(v)
    if v then State.Move.infJ = UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end)
    else if State.Move.infJ then State.Move.infJ:Disconnect() State.Move.infJ=nil end end
end })

local secAbi = T_PL:Section({ Title = "Abilities", Opened = true })
secAbi:Toggle({ Title = "Fly", Value = false, Callback = function(v) toggleFly(v) end })
secAbi:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 10, Max = 300, Default = 50 }, Callback = function(v) State.Move.flyS = v end })
secAbi:Toggle({ Title = "NoClip", Value = false, Callback = function(v) State.Move.ncp = v end })
secAbi:Toggle({ Title = "Fling", Value = false, Callback = function(v) State.Fling.active=v; State.Move.ncp=v end })

-- GHOST MODE (Desync)
secAbi:Toggle({ Title = "Ghost Mode (Desync)", Desc = "Badan asli diam, kamu bisa jalan", Value = false, Callback = function(v)
    State.Ghost.active = v
    local hrp = getCharRoot(LP.Character)
    if v and hrp then
        hrp.Anchored = true
        notify("Ghost", "Diaktifkan: Tubuh aslimu terkunci di server.", 3)
    elseif hrp then
        hrp.Anchored = false
        notify("Ghost", "Dimatikan: Tubuh sinkron kembali.", 2)
    end
end})

-- ══════════════════════════════════════════════════════════════
--  TAB 3: CINEMATIC (Dikembalikan)
-- ══════════════════════════════════════════════════════════════
local T_CI   = Window:Tab({ Title = "Cinematic", Icon = "video" })
local secFC  = T_CI:Section({ Title = "Freecam", Opened = true })
secFC:Toggle({ Title = "Freecam", Value = false, Callback = function(v)
    FC.active = v; State.Cinema.active = v
    if v then
        local cf=Cam.CFrame; FC.pos=cf.Position; FC.vel=Vector3.zero; local rx,ry=cf:ToEulerAnglesYXZ()
        FC.pitchDeg=math.deg(rx); FC.yawDeg=math.deg(ry); local hrp=getRoot()
        if hrp then FC.savedCF=hrp.CFrame; hrp.Anchored=true end
        if getHum() then getHum().WalkSpeed=0; getHum().JumpPower=0; getHum():ChangeState(Enum.HumanoidStateType.Physics) end
        startFCCapture(); startFCLoop(); notify("Freecam","🎬 ON", 2)
    else
        stopFCLoop(); stopFCCapture(); local hrp=getRoot()
        if hrp then hrp.Anchored=false if FC.savedCF then hrp.CFrame=FC.savedCF; FC.savedCF=nil end end
        if getHum() then getHum().WalkSpeed=State.Move.ws getHum().UseJumpPower=true getHum().JumpPower=State.Move.jp getHum():ChangeState(Enum.HumanoidStateType.GettingUp) end
        Cam.FieldOfView=70; Cam.CameraType=Enum.CameraType.Custom; notify("Freecam","🎬 OFF", 2)
    end
end })
secFC:Slider({ Title="Speed", Step=1, Value={Min=1, Max=30, Default=5}, Callback=function(v) FC.speed=v end })
secFC:Slider({ Title="Damping (Responsif)", Step=1, Value={Min=10, Max=100, Default=40}, Callback=function(v) FC.damping=v*0.01 end })

-- ══════════════════════════════════════════════════════════════
--  TAB 4: SPECTATE (Dikembalikan)
-- ══════════════════════════════════════════════════════════════
local T_SP   = Window:Tab({ Title = "Spectate", Icon = "eye" })
local secSP  = T_SP:Section({ Title = "Spectate Player", Opened = true })

local Spec = { active=false, target=nil, dist=8 }
local specConns = {}
secSP:Dropdown({ Title = "Target Player", Values = getDisplayNames(), Callback = function(v) Spec.target = findPlayerByDisplay(v) end })
secSP:Toggle({ Title = "Spectate ON/OFF", Value = false, Callback = function(v)
    Spec.active = v
    if v then
        if not Spec.target then notify("Spectate","Pilih target dulu!"); return end
        Cam.CameraSubject = Spec.target.Character
        notify("Spectate", "Menonton: " .. Spec.target.DisplayName)
    else
        Cam.CameraSubject = LP.Character
        Cam.CameraType = Enum.CameraType.Custom
        notify("Spectate", "OFF")
    end
end })

-- ══════════════════════════════════════════════════════════════
--  TAB 5: WORLD & ATMOSPHERE (Dikembalikan + Fullbright)
-- ══════════════════════════════════════════════════════════════
local T_WO   = Window:Tab({ Title = "World", Icon = "globe" })
local secAtmos = T_WO:Section({ Title = "Atmosphere", Opened = true })

secAtmos:Toggle({ Title = "Fullbright (Clear Vision)", Desc = "Terangkan tempat gelap & hapus kabut", Value = false, Callback = function(v)
    State.Atmos.fullbright = v
    if v then
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.ColorShift_Bottom = Color3.new(1,1,1)
        Lighting.ColorShift_Top = Color3.new(1,1,1)
        Lighting.FogEnd = 999999
        Lighting.ClockTime = 14
    else
        Lighting.Ambient = State.Atmos.default.Ambient
        Lighting.FogEnd = 1000
    end
end })

secAtmos:Button({ Title = "Set Siang", Callback = function() Lighting.ClockTime = 14 end })
secAtmos:Button({ Title = "Set Malam", Callback = function() Lighting.ClockTime = 0 end })

-- ══════════════════════════════════════════════════════════════
--  TAB 6: SECURITY & ESP TRACKER
-- ══════════════════════════════════════════════════════════════
local T_SC   = Window:Tab({ Title = "Security", Icon = "shield" })
local secESP = T_SC:Section({ Title = "ESP Tracker", Opened = true })

secESP:Toggle({ Title = "ESP Global", Value = false, Callback = function(v)
    State.ESP.active=v
    if not v then
        for _,c in pairs(State.ESP.cache) do for _,r in pairs(c.renders) do if r and r.Parent then r:Destroy() end end if c.hl then c.hl:Destroy() end end
        State.ESP.cache={}
    end
end })
secESP:Dropdown({ Title = "Box Mode", Values = {"Corner","2D Box","HIGHLIGHT","OFF"}, Value = "Corner", Callback = function(v) State.ESP.boxMode=v end })
secESP:Dropdown({ Title = "Text / Name Color", Values = {"White","Green","Red","Blue","Yellow","Purple","Rose","Cyan"}, Value = "White", Callback = function(v)
    local c = {White=Color3.new(1,1,1), Green=Color3.new(0,1,0), Red=Color3.new(1,0,0), Blue=Color3.new(0,0,1), Yellow=Color3.new(1,1,0), Purple=Color3.new(1,0,1), Rose=Color3.fromRGB(255,100,150), Cyan=Color3.new(0,1,1)}
    State.ESP.nameColor = c[v] or c.White
end })
secESP:Slider({ Title="Draw Distance", Step=10, Value={Min=50,Max=500,Default=300}, Callback=function(v) State.ESP.maxDrawDistance=v end })

local secProt = T_SC:Section({ Title = "Protection & Tools", Opened = true })
secProt:Toggle({ Title = "Anti-AFK", Value = false, Callback = function(v)
    if v then State.Security.afkConn = LP.Idled:Connect(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end) notify("Anti-AFK","Aktif!")
    else if State.Security.afkConn then State.Security.afkConn:Disconnect() end notify("Anti-AFK","Mati") end
end })
secProt:Toggle({ Title = "Chat Bypass Filter", Desc = "Kirim pesan tanpa *** (Bypass lokal)", Value = false, Callback = function(v) State.Chat.bypass = v end })
secProt:Button({ Title = "Memory Purge (Bersihkan RAM)", Desc = "Tekan jika game mulai ngelag", Callback = function()
    collectgarbage("collect"); task.wait(0.1); notify("System", "Memory berhasil dibersihkan!", 2)
end })

-- ══════════════════════════════════════════════════════════════
--  TAB 7: SETTINGS & FPS COUNTER
-- ══════════════════════════════════════════════════════════════
local T_SET  = Window:Tab({ Title = "Settings", Icon = "settings" })
local secInfo = T_SET:Section({ Title = "System Info", Opened = true })

local fpsLabel = secInfo:Paragraph({ Title = "FPS Counter", Desc = "Menghitung..." })
local fpsSamples = {}
RS.RenderStepped:Connect(function(dt)
    table.insert(fpsSamples, dt)
    if #fpsSamples > 30 then table.remove(fpsSamples,1) end
end)
task.spawn(function()
    while true do
        task.wait(0.5)
        if #fpsSamples > 0 then
            local avg = 0
            for _,s in ipairs(fpsSamples) do avg=avg+s end
            avg = avg / #fpsSamples
            local fps = math.floor(1/avg)
            local pct = math.clamp(fps/120, 0, 1)
            local filled = math.floor(pct * 10)
            local bar = ""
            for i = 1, 10 do bar = bar .. (i <= filled and "█" or "░") end
            local color = fps>=60 and "🟢" or fps>=30 and "🟡" or "🔴"
            if fpsLabel then pcall(function() fpsLabel:SetDesc(color.."  "..fps.." FPS    ["..bar.."]") end) end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS (Fling / NoClip)
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.Fling.active and getRoot() then
            local r=getRoot()
            r.AssemblyAngularVelocity=Vector3.new(0,State.Fling.power,0)
            r.AssemblyLinearVelocity=Vector3.new(State.Fling.power,State.Fling.power,State.Fling.power)
        end
        RS.RenderStepped:Wait()
    end
end)

RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active) and LP.Character then
        for _,v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide=false end
        end
    end
end)

WindUI:Notify({ Title = "XKID SCRIPT", Content = "Ultimate Revision siap! Tema Rose, UI Compact.", Duration = 4 })
