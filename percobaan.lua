--[[
========================
      @WTF.XKID
        Engine
========================
  💎 Dibuat oleh @WTF.XKID
  📱 Tiktok: @wtf.xkid
  💬 Discord: @4Sharken
  📌 v2.0.9 - Fluent Modded RGB Edition
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
            if v.Name == "Fluent" or v.Name == "XKID_FreecamUI" or v.Name == "XKID_Floater" then v:Destroy() end
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
    for _, gui in pairs(LP.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then gui.Enabled = true end
    end
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
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

-- ══════════════════════════════════════════════════════════════
--  LOAD FLUENT MODDED
-- ══════════════════════════════════════════════════════════════
local Fluent = loadstring(game:HttpGet("https://github.com/StyearX/Fluent-Modded/releases/download/Fluent/FluentLite"))()
task.wait(0.3)

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

local CURRENT_VERSION = "2.0.9"

-- ══════════════════════════════════════════════════════════════
--  STATE MANAGEMENT
-- ══════════════════════════════════════════════════════════════
local State = {
    Move      = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly       = { active = false, bv = nil, bg = nil, _keys = {} },
    SoftFling = { active = false, power = 50000 },
    Teleport  = { selectedTarget = "", clickTool = nil, clickConn = nil, clickActive = false, lastTap = 0 },
    Security  = { afkActive = true, shiftLock = false, shiftLockGyro = nil, voidConn = nil, antiLag = false },
    Cinema    = { hideUI = false, hideNametag = false, hideBubble = false, nametagConn = nil, bubbleConn = nil, cachedGuis = {} },
    Avatar    = { isRefreshing = false },
    Utility   = { chatLog = false, chatTarget = nil, chatHistory = {}, chatSilent = false },
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
    pcall(function() Fluent:Notify({ Title = title, Content = content, Duration = dur or 2 }) end)
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
local function RefreshDropdown(dropdown, newValues)
    pcall(function()
        dropdown:SetValues(newValues)
    end)
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
--  ANTI AFK / ANTI KICK SYSTEM
-- ══════════════════════════════════════════════════════════════
local AntiAFK = {
    idleConn = nil,
    heartbeatConn = nil,
    kickConn = nil,
    promptConn = nil,
}

local function startAntiAFK()
    State.Security.afkActive = true
    
    if not AntiAFK.idleConn then
        AntiAFK.idleConn = TrackC(LP.Idled:Connect(function()
            if not State.Security.afkActive then return end
            pcall(function()
                VirtualUser:Button2Down(Vector2.zero, Cam.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.zero, Cam.CFrame)
            end)
        end))
    end
    
    if not AntiAFK.heartbeatConn then
        task.spawn(function()
            while State.Security.afkActive and getgenv()._XKID_RUNNING do
                task.wait(math.random(30, 120))
                if not State.Security.afkActive then break end
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:Button2Down(Vector2.zero, Cam.CFrame)
                    task.wait(0.5)
                    VirtualUser:Button2Up(Vector2.zero, Cam.CFrame)
                end)
            end
        end)
    end
    
    if not AntiAFK.kickConn then
        AntiAFK.kickConn = TrackC(GuiService.ErrorMessageChanged:Connect(function(err)
            if err ~= "" then
                notify("Anti Kick", "Kick detected! Rejoining... 🔄", 3)
                task.wait(1)
                pcall(function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
            end
        end))
    end
    
    if not AntiAFK.promptConn then
        AntiAFK.promptConn = TrackC(CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
                notify("Anti Kick", "Kick popup! Rejoining... 🔄", 3)
                task.wait(1)
                pcall(function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
            end
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
    if State.Cinema.hideNametag then
        task.wait(0.3)
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            if p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
                for _, desc in ipairs(p.Character:GetDescendants()) do
                    if desc:IsA("BillboardGui") and desc.Parent then desc.Enabled = false end
                end
            end
        end
    end
    if State.Cinema.hideBubble then
        task.wait(0.3)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.PlayerGui then
                for _, v in ipairs(p.PlayerGui:GetDescendants()) do
                    if v:IsA("BillboardGui") then v.Enabled = false end
                end
            end
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
--  ESP ENGINE (FULL - KEMBALI KE MODE LAMA)
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
--  SMART CLICK TP
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
--  FREECAM ENGINE
-- ══════════════════════════════════════════════════════════════
local FC = { active = false, pos = Vector3.zero, pitchDeg = 0, yawDeg = 0, rollDeg = 0, speed = 3, sens = 0.25, savedCF = nil, origFov = 70, lockGyro = nil, lockPos = nil }
local I_CamVel = Vector3.zero; local I_YawVel = 0; local I_PitchVel = 0; local I_RollVel = 0; local heightVelocity = 0
local fcMoveTouch, fcMoveSt, fcJoy = nil, nil, Vector2.zero; local fcRotTouch, fcRotLast = nil, nil; local fcKeysHeld, fcConns = {}, {}
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
    local function press(down)
        FC_UI_Btns[actionKey] = down; b.BackgroundTransparency = down and 0.05 or 0.4
        indicator.BackgroundColor3 = down and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(60, 60, 60)
    end
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

local function stopFreecamCapture()
    for _, c in ipairs(fcConns) do c:Disconnect() end; fcConns = {}; fcMoveTouch = nil; fcMoveSt = nil; fcJoy = Vector2.zero; fcRotTouch = nil; fcRotLast = nil; fcKeysHeld = {}; FC._mouseRot = false; UIS.MouseBehavior = Enum.MouseBehavior.Default
    I_CamVel = Vector3.zero; I_YawVel = 0; I_PitchVel = 0; I_RollVel = 0; heightVelocity = 0; FC.rollDeg = 0
    for k in pairs(FC_UI_Btns) do FC_UI_Btns[k] = false end
end

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
        local hrp, hum = getRoot(), getHum(); if hrp and not hrp.Anchored then hrp.Anchored = true end; if hum then hum:ChangeState(Enum.HumanoidStateType.Physics); hum.WalkSpeed = 0; hum.JumpPower = 0 end
    end)
end
local function stopFreecamLoop() RS:UnbindFromRenderStep("XKIDFreecam") end

local function fullCleanupFreecam()
    stopFreecamLoop(); stopFreecamCapture(); FC.rollDeg = 0
    pcall(function() if FC.lockGyro then FC.lockGyro:Destroy(); FC.lockGyro = nil end end)
    pcall(function() if FC.lockPos then FC.lockPos:Destroy(); FC.lockPos = nil end end)
    local hrp = getRoot(); if hrp then hrp.Anchored = false; if FC.savedCF then hrp.CFrame = FC.savedCF; FC.savedCF = nil end end
    local hum = getHum(); if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.WalkSpeed = State.Move.ws; hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
    Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = FC.origFov
    if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = false end
    for k in pairs(FC_UI_Btns) do FC_UI_Btns[k] = false end
end

-- ══════════════════════════════════════════════════════════════
--  SPECTATE ENGINE
-- ══════════════════════════════════════════════════════════════
local function inJoystick(pos)
    local ctrl = LP and LP.PlayerGui and LP.PlayerGui:FindFirstChild("TouchGui"); if not ctrl then return false end
    local frame = ctrl:FindFirstChild("TouchControlFrame"); local thumb = frame and frame:FindFirstChild("DynamicThumbstickFrame"); if not thumb then return false end
    return pos.X >= thumb.AbsolutePosition.X and pos.Y >= thumb.AbsolutePosition.Y and pos.X <= thumb.AbsolutePosition.X + thumb.AbsoluteSize.X and pos.Y <= thumb.AbsolutePosition.Y + thumb.AbsoluteSize.Y
end

local Spec = { active = false, target = nil, mode = "third", dist = 8, origFov = 70, orbitYaw = 0, orbitPitch = 0, fpYaw = 0, fpPitch = 0 }
local specTM, specPinch, specPinchD, specPan, specConns = nil, {}, nil, Vector2.zero, {}
local function startSpecCapture()
    table.insert(specConns, UIS.InputBegan:Connect(function(inp, gp) if gp or not Spec.active or inp.UserInputType ~= Enum.UserInputType.Touch or inJoystick(inp.Position) then return end; table.insert(specPinch, inp); specTM = #specPinch == 1 and inp or nil end))
    table.insert(specConns, UIS.InputChanged:Connect(function(inp) if not Spec.active or inp.UserInputType ~= Enum.UserInputType.Touch then return end; if #specPinch == 1 and inp == specTM then specPan = specPan + Vector2.new(inp.Delta.X, inp.Delta.Y) elseif #specPinch >= 2 then local d = (specPinch[1].Position - specPinch[2].Position).Magnitude; if specPinchD then local diff = d - specPinchD; Cam.FieldOfView = math.clamp(Cam.FieldOfView - diff * 0.15, 10, 120); if Spec.mode == "third" then Spec.dist = math.clamp(Spec.dist - diff * 0.03, 3, 30) end end; specPinchD = d end end))
    table.insert(specConns, UIS.InputEnded:Connect(function(inp) if inp.UserInputType ~= Enum.UserInputType.Touch then return end; for i, v in ipairs(specPinch) do if v == inp then table.remove(specPinch, i); break end end; specPinchD = nil; specTM = #specPinch == 1 and specPinch[1] or nil end))
end
local function stopSpecCapture() for _, c in ipairs(specConns) do c:Disconnect() end; specConns = {}; specTM = nil; specPinch = {}; specPinchD = nil; specPan = Vector2.zero end
local function startSpecLoop()
    RS:BindToRenderStep("XKIDSpec", Enum.RenderPriority.Camera.Value + 1, function()
        if not Spec.active then return end
        pcall(function()
            if not Spec.target or not Spec.target.Parent or not Spec.target.Character or not Spec.target.Character:FindFirstChild("HumanoidRootPart") then notify("System", "Target not valid! ⚠️", 2); Spec.active = false; stopSpecLoop(); stopSpecCapture(); Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov; return end
            local hrp = Spec.target.Character.HumanoidRootPart; Cam.CameraType = Enum.CameraType.Scriptable; local pan, sens = specPan, 0.3; specPan = Vector2.zero
            if Spec.mode == "third" then Spec.orbitYaw = Spec.orbitYaw + pan.X * sens; Spec.orbitPitch = math.clamp(Spec.orbitPitch + pan.Y * sens, -75, 75); Cam.CFrame = CFrame.new((CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(-Spec.orbitYaw), 0) * CFrame.Angles(math.rad(-Spec.orbitPitch), 0, 0) * CFrame.new(0, 0, Spec.dist)).Position, hrp.Position + Vector3.new(0, 1, 0))
            else local head = Spec.target.Character:FindFirstChild("Head"); local origin = head and head.Position or hrp.Position + Vector3.new(0, 1.5, 0); Spec.fpYaw = Spec.fpYaw - pan.X * sens; Spec.fpPitch = math.clamp(Spec.fpPitch - pan.Y * sens, -85, 85); Cam.CFrame = CFrame.new(origin) * CFrame.Angles(0, math.rad(Spec.fpYaw), 0) * CFrame.Angles(math.rad(Spec.fpPitch), 0, 0) end
        end)
    end)
end
local function stopSpecLoop() RS:UnbindFromRenderStep("XKIDSpec") end

-- ══════════════════════════════════════════════════════════════
--  CHAT LOGGER (FULL - BERFUNGSI)
-- ══════════════════════════════════════════════════════════════
local chatLogPanel = nil
local chatTargetLabel = nil
local chatTargetDrop = nil

local function logMsg(displayName, msg)
    if not State.Utility.chatLog then return end
    if not State.Utility.chatTarget then return end
    if displayName ~= State.Utility.chatTarget.DisplayName then return end
    local entry = string.format("[%s] %s: %s", os.date("%H:%M:%S"), displayName, msg)
    table.insert(State.Utility.chatHistory, entry)
    if #State.Utility.chatHistory > 50 then table.remove(State.Utility.chatHistory, 1) end
    if not State.Utility.chatSilent then notify("Chat", displayName .. ": " .. msg, 2) end
end
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    pcall(function() TrackC(TextChatService.MessageReceived:Connect(function(m) if m.TextSource then logMsg(m.TextSource.Name, m.Text) end end)) end)
else
    for _, p in ipairs(Players:GetPlayers()) do pcall(function() TrackC(p.Chatted:Connect(function(m) logMsg(p.Name, m) end)) end) end
    TrackC(Players.PlayerAdded:Connect(function(p) pcall(function() TrackC(p.Chatted:Connect(function(m) logMsg(p.Name, m) end)) end) end))
end
task.spawn(function() while getgenv()._XKID_RUNNING do task.wait(0.5); if chatLogPanel and State.Utility.chatLog then pcall(function() local t = table.concat(State.Utility.chatHistory, "\n"); if #t > 2000 then t = t:sub(-2000) end; if #t == 0 then t = "Belum ada chat..." end; chatLogPanel:SetContent(t) end) end end end)

-- ══════════════════════════════════════════════════════════════
--  RGB THEME REGISTRATION
-- ══════════════════════════════════════════════════════════════
local RGB_ACCENT = Color3.fromRGB(255, 0, 0)
task.spawn(function()
    local hue = 0
    while getgenv()._XKID_RUNNING do
        hue = (hue + 0.005) % 1
        RGB_ACCENT = Color3.fromHSV(hue, 1, 1)
        task.wait(0.03)
    end
end)

Fluent:RegisterCustomTheme("XKID_RGB", {
    Accent              = RGB_ACCENT,
    AcrylicMain         = Color3.fromRGB(15, 15, 20),
    AcrylicBorder       = Color3.fromRGB(50, 50, 70),
    AcrylicGradient     = ColorSequence.new(Color3.fromRGB(15, 15, 20), Color3.fromRGB(10, 10, 15)),
    AcrylicNoise        = 0.8,
    TitleBarLine        = Color3.fromRGB(50, 50, 70),
    Tab                 = Color3.fromRGB(25, 25, 35),
    Element             = Color3.fromRGB(20, 20, 30),
    ElementBorder       = Color3.fromRGB(50, 50, 70),
    InElementBorder     = Color3.fromRGB(60, 60, 85),
    ElementTransparency = 0.85,
    ToggleSlider        = Color3.fromRGB(40, 40, 60),
    ToggleToggled       = RGB_ACCENT,
    SliderRail          = Color3.fromRGB(40, 40, 60),
    DropdownFrame       = Color3.fromRGB(20, 20, 32),
    DropdownHolder      = Color3.fromRGB(15, 15, 25),
    DropdownBorder      = Color3.fromRGB(50, 50, 70),
    DropdownOption      = Color3.fromRGB(28, 28, 42),
    Keybind             = Color3.fromRGB(28, 28, 42),
    Input               = Color3.fromRGB(18, 18, 28),
    InputFocused        = Color3.fromRGB(12, 12, 20),
    InputIndicator      = Color3.fromRGB(60, 60, 90),
    InputIndicatorFocus = RGB_ACCENT,
    Dialog              = Color3.fromRGB(15, 15, 25),
    DialogHolder        = Color3.fromRGB(12, 12, 20),
    DialogHolderLine    = Color3.fromRGB(40, 40, 60),
    DialogButton        = Color3.fromRGB(22, 22, 35),
    DialogButtonBorder  = Color3.fromRGB(50, 50, 70),
    DialogBorder        = Color3.fromRGB(50, 50, 70),
    DialogInput         = Color3.fromRGB(18, 18, 28),
    DialogInputLine     = Color3.fromRGB(60, 60, 90),
    Text                = Color3.fromRGB(240, 240, 255),
    SubText             = Color3.fromRGB(140, 140, 175),
    Hover               = Color3.fromRGB(35, 35, 55),
    HoverChange         = 0.04,
    ShineEnabled        = true,
    StrokeShine         = true,
    StrokeDark          = Color3.fromRGB(40, 40, 60),
    IconColor           = RGB_ACCENT,
    IconSize            = 18,
    Background          = nil,
    BackgroundTransparency = 0,
    ThemeAccentColors   = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255) },
})

-- ══════════════════════════════════════════════════════════════
--  MAIN WINDOW
-- ══════════════════════════════════════════════════════════════
local Window = Fluent:CreateWindow({
    Title = "XKID", SubTitle = "Engine v"..CURRENT_VERSION,
    TabWidth = 139, Size = UDim2.fromOffset(580, 460),
    Acrylic = true, Theme = "XKID_RGB",
    MinimizeKey = Enum.KeyCode.RightShift,
    UserInfo = true, UserInfoTop = false,
    UserInfoTitle = "", UserInfoSubtitle = "@WTF.XKID",
    UserInfoColor = Color3.fromRGB(220, 20, 60),
    Search = true,
})

local SaveManager = Fluent.SaveManager
local InterfaceManager = Fluent.InterfaceManager
local FloatingButtonManager = Fluent.FloatingButtonManager

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
FloatingButtonManager:SetLibrary(Fluent)

InterfaceManager:SetFolder("XKIDScript")
SaveManager:SetFolder("XKIDScript/Config")
FloatingButtonManager:SetFolder("XKIDScript/Floating")

SaveManager:IgnoreThemeSettings()

-- ══════════════════════════════════════════════════════════════
--  TAB 1: SYSTEM HUB
-- ══════════════════════════════════════════════════════════════
local T_HOME = Window:AddTab({ Title = "System Hub", Icon = "solar/home-bold" })

local secCredits = T_HOME:AddSection("Credits")
secCredits:AddParagraph({ Title = "💎 XKID Engine v"..CURRENT_VERSION, Content = "Dibuat oleh @WTF.XKID\n📱 Tiktok: @wtf.xkid\n💬 Discord: @4Sharken" })

local secDiscord = T_HOME:AddSection("Discord")
secDiscord:AddButton({ Title = "Copy Discord Link", Icon = "solar/copy-bold", Callback = function() pcall(function() setclipboard("https://discord.gg/bzumc2u96") end); notify("System", "Link disalin ✅", 2) end })

local secStatus = T_HOME:AddSection("Live Monitor")
local srvLabel = secStatus:AddParagraph({ Title = "Server Info", Content = "Loading..." })
local netLabel = secStatus:AddParagraph({ Title = "Performance", Content = "Loading..." })
local securityLabel = secStatus:AddParagraph({ Title = "Diagnostics", Content = "Protected" })

task.spawn(function()
    task.wait(2)
    while getgenv()._XKID_RUNNING do
        task.wait(0.5)
        pcall(function()
            if cachedMapName then
                local pCount, mCount = #Players:GetPlayers(), Players.MaxPlayers
                local uptime = formatTime(os.difftime(os.time(), START_TIME))
                local job = game.JobId ~= "" and game.JobId:sub(1, 8).."..." or "N/A"
                srvLabel:SetContent(string.format("Grid: %s\nNode: %s\nEntities: %d / %d\nSession: %s", cachedMapName, job, pCount, mCount, uptime))
            end
        end)
        pcall(function()
            local fps, ping = math.clamp(sharedFPS, 0, 300), math.clamp(sharedPing, 0, 9999)
            netLabel:SetContent(string.format("FPS: %d | PING: %dms", fps, ping))
        end)
        pcall(function()
            local afk = State.Security.afkActive and "🟢" or "🔴"
            local sl = State.Security.shiftLock and "🟢" or "🔴"
            local vd = State.Security.voidConn and "🟢" or "🔴"
            securityLabel:SetContent(string.format("AFK: %s | ShiftLock: %s | Void: %s", afk, sl, vd))
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 2: PLAYER CORE
-- ══════════════════════════════════════════════════════════════
local T_AV = Window:AddTab({ Title = "Player Core", Icon = "solar/user-circle-bold" })

local secStateCtrl = T_AV:AddSection("State Control")
secStateCtrl:AddButton({ Title = "Fast Respawn 💀", Icon = "solar/skull-bold", Callback = function() fastRespawn() end })
secStateCtrl:AddButton({ Title = "Refresh Character", Icon = "solar/refresh-bold", Callback = function() refreshCharacter() end })

local secMov = T_AV:AddSection("Movement")
secMov:AddSlider("WalkSpeed", { Title = "Walk Speed", Icon = "solar/running-bold", Default = 16, Min = 16, Max = 500, Rounding = 1, Callback = function(v) State.Move.ws = v; if getHum() then getHum().WalkSpeed = v end end })
secMov:AddSlider("JumpPower", { Title = "Jump Power", Icon = "solar/arrow-up-bold", Default = 50, Min = 50, Max = 500, Rounding = 1, Callback = function(v) State.Move.jp = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end })
secMov:AddToggle("InfJump", { Title = "Infinite Jump", Icon = "solar/infinity-bold", Default = false, Callback = function(v) if v then State.Move.infJ = TrackC(UIS.JumpRequest:Connect(function() if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end end)) else if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end end end })

local secAbi = T_AV:AddSection("Abilities")
secAbi:AddToggle("FlyToggle", { Title = "Fly ✈️", Icon = "solar/plain-3-bold", Default = false, Callback = function(v) toggleFly(v) end })
secAbi:AddSlider("FlySpeed", { Title = "Fly Speed", Icon = "solar/speed-bold", Default = 60, Min = 10, Max = 300, Rounding = 1, Callback = function(v) State.Move.flyS = v end })
local noclipConn = nil
secAbi:AddToggle("NoClip", { Title = "NoClip", Icon = "solar/ghost-bold", Default = false, Callback = function(v) State.Move.ncp = v; if v then if not noclipConn then noclipConn = TrackC(RS.Heartbeat:Connect(function() if not State.Move.ncp then return end; if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)) end else if noclipConn then noclipConn:Disconnect(); noclipConn = nil end end end })
local softFlingConn = nil
secAbi:AddToggle("SoftFling", { Title = "Soft Fling ⚡", Icon = "solar/flash-bold", Default = false, Callback = function(v) State.SoftFling.active = v; State.Move.ncp = v; if v then if not softFlingConn then softFlingConn = TrackC(RS.Heartbeat:Connect(function() if not State.SoftFling.active then return end; local r = getRoot(); if not r then return end; pcall(function() r.AssemblyAngularVelocity = Vector3.new(0, State.SoftFling.power, 0) end); if LP.Character then for _, p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)) end else if softFlingConn then softFlingConn:Disconnect(); softFlingConn = nil end end end })

-- ══════════════════════════════════════════════════════════════
--  TAB 3: NAVIGATION
-- ══════════════════════════════════════════════════════════════
local T_TP = Window:AddTab({ Title = "Navigation", Icon = "solar/map-point-bold" })

local secDirTP = T_TP:AddSection("Direct Teleport")
secDirTP:AddToggle("SmartTP", { Title = "Smart Touch/Click TP", Icon = "solar/mouse-bold", Default = false, Callback = toggleSmartTP })

local secTP = T_TP:AddSection("Target Teleport")
local tpTarget = ""
secTP:AddInput("SearchPlayer", { Title = "Search Player", Icon = "solar/magnifer-bold", Placeholder = "Type player name...", Callback = function(v) tpTarget = v end })
secTP:AddButton({ Title = "Execute TP ⚡", Icon = "solar/plain-3-bold", Callback = function()
    pcall(function()
        if tpTarget == "" then notify("Teleport", "Input target!", 2); return end
        local target = nil
        for _, p in pairs(Players:GetPlayers()) do if p ~= LP and (string.find(string.lower(p.Name), string.lower(tpTarget)) or string.find(string.lower(p.DisplayName), string.lower(tpTarget))) then target = p; break end end
        if not target or not target.Character then notify("Teleport", "Invalid Target", 2); return end
        local tHrp = getCharRoot(target.Character); local myHrp = getRoot()
        if not tHrp or not myHrp then return end
        myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3) + Vector3.new(0, 2, 0)
        notify("Teleport", "Teleported to "..target.DisplayName.." ✅", 2)
    end)
end })

local pDropOpts = getDisplayNames()
local tpDropdown = secTP:AddDropdown("PlayerList", { Title = "Player List", Icon = "solar/users-group-rounded-bold", Values = pDropOpts, Default = pDropOpts[1], Multi = false, NoSearch = true, Callback = function(v) tpTarget = v end })
secTP:AddButton({ Title = "🔄 Refresh Player List", Icon = "solar/refresh-bold", Callback = function()
    local newValues = getDisplayNames()
    RefreshDropdown(tpDropdown, newValues)
    notify("System", "List updated ✅", 2)
end })

local secLoc = T_TP:AddSection("Coordinates Cache")
local SavedLocs = {}
for i = 1, 3 do local idx = i
    secLoc:AddButton({ Title = "💾 Save Slot "..idx, Icon = "solar/diskette-bold", Callback = function() local r = getRoot(); if not r then return end; SavedLocs[idx] = r.CFrame; notify("Slot", "Slot "..idx.." saved ✅", 2) end })
    secLoc:AddButton({ Title = "📍 Load Slot "..idx, Icon = "solar/map-arrow-up-bold", Callback = function() if not SavedLocs[idx] then notify("Error", "Slot is empty", 2); return end; local r = getRoot(); if not r then return end; r.CFrame = SavedLocs[idx]; notify("Slot", "Loaded slot "..idx.." ✅", 2) end })
end

-- ══════════════════════════════════════════════════════════════
--  TAB 4: VISION
-- ══════════════════════════════════════════════════════════════
local T_CAM = Window:AddTab({ Title = "Vision", Icon = "solar/eye-bold" })

local secZoom = T_CAM:AddSection("Zoom Override")
secZoom:AddToggle("MaxZoom", { Title = "Max Zoom Out", Icon = "solar/magnifer-zoom-out-bold", Default = false, Callback = function(v) pcall(function() LP.CameraMaxZoomDistance = v and 100000 or 400 end) end })

local secSP = T_CAM:AddSection("Spectator Mode")
local specDropOpts = getDisplayNames()
local specDropdown = secSP:AddDropdown("SpecTarget", { Title = "Select Target", Icon = "solar/user-speak-bold", Values = specDropOpts, Default = specDropOpts[1], Multi = false, NoSearch = true, Callback = function(v)
    local p = findPlayerByDisplay(v)
    if p then
        Spec.target = p
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local _, ry, _ = p.Character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ()
            Spec.orbitYaw = math.deg(ry); Spec.orbitPitch = 20; Spec.fpYaw = math.deg(ry)
        end
        notify("Spectate", "Target: "..p.DisplayName.." ✅", 2)
    end
end })
secSP:AddButton({ Title = "🔄 Refresh Target List", Icon = "solar/refresh-bold", Callback = function()
    local newValues = getDisplayNames()
    RefreshDropdown(specDropdown, newValues)
    notify("System", "List updated ✅", 2)
end })
secSP:AddToggle("EnableSpec", { Title = "Enable Spectate", Icon = "solar/playlist-bold", Default = false, Callback = function(v) Spec.active = v; if v then if not Spec.target or not Spec.target.Character then Spec.active = false; return end; Spec.origFov = Cam.FieldOfView; startSpecCapture(); startSpecLoop() else stopSpecLoop(); stopSpecCapture(); Cam.CameraType = Enum.CameraType.Custom; Cam.FieldOfView = Spec.origFov end end })
secSP:AddToggle("FPMode", { Title = "First Person View", Icon = "solar/gameboy-bold", Default = false, Callback = function(v) Spec.mode = v and "first" or "third" end })
secSP:AddSlider("SpecDist", { Title = "Distance", Icon = "solar/ruler-bold", Default = 8, Min = 3, Max = 30, Rounding = 1, Callback = function(v) Spec.dist = v end })

-- ══════════════════════════════════════════════════════════════
--  TAB 5: FREECAM
-- ══════════════════════════════════════════════════════════════
local T_FREE = Window:AddTab({ Title = "Freecam", Icon = "solar/video-frame-bold" })

local secFC = T_FREE:AddSection("Drone Engine")
secFC:AddToggle("EnableFC", { Title = "Enable Freecam", Icon = "solar/drone-bold", Default = false, Callback = function(v) FC.active = v; if v then local cf = Cam.CFrame; FC.pos = cf.Position; local rx, ry = cf:ToEulerAnglesYXZ(); FC.pitchDeg = math.deg(rx); FC.yawDeg = math.deg(ry); local hrp = getRoot(); if hrp then FC.savedCF = hrp.CFrame; pcall(function() if FC.lockGyro then FC.lockGyro:Destroy() end end); pcall(function() if FC.lockPos then FC.lockPos:Destroy() end end); FC.lockGyro = Instance.new("BodyGyro", hrp); FC.lockGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); FC.lockPos = Instance.new("BodyPosition", hrp); FC.lockPos.MaxForce = Vector3.new(9e9, 9e9, 9e9); hrp.Anchored = true end; FC.origFov = Cam.FieldOfView; startFreecamCapture(); startFreecamLoop(); if getgenv()._XKID_FCUI then getgenv()._XKID_FCUI.Enabled = true end else fullCleanupFreecam() end end })
secFC:AddSlider("FCSpeed", { Title = "Camera Speed", Icon = "solar/speed-bold", Default = 3, Min = 1, Max = 20, Rounding = 1, Callback = function(v) FC.speed = v end })
secFC:AddSlider("FCSens", { Title = "Sensitivity", Icon = "solar/tuning-bold", Default = 0.25, Min = 0.1, Max = 1.0, Rounding = 2, Callback = function(v) FC.sens = v end })

local secCine = T_FREE:AddSection("Cinematic Mode")
secCine:AddToggle("HideUI", { Title = "Hide All UI", Icon = "solar/eye-closed-bold", Default = false, Callback = function(v)
    if v then
        State.Cinema.hideUI = true; State.Cinema.cachedGuis = {}
        for _, gui in pairs(LP.PlayerGui:GetChildren()) do if gui:IsA("ScreenGui") and gui.Enabled then table.insert(State.Cinema.cachedGuis, gui); gui.Enabled = false end end
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
    else
        State.Cinema.hideUI = false
        for _, gui in pairs(State.Cinema.cachedGuis) do if gui and gui.Parent then gui.Enabled = true end end; State.Cinema.cachedGuis = {}
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
    end
end })

-- ══════════════════════════════════════════════════════════════
--  TAB 6: FILTER
-- ══════════════════════════════════════════════════════════════
local T_WO = Window:AddTab({ Title = "Filter", Icon = "solar/layers-bold" })

local secFilter = T_WO:AddSection("Presets")
local function resetFilterOnly() for _, v in pairs(Lighting:GetChildren()) do if v.Name == "_XKID_FILTER" then v:Destroy() end end end
local function applyFilter(filter)
    resetFilterOnly(); if filter == "Default" then return end
    local cc = Instance.new("ColorCorrectionEffect", Lighting); cc.Name = "_XKID_FILTER"
    local bloom = Instance.new("BloomEffect", Lighting); bloom.Name = "_XKID_FILTER"; bloom.Intensity = 0; bloom.Size = 24
    if filter == "Full Bright HD" then cc:Destroy(); bloom:Destroy(); Lighting.GlobalShadows = false; Lighting.Brightness = 3; Lighting.ClockTime = 12; Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    elseif filter == "Mendung HD" then cc.TintColor = Color3.fromRGB(180, 185, 200); cc.Saturation = -0.3; cc.Contrast = 0.1; cc.Brightness = -0.15; bloom.Intensity = 0.05; Lighting.ClockTime = 10; Lighting.Brightness = 0.7
    elseif filter == "Cool Blue HD" then cc.TintColor = Color3.fromRGB(180, 200, 255); cc.Saturation = 0.1; cc.Contrast = 0.15; cc.Brightness = 0.05; bloom.Intensity = 0.2; Lighting.ClockTime = 12; Lighting.Brightness = 1.2
    elseif filter == "Edgy HD" then cc.TintColor = Color3.fromRGB(200, 195, 210); cc.Saturation = -0.5; cc.Contrast = 0.4; cc.Brightness = -0.1; bloom.Intensity = 0.3; bloom.Size = 20; Lighting.ClockTime = 8; Lighting.Brightness = 0.8
    elseif filter == "Senja" then cc.TintColor = Color3.fromRGB(255, 180, 120); cc.Saturation = 0.2; cc.Contrast = 0.1; cc.Brightness = 0.05; bloom.Intensity = 0.5; bloom.Size = 40; Lighting.ClockTime = 17.5
    elseif filter == "Night HD" then cc.TintColor = Color3.fromRGB(200, 200, 255); cc.Saturation = 0.1; cc.Contrast = 0.2; bloom.Intensity = 0.15; Lighting.ClockTime = 1
    end
    notify("Filter", filter.." applied ✅", 2)
end
secFilter:AddDropdown("SelectFilter", { Title = "Select Filter", Icon = "solar/pallete-bold", Values = {"Default","Full Bright HD","Mendung HD","Cool Blue HD","Edgy HD","Senja","Night HD"}, Default = "Default", Multi = false, NoSearch = true, Callback = function(v) applyFilter(v) end })

local secAtmos = T_WO:AddSection("Atmosphere")
secAtmos:AddSlider("Brightness", { Title = "Brightness", Icon = "solar/sun-bold", Default = 5, Min = 0, Max = 10, Rounding = 1, Callback = function(v) Lighting.Brightness = v end })
secAtmos:AddSlider("ClockTime", { Title = "ClockTime", Icon = "solar/clock-circle-bold", Default = 14, Min = 0, Max = 24, Rounding = 1, Callback = function(v) Lighting.ClockTime = v end })
secAtmos:AddButton({ Title = "Reset Atmosphere", Icon = "solar/refresh-bold", Callback = function() Lighting.Brightness = 5; Lighting.ClockTime = 14; resetFilterOnly() end })

-- ══════════════════════════════════════════════════════════════
--  TAB 7: RADAR
-- ══════════════════════════════════════════════════════════════
local T_ESP = Window:AddTab({ Title = "Radar", Icon = "solar/cpu-bold" })

local secESP = T_ESP:AddSection("Detection System")
secESP:AddToggle("EnableESP", { Title = "Enable Radar", Icon = "solar/radar-bold", Default = false, Callback = function(v) State.ESP.active = v end })
secESP:AddDropdown("TracerMode", { Title = "Tracer Origin", Icon = "solar/target-bold", Values = {"Bottom","Center","Mouse","OFF"}, Default = "Bottom", Multi = false, NoSearch = true, Callback = function(v) State.ESP.tracerMode = v end })
secESP:AddToggle("HighlightESP", { Title = "Highlight Entity", Icon = "solar/lightbulb-bold", Default = false, Callback = function(v) State.ESP.highlightMode = v end })
secESP:AddSlider("ScanDist", { Title = "Scan Distance", Icon = "solar/ruler-bold", Default = 300, Min = 50, Max = 500, Rounding = 1, Callback = function(v) State.ESP.maxDrawDistance = v end })

-- ══════════════════════════════════════════════════════════════
--  TAB 8: UTILITY
-- ══════════════════════════════════════════════════════════════
local T_UTIL = Window:AddTab({ Title = "Utility", Icon = "solar/terminal-bold" })

local secChat = T_UTIL:AddSection("Chat Logger")
secChat:AddToggle("EnableLogger", { Title = "Enable Logger", Icon = "solar/chat-round-bold", Default = false, Callback = function(v) State.Utility.chatLog = v end })
secChat:AddToggle("SilentMode", { Title = "Silent Mode", Icon = "solar/volume-cross-bold", Default = false, Callback = function(v) State.Utility.chatSilent = v end })

local chatDropOpts = getDisplayNames()
chatTargetDrop = secChat:AddDropdown("ChatTarget", { Title = "Select Target", Icon = "solar/user-speak-bold", Values = chatDropOpts, Default = chatDropOpts[1], Multi = false, NoSearch = true, Callback = function(v)
    local p = findPlayerByDisplay(v)
    if p then State.Utility.chatTarget = p; pcall(function() chatTargetLabel:SetContent("Tracking: "..p.DisplayName) end) end
end })
chatTargetLabel = secChat:AddParagraph({ Title = "Target", Content = "None" })
secChat:AddButton({ Title = "Clear Target", Icon = "solar/close-circle-bold", Callback = function() State.Utility.chatTarget = nil; pcall(function() chatTargetLabel:SetContent("None") end); pcall(function() chatTargetDrop:SetValues(getDisplayNames()) end) end })
secChat:AddButton({ Title = "🔄 Refresh List", Icon = "solar/refresh-bold", Callback = function() RefreshDropdown(chatTargetDrop, getDisplayNames()) end })
chatLogPanel = secChat:AddParagraph({ Title = "Console", Content = "Belum ada chat..." })
secChat:AddButton({ Title = "Clear Log", Icon = "solar/trash-bin-bold", Callback = function() State.Utility.chatHistory = {}; pcall(function() chatLogPanel:SetContent("Belum ada chat...") end) end })

local secMisc = T_UTIL:AddSection("Data Extraction")
secMisc:AddButton({ Title = "Copy JobID", Icon = "solar/copy-bold", Callback = function() pcall(function() setclipboard(game.JobId) end); notify("Utility", "JobID copied ✅", 2) end })

-- ══════════════════════════════════════════════════════════════
--  TAB 9: SECURITY
-- ══════════════════════════════════════════════════════════════
local T_SEC = Window:AddTab({ Title = "Security", Icon = "solar/shield-bold" })

local secProt = T_SEC:AddSection("Protection Protocols")
secProt:AddToggle("AntiAFK", { Title = "Anti AFK / Anti Kick 🛡️", Icon = "solar/shield-check-bold", Default = true, Callback = function(v) if v then startAntiAFK() else stopAntiAFK() end end })
secProt:AddToggle("AntiVoid", { Title = "Anti Void 🕳️", Icon = "solar/black-hole-bold", Default = false, Callback = function(v) if v then State.Security.voidConn = TrackC(RS.Heartbeat:Connect(function() local hrp = getRoot(); if hrp and hrp.Position.Y <= workspace.FallenPartsDestroyHeight + 50 then hrp.AssemblyLinearVelocity = Vector3.zero; hrp.CFrame = hrp.CFrame + Vector3.new(0, 300, 0) end end)) else if State.Security.voidConn then State.Security.voidConn:Disconnect(); State.Security.voidConn = nil end end end })
secProt:AddButton({ Title = "Stuck Fix 🔧", Icon = "solar/wrench-bold", Callback = function() local hrp, hum = getRoot(), getHum(); if hrp then hrp.Anchored = false; hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0) end; if hum then hum.Sit = false; hum:ChangeState(Enum.HumanoidStateType.Jumping) end end })

local secSrv = T_SEC:AddSection("Server Control")
secSrv:AddButton({ Title = "Force Rejoin", Icon = "solar/restart-bold", Callback = function() pcall(function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end) end })
secSrv:AddButton({ Title = "Server Hop", Icon = "solar/globus-bold", Callback = function() pcall(function() local req = (syn and syn.request) or (http and http.request) or http_request or request; if not req then return end; local res = req({Url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100", Method = "GET"}); if res.StatusCode == 200 then local body = HttpService:JSONDecode(res.Body); if body and body.data then for _, v in ipairs(body.data) do if v.playing > 0 and v.playing < v.maxPlayers and v.id ~= game.JobId then TPService:TeleportToPlaceInstance(game.PlaceId, v.id, LP); return end end end end end) end })

local secCamLock = T_SEC:AddSection("Camera Lock")
secCamLock:AddToggle("ShiftLock", { Title = "Force Shift Lock", Icon = "solar/lock-bold", Default = false, Callback = function(v) toggleShiftLock(v) end })

-- ══════════════════════════════════════════════════════════════
--  TAB 10: CONFIG
-- ══════════════════════════════════════════════════════════════
local T_SET = Window:AddTab({ Title = "Config", Icon = "solar/settings-bold" })
InterfaceManager:BuildInterfaceSection(T_SET)
SaveManager:BuildConfigSection(T_SET)
FloatingButtonManager:BuildConfigSection(T_SET)

-- ══════════════════════════════════════════════════════════════
--  FLOATING BUTTON (MOBILE + PC MINIMIZE)
-- ══════════════════════════════════════════════════════════════
local floaterGui = Instance.new("ScreenGui")
floaterGui.Name = "XKID_Floater"
floaterGui.Parent = LP:WaitForChild("PlayerGui")
floaterGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
floaterGui.ResetOnSpawn = false

local floaterBtn = Instance.new("TextButton")
floaterBtn.Name = "FloaterButton"
floaterBtn.Parent = floaterGui
floaterBtn.BackgroundColor3 = Color3.fromRGB(220, 20, 60)
floaterBtn.Position = UDim2.new(0.85, 0, 0.5, 0)
floaterBtn.Size = UDim2.new(0, 48, 0, 48)
floaterBtn.Text = "🔄"
floaterBtn.TextSize = 24
floaterBtn.Visible = false
Instance.new("UICorner", floaterBtn).CornerRadius = UDim.new(1, 0)

local floaterStroke = Instance.new("UIStroke", floaterBtn)
floaterStroke.Thickness = 2
floaterStroke.Color = Color3.fromRGB(255, 255, 255)

task.spawn(function()
    local hue = 0
    while getgenv()._XKID_RUNNING do
        hue = (hue + 0.01) % 1
        floaterBtn.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        floaterStroke.Color = Color3.fromHSV((hue + 0.5) % 1, 1, 1)
        task.wait(0.03)
    end
end)

local function makeFloaterDraggable(btn)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeFloaterDraggable(floaterBtn)

floaterBtn.MouseButton1Click:Connect(function()
    Window:Minimize()
    floaterBtn.Visible = true
end)

local function onMinimize()
    floaterBtn.Visible = true
end

local function onRestore()
    floaterBtn.Visible = false
end

-- Deteksi minimize/restore Fluent
task.spawn(function()
    while getgenv()._XKID_RUNNING do
        pcall(function()
            local fluentGui = CoreGui:FindFirstChild("Fluent")
            if fluentGui then
                local mainFrame = fluentGui:FindFirstChild("MainFrame") or fluentGui:FindFirstChild("Main")
                if mainFrame then
                    if mainFrame.Visible == false and not floaterBtn.Visible then
                        onMinimize()
                    elseif mainFrame.Visible == true and floaterBtn.Visible then
                        onRestore()
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

FloatingButtonManager:AddButton("XKID_Floater", floaterBtn, false, false)

-- ══════════════════════════════════════════════════════════════
--  STARTUP
-- ══════════════════════════════════════════════════════════════
SaveManager:LoadAutoloadConfig()
FloatingButtonManager:LoadAutoloadConfig()
pcall(function() Window:SelectTab(1) end)
notify("System", "XKID Engine v"..CURRENT_VERSION.." - RGB Edition Ready ⚡", 3)
print("✅ XKID Engine v"..CURRENT_VERSION.." - Fluent RGB Edition")