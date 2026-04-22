--[[
╔══════════════════════════════════════════════════════════════════╗
║                    @WTF.XKID - LUXURY SCRIPT                     ║
║                    Freecam = Fly-like movement                   ║
║                    Theme: CRIMSON | OpenButton: ⚡XKID HUB        ║
╚══════════════════════════════════════════════════════════════════╝
]]

local RS = game:GetService("RunService")

-- CLEANUP
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
        for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do if v.Name == "WindUI" then v:Destroy() end end
        if getgenv()._XKID_CONNS then for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end end
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

-- LOAD WINDUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TPService = game:GetService("TeleportService")
local StatsService = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local onMobile = not UIS.KeyboardEnabled

-- STATE
local State = {
    Move = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly = { active = false, bv = nil, bg = nil },
    Fling = { active = false, power = 1000000 },
    SoftFling = { active = false, power = 4000 },
    Teleport = { selectedTarget = "" },
    Security = { afkConn = nil },
    Cinema = { active = false },
    Spectate = { hideName = false },
    Avatar = { isRefreshing = false },
    Ghost = { active = false },
    Chat = { bypass = false },
    ESP = {
        active = false, cache = getgenv()._XKID_ESP_CACHE, boxMode = "Corner", tracerMode = "Bottom",
        maxDrawDistance = 300, showDistance = true, showNickname = true,
        boxColor_N = Color3.fromRGB(0, 255, 150), boxColor_S = Color3.fromRGB(220, 20, 60),
        tracerColor_N = Color3.fromRGB(0, 200, 255), tracerColor_S = Color3.fromRGB(220, 20, 60),
        nameColor = Color3.fromRGB(255, 255, 255),
    },
}

local colorMap = {
    Merah = Color3.fromRGB(255,0,0), Hijau = Color3.fromRGB(0,255,0), Biru = Color3.fromRGB(0,0,255),
    Kuning = Color3.fromRGB(255,255,0), Ungu = Color3.fromRGB(255,0,255), Cyan = Color3.fromRGB(0,255,255),
    Orange = Color3.fromRGB(255,165,0), Pink = Color3.fromRGB(255,105,180), Putih = Color3.fromRGB(255,255,255),
    Hitam = Color3.fromRGB(0,0,0), Crimson = Color3.fromRGB(220,20,60),
}

-- HELPERS
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getCharRoot(char) if not char then return nil end return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") end
local function notify(title, content, dur) WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 }) end

TrackC(LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
    end
end))

-- FAST RESPAWN
local function fastRespawn()
    if State.Avatar.isRefreshing then return end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = getRoot()
    if not hum or not hrp then notify("Fast Respawn", "Character not found!", 2) return end
    State.Avatar.isRefreshing = true
    notify("Fast Respawn", "Respawning...", 1.5)
    local savedCF = hrp.CFrame
    local savedCamCF = Cam.CFrame
    Cam.CameraType = Enum.CameraType.Scriptable
    Cam.CFrame = savedCamCF
    local charAddedConn
    charAddedConn = TrackC(LP.CharacterAdded:Connect(function(newChar)
        charAddedConn:Disconnect()
        local newHrp = newChar:WaitForChild("HumanoidRootPart", 5)
        local newHum = newChar:WaitForChild("Humanoid", 5)
        if not LP:HasAppearanceLoaded() then LP.CharacterAppearanceLoaded:Wait() end
        task.wait(0.2)
        if newHrp and newHum then
            newHrp.CFrame = savedCF + Vector3.new(0, 3, 0)
            newHrp.AssemblyLinearVelocity = Vector3.zero
            task.spawn(function() task.wait(0.05); if newHrp then newHrp.CFrame = savedCF + Vector3.new(0, 3, 0) end end)
            Cam.CameraSubject = newHum
            Cam.CameraType = Enum.CameraType.Custom
            notify("Success", "Fast Respawn!", 2)
        end
        State.Avatar.isRefreshing = false
    end))
    hum.Health = 0
    task.delay(5, function() State.Avatar.isRefreshing = false end)
end

