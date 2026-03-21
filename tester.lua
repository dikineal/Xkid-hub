--[[
╔═══════════════════════════════════════════════════════════╗
║       🌾  X K I D  |  S A W A H  I N D O  V.2           ║
║                Aurora UI  ·  Indo Farmer                 ║
╠═══════════════════════════════════════════════════════════╣
║  Farm · Harvest · Shop · Teleport · Player · Security    ║
╚═══════════════════════════════════════════════════════════╝
]]

-- ┌─────────────────────────────────────────────────────────┐
-- │                    AURORA UI                            │
-- └─────────────────────────────────────────────────────────┘
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ┌─────────────────────────────────────────────────────────┐
-- │                    SERVICES                             │
-- └─────────────────────────────────────────────────────────┘
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local VirtualUser= game:GetService("VirtualUser")
local TpService  = game:GetService("TeleportService")
local Workspace  = game:GetService("Workspace")
local RS         = game:GetService("ReplicatedStorage")
local LP         = Players.LocalPlayer

-- ┌─────────────────────────────────────────────────────────┐
-- │                    REMOTES                              │
-- └─────────────────────────────────────────────────────────┘
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
local function fireEv(name,...) local r=getR(name); if not r then return false end; return pcall(function(...) r:FireServer(...) end,...) end
local function invokeRF(name,...) local r=getR(name); if not r then return false,nil end; return pcall(function(...) return r:InvokeServer(...) end,...) end
local function unwrap(res) if type(res)=="table" then return type(res[1])=="table" and res[1] or res end; return nil end

-- ┌─────────────────────────────────────────────────────────┐
-- │                    HELPERS                              │
-- └─────────────────────────────────────────────────────────┘
local function getChar() return LP.Character end
local function getRoot() local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getPos()  local r=getRoot(); return r and r.Position end
local function getCF()   local r=getRoot(); return r and r.CFrame  end

