--[[
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                  P R E M I U M   E D I T I O N                  ║
║                     Powered by WindUI                            ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService   = game:GetService("TextChatService")
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
    Ghost    = { active = false, savedPos = nil },
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
--  CHAT COMMANDS & BYPASS ENGINE
-- ══════════════════════════════════════════════════════════════
local function sendBypassMessage(msg)
    local bypassed = ""
    for i = 1, #msg do
        -- Menyisipkan Zero-Width Character agar tidak terdeteksi filter
        bypassed = bypassed .. msg:sub(i, i) .. "󠀠" 
    end

    -- Legacy Chat System
    local DefaultChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if DefaultChat and DefaultChat:FindFirstChild("SayMessageRequest") then
        DefaultChat.SayMessageRequest:FireServer(bypassed, "All")
    -- New TextChatService
    elseif TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then channel:SendAsync(bypassed) end
    end
end

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

    -- Custom Chat Bypass Trigger
    if State.Chat.bypass and not msg:match("^/") then
        sendBypassMessage(msg)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  ESP ENGINE
-- ══════════════════════════════════════════════════════════════
local function getESPGui()
    local sg = LP.PlayerGui:FindFirstChild("_XKIDEsp")
    if not sg then
        sg = Instance.new("ScreenGui", LP.PlayerGui)
        sg.Name = "_XKIDEsp"; sg.ResetOnSpawn = false; sg.DisplayOrder = 999
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
    local f = Instance.new("Frame", getESPGui())
    f.BackgroundColor3 = color; f.BorderSizePixel = 0
    f.Position = UDim2.new(0, (p1.X + p2.X)/2 - dist/2, 0, (p1.Y + p2.Y)/2 - thick/2)
    f.Size = UDim2.new(0, dist, 0, thick)
    f.Rotation = math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X))
    return f
end

local function renderESP(player)
    if not State.ESP.active or player == LP then return end
    local char = player.Character
    if not char then return end
    local hrp  = getCharRoot(char)
    if not hrp then return end
    local myR  = getCharRoot(LP.Character)
    if myR and (myR.Position - hrp.Position).Magnitude > State.ESP.maxDrawDistance then return end

    local suspect    = false -- Simplified for performance
    local boxColor   = suspect and State.ESP.boxColor_S   or State.ESP.boxColor_N
    local tracerCol  = suspect and State.ESP.tracerColor_S or State.ESP.tracerColor_N

    if not State.ESP.cache[player] then State.ESP.cache[player] = { renders = {}, hl = nil } end
    local cache = State.ESP.cache[player]

    for _, r in pairs(cache.renders) do r:Destroy() end
    cache.renders = {}

    local root2d, visible = w2s(hrp.Position)
    if not visible then if cache.hl then cache.hl.Enabled = false end return end

    -- Box
    if State.ESP.boxMode == "Corner" or State.ESP.boxMode == "2D Box" then
        if cache.hl then cache.hl.Enabled = false end
        local top = w2s(hrp.Position + Vector3.new(0, 3, 0))
        local bottom = w2s(hrp.Position - Vector3.new(0, 3.5, 0))
        local h = math.abs(top.Y - bottom.Y)
        local w = h * 0.6
        local tl = Vector2.new(root2d.X - w/2, root2d.Y - h/2)
        local tr = Vector2.new(root2d.X + w/2, root2d.Y - h/2)
        local bl = Vector2.new(root2d.X - w/2, root2d.Y + h/2)
        local br = Vector2.new(root2d.X + w/2, root2d.Y + h/2)
        
        if State.ESP.boxMode == "Corner" then
            local len = w/4
            table.insert(cache.renders, drawLine(tl, tl + Vector2.new(len,0), 2, boxColor))
            table.insert(cache.renders, drawLine(tl, tl + Vector2.new(0,len), 2, boxColor))
            table.insert(cache.renders, drawLine(tr, tr - Vector2.new(len,0), 2, boxColor))
            table.insert(cache.renders, drawLine(tr, tr + Vector2.new(0,len), 2, boxColor))
        else
            table.insert(cache.renders, drawLine(tl, tr, 2, boxColor))
            table.insert(cache.renders, drawLine(tr, br, 2, boxColor))
            table.insert(cache.renders, drawLine(br, bl, 2, boxColor))
            table.insert(cache.renders, drawLine(bl, tl, 2, boxColor))
        end
    elseif State.ESP.boxMode == "HIGHLIGHT" then
        if not cache.hl or cache.hl.Parent ~= char then
            if cache.hl then cache.hl:Destroy() end
            local hl = Instance.new("Highlight", char)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            cache.hl = hl
        end
        cache.hl.FillColor = boxColor; cache.hl.Enabled = true
    else
        if cache.hl then cache.hl.Enabled = false end
    end

    -- Tracer
    if State.ESP.tracerMode ~= "OFF" then
        local sp, on = w2s(hrp.Position - Vector3.new(0, 2.5, 0))
        if on then
            local origin
            if State.ESP.tracerMode == "Bottom" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
            elseif State.ESP.tracerMode == "Center" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
            elseif State.ESP.tracerMode == "Mouse" then local m = UIS:GetMouseLocation(); origin = Vector2.new(m.X, m.Y) end
            if origin then table.insert(cache.renders, drawLine(origin, sp, 1.5, tracerCol)) end
        end
    end

    -- Name + Distance
    if State.ESP.showNickname or State.ESP.showDistance then
        local lbl = Instance.new("TextLabel", getESPGui())
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = State.ESP.nameColor
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12
        lbl.Size = UDim2.new(0, 180, 0, 30)
        lbl.Position = UDim2.new(0, root2d.X - 90, 0, root2d.Y - 50)
        
        local txt = ""
        if State.ESP.showNickname then txt = player.DisplayName end
        if State.ESP.showDistance and myR then
            local dist = math.floor((myR.Position - hrp.Position).Magnitude)
            txt = txt .. "\n[" .. dist .. "m]"
        end
        lbl.Text = txt
        table.insert(cache.renders, lbl)
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
        for _, r in pairs(c.renders) do r:Destroy() end
        if c.hl then c.hl:Destroy() end
        State.ESP.cache[p] = nil
    end
