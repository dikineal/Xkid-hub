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
║                      Script Client                              ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
]]

local RS = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- FIXED: Auto Cleanup & State Reset (Fix Reload / Close Issue)
if getgenv()._XKID_RUNNING ~= nil then
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

if getgenv()._XKID_CONNS then
    for _, c in pairs(getgenv()._XKID_CONNS) do 
        pcall(function() c:Disconnect() end) 
    end
end
getgenv()._XKID_CONNS = {}

pcall(function()
    RS:UnbindFromRenderStep("XKIDFreecam")
    RS:UnbindFromRenderStep("XKIDFly")
    RS:UnbindFromRenderStep("XKIDSpec")
end)

pcall(function()
    for _, v in pairs(CoreGui:GetChildren()) do
        if v.Name == "WindUI" or v.Name == "_XKIDEsp" then v:Destroy() end
    end
end)

task.wait(0.1) 
collectgarbage("collect")

getgenv()._XKID_LOADED = true
getgenv()._XKID_RUNNING = true
local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

-- UI Monitor: Stop loop jika UI diclose
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(1)
        local guiExists = false
        for _, v in pairs(CoreGui:GetChildren()) do
            if v.Name == "WindUI" then guiExists = true break end
        end
        if not guiExists then
            getgenv()._XKID_RUNNING = false
        end
    end
end)

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Services
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

