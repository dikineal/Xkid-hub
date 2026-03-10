-- ╔══════════════════════════════════════════════╗
-- ║  🌾 SAWAH INDO v9.2 ULTIMATE — XKID HUB     ║
-- ║  Fix: RequestSell + PlantCrop + SummonRain   ║
-- ║  Semua jual/tanam via remote langsung!       ║
-- ║  Support: Android + Delta/Arceus/Fluxus      ║
-- ╚══════════════════════════════════════════════╝

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO v9.2 ULTIMATE 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "RequestSell + PlantCrop + Rain 🔥",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

-- ============================================
-- SERVICES
-- ============================================
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")

local myName = LocalPlayer.Name

-- ============================================
-- GLOBAL FLAGS
-- ============================================
_G.ScriptRunning       = true
_G.AutoFarm            = false
_G.AutoBeli            = false
_G.AutoTanam           = false
_G.AutoJual            = false
_G.AutoPanen           = false
_G.ESP                 = false
_G.TeleportPanen       = false
_G.DetectorSawit       = false
_G.PenangkalPetir      = false
_G.AutoConfirm         = false  -- ✨ Auto confirm ConfirmAction (beli lahan dll)
_G.AutoSellIntercept   = false  -- ✨ Auto sell saat GUI terbuka (dari event intercept)
_G.AutoBeliIntercept   = false  -- ✨ Auto beli saat GUI bibit terbuka
_G.NotifLevelUp        = true   -- ✨ Notif saat level up

-- ============================================
-- PLAYER DATA (dari SyncData)
-- ============================================
local PlayerData = {
    Coins        = 0,
    Level        = 1,
    XP           = 0,
    Needed       = 50,
    Inventory    = {},
    OwnedTools   = {},
    TutorialDone = false,
    LastSync     = 0,
}

-- ============================================
-- DATA & CONFIG
-- ============================================

local LahanData = {
    Sawah = {
        label="🌾 Sawah", pos=nil, radius=50, cache={}, cacheTime=0,
        keywords={"areatanamsawah","areatanambesar","areatanampadi","sawah","tanah","lahan","plot","farm"},
    },
    Sawit = {
        label="🌴 Sawit", pos=nil, radius=50, cache={}, cacheTime=0,
        keywords={"areatanamsawit","sawit","kelapa"},
    },
    Ternak = {
        label="🐄 Ternak", pos=nil, radius=50, cache={}, cacheTime=0,
        keywords={"ternak","kandang","peternakan","hewan"},
    },
}

local ActiveFarmJenis = "Sawah"
local CopyPositions   = {Sawah=nil, Sawit=nil, Ternak=nil}
local TanamPositions  = {Sawit=nil, Durian=nil}
local SafePos         = nil

-- ✨ Shop mode untuk auto sell (dari decompile SellCrop handler)
-- p41 bisa: "OPEN_SELL_GUI","OPEN_TOOL_GUI","OPEN_SAWIT_GUI","OPEN_EGG_GUI","OPEN_FRUIT_GUI"
local SHOP_MODES = {
    {mode="sell",  label="💰 Jual Hasil Panen",  key="OPEN_SELL_GUI"},
    {mode="sawit", label="🌴 Jual Sawit",         key="OPEN_SAWIT_GUI"},
    {mode="egg",   label="🥚 Jual Telur",         key="OPEN_EGG_GUI"},
    {mode="fruit", label="🍎 Jual Buah",          key="OPEN_FRUIT_GUI"},
    {mode="tool",  label="🔧 Beli Alat",          key="OPEN_TOOL_GUI"},
}
local SelectedSellMode = "sell"

local BIBIT = {
    {name="Padi",       remote="Padi",       emoji="🌾", minLv=1,   harga=5},
    {name="Jagung",     remote="Jagung",      emoji="🌽", minLv=20,  harga=15},
    {name="Tomat",      remote="Tomat",       emoji="🍅", minLv=40,  harga=25},
    {name="Terong",     remote="Terong",      emoji="🍆", minLv=60,  harga=40},
    {name="Strawberry", remote="Strawberry",  emoji="🍓", minLv=80,  harga=60},
    {name="Sawit",      remote="Sawit",       emoji="🌴", minLv=80,  harga=1000},
    {name="Durian",     remote="Durian",      emoji="🥥", minLv=120, harga=2000},
}

local LAHAN_LIST = {
    {partName="AreaTanam Besar2", price=100000, label="Lahan Besar 2"},
    {partName="AreaTanam Besar3", price=200000, label="Lahan Besar 3"},
    {partName="AreaTanam Sawit1", price=150000, label="Lahan Sawit 1"},
    {partName="AreaTanam Sawit2", price=300000, label="Lahan Sawit 2"},
}

local selectedBibit  = "Padi"
local selectedRemote = "Padi"
local jumlahBeli     = 1
local Cooldown       = 1
local Jarak          = 3
local dBeli=2; local dTanam=2; local dPanen=3; local dJual=2; local waitPanen=30

local SiklusCount  = 0
local BeliLoop     = nil
local ESPObjects   = {}
local lightningHits = 0
local levelUpCount  = 0

local testRemoteName = ""
local testArg1       = ""

-- ============================================
-- UTILITY
-- ============================================

local function notif(judul, isi, dur)
    pcall(function()
        Rayfield:Notify({Title=judul, Content=isi, Duration=dur or 3, Image=4483362458})
    end)
    print("[XKID] "..judul.." — "..isi)
end

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getPos() local r=getRoot(); return r and r.Position end
local function getCF()  local r=getRoot(); return r and r.CFrame  end

local function tp(obj)
    if not obj then return false end
    local root = getRoot(); if not root then return false end
    local pos
    if typeof(obj)=="Vector3" then pos=obj
    elseif typeof(obj)=="CFrame" then root.CFrame=obj+Vector3.new(0,5,0); task.wait(0.3); return true
    elseif obj:IsA("BasePart") then pos=obj.Position
    elseif obj:IsA("Model") then
        pos = obj.PrimaryPart and obj.PrimaryPart.Position
           or (obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position)
           or (obj:FindFirstChild("Head") and obj.Head.Position)
    end
    if not pos then return false end
    root.CFrame = CFrame.new(pos.X, pos.Y+5, pos.Z)
    task.wait(0.3); return true
end

local function tpCoord(x,y,z)
    local r=getRoot(); if not r then return false end
    r.CFrame=CFrame.new(x,y+5,z); task.wait(0.3); return true
end

local function cari(nama)
    nama=nama:lower()
    for _,v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower()==nama then return v end
    end
end

local function findNearest(radius, keyword)
    local root=getRoot(); if not root then return nil end
    local nearest, minDist = nil, radius or 100
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("BasePart") then
            if not keyword or v.Name:lower():find(keyword:lower()) then
                local pos = v:IsA("BasePart") and v.Position
                         or (v.PrimaryPart and v.PrimaryPart.Position)
                if pos then
                    local d=(pos-root.Position).Magnitude
                    if d<minDist then minDist=d; nearest=v end
                end
            end
        end
    end
    return nearest
end

-- ============================================
-- REMOTE SYSTEM
-- ============================================

local remoteCache = {}
local function getRemote(name)
    if remoteCache[name] then return remoteCache[name] end
    for _,v in pairs(RS:GetDescendants()) do
        if v.Name==name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            remoteCache[name]=v; return v
        end
    end
end

local function fireR(name, ...)
    local r=getRemote(name)
    if not r then return false,"Remote not found: "..name end
    local ok,result=pcall(function(...)
        if r:IsA("RemoteEvent") then r:FireServer(...); return "Fired"
        else return r:InvokeServer(...) end
    end, ...)
    return ok, result
end

-- ============================================
-- PROXIMITY PROMPT
-- ============================================

local function getPPDekat(radius)
    radius=radius or 15
    local root=getRoot(); if not root then return nil end
    local best, bestD=nil, radius
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local par=v.Parent
            if par and par:IsA("BasePart") then
                local d=(par.Position-root.Position).Magnitude
                if d<bestD then best=v; bestD=d end
            end
        end
    end
    return best
end

local function firePrompt(prompt)
    if not prompt then return end
    pcall(function() fireproximityprompt(prompt) end)
    task.wait(0.1)
    pcall(function()
        local VIM=game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true,Enum.KeyCode.E,false,game); task.wait(0.1)
        VIM:SendKeyEvent(false,Enum.KeyCode.E,false,game)
    end)
end

-- ============================================
-- UI CLICK
-- ============================================

