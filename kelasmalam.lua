--[[
========================
      @WTF.XKID
        Script
========================

  ✨ Features:
  • Avatar Refresh (Fast Respawn + Refresh Character)
  • Teleport (Click TP) & Location Saver
  • Movement (Speed / Jump / Fly / NoClip / Soft Fling)
  • Freecam (Smooth + Mobile Ready)
  • Spectate (Orbit & First Person)
  • Modern Hybrid ESP (Highlight Mode + Large Glitch Detection)
  • World Control (Custom Bloom/Lighting & Camera FOV)
  • Utility & Security (Auto Rejoin, Crash Detection, Anti Void)
  • Network (Ping Spike Alert, Low Player Server Hop)
  • Live FPS, PING & Map Display
  
  💎 Created by @WTF.XKID
  📱 Tiktok: @wtf.xkid
  💬 Discord: @4sharken
]]

local RS = game:GetService("RunService")

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
    end)
    task.wait(0.2) 
    collectgarbage("collect")
end

getgenv()._XKID_LOADED = true
getgenv()._XKID_RUNNING = true
getgenv()._XKID_CONNS = {}
local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

-- Memory GC Optimizer
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(30)
        collectgarbage("collect")
    end
end)

-- ══════════════════════════════════════════════════════════════
--  LOAD WINDUI
-- ══════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- ══════════════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════════════
local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting    = game:GetService("Lighting")
local TPService   = game:GetService("TeleportService")
local StatsService= game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui     = game:GetService("CoreGui")
local LP          = Players.LocalPlayer
local Cam         = workspace.CurrentCamera
local onMobile    = not UIS.KeyboardEnabled

-- ══════════════════════════════════════════════════════════════
--  STATE MANAGEMENT
-- ══════════════════════════════════════════════════════════════
local State = {
    Move     = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly      = { active = false, bv = nil, bg = nil, noFallConn = nil },
    SoftFling= { active = false, power = 4000 },
    Teleport = { selectedTarget = "", clickTool = nil, clickConn = nil },
    Security = { afkConn = nil, antiLag = false, shiftLock = false, shiftLockGyro = nil, voidConn = nil, fallConn = nil, arConn = nil },
    Cinema   = { active = false },
    Spectate = { hideName = false },
    Avatar   = { isRefreshing = false },
    ESP = {
        active          = false,
        cache           = getgenv()._XKID_ESP_CACHE,
        boxMode         = "Corner",
        tracerMode      = "Bottom",
        maxDrawDistance = 300,
        showDistance    = true,
        showNickname    = true,
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
    for _, p in pairs(Players:GetPlayers()) do 
        if p ~= LP then table.insert(t, p.DisplayName) end 
    end
    return t
end

local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do 
        if str == p.DisplayName then return p end 
    end
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
    if State.Teleport.clickTool then
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
        notify("Shift Lock", "🔒 Shift Lock ON", 2)
    else
        RS:UnbindFromRenderStep("XKIDShiftLock")
        if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy(); State.Security.shiftLockGyro = nil end
        notify("Shift Lock", "🔓 Shift Lock OFF", 2)
    end
end

-- ══════════════════════════════════════════════════════════════
--  💎 AVATAR REFRESH ENGINE
-- ══════════════════════════════════════════════════════════════
local function fastRespawn()
    if State.Avatar.isRefreshing then return end
    local char, hrp = LP.Character, getRoot()
    if not char or not hrp then notify("❌ Error", "Karakter tidak ditemukan!", 2); return end
    State.Avatar.isRefreshing = true; notify("🔄 Fast Respawn", "Respawning...", 1.5)
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
        State.Avatar.isRefreshing = false; notify("✅ Success", "Fast Respawn Selesai!", 2)
    end)
    char:BreakJoints()
    task.delay(5, function() State.Avatar.isRefreshing = false end)
end

local function refreshCharacter()
    if State.Avatar.isRefreshing then return end
    local char, hrp = LP.Character, getRoot()
    if not char or not hrp then notify("❌ Error", "Karakter tidak ditemukan!", 2); return end
    State.Avatar.isRefreshing = true; notify("🔄 Refresh", "Refreshing karakter...", 1.5)
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
        State.Avatar.isRefreshing = false; notify("✅ Success", "Karakter Refreshed!", 2)
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
--  💎 HYBRID DETECTION ESP ENGINE
-- ══════════════════════════════════════════════════════════════
local function initPlayerCache(player)
    if State.ESP.cache[player] then return end
    local cache = { texts=Drawing.new("Text"), tracer=Drawing.new("Line"), boxLines={}, hl=nil, isSuspect=false, isGlitch=false, reason="" }
    cache.texts.Center = true; cache.texts.Outline = true; cache.texts.Font = 2; cache.texts.Size = 13; cache.texts.ZIndex = 2
    cache.tracer.Thickness = 1.5; cache.tracer.ZIndex = 1
    for i = 1, 4 do local line = Drawing.new("Line"); line.Thickness = 1.5; line.ZIndex = 1; cache.boxLines[i] = line end
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
                    local isSus, isGlitch, reason = false, false, ""
                    for _, v in pairs(p.Character:GetChildren()) do
                        if v:IsA("BasePart") and (v.Size.X > 30 or v.Size.Y > 30 or v.Size.Z > 30) then
                            isSus = true; reason = "Map Blocker" break
                        elseif v:IsA("Accessory") then
                            local h = v:FindFirstChild("Handle")
                            if h and h:IsA("BasePart") then
                                if h.Size.Magnitude > 20 then isSus = true; reason = "Huge Hat" break
                                elseif h.Size.Magnitude > 10 or (h.Transparency < 0.1 and h.Material == Enum.Material.Neon) then
                                    isGlitch = true; reason = "Glitch Accessory"
                                end
                            end
                        end
                    end
                    if not isSus and not isGlitch then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local bws = hum:FindFirstChild("BodyWidthScale")
                            local bhs = hum:FindFirstChild("BodyHeightScale")
                            if (bws and bws.Value > 2.0) or (bhs and bhs.Value > 2.0) then isSus = true; reason = "Glitch Avatar" end
                        end
                    end
                    initPlayerCache(p)
                    State.ESP.cache[p].isSuspect = isSus; State.ESP.cache[p].isGlitch = isGlitch; State.ESP.cache[p].reason = reason
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
            local char, hrp, hum = player.Character, getCharRoot(player.Character), player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if not char or not hrp or not hum then clearPlayerCache(player); continue end
            initPlayerCache(player); local c = State.ESP.cache[player]
            local active = hum.Health > 0 and myHrp
            local dist = active and (hrp.Position - myHrp.Position).Magnitude or 9999
            
            if not active or dist > State.ESP.maxDrawDistance then
                c.texts.Visible=false; c.tracer.Visible=false; for _, l in ipairs(c.boxLines) do l.Visible=false end; if c.hl then c.hl.Enabled=false end; continue
            end
            
            local rootPos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
            if not onScreen then
                c.texts.Visible=false; c.tracer.Visible=false; for _, l in ipairs(c.boxLines) do l.Visible=false end; if c.hl then c.hl.Enabled=false end; continue
            end
            
            local isSus, isGlitch = c.isSuspect, c.isGlitch
            local useHighlight = isSus or isGlitch or State.ESP.highlightMode
            local txt = ""
            if State.ESP.showNickname then txt = player.DisplayName end
            if State.ESP.showDistance then txt = txt .. "\n[" .. math.floor(dist) .. "m]" end
            if isSus or isGlitch then txt = txt .. "\n⚠ " .. c.reason .. " ⚠" end
            
            c.texts.Text = txt
            c.texts.Color = isSus and State.ESP.boxColor_S or (isGlitch and State.ESP.boxColor_G or State.ESP.nameColor)
            c.texts.Position = Vector2.new(rootPos.X, rootPos.Y - 45); c.texts.Visible = true
            
            if State.ESP.tracerMode ~= "OFF" or isSus or isGlitch then
                local origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
                if State.ESP.tracerMode == "Center" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
                elseif State.ESP.tracerMode == "Mouse" then local m = UIS:GetMouseLocation(); origin = Vector2.new(m.X, m.Y) end
                
                c.tracer.From = origin; c.tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                c.tracer.Color = isSus and State.ESP.tracerColor_S or (isGlitch and State.ESP.tracerColor_G or State.ESP.tracerColor_N); c.tracer.Visible = true
            else c.tracer.Visible = false end
            
            if useHighlight then
                local boxColor = isSus and State.ESP.boxColor_S or (isGlitch and State.ESP.boxColor_G or State.ESP.boxColor_N)
                local top, topOn = Cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local bot, botOn = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                if topOn and botOn then
                    local h = math.abs(top.Y - bot.Y); local w = h * 0.6
                    local tl, tr = Vector2.new(rootPos.X - w/2, top.Y), Vector2.new(rootPos.X + w/2, top.Y)
                    local bl, br = Vector2.new(rootPos.X - w/2, bot.Y), Vector2.new(rootPos.X + w/2, bot.Y)
                    c.boxLines[1].From=tl; c.boxLines[1].To=tr; c.boxLines[2].From=tr; c.boxLines[2].To=br
                    c.boxLines[3].From=br; c.boxLines[3].To=bl; c.boxLines[4].From=bl; c.boxLines[4].To=tl
                    for i=1, 4 do c.boxLines[i].Color = boxColor; c.boxLines[i].Visible = true end
                end
                if not c.hl or c.hl.Parent ~= char then
                    if c.hl then c.hl:Destroy() end; c.hl = Instance.new("Highlight", char); c.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
                c.hl.FillColor = boxColor; c.hl.OutlineColor = Color3.new(1,1,1); c.hl.Enabled = true
            else
                for _, l in ipairs(c.boxLines) do l.Visible = false end; if c.hl then c.hl.Enabled = false end
            end
        end
    end
end))

