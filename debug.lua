--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    ✦  X K I D     H U B  ✦   FINAL WINDUI UPDATE            ║
║                                                              ║
║   ✅ WindUI Template Asli (Profil, Settings, Acrylic Aman)   ║
║   ✅ ESP Highlight Only (Tanpa Teks/Nama)                    ║
║   ✅ Smooth Freecam & Native Fly                             ║
║   ✅ No Crash / Blank Black Screen                           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
]]

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TPService = game:GetService("TeleportService")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- Global State
local State = {
    Move = {ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60},
    Fly = {active = false, bv = nil, bg = nil, _keys = {}},
    Fling = {active = false, power = 1000000},
    SoftFling = {active = false, power = 4000},
    Teleport = {selectedTarget = ""},
    Security = {afkConn = nil},
    Spectate = {hideName = false},
    ESP = {
        active = false, 
        cache = {},
        colorNormal = Color3.fromRGB(0, 255, 150),
        colorSuspect = Color3.fromRGB(255, 0, 100),
    }
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end
local function getDisplayNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")") end end
    return t
end
local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do if str == p.DisplayName .. " (@" .. p.Name .. ")" then return p end end
    return nil
end

-- Persistent Movement
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- ESP HIGHLIGHT ONLY (ANTI-GLITCHER)
-- ═══════════════════════════════════════════════════════════

local function isSuspectPlayer(player)
    local char = player.Character
    if not char then return false end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Size.X > 15 or part.Size.Y > 15 or part.Size.Z > 15 then
                return true
            end
        end
    end
    return false
end

local function clearESP()
    for _, cache in pairs(State.ESP.cache) do
        if cache.highlight then cache.highlight:Destroy() end
    end
    State.ESP.cache = {}
end

local function updateESP()
    if not State.ESP.active then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local char = player.Character
            if not State.ESP.cache[player] then State.ESP.cache[player] = {highlight = nil} end
            local cache = State.ESP.cache[player]
            
            local isSuspect = isSuspectPlayer(player)
            local color = isSuspect and State.ESP.colorSuspect or State.ESP.colorNormal
            
            if not cache.highlight or cache.highlight.Parent ~= char then
                if cache.highlight then cache.highlight:Destroy() end
                local hl = Instance.new("Highlight")
                hl.Parent = char
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                cache.highlight = hl
            end
            
            cache.highlight.FillColor = color
            cache.highlight.OutlineColor = Color3.new(1, 1, 1)
            cache.highlight.FillTransparency = 0.5
            cache.highlight.OutlineTransparency = 0
            cache.highlight.Enabled = true
        end
    end
end

RS.RenderStepped:Connect(function()
    if State.ESP.active then updateESP() end
end)

Players.PlayerRemoving:Connect(function(player)
    if State.ESP.cache[player] then
        if State.ESP.cache[player].highlight then State.ESP.cache[player].highlight:Destroy() end
        State.ESP.cache[player] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════
-- FLY ENGINE
-- ═══════════════════════════════════════════════════════════

local onMobile = not UIS.KeyboardEnabled
local flyMoveTouch, flyMoveSt, flyJoy = nil, nil, Vector2.zero
local flyConns = {}

local function startFlyCapture()
    local keysHeld = {}
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then keysHeld[k] = true end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp) keysHeld[inp.KeyCode] = false end))
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local half = Cam.ViewportSize.X / 2
        if inp.Position.X <= half then
            if not flyMoveTouch then flyMoveTouch = inp; flyMoveSt = inp.Position end
        end
    end))
    table.insert(flyConns, UIS.TouchMoved:Connect(function(inp)
        if inp == flyMoveTouch and flyMoveSt then
            local dx = inp.Position.X - flyMoveSt.X
            local dy = inp.Position.Y - flyMoveSt.Y
            local nx = math.abs(dx) > 25 and math.clamp((dx - math.sign(dx)*25)/80,-1,1) or 0
            local ny = math.abs(dy) > 20 and math.clamp((dy - math.sign(dy)*20)/80,-1,1) or 0
            flyJoy = Vector2.new(nx, ny)
        end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == flyMoveTouch then flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero end
    end))
    State.Fly._keys = keysHeld
end

local function stopFlyCapture()
    for _, c in ipairs(flyConns) do c:Disconnect() end
    flyConns = {}; flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero; State.Fly._keys = {}
