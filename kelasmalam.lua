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

  V8 MODIFIED:
  • SDF Refresh (/re) Integrated
  • Realtime PING & FPS Counter
  • Ultra-Responsive Freecam
  • Anti-Glitcher Screen-Block
  • Aesthetic World Presets
]]

-- ══════════════════════════════════════════════════════════════
--  0. AUTO CLEANUP & MEMORY PLUG
-- ══════════════════════════════════════════════════════════════
if getgenv()._XKID_LOADED then
    pcall(function()
        for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
            if v.Name == "WindUI" or v.Name == "_XKIDEsp" then v:Destroy() end
        end
        if getgenv()._XKID_CONNS then
            for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end
        end
    end)
    collectgarbage("collect")
end
getgenv()._XKID_LOADED = true
getgenv()._XKID_CONNS = {}
local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

-- ══════════════════════════════════════════════════════════════
--  LOAD & SERVICES
-- ══════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local Players     = game:GetService("Players")
local RS          = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting    = game:GetService("Lighting")
local TPService   = game:GetService("TeleportService")
local StatsService= game:GetService("Stats")
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
    Security = { afkConn = nil, antiGlitch = false },
    Cinema   = { active = false },
    Spectate = { hideName = false },
    ESP = {
        active          = false, cache = {}, boxMode = "Corner", tracerMode = "Bottom",
        maxDrawDistance = 300, showDistance = true, showNickname = true,
        boxColor_N      = Color3.fromRGB(0, 255, 150), boxColor_S = Color3.fromRGB(255, 0, 100),
        tracerColor_N   = Color3.fromRGB(0, 200, 255), tracerColor_S = Color3.fromRGB(255, 50, 50),
        nameColor       = Color3.fromRGB(255, 255, 255)
    },
}

-- ══════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames() local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end; return t end
local function getDisplayNames() local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")") end end; return t end
local function findPlayerByDisplay(str) for _, p in pairs(Players:GetPlayers()) do if str == p.DisplayName .. " (@" .. p.Name .. ")" then return p end end; return nil end
local function getCharRoot(char) if not char then return nil end; return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart") end
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
--  COMMAND /RE (SDF STYLE - NO DELAY)
-- ══════════════════════════════════════════════════════════════
TrackC(LP.Chatted:Connect(function(msg)
    local cmd = string.lower(msg)
    if cmd == ":re" or cmd == "/re" then
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                -- Mengambil deskripsi terbaru secara instant
                local description = Players:GetHumanoidDescriptionFromUserId(LP.UserId)
                -- Menerapkan tanpa membunuh karakter (Local Refresh)
                hum:ApplyDescription(description)
                notify("System", "✨ Avatar Refreshed!", 2)
            end)
        end
    end
end))

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

local function drawLine(p1, p2, thick, color)
    local dist = (p1 - p2).Magnitude
    if dist < 1 then return nil end
    local dir = (p2 - p1).Unit
    local f = Instance.new("Frame", getESPGui())
    f.BackgroundColor3 = color; f.BorderSizePixel = 0
    f.Position = UDim2.new(0, ((p1 + p2) / 2).X - dist/2, 0, ((p1 + p2) / 2).Y - thick/2)
    f.Size = UDim2.new(0, dist, 0, thick)
    f.Rotation = math.deg(math.atan2(dir.Y, dir.X)); f.ZIndex = 10
    return f
end

