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
    Teleport  = { selectedTarget = "", clickTool = nil, clickConn = nil, clickActive = false },
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

-- FPS Tracker
TrackC(RS.RenderStepped:Connect(function(dt)
    if dt > 0 then sharedFPS = math.floor(1 / dt) end
end))

-- Ping Tracker
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(0.5)
        pcall(function()
            local item = StatsService.Network.ServerStatsItem["Data Ping"]
            if item then sharedPing = math.floor(item:GetValue()) end
        end)
    end
end)

-- Map Cache
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        pcall(function()
            if tick() - lastMapCheck > 30 or not cachedMapName then
                cachedMapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
                lastMapCheck = tick()
            end
        end)
        task.wait(5)
    end
end)

-- Garbage collector
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        task.wait(120)
        collectgarbage("collect")
    end
end)

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
    if State.Teleport.clickActive and State.Teleport.clickTool then
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
--  FAST RESPAWN
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

-- ══════════════════════════════════════════════════════════════
--  REFRESH CHARACTER
-- ══════════════════════════════════════════════════════════════
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
-- Background ESP Data Tracker
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
                    if State.ESP.cache[p] then 
                        State.ESP.cache[p].isSuspect = isSus; State.ESP.cache[p].isGlitch = isGlitch; State.ESP.cache[p].reason = reason 
                    end
                    
                    if myHrp then
                        local hrp = getCharRoot(p.Character)
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local dist = (hrp.Position - myHrp.Position).Magnitude
                            if dist <= State.ESP.maxDrawDistance then
                                table.insert(tempSorted, {p = p, hrp = hrp, dist = dist, char = p.Character})
                            end
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

-- Fast UI Render ESP
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
--  FREECAM ENGINE (SMOOTH & ANIMATED)
-- ══════════════════════════════════════════════════════════════
local FC = { active = false, pos = Vector3.zero, pitchDeg = 0, yawDeg = 0, speed = 3, sens = 0.25, savedCF = nil }
local fcMoveTouch, fcMoveSt, fcRotTouch, fcRotLast = nil, nil, nil, nil
local fcKeysHeld = {}
local FC_UI_Btns = { up = false, down = false, left = false, right = false }

-- Interpolation States
local I_FlyJoy = Vector2.zero
local I_CamVel = Vector3.zero
local I_HeightVel = 0
local I_RotVel = 0

-- Build Mobile Overlay UI
local FCUI = Instance.new("ScreenGui")
FCUI.Name = "XKID_FreecamUI"; FCUI.ResetOnSpawn = false; FCUI.ZIndexBehavior = Enum.ZIndexBehavior.Global; FCUI.Enabled = false; FCUI.Parent = CoreGui
getgenv()._XKID_FCUI = FCUI

local function makeFCBtn(name, txt, pos, actionKey)
    local b = Instance.new("TextButton", FCUI)
    b.Name = name; b.Size = UDim2.new(0, 60, 0, 60); b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(15, 15, 15); b.BackgroundTransparency = 0.5
    b.Text = txt; b.TextColor3 = Color3.fromRGB(255, 255, 255); b.TextSize = 30; b.Font = Enum.Font.GothamBold
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 15)
    local uis = Instance.new("UIStroke", b); uis.Color = Color3.fromRGB(220, 20, 60); uis.Thickness = 2; uis.Transparency = 0.3
    b.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then FC_UI_Btns[actionKey] = true end end)
    b.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then FC_UI_Btns[actionKey] = false end end)
    return b
end