-- CHAT COMMANDS
TrackC(LP.Chatted:Connect(function(msg)
    local lowerMsg = msg:lower()
    if lowerMsg == "/re" or lowerMsg == ";re" then fastRespawn() end
    if lowerMsg == "!rejoin" then TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end
end))

-- ESP ENGINE (simplified but working)
local function initPlayerCache(player)
    if State.ESP.cache[player] then return end
    local cache = {
        texts = Drawing.new("Text"), tracer = Drawing.new("Line"), boxLines = {},
        hl = nil, isSuspect = false, reason = ""
    }
    cache.texts.Center = true; cache.texts.Outline = true; cache.texts.Font = 2; cache.texts.Size = 13
    cache.tracer.Thickness = 1.5
    for i = 1, 4 do local line = Drawing.new("Line"); line.Thickness = 1.5; cache.boxLines[i] = line end
    State.ESP.cache[player] = cache
end
local function clearPlayerCache(player)
    local c = State.ESP.cache[player]
    if c then
        if c.texts then c.texts:Remove() end
        if c.tracer then c.tracer:Remove() end
        for _, l in ipairs(c.boxLines) do l:Remove() end
        if c.hl then c.hl:Destroy() end
        State.ESP.cache[player] = nil
    end
end
TrackC(Players.PlayerRemoving:Connect(clearPlayerCache))

task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if State.ESP.active then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local isSus = false; local reason = ""
                    for _, v in pairs(p.Character:GetChildren()) do
                        if v:IsA("BasePart") and (v.Size.X > 20 or v.Size.Y > 20 or v.Size.Z > 20) then isSus = true; reason = "Map Blocker" break end
                        if v:IsA("Accessory") then local h = v:FindFirstChild("Handle"); if h and h:IsA("BasePart") and (h.Size.Magnitude > 15) then isSus = true; reason = "Huge Hat" break end end
                    end
                    if not isSus then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local bws = hum:FindFirstChild("BodyWidthScale"); local bhs = hum:FindFirstChild("BodyHeightScale")
                            if (bws and bws.Value > 1.5) or (bhs and bhs.Value > 1.5) then isSus = true; reason = "Glitch Avatar" end
                        end
                    end
                    initPlayerCache(p)
                    State.ESP.cache[p].isSuspect = isSus
                    State.ESP.cache[p].reason = reason
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
                c.texts.Visible = false; c.tracer.Visible = false
                for _, l in ipairs(c.boxLines) do l.Visible = false end; if c.hl then c.hl.Enabled = false end
                continue
            end
            local rootPos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
            if not onScreen then
                c.texts.Visible = false; c.tracer.Visible = false
                for _, l in ipairs(c.boxLines) do l.Visible = false end; if c.hl then c.hl.Enabled = false end
                continue
            end
            local isSus = c.isSuspect
            local txt = ""
            if State.ESP.showNickname then txt = player.DisplayName end
            if State.ESP.showDistance then txt = txt .. "\n[" .. math.floor(dist) .. "m]" end
            if isSus then txt = txt .. "\n⚠ " .. c.reason .. " ⚠" end
            c.texts.Text = txt; c.texts.Color = isSus and State.ESP.boxColor_S or State.ESP.nameColor
            c.texts.Position = Vector2.new(rootPos.X, rootPos.Y - 45); c.texts.Visible = true
            if State.ESP.tracerMode ~= "OFF" or isSus then
                local origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
                if State.ESP.tracerMode == "Center" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
                elseif State.ESP.tracerMode == "Mouse" then local m = UIS:GetMouseLocation(); origin = Vector2.new(m.X, m.Y) end
                c.tracer.From = origin; c.tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                c.tracer.Color = isSus and State.ESP.tracerColor_S or State.ESP.tracerColor_N
                c.tracer.Visible = true
            else c.tracer.Visible = false end
            if isSus then
                local top = Cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)); local bot = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                local h = math.abs(top.Y - bot.Y); local w = h * 0.6
                local tl = Vector2.new(rootPos.X - w/2, top.Y); local tr = Vector2.new(rootPos.X + w/2, top.Y)
                local bl = Vector2.new(rootPos.X - w/2, bot.Y); local br = Vector2.new(rootPos.X + w/2, bot.Y)
                c.boxLines[1].From = tl; c.boxLines[1].To = tr; c.boxLines[2].From = tr; c.boxLines[2].To = br
                c.boxLines[3].From = br; c.boxLines[3].To = bl; c.boxLines[4].From = bl; c.boxLines[4].To = tl
                for i = 1, 4 do c.boxLines[i].Color = State.ESP.boxColor_S; c.boxLines[i].Visible = true end
                if not c.hl or c.hl.Parent ~= char then if c.hl then c.hl:Destroy() end; c.hl = Instance.new("Highlight", char); c.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end
                c.hl.FillColor = State.ESP.boxColor_S; c.hl.OutlineColor = Color3.new(1,1,1); c.hl.Enabled = true
            else for _, l in ipairs(c.boxLines) do l.Visible = false end; if c.hl then c.hl.Enabled = false end end
        end
    end
