--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        ✦  X  K  I  D     H  U  B  ✦   FINAL  V.4           ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║   🎬 Freecam    👁️ Spectate    🌍 World    🗺️ Teleport      ║
║   ⚡ Player     🛡️ Security    🎮 Fly TP Freecam            ║
╚══════════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TPService = game:GetService("TeleportService")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- State
local State = {
    ws = 16,
    jp = 50,
    ncp = false,
    infJ = nil,
    flySpeed = 60,
    flyActive = false,
    flingActive = false,
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
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")") end
    end
    return t
end

local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do
        if str == p.DisplayName .. " (@" .. p.Name .. ")" then return p end
    end
    return nil
end

local onMobile = not UIS.KeyboardEnabled

-- ┌─────────────────────────────────────────────────────────┐
-- │              FLY ENGINE - THIRD PERSON                  │
-- │         KONTROL IDENTIK DENGAN FREECAM                  │
-- │         KARAKTER LOCK ROTASI IKUT KAMERA                │
-- └─────────────────────────────────────────────────────────┘
local flyData = {
    yaw = 0,
    pitch = 0,
    active = false,
    keys = {},
    joy = Vector2.zero,
    rotTouch = nil,
    moveTouch = nil,
    moveStart = nil,
    rotLast = nil,
    mouseRot = false,
    conns = {}
}

local function stopFly()
    if not flyData.active then return end
    flyData.active = false
    for _, c in ipairs(flyData.conns) do c:Disconnect() end
    flyData.conns = {}
    flyData.keys = {}
    flyData.mouseRot = false
    flyData.rotTouch = nil
    flyData.moveTouch = nil
    flyData.moveStart = nil
    flyData.rotLast = nil
    flyData.joy = Vector2.zero
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    RS:UnbindFromRenderStep("XKIDFlyTP")
    local hum = getHum()
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        hum.WalkSpeed = State.ws
        hum.JumpPower = State.jp
    end
    State.ncp = false
    Cam.CameraType = Enum.CameraType.Custom
    Library:Notification("Fly", "✈️ Fly OFF", 2)
end

