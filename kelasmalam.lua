--[[
========================
      @WTF.XKID
        Engine
========================
  💎 Dibuat oleh @WTF.XKID
  📱 Tiktok: @wtf.xkid
  💬 Discord: @4Sharken
  📌 v2.0.1 | Fixed
]]

local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TPService = game:GetService("TeleportService")
local StatsService = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local onMobile = not UIS.KeyboardEnabled

local CURRENT_VERSION = "2.0.1"

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
        for _, v in pairs(CoreGui:GetChildren()) do
            if v.Name == "WindUI" or v.Name == "XKID_FreecamUI" then v:Destroy() end
        end
        for _, v in pairs(Lighting:GetChildren()) do
            if v.Name == "_XKID_CC" or v.Name == "_XKID_BLOOM" then v:Destroy() end
        end
        if getgenv()._XKID_CONNS then
            for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end
        end
    end)
    pcall(function() RS:UnbindFromRenderStep("XKIDFreecam") end)
    pcall(function() RS:UnbindFromRenderStep("XKIDFly") end)
    pcall(function() RS:UnbindFromRenderStep("XKIDSpec") end)
    pcall(function() RS:UnbindFromRenderStep("XKIDShiftLock") end)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
    for _, gui in pairs(LP.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then gui.Enabled = true end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        pcall(function()
            if p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end
                for _, desc in ipairs(p.Character:GetDescendants()) do
                    if desc:IsA("BillboardGui") and desc.Parent then desc.Enabled = true end
                end
            end
            if p.PlayerGui then
                for _, v in ipairs(p.PlayerGui:GetDescendants()) do
                    if v:IsA("BillboardGui") then v.Enabled = true end
                end
            end
        end)
    end
    task.wait(0.2)
    collectgarbage("collect")
end

getgenv()._XKID_LOADED = true
getgenv()._XKID_RUNNING = true
getgenv()._XKID_CONNS = {}
local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local State = {
    Move      = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly       = { active = false, bv = nil, bg = nil, _keys = {}, voidConn = nil },
    HardFling = { active = false, power = 200000 },
    Teleport  = { selectedTarget = "", clickConn = nil, clickActive = false, lastTap = 0 },
    Security  = { afkActive = true, shiftLock = false, shiftLockGyro = nil, antiLag = false, arConn = nil },
    Cinema    = { hideUI = false, hideNametag = false, hideBubble = false, nametagConn = nil, bubbleConn = nil, cachedGuis = {} },
    Avatar    = { isRefreshing = false },
    Utility   = { chatLog = false, chatTargets = {}, chatHistory = {}, autoLike = false, chatSilent = false },
    ESP = {
        active = false, cache = getgenv()._XKID_ESP_CACHE, tracerMode = "Bottom", maxDrawDistance = 300,
        highlightMode = false, hideSelf = false,
        boxColor_N = Color3.fromRGB(0, 255, 150), boxColor_S = Color3.fromRGB(220, 20, 60), boxColor_G = Color3.fromRGB(255, 165, 0),
        tracerColor_N = Color3.fromRGB(0, 200, 255), tracerColor_S = Color3.fromRGB(220, 20, 60), tracerColor_G = Color3.fromRGB(255, 165, 0),
        nameColor = Color3.fromRGB(255, 255, 255),
    },
    Filter    = { current = "Default", bloomActive = false, bloomIntensity = 0.5, brightness = 1, exposure = 0, clockTime = 14, contrast = 0, qualityLevel = 1, fpsCap = "60", fullBright = false },
    Settings  = { theme = "Crimson", acrylic = true, transparency = true, toggleKey = "RightShift" },
}

local colorMap = {
    ["Merah"] = Color3.fromRGB(255, 0, 0), ["Hijau"] = Color3.fromRGB(0, 255, 0),
    ["Biru"] = Color3.fromRGB(0, 0, 255), ["Kuning"] = Color3.fromRGB(255, 255, 0),
    ["Ungu"] = Color3.fromRGB(255, 0, 255), ["Cyan"] = Color3.fromRGB(0, 255, 255),
    ["Orange"] = Color3.fromRGB(255, 165, 0), ["Pink"] = Color3.fromRGB(255, 105, 180),
    ["Putih"] = Color3.fromRGB(255, 255, 255), ["Hitam"] = Color3.fromRGB(0, 0, 0),
    ["Crimson"] = Color3.fromRGB(220, 20, 60),
}

local LikeEvent = nil
pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then LikeEvent = remotes:FindFirstChild("LikePlayerEvent") end
end)

local function likePlayer(player)
    if not player or not LikeEvent then return false end
    return pcall(function() LikeEvent:FireServer(player) end)
end

local function startAutoLike()
    if not LikeEvent then notify("Like", "Like remote not found! ⚠️", 2); State.Utility.autoLike = false; return end
    State.Utility.autoLike = true
    task.spawn(function()
        while State.Utility.autoLike and getgenv()._XKID_RUNNING do
            for _, p in ipairs(Players:GetPlayers()) do
                if not State.Utility.autoLike then break end
                if p ~= LP then likePlayer(p); task.wait(0.15) end
            end
            task.wait(3)
        end
    end)
    notify("Auto Like", "Auto Like active ❤️", 2)
end

local function stopAutoLike()
    State.Utility.autoLike = false
    notify("Auto Like", "Auto Like stopped", 2)
end

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
local function isValidFileName(name)
    if not name or name == "" then return false end
    return not name:match("[/\\:*?\"<>|]")
end

local START_TIME = os.time()
local cachedMapName, lastMapCheck = nil, 0
local sharedFPS, sharedPing = 60, 0

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

-- Anti AFK
local AntiAFK = { idleConn = nil, kickConn = nil, promptConn = nil }
local function startAntiAFK()
    State.Security.afkActive = true
    if not AntiAFK.idleConn then
        AntiAFK.idleConn = TrackC(LP.Idled:Connect(function()
            if not State.Security.afkActive then return end
            pcall(function() VirtualUser:Button2Down(Vector2.zero, Cam.CFrame); task.wait(1); VirtualUser:Button2Up(Vector2.zero, Cam.CFrame) end)
        end))
    end
    task.spawn(function()
        while State.Security.afkActive and getgenv()._XKID_RUNNING do
            task.wait(math.random(15, 45))
            if not State.Security.afkActive then break end
            pcall(function() VirtualUser:CaptureController(); VirtualUser:Button2Down(Vector2.zero, Cam.CFrame); task.wait(0.5); VirtualUser:Button2Up(Vector2.zero, Cam.CFrame) end)
        end
    end)
    if not AntiAFK.kickConn then
        AntiAFK.kickConn = TrackC(GuiService.ErrorMessageChanged:Connect(function(err)
            if err ~= "" then notify("Anti Kick", "Kick detected! Rejoining... 🔄", 3); task.wait(1); pcall(function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end) end
        end))
    end
    if not AntiAFK.promptConn then
        AntiAFK.promptConn = TrackC(CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then notify("Anti Kick", "Kick popup! Rejoining... 🔄", 3); task.wait(1); pcall(function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end) end
        end))
    end
    notify("Anti AFK", "Full protection active 🛡️", 2)
end
local function stopAntiAFK()
    State.Security.afkActive = false
    if AntiAFK.idleConn then AntiAFK.idleConn:Disconnect(); AntiAFK.idleConn = nil end
    if AntiAFK.kickConn then AntiAFK.kickConn:Disconnect(); AntiAFK.kickConn = nil end
    if AntiAFK.promptConn then AntiAFK.promptConn:Disconnect(); AntiAFK.promptConn = nil end
    notify("Anti AFK", "Protection disabled ❌", 2)
end
startAntiAFK()

