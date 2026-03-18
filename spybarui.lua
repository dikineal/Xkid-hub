--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🌾  I N D O   F A R M E R  v24.0  🌾           ║
  ║      XKID HUB  ✦  Aurora UI                         ║
  ║      ESP Growth · Vector3 Plant · Clean UI           ║
  ╚═══════════════════════════════════════════════════════╝
  v24:
  [1] PlantCrop: loop Vector3 setiap BasePart di AreaTanam*
  [2] HarvestCrop: firesignal OnClientEvent semua/pilih satu
  [3] GetBibit: FireServer(0, false)
  [4] ESP: track Size min/max otomatis → tampil % tumbuh
  [5] Petir: intercept LightningStrike → TP SafeZone instan
  [6] Teleport: NPC ProximityPrompt + TP ke Player
  [7] UI bersih tanpa duplikasi
]]

-- ════════════════════════════════════════
--  LOAD AURORA UI
-- ════════════════════════════════════════
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Win = Library:Window("Indo Farmer", "sprout", "v24.0 | XKID HUB", false)

-- ════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════
local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TpService  = game:GetService("TeleportService")
local LP         = Players.LocalPlayer

-- ════════════════════════════════════════
--  FLAGS
-- ════════════════════════════════════════
_G.AutoHarvest    = false
_G.AutoSell       = false
_G.AutoBeliBibit  = false
_G.ESPTanaman     = false
_G.PenangkalPetir = false
_G.AntiAFK        = false
_G.AntiKick       = false
_G.AutoConfirm    = false
_G.NotifLevelUp   = true
_G.AutoMandi      = false
_G.FlyOn          = false
_G.NoclipOn       = false

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local PlayerData    = { Coins=0, Level=1, XP=0, Needed=50 }
local lightningHits = 0
local levelUpCount  = 0
local totalEarned   = 0
local harvestCount  = 0
local plantCount    = 0
local HarvestLoop   = nil
local SellLoop      = nil
local antiKickConn  = nil
local antiAFKConn   = nil
local noclipConn    = nil
local flyBV         = nil
local flyBG         = nil
local flyConn       = nil
local flySpeed      = 60
local PITCH_UP      =  0.3
local PITCH_DOWN    = -0.3
local curWS         = 16
local curJP         = 50
local isPetirActive = false
local petirReturnCF = nil
local godConn       = nil
local selectedBibit = "Bibit Padi"
local jumlahBeli    = 10
local minStok       = 5
local selectedCrop  = "Padi"
local harvestAll    = true

-- ════════════════════════════════════════
--  DATA
-- ════════════════════════════════════════
local CROP_LIST = {
    { name="Padi",       idx=1, icon="🌾" },
    { name="Jagung",     idx=2, icon="🌽" },
    { name="Tomat",      idx=3, icon="🍅" },
    { name="Terong",     idx=4, icon="🍆" },
    { name="Strawberry", idx=5, icon="🍓" },
    { name="Sawit",      idx=6, icon="🌴" },
    { name="Durian",     idx=7, icon="🍈" },
}
local cropNames = {}
for _, c in ipairs(CROP_LIST) do table.insert(cropNames, c.icon.." "..c.name) end