local function startFly()
    if flyData.active then return end
    local hrp = getRoot()
    local hum = getHum()
    if not hrp or not hum then
        Library:Notification("Fly", "❌ Karakter tidak ditemukan!", 2)
        return
    end

    flyData.active = true
    hum.PlatformStand = true
    State.ncp = true

    local _, ry = Cam.CFrame:ToEulerAnglesYXZ()
    flyData.yaw = math.deg(ry)
    flyData.pitch = 0

    -- Input handlers
    table.insert(flyData.conns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then
            flyData.keys[k] = true
        end
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            flyData.mouseRot = true
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end))

    table.insert(flyData.conns, UIS.InputEnded:Connect(function(inp)
        flyData.keys[inp.KeyCode] = false
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            flyData.mouseRot = false
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end))

    table.insert(flyData.conns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and flyData.mouseRot then
            flyData.yaw = flyData.yaw - inp.Delta.X * 0.3
            flyData.pitch = math.clamp(flyData.pitch - inp.Delta.Y * 0.3, -80, 80)
        end
    end))

    -- Touch
    table.insert(flyData.conns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local half = Cam.ViewportSize.X / 2
        if inp.Position.X > half then
            if not flyData.rotTouch then flyData.rotTouch = inp; flyData.rotLast = inp.Position end
        else
            if not flyData.moveTouch then flyData.moveTouch = inp; flyData.moveStart = inp.Position end
        end
    end))

    table.insert(flyData.conns, UIS.TouchMoved:Connect(function(inp)
        if inp == flyData.rotTouch and flyData.rotLast then
            flyData.yaw = flyData.yaw - (inp.Position.X - flyData.rotLast.X) * 0.3
            flyData.pitch = math.clamp(flyData.pitch - (inp.Position.Y - flyData.rotLast.Y) * 0.3, -80, 80)
            flyData.rotLast = inp.Position
        end
        if inp == flyData.moveTouch and flyData.moveStart then
            local dx = inp.Position.X - flyData.moveStart.X
            local dy = inp.Position.Y - flyData.moveStart.Y
            local nx = math.abs(dx) > 25 and math.clamp((dx - math.sign(dx)*25)/80, -1, 1) or 0
            local ny = math.abs(dy) > 20 and math.clamp((dy - math.sign(dy)*20)/80, -1, 1) or 0
            flyData.joy = Vector2.new(nx, ny)
        end
    end))

    table.insert(flyData.conns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == flyData.rotTouch then flyData.rotTouch = nil; flyData.rotLast = nil end
        if inp == flyData.moveTouch then flyData.moveTouch = nil; flyData.moveStart = nil; flyData.joy = Vector2.zero end
    end))

    -- Render loop
    RS:BindToRenderStep("XKIDFlyTP", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not flyData.active then return end
        local r = getRoot()
        local h = getHum()
        if not r or not h then return end

        -- 1. Update rotasi karakter IKUT KAMERA
        r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, math.rad(flyData.yaw), 0)

        -- 2. Hitung arah gerak berdasarkan kamera (IDENTIK FREECAM)
        local camDir = CFrame.new(r.Position)
            * CFrame.Angles(0, math.rad(flyData.yaw), 0)
            * CFrame.Angles(math.rad(flyData.pitch), 0, 0)

        local spd = State.flySpeed * dt * 60
        local move = Vector3.zero

        if onMobile then
            move = camDir.LookVector * (-flyData.joy.Y) * spd + camDir.RightVector * flyData.joy.X * spd
        else
            if flyData.keys[Enum.KeyCode.W] then move = move + camDir.LookVector * spd end
            if flyData.keys[Enum.KeyCode.S] then move = move - camDir.LookVector * spd end
            if flyData.keys[Enum.KeyCode.D] then move = move + camDir.RightVector * spd end
            if flyData.keys[Enum.KeyCode.A] then move = move - camDir.RightVector * spd end
            if flyData.keys[Enum.KeyCode.E] then move = move + Vector3.new(0, 1, 0) * spd end
            if flyData.keys[Enum.KeyCode.Q] then move = move - Vector3.new(0, 1, 0) * spd end
        end

        r.Velocity = move

        -- 3. Update kamera third person (di belakang karakter)
        local offset = CFrame.new(0, 1.5, 8)
        local camCF = r.CFrame
            * CFrame.Angles(0, math.rad(flyData.yaw), 0)
            * CFrame.Angles(math.rad(flyData.pitch), 0, 0)
            * offset
        Cam.CameraType = Enum.CameraType.Scriptable
        Cam.CFrame = camCF
    end)

    Library:Notification("Fly", "✈️ Fly ON — Kontrol kayak freecam, rotasi ikut kamera", 3)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │              RESET KARAKTER (WORKING 100%)              │
-- └─────────────────────────────────────────────────────────┘
local lastPosition = nil

-- Simpan posisi setiap saat
RS.Heartbeat:Connect(function()
    local r = getRoot()
    if r then lastPosition = r.CFrame end
end)

local function respawnAndTeleport()
    local targetPos = lastPosition
    if not targetPos then
        local r = getRoot()
        if r then targetPos = r.CFrame end
    end
    if not targetPos then
        Library:Notification("Reset", "❌ Tidak ada posisi tersimpan!", 2)
        return
    end

    -- Matiin fly dulu
    if flyData.active then stopFly() end

    -- Method 1: Pake Health = 0 (trigger respawn cepat)
    local hum = getHum()
    if hum then
        hum.Health = 0
    else
        -- Fallback: LoadCharacter
        LP:LoadCharacter()
    end

    -- Tunggu karakter baru
    local char = LP.CharacterAdded:Wait()
    task.wait(0.1)

    -- Dapetin HRP dan Humanoid
    local hrp = char:WaitForChild("HumanoidRootPart", 3)
    local newHum = char:WaitForChild("Humanoid", 3)

    if hrp then
        hrp.CFrame = targetPos
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    if newHum then
        newHum.PlatformStand = false
        newHum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    Library:Notification("Reset", "✅ Respawn cepat! Kembali ke posisi terakhir", 2)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                    FREECAM ENGINE                       │