-- Character Handler
TrackC(LP.CharacterAdded:Connect(function(char)
    if State.Fly.active then
        State.Fly.active = false; RS:UnbindFromRenderStep("XKIDFly")
        pcall(function() if State.Fly.bv then State.Fly.bv:Destroy() end end)
        pcall(function() if State.Fly.bg then State.Fly.bg:Destroy() end end)
        if State.Fly.voidConn then State.Fly.voidConn:Disconnect(); State.Fly.voidConn = nil end
        State.Fly.bv = nil; State.Fly.bg = nil; flyVel = Vector3.zero
        for _, c in ipairs(flyConns) do c:Disconnect() end; flyConns = {}; flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero; State.Fly._keys = {}
    end
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
    if State.Cinema.hideNametag then
        task.wait(0.3)
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            if p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
                for _, desc in ipairs(p.Character:GetDescendants()) do if desc:IsA("BillboardGui") and desc.Parent then desc.Enabled = false end end
            end
        end
    end
    if State.Cinema.hideBubble then
        task.wait(0.3)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.PlayerGui then
                for _, v in ipairs(p.PlayerGui:GetDescendants()) do if v:IsA("BillboardGui") then v.Enabled = false end end
            end
        end
    end
end))

-- Shift Lock
local function toggleShiftLock(v)
    State.Security.shiftLock = v
    if v then
        local hrp = getRoot()
        if hrp then
            if State.Security.shiftLockGyro then State.Security.shiftLockGyro:Destroy() end
            State.Security.shiftLockGyro = Instance.new("BodyGyro", hrp)
            State.Security.shiftLockGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); State.Security.shiftLockGyro.P = 50000; State.Security.shiftLockGyro.D = 1000
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

-- Fast Respawn
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
            local newHum = newChar:WaitForChild("Humanoid", 5)
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

-- ESP Engine
local function initPlayerCache(player)
    if State.ESP.cache[player] then return end
    local cache = { texts = nil, tracer = nil, boxLines = {}, hl = nil, isSuspect = false, isGlitch = false, reason = "" }
    pcall(function()
        cache.texts = Drawing.new("Text"); if cache.texts then cache.texts.Center = true; cache.texts.Outline = true; cache.texts.Font = 2; cache.texts.Size = 13 end
        cache.tracer = Drawing.new("Line"); if cache.tracer then cache.tracer.Thickness = 1.5 end
        for i = 1, 4 do local line = Drawing.new("Line"); if line then line.Thickness = 1.5; cache.boxLines[i] = line end end
    end)
    State.ESP.cache[player] = cache
end
local function clearPlayerCache(player)
    local c = State.ESP.cache[player]; if not c then return end
    pcall(function() if c.texts then c.texts:Remove() end end)
    pcall(function() if c.tracer then c.tracer:Remove() end end)
    for _, l in ipairs(c.boxLines) do pcall(function() if l then l:Remove() end end) end
    pcall(function() if c.hl then c.hl:Destroy(); c.hl = nil end end)
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
                        local hrp = getCharRoot(p.Character); local hum = p.Character:FindFirstChildOfClass("Humanoid")
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
    local myHrp = getCharRoot(LP.Character); if not myHrp then return end
    local vp = Cam.ViewportSize; local center = Vector2.new(vp.X / 2, vp.Y / 2)
    for _, c in pairs(State.ESP.cache) do pcall(function() if c.hl and not c.hl.Parent then c.hl:Destroy(); c.hl = nil end end) end
    for _, c in pairs(State.ESP.cache) do pcall(function() if c.texts then c.texts.Visible = false end; if c.tracer then c.tracer.Visible = false end; for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end; if c.hl then c.hl.Enabled = false end end) end
    local hlCount = 0
    for _, data in ipairs(espsortedPlayers) do
        local player, char, hrp, dist = data.p, data.char, data.hrp, data.dist
        local c = State.ESP.cache[player]; if not c then continue end
        local rootPos, onScreen = Cam:WorldToViewportPoint(hrp.Position); if not onScreen then continue end
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
                if not c.hl or c.hl.Parent ~= char then if c.hl then c.hl:Destroy() end; c.hl = Instance.new("Highlight", char); c.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end
                if c.hl then c.hl.FillColor = bColor; c.hl.OutlineColor = Color3.new(1,1,1); c.hl.Enabled = true end
            end)
        end
    end
end))

-- Fly Engine
local flyMoveTouch, flyMoveSt, flyJoy, flyConns = nil, nil, Vector2.zero, {}
local flyVel = Vector3.zero
local function startFlyCapture()
    local keysHeld = {}
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp) if gp then return end; local k = inp.KeyCode; if k==Enum.KeyCode.W or k==Enum.KeyCode.A or k==Enum.KeyCode.S or k==Enum.KeyCode.D or k==Enum.KeyCode.E or k==Enum.KeyCode.Q then keysHeld[k] = true end end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp) keysHeld[inp.KeyCode] = nil end))
    table.insert(flyConns, UIS.InputBegan:Connect(function(inp, gp) if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp.Position.X <= Cam.ViewportSize.X / 2 then if not flyMoveTouch then flyMoveTouch = inp; flyMoveSt = inp.Position end end end))
    table.insert(flyConns, UIS.TouchMoved:Connect(function(inp) if inp == flyMoveTouch and flyMoveSt then local dx, dy = inp.Position.X - flyMoveSt.X, inp.Position.Y - flyMoveSt.Y; flyJoy = Vector2.new(math.abs(dx)>25 and math.clamp((dx-math.sign(dx)*25)/80,-1,1) or 0, math.abs(dy)>20 and math.clamp((dy-math.sign(dy)*20)/80,-1,1) or 0) end end))
    table.insert(flyConns, UIS.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp == flyMoveTouch then flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero end end))
    State.Fly._keys = keysHeld
end
local function stopFlyCapture() for _, c in ipairs(flyConns) do c:Disconnect() end; flyConns = {}; flyMoveTouch = nil; flyMoveSt = nil; flyJoy = Vector2.zero; State.Fly._keys = {} end

local function toggleFly(v)
    if not v then
        State.Fly.active = false; stopFlyCapture(); RS:UnbindFromRenderStep("XKIDFly")
        if State.Fly.voidConn then State.Fly.voidConn:Disconnect(); State.Fly.voidConn = nil end
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
    if State.Fly.voidConn then State.Fly.voidConn:Disconnect() end
    State.Fly.voidConn = TrackC(RS.Heartbeat:Connect(function()
        if not State.Fly.active then return end
        local r = getRoot()
        if r and r.Position.Y <= workspace.FallenPartsDestroyHeight + 50 then r.AssemblyLinearVelocity = Vector3.zero; r.CFrame = r.CFrame + Vector3.new(0, 300, 0) end
    end))
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
        else if isOnGround() then flyVel = flyVel:Lerp(Vector3.zero, 0.1) else flyVel = flyVel:Lerp(Vector3.new(0, -0.8, 0), 0.08) end end
        if State.Fly.bv and State.Fly.bv.Parent then State.Fly.bv.Velocity = flyVel end
        if State.Fly.bg and State.Fly.bg.Parent then State.Fly.bg.CFrame = CFrame.new(r.Position, r.Position + camCF.LookVector) end
    end)
    notify("Movement", "Fly enabled ✈️", 2)
end

-- Smart TP
local function toggleSmartTP(v)
    State.Teleport.clickActive = v
    if v then
        State.Teleport.clickConn = TrackC(UIS.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                local m = LP:GetMouse(); if m.Hit then getRoot().CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3.5, 0)); getRoot().AssemblyLinearVelocity = Vector3.zero end
            elseif inp.UserInputType == Enum.UserInputType.Touch then
                if tick() - State.Teleport.lastTap < 0.8 and tick() - State.Teleport.lastTap > 0.1 then
                    local m = LP:GetMouse(); if m.Hit then getRoot().CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3.5, 0)); getRoot().AssemblyLinearVelocity = Vector3.zero end
                end
                State.Teleport.lastTap = tick()
            end
        end))
        notify("Teleport", "Smart TP: Ctrl+Click / Double Tap ✅", 2)
    else
        if State.Teleport.clickConn then State.Teleport.clickConn:Disconnect(); State.Teleport.clickConn = nil end
        notify("Teleport", "Smart TP Disabled ❌", 2)
    end
end