end

local function toggleFly(v)
    if not v then
        State.Fly.active = false
        stopFlyCapture()
        RS:UnbindFromRenderStep("XKIDFly")
        if State.Fly.bv then State.Fly.bv:Destroy(); State.Fly.bv = nil end
        if State.Fly.bg then State.Fly.bg:Destroy(); State.Fly.bg = nil end
        local hum = getHum()
        if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.WalkSpeed = State.Move.ws; hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
        WindUI:Notify({Title = "Fly", Content = "✈️ Fly OFF", Duration = 2})
        return
    end

    local hrp, hum = getRoot(), getHum()
    if not hrp or not hum then return end

    State.Fly.active = true
    hum.PlatformStand = true
    State.Fly.bv = Instance.new("BodyVelocity", hrp)
    State.Fly.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    State.Fly.bv.Velocity  = Vector3.zero
    State.Fly.bg = Instance.new("BodyGyro", hrp)
    State.Fly.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    State.Fly.bg.P = 1e5

    startFlyCapture()
    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not State.Fly.active then return end
        local r, h = getRoot(), getHum()
        if not r or not h then return end
        local camCF = Cam.CFrame
        local spd  = State.Move.flyS
        local move = Vector3.zero
        local keys = State.Fly._keys or {}

        if onMobile then
            move = camCF.LookVector * (-flyJoy.Y) * spd + camCF.RightVector * flyJoy.X * spd
        else
            if keys[Enum.KeyCode.W] then move = move + camCF.LookVector end
            if keys[Enum.KeyCode.S] then move = move - camCF.LookVector end
            if keys[Enum.KeyCode.D] then move = move + camCF.RightVector end
            if keys[Enum.KeyCode.A] then move = move - camCF.RightVector end
            if keys[Enum.KeyCode.E] then move = move + Vector3.new(0,1,0) end
            if keys[Enum.KeyCode.Q] then move = move - Vector3.new(0,1,0) end
            if move.Magnitude > 0 then move = move.Unit * spd end
        end

        State.Fly.bv.Velocity = move
        State.Fly.bg.CFrame = CFrame.new(r.Position, r.Position + camCF.LookVector)
    end)
    WindUI:Notify({Title = "Fly", Content = "✈️ Fly ON", Duration = 3})
end

-- ═══════════════════════════════════════════════════════════
-- FREECAM ENGINE
-- ═══════════════════════════════════════════════════════════

local FC = {
    active = false, pos = Vector3.zero, vel = Vector3.zero,
    pitchDeg = 0, yawDeg = 0, speed = 1, sens = 0.25,
    savedCharCFrame = nil, damping = 0.85, acceleration = 0.15,
}
local fcRotTouch, fcMoveTouch, fcMoveSt, fcRotLast = nil, nil, nil, nil
local fcJoy = Vector2.zero
local DEAD_X, DEAD_Y = 25, 20
local fcConns = {}

local function startFCCapture()
    local keysHeld = {}
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then keysHeld[k] = true end
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mouseRotate = true; UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        keysHeld[inp.KeyCode] = false
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mouseRotate = false; UIS.MouseBehavior = Enum.MouseBehavior.Default end
    end))
    table.insert(fcConns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and FC._mouseRotate then
            FC.yawDeg = FC.yawDeg - inp.Delta.X * FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg - inp.Delta.Y * FC.sens, -80, 80)
        end
        if inp.UserInputType == Enum.UserInputType.MouseWheel then Cam.FieldOfView = math.clamp(Cam.FieldOfView - inp.Position.Z * 5, 10, 120) end
    end))
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local half = Cam.ViewportSize.X / 2
        if inp.Position.X > half then
            if not fcRotTouch then fcRotTouch = inp; fcRotLast = inp.Position end
        else
            if not fcMoveTouch then fcMoveTouch = inp; fcMoveSt = inp.Position end
        end
    end))
    table.insert(fcConns, UIS.TouchMoved:Connect(function(inp)
        if inp == fcRotTouch and fcRotLast then
            local dx = inp.Position.X - fcRotLast.X
            local dy = inp.Position.Y - fcRotLast.Y
            FC.yawDeg = FC.yawDeg - dx * FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg - dy * FC.sens, -80, 80)
            fcRotLast = inp.Position
        end
        if inp == fcMoveTouch and fcMoveSt then
            local dx = inp.Position.X - fcMoveSt.X
            local dy = inp.Position.Y - fcMoveSt.Y
            local nx = math.abs(dx) > DEAD_X and math.clamp((dx - math.sign(dx) * DEAD_X) / 80, -1, 1) or 0
            local ny = math.abs(dy) > DEAD_Y and math.clamp((dy - math.sign(dy) * DEAD_Y) / 80, -1, 1) or 0
            fcJoy = Vector2.new(nx, ny)
        end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == fcRotTouch then fcRotTouch = nil; fcRotLast = nil end
        if inp == fcMoveTouch then fcMoveTouch = nil; fcMoveSt = nil; fcJoy = Vector2.zero end
    end))
    FC._keys = keysHeld