local function notify(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
    print(string.format("[XKID SAWAH] %s | %s", t, tostring(b)))
end

-- Raycast Y
local function raycastY(x, z)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local ch = getChar(); if ch then rp.FilterDescendantsInstances={ch} end
    local res = Workspace:Raycast(Vector3.new(x,500,z), Vector3.new(0,-1000,0), rp)
    return res and (res.Position.Y+3) or 42
end

-- Raycast ground dari posisi karakter
local function getGroundPos()
    local hrp = getRoot(); if not hrp then return nil end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {getChar()}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local res = Workspace:Raycast(hrp.Position, Vector3.new(0,-15,0), rp)
    if res then return res.Position end
    return Vector3.new(hrp.Position.X, hrp.Position.Y-3, hrp.Position.Z)
end

local function tpTo(pos)
    local hrp = getRoot(); if not hrp then return end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
    task.wait(0.2)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                    STATE                                │
-- └─────────────────────────────────────────────────────────┘
local PlayerData     = { Coins=0, Level=1, XP=0, Needed=50 }
local totalEarned    = 0
local harvestCount   = 0
local levelUpCount   = 0
local lightningHits  = 0
local isPetirActive  = false
local petirReturnCF  = nil
local godConn        = nil
local fleePos        = nil
local savedPositions = {nil,nil,nil,nil,nil}

-- ┌─────────────────────────────────────────────────────────┐
-- │                    DATA                                 │
-- └─────────────────────────────────────────────────────────┘
local CROP_SELL = {"Padi","Jagung","Tomat","Terong","Strawberry","Sawit","Durian"}
local CROP_NAMES = CROP_SELL

local ITEM_LIST = {
    {name="Padi",price=10},{name="Jagung",price=20},
    {name="Tomat",price=30},{name="Terong",price=50},{name="Strawberry",price=75},
}

local BIBIT_LIST = {
    {name="Bibit Padi",price=5,minLv=1},{name="Bibit Jagung",price=15,minLv=20},
    {name="Bibit Tomat",price=25,minLv=40},{name="Bibit Terong",price=40,minLv=60},
    {name="Bibit Strawberry",price=60,minLv=80},{name="Bibit Sawit",price=1000,minLv=80},
    {name="Bibit Durian",price=2000,minLv=120},
}
local bibitNames={}; for _,b in ipairs(BIBIT_LIST) do table.insert(bibitNames,b.name) end

local NPC_LIST = {
    {label="NPC Penjual",       x=-59,   y=nil,  z=-207  },
    {label="NPC Bibit",         x=-42,   y=nil,  z=-207  },
    {label="NPC Alat",          x=-41.5, y=49.2, z=-180.8},
    {label="NPC Pedagang Sawit",x= 56,   y=nil,  z=-208  },
    {label="NPC Pedagang Telur",x=-98,   y=nil,  z=-176  },
}
local MANDI = {x=137, z=-235}

local NpcScanResult = {}
local NPC_OVERRIDE  = {}
local NPC_KEYWORDS  = {"npc","pedagang","penjual","bibit","alat","toko","shop","vendor","seller"}

-- ┌─────────────────────────────────────────────────────────┐
-- │                  CONFIG                                 │
-- └─────────────────────────────────────────────────────────┘
local Config = {
    PlantDelay=0.5, SellDelay=2, SellAmount=999,
    AutoPlant=false, AutoSell=false, AutoBuy=false,
    BuyDelay=1, BuyAmount=10, SelectedSeedIndex=1,
    TpToPlot=true,
}
local selectedBibit = "Bibit Padi"
local jumlahBeli    = 1

-- ┌─────────────────────────────────────────────────────────┐
-- │                  PLOT MANAGER                           │
-- └─────────────────────────────────────────────────────────┘
local PlotPositions = {}

-- ┌─────────────────────────────────────────────────────────┐
-- │                  SHOP / SEED DATA                       │
-- └─────────────────────────────────────────────────────────┘
local ShopSeeds    = {}
local ShopDropdown = {}

local function fetchShopSeeds()
    ShopSeeds={}; ShopDropdown={}
    local ok, res = invokeRF("RequestShop","GET_LIST")
    if ok and type(res)=="table" then
        local data = unwrap(res) or res
        if type(data)=="table" then
            local seeds = data.Seeds or data.seeds or data.Items or data.items or data
            if type(seeds)=="table" then
                for i,seed in ipairs(seeds) do
                    if type(seed)=="table" then
                        local name  = seed.Name or seed.name or tostring(i)
                        local price = seed.Price or seed.price or "?"
                        local label = string.format("[%d] %s — %s koin",i,tostring(name),tostring(price))
                        table.insert(ShopSeeds,{index=i,name=name,price=price,label=label})
                        table.insert(ShopDropdown,label)
                    end
                end
            end
        end
    end
    if #ShopSeeds==0 then
        for i,name in ipairs({"Bibit Padi","Bibit Jagung","Bibit Tomat","Bibit Terong","Bibit Strawberry","Bibit Sawit","Bibit Durian"}) do
            table.insert(ShopSeeds,{index=i,name=name,label=name})
            table.insert(ShopDropdown,name)
        end
    end
    print(string.format("[XKID SAWAH] Shop: %d seed", #ShopSeeds))
end
fetchShopSeeds()

-- ┌─────────────────────────────────────────────────────────┐
-- │                  FARMING FUNCTIONS                      │
-- └─────────────────────────────────────────────────────────┘
-- Tanam pakai PlantCrop:FireServer(Vector3)
local PlantRemote = RS:WaitForChild("Remotes"):WaitForChild("TutorialRemotes"):WaitForChild("PlantCrop")
local SellRemote  = RS:WaitForChild("Remotes"):WaitForChild("TutorialRemotes"):WaitForChild("RequestSell")

-- Auto Plant loop
task.spawn(function()
    while true do
        task.wait(Config.PlantDelay)
        if Config.AutoPlant and #PlotPositions>0 then
            for _,pos in ipairs(PlotPositions) do
                if not Config.AutoPlant then break end
                pcall(function()
                    if Config.TpToPlot then tpTo(pos) end
                    PlantRemote:FireServer(pos)
                end)
                task.wait(0.15)
            end
        end
    end
end)

-- Auto Sell loop
local SellLoop = nil
task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        if Config.AutoSell then
            for _,crop in ipairs(CROP_SELL) do
                if not Config.AutoSell then break end
                pcall(function() SellRemote:InvokeServer("SELL",crop,Config.SellAmount) end)
                task.wait(0.08)
            end
        end
    end
end)

-- Auto Buy loop
task.spawn(function()
    while true do
        task.wait(Config.BuyDelay)
        if Config.AutoBuy then
            pcall(function()
                local seed=ShopSeeds[Config.SelectedSeedIndex]; if not seed then return end
                local ok,res=pcall(function() return invokeRF("RequestShop","BUY",seed.name,Config.BuyAmount) end)
                if not ok or (type(res)=="table" and res.Success==false) then
                    pcall(function() invokeRF("RequestShop","BUY",seed.index,Config.BuyAmount) end)
                end
            end)
        end
    end
end)

-- Harvest via firesignal
local HarvestLoop = nil
local function harvestViaSignal()
    local Event=getR("HarvestCrop"); if not Event then notify("❌","HarvestCrop tidak ada",4); return 0 end
    local count=0
    for _,cropName in ipairs(CROP_NAMES) do
        pcall(function() firesignal(Event.OnClientEvent,cropName,1,cropName) end)
        harvestCount=harvestCount+1; count=count+1
        task.wait(0.3)
    end
    return count
end

-- Jual semua
local function getInventoryJual()
    local ok,res=invokeRF("RequestSell","GET_LIST"); if not ok then return nil end
    local data=unwrap(res)
    if data then PlayerData.Coins=data.Coins or PlayerData.Coins end
    return data
end

local function jualItem(nama,qty)
    local ok,res=invokeRF("RequestSell","SELL",nama,qty or 1); if not ok then return false,"Remote gagal",0 end
    local data=unwrap(res)
    if data and data.Success then
        local earned=data.Earned or 0
        PlayerData.Coins=data.NewCoins or PlayerData.Coins
        totalEarned=totalEarned+earned
        return true,data.Message or "Terjual",earned
    end
    return false,(data and data.Message) or "Gagal",0
end

local function jualSemua()
    local data=getInventoryJual()
    if not data or not data.Items then return false,"GET_LIST gagal" end
    local totalItem,totalCoin=0,0
    for _,item in ipairs(data.Items) do
        if item.Owned and item.Owned>0 and (item.Price or 0)>0 then
            local ok=jualItem(item.Name,item.Owned)
            if ok then totalItem=totalItem+item.Owned; totalCoin=totalCoin+((item.Price or 0)*item.Owned) end
            task.wait(0.3)
        end
    end
    if totalItem==0 then return false,"Tidak ada item" end
    return true,totalItem.." item | +"..totalCoin.."💰"
end

local function beliBibit(nama,qty)
    local ok,res=invokeRF("RequestShop","BUY",nama or selectedBibit,qty or jumlahBeli)
    if not ok then return false,"RequestShop gagal" end
    local data=unwrap(res)
    if data and data.Success then PlayerData.Coins=data.NewCoins or PlayerData.Coins; return true,data.Message or "Berhasil" end
    return false,(data and data.Message) or "Gagal"
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                  SCAN NPC                               │
-- └─────────────────────────────────────────────────────────┘
local function nameMatchNPC(n)
    n=n:lower(); for _,kw in ipairs(NPC_KEYWORDS) do if n:find(kw) then return true end end; return false
end

local function scanAllNPC()
    NpcScanResult={}; local seen={}
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and not seen[v] then
            seen[v]=true
            local hasHum=v:FindFirstChildOfClass("Humanoid")~=nil
            local rootPart=v:FindFirstChild("HumanoidRootPart") or v.PrimaryPart
            if (hasHum or nameMatchNPC(v.Name)) and rootPart then
                table.insert(NpcScanResult,{
                    name=v.Name, x=math.floor(rootPart.Position.X*10+0.5)/10,
                    y=rootPart.Position.Y, z=math.floor(rootPart.Position.Z*10+0.5)/10,
                    model=v, cf=rootPart.CFrame,
                })
            end
        end
    end
    table.sort(NpcScanResult,function(a,b) return a.name<b.name end)
    return NpcScanResult
end

local function buildNPCOverride()
    NPC_OVERRIDE={}; if #NpcScanResult==0 then return end
    for _,npc in ipairs(NPC_LIST) do
        local bestDist,bestCF=math.huge,nil
        for _,found in ipairs(NpcScanResult) do
            local d=math.sqrt((found.x-npc.x)^2+(found.z-npc.z)^2)
            if d<bestDist then bestDist=d; bestCF=found.cf end
        end
        if bestCF and bestDist<=40 then NPC_OVERRIDE[npc.label]=bestCF end
    end
end

local function tpToNPC(x,z,label,hardY)
    local root=getRoot(); if not root then return false,0 end
    if label and NPC_OVERRIDE[label] then
        root.CFrame=NPC_OVERRIDE[label]*CFrame.new(0,0,3); task.wait(0.35)
        return true,NPC_OVERRIDE[label].Position.Y
    end
    if hardY then root.CFrame=CFrame.new(x,hardY,z); task.wait(0.35); return true,hardY end
    local y=raycastY(x,z); root.CFrame=CFrame.new(x,y,z); task.wait(0.35); return true,y
end

local function goMandi() tpToNPC(MANDI.x,MANDI.z); notify("🚿 Mandi","TP ke area mandi",2) end

-- ┌─────────────────────────────────────────────────────────┐
-- │                  PENANGKAL PETIR                        │
-- └─────────────────────────────────────────────────────────┘
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
    local root=getRoot(); if not root then isPetirActive=false; return end
    local hum=getHum(); if hum then hum.Health=hum.MaxHealth end
    petirReturnCF=root.CFrame; startHpLock(8)
    if fleePos then
        root.CFrame=fleePos
        notify("⚡ Kabur! #"..lightningHits,"→ Titik aman | kembali 5s",5)
    else
        local pos=root.Position
        root.CFrame=CFrame.new(pos.X,pos.Y+350,pos.Z)
        notify("⚡ Kabur! #"..lightningHits,"→ Naik awan | kembali 5s",5)
    end
    task.wait(5)
    local r2=getRoot()
    if r2 and petirReturnCF then r2.CFrame=petirReturnCF; notify("✅ Kembali","Balik ke posisi",2) end
    task.wait(0.5); isPetirActive=false
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                  MOVEMENT                               │
-- └─────────────────────────────────────────────────────────┘
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
    else if Move.jumpConn then Move.jumpConn:Disconnect(); Move.jumpConn=nil end end
end

-- Fly (dari XKID HUB v5.20)
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
    flyBV.MaxForce=Vector3.new(1e6,1e6,1e6); flyBV.Velocity=Vector3.zero
    flyBG=Instance.new("BodyGyro",root)
    flyBG.MaxTorque=Vector3.new(1e6,1e6,1e6); flyBG.P=1e5; flyBG.D=1e3
    flyConn=RunService.RenderStepped:Connect(function(dt)
        local r2=getRoot(); if not r2 then return end
        local h2=getHum(); if not h2 then return end
        local cam=Workspace.CurrentCamera; local cf=cam.CFrame
        h2.PlatformStand=true; h2:ChangeState(Enum.HumanoidStateType.Physics)
        local md=getMoveVector()
        local look=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
        local right=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z)
        if look.Magnitude>0 then look=look.Unit end
        if right.Magnitude>0 then right=right.Unit end
        local move=right*md.X+look*(-md.Z)
        if move.Magnitude>1 then move=move.Unit end
        local pitch=cf.LookVector.Y; local vVel=0
        if math.abs(pitch)>0.25 then
            local t=math.clamp((math.abs(pitch)-0.25)/(1-0.25),0,1)
            vVel=math.sign(pitch)*t*Move.flySpeed*0.6
        end
        local target=Vector3.new(move.X*Move.flySpeed,vVel,move.Z*Move.flySpeed)
        target=target+Vector3.new(0,Workspace.Gravity*dt,0)
        if move.Magnitude>0 or math.abs(vVel)>0.1 then flyBV.Velocity=target
        else flyBV.Velocity=Vector3.new(0,Workspace.Gravity*dt,0) end
        local flatLook=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
        if flatLook.Magnitude>0.01 then flyBG.CFrame=CFrame.lookAt(r2.Position,r2.Position+flatLook) end
    end)
end

local function stopFly()
    flyFlying=false
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV=nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG=nil end
    local hum=getHum()
    if hum then
        hum.PlatformStand=false; hum.AutoRotate=true; hum.WalkSpeed=Move.speed
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        task.defer(function()
            local h=getHum(); if h then h.PlatformStand=false; h.WalkSpeed=Move.speed; h:ChangeState(Enum.HumanoidStateType.Running) end
        end)
    end
end

-- TP ke Player
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

-- Respawn
local Respawn={savedPosition=nil,busy=false}
RunService.Heartbeat:Connect(function() local r=getRoot(); if r then Respawn.savedPosition=r.CFrame end end)

local function doRespawn()
    if Respawn.busy then notify("Respawn","Sedang proses...",2); return end
    if not Respawn.savedPosition then notify("Respawn","Posisi belum tersimpan!",2); return end
    Respawn.busy=true; local savedCF=Respawn.savedPosition
    local hum=getHum(); if hum then hum.Health=0 end
    local newChar=LP.CharacterAdded:Wait(); task.wait(1)
    local hrp=newChar:WaitForChild("HumanoidRootPart",5)
    if hrp then hrp.CFrame=savedCF; notify("✅ Respawn","Kembali ke posisi!",2) end
    Respawn.busy=false
end

LP.CharacterAdded:Connect(function()
    task.wait(0.6)
    if flyFlying then
        flyFlying=false
        if flyConn then flyConn:Disconnect(); flyConn=nil end
        if flyBV then pcall(function() flyBV:Destroy() end); flyBV=nil end
        if flyBG then pcall(function() flyBG:Destroy() end); flyBG=nil end
        task.wait(0.3); startFly()
    end
    if Move.noclip and not Move.noclipConn then
        Move.noclipConn=RunService.Stepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end)
    end
end)