-- Freecam (FIXED - no animation)
local FC = { active = false, pos = Vector3.zero, pitchDeg = 0, yawDeg = 0, rollDeg = 0, speed = 3, sens = 0.25, savedCF = nil, origFov = 70 }
local I_CamVel, I_YawVel, I_PitchVel, I_RollVel, heightVelocity = Vector3.zero, 0, 0, 0, 0
local fcMoveTouch, fcMoveSt, fcJoy, fcRotTouch, fcRotLast, fcConns = nil, nil, Vector2.zero, nil, nil, {}
local FC_UI_Btns = { up = false, down = false, rollLeft = false, rollRight = false, zoomIn = false, zoomOut = false }
local FCUI = Instance.new("ScreenGui"); FCUI.Name = "XKID_FreecamUI"; FCUI.ResetOnSpawn = false; FCUI.ZIndexBehavior = Enum.ZIndexBehavior.Global; FCUI.Enabled = false; FCUI.Parent = CoreGui; getgenv()._XKID_FCUI = FCUI

local function makeFCBtn(name, txt, pos, actionKey)
    local b = Instance.new("TextButton", FCUI); b.Name = name; b.Size = UDim2.new(0, 52, 0, 52); b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(15, 15, 15); b.BackgroundTransparency = 0.4
    b.Text = txt; b.TextColor3 = Color3.fromRGB(255, 255, 255); b.TextSize = 22; b.Font = Enum.Font.GothamBold; b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    local uis = Instance.new("UIStroke", b); uis.Color = Color3.fromRGB(220, 20, 60); uis.Thickness = 2; uis.Transparency = 0.3
    local indicator = Instance.new("Frame", b); indicator.Name = "Indicator"; indicator.Size = UDim2.new(0, 8, 0, 8); indicator.Position = UDim2.new(0, 5, 0, 5); indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    local function press(down) FC_UI_Btns[actionKey] = down; b.BackgroundTransparency = down and 0.05 or 0.4; indicator.BackgroundColor3 = down and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(60, 60, 60) end
    b.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then press(true) end end)
    b.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then press(false) end end)
    b.MouseLeave:Connect(function() press(false) end)
    return b
end
makeFCBtn("BtnRollL", "L", UDim2.new(1, -118, 0.5, -84), "rollLeft")
makeFCBtn("BtnRollR", "R", UDim2.new(1, -58, 0.5, -84), "rollRight")
makeFCBtn("BtnUp", "↑", UDim2.new(1, -118, 0.5, -26), "up")
makeFCBtn("BtnZIn", "+", UDim2.new(1, -58, 0.5, -26), "zoomIn")
makeFCBtn("BtnDown", "↓", UDim2.new(1, -118, 0.5, 32), "down")
makeFCBtn("BtnZOut", "-", UDim2.new(1, -58, 0.5, 32), "zoomOut")

local fcKeysHeld = {}
local function startFreecamCapture()
    fcKeysHeld = {}
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp) if gp then return end; fcKeysHeld[inp.KeyCode] = true; if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mouseRot = true; UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition end end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp) fcKeysHeld[inp.KeyCode] = false; if inp.UserInputType == Enum.UserInputType.MouseButton2 then FC._mouseRot = false; UIS.MouseBehavior = Enum.MouseBehavior.Default end end))
    table.insert(fcConns, UIS.InputChanged:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseMovement and FC._mouseRot then I_YawVel = I_YawVel - inp.Delta.X * FC.sens * 120; I_PitchVel = I_PitchVel - inp.Delta.Y * FC.sens * 120 end end))
    table.insert(fcConns, UIS.InputBegan:Connect(function(inp, gp) if gp or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp.Position.X > Cam.ViewportSize.X / 2 then if not fcRotTouch then fcRotTouch = inp; fcRotLast = inp.Position end else if not fcMoveTouch then fcMoveTouch = inp; fcMoveSt = inp.Position; fcJoy = Vector2.zero end end end))
    table.insert(fcConns, UIS.TouchMoved:Connect(function(inp)
        if inp == fcRotTouch and fcRotLast then local dx, dy = inp.Position.X - fcRotLast.X, inp.Position.Y - fcRotLast.Y; fcRotLast = inp.Position; I_YawVel = I_YawVel - dx * FC.sens * 80; I_PitchVel = I_PitchVel - dy * FC.sens * 80 end
        if inp == fcMoveTouch and fcMoveSt then local dx, dy = inp.Position.X - fcMoveSt.X, inp.Position.Y - fcMoveSt.Y; local function ad(v,d,m) if math.abs(v)<d then return 0 end; return math.clamp((v-math.sign(v)*d)/(m-d),-1,1) end; fcJoy = Vector2.new(ad(dx,15,70), ad(dy,15,70)) end
    end))
    table.insert(fcConns, UIS.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; if inp == fcRotTouch then fcRotTouch = nil; fcRotLast = nil end; if inp == fcMoveTouch then fcMoveTouch = nil; fcMoveSt = nil; fcJoy = Vector2.zero end end))
end
local function stopFreecamCapture() for _, c in ipairs(fcConns) do c:Disconnect() end; fcConns = {}; fcMoveTouch, fcMoveSt, fcJoy, fcRotTouch, fcRotLast = nil, nil, Vector2.zero, nil, nil; fcKeysHeld = {}; FC._mouseRot = false; UIS.MouseBehavior = Enum.MouseBehavior.Default; I_CamVel, I_YawVel, I_PitchVel, I_RollVel, heightVelocity, FC.rollDeg = Vector3.zero, 0, 0, 0, 0, 0; for k in pairs(FC_UI_Btns) do FC_UI_Btns[k] = false end end
local function startFreecamLoop()
    RS:BindToRenderStep("XKIDFreecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not FC.active then return end; Cam.CameraType = Enum.CameraType.Scriptable; local safeDt = math.clamp(dt, 0.001, 0.05)
        I_YawVel = I_YawVel * math.max(0, 1 - safeDt * 14); I_PitchVel = I_PitchVel * math.max(0, 1 - safeDt * 14)
        FC.yawDeg = FC.yawDeg + I_YawVel * safeDt; FC.pitchDeg = math.clamp(FC.pitchDeg + I_PitchVel * safeDt, -80, 80)
        local rollTarget = 0; if FC_UI_Btns.rollLeft then rollTarget = -100 elseif FC_UI_Btns.rollRight then rollTarget = 100 end
        I_RollVel = I_RollVel + (rollTarget - I_RollVel) * math.clamp(safeDt * 5, 0, 1); FC.rollDeg = math.clamp(FC.rollDeg + I_RollVel * safeDt, -100, 100)
        if rollTarget == 0 and math.abs(FC.rollDeg) < 1 and math.abs(I_RollVel) < 1 then FC.rollDeg = 0; I_RollVel = 0 end
        local camCF = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0)
        local joyX, joyY = fcJoy.X, fcJoy.Y
        if not onMobile then if fcKeysHeld[Enum.KeyCode.W] then joyY = joyY - 1 end; if fcKeysHeld[Enum.KeyCode.S] then joyY = joyY + 1 end; if fcKeysHeld[Enum.KeyCode.D] then joyX = joyX + 1 end; if fcKeysHeld[Enum.KeyCode.A] then joyX = joyX - 1 end end
        local rawMove = Vector2.new(joyX, joyY); if rawMove.Magnitude > 1 then rawMove = rawMove.Unit end
        I_CamVel = I_CamVel:Lerp((camCF.LookVector * (-rawMove.Y) + camCF.RightVector * rawMove.X) * (FC.speed * 60), math.clamp(safeDt * 3.5, 0, 1))
        local heightTarget = 0; if fcKeysHeld[Enum.KeyCode.E] or FC_UI_Btns.up then heightTarget = FC.speed * 60 end; if fcKeysHeld[Enum.KeyCode.Q] or FC_UI_Btns.down then heightTarget = -FC.speed * 60 end
        if heightTarget == 0 then heightVelocity = heightVelocity * math.max(0, 1 - safeDt * 10); if math.abs(heightVelocity) < 0.5 then heightVelocity = 0 end
        else heightVelocity = heightVelocity + (heightTarget - heightVelocity) * math.clamp(safeDt * 3, 0, 1) end
        if FC_UI_Btns.zoomIn then Cam.FieldOfView = math.clamp(Cam.FieldOfView - 1.2, 10, 120) end
        if FC_UI_Btns.zoomOut then Cam.FieldOfView = math.clamp(Cam.FieldOfView + 1.2, 10, 120) end
        FC.pos = FC.pos + (I_CamVel + Vector3.new(0, heightVelocity, 0)) * safeDt
        Cam.CFrame = CFrame.new(FC.pos) * CFrame.Angles(0, math.rad(FC.yawDeg), 0) * CFrame.Angles(math.rad(FC.pitchDeg), 0, 0) * CFrame.Angles(0, 0, math.rad(FC.rollDeg))
        local hrp = getRoot(); if hrp and not hrp.Anchored then hrp.Anchored = true end
    end)
