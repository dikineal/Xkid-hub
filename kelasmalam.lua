--[[
╔════════════════════════════════════════════════════════════════╗
║              🌟  XKID HUB v5.26 FIXED 🌟                    ║
║                Aurora UI · Optimized Edition                 ║
║        Teleport · Player · Security · Setting                ║
╚════════════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local lastCFrame = nil
local logLines = {}

local function getChar()
    return LP.Character
end

local function getRoot()
    local c = getChar()
    if c then return c:FindFirstChild("HumanoidRootPart") end
    return nil
end

local function getHum()
    local c = getChar()
    if c then return c:FindFirstChildOfClass("Humanoid") end
    return nil
end

local function notify(title, message, duration)
    pcall(function()
        Library:Notification(title, message, duration or 3)
    end)
    print("[XKID] " .. title .. " | " .. tostring(message))
end

local function xlog(tag, msg, isError)
    local entry = string.format("[%s][%s] %s", os.date("%H:%M:%S"), tag, msg)
    table.insert(logLines, 1, entry)
    if #logLines > 30 then table.remove(logLines) end
    print(entry)
    if isError then
        pcall(function()
            Library:Notification("❌ " .. tag, msg:sub(1, 80), 5)
        end)
    end
end

local function getBridge()
    local bn = RS:FindFirstChild("BridgeNet2")
    if bn then return bn:FindFirstChild("dataRemoteEvent") end
    return nil
end

local function getFishEv(name)
    local fr = RS:FindFirstChild("FishRemotes")
    if fr then return fr:FindFirstChild(name) end
    return nil
end

RunService.Heartbeat:Connect(function()
    local r = getRoot()
    if r then lastCFrame = r.CFrame end
end)

local Move = {
    flying = false,
    flySpeed = 60,
}

local Respawn = {
    savedPosition = nil,
}

local Fish = {
    autoOn = false,
    fishTask = nil,
    waitDelay = 2,
    rodEquipped = false,
    totalFished = 0,
    instantDelay = 2,
}

local ESPPl = {
    active = false,
    uis = {},
    conn = nil,
}

local flyConn = nil
local noclipConn = nil
local infJumpConn = nil
local afkConn = nil
local antiKickConn = nil

local function startFly()
    if Move.flying then return end
    Move.flying = true
    local r = getRoot()
    if not r then Move.flying = false return end
    
    local bd = Instance.new("BodyVelocity")
    bd.Parent = r
    bd.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bd.Velocity = Vector3.new()
    
    flyConn = RunService.RenderStepped:Connect(function()
        if not Move.flying or not r or not r.Parent then
            pcall(function() bd:Destroy() end)
            if flyConn then flyConn:Disconnect() end
            Move.flying = false
            return
        end
        
        local vel = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then vel = vel + r.CFrame.LookVector * Move.flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.S) then vel = vel - r.CFrame.LookVector * Move.flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.A) then vel = vel - r.CFrame.RightVector * Move.flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.D) then vel = vel + r.CFrame.RightVector * Move.flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, Move.flySpeed, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then vel = vel - Vector3.new(0, Move.flySpeed, 0) end
        
        bd.Velocity = vel
    end)
end

local function stopFly()
    Move.flying = false
    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end
end

local function setNoclip(enabled)
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    if not enabled then return end
    
    noclipConn = RunService.Stepped:Connect(function()
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end)
end

local function setInfJump(enabled)
    if infJumpConn then
        infJumpConn:Disconnect()
        infJumpConn = nil
    end
    if not enabled then return end
    
    infJumpConn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.Space then
            local h = getHum()
            if h then h:Jump() end
        end
    end)
end