end)

-- ══════════════════════════════════════════════════════════════
--  FREECAM ENGINE (NORMAL SPEED & DIRECT CONTROL)
-- ══════════════════════════════════════════════════════════════
-- Fitur ini telah dirombak. Menghapus efek licin, pergerakan langsung & instan.
local FC = {
    active=false, pos=Vector3.zero,
    pitchDeg=0, yawDeg=0, speed=1, sens=0.25,
    savedCF=nil
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
        if k==Enum.KeyCode.W or k==Enum.KeyCode.A or k==Enum.KeyCode.S
        or k==Enum.KeyCode.D or k==Enum.KeyCode.E or k==Enum.KeyCode.Q then
            keysHeld[k]=true
        end
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then
            FC._mouseRot=true
            UIS.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition
        end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        keysHeld[inp.KeyCode]=false
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then
            FC._mouseRot=false
            UIS.MouseBehavior=Enum.MouseBehavior.Default
        end
    end))
    table.insert(fcConns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement and FC._mouseRot then
            FC.yawDeg   = FC.yawDeg   - inp.Delta.X*FC.sens
            FC.pitchDeg = math.clamp(FC.pitchDeg-inp.Delta.Y*FC.sens,-80,80)
        end
    end))
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp,gp)
        if gp or inp.UserInputType~=Enum.UserInputType.Touch then return end
        local half=Cam.ViewportSize.X/2
        if inp.Position.X>half then
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
            local dx=inp.Position.X-fcMoveSt.X
            local dy=inp.Position.Y-fcMoveSt.Y
            fcJoy=Vector2.new(
                math.abs(dx)>DEAD_X and math.clamp((dx-math.sign(dx)*DEAD_X)/80,-1,1) or 0,
                math.abs(dy)>DEAD_Y and math.clamp((dy-math.sign(dy)*DEAD_Y)/80,-1,1) or 0
            )
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
    fcConns={}; fcRotT=nil; fcMoveT=nil; fcMoveSt=nil; fcRotLast=nil
    fcJoy=Vector2.zero; FC._mouseRot=false; FC._keys={}
    UIS.MouseBehavior=Enum.MouseBehavior.Default
end

