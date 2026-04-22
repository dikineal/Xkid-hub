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
║                   ⚡ 🛡 XKID HUB                                 ║
║                      Luxury Script                              ║
║                     Powered by WindUI                            ║
║                                                                  ║
║                    Designed by @WTF.XKID                        ║
╚══════════════════════════════════════════════════════════════════╝

  ✨ Premium Features:
  • Fast Respawn (/re - Safe & Instant)
  • Teleport & Location Saver (5 Slots)
  • Movement (Speed / Jump / Fly / NoClip / Fling)
  • Freecam (Smooth + Mobile Ready)
  • Spectate (Orbit & First Person)
  • Hybrid ESP (Drawing API / Smart Detection)
  • World Control (Weather / Atmosphere / Graphics)
  • Security (Anti-AFK / Anti-Glitcher / Anti-Lag)
  • Live FPS & PING Counter
  • Premium Settings (Theme / Keybind / Acrylic)
  
  💎 Created by @WTF.XKID
]]

-- ══════════════════════════════════════════════════════════════
--  0. AUTO CLEANUP & MEMORY MANAGEMENT
-- ══════════════════════════════════════════════════════════════
pcall(function()
    if getgenv()._XKID_RUNNING then
        getgenv()._XKID_RUNNING = false 
    end
end)

pcall(function()
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
end)
getgenv()._XKID_ESP_CACHE = {}

pcall(function()
    if getgenv()._XKID_LOADED then
        for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
            if v.Name == "WindUI" then v:Destroy() end
        end
        if getgenv()._XKID_CONNS then
            for _, c in pairs(getgenv()._XKID_CONNS) do 
                pcall(function() c:Disconnect() end) 
            end
        end
        pcall(function() game:GetService("RunService"):UnbindFromRenderStep("XKIDFreecam") end)
        pcall(function() game:GetService("RunService"):UnbindFromRenderStep("XKIDFly") end)
    end
end)

task.wait(0.2) 
collectgarbage("collect")

getgenv()._XKID_LOADED = true
getgenv()._XKID_RUNNING = true
getgenv()._XKID_CONNS = {}

local function TrackC(conn) 
    table.insert(getgenv()._XKID_CONNS, conn) 
    return conn 
end

-- ══════════════════════════════════════════════════════════════
--  LOAD WINDUI (Dengan error handling)
-- ══════════════════════════════════════════════════════════════
local WindUI
local loadSuccess, loadError = pcall(function()
    WindUI = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
    ))()
end)

if not loadSuccess then
    warn("Failed to load WindUI: " .. tostring(loadError))
    return
end

-- ══════════════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════════════
local Players     = game:GetService("Players")
local RS          = game:GetService("RunService")
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
--  DEKLARASI VARIABEL GLOBAL (FIXED)
-- ══════════════════════════════════════════════════════════════
local fpsSamples = {}  -- FIXED: Dideklarasikan sebelum digunakan

-- ══════════════════════════════════════════════════════════════
--  STATE MANAGEMENT
-- ══════════════════════════════════════════════════════════════
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
        boxColor_S      = Color3.fromRGB(220, 20, 60),
        tracerColor_N   = Color3.fromRGB(0, 200, 255),
        tracerColor_S   = Color3.fromRGB(220, 20, 60),
        nameColor       = Color3.fromRGB(255, 255, 255),
    },
}

-- ══════════════════════════════════════════════════════════════
--  COLOR MAP
-- ══════════════════════════════════════════════════════════════
local colorMap = {
    ["Merah"] = Color3.fromRGB(255, 0, 0), 
    ["Hijau"] = Color3.fromRGB(0, 255, 0),
    ["Biru"]  = Color3.fromRGB(0, 0, 255), 
    ["Kuning"]= Color3.fromRGB(255, 255, 0),
    ["Ungu"]  = Color3.fromRGB(255, 0, 255), 
    ["Cyan"]  = Color3.fromRGB(0, 255, 255),
    ["Orange"]= Color3.fromRGB(255, 165, 0), 
    ["Pink"]  = Color3.fromRGB(255, 105, 180),
    ["Putih"] = Color3.fromRGB(255, 255, 255), 
    ["Hitam"] = Color3.fromRGB(0, 0, 0),
    ["Crimson"] = Color3.fromRGB(220, 20, 60),
}

-- ══════════════════════════════════════════════════════════════
--  HELPER FUNCTIONS
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
    pcall(function()
        WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 })
    end)
end

-- ══════════════════════════════════════════════════════════════
--  PERSISTENT STATS ON RESPAWN
-- ══════════════════════════════════════════════════════════════
TrackC(LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then 
            hum.UseJumpPower = true
            hum.JumpPower = State.Move.jp 
        end
    end
end))

-- ══════════════════════════════════════════════════════════════
--  💎 PREMIUM FAST RESPAWN SYSTEM (/re Command)
-- ══════════════════════════════════════════════════════════════
local function fastRespawn() 
    if State.Avatar.isRefreshing then return end
    
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = getRoot()

    if not hum or not hrp then
        notify("❌ Fast Respawn", "Character not found!", 2)
        return 
    end

    State.Avatar.isRefreshing = true
    notify("🔄 Fast Respawn", "Respawning safely...", 1.5)
    
    local savedCF = hrp.CFrame
    local savedCamCF = Cam.CFrame
    
    Cam.CameraType = Enum.CameraType.Scriptable
    Cam.CFrame = savedCamCF
    
    local charAddedConn
    charAddedConn = TrackC(LP.CharacterAdded:Connect(function(newChar)
        charAddedConn:Disconnect() 
        
        local newHrp = newChar:WaitForChild("HumanoidRootPart", 5)
        local newHum = newChar:WaitForChild("Humanoid", 5)
        
        pcall(function()
            if not LP:HasAppearanceLoaded() then
                LP.CharacterAppearanceLoaded:Wait()
            end
        end)
        
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
            
            notify("✨ Success", "Fast Respawn Complete!", 2)
        end
        State.Avatar.isRefreshing = false
    end))

    hum.Health = 0

    task.delay(5, function()
        State.Avatar.isRefreshing = false
    end)
end

-- ══════════════════════════════════════════════════════════════
--  CHAT COMMANDS
-- ══════════════════════════════════════════════════════════════
TrackC(LP.Chatted:Connect(function(msg)
    local lowerMsg = msg:lower()
    if lowerMsg == ";re" or lowerMsg == "/re" or lowerMsg == "/reset" or lowerMsg == ";reset" then 
        fastRespawn() 
        return 
    end
    if lowerMsg == "!rejoin" then 
        notify("Command", "Rejoining Server...", 2)
        TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        return 
    end
end))

