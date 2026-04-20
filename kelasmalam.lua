--[[
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      ██╗  ██╗██╗  ██╗██╗██████╗     ███████╗ ██████╗           ║
║      ╚██╗██╔╝██║ ██╔╝██║██╔══██╗    ██╔════╝██╔════╝           ║
║       ╚███╔╝ █████╔╝ ██║██║  ██║    ███████╗██║                 ║
║       ██╔██╗ ██╔═██╗ ██║██║  ██║    ╚════██║██║                 ║
║      ██╔╝ ██╗██║  ██╗██║██████╔╝    ███████║╚██████╗            ║
║      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═════╝     ╚══════╝ ╚═════╝           ║
║                                                                  ║
║                  P R E M I U M   E D I T I O N                  ║
║                     Powered by WindUI                            ║
╚══════════════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════════════════════════════
--  0. AUTO CLEANUP & MEMORY PLUG (GARBAGE COLLECTION)
-- ══════════════════════════════════════════════════════════════
if getgenv()._XKID_CLEANUP then
    pcall(function() getgenv()._XKID_CLEANUP() end)
end

getgenv()._XKID_CONNS = {}
getgenv()._XKID_CLEANUP = function()
    for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end
    -- WindUI auto-clears on new instance, but forcing CoreGui cleanup ensures zero overlap
    for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
        if v.Name == "WindUI" or v.Name == "_XKIDEsp" then v:Destroy() end
    end
    collectgarbage("collect")
end

local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

-- ══════════════════════════════════════════════════════════════
--  LOAD
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
--  STATE
-- ══════════════════════════════════════════════════════════════
local State = {
    Move     = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly      = { active = false, bv = nil, bg = nil },
    Fling    = { active = false, power = 1000000 },
    SoftFling= { active = false, power = 4000 },
    Teleport = { selectedTarget = "" },
    Security = { afkConn = nil, antiFilter = false },
    Cinema   = { active = false },
    Spectate = { }, -- hideName removed
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
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end

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

local function getCharRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
end

local function notify(title, content, dur)
    WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 })
end

-- Persistent stats on respawn
TrackC(LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then
            hum.UseJumpPower = true
            hum.JumpPower    = State.Move.jp
        end
    end
end))

-- ══════════════════════════════════════════════════════════════
--  COMMAND ENGINE (:re) & ANTI-CHAT FILTER (HOOK)
-- ══════════════════════════════════════════════════════════════
TrackC(LP.Chatted:Connect(function(msg)
    local cmd = string.lower(msg)
    if cmd == ":re" or cmd == "/re" then
        local r = getRoot()
        local h = getHum()
        if r and h then
            local savedCF = r.CFrame
            h.Health = 0
            task.spawn(function()
                local char = LP.CharacterAdded:Wait()
                task.wait(0.3)
                local hrp = char:WaitForChild("HumanoidRootPart", 5)
                if hrp then hrp.CFrame = savedCF; notify("Command", "✅ Respawned!", 2) end
            end)
        end
    end
end))

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if State.Security.antiFilter and not checkcaller() then
        if method == "FireServer" and self.Name == "SayMessageRequest" and type(args[1]) == "string" then
            local res = ""
            for i=1, #args[1] do res = res .. string.sub(args[1],i,i) .. "\226\128\140" end
            args[1] = res
            return oldNamecall(self, unpack(args))
        elseif method == "SendAsync" and self.ClassName == "TextChannel" and type(args[1]) == "string" then
            local res = ""
            for i=1, #args[1] do res = res .. string.sub(args[1],i,i) .. "\226\128\140" end
            args[1] = res
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- ══════════════════════════════════════════════════════════════
--  ESP ENGINE
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
        for _, pair in ipairs({{tl, tl+Vector2.new(L,0)}, {tl, tl+Vector2.new(0,L)},{tr, tr-Vector2.new(L,0)}, {tr, tr+Vector2.new(0,L)},{bl, bl+Vector2.new(L,0)}, {bl, bl-Vector2.new(0,L)},{br, br-Vector2.new(L,0)}, {br, br-Vector2.new(0,L)},}) do
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
            if p.Size.X > 15 or p.Size.Y > 15 or p.Size.Z > 15 then return true end
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

    if not State.ESP.cache[player] then State.ESP.cache[player] = { renders = {}, hl = nil } end
    local cache = State.ESP.cache[player]

    for _, r in pairs(cache.renders) do if r and r.Parent then r:Destroy() end end
    cache.renders = {}

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

    if State.ESP.tracerMode ~= "OFF" then
        local sp, on = w2s(hrp.Position - Vector3.new(0, 2.5, 0))
        if on then
            local origin
            if State.ESP.tracerMode == "Bottom" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
            elseif State.ESP.tracerMode == "Center" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
            elseif State.ESP.tracerMode == "Mouse"  then local m = UIS:GetMouseLocation(); origin = Vector2.new(m.X, m.Y) end
            if origin then
                local l = drawLine(origin, sp, 1.5, tracerCol)
                if l then table.insert(cache.renders, l) end
            end
        end
    end

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

