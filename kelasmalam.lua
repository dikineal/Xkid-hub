--[[
╔═══════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v4.0  🌟              ║
║          Aurora UI  ·  Pro Structure Edition             ║
╠═══════════════════════════════════════════════════════════╣
║  FARMING   : Beli · Tanam (pilih jumlah) · Harvest all  ║
║  FISHING   : Auto cast · equip rod · minigame            ║
║  ESP       : Player & Tanaman (billboard realtime)       ║
║  TELEPORT  : Ketik nama · Save/Load Location             ║
║  PLAYER    : Speed · Jump · Fly · NoClip                 ║
╚═══════════════════════════════════════════════════════════╝
]]

-- ┌─────────────────────────────────────────┐
-- │           AURORA UI LOAD                │
-- └─────────────────────────────────────────┘
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ┌─────────────────────────────────────────┐
-- │              SERVICES                   │
-- └─────────────────────────────────────────┘
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local VirtualUser= game:GetService("VirtualUser")
local TpService  = game:GetService("TeleportService")
local Workspace  = game:GetService("Workspace")
local RS         = game:GetService("ReplicatedStorage")
local LP         = Players.LocalPlayer

-- ┌─────────────────────────────────────────┐
-- │           CORE HELPERS                  │
-- └─────────────────────────────────────────┘
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function notify(title, body, duration)
    pcall(function() Library:Notification(title, body, duration or 3) end)
    print(string.format("[XKID] %s | %s", title, tostring(body)))
end

-- Track posisi terakhir (untuk respawn)
local lastCFrame
RunService.Heartbeat:Connect(function()
    local r = getRoot()
    if r then lastCFrame = r.CFrame end
end)

-- ┌─────────────────────────────────────────┐
-- │         REMOTE BRIDGE                   │
-- └─────────────────────────────────────────┘
local function getBridge()
    local bn = RS:FindFirstChild("BridgeNet2")
    return bn and bn:FindFirstChild("dataRemoteEvent")
end

local function getFishEv(name)
    local fr = RS:FindFirstChild("FishRemotes")
    return fr and fr:FindFirstChild(name)
end

-- ┌─────────────────────────────────────────┐
-- │           CROP DATA                     │
-- └─────────────────────────────────────────┘
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

local CROP_VALID = {} -- untuk ESP filter
for _, c in ipairs(CROPS) do CROP_VALID[c.name] = true end

local cropDropNames = {}
for _, c in ipairs(CROPS) do
    table.insert(cropDropNames, c.icon.." "..c.seed)
end

-- ┌─────────────────────────────────────────┐
-- │           FARM STATE                    │
-- └─────────────────────────────────────────┘
local Farm = {
    selectedCrop = CROPS[1],
    jumlahBeli   = 10,
    jumlahTanam  = 5,    -- berapa plot yang mau ditanam
    growDelay    = 60,
    autoCycleOn  = false,
    cycleTask    = nil,
    plotCache    = nil,
}