-- ══════════════════════════════════════════════════════════════
--  HYBRID DETECTION ESP ENGINE
-- ══════════════════════════════════════════════════════════════

local function initPlayerCache(player)
    if State.ESP.cache[player] then return end
    
    local success, cache = pcall(function()
        local c = {
            texts    = Drawing.new("Text"),
            tracer   = Drawing.new("Line"),
            boxLines = {},
            hl       = nil,
            isSuspect= false,
            reason   = ""
        }
        
        c.texts.Center  = true
        c.texts.Outline = true
        c.texts.Font    = 2
        c.texts.Size    = 13
        c.texts.ZIndex  = 2
        
        c.tracer.Thickness = 1.5
        c.tracer.ZIndex    = 1
        
        for i = 1, 4 do
            local line = Drawing.new("Line")
            line.Thickness = 1.5
            line.ZIndex    = 1
            c.boxLines[i] = line
        end
        
        return c
    end)
    
    if success then
        State.ESP.cache[player] = cache
    end
end

local function clearPlayerCache(player)
    local c = State.ESP.cache[player]
    if c then
        pcall(function()
            if c.texts then c.texts:Remove() end
            if c.tracer then c.tracer:Remove() end
            for _, l in ipairs(c.boxLines) do l:Remove() end
            if c.hl then c.hl:Destroy() end
        end)
        State.ESP.cache[player] = nil
    end
end

TrackC(Players.PlayerRemoving:Connect(clearPlayerCache))

-- Scanner untuk deteksi suspect
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        pcall(function()
            if State.ESP.active then
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local isSus = false
                        local reason = ""
                        
                        for _, v in pairs(p.Character:GetChildren()) do
                            if v:IsA("BasePart") and (v.Size.X > 20 or v.Size.Y > 20 or v.Size.Z > 20) then
                                isSus = true
                                reason = "Map Blocker"
                                break
                            elseif v:IsA("Accessory") then
                                local h = v:FindFirstChild("Handle")
                                if h and h:IsA("BasePart") and (h.Size.Magnitude > 15) then
                                    isSus = true
                                    reason = "Huge Hat"
                                    break
                                end
                            end
                        end
                        
                        if not isSus then
                            local hum = p.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                local bws = hum:FindFirstChild("BodyWidthScale")
                                local bhs = hum:FindFirstChild("BodyHeightScale")
                                if (bws and bws.Value > 1.5) or (bhs and bhs.Value > 1.5) then
                                    isSus = true
                                    reason = "Glitch Avatar"
                                end
                            end
                        end
                        
                        initPlayerCache(p)
                        if State.ESP.cache[p] then
                            State.ESP.cache[p].isSuspect = isSus
                            State.ESP.cache[p].reason = reason
                        end
                    end
                end
            end
        end)
        task.wait(1)
    end
end)

-- Visual Tracker
TrackC(RS.RenderStepped:Connect(function()
    pcall(function()
        if not State.ESP.active then return end
        local myHrp = getCharRoot(LP.Character)
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                local char = player.Character
                local hrp = getCharRoot(char)
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                
                initPlayerCache(player)
                local c = State.ESP.cache[player]
                if not c then goto continue end
                
                local active = char and hrp and hum and hum.Health > 0 and myHrp
                local dist = active and (hrp.Position - myHrp.Position).Magnitude or 9999
                
                if not active or dist > State.ESP.maxDrawDistance then
                    c.texts.Visible = false
                    c.tracer.Visible = false
                    for _, l in ipairs(c.boxLines) do l.Visible = false end
                    if c.hl then c.hl.Enabled = false end
                    goto continue
                end
                
                local rootPos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
                if not onScreen then
                    c.texts.Visible = false
                    c.tracer.Visible = false
                    for _, l in ipairs(c.boxLines) do l.Visible = false end
                    if c.hl then c.hl.Enabled = false end
                    goto continue
                end
                
                local isSus = c.isSuspect
                
                -- Text Rendering
                local txt = ""
                if State.ESP.showNickname then txt = player.DisplayName end
                if State.ESP.showDistance then txt = txt .. "\n[" .. math.floor(dist) .. "m]" end
                if isSus then txt = txt .. "\n⚠ " .. c.reason .. " ⚠" end
                
                c.texts.Text = txt
                c.texts.Color = isSus and State.ESP.boxColor_S or State.ESP.nameColor
                c.texts.Position = Vector2.new(rootPos.X, rootPos.Y - 45)
                c.texts.Visible = true
                
                -- Tracer Rendering
                if State.ESP.tracerMode ~= "OFF" or isSus then
                    local origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
                    if State.ESP.tracerMode == "Center" then 
                        origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
                    elseif State.ESP.tracerMode == "Mouse" then 
                        local m = UIS:GetMouseLocation()
                        origin = Vector2.new(m.X, m.Y)
                    end
                    
                    c.tracer.From = origin
                    c.tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                    c.tracer.Color = isSus and State.ESP.tracerColor_S or State.ESP.tracerColor_N
                    c.tracer.Visible = true
                else
                    c.tracer.Visible = false
                end
                
                -- Box & Highlight untuk Suspect
                if isSus then
                    local top, topOn = Cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                    local bot, botOn = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                    local h = math.abs(top.Y - bot.Y)
                    local w = h * 0.6
                    
                    local tl = Vector2.new(rootPos.X - w/2, top.Y)
                    local tr = Vector2.new(rootPos.X + w/2, top.Y)
                    local bl = Vector2.new(rootPos.X - w/2, bot.Y)
                    local br = Vector2.new(rootPos.X + w/2, bot.Y)
                    
                    c.boxLines[1].From = tl
                    c.boxLines[1].To = tr
                    c.boxLines[2].From = tr
                    c.boxLines[2].To = br
                    c.boxLines[3].From = br
                    c.boxLines[3].To = bl
                    c.boxLines[4].From = bl
                    c.boxLines[4].To = tl
                    
                    for i=1, 4 do
                        c.boxLines[i].Color = State.ESP.boxColor_S
                        c.boxLines[i].Visible = true
                    end
                    
                    if not c.hl or c.hl.Parent ~= char then
                        if c.hl then c.hl:Destroy() end
                        c.hl = Instance.new("Highlight", char)
                        c.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    end
                    c.hl.FillColor = State.ESP.boxColor_S
                    c.hl.OutlineColor = Color3.new(1,1,1)
                    c.hl.Enabled = true
                else
                    for _, l in ipairs(c.boxLines) do l.Visible = false end
                    if c.hl then c.hl.Enabled = false end
                end
                
                ::continue::
            end
        end
    end)
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
        if k==Enum.KeyCode.W or k==Enum.KeyCode.A or k==Enum.KeyCode.S
        or k==Enum.KeyCode.D or k==Enum.KeyCode.E or k==Enum.KeyCode.Q then
            keysHeld[k] = true
        end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp)
        keysHeld[inp.KeyCode] = false
    end))
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
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == flyMoveTouch then 
            flyMoveTouch=nil
            flyMoveSt=nil
            flyJoy=Vector2.zero 
        end
    end))
    State.Fly._keys = keysHeld
