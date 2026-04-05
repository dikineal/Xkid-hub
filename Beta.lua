-- XKID HUB (FINAL - MOVEMENT & TELEPORT UPGRADE)

local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Vovabro46/trash/main/Aurora.lua?cache="..tostring(os.time())
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer

local function getChar() return LP.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function notify(t,b,d)
    pcall(function() Library:Notification(t,b,d or 3) end)
end

-- ================= WINDOW =================
local Win=Library:Window("XKID HUB","sprout","vFinal",false)
Win:TabSection("MAIN")

local T_TP  =Win:Tab("Teleport","map-pin")
local T_Pl  =Win:Tab("Player","user")
local T_Sec =Win:Tab("Security","shield")
local T_Set =Win:Tab("Setting","settings")

-- =========================================================
-- 🧠 MOVEMENT SYSTEM (FULL UPGRADE DARI LU)
-- =========================================================

local Move={speed=16,flySpeed=60,noclip=false,noclipConn=nil,jumpConn=nil}
local flyFlying=false; local flyConn=nil; local flyBV=nil; local flyBG=nil

RunService.RenderStepped:Connect(function()
    if flyFlying then return end
    local h=getHum(); if h then h.WalkSpeed=Move.speed end
end)

local function setNoclip(v)
    Move.noclip=v
    if v then
        if Move.noclipConn then Move.noclipConn:Disconnect() end
        Move.noclipConn=RunService.Stepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end)
    else
        if Move.noclipConn then Move.noclipConn:Disconnect(); Move.noclipConn=nil end
        local c=getChar()
        if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
    end
end

local function setInfJump(v)
    if v then
        if Move.jumpConn then Move.jumpConn:Disconnect() end
        Move.jumpConn=UIS.JumpRequest:Connect(function()
            local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if Move.jumpConn then Move.jumpConn:Disconnect(); Move.jumpConn=nil end
    end
end

-- MOBILE + PC CONTROL
local ControlModule=nil
pcall(function()
    ControlModule=require(LP:WaitForChild("PlayerScripts")
        :WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
end)

local function getMoveVector()
    if ControlModule then
        local ok,result=pcall(function() return ControlModule:GetMoveVector() end)
        if ok and result then return result end
    end
    return Vector3.new(
        (UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0)-(UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
        0,
        (UIS:IsKeyDown(Enum.KeyCode.W) and -1 or 0)+(UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0))
end

local function startFly()
    if flyFlying then return end
    local root=getRoot(); if not root then return end
    local hum=getHum(); if not hum then return end
    flyFlying=true; hum.PlatformStand=true

    flyBV=Instance.new("BodyVelocity",root)
    flyBV.MaxForce=Vector3.new(1e6,1e6,1e6)

    flyBG=Instance.new("BodyGyro",root)
    flyBG.MaxTorque=Vector3.new(1e6,1e6,1e6); flyBG.P=1e5; flyBG.D=1e3

    flyConn=RunService.RenderStepped:Connect(function(dt)
        local r2=getRoot(); if not r2 then return end
        local h2=getHum(); if not h2 then return end

        local cam=Workspace.CurrentCamera; local cf=cam.CFrame
        h2.PlatformStand=true

        local md=getMoveVector()
        local look=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
        local right=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z)

        if look.Magnitude>0 then look=look.Unit end
        if right.Magnitude>0 then right=right.Unit end

        local move=right*md.X+look*(-md.Z)

        local pitch=cf.LookVector.Y
        local vVel=pitch*Move.flySpeed

        flyBV.Velocity=Vector3.new(move.X*Move.flySpeed,vVel,move.Z*Move.flySpeed)
        flyBG.CFrame=cf
    end)
end

local function stopFly()
    flyFlying=false
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
    local hum=getHum()
    if hum then hum.PlatformStand=false; hum.WalkSpeed=Move.speed end
end

-- =========================================================
-- 🚀 TELEPORT SYSTEM (ADVANCED)
-- =========================================================

local function inferPlayer(prefix)
    if not prefix or prefix=="" then return nil end
    local best,bestScore=nil,math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP then
            local score=math.huge
            if p.Name:lower():sub(1,#prefix)==prefix:lower() then score=#p.Name-#prefix end
            if score<bestScore then best=p bestScore=score end
        end
    end
    return best
end

local function tpToPlayer(prefix)
    local p=inferPlayer(prefix)
    if not p then notify("TP","Player tidak ditemukan",2); return end
    local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    local root=getRoot()
    if hrp and root then root.CFrame=hrp.CFrame*CFrame.new(0,0,3) end
end

-- =========================================================
-- 🧩 UI PLAYER (CONNECT KE SYSTEM LU)
-- =========================================================

local PP=T_Pl:Page("Player","user")
local PL=PP:Section("Movement","Left")
local PR=PP:Section("Utility","Right")

PL:Slider("Speed","spd",16,200,16,function(v) Move.speed=v end)
PL:Toggle("NoClip","nc",false,function(v) setNoclip(v) end)
PL:Toggle("Infinite Jump","ij",false,function(v) setInfJump(v) end)

PR:Toggle("Fly","fly",false,function(v)
    if v then startFly() else stopFly() end
end)

PR:Slider("Fly Speed","fspd",20,150,60,function(v) Move.flySpeed=v end)

-- =========================================================
-- 🧩 UI TELEPORT
-- =========================================================

local TP=T_TP:Page("Teleport","map-pin")
local TL=TP:Section("Player","Left")

local input=""
TL:TextBox("Nama Player","tp","",function(v) input=v end)
TL:Button("Teleport","TP",function() tpToPlayer(input) end)

-- =========================================================
-- 🛡 SECURITY
-- =========================================================

local Sec=T_Sec:Page("Security","shield")
local SL=Sec:Section("Protection","Left")

SL:Toggle("Anti AFK","afk",false,function(v)
    if v then
        LP.Idled:Connect(function()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

SL:Button("Rejoin","Reconnect",function()
    TpService:Teleport(game.PlaceId,LP)
end)

-- =========================================================
-- ⚙️ SETTING
-- =========================================================

local Set=T_Set:Page("Setting","settings")
local ST=Set:Section("Info","Left")

ST:Button("Cek Posisi","",function()
    local r=getRoot()
    if r then notify("Posisi",tostring(r.Position),5) end
end)

notify("XKID HUB","Movement & TP upgraded",5)