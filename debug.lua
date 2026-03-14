--[[
  ╔══════════════════════════════════════════════════════╗
  ║       🌟  X K I D . H U B  F U L L  v3.0  🌟      ║
  ║       Aurora UI  ✦  Mobile  ✦  BridgeNet2          ║
  ╚══════════════════════════════════════════════════════╝
  Tab Farm      : Auto Farm + Manual + Pola Tanam
  Tab Teleport  : infer_plr + Daftar Player
  Tab Fly       : BodyVelocity + NoClip
  Tab Speed     : WalkSpeed + JumpPower + InfJump
  Tab Protection: Anti AFK + Anti Kick + Respawn
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
--  BRIDGENET2 — Safe load, tidak crash
-- ════════════════════════════════════════
local dataRE = nil
pcall(function()
    local BN2 = RS:FindFirstChild("BridgeNet2")
    if BN2 then
        dataRE = BN2:FindFirstChild("dataRemoteEvent")
    end
end)

-- Identifier packet (confirmed dari spy)
local ID_BUY     = "\x05"
local ID_PLANT   = "\x06"
local ID_HARVEST = "\x09"

-- ════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════
local Win = Library:Window("🌟 XKID FULL", "star", "v3.0", false)

-- ════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════
Win:TabSection("FARM")
local TabFarm = Win:Tab("Farm",       "wheat")
local TabPola = Win:Tab("Pola",       "grid")

Win:TabSection("HUB")
local TabTP   = Win:Tab("Teleport",   "map-pin")
local TabFly  = Win:Tab("Fly",        "rocket")
local TabSpd  = Win:Tab("Speed",      "zap")
local TabProt = Win:Tab("Protection", "shield")

-- ════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════
local function getChar()
    return LP.Character
end
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
    { name="Sawi",   cropName="Sawi",      seedName="Bibit Sawi",   sellPrice=20,    seedPrice=15    },
    { name="Padi",   cropName="Padi",      seedName="Bibit Padi",   sellPrice=35,    seedPrice=20    },
    { name="Tomat",  cropName="Tomat",     seedName="Bibit Tomat",  sellPrice=65,    seedPrice=40    },
    { name="Melon",  cropName="Melon",     seedName="Bibit Melon",  sellPrice=130,   seedPrice=70    },
    { name="Kelapa", cropName="Coconut",   seedName="Bibit Kelapa", sellPrice=1150,  seedPrice=800   },
    { name="Apel",   cropName="AppleTree", seedName="Bibit Apel",   sellPrice=2667,  seedPrice=2000  },
    { name="Daisy",  cropName="Daisy",     seedName="Bibit Daisy",  sellPrice=18333, seedPrice=15000 },
}
local function getCrop(name)
    for _, c in ipairs(CROPS) do
        if c.name == name then return c end
    end
    return CROPS[1]
end

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local selectedCrop   = "Sawi"
local buyQty         = 5
local plantDelay     = 0.3
local farmOn         = false
local farmLoop       = nil
local totalHarvest   = 0
local totalCoins     = 0
local harvestConn    = nil
local autoPanenOn    = false
local autoPanenLoop  = nil
local tokoPos        = nil
local patternSize    = 10
local patternSpacing = 2
local selectedPola   = "Bulat"
local previewPts     = {}

-- HUB state
local curWS        = 16
local curJP        = 50
local flyOn        = false
local flySpeed     = 60
local flyBV        = nil
local flyBG        = nil
local flyConn      = nil
local noclipOn     = false
local noclipConn   = nil
local espOn        = false
local espBills     = {}
local espConns     = {}
local afkConn      = nil
local antiKickOn   = false
local slots        = {}
local PITCH_UP     =  0.3
local PITCH_DOWN   = -0.3
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
--  RE-APPLY STATS ON RESPAWN
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
--  FARM FUNCTIONS
-- ════════════════════════════════════════
local function beliBibit(cropName, qty)
    if not dataRE then return false end
    return pcall(function()
        dataRE:FireServer({
            { { cropName = cropName, count = qty } },
            ID_BUY,
        })
    end)
end

local function tpToLahan(idx)
    idx = idx or 1
    if idx > #LAHAN then idx = 1 end
    local root = getRoot()
    if not root then return end
    local pos = LAHAN[idx]
    root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    task.wait(0.3)
end

local function tpToToko()
    if not tokoPos then
        Library:Notification("Toko", "Scan toko dulu!", 2)
        return
    end
    local root = getRoot()
    if not root then return end
    root.CFrame = CFrame.new(tokoPos) * CFrame.new(0, 3, 0)
    task.wait(0.5)
end

local function tanamSatu(pos, cropName)
    if not dataRE then return false end
    -- Cari landPart terdekat
    local landPart = Workspace:FindFirstChild("Land")
    local minDist  = math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("land") or n:find("lahan") or n:find("plot") then
                local d = (v.Position - pos).Magnitude
                if d < minDist then
                    minDist  = d
                    landPart = v
                end
            end
        end
    end
    return pcall(function()
        dataRE:FireServer({
            {
                slotIdx     = 1,
                hitPosition = pos,
                hitPart     = landPart,
            },
            ID_PLANT,
        })
    end)
end

local function tanamSemua(cropName)
    local n = 0
    for _, pos in ipairs(LAHAN) do
        local ok = tanamSatu(pos, cropName)
        if ok then n = n + 1 end
        task.wait(plantDelay)
    end
    return n
end

local function harvestSemua(cropName)
    if not dataRE then return 0 end
    local n = 0
    for _, pos in ipairs(LAHAN) do
        local ok = pcall(function()
            dataRE:FireServer({
                { amount = 1, cropName = cropName },
                ID_HARVEST,
            })
        end)
        if ok then n = n + 1 end
        task.wait(0.1)
    end
    -- ProximityPrompt fallback
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local parent = v.Parent
            if parent then
                local pos = nil
                if parent:IsA("BasePart") then
                    pos = parent.Position
                elseif parent.PrimaryPart then
                    pos = parent.PrimaryPart.Position
                end
                if pos then
                    for _, lp2 in ipairs(LAHAN) do
                        if (pos - lp2).Magnitude < 15 then
                            pcall(function() fireproximityprompt(v) end)
                            task.wait(0.05)
                            break
                        end
                    end
                end
            end
        end
    end
    return n
end

local function startHarvestMonitor()
    if harvestConn then
        pcall(function() harvestConn:Disconnect() end)
    end
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

-- Auto Farm Loop
local function startAutoFarm()
    if not dataRE then
        Library:Notification("Farm", "BridgeNet2 tidak ada di game ini!", 4)
        return
    end
    startHarvestMonitor()
    farmLoop = task.spawn(function()
        while farmOn do
            local crop = getCrop(selectedCrop)

            -- 1. TP ke toko & beli
            Library:Notification("Farm", "Beli " .. crop.seedName, 2)
            tpToToko()
            beliBibit(crop.cropName, buyQty)
            task.wait(1)

            -- 2. TP ke lahan & tanam
            Library:Notification("Farm", "Menanam...", 2)
            tpToLahan(1)
            local planted = tanamSemua(crop.cropName)
            Library:Notification("Farm", planted .. " lahan ditanam", 2)

            -- 3. Tunggu & harvest tiap 5 detik (max 5 menit)
            local waited = 0
            while farmOn and waited < 300 do
                task.wait(5)
                waited = waited + 5
                local harvested = harvestSemua(crop.cropName)
                if harvested > 0 then
                    Library:Notification("Panen",
                        string.format("%d dipanen\nTotal: %d | Coins: %d",
                            harvested, totalHarvest, totalCoins), 3)
                end
            end
        end
        Library:Notification("Farm", "Dihentikan", 2)
    end)
end

local function stopAutoFarm()
    farmOn = false
    if farmLoop then
        pcall(function() task.cancel(farmLoop) end)
        farmLoop = nil
    end
    if harvestConn then
        pcall(function() harvestConn:Disconnect() end)
        harvestConn = nil
    end
end

-- Scan toko NPC
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
                        if hrp then
                            tokoPos = hrp.Position
                            return true, v.Name
                        end
                    else
                        tokoPos = v.Position
                        return true, v.Name
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
local function genBulat(cx, y, cz, r, sp)
    local pts   = {}
    local steps = math.max(8, math.floor(2 * math.pi * r / sp))
    for i = 0, steps - 1 do
        local t = (2 * math.pi * i) / steps
        table.insert(pts, Vector3.new(cx + r*math.cos(t), y, cz + r*math.sin(t)))
    end
    return pts
end

local function genKotak(cx, y, cz, sz, sp)
    local pts  = {}
    local half = sz / 2
    local s    = -half
    while s <= half do
        table.insert(pts, Vector3.new(cx+s,   y, cz-half))
        table.insert(pts, Vector3.new(cx+s,   y, cz+half))
        table.insert(pts, Vector3.new(cx-half, y, cz+s))
        table.insert(pts, Vector3.new(cx+half, y, cz+s))
        s = s + sp
    end
    return pts
end

local function genSegitiga(cx, y, cz, sz, sp)
    local pts = {}
    local h   = sz * math.sqrt(3) / 2
    local p1x, p1z = cx,         cz - h*2/3
    local p2x, p2z = cx - sz/2,  cz + h/3
    local p3x, p3z = cx + sz/2,  cz + h/3
    local function addSide(ax, az, bx, bz)
        local dist  = math.sqrt((bx-ax)^2 + (bz-az)^2)
        local steps = math.max(1, math.floor(dist / sp))
        for i = 0, steps do
            local t = i / steps
            table.insert(pts, Vector3.new(ax+(bx-ax)*t, y, az+(bz-az)*t))
        end
    end
    addSide(p1x,p1z, p2x,p2z)
    addSide(p2x,p2z, p3x,p3z)
    addSide(p3x,p3z, p1x,p1z)
    return pts
end

local function genHati(cx, y, cz, sz, sp)
    local pts   = {}
    local steps = math.max(30, math.floor(150 * sz / 10))
    local scale = sz / 16
    for i = 0, steps do
        local t  = (2 * math.pi * i) / steps
        local hx = 16 * math.sin(t)^3
        local hz = -(13*math.cos(t) - 5*math.cos(2*t) - 2*math.cos(3*t) - math.cos(4*t))
        table.insert(pts, Vector3.new(cx + hx*scale, y, cz + hz*scale))
    end
    return pts
end

local function genPlus(cx, y, cz, sz, sp)
    local pts = {}
    local s   = -sz
    while s <= sz do
        table.insert(pts, Vector3.new(cx+s, y, cz))
        if math.abs(s) > sp then
            table.insert(pts, Vector3.new(cx, y, cz+s))
        end
        s = s + sp
    end
    return pts
end

local function genSpiral(cx, y, cz, sz, sp)
    local pts = {}
    local t   = 0
    local dt  = 0.15
    while true do
        local r = sp * t / (2 * math.pi)
        if r > sz then break end
        table.insert(pts, Vector3.new(cx + r*math.cos(t), y, cz + r*math.sin(t)))
        t = t + dt
    end
    return pts
end

local function generatePola(name, cx, y, cz)
    if     name == "Bulat"    then return genBulat   (cx,y,cz, patternSize, patternSpacing)
    elseif name == "Kotak"    then return genKotak   (cx,y,cz, patternSize, patternSpacing)
    elseif name == "Segitiga" then return genSegitiga(cx,y,cz, patternSize, patternSpacing)
    elseif name == "Hati"     then return genHati    (cx,y,cz, patternSize, patternSpacing)
    elseif name == "Plus"     then return genPlus    (cx,y,cz, patternSize, patternSpacing)
    elseif name == "Spiral"   then return genSpiral  (cx,y,cz, patternSize, patternSpacing)
    end
    return {}
end

local function tanamPola(pts, cropName)
    if not dataRE then
        Library:Notification("Error", "BridgeNet2 tidak ada!", 3)
        return 0
    end
    local landPart = Workspace:FindFirstChild("Land")
    local n = 0
    for _, pos in ipairs(pts) do
        local ok = pcall(function()
            dataRE:FireServer({
                { slotIdx=1, hitPosition=pos, hitPart=landPart },
                ID_PLANT,
            })
        end)
        if ok then n = n + 1 end
        task.wait(plantDelay)
    end
    return n
end

-- ════════════════════════════════════════
--  FLY
-- ════════════════════════════════════════
local function startFly()
    local root = getRoot(); if not root then return end
    local hum  = getHum();  if not hum  then return end
    if flyBV   then pcall(function() flyBV:Destroy()      end) end
    if flyBG   then pcall(function() flyBG:Destroy()      end) end
    if flyConn then pcall(function() flyConn:Disconnect() end) end
    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Velocity = Vector3.new()
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 1e4; flyBG.D = 100
    flyBG.CFrame = root.CFrame
    hum.PlatformStand = true
    flyConn = RunService.Heartbeat:Connect(function()
        local r2 = getRoot(); if not r2 or not flyBV then return end
        local h2 = getHum();  if not h2 then return end
        local cam    = Workspace.CurrentCamera
        local cf     = cam.CFrame
        local camFwd = Vector3.new(cf.LookVector.X,  0, cf.LookVector.Z)
        local camRgt = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
        if camFwd.Magnitude > 0 then camFwd = camFwd.Unit end
        if camRgt.Magnitude > 0 then camRgt = camRgt.Unit end
        local md  = h2.MoveDirection
        local hor = Vector3.new()
        if md.Magnitude > 0.05 then
            hor = camFwd * md:Dot(camFwd) + camRgt * md:Dot(camRgt)
            if hor.Magnitude > 1 then hor = hor.Unit end
        end
        local py  = cf.LookVector.Y
        local ver = Vector3.new()
        if py > PITCH_UP then
            ver = Vector3.new(0, math.min((py-PITCH_UP)/(1-PITCH_UP), 1), 0)
        elseif py < PITCH_DOWN then
            ver = Vector3.new(0,-math.min((-py+PITCH_DOWN)/(1+PITCH_DOWN),1),0)
        end
        local dir = hor + ver
        if dir.Magnitude > 0 then
            flyBV.Velocity = (dir.Magnitude>1 and dir.Unit or dir) * flySpeed
            if hor.Magnitude > 0.05 then
                flyBG.CFrame = CFrame.new(Vector3.new(), hor)
            end
        else
            flyBV.Velocity = Vector3.new()
        end
        h2.PlatformStand = true
    end)
end

local function stopFly()
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn = nil end
    if flyBV   then pcall(function() flyBV:Destroy()      end); flyBV   = nil end
    if flyBG   then pcall(function() flyBG:Destroy()      end); flyBG   = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

-- ════════════════════════════════════════
--  NOCLIP
-- ════════════════════════════════════════
local function setNoclip(v)
    noclipOn = v
    if v then
        noclipConn = RunService.Stepped:Connect(function()
            local c = getChar(); if not c then return end
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local c = getChar()
        if c then
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

-- ════════════════════════════════════════
--  ESP
-- ════════════════════════════════════════
local function clearESP()
    for _, b in ipairs(espBills) do pcall(function() b:Destroy()    end) end
    for _, c in ipairs(espConns) do pcall(function() c:Disconnect() end) end
    espBills = {}; espConns = {}
end

local function makeESP(player)
    if player == LP then return end
    local function onChar(char)
        if not espOn then return end
        task.wait(0.5)
        local head = char:FindFirstChild("Head"); if not head then return end
        local bill = Instance.new("BillboardGui")
        bill.Size = UDim2.new(0,180,0,50); bill.StudsOffset = Vector3.new(0,3,0)
        bill.AlwaysOnTop = true; bill.Adornee = head; bill.Parent = char
        local bg = Instance.new("Frame", bill)
        bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
        bg.BackgroundTransparency = 0.45; bg.BorderSizePixel = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0,6)
        local lbl = Instance.new("TextLabel", bg)
        lbl.Size = UDim2.new(1,-6,1,-4); lbl.Position = UDim2.new(0,3,0,2)
        lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(255,230,80)
        lbl.TextStrokeTransparency = 0.3; lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold; lbl.TextXAlignment = Enum.TextXAlignment.Center
        local upd = RunService.Heartbeat:Connect(function()
            if not bill or not bill.Parent then return end
            local mr = getRoot()
            local d  = mr and getDist(head.Position, mr.Position) or 0
            lbl.Text = string.format("👤 %s\n📍 %dm", player.Name, d)
        end)
        table.insert(espConns, upd); table.insert(espBills, bill)
    end
    if player.Character then onChar(player.Character) end
    table.insert(espConns, player.CharacterAdded:Connect(onChar))
end

local function toggleESP(v)
    espOn = v; clearESP()
    if v then
        for _, p in pairs(Players:GetPlayers()) do makeESP(p) end
        table.insert(espConns, Players.PlayerAdded:Connect(makeESP))
    end
    Library:Notification("ESP", v and "ON" or "OFF", 2)
end

-- ════════════════════════════════════════
--  TELEPORT — infer_plr
-- ════════════════════════════════════════
local function infer_plr(ref)
    if typeof(ref) ~= "string" then return ref end
    local best, min = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local nv   = math.huge
            local un   = p.Name
            local dn   = p.DisplayName
            if     un:find("^"..ref)                   then nv = 1.0*(#un-#ref)
            elseif dn:find("^"..ref)                   then nv = 1.5*(#dn-#ref)
            elseif un:lower():find("^"..ref:lower())   then nv = 2.0*(#un-#ref)
            elseif dn:lower():find("^"..ref:lower())   then nv = 2.5*(#dn-#ref) end
            if nv < min then best = p; min = nv end
        end
    end
    return best
end

local function tpToPlayer(ref)
    if not ref or ref == "" then
        Library:Notification("TP", "Ketik nama dulu!", 2); return
    end
    local pl = infer_plr(ref)
    if not pl then Library:Notification("TP", "Tidak ditemukan", 2); return end
    if not pl.Character then Library:Notification("TP", pl.Name.." offline", 2); return end
    local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
             or pl.Character:FindFirstChild("Torso")
    if not hrp then return end
    local c = getChar()
    if c then c:PivotTo(hrp.CFrame * CFrame.new(0,3,0)) end
    Library:Notification("TP", "→ "..pl.Name, 2)
end

local function tpToMouse()
    local mouse = LP:GetMouse()
    if mouse and mouse.Hit then
        local root = getRoot()
        if root then
            root.CFrame = mouse.Hit * CFrame.new(0,3,0)
            Library:Notification("TP", "Ke posisi mouse", 2)
        end
    end
end

local function quickRespawn()
    local root = getRoot(); if not root then return end
    local savedCF = root.CFrame
    local sWS, sJP = curWS, curJP
    local c = getChar(); if c then c:BreakJoints() end
    local conn
    conn = LP.CharacterAdded:Connect(function(newChar)
        conn:Disconnect(); task.wait(0.8)
        local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
        local hum = newChar:WaitForChild("Humanoid", 5)
        if hrp then hrp.CFrame = savedCF end
        if hum then hum.WalkSpeed=sWS; hum.JumpPower=sJP; hum.UseJumpPower=true end
        Library:Notification("Respawn", "Kembali ke posisi semula", 2)
    end)
end

-- ════════════════════════════════════════
--  PROTECTION
-- ════════════════════════════════════════
local function startAntiAFK()
    if afkConn then return end
    afkConn = LP.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
local function stopAntiAFK()
    if afkConn then afkConn:Disconnect(); afkConn = nil end
end
local function startAntiKick()
    if antiKickOn then return end
    antiKickOn = true
    task.spawn(function()
        while antiKickOn do
            pcall(function()
                local hum = getHum()
                if hum and hum.Health > 0 and hum.Health < hum.MaxHealth*0.1 then
                    hum.Health = hum.MaxHealth
                end
            end)
            task.wait(0.5)
        end
    end)
end
local function stopAntiKick() antiKickOn = false end

local function setupAutoRespawn()
    if respawnConn then pcall(function() respawnConn:Disconnect() end); respawnConn = nil end
    if not autoRespawnOn then return end
    local function hookChar(char)
        local hum  = char:WaitForChild("Humanoid", 5)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not hum or not root then return end
        local posConn = RunService.Heartbeat:Connect(function()
            if root and root.Parent then lastPos = root.CFrame end
        end)
        hum.Died:Connect(function()
            posConn:Disconnect()
            local savedCF = lastPos; if not savedCF then return end
            if respawnMode == "Cepat" then
                task.wait(0.1); pcall(function() char:BreakJoints() end)
            end
            local conn2
            conn2 = LP.CharacterAdded:Connect(function(newChar)
                conn2:Disconnect(); task.wait(respawnWaitTime)
                local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
                local hm2 = newChar:WaitForChild("Humanoid", 5)
                if hrp then hrp.CFrame = savedCF end
                if hm2 then hm2.WalkSpeed=curWS; hm2.JumpPower=curJP; hm2.UseJumpPower=true end
                Library:Notification("Respawn", "Kembali! Mode:"..respawnMode, 3)
                task.wait(1); if autoRespawnOn then hookChar(newChar) end
            end)
        end)
    end
    if LP.Character then hookChar(LP.Character) end
    respawnConn = LP.CharacterAdded:Connect(function() end)
end

-- ════════════════════════════════════════
--  BUILD UI — TAB FARM
-- ════════════════════════════════════════
local FarmPage  = TabFarm:Page("Auto Farm", "wheat")
local FarmLeft  = FarmPage:Section("Auto Farm", "Left")
local FarmRight = FarmPage:Section("Manual", "Right")

local cropNames = {}
for _, c in ipairs(CROPS) do table.insert(cropNames, c.name) end

FarmLeft:Dropdown("Tanaman", "CropDD", cropNames,
    function(v) selectedCrop = v end)

FarmLeft:Slider("Beli Qty", "BuyQty", 1, 50, 5,
    function(v) buyQty = v end, "Jumlah bibit per siklus")

FarmLeft:Slider("Delay Tanam", "PlantDly", 1, 20, 3,
    function(v) plantDelay = v * 0.1 end, "Jeda tanam x0.1 detik")

FarmLeft:Toggle("AUTO FARM", "AutoFarmTog", false,
    "Otomatis beli-tanam-panen loop",
    function(v)
        farmOn = v
        if v then startAutoFarm()
        else stopAutoFarm() end
        Library:Notification("Farm", v and "ON" or "OFF", 2)
    end)

FarmLeft:Paragraph("Status",
    "Auto Farm loop:\n1. Beli bibit\n2. Tanam semua lahan\n3. Harvest tiap 5 detik\n4. Ulangi")

FarmRight:Button("Scan Toko", "Cari NPC toko bibit",
    function()
        task.spawn(function()
            local ok, name = scanToko()
            Library:Notification("Toko",
                ok and "Ditemukan: "..name or "Tidak ditemukan\nSave manual!", 4)
        end)
    end)

FarmRight:Button("Save Posisi Toko", "Simpan posisi kamu sebagai toko",
    function()
        local root = getRoot()
        if root then
            tokoPos = root.Position
            Library:Notification("Toko", "Saved!", 2)
        end
    end)

FarmRight:Button("TP ke Toko", "Teleport ke toko", function() tpToToko() end)

FarmRight:Button("Beli Bibit Sekarang", "FireServer beli bibit",
    function()
        local crop = getCrop(selectedCrop)
        task.spawn(function()
            beliBibit(crop.cropName, buyQty)
            Library:Notification("Beli", crop.seedName.." x"..buyQty, 3)
        end)
    end)

FarmRight:Button("TP ke Lahan 1", "Teleport ke lahan", function() tpToLahan(1) end)

FarmRight:Button("Tanam Sekarang", "Tanam ke semua lahan",
    function()
        task.spawn(function()
            local crop = getCrop(selectedCrop)
            local n = tanamSemua(crop.cropName)
            Library:Notification("Tanam", n.." lahan ditanam", 3)
        end)
    end)

FarmRight:Button("Panen Sekarang", "Harvest semua lahan",
    function()
        task.spawn(function()
            local crop = getCrop(selectedCrop)
            local n = harvestSemua(crop.cropName)
            Library:Notification("Panen", n.." request dikirim", 3)
        end)
    end)

FarmRight:Toggle("Auto Panen", "AutoPanenTog", false,
    "Harvest otomatis tiap 5 detik",
    function(v)
        autoPanenOn = v
        if v then
            autoPanenLoop = task.spawn(function()
                while autoPanenOn do
                    local crop = getCrop(selectedCrop)
                    harvestSemua(crop.cropName)
                    task.wait(5)
                end
            end)
        else
            if autoPanenLoop then
                pcall(function() task.cancel(autoPanenLoop) end)
                autoPanenLoop = nil
            end
        end
        Library:Notification("Auto Panen", v and "ON" or "OFF", 2)
    end)

FarmRight:Button("Statistik", "Lihat total panen & coins",
    function()
        Library:Notification("Statistik",
            string.format("Panen: %d\nCoins: %d\nTanaman: %s",
                totalHarvest, totalCoins, selectedCrop), 6)
    end)

-- Lahan page
local LahanPage  = TabFarm:Page("Kelola Lahan", "map-pin")
local LahanLeft  = LahanPage:Section("Daftar Lahan", "Left")
local LahanRight = LahanPage:Section("Save Lahan", "Right")

LahanLeft:Button("Lihat Semua Lahan", "Tampilkan daftar lahan",
    function()
        local text = #LAHAN.." lahan:\n\n"
        for i, pos in ipairs(LAHAN) do
            text = text..string.format("[%d] X=%.0f Y=%.0f Z=%.0f\n", i, pos.X, pos.Y, pos.Z)
        end
        Library:Notification("Lahan", text, 12)
    end)

for i = 1, 5 do
    local idx = i
    LahanLeft:Button("TP Lahan "..idx, "Teleport ke lahan "..idx,
        function() tpToLahan(idx) end)
end

LahanRight:Paragraph("Cara Save",
    "Berdiri di atas lahan\nlalu tekan Save di bawah")

for i = 1, 5 do
    local idx = i
    LahanRight:Button("Save Lahan "..idx, "Simpan posisi kamu sebagai lahan",
        function()
            local root = getRoot(); if not root then return end
            LAHAN[idx] = root.Position
            local p = root.Position
            Library:Notification("Lahan "..idx,
                string.format("X=%.0f Y=%.0f Z=%.0f", p.X, p.Y, p.Z), 3)
        end)
end

-- ════════════════════════════════════════
--  BUILD UI — TAB POLA
-- ════════════════════════════════════════
local PolaPage  = TabPola:Page("Pola Tanam", "grid")
local PolaLeft  = PolaPage:Section("Pilih Pola", "Left")
local PolaRight = PolaPage:Section("Setting", "Right")

PolaLeft:Dropdown("Pola", "PolaDD",
    {"Bulat","Kotak","Segitiga","Hati","Plus","Spiral"},
    function(v) selectedPola = v end)

PolaLeft:Paragraph("Info Pola",
    "Bulat   = Lingkaran\nKotak   = Persegi\nSegitiga = 3 sisi\n"..
    "Hati    = Love shape\nPlus    = Salib\nSpiral  = Melingkar\n\n"..
    "Berdiri di TENGAH\nlahan sebelum tanam!")

PolaLeft:Button("Preview", "Lihat jumlah titik pola",
    function()
        local root = getRoot(); if not root then return end
        local p    = root.Position
        local pts  = generatePola(selectedPola, p.X, p.Y, p.Z)
        previewPts = pts
        Library:Notification("Preview "..selectedPola,
            string.format("Titik: %d tanaman\nUkuran: %d studs\nSpacing: %d studs\n\nTekan Tanam Pola!",
                #pts, patternSize, patternSpacing), 6)
    end)

PolaLeft:Button("Tanam Pola Sekarang", "Generate koordinat + tanam",
    function()
        task.spawn(function()
            local root = getRoot(); if not root then return end
            local crop = getCrop(selectedCrop)
            local p    = root.Position
            local pts  = generatePola(selectedPola, p.X, p.Y, p.Z)
            Library:Notification("Tanam Pola",
                string.format("%s — %d titik\nBeli + tanam...", selectedPola, #pts), 3)
            beliBibit(crop.cropName, #pts)
            task.wait(1)
            local n = tanamPola(pts, crop.cropName)
            Library:Notification("Pola Selesai",
                string.format("%s\n%d/%d ditanam!", selectedPola, n, #pts), 5)
        end)
    end)

PolaLeft:Button("Tanam dari Preview", "Tanam dari preview terakhir",
    function()
        if #previewPts == 0 then
            Library:Notification("Error", "Preview dulu!", 2); return
        end
        task.spawn(function()
            local crop = getCrop(selectedCrop)
            beliBibit(crop.cropName, #previewPts)
            task.wait(1)
            local n = tanamPola(previewPts, crop.cropName)
            Library:Notification("Tanam", n.."/"..#previewPts.." ditanam!", 4)
        end)
    end)

PolaRight:Slider("Ukuran (studs)", "PolaSz", 2, 50, 10,
    function(v) patternSize = v end, "Radius/ukuran pola")

PolaRight:Slider("Spacing (studs)", "PolaSp", 1, 10, 2,
    function(v) patternSpacing = v end, "Jarak antar tanaman")

PolaRight:Paragraph("Tips",
    "1. Pilih pola & tanaman\n2. Atur ukuran & spacing\n3. Berdiri di TENGAH\n"..
    "4. Preview dulu\n5. Tanam!\n\nBibit dibeli otomatis")

-- ════════════════════════════════════════
--  BUILD UI — TAB TELEPORT
-- ════════════════════════════════════════
local TPage  = TabTP:Page("Teleport", "map-pin")
local TLeft  = TPage:Section("Ke Player", "Left")
local TRight = TPage:Section("Slot Posisi", "Right")

TLeft:Button("Lihat Player Online", "Tampilkan semua player",
    function()
        local list, n = "", 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                local r2 = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local mr = getRoot()
                local d  = (r2 and mr) and getDist(r2.Position, mr.Position) or "?"
                n    = n + 1
                list = list..string.format("• %s — %sm\n", p.Name, tostring(d))
            end
        end
        Library:Notification(n.." Player Online", n>0 and list or "Tidak ada", 10)
    end)

local tpInput = ""
TLeft:TextBox("Nama / Prefix", "TPInput", "",
    function(v) tpInput = v end, "Ketik 1-2 huruf pertama")
TLeft:Button("Teleport ke Player", "TP ke player",
    function() tpToPlayer(tpInput) end)
TLeft:Button("TP ke Mouse", "TP ke posisi tap",
    function() tpToMouse() end)
TLeft:Button("Respawn Cepat", "Mati & spawn di posisi sama",
    function() quickRespawn() end)

TRight:Label("Save & Load Posisi")
for i = 1, 5 do
    local idx = i
    TRight:Button("Save Slot "..idx, "Simpan posisi",
        function()
            local root = getRoot(); if not root then return end
            slots[idx] = root.CFrame
            local p    = root.Position
            Library:Notification("Slot "..idx,
                string.format("X=%.0f Y=%.0f Z=%.0f", p.X, p.Y, p.Z), 3)
        end)
    TRight:Button("Load Slot "..idx, "TP ke slot",
        function()
            if not slots[idx] then
                Library:Notification("Error", "Slot kosong", 2); return
            end
            local root = getRoot()
            if root then root.CFrame = slots[idx] end
        end)
end

-- ════════════════════════════════════════
--  BUILD UI — TAB FLY
-- ════════════════════════════════════════
local FlyPage = TabFly:Page("Fly & NoClip", "rocket")
local FL      = FlyPage:Section("Fly", "Left")
local FR      = FlyPage:Section("NoClip & ESP", "Right")

FL:Toggle("Fly Mode", "FlyTog", false, "Terbang bebas",
    function(v)
        flyOn = v
        if v then startFly() else stopFly() end
        Library:Notification("Fly", v and "ON" or "OFF", 2)
    end)
FL:Slider("Kecepatan", "FlySpd", 5, 300, 60,
    function(v) flySpeed = v end, "Default 60")
FL:Slider("Sensitivitas", "PitchSld", 1, 9, 3,
    function(v) PITCH_UP=v*0.1; PITCH_DOWN=-v*0.1 end, "Naik/turun kamera")
FL:Paragraph("Kontrol",
    "Joystick = maju/mundur\nKamera atas = NAIK\nKamera bawah = TURUN\nLepas = melayang")

FR:Toggle("NoClip", "NoclipTog", false, "Tembus dinding",
    function(v) setNoclip(v); Library:Notification("NoClip", v and "ON" or "OFF", 2) end)
FR:Toggle("ESP Player", "ESPTog", false, "Lihat player tembus dinding",
    function(v) toggleESP(v) end)
FR:Button("Refresh ESP", "Perbarui ESP",
    function()
        if espOn then
            clearESP(); task.wait(0.2)
            for _, p in pairs(Players:GetPlayers()) do makeESP(p) end
            Library:Notification("ESP", "Refreshed", 2)
        end
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB SPEED
-- ════════════════════════════════════════
local SPage = TabSpd:Page("Speed & Jump", "zap")
local SL    = SPage:Section("Speed", "Left")
local SR    = SPage:Section("Jump", "Right")

SL:Slider("WalkSpeed", "WSSld", 1, 500, 16,
    function(v) curWS=v; local h=getHum(); if h then h.WalkSpeed=v end end,
    "Default 16")
SL:Button("Reset Speed", "Kembalikan ke 16",
    function()
        curWS = 16; local h = getHum()
        if h then h.WalkSpeed = 16 end
        Library:Notification("Speed", "Reset 16", 2)
    end)

SR:Slider("JumpPower", "JPSld", 1, 500, 50,
    function(v)
        curJP=v; local h=getHum()
        if h then h.JumpPower=v; h.UseJumpPower=true end
    end, "Default 50")
SR:Button("Reset Jump", "Kembalikan ke 50",
    function()
        curJP=50; local h=getHum()
        if h then h.JumpPower=50; h.UseJumpPower=true end
        Library:Notification("Jump", "Reset 50", 2)
    end)
SR:Toggle("Infinite Jump", "InfJump", false, "Lompat terus di udara",
    function(v)
        if v then
            _G.xkid_ij = UIS.JumpRequest:Connect(function()
                local h = getHum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if _G.xkid_ij then _G.xkid_ij:Disconnect(); _G.xkid_ij = nil end
        end
        Library:Notification("Inf Jump", v and "ON" or "OFF", 2)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB PROTECTION
-- ════════════════════════════════════════
local PPage = TabProt:Page("Protection", "shield")
local PL    = PPage:Section("Controls", "Left")
local PR    = PPage:Section("Auto Respawn", "Right")

PL:Toggle("Anti AFK", "AfkTog", false, "Cegah disconnect",
    function(v)
        if v then startAntiAFK() else stopAntiAFK() end
        Library:Notification("Anti AFK", v and "ON" or "OFF", 2)
    end)
PL:Toggle("Anti Kick", "KickTog", false, "Cegah dikeluarkan",
    function(v)
        if v then startAntiKick() else stopAntiKick() end
        Library:Notification("Anti Kick", v and "ON" or "OFF", 2)
    end)
PL:Button("Rejoin", "Koneksi ulang",
    function()
        Library:Notification("Rejoin", "Connecting...", 3)
        task.wait(1); TpService:Teleport(game.PlaceId, LP)
    end)
PL:Button("Posisi Saya", "Lihat koordinat",
    function()
        local root = getRoot()
        if root then
            local p = root.Position
            Library:Notification("Posisi",
                string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 6)
        end
    end)

PR:Toggle("Auto Respawn", "RespawnTog", false, "Kembali ke posisi terakhir saat mati",
    function(v)
        autoRespawnOn = v
        if v then setupAutoRespawn() end
        Library:Notification("Auto Respawn", v and "ON — "..respawnMode or "OFF", 3)
    end)
PR:Dropdown("Mode Respawn", "RespawnMode",
    {"Natural — Tunggu game", "Cepat — BreakJoints"},
    function(v)
        respawnMode     = v:find("Natural") and "Natural" or "Cepat"
        respawnWaitTime = respawnMode == "Natural" and 1.0 or 0.5
        if autoRespawnOn then setupAutoRespawn() end
    end)
PR:Button("Respawn Manual", "Mati & kembali ke posisi sekarang",
    function() quickRespawn() end)
PR:Paragraph("Info",
    "Natural = Tunggu animasi\nCepat   = BreakJoints\n\nPosisi disimpan\notomatis tiap detik")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
-- Auto scan toko
task.spawn(function()
    task.wait(2)
    local ok, name = scanToko()
    if ok then
        Library:Notification("Toko Auto-Scan", "Toko: "..name, 4)
    end
end)

Library:Notification("XKID FULL v3.0", "Siap! Farm+Pola+Hub", 4)
Library:ConfigSystem(Win)

print("[ XKID FULL v3.0 ] " .. LP.Name)
