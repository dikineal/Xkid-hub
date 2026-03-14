--[[
  ╔══════════════════════════════════════════════════════╗
  ║       🌟  X K I D . H U B  F U L L  v1.0  🌟      ║
  ║       Aurora UI  ✦  Mobile  ✦  BridgeNet2          ║
  ╚══════════════════════════════════════════════════════╝
  Tab Farm      : Auto Farm + Manual Farm + Scan Lahan/Toko
  Tab Teleport  : infer_plr + Daftar Player
  Tab Fly       : BodyVelocity + NoClip
  Tab Speed     : WalkSpeed + JumpPower + InfJump
  Tab Protection: Anti AFK + Anti Kick + Rejoin + ESP
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
--  REMOTE BRIDGENET2
-- ════════════════════════════════════════
local BN2    = RS:WaitForChild("BridgeNet2", 5)
local dataRE = BN2 and BN2:WaitForChild("dataRemoteEvent", 5)

-- Identifier packet (dari hasil spy)
local ID_BUY   = "\x05"
local ID_PLANT = "\x06"

-- ════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════
local Win = Library:Window("🌟 XKID FULL", "star", "v1.0 Farm+Hub", false)

-- ════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════
Win:TabSection("🌾 FARM")
local TabFarm = Win:Tab("Farm",       "wheat")

Win:TabSection("🛠 HUB")
local TabTP   = Win:Tab("Teleport",   "map-pin")
local TabFly  = Win:Tab("Fly",        "rocket")
local TabSpd  = Win:Tab("Speed",      "zap")
local TabProt = Win:Tab("Protection", "shield")

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
    { name="Sawi",  cropName="Sawi",     seedName="Bibit Sawi",   sellPrice=20,    seedPrice=15    },
    { name="Padi",  cropName="Padi",     seedName="Bibit Padi",   sellPrice=35,    seedPrice=20    },
    { name="Tomat", cropName="Tomat",    seedName="Bibit Tomat",  sellPrice=65,    seedPrice=40    },
    { name="Melon", cropName="Melon",    seedName="Bibit Melon",  sellPrice=130,   seedPrice=70    },
    { name="Kelapa",cropName="Coconut",  seedName="Bibit Kelapa", sellPrice=1150,  seedPrice=800   },
    { name="Apel",  cropName="AppleTree",seedName="Bibit Apel",   sellPrice=2667,  seedPrice=2000  },
    { name="Daisy", cropName="Daisy",    seedName="Bibit Daisy",  sellPrice=18333, seedPrice=15000 },
}

local function getCrop(name)
    for _, c in ipairs(CROPS) do
        if c.name == name then return c end
    end
    return CROPS[1]
end

-- ════════════════════════════════════════
--  STATE — FARM
-- ════════════════════════════════════════
local farmOn        = false
local farmLoop      = nil
local selectedCrop  = "Sawi"
local buyQty        = 5
local plantDelay    = 0.5   -- detik antar tanam
local farmStatus    = "Idle"
local totalHarvest  = 0
local totalCoins    = 0
local harvestConn   = nil

-- Posisi lahan (dari spy + bisa tambah manual)
local LAHAN = {
    Vector3.new(517.92, 22.07, -58.40),
    Vector3.new(564.19, 22.83, -67.26),
    Vector3.new(582.31, 23.65, -171.46),
    Vector3.new(617.29, 41.72, -105.20),
    Vector3.new(619.11, 41.72, -105.57),
}

-- Posisi toko (di-scan atau di-save manual)
local tokoPos = nil
local tokoNPC = nil

-- ════════════════════════════════════════
--  STATE — HUB
-- ════════════════════════════════════════
local curWS      = 16
local curJP      = 50
local flyOn      = false
local flySpeed   = 60
local flyBV, flyBG, flyConn
local noclipOn   = false
local noclipConn = nil
local espOn      = false
local espBills   = {}
local espConns   = {}
local afkConn    = nil
local antiKickOn = false
local slots      = {}
local PITCH_UP   =  0.3
local PITCH_DOWN = -0.3

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
            flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
            flyBG = Instance.new("BodyGyro", r2)
            flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
            flyBG.P = 1e4; flyBG.D = 100
            flyBG.CFrame = r2.CFrame
            hum.PlatformStand = true
        end
    end
end)

-- ════════════════════════════════════════
--  ① SCAN TOKO NPC
-- ════════════════════════════════════════
local TOKO_KEYWORDS = {
    "toko","shop","bibit","seed","store","merchant",
    "vendor","seller","jual","dagang","market"
}

local function scanTokoNPC()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") then
            local n = v.Name:lower()
            for _, kw in ipairs(TOKO_KEYWORDS) do
                if n:find(kw) then
                    local hrp = v:FindFirstChild("HumanoidRootPart")
                              or v:FindFirstChildOfClass("Part")
                              or v.PrimaryPart
                    if hrp then
                        tokoNPC = v
                        tokoPos = hrp.Position
                        return true, v.Name, hrp.Position
                    end
                end
            end
        end
        -- Cek Part/BasePart juga
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            for _, kw in ipairs(TOKO_KEYWORDS) do
                if n:find(kw) then
                    tokoPos = v.Position
                    return true, v.Name, v.Position
                end
            end
        end
    end
    return false, nil, nil
end

-- ════════════════════════════════════════
--  ② FARM — CORE FUNCTIONS
-- ════════════════════════════════════════