local function startFCLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value+1, function(dt)
        if not FC.active then return end
        Cam.CameraType=Enum.CameraType.Scriptable
        
        local move = Vector3.zero
        local keys = FC._keys or {}
        
        -- Mapping input directly
        if onMobile then
            move = Vector3.new(fcJoy.X, -fcJoy.Y, 0)
        else
            if keys[Enum.KeyCode.W] then move = move + Vector3.new(0, 0, -1) end
            if keys[Enum.KeyCode.S] then move = move + Vector3.new(0, 0, 1)  end
            if keys[Enum.KeyCode.A] then move = move + Vector3.new(-1, 0, 0) end
            if keys[Enum.KeyCode.D] then move = move + Vector3.new(1, 0, 0)  end
            if keys[Enum.KeyCode.E] then move = move + Vector3.new(0, 1, 0)  end
            if keys[Enum.KeyCode.Q] then move = move + Vector3.new(0, -1, 0) end
        end
        
        if move.Magnitude > 0 then move = move.Unit end
        
        -- Direct CFrame translation (No lerping/sliding)
        local cf = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        FC.pos = FC.pos + cf:VectorToWorldSpace(move * (FC.speed * dt * 60))
        
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        
        local hrp=getRoot(); local hum=getHum()
        if hrp and not hrp.Anchored then hrp.Anchored=true end
        if hum then hum:ChangeState(Enum.HumanoidStateType.Physics); hum.WalkSpeed=0; hum.JumpPower=0 end
    end)
end

local function stopFCLoop()
    RS:UnbindFromRenderStep("XKIDFreecam")
end

-- ══════════════════════════════════════════════════════════════
--  WINDOW INITIALIZATION
-- ══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title       = "XKID SCRIPT V2",
    Author      = "by XKID",
    Folder      = "XKIDScript",
    Icon        = "shield",
    Theme       = "Rose",
    Acrylic     = true,
    Transparent = true,
    Size        = UDim2.fromOffset(600, 400),
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
--  TAB: TELEPORT
-- ══════════════════════════════════════════════════════════════
local T_TP   = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local secTP  = T_TP:Section({ Title = "Quick Teleport", Opened = true })

local tpTarget = ""
secTP:Input({ Title = "Search Player", Placeholder = "nama player...", Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "Teleport", Callback = function()
    if tpTarget == "" then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and (string.find(p.Name:lower(), tpTarget:lower()) or string.find(p.DisplayName:lower(), tpTarget:lower())) and getCharRoot(p.Character) then
            getRoot().CFrame = getCharRoot(p.Character).CFrame; notify("Teleport","✅  TP ke "..p.DisplayName); return
        end
    end
    notify("Teleport","❌  Player tidak ditemukan")
end })

local pDropOpts = getPNames()
secTP:Dropdown({ Title = "Player List", Values = pDropOpts, Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "Refresh List", Callback = function() pDropOpts = getPNames(); notify("Teleport","Daftar diperbarui!") end })

local secLoc = T_TP:Section({ Title = "Save Location", Opened = false })
local SavedLocs = {}
for i = 1, 3 do
    secLoc:Button({ Title = "Save Slot "..i, Callback = function() local r = getRoot() if r then SavedLocs[i] = r.CFrame notify("Location","💾  Tersimpan!") end end })
    secLoc:Button({ Title = "Load Slot "..i, Callback = function() if SavedLocs[i] and getRoot() then getRoot().CFrame = SavedLocs[i] notify("Location","📍  TP") end end })
end

-- ══════════════════════════════════════════════════════════════
--  TAB: PLAYER & GHOST MODE
-- ══════════════════════════════════════════════════════════════
local T_PL   = Window:Tab({ Title = "Player", Icon = "user" })

local secMov = T_PL:Section({ Title = "Movement", Opened = true })
secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v if getHum() then getHum().WalkSpeed = v end end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v if getHum() then getHum().UseJumpPower=true; getHum().JumpPower=v end end })

local secAbi = T_PL:Section({ Title = "Abilities", Opened = true })
secAbi:Toggle({ Title = "NoClip", Callback = function(v) State.Move.ncp = v end })

