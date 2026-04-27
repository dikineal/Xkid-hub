--[[
========================
      @WTF.XKID
        Script
========================
  💎 Dibuat oleh @WTF.XKID
  📱 Tiktok: @wtf.xkid
  💬 Discord: @4sharken
]]

local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- ══════════════════════════════════════════════════════════════
--  0. CLEANUP AWAL (SIMPEL, TANPA LOOP)
-- ══════════════════════════════════════════════════════════════
if getgenv()._XKID_RUNNING then
    getgenv()._XKID_RUNNING = false
    task.wait(0.1)
end

-- Bersihin ESP cache lama
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

-- Bersihin UI lama & koneksi
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
    end)
    -- Unbind semua render step
    pcall(function() RS:UnbindFromRenderStep("XKIDFreecam") end)
    pcall(function() RS:UnbindFromRenderStep("XKIDFly") end)
    pcall(function() RS:UnbindFromRenderStep("XKIDSpec") end)
    pcall(function() RS:UnbindFromRenderStep("XKIDShiftLock") end)
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
    Cinema    = { active = false },
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
    if #t == 0 then table.insert(t, "(kosong)") end
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
    if #list == 0 then table.insert(list, "Tidak ada config") end
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
--  ENGINE: SHIFT LOCK, RESPAWN, REFRESH, ESP, FLY, FREECAM, SPECTATE
--  (Semua engine dari script original kamu - gak ada perubahan)
-- ══════════════════════════════════════════════════════════════

-- SHIFT LOCK
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
        notify("Shift Lock", "Dikunci 🔒", 2)
    else
        RS:UnbindFromRenderStep("XKIDShiftLock")
        if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy(); State.Security.shiftLockGyro = nil end
        notify("Shift Lock", "Dibuka 🔓", 2)
    end
end

-- FAST RESPAWN
local function fastRespawn()
    if State.Avatar.isRefreshing then return end
    local char, hrp = LP.Character, getRoot()
    if not char or not hrp then notify("Error", "Karakter gak ada!", 2); return end
    State.Avatar.isRefreshing = true; notify("Respawn", "Respawn aman 💨", 1.5)
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
                notify("Sukses", "Respawn berhasil!", 2)
            end
            LP.RespawnLocation = prevRespawn; State.Avatar.isRefreshing = false
        end)
        char:BreakJoints()
        task.delay(8, function() if not done then conn:Disconnect(); LP.RespawnLocation = prevRespawn; State.Avatar.isRefreshing = false; Cam.CameraType = Enum.CameraType.Custom end end)
    end)
end

-- REFRESH CHARACTER
local function refreshCharacter()
    if State.Avatar.isRefreshing then return end
    local char, hrp = LP.Character, getRoot()
    if not char or not hrp then notify("Error", "Karakter gak ada!", 2); return end
    State.Avatar.isRefreshing = true; notify("Refresh", "Refresh karakter 🔁", 1.5)
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
                notify("Sukses", "Refresh berhasil!", 2)
            else notify("Error", "Gagal refresh!", 2) end
            LP.RespawnLocation = prevRespawn; State.Avatar.isRefreshing = false
        end)
        local ok = pcall(function() LP:LoadCharacter() end)
        if not ok then char:BreakJoints() end
        task.delay(15, function() if not done then conn:Disconnect(); LP.RespawnLocation = prevRespawn; State.Avatar.isRefreshing = false; Cam.CameraType = Enum.CameraType.Custom end end)
    end)
end

-- ESP ENGINE
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

-- ESP Detection Loop
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if State.ESP.active then
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
                end
            end
        end
        task.wait(1)
    end
end)