end
local function stopFreecamLoop() RS:UnbindFromRenderStep("XKIDFreecam") end

-- ⭐ FIXED: Cleanup tanpa animasi
local function fullCleanupFreecam()
    stopFreecamLoop(); stopFreecamCapture(); FC.rollDeg = 0
    local hrp, hum = getRoot(), getHum()
    if hrp and FC.savedCF then
        local safeCF = FC.savedCF + Vector3.new(0, 3, 0)
        hrp.CFrame = safeCF; hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.Anchored = false
        local holdConn; holdConn = RS.Heartbeat:Connect(function()
            if hrp and hrp.Parent then hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end
            task.delay(0.5, function() pcall(function() holdConn:Disconnect() end) end)
        end)
        FC.savedCF = nil
    elseif hrp then hrp.Anchored = false end
    if hum then hum.PlatformStand = false; hum.WalkSpeed = State.Move.ws; hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
    Cam.CameraType = Enum.CameraType.Custom; Cam.CameraSubject = hum or LP.Character; Cam.FieldOfView = FC.origFov
    if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = false end
    for k in pairs(FC_UI_Btns) do FC_UI_Btns[k] = false end
end

-- Spectate
local Spec = { active = false, target = nil, mode = "third", dist = 8, origFov = 70, orbitYaw = 0, orbitPitch = 0, fpYaw = 0, fpPitch = 0 }
local specPinch, specPinchD, specPan, specConns = {}, nil, Vector2.zero, {}
local function inJoystick(pos)
    local ctrl = LP and LP.PlayerGui and LP.PlayerGui:FindFirstChild("TouchGui"); if not ctrl then return false end
    local frame = ctrl:FindFirstChild("TouchControlFrame"); local thumb = frame and frame:FindFirstChild("DynamicThumbstickFrame"); if not thumb then return false end
    return pos.X >= thumb.AbsolutePosition.X and pos.Y >= thumb.AbsolutePosition.Y and pos.X <= thumb.AbsolutePosition.X + thumb.AbsoluteSize.X and pos.Y <= thumb.AbsolutePosition.Y + thumb.AbsoluteSize.Y
end
local function startSpecCapture()
    table.insert(specConns, UIS.InputBegan:Connect(function(inp, gp) if gp or not Spec.active or inp.UserInputType ~= Enum.UserInputType.Touch or inJoystick(inp.Position) then return end; table.insert(specPinch, inp) end))
    table.insert(specConns, UIS.InputChanged:Connect(function(inp) if not Spec.active or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if #specPinch >= 2 then local d = (specPinch[1].Position - specPinch[2].Position).Magnitude; if specPinchD then local diff = d - specPinchD; Cam.FieldOfView = math.clamp(Cam.FieldOfView - diff * 0.15, 10, 120); if Spec.mode == "third" then Spec.dist = math.clamp(Spec.dist - diff * 0.03, 3, 30) end end; specPinchD = d end end))
    table.insert(specConns, UIS.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; for i, v in ipairs(specPinch) do if v == inp then table.remove(specPinch, i); break end end; specPinchD = nil end))
end
local function stopSpecCapture() for _, c in ipairs(specConns) do c:Disconnect() end; specConns = {}; specPinch = {}; specPinchD = nil; specPan = Vector2.zero end
local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value + 1, function()
        if not Spec.active then return end
        pcall(function()
            if not Spec.target or not Spec.target.Parent or not Spec.target.Character or not Spec.target.Character:FindFirstChild("HumanoidRootPart") then notify("System", "Target not valid! ⚠️", 2); Spec.active = false; stopSpecLoop(); stopSpecCapture(); Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov; return end
            local hrp = Spec.target.Character.HumanoidRootPart; Cam.CameraType = Enum.CameraType.Scriptable
            if Spec.mode == "third" then Cam.CFrame = CFrame.new((CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(-Spec.orbitYaw), 0) * CFrame.Angles(math.rad(-Spec.orbitPitch), 0, 0) * CFrame.new(0, 0, Spec.dist)).Position, hrp.Position + Vector3.new(0, 1, 0))
            else local head = Spec.target.Character:FindFirstChild("Head"); local origin = head and head.Position or hrp.Position + Vector3.new(0, 1.5, 0); Cam.CFrame = CFrame.new(origin) * CFrame.Angles(0, math.rad(Spec.fpYaw), 0) * CFrame.Angles(math.rad(Spec.fpPitch), 0, 0) end
        end)
    end)
end
local function stopSpecLoop() RS:UnbindFromRenderStep("XKIDSpec") end
TrackC(Players.PlayerRemoving:Connect(function(p) if Spec.active and Spec.target == p then Spec.active = false; stopSpecLoop(); stopSpecCapture(); Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov; notify("Spectate", "Target left the game ❌", 2) end end))

-- Chat Logger (FIXED)
local chatLogPanel, chatTargetsLabel, addTargetDrop = nil, nil, nil
local function logMsg(speakerName, msg)
    if not State.Utility.chatLog then return end
    if #State.Utility.chatTargets > 0 then
        local found = false
        for _, t in ipairs(State.Utility.chatTargets) do if t and t.Parent and (t.Name == speakerName or t.DisplayName == speakerName) then found = true; break end end
        if not found then return end
    end
    local entry = string.format("[%s] %s: %s", os.date("%H:%M:%S"), speakerName, msg)
    table.insert(State.Utility.chatHistory, entry)
    if #State.Utility.chatHistory > 50 then table.remove(State.Utility.chatHistory, 1) end
    if chatLogPanel then pcall(function() chatLogPanel:SetDesc(table.concat(State.Utility.chatHistory, "\n")) end) end
    if not State.Utility.chatSilent then notify("Chat", speakerName .. ": " .. msg, 2) end
end
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    pcall(function() TrackC(TextChatService.MessageReceived:Connect(function(m) if m.TextSource then logMsg(m.TextSource.Name, m.Text) end end)) end)
else
    for _, p in ipairs(Players:GetPlayers()) do pcall(function() TrackC(p.Chatted:Connect(function(m) logMsg(p.Name, m) end)) end) end
    TrackC(Players.PlayerAdded:Connect(function(p) pcall(function() TrackC(p.Chatted:Connect(function(m) logMsg(p.Name, m) end)) end) end))
