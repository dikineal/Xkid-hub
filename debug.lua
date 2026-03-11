-- ╔═══════════════════════════════════════════════════════╗
-- ║                                                       ║
-- ║   ░██████╗░░█████╗░░██╗░░░░░░░██╗░█████╗░██╗░░██╗   ║
-- ║   ██╔════╝░██╔══██╗██║░░██╗░░██║██╔══██╗██║░░██║   ║
-- ║   ╚█████╗░███████║╚██╗████╗██╔╝███████║███████║   ║
-- ║   ░╚═══██╗██╔══██║░████╔═████║░██╔══██║██╔══██║   ║
-- ║   ██████╔╝██║░░██║░╚██╔╝░╚██╔╝░██║░░██║██║░░██║   ║
-- ║   ╚═════╝░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░╚═╝   ║
-- ║                                                       ║
-- ║      🌾  I N D O   F A R M E R  v13.0  🌾           ║
-- ║      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━          ║
-- ║      XKID HUB  ✦  Cobalt Confirmed Edition           ║
-- ║      GodMode ⚡  AutoFarm 🌱  AutoSell 💰            ║
-- ╚═══════════════════════════════════════════════════════╝

--[[
  ╭──────────────────────────────────────────────────────╮
  │  REMOTE CONFIRMED  ✦  Cobalt Spy v13                 │
  ├──────────────────────────────────────────────────────┤
  │  RequestShop  → BUY, GET_LIST                        │
  │  RequestSell  → GET_LIST, SELL (nama, qty) ✅        │
  │  PlantCrop    → FireServer(Vector3) ✅               │
  │  HarvestCrop  → OnClientEvent(crop, qty) ✅          │
  │  BackpackAdded→ nil instance DebugId 0_58612 ✅      │
  ├──────────────────────────────────────────────────────┤
  │  NPC COORDS  (Scan Confirmed)                        │
  │  NPC Penjual       X=-59   Z=-207                    │
  │  NPC Bibit         X=-42   Z=-207                    │
  │  NPC Alat          X=-41   Z=-100                    │
  │  NPC PedagangSawit X= 56   Z=-208                    │
  │  NPCPedagangTelur  X=-98   Z=-176                    │
  │  🚿 Mandi          X= 137  Z=-235                    │
  ╰──────────────────────────────────────────────────────╯
]]

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  RAYFIELD UI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name            = "🌾 INDO FARMER  v13.0",
    LoadingTitle    = "✦ XKID HUB ✦",
    LoadingSubtitle = "Cobalt Confirmed  ·  GodMode Edition",
    ConfigurationSaving = { Enabled = false },
    KeySystem       = false,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SERVICES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  FLAGS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
_G.ScriptRunning  = true
_G.AutoFarm       = false
_G.AutoBeli       = false
_G.AutoTanam      = false
_G.AutoSell       = false
_G.AutoHarvest    = false
_G.GodModePetir   = false   -- ⚡ petir godmode
_G.AntiAFK        = false
_G.AutoConfirm    = false
_G.NotifLevelUp   = true
_G.AutoMandi      = false

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  STATE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local PlayerData     = { Coins=0, Level=1, XP=0, Needed=50 }
local SiklusCount    = 0
local lightningHits  = 0
local levelUpCount   = 0
local totalEarned    = 0
local harvestCount   = 0
local SafePos        = nil
local LahanCache     = {}
local LahanCacheTime = 0
local BeliLoop       = nil
local SellLoop       = nil
local HarvestLoop    = nil
local selectedBibit  = "Bibit Padi"
local jumlahBeli     = 1
local dTanam         = 0.5
local waitPanen      = 60
local harvestInterval= 5

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  NPC COORDS — hardcoded dari hasil scan ✅
--  Y = 39 (default ground level sawah)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Y_GROUND = 39

local NPC_LIST = {
    { id="penjual",    label="🛒  NPC Penjual",        pos=Vector3.new(-59,  Y_GROUND, -207) },
    { id="bibit",      label="🌱  NPC Bibit",           pos=Vector3.new(-42,  Y_GROUND, -207) },
    { id="alat",       label="🔧  NPC Alat",            pos=Vector3.new(-41,  Y_GROUND, -100) },
    { id="sawit",      label="🌴  NPC Pedagang Sawit",  pos=Vector3.new( 56,  Y_GROUND, -208) },
    { id="telur",      label="🥚  NPC Pedagang Telur",  pos=Vector3.new(-98,  Y_GROUND, -176) },
}

local MANDI_POS = Vector3.new(137, Y_GROUND, -235)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ITEM & BIBIT LIST
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ITEM_LIST = {
    { name="Padi",       icon="🌾", price=10  },
    { name="Jagung",     icon="🌽", price=20  },
    { name="Tomat",      icon="🍅", price=30  },
    { name="Terong",     icon="🍆", price=50  },
    { name="Strawberry", icon="🍓", price=75  },
}