TrackC(RS.RenderStepped:Connect(function()
    if State.ESP.active then for _, p in pairs(Players:GetPlayers()) do renderESP(p) end end
end))

TrackC(Players.PlayerRemoving:Connect(function(p)
    local c = State.ESP.cache[p]
    if c then
        for _, r in pairs(c.renders) do if r and r.Parent then r:Destroy() end end
        if c.hl then c.hl:Destroy() end
        State.ESP.cache[p] = nil
    end
end))

-- ══════════════════════════════════════════════════════════════
--  FLY ENGINE
-- ══════════════════════════════════════════════════════════════
local flyMoveTouch, flyMoveSt = nil, nil
local flyJoy   = Vector2.zero
local flyConns = {}

local function startFlyCapture()
    local keysHeld = {}
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode
        if k==Enum.KeyCode.W or k==Enum.KeyCode.A or k==Enum.KeyCode.S or k==Enum.KeyCode.D or k==Enum.KeyCode.E or k==Enum.KeyCode.Q then keysHeld[k] = true end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp) keysHeld[inp.KeyCode] = false end))
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
    flyConns={}; flyMoveTouch=nil; flyMoveSt=nil; flyJoy=Vector2.zero; State.Fly._keys={}
end

local function toggleFly(v)
    if not v then
        State.Fly.active = false
        stopFlyCapture()
        RS:UnbindFromRenderStep("XKIDFly")
        if State.Fly.bv then State.Fly.bv:Destroy(); State.Fly.bv=nil end
        if State.Fly.bg then State.Fly.bg:Destroy(); State.Fly.bg=nil end
        local hum = getHum()
        if hum then hum.PlatformStand=false; hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.WalkSpeed=State.Move.ws; hum.UseJumpPower=true; hum.JumpPower=State.Move.jp end
        notify("Fly","✈ Fly OFF")
        return
    end
    local hrp=getRoot(); local hum=getHum()
    if not hrp or not hum then return end
    State.Fly.active=true; hum.PlatformStand=true
    State.Fly.bv=Instance.new("BodyVelocity",hrp)
    State.Fly.bv.MaxForce=Vector3.new(9e9,9e9,9e9); State.Fly.bv.Velocity=Vector3.zero
    State.Fly.bg=Instance.new("BodyGyro",hrp)
    State.Fly.bg.MaxTorque=Vector3.new(9e9,9e9,9e9); State.Fly.bg.P=1e5
    startFlyCapture()
    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value+1, function()
        if not State.Fly.active then return end
        local r=getRoot(); if not r then return end
        local camCF=Cam.CFrame
        local spd=State.Move.flyS
        local move=Vector3.zero
        local keys=State.Fly._keys or {}
        if onMobile then
            move = camCF.LookVector*(-flyJoy.Y)*spd + camCF.RightVector*flyJoy.X*spd
        else
            if keys[Enum.KeyCode.W] then move=move+camCF.LookVector  end
            if keys[Enum.KeyCode.S] then move=move-camCF.LookVector  end
            if keys[Enum.KeyCode.D] then move=move+camCF.RightVector end
            if keys[Enum.KeyCode.A] then move=move-camCF.RightVector end
            if keys[Enum.KeyCode.E] then move=move+Vector3.new(0,1,0) end
            if keys[Enum.KeyCode.Q] then move=move-Vector3.new(0,1,0) end
            if move.Magnitude>0 then move=move.Unit*spd end
        end
        State.Fly.bv.Velocity = move
        State.Fly.bg.CFrame   = CFrame.new(r.Position, r.Position+camCF.LookVector)
    end)
    notify("Fly","✈ Fly ON", 3)
end

