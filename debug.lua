-- ╔══════════════════════════════════════════════════╗
-- ║   🌾 SAWAH INDO v11.0 — XKID HUB                ║
-- ║   100% Confirmed Cobalt Spy Edition              ║
-- ║   Anti AFK + Teleport NPC + AUTO SELL           ║
-- ╚══════════════════════════════════════════════════╝

--[[
  REMOTE CONFIRMED (Cobalt Outgoing v11):
  ┌─────────────────────────────────────────────────────────┐
  │ CLIENT → SERVER                                         │
  │                                                         │
  │ RequestShop:InvokeServer("BUY", nama, qty)              │
  │   → Return: {Success, Message, NewCoins}                │
  │                                                         │
  │ RequestSell:InvokeServer("SELL", nama, qty)             │
  │   → Return: {Success, Message, NewCoins}  [v11 FIXED]  │
  │                                                         │
  │ RequestSell:InvokeServer("SELL_ALL")                    │
  │   → Return: {Success, TotalEarned, NewCoins} [v11]     │
  │                                                         │
  │ PlantCrop:FireServer(Vector3)                           │
  │   → Tanam bibit di posisi lahan                         │
  │                                                         │
  │ HarvestCrop (client event — server driven)             │
  └─────────────────────────────────────────────────────────┘

  NPC PATHS (Cobalt Confirmed v11):
  ┌─────────────────────────────────────────────────────────┐
  │ NPC_Alat        → Workspace.NPCs.NPC_Alat               │
  │ NPC_PedagangSawit → Workspace.NPCs.NPC_PedagangSawit    │
  │ NPC_Bibit       → Workspace.NPCs.NPC_Bibit              │
  │ NPCPedagangTelur → Workspace.NPCs.NPCPedagangTelur      │
  └─────────────────────────────────────────────────────────┘
]]

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name            = "🌾 SAWAH INDO v11.0 💸",
    LoadingTitle    = "XKID HUB",
    LoadingSubtitle = "Cobalt Spy Edition 🔥",
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
_G.ScriptRunning  = true
_G.AutoFarm       = false
_G.AutoBeli       = false
_G.AutoTanam      = false
_G.AutoSell       = false
_G.PenangkalPetir = false
_G.AntiAFK        = false
_G.AutoConfirm    = false
_G.NotifLevelUp   = true

-- ══════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════
local PlayerData     = { Coins=0, Level=1, XP=0, Needed=50 }
local SiklusCount    = 0
local lightningHits  = 0
local levelUpCount   = 0
local totalEarned    = 0
local SafePos        = nil
local LahanCache     = {}
local LahanCacheTime = 0
local BeliLoop       = nil
local SellLoop       = nil
local selectedBibit  = "Bibit Padi"
local jumlahBeli     = 1
local dTanam         = 0.5
local waitPanen      = 60
local sellMode       = "SELL_ALL"   -- "SELL_ALL" atau "SELL" per item
local selectedSell   = "Padi"

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
    { name="NPC_Alat",            path="NPCs.NPC_Alat.npcalat" },
    { name="NPC_PedagangSawit",   path="NPCs.NPC_PedagangSawit.NPCPedagangSawit" },
    { name="NPC_Bibit",           path="NPCs.NPC_Bibit.npcbibit" },
    { name="NPCPedagangTelur",    path="NPCs.NPCPedagangTelur.NPCPedagangTelur" },
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
        root.CFrame = CFrame.new(pos.X, pos.Y + 5, pos.Z)
    elseif typeof(pos) == "CFrame" then
        root.CFrame = pos
    end
    task.wait(0.3); return true
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
-- SCAN NPC — v11: pakai path confirmed dari Cobalt
-- ══════════════════════════════════════════
local NpcPositions = {}

local function resolveNpcPath(pathStr)
    -- traverse "NPCs.NPC_Bibit.npcbibit" dari Workspace
    local parts = pathStr:split(".")
    local cur = Workspace
    for _, p in ipairs(parts) do
        cur = cur:FindFirstChild(p)
        if not cur then return nil end
    end
    -- ambil posisi
    if cur:IsA("BasePart") then return cur.Position end
    local hrp = cur:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position end
    if cur.PrimaryPart then return cur.PrimaryPart.Position end
    return nil
end

