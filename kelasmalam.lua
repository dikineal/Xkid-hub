--[[
╔═══════════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.26  🌟              ║
║                  Aurora UI  ·  Pro Edition               ║
╠═══════════════════════════════════════════════════════════════╣
║  Teleport  ·  Player  ·  Security  ·  Setting                ║
║  [MODIFIED] Hapus Tab Farming & Shop, Tambah Bring Player    ║
╚═══════════════════════════════════════════════════════════════╝
]]

Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService   = game:GetService("TeleportService")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")
local LP          = Players.LocalPlayer

local function getChar() return LP.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function notify(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
    print(string.format("[XKID] %s | %s", t, tostring(b)))
end

local lastCFrame
RunService.Heartbeat:Connect(function()
    local r = getRoot(); if r then lastCFrame = r.CFrame end
end)

local function getBridge()
    local bn = RS:FindFirstChild("BridgeNet2")
    return bn and bn:FindFirstChild("dataRemoteEvent")
end
local function getFishEv(name)
    local fr = RS:FindFirstChild("FishRemotes")
    return fr and fr:FindFirstChild(name)
end

local LOG_MAX = 30
local logLines = {}
local function xlog(tag, msg, isError)
    local entry = string.format("[%s][%s] %s", os.date("%H:%M:%S"), tag, msg)
    table.insert(logLines, 1, entry)
    if #logLines > LOG_MAX then table.remove(logLines) end
    print(entry)
    if isError then
        pcall(function() Library:Notification("❌ "..tag, msg:sub(1,80), 5) end)
    end
end

local Fish = {
    autoOn = false,
    fishTask = nil,
    waitDelay = 2,
    rodEquipped = false,
    totalFished = 0,
    instantDelay = 2,
}

local Move = {
    flying = false,
    flySpeed = 60,
    speed = 16,
}

local Respawn = {
    savedPosition = nil,
}

local ESPPl = {active = false, uis = {}, conn = nil}

local flyConn, noclipConn, infJumpConn, afkConn, antiKickConn

local function equipRod()
    local bp = LP:FindFirstChildOfClass("Backpack")
    if not bp then return false end
    local rod = bp:FindFirstChild("AdvanceRod") or bp:FindFirstChild("Rod")
    if not rod then
        xlog("Fishing","Rod tidak ada",true)
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
    if rod then pcall(function() rod.Parent = LP.Backpack end) end
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
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
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
    for _, label in pairs(ESPPl.uis) do
        pcall(function() label:Destroy() end)
    end
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

local Win = Library:CreateWindow("XKID HUB v5.26", false, 3)
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

TeleL:Button("👤 P1","TP Player 1",function()
    local p=Players:FindFirstChild("Player1")
    if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        local r=getRoot()
        if r then r.CFrame=p.Character.HumanoidRootPart.CFrame+Vector3.new(0,3,0); notify("TP","P1",1) end
    end
end)

TeleL:Paragraph("Info","TP Spawn or Players")

TeleR:Label("Bring Player")
TeleR:Button("Pull P1","Bring Player1",function()
    local p=Players:FindFirstChild("Player1")
    if p then bringPlayer(p) end
end)
TeleR:Paragraph("Info","Click to pull player\nto your position")

local PlayP=T_Play:Page("Player","user")
local PlayL=PlayP:Section("⚡ Speed","Left")
local PlayR=PlayP:Section("🚀 Fly","Right")

PlayL:Slider("Speed","ws",16,500,16,function(v)
    if not Move.flying then
        local h=getHum()
        if h then h.WalkSpeed=v end
    end
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
local SecR=SecP:Section("Info","Right")

local afkConn=nil
SecL:Toggle("Anti AFK","antiAfk",false,"Prevent kick",function(v)
    if v then
        if afkConn then afkConn:Disconnect() end
        afkConn=LP.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if afkConn then afkConn:Disconnect(); afkConn=nil end
    end
    notify("Anti AFK",v and "ON" or "OFF",1)
end)

local antiKickConn=nil
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

SecL:Button("📍 Save","Save position",function()
    local root=getRoot()
    if root then
        Respawn.savedPosition=root.CFrame
        local p=root.Position
        notify("Saved",string.format("X=%.0f Y=%.0f Z=%.0f",p.X,p.Y,p.Z),2)
    end
end)

SecL:Button("🔄 Rejoin","Rejoin server",function()
    notify("Rejoin","...",1)
    task.wait(1)
    TpService:Teleport(game.PlaceId,LP)
end)

SecR:Paragraph("Anti AFK","Prevent idle kick")
SecR:Paragraph("Anti Kick","HP <15% = heal")
SecR:Paragraph("Respawn","Save & restore pos")

local SetP=T_Set:Page("Setting","settings")
local SetL=SetP:Section("🎣 Fishing","Left")
local SetR=SetP:Section("Log","Right")

SetL:Label("Settings")
SetL:Slider("Hold","hold",1,10,2,function(v)
    Fish.instantDelay=v
end,"Cast hold time")

SetL:Slider("Timeout","to",10,180,120,function(v)
    Fish.waitDelay=v
end,"Wait for minigame")

SetL:Label("Auto Fish")
SetL:Toggle("Auto","af",false,"Cast loop",function(v)
    Fish.autoOn=v
    if v then
        task.spawn(function()
            if not Fish.rodEquipped then
                if not equipRod() then Fish.autoOn=false; return end
                task.wait(0.3)
            end
            notify("Fish","ON",2)
            local attempts=0
            Fish.fishTask=task.spawn(function()
                while Fish.autoOn do
                    local ok=pcall(castOnce)
                    if ok then
                        attempts=0
                    else
                        attempts=attempts+1
                        if attempts>=3 then
                            notify("Fish","Stop",2)
                            Fish.autoOn=false; break
                        end
                        task.wait(3)
                    end
                end
            end)
        end)
    else
        if Fish.fishTask then
            pcall(function() task.cancel(Fish.fishTask) end)
            Fish.fishTask=nil
        end
        notify("Fish","OFF | Total: "..Fish.totalFished,1)
    end
end)

SetL:Button("Cast 1x","Manual cast",function()
    task.spawn(function()
        if not Fish.rodEquipped then
            if not equipRod() then return end
            task.wait(0.5)
        end
        castOnce()
        notify("Cast","Done! "..Fish.totalFished,1)
    end)
end)

SetL:Button("Equip","Get rod",function()
    if equipRod() then notify("Rod","OK",1) end
end)

SetL:Button("Unequip","Return rod",function()
    unequipRod()
    notify("Rod","OK",1)
end)

SetR:Button("Logs 5","Recent logs",function()
    if #logLines==0 then notify("Log","Empty",1); return end
    local txt=""
    for i=1,math.min(5,#logLines) do txt=txt..logLines[i].."\n" end
    notify("Logs",txt,10)
end)

SetR:Button("Logs 10","All logs",function()
    if #logLines==0 then notify("Log","Empty",1); return end
    local txt=""
    for i=1,math.min(10,#logLines) do txt=txt..logLines[i].."\n" end
    notify("All",txt,12)
end)

SetR:Button("Clear","Clear logs",function()
    logLines={}
    notify("Log","Cleared",1)
end)

SetR:Paragraph("v5.26","Teleport+Bring\nPlayer+Security\nFishing")

notify("✅ XKID v5.26 Ready","No Farming/Shop - Bring Player Added",4)
Library:Notification("XKID HUB v5.26","Teleport·Player·Security·Setting",6)
Library:ConfigSystem(Win)
print("[XKID] v5.26 loaded")
