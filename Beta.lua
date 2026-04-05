--[[
╔═══════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.26  🌟              ║
║                  Aurora UI  ·  Pro Edition               ║
╠═══════════════════════════════════════════════════════════╣
║  Teleport  ·  Player  ·  Security  ·  Setting                ║
║  [UPDATE] Custom ESP, Smart TP, Invisible, Bring Player  ║
╚═══════════════════════════════════════════════════════════╝
]]

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService   = game:GetService("TeleportService")
local Workspace   = game:GetService("Workspace")
local LP          = Players.LocalPlayer

-- Helper Functions
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function notify(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
end

-- State Management
local lastCFrame
local Move = {speed = 16, flySpeed = 60, noclip = false, noclipConn = nil, jumpConn = nil}
local flyFlying = false; local flyConn = nil; local flyBV = nil; local flyBG = nil
local Respawn = {savedPosition = nil, busy = false}
local InvisConn = nil

RunService.Heartbeat:Connect(function()
    local r = getRoot()
    if r then 
        lastCFrame = r.CFrame 
        Respawn.savedPosition = r.CFrame
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │                   CUSTOM ESP PLAYER                     │
-- └─────────────────────────────────────────────────────────┘
local ESPPl={active=false,data={},conn=nil}
local function _mkPlBill(p)
    if p==LP or ESPPl.data[p] then return end
    if not p.Character then return end
    local head=p.Character:FindFirstChild("Head"); if not head then return end
    local bill=Instance.new("BillboardGui")
    bill.Name="XKID_PESP"; bill.Size=UDim2.new(0,100,0,24)
    bill.StudsOffset=Vector3.new(0,2.5,0); bill.AlwaysOnTop=true
    bill.Adornee=head; bill.Parent=head
    local bg=Instance.new("Frame",bill)
    bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency=0.45; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,4)
    local lbl=Instance.new("TextLabel",bg)
    lbl.Size=UDim2.new(1,-4,1,-4); lbl.Position=UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.fromRGB(255,230,80)
    lbl.TextStrokeColor3=Color3.fromRGB(0,0,0); lbl.TextStrokeTransparency=0.35
    lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold; lbl.Text=p.Name
    ESPPl.data[p]={bill=bill,lbl=lbl}
end
local function _rmPlBill(p)
    if ESPPl.data[p] then pcall(function() ESPPl.data[p].bill:Destroy() end); ESPPl.data[p]=nil end
end
local function startESPPlayer()
    for _,p in pairs(Players:GetPlayers()) do _mkPlBill(p) end
    ESPPl.conn=RunService.Heartbeat:Connect(function()
        if not ESPPl.active then return end
        local myR=getRoot()
        for p,d in pairs(ESPPl.data) do
            if not d.bill or not d.bill.Parent then ESPPl.data[p]=nil
            else
                if myR and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist=math.floor((p.Character.HumanoidRootPart.Position-myR.Position).Magnitude)
                    d.lbl.Text=p.Name.."\n"..dist.."m"
                else d.lbl.Text=p.Name end
            end
        end
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character and not ESPPl.data[p] then _mkPlBill(p) end
        end
    end)
end
local function stopESPPlayer()
    if ESPPl.conn then ESPPl.conn:Disconnect(); ESPPl.conn=nil end
    for p in pairs(ESPPl.data) do _rmPlBill(p) end; ESPPl.data={}
end
Players.PlayerRemoving:Connect(_rmPlBill)
for _,p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        task.wait(0.5); if ESPPl.active then _rmPlBill(p); _mkPlBill(p) end
    end)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   SMART TELEPORT                        │
-- └─────────────────────────────────────────────────────────┘
local SavedLoc={nil,nil,nil,nil,nil}