-- State
local State = {
    Move     = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly      = { active = false, bv = nil, bg = nil },
    Fling    = { active = false, power = 1000000 },
    SoftFling= { active = false, power = 4000 },
    Teleport = { selectedTarget = "" },
    Security = { afkConn = nil },
    Cinema   = { active = false },
    Spectate = { hideName = false },
    Avatar   = { isRefreshing = false },
    Ghost    = { active = false },
    Chat     = { bypass = false },
    Atmos    = { fullbright = false, default = { Ambient = Lighting.Ambient, FogEnd = Lighting.FogEnd } },
    ESP = {
        active          = false,
        cache           = getgenv()._XKID_ESP_CACHE,
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

local colorMap = {
    ["Merah"] = Color3.fromRGB(255, 0, 0), ["Hijau"] = Color3.fromRGB(0, 255, 0),
    ["Biru"]  = Color3.fromRGB(0, 0, 255), ["Kuning"]= Color3.fromRGB(255, 255, 0),
    ["Ungu"]  = Color3.fromRGB(255, 0, 255), ["Cyan"]  = Color3.fromRGB(0, 255, 255),
    ["Orange"]= Color3.fromRGB(255, 165, 0), ["Pink"]  = Color3.fromRGB(255, 105, 180),
    ["Putih"] = Color3.fromRGB(255, 255, 255), ["Hitam"] = Color3.fromRGB(0, 0, 0),
}

-- Helpers
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
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
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

-- Fast Respawn
local function fastRespawn() 
    if State.Avatar.isRefreshing then return end
    
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = getRoot()

    if not hum or not hrp then return end

    State.Avatar.isRefreshing = true
    
    local savedCF = hrp.CFrame
    local savedCamCF = Cam.CFrame
    
    Cam.CameraType = Enum.CameraType.Scriptable
    Cam.CFrame = savedCamCF
    
    local charAddedConn
    charAddedConn = TrackC(LP.CharacterAdded:Connect(function(newChar)
        charAddedConn:Disconnect() 
        local newHrp = newChar:WaitForChild("HumanoidRootPart", 5)
        local newHum = newChar:WaitForChild("Humanoid", 5)
        
        if not LP:HasAppearanceLoaded() then
            LP.CharacterAppearanceLoaded:Wait()
        end
        task.wait(0.2) 
        
        if newHrp and newHum then
            newHrp.CFrame = savedCF + Vector3.new(0, 3, 0)
            newHrp.AssemblyLinearVelocity = Vector3.zero 
            task.spawn(function()
                task.wait(0.05)
                if newHrp then newHrp.CFrame = savedCF + Vector3.new(0, 3, 0) end
            end)
            Cam.CameraSubject = newHum
            Cam.CameraType = Enum.CameraType.Custom
        end
        State.Avatar.isRefreshing = false
    end))

    hum.Health = 0
    task.delay(5, function() State.Avatar.isRefreshing = false end)
end

-- Chat Commands & Bypass
local function sendBypassMessage(msg)
    local bypassed = ""
    for i = 1, #msg do bypassed = bypassed .. msg:sub(i, i) .. "󠀠" end
    local DefaultChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if DefaultChat and DefaultChat:FindFirstChild("SayMessageRequest") then
        DefaultChat.SayMessageRequest:FireServer(bypassed, "All")
    elseif TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then channel:SendAsync(bypassed) end
    end
end

TrackC(LP.Chatted:Connect(function(msg)
    local lowerMsg = msg:lower()
    if lowerMsg == ";re" or lowerMsg == "/re" or lowerMsg == "/reset" or lowerMsg == ";reset" then fastRespawn(); return end
    if lowerMsg == "!rejoin" then TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP); return end
    if State.Chat.bypass and not msg:match("^/") then sendBypassMessage(msg) end
end))

-- ESP
local function initPlayerCache(player)
    if State.ESP.cache[player] then return end
    local cache = { texts = Drawing.new("Text"), tracer = Drawing.new("Line"), boxLines = {}, hl = nil, isSuspect= false, reason = "" }
    cache.texts.Center = true; cache.texts.Outline = true; cache.texts.Font = 2; cache.texts.Size = 13; cache.texts.ZIndex = 2
    cache.tracer.Thickness = 1.5; cache.tracer.ZIndex = 1
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = 1.5; line.ZIndex = 1
        cache.boxLines[i] = line
    end
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

-- ESP Scanner Loop
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if State.ESP.active then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local isSus = false; local reason = ""
                    for _, v in pairs(p.Character:GetChildren()) do
                        if v:IsA("BasePart") and (v.Size.X > 20 or v.Size.Y > 20 or v.Size.Z > 20) then
                            isSus = true; reason = "Map Blocker" break
                        elseif v:IsA("Accessory") then
                            local h = v:FindFirstChild("Handle")
                            if h and h:IsA("BasePart") and (h.Size.Magnitude > 15) then isSus = true; reason = "Huge Hat" break end
                        end
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

-- ESP Render Loop
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
                for _, l in ipairs(c.boxLines) do l.Visible = false end
                if c.hl then c.hl.Enabled = false end
                continue
            end
            
            local rootPos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
            if not onScreen then
                c.texts.Visible = false; c.tracer.Visible = false
                for _, l in ipairs(c.boxLines) do l.Visible = false end
                if c.hl then c.hl.Enabled = false end
                continue
            end
            
            local isSus = c.isSuspect
            
            local txt = ""
            if State.ESP.showNickname then txt = player.DisplayName end
            if State.ESP.showDistance then txt = txt .. "\n[" .. math.floor(dist) .. "m]" end
            if isSus then txt = txt .. "\n⚠ " .. c.reason .. " ⚠" end
            
            c.texts.Text = txt
            c.texts.Color = isSus and State.ESP.boxColor_S or State.ESP.nameColor
            c.texts.Position = Vector2.new(rootPos.X, rootPos.Y - 45)
            c.texts.Visible = true
            
            if State.ESP.tracerMode ~= "OFF" or isSus then
                local origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
                if State.ESP.tracerMode == "Center" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
                elseif State.ESP.tracerMode == "Mouse" then local m = UIS:GetMouseLocation(); origin = Vector2.new(m.X, m.Y) end
                
                c.tracer.From = origin; c.tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                c.tracer.Color = isSus and State.ESP.tracerColor_S or State.ESP.tracerColor_N
                c.tracer.Visible = true
            else
                c.tracer.Visible = false
            end
            
            if isSus then
                local top, _ = Cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local bot, _ = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                local h = math.abs(top.Y - bot.Y); local w = h * 0.6
                local tl = Vector2.new(rootPos.X - w/2, top.Y); local tr = Vector2.new(rootPos.X + w/2, top.Y)
                local bl = Vector2.new(rootPos.X - w/2, bot.Y); local br = Vector2.new(rootPos.X + w/2, bot.Y)
                
                c.boxLines[1].From = tl; c.boxLines[1].To = tr
                c.boxLines[2].From = tr; c.boxLines[2].To = br
                c.boxLines[3].From = br; c.boxLines[3].To = bl
                c.boxLines[4].From = bl; c.boxLines[4].To = tl
                
                for i=1, 4 do c.boxLines[i].Color = State.ESP.boxColor_S; c.boxLines[i].Visible = true end
                
                if not c.hl or c.hl.Parent ~= char then
                    if c.hl then c.hl:Destroy() end
                    c.hl = Instance.new("Highlight", char)
                    c.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
                c.hl.FillColor = State.ESP.boxColor_S; c.hl.OutlineColor = Color3.new(1,1,1); c.hl.Enabled = true
            else
                for _, l in ipairs(c.boxLines) do l.Visible = false end
                if c.hl then c.hl.Enabled = false end
            end
        end
    end
end))