end

local function stopFCCapture()
    for _, c in ipairs(fcConns) do c:Disconnect() end
    fcConns = {}; fcRotTouch = nil; fcMoveTouch = nil; fcMoveSt = nil; fcRotLast = nil; fcJoy = Vector2.zero; FC._mouseRotate = false; FC._keys = {}
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

local function startFCLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable
        local cf = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local spd = FC.speed * 32
        local desiredVel = Vector3.zero
        local keys = FC._keys or {}

        if onMobile then
            desiredVel = cf.LookVector * (-fcJoy.Y) * spd + cf.RightVector * fcJoy.X * spd
        else
            if keys[Enum.KeyCode.W] then desiredVel = desiredVel + cf.LookVector * spd end
            if keys[Enum.KeyCode.S] then desiredVel = desiredVel - cf.LookVector * spd end
            if keys[Enum.KeyCode.D] then desiredVel = desiredVel + cf.RightVector * spd end
            if keys[Enum.KeyCode.A] then desiredVel = desiredVel - cf.RightVector * spd end
            if keys[Enum.KeyCode.E] then desiredVel = desiredVel + Vector3.new(0,1,0) * spd end
            if keys[Enum.KeyCode.Q] then desiredVel = desiredVel - Vector3.new(0,1,0) * spd end
        end

        FC.vel = FC.vel:Lerp(desiredVel, FC.acceleration * dt * 60)
        FC.vel = FC.vel * (FC.damping ^ (dt * 60))
        FC.pos = FC.pos + FC.vel * dt
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)

        local hrp, hum = getRoot(), getHum()
        if hrp and not hrp.Anchored then hrp.Anchored = true end
        if hum then
            if hum:GetState() ~= Enum.HumanoidStateType.Physics then hum:ChangeState(Enum.HumanoidStateType.Physics) end
            hum.WalkSpeed = 0; hum.JumpPower = 0
        end
    end)
end

local function stopFCLoop() RS:UnbindFromRenderStep("XKIDFreecam") end

-- ═══════════════════════════════════════════════════════════
-- SPECTATE ENGINE
-- ═══════════════════════════════════════════════════════════

local Spec = { active = false, target = nil, mode = "third", dist = 8, origFov = 70, orbitYaw = 0, orbitPitch = 0, fpYaw = 0, fpPitch = 0 }
local specTouchMain, specTouchPinch, specPinchDist = nil, {}, nil
local specPanDelta = Vector2.zero
local specConns = {}

local function inJoystickArea(pos)
    local ctrl = LP and LP.PlayerGui and LP.PlayerGui:FindFirstChild("TouchGui")
    if ctrl then
        local thumb = ctrl:FindFirstChild("TouchControlFrame") and ctrl.TouchControlFrame:FindFirstChild("DynamicThumbstickFrame")
        if thumb then
            local ap, as = thumb.AbsolutePosition, thumb.AbsoluteSize
            if pos.X >= ap.X and pos.Y >= ap.Y and pos.X <= ap.X+as.X and pos.Y <= ap.Y+as.Y then return true end
        end
    end
    return false
end