end))

-- FLY ENGINE
local flyMoveTouch, flyMoveSt = nil, nil; local flyJoy = Vector2.zero; local flyConns = {}
local function startFlyCapture()
    local keysHeld = {}
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp) if gp then return end; local k = inp.KeyCode; if k==Enum.KeyCode.W or k==Enum.KeyCode.A or k==Enum.KeyCode.S or k==Enum.KeyCode.D or k==Enum.KeyCode.E or k==Enum.KeyCode.Q then keysHeld[k] = true end end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp) keysHeld[inp.KeyCode] = false end))
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp) if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp.Position.X <= Cam.ViewportSize.X/2 then if not flyMoveTouch then flyMoveTouch = inp; flyMoveSt = inp.Position end end end))
    table.insert(flyConns, UIS.TouchMoved:Connect(function(inp) if inp == flyMoveTouch and flyMoveSt then local dx = inp.Position.X - flyMoveSt.X; local dy = inp.Position.Y - flyMoveSt.Y; flyJoy = Vector2.new(math.abs(dx)>25 and math.clamp((dx-math.sign(dx)*25)/80,-1,1) or 0, math.abs(dy)>20 and math.clamp((dy-math.sign(dy)*20)/80,-1,1) or 0) end end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp == flyMoveTouch then flyMoveTouch=nil; flyMoveSt=nil; flyJoy=Vector2.zero end end))
    State.Fly._keys = keysHeld
end
local function stopFlyCapture() for _, c in ipairs(flyConns) do c:Disconnect() end; flyConns={}; flyMoveTouch=nil; flyMoveSt=nil; flyJoy=Vector2.zero; State.Fly._keys={} end
local function toggleFly(v)
    if not v then
        State.Fly.active = false; stopFlyCapture(); RS:UnbindFromRenderStep("XKIDFly")
        if State.Fly.bv then State.Fly.bv:Destroy(); State.Fly.bv=nil end; if State.Fly.bg then State.Fly.bg:Destroy(); State.Fly.bg=nil end
        local hum = getHum(); if hum then hum.PlatformStand=false; hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.WalkSpeed=State.Move.ws; hum.UseJumpPower=true; hum.JumpPower=State.Move.jp end
        notify("Fly","OFF", 2); return
    end
    local hrp=getRoot(); local hum=getHum(); if not hrp or not hum then return end
    State.Fly.active=true; hum.PlatformStand=true
    State.Fly.bv=Instance.new("BodyVelocity",hrp); State.Fly.bv.MaxForce=Vector3.new(9e9,9e9,9e9); State.Fly.bv.Velocity=Vector3.zero
    State.Fly.bg=Instance.new("BodyGyro",hrp); State.Fly.bg.MaxTorque=Vector3.new(9e9,9e9,9e9); State.Fly.bg.P=50000
    startFlyCapture()
    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value+1, function()
        if not State.Fly.active then return end; local r=getRoot(); if not r then return end; local camCF=Cam.CFrame; local spd=State.Move.flyS; local move=Vector3.zero; local keys=State.Fly._keys or {}
        if onMobile then move = camCF.LookVector * (-flyJoy.Y) + camCF.RightVector * flyJoy.X
        else if keys[Enum.KeyCode.W] then move=move+camCF.LookVector end; if keys[Enum.KeyCode.S] then move=move-camCF.LookVector end; if keys[Enum.KeyCode.D] then move=move+camCF.RightVector end; if keys[Enum.KeyCode.A] then move=move-camCF.RightVector end; if keys[Enum.KeyCode.E] then move=move+Vector3.new(0,1,0) end; if keys[Enum.KeyCode.Q] then move=move-Vector3.new(0,1,0) end end
        if move.Magnitude > 0 then State.Fly.bv.Velocity = move.Unit * spd else State.Fly.bv.Velocity = Vector3.zero end
        State.Fly.bg.CFrame = CFrame.new(r.Position, r.Position+camCF.LookVector)
    end)
    notify("Fly","ON", 3)