local function inferPlayer(prefix)
    if not prefix or prefix=="" then return nil end
    local best,bestScore=nil,math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP then
            local score=math.huge
            if p.Name:lower():sub(1,#prefix)==prefix:lower() then score=#p.Name-#prefix
            elseif p.DisplayName:lower():sub(1,#prefix)==prefix:lower() then score=(#p.DisplayName-#prefix)+0.5 end
            if score<bestScore then best=p; bestScore=score end
        end
    end
    return best
end

local function tpToPlayer(prefix)
    if not prefix or prefix=="" then notify("TP","Ketik nama dulu!",2); return end
    local p=inferPlayer(prefix)
    if not p then notify("TP","'"..prefix.."' tidak ditemukan",3); return end
    if not p.Character then notify("TP",p.Name.." tidak ada karakter",2); return end
    local hrp=p.Character:FindFirstChild("HumanoidRootPart"); local root=getRoot()
    if hrp and root then root.CFrame=hrp.CFrame*CFrame.new(0,0,3); notify("TP","→ "..p.Name,2) end
end

local function bringPlayer(prefix)
    if not prefix or prefix=="" then notify("Bring","Ketik nama dulu!",2); return end
    local p=inferPlayer(prefix)
    if not p then notify("Bring","'"..prefix.."' tidak ditemukan",3); return end
    if not p.Character then notify("Bring",p.Name.." tidak ada karakter",2); return end
    local hrp=p.Character:FindFirstChild("HumanoidRootPart"); local root=getRoot()
    if hrp and root then 
        hrp.CFrame = root.CFrame * CFrame.new(0,0,-3)
        notify("Bring","🧲 Menarik "..p.Name,2) 
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   PLAYER UTILITIES                      │
-- └─────────────────────────────────────────────────────────┘
local function setNoclip(v)
    Move.noclip = v
    if v then
        if Move.noclipConn then Move.noclipConn:Disconnect() end
        Move.noclipConn = RunService.Stepped:Connect(function()
            local c = getChar(); if not c then return end
            for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
        end)
    else
        if Move.noclipConn then Move.noclipConn:Disconnect(); Move.noclipConn = nil end
        local c = getChar()
        if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    end
end

local function setInfJump(v)
    if v then
        if Move.jumpConn then Move.jumpConn:Disconnect() end
        Move.jumpConn = UIS.JumpRequest:Connect(function()
            local h = getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else 
        if Move.jumpConn then Move.jumpConn:Disconnect(); Move.jumpConn = nil end 
    end
end

local function setInvisible(v)
    if v then
        InvisConn = RunService.Stepped:Connect(function()
            local c = getChar()
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency = 1 end
                end
            end
        end)
        notify("Invisible", "ON (Visual)", 2)
    else
        if InvisConn then InvisConn:Disconnect(); InvisConn = nil end
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.Transparency = 0
                elseif p:IsA("Decal") then
                    p.Transparency = 0
                end
            end
        end
        notify("Invisible", "OFF", 2)
    end
end

local ControlModule = nil
pcall(function() ControlModule = require(LP:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule")) end)
local function getMoveVector()
    if ControlModule then
        local ok, result = pcall(function() return ControlModule:GetMoveVector() end)
        if ok and result then return result end
    end
    return Vector3.new((UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0), 0, (UIS:IsKeyDown(Enum.KeyCode.W) and -1 or 0) + (UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0))
end

local function startFly()
    if flyFlying then return end
    local root = getRoot(); local hum = getHum(); if not root or not hum then return end
    flyFlying = true; hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity", root); flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6); flyBV.Velocity = Vector3.zero
    flyBG = Instance.new("BodyGyro", root); flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6); flyBG.P = 1e5; flyBG.D = 1e3
    flyConn = RunService.RenderStepped:Connect(function()
        local r2 = getRoot(); local h2 = getHum(); if not r2 or not h2 then return end
        local cam = Workspace.CurrentCamera; local cf = cam.CFrame
        h2.PlatformStand = true; h2:ChangeState(Enum.HumanoidStateType.Physics)
        local md = getMoveVector()
        local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z); if look.Magnitude > 0 then look = look.Unit end
        local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z); if right.Magnitude > 0 then right = right.Unit end
        local move = right * md.X + look * (-md.Z)
        local pitch = cf.LookVector.Y; local vVel = 0
        if math.abs(pitch) > 0.25 then vVel = math.sign(pitch) * Move.flySpeed * 0.6 end
        flyBV.Velocity = Vector3.new(move.X * Move.flySpeed, vVel, move.Z * Move.flySpeed)
        flyBG.CFrame = CFrame.lookAt(r2.Position, r2.Position + Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z))
    end)
end

local function stopFly()
    flyFlying = false; if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end; if flyBG then flyBG:Destroy(); flyBG = nil end
    local hum = getHum(); if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.Running) end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   GUI INITIALIZATION                    │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB", "shield", "v5.26", false)
