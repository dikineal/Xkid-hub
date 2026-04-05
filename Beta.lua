-- XKID HUB LITE (Teleport + Security + Setting)

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
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

-- SAVE POSITION
local lastCFrame
RunService.Heartbeat:Connect(function()
    local r = getRoot()
    if r then lastCFrame = r.CFrame end
end)

-- WINDOW
local Win=Library:Window("XKID HUB Lite","sprout","Lite",false)
Win:TabSection("MAIN")

local T_TP  =Win:Tab("Teleport","map-pin")
local T_Pl  =Win:Tab("Player","user")
local T_Sec =Win:Tab("Security","shield")
local T_Set =Win:Tab("Setting","settings")

-- ╔════════════════════════════════╗
-- ║        TELEPORT TAB           ║
-- ╚════════════════════════════════╝
local TP=T_TP:Page("Teleport","map-pin")
local TPL=TP:Section("👥 Player","Left")
local TPR=TP:Section("📍 Lokasi","Right")

-- PLAYER TELEPORT
for _,p in pairs(Players:GetPlayers()) do
    if p~=LP then
        TPL:Button("🚀 "..p.Name,"TP ke "..p.Name,function()
            local root=getRoot()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                root.CFrame=p.Character.HumanoidRootPart.CFrame
                notify("TP","→ "..p.Name,2)
            end
        end)
    end
end

-- SAVE / LOAD
local SavedLoc={nil,nil,nil,nil,nil}

for i=1,5 do
    local idx=i
    TPR:Button("💾 Save "..idx,"Simpan posisi",function()
        local cf=lastCFrame
        if cf then SavedLoc[idx]=cf notify("Saved","Slot "..idx,2) end
    end)

    TPR:Button("📍 Load "..idx,"Teleport posisi",function()
        if SavedLoc[idx] then
            local root=getRoot()
            if root then root.CFrame=SavedLoc[idx] end
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

-- ╔════════════════════════════════╗
-- ║          PLAYER TAB           ║
-- ╚════════════════════════════════╝
local PP=T_Pl:Page("Player","user")
local PL=PP:Section("⚡ Movement","Left")
local PR=PP:Section("👁 ESP","Right")

local speed=16
RunService.RenderStepped:Connect(function()
    local h=getHum()
    if h then h.WalkSpeed=speed end
end)

PL:Slider("Speed","spd",16,200,16,function(v)
    speed=v
end)

PL:Toggle("Infinite Jump","infJump",false,function(v)
    if v then
        UIS.JumpRequest:Connect(function()
            local h=getHum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end)

-- ESP
local ESP=false
RunService.Heartbeat:Connect(function()
    if not ESP then return end
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP and p.Character and p.Character:FindFirstChild("Head") then
            if not p.Character.Head:FindFirstChild("ESP") then
                local bill=Instance.new("BillboardGui",p.Character.Head)
                bill.Name="ESP"
                bill.Size=UDim2.new(0,100,0,20)
                bill.AlwaysOnTop=true
                local txt=Instance.new("TextLabel",bill)
                txt.Size=UDim2.new(1,0,1,0)
                txt.Text=p.Name
                txt.BackgroundTransparency=1
                txt.TextColor3=Color3.new(1,1,0)
            end
        end
    end
end)

PR:Toggle("ESP Player","esp",false,function(v)
    ESP=v
end)

-- ╔════════════════════════════════╗
-- ║        SECURITY TAB           ║
-- ╚════════════════════════════════╝
local Sec=T_Sec:Page("Security","shield")
local SL=Sec:Section("🛡 Protection","Left")

local afk
SL:Toggle("Anti AFK","afk",false,function(v)
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

SL:Button("⚡ Respawn","Respawn cepat",function()
    local h=getHum()
    if h then h.Health=0 end
end)

-- ╔════════════════════════════════╗
-- ║        SETTING TAB            ║
-- ╚════════════════════════════════╝
local Set=T_Set:Page("Setting","settings")
local ST=Set:Section("Info","Left")

ST:Button("Info","Status script",function()
    notify("XKID HUB Lite","Running OK",3)
end)

-- INIT
notify("XKID HUB Lite","Loaded!",5)