end

local function stopFlyCapture()
    for _, c in ipairs(flyConns) do c:Disconnect() end
    flyConns={}
    flyMoveTouch=nil
    flyMoveSt=nil
    flyJoy=Vector2.zero
    State.Fly._keys={}
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
            hum.WalkSpeed=State.Move.ws
            hum.UseJumpPower=true
            hum.JumpPower=State.Move.jp
        end
        notify("Fly","✈ Fly OFF", 2)
        return
    end
    local hrp=getRoot()
    local hum=getHum()
    if not hrp or not hum then return end
    State.Fly.active=true
    hum.PlatformStand=true
    
    State.Fly.bv=Instance.new("BodyVelocity",hrp)
    State.Fly.bv.MaxForce=Vector3.new(9e9,9e9,9e9)
    State.Fly.bv.Velocity=Vector3.zero
    
    State.Fly.bg=Instance.new("BodyGyro",hrp)
    State.Fly.bg.MaxTorque=Vector3.new(9e9,9e9,9e9)
    State.Fly.bg.P=50000 
    
    startFlyCapture()
    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value+1, function()
        if not State.Fly.active then return end
        local r=getRoot()
        if not r then return end
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
        
        if move.Magnitude > 0 then 
            State.Fly.bv.Velocity = move.Unit * spd 
        else
            State.Fly.bv.Velocity = Vector3.zero
        end
        
        State.Fly.bg.CFrame   = CFrame.new(r.Position, r.Position+camCF.LookVector)
    end)
    notify("Fly","✈ Fly ON", 2)
end

-- ══════════════════════════════════════════════════════════════
--  FREECAM ENGINE
-- ══════════════════════════════════════════════════════════════
local FC = {
    active=false, pos=Vector3.zero,
    pitchDeg=0, yawDeg=0, speed=5, sens=0.25,
    savedCF=nil
}
local fcRotT,fcMoveT,fcMoveSt,fcRotLast = nil,nil,nil,nil
local fcJoy   = Vector2.zero
local DEAD_X  = 25
local DEAD_Y = 20
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
    fcConns={}
    fcRotT=nil
    fcMoveT=nil
    fcMoveSt=nil
    fcRotLast=nil
    fcJoy=Vector2.zero
    FC._mouseRot=false
    FC._keys={}
    UIS.MouseBehavior=Enum.MouseBehavior.Default
end

local function startFCLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value+1, function(dt)
        if not FC.active then return end
        Cam.CameraType=Enum.CameraType.Scriptable
        
        local move = Vector3.zero
        local keys = FC._keys or {}
        
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
        
        local cf = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        FC.pos = FC.pos + cf:VectorToWorldSpace(move * (FC.speed * dt * 60))
        
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        
        local hrp=getRoot()
        local hum=getHum()
        if hrp and not hrp.Anchored then hrp.Anchored=true end
        if hum then 
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            hum.WalkSpeed=0
            hum.JumpPower=0 
        end
    end)
end

local function stopFCLoop()
    RS:UnbindFromRenderStep("XKIDFreecam")
end

-- ══════════════════════════════════════════════════════════════
--  MAIN WINDOW - CRIMSON THEME
-- ══════════════════════════════════════════════════════════════
local Window
local windowSuccess, windowError = pcall(function()
    Window = WindUI:CreateWindow({
        Title       = "⚡ 🛡 XKID HUB",
        Subtitle    = "Luxury Script by @WTF.XKID",
        Author      = "by @WTF.XKID",
        Folder      = "XKIDScript",
        Icon        = "zap",
        Theme       = "Crimson",
        Acrylic     = true,
        Transparent = true,
        Size        = UDim2.fromOffset(720, 580),
        MinSize     = Vector2.new(580, 440),
        MaxSize     = Vector2.new(880, 640),
        ToggleKey   = Enum.KeyCode.RightShift,
        Resizable   = true,
        AutoScale   = true,
        NewElements = true,
        SideBarWidth= 200,
        Topbar = { Height = 44, ButtonsType = "Default" },
        OpenButton  = {
            Title           = "⚡ 🛡 XKID HUB",
            Icon            = "zap",
            CornerRadius    = UDim.new(1, 0),
            StrokeThickness = 2,
            StrokeColor     = Color3.fromRGB(220, 20, 60),
            Enabled         = true,
            Draggable       = true,
            OnlyMobile      = false,
            Scale           = 0.9,
            Color = ColorSequence.new(
                Color3.fromRGB(30, 30, 40),
                Color3.fromRGB(40, 40, 50)
            ),
        },
        User = {
            Enabled   = true,
            Anonymous = false,
            Callback  = function()
                notify("⚡ 🛡 XKID HUB", "Designed by @WTF.XKID", 3)
            end,
        },
    })
end)

if not windowSuccess then
    warn("Failed to create window: " .. tostring(windowError))
    return
end

getgenv()._XKID_INSTANCE = Window.Instance
pcall(function() WindUI:SetTheme("Crimson") end)

-- ══════════════════════════════════════════════════════════════
--  FPS COUNTER SETUP (FIXED - Dideklarasikan sebelum digunakan)
-- ══════════════════════════════════════════════════════════════
TrackC(RS.RenderStepped:Connect(function(dt)
    table.insert(fpsSamples, dt)
    if #fpsSamples > 30 then table.remove(fpsSamples,1) end
end))

-- ══════════════════════════════════════════════════════════════
--  TAB 0: HOME SCREEN (WELCOME & STATUS)
-- ══════════════════════════════════════════════════════════════
local T_HOME = Window:Tab({ Title = "Home", Icon = "home" })

