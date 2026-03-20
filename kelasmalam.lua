--[[
╔═══════════════════════════════════════════════════════════╗
║              🌟  X K I D   H U B  v6.0  🌟              ║
║                Aurora UI  ·  Full Edition               ║
╠═══════════════════════════════════════════════════════════╣
║  Farming v2  ·  Shop  ·  Teleport  ·  Player             ║
║  Security +FastRespawn  ·  Fishing v2  ·  Complete       ║
╚═══════════════════════════════════════════════════════════╝
]]

-- ┌─────────────────────────────────────────────────────────┐
-- │                    AURORA UI LIBRARY                    │
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
-- │                   CROP DATA (10 CROPS)                  │
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
-- │                AREA / PLOT DATA                         │
-- └─────────────────────────────────────────────────────────┘
local AREA_INDICES = {52, 53, 54, 64, 65, 66, 67}
local AREA_NAMES   = {}
local AREA_PLOTS   = {}

local LAND_DATA = {
    { name="Land1", pos=Vector3.new(23.97, 9.00, 0.18) },
    { name="Land2", pos=Vector3.new(23.85, 9.36, 0.18) },
    { name="Land3", pos=Vector3.new(23.86, 9.71, 0.18) },
    { name="Land4", pos=Vector3.new(24.32, 9.71, 0.18) },
    { name="Land5", pos=Vector3.new(33.31, 15.82, 40.51) },
    { name="Land6", pos=Vector3.new(23.88, 9.28, 0.18) },
}

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
-- │         FARMING POLA (4 PILIHAN)                        │
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

-- ┌─────────────────────────────────────────────────────────┐
-- │         FARMING FUNCTIONS v2                            │
-- └─────────────────────────────────────────────────────────┘
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

local function harvestAll(parts)
    if not parts or #parts == 0 then return 0 end
    local count = 0
    for _, p in ipairs(parts) do
        if harvest(p) then count = count + 1 end
        task.wait(0.3)
    end
    return count
end

-- ┌─────────────────────────────────────────────────────────┐
-- │         FISHING SYSTEM v2 (31.6s TIMING)                │
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
    
    pcall(function() castEv:FireServer(true) end)
    task.wait(0.8)
    
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
-- │                 MOVEMENT SYSTEM                         │
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
        
        local cf = r.CFrame
        local pitch = cf.LookVector.Y
        local vVel = 0
        if math.abs(pitch) > 0.25 then
            local t = math.clamp((math.abs(pitch) - 0.25) / (1 - 0.25), 0, 1)
            vVel = math.sign(pitch) * t * Move.flySpeed * 0.6
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
local Win = Library:CreateWindow("XKID HUB v6.0", false, 3)
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
local FarmL = FarmP:Section("🚜 Manual Tanam","Left")
local FarmM = FarmP:Section("🔄 Auto Farming","Middle")
local FarmR = FarmP:Section("ℹ Info","Right")

local Farm = {
    selectedArea = nil,
    selectedCrop = nil,
    selectedPola = "Normal",
    jumlahTanam = 5,
    active = false,
    task = nil,
    autoFarmActive = false,
    autoFarmTask = nil,
    autoWaitTime = 60,
    autoBeli = true
}

-- MANUAL TANAM SECTION
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
    function(v) Farm.jumlahTanam = v end,"Max 20 plot")

