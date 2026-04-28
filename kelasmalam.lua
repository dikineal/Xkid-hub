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

-- Trackers
TrackC(RS.RenderStepped:Connect(function(dt) if dt > 0 then sharedFPS = math.floor(1 / dt) end end))
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(0.5)
        pcall(function() local item = StatsService.Network.ServerStatsItem["Data Ping"]; if item then sharedPing = math.floor(item:GetValue()) end end)
    end
end)
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

-- ══════════════════════════════════════════════════════════════
--  FAST RESPAWN & REFRESH
-- ══════════════════════════════════════════════════════════════
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
--  FREECAM ENGINE (ROLL/TILT + SMOOTH + FIXED HEIGHT STOP)
-- ══════════════════════════════════════════════════════════════
local FC = {
    active   = false,
    pos      = Vector3.zero,
    pitchDeg = 0,
    yawDeg   = 0,
    rollDeg  = 0,
    speed    = 3,
    sens     = 0.25,
    savedCF  = nil,
    origFov  = 70,
}

local I_CamVel        = Vector3.zero
local I_YawVel        = 0
local I_PitchVel      = 0
local I_RollVel       = 0
local heightVelocity  = 0

local fcMoveTouch  = nil
local fcMoveSt     = nil
local fcJoy        = Vector2.zero
local fcRotTouch   = nil
local fcRotLast    = nil

local fcKeysHeld   = {}
local fcConns      = {}

local FC_UI_Btns = {
    up        = false,
    down      = false,
    rollLeft  = false,
    rollRight = false,
    zoomIn    = false,
    zoomOut   = false,
}

local FCUI = Instance.new("ScreenGui")
FCUI.Name          = "XKID_FreecamUI"
FCUI.ResetOnSpawn  = false
FCUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
FCUI.Enabled       = false
FCUI.Parent        = CoreGui
getgenv()._XKID_FCUI = FCUI

local function makeFCBtn(name, txt, pos, actionKey)
    local b = Instance.new("TextButton", FCUI)
    b.Name                 = name
    b.Size                 = UDim2.new(0, 52, 0, 52)
    b.Position             = pos
    b.BackgroundColor3     = Color3.fromRGB(15, 15, 15)
    b.BackgroundTransparency = 0.4
    b.Text                 = txt
    b.TextColor3           = Color3.fromRGB(255, 255, 255)
    b.TextSize             = 26
    b.Font                 = Enum.Font.GothamBold
    b.AutoButtonColor      = false

    local uic = Instance.new("UICorner", b); uic.CornerRadius = UDim.new(0, 10)
    local uis = Instance.new("UIStroke", b)
    uis.Color       = Color3.fromRGB(220, 20, 60)
    uis.Thickness   = 2
    uis.Transparency = 0.3

    local function press(down)
        FC_UI_Btns[actionKey]        = down
        b.BackgroundTransparency     = down and 0.05 or 0.4
    end

    b.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            press(true)
        end
    end)
    b.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            press(false)
        end
    end)
    b.MouseLeave:Connect(function() press(false) end)

    return b
end

makeFCBtn("BtnRollL", "↺", UDim2.new(1, -118, 0.5, -84), "rollLeft")
makeFCBtn("BtnRollR", "↻", UDim2.new(1, -58,  0.5, -84), "rollRight")
makeFCBtn("BtnUp",    "↑", UDim2.new(1, -118, 0.5, -26), "up")
makeFCBtn("BtnZIn",   "+", UDim2.new(1, -58,  0.5, -26), "zoomIn")
makeFCBtn("BtnDown",  "↓", UDim2.new(1, -118, 0.5,  32), "down")
makeFCBtn("BtnZOut",  "-", UDim2.new(1, -58,  0.5,  32), "zoomOut")

local function startFreecamCapture()
    fcKeysHeld = {}

    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        fcKeysHeld[inp.KeyCode] = true
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            FC._mouseRot = true
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end))

    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        fcKeysHeld[inp.KeyCode] = false
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            FC._mouseRot = false
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end))

    table.insert(fcConns, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and FC._mouseRot then
            I_YawVel   = I_YawVel   - inp.Delta.X * FC.sens * 120
            I_PitchVel = I_PitchVel - inp.Delta.Y * FC.sens * 120
        end
    end))

    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp.Position.X > Cam.ViewportSize.X / 2 then
            if not fcRotTouch then
                fcRotTouch = inp
                fcRotLast  = inp.Position
            end
        else
            if not fcMoveTouch then
                fcMoveTouch = inp
                fcMoveSt    = inp.Position
                fcJoy       = Vector2.zero
            end
        end
    end))

    table.insert(fcConns, UIS.TouchMoved:Connect(function(inp)
        if inp == fcRotTouch and fcRotLast then
            local dx = inp.Position.X - fcRotLast.X
            local dy = inp.Position.Y - fcRotLast.Y
            fcRotLast = inp.Position
            I_YawVel   = I_YawVel   - dx * FC.sens * 80
            I_PitchVel = I_PitchVel - dy * FC.sens * 80
        end

        if inp == fcMoveTouch and fcMoveSt then
            local dx = inp.Position.X - fcMoveSt.X
            local dy = inp.Position.Y - fcMoveSt.Y
            local function applyDead(val, dead, maxRange)
                if math.abs(val) < dead then return 0 end
                return math.clamp((val - math.sign(val) * dead) / (maxRange - dead), -1, 1)
            end
            fcJoy = Vector2.new(
                applyDead(dx, 15, 70),
                applyDead(dy, 15, 70)
            )
        end
    end))

    table.insert(fcConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if inp == fcRotTouch then
            fcRotTouch = nil
            fcRotLast  = nil
        end
        if inp == fcMoveTouch then
            fcMoveTouch = nil
            fcMoveSt    = nil
            fcJoy       = Vector2.zero
        end
    end))
end

local function stopFreecamCapture()
    for _, c in ipairs(fcConns) do c:Disconnect() end
    fcConns      = {}
    fcMoveTouch  = nil; fcMoveSt   = nil; fcJoy      = Vector2.zero
    fcRotTouch   = nil; fcRotLast  = nil
    fcKeysHeld   = {}
    FC._mouseRot = false
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    I_CamVel       = Vector3.zero
    I_YawVel       = 0
    I_PitchVel     = 0
    I_RollVel      = 0
    heightVelocity = 0
    for k in pairs(FC_UI_Btns) do FC_UI_Btns[k] = false end