local function renderESP(player)
    if not State.ESP.active or player == LP then return end
    local char = player.Character
    if not char then return end
    local hrp = getCharRoot(char)
    local myR = getCharRoot(LP.Character)
    if not hrp or not myR or (myR.Position - hrp.Position).Magnitude > State.ESP.maxDrawDistance then return end

    if not State.ESP.cache[player] then State.ESP.cache[player] = { renders = {}, hl = nil } end
    local cache = State.ESP.cache[player]
    for _, r in pairs(cache.renders) do if r and r.Parent then r:Destroy() end end
    cache.renders = {}

    local top, ton = Cam:WorldToScreenPoint(hrp.Position + Vector3.new(0, 2.5, 0))
    local bot, bon = Cam:WorldToScreenPoint(hrp.Position - Vector3.new(0, 3, 0))
    
    if ton or bon then
        local color = State.ESP.boxColor_N
        local h = math.abs(bot.Y - top.Y)
        local w = h * 0.6
        
        -- Box Logic
        if State.ESP.boxMode ~= "OFF" and State.ESP.boxMode ~= "HIGHLIGHT" then
            local tl = Vector2.new(bot.X - w/2, top.Y)
            local tr = Vector2.new(bot.X + w/2, top.Y)
            local bl = Vector2.new(bot.X - w/2, bot.Y)
            local br = Vector2.new(bot.X + w/2, bot.Y)
            
            local lines = {}
            if State.ESP.boxMode == "Corner" then
                local L = w / 3.5
                table.insert(cache.renders, drawLine(tl, tl + Vector2.new(L,0), 2, color))
                table.insert(cache.renders, drawLine(tl, tl + Vector2.new(0,L), 2, color))
                table.insert(cache.renders, drawLine(tr, tr - Vector2.new(L,0), 2, color))
                table.insert(cache.renders, drawLine(tr, tr + Vector2.new(0,L), 2, color))
                table.insert(cache.renders, drawLine(bl, bl + Vector2.new(L,0), 2, color))
                table.insert(cache.renders, drawLine(bl, bl - Vector2.new(0,L), 2, color))
                table.insert(cache.renders, drawLine(br, br - Vector2.new(L,0), 2, color))
                table.insert(cache.renders, drawLine(br, br - Vector2.new(0,L), 2, color))
            else
                table.insert(cache.renders, drawLine(tl, tr, 2, color))
                table.insert(cache.renders, drawLine(tr, br, 2, color))
                table.insert(cache.renders, drawLine(br, bl, 2, color))
                table.insert(cache.renders, drawLine(bl, tl, 2, color))
            end
        elseif State.ESP.boxMode == "HIGHLIGHT" then
            if not cache.hl or cache.hl.Parent ~= char then
                if cache.hl then cache.hl:Destroy() end
                cache.hl = Instance.new("Highlight", char)
                cache.hl.FillTransparency = 0.5; cache.hl.OutlineTransparency = 0
            end
            cache.hl.Enabled = true; cache.hl.FillColor = color
        end

        -- Name Label
        if State.ESP.showNickname then
            local lbl = Instance.new("TextLabel", getESPGui())
            lbl.Text = player.DisplayName; lbl.TextColor3 = State.ESP.nameColor
            lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12
            lbl.Size = UDim2.new(0, 100, 0, 20); lbl.Position = UDim2.new(0, top.X - 50, 0, top.Y - 25)
            table.insert(cache.renders, lbl)
        end
    end
end

TrackC(RS.RenderStepped:Connect(function()
    if State.ESP.active then for _, p in pairs(Players:GetPlayers()) do renderESP(p) end end
end))

-- ══════════════════════════════════════════════════════════════
--  FLY & FREECAM ENGINE (RESPONSIVE)
-- ══════════════════════════════════════════════════════════════
local FC = { active=false, pos=Vector3.zero, vel=Vector3.zero, pitchDeg=0, yawDeg=0, speed=8, sens=0.25, damping=0.15, accel=0.90 }
local fcJoy = Vector2.zero; local fcConns = {}

local function startFCLoop()
    RS:BindToRenderStep("XKIDFreecam", 201, function(dt)
        if not FC.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable
        local cf = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local dv = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dv = dv + cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dv = dv - cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dv = dv + cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dv = dv - cf.RightVector end
        if dv.Magnitude > 0 then dv = dv.Unit * FC.speed * 40 end
        FC.vel = FC.vel:Lerp(dv, FC.accel)
        FC.vel = FC.vel * (1 - FC.damping)
        FC.pos = FC.pos + FC.vel * dt
        Cam.CFrame = cf
        local hrp = getRoot(); if hrp then hrp.Anchored = true end
    end)
end

local function toggleFly(v)
    if not v then
        State.Fly.active = false; RS:UnbindFromRenderStep("XKIDFly")
        if State.Fly.bv then State.Fly.bv:Destroy(); State.Fly.bg:Destroy() end
        local h = getHum(); if h then h.PlatformStand = false; h:ChangeState(11) end
        return
    end
    local hrp = getRoot(); local hum = getHum()
    if not hrp or not hum then return end
    State.Fly.active = true; hum.PlatformStand = true
    State.Fly.bv = Instance.new("BodyVelocity", hrp); State.Fly.bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    State.Fly.bg = Instance.new("BodyGyro", hrp); State.Fly.bg.MaxTorque = Vector3.new(9e9,9e9,9e9)
    RS:BindToRenderStep("XKIDFly", 201, function()
        local camCF = Cam.CFrame; local spd = State.Move.flyS
        local mv = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - camCF.LookVector end
        if mv.Magnitude > 0 then mv = mv.Unit * spd end
        State.Fly.bv.Velocity = mv
        State.Fly.bg.CFrame = camCF
    end)
end