-- Welcome Panel
local secWelcome = T_HOME:Section({ Title = "⚡ 🛡 XKID HUB", Opened = true })
secWelcome:Paragraph({
    Title = "Welcome Back!",
    Desc  = "Premium Luxury Script — Designed by @WTF.XKID",
})

-- Status Panel
local secStatus = T_HOME:Section({ Title = "System Status", Opened = true })
local statusLabel = secStatus:Paragraph({
    Title = "Live Statistics",
    Desc  = "Loading...",
})

-- Update status loop
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(1)
        pcall(function()
            local fps = 60
            local ping = 0
            local playerCount = #Players:GetPlayers()
            local gameName = "Unknown"
            
            pcall(function()
                gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
            end)
            
            if #fpsSamples > 0 then
                local avg = 0
                for _,s in ipairs(fpsSamples) do avg=avg+s end
                avg = avg / #fpsSamples
                fps = math.floor(1/avg)
            end
            pcall(function() 
                ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) 
            end)
            
            local fpsColor = fps >= 60 and "🟢" or fps >= 30 and "🟡" or "🔴"
            local pingColor = ping < 100 and "🟢" or ping < 200 and "🟡" or "🔴"
            
            statusLabel:SetDesc(
                fpsColor .. "  FPS: " .. fps .. "\n" ..
                pingColor .. "  PING: " .. ping .. " ms\n" ..
                "👥  PLAYERS: " .. playerCount .. "\n" ..
                "🎮  GAME: " .. gameName .. "\n" ..
                "✅  SCRIPT: Loaded | Executor: Ready"
            )
        end)
    end
end)

-- Quick Actions Panel
local secActions = T_HOME:Section({ Title = "Quick Actions", Opened = true })
secActions:Button({
    Title    = "🔄 Rejoin Server",
    Desc     = "Teleport kembali ke server yang sama",
    Callback = function() 
        TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) 
    end,
})
secActions:Button({
    Title    = "⚡ Reset Character (/re)",
    Desc     = "Fast respawn tanpa bug",
    Callback = function() 
        fastRespawn() 
    end,
})
secActions:Button({
    Title    = "🔘 Toggle UI",
    Desc     = "Buka/Tutup menu",
    Callback = function() 
        Window:Toggle() 
    end,
})

-- Changelog Panel
local secChangelog = T_HOME:Section({ Title = "📋 Changelog", Opened = false })
secChangelog:Paragraph({
    Title = "Version 2.0 - Crimson Edition",
    Desc  = "✨ New Crimson Theme\n" ..
           "✨ Redesigned OpenButton\n" ..
           "✨ New Home Screen Dashboard\n" ..
           "✨ Optimized Performance\n" ..
           "✨ Improved Mobile Support\n" ..
           "✨ Live FPS & PING Display",
})

-- Credits Panel
local secCredits = T_HOME:Section({ Title = "💎 Credits", Opened = false })
secCredits:Paragraph({
    Title = "Designed & Developed by",
    Desc  = "@WTF.XKID",
})
secCredits:Paragraph({
    Title = "Powered by",
    Desc  = "WindUI - Modern Roblox UI Library",
})
secCredits:Paragraph({
    Title = "Version",
    Desc  = "XKID HUB V2 - Crimson Edition",
})

-- ══════════════════════════════════════════════════════════════
--  TAB 1: PLAYER
-- ══════════════════════════════════════════════════════════════
local T_AV = Window:Tab({ Title = "Player", Icon = "user" })

local secAvatar = T_AV:Section({ Title = "Avatar & Respawn", Opened = true })
secAvatar:Button({
    Title    = "⚡ Fast Respawn — /re",
    Desc     = "Respawn instan dan aman",
    Callback = function() 
        fastRespawn() 
    end,
})

local secMov = T_AV:Section({ Title = "Movement", Opened = true })
secMov:Button({
    Title    = "Refresh POV",
    Desc     = "Reset camera & character",
    Callback = function()
        local r=getRoot()
        local h=getHum()
        if not r or not h then 
            notify("Refresh","❌ Character not found")
            return 
        end
        Cam.CameraType=Enum.CameraType.Custom
        task.wait(0.05)
        Cam.CameraType=Enum.CameraType.Scriptable
        task.wait(0.05)
        Cam.CameraType=Enum.CameraType.Custom
        pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        notify("Refresh","✅ POV & camera reset!", 2)
    end,
})
secMov:Slider({
    Title = "Walk Speed",
    Desc  = "Default: 16",
    Step  = 1,
    Value = { Min = 16, Max = 500, Default = 16 },
    Callback = function(v)
        State.Move.ws = tonumber(v) or 16
        if getHum() then getHum().WalkSpeed = State.Move.ws end
    end,
})
secMov:Slider({
    Title = "Jump Power",
    Desc  = "Default: 50",
    Step  = 1,
    Value = { Min = 50, Max = 500, Default = 50 },
    Callback = function(v)
        State.Move.jp = tonumber(v) or 50
        local hum = getHum()
        if hum then 
            hum.UseJumpPower=true
            hum.JumpPower=State.Move.jp 
        end
    end,
})
secMov:Toggle({
    Title    = "Infinite Jump",
    Desc     = "Jump continuously",
    Value    = false,
    Callback = function(v)
        if v then
            State.Move.infJ = TrackC(UIS.JumpRequest:Connect(function()
                if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end
            end))
        else
            if State.Move.infJ then 
                State.Move.infJ:Disconnect()
                State.Move.infJ=nil 
            end
        end
    end,
})

local secAbi = T_AV:Section({ Title = "Abilities", Opened = true })
secAbi:Toggle({
    Title    = "Fly",
    Desc     = "Fly following camera direction",
    Value    = false,
    Callback = function(v) 
        toggleFly(v) 
    end,
})
secAbi:Slider({
    Title = "Fly Speed",
    Desc  = "Default: 60",
    Step  = 1,
    Value = { Min = 10, Max = 300, Default = 60 },
    Callback = function(v) 
        State.Move.flyS = tonumber(v) or 60 
    end,
})
secAbi:Toggle({
    Title    = "NoClip",
    Desc     = "Walk through walls",
    Value    = false,
    Callback = function(v) 
        State.Move.ncp = v 
    end,
})
secAbi:Toggle({
    Title    = "Extreme Fling",
    Desc     = "Violent collision + noclip",
    Value    = false,
    Callback = function(v) 
        State.Fling.active=v
        State.Move.ncp=v 
    end,
})
secAbi:Toggle({
    Title    = "Soft Fling",
    Desc     = "Gentle collision",
    Value    = false,
    Callback = function(v) 
        State.SoftFling.active=v
        State.Move.ncp=v 
    end,
})