-- GHOST MODE: Sembunyi Di Bawah Tanah + Freecam Auto
local ghostBtn
ghostBtn = secAbi:Toggle({
    Title    = "Ghost Mode (Glitch Underground)",
    Desc     = "Badan aslimu ditanam di bawah tanah, kamu keliling tak terlihat.",
    Value    = false,
    Callback = function(v)
        State.Ghost.active = v
        local hrp = getRoot()
        
        if v and hrp then
            State.Ghost.savedPos = hrp.CFrame
            -- Teleport tubuh 100 stud ke bawah tanah dan anchor
            hrp.CFrame = hrp.CFrame - Vector3.new(0, 100, 0)
            hrp.Anchored = true
            
            -- Auto aktifkan freecam di posisi awal
            FC.active = true; State.Cinema.active = true
            FC.pos = State.Ghost.savedPos.Position
            local rx,ry = Cam.CFrame:ToEulerAnglesYXZ()
            FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry)
            
            startFCCapture(); startFCLoop()
            notify("Ghost Mode", "Badan aslimu ditanam di bawah tanah! Freecam diaktifkan otomatis.", 3)
        else
            -- Matikan Ghost Mode
            if State.Ghost.savedPos and hrp then
                hrp.Anchored = false
                hrp.CFrame = State.Ghost.savedPos
            end
            
            -- Matikan freecam
            FC.active = false; State.Cinema.active = false
            stopFCLoop(); stopFCCapture()
            Cam.CameraType = Enum.CameraType.Custom
            if getHum() then getHum():ChangeState(Enum.HumanoidStateType.GettingUp) end
            
            notify("Ghost Mode", "Kembali ke permukaan.", 2)
        end
    end,
})

-- ══════════════════════════════════════════════════════════════
--  TAB: CINEMATIC (Freecam)
-- ══════════════════════════════════════════════════════════════
local T_CI   = Window:Tab({ Title = "Cinematic", Icon = "video" })
local secFC  = T_CI:Section({ Title = "Freecam Normal", Opened = true })

secFC:Toggle({
    Title    = "Freecam",
    Desc     = "Pergerakan direct / instan (tanpa smooth)",
    Value    = false,
    Callback = function(v)
        -- Jangan bertabrakan dengan Ghost Mode
        if State.Ghost.active then 
            notify("Peringatan", "Matikan Ghost Mode terlebih dahulu!"); 
            return 
        end
        
        FC.active = v; State.Cinema.active = v
        if v then
            local cf=Cam.CFrame; FC.pos=cf.Position; local rx,ry=cf:ToEulerAnglesYXZ()
            FC.pitchDeg=math.deg(rx); FC.yawDeg=math.deg(ry)
            FC._keys={}; FC._mouseRot=false
            local hrp=getRoot(); local hum=getHum()
            if hrp then FC.savedCF=hrp.CFrame; hrp.Anchored=true end
            if hum then hum.WalkSpeed=0; hum.JumpPower=0; hum:ChangeState(Enum.HumanoidStateType.Physics) end
            startFCCapture(); startFCLoop()
            notify("Freecam","🎬  ON", 2)
        else
            stopFCLoop(); stopFCCapture()
            local hrp=getRoot(); local hum=getHum()
            if hrp then hrp.Anchored=false if FC.savedCF then hrp.CFrame=FC.savedCF; FC.savedCF=nil end end
            if hum then hum.WalkSpeed=State.Move.ws; hum.UseJumpPower=true; hum.JumpPower=State.Move.jp; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            Cam.FieldOfView=70; Cam.CameraType=Enum.CameraType.Custom
            notify("Freecam","🎬  OFF", 2)
        end
    end,
})
secFC:Slider({ Title="Speed", Step=0.5, Value={Min=0.5, Max=15, Default=2}, Callback=function(v) FC.speed = v end })
secFC:Slider({ Title="FOV", Step=1, Value={Min=10, Max=120, Default=70}, Callback=function(v) Cam.FieldOfView = v end })

-- ══════════════════════════════════════════════════════════════
--  TAB: SPECTATE (Tanpa Hide Name)
-- ══════════════════════════════════════════════════════════════
local T_SP   = Window:Tab({ Title = "Spectate", Icon = "eye" })
local secSP  = T_SP:Section({ Title = "Spectate Player", Opened = true })

