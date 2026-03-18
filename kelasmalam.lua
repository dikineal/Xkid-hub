--[[
  ╔══════════════════════════════════════════════════════╗
  ║         🌟  X K I D  H U B  v3.2  🌟               ║
  ║         Aurora UI  ✦  Farm Fix + Manual              ║
  ╚══════════════════════════════════════════════════════╝
  v3.2 Fix:
  [1] Plot scan: GetChildren index + workspace.Land langsung
  [2] Farm manual: pilih bibit + jumlah + tanam per plot
  [3] ESP Tanaman: scan children langsung (bukan descendants)
  [4] Auto fishing: equip AdvanceRod otomatis
]]

-- ════════════════════════════════════════
--  LOAD AURORA UI
-- ════════════════════════════════════════
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local VirtualUser= game:GetService("VirtualUser")
local TpService  = game:GetService("TeleportService")
local Workspace  = game:GetService("Workspace")
local RS         = game:GetService("ReplicatedStorage")
local LP         = Players.LocalPlayer

-- ════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function notif(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
    print("[ XKID ] "..t.." | "..tostring(b))
end

-- Save last position
local lastPos
RunService.Heartbeat:Connect(function()
    local r = getRoot(); if r then lastPos = r.CFrame end
end)

-- ════════════════════════════════════════
--  REMOTE HELPERS
-- ════════════════════════════════════════
local function getBridge()
    local bn = RS:FindFirstChild("BridgeNet2")
    return bn and bn:FindFirstChild("dataRemoteEvent")
end
local function getFishRemote(name)
    local fr = RS:FindFirstChild("FishRemotes")
    return fr and fr:FindFirstChild(name)
end

-- ════════════════════════════════════════
--  DATA TANAMAN
-- ════════════════════════════════════════
local CROP_LIST = {
    { name="AppleTree", seed="Bibit Apel",      icon="🍎", price=15,       sell=45        },
    { name="Padi",      seed="Bibit Padi",      icon="🌾", price=15,       sell=20        },
    { name="Melon",     seed="Bibit Melon",     icon="🍈", price=15,       sell=20        },
    { name="Tomat",     seed="Bibit Tomat",     icon="🍅", price=15,       sell=20        },
    { name="Sawi",      seed="Bibit Sawi",      icon="🥬", price=15,       sell=20        },
    { name="Coconut",   seed="Bibit Kelapa",    icon="🥥", price=100,      sell=140       },
    { name="Daisy",     seed="Bibit Daisy",     icon="🌼", price=5000,     sell=6000      },
    { name="FanPalm",   seed="Bibit FanPalm",   icon="🌴", price=100000,   sell=102000    },
    { name="SunFlower", seed="Bibit SunFlower", icon="🌻", price=2000000,  sell=2010000   },
    { name="Sawit",     seed="Bibit Sawit",     icon="🪴", price=80000000, sell=80100000  },
}
local cropNames = {}
for _, c in ipairs(CROP_LIST) do
    table.insert(cropNames, c.icon.." "..c.seed)
end

-- ════════════════════════════════════════
--  SCAN PLOT (FIXED)
--  Plot = BasePart langsung di:
--  - workspace:GetChildren()[52,53,54,64,65,66,67]
--  - workspace.Land (BasePart langsung)
-- ════════════════════════════════════════
local plotCache  = nil
local MAX_PLOT   = 20

local function scanPlots()
    if plotCache then return plotCache end
    plotCache = {}

    -- workspace.Land langsung sebagai BasePart
    local land = Workspace:FindFirstChild("Land")
    if land then
        if land:IsA("BasePart") then
            table.insert(plotCache, land)
        else
            -- kalau Land adalah folder/model, ambil children BasePart
            for _, p in ipairs(land:GetChildren()) do
                if p:IsA("BasePart") then
                    table.insert(plotCache, p)
                end
            end
        end
    end

    -- workspace:GetChildren() index tertentu dari Dex
    local PLOT_INDICES = {52, 53, 54, 64, 65, 66, 67}
    local allChildren  = Workspace:GetChildren()
    for _, idx in ipairs(PLOT_INDICES) do
        local obj = allChildren[idx]
        if obj and obj:IsA("BasePart") then
            -- cek duplikasi
            local dup = false
            for _, existing in ipairs(plotCache) do
                if existing == obj then dup = true; break end
            end
            if not dup then table.insert(plotCache, obj) end
        end
    end

    print("[ XKID ] Plots cached: "..#plotCache)
    return plotCache
end

-- ════════════════════════════════════════
--  BELI BIBIT
--  dataRemoteEvent:FireServer({{cropName,amount},"\a"})
-- ════════════════════════════════════════
local selectedCrop = CROP_LIST[1]
local jumlahBeli   = 10
local jumlahTanam  = 1  -- jumlah per plot

local function beliBibit(crop, qty)
    local ev = getBridge()
    if not ev then notif("Gagal","BridgeNet2 tidak ada",3); return false end
    local ok = pcall(function()
        ev:FireServer({
            { cropName=crop.name, amount=qty },
            "\a"
        })
    end)
    if ok then notif("Beli",crop.seed.." x"..qty,2) end
    return ok
end

-- ════════════════════════════════════════
--  TANAM PER PLOT
--  dataRemoteEvent:FireServer({{slotIdx,hitPosition,hitPart},"\x04"})
-- ════════════════════════════════════════
local function tanamSatuPlot(plot, idx)
    local ev = getBridge()
    if not ev or not plot then return false end
    local ok = pcall(function()
        ev:FireServer({
            {
                slotIdx     = idx or 1,
                hitPosition = plot.Position,
                hitPart     = plot
            },
            "\x04"
        })
    end)
    return ok
end

local function tanamSemuaPlot(maxPlot)
    local plots = scanPlots()
    if #plots == 0 then
        notif("Tanam","Plot tidak ditemukan! Coba Refresh Cache",4)
        return 0
    end
    local limit = math.min(#plots, maxPlot or MAX_PLOT)
    local count = 0
    for i = 1, limit do
        local ok = tanamSatuPlot(plots[i], i)
        if ok then count = count + 1 end
        task.wait(0.2)
    end
    return count
end

-- ════════════════════════════════════════
--  HARVEST
--  firesignal(OnClientEvent, {["\r"]={...},["\x02"]={...}})
-- ════════════════════════════════════════
local function harvestSatuPlot(plot)
    local ev = getBridge()
    if not ev or not plot then return false end
    local ok = pcall(function()
        firesignal(ev.OnClientEvent, {
            ["\r"] = {{
                cropName  = selectedCrop.name,
                cropPos   = plot.Position,
                sellPrice = selectedCrop.sell,
                drops     = {}
            }},
            ["\x02"] = { 0, 0 }
        })
    end)
    return ok
end

local function harvestSemuaPlot(maxPlot)
    local plots = scanPlots()
    if #plots == 0 then
        notif("Harvest","Plot tidak ditemukan!",4); return 0
    end
    local limit = math.min(#plots, maxPlot or MAX_PLOT)
    local count = 0
    for i = 1, limit do
        if harvestSatuPlot(plots[i]) then count = count + 1 end
        task.wait(0.15)
    end
    return count
end

-- ════════════════════════════════════════
--  AUTO FARM CYCLE
-- ════════════════════════════════════════
local farmLoop  = nil
local autoFarm  = false
local farmDelay = 60
local maxFarm   = 20

local function runFarmCycle()
    -- 1. Beli bibit
    notif("Cycle","Beli "..selectedCrop.seed.." x"..jumlahBeli,2)
    beliBibit(selectedCrop, jumlahBeli)
    task.wait(1)

    -- 2. Tanam
    notif("Cycle","Tanam max "..maxFarm.." plot...",2)
    local planted = tanamSemuaPlot(maxFarm)
    notif("Cycle",planted.." plot ditanam",3)
    task.wait(1)

    -- 3. Tunggu tumbuh
    notif("Cycle","Menunggu "..farmDelay.."s...",farmDelay-1)
    task.wait(farmDelay)

    -- 4. Harvest
    notif("Cycle","Harvest...",2)
    local harvested = harvestSemuaPlot(maxFarm)
    notif("Cycle #","Selesai! Harvest: "..harvested,4)
end

-- ════════════════════════════════════════
--  EQUIP ROD
-- ════════════════════════════════════════
local rodEquipped = false

local function equipRod()
    local backpack = LP:FindFirstChild("Backpack"); if not backpack then return false end
    local char     = getChar(); if not char then return false end
    local rod = backpack:FindFirstChild("AdvanceRod")
    if not rod then
        for _, t in ipairs(backpack:GetChildren()) do
            if t.Name:lower():find("rod") or t.Name:lower():find("pancing") then
                rod = t; break
            end
        end
    end
    if not rod then notif("Rod","AdvanceRod tidak ada di backpack!",4); return false end
    rod.Parent = char
    task.wait(0.5)
    notif("Rod","AdvanceRod equipped!",2)
    return true
end

local function unequipRod()
    local char     = getChar(); if not char then return end
    local backpack = LP:FindFirstChild("Backpack"); if not backpack then return end
    local rod = char:FindFirstChild("AdvanceRod")
    if rod then rod.Parent = backpack end
end

-- ════════════════════════════════════════
--  AUTO FISHING
-- ════════════════════════════════════════
local fishLoop  = nil
local autoFish  = false
local fishDelay = 5

local function doFishing()
    local castEv = getFishRemote("CastEvent")
    local miniEv = getFishRemote("MiniGame")
    if not castEv then notif("Fish","CastEvent tidak ada",3); return end
    pcall(function() castEv:FireServer(false, 0) end)
    task.wait(0.5)
    pcall(function() castEv:FireServer(true) end)
    task.wait(fishDelay)
    pcall(function() castEv:FireServer(false, fishDelay) end)
    task.wait(0.5)
    if miniEv then
        pcall(function() miniEv:FireServer(true) end)
        task.wait(0.3)
        pcall(function() firesignal(miniEv.OnClientEvent, "Stop") end)
    end
    task.wait(0.8)
end

-- ════════════════════════════════════════
--  ESP TANAMAN (FIXED)
--  Scan GetDescendants tapi filter HANYA nama crop valid
--  Tambah scan setiap area plot juga
-- ════════════════════════════════════════
local VALID_CROPS = {}
for _, c in ipairs(CROP_LIST) do VALID_CROPS[c.name] = true end

local sizeTracker   = {}
local espCropBills  = {}
local espCropTagged = {}
local espCropLoop   = nil
local lastCropScan  = 0

local function getMatang(part, name)
    local mag = part.Size.Magnitude
    local tr  = sizeTracker[name]
    if not tr then
        sizeTracker[name] = {min=mag, max=mag}; return 0
    end
    if mag < tr.min then tr.min = mag end
    if mag > tr.max then tr.max = mag end
    if tr.max == tr.min then return 50 end
    return math.floor(math.clamp((mag-tr.min)/(tr.max-tr.min)*100, 0, 100))
end

local function matangColor(pct)
    if pct >= 80 then return Color3.fromRGB(80,255,80)  end
    if pct >= 40 then return Color3.fromRGB(255,210,50) end
    return Color3.fromRGB(255,80,80)
end

local function makeESPCrop(part, name)
    if espCropTagged[part] then return end
    espCropTagged[part] = true

    local bill = Instance.new("BillboardGui")
    bill.Size        = UDim2.new(0,90,0,30)
    bill.StudsOffset = Vector3.new(0,4,0)
    bill.AlwaysOnTop = true
    bill.Adornee     = part
    bill.Parent      = part

    local bg = Instance.new("Frame",bill)
    bg.Size=UDim2.new(1,0,1,0)
    bg.BackgroundColor3=Color3.fromRGB(5,15,5)
    bg.BackgroundTransparency=0.25
    bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,6)

    local lbl = Instance.new("TextLabel",bg)
    lbl.Size=UDim2.new(1,-4,1,-4)
    lbl.Position=UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency=1
    lbl.TextScaled=true
    lbl.Font=Enum.Font.GothamBold
    lbl.TextXAlignment=Enum.TextXAlignment.Center
    lbl.TextStrokeTransparency=0.3

    local conn = RunService.Heartbeat:Connect(function()
        if not bill or not bill.Parent then return end
        local pct = getMatang(part, name)
        lbl.Text = name.."\n"..pct.."%"
        lbl.TextColor3 = matangColor(pct)
        lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    end)
    table.insert(espCropBills, {bill=bill, conn=conn})
end

local function clearESPCrop()
    for _, e in ipairs(espCropBills) do
        pcall(function() e.conn:Disconnect() end)
        pcall(function() e.bill:Destroy()    end)
    end
    espCropBills={}; espCropTagged={}
end

local function scanESPCrop()
    local now = tick()
    if now - lastCropScan < 5 then return end
    lastCropScan = now
    local count  = 0

    -- Scan seluruh workspace descendants
    for _, v in pairs(Workspace:GetDescendants()) do
        local name = v.Name
        if VALID_CROPS[name] then
            if v:IsA("BasePart") and not espCropTagged[v] then
                makeESPCrop(v, name); count = count + 1
            elseif v:IsA("Model") then
                local p = v.PrimaryPart or v:FindFirstChildOfClass("BasePart")
                if p and not espCropTagged[p] then
                    makeESPCrop(p, name); count = count + 1
                end
            end
        end
    end

    if count > 0 then notif("ESP","+"..count.." tanaman baru",2) end
end

local function startESPCrop()
    clearESPCrop(); lastCropScan=0; scanESPCrop()
    espCropLoop = task.spawn(function()
        while _G.ESPCrop do
            task.wait(5)
            if _G.ESPCrop then scanESPCrop() end
        end
    end)
end
local function stopESPCrop()
    clearESPCrop()
    if espCropLoop then
        pcall(function() task.cancel(espCropLoop) end)
        espCropLoop = nil
    end
end

-- ════════════════════════════════════════
--  ESP PLAYER (simple)
-- ════════════════════════════════════════
local espPlayerOn   = false
local espPlayerData = {}
local espPlayerConn = nil

local function makeESPPlayer(p)
    if p==LP or espPlayerData[p] then return end
    if not p.Character then return end
    local head = p.Character:FindFirstChild("Head")
    if not head then return end

    local bill = Instance.new("BillboardGui")
    bill.Name="XKID_ESP"; bill.Size=UDim2.new(0,80,0,20)
    bill.StudsOffset=Vector3.new(0,2.5,0)
    bill.AlwaysOnTop=true; bill.Adornee=head; bill.Parent=head

    local lbl = Instance.new("TextLabel",bill)
    lbl.Size=UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency=1
    lbl.TextColor3=Color3.fromRGB(255,255,100)
    lbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
    lbl.TextStrokeTransparency=0.4
    lbl.TextScaled=true
    lbl.Font=Enum.Font.Gotham
    lbl.Text=p.Name

    espPlayerData[p]={bill=bill,lbl=lbl}
end

local function cleanESPPlayer(p)
    if espPlayerData[p] then
        pcall(function() espPlayerData[p].bill:Destroy() end)
        espPlayerData[p]=nil
    end
end
local function clearAllESPPlayer()
    for p in pairs(espPlayerData) do cleanESPPlayer(p) end
    espPlayerData={}
end
local function startESPPlayer()
    for _,p in pairs(Players:GetPlayers()) do makeESPPlayer(p) end
    espPlayerConn = RunService.Heartbeat:Connect(function()
        if not espPlayerOn then return end
        local myR = getRoot()
        for p,data in pairs(espPlayerData) do
            if not data.bill or not data.bill.Parent then
                espPlayerData[p]=nil
            else
                if myR and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local d=math.floor((p.Character.HumanoidRootPart.Position-myR.Position).Magnitude)
                    data.lbl.Text=p.Name.." "..d.."m"
                else
                    data.lbl.Text=p.Name
                end
            end
        end
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character and not espPlayerData[p] then makeESPPlayer(p) end
        end
    end)
end
local function stopESPPlayer()
    if espPlayerConn then espPlayerConn:Disconnect(); espPlayerConn=nil end
    clearAllESPPlayer()
end

Players.PlayerRemoving:Connect(cleanESPPlayer)
for _,p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espPlayerOn then cleanESPPlayer(p); makeESPPlayer(p) end
    end)
end

-- ════════════════════════════════════════
--  NOCLIP, INF JUMP, FLY, SPEED
-- ════════════════════════════════════════
local noclip=false; local noclipConn=nil
local function setNoclip(v)
    noclip=v
    if v then
        if noclipConn then noclipConn:Disconnect() end
        noclipConn=RunService.Stepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        local c=getChar()
        if c then for _,p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end end
    end
end

local jumpConn=nil
local function setInfJump(v)
    if v then
        if jumpConn then jumpConn:Disconnect() end
        jumpConn=UIS.JumpRequest:Connect(function()
            local h=getHum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if jumpConn then jumpConn:Disconnect(); jumpConn=nil end
    end
end

local flying=false; local flySpeed=60
local bv,bg,flyConn=nil,nil,nil
local function stopFly()
    flying=false
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if bv then pcall(function() bv:Destroy() end); bv=nil end
    if bg then pcall(function() bg:Destroy() end); bg=nil end
    local h=getHum(); if h then h.PlatformStand=false end
end
local function startFly()
    local root=getRoot(); if not root then return end
    stopFly(); flying=true
    bv=Instance.new("BodyVelocity",root)
    bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Velocity=Vector3.new()
    bg=Instance.new("BodyGyro",root)
    bg.MaxTorque=Vector3.new(1e5,1e5,1e5)
    bg.P=1e4; bg.D=100; bg.CFrame=root.CFrame
    local h=getHum(); if h then h.PlatformStand=true end
    flyConn=RunService.Heartbeat:Connect(function()
        if not flying then return end
        local h2=getHum(); local r2=getRoot()
        if not h2 or not r2 or not bv or not bg then return end
        local cf=Workspace.CurrentCamera.CFrame
        local lv=cf.LookVector; local rv=cf.RightVector
        local md=h2.MoveDirection; local horiz=Vector3.new()
        if md.Magnitude>0.05 then
            local f=Vector3.new(lv.X,0,lv.Z); local r3=Vector3.new(rv.X,0,rv.Z)
            if f.Magnitude>0 then f=f.Unit end
            if r3.Magnitude>0 then r3=r3.Unit end
            horiz=f*md:Dot(f)+r3*md:Dot(r3)
            if horiz.Magnitude>1 then horiz=horiz.Unit end
        end
        local py=lv.Y; local vert=Vector3.new()
        if py>0.3 then vert=Vector3.new(0,math.min((py-0.3)/0.7,1),0)
        elseif py<-0.3 then vert=Vector3.new(0,-math.min((-py-0.3)/0.7,1),0) end
        local dir=horiz+vert
        if dir.Magnitude>0 then
            bv.Velocity=(dir.Magnitude>1 and dir.Unit or dir)*flySpeed
            if horiz.Magnitude>0.05 then bg.CFrame=CFrame.new(Vector3.new(),horiz) end
        else bv.Velocity=Vector3.new() end
        h2.PlatformStand=true
    end)
end

local speed=16
RunService.RenderStepped:Connect(function()
    local h=getHum(); if h then h.WalkSpeed=speed end
end)

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if flying then task.wait(0.3); startFly() end
    if noclip and not noclipConn then
        noclipConn=RunService.Stepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    end
end)

-- ════════════════════════════════════════
--  WINDOW & TABS
-- ════════════════════════════════════════
local Win = Library:Window("XKID HUB","star","v3.2",false)

Win:TabSection("Farming")
local TabFarm = Win:Tab("Farm",    "leaf")
local TabMan  = Win:Tab("Manual",  "tool")
local TabFish = Win:Tab("Fishing", "fish")

Win:TabSection("Player")
local TabTP   = Win:Tab("Teleport","map-pin")
local TabPl   = Win:Tab("Movement","zap")
local TabESP  = Win:Tab("ESP",     "eye")
local TabProt = Win:Tab("Protect", "shield")

-- ════════════════════════════════════════
--  TAB AUTO FARM
-- ════════════════════════════════════════
local FPage = TabFarm:Page("Auto Farm","leaf")
local FL    = FPage:Section("Auto Cycle","Left")
local FR    = FPage:Section("Pengaturan","Right")

FL:Toggle("Auto Farm Cycle","AutoFarmToggle",false,
    "Beli bibit + tanam + harvest loop otomatis",
    function(v)
        autoFarm=v
        if v then
            farmLoop=task.spawn(function()
                while autoFarm do
                    runFarmCycle(); task.wait(2)
                end
            end)
            notif("Auto Farm","ON",3)
        else
            if farmLoop then pcall(function() task.cancel(farmLoop) end); farmLoop=nil end
            notif("Auto Farm","OFF",2)
        end
    end)

FL:Button("Jalankan 1 Cycle","Beli + Tanam + Harvest sekali",
    function() task.spawn(runFarmCycle) end)

FL:Button("Refresh Cache Plot","Scan ulang semua plot dari workspace",
    function()
        plotCache=nil
        local p=scanPlots()
        notif("Plot",#p.." plot ditemukan",3)
        if #p==0 then
            notif("INFO","Coba cek Dex lagi untuk nama folder plot",5)
        end
    end)

FR:Dropdown("Pilih Tanaman","CropDrop",cropNames,
    function(val)
        for _,c in ipairs(CROP_LIST) do
            if val:find(c.seed,1,true) then selectedCrop=c; break end
        end
        notif("Tanaman",selectedCrop.seed.." dipilih",2)
    end,"Tanaman untuk auto farm")

FR:Slider("Jumlah Beli","BeliQty",1,99,10,
    function(v) jumlahBeli=v end,"Jumlah beli bibit per cycle")

FR:Slider("Max Plot per Cycle","MaxPlot",1,20,20,
    function(v) maxFarm=v end,"Batas plot per cycle (max 20)")

FR:Slider("Delay Tumbuh (detik)","GrowDelay",10,300,60,
    function(v) farmDelay=v end,"Waktu tunggu setelah tanam")

FR:Paragraph("Info Auto Farm",
    "Plot didapat dari:\n"..
    "- workspace.Land\n"..
    "- workspace index 52-54, 64-67\n\n"..
    "Max 20 plot per cycle\n"..
    "Sesuai batas game")

-- ════════════════════════════════════════
--  TAB FARM MANUAL
-- ════════════════════════════════════════
local MPage = TabMan:Page("Farm Manual","tool")
local ML    = MPage:Section("Tanam & Harvest","Left")
local MR    = MPage:Section("Pilih Tanaman","Right")

ML:Button("Beli Bibit Sekarang","Beli bibit yang dipilih",
    function()
        task.spawn(function()
            local ok=beliBibit(selectedCrop, jumlahBeli)
            notif(ok and "Beli OK" or "Gagal",
                selectedCrop.seed.." x"..jumlahBeli, 3)
        end)
    end)

ML:Button("Tanam Semua Plot","FireServer ke semua plot yang ditemukan",
    function()
        task.spawn(function()
            local c=tanamSemuaPlot(maxFarm)
            notif("Tanam",c.." plot | "..selectedCrop.seed,3)
        end)
    end)

ML:Button("Harvest Semua Plot","Harvest semua plot sekarang",
    function()
        task.spawn(function()
            local c=harvestSemuaPlot(maxFarm)
            notif("Harvest",c.." plot selesai",3)
        end)
    end)

ML:Button("Lihat Plot Tersedia","Cek berapa plot yang terdeteksi",
    function()
        local plots=scanPlots()
        local txt=""
        for i,p in ipairs(plots) do
            txt=txt..string.format("[%d] %s | X=%.0f Y=%.0f Z=%.0f\n",
                i, p.Name, p.Position.X, p.Position.Y, p.Position.Z)
            if i>=10 then txt=txt.."...(total "..#plots..")"; break end
        end
        notif(#plots.." Plot Ditemukan", #plots>0 and txt or "Tidak ada!", 10)
        print("[ XKID PLOTS ]")
        for i,p in ipairs(plots) do
            print(string.format("[%d] %s  X=%.2f Y=%.2f Z=%.2f",
                i,p.Name,p.Position.X,p.Position.Y,p.Position.Z))
        end
    end)

ML:Slider("Max Plot Tanam","ManualMax",1,20,20,
    function(v) maxFarm=v end,"Max plot per aksi")

MR:Dropdown("Pilih Tanaman","ManualCropDrop",cropNames,
    function(val)
        for _,c in ipairs(CROP_LIST) do
            if val:find(c.seed,1,true) then selectedCrop=c; break end
        end
        notif("Tanaman",selectedCrop.seed,2)
    end,"Tanaman untuk ditanam")

MR:Slider("Jumlah Beli","ManualBeli",1,99,10,
    function(v) jumlahBeli=v end,"Jumlah beli bibit")

MR:Paragraph("Info Tanaman",
    "Dipilih: "..selectedCrop.seed.."\n"..
    "Harga: "..selectedCrop.price.."\n"..
    "Jual: "..selectedCrop.sell.."\n\n"..
    "Ganti via dropdown di atas")

-- Quick buy buttons
for _, b in ipairs(CROP_LIST) do
    local bb=b
    MR:Button(bb.icon.." "..bb.seed,"Beli "..bb.price.." koin",
        function()
            task.spawn(function()
                selectedCrop=bb
                local ok=beliBibit(bb,jumlahBeli)
                notif(ok and "Beli OK" or "Gagal",bb.seed.." x"..jumlahBeli,3)
            end)
        end)
end

-- ════════════════════════════════════════
--  TAB FISHING
-- ════════════════════════════════════════
local FishPage = TabFish:Page("Auto Fishing","fish")
local FishL    = FishPage:Section("Auto Fish","Left")
local FishR    = FishPage:Section("Setting","Right")

FishL:Toggle("Auto Fishing","AutoFishToggle",false,
    "Auto equip AdvanceRod + cast loop",
    function(v)
        autoFish=v
        if v then
            local ok=equipRod()
            if not ok then autoFish=false; return end
            rodEquipped=true
            fishLoop=task.spawn(function()
                while autoFish do doFishing(); task.wait(0.5) end
            end)
            notif("Auto Fish","ON",3)
        else
            if fishLoop then pcall(function() task.cancel(fishLoop) end); fishLoop=nil end
            rodEquipped=false
            notif("Auto Fish","OFF",2)
        end
    end)

FishL:Button("Equip AdvanceRod","Ambil rod dari backpack",
    function()
        local ok=equipRod()
        if ok then rodEquipped=true end
    end)

FishL:Button("Mancing Sekali","Cast 1 kali",
    function()
        task.spawn(function()
            if not rodEquipped then
                local ok=equipRod()
                if not ok then return end
                rodEquipped=true; task.wait(0.5)
            end
            doFishing()
            notif("Fish","1 cast selesai",2)
        end)
    end)

FishL:Button("Unequip Rod","Kembalikan ke backpack",
    function() unequipRod(); rodEquipped=false; notif("Rod","Dikembalikan",2) end)

FishR:Slider("Delay Tarik (detik)","FishDelay",1,15,5,
    function(v) fishDelay=v end,"Waktu tunggu sebelum tarik")

FishR:Paragraph("Cara Kerja",
    "1. Toggle ON\n2. AdvanceRod auto equip\n3. Cast kail\n4. Tunggu "..fishDelay.."s\n5. Tarik + minigame\n6. Ulangi\n\nPastikan AdvanceRod\nada di backpack!")

-- ════════════════════════════════════════
--  TAB TELEPORT
-- ════════════════════════════════════════
local TPage = TabTP:Page("Teleport","map-pin")
local TL    = TPage:Section("Players Online","Left")
local TR    = TPage:Section("Info","Right")

local function addPlayerBtn(p)
    if p==LP then return end
    TL:Button(p.Name,"TP ke "..p.Name,function()
        local root=getRoot(); if not root then return end
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            root.CFrame=p.Character.HumanoidRootPart.CFrame*CFrame.new(0,3,0)
            notif("TP","Ke "..p.Name,2)
        end
    end)
end
for _,p in pairs(Players:GetPlayers()) do addPlayerBtn(p) end
Players.PlayerAdded:Connect(addPlayerBtn)
TR:Paragraph("Info","Player online otomatis\nmuncul di kiri.\nKlik nama untuk TP!")

-- ════════════════════════════════════════
--  TAB MOVEMENT
-- ════════════════════════════════════════
local MovPage = TabPl:Page("Movement","zap")
local MvL     = MovPage:Section("Speed & Jump","Left")
local MvR     = MovPage:Section("Fly","Right")

MvL:Slider("Walk Speed","speed",16,500,16,
    function(v) speed=v end,"Default 16")
MvL:Toggle("NoClip","noclip",false,"Tembus dinding",
    function(v) setNoclip(v); notif("NoClip",v and "ON" or "OFF",2) end)
MvL:Toggle("Infinite Jump","jump",false,"Lompat terus",
    function(v) setInfJump(v); notif("Inf Jump",v and "ON" or "OFF",2) end)
MvL:Slider("Jump Power","jp",50,500,50,
    function(v) local h=getHum()
        if h then h.JumpPower=v; h.UseJumpPower=true end
    end,"Default 50")

MvR:Toggle("Fly","fly",false,"Aktifkan terbang",
    function(v)
        if v then startFly() else stopFly() end
        notif("Fly",v and "ON" or "OFF",2)
    end)
MvR:Slider("Fly Speed","flyspd",10,300,60,
    function(v) flySpeed=v end,"Kecepatan terbang")
MvR:Paragraph("Cara Fly",
    "Joystick = arah\nKamera atas = naik\nKamera bawah = turun\nLepas = melayang")

-- ════════════════════════════════════════
--  TAB ESP
-- ════════════════════════════════════════
local ESPPage = TabESP:Page("ESP","eye")
local EL      = ESPPage:Section("ESP Player","Left")
local ER      = ESPPage:Section("ESP Tanaman","Right")

EL:Toggle("ESP Player","espplayer",false,"Nama + jarak simpel",
    function(v)
        espPlayerOn=v
        if v then startESPPlayer() else stopESPPlayer() end
        notif("ESP Player",v and "ON" or "OFF",2)
    end)
EL:Paragraph("ESP Player","Nama + jarak meter\nFont kecil\nUpdate real-time")

ER:Toggle("ESP Tanaman","espcrop",false,"Nama + % kematangan",
    function(v)
        _G.ESPCrop=v
        if v then startESPCrop() else stopESPCrop() end
        notif("ESP Tanaman",v and "ON" or "OFF",2)
    end)
ER:Button("Scan Ulang ESP","Cari tanaman baru di workspace",
    function()
        if _G.ESPCrop then
            lastCropScan=0; scanESPCrop()
        else notif("ESP","Aktifkan dulu!",2) end
    end)
ER:Button("Reset Size Tracker","Reset data kematangan",
    function() sizeTracker={}; notif("Reset","Size tracker di-reset",2) end)
ER:Paragraph("ESP Tanaman",
    "Merah  = baru tanam 0%\nKuning = setengah 40%\nHijau  = siap panen 80%\n\nScan setiap 5 detik\nFilter nama crop valid:\nPadi,Melon,Tomat,Sawi\nCoconut,Daisy,FanPalm\nSunFlower,Sawit,AppleTree")

-- ════════════════════════════════════════
--  TAB PROTECTION
-- ════════════════════════════════════════
local ProtPage = TabProt:Page("Protection","shield")
local PL       = ProtPage:Section("Safety","Left")
local PR       = ProtPage:Section("Info","Right")

local afkConn=nil
PL:Toggle("Anti AFK","afk",false,"Cegah disconnect idle",
    function(v)
        if v then
            if afkConn then afkConn:Disconnect() end
            afkConn=LP.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            if afkConn then afkConn:Disconnect(); afkConn=nil end
        end
        notif("Anti AFK",v and "ON" or "OFF",2)
    end)

PL:Button("Respawn di Posisi Ini","Mati lalu kembali ke posisi terakhir",
    function()
        local saved=lastPos
        local char=LP.Character
        if char then char:BreakJoints() end
        local conn
        conn=LP.CharacterAdded:Connect(function(nc)
            conn:Disconnect(); task.wait(1)
            local hrp=nc:WaitForChild("HumanoidRootPart",5)
            if hrp and saved then hrp.CFrame=saved end
            notif("Respawn","Kembali ke posisi!",3)
        end)
    end)

PL:Button("Rejoin","Koneksi ulang",
    function()
        notif("Rejoin","Menghubungkan ulang...",3)
        task.wait(1); TpService:Teleport(game.PlaceId,LP)
    end)

PL:Button("Posisi Saya","Lihat koordinat",
    function()
        local r=getRoot()
        if r then
            local p=r.Position
            notif("Posisi",
                string.format("X=%.1f\nY=%.1f\nZ=%.1f",p.X,p.Y,p.Z),6)
        end
    end)

PR:Paragraph("Info","Anti AFK cegah disconnect\nRespawn kembali ke\nposisi terakhir sebelum mati")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
task.spawn(function()
    task.wait(2)
    local plots = scanPlots()
    if #plots == 0 then
        notif("WARNING","Plot tidak ditemukan!\nBuka tab Manual > Lihat Plot",6)
    else
        notif("Ready",#plots.." plot siap digunakan!",4)
    end
end)

Library:Notification("XKID HUB","v3.2 — Farm Fix · Manual · ESP Fix",5)
Library:ConfigSystem(Win)

print("[ XKID HUB ] v3.2 loaded — "..LP.Name)