local noFallConn = nil
secAbi:Toggle({
    Title    = "No Fall Damage",
    Desc     = "Prevents fall damage",
    Value    = false,
    Callback = function(v)
        if v then
            noFallConn = TrackC(RS.Heartbeat:Connect(function()
                local hrp=getRoot()
                if hrp and hrp.Velocity.Y < -30 then
                    hrp.Velocity=Vector3.new(hrp.Velocity.X,-10,hrp.Velocity.Z)
                end
            end))
        else
            if noFallConn then 
                noFallConn:Disconnect()
                noFallConn=nil 
            end
        end
    end,
})

local godConn,godRespConn,godLastPos = nil,nil,nil
secAbi:Toggle({
    Title    = "God Mode",
    Desc     = "Infinite HP + Auto respawn to last position",
    Value    = false,
    Callback = function(v)
        if v then
            local hum=getHum()
            if hum then 
                hum.MaxHealth=math.huge
                hum.Health=math.huge 
            end
            godLastPos  = getRoot() and getRoot().CFrame
            godRespConn = TrackC(RS.Heartbeat:Connect(function()
                local r=getRoot()
                if r then godLastPos=r.CFrame end
            end))
            godConn = TrackC(RS.Heartbeat:Connect(function()
                local h=getHum()
                if h then
                    if h.Health<h.MaxHealth then h.Health=h.MaxHealth end
                    if h.MaxHealth~=math.huge then h.MaxHealth=math.huge end
                end
            end))
            TrackC(LP.CharacterAdded:Connect(function(char)
                task.wait(0.2)
                local hrp=char:WaitForChild("HumanoidRootPart",5)
                if hrp and godLastPos then hrp.CFrame=godLastPos end
                local h=char:WaitForChild("Humanoid",5)
                if h then 
                    h.MaxHealth=math.huge
                    h.Health=math.huge 
                end
            end))
            notify("God Mode","🛡 Infinite HP active!", 3)
        else
            if godConn then 
                godConn:Disconnect()
                godConn=nil 
            end
            if godRespConn then 
                godRespConn:Disconnect()
                godRespConn=nil 
            end
            local hum=getHum()
            if hum then 
                hum.MaxHealth=100
                hum.Health=100 
            end
            notify("God Mode","❌ Disabled", 2)
        end
    end,
})

-- ══════════════════════════════════════════════════════════════
--  TAB 2: TELEPORT
-- ══════════════════════════════════════════════════════════════
local T_TP = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

local secTP = T_TP:Section({ Title = "Quick Teleport", Opened = true })
local tpTarget = ""

secTP:Input({
    Title       = "Search Player",
    Desc        = "Type player name",
    Placeholder = "player name...",
    Callback    = function(v) 
        tpTarget = v 
    end,
})
secTP:Button({
    Title    = "Teleport",
    Desc     = "Teleport to searched player",
    Callback = function()
        if tpTarget == "" then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                local nl = string.lower(p.Name)
                local dl = string.lower(p.DisplayName)
                local tl = string.lower(tpTarget)
                
                if (string.find(nl,tl) or string.find(dl,tl)) then
                    local tChar = p.Character
                    local tHrp = getCharRoot(tChar)
                    local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
                    local myHrp = getRoot()
                    
                    if tHrp and tHum and myHrp then
                        if tHum.Health <= 0 then
                            notify("Teleport", "❌ Target is dead!", 2)
                            return
                        end
                        
                        myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3) + Vector3.new(0, 2, 0)
                        myHrp.AssemblyLinearVelocity = Vector3.zero
                        notify("Teleport","✅ TP to "..p.DisplayName, 2)
                        return
                    end
                end
            end
        end
        notify("Teleport","❌ Player not found", 2)
    end,
})

local pDropOpts = getPNames()
secTP:Dropdown({
    Title    = "Player List",
    Desc     = "Select from list",
    Values   = pDropOpts,
    Callback = function(v) 
        tpTarget = v 
    end,
})
secTP:Button({
    Title    = "Refresh List",
    Desc     = "Update player list",
    Callback = function()
        pDropOpts = getPNames()
        notify("Teleport","List updated!", 2)
    end,
})

local secLoc = T_TP:Section({ Title = "Save & Load Location", Opened = true })
local SavedLocs = {}

for i = 1, 5 do
    local idx = i
    secLoc:Button({
        Title    = "Save Slot "..idx,
        Desc     = "Save current position",
        Callback = function()
            local r = getRoot()
            if not r then 
                notify("Location","❌ Character not found")
                return 
            end
            SavedLocs[idx] = r.CFrame
            notify("Location","💾 Slot "..idx.." saved!", 2)
        end,
    })
end
for i = 1, 5 do
    local idx = i
    secLoc:Button({
        Title    = "Load Slot "..idx,
        Desc     = "Teleport to saved location",
        Callback = function()
            if not SavedLocs[idx] then 
                notify("Location","❌ Slot "..idx.." empty!")
                return 
            end
            local r = getRoot()
            if not r then return end
            r.CFrame = SavedLocs[idx]
            notify("Location","📍 Teleported to Slot "..idx, 2)
        end,
    })
end

-- ══════════════════════════════════════════════════════════════
--  TAB 3: CAMERA & SPECTATE
-- ══════════════════════════════════════════════════════════════
local T_CAM = Window:Tab({ Title = "Camera", Icon = "eye" })

