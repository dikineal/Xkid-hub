--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🌾  I N D O   F A R M E R  v22.0  🌾           ║
  ║      XKID HUB  ✦  Aurora UI                         ║
  ║      Full Cycle · ESP Tanaman · Speed · Fly          ║
  ╚═══════════════════════════════════════════════════════╝

  CHANGELOG v22:
  [1] Auto Farm Full Cycle — tanam > harvest > jual loop
  [2] ESP Tanaman — BillboardGui di setiap tanaman di workspace
  [3] Auto Beli Bibit — otomatis beli saat stok habis
  [4] Speed & Fly — dari v5.1 (BodyVelocity + pitch kamera)
  [5] Anti Kick visual — HP lock + notif
  [6] Anti AFK visual — status bar aktif
  [7] Tab baru: Farm Cycle, ESP, Movement, Protection
]]

-- ════════════════════════════════════════════════
--  LOAD AURORA UI
-- ════════════════════════════════════════════════
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Win = Library:Window(
    "Indo Farmer",
    "sprout",
    "v22.0  |  XKID HUB",
    false
)

-- ════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService   = game:GetService("TeleportService")
local Lighting    = game:GetService("Lighting")
local LP          = Players.LocalPlayer

-- ════════════════════════════════════════════════
--  FLAGS
-- ════════════════════════════════════════════════
_G.ScriptRunning   = true
_G.AutoSell        = false
_G.AutoHarvest     = false
_G.AutoFarmCycle   = false
_G.AutoBeliBibit   = false
_G.ESPTanaman      = false
_G.PenangkalPetir  = false
_G.AntiAFK         = false
_G.AntiKick        = false
_G.AutoConfirm     = false
_G.NotifLevelUp    = true
_G.AutoMandi       = false
_G.FlyOn           = false
_G.NoclipOn        = false

-- ════════════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════════════
local PlayerData      = { Coins=0, Level=1, XP=0, Needed=50 }
local lightningHits   = 0
local levelUpCount    = 0
local totalEarned     = 0
local harvestCount    = 0
local cycleCount      = 0
local SellLoop        = nil
local HarvestLoop     = nil
local FarmCycleLoop   = nil
local AutoBeliLoop    = nil
local AntiKickLoop    = nil
local ESPConns        = {}
local ESPBills        = {}
local selectedBibit   = "Bibit Padi"
local jumlahBeli      = 10
local minStokBibit    = 5
local cycleDelay      = 15
local isPetirActive   = false
local savedPositions  = { nil, nil, nil, nil, nil }
local savedLocations  = {}
local fleePos         = nil
local petirReturnCF   = nil
local godConn         = nil
local antiAFKConn     = nil
local noclipConn      = nil
local flyBV           = nil
local flyBG           = nil
local flyConn         = nil
local flySpeed        = 60
local PITCH_UP        =  0.3
local PITCH_DOWN      = -0.3
local curWS           = 16
local curJP           = 50

-- ════════════════════════════════════════════════
--  DATA
-- ════════════════════════════════════════════════
local CROP_NAMES = {
    { name="Padi",       idx=1 },
    { name="Jagung",     idx=2 },
    { name="Tomat",      idx=3 },
    { name="Terong",     idx=4 },
    { name="Strawberry", idx=5 },
    { name="Sawit",      idx=6 },
    { name="Durian",     idx=7 },
}

local BIBIT_LIST = {
    { name="Bibit Padi",       price=5,    minLv=1,   icon="🌾", crop="Padi"       },
    { name="Bibit Jagung",     price=15,   minLv=20,  icon="🌽", crop="Jagung"     },
    { name="Bibit Tomat",      price=25,   minLv=40,  icon="🍅", crop="Tomat"      },
    { name="Bibit Terong",     price=40,   minLv=60,  icon="🍆", crop="Terong"     },
    { name="Bibit Strawberry", price=60,   minLv=80,  icon="🍓", crop="Strawberry" },
    { name="Bibit Sawit",      price=1000, minLv=80,  icon="🌴", crop="Sawit"      },
    { name="Bibit Durian",     price=2000, minLv=120, icon="🍈", crop="Durian"     },
}
local bibitNames = {}
for _, b in ipairs(BIBIT_LIST) do table.insert(bibitNames, b.name) end

local ITEM_LIST = {
    { name="Padi",       price=10,  icon="🌾" },
    { name="Jagung",     price=20,  icon="🌽" },
    { name="Tomat",      price=30,  icon="🍅" },
    { name="Terong",     price=50,  icon="🍆" },
    { name="Strawberry", price=75,  icon="🍓" },
}

local NPC_LIST = {
    { label="NPC Penjual",        x=-59,   y=nil,  z=-207   },
    { label="NPC Bibit",          x=-42,   y=nil,  z=-207   },
    { label="NPC Alat",           x=-41.5, y=49.2, z=-180.8 },
    { label="NPC Pedagang Sawit", x= 56,   y=nil,  z=-208   },
    { label="NPC Pedagang Telur", x=-98,   y=nil,  z=-176   },
}
local MANDI = { x=137, z=-235 }

local LOCATION_LIST = {
    { name="Spawn / Rumah",  x=0,   y=nil, z=0    },
    { name="Area Pasar",     x=-59, y=nil, z=-207 },
    { name="Area Sawah",     x=-41, y=nil, z=-180 },
    { name="Area Mandi",     x=137, y=nil, z=-235 },
}

-- ════════════════════════════════════════════════
--  REMOTE CACHE
-- ════════════════════════════════════════════════
local remoteCache = {}
local function getR(name)
    if remoteCache[name] then return remoteCache[name] end
    local folder = RS:FindFirstChild("Remotes")
    folder = folder and folder:FindFirstChild("TutorialRemotes")
    if not folder then return nil end
    local r = folder:FindFirstChild(name)
    if r then remoteCache[name] = r end
    return r
end
local function fireEv(name, ...)
    local r = getR(name)
    if not r or not r:IsA("RemoteEvent") then return false end
    return pcall(function(...) r:FireServer(...) end, ...)
end
local function invokeRF(name, ...)
    local r = getR(name)
    if not r or not r:IsA("RemoteFunction") then return false, nil end
    local ok, res = pcall(function(...) return r:InvokeServer(...) end, ...)
    return ok, res
end
local function unwrap(res)
    if type(res)=="table" then
        return type(res[1])=="table" and res[1] or res
    end
    return nil
end

-- ════════════════════════════════════════════════
--  NOTIF
-- ════════════════════════════════════════════════
local function notif(title, body, dur)
    pcall(function() Library:Notification(title, body, dur or 3) end)
    print(string.format("[ XKID ] %s | %s", title, tostring(body)))
end