-- ESP Player
local ESPPl={active=false,data={},conn=nil}
local function _mkPlBill(p)
    if p==LP or ESPPl.data[p] then return end
    if not p.Character then return end
    local head=p.Character:FindFirstChild("Head"); if not head then return end
    local bill=Instance.new("BillboardGui")
    bill.Name="XKID_PESP"; bill.Size=UDim2.new(0,100,0,24)
    bill.StudsOffset=Vector3.new(0,2.5,0); bill.AlwaysOnTop=true
    bill.Adornee=head; bill.Parent=head
    local bg=Instance.new("Frame",bill); bg.Size=UDim2.new(1,0,1,0)
    bg.BackgroundColor3=Color3.fromRGB(0,0,0); bg.BackgroundTransparency=0.45; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,4)
    local lbl=Instance.new("TextLabel",bg); lbl.Size=UDim2.new(1,-4,1,-4); lbl.Position=UDim2.new(0,2,0,2)
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
            else if myR and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist=math.floor((p.Character.HumanoidRootPart.Position-myR.Position).Magnitude)
                d.lbl.Text=p.Name.."\n"..dist.."m"
            else d.lbl.Text=p.Name end end
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
    p.CharacterAdded:Connect(function() task.wait(0.5); if ESPPl.active then _rmPlBill(p); _mkPlBill(p) end end)