end

-- FREECAM ENGINE (IDENTICAL TO FLY)
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

-- SPECTATE (simplified)
local Spec = { active=false, target=nil, mode="third", dist=8, origFov=70, orbitYaw=0, orbitPitch=0, fpYaw=0, fpPitch=0 }
local specConns={}; local specPan=Vector2.zero
local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value+1, function()
        if not Spec.active then return end; Cam.CameraType=Enum.CameraType.Scriptable; local char=Spec.target and Spec.target.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        if Spec.mode=="third" then
            local oCF = CFrame.new(hrp.Position) * CFrame.Angles(0,math.rad(-Spec.orbitYaw),0) * CFrame.Angles(math.rad(-Spec.orbitPitch),0,0) * CFrame.new(0,0,Spec.dist)
            Cam.CFrame=CFrame.new(oCF.Position, hrp.Position+Vector3.new(0,1,0))
        else
            local head=char:FindFirstChild("Head"); local origin=head and head.Position or hrp.Position+Vector3.new(0,1.5,0)
            Cam.CFrame = CFrame.new(origin) * CFrame.Angles(0,math.rad(Spec.fpYaw),0) * CFrame.Angles(math.rad(Spec.fpPitch),0,0)
        end
    end)
end
local function stopSpecLoop() RS:UnbindFromRenderStep("XKIDSpec") end

-- CREATE WINDOW
local Window = WindUI:CreateWindow({
    Title = "@WTF.XKID", Subtitle = "Luxury Script", Author = "by @WTF.XKID", Folder = "XKIDScript",
    Icon = "zap", Theme = "Crimson", Acrylic = true, Transparent = true, Size = UDim2.fromOffset(720, 560),
    MinSize = Vector2.new(580, 420), MaxSize = Vector2.new(880, 620), ToggleKey = Enum.KeyCode.RightShift,
    Resizable = true, AutoScale = true, NewElements = true, SideBarWidth = 200,
    Topbar = { Height = 44, ButtonsType = "Default" },
    OpenButton = { Title = "⚡XKID HUB", Icon = "shield", CornerRadius = UDim.new(1,0), StrokeThickness = 3, Enabled = true, Draggable = true, OnlyMobile = false, Scale = 1, Color = ColorSequence.new(Color3.fromRGB(220,20,60), Color3.fromRGB(180,10,40)) },
    User = { Enabled = true, Anonymous = false, Callback = function() notify("@WTF.XKID", "Designed by @WTF.XKID", 3) end },
})
WindUI:SetTheme("Crimson")

-- HOME TAB
local T_HOME = Window:Tab({ Title = "Home", Icon = "home" })
local secWelcome = T_HOME:Section({ Title = "⚡XKID HUB", Opened = true })
secWelcome:Paragraph({ Title = "Welcome Back", Desc = "@WTF.XKID\nFreecam = Fly-like movement!" })
local secStatus = T_HOME:Section({ Title = "System Status", Opened = true })
local statusLabel = secStatus:Paragraph({ Title = "Live Metrics", Desc = "Calculating..." })
local secChangelog = T_HOME:Section({ Title = "Changelog", Opened = true })
secChangelog:Paragraph({ Title = "Latest", Desc = "• Freecam movement IDENTICAL to Fly\n• Joystick left = move, right = rotate\n• Camera up = fly up, down = descend\n• Crimson Theme\n• OpenButton: ⚡XKID HUB" })
local secCreditsHome = T_HOME:Section({ Title = "Credits", Opened = false })
secCreditsHome:Paragraph({ Title = "Created by", Desc = "@WTF.XKID\nPowered by WindUI\nVersion 2.2" })