local function klikUI(tombol)
    if not tombol then return false end
    pcall(function()
        if tombol:IsA("GuiButton") then tombol.MouseButton1Click:Fire() end
    end)
    task.wait(0.05)
    pcall(function()
        local VIM=game:GetService("VirtualInputManager")
        local pos=tombol.AbsolutePosition+(tombol.AbsoluteSize/2)
        VIM:SendMouseButtonEvent(pos.X,pos.Y,0,true,game,0); task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X,pos.Y,0,false,game,0)
    end)
    task.wait(0.1); return true
end

-- Cari tombol di FarmGui berdasarkan keywords
local function cariFarmGuiTombol(keywords, onlyVisible)
    local pg = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not pg then return nil end
    local fg = pg:FindFirstChild("FarmGui") or pg
    for _,v in pairs(fg:GetDescendants()) do
        if v:IsA("TextButton") then
            if not onlyVisible or v.Visible then
                local t=v.Text:lower()
                for _,kw in ipairs(keywords) do
                    if t:find(kw) then return v end
                end
            end
        end
    end
end

-- Auto klik SEMUA tombol yang cocok keyword di FarmGui
local function autoKlikSemua(keywords)
    local pg=LocalPlayer:WaitForChild("PlayerGui",5)
    if not pg then return 0 end
    local fg=pg:FindFirstChild("FarmGui") or pg
    local count=0
    for _,v in pairs(fg:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local t=v.Text:lower()
            for _,kw in ipairs(keywords) do
                if t:find(kw) then klikUI(v); count=count+1; task.wait(0.2); break end
            end
        end
    end
    return count
end

-- Tutup semua GUI yang terbuka
local function tutupGUI()
    local pg=LocalPlayer:WaitForChild("PlayerGui",5)
    if not pg then return end
    local fg=pg:FindFirstChild("FarmGui") or pg
    for _,v in pairs(fg:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local t=v.Text:lower()
            if t:find("tutup") or t:find("close") or t=="x" or t=="✕" then
                klikUI(v); task.wait(0.1)
            end
        end
    end
end

-- ============================================
-- NPC INTERAKSI
-- ============================================

local function interakNPC(npcName, waitAfter)
    waitAfter=waitAfter or 1.5
    local npc=cari(npcName)
    if not npc then notif("NPC ❌",npcName.." tidak ditemukan!",3); return false end
    tp(npc); task.wait(0.8)
    local prompt=nil
    local si=npc:IsA("Model") and npc or npc.Parent
    for _,v in pairs(si:GetDescendants()) do
        if v:IsA("ProximityPrompt") then prompt=v; break end
    end
    if not prompt then prompt=getPPDekat(15) end
    if not prompt then notif("Prompt ❌","Tidak ada ProximityPrompt!",3); return false end
    firePrompt(prompt); task.wait(waitAfter); return true
end

-- ============================================
-- LAHAN CACHE
-- ============================================

local function cacheLahan(jenis)
    local data=LahanData[jenis]; if not data then return {} end
    local now=tick()
    if now-data.cacheTime<5 and #data.cache>0 then return data.cache end
    data.cache={}
    if data.pos then
        for _,v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n=v.Name:lower(); local match=false
                for _,kw in ipairs(data.keywords) do
                    if n:find(kw) then match=true; break end
                end
                if match and (v.Position-data.pos).Magnitude<=data.radius then
                    table.insert(data.cache,v)
                end
            end
        end
    end
    if #data.cache==0 and data.pos then
        for _,v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n=v.Name:lower()
                for _,kw in ipairs(data.keywords) do
                    if n:find(kw) then table.insert(data.cache,v); break end
                end
            end
        end
    end
    data.cacheTime=now; return data.cache
end

local function getLahan(j) return cacheLahan(j or ActiveFarmJenis) end

local function simpanPosLahan(jenis)
    local root=getRoot()
    if not root then notif("Error","Karakter belum ready!",3); return false end
    local data=LahanData[jenis]
    data.pos=root.Position; data.cache={}; data.cacheTime=0; cacheLahan(jenis)
    notif(data.label.." ✅",
        string.format("X=%.1f Z=%.1f\n%d lahan ditemukan",data.pos.X,data.pos.Z,#data.cache),4)
    return true
end

-- ============================================
-- ┌──────────────────────────────────────────┐
-- │  ✨ SYNC DATA — Baca data player asli     │
-- │  Dari decompile: SafeRemote.Invoke(SyncData)│
-- │  Return: Coins,Level,XP,Inventory,dll    │
-- └──────────────────────────────────────────┘
-- ============================================

local function syncPlayerData()
    local r = getRemote("SyncData")
    if not r then return false end
    local ok, data = pcall(function()
        if r:IsA("RemoteFunction") then
            return r:InvokeServer()
        end
    end)
    if ok and type(data)=="table" then
        PlayerData.Coins        = data.Coins        or PlayerData.Coins
        PlayerData.Level        = data.Level        or PlayerData.Level
        PlayerData.XP           = data.XP           or PlayerData.XP
        PlayerData.Needed       = data.Needed       or PlayerData.Needed
        PlayerData.Inventory    = data.Inventory    or PlayerData.Inventory
        PlayerData.OwnedTools   = data.OwnedTools   or PlayerData.OwnedTools
        PlayerData.TutorialDone = data.TutorialCompleted or false
        PlayerData.LastSync     = tick()
        return true
    end
    return false
end

-- ============================================
-- ┌──────────────────────────────────────────┐
-- │  AUTO BELI BIBIT — METODE BARU (FIX)      │
-- │  Dari Remote Spy:                         │
-- │  GetBibit [1]=0, [2]=false                │
-- │  → Server langsung buka GUI bibit         │
-- │  → TIDAK perlu TP ke NPC / ProxPrompt!    │
-- └──────────────────────────────────────────┘
-- ============================================

local function autoBeliBibit(bibit, jumlah)
    bibit  = bibit  or selectedBibit
    jumlah = jumlah or jumlahBeli

    -- Step 1: Fire GetBibit ke server dengan (0, false)
    -- Server akan balas kirim GetBibit ke client → buka ShopUI("bibit")
    local ok, res = fireR("GetBibit", 0, false)
    if not ok then
        notif("GetBibit ❌", "Remote gagal: "..tostring(res), 3)
        return false
    end

    -- Step 2: Tunggu GUI bibit terbuka
    task.wait(1.5)

    local gui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not gui then return false end

    -- Step 3: Atur jumlah (tombol +)
    if jumlah > 1 then
        local fg = gui:FindFirstChild("FarmGui") or gui
        for _, v in pairs(fg:GetDescendants()) do
            if v:IsA("TextButton") and v.Text == "+" and v.Visible then
                for i = 1, jumlah - 1 do
                    klikUI(v); task.wait(0.05)
                end
                break
            end
        end
        task.wait(0.2)
    end

    -- Step 4: Klik tombol Beli / Buy
    local berhasil = false
    local fg = gui:FindFirstChild("FarmGui") or gui
    for _, v in pairs(fg:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local t = v.Text:lower()
            if t:find("beli") or t:find("buy") then
                klikUI(v); berhasil = true; break
            end
        end
    end

    -- Step 5: Tutup GUI
    task.wait(0.3)
    tutupGUI()

    return berhasil
end

-- ============================================
-- ┌──────────────────────────────────────────┐
-- │  ✨ AUTO JUAL — METODE BARU (FIX)         │
-- │  Dari Scan Map: RequestSell = RemoteFunc  │
-- │  InvokeServer() → server buka GUI jual    │
-- │  TIDAK perlu TP ke NPC lagi!              │
-- │                                           │
-- │  Mode map (dari SellCrop intercept):      │
-- │  sell / sawit / egg / fruit / tool        │
-- └──────────────────────────────────────────┘
-- ============================================

-- Peta mode → remote yang dipakai
-- RequestSell  = jual hasil panen biasa
-- RequestShop  = buka shop bibit/tool
-- RequestToolShop = beli alat
local SELL_REMOTE_MAP = {
    sell  = "RequestSell",
    sawit = "RequestSell",
    egg   = "RequestSell",
    fruit = "RequestSell",
    tool  = "RequestToolShop",
}

local function autoJualMode(mode)
    mode = mode or SelectedSellMode
    local remoteName = SELL_REMOTE_MAP[mode] or "RequestSell"

    -- Step 1: InvokeServer ke RequestSell / RequestToolShop
    -- Server akan balas dengan membuka GUI jual (SellCrop.OnClientEvent)
    local ok, res = fireR(remoteName)
    if not ok then
        -- Fallback: coba RequestSell langsung
        ok, res = fireR("RequestSell")
        if not ok then
            notif("RequestSell ❌", "Remote gagal: "..tostring(res), 3)
            return false
        end
    end

    -- Step 2: Tunggu GUI terbuka (server kirim SellCrop OnClientEvent)
    task.wait(1.2)

    -- Step 3: Klik semua tombol jual
    local count = autoKlikSemua({"jual semua", "sell all", "jual all"})
    if count == 0 then
        count = autoKlikSemua({"jual", "sell"})
    end

    -- Step 4: Tutup GUI
    task.wait(0.3)
    tutupGUI()
    return count > 0
end

-- ============================================
-- AUTO PANEN
-- ============================================

local function autoPanen(jenis)
    local lahans=getLahan(jenis); local harvested=0
    for _,lahan in ipairs(lahans) do
        if not _G.AutoPanen and not _G.AutoFarm then break end
        pcall(function()
            tp(lahan); task.wait(0.5)
            local p=getPPDekat(10)
            if p then firePrompt(p); harvested=harvested+1 end
        end)
        task.wait(0.3)
    end
    return harvested
end

local function interakLahan(lahanObj, delayTime)
    delayTime=delayTime or 1.5
    if not lahanObj then return false end
    local ok=pcall(function()
        tp(lahanObj); task.wait(delayTime)
        local p=getPPDekat(10); if p then firePrompt(p) end
        task.wait(0.3)
        local gui=LocalPlayer:WaitForChild("PlayerGui",3)
        if gui then
            for _,v in pairs(gui:GetDescendants()) do
                if v:IsA("TextButton") and v.Visible then
                    local t=v.Text:lower()
                    if t:find("tanam") or t:find("plant") then klikUI(v); break end
                end
            end
        end
    end)
    return ok
end

-- ============================================
-- ┌──────────────────────────────────────────┐
-- │  ✨ BELI LAHAN dengan Auto Confirm        │
-- │  LahanUpdate + ConfirmAction auto return  │
-- └──────────────────────────────────────────┘
-- ============================================

local function beliLahan(partName, price)
    return fireR("LahanUpdate","CONFIRM_BUY",{["PartName"]=partName,["Price"]=price})
end

-- ============================================
-- ┌──────────────────────────────────────────┐
-- │  ✨ PLANT CROP — Remote langsung          │
-- │  Dari scan: PlantCrop (RemoteEvent)       │
-- │           PlantLahanCrop (RemoteEvent)    │
-- │  Tanam tanpa perlu klik GUI!              │
-- └──────────────────────────────────────────┘
-- ============================================

local function plantCropRemote(cropName, lahanPart)
    -- PlantLahanCrop untuk sawit/durian (lahan khusus)
    if cropName == "Sawit" or cropName == "Durian" then
        return fireR("PlantLahanCrop", cropName, lahanPart)
    end
    -- PlantCrop untuk tanaman biasa
    return fireR("PlantCrop", cropName, lahanPart)
end

-- ============================================
-- ┌──────────────────────────────────────────┐
-- │  ✨ SUMMON RAIN — Percepat tumbuh 1.5x!  │
-- │  Dari scan config: GrowthSpeedMultiplier │
-- │  = 1.5 saat hujan                        │
-- │  SummonRain = RemoteEvent                │
-- └──────────────────────────────────────────┘
-- ============================================

local function summonRain()
    local ok, res = fireR("SummonRain")
    return ok, res
end

-- ============================================
-- ┌──────────────────────────────────────────┐
-- │  ✨ REQUEST LAHAN — Beli/Info lahan        │
-- │  Dari scan: RequestLahan = RemoteFunction │
-- └──────────────────────────────────────────┘
-- ============================================

local function requestLahan(partName)
    return fireR("RequestLahan", partName)
end

-- ============================================
-- TELEPORT PANEN 3 TITIK
-- ============================================

local function teleportPanenLoop()
    local points={CopyPositions.Sawah,CopyPositions.Sawit,CopyPositions.Ternak}
    local index=1
    while _G.TeleportPanen do
        local point=points[index]
        if point then
            tp(point); task.wait(0.5)
            local p=getPPDekat(10); if p then firePrompt(p) end
            task.wait(Cooldown)
        end
        index=index+1; if index>3 then index=1 end
        if not _G.TeleportPanen then break end
        task.wait(Jarak)
    end
end

-- ============================================
-- DETECTOR SAWIT
-- ============================================

local function detectorSawitLoop()
    while _G.DetectorSawit do
        local s=findNearest(100,"sawit") or findNearest(100,"kelapa")
        if s then
            notif("Sawit!","Auto teleport...",2); tp(s); task.wait(0.5)
            local p=getPPDekat(10); if p then firePrompt(p) end
            task.wait(Cooldown)
        else task.wait(2) end
        if not _G.DetectorSawit then break end
    end
end

-- ============================================
-- ESP
-- ============================================

local function createESP(obj, color)
    if not obj then return end
    local hl=Instance.new("Highlight")
    hl.Name="XKIDESP"; hl.FillColor=color or Color3.fromRGB(0,255,0)
    hl.OutlineColor=Color3.fromRGB(255,255,255); hl.FillTransparency=0.5
    hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent=obj; table.insert(ESPObjects,hl)
end

local function clearESP()
    for _,e in pairs(ESPObjects) do pcall(function() e:Destroy() end) end
    ESPObjects={}
end

local function updateESP()
    clearESP()
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("BasePart") then
            local n=v.Name:lower()
            if n:find("crop") or n:find("tanaman") or n:find("padi") or n:find("jagung")
               or n:find("tomat") or n:find("sawit") or n:find("durian") then
                createESP(v,Color3.fromRGB(0,255,0))
            elseif n:find("npc") or n:find("toko") or n:find("pedagang") then
                createESP(v,Color3.fromRGB(255,255,0))
            elseif n:find("areatanambesar") or n:find("areatanamsawah") then
                createESP(v,Color3.fromRGB(0,170,255))
            elseif n:find("areatanamsawit") then
                createESP(v,Color3.fromRGB(0,255,128))
            elseif n:find("ternak") or n:find("kandang") then
                createESP(v,Color3.fromRGB(255,128,0))
            end
        end
    end
end

-- ============================================
-- STOP ALL
-- ============================================

local function stopSemua()
    _G.AutoFarm=false; _G.AutoBeli=false; _G.AutoTanam=false
    _G.AutoPanen=false; _G.AutoJual=false; _G.TeleportPanen=false
    _G.DetectorSawit=false
    if BeliLoop then pcall(function() task.cancel(BeliLoop) end); BeliLoop=nil end
    notif("⛔ STOP SEMUA!","Semua auto dimatikan",3)
end

-- ============================================
-- ┌══════════════════════════════════════════┐
-- ║  ✨ INTERCEPT CLIENT EVENTS               ║
-- ║  Dari decompile — sangat powerful!        ║
-- ╠══════════════════════════════════════════╣
-- ║  1. SellCrop → auto klik jual             ║
-- ║  2. GetBibit → auto klik beli             ║
-- ║  3. UpdateLevel → notif level up          ║
-- ║  4. ConfirmAction → auto return true      ║
-- ║  5. Notification → log ke console         ║
-- ║  6. LightningStrike → penangkal petir     ║
-- ╚══════════════════════════════════════════╝
-- ============================================

local interceptsSetup = false

local function setupIntercepts()
    if interceptsSetup then return end
    interceptsSetup = true

    -- ┌──────────────────────────────────────┐
    -- │ 1. SellCrop — intercept GUI jual      │
    -- │ p40=success, p41=mode/message         │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r = getRemote("SellCrop")
        if not r then task.wait(5); r=getRemote("SellCrop") end
        if not r then return end

        r.OnClientEvent:Connect(function(p40, p41)
            -- Log semua event
            print("[XKID INTERCEPT] SellCrop — p40="..tostring(p40).." p41="..tostring(p41))

            -- Auto sell saat GUI terbuka
            if _G.AutoSellIntercept then
                if p41 == "OPEN_SELL_GUI" or p41 == "OPEN_SAWIT_GUI"
                   or p41 == "OPEN_EGG_GUI" or p41 == "OPEN_FRUIT_GUI" then
                    task.wait(0.8) -- tunggu GUI muncul
                    local count = autoKlikSemua({"jual semua","sell all","jual all"})
                    if count == 0 then count = autoKlikSemua({"jual","sell"}) end
                    task.wait(0.5); tutupGUI()
                    if count > 0 then notif("Auto Sell ✅","GUI "..tostring(p41).." → "..count.." item dijual",3) end
                end
            end

            -- Notif hasil jual
            if p40 == true and type(p41)=="string" and not p41:find("OPEN_") then
                print("[XKID] Jual sukses: "..p41)
            elseif p40 == false then
                print("[XKID] Jual gagal: "..tostring(p41))
            end
        end)
        print("[XKID] ✅ SellCrop intercept aktif")
    end)

    -- ┌──────────────────────────────────────┐
    -- │ 2. GetBibit — intercept GUI bibit     │
    -- │ p42=qty, p43=isFree                   │
    -- │ if not p43 → buka shop bibit          │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r = getRemote("GetBibit")
        if not r then task.wait(5); r=getRemote("GetBibit") end
        if not r then return end

        r.OnClientEvent:Connect(function(p42, p43)
            print("[XKID INTERCEPT] GetBibit — qty="..tostring(p42).." isFree="..tostring(p43))

            if _G.AutoBeliIntercept then
                if not p43 then
                    -- GUI bibit terbuka, auto beli
                    task.wait(0.8)
                    local count = autoKlikSemua({"beli","buy"})
                    task.wait(0.3); tutupGUI()
                    if count > 0 then notif("Auto Beli ✅","GUI Bibit → "..count.." tombol diklik",3) end
                elseif p43 and p42 and p42 > 0 then
                    notif("🎁 Bibit Gratis!","Dapat "..p42.."x bibit gratis!",5)
                end
            end
        end)
        print("[XKID] ✅ GetBibit intercept aktif")
    end)

    -- ┌──────────────────────────────────────┐
    -- │ 3. UpdateLevel — track level up       │
    -- │ p={Level,XP,Needed,LeveledUp}         │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r = getRemote("UpdateLevel")
        if not r then task.wait(5); r=getRemote("UpdateLevel") end
        if not r then return end

        r.OnClientEvent:Connect(function(data)
            if type(data)~="table" then return end
            PlayerData.Level  = data.Level  or PlayerData.Level
            PlayerData.XP     = data.XP     or PlayerData.XP
            PlayerData.Needed = data.Needed or PlayerData.Needed

            print("[XKID INTERCEPT] UpdateLevel — Lv."..tostring(data.Level)
                .." XP:"..tostring(data.XP).."/"..tostring(data.Needed))

            if data.LeveledUp and _G.NotifLevelUp then
                levelUpCount = levelUpCount + 1
                notif("🎉 LEVEL UP! #"..levelUpCount,
                    "Sekarang Level "..tostring(data.Level).."! 🔥\nXP: "..tostring(data.XP).."/"..tostring(data.Needed), 6)
            end
        end)
        print("[XKID] ✅ UpdateLevel intercept aktif")
    end)

    -- ┌──────────────────────────────────────┐
    -- │ 4. ConfirmAction — auto confirm       │
    -- │ Server invoke client untuk konfirmasi │
    -- │ Return true = konfirm, false = batal  │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r = getRemote("ConfirmAction")
        if not r then task.wait(5); r=getRemote("ConfirmAction") end
        if not r then return end

        if r:IsA("RemoteFunction") then
            r.OnClientInvoke = function(data)
                print("[XKID INTERCEPT] ConfirmAction — data="..tostring(data)
                    .." AutoConfirm="..tostring(_G.AutoConfirm))
                if _G.AutoConfirm then
                    notif("✅ Auto Confirm!","Konfirmasi otomatis: "..tostring(data),2)
                    return true
                end
                -- Default: buka GUI konfirm normal
                return nil
            end
        end
        print("[XKID] ✅ ConfirmAction intercept aktif")
    end)

    -- ┌──────────────────────────────────────┐
    -- │ 5. Notification — log semua notif     │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r = getRemote("Notification")
        if not r then task.wait(5); r=getRemote("Notification") end
        if not r then return end

        r.OnClientEvent:Connect(function(msg)
            print("[XKID NOTIF] "..tostring(msg))
        end)
        print("[XKID] ✅ Notification intercept aktif")
    end)

    -- ┌──────────────────────────────────────┐
    -- │ 6. LightningStrike — penangkal petir  │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r = getRemote("LightningStrike")
        if not r then task.wait(5); r=getRemote("LightningStrike") end
        if not r then return end

        r.OnClientEvent:Connect(function(data)
            print("[XKID INTERCEPT] LightningStrike! Reason="..tostring(data and data.Reason))
            if not _G.PenangkalPetir then return end
            lightningHits = lightningHits + 1
            local root = getRoot()
            if root then
                if SafePos then
                    root.CFrame = CFrame.new(SafePos.X, SafePos.Y+5, SafePos.Z)
                    notif("⚡ PETIR DITANGKAL ✅","TP ke Safe Pos! #"..lightningHits,3)
                else
                    root.CFrame = root.CFrame + Vector3.new(0, 60, 0)
                    notif("⚡ PETIR!","Set Safe Pos untuk proteksi penuh!",3)
                end
            end
        end)
        print("[XKID] ✅ LightningStrike intercept aktif")
    end)

    -- ┌──────────────────────────────────────┐
    -- │ 7. HarvestCrop — log saat panen       │
    -- │ (server→client: play sound only)      │
    -- └──────────────────────────────────────┘
    task.spawn(function()
        local r = getRemote("HarvestCrop")
        if not r then task.wait(5); r=getRemote("HarvestCrop") end
        if not r then return end
        r.OnClientEvent:Connect(function()
            print("[XKID INTERCEPT] HarvestCrop — sound played by server")
        end)
        print("[XKID] ✅ HarvestCrop intercept aktif")
    end)

    print("[XKID] === SEMUA INTERCEPT SIAP ===")