-- Teleport ke toko
local function tpToToko()
    if not tokoPos then
        Library:Notification("❌","Scan toko dulu!",2); return false
    end
    local root = getRoot(); if not root then return false end
    root.CFrame = CFrame.new(tokoPos) * CFrame.new(0,3,0)
    task.wait(0.5)
    return true
end

-- Beli bibit via FireServer BridgeNet2
-- Format benar dari Cobalt spy
local function beliBibit(cropName, qty)
    if not dataRE then
        Library:Notification("❌","dataRemoteEvent tidak ada",3); return false
    end
    local ok, err = pcall(function()
        dataRE:FireServer({
            {   -- wrapper table (dari Cobalt)
                {
                    cropName = cropName,
                    count    = qty,
                }
            },
            ID_BUY,
        })
    end)
    if not ok then
        Library:Notification("❌ Beli Error", tostring(err), 3)
        return false
    end
    return true
end

-- Teleport ke lahan
local function tpToLahan(idx)
    if #LAHAN == 0 then
        Library:Notification("❌","Tidak ada data lahan",2); return false
    end
    idx = idx or 1
    if idx > #LAHAN then idx = 1 end
    local root = getRoot(); if not root then return false end
    local pos  = LAHAN[idx]
    root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    task.wait(0.3)
    return true
end

-- Tanam ke semua lahan
-- Format benar dari Cobalt spy
local function tanamSemua(cropName)
    if not dataRE then
        Library:Notification("❌","dataRemoteEvent tidak ada",3); return 0
    end

    local success = 0
    for _, pos in ipairs(LAHAN) do
        -- Cari BasePart Land terdekat dari posisi lahan
        local landPart = nil
        local minDist  = math.huge
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n = v.Name:lower()
                if n:find("land") or n:find("lahan")
                or n:find("plot") or n:find("farm") then
                    local d = (v.Position - pos).Magnitude
                    if d < minDist then
                        minDist  = d
                        landPart = v
                    end
                end
            end
        end
        if not landPart then
            landPart = Workspace:FindFirstChild("Land")
        end

        local ok = pcall(function()
            dataRE:FireServer({
                {   -- wrapper table (dari Cobalt)
                    slotIdx     = 1,
                    hitPosition = pos,
                    hitPart     = landPart,
                },
                ID_PLANT,
            })
        end)

        if ok then success = success + 1 end
        task.wait(plantDelay)
    end
    return success
end

-- ════════════════════════════════════════
--  AUTO PANEN — ProximityPrompt
-- ════════════════════════════════════════
local autoPanenOn   = false
local autoPanenLoop = nil
local PANEN_INTERVAL = 5  -- detik

-- Keyword nama tanaman untuk filter ProximityPrompt
local CROP_KEYWORDS = {
    "sawi","padi","tomat","melon","coconut","appletree",
    "daisy","fanpalm","sunflower","sawit","crop","plant",
    "tanaman","harvest","panen","bibit","seed","flower",
    "bunga","buah","sayur","pohon","tree","kebun"
}

local function isTanamanPart(part)
    if not part then return false end
    local n = part.Name:lower()
    for _, kw in ipairs(CROP_KEYWORDS) do
        if n:find(kw) then return true end
    end
    -- Cek parent juga
    if part.Parent then
        local pn = part.Parent.Name:lower()
        for _, kw in ipairs(CROP_KEYWORDS) do
            if pn:find(kw) then return true end
        end
    end
    return false
end

local function triggerPrompt(prompt)
    -- Coba fireproximityprompt dulu (executor function)
    local ok1 = pcall(function()
        fireproximityprompt(prompt)
    end)
    if ok1 then return true end

    -- Fallback: TriggerEnded
    local ok2 = pcall(function()
        prompt:TriggerEnded(LP)
    end)
    if ok2 then return true end

    -- Fallback 2: fireclickdetector pada parent
    local ok3 = pcall(function()
        local cd = prompt.Parent:FindFirstChildOfClass("ClickDetector")
        if cd then fireclickdetector(cd) end
    end)
    return ok3
end

local function scanDanPanen()
    local count = 0
    local myRoot = getRoot()

    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local parent = v.Parent
            if not parent then continue end

            -- Filter: hanya trigger prompt di dekat lahan kita
            local pos = parent:IsA("BasePart") and parent.Position
                     or (parent.PrimaryPart and parent.PrimaryPart.Position)
                     or nil

            local dekatLahan = false
            if pos then
                -- Cek apakah dekat salah satu lahan (radius 15 studs)
                for _, lahanPos in ipairs(LAHAN) do
                    if (pos - lahanPos).Magnitude < 15 then
                        dekatLahan = true
                        break
                    end
                end
                -- Kalau tidak ada data lahan, trigger semua yang ada tanaman
                if #LAHAN == 0 then
                    dekatLahan = isTanamanPart(parent)
                end
            end

            if dekatLahan or isTanamanPart(parent) then
                local ok = triggerPrompt(v)
                if ok then
                    count = count + 1
                    task.wait(0.1)  -- jeda kecil antar trigger
                end
            end
        end
    end
    return count
end

local function startAutoPanen()
    if autoPanenLoop then
        pcall(function() task.cancel(autoPanenLoop) end)
    end
    autoPanenLoop = task.spawn(function()
        while autoPanenOn do
            local n = scanDanPanen()
            if n > 0 then
                Library:Notification("🌾 Auto Panen",
                    string.format("%d tanaman dipanen!\nTotal: %d | Coins: %d",
                        n, totalHarvest, totalCoins), 3)
            end
            task.wait(PANEN_INTERVAL)
        end
    end)
end