end
local function updateChatTargetLabel()
    local names = {}
    for _, t in ipairs(State.Utility.chatTargets) do if t and t.Parent then table.insert(names, t.DisplayName) end end
    pcall(function() if chatTargetsLabel then chatTargetsLabel:SetDesc(#names > 0 and "Tracking: " .. table.concat(names, ", ") or "None") end end)
    pcall(function() if addTargetDrop then addTargetDrop:Refresh(getDisplayNames(), true) end end)
end

-- ══════════════════════════════════════════════════════════════
--  UI WINDOW
-- ══════════════════════════════════════════════════════════════
task.wait(0.3)
local Window = WindUI:CreateWindow({
    Title = "XKID", Subtitle = "Engine", Author = "by XKID", Folder = "XKIDScript", Icon = "terminal", Theme = "Crimson",
    Acrylic = true, Transparent = true, Size = UDim2.fromOffset(480, 420), MinSize = Vector2.new(380, 320),
    ToggleKey = Enum.KeyCode.RightShift, NewElements = true, SideBarWidth = 140,
    OpenButton = { Enabled = true, Draggable = true, CornerRadius = UDim.new(1, 0), StrokeThickness = 4, Scale = 0.75,
        Color = ColorSequence.new(Color3.fromRGB(225, 0, 120), Color3.fromRGB(0, 255, 255)) },
    User = { Enabled = true, Anonymous = false, UserId = LP.UserId, Callback = function() notify("System", "XKID Engine v"..CURRENT_VERSION.." ✅", 3) end },
})
getgenv()._XKID_INSTANCE = Window.Instance; WindUI:SetTheme("Crimson")

-- Tab 1: System Hub
local T_HOME = Window:Tab({ Title = "System Hub", Icon = "layout-dashboard" })
T_HOME:Section({ Title = "Credits", Opened = true }):Paragraph({ Title = "💎 XKID Engine", Desc = "v"..CURRENT_VERSION.." | @WTF.XKID | @wtf.xkid | @4Sharken" })
T_HOME:Section({ Title = "Discord", Opened = true }):Button({ Title = "Copy Link", Desc = "discord.gg/bzumc2u96", Callback = function() pcall(function() setclipboard("https://discord.gg/bzumc2u96") end); notify("System", "Link disalin ✅", 2) end })
local secStatus = T_HOME:Section({ Title = "Monitor", Opened = true })
local srvLabel = secStatus:Paragraph({ Title = "Server", Desc = "Loading..." })
local netLabel = secStatus:Paragraph({ Title = "Performance", Desc = "Loading..." })
task.spawn(function()
    task.wait(2)
    while getgenv()._XKID_RUNNING do
        task.wait(0.5)
        pcall(function() if srvLabel then local pCount = #Players:GetPlayers(); srvLabel:SetDesc(string.format("Map: %s | Job: %s | Players: %d/%d | Uptime: %s", cachedMapName or "?", game.JobId:sub(1,8).."...", pCount, Players.MaxPlayers, formatTime(os.difftime(os.time(), START_TIME)))) end end)
        pcall(function() if netLabel then netLabel:SetDesc(string.format("FPS: %d | Ping: %dms", math.clamp(sharedFPS,0,300), math.clamp(sharedPing,0,9999))) end end)
    end
end)

-- Tab 2: Player Core
local T_AV = Window:Tab({ Title = "Player Core", Icon = "fingerprint" })
T_AV:Section({ Title = "State", Opened = true }):Button({ Title = "Fast Respawn 💀", Callback = function() fastRespawn() end })
local secMov = T_AV:Section({ Title = "Movement", Opened = true })
secMov:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
secMov:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) State.Move.jp = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end })
secMov:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(v) if v then State.Move.infJ = TrackC(UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end)) else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end end end})
local secAbi = T_AV:Section({ Title = "Abilities", Opened = true })
secAbi:Toggle({ Title = "Fly ✈️", Value = false, Callback = function(v) toggleFly(v) end })
secAbi:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(v) State.Move.flyS = v end })
local noclipConn = nil
secAbi:Toggle({ Title = "NoClip", Value = false, Callback = function(v) State.Move.ncp = v; if v then if not noclipConn then noclipConn = TrackC(RS.Heartbeat:Connect(function() if not State.Move.ncp then return end; if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)) end else if noclipConn then noclipConn:Disconnect(); noclipConn = nil end end end})
local hardFlingConn = nil
secAbi:Toggle({ Title = "Hard Fling 💥", Value = false, Callback = function(v) State.HardFling.active = v; local nw = State.Move.ncp; State.Move.ncp = v; if v then if not hardFlingConn then hardFlingConn = TrackC(RS.Heartbeat:Connect(function() if not State.HardFling.active then return end; local r = getRoot(); if r then pcall(function() r.AssemblyAngularVelocity = Vector3.new(math.random(-200000,200000), math.random(-200000,200000), math.random(-200000,200000)); r.AssemblyLinearVelocity = Vector3.new(math.random(-200,200), math.random(100,300), math.random(-200,200)) end); if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end end)) end; notify("Fling", v and "ON 💥" or "OFF ❌", 2) else if hardFlingConn then hardFlingConn:Disconnect(); hardFlingConn = nil end; State.Move.ncp = nw end end})

-- Tab 3: Navigation
local T_TP = Window:Tab({ Title = "Navigation", Icon = "crosshair" })
T_TP:Section({ Title = "Smart TP", Opened = true }):Toggle({ Title = "Enable", Value = false, Callback = toggleSmartTP })
local secTP = T_TP:Section({ Title = "Target TP", Opened = true })
local tpTarget = ""
secTP:Input({ Title = "Search", Placeholder = "Name...", Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "TP ⚡", Callback = function() pcall(function() if tpTarget == "" then notify("TP", "Input name! ⚠️", 2); return end; local t = nil; for _, p in pairs(Players:GetPlayers()) do if p ~= LP and (string.find(string.lower(p.Name), string.lower(tpTarget)) or string.find(string.lower(p.DisplayName), string.lower(tpTarget))) then t = p; break end end; if not t or not t.Character then notify("TP", "Not found ❌", 2); return end; local tHrp = getCharRoot(t.Character); local mHrp = getRoot(); if not tHrp or not mHrp then return end; mHrp.CFrame = tHrp.CFrame * CFrame.new(0,0,3) + Vector3.new(0,2,0); mHrp.AssemblyLinearVelocity = Vector3.zero; notify("TP", "→ "..t.DisplayName.." ✅", 2) end) end})
local pDropOpts = getDisplayNames()
local tpDropdown = secTP:Dropdown({ Title = "Player List", Values = pDropOpts, Callback = function(v) tpTarget = v end })
secTP:Button({ Title = "Refresh", Callback = function() pDropOpts = getDisplayNames(); pcall(function() tpDropdown:Refresh(pDropOpts, true) end) end })
local secLoc = T_TP:Section({ Title = "Slots", Opened = true })
local SavedLocs = {}
for i = 1, 3 do local idx = i
    secLoc:Button({ Title = "💾 Save "..idx, Callback = function() local r = getRoot(); if r then SavedLocs[idx] = r.CFrame; notify("Slot", "Saved ✅", 2) end end })
    secLoc:Button({ Title = "📍 Load "..idx, Callback = function() if SavedLocs[idx] then local r = getRoot(); if r then r.CFrame = SavedLocs[idx]; notify("Slot", "Loaded ✅", 2) end else notify("Slot", "Empty ⚠️", 2) end end })
end

-- Tab 4: Vision
local T_CAM = Window:Tab({ Title = "Vision", Icon = "focus" })
T_CAM:Section({ Title = "Zoom", Opened = true }):Toggle({ Title = "Max Zoom Out", Value = false, Callback = function(v) pcall(function() LP.CameraMaxZoomDistance = v and 100000 or 400 end) end })
local secSP = T_CAM:Section({ Title = "Spectate", Opened = true })
local specDropOpts = getDisplayNames()
local specDropdown = secSP:Dropdown({ Title = "Target", Values = specDropOpts, Callback = function(v) local p = findPlayerByDisplay(v); if p then Spec.target = p; notify("Spectate", "→ "..p.DisplayName, 2) end end})
secSP:Button({ Title = "Refresh", Callback = function() specDropOpts = getDisplayNames(); pcall(function() specDropdown:Refresh(specDropOpts, true) end) end })
secSP:Toggle({ Title = "Enable Spectate", Value = false, Callback = function(v) Spec.active = v; if v then if not Spec.target or not Spec.target.Character then notify("Spectate", "No target! ⚠️", 2); Spec.active = false; return end; Spec.origFov = Cam.FieldOfView; startSpecCapture(); startSpecLoop() else stopSpecLoop(); stopSpecCapture(); Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov end end})
secSP:Toggle({ Title = "First Person", Value = false, Callback = function(v) Spec.mode = v and "first" or "third" end })
secSP:Slider({ Title = "Distance", Step = 1, Value = { Min = 3, Max = 30, Default = 8 }, Callback = function(v) Spec.dist = v end })