-- Fly
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
            local dx = inp.Position.X - flyMoveSt.X; local dy = inp.Position.Y - flyMoveSt.Y
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
        if hum then hum.PlatformStand=false; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        return
    end
    local hrp=getRoot(); local hum=getHum()
    if not hrp or not hum then return end
    State.Fly.active=true; hum.PlatformStand=true
    State.Fly.bv=Instance.new("BodyVelocity",hrp); State.Fly.bv.MaxForce=Vector3.new(9e9,9e9,9e9); State.Fly.bv.Velocity=Vector3.zero
    State.Fly.bg=Instance.new("BodyGyro",hrp); State.Fly.bg.MaxTorque=Vector3.new(9e9,9e9,9e9); State.Fly.bg.P=50000 
    
    startFlyCapture()
    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value+1, function()
        if not State.Fly.active then return end
        local r=getRoot(); if not r then return end
        local camCF=Cam.CFrame
        local spd=State.Move.flyS
        local move=Vector3.zero
        local keys=State.Fly._keys or {}
        if onMobile then
            move = camCF.LookVector*(-flyJoy.Y) + camCF.RightVector*flyJoy.X
        else
            if keys[Enum.KeyCode.W] then move=move+camCF.LookVector  end
            if keys[Enum.KeyCode.S] then move=move-camCF.LookVector  end
            if keys[Enum.KeyCode.D] then move=move+camCF.RightVector end
            if keys[Enum.KeyCode.A] then move=move-camCF.RightVector end
            if keys[Enum.KeyCode.E] then move=move+Vector3.new(0,1,0) end
            if keys[Enum.KeyCode.Q] then move=move-Vector3.new(0,1,0) end
        end
        if move.Magnitude > 0 then State.Fly.bv.Velocity = move.Unit * spd else State.Fly.bv.Velocity = Vector3.zero end
        State.Fly.bg.CFrame = CFrame.new(r.Position, r.Position+camCF.LookVector)
    end)
end