end

-- Intercepts
local function setupIntercepts()
    -- Petir
    task.spawn(function()
        local r; for i=1,25 do r=getR("LightningStrike"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function() if not _G.PenangkalPetir then return end; task.spawn(fleePetir) end)
    end)
    -- Level Up
    task.spawn(function()
        local r; for i=1,15 do r=getR("UpdateLevel"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
            if type(data)~="table" then return end
            PlayerData.Level=data.Level or PlayerData.Level
            PlayerData.XP=data.XP or PlayerData.XP
            PlayerData.Needed=data.Needed or PlayerData.Needed
            if data.LeveledUp then
                levelUpCount=levelUpCount+1
                notify("🎉 Level Up! #"..levelUpCount,"Level "..data.Level,6)
            end
        end)
    end)
    -- Notif game
    task.spawn(function()
        local r; for i=1,15 do r=getR("Notification"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(msg)
            if type(msg)~="string" then return end
            local ml=msg:lower()
            if ml:find("hujan") then notify("🌧 Hujan!","Tanaman tumbuh lebih cepat",4)
            elseif ml:find("petir") or ml:find("gosong") then notify("⚡ Petir!",msg,4)
            elseif ml:find("mandi") or ml:find("kotor") then
                notify("🚿 Perlu Mandi!",msg,4)
                if _G.AutoMandi then task.delay(0.5,goMandi) end
            end
        end)
    end)
    print("[XKID SAWAH] Intercepts ready")