end

local function startFreecamLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end
        Cam.CameraType = Enum.CameraType.Scriptable

        local safeDt = math.clamp(dt, 0.001, 0.05)

        -- ── 1. YAW & PITCH (mouse drag / touch drag) ──────────
        I_YawVel   = I_YawVel   * math.max(0, 1 - safeDt * 14)
        I_PitchVel = I_PitchVel * math.max(0, 1 - safeDt * 14)

        FC.yawDeg   = FC.yawDeg   + I_YawVel   * safeDt
        FC.pitchDeg = math.clamp(FC.pitchDeg + I_PitchVel * safeDt, -80, 80)

        -- ── 2. ROLL / TILT (↺ ↻ buttons) ─────────────────────
        local targetRoll = 0
        if FC_UI_Btns.rollLeft  then targetRoll = -35 end
        if FC_UI_Btns.rollRight then targetRoll =  35 end

        I_RollVel = I_RollVel + (targetRoll - I_RollVel) * math.clamp(safeDt * 6, 0, 1)
        FC.rollDeg = FC.rollDeg + I_RollVel * safeDt

        if not FC_UI_Btns.rollLeft and not FC_UI_Btns.rollRight then
            FC.rollDeg = FC.rollDeg * math.max(0, 1 - safeDt * 8)
            if math.abs(FC.rollDeg) < 0.1 then
                FC.rollDeg = 0
                I_RollVel = 0
            end
        end

        FC.rollDeg = math.clamp(FC.rollDeg, -45, 45)

        -- ── 3. POSISI (WASD / Joystick) ───────────────────────
        local camCF = CFrame.new(FC.pos)
            * CFrame.Angles(0, math.rad(FC.yawDeg), 0)
            * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)

        local joyX, joyY = fcJoy.X, fcJoy.Y
        if not onMobile then
            if fcKeysHeld[Enum.KeyCode.W] then joyY = joyY - 1 end
            if fcKeysHeld[Enum.KeyCode.S] then joyY = joyY + 1 end
            if fcKeysHeld[Enum.KeyCode.D] then joyX = joyX + 1 end
            if fcKeysHeld[Enum.KeyCode.A] then joyX = joyX - 1 end
        end

        local rawMove = Vector2.new(joyX, joyY)
        if rawMove.Magnitude > 1 then rawMove = rawMove.Unit end

        local moveTarget = (camCF.LookVector * (-rawMove.Y) + camCF.RightVector * rawMove.X)
            * (FC.speed * 60)

        local lerpFactor = math.clamp(safeDt * 3.5, 0, 1)
        I_CamVel = I_CamVel:Lerp(moveTarget, lerpFactor)

        -- ── 4. KETINGGIAN (E/Q atau tombol ↑↓) ───────────────
        local heightTarget = 0
        if fcKeysHeld[Enum.KeyCode.E] or FC_UI_Btns.up   then heightTarget =  FC.speed * 60 end
        if fcKeysHeld[Enum.KeyCode.Q] or FC_UI_Btns.down then heightTarget = -FC.speed * 60 end

        if heightTarget == 0 then
            heightVelocity = heightVelocity * math.max(0, 1 - safeDt * 10)
            if math.abs(heightVelocity) < 0.5 then heightVelocity = 0 end
        else
            heightVelocity = heightVelocity + (heightTarget - heightVelocity)
                * math.clamp(safeDt * 3, 0, 1)
        end

        -- ── 5. ZOOM (FOV) ──────────────────────────────────────
        if FC_UI_Btns.zoomIn  then Cam.FieldOfView = math.clamp(Cam.FieldOfView - 1.2, 10, 120) end
        if FC_UI_Btns.zoomOut then Cam.FieldOfView = math.clamp(Cam.FieldOfView + 1.2, 10, 120) end

        -- ── 6. APPLY (DENGAN ROLL) ────────────────────────────
        local finalVel = I_CamVel + Vector3.new(0, heightVelocity, 0)
        FC.pos = FC.pos + finalVel * safeDt

        Cam.CFrame = CFrame.new(FC.pos)
            * CFrame.Angles(0, math.rad(FC.yawDeg), 0)
            * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
            * CFrame.Angles(0, 0, math.rad(FC.rollDeg))

        local hrp, hum = getRoot(), getHum()
        if hrp and not hrp.Anchored then hrp.Anchored = true end
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end
    end)
end

local function stopFreecamLoop()
    RS:UnbindFromRenderStep("XKIDFreecam")
end

-- ══════════════════════════════════════════════════════════════
--  SPECTATE ENGINE
-- ══════════════════════════════════════════════════════════════
local function inJoystick(pos)
    local ctrl = LP and LP.PlayerGui and LP.PlayerGui:FindFirstChild("TouchGui")
    if not ctrl then return false end
    local frame = ctrl:FindFirstChild("TouchControlFrame"); local thumb = frame and frame:FindFirstChild("DynamicThumbstickFrame")
    if not thumb then return false end
    local ap, as = thumb.AbsolutePosition, thumb.AbsoluteSize
    return pos.X >= ap.X and pos.Y >= ap.Y and pos.X <= ap.X + as.X and pos.Y <= ap.Y + as.Y
end

local Spec = { active = false, target = nil, mode = "third", dist = 8, origFov = 70, orbitYaw = 0, orbitPitch = 0, fpYaw = 0, fpPitch = 0 }
local specTM, specPinch, specPinchD, specPan, specConns = nil, {}, nil, Vector2.zero, {}