-- └─────────────────────────────────────────────────────────┘
local FC = {
    active = false,
    pos = Vector3.zero,
    pitch = 0,
    yaw = 0,
    speed = 1,
    sens = 0.25,
    savedCharCFrame = nil,
    keys = {},
    joy = Vector2.zero,
    rotTouch = nil, moveTouch = nil, moveStart = nil, rotLast = nil,
    mouseRot = false,
    conns = {}
}

local DEAD_X, DEAD_Y = 25, 20

local function stopFC()
    if not FC.active then return end
    FC.active = false
    for _, c in ipairs(FC.conns) do c:Disconnect() end
    FC.conns = {}
    FC.keys = {}
    FC.mouseRot = false
    FC.rotTouch = nil
    FC.moveTouch = nil
    FC.moveStart = nil
    FC.rotLast = nil
    FC.joy = Vector2.zero
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    RS:UnbindFromRenderStep("XKIDFreecam")
    
    for part, t in pairs(FC.invisSaved or {}) do
        if part and part.Parent then part.Transparency = t end
    end
    FC.invisSaved = {}
    
    local hrp = getRoot()
    local hum = getHum()
    if hrp then
        hrp.Anchored = false
        if FC.savedCharCFrame then hrp.CFrame = FC.savedCharCFrame end
    end
    if hum then
        hum.WalkSpeed = State.ws
        hum.JumpPower = State.jp
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    Cam.FieldOfView = 70
    Cam.CameraType = Enum.CameraType.Custom
    Library:Notification("Freecam", "Freecam OFF", 2)
end