-- ════════════════════════════════════════════════
--  CHARACTER HELPERS
-- ════════════════════════════════════════════════
local function getChar() return LP.Character end
local function getRoot()
    local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function getPos() local r=getRoot(); return r and r.Position end
local function getCF()  local r=getRoot(); return r and r.CFrame  end

-- ════════════════════════════════════════════════
--  TELEPORT
-- ════════════════════════════════════════════════
local function tpCFrame(cf)
    local r=getRoot(); if not r then return false end
    r.CFrame=cf; task.wait(0.35); return true
end
local function raycastY(x, z)
    local rp=RaycastParams.new()
    rp.FilterType=Enum.RaycastFilterType.Exclude
    local ch=getChar(); if ch then rp.FilterDescendantsInstances={ch} end
    local res=Workspace:Raycast(Vector3.new(x,500,z), Vector3.new(0,-1000,0), rp)
    return res and (res.Position.Y+3) or 42
end
local function tpToXZ(x, z, hardY)
    local r=getRoot(); if not r then return false end
    local y=hardY or raycastY(x,z)
    r.CFrame=CFrame.new(x,y,z); task.wait(0.35)
    return true, y
end

-- ════════════════════════════════════════════════
--  SCAN NPC
-- ════════════════════════════════════════════════
local NpcScanResult={}
local NPC_OVERRIDE={}
local NPC_KEYWORDS={"npc","pedagang","penjual","bibit","alat","toko","shop","vendor"}
local function nameMatchNPC(n)
    n=n:lower()
    for _,kw in ipairs(NPC_KEYWORDS) do if n:find(kw) then return true end end
    return false
end
local function scanAllNPC()
    NpcScanResult={}
    local seen={}
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and not seen[v] then
            seen[v]=true
            local rp=v:FindFirstChild("HumanoidRootPart") or v.PrimaryPart
            if (v:FindFirstChildOfClass("Humanoid") or nameMatchNPC(v.Name)) and rp then
                table.insert(NpcScanResult,{
                    name=v.Name, x=math.floor(rp.Position.X*10+0.5)/10,
                    y=rp.Position.Y, z=math.floor(rp.Position.Z*10+0.5)/10,
                    cf=rp.CFrame,
                })
            end
        end
    end
    table.sort(NpcScanResult, function(a,b) return a.name<b.name end)
    return NpcScanResult
end
local function buildNPCOverride()
    NPC_OVERRIDE={}
    for _,npc in ipairs(NPC_LIST) do
        local best,bestCF=math.huge,nil
        for _,f in ipairs(NpcScanResult) do
            local d=math.sqrt((f.x-npc.x)^2+(f.z-npc.z)^2)
            if d<best then best=d; bestCF=f.cf end
        end
        if bestCF and best<=40 then NPC_OVERRIDE[npc.label]=bestCF end
    end
end
local function tpToNPC(x,z,label,hardY)
    local r=getRoot(); if not r then return false,0 end
    if label and NPC_OVERRIDE[label] then
        local cf=NPC_OVERRIDE[label]*CFrame.new(0,0,3)
        r.CFrame=cf; task.wait(0.35)
        return true,cf.Position.Y
    end
    if hardY then r.CFrame=CFrame.new(x,hardY,z); task.wait(0.35); return true,hardY end
    local y=raycastY(x,z); r.CFrame=CFrame.new(x,y,z); task.wait(0.35)
    return true,y
end

-- ════════════════════════════════════════════════
--  PENANGKAL PETIR
-- ════════════════════════════════════════════════
local function startHpLock(dur)
    if godConn then godConn:Disconnect(); godConn=nil end
    local deadline=tick()+dur
    godConn=RunService.Heartbeat:Connect(function()
        if tick()>deadline then godConn:Disconnect(); godConn=nil; return end
        local h=getHum(); if h and h.Health<h.MaxHealth then h.Health=h.MaxHealth end
    end)
end
local function fleePetir()
    if isPetirActive then return end
    isPetirActive=true; lightningHits=lightningHits+1
    local r=getRoot(); if not r then isPetirActive=false; return end
    local h=getHum(); if h then h.Health=h.MaxHealth end
    petirReturnCF=r.CFrame; startHpLock(8)
    if fleePos then
        r.CFrame=fleePos
        notif("Petir #"..lightningHits,"Kabur ke titik aman | balik 5s",5)
    else
        r.CFrame=CFrame.new(r.Position.X,r.Position.Y+350,r.Position.Z)
        notif("Petir #"..lightningHits,"Naik awan | balik 5s",5)
    end
    task.wait(5)
    local r2=getRoot()
    if r2 and petirReturnCF then r2.CFrame=petirReturnCF end
    task.wait(0.5); isPetirActive=false
end

-- ════════════════════════════════════════════════
--  ANTI AFK
-- ════════════════════════════════════════════════
local function startAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect() end
    local last=tick()
    antiAFKConn=RunService.Heartbeat:Connect(function()
        if not _G.AntiAFK then antiAFKConn:Disconnect(); antiAFKConn=nil; return end
        if tick()-last>=120 then
            last=tick(); local h=getHum(); if h then h.Jump=true end
        end
    end)
end

-- ════════════════════════════════════════════════
--  ANTI KICK (HP Lock permanen)
-- ════════════════════════════════════════════════
local function startAntiKick()
    if AntiKickLoop then return end
    AntiKickLoop = task.spawn(function()
        while _G.AntiKick do
            pcall(function()
                local h=getHum()
                if h and h.Health>0 and h.Health<h.MaxHealth*0.15 then
                    h.Health=h.MaxHealth
                    notif("Anti Kick","HP dikembalikan penuh!",3)
                end
            end)
            task.wait(0.3)
        end
        AntiKickLoop=nil
    end)
end

-- ════════════════════════════════════════════════
--  NOCLIP
-- ════════════════════════════════════════════════
local function setNoclip(state)
    _G.NoclipOn=state
    if state then
        noclipConn=RunService.Stepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        local c=getChar()
        if c then
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=true end
            end
        end
    end
end