local btnUp = makeFCBtn("BtnUp", "+", UDim2.new(1, -85, 0.5, -70), "up")
local btnDown = makeFCBtn("BtnDown", "-", UDim2.new(1, -85, 0.5, 10), "down")
local btnLeft = makeFCBtn("BtnLeft", "↺", UDim2.new(0.5, -80, 1, -100), "left")
local btnRight = makeFCBtn("BtnRight", "↻", UDim2.new(0.5, 20, 1, -100), "right")

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
            fcMoveSt = inp.Position -- Update center to drag region
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
    fcConns = {}; fcMoveTouch = nil; fcMoveSt = nil; fcRotTouch = nil; fcRotLast = nil; State.Move.inf_virtual_joy = Vector2.zero; fcKeysHeld = {}; FC_UI_Btns = { up = false, down = false, left = false, right = false }
    I_FlyJoy = Vector2.zero; I_CamVel = Vector3.zero; I_HeightVel = 0; I_RotVel = 0
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

        -- Smooth Rotation Velocity
        local targetRot = 0
        if FC_UI_Btns.left then targetRot = 1 end
        if FC_UI_Btns.right then targetRot = -1 end
        I_RotVel = math.lerp(I_RotVel, targetRot, math.clamp(dt * 8, 0, 1))
        
        -- Apply Rotation (Euler)
        FC.yawDeg = FC.yawDeg + (I_RotVel * FC.sens * 10 * dt * 60)

        -- Calculate CFrame & Smooth Movement Velocity
        local camCF = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local inputMove = (camCF.LookVector * (-I_FlyJoy.Y) + camCF.RightVector * I_FlyJoy.X + Vector3.new(0, I_HeightVel, 0))
        I_CamVel = I_CamVel:Lerp(inputMove, math.clamp(dt * 12, 0, 1)) -- Smooth Accel/Decel

        -- Apply Velocity to Position
        if I_CamVel.Magnitude > 0.01 then FC.pos = FC.pos + (I_CamVel * FC.speed * dt * 60) end
        
        -- Apply Final CFrame
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        
        -- Lock Character
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
secWelcome:Paragraph({ Title = "Identity Data", Desc = "[🖥️] SHARKEN_v1.3.37 :: Elevated Privileges: ACTIVE\n[Scrubbing_Identity_Diagnostics] Status: GHOST." })

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
        task.wait(0.5); pcall(function() if srvLabel and cachedMapName then srvLabel:SetDesc(string.format("[🗺️] Sector : %s\n[🆔] Node ID: %s\n[👥] Entities: %d / %d\n[⏳] Session: %s", cachedMapName, game.JobId:sub(1,8).."...", #Players:GetPlayers(), Players.MaxPlayers, formatTime(os.difftime(os.time(), START_TIME)))) end end)
        pcall(function() if netLabel then netLabel:SetDesc(string.format("<font face='RobotoMono'><b>FPS  </b></font> %s <font color='#FFFFFF'>%d</font>\n<font face='RobotoMono'><b>PING </b></font> %s <font color='#FFFFFF'>%dms</font>", makeBarA(sharedFPS,120,14,"FPS"), sharedFPS, makeBarA(sharedPing,200,14,"PING"), sharedPing)) end end)
        pcall(function() if securityLabel then securityLabel:SetDesc(string.format("[⏰] AFK Protocol: %s\n[🔒] Shift Lock: %s\n[🕳️] Void Shield: %s\n[⚡] Frame Boost: %s", State.Security.afkConn and "🟢 Active" or "🔴 Offline", State.Security.shiftLock and "🟢 Locked" or "🔴 Unlocked", State.Security.voidConn and "🟢 Secured" or "🔴 Offline", State.Security.antiLag and "🟢 Active" or "🔴 Inactive")) end end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 2: PLAYER CORE
-- ══════════════════════════════════════════════════════════════
local T_AV = Window:Tab({ Title = "Player Core", Icon = "fingerprint" })
local secAVR = T_AV:Section({ Title = "State Control", Opened = true })
secAVR:Button({ Title = "Fast Respawn 💀", Desc = "Respawn on death point", Callback = fastRespawn })
secAVR:Button({ Title = "Refresh Character", Desc = "Reload without kill", Callback = refreshCharacter })

local secMov = T_AV:Section({ Title = "Movement", Opened = true })
secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end })

-- ══════════════════════════════════════════════════════════════
--  TAB 3: NAVIGATION
-- ══════════════════════════════════════════════════════════════
local T_TP = Window:Tab({ Title = "Navigation", Icon = "crosshair" })
local secTPC = T_TP:Section({ Title = "Point Teleport", Opened = true })
secTPC:Toggle({ Title = "Click TP Tool", Value = false, Callback = function(v)
    if v then
        if State.Teleport.clickTool then State.Teleport.clickTool:Destroy() end; local tool = Instance.new("Tool"); tool.Name = "Click TP"; tool.RequiresHandle = false; tool.Parent = LP.Backpack; State.Teleport.clickTool = tool; State.Teleport.clickActive = true
        State.Teleport.clickConn = tool.Activated:Connect(function() local m, r = LP:GetMouse(), getRoot(); if r and m and m.Hit then r.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3.5, 0)); r.AssemblyLinearVelocity = Vector3.zero end end)
        notify("Teleport", "Tool injected ✅", 2)
    else State.Teleport.clickActive = false; if State.Teleport.clickTool then State.Teleport.clickTool:Destroy(); State.Teleport.clickTool = nil end; if State.Teleport.clickConn then State.Teleport.clickConn:Disconnect(); State.Teleport.clickConn = nil end; notify("Teleport", "Tool removed ❌", 2) end
end})