-- ══════════════════════════════════════════════════════════════
--  FREECAM ENGINE (Smooth + Mobile)
-- ══════════════════════════════════════════════════════════════
local FC = { active=false, pos=Vector3.zero, vel=Vector3.zero, pitchDeg=0, yawDeg=0, speed=1, sens=0.25, savedCF=nil, damping=0.40, accel=0.50 }
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
        local half=Cam.ViewportSize.X/2
        if inp.Position.X>half then if not fcRotT then fcRotT=inp; fcRotLast=inp.Position end
        else if not fcMoveT then fcMoveT=inp; fcMoveSt=inp.Position end end
    end))
    table.insert(fcConns, UIS.TouchMoved:Connect(function(inp)
        if inp==fcRotT and fcRotLast then
            FC.yawDeg   = FC.yawDeg  -(inp.Position.X-fcRotLast.X)*FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg-(inp.Position.Y-fcRotLast.Y)*FC.sens,-80,80)
            fcRotLast=inp.Position
        end
        if inp==fcMoveT and fcMoveSt then
            local dx=inp.Position.X-fcMoveSt.X
            local dy=inp.Position.Y-fcMoveSt.Y
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
        local spd=FC.speed*32
        local dv=Vector3.zero
        local keys=FC._keys or {}
        if onMobile then dv=cf.LookVector*(-fcJoy.Y)*spd + cf.RightVector*fcJoy.X*spd else
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
        if hum then
            if hum:GetState()~=Enum.HumanoidStateType.Physics then hum:ChangeState(Enum.HumanoidStateType.Physics) end
            hum.WalkSpeed=0; hum.JumpPower=0
        end
    end)
end

local function stopFCLoop() RS:UnbindFromRenderStep("XKIDFreecam") end

-- ══════════════════════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title       = "XKID SCRIPT V2",
    Author      = "by XKID",
    Folder      = "XKIDScript",
    Icon        = "shield",
    Theme       = "Rose",
    Acrylic     = true,
    Transparent = true,
    Size        = UDim2.fromOffset(700, 480),
    MinSize     = Vector2.new(560, 380),
    MaxSize     = Vector2.new(860, 580),
    ToggleKey   = Enum.KeyCode.RightShift,
    Resizable   = true,
    AutoScale   = true,
    NewElements = true,
    SideBarWidth= 200,
    Topbar = { Height = 44, ButtonsType = "Default" },
    OpenButton  = { Title="XKID", Icon="shield", CornerRadius=UDim.new(1,0), StrokeThickness=3, Enabled=true, Draggable=true, OnlyMobile=false, Scale=1, Color=ColorSequence.new(Color3.fromHex("#00FFA3"),Color3.fromHex("#0096FF")) },
    User = { Enabled=true, Anonymous=false, Callback=function() notify("XKID SCRIPT","Premium Edition — by XKID", 3) end },
})

WindUI:SetTheme("Rose")

-- ══════════════════════════════════════════════════════════════
--  TAB: TELEPORT
-- ══════════════════════════════════════════════════════════════
local T_TP   = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local secTP  = T_TP:Section({ Title = "Quick Teleport", Opened = true })

local tpTarget = ""
secTP:Input({ Title="Search Player", Desc="Ketik nama atau 2-3 huruf", Placeholder="nama player...", Callback=function(v) tpTarget = v end })
secTP:Button({
    Title="Teleport", Desc="Teleport ke player yang dicari",
    Callback=function()
        if tpTarget == "" then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                local nl = string.lower(p.Name)
                local dl = string.lower(p.DisplayName)
                local tl = string.lower(tpTarget)
                if (string.find(nl,tl) or string.find(dl,tl)) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    getRoot().CFrame = p.Character.HumanoidRootPart.CFrame
                    notify("Teleport","✅ TP ke "..p.DisplayName, 2)
                    return
                end
            end
        end
        notify("Teleport","❌ Player tidak ditemukan", 2)
    end,
})

local pDropOpts = getPNames()
secTP:Dropdown({ Title="Player List", Desc="Pilih dari daftar", Values=pDropOpts, Callback=function(v) tpTarget = v end })
secTP:Button({ Title="Refresh List", Desc="Perbarui daftar player", Callback=function() pDropOpts=getPNames(); notify("Teleport","Daftar diperbarui!", 2) end })

