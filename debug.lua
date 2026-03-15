--[[
  ╔══════════════════════════════════════════════════════╗
  ║       🌟  X K I D . H U B  F U L L  v4.0  🌟      ║
  ║       Aurora UI  ✦  Mobile  ✦  BridgeNet2          ║
  ╚══════════════════════════════════════════════════════╝
]]

-- ════════════════════════════════════════
--  AURORA UI
-- ════════════════════════════════════════
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService   = game:GetService("TeleportService")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")
local LP          = Players.LocalPlayer

-- ════════════════════════════════════════
--  BRIDGENET2 — Safe load
-- ════════════════════════════════════════
local dataRE = nil
pcall(function()
    local BN2 = RS:FindFirstChild("BridgeNet2")
    if BN2 then dataRE = BN2:FindFirstChild("dataRemoteEvent") end
end)

local ID_BUY     = "\x05"
local ID_PLANT   = "\x06"
local ID_HARVEST = "\x09"

-- ════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════
local Win = Library:Window("🌟 XKID FULL", "star", "v4.0 Mobile", false)

-- ════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════
Win:TabSection("🌾 FARM")
local TabFarm = Win:Tab("🌾 Farm",      "wheat")
local TabPola = Win:Tab("🎨 Pola",      "grid")
local TabLahan= Win:Tab("📍 Lahan",     "map-pin")

Win:TabSection("🛠 HUB")
local TabTP   = Win:Tab("📍 Teleport",  "map-pin")
local TabFly  = Win:Tab("🚀 Fly",       "rocket")
local TabSpd  = Win:Tab("⚡ Speed",     "zap")
local TabProt = Win:Tab("🛡 Protect",   "shield")
local TabToko = Win:Tab("🛒 Toko",      "shopping-cart")

-- ════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════
local function getChar()  return LP.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getDist(a, b)
    return math.floor((a - b).Magnitude + 0.5)
end

-- ════════════════════════════════════════
--  TANAMAN DATA
-- ════════════════════════════════════════
local CROPS = {
    { name="🥬 Sawi",   cropName="Sawi",      seedName="Bibit Sawi",   sellPrice=20,    seedPrice=15    },
    { name="🌾 Padi",   cropName="Padi",      seedName="Bibit Padi",   sellPrice=35,    seedPrice=20    },
    { name="🍅 Tomat",  cropName="Tomat",     seedName="Bibit Tomat",  sellPrice=65,    seedPrice=40    },
    { name="🍈 Melon",  cropName="Melon",     seedName="Bibit Melon",  sellPrice=130,   seedPrice=70    },
    { name="🥥 Kelapa", cropName="Coconut",   seedName="Bibit Kelapa", sellPrice=1150,  seedPrice=800   },
    { name="🍎 Apel",   cropName="AppleTree", seedName="Bibit Apel",   sellPrice=2667,  seedPrice=2000  },
    { name="🌼 Daisy",  cropName="Daisy",     seedName="Bibit Daisy",  sellPrice=18333, seedPrice=15000 },
}
local function getCrop(name)
    for _, c in ipairs(CROPS) do
        if c.name == name then return c end
    end
    return CROPS[1]
end
local function getCropByCropName(cn)
    for _, c in ipairs(CROPS) do
        if c.cropName == cn then return c end
    end
    return CROPS[1]
end

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local selectedCrop   = "🥬 Sawi"
local buyQty         = 5
local plantDelay     = 0.3
local farmOn         = false
local farmLoop       = nil
local farmStatus     = "💤 Idle"
local totalHarvest   = 0
local totalCoins     = 0
local harvestConn    = nil
local autoPanenOn    = false
local autoPanenLoop  = nil
local tokoPos        = nil
local harvestTimer   = 0    -- countdown timer
local timerLoop      = nil
local patternSize    = 10
local patternSpacing = 2
local selectedPola   = "⭕ Bulat"
local previewPts     = {}

-- Qty per item override (key=cropName, val=qty)
local itemQtyOverride = {}
-- Hasil scan ProximityPrompt di lahan
local scannedPrompts  = {}
local selectedPromptIdx = 1

-- HUB state
local curWS           = 16
local curJP           = 50
local flyOn           = false
local flySpeed        = 60
local flyBV, flyBG, flyConn
local noclipOn        = false
local noclipConn      = nil
local espOn           = false
local espBills        = {}
local espConns        = {}
local afkConn         = nil
local antiKickOn      = false
local slots           = {}
local PITCH_UP        =  0.3
local PITCH_DOWN      = -0.3
local autoRespawnOn   = false
local respawnMode     = "Natural"
local respawnConn     = nil
local lastPos         = nil
local respawnWaitTime = 1.0

-- Posisi lahan (dari spy + hook, 2 map)
local LAHAN = {
    Vector3.new(517.92, 22.07,  -58.40),
    Vector3.new(564.19, 22.83,  -67.26),
    Vector3.new(582.31, 23.65, -171.46),
    Vector3.new(617.29, 41.72, -105.20),
    Vector3.new(619.11, 41.72, -105.57),
    Vector3.new(428.37, 42.00, -115.21),
    Vector3.new(435.55, 42.00,  -95.55),
    Vector3.new(433.45, 42.00, -106.22),
    Vector3.new(439.32, 42.00,  -93.10),
    Vector3.new(440.72, 42.00,  -91.84),
    Vector3.new(561.91, 23.29,  -63.78),
    Vector3.new(562.30, 23.29,  -64.19),
    Vector3.new(562.86, 23.29,  -62.98),
    Vector3.new(563.48, 23.29,  -62.55),
    Vector3.new(563.00, 23.29,  -66.56),
}

-- ════════════════════════════════════════
--  RE-APPLY ON RESPAWN
-- ════════════════════════════════════════
LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    task.wait(0.5)
    hum.WalkSpeed    = curWS
    hum.JumpPower    = curJP
    hum.UseJumpPower = true
    if flyOn then
        task.wait(0.3)
        local r2 = char:FindFirstChild("HumanoidRootPart")
        if r2 then
            if flyBV then pcall(function() flyBV:Destroy() end) end
            if flyBG then pcall(function() flyBG:Destroy() end) end
            flyBV = Instance.new("BodyVelocity", r2)
            flyBV.Velocity = Vector3.new()
            flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBG = Instance.new("BodyGyro", r2)
            flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            flyBG.P = 1e4; flyBG.D = 100
            flyBG.CFrame = r2.CFrame
            hum.PlatformStand = true
        end
    end
end)

-- ════════════════════════════════════════
--  FARM CORE
-- ════════════════════════════════════════
local function setStatus(s)
    farmStatus = s
end

local function beliBibit(cropName, qty)
    if not dataRE then return false end
    return pcall(function()
        dataRE:FireServer({
            { { cropName = cropName, count = qty } },
            ID_BUY,
        })
    end)
end

local function tpToToko()
    if not tokoPos then
        Library:Notification("🏪 Toko", "Scan toko dulu!", 2)
        return false
    end
    local root = getRoot(); if not root then return false end
    root.CFrame = CFrame.new(tokoPos) * CFrame.new(0, 3, 0)
    task.wait(0.5)
    return true
end

local function tpToLahan(idx)
    idx = idx or 1
    if #LAHAN == 0 then return end
    if idx > #LAHAN then idx = 1 end
    local root = getRoot(); if not root then return end
    local pos  = LAHAN[idx]
    root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    task.wait(0.3)
end

-- Cari hitPart untuk tanam — pakai GetChildren index seperti Cobalt
local function findLandPart(pos)
    -- Cari BasePart terdekat bernama Land/Lahan/Plot
    local best    = nil
    local bestDist= math.huge
    local children = Workspace:GetChildren()
    for _, v in ipairs(children) do
        if v:IsA("BasePart") then
            local nl = v.Name:lower()
            if nl:find("land") or nl:find("lahan") or nl:find("plot") or nl == "land" then
                local d = (v.Position - pos).Magnitude
                if d < bestDist then bestDist = d; best = v end
            end
        end
        -- Cek descendants juga
        for _, vv in pairs(v:GetDescendants()) do
            if vv:IsA("BasePart") then
                local nl = vv.Name:lower()
                if nl:find("land") or nl:find("lahan") or nl:find("plot") then
                    local d = (vv.Position - pos).Magnitude
                    if d < bestDist then bestDist = d; best = vv end
                end
            end
        end
    end
    -- Fallback ke Workspace.Land
    if not best then best = Workspace:FindFirstChild("Land") end
    return best