-- Tab 5: Freecam
local T_FREE = Window:Tab({ Title = "Freecam", Icon = "video" })
local secFC = T_FREE:Section({ Title = "Drone", Opened = true })
secFC:Toggle({ Title = "Enable", Value = false, Callback = function(v) FC.active = v; if v then local cf = Cam.CFrame; FC.pos = cf.Position; local rx, ry = cf:ToEulerAnglesYXZ(); FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry); local hrp = getRoot(); if hrp then FC.savedCF = hrp.CFrame; hrp.Anchored = true end; FC.origFov = Cam.FieldOfView; startFreecamCapture(); startFreecamLoop(); if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = true end else fullCleanupFreecam() end end})
secFC:Slider({ Title = "Speed", Step = 0.5, Value = { Min = 1, Max = 20, Default = 3 }, Callback = function(v) FC.speed = v end })
secFC:Slider({ Title = "Sensitivity", Step = 0.05, Value = { Min = 0.1, Max = 1.0, Default = 0.25 }, Callback = function(v) FC.sens = v end })
local secCine = T_FREE:Section({ Title = "Cinematic", Opened = true })
secCine:Toggle({ Title = "Hide UI", Value = false, Callback = function(v) if v then State.Cinema.hideUI = true; State.Cinema.cachedGuis = {}; for _, gui in pairs(LP.PlayerGui:GetChildren()) do if gui:IsA("ScreenGui") and gui.Enabled then table.insert(State.Cinema.cachedGuis, gui); gui.Enabled = false end end; pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end) else State.Cinema.hideUI = false; for _, gui in pairs(State.Cinema.cachedGuis) do if gui and gui.Parent then gui.Enabled = true end end; State.Cinema.cachedGuis = {}; pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end) end end})
secCine:Toggle({ Title = "Nametags", Value = true, Callback = function(v) State.Cinema.hideNametag = not v end })
secCine:Toggle({ Title = "Bubble Chat", Value = true, Callback = function(v) State.Cinema.hideBubble = not v end })

-- Tab 6: Filter (FIXED)
local T_WO = Window:Tab({ Title = "Filter", Icon = "layers" })
local secFilter = T_WO:Section({ Title = "Presets", Opened = true })
local function resetFilterOnly()
    for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_CC" or v.Name == "_XKID_BLOOM" then v:Destroy() end end
    Lighting.GlobalShadows = true; Lighting.Brightness = 1; Lighting.ClockTime = 14
    Lighting.Ambient = Color3.new(0,0,0); Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5)
    Lighting.ExposureCompensation = 0; Lighting.FogEnd = 500
    State.Filter.current = "Default"; State.Filter.fullBright = false
end
local function applyFilter(filter)
    resetFilterOnly(); State.Filter.current = filter
    if filter == "Default" then notify("Filter", "Reset ✅", 2); return end
    local cc = Instance.new("ColorCorrectionEffect", Lighting); cc.Name = "_XKID_CC"
    local bloom = Instance.new("BloomEffect", Lighting); bloom.Name = "_XKID_BLOOM"; bloom.Intensity = 0; bloom.Size = 24
    if filter == "Mendung HD" then cc.TintColor = Color3.fromRGB(180,185,200); cc.Saturation = -0.3; cc.Contrast = 0.1; cc.Brightness = -0.15; bloom.Intensity = 0.05; Lighting.ClockTime = 10; Lighting.Brightness = 0.7
    elseif filter == "Cool Blue HD" then cc.TintColor = Color3.fromRGB(180,200,255); cc.Saturation = 0.1; cc.Contrast = 0.15; cc.Brightness = 0.05; bloom.Intensity = 0.2; Lighting.ClockTime = 12; Lighting.Brightness = 1.2
    elseif filter == "Full Bright HD" then cc:Destroy(); bloom:Destroy(); Lighting.GlobalShadows = false; Lighting.Brightness = 3; Lighting.ClockTime = 12; Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1); State.Filter.fullBright = true
    elseif filter == "Senja" then cc.TintColor = Color3.fromRGB(255,180,120); cc.Saturation = 0.2; cc.Contrast = 0.1; cc.Brightness = 0.05; bloom.Intensity = 0.5; bloom.Size = 40; Lighting.ClockTime = 17.5
    elseif filter == "Night HD" then cc.TintColor = Color3.fromRGB(200,200,255); cc.Saturation = 0.1; cc.Contrast = 0.2; bloom.Intensity = 0.15; Lighting.ClockTime = 1
    elseif filter == "Cinematic Film" then cc.TintColor = Color3.fromRGB(200,210,230); cc.Saturation = -0.15; cc.Contrast = 0.25; cc.Brightness = -0.05; bloom.Intensity = 0.15; bloom.Size = 20; Lighting.ClockTime = 16
    elseif filter == "Golden Hour" then cc.TintColor = Color3.fromRGB(255,200,100); cc.Saturation = 0.1; cc.Contrast = 0.15; cc.Brightness = 0.1; bloom.Intensity = 0.4; bloom.Size = 35; Lighting.ClockTime = 17.5
    elseif filter == "Moody Blue" then cc.TintColor = Color3.fromRGB(150,170,255); cc.Saturation = 0.05; cc.Contrast = 0.2; cc.Brightness = -0.1; bloom.Intensity = 0.1; Lighting.ClockTime = 2
    elseif filter == "Soft Fade HD" then cc.TintColor = Color3.fromRGB(255,240,235); cc.Saturation = -0.1; cc.Contrast = -0.05; cc.Brightness = 0.1; bloom.Intensity = 0.4; bloom.Size = 35; Lighting.ClockTime = 15; Lighting.Brightness = 1.3
    elseif filter == "Adaptif Langit HD" then cc.Saturation = 0.15; cc.Contrast = 0.2; cc.Brightness = 0.05; bloom.Intensity = 0.15; Lighting.ClockTime = 13; Lighting.Brightness = 1.5
    elseif filter == "Edgy HD" then cc.TintColor = Color3.fromRGB(200,195,210); cc.Saturation = -0.5; cc.Contrast = 0.4; cc.Brightness = -0.1; bloom.Intensity = 0.3; bloom.Size = 20; Lighting.ClockTime = 8; Lighting.Brightness = 0.8
    elseif filter == "Soft Pastel HD" then cc.TintColor = Color3.fromRGB(255,240,245); cc.Saturation = -0.05; cc.Contrast = 0.05; bloom.Intensity = 0.3; bloom.Size = 24; Lighting.ClockTime = 8
    elseif filter == "Cinematic Soft" then cc.Saturation = 0.1; cc.Contrast = 0.15; cc.Brightness = 0.05; bloom.Intensity = 0.2; Lighting.ClockTime = 17
    elseif filter == "Ultra HD" then cc.Saturation = 0.2; cc.Contrast = 0.3; bloom.Intensity = 0.2
    elseif filter == "Realistic" then cc.Saturation = 0.1; cc.Contrast = 0.2; bloom.Intensity = 0.15; Lighting.ClockTime = 15
    end
    notify("Filter", filter, 2)
end
secFilter:Dropdown({ Title = "Filter", Values = {"Default","Mendung HD","Cool Blue HD","Soft Fade HD","Adaptif Langit HD","Edgy HD","Full Bright HD","Soft Pastel HD","Cinematic Soft","Ultra HD","Realistic","Night HD","Senja","Cinematic Film","Golden Hour","Moody Blue"}, Value = "Default", Callback = applyFilter })
local secAtmos = T_WO:Section({ Title = "Atmos", Opened = false })
secAtmos:Toggle({ Title = "Bloom", Value = false, Callback = function(v) State.Filter.bloomActive = v; if v then local bl = nil; for _, e in pairs(Lighting:GetChildren()) do if e:IsA("BloomEffect") and e.Name == "_XKID_BLOOM" then bl = e; break end end; if not bl then bl = Instance.new("BloomEffect", Lighting); bl.Name = "_XKID_BLOOM" end; bl.Intensity = State.Filter.bloomIntensity else for _, e in pairs(Lighting:GetChildren()) do if e:IsA("BloomEffect") and e.Name == "_XKID_BLOOM" then e:Destroy() end end end end})
secAtmos:Slider({ Title = "Bloom Int", Step = 0.1, Value = {Min=0,Max=5,Default=0.5}, Callback = function(v) State.Filter.bloomIntensity = v; if State.Filter.bloomActive then for _, e in pairs(Lighting:GetChildren()) do if e:IsA("BloomEffect") and e.Name == "_XKID_BLOOM" then e.Intensity = v; break end end end end })
secAtmos:Slider({ Title = "Brightness", Step = 0.1, Value = {Min=0,Max=10,Default=1}, Callback = function(v) State.Filter.brightness = v; Lighting.Brightness = v end })
secAtmos:Slider({ Title = "Exposure", Step = 0.1, Value = {Min=-2,Max=2,Default=0}, Callback = function(v) State.Filter.exposure = v; Lighting.ExposureCompensation = v end })
secAtmos:Slider({ Title = "ClockTime", Step = 0.1, Value = {Min=0,Max=24,Default=14}, Callback = function(v) State.Filter.clockTime = v; Lighting.ClockTime = v end })
secAtmos:Button({ Title = "Reset", Callback = function() resetFilterOnly(); State.Filter.bloomActive = false end })
local secGfx = T_WO:Section({ Title = "Graphics", Opened = false })
secGfx:Slider({ Title = "Quality", Step = 1, Value = {Min=1,Max=21,Default=1}, Callback = function(v) State.Filter.qualityLevel = v; pcall(function() settings().Rendering.QualityLevel = v end) end })
secGfx:Dropdown({ Title = "FPS Cap", Values = {"30","60","120","144","240","Unlimited"}, Value = "60", Callback = function(v) State.Filter.fpsCap = v; if v == "Unlimited" then pcall(function() setfpscap(9999) end) else pcall(function() setfpscap(tonumber(v)) end) end end })