end

_G.PenangkalPetir=false; _G.AntiAFK=false; _G.AutoMandi=false

-- Anti AFK
local antiAFKConn=nil
local function startAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect() end
    local last=tick()
    antiAFKConn=RunService.Heartbeat:Connect(function()
        if not _G.AntiAFK then antiAFKConn:Disconnect(); antiAFKConn=nil; return end
        if tick()-last>=120 then last=tick(); local h=getHum(); if h then h.Jump=true end end
    end)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                  WINDOW & TABS                          │
-- └─────────────────────────────────────────────────────────┘
local Win=Library:Window("XKID | SAWAH INDO","sprout","V.2",false)
Win:TabSection("FARMING")
local TFarm=Win:Tab("Farm","leaf")
local THarv=Win:Tab("Harvest","scissors")
local TShop=Win:Tab("Shop","shopping-cart")
Win:TabSection("UTILITY")
local TTP  =Win:Tab("Teleport","map-pin")
local TPl  =Win:Tab("Player","user")
local TSec =Win:Tab("Security","shield")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB FARM                            ║
-- ╚═══════════════════════════════════════════════════════╝
local FP=TFarm:Page("Farming","leaf")
local FL=FP:Section("📍 Plot Manager","Left")
local FR=FP:Section("🌾 Auto Farm","Right")

