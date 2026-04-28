--[[
========================
      @WTF.XKID
        Engine
========================
  💎 Dibuat oleh @WTF.XKID
  📱 Tiktok: @wtf.xkid
  💬 Discord: @4Sharken
]]

local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- ══════════════════════════════════════════════════════════════
--  0. CLEANUP AWAL
-- ══════════════════════════════════════════════════════════════
if getgenv()._XKID_RUNNING then
    getgenv()._XKID_RUNNING = false
    task.wait(0.1)
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
            if v.Name == "WindUI" or v.Name == "XKID_FreecamUI" then v:Destroy() end
        end
        for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
            if v.Name == "_XKID_FILTER" then v:Destroy() end
        end
        if getgenv()._XKID_CONNS then
            for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end
        end
    end)
    pcall(function() RS:UnbindFromRenderStep("XKIDFreecam") end)
    pcall(function() RS:UnbindFromRenderStep("XKIDFly") end)
    pcall(function() RS:UnbindFromRenderStep("XKIDSpec") end)
    pcall(function() RS:UnbindFromRenderStep("XKIDShiftLock") end)
    pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
    task.wait(0.2)
    collectgarbage("collect")
end

getgenv()._XKID_LOADED = true
getgenv()._XKID_RUNNING = true
getgenv()._XKID_CONNS = {}
local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

-- ══════════════════════════════════════════════════════════════
--  LOAD WINDUI
-- ══════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- ══════════════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════════════
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local VirtualUser  = game:GetService("VirtualUser")
local Lighting     = game:GetService("Lighting")
local TPService    = game:GetService("TeleportService")
local StatsService = game:GetService("Stats")
local CoreGui      = game:GetService("CoreGui")
local GuiService   = game:GetService("GuiService")
local TextChatService = game:GetService("TextChatService")
local StarterGui   = game:GetService("StarterGui")
local LP           = Players.LocalPlayer
local Cam          = workspace.CurrentCamera
local onMobile     = not UIS.KeyboardEnabled

-- ══════════════════════════════════════════════════════════════
--  STATE MANAGEMENT
-- ══════════════════════════════════════════════════════════════
local State = {
    Move      = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly       = { active = false, bv = nil, bg = nil, _keys = {} },
    SoftFling = { active = false, power = 50000 },
    Teleport  = { selectedTarget = "", clickTool = nil, clickConn = nil, clickActive = false, lastTap = 0 },
    Security  = { afkConn = nil, antiLag = false, shiftLock = false, shiftLockGyro = nil, voidConn = nil, arConn = nil, arFallback = nil },
    Cinema    = { hideUI = false, hideNames = false, nameConn = nil, cachedGuis = {} },
    Avatar    = { isRefreshing = false },
    Utility   = { chatLog = false, chatTarget = nil, chatHistory = {} },
    ESP = {
        active          = false,
        cache           = getgenv()._XKID_ESP_CACHE,
        tracerMode      = "Bottom",
        maxDrawDistance = 300,
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
    ["Biru"] = Color3.fromRGB(0, 0, 255), ["Kuning"] = Color3.fromRGB(255, 255, 0),
    ["Ungu"] = Color3.fromRGB(255, 0, 255), ["Cyan"] = Color3.fromRGB(0, 255, 255),
    ["Orange"] = Color3.fromRGB(255, 165, 0), ["Pink"] = Color3.fromRGB(255, 105, 180),
    ["Putih"] = Color3.fromRGB(255, 255, 255), ["Hitam"] = Color3.fromRGB(0, 0, 0),
    ["Crimson"] = Color3.fromRGB(220, 20, 60),
}

-- ══════════════════════════════════════════════════════════════
--  HELPER FUNCTIONS
-- ══════════════════════════════════════════════════════════════
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum()  return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getDisplayNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName) end end
    if #t == 0 then table.insert(t, "N/A") end
    return t
end
local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do if p.DisplayName == str or p.Name == str then return p end end
    return nil
end
local function getCharRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
end
local function notify(title, content, dur)
    pcall(function() WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 }) end)
end
local function formatTime(seconds)
    local m = math.floor(seconds / 60); local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end
local function getConfigList()
    local list = {}
    pcall(function()
        if isfolder and isfolder("XKID_HUB") then
            for _, file in ipairs(listfiles("XKID_HUB")) do
                if file:match("%.json$") then
                    local name = file:match("([^/\\]+)%.json$")
                    if name then table.insert(list, name) end
                end
            end
        end
    end)
    if #list == 0 then table.insert(list, "No config") end
    return list
end
local function isOnGround()
    local r = getRoot(); if not r then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character }
    return workspace:Raycast(r.Position, Vector3.new(0, -5, 0), params) ~= nil
end

local START_TIME = os.time()
local cachedMapName, lastMapCheck = nil, 0
local sharedFPS, sharedPing = 60, 0

-- FPS & Ping Trackers
TrackC(RS.RenderStepped:Connect(function(dt) if dt > 0 then sharedFPS = math.floor(1 / dt) end end))
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(0.5)
        pcall(function() local item = StatsService.Network.ServerStatsItem["Data Ping"]; if item then sharedPing = math.floor(item:GetValue()) end end)
    end
end)

-- Map Cache & GC
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        pcall(function() if tick() - lastMapCheck > 30 or not cachedMapName then cachedMapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name; lastMapCheck = tick() end end)
        task.wait(5)
    end
end)
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(120); collectgarbage("collect") end end)

-- ══════════════════════════════════════════════════════════════
--  CHARACTER HANDLER
-- ══════════════════════════════════════════════════════════════
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
end))