local secLoc = T_TP:Section({ Title = "Save & Load Location", Opened = true })
local SavedLocs = {}

for i = 1, 5 do
    secLoc:Button({ Title="Save Slot "..i, Desc="Simpan posisi sekarang", Callback=function()
        local r = getRoot()
        if not r then notify("Location","❌ Karakter tidak ditemukan"); return end
        SavedLocs[i] = r.CFrame; notify("Location","💾 Slot "..i.." tersimpan!", 2)
    end})
end
for i = 1, 5 do
    secLoc:Button({ Title="Load Slot "..i, Desc="Teleport ke lokasi slot "..i, Callback=function()
        if not SavedLocs[i] then notify("Location","❌ Slot "..i.." kosong!"); return end
        local r = getRoot(); if not r then return end
        r.CFrame = SavedLocs[i]; notify("Location","📍 Teleport ke Slot "..i, 2)
    end})
end

-- ══════════════════════════════════════════════════════════════
--  TAB: PLAYER (ATMOSPHERE REMOVED)
-- ══════════════════════════════════════════════════════════════
local T_PL   = Window:Tab({ Title = "Player", Icon = "user" })

local secMov = T_PL:Section({ Title = "Movement", Opened = true })
secMov:Button({ Title="Refresh POV", Desc="Reset kamera & karakter", Callback=function()
    local r=getRoot(); local h=getHum()
    if not r or not h then notify("Refresh","❌ Karakter tidak ditemukan"); return end
    Cam.CameraType=Enum.CameraType.Custom; task.wait(0.05); Cam.CameraType=Enum.CameraType.Scriptable; task.wait(0.05); Cam.CameraType=Enum.CameraType.Custom
    pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    notify("Refresh","✅ POV & kamera di-reset!", 2)
end})
secMov:Slider({ Title="Walk Speed", Step=1, Value={Min=16,Max=500,Default=16}, Callback=function(v) State.Move.ws=v; if getHum() then getHum().WalkSpeed=v end end })
secMov:Slider({ Title="Jump Power", Step=1, Value={Min=50,Max=500,Default=50}, Callback=function(v) State.Move.jp=v; local h=getHum(); if h then h.UseJumpPower=true; h.JumpPower=v end end })
secMov:Toggle({ Title="Infinite Jump", Desc="Lompat terus menerus", Value=false, Callback=function(v)
    if v then State.Move.infJ = TrackC(UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end))
    else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ=nil end end
end})

local secAbi = T_PL:Section({ Title = "Abilities", Opened = true })
secAbi:Toggle({ Title="Fly", Desc="Terbang mengikuti arah kamera", Value=false, Callback=function(v) toggleFly(v) end })
secAbi:Slider({ Title="Fly Speed", Step=1, Value={Min=10,Max=300,Default=60}, Callback=function(v) State.Move.flyS=v end })
secAbi:Toggle({ Title="NoClip", Desc="Tembus dinding", Value=false, Callback=function(v) State.Move.ncp=v end })
secAbi:Toggle({ Title="IY Fling (Brutal)", Desc="Fling kencang + noclip", Value=false, Callback=function(v) State.Fling.active=v; State.Move.ncp=v end })
secAbi:Toggle({ Title="Soft Fling", Desc="Fling pelan (jatuh)", Value=false, Callback=function(v) State.SoftFling.active=v; State.Move.ncp=v end })

local noFallConn = nil
secAbi:Toggle({ Title="No Fall Damage", Desc="Anti mati saat jatuh tinggi", Value=false, Callback=function(v)
    if v then noFallConn = TrackC(RS.Heartbeat:Connect(function() local hrp=getRoot(); if hrp and hrp.Velocity.Y < -30 then hrp.Velocity=Vector3.new(hrp.Velocity.X,-10,hrp.Velocity.Z) end end))
    else if noFallConn then noFallConn:Disconnect(); noFallConn=nil end end
end})