-- ════════════════════════════════════════════════
--  FLY (BodyVelocity + pitch kamera)
-- ════════════════════════════════════════════════
local function startFly()
    local root=getRoot(); if not root then return end
    local hum=getHum();   if not hum  then return end
    if flyBV   then pcall(function() flyBV:Destroy()      end) end
    if flyBG   then pcall(function() flyBG:Destroy()      end) end
    if flyConn then pcall(function() flyConn:Disconnect() end) end
    flyBV=Instance.new("BodyVelocity",root)
    flyBV.Velocity=Vector3.new(); flyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
    flyBG=Instance.new("BodyGyro",root)
    flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5)
    flyBG.P=1e4; flyBG.D=100; flyBG.CFrame=root.CFrame
    hum.PlatformStand=true
    flyConn=RunService.Heartbeat:Connect(function()
        local r2=getRoot(); if not r2 or not flyBV then return end
        local h2=getHum();  if not h2 then return end
        local cam=Workspace.CurrentCamera
        local camCF=cam.CFrame
        local fwd=Vector3.new(camCF.LookVector.X,0,camCF.LookVector.Z)
        local rgt=Vector3.new(camCF.RightVector.X,0,camCF.RightVector.Z)
        if fwd.Magnitude>0 then fwd=fwd.Unit end
        if rgt.Magnitude>0 then rgt=rgt.Unit end
        local md=h2.MoveDirection
        local horiz=Vector3.new()
        if md.Magnitude>0.05 then
            horiz=fwd*md:Dot(fwd)+rgt*md:Dot(rgt)
            if horiz.Magnitude>1 then horiz=horiz.Unit end
        end
        local py=camCF.LookVector.Y
        local vert=Vector3.new()
        if py>PITCH_UP then
            vert=Vector3.new(0,math.min((py-PITCH_UP)/(1-PITCH_UP),1),0)
        elseif py<PITCH_DOWN then
            vert=Vector3.new(0,-math.min((-py+PITCH_DOWN)/(1+PITCH_DOWN),1),0)
        end
        local dir=horiz+vert
        if dir.Magnitude>0 then
            flyBV.Velocity=(dir.Magnitude>1 and dir.Unit or dir)*flySpeed
            if horiz.Magnitude>0.05 then flyBG.CFrame=CFrame.new(Vector3.new(),horiz) end
        else
            flyBV.Velocity=Vector3.new()
        end
        h2.PlatformStand=true
    end)
end
local function stopFly()
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn=nil end
    if flyBV   then pcall(function() flyBV:Destroy()      end); flyBV=nil   end
    if flyBG   then pcall(function() flyBG:Destroy()      end); flyBG=nil   end
    local h=getHum(); if h then h.PlatformStand=false end
end

-- Respawn handler
LP.CharacterAdded:Connect(function(char)
    local hum=char:WaitForChild("Humanoid",5); if not hum then return end
    task.wait(0.5)
    hum.WalkSpeed=curWS; hum.JumpPower=curJP; hum.UseJumpPower=true
    if _G.FlyOn then
        task.wait(0.3)
        local r2=char:FindFirstChild("HumanoidRootPart")
        if r2 then startFly() end
    end
end)

-- ════════════════════════════════════════════════
--  HARVEST
-- ════════════════════════════════════════════════
local function harvestViaSignal()
    local Event=getR("HarvestCrop")
    if not Event then notif("Harvest","HarvestCrop tidak ditemukan",4); return 0 end
    local count=0
    for _,crop in ipairs(CROP_NAMES) do
        pcall(function() firesignal(Event.OnClientEvent, crop.name, crop.idx, crop.name) end)
        harvestCount=harvestCount+1; count=count+1; task.wait(0.3)
    end
    return count
end

-- ════════════════════════════════════════════════
--  MANDI
-- ════════════════════════════════════════════════
local function goMandi()
    tpToXZ(MANDI.x, MANDI.z)
    notif("Mandi", string.format("X=%d Z=%d",MANDI.x,MANDI.z), 3)
end

-- ════════════════════════════════════════════════
--  BELI BIBIT
-- ════════════════════════════════════════════════
local function beliBibit(nama, qty)
    local ok,res=invokeRF("RequestShop","BUY",nama or selectedBibit,qty or jumlahBeli)
    if not ok then return false,"RequestShop gagal" end
    local data=unwrap(res)
    if data and data.Success then
        PlayerData.Coins=data.NewCoins or PlayerData.Coins
        return true, data.Message or "Berhasil beli "..(nama or selectedBibit)
    end
    return false,(data and data.Message) or "Gagal"
end

local function cekStokBibit()
    local ok,res=invokeRF("RequestShop","GET_LIST")
    if not ok then return nil end
    local data=unwrap(res)
    if not data or not data.Seeds then return nil end
    PlayerData.Coins=data.Coins or PlayerData.Coins
    return data.Seeds
end

-- ════════════════════════════════════════════════
--  JUAL
-- ════════════════════════════════════════════════
local function getInventoryJual()
    local ok,res=invokeRF("RequestSell","GET_LIST")
    if not ok then return nil end
    local data=unwrap(res)
    if data then PlayerData.Coins=data.Coins or PlayerData.Coins end
    return data
end
local function jualItem(nama, qty)
    local ok,res=invokeRF("RequestSell","SELL",nama,qty or 1)
    if not ok then return false,"Remote gagal",0 end
    local data=unwrap(res)
    if data and data.Success then
        local earned=data.Earned or 0
        totalEarned=totalEarned+earned
        PlayerData.Coins=data.NewCoins or PlayerData.Coins
        return true, data.Message or "Terjual", earned
    end
    return false,(data and data.Message) or "Gagal",0
end
local function jualSemua()
    local data=getInventoryJual()
    if not data or not data.Items then
        fireEv("SellCrop"); return true,"SellCrop dikirim"
    end
    local totalItem,totalCoin=0,0
    for _,item in ipairs(data.Items) do
        if (item.Owned or 0)>0 and (item.Price or 0)>0 then
            local ok,_,earned=jualItem(item.Name,item.Owned)
            if ok then totalItem=totalItem+item.Owned; totalCoin=totalCoin+earned end
            task.wait(0.3)
        end
    end
    if totalItem==0 then fireEv("SellCrop"); return true,"SellCrop fallback" end
    return true, totalItem.." item | +"..totalCoin.." koin"
end

-- ════════════════════════════════════════════════
--  AUTO FARM FULL CYCLE
--  Tanam > Tunggu > Harvest > Jual > Ulangi
-- ════════════════════════════════════════════════
local function runFarmCycle()
    cycleCount=cycleCount+1
    notif("Farm Cycle #"..cycleCount,"Tanam...",2)

    -- 1. Tanam
    fireEv("PlantCrop")
    task.wait(1)
    fireEv("PlantLahanCrop")
    task.wait(1)
    fireEv("ToggleAutoHarvest")
    task.wait(1)

    -- 2. Tunggu tumbuh
    notif("Farm Cycle","Menunggu "..cycleDelay.."s tumbuh...",cycleDelay)
    task.wait(cycleDelay)

    -- 3. Harvest semua
    notif("Farm Cycle","Harvest...",2)
    harvestViaSignal()
    task.wait(2)

    -- 4. Jual semua
    notif("Farm Cycle","Jual...",2)
    local ok,msg=jualSemua()
    task.wait(1)

    -- 5. Auto beli bibit kalau aktif
    if _G.AutoBeliBibit then
        local seeds=cekStokBibit()
        if seeds then
            for _,s in ipairs(seeds) do
                if not s.Locked and (s.Owned or 0)<minStokBibit then
                    local bOk,bMsg=beliBibit(s.Name, jumlahBeli)
                    notif("Auto Beli", s.Name.." | "..(bMsg or ""), 3)
                    task.wait(0.5)
                end
            end
        end
    end

    notif("Cycle Selesai","#"..cycleCount.." | "..msg, 4)