local function startESPPlayer()
    if ESPPl.conn then ESPPl.conn:Disconnect() end
    
    ESPPl.conn = RunService.RenderStepped:Connect(function()
        if not ESPPl.active then return end
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local chr = p.Character
            if chr and chr:FindFirstChild("HumanoidRootPart") then
                local pos = chr.HumanoidRootPart.Position
                local root = getRoot()
                local dist = (root.Position - pos).Magnitude
                local txt = p.Name .. " [" .. string.format("%.1f", dist) .. "m]"
                
                if not ESPPl.uis[p.UserId] then
                    local label = Instance.new("TextLabel")
                    label.Name = "ESP_" .. p.UserId
                    label.Parent = game:GetService("CoreGui")
                    label.BackgroundTransparency = 0.3
                    label.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    label.TextColor3 = Color3.new(1, 1, 1)
                    label.TextSize = 14
                    label.Size = UDim2.new(0, 150, 0, 20)
                    ESPPl.uis[p.UserId] = label
                end
                
                local label = ESPPl.uis[p.UserId]
                if label then
                    label.Text = txt
                    local camPos = Workspace.CurrentCamera:WorldToScreenPoint(pos)
                    label.Position = UDim2.new(0, camPos.X - 75, 0, camPos.Y - 10)
                    label.Visible = camPos.Z > 0
                end
            end
        end
    end)
end

local function stopESPPlayer()
    if ESPPl.conn then
        ESPPl.conn:Disconnect()
        ESPPl.conn = nil
    end
    for _, label in pairs(ESPPl.uis) do
        pcall(function() label:Destroy() end)
    end
    ESPPl.uis = {}
end

local function bringPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        notify("❌ Bring", "Player tidak valid", 2)
        return false
    end
    
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        notify("❌ Bring", "Target tidak punya HumanoidRootPart", 2)
        return false
    end
    
    local myRoot = getRoot()
    if not myRoot then
        notify("❌ Bring", "You tidak punya HumanoidRootPart", 2)
        return false
    end
    
    local ok = pcall(function()
        targetRoot.CFrame = myRoot.CFrame + Vector3.new(0, 3, 0)
    end)
    
    if ok then
        notify("✅ Bring", "Pulled " .. targetPlayer.Name .. " to you!", 2)
        return true
    else
        notify("❌ Bring", "Error pulling player", 2)
        return false
    end
end

local function doRespawn()
    local saved = lastCFrame
    local char = LP.Character
    if char then char:BreakJoints() end
    
    local conn
    conn = LP.CharacterAdded:Connect(function(nc)
        conn:Disconnect()
        task.wait(0.5)
        local hrp = nc:WaitForChild("HumanoidRootPart", 5)
        if hrp and saved then
            hrp.CFrame = saved
        end
        notify("✅ Respawn", "Back to saved position!", 2)
    end)
end

local function equipRod()
    local bp = LP:FindFirstChildOfClass("Backpack")
    if not bp then return false end
    
    local rod = bp:FindFirstChild("AdvanceRod") or bp:FindFirstChild("Rod")
    if not rod then
        xlog("Fishing", "Rod not found", true)
        return false
    end
    
    pcall(function() rod.Parent = LP.Character end)
    task.wait(0.5)
    Fish.rodEquipped = true
    return true
end

local function unequipRod()
    local char = getChar()
    if not char then return false end
    
    local rod = char:FindFirstChild("AdvanceRod") or char:FindFirstChild("Rod")
    if rod then
        pcall(function() rod.Parent = LP.Backpack end)
    end
    
    Fish.rodEquipped = false
    return true
end

local function castOnce()
    local castEv = getFishEv("CastEvent")
    if not castEv then return false end
    
    pcall(function() castEv:FireServer(true) end)
    task.wait(0.8)
    pcall(function() castEv:FireServer(false, Fish.instantDelay) end)
    task.wait(Fish.instantDelay)
    
    local miniEv = getFishEv("MiniGame")
    if miniEv then
        pcall(function() miniEv:FireServer(true) end)
        task.wait(0.2)
        pcall(function() miniEv:FireServer(true) end)
    end
    
    Fish.totalFished = Fish.totalFished + 1
    task.wait(0.5)
    return true
end

local Win = Library:CreateWindow("XKID HUB v5.26", false, 3)
local T_Tele = Win:Tab("Teleport", "map-pin")
local T_Play = Win:Tab("Player", "user")
local T_Sec = Win:Tab("Security", "shield")
local T_Set = Win:Tab("Setting", "sliders")