local function startSpecCapture()
    table.insert(specConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or not Spec.active or inp.UserInputType ~= Enum.UserInputType.Touch or inJoystickArea(inp.Position) then return end
        table.insert(specTouchPinch, inp)
        specTouchMain = (#specTouchPinch == 1) and inp or nil
    end))
    table.insert(specConns, UIS.InputChanged:Connect(function(inp)
        if not Spec.active or inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if #specTouchPinch == 1 and inp == specTouchMain then
            specPanDelta = specPanDelta + Vector2.new(inp.Delta.X, inp.Delta.Y)
        elseif #specTouchPinch >= 2 then
            local d = (specTouchPinch[1].Position - specTouchPinch[2].Position).Magnitude
            if specPinchDist then
                local diff = d - specPinchDist
                Cam.FieldOfView = math.clamp(Cam.FieldOfView - diff * 0.15, 10, 120)
                if Spec.mode == "third" then Spec.dist = math.clamp(Spec.dist - diff * 0.03, 3, 30) end
            end
            specPinchDist = d
        end
    end))
    table.insert(specConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        for i, v in ipairs(specTouchPinch) do if v == inp then table.remove(specTouchPinch, i); break end end
        specPinchDist = nil
        specTouchMain = (#specTouchPinch == 1) and specTouchPinch[1] or nil
    end))
end

local function stopSpecCapture()
    for _, c in ipairs(specConns) do c:Disconnect() end
    specConns = {}; specTouchMain = nil; specTouchPinch = {}; specPinchDist = nil; specPanDelta = Vector2.zero
end

local specLoop = nil
local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not Spec.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable
        local char = Spec.target and Spec.target.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local pan = specPanDelta; specPanDelta = Vector2.zero
        if Spec.mode == "third" then
            Spec.orbitYaw = Spec.orbitYaw + pan.X * 0.3
            Spec.orbitPitch = math.clamp(Spec.orbitPitch + pan.Y * 0.3, -75, 75)
            local orbitCF = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(-Spec.orbitYaw), 0) * CFrame.Angles(math.rad(-Spec.orbitPitch), 0, 0) * CFrame.new(0, 0, Spec.dist)
            Cam.CFrame = CFrame.new(orbitCF.Position, hrp.Position + Vector3.new(0, 1, 0))
        else
            local origin = (char:FindFirstChild("Head") and char.Head.Position) or (hrp.Position + Vector3.new(0, 1.5, 0))
            Spec.fpYaw = Spec.fpYaw - pan.X * 0.3
            Spec.fpPitch = math.clamp(Spec.fpPitch - pan.Y * 0.3, -85, 85)
            Cam.CFrame = CFrame.new(origin) * CFrame.Angles(0, math.rad(Spec.fpYaw), 0) * CFrame.Angles(math.rad(Spec.fpPitch), 0, 0)
        end
    end)
    specLoop = true
end
local function stopSpecLoop() RS:UnbindFromRenderStep("XKIDSpec"); specLoop = nil end

-- ═══════════════════════════════════════════════════════════
-- WINDOW CREATION (WINDUI TEMPLATE)
-- ═══════════════════════════════════════════════════════════

local Window = WindUI:CreateWindow({
    Title   = "✦ XKID HUB ✦",
    Author  = "by XKIDB4D",
    Folder  = "xkid_hub_v4",
    Icon    = "paint-bucket",
    Theme   = "Dark",
    Acrylic = true,
    Transparent = true,
    Size    = UDim2.fromOffset(680, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey  = Enum.KeyCode.RightShift,
    Resizable  = true,
    AutoScale  = true,
    NewElements = true,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    SideBarWidth = 200,
    Topbar = {
        Height      = 44,
        ButtonsType = "Default",
    },
    OpenButton = {
        Title = "My Hub",
        Icon = "zap",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 1,
        Color = ColorSequence.new(
            Color3.fromHex("#000000"),
            Color3.fromHex("#000000")
        ),
    },
    User = {
        Enabled  = true,
        Anonymous = false,
        Callback = function()
            print("user panel clicked")
        end,
    },
})

-- ==================== TAB: MAIN / TELEPORT ====================
local MainTab = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

MainTab:TextBox({
    Title = "Search Player (2-3 Huruf)",
    Callback = function(v) State.Teleport.selectedTarget = v end
})

MainTab:Button({
    Title = "🚀 Teleport To Target",
    Callback = function()
        local snippet = State.Teleport.selectedTarget
        if snippet == "" then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and (string.find(string.lower(p.Name), string.lower(snippet)) or string.find(string.lower(p.DisplayName), string.lower(snippet))) then
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    getRoot().CFrame = p.Character.HumanoidRootPart.CFrame
                    return
                end
            end
        end
    end
})

local pDropList = MainTab:Dropdown({
    Title = "Manual Player List",
    Values = getPNames(),
    Value = "",
    Callback = function(v) State.Teleport.selectedTarget = v end
})

MainTab:Button({
    Title = "🔄 Refresh Player List",
    Callback = function() pcall(function() pDropList:Refresh(getPNames()) end) end
})

local SavedLocs = {}
for i = 1, 3 do
    MainTab:Button({
        Title = "💾 Save Location to Slot " .. i,
        Callback = function()
            local r = getRoot()
            if r then SavedLocs[i] = r.CFrame; WindUI:Notify({Title="Saved", Content="Slot "..i, Duration=2}) end
        end
    })
    MainTab:Button({
        Title = "📍 Load Location Slot " .. i,
        Callback = function()
            if SavedLocs[i] and getRoot() then getRoot().CFrame = SavedLocs[i]; WindUI:Notify({Title="Loaded", Content="Slot "..i, Duration=2}) end
        end
    })
end

-- ==================== TAB: PLAYER ====================
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })

PlayerTab:Slider({ Title = "🏃 WalkSpeed", Min = 16, Max = 500, Value = 16, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
PlayerTab:Slider({ Title = "🦘 JumpPower", Min = 50, Max = 500, Value = 50, Callback = function(v) State.Move.jp = v; local hum = getHum(); if hum then hum.UseJumpPower = true; hum.JumpPower = v end end })

PlayerTab:Toggle({
    Title = "∞ Inf Jump", Value = false,
    Callback = function(v)
        if v then State.Move.infJ = UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end)
        else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end end
    end
})

PlayerTab:Toggle({ Title = "✈️ Native Fly", Value = false, Callback = toggleFly })
PlayerTab:Slider({ Title = "✈️ Fly Speed", Min = 10, Max = 300, Value = 60, Callback = function(v) State.Move.flyS = v end })
PlayerTab:Toggle({ Title = "👻 NoClip", Value = false, Callback = function(v) State.Move.ncp = v end })

local shiftLockConn = nil
PlayerTab:Toggle({
    Title = "🎯 Enable Shift Lock", Value = false,
    Callback = function(v)
        local hum, hrp = getHum(), getRoot()
        if not hum or not hrp then WindUI:Notify({Title="Error", Content="Karakter tidak ada!", Duration=2}); return end
        if v then
            hum.CameraOffset = Vector3.new(1.75, 0, 0); hum.AutoRotate = false
            shiftLockConn = RS.RenderStepped:Connect(function() local curHrp = getRoot(); if curHrp then local camLook = Cam.CFrame.LookVector; curHrp.CFrame = CFrame.new(curHrp.Position, curHrp.Position + Vector3.new(camLook.X, 0, camLook.Z)) end end)
        else
            if shiftLockConn then shiftLockConn:Disconnect(); shiftLockConn = nil end
            hum.CameraOffset = Vector3.zero; hum.AutoRotate = true
        end
    end
})

PlayerTab:Toggle({ Title = "💥 IY Fling (Brutal)", Value = false, Callback = function(v) State.Fling.active = v; State.Move.ncp = v end })
PlayerTab:Toggle({ Title = "💫 Soft Fling (Jatuh)", Value = false, Callback = function(v) State.SoftFling.active = v; State.Move.ncp = v end })

local noFallConn = nil
PlayerTab:Toggle({
    Title = "🛡️ No Fall Damage", Value = false,
    Callback = function(v)
        if v then noFallConn = RS.Heartbeat:Connect(function() local hrp = getRoot(); if hrp and hrp.Velocity.Y < -30 then hrp.Velocity = Vector3.new(hrp.Velocity.X, -10, hrp.Velocity.Z) end end)
        else if noFallConn then noFallConn:Disconnect(); noFallConn = nil end end
    end
})

local godConn, godRespawn, godLastPos = nil, nil, nil
PlayerTab:Toggle({
    Title = "🛡️ God Mode (Auto Respawn)", Value = false,
    Callback = function(v)
        if v then
            local hum = getHum(); if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
            godLastPos = getRoot() and getRoot().CFrame
            godRespawn = RS.Heartbeat:Connect(function() local r = getRoot(); if r then godLastPos = r.CFrame end end)
            godConn = RS.Heartbeat:Connect(function() local h = getHum(); if h then if h.Health < h.MaxHealth then h.Health = h.MaxHealth end; if h.MaxHealth ~= math.huge then h.MaxHealth = math.huge end end end)
            WindUI:Notify({Title="God Mode", Content="Aktif!", Duration=3})
        else
            if godConn then godConn:Disconnect(); godConn = nil end
            if godRespawn then godRespawn:Disconnect(); godRespawn = nil end
            local hum = getHum(); if hum then hum.MaxHealth = 100; hum.Health = 100 end
        end
    end
})

-- ==================== TAB: CINEMATIC ====================
local CineTab = Window:Tab({ Title = "Cinematic", Icon = "video" })

CineTab:Toggle({
    Title = "🎬 Freecam ON/OFF", Value = false,
    Callback = function(v)
        FC.active = v; State.Cinema.active = v
        if v then
            FC.pos = Cam.CFrame.Position; FC.vel = Vector3.zero
            local rx, ry = Cam.CFrame:ToEulerAnglesYXZ(); FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry)
            FC._keys = {}; FC._mouseRotate = false
            local hrp, hum = getRoot(), getHum()
            if hrp then FC.savedCharCFrame = hrp.CFrame; hrp.Anchored = true end
            if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum:ChangeState(Enum.HumanoidStateType.Physics) end
            startFCCapture(); startFCLoop()
            WindUI:Notify({Title="Freecam", Content="Kiri Gerak | Kanan Rotate", Duration=3})
        else
            stopFCLoop(); stopFCCapture()
            local hrp, hum = getRoot(), getHum()
            if hrp then hrp.Anchored = false; if FC.savedCharCFrame then hrp.CFrame = FC.savedCharCFrame; FC.savedCharCFrame = nil end end
            if hum then hum.WalkSpeed = State.Move.ws; hum.UseJumpPower = true; hum.JumpPower = State.Move.jp; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            Cam.FieldOfView = 70; Cam.CameraType = Enum.CameraType.Custom
        end
    end
})

