-- ╔══════════════════════════════════════════════════╗
-- ║   🌾 SAWAH INDO v12.0 — XKID HUB                ║
-- ║   100% Confirmed Cobalt Spy Edition              ║
-- ║   Backpack + Auto Harvest + Auto Sell + Mandi   ║
-- ╚══════════════════════════════════════════════════╝

--[[
  REMOTE CONFIRMED (Cobalt v12):
  ┌──────────────────────────────────────────────────────────┐
  │ CLIENT → SERVER                                          │
  │                                                          │
  │ RequestShop:InvokeServer("BUY", nama, qty)               │
  │   → {Success, Message, NewCoins}                         │
  │                                                          │
  │ RequestSell:InvokeServer("GET_LIST")                     │
  │   → {Items=[{Name,DisplayName,Price,Owned,...}], Coins}  │
  │                                                          │
  │ RequestSell:InvokeServer("SELL", nama, qty)              │
  │   → ✅ CONFIRMED via Cobalt                              │
  │                                                          │
  │ PlantCrop:FireServer(Vector3)    ✅ CONFIRMED            │
  │                                                          │
  │ SERVER → CLIENT                                          │
  │ HarvestCrop.OnClientEvent(cropName, qty, cropName)       │
  │   ✅ CONFIRMED: ("Padi", 1, "Padi")                      │
  │                                                          │
  │ BackpackAdded (BindableEvent, nil instance)              │
  │   GetNil("BackpackAdded","0_58612"):Fire()               │
  └──────────────────────────────────────────────────────────┘

  NPC PATHS (Cobalt Confirmed v12):
  ┌──────────────────────────────────────────────────────────┐
  │ NPC_Alat         → NPCs.NPC_Alat.npcalat                 │
  │ NPC_PedagangSawit→ NPCs.NPC_PedagangSawit.NPCPedagangSawit│
  │ NPC_Bibit        → NPCs.NPC_Bibit.npcbibit               │
  │ NPCPedagangTelur → NPCs.NPCPedagangTelur.NPCPedagangTelur│
  │ CoopPlot_1       → CoopPlots.CoopPlot_1 (ProximityPrompt)│
  └──────────────────────────────────────────────────────────┘

  ITEM PRICES (Cobalt GET_LIST Confirmed):
  Padi=10 | Jagung=20 | Tomat=30 | Terong=50 | Strawberry=75
]]

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name            = "🌾 SAWAH INDO v12.0 💸",
    LoadingTitle    = "XKID HUB",
    LoadingSubtitle = "Cobalt Spy v12 🔥",
    ConfigurationSaving = { Enabled = false },
    KeySystem       = false,
})

-- ══════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════
local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════
-- FLAGS
-- ══════════════════════════════════════════
_G.ScriptRunning    = true
_G.AutoFarm         = false
_G.AutoBeli         = false
_G.AutoTanam        = false
_G.AutoSell         = false
_G.AutoHarvest      = false
_G.PenangkalPetir   = false
_G.AntiAFK          = false
_G.AutoConfirm      = false
_G.NotifLevelUp     = true
_G.AutoMandi        = false

-- ══════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════
local PlayerData     = { Coins=0, Level=1, XP=0, Needed=50 }
local SiklusCount    = 0
local lightningHits  = 0
local levelUpCount   = 0
local totalEarned    = 0
local harvestCount   = 0
local SafePos        = nil
local MandiPos       = nil   -- posisi tempat pemandian
local LahanCache     = {}
local LahanCacheTime = 0
local BeliLoop       = nil
local SellLoop       = nil
local HarvestLoop    = nil
local NpcPositions   = {}
local selectedBibit  = "Bibit Padi"
local jumlahBeli     = 1
local dTanam         = 0.5
local waitPanen      = 60
local harvestInterval = 5   -- detik antar cek harvest

-- Item list confirmed dari Cobalt GET_LIST
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

-- NPC PATHS — confirmed dari Cobalt spy
local NPC_PATHS = {
    { name="NPC_Bibit",           path="NPCs.NPC_Bibit.npcbibit",                         label="🌱 Toko Bibit"    },
    { name="NPC_Alat",            path="NPCs.NPC_Alat.npcalat",                           label="🔧 Toko Alat"     },
    { name="NPC_PedagangSawit",   path="NPCs.NPC_PedagangSawit.NPCPedagangSawit",         label="🌴 Pedagang Sawit" },
    { name="NPCPedagangTelur",    path="NPCs.NPCPedagangTelur.NPCPedagangTelur",          label="🥚 Pedagang Telur" },
}

-- ══════════════════════════════════════════
-- NOTIF
-- ══════════════════════════════════════════
local function notif(title, body, dur)
    pcall(function()
        Rayfield:Notify({ Title=title, Content=body, Duration=dur or 3, Image=4483362458 })
    end)
    print("[XKID] "..title.." | "..tostring(body))
end

-- ══════════════════════════════════════════
-- CHARACTER
-- ══════════════════════════════════════════
local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPos()
    local r = getRoot(); return r and r.Position
end

local function tp(pos)
    local root = getRoot(); if not root then return false end
    if typeof(pos) == "Vector3" then
        root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    elseif typeof(pos) == "CFrame" then
        root.CFrame = pos
    end
    task.wait(0.3); return true
end

-- ══════════════════════════════════════════
-- BACKPACK — confirmed via getnilinstances()
-- GetNil("BackpackAdded","0_58612"):Fire()
-- ══════════════════════════════════════════
local function getBackpackEvent()
    if not getnilinstances then
        print("[XKID] getnilinstances tidak tersedia di executor ini")
        return nil
    end
    for _, obj in getnilinstances() do
        if obj.Name == "BackpackAdded" and obj:GetDebugId() == "0_58612" then
            return obj
        end
    end
    return nil
end

local function triggerBackpack()
    local ev = getBackpackEvent()
    if ev then
        pcall(function() ev:Fire() end)
        return true
    end
    return false
end

-- ══════════════════════════════════════════
-- REMOTE HELPER
-- ══════════════════════════════════════════
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
    if not r or not r:IsA("RemoteEvent") then
        return false, "'"..name.."' tidak ditemukan"
    end
    return pcall(function(...) r:FireServer(...) end, ...)
end

local function invokeRF(name, ...)
    local r = getR(name)
    if not r or not r:IsA("RemoteFunction") then
        return false, nil
    end
    local ok, res = pcall(function(...) return r:InvokeServer(...) end, ...)
    return ok, res
end

local function unwrap(res)
    if type(res) == "table" then
        return (type(res[1]) == "table") and res[1] or res
    end
    return nil
end