-- Tab 7: Radar
local T_ESP = Window:Tab({ Title = "Radar", Icon = "cpu" })
local secESP = T_ESP:Section({ Title = "ESP", Opened = true })
secESP:Toggle({ Title = "Enable", Value = false, Callback = function(v) State.ESP.active = v; if not v then for _, c in pairs(State.ESP.cache) do pcall(function() if c.texts then c.texts.Visible = false end; if c.tracer then c.tracer.Visible = false end; for _, l in ipairs(c.boxLines) do if l then l.Visible = false end end; if c.hl then c.hl:Destroy(); c.hl = nil end end) end end end})
secESP:Dropdown({ Title = "Tracer", Values = {"Bottom","Center","Mouse","OFF"}, Value = "Bottom", Callback = function(v) State.ESP.tracerMode = v end })
secESP:Toggle({ Title = "Highlight", Value = false, Callback = function(v) State.ESP.highlightMode = v end })
secESP:Toggle({ Title = "Hide Self", Value = false, Callback = function(v) State.ESP.hideSelf = v end })
secESP:Slider({ Title = "Distance", Step = 10, Value = { Min=50,Max=500,Default=300 }, Callback = function(v) State.ESP.maxDrawDistance = v end })
local secESPColor = T_ESP:Section({ Title = "Colors", Opened = false })
secESPColor:Dropdown({ Title="Normal", Values={"Hijau","Merah","Biru","Kuning","Ungu","Cyan","Orange","Pink","Putih"}, Value="Hijau", Callback=function(v) if colorMap[v] then State.ESP.tracerColor_N=colorMap[v]; State.ESP.boxColor_N=colorMap[v] end end })
secESPColor:Dropdown({ Title="Suspect", Values={"Merah","Crimson","Orange","Kuning"}, Value="Crimson", Callback=function(v) if colorMap[v] then State.ESP.tracerColor_S=colorMap[v]; State.ESP.boxColor_S=colorMap[v] end end })
secESPColor:Dropdown({ Title="Glitch", Values={"Orange","Merah","Kuning"}, Value="Orange", Callback=function(v) if colorMap[v] then State.ESP.tracerColor_G=colorMap[v]; State.ESP.boxColor_G=colorMap[v] end end })

