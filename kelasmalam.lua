--[[
╔═══════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.0  🌟              ║
║                  Aurora UI  ·  Pro Edition               ║
╠═══════════════════════════════════════════════════════════╣
║  Farming  ·  Shop  ·  Teleport  ·  Player                ║
║  Security  ·  Setting                                    ║
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
-- │                  CORE HELPERS                           │
-- └─────────────────────────────────────────────────────────┘
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function notify(t, b, d)
    pcall(function() Library:Notification(t, b, d or 3) end)
    print(string.format("[XKID] %s | %s", t, tostring(b)))
end

local lastCFrame
RunService.Heartbeat:Connect(function()
    local r = getRoot(); if r then lastCFrame = r.CFrame end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │                   REMOTE BRIDGE                         │
-- └─────────────────────────────────────────────────────────┘
local function getBridge()
    local bn = RS:FindFirstChild("BridgeNet2")
    return bn and bn:FindFirstChild("dataRemoteEvent")
end
local function getFishEv(name)
    local fr = RS:FindFirstChild("FishRemotes")
    return fr and fr:FindFirstChild(name)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   CROP DATA                             │
-- └─────────────────────────────────────────────────────────┘
local CROPS = {
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
local CROP_VALID = {}
for _, c in ipairs(CROPS) do CROP_VALID[c.name] = true end
local cropDropNames = {}
for _, c in ipairs(CROPS) do table.insert(cropDropNames, c.icon.." "..c.seed) end

-- ┌─────────────────────────────────────────────────────────┐
-- │                  AREA / PLOT DATA                       │
-- └─────────────────────────────────────────────────────────┘
-- Area tanam dari workspace (sesuai data Dex)
local AREA_INDICES = {52, 53, 54, 64, 65, 66, 67}
local AREA_NAMES   = {}  -- nama dropdown
local AREA_PARTS   = {}  -- nama → list BasePart

local function buildAreaData()
    AREA_NAMES = {}
    AREA_PARTS = {}

    -- workspace.Land
    local land = Workspace:FindFirstChild("Land")
    if land then
        local parts = {}
        if land:IsA("BasePart") then
            table.insert(parts, land)
        else
            for _, p in ipairs(land:GetChildren()) do
                if p:IsA("BasePart") then table.insert(parts, p) end
            end
        end
        if #parts > 0 then
            table.insert(AREA_NAMES, "Land ("..#parts.." plot)")
            AREA_PARTS["Land ("..#parts.." plot)"] = parts
        end
    end

    -- workspace:GetChildren() index
    local allCh = Workspace:GetChildren()
    for _, idx in ipairs(AREA_INDICES) do
        local obj = allCh[idx]
        if obj then
            local parts = {}
            if obj:IsA("BasePart") then
                table.insert(parts, obj)
            else
                for _, p in ipairs(obj:GetChildren()) do
                    if p:IsA("BasePart") then table.insert(parts, p) end
                end
                if #parts == 0 then
                    for _, p in ipairs(obj:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            table.insert(parts, p)
                        end
                    end
                end
            end
            if #parts > 0 then
                local label = obj.Name.." ["..idx.."] ("..#parts.." plot)"
                table.insert(AREA_NAMES, label)
                AREA_PARTS[label] = parts
            end
        end
    end

    -- Fallback kalau kosong
    if #AREA_NAMES == 0 then
        table.insert(AREA_NAMES, "Auto Scan")
        local fallback = {}
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj.Name:lower():find("land") or obj.Name:lower():find("farm")
            or obj.Name:lower():find("area") or obj.Name:lower():find("plot") then
                if obj:IsA("BasePart") then
                    table.insert(fallback, obj)
                else
                    for _, p in ipairs(obj:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            table.insert(fallback, p)
                        end
                    end
                end
            end
        end
        AREA_PARTS["Auto Scan"] = fallback
    end

    print("[XKID] Area data built: "..#AREA_NAMES.." area")
end

-- Pola tanam
local POLA_NAMES = {"Normal", "Rapat (terdekat)", "Selang-seling Lebar", "Selang-seling Panjang"}

local function filterByPola(plots, pola, jumlah)
    local max = math.min(jumlah, #plots, 20)
    local result = {}

    if pola == "Normal" then
        for i = 1, max do table.insert(result, plots[i]) end

    elseif pola == "Rapat (terdekat)" then
        local root = getRoot()
        if root then
            local sorted = {}
            for _, p in ipairs(plots) do
                table.insert(sorted, {part=p, dist=(p.Position-root.Position).Magnitude})
            end
            table.sort(sorted, function(a,b) return a.dist < b.dist end)
            for i = 1, max do table.insert(result, sorted[i].part) end
        else
            for i = 1, max do table.insert(result, plots[i]) end
        end

    elseif pola == "Selang-seling Lebar" then
        local sorted = {table.unpack(plots)}
        table.sort(sorted, function(a,b) return a.Position.X < b.Position.X end)
        local lastX, skip = nil, false
        for _, p in ipairs(sorted) do
            if lastX == nil then lastX = p.Position.X; skip = false
            elseif math.abs(p.Position.X - lastX) > 6 then
                lastX = p.Position.X; skip = not skip
            end
            if not skip then
                table.insert(result, p)
                if #result >= max then break end
            end
        end
        if #result == 0 then for i=1,max do table.insert(result, plots[i]) end end

    elseif pola == "Selang-seling Panjang" then
        local sorted = {table.unpack(plots)}
        table.sort(sorted, function(a,b) return a.Position.Z < b.Position.Z end)
        local lastZ, skip = nil, false
        for _, p in ipairs(sorted) do
            if lastZ == nil then lastZ = p.Position.Z; skip = false
            elseif math.abs(p.Position.Z - lastZ) > 6 then
                lastZ = p.Position.Z; skip = not skip
            end
            if not skip then
                table.insert(result, p)
                if #result >= max then break end
            end
        end
        if #result == 0 then for i=1,max do table.insert(result, plots[i]) end end
    end

    return result
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                  FARM STATE                             │
-- └─────────────────────────────────────────────────────────┘
local Farm = {
    -- Penempatan lahan
    selectedCrop    = CROPS[1],
    selectedArea    = "",
    selectedPola    = "Normal",
    -- Eksekusi
    jumlahTanam     = 5,
    -- Auto Cycle
    autoCycleOn     = false,
    autoCycleTask   = nil,
    autoBeli        = false,
    jumlahAutoBeli  = 10,
    growDelay       = 60,
    -- Fitur tambahan
    autoPanen       = false,
    autoPanenTask   = nil,
    espKematangan   = false,
}

-- Remote: Beli Bibit
local function beliBibit(crop, qty)
    local ev = getBridge()
    if not ev then notify("Farm","BridgeNet2 tidak ada!",4); return false end
    local ok = pcall(function()
        ev:FireServer({{ cropName=crop.name, amount=qty }, "\a"})
    end)
    return ok
end

-- Remote: Tanam
local function tanamPlots()
    local ev = getBridge()
    if not ev then notify("Farm","BridgeNet2 tidak ada!",4); return 0 end

    local plots = AREA_PARTS[Farm.selectedArea]
    if not plots or #plots == 0 then
        notify("Farm","Area '"..Farm.selectedArea.."' tidak ada plot!",5)
        return 0
    end

    local filtered = filterByPola(plots, Farm.selectedPola, Farm.jumlahTanam)
    if #filtered == 0 then notify("Farm","Tidak ada plot setelah filter!",4); return 0 end

    local count = 0
    for i, plot in ipairs(filtered) do
        pcall(function()
            ev:FireServer({{
                slotIdx     = i,
                hitPosition = plot.Position,
                hitPart     = plot
            }, "\x04"})
        end)
        count = count + 1
        task.wait(0.2)
    end
    return count
end

-- Remote: Harvest semua
local function harvestAll()
    local ev = getBridge()
    if not ev then notify("Farm","BridgeNet2 tidak ada!",4); return 0 end

    -- Harvest semua area yang ada
    local allPlots = {}
    for _, parts in pairs(AREA_PARTS) do
        for _, p in ipairs(parts) do table.insert(allPlots, p) end
    end

    if #allPlots == 0 then notify("Farm","Tidak ada plot!",4); return 0 end

    local count = 0
    for _, plot in ipairs(allPlots) do
        pcall(function()
            firesignal(ev.OnClientEvent, {
                ["\r"] = {{
                    cropName  = Farm.selectedCrop.name,
                    cropPos   = plot.Position,
                    sellPrice = Farm.selectedCrop.sell,
                    drops     = {}
                }},
                ["\x02"] = {0, 0}
            })
        end)
        count = count + 1
        task.wait(0.15)
    end
    return count
end

-- Auto Cycle
local function runCycle()
    -- 1. Beli bibit (kalau autoBeli aktif atau stok mau habis)
    if Farm.autoBeli then
        notify("Cycle [1/4]","Beli "..Farm.selectedCrop.seed.." x"..Farm.jumlahAutoBeli,2)
        beliBibit(Farm.selectedCrop, Farm.jumlahAutoBeli)
        task.wait(1.5)
    end

    -- 2. Tanam
    notify("Cycle [2/4]","Tanam "..Farm.jumlahTanam.." plot ("..Farm.selectedPola..")...",2)
    local planted = tanamPlots()
    notify("Cycle [2/4]",planted.." plot berhasil ditanam",3)
    task.wait(1)

    -- 3. Tunggu tumbuh
    notify("Cycle [3/4]","Menunggu "..Farm.growDelay.."s tumbuh...",3)
    task.wait(Farm.growDelay)

    -- 4. Harvest
    notify("Cycle [4/4]","Panen semua...",2)
    local harvested = harvestAll()
    notify("✅ Cycle Selesai","Panen: "..harvested.." plot",4)
    task.wait(1)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                  ESP SYSTEM                             │
-- └─────────────────────────────────────────────────────────┘

-- ESP Player
local ESPPl = { active=false, data={}, conn=nil }

local function _mkPlBill(p)
    if p==LP or ESPPl.data[p] then return end
    if not p.Character then return end
    local head = p.Character:FindFirstChild("Head"); if not head then return end

    local bill = Instance.new("BillboardGui")
    bill.Name="XKID_PESP"; bill.Size=UDim2.new(0,100,0,24)
    bill.StudsOffset=Vector3.new(0,2.5,0); bill.AlwaysOnTop=true
    bill.Adornee=head; bill.Parent=head

    local bg = Instance.new("Frame",bill)
    bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency=0.45; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,4)

    local lbl = Instance.new("TextLabel",bg)
    lbl.Size=UDim2.new(1,-4,1,-4); lbl.Position=UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.fromRGB(255,230,80)
    lbl.TextStrokeColor3=Color3.fromRGB(0,0,0); lbl.TextStrokeTransparency=0.35
    lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold; lbl.Text=p.Name

    ESPPl.data[p]={bill=bill,lbl=lbl}
end

local function _rmPlBill(p)
    if ESPPl.data[p] then
        pcall(function() ESPPl.data[p].bill:Destroy() end)
        ESPPl.data[p]=nil
    end
end

local function startESPPlayer()
    for _,p in pairs(Players:GetPlayers()) do _mkPlBill(p) end
    ESPPl.conn = RunService.Heartbeat:Connect(function()
        if not ESPPl.active then return end
        local myR = getRoot()
        for p,d in pairs(ESPPl.data) do
            if not d.bill or not d.bill.Parent then ESPPl.data[p]=nil
            else
                if myR and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((p.Character.HumanoidRootPart.Position-myR.Position).Magnitude)
                    d.lbl.Text = p.Name.."\n"..dist.."m"
                else d.lbl.Text = p.Name end
            end
        end
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character and not ESPPl.data[p] then _mkPlBill(p) end
        end
    end)
end

local function stopESPPlayer()
    if ESPPl.conn then ESPPl.conn:Disconnect(); ESPPl.conn=nil end
    for p in pairs(ESPPl.data) do _rmPlBill(p) end
    ESPPl.data={}
end

Players.PlayerRemoving:Connect(_rmPlBill)
for _,p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPPl.active then _rmPlBill(p); _mkPlBill(p) end
    end)
end

-- ESP Kematangan Tanaman
local ESPCr = {
    active=false, bills={}, tagged={},
    loopTask=nil, lastScan=0, sizeData={}
}

local function _pct(part, name)
    local mag = part.Size.Magnitude
    local sd  = ESPCr.sizeData[name]
    if not sd then ESPCr.sizeData[name]={min=mag,max=mag}; return 0 end
    if mag<sd.min then sd.min=mag end
    if mag>sd.max then sd.max=mag end
    if sd.max==sd.min then return 50 end
    return math.floor(math.clamp((mag-sd.min)/(sd.max-sd.min)*100,0,100))
end

local function _pctCol(pct)
    if pct>=80 then return Color3.fromRGB(80,255,80)  end
    if pct>=40 then return Color3.fromRGB(255,200,50) end
    return Color3.fromRGB(255,80,80)
end

local function _mkCropBill(part, name)
    if ESPCr.tagged[part] then return end
    ESPCr.tagged[part]=true

    local bill = Instance.new("BillboardGui")
    bill.Name="XKID_CESP"; bill.Size=UDim2.new(0,100,0,28)
    bill.StudsOffset=Vector3.new(0,3.5,0); bill.AlwaysOnTop=true
    bill.Adornee=part; bill.Parent=part

    local bg = Instance.new("Frame",bill)
    bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(5,20,5)
    bg.BackgroundTransparency=0.3; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,5)

    local lbl = Instance.new("TextLabel",bg)
    lbl.Size=UDim2.new(1,-4,1,-4); lbl.Position=UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency=1; lbl.TextScaled=true
    lbl.Font=Enum.Font.GothamBold; lbl.TextXAlignment=Enum.TextXAlignment.Center
    lbl.TextStrokeTransparency=0.3; lbl.Text=name.."\n0%"
    lbl.TextColor3=Color3.fromRGB(255,80,80)

    local conn = RunService.Heartbeat:Connect(function()
        if not bill or not bill.Parent then return end
        local pct = _pct(part,name)
        lbl.Text=name.."\n"..pct.."%"
        lbl.TextColor3=_pctCol(pct)
        lbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
    end)
    table.insert(ESPCr.bills,{bill=bill,conn=conn})
end

local function clearESPCrop()
    for _,e in ipairs(ESPCr.bills) do
        pcall(function() e.conn:Disconnect() end)
        pcall(function() e.bill:Destroy()    end)
    end
    ESPCr.bills={}; ESPCr.tagged={}
end

local function scanESPCrop()
    local now=tick()
    if now-ESPCr.lastScan<5 then return end
    ESPCr.lastScan=now
    local count=0
    for _,v in pairs(Workspace:GetDescendants()) do
        if CROP_VALID[v.Name] then
            if v:IsA("BasePart") and not ESPCr.tagged[v] then
                _mkCropBill(v,v.Name); count=count+1
            elseif v:IsA("Model") then
                local p=v.PrimaryPart or v:FindFirstChildOfClass("BasePart")
                if p and not ESPCr.tagged[p] then _mkCropBill(p,v.Name); count=count+1 end
            end
        end
    end
    if count>0 then notify("ESP Tanaman","+"..count.." tanaman",2) end
end

local function startESPCrop()
    clearESPCrop(); ESPCr.lastScan=0; scanESPCrop()
    ESPCr.loopTask=task.spawn(function()
        while ESPCr.active do task.wait(5); if ESPCr.active then scanESPCrop() end end
    end)
end

local function stopESPCrop()
    clearESPCrop()
    if ESPCr.loopTask then pcall(function() task.cancel(ESPCr.loopTask) end); ESPCr.loopTask=nil end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │               MOVEMENT SYSTEM                           │
-- └─────────────────────────────────────────────────────────┘
local Move = {
    speed=16, flySpeed=60, flying=false, noclip=false,
    bv=nil, bg=nil, flyConn=nil, noclipConn=nil, jumpConn=nil,
    PITCH_UP=0.3, PITCH_DOWN=-0.3
}

RunService.RenderStepped:Connect(function()
    local h=getHum(); if h then h.WalkSpeed=Move.speed end
end)

local function setNoclip(v)
    Move.noclip=v
    if v then
        if Move.noclipConn then Move.noclipConn:Disconnect() end
        Move.noclipConn=RunService.Stepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    else
        if Move.noclipConn then Move.noclipConn:Disconnect(); Move.noclipConn=nil end
        local c=getChar()
        if c then for _,p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end end
    end
end

local function setInfJump(v)
    if v then
        if Move.jumpConn then Move.jumpConn:Disconnect() end
        Move.jumpConn=UIS.JumpRequest:Connect(function()
            local h=getHum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if Move.jumpConn then Move.jumpConn:Disconnect(); Move.jumpConn=nil end
    end
end

local function stopFly()
    Move.flying=false
    if Move.flyConn then Move.flyConn:Disconnect(); Move.flyConn=nil end
    if Move.bv then pcall(function() Move.bv:Destroy() end); Move.bv=nil end
    if Move.bg then pcall(function() Move.bg:Destroy() end); Move.bg=nil end
    local h=getHum(); if h then h.PlatformStand=false end
end

local function startFly()
    local root=getRoot(); if not root then return end
    stopFly(); Move.flying=true
    Move.bv=Instance.new("BodyVelocity",root)
    Move.bv.MaxForce=Vector3.new(1e5,1e5,1e5); Move.bv.Velocity=Vector3.new()
    Move.bg=Instance.new("BodyGyro",root)
    Move.bg.MaxTorque=Vector3.new(1e5,1e5,1e5)
    Move.bg.P=1e4; Move.bg.D=100; Move.bg.CFrame=root.CFrame
    local h=getHum(); if h then h.PlatformStand=true end
    Move.flyConn=RunService.Heartbeat:Connect(function()
        if not Move.flying then return end
        local h2=getHum(); local r2=getRoot()
        if not h2 or not r2 or not Move.bv then return end
        local cf=Workspace.CurrentCamera.CFrame
        local lv=cf.LookVector; local rv=cf.RightVector
        local md=h2.MoveDirection; local hoz=Vector3.new()
        if md.Magnitude>0.05 then
            local f=Vector3.new(lv.X,0,lv.Z); local r=Vector3.new(rv.X,0,rv.Z)
            if f.Magnitude>0 then f=f.Unit end
            if r.Magnitude>0 then r=r.Unit end
            hoz=f*md:Dot(f)+r*md:Dot(r)
            if hoz.Magnitude>1 then hoz=hoz.Unit end
        end
        local py=lv.Y; local vrt=Vector3.new()
        if py>Move.PITCH_UP then
            vrt=Vector3.new(0,math.min((py-Move.PITCH_UP)/(1-Move.PITCH_UP),1),0)
        elseif py<Move.PITCH_DOWN then
            vrt=Vector3.new(0,-math.min((-py+Move.PITCH_DOWN)/(1+Move.PITCH_DOWN),1),0)
        end
        local dir=hoz+vrt
        if dir.Magnitude>0 then
            Move.bv.Velocity=(dir.Magnitude>1 and dir.Unit or dir)*Move.flySpeed
            if hoz.Magnitude>0.05 then Move.bg.CFrame=CFrame.new(Vector3.new(),hoz) end
        else Move.bv.Velocity=Vector3.new() end
        h2.PlatformStand=true
    end)
end

LP.CharacterAdded:Connect(function()
    task.wait(0.6)
    if Move.flying then task.wait(0.3); startFly() end
    if Move.noclip and not Move.noclipConn then
        Move.noclipConn=RunService.Stepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │               TELEPORT HELPERS                          │
-- └─────────────────────────────────────────────────────────┘
local function inferPlayer(prefix)
    if not prefix or prefix=="" then return nil end
    local best, bestScore = nil, math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP then
            local score = math.huge
            if p.Name:lower():sub(1,#prefix)==prefix:lower() then
                score = #p.Name-#prefix
            elseif p.DisplayName:lower():sub(1,#prefix)==prefix:lower() then
                score = (#p.DisplayName-#prefix)+0.5
            end
            if score<bestScore then best=p; bestScore=score end
        end
    end
    return best
end

local function tpToPlayer(prefix)
    if not prefix or prefix=="" then notify("TP","Ketik nama dulu!",2); return end
    local p=inferPlayer(prefix)
    if not p then notify("TP","Player '"..prefix.."' tidak ditemukan",3); return end
    if not p.Character then notify("TP",p.Name.." tidak ada karakter",2); return end
    local hrp=p.Character:FindFirstChild("HumanoidRootPart")
    local root=getRoot()
    if hrp and root then
        root.CFrame=hrp.CFrame*CFrame.new(0,0,3)
        notify("TP","→ "..p.Name,2)
    end
end

local SavedLoc = {nil,nil,nil,nil,nil}

-- ┌─────────────────────────────────────────────────────────┐
-- │               FISHING                                   │
-- └─────────────────────────────────────────────────────────┘
local Fish = { autoOn=false, fishTask=nil, waitDelay=6, rodEquipped=false }

local function equipRod()
    local bp=LP:FindFirstChild("Backpack"); if not bp then return false end
    local char=getChar(); if not char then return false end
    local rod=bp:FindFirstChild("AdvanceRod")
    if not rod then
        for _,t in ipairs(bp:GetChildren()) do
            if t.Name:lower():find("rod") or t.Name:lower():find("pancing") then
                rod=t; break
            end
        end
    end
    if not rod then notify("Fishing","AdvanceRod tidak ada!",4); return false end
    rod.Parent=char; task.wait(0.5); Fish.rodEquipped=true
    notify("Fishing","AdvanceRod equipped!",2); return true
end

local function unequipRod()
    local char=getChar(); if not char then return end
    local bp=LP:FindFirstChild("Backpack"); if not bp then return end
    local rod=char:FindFirstChild("AdvanceRod")
    if rod then rod.Parent=bp end
    Fish.rodEquipped=false
end

local function castOnce()
    local castEv=getFishEv("CastEvent"); local miniEv=getFishEv("MiniGame")
    if not castEv then notify("Fishing","CastEvent tidak ada!",4); return end
    pcall(function() castEv:FireServer(false,0) end); task.wait(0.8)
    pcall(function() castEv:FireServer(true) end); task.wait(Fish.waitDelay)
    pcall(function() castEv:FireServer(false,Fish.waitDelay) end); task.wait(0.8)
    if miniEv then
        pcall(function() miniEv:FireServer(true) end); task.wait(0.5)
        pcall(function() firesignal(miniEv.OnClientEvent,"Start") end); task.wait(0.3)
        pcall(function() firesignal(miniEv.OnClientEvent,"Stop") end)
    end
    task.wait(1)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │      SCAN AREA SEBELUM UI DIBUAT (PENTING!)             │
-- └─────────────────────────────────────────────────────────┘
-- Tunggu workspace siap
local _t = tick()
repeat task.wait(0.1)
until Workspace:FindFirstChild("Land") ~= nil
    or #Workspace:GetChildren() >= 50
    or (tick()-_t) > 8

-- Scan sekarang sebelum dropdown dibuat
buildAreaData()
if #AREA_NAMES > 0 then
    Farm.selectedArea = AREA_NAMES[1]
    print("[XKID] Default area: "..Farm.selectedArea)
end
local _tp = 0
for _,v in pairs(AREA_PARTS) do _tp=_tp+#v end
print(string.format("[XKID] Scan: %d area, %d plot", #AREA_NAMES, _tp))

-- ┌─────────────────────────────────────────────────────────┐
-- │                  WINDOW & TABS                          │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:Window("XKID HUB","sprout","v5.1",false)

Win:TabSection("MAIN")
local T_Farm = Win:Tab("Farming",  "leaf")
local T_Shop = Win:Tab("Shop",     "shopping-cart")
local T_TP   = Win:Tab("Teleport", "map-pin")
local T_Pl   = Win:Tab("Player",   "user")
local T_Sec  = Win:Tab("Security", "shield")
local T_Set  = Win:Tab("Setting",  "settings")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB FARMING                         ║
-- ╚═══════════════════════════════════════════════════════╝
local FP   = T_Farm:Page("Farming","leaf")
local FL   = FP:Section("Farming","Left")
local FR   = FP:Section("Auto & Fitur","Right")

-- ── Penempatan Lahan ─────────────────────────────────────
FL:Label("📍 Penempatan Lahan")

FL:Dropdown("Pilih Tanaman","cropSel",cropDropNames,
    function(val)
        for _,c in ipairs(CROPS) do
            if val:find(c.seed,1,true) then
                Farm.selectedCrop=c
                notify("Tanaman",c.seed.." dipilih",2)
                break
            end
        end
    end,"Pilih jenis tanaman")

FL:Dropdown("Pilih Area Tanam","areaSel",
    #AREA_NAMES>0 and AREA_NAMES or {"(Scan dulu)"},
    function(val)
        Farm.selectedArea=val
        local plots=AREA_PARTS[val]
        notify("Area",val.." | "..(plots and #plots or 0).." plot",2)
    end,"Pilih area / lahan")

FL:Dropdown("Pola Tanam","polaSel",POLA_NAMES,
    function(val)
        Farm.selectedPola=val
        notify("Pola",val,2)
    end,"Pilih pola penanaman")

-- ── Eksekusi Tanam ───────────────────────────────────────
FL:Label("🌱 Eksekusi Tanam")

FL:Slider("Jumlah Bibit (plot)","plantQty",1,20,5,
    function(v) Farm.jumlahTanam=v end,
    "Berapa plot yang akan ditanam (max 20)")

FL:Button("🌱 Mulai Tanam","Tanam sesuai area & pola yang dipilih",
    function()
        task.spawn(function()
            if Farm.selectedArea=="" then
                notify("Farm","Pilih area tanam dulu!",3); return
            end
            local n=tanamPlots()
            notify("Tanam",n.." plot | "..Farm.selectedCrop.seed,3)
        end)
    end)

-- ── Auto Cycle ───────────────────────────────────────────
FR:Label("🔄 Auto Cycle")

FR:Toggle("Auto Farm (Full Cycle)","autoCycle",false,
    "Beli → Tanam → Tunggu → Panen → Ulangi",
    function(v)
        Farm.autoCycleOn=v
        if v then
            if Farm.selectedArea=="" then
                notify("Farm","Pilih area tanam dulu!",3)
                Farm.autoCycleOn=false; return
            end
            Farm.autoCycleTask=task.spawn(function()
                while Farm.autoCycleOn do
                    runCycle(); task.wait(2)
                end
            end)
            notify("Auto Farm","ON",3)
        else
            if Farm.autoCycleTask then
                pcall(function() task.cancel(Farm.autoCycleTask) end)
                Farm.autoCycleTask=nil
            end
            notify("Auto Farm","OFF",2)
        end
    end)

FR:Toggle("Auto Beli Jika Habis","autoBeli",false,
    "Otomatis beli bibit saat stok habis",
    function(v)
        Farm.autoBeli=v
        notify("Auto Beli",v and "ON" or "OFF",2)
    end)

FR:Slider("Jumlah Auto Beli","autoBeliQty",1,99,10,
    function(v) Farm.jumlahAutoBeli=v end,
    "Jumlah beli bibit per transaksi")

FR:Slider("Waktu Tumbuh (detik)","growDly",15,300,60,
    function(v) Farm.growDelay=v end,
    "Tunggu berapa detik setelah tanam")

-- ── Fitur Tambahan ───────────────────────────────────────
FR:Label("✨ Fitur Tambahan")

FR:Toggle("Auto Panen","autoPanen",false,
    "Panen semua plot otomatis tiap interval",
    function(v)
        Farm.autoPanen=v
        if v then
            Farm.autoPanenTask=task.spawn(function()
                while Farm.autoPanen do
                    local n=harvestAll()
                    if n>0 then notify("Auto Panen",n.." plot",2) end
                    task.wait(30)
                end
            end)
            notify("Auto Panen","ON — tiap 30s",3)
        else
            if Farm.autoPanenTask then
                pcall(function() task.cancel(Farm.autoPanenTask) end)
                Farm.autoPanenTask=nil
            end
            notify("Auto Panen","OFF",2)
        end
    end)

FR:Toggle("ESP Kematangan (%)","espMatang",false,
    "Tampilkan % pertumbuhan di atas tanaman",
    function(v)
        Farm.espKematangan=v
        ESPCr.active=v
        if v then startESPCrop() else stopESPCrop() end
        notify("ESP Kematangan",v and "ON" or "OFF",2)
    end)

FR:Button("▶ Jalankan 1 Cycle","Beli+Tanam+Tunggu+Panen sekali",
    function()
        if Farm.selectedArea=="" then
            notify("Farm","Pilih area tanam dulu!",3); return
        end
        task.spawn(runCycle)
    end)

FR:Button("✂ Panen Sekarang","Harvest semua plot",
    function()
        task.spawn(function()
            local n=harvestAll()
            notify("Panen",n.." plot selesai!",3)
        end)
    end)

FR:Button("🔄 Scan Ulang Area","Refresh data area tanam",
    function()
        buildAreaData()
        notify("Area",#AREA_NAMES.." area ditemukan",3)
        -- Print ke console
        for _,name in ipairs(AREA_NAMES) do
            local p=AREA_PARTS[name]
            print(string.format("[XKID AREA] %s → %d plot", name, p and #p or 0))
        end
    end)

-- ╔═══════════════════════════════════════════════════════╗
-- ║                    TAB SHOP                           ║
-- ╚═══════════════════════════════════════════════════════╝
local SP   = T_Shop:Page("Shop","shopping-cart")
local SL   = SP:Section("Informasi Tas","Left")
local SR   = SP:Section("Beli Bibit Sawah","Right")

-- Informasi Tas Real-Time (dari LP.Backpack)
SL:Label("🎒 Informasi Tas (Real-Time)")

SL:Button("🔄 Refresh Isi Tas","Lihat semua item di backpack",
    function()
        local bp = LP:FindFirstChild("Backpack")
        if not bp then notify("Tas","Backpack tidak ada!",3); return end
        local items = bp:GetChildren()
        if #items == 0 then
            notify("Tas Kosong","Tidak ada item",3); return
        end
        local txt = ""
        for i, item in ipairs(items) do
            txt = txt..string.format("[%d] %s (%s)\n", i, item.Name, item.ClassName)
        end
        notify("🎒 Isi Tas ("..#items.." item)", txt, 12)
        print("[XKID TAS]")
        for i,item in ipairs(items) do
            print(string.format("  [%d] %s — %s", i, item.Name, item.ClassName))
        end
    end)

-- Auto refresh inventory display
local invDisplay = ""
local invConn    = nil

SL:Toggle("Auto Refresh Tas","autoInv",false,
    "Update isi tas setiap 3 detik",
    function(v)
        if v then
            invConn = task.spawn(function()
                while v do
                    local bp = LP:FindFirstChild("Backpack")
                    if bp then
                        local items = bp:GetChildren()
                        invDisplay = ""
                        for _,item in ipairs(items) do
                            invDisplay = invDisplay.."• "..item.Name.."\n"
                        end
                        if #items == 0 then invDisplay = "Tas kosong" end
                    end
                    task.wait(3)
                end
            end)
        else
            if invConn then pcall(function() task.cancel(invConn) end); invConn=nil end
        end
        notify("Auto Refresh Tas", v and "ON" or "OFF", 2)
    end)

SL:Paragraph("Cara Pakai",
    "Klik Refresh untuk\nmelihat isi tas\n\nAtau ON Auto Refresh\nuntuk update otomatis\ntiap 3 detik\n\nDetail di console F9")

-- Beli Bibit Sawah
SR:Label("🌾 Beli Bibit Sawah")

local shopCrop = CROPS[1]
local shopQty  = 1

SR:Dropdown("Pilih Bibit Beli","shopCropSel",cropDropNames,
    function(val)
        for _,c in ipairs(CROPS) do
            if val:find(c.seed,1,true) then shopCrop=c; break end
        end
        notify("Pilih",shopCrop.seed,2)
    end,"Pilih bibit yang mau dibeli")

SR:Slider("Jumlah Beli","shopQtySel",1,99,1,
    function(v) shopQty=v end,
    "Jumlah bibit per transaksi")

SR:Button("🛒 Beli","Beli bibit yang dipilih sekarang",
    function()
        task.spawn(function()
            local ok=beliBibit(shopCrop, shopQty)
            notify(ok and "✅ Beli OK" or "❌ Gagal",
                shopCrop.seed.." x"..shopQty, 3)
        end)
    end)

-- Quick buy per tanaman
SR:Label("─── Beli Cepat ───")
for _,c in ipairs(CROPS) do
    local cc=c
    SR:Button(cc.icon.." "..cc.seed,"Harga "..cc.price.." | Jual "..cc.sell,
        function()
            task.spawn(function()
                local ok=beliBibit(cc, shopQty)
                notify(ok and "✅ Beli" or "❌ Gagal", cc.seed.." x"..shopQty, 2)
            end)
        end)
end

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB TELEPORT                         ║
-- ╚═══════════════════════════════════════════════════════╝
local TPG  = T_TP:Page("Teleport","map-pin")
local TPL  = TPG:Section("👥 Tombol Player","Left")
local TPR  = TPG:Section("🔍 Ketik Nama  📍 Lokasi","Right")

-- Tombol per player (mode lama)
local playerBtns={}
local function addPlayerBtn(p)
    if p==LP or playerBtns[p] then return end
    playerBtns[p]=TPL:Button("🚀 "..p.Name,"TP ke "..p.Name,
        function()
            local root=getRoot(); if not root then return end
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                root.CFrame=p.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,3)
                notify("TP","→ "..p.Name,2)
            else
                notify("TP",p.Name.." tidak ada karakter",2)
            end
        end)
end
for _,p in pairs(Players:GetPlayers()) do addPlayerBtn(p) end
Players.PlayerAdded:Connect(function(p) task.wait(0.5); addPlayerBtn(p) end)
Players.PlayerRemoving:Connect(function(p) playerBtns[p]=nil end)

TPL:Button("👥 Lihat Semua Player","Daftar player + jarak",
    function()
        local list,n="",0
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP then
                n=n+1
                local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local myR=getRoot()
                local d=(hrp and myR) and math.floor((hrp.Position-myR.Position).Magnitude) or "?"
                list=list.."• "..p.Name.." — "..tostring(d).."m\n"
            end
        end
        notify(n.." Player Online",n>0 and list or "Tidak ada",10)
    end)

-- Ketik nama
local tpInput=""
TPR:TextBox("Nama / Prefix","tpInput","",
    function(v) tpInput=v end,"Ketik 1-2 huruf awal")
TPR:Button("🔍 Teleport via Nama","Cari & TP otomatis",
    function() tpToPlayer(tpInput) end)
TPR:Paragraph("Cara Ketik Nama",
    "Ketik 1-2 huruf pertama\nnama player → TP!\n\nContoh: 'XKIDTest'\nKetik 'XK' → TP")

-- Save / Load Location
TPR:Label("💾 Save & Load Lokasi")
for i=1,5 do
    local idx=i
    TPR:Button("💾 Save Slot "..idx,"Simpan posisi ke slot "..idx,
        function()
            local cf=lastCFrame
            if not cf then notify("Save","Karakter tidak ada!",2); return end
            SavedLoc[idx]=cf
            local p=cf.Position
            notify("Slot "..idx.." Saved",
                string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z),4)
        end)
    TPR:Button("📍 Load Slot "..idx,"TP ke slot "..idx,
        function()
            if not SavedLoc[idx] then notify("Load","Slot "..idx.." kosong!",2); return end
            local root=getRoot()
            if root then
                root.CFrame=SavedLoc[idx]
                local p=SavedLoc[idx].Position
                notify("Slot "..idx.." Loaded",
                    string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z),3)
            end
        end)
end

TPR:Button("📌 Posisi Saya","Koordinat sekarang",
    function()
        local r=getRoot()
        if r then
            local p=r.Position
            notify("Posisi Saya",
                string.format("X=%.2f\nY=%.2f\nZ=%.2f",p.X,p.Y,p.Z),8)
            print(string.format("[XKID] X=%.4f Y=%.4f Z=%.4f",p.X,p.Y,p.Z))
        end
    end)

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB PLAYER                          ║
-- ╚═══════════════════════════════════════════════════════╝
local PP   = T_Pl:Page("Player","user")
local PL   = PP:Section("⚡ Speed & Jump","Left")
local PR   = PP:Section("🚀 Fly & ESP","Right")

PL:Slider("Walk Speed","ws",16,500,16,
    function(v) Move.speed=v end,"Default 16")
PL:Button("Reset Speed","Ke 16",
    function() Move.speed=16; notify("Speed","Reset 16",2) end)
PL:Slider("Jump Power","jp",50,500,50,
    function(v) local h=getHum()
        if h then h.JumpPower=v; h.UseJumpPower=true end
    end,"Default 50")
PL:Toggle("Infinite Jump","infJump",false,"Lompat terus",
    function(v) setInfJump(v); notify("Inf Jump",v and "ON" or "OFF",2) end)
PL:Toggle("NoClip","noclip",false,"Tembus dinding",
    function(v) setNoclip(v); notify("NoClip",v and "ON" or "OFF",2) end)

PR:Toggle("Fly","fly",false,"Terbang bebas",
    function(v)
        if v then startFly() else stopFly() end
        notify("Fly",v and "ON" or "OFF",2)
    end)
PR:Slider("Fly Speed","flySpd",10,300,60,
    function(v) Move.flySpeed=v end,"Kecepatan terbang")
PR:Toggle("ESP Player","espPl",false,"Nama + jarak player lain",
    function(v)
        ESPPl.active=v
        if v then startESPPlayer() else stopESPPlayer() end
        notify("ESP Player",v and "ON" or "OFF",2)
    end)
PR:Paragraph("Cara Fly",
    "Joystick = arah\nKamera atas = naik\nKamera bawah = turun\nLepas = melayang")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB SECURITY                         ║
-- ╚═══════════════════════════════════════════════════════╝
local SecP  = T_Sec:Page("Security","shield")
local SecL  = SecP:Section("🛡 Perlindungan","Left")
local SecR  = SecP:Section("ℹ Info","Right")

local afkConn=nil
SecL:Toggle("Anti AFK","antiAfk",false,"Cegah auto disconnect saat idle",
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
        notify("Anti AFK",v and "ON" or "OFF",2)
    end)

local antiKickConn=nil
SecL:Toggle("Anti Kick","antiKick",false,"HP dikunci saat hampir mati",
    function(v)
        if v then
            if antiKickConn then antiKickConn:Disconnect() end
            antiKickConn=RunService.Heartbeat:Connect(function()
                local h=getHum()
                if h and h.Health>0 and h.Health<h.MaxHealth*0.15 then
                    h.Health=h.MaxHealth
                end
            end)
        else
            if antiKickConn then antiKickConn:Disconnect(); antiKickConn=nil end
        end
        notify("Anti Kick",v and "ON — HP terkunci" or "OFF",2)
    end)

SecL:Button("💀 Respawn di Sini","Mati & kembali ke posisi terakhir",
    function()
        local saved=lastCFrame
        local char=LP.Character
        if char then char:BreakJoints() end
        local conn
        conn=LP.CharacterAdded:Connect(function(nc)
            conn:Disconnect(); task.wait(1)
            local hrp=nc:WaitForChild("HumanoidRootPart",5)
            if hrp and saved then hrp.CFrame=saved end
            notify("Respawn","Kembali ke posisi!",3)
        end)
    end)

SecL:Button("🔄 Rejoin","Koneksi ulang ke server",
    function()
        notify("Rejoin","Menghubungkan ulang...",3)
        task.wait(1); TpService:Teleport(game.PlaceId,LP)
    end)

SecR:Paragraph("Anti AFK","Simulasi input saat idle\nCegah auto disconnect")
SecR:Paragraph("Anti Kick","HP dipantau real-time\nHP < 15% = penuh lagi")
SecR:Paragraph("Respawn","Posisi disimpan tiap frame\nMati → kembali ke posisi\nterakhir sebelum mati")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB SETTING                         ║
-- ╚═══════════════════════════════════════════════════════╝
local SetP  = T_Set:Page("Setting","settings")
local SetL  = SetP:Section("🎣 Fishing","Left")
local SetR  = SetP:Section("ℹ Script Info","Right")

-- Fishing di setting
SetL:Toggle("Auto Fishing","autoFish",false,"Auto equip rod + cast loop",
    function(v)
        Fish.autoOn=v
        if v then
            if not Fish.rodEquipped then
                local ok=equipRod()
                if not ok then Fish.autoOn=false; return end
            end
            Fish.fishTask=task.spawn(function()
                while Fish.autoOn do castOnce() end
            end)
            notify("Fishing","ON",3)
        else
            if Fish.fishTask then
                pcall(function() task.cancel(Fish.fishTask) end)
                Fish.fishTask=nil
            end
            notify("Fishing","OFF",2)
        end
    end)

SetL:Button("🎣 Cast Sekali","Lempar kail 1 kali",
    function()
        task.spawn(function()
            if not Fish.rodEquipped then
                local ok=equipRod(); if not ok then return end
                task.wait(0.5)
            end
            castOnce(); notify("Fishing","1 cast selesai",2)
        end)
    end)

SetL:Button("📦 Equip Rod","Ambil AdvanceRod dari backpack",
    function() equipRod() end)
SetL:Button("📤 Unequip Rod","Kembalikan rod ke backpack",
    function() unequipRod(); notify("Rod","Dikembalikan",2) end)
SetL:Slider("Delay Tunggu Ikan","fishWait",2,20,6,
    function(v) Fish.waitDelay=v end,"Detik tunggu sebelum tarik")

SetR:Paragraph("XKID HUB v5.0",
    "Struktur:\n"..
    "Farming  · Shop\n"..
    "Teleport · Player\n"..
    "Security · Setting\n\n"..
    "Remote: BridgeNet2\nFishing: FishRemotes")

SetR:Paragraph("Farming Info",
    "Pilih area → pola → jumlah\nlalu Mulai Tanam\n\nAuto Cycle:\nBeli→Tanam→Tunggu→Panen\n\nMax 20 plot per cycle")

-- ┌─────────────────────────────────────────────────────────┐
-- │                      INIT                               │
-- └─────────────────────────────────────────────────────────┘
-- Notif hasil scan yang sudah dilakukan sebelum UI
local _totalPl = 0
for _,v in pairs(AREA_PARTS) do _totalPl=_totalPl+#v end
if _totalPl > 0 then
    notify("✅ XKID HUB v5.1 Ready",
        #AREA_NAMES.." area | ".._totalPl.." plot\nDropdown area sudah terisi!",5)
else
    notify("⚠ Warning",
        "Plot tidak ditemukan!\nBuka Farming → Scan Ulang Area",6)
end

Library:Notification("XKID HUB v5.1",
    "Farming · Shop · Teleport · Player · Security", 6)
Library:ConfigSystem(Win)

print("[XKID HUB] v5.1 loaded — "..LP.Name)
