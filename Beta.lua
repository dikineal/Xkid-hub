--[[
╔═══════════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  MINIMAL 🌟                ║
║                  Aurora UI  ·  19 Features Only            ║
╚═══════════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TpService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local function getChar() return LP.Character end
local function getRoot() 
    local c = getChar(); 
    return c and c:FindFirstChild("HumanoidRootPart") 
end
local function getHum() 
    local c = getChar(); 
    return c and c:FindFirstChildOfClass("Humanoid") 
end

local function notify(title, text)
    pcall(function() 
        Library:Notification(title, text, 3) 
    end)
    print(string.format("[XKID MINI] %s: %s", title, text))
end

-- Fly System
local flyConn, flyBodyVel
local Move = {flying = false, flySpeed = 60}
local function toggleFly(enabled)
    if enabled then
        local r = getRoot()
        if r then
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            flyBodyVel.Parent = r
            flyConn = RunService.RenderStepped:Connect(function()
                if not Move.flying or not r.Parent then
                    if flyBodyVel then flyBodyVel:Destroy() end
                    if flyConn then flyConn:Disconnect() end
                    return
                end
                local vel = Vector3.new()
                if UIS:IsKeyDown(Enum.KeyCode.W) then vel = vel + r.CFrame.LookVector * Move.flySpeed end
                if UIS:IsKeyDown(Enum.KeyCode.S) then vel = vel - r.CFrame.LookVector * Move.flySpeed end
                if UIS:IsKeyDown(Enum.KeyCode.A) then vel = vel - r.CFrame.RightVector * Move.flySpeed end
                if UIS:IsKeyDown(Enum.KeyCode.D) then vel = vel + r.CFrame.RightVector * Move.flySpeed end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, Move.flySpeed, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0, Move.flySpeed, 0) end
                flyBodyVel.Velocity = vel
            end)
            notify("Fly", "ON (WASD + Space/Shift)")
        end
    else
        Move.flying = false
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
        notify("Fly", "OFF")
    end
end

-- Noclip
local noclipConn
local function toggleNoclip(enabled)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if enabled then
        noclipConn = RunService.Stepped:Connect(function()
            local c = getChar()
            if c then
                for _, p in pairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
        notify("NoClip", "ON")
    else
        notify("NoClip", "OFF")
    end
end

-- Infinite Jump
local infJumpConn
local function toggleInfJump(enabled)
    if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    if enabled then
        infJumpConn = UIS.JumpRequest:Connect(function()
            local h = getHum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        notify("Inf Jump", "ON")
    else
        notify("Inf Jump", "OFF")
    end
end

-- ESP Players
local espConn, espLabels = nil, {}
local function toggleESP(enabled)
    if espConn then espConn:Disconnect() espConn = nil end
    for _, label in pairs(espLabels) do label:Destroy() end
    espLabels = {}
    
    if enabled then
        espConn = RunService.RenderStepped:Connect(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local root = p.Character.HumanoidRootPart
                    local dist = (getRoot().Position - root.Position).Magnitude
                    local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
                    
                    if onScreen and not espLabels[p.UserId] then
                        local label = Instance.new("BillboardGui")
                        label.Name = "XKID_ESP_" .. p.UserId
                        label.Adornee = root
                        label.Size = UDim2.new(0, 200, 0, 50)
                        label.StudsOffset = Vector3.new(0, 3, 0)
                        label.Parent = root
                        
                        local text = Instance.new("TextLabel")
                        text.Size = UDim2.new(1, 0, 1, 0)
                        text.BackgroundTransparency = 1
                        text.Text = p.Name .. "
[" .. math.floor(dist) .. "m]"
                        text.TextColor3 = Color3.new(1, 1, 1)
                        text.TextStrokeTransparency = 0
                        text.Font = Enum.Font.GothamBold
                        text.TextScaled = true
                        text.Parent = label
                        
                        espLabels[p.UserId] = label
                    elseif espLabels[p.UserId] then
                        espLabels[p.UserId].TextLabel.Text = p.Name .. "
[" .. math.floor(dist) .. "m]"
                    end
                end
            end
        end)
        notify("ESP", "ON")
    else
        notify("ESP", "OFF")
    end
end

-- Bring Player
local function bringPlayer(playerName)
    local target = Players:FindFirstChild(playerName)
    if not target or not target.Character then
        notify("Bring", "Player tidak ditemukan")
        return
    end
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local myRoot = getRoot()
    if targetRoot and myRoot then
        targetRoot.CFrame = myRoot.CFrame * CFrame.new(2, 0, 0)
        notify("Bring", playerName .. " ditarik!")
    end
end

-- Respawn with Save
local savedPos = nil
local function savePosition()
    local root = getRoot()
    if root then
        savedPos = root.CFrame
        notify("Save Pos", "Posisi tersimpan!")
    end
end

local function respawnToSaved()
    if savedPos then
        LP.Character:BreakJoints()
        LP.CharacterAdded:Wait()
        task.wait(1)
        local root = getRoot()
        if root then root.CFrame = savedPos end
        notify("Respawn", "Teleport kembali!")
    end
end

-- Anti AFK
local antiAfkConn
local function toggleAntiAfk(enabled)
    if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
    if enabled then
        antiAfkConn = RunService.Heartbeat:Connect(function()
            local cam = Workspace.CurrentCamera
            cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(1), 0)
        end)
        notify("Anti AFK", "ON")
    end
end

-- Anti Kick (HP Lock)
local antiKickConn
local function toggleAntiKick(enabled)
    if antiKickConn then antiKickConn:Disconnect() antiKickConn = nil end
    if enabled then
        antiKickConn = RunService.Heartbeat:Connect(function()
            local h = getHum()
            if h and h.Health < h.MaxHealth * 0.2 then
                h.Health = h.MaxHealth
            end
        end)
        notify("Anti Kick", "ON")
    end
end

-- Main UI
local Win = Library:Window("XKID HUB MINIMAL", "crown", "19 Features", false)

-- TELEPORT TAB (5 Fitur)
local TeleTab = Win:Tab("Teleport", "map-pin")
local TelePage = TeleTab:Page("Locations", "globe")

TelePage:Button("🏠 Spawn", "Teleport ke spawn", "Left", function()
    local r = getRoot()
    if r then r.CFrame = CFrame.new(0, 50, 0) notify("Teleport", "Spawn!") end
end)

TelePage:Button("📍 Save Position", "Simpan posisi sekarang", "Left", savePosition)

TelePage:Button("🔄 Respawn to Saved", "Respawn & TP kembali", "Left", respawnToSaved)

TelePage:Paragraph("Bring Player", "Tarik player ke posisi kamu", "Right")

TelePage:Button("👤 Bring Player1", "Pull Player1", "Right", function()
    bringPlayer("Player1")
end)

TelePage:Button("👥 Bring Nearest", "Pull player terdekat", "Right", function()
    local nearest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (getRoot().Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then nearest, dist = p, d end
        end
    end
    if nearest then bringPlayer(nearest.Name) end
end)

-- PLAYER TAB (8 Fitur)
local PlayTab = Win:Tab("Player", "user")
local PlayPage = PlayTab:Page("Movement", "sword")

PlayPage:Slider("Speed", "ws", 16, 500, 16, function(v)
    local h = getHum()
    if h then h.WalkSpeed = v end
end, "16")

PlayPage:Slider("Jump Power", "jp", 50, 500, 50, function(v)
    local h = getHum()
    if h then h.JumpPower = v; h.UseJumpPower = true end
end, "50")

PlayPage:Toggle("Fly", "fly", false, "WASD + Space/Shift", "Left", function(v)
    Move.flying = v
    toggleFly(v)
end)

PlayPage:Slider("Fly Speed", "fs", 10, 300, 60, function(v)
    Move.flySpeed = v
end, "60")

PlayPage:Toggle("NoClip", "nc", false, "Walk through walls", "Left", function(v)
    toggleNoclip(v)
end)

PlayPage:Toggle("Inf Jump", "ij", false, "Unlimited jumping", "Left", function(v)
    toggleInfJump(v)
end)

PlayPage:Toggle("ESP Players", "esp", false, "Player names + distance", "Left", function(v)
    toggleESP(v)
end)

-- SECURITY TAB (6 Fitur)
local SecTab = Win:Tab("Security", "shield")
local SecPage = SecTab:Page("Protection", "shield")

SecPage:Toggle("Anti AFK", "antiAfk", false, "Prevent idle kick", "Left", function(v)
    toggleAntiAfk(v)
end)

SecPage:Toggle("Anti Kick", "antiKick", false, "HP lock >20%", "Left", function(v)
    toggleAntiKick(v)
end)

SecPage:Button("🔄 Rejoin Server", "Rejoin current game", "Left", function()
    TpService:Teleport(game.PlaceId, LP)
end)

Library:ConfigSystem(Win)

notify("XKID MINIMAL", "19 Features Loaded!")
Library:Notification("XKID HUB", "Teleport(5) + Player(8) + Security(6)", 5)

print("XKID MINIMAL v5.26 - 19 Features Only")