local godConn,godRespConn,godLastPos = nil,nil,nil
secAbi:Toggle({ Title="God Mode", Desc="HP Infinite + Auto Respawn ke posisi terakhir", Value=false, Callback=function(v)
    if v then
        local hum=getHum(); if hum then hum.MaxHealth=math.huge; hum.Health=math.huge end
        godLastPos  = getRoot() and getRoot().CFrame
        godRespConn = TrackC(RS.Heartbeat:Connect(function() local r=getRoot(); if r then godLastPos=r.CFrame end end))
        godConn = TrackC(RS.Heartbeat:Connect(function() local h=getHum(); if h then if h.Health<h.MaxHealth then h.Health=h.MaxHealth end; if h.MaxHealth~=math.huge then h.MaxHealth=math.huge end end end))
        notify("God Mode","🛡 HP Infinite aktif!", 3)
    else
        if godConn then godConn:Disconnect(); godConn=nil end
        if godRespConn then godRespConn:Disconnect(); godRespConn=nil end
        local hum=getHum(); if hum then hum.MaxHealth=100; hum.Health=100 end
        notify("God Mode","❌ Nonaktif", 2)
    end
end})

local secLock = T_PL:Section({ Title = "Shift Lock", Opened = false })
local shiftConn = nil
secLock:Toggle({ Title="Shift Lock", Desc="Karakter selalu hadap kamera", Value=false, Callback=function(v)
    local hum=getHum(); local hrp=getRoot()
    if not hum or not hrp then notify("Shift Lock","❌ Karakter tidak ditemukan"); return end
    if v then
        hum.CameraOffset=Vector3.new(1.75,0,0); hum.AutoRotate=false
        shiftConn = TrackC(RS.RenderStepped:Connect(function() local r=getRoot(); if r then local cl=Cam.CFrame.LookVector; r.CFrame=CFrame.new(r.Position, r.Position+Vector3.new(cl.X,0,cl.Z)) end end))
        notify("Shift Lock","🎯 Aktif!", 2)
    else
        if shiftConn then shiftConn:Disconnect(); shiftConn=nil end
        local h=getHum(); if h then h.CameraOffset=Vector3.zero; h.AutoRotate=true end
        notify("Shift Lock","🔓 Nonaktif", 2)
    end
end})

-- ══════════════════════════════════════════════════════════════
--  TAB: CINEMATIC
-- ══════════════════════════════════════════════════════════════
local T_CI   = Window:Tab({ Title = "Cinematic", Icon = "video" })
local secFC  = T_CI:Section({ Title = "Freecam", Opened = true })

secFC:Toggle({ Title="Freecam", Desc="PC: RMB rotate | Mobile: Kiri gerak / Kanan rotate", Value=false, Callback=function(v)
    FC.active = v; State.Cinema.active = v
    if v then
        local cf=Cam.CFrame
        FC.pos=cf.Position; FC.vel=Vector3.zero
        local rx,ry=cf:ToEulerAnglesYXZ(); FC.pitchDeg=math.deg(rx); FC.yawDeg=math.deg(ry)
        FC._keys={}; FC._mouseRot=false
        local hrp=getRoot(); local hum=getHum()
        if hrp then FC.savedCF=hrp.CFrame; hrp.Anchored=true end
        if hum then hum.WalkSpeed=0; hum.JumpPower=0; hum:ChangeState(Enum.HumanoidStateType.Physics) end
        startFCCapture(); startFCLoop()
        notify("Freecam","🎬 ON — Kiri gerak | Kanan rotate", 3)
    else
        stopFCLoop(); stopFCCapture()
        local hrp=getRoot(); local hum=getHum()
        if hrp then hrp.Anchored=false; if FC.savedCF then hrp.CFrame=FC.savedCF; FC.savedCF=nil end end
        if hum then hum.WalkSpeed=State.Move.ws; hum.UseJumpPower=true; hum.JumpPower=State.Move.jp; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        Cam.FieldOfView=70; Cam.CameraType=Enum.CameraType.Custom
        notify("Freecam","🎬 OFF", 2)
    end
end})
secFC:Slider({ Title="Speed", Step=1, Value={Min=1,Max=30,Default=5}, Callback=function(v) FC.speed=v end })
secFC:Slider({ Title="Sensitivity", Step=1, Value={Min=1,Max=20,Default=5}, Callback=function(v) FC.sens=v*0.05 end })
secFC:Slider({ Title="Damping", Step=1, Value={Min=10,Max=100,Default=40}, Callback=function(v) FC.damping=v*0.01 end })
secFC:Slider({ Title="Acceleration", Step=1, Value={Min=5,Max=100,Default=50}, Callback=function(v) FC.accel=v*0.01 end })
secFC:Slider({ Title="FOV", Step=1, Value={Min=10,Max=120,Default=70}, Callback=function(v) Cam.FieldOfView=v end })