-- ══════════════════════════════════════════════════════════════
--  SHIFT LOCK & FAST RESPAWN ENGINE
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
            local hrp2, gyro = getRoot(), State.Security.shiftLockGyro
            if hrp2 and gyro and gyro.Parent == hrp2 then
                local flatLook = Vector3.new(Cam.CFrame.LookVector.X, 0, Cam.CFrame.LookVector.Z)
                if flatLook.Magnitude > 0.01 then gyro.CFrame = CFrame.new(hrp2.Position, hrp2.Position + flatLook) end
            end
        end)
        notify("System", "Shift Lock enabled ✅", 2)
    else
        RS:UnbindFromRenderStep("XKIDShiftLock")
        if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy(); State.Security.shiftLockGyro = nil end
        notify("System", "Shift Lock disabled ❌", 2)
    end
end

local function fastRespawn()
    if State.Avatar.isRefreshing then return end
    local char, hrp = LP.Character, getRoot()
    if not char or not hrp then notify("Error", "Character not found ⚠️", 2); return end
    State.Avatar.isRefreshing = true; notify("System", "Fast Respawn executed 💀", 1.5)
    local savedCF, prevRespawn = hrp.CFrame, LP.RespawnLocation
    LP.RespawnLocation = nil
    task.spawn(function()
        local done = false; local conn
        conn = LP.CharacterAdded:Connect(function(newChar)
            if done then return end; done = true; conn:Disconnect()
            local newHrp = newChar:FindFirstChild("HumanoidRootPart")
            if newHrp then newHrp.CFrame = savedCF + Vector3.new(0, 3.5, 0); newHrp.AssemblyLinearVelocity = Vector3.zero end
            local newHum = newChar:WaitForChild("Humanoid", 5); newHrp = newChar:WaitForChild("HumanoidRootPart", 5)
            task.wait(0.1)
            if newHrp and newHum then
                local t0 = tick(); local hold
                hold = RS.Heartbeat:Connect(function()
                    if tick() - t0 > 0.5 then hold:Disconnect(); return end
                    if newHrp and newHrp.Parent then newHrp.CFrame = savedCF + Vector3.new(0, 3.5, 0); newHrp.AssemblyLinearVelocity = Vector3.zero end
                end)
                Cam.CameraSubject = newHum; Cam.CameraType = Enum.CameraType.Custom
                if State.Move.ws ~= 16 then newHum.WalkSpeed = State.Move.ws end
                if State.Move.jp ~= 50 then newHum.UseJumpPower = true; newHum.JumpPower = State.Move.jp end
                notify("System", "Respawn success ✅", 2)
            end
            LP.RespawnLocation = prevRespawn; State.Avatar.isRefreshing = false
        end)
        char:BreakJoints()
        task.delay(8, function() if not done then conn:Disconnect(); LP.RespawnLocation = prevRespawn; State.Avatar.isRefreshing = false; Cam.CameraType = Enum.CameraType.Custom end end)
    end)
end

local function refreshCharacter()
    if State.Avatar.isRefreshing then return end
    local char, hrp = LP.Character, getRoot()
    if not char or not hrp then notify("Error", "Character not found ⚠️", 2); return end
    State.Avatar.isRefreshing = true; notify("System", "Refreshing character...", 1.5)
    local savedCF, prevRespawn = hrp.CFrame, LP.RespawnLocation
    LP.RespawnLocation = nil
    task.spawn(function()
        local done = false; local conn
        conn = LP.CharacterAdded:Connect(function(newChar)
            if done then return end; done = true; conn:Disconnect()
            local newHrp = newChar:FindFirstChild("HumanoidRootPart")
            if newHrp then newHrp.CFrame = savedCF + Vector3.new(0, 3.5, 0); newHrp.AssemblyLinearVelocity = Vector3.zero end
            local newHum = newChar:WaitForChild("Humanoid", 10); newHrp = newChar:WaitForChild("HumanoidRootPart", 10)
            task.wait(0.15)
            if newHrp and newHum then
                local t0 = tick(); local hold
                hold = RS.Heartbeat:Connect(function()
                    if tick() - t0 > 0.5 then hold:Disconnect(); return end
                    if newHrp and newHrp.Parent then newHrp.CFrame = savedCF + Vector3.new(0, 3.5, 0); newHrp.AssemblyLinearVelocity = Vector3.zero end
                end)
                Cam.CameraSubject = newHum; Cam.CameraType = Enum.CameraType.Custom
                if State.Move.ws ~= 16 then newHum.WalkSpeed = State.Move.ws end
                if State.Move.jp ~= 50 then newHum.UseJumpPower = true; newHum.JumpPower = State.Move.jp end
                notify("System", "Refresh success ✅", 2)
            else notify("Error", "Refresh failed ❌", 2) end
            LP.RespawnLocation = prevRespawn; State.Avatar.isRefreshing = false
        end)
        local ok = pcall(function() LP:LoadCharacter() end)
        if not ok then char:BreakJoints() end
        task.delay(15, function() if not done then conn:Disconnect(); LP.RespawnLocation = prevRespawn; State.Avatar.isRefreshing = false; Cam.CameraType = Enum.CameraType.Custom end end)
    end)
end

-- ══════════════════════════════════════════════════════════════
--  ESP ENGINE (OPTIMIZED)
-- ══════════════════════════════════════════════════════════════
local function initPlayerCache(player)
    if State.ESP.cache[player] then return end
    local cache = { texts = nil, tracer = nil, boxLines = {}, hl = nil, isSuspect = false, isGlitch = false, reason = "" }
    pcall(function()
        cache.texts = Drawing.new("Text")
        if cache.texts then cache.texts.Center = true; cache.texts.Outline = true; cache.texts.Font = 2; cache.texts.Size = 13; cache.texts.ZIndex = 2 end
        cache.tracer = Drawing.new("Line")
        if cache.tracer then cache.tracer.Thickness = 1.5; cache.tracer.ZIndex = 1 end
        for i = 1, 4 do local line = Drawing.new("Line")
            if line then line.Thickness = 1.5; line.ZIndex = 1; cache.boxLines[i] = line end
        end
    end)
    State.ESP.cache[player] = cache