-- ══════════════════════════════════════════════════════════════
--  UI WINDOW & TABS
-- ══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title = "XKID SCRIPT V8", Author = "by XKID", Folder = "XKID_V8",
    Theme = "Rose", Transparent = true, Size = UDim2.fromOffset(650, 450),
    ToggleKey = Enum.KeyCode.RightShift
})

-- TAB: PLAYER
local T_PL = Window:Tab({ Title = "Player", Icon = "user" })
local secM = T_PL:Section({ Title = "Movement", Opened = true })
secM:Slider({ Title = "Walk Speed", Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
secM:Slider({ Title = "Jump Power", Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end })
secM:Toggle({ Title = "Fly", Callback = function(v) toggleFly(v) end })
secM:Slider({ Title = "Fly Speed", Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(v) State.Move.flyS = v end })

-- TAB: CINEMATIC
local T_CI = Window:Tab({ Title = "Cinematic", Icon = "video" })
local secF = T_CI:Section({ Title = "Responsive Freecam", Opened = true })
secF:Toggle({ Title = "Freecam Mode", Callback = function(v)
    FC.active = v
    if v then 
        FC.pos = Cam.CFrame.Position; startFCLoop() 
        notify("Cinema", "Freecam Active (Responsive)", 2)
    else 
        RS:UnbindFromRenderStep("XKIDFreecam")
        local hrp = getRoot(); if hrp then hrp.Anchored = false end
        Cam.CameraType = Enum.CameraType.Custom
    end
end })
secF:Slider({ Title = "Cam Speed", Value = { Min = 1, Max = 50, Default = 8 }, Callback = function(v) FC.speed = v end })

-- TAB: WORLD
local T_WO = Window:Tab({ Title = "World", Icon = "globe" })
local secW = T_WO:Section({ Title = "Aesthetic & Time", Opened = true })
secW:Slider({ Title = "Clock Time", Value = { Min = 0, Max = 24, Default = 14 }, Callback = function(v) Lighting.ClockTime = v end })
secW:Button({ Title = "🌸 Soft Aesthetic", Callback = function() Lighting.Brightness=1.5; Lighting.ClockTime=15; local a=Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",Lighting); a.Density=0.1; a.Offset=0.2; notify("World","Soft Applied",1) end })
secW:Button({ Title = "🌴 Vaporwave", Callback = function() Lighting.Brightness=2; Lighting.ClockTime=18; Lighting.FogColor=Color3.fromRGB(255,100,255); notify("World","Vapor Applied",1) end })

local secG = T_WO:Section({ Title = "Graphics Engine", Opened = true })
secG:Button({ Title = "🥔 Potato (Level 1)", Callback = function() settings().Rendering.QualityLevel = 1; notify("Graphics","Level 1",1) end })
secG:Button({ Title = "📊 Medium (Level 5)", Callback = function() settings().Rendering.QualityLevel = 5; notify("Graphics","Level 5",1) end })
secG:Button({ Title = "💎 Ultra (Level 10)", Callback = function() settings().Rendering.QualityLevel = 10; notify("Graphics","Level 10",1) end })

-- TAB: SECURITY
local T_SC = Window:Tab({ Title = "Security", Icon = "shield" })
local secP = T_SC:Section({ Title = "Protection", Opened = true })
secP:Toggle({ Title = "Anti Screen-Block (Anti-Glitcher)", Callback = function(v) State.Security.antiGlitch = v end })
TrackC(RS.Heartbeat:Connect(function()
    if State.Security.antiGlitch then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                for _, part in pairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") and (part.Size.X > 50 or part.Size.Y > 50 or part.Size.Z > 50) then part:Destroy() end
                end
            end
        end
    end
end))

secP:Toggle({ Title = "ESP Master", Callback = function(v) State.ESP.active = v end })

-- TAB: SETTINGS
local T_ST = Window:Tab({ Title = "Settings", Icon = "settings" })
local secI = T_ST:Section({ Title = "System Info", Opened = true })
local statsLabel = secI:Paragraph({ Title = "Performance", Desc = "Loading Statistics..." })

task.spawn(function()
    while true do
        local fps = math.floor(1/RS.RenderStepped:Wait())
        local ping = 0; pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        local fCol = fps > 50 and "🟢" or "🔴"; local pCol = ping < 150 and "🟢" or "🔴"
        statsLabel:SetDesc(string.format("%s %d FPS  |  %s %d ms PING", fCol, fps, pCol, ping))
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  INIT READY
-- ══════════════════════════════════════════════════════════════
WindUI:SetNotificationLower(true)
WindUI:Notify({ Title = "XKID V8 PRO", Content = "Script Loaded. Use /re to refresh avatar!", Duration = 5 })