-- Freecam
local FC = { active=false, pos=Vector3.zero, pitchDeg=0, yawDeg=0, speed=5, sens=0.25, savedCF=nil }
local fcRotT,fcMoveT,fcMoveSt,fcRotLast = nil,nil,nil,nil
local DEAD_X = 25; local DEAD_Y = 20
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
            FC.yawDeg = FC.yawDeg - inp.Delta.X*FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg-inp.Delta.Y*FC.sens,-80,80)
        end
    end))
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp,gp)
        if gp or inp.UserInputType~=Enum.UserInputType.Touch then return end
        local half=Cam.ViewportSize.X/2
        if inp.Position.X>half then if not fcRotT then fcRotT=inp; fcRotLast=inp.Position end else if not fcMoveT then fcMoveT=inp; fcMoveSt=inp.Position end end
    end))
    table.insert(fcConns, UIS.TouchMoved:Connect(function(inp)
        if inp==fcRotT and fcRotLast then
            FC.yawDeg = FC.yawDeg -(inp.Position.X-fcRotLast.X)*FC.sens
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
        if inp==fcRotT then fcRotT=nil; fcRotLast=nil end
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
        local move = Vector3.zero
        local keys = FC._keys or {}
        if onMobile then move = Vector3.new(fcJoy.X, -fcJoy.Y, 0)
        else
            if keys[Enum.KeyCode.W] then move = move + Vector3.new(0, 0, -1) end
            if keys[Enum.KeyCode.S] then move = move + Vector3.new(0, 0, 1)  end
            if keys[Enum.KeyCode.A] then move = move + Vector3.new(-1, 0, 0) end
            if keys[Enum.KeyCode.D] then move = move + Vector3.new(1, 0, 0)  end
            if keys[Enum.KeyCode.E] then move = move + Vector3.new(0, 1, 0)  end
            if keys[Enum.KeyCode.Q] then move = move + Vector3.new(0, -1, 0) end
        end
        if move.Magnitude > 0 then move = move.Unit end
        
        local cf = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        FC.pos = FC.pos + cf:VectorToWorldSpace(move * (FC.speed * dt * 60))
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        
        local hrp=getRoot(); local hum=getHum()
        if hrp and not hrp.Anchored then hrp.Anchored=true end
        if hum then hum:ChangeState(Enum.HumanoidStateType.Physics); hum.WalkSpeed=0; hum.JumpPower=0 end
    end)
end

-- UI Setup
local Window = WindUI:CreateWindow({
    Title       = "@WTF.XKID",
    Folder      = "XKIDScript",
    Icon        = "zap",
    Theme       = "Rose",
    Acrylic     = true,
    Transparent = true,
    Size        = UDim2.fromOffset(600, 420),
    MinSize     = Vector2.new(500, 380),
    ToggleKey   = Enum.KeyCode.RightShift,
    Resizable   = true,
    AutoScale   = true,
    SideBarWidth= 180,
})

WindUI:SetTheme("Rose")

-- Player
local T_AV = Window:Tab({ Title = "Player", Icon = "user" })
local secAvatar = T_AV:Section({ Title = "Avatar", Opened = true })
secAvatar:Button({ Title = "Fast Respawn — /re", Callback = function() fastRespawn() end })

local secMov = T_AV:Section({ Title = "Movement", Opened = true })
secMov:Button({ Title = "Refresh POV", Callback = function()
    local r=getRoot(); local h=getHum()
    if not r or not h then return end
    Cam.CameraType=Enum.CameraType.Custom; task.wait(0.05); Cam.CameraType=Enum.CameraType.Scriptable; task.wait(0.05); Cam.CameraType=Enum.CameraType.Custom
    pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
end})
secMov:Slider({ Title = "Walk Speed", Step=1, Value={Min=16, Max=500, Default=16}, Callback = function(v) State.Move.ws = v if getHum() then getHum().WalkSpeed = v end end })
secMov:Slider({ Title = "Jump Power", Step=1, Value={Min=50, Max=500, Default=50}, Callback = function(v) State.Move.jp = v if getHum() then getHum().UseJumpPower=true; getHum().JumpPower=v end end })
secMov:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(v)
    if v then State.Move.infJ = TrackC(UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end))
    else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ=nil end end
end})

local secAbi = T_AV:Section({ Title = "Abilities", Opened = true })
secAbi:Toggle({ Title = "Fly", Callback = function(v) toggleFly(v) end })
secAbi:Slider({ Title = "Fly Speed", Step=1, Value={Min=10, Max=300, Default=60}, Callback = function(v) State.Move.flyS = v end })
secAbi:Toggle({ Title = "NoClip", Callback = function(v) State.Move.ncp = v end })
secAbi:Toggle({ Title = "Fling", Callback = function(v) State.Fling.active=v; State.Move.ncp=v end })