end

local function clearPlayerCache(player)
    local c = State.ESP.cache[player]; if not c then return end
    pcall(function() if c.texts then c.texts:Remove() end end)
    pcall(function() if c.tracer then c.tracer:Remove() end end)
    for _, l in ipairs(c.boxLines) do pcall(function() if l then l:Remove() end end) end
    pcall(function() if c.hl then c.hl:Destroy() end end)
    State.ESP.cache[player] = nil
end
TrackC(Players.PlayerRemoving:Connect(clearPlayerCache))

local espsortedPlayers = {}
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if State.ESP.active then
            local tempSorted = {}
            local myHrp = getCharRoot(LP.Character)
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local isSus, isGlitch, reason = false, false, ""
                    for _, v in pairs(p.Character:GetChildren()) do
                        if v:IsA("BasePart") and (v.Size.X > 30 or v.Size.Y > 30 or v.Size.Z > 30) then isSus = true; reason = "Map Blocker"; break
                        elseif v:IsA("Accessory") then
                            local h = v:FindFirstChild("Handle")
                            if h and h:IsA("BasePart") then
                                if h.Size.Magnitude > 20 then isSus = true; reason = "Huge Hat"; break
                                elseif h.Size.Magnitude > 10 or (h.Transparency < 0.1 and h.Material == Enum.Material.Neon) then isGlitch = true; reason = "Glitch Acc" end
                            end
                        end
                    end
                    if not isSus and not isGlitch then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local bws, bhs = hum:FindFirstChild("BodyWidthScale"), hum:FindFirstChild("BodyHeightScale")
                            if (bws and bws.Value > 2.0) or (bhs and bhs.Value > 2.0) then isSus = true; reason = "Glitch Avatar" end
                        end
                    end
                    initPlayerCache(p)
                    if State.ESP.cache[p] then State.ESP.cache[p].isSuspect = isSus; State.ESP.cache[p].isGlitch = isGlitch; State.ESP.cache[p].reason = reason end
                    if myHrp then
                        local hrp = getCharRoot(p.Character)
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local dist = (hrp.Position - myHrp.Position).Magnitude
                            if dist <= State.ESP.maxDrawDistance then table.insert(tempSorted, {p = p, hrp = hrp, dist = dist, char = p.Character}) end
                        end
                    end
                end
            end
            table.sort(tempSorted, function(a, b) return a.dist < b.dist end)
            espsortedPlayers = tempSorted
        end
        task.wait(0.5)
    end
end)

TrackC(RS.RenderStepped:Connect(function()
    if not State.ESP.active then return end
    local myHrp = getCharRoot(LP.Character)
    if not myHrp then return end
    local vp = Cam.ViewportSize; local center = Vector2.new(vp.X / 2, vp.Y / 2)
    
    for _, c in pairs(State.ESP.cache) do
        pcall(function() if c.texts then c.texts.Visible = false end; if c.tracer then c.tracer.Visible = false end; for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end; if c.hl then c.hl.Enabled = false end end)
    end

    local hlCount = 0
    for _, data in ipairs(espsortedPlayers) do
        local player, char, hrp, dist = data.p, data.char, data.hrp, data.dist
        local c = State.ESP.cache[player]
        if not c then continue end

        local rootPos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end

        local isSus, isGlitch = c.isSuspect, c.isGlitch
        local useHl = isSus or isGlitch or State.ESP.highlightMode
        local txt = string.format("%s\n[%dm]", player.DisplayName, math.floor(dist))
        if isSus or isGlitch then txt = txt .. "\n⚠ " .. c.reason end
        
        local cColor = isSus and State.ESP.boxColor_S or (isGlitch and State.ESP.boxColor_G or State.ESP.nameColor)
        local tColor = isSus and State.ESP.tracerColor_S or (isGlitch and State.ESP.tracerColor_G or State.ESP.tracerColor_N)
        local bColor = isSus and State.ESP.boxColor_S or (isGlitch and State.ESP.boxColor_G or State.ESP.boxColor_N)

        pcall(function()
            if c.texts then c.texts.Text = txt; c.texts.Color = cColor; c.texts.Position = Vector2.new(rootPos.X, rootPos.Y - 45); c.texts.Visible = true end
            if State.ESP.tracerMode ~= "OFF" and c.tracer then
                local origin = Vector2.new(vp.X / 2, vp.Y)
                if State.ESP.tracerMode == "Center" then origin = center
                elseif State.ESP.tracerMode == "Mouse" then local m = UIS:GetMouseLocation(); origin = Vector2.new(m.X, m.Y) end
                c.tracer.From = origin; c.tracer.To = Vector2.new(rootPos.X, rootPos.Y); c.tracer.Color = tColor; c.tracer.Visible = true
            end
        end)

        if useHl and hlCount < 30 then
            hlCount = hlCount + 1
            pcall(function()
                local top, topOn = Cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local bot, botOn = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                if topOn and botOn and #c.boxLines == 4 then
                    local bh = math.abs(top.Y - bot.Y); local bw = bh * 0.6
                    c.boxLines[1].From = Vector2.new(rootPos.X - bw/2, top.Y); c.boxLines[1].To = Vector2.new(rootPos.X + bw/2, top.Y)
                    c.boxLines[2].From = Vector2.new(rootPos.X + bw/2, top.Y); c.boxLines[2].To = Vector2.new(rootPos.X + bw/2, bot.Y)
                    c.boxLines[3].From = Vector2.new(rootPos.X + bw/2, bot.Y); c.boxLines[3].To = Vector2.new(rootPos.X - bw/2, bot.Y)
                    c.boxLines[4].From = Vector2.new(rootPos.X - bw/2, bot.Y); c.boxLines[4].To = Vector2.new(rootPos.X - bw/2, top.Y)
                    for i = 1, 4 do c.boxLines[i].Color = bColor; c.boxLines[i].Visible = true end
                end
            end)
            pcall(function()
                if not c.hl or c.hl.Parent ~= char then if c.hl then c.hl:Destroy() end; c.hl = Instance.new("Highlight", char); c.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end
                if c.hl then c.hl.FillColor = bColor; c.hl.OutlineColor = Color3.new(1,1,1); c.hl.Enabled = true end
            end)
        end
    end
end))