local secDisp = T_CI:Section({ Title = "Display", Opened = false })
secDisp:Button({ Title="Portrait", Callback=function() LP.PlayerGui.ScreenOrientation=Enum.ScreenOrientation.Portrait end })
secDisp:Button({ Title="Landscape", Callback=function() LP.PlayerGui.ScreenOrientation=Enum.ScreenOrientation.LandscapeRight end })

-- ══════════════════════════════════════════════════════════════
--  TAB: SPECTATE (HIDE NAME REMOVED)
-- ══════════════════════════════════════════════════════════════
local T_SP   = Window:Tab({ Title = "Spectate", Icon = "eye" })
local secSP  = T_SP:Section({ Title = "Spectate Player", Opened = true })

local function inJoystick(pos)
    local ctrl = LP and LP.PlayerGui and LP.PlayerGui:FindFirstChild("TouchGui")
    if ctrl then
        local frame = ctrl:FindFirstChild("TouchControlFrame")
        local thumb = frame and frame:FindFirstChild("DynamicThumbstickFrame")
        if thumb then
            local ap=thumb.AbsolutePosition; local as=thumb.AbsoluteSize
            if pos.X>=ap.X and pos.Y>=ap.Y and pos.X<=ap.X+as.X and pos.Y<=ap.Y+as.Y then return true end
        end
    end
    return false
end

local Spec = { active=false, target=nil, mode="third", dist=8, origFov=70, orbitYaw=0, orbitPitch=0, fpYaw=0, fpPitch=0 }
local specTM,specPinch,specPinchD = nil,{},nil
local specPan  = Vector2.zero
local specConns= {}

local function startSpecCapture()
    table.insert(specConns, UIS.InputBegan:Connect(function(inp,gp)
        if gp or not Spec.active then return end
        if inp.UserInputType~=Enum.UserInputType.Touch then return end
        if inJoystick(inp.Position) then return end
        table.insert(specPinch,inp)
        specTM = #specPinch==1 and inp or nil
    end))
    table.insert(specConns, UIS.InputChanged:Connect(function(inp)
        if not Spec.active then return end
        if inp.UserInputType~=Enum.UserInputType.Touch then return end
        if #specPinch==1 and inp==specTM then
            specPan = specPan+Vector2.new(inp.Delta.X,inp.Delta.Y)
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
        specPinchD=nil
        specTM = #specPinch==1 and specPinch[1] or nil
    end))
end

local function stopSpecCapture()
    for _,c in ipairs(specConns) do c:Disconnect() end
    specConns={}; specTM=nil; specPinch={}; specPinchD=nil; specPan=Vector2.zero
end

local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value+1, function()
        if not Spec.active then return end
        Cam.CameraType=Enum.CameraType.Scriptable
        local char=Spec.target and Spec.target.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local pan=specPan; specPan=Vector2.zero; local sens=0.3
        if Spec.mode=="third" then
            Spec.orbitYaw   = Spec.orbitYaw+pan.X*sens
            Spec.orbitPitch = math.clamp(Spec.orbitPitch+pan.Y*sens,-75,75)
            local oCF = CFrame.new(hrp.Position) * CFrame.Angles(0,math.rad(-Spec.orbitYaw),0) * CFrame.Angles(math.rad(-Spec.orbitPitch),0,0) * CFrame.new(0,0,Spec.dist)
            Cam.CFrame=CFrame.new(oCF.Position, hrp.Position+Vector3.new(0,1,0))
        else
            local head=char:FindFirstChild("Head")
            local origin=head and head.Position or hrp.Position+Vector3.new(0,1.5,0)
            Spec.fpYaw  = Spec.fpYaw-pan.X*sens
            Spec.fpPitch= math.clamp(Spec.fpPitch-pan.Y*sens,-85,85)
            Cam.CFrame  = CFrame.new(origin) * CFrame.Angles(0,math.rad(Spec.fpYaw),0) * CFrame.Angles(math.rad(Spec.fpPitch),0,0)
        end
    end)
end

local function stopSpecLoop() RS:UnbindFromRenderStep("XKIDSpec") end