local noFallConn, godConn, godRespConn = nil, nil, nil
local godLastPos = nil
secAbi:Toggle({ Title = "No Fall Damage", Callback = function(v)
    if v then noFallConn = TrackC(RS.Heartbeat:Connect(function() local hrp=getRoot() if hrp and hrp.Velocity.Y < -30 then hrp.Velocity=Vector3.new(hrp.Velocity.X,-10,hrp.Velocity.Z) end end))
    else if noFallConn then noFallConn:Disconnect(); noFallConn=nil end end
end})

secAbi:Toggle({ Title = "God Mode", Callback = function(v)
    if v then
        local hum=getHum(); if hum then hum.MaxHealth=math.huge; hum.Health=math.huge end
        godLastPos = getRoot() and getRoot().CFrame
        godRespConn = TrackC(RS.Heartbeat:Connect(function() local r=getRoot(); if r then godLastPos=r.CFrame end end))
        godConn = TrackC(RS.Heartbeat:Connect(function() local h=getHum(); if h then h.Health=math.huge; h.MaxHealth=math.huge end end))
        TrackC(LP.CharacterAdded:Connect(function(char)
            task.wait(0.2)
            local hrp=char:WaitForChild("HumanoidRootPart",5); if hrp and godLastPos then hrp.CFrame=godLastPos end
            local h=char:WaitForChild("Humanoid",5); if h then h.MaxHealth=math.huge; h.Health=math.huge end
        end))
    else
        if godConn then godConn:Disconnect(); godConn=nil end
        if godRespConn then godRespConn:Disconnect(); godRespConn=nil end
        local hum=getHum(); if hum then hum.MaxHealth=100; hum.Health=100 end
    end
end})

-- Teleport
local T_TP = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local secTP = T_TP:Section({ Title = "Quick Teleport", Opened = true })
local tpTarget = ""
secTP:Input({ Title = "Search Player", Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "Teleport", Callback = function()
    if tpTarget == "" then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local nl, dl, tl = string.lower(p.Name), string.lower(p.DisplayName), string.lower(tpTarget)
            if (string.find(nl,tl) or string.find(dl,tl)) then
                local tChar = p.Character; local tHrp = getCharRoot(tChar); local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
                local myHrp = getRoot()
                if tHrp and tHum and myHrp then
                    if tHum.Health <= 0 then notify("Teleport", "Target is dead!", 2); return end
                    myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3) + Vector3.new(0, 2, 0)
                    myHrp.AssemblyLinearVelocity = Vector3.zero
                    notify("Teleport","TP to "..p.DisplayName, 2); return
                end
            end
        end
    end
end})

local pDropOpts = getPNames()
secTP:Dropdown({ Title = "Player List", Values = pDropOpts, Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "Refresh List", Callback = function() pDropOpts = getPNames() end })

local secLoc = T_TP:Section({ Title = "Locations", Opened = true })
local SavedLocs = {}
for i = 1, 3 do
    secLoc:Button({ Title = "Save Slot "..i, Callback = function() local r = getRoot() if r then SavedLocs[i] = r.CFrame end end })
    secLoc:Button({ Title = "Load Slot "..i, Callback = function() if SavedLocs[i] and getRoot() then getRoot().CFrame = SavedLocs[i] end end })
end

