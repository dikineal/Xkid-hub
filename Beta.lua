-- XKID HUB LITE + UTILITY (MERGED FINAL)

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

-- ================= STATE =================
local State = {
    speed = 16,
    jump = 50,
    noclip = false,
    infJump = false,
    fly = false,
    flySpeed = 70,
    esp = false,
    antiAFK = false
}

-- ================= WINDOW =================
local Win=Library:Window("XKID HUB","sprout","Lite",false)
Win:TabSection("MAIN")

local T_TP  =Win:Tab("Teleport","map-pin")
local T_Pl  =Win:Tab("Player","user")
local T_Sec =Win:Tab("Security","shield")
local T_Set =Win:Tab("Setting","settings")

-- ================= TELEPORT =================
local TP=T_TP:Page("Teleport","map-pin")
local TPL=TP:Section("👥 Player","Left")
local TPR=TP:Section("📍 Lokasi","Right")

for _,p in pairs(Players:GetPlayers()) do
    if p~=LP then
        TPL:Button("🚀 "..p.Name,"TP",function()
            local root=getRoot()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                root.CFrame=p.Character.HumanoidRootPart.CFrame
                notify("TP","→ "..p.Name,2)
            end
        end)
    end
end

local SavedLoc={nil,nil,nil,nil,nil}
for i=1,5 do
    local idx=i
    TPR:Button("💾 Save "..idx,"Simpan posisi",function()
        local r=getRoot()
        if r then SavedLoc[idx]=r.CFrame notify("Saved","Slot "..idx,2) end
    end)
    TPR:Button("📍 Load "..idx,"Teleport posisi",function()
        if SavedLoc[idx] then
            local r=getRoot()
            if r then r.CFrame=SavedLoc[idx] end
        end
    end)
end

TPR:Button("📌 Posisi Saya","Cek koordinat",function()
    local r=getRoot()
    if r then
        local p=r.Position
        notify("Posisi",string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z),5)
    end
end)

-- ================= PLAYER =================
local PP=T_Pl:Page("Player","user")
local PL=PP:Section("⚡ Movement","Left")
local PR=PP:Section("🔥 Utility","Right")

RunService.RenderStepped:Connect(function()
    local h=getHum()
    if h and not h.PlatformStand then
        h.WalkSpeed=State.speed
        h.JumpPower=State.jump
    end
end)

PL:Slider("Speed","spd",16,200,16,function(v) State.speed=v end)
PL:Slider("Jump","jmp",50,200,50,function(v) State.jump=v end)

UIS.JumpRequest:Connect(function()
    if State.infJump then
        local h=getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

PL:Toggle("Infinite Jump","ij",false,function(v) State.infJump=v end)

RunService.Stepped:Connect(function()
    if State.noclip and LP.Character then
        for _,v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide=false end
        end
    end
end)

PL:Toggle("NoClip","nc",false,function(v) State.noclip=v end)

-- ================= FLY =================
local flyConn, flyBV, flyBG, flying

local function startFly()
    if flying then return end
    local root=getRoot()
    local hum=getHum()
    if not root or not hum then return end

    flying=true
    hum.PlatformStand=true

    flyBV=Instance.new("BodyVelocity",root)
    flyBV.MaxForce=Vector3.new(1e6,1e6,1e6)

    flyBG=Instance.new("BodyGyro",root)
    flyBG.MaxTorque=Vector3.new(1e6,1e6,1e6)
    flyBG.P=1e5

    flyConn=RunService.RenderStepped:Connect(function()
        if not flying then return end

        local cam=Workspace.CurrentCamera
        local dir=Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=cam.CFrame.RightVector end

        if dir.Magnitude>0 then
            flyBV.Velocity=dir.Unit*State.flySpeed
        else
            flyBV.Velocity=Vector3.new(0,0.1,0)
        end

        flyBG.CFrame=cam.CFrame
    end)
end

local function stopFly()
    flying=false
    if flyConn then flyConn:Disconnect() flyConn=nil end
    if flyBV then flyBV:Destroy() flyBV=nil end
    if flyBG then flyBG:Destroy() flyBG=nil end
    local h=getHum()
    if h then h.PlatformStand=false end
end

PR:Toggle("Fly","fly",false,function(v)
    State.fly=v
    if v then startFly() else stopFly() end
end)

PR:Slider("Fly Speed","fspd",20,150,70,function(v) State.flySpeed=v end)

-- ================= ESP =================
RunService.Heartbeat:Connect(function()
    if not State.esp then return end
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP and p.Character and p.Character:FindFirstChild("Head") then
            if not p.Character.Head:FindFirstChild("XKID_ESP") then
                local bill=Instance.new("BillboardGui",p.Character.Head)
                bill.Name="XKID_ESP"
                bill.Size=UDim2.new(0,100,0,20)
                bill.AlwaysOnTop=true

                local txt=Instance.new("TextLabel",bill)
                txt.Size=UDim2.new(1,0,1,0)
                txt.BackgroundTransparency=1
                txt.TextColor3=Color3.new(1,1,0)
                txt.Text=p.Name
            end
        end
    end
end)

PR:Toggle("ESP Player","esp",false,function(v) State.esp=v end)

-- ================= SECURITY =================
local Sec=T_Sec:Page("Security","shield")
local SL=Sec:Section("🛡 Protection","Left")

local afk
SL:Toggle("Anti AFK","afk",false,function(v)
    State.antiAFK=v
    if v then
        afk=LP.Idled:Connect(function()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if afk then afk:Disconnect() end
    end
end)

SL:Button("🔄 Rejoin","Reconnect",function()
    TpService:Teleport(game.PlaceId,LP)
end)

SL:Button("⚡ Respawn","Fast Respawn",function()
    local r=getRoot()
    local h=getHum()
    if r and h then
        local cf=r.CFrame
        h.Health=0
        LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame=cf
    end
end)

-- ================= SETTING =================
local Set=T_Set:Page("Setting","settings")
local ST=Set:Section("Info","Left")

ST:Button("📌 Posisi Saya","Cek posisi",function()
    local r=getRoot()
    if r then
        local p=r.Position
        notify("Posisi",p.X..","..p.Y..","..p.Z,5)
    end
end)

notify("XKID HUB","Loaded + Utility Aktif",5)