local function stopAutoPanen()
    autoPanenOn = false
    if autoPanenLoop then
        pcall(function() task.cancel(autoPanenLoop) end)
        autoPanenLoop = nil
    end
end

-- Monitor harvest dari server
local function startHarvestMonitor()
    if harvestConn then
        pcall(function() harvestConn:Disconnect() end)
    end
    if not dataRE then return end

    harvestConn = dataRE.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        -- Cek identifier harvest \x0F
        for k, v in pairs(data) do
            if type(k) == "string" and k == "\x0F" then
                if type(v) == "table" then
                    for _, entry in ipairs(v) do
                        if type(entry) == "table" and entry.cropName then
                            totalHarvest = totalHarvest + 1
                            local price  = entry.sellPrice or 0
                            totalCoins   = totalCoins + price
                            Library:Notification(
                                "🌾 Panen!",
                                string.format("%s +%d coins\nTotal: %d panen | %d coins",
                                    entry.cropName, price, totalHarvest, totalCoins), 3)
                        end
                    end
                end
            end
            -- Update coins \x04
            if type(k) == "string" and k == "\x04" then
                if type(v) == "table" and v[1] then
                    totalCoins = v[1]
                end
            end
        end
    end)
end

local function stopHarvestMonitor()
    if harvestConn then
        pcall(function() harvestConn:Disconnect() end)
        harvestConn = nil
    end
end

-- ════════════════════════════════════════
--  ③ AUTO FARM LOOP
-- ════════════════════════════════════════
local function setFarmStatus(s)
    farmStatus = s
    Library:Notification("🌾 Farm", s, 2)
end

local function startAutoFarm()
    if not dataRE then
        Library:Notification("❌","BridgeNet2 tidak tersedia!",4); return
    end

    startHarvestMonitor()
    farmLoop = task.spawn(function()
        while farmOn do
            local crop = getCrop(selectedCrop)

            -- 1. TP ke toko
            setFarmStatus("📍 TP ke Toko...")
            if tokoPos then
                tpToToko()
                task.wait(1)
            end

            -- 2. Beli bibit
            setFarmStatus("🛒 Beli " .. crop.seedName .. " x" .. buyQty)
            beliBibit(crop.cropName, buyQty)
            task.wait(1)

            -- 3. TP ke lahan pertama
            setFarmStatus("📍 TP ke Lahan...")
            tpToLahan(1)
            task.wait(0.5)

            -- 4. Tanam ke semua lahan
            setFarmStatus("🌱 Menanam " .. crop.cropName .. "...")
            local n = tanamSemua(crop.cropName)
            Library:Notification("🌱 Tanam",
                string.format("%d lahan ditanam\nMenunggu panen...", n), 3)

            -- 5. Tunggu & auto panen via ProximityPrompt
            setFarmStatus("⏳ Menunggu & Memanen...")
            local waited = 0
            while farmOn and waited < 300 do
                -- Scan ProximityPrompt tiap 5 detik
                local n = scanDanPanen()
                if n > 0 then
                    Library:Notification("🌾 Auto Panen",
                        string.format("%d tanaman dipanen!\nTotal: %d",
                            n, totalHarvest), 3)
                end
                task.wait(5)
                waited = waited + 5
            end

            if not farmOn then break end

            -- 6. Ulangi
            setFarmStatus("🔄 Loop berikutnya...")
            task.wait(1)
        end
        setFarmStatus("⛔ Farm dihentikan")
    end)
end

local function stopAutoFarm()
    farmOn = false
    if farmLoop then
        pcall(function() task.cancel(farmLoop) end)
        farmLoop = nil
    end
    stopHarvestMonitor()
    setFarmStatus("⛔ Dihentikan")
end

-- ════════════════════════════════════════
--  ④ FLY
-- ════════════════════════════════════════
local function startFly()
    local root = getRoot(); if not root then return end
    local hum  = getHum();  if not hum  then return end
    if flyBV   then pcall(function() flyBV:Destroy() end) end
    if flyBG   then pcall(function() flyBG:Destroy() end) end
    if flyConn then pcall(function() flyConn:Disconnect() end) end
    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Velocity = Vector3.new()
    flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyBG.P = 1e4; flyBG.D = 100
    flyBG.CFrame = root.CFrame
    hum.PlatformStand = true
    flyConn = RunService.Heartbeat:Connect(function()
        local r2 = getRoot(); if not r2 or not flyBV then return end
        local h2 = getHum();  if not h2 then return end
        local cam = Workspace.CurrentCamera
        local cf  = cam.CFrame
        local camFwd = Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
        local camRgt = Vector3.new(cf.RightVector.X,0,cf.RightVector.Z)
        if camFwd.Magnitude>0 then camFwd=camFwd.Unit end
        if camRgt.Magnitude>0 then camRgt=camRgt.Unit end
        local md = h2.MoveDirection
        local horizontal = Vector3.new()
        if md.Magnitude > 0.05 then
            horizontal = camFwd*md:Dot(camFwd) + camRgt*md:Dot(camRgt)
            if horizontal.Magnitude>1 then horizontal=horizontal.Unit end
        end
        local pitchY = cf.LookVector.Y
        local vertical = Vector3.new()
        if pitchY > PITCH_UP then
            vertical = Vector3.new(0, math.min((pitchY-PITCH_UP)/(1-PITCH_UP),1), 0)
        elseif pitchY < PITCH_DOWN then
            vertical = Vector3.new(0,-math.min((-pitchY+PITCH_DOWN)/(1+PITCH_DOWN),1),0)
        end
        local dir = horizontal + vertical
        if dir.Magnitude>0 then
            flyBV.Velocity = (dir.Magnitude>1 and dir.Unit or dir)*flySpeed
            if horizontal.Magnitude>0.05 then
                flyBG.CFrame = CFrame.new(Vector3.new(), horizontal)
            end
        else
            flyBV.Velocity = Vector3.new()
        end
        h2.PlatformStand = true
    end)