-- ESP Render Loop
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        if not State.ESP.active then task.wait(0.5); continue end
        local myHrp = getCharRoot(LP.Character)
        if not myHrp then task.wait(0.5); continue end
        local vp = Cam.ViewportSize; local center = Vector2.new(vp.X / 2, vp.Y / 2)
        for _, player in pairs(Players:GetPlayers()) do
            if player == LP then continue end
            local char = player.Character; local hrp = getCharRoot(char); local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then clearPlayerCache(player); continue end
            initPlayerCache(player); local c = State.ESP.cache[player]; if not c then continue end
            local alive = hum.Health > 0; local dist = alive and (hrp.Position - myHrp.Position).Magnitude or 9999
            local function hideAll()
                pcall(function() if c.texts then c.texts.Visible = false end; if c.tracer then c.tracer.Visible = false end; for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end; if c.hl then c.hl.Enabled = false end end)
            end
            if not alive or dist > State.ESP.maxDrawDistance then hideAll(); continue end
            local rootPos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
            if not onScreen then hideAll(); continue end
            local isSus, isGlitch = c.isSuspect, c.isGlitch
            local useHl = isSus or isGlitch or State.ESP.highlightMode
            local txt = player.DisplayName .. "\n[" .. math.floor(dist) .. "m]"
            if isSus or isGlitch then txt = txt .. "\n⚠ " .. c.reason .. " ⚠" end
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
                elseif c.tracer then c.tracer.Visible = false end
            end)
            if useHl then
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
            else
                pcall(function() for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end; if c.hl then c.hl.Enabled = false end end)
            end
        end
        task.wait()
    end
end)

-- FLY ENGINE
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
        notify("Fly", "Fly dimatikan 👋", 2); return
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
    notify("Fly", "Fly menyala ✈️", 2)
end

-- FREECAM ENGINE (dari script original kamu - gak ada perubahan, taruh sini)
-- SPECTATE ENGINE (dari script original kamu - gak ada perubahan, taruh sini)

-- ══════════════════════════════════════════════════════════════
--  MAIN WINDOW
-- ══════════════════════════════════════════════════════════════
task.wait(0.3)

local Window = WindUI:CreateWindow({
    Title = "@WTF.XKID", Subtitle = "Script", Author = "by @WTF.XKID",
    Folder = "XKIDScript", Icon = "ghost", Theme = "Crimson",
    Acrylic = true, Transparent = true,
    Size = UDim2.fromOffset(540, 460), MinSize = Vector2.new(440, 360), MaxSize = Vector2.new(680, 540),
    ToggleKey = Enum.KeyCode.RightShift, Resizable = true, AutoScale = true, NewElements = true, SideBarWidth = 150,
    Topbar = { Height = 40, ButtonsType = "Default" },
    OpenButton = {
        Title = "@WTF.XKID", Icon = "ghost", CornerRadius = UDim.new(1, 0), StrokeThickness = 4,
        Enabled = true, Draggable = true, OnlyMobile = false, Scale = 0.75,
        Color = ColorSequence.new(Color3.fromRGB(225, 0, 120), Color3.fromRGB(0, 255, 255)),
    },
    User = { Enabled = true, Anonymous = false, UserId = LP.UserId, Callback = function() notify("XKID", "Dibuat oleh @WTF.XKID", 3) end },
})
getgenv()._XKID_INSTANCE = Window.Instance
WindUI:SetTheme("Crimson")