-- ══════════════════════════════════════════
-- ANTI AFK
-- ══════════════════════════════════════════
local antiAFKConn = nil

local function startAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect() end
    local lastTime = tick()
    antiAFKConn = RunService.Heartbeat:Connect(function()
        if not _G.AntiAFK then
            antiAFKConn:Disconnect(); antiAFKConn = nil; return
        end
        if tick() - lastTime >= 120 then
            lastTime = tick()
            local c = LocalPlayer.Character
            local hum = c and c:FindFirstChild("Humanoid")
            if hum then hum.Jump = true end
        end
    end)
end

-- ══════════════════════════════════════════
-- NPC — resolve path confirmed Cobalt
-- ══════════════════════════════════════════
local function resolveNpcPath(pathStr)
    local parts = string.split(pathStr, ".")
    local cur = Workspace
    for _, p in ipairs(parts) do
        cur = cur:FindFirstChild(p)
        if not cur then return nil end
    end
    if cur:IsA("BasePart") then return cur.Position end
    local hrp = cur:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position end
    if cur.PrimaryPart then return cur.PrimaryPart.Position end
    -- coba ambil posisi dari child pertama BasePart
    for _, child in ipairs(cur:GetChildren()) do
        if child:IsA("BasePart") then return child.Position end
    end
    return nil
end

local function scanNPC()
    NpcPositions = {}
    for _, entry in ipairs(NPC_PATHS) do
        local pos = resolveNpcPath(entry.path)
        if pos then
            NpcPositions[entry.name] = pos
            print(string.format("[XKID NPC] %s → X=%.1f Y=%.1f Z=%.1f", entry.name, pos.X, pos.Y, pos.Z))
        end
    end
    -- Scan tempat mandi (keyword: mandi, shower, hygiene, kolam, bathroom)
    local mandiKeywords = {"mandi","shower","hygiene","kolam","bathroom","kamar mandi","tempat mandi"}
    for _, v in pairs(Workspace:GetDescendants()) do
        local n = v.Name:lower()
        for _, kw in ipairs(mandiKeywords) do
            if n:find(kw) then
                local pos
                if v:IsA("BasePart") then pos = v.Position
                elseif v:IsA("Model") then
                    pos = v.PrimaryPart and v.PrimaryPart.Position
                end
                if pos then
                    MandiPos = pos
                    print(string.format("[XKID🚿] Tempat mandi: %s → X=%.1f Y=%.1f Z=%.1f", v.Name, pos.X, pos.Y, pos.Z))
                end
                break
            end
        end
    end
    -- Fallback keyword NPC lain
    local keywords = {"npc","toko","pedagang","shop","penjual","bibit"}
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("BasePart") then
            local n = v.Name:lower()
            for _, kw in ipairs(keywords) do
                if n:find(kw) and not NpcPositions[v.Name] then
                    local pos
                    if v:IsA("Model") then
                        pos = v.PrimaryPart and v.PrimaryPart.Position
                           or (v:FindFirstChild("HumanoidRootPart") and v.HumanoidRootPart.Position)
                    else pos = v.Position end
                    if pos then NpcPositions[v.Name] = pos end
                    break
                end
            end
        end
    end
    return NpcPositions
end

-- ══════════════════════════════════════════
-- SCAN LAHAN
-- ══════════════════════════════════════════
local function scanLahan()
    if tick() - LahanCacheTime < 10 and #LahanCache > 0 then return LahanCache end
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

-- ══════════════════════════════════════════
-- BELI BIBIT ✅ CONFIRMED
-- ══════════════════════════════════════════
local function beliBibit(nama, qty)
    nama = nama or selectedBibit
    qty  = qty  or jumlahBeli
    local ok, res = invokeRF("RequestShop", "BUY", nama, qty)
    if not ok then return false, "RequestShop gagal" end
    local data = unwrap(res)
    if data and data.Success then
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        return true, data.Message or "Berhasil"
    end
    return false, (data and data.Message) or "Gagal"
end

-- ══════════════════════════════════════════
-- JUAL ✅ CONFIRMED via Cobalt
-- RequestSell:InvokeServer("SELL", "Padi", 7)
-- ══════════════════════════════════════════
local function getInventoryJual()
    local ok, res = invokeRF("RequestSell", "GET_LIST")
    if not ok then return nil end
    local data = unwrap(res)
    if data then
        PlayerData.Coins = data.Coins or PlayerData.Coins
    end
    return data
end

local function jualItem(nama, qty)
    local ok, res = invokeRF("RequestSell", "SELL", nama, qty or 1)
    if not ok then return false, "Remote gagal", 0 end
    local data = unwrap(res)
    if data and data.Success then
        local earned = data.Earned or data.NewCoins and (data.NewCoins - PlayerData.Coins) or 0
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        totalEarned = totalEarned + earned
        return true, (data.Message or "Terjual"), earned
    end
    -- kalau server return langsung number coins (beberapa game begini)
    if type(res) == "number" then
        PlayerData.Coins = res
        return true, "Terjual", 0
    end
    return false, (data and data.Message) or "Gagal", 0
end

local function jualSemua()
    -- Ambil list dulu (confirmed GET_LIST)
    local data = getInventoryJual()
    if not data or not data.Items then return false, "GET_LIST gagal" end

    local totalItem = 0
    local totalCoin = 0
    for _, item in ipairs(data.Items) do
        if item.Owned and item.Owned > 0 then
            local ok, msg, earned = jualItem(item.Name, item.Owned)
            if ok then
                totalItem = totalItem + item.Owned
                totalCoin = totalCoin + (item.Price * item.Owned)
                print(string.format("[XKID💰] Jual %s x%d = +%d💰", item.Name, item.Owned, item.Price * item.Owned))
            else
                print(string.format("[XKID❌] Gagal jual %s: %s", item.Name, msg))
            end
            task.wait(0.3)
        end
    end

    if totalItem == 0 then return false, "Tidak ada item" end
    return true, totalItem.." item | +"..totalCoin.."💰 est."
end

-- ══════════════════════════════════════════
-- HARVEST — trigger via firesignal
-- HarvestCrop.OnClientEvent("Padi", 1, "Padi")
-- ══════════════════════════════════════════
local function autoHarvestTick()
    -- Harvest dengan cara trigger proximity prompt di lahan
    -- atau scan tanaman matang dan fire event
    local r = getR("HarvestCrop")
    if not r then return false end

    -- Cek apakah ada tanaman matang di workspace
    local harvested = 0
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Model") then
            local n = v.Name:lower()
            -- Cari ProximityPrompt harvest
            local pp = v:FindFirstChildWhichIsA("ProximityPrompt", true)
            if pp and (n:find("crop") or n:find("plant") or n:find("padi")
                    or n:find("jagung") or n:find("tomat") or n:find("terong")
                    or n:find("sawit") or n:find("durian") or n:find("strawberry")) then
                local rootPos = getPos()
                local partPos
                if v:IsA("BasePart") then partPos = v.Position
                elseif v.PrimaryPart then partPos = v.PrimaryPart.Position end

                if partPos and rootPos then
                    local dist = (partPos - rootPos).Magnitude
                    if dist < 20 then
                        pcall(function()
                            fireproximityprompt(pp)
                        end)
                        harvested = harvested + 1
                        task.wait(0.1)
                    end
                end
            end
        end
    end
    return harvested