end

-- ============================================
-- TABS
-- ============================================
local TabStatus  = Window:CreateTab("📊 Status",       nil)
local TabPlayer  = Window:CreateTab("👤 Player Info",  nil)
local TabBibit   = Window:CreateTab("🛒 Beli Bibit",   nil)
local TabJual    = Window:CreateTab("💰 Jual",         nil)
local TabFarm    = Window:CreateTab("🤖 Auto Farm",    nil)
local TabLahan   = Window:CreateTab("🌾 Posisi Lahan", nil)
local TabCopy    = Window:CreateTab("📋 Copy TP",      nil)
local TabTanam   = Window:CreateTab("🌴 Tanam",        nil)
local TabHujan   = Window:CreateTab("🌧 Hujan",        nil)  -- ✨ NEW SummonRain
local TabTP      = Window:CreateTab("🚀 Teleport",     nil)
local TabPetir   = Window:CreateTab("⚡ Petir",        nil)
local TabESP     = Window:CreateTab("👁 ESP",          nil)
local TabTools   = Window:CreateTab("🛠 Tools",        nil)
local TabSet     = Window:CreateTab("⚙ Setting",      nil)
local TabTest    = Window:CreateTab("🧪 Test Remote",  nil)

-- ============================================
-- TAB STATUS
-- ============================================
TabStatus:CreateSection("📊 Live Status")