end

-- ════════════════════════════════════════════════
--  ESP TANAMAN
--  Scan workspace cari Part/Model tanaman
--  Tampilkan BillboardGui di atas setiap tanaman
-- ════════════════════════════════════════════════
local CROP_KEYWORDS = {
    "padi","jagung","tomat","terong","strawberry","sawit","durian",
    "tanaman","plant","crop","kebun","ladang","sawah","seed","bibit"
}
local function isCropPart(name)
    local n=name:lower()
    for _,kw in ipairs(CROP_KEYWORDS) do if n:find(kw) then return true end end
    return false
end

local function clearESPTanaman()
    for _,b in ipairs(ESPBills) do pcall(function() b:Destroy() end) end
    for _,c in ipairs(ESPConns) do pcall(function() c:Disconnect() end) end
    ESPBills={}; ESPConns={}
end

local function makeESPBill(part, label, color)
    local bill=Instance.new("BillboardGui")
    bill.Size=UDim2.new(0,120,0,35)
    bill.StudsOffset=Vector3.new(0,3,0)
    bill.AlwaysOnTop=true
    bill.Adornee=part
    bill.Parent=part

    local bg=Instance.new("Frame",bill)
    bg.Size=UDim2.new(1,0,1,0)
    bg.BackgroundColor3=Color3.fromRGB(10,25,10)
    bg.BackgroundTransparency=0.3
    bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel",bg)
    lbl.Size=UDim2.new(1,-4,1,-4)
    lbl.Position=UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency=1
    lbl.TextColor3=color or Color3.fromRGB(120,255,80)
    lbl.TextStrokeTransparency=0.2
    lbl.TextScaled=true
    lbl.Font=Enum.Font.GothamBold
    lbl.Text=label

    table.insert(ESPBills,bill)
    return bill
end

local function scanESPTanaman()
    clearESPTanaman()
    local count=0
    for _,v in pairs(Workspace:GetDescendants()) do
        if (v:IsA("BasePart") or v:IsA("Model")) and isCropPart(v.Name) then
            local part=v:IsA("Model") and (v.PrimaryPart or v:FindFirstChildOfClass("BasePart")) or v
            if part then
                -- Cek apakah sudah punya billboard
                if not part:FindFirstChildOfClass("BillboardGui") then
                    makeESPBill(part, v.Name, Color3.fromRGB(80,255,120))
                    count=count+1
                end
            end
        end
    end
    return count
end

local espScanConn=nil
local function startESPTanaman()
    scanESPTanaman()
    -- Re-scan tiap 10 detik untuk tanaman baru
    espScanConn=task.spawn(function()
        while _G.ESPTanaman do
            task.wait(10)
            if _G.ESPTanaman then scanESPTanaman() end
        end
    end)
end
local function stopESPTanaman()
    clearESPTanaman()
    if espScanConn then pcall(function() task.cancel(espScanConn) end); espScanConn=nil end
end

-- ════════════════════════════════════════════════
--  STOP ALL
-- ════════════════════════════════════════════════
local function stopSemua()
    _G.AutoSell=false; _G.AutoHarvest=false; _G.AutoFarmCycle=false
    _G.AutoBeliBibit=false; _G.ESPTanaman=false; _G.AntiKick=false
    if SellLoop     then pcall(function() task.cancel(SellLoop)     end); SellLoop=nil     end
    if HarvestLoop  then pcall(function() task.cancel(HarvestLoop)  end); HarvestLoop=nil  end
    if FarmCycleLoop then pcall(function() task.cancel(FarmCycleLoop) end); FarmCycleLoop=nil end
    if AutoBeliLoop  then pcall(function() task.cancel(AutoBeliLoop) end); AutoBeliLoop=nil  end
    stopESPTanaman()
    stopFly()
    notif("STOP SEMUA","Semua fitur dimatikan",3)
end

-- ════════════════════════════════════════════════
--  INTERCEPTS
-- ════════════════════════════════════════════════
local function setupIntercepts()
    task.spawn(function()
        local r; for i=1,25 do r=getR("LightningStrike"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
            if not _G.PenangkalPetir then return end
            if type(data)=="table" and data.Hit then task.spawn(fleePetir) end
        end)
        print("[ XKID ] LightningStrike intercept READY")
    end)
    task.spawn(function()
        local r; for i=1,15 do r=getR("RainSync"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(isRaining)
            if isRaining then notif("Hujan","Tanaman tumbuh lebih cepat!",4) end
        end)
    end)
    task.spawn(function()
        local r; for i=1,15 do r=getR("UpdateLevel"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
            if type(data)~="table" then return end
            PlayerData.Level=data.Level or PlayerData.Level
            PlayerData.XP=data.XP or PlayerData.XP
            PlayerData.Needed=data.Needed or PlayerData.Needed
            if data.LeveledUp and _G.NotifLevelUp then
                levelUpCount=levelUpCount+1
                notif("Level Up! #"..levelUpCount,
                    "Level "..data.Level.." | XP "..data.XP.."/"..data.Needed, 6)
            end
        end)
    end)
    task.spawn(function()
        local r; for i=1,15 do r=getR("Notification"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(msg)
            if type(msg)~="string" then return end
            local ml=msg:lower()
            if ml:find("petir") or ml:find("gosong") then notif("Petir!",msg,4)
            elseif ml:find("kotor") or ml:find("mandi") then
                notif("Perlu Mandi!",msg,4)
                if _G.AutoMandi then task.delay(0.5,goMandi) end
            end
        end)
    end)
    task.spawn(function()
        local r; for i=1,15 do r=getR("ConfirmAction"); if r then break end; task.wait(1) end
        if not r or not r:IsA("RemoteFunction") then return end
        r.OnClientInvoke=function()
            if _G.AutoConfirm then return true end; return nil
        end
    end)
    print("[ XKID ] ALL INTERCEPTS READY")
end

-- ════════════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════════════
Win:TabSection("Farming")
local TabCycle   = Win:Tab("Farm Cycle", "repeat")
local TabBibit   = Win:Tab("Bibit",      "shopping-cart")
local TabHarvest = Win:Tab("Harvest",    "scissors")
local TabJual    = Win:Tab("Jual",       "coins")
local TabESP     = Win:Tab("ESP",        "eye")

Win:TabSection("Player")
local TabMove    = Win:Tab("Movement",   "zap")
local TabProt    = Win:Tab("Protection", "shield")