local secFC = T_CAM:Section({ Title = "Freecam", Opened = true })
secFC:Toggle({
    Title    = "Freecam",
    Desc     = "PC: RMB rotate | Mobile: Left move / Right rotate",
    Value    = false,
    Callback = function(v)
        FC.active = v
        State.Cinema.active = v
        if v then
            local cf=Cam.CFrame
            FC.pos=cf.Position
            FC.vel=Vector3.zero
            local rx,ry=cf:ToEulerAnglesYXZ()
            FC.pitchDeg=math.deg(rx)
            FC.yawDeg=math.deg(ry)
            FC._keys={}
            FC._mouseRot=false
            local hrp=getRoot()
            local hum=getHum()
            if hrp then 
                FC.savedCF=hrp.CFrame
                hrp.Anchored=true 
            end
            if hum then 
                hum.WalkSpeed=0
                hum.JumpPower=0
                hum:ChangeState(Enum.HumanoidStateType.Physics) 
            end
            startFCCapture()
            startFCLoop()
            notify("Freecam","🎬 ON", 2)
        else
            stopFCLoop()
            stopFCCapture()
            local hrp=getRoot()
            local hum=getHum()
            if hrp then
                hrp.Anchored=false
                if FC.savedCF then 
                    hrp.CFrame=FC.savedCF
                    FC.savedCF=nil 
                end
            end
            if hum then
                hum.WalkSpeed=State.Move.ws
                hum.UseJumpPower=true
                hum.JumpPower=State.Move.jp
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            Cam.FieldOfView=70
            Cam.CameraType=Enum.CameraType.Custom
            notify("Freecam","🎬 OFF", 2)
        end
    end,
})
secFC:Slider({ 
    Title="Speed", 
    Step=1, 
    Value={Min=1, Max=30, Default=5}, 
    Callback=function(v) 
        FC.speed = tonumber(v) or 5 
    end 
})
secFC:Slider({ 
    Title="Sensitivity", 
    Step=1, 
    Value={Min=1, Max=20, Default=5}, 
    Callback=function(v) 
        FC.sens = (tonumber(v) or 5)*0.05 
    end 
})
secFC:Slider({ 
    Title="FOV", 
    Step=1, 
    Value={Min=10, Max=120, Default=70}, 
    Callback=function(v) 
        Cam.FieldOfView = tonumber(v) or 70 
    end 
})

local secSP = T_CAM:Section({ Title = "Spectate Player", Opened = true })

local function inJoystick(pos)
    local ctrl = LP and LP.PlayerGui and LP.PlayerGui:FindFirstChild("TouchGui")
    if ctrl then
        local frame = ctrl:FindFirstChild("TouchControlFrame")
        local thumb = frame and frame:FindFirstChild("DynamicThumbstickFrame")
        if thumb then
            local ap=thumb.AbsolutePosition
            local as=thumb.AbsoluteSize
            if pos.X>=ap.X and pos.Y>=ap.Y and pos.X<=ap.X+as.X and pos.Y<=ap.Y+as.Y then 
                return true 
            end
        end
    end
    return false
end

local Spec = {
    active=false, target=nil, mode="third",
    dist=8, origFov=70, orbitYaw=0, orbitPitch=0, fpYaw=0, fpPitch=0,
}
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
                if Spec.mode=="third" then 
                    Spec.dist=math.clamp(Spec.dist-diff*0.03,3,30) 
                end
            end
            specPinchD=d
        end
    end))
    table.insert(specConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.Touch then return end
        for i,v in ipairs(specPinch) do 
            if v==inp then 
                table.remove(specPinch,i)
                break 
            end 
        end
        specPinchD=nil
        specTM = #specPinch==1 and specPinch[1] or nil
    end))
end

local function stopSpecCapture()
    for _,c in ipairs(specConns) do c:Disconnect() end
    specConns={}
    specTM=nil
    specPinch={}
    specPinchD=nil
    specPan=Vector2.zero
end

local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value+1, function()
        if not Spec.active then return end
        Cam.CameraType=Enum.CameraType.Scriptable
        local char=Spec.target and Spec.target.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local pan=specPan
        specPan=Vector2.zero
        local sens=0.3
        if Spec.mode=="third" then
            Spec.orbitYaw   = Spec.orbitYaw+pan.X*sens
            Spec.orbitPitch = math.clamp(Spec.orbitPitch+pan.Y*sens,-75,75)
            local oCF = CFrame.new(hrp.Position)
                * CFrame.Angles(0,math.rad(-Spec.orbitYaw),0)
                * CFrame.Angles(math.rad(-Spec.orbitPitch),0,0)
                * CFrame.new(0,0,Spec.dist)
            Cam.CFrame=CFrame.new(oCF.Position, hrp.Position+Vector3.new(0,1,0))
        else
            local head=char:FindFirstChild("Head")
            local origin=head and head.Position or hrp.Position+Vector3.new(0,1.5,0)
            Spec.fpYaw  = Spec.fpYaw-pan.X*sens
            Spec.fpPitch= math.clamp(Spec.fpPitch-pan.Y*sens,-85,85)
            Cam.CFrame  = CFrame.new(origin)
                * CFrame.Angles(0,math.rad(Spec.fpYaw),0)
                * CFrame.Angles(math.rad(Spec.fpPitch),0,0)
        end
    end)
end

local function stopSpecLoop()
    RS:UnbindFromRenderStep("XKIDSpec")
end

local specDropOpts = getDisplayNames()
secSP:Dropdown({
    Title    = "Target Player",
    Values   = specDropOpts,
    Callback = function(v)
        local p=findPlayerByDisplay(v)
        if p then
            Spec.target=p
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local _,ry,_=p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ()
                Spec.orbitYaw=math.deg(ry)
                Spec.orbitPitch=20
                Spec.fpYaw=math.deg(ry)
                Spec.fpPitch=0
            end
        end
    end,
})
secSP:Button({
    Title    = "Refresh List",
    Callback = function()
        Spec.target=nil
        specDropOpts=getDisplayNames()
        notify("Spectate","List updated!", 2)
    end,
})
secSP:Toggle({
    Title    = "Spectate ON",
    Value    = false,
    Callback = function(v)
        Spec.active=v
        if v then
            if not Spec.target then 
                notify("Spectate","Select target first!", 2)
                Spec.active=false
                return 
            end
            Spec.origFov=Cam.FieldOfView
            startSpecCapture()
            startSpecLoop()
            notify("Spectate","👁 Spectating: "..Spec.target.DisplayName, 2)
        else
            stopSpecLoop()
            stopSpecCapture()
            Cam.CameraType=Enum.CameraType.Custom
            Cam.FieldOfView=Spec.origFov
            notify("Spectate","Off", 2)
        end
    end,
})
secSP:Toggle({
    Title    = "First Person Mode",
    Value    = false,
    Callback = function(v) 
        Spec.mode=v and "first" or "third" 
    end,
})
secSP:Slider({
    Title="Orbit Distance", 
    Step=1, 
    Value={Min=3,Max=30,Default=8},
    Callback=function(v) 
        Spec.dist=tonumber(v) or 8 
    end,
})

-- ══════════════════════════════════════════════════════════════
--  TAB 4: WORLD
-- ══════════════════════════════════════════════════════════════
local T_WO = Window:Tab({ Title = "World", Icon = "globe" })

local function getAtm()
    return Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",Lighting)
end