-- LIVE STATS
local fpsSamples = {}
TrackC(RS.RenderStepped:Connect(function(dt) table.insert(fpsSamples, dt); if #fpsSamples > 30 then table.remove(fpsSamples,1) end end))
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(0.5)
        if statusLabel then
            local avg = 0; for _,s in ipairs(fpsSamples) do avg=avg+s end; avg = #fpsSamples>0 and avg/#fpsSamples or 0.033; local fps = math.floor(1/avg); local fpsColor = fps>=60 and "🟢" or fps>=30 and "🟡" or "🔴"
            local ping = 0; pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) end); local pingColor = ping<100 and "🟢" or ping<200 and "🟡" or "🔴"
            local statusText = string.format("FPS: %s %s\nPING: %s %s ms\nPlayers: %d", fpsColor, fps, pingColor, ping, #Players:GetPlayers())
            pcall(function() statusLabel:SetDesc(statusText) end)
        end
    end
end)

-- PLAYER TAB
local T_AV = Window:Tab({ Title = "Player", Icon = "user" })
local secAvatar = T_AV:Section({ Title = "Avatar", Opened = true })
secAvatar:Button({ Title = "Fast Respawn — /re", Callback = function() fastRespawn() end })
local secMov = T_AV:Section({ Title = "Movement", Opened = true })
secMov:Button({ Title = "Refresh POV", Callback = function() local r=getRoot(); local h=getHum(); if not r or not h then return end; Cam.CameraType=Enum.CameraType.Custom; task.wait(0.05); Cam.CameraType=Enum.CameraType.Scriptable; task.wait(0.05); Cam.CameraType=Enum.CameraType.Custom; pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end); notify("POV","Reset",2) end })
secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = tonumber(v) or 16; if getHum() then getHum().WalkSpeed = State.Move.ws end end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = tonumber(v) or 50; local hum = getHum(); if hum then hum.UseJumpPower=true; hum.JumpPower=State.Move.jp end end })
secMov:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(v) if v then State.Move.infJ = TrackC(UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end)) else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ=nil end end end })
local secAbi = T_AV:Section({ Title = "Abilities", Opened = true })
secAbi:Toggle({ Title = "Fly", Value = false, Callback = function(v) toggleFly(v) end })
secAbi:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(v) State.Move.flyS = tonumber(v) or 60 end })
secAbi:Toggle({ Title = "NoClip", Value = false, Callback = function(v) State.Move.ncp = v end })
secAbi:Toggle({ Title = "Extreme Fling", Value = false, Callback = function(v) State.Fling.active=v; State.Move.ncp=v end })
secAbi:Toggle({ Title = "Soft Fling", Value = false, Callback = function(v) State.SoftFling.active=v; State.Move.ncp=v end })
secAbi:Toggle({ Title = "God Mode", Value = false, Callback = function(v) if v then local hum=getHum(); if hum then hum.MaxHealth=math.huge; hum.Health=math.huge end; notify("God","ON",2) else local hum=getHum(); if hum then hum.MaxHealth=100; hum.Health=100 end; notify("God","OFF",2) end end })