local function scanNPC()
    NpcPositions = {}
    -- Scan dari NPC_PATHS (Cobalt confirmed)
    for _, entry in ipairs(NPC_PATHS) do
        local pos = resolveNpcPath(entry.path)
        if pos then
            NpcPositions[entry.name] = pos
            print(string.format("[XKID NPC] %s → X=%.1f Y=%.1f Z=%.1f", entry.name, pos.X, pos.Y, pos.Z))
        end
    end
    -- Fallback: keyword scan
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
                    else
                        pos = v.Position
                    end
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
-- JUAL — v11 CONFIRMED + SELL_ALL
-- RequestSell:InvokeServer("SELL_ALL")
-- RequestSell:InvokeServer("SELL", nama, qty)
-- ══════════════════════════════════════════
local function jualSemua()
    local ok, res = invokeRF("RequestSell", "SELL_ALL")
    if not ok then
        -- fallback: coba GET_LIST dulu lalu SELL satu per satu
        local listOk, listRes = invokeRF("RequestSell", "GET_LIST")
        if not listOk then return false, "SELL_ALL & GET_LIST gagal" end
        local data = unwrap(listRes)
        if not data or not data.Items then return false, "Data kosong" end
        local earned = 0
        for _, item in ipairs(data.Items) do
            if item.Owned and item.Owned > 0 then
                local sOk, sRes = invokeRF("RequestSell", "SELL", item.DisplayName or item.Name, item.Owned)
                local sData = unwrap(sRes)
                if sOk and sData and sData.Success then
                    earned = earned + (sData.Earned or 0)
                    PlayerData.Coins = sData.NewCoins or PlayerData.Coins
                end
                task.wait(0.3)
            end
        end
        totalEarned = totalEarned + earned
        return true, "Fallback SELL | +"..earned.."💰"
    end
    local data = unwrap(res)
    if data and data.Success then
        local earned = data.TotalEarned or data.Earned or 0
        totalEarned = totalEarned + earned
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        return true, "+"..earned.."💰 | Total: "..totalEarned.."💰"
    end
    return false, (data and data.Message) or "Gagal"
end

local function jualItem(nama, qty)
    local ok, res = invokeRF("RequestSell", "SELL", nama, qty or 1)
    if not ok then return false, "Gagal" end
    local data = unwrap(res)
    if data and data.Success then
        local earned = data.Earned or 0
        totalEarned = totalEarned + earned
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        return true, (data.Message or "Terjual").." +"..earned.."💰"
    end
    return false, (data and data.Message) or "Gagal"
end

-- ══════════════════════════════════════════
-- TANAM
-- ══════════════════════════════════════════
local function tanamSemua()
    local lahans = scanLahan()
    if #lahans == 0 then return 0 end
    local count = 0
    for _, pos in ipairs(lahans) do
        if not _G.AutoTanam and not _G.AutoFarm then break end
        local ok = fireEv("PlantCrop", pos)
        if ok then count=count+1 end
        task.wait(dTanam)
    end
    return count
end

-- ══════════════════════════════════════════
-- STOP ALL
-- ══════════════════════════════════════════
local function stopSemua()
    _G.AutoFarm=false; _G.AutoBeli=false; _G.AutoTanam=false; _G.AutoSell=false
    if BeliLoop then pcall(function() task.cancel(BeliLoop) end); BeliLoop=nil end
    if SellLoop then pcall(function() task.cancel(SellLoop) end); SellLoop=nil end
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
            print("[XKID⚡] Petir! Reason="..tostring(data and data.Reason))
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
        print("[XKID] ✅ LightningStrike aktif")
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
                    "Level "..tostring(data.Level).." | XP "..tostring(data.XP).."/"..tostring(data.Needed), 6)
            end
        end)
        print("[XKID] ✅ UpdateLevel aktif")
    end)

    task.spawn(function()
        local r; for i=1,15 do r=getR("Notification"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(msg)
            print("[XKID🔔] "..tostring(msg))
            if type(msg) ~= "string" then return end
            if msg:lower():find("hujan mulai") then
                notif("🌧 Hujan!","Tanaman tumbuh lebih cepat!",4)
            elseif msg:lower():find("petir") or msg:lower():find("gosong") then
                notif("⚡ KENA PETIR!",msg,4)
            elseif msg:lower():find("mandi") or msg:lower():find("segar") then
                notif("🚿 Mandi!",msg,3)
            end
        end)
        print("[XKID] ✅ Notification aktif")
    end)

    task.spawn(function()
        local r; for i=1,15 do r=getR("HarvestCrop"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(cropName, qty, _)
            print(string.format("[XKID🌾] Panen: %s x%d", tostring(cropName), tonumber(qty) or 1))
        end)
        print("[XKID] ✅ HarvestCrop aktif")
    end)

    task.spawn(function()
        local r; for i=1,15 do r=getR("SellCrop"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(p40, p41)
            -- Intercept kapan GUI jual dibuka
            if p41 and type(p41) == "string" then
                print("[XKID💰] SellCrop event: "..p41)
                if _G.AutoSell and p41:find("OPEN") then
                    -- Auto trigger sell saat GUI terbuka
                    task.delay(0.5, function()
                        local ok, msg = jualSemua()
                        notif(ok and "Auto Sell ✅" or "Auto Sell ❌", msg, 3)
                    end)
                end
            end
        end)
        print("[XKID] ✅ SellCrop intercept aktif")
    end)

    task.spawn(function()
        local r; for i=1,15 do r=getR("ConfirmAction"); if r then break end; task.wait(1) end
        if not r or not r:IsA("RemoteFunction") then return end
        r.OnClientInvoke = function(data)
            if _G.AutoConfirm then notif("✅ Auto Confirm",tostring(data),2); return true end
            return nil
        end
        print("[XKID] ✅ ConfirmAction aktif")
    end)

    print("[XKID] === SEMUA INTERCEPT SIAP ===")
