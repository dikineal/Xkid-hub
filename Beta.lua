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
-- │         IN-GAME LOG (Android friendly)                  │
-- │  Tidak ada F9 — error tampil di notif + executor log   │
-- └─────────────────────────────────────────────────────────┘
local LOG_MAX  = 30
local logLines = {}

local function xlog(tag, msg, isError)
    local entry = string.format("[%s][%s] %s", os.date("%H:%M:%S"), tag, msg)
    table.insert(logLines, 1, entry)
    if #logLines > LOG_MAX then table.remove(logLines) end
    print(entry)  -- executor log (Delta/Arceus ada log viewer)
    if isError then
        pcall(function() Library:Notification("❌ "..tag, msg:sub(1,80), 5) end)
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                   CROP DATA                             │
-- └─────────────────────────────────────────────────────────┘
local CROPS = {
    { name="AppleTree", seed="Bibit Apel",      icon="🍎", price=15,       sell=45,       harvest=40  },
    { name="Sawi",      seed="Bibit Sawi",      icon="🥬", price=15,       sell=20,       harvest=92  },
    { name="Padi",      seed="Bibit Padi",      icon="🌾", price=15,       sell=20        },
    { name="Melon",     seed="Bibit Melon",     icon="🍈", price=15,       sell=20        },
    { name="Tomat",     seed="Bibit Tomat",     icon="🍅", price=15,       sell=20        },
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
-- Land positions dari event data terbaru
local LAND_DATA = {
    { name="Land1", pos=Vector3.new(23.97, 9.00, 0.18)   },
    { name="Land2", pos=Vector3.new(23.85, 9.36, 0.18)   },
    { name="Land3", pos=Vector3.new(23.86, 9.71, 0.18)   },
    { name="Land4", pos=Vector3.new(24.32, 9.71, 0.18)   },
    { name="Land5", pos=Vector3.new(33.31, 15.82, 40.51) },
    { name="Land6", pos=Vector3.new(23.88, 9.28, 0.18)   },
}
local AREA_INDICES = {52, 53, 54, 64, 65, 66, 67}
local AREA_NAMES   = {}
-- Simpan: { part=BasePart, obj=parentObject }
-- hitPart di spy log = object workspace langsung (index/Land)
local AREA_PLOTS   = {}  -- nama → list { part, obj }

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

    -- Compat: AREA_PARTS untuk harvestAll (pakai part saja)
    AREA_PARTS = {}
    for name, plotList in pairs(AREA_PLOTS) do
        local parts = {}
        for _, pl in ipairs(plotList) do table.insert(parts, pl.part) end
        AREA_PARTS[name] = parts
    end

    print("[XKID] Area data built: "..#AREA_NAMES.." area")
end

-- Pola tanam
local POLA_NAMES = {"Normal", "Rapat (terdekat)", "Selang-seling Lebar", "Selang-seling Panjang"}

local function filterByPola(plotList, pola, jumlah)
    -- plotList = list of { part=BasePart, obj=parentObj }
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

-- ┌─────────────────────────────────────────────────────────┐
-- │                    FARMING LOGIC                        │
-- └─────────────────────────────────────────────────────────┘
local Farm = {
    active = false, task = nil,
    selectedArea = nil, selectedCrop = nil,
    selectedPola = "Normal", selectedQty = 5
}

local function teleportToPart(part)
    if not part then return false end
    local r = getRoot()
    if r then
        r.CFrame = part.CFrame + Vector3.new(0, 3, 0)
        return true
    end
    return false
end

local function harvest(part)
    local bridge = getBridge()
    if not bridge then xlog("Harvest", "Bridge not found", true); return false end
    local ok, res = pcall(function()
        bridge:FireServer("Harvest", {part})
    end)
    if not ok then xlog("Harvest", "Error: "..tostring(res):sub(1,60), true); return false end
    return true
end

local function plant(part, cropName, seedName)
    local bridge = getBridge()
    if not bridge then xlog("Plant", "Bridge not found", true); return false end
    local ok, res = pcall(function()
        bridge:FireServer("Plant", {part, cropName, seedName})
    end)
    if not ok then xlog("Plant", "Error: "..tostring(res):sub(1,60), true); return false end
    return true
end

local function buySeed(seedName)
    local bridge = getBridge()
    if not bridge then xlog("Shop", "Bridge not found", true); return false end
    local ok, res = pcall(function()
        bridge:FireServer("BuySeed", {seedName})
    end)
    if not ok then xlog("Shop", "Error: "..tostring(res):sub(1,60), true); return false end
    return true
end

local function sellCrop(cropName)
    local bridge = getBridge()
    if not bridge then xlog("Sell", "Bridge not found", true); return false end
    local ok, res = pcall(function()
        bridge:FireServer("Sell", {cropName})
    end)
    if not ok then xlog("Sell", "Error: "..tostring(res):sub(1,60), true); return false end
    return true
end

local function harvestAll(parts)
    if not parts or #parts == 0 then return 0 end
    local count = 0
    for _, p in ipairs(parts) do
        if harvest(p) then count = count + 1 end
        task.wait(0.3)
    end
    return count
end

local function getBalanceInfo()
    local bridge = getBridge()
    if not bridge then return nil end
    local ok, info = pcall(function()
        local ev = RS:FindFirstChild("MoneyValue") or RS:FindFirstChild("Cash")
        if ev and ev:IsA("IntValue") then
            return { cash = ev.Value }
        end
        return { cash = 0 }
    end)
    if ok then return info end
    return nil
end

-- ┌─────────────────────────────────────────────────────────┐
-- │                  FISHING LOGIC                          │
-- └─────────────────────────────────────────────────────────┘
local Fish = {
    autoOn = false, fishTask = nil,
    rodEquipped = false, waitDelay = 6
}

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

local function castOnce()
    local castEv = getFishEv("CastEvent") or getFishEv("Cast")
    if not castEv then
        xlog("Fishing", "Cast event not found", true)
        return false
    end
    local ok = pcall(function()
        castEv:FireServer()
    end)
    if ok then task.wait(Fish.waitDelay) end
    
    -- Tarik otomatis
    local reelEv = getFishEv("ReelEvent") or getFishEv("Reel")
    if reelEv then pcall(function() reelEv:FireServer() end) end
    return ok
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
        
        bd.Velocity = vel
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
                
                local scrPos = (game:GetService("Workspace").CurrentCamera.CFrame.p - pos).Magnitude
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
local Win = Library:CreateWindow("XKID HUB v5.1", false, 3)
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
    function(v) Farm.selectedQty = v end,"Plot per cycle")

FarmL:Button("▶ Mulai Tanam","Auto cycle: Beli → Tanam → Panen",
    function()
        if not Farm.selectedArea or not Farm.selectedCrop then
            notify("Error","Pilih area & tanaman dulu!",3); return
        end
        if Farm.active then
            notify("Info","Farming sudah running",2); return
        end
        
        Farm.active = true
        Farm.task = task.spawn(function()
            local plots = filterByPola(AREA_PLOTS[Farm.selectedArea], Farm.selectedPola, Farm.selectedQty)
            notify("Farm","Dimulai! "..#plots.." plot",2)
            
            while Farm.active do
                -- Beli benih
                local ok = buySeed(Farm.selectedCrop.seed)
                if not ok then
                    notify("Farm","Gagal beli benih, stop",3)
                    Farm.active = false; break
                end
                task.wait(0.5)
                
                -- Tanam
                local planted = 0
                for _, pl in ipairs(plots) do
                    if not Farm.active then break end
                    if teleportToPart(pl.part) then
                        if plant(pl.part, Farm.selectedCrop.name, Farm.selectedCrop.seed) then
                            planted = planted + 1
                        end
                        task.wait(0.5)
                    end
                end
                notify("Farm","Ditanam: "..planted.."/"..#plots,2)
                
                -- Tunggu tumbuh (simulasi 30 detik)
                task.wait(30)
                
                -- Panen
                local harvested = 0
                for _, pl in ipairs(plots) do
                    if not Farm.active then break end
                    if teleportToPart(pl.part) then
                        if harvest(pl.part) then
                            harvested = harvested + 1
                        end
                        task.wait(0.3)
                    end
                end
                notify("Farm","Dipanen: "..harvested.."/"..#plots,2)
                task.wait(2)
            end
        end)
    end)

FarmL:Button("⏸ Hentikan","Stop farming cycle",
    function()
        Farm.active = false
        if Farm.task then pcall(function() task.cancel(Farm.task) end); Farm.task = nil end
        notify("Farm","Dihentikan",2)
    end)

FarmR:Paragraph("Cara Tanam",
    "1. Pilih area (Scan otomatis)\n"..
    "2. Pilih tanaman (AppleTree, Padi, dll)\n"..
    "3. Pilih pola (Normal/Rapat/etc)\n"..
    "4. Atur jumlah plot (max 20)\n"..
    "5. Klik Mulai Tanam\n\n"..
    "✓ Auto beli benih\n"..
    "✓ Auto tanam\n"..
    "✓ Auto panen")

FarmR:Paragraph("Pola Tanam",
    "Normal: Urut biasa\n"..
    "Rapat: Terdekat dulu\n"..
    "Selang-seling Lebar: Ganjil-genap\n"..
    "Selang-seling Panjang: Baris atas dulu")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                    TAB SHOP                           ║
-- ╚═══════════════════════════════════════════════════════╝
local ShopP = T_Shop:Page("Shop","shopping-cart")
local ShopL = ShopP:Section("🏪 Beli","Left")
local ShopR = ShopP:Section("💰 Jual","Right")

for _, c in ipairs(CROPS) do
    ShopL:Button(c.icon.." Beli "..c.seed,"Harga: 💵 "..c.price,
        function()
            task.spawn(function()
                for i = 1, 5 do  -- beli 5x
                    if buySeed(c.seed) then
                        notify("Shop","Beli "..c.seed.." ("..i.."/"..5..")",1)
                    else
                        notify("Shop","Gagal beli "..c.seed,2)
                        break
                    end
                    task.wait(0.3)
                end
            end)
        end)
end

for _, c in ipairs(CROPS) do
    ShopR:Button(c.icon.." Jual "..c.name,"Harga: 💵 "..c.sell,
        function()
            if sellCrop(c.name) then
                notify("Shop","Dijual: "..c.name,2)
            else
                notify("Shop","Gagal jual",2)
            end
        end)
end

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB TELEPORT                         ║
-- ╚═══════════════════════════════════════════════════════╝
local TeleP = T_Tele:Page("Teleport","map-pin")
local TeleL = TeleP:Section("🗺 Teleport","Left")
local TeleR = TeleP:Section("ℹ Info","Right")

for _, areaName in ipairs(AREA_NAMES) do
    TeleL:Button("➡️ "..areaName,"Ke area ini",
        function()
            local plots = AREA_PLOTS[areaName]
            if plots and #plots > 0 then
                teleportToPart(plots[1].part)
                notify("Teleport","Ke "..areaName,2)
            else
                notify("Error","Area tidak ada plot",2)
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

TeleR:Paragraph("Tips Teleport",
    "Semua area di-scan otomatis\n"..
    "dari Workspace.Land & index\n"..
    "52-67 di Workspace\n\n"..
    "Teleport = CFrame lerp\n"..
    "Tidak ada delay")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB PLAYER                          ║
-- ╚═══════════════════════════════════════════════════════╝
local PlayP = T_Play:Page("Player","user")
local PlayL = PlayP:Section("⚡ Kemampuan","Left")
local PlayR = PlayP:Section("💨 Movement","Right")

PlayL:Slider("Walk Speed","walkSpd",10,50,16,
    function(v) local h=getHum()
        if h then h.WalkSpeed=v end
    end,"Default 16")
PlayL:Slider("Jump Power","jp",50,500,50,
    function(v) local h=getHum()
        if h then h.JumpPower=v; h.UseJumpPower=true end
    end,"Default 50")
PlayL:Toggle("Infinite Jump","infJump",false,"Lompat terus",
    function(v) setInfJump(v); notify("Inf Jump",v and "ON" or "OFF",2) end)
PlayL:Toggle("NoClip","noclip",false,"Tembus dinding",
    function(v) setNoclip(v); notify("NoClip",v and "ON" or "OFF",2) end)

PlayR:Toggle("Fly","fly",false,"Terbang bebas",
    function(v)
        Move.flySpeed = Move.flySpeed  -- sync
        if v then startFly() else stopFly() end
        notify("Fly",v and "ON" or "OFF",2)
    end)
PlayR:Slider("Fly Speed","flySpd",10,300,60,
    function(v) Move.flySpeed=v end,"Kecepatan terbang")
PlayR:Toggle("ESP Player","espPl",false,"Nama + jarak player lain",
    function(v)
        ESPPl.active=v
        if v then
            startESPPlayer()
        else
            stopESPPlayer()  -- disconnect + cleanup, bukan cuma flag
        end
        notify("ESP Player",v and "ON" or "OFF",2)
    end)
PlayR:Paragraph("Cara Fly",
    "Mobile:\nJoystick = maju/mundur/kiri/kanan\nKamera atas  = naik\nKamera bawah = turun\nDiam = melayang stabil\n\n"..
    "PC:\nW/S/A/D = gerak\nE/Space = naik  Q = turun")

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
local SetR  = SetP:Section("ℹ Log & Info","Right")

-- Tombol lihat log — Android friendly, tidak butuh F9
SetR:Button("📋 Lihat Log Terbaru","Tampilkan 5 log error terakhir di notif",
    function()
        if #logLines == 0 then
            notify("Log","Belum ada log error",3); return
        end
        local txt = ""
        for i = 1, math.min(5, #logLines) do
            txt = txt..logLines[i].."\n"
        end
        notify("Log ("..#logLines.." total)", txt, 12)
    end)

SetR:Button("📋 Lihat Semua Log","Tampilkan semua log (maks 10)",
    function()
        if #logLines == 0 then
            notify("Log","Belum ada log",3); return
        end
        local txt = ""
        for i = 1, math.min(10, #logLines) do
            txt = txt..logLines[i].."\n"
        end
        notify("Log Lengkap", txt, 15)
    end)

SetR:Button("🗑 Bersihkan Log","Hapus semua riwayat log",
    function()
        logLines = {}
        notify("Log","Log dibersihkan",2)
    end)

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
                while Fish.autoOn do
                    local ok, err = pcall(castOnce)
                    if not ok then
                        xlog("Fishing","castOnce error: "..tostring(err):sub(1,60), true)
                        task.wait(3)  -- backoff kalau error
                    else
                        task.wait(0.5)  -- safety gap antar cast
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