end

local function tanamSemua(cropName)
    if not dataRE then return 0 end
    -- Reset planted positions untuk sesi tanam baru
    plantedPos = {}
    local n        = 0
    local landPart = Workspace:FindFirstChild("Land")
    local minD     = math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local nl = v.Name:lower()
            if nl:find("land") or nl:find("lahan") or nl:find("plot") then
                local root = getRoot()
                if root then
                    local d = (v.Position - root.Position).Magnitude
                    if d < minD then minD=d; landPart=v end
                end
            end
        end
    end
    for _, pos in ipairs(LAHAN) do
        local root = getRoot()
        if root then
            root.CFrame = CFrame.new(pos.X, pos.Y+3, pos.Z)
            task.wait(0.2)
        end
        local ok = pcall(function()
            dataRE:FireServer({
                {slotIdx=1, hitPosition=pos, hitPart=landPart},
                ID_PLANT,
            })
        end)
        if ok then
            n = n + 1
            -- Simpan posisi tanam untuk harvest nanti!
            addPlantedPos(pos, cropName)
        end
        task.wait(plantDelay)
    end
    return n
end

-- ════════════════════════════════════════
--  HARVEST — TP ke tiap lahan → trigger
--  ProximityPrompt terdekat
--  Karakter HARUS dekat tanaman dulu!
-- ════════════════════════════════════════

-- Filter ProximityPrompt: bukan sit/chair/door
local IGNORE_PROMPT = {
    "sit","chair","seat","ride","door","gate","shop",
    "toko","npc","vehicle","car","boat","bed","sleep",
}
local function isValidHarvestPrompt(prompt)
    local action = (prompt.ActionText or ""):lower()
    local obj    = (prompt.ObjectText  or ""):lower()
    local pname  = prompt.Parent and prompt.Parent.Name:lower() or ""
    -- Cek ignore list
    for _, kw in ipairs(IGNORE_PROMPT) do
        if action:find(kw) or obj:find(kw) or pname:find(kw) then
            return false
        end
    end
    -- Hanya trigger kalau action text ada kata panen/harvest/ambil/pick
    -- ATAU nama parent mirip tanaman
    local harvestWords = {"panen","harvest","ambil","collect","pick","petik"}
    for _, kw in ipairs(harvestWords) do
        if action:find(kw) then return true end
    end
    local cropWords = {"sawi","padi","tomat","melon","coconut","appletree",
        "daisy","fanpalm","sunflower","sawit","crop","plant","tanaman"}
    for _, kw in ipairs(cropWords) do
        if pname:find(kw) then return true end
    end
    return false
end

local function triggerNearbyPrompt(pos, radius)
    radius = radius or 8
    local triggered = 0
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and isValidHarvestPrompt(v) then
            local parent = v.Parent
            if parent then
                local ppos = parent:IsA("BasePart") and parent.Position
                          or (parent.PrimaryPart and parent.PrimaryPart.Position)
                if ppos and (ppos - pos).Magnitude <= radius then
                    pcall(function() fireproximityprompt(v) end)
                    pcall(function() v:TriggerEnded(LP) end)
                    triggered = triggered + 1
                    task.wait(0.05)
                end
            end
        end
    end
    return triggered
end

local function harvestSemua(cropName)
    local n    = 0
    local root = getRoot()
    if not root then return 0 end

    -- Simpan posisi awal
    local savedCF = root.CFrame

    -- TP ke tiap lahan → trigger prompt di dekat sana
    for _, pos in ipairs(LAHAN) do
        -- TP ke posisi lahan
        root.CFrame = CFrame.new(pos.X, pos.Y + 2, pos.Z)
        task.wait(0.3)

        -- Trigger ProximityPrompt dalam radius 8 studs
        local triggered = triggerNearbyPrompt(pos, 8)
        if triggered > 0 then n = n + triggered end

        -- Juga coba FireServer \x09 kalau ada
        if dataRE then
            pcall(function()
                dataRE:FireServer({
                    { amount = 1, cropName = cropName },
                    ID_HARVEST,
                })
            end)
        end
        task.wait(0.2)
    end

    -- Kembali ke posisi awal
    task.wait(0.3)
    root.CFrame = savedCF

    return n
end

local function startHarvestMonitor()
    if harvestConn then pcall(function() harvestConn:Disconnect() end) end
    if not dataRE then return end
    harvestConn = dataRE.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        for k, v in pairs(data) do
            if k == "\x0F" and type(v) == "table" then
                for _, entry in ipairs(v) do
                    if type(entry) == "table" and entry.cropName then
                        totalHarvest = totalHarvest + 1
                        totalCoins   = totalCoins + (entry.sellPrice or 0)
                    end
                end
            end
            if k == "\x04" and type(v) == "table" and v[1] then
                totalCoins = v[1]
            end
        end
    end)
end

-- ════════════════════════════════════════
-- ════════════════════════════════════════
--  HARVEST SYSTEM v3
--  Posisi panen = posisi tanam (akurat!)
--  Default: LAHAN list, update saat tanam
-- ════════════════════════════════════════

local plantedPos = {}
local MY_NAME    = LP.Name

local function initPlantedFromLahan(cropName)
    plantedPos = {}
    for _, pos in ipairs(LAHAN) do
        table.insert(plantedPos, {pos=pos, cropName=cropName, time=os.time()})
    end
end

local function addPlantedPos(pos, cropName)
    for _, p in ipairs(plantedPos) do
        if (p.pos - pos).Magnitude < 2 then
            p.cropName=cropName; p.time=os.time(); return
        end
    end
    table.insert(plantedPos, {pos=pos, cropName=cropName, time=os.time()})
end

local function findHarvestPromptAt(pos, radius)
    radius = radius or 10
    local best, bestDist = nil, math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local parent = v.Parent
            if parent then
                local ppos = parent:IsA("BasePart") and parent.Position
                          or (parent.PrimaryPart and parent.PrimaryPart.Position)
                if ppos and (ppos - pos).Magnitude <= radius then
                    local action = (v.ActionText or ""):lower()
                    local obj    = (v.ObjectText  or ""):lower()
                    local isPanen = action:find("panen") or action:find("harvest")
                                 or action:find("petik") or action:find("ambil")
                                 or obj:find(MY_NAME:lower())
                    local isIgnore = action:find("sit") or action:find("ride")
                                  or action:find("door") or action:find("shop")
                    if isPanen and not isIgnore then
                        local d = (ppos - pos).Magnitude
                        if d < bestDist then bestDist=d; best=v end
                    end
                end
            end
        end
    end
    return best
end

local function harvestSemua(cropName)
    local root = getRoot(); if not root then return 0 end
    if #plantedPos == 0 then initPlantedFromLahan(cropName) end
    local savedCF = root.CFrame
    local n = 0
    for _, planted in ipairs(plantedPos) do
        root.CFrame = CFrame.new(planted.pos.X, planted.pos.Y+2, planted.pos.Z)
        task.wait(0.3)
        local prompt = findHarvestPromptAt(planted.pos, 10)
        if prompt then
            pcall(function() fireproximityprompt(prompt) end)
            pcall(function() prompt:TriggerEnded(LP) end)
            n = n + 1
        end
        if dataRE then
            pcall(function()
                dataRE:FireServer({{amount=1,cropName=planted.cropName},ID_HARVEST})
            end)
        end
        task.wait(0.15)
    end
    task.wait(0.3); root.CFrame = savedCF
    return n
end