-- Camera
local T_CAM = Window:Tab({ Title = "Camera", Icon = "eye" })
local secFC = T_CAM:Section({ Title = "Freecam", Opened = true })
secFC:Toggle({ Title = "Freecam", Callback = function(v)
    FC.active = v; State.Cinema.active = v
    if v then
        local cf=Cam.CFrame; FC.pos=cf.Position; FC.vel=Vector3.zero; local rx,ry=cf:ToEulerAnglesYXZ(); FC.pitchDeg=math.deg(rx); FC.yawDeg=math.deg(ry)
        FC._keys={}; FC._mouseRot=false
        local hrp=getRoot(); local hum=getHum()
        if hrp then FC.savedCF=hrp.CFrame; hrp.Anchored=true end
        if hum then hum.WalkSpeed=0; hum.JumpPower=0; hum:ChangeState(Enum.HumanoidStateType.Physics) end
        startFCCapture(); startFCLoop()
    else
        RS:UnbindFromRenderStep("XKIDFreecam"); stopFCCapture()
        local hrp=getRoot(); local hum=getHum()
        if hrp then hrp.Anchored=false if FC.savedCF then hrp.CFrame=FC.savedCF; FC.savedCF=nil end end
        if hum then hum.WalkSpeed=State.Move.ws; hum.UseJumpPower=true; hum.JumpPower=State.Move.jp; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        Cam.FieldOfView=70; Cam.CameraType=Enum.CameraType.Custom
    end
end})
secFC:Slider({ Title="Speed", Step=1, Value={Min=1, Max=30, Default=5}, Callback=function(v) FC.speed = v end })
secFC:Slider({ Title="FOV", Step=1, Value={Min=10, Max=120, Default=70}, Callback=function(v) Cam.FieldOfView = v end })

local secSP = T_CAM:Section({ Title = "Spectate", Opened = true })
local Spec = { active=false, target=nil, dist=8 }
secSP:Dropdown({ Title = "Target Player", Values = getDisplayNames(), Callback = function(v) Spec.target = findPlayerByDisplay(v) end })
secSP:Toggle({ Title = "Spectate ON/OFF", Callback = function(v)
    Spec.active = v
    if v and Spec.target and Spec.target.Character then Cam.CameraSubject = Spec.target.Character
    else Cam.CameraSubject = LP.Character; Cam.CameraType = Enum.CameraType.Custom end
end})

-- FIXED: World Upgrade (Clean, Smooth, Reusable Environment)
local T_WO = Window:Tab({ Title = "World", Icon = "globe" })

local function getAtmosphere()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atm then
        atm = Instance.new("Atmosphere")
        atm.Parent = Lighting
    end
    return atm
end

local function applyWeather(preset)
    local atm = getAtmosphere()
    if preset == "Clear" then
        Lighting.ClockTime = 14; Lighting.Brightness = 2; Lighting.FogEnd = 100000
        atm.Density = 0; atm.Offset = 0; atm.Glare = 0; atm.Halo = 0
    elseif preset == "Foggy" then
        Lighting.ClockTime = 8; Lighting.Brightness = 1; Lighting.FogEnd = 300
        Lighting.FogColor = Color3.fromRGB(200, 200, 200)
        atm.Density = 0.6; atm.Offset = 0.5; atm.Glare = 0; atm.Halo = 0
    elseif preset == "Sunset" then
        Lighting.ClockTime = 17.8; Lighting.Brightness = 1.5; Lighting.FogEnd = 4000
        Lighting.FogColor = Color3.fromRGB(255, 180, 100)
        atm.Density = 0.2; atm.Offset = 0.3; atm.Glare = 0.8; atm.Halo = 0.5
    elseif preset == "Dark" then
        Lighting.ClockTime = 0; Lighting.Brightness = 0.2; Lighting.FogEnd = 500
        Lighting.FogColor = Color3.fromRGB(10, 10, 15)
        atm.Density = 0.5; atm.Offset = 0; atm.Glare = 0; atm.Halo = 0
    elseif preset == "Bright" then
        Lighting.ClockTime = 12; Lighting.Brightness = 3; Lighting.FogEnd = 100000
        Lighting.FogColor = Color3.fromRGB(255, 255, 255)
        atm.Density = 0; atm.Offset = 0; atm.Glare = 0; atm.Halo = 0
    end
end

local secTime = T_WO:Section({ Title = "Time Presets", Opened = true })
secTime:Button({ Title="Morning", Callback=function() Lighting.ClockTime = 7 end })
secTime:Button({ Title="Day", Callback=function() Lighting.ClockTime = 14 end })
secTime:Button({ Title="Evening", Callback=function() Lighting.ClockTime = 17.5 end })
secTime:Button({ Title="Night", Callback=function() Lighting.ClockTime = 0 end })