local BIBIT_LIST = {
    { name="Bibit Padi",       icon="🌾", price=5,    minLv=1   },
    { name="Bibit Jagung",     icon="🌽", price=15,   minLv=20  },
    { name="Bibit Tomat",      icon="🍅", price=25,   minLv=40  },
    { name="Bibit Terong",     icon="🍆", price=40,   minLv=60  },
    { name="Bibit Strawberry", icon="🍓", price=60,   minLv=80  },
    { name="Bibit Sawit",      icon="🌴", price=1000, minLv=80  },
    { name="Bibit Durian",     icon="🍈", price=2000, minLv=120 },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  NOTIF
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function notif(title, body, dur)
    pcall(function()
        Rayfield:Notify({ Title=title, Content=body, Duration=dur or 3, Image=4483362458 })
    end)
    print(string.format("[ XKID ✦ ] %s  |  %s", title, tostring(body)))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  CHARACTER HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function getChar()  return LocalPlayer.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function getPos()
    local r = getRoot(); return r and r.Position
end

local function tp(pos)
    local root = getRoot(); if not root then return false end
    root.CFrame = CFrame.new(
        typeof(pos)=="Vector3" and Vector3.new(pos.X, pos.Y+3, pos.Z) or pos
    )
    task.wait(0.3); return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  REMOTE HELPER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
    if not r or not r:IsA("RemoteEvent") then return false, "not found" end
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

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ⚡ GODMODE PETIR — v13
--  Metode: saat LightningStrike event masuk →
--  1. Set Humanoid.Health = MaxHealth terus-menerus
--  2. Disable semua damage via HealthChanged hook
--  3. Jika karakter terkena, instant restore HP
--  4. Bonus: briefly set WalkSpeed=0 prevent knockback
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local godConn       = nil
local godHealConn   = nil
local godActive     = false

local function activateGodMode(duration)
    -- Batalkan godmode sebelumnya
    if godConn      then godConn:Disconnect();    godConn=nil    end
    if godHealConn  then godHealConn:Disconnect(); godHealConn=nil end

    godActive = true
    local hum = getHum()
    if not hum then godActive=false; return end

    local maxHp = hum.MaxHealth
    -- Kunci HP tiap heartbeat selama 'duration' detik
    godConn = RunService.Heartbeat:Connect(function()
        if not godActive then godConn:Disconnect(); godConn=nil; return end
        local h = getHum()
        if h then
            h.Health = h.MaxHealth   -- restore tiap frame
        end
    end)

    -- Auto stop setelah durasi
    task.delay(duration or 6, function()
        godActive = false
        if godConn then godConn:Disconnect(); godConn=nil end
        print("[ XKID ⚡ ] GodMode selesai")
    end)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ANTI AFK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local antiAFKConn = nil
local function startAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect() end
    local last = tick()
    antiAFKConn = RunService.Heartbeat:Connect(function()
        if not _G.AntiAFK then antiAFKConn:Disconnect(); antiAFKConn=nil; return end
        if tick()-last >= 120 then
            last=tick()
            local h=getHum(); if h then h.Jump=true end
        end
    end)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SCAN LAHAN
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function scanLahan()
    if tick()-LahanCacheTime < 10 and #LahanCache>0 then return LahanCache end
    LahanCache = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("areatanambesar") or n:find("areatanampadi")
            or n:find("areatanamsawah") or n:find("areatanamsawit") then
                table.insert(LahanCache, v.Position)
            end
        end
    end
    LahanCacheTime = tick()
    return LahanCache
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  BELI BIBIT ✅
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function beliBibit(nama, qty)
    nama = nama or selectedBibit; qty = qty or jumlahBeli
    local ok, res = invokeRF("RequestShop","BUY",nama,qty)
    if not ok then return false,"RequestShop gagal" end
    local data = unwrap(res)
    if data and data.Success then
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        return true, data.Message or "Berhasil"
    end
    return false, (data and data.Message) or "Gagal"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  JUAL ✅ CONFIRMED
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function getInventoryJual()
    local ok, res = invokeRF("RequestSell","GET_LIST")
    if not ok then return nil end
    local data = unwrap(res)
    if data then PlayerData.Coins = data.Coins or PlayerData.Coins end
    return data
end

local function jualItem(nama, qty)
    local ok, res = invokeRF("RequestSell","SELL",nama,qty or 1)
    if not ok then return false,"Remote gagal",0 end
    local data = unwrap(res)
    if data and data.Success then
        local earned = data.Earned or 0
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        totalEarned = totalEarned + earned
        return true, data.Message or "Terjual", earned
    end
    if type(res)=="number" then PlayerData.Coins=res; return true,"Terjual",0 end
    return false, (data and data.Message) or "Gagal", 0
end

local function jualSemua()
    local data = getInventoryJual()
    if not data or not data.Items then return false,"GET_LIST gagal" end
    local totalItem, totalCoin = 0, 0
    for _, item in ipairs(data.Items) do
        if item.Owned and item.Owned > 0 then
            local ok, _, earned = jualItem(item.Name, item.Owned)
            if ok then
                totalItem = totalItem + item.Owned
                totalCoin = totalCoin + (item.Price * item.Owned)
            end
            task.wait(0.3)
        end
    end
    if totalItem == 0 then return false,"Tidak ada item" end
    return true, totalItem.." item  ·  +"..totalCoin.."💰"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  AUTO HARVEST
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function autoHarvestTick()
    local harvested = 0
    for _, v in pairs(Workspace:GetDescendants()) do
        local n = v.Name:lower()
        local isCrop = n:find("crop") or n:find("plant") or n:find("padi")
            or n:find("jagung") or n:find("tomat") or n:find("terong")
            or n:find("sawit") or n:find("durian") or n:find("strawberry")
        if isCrop then
            local pp = v:FindFirstChildWhichIsA("ProximityPrompt", true)
            if pp then
                local partPos
                if v:IsA("BasePart") then partPos=v.Position
                elseif v.PrimaryPart then partPos=v.PrimaryPart.Position end
                local myPos = getPos()
                if partPos and myPos and (partPos-myPos).Magnitude < 20 then
                    pcall(function() fireproximityprompt(pp) end)
                    harvested = harvested+1
                    task.wait(0.1)
                end
            end
        end
    end
    return harvested
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  BACKPACK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function triggerBackpack()
    if not getnilinstances then return false end
    for _, obj in getnilinstances() do
        if obj.Name=="BackpackAdded" and obj:GetDebugId()=="0_58612" then
            pcall(function() obj:Fire() end); return true
        end
    end
    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  MANDI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function goMandi()
    tp(MANDI_POS)
    notif("🚿  Mandi", string.format("TP  X=%.0f  Z=%.0f", MANDI_POS.X, MANDI_POS.Z), 3)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  STOP ALL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function stopSemua()
    _G.AutoFarm=false; _G.AutoBeli=false; _G.AutoTanam=false
    _G.AutoSell=false; _G.AutoHarvest=false; _G.AutoMandi=false
    for _, ref in ipairs({BeliLoop,SellLoop,HarvestLoop}) do
        if ref then pcall(function() task.cancel(ref) end) end
    end
    BeliLoop=nil; SellLoop=nil; HarvestLoop=nil
    notif("⛔  STOP ALL","Semua fitur dimatikan",3)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  INTERCEPTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function setupIntercepts()

    -- ⚡ LIGHTNING — GodMode approach
    task.spawn(function()
        local r; for i=1,15 do r=getR("LightningStrike"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
            lightningHits = lightningHits+1
            print(string.format("[ XKID ⚡ ] Petir #%d | Reason=%s", lightningHits, tostring(data and data.Reason)))
            if not _G.GodModePetir then return end
            -- Aktifkan GodMode 8 detik (cukup untuk petir selesai)
            activateGodMode(8)
            notif("⚡  GodMode AKTIF",
                string.format("Petir #%d ditangkal!\nHP terkunci selama 8 detik", lightningHits), 3)
        end)
        print("[ XKID ✦ ] LightningStrike intercept ready")
    end)

    -- 📊 LEVEL
    task.spawn(function()
        local r; for i=1,15 do r=getR("UpdateLevel"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
            if type(data)~="table" then return end
            PlayerData.Level  = data.Level  or PlayerData.Level
            PlayerData.XP     = data.XP     or PlayerData.XP
            PlayerData.Needed = data.Needed or PlayerData.Needed
            if data.LeveledUp and _G.NotifLevelUp then
                levelUpCount=levelUpCount+1
                notif("🎉  Level Up!  #"..levelUpCount,
                    "Level "..data.Level.."  ·  XP "..data.XP.."/"..data.Needed, 6)
            end
        end)
    end)

    -- 🔔 NOTIFICATION
    task.spawn(function()
        local r; for i=1,15 do r=getR("Notification"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(msg)
            if type(msg)~="string" then return end
            local ml=msg:lower()
            if ml:find("hujan") then
                notif("🌧  Hujan!","Tanaman tumbuh lebih cepat",4)
            elseif ml:find("petir") or ml:find("gosong") then
                notif("⚡  Petir!",msg,4)
            elseif ml:find("mandi") or ml:find("segar") or ml:find("hygiene") or ml:find("kotor") then
                notif("🚿  Perlu Mandi!",msg,4)
                if _G.AutoMandi then task.delay(0.5, goMandi) end
            end
        end)
    end)

    -- 🌾 HARVEST
    task.spawn(function()
        local r; for i=1,15 do r=getR("HarvestCrop"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(cropName, qty)
            harvestCount = harvestCount+(tonumber(qty) or 1)
            print(string.format("[ XKID 🌾 ] Panen: %s x%d  ·  Total: %d",
                tostring(cropName), tonumber(qty) or 1, harvestCount))
        end)
    end)

    -- 💰 SELL CROP (intercept GUI open)
    task.spawn(function()
        local r; for i=1,15 do r=getR("SellCrop"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(_, p41)
            if _G.AutoSell and type(p41)=="string" and p41:find("OPEN") then
                task.delay(0.5, function()
                    local ok, msg = jualSemua()
                    notif(ok and "💰  Auto Sell ✅" or "❌  Auto Sell", msg, 3)
                end)
            end
        end)
    end)

    -- ✅ CONFIRM
    task.spawn(function()
        local r; for i=1,15 do r=getR("ConfirmAction"); if r then break end; task.wait(1) end
        if not r or not r:IsA("RemoteFunction") then return end
        r.OnClientInvoke = function(data)
            if _G.AutoConfirm then notif("✅  Auto Confirm",tostring(data),2); return true end
            return nil
        end
    end)

    print("[ XKID ✦ ] ══ ALL INTERCEPTS READY ══")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TABS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local TabStatus  = Window:CreateTab("📊  Status",      nil)
local TabFarm    = Window:CreateTab("🤖  Auto Farm",   nil)
local TabBibit   = Window:CreateTab("🛒  Bibit",       nil)
local TabJual    = Window:CreateTab("💰  Jual",        nil)
local TabHarvest = Window:CreateTab("🌾  Harvest",     nil)
local TabTP      = Window:CreateTab("📍  Teleport",    nil)
local TabPetir   = Window:CreateTab("⚡  GodMode",     nil)
local TabBag     = Window:CreateTab("🎒  Backpack",    nil)
local TabSet     = Window:CreateTab("⚙  Setting",    nil)
local TabTest    = Window:CreateTab("🧪  Debug",       nil)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB STATUS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabStatus:CreateSection("✦  Live Monitor")
local St = {
    farm    = TabStatus:CreateParagraph({Title="🤖  Auto Farm",    Content="○  Offline"}),
    harvest = TabStatus:CreateParagraph({Title="🌾  Auto Harvest", Content="○  Offline"}),
    sell    = TabStatus:CreateParagraph({Title="💰  Auto Sell",    Content="○  Offline"}),
    god     = TabStatus:CreateParagraph({Title="⚡  GodMode Petir",Content="○  Offline"}),
    player  = TabStatus:CreateParagraph({Title="👤  Player",       Content="..."}),
    lahan   = TabStatus:CreateParagraph({Title="🗺  Lahan",        Content="Belum scan"}),
    afk     = TabStatus:CreateParagraph({Title="🛡  Anti AFK",     Content="○  Offline"}),
    stats   = TabStatus:CreateParagraph({Title="💸  Session",      Content="—"}),
}

task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            St.farm:Set({Title="🤖  Auto Farm",
                Content=_G.AutoFarm and ("●  Running  ·  Siklus "..SiklusCount) or "○  Offline"})
            St.harvest:Set({Title="🌾  Auto Harvest",
                Content=_G.AutoHarvest and ("●  Active  ·  Panen "..harvestCount.."×") or ("○  Offline  ·  Total "..harvestCount.."×")})
            St.sell:Set({Title="💰  Auto Sell",
                Content=_G.AutoSell and "●  Active" or "○  Offline"})
            St.god:Set({Title="⚡  GodMode Petir",
                Content=(_G.GodModePetir and "●  ACTIVE" or "○  Offline")
                    .."  ·  "..lightningHits.."× tangkal"})
            St.player:Set({Title="👤  "..LocalPlayer.Name,
                Content="💰 "..PlayerData.Coins
                    .."   ⭐ Lv."..PlayerData.Level
                    .."   📊 "..PlayerData.XP.."/"..PlayerData.Needed
                    .."\n🎉 Level Up: "..levelUpCount.."×"})
            St.lahan:Set({Title="🗺  Lahan",
                Content=#LahanCache.." plot"
                    ..(LahanCacheTime>0 and ("  ·  "..string.format("%.0f",tick()-LahanCacheTime).."s ago") or "")})
            St.afk:Set({Title="🛡  Anti AFK", Content=_G.AntiAFK and "●  Active" or "○  Offline"})
            St.stats:Set({Title="💸  Session Stats",
                Content="Earned: "..totalEarned.."💰  ·  Panen: "..harvestCount.."×  ·  Siklus: "..SiklusCount})
        end)
        task.wait(1)
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB AUTO FARM
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabFarm:CreateSection("✦  Full Auto Farm")
TabFarm:CreateParagraph({Title="Flow",
    Content="① Beli Bibit\n② Tanam ke semua lahan\n③ Tunggu panen\n④ Harvest\n⑤ Mandi (opsional)\n⑥ Jual semua\n\n— Scan Lahan dulu di tab 🗺"})