local function startHarvestMonitor()
    if harvestConn then pcall(function() harvestConn:Disconnect() end) end
    if not dataRE then return end
    harvestConn = dataRE.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        for k, v in pairs(data) do
            if k == "\x0F" and type(v) == "table" then
                for _, entry in ipairs(v) do
                    if type(entry)=="table" and entry.cropName then
                        totalHarvest = totalHarvest + 1
                        totalCoins   = totalCoins + (entry.sellPrice or 0)
                        if entry.cropPos then addPlantedPos(entry.cropPos, entry.cropName) end
                    end
                end
            end
            if k == "\x04" and type(v)=="table" and v[1] then totalCoins = v[1] end
        end
    end)
end

local function startAutoFarm()
    if not dataRE then
        Library:Notification("❌ Farm", "BridgeNet2 tidak ada!", 4); return
    end
    startHarvestMonitor()
    farmLoop = task.spawn(function()
        while farmOn do
            local crop = getCrop(selectedCrop)

            -- Step 1: TP ke toko & beli
            setStatus("🏪 Beli " .. crop.seedName)
            Library:Notification("🌾 Farm", "🏪 " .. crop.seedName .. " x" .. buyQty, 2)
            tpToToko()
            beliBibit(crop.cropName, buyQty)
            task.wait(1)

            -- Step 2: TP ke lahan & tanam
            setStatus("🌱 Menanam " .. crop.cropName)
            tpToLahan(1)
            local planted = tanamSemua(crop.cropName)
            Library:Notification("🌱 Tanam", planted .. " lahan ditanam!", 2)

            -- Step 3: Tunggu & harvest tiap 5 detik
            local waitMax = 300
            harvestTimer  = waitMax
            setStatus("⏳ Menunggu panen...")

            -- Start countdown timer
            if timerLoop then pcall(function() task.cancel(timerLoop) end) end
            timerLoop = task.spawn(function()
                while farmOn and harvestTimer > 0 do
                    task.wait(1)
                    harvestTimer = harvestTimer - 1
                    setStatus(string.format("⏳ Panen dalam %ds", harvestTimer))
                end
            end)

            local waited = 0
            while farmOn and waited < waitMax do
                task.wait(5); waited = waited + 5
                local harvested = harvestSemua(crop.cropName)
                if harvested > 0 then
                    setStatus("🌾 Panen! +" .. totalCoins .. " coins")
                    Library:Notification("🌾 Panen!",
                        string.format(
                            "✅ %s dipanen!\n💰 Coins: %d\n📦 Total: %d kali",
                            crop.cropName, totalCoins, totalHarvest), 4)
                end
            end
            setStatus("🔄 Loop berikutnya...")
            task.wait(1)
        end
        setStatus("💤 Idle")
        Library:Notification("🌾 Farm", "⛔ Dihentikan", 2)
    end)
end

local function stopAutoFarm()
    farmOn = false
    if farmLoop then pcall(function() task.cancel(farmLoop) end); farmLoop = nil end
    if timerLoop then pcall(function() task.cancel(timerLoop) end); timerLoop = nil end
    if harvestConn then pcall(function() harvestConn:Disconnect() end); harvestConn = nil end
    setStatus("💤 Idle")
end

-- Scan toko
local TOKO_KW = {"toko","shop","bibit","seed","store","merchant","seller","jual"}
local function scanToko()
    for _, v in pairs(Workspace:GetDescendants()) do
        local isModel = v:IsA("Model")
        local isPart  = v:IsA("BasePart")
        if isModel or isPart then
            local n = v.Name:lower()
            for _, kw in ipairs(TOKO_KW) do
                if n:find(kw) then
                    if isModel then
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                               or v:FindFirstChildOfClass("Part")
                               or v.PrimaryPart
                        if hrp then tokoPos = hrp.Position; return true, v.Name end
                    else
                        tokoPos = v.Position; return true, v.Name
                    end
                end
            end
        end
    end
    return false, nil
end

-- ════════════════════════════════════════
--  POLA TANAM
-- ════════════════════════════════════════
local function genBulat(cx,y,cz,r,sp)
    local pts={};local steps=math.max(8,math.floor(2*math.pi*r/sp))
    for i=0,steps-1 do local t=(2*math.pi*i)/steps
        table.insert(pts,Vector3.new(cx+r*math.cos(t),y,cz+r*math.sin(t))) end
    return pts
end
local function genKotak(cx,y,cz,sz,sp)
    local pts={};local half=sz/2;local s=-half
    while s<=half do
        table.insert(pts,Vector3.new(cx+s,y,cz-half))
        table.insert(pts,Vector3.new(cx+s,y,cz+half))
        table.insert(pts,Vector3.new(cx-half,y,cz+s))
        table.insert(pts,Vector3.new(cx+half,y,cz+s))
        s=s+sp end return pts
end
local function genSegitiga(cx,y,cz,sz,sp)
    local pts={};local h=sz*math.sqrt(3)/2
    local p1x,p1z=cx,cz-h*2/3;local p2x,p2z=cx-sz/2,cz+h/3;local p3x,p3z=cx+sz/2,cz+h/3
    local function addS(ax,az,bx,bz)
        local d=math.sqrt((bx-ax)^2+(bz-az)^2);local s=math.max(1,math.floor(d/sp))
        for i=0,s do local t=i/s;table.insert(pts,Vector3.new(ax+(bx-ax)*t,y,az+(bz-az)*t)) end
    end
    addS(p1x,p1z,p2x,p2z);addS(p2x,p2z,p3x,p3z);addS(p3x,p3z,p1x,p1z);return pts
end
local function genHati(cx,y,cz,sz,sp)
    local pts={};local steps=math.max(30,math.floor(150*sz/10));local scale=sz/16
    for i=0,steps do local t=(2*math.pi*i)/steps
        local hx=16*math.sin(t)^3
        local hz=-(13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))
        table.insert(pts,Vector3.new(cx+hx*scale,y,cz+hz*scale)) end
    return pts
end
local function genPlus(cx,y,cz,sz,sp)
    local pts={};local s=-sz
    while s<=sz do
        table.insert(pts,Vector3.new(cx+s,y,cz))
        if math.abs(s)>sp then table.insert(pts,Vector3.new(cx,y,cz+s)) end
        s=s+sp end return pts
end
local function genSpiral(cx,y,cz,sz,sp)
    local pts={};local t=0;local dt=0.15
    while true do local r=sp*t/(2*math.pi);if r>sz then break end
        table.insert(pts,Vector3.new(cx+r*math.cos(t),y,cz+r*math.sin(t)));t=t+dt end
    return pts
end
local function generatePola(name,cx,y,cz)
    if     name=="⭕ Bulat"    then return genBulat   (cx,y,cz,patternSize,patternSpacing)
    elseif name=="⬜ Kotak"    then return genKotak   (cx,y,cz,patternSize,patternSpacing)
    elseif name=="🔺 Segitiga" then return genSegitiga(cx,y,cz,patternSize,patternSpacing)
    elseif name=="❤️ Hati"    then return genHati    (cx,y,cz,patternSize,patternSpacing)
    elseif name=="➕ Plus"     then return genPlus    (cx,y,cz,patternSize,patternSpacing)
    elseif name=="🌀 Spiral"   then return genSpiral  (cx,y,cz,patternSize,patternSpacing)
    end; return {}
end
local function tanamPola(pts,cropName)
    if not dataRE then Library:Notification("❌","BridgeNet2 tidak ada!",3);return 0 end
    local landPart=Workspace:FindFirstChild("Land");local n=0
    for _,pos in ipairs(pts) do
        local ok=pcall(function()
            dataRE:FireServer({{slotIdx=1,hitPosition=pos,hitPart=landPart},ID_PLANT}) end)
        if ok then n=n+1 end;task.wait(plantDelay) end
    return n
end