-- ══════════════════════════════════════════════════════════════
--  FLY ENGINE
-- ══════════════════════════════════════════════════════════════
local flyMoveTouch, flyMoveSt, flyJoy, flyConns = nil, nil, Vector2.zero, {}
local flyVel = Vector3.zero

local function startFlyCapture()
    local keysHeld = {}
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end; local k = inp.KeyCode
        if k==Enum.KeyCode.W or k==Enum.KeyCode.A or k==Enum.KeyCode.S or k==Enum.KeyCode.D or k==Enum.KeyCode.E or k==Enum.KeyCode.Q then keysHeld[k] = true end
    end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp) keysHeld[inp.KeyCode] = nil end))
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp.Position.X <= Cam.ViewportSize.X / 2 then if not flyMoveTouch then flyMoveTouch = inp; flyMoveSt = inp.Position end end
    end))
    table.insert(flyConns, UIS.TouchMoved:Connect(function(inp)
        if inp == flyMoveTouch and flyMoveSt then
            local dx, dy = inp.Position.X - flyMoveSt.X, inp.Position.Y - flyMoveSt.Y
            flyJoy = Vector2.new(math.abs(dx)>25 and math.clamp((dx-math.sign(dx)*25)/80,-1,1) or 0, math.abs(dy)>20 and math.clamp((dy-math.sign(dy)*20)/80,-1,1) or 0)
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
        State.Fly.active = false; stopFlyCapture(); RS:UnbindFromRenderStep("XKIDFly")
        pcall(function() if State.Fly.bv then State.Fly.bv:Destroy() end end)
        pcall(function() if State.Fly.bg then State.Fly.bg:Destroy() end end)
        State.Fly.bv = nil; State.Fly.bg = nil; flyVel = Vector3.zero
        local hum = getHum()
        if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.WalkSpeed = State.Move.ws; hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
        notify("Movement", "Fly disabled ❌", 2); return
    end
    local hrp, hum = getRoot(), getHum(); if not hrp or not hum then return end
    State.Fly.active = true; hum.PlatformStand = true; flyVel = Vector3.zero
    State.Fly.bv = Instance.new("BodyVelocity", hrp); State.Fly.bv.MaxForce = Vector3.new(9e9,9e9,9e9); State.Fly.bv.Velocity = Vector3.zero
    State.Fly.bg = Instance.new("BodyGyro", hrp); State.Fly.bg.MaxTorque = Vector3.new(9e9,9e9,9e9); State.Fly.bg.P = 50000
    startFlyCapture()
    RS:BindToRenderStep("XKIDFly", Enum.RenderPriority.Camera.Value + 1, function()
        if not State.Fly.active then return end; local r = getRoot(); if not r then return end
        local camCF = Cam.CFrame; local spd = State.Move.flyS; local move = Vector3.zero; local keys = State.Fly._keys or {}
        if onMobile then move = camCF.LookVector * (-flyJoy.Y) + camCF.RightVector * flyJoy.X
        else
            if keys[Enum.KeyCode.W] then move = move + camCF.LookVector end
            if keys[Enum.KeyCode.S] then move = move - camCF.LookVector end
            if keys[Enum.KeyCode.D] then move = move + camCF.RightVector end
            if keys[Enum.KeyCode.A] then move = move - camCF.RightVector end
            if keys[Enum.KeyCode.E] then move = move + Vector3.new(0,1,0) end
            if keys[Enum.KeyCode.Q] then move = move - Vector3.new(0,1,0) end
        end
        local targetVel
        if move.Magnitude > 0 then targetVel = move.Unit * spd; flyVel = flyVel:Lerp(targetVel, 0.15)
        else
            if isOnGround() then flyVel = flyVel:Lerp(Vector3.zero, 0.1)
            else flyVel = flyVel:Lerp(Vector3.new(0, -0.8, 0), 0.08) end
        end
        if State.Fly.bv and State.Fly.bv.Parent then State.Fly.bv.Velocity = flyVel end
        if State.Fly.bg and State.Fly.bg.Parent then State.Fly.bg.CFrame = CFrame.new(r.Position, r.Position + camCF.LookVector) end
    end)
    notify("Movement", "Fly enabled ✈️", 2)
end

-- ══════════════════════════════════════════════════════════════
--  SMART CLICK TP (RAYCAST INJECTION)
-- ══════════════════════════════════════════════════════════════
local function toggleSmartTP(v)
    State.Teleport.clickActive = v
    if v then
        State.Teleport.clickConn = TrackC(UIS.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                local m = LP:GetMouse()
                if m.Hit then getRoot().CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3.5, 0)); getRoot().AssemblyLinearVelocity = Vector3.zero end
            elseif inp.UserInputType == Enum.UserInputType.Touch then
                if tick() - State.Teleport.lastTap < 0.4 then
                    local m = LP:GetMouse()
                    if m.Hit then getRoot().CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3.5, 0)); getRoot().AssemblyLinearVelocity = Vector3.zero end
                end
                State.Teleport.lastTap = tick()
            end
        end))
        notify("Teleport", "Smart TP: Double Tap / Ctrl+Click ✅", 2)
    else
        if State.Teleport.clickConn then State.Teleport.clickConn:Disconnect(); State.Teleport.clickConn = nil end
        notify("Teleport", "Smart TP Disabled ❌", 2)
    end