CineTab:Slider({ Title = "⚡ Freecam Speed", Min = 1, Max = 30, Value = 5, Callback = function(v) FC.speed = v end })
CineTab:Slider({ Title = "🎯 Sensitivity", Min = 1, Max = 20, Value = 5, Callback = function(v) FC.sens = v * 0.05 end })
CineTab:Slider({ Title = "📊 Damping (Smoothness)", Min = 0.5, Max = 1, Value = 0.85, Callback = function(v) FC.damping = v end })
CineTab:Slider({ Title = "⚙️ Acceleration", Min = 0.05, Max = 0.5, Value = 0.15, Callback = function(v) FC.acceleration = v end })
CineTab:Slider({ Title = "🔍 Camera FOV", Min = 10, Max = 120, Value = 70, Callback = function(v) Cam.FieldOfView = v end })

CineTab:Button({ Title = "📱 Screen: Portrait", Callback = function() pcall(function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait end) end })
CineTab:Button({ Title = "📺 Screen: Landscape", Callback = function() pcall(function() LP.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight end) end })

-- ==================== TAB: SPECTATE ====================
local SpecTab = Window:Tab({ Title = "Spectate", Icon = "eye" })

local specDrop = SpecTab:Dropdown({
    Title = "Pilih Target",
    Values = getDisplayNames(),
    Value = "",
    Callback = function(v)
        local p = findPlayerByDisplay(v)
        if p then Spec.target = p; if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ(); Spec.orbitYaw = math.deg(ry); Spec.orbitPitch = 20; Spec.fpYaw = math.deg(ry); Spec.fpPitch = 0 end end
    end
})

SpecTab:Button({ Title = "🔄 Refresh List Target", Callback = function() Spec.target = nil; pcall(function() specDrop:Refresh(getDisplayNames()) end) end })

SpecTab:Toggle({ Title = "🙈 Hide Name in Notification", Value = false, Callback = function(v) State.Spectate.hideName = v end })