local Spec = { active=false, target=nil, dist=8 }
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
--  TAB: WORLD (Simple V2 - Sesuai Request)
-- ══════════════════════════════════════════════════════════════
local T_WO   = Window:Tab({ Title = "World", Icon = "globe" })

local secAtmos = T_WO:Section({ Title = "Environment Control", Opened = true })

-- Tombol Simpel Sesuai Request
secAtmos:Button({ Title = "🌅 Pagi (Morning)", Callback = function() Lighting.ClockTime = 7; Lighting.Brightness = 1 end })
secAtmos:Button({ Title = "☀ Siang (Day)", Callback = function() Lighting.ClockTime = 14; Lighting.Brightness = 2 end })
secAtmos:Button({ Title = "🌇 Sore (Evening)", Callback = function() Lighting.ClockTime = 17.5; Lighting.Brightness = 1.5 end })
secAtmos:Button({ Title = "🌃 Malam (Night)", Callback = function() Lighting.ClockTime = 0; Lighting.Brightness = 0.5 end })

-- Slider Pengaturan
secAtmos:Slider({ Title="Clock Time", Step=1, Value={Min=0, Max=24, Default=14}, Callback=function(v) Lighting.ClockTime = v end })
secAtmos:Slider({ Title="Brightness", Step=0.1, Value={Min=0, Max=5, Default=1}, Callback=function(v) Lighting.Brightness = v end })

secAtmos:Toggle({ Title = "Fullbright (Clear Vision)", Desc = "Terangkan tempat gelap & hapus kabut", Value = false, Callback = function(v)
    State.Atmos.fullbright = v
    if v then
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.ColorShift_Bottom = Color3.new(1,1,1)
        Lighting.ColorShift_Top = Color3.new(1,1,1)
        Lighting.FogEnd = 999999
    else
        Lighting.Ambient = State.Atmos.default.Ambient
        Lighting.FogEnd = 1000
    end
end })

-- ══════════════════════════════════════════════════════════════
--  TAB: SECURITY & ESP TRACKER
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
secProt:Toggle({ Title = "Chat Bypass Filter", Desc = "Otomatis merubah teks kasarmu agar lolos", Value = false, Callback = function(v) State.Chat.bypass = v end })
secProt:Button({ Title = "Memory Purge (Bersihkan RAM)", Desc = "Tekan jika game mulai ngelag", Callback = function()
    collectgarbage("collect"); task.wait(0.1); notify("System", "Memory berhasil dibersihkan!", 2)
end })

-- ══════════════════════════════════════════════════════════════
--  TAB: SETTINGS
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

local secTheme = T_SET:Section({ Title = "Appearance", Opened = true })
secTheme:Dropdown({
    Title    = "Theme",
    Values   = (function() local names={} for name in pairs(WindUI:GetThemes()) do table.insert(names,name) end table.sort(names); return names end)(),
    Value    = "Rose",
    Callback = function(selected) WindUI:SetTheme(selected) end,
})
secTheme:Toggle({ Title = "Acrylic", Value = true, Callback = function() WindUI:ToggleAcrylic(not WindUI.Window.Acrylic) end })
secTheme:Toggle({ Title = "Transparent", Value = true, Callback = function(state) Window:ToggleTransparency(state) end })

local currentKey = Enum.KeyCode.RightShift
secTheme:Keybind({
    Title    = "Toggle Key",
    Value    = currentKey,
    Callback = function(v) currentKey = (typeof(v)=="EnumItem") and v or Enum.KeyCode[v]; Window:SetToggleKey(currentKey) end,
})

-- ══════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS (NoClip / Fling)
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if (State.Fling.active or State.SoftFling.active) and getRoot() then
            local r=getRoot()
            local brutal=State.Fling.active
            local pwr=brutal and State.Fling.power or State.SoftFling.power
            pcall(function()
                r.AssemblyAngularVelocity=Vector3.new(0,pwr,0)
                if brutal then r.AssemblyLinearVelocity=Vector3.new(pwr,pwr,pwr) end
            end)
        end
        RS.RenderStepped:Wait()
    end
end)

RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active or State.SoftFling.active) and LP.Character then
        for _,v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide=false end
        end
    end
end)

WindUI:Notify({ Title = "XKID SCRIPT", Content = "Ultimate Patch - Rose Theme Ready!", Duration = 5 })