end

-- ══════════════════════════════════════════════════════════════
--  FREECAM ENGINE (SMOOTH LERP UI OVERLAY)
-- ══════════════════════════════════════════════════════════════
local FC = { active = false, pos = Vector3.zero, pitchDeg = 0, yawDeg = 0, speed = 3, sens = 0.25, savedCF = nil, origFov = 70 }
local fcMoveTouch, fcMoveSt, fcRotTouch, fcRotLast = nil, nil, nil, nil
local fcKeysHeld = {}
local FC_UI_Btns = { up = false, down = false, rotUp = false, rotDown = false, zoomIn = false, zoomOut = false }

local I_FlyJoy = Vector2.zero
local I_CamVel = Vector3.zero
local I_HeightVel = 0
local I_PitchVel = 0

local FCUI = Instance.new("ScreenGui")
FCUI.Name = "XKID_FreecamUI"; FCUI.ResetOnSpawn = false; FCUI.ZIndexBehavior = Enum.ZIndexBehavior.Global; FCUI.Enabled = false; FCUI.Parent = CoreGui
getgenv()._XKID_FCUI = FCUI

local function makeFCBtn(name, txt, pos, actionKey)
    local b = Instance.new("TextButton", FCUI)
    b.Name = name; b.Size = UDim2.new(0, 50, 0, 50); b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(15, 15, 15); b.BackgroundTransparency = 0.4
    b.Text = txt; b.TextColor3 = Color3.fromRGB(255, 255, 255); b.TextSize = 26; b.Font = Enum.Font.GothamBold
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    local uis = Instance.new("UIStroke", b); uis.Color = Color3.fromRGB(220, 20, 60); uis.Thickness = 2; uis.Transparency = 0.3
    b.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then FC_UI_Btns[actionKey] = true; b.BackgroundTransparency = 0.1 end end)
    b.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then FC_UI_Btns[actionKey] = false; b.BackgroundTransparency = 0.4 end end)
    return b
end

-- Layout Kanan 2x3 Matrix
local btnRotL = makeFCBtn("BtnRotL", "↺", UDim2.new(1, -120, 0.5, -80), "rotUp")
local btnRotR = makeFCBtn("BtnRotR", "↻", UDim2.new(1, -60, 0.5, -80), "rotDown")
local btnUp   = makeFCBtn("BtnUp", "↑", UDim2.new(1, -120, 0.5, -20), "up")
local btnZIn  = makeFCBtn("BtnZIn", "+", UDim2.new(1, -60, 0.5, -20), "zoomIn")
local btnDown = makeFCBtn("BtnDown", "↓", UDim2.new(1, -120, 0.5, 40), "down")
local btnZOut = makeFCBtn("BtnZOut", "-", UDim2.new(1, -60, 0.5, 40), "zoomOut")

local function startFreecamCapture()
    fcKeysHeld = {}
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end; fcKeysHeld[inp.KeyCode] = true
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
        if inp.Position.X > Cam.ViewportSize.X / 2 then if not fcRotTouch then fcRotTouch = inp; fcRotLast = inp.Position end
        else if not fcMoveTouch then fcMoveTouch = inp; fcMoveSt = inp.Position end end
    end))
    table.insert(fcConns, UIS.TouchMoved:Connect(function(inp)
        if inp == fcRotTouch and fcRotLast then
            FC.yawDeg = FC.yawDeg - (inp.Position.X - fcRotLast.X) * FC.sens; FC.pitchDeg = math.clamp(FC.pitchDeg - (inp.Position.Y - fcRotLast.Y) * FC.sens, -80, 80); fcRotLast = inp.Position
        end
        if inp == fcMoveTouch and fcMoveSt then
            local dx, dy = inp.Position.X - fcMoveSt.X, inp.Position.Y - fcMoveSt.Y
            fcMoveSt = inp.Position 
            State.Move.inf_virtual_joy = Vector2.new(math.clamp(dx/80,-1,1), math.clamp(dy/80,-1,1))
        end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == fcRotTouch then fcRotTouch = nil; fcRotLast = nil end
        if inp == fcMoveTouch then fcMoveTouch = nil; fcMoveSt = nil; State.Move.inf_virtual_joy = Vector2.zero end
    end))
end

local function stopFreecamCapture()
    for _, c in ipairs(fcConns) do c:Disconnect() end
    fcConns = {}; fcMoveTouch = nil; fcMoveSt = nil; fcRotTouch = nil; fcRotLast = nil; State.Move.inf_virtual_joy = Vector2.zero; fcKeysHeld = {}; FC_UI_Btns = { up = false, down = false, rotUp = false, rotDown = false, zoomIn = false, zoomOut = false }
    I_FlyJoy = Vector2.zero; I_CamVel = Vector3.zero; I_HeightVel = 0; I_PitchVel = 0
end