TabFarm:CreateSlider({Name="Delay Tanam  (detik)", Range={0.1,3}, Increment=0.1, CurrentValue=0.5,
    Callback=function(v) dTanam=v end})
TabFarm:CreateSlider({Name="Tunggu Panen  (detik)", Range={10,300}, Increment=5, CurrentValue=60,
    Callback=function(v) waitPanen=v end})
TabFarm:CreateToggle({Name="🚿  Auto Mandi tiap siklus", CurrentValue=false,
    Callback=function(v) _G.AutoMandi=v end})

TabFarm:CreateToggle({Name="🔥  FULL AUTO FARM", CurrentValue=false,
    Callback=function(v)
        _G.AutoFarm=v
        if not v then notif("🤖  Auto Farm","Dihentikan",2); return end
        if #LahanCache==0 then scanLahan() end
        if #LahanCache==0 then notif("⚠️","Scan Lahan dulu!",5); _G.AutoFarm=false; return end
        SiklusCount=0
        notif("🔥  Auto Farm ON","Lahan: "..#LahanCache.."  ·  Bibit: "..selectedBibit,4)
        task.spawn(function()
            while _G.AutoFarm do
                SiklusCount=SiklusCount+1
                local ok,msg = beliBibit(selectedBibit,jumlahBeli)
                notif(ok and "🛒  Beli ✅" or "🛒  Beli ❌",msg,2)
                if not _G.AutoFarm then break end; task.wait(1)
                local planted=0
                for _,pos in ipairs(LahanCache) do
                    if not _G.AutoFarm then break end
                    if fireEv("PlantCrop",pos) then planted=planted+1 end
                    task.wait(dTanam)
                end
                notif("🌱  Tanam ✅",planted.."/"..#LahanCache.." plot",2)
                if not _G.AutoFarm then break end
                local w=0
                while w<waitPanen and _G.AutoFarm do task.wait(1); w=w+1 end
                if not _G.AutoFarm then break end
                local h=autoHarvestTick()
                if h>0 then notif("🌾  Harvest ✅",h.." tanaman",2) end
                task.wait(1)
                if _G.AutoMandi then goMandi(); task.wait(3) end
                local sOk,sMsg=jualSemua()
                notif(sOk and "💰  Jual ✅" or "💰  Jual ❌",sMsg,3)
                task.wait(2)
            end
            notif("⛔  Farm Stop","Siklus: "..SiklusCount.."  ·  Earned: "..totalEarned.."💰",4)
        end)
    end})

TabFarm:CreateToggle({Name="🌱  Auto Tanam Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoTanam=v
        if v then
            task.spawn(function()
                while _G.AutoTanam do
                    if #LahanCache==0 then scanLahan() end
                    local c=0
                    for _,pos in ipairs(LahanCache) do
                        if not _G.AutoTanam then break end
                        if fireEv("PlantCrop",pos) then c=c+1 end
                        task.wait(dTanam)
                    end
                    notif("🌱  Tanam ✅",c.." plot",2); task.wait(5)
                end
            end)
            notif("🌱  Auto Tanam","ON ✅",3)
        else notif("🌱  Auto Tanam","OFF",2) end
    end})

TabFarm:CreateButton({Name="⛔  STOP SEMUA", Callback=stopSemua})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB BIBIT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabBibit:CreateSection("✦  Beli Bibit")
local opsiB={}
for _,b in ipairs(BIBIT_LIST) do
    table.insert(opsiB, b.icon.."  "..b.name.."  ·  Lv."..b.minLv.."  ·  "..b.price.."💰")
end
TabBibit:CreateDropdown({Name="Pilih Bibit", Options=opsiB, CurrentOption={opsiB[1]},
    Callback=function(v)
        for _,b in ipairs(BIBIT_LIST) do
            if v[1]:find(b.name,1,true) then selectedBibit=b.name; notif("✅  Dipilih",b.name,2); break end
        end
    end})
TabBibit:CreateSlider({Name="Jumlah", Range={1,99}, Increment=1, CurrentValue=1,
    Callback=function(v) jumlahBeli=v end})
TabBibit:CreateButton({Name="🛒  Beli Sekarang",
    Callback=function()
        task.spawn(function()
            local ok,msg=beliBibit(selectedBibit,jumlahBeli)
            notif(ok and "🛒  Beli ✅" or "❌",msg,4)
        end)
    end})
TabBibit:CreateSection("✦  Beli Cepat")
for _,b in ipairs(BIBIT_LIST) do
    local bb=b
    TabBibit:CreateButton({Name=bb.icon.."  "..bb.name.."  ·  "..bb.price.."💰",
        Callback=function()
            task.spawn(function()
                selectedBibit=bb.name
                local ok,msg=beliBibit(bb.name,jumlahBeli)
                notif(ok and "✅" or "❌",msg,3)
            end)
        end})
end
TabBibit:CreateSection("✦  Stok")
TabBibit:CreateButton({Name="📋  Lihat Stok Bibit",
    Callback=function()
        task.spawn(function()
            local ok,res=invokeRF("RequestShop","GET_LIST")
            if not ok then notif("❌","Gagal",3); return end
            local data=unwrap(res)
            if not data or not data.Seeds then notif("❌","Kosong",3); return end
            PlayerData.Coins=data.Coins or PlayerData.Coins
            local txt="💰 "..tostring(data.Coins).."\n\n"
            for _,s in ipairs(data.Seeds) do
                txt=txt..(s.Locked and "🔒" or "✅").."  "..s.Name
                    .."  x"..s.Owned.."  ·  "..s.Price.."💰\n"
            end
            notif("🛒  Bibit Shop",txt,10)
        end)
    end})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB JUAL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabJual:CreateSection("✦  Jual  —  Confirmed v13")
TabJual:CreateParagraph({Title="Method ✅",
    Content="RequestSell:InvokeServer('SELL', nama, qty)\n\n"
        .."Harga confirmed:\n"
        .."🌾 Padi 10💰  ·  🌽 Jagung 20💰\n"
        .."🍅 Tomat 30💰  ·  🍆 Terong 50💰\n"
        .."🍓 Strawberry 75💰"})
TabJual:CreateButton({Name="💰  Jual Semua",
    Callback=function()
        task.spawn(function()
            local ok,msg=jualSemua()
            notif(ok and "💰  Jual ✅" or "❌",msg,4)
        end)
    end})
TabJual:CreateToggle({Name="🔄  Auto Sell Loop  (30s)", CurrentValue=false,
    Callback=function(v)
        _G.AutoSell=v
        if v then
            SellLoop=task.spawn(function()
                while _G.AutoSell do
                    local ok,msg=jualSemua()
                    notif(ok and "💰  Auto Sell ✅" or "❌",msg,3)
                    task.wait(30)
                end
            end)
            notif("💰  Auto Sell","ON  ·  tiap 30s",3)
        else
            if SellLoop then pcall(function() task.cancel(SellLoop) end); SellLoop=nil end
            notif("💰  Auto Sell","OFF",2)
        end
    end})
TabJual:CreateSection("✦  Preview Inventory")
TabJual:CreateButton({Name="📋  Lihat Inventory",
    Callback=function()
        task.spawn(function()
            local data=getInventoryJual()
            if not data or not data.Items then notif("❌","Gagal",3); return end
            local txt="SellMult: "..tostring(data.SellMult).."  ·  💰 "..tostring(data.Coins).."\n\n"
            for _,item in ipairs(data.Items) do
                txt=txt..(item.Owned>0 and "✅" or "⬜").."  "
                    ..item.DisplayName.."  x"..item.Owned.."  ·  "..item.Price.."💰\n"
            end
            notif("📦  Inventory",txt,10)
        end)
    end})
TabJual:CreateSection("✦  Jual Cepat Per Item")
for _,item in ipairs(ITEM_LIST) do
    local it=item
    TabJual:CreateButton({Name=it.icon.."  "..it.name.."  ·  "..it.price.."💰/pcs",
        Callback=function()
            task.spawn(function()
                local data=getInventoryJual()
                local owned=0
                if data and data.Items then
                    for _,i in ipairs(data.Items) do
                        if i.Name==it.name then owned=i.Owned; break end
                    end
                end
                if owned==0 then notif("⬜  "..it.name,"Stok kosong",3); return end
                local ok,msg,earned=jualItem(it.name,owned)
                notif(ok and "💰  Jual ✅" or "❌",
                    it.name.."  x"..owned..(ok and "  +"..earned.."💰" or "  ·  "..msg),4)
            end)
        end})
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB HARVEST
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabHarvest:CreateSection("✦  Auto Harvest")
TabHarvest:CreateParagraph({Title="Cara Kerja",
    Content="Scan ProximityPrompt di sekitar karakter\n→ fireproximityprompt() otomatis\n\nConfirmed: HarvestCrop.OnClientEvent\n('Padi', 1, 'Padi')"})
TabHarvest:CreateSlider({Name="Interval  (detik)", Range={1,30}, Increment=1, CurrentValue=5,
    Callback=function(v) harvestInterval=v end})
TabHarvest:CreateToggle({Name="🌾  AUTO HARVEST", CurrentValue=false,
    Callback=function(v)
        _G.AutoHarvest=v
        if v then
            HarvestLoop=task.spawn(function()
                while _G.AutoHarvest do
                    local h=autoHarvestTick()
                    if h>0 then notif("🌾  Harvest ✅",h.." tanaman",2) end
                    task.wait(harvestInterval)
                end
            end)
            notif("🌾  Auto Harvest","ON  ·  tiap "..harvestInterval.."s",3)
        else
            if HarvestLoop then pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil end
            notif("🌾  Auto Harvest","OFF  ·  Total: "..harvestCount.."×",3)
        end
    end})
TabHarvest:CreateButton({Name="🌾  Harvest Sekali",
    Callback=function()
        task.spawn(function()
            local h=autoHarvestTick()
            notif("🌾  Harvest", h>0 and h.." tanaman" or "Tidak ada tanaman dekat",3)
        end)
    end})
TabHarvest:CreateButton({Name="🗑  Reset Counter",
    Callback=function() harvestCount=0; notif("✅  Reset","Counter panen di-reset",2) end})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB TELEPORT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabTP:CreateSection("✦  Teleport NPC  —  5 NPC Confirmed")
TabTP:CreateParagraph({Title="Koordinat (Scan Confirmed)",
    Content="🛒  Penjual      X=-59   Z=-207\n"
        .."🌱  Bibit        X=-42   Z=-207\n"
        .."🔧  Alat         X=-41   Z=-100\n"
        .."🌴  Sawit        X= 56   Z=-208\n"
        .."🥚  Telur        X=-98   Z=-176\n"
        .."🚿  Mandi        X=137   Z=-235"})

-- Tombol TP per NPC
for _,npc in ipairs(NPC_LIST) do
    local n=npc
    TabTP:CreateButton({Name="🚀  "..n.label,
        Callback=function()
            tp(n.pos)
            notif("📍  TP  ·  "..n.label,
                string.format("X=%.0f  Z=%.0f", n.pos.X, n.pos.Z),3)
        end})
end

TabTP:CreateSection("✦  Mandi")
TabTP:CreateButton({Name="🚿  TP ke Tempat Mandi",
    Callback=function() goMandi() end})
TabTP:CreateToggle({Name="🚿  Auto Mandi  (saat notif kotor)", CurrentValue=false,
    Callback=function(v) _G.AutoMandi=v; notif("🚿  Auto Mandi",v and "ON ✅" or "OFF",2) end})

TabTP:CreateSection("✦  Scan Lahan")
local LahanPara = TabTP:CreateParagraph({Title="🗺  Lahan",Content="Belum scan"})
TabTP:CreateButton({Name="🔍  Scan Lahan",
    Callback=function()
        LahanCacheTime=0; local l=scanLahan()
        LahanPara:Set({Title="🗺  Lahan", Content=#l.." plot  "..(#l>0 and "✅" or "❌")})
        notif("🔍  Scan",#l.." plot ditemukan",3)
    end})

TabTP:CreateSection("✦  Manual Koordinat")
local tpX,tpY,tpZ=0,5,0
TabTP:CreateInput({Name="X", PlaceholderText="-59",
    RemoveTextAfterFocusLost=false, Callback=function(v) tpX=tonumber(v) or 0 end})
TabTP:CreateInput({Name="Y", PlaceholderText="39",
    RemoveTextAfterFocusLost=false, Callback=function(v) tpY=tonumber(v) or 5 end})
TabTP:CreateInput({Name="Z", PlaceholderText="-207",
    RemoveTextAfterFocusLost=false, Callback=function(v) tpZ=tonumber(v) or 0 end})
TabTP:CreateButton({Name="🚀  TP ke Koordinat",
    Callback=function()
        tp(Vector3.new(tpX,tpY,tpZ))
        notif("📍  TP",string.format("X=%.1f  Y=%.1f  Z=%.1f",tpX,tpY,tpZ),3)
    end})
TabTP:CreateButton({Name="📍  Print Posisi Saya",
    Callback=function()
        local pos=getPos()
        if pos then
            notif("📍  Posisi",string.format("X=%.2f\nY=%.2f\nZ=%.2f",pos.X,pos.Y,pos.Z),5)
            print(string.format("[ XKID 📍 ] X=%.4f  Y=%.4f  Z=%.4f",pos.X,pos.Y,pos.Z))
        end
    end})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB GODMODE PETIR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabPetir:CreateSection("⚡  GodMode Petir  —  v13")
TabPetir:CreateParagraph({Title="Cara Kerja  (v13 Fix)",
    Content="Saat LightningStrike event masuk:\n\n"
        .."① Kunci HP = MaxHP tiap Heartbeat\n"
        .."   selama 8 detik\n"
        .."② Tidak perlu Safe Position lagi!\n"
        .."③ Karakter tetap di tempat,\n"
        .."   tidak perlu teleport\n\n"
        .."✅ Lebih reliable dari TP Safe Pos\n"
        .."✅ Bekerja meski di tengah lahan"})

TabPetir:CreateToggle({Name="⚡  GodMode Petir  AKTIF", CurrentValue=false,
    Callback=function(v)
        _G.GodModePetir=v
        notif("⚡  GodMode Petir", v and "●  AKTIF  —  HP terkunci saat petir" or "○  OFF", 3)
    end})

TabPetir:CreateButton({Name="⚡  Test GodMode  (manual)",
    Callback=function()
        notif("⚡  GodMode Test","Aktif 8 detik...",3)
        activateGodMode(8)
    end})

TabPetir:CreateButton({Name="🗑  Reset Counter Petir",
    Callback=function() lightningHits=0; notif("✅  Reset","Counter petir di-reset",2) end})

TabPetir:CreateSection("⚡  Info Statistik")
local petirPara = TabPetir:CreateParagraph({Title="Stats",Content="—"})
task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            petirPara:Set({Title="⚡  Statistik Petir",
                Content="Total petir: "..lightningHits.."×\n"
                    .."GodMode: "..(_G.GodModePetir and "●  AKTIF" or "○  OFF").."\n"
                    .."HP Lock aktif: "..(godActive and "●  YA" or "○  Tidak")})
        end)
        task.wait(1)
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB BACKPACK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabBag:CreateSection("✦  Backpack")
TabBag:CreateParagraph({Title="Confirmed  ✅",
    Content="BindableEvent  (nil instance)\n"
        .."Name: BackpackAdded\n"
        .."DebugId: 0_58612\n\n"
        .."GetNil('BackpackAdded','0_58612'):Fire()\n\n"
        .."Butuh executor dengan getnilinstances()"})
TabBag:CreateButton({Name="🎒  Trigger Backpack",
    Callback=function()
        local ok=triggerBackpack()
        notif(ok and "🎒  Backpack ✅" or "❌  Backpack",
            ok and "BackpackAdded:Fire() sukses!"
            or "Gagal · getnilinstances tidak tersedia\natau DebugId berubah",
            ok and 4 or 5)
    end})
TabBag:CreateSection("✦  Scan Nil Instances")
TabBag:CreateButton({Name="🔍  Cari BackpackAdded",
    Callback=function()
        if not getnilinstances then notif("❌","Tidak support",4); return end
        local found={}
        for _,obj in getnilinstances() do
            local n=obj.Name:lower()
            if n:find("backpack") or n:find("bag") or n:find("inventory") then
                table.insert(found, obj.Name.."  ·  "..obj:GetDebugId())
                print("[ XKID 🎒 ] "..obj.Name.."  |  "..obj:GetDebugId().."  |  "..obj.ClassName)
            end
        end
        notif(#found>0 and "🎒  Ditemukan" or "⬜  Tidak ada",
            #found>0 and table.concat(found,"\n") or "Tidak ada nil backpack event",6)
    end})
TabBag:CreateButton({Name="📋  Dump Semua Nil Instances",
    Callback=function()
        if not getnilinstances then notif("❌","Tidak support",4); return end
        local c=0
        for _,obj in getnilinstances() do
            c=c+1
            print(string.format("[ XKID NIL ] [%d] %s  |  %s  |  %s",c,obj.Name,obj.ClassName,obj:GetDebugId()))
        end
        notif("📋  Dump Selesai",c.." objects  ·  Lihat console F9",5)
    end})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB SETTING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabSet:CreateSection("✦  Anti AFK")
TabSet:CreateToggle({Name="🛡  Anti AFK", CurrentValue=false,
    Callback=function(v)
        _G.AntiAFK=v
        if v then startAntiAFK() end
        notif("🛡  Anti AFK",v and "ON  ·  Jump tiap 2 menit" or "OFF",3)
    end})
TabSet:CreateSection("✦  Farm Timing")
TabSet:CreateSlider({Name="Delay Tanam  (s)", Range={0.1,3}, Increment=0.1, CurrentValue=0.5,
    Callback=function(v) dTanam=v end})
TabSet:CreateSlider({Name="Tunggu Panen  (s)", Range={10,300}, Increment=5, CurrentValue=60,
    Callback=function(v) waitPanen=v end})
TabSet:CreateSlider({Name="Harvest Interval  (s)", Range={1,30}, Increment=1, CurrentValue=5,
    Callback=function(v) harvestInterval=v end})
TabSet:CreateSection("✦  Misc")
TabSet:CreateToggle({Name="✅  Auto Confirm", CurrentValue=false,
    Callback=function(v) _G.AutoConfirm=v; notif("✅  Auto Confirm",v and "ON" or "OFF",2) end})
TabSet:CreateToggle({Name="🎉  Notif Level Up", CurrentValue=true,
    Callback=function(v) _G.NotifLevelUp=v end})
TabSet:CreateButton({Name="⛔  STOP SEMUA", Callback=stopSemua})
TabSet:CreateButton({Name="🔄  Reset Session Stats",
    Callback=function()
        totalEarned=0; harvestCount=0; SiklusCount=0; levelUpCount=0; lightningHits=0
        notif("✅  Reset","Semua stats di-reset",2)
    end})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB DEBUG
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TabTest:CreateSection("✦  Remote Confirmed  v13")
TabTest:CreateParagraph({Title="Cobalt ✅",
    Content="✅  RequestShop('BUY', nama, qty)\n"
        .."✅  RequestShop('GET_LIST')\n"
        .."✅  RequestSell('GET_LIST')\n"
        .."✅  RequestSell('SELL', nama, qty)\n"
        .."✅  PlantCrop:FireServer(Vector3)\n"
        .."✅  HarvestCrop.OnClientEvent\n"
        .."✅  BackpackAdded  nil  0_58612"})
TabTest:CreateSection("✦  Test SELL")
local sellCmd,sellArg,sellQty2="SELL","Padi","7"
TabTest:CreateInput({Name="Command", PlaceholderText="SELL / GET_LIST",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellCmd=v end})
TabTest:CreateInput({Name="Nama Item", PlaceholderText="Padi",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellArg=v end})
TabTest:CreateInput({Name="Qty", PlaceholderText="7",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellQty2=v end})
TabTest:CreateButton({Name="🔥  Test RequestSell",
    Callback=function()
        task.spawn(function()
            local qty=tonumber(sellQty2)
            local ok,res
            if qty and sellArg~="" then ok,res=invokeRF("RequestSell",sellCmd,sellArg,qty)
            elseif sellArg~="" then ok,res=invokeRF("RequestSell",sellCmd,sellArg)
            else ok,res=invokeRF("RequestSell",sellCmd) end
            notif("RequestSell("..sellCmd..")",ok and "✅  Lihat console" or "❌  "..tostring(res),5)
            if ok then
                local d=unwrap(res) or res
                if type(d)=="table" then
                    for k,v in pairs(d) do
                        if type(v)~="table" then
                            print(string.format("[ XKID SELL ] %s = %s",tostring(k),tostring(v)))
                        end
                    end
                end
            end
        end)
    end})
TabTest:CreateSection("✦  Quick Test")
for _,q in ipairs({
    {"SummonRain","🌧  SummonRain"},
    {"SkipTutorial","📖  SkipTutorial"},
    {"RefreshShop","🔄  RefreshShop"},
}) do
    local qq=q
    TabTest:CreateButton({Name=qq[2],
        Callback=function()
            task.spawn(function()
                local ok,err=fireEv(qq[1])
                notif(qq[1],ok and "Fired ✅" or "❌  "..tostring(err),3)
            end)
        end})
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  INIT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
setupIntercepts()

task.spawn(function()
    task.wait(3)
    scanLahan()
    notif("🔍  Auto Scan", #LahanCache.." lahan ditemukan", 4)
end)

notif("🌾  INDO FARMER  v13.0","Welcome,  "..LocalPlayer.Name.."  ✦",5)
task.wait(1.5)
notif("✦  v13  Update",
    "⚡ GodMode Petir (HP lock)\n"
    .."📍 5 NPC hardcoded\n"
    .."🚿 Mandi pos confirmed\n"
    .."💰 SELL confirmed\n"
    .."🎨 Aesthetic overhaul", 8)

print("╔══════════════════════════════════════════╗")
print("║   🌾  INDO FARMER  v13.0  —  XKID HUB  ║")
print("║   GodMode  ·  5 NPC  ·  AutoFarm        ║")
print("║   Player: "..LocalPlayer.Name)
print("╚══════════════════════════════════════════╝")
