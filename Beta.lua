-- XKID HUB CLEAN VERSION (NO FARMING / NO FISHING / NO LIKE)

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

-- ================= CORE =================

local function getChar() return LP.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end

local function notify(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
    print("[XKID]", t, b)
end

-- ================= LOG =================

local logLines = {}
local function xlog(tag, msg)
    local entry = "["..tag.."] "..msg
    table.insert(logLines, 1, entry)
    if #logLines > 30 then table.remove(logLines) end
    print(entry)
end

-- ================= ESP PLAYER =================

local ESPPl={active=false,data={},conn=nil}

local function _mkPlBill(p)
    if p==LP or ESPPl.data[p] then return end
    if not p.Character then return end

    local head=p.Character:FindFirstChild("Head")
    if not head then return end

    local bill=Instance.new("BillboardGui")
    bill.Size=UDim2.new(0,100,0,24)
    bill.StudsOffset=Vector3.new(0,2.5,0)
    bill.AlwaysOnTop=true
    bill.Adornee=head
    bill.Parent=head

    local lbl=Instance.new("TextLabel",bill)
    lbl.Size=UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency=1
    lbl.TextColor3=Color3.fromRGB(255,230,80)
    lbl.TextScaled=true
    lbl.Font=Enum.Font.GothamBold
    lbl.Text=p.Name

    ESPPl.data[p]={bill=bill,lbl=lbl}
end

local function startESPPlayer()
    for _,p in pairs(Players:GetPlayers()) do _mkPlBill(p) end

    ESPPl.conn=RunService.Heartbeat:Connect(function()
        local myR=getRoot()
        for p,d in pairs(ESPPl.data) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and myR then
                local dist=math.floor((p.Character.HumanoidRootPart.Position-myR.Position).Magnitude)
                d.lbl.Text=p.Name.." ["..dist.."m]"
            end
        end
    end)
end

local function stopESPPlayer()
    if ESPPl.conn then ESPPl.conn:Disconnect() end
    for _,d in pairs(ESPPl.data) do
        pcall(function() d.bill:Destroy() end)
    end
    ESPPl.data={}
end

-- ================= MOVEMENT =================

local Move={speed=16,flySpeed=60}

RunService.RenderStepped:Connect(function()
    local h=getHum()
    if h then h.WalkSpeed=Move.speed end
end)

-- ================= TELEPORT =================

local function tpToPlayer(name)
    for _,p in pairs(Players:GetPlayers()) do
        if p.Name:lower():find(name:lower()) then
            local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local root=getRoot()
            if hrp and root then
                root.CFrame=hrp.CFrame
                notify("TP",p.Name)
            end
        end
    end
end

-- ================= SECURITY =================

local afkConn=nil

local function setAntiAFK(v)
    if v then
        afkConn=LP.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if afkConn then afkConn:Disconnect() end
    end
end

-- ================= UI =================

local Win=Library:Window("XKID HUB CLEAN","clean","v1",false)

Win:TabSection("MAIN")

local T_TP  =Win:Tab("Teleport","map-pin")
local T_Pl  =Win:Tab("Player","user")
local T_Sec =Win:Tab("Security","shield")

-- PLAYER TAB
local PP=T_Pl:Page("Player","user")
local PL=PP:Section("Movement","Left")

PL:Slider("Speed","ws",16,200,16,function(v)
    Move.speed=v
end)

PL:Toggle("ESP Player","esp",false,function(v)
    ESPPl.active=v
    if v then startESPPlayer() else stopESPPlayer() end
end)

-- TELEPORT TAB
local TP=T_TP:Page("Teleport","map-pin")
local TPL=TP:Section("Player","Left")

TPL:TextBox("Nama","tpInput","",function(v)
    tpToPlayer(v)
end)

-- SECURITY TAB
local SP=T_Sec:Page("Security","shield")
local SL=SP:Section("Security","Left")

SL:Toggle("Anti AFK","afk",false,function(v)
    setAntiAFK(v)
end)

-- ================= INIT =================

notify("XKID CLEAN","Loaded tanpa farming/fishing/like",5)