-- ─── Scan Plots ───────────────────────────
local function scanPlots()
    if Farm.plotCache then return Farm.plotCache end
    Farm.plotCache = {}

    -- workspace.Land
    local land = Workspace:FindFirstChild("Land")
    if land then
        if land:IsA("BasePart") then
            table.insert(Farm.plotCache, land)
        else
            for _, p in ipairs(land:GetChildren()) do
                if p:IsA("BasePart") then
                    table.insert(Farm.plotCache, p)
                end
            end
        end
    end

    -- Index dari Dex: 52,53,54,64,65,66,67
    local idx_list   = {52,53,54,64,65,66,67}
    local allChildren = Workspace:GetChildren()
    for _, idx in ipairs(idx_list) do
        local obj = allChildren[idx]
        if obj and obj:IsA("BasePart") then
            local dup = false
            for _, ex in ipairs(Farm.plotCache) do
                if ex == obj then dup = true; break end
            end
            if not dup then table.insert(Farm.plotCache, obj) end
        end
    end

    print(string.format("[XKID] Plots cached: %d", #Farm.plotCache))
    return Farm.plotCache
end

-- ─── Beli Bibit ───────────────────────────
local function beliBibit(crop, qty)
    local ev = getBridge()
    if not ev then notify("Farm","BridgeNet2 tidak ada!",4); return false end
    local ok = pcall(function()
        ev:FireServer({ {cropName=crop.name, amount=qty}, "\a" })
    end)
    return ok
end

-- ─── Tanam (jumlah plot yang dipilih) ─────
local function tanamPlots(crop, jumlah)
    local ev = getBridge()
    if not ev then notify("Farm","BridgeNet2 tidak ada!",4); return 0 end

    local plots = scanPlots()
    if #plots == 0 then
        notify("Farm","Tidak ada plot ditemukan!",5)
        return 0
    end

    -- Sort by jarak dari karakter (tanam yang terdekat dulu)
    local root = getRoot()
    if root then
        table.sort(plots, function(a, b)
            return (a.Position - root.Position).Magnitude
                 < (b.Position - root.Position).Magnitude
        end)
    end

    local max   = math.min(jumlah, #plots, 20) -- max 20 sesuai batas game
    local count = 0

    for i = 1, max do
        local plot = plots[i]
        local ok   = pcall(function()
            ev:FireServer({
                { slotIdx=i, hitPosition=plot.Position, hitPart=plot },
                "\x04"
            })
        end)
        if ok then count = count + 1 end
        task.wait(0.2)
    end
    return count
end

-- ─── Harvest SEMUA plot ───────────────────
local function harvestAll(crop)
    local ev = getBridge()
    if not ev then notify("Farm","BridgeNet2 tidak ada!",4); return 0 end

    local plots = scanPlots()
    if #plots == 0 then notify("Farm","Tidak ada plot!",4); return 0 end

    local count = 0
    for _, plot in ipairs(plots) do
        pcall(function()
            firesignal(ev.OnClientEvent, {
                ["\r"] = {{
                    cropName  = crop.name,
                    cropPos   = plot.Position,
                    sellPrice = crop.sell,
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

-- ─── Auto Cycle ───────────────────────────
local function runCycle()
    local crop = Farm.selectedCrop

    -- Step 1: Beli bibit
    notify("Cycle [1/4]","Beli "..crop.seed.." x"..Farm.jumlahBeli,2)
    beliBibit(crop, Farm.jumlahBeli)
    task.wait(1.5)

    -- Step 2: Tanam
    notify("Cycle [2/4]","Tanam "..Farm.jumlahTanam.." plot...",2)
    local planted = tanamPlots(crop, Farm.jumlahTanam)
    notify("Cycle [2/4]",planted.." plot berhasil ditanam",3)
    task.wait(1)

    -- Step 3: Tunggu tumbuh
    notify("Cycle [3/4]","Menunggu "..Farm.growDelay.."s...",Farm.growDelay)
    task.wait(Farm.growDelay)

    -- Step 4: Harvest semua
    notify("Cycle [4/4]","Harvest semua plot...",2)
    local harvested = harvestAll(crop)
    notify("Cycle Selesai","Harvest: "..harvested.." plot!",4)
    task.wait(1)
end

-- ┌─────────────────────────────────────────┐
-- │           FISHING STATE                 │
-- └─────────────────────────────────────────┘
local Fish = {
    autoOn       = false,
    fishTask     = nil,
    waitDelay    = 6,     -- detik tunggu ikan
    rodEquipped  = false,
    ROD_NAME     = "AdvanceRod",
}

local function equipRod()
    local bp   = LP:FindFirstChild("Backpack"); if not bp   then return false end
    local char = getChar();                     if not char then return false end

    local rod  = bp:FindFirstChild(Fish.ROD_NAME)
    if not rod then
        -- Coba cari nama mirip
        for _, t in ipairs(bp:GetChildren()) do
            if t.Name:lower():find("rod") or t.Name:lower():find("pancing") then
                rod = t; break
            end
        end
    end

    if not rod then
        notify("Fishing","AdvanceRod tidak ada di backpack!",5)
        return false
    end

    rod.Parent = char
    task.wait(0.5)
    Fish.rodEquipped = true
    notify("Fishing","AdvanceRod equipped!",2)
    return true
end

local function unequipRod()
    local char = getChar();   if not char then return end
    local bp   = LP:FindFirstChild("Backpack"); if not bp then return end
    local rod  = char:FindFirstChild(Fish.ROD_NAME)
    if rod then rod.Parent = bp end
    Fish.rodEquipped = false
end

--[[
  URUTAN FISHING YANG BENAR (dari spy log):
  1. CastEvent:FireServer(false, 0)  → mulai cast (lempar kail)
  2. CastEvent:FireServer(true)      → kail masuk air / siap
  3. tunggu fishDelay detik
  4. CastEvent:FireServer(false, waktu) → tarik kail
  5. MiniGame:FireServer(true)       → mulai minigame
  6. firesignal(MiniGame.OnClientEvent, "Stop") → selesaikan
]]
local function castOnce()
    local castEv = getFishEv("CastEvent")
    local miniEv = getFishEv("MiniGame")

    if not castEv then notify("Fishing","CastEvent tidak ada!",4); return end

    -- 1. Lempar kail
    pcall(function() castEv:FireServer(false, 0) end)
    task.wait(0.8)

    -- 2. Kail masuk air
    pcall(function() castEv:FireServer(true) end)
    task.wait(Fish.waitDelay)

    -- 3. Tarik
    pcall(function() castEv:FireServer(false, Fish.waitDelay) end)
    task.wait(0.8)

    -- 4. Minigame
    if miniEv then
        pcall(function() miniEv:FireServer(true) end)
        task.wait(0.5)
        pcall(function() firesignal(miniEv.OnClientEvent, "Start") end)
        task.wait(0.3)
        pcall(function() firesignal(miniEv.OnClientEvent, "Stop") end)
    end

    task.wait(1)
end

-- ┌─────────────────────────────────────────┐
-- │         ESP SYSTEM                      │
-- └─────────────────────────────────────────┘

-- ─── ESP Player ───────────────────────────
local ESPPlayer = {
    active   = false,
    data     = {}, -- p → {bill, lbl}
    conn     = nil,
}

local function _makePlayerBill(p)
    if p == LP or ESPPlayer.data[p] then return end
    if not p.Character then return end
    local head = p.Character:FindFirstChild("Head"); if not head then return end

    local bill    = Instance.new("BillboardGui")
    bill.Name        = "XKID_PESP"
    bill.Size        = UDim2.new(0, 100, 0, 24)
    bill.StudsOffset = Vector3.new(0, 2.5, 0)
    bill.AlwaysOnTop = true
    bill.Adornee     = head
    bill.Parent      = head

    local bg = Instance.new("Frame", bill)
    bg.Size                   = UDim2.new(1,0,1,0)
    bg.BackgroundColor3       = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 0.45
    bg.BorderSizePixel        = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,4)

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size                   = UDim2.new(1,-4,1,-4)
    lbl.Position               = UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = Color3.fromRGB(255, 230, 80)
    lbl.TextStrokeColor3       = Color3.fromRGB(0,0,0)
    lbl.TextStrokeTransparency = 0.35
    lbl.TextScaled             = true
    lbl.Font                   = Enum.Font.GothamBold
    lbl.Text                   = p.Name

    ESPPlayer.data[p] = {bill=bill, lbl=lbl}
end

local function _removePlayerBill(p)
    if ESPPlayer.data[p] then
        pcall(function() ESPPlayer.data[p].bill:Destroy() end)
        ESPPlayer.data[p] = nil
    end
end

local function startESPPlayer()
    for _, p in pairs(Players:GetPlayers()) do _makePlayerBill(p) end

    ESPPlayer.conn = RunService.Heartbeat:Connect(function()
        if not ESPPlayer.active then return end
        local myRoot = getRoot()

        for p, data in pairs(ESPPlayer.data) do
            if not data.bill or not data.bill.Parent then
                ESPPlayer.data[p] = nil
            else
                if myRoot and p.Character
                and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor(
                        (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
                    )
                    data.lbl.Text = p.Name.."\n"..dist.."m"
                else
                    data.lbl.Text = p.Name
                end
            end
        end

        -- Tambah player baru / respawn
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and not ESPPlayer.data[p] then
                _makePlayerBill(p)
            end
        end
    end)
end

local function stopESPPlayer()
    if ESPPlayer.conn then ESPPlayer.conn:Disconnect(); ESPPlayer.conn=nil end
    for p in pairs(ESPPlayer.data) do _removePlayerBill(p) end
    ESPPlayer.data = {}
end

Players.PlayerRemoving:Connect(_removePlayerBill)
for _, p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPPlayer.active then
            _removePlayerBill(p); _makePlayerBill(p)
        end
    end)
end

-- ─── ESP Tanaman ──────────────────────────
local ESPCrop = {
    active   = false,
    bills    = {}, -- {bill, conn, lbl}
    tagged   = {}, -- part → true
    loopTask = nil,
    lastScan = 0,
    sizeData = {}, -- cropName → {min,max}
}

local function _getCropPct(part, name)
    local mag = part.Size.Magnitude
    local sd  = ESPCrop.sizeData[name]
    if not sd then
        ESPCrop.sizeData[name] = {min=mag, max=mag}
        return 0
    end
    if mag < sd.min then sd.min = mag end
    if mag > sd.max then sd.max = mag end
    if sd.max == sd.min then return 50 end
    return math.floor(math.clamp((mag-sd.min)/(sd.max-sd.min)*100, 0, 100))
end

local function _pctColor(pct)
    if pct >= 80 then return Color3.fromRGB(80,255,80)  end
    if pct >= 40 then return Color3.fromRGB(255,200,50) end
    return Color3.fromRGB(255,80,80)
end

local function _makeCropBill(part, name)
    if ESPCrop.tagged[part] then return end
    ESPCrop.tagged[part] = true

    local bill    = Instance.new("BillboardGui")
    bill.Name        = "XKID_CESP"
    bill.Size        = UDim2.new(0, 100, 0, 28)
    bill.StudsOffset = Vector3.new(0, 3.5, 0)
    bill.AlwaysOnTop = true
    bill.Adornee     = part
    bill.Parent      = part

    local bg = Instance.new("Frame", bill)
    bg.Size                   = UDim2.new(1,0,1,0)
    bg.BackgroundColor3       = Color3.fromRGB(5,20,5)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel        = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,5)

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size                   = UDim2.new(1,-4,1,-4)
    lbl.Position               = UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency = 1
    lbl.TextScaled             = true
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextXAlignment         = Enum.TextXAlignment.Center
    lbl.TextStrokeTransparency = 0.3
    lbl.Text                   = name.."\n0%"
    lbl.TextColor3             = Color3.fromRGB(255,80,80)

    -- Update real-time seperti ESP player
    local conn = RunService.Heartbeat:Connect(function()
        if not bill or not bill.Parent then return end
        local pct = _getCropPct(part, name)
        lbl.Text       = name.."\n"..pct.."%"
        lbl.TextColor3 = _pctColor(pct)
        lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    end)

    table.insert(ESPCrop.bills, {bill=bill, conn=conn})
end

local function clearESPCrop()
    for _, e in ipairs(ESPCrop.bills) do
        pcall(function() e.conn:Disconnect() end)
        pcall(function() e.bill:Destroy()    end)
    end
    ESPCrop.bills  = {}
    ESPCrop.tagged = {}
end

local function scanESPCrop()
    local now = tick()
    if now - ESPCrop.lastScan < 5 then return end
    ESPCrop.lastScan = now

    local count = 0
    for _, v in pairs(Workspace:GetDescendants()) do
        if CROP_VALID[v.Name] then
            if v:IsA("BasePart") and not ESPCrop.tagged[v] then
                _makeCropBill(v, v.Name); count = count + 1
            elseif v:IsA("Model") then
                local p = v.PrimaryPart or v:FindFirstChildOfClass("BasePart")
                if p and not ESPCrop.tagged[p] then
                    _makeCropBill(p, v.Name); count = count + 1
                end
            end
        end
    end

    if count > 0 then notify("ESP Tanaman","+"..count.." tanaman baru",2) end
end

local function startESPCrop()
    clearESPCrop()
    ESPCrop.lastScan = 0
    scanESPCrop()
    ESPCrop.loopTask = task.spawn(function()
        while ESPCrop.active do
            task.wait(5)
            if ESPCrop.active then scanESPCrop() end
        end
    end)
end

local function stopESPCrop()
    clearESPCrop()
    if ESPCrop.loopTask then
        pcall(function() task.cancel(ESPCrop.loopTask) end)
        ESPCrop.loopTask = nil
    end
end

-- ┌─────────────────────────────────────────┐
-- │         MOVEMENT SYSTEM                 │
-- └─────────────────────────────────────────┘
local Move = {
    speed     = 16,
    flySpeed  = 60,
    flying    = false,
    noclip    = false,
    bv        = nil,
    bg        = nil,
    flyConn   = nil,
    noclipConn= nil,
    jumpConn  = nil,
    PITCH_UP  = 0.3,
    PITCH_DOWN= -0.3,
}

-- Speed loop
RunService.RenderStepped:Connect(function()
    local h = getHum()
    if h then h.WalkSpeed = Move.speed end
end)

-- NoClip
local function setNoclip(v)
    Move.noclip = v
    if v then
        if Move.noclipConn then Move.noclipConn:Disconnect() end
        Move.noclipConn = RunService.Stepped:Connect(function()
            local c = getChar(); if not c then return end
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        if Move.noclipConn then Move.noclipConn:Disconnect(); Move.noclipConn=nil end
        local c = getChar()
        if c then
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

-- Infinite Jump
local function setInfJump(v)
    if v then
        if Move.jumpConn then Move.jumpConn:Disconnect() end
        Move.jumpConn = UIS.JumpRequest:Connect(function()
            local h = getHum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if Move.jumpConn then Move.jumpConn:Disconnect(); Move.jumpConn=nil end
    end
end

-- Fly
local function stopFly()
    Move.flying = false
    if Move.flyConn then Move.flyConn:Disconnect(); Move.flyConn=nil end
    if Move.bv then pcall(function() Move.bv:Destroy() end); Move.bv=nil end
    if Move.bg then pcall(function() Move.bg:Destroy() end); Move.bg=nil end
    local h = getHum(); if h then h.PlatformStand = false end
end

local function startFly()
    local root = getRoot(); if not root then return end
    stopFly()
    Move.flying = true

    Move.bv = Instance.new("BodyVelocity", root)
    Move.bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    Move.bv.Velocity = Vector3.new()

    Move.bg = Instance.new("BodyGyro", root)
    Move.bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    Move.bg.P = 1e4; Move.bg.D = 100
    Move.bg.CFrame = root.CFrame

    local h = getHum(); if h then h.PlatformStand = true end

    Move.flyConn = RunService.Heartbeat:Connect(function()
        if not Move.flying then return end
        local h2   = getHum(); local r2 = getRoot()
        if not h2 or not r2 or not Move.bv then return end

        local cf  = Workspace.CurrentCamera.CFrame
        local lv  = cf.LookVector
        local rv  = cf.RightVector
        local md  = h2.MoveDirection
        local hoz = Vector3.new()

        if md.Magnitude > 0.05 then
            local f = Vector3.new(lv.X,0,lv.Z)
            local r = Vector3.new(rv.X,0,rv.Z)
            if f.Magnitude > 0 then f = f.Unit end
            if r.Magnitude > 0 then r = r.Unit end
            hoz = f*md:Dot(f) + r*md:Dot(r)
            if hoz.Magnitude > 1 then hoz = hoz.Unit end
        end

        local py  = lv.Y
        local vrt = Vector3.new()
        if     py >  Move.PITCH_UP   then vrt = Vector3.new(0, math.min((py-Move.PITCH_UP)/(1-Move.PITCH_UP),1), 0)
        elseif py <  Move.PITCH_DOWN then vrt = Vector3.new(0,-math.min((-py+Move.PITCH_DOWN)/(1+Move.PITCH_DOWN),1),0) end

        local dir = hoz + vrt
        if dir.Magnitude > 0 then
            Move.bv.Velocity = (dir.Magnitude>1 and dir.Unit or dir) * Move.flySpeed
            if hoz.Magnitude > 0.05 then
                Move.bg.CFrame = CFrame.new(Vector3.new(), hoz)
            end
        else
            Move.bv.Velocity = Vector3.new()
        end
        h2.PlatformStand = true
    end)
end

-- Respawn handler
LP.CharacterAdded:Connect(function()
    task.wait(0.6)
    if Move.flying then task.wait(0.3); startFly() end
    if Move.noclip and not Move.noclipConn then
        Move.noclipConn = RunService.Stepped:Connect(function()
            local c = getChar(); if not c then return end
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end
end)

-- ┌─────────────────────────────────────────┐
-- │         TELEPORT SYSTEM                 │
-- └─────────────────────────────────────────┘
-- Infer player dari prefix nama
local function inferPlayer(prefix)
    if not prefix or prefix == "" then return nil end
    local best, bestScore = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local score = math.huge
            if p.Name:lower():sub(1,#prefix) == prefix:lower() then
                score = #p.Name - #prefix
            elseif p.DisplayName:lower():sub(1,#prefix) == prefix:lower() then
                score = (#p.DisplayName - #prefix) + 0.5
            end
            if score < bestScore then best=p; bestScore=score end
        end
    end
    return best
end

local function tpToPlayer(prefix)
    if not prefix or prefix=="" then
        notify("TP","Ketik nama dulu!",2); return
    end
    local p = inferPlayer(prefix)
    if not p then notify("TP","Player '"..prefix.."' tidak ditemukan",3); return end
    if not p.Character then notify("TP",p.Name.." tidak punya karakter",2); return end
    local hrp  = p.Character:FindFirstChild("HumanoidRootPart")
    local root = getRoot()
    if hrp and root then
        root.CFrame = hrp.CFrame * CFrame.new(0,0,3)
        notify("TP","Teleport ke "..p.Name,2)
    end
end

-- Save/Load Location (5 slot)
local SavedLoc = {nil,nil,nil,nil,nil}

-- ┌─────────────────────────────────────────┐
-- │         BUILD WINDOW                    │
-- └─────────────────────────────────────────┘
local Win = Library:Window("XKID HUB","star","v4.0",false)

-- ═══════════════════════════════════════
Win:TabSection("🌾 FARMING")
-- ═══════════════════════════════════════
local TFarm = Win:Tab("Farm",    "leaf")
local TFish = Win:Tab("Fishing", "fish")

-- ═══════════════════════════════════════
Win:TabSection("👤 PLAYER")
-- ═══════════════════════════════════════
local TMove = Win:Tab("Movement","zap")
local TESP  = Win:Tab("ESP",     "eye")
local TTP   = Win:Tab("Teleport","map-pin")
local TProt = Win:Tab("Protect", "shield")

-- ╔═══════════════════════════════════════╗
-- ║              TAB FARM                 ║
-- ╚═══════════════════════════════════════╝
local FP   = TFarm:Page("Farming","leaf")
local FCol = FP:Section("🔄 Auto Cycle","Left")
local FSet = FP:Section("⚙️ Pengaturan","Right")

-- Auto Cycle toggle
FCol:Toggle("Auto Farm Cycle","autoCycle",false,
    "Beli → Tanam → Tunggu → Harvest → Ulangi",
    function(v)
        Farm.autoCycleOn = v
        if v then
            Farm.cycleTask = task.spawn(function()
                while Farm.autoCycleOn do
                    runCycle()
                    task.wait(2)
                end
            end)
            notify("Auto Farm","ON — "..Farm.selectedCrop.seed,3)
        else
            if Farm.cycleTask then
                pcall(function() task.cancel(Farm.cycleTask) end)
                Farm.cycleTask = nil
            end
            notify("Auto Farm","OFF",2)
        end
    end)

-- Manual buttons
FCol:Button("▶ Jalankan 1 Cycle","Beli+Tanam+Harvest sekali",
    function() task.spawn(runCycle) end)

FCol:Button("🌱 Beli Bibit","Beli bibit yang dipilih",
    function()
        task.spawn(function()
            local ok = beliBibit(Farm.selectedCrop, Farm.jumlahBeli)
            notify("Beli", ok and Farm.selectedCrop.seed.." x"..Farm.jumlahBeli or "Gagal!",3)
        end)
    end)

FCol:Button("🌾 Tanam Sekarang","Tanam sejumlah plot yang dipilih",
    function()
        task.spawn(function()
            local n = tanamPlots(Farm.selectedCrop, Farm.jumlahTanam)
            notify("Tanam",n.." plot | "..Farm.selectedCrop.seed,3)
        end)
    end)

FCol:Button("✂ Harvest Semua","Harvest SEMUA plot sekarang",
    function()
        task.spawn(function()
            local n = harvestAll(Farm.selectedCrop)
            notify("Harvest",n.." plot selesai!",3)
        end)
    end)

FCol:Button("🔍 Cek Plot","Lihat berapa plot yang terdeteksi",
    function()
        Farm.plotCache = nil
        local plots = scanPlots()
        local info  = #plots.." plot ditemukan\n"
        for i,p in ipairs(plots) do
            info = info..string.format("[%d] %s X=%.0f Z=%.0f\n",i,p.Name,p.Position.X,p.Position.Z)
            if i >= 8 then info=info.."...dst"; break end
        end
        notify("Plot",info,10)
        for i,p in ipairs(plots) do
            print(string.format("[XKID PLOT %d] %s  X=%.2f Y=%.2f Z=%.2f",i,p.Name,p.Position.X,p.Position.Y,p.Position.Z))
        end
    end)

-- Settings
FSet:Dropdown("Pilih Tanaman","cropSel",cropDropNames,
    function(val)
        for _,c in ipairs(CROPS) do
            if val:find(c.seed,1,true) then
                Farm.selectedCrop = c
                notify("Tanaman",c.seed.." dipilih",2)
                break
            end
        end
    end,"Tanaman untuk farm")

FSet:Slider("Jumlah Beli","buyQty",1,99,10,
    function(v) Farm.jumlahBeli=v end,
    "Jumlah bibit per beli")

FSet:Slider("Jumlah Plot Tanam","plantQty",1,20,5,
    function(v) Farm.jumlahTanam=v end,
    "Berapa plot yang mau ditanam (max 20)")

FSet:Slider("Waktu Tumbuh (detik)","growDly",15,300,60,
    function(v) Farm.growDelay=v end,
    "Tunggu berapa detik setelah tanam")

FSet:Paragraph("Info Tanaman",
    "Urutan terdekat dari posisi kamu\n\n"..
    "Max plot = 20 (batas game)\n\n"..
    "Harvest = semua plot sekaligus\nTanam = sesuai slider")

-- ╔═══════════════════════════════════════╗
-- ║             TAB FISHING               ║
-- ╚═══════════════════════════════════════╝
local FiP  = TFish:Page("Fishing","fish")
local FiL  = FiP:Section("🎣 Auto Fishing","Left")
local FiR  = FiP:Section("⚙️ Setting","Right")

FiL:Toggle("Auto Fishing","autoFish",false,
    "Auto equip rod + cast loop otomatis",
    function(v)
        Fish.autoOn = v
        if v then
            -- Equip rod dulu
            if not Fish.rodEquipped then
                local ok = equipRod()
                if not ok then Fish.autoOn=false; return end
            end
            Fish.fishTask = task.spawn(function()
                while Fish.autoOn do
                    castOnce()
                end
            end)
            notify("Fishing","ON — casting loop!",3)
        else
            if Fish.fishTask then
                pcall(function() task.cancel(Fish.fishTask) end)
                Fish.fishTask = nil
            end
            notify("Fishing","OFF",2)
        end
    end)

FiL:Button("🎣 Cast Sekali","Lempar kail 1 kali",
    function()
        task.spawn(function()
            if not Fish.rodEquipped then
                local ok = equipRod()
                if not ok then return end
                task.wait(0.5)
            end
            castOnce()
            notify("Fishing","1 cast selesai",2)
        end)
    end)

FiL:Button("📦 Equip AdvanceRod","Ambil rod dari backpack",
    function()
        local ok = equipRod()
        notify("Rod", ok and "Equipped!" or "Tidak ada di backpack!",3)
    end)

FiL:Button("📤 Unequip Rod","Kembalikan rod ke backpack",
    function()
        unequipRod()
        notify("Rod","Dikembalikan ke backpack",2)
    end)

FiR:Slider("Delay Tunggu Ikan (detik)","fishWait",2,20,6,
    function(v) Fish.waitDelay=v end,
    "Waktu tunggu sebelum tarik kail")

FiR:Paragraph("Urutan Cast",
    "1. Equip AdvanceRod\n"..
    "2. CastEvent(false, 0)\n"..
    "   → Lempar kail\n"..
    "3. CastEvent(true)\n"..
    "   → Kail masuk air\n"..
    "4. Tunggu "..Fish.waitDelay.."s\n"..
    "5. CastEvent(false, waktu)\n"..
    "   → Tarik kail\n"..
    "6. MiniGame(true) → selesai")

-- ╔═══════════════════════════════════════╗
-- ║            TAB MOVEMENT               ║
-- ╚═══════════════════════════════════════╝
local MvP  = TMove:Page("Movement","zap")
local MvL  = MvP:Section("⚡ Speed & Jump","Left")
local MvR  = MvP:Section("🚀 Fly & Clip","Right")

MvL:Slider("Walk Speed","ws",16,500,16,
    function(v) Move.speed=v end,"Default 16")

MvL:Button("Reset Speed","Kembalikan ke 16",
    function()
        Move.speed=16
        notify("Speed","Reset ke 16",2)
    end)

MvL:Slider("Jump Power","jp",50,500,50,
    function(v)
        local h=getHum()
        if h then h.JumpPower=v; h.UseJumpPower=true end
    end,"Default 50")

MvL:Toggle("Infinite Jump","infJump",false,
    "Lompat terus tanpa batas",
    function(v)
        setInfJump(v)
        notify("Inf Jump",v and "ON" or "OFF",2)
    end)

MvR:Toggle("Fly","fly",false,
    "Terbang bebas | Joystick + Kamera",
    function(v)
        if v then startFly() else stopFly() end
        notify("Fly",v and "ON" or "OFF",2)
    end)

MvR:Slider("Fly Speed","flySpd",10,300,60,
    function(v) Move.flySpeed=v end,"Kecepatan terbang")

MvR:Toggle("NoClip","noclip",false,
    "Tembus semua dinding",
    function(v)
        setNoclip(v)
        notify("NoClip",v and "ON" or "OFF",2)
    end)

MvR:Paragraph("Cara Fly",
    "Joystick kiri = arah gerak\n"..
    "Kamera ke atas = naik\n"..
    "Kamera ke bawah = turun\n"..
    "Lepas joystick = melayang diam")

-- ╔═══════════════════════════════════════╗
-- ║              TAB ESP                  ║
-- ╚═══════════════════════════════════════╝
local EP   = TESP:Page("ESP","eye")
local EPL  = EP:Section("👤 ESP Player","Left")
local EPR  = EP:Section("🌾 ESP Tanaman","Right")

EPL:Toggle("ESP Player","espPlayer",false,
    "Tampilkan nama + jarak semua player",
    function(v)
        ESPPlayer.active = v
        if v then startESPPlayer() else stopESPPlayer() end
        notify("ESP Player",v and "ON" or "OFF",2)
    end)

EPL:Paragraph("Info ESP Player",
    "Tampil di atas kepala:\n• Nama player\n• Jarak (meter)\n\n"..
    "Update real-time\nTidak lag — dibuat 1x per player")

EPR:Toggle("ESP Tanaman","espCrop",false,
    "Tampilkan nama + % kematangan tanaman",
    function(v)
        ESPCrop.active = v
        if v then startESPCrop() else stopESPCrop() end
        notify("ESP Tanaman",v and "ON" or "OFF",2)
    end)

EPR:Button("🔄 Scan Ulang Tanaman","Cari tanaman baru di workspace",
    function()
        if ESPCrop.active then
            ESPCrop.lastScan=0; scanESPCrop()
        else
            notify("ESP","Aktifkan ESP Tanaman dulu!",2)
        end
    end)

EPR:Button("🗑 Hapus Semua Label","Bersihkan semua ESP tanaman",
    function()
        clearESPCrop()
        notify("ESP","Semua label dihapus",2)
    end)

EPR:Button("📊 Reset Size Data","Reset data kematangan",
    function()
        ESPCrop.sizeData={}
        notify("ESP","Size data di-reset",2)
    end)

EPR:Paragraph("Info ESP Tanaman",
    "Warna label:\n"..
    "🔴 Merah  = 0-39%  (baru)\n"..
    "🟡 Kuning = 40-79% (tumbuh)\n"..
    "🟢 Hijau  = 80-100% (siap!)\n\n"..
    "Update real-time tiap frame\n"..
    "Rescan workspace tiap 5 detik\n"..
    "Filter: nama crop valid saja")

-- ╔═══════════════════════════════════════╗
-- ║            TAB TELEPORT               ║
-- ╚═══════════════════════════════════════╝
local TPG  = TTP:Page("Teleport","map-pin")
local TPL  = TPG:Section("🧭 TP ke Player","Left")
local TPR  = TPG:Section("📍 Save Location","Right")

-- TP ke Player (ketik nama)
TPL:Button("👥 Lihat Player Online","Daftar semua player di server",
    function()
        local list, n = "", 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                n = n + 1
                local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local myR = getRoot()
                local dist = (hrp and myR)
                    and math.floor((hrp.Position-myR.Position).Magnitude)
                    or "?"
                list = list.."• "..p.Name.." ("..p.DisplayName..") — "..dist.."m\n"
            end
        end
        notify(n.." Player Online", n>0 and list or "Tidak ada player lain",10)
    end)

local tpInput = ""
TPL:TextBox("Nama / Prefix Player","tpInput","",
    function(v) tpInput=v end,
    "Ketik 1-2 huruf awal nama")

TPL:Button("🚀 Teleport ke Player","Cari otomatis & TP",
    function() tpToPlayer(tpInput) end)

TPL:Paragraph("Cara Pakai",
    "1. Klik Lihat Player Online\n"..
    "2. Catat nama / prefix\n"..
    "3. Ketik 1-2 huruf\n"..
    "4. Klik Teleport\n\n"..
    "Contoh: player 'XKIDTest'\nKetik 'XK' → langsung TP!")

-- Save / Load Location
TPR:Label("💾 Save & Load Lokasi")

for i = 1, 5 do
    local idx = i
    TPR:Button("💾 Save Lokasi "..idx,"Simpan posisi sekarang ke slot "..idx,
        function()
            local cf = lastCFrame or getCF()
            if not cf then notify("Save","Karakter tidak ada!",2); return end
            SavedLoc[idx] = cf
            local p = cf.Position
            notify("Slot "..idx.." Saved",
                string.format("X=%.1f  Y=%.1f  Z=%.1f",p.X,p.Y,p.Z),4)
        end)
    TPR:Button("📍 Load Lokasi "..idx,"Teleport ke slot "..idx,
        function()
            if not SavedLoc[idx] then
                notify("Load","Slot "..idx.." kosong!",2); return
            end
            local root = getRoot()
            if root then
                root.CFrame = SavedLoc[idx]
                local p = SavedLoc[idx].Position
                notify("Slot "..idx.." Loaded",
                    string.format("X=%.1f  Y=%.1f  Z=%.1f",p.X,p.Y,p.Z),3)
            end
        end)
end

TPR:Button("📌 Posisi Saya Sekarang","Cetak koordinat ke notif & console",
    function()
        local root = getRoot()
        if root then
            local p = root.Position
            notify("Posisi Saya",
                string.format("X=%.2f\nY=%.2f\nZ=%.2f",p.X,p.Y,p.Z),8)
            print(string.format("[XKID] X=%.4f  Y=%.4f  Z=%.4f",p.X,p.Y,p.Z))
        end
    end)

-- ╔═══════════════════════════════════════╗
-- ║            TAB PROTECT                ║
-- ╚═══════════════════════════════════════╝
local PP   = TProt:Page("Protection","shield")
local PPL  = PP:Section("🛡 Safety","Left")
local PPR  = PP:Section("ℹ Info","Right")

local afkConn = nil
PPL:Toggle("Anti AFK","antiAfk",false,
    "Cegah auto disconnect saat idle",
    function(v)
        if v then
            if afkConn then afkConn:Disconnect() end
            afkConn = LP.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            if afkConn then afkConn:Disconnect(); afkConn=nil end
        end
        notify("Anti AFK",v and "ON" or "OFF",2)
    end)

PPL:Button("💀 Respawn di Sini","Mati & kembali ke posisi terakhir",
    function()
        local saved = lastCFrame
        local char  = LP.Character
        if char then char:BreakJoints() end
        local conn
        conn = LP.CharacterAdded:Connect(function(nc)
            conn:Disconnect()
            task.wait(1)
            local hrp = nc:WaitForChild("HumanoidRootPart",5)
            if hrp and saved then
                hrp.CFrame = saved
                notify("Respawn","Kembali ke posisi!",3)
            end
        end)
    end)

PPL:Button("🔄 Rejoin Server","Koneksi ulang ke server",
    function()
        notify("Rejoin","Menghubungkan ulang...",3)
        task.wait(1)
        TpService:Teleport(game.PlaceId, LP)
    end)

PPL:Button("📌 Posisi Saya","Koordinat sekarang",
    function()
        local r = getRoot()
        if r then
            local p = r.Position
            notify("Posisi",
                string.format("X=%.1f\nY=%.1f\nZ=%.1f",p.X,p.Y,p.Z),6)
        end
    end)

PPR:Paragraph("Anti AFK",
    "Simulasi input saat idle\nCegah auto disconnect\ndari server")

PPR:Paragraph("Respawn",
    "Posisi disimpan tiap frame\nMati → kembali ke posisi\nterakhir sebelum mati")

-- ┌─────────────────────────────────────────┐
-- │              INIT                       │
-- └─────────────────────────────────────────┘
task.spawn(function()
    task.wait(2)
    local plots = scanPlots()
    if #plots == 0 then
        notify("⚠ WARNING",
            "Plot tidak ditemukan!\nBuka tab Farm → Cek Plot\nuntuk debug",6)
    else
        notify("✅ Ready",
            #plots.." plot terdeteksi!\nXKID HUB siap digunakan",4)
    end
end)

Library:Notification("XKID HUB v4.0",
    "Farm · Fish · ESP · Teleport · Save Location", 6)
Library:ConfigSystem(Win)

print("[XKID HUB] v4.0 loaded — "..LP.Name)