local secWea = T_WO:Section({ Title = "Time Presets", Opened = true })
secWea:Button({ 
    Title="🌅 Pagi (Morning)", 
    Callback = function() 
        Lighting.ClockTime = 7
        Lighting.Brightness = 1 
    end 
})
secWea:Button({ 
    Title="☀ Siang (Day)", 
    Callback = function() 
        Lighting.ClockTime = 14
        Lighting.Brightness = 2 
    end 
})
secWea:Button({ 
    Title="🌇 Sore (Evening)", 
    Callback = function() 
        Lighting.ClockTime = 17.5
        Lighting.Brightness = 1.5 
    end 
})
secWea:Button({ 
    Title="🌃 Malam (Night)", 
    Callback = function() 
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.5 
    end 
})

local secAtmos = T_WO:Section({ Title = "Atmosphere", Opened = false })
secAtmos:Slider({ 
    Title="Clock Time", 
    Step=1, 
    Value={Min=0, Max=24, Default=14}, 
    Callback=function(v) 
        Lighting.ClockTime = tonumber(v) or 14 
    end 
})
secAtmos:Slider({ 
    Title="Brightness", 
    Step=0.1, 
    Value={Min=0, Max=5, Default=1}, 
    Callback=function(v) 
        Lighting.Brightness = tonumber(v) or 1 
    end 
})

secAtmos:Toggle({ 
    Title = "Fullbright (Clear Vision)", 
    Desc = "Terangkan tempat gelap & hapus kabut", 
    Value = false, 
    Callback = function(v)
        State.Atmos.fullbright = v
        if v then
            State.Atmos.default.Ambient = Lighting.Ambient
            State.Atmos.default.FogEnd = Lighting.FogEnd
            Lighting.Ambient = Color3.new(1,1,1)
            Lighting.ColorShift_Bottom = Color3.new(1,1,1)
            Lighting.ColorShift_Top = Color3.new(1,1,1)
            Lighting.FogEnd = 999999
        else
            Lighting.Ambient = State.Atmos.default.Ambient
            Lighting.FogEnd = State.Atmos.default.FogEnd
        end
    end 
})

local secGfx = T_WO:Section({ Title = "Graphics", Opened = false })
local function setGfx(level) 
    pcall(function() 
        settings().Rendering.QualityLevel=level 
    end) 
end
secGfx:Button({ 
    Title="🥔 Potato (Lv1)", 
    Callback=function() 
        setGfx(Enum.QualityLevel.Level01)
        notify("Graphics","Potato Lv1",2) 
    end 
})
secGfx:Button({ 
    Title="📊 Medium (Lv5)", 
    Callback=function() 
        setGfx(Enum.QualityLevel.Level05)
        notify("Graphics","Medium Lv5",2) 
    end 
})
secGfx:Button({ 
    Title="💎 Ultra (Lv10)", 
    Callback=function() 
        setGfx(Enum.QualityLevel.Level10)
        notify("Graphics","Ultra Lv10",2) 
    end 
})

-- ══════════════════════════════════════════════════════════════
--  TAB 5: ESP
-- ══════════════════════════════════════════════════════════════
local T_ESP = Window:Tab({ Title = "ESP", Icon = "radar" })

local secESP = T_ESP:Section({ Title = "Hybrid Detection ESP", Opened = true })
secESP:Toggle({
    Title    = "Enable ESP",
    Desc     = "Normal: Text & Tracer. Suspect: Box & Highlight",
    Value    = false,
    Callback = function(v)
        State.ESP.active = v
        if not v and getgenv()._XKID_ESP_CACHE then
            for _,c in pairs(getgenv()._XKID_ESP_CACHE) do
                pcall(function()
                    if c.texts then c.texts.Visible = false end
                    if c.tracer then c.tracer.Visible = false end
                    if c.boxLines then 
                        for _, l in ipairs(c.boxLines) do 
                            l.Visible = false 
                        end 
                    end
                    if c.hl then c.hl.Enabled = false end
                end)
            end
        end
        notify("ESP", v and "Hybrid ESP Active" or "Disabled", 2)
    end,
})

secESP:Dropdown({
    Title    = "Tracer Mode (Global)",
    Values   = {"Bottom","Center","Mouse","OFF"},
    Value    = "Bottom",
    Callback = function(v) 
        State.ESP.tracerMode=v 
    end,
})
secESP:Toggle({ 
    Title="Show Distance", 
    Value=true, 
    Callback=function(v) 
        State.ESP.showDistance=v 
    end 
})
secESP:Toggle({ 
    Title="Show Name", 
    Value=true, 
    Callback=function(v) 
        State.ESP.showNickname=v 
    end 
})
secESP:Slider({ 
    Title="Draw Distance", 
    Step=10, 
    Value={Min=50,Max=500,Default=300}, 
    Callback=function(v) 
        State.ESP.maxDrawDistance=tonumber(v) or 300 
    end 
})

local secESPColor = T_ESP:Section({ Title = "🎨 ESP Colors", Opened = false })
secESPColor:Dropdown({
    Title    = "Normal Tracer Color",
    Values   = {"Hijau", "Merah", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam"},
    Value    = "Hijau",
    Callback = function(v) 
        if colorMap[v] then 
            State.ESP.tracerColor_N = colorMap[v] 
        end 
    end,
})
secESPColor:Dropdown({
    Title    = "Suspect Full Color",
    Values   = {"Crimson", "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Putih", "Hitam"},
    Value    = "Crimson",
    Callback = function(v)
        if colorMap[v] then
            State.ESP.boxColor_S = colorMap[v]
            State.ESP.tracerColor_S = colorMap[v]
        end
    end,
})
secESPColor:Dropdown({
    Title    = "Text/Name Color",
    Values   = {"Putih", "Merah", "Hijau", "Biru", "Kuning", "Ungu", "Cyan", "Orange", "Pink", "Hitam"},
    Value    = "Putih",
    Callback = function(v) 
        if colorMap[v] then 
            State.ESP.nameColor = colorMap[v] 
        end 
    end,
})

-- ══════════════════════════════════════════════════════════════
--  TAB 6: SECURITY
-- ══════════════════════════════════════════════════════════════
local T_SEC = Window:Tab({ Title = "Security", Icon = "shield" })

local secProt = T_SEC:Section({ Title = "Protection", Opened = true })
secProt:Toggle({
    Title    = "Anti-AFK",
    Desc     = "Prevent AFK kick",
    Value    = false,
    Callback = function(v)
        if v then
            State.Security.afkConn = TrackC(LP.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                task.wait(1)
            end))
            notify("Anti-AFK","Active", 2)
        else
            if State.Security.afkConn then 
                State.Security.afkConn:Disconnect()
                State.Security.afkConn=nil 
            end
            notify("Anti-AFK","Disabled", 2)
        end
    end,
})
secProt:Button({
    Title    = "Rejoin Server",
    Callback = function() 
        TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) 
    end,
})