FarmL:Button("🌱 Mulai Tanam","Tanam instant sekarang",
    function()
        if not Farm.selectedArea or not Farm.selectedCrop then
            notify("Error","Pilih area & tanaman!",3); return
        end
        
        local plotList = AREA_PLOTS[Farm.selectedArea]
        if not plotList then
            notify("Error","Area tidak ada!",2); return
        end
        
        local filtered = filterByPola(plotList, Farm.selectedPola, Farm.jumlahTanam)
        local planted = 0
        
        for _, pl in ipairs(filtered) do
            if teleportToPart(pl.part) then
                if plant(pl.part, Farm.selectedCrop.name, Farm.selectedCrop.seed) then
                    planted = planted + 1
                end
                task.wait(0.2)
            end
        end
        
        notify("Farm","✅ "..planted.."/"..#filtered.." ditanam",2)
    end)

-- AUTO FARMING SECTION
FarmM:Label("⚙️ Settings")

FarmM:Toggle("Auto Farm (Full Cycle)","autoFarm",false,"Beli→Tanam→Tunggu→Panen",
    function(v)
        Farm.autoFarmActive = v
        if v then
            if not Farm.selectedArea or not Farm.selectedCrop then
                notify("Error","Pilih area & crop!",2)
                Farm.autoFarmActive = false
                return
            end
            
            Farm.autoFarmTask = task.spawn(function()
                while Farm.autoFarmActive do
                    -- Beli
                    if Farm.autoBeli then
                        buySeed(Farm.selectedCrop.seed)
                        task.wait(0.5)
                    end
                    
                    -- Tanam
                    local plotList = AREA_PLOTS[Farm.selectedArea]
                    local filtered = filterByPola(plotList, Farm.selectedPola, Farm.jumlahTanam)
                    local planted = 0
                    
                    for _, pl in ipairs(filtered) do
                        if not Farm.autoFarmActive then break end
                        if teleportToPart(pl.part) then
                            if plant(pl.part, Farm.selectedCrop.name, Farm.selectedCrop.seed) then
                                planted = planted + 1
                            end
                            task.wait(0.2)
                        end
                    end
                    
                    notify("Auto Farm","Ditanam: "..planted,1)
                    task.wait(Farm.autoWaitTime)
                    
                    -- Panen
                    local harvested = 0
                    for _, pl in ipairs(filtered) do
                        if not Farm.autoFarmActive then break end
                        if teleportToPart(pl.part) then
                            if harvest(pl.part) then
                                harvested = harvested + 1
                            end
                            task.wait(0.1)
                        end
                    end
                    
                    notify("Auto Farm","Dipanen: "..harvested,1)
                    task.wait(2)
                end
            end)
            notify("Auto Farm","ON - Cycle dimulai",2)
        else
            if Farm.autoFarmTask then
                pcall(function() task.cancel(Farm.autoFarmTask) end)
                Farm.autoFarmTask = nil
            end
            notify("Auto Farm","OFF",2)
        end
    end)

FarmM:Toggle("Auto Beli Jika Habis","autoBeli",true,"Beli otomatis sebelum tanam",
    function(v) Farm.autoBeli = v end)

FarmM:Slider("Waktu Tumbuh","waitTime",15,300,60,
    function(v) Farm.autoWaitTime = v end,"Detik")

FarmM:Button("💰 Panen Semua","Panen dari semua plot",
    function()
        if not Farm.selectedArea then
            notify("Error","Pilih area!",2); return
        end
        
        local allParts = AREA_PARTS[Farm.selectedArea]
        if not allParts then
            notify("Error","Tidak ada plot!",2); return
        end
        
        local harvested = 0
        for _, p in ipairs(allParts) do
            if teleportToPart(p) then
                if harvest(p) then
                    harvested = harvested + 1
                end
                task.wait(0.1)
            end
        end
        
        notify("Panen","✅ "..harvested.." plot dipanen",2)
    end)

-- INFO SECTION
FarmR:Paragraph("📖 Manual Tanam",
    "1. Scan Area\n"..
    "2. Pilih Area, Crop, Pola, Qty\n"..
    "3. Klik Mulai Tanam\n"..
    "Instant execute!")

FarmR:Paragraph("📖 Auto Farming",
    "1. Setup area & crop\n"..
    "2. Toggle Auto Farm ON\n"..
    "3. Auto loop: Beli→Tanam→Tunggu→Panen\n"..
    "Customizable waktu tumbuh!")

FarmR:Paragraph("💡 Tips",
    "• Max 20 plot per tanam\n"..
    "• Pola Rapat = cepat\n"..
    "• Auto Beli on = seamless\n"..
    "• Monitor log untuk errors")

-- ╔═══════════════════════════════════════════════════════╗
-- ║                    TAB SHOP                           ║
-- ╚═══════════════════════════════════════════════════════╝
local ShopP = T_Shop:Page("Shop","shopping-cart")
local ShopL = ShopP:Section("🛒 Manual Beli","Left")
local ShopR = ShopP:Section("⚡ Quick Buy","Right")

local shopCrop = nil
local shopQty = 1

ShopL:Dropdown("Pilih Bibit","shopCrop",cropDropNames,
    function(v)
        for _, c in ipairs(CROPS) do
            if (c.icon.." "..c.seed) == v then
                shopCrop = c; break
            end
        end
    end)

ShopL:Slider("Jumlah","shopQty",1,99,5,
    function(v) shopQty = v end,"Item")

ShopL:Button("🛒 Beli Sekarang","Execute beli",
    function()
        if not shopCrop then
            notify("Error","Pilih bibit!",2); return
        end
        
        for i = 1, shopQty do
            if buySeed(shopCrop.seed) then
                task.wait(0.1)
            else
                notify("Beli","Gagal pada item ke-"..i,2); break
            end
        end
        notify("Beli","✅ "..shopQty.." bibit dibeli",2)
    end)

ShopL:Paragraph("📊 Harga Referensi",
    "🍎 Apel: Jual 45\n"..
    "🥬 Sawi: Jual 20\n"..
    "🌼 Daisy: Jual 6000\n"..
    "🪴 Sawit: Jual 80M")

for _, c in ipairs(CROPS) do
    ShopR:Button(c.icon.." "..c.name,"Harga: "..c.price.." | Jual: "..c.sell,
        function()
            if buySeed(c.seed) then
                notify("Beli","✅ Bibit "..c.name.." dibeli",1)
            end
        end)
end

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB TELEPORT                         ║
-- ╚═══════════════════════════════════════════════════════╝
local TeleP = T_Tele:Page("Teleport","map-pin")
local TeleL = TeleP:Section("📍 Ke Area","Left")
local TeleR = TeleP:Section("👤 Ke Player","Right")

for _, areaName in ipairs(AREA_NAMES) do
    TeleL:Button("TP: "..areaName,"Teleport instant",
        function()
            local plots = AREA_PLOTS[areaName]
            if plots and #plots > 0 then
                local r = getRoot()
                if r then
                    r.CFrame = plots[1].part.CFrame + Vector3.new(0, 3, 0)
                    notify("TP","✅ Ke "..areaName,1)
                end
            end
        end)
end

TeleL:Button("🏠 Spawn","Ke spawn area",
    function()
        local r = getRoot()
        if r then
            r.CFrame = CFrame.new(0, 50, 0)
            notify("TP","✅ Ke spawn",1)
        end
    end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        TeleR:Button("👤 "..p.Name,"TP instant",
            function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local r = getRoot()
                    if r then
                        r.CFrame = p.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                        notify("TP","✅ Ke "..p.Name,1)
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

PlayL:Slider("Walk Speed","walkSpd",10,500,16,
    function(v) local h=getHum(); if h then h.WalkSpeed=v end end,"km/h")
PlayL:Slider("Jump Power","jp",50,500,50,
    function(v) local h=getHum(); if h then h.JumpPower=v; h.UseJumpPower=true end end,"unit")
PlayL:Toggle("Infinite Jump","infJump",false,"Lompat unlimited",
    function(v) setInfJump(v); notify("Inf Jump",v and "ON" or "OFF",1) end)
PlayL:Toggle("NoClip","noclip",false,"Tembus dinding",
    function(v) setNoclip(v); notify("NoClip",v and "ON" or "OFF",1) end)

PlayR:Toggle("Fly","fly",false,"Terbang (WASD+Space/Q)",
    function(v)
        if v then startFly() else stopFly() end
        notify("Fly",v and "✅ ON" or "❌ OFF",1)
    end)
PlayR:Slider("Fly Speed","flySpd",10,300,60,
    function(v) Move.flySpeed=v end,"unit/s")
PlayR:Toggle("ESP Player","espPl",false,"Lihat player + jarak",
    function(v)
        ESPPl.active=v
        if v then startESPPlayer() else stopESPPlayer() end
        notify("ESP",v and "✅ ON" or "❌ OFF",1)
    end)

-- ╔═══════════════════════════════════════════════════════╗
-- ║                  TAB SECURITY                         ║
-- ╚═══════════════════════════════════════════════════════╝
local SecP  = T_Sec:Page("Security","shield")
local SecL  = SecP:Section("🛡️ Protection","Left")
local SecR  = SecP:Section("⏪ Fast Respawn","Right")

local afkConn=nil
SecL:Toggle("Anti AFK","antiAfk",false,"Prevent idle kick",
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
        notify("Anti AFK",v and "✅ ON" or "❌ OFF",1)
    end)

local antiKickConn=nil
SecL:Toggle("Anti Kick","antiKick",false,"HP terlindungi <15%",
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
        notify("Anti Kick",v and "✅ ON" or "❌ OFF",1)
    end)

SecL:Button("🔄 Rejoin","Reconnect ke server",
    function()
        notify("Rejoin","Loading...",2)
        task.wait(1); TpService:Teleport(game.PlaceId,LP)
    end)

SecR:Button("⏪ Respawn Instant","TP ke posisi terakhir",
    function() fastRespawn() end)

SecR:Toggle("Auto Respawn","autoResp",false,"Otomatis setelah mati",
    function(v)
        Respawn.autoRespawn = v
        if v then
            startAutoRespawn()
            notify("Auto Respawn","✅ ON",1)
        else
            stopAutoRespawn()
            notify("Auto Respawn","❌ OFF",1)
        end
    end)

SecR:Button("📍 Save Posisi","Simpan posisi saat ini",
    function()
        local root = getRoot()
        if root then
            Respawn.savedPosition = root.CFrame
            notify("Posisi","✅ Tersimpan",1)
        end
    end)

-- ╔═══════════════════════════════════════════════════════╗
-- ║                   TAB SETTING                         ║
-- ╚═══════════════════════════════════════════════════════╝
local SetP  = T_Set:Page("Setting","settings")
local SetL  = SetP:Section("🎣 Fishing","Left")
local SetR  = SetP:Section("📋 Log & Info","Right")

SetL:Toggle("Auto Fishing","autoFish",false,"Auto cast loop 31.6s",
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
                            notify("Fishing","Auto stopped - errors",3)
                            Fish.autoOn = false
                            break
                        end
                        task.wait(5)
                    end
                end
            end)
            notify("Fishing","✅ ON",2)
        else
            if Fish.fishTask then
                pcall(function() task.cancel(Fish.fishTask) end)
                Fish.fishTask=nil
            end
            notify("Fishing","❌ OFF",1)
        end
    end)

SetL:Button("🎣 Cast 1x","Cast kail sekali saja",
    function()
        if not Fish.rodEquipped then
            if not equipRod() then return end
        end
        if castOnce() then
            notify("Fishing","✅ 1x cast selesai",1)
        end
    end)

SetL:Button("📦 Equip Rod","Ambil rod dari backpack",
    function() if equipRod() then notify("Rod","✅ Equipped",1) end end)
SetL:Button("📤 Unequip Rod","Kembalikan rod ke backpack",
    function() unequipRod(); notify("Rod","✅ Unequipped",1) end)
SetL:Slider("Fish Wait Time","fishWait",2,60,31,
    function(v) Fish.waitDelay=v end,"Detik")

SetR:Button("📋 Lihat Log","5 log terakhir",
    function()
        if #logLines == 0 then
            notify("Log","Kosong",1); return
        end
        local txt = ""
        for i = 1, math.min(5, #logLines) do
            txt = txt..logLines[i].."\n"
        end
        notify("Log ("..#logLines.." total)", txt, 10)
    end)

SetR:Button("🗑️ Clear Log","Hapus semua log",
    function()
        logLines = {}
        notify("Log","✅ Dihapus",1)
    end)

SetR:Paragraph("ℹ️ XKID HUB v6.0",
    "✅ Full Farming System\n"..
    "✅ Manual + Auto Mode\n"..
    "✅ Fishing v2 (31.6s)\n"..
    "✅ Fast Respawn\n"..
    "✅ Complete Security")

-- ┌─────────────────────────────────────────────────────────┐
-- │                      INIT                               │
-- └─────────────────────────────────────────────────────────┘
local _totalPl = 0
for _,v in pairs(AREA_PARTS or {}) do _totalPl=_totalPl+#v end
if _totalPl > 0 then
    notify("✅ XKID HUB v6.0 Ready",
        #AREA_NAMES.." area | ".._totalPl.." plot",5)
else
    notify("⚠️ Warning","Plot tidak ditemukan!",5)
end

Library:Notification("XKID HUB v6.0 - COMPLETE EDITION",
    "Manual Farming · Auto Farming · Fishing v2 · Security", 6)
Library:ConfigSystem(Win)

print("[XKID HUB v6.0] loaded successfully — "..LP.Name)