local StFarm    = TabStatus:CreateParagraph({Title="Auto Farm",           Content="🔴 OFF"})
local StBeli    = TabStatus:CreateParagraph({Title="Auto Beli",           Content="🔴 OFF"})
local StPlayer  = TabStatus:CreateParagraph({Title="👤 Player",           Content="Loading..."})
local StLahan   = TabStatus:CreateParagraph({Title="Posisi Lahan",        Content="Belum disimpan"})
local StPetir   = TabStatus:CreateParagraph({Title="⚡ Petir",            Content="🔴 OFF"})
local StIntercept = TabStatus:CreateParagraph({Title="✨ Intercept",      Content="Setup..."})
local StSiklus  = TabStatus:CreateParagraph({Title="Siklus",              Content="0 siklus"})

task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            StFarm:Set({Title="Auto Farm",
                Content=_G.AutoFarm and ("🟢 RUNNING — Siklus "..SiklusCount.." — "..ActiveFarmJenis) or "🔴 OFF"})
            StBeli:Set({Title="Auto Beli",
                Content=_G.AutoBeli and ("🟢 RUNNING — "..selectedBibit.." x"..jumlahBeli) or "🔴 OFF"})
            StPlayer:Set({Title="👤 Player — "..myName,
                Content="💰 Coins: "..PlayerData.Coins
                    .."\n⭐ Level: "..PlayerData.Level
                    .." | XP: "..PlayerData.XP.."/"..PlayerData.Needed
                    .."\n🎉 Level Up: "..levelUpCount.."x"
                    ..(PlayerData.LastSync>0 and "\n🔄 Sync: "..string.format("%.0fs ago", tick()-PlayerData.LastSync) or "\n🔄 Sync: belum")})
            local lahanInfo=""
            for j,d in pairs(LahanData) do
                lahanInfo=lahanInfo..d.label..(d.pos and (" ✅ "..#d.cache.." lahan\n") or " ❌\n")
            end
            StLahan:Set({Title="Posisi Lahan", Content=lahanInfo})
            StPetir:Set({Title="⚡ Penangkal Petir",
                Content=(_G.PenangkalPetir and "🟢 AKTIF" or "🔴 OFF")
                    .." | "..lightningHits.."x ditangkal"
                    ..(SafePos and " | SafePos ✅" or " | SafePos ❌")})
            StIntercept:Set({Title="✨ Intercept Events",
                Content="SellCrop: "..((_G.AutoSellIntercept) and "🟢" or "⚪")
                    .." | GetBibit: "..((_G.AutoBeliIntercept) and "🟢" or "⚪")
                    .."\nConfirmAction: "..((_G.AutoConfirm) and "🟢 AUTO" or "⚪ manual")
                    .."\nLevelUp Notif: "..((_G.NotifLevelUp) and "🟢" or "⚪")})
            StSiklus:Set({Title="Siklus Farm", Content=SiklusCount.." siklus — "..ActiveFarmJenis})
        end)
        task.wait(1)
    end
end)