end

-- ══════════════════════════════════════════
-- MANDI — teleport ke tempat mandi
-- ══════════════════════════════════════════
local function goMandi()
    if MandiPos then
        tp(MandiPos)
        notif("🚿 Mandi!","Teleport ke tempat mandi",3)
        return true
    end
    -- Cari lagi jika belum ditemukan
    local keywords = {"mandi","shower","hygiene","kolam"}
    for _, v in pairs(Workspace:GetDescendants()) do
        local n = v.Name:lower()
        for _, kw in ipairs(keywords) do
            if n:find(kw) then
                local pos
                if v:IsA("BasePart") then pos = v.Position
                elseif v:IsA("Model") and v.PrimaryPart then pos = v.PrimaryPart.Position end
                if pos then
                    MandiPos = pos
                    tp(pos)
                    notif("🚿 Mandi!","Ditemukan: "..v.Name,3)
                    return true
                end
            end
        end
    end
    notif("❌ Mandi","Tempat mandi tidak ditemukan!\nSet manual di tab TP",4)
    return false
end

-- ══════════════════════════════════════════
-- STOP ALL
-- ══════════════════════════════════════════
local function stopSemua()
    _G.AutoFarm=false; _G.AutoBeli=false; _G.AutoTanam=false
    _G.AutoSell=false; _G.AutoHarvest=false; _G.AutoMandi=false
    if BeliLoop   then pcall(function() task.cancel(BeliLoop)   end); BeliLoop=nil   end
    if SellLoop   then pcall(function() task.cancel(SellLoop)   end); SellLoop=nil   end
    if HarvestLoop then pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil end
    notif("⛔ STOP SEMUA","Semua auto dimatikan",3)
end

-- ══════════════════════════════════════════
-- INTERCEPT SERVER→CLIENT
-- ══════════════════════════════════════════
local function setupIntercepts()

    task.spawn(function()
        local r; for i=1,15 do r=getR("LightningStrike"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
            if not _G.PenangkalPetir then return end
            lightningHits = lightningHits + 1
            local root = getRoot(); if not root then return end
            if SafePos then
                root.CFrame = CFrame.new(SafePos.X, SafePos.Y+5, SafePos.Z)
                notif("⚡ DITANGKAL ✅","#"..lightningHits,2)
            else
                root.CFrame = root.CFrame + Vector3.new(0,80,0)
                notif("⚡ PETIR!","Set Safe Pos dulu!",3)
            end
        end)
    end)

    task.spawn(function()
        local r; for i=1,15 do r=getR("UpdateLevel"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
            if type(data) ~= "table" then return end
            PlayerData.Level  = data.Level  or PlayerData.Level
            PlayerData.XP     = data.XP     or PlayerData.XP
            PlayerData.Needed = data.Needed or PlayerData.Needed
            if data.LeveledUp and _G.NotifLevelUp then
                levelUpCount = levelUpCount + 1
                notif("🎉 LEVEL UP! #"..levelUpCount,
                    "Level "..tostring(data.Level).." | XP "..tostring(data.XP).."/"..tostring(data.Needed),6)
            end
        end)
    end)

    task.spawn(function()
        local r; for i=1,15 do r=getR("Notification"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(msg)
            print("[XKID🔔] "..tostring(msg))
            if type(msg) ~= "string" then return end
            local ml = msg:lower()
            if ml:find("hujan mulai") then
                notif("🌧 Hujan!","Tanaman tumbuh lebih cepat!",4)
            elseif ml:find("petir") or ml:find("gosong") then
                notif("⚡ KENA PETIR!",msg,4)
            elseif ml:find("mandi") or ml:find("segar") then
                notif("🚿 Mandi!",msg,3)
                -- Auto mandi jika toggle aktif
                if _G.AutoMandi then
                    task.delay(0.5, goMandi)
                end
            end
        end)
    end)

    -- HarvestCrop intercept — confirmed ("Padi", 1, "Padi")
    task.spawn(function()
        local r; for i=1,15 do r=getR("HarvestCrop"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(cropName, qty, _)
            harvestCount = harvestCount + (tonumber(qty) or 1)
            print(string.format("[XKID🌾] Panen: %s x%d | Total: %d", tostring(cropName), tonumber(qty) or 1, harvestCount))
        end)
        print("[XKID] ✅ HarvestCrop intercept aktif")
    end)

    -- SellCrop intercept
    task.spawn(function()
        local r; for i=1,15 do r=getR("SellCrop"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(p40, p41)
            if p41 and type(p41) == "string" then
                print("[XKID💰] SellCrop: "..p41)
                if _G.AutoSell and p41:find("OPEN") then
                    task.delay(0.5, function()
                        local ok, msg = jualSemua()
                        notif(ok and "Auto Sell ✅" or "Auto Sell ❌", msg, 3)
                    end)
                end
            end
        end)
    end)

    task.spawn(function()
        local r; for i=1,15 do r=getR("ConfirmAction"); if r then break end; task.wait(1) end
        if not r or not r:IsA("RemoteFunction") then return end
        r.OnClientInvoke = function(data)
            if _G.AutoConfirm then notif("✅ Auto Confirm",tostring(data),2); return true end
            return nil
        end
    end)

    print("[XKID] === SEMUA INTERCEPT SIAP ===")
end

-- ══════════════════════════════════════════
-- TABS
-- ══════════════════════════════════════════
local TabStatus  = Window:CreateTab("📊 Status",        nil)
local TabFarm    = Window:CreateTab("🤖 Auto Farm",     nil)
local TabBibit   = Window:CreateTab("🛒 Beli Bibit",    nil)
local TabJual    = Window:CreateTab("💰 Jual",          nil)
local TabHarvest = Window:CreateTab("🌾 Harvest",       nil)
local TabTanam   = Window:CreateTab("🌱 Tanam",         nil)
local TabLahan   = Window:CreateTab("🗺 Lahan",         nil)
local TabTP      = Window:CreateTab("📍 Teleport",      nil)
local TabPetir   = Window:CreateTab("⚡ Petir",         nil)
local TabBag     = Window:CreateTab("🎒 Backpack",      nil)
local TabSet     = Window:CreateTab("⚙ Setting",       nil)
local TabTest    = Window:CreateTab("🧪 Test Remote",   nil)