-- TELEPORT TAB
local T_TP = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local secTP = T_TP:Section({ Title = "Quick Teleport", Opened = true })
local tpTarget = ""
secTP:Input({ Title = "Search Player", Placeholder = "name...", Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "Teleport", Callback = function() if tpTarget=="" then return end; for _,p in pairs(Players:GetPlayers()) do if p~=LP then if string.find(string.lower(p.Name),string.lower(tpTarget)) or string.find(string.lower(p.DisplayName),string.lower(tpTarget)) then local tHrp = getCharRoot(p.Character); local myHrp = getRoot(); if tHrp and myHrp then myHrp.CFrame = tHrp.CFrame * CFrame.new(0,0,3) + Vector3.new(0,2,0); notify("TP","To "..p.DisplayName,2); return end end end end; notify("TP","Not found",2) end })
local secLoc = T_TP:Section({ Title = "Save & Load", Opened = true })
local SavedLocs = {}
for i=1,5 do local idx=i; secLoc:Button({ Title="Save "..idx, Callback=function() local r=getRoot(); if r then SavedLocs[idx]=r.CFrame; notify("Saved","Slot "..idx,2) end end }) end
for i=1,5 do local idx=i; secLoc:Button({ Title="Load "..idx, Callback=function() if SavedLocs[idx] then local r=getRoot(); if r then r.CFrame=SavedLocs[idx]; notify("Loaded","Slot "..idx,2) end end end }) end

-- CAMERA TAB
local T_CAM = Window:Tab({ Title = "Camera", Icon = "eye" })
local secFC = T_CAM:Section({ Title = "Freecam", Opened = true })
secFC:Toggle({ Title = "Freecam", Desc = "Left area = move, Right area = rotate (Fly-like)", Value = false, Callback = function(v)
    FC.active = v
    if v then
        local cf = Cam.CFrame; FC.pos = cf.Position; local rx,ry = cf:ToEulerAnglesYXZ(); FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry)
        local hrp = getRoot(); if hrp then FC.savedCF = hrp.CFrame; hrp.Anchored = true end
        local hum = getHum(); if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum:ChangeState(Enum.HumanoidStateType.Physics) end
        startFreecamCapture(); startFreecamLoop(); notify("Freecam","ON (Fly-like)",2)
    else
        stopFreecamLoop(); stopFreecamCapture()
        local hrp = getRoot(); if hrp then hrp.Anchored = false; if FC.savedCF then hrp.CFrame = FC.savedCF; FC.savedCF = nil end end
        local hum = getHum(); if hum then hum.WalkSpeed = State.Move.ws; hum.JumpPower = State.Move.jp; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        Cam.FieldOfView = 70; Cam.CameraType = Enum.CameraType.Custom; notify("Freecam","OFF",2)
    end
end })
secFC:Slider({ Title = "Speed", Step = 1, Value = { Min = 1, Max = 30, Default = 5 }, Callback = function(v) FC.speed = tonumber(v) or 5 end })
secFC:Slider({ Title = "Sensitivity", Step = 1, Value = { Min = 1, Max = 20, Default = 5 }, Callback = function(v) FC.sens = (tonumber(v) or 5)*0.05 end })
secFC:Slider({ Title = "FOV", Step = 1, Value = { Min = 10, Max = 120, Default = 70 }, Callback = function(v) Cam.FieldOfView = tonumber(v) or 70 end })

local secSP = T_CAM:Section({ Title = "Spectate", Opened = true })
local specDropOpts = {}
for _,p in pairs(Players:GetPlayers()) do if p~=LP then table.insert(specDropOpts, p.DisplayName) end end
secSP:Dropdown({ Title = "Target", Values = specDropOpts, Callback = function(v) for _,p in pairs(Players:GetPlayers()) do if p~=LP and p.DisplayName == v then Spec.target = p; break end end end })
secSP:Toggle({ Title = "Spectate ON", Value = false, Callback = function(v) Spec.active=v; if v then if not Spec.target then notify("Spec","Select target first",2); Spec.active=false; return end; Spec.origFov=Cam.FieldOfView; startSpecLoop(); notify("Spec","ON",2) else stopSpecLoop(); Cam.CameraType=Enum.CameraType.Custom; Cam.FieldOfView=Spec.origFov; notify("Spec","OFF",2) end end })
secSP:Toggle({ Title = "First Person", Value = false, Callback = function(v) Spec.mode = v and "first" or "third" end })

