--[[
╔═══════════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.26  CLEAN 🌟           ║
║                  Aurora UI  ·  No Fishing Edition          ║
╚═══════════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/main/Aurora.lua"
))()

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local TpService   = game:GetService("TeleportService")
local Workspace   = game:GetService("Workspace")
local LP          = Players.LocalPlayer

local function getChar() return LP.Character end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function notify(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
    print(string.format("[XKID CLEAN] %s | %s", t, tostring(b)))
end

local lastCFrame
RunService.Heartbeat:Connect(function()
    local r = getRoot()
    if r and r.Parent then lastCFrame = r.CFrame end
end)

local Move = {flying = false, flySpeed = 60, speed = 16}
local ESPPl = {active = false, uis = {}, conn = nil}
local flyConn, noclipConn, infJumpConn, afkConn, antiKickConn

local function startFly()
    if Move.flying then return end
    Move.flying = true
    local r = getRoot()
    if not r then return end
    local bd = Instance.new("BodyVelocity")
    bd.Parent = r
    bd.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bd.Velocity = Vector3.new()
    flyConn = RunService.RenderStepped:Connect(function()
        if not Move.flying or not r or not r.Parent then
            if bd then pcall(function() bd:Destroy() end) end
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
    if flyConn then flyConn:Disconnect() flyConn = nil end
end

local function setNoclip(enabled)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if not enabled then return end
    noclipConn = RunService.Stepped:Connect(function()
        local c = getChar()
        if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    end)
end

local function setInfJump(enabled)
    if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
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
                local dist = (getRoot().Position - pos).Magnitude
                local txt = string.format("%s [%.1fm]", p.Name, dist)
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
    if ESPPl.conn then ESPPl.conn:Disconnect() ESPPl.conn = nil end
    for _, label in pairs(ESPPl.uis) do pcall(function() label:Destroy() end) end
    ESPPl.uis = {}
end

local function bringPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        notify("Bring","Player tidak valid",2)
        return false
    end
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        notify("Bring","Target tidak ada HRP",2)
        return false
    end
    local myRoot = getRoot()
    if not myRoot then
        notify("Bring","Anda tidak ada HRP",2)
        return false
    end
    local ok = pcall(function()
        targetRoot.CFrame = myRoot.CFrame + Vector3.new(0, 3, 0)
    end)
    if ok then
        notify("✅ Bring","Pulled "..targetPlayer.Name,2)
        return true
    else
        notify("❌ Bring","Error",2)
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
        task.wait(1)
        local hrp = nc:WaitForChild("HumanoidRootPart",5)
        if hrp and saved then hrp.CFrame = saved end
        notify("Respawn","Kembali ke posisi!",2)
    end)
end

local Win = Library:CreateWindow("XKID HUB v5.26 CLEAN", false, 3)
local T_Tele = Win:Tab("Teleport","map-pin")
local T_Play = Win:Tab("Player","user")
local T_Sec = Win:Tab("Security","shield")
local T_Set = Win:Tab("Setting","sliders")

local TeleP=T_Tele:Page("Teleport","map-pin")
local TeleL=TeleP:Section("📍 Teleport","Left")
local TeleR=TeleP:Section("👥 Bring","Right")

TeleL:Button("🏠 Spawn","Ke spawn",function()
    local r=getRoot()
    if r then r.CFrame=CFrame.new(0,50,0); notify("TP","Spawn",1) end
end)

TeleL:Button("📍 Save Pos","Save position",function()
    local root=getRoot()
    if root then
        Respawn.savedPosition=root.CFrame
        local p=root.Position
        notify("Saved",string.format("X=%.0f Y=%.0f Z=%.0f",p.X,p.Y,p.Z),2)
    end
end)

TeleR:Button("Pull P1","Bring Player1",function()
    local p=Players:FindFirstChild("Player1")
    if p then bringPlayer(p) end
end)

TeleR:Paragraph("Click to pull player to you")

local PlayP=T_Play:Page("Player","user")
local PlayL=PlayP:Section("⚡ Speed","Left")
local PlayR=PlayP:Section("🚀 Fly","Right")

PlayL:Slider("Speed","ws",16,500,16,function(v)
    local h=getHum()
    if h then h.WalkSpeed=v end
end,"16")

PlayL:Slider("Jump","jp",50,500,50,function(v)
    local h=getHum()
    if h then h.JumpPower=v; h.UseJumpPower=true end
end,"50")

PlayL:Toggle("Inf Jump","ij",false,"Hold space",function(v)
    setInfJump(v)
    notify("Inf Jump",v and "ON" or "OFF",1)
end)

PlayL:Toggle("NoClip","nc",false,"Walk thru walls",function(v)
    setNoclip(v)
    notify("NoClip",v and "ON" or "OFF",1)
end)

PlayR:Toggle("Fly","fly",false,"WASD+Space/Q",function(v)
    if v then startFly() else stopFly() end
    notify("Fly",v and "ON" or "OFF",1)
end)

PlayR:Slider("Fly Speed","fs",10,300,60,function(v)
    Move.flySpeed=v
end,"Speed")

PlayR:Toggle("ESP","esp",false,"See players",function(v)
    ESPPl.active=v
    if v then startESPPlayer() else stopESPPlayer() end
    notify("ESP",v and "ON" or "OFF",1)
end)

local SecP=T_Sec:Page("Security","shield")
local SecL=SecP:Section("🛡 Protection","Left")

SecL:Toggle("Anti AFK","antiAfk",false,"Prevent kick",function(v)
    if v then
        if afkConn then afkConn:Disconnect() end
        -- VirtualUser disabled untuk Delta compatibility
        afkConn=RunService.Heartbeat:Connect(function()
            -- Simulate mouse move
            local cam = Workspace.CurrentCamera
            cam.CFrame = cam.CFrame * CFrame.Angles(0,0.001,0)
        end)
    else
        if afkConn then afkConn:Disconnect(); afkConn=nil end
    end
    notify("Anti AFK",v and "ON" or "OFF",1)
end)

SecL:Toggle("Anti Kick","antiKick",false,"Lock HP >15%",function(v)
    if v then
        if antiKickConn then antiKickConn:Disconnect() end
        antiKickConn=RunService.Heartbeat:Connect(function()
            local h=getHum()
            if h and h.Health>0 and h.Health<h.MaxHealth*0.15 then h.Health=h.MaxHealth end
        end)
    else
        if antiKickConn then antiKickConn:Disconnect(); antiKickConn=nil end
    end
    notify("Anti Kick",v and "ON" or "OFF",1)
end)

SecL:Button("⚡ Respawn","Die & TP back",function()
    task.spawn(doRespawn)
end)

SecL:Button("🔄 Rejoin","Rejoin server",function()
    notify("Rejoin","...",1)
    task.wait(1)
    TpService:Teleport(game.PlaceId,LP)
end)

local T_Set=T_Set:Tab("Setting","sliders")
local SetP=T_Set:Page("Setting","settings")
local SetL=SetP:Section("Log","Left")

SetL:Button("Logs","Show recent logs",function()
    notify("Clean Version","Fishing removed - Stable!",3)
end)

SetL:Button("Clear","Clear cache",function()
    notify("Ready","XKID v5.26 CLEAN Loaded!",4)
end)

notify("✅ XKID v5.26 CLEAN Ready","No Fishing - Delta Compatible",4)
Library:Notification("XKID CLEAN","Teleport·Player·Security",6)

print("[XKID CLEAN] Loaded successfully!")