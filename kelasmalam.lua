--[[
  ╔══════════════════════════════════════════════════════╗
  ║         🌟  X K I D  H U B  v3.1  🌟               ║
  ║         Aurora UI  ✦  Farming + Fishing Fix          ║
  ╚══════════════════════════════════════════════════════╝
  v3.1 Fix:
  [1] Auto Fishing: auto equip AdvanceRod dari backpack
  [2] Batas tanam max 20 plot per cycle, sisanya cycle berikut
  [3] Pola tanam lebih reliable dengan spacing grid
  [4] Semua fix dari v2.0 (NoClip, Fly, ESP, InfJump)
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

-- ════════════════════════════════════════
--  SAVE LAST POSITION
-- ════════════════════════════════════════
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
    { name="AppleTree",  seed="Bibit Apel",      icon="🍎", price=15,       sell=45        },
    { name="Padi",       seed="Bibit Padi",      icon="🌾", price=15,       sell=20        },
    { name="Melon",      seed="Bibit Melon",     icon="🍈", price=15,       sell=20        },
    { name="Tomat",      seed="Bibit Tomat",     icon="🍅", price=15,       sell=20        },
    { name="Sawi",       seed="Bibit Sawi",      icon="🥬", price=15,       sell=20        },
    { name="Coconut",    seed="Bibit Kelapa",    icon="🥥", price=100,      sell=140       },
    { name="Daisy",      seed="Bibit Daisy",     icon="🌼", price=5000,     sell=6000      },
    { name="FanPalm",    seed="Bibit FanPalm",   icon="🌴", price=100000,   sell=102000    },
    { name="SunFlower",  seed="Bibit SunFlower", icon="🌻", price=2000000,  sell=2010000   },
    { name="Sawit",      seed="Bibit Sawit",     icon="🪴", price=80000000, sell=80100000  },
}
local cropNames = {}
for _, c in ipairs(CROP_LIST) do table.insert(cropNames, c.icon.." "..c.seed) end

-- ════════════════════════════════════════
--  SCAN PLOT
-- ════════════════════════════════════════
local plotCache = nil
local MAX_PLOT  = 20  -- batas maksimal tanam per cycle

local function scanPlots()
    if plotCache then return plotCache end
    plotCache = {}

    local land = Workspace:FindFirstChild("Land")
    if land then
        for _, p in ipairs(land:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                table.insert(plotCache, p)
            end
        end
    end

    -- Fallback index
    local indices = {52,53,54,64,65,66,67}
    for _, idx in ipairs(indices) do
        local obj = Workspace:GetChildren()[idx]
        if obj then
            if obj:IsA("BasePart") then
                table.insert(plotCache, obj)
            else
                for _, p in ipairs(obj:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then
                        table.insert(plotCache, p)
                    end
                end
            end
        end
    end

    print("[ XKID ] Plots cached: "..#plotCache)
    return plotCache
end

-- ════════════════════════════════════════
--  POLA TANAM (FIXED)
--  Normal  = urutan biasa, max 20
--  Rapat   = sort by distance dari karakter, ambil 20 terdekat
--  Lebar   = ambil plot dengan X berbeda (selang baris), max 20
--  Panjang = ambil plot dengan Z berbeda (selang kolom), max 20
-- ════════════════════════════════════════
local POLA_LIST    = {"Normal", "Rapat", "Lebar", "Panjang"}
local selectedPola = "Normal"

local function filterPlots(plots)
    local result = {}

    if selectedPola == "Normal" then
        -- Urutan biasa, ambil max 20
        for i = 1, math.min(#plots, MAX_PLOT) do
            table.insert(result, plots[i])
        end

    elseif selectedPola == "Rapat" then
        -- Sort by jarak dari karakter, ambil 20 terdekat
        local root = getRoot()
        if root then
            local sorted = {}
            for _, p in ipairs(plots) do
                table.insert(sorted, {
                    part = p,
                    dist = (p.Position - root.Position).Magnitude
                })
            end
            table.sort(sorted, function(a,b) return a.dist < b.dist end)
            for i = 1, math.min(#sorted, MAX_PLOT) do
                table.insert(result, sorted[i].part)
            end
        else
            for i = 1, math.min(#plots, MAX_PLOT) do
                table.insert(result, plots[i])
            end
        end

    elseif selectedPola == "Lebar" then
        -- Pilih plot dengan X berbeda (selang-seling baris)
        -- Sort by X, ambil setiap baris genap
        local sorted = {table.unpack(plots)}
        table.sort(sorted, function(a,b) return a.Position.X < b.Position.X end)
        local lastX, skip = nil, false
        local spacing = 8 -- jarak antar baris
        for _, p in ipairs(sorted) do
            if lastX == nil then
                lastX = p.Position.X; skip = false
            elseif math.abs(p.Position.X - lastX) > spacing then
                lastX = p.Position.X; skip = not skip
            end
            if not skip then
                table.insert(result, p)
                if #result >= MAX_PLOT then break end
            end
        end
        -- Fallback kalau kosong
        if #result == 0 then
            for i=1, math.min(#plots, MAX_PLOT) do table.insert(result, plots[i]) end
        end

    elseif selectedPola == "Panjang" then
        -- Pilih plot dengan Z berbeda (selang-seling kolom)
        local sorted = {table.unpack(plots)}
        table.sort(sorted, function(a,b) return a.Position.Z < b.Position.Z end)
        local lastZ, skip = nil, false
        local spacing = 8
        for _, p in ipairs(sorted) do
            if lastZ == nil then
                lastZ = p.Position.Z; skip = false
            elseif math.abs(p.Position.Z - lastZ) > spacing then
                lastZ = p.Position.Z; skip = not skip
            end
            if not skip then
                table.insert(result, p)
                if #result >= MAX_PLOT then break end
            end
        end
        if #result == 0 then
            for i=1, math.min(#plots, MAX_PLOT) do table.insert(result, plots[i]) end
        end
    end

    return result
end

-- ════════════════════════════════════════
--  BELI BIBIT
-- ════════════════════════════════════════
local selectedCrop = CROP_LIST[1]
local jumlahBeli   = 10

local function beliBibit(crop, qty)
    local ev = getBridge()
    if not ev then notif("Gagal","BridgeNet2 tidak ada",3); return false end
    local ok = pcall(function()
        ev:FireServer({
            { cropName=crop.name, amount=qty or jumlahBeli },
            "\a"
        })
    end)
    return ok
end

-- ════════════════════════════════════════
--  TANAM — loop Vector3 max 20 per cycle
-- ════════════════════════════════════════
local plantOffset = 0  -- track posisi cycle untuk queue

local function tanamPlots(crop)
    local ev = getBridge()
    if not ev then notif("Gagal","BridgeNet2 tidak ada",3); return 0 end

    local allPlots = scanPlots()
    if #allPlots == 0 then notif("Plant","Tidak ada plot",4); return 0 end

    -- Ambil berdasarkan pola
    local filtered = filterPlots(allPlots)
    if #filtered == 0 then notif("Plant","Filter plot kosong",4); return 0 end

    local count = 0
    for idx, plot in ipairs(filtered) do
        pcall(function()
            ev:FireServer({
                {
                    slotIdx     = idx,
                    hitPosition = plot.Position,
                    hitPart     = plot
                },
                "\x04"
            })
        end)
        count = count + 1
        task.wait(0.15)
    end
    return count
end

-- ════════════════════════════════════════
--  HARVEST
-- ════════════════════════════════════════
local function harvestAll()
    local ev = getBridge()
    if not ev then notif("Gagal","BridgeNet2 tidak ada",3); return 0 end
    local plots = filterPlots(scanPlots())
    local count = 0
    for _, plot in ipairs(plots) do
        pcall(function()
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
        count = count + 1
        task.wait(0.1)
    end
    return count
end

-- ════════════════════════════════════════
--  AUTO FARM CYCLE
-- ════════════════════════════════════════
local farmLoop  = nil
local farmDelay = 60
local autoFarm  = false

local function runFarmCycle()
    -- 1. Beli bibit
    notif("Farm","Beli "..selectedCrop.seed.."...",2)
    beliBibit(selectedCrop, jumlahBeli)
    task.wait(1)

    -- 2. Tanam (max 20 plot)
    notif("Farm","Tanam pola "..selectedPola.." (max "..MAX_PLOT..")...",2)
    local planted = tanamPlots(selectedCrop)
    notif("Farm",planted.." plot ditanam",3)
    task.wait(1)

    -- 3. Tunggu tumbuh
    notif("Farm","Tumbuh "..farmDelay.."s...",farmDelay-1)
    task.wait(farmDelay)

    -- 4. Harvest
    notif("Farm","Harvest...",2)
    local harvested = harvestAll()
    notif("Farm","Cycle selesai! Harvest: "..harvested,4)
    task.wait(1)
end

-- ════════════════════════════════════════
--  EQUIP ROD (FIXED)
--  Cari AdvanceRod di backpack, lalu equip via humanoid
-- ════════════════════════════════════════
local function equipRod()
    local char    = getChar()
    local backpack = LP:FindFirstChild("Backpack")
    if not backpack then return false end

    -- Cari AdvanceRod di backpack
    local rod = backpack:FindFirstChild("AdvanceRod")
    if not rod then
        -- Coba cari yang mirip
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool.Name:lower():find("rod") or tool.Name:lower():find("pancing") then
                rod = tool; break
            end
        end
    end

    if not rod then
        notif("Fishing","AdvanceRod tidak ada di backpack!",4)
        return false
    end

    -- Equip tool ke karakter
    if char then
        rod.Parent = char
        task.wait(0.5)
        notif("Fishing","AdvanceRod di-equip!",2)
        return true
    end
    return false
end

local function unequipRod()
    local char = getChar(); if not char then return end
    local backpack = LP:FindFirstChild("Backpack"); if not backpack then return end
    local rod = char:FindFirstChild("AdvanceRod")
    if rod then rod.Parent = backpack end
end

-- ════════════════════════════════════════
--  AUTO FISHING (FIXED)
--  1. Equip AdvanceRod otomatis
--  2. Cast → tunggu → tarik
--  3. MiniGame selesai
--  4. Ulangi (rod sudah equipped, tidak perlu equip lagi)
-- ════════════════════════════════════════
local fishLoop  = nil
local autoFish  = false
local fishDelay = 5
local rodEquipped = false

local function doFishing()
    local castEv = getFishRemote("CastEvent")
    local miniEv = getFishRemote("MiniGame")
    if not castEv then notif("Fish","CastEvent tidak ada",3); return end

    -- Lempar kail
    pcall(function() castEv:FireServer(false, 0) end)
    task.wait(0.5)
    pcall(function() castEv:FireServer(true) end)

    -- Tunggu ikan makan
    task.wait(fishDelay)

    -- Tarik
    pcall(function() castEv:FireServer(false, fishDelay) end)
    task.wait(0.5)

    -- Selesaikan minigame
    if miniEv then
        pcall(function() miniEv:FireServer(true) end)
        task.wait(0.3)
        pcall(function() firesignal(miniEv.OnClientEvent, "Stop") end)
    end

    task.wait(0.8)
end

-- ════════════════════════════════════════
--  ESP TANAMAN
-- ════════════════════════════════════════
local VALID_CROPS_ESP = {}
for _, c in ipairs(CROP_LIST) do VALID_CROPS_ESP[c.name] = true end

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
    bill.Size        = UDim2.new(0,90,0,28)
    bill.StudsOffset = Vector3.new(0,3.5,0)
    bill.AlwaysOnTop = true
    bill.Adornee     = part
    bill.Parent      = part

    local bg = Instance.new("Frame",bill)
    bg.Size=UDim2.new(1,0,1,0)
    bg.BackgroundColor3=Color3.fromRGB(5,15,5)
    bg.BackgroundTransparency=0.3
    bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,5)

    local lbl = Instance.new("TextLabel",bg)
    lbl.Size=UDim2.new(1,-4,1,-2)
    lbl.Position=UDim2.new(0,2,0,1)
    lbl.BackgroundTransparency=1
    lbl.TextScaled=true
    lbl.Font=Enum.Font.GothamBold
    lbl.TextXAlignment=Enum.TextXAlignment.Center
    lbl.TextStrokeTransparency=0.3

    local conn = RunService.Heartbeat:Connect(function()
        if not bill or not bill.Parent then return end
        local pct = getMatang(part, name)
        lbl.Text=name.."\n"..pct.."%"
        lbl.TextColor3=matangColor(pct)
        lbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
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
    if now-lastCropScan < 8 then return end
    lastCropScan = now
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and VALID_CROPS_ESP[v.Name] and not espCropTagged[v] then
            makeESPCrop(v, v.Name)
        elseif v:IsA("Model") and VALID_CROPS_ESP[v.Name] then
            local p = v.PrimaryPart or v:FindFirstChildOfClass("BasePart")
            if p and not espCropTagged[p] then makeESPCrop(p, v.Name) end
        end
    end
end

local function startESPCrop()
    clearESPCrop(); lastCropScan=0; scanESPCrop()
    espCropLoop=task.spawn(function()
        while _G.ESPCrop do task.wait(10); if _G.ESPCrop then scanESPCrop() end end
    end)
end
local function stopESPCrop()
    clearESPCrop()
    if espCropLoop then pcall(function() task.cancel(espCropLoop) end); espCropLoop=nil end
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
    local head = p.Character:FindFirstChild("Head"); if not head then return end

    local bill = Instance.new("BillboardGui")
    bill.Name="XKID_ESP"; bill.Size=UDim2.new(0,80,0,20)
    bill.StudsOffset=Vector3.new(0,2.2,0)
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
    espPlayerConn=RunService.Heartbeat:Connect(function()
        if not espPlayerOn then return end
        local myR=getRoot()
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
--  NOCLIP
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

-- ════════════════════════════════════════
--  INF JUMP
-- ════════════════════════════════════════
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

-- ════════════════════════════════════════
--  FLY
-- ════════════════════════════════════════
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
    bg.MaxTorque=Vector3.new(1e5,1e5,1e5); bg.P=1e4; bg.D=100; bg.CFrame=root.CFrame
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
--  SPEED
-- ════════════════════════════════════════
local speed=16
RunService.RenderStepped:Connect(function()
    local h=getHum(); if h then h.WalkSpeed=speed end
end)

-- ════════════════════════════════════════
--  WINDOW & TABS
-- ════════════════════════════════════════
local Win = Library:Window("XKID HUB","star","v3.1",false)

Win:TabSection("Farming")
local TabFarm = Win:Tab("Farm",    "leaf")
local TabFish = Win:Tab("Fishing", "fish")

Win:TabSection("Player")
local TabTP   = Win:Tab("Teleport","map-pin")
local TabPl   = Win:Tab("Movement","zap")
local TabESP  = Win:Tab("ESP",     "eye")
local TabProt = Win:Tab("Protect", "shield")

-- ════════════════════════════════════════
--  TAB FARM
-- ════════════════════════════════════════
local FPage = TabFarm:Page("Auto Farm","leaf")
local FL    = FPage:Section("Auto Cycle","Left")
local FR    = FPage:Section("Pengaturan","Right")

FL:Toggle("Auto Farm Cycle","AutoFarmToggle",false,
    "Beli bibit + tanam + harvest loop",
    function(v)
        autoFarm=v
        if v then
            farmLoop=task.spawn(function()
                while autoFarm do
                    runFarmCycle(); task.wait(2)
                end
            end)
            notif("Auto Farm","ON — pola "..selectedPola,3)
        else
            if farmLoop then pcall(function() task.cancel(farmLoop) end); farmLoop=nil end
            notif("Auto Farm","OFF",2)
        end
    end)

FL:Button("1 Cycle Sekarang","Jalankan 1 cycle penuh",
    function() task.spawn(runFarmCycle) end)

FL:Button("Tanam Sekarang","Tanam "..MAX_PLOT.." plot (pola dipilih)",
    function()
        task.spawn(function()
            local c=tanamPlots(selectedCrop)
            notif("Tanam",c.." plot | pola: "..selectedPola,3)
        end)
    end)

FL:Button("Harvest Sekarang","Harvest plot yang dipilih",
    function()
        task.spawn(function()
            local c=harvestAll()
            notif("Harvest",c.." plot selesai",3)
        end)
    end)

FL:Button("Beli Bibit","Beli bibit yang dipilih",
    function()
        task.spawn(function()
            local ok=beliBibit(selectedCrop,jumlahBeli)
            notif("Beli",ok and selectedCrop.seed.." x"..jumlahBeli or "Gagal",3)
        end)
    end)

FR:Dropdown("Pilih Tanaman","CropDrop",cropNames,
    function(val)
        for _,c in ipairs(CROP_LIST) do
            if val:find(c.seed,1,true) then selectedCrop=c; break end
        end
        notif("Tanaman",selectedCrop.seed,2)
    end,"Pilih tanaman untuk ditanam")

FR:Dropdown("Pola Tanam","PolaDrop",POLA_LIST,
    function(val)
        selectedPola=val
        notif("Pola",val.." (max "..MAX_PLOT.." plot)",2)
    end,"Pilih pola tanam")

FR:Slider("Jumlah Beli","BeliQty",1,99,10,
    function(v) jumlahBeli=v end,"Per transaksi beli bibit")

FR:Slider("Delay Tumbuh (detik)","GrowDelay",10,300,60,
    function(v) farmDelay=v end,"Waktu tunggu setelah tanam")

FR:Button("Refresh Cache Plot","Scan ulang semua plot",
    function()
        plotCache=nil
        local p=scanPlots()
        notif("Plot",#p.." plot di-cache",3)
    end)

FR:Paragraph("Pola Tanam",
    "Normal  = urut, max "..MAX_PLOT.."\n"..
    "Rapat   = "..MAX_PLOT.." terdekat dari kamu\n"..
    "Lebar   = selang baris (X)\n"..
    "Panjang = selang kolom (Z)\n\n"..
    "Semua max "..MAX_PLOT.." plot per cycle")

-- ════════════════════════════════════════
--  TAB FISHING
-- ════════════════════════════════════════
local FishPage = TabFish:Page("Auto Fishing","fish")
local FishL    = FishPage:Section("Auto Fish","Left")
local FishR    = FishPage:Section("Pengaturan","Right")

FishL:Toggle("Auto Fishing","AutoFishToggle",false,
    "Auto equip AdvanceRod + cast loop",
    function(v)
        autoFish=v
        if v then
            -- Equip rod dulu sebelum mulai loop
            local equipped = equipRod()
            if not equipped then
                autoFish=false
                notif("Fish","Gagal equip AdvanceRod! Pastikan ada di backpack.",5)
                return
            end
            rodEquipped=true
            fishLoop=task.spawn(function()
                while autoFish do
                    doFishing(); task.wait(0.5)
                end
            end)
            notif("Auto Fish","ON — AdvanceRod equipped!",3)
        else
            if fishLoop then pcall(function() task.cancel(fishLoop) end); fishLoop=nil end
            rodEquipped=false
            notif("Auto Fish","OFF",2)
        end
    end)

FishL:Button("Equip AdvanceRod","Ambil rod dari backpack",
    function()
        local ok=equipRod()
        notif("Rod",ok and "AdvanceRod equipped!" or "Tidak ada di backpack",3)
    end)

FishL:Button("Mancing Sekali","Cast 1 kali manual",
    function()
        task.spawn(function()
            -- Auto equip kalau belum
            if not rodEquipped then
                local ok=equipRod()
                if not ok then
                    notif("Fish","AdvanceRod tidak ada!",3); return
                end
                rodEquipped=true
                task.wait(0.5)
            end
            doFishing()
            notif("Fish","Selesai 1 cast",2)
        end)
    end)

FishL:Button("Unequip Rod","Kembalikan rod ke backpack",
    function()
        unequipRod(); rodEquipped=false
        notif("Rod","Dikembalikan ke backpack",2)
    end)

FishR:Slider("Delay Tarik (detik)","FishDelay",1,15,5,
    function(v) fishDelay=v end,"Waktu tunggu sebelum tarik")

FishR:Paragraph("Cara Kerja",
    "1. Toggle ON\n"..
    "2. AdvanceRod otomatis\n"..
    "   di-equip dari backpack\n"..
    "3. Cast kail\n"..
    "4. Tunggu "..fishDelay.."s\n"..
    "5. Tarik + minigame\n"..
    "6. Ulangi otomatis\n\n"..
    "Pastikan AdvanceRod\nada di backpack dulu!")

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

TR:Paragraph("Info","Player online otomatis\nmuncul di kiri.\n\nKlik nama untuk TP!")

-- ════════════════════════════════════════
--  TAB MOVEMENT
-- ════════════════════════════════════════
local MovPage = TabPl:Page("Movement","zap")
local ML      = MovPage:Section("Speed & Jump","Left")
local MR      = MovPage:Section("Fly","Right")

ML:Slider("Walk Speed","speed",16,500,16,
    function(v) speed=v end,"Default 16")

ML:Toggle("NoClip","noclip",false,"Tembus dinding",
    function(v) setNoclip(v); notif("NoClip",v and "ON" or "OFF",2) end)

ML:Toggle("Infinite Jump","jump",false,"Lompat terus",
    function(v) setInfJump(v); notif("Inf Jump",v and "ON" or "OFF",2) end)

ML:Slider("Jump Power","jp",50,500,50,
    function(v)
        local h=getHum()
        if h then h.JumpPower=v; h.UseJumpPower=true end
    end,"Default 50")

MR:Toggle("Fly","fly",false,"Aktifkan terbang",
    function(v)
        if v then startFly() else stopFly() end
        notif("Fly",v and "ON" or "OFF",2)
    end)

MR:Slider("Fly Speed","flyspd",10,300,60,
    function(v) flySpeed=v end,"Kecepatan terbang")

MR:Paragraph("Cara Fly",
    "Joystick = arah\nKamera atas = naik\nKamera bawah = turun\nLepas = melayang")

-- ════════════════════════════════════════
--  TAB ESP
-- ════════════════════════════════════════
local ESPPage = TabESP:Page("ESP","eye")
local EL      = ESPPage:Section("ESP Player","Left")
local ER      = ESPPage:Section("ESP Tanaman","Right")

EL:Toggle("ESP Player","espplayer",false,"Nama + jarak (simpel)",
    function(v)
        espPlayerOn=v
        if v then startESPPlayer() else stopESPPlayer() end
        notif("ESP Player",v and "ON" or "OFF",2)
    end)

EL:Paragraph("ESP Player","Tampil: Nama + jarak\nFont kecil & simple\nUpdate real-time")

ER:Toggle("ESP Tanaman","espcrop",false,"Nama + % kematangan",
    function(v)
        _G.ESPCrop=v
        if v then startESPCrop() else stopESPCrop() end
        notif("ESP Tanaman",v and "ON" or "OFF",2)
    end)

ER:Button("Scan Ulang","Refresh ESP tanaman",
    function()
        if _G.ESPCrop then lastCropScan=0; scanESPCrop()
        else notif("ESP","Aktifkan ESP Tanaman dulu!",2) end
    end)

ER:Button("Reset Size","Reset data kematangan",
    function() sizeTracker={}; notif("Reset","Size tracker di-reset",2) end)

ER:Paragraph("ESP Tanaman",
    "Merah  = baru tanam\nKuning = setengah\nHijau  = siap panen\n\nRescan tiap 10 detik")

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

PL:Button("Rejoin","Koneksi ulang ke server",
    function()
        notif("Rejoin","Menghubungkan ulang...",3)
        task.wait(1); TpService:Teleport(game.PlaceId,LP)
    end)

PL:Button("Posisi Saya","Lihat koordinat sekarang",
    function()
        local r=getRoot()
        if r then
            local p=r.Position
            notif("Posisi",string.format("X=%.1f\nY=%.1f\nZ=%.1f",p.X,p.Y,p.Z),6)
        end
    end)

PR:Paragraph("Anti AFK","Cegah auto disconnect\ndengan simulasi input")
PR:Paragraph("Respawn","Kembali ke posisi\nterakhir sebelum mati")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
task.spawn(function()
    task.wait(2); scanPlots()
    notif("Plot","Farm plots di-cache!",3)
end)

Library:Notification("XKID HUB","v3.1 — Farm · Fish (Auto Rod) · ESP",5)
Library:ConfigSystem(Win)

print("[ XKID HUB ] v3.1 loaded — "..LP.Name)