-- WORLD TAB
local T_WO = Window:Tab({ Title = "World", Icon = "globe" })
local secWea = T_WO:Section({ Title = "Weather", Opened = true })
secWea:Button({ Title = "Morning", Callback = function() Lighting.ClockTime = 7; Lighting.Brightness = 1 end })
secWea:Button({ Title = "Day", Callback = function() Lighting.ClockTime = 14; Lighting.Brightness = 2 end })
secWea:Button({ Title = "Night", Callback = function() Lighting.ClockTime = 0; Lighting.Brightness = 0.5 end })
secWea:Toggle({ Title = "Fullbright", Value = false, Callback = function(v) if v then Lighting.Ambient = Color3.new(1,1,1); Lighting.FogEnd = 999999 else Lighting.Ambient = Color3.new(0.5,0.5,0.5); Lighting.FogEnd = 1000 end end })

-- ESP TAB
local T_ESP = Window:Tab({ Title = "ESP", Icon = "radar" })
local secESP = T_ESP:Section({ Title = "ESP", Opened = true })
secESP:Toggle({ Title = "Enable ESP", Value = false, Callback = function(v) State.ESP.active = v; notify("ESP",v and "ON" or "OFF",2) end })
secESP:Dropdown({ Title = "Tracer Mode", Values = {"Bottom","Center","Mouse","OFF"}, Value = "Bottom", Callback = function(v) State.ESP.tracerMode = v end })
secESP:Toggle({ Title = "Show Distance", Value = true, Callback = function(v) State.ESP.showDistance = v end })
secESP:Slider({ Title = "Draw Distance", Step = 10, Value = { Min = 50, Max = 500, Default = 300 }, Callback = function(v) State.ESP.maxDrawDistance = tonumber(v) or 300 end })

-- SECURITY TAB
local T_SEC = Window:Tab({ Title = "Security", Icon = "shield" })
local secProt = T_SEC:Section({ Title = "Protection", Opened = true })
secProt:Toggle({ Title = "Anti-AFK", Value = false, Callback = function(v) if v then State.Security.afkConn = TrackC(LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); task.wait(1) end)); notify("Anti-AFK","ON",2) else if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn=nil end; notify("Anti-AFK","OFF",2) end end })
secProt:Button({ Title = "Rejoin Server", Callback = function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end })

-- SETTINGS TAB
local T_SET = Window:Tab({ Title = "Settings", Icon = "settings" })
local secTheme = T_SET:Section({ Title = "Appearance", Opened = true })
secTheme:Dropdown({ Title = "Theme", Values = {"Crimson","Rose","Dark","Light"}, Value = "Crimson", Callback = function(v) WindUI:SetTheme(v) end })
secTheme:Toggle({ Title = "Acrylic", Value = true, Callback = function() WindUI:ToggleAcrylic(not WindUI.Window.Acrylic) end })
secTheme:Keybind({ Title = "Toggle Key", Value = Enum.KeyCode.RightShift, Callback = function(v) Window:SetToggleKey((typeof(v)=="EnumItem") and v or Enum.KeyCode[v]) end })
local secCredit = T_SET:Section({ Title = "Credits", Opened = false })
secCredit:Paragraph({ Title = "Created by", Desc = "@WTF.XKID" })

-- BACKGROUND LOOPS
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if (State.Fling.active or State.SoftFling.active) and getRoot() then
            local r = getRoot()
            local pwr = State.Fling.active and State.Fling.power or State.SoftFling.power
            pcall(function() r.AssemblyAngularVelocity = Vector3.new(0,pwr,0); if State.Fling.active then r.AssemblyLinearVelocity = Vector3.new(pwr,pwr,pwr) end end)
        end
        RS.RenderStepped:Wait()
    end
end)

TrackC(RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active or State.SoftFling.active) and LP.Character then
        for _,v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end))

-- STARTUP
WindUI:SetNotificationLower(true)
WindUI:Notify({ Title = "@WTF.XKID", Content = "Luxury Script - Freecam Fixed", Duration = 3 })
task.wait(1)
WindUI:Notify({ Title = "⚡XKID HUB", Content = "Freecam = Fly-like movement!", Duration = 4 })
print("✅ XKID Luxury Script Loaded | Freecam Fixed")