local function startFreecamLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end; Cam.CameraType = Enum.CameraType.Scriptable
        
        -- Smooth Joystick & Keys Acceleration
        local targetJoy = onMobile and (State.Move.inf_virtual_joy or Vector2.zero) or Vector2.zero
        if not onMobile then
            if fcKeysHeld[Enum.KeyCode.W] then targetJoy = targetJoy + Vector2.new(0, -1) end
            if fcKeysHeld[Enum.KeyCode.S] then targetJoy = targetJoy + Vector2.new(0, 1) end
            if fcKeysHeld[Enum.KeyCode.D] then targetJoy = targetJoy + Vector2.new(1, 0) end
            if fcKeysHeld[Enum.KeyCode.A] then targetJoy = targetJoy + Vector2.new(-1, 0) end
        end
        I_FlyJoy = I_FlyJoy:Lerp(targetJoy, math.clamp(dt * 8, 0, 1))

        -- Smooth Height Velocity
        local targetHeight = 0
        if fcKeysHeld[Enum.KeyCode.E] or FC_UI_Btns.up then targetHeight = 1 end
        if fcKeysHeld[Enum.KeyCode.Q] or FC_UI_Btns.down then targetHeight = -1 end
        I_HeightVel = math.lerp(I_HeightVel, targetHeight, math.clamp(dt * 10, 0, 1))

        -- Smooth Pitch (Vertical Rotation)
        local targetPitch = 0
        if FC_UI_Btns.rotUp then targetPitch = 1 end
        if FC_UI_Btns.rotDown then targetPitch = -1 end
        I_PitchVel = math.lerp(I_PitchVel, targetPitch, math.clamp(dt * 8, 0, 1))
        FC.pitchDeg = math.clamp(FC.pitchDeg + (I_PitchVel * FC.sens * 8 * dt * 60), -80, 80)

        -- Smooth FOV (Cinematic Zoom)
        local targetFov = Cam.FieldOfView
        if FC_UI_Btns.zoomIn then targetFov = math.clamp(targetFov - 1.5, 10, 120) end
        if FC_UI_Btns.zoomOut then targetFov = math.clamp(targetFov + 1.5, 10, 120) end
        Cam.FieldOfView = math.lerp(Cam.FieldOfView, targetFov, math.clamp(dt * 10, 0, 1))

        -- Apply Movement
        local camCF = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local inputMove = (camCF.LookVector * (-I_FlyJoy.Y) + camCF.RightVector * I_FlyJoy.X + Vector3.new(0, I_HeightVel, 0))
        I_CamVel = I_CamVel:Lerp(inputMove, math.clamp(dt * 12, 0, 1))

        if I_CamVel.Magnitude > 0.01 then FC.pos = FC.pos + (I_CamVel * FC.speed * dt * 60) end
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        
        local hrp, hum = getRoot(), getHum()
        if hrp and not hrp.Anchored then hrp.Anchored = true end
        if hum then hum:ChangeState(Enum.HumanoidStateType.Physics); hum.WalkSpeed = 0; hum.JumpPower = 0 end
    end)
end

local function stopFreecamLoop() RS:UnbindFromRenderStep("XKIDFreecam") end

-- ══════════════════════════════════════════════════════════════
--  MAIN WINDOW UI
-- ══════════════════════════════════════════════════════════════
task.wait(0.3)
local Window = WindUI:CreateWindow({
    Title = "XKID", Subtitle = "Engine", Author = "by XKID", Folder = "XKIDScript", Icon = "terminal", Theme = "Crimson", Acrylic = true, Transparent = true, Size = UDim2.fromOffset(540, 460), MinSize = Vector2.new(440, 360), ToggleKey = Enum.KeyCode.RightShift, NewElements = true, SideBarWidth = 150,
    OpenButton = { Enabled = true, Draggable = true, CornerRadius = UDim.new(1, 0), StrokeThickness = 4, Scale = 0.75, Color = ColorSequence.new(Color3.fromRGB(225, 0, 120), Color3.fromRGB(0, 255, 255)) },
    User = { Enabled = true, Anonymous = false, UserId = LP.UserId, Callback = function() notify("System", "XKID Engine Identity Verified ✅", 3) end },
})
getgenv()._XKID_INSTANCE = Window.Instance; WindUI:SetTheme("Crimson")

-- ══════════════════════════════════════════════════════════════
--  TAB 1: SYSTEM HUB
-- ══════════════════════════════════════════════════════════════
local T_HOME = Window:Tab({ Title = "System Hub", Icon = "layout-dashboard" })
local secWelcome = T_HOME:Section({ Title = "System Access", Opened = true })
secWelcome:Paragraph({ Title = "Identity Data", Desc = "\"Talk is cheap. Show me the code. 💻\"\n\n[ 👤 ] <font face='RobotoMono'>Operator :</font> @WTF.XKID\n[ 📱 ] <font face='RobotoMono'>TikTok   :</font> @wtf.xkid\n[ 💬 ] <font face='RobotoMono'>Discord  :</font> @4Sharken" })

local secStatus = T_HOME:Section({ Title = "Live Monitor", Opened = true })
local srvLabel = secStatus:Paragraph({ Title = "Server Info", Desc = "Loading..." })
local netLabel = secStatus:Paragraph({ Title = "Performance", Desc = "Loading..." })
local secSecHome = T_HOME:Section({ Title = "Security Check", Opened = true })
local securityLabel = secSecHome:Paragraph({ Title = "Diagnostics", Desc = "Protected" })