Win:TabSection("Utility")
local TabTP      = Win:Tab("Teleport",   "map-pin")
local TabLoc     = Win:Tab("Location",   "map")
local TabPetir   = Win:Tab("Petir",      "cloud-lightning")
local TabSet     = Win:Tab("Setting",    "settings")

-- ════════════════════════════════════════════════
--  TAB FARM CYCLE
-- ════════════════════════════════════════════════
local CyclePage  = TabCycle:Page("Auto Farm Full Cycle","repeat")
local CycleLeft  = CyclePage:Section("Cycle Control","Left")
local CycleRight = CyclePage:Section("Pengaturan","Right")

CycleLeft:Toggle("Auto Farm Cycle","AutoCycleToggle",false,
    "Loop: Tanam > Harvest > Jual otomatis",
    function(v)
        _G.AutoFarmCycle=v
        if v then
            FarmCycleLoop=task.spawn(function()
                while _G.AutoFarmCycle do
                    runFarmCycle()
                    task.wait(3)
                end
            end)
            notif("Farm Cycle","ON — mulai loop!",3)
        else
            if FarmCycleLoop then
                pcall(function() task.cancel(FarmCycleLoop) end); FarmCycleLoop=nil
            end
            notif("Farm Cycle","OFF | "..cycleCount.." cycle selesai",3)
        end
    end)

CycleLeft:Button("Jalankan 1 Cycle","Satu kali tanam > harvest > jual",
    function()
        task.spawn(runFarmCycle)
    end)

CycleLeft:Toggle("Auto Beli Bibit","AutoBeliToggle",false,
    "Otomatis beli bibit saat stok habis",
    function(v)
        _G.AutoBeliBibit=v
        notif("Auto Beli Bibit",v and "ON" or "OFF",2)
    end)

CycleLeft:Button("Cek & Beli Bibit Sekarang","Cek stok lalu beli yang kurang",
    function()
        task.spawn(function()
            local seeds=cekStokBibit()
            if not seeds then notif("Gagal","Tidak bisa cek stok",3); return end
            local bought=0
            for _,s in ipairs(seeds) do
                if not s.Locked and (s.Owned or 0)<minStokBibit then
                    local ok,msg=beliBibit(s.Name,jumlahBeli)
                    notif(ok and "Beli OK" or "Gagal", s.Name.." | "..msg, 3)
                    if ok then bought=bought+1 end
                    task.wait(0.5)
                end
            end
            if bought==0 then notif("Stok Cukup","Semua bibit stok aman",3) end
        end)
    end)

CycleRight:Slider("Delay Tumbuh (detik)","CycleDelay",5,120,15,
    function(v) cycleDelay=v end,"Waktu tunggu setelah tanam")

CycleRight:Slider("Jumlah Beli Bibit","BeliQty",1,99,10,
    function(v) jumlahBeli=v end,"Per transaksi beli")

CycleRight:Slider("Min Stok Bibit","MinStok",1,50,5,
    function(v) minStokBibit=v end,"Beli kalau stok di bawah ini")

CycleRight:Dropdown("Bibit Cycle","CycleBibitDrop",bibitNames,
    function(val) selectedBibit=val; notif("Bibit",val.." dipilih",2) end,
    "Bibit untuk auto cycle")

CycleRight:Paragraph("Urutan Cycle",
    "1. PlantCrop\n2. PlantLahanCrop\n3. ToggleAutoHarvest\n4. Tunggu "..cycleDelay.."s\n5. HarvestCrop (semua)\n6. SellCrop / RequestSell\n7. Auto beli bibit (opsional)\n8. Ulangi")

-- ════════════════════════════════════════════════
--  TAB BIBIT
-- ════════════════════════════════════════════════
local BibitPage  = TabBibit:Page("Beli Bibit","shopping-cart")
local BibitLeft  = BibitPage:Section("Pilih & Beli","Left")
local BibitRight = BibitPage:Section("Beli Cepat","Right")

BibitLeft:Dropdown("Pilih Bibit","BibitDropdown",bibitNames,
    function(val) selectedBibit=val; notif("Bibit",val.." dipilih",2) end,"Pilih bibit")

BibitLeft:Slider("Jumlah Beli","SliderBeli",1,99,10,
    function(v) jumlahBeli=v end,"Jumlah per transaksi")

BibitLeft:Button("Beli Sekarang","Beli bibit dipilih",
    function()
        task.spawn(function()
            local ok,msg=beliBibit(selectedBibit,jumlahBeli)
            notif(ok and "Beli OK" or "Gagal",msg,4)
        end)
    end)

BibitLeft:Button("Cek Stok Bibit","Lihat stok & harga",
    function()
        task.spawn(function()
            local seeds=cekStokBibit()
            if not seeds then notif("Gagal","RequestShop error",3); return end
            local txt="Koin: "..PlayerData.Coins.."\n\n"
            for _,s in ipairs(seeds) do
                txt=txt..(s.Locked and "[KUNCI] " or "[OK] ")
                    ..s.Name.."  x"..s.Owned.."  ("..s.Price..")\n"
            end
            notif("Toko Bibit",txt,12)
        end)
    end)

for _,b in ipairs(BIBIT_LIST) do
    local bb=b
    BibitRight:Button(bb.icon.." "..bb.name,"Harga "..bb.price.." | Min Lv "..bb.minLv,
        function()
            task.spawn(function()
                selectedBibit=bb.name
                local ok,msg=beliBibit(bb.name,jumlahBeli)
                notif(ok and "Beli OK" or "Gagal",msg,3)
            end)
        end)
end

-- ════════════════════════════════════════════════
--  TAB HARVEST
-- ════════════════════════════════════════════════
local HarvPage  = TabHarvest:Page("Harvest","scissors")
local HarvLeft  = HarvPage:Section("Auto Harvest","Left")
local HarvRight = HarvPage:Section("Info","Right")

HarvLeft:Toggle("Auto Harvest (10s)","AutoHarvToggle",false,
    "Harvest semua tanaman tiap 10 detik",
    function(v)
        _G.AutoHarvest=v
        if v then
            HarvestLoop=task.spawn(function()
                while _G.AutoHarvest do
                    local c=harvestViaSignal()
                    notif("Auto Harvest",c.." sinyal dikirim",2)
                    task.wait(10)
                end
            end)
            notif("Auto Harvest","ON",3)
        else
            if HarvestLoop then pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil end
            notif("Auto Harvest","OFF | Total: "..harvestCount,3)
        end
    end)

HarvLeft:Button("Harvest Sekarang","Kirim harvest semua tanaman",
    function()
        task.spawn(function()
            local c=harvestViaSignal()
            notif("Harvest Selesai",c.." tanaman",3)
        end)
    end)