local specDropOpts = getDisplayNames()
secSP:Dropdown({ Title="Target Player", Values=specDropOpts, Callback=function(v)
    local p=findPlayerByDisplay(v)
    if p then
        Spec.target=p
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local _,ry,_=p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ()
            Spec.orbitYaw=math.deg(ry); Spec.orbitPitch=20; Spec.fpYaw=math.deg(ry); Spec.fpPitch=0
        end
    end
end})
secSP:Button({ Title="Refresh List", Callback=function() Spec.target=nil; specDropOpts=getDisplayNames(); notify("Spectate","Daftar diperbarui!", 2) end })
secSP:Toggle({ Title="Spectate ON / OFF", Value=false, Callback=function(v)
    Spec.active=v
    if v then
        if not Spec.target then notify("Spectate","Pilih target dulu!", 3); Spec.active=false; return end
        Spec.origFov=Cam.FieldOfView
        startSpecCapture(); startSpecLoop()
        notify("Spectate","👁 Menonton: "..Spec.target.DisplayName, 3)
    else
        stopSpecLoop(); stopSpecCapture()
        Cam.CameraType=Enum.CameraType.Custom; Cam.FieldOfView=Spec.origFov
        notify("Spectate","Spectate off", 2)
    end
end})
secSP:Toggle({ Title="First Person Mode", Value=false, Callback=function(v)
    Spec.mode=v and "first" or "third"
    if v and Spec.target and Spec.target.Character then
        local _,ry,_=Cam.CFrame:ToEulerAnglesYXZ()
        local rx=math.asin(Cam.CFrame.LookVector.Y)
        Spec.fpYaw=math.deg(ry); Spec.fpPitch=math.deg(rx)
    end
end})
secSP:Slider({ Title="Orbit Distance", Step=1, Value={Min=3,Max=30,Default=8}, Callback=function(v) Spec.dist=v end })

-- ══════════════════════════════════════════════════════════════
--  TAB: WORLD
-- ══════════════════════════════════════════════════════════════
local T_WO   = Window:Tab({ Title = "World", Icon = "globe" })
local function getAtm() return Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",Lighting) end
local function setWeather(c,b,fs,fe,fr,fg,fb,ar,ag,ab,d,o,gl,h)
    Lighting.ClockTime=c; Lighting.Brightness=b; Lighting.FogStart=fs; Lighting.FogEnd=fe; Lighting.FogColor=Color3.fromRGB(fr,fg,fb); Lighting.Ambient=Color3.fromRGB(ar,ag,ab)
    local atm=getAtm(); atm.Density=d; atm.Offset=o; atm.Glare=gl; atm.Halo=h
end

local secWea = T_WO:Section({ Title = "Weather Presets", Opened = true })
secWea:Button({ Title="☀ Cerah", Callback=function() setWeather(14,2,1000,10000,200,220,255,120,120,120,0.05,0.1,0.3,0.2); notify("Weather","☀ Cerah!",2) end })
secWea:Button({ Title="🌃 Malam Bintang", Callback=function() setWeather(0,0.3,2000,20000,10,10,30,20,20,40,0.02,0,0,0.1); notify("Weather","🌃 Malam Bintang!",2) end })
secWea:Button({ Title="↺ Reset Default", Callback=function() setWeather(14,1,0,100000,191,191,191,70,70,70,0.35,0,0,0.25); notify("Weather","↺ Reset!",2) end })

-- ══════════════════════════════════════════════════════════════
--  TAB: SECURITY (WITH ANTI-CHAT FILTER MODULE)
-- ══════════════════════════════════════════════════════════════
local T_SC   = Window:Tab({ Title = "Security", Icon = "shield" })

local secProt = T_SC:Section({ Title = "Protection & Chat", Opened = true })
secProt:Toggle({ Title="Anti Chat Filter (Pro 2026)", Desc="Bypass tags (####) menggunakan ZWS Obfuscation", Value=false, Callback=function(v) State.Security.antiFilter = v end })
secProt:Toggle({ Title="Anti-AFK", Desc="Cegah kick saat AFK", Value=false, Callback=function(v)
    if v then
        State.Security.afkConn = TrackC(LP.Idled:Connect(function()
            VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); VirtualUser:Button2Down(Vector2.new(0,0),Cam.CFrame); task.wait(1); VirtualUser:Button2Up(Vector2.new(0,0),Cam.CFrame)
        end))
        pcall(function() for _,conn in pairs(getconnections(LP.Idled)) do conn:Disable() end end)
        notify("Anti-AFK","🛡 Bypass aktif!", 2)
    else
        if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn=nil end
        pcall(function() for _,conn in pairs(getconnections(LP.Idled)) do conn:Enable() end end)
        notify("Anti-AFK","❌ Nonaktif", 2)
    end
end})
secProt:Button({ Title="Rejoin Server", Callback=function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end })