local function startSpecCapture()
    table.insert(specConns, UIS.InputBegan:Connect(function(inp, gp)
        if gp or not Spec.active or inp.UserInputType ~= Enum.UserInputType.Touch or inJoystick(inp.Position) then return end
        table.insert(specPinch, inp); specTM = #specPinch == 1 and inp or nil
    end))
    table.insert(specConns, UIS.InputChanged:Connect(function(inp)
        if not Spec.active or inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if #specPinch == 1 and inp == specTM then specPan = specPan + Vector2.new(inp.Delta.X, inp.Delta.Y)
        elseif #specPinch >= 2 then
            local d = (specPinch[1].Position - specPinch[2].Position).Magnitude
            if specPinchD then
                local diff = d - specPinchD
                Cam.FieldOfView = math.clamp(Cam.FieldOfView - diff * 0.15, 10, 120)
                if Spec.mode == "third" then Spec.dist = math.clamp(Spec.dist - diff * 0.03, 3, 30) end
            end; specPinchD = d
        end
    end))
    table.insert(specConns, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        for i, v in ipairs(specPinch) do if v == inp then table.remove(specPinch, i); break end end
        specPinchD = nil; specTM = #specPinch == 1 and specPinch[1] or nil
    end))
end

local function stopSpecCapture()
    for _, c in ipairs(specConns) do c:Disconnect() end
    specConns = {}; specTM = nil; specPinch = {}; specPinchD = nil; specPan = Vector2.zero
end

local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value + 1, function()
        if not Spec.active then return end
        pcall(function()
            if not Spec.target or not Spec.target.Parent or not Spec.target.Character or not Spec.target.Character:FindFirstChild("HumanoidRootPart") then
                notify("System", "Target not valid! ⚠️", 2); Spec.active = false; stopSpecLoop(); stopSpecCapture()
                Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov; return
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
--  CHAT LOGGER
-- ══════════════════════════════════════════════════════════════
local chatLogPanel = nil
local function logMsg(speakerName, msg)
    if not State.Utility.chatLog then return end
    if State.Utility.chatTarget and State.Utility.chatTarget.Name ~= speakerName and State.Utility.chatTarget.DisplayName ~= speakerName then return end
    
    local entry = string.format("[%s] %s: %s", os.date("%H:%M:%S"), speakerName, msg)
    table.insert(State.Utility.chatHistory, entry)
    if #State.Utility.chatHistory > 50 then table.remove(State.Utility.chatHistory, 1) end
    if chatLogPanel then
        local logText = table.concat(State.Utility.chatHistory, "\n")
        if #logText > 2000 then logText = logText:sub(-2000) end
        pcall(function() chatLogPanel:SetDesc(logText) end)
    end
    notify("Chat", speakerName .. ": " .. msg, 3)
end

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    pcall(function() TrackC(TextChatService.MessageReceived:Connect(function(m) if m.TextSource then logMsg(m.TextSource.Name, m.Text) end end)) end)
else
    for _, p in ipairs(Players:GetPlayers()) do pcall(function() TrackC(p.Chatted:Connect(function(m) logMsg(p.Name, m) end)) end) end
    TrackC(Players.PlayerAdded:Connect(function(p) pcall(function() TrackC(p.Chatted:Connect(function(m) logMsg(p.Name, m) end)) end) end))
end

-- ══════════════════════════════════════════════════════════════
--  MAIN WINDOW UI SETUP
-- ══════════════════════════════════════════════════════════════
task.wait(0.3)
local Window = WindUI:CreateWindow({
    Title = "XKID", Subtitle = "Engine", Author = "by XKID", Folder = "XKIDScript", Icon = "terminal", Theme = "Crimson", Acrylic = true, Transparent = true, Size = UDim2.fromOffset(540, 460), MinSize = Vector2.new(440, 360), ToggleKey = Enum.KeyCode.RightShift, NewElements = true, SideBarWidth = 150,
    OpenButton = { Enabled = true, Draggable = true, CornerRadius = UDim.new(1, 0), StrokeThickness = 4, Scale = 0.75, Color = ColorSequence.new(Color3.fromRGB(225, 0, 120), Color3.fromRGB(0, 255, 255)) },
    User = { Enabled = true, Anonymous = false, UserId = LP.UserId, Callback = function() notify("System", "XKID Engine Identity Verified ✅", 3) end },
})
getgenv()._XKID_INSTANCE = Window.Instance; WindUI:SetTheme("Crimson")

task.spawn(function()
    local hue = 0
    while getgenv()._XKID_RUNNING do
        hue = (hue + 0.005) % 1
        local seq = ColorSequence.new(Color3.fromHSV(hue, 1, 1), Color3.fromHSV((hue + 0.5) % 1, 1, 1))
        pcall(function()
            local wind = CoreGui:FindFirstChild("WindUI"); if not wind then return end
            local openBtn = wind:FindFirstChild("OpenButton", true); if not openBtn then return end
            local stroke = openBtn:FindFirstChildOfClass("UIStroke")
            if stroke then local grad = stroke:FindFirstChildOfClass("UIGradient"); if not grad then grad = Instance.new("UIGradient", stroke) end; grad.Color = seq; grad.Rotation = (grad.Rotation + 5) % 360 end
            local bgGrad = openBtn:FindFirstChildOfClass("UIGradient"); if bgGrad then bgGrad.Color = seq; bgGrad.Rotation = (bgGrad.Rotation + 2) % 360 end
        end)
        task.wait(0.03)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 1: SYSTEM HUB
-- ══════════════════════════════════════════════════════════════
local T_HOME = Window:Tab({ Title = "System Hub", Icon = "layout-dashboard" })
local secWelcome = T_HOME:Section({ Title = "System Access", Opened = true })

secWelcome:Paragraph({ Title = "Identity Data", Desc = "\"Talk is cheap. Show me the code. 💻\"\n\n[ 👤 ] <font face='RobotoMono'>Operator :</font> @WTF.XKID\n[ 📱 ] <font face='RobotoMono'>TikTok   :</font> @wtf.xkid\n[ 💬 ] <font face='RobotoMono'>Discord  :</font> @4Sharken" })
secWelcome:Button({ Title = "Copy Discord Link", Desc = "Join the network", Callback = function() pcall(function() setclipboard("https://discord.gg/bzumc2u96") end); notify("System", "Link disalin ✅", 2) end })

local secStatus = T_HOME:Section({ Title = "Live Monitor", Opened = true })
local srvLabel = secStatus:Paragraph({ Title = "Server Info", Desc = "Loading..." })
local netLabel = secStatus:Paragraph({ Title = "Performance", Desc = "Loading..." })
local secSecHome = T_HOME:Section({ Title = "Security Check", Opened = true })
local securityLabel = secSecHome:Paragraph({ Title = "Diagnostics", Desc = "Protected" })

task.spawn(function()
    task.wait(2)
    local function lerpColor(c1, c2, t) return Color3.new(c1.R + (c2.R - c1.R) * t, c1.G + (c2.G - c1.G) * t, c1.B + (c2.B - c1.B) * t) end
    local function toHex(c) return string.format("#%02X%02X%02X", c.R*255, c.G*255, c.B*255) end
    local function makeBarA(val, maxVal, len, mode)
        local fill = math.clamp(math.floor((val/maxVal)*len), 0, len)
        local res = ""
        for i=1, len do
            if i <= fill then
                local t = (i-1)/math.max(1, len-1)
                local col = mode == "FPS" and lerpColor(Color3.fromRGB(0,255,255), Color3.fromRGB(0,100,255), t) or (t < 0.5 and lerpColor(Color3.fromRGB(0,255,0), Color3.fromRGB(255,255,0), t*2) or lerpColor(Color3.fromRGB(255,255,0), Color3.fromRGB(255,0,0), (t-0.5)*2))
                res = res .. '<font color="'..toHex(col)..'">▰</font>'
            else
                res = res .. '<font color="#444444">▱</font>'
            end
        end
        return res
    end

    while getgenv()._XKID_RUNNING do
        task.wait(0.5)
        pcall(function()
            if srvLabel and cachedMapName then
                local pCount = #Players:GetPlayers(); local mCount = Players.MaxPlayers
                local uptime = formatTime(os.difftime(os.time(), START_TIME))
                local job = game.JobId ~= "" and game.JobId:sub(1, 8).."..." or "N/A"
                srvLabel:SetDesc(string.format("[ 🗺️ ] <font face='RobotoMono'>Grid     :</font> %s\n[ 🆔 ] <font face='RobotoMono'>Node     :</font> %s\n[ 👥 ] <font face='RobotoMono'>Entities :</font> %d / %d\n[ ⏳ ] <font face='RobotoMono'>Session  :</font> %s", cachedMapName, job, pCount, mCount, uptime))
            end
        end)
        pcall(function()
            if netLabel then
                local fps = math.clamp(sharedFPS, 0, 300)
                local ping = math.clamp(sharedPing, 0, 9999)
                local fpsBar = makeBarA(fps, 120, 14, "FPS")
                local pingBar = makeBarA(ping, 200, 14, "PING")
                netLabel:SetDesc(string.format("<font face='RobotoMono'><b>FPS  </b></font> %s <font color='#FFFFFF'>%d</font>\n<font face='RobotoMono'><b>PING </b></font> %s <font color='#FFFFFF'>%dms</font>", fpsBar, fps, pingBar, ping))
            end
        end)
        pcall(function()
            if securityLabel then
                local afk = State.Security.afkConn and "🟢 ONLINE" or "🔴 OFFLINE"
                local sl = State.Security.shiftLock and "🟢 LOCKED" or "🔴 UNLOCKED"
                local vd = State.Security.voidConn and "🟢 SECURED" or "🔴 OFFLINE"
                local lag = State.Security.antiLag and "🟢 ACTIVE" or "🔴 INACTIVE"
                securityLabel:SetDesc(string.format("[ ⏰ ] <font face='RobotoMono'>AFK Protocol :</font> %s\n[ 🔒 ] <font face='RobotoMono'>Shift Lock   :</font> %s\n[ 🕳️ ] <font face='RobotoMono'>Void Shield  :</font> %s\n[ ⚡ ] <font face='RobotoMono'>Frame Boost  :</font> %s", afk, sl, vd, lag))
            end
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 2: PLAYER CORE
-- ══════════════════════════════════════════════════════════════
local T_AV = Window:Tab({ Title = "Player Core", Icon = "fingerprint" })
local secAvatarRefresh = T_AV:Section({ Title = "State Control", Opened = true })
secAvatarRefresh:Button({ Title = "Fast Respawn 💀", Desc = "Respawn on death point", Callback = function() fastRespawn() end })
secAvatarRefresh:Button({ Title = "Refresh Character", Desc = "Reload without kill", Callback = function() refreshCharacter() end })

local secMov = T_AV:Section({ Title = "Movement", Opened = true })
secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end })
secMov:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(v)
    if v then State.Move.infJ = TrackC(UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end))
    else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end end
end})