HarvLeft:Button("PlantCrop","Fire PlantCrop ke server",
    function() fireEv("PlantCrop"); notif("PlantCrop","Dikirim",2) end)

HarvLeft:Button("PlantLahanCrop","Fire PlantLahanCrop ke server",
    function() fireEv("PlantLahanCrop"); notif("PlantLahanCrop","Dikirim",2) end)

HarvLeft:Button("ToggleAutoHarvest","Fire ToggleAutoHarvest ke server",
    function() fireEv("ToggleAutoHarvest"); notif("ToggleAutoHarvest","Dikirim",2) end)

HarvRight:Paragraph("Tanaman Didukung",
    "Padi (1) · Jagung (2)\nTomat (3) · Terong (4)\nStrawberry (5) · Sawit (6)\nDurian (7)\n\nDelay: 0.3s per tanaman")

-- ════════════════════════════════════════════════
--  TAB JUAL
-- ════════════════════════════════════════════════
local JualPage  = TabJual:Page("Jual Hasil","coins")
local JualLeft  = JualPage:Section("Jual Semua","Left")
local JualRight = JualPage:Section("Jual Per Item","Right")

JualLeft:Button("Jual Semua Sekarang","Jual semua item di inventori",
    function()
        task.spawn(function()
            local ok,msg=jualSemua()
            notif(ok and "Jual OK" or "Gagal",msg,4)
        end)
    end)

JualLeft:Button("SellCrop Langsung","Fire SellCrop (dari spy log)",
    function() fireEv("SellCrop"); notif("SellCrop","Dikirim",2) end)

JualLeft:Toggle("Auto Sell (30s)","AutoSellToggle",false,
    "Jual otomatis tiap 30 detik",
    function(v)
        _G.AutoSell=v
        if v then
            SellLoop=task.spawn(function()
                while _G.AutoSell do
                    local ok,msg=jualSemua()
                    notif(ok and "Auto Sell OK" or "Gagal",msg,3)
                    task.wait(30)
                end
            end)
            notif("Auto Sell","ON",3)
        else
            if SellLoop then pcall(function() task.cancel(SellLoop) end); SellLoop=nil end
            notif("Auto Sell","OFF",2)
        end
    end)

JualLeft:Button("Lihat Inventory","Cek semua item",
    function()
        task.spawn(function()
            local data=getInventoryJual()
            if not data then notif("Gagal","Tidak ada response",4); return end
            local items=data.Items
            if not items or #items==0 then
                notif("Inventory Kosong","Koin: "..tostring(data.Coins),5); return
            end
            local txt="Koin: "..tostring(data.Coins).."\n\n"
            for _,item in ipairs(items) do
                local owned=item.Owned or 0
                txt=txt..(owned>0 and "[ADA] " or "[  ] ")
                    ..item.Name.."  x"..owned.."  ("..item.Price..")\n"
            end
            notif("Inventory",txt,12)
        end)
    end)

for _,item in ipairs(ITEM_LIST) do
    local it=item
    JualRight:Button(it.icon.." Jual "..it.name,it.price.." koin per item",
        function()
            task.spawn(function()
                local data=getInventoryJual()
                local owned=0
                if data and data.Items then
                    for _,i in ipairs(data.Items) do
                        if i.Name==it.name then owned=i.Owned or 0; break end
                    end
                end
                if owned==0 then notif(it.name,"Stok kosong",3); return end
                local ok,msg,earned=jualItem(it.name,owned)
                notif(ok and "Jual OK" or "Gagal",
                    it.name.." x"..owned..(ok and " | +"..earned or " | "..msg),4)
            end)
        end)
end

-- ════════════════════════════════════════════════
--  TAB ESP TANAMAN
-- ════════════════════════════════════════════════
local ESPPage  = TabESP:Page("ESP Tanaman","eye")
local ESPLeft  = ESPPage:Section("ESP Control","Left")
local ESPRight = ESPPage:Section("Info","Right")

ESPLeft:Toggle("ESP Tanaman","ESPTanamanToggle",false,
    "Tampilkan label di atas semua tanaman di workspace",
    function(v)
        _G.ESPTanaman=v
        if v then startESPTanaman() else stopESPTanaman() end
        notif("ESP Tanaman",v and "ON" or "OFF",2)
    end)

ESPLeft:Button("Scan Ulang ESP","Refresh posisi tanaman",
    function()
        if _G.ESPTanaman then
            local c=scanESPTanaman()
            notif("ESP Scan",c.." tanaman ditemukan",3)
        else
            notif("ESP","Aktifkan ESP dulu!",2)
        end
    end)

ESPLeft:Button("Hapus Semua ESP","Bersihkan semua label",
    function()
        clearESPTanaman()
        notif("ESP","Semua label dihapus",2)
    end)

ESPRight:Paragraph("Cara Kerja ESP",
    "Scan semua BasePart/Model\ndi workspace yang namanya\nmengandung kata kunci:\n\npadi · jagung · tomat\nterong · strawberry\nsawit · durian · tanaman\nplant · crop · kebun\n\nLabel muncul di atas tanaman\nAuto rescan tiap 10 detik")

-- ════════════════════════════════════════════════
--  TAB MOVEMENT
-- ════════════════════════════════════════════════
local MovePage  = TabMove:Page("Speed & Fly","zap")
local MoveLeft  = MovePage:Section("Speed & Jump","Left")
local MoveRight = MovePage:Section("Fly & NoClip","Right")

MoveLeft:Slider("Walk Speed","WSSlider",1,500,16,
    function(v)
        curWS=v; local h=getHum(); if h then h.WalkSpeed=v end
    end,"Default 16")

MoveLeft:Button("Reset Speed","Kembalikan ke 16",
    function()
        curWS=16; local h=getHum()
        if h then h.WalkSpeed=16 end
        notif("Speed","Reset ke 16",2)
    end)

MoveLeft:Slider("Jump Power","JPSlider",1,500,50,
    function(v)
        curJP=v; local h=getHum()
        if h then h.JumpPower=v; h.UseJumpPower=true end
    end,"Default 50")

MoveLeft:Button("Reset Jump","Kembalikan ke 50",
    function()
        curJP=50; local h=getHum()
        if h then h.JumpPower=50; h.UseJumpPower=true end
        notif("Jump","Reset ke 50",2)
    end)