local secWeather = T_WO:Section({ Title = "Weather Presets", Opened = true })
secWeather:Button({ Title="Clear", Callback=function() applyWeather("Clear") end })
secWeather:Button({ Title="Foggy", Callback=function() applyWeather("Foggy") end })
secWeather:Button({ Title="Sunset", Callback=function() applyWeather("Sunset") end })
secWeather:Button({ Title="Dark", Callback=function() applyWeather("Dark") end })
secWeather:Button({ Title="Bright", Callback=function() applyWeather("Bright") end })

local secWorldCtrl = T_WO:Section({ Title = "Custom Controls", Opened = false })
secWorldCtrl:Toggle({ Title = "Fullbright", Callback = function(v)
    State.Atmos.fullbright = v
    if v then
        Lighting.Ambient = Color3.new(1,1,1); Lighting.ColorShift_Bottom = Color3.new(1,1,1); Lighting.ColorShift_Top = Color3.new(1,1,1)
        Lighting.FogEnd = 999999
    else
        Lighting.Ambient = State.Atmos.default.Ambient; Lighting.ColorShift_Bottom = Color3.new(0,0,0); Lighting.ColorShift_Top = Color3.new(0,0,0)
        Lighting.FogEnd = State.Atmos.default.FogEnd
    end
end})
secWorldCtrl:Slider({ Title="Clock Time", Step=1, Value={Min=0, Max=24, Default=14}, Callback=function(v) Lighting.ClockTime = v end })
secWorldCtrl:Slider({ Title="Brightness", Step=0.1, Value={Min=0, Max=5, Default=1}, Callback=function(v) Lighting.Brightness = v end })
secWorldCtrl:Slider({ Title="Fog Range", Step=50, Value={Min=0, Max=5000, Default=1000}, Callback=function(v) Lighting.FogEnd = v end })

local secGfx = T_WO:Section({ Title = "Graphics Mode", Opened = false })
local function setGfx(level) pcall(function() settings().Rendering.QualityLevel = level end) end
secGfx:Button({ Title="Potato", Callback=function() setGfx(Enum.QualityLevel.Level01) end })
secGfx:Button({ Title="Low", Callback=function() setGfx(Enum.QualityLevel.Level03) end })
secGfx:Button({ Title="Medium", Callback=function() setGfx(Enum.QualityLevel.Level05) end })
secGfx:Button({ Title="High", Callback=function() setGfx(Enum.QualityLevel.Level08) end })
secGfx:Button({ Title="Ultra", Callback=function() setGfx(Enum.QualityLevel.Level10) end })

-- ESP
local T_ESP = Window:Tab({ Title = "ESP", Icon = "radar" })
local secESP = T_ESP:Section({ Title = "ESP Control", Opened = true })

secESP:Toggle({ Title = "Enable ESP", Callback = function(v)
    State.ESP.active = v
    if not v and getgenv()._XKID_ESP_CACHE then
        for _,c in pairs(getgenv()._XKID_ESP_CACHE) do
            pcall(function()
                if c.texts then c.texts.Visible = false end
                if c.tracer then c.tracer.Visible = false end
                if c.boxLines then for _, l in ipairs(c.boxLines) do l.Visible = false end end
                if c.hl then c.hl.Enabled = false end
            end)
        end
    end
end})

secESP:Dropdown({ Title="Tracer Mode", Values={"Bottom","Center","Mouse","OFF"}, Value="Bottom", Callback=function(v) State.ESP.tracerMode=v end })
secESP:Toggle({ Title="Show Distance", Value=true, Callback=function(v) State.ESP.showDistance=v end })
secESP:Toggle({ Title="Show Name", Value=true, Callback=function(v) State.ESP.showNickname=v end })
secESP:Slider({ Title="Draw Distance", Step=10, Value={Min=50,Max=500,Default=300}, Callback=function(v) State.ESP.maxDrawDistance=v end })