local secAbi = T_AV:Section({ Title = "Abilities", Opened = true })
secAbi:Toggle({ Title = "Fly ✈️", Value = false, Callback = function(v) toggleFly(v) end })
secAbi:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(v) State.Move.flyS = v end })

local noclipConn = nil
secAbi:Toggle({ Title = "NoClip", Value = false, Callback = function(v)
    State.Move.ncp = v
    if v then
        if not noclipConn then noclipConn = TrackC(RS.Heartbeat:Connect(function() if not State.Move.ncp then return end; if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)) end
    else if noclipConn then noclipConn:Disconnect(); noclipConn = nil end end
end})

local softFlingConn = nil
secAbi:Toggle({ Title = "Soft Fling ⚡", Value = false, Callback = function(v)
    State.SoftFling.active = v; State.Move.ncp = v
    if v then
        if not softFlingConn then softFlingConn = TrackC(RS.Heartbeat:Connect(function()
            if not State.SoftFling.active then return end; local r = getRoot(); if not r then return end
            pcall(function() r.AssemblyAngularVelocity = Vector3.new(0, State.SoftFling.power, 0); r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, 50, r.AssemblyLinearVelocity.Z) end)
            if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)) end
    else if softFlingConn then softFlingConn:Disconnect(); softFlingConn = nil end end
end})

-- ══════════════════════════════════════════════════════════════
--  TAB 3: NAVIGATION
-- ══════════════════════════════════════════════════════════════
local T_TP = Window:Tab({ Title = "Navigation", Icon = "crosshair" })
local secTPC = T_TP:Section({ Title = "Direct Teleport", Opened = true })
secTPC:Toggle({ Title = "Smart Touch/Click TP", Value = false, Callback = toggleSmartTP })