-- RGB Animasi
task.spawn(function()
    local hue = 0
    while getgenv()._XKID_RUNNING do
        hue = (hue + 0.005) % 1
        local c1 = Color3.fromHSV(hue, 1, 1); local c2 = Color3.fromHSV((hue + 0.5) % 1, 1, 1); local seq = ColorSequence.new(c1, c2)
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
--  TAB: HOME (LIVE MONITOR - FIXED)
-- ══════════════════════════════════════════════════════════════
local T_HOME = Window:Tab({ Title = "Home", Icon = "home" })
T_HOME:Section({ Title = "⚡ XKID HUB", Opened = true }):Paragraph({ Title = "Welcome", Desc = "Script loaded!\n📱 @wtf.xkid\n💬 @4sharken" })
T_HOME:Section({ Title = "🔗 Discord", Opened = true }):Button({ Title = "Copy Discord Link", Desc = "discord.gg/bzumc2u96", Callback = function() pcall(function() setclipboard("https://discord.gg/bzumc2u96") end); notify("Discord", "Link dicopy!", 2) end })

local secStatus = T_HOME:Section({ Title = "📊 Live Monitor", Opened = true })
local srvLabel = secStatus:Paragraph({ Title = "🌐 Server Info", Desc = "Memuat..." })
local netLabel = secStatus:Paragraph({ Title = "⚡ Network & Perf", Desc = "Memuat..." })

local secSecHome = T_HOME:Section({ Title = "🛡️ Security Status", Opened = true })
local securityLabel = secSecHome:Paragraph({ Title = "Status", Desc = "Script Protected" })

-- LIVE MONITOR LOOP (AMAN, GAK KENA CLEANUP)
task.spawn(function()
    task.wait(2) -- Tunggu UI siap
    while getgenv()._XKID_RUNNING do
        task.wait(0.5)
        pcall(function()
            if srvLabel and cachedMapName then
                local pCount = #Players:GetPlayers(); local mCount = Players.MaxPlayers
                local uptime = formatTime(os.difftime(os.time(), START_TIME))
                local job = game.JobId ~= "" and game.JobId:sub(1, 8).."..." or "N/A"
                srvLabel:SetDesc(string.format("🗺️ Map: %s\n🆔 Job: %s\n👥 Pemain: %d/%d\n⏳ Uptime: %s", cachedMapName, job, pCount, mCount, uptime))
            end
        end)
        pcall(function()
            if netLabel then
                local fps = math.clamp(sharedFPS, 0, 300); local ping = math.clamp(sharedPing, 0, 9999)
                local fc = fps >= 60 and "🟢" or (fps >= 30 and "🟡" or "🔴")
                local pc = ping < 100 and "🟢" or (ping < 200 and "🟡" or "🔴")
                local fBar = string.rep("█", math.clamp(math.floor(fps / 12), 0, 10)) .. string.rep("░", 10 - math.clamp(math.floor(fps / 12), 0, 10))
                local pBar = string.rep("█", math.clamp(math.floor((200 - math.min(ping, 200)) / 20), 0, 10)) .. string.rep("░", 10 - math.clamp(math.floor((200 - math.min(ping, 200)) / 20), 0, 10))
                netLabel:SetDesc(string.format("%s %d FPS\n[%s]\n\n%s %d ms\n[%s]", fc, fps, fBar, pc, ping, pBar))
            end
        end)
        pcall(function()
            if securityLabel then
                local afk = State.Security.afkConn and "✅ Aktif" or "⭕ Mati"
                local lag = State.Security.antiLag and "⚡ Aktif" or "⭕ Mati"
                local sl = State.Security.shiftLock and "🔒 Aktif" or "🔓 Mati"
                local vd = State.Security.voidConn and "✅ Aktif" or "⭕ Mati"
                securityLabel:SetDesc(string.format("⏰ Anti-AFK: %s\n🔒 Shift Lock: %s\n🕳️ Anti-Void: %s\n⚡ FPS Boost: %s", afk, sl, vd, lag))
            end
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB: PLAYER, TELEPORT, CAMERA, WORLD, ESP, UTILITY, SECURITY, SETTINGS
--  (Semua UI dari script original kamu - gak ada perubahan struktural)
-- ══════════════════════════════════════════════════════════════

-- ( ... semua tab UI sama persis kayak script original kamu ... )

-- ══════════════════════════════════════════════════════════════
--  STARTUP
-- ══════════════════════════════════════════════════════════════
if not State.Security.afkConn then
    State.Security.afkConn = TrackC(LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); task.wait(1) end))
end
WindUI:SetNotificationLower(true)
task.spawn(function() pcall(function() cachedMapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name; lastMapCheck = tick() end) end)
task.wait(0.5)
pcall(function() Window:SelectTab(T_HOME) end)
notify("XKID", "Script siap 💎", 2)
print("✅ XKID Script Ready")