-- ============================================
-- ✨ TAB PLAYER INFO (dari SyncData)
-- ============================================
TabPlayer:CreateSection("👤 Data Player (SyncData)")

TabPlayer:CreateParagraph({
    Title="Info",
    Content="Data diambil langsung dari server\nmenggunakan SyncData remote (hasil decompile)\nData real-time dan akurat!"
})

local PlayerInfoPara = TabPlayer:CreateParagraph({Title="Data Player", Content="Belum di-sync"})
local InventoryPara  = TabPlayer:CreateParagraph({Title="Inventory",   Content="Belum di-sync"})
local ToolsPara      = TabPlayer:CreateParagraph({Title="Owned Tools", Content="Belum di-sync"})

TabPlayer:CreateButton({Name="🔄 SYNC DATA SEKARANG",
    Callback=function()
        task.spawn(function()
            notif("Syncing...","Mengambil data dari server...",2)
            local ok=syncPlayerData()
            if ok then
                PlayerInfoPara:Set({Title="Data Player",
                    Content="💰 Coins: "..PlayerData.Coins
                        .."\n⭐ Level: "..PlayerData.Level
                        .."\n📊 XP: "..PlayerData.XP.."/"..PlayerData.Needed
                        .."\n🎓 Tutorial: "..(PlayerData.TutorialDone and "Selesai ✅" or "Belum ❌")})

                local inv=""
                if type(PlayerData.Inventory)=="table" then
                    for k,v in pairs(PlayerData.Inventory) do
                        inv=inv..tostring(k)..": "..tostring(v).."\n"
                    end
                end
                InventoryPara:Set({Title="Inventory", Content=inv~="" and inv or "Kosong"})

                local tools=""
                if type(PlayerData.OwnedTools)=="table" then
                    for _,t in pairs(PlayerData.OwnedTools) do
                        tools=tools.."✅ "..tostring(t).."\n"
                    end
                end
                ToolsPara:Set({Title="Owned Tools", Content=tools~="" and tools or "Tidak ada"})

                notif("Sync Berhasil ✅","Data player diperbarui!",3)
            else
                notif("Sync Gagal ❌","SyncData remote tidak ditemukan",3)
            end
        end)
    end})

TabPlayer:CreateSection("✨ Intercept Events")

TabPlayer:CreateParagraph({
    Title="Penjelasan Intercept",
    Content="Script intercept event dari server:\n\n"
        .."🔵 SellCrop → auto klik jual saat GUI terbuka\n"
        .."🔵 GetBibit → auto klik beli saat GUI bibit terbuka\n"
        .."🔵 UpdateLevel → notifikasi saat level naik\n"
        .."🔵 ConfirmAction → auto konfirm beli lahan dll\n"
        .."🔵 LightningStrike → penangkal petir\n\n"
        .."Semua berdasarkan decompile script asli game!"
})

TabPlayer:CreateToggle({Name="🔵 Auto Sell Intercept (saat GUI jual terbuka)", CurrentValue=false,
    Callback=function(v)
        _G.AutoSellIntercept=v
        notif("Auto Sell Intercept", v and "ON ✅" or "OFF",2)
    end})

TabPlayer:CreateToggle({Name="🔵 Auto Beli Intercept (saat GUI bibit terbuka)", CurrentValue=false,
    Callback=function(v)
        _G.AutoBeliIntercept=v
        notif("Auto Beli Intercept", v and "ON ✅" or "OFF",2)
    end})

TabPlayer:CreateToggle({Name="✅ Auto Confirm (beli lahan dll)", CurrentValue=false,
    Callback=function(v)
        _G.AutoConfirm=v
        notif("Auto Confirm", v and "ON ✅ — Semua konfirmasi otomatis!" or "OFF",3)
    end})

TabPlayer:CreateToggle({Name="🎉 Notif Level Up", CurrentValue=true,
    Callback=function(v)
        _G.NotifLevelUp=v
        notif("Notif Level Up", v and "ON ✅" or "OFF",2)
    end})

-- ============================================
-- TAB BELI BIBIT
-- ============================================
TabBibit:CreateSection("🌱 Pilih Bibit")

local opsiBibit={}
for _,b in ipairs(BIBIT) do
    table.insert(opsiBibit, b.emoji.." "..b.name.." Lv."..b.minLv.." | "..b.harga.."💰")
end

TabBibit:CreateDropdown({
    Name="Jenis Bibit", Options=opsiBibit, CurrentOption={opsiBibit[1]},
    Callback=function(v)
        for _,b in ipairs(BIBIT) do
            if v[1]:find(b.name) then
                selectedBibit=b.name; selectedRemote=b.remote
                notif("Dipilih",b.emoji.." "..b.name,2); break
            end
        end
    end})

TabBibit:CreateSlider({Name="Jumlah Beli", Range={1,99}, Increment=1, CurrentValue=1,
    Callback=function(v) jumlahBeli=v end})

TabBibit:CreateSection("🛒 Beli Manual")

TabBibit:CreateButton({Name="💰 BELI SEKARANG",
    Callback=function()
        task.spawn(function()
            notif("Membeli",jumlahBeli.."x "..selectedBibit,2)
            local ok=autoBeliBibit(selectedBibit,jumlahBeli)
            notif(ok and "Sukses ✅" or "Gagal ❌", ok and "Berhasil" or "Coba lagi",3)
        end) end})

TabBibit:CreateSection("⚡ Beli Cepat")
for _,b in ipairs(BIBIT) do
    TabBibit:CreateButton({Name=b.emoji.." "..b.name.." | "..b.harga.."💰",
        Callback=function()
            task.spawn(function()
                selectedBibit=b.name; selectedRemote=b.remote
                autoBeliBibit(b.name,jumlahBeli)
            end) end})
end

TabBibit:CreateSection("🔄 Auto Beli Loop")
TabBibit:CreateParagraph({
    Title="✅ Metode Baru (Remote Spy)",
    Content="Fire GetBibit(0, false) → server buka GUI bibit\n→ Script auto klik beli\n\nTidak perlu TP ke NPC lagi! 🎉"})
TabBibit:CreateToggle({Name="🛒 Auto Beli Bibit", CurrentValue=false,
    Callback=function(v)
        _G.AutoBeli=v
        if v then
            notif("Auto Beli ON ✅",selectedBibit.." x"..jumlahBeli,3)
            BeliLoop=task.spawn(function()
                while _G.AutoBeli do
                    -- Langsung fire GetBibit(0, false) — tidak perlu TP ke NPC!
                    local ok=autoBeliBibit(selectedBibit,jumlahBeli)
                    if ok then notif("Auto Beli ✅",selectedBibit.." x"..jumlahBeli,2) end
                    task.wait(10)
                end
            end)
        else
            if BeliLoop then pcall(function() task.cancel(BeliLoop) end); BeliLoop=nil end
            notif("Auto Beli OFF","",2)
        end end})

-- ============================================
-- ✨ TAB JUAL (ShopUI Mode dari decompile)
-- ============================================
TabJual:CreateSection("💰 Mode Jual (RequestSell — Scan Map)")

TabJual:CreateParagraph({
    Title="✅ Metode Baru (Scan Map)",
    Content="Dari scan: RequestSell = RemoteFunction\n"
        .."InvokeServer() → server buka GUI jual\n"
        .."TIDAK perlu TP ke NPC lagi! 🎉\n\n"
        .."💰 sell  → RequestSell\n"
        .."🌴 sawit → RequestSell\n"
        .."🥚 egg   → RequestSell\n"
        .."🍎 fruit → RequestSell\n"
        .."🔧 tool  → RequestToolShop"
})

local opsiMode={}
for _,m in ipairs(SHOP_MODES) do table.insert(opsiMode, m.label) end

TabJual:CreateDropdown({
    Name="Mode Jual", Options=opsiMode, CurrentOption={opsiMode[1]},
    Callback=function(v)
        for _,m in ipairs(SHOP_MODES) do
            if v[1]:find(m.label:sub(4)) then
                SelectedSellMode=m.mode
                notif("Mode Jual",m.label,2); break
            end
        end
    end})