task.spawn(function()
    task.wait(2)
    local function makeBarA(val, maxVal, len, mode)
        local fill = math.clamp(math.floor((val/maxVal)*len), 0, len)
        local res = ""
        for i=1, len do
            if i <= fill then
                local t = (i-1)/math.max(1, len-1)
                local col = mode == "FPS" and Color3.fromRGB(0,255,255):Lerp(Color3.fromRGB(0,100,255),t) or (t<0.5 and Color3.fromRGB(0,255,0):Lerp(Color3.fromRGB(255,255,0),t*2) or Color3.fromRGB(255,255,0):Lerp(Color3.fromRGB(255,0,0),(t-0.5)*2))
                res = res .. string.format('<font color="#%02X%02X%02X">▰</font>',col.R*255,col.G*255,col.B*255)
            else res = res .. '<font color="#444444">▱</font>' end
        end
        return res
    end
    while getgenv()._XKID_RUNNING do
        task.wait(0.5); pcall(function() if srvLabel and cachedMapName then srvLabel:SetDesc(string.format("[ 🗺️ ] <font face='RobotoMono'>Grid     :</font> %s\n[ 🆔 ] <font face='RobotoMono'>Node     :</font> %s\n[ 👥 ] <font face='RobotoMono'>Entities :</font> %d / %d\n[ ⏳ ] <font face='RobotoMono'>Session  :</font> %s", cachedMapName, game.JobId:sub(1,8), #Players:GetPlayers(), Players.MaxPlayers, formatTime(os.difftime(os.time(), START_TIME)))) end end)
        pcall(function() if netLabel then netLabel:SetDesc(string.format("<font face='RobotoMono'><b>FPS  </b></font> %s <font color='#FFFFFF'>%d</font>\n<font face='RobotoMono'><b>PING </b></font> %s <font color='#FFFFFF'>%dms</font>", makeBarA(sharedFPS,120,14,"FPS"), sharedFPS, makeBarA(sharedPing,200,14,"PING"), sharedPing)) end end)
        pcall(function() if securityLabel then securityLabel:SetDesc(string.format("[ ⏰ ] <font face='RobotoMono'>AFK Protocol :</font> %s\n[ 🔒 ] <font face='RobotoMono'>Shift Lock   :</font> %s\n[ 🕳️ ] <font face='RobotoMono'>Void Shield  :</font> %s\n[ ⚡ ] <font face='RobotoMono'>Frame Boost  :</font> %s", State.Security.afkConn and "🟢 ONLINE" or "🔴 OFFLINE", State.Security.shiftLock and "🟢 LOCKED" or "🔴 UNLOCKED", State.Security.voidConn and "🟢 SECURED" or "🔴 OFFLINE", State.Security.antiLag and "🟢 ACTIVE" or "🔴 INACTIVE")) end end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 2: PLAYER CORE
-- ══════════════════════════════════════════════════════════════
local T_AV = Window:Tab({ Title = "Player Core", Icon = "fingerprint" })
local secAVR = T_AV:Section({ Title = "State Control", Opened = true })
secAVR:Button({ Title = "Fast Respawn 💀", Callback = fastRespawn })
secAVR:Button({ Title = "Refresh Character", Callback = refreshCharacter })
local secMov = T_AV:Section({ Title = "Movement", Opened = true })
secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end })

-- ══════════════════════════════════════════════════════════════
--  TAB 3: NAVIGATION
-- ══════════════════════════════════════════════════════════════
local T_TP = Window:Tab({ Title = "Navigation", Icon = "crosshair" })
local secTPC = T_TP:Section({ Title = "Direct Teleport", Opened = true })
secTPC:Toggle({ Title = "Smart Touch/Click TP", Value = false, Callback = toggleSmartTP })
local secLoc = T_TP:Section({ Title = "Coordinates Cache", Opened = true })
local SavedLocs = {}
for i = 1, 3 do
    secLoc:Button({ Title = "💾 Save Slot "..i, Callback = function() local r = getRoot(); if r then SavedLocs[i] = r.CFrame; notify("System", "Slot "..i.." saved ✅") end end })
    secLoc:Button({ Title = "📍 Load Slot "..i, Callback = function() if SavedLocs[i] then local r = getRoot(); if r then r.CFrame = SavedLocs[i]; notify("System", "Loaded slot "..i.." ✅") end else notify("Error", "Slot is empty ⚠️") end end })
end

-- ══════════════════════════════════════════════════════════════
--  TAB 4: FREECAM (SMOOTH DEDICATED TAB)
-- ══════════════════════════════════════════════════════════════
local T_FREE = Window:Tab({ Title = "Freecam", Icon = "video" })

local secFC = T_FREE:Section({ Title = "Drone Engine", Opened = true })
secFC:Toggle({ Title = "Enable Freecam", Value = false, Callback = function(v)
    FC.active = v; if v then local cf = Cam.CFrame; FC.pos = cf.Position; local rx, ry = cf:ToEulerAnglesYXZ(); FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry)
        local hrp, hum = getRoot(), getHum(); if hrp then FC.savedCF = hrp.CFrame; hrp.Anchored = true end
        FC.origFov = Cam.FieldOfView
        startFreecamCapture(); startFreecamLoop(); if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = true end; notify("Freecam", "Drone deployed ✅", 2)
    else stopFreecamLoop(); stopFreecamCapture(); local hrp, hum = getRoot(), getHum(); if hrp then hrp.Anchored = false; if FC.savedCF then hrp.CFrame = FC.savedCF end end
        Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = FC.origFov; if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = false end; notify("Freecam", "Drone recalled ❌", 2)
    end
end})
secFC:Slider({ Title = "Camera Speed", Step = 0.5, Value = { Min = 1, Max = 20, Default = 3 }, Callback = function(v) FC.speed = v end })
secFC:Slider({ Title = "Sensitivity", Step = 0.05, Value = { Min = 0.1, Max = 1.0, Default = 0.25 }, Callback = function(v) FC.sens = v end })

local secCine = T_FREE:Section({ Title = "Cinematic Mode", Opened = true })
secCine:Toggle({ Title = "Hide All UI (Safe Mode)", Value = false, Callback = function(v)
    State.Cinema.hideUI = v; if v then for _, gui in pairs(LP.PlayerGui:GetChildren()) do if gui:IsA("ScreenGui") and gui.Enabled then table.insert(State.Cinema.cachedGuis, gui); gui.Enabled = false end end
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end); notify("Cinematic", "UI Hidden🎬", 2)
    else for _, gui in pairs(State.Cinema.cachedGuis) do if gui and gui.Parent then gui.Enabled = true end end; State.Cinema.cachedGuis = {}
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end); notify("Cinematic", "UI Restored ✅", 2) end
end})
secCine:Toggle({ Title = "Hide Player Names & Bubble Chat", Value = false, Callback = function(v)
    State.Cinema.hideNames = v; if v then State.Cinema.nameConn = TrackC(RS.Heartbeat:Connect(function() for _, p in ipairs(Players:GetPlayers()) do if p.Character then local hum = p.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end for _, desc in ipairs(p.Character:GetDescendants()) do if desc:IsA("BillboardGui") then desc.Enabled = false end end end end end))
        notify("Cinematic", "Names & Chat wiped 🧹", 2) else if State.Cinema.nameConn then State.Cinema.nameConn:Disconnect(); State.Cinema.nameConn = nil end
        for _, p in ipairs(Players:GetPlayers()) do if p.Character then local hum = p.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end for _, desc in ipairs(p.Character:GetDescendants()) do if desc:IsA("BillboardGui") then desc.Enabled = true end end end end; notify("Cinematic", "Names & Chat restored ✅", 2) end
end})