local antiGlitchConn = nil
secProt:Toggle({
    Title    = "Anti Screen-Block",
    Desc     = "Auto remove giant parts from other players",
    Value    = false,
    Callback = function(v)
        if v then
            antiGlitchConn = TrackC(RS.Heartbeat:Connect(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        for _, part in pairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") and (part.Size.X > 50 or part.Size.Y > 50 or part.Size.Z > 50) then
                                part:Destroy() 
                            end
                        end
                    end
                end
            end))
            notify("Anti-Glitch","Active", 2)
        else
            if antiGlitchConn then 
                antiGlitchConn:Disconnect()
                antiGlitchConn=nil 
            end
            notify("Anti-Glitch","Disabled", 2)
        end
    end,
})

local antiLag = { mats={}, texs={}, shadows=true }
secProt:Toggle({
    Title    = "Anti Lag Mode",
    Desc     = "Remove textures & shadows for better FPS",
    Value    = false,
    Callback = function(v)
        if v then
            antiLag.shadows=Lighting.GlobalShadows
            Lighting.GlobalShadows=false
            for _,obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    antiLag.mats[obj]=obj.Material
                    obj.Material=Enum.Material.SmoothPlastic
                elseif obj:IsA("Texture") or obj:IsA("Decal") then
                    antiLag.texs[obj]=obj.Parent
                    obj.Parent=nil
                end
            end
            notify("Anti Lag","Active", 2)
        else
            Lighting.GlobalShadows=antiLag.shadows
            for obj,mat in pairs(antiLag.mats) do 
                if obj and obj.Parent then 
                    obj.Material=mat 
                end 
            end
            for obj,par in pairs(antiLag.texs) do 
                if obj and par and par.Parent then 
                    obj.Parent=par 
                end 
            end
            antiLag.mats={}
            antiLag.texs={}
            notify("Anti Lag","Disabled", 2)
        end
    end,
})

-- ══════════════════════════════════════════════════════════════
--  TAB 7: SETTINGS
-- ══════════════════════════════════════════════════════════════
local T_SET = Window:Tab({ Title = "Settings", Icon = "settings" })

local secInfo = T_SET:Section({ Title = "System Info", Opened = true })
local statsLabel2 = secInfo:Paragraph({
    Title = "Performance Monitor",
    Desc  = "Loading...",
})

-- Live stats untuk settings tab
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(1)
        pcall(function()
            local fps = 60
            local ping = 0
            
            if #fpsSamples > 0 then
                local avg = 0
                for _,s in ipairs(fpsSamples) do avg=avg+s end
                avg = avg / #fpsSamples
                fps = math.floor(1/avg)
            end
            pcall(function() 
                ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) 
            end)
            
            local fpsColor = fps >= 60 and "🟢" or fps >= 30 and "🟡" or "🔴"
            local pingColor = ping < 100 and "🟢" or ping < 200 and "🟡" or "🔴"
            
            local gameName = "Unknown"
            pcall(function()
                gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
            end)
            
            statsLabel2:SetDesc(
                fpsColor .. "  FPS: " .. fps .. "\n" ..
                pingColor .. "  PING: " .. ping .. " ms\n" ..
                "🎮  Game: " .. gameName
            )
        end)
    end
end)

local secTheme = T_SET:Section({ Title = "Appearance", Opened = true })
secTheme:Dropdown({
    Title    = "Theme",
    Values   = (function()
        local names={}
        pcall(function()
            for name in pairs(WindUI:GetThemes()) do 
                table.insert(names,name) 
            end
        end)
        table.sort(names)
        return names
    end)(),
    Value    = "Crimson",
    Callback = function(selected) 
        pcall(function() 
            WindUI:SetTheme(selected) 
        end)
    end,
})
secTheme:Toggle({
    Title    = "Acrylic Background",
    Desc     = "Background blur effect",
    Value    = true,
    Callback = function()
        local isOn = false
        pcall(function()
            isOn = WindUI.Window.Acrylic
        end)
        pcall(function()
            WindUI:ToggleAcrylic(not isOn)
        end)
    end,
})
secTheme:Toggle({
    Title    = "Transparent Window",
    Desc     = "Window transparency",
    Value    = true,
    Callback = function(state) 
        pcall(function()
            Window:ToggleTransparency(state) 
        end)
    end,
})

local currentKey = Enum.KeyCode.RightShift
secTheme:Keybind({
    Title    = "Toggle Key",
    Desc     = "Menu open/close button",
    Value    = currentKey,
    Callback = function(v)
        currentKey = (typeof(v)=="EnumItem") and v or Enum.KeyCode[v]
        pcall(function()
            Window:SetToggleKey(currentKey)
        end)
    end,
})

-- ══════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS (Fling / NoClip)
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        pcall(function()
            if (State.Fling.active or State.SoftFling.active) and getRoot() then
                local r=getRoot()
                local brutal=State.Fling.active
                local pwr=brutal and State.Fling.power or State.SoftFling.power
                pcall(function()
                    r.AssemblyAngularVelocity=Vector3.new(0,pwr,0)
                    if brutal then r.AssemblyLinearVelocity=Vector3.new(pwr,pwr,pwr) end
                end)
            end
        end)
        RS.RenderStepped:Wait()
    end
end)

TrackC(RS.Stepped:Connect(function()
    pcall(function()
        if (State.Move.ncp or State.Fling.active or State.SoftFling.active) and LP.Character then
            for _,v in pairs(LP.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide=false end
            end
        end
    end)
end))

-- ══════════════════════════════════════════════════════════════
--  STARTUP NOTIFICATIONS
-- ══════════════════════════════════════════════════════════════
pcall(function()
    WindUI:SetNotificationLower(true)
    WindUI:Notify({ Title = "⚡ 🛡 XKID HUB", Content = "Crimson Edition — Ready.", Duration = 3 })
end)

task.spawn(function()
    task.wait(1.5)
    pcall(function()
        WindUI:Notify({ Title = "Hybrid ESP", Content = "Smart Detection Active. Zero FPS Drop.", Duration = 5 })
    end)
end)

print("✅ XKID HUB - Crimson Edition Loaded | Designed by @WTF.XKID")