local function startFC()
    if FC.active then return end
    FC.active = true
    
    local cf = Cam.CFrame
    FC.pos = cf.Position
    local rx, ry = cf:ToEulerAnglesYXZ()
    FC.pitch = math.deg(rx)
    FC.yaw = math.deg(ry)
    
    local hrp = getRoot()
    local hum = getHum()
    if hrp then
        FC.savedCharCFrame = hrp.CFrame
        hrp.Anchored = true
    end
    if hum then
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end
    
    FC.invisSaved = {}
    local char = LP.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                FC.invisSaved[part] = part.Transparency
                part.Transparency = 1
            end
        end
    end
    
    -- Input handlers
    table.insert(FC.conns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then
            FC.keys[k] = true
        end
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            FC.mouseRot = true
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end))
    
    table.insert(FC.conns, UIS.InputEnded:Connect(function(inp)
        FC.keys[inp.KeyCode] = false
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            FC.mouseRot = false
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end))
    
    table.insert(FC.conns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and FC.mouseRot then
            FC.yaw = FC.yaw - inp.Delta.X * FC.sens
            FC.pitch = math.clamp(FC.pitch - inp.Delta.Y * FC.sens, -80, 80)
        end
        if inp.UserInputType == Enum.UserInputType.MouseWheel then
            Cam.FieldOfView = math.clamp(Cam.FieldOfView - inp.Position.Z * 5, 10, 120)
        end
    end))
    
    table.insert(FC.conns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local half = Cam.ViewportSize.X / 2
        if inp.Position.X > half then
            if not FC.rotTouch then FC.rotTouch = inp; FC.rotLast = inp.Position end
        else
            if not FC.moveTouch then FC.moveTouch = inp; FC.moveStart = inp.Position end
        end
    end))
    
    table.insert(FC.conns, UIS.TouchMoved:Connect(function(inp)
        if inp == FC.rotTouch and FC.rotLast then
            local dx = inp.Position.X - FC.rotLast.X
            local dy = inp.Position.Y - FC.rotLast.Y
            FC.yaw = FC.yaw - dx * FC.sens
            FC.pitch = math.clamp(FC.pitch - dy * FC.sens, -80, 80)
            FC.rotLast = inp.Position
        end
        if inp == FC.moveTouch and FC.moveStart then
            local dx = inp.Position.X - FC.moveStart.X
            local dy = inp.Position.Y - FC.moveStart.Y
            local nx = math.abs(dx) > DEAD_X and math.clamp((dx - math.sign(dx)*DEAD_X)/80, -1, 1) or 0
            local ny = math.abs(dy) > DEAD_Y and math.clamp((dy - math.sign(dy)*DEAD_Y)/80, -1, 1) or 0
            FC.joy = Vector2.new(nx, ny)
        end
    end))
    
    table.insert(FC.conns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == FC.rotTouch then FC.rotTouch = nil; FC.rotLast = nil end
        if inp == FC.moveTouch then FC.moveTouch = nil; FC.moveStart = nil; FC.joy = Vector2.zero end
    end))
    
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable
        local cf = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yaw), 0) * CFrame.Angles(math.rad(FC.pitch), 0, 0)
        local spd = FC.speed * 32 * dt
        local move = Vector3.zero
        
        if onMobile then
            move = cf.LookVector * (-FC.joy.Y) * spd + cf.RightVector * FC.joy.X * spd
        else
            if FC.keys[Enum.KeyCode.W] then move = move + cf.LookVector * spd end
            if FC.keys[Enum.KeyCode.S] then move = move - cf.LookVector * spd end
            if FC.keys[Enum.KeyCode.D] then move = move + cf.RightVector * spd end
            if FC.keys[Enum.KeyCode.A] then move = move - cf.RightVector * spd end
            if FC.keys[Enum.KeyCode.E] then move = move + Vector3.new(0,1,0) * spd end
            if FC.keys[Enum.KeyCode.Q] then move = move - Vector3.new(0,1,0) * spd end
        end
        FC.pos = FC.pos + move
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yaw), 0) * CFrame.Angles(math.rad(FC.pitch), 0, 0)
    end)
    
    Library:Notification("Freecam", "Freecam ON", 2)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                        UI                               │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("✦ XKID HUB — V.4 ✦", "star", "FREECAM", false)

-- TAB 1: PLAYER
local T_PL = Win:Tab("Player", "user")
local PLPage1 = T_PL:Page("Movement", "zap")
local PLM = PLPage1:Section("⚡ Movement", "Left")
local PLH = PLPage1:Section("🚀 Abilities", "Right")

PLM:Slider("🏃 WalkSpeed", "ws", 16, 500, 16, function(v)
    State.ws = v
    if getHum() then getHum().WalkSpeed = v end
end)
PLM:Button("🔄 Reset Speed", "", function()
    State.ws = 16
    if getHum() then getHum().WalkSpeed = 16 end
end)

PLM:Slider("🦘 JumpPower", "jp", 50, 500, 50, function(v)
    State.jp = v
    if getHum() then getHum().JumpPower = v end
end)
PLM:Button("🔄 Reset Jump", "", function()
    State.jp = 50
    if getHum() then getHum().JumpPower = 50 end
end)