local secESPColor = T_ESP:Section({ Title = "Colors", Opened = false })
secESPColor:Dropdown({ Title="Normal Tracer Color", Values={"Hijau","Merah","Biru","Kuning","Putih"}, Value="Hijau", Callback=function(v) if colorMap[v] then State.ESP.tracerColor_N = colorMap[v] end end })
secESPColor:Dropdown({ Title="Suspect Full Color", Values={"Merah","Hijau","Biru","Kuning","Putih"}, Value="Merah", Callback=function(v) if colorMap[v] then State.ESP.boxColor_S = colorMap[v]; State.ESP.tracerColor_S = colorMap[v] end end })
secESPColor:Dropdown({ Title="Text/Name Color", Values={"Putih","Merah","Hijau","Biru","Kuning"}, Value="Putih", Callback=function(v) if colorMap[v] then State.ESP.nameColor = colorMap[v] end end })

-- Security
local T_SEC = Window:Tab({ Title = "Security", Icon = "shield" })
local secProt = T_SEC:Section({ Title = "Protection", Opened = true })
secProt:Toggle({ Title = "Anti-AFK", Callback = function(v)
    if v then State.Security.afkConn = TrackC(LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end))
    else if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn=nil end end
end})

local antiLag = { mats={}, texs={}, shadows=true }
secProt:Toggle({ Title = "Anti Lag Mode", Callback = function(v)
    if v then
        antiLag.shadows=Lighting.GlobalShadows; Lighting.GlobalShadows=false
        for _,obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then antiLag.mats[obj]=obj.Material; obj.Material=Enum.Material.SmoothPlastic
            elseif obj:IsA("Texture") or obj:IsA("Decal") then antiLag.texs[obj]=obj.Parent; obj.Parent=nil end
        end
    else
        Lighting.GlobalShadows=antiLag.shadows
        for obj,mat in pairs(antiLag.mats) do if obj and obj.Parent then obj.Material=mat end end
        for obj,par in pairs(antiLag.texs) do if obj and par and par.Parent then obj.Parent=par end end
        antiLag.mats={}; antiLag.texs={}
    end
end})

-- Settings
local T_SET = Window:Tab({ Title = "Settings", Icon = "settings" })
local secInfo = T_SET:Section({ Title = "System Info", Opened = true })
local statsLabel = secInfo:Paragraph({ Title = "Network & Performance", Desc = "Calculating..." })

local fpsSamples = {}
TrackC(RS.RenderStepped:Connect(function(dt)
    table.insert(fpsSamples, dt)
    if #fpsSamples > 30 then table.remove(fpsSamples,1) end
end))

task.spawn(function()
    while getgenv()._XKID_RUNNING do
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
            local fpsColor = fps>=60 and "🟢" or fps>=30 and "🟡" or "🔴"
            local ping = 0
            pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            local pingColor = ping < 100 and "🟢" or ping < 200 and "🟡" or "🔴"
            if statsLabel then
                pcall(function() statsLabel:SetDesc(fpsColor.." "..fps.." FPS ["..bar.."]\n"..pingColor.." "..ping.." ms PING") end)
            end
        end
    end
end)

local secTheme = T_SET:Section({ Title = "Appearance", Opened = true })
secTheme:Dropdown({ Title = "Theme", Values = (function() local names={} for name in pairs(WindUI:GetThemes()) do table.insert(names,name) end table.sort(names); return names end)(), Value = "Rose", Callback = function(s) WindUI:SetTheme(s) end })
secTheme:Toggle({ Title = "Transparent Window", Value = true, Callback = function(s) Window:ToggleTransparency(s) end })

-- Background Loops
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if (State.Fling.active or State.SoftFling.active) and getRoot() then
            local r=getRoot()
            local brutal=State.Fling.active
            local pwr=brutal and State.Fling.power or State.SoftFling.power
            pcall(function() r.AssemblyAngularVelocity=Vector3.new(0,pwr,0); if brutal then r.AssemblyLinearVelocity=Vector3.new(pwr,pwr,pwr) end end)
        end
        RS.RenderStepped:Wait()
    end
end)

TrackC(RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active or State.SoftFling.active) and LP.Character then
        for _,v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end
    end
end))

notify("@WTF.XKID", "Script ready & optimized.", 3)