MoveLeft:Toggle("Infinite Jump","InfJumpToggle",false,"Lompat terus di udara",
    function(v)
        if v then
            _G.xkid_ij=UIS.JumpRequest:Connect(function()
                local h=getHum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if _G.xkid_ij then _G.xkid_ij:Disconnect(); _G.xkid_ij=nil end
        end
        notif("Inf Jump",v and "ON" or "OFF",2)
    end)

MoveRight:Toggle("Fly Mode","FlyToggle",false,"Aktifkan terbang",
    function(v)
        _G.FlyOn=v
        if v then startFly() else stopFly() end
        notif("Fly",v and "ON" or "OFF",2)
    end)

MoveRight:Slider("Kecepatan Fly","FlySpeed",5,300,60,
    function(v) flySpeed=v end,"Default 60")

MoveRight:Slider("Sensitivitas Pitch","PitchSlider",1,9,3,
    function(v) PITCH_UP=v*0.1; PITCH_DOWN=-v*0.1 end,"Naik/turun kamera")

MoveRight:Toggle("NoClip","NoclipToggle",false,"Tembus semua dinding",
    function(v)
        setNoclip(v)
        notif("NoClip",v and "ON" or "OFF",2)
    end)

MoveRight:Paragraph("Cara Fly",
    "Joystick = gerak\nKamera atas = naik\nKamera bawah = turun\nLepas joystick = melayang")

-- ════════════════════════════════════════════════
--  TAB PROTECTION
-- ════════════════════════════════════════════════
local ProtPage  = TabProt:Page("Protection","shield")
local ProtLeft  = ProtPage:Section("Anti AFK & Kick","Left")
local ProtRight = ProtPage:Section("Info","Right")

ProtLeft:Toggle("Anti AFK","AntiAFKToggle",false,
    "Jump kecil tiap 2 menit cegah disconnect",
    function(v)
        _G.AntiAFK=v
        if v then startAntiAFK() end
        notif("Anti AFK",v and "ON — aktif tiap 2 menit" or "OFF",3)
    end)

ProtLeft:Toggle("Anti Kick","AntiKickToggle",false,
    "HP dikunci penuh — cegah mati dari kick server",
    function(v)
        _G.AntiKick=v
        if v then startAntiKick() end
        notif("Anti Kick",v and "ON — HP terkunci" or "OFF",3)
    end)

ProtLeft:Toggle("Auto Mandi","AutoMandiProt",false,
    "TP mandi otomatis saat kotor",
    function(v) _G.AutoMandi=v; notif("Auto Mandi",v and "ON" or "OFF",2) end)

ProtLeft:Button("Rejoin Server","Koneksi ulang ke server",
    function()
        notif("Rejoin","Menghubungkan ulang...",3)
        task.wait(1); TpService:Teleport(game.PlaceId,LP)
    end)

ProtLeft:Button("Posisi Saya","Lihat koordinat sekarang",
    function()
        local pos=getPos()
        if pos then
            notif("Posisi",
                string.format("X=%.1f\nY=%.1f\nZ=%.1f",pos.X,pos.Y,pos.Z),6)
        end
    end)

ProtRight:Paragraph("Anti AFK",
    "Jump kecil tiap 120 detik\nMencegah auto disconnect\nsaat AFK di game")

ProtRight:Paragraph("Anti Kick",
    "HP dipantau tiap 0.3 detik\nJika HP < 15% MaxHP\nHP langsung dikembalikan penuh\nNotif saat terpicu")

-- ════════════════════════════════════════════════
--  TAB TELEPORT
-- ════════════════════════════════════════════════
local TpPage  = TabTP:Page("Teleport NPC","map-pin")
local TpLeft  = TpPage:Section("NPC","Left")
local TpRight = TpPage:Section("Save Slot","Right")
local TpScan  = TpPage:Section("Scan NPC","Right")

TpScan:Button("Scan Semua NPC","Cari semua NPC di workspace",
    function()
        task.spawn(function()
            notif("Scan NPC","Sedang scan...",2)
            local found=scanAllNPC(); buildNPCOverride()
            if #found==0 then notif("Scan NPC","Tidak ditemukan!",5); return end
            for i,n in ipairs(found) do
                print(string.format("[ NPC #%d ] %-30s X=%.1f Y=%.1f Z=%.1f",i,n.name,n.x,n.y,n.z))
            end
            local matched=0
            for _,npc in ipairs(NPC_LIST) do if NPC_OVERRIDE[npc.label] then matched=matched+1 end end
            notif("Scan Selesai",#found.." NPC | "..matched.."/"..#NPC_LIST.." match",6)
        end)
    end)

TpLeft:Label("Scan dulu untuk TP akurat")
for _,npc in ipairs(NPC_LIST) do
    local n=npc
    TpLeft:Button("TP: "..n.label,n.y and "Koordinat exact" or "Y auto raycast",
        function()
            task.spawn(function()
                local _,y=tpToNPC(n.x,n.z,n.label,n.y)
                notif("TP "..n.label,string.format("Y=%.1f",y or 0),3)
            end)
        end)
end

TpLeft:Button("TP ke Mandi",string.format("X=%d Z=%d",MANDI.x,MANDI.z),goMandi)

TpLeft:Button("Posisi Saya","Cetak koordinat",
    function()
        local pos=getPos()
        if pos then
            notif("Posisi",string.format("X=%.1f  Y=%.1f  Z=%.1f",pos.X,pos.Y,pos.Z),6)
            print(string.format("[ XKID ] X=%.4f  Y=%.4f  Z=%.4f",pos.X,pos.Y,pos.Z))
        end
    end)

TpRight:Label("Simpan posisi sementara")
for i=1,5 do
    local idx=i
    TpRight:Button("Simpan Slot "..idx,"Simpan posisi ke slot "..idx,
        function()
            local cf=getCF()
            if not cf then notif("Gagal","Karakter tidak ada",3); return end
            savedPositions[idx]=cf
            local p=cf.Position
            notif("Slot "..idx,string.format("X=%.1f  Y=%.1f  Z=%.1f",p.X,p.Y,p.Z),3)
        end)
    TpRight:Button("Load Slot "..idx,"TP ke slot "..idx,
        function()
            if not savedPositions[idx] then notif("Gagal","Slot "..idx.." kosong",3); return end
            tpCFrame(savedPositions[idx])
            local p=savedPositions[idx].Position
            notif("Slot "..idx,string.format("X=%.1f  Y=%.1f  Z=%.1f",p.X,p.Y,p.Z),3)
        end)
end

-- ════════════════════════════════════════════════
--  TAB LOCATION
-- ════════════════════════════════════════════════
local LocPage  = TabLoc:Page("Save Location","map")
local LocLeft  = LocPage:Section("Lokasi Tetap","Left")
local LocRight = LocPage:Section("Lokasi Custom","Right")

LocLeft:Label("Lokasi Diketahui di Map")
for _,loc in ipairs(LOCATION_LIST) do
    local lc=loc
    LocLeft:Button("TP: "..lc.name,string.format("X=%.0f  Z=%.0f",lc.x,lc.z),
        function()
            task.spawn(function()
                local _,y=tpToXZ(lc.x,lc.z,lc.y)
                notif("TP "..lc.name,string.format("X=%.0f  Y=%.1f  Z=%.0f",lc.x,y,lc.z),3)
            end)
        end)
end

LocLeft:Button("Posisi Saya Sekarang","Cetak koordinat ke notif",
    function()
        local pos=getPos()
        if pos then
            notif("Posisi Saya",string.format("X=%.2f\nY=%.2f\nZ=%.2f",pos.X,pos.Y,pos.Z),8)
            print(string.format("[ XKID LOC ] X=%.4f  Y=%.4f  Z=%.4f",pos.X,pos.Y,pos.Z))
        end
    end)

local locNames={"Lokasi A","Lokasi B","Lokasi C","Lokasi D","Lokasi E"}
for i=1,5 do
    local idx=i
    LocRight:Button("Simpan "..locNames[idx],"Simpan posisi dengan nama ini",
        function()
            local cf=getCF()
            if not cf then notif("Gagal","Karakter tidak ada",3); return end
            savedLocations[idx]={name=locNames[idx],cf=cf}
            local p=cf.Position
            notif("Simpan "..locNames[idx],
                string.format("X=%.1f  Y=%.1f  Z=%.1f",p.X,p.Y,p.Z),4)
        end)
    LocRight:Button("TP ke "..locNames[idx],"Teleport ke lokasi yang disimpan",
        function()
            if not savedLocations[idx] then
                notif("Gagal",locNames[idx].." belum disimpan",3); return
            end
            tpCFrame(savedLocations[idx].cf)
            local p=savedLocations[idx].cf.Position
            notif("TP "..locNames[idx],
                string.format("X=%.1f  Y=%.1f  Z=%.1f",p.X,p.Y,p.Z),3)
        end)
end

-- ════════════════════════════════════════════════
--  TAB PETIR
-- ════════════════════════════════════════════════
local PetirPage  = TabPetir:Page("Penangkal Petir","cloud-lightning")
local PetirLeft  = PetirPage:Section("Perlindungan","Left")
local PetirRight = PetirPage:Section("Titik Aman","Right")

PetirLeft:Toggle("Penangkal Petir","PenangkalToggle",false,
    "HP lock + flee saat LightningStrike",
    function(v)
        _G.PenangkalPetir=v
        notif("Penangkal Petir",
            v and (fleePos and "ON — Titik Aman" or "ON — Naik Awan") or "OFF",3)
    end)

PetirLeft:Paragraph("Cara Kerja",
    "1. HP langsung penuh\n2. HP dikunci 8 detik\n3. Kabur ke titik aman\n4. Tunggu 5 detik\n5. Kembali otomatis\n\nIntercept: LightningStrike\nTrigger: data.Hit == true")

PetirLeft:Button("Test Petir","Simulasi flee",
    function()
        if not getRoot() then notif("Gagal","Karakter tidak ada",3); return end
        task.spawn(fleePetir)
    end)

PetirLeft:Button("Reset Counter","Reset hitungan kena petir",
    function() lightningHits=0; notif("Reset","Counter petir di-reset",2) end)

PetirRight:Button("Set Titik Aman","Simpan posisi sebagai titik flee",
    function()
        local cf=getCF()
        if not cf then notif("Gagal","Karakter tidak ada",3); return end
        fleePos=cf
        local p=cf.Position
        notif("Titik Aman OK",string.format("X=%.1f  Y=%.1f  Z=%.1f",p.X,p.Y,p.Z),5)
    end)

PetirRight:Button("Hapus Titik Aman","Kembali ke mode naik awan",
    function() fleePos=nil; notif("Mode Naik Awan","Titik aman dihapus",3) end)

PetirRight:Paragraph("Tips","Masuk ke dalam rumah\natau bangunan tertutup\nlalu klik Set Titik Aman")

-- ════════════════════════════════════════════════
--  TAB SETTING
-- ════════════════════════════════════════════════
local SetPage  = TabSet:Page("Setting","settings")
local SetLeft  = SetPage:Section("Umum","Left")
local SetRight = SetPage:Section("Info","Right")

SetLeft:Toggle("Notif Level Up","NLvUpToggle",true,
    "Tampilkan notif saat level naik",
    function(v) _G.NotifLevelUp=v end)

SetLeft:Toggle("Auto Confirm","AutoConfirmToggle",false,
    "Auto klik konfirmasi dialog",
    function(v) _G.AutoConfirm=v; notif("Auto Confirm",v and "ON" or "OFF",2) end)

SetLeft:Button("STOP SEMUA","Matikan semua fitur",stopSemua)

SetLeft:Button("Reset Stats","Reset semua hitungan sesi",
    function()
        totalEarned=0; harvestCount=0; levelUpCount=0; lightningHits=0; cycleCount=0
        notif("Reset","Stats sesi di-reset",2)
    end)

SetLeft:Button("Cek Storage","RequestStorage GET_BOTH_LISTS",
    function()
        task.spawn(function()
            local ok,res=invokeRF("RequestStorage","GET_BOTH_LISTS")
            if not ok then notif("Gagal","RequestStorage error",3); return end
            local data=unwrap(res)
            if not data then notif("Gagal","Data kosong",3); return end
            notif("Storage",
                "Inventory: "..(#(data.InventoryItems or {})).." item\n"..
                "Storage: "..(#(data.StorageItems or {})).." item\n"..
                "Koin: "..(data.Coins or 0),6)
        end)
    end)

SetLeft:Button("Lihat Stats Sesi","Total harvest, jual, cycle, petir",
    function()
        notif("Stats Sesi",
            "Cycle: "..cycleCount.."\n"..
            "Harvest: "..harvestCount.."\n"..
            "Koin: "..totalEarned.."\n"..
            "Level Up: "..levelUpCount.."\n"..
            "Petir: "..lightningHits, 8)
    end)

SetRight:Paragraph("Indo Farmer v22.0",
    "XKID HUB — Aurora UI\n\nFitur baru v22:\nAuto Farm Full Cycle\nESP Tanaman\nAuto Beli Bibit\nSpeed & Fly\nAnti Kick visual\n\nTotal Tab: 12")

SetRight:Paragraph("Koordinat Map",
    "Penjual  X=-59  Z=-207\nBibit    X=-42  Z=-207\nAlat     X=-41.5 Y=49.2 Z=-180.8\nSawit    X=56   Z=-208\nTelur    X=-98  Z=-176\nMandi    X=137  Z=-235")

-- ════════════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════════════
setupIntercepts()

Library:Notification("Indo Farmer v22",
    "Welcome "..LP.Name.."!\nFull Cycle · ESP · Fly · Anti Kick", 6)
Library:ConfigSystem(Win)

print("[ XKID ] Indo Farmer v22.0 loaded — "..LP.Name)