-- ══════════════════════════════════════════════════════════════
--  FLY ENGINE (DIPERBAIKI: INCLUDE AUTO NO-FALL DAMAGE)
-- ══════════════════════════════════════════════════════════════
local flyMoveTouch, flyMoveSt, flyJoy, flyConns = nil, nil, Vector2.zero, {}

local function startFlyCapture()
    local keysHeld = {}
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode; if k==Enum.KeyCode.W or k==Enum.KeyCode.A or k==Enum.KeyCode.S or k==Enum.KeyCode.D or k==Enum.KeyCode.E or k==Enum.KeyCode.Q then keysHeld[k] = true end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp) keysHeld[inp.KeyCode] = false end))
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
    flyConns={}; flyMoveTouch=nil; flyMoveSt=nil; flyJoy=Vector2.zero; State.Fly._keys={}
end

local function toggleFly(v)
    if not v then
        State.Fly.active = false; stopFlyCapture(); RS:UnbindFromRenderStep("XKIDFly")
        if State.Fly.bv then State.Fly.bv:Destroy(); State.Fly.bv=nil end
        if State.Fly.bg then State.Fly.bg:Destroy(); State.Fly.bg=nil end
        local hum = getHum()
        if hum then hum.PlatformStand=false; hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.WalkSpeed=State.Move.ws; hum.UseJumpPower=true; hum.JumpPower=State.Move.jp end
        if State.Fly.noFallConn then State.Fly.noFallConn:Disconnect(); State.Fly.noFallConn = nil end -- Auto turn off no fall
        notify("Fly","✈ Fly OFF (No Fall Off)", 2)
        return
    end
    local hrp=getRoot(); local hum=getHum()
    if not hrp or not hum then return end
    State.Fly.active=true; hum.PlatformStand=true
    State.Fly.bv=Instance.new("BodyVelocity",hrp); State.Fly.bv.MaxForce=Vector3.new(9e9,9e9,9e9); State.Fly.bv.Velocity=Vector3.zero
    State.Fly.bg=Instance.new("BodyGyro",hrp); State.Fly.bg.MaxTorque=Vector3.new(9e9,9e9,9e9); State.Fly.bg.P=50000 
    
    -- Mengaktifkan No Fall Damage secara otomatis saat Fly On
    if not State.Fly.noFallConn then
        State.Fly.noFallConn = TrackC(RS.Heartbeat:Connect(function()
            local r = getRoot()
            if r and r.Velocity.Y < -30 then r.Velocity = Vector3.new(r.Velocity.X, -10, r.Velocity.Z) end
        end))
    end

    startFlyCapture()
    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value+1, function()
        if not State.Fly.active then return end
        local r=getRoot(); if not r then return end
        local camCF=Cam.CFrame; local spd=State.Move.flyS; local move=Vector3.zero; local keys=State.Fly._keys or {}
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
        State.Fly.bv.Velocity = move.Magnitude > 0 and move.Unit * spd or Vector3.zero
        State.Fly.bg.CFrame   = CFrame.new(r.Position, r.Position+camCF.LookVector)
    end)
    notify("Fly","✈ Fly Linear ON (No Fall Active)", 3)
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
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then fcKeysHeld[k] = true end
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
        if inp.Position.X > Cam.ViewportSize.X / 2 then
            if not fcRotTouch then fcRotTouch = inp; fcRotLast = inp.Position end
        else
            if not fcMoveTouch then fcMoveTouch = inp; fcMoveSt = inp.Position end
        end
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
    fcConns = {}; fcMoveTouch = nil; fcMoveSt = nil; fcRotTouch = nil; fcRotLast = nil; fcJoy = Vector2.zero; fcKeysHeld = {}
    FC._mouseRot = false; UIS.MouseBehavior = Enum.MouseBehavior.Default
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
        local frame = ctrl:FindFirstChild("TouchControlFrame")
        local thumb = frame and frame:FindFirstChild("DynamicThumbstickFrame")
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
                notify("Spectate", "❌ Target tidak valid!", 2); Spec.active = false; stopSpecLoop(); stopSpecCapture()
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
--  MAIN WINDOW
-- ══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title       = "@WTF.XKID",
    Subtitle    = "Script",
    Author      = "by @WTF.XKID",
    Folder      = "XKIDScript",
    Icon        = "ghost",
    Theme       = "Crimson",
    Acrylic     = true,
    Transparent = true,
    Size        = UDim2.fromOffset(520, 430),
    MinSize     = Vector2.new(420, 340),
    MaxSize     = Vector2.new(650, 500),
    ToggleKey   = Enum.KeyCode.RightShift,
    Resizable   = true,
    AutoScale   = true,
    NewElements = true,
    SideBarWidth= 145,
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
        Color = ColorSequence.new(
            Color3.fromRGB(225, 0, 120),
            Color3.fromRGB(0, 255, 255)
        ),
    },
    User = {
        Enabled   = true,
        Anonymous = false,
        Callback  = function()
            notify("@WTF.XKID", "Tiktok: @wtf.xkid\nDiscord: @4sharken", 4)
        end,
    },
})