end

-- ══════════════════════════════════════════
-- TABS
-- ══════════════════════════════════════════
local TabStatus = Window:CreateTab("📊 Status",       nil)
local TabFarm   = Window:CreateTab("🤖 Auto Farm",    nil)
local TabBibit  = Window:CreateTab("🛒 Beli Bibit",   nil)
local TabJual   = Window:CreateTab("💰 Jual",         nil)
local TabTanam  = Window:CreateTab("🌱 Tanam",        nil)
local TabLahan  = Window:CreateTab("🌾 Lahan",        nil)
local TabNPC    = Window:CreateTab("📍 Teleport NPC", nil)
local TabPetir  = Window:CreateTab("⚡ Petir",        nil)
local TabSet    = Window:CreateTab("⚙ Setting",      nil)
local TabTest   = Window:CreateTab("🧪 Test Remote",  nil)

-- ══════════════════════════════════════════
-- TAB STATUS
-- ══════════════════════════════════════════
TabStatus:CreateSection("📊 Live Monitor")
local St = {
    farm   = TabStatus:CreateParagraph({Title="🤖 Auto Farm",  Content="🔴 OFF"}),
    beli   = TabStatus:CreateParagraph({Title="🛒 Auto Beli",  Content="🔴 OFF"}),
    tanam  = TabStatus:CreateParagraph({Title="🌱 Auto Tanam", Content="🔴 OFF"}),
    sell   = TabStatus:CreateParagraph({Title="💰 Auto Sell",  Content="🔴 OFF"}),
    player = TabStatus:CreateParagraph({Title="👤 Player",     Content="..."}),
    lahan  = TabStatus:CreateParagraph({Title="🌾 Lahan",      Content="Belum scan"}),
    petir  = TabStatus:CreateParagraph({Title="⚡ Petir",      Content="🔴 OFF"}),
    afk    = TabStatus:CreateParagraph({Title="🛡 Anti AFK",   Content="🔴 OFF"}),
    earn   = TabStatus:CreateParagraph({Title="💸 Total Earned", Content="0 💰"}),
}

task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            St.farm:Set({Title="🤖 Auto Farm",
                Content=_G.AutoFarm and ("🟢 RUNNING — Siklus "..SiklusCount) or "🔴 OFF"})
            St.beli:Set({Title="🛒 Auto Beli",
                Content=_G.AutoBeli and ("🟢 "..selectedBibit.." x"..jumlahBeli) or "🔴 OFF"})
            St.tanam:Set({Title="🌱 Auto Tanam",
                Content=_G.AutoTanam and "🟢 RUNNING" or "🔴 OFF"})
            St.sell:Set({Title="💰 Auto Sell",
                Content=_G.AutoSell and ("🟢 Mode: "..sellMode) or "🔴 OFF"})
            St.player:Set({Title="👤 "..LocalPlayer.Name,
                Content="💰 "..PlayerData.Coins.."  ⭐ Lv."..PlayerData.Level
                    .."  📊 "..PlayerData.XP.."/"..PlayerData.Needed
                    .."\n🎉 Level up: "..levelUpCount.."x"})
            St.lahan:Set({Title="🌾 Lahan",
                Content=#LahanCache.." plot"
                    ..(LahanCacheTime>0 and (" | "..string.format("%.0fs ago",tick()-LahanCacheTime)) or "")})
            St.petir:Set({Title="⚡ Penangkal Petir",
                Content=(_G.PenangkalPetir and "🟢" or "🔴").." | "..lightningHits.."x ditangkal"
                    ..(SafePos and " | ✅ Safe" or " | ❌ Belum set")})
            St.afk:Set({Title="🛡 Anti AFK", Content=_G.AntiAFK and "🟢 AKTIF" or "🔴 OFF"})
            St.earn:Set({Title="💸 Total Earned Session", Content=totalEarned.." 💰"})
        end)
        task.wait(1)
    end
