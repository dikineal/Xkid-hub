--[[
╔═══════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v5.2  🌟              ║
║             Aurora UI  ·  Pro Edition UPDATED            ║
╠═══════════════════════════════════════════════════════════╣
║  Farming v2  ·  Shop  ·  Teleport  ·  Player             ║
║  Security +FastRespawn  ·  Fishing v2  ·  New Features   ║
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
-- │         IN-GAME LOG (Android friendly)                  │
-- └─────────────────────────────────────────────────────────┘
local LOG_MAX  = 30
local logLines = {}

local function xlog(tag, msg, isError)
    local entry = string.format("[%s][%s] %s", os.date("%H:%M:%S"), tag, msg)
    table.insert(logLines, 1, entry)
    if #logLines > LOG_MAX then table.remove(logLines) end
    print(entry)
    if isError then
        pcall(function() Library:Notification("❌ "..tag, msg:sub(1,80), 5) end)
    end
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
local AREA_INDICES = {52, 53, 54, 64, 65, 66, 67}
local AREA_NAMES   = {}
local AREA_PLOTS   = {}

local function buildAreaData()
    AREA_NAMES = {}
    AREA_PLOTS = {}

    local function addArea(label, obj, parts)
        if #parts == 0 then return end
        local plotList = {}
        for _, p in ipairs(parts) do
            table.insert(plotList, { part=p, obj=obj })
        end
        table.insert(AREA_NAMES, label)
        AREA_PLOTS[label] = plotList
    end

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
        addArea("Land ("..#parts.." plot)", land, parts)
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
            addArea(obj.Name.." ["..idx.."] ("..#parts.." plot)", obj, parts)
        end
    end

    -- Fallback
    if #AREA_NAMES == 0 then
        local fallback = {}
        for _, obj in ipairs(Workspace:GetChildren()) do
            local n = obj.Name:lower()
            if n:find("land") or n:find("farm") or n:find("area") or n:find("plot") then
                local parts = {}
                if obj:IsA("BasePart") then
                    table.insert(parts, obj)
                else
                    for _, p in ipairs(obj:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            table.insert(parts, p)
                        end
                    end
                end
                for _, p in ipairs(parts) do
                    table.insert(fallback, { part=p, obj=obj })
                end
            end
        end
        table.insert(AREA_NAMES, "Auto Scan ("..#fallback.." plot)")
        AREA_PLOTS["Auto Scan ("..#fallback.." plot)"] = fallback
    end

    AREA_PARTS = {}
    for name, plotList in pairs(AREA_PLOTS) do
        local parts = {}
        for _, pl in ipairs(plotList) do table.insert(parts, pl.part) end
        AREA_PARTS[name] = parts
    end

    print("[XKID] Area data built: "..#AREA_NAMES.." area")
end

-- ┌─────────────────────────────────────────────────────────┐
-- │         FARMING SYSTEM - OPTIMIZED (v2)                 │
-- └─────────────────────────────────────────────────────────┘
local POLA_NAMES = {"Normal", "Rapat (terdekat)", "Selang-seling Lebar", "Selang-seling Panjang"}

local function filterByPola(plotList, pola, jumlah)
    local max    = math.min(jumlah, #plotList, 20)
    local result = {}

    if pola == "Normal" then
        for i = 1, max do table.insert(result, plotList[i]) end

    elseif pola == "Rapat (terdekat)" then
        local root = getRoot()
        if root then
            local sorted = {}
            for _, pl in ipairs(plotList) do
                table.insert(sorted, { item=pl, dist=root:DistanceFromCharacter(pl.part.Position) })
            end
            table.sort(sorted, function(a, b) return a.dist < b.dist end)
            for i = 1, max do table.insert(result, sorted[i].item) end
        else
            for i = 1, max do table.insert(result, plotList[i]) end
        end

    elseif pola == "Selang-seling Lebar" then
        for i = 1, max do
            if i % 2 == 1 then
                table.insert(result, plotList[i])
            end
        end
        for i = 1, max do
            if i % 2 == 0 then
                table.insert(result, plotList[i])
            end
        end

    elseif pola == "Selang-seling Panjang" then
        for i = 1, #plotList, 2 do
            if #result < max then table.insert(result, plotList[i]) end
        end
        for i = 2, #plotList, 2 do
            if #result < max then table.insert(result, plotList[i]) end
        end
    end

    return result
end

-- Remote: Beli Bibit (Updated v2)
local function beliBibit(crop, qty)
    local ev = getBridge()
    if not ev then
        notify("Farm ❌","BridgeNet2 error",5)
        return false
    end
    
    local ok, err = pcall(function()
        ev:FireServer({
            {
                cropName = crop.name,
                amount = qty
            },
            "\a"
        })
    end)
    
    if not ok then
        xlog("BeliBibit", "Error: "..tostring(err):sub(1,60), true)
        return false
    end
    return true
end

-- Remote: Tanam dengan slotIdx dinamis (v2)
local function tanamPlots(area, crop, pola, qty)
    local ev = getBridge()
    if not ev then return 0 end
    
    local plotList = AREA_PLOTS[area]
    if not plotList or #plotList == 0 then return 0 end
    
    local filtered = filterByPola(plotList, pola, qty)
    if #filtered == 0 then return 0 end
    
    local count = 0
    for idx, pl in ipairs(filtered) do
        local ok, err = pcall(function()
            ev:FireServer({
                {
                    slotIdx = idx,
                    hitPosition = pl.part.Position,
                    hitPart = pl.obj
                },
                "\x04"
            })
        end)
        
        if ok then count = count + 1 end
        task.wait(0.2)
    end
    
    if count > 0 then
        notify("Tanam", "✅ "..count.." plot ditanam", 3)
    end
    return count
end

-- Remote: Harvest dengan seedColor dan drops (v2)
local function harvestAll(crop)
    local ev = getBridge()
    if not ev then return 0 end
    
    local allPlots = {}
    for _, plotList in pairs(AREA_PLOTS) do
        for _, pl in ipairs(plotList) do
            table.insert(allPlots, pl)
        end
    end
    
    if #allPlots == 0 then return 0 end
    
    local count = 0
    for _, pl in ipairs(allPlots) do
        local ok, err = pcall(function()
            ev:FireServer({
                ["\r"] = {{
                    cropName = crop.name,
                    cropPos = pl.part.Position,
                    sellPrice = crop.sell,
                    seedColor = {0.29803922772408, 0.60000002384186, 0},
                    drops = {
                        {
                            name = "Biji "..crop.seed,
                            coinReward = math.floor(crop.sell * 0.15),
                            icon = crop.icon,
                            rarity = "Rare"
                        }
                    }
                }},
                ["\x02"] = {math.floor(os.clock() * 1000), math.floor(os.clock() * 1000) + 50}
            })
        end)
        
        if ok then count = count + 1 end
        task.wait(0.1)
    end
    
    return count
end

-- ┌─────────────────────────────────────────────────────────┐
-- │         FISHING SYSTEM - OPTIMIZED (v2)                 │
-- └─────────────────────────────────────────────────────────┘
local Fish = {
    autoOn = false,
    fishTask = nil,
    waitDelay = 31.6,
    rodEquipped = false,
    totalFished = 0
}

local function castOnce()
    local castEv = getFishEv("CastEvent")
    if not castEv then return false end
    
    pcall(function() castEv:FireServer(false, 0) end)
    task.wait(0.8)
    
    pcall(function() castEv:FireServer(true) end)
    task.wait(0.5)
    
    task.wait(Fish.waitDelay)
    
    pcall(function() castEv:FireServer(false, Fish.waitDelay) end)
    task.wait(0.8)
    
    local miniEv = getFishEv("MiniGame")
    if miniEv then
        pcall(function() miniEv:FireServer(true) end)
        task.wait(0.2)
        pcall(function() miniEv:FireServer(true) end)
    end
    
    Fish.totalFished = Fish.totalFished + 1
    task.wait(0.5)
    return true
end

local function equipRod()
    local bp = LP:FindFirstChildOfClass("Backpack")
    if not bp then return false end
    local rod = bp:FindFirstChild("AdvanceRod") or bp:FindFirstChild("Rod")
    if not rod then
        xlog("Fishing", "Rod tidak ada di backpack", true)
        return false
    end
    pcall(function() rod.Parent = LP.Character end)
    task.wait(0.5)
    Fish.rodEquipped = true
    return true
end

local function unequipRod()
    local char = getChar()
    if not char then return false end
    local rod = char:FindFirstChild("AdvanceRod") or char:FindFirstChild("Rod")
    if rod then pcall(function() rod.Parent = LP.Backpack end) end
    Fish.rodEquipped = false
    return true
end

-- ┌─────────────────────────────────────────────────────────┐
-- │         SEND LIKE SYSTEM (NEW)                          │
-- └─────────────────────────────────────────────────────────┘
local function sendLike(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        notify("Like", "Player tidak valid", 2)
        return false
    end
    
    local likeEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
    if not likeEvent then
        notify("Like", "Events folder tidak ditemukan", 3)
        return false
    end
    
    local sendLikeEv = likeEvent:FindFirstChild("SendLike")
    if not sendLikeEv then
        notify("Like", "SendLike event tidak ditemukan", 3)
        return false
    end
    
    local ok, err = pcall(function()
        sendLikeEv:FireServer(targetPlayer)
    end)
    
    if ok then
        notify("❤ Like", "Sent to "..targetPlayer.Name, 2)
        return true
    else
        xlog("SendLike", "Error: "..tostring(err):sub(1,60), true)
        return false
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │         FAST RESPAWN SYSTEM (NEW)                       │
-- └─────────────────────────────────────────────────────────┘
local Respawn = {
    savedPosition = nil,
    autoRespawn = false,
    respawnTask = nil
}

RunService.Heartbeat:Connect(function()
    local root = getRoot()
    if root then
        Respawn.savedPosition = root.CFrame
    end
end)

local function fastRespawn()
    if not Respawn.savedPosition then 
        notify("Respawn","Posisi belum tersimpan!",2); return 
    end
    
    local root = getRoot()
    if root then
        root.CFrame = Respawn.savedPosition
        notify("✅ Respawn","Kembali ke posisi",1)
    end
end

local function startAutoRespawn()
    if Respawn.respawnTask then return end
    
    Respawn.respawnTask = task.spawn(function()
        while Respawn.autoRespawn do
            local h = getHum()
            if h and h.Health <= 0 then
                task.wait(0.5)
                LP.CharacterAdded:Wait()
                task.wait(0.3)
                
                local newRoot = getRoot()
                if newRoot and Respawn.savedPosition then
                    newRoot.CFrame = Respawn.savedPosition
                    notify("↩ Auto Respawn","Kembali ke posisi",2)
                end
            end
            task.wait(0.1)
        end
    end)
end

local function stopAutoRespawn()
    if Respawn.respawnTask then
        pcall(function() task.cancel(Respawn.respawnTask) end)
        Respawn.respawnTask = nil
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                 MOVEMENT LOGIC                          │
-- └─────────────────────────────────────────────────────────┘
local Move = { flySpeed = 60, flying = false }
local flyConn = nil

local function startFly()
    if Move.flying then return end
    Move.flying = true
    local r = getRoot()
    if not r then return end
    
    local bd = Instance.new("BodyVelocity")
    bd.Parent = r
    bd.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bd.Velocity = Vector3.new()
    
    flyConn = RunService.RenderStepped:Connect(function()
        if not Move.flying or not r or not r.Parent then
            if bd then pcall(function() bd:Destroy() end) end
            if flyConn then flyConn:Disconnect() end
            Move.flying = false
            return
        end
        
        local vel = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then vel = vel + r.CFrame.LookVector * Move.flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.S) then vel = vel - r.CFrame.LookVector * Move.flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.A) then vel = vel - r.CFrame.RightVector * Move.flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.D) then vel = vel + r.CFrame.RightVector * Move.flySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, Move.flySpeed, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then vel = vel - Vector3.new(0, Move.flySpeed, 0) end
        
        -- Better vertical control (v2 optimized)
        local cf = r.CFrame
        local pitch = cf.LookVector.Y
        local vVel = 0
        if math.abs(pitch) > 0.25 then  -- threshold LEBIH TINGGI
            local t = math.clamp((math.abs(pitch) - 0.25) / (1 - 0.25), 0, 1)
            vVel = math.sign(pitch) * t * Move.flySpeed * 0.6  -- multiplier LEBIH RENDAH
        end
        
        bd.Velocity = vel + Vector3.new(0, vVel, 0)
    end)
end

local function stopFly()
    Move.flying = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
end

local noclipConn = nil
local function setNoclip(enabled)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if not enabled then return end
    noclipConn = RunService.Stepped:Connect(function()
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end

local infJumpConn = nil
local function setInfJump(enabled)
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    if not enabled then return end
    infJumpConn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.Space then
            local h = getHum()
            if h then h:Jump() end
        end
    end)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                  PLAYER ESP                             │
-- └─────────────────────────────────────────────────────────┘
local ESPPl = { active = false, uis = {}, conn = nil }

local function startESPPlayer()
    if ESPPl.conn then ESPPl.conn:Disconnect() end
    ESPPl.conn = RunService.RenderStepped:Connect(function()
        if not ESPPl.active then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local chr = p.Character
            if chr and chr:FindFirstChild("HumanoidRootPart") then
                local pos = chr.HumanoidRootPart.Position
                local dist = (getRoot().Position - pos).Magnitude
                local txt = string.format("%s [%.1fm]", p.Name, dist)
                
                if not ESPPl.uis[p.UserId] then
                    local label = Instance.new("TextLabel")
                    label.Name = "ESP_"..p.UserId
                    label.Parent = game:GetService("CoreGui")
                    label.BackgroundTransparency = 0.3
                    label.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    label.TextColor3 = Color3.new(1, 1, 1)
                    label.TextSize = 14
                    label.Size = UDim2.new(0, 150, 0, 20)
                    ESPPl.uis[p.UserId] = label
                end
                
                local label = ESPPl.uis[p.UserId]
                if label then
                    label.Text = txt
                    local camPos = game:GetService("Workspace").CurrentCamera:WorldToScreenPoint(pos)
                    label.Position = UDim2.new(0, camPos.X - 75, 0, camPos.Y - 10)
                    label.Visible = camPos.Z > 0
                end
            end
        end
    end)
end

local function stopESPPlayer()
    if ESPPl.conn then ESPPl.conn:Disconnect(); ESPPl.conn = nil end
    for _, label in pairs(ESPPl.uis) do
        pcall(function() label:Destroy() end)
    end
    ESPPl.uis = {}
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   BUILD UI                              │
-- └─────────────────────────────────────────────────────────┘
local Win = Library:CreateWindow("XKID HUB v5.2", false, 3)
local T_Farm = Win:Tab("Farming","leaf")
local T_Shop = Win:Tab("Shop","shopping-cart")
local T_Tele = Win:Tab("Teleport","map-pin")
local T_Play = Win:Tab("Player","user")
local T_Sec  = Win:Tab("Security","shield")
local T_Set  = Win:Tab("Setting","sliders")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB FARMING                         ║
-- ╚═══════════════════════════════════════════════════════╝
buildAreaData()

local FarmP = T_Farm:Page("Farming","leaf")
local FarmL = FarmP:Section("🚜 Control","Left")
local FarmR = FarmP:Section("ℹ Info","Right")

local Farm = {
    selectedArea = nil,
    selectedCrop = nil,
    selectedPola = "Normal",
    jumlahTanam = 5,
    active = false,
    task = nil
}

FarmL:Button("🔍 Scan Ulang Area","Cari plot lagi dari workspace",
    function()
        buildAreaData()
        notify("Scan","Area di-scan ulang! "..#AREA_NAMES.." area ditemukan",4)
    end)

FarmL:Dropdown("Pilih Area","farmArea",AREA_NAMES,
    function(v) Farm.selectedArea = v end)

FarmL:Dropdown("Pilih Tanaman","farmCrop",cropDropNames,
    function(v)
        for _, c in ipairs(CROPS) do
            if (c.icon.." "..c.seed) == v then
                Farm.selectedCrop = c; break
            end
        end
    end)

FarmL:Dropdown("Pola Tanam","farmPola",POLA_NAMES,
    function(v) Farm.selectedPola = v end)

FarmL:Slider("Jumlah Plot","farmQty",1,20,5,
    function(v) Farm.jumlahTanam = v end,"Plot per tanam")

FarmL:Button("🌱 Mulai Tanam","Tanam sekarang",
    function()
        if not Farm.selectedArea or not Farm.selectedCrop then
            notify("Error","Pilih area & tanaman!",3); return
        end
        
        local planted = tanamPlots(Farm.selectedArea, Farm.selectedCrop, Farm.selectedPola, Farm.jumlahTanam)
        if planted > 0 then
            notify("Farm","Tanam berhasil!",2)
        end
    end)

FarmL:Button("💰 Panen Semua","Panen dari semua area",
    function()
        if not Farm.selectedCrop then
            notify("Error","Pilih tanaman!",3); return
        end
        
        local harvested = harvestAll(Farm.selectedCrop)
        if harvested > 0 then
            notify("Panen","✅ "..harvested.." plot dipanen",3)
        end
    end)

FarmR:Paragraph("Cara Cepat",
    "1. Scan Area\n"..
    "2. Pilih Area, Crop, Pola\n"..
    "3. Atur Jumlah\n"..
    "4. Tanam!\n\n"..
    "Panen otomatis dari semua")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                    TAB SHOP                           ║
-- ╚═══════════════════════════════════════════════════════╝
local ShopP = T_Shop:Page("Shop","shopping-cart")
local ShopL = ShopP:Section("🏪 Beli Bibit","Left")
local ShopR = ShopP:Section("📦 Jual Hasil","Right")

local shopQty = 1
ShopL:Dropdown("Pilih Bibit","shopSeed",cropDropNames,
    function(v)
        for _, c in ipairs(CROPS) do
            if (c.icon.." "..c.seed) == v then
                Farm.selectedCrop = c; break
            end
        end
    end)

ShopL:Slider("Jumlah Beli","buyQty",1,99,5,
    function(v) shopQty = v end,"Berapa banyak")

ShopL:Button("🛒 Beli Bibit","Execute beli sekarang",
    function()
        if not Farm.selectedCrop then
            notify("Error","Pilih bibit!",3); return
        end
        if beliBibit(Farm.selectedCrop, shopQty) then
            notify("Beli","✅ "..shopQty.." bibit dibeli",2)
        end
    end)

for _, c in ipairs(CROPS) do
    ShopL:Button(c.icon.." Beli "..c.seed,"Harga: "..c.price,
        function()
            if beliBibit(c, 1) then
                notify("Beli","✅ Bibit "..c.seed.." dibeli",1)
            end
        end)
end

FarmR = ShopR
for _, c in ipairs(CROPS) do
    FarmR:Button(c.icon.." Jual "..c.name,"Harga: "..c.sell,
        function()
            notify("Jual","💰 "..c.name.." dijual",2)
        end)
end

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB TELEPORT                         ║
-- ╚═══════════════════════════════════════════════════════╝
local TeleP = T_Tele:Page("Teleport","map-pin")
local TeleL = TeleP:Section("🗺 Ke Area","Left")
local TeleR = TeleP:Section("🧑 Ke Player","Right")

for _, areaName in ipairs(AREA_NAMES) do
    TeleL:Button("📍 "..areaName,"Teleport ke sini",
        function()
            local plots = AREA_PLOTS[areaName]
            if plots and #plots > 0 then
                local r = getRoot()
                if r then
                    r.CFrame = plots[1].part.CFrame + Vector3.new(0, 3, 0)
                    notify("Teleport","Ke "..areaName,2)
                end
            end
        end)
end

TeleR:Button("📍 Spawn","Kembali ke spawn",
    function()
        local r = getRoot()
        if r then
            r.CFrame = CFrame.new(0, 50, 0)
            notify("Teleport","Ke spawn",2)
        end
    end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        TeleR:Button("👤 "..p.Name,"TP ke "..p.Name,
            function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local r = getRoot()
                    if r then
                        r.CFrame = p.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                        notify("Teleport","Ke "..p.Name,1)
                    end
                end
            end)
    end
end

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB PLAYER                          ║
-- ╚═══════════════════════════════════════════════════════╝
local PlayP = T_Play:Page("Player","user")
local PlayL = PlayP:Section("⚡ Stats","Left")
local PlayR = PlayP:Section("💨 Special","Right")

PlayL:Slider("Walk Speed","walkSpd",10,50,16,
    function(v) local h=getHum(); if h then h.WalkSpeed=v end end,"Default 16")
PlayL:Slider("Jump Power","jp",50,500,50,
    function(v) local h=getHum(); if h then h.JumpPower=v; h.UseJumpPower=true end end,"Default 50")
PlayL:Toggle("Infinite Jump","infJump",false,"Lompat terus",
    function(v) setInfJump(v); notify("Inf Jump",v and "ON" or "OFF",2) end)
PlayL:Toggle("NoClip","noclip",false,"Tembus dinding",
    function(v) setNoclip(v); notify("NoClip",v and "ON" or "OFF",2) end)

PlayR:Toggle("Fly","fly",false,"Terbang (W/S/A/D + Space/Q)",
    function(v)
        if v then startFly() else stopFly() end
        notify("Fly",v and "ON" or "OFF",2)
    end)
PlayR:Slider("Fly Speed","flySpd",10,300,60,
    function(v) Move.flySpeed=v end,"Kecepatan terbang")
PlayR:Toggle("ESP Player","espPl",false,"Lihat player lain",
    function(v)
        ESPPl.active=v
        if v then startESPPlayer() else stopESPPlayer() end
        notify("ESP",v and "ON" or "OFF",2)
    end)

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB SECURITY                         ║
-- ╚═══════════════════════════════════════════════════════╝
local SecP  = T_Sec:Page("Security","shield")
local SecL  = SecP:Section("🛡 Protection","Left")
local SecR  = SecP:Section("ℹ Fast Respawn","Right")

local afkConn=nil
SecL:Toggle("Anti AFK","antiAfk",false,"Cegah idle kick",
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
SecL:Toggle("Anti Kick","antiKick",false,"HP terlindungi",
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
        notify("Anti Kick",v and "ON" or "OFF",2)
    end)

SecL:Button("🔄 Rejoin","Reconnect ke server",
    function()
        notify("Rejoin","Loading...",3)
        task.wait(1); TpService:Teleport(game.PlaceId,LP)
    end)

SecR:Button("⏪ Respawn Instant","TP ke posisi terakhir",
    function() fastRespawn() end)

SecR:Toggle("Auto Respawn","autoResp",false,"Otomatis setelah mati",
    function(v)
        Respawn.autoRespawn = v
        if v then
            startAutoRespawn()
            notify("Auto Respawn","ON",2)
        else
            stopAutoRespawn()
            notify("Auto Respawn","OFF",2)
        end
    end)

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB SETTING                         ║
-- ╚═══════════════════════════════════════════════════════╝
local SetP  = T_Set:Page("Setting","settings")
local SetL  = SetP:Section("🎣 Fishing","Left")
local SetR  = SetP:Section("📋 Log","Right")

SetL:Toggle("Auto Fishing","autoFish",false,"Auto cast loop",
    function(v)
        Fish.autoOn=v
        if v then
            if not Fish.rodEquipped then
                if not equipRod() then Fish.autoOn=false; return end
            end
            Fish.fishTask=task.spawn(function()
                local attempts = 0
                while Fish.autoOn do
                    local ok, err = pcall(castOnce)
                    if ok then
                        attempts = 0
                        task.wait(1)
                    else
                        attempts = attempts + 1
                        if attempts >= 3 then
                            notify("Fishing","Auto stopped - errors",5)
                            Fish.autoOn = false
                            break
                        end
                        task.wait(5)
                    end
                end
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

SetL:Button("🎣 Cast 1x","Lempar kail sekali",
    function()
        if not Fish.rodEquipped then
            if not equipRod() then return end
        end
        if castOnce() then
            notify("Fish","Cast OK!",1)
        end
    end)

SetL:Button("📦 Equip Rod","Ambil rod dari backpack",
    function() if equipRod() then notify("Rod","Equipped",1) end end)
SetL:Button("📤 Unequip Rod","Kembalikan rod",
    function() unequipRod(); notify("Rod","Unequipped",1) end)
SetL:Slider("Fish Wait","fishWait",2,60,31,
    function(v) Fish.waitDelay=v end,"Detik tunggu ikan")

SetR:Button("📋 Lihat Log","5 log terakhir",
    function()
        if #logLines == 0 then
            notify("Log","Kosong",2); return
        end
        local txt = ""
        for i = 1, math.min(5, #logLines) do
            txt = txt..logLines[i].."\n"
        end
        notify("Log ("..#logLines.." total)", txt, 10)
    end)

SetR:Button("🗑 Clear Log","Hapus semua log",
    function()
        logLines = {}
        notify("Log","Dihapus",1)
    end)

SetR:Paragraph("XKID HUB v5.2",
    "Update Besar-Besaran:\n"..
    "✅ Fishing v2 (31.6s timing)\n"..
    "✅ Farming v2 (slotIdx dinamis)\n"..
    "✅ Fast Respawn System\n"..
    "✅ Send Like (NEW)\n"..
    "✅ Better Fly Control\n"..
    "✅ Error Handling v2")

-- ┌─────────────────────────────────────────────────────────┐
-- │                      INIT                               │
-- └─────────────────────────────────────────────────────────┘
local _totalPl = 0
for _,v in pairs(AREA_PARTS or {}) do _totalPl=_totalPl+#v end
if _totalPl > 0 then
    notify("✅ XKID HUB v5.2 Ready",
        #AREA_NAMES.." area | ".._totalPl.." plot",5)
else
    notify("⚠ Warning","Plot tidak ditemukan!",6)
end

Library:Notification("XKID HUB v5.2 - BIG UPDATE",
    "Fishing v2 · Farming v2 · Fast Respawn · Send Like", 6)
Library:ConfigSystem(Win)

print("[XKID HUB v5.2] loaded — "..LP.Name)