local T_TP = Win:Tab("Teleport", "map-pin")
local T_Pl = Win:Tab("Player", "user")
local T_Sec = Win:Tab("Security", "shield")

-- TAB TELEPORT
local TP_P = T_TP:Page("Teleport", "map-pin")
local TPR = TP_P:Section("💾 Save & Load", "Left")
local TPL = TP_P:Section("🎯 Target Player", "Right")

local tpInput = ""
TPL:TextBox("Nama / Prefix", "tpInp", "", function(v) tpInput = v end, "Ketik awalan nama")
TPL:Button("🔍 TP ke Player", "Teleportasi", function() tpToPlayer(tpInput) end)
TPL:Button("🧲 Bring Player", "Tarik ke lokasi kamu", function() bringPlayer(tpInput) end)

for i = 1, 3 do
    TPR:Button("💾 Save Slot " .. i, "Simpan posisi", function() SavedLoc[i] = lastCFrame; notify("Save", "Slot " .. i .. " tersimpan") end)
    TPR:Button("📍 Load Slot " .. i, "Teleport", function() if SavedLoc[i] then getRoot().CFrame = SavedLoc[i]; notify("Load", "TP ke Slot " .. i) end end)
end

-- TAB PLAYER
local PL = T_Pl:Page("Movement", "user"):Section("⚡ Speed & Jump", "Left")
local PR = T_Pl:Page("Movement", "user"):Section("🚀 Visual & Hack", "Right")

PL:Slider("Walk Speed", "ws", 16, 500, 16, function(v) Move.speed = v; getHum().WalkSpeed = v end)
PL:Slider("Jump Power", "jp", 50, 500, 50, function(v) getHum().JumpPower = v; getHum().UseJumpPower = true end)
PL:Toggle("Infinite Jump", "infj", false, "Lompat terus", function(v) setInfJump(v) end)

PR:Toggle("Fly", "fly", false, "Terbang bebas", function(v) if v then startFly() else stopFly() end end)
PR:Toggle("NoClip", "nc", false, "Tembus Dinding", function(v) setNoclip(v) end)
PR:Toggle("Invisible", "invis", false, "Menghilang (Lokal)", function(v) setInvisible(v) end)
PR:Toggle("ESP Player", "esp", false, "Box & Jarak", function(v)
    ESPPl.active = v
    if v then startESPPlayer() else stopESPPlayer() end
end)

-- TAB SECURITY
local SL = T_Sec:Page("Security", "shield"):Section("🛡️ Protection", "Left")
local SR = T_Sec:Page("Security", "shield"):Section("🔄 System", "Right")

SL:Toggle("Anti AFK", "afk", false, "Anti Kick Idle", function(v)
    if v then LP.Idled:Connect(function() VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame) end) end
end)
SL:Button("⚡ Fast Respawn", "Mati & TP balik", function()
    if Respawn.savedPosition then
        local old = Respawn.savedPosition; getHum().Health = 0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = old
        notify("Respawn", "Sukses kembali!")
    end
end)

SR:Button("🔄 Rejoin Server", "Masuk ulang", function()
    notify("Rejoin", "Menyambung ulang...")
    TpService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end)

notify("XKID HUB", "Fitur Custom Loaded!")