local secResp = T_SC:Section({ Title = "Fast Respawn & Commands", Opened = true })
local respawnLastPos = nil
task.spawn(function()
    while true do
        task.wait(1)
        local r=getRoot(); local h=getHum()
        if r and h and h.Health>0 then respawnLastPos=r.CFrame end
    end
end)
secResp:Button({ Title="Fast Respawn", Desc="Mati & kembali ke posisi terakhir", Callback=function()
    if not respawnLastPos then notify("Respawn","❌ Posisi belum direkam!"); return end
    local savedCF=respawnLastPos; local hum=getHum()
    if not hum then return end
    hum.Health=0
    task.spawn(function()
        local char=LP.CharacterAdded:Wait(); task.wait(0.3)
        local hrp=char:WaitForChild("HumanoidRootPart",10)
        if hrp then hrp.CFrame=savedCF; notify("Respawn","✅ Kembali ke posisi terakhir!", 3) end
    end)
end})

-- ESP Tracker
local secESP = T_SC:Section({ Title = "ESP Tracker", Opened = true })
secESP:Toggle({ Title="ESP ON / OFF", Value=false, Callback=function(v)
    State.ESP.active=v
    if not v then
        for _,c in pairs(State.ESP.cache) do
            for _,r in pairs(c.renders) do if r and r.Parent then r:Destroy() end end
            if c.hl then c.hl:Destroy() end
        end
        State.ESP.cache={}
    end
    notify("ESP", v and "ESP ON" or "ESP OFF", 2)
end})

-- Performance
local secPerf = T_SC:Section({ Title = "Performance", Opened = false })
local antiLag = { mats={}, texs={}, shadows=true }
secPerf:Toggle({ Title="Anti Lag Mode", Value=false, Callback=function(v)
    if v then
        antiLag.shadows=Lighting.GlobalShadows; Lighting.GlobalShadows=false
        for _,obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then antiLag.mats[obj]=obj.Material; obj.Material=Enum.Material.SmoothPlastic
            elseif obj:IsA("Texture") or obj:IsA("Decal") then antiLag.texs[obj]=obj.Parent; obj.Parent=nil end
        end
        notify("Anti Lag","🚀 Aktif! Grafik diturunkan.", 3)
    else
        Lighting.GlobalShadows=antiLag.shadows
        for obj,mat in pairs(antiLag.mats) do if obj and obj.Parent then obj.Material=mat end end
        for obj,par in pairs(antiLag.texs) do if obj and par and par.Parent then obj.Parent=par end end
        antiLag.mats={}; antiLag.texs={}
        notify("Anti Lag","↺ Grafik kembali normal.", 3)
    end
end})

-- ══════════════════════════════════════════════════════════════
--  TAB: SETTINGS
-- ══════════════════════════════════════════════════════════════
local T_SET  = Window:Tab({ Title = "Settings", Icon = "settings" })
local secTheme = T_SET:Section({ Title = "Appearance", Opened = true })
secTheme:Dropdown({ Title="Theme", Values=(function() local names={}; for name in pairs(WindUI:GetThemes()) do table.insert(names,name) end; table.sort(names); return names end)(), Value="Rose", Callback=function(selected) WindUI:SetTheme(selected) end })

-- ══════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if (State.Fling.active or State.SoftFling.active) and getRoot() then
            local r=getRoot(); local brutal=State.Fling.active; local pwr=brutal and State.Fling.power or State.SoftFling.power
            local ok=pcall(function() r.AssemblyAngularVelocity=Vector3.new(0,pwr,0); if brutal then r.AssemblyLinearVelocity=Vector3.new(pwr,pwr,pwr) end end)
            if not ok then pcall(function() r.RotVelocity=Vector3.new(0,pwr,0); if brutal then r.Velocity=Vector3.new(pwr,pwr,pwr) end end) end
        end
        RS.RenderStepped:Wait()
    end
end)

TrackC(RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active or State.SoftFling.active) and LP.Character then
        for _,v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end
    end
end))

WindUI:SetNotificationLower(true)
WindUI:Notify({ Title = "XKID SCRIPT", Content = "Premium Edition V2 siap digunakan! 🚀", Duration = 5 })