-- ════════════════════════════════════════
--  FLY
-- ════════════════════════════════════════
local function startFly()
    local root=getRoot();if not root then return end
    local hum=getHum();if not hum then return end
    if flyBV then pcall(function() flyBV:Destroy() end) end
    if flyBG then pcall(function() flyBG:Destroy() end) end
    if flyConn then pcall(function() flyConn:Disconnect() end) end
    flyBV=Instance.new("BodyVelocity",root);flyBV.Velocity=Vector3.new()
    flyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
    flyBG=Instance.new("BodyGyro",root);flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5)
    flyBG.P=1e4;flyBG.D=100;flyBG.CFrame=root.CFrame;hum.PlatformStand=true
    flyConn=RunService.Heartbeat:Connect(function()
        local r2=getRoot();if not r2 or not flyBV then return end
        local h2=getHum();if not h2 then return end
        local cf=Workspace.CurrentCamera.CFrame
        local camF=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
        local camR=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z)
        if camF.Magnitude>0 then camF=camF.Unit end
        if camR.Magnitude>0 then camR=camR.Unit end
        local md=h2.MoveDirection;local hor=Vector3.new()
        if md.Magnitude>0.05 then
            hor=camF*md:Dot(camF)+camR*md:Dot(camR)
            if hor.Magnitude>1 then hor=hor.Unit end end
        local py=cf.LookVector.Y;local ver=Vector3.new()
        if py>PITCH_UP then ver=Vector3.new(0,math.min((py-PITCH_UP)/(1-PITCH_UP),1),0)
        elseif py<PITCH_DOWN then ver=Vector3.new(0,-math.min((-py+PITCH_DOWN)/(1+PITCH_DOWN),1),0) end
        local dir=hor+ver
        if dir.Magnitude>0 then
            flyBV.Velocity=(dir.Magnitude>1 and dir.Unit or dir)*flySpeed
            if hor.Magnitude>0.05 then flyBG.CFrame=CFrame.new(Vector3.new(),hor) end
        else flyBV.Velocity=Vector3.new() end
        h2.PlatformStand=true end)
end
local function stopFly()
    if flyConn then pcall(function() flyConn:Disconnect() end);flyConn=nil end
    if flyBV   then pcall(function() flyBV:Destroy()      end);flyBV=nil   end
    if flyBG   then pcall(function() flyBG:Destroy()      end);flyBG=nil   end
    local hum=getHum();if hum then hum.PlatformStand=false end
end

-- ════════════════════════════════════════
--  NOCLIP
-- ════════════════════════════════════════
local function setNoclip(v)
    noclipOn=v
    if v then
        noclipConn=RunService.Stepped:Connect(function()
            local c=getChar();if not c then return end
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end end end)
    else
        if noclipConn then noclipConn:Disconnect();noclipConn=nil end
        local c=getChar()
        if c then for _,p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end end end end
end

-- ════════════════════════════════════════
--  ESP
-- ════════════════════════════════════════
local function clearESP()
    for _,b in ipairs(espBills) do pcall(function() b:Destroy() end) end
    for _,c in ipairs(espConns) do pcall(function() c:Disconnect() end) end
    espBills={};espConns={}
end
local function makeESP(player)
    if player==LP then return end
    local function onChar(char)
        if not espOn then return end;task.wait(0.5)
        local head=char:FindFirstChild("Head");if not head then return end
        local bill=Instance.new("BillboardGui")
        bill.Size=UDim2.new(0,180,0,50);bill.StudsOffset=Vector3.new(0,3,0)
        bill.AlwaysOnTop=true;bill.Adornee=head;bill.Parent=char
        local bg=Instance.new("Frame",bill);bg.Size=UDim2.new(1,0,1,0)
        bg.BackgroundColor3=Color3.fromRGB(0,0,0);bg.BackgroundTransparency=0.45
        bg.BorderSizePixel=0;Instance.new("UICorner",bg).CornerRadius=UDim.new(0,6)
        local lbl=Instance.new("TextLabel",bg);lbl.Size=UDim2.new(1,-6,1,-4)
        lbl.Position=UDim2.new(0,3,0,2);lbl.BackgroundTransparency=1
        lbl.TextColor3=Color3.fromRGB(255,230,80);lbl.TextStrokeTransparency=0.3
        lbl.TextScaled=true;lbl.Font=Enum.Font.GothamBold
        lbl.TextXAlignment=Enum.TextXAlignment.Center
        local upd=RunService.Heartbeat:Connect(function()
            if not bill or not bill.Parent then return end
            local mr=getRoot();local d=mr and getDist(head.Position,mr.Position) or 0
            lbl.Text=string.format("👤 %s\n📍 %dm",player.Name,d) end)
        table.insert(espConns,upd);table.insert(espBills,bill) end
    if player.Character then onChar(player.Character) end
    table.insert(espConns,player.CharacterAdded:Connect(onChar))
end
local function toggleESP(v)
    espOn=v;clearESP()
    if v then
        for _,p in pairs(Players:GetPlayers()) do makeESP(p) end
        table.insert(espConns,Players.PlayerAdded:Connect(makeESP)) end
    Library:Notification("👁 ESP",v and "ON" or "OFF",2)
end