-- ══════════════════════════════════════════
-- TAB STATUS
-- ══════════════════════════════════════════
TabStatus:CreateSection("📊 Live Monitor")
local St = {
    farm    = TabStatus:CreateParagraph({Title="🤖 Auto Farm",    Content="🔴 OFF"}),
    harvest = TabStatus:CreateParagraph({Title="🌾 Auto Harvest", Content="🔴 OFF"}),
    sell    = TabStatus:CreateParagraph({Title="💰 Auto Sell",    Content="🔴 OFF"}),
    player  = TabStatus:CreateParagraph({Title="👤 Player",       Content="..."}),
    lahan   = TabStatus:CreateParagraph({Title="🗺 Lahan",        Content="Belum scan"}),
    petir   = TabStatus:CreateParagraph({Title="⚡ Petir",        Content="🔴 OFF"}),
    afk     = TabStatus:CreateParagraph({Title="🛡 Anti AFK",     Content="🔴 OFF"}),
    earn    = TabStatus:CreateParagraph({Title="💸 Session Stats",Content="0 💰"}),
}

task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            St.farm:Set({Title="🤖 Auto Farm",
                Content=_G.AutoFarm and ("🟢 RUNNING — Siklus "..SiklusCount) or "🔴 OFF"})
            St.harvest:Set({Title="🌾 Auto Harvest",
                Content=_G.AutoHarvest and ("🟢 AKTIF | Panen: "..harvestCount.."x") or
                    ("🔴 OFF | Total panen: "..harvestCount.."x")})
            St.sell:Set({Title="💰 Auto Sell",
                Content=_G.AutoSell and "🟢 AKTIF" or "🔴 OFF"})
            St.player:Set({Title="👤 "..LocalPlayer.Name,
                Content="💰 "..PlayerData.Coins
                    .."  ⭐ Lv."..PlayerData.Level
                    .."  📊 "..PlayerData.XP.."/"..PlayerData.Needed
                    .."\n🎉 Level up: "..levelUpCount.."x"})
            St.lahan:Set({Title="🗺 Lahan",
                Content=#LahanCache.." plot"
                    ..(LahanCacheTime>0 and (" | "..string.format("%.0fs ago",tick()-LahanCacheTime)) or "")})
            St.petir:Set({Title="⚡ Penangkal Petir",
                Content=(_G.PenangkalPetir and "🟢" or "🔴").." | "..lightningHits.."x ditangkal"
                    ..(SafePos and " | ✅ Safe" or " | ❌ Belum set")})
            St.afk:Set({Title="🛡 Anti AFK", Content=_G.AntiAFK and "🟢 AKTIF" or "🔴 OFF"})
            St.earn:Set({Title="💸 Session Stats",
                Content="Earned: "..totalEarned.."💰\nPanen: "..harvestCount.."x\nSiklus: "..SiklusCount})
        end)
        task.wait(1)
    end
end)

-- ══════════════════════════════════════════
-- TAB AUTO FARM — full loop v12
-- ══════════════════════════════════════════
TabFarm:CreateSection("🤖 Full Auto Farm v12")
TabFarm:CreateParagraph({Title="Flow v12",
    Content="1️⃣ Beli → RequestShop('BUY',nama,qty)\n"
        .."2️⃣ Tanam → PlantCrop(Vector3)\n"
        .."3️⃣ Tunggu panen\n"
        .."4️⃣ Harvest → ProximityPrompt/auto\n"
        .."5️⃣ Jual → SELL per item ✅\n"
        .."6️⃣ Mandi (opsional)\n\n"
        .."⚠️ Scan Lahan dulu di tab 🗺"})

TabFarm:CreateSlider({Name="Delay Tanam (s)", Range={0.1,3}, Increment=0.1, CurrentValue=0.5,
    Callback=function(v) dTanam=v end})
TabFarm:CreateSlider({Name="Tunggu Panen (s)", Range={10,300}, Increment=5, CurrentValue=60,
    Callback=function(v) waitPanen=v end})
TabFarm:CreateToggle({Name="🚿 Auto Mandi di tiap siklus", CurrentValue=false,
    Callback=function(v) _G.AutoMandi=v end})