local secTP = T_TP:Section({ Title = "Target Teleport", Opened = true })
local tpTarget = ""
secTP:Input({ Title = "Search Player", Placeholder = "Type name...", Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "Execute TP ⚡", Callback = function()
    pcall(function()
        if tpTarget == "" then notify("Teleport", "Input target! ⚠️", 2); return end
        local target = nil
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and (string.find(string.lower(p.Name), string.lower(tpTarget)) or string.find(string.lower(p.DisplayName), string.lower(tpTarget))) then target = p; break end
        end
        if not target or not target.Parent or not target.Character then notify("Teleport", "Invalid Target ❌", 2); return end
        local tHrp = getCharRoot(target.Character); local tHum = target.Character:FindFirstChildOfClass("Humanoid"); local myHrp = getRoot()
        if not tHrp or not tHum or not myHrp or tHum.Health <= 0 then notify("Teleport", "Target is dead/failed ⚠️", 2); return end
        myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3) + Vector3.new(0, 2, 0); myHrp.AssemblyLinearVelocity = Vector3.zero
        notify("Teleport", "Teleporting to "..target.DisplayName.." ✅", 2)
    end)
end})

local pDropOpts = getDisplayNames()
local tpDropdown = secTP:Dropdown({ Title = "Player List", Values = pDropOpts, Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "Refresh List", Callback = function() pDropOpts = getDisplayNames(); pcall(function() tpDropdown:Refresh(pDropOpts, true) end); notify("System", "List updated ✅", 2) end })

local secLoc = T_TP:Section({ Title = "Coordinates Cache", Opened = true })
local SavedLocs = {}
for i = 1, 3 do
    local idx = i
    secLoc:Button({ Title = "💾 Save Slot "..idx, Callback = function() local r = getRoot(); if not r then notify("Error", "Character not found ⚠️", 2); return end; SavedLocs[idx] = r.CFrame; notify("Slot", "Slot "..idx.." saved ✅", 2) end })
    secLoc:Button({ Title = "📍 Load Slot "..idx, Callback = function() if not SavedLocs[idx] then notify("Error", "Slot is empty ⚠️", 2); return end; local r = getRoot(); if not r then return end; r.CFrame = SavedLocs[idx]; notify("Slot", "Loaded slot "..idx.." ✅", 2) end })
end

-- ══════════════════════════════════════════════════════════════
--  TAB 4: VISION
-- ══════════════════════════════════════════════════════════════
local T_CAM = Window:Tab({ Title = "Vision", Icon = "focus" })
T_CAM:Section({ Title = "Zoom Override", Opened = true }):Toggle({ Title = "Max Zoom Out", Value = false, Callback = function(v) pcall(function() LP.CameraMaxZoomDistance = v and 100000 or 400 end); notify("Vision", v and "Zoom override enabled ✅" or "Zoom normalized", 2) end })

local secSP = T_CAM:Section({ Title = "Spectator Mode", Opened = true })
local specDropOpts = getDisplayNames()
local specDropdown = secSP:Dropdown({ Title = "Select Target", Values = specDropOpts, Callback = function(v)
    local p = findPlayerByDisplay(v)
    if p then
        Spec.target = p
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ(); Spec.orbitYaw = math.deg(ry); Spec.orbitPitch = 20; Spec.fpYaw = math.deg(ry) end
        notify("Spectate", "Target locked: "..p.DisplayName.." ✅", 2)
    end
end})
secSP:Button({ Title = "Refresh Target List", Callback = function() specDropOpts = getDisplayNames(); pcall(function() specDropdown:Refresh(specDropOpts, true) end); notify("System", "List updated ✅", 2) end })
secSP:Toggle({ Title = "Enable Spectate", Value = false, Callback = function(v)
    Spec.active = v
    if v then
        if not Spec.target or not Spec.target.Parent or not Spec.target.Character or not Spec.target.Character:FindFirstChild("HumanoidRootPart") then notify("Spectate", "Select target first! ⚠️", 2); Spec.active = false; return end
        Spec.origFov = Cam.FieldOfView; startSpecCapture(); startSpecLoop(); notify("Spectate", "Tracking "..Spec.target.DisplayName.." 👀", 2)
    else stopSpecLoop(); stopSpecCapture(); Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov; notify("Spectate", "Tracking stopped ❌", 2) end
end})
secSP:Toggle({ Title = "First Person View", Value = false, Callback = function(v) Spec.mode = v and "first" or "third" end })
secSP:Slider({ Title = "Distance", Step = 1, Value = { Min = 3, Max = 30, Default = 8 }, Callback = function(v) Spec.dist = v end })

-- ══════════════════════════════════════════════════════════════
--  TAB 5: FREECAM (ROLL/TILT + SMOOTH)
-- ══════════════════════════════════════════════════════════════
local T_FREE = Window:Tab({ Title = "Freecam", Icon = "video" })

local secFC = T_FREE:Section({ Title = "Drone Engine", Opened = true })
secFC:Toggle({ Title = "Enable Freecam", Value = false, Callback = function(v)
    FC.active = v
    if v then
        local cf = Cam.CFrame; FC.pos = cf.Position
        local rx, ry = cf:ToEulerAnglesYXZ(); FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry)
        local hrp = getRoot(); if hrp then FC.savedCF = hrp.CFrame; hrp.Anchored = true end
        FC.origFov = Cam.FieldOfView
        startFreecamCapture(); startFreecamLoop()
        if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = true end
        notify("Freecam", "Drone deployed ✅", 2)
    else
        stopFreecamLoop(); stopFreecamCapture()
        local hrp = getRoot()
        if hrp then
            hrp.Anchored = false
            if FC.savedCF then hrp.CFrame = FC.savedCF; FC.savedCF = nil end
        end
        local hum = getHum()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            hum.WalkSpeed = State.Move.ws
            hum.UseJumpPower = true
            hum.JumpPower = State.Move.jp
        end
        Cam.CameraType = Enum.CameraType.Custom
        Cam.FieldOfView = FC.origFov
        if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = false end
        notify("Freecam", "Drone recalled ❌", 2)
    end
end})
secFC:Slider({ Title = "Camera Speed", Step = 0.5, Value = { Min = 1, Max = 20, Default = 3 }, Callback = function(v) FC.speed = v end })
secFC:Slider({ Title = "Sensitivity", Step = 0.05, Value = { Min = 0.1, Max = 1.0, Default = 0.25 }, Callback = function(v) FC.sens = v end })