end)

-- ══════════════════════════════════════════
-- TAB AUTO FARM — v11: includes SELL step
-- ══════════════════════════════════════════
TabFarm:CreateSection("🤖 Full Auto Farm v11")
TabFarm:CreateParagraph({Title="Flow v11",
    Content="1️⃣ Beli → RequestShop('BUY',nama,qty)\n"
        .."2️⃣ Tanam → PlantCrop(Vector3)\n"
        .."3️⃣ Tunggu panen\n"
        .."4️⃣ Jual → RequestSell('SELL_ALL') ✅\n\n"
        .."⚠️ Scan Lahan dulu di tab 🌾"})

TabFarm:CreateSlider({Name="Delay Tanam (s)", Range={0.1,3}, Increment=0.1, CurrentValue=0.5,
    Callback=function(v) dTanam=v end})
TabFarm:CreateSlider({Name="Tunggu Panen (s)", Range={10,300}, Increment=5, CurrentValue=60,
    Callback=function(v) waitPanen=v end})

TabFarm:CreateToggle({Name="🔥 FULL AUTO FARM (+ Auto Sell)", CurrentValue=false,
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
                -- Beli
                local ok, msg = beliBibit(selectedBibit, jumlahBeli)
                notif(ok and "Beli ✅" or "Beli ❌", msg, 2)
                if not _G.AutoFarm then break end; task.wait(1)
                -- Tanam
                local planted = 0
                for _, pos in ipairs(LahanCache) do
                    if not _G.AutoFarm then break end
                    if fireEv("PlantCrop", pos) then planted=planted+1 end
                    task.wait(dTanam)
                end
                notif("Tanam ✅", planted.."/"..#LahanCache.." plot", 2)
                if not _G.AutoFarm then break end
                -- Tunggu panen
                local w=0
                while w < waitPanen and _G.AutoFarm do task.wait(1); w=w+1 end
                if not _G.AutoFarm then break end
                -- Jual (v11 confirmed!)
                local sOk, sMsg = jualSemua()
                notif(sOk and "Jual ✅" or "Jual ❌", sMsg, 3)
                task.wait(2)
            end
            notif("FARM STOP","Total: "..SiklusCount.." siklus | Earned: "..totalEarned.."💰",4)
        end)
    end})