-- ══════════════════════════════════════════════════════════════
--  TAB 5: WORLD EDITOR
-- ══════════════════════════════════════════════════════════════
local T_WO = Window:Tab({ Title = "World Editor", Icon = "layers" })
local secFilter = T_WO:Section({ Title = "Aesthetic Shaders", Opened = true })

local function resetLighting()
    for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" then v:Destroy() end end
    Lighting.ClockTime = 14; Lighting.Brightness = 1; Lighting.ExposureCompensation = 0
    Lighting.Ambient = Color3.fromRGB(127, 127, 127); Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    Lighting.GlobalShadows = true; Lighting.FogEnd = 100000; notify("World Editor", "Shaders reset ✅", 2)
end

local function applyFilter(filter)
    resetLighting()
    if filter == "Default" then return end
    
    local cc = Instance.new("ColorCorrectionEffect", Lighting); cc.Name = "_XKID_FILTER"
    local bloom = Instance.new("BloomEffect", Lighting); bloom.Name = "_XKID_FILTER"
    
    if filter == "Full Bright HD" then
        cc:Destroy(); bloom:Destroy()
        Lighting.GlobalShadows = false
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    elseif filter == "Soft Pastel HD" then
        cc.TintColor = Color3.fromRGB(255, 240, 245)
        cc.Saturation = -0.05
        cc.Contrast = 0.05
        bloom.Intensity = 0.3
        bloom.Size = 24
        Lighting.ClockTime = 8
    elseif filter == "Cinematic Soft" then
        cc.Saturation = 0.1
        cc.Contrast = 0.15
        cc.Brightness = 0.05
        bloom.Intensity = 0.2
        Lighting.ClockTime = 17
    elseif filter == "Ultra HD" then
        cc.Saturation = 0.2
        cc.Contrast = 0.3
        bloom.Intensity = 0.2
    elseif filter == "Realistic" then
        cc.Saturation = 0.1
        cc.Contrast = 0.2
        bloom.Intensity = 0.15
        Lighting.ClockTime = 15
    elseif filter == "Night HD" then
        cc.TintColor = Color3.fromRGB(200, 200, 255)
        cc.Saturation = 0.1
        cc.Contrast = 0.2
        bloom.Intensity = 0.15
        Lighting.ClockTime = 1
    end
    notify("World Editor", filter.." applied ✅", 2)
end

secFilter:Button({ Title = "☀️ Full Bright HD",  Callback = function() applyFilter("Full Bright HD")  end })
secFilter:Button({ Title = "🌸 Soft Pastel HD",   Callback = function() applyFilter("Soft Pastel HD")  end })
secFilter:Button({ Title = "🎬 Cinematic Soft",   Callback = function() applyFilter("Cinematic Soft")  end })
secFilter:Button({ Title = "💎 Ultra HD",      Callback = function() applyFilter("Ultra HD")     end })
secFilter:Button({ Title = "🌍 Realistic",     Callback = function() applyFilter("Realistic")    end })
secFilter:Button({ Title = "🌃 Night HD",      Callback = function() applyFilter("Night HD")     end })
secFilter:Button({ Title = "🔄 Reset Lighting",Callback = function() applyFilter("Default")      end })

-- ══════════════════════════════════════════════════════════════
--  TAB 6-9: UTILITY, SECURITY, SETTINGS
-- ══════════════════════════════════════════════════════════════
local T_UTIL = Window:Tab({ Title = "Utility", Icon = "terminal" })
local secC = T_UTIL:Section({ Title = "Chat Logger", Opened = true })
secC:Toggle({ Title = "Enable Logger", Value = false, Callback = function(v) State.Utility.chatLog = v end })
chatLogPanel = secC:Paragraph({ Title = "Output", Desc = "Waiting..." })

local T_SEC = Window:Tab({ Title = "Security", Icon = "shield-alert" })
T_SEC:Section({ Title = "Protocols", Opened = true }):Toggle({ Title = "Anti AFK", Value = true, Callback = function(v)
    if v then if not State.Security.afkConn then State.Security.afkConn = TrackC(LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); task.wait(1) end)) end else if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn = nil end end
end})

local T_SET = Window:Tab({ Title = "Config", Icon = "settings" })
local secCfg = T_SET:Section({ Title = "Files", Opened = true })
secCfg:Input({ Title = "Name", Default = "XKID_Config", Callback = function(v) cfgName = v end })
secCfg:Button({ Title = "Save 💾", Callback = function() pcall(function() if not isfolder("XKID_HUB") then makefolder("XKID_HUB") end; writefile("XKID_HUB/"..cfgName..".json", HttpService:JSONEncode({ Move={ws=State.Move.ws, jp=State.Move.jp}, ESP={tracerMode=State.ESP.tracerMode} })); notify("Config", "Saved ✅", 2) end) end })

pcall(function() Window:SelectTab(T_HOME) end)
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
notify("System", "XKID Engine Ready ⚡", 2); print("✅ XKID Engine v1.5 Ready")