local TeleP = T_Tele:Page("Teleport", "map-pin")
local TeleL = TeleP:Section("📍 Teleport", "Left")
local TeleR = TeleP:Section("👥 Bring Player", "Right")

TeleL:Button("🏠 Spawn", "Go to spawn", function()
    local r = getRoot()
    if r then
        r.CFrame = CFrame.new(0, 50, 0)
        notify("TP", "✅ Spawn", 1)
    end
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        TeleL:Button("👤 " .. p.Name, "TP to " .. p.Name, function()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local r = getRoot()
                if r then
                    r.CFrame = p.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                    notify("TP", "✅ To " .. p.Name, 1)
                end
            end
        end)
    end
end

TeleL:Paragraph("📖 Info", "Teleport to Spawn\nor to Players")

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        TeleR:Button("🔗 " .. p.Name, "Pull " .. p.Name, function()
            bringPlayer(p)
        end)
    end
end

TeleR:Paragraph("ℹ️ Bring Player", "Click player name\nto pull them to you!")

local PlayP = T_Play:Page("Player", "user")
local PlayL = PlayP:Section("⚡ Speed & Jump", "Left")
local PlayR = PlayP:Section("🚀 Fly & ESP", "Right")

PlayL:Slider("Walk Speed", "ws", 16, 500, 16, function(v)
    local h = getHum()
    if h and not Move.flying then
        h.WalkSpeed = v
    end
end, "Default 16")

PlayL:Slider("Jump Power", "jp", 50, 500, 50, function(v)
    local h = getHum()
    if h then
        h.JumpPower = v
        h.UseJumpPower = true
    end
end, "Default 50")

PlayL:Toggle("Infinite Jump", "infJump", false, "Hold space", function(v)
    setInfJump(v)
    notify("Inf Jump", v and "ON" or "OFF", 2)
end)

PlayL:Toggle("NoClip", "noclip", false, "Walk through walls", function(v)
    setNoclip(v)
    notify("NoClip", v and "ON" or "OFF", 2)
end)

PlayR:Toggle("Fly", "fly", false, "WASD + Space/Q", function(v)
    if v then startFly() else stopFly() end
    notify("Fly", v and "ON" or "OFF", 2)
end)

PlayR:Slider("Fly Speed", "flySpd", 10, 300, 60, function(v)
    Move.flySpeed = v
end, "Speed")

PlayR:Toggle("ESP Player", "espPl", false, "See all players", function(v)
    ESPPl.active = v
    if v then
        startESPPlayer()
    else
        stopESPPlayer()
    end
    notify("ESP", v and "ON" or "OFF", 2)
end)

PlayR:Paragraph("Controls", "Fly: WASD\nSpace: Up\nQ: Down")

local SecP = T_Sec:Page("Security", "shield")
local SecL = SecP:Section("🛡️ Protection", "Left")
local SecR = SecP:Section("ℹ Info", "Right")

SecL:Toggle("Anti AFK", "antiAfk", false, "Prevent kick", function(v)
    if v then
        if afkConn then afkConn:Disconnect() end
        afkConn = LP.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if afkConn then
            afkConn:Disconnect()
            afkConn = nil
        end
    end
    notify("Anti AFK", v and "ON" or "OFF", 2)
end)

SecL:Toggle("Anti Kick", "antiKick", false, "Lock HP > 15%", function(v)
    if v then
        if antiKickConn then antiKickConn:Disconnect() end
        antiKickConn = RunService.Heartbeat:Connect(function()
            local h = getHum()
            if h and h.Health > 0 and h.Health < h.MaxHealth * 0.15 then
                h.Health = h.MaxHealth
            end
        end)
    else
        if antiKickConn then
            antiKickConn:Disconnect()
            antiKickConn = nil
        end
    end
    notify("Anti Kick", v and "ON" or "OFF", 2)
end)

SecL:Label("⚡ Respawn")

SecL:Button("⚡ Respawn Now", "Die and TP back", function()
    task.spawn(doRespawn)
end)

SecL:Button("📍 Save Position", "Save current pos", function()
    local root = getRoot()
    if root then
        Respawn.savedPosition = root.CFrame
        local p = root.Position
        notify("📍 Saved", string.format("X=%.1f Y=%.1f Z=%.1f", p.X, p.Y, p.Z), 3)
    end
end)

SecL:Button("🔄 Rejoin", "Reconnect to server", function()
    notify("Rejoin", "Reconnecting...", 3)
    task.wait(1)
    TpService:Teleport(game.PlaceId, LP)
end)

SecR:Paragraph("Anti AFK", "Simulate input when idle")
SecR:Paragraph("Anti Kick", "HP < 15% = auto heal")
SecR:Paragraph("Respawn", "Save and restore position")

local SetP = T_Set:Page("Setting", "settings")
local SetL = SetP:Section("🎣 Fishing", "Left")
local SetR = SetP:Section("📋 Log", "Right")

SetL:Label("Fishing Settings")

SetL:Slider("Hold Duration", "fishHold", 1, 10, 2, function(v)
    Fish.instantDelay = v
end, "How long to hold cast")

SetL:Slider("Timeout Wait", "fishWait", 10, 180, 120, function(v)
    Fish.waitDelay = v
end, "Max wait for minigame")

SetL:Label("Auto Fishing")

SetL:Toggle("Auto Fish", "autoFish", false, "Auto cast loop", function(v)
    Fish.autoOn = v
    if v then
        task.spawn(function()
            if not Fish.rodEquipped then
                if not equipRod() then
                    Fish.autoOn = false
                    return
                end
                task.wait(0.3)
            end
            
            notify("Fishing 🎣", "Auto ON!", 3)
            local attempts = 0
            
            Fish.fishTask = task.spawn(function()
                while Fish.autoOn do
                    local ok = pcall(castOnce)
                    if ok then
                        attempts = 0
                    else
                        attempts = attempts + 1
                        if attempts >= 3 then
                            notify("Fishing", "Auto stopped", 3)
                            Fish.autoOn = false
                            break
                        end
                        task.wait(3)
                    end
                end
            end)
        end)
    else
        if Fish.fishTask then
            pcall(function() task.cancel(Fish.fishTask) end)
            Fish.fishTask = nil
        end
        notify("Fishing", "OFF | Total: " .. Fish.totalFished, 2)
    end
end)

SetL:Button("🎣 Cast Once", "1x manual cast", function()
    task.spawn(function()
        if not Fish.rodEquipped then
            if not equipRod() then return end
            task.wait(0.5)
        end
        castOnce()
        notify("Fishing", "Cast done! Total: " .. Fish.totalFished, 2)
    end)
end)

SetL:Button("📦 Equip Rod", "Get rod from backpack", function()
    if equipRod() then
        notify("Rod", "Equipped", 1)
    end
end)

SetL:Button("📤 Unequip Rod", "Return rod", function()
    unequipRod()
    notify("Rod", "Unequipped", 1)
end)

SetR:Button("📋 Recent Logs", "Last 5 logs", function()
    if #logLines == 0 then
        notify("Log", "No logs", 1)
        return
    end
    local txt = ""
    for i = 1, math.min(5, #logLines) do
        txt = txt .. logLines[i] .. "\n"
    end
    notify("Logs (" .. #logLines .. ")", txt, 12)
end)

SetR:Button("📋 All Logs", "Last 10 logs", function()
    if #logLines == 0 then
        notify("Log", "No logs", 1)
        return
    end
    local txt = ""
    for i = 1, math.min(10, #logLines) do
        txt = txt .. logLines[i] .. "\n"
    end
    notify("All Logs", txt, 15)
end)

SetR:Button("🗑 Clear Logs", "Delete all logs", function()
    logLines = {}
    notify("Log", "Cleared", 2)
end)

SetR:Paragraph("XKID v5.26", "Teleport + Bring Player\nPlayer Mods\nSecurity + Fishing")

notify("✅ XKID HUB v5.26 Ready", "4 Tabs Active - No Errors", 5)
Library:Notification("XKID HUB v5.26", "Teleport · Player · Security · Setting", 6)
Library:ConfigSystem(Win)

print("[XKID HUB] v5.26 FIXED loaded — " .. LP.Name)