local BIBIT_LIST = {
    { name="Bibit Padi",       price=5,    minLv=1,   icon="🌾" },
    { name="Bibit Jagung",     price=15,   minLv=20,  icon="🌽" },
    { name="Bibit Tomat",      price=25,   minLv=40,  icon="🍅" },
    { name="Bibit Terong",     price=40,   minLv=60,  icon="🍆" },
    { name="Bibit Strawberry", price=60,   minLv=80,  icon="🍓" },
    { name="Bibit Sawit",      price=1000, minLv=80,  icon="🌴" },
    { name="Bibit Durian",     price=2000, minLv=120, icon="🍈" },
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

-- NPC ProximityPrompt paths
local NPC_LIST = {
    { label="Pedagang Susu",  path={"NPCs","NPCPedagangSusu","aaa"}                        },
    { label="Pedagang Telur", path={"NPCs","NPCPedagangTelur","NPCPedagangTelur"}          },
    { label="NPC Alat",       path={"NPCs","NPC_Alat","npcalat"}                           },
    { label="NPC Bibit",      path={"NPCs","NPC_Bibit","npcbibit"}                         },
    { label="Pedagang Sawit", path={"NPCs","NPC_PedagangSawit","NPCPedagangSawit"}         },
    { label="NPC Penjual",    path={"NPCs","NPC_Penjual","npcpenjual"}                     },
}

-- ════════════════════════════════════════
--  CACHE FARM PLOTS
-- ════════════════════════════════════════
local plotCache = nil

local function scanPlots()
    if plotCache then return plotCache end
    plotCache = {}

    local areaNames = {"AreaTanam","AreaTanam3","AreaTanam4","AreaTanam5","AreaTanam6","AreaTanam7"}
    for _, name in ipairs(areaNames) do
        local area = Workspace:FindFirstChild(name)
        if area then
            for _, p in ipairs(area:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    table.insert(plotCache, p)
                end
            end
        end
    end

    for i = 1, 29 do
        local area = Workspace:FindFirstChild("AreaTanamBesar"..i)
        if area then
            for _, p in ipairs(area:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    table.insert(plotCache, p)
                end
            end
        end
    end

    print("[ XKID ] Plots cached: "..#plotCache)
    return plotCache
end

-- Cache SafeZone
local safeZoneCache = nil
local function getSafeZones()
    if safeZoneCache then return safeZoneCache end
    safeZoneCache = {}
    for i = 1, 12 do
        local sz = Workspace:FindFirstChild("SafeZone"..i)
        if sz then
            local part = sz:IsA("BasePart") and sz
                      or sz:FindFirstChildOfClass("BasePart")
            if part then table.insert(safeZoneCache, part) end
        end
    end
    print("[ XKID ] SafeZones cached: "..#safeZoneCache)
    return safeZoneCache
end

-- ════════════════════════════════════════
--  REMOTE HELPERS
-- ════════════════════════════════════════
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

-- ════════════════════════════════════════
--  NOTIF
-- ════════════════════════════════════════
local function notif(title, body, dur)
    pcall(function() Library:Notification(title, body, dur or 3) end)
    print(string.format("[ XKID ] %s | %s", title, tostring(body)))
end

-- ════════════════════════════════════════
--  CHARACTER HELPERS
-- ════════════════════════════════════════
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function getPos() local r = getRoot(); return r and r.Position end
local function getCF()  local r = getRoot(); return r and r.CFrame  end

-- ════════════════════════════════════════
--  PLANT — Vector3 loop per BasePart
-- ════════════════════════════════════════
local function plantAllPlots()
    local plots = scanPlots()
    if #plots == 0 then
        notif("Plant", "Tidak ada plot ditemukan!", 4); return 0
    end
    local r = getR("PlantCrop")
    if not r then notif("Plant", "PlantCrop remote tidak ada", 4); return 0 end
    local count = 0
    for _, plot in ipairs(plots) do
        pcall(function() r:FireServer(plot.Position) end)
        count = count + 1
        plantCount = plantCount + 1
        task.wait(0.15)
    end
    return count
end

-- ════════════════════════════════════════
--  HARVEST — firesignal OnClientEvent
--  Args: "Nama", idx, "Nama"
-- ════════════════════════════════════════
local function harvestCrop(cropName, cropIdx)
    local Event = getR("HarvestCrop")
    if not Event then
        notif("Harvest", "HarvestCrop tidak ada", 4); return 0
    end
    pcall(function()
        firesignal(Event.OnClientEvent, cropName, cropIdx, cropName)
    end)
    harvestCount = harvestCount + 1
    return 1
end

local function harvestAll()
    local Event = getR("HarvestCrop")
    if not Event then
        notif("Harvest", "HarvestCrop tidak ada", 4); return 0
    end
    local count = 0
    for _, crop in ipairs(CROP_LIST) do
        pcall(function()
            firesignal(Event.OnClientEvent, crop.name, crop.idx, crop.name)
        end)
        harvestCount = harvestCount + 1
        count = count + 1
        task.wait(0.2)
    end
    return count
end

-- ════════════════════════════════════════
--  JUAL
-- ════════════════════════════════════════
local function getInventory()
    local ok, res = invokeRF("RequestSell", "GET_LIST")
    if not ok then return nil end
    local data = unwrap(res)
    if data then PlayerData.Coins = data.Coins or PlayerData.Coins end
    return data
end

local function jualItem(nama, qty)
    local ok, res = invokeRF("RequestSell", "SELL", nama, qty or 1)
    if not ok then return false, "Remote gagal", 0 end
    local data = unwrap(res)
    if data and data.Success then
        local earned = data.Earned or 0
        totalEarned = totalEarned + earned
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        return true, data.Message or "Terjual", earned
    end
    return false, (data and data.Message) or "Gagal", 0
end

local function jualSemua()
    local data = getInventory()
    if not data or not data.Items then
        fireEv("SellCrop"); return true, "SellCrop dikirim"
    end
    local totalItem, totalCoin = 0, 0
    for _, item in ipairs(data.Items) do
        if (item.Owned or 0) > 0 and (item.Price or 0) > 0 then
            local ok, _, earned = jualItem(item.Name, item.Owned)
            if ok then
                totalItem = totalItem + item.Owned
                totalCoin = totalCoin + earned
            end
            task.wait(0.3)
        end
    end
    if totalItem == 0 then fireEv("SellCrop"); return true, "SellCrop fallback" end
    return true, totalItem.." item | +"..totalCoin.." koin"
end

-- ════════════════════════════════════════
--  BELI BIBIT
--  GetBibit:FireServer(0, false) — dari spy log lama
--  RequestShop:InvokeServer("BUY", nama, qty)
-- ════════════════════════════════════════
local function ambilBibit()
    fireEv("GetBibit", 0, false)
    notif("GetBibit", "Dikirim (0, false)", 2)
end

local function beliBibit(nama, qty)
    local ok, res = invokeRF("RequestShop", "BUY", nama or selectedBibit, qty or jumlahBeli)
    if not ok then return false, "RequestShop gagal" end
    local data = unwrap(res)
    if data and data.Success then
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        return true, data.Message or "Berhasil"
    end
    return false, (data and data.Message) or "Gagal"
end

local function cekDanBeliBibit()
    local ok, res = invokeRF("RequestShop", "GET_LIST")
    if not ok then return end
    local data = unwrap(res)
    if not data or not data.Seeds then return end
    PlayerData.Coins = data.Coins or PlayerData.Coins
    for _, s in ipairs(data.Seeds) do
        if not s.Locked and (s.Owned or 0) < minStok then
            local bOk, bMsg = beliBibit(s.Name, jumlahBeli)
            notif("Auto Beli", s.Name.." | "..(bMsg or ""), 3)
            task.wait(0.5)
        end
    end
end

-- ════════════════════════════════════════
--  MANDI
-- ════════════════════════════════════════
local function goMandi()
    local root = getRoot(); if not root then return end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local ch = getChar(); if ch then rp.FilterDescendantsInstances = {ch} end
    local res = Workspace:Raycast(Vector3.new(137,500,-235), Vector3.new(0,-1000,0), rp)
    local y = res and (res.Position.Y + 3) or 42
    root.CFrame = CFrame.new(137, y, -235)
    notif("Mandi", "X=137 Z=-235", 2)
end

-- ════════════════════════════════════════
--  PENANGKAL PETIR
--  Intercept LightningStrike.OnClientEvent
--  data.Hit == true → TP SafeZone instan
-- ════════════════════════════════════════
local function startHpLock(dur)
    if godConn then godConn:Disconnect(); godConn = nil end
    local deadline = tick() + dur
    godConn = RunService.Heartbeat:Connect(function()
        if tick() > deadline then godConn:Disconnect(); godConn = nil; return end
        local h = getHum()
        if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
    end)
end

local function fleePetir()
    if isPetirActive then return end
    isPetirActive = true
    lightningHits = lightningHits + 1

    local root = getRoot()
    if not root then isPetirActive = false; return end

    -- HP penuh instan
    local h = getHum()
    if h then h.Health = h.MaxHealth end
    petirReturnCF = root.CFrame
    startHpLock(6)

    -- TP ke SafeZone acak
    local zones = getSafeZones()
    if #zones > 0 then
        local sz = zones[math.random(1, #zones)]
        root.CFrame = sz.CFrame * CFrame.new(0, 3, 0)
        notif("Petir #"..lightningHits, "Kabur ke SafeZone | balik 4s", 4)
    else
        -- Fallback: naik awan
        root.CFrame = CFrame.new(root.Position.X, root.Position.Y + 300, root.Position.Z)
        notif("Petir #"..lightningHits, "Naik awan | balik 4s", 4)
    end

    task.wait(4)
    local r2 = getRoot()
    if r2 and petirReturnCF then
        r2.CFrame = petirReturnCF
        notif("Kembali", "Balik ke posisi semula", 2)
    end
    task.wait(0.5)
    isPetirActive = false
end

-- ════════════════════════════════════════
--  ANTI AFK
-- ════════════════════════════════════════
local function startAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect() end
    local last = tick()
    antiAFKConn = RunService.Heartbeat:Connect(function()
        if not _G.AntiAFK then
            antiAFKConn:Disconnect(); antiAFKConn = nil; return
        end
        if tick() - last >= 120 then
            last = tick()
            local h = getHum(); if h then h.Jump = true end
        end
    end)
end

-- ════════════════════════════════════════
--  ANTI KICK
-- ════════════════════════════════════════
local function startAntiKick()
    if antiKickConn then return end
    antiKickConn = RunService.Heartbeat:Connect(function()
        if not _G.AntiKick then
            antiKickConn:Disconnect(); antiKickConn = nil; return
        end
        pcall(function()
            local h = getHum()
            if h and h.Health > 0 and h.Health < h.MaxHealth * 0.15 then
                h.Health = h.MaxHealth
                notif("Anti Kick", "HP dikembalikan!", 2)
            end
        end)
    end)
end

-- ════════════════════════════════════════
--  NOCLIP
-- ════════════════════════════════════════
local function setNoclip(state)
    _G.NoclipOn = state
    if state then
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
--  FLY
-- ════════════════════════════════════════
local function startFly()
    local root = getRoot(); if not root then return end
    local hum  = getHum();  if not hum  then return end
    if flyBV   then pcall(function() flyBV:Destroy()      end) end
    if flyBG   then pcall(function() flyBG:Destroy()      end) end
    if flyConn then pcall(function() flyConn:Disconnect() end) end
    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Velocity = Vector3.new(); flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyBG.P = 1e4; flyBG.D = 100; flyBG.CFrame = root.CFrame
    hum.PlatformStand = true
    flyConn = RunService.Heartbeat:Connect(function()
        local r2 = getRoot(); if not r2 or not flyBV then return end
        local h2 = getHum();  if not h2 then return end
        local cam = Workspace.CurrentCamera; local cf = cam.CFrame
        local fwd = Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
        local rgt = Vector3.new(cf.RightVector.X,0,cf.RightVector.Z)
        if fwd.Magnitude>0 then fwd=fwd.Unit end
        if rgt.Magnitude>0 then rgt=rgt.Unit end
        local md = h2.MoveDirection; local horiz = Vector3.new()
        if md.Magnitude > 0.05 then
            horiz = fwd*md:Dot(fwd) + rgt*md:Dot(rgt)
            if horiz.Magnitude > 1 then horiz = horiz.Unit end
        end
        local py = cf.LookVector.Y; local vert = Vector3.new()
        if py > PITCH_UP then
            vert = Vector3.new(0, math.min((py-PITCH_UP)/(1-PITCH_UP),1), 0)
        elseif py < PITCH_DOWN then
            vert = Vector3.new(0, -math.min((-py+PITCH_DOWN)/(1+PITCH_DOWN),1), 0)
        end
        local dir = horiz + vert
        if dir.Magnitude > 0 then
            flyBV.Velocity = (dir.Magnitude>1 and dir.Unit or dir) * flySpeed
            if horiz.Magnitude > 0.05 then flyBG.CFrame = CFrame.new(Vector3.new(), horiz) end
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
    local h = getHum(); if h then h.PlatformStand = false end
end

LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5); if not hum then return end
    task.wait(0.5)
    hum.WalkSpeed = curWS; hum.JumpPower = curJP; hum.UseJumpPower = true
    if _G.FlyOn then task.wait(0.3); startFly() end
end)

-- ════════════════════════════════════════
--  ESP TANAMAN
--  Track Size min/max per nama tanaman
--  % = (SizeMag - MinMag) / (MaxMag - MinMag) * 100
-- ════════════════════════════════════════
local VALID_CROPS = {
    Padi=true, Jagung=true, Tomat=true, Terong=true,
    Strawberry=true, Sawit=true, Durian=true
}

local sizeTracker = {}  -- name → { min, max }
local espTagged   = {}  -- part → bill
local espBills    = {}
local espLoopTask = nil
local lastESPScan = 0

local function getGrowthPct(part, cropName)
    local mag = part.Size.Magnitude
    local tr  = sizeTracker[cropName]
    if not tr then
        sizeTracker[cropName] = { min=mag, max=mag }
        return 0
    end
    if mag < tr.min then tr.min = mag end
    if mag > tr.max then tr.max = mag end
    if tr.max == tr.min then return 50 end
    local pct = (mag - tr.min) / (tr.max - tr.min) * 100
    return math.floor(math.clamp(pct, 0, 100))
end

local function getGrowthColor(pct)
    if pct >= 80 then return Color3.fromRGB(80, 255, 80)   end -- hijau = siap
    if pct >= 40 then return Color3.fromRGB(255, 220, 50)  end -- kuning = setengah
    return Color3.fromRGB(255, 100, 100)                        -- merah = baru tanam
end

local function makeESPBill(part, cropName)
    if espTagged[part] then return end
    espTagged[part] = true

    local bill = Instance.new("BillboardGui")
    bill.Size        = UDim2.new(0, 120, 0, 36)
    bill.StudsOffset = Vector3.new(0, 4, 0)
    bill.AlwaysOnTop = true
    bill.Adornee     = part
    bill.Parent      = part

    local bg = Instance.new("Frame", bill)
    bg.Size                   = UDim2.new(1,0,1,0)
    bg.BackgroundColor3       = Color3.fromRGB(8,20,8)
    bg.BackgroundTransparency = 0.25
    bg.BorderSizePixel        = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,6)

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size                   = UDim2.new(1,-4,1,-4)
    lbl.Position               = UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency = 1
    lbl.TextScaled             = true
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextXAlignment         = Enum.TextXAlignment.Center

    -- Update label setiap detik
    local updateConn = RunService.Heartbeat:Connect(function()
        if not bill or not bill.Parent then return end
        local pct   = getGrowthPct(part, cropName)
        local color = getGrowthColor(pct)
        lbl.Text       = cropName.."\n"..pct.."%"
        lbl.TextColor3 = color
        lbl.TextStrokeColor3       = Color3.fromRGB(0,0,0)
        lbl.TextStrokeTransparency = 0.3
    end)

    table.insert(espBills, { bill=bill, conn=updateConn })
end

local function clearESP()
    for _, entry in ipairs(espBills) do
        pcall(function() entry.conn:Disconnect() end)
        pcall(function() entry.bill:Destroy()    end)
    end
    espBills  = {}
    espTagged = {}
end

local function scanESP()
    local now = tick()
    if now - lastESPScan < 8 then return end
    lastESPScan = now
    local count = 0
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and VALID_CROPS[v.Name] and not espTagged[v] then
            makeESPBill(v, v.Name)
            count = count + 1
        elseif v:IsA("Model") and VALID_CROPS[v.Name] then
            local part = v.PrimaryPart or v:FindFirstChildOfClass("BasePart")
            if part and not espTagged[part] then
                makeESPBill(part, v.Name)
                count = count + 1
            end
        end
    end
    if count > 0 then notif("ESP", "+"..count.." tanaman ditemukan", 2) end
end

local function startESP()
    clearESP(); lastESPScan = 0; scanESP()
    espLoopTask = task.spawn(function()
        while _G.ESPTanaman do task.wait(10); if _G.ESPTanaman then scanESP() end end
    end)
end

local function stopESP()
    clearESP()
    if espLoopTask then pcall(function() task.cancel(espLoopTask) end); espLoopTask = nil end
end

-- ════════════════════════════════════════
--  NPC TELEPORT via ProximityPrompt
-- ════════════════════════════════════════
local function getNPCPart(pathTable)
    local obj = Workspace
    for _, p in ipairs(pathTable) do
        obj = obj:FindFirstChild(p)
        if not obj then return nil end
    end
    return obj:IsA("BasePart") and obj
        or obj:FindFirstChildOfClass("BasePart")
        or obj
end

local function tpToNPC(label, pathTable)
    local root = getRoot(); if not root then return end
    local part = getNPCPart(pathTable)
    if part then
        local pos = part:IsA("BasePart") and part.Position or part.Position
        root.CFrame = CFrame.new(pos) * CFrame.new(0, 0, 4)
        notif("TP "..label, "Berhasil", 2)
    else
        notif("TP "..label, "NPC tidak ditemukan", 3)
    end
end

-- ════════════════════════════════════════
--  TP KE PLAYER
-- ════════════════════════════════════════
local function inferPlayer(ref)
    if typeof(ref) ~= "string" or ref == "" then return nil end
    local best, min = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local nv = math.huge
            if p.Name:find("^"..ref)             then nv = 1.0*(#p.Name-#ref)
            elseif p.DisplayName:find("^"..ref)  then nv = 1.5*(#p.DisplayName-#ref)
            elseif p.Name:lower():find("^"..ref:lower())        then nv = 2.0*(#p.Name-#ref)
            elseif p.DisplayName:lower():find("^"..ref:lower()) then nv = 2.5*(#p.DisplayName-#ref)
            end
            if nv < min then best = p; min = nv end
        end
    end
    return best
end

local function tpToPlayer(ref)
    if not ref or ref == "" then
        notif("TP Player", "Ketik nama dulu!", 2); return
    end
    local pl = inferPlayer(ref)
    if not pl then notif("TP Player", "Tidak ditemukan: "..ref, 3); return end
    if not pl.Character then notif("TP Player", pl.Name.." tidak ada karakter", 2); return end
    local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
    local root = getRoot()
    if hrp and root then
        root.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
        notif("TP Player", "Ke "..pl.Name, 2)
    end
end

-- ════════════════════════════════════════
--  STOP ALL
-- ════════════════════════════════════════
local function stopSemua()
    _G.AutoHarvest=false; _G.AutoSell=false; _G.AutoBeliBibit=false
    _G.ESPTanaman=false; _G.AntiKick=false; _G.AntiAFK=false
    if HarvestLoop then pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil end
    if SellLoop    then pcall(function() task.cancel(SellLoop)    end); SellLoop=nil    end
    stopESP(); stopFly()
    notif("STOP SEMUA", "Semua fitur dimatikan", 3)
end

-- ════════════════════════════════════════
--  INTERCEPTS
-- ════════════════════════════════════════
local function setupIntercepts()
    -- LightningStrike → TP SafeZone instan
    task.spawn(function()
        local r
        for i=1,30 do r=getR("LightningStrike"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
            if not _G.PenangkalPetir then return end
            if type(data)=="table" and data.Hit then
                task.spawn(fleePetir)
            end
        end)
        print("[ XKID ] LightningStrike intercept READY")
    end)
    -- UpdateLevel
    task.spawn(function()
        local r
        for i=1,15 do r=getR("UpdateLevel"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
            if type(data)~="table" then return end
            PlayerData.Level=data.Level or PlayerData.Level
            if data.LeveledUp and _G.NotifLevelUp then
                levelUpCount=levelUpCount+1
                notif("Level Up! #"..levelUpCount,
                    "Level "..data.Level, 5)
            end
        end)
    end)
    -- Notification
    task.spawn(function()
        local r
        for i=1,15 do r=getR("Notification"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(msg)
            if type(msg)~="string" then return end
            local ml = msg:lower()
            if ml:find("kotor") or ml:find("mandi") then
                notif("Perlu Mandi!", msg, 4)
                if _G.AutoMandi then task.delay(0.5, goMandi) end
            end
        end)
    end)
    print("[ XKID ] INTERCEPTS READY")
end

-- ════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════
Win:TabSection("Farming")
local TabBibit   = Win:Tab("Bibit",    "shopping-cart")
local TabHarvest = Win:Tab("Harvest",  "scissors")
local TabJual    = Win:Tab("Jual",     "coins")
local TabESP     = Win:Tab("ESP",      "eye")

Win:TabSection("Player")
local TabMove    = Win:Tab("Movement", "zap")
local TabProt    = Win:Tab("Shield",   "shield")

Win:TabSection("Utility")
local TabTP      = Win:Tab("Teleport", "map-pin")
local TabPetir   = Win:Tab("Petir",    "cloud-lightning")
local TabSet     = Win:Tab("Setting",  "settings")

-- ════════════════════════════════════════
--  TAB BIBIT
-- ════════════════════════════════════════
local BibitPage  = TabBibit:Page("Beli Bibit", "shopping-cart")
local BibitLeft  = BibitPage:Section("Pilih & Beli", "Left")
local BibitRight = BibitPage:Section("Beli Cepat", "Right")

BibitLeft:Dropdown("Pilih Bibit", "BibitDrop", bibitNames,
    function(val) selectedBibit=val; notif("Bibit", val.." dipilih", 2) end,
    "Pilih bibit")

BibitLeft:Slider("Jumlah Beli", "BeliQty", 1, 99, 10,
    function(v) jumlahBeli=v end, "Per transaksi")

BibitLeft:Button("Beli Sekarang", "Beli bibit yang dipilih",
    function()
        task.spawn(function()
            local ok,msg = beliBibit(selectedBibit, jumlahBeli)
            notif(ok and "Beli OK" or "Gagal", msg, 4)
        end)
    end)

BibitLeft:Button("Ambil Bibit (GetBibit)", "FireServer(0, false)",
    function() ambilBibit() end)

BibitLeft:Toggle("Auto Beli Bibit", "AutoBeliToggle", false,
    "Beli otomatis saat stok kurang",
    function(v) _G.AutoBeliBibit=v; notif("Auto Beli",v and "ON" or "OFF",2) end)

BibitLeft:Button("Cek Stok Bibit", "Lihat stok di toko",
    function()
        task.spawn(function()
            local ok,res = invokeRF("RequestShop","GET_LIST")
            if not ok then notif("Gagal","RequestShop error",3); return end
            local data = unwrap(res)
            if not data or not data.Seeds then notif("Gagal","Data kosong",3); return end
            PlayerData.Coins = data.Coins or PlayerData.Coins
            local txt = "Koin: "..tostring(data.Coins).."\n\n"
            for _,s in ipairs(data.Seeds) do
                txt = txt..(s.Locked and "[KUNCI] " or "[OK] ")
                    ..s.Name.."  x"..s.Owned.."  ("..s.Price..")\n"
            end
            notif("Toko Bibit", txt, 12)
        end)
    end)

for _, b in ipairs(BIBIT_LIST) do
    local bb = b
    BibitRight:Button(bb.icon.." "..bb.name, "Harga "..bb.price.." | Lv "..bb.minLv,
        function()
            task.spawn(function()
                selectedBibit = bb.name
                local ok,msg = beliBibit(bb.name, jumlahBeli)
                notif(ok and "Beli OK" or "Gagal", msg, 3)
            end)
        end)
end

-- ════════════════════════════════════════
--  TAB HARVEST
-- ════════════════════════════════════════
local HarvPage  = TabHarvest:Page("Harvest & Tanam", "scissors")
local HarvLeft  = HarvPage:Section("Harvest", "Left")
local HarvRight = HarvPage:Section("Tanam", "Right")

-- Pilih semua atau satu
HarvLeft:Toggle("Harvest Semua", "HarvAllToggle", true,
    "ON=semua tanaman | OFF=pilih satu",
    function(v) harvestAll=v end)

HarvLeft:Dropdown("Pilih Tanaman", "CropDrop", cropNames,
    function(val)
        -- strip icon, ambil nama
        for _, c in ipairs(CROP_LIST) do
            if val:find(c.name) then selectedCrop=c.name; break end
        end
        notif("Tanaman", selectedCrop.." dipilih", 2)
    end,
    "Aktif saat Harvest Semua OFF")

HarvLeft:Button("Harvest Sekarang", "Panen tanaman",
    function()
        task.spawn(function()
            if harvestAll then
                local c = harvestAll()
                notif("Harvest", c.." tanaman dipanen", 3)
            else
                -- cari crop yang dipilih
                for _, c in ipairs(CROP_LIST) do
                    if c.name == selectedCrop then
                        harvestCrop(c.name, c.idx)
                        notif("Harvest", selectedCrop.." dipanen", 3)
                        break
                    end
                end
            end
        end)
    end)

HarvLeft:Toggle("Auto Harvest (10s)", "AutoHarvToggle", false,
    "Harvest otomatis tiap 10 detik",
    function(v)
        _G.AutoHarvest = v
        if v then
            HarvestLoop = task.spawn(function()
                while _G.AutoHarvest do
                    if harvestAll then
                        harvestAll()
                    else
                        for _, c in ipairs(CROP_LIST) do
                            if c.name == selectedCrop then
                                harvestCrop(c.name, c.idx); break
                            end
                        end
                    end
                    task.wait(10)
                end
            end)
            notif("Auto Harvest", "ON", 3)
        else
            if HarvestLoop then
                pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil
            end
            notif("Auto Harvest", "OFF | Total: "..harvestCount, 3)
        end
    end)

HarvRight:Button("Tanam Semua Plot", "PlantCrop loop Vector3",
    function()
        task.spawn(function()
            local c = plantAllPlots()
            notif("Plant", c.." plot ditanam", 3)
        end)
    end)

HarvRight:Button("Refresh Cache Plot", "Scan ulang semua AreaTanam",
    function()
        plotCache = nil
        local plots = scanPlots()
        notif("Cache", #plots.." plot di-cache", 3)
    end)

HarvRight:Paragraph("Info Plot",
    "Scan otomatis:\nAreaTanam\nAreaTanam3-7\nAreaTanamBesar1-29\n\nPlantCrop:FireServer(Vector3)\nloop per BasePart")

-- ════════════════════════════════════════
--  TAB JUAL
-- ════════════════════════════════════════
local JualPage  = TabJual:Page("Jual Hasil Panen", "coins")
local JualLeft  = JualPage:Section("Jual Semua", "Left")
local JualRight = JualPage:Section("Jual Per Item", "Right")

JualLeft:Button("Jual Semua Sekarang", "Jual semua item di inventori",
    function()
        task.spawn(function()
            local ok,msg = jualSemua()
            notif(ok and "Jual OK" or "Gagal", msg, 4)
        end)
    end)

JualLeft:Button("SellCrop Langsung", "FireServer SellCrop",
    function() fireEv("SellCrop"); notif("SellCrop","Dikirim",2) end)

JualLeft:Toggle("Auto Sell (30s)", "AutoSellToggle", false,
    "Jual otomatis tiap 30 detik",
    function(v)
        _G.AutoSell = v
        if v then
            SellLoop = task.spawn(function()
                while _G.AutoSell do
                    local ok,msg = jualSemua()
                    notif(ok and "Auto Sell OK" or "Gagal", msg, 3)
                    task.wait(30)
                end
            end)
            notif("Auto Sell", "ON", 3)
        else
            if SellLoop then pcall(function() task.cancel(SellLoop) end); SellLoop=nil end
            notif("Auto Sell", "OFF", 2)
        end
    end)

JualLeft:Button("Lihat Inventory", "Cek semua item",
    function()
        task.spawn(function()
            local data = getInventory()
            if not data then notif("Gagal","Tidak ada response",4); return end
            local items = data.Items
            if not items or #items==0 then
                notif("Inventory Kosong","Koin: "..tostring(data.Coins),5); return
            end
            local txt = "Koin: "..tostring(data.Coins).."\n\n"
            for _, item in ipairs(items) do
                local owned = item.Owned or 0
                txt = txt..(owned>0 and "[ADA] " or "[  ] ")
                    ..item.Name.."  x"..owned.."  ("..item.Price..")\n"
            end
            notif("Inventory", txt, 12)
        end)
    end)

for _, item in ipairs(ITEM_LIST) do
    local it = item
    JualRight:Button(it.icon.." Jual "..it.name, it.price.." koin per item",
        function()
            task.spawn(function()
                local data = getInventory()
                local owned = 0
                if data and data.Items then
                    for _, i in ipairs(data.Items) do
                        if i.Name==it.name then owned=i.Owned or 0; break end
                    end
                end
                if owned==0 then notif(it.name,"Stok kosong",3); return end
                local ok,msg,earned = jualItem(it.name, owned)
                notif(ok and "Jual OK" or "Gagal",
                    it.name.." x"..owned..(ok and " | +"..earned or " | "..msg), 4)
            end)
        end)
end

-- ════════════════════════════════════════
--  TAB ESP
-- ════════════════════════════════════════
local ESPPage  = TabESP:Page("ESP Tanaman", "eye")
local ESPLeft  = ESPPage:Section("Control", "Left")
local ESPRight = ESPPage:Section("Info", "Right")

ESPLeft:Toggle("ESP Tanaman", "ESPToggle", false,
    "Label nama + % pertumbuhan di atas tanaman",
    function(v)
        _G.ESPTanaman = v
        if v then startESP() else stopESP() end
        notif("ESP", v and "ON" or "OFF", 2)
    end)

ESPLeft:Button("Scan Ulang", "Cari tanaman baru",
    function()
        if _G.ESPTanaman then
            lastESPScan = 0; scanESP()
        else notif("ESP","Aktifkan dulu!",2) end
    end)

ESPLeft:Button("Hapus Semua Label", "Bersihkan ESP",
    function() clearESP(); notif("ESP","Dibersihkan",2) end)

ESPLeft:Button("Reset Size Tracker", "Reset data min/max ukuran tanaman",
    function() sizeTracker={}; notif("ESP","Size tracker di-reset",2) end)

ESPRight:Paragraph("Cara Kerja",
    "Scan workspace cari:\nPadi, Jagung, Tomat\nTerong, Strawberry\nSawit, Durian\n\nLabel tampil:\nNama Tanaman\n% Pertumbuhan\n\nWarna:\nMerah = baru tanam\nKuning = setengah\nHijau = siap panen\n\nUpdate real-time\nRescan tiap 10 detik")

-- ════════════════════════════════════════
--  TAB MOVEMENT
-- ════════════════════════════════════════
local MovePage  = TabMove:Page("Speed & Fly", "zap")
local MoveLeft  = MovePage:Section("Speed & Jump", "Left")
local MoveRight = MovePage:Section("Fly & NoClip", "Right")

MoveLeft:Slider("Walk Speed","WSSlider",1,500,16,
    function(v) curWS=v; local h=getHum(); if h then h.WalkSpeed=v end end,
    "Default 16")

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

MoveRight:Slider("Sensitivitas Pitch","PitchSens",1,9,3,
    function(v) PITCH_UP=v*0.1; PITCH_DOWN=-v*0.1 end,"Naik/turun kamera")

MoveRight:Toggle("NoClip","NoclipToggle",false,"Tembus semua dinding",
    function(v) setNoclip(v); notif("NoClip",v and "ON" or "OFF",2) end)

MoveRight:Paragraph("Cara Fly",
    "Joystick = arah\nKamera atas = naik\nKamera bawah = turun\nLepas = melayang")

-- ════════════════════════════════════════
--  TAB PROTECTION
-- ════════════════════════════════════════
local ProtPage  = TabProt:Page("Protection", "shield")
local ProtLeft  = ProtPage:Section("Anti AFK & Kick", "Left")
local ProtRight = ProtPage:Section("Info", "Right")

ProtLeft:Toggle("Anti AFK","AntiAFKToggle",false,
    "Jump kecil tiap 2 menit",
    function(v)
        _G.AntiAFK=v
        if v then startAntiAFK() end
        notif("Anti AFK",v and "ON" or "OFF",3)
    end)

ProtLeft:Toggle("Anti Kick","AntiKickToggle",false,
    "HP dikunci saat hampir mati",
    function(v)
        _G.AntiKick=v
        if v then startAntiKick() end
        notif("Anti Kick",v and "ON — HP terkunci" or "OFF",3)
    end)

ProtLeft:Toggle("Auto Mandi","AutoMandiToggle",false,
    "TP mandi saat notif kotor",
    function(v) _G.AutoMandi=v; notif("Auto Mandi",v and "ON" or "OFF",2) end)

ProtLeft:Button("Rejoin Server","Koneksi ulang",
    function()
        notif("Rejoin","Menghubungkan ulang...",3)
        task.wait(1); TpService:Teleport(game.PlaceId, LP)
    end)

ProtLeft:Button("Posisi Saya","Lihat koordinat",
    function()
        local pos = getPos()
        if pos then
            notif("Posisi",
                string.format("X=%.1f\nY=%.1f\nZ=%.1f",pos.X,pos.Y,pos.Z),6)
            print(string.format("[ XKID ] X=%.4f Y=%.4f Z=%.4f",pos.X,pos.Y,pos.Z))
        end
    end)

ProtRight:Paragraph("Anti AFK","Jump tiap 120 detik\nCegah auto disconnect")
ProtRight:Paragraph("Anti Kick","HP dipantau tiap frame\nHP < 15% = langsung penuh")

-- ════════════════════════════════════════
--  TAB TELEPORT
-- ════════════════════════════════════════
local TpPage  = TabTP:Page("Teleport", "map-pin")
local TpLeft  = TpPage:Section("NPC", "Left")
local TpRight = TpPage:Section("TP ke Player", "Right")

-- NPC via ProximityPrompt path
TpLeft:Label("Teleport ke NPC")
for _, npc in ipairs(NPC_LIST) do
    local n = npc
    TpLeft:Button("TP: "..n.label, "workspace."..table.concat(n.path,"."),
        function() tpToNPC(n.label, n.path) end)
end

TpLeft:Button("TP ke Area Mandi","X=137 Z=-235", goMandi)

-- TP ke Player
TpRight:Label("Teleport ke Player Online")

TpRight:Button("Lihat Player Online","Daftar semua player di server",
    function()
        local list, n = "", 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                n = n + 1
                list = list.."• "..p.Name.." ("..p.DisplayName..")\n"
            end
        end
        notif(n.." Player Online", n>0 and list or "Tidak ada player lain", 10)
    end)

local tpInput = ""
TpRight:TextBox("Nama / Prefix Player","TPInput","",
    function(v) tpInput=v end,
    "Ketik 1-2 huruf pertama nama")

TpRight:Button("Teleport ke Player","Cari dan TP otomatis",
    function() tpToPlayer(tpInput) end)

TpRight:Paragraph("Cara Pakai",
    "1. Klik Lihat Player Online\n2. Ketik 1-2 huruf nama\n3. Klik Teleport\n\nContoh: ada 'XKIDTest'\nKetik 'XK' → langsung TP!")

-- ════════════════════════════════════════
--  TAB PETIR
-- ════════════════════════════════════════
local PetirPage  = TabPetir:Page("Penangkal Petir", "cloud-lightning")
local PetirLeft  = PetirPage:Section("Perlindungan", "Left")
local PetirRight = PetirPage:Section("Info", "Right")

PetirLeft:Toggle("Penangkal Petir","PetirToggle",false,
    "TP ke SafeZone instan saat petir",
    function(v)
        _G.PenangkalPetir=v
        notif("Penangkal Petir",v and "ON — SafeZone aktif" or "OFF",3)
    end)

PetirLeft:Button("Test Flee","Simulasi kabur petir",
    function()
        if not getRoot() then notif("Gagal","Karakter tidak ada",3); return end
        task.spawn(fleePetir)
    end)

PetirLeft:Button("Reset Counter","Reset hitungan kena petir",
    function() lightningHits=0; notif("Reset","Counter petir di-reset",2) end)

PetirRight:Paragraph("Cara Kerja",
    "Intercept:\nLightningStrike.OnClientEvent\n\nTrigger: data.Hit == true\n\nAksi:\n1. HP langsung penuh\n2. HP dikunci 6 detik\n3. TP ke SafeZone acak\n   (SafeZone1-12)\n4. Tunggu 4 detik\n5. Kembali ke posisi\n\nFallback: naik awan Y+300")

PetirRight:Paragraph("SafeZone","workspace.SafeZone1\nworkspace.SafeZone2\n...\nworkspace.SafeZone12\nDipilih acak saat petir")

-- ════════════════════════════════════════
--  TAB SETTING
-- ════════════════════════════════════════
local SetPage  = TabSet:Page("Setting", "settings")
local SetLeft  = SetPage:Section("Umum", "Left")
local SetRight = SetPage:Section("Stats", "Right")

SetLeft:Toggle("Notif Level Up","NLvUpToggle",true,
    "Tampilkan notif saat level naik",
    function(v) _G.NotifLevelUp=v end)

SetLeft:Toggle("Auto Confirm","AutoConfirmToggle",false,
    "Auto klik konfirmasi dialog",
    function(v) _G.AutoConfirm=v; notif("Auto Confirm",v and "ON" or "OFF",2) end)

SetLeft:Slider("Min Stok Bibit","MinStokSlider",1,50,5,
    function(v) minStok=v end,"Beli kalau stok di bawah ini")

SetLeft:Button("STOP SEMUA","Matikan semua fitur",stopSemua)

SetLeft:Button("Reset Stats","Reset semua hitungan",
    function()
        totalEarned=0; harvestCount=0; levelUpCount=0
        lightningHits=0; plantCount=0
        notif("Reset","Stats di-reset",2)
    end)

SetRight:Button("Lihat Stats","Total plant, harvest, koin, petir",
    function()
        notif("Stats Sesi",
            "Plant: "..plantCount.."\n"..
            "Harvest: "..harvestCount.."\n"..
            "Koin: "..totalEarned.."\n"..
            "Level Up: "..levelUpCount.."\n"..
            "Petir: "..lightningHits, 10)
    end)

SetRight:Paragraph("Indo Farmer v24",
    "XKID HUB — Aurora UI\n\nv24 Fix:\nVector3 plant loop\nfiresignal harvest\nESP size tracker\nSafeZone petir flee\nNPC ProximityPrompt\nTP ke Player")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
task.spawn(function()
    task.wait(2)
    scanPlots()
    getSafeZones()
end)

setupIntercepts()

Library:Notification("Indo Farmer v24",
    "Welcome "..LP.Name.."!\nESP Growth · SafeZone · Fixed Harvest", 6)
Library:ConfigSystem(Win)

print("[ XKID ] Indo Farmer v24.0 loaded — "..LP.Name)