local secCine = T_FREE:Section({ Title = "Cinematic Mode", Opened = true })
secCine:Toggle({ Title = "Hide All UI (Safe Mode)", Value = false, Callback = function(v)
    State.Cinema.hideUI = v; if v then for _, gui in pairs(LP.PlayerGui:GetChildren()) do if gui:IsA("ScreenGui") and gui.Enabled then table.insert(State.Cinema.cachedGuis, gui); gui.Enabled = false end end
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end); notify("Cinematic", "UI Hidden 🎬", 2)
    else for _, gui in pairs(State.Cinema.cachedGuis) do if gui and gui.Parent then gui.Enabled = true end end; State.Cinema.cachedGuis = {}
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end); notify("Cinematic", "UI Restored ✅", 2) end
end})
secCine:Toggle({ Title = "Hide Player Names & Bubble Chat", Value = false, Callback = function(v)
    State.Cinema.hideNames = v; if v then State.Cinema.nameConn = TrackC(RS.Heartbeat:Connect(function() for _, p in ipairs(Players:GetPlayers()) do if p.Character then local hum = p.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end for _, desc in ipairs(p.Character:GetDescendants()) do if desc:IsA("BillboardGui") then desc.Enabled = false end end end end end))
        notify("Cinematic", "Names & Chat wiped 🧹", 2) else if State.Cinema.nameConn then State.Cinema.nameConn:Disconnect(); State.Cinema.nameConn = nil end
        for _, p in ipairs(Players:GetPlayers()) do if p.Character then local hum = p.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end for _, desc in ipairs(p.Character:GetDescendants()) do if desc:IsA("BillboardGui") then desc.Enabled = true end end end end; notify("Cinematic", "Names & Chat restored ✅", 2) end
end})

-- ══════════════════════════════════════════════════════════════
--  TAB 6: WORLD EDITOR
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
        cc.Saturation = -0.05; cc.Contrast = 0.05
        bloom.Intensity = 0.3; bloom.Size = 24; Lighting.ClockTime = 8
    elseif filter == "Cinematic Soft" then
        cc.Saturation = 0.1; cc.Contrast = 0.15; cc.Brightness = 0.05
        bloom.Intensity = 0.2; Lighting.ClockTime = 17
    elseif filter == "Ultra HD" then
        cc.Saturation = 0.2; cc.Contrast = 0.3; bloom.Intensity = 0.2
    elseif filter == "Realistic" then
        cc.Saturation = 0.1; cc.Contrast = 0.2; bloom.Intensity = 0.15; Lighting.ClockTime = 15
    elseif filter == "Night HD" then
        cc.TintColor = Color3.fromRGB(200, 200, 255); cc.Saturation = 0.1; cc.Contrast = 0.2; bloom.Intensity = 0.15; Lighting.ClockTime = 1
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

local secAtmos = T_WO:Section({ Title = "Atmosphere Control", Opened = false })
local function getEff(cls) for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" and v:IsA(cls) then return v end end; local e = Instance.new(cls); e.Name = "_XKID_FILTER"; e.Parent = Lighting; return e end
secAtmos:Slider({ Title="Brightness", Step=0.1, Value={Min=0,Max=10,Default=1}, Callback=function(v) Lighting.Brightness=v end })
secAtmos:Slider({ Title="Exposure", Step=0.1, Value={Min=-5,Max=5,Default=0}, Callback=function(v) Lighting.ExposureCompensation=v end })
secAtmos:Slider({ Title="ClockTime", Step=0.1, Value={Min=0,Max=24,Default=14}, Callback=function(v) Lighting.ClockTime=v end })
secAtmos:Slider({ Title="Contrast", Step=0.1, Value={Min=-2,Max=2,Default=0}, Callback=function(v) getEff("ColorCorrectionEffect").Contrast=v end })
secAtmos:Slider({ Title="Bloom", Step=0.1, Value={Min=0,Max=5,Default=0}, Callback=function(v) getEff("BloomEffect").Intensity=v end })
secAtmos:Button({ Title="🔄 Reset Atmosphere", Callback=function() Lighting.Brightness = 1; Lighting.ExposureCompensation = 0; Lighting.ClockTime = 14; getEff("ColorCorrectionEffect").Contrast = 0; getEff("BloomEffect").Intensity = 0; notify("Atmosphere", "Reset to normal ✅", 2) end })

local secGfx = T_WO:Section({ Title = "Graphics Override", Opened = false })
local gfxMap = {[1]="Level01",[2]="Level03",[3]="Level05",[4]="Level07",[5]="Level09",[6]="Level11",[7]="Level13",[8]="Level15",[9]="Level17",[10]="Level21"}
secGfx:Slider({ Title="Quality Level", Step=1, Value={Min=1,Max=10,Default=1}, Callback=function(v) if gfxMap[v] then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel[gfxMap[v]] end) end end })

-- ══════════════════════════════════════════════════════════════
--  TAB 7: RADAR
-- ══════════════════════════════════════════════════════════════
local T_ESP = Window:Tab({ Title = "Radar", Icon = "cpu" })
local secESP = T_ESP:Section({ Title = "Detection System", Opened = true })
secESP:Toggle({ Title = "Enable Radar", Value = false, Callback = function(v)
    State.ESP.active = v
    if not v and State.ESP.cache then for _, c in pairs(State.ESP.cache) do pcall(function() if c.texts then c.texts.Visible = false end; if c.tracer then c.tracer.Visible = false end; for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end; if c.hl then c.hl.Enabled = false end end) end end
    notify("Radar", v and "System active ✅" or "System disabled ❌", 2)
end})
secESP:Dropdown({ Title = "Tracer Origin", Values = {"Bottom","Center","Mouse","OFF"}, Value = "Bottom", Callback = function(v) State.ESP.tracerMode = v end })
secESP:Toggle({ Title = "Highlight Entity", Value = false, Callback = function(v) State.ESP.highlightMode = v end })
secESP:Slider({ Title = "Scan Distance", Step = 10, Value = { Min = 50, Max = 500, Default = 300 }, Callback = function(v) State.ESP.maxDrawDistance = v end })