TabJual:CreateSection("🛒 Jual Manual per Mode")

for _,m in ipairs(SHOP_MODES) do
    if m.mode ~= "tool" then  -- tool bukan untuk jual
        TabJual:CreateButton({Name=m.label,
            Callback=function()
                task.spawn(function()
                    notif("Membuka "..m.label,"Interak NPC...",2)
                    local ok=autoJualMode(m.mode)
                    notif(ok and "Jual ✅" or "Gagal ❌", ok and m.label.." berhasil" or "Coba lagi",3)
                end) end})
    end
end

TabJual:CreateSection("💰 Jual Semua (Semua Mode)")

TabJual:CreateButton({Name="💰 JUAL SEMUA — Semua Jenis",
    Callback=function()
        task.spawn(function()
            notif("Jual Semua","Menjual semua jenis...",3)
            local total=0
            for _,m in ipairs(SHOP_MODES) do
                if m.mode~="tool" then
                    local ok=autoJualMode(m.mode)
                    if ok then total=total+1 end
                    task.wait(2)
                end
            end
            notif("Jual Selesai ✅",total.." mode berhasil dijual",4)
        end) end})

TabJual:CreateSection("🔄 Auto Jual Loop")

TabJual:CreateToggle({Name="💰 Auto Jual Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoJual=v
        if v then
            task.spawn(function()
                while _G.AutoJual do
                    pcall(function() autoJualMode(SelectedSellMode) end)
                    task.wait(dJual+5)
                end
            end)
            notif("Auto Jual ON ✅",SelectedSellMode,2)
        else notif("Auto Jual OFF","",2) end
    end})

-- ============================================
-- TAB AUTO FARM
-- ============================================
TabFarm:CreateSection("🎯 Pilih Jenis Lahan")

TabFarm:CreateDropdown({
    Name="Lahan Auto Farm", Options={"🌾 Sawah","🌴 Sawit","🐄 Ternak"}, CurrentOption={"🌾 Sawah"},
    Callback=function(v)
        if v[1]:find("Sawah")  then ActiveFarmJenis="Sawah"  end
        if v[1]:find("Sawit")  then ActiveFarmJenis="Sawit"  end
        if v[1]:find("Ternak") then ActiveFarmJenis="Ternak" end
        notif("Lahan Farm",ActiveFarmJenis,2)
    end})

TabFarm:CreateParagraph({
    Title="⚠️ PENTING",
    Content="1. Tab 🌾 Posisi Lahan → Simpan posisi\n2. Pilih jenis lahan di atas\n3. Aktifkan Full Auto Farm\n\n💡 Aktifkan Auto Confirm di Tab 👤 Player Info\nagar beli lahan otomatis terkonfirmasi!"
})

TabFarm:CreateSection("⏱ Delay")
TabFarm:CreateSlider({Name="Delay Beli (s)",   Range={1,10},  Increment=0.5, CurrentValue=2,  Callback=function(v) dBeli=v    end})
TabFarm:CreateSlider({Name="Delay Tanam (s)",  Range={1,10},  Increment=0.5, CurrentValue=2,  Callback=function(v) dTanam=v   end})
TabFarm:CreateSlider({Name="Delay Panen (s)",  Range={1,10},  Increment=0.5, CurrentValue=3,  Callback=function(v) dPanen=v   end})
TabFarm:CreateSlider({Name="Delay Jual (s)",   Range={1,10},  Increment=0.5, CurrentValue=2,  Callback=function(v) dJual=v    end})
TabFarm:CreateSlider({Name="Tunggu Panen (s)", Range={10,300},Increment=5,   CurrentValue=30, Callback=function(v) waitPanen=v end})

TabFarm:CreateSection("🔥 FULL AUTO FARM")

TabFarm:CreateToggle({
    Name="🔥 FULL AUTO: Beli → Tanam → Panen → Jual", CurrentValue=false,
    Callback=function(v)
        _G.AutoFarm=v
        if v then
            if not LahanData[ActiveFarmJenis].pos then
                notif("⚠️ ERROR!","Simpan posisi "..ActiveFarmJenis.." dulu!",7)
                _G.AutoFarm=false; return
            end
            SiklusCount=0; notif("AUTO FARM ON ✅","Jenis: "..ActiveFarmJenis.." 🔥",3)
            task.spawn(function()
                while _G.AutoFarm do
                    SiklusCount=SiklusCount+1
                    -- Step 1: Beli
                    notif("Siklus #"..SiklusCount,"Step 1: Beli bibit...",2)
                    pcall(function() autoBeliBibit(selectedBibit,jumlahBeli) end)
                    if not _G.AutoFarm then break end; task.wait(dBeli)
                    -- Step 2: Tanam
                    notif("Siklus #"..SiklusCount,"Step 2: Tanam "..ActiveFarmJenis.."...",2)
                    local lahans=getLahan(ActiveFarmJenis)
                    if #lahans==0 then notif("⚠️ Lahan 0!","Tidak ada lahan "..ActiveFarmJenis,5) end
                    for _,lahan in ipairs(lahans) do
                        if not _G.AutoFarm then break end
                        pcall(function() interakLahan(lahan,dTanam) end); task.wait(0.5)
                    end
                    if not _G.AutoFarm then break end
                    -- Step 3: Tunggu
                    notif("Siklus #"..SiklusCount,"Step 3: Tunggu "..waitPanen.."s...",3)
                    local w=0
                    while w<waitPanen and _G.AutoFarm do task.wait(1); w=w+1 end
                    if not _G.AutoFarm then break end
                    -- Step 4: Panen
                    notif("Siklus #"..SiklusCount,"Step 4: Panen "..ActiveFarmJenis.."...",2)
                    pcall(function() autoPanen(ActiveFarmJenis) end)
                    if not _G.AutoFarm then break end; task.wait(dPanen)
                    -- Step 5: Jual
                    notif("Siklus #"..SiklusCount,"Step 5: Jual...",2)
                    pcall(function() autoJualMode(SelectedSellMode) end)
                    if not _G.AutoFarm then break end; task.wait(dJual)
                    notif("✅ Siklus #"..SiklusCount,"Selesai!",3); task.wait(2)
                end
                notif("AUTO FARM","Stopped di siklus "..SiklusCount,3)
            end)
        else notif("AUTO FARM OFF","",2) end
    end})

TabFarm:CreateSection("🎯 Auto Satuan")
TabFarm:CreateToggle({Name="Auto Tanam Saja", CurrentValue=false,
    Callback=function(v) _G.AutoTanam=v; if v then task.spawn(function()
        while _G.AutoTanam do
            for _,l in ipairs(getLahan(ActiveFarmJenis)) do
                if not _G.AutoTanam then break end
                pcall(function() interakLahan(l,dTanam) end); task.wait(0.5)
            end; task.wait(3)
        end end) end end})

TabFarm:CreateToggle({Name="Auto Panen Saja", CurrentValue=false,
    Callback=function(v) _G.AutoPanen=v; if v then task.spawn(function()
        while _G.AutoPanen do pcall(function() autoPanen(ActiveFarmJenis) end); task.wait(5) end
    end) end end})

TabFarm:CreateSection("🛑 Emergency")
TabFarm:CreateButton({Name="🛑 STOP SEMUA AUTO", Callback=function() stopSemua() end})

-- ============================================
-- TAB POSISI LAHAN
-- ============================================
TabLahan:CreateSection("💾 Simpan Posisi Per Jenis")

TabLahan:CreateParagraph({Title="📌 Cara Pakai",
    Content="1. Berdiri di TENGAH lahan\n2. Tekan SIMPAN sesuai jenis\n3. Sawit TIDAK akan nyasar ke Sawah!"})

TabLahan:CreateButton({Name="💾 SIMPAN POSISI SAWAH 🌾",  Callback=function() simpanPosLahan("Sawah")  end})
TabLahan:CreateSlider({Name="Radius Sawah",  Range={10,200},Increment=10,CurrentValue=50,
    Callback=function(v) LahanData.Sawah.radius=v; LahanData.Sawah.cacheTime=0; cacheLahan("Sawah") end})
TabLahan:CreateButton({Name="💾 SIMPAN POSISI SAWIT 🌴",  Callback=function() simpanPosLahan("Sawit")  end})
TabLahan:CreateSlider({Name="Radius Sawit",  Range={10,200},Increment=10,CurrentValue=50,
    Callback=function(v) LahanData.Sawit.radius=v; LahanData.Sawit.cacheTime=0; cacheLahan("Sawit") end})