-- ══════════════════════════════════════════════════════════════
--  TAB 4: VISION
-- ══════════════════════════════════════════════════════════════
local T_CAM = Window:Tab({ Title = "Vision", Icon = "focus" })
local secZ = T_CAM:Section({ Title = "Zoom Override", Opened = true })
secZ:Toggle({ Title = "Max Zoom Out", Value = false, Callback = function(v) pcall(function() LP.CameraMaxZoomDistance = v and 100000 or 400 end); notify("Vision", v and "Max zoom enabled ✅" or "Zoom normal", 2) end })

local secS = T_CAM:Section({ Title = "Spectator Mode", Opened = true })
secS:Dropdown({ Title = "Select Target", Values = getDisplayNames(), Callback = function(v) local p = findPlayerByDisplay(v); if p then Spec.target = p; notify("Spectate", "Target locked: "..p.DisplayName.." ✅", 2) end end })
secS:Toggle({ Title = "Enable Spectate", Value = false, Callback = function(v)
    Spec.active = v; if v then if not Spec.target or not Spec.target.Parent then notify("Spectate", "Invalid target! ⚠️", 2); Spec.active = false; return end; Spec.origFov = Cam.FieldOfView; startSpecCapture(); startSpecLoop(); notify("Spectate", "Tracking "..Spec.target.DisplayName.." 👀", 2) else stopSpecLoop(); stopSpecCapture(); Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov; notify("Spectate", "Stopped tracking ❌", 2) end
end})

-- ══════════════════════════════════════════════════════════════
--  TAB 5: FREECAM (SMOOTH DEDICATED TAB)
-- ══════════════════════════════════════════════════════════════
local T_FREE = Window:Tab({ Title = "Freecam", Icon = "video" })

local secFC = T_FREE:Section({ Title = "Drone Engine", Opened = true })
secFC:Toggle({ Title = "Enable Freecam", Value = false, Callback = function(v)
    FC.active = v; if v then local cf = Cam.CFrame; FC.pos = cf.Position; local rx, ry = cf:ToEulerAnglesYXZ(); FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry)
        local hrp, hum = getRoot(), getHum(); if hrp then FC.savedCF = hrp.CFrame; hrp.Anchored = true end
        startFreecamCapture(); startFreecamLoop(); if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = true end; notify("Freecam", "Drone deployed ✅", 2)
    else stopFreecamLoop(); stopFreecamCapture(); local hrp, hum = getRoot(), getHum(); if hrp then hrp.Anchored = false; if FC.savedCF then hrp.CFrame = FC.savedCF end end
        Cam.CameraType = Enum.CameraType.Custom; if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = false end; notify("Freecam", "Drone recalled ❌", 2)
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

-- Startup & Apply Default GFX
pcall(function() Window:SelectTab(T_HOME) end)
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end) -- Default 1 GFX
notify("System", "XKID Engine Ready ⚡", 2); print("✅ XKID Engine v1.4 Ready")