SpecTab:Toggle({
    Title = "👁️ Spectate ON/OFF", Value = false,
    Callback = function(v)
        Spec.active = v
        if v then
            if not Spec.target then WindUI:Notify({Title="Error", Content="Pilih target dulu!", Duration=2}); Spec.active = false; return end
            Spec.origFov = Cam.FieldOfView; startSpecCapture(); startSpecLoop()
            local dispName = State.Spectate.hideName and "[HIDDEN]" or Spec.target.DisplayName
            WindUI:Notify({Title="Spectate", Content="Nonton: " .. dispName, Duration=3})
        else
            stopSpecLoop(); stopSpecCapture(); Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov
        end
    end
})

SpecTab:Toggle({ Title = "🎥 Mode Drone (First Person)", Value = false, Callback = function(v)
    Spec.mode = v and "first" or "third"
    if v and Spec.target and Spec.target.Character then local _, ry, _ = Cam.CFrame:ToEulerAnglesYXZ(); local rx = math.asin(Cam.CFrame.LookVector.Y); Spec.fpYaw = math.deg(ry); Spec.fpPitch = math.deg(rx) end
end})

SpecTab:Slider({ Title = "📏 Jarak Orbit", Min = 3, Max = 30, Value = 8, Callback = function(v) Spec.dist = v end })

SpecTab:Button({ Title = "🔄 Fix POV / Reset Camera", Callback = function()
    local r, h = getRoot(), getHum()
    if not r or not h then return end
    Cam.CameraType = Enum.CameraType.Custom; task.wait(0.05); Cam.CameraType = Enum.CameraType.Scriptable; task.wait(0.05); Cam.CameraType = Enum.CameraType.Custom
    pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
end})

-- ==================== TAB: WORLD & PERF ====================
local WorldTab = Window:Tab({ Title = "World", Icon = "globe" })

local function setWeather(clock, bright, fogStart, fogEnd, fogR, fogG, fogB, ambR, ambG, ambB, density, offset, glare, halo)
    Lighting.ClockTime = clock; Lighting.Brightness = bright; Lighting.FogStart = fogStart; Lighting.FogEnd = fogEnd
    Lighting.FogColor = Color3.fromRGB(fogR, fogG, fogB); Lighting.Ambient = Color3.fromRGB(ambR, ambG, ambB)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Density = density; atm.Offset = offset; atm.Glare = glare; atm.Halo = halo
end

WorldTab:Button({ Title = "☀️ Set Cuaca: Cerah", Callback = function() setWeather(14, 2, 1000, 10000, 200,220,255, 120,120,120, 0.05, 0.1, 0.3, 0.2) end })
WorldTab:Button({ Title = "🌃 Set Cuaca: Malam", Callback = function() setWeather(0, 0.3, 2000, 20000, 10,10,30, 20,20,40, 0.02, 0.0, 0.0, 0.1) end })
WorldTab:Slider({ Title = "🕐 Set Waktu (ClockTime)", Min = 0, Max = 24, Value = 14, Callback = function(v) Lighting.ClockTime = v end })

WorldTab:Button({ Title = "🚀 Unlock FPS (999)", Callback = function() if setfpscap then setfpscap(999) end end })
WorldTab:Button({ Title = "🚀 Default FPS (60)", Callback = function() if setfpscap then setfpscap(60) end end })

local AntiLagState = { materials = {}, textures = {}, shadows = true }
WorldTab:Toggle({ Title = "🗑️ Anti Lag Mode (Hapus Tekstur)", Value = false, Callback = function(v)
    if v then
        AntiLagState.shadows = Lighting.GlobalShadows; Lighting.GlobalShadows = false
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then AntiLagState.materials[obj] = obj.Material; obj.Material = Enum.Material.SmoothPlastic
            elseif obj:IsA("Texture") or obj:IsA("Decal") then AntiLagState.textures[obj] = obj.Parent; obj.Parent = nil end
        end
    else
        Lighting.GlobalShadows = AntiLagState.shadows
        for obj, mat in pairs(AntiLagState.materials) do if obj and obj.Parent then obj.Material = mat end end
        for obj, parent in pairs(AntiLagState.textures) do if obj and parent and parent.Parent then obj.Parent = parent end end
        AntiLagState.materials = {}; AntiLagState.textures = {}
    end
end})

-- ==================== TAB: SECURITY & ESP ====================
local SecTab = Window:Tab({ Title = "Security", Icon = "shield" })