FL:Label("📍 Plot Manager")
FL:Button("➕ Add Plot","Berdiri di plot lalu klik",
    function()
        local pos=getGroundPos()
        if pos then
            table.insert(PlotPositions,pos)
            notify("Plot #"..#PlotPositions,string.format("X=%.1f Y=%.1f Z=%.1f",pos.X,pos.Y,pos.Z),3)
        else notify("Error","Karakter tidak ada!",3) end
    end)
FL:Button("➖ Remove Terakhir","Hapus plot terakhir",
    function()
        if #PlotPositions>0 then
            local r=table.remove(PlotPositions,#PlotPositions)
            notify("Removed","Sisa: "..#PlotPositions.." | X="..math.floor(r.X).." Z="..math.floor(r.Z),3)
        else notify("Plot","Tidak ada plot!",2) end
    end)
FL:Button("🗑 Clear Semua Plot","Hapus semua posisi",
    function() local n=#PlotPositions; PlotPositions={}; notify("Clear","Semua "..n.." plot dihapus",2) end)
FL:Button("📋 Lihat Plot","Tampilkan daftar posisi",
    function()
        if #PlotPositions==0 then notify("Plot","Belum ada plot!",3); return end
        local txt=#PlotPositions.." plot:\n"
        for i,pos in ipairs(PlotPositions) do
            txt=txt..string.format("[%d] X=%.1f Z=%.1f\n",i,pos.X,pos.Z)
            if i>=8 then txt=txt.."...dst"; break end
        end
        notify("Plot List",txt,10)
    end)
FL:Button("🌱 Tanam Sekarang","Tanam 1x ke semua plot",
    function()
        if #PlotPositions==0 then notify("Tanam","Tambah plot dulu!",3); return end
        task.spawn(function()
            local count=0
            for _,pos in ipairs(PlotPositions) do
                pcall(function()
                    if Config.TpToPlot then tpTo(pos) end
                    PlantRemote:FireServer(pos); count=count+1
                end); task.wait(0.15)
            end
            notify("Tanam","✅ "..count.." plot ditanam!",3)
        end)
    end)
FL:Toggle("TP ke Plot sebelum tanam","tpPlot",true,"Teleport ke plot sebelum FireServer",
    function(v) Config.TpToPlot=v end)

FR:Label("🔄 Auto Farm")
FR:Toggle("Auto Plant","autoPlant",false,"Tanam terus ke semua plot",
    function(v)
        Config.AutoPlant=v
        if v and #PlotPositions==0 then notify("Auto Plant","⚠ Tambah plot dulu!",4); Config.AutoPlant=false; return end
        notify("Auto Plant",v and "ON — "..#PlotPositions.." plot" or "OFF",3)
    end)
FR:Slider("Plant Delay (s)","plantDelay",0.1,5,0.5,function(v) Config.PlantDelay=v end,"Jeda antar cycle")
FR:Toggle("Auto Sell","autoSell",false,"Jual semua crop otomatis",
    function(v) Config.AutoSell=v; notify("Auto Sell",v and "ON" or "OFF",2) end)
FR:Slider("Sell Interval (s)","sellDelay",0.5,10,2,function(v) Config.SellDelay=v end,"Jeda antar jual")
FR:Button("💰 Jual Sekarang","Jual semua crop sekarang",
    function()
        task.spawn(function()
            for _,crop in ipairs(CROP_SELL) do
                pcall(function() SellRemote:InvokeServer("SELL",crop,999) end); task.wait(0.08)
            end
            notify("Sell","✅ Semua crop dijual!",3)
        end)
    end)

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB HARVEST                          ║
-- ╚═══════════════════════════════════════════════════════╝
local HP2=THarv:Page("Harvest","scissors")
local HL=HP2:Section("🌾 Harvest Control","Left")
local HR=HP2:Section("ℹ Info","Right")

HL:Toggle("Auto Harvest (10s)","autoHarv",false,"Harvest semua tanaman tiap 10 detik",
    function(v)
        if v then
            HarvestLoop=task.spawn(function()
                while v do
                    local c=harvestViaSignal(); if c>0 then notify("🌾 Harvest",c.." sinyal",2) end
                    task.wait(10)
                end
            end)
            notify("Auto Harvest","ON — tiap 10s",3)
        else
            if HarvestLoop then pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil end
            notify("Auto Harvest","OFF | Total: "..harvestCount,3)
        end
    end)
HL:Button("🌾 Harvest Sekarang","Kirim firesignal harvest semua",
    function()
        task.spawn(function()
            notify("Harvest","Mengirim sinyal...",2)
            local c=harvestViaSignal(); notify("✅ Harvest","Sinyal: "..c.." tanaman",3)
        end)
    end)
HL:Button("🗑 Reset Counter","Reset hitungan panen",
    function() harvestCount=0; notify("Reset","Counter panen di-reset",2) end)

HR:Paragraph("Tanaman Didukung","Padi · Jagung · Tomat · Terong\nStrawberry · Sawit · Durian\n\nDelay: 0.3s antar tanaman")
HR:Paragraph("Info","Harvest via firesignal ke\nHarvestCrop.OnClientEvent")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB SHOP                            ║
-- ╚═══════════════════════════════════════════════════════╝
local SP=TShop:Page("Shop","shopping-cart")
local SL=SP:Section("🛒 Beli Bibit","Left")
local SR=SP:Section("⚙ Setting","Right")

SL:Dropdown("Pilih Bibit","bibitDrop",bibitNames,
    function(val) selectedBibit=val; notify("Bibit",val.." dipilih",2) end,"Pilih jenis bibit")
SL:Slider("Jumlah Beli","beliQty",1,99,1,function(v) jumlahBeli=v end,"Jumlah per transaksi")
SL:Button("🛒 Beli Sekarang","Beli bibit yang dipilih",
    function()
        task.spawn(function()
            local ok,msg=beliBibit(selectedBibit,jumlahBeli)
            notify(ok and "✅ Beli" or "❌ Gagal",msg,4)
        end)
    end)
SL:Button("📋 Cek Stok Bibit","Lihat stok di toko",
    function()
        task.spawn(function()
            local ok,res=invokeRF("RequestShop","GET_LIST")
            if not ok then notify("❌","Gagal",3); return end
            local data=unwrap(res)
            if not data or not data.Seeds then notify("❌","Data kosong",3); return end
            local txt="💰 "..tostring(data.Coins).."\n\n"
            for _,s in ipairs(data.Seeds) do
                txt=txt..(s.Locked and "🔒 " or "✅ ")..s.Name.."  x"..s.Owned.."  ("..s.Price.."💰)\n"
            end
            notify("🛒 Bibit Shop",txt,10)
        end)
    end)

for _,b in ipairs(BIBIT_LIST) do
    local bb=b
    SL:Button(bb.name.."  "..bb.price.."💰","Min Lv "..bb.minLv,
        function()
            task.spawn(function()
                selectedBibit=bb.name; local ok,msg=beliBibit(bb.name,jumlahBeli)
                notify(ok and "✅ Beli" or "❌",msg,3)
            end)
        end)
end

SR:Toggle("Auto Buy Seed","autoBuy",false,"Beli bibit otomatis",
    function(v) Config.AutoBuy=v; notify("Auto Buy",v and "ON" or "OFF",2) end)
SR:Slider("Jumlah Beli (Auto)","buyAmt",1,100,10,function(v) Config.BuyAmount=v end,"Per transaksi")
SR:Slider("Buy Interval (s)","buyDelay",0.5,10,1,function(v) Config.BuyDelay=v end,"Jeda auto buy")
SR:Button("💰 Jual Semua (Inventory)","Jual via GET_LIST + SELL",
    function()
        task.spawn(function()
            local ok,msg=jualSemua(); notify(ok and "💰 ✅" or "❌",msg,4)
        end)
    end)

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB TELEPORT                         ║
-- ╚═══════════════════════════════════════════════════════╝
local TPG=TTP:Page("Teleport","map-pin")
local TPL=TPG:Section("🚀 NPC & Player","Left")
local TPR=TPG:Section("🔍 Scan & Save","Right")

-- Tombol per player
local playerBtns={}
local function addPlayerBtn(p)
    if p==LP or playerBtns[p] then return end
    playerBtns[p]=TPL:Button("🚀 "..p.Name,"TP ke "..p.Name,
        function()
            local root=getRoot(); if not root then return end
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                root.CFrame=p.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,3)
                notify("TP","→ "..p.Name,2)
            end
        end)
end
for _,p in pairs(Players:GetPlayers()) do addPlayerBtn(p) end
Players.PlayerAdded:Connect(function(p) task.wait(0.5); addPlayerBtn(p) end)
Players.PlayerRemoving:Connect(function(p) playerBtns[p]=nil end)

-- NPC buttons
TPL:Label("── NPC ──")
for _,npc in ipairs(NPC_LIST) do
    local n=npc
    TPL:Button("📍 "..n.label,string.format("X=%.0f Z=%.0f",n.x,n.z),
        function()
            task.spawn(function()
                tpToNPC(n.x,n.z,n.label,n.y)
                notify("TP NPC",n.label,2)
            end)
        end)
end
TPL:Button("🚿 Mandi",string.format("X=%d Z=%d",MANDI.x,MANDI.z),goMandi)
TPL:Toggle("Auto Mandi","autoMandi",false,"TP mandi saat notif kotor",
    function(v) _G.AutoMandi=v; notify("Auto Mandi",v and "ON" or "OFF",2) end)
TPL:Button("📌 Posisi Saya","Koordinat sekarang",
    function()
        local pos=getPos()
        if pos then notify("📌 Posisi",string.format("X=%.1f Y=%.1f Z=%.1f",pos.X,pos.Y,pos.Z),6) end
    end)

-- Ketik nama player
local tpInput=""
TPR:TextBox("Ketik Nama Player","tpInput","",function(v) tpInput=v end,"1-2 huruf prefix")
TPR:Button("🔍 TP via Nama","Cari & TP ke player",function() tpToPlayer(tpInput) end)

-- Scan NPC
TPR:Label("── Scan NPC ──")
TPR:Button("🔍 Scan Semua NPC","Scan workspace untuk TP akurat",
    function()
        task.spawn(function()
            notify("Scan","Sedang scan...",2)
            local found=scanAllNPC(); buildNPCOverride()
            if #found==0 then notify("⚠ Scan","Tidak ada NPC!",5); return end
            local matched=0
            for _,npc in ipairs(NPC_LIST) do if NPC_OVERRIDE[npc.label] then matched=matched+1 end end
            notify("✅ Scan",#found.." NPC | "..matched.."/"..#NPC_LIST.." match",5)
        end)
    end)
TPR:Button("🗑 Reset Override","Kembali ke koordinat hardcode",
    function() NPC_OVERRIDE={}; NpcScanResult={}; notify("Reset","Override dihapus",2) end)

-- Save/Load lokasi
TPR:Label("── Save Lokasi ──")
for i=1,5 do
    local idx=i
    TPR:Button("💾 Save Slot "..idx,"Simpan posisi ke slot "..idx,
        function()
            local cf=getCF(); if not cf then notify("❌","Karakter tidak ada",2); return end
            savedPositions[idx]=cf; local p=cf.Position
            notify("💾 Slot "..idx,string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z),3)
        end)
    TPR:Button("🚀 Load Slot "..idx,"TP ke slot "..idx,
        function()
            if not savedPositions[idx] then notify("❌","Slot "..idx.." kosong",2); return end
            local root=getRoot(); if root then root.CFrame=savedPositions[idx]; notify("📍 Slot "..idx,"Teleport!",2) end
        end)
end

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB PLAYER                          ║
-- ╚═══════════════════════════════════════════════════════╝
local PP=TPl:Page("Player","user")
local PL=PP:Section("⚡ Speed & Jump","Left")
local PR=PP:Section("🚀 Fly & ESP","Right")

PL:Slider("Walk Speed","ws",16,500,16,
    function(v) Move.speed=v; if not flyFlying then local h=getHum(); if h then h.WalkSpeed=v end end end,"Default 16")
PL:Button("Reset Speed","Ke 16",
    function() Move.speed=16; local h=getHum(); if h and not flyFlying then h.WalkSpeed=16 end; notify("Speed","Reset 16",2) end)
PL:Slider("Jump Power","jp",50,500,50,
    function(v) local h=getHum(); if h then h.JumpPower=v; h.UseJumpPower=true end end,"Default 50")
PL:Toggle("Infinite Jump","infJump",false,"Lompat terus",
    function(v) setInfJump(v); notify("Inf Jump",v and "ON" or "OFF",2) end)
PL:Toggle("NoClip","noclip",false,"Tembus dinding",
    function(v) setNoclip(v); notify("NoClip",v and "ON" or "OFF",2) end)

PR:Toggle("Fly","fly",false,"Terbang bebas (Joystick+Kamera)",
    function(v) if v then startFly() else stopFly() end; notify("Fly",v and "ON" or "OFF",2) end)
PR:Slider("Fly Speed","flySpd",10,300,60,
    function(v) Move.flySpeed=v end,"Kecepatan terbang")
PR:Toggle("ESP Player","espPl",false,"Nama + jarak player lain",
    function(v) ESPPl.active=v; if v then startESPPlayer() else stopESPPlayer() end; notify("ESP Player",v and "ON" or "OFF",2) end)
PR:Paragraph("Cara Fly",
    "Mobile: Joystick=gerak\nKamera atas=naik\nKamera bawah=turun\n\nPC: W/A/S/D + Mouse")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB SECURITY                         ║
-- ╚═══════════════════════════════════════════════════════╝
local SecP=TSec:Page("Security","shield")
local SecL=SecP:Section("🛡 Perlindungan","Left")
local SecR=SecP:Section("ℹ Info","Right")

SecL:Toggle("Anti AFK","antiAfk",false,"Cegah disconnect idle",
    function(v)
        _G.AntiAFK=v; if v then startAntiAFK() end
        notify("Anti AFK",v and "ON" or "OFF",2)
    end)

local antiKickConn=nil
SecL:Toggle("Anti Kick","antiKick",false,"HP dikunci < 15%",
    function(v)
        if v then
            if antiKickConn then antiKickConn:Disconnect() end
            antiKickConn=RunService.Heartbeat:Connect(function()
                local h=getHum(); if h and h.Health>0 and h.Health<h.MaxHealth*0.15 then h.Health=h.MaxHealth end
            end)
        else if antiKickConn then antiKickConn:Disconnect(); antiKickConn=nil end end
        notify("Anti Kick",v and "ON" or "OFF",2)
    end)

SecL:Toggle("Penangkal Petir","petir",false,"HP lock + flee saat petir",
    function(v)
        _G.PenangkalPetir=v
        notify("⚡ Penangkal",v and (fleePos and "ON — Titik Aman" or "ON — Naik Awan") or "OFF",3)
    end)
SecL:Button("📍 Set Titik Aman","Simpan posisi sebagai titik flee",
    function()
        local cf=getCF()
        if cf then fleePos=cf; local p=cf.Position
            notify("✅ Titik Aman",string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z),5)
        else notify("❌","Karakter tidak ada",3) end
    end)
SecL:Button("🗑 Hapus Titik Aman","Kembali ke mode naik awan",
    function() fleePos=nil; notify("Mode Awan","Titik aman dihapus",3) end)
SecL:Button("⚡ Test Petir","Simulasi flee",
    function() if not getRoot() then notify("❌","Karakter tidak ada",3); return end; task.spawn(fleePetir) end)

SecL:Button("⚡ Respawn Cepat","Mati → spawn → TP balik",function() task.spawn(doRespawn) end)
SecL:Button("🔄 Rejoin","Koneksi ulang ke server",
    function() notify("Rejoin","Menghubungkan ulang...",3); task.wait(1); TpService:Teleport(game.PlaceId,LP) end)

SecR:Paragraph("Penangkal Petir","① HP = MaxHP instant\n② HP lock 8 detik\n③ Flee → tunggu 5s → kembali\n\nSet Titik Aman dulu\n(posisi dalam bangunan)")
SecR:Paragraph("Anti AFK","Jump kecil tiap 2 menit\nCegah auto disconnect")
SecR:Paragraph("NPC Coords","Penjual  X=-59  Z=-207\nBibit    X=-42  Z=-207\nAlat     X=-41.5 Y=49.2 Z=-180.8\nSawit    X= 56  Z=-208\nTelur    X=-98  Z=-176\nMandi    X=137  Z=-235")

-- ┌─────────────────────────────────────────────────────────┐
-- │                      INIT                               │
-- └─────────────────────────────────────────────────────────┘
setupIntercepts()

Library:Notification("XKID | SAWAH INDO V.2",
    "Farm · Harvest · Shop · NPC · Fly · Security", 6)
Library:ConfigSystem(Win)
print("[XKID SAWAH INDO] V.2 loaded — "..LP.Name)