getgenv()._XKID_INSTANCE = Window.Instance
WindUI:SetTheme("Crimson")

-- ══════════════════════════════════════════════════════════════
--  TAB 1: HOME SCREEN
-- ══════════════════════════════════════════════════════════════
local T_HOME = Window:Tab({ Title = "Home", Icon = "home" })

local secWelcome = T_HOME:Section({ Title = "⚡XKID HUB", Opened = true })
secWelcome:Paragraph({ Title = "Welcome Back", Desc  = "Script Loaded Successfully.\n📱 Tiktok: @wtf.xkid\n💬 Discord: @4sharken" })

local secStatus = T_HOME:Section({ Title = "📊 Live System Monitor", Opened = true })
local mapLabel = secStatus:Paragraph({ Title = "🗺️ Map", Desc  = "Loading..." })
local fpsLabel = secStatus:Paragraph({ Title = "⚡ FPS", Desc  = "---" })
local pingLabel = secStatus:Paragraph({ Title = "📡 Ping", Desc  = "--- ms" })

local secSecurity = T_HOME:Section({ Title = "🛡️ Security Status", Opened = true })
local securityLabel = secSecurity:Paragraph({ Title = "Protection Active", Desc  = "✅ Script Protected\n✅ Anti-Crash Enabled\n✅ Memory Optimized" })

local secChangelog = T_HOME:Section({ Title = "📋 Changelog", Opened = false })
secChangelog:Paragraph({ Title = "Latest Updates", Desc  = "• NEW: Utility & Security Features\n• NEW: Custom Atmosphere Sliders & FOV\n• NEW: Auto Rejoin & Server Tools\n• OPTIMIZED: UI & Memory" })

local fpsSamples = {}
TrackC(RS.RenderStepped:Connect(function(dt)
    table.insert(fpsSamples, dt)
    if #fpsSamples > 30 then table.remove(fpsSamples,1) end
end))