end

local function stopFly()
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn=nil end
    if flyBV   then pcall(function() flyBV:Destroy()      end); flyBV=nil  end
    if flyBG   then pcall(function() flyBG:Destroy()      end); flyBG=nil  end
    local hum = getHum()
    if hum then hum.PlatformStand=false end
end

-- ════════════════════════════════════════
--  ⑤ NOCLIP
-- ════════════════════════════════════════
local function setNoclip(state)
    noclipOn = state
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local c = getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        local c = getChar()
        if c then
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=true end
            end
        end
    end
end

-- ════════════════════════════════════════
--  ⑥ ESP
-- ════════════════════════════════════════
local function clearESP()
    for _,b in ipairs(espBills) do pcall(function() b:Destroy()    end) end
    for _,c in ipairs(espConns) do pcall(function() c:Disconnect() end) end
    espBills={}; espConns={}
end

local function getArea(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return "?" end
    local pos = root.Position
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("room") or n:find("area") or n:find("zone")
            or n:find("vip")  or n:find("priv") or n:find("salon") then
                if (v.Position-pos).Magnitude < 25 then return v.Name end
            end
        end
    end
    return "Area"
end

local function makeESP(player)
    if player==LP then return end
    local function onChar(char)
        if not espOn then return end
        task.wait(0.5)
        local head = char:FindFirstChild("Head"); if not head then return end
        local bill = Instance.new("BillboardGui")
        bill.Size=UDim2.new(0,180,0,50); bill.StudsOffset=Vector3.new(0,3,0)
        bill.AlwaysOnTop=true; bill.Adornee=head; bill.Parent=char
        local bg=Instance.new("Frame",bill)
        bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(0,0,0)
        bg.BackgroundTransparency=0.45; bg.BorderSizePixel=0
        Instance.new("UICorner",bg).CornerRadius=UDim.new(0,6)
        local lbl=Instance.new("TextLabel",bg)
        lbl.Size=UDim2.new(1,-6,1,-4); lbl.Position=UDim2.new(0,3,0,2)
        lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.fromRGB(255,230,80)
        lbl.TextStrokeTransparency=0.3; lbl.TextScaled=true
        lbl.Font=Enum.Font.GothamBold; lbl.TextXAlignment=Enum.TextXAlignment.Center
        local upd=RunService.Heartbeat:Connect(function()
            if not bill or not bill.Parent then return end
            local mr=getRoot()
            local d=mr and getDist(head.Position,mr.Position) or 0
            lbl.Text=string.format("👤 %s\n📍 %dm | %s",player.Name,d,getArea(char))
        end)
        table.insert(espConns,upd); table.insert(espBills,bill)
    end
    if player.Character then onChar(player.Character) end
    table.insert(espConns,player.CharacterAdded:Connect(onChar))
end

local function toggleESP(state)
    espOn=state; clearESP()
    if state then
        for _,p in pairs(Players:GetPlayers()) do makeESP(p) end
        table.insert(espConns,Players.PlayerAdded:Connect(makeESP))
    end
    Library:Notification("👁 ESP",state and "ON" or "OFF",2)
end

-- ════════════════════════════════════════
--  ⑦ TELEPORT — infer_plr
-- ════════════════════════════════════════
local function infer_plr(ref)
    if typeof(ref)~="string" then return ref end
    local to_pl, min = nil, math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP then
            local nv=math.huge
            local un,dn=p.Name,p.DisplayName
            if     un:find("^"..ref)            then nv=1.0*(#un-#ref)
            elseif dn:find("^"..ref)            then nv=1.5*(#dn-#ref)
            elseif un:lower():find("^"..ref:lower()) then nv=2.0*(#un-#ref)
            elseif dn:lower():find("^"..ref:lower()) then nv=2.5*(#dn-#ref) end
            if nv<min then to_pl=p; min=nv end
        end
    end
    return to_pl
end

local function tpToPlayer(ref)
    if not ref or ref=="" then
        Library:Notification("❌","Ketik nama dulu!",2); return
    end
    local pl=infer_plr(ref)
    if not pl then Library:Notification("❌","Tidak ditemukan",2); return end
    if not pl.Character then Library:Notification("❌",pl.Name.." tidak ada karakter",2); return end
    local hrp=pl.Character:FindFirstChild("HumanoidRootPart")
           or pl.Character:FindFirstChild("Torso")
    if not hrp then Library:Notification("❌","Karakter tidak valid",2); return end
    local myChar=getChar()
    if myChar then
        myChar:PivotTo(hrp.CFrame*CFrame.new(0,3,0))
        Library:Notification("📍 TP","→ "..pl.Name,2)
    end
end

local function tpToMouse()
    local mouse=LP:GetMouse()
    if mouse and mouse.Hit then
        local root=getRoot()
        if root then
            root.CFrame=mouse.Hit*CFrame.new(0,3,0)
            Library:Notification("📍 TP","Ke posisi mouse",2)
        end
    end
end

local function quickRespawn()
    local root=getRoot()
    if not root then Library:Notification("❌","Karakter tidak ada",2); return end
    local savedCF=root.CFrame; local sWS=curWS; local sJP=curJP
    local c=getChar(); if c then c:BreakJoints() end
    local conn
    conn=LP.CharacterAdded:Connect(function(newChar)
        conn:Disconnect(); task.wait(0.8)
        local hrp=newChar:WaitForChild("HumanoidRootPart",5)
        local hum=newChar:WaitForChild("Humanoid",5)
        if hrp then hrp.CFrame=savedCF end
        if hum then hum.WalkSpeed=sWS; hum.JumpPower=sJP; hum.UseJumpPower=true end
        Library:Notification("✅ Respawn","Kembali ke posisi semula",2)
    end)
end

-- ════════════════════════════════════════
--  ⑧ PROTECTION
-- ════════════════════════════════════════
local function startAntiAFK()
    if afkConn then return end
    afkConn=LP.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
local function stopAntiAFK()
    if afkConn then afkConn:Disconnect(); afkConn=nil end
end
local function startAntiKick()
    if antiKickOn then return end
    antiKickOn=true
    task.spawn(function()
        while antiKickOn do
            pcall(function()
                local hum=getHum()
                if hum and hum.Health>0 and hum.Health<hum.MaxHealth*0.1 then
                    hum.Health=hum.MaxHealth
                end
            end)
            task.wait(0.5)
        end
    end)
end
local function stopAntiKick() antiKickOn=false end

-- ════════════════════════════════════════
--  ⑨ AUTO RESPAWN
-- ════════════════════════════════════════
local autoRespawnOn   = false
local respawnMode     = "Natural"  -- "Natural" atau "Cepat"
local respawnConn     = nil
local lastPos         = nil
local respawnWaitTime = 1.0  -- detik tunggu setelah spawn

local function setupAutoRespawn()
    -- Cleanup koneksi lama
    if respawnConn then
        pcall(function() respawnConn:Disconnect() end)
        respawnConn = nil
    end
    if not autoRespawnOn then return end

    local function hookCharacter(char)
        local hum  = char:WaitForChild("Humanoid", 5)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not hum or not root then return end

        -- Simpan posisi terus menerus saat hidup
        local posConn = RunService.Heartbeat:Connect(function()
            if root and root.Parent then
                lastPos = root.CFrame
            end
        end)

        -- Deteksi mati
        hum.Died:Connect(function()
            posConn:Disconnect()
            local savedCF = lastPos
            if not savedCF then return end

            if respawnMode == "Cepat" then
                -- Mode Cepat: BreakJoints setelah deteksi mati
                task.wait(0.1)
                pcall(function() char:BreakJoints() end)
            end
            -- Mode Natural: tunggu game respawn sendiri

            -- Tunggu karakter baru
            local conn2
            conn2 = LP.CharacterAdded:Connect(function(newChar)
                conn2:Disconnect()
                task.wait(respawnWaitTime)
                local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
                local hum2 = newChar:WaitForChild("Humanoid", 5)
                if hrp then
                    hrp.CFrame = savedCF
                end
                if hum2 then
                    hum2.WalkSpeed    = curWS
                    hum2.JumpPower    = curJP
                    hum2.UseJumpPower = true
                end
                Library:Notification("✅ Auto Respawn",
                    string.format("Kembali!\nMode: %s\nX=%.0f Y=%.0f Z=%.0f",
                        respawnMode,
                        savedCF.Position.X,
                        savedCF.Position.Y,
                        savedCF.Position.Z), 4)
                -- Hook karakter baru
                task.wait(1)
                if autoRespawnOn then
                    hookCharacter(newChar)
                end
            end)
        end)
    end

    -- Hook karakter saat ini
    if LP.Character then
        hookCharacter(LP.Character)
    end

    -- Hook karakter berikutnya (sudah di-handle di Died)
    respawnConn = LP.CharacterAdded:Connect(function() end) -- placeholder
end

-- ════════════════════════════════════════
--  BUILD UI — TAB FARM
-- ════════════════════════════════════════
local FarmPage  = TabFarm:Page("Auto Farm", "wheat")
local FarmLeft  = FarmPage:Section("🌾 Auto Farm", "Left")
local FarmRight = FarmPage:Section("🔧 Manual", "Right")

-- Dropdown pilih tanaman
local cropNames = {}
for _,c in ipairs(CROPS) do table.insert(cropNames, c.name) end

FarmLeft:Dropdown("Pilih Tanaman", "CropDropdown", cropNames,
    function(v) selectedCrop=v end)

FarmLeft:Slider("Beli Qty", "BuyQtySlider", 1, 50, 5,
    function(v) buyQty=v end, "Jumlah bibit dibeli per siklus")

FarmLeft:Slider("Delay Tanam (detik)", "PlantDelaySlider", 1, 10, 5,
    function(v) plantDelay=v*0.1 end, "Jeda antar tanam (x0.1 detik)")

FarmLeft:Toggle("🌾 AUTO FARM", "AutoFarmToggle", false,
    "Otomatis beli → tanam → panen loop",
    function(v)
        farmOn=v
        if v then
            startAutoFarm()
            Library:Notification("🌾 Auto Farm",
                "ON — "..selectedCrop.."\nLoop dimulai!", 3)
        else
            stopAutoFarm()
        end
    end)

FarmLeft:Paragraph("Status Farm",
    "Toggle untuk lihat\nstatus terbaru di\nnotifikasi\n\n"..
    "Counter panen muncul\ntiap kali harvest")

-- Manual step buttons
FarmRight:Button("🔍 Scan Toko Bibit", "Cari NPC toko di Workspace",
    function()
        task.spawn(function()
            Library:Notification("🔍","Scanning toko...",2)
            local ok, name, pos = scanTokoNPC()
            if ok then
                Library:Notification("✅ Toko Ditemukan",
                    string.format("Nama: %s\nX=%.1f Y=%.1f Z=%.1f",
                        name, pos.X, pos.Y, pos.Z), 6)
            else
                Library:Notification("❌","Toko tidak ditemukan\nSave manual di bawah",4)
            end
        end)
    end)

FarmRight:Button("💾 Save Posisi Toko (di sini)", "Simpan posisi toko dari posisi kamu sekarang",
    function()
        local root=getRoot()
        if root then
            tokoPos=root.Position
            Library:Notification("💾 Toko",
                string.format("Saved!\nX=%.1f Y=%.1f Z=%.1f",
                    tokoPos.X, tokoPos.Y, tokoPos.Z), 4)
        end
    end)

FarmRight:Button("📍 TP ke Toko", "Teleport ke NPC toko bibit",
    function()
        if tpToToko() then
            Library:Notification("📍","Tiba di toko",2)
        end
    end)

FarmRight:Button("🛒 Beli Bibit Sekarang", "FireServer beli bibit pilihan",
    function()
        local crop=getCrop(selectedCrop)
        Library:Notification("🛒","Beli "..crop.seedName.." x"..buyQty,2)
        task.spawn(function()
            local ok=beliBibit(crop.cropName, buyQty)
            if ok then
                Library:Notification("✅ Beli",
                    crop.seedName.." x"..buyQty.." berhasil!", 3)
            end
        end)
    end)

FarmRight:Button("📍 TP ke Lahan", "Teleport ke lahan pertama",
    function() tpToLahan(1) end)

FarmRight:Button("🌱 Tanam Sekarang", "Tanam ke semua lahan",
    function()
        task.spawn(function()
            local crop=getCrop(selectedCrop)
            Library:Notification("🌱","Menanam "..crop.cropName.."...",2)
            local n=tanamSemua(crop.cropName)
            Library:Notification("✅ Tanam",n.." lahan ditanam",3)
        end)
    end)

FarmRight:Toggle("👁 Monitor Panen", "MonitorToggle", false,
    "Monitor notif panen dari server",
    function(v)
        if v then startHarvestMonitor()
        else stopHarvestMonitor() end
        Library:Notification("👁 Monitor", v and "ON" or "OFF", 2)
    end)

FarmRight:Toggle("🌾 Auto Panen (ProximityPrompt)", "AutoPanenToggle", false,
    "Scan & trigger ProximityPrompt tanaman tiap 5 detik",
    function(v)
        autoPanenOn = v
        if v then
            startAutoPanen()
            Library:Notification("🌾 Auto Panen",
                "ON — Scan tiap 5 detik\nTrigger ProximityPrompt", 3)
        else
            stopAutoPanen()
            Library:Notification("🌾 Auto Panen","OFF",2)
        end
    end)

FarmRight:Button("🌾 Panen Manual Sekarang", "Trigger semua ProximityPrompt tanaman sekali",
    function()
        task.spawn(function()
            Library:Notification("🌾","Scanning tanaman matang...",2)
            local n = scanDanPanen()
            Library:Notification(
                n > 0 and "✅ Panen!" or "⏳ Belum Ada",
                n > 0
                    and string.format("%d tanaman dipanen!", n)
                    or "Tidak ada ProximityPrompt\nCoba lagi nanti",
                4)
        end)
    end)

FarmRight:Button("📊 Lihat Statistik", "Total panen & coins sesi ini",
    function()
        Library:Notification("📊 Statistik",
            string.format(
                "Total Panen: %d kali\n"..
                "Total Coins: %d\n"..
                "Tanaman: %s\n"..
                "Status: %s",
                totalHarvest, totalCoins,
                selectedCrop, farmStatus), 8)
    end)

FarmRight:Button("🔄 Reset Statistik", "Reset counter panen & coins",
    function()
        totalHarvest=0; totalCoins=0
        Library:Notification("🔄","Statistik direset",2)
    end)

-- Lahan section
local LahanPage  = TabFarm:Page("Kelola Lahan", "map-pin")
local LahanLeft  = LahanPage:Section("📍 Daftar Lahan", "Left")
local LahanRight = LahanPage:Section("➕ Tambah Lahan", "Right")

-- Tampilkan lahan yang ada
LahanLeft:Button("📄 Lihat Semua Lahan", "Tampilkan daftar posisi lahan",
    function()
        if #LAHAN==0 then
            Library:Notification("❌","Belum ada data lahan",2); return
        end
        local text=string.format("%d lahan tersimpan:\n\n",#LAHAN)
        for i,pos in ipairs(LAHAN) do
            text=text..string.format("[%d] X=%.0f Y=%.0f Z=%.0f\n",
                i, pos.X, pos.Y, pos.Z)
        end
        Library:Notification("📍 Lahan",text,10)
    end)

LahanLeft:Button("📍 TP ke Lahan 1", "Teleport ke lahan pertama",
    function() tpToLahan(1) end)
LahanLeft:Button("📍 TP ke Lahan 2", "Teleport ke lahan kedua",
    function() tpToLahan(2) end)
LahanLeft:Button("📍 TP ke Lahan 3", "Teleport ke lahan ketiga",
    function() tpToLahan(3) end)
LahanLeft:Button("📍 TP ke Lahan 4", "Teleport ke lahan keempat",
    function() tpToLahan(4) end)
LahanLeft:Button("📍 TP ke Lahan 5", "Teleport ke lahan kelima",
    function() tpToLahan(5) end)

LahanRight:Paragraph("Tambah Lahan Manual",
    "Berdiri di atas lahan\nlalu tekan tombol\nSave di bawah\n\n"..
    "Lahan baru otomatis\nditambah ke daftar")

for i=1,5 do
    local idx=i
    LahanRight:Button("💾 Save Lahan "..idx, "Simpan posisi kamu sebagai lahan "..idx,
        function()
            local root=getRoot()
            if not root then
                Library:Notification("❌","Karakter tidak ada",2); return
            end
            LAHAN[idx]=root.Position
            Library:Notification("💾 Lahan "..idx,
                string.format("X=%.1f Y=%.1f Z=%.1f",
                    root.Position.X, root.Position.Y, root.Position.Z), 3)
        end)
end

-- ════════════════════════════════════════
--  BUILD UI — TAB TELEPORT
-- ════════════════════════════════════════
local TPage  = TabTP:Page("Teleport","map-pin")
local TLeft  = TPage:Section("👥 Ke Player","Left")
local TRight = TPage:Section("💾 Slot","Right")

TLeft:Button("👥 Lihat Player Online","Tampilkan semua player",
    function()
        local list,n="",0
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP then
                local r2=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local mr=getRoot()
                local d=(r2 and mr) and getDist(r2.Position,mr.Position) or "?"
                n=n+1
                list=list..string.format("• %s — %sm\n",p.Name,tostring(d))
            end
        end
        Library:Notification("👥 "..n.." Online",
            n>0 and list or "Tidak ada player lain",10)
    end)

local tpInput=""
TLeft:TextBox("Nama / Prefix","TPInput","",
    function(v) tpInput=v end,"Ketik 1-2 huruf pertama nama")
TLeft:Button("📍 Teleport ke Player","TP ke player",
    function() tpToPlayer(tpInput) end)
TLeft:Button("🖱 TP ke Mouse","TP ke posisi tap",
    function() tpToMouse() end)
TLeft:Button("💀 Respawn Cepat","Mati & spawn di posisi sama",
    function() quickRespawn() end)

TLeft:Paragraph("Cara Pakai",
    "1. Lihat Player Online\n\n"..
    "2. Ketik 1-2 huruf\n"..
    "   pertama nama\n\n"..
    "3. Tekan TP!")

TRight:Label("💾 Save & Load Posisi")
for i=1,5 do
    local idx=i
    TRight:Button("💾 Save Slot "..idx,"Simpan posisi",
        function()
            local root=getRoot()
            if not root then return end
            slots[idx]=root.CFrame
            local p=root.Position
            Library:Notification("💾 Slot "..idx,
                string.format("X=%.0f Y=%.0f Z=%.0f",p.X,p.Y,p.Z),3)
        end)
    TRight:Button("🚀 Load Slot "..idx,"TP ke slot",
        function()
            if not slots[idx] then
                Library:Notification("❌","Slot "..idx.." kosong",2); return
            end
            local root=getRoot()
            if root then root.CFrame=slots[idx] end
            local p=slots[idx].Position
            Library:Notification("📍 Slot "..idx,
                string.format("X=%.0f Y=%.0f Z=%.0f",p.X,p.Y,p.Z),3)
        end)
end

-- ════════════════════════════════════════
--  BUILD UI — TAB FLY
-- ════════════════════════════════════════
local FlyPage = TabFly:Page("Fly & NoClip","rocket")
local FL      = FlyPage:Section("🚀 Fly","Left")
local FR      = FlyPage:Section("🚶 NoClip","Right")

FL:Toggle("Fly Mode","FlyToggle",false,"Terbang bebas",
    function(v)
        flyOn=v
        if v then startFly() else stopFly() end
        Library:Notification("🚀 Fly",v and "ON" or "OFF",2)
    end)
FL:Slider("Kecepatan","FlySpeedSlider",5,300,60,
    function(v) flySpeed=v end,"Default 60")
FL:Slider("Sensitivitas Naik/Turun","PitchSlider",1,9,3,
    function(v) PITCH_UP=v*0.1; PITCH_DOWN=-v*0.1 end,
    "1=Sensitif · 9=Perlu miring banyak")
FL:Paragraph("🎮 Kontrol",
    "Joystick → maju/mundur\nKanan/kiri\n\n"..
    "Kamera atas → NAIK\n"..
    "Kamera bawah → TURUN\n\n"..
    "Lepas semua → melayang")

FR:Toggle("NoClip","NoclipToggle",false,"Tembus semua dinding",
    function(v)
        setNoclip(v)
        Library:Notification("🚶 NoClip",v and "ON" or "OFF",2)
    end)
FR:Toggle("ESP Player","ESPToggle",false,"Lihat player tembus dinding",
    function(v) toggleESP(v) end)
FR:Button("🔄 Refresh ESP","Perbarui ESP",
    function()
        if espOn then
            clearESP(); task.wait(0.2)
            for _,p in pairs(Players:GetPlayers()) do makeESP(p) end
            Library:Notification("👁 ESP","Refreshed",2)
        end
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB SPEED
-- ════════════════════════════════════════
local SPage = TabSpd:Page("Speed & Jump","zap")
local SL    = SPage:Section("⚡ Speed","Left")
local SR    = SPage:Section("🦘 Jump","Right")

SL:Slider("WalkSpeed","WSSlider",1,500,16,
    function(v) curWS=v; local h=getHum(); if h then h.WalkSpeed=v end end,
    "Default 16")
SL:Button("🔁 Reset Speed","Kembalikan ke 16",
    function()
        curWS=16; local h=getHum()
        if h then h.WalkSpeed=16 end
        Library:Notification("Speed","Reset → 16",2)
    end)

SR:Slider("JumpPower","JPSlider",1,500,50,
    function(v)
        curJP=v; local h=getHum()
        if h then h.JumpPower=v; h.UseJumpPower=true end
    end,"Default 50")
SR:Button("🔁 Reset Jump","Kembalikan ke 50",
    function()
        curJP=50; local h=getHum()
        if h then h.JumpPower=50; h.UseJumpPower=true end
        Library:Notification("Jump","Reset → 50",2)
    end)
SR:Toggle("Infinite Jump","InfJumpToggle",false,"Lompat terus di udara",
    function(v)
        if v then
            _G.xkid_ij=UIS.JumpRequest:Connect(function()
                local h=getHum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if _G.xkid_ij then _G.xkid_ij:Disconnect(); _G.xkid_ij=nil end
        end
        Library:Notification("Inf Jump",v and "ON" or "OFF",2)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB PROTECTION
-- ════════════════════════════════════════
local PPage  = TabProt:Page("Protection","shield")
local PL     = PPage:Section("🛡 Controls","Left")
local PR     = PPage:Section("💀 Auto Respawn","Right")

PL:Toggle("Anti AFK","AntiAFKToggle",false,"Cegah disconnect",
    function(v)
        if v then startAntiAFK() else stopAntiAFK() end
        Library:Notification("Anti AFK",v and "ON" or "OFF",2)
    end)
PL:Toggle("Anti Kick","AntiKickToggle",false,"Cegah dikeluarkan",
    function(v)
        if v then startAntiKick() else stopAntiKick() end
        Library:Notification("Anti Kick",v and "ON" or "OFF",2)
    end)
PL:Button("🔄 Rejoin Server","Koneksi ulang",
    function()
        Library:Notification("🔄","Menghubungkan ulang...",3)
        task.wait(1); TpService:Teleport(game.PlaceId,LP)
    end)
PL:Button("📍 Posisi Saya","Lihat koordinat sekarang",
    function()
        local root=getRoot()
        if root then
            local p=root.Position
            Library:Notification("📍 Posisi",
                string.format("X=%.1f\nY=%.1f\nZ=%.1f",p.X,p.Y,p.Z),6)
        end
    end)

PL:Paragraph("Info",
    "Anti AFK:\nCegah auto-disconnect\n\n"..
    "Anti Kick:\nJaga HP dari kick\n\n"..
    "Rejoin:\nKoneksi ulang cepat\n\n"..
    "ESP:\nDi tab Fly → NoClip")

-- ── Auto Respawn ──
PR:Toggle("💀 Auto Respawn","AutoRespawnToggle",false,
    "Otomatis kembali ke posisi terakhir saat mati",
    function(v)
        autoRespawnOn = v
        if v then
            setupAutoRespawn()
            Library:Notification("💀 Auto Respawn",
                "ON — Mode: "..respawnMode.."\nPosisi terakhir tersimpan", 3)
        else
            if respawnConn then
                pcall(function() respawnConn:Disconnect() end)
                respawnConn = nil
            end
            Library:Notification("💀 Auto Respawn","OFF",2)
        end
    end)

PR:Dropdown("Mode Respawn","RespawnModeDropdown",
    {"Natural — Tunggu game","Cepat — BreakJoints"},
    function(v)
        if v:find("Natural") then
            respawnMode     = "Natural"
            respawnWaitTime = 1.0
        else
            respawnMode     = "Cepat"
            respawnWaitTime = 0.5
        end
        Library:Notification("Mode Respawn",respawnMode,2)
        -- Re-setup jika sudah aktif
        if autoRespawnOn then setupAutoRespawn() end
    end)

PR:Button("💀 Respawn Sekarang (Natural)","Mati & kembali ke posisi sekarang",
    function()
        local root=getRoot()
        if not root then
            Library:Notification("❌","Karakter tidak ada",2); return
        end
        local savedCF = root.CFrame
        local sWS,sJP = curWS,curJP
        local c=getChar(); if c then c:BreakJoints() end
        local conn
        conn=LP.CharacterAdded:Connect(function(newChar)
            conn:Disconnect(); task.wait(0.8)
            local hrp=newChar:WaitForChild("HumanoidRootPart",5)
            local hum=newChar:WaitForChild("Humanoid",5)
            if hrp then hrp.CFrame=savedCF end
            if hum then
                hum.WalkSpeed=sWS
                hum.JumpPower=sJP
                hum.UseJumpPower=true
            end
            Library:Notification("✅ Respawn","Kembali ke posisi semula",2)
        end)
    end)

PR:Paragraph("Info Respawn",
    "Natural:\nTunggu animasi mati\nlebih aman\n\n"..
    "Cepat:\nBreakJoints langsung\nrespawn lebih cepat\n\n"..
    "Posisi disimpan\nsecara otomatis\ntiap detik saat hidup")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
-- Auto scan toko saat load
task.spawn(function()
    task.wait(2)
    local ok, name, pos = scanTokoNPC()
    if ok then
        Library:Notification("✅ Toko Auto-Scan",
            "Toko: "..name.."\nSiap digunakan!", 4)
    end
end)

Library:Notification("🌟 XKID FULL v1.0",
    "Farm+Hub siap!\nScan toko otomatis...", 4)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════╗")
print("║   🌟  XKID FULL v1.0               ║")
print("║   Farm · TP · Fly · Speed · Prot    ║")
print("║   Player: "..LP.Name)
print("╚══════════════════════════════════════╝")