TabFarm:CreateToggle({Name="🛒 Auto Beli Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoBeli = v
        if v then
            BeliLoop = task.spawn(function()
                while _G.AutoBeli do
                    local ok, msg = beliBibit(selectedBibit, jumlahBeli)
                    notif(ok and "Beli ✅" or "❌", msg, 2)
                    task.wait(10)
                end
            end)
            notif("Auto Beli ON ✅", selectedBibit, 3)
        else
            if BeliLoop then pcall(function() task.cancel(BeliLoop) end); BeliLoop=nil end
            notif("Auto Beli OFF","",2)
        end
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
TabBibit:CreateParagraph({Title="✅ Confirmed",
    Content="RequestShop:InvokeServer('BUY', nama, qty)\n"
        .."Return: {Success, Message, NewCoins}\n\n"
        .."'Membeli 1x Bibit Padi! -5 Coins'"})

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
TabBibit:CreateButton({Name="📋 GET_LIST — lihat semua bibit",
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
-- TAB JUAL — v11 CONFIRMED SELL
-- ══════════════════════════════════════════
TabJual:CreateSection("💰 Jual v11 — CONFIRMED")
TabJual:CreateParagraph({Title="✅ Sell Commands",
    Content="✅ RequestSell('SELL_ALL')\n"
        .."   → {Success, TotalEarned, NewCoins}\n\n"
        .."✅ RequestSell('SELL', nama, qty)\n"
        .."   → {Success, Earned, NewCoins}\n\n"
        .."Auto-fallback: GET_LIST → SELL per item"})

TabJual:CreateButton({Name="💰 JUAL SEMUA (SELL_ALL)",
    Callback=function()
        task.spawn(function()
            local ok, msg = jualSemua()
            notif(ok and "Jual ✅" or "❌", msg, 4)
        end)
    end})

TabJual:CreateToggle({Name="🔄 Auto Sell Loop", CurrentValue=false,
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
            notif("Auto Sell ON ✅","SELL_ALL setiap 30s",3)
        else
            if SellLoop then pcall(function() task.cancel(SellLoop) end); SellLoop=nil end
            notif("Auto Sell OFF","",2)
        end
    end})

TabJual:CreateSection("🔍 Jual Per Item")
local sellItemName = "Padi"
local sellItemQty  = 1
TabJual:CreateInput({Name="Nama Item", PlaceholderText="Padi / Jagung / Tomat",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellItemName=v end})
TabJual:CreateSlider({Name="Jumlah", Range={1,99}, Increment=1, CurrentValue=1,
    Callback=function(v) sellItemQty=v end})
TabJual:CreateButton({Name="🛒 JUAL ITEM",
    Callback=function()
        task.spawn(function()
            local ok, msg = jualItem(sellItemName, sellItemQty)
            notif(ok and "Jual ✅" or "❌", msg, 4)
        end)
    end})

TabJual:CreateSection("📊 Preview Data")
TabJual:CreateButton({Name="📋 GET_LIST — hasil panen",
    Callback=function()
        task.spawn(function()
            local ok, res = invokeRF("RequestSell","GET_LIST")
            if not ok then notif("❌","GET_LIST gagal",3); return end
            local data = unwrap(res)
            if not data or not data.Items then notif("❌","Kosong",3); return end
            local txt = "SellMult: "..tostring(data.SellMult).."\n\n"
            for _, item in ipairs(data.Items) do
                txt=txt..(item.Owned>0 and "✅" or "⬜").." "
                    ..item.DisplayName.." x"..item.Owned.." | "..item.Price.."💰\n"
            end
            notif("Hasil Panen", txt, 8)
        end)
    end})

TabJual:CreateButton({Name="📋 GET_SEED_LIST",
    Callback=function()
        task.spawn(function()
            local ok, res = invokeRF("RequestSell","GET_SEED_LIST")
            if not ok then notif("❌","Gagal",3); return end
            local data = unwrap(res)
            if data and data.Seeds then
                local txt=""
                for _, s in ipairs(data.Seeds) do
                    txt=txt.."🌱 "..s.DisplayName.." x"..s.Owned.." | "..s.Price.."💰\n"
                end
                notif("Bibit Jual", txt=="" and "Kosong" or txt, 6)
            end
        end)
    end})

TabJual:CreateButton({Name="🥚 GET_EGG_LIST",
    Callback=function()
        task.spawn(function()
            local ok, res = invokeRF("RequestSell","GET_EGG_LIST")
            if not ok then notif("❌","Gagal",3); return end
            local data = unwrap(res)
            notif("Telur","Count: "..tostring(data and data.EggCount or 0)
                .."\nCoins: "..tostring(data and data.Coins or 0),4)
        end)
    end})

TabJual:CreateButton({Name="🌴 GET_FRUIT_LIST — Sawit",
    Callback=function()
        task.spawn(function()
            local ok, res = invokeRF("RequestSell","GET_FRUIT_LIST","Sawit")
            local data = ok and unwrap(res) or nil
            notif("Sawit","Count: "..tostring(data and data.FruitCount or 0)
                .."\nCoins: "..tostring(data and data.Coins or 0),4)
        end)
    end})

TabJual:CreateButton({Name="🍈 GET_FRUIT_LIST — Durian",
    Callback=function()
        task.spawn(function()
            local ok, res = invokeRF("RequestSell","GET_FRUIT_LIST","Durian")
            local data = ok and unwrap(res) or nil
            notif("Durian","Count: "..tostring(data and data.FruitCount or 0)
                .."\nCoins: "..tostring(data and data.Coins or 0),4)
        end)
    end})

-- ══════════════════════════════════════════
-- TAB TANAM
-- ══════════════════════════════════════════
TabTanam:CreateSection("🌱 Tanam Manual")
TabTanam:CreateParagraph({Title="✅ Confirmed",
    Content="PlantCrop:FireServer(Vector3)\n"
        .."Server tau sendiri bibit yg dipunya!\n\n"
        .."Scan lahan dulu di tab 🌾"})

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
TabLahan:CreateSection("🌾 Scan Lahan")
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
-- TAB TELEPORT NPC — v11: path confirmed
-- ══════════════════════════════════════════
TabNPC:CreateSection("📍 Teleport ke NPC")
TabNPC:CreateParagraph({Title="✅ NPC Paths (Cobalt v11)",
    Content="NPC_Alat → NPCs.NPC_Alat.npcalat\n"
        .."NPC_PedagangSawit → NPCs.NPC_PedagangSawit\n"
        .."NPC_Bibit → NPCs.NPC_Bibit.npcbibit\n"
        .."NPCPedagangTelur → NPCs.NPCPedagangTelur\n\n"
        .."Scan dulu untuk ambil koordinat live"})

local NpcPara = TabNPC:CreateParagraph({Title="NPC", Content="Belum scan"})

TabNPC:CreateButton({Name="🔍 SCAN NPC",
    Callback=function()
        local npcs = scanNPC()
        local count = 0
        local txt = ""
        for name, pos in pairs(npcs) do
            count=count+1
            txt=txt..string.format("• %s X=%.0f Z=%.0f\n",name,pos.X,pos.Z)
        end
        NpcPara:Set({Title=count.." NPC", Content=count>0 and txt or "Tidak ada"})
        notif("Scan NPC ✅",count.." NPC ditemukan",3)
    end})

-- Tombol TP ke NPC langsung (dari NPC_PATHS confirmed)
TabNPC:CreateSection("🏪 TP Langsung ke NPC")
for _, entry in ipairs(NPC_PATHS) do
    local e = entry
    TabNPC:CreateButton({Name="🚀 TP → "..e.name,
        Callback=function()
            -- Coba dari cache dulu
            local pos = NpcPositions[e.name]
            if not pos then
                pos = resolveNpcPath(e.path)
            end
            if pos then
                tp(pos)
                notif("TP ✅", e.name..string.format("\nX=%.1f Z=%.1f",pos.X,pos.Z),3)
            else
                notif("❌","NPC tidak ditemukan, coba Scan dulu",4)
            end
        end})
end

TabNPC:CreateButton({Name="🚀 TP ke NPC Terdekat",
    Callback=function()
        local pos = getPos(); if not pos then return end
        local closest, closestDist, closestName = nil, math.huge, ""
        for name, npos in pairs(NpcPositions) do
            local d=(npos-pos).Magnitude
            if d<closestDist then closestDist=d; closest=npos; closestName=name end
        end
        if closest then
            tp(closest)
            notif("TP ✅",closestName..string.format(" | Jarak: %.0f studs",closestDist),3)
        else notif("❌","Scan NPC dulu!",3) end
    end})

TabNPC:CreateSection("📌 TP Manual")
local tpX, tpY, tpZ = 0, 5, 0
TabNPC:CreateInput({Name="X", PlaceholderText="-99",
    RemoveTextAfterFocusLost=false, Callback=function(v) tpX=tonumber(v) or 0 end})
TabNPC:CreateInput({Name="Y", PlaceholderText="39",
    RemoveTextAfterFocusLost=false, Callback=function(v) tpY=tonumber(v) or 5 end})
TabNPC:CreateInput({Name="Z", PlaceholderText="-259",
    RemoveTextAfterFocusLost=false, Callback=function(v) tpZ=tonumber(v) or 0 end})
TabNPC:CreateButton({Name="🚀 TP ke Koordinat",
    Callback=function()
        tp(Vector3.new(tpX,tpY,tpZ))
        notif("TP ✅",string.format("X=%.1f Y=%.1f Z=%.1f",tpX,tpY,tpZ),3)
    end})
TabNPC:CreateButton({Name="📍 Print Posisi Saya",
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
TabPetir:CreateParagraph({Title="✅ Confirmed",
    Content="LightningStrike.OnClientEvent(\n"
        .."  {Reason='EXPOSED',Hit=true,Position}\n"
        ..")\n\nScript intercept → TP ke Safe Pos!\n\n"
        .."⚠️ Set Safe Pos di dalam bangunan"})

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

TabSet:CreateSection("✅ Lain")
TabSet:CreateToggle({Name="✅ Auto Confirm", CurrentValue=false,
    Callback=function(v) _G.AutoConfirm=v; notif("Auto Confirm",v and "ON" or "OFF",2) end})
TabSet:CreateToggle({Name="🎉 Notif Level Up", CurrentValue=true,
    Callback=function(v) _G.NotifLevelUp=v end})
TabSet:CreateButton({Name="🛑 STOP SEMUA", Callback=function() stopSemua() end})
TabSet:CreateButton({Name="🔄 Reset Total Earned",
    Callback=function() totalEarned=0; notif("Reset ✅","Total Earned di-reset",2) end})

-- ══════════════════════════════════════════
-- TAB TEST REMOTE — v11
-- ══════════════════════════════════════════
TabTest:CreateSection("📋 Remote Confirmed v11")
TabTest:CreateParagraph({Title="Cobalt Outgoing Confirmed",
    Content="✅ RequestShop('BUY',nama,qty)\n"
        .."✅ RequestShop('GET_LIST')\n"
        .."✅ RequestSell('GET_LIST')\n"
        .."✅ RequestSell('GET_SEED_LIST')\n"
        .."✅ RequestSell('GET_EGG_LIST')\n"
        .."✅ RequestSell('GET_FRUIT_LIST','X')\n"
        .."✅ RequestSell('SELL_ALL')  ← NEW v11\n"
        .."✅ RequestSell('SELL',nama,qty) ← NEW v11\n"
        .."✅ RequestToolShop('GET_LIST')\n"
        .."✅ PlantCrop:FireServer(Vector3)"})

TabTest:CreateSection("🔍 Test SELL Command")
local sellCmd, sellArg = "SELL_ALL", ""
TabTest:CreateInput({Name="Command", PlaceholderText="SELL_ALL / SELL / SELL_CROPS",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellCmd=v end})
TabTest:CreateInput({Name="Arg (opsional)", PlaceholderText="Padi / 1 / kosong",
    RemoveTextAfterFocusLost=false, Callback=function(v) sellArg=v end})

TabTest:CreateButton({Name="🔥 Test RequestSell(cmd)",
    Callback=function()
        task.spawn(function()
            local ok, res
            if sellArg~="" then
                ok,res = invokeRF("RequestSell", sellCmd, sellArg)
            else
                ok,res = invokeRF("RequestSell", sellCmd)
            end
            notif("RequestSell("..sellCmd..")",
                ok and "✅ lihat console" or "❌ "..tostring(res), 5)
            if ok and type(res)=="table" then
                local d=unwrap(res) or res
                for k,v in pairs(d) do
                    if type(v)~="table" then
                        print(string.format("[XKID SELL] %s = %s",tostring(k),tostring(v)))
                    end
                end
            end
        end)
    end})

TabTest:CreateSection("⚡ Quick Test")
local QT = {
    {"SummonRain","EV","🌧 SummonRain"},
    {"SkipTutorial","EV","📖 SkipTutorial"},
    {"RefreshShop","EV","🔄 RefreshShop"},
}
for _, q in ipairs(QT) do
    local qq=q
    TabTest:CreateButton({Name=qq[3],
        Callback=function()
            task.spawn(function()
                if qq[2]=="EV" then
                    local ok,err=fireEv(qq[1])
                    notif(qq[1],ok and "Fired ✅" or "❌ "..tostring(err),3)
                else
                    local ok,res=invokeRF(qq[1])
                    notif(qq[1],ok and "✅" or "❌ "..tostring(res),3)
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
    scanLahan(); scanNPC()
    local nc=0; for _ in pairs(NpcPositions) do nc=nc+1 end
    notif("Auto Scan ✅", #LahanCache.." lahan | "..nc.." NPC", 4)
end)

notif("🌾 SAWAH INDO v11.0","Welcome "..LocalPlayer.Name.."! 🔥",5)
task.wait(1.2)
notif("✅ v11 Update",
    "✅ SELL_ALL confirmed!\n"
    .."✅ NPC paths fixed!\n"
    .."✅ Auto Sell added!\n"
    .."✅ Total Earned tracker",8)

print(string.rep("═",50))
print("  🌾 SAWAH INDO v11.0 — XKID HUB")
print("  SELL_ALL + NPC Path Fix + Auto Sell")
print("  Player: "..LocalPlayer.Name)
print(string.rep("═",50))