PLM:Toggle("∞ Inf Jump", "ij", false, "", function(v)
    if v then
        State.infJ = UIS.JumpRequest:Connect(function()
            if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if State.infJ then State.infJ:Disconnect(); State.infJ = nil end
    end
end)

PLH:Toggle("✈️ Fly (TP Freecam)", "fly", false, "Kontrol kayak freecam + rotasi ikut kamera", function(v)
    if v then startFly() else stopFly() end
end)
PLH:Slider("✈️ Fly Speed", "flyspd", 10, 300, 60, function(v) State.flySpeed = v end)
PLH:Toggle("👻 NoClip", "nc", false, "", function(v) State.ncp = v end)
PLH:Toggle("💥 IY Fling", "fling", false, "", function(v) State.flingActive = v end)

-- God Mode
local godConn, godRespawn, godLastPos = nil, nil, nil
PLH:Toggle("🛡️ God Mode", "god", false, "", function(v)
    if v then
        local hum = getHum()
        if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
        godLastPos = getRoot() and getRoot().CFrame
        godRespawn = RS.Heartbeat:Connect(function()
            local r = getRoot()
            if r then godLastPos = r.CFrame end
        end)
        godConn = RS.Heartbeat:Connect(function()
            local h = getHum()
            if h then
                if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
                if h.MaxHealth ~= math.huge then h.MaxHealth = math.huge end
            end
        end)
        LP.CharacterAdded:Connect(function(char)
            task.wait(0.2)
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and godLastPos then hrp.CFrame = godLastPos end
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h.MaxHealth = math.huge; h.Health = math.huge end
        end)
    else
        if godConn then godConn:Disconnect(); godConn = nil end
        if godRespawn then godRespawn:Disconnect(); godRespawn = nil end
        local hum = getHum()
        if hum then hum.MaxHealth = 100; hum.Health = 100 end
    end
end)

-- Reset Karakter
local SCR = Win:Tab("Security", "shield"):Page("Guard", "shield"):Section("💀 Reset Karakter", "Left")
SCR:Button("💀 RESPAWN CEPAT + KEMBALI KE POSISI", "", function()
    respawnAndTeleport()
end)
SCR:Button("📍 TELEPORT KE POSISI TERAKHIR SAJA", "", function()
    local r = getRoot()
    if r and lastPosition then
        r.CFrame = lastPosition
        Library:Notification("Posisi", "Teleport ke posisi terakhir!", 2)
    else
        Library:Notification("Posisi", "❌ Gagal!", 2)
    end
end)

-- Freecam
local T_CI = Win:Tab("Cinematic", "video")
local CIM = T_CI:Page("Freecam", "video"):Section("🎬 Freecam", "Left")
CIM:Toggle("🎬 Freecam ON/OFF", "fc", false, "", function(v)
    if v then startFC() else stopFC() end
end)
CIM:Slider("⚡ FC Speed", "fcspd", 1, 30, 1, function(v) FC.speed = v end)
CIM:Slider("🎯 FC Sensitivity", "fcsens", 1, 20, 5, function(v) FC.sens = v * 0.05 end)
CIM:Slider("🔍 FOV", "fcfov", 10, 120, 70, function(v) Cam.FieldOfView = v end)

-- Teleport
local T_TP = Win:Tab("Teleport", "map-pin")
local TPT = T_TP:Page("Navigation", "map-pin"):Section("🎯 Teleport Player", "Left")
TPT:TextBox("Ketik nama", "pText", "", function(v) State.teleTarget = v end)
TPT:Button("🚀 Teleport", "", function()
    local snippet = State.teleTarget
    if snippet == "" then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and (string.find(string.lower(p.Name), string.lower(snippet)) or string.find(string.lower(p.DisplayName), string.lower(snippet))) then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local r = getRoot()
                if r then r.CFrame = p.Character.HumanoidRootPart.CFrame end
                return
            end
        end
    end
end)

-- NOCLIP Loop
RS.Stepped:Connect(function()
    if (State.ncp or State.flingActive) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

-- FLING Loop
task.spawn(function()
    while true do
        if State.flingActive and getRoot() then
            local r = getRoot()
            pcall(function()
                r.AssemblyAngularVelocity = Vector3.new(0, 1000000, 0)
                r.AssemblyLinearVelocity = Vector3.new(1000000, 1000000, 1000000)
            end)
        end
        RS.RenderStepped:Wait()
    end
end)

Library:Notification("XKID HUB", "V.4 READY! 🚀", 3)