SecTab:Toggle({ Title = "🛡️ Anti-AFK (Bypass Kick)", Value = false, Callback = function(v)
    if v then
        State.Security.afkConn = LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); VirtualUser:Button2Down(Vector2.new(0,0), Cam.CFrame); task.wait(1); VirtualUser:Button2Up(Vector2.new(0,0), Cam.CFrame) end)
        pcall(function() for _, conn in pairs(getconnections(LP.Idled)) do conn:Disable() end end)
    else
        if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn = nil end
        pcall(function() for _, conn in pairs(getconnections(LP.Idled)) do conn:Enable() end end)
    end
end})

SecTab:Button({ Title = "🔄 Rejoin Server", Callback = function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end })

local respawnLastPos = nil
task.spawn(function() while true do task.wait(1); local r = getRoot(); local h = getHum(); if r and h and h.Health > 0 then respawnLastPos = r.CFrame end end end)
SecTab:Button({ Title = "💀 Fast Respawn ke Posisi", Callback = function()
    if not respawnLastPos or not getHum() then return end
    local savedCF = respawnLastPos; getHum().Health = 0
    task.spawn(function() local char = LP.CharacterAdded:Wait(); task.wait(0.3); local hrp = char:WaitForChild("HumanoidRootPart", 10); if hrp then hrp.CFrame = savedCF end end)
end})

SecTab:Toggle({ Title = "🎯 ESP Highlight ON/OFF", Value = false, Callback = function(v)
    State.ESP.active = v
    if not v then clearESP() end
end})

SecTab:Dropdown({ Title = "🎨 Highlight Color", Values = {"Green", "Red", "Blue", "White", "Yellow", "Purple"}, Value = "Green", Callback = function(v)
    local c = Color3.fromRGB(0, 255, 150)
    if v == "Green" then c = Color3.fromRGB(0, 255, 150) elseif v == "Red" then c = Color3.fromRGB(255, 50, 50) elseif v == "Blue" then c = Color3.fromRGB(0, 150, 255) elseif v == "White" then c = Color3.fromRGB(255, 255, 255) elseif v == "Yellow" then c = Color3.fromRGB(255, 255, 0) elseif v == "Purple" then c = Color3.fromRGB(150, 0, 255) end
    State.ESP.colorNormal = c
end})

-- ==================== TAB: SETTINGS ====================
local ThemeTab = Window:Tab({ Title = "Settings", Icon = "settings" })

ThemeTab:Dropdown({
    Title  = "Theme",
    Values = (function() local names = {}; for name in pairs(WindUI:GetThemes()) do table.insert(names, name) end; table.sort(names); return names end)(),
    Value    = WindUI:GetCurrentTheme(),
    Callback = function(selected) WindUI:SetTheme(selected) end,
})

ThemeTab:Toggle({
    Title = "Acrylic Mode",
    Value = WindUI.Window.Acrylic,
    Callback = function() WindUI:ToggleAcrylic(not WindUI.Window.Acrylic) end,
})

ThemeTab:Toggle({
    Title = "Transparent Background",
    Value = WindUI:GetTransparency(),
    Callback = function(state) Window:ToggleTransparency(state) end
})

local currentKey = Enum.KeyCode.RightShift
ThemeTab:Keybind({
    Title = "Toggle UI Key",
    Value = currentKey,
    Callback = function(v)
        currentKey = (typeof(v) == "EnumItem") and v or Enum.KeyCode[v]
        Window:SetToggleKey(currentKey)
    end,
})

UIS.InputBegan:Connect(function(input) if input.KeyCode == currentKey then Window:Toggle() end end)

-- ═══════════════════════════════════════════════════════════
-- BACKGROUND LOOPS (FLING & NOCLIP)
-- ═══════════════════════════════════════════════════════════

task.spawn(function()
    while true do
        if (State.Fling.active or State.SoftFling.active) and getRoot() then
            local r = getRoot()
            local isBrutal = State.Fling.active
            local pwr = isBrutal and State.Fling.power or State.SoftFling.power
            pcall(function() r.AssemblyAngularVelocity = Vector3.new(0, pwr, 0); if isBrutal then r.AssemblyLinearVelocity = Vector3.new(pwr, pwr, pwr) end end)
        end
        RS.RenderStepped:Wait()
    end
end)

RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active or State.SoftFling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

WindUI:Notify({Title = "PlayerHub", Content = "Welcome to XKID HUB!", Duration = 5})