task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(0.3)
        pcall(function()
            local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
            if placeName and mapLabel then mapLabel:SetDesc("📍 " .. (#placeName > 25 and placeName:sub(1, 22) .. "..." or placeName)) end
        end)
        
        if fpsLabel then
            local fps = 0
            if #fpsSamples > 0 then
                local avg = 0; for _, s in ipairs(fpsSamples) do avg = avg + s end; fps = math.floor(1 / (avg / #fpsSamples))
            end
            fpsLabel:SetDesc((fps >= 60 and "🟢" or (fps >= 30 and "🟡" or "🔴")) .. " " .. fps .. " FPS")
        end
        
        if pingLabel then
            local ping = 0
            pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            pingLabel:SetDesc((ping < 100 and "🟢" or (ping < 200 and "🟡" or "🔴")) .. " " .. ping .. " ms")
        end
        
        if securityLabel then
            local playerCount = #Players:GetPlayers()
            local antiAFKStatus = State.Security.afkConn and "✅" or "⭕"
            local antiLagStatus = State.Security.antiLag and "✅" or "⭕"
            local shiftLockStatus = State.Security.shiftLock and "🔒" or "🔓"
            local securityText = string.format("🛡️ Script: Active\n👥 Players: %d\n⏰ Anti-AFK: %s\n🔒 Shift Lock: %s\n⚡ Anti-Lag: %s\n💾 Memory: GC Running", playerCount, antiAFKStatus, shiftLockStatus, antiLagStatus)
            securityLabel:SetDesc(securityText)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 2: AVATAR & PLAYER
-- ══════════════════════════════════════════════════════════════
local T_AV = Window:Tab({ Title = "Player", Icon = "user" })

local secAvatar = T_AV:Section({ Title = "Avatar Refresh", Opened = true })
secAvatar:Button({ Title = "Fast Respawn", Desc = "Respawn instan — tetap di posisi kematian", Callback = function() fastRespawn() end })
secAvatar:Button({ Title = "Refresh Character", Desc = "Reload character tanpa kill — tetap di posisi semula", Callback = function() refreshCharacter() end })

local secMov = T_AV:Section({ Title = "Movement", Opened = true })
secMov:Slider({ Title = "Walk Speed", Desc = "Default: 16", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = tonumber(v) or 16; if getHum() then getHum().WalkSpeed = State.Move.ws end end })
secMov:Slider({ Title = "Jump Power", Desc = "Default: 50", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = tonumber(v) or 50; local hum = getHum(); if hum then hum.UseJumpPower=true; hum.JumpPower=State.Move.jp end end })
secMov:Toggle({ Title = "Infinite Jump", Desc = "Jump continuously", Value = false, Callback = function(v)
    if v then State.Move.infJ = TrackC(UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end))
    else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ=nil end end
end})

local secAbi = T_AV:Section({ Title = "Abilities", Opened = true })
secAbi:Toggle({ Title = "Fly", Desc = "Fly following camera direction (Auto No-Fall Damage)", Value = false, Callback = function(v) toggleFly(v) end })
secAbi:Slider({ Title = "Fly Speed", Desc = "Default: 60", Step = 1, Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(v) State.Move.flyS = tonumber(v) or 60 end })
secAbi:Toggle({ Title = "NoClip", Desc = "Walk through walls", Value = false, Callback = function(v) State.Move.ncp = v end })
secAbi:Toggle({ Title = "Soft Fling", Desc = "Gentle collision", Value = false, Callback = function(v) State.SoftFling.active=v; State.Move.ncp=v end })

-- ══════════════════════════════════════════════════════════════
--  TAB 3: TELEPORT
-- ══════════════════════════════════════════════════════════════
local T_TP = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

local secTP = T_TP:Section({ Title = "Teleport Tool", Opened = true })
secTP:Toggle({ Title = "Click Teleport (Tool)", Desc = "Equip Tool di layar/backpack dan klik area untuk TP", Value = false, Callback = function(v)
    if v then
        local tool = Instance.new("Tool")
        tool.Name = "Click TP"; tool.RequiresHandle = false; tool.Parent = LP.Backpack
        State.Teleport.clickTool = tool
        State.Teleport.clickConn = tool.Activated:Connect(function()
            local mouse = LP:GetMouse(); local hrp = getRoot()
            if hrp and mouse.Hit then hrp.CFrame = mouse.Hit + Vector3.new(0, 3, 0) end
        end)
        notify("Click TP", "✅ Tool 'Click TP' diberikan ke Backpack!", 2)
    else
        if State.Teleport.clickTool then State.Teleport.clickTool:Destroy(); State.Teleport.clickTool = nil end
        if State.Teleport.clickConn then State.Teleport.clickConn:Disconnect(); State.Teleport.clickConn = nil end
        notify("Click TP", "❌ Tool dihapus", 2)
    end
end})

local secTPO = T_TP:Section({ Title = "Player Teleport", Opened = true })
local tpTarget = ""
local function refreshPlayerLists() return getDisplayNames() end

secTPO:Input({ Title = "Search Player", Desc = "Type player name", Placeholder = "player name...", Callback = function(v) tpTarget = v end })
secTPO:Button({ Title = "Teleport", Desc = "Teleport to searched player", Callback = function()
    local success, err = pcall(function()
        if tpTarget == "" then notify("Teleport", "❌ Masukkan nama player!", 2); return end
        local targetPlayer = nil
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                local nl, dl, tl = string.lower(p.Name), string.lower(p.DisplayName), string.lower(tpTarget)
                if string.find(nl, tl) or string.find(dl, tl) then targetPlayer = p; break end
            end
        end
        if not targetPlayer or not targetPlayer.Parent or not targetPlayer.Character then notify("Teleport", "❌ Player tidak valid/spawn!", 2); return end
        local tHrp, tHum, myHrp = getCharRoot(targetPlayer.Character), targetPlayer.Character:FindFirstChildOfClass("Humanoid"), getRoot()
        if not tHrp or not tHum or not myHrp or tHum.Health <= 0 then notify("Teleport", "❌ Gagal mendapatkan posisi / Target mati!", 2); return end
        myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3) + Vector3.new(0, 2, 0); myHrp.AssemblyLinearVelocity = Vector3.zero
        notify("Teleport", "✅ TP ke "..targetPlayer.DisplayName, 2)
    end)
    if not success then notify("Teleport", "❌ Error: "..tostring(err), 3) end
end})

local pDropOpts = refreshPlayerLists()
local tpDropdown = secTPO:Dropdown({ Title = "Player List", Desc = "Select from list", Values = pDropOpts, Callback = function(v) tpTarget = v end })
secTPO:Button({ Title = "Refresh List", Desc = "Update player list", Callback = function()
    local newList = refreshPlayerLists(); pcall(function() tpDropdown:Refresh(newList, true) end)
    notify("Teleport", "✅ List updated! "..#newList.." players", 2)
end})

local secLoc = T_TP:Section({ Title = "Save & Load Location", Opened = true })
local SavedLocs = {}
for i = 1, 3 do
    secLoc:Button({ Title = "💾 Save Slot "..i, Callback = function()
        local r = getRoot(); if not r then notify("Location", "❌ Character not found", 2); return end
        SavedLocs[i] = r.CFrame; notify("Location", "✅ Slot "..i.." saved!", 2)
    end})
    secLoc:Button({ Title = "📍 Load Slot "..i, Callback = function()
        if not SavedLocs[i] then notify("Location", "❌ Slot "..i.." empty!", 2); return end
        local r = getRoot(); if not r then notify("Location", "❌ Character not found", 2); return end
        r.CFrame = SavedLocs[i]; notify("Location", "✅ Teleported to Slot "..i, 2)
    end})
end

-- ══════════════════════════════════════════════════════════════
--  TAB 4: CAMERA & SPECTATE
-- ══════════════════════════════════════════════════════════════
local T_CAM = Window:Tab({ Title = "Camera", Icon = "eye" })
local secFC = T_CAM:Section({ Title = "Freecam", Opened = true })
secFC:Toggle({ Title = "Freecam", Desc = "PC: RMB rotate | Mobile: Left move / Right rotate", Value = false, Callback = function(v)
    FC.active = v; State.Cinema.active = v
    if v then
        local cf=Cam.CFrame; FC.pos=cf.Position; local rx,ry=cf:ToEulerAnglesYXZ(); FC.pitchDeg=math.deg(rx); FC.yawDeg=math.deg(ry)
        local hrp=getRoot(); local hum=getHum(); if hrp then FC.savedCF=hrp.CFrame; hrp.Anchored=true end
        if hum then hum.WalkSpeed=0; hum.JumpPower=0; hum:ChangeState(Enum.HumanoidStateType.Physics) end
        startFreecamCapture(); startFreecamLoop(); notify("Freecam","🎬 ON", 2)
    else
        stopFreecamLoop(); stopFreecamCapture()
        local hrp=getRoot(); local hum=getHum(); if hrp then hrp.Anchored=false; if FC.savedCF then hrp.CFrame=FC.savedCF; FC.savedCF=nil end end
        if hum then hum.WalkSpeed=State.Move.ws; hum.UseJumpPower=true; hum.JumpPower=State.Move.jp; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        Cam.CameraType=Enum.CameraType.Custom; notify("Freecam","🎬 OFF", 2)
    end
end})
secFC:Slider({ Title="Speed", Step=0.5, Value={Min=1, Max=20, Default=3}, Callback=function(v) FC.speed = tonumber(v) or 3 end })
secFC:Slider({ Title="Sensitivity", Step=1, Value={Min=1, Max=20, Default=5}, Callback=function(v) FC.sens = (tonumber(v) or 5)*0.05 end })

local secSP = T_CAM:Section({ Title = "Spectate Player", Opened = true })
local specDropOpts = getDisplayNames()
local specDropdown = secSP:Dropdown({ Title = "Target Player", Values = specDropOpts, Callback = function(v)
    local success, p = pcall(function() return findPlayerByDisplay(v) end)
    if success and p then
        Spec.target = p
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ(); Spec.orbitYaw = math.deg(ry); Spec.orbitPitch = 20; Spec.fpYaw = math.deg(ry); Spec.fpPitch = 0
        end
        notify("Spectate", "✅ Target: "..p.DisplayName, 2)
    else notify("Spectate", "❌ Player tidak valid!", 2) end
end})
secSP:Button({ Title = "🔄 Refresh List", Callback = function()
    specDropOpts = getDisplayNames(); pcall(function() specDropdown:Refresh(specDropOpts, true) end)
    notify("Spectate", "✅ List updated!", 2)
end})
secSP:Toggle({ Title = "Spectate ON", Value = false, Callback = function(v)
    Spec.active = v
    if v then
        if not Spec.target or not Spec.target.Parent or not Spec.target.Character or not Spec.target.Character:FindFirstChild("HumanoidRootPart") then
            notify("Spectate", "❌ Select valid target first!", 2); Spec.active = false; return
        end
        Spec.origFov = Cam.FieldOfView; startSpecCapture(); startSpecLoop(); notify("Spectate", "👁 Spectating: "..Spec.target.DisplayName, 2)
    else
        stopSpecLoop(); stopSpecCapture(); Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov; notify("Spectate", "❌ Off", 2)
    end
end})
secSP:Toggle({ Title = "First Person Mode", Value = false, Callback = function(v) Spec.mode = v and "first" or "third" end })
secSP:Slider({ Title = "Orbit Distance", Step = 1, Value = {Min = 3, Max = 30, Default = 8}, Callback = function(v) Spec.dist = tonumber(v) or 8 end })

-- ══════════════════════════════════════════════════════════════
--  TAB 5: WORLD (AESTHETIC HD FILTERS)
-- ══════════════════════════════════════════════════════════════
local T_WO = Window:Tab({ Title = "World", Icon = "globe" })

local secFilter = T_WO:Section({ Title = "Aesthetic HD Filters", Opened = true })

local function resetLighting()
    for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" then v:Destroy() end end
    Lighting.ClockTime = 14; Lighting.Brightness = 1; Lighting.ExposureCompensation = 0
    Lighting.Ambient = Color3.fromRGB(127, 127, 127); Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    Lighting.ColorShift_Bottom = Color3.new(0, 0, 0); Lighting.ColorShift_Top = Color3.new(0, 0, 0)
    Lighting.FogEnd = 100000
    notify("Filter", "✅ Lighting direset ke Default!", 2)
end

local function applyFilter(filter)
    for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" then v:Destroy() end end
    if filter == "Default" then resetLighting(); return end
    local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "_XKID_FILTER"; cc.Parent = Lighting
    local bloom = Instance.new("BloomEffect"); bloom.Name = "_XKID_FILTER"; bloom.Parent = Lighting

    if filter == "Dark Map HD" then cc.Saturation = -0.3; cc.Contrast = 0.5; cc.Brightness = -0.2; bloom.Intensity = 0.1; Lighting.ClockTime = 2
    elseif filter == "Ultra HD" then cc.Saturation = 0.2; cc.Contrast = 0.3; cc.Brightness = 0.1; bloom.Intensity = 0.2; Lighting.ClockTime = 14
    elseif filter == "Sharp Visual HD" then cc.Saturation = 0.1; cc.Contrast = 0.4; cc.Brightness = 0; bloom.Intensity = 0; Lighting.ClockTime = 12
    elseif filter == "Realistic HD" then cc.Saturation = 0.1; cc.Contrast = 0.2; cc.Brightness = 0.1; bloom.Intensity = 0.15; Lighting.ClockTime = 15
    elseif filter == "Night HD" then cc.TintColor = Color3.fromRGB(180, 180, 255); cc.Saturation = 0.1; cc.Contrast = 0.3; cc.Brightness = -0.1; bloom.Intensity = 0.1; Lighting.ClockTime = 0
    elseif filter == "Luxury HD" then cc.TintColor = Color3.fromRGB(255, 230, 200); cc.Saturation = 0.3; cc.Contrast = 0.3; cc.Brightness = 0.1; bloom.Intensity = 0.4; Lighting.ClockTime = 17
    elseif filter == "Soft dreamy pastel HD" then cc.TintColor = Color3.fromRGB(255, 225, 235); cc.Saturation = -0.1; cc.Contrast = -0.1; bloom.Intensity = 0.6; bloom.Size = 40; Lighting.ClockTime = 8 end
    notify("Filter", "✅ " .. filter .. " Applied!", 2)
end

secFilter:Button({ Title="🎬 Dark Map HD", Callback = function() applyFilter("Dark Map HD") end })
secFilter:Button({ Title="💎 Ultra HD", Callback = function() applyFilter("Ultra HD") end })
secFilter:Button({ Title="👁 Sharp Visual HD", Callback = function() applyFilter("Sharp Visual HD") end })
secFilter:Button({ Title="🌍 Realistic HD", Callback = function() applyFilter("Realistic HD") end })
secFilter:Button({ Title="🌃 Night HD", Callback = function() applyFilter("Night HD") end })
secFilter:Button({ Title="✨ Luxury HD", Callback = function() applyFilter("Luxury HD") end })
secFilter:Button({ Title="☁ Soft dreamy pastel HD", Callback = function() applyFilter("Soft dreamy pastel HD") end })

local secAtmos = T_WO:Section({ Title = "Custom Atmosphere Sliders", Opened = false })
local function getEff(className)
    for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" and v:IsA(className) then return v end end
    local e = Instance.new(className); e.Name = "_XKID_FILTER"; e.Parent = Lighting; return e
end

secAtmos:Slider({ Title="Brightness", Step=0.1, Value={Min=0, Max=10, Default=1}, Callback=function(v) Lighting.Brightness = tonumber(v) or 1 end })
secAtmos:Slider({ Title="Exposure", Step=0.1, Value={Min=-5, Max=5, Default=0}, Callback=function(v) Lighting.ExposureCompensation = tonumber(v) or 0 end })
secAtmos:Slider({ Title="ClockTime", Step=0.1, Value={Min=0, Max=24, Default=14}, Callback=function(v) Lighting.ClockTime = tonumber(v) or 14 end })
secAtmos:Slider({ Title="Contrast", Step=0.1, Value={Min=-2, Max=2, Default=0}, Callback=function(v) getEff("ColorCorrectionEffect").Contrast = tonumber(v) or 0 end })
secAtmos:Slider({ Title="Bloom", Step=0.1, Value={Min=0, Max=5, Default=0}, Callback=function(v) getEff("BloomEffect").Intensity = tonumber(v) or 0 end })
secAtmos:Button({ Title="🔄 Reset Sliders", Callback = function() applyFilter("Default") end })

local secCamW = T_WO:Section({ Title = "Camera Settings", Opened = false })
secCamW:Slider({ Title="Player Camera FOV", Desc="Mengubah Field of View asli Player", Step=1, Value={Min=10, Max=120, Default=70}, Callback=function(v) Cam.FieldOfView = tonumber(v) or 70 end })

local secGfx = T_WO:Section({ Title = "Graphics Menu", Opened = false })
local gfxMap = { [1] = "Level01", [2] = "Level03", [3] = "Level05", [4] = "Level07", [5] = "Level09", [6] = "Level11", [7] = "Level13", [8] = "Level15", [9] = "Level17", [10] = "Level21" }
secGfx:Slider({
    Title = "Roblox Graphics Level", Desc  = "Sesuai dengan 1-10 bar di Esc Menu", Step  = 1, Value = {Min = 1, Max = 10, Default = 5},
    Callback = function(v)
        local levelNum = tonumber(v)
        if levelNum and gfxMap[levelNum] then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel[gfxMap[levelNum]]; notify("Graphics", "✅ Set to Graphic Level "..tostring(levelNum), 2) end) end
    end
})

-- ══════════════════════════════════════════════════════════════
--  TAB 6: HYBRID ESP
-- ══════════════════════════════════════════════════════════════
local T_ESP = Window:Tab({ Title = "ESP", Icon = "radar" })

local secESP = T_ESP:Section({ Title = "Hybrid Detection ESP", Opened = true })
secESP:Toggle({ Title="Enable ESP", Value=false, Callback=function(v)
    State.ESP.active = v
    if not v and getgenv()._XKID_ESP_CACHE then
        for _,c in pairs(getgenv()._XKID_ESP_CACHE) do pcall(function() c.texts.Visible=false; c.tracer.Visible=false; for _,l in ipairs(c.boxLines) do l.Visible=false end; c.hl.Enabled=false end) end
    end
end})
secESP:Dropdown({ Title="Tracer Mode", Values={"Bottom","Center","Mouse","OFF"}, Value="Bottom", Callback=function(v) State.ESP.tracerMode=v end })
secESP:Toggle({ Title="Show Distance", Value=true, Callback=function(v) State.ESP.showDistance=v end })
secESP:Toggle({ Title="Show Name", Value=true, Callback=function(v) State.ESP.showNickname=v end })
secESP:Toggle({ Title="Highlight Mode (All)", Value=false, Callback=function(v) State.ESP.highlightMode=v end })
secESP:Slider({ Title="Draw Distance", Step=10, Value={Min=50,Max=500,Default=300}, Callback=function(v) State.ESP.maxDrawDistance=tonumber(v) or 300 end })

local secESPColor = T_ESP:Section({ Title = "🎨 ESP Colors", Opened = false })
secESPColor:Dropdown({ Title="Normal Tracer", Values={"Hijau", "Merah", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam"}, Value="Hijau", Callback=function(v) if colorMap[v] then State.ESP.tracerColor_N = colorMap[v] end end })
secESPColor:Dropdown({ Title="Suspect (Map Blocker)", Values={"Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam", "Crimson"}, Value="Crimson", Callback=function(v) if colorMap[v] then State.ESP.boxColor_S = colorMap[v]; State.ESP.tracerColor_S = colorMap[v] end end })
secESPColor:Dropdown({ Title="Glitch Accessory", Values={"Orange", "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Pink", "Putih", "Hitam"}, Value="Orange", Callback=function(v) if colorMap[v] then State.ESP.boxColor_G = colorMap[v]; State.ESP.tracerColor_G = colorMap[v] end end })
secESPColor:Dropdown({ Title="Text/Name", Values={"Putih", "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Hitam"}, Value="Putih", Callback=function(v) if colorMap[v] then State.ESP.nameColor = colorMap[v] end end })

-- ══════════════════════════════════════════════════════════════
--  TAB 7: UTILITY / SECURITY
-- ══════════════════════════════════════════════════════════════
local T_SEC = Window:Tab({ Title = "Utility/Security", Icon = "shield" })

local secProt = T_SEC:Section({ Title = "Protection", Opened = true })
secProt:Toggle({ Title="Anti Void", Desc="Otomatis TP ke atas jika jatuh keluar map", Value=false, Callback=function(v)
    if v then
        State.Security.voidConn = TrackC(RS.Heartbeat:Connect(function()
            local hrp = getRoot(); if hrp and hrp.Position.Y <= workspace.FallenPartsDestroyHeight + 50 then hrp.Velocity = Vector3.zero; hrp.CFrame = hrp.CFrame + Vector3.new(0, 300, 0); notify("Anti Void", "Jatuh ke void! Diselamatkan.", 2) end
        end))
        notify("Anti Void","✅ Active", 2)
    else
        if State.Security.voidConn then State.Security.voidConn:Disconnect(); State.Security.voidConn=nil end
        notify("Anti Void","❌ Disabled", 2)
    end
end})
secProt:Toggle({ Title="Anti Fall (No Fall Damage)", Desc="Memblokir kecepatan jatuh / fall damage", Value=false, Callback=function(v)
    if v then
        State.Security.fallConn = TrackC(RS.Heartbeat:Connect(function()
            local hrp = getRoot(); if hrp and hrp.Velocity.Y < -30 then hrp.Velocity = Vector3.new(hrp.Velocity.X, -10, hrp.Velocity.Z) end
        end))
        notify("Anti Fall","✅ Active", 2)
    else
        if State.Security.fallConn then State.Security.fallConn:Disconnect(); State.Security.fallConn=nil end
        notify("Anti Fall","❌ Disabled", 2)
    end
end})
secProt:Toggle({ Title="Anti-AFK", Desc="Mencegah kick 20 menit dari Roblox (Otomatis berjalan!)", Value=true, Callback=function(v)
    if v then
        if not State.Security.afkConn then
            State.Security.afkConn = TrackC(LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); task.wait(1) end))
        end
        notify("Anti-AFK","✅ Active", 2)
    else
        if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn=nil end
        notify("Anti-AFK","❌ Disabled", 2)
    end
end})
secProt:Button({ Title="Stuck Fix", Desc="Lepaskan karakter jika nyangkut / glitch", Callback=function()
    local hrp, hum = getRoot(), getHum()
    if hrp then hrp.Anchored = false; hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
    if hum then hum.Sit = false; hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    notify("Stuck Fix", "Mencoba melepaskan karakter...", 2)
end})

local secSrv = T_SEC:Section({ Title = "Server & Network Tools", Opened = true })
secSrv:Toggle({ Title="Auto Rejoin", Desc="Otomatis rejoin saat terdeteksi koneksi putus/kick", Value=false, Callback=function(v)
    if v then
        State.Security.arConn = TrackC(CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
                notify("Auto Rejoin", "Terputus! Rejoining...", 3)
                TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
            end
        end))
    else
        if State.Security.arConn then State.Security.arConn:Disconnect(); State.Security.arConn=nil end
    end
end})
secSrv:Button({ Title="Rejoin Same Server", Desc="Masuk kembali ke server yang SAMA", Callback=function() 
    notify("Rejoin", "🔄 Rejoining Same Server...", 2)
    TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) 
end})
secSrv:Button({ Title="Low Player Server", Desc="Server Hop ke server sepi (Butuh Executor Support)", Callback=function() 
    notify("Server Hop", "Mencari server sepi...", 2)
    pcall(function()
        local Http = game:GetService("HttpService")
        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if req then
            local res = req({Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100", Method = "GET"})
            if res.StatusCode == 200 then
                local body = Http:JSONDecode(res.Body)
                if body and body.data then
                    for _, v in ipairs(body.data) do
                        if v.playing < v.maxPlayers and v.id ~= game.JobId then TPService:TeleportToPlaceInstance(game.PlaceId, v.id, LP); return end
                    end
                end
            end
        end
        notify("Server Hop", "Gagal (Executor API kurang / Server penuh)", 3)
    end)
end})

-- Ping Spike Alert
task.spawn(function()
    local lastSpike = 0
    while getgenv()._XKID_RUNNING do
        task.wait(2)
        pcall(function()
            local ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
            if ping > 250 and (tick() - lastSpike > 10) then
                lastSpike = tick()
                notify("⚠ Ping Spike Alert", "Koneksi tidak stabil: " .. ping .. " ms", 3)
            end
        end)
    end
end)

local secPerf = T_SEC:Section({ Title = "Performance", Opened = true })
secPerf:Button({ Title="FPS Boost Advance", Desc="Menghapus semua tekstur, shadow, material, & partikel", Callback=function() 
    settings().Rendering.QualityLevel = 1
    Lighting.GlobalShadows = false
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false; v.Transparency = 1 end
    end
    notify("FPS Boost", "Advanced Boost Activated!", 2)
end})

local antiLag = { mats={}, texs={}, shadows=true }
secPerf:Toggle({ Title="Anti Lag Mode (Simple)", Desc="Remove textures & shadows (bisa di-reset)", Value=false, Callback=function(v)
    State.Security.antiLag = v
    if v then
        antiLag.shadows=Lighting.GlobalShadows; Lighting.GlobalShadows=false
        for _,obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then antiLag.mats[obj]=obj.Material; obj.Material=Enum.Material.SmoothPlastic
            elseif obj:IsA("Texture") or obj:IsA("Decal") then antiLag.texs[obj]=obj.Parent; obj.Parent=nil end
        end
        notify("Anti Lag","✅ Active", 2)
    else
        Lighting.GlobalShadows=antiLag.shadows
        for obj,mat in pairs(antiLag.mats) do if obj and obj.Parent then obj.Material=mat end end
        for obj,par in pairs(antiLag.texs) do if obj and par and par.Parent then obj.Parent=par end end
        antiLag.mats={}; antiLag.texs={}
    end
end})

local secCameraLock = T_SEC:Section({ Title = "🔒 Camera Lock", Opened = true })
secCameraLock:Toggle({ Title="Shift Lock", Desc="Lock character rotation to camera (Mobile Ready)", Value=false, Callback=function(v) toggleShiftLock(v) end })

-- ══════════════════════════════════════════════════════════════
--  TAB 8: SETTINGS
-- ══════════════════════════════════════════════════════════════
local T_SET = Window:Tab({ Title = "Settings", Icon = "settings" })
local secTheme = T_SET:Section({ Title = "Appearance", Opened = true })
secTheme:Dropdown({ Title="Theme", Values=(function() local names={}; for name in pairs(WindUI:GetThemes()) do table.insert(names,name) end; table.sort(names); if not table.find(names, "Crimson") then table.insert(names, 1, "Crimson") end; return names end)(), Value="Crimson", Callback=function(selected) WindUI:SetTheme(selected) end })
secTheme:Toggle({ Title="Acrylic Background", Value=true, Callback=function() WindUI:ToggleAcrylic(not WindUI.Window.Acrylic) end })
secTheme:Toggle({ Title="Transparent Window", Value=true, Callback=function(state) Window:ToggleTransparency(state) end })
local currentKey = Enum.KeyCode.RightShift
secTheme:Keybind({ Title="Toggle Key", Value=currentKey, Callback=function(v) currentKey = (typeof(v)=="EnumItem") and v or Enum.KeyCode[v]; Window:SetToggleKey(currentKey) end })

-- ══════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS & STARTUP
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if (State.Fling.active or State.SoftFling.active) and getRoot() then
            local r, brutal = getRoot(), State.Fling.active
            local pwr = brutal and State.Fling.power or State.SoftFling.power
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

-- Memantau FPS untuk Crash Detection
task.spawn(function()
    local dropTime = 0
    while getgenv()._XKID_RUNNING do
        task.wait(1)
        local fps = 60
        if #fpsSamples > 0 then
            local avg = 0; for _, s in ipairs(fpsSamples) do avg = avg + s end; fps = math.floor(1 / (avg / #fpsSamples))
        end
        if fps < 15 then dropTime = dropTime + 1 else dropTime = 0 end
        
        if dropTime >= 5 and not State.Security.antiLag then
            notify("⚠ Crash Detection", "FPS sangat rendah! Mengaktifkan Anti-Lag otomatis...", 4)
            -- Memaksa eksekusi FPS Boost Advance untuk penyelamatan
            pcall(function() settings().Rendering.QualityLevel = 1; Lighting.GlobalShadows = false end)
            dropTime = 0
        end
    end
end)

-- Eksekusi otomatis Anti-AFK (Default Value = True, logic dijalan di awal)
if not State.Security.afkConn then
    State.Security.afkConn = TrackC(LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); task.wait(1) end))
end

WindUI:SetNotificationLower(true)
print("✅ @WTF.XKID Script Loaded | Ultimate Utility & Security")