local secESPColor = T_ESP:Section({ Title = "Color Config", Opened = false })
secESPColor:Dropdown({ Title="Normal Color", Values={"Hijau","Merah","Biru","Kuning","Ungu","Cyan","Orange","Pink","Putih","Hitam"}, Value="Hijau", Callback=function(v) if colorMap[v] then State.ESP.tracerColor_N=colorMap[v] end end })
secESPColor:Dropdown({ Title="Suspect Color", Values={"Merah","Hijau","Biru","Kuning","Ungu","Cyan","Orange","Pink","Putih","Hitam","Crimson"}, Value="Crimson", Callback=function(v) if colorMap[v] then State.ESP.tracerColor_S=colorMap[v]; State.ESP.boxColor_S=colorMap[v] end end })
secESPColor:Dropdown({ Title="Glitch Acc Color", Values={"Orange","Merah","Hijau","Biru","Kuning","Ungu","Cyan","Pink","Putih","Hitam"}, Value="Orange", Callback=function(v) if colorMap[v] then State.ESP.tracerColor_G=colorMap[v]; State.ESP.boxColor_G=colorMap[v] end end })

-- ══════════════════════════════════════════════════════════════
--  TAB 8: UTILITY
-- ══════════════════════════════════════════════════════════════
local T_UTIL = Window:Tab({ Title = "Utility", Icon = "terminal" })
local secChat = T_UTIL:Section({ Title = "Chat Logger", Opened = true })
secChat:Toggle({ Title = "Enable Logger", Value = false, Callback = function(v) State.Utility.chatLog = v; notify("Utility", v and "Logger running ✅" or "Logger stopped ❌", 2) end })
chatLogPanel = secChat:Paragraph({ Title = "Console Output", Desc = "Waiting for data..." })
local chatTargetDrop = secChat:Dropdown({ Title = "Select Target", Values = getDisplayNames(), Callback = function(v)
    local p = findPlayerByDisplay(v)
    if p then State.Utility.chatTarget = p; State.Utility.chatHistory = {}; pcall(function() chatLogPanel:SetDesc("Tracking: "..p.DisplayName) end); notify("Utility", "Tracking target ✅", 2) end
end})
secChat:Button({ Title = "Refresh Target List", Callback = function() pcall(function() chatTargetDrop:Refresh(getDisplayNames(), true) end); notify("Utility", "List updated ✅", 2) end })
secChat:Button({ Title = "Clear Log", Callback = function() State.Utility.chatHistory = {}; pcall(function() chatLogPanel:SetDesc("Waiting for data...") end); notify("Utility", "Log cleared ❌", 2) end })
local secMisc = T_UTIL:Section({ Title = "Data Extraction", Opened = true })
secMisc:Button({ Title = "Copy JobID", Callback = function() pcall(function() setclipboard(game.JobId) end); notify("Utility", "JobID copied ✅", 2) end })

-- ══════════════════════════════════════════════════════════════
--  TAB 9: SECURITY
-- ══════════════════════════════════════════════════════════════
local T_SEC = Window:Tab({ Title = "Security", Icon = "shield-alert" })
local secProt = T_SEC:Section({ Title = "Protection Protocols", Opened = true })
secProt:Toggle({ Title = "Anti Void 🛡️", Value = false, Callback = function(v)
    if v then State.Security.voidConn = TrackC(RS.Heartbeat:Connect(function() local hrp = getRoot(); if hrp and hrp.Position.Y <= workspace.FallenPartsDestroyHeight + 50 then hrp.AssemblyLinearVelocity = Vector3.zero; hrp.CFrame = hrp.CFrame + Vector3.new(0, 300, 0); notify("Security", "Anti-Void saved entity 🛡️", 2) end end))
    else if State.Security.voidConn then State.Security.voidConn:Disconnect(); State.Security.voidConn = nil end end
    notify("Security", v and "Anti-Void Enabled ✅" or "Anti-Void Disabled ❌", 2)
end})
secProt:Toggle({ Title = "Anti AFK", Value = true, Callback = function(v)
    if v then if not State.Security.afkConn then State.Security.afkConn = TrackC(LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); task.wait(1) end)) end
    else if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn = nil end end
end})
secProt:Button({ Title = "Stuck Fix", Callback = function() local hrp, hum = getRoot(), getHum(); if hrp then hrp.Anchored = false; hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0) end; if hum then hum.Sit = false; hum:ChangeState(Enum.HumanoidStateType.Jumping) end; notify("Security", "Stuck fix applied ✅", 2) end })