TabLahan:CreateButton({Name="💾 SIMPAN POSISI TERNAK 🐄", Callback=function() simpanPosLahan("Ternak") end})
TabLahan:CreateSlider({Name="Radius Ternak", Range={10,200},Increment=10,CurrentValue=50,
    Callback=function(v) LahanData.Ternak.radius=v; LahanData.Ternak.cacheTime=0; cacheLahan("Ternak") end})

TabLahan:CreateSection("📊 Tools")
TabLahan:CreateButton({Name="📊 Info Semua Lahan",
    Callback=function()
        local msg=""
        for j,d in pairs(LahanData) do
            if d.pos then
                msg=msg..d.label.." ✅\n"
                msg=msg..string.format("  X=%.1f Z=%.1f — %d lahan\n",d.pos.X,d.pos.Z,#d.cache)
            else msg=msg..d.label.." ❌\n" end
        end
        notif("Info Lahan",msg,8)
    end})

TabLahan:CreateButton({Name="🔄 Refresh Cache",
    Callback=function()
        local msg=""
        for j in pairs(LahanData) do
            LahanData[j].cacheTime=0; cacheLahan(j)
            msg=msg..j..": "..#LahanData[j].cache.." lahan\n"
        end
        notif("Refresh ✅",msg,4)
    end})

TabLahan:CreateButton({Name="🗑 Hapus Semua Posisi",
    Callback=function()
        for _,d in pairs(LahanData) do d.pos=nil; d.cache={}; d.cacheTime=0 end
        notif("Reset ✅","Semua posisi dihapus",3)
    end})

TabLahan:CreateSection("🏞 Beli Lahan (LahanUpdate + Auto Confirm)")

TabLahan:CreateParagraph({Title="Info",
    Content="Menggunakan LahanUpdate remote\nAktifkan Auto Confirm di Tab 👤 Player Info\nagar tidak perlu konfirmasi manual!"})

for _,l in ipairs(LAHAN_LIST) do
    TabLahan:CreateButton({Name="🏞 Beli "..l.label.." | "..l.price.."💰",
        Callback=function()
            task.spawn(function()
                local ok,res=beliLahan(l.partName,l.price)
                notif(ok and "Beli Lahan ✅" or "Gagal ❌",
                    ok and l.label.." berhasil!" or tostring(res),4)
            end) end})
end

-- ============================================
-- TAB COPY TP
-- ============================================
TabCopy:CreateSection("📍 Simpan 3 Titik Teleport")
TabCopy:CreateButton({Name="📍 COPY SAWAH",
    Callback=function() local p=getPos(); if p then CopyPositions.Sawah=p
        notif("Copy Sawah ✅",string.format("X=%.1f Z=%.1f",p.X,p.Z),3) end end})
TabCopy:CreateButton({Name="🌴 COPY SAWIT",
    Callback=function() local p=getPos(); if p then CopyPositions.Sawit=p
        notif("Copy Sawit ✅",string.format("X=%.1f Z=%.1f",p.X,p.Z),3) end end})
TabCopy:CreateButton({Name="🐄 COPY TERNAK",
    Callback=function() local p=getPos(); if p then CopyPositions.Ternak=p
        notif("Copy Ternak ✅",string.format("X=%.1f Z=%.1f",p.X,p.Z),3) end end})
TabCopy:CreateButton({Name="🗑 Reset Copy",
    Callback=function() CopyPositions.Sawah=nil; CopyPositions.Sawit=nil; CopyPositions.Ternak=nil
        notif("Reset ✅","",3) end})

TabCopy:CreateSection("🚀 Teleport Panen Loop")
TabCopy:CreateToggle({Name="🚀 Teleport Panen (3 Titik)", CurrentValue=false,
    Callback=function(v)
        _G.TeleportPanen=v
        if v then
            if not CopyPositions.Sawah and not CopyPositions.Sawit and not CopyPositions.Ternak then
                notif("ERROR ❌","Copy minimal 1 titik!",4); _G.TeleportPanen=false; return
            end
            task.spawn(teleportPanenLoop); notif("TP Panen ON ✅","",2)
        else notif("TP Panen OFF","",2) end
    end})

-- ============================================
-- TAB TANAM
-- ============================================
TabTanam:CreateSection("🌴 Tanam Sawit")
TabTanam:CreateButton({Name="📍 COPY POSISI SAWIT",
    Callback=function() local cf=getCF(); if cf then TanamPositions.Sawit=cf; notif("Copy ✅","Tersimpan",3) end end})
TabTanam:CreateButton({Name="🌴 TANAM SAWIT",
    Callback=function()
        if TanamPositions.Sawit then
            tp(TanamPositions.Sawit); task.wait(0.5)
            local p=getPPDekat(10); if p then firePrompt(p) end
            notif("Tanam Sawit ✅","Berhasil!",2)
        else notif("Error ❌","Copy posisi dulu!",3) end end})

TabTanam:CreateSection("🥥 Tanam Durian")
TabTanam:CreateButton({Name="📍 COPY POSISI DURIAN",
    Callback=function() local cf=getCF(); if cf then TanamPositions.Durian=cf; notif("Copy ✅","Tersimpan",3) end end})
TabTanam:CreateButton({Name="🥥 TANAM DURIAN",
    Callback=function()
        if TanamPositions.Durian then
            tp(TanamPositions.Durian); task.wait(0.5)
            local p=getPPDekat(10); if p then firePrompt(p) end
            notif("Tanam Durian ✅","Berhasil!",2)
        else notif("Error ❌","Copy posisi dulu!",3) end end})

TabTanam:CreateSection("🔍 Detector")
TabTanam:CreateToggle({Name="🔍 Detector Sawit", CurrentValue=false,
    Callback=function(v) _G.DetectorSawit=v
        if v then task.spawn(detectorSawitLoop); notif("Detector ON ✅","",3)
        else notif("Detector OFF","",2) end end})

-- ============================================
-- ✨ TAB HUJAN (SummonRain — dari scan map)
-- ============================================
TabHujan:CreateSection("🌧 Summon Rain")

TabHujan:CreateParagraph({
    Title="Kegunaan Hujan 🌧",
    Content="Dari scan RainConfig:\n"
        .."⚡ GrowthSpeedMultiplier = 1.5x\n"
        .."Tanaman tumbuh 50% lebih cepat saat hujan!\n\n"
        .."Duration: 120–180 detik\n"
        .."Interval normal: 300–600 detik\n\n"
        .."Remote: SummonRain (RemoteEvent)\n"
        .."Fire ke server → hujan langsung turun!"
})

TabHujan:CreateButton({Name="🌧 SUMMON RAIN SEKARANG!",
    Callback=function()
        task.spawn(function()
            local ok, res = summonRain()
            notif(ok and "Hujan ✅" or "Gagal ❌",
                ok and "Hujan dipanggil! Tumbuh 1.5x lebih cepat 🔥" or tostring(res), 4)
        end)
    end})

TabHujan:CreateSection("⏱ Auto Summon Rain Loop")

TabHujan:CreateParagraph({
    Title="Auto Rain Loop",
    Content="Summon rain setiap X detik\nPastikan server mengizinkan summon!"
})

local rainInterval = 150
TabHujan:CreateSlider({Name="Interval Summon (s)", Range={30,600}, Increment=30, CurrentValue=150,
    Callback=function(v) rainInterval=v end})

TabHujan:CreateToggle({Name="🌧 Auto Summon Rain Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoRain = v
        if v then
            task.spawn(function()
                while _G.AutoRain do
                    local ok = pcall(summonRain)
                    if ok then notif("🌧 Rain!","Hujan dipanggil! 1.5x growth",3) end
                    task.wait(rainInterval)
                end
            end)
            notif("Auto Rain ON ✅","Interval: "..rainInterval.."s",3)
        else
            notif("Auto Rain OFF","",2)
        end
    end})

TabHujan:CreateSection("🌾 Info Lahan Config")

TabHujan:CreateParagraph({
    Title="Lahan Config (dari scan)",
    Content="AreaPrefix: AreaTanamBesar\n"
        .."Total Areas: 32\n"
        .."Buy Price: 100,000 💰\n"
        .."Max Crops per Type: 1\n"
        .."Max Total Crops: 2\n"
        .."Prompt Distance: 12 studs\n\n"
        .."Special: Sawit & Durian\n"
        .."→ pakai PlantLahanCrop remote"
})

-- ============================================
-- TAB TELEPORT
-- ============================================
TabTP:CreateSection("🏪 NPC Toko")
local npcList = {
    {name="npcbibit",         label="🌱 Beli Bibit"},
    {name="npcpenjual",       label="💰 Jual Hasil"},
    {name="npcalat",          label="🔧 Beli Alat"},
    {name="NPCPedagangTelur", label="🥚 Jual Telur"},
    {name="NPCPedagangSawit", label="🌴 Jual Sawit"},
}
for _,npc in ipairs(npcList) do
    TabTP:CreateButton({Name=npc.label,
        Callback=function()
            local o=cari(npc.name)
            if o then tp(o); notif("TP ✅",npc.label,2)
            else notif("Error ❌",npc.name.." tidak ada",3) end
        end})
end
TabTP:CreateSection("🌾 Ke Lahan Tersimpan")
for jenis,data in pairs(LahanData) do
    TabTP:CreateButton({Name="🏠 Ke Lahan "..jenis,
        Callback=function()
            if data.pos then tpCoord(data.pos.X,data.pos.Y,data.pos.Z); notif("TP ✅","Di lahan "..jenis,2)
            else notif("Error ❌","Simpan posisi "..jenis.." dulu!",3) end
        end})
end

-- ============================================
-- TAB PETIR
-- ============================================
TabPetir:CreateSection("⚡ Penangkal Petir")
TabPetir:CreateParagraph({Title="Cara Kerja",
    Content="Intercept LightningStrike.OnClientEvent\nSebelum damage dihitung → TP ke Safe Pos\n\n⚠️ Set Safe Position dulu!\n(di dalam bangunan / berteduh)"})
TabPetir:CreateButton({Name="📍 SET SAFE POSITION",
    Callback=function()
        local p=getPos(); if p then SafePos=p
            notif("Safe Pos ✅",string.format("X=%.1f Y=%.1f Z=%.1f\nSiap ditangkal!",p.X,p.Y,p.Z),4)
        end end})
TabPetir:CreateToggle({Name="⚡ Penangkal Petir AKTIF", CurrentValue=false,
    Callback=function(v) _G.PenangkalPetir=v
        notif("Penangkal Petir", v and "ON ✅" or "OFF",2) end})
TabPetir:CreateButton({Name="🗑 Reset Counter",
    Callback=function() lightningHits=0; notif("Reset ✅","Counter petir direset",2) end})

-- ============================================
-- TAB ESP
-- ============================================
TabESP:CreateSection("👁 ESP")
TabESP:CreateParagraph({Title="Warna",
    Content="🟢 Tanaman | 🟡 NPC | 🔵 Lahan Sawah\n🟩 Lahan Sawit | 🟠 Ternak"})
TabESP:CreateToggle({Name="👁 ESP Aktif", CurrentValue=false,
    Callback=function(v) _G.ESP=v
        if v then updateESP(); notif("ESP ON ✅",#ESPObjects.." obj",2)
        else clearESP(); notif("ESP OFF","",2) end end})
TabESP:CreateButton({Name="🔄 Refresh", Callback=function()
    if _G.ESP then updateESP(); notif("Refresh ✅",#ESPObjects.." obj",3)
    else notif("ESP","Aktifkan dulu!",3) end end})
TabESP:CreateButton({Name="🗑 Clear",
    Callback=function() clearESP(); _G.ESP=false; notif("Cleared ✅","",2) end})

-- ============================================
-- TAB TOOLS
-- ============================================
TabTools:CreateSection("📍 Info")
TabTools:CreateButton({Name="📍 Koordinat Saya",
    Callback=function() local r=getRoot(); if r then
        local p=r.Position; notif("Posisi",string.format("X=%.1f\nY=%.1f\nZ=%.1f",p.X,p.Y,p.Z),5)
    end end})
TabTools:CreateButton({Name="🔄 Respawn",
    Callback=function()
        local c=LocalPlayer.Character; if c then
            local h=c:FindFirstChildOfClass("Humanoid"); if h then h.Health=0; notif("Respawn","Tunggu...",2) end
        end end})
TabTools:CreateSection("🧪 Quick Test")
TabTools:CreateButton({Name="Test NPC Bibit",
    Callback=function() task.spawn(function()
        local ok=interakNPC("npcbibit",2)
        notif(ok and "Sukses ✅" or "Gagal ❌", ok and "NPC terbuka" or "Coba lagi",3)
    end) end})
TabTools:CreateButton({Name="Test Jual Hasil",
    Callback=function() task.spawn(function()
        local ok=autoJualMode("sell")
        notif(ok and "Sukses ✅" or "Gagal ❌", ok and "Terjual" or "Gagal",3)
    end) end})
TabTools:CreateButton({Name="🔄 Sync Data Player",
    Callback=function() task.spawn(function()
        local ok=syncPlayerData()
        notif(ok and "Sync ✅" or "Gagal ❌",
            ok and ("Lv."..PlayerData.Level.." | "..PlayerData.Coins.." Coins") or "SyncData tidak ada",3)
    end) end})

-- ============================================
-- TAB SETTING
-- ============================================
TabSet:CreateSection("⏱ Timing")
TabSet:CreateSlider({Name="Cooldown Remote (s)", Range={0.5,5}, Increment=0.5, CurrentValue=1,
    Callback=function(v) Cooldown=v end})
TabSet:CreateSlider({Name="Jarak antar TP (s)", Range={1,10}, Increment=1, CurrentValue=3,
    Callback=function(v) Jarak=v end})
TabSet:CreateSection("🛑 Emergency")
TabSet:CreateButton({Name="🛑 STOP SEMUA AUTO", Callback=function() stopSemua() end})

-- ============================================
-- TAB TEST REMOTE
-- ============================================
TabTest:CreateSection("🔥 Fire Remote Manual")
TabTest:CreateInput({Name="Nama Remote", PlaceholderText="contoh: LahanUpdate",
    RemoveTextAfterFocusLost=false, Callback=function(v) testRemoteName=v end})
TabTest:CreateInput({Name="Argumen 1 (opsional)", PlaceholderText="string/number/bool",
    RemoveTextAfterFocusLost=false, Callback=function(v) testArg1=v end})
TabTest:CreateButton({Name="🔥 FIRE REMOTE",
    Callback=function()
        if testRemoteName=="" then notif("Error","Masukkan nama remote!",3); return end
        local args={}
        if testArg1~="" then
            local num=tonumber(testArg1)
            if num then table.insert(args,num)
            elseif testArg1=="true"  then table.insert(args,true)
            elseif testArg1=="false" then table.insert(args,false)
            else table.insert(args,testArg1) end
        end
        local ok,result=fireR(testRemoteName,table.unpack(args))
        notif(ok and "Sukses ✅" or "Gagal ❌",tostring(result),4)
    end})

TabTest:CreateSection("⚡ Quick Test (dari Scan Map)")
local quickTests={
    {"SyncData",        "👤 SyncData (baca data player)"},
    {"RequestSell",     "💰 RequestSell (buka GUI jual) ✨"},
    {"RequestShop",     "🛒 RequestShop (buka toko) ✨"},
    {"RequestToolShop", "🔧 RequestToolShop (toko alat) ✨"},
    {"RequestLahan",    "🏞 RequestLahan ✨"},
    {"GetBibit",        "🌱 GetBibit(0,false) → GUI bibit"},
    {"SummonRain",      "🌧 SummonRain (1.5x growth) ✨"},
    {"LahanUpdate",     "🏞 LahanUpdate CONFIRM_BUY"},
    {"SkipTutorial",    "📖 SkipTutorial ✨"},
    {"RefreshShop",     "🔄 RefreshShop ✨"},
}
for _,t in ipairs(quickTests) do
    TabTest:CreateButton({Name=t[2],
        Callback=function()
            local ok,r=fireR(t[1])
            notif(t[1], ok and ("OK: "..tostring(r)) or ("ERR: "..tostring(r)),3)
        end})
end

-- ============================================
-- INIT
-- ============================================

-- Setup semua intercept dari decompile
setupIntercepts()

-- Sync data player awal
task.spawn(function()
    task.wait(3)
    local ok=syncPlayerData()
    if ok then
        notif("Data Synced ✅",
            "Lv."..PlayerData.Level.." | "..PlayerData.Coins.." Coins",3)
    end
end)

notif("🌾 SAWAH INDO v9.2","Welcome "..myName.."! 🔥",5)
task.wait(1)
notif("✅ Fix v9.2","Jual: RequestSell (no NPC!)\nHujan: SummonRain 1.5x grow!",6)
task.wait(1.5)
notif("Langkah 1","Tab 🌾 Posisi Lahan → Simpan posisi",5)
task.wait(1.3)
notif("Langkah 2","Tab 🌧 Hujan → Summon Rain dulu untuk 1.5x!",5)
task.wait(1.3)
notif("Langkah 3","Tab 🤖 Auto Farm → Pilih jenis → ON 🔥",5)

print(string.rep("=",52))
print("  SAWAH INDO v9.2 ULTIMATE — XKID HUB")
print("  RequestSell + PlantCrop + SummonRain")
print("  Semua via remote — No NPC TP needed!")
print("  Player: "..myName)
print(string.rep("=",52))