-- ════════════════════════════════════════
--  TELEPORT
-- ════════════════════════════════════════
local function infer_plr(ref)
    if typeof(ref)~="string" then return ref end
    local best,min=nil,math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP then
            local nv=math.huge;local un,dn=p.Name,p.DisplayName
            if     un:find("^"..ref)                 then nv=1.0*(#un-#ref)
            elseif dn:find("^"..ref)                 then nv=1.5*(#dn-#ref)
            elseif un:lower():find("^"..ref:lower()) then nv=2.0*(#un-#ref)
            elseif dn:lower():find("^"..ref:lower()) then nv=2.5*(#dn-#ref) end
            if nv<min then best=p;min=nv end end end
    return best
end
local function tpToPlayer(ref)
    if not ref or ref=="" then Library:Notification("❌","Ketik nama dulu!",2);return end
    local pl=infer_plr(ref)
    if not pl then Library:Notification("❌","Player tidak ditemukan",2);return end
    if not pl.Character then Library:Notification("❌",pl.Name.." offline",2);return end
    local hrp=pl.Character:FindFirstChild("HumanoidRootPart") or pl.Character:FindFirstChild("Torso")
    if not hrp then return end
    local c=getChar();if c then c:PivotTo(hrp.CFrame*CFrame.new(0,3,0)) end
    Library:Notification("📍 TP","→ "..pl.Name,2)
end
local function tpToMouse()
    local mouse=LP:GetMouse()
    if mouse and mouse.Hit then
        local root=getRoot()
        if root then root.CFrame=mouse.Hit*CFrame.new(0,3,0)
            Library:Notification("📍 TP","Ke posisi mouse",2) end end
end
local function quickRespawn()
    local root=getRoot();if not root then return end
    local savedCF=root.CFrame;local sWS,sJP=curWS,curJP
    local c=getChar();if c then c:BreakJoints() end
    local conn;conn=LP.CharacterAdded:Connect(function(newChar)
        conn:Disconnect();task.wait(0.8)
        local hrp=newChar:WaitForChild("HumanoidRootPart",5)
        local hum=newChar:WaitForChild("Humanoid",5)
        if hrp then hrp.CFrame=savedCF end
        if hum then hum.WalkSpeed=sWS;hum.JumpPower=sJP;hum.UseJumpPower=true end
        Library:Notification("✅ Respawn","Kembali ke posisi semula",2) end)
end

-- ════════════════════════════════════════
--  PROTECTION
-- ════════════════════════════════════════
local function startAntiAFK()
    if afkConn then return end
    afkConn=LP.Idled:Connect(function()
        VirtualUser:CaptureController();VirtualUser:ClickButton2(Vector2.new()) end)
end
local function stopAntiAFK()
    if afkConn then afkConn:Disconnect();afkConn=nil end end
local function startAntiKick()
    if antiKickOn then return end;antiKickOn=true
    task.spawn(function()
        while antiKickOn do pcall(function()
            local hum=getHum()
            if hum and hum.Health>0 and hum.Health<hum.MaxHealth*0.1 then
                hum.Health=hum.MaxHealth end end);task.wait(0.5) end end)
end
local function stopAntiKick() antiKickOn=false end
local function setupAutoRespawn()
    if respawnConn then pcall(function() respawnConn:Disconnect() end);respawnConn=nil end
    if not autoRespawnOn then return end
    local function hookChar(char)
        local hum=char:WaitForChild("Humanoid",5);local root=char:WaitForChild("HumanoidRootPart",5)
        if not hum or not root then return end
        local pc=RunService.Heartbeat:Connect(function()
            if root and root.Parent then lastPos=root.CFrame end end)
        hum.Died:Connect(function()
            pc:Disconnect();local savedCF=lastPos;if not savedCF then return end
            if respawnMode=="Cepat" then task.wait(0.1);pcall(function() char:BreakJoints() end) end
            local c2;c2=LP.CharacterAdded:Connect(function(newChar)
                c2:Disconnect();task.wait(respawnWaitTime)
                local hrp=newChar:WaitForChild("HumanoidRootPart",5)
                local hm2=newChar:WaitForChild("Humanoid",5)
                if hrp then hrp.CFrame=savedCF end
                if hm2 then hm2.WalkSpeed=curWS;hm2.JumpPower=curJP;hm2.UseJumpPower=true end
                Library:Notification("✅ Respawn","Mode: "..respawnMode,3)
                task.wait(1);if autoRespawnOn then hookChar(newChar) end end) end)
    end
    if LP.Character then hookChar(LP.Character) end
    respawnConn=LP.CharacterAdded:Connect(function() end)
end

-- ════════════════════════════════════════
--  BUILD UI — TAB FARM
-- ════════════════════════════════════════
local FarmPage = TabFarm:Page("🌾 Auto Farm", "wheat")
local FarmL    = FarmPage:Section("⚙️ Controls", "Left")
local FarmR    = FarmPage:Section("🌱 Tanaman & Info", "Right")

-- KIRI: Controls
local cropNames = {}
for _, c in ipairs(CROPS) do table.insert(cropNames, c.name) end

FarmL:Toggle("🌾 AUTO FARM", "AutoFarmTog", false,
    "Otomatis beli → tanam → panen loop",
    function(v)
        farmOn = v
        if v then startAutoFarm() else stopAutoFarm() end
        Library:Notification("🌾 Farm", v and "✅ ON" or "⛔ OFF", 2)
    end)

FarmL:Slider("⏱️ Delay Tanam", "PlantDly", 1, 20, 3,
    function(v) plantDelay = v * 0.1 end, "Jeda antar tanam (x0.1 detik)")

FarmL:Toggle("🌾 Auto Panen", "AutoPanenTog", false,
    "Harvest otomatis tiap 5 detik",
    function(v)
        autoPanenOn = v
        if v then
            autoPanenLoop = task.spawn(function()
                while autoPanenOn do
                    local crop = getCrop(selectedCrop)
                    local n = harvestSemua(crop.cropName)
                    if n > 0 then
                        Library:Notification("🌾 Auto Panen",
                            string.format("✅ %d dipanen!\n💰 Coins: %d", n, totalCoins), 3)
                    end
                    task.wait(10)  -- tiap 10 detik
                end
            end)
            Library:Notification("🌾 Auto Panen",
                "✅ ON — tiap 10 detik\nTP ke tiap lahan → panen", 3)
        else
            if autoPanenLoop then
                pcall(function() task.cancel(autoPanenLoop) end)
                autoPanenLoop = nil
            end
            Library:Notification("🌾 Auto Panen", "⛔ OFF", 2)
        end
    end)

FarmL:Button("📊 Lihat Statistik", "Total panen & coins sesi ini",
    function()
        local crop = getCrop(selectedCrop)
        Library:Notification("📊 Statistik Farm",
            string.format(
                "🌱 Tanaman : %s\n"..
                "🌾 Panen   : %d kali\n"..
                "💰 Coins   : %d\n"..
                "📦 Buy Qty : %d\n"..
                "⚙️ Status  : %s",
                crop.cropName, totalHarvest, totalCoins,
                buyQty, farmStatus), 10)
    end)

FarmL:Button("🔄 Reset Statistik", "Reset counter",
    function()
        totalHarvest = 0; totalCoins = 0
        Library:Notification("🔄", "Statistik direset", 2)
    end)

FarmL:Button("🛑 STOP ALL", "Hentikan semua fitur sekaligus",
    function()
        -- Stop Farm
        farmOn = false
        if farmLoop then pcall(function() task.cancel(farmLoop) end); farmLoop=nil end
        if timerLoop then pcall(function() task.cancel(timerLoop) end); timerLoop=nil end
        if harvestConn then pcall(function() harvestConn:Disconnect() end); harvestConn=nil end
        -- Stop Auto Panen
        autoPanenOn = false
        if autoPanenLoop then pcall(function() task.cancel(autoPanenLoop) end); autoPanenLoop=nil end
        -- Stop Fly
        flyOn = false
        if flyConn then pcall(function() flyConn:Disconnect() end); flyConn=nil end
        if flyBV then pcall(function() flyBV:Destroy() end); flyBV=nil end
        if flyBG then pcall(function() flyBG:Destroy() end); flyBG=nil end
        local hum = getHum(); if hum then hum.PlatformStand=false end
        -- Stop NoClip
        noclipOn = false
        if noclipConn then pcall(function() noclipConn:Disconnect() end); noclipConn=nil end
        local c = getChar()
        if c then for _,p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end end end
        -- Stop ESP
        espOn = false
        for _,b in ipairs(espBills) do pcall(function() b:Destroy() end) end
        for _,conn in ipairs(espConns) do pcall(function() conn:Disconnect() end) end
        espBills={}; espConns={}
        -- Stop Anti AFK & Kick
        if afkConn then afkConn:Disconnect(); afkConn=nil end
        antiKickOn = false
        -- Stop Auto Respawn
        autoRespawnOn = false
        if respawnConn then pcall(function() respawnConn:Disconnect() end); respawnConn=nil end
        -- Reset status
        farmStatus = "💤 Idle"
        Library:Notification("🛑 STOP ALL",
            "✅ Semua fitur dihentikan!\n"..
            "Farm · AutoPanen · Fly\n"..
            "NoClip · ESP · AFK · Respawn", 5)
    end)

-- KANAN: Tanaman + Buy Qty
FarmR:Dropdown("🌱 Pilih Tanaman", "CropDD", cropNames,
    function(v) selectedCrop = v end)

FarmR:Paragraph("💰 Harga Tanaman",
    "🥬 Sawi    20 coins\n"..
    "🌾 Padi    35 coins\n"..
    "🍅 Tomat   65 coins\n"..
    "🍈 Melon   130 coins\n"..
    "🥥 Kelapa  1150 coins\n"..
    "🍎 Apel    2667 coins\n"..
    "🌼 Daisy   18333 coins")

FarmR:Slider("🛒 Buy Qty", "BuyQty", 1, 50, 5,
    function(v) buyQty = v end, "Jumlah bibit dibeli per siklus (1-50)")

local qtyInput = ""
FarmR:TextBox("✏️ Ketik Qty Manual", "QtyInput", "",
    function(v)
        qtyInput = v
        local num = tonumber(v)
        if num then
            buyQty = math.max(1, math.min(50, math.floor(num)))
            Library:Notification("🛒 Qty", "Buy Qty: " .. buyQty, 1)
        end
    end, "Ketik angka 1-50")

-- Manual Farm Page
local ManualPage = TabFarm:Page("🔧 Manual Farm", "tool")
local ManL       = ManualPage:Section("🏪 Toko & Beli", "Left")
local ManR       = ManualPage:Section("🌱 Tanam & Panen", "Right")

-- TOKO
ManL:Button("🔍 Scan Toko Bibit", "Cari NPC toko otomatis",
    function()
        task.spawn(function()
            Library:Notification("🔍", "Scanning...", 2)
            local ok, name = scanToko()
            Library:Notification(
                ok and "✅ Toko Ditemukan" or "❌ Tidak Ditemukan",
                ok and "📍 " .. name .. "\nSiap digunakan!"
                   or "Tidak ada NPC toko\nSave manual di bawah!", 4)
        end)
    end)

ManL:Button("💾 Save Posisi Toko", "Simpan posisi kamu sebagai toko",
    function()
        local root = getRoot()
        if root then
            tokoPos = root.Position
            local p = root.Position
            Library:Notification("💾 Toko Saved",
                string.format("X=%.0f Y=%.0f Z=%.0f", p.X, p.Y, p.Z), 3)
        end
    end)

ManL:Button("🏪 TP ke Toko", "Teleport ke NPC toko",
    function() tpToToko() end)

ManL:Button("🛒 Beli Bibit Sekarang", "FireServer beli bibit pilihan",
    function()
        local crop = getCrop(selectedCrop)
        local qty  = itemQtyOverride[crop.cropName] or buyQty
        task.spawn(function()
            local ok = beliBibit(crop.cropName, qty)
            Library:Notification(
                ok and "✅ Beli Berhasil" or "❌ Gagal",
                crop.seedName .. " x" .. qty, 3)
        end)
    end)

-- TANAM & PANEN
ManR:Button("📍 TP ke Lahan 1", "Teleport ke lahan pertama",
    function() tpToLahan(1) end)

ManR:Button("🌱 Tanam Sekarang", "TP ke tiap lahan lalu tanam",
    function()
        task.spawn(function()
            local crop = getCrop(selectedCrop)
            Library:Notification("🌱", "Menanam " .. crop.cropName .. "...", 2)
            local n = tanamSemua(crop.cropName)
            Library:Notification("✅ Tanam", n .. " lahan ditanam!", 3)
        end)
    end)

ManR:Button("🌾 Panen Sekarang", "TP ke tiap lahan lalu harvest",
    function()
        task.spawn(function()
            local crop = getCrop(selectedCrop)
            Library:Notification("🌾", "Harvesting...", 2)
            local n = harvestSemua(crop.cropName)
            Library:Notification("✅ Panen",
                n .. " lahan di-harvest!", 3)
        end)
    end)

-- SCAN PROMPT
ManR:Button("🔍 Scan Prompt di Lahan", "TP ke lahan → kumpulkan daftar ProximityPrompt",
    function()
        task.spawn(function()
            Library:Notification("🔍", "Scanning prompt di lahan...", 2)
            scannedPrompts = scanPromptsDekatLahan()
            if #scannedPrompts == 0 then
                Library:Notification("❌ Scan",
                    "Tidak ada ProximityPrompt\ndi dekat lahan kamu\n\nPastikan ada tanaman\nyang sudah tumbuh", 5)
                return
            end
            -- Tampilkan daftar dengan nama jelas
            local text = #scannedPrompts .. " prompt ditemukan:\n\n"
            for i, e in ipairs(scannedPrompts) do
                text = text .. string.format(
                    "[%d] %s\n    → %s\n\n",
                    i, e.parentName, e.actionText)
            end
            text = text .. "Tekan tombol per prompt di bawah!"
            Library:Notification("🔍 Prompt Lahan", text, 15)
        end)
    end)

-- Tombol per prompt — generate saat scan
-- Karena Aurora tidak bisa dynamic, kita pre-buat 10 tombol
-- yang aktif hanya kalau ada data di index tersebut
for i = 1, 10 do
    local idx = i
    ManR:Button("⚡ Trigger Prompt [" .. idx .. "]",
        "Trigger prompt nomor " .. idx .. " dari hasil scan",
        function()
            if #scannedPrompts == 0 then
                Library:Notification("❌", "Scan prompt dulu!", 2); return
            end
            if idx > #scannedPrompts then
                Library:Notification("❌",
                    "Prompt #"..idx.." tidak ada\nHanya ada "..#scannedPrompts.." prompt", 3)
                return
            end
            local e  = scannedPrompts[idx]
            local ok = triggerPromptByIdx(scannedPrompts, idx)
            Library:Notification(
                ok and "✅ Trigger!" or "❌ Gagal",
                string.format("[%d] %s\n→ %s", idx, e.parentName, e.actionText), 3)
        end)
end

ManR:Button("⚡ Trigger SEMUA Prompt", "Trigger semua prompt hasil scan",
    function()
        if #scannedPrompts == 0 then
            Library:Notification("❌", "Scan prompt dulu!", 2); return
        end
        task.spawn(function()
            local n = triggerAllPrompts(scannedPrompts)
            Library:Notification("✅ Trigger Semua", n .. " prompt di-trigger!", 3)
        end)
    end)

ManR:Toggle("👁️ Monitor Panen", "MonitorTog", false,
    "Monitor notif coins dari server",
    function(v)
        if v then startHarvestMonitor()
        else
            if harvestConn then
                pcall(function() harvestConn:Disconnect() end)
                harvestConn = nil
            end
        end
        Library:Notification("👁️ Monitor", v and "ON" or "OFF", 2)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB POLA
-- ════════════════════════════════════════
local PolaPage = TabPola:Page("🎨 Pola Tanam", "grid")
local PolaL    = PolaPage:Section("🎨 Pilih & Tanam", "Left")
local PolaR    = PolaPage:Section("⚙️ Ukuran", "Right")

PolaL:Dropdown("🎨 Pola", "PolaDD",
    {"⭕ Bulat","⬜ Kotak","🔺 Segitiga","❤️ Hati","➕ Plus","🌀 Spiral"},
    function(v) selectedPola = v end)

PolaL:Button("👁️ Preview Pola", "Lihat jumlah titik sebelum tanam",
    function()
        local root = getRoot(); if not root then return end
        local p    = root.Position
        local pts  = generatePola(selectedPola, p.X, p.Y, p.Z)
        previewPts = pts
        Library:Notification("👁️ Preview " .. selectedPola,
            string.format(
                "📐 Titik   : %d tanaman\n"..
                "📏 Ukuran  : %d studs\n"..
                "↔️ Spacing : %d studs\n\n"..
                "✅ Siap ditanam!\nTekan Tanam Pola",
                #pts, patternSize, patternSpacing), 8)
    end)

PolaL:Button("🌱 Tanam Pola Sekarang", "Generate + beli + tanam otomatis",
    function()
        task.spawn(function()
            local root = getRoot(); if not root then return end
            local crop = getCrop(selectedCrop)
            local p    = root.Position
            local pts  = generatePola(selectedPola, p.X, p.Y, p.Z)
            Library:Notification("🌱 Tanam Pola",
                selectedPola .. " — " .. #pts .. " titik\nBeli + tanam...", 3)
            beliBibit(crop.cropName, #pts)
            task.wait(1)
            local n = tanamPola(pts, crop.cropName)
            Library:Notification("✅ Pola Selesai!",
                string.format(
                    "🎨 Pola   : %s\n"..
                    "🌱 Tanam  : %d/%d\n"..
                    "🌿 Tanaman: %s",
                    selectedPola, n, #pts, crop.cropName), 6)
        end)
    end)

PolaL:Button("🌱 Tanam dari Preview", "Tanam dari hasil preview terakhir",
    function()
        if #previewPts == 0 then
            Library:Notification("❌", "Preview dulu!", 2); return
        end
        task.spawn(function()
            local crop = getCrop(selectedCrop)
            beliBibit(crop.cropName, #previewPts)
            task.wait(1)
            local n = tanamPola(previewPts, crop.cropName)
            Library:Notification("✅ Tanam",
                n .. "/" .. #previewPts .. " ditanam!", 4)
        end)
    end)

PolaL:Paragraph("ℹ️ Info Pola",
    "⭕ Bulat   = Lingkaran\n"..
    "⬜ Kotak   = Persegi\n"..
    "🔺 Segitiga = 3 sisi\n"..
    "❤️ Hati    = Love shape\n"..
    "➕ Plus    = Salib/Cross\n"..
    "🌀 Spiral  = Melingkar\n\n"..
    "📌 Berdiri di TENGAH\nlahan sebelum tanam!")

PolaR:Slider("📏 Ukuran (studs)", "PolaSz", 2, 50, 10,
    function(v) patternSize = v end, "Radius/ukuran pola")

PolaR:Slider("↔️ Spacing (studs)", "PolaSp", 1, 10, 2,
    function(v) patternSpacing = v end, "Jarak antar tanaman")

PolaR:Paragraph("💡 Tips",
    "1️⃣ Pilih pola\n2️⃣ Pilih tanaman\n"..
    "3️⃣ Atur ukuran\n4️⃣ Preview\n"..
    "5️⃣ Berdiri di tengah\n6️⃣ Tanam!\n\n"..
    "💰 Bibit dibeli\notomatis sesuai\njumlah titik")

-- ════════════════════════════════════════
--  BUILD UI — TAB LAHAN
-- ════════════════════════════════════════
local LahanPage = TabLahan:Page("📍 Kelola Lahan", "map-pin")
local LahanL    = LahanPage:Section("📍 TP & Lihat", "Left")
local LahanR    = LahanPage:Section("💾 Save Lahan", "Right")

LahanL:Button("📋 Lihat Semua Lahan", "Tampilkan daftar posisi lahan",
    function()
        local text = "📍 " .. #LAHAN .. " lahan tersimpan:\n\n"
        for i, pos in ipairs(LAHAN) do
            text = text .. string.format(
                "[%d] X=%.0f Y=%.0f Z=%.0f\n", i, pos.X, pos.Y, pos.Z)
        end
        Library:Notification("📍 Daftar Lahan", text, 15)
    end)

for i = 1, 5 do
    local idx = i
    LahanL:Button("📍 TP Lahan " .. idx, "Teleport ke lahan " .. idx,
        function() tpToLahan(idx) end)
end

LahanR:Paragraph("💾 Cara Save",
    "Berdiri di atas lahan\nlalu tekan Save\ndi bawah ini")

for i = 1, 10 do
    local idx = i
    LahanR:Button("💾 Save Lahan " .. idx, "Simpan posisi sebagai lahan " .. idx,
        function()
            local root = getRoot(); if not root then return end
            LAHAN[idx] = root.Position
            local p = root.Position
            Library:Notification("💾 Lahan " .. idx,
                string.format("X=%.0f Y=%.0f Z=%.0f", p.X, p.Y, p.Z), 3)
        end)
end

-- ════════════════════════════════════════
--  BUILD UI — TAB TELEPORT
-- ════════════════════════════════════════
local TPage = TabTP:Page("📍 Teleport", "map-pin")
local TL    = TPage:Section("👥 Ke Player", "Left")
local TR    = TPage:Section("💾 Slot Posisi", "Right")

TL:Button("👥 Lihat Player Online", "Tampilkan semua player di server",
    function()
        local list, n = "", 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                local r2 = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local mr = getRoot()
                local d  = (r2 and mr) and getDist(r2.Position, mr.Position) or "?"
                n    = n + 1
                list = list .. string.format("• %s — %sm\n", p.Name, tostring(d))
            end
        end
        Library:Notification("👥 " .. n .. " Player Online",
            n > 0 and list or "Tidak ada player lain", 10)
    end)

local tpInput = ""
TL:TextBox("🔍 Nama / Prefix", "TPInput", "",
    function(v) tpInput = v end, "Ketik 1-2 huruf pertama")
TL:Button("📍 Teleport ke Player", "TP ke player",
    function() tpToPlayer(tpInput) end)
TL:Button("🖱️ TP ke Mouse", "TP ke posisi tap layar",
    function() tpToMouse() end)
TL:Button("💀 Respawn Cepat", "Mati & spawn di posisi sama",
    function() quickRespawn() end)
TL:Paragraph("💡 Cara Pakai",
    "1️⃣ Lihat Player Online\n2️⃣ Ketik 1-2 huruf\n3️⃣ Tekan Teleport!")

TR:Label("💾 Save & Load Posisi")
for i = 1, 5 do
    local idx = i
    TR:Button("💾 Save Slot " .. idx, "Simpan posisi ke slot " .. idx,
        function()
            local root = getRoot(); if not root then return end
            slots[idx] = root.CFrame
            local p = root.Position
            Library:Notification("💾 Slot " .. idx,
                string.format("X=%.0f Y=%.0f Z=%.0f", p.X, p.Y, p.Z), 3)
        end)
    TR:Button("🚀 Load Slot " .. idx, "TP ke slot " .. idx,
        function()
            if not slots[idx] then
                Library:Notification("❌", "Slot " .. idx .. " kosong", 2); return
            end
            local root = getRoot()
            if root then root.CFrame = slots[idx] end
            local p = slots[idx].Position
            Library:Notification("📍 Slot " .. idx,
                string.format("X=%.0f Y=%.0f Z=%.0f", p.X, p.Y, p.Z), 3)
        end)
end

-- ════════════════════════════════════════
--  BUILD UI — TAB FLY
-- ════════════════════════════════════════
local FlyPage = TabFly:Page("🚀 Fly & NoClip", "rocket")
local FL      = FlyPage:Section("🚀 Fly", "Left")
local FR      = FlyPage:Section("🚶 NoClip & ESP", "Right")

FL:Toggle("🚀 Fly Mode", "FlyTog", false, "Terbang bebas",
    function(v)
        flyOn = v
        if v then startFly() else stopFly() end
        Library:Notification("🚀 Fly", v and "✅ ON" or "⛔ OFF", 2)
    end)
FL:Slider("⚡ Kecepatan Fly", "FlySp", 5, 300, 60,
    function(v) flySpeed = v end, "Default 60")
FL:Slider("📐 Sensitivitas", "PitchSl", 1, 9, 3,
    function(v) PITCH_UP = v*0.1; PITCH_DOWN = -v*0.1 end,
    "Naik/turun kamera (1=sensitif)")
FL:Paragraph("🎮 Kontrol Fly",
    "🕹️ Joystick = maju/mundur\n"..
    "📷 Kamera atas  = NAIK\n"..
    "📷 Kamera bawah = TURUN\n"..
    "✋ Lepas = melayang diam")

FR:Toggle("🚶 NoClip", "NoclipTog", false, "Tembus semua dinding",
    function(v)
        setNoclip(v)
        Library:Notification("🚶 NoClip", v and "✅ ON" or "⛔ OFF", 2)
    end)
FR:Toggle("👁️ ESP Player", "ESPTog", false, "Lihat player tembus dinding",
    function(v) toggleESP(v) end)
FR:Button("🔄 Refresh ESP", "Perbarui ESP semua player",
    function()
        if espOn then
            clearESP(); task.wait(0.2)
            for _, p in pairs(Players:GetPlayers()) do makeESP(p) end
            Library:Notification("👁️ ESP", "🔄 Refreshed", 2)
        end
    end)
FR:Paragraph("💡 Tips Fly+NoClip",
    "✅ Fly ON\n✅ NoClip ON\n\n"..
    "→ Masuk private room\n"..
    "→ Tembus semua tembok\n"..
    "→ Akses area terlarang")

-- ════════════════════════════════════════
--  BUILD UI — TAB SPEED
-- ════════════════════════════════════════
local SPage = TabSpd:Page("⚡ Speed & Jump", "zap")
local SL    = SPage:Section("🏃 Speed", "Left")
local SR    = SPage:Section("🦘 Jump", "Right")

SL:Slider("🏃 WalkSpeed", "WSSl", 1, 500, 16,
    function(v)
        curWS = v; local h = getHum()
        if h then h.WalkSpeed = v end
    end, "Default 16")
SL:Button("➕ Speed +10", "Tambah speed 10",
    function()
        curWS = math.min(curWS + 10, 500)
        local h = getHum(); if h then h.WalkSpeed = curWS end
        Library:Notification("🏃 Speed", "Speed: " .. curWS, 1)
    end)
SL:Button("➖ Speed -10", "Kurangi speed 10",
    function()
        curWS = math.max(curWS - 10, 1)
        local h = getHum(); if h then h.WalkSpeed = curWS end
        Library:Notification("🏃 Speed", "Speed: " .. curWS, 1)
    end)
SL:Button("🔁 Reset Speed", "Kembalikan ke 16",
    function()
        curWS = 16; local h = getHum()
        if h then h.WalkSpeed = 16 end
        Library:Notification("🏃 Speed", "Reset → 16", 2)
    end)

SR:Slider("🦘 JumpPower", "JPSl", 1, 500, 50,
    function(v)
        curJP = v; local h = getHum()
        if h then h.JumpPower = v; h.UseJumpPower = true end
    end, "Default 50")
SR:Button("➕ Jump +10", "Tambah jump 10",
    function()
        curJP = math.min(curJP + 10, 500)
        local h = getHum()
        if h then h.JumpPower = curJP; h.UseJumpPower = true end
        Library:Notification("🦘 Jump", "Jump: " .. curJP, 1)
    end)
SR:Button("➖ Jump -10", "Kurangi jump 10",
    function()
        curJP = math.max(curJP - 10, 1)
        local h = getHum()
        if h then h.JumpPower = curJP; h.UseJumpPower = true end
        Library:Notification("🦘 Jump", "Jump: " .. curJP, 1)
    end)
SR:Button("🔁 Reset Jump", "Kembalikan ke 50",
    function()
        curJP = 50; local h = getHum()
        if h then h.JumpPower = 50; h.UseJumpPower = true end
        Library:Notification("🦘 Jump", "Reset → 50", 2)
    end)
SR:Toggle("♾️ Infinite Jump", "InfJump", false, "Lompat terus di udara",
    function(v)
        if v then
            _G.xkid_ij = UIS.JumpRequest:Connect(function()
                local h = getHum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if _G.xkid_ij then _G.xkid_ij:Disconnect(); _G.xkid_ij = nil end
        end
        Library:Notification("♾️ Inf Jump", v and "✅ ON" or "⛔ OFF", 2)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB PROTECTION
-- ════════════════════════════════════════
local PPage = TabProt:Page("🛡️ Protection", "shield")
local PL    = PPage:Section("🛡️ Controls", "Left")
local PR    = PPage:Section("💀 Auto Respawn", "Right")

PL:Toggle("⏰ Anti AFK", "AfkTog", false, "Cegah disconnect otomatis",
    function(v)
        if v then startAntiAFK() else stopAntiAFK() end
        Library:Notification("⏰ Anti AFK", v and "✅ ON" or "⛔ OFF", 2)
    end)
PL:Toggle("🦺 Anti Kick", "KickTog", false, "Cegah dikeluarkan dari server",
    function(v)
        if v then startAntiKick() else stopAntiKick() end
        Library:Notification("🦺 Anti Kick", v and "✅ ON" or "⛔ OFF", 2)
    end)
PL:Button("🔄 Rejoin Server", "Koneksi ulang ke server",
    function()
        Library:Notification("🔄 Rejoin", "Connecting...", 3)
        task.wait(1); TpService:Teleport(game.PlaceId, LP)
    end)
PL:Button("📍 Posisi Saya", "Lihat koordinat sekarang",
    function()
        local root = getRoot()
        if root then
            local p = root.Position
            Library:Notification("📍 Posisi Saya",
                string.format("X = %.1f\nY = %.1f\nZ = %.1f", p.X, p.Y, p.Z), 6)
        end
    end)
PL:Paragraph("ℹ️ Info",
    "⏰ Anti AFK:\nCegah auto-disconnect\n\n"..
    "🦺 Anti Kick:\nJaga HP dari kick\n\n"..
    "🔄 Rejoin:\nKoneksi ulang cepat")

PR:Toggle("💀 Auto Respawn", "RespawnTog", false,
    "Otomatis kembali ke posisi terakhir saat mati",
    function(v)
        autoRespawnOn = v
        if v then setupAutoRespawn() end
        Library:Notification("💀 Auto Respawn",
            v and "✅ ON — " .. respawnMode or "⛔ OFF", 3)
    end)
PR:Dropdown("⚙️ Mode Respawn", "RespawnMode",
    {"🌿 Natural — Tunggu game", "⚡ Cepat — BreakJoints"},
    function(v)
        respawnMode     = v:find("Natural") and "Natural" or "Cepat"
        respawnWaitTime = respawnMode == "Natural" and 1.0 or 0.5
        if autoRespawnOn then setupAutoRespawn() end
        Library:Notification("⚙️ Mode", respawnMode, 2)
    end)
PR:Button("💀 Respawn Manual", "Mati & kembali ke posisi sekarang",
    function() quickRespawn() end)
PR:Paragraph("ℹ️ Info Respawn",
    "🌿 Natural:\nTunggu animasi mati\nLebih aman\n\n"..
    "⚡ Cepat:\nBreakJoints langsung\nLebih cepat\n\n"..
    "📍 Posisi disimpan\notomatis tiap detik")

-- ════════════════════════════════════════
--  BUILD UI — TAB TOKO
-- ════════════════════════════════════════
local TokoPage = TabToko:Page("🛒 Daftar Toko", "shopping-cart")
local TokoL    = TokoPage:Section("🛒 Beli Bibit", "Left")
local TokoR    = TokoPage:Section("⚙️ Qty Global", "Right")

-- Qty global
TokoR:Slider("📦 Qty Global", "QtyGlobal", 1, 50, 5,
    function(v) buyQty = v end, "Berlaku untuk semua item\nkecuali yang di-override")

local qtyTxtGlobal = ""
TokoR:TextBox("✏️ Ketik Qty Global", "QtyGlobalTxt", "",
    function(v)
        qtyTxtGlobal = v
        local num = tonumber(v)
        if num then
            buyQty = math.max(1, math.min(50, math.floor(num)))
            Library:Notification("📦 Qty Global", "= " .. buyQty, 1)
        end
    end, "Ketik angka 1-50")

TokoR:Paragraph("ℹ️ Cara Override",
    "Qty Global = default\nuntuk semua tanaman\n\n"..
    "Override per item:\nGanti qty di textbox\nmasing-masing item\n\n"..
    "Kosongkan override =\npakai Qty Global")

TokoR:Button("🏪 TP ke Toko", "Teleport ke NPC toko",
    function() tpToToko() end)

-- Per-item buy buttons
local itemOverrideTxt = {}

for _, crop in ipairs(CROPS) do
    local cn   = crop.cropName
    local cname= crop.name
    local seed = crop.seedName
    local price= crop.seedPrice

    -- Tombol beli + textbox override qty
    TokoL:Button(
        string.format("%s  [%d💰]  Beli", cname, price),
        "Beli " .. seed,
        function()
            local qty = itemQtyOverride[cn] or buyQty
            task.spawn(function()
                local ok = beliBibit(cn, qty)
                Library:Notification(
                    ok and "✅ Beli!" or "❌ Gagal",
                    string.format("%s x%d\n%d💰 total",
                        seed, qty, price * qty), 3)
            end)
        end)

    local overrideTxt = ""
    TokoL:TextBox(
        "  Override Qty " .. cname, "OvQty_"..cn, "",
        function(v)
            overrideTxt = v
            local num = tonumber(v)
            if num and num >= 1 then
                itemQtyOverride[cn] = math.min(50, math.floor(num))
            elseif v == "" then
                itemQtyOverride[cn] = nil
            end
        end, "Kosong = pakai Qty Global")
end

-- Beli semua sekaligus
TokoL:Button("🛒 Beli SEMUA Tanaman", "Beli semua jenis bibit sekaligus",
    function()
        task.spawn(function()
            Library:Notification("🛒", "Beli semua bibit...", 2)
            local total = 0
            for _, crop in ipairs(CROPS) do
                local qty = itemQtyOverride[crop.cropName] or buyQty
                local ok  = beliBibit(crop.cropName, qty)
                if ok then total = total + 1 end
                task.wait(0.3)
            end
            Library:Notification("✅ Beli Semua",
                total .. "/" .. #CROPS .. " berhasil!", 3)
        end)
    end)

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
task.spawn(function()
    task.wait(2)
    local ok, name = scanToko()
    if ok then
        Library:Notification("🏪 Toko Auto-Scan", "✅ " .. name .. " ditemukan!", 4)
    end
    -- Cek BN2
    if not dataRE then
        Library:Notification("⚠️ BridgeNet2",
            "Tidak ditemukan di game ini\nFitur farm tidak aktif", 5)
    end
end)

Library:Notification("🌟 XKID FULL v4.0",
    "✅ Mobile Ready!\n🌾 Farm + 🎨 Pola + 🛠️ Hub", 5)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════╗")
print("║   🌟  XKID FULL  v4.0  Mobile      ║")
print("║   Farm · Pola · TP · Fly · Protect  ║")
print("║   Player: " .. LP.Name)
print("╚══════════════════════════════════════╝")