local secSrv = T_SEC:Section({ Title = "Server Control", Opened = true })
secSrv:Toggle({ Title = "Auto Rejoin", Value = false, Callback = function(v)
    if v then
        State.Security.arConn = TrackC(GuiService.ErrorMessageChanged:Connect(function(err) if err and err ~= "" then notify("Security", "Error detected, rejoining... ⚠️", 3); task.wait(1); pcall(function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end) end end))
        notify("Security", "Auto Rejoin standby ✅", 2)
    else if State.Security.arConn then State.Security.arConn:Disconnect(); State.Security.arConn = nil end; notify("Security", "Auto Rejoin disabled ❌", 2) end
end})
secSrv:Button({ Title = "Force Rejoin", Callback = function() notify("System", "Rejoining... ⚡", 2); pcall(function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end) end })
secSrv:Button({ Title = "Server Hop ⚡", Callback = function()
    notify("System", "Searching new grid... ⚡", 2)
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if not req then notify("Error", "HTTP request failed ⚠️", 2); return end
        local res = req({Url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100", Method = "GET"})
        if res.StatusCode == 200 then local body = HttpService:JSONDecode(res.Body)
            if body and body.data then for _, v in ipairs(body.data) do if v.playing < v.maxPlayers and v.id ~= game.JobId then TPService:TeleportToPlaceInstance(game.PlaceId, v.id, LP); return end end end
        end
        notify("System", "No servers found ❌", 2)
    end)
end})

local secPerf = T_SEC:Section({ Title = "Performance Tweaks", Opened = true })
local advCache = { mats = {}, texs = {}, shadows = true, level = 10, brightness = 0, clockTime = 0, fogEnd = 0 }
secPerf:Toggle({ Title = "FPS Boost ⚡", Value = false, Callback = function(v)
    State.Security.antiLag = v
    if v then
        pcall(function() advCache.level = settings().Rendering.QualityLevel end)
        advCache.shadows = Lighting.GlobalShadows; advCache.brightness = Lighting.Brightness; advCache.clockTime = Lighting.ClockTime; advCache.fogEnd = Lighting.FogEnd
        pcall(function() settings().Rendering.QualityLevel = 1 end)
        Lighting.GlobalShadows = false; Lighting.Brightness = 1; Lighting.FogEnd = 100000
        for _, obj in pairs(workspace:GetDescendants()) do if obj:IsA("BasePart") then advCache.mats[obj] = obj.Material; obj.Material = Enum.Material.SmoothPlastic elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then advCache.texs[obj] = obj.Enabled; obj.Enabled = false end end
        notify("Performance", "FPS Boost activated ⚡", 2)
    else
        pcall(function() if advCache.level then settings().Rendering.QualityLevel = advCache.level end end)
        Lighting.GlobalShadows = advCache.shadows; Lighting.Brightness = advCache.brightness; Lighting.ClockTime = advCache.clockTime; Lighting.FogEnd = advCache.fogEnd
        for obj, mat in pairs(advCache.mats) do if obj and obj.Parent then obj.Material = mat end end
        for obj, enb in pairs(advCache.texs) do if obj and obj.Parent then obj.Enabled = enb end end
        advCache.mats = {}; advCache.texs = {}
        notify("Performance", "Graphics restored ✅", 2)
    end
end})

T_SEC:Section({ Title = "Camera Lock", Opened = true }):Toggle({ Title = "Force Shift Lock", Value = false, Callback = function(v) toggleShiftLock(v) end })

-- ══════════════════════════════════════════════════════════════
--  TAB 10: SETTINGS (CONFIG)
-- ══════════════════════════════════════════════════════════════
local T_SET = Window:Tab({ Title = "Config", Icon = "settings" })
local secCfg = T_SET:Section({ Title = "File Management", Opened = true })
local cfgName = "XKID_Config"
local currentConfig = "No config"

secCfg:Input({ Title = "Config Name", Default = "XKID_Config", Callback = function(v) cfgName = v end })
secCfg:Button({ Title = "💾 Save Config", Callback = function()
    pcall(function()
        if makefolder and writefile then if not isfolder("XKID_HUB") then makefolder("XKID_HUB") end
            local data = { Move = { ws = State.Move.ws, jp = State.Move.jp, flyS = State.Move.flyS }, ESP = { tracerMode = State.ESP.tracerMode, maxDrawDistance = State.ESP.maxDrawDistance, highlightMode = State.ESP.highlightMode }, Security = { shiftLock = State.Security.shiftLock, antiLag = State.Security.antiLag } }
            writefile("XKID_HUB/"..cfgName..".json", HttpService:JSONEncode(data)); notify("Config", "Data saved ✅", 2)
        end
    end)
end})
local configDrop = secCfg:Dropdown({ Title = "📂 Load Config", Values = getConfigList(), Callback = function(selected)
    currentConfig = selected
    if selected == "No config" then return end
    pcall(function()
        if isfile and readfile and isfile("XKID_HUB/"..selected..".json") then
            local data = HttpService:JSONDecode(readfile("XKID_HUB/"..selected..".json"))
            if data then
                if data.Move then State.Move.ws = data.Move.ws or 16; State.Move.jp = data.Move.jp or 50; State.Move.flyS = data.Move.flyS or 60; local h = getHum(); if h then h.WalkSpeed = State.Move.ws; h.UseJumpPower = true; h.JumpPower = State.Move.jp end end
                if data.ESP then State.ESP.tracerMode = data.ESP.tracerMode or "Bottom"; State.ESP.maxDrawDistance = data.ESP.maxDrawDistance or 300; State.ESP.highlightMode = data.ESP.highlightMode or false end
                if data.Security and data.Security.shiftLock ~= State.Security.shiftLock then toggleShiftLock(data.Security.shiftLock) end
                notify("Config", "Data loaded ✅", 2)
            end
        end
    end)
end})
secCfg:Button({ Title = "🗑️ Hapus Config", Callback = function()
    if currentConfig ~= "No config" and currentConfig ~= "" then
        pcall(function()
            if isfile and delfile and isfile("XKID_HUB/"..currentConfig..".json") then
                delfile("XKID_HUB/"..currentConfig..".json")
                notify("Config", currentConfig .. " dihapus 🗑️", 2)
                pcall(function() configDrop:Refresh(getConfigList(), true) end)
                currentConfig = "No config"
            end
        end)
    else notify("Config", "Pilih config dari Load List dulu! ⚠️", 2) end
end})
secCfg:Button({ Title = "🔄 Refresh Files", Callback = function() pcall(function() configDrop:Refresh(getConfigList(), true) end); notify("Config", "Files updated ✅", 2) end })

local secTheme = T_SET:Section({ Title = "Interface", Opened = true })
secTheme:Dropdown({ Title = "Theme", Values = (function() local n = {}; for name in pairs(WindUI:GetThemes()) do table.insert(n, name) end; table.sort(n); if not table.find(n, "Crimson") then table.insert(n, 1, "Crimson") end; return n end)(), Value = "Crimson", Callback = function(s) pcall(function() WindUI:SetTheme(s) end) end })
secTheme:Toggle({ Title = "Acrylic Blur", Value = true, Callback = function() pcall(function() WindUI:ToggleAcrylic(not WindUI.Window.Acrylic) end) end })
secTheme:Toggle({ Title = "Transparency", Value = true, Callback = function(s) pcall(function() Window:ToggleTransparency(s) end) end })
secTheme:Keybind({ Title = "Toggle Key", Value = Enum.KeyCode.RightShift, Callback = function(v) Window:SetToggleKey(typeof(v) == "EnumItem" and v or Enum.KeyCode[v]) end })

-- ══════════════════════════════════════════════════════════════
--  STARTUP
-- ══════════════════════════════════════════════════════════════
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
pcall(function() Window:SelectTab(T_HOME) end)
notify("System", "XKID Engine Ready ⚡", 2)
print("✅ XKID Engine - Freecam Roll/Tilt Ready")