TabFarm:CreateToggle({Name="🔥 FULL AUTO FARM", CurrentValue=false,
    Callback=function(v)
        _G.AutoFarm = v
        if not v then notif("AUTO FARM OFF","",2); return end
        if #LahanCache == 0 then scanLahan() end
        if #LahanCache == 0 then
            notif("⚠️","Scan Lahan dulu!",5); _G.AutoFarm=false; return
        end
        SiklusCount = 0
        notif("AUTO FARM ON 🔥", #LahanCache.." lahan | "..selectedBibit, 4)
        task.spawn(function()
            while _G.AutoFarm do
                SiklusCount = SiklusCount + 1

                -- 1. Beli
                local ok, msg = beliBibit(selectedBibit, jumlahBeli)
                notif(ok and "Beli ✅" or "Beli ❌", msg, 2)
                if not _G.AutoFarm then break end
                task.wait(1)

                -- 2. Tanam
                local planted = 0
                for _, pos in ipairs(LahanCache) do
                    if not _G.AutoFarm then break end
                    if fireEv("PlantCrop", pos) then planted=planted+1 end
                    task.wait(dTanam)
                end
                notif("Tanam ✅", planted.."/"..#LahanCache.." plot", 2)
                if not _G.AutoFarm then break end

                -- 3. Tunggu panen
                local w=0
                while w < waitPanen and _G.AutoFarm do task.wait(1); w=w+1 end
                if not _G.AutoFarm then break end

                -- 4. Harvest
                local h = autoHarvestTick()
                if h and h > 0 then notif("Harvest ✅", h.." tanaman", 2) end
                task.wait(2)

                -- 5. Mandi (opsional)
                if _G.AutoMandi then
                    goMandi()
                    task.wait(3)
                end

                -- 6. Jual
                local sOk, sMsg = jualSemua()
                notif(sOk and "Jual ✅" or "Jual ❌", sMsg, 3)
                task.wait(2)
            end
            notif("FARM STOP","Total: "..SiklusCount.." siklus | Earned: "..totalEarned.."💰",4)
        end)
    end})

TabFarm:CreateToggle({Name="🌱 Auto Tanam Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoTanam = v
        if v then
            task.spawn(function()
                while _G.AutoTanam do
                    if #LahanCache==0 then scanLahan() end
                    local c=0
                    for _, pos in ipairs(LahanCache) do
                        if not _G.AutoTanam then break end
                        if fireEv("PlantCrop",pos) then c=c+1 end
                        task.wait(dTanam)
                    end
                    notif("Tanam ✅",c.." plot",2); task.wait(5)
                end
            end)
            notif("Auto Tanam ON ✅","",3)
        else notif("Auto Tanam OFF","",2) end
    end})

TabFarm:CreateButton({Name="🛑 STOP SEMUA", Callback=function() stopSemua() end})

-- ══════════════════════════════════════════
-- TAB BELI BIBIT
-- ══════════════════════════════════════════
TabBibit:CreateSection("🌱 Beli Bibit")
local opsiB = {}
for _, b in ipairs(BIBIT_LIST) do
    table.insert(opsiB, b.icon.." "..b.name.." Lv."..b.minLv.." | "..b.price.."💰")
end
TabBibit:CreateDropdown({Name="Pilih Bibit", Options=opsiB, CurrentOption={opsiB[1]},
    Callback=function(v)
        for _, b in ipairs(BIBIT_LIST) do
            if v[1]:find(b.name,1,true) then selectedBibit=b.name; notif("Dipilih",b.name,2); break end
        end
    end})
TabBibit:CreateSlider({Name="Jumlah", Range={1,99}, Increment=1, CurrentValue=1,
    Callback=function(v) jumlahBeli=v end})
TabBibit:CreateButton({Name="🛒 BELI SEKARANG",
    Callback=function()
        task.spawn(function()
            local ok, msg = beliBibit(selectedBibit, jumlahBeli)
            notif(ok and "Beli ✅" or "❌", msg, 4)
        end)
    end})

TabBibit:CreateSection("⚡ Beli Cepat")
for _, b in ipairs(BIBIT_LIST) do
    local bb = b
    TabBibit:CreateButton({Name=bb.icon.." "..bb.name.." | "..bb.price.."💰",
        Callback=function()
            task.spawn(function()
                selectedBibit = bb.name
                local ok, msg = beliBibit(bb.name, jumlahBeli)
                notif(ok and "✅" or "❌", msg, 3)
            end)
        end})
end

TabBibit:CreateSection("📋 Lihat Stock")
TabBibit:CreateButton({Name="📋 GET_LIST Bibit",
    Callback=function()
        task.spawn(function()
            local ok, res = invokeRF("RequestShop","GET_LIST")
            if not ok then notif("❌","Gagal",3); return end
            local data = unwrap(res)
            if not data or not data.Seeds then notif("❌","Kosong",3); return end
            PlayerData.Coins = data.Coins or PlayerData.Coins
            local txt = "💰 "..tostring(data.Coins).."\n\n"
            for _, s in ipairs(data.Seeds) do
                txt=txt..(s.Locked and "🔒" or "✅").." "..s.Name
                    .." | x"..s.Owned.." | "..s.Price.."💰\n"
            end
            notif("Bibit Shop", txt, 10)
        end)
    end})

-- ══════════════════════════════════════════
-- TAB JUAL — v12 CONFIRMED
-- ══════════════════════════════════════════
TabJual:CreateSection("💰 Jual v12 — CONFIRMED")
TabJual:CreateParagraph({Title="✅ Method Confirmed",
    Content="RequestSell:InvokeServer('SELL', 'Padi', 7)\n"
        .."✅ Cobalt confirmed!\n\n"
        .."Script: GET_LIST → SELL per item\n"
        .."Item: Padi=10💰 Jagung=20💰 Tomat=30💰\n"
        .."Terong=50💰 Strawberry=75💰"})

TabJual:CreateButton({Name="💰 JUAL SEMUA",
    Callback=function()
        task.spawn(function()
            local ok, msg = jualSemua()
            notif(ok and "Jual ✅" or "❌", msg, 4)
        end)
    end})

TabJual:CreateToggle({Name="🔄 Auto Sell Loop (30s)", CurrentValue=false,
    Callback=function(v)
        _G.AutoSell = v
        if v then
            SellLoop = task.spawn(function()
                while _G.AutoSell do
                    local ok, msg = jualSemua()
                    notif(ok and "Auto Sell ✅" or "❌", msg, 3)
                    task.wait(30)
                end
            end)
            notif("Auto Sell ON ✅","Jual semua tiap 30s",3)
        else
            if SellLoop then pcall(function() task.cancel(SellLoop) end); SellLoop=nil end
            notif("Auto Sell OFF","",2)
        end
    end})

TabJual:CreateSection("📋 Preview Inventory")
TabJual:CreateButton({Name="📋 Lihat Inventory Jual",
    Callback=function()
        task.spawn(function()
            local data = getInventoryJual()
            if not data or not data.Items then notif("❌","GET_LIST gagal",3); return end
            local txt = "SellMult: "..tostring(data.SellMult).."\n💰 "..tostring(data.Coins).."\n\n"
            for _, item in ipairs(data.Items) do
                txt=txt..(item.Owned>0 and "✅" or "⬜").." "
                    ..item.DisplayName.." x"..item.Owned.." | "..item.Price.."💰\n"
            end
            notif("Inventory", txt, 10)
        end)
    end})

TabJual:CreateSection("🔧 Jual Manual Per Item")
local sellItemName = "Padi"
local sellItemQty  = 1
TabJual:CreateInput({Name="Nama Item", PlaceholderText="Padi / Jagung / Tomat",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellItemName=v end})
TabJual:CreateSlider({Name="Jumlah", Range={1,99}, Increment=1, CurrentValue=1,
    Callback=function(v) sellItemQty=v end})
TabJual:CreateButton({Name="💰 JUAL ITEM",
    Callback=function()
        task.spawn(function()
            local ok, msg, earned = jualItem(sellItemName, sellItemQty)
            notif(ok and "Jual ✅" or "❌", msg..(ok and " +"..earned.."💰" or ""), 4)
        end)
    end})

-- Tombol cepat per item
TabJual:CreateSection("⚡ Jual Cepat")
for _, item in ipairs(ITEM_LIST) do
    local it = item
    TabJual:CreateButton({Name=it.icon.." Jual "..it.name.." | "..it.price.."💰/pcs",
        Callback=function()
            task.spawn(function()
                -- GET_LIST dulu untuk cek stok
                local data = getInventoryJual()
                local owned = 0
                if data and data.Items then
                    for _, i in ipairs(data.Items) do
                        if i.Name == it.name then owned = i.Owned; break end
                    end
                end
                if owned == 0 then notif("⬜ "..it.name,"Stok kosong",3); return end
                local ok, msg, earned = jualItem(it.name, owned)
                notif(ok and "Jual ✅" or "❌",
                    it.name.." x"..owned..(ok and " +"..earned.."💰" or " | "..msg), 4)
            end)
        end})
end

TabJual:CreateSection("🍈 Buah")
TabJual:CreateButton({Name="🌴 Sawit — GET_FRUIT_LIST",
    Callback=function()
        task.spawn(function()
            local ok, res = invokeRF("RequestSell","GET_FRUIT_LIST","Sawit")
            local data = ok and unwrap(res) or nil
            notif("Sawit","Count: "..tostring(data and data.FruitCount or 0)
                .."\nCoins: "..tostring(data and data.Coins or 0),4)
        end)
    end})
TabJual:CreateButton({Name="🍈 Durian — GET_FRUIT_LIST",
    Callback=function()
        task.spawn(function()
            local ok, res = invokeRF("RequestSell","GET_FRUIT_LIST","Durian")
            local data = ok and unwrap(res) or nil
            notif("Durian","Count: "..tostring(data and data.FruitCount or 0)
                .."\nCoins: "..tostring(data and data.Coins or 0),4)
        end)
    end})
TabJual:CreateButton({Name="🥚 GET_EGG_LIST",
    Callback=function()
        task.spawn(function()
            local ok, res = invokeRF("RequestSell","GET_EGG_LIST")
            local data = ok and unwrap(res) or nil
            notif("Telur","Count: "..tostring(data and data.EggCount or 0)
                .."\nCoins: "..tostring(data and data.Coins or 0),4)
        end)
    end})

-- ══════════════════════════════════════════
-- TAB HARVEST
-- ══════════════════════════════════════════
TabHarvest:CreateSection("🌾 Auto Harvest")
TabHarvest:CreateParagraph({Title="✅ Confirmed",
    Content="HarvestCrop.OnClientEvent confirmed:\n"
        .."('Padi', 1, 'Padi')\n\n"
        .."Auto Harvest: scan ProximityPrompt\ntanaman & fireproximityprompt\n\n"
        .."⚠️ Harus dekat tanaman atau\ngunakan TP Lahan dulu"})

TabHarvest:CreateSlider({Name="Interval cek (s)", Range={1,30}, Increment=1, CurrentValue=5,
    Callback=function(v) harvestInterval=v end})

TabHarvest:CreateToggle({Name="🌾 AUTO HARVEST", CurrentValue=false,
    Callback=function(v)
        _G.AutoHarvest = v
        if v then
            HarvestLoop = task.spawn(function()
                while _G.AutoHarvest do
                    local h = autoHarvestTick()
                    if h and h > 0 then
                        notif("Harvest ✅", h.." tanaman dipanen",2)
                    end
                    task.wait(harvestInterval)
                end
            end)
            notif("Auto Harvest ON ✅","Scan tiap "..harvestInterval.."s",3)
        else
            if HarvestLoop then pcall(function() task.cancel(HarvestLoop) end); HarvestLoop=nil end
            notif("Auto Harvest OFF","Total: "..harvestCount.."x panen",3)
        end
    end})

TabHarvest:CreateButton({Name="🌾 HARVEST SEKALI",
    Callback=function()
        task.spawn(function()
            local h = autoHarvestTick()
            notif("Harvest", (h and h > 0) and h.." tanaman" or "Tidak ada tanaman dekat", 3)
        end)
    end})

TabHarvest:CreateButton({Name="🗑 Reset Counter Panen",
    Callback=function() harvestCount=0; notif("Reset ✅","",2) end})

-- ══════════════════════════════════════════
-- TAB TANAM
-- ══════════════════════════════════════════
TabTanam:CreateSection("🌱 Tanam Manual")
TabTanam:CreateButton({Name="🌱 TANAM SEMUA LAHAN",
    Callback=function()
        task.spawn(function()
            if #LahanCache==0 then scanLahan() end
            if #LahanCache==0 then notif("❌","Scan lahan dulu!",4); return end
            local c=0
            for _, pos in ipairs(LahanCache) do
                if fireEv("PlantCrop",pos) then c=c+1 end
                task.wait(dTanam)
            end
            notif("Tanam ✅",c.."/"..#LahanCache.." plot",3)
        end)
    end})
TabTanam:CreateButton({Name="📍 Tanam di Posisi Saya",
    Callback=function()
        local pos = getPos()
        if not pos then notif("❌","Posisi tidak valid",3); return end
        task.spawn(function()
            local ok,err = fireEv("PlantCrop",pos)
            notif(ok and "Tanam ✅" or "❌",
                ok and string.format("X=%.1f Z=%.1f",pos.X,pos.Z) or tostring(err),3)
        end)
    end})

-- ══════════════════════════════════════════
-- TAB LAHAN
-- ══════════════════════════════════════════
TabLahan:CreateSection("🗺 Scan Lahan")
local LahanPara = TabLahan:CreateParagraph({Title="Status",Content="Belum scan"})
TabLahan:CreateButton({Name="🔍 SCAN LAHAN",
    Callback=function()
        LahanCacheTime=0; local l=scanLahan()
        LahanPara:Set({Title="Status",
            Content=#l.." plot\n"..(#l>0 and "✅ Siap!" or "❌ Tidak ada")})
        notif("Scan ✅",#l.." plot",3)
    end})
TabLahan:CreateButton({Name="📊 Lihat Posisi",
    Callback=function()
        if #LahanCache==0 then notif("❌","Scan dulu!",3); return end
        local txt=#LahanCache.." plot:\n"
        for i,pos in ipairs(LahanCache) do
            if i>8 then txt=txt.."...dan "..(#LahanCache-8).." lagi"; break end
            txt=txt..string.format("#%d X=%.0f Z=%.0f\n",i,pos.X,pos.Z)
        end
        notif("Posisi Lahan",txt,8)
    end})
TabLahan:CreateButton({Name="🗑 Reset Cache",
    Callback=function() LahanCache={}; LahanCacheTime=0; notif("Reset ✅","",2) end})

-- ══════════════════════════════════════════
-- TAB TELEPORT — v12: NPC + Sell + Mandi
-- ══════════════════════════════════════════
TabTP:CreateSection("🏪 TP ke NPC")
TabTP:CreateParagraph({Title="✅ NPC Confirmed (Cobalt v12)",
    Content="NPC_Bibit, NPC_Alat,\nNPC_PedagangSawit, NPCPedagangTelur\n\n"
        .."Scan untuk ambil koordinat live"})

local NpcParaTP = TabTP:CreateParagraph({Title="NPC Status", Content="Belum scan"})

TabTP:CreateButton({Name="🔍 SCAN NPC & MANDI",
    Callback=function()
        local npcs = scanNPC()
        local count=0; local txt=""
        for name, pos in pairs(npcs) do
            count=count+1
            txt=txt..string.format("• %s X=%.0f Z=%.0f\n",name,pos.X,pos.Z)
        end
        if MandiPos then txt=txt..string.format("🚿 Mandi X=%.0f Z=%.0f",MandiPos.X,MandiPos.Z) end
        NpcParaTP:Set({Title=count.." NPC ditemukan", Content=count>0 and txt or "Tidak ada"})
        notif("Scan ✅",count.." NPC"..(MandiPos and " + Mandi ✅" or ""),3)
    end})

-- Tombol TP per NPC
for _, entry in ipairs(NPC_PATHS) do
    local e = entry
    TabTP:CreateButton({Name="🚀 "..e.label,
        Callback=function()
            local pos = NpcPositions[e.name] or resolveNpcPath(e.path)
            if pos then
                tp(pos)
                notif("TP ✅", e.label..string.format("\nX=%.1f Z=%.1f",pos.X,pos.Z),3)
            else
                notif("❌",e.name.." tidak ditemukan\nCoba Scan dulu",4)
            end
        end})
end

TabTP:CreateSection("🚿 Teleport Mandi")
TabTP:CreateParagraph({Title="Cara Pakai",
    Content="1. Scan NPC & Mandi dulu\n2. Atau Set Manual posisi mandi\n3. TP langsung ke tempat mandi\n\nAuto Mandi: aktifkan di Auto Farm\natau toggle di bawah"})

TabTP:CreateButton({Name="🚿 TP KE TEMPAT MANDI",
    Callback=function()
        goMandi()
    end})

TabTP:CreateButton({Name="📍 SET POSISI MANDI (posisi saya)",
    Callback=function()
        local p = getPos()
        if p then
            MandiPos = p
            notif("Mandi Pos ✅",string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z),4)
        end
    end})

TabTP:CreateToggle({Name="🚿 Auto Mandi (saat notif mandi)", CurrentValue=false,
    Callback=function(v)
        _G.AutoMandi = v
        notif("Auto Mandi", v and "ON ✅" or "OFF", 2)
    end})

TabTP:CreateSection("📌 TP ke NPC Terdekat & Manual")
TabTP:CreateButton({Name="🎯 TP ke NPC Terdekat",
    Callback=function()
        local pos = getPos(); if not pos then return end
        local closest, closestDist, closestName = nil, math.huge, ""
        for name, npos in pairs(NpcPositions) do
            local d=(npos-pos).Magnitude
            if d<closestDist then closestDist=d; closest=npos; closestName=name end
        end
        if closest then
            tp(closest)
            notif("TP ✅",closestName..string.format(" | %.0f studs",closestDist),3)
        else notif("❌","Scan NPC dulu!",3) end
    end})

local tpX, tpY, tpZ = 0, 5, 0
TabTP:CreateInput({Name="X", PlaceholderText="-99",
    RemoveTextAfterFocusLost=false, Callback=function(v) tpX=tonumber(v) or 0 end})
TabTP:CreateInput({Name="Y", PlaceholderText="39",
    RemoveTextAfterFocusLost=false, Callback=function(v) tpY=tonumber(v) or 5 end})
TabTP:CreateInput({Name="Z", PlaceholderText="-259",
    RemoveTextAfterFocusLost=false, Callback=function(v) tpZ=tonumber(v) or 0 end})
TabTP:CreateButton({Name="🚀 TP ke Koordinat",
    Callback=function()
        tp(Vector3.new(tpX,tpY,tpZ))
        notif("TP ✅",string.format("X=%.1f Y=%.1f Z=%.1f",tpX,tpY,tpZ),3)
    end})
TabTP:CreateButton({Name="📍 Print Posisi Saya",
    Callback=function()
        local pos=getPos()
        if pos then
            notif("Posisi",string.format("X=%.2f\nY=%.2f\nZ=%.2f",pos.X,pos.Y,pos.Z),5)
            print(string.format("[XKID] X=%.4f Y=%.4f Z=%.4f",pos.X,pos.Y,pos.Z))
        end
    end})

-- ══════════════════════════════════════════
-- TAB PETIR
-- ══════════════════════════════════════════
TabPetir:CreateSection("⚡ Penangkal Petir")
TabPetir:CreateButton({Name="📍 SET SAFE POSITION",
    Callback=function()
        local p=getPos()
        if p then
            SafePos=p
            notif("Safe Pos ✅",string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z),4)
        end
    end})
TabPetir:CreateToggle({Name="⚡ Penangkal Petir AKTIF", CurrentValue=false,
    Callback=function(v)
        _G.PenangkalPetir=v
        if v and not SafePos then notif("⚠️","Set Safe Pos dulu!",4) end
        notif("Penangkal Petir",v and "ON ✅" or "OFF",2)
    end})
TabPetir:CreateButton({Name="🗑 Reset Counter",
    Callback=function() lightningHits=0; notif("Reset ✅","",2) end})

-- ══════════════════════════════════════════
-- TAB BACKPACK — v12 NEW
-- ══════════════════════════════════════════
TabBag:CreateSection("🎒 Backpack")
TabBag:CreateParagraph({Title="✅ Confirmed (Cobalt)",
    Content="BindableEvent di nil instances:\n"
        .."Name: BackpackAdded\n"
        .."DebugId: 0_58612\n\n"
        .."GetNil('BackpackAdded','0_58612'):Fire()\n\n"
        .."⚠️ Butuh executor dengan getnilinstances()\n"
        .."(Synapse X, KRNL, Fluxus, dll)"})

TabBag:CreateButton({Name="🎒 TRIGGER BACKPACK",
    Callback=function()
        local ok = triggerBackpack()
        if ok then
            notif("Backpack ✅","BackpackAdded:Fire() berhasil!",4)
        else
            notif("❌ Backpack",
                "Gagal! Kemungkinan:\n"
                .."• Executor tidak support getnilinstances\n"
                .."• DebugId berubah (cek ulang)\n"
                .."• Event sudah tidak ada",5)
        end
    end})

TabBag:CreateSection("🔍 Cari Event Nil")
TabBag:CreateButton({Name="🔍 Scan nil instances (Backpack)",
    Callback=function()
        if not getnilinstances then
            notif("❌","Executor tidak support getnilinstances",4); return
        end
        local found = {}
        for _, obj in getnilinstances() do
            local n = obj.Name:lower()
            if n:find("backpack") or n:find("bag") or n:find("inventory") then
                table.insert(found, obj.Name.." | "..obj:GetDebugId())
                print("[XKID🎒] "..obj.Name.." | DebugId: "..obj:GetDebugId().." | Class: "..obj.ClassName)
            end
        end
        if #found > 0 then
            notif("🎒 Ditemukan", table.concat(found,"\n"), 8)
        else
            notif("⬜ Tidak ditemukan","Tidak ada nil instance backpack",4)
        end
    end})

TabBag:CreateButton({Name="📋 Scan SEMUA nil instances",
    Callback=function()
        if not getnilinstances then
            notif("❌","Executor tidak support getnilinstances",4); return
        end
        local count=0
        for _, obj in getnilinstances() do
            count=count+1
            print(string.format("[XKID NIL] [%d] %s | %s | %s",
                count, obj.Name, obj.ClassName, obj:GetDebugId()))
        end
        notif("Nil Scan ✅",count.." objects\nLihat console F9",5)
    end})

-- ══════════════════════════════════════════
-- TAB SETTING
-- ══════════════════════════════════════════
TabSet:CreateSection("🛡 Anti AFK")
TabSet:CreateToggle({Name="🛡 Anti AFK", CurrentValue=false,
    Callback=function(v)
        _G.AntiAFK=v
        if v then startAntiAFK() end
        notif("Anti AFK",v and "ON ✅ (jump/2 menit)" or "OFF",3)
    end})

TabSet:CreateSection("⚙ Farm Setting")
TabSet:CreateSlider({Name="Delay Tanam (s)", Range={0.1,3}, Increment=0.1, CurrentValue=0.5,
    Callback=function(v) dTanam=v end})
TabSet:CreateSlider({Name="Tunggu Panen (s)", Range={10,300}, Increment=5, CurrentValue=60,
    Callback=function(v) waitPanen=v end})
TabSet:CreateSlider({Name="Harvest interval (s)", Range={1,30}, Increment=1, CurrentValue=5,
    Callback=function(v) harvestInterval=v end})

TabSet:CreateSection("✅ Lain")
TabSet:CreateToggle({Name="✅ Auto Confirm", CurrentValue=false,
    Callback=function(v) _G.AutoConfirm=v; notif("Auto Confirm",v and "ON" or "OFF",2) end})
TabSet:CreateToggle({Name="🎉 Notif Level Up", CurrentValue=true,
    Callback=function(v) _G.NotifLevelUp=v end})
TabSet:CreateButton({Name="🛑 STOP SEMUA", Callback=function() stopSemua() end})
TabSet:CreateButton({Name="🔄 Reset Stats Session",
    Callback=function()
        totalEarned=0; harvestCount=0; SiklusCount=0; levelUpCount=0
        notif("Reset ✅","Semua stats di-reset",2)
    end})

-- ══════════════════════════════════════════
-- TAB TEST REMOTE
-- ══════════════════════════════════════════
TabTest:CreateSection("📋 Remote Confirmed v12")
TabTest:CreateParagraph({Title="Cobalt Confirmed",
    Content="✅ RequestShop('BUY',nama,qty)\n"
        .."✅ RequestShop('GET_LIST')\n"
        .."✅ RequestSell('GET_LIST')\n"
        .."✅ RequestSell('SELL','Padi',7) ← v12!\n"
        .."✅ RequestSell('GET_SEED_LIST')\n"
        .."✅ RequestSell('GET_EGG_LIST')\n"
        .."✅ RequestSell('GET_FRUIT_LIST','X')\n"
        .."✅ PlantCrop:FireServer(Vector3)\n"
        .."✅ HarvestCrop.OnClientEvent\n"
        .."✅ BackpackAdded (nil, DebugId 0_58612)"})

TabTest:CreateSection("🔍 Test SELL")
local sellCmd, sellArg, sellQty2 = "SELL", "Padi", "7"
TabTest:CreateInput({Name="Command", PlaceholderText="SELL / GET_LIST",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellCmd=v end})
TabTest:CreateInput({Name="Arg1 (nama)", PlaceholderText="Padi",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellArg=v end})
TabTest:CreateInput({Name="Arg2 (qty)", PlaceholderText="7",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellQty2=v end})
TabTest:CreateButton({Name="🔥 Test RequestSell",
    Callback=function()
        task.spawn(function()
            local ok, res
            local qty = tonumber(sellQty2)
            if qty and sellArg ~= "" then
                ok, res = invokeRF("RequestSell", sellCmd, sellArg, qty)
            elseif sellArg ~= "" then
                ok, res = invokeRF("RequestSell", sellCmd, sellArg)
            else
                ok, res = invokeRF("RequestSell", sellCmd)
            end
            notif("RequestSell("..sellCmd..")",
                ok and "✅ lihat console" or "❌ "..tostring(res), 5)
            if ok then
                local d = unwrap(res) or res
                if type(d) == "table" then
                    for k,v in pairs(d) do
                        if type(v)~="table" then
                            print(string.format("[XKID SELL] %s = %s",tostring(k),tostring(v)))
                        end
                    end
                else
                    print("[XKID SELL] result = "..tostring(d))
                end
            end
        end)
    end})

TabTest:CreateSection("⚡ Quick Test")
for _, q in ipairs({
    {"SummonRain",   "EV", "🌧 SummonRain"},
    {"SkipTutorial", "EV", "📖 SkipTutorial"},
    {"RefreshShop",  "EV", "🔄 RefreshShop"},
}) do
    local qq=q
    TabTest:CreateButton({Name=qq[3],
        Callback=function()
            task.spawn(function()
                if qq[2]=="EV" then
                    local ok,err=fireEv(qq[1])
                    notif(qq[1],ok and "Fired ✅" or "❌ "..tostring(err),3)
                end
            end)
        end})
end

-- ══════════════════════════════════════════
-- INIT
-- ══════════════════════════════════════════
setupIntercepts()

task.spawn(function()
    task.wait(3)
    scanLahan()
    scanNPC()
    local nc=0; for _ in pairs(NpcPositions) do nc=nc+1 end
    notif("Auto Scan ✅",
        #LahanCache.." lahan | "..nc.." NPC"
        ..(MandiPos and " | 🚿 Mandi ✅" or ""), 5)
end)

notif("🌾 SAWAH INDO v12.0","Welcome "..LocalPlayer.Name.."! 🔥",5)
task.wait(1.2)
notif("✅ v12 Update",
    "✅ SELL confirmed ('SELL','Padi',7)\n"
    .."✅ Backpack (nil instance)\n"
    .."✅ Auto Harvest\n"
    .."✅ TP Mandi & NPC Sell\n"
    .."✅ Total Earned tracker",8)

print(string.rep("═",50))
print("  🌾 SAWAH INDO v12.0 — XKID HUB")
print("  SELL Confirmed + Backpack + Harvest + Mandi")
print("  Player: "..LocalPlayer.Name)
print(string.rep("═",50))