-- Tab 8: Utility
local T_UTIL = Window:Tab({ Title = "Utility", Icon = "terminal" })
local secLike = T_UTIL:Section({ Title = "Auto Like ❤️", Opened = true })
if not LikeEvent then secLike:Paragraph({ Title = "Status", Desc = "⚠️ Not available" }) end
secLike:Toggle({ Title = "Auto Like", Value = false, Callback = function(v) if v then startAutoLike() else stopAutoLike() end end})
local secChat = T_UTIL:Section({ Title = "Chat Logger", Opened = true })
secChat:Toggle({ Title = "Enable", Value = false, Callback = function(v) State.Utility.chatLog = v end })
secChat:Toggle({ Title = "Silent", Value = false, Callback = function(v) State.Utility.chatSilent = v end })
chatTargetsLabel = secChat:Paragraph({ Title = "Targets", Desc = "None" })
addTargetDrop = secChat:Dropdown({ Title = "Add Target", Values = getDisplayNames(), Callback = function(v) local p = findPlayerByDisplay(v); if p then for _, t in ipairs(State.Utility.chatTargets) do if t.Name == p.Name then notify("Chat","Already added!",2); return end end; table.insert(State.Utility.chatTargets, p); updateChatTargetLabel(); notify("Chat","Added: "..p.DisplayName, 2) end end})
secChat:Button({ Title = "Remove Last", Callback = function() if #State.Utility.chatTargets > 0 then table.remove(State.Utility.chatTargets); updateChatTargetLabel() else notify("Chat","Empty!",2) end end})
secChat:Button({ Title = "Refresh List", Callback = function() pcall(function() addTargetDrop:Refresh(getDisplayNames(), true) end) end})
chatLogPanel = secChat:Paragraph({ Title = "Log", Desc = "Waiting..." })
secChat:Button({ Title = "Clear Log", Callback = function() State.Utility.chatHistory = {}; pcall(function() chatLogPanel:SetDesc("Waiting...") end) end})
secChat:Button({ Title = "Clear Targets", Callback = function() State.Utility.chatTargets = {}; updateChatTargetLabel() end})
local secMisc = T_UTIL:Section({ Title = "Data", Opened = true })
secMisc:Button({ Title = "Copy JobID", Callback = function() pcall(function() setclipboard(game.JobId) end); notify("Data","Copied ✅",2) end })

-- Tab 9: Security
local T_SEC = Window:Tab({ Title = "Security", Icon = "shield-alert" })
local secProt = T_SEC:Section({ Title = "Protection", Opened = true })
secProt:Toggle({ Title = "Anti AFK 🛡️", Value = true, Callback = function(v) if v then startAntiAFK() else stopAntiAFK() end end })
secProt:Button({ Title = "Stuck Fix 🔧", Callback = function() local hrp, hum = getRoot(), getHum(); if hrp then hrp.Anchored = false; hrp.CFrame = hrp.CFrame + Vector3.new(0,3,0) end; if hum then hum.Sit = false; hum:ChangeState(Enum.HumanoidStateType.Jumping) end; notify("Fix","Done ✅",2) end })
local secSrv = T_SEC:Section({ Title = "Server", Opened = true })
secSrv:Toggle({ Title = "Auto Rejoin", Value = false, Callback = function(v) if v then State.Security.arConn = TrackC(GuiService.ErrorMessageChanged:Connect(function(err) if err~="" then notify("Rejoin","Rejoining...",3); task.wait(1); pcall(function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end) end end)) else if State.Security.arConn then State.Security.arConn:Disconnect(); State.Security.arConn = nil end end end})
secSrv:Button({ Title = "Rejoin", Callback = function() pcall(function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end) end })
secSrv:Button({ Title = "Server Hop", Callback = function()
    notify("Hop","Searching... 🔍", 2)
    task.spawn(function() pcall(function()
        local req = nil; pcall(function() req = syn.request end); if not req then pcall(function() req = http_request end) end; if not req then pcall(function() req = request end) end
        if not req then notify("Hop","HTTP not supported",2); return end
        local s, r = pcall(function() return req({Url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100",Method="GET"}) end)
        if not s or not r or r.StatusCode~=200 then notify("Hop","Failed ❌",2); return end
        local body = HttpService:JSONDecode(r.Body)
        if not body or not body.data or #body.data==0 then notify("Hop","No servers",2); return end
        table.sort(body.data, function(a,b) return a.playing>b.playing end)
        for _, v in ipairs(body.data) do if v.id~=game.JobId and v.playing>0 then notify("Hop","Joining... 🚀",2); task.wait(0.5); TPService:TeleportToPlaceInstance(game.PlaceId, v.id, LP); return end end
        notify("Hop","No suitable server 😕", 2)
    end) end)
end})
local secPerf = T_SEC:Section({ Title = "Performance", Opened = true })
local advCache = { mats={}, texs={}, shadows=true, level=10, brightness=0, clockTime=0, fogEnd=0 }
secPerf:Toggle({ Title = "FPS Boost ⚡", Value = false, Callback = function(v) State.Security.antiLag = v; if v then pcall(function() advCache.level=settings().Rendering.QualityLevel end); advCache.shadows=Lighting.GlobalShadows; advCache.brightness=Lighting.Brightness; advCache.clockTime=Lighting.ClockTime; advCache.fogEnd=Lighting.FogEnd; pcall(function() settings().Rendering.QualityLevel=1 end); Lighting.GlobalShadows=false; Lighting.Brightness=1; Lighting.FogEnd=100000; for _, obj in pairs(workspace:GetDescendants()) do if obj:IsA("BasePart") then advCache.mats[obj]=obj.Material; obj.Material=Enum.Material.SmoothPlastic elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then advCache.texs[obj]=obj.Enabled; obj.Enabled=false end end else pcall(function() if advCache.level then settings().Rendering.QualityLevel=advCache.level end end); Lighting.GlobalShadows=advCache.shadows; Lighting.Brightness=advCache.brightness; Lighting.ClockTime=advCache.clockTime; Lighting.FogEnd=advCache.fogEnd; for obj, mat in pairs(advCache.mats) do if obj and obj.Parent then obj.Material=mat end end; for obj, enb in pairs(advCache.texs) do if obj and obj.Parent then obj.Enabled=enb end end; advCache.mats={}; advCache.texs={} end end})
T_SEC:Section({ Title = "Camera", Opened = true }):Toggle({ Title = "Shift Lock", Value = false, Callback = toggleShiftLock })

-- Tab 10: Config
local T_SET = Window:Tab({ Title = "Config", Icon = "settings" })
local secCfg = T_SET:Section({ Title = "Files", Opened = true })
local cfgName, currentConfig = "XKID_Config", "No config"
secCfg:Input({ Title = "Name", Default = "XKID_Config", Callback = function(v) cfgName = v end })
secCfg:Button({ Title = "💾 Save", Callback = function()
    if not isValidFileName(cfgName) then notify("Config","Invalid name! ⚠️",2); return end
    pcall(function() if makefolder and writefile then if not isfolder("XKID_HUB") then makefolder("XKID_HUB") end; local data = { Move={ws=State.Move.ws,jp=State.Move.jp,flyS=State.Move.flyS}, ESP={tracerMode=State.ESP.tracerMode,maxDrawDistance=State.ESP.maxDrawDistance,highlightMode=State.ESP.highlightMode,hideSelf=State.ESP.hideSelf,tracerColor_N={R=State.ESP.tracerColor_N.R,G=State.ESP.tracerColor_N.G,B=State.ESP.tracerColor_N.B},tracerColor_S={R=State.ESP.tracerColor_S.R,G=State.ESP.tracerColor_S.G,B=State.ESP.tracerColor_S.B},tracerColor_G={R=State.ESP.tracerColor_G.R,G=State.ESP.tracerColor_G.G,B=State.ESP.tracerColor_G.B}}, Security={shiftLock=State.Security.shiftLock,antiLag=State.Security.antiLag}, Filter={current=State.Filter.current,bloomActive=State.Filter.bloomActive,bloomIntensity=State.Filter.bloomIntensity,brightness=State.Filter.brightness,exposure=State.Filter.exposure,clockTime=State.Filter.clockTime,contrast=State.Filter.contrast,qualityLevel=State.Filter.qualityLevel,fpsCap=State.Filter.fpsCap}, Settings={theme=State.Settings.theme,acrylic=State.Settings.acrylic,transparency=State.Settings.transparency}, Freecam={speed=FC.speed,sens=FC.sens}, Utility={chatSilent=State.Utility.chatSilent} }; writefile("XKID_HUB/"..cfgName..".json", HttpService:JSONEncode(data)); notify("Config","Saved ✅",2); pcall(function() configDrop:Refresh(getConfigList(),true) end) end end)
end})
local configDrop = secCfg:Dropdown({ Title = "Load", Values = getConfigList(), Callback = function(selected) currentConfig = selected; if selected=="No config" then return end; pcall(function() if isfile and readfile and isfile("XKID_HUB/"..selected..".json") then local data = HttpService:JSONDecode(readfile("XKID_HUB/"..selected..".json")); if data then if data.Move then State.Move.ws=data.Move.ws or 16; State.Move.jp=data.Move.jp or 50; State.Move.flyS=data.Move.flyS or 60; local h=getHum(); if h then h.WalkSpeed=State.Move.ws; h.UseJumpPower=true; h.JumpPower=State.Move.jp end end; if data.ESP then State.ESP.tracerMode=data.ESP.tracerMode or "Bottom"; State.ESP.maxDrawDistance=data.ESP.maxDrawDistance or 300; State.ESP.highlightMode=data.ESP.highlightMode or false; State.ESP.hideSelf=data.ESP.hideSelf or false; if data.ESP.tracerColor_N and data.ESP.tracerColor_N.R then State.ESP.tracerColor_N=Color3.new(data.ESP.tracerColor_N.R,data.ESP.tracerColor_N.G,data.ESP.tracerColor_N.B) end; if data.ESP.tracerColor_S and data.ESP.tracerColor_S.R then State.ESP.tracerColor_S=Color3.new(data.ESP.tracerColor_S.R,data.ESP.tracerColor_S.G,data.ESP.tracerColor_S.B) end; if data.ESP.tracerColor_G and data.ESP.tracerColor_G.R then State.ESP.tracerColor_G=Color3.new(data.ESP.tracerColor_G.R,data.ESP.tracerColor_G.G,data.ESP.tracerColor_G.B) end end; if data.Security then if data.Security.shiftLock~=State.Security.shiftLock then toggleShiftLock(data.Security.shiftLock) end; State.Security.antiLag=data.Security.antiLag or false end; if data.Filter then if data.Filter.current and data.Filter.current~=State.Filter.current then applyFilter(data.Filter.current) end; State.Filter.bloomActive=data.Filter.bloomActive or false; State.Filter.bloomIntensity=data.Filter.bloomIntensity or 0.5 end; if data.Freecam then FC.speed=data.Freecam.speed or 3; FC.sens=data.Freecam.sens or 0.25 end; if data.Utility then State.Utility.chatSilent=data.Utility.chatSilent or false end; notify("Config","Loaded ✅",2) end end end) end})
secCfg:Button({ Title = "🗑️ Delete", Callback = function() if currentConfig~="No config" and currentConfig~="" then pcall(function() if isfile and delfile and isfile("XKID_HUB/"..currentConfig..".json") then delfile("XKID_HUB/"..currentConfig..".json"); notify("Config","Deleted 🗑️",2); currentConfig="No config"; pcall(function() configDrop:Refresh(getConfigList(),true) end) end end) else notify("Config","Select first! ⚠️",2) end end})
secCfg:Button({ Title = "🔄 Refresh", Callback = function() pcall(function() configDrop:Refresh(getConfigList(),true) end) end })
local secTheme = T_SET:Section({ Title = "UI", Opened = true })
secTheme:Dropdown({ Title = "Theme", Values = (function() local n={}; for name in pairs(WindUI:GetThemes()) do table.insert(n,name) end; table.sort(n); return n end)(), Value = "Crimson", Callback = function(s) State.Settings.theme=s; pcall(function() WindUI:SetTheme(s) end) end })
secTheme:Toggle({ Title = "Acrylic", Value = true, Callback = function(v) State.Settings.acrylic=v; pcall(function() WindUI:ToggleAcrylic(not WindUI.Window.Acrylic) end) end })
secTheme:Toggle({ Title = "Transparent", Value = true, Callback = function(s) State.Settings.transparency=s; pcall(function() Window:ToggleTransparency(s) end) end })
secTheme:Keybind({ Title = "Toggle Key", Value = Enum.KeyCode.RightShift, Callback = function(v) Window:SetToggleKey(typeof(v)=="EnumItem" and v or Enum.KeyCode[v]) end })

-- Startup
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
pcall(function() Window:SelectTab(T_HOME) end)
notify("System", "XKID Engine v"..CURRENT_VERSION.." Ready ⚡", 3)
print("✅ XKID Engine v"..CURRENT_VERSION.." - All Systems Go")