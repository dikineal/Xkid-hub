-- ╔══════════════════════════════════════════════════╗
-- ║   🌾 SAWAH INDO v10.0 ULTIMATE — XKID HUB       ║
-- ║   Full Remote Spy Edition                        ║
-- ║   PlantCrop(Vector3) + RequestSell() + Rain      ║
-- ║   Support: Android + Delta / Arceus / Fluxus     ║
-- ╚══════════════════════════════════════════════════╝

-- ┌─────────────────────────────────────────────────┐
-- │  REMOTE MAP (dikonfirmasi dari spy)              │
-- │                                                  │
-- │  PlantCrop         FireServer(Vector3)           │
-- │  RequestSell       InvokeServer()  → jual semua  │
-- │  RequestShop       InvokeServer()  → shop bibit  │
-- │  RequestToolShop   InvokeServer()  → shop alat   │
-- │  GetBibit          FireServer(0,false) → GUI     │
-- │  SummonRain        FireServer()                  │
-- │  LahanUpdate       FireServer("CONFIRM_BUY",{})  │
-- │  SyncData          InvokeServer()  → data player │
-- │  ConfirmAction     OnClientInvoke → return bool  │
-- │  LightningStrike   OnClientEvent  → {Pos,Hit,..} │
-- └─────────────────────────────────────────────────┘

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name             = "🌾 SAWAH INDO v10.0 💸",
    LoadingTitle     = "XKID HUB",
    LoadingSubtitle  = "Full Spy Edition — No NPC Needed! 🔥",
    ConfigurationSaving = { Enabled = false },
    KeySystem        = false,
})

-- ══════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════
-- FLAGS
-- ══════════════════════════════════════════
_G.ScriptRunning  = true
_G.AutoFarm       = false
_G.AutoBeli       = false
_G.AutoJual       = false
_G.AutoTanam      = false
_G.AutoPanen      = false
_G.PenangkalPetir = false
_G.AutoRain       = false
_G.AutoConfirm    = false
_G.NotifLevelUp   = true
_G.ESP            = false

-- ══════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════
local PlayerData = {
    Coins   = 0, Level  = 1,
    XP      = 0, Needed = 50,
    Seeds   = {}, -- {Name, Owned, Price, Icon, Locked}
    Tools   = {}, -- {Name, Price, Owned, EffectText}
    LastSync = 0,
}

local SiklusCount  = 0
local lightningHits = 0
local levelUpCount  = 0
local BeliLoop      = nil
local ESPObjects    = {}
local SafePos       = nil

-- Lahan cache: simpan Vector3 posisi setiap plot lahan
local LahanCache    = {}       -- list of Vector3
local LahanCacheTime = 0

-- Jenis tanaman aktif (untuk label saja, server yg handle bibit)
local BIBIT_LIST = {
    { name = "Bibit Padi",       icon = "🌾", price = 5,    minLv = 1   },
    { name = "Bibit Jagung",     icon = "🌽", price = 15,   minLv = 20  },
    { name = "Bibit Tomat",      icon = "🍅", price = 25,   minLv = 40  },
    { name = "Bibit Terong",     icon = "🍆", price = 40,   minLv = 60  },
    { name = "Bibit Strawberry", icon = "🍓", price = 60,   minLv = 80  },
    { name = "Bibit Sawit",      icon = "🌴", price = 1000, minLv = 80  },
    { name = "Bibit Durian",     icon = "🍈", price = 2000, minLv = 120 },
}

local selectedBibit  = "Bibit Padi"
local jumlahBeli     = 1
local dTanam         = 0.5   -- delay antar PlantCrop
local waitPanen      = 60    -- tunggu tumbuh (detik)
local rainInterval   = 150   -- auto rain interval

-- Lahan config (dari scan map)
local LAHAN_CONFIG = {
    prefix  = "AreaTanamBesar",
    total   = 32,
    price   = 100000,
    promptDist = 12,
}

-- ══════════════════════════════════════════
-- UTILITY
-- ══════════════════════════════════════════

local function notif(judul, isi, dur)
    pcall(function()
        Rayfield:Notify({ Title=judul, Content=isi, Duration=dur or 3, Image=4483362458 })
    end)
    print("[XKID] "..judul.." — "..isi)
end

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPos()
    local r = getRoot(); return r and r.Position
end

local function tp(target)
    local root = getRoot(); if not root then return false end
    local pos
    if typeof(target) == "Vector3" then
        pos = target
    elseif typeof(target) == "CFrame" then
        root.CFrame = target + Vector3.new(0,5,0); task.wait(0.3); return true
    elseif typeof(target) == "Instance" then
        if target:IsA("BasePart") then pos = target.Position
        elseif target:IsA("Model") then
            pos = target.PrimaryPart and target.PrimaryPart.Position
               or (target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Position)
        end
    end
    if not pos then return false end
    root.CFrame = CFrame.new(pos.X, pos.Y + 5, pos.Z)
    task.wait(0.3); return true
end

-- ══════════════════════════════════════════
-- REMOTE SYSTEM
-- ══════════════════════════════════════════

-- Path: RS.Remotes.TutorialRemotes.<name>  (dari spy)
local remoteFolder = nil
local remoteCache  = {}

local function getRemoteFolder()
    if remoteFolder then return remoteFolder end
    local rem = RS:FindFirstChild("Remotes")
    if rem then
        local tr = rem:FindFirstChild("TutorialRemotes")
        if tr then remoteFolder = tr; return tr end
    end
    return nil
end

local function getRemote(name)
    if remoteCache[name] then return remoteCache[name] end
    local folder = getRemoteFolder()
    if not folder then return nil end
    local r = folder:FindFirstChild(name)
    if r then remoteCache[name] = r end
    return r
end

-- Fire RemoteEvent ke server
local function fireEv(name, ...)
    local r = getRemote(name)
    if not r or not r:IsA("RemoteEvent") then
        return false, "RemoteEvent '"..name.."' tidak ditemukan"
    end
    local ok, err = pcall(function(...) r:FireServer(...) end, ...)
    return ok, err
end

-- Invoke RemoteFunction ke server
local function invokeRF(name, ...)
    local r = getRemote(name)
    if not r or not r:IsA("RemoteFunction") then
        return false, nil, "RemoteFunction '"..name.."' tidak ditemukan"
    end
    local ok, result = pcall(function(...) return r:InvokeServer(...) end, ...)
    return ok, result, ok and nil or result
end

-- ══════════════════════════════════════════
-- SCAN LAHAN (cari semua Vector3 plot)
-- ══════════════════════════════════════════

local function scanLahan()
    local now = tick()
    if now - LahanCacheTime < 10 and #LahanCache > 0 then
        return LahanCache
    end

    LahanCache = {}
    local prefix = LAHAN_CONFIG.prefix:lower()

    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            -- AreaTanamBesar*, AreaTanam Besar*, areatanampadi, dsb
            if n:find("areatanambesar") or n:find("areatanampadi")
               or n:find("areatanamsawah") or n:find("areatanamsawit")
               or n:find("areatanamlahan") then
                table.insert(LahanCache, v.Position)
            end
        end
    end

    LahanCacheTime = now
    return LahanCache
end

-- ══════════════════════════════════════════
-- ┌─────────────────────────────────────────┐
-- │  BELI BIBIT                              │
-- │  GetBibit:FireServer(0, false)           │
-- │  → server buka GUI bibit                 │
-- │  → klik tombol beli di GUI               │
-- └─────────────────────────────────────────┘
-- ══════════════════════════════════════════

local function klikUI(btn)
    if not btn then return false end
    pcall(function() if btn:IsA("GuiButton") then btn.MouseButton1Click:Fire() end end)
    task.wait(0.05)
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        local p = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, true,  game, 0); task.wait(0.05)
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
    end)
    task.wait(0.1); return true
end

local function tutupGUI()
    local pg = LocalPlayer:FindFirstChild("PlayerGui"); if not pg then return end
    local fg = pg:FindFirstChild("FarmGui") or pg
    for _, v in pairs(fg:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local t = v.Text:lower()
            if t == "x" or t == "✕" or t:find("tutup") or t:find("close") then
                klikUI(v); task.wait(0.1)
            end
        end
    end
end

local function beliBibit(namabibit, jumlah)
    namabibit = namabibit or selectedBibit
    jumlah    = jumlah    or jumlahBeli

    -- Fire GetBibit(0, false) → server buka GUI bibit
    local ok = fireEv("GetBibit", 0, false)
    if not ok then return false, "GetBibit gagal" end

    task.wait(1.5) -- tunggu GUI terbuka

    local pg = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not pg then return false, "PlayerGui tidak ada" end
    local fg = pg:FindFirstChild("FarmGui") or pg

    -- Atur jumlah (tombol +)
    if jumlah > 1 then
        for _, v in pairs(fg:GetDescendants()) do
            if v:IsA("TextButton") and v.Text == "+" and v.Visible then
                for i = 1, jumlah - 1 do klikUI(v); task.wait(0.05) end
                break
            end
        end
        task.wait(0.2)
    end

    -- Klik beli
    local berhasil = false
    for _, v in pairs(fg:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local t = v.Text:lower()
            if t:find("beli") or t:find("buy") then
                klikUI(v); berhasil = true; break
            end
        end
    end

    task.wait(0.4); tutupGUI()
    return berhasil
end

-- ══════════════════════════════════════════
-- ┌─────────────────────────────────────────┐
-- │  TANAM                                   │
-- │  PlantCrop:FireServer(Vector3)           │
-- │  Server tau sendiri bibit apa yg dipunya │
-- └─────────────────────────────────────────┘
-- ══════════════════════════════════════════

local function tanamSatu(pos)
    -- pos = Vector3 posisi lahan
    if typeof(pos) ~= "Vector3" then return false end
    local ok, err = fireEv("PlantCrop", pos)
    return ok, err
end

local function tanamSemua()
    local lahans = scanLahan()
    if #lahans == 0 then
        return 0, "Tidak ada lahan ditemukan"
    end
    local count = 0
    for _, pos in ipairs(lahans) do
        if not _G.AutoTanam and not _G.AutoFarm then break end
        local ok = fireEv("PlantCrop", pos)
        if ok then count = count + 1 end
        task.wait(dTanam)
    end
    return count
end

-- ══════════════════════════════════════════
-- ┌─────────────────────────────────────────┐
-- │  JUAL                                    │
-- │  RequestSell:InvokeServer()              │
-- │  TANPA ARGS — server jual semua otomatis │
-- │  Return: {Success, Message, NewCoins}    │
-- └─────────────────────────────────────────┘
-- ══════════════════════════════════════════

local function jualSemua()
    local ok, result = invokeRF("RequestSell")
    if not ok then return false, "RequestSell gagal", 0 end

    -- result bisa array atau table langsung
    local data = (type(result) == "table" and result[1]) and result[1] or result
    if type(data) ~= "table" then return false, "Respons tidak valid", 0 end

    if data.Success then
        local msg  = data.Message  or ("+"..tostring(data.Coins or 0).." Coins")
        local coin = data.NewCoins or data.Coins or 0
        PlayerData.Coins = coin
        return true, msg, coin
    else
        return false, "Server: gagal jual", 0
    end
end

-- ══════════════════════════════════════════
-- ┌─────────────────────────────────────────┐
-- │  SHOP / BELI BIBIT via RequestShop       │
-- │  RequestShop:InvokeServer()              │
-- │  Return: {Seeds=[...], Coins}            │
-- │  Untuk beli: kemungkinan perlu arg nama  │
-- └─────────────────────────────────────────┘
-- ══════════════════════════════════════════

local function getShopData()
    local ok, result = invokeRF("RequestShop")
    if not ok then return nil end
    local data = (type(result)=="table" and result[1]) and result[1] or result
    if type(data)=="table" and data.Seeds then
        PlayerData.Seeds = data.Seeds
        PlayerData.Coins = data.Coins or PlayerData.Coins
    end
    return data
end

-- Beli bibit via RequestShop (coba dengan nama bibit)
local function beliViaRequestShop(namabibit, jumlah)
    namabibit = namabibit or selectedBibit
    jumlah    = jumlah    or jumlahBeli
    local ok, result = invokeRF("RequestShop", namabibit, jumlah)
    if not ok then return false, "RequestShop gagal" end
    local data = (type(result)=="table" and result[1]) and result[1] or result
    if type(data)=="table" and data.Success then
        PlayerData.Coins = data.NewCoins or PlayerData.Coins
        return true, data.Message or "Berhasil"
    end
    return false, type(data)=="table" and (data.Message or "Gagal") or "Gagal"
end

-- ══════════════════════════════════════════
-- ┌─────────────────────────────────────────┐
-- │  SYNC DATA                               │
-- │  SyncData:InvokeServer()                 │
-- └─────────────────────────────────────────┘
-- ══════════════════════════════════════════

local function syncData()
    local ok, result = invokeRF("SyncData")
    if not ok then return false end
    local data = (type(result)=="table" and result[1]) and result[1] or result
    if type(data) ~= "table" then return false end
    PlayerData.Coins        = data.Coins   or PlayerData.Coins
    PlayerData.Level        = data.Level   or PlayerData.Level
    PlayerData.XP           = data.XP      or PlayerData.XP
    PlayerData.Needed       = data.Needed  or PlayerData.Needed
    PlayerData.LastSync     = tick()
    return true
end

-- ══════════════════════════════════════════
-- SUMMON RAIN (1.5x growth)
-- ══════════════════════════════════════════

local function summonRain()
    return fireEv("SummonRain")
end

-- ══════════════════════════════════════════
-- STOP ALL
-- ══════════════════════════════════════════

local function stopSemua()
    _G.AutoFarm  = false; _G.AutoBeli  = false
    _G.AutoJual  = false; _G.AutoTanam = false
    _G.AutoPanen = false; _G.AutoRain  = false
    if BeliLoop then
        pcall(function() task.cancel(BeliLoop) end)
        BeliLoop = nil
    end
    notif("⛔ STOP SEMUA", "Semua auto dimatikan", 3)
end

-- ESP
local function clearESP()
    for _, e in pairs(ESPObjects) do pcall(function() e:Destroy() end) end
    ESPObjects = {}
end

local function updateESP()
    clearESP()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("BasePart") then
            local n = v.Name:lower()
            local color
            if n:find("areatanambesar") or n:find("areatanampadi") or n:find("areatanamsawah") then
                color = Color3.fromRGB(0, 170, 255)
            elseif n:find("areatanamsawit") then
                color = Color3.fromRGB(0, 255, 128)
            elseif n:find("npc") or n:find("toko") or n:find("pedagang") then
                color = Color3.fromRGB(255, 255, 0)
            elseif n:find("sawit") or n:find("padi") or n:find("jagung")
                or n:find("tomat") or n:find("durian") or n:find("crop") then
                color = Color3.fromRGB(0, 255, 0)
            elseif n:find("ternak") or n:find("kandang") then
                color = Color3.fromRGB(255, 128, 0)
            end
            if color then
                local hl = Instance.new("Highlight")
                hl.Name = "XKIDESP"; hl.FillColor = color
                hl.OutlineColor = Color3.fromRGB(255,255,255)
                hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = v; table.insert(ESPObjects, hl)
            end
        end
    end
end

-- ══════════════════════════════════════════
-- INTERCEPT CLIENT EVENTS
-- ══════════════════════════════════════════

local function setupIntercepts()
    -- 1. LightningStrike → penangkal petir
    task.spawn(function()
        local r; for i=1,10 do r=getRemote("LightningStrike"); if r then break end; task.wait(1) end
        if not r then print("[XKID] LightningStrike tidak ditemukan"); return end
        r.OnClientEvent:Connect(function(data)
            print("[XKID⚡] LightningStrike! Reason="..tostring(data and data.Reason))
            if not _G.PenangkalPetir then return end
            lightningHits = lightningHits + 1
            local root = getRoot()
            if root then
                if SafePos then
                    root.CFrame = CFrame.new(SafePos.X, SafePos.Y + 5, SafePos.Z)
                    notif("⚡ PETIR DITANGKAL ✅", "Safe! #"..lightningHits, 3)
                else
                    root.CFrame = root.CFrame + Vector3.new(0, 60, 0)
                    notif("⚡ PETIR!", "Set Safe Pos dulu!", 3)
                end
            end
        end)
        print("[XKID] ✅ LightningStrike intercept aktif")
    end)

    -- 2. UpdateLevel → track level up
    task.spawn(function()
        local r; for i=1,10 do r=getRemote("UpdateLevel"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(data)
            if type(data) ~= "table" then return end
            PlayerData.Level  = data.Level  or PlayerData.Level
            PlayerData.XP     = data.XP     or PlayerData.XP
            PlayerData.Needed = data.Needed or PlayerData.Needed
            print("[XKID📈] Level "..tostring(data.Level).." | XP "..tostring(data.XP))
            if data.LeveledUp and _G.NotifLevelUp then
                levelUpCount = levelUpCount + 1
                notif("🎉 LEVEL UP! #"..levelUpCount,
                    "Level "..tostring(data.Level).." 🔥 XP: "..tostring(data.XP).."/"..tostring(data.Needed), 6)
            end
        end)
        print("[XKID] ✅ UpdateLevel intercept aktif")
    end)

    -- 3. Notification → log
    task.spawn(function()
        local r; for i=1,10 do r=getRemote("Notification"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(msg)
            print("[XKID🔔] "..tostring(msg))
        end)
    end)

    -- 4. ConfirmAction → auto confirm
    task.spawn(function()
        local r; for i=1,10 do r=getRemote("ConfirmAction"); if r then break end; task.wait(1) end
        if not r or not r:IsA("RemoteFunction") then return end
        r.OnClientInvoke = function(data)
            if _G.AutoConfirm then
                notif("✅ Auto Confirm", tostring(data), 2)
                return true
            end
            return nil
        end
        print("[XKID] ✅ ConfirmAction intercept aktif")
    end)

    -- 5. GetBibit → log bibit gratis
    task.spawn(function()
        local r; for i=1,10 do r=getRemote("GetBibit"); if r then break end; task.wait(1) end
        if not r then return end
        r.OnClientEvent:Connect(function(qty, isFree)
            if isFree and qty and qty > 0 then
                notif("🎁 Bibit Gratis!", qty.."x bibit gratis diterima!", 5)
            end
        end)
    end)

    print("[XKID] === SEMUA INTERCEPT SIAP ===")
end

-- ══════════════════════════════════════════
-- TABS
-- ══════════════════════════════════════════
local TabStatus  = Window:CreateTab("📊 Status",      nil)
local TabPlayer  = Window:CreateTab("👤 Player",      nil)
local TabFarm    = Window:CreateTab("🤖 Auto Farm",   nil)
local TabBibit   = Window:CreateTab("🛒 Beli Bibit",  nil)
local TabJual    = Window:CreateTab("💰 Jual",        nil)
local TabTanam   = Window:CreateTab("🌱 Tanam",       nil)
local TabLahan   = Window:CreateTab("🌾 Lahan",       nil)
local TabHujan   = Window:CreateTab("🌧 Hujan",       nil)
local TabPetir   = Window:CreateTab("⚡ Petir",       nil)
local TabESP     = Window:CreateTab("👁 ESP",         nil)
local TabSet     = Window:CreateTab("⚙ Setting",     nil)
local TabTest    = Window:CreateTab("🧪 Test Remote", nil)

-- ══════════════════════════════════════════
-- TAB STATUS
-- ══════════════════════════════════════════
TabStatus:CreateSection("📊 Live Status")

local StFarm   = TabStatus:CreateParagraph({Title="🤖 Auto Farm",  Content="🔴 OFF"})
local StBeli   = TabStatus:CreateParagraph({Title="🛒 Auto Beli",  Content="🔴 OFF"})
local StJual   = TabStatus:CreateParagraph({Title="💰 Auto Jual",  Content="🔴 OFF"})
local StPlayer = TabStatus:CreateParagraph({Title="👤 Player",     Content="..."})
local StLahan  = TabStatus:CreateParagraph({Title="🌾 Lahan",      Content="Belum scan"})
local StPetir  = TabStatus:CreateParagraph({Title="⚡ Petir",      Content="🔴 OFF"})
local StSiklus = TabStatus:CreateParagraph({Title="🔄 Siklus",     Content="0"})

task.spawn(function()
    while _G.ScriptRunning do
        pcall(function()
            StFarm:Set({Title="🤖 Auto Farm",
                Content=_G.AutoFarm and ("🟢 RUNNING — Siklus "..SiklusCount) or "🔴 OFF"})
            StBeli:Set({Title="🛒 Auto Beli",
                Content=_G.AutoBeli and ("🟢 "..selectedBibit.." x"..jumlahBeli) or "🔴 OFF"})
            StJual:Set({Title="💰 Auto Jual",
                Content=_G.AutoJual and "🟢 RUNNING" or "🔴 OFF"})
            StPlayer:Set({Title="👤 "..LocalPlayer.Name,
                Content="💰 "..PlayerData.Coins
                    .."  |  ⭐ Lv."..PlayerData.Level
                    .."  |  📊 XP "..PlayerData.XP.."/"..PlayerData.Needed
                    .."\n🎉 Level up: "..levelUpCount.."x"
                    ..(PlayerData.LastSync>0 and "\n🔄 Sync: "..string.format("%.0fs ago",tick()-PlayerData.LastSync) or "")})
            StLahan:Set({Title="🌾 Lahan Cache",
                Content=#LahanCache.." plot tersimpan"
                    ..(LahanCacheTime>0 and (" | "..string.format("%.0fs ago",tick()-LahanCacheTime)) or "")})
            StPetir:Set({Title="⚡ Penangkal Petir",
                Content=(_G.PenangkalPetir and "🟢 AKTIF" or "🔴 OFF")
                    .." | "..lightningHits.."x ditangkal"
                    ..(SafePos and " | ✅ Safe pos" or " | ❌ Belum set")})
            StSiklus:Set({Title="🔄 Siklus Farm", Content=SiklusCount.." siklus"})
        end)
        task.wait(1)
    end
end)

-- ══════════════════════════════════════════
-- TAB PLAYER
-- ══════════════════════════════════════════
TabPlayer:CreateSection("👤 Data Player")

TabPlayer:CreateParagraph({Title="Info",
    Content="Data dari SyncData:InvokeServer()\nInventory + level + coins"})

local PDataPara = TabPlayer:CreateParagraph({Title="Player Data", Content="Tekan Sync"})
local SeedsPara = TabPlayer:CreateParagraph({Title="Bibit (dari RequestShop)", Content="Tekan Sync Shop"})
local ToolsPara = TabPlayer:CreateParagraph({Title="Tools (dari RequestToolShop)", Content="Tekan Sync Tools"})

TabPlayer:CreateButton({Name="🔄 Sync Data Player",
    Callback=function()
        task.spawn(function()
            local ok = syncData()
            if ok then
                PDataPara:Set({Title="Player Data",
                    Content="💰 Coins: "..PlayerData.Coins
                        .."\n⭐ Level: "..PlayerData.Level
                        .."\n📊 XP: "..PlayerData.XP.."/"..PlayerData.Needed})
                notif("Sync ✅", "Lv."..PlayerData.Level.." | "..PlayerData.Coins.." coins", 3)
            else
                notif("Sync ❌", "SyncData tidak merespons", 3)
            end
        end)
    end})

TabPlayer:CreateButton({Name="🛒 Sync Shop (Bibit + Coins)",
    Callback=function()
        task.spawn(function()
            local data = getShopData()
            if data and data.Seeds then
                local txt = "Coins: "..tostring(data.Coins).."\n\n"
                for _, s in ipairs(data.Seeds) do
                    txt = txt..(s.Locked and "🔒" or "✅").." "
                        ..s.Icon.." "..s.DisplayName
                        .." | Punya: "..s.Owned
                        .." | "..s.Price.."💰\n"
                end
                SeedsPara:Set({Title="Bibit di Shop", Content=txt})
                notif("Shop Sync ✅", #data.Seeds.." bibit tersedia", 3)
            else
                notif("Shop ❌", "RequestShop gagal", 3)
            end
        end)
    end})

TabPlayer:CreateButton({Name="🔧 Sync Tools (RequestToolShop)",
    Callback=function()
        task.spawn(function()
            local ok, result = invokeRF("RequestToolShop")
            if ok then
                local data = (type(result)=="table" and result[1]) and result[1] or result
                if data and data.Tools then
                    PlayerData.Tools = data.Tools
                    local txt = "Level: "..tostring(data.PlayerLevel)
                              .."\nCoins: "..tostring(data.Coins).."\n\n"
                    for _, t in ipairs(data.Tools) do
                        txt = txt..(t.Owned and "✅" or "❌").." "
                            ..t.Icon.." "..t.DisplayName
                            .." | "..t.Price.."💰"
                            ..(t.EffectText~="" and (" ["..t.EffectText.."]") or "").."\n"
                    end
                    ToolsPara:Set({Title="Tools", Content=txt})
                    notif("Tools ✅", #data.Tools.." tools", 3)
                end
            else
                notif("Tools ❌", "RequestToolShop gagal", 3)
            end
        end)
    end})

TabPlayer:CreateSection("✨ Intercepts")

TabPlayer:CreateToggle({Name="✅ Auto Confirm (beli lahan dll)", CurrentValue=false,
    Callback=function(v) _G.AutoConfirm=v; notif("Auto Confirm", v and "ON ✅" or "OFF", 2) end})

TabPlayer:CreateToggle({Name="🎉 Notif Level Up", CurrentValue=true,
    Callback=function(v) _G.NotifLevelUp=v end})

-- ══════════════════════════════════════════
-- TAB AUTO FARM
-- ══════════════════════════════════════════
TabFarm:CreateSection("🤖 Full Auto Farm")

TabFarm:CreateParagraph({Title="Flow Auto Farm",
    Content="1️⃣ Beli bibit  → GetBibit(0,false)\n"
        .."2️⃣ Tanam       → PlantCrop(Vector3) per plot\n"
        .."3️⃣ Tunggu tumbuh (X detik)\n"
        .."4️⃣ Jual semua  → RequestSell()\n"
        .."↩️ Ulangi dari awal\n\n"
        .."⚠️ Scan Lahan dulu di tab 🌾 Lahan!"})

TabFarm:CreateSection("⏱ Delay")
TabFarm:CreateSlider({Name="Delay antar PlantCrop (s)", Range={0.1,3}, Increment=0.1, CurrentValue=0.5,
    Callback=function(v) dTanam=v end})
TabFarm:CreateSlider({Name="Tunggu Panen (s)", Range={10,300}, Increment=5, CurrentValue=60,
    Callback=function(v) waitPanen=v end})

TabFarm:CreateSection("🔥 START")

TabFarm:CreateToggle({Name="🔥 FULL AUTO FARM", CurrentValue=false,
    Callback=function(v)
        _G.AutoFarm = v
        if v then
            if #LahanCache == 0 then
                scanLahan()
                if #LahanCache == 0 then
                    notif("⚠️ Lahan 0!", "Tab 🌾 Lahan → Scan Lahan dulu!", 6)
                    _G.AutoFarm = false; return
                end
            end
            SiklusCount = 0
            notif("AUTO FARM ON 🔥", #LahanCache.." lahan | Tunggu "..waitPanen.."s", 4)
            task.spawn(function()
                while _G.AutoFarm do
                    SiklusCount = SiklusCount + 1
                    notif("Siklus #"..SiklusCount, "Step 1: Beli bibit...", 2)

                    -- Step 1: Beli
                    pcall(beliBibit, selectedBibit, jumlahBeli)
                    if not _G.AutoFarm then break end; task.wait(1)

                    -- Step 2: Tanam semua lahan
                    notif("Siklus #"..SiklusCount, "Step 2: Tanam "..#LahanCache.." lahan...", 2)
                    local planted = 0
                    for _, pos in ipairs(LahanCache) do
                        if not _G.AutoFarm then break end
                        local ok = fireEv("PlantCrop", pos)
                        if ok then planted = planted + 1 end
                        task.wait(dTanam)
                    end
                    notif("Siklus #"..SiklusCount, "Tanam: "..planted.." plot ✅", 2)
                    if not _G.AutoFarm then break end

                    -- Step 3: Tunggu panen
                    notif("Siklus #"..SiklusCount, "Step 3: Tunggu "..waitPanen.."s...", 3)
                    local w = 0
                    while w < waitPanen and _G.AutoFarm do task.wait(1); w=w+1 end
                    if not _G.AutoFarm then break end

                    -- Step 4: Jual
                    notif("Siklus #"..SiklusCount, "Step 4: Jual semua...", 2)
                    local ok, msg, coins = jualSemua()
                    if ok then
                        notif("Jual ✅ #"..SiklusCount, msg.."\n💰 "..coins, 3)
                    else
                        notif("Jual ❌", msg, 3)
                    end
                    if not _G.AutoFarm then break end
                    task.wait(2)
                end
                notif("AUTO FARM STOP", "Total: "..SiklusCount.." siklus", 3)
            end)
        else
            notif("AUTO FARM OFF", "", 2)
        end
    end})

TabFarm:CreateSection("🎯 Auto Satuan")

TabFarm:CreateToggle({Name="🛒 Auto Beli Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoBeli = v
        if v then
            BeliLoop = task.spawn(function()
                while _G.AutoBeli do
                    local ok = beliBibit(selectedBibit, jumlahBeli)
                    if ok then notif("Auto Beli ✅", selectedBibit.." x"..jumlahBeli, 2) end
                    task.wait(10)
                end
            end)
            notif("Auto Beli ON ✅", selectedBibit.." x"..jumlahBeli, 3)
        else
            if BeliLoop then pcall(function() task.cancel(BeliLoop) end); BeliLoop=nil end
            notif("Auto Beli OFF", "", 2)
        end
    end})

TabFarm:CreateToggle({Name="🌱 Auto Tanam Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoTanam = v
        if v then
            task.spawn(function()
                while _G.AutoTanam do
                    if #LahanCache == 0 then scanLahan() end
                    local count = 0
                    for _, pos in ipairs(LahanCache) do
                        if not _G.AutoTanam then break end
                        local ok = fireEv("PlantCrop", pos)
                        if ok then count=count+1 end
                        task.wait(dTanam)
                    end
                    notif("Auto Tanam ✅", count.." plot ditanam", 2)
                    task.wait(5)
                end
            end)
            notif("Auto Tanam ON ✅", #LahanCache.." plot", 3)
        else notif("Auto Tanam OFF","",2) end
    end})

TabFarm:CreateToggle({Name="💰 Auto Jual Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoJual = v
        if v then
            task.spawn(function()
                while _G.AutoJual do
                    local ok, msg = jualSemua()
                    if ok then notif("Auto Jual ✅", msg, 2) end
                    task.wait(15)
                end
            end)
            notif("Auto Jual ON ✅", "", 3)
        else notif("Auto Jual OFF","",2) end
    end})

TabFarm:CreateSection("🛑 Emergency")
TabFarm:CreateButton({Name="🛑 STOP SEMUA", Callback=function() stopSemua() end})

-- ══════════════════════════════════════════
-- TAB BELI BIBIT
-- ══════════════════════════════════════════
TabBibit:CreateSection("🌱 Pilih Bibit")

TabBibit:CreateParagraph({Title="Metode Beli",
    Content="GetBibit(0,false) → server buka GUI\n"
        .."Script klik tombol beli\n\n"
        .."Alternatif: RequestShop(NamaBibit,Qty)\n"
        .."Langsung beli tanpa GUI!"})

local opsiB = {}
for _, b in ipairs(BIBIT_LIST) do
    table.insert(opsiB, b.icon.." "..b.name.." Lv."..b.minLv.." | "..b.price.."💰")
end

TabBibit:CreateDropdown({Name="Pilih Bibit", Options=opsiB, CurrentOption={opsiB[1]},
    Callback=function(v)
        for _, b in ipairs(BIBIT_LIST) do
            if v[1]:find(b.name:gsub("Bibit ",""), 1, true) then
                selectedBibit = b.name
                notif("Dipilih", b.icon.." "..b.name, 2); break
            end
        end
    end})

TabBibit:CreateSlider({Name="Jumlah", Range={1,99}, Increment=1, CurrentValue=1,
    Callback=function(v) jumlahBeli=v end})

TabBibit:CreateSection("🛒 Beli")

TabBibit:CreateButton({Name="🛒 Beli via GetBibit (GUI)",
    Callback=function()
        task.spawn(function()
            notif("Beli...", selectedBibit.." x"..jumlahBeli, 2)
            local ok = beliBibit(selectedBibit, jumlahBeli)
            notif(ok and "Beli ✅" or "Beli ❌", ok and "Berhasil!" or "Coba lagi", 3)
        end)
    end})

TabBibit:CreateButton({Name="⚡ Beli via RequestShop (langsung)",
    Callback=function()
        task.spawn(function()
            local ok, msg = beliViaRequestShop(selectedBibit, jumlahBeli)
            notif(ok and "Beli ✅" or "Beli ❌", msg, 3)
        end)
    end})

TabBibit:CreateSection("⚡ Beli Cepat")
for _, b in ipairs(BIBIT_LIST) do
    local bb = b
    TabBibit:CreateButton({Name=bb.icon.." "..bb.name.." | "..bb.price.."💰",
        Callback=function()
            task.spawn(function()
                selectedBibit = bb.name
                local ok = beliBibit(bb.name, jumlahBeli)
                notif(ok and "✅" or "❌", bb.name.." x"..jumlahBeli, 2)
            end)
        end})
end

-- ══════════════════════════════════════════
-- TAB JUAL
-- ══════════════════════════════════════════
TabJual:CreateSection("💰 Jual Hasil Panen")

TabJual:CreateParagraph({Title="Metode Jual",
    Content="RequestSell:InvokeServer() — tanpa args!\n"
        .."Server otomatis jual semua inventori\n\n"
        .."Return: {Success, Message, NewCoins}\n"
        .."Contoh: 'Menjual 8x Padi! +80 Coins'"})

TabJual:CreateButton({Name="💰 JUAL SEMUA SEKARANG",
    Callback=function()
        task.spawn(function()
            notif("Menjual...", "Kirim ke server...", 2)
            local ok, msg, coins = jualSemua()
            notif(ok and "Jual ✅" or "Jual ❌",
                ok and (msg.."\n💰 Total: "..coins) or msg, 4)
        end)
    end})

TabJual:CreateSection("📊 Preview Jual (tanpa jual)")

TabJual:CreateButton({Name="📊 Lihat Isi Inventori",
    Callback=function()
        task.spawn(function()
            -- RequestSell tanpa jual — lihat data dulu
            local ok, result = invokeRF("RequestSell")
            if not ok then notif("❌","RequestSell gagal",3); return end
            local data = (type(result)=="table" and result[1]) and result[1] or result
            if type(data)~="table" then notif("❌","Respons tidak valid",3); return end

            if data.Items then
                local txt = "SellMult: "..tostring(data.SellMult).."\n\n"
                for _, item in ipairs(data.Items) do
                    txt = txt..(item.Owned>0 and "✅" or "⬜").." "
                        ..item.Icon.." "..item.DisplayName
                        .." x"..item.Owned
                        .." | "..item.Price.."💰 each\n"
                end
                notif("Inventori", txt, 10)
            elseif data.Message then
                notif("Jual", data.Message, 5)
            elseif data.FruitType then
                notif("Sawit/Buah", "Type: "..data.FruitType.." | Count: "..tostring(data.FruitCount), 5)
            elseif data.EggCount ~= nil then
                notif("Telur", "Count: "..tostring(data.EggCount), 5)
            end
        end)
    end})

-- ══════════════════════════════════════════
-- TAB TANAM
-- ══════════════════════════════════════════
TabTanam:CreateSection("🌱 Tanam Manual")

TabTanam:CreateParagraph({Title="PlantCrop Remote",
    Content="PlantCrop:FireServer(Vector3)\n"
        .."Server tau sendiri bibit apa yang dipunya!\n\n"
        .."Scan lahan dulu → posisi tersimpan\n"
        .."Lalu klik Tanam Semua"})

TabTanam:CreateButton({Name="🌱 TANAM SEMUA LAHAN",
    Callback=function()
        task.spawn(function()
            if #LahanCache == 0 then
                scanLahan()
                if #LahanCache == 0 then
                    notif("❌", "Scan lahan dulu! Tab 🌾 Lahan", 4); return
                end
            end
            notif("Tanam...", #LahanCache.." lahan...", 2)
            local count = 0
            for _, pos in ipairs(LahanCache) do
                local ok = fireEv("PlantCrop", pos)
                if ok then count=count+1 end
                task.wait(dTanam)
            end
            notif("Tanam ✅", count.."/"..#LahanCache.." plot berhasil", 3)
        end)
    end})

TabTanam:CreateSection("📍 Tanam di Posisi Saat Ini")

TabTanam:CreateButton({Name="📍 PlantCrop di Posisi Saya",
    Callback=function()
        local pos = getPos()
        if not pos then notif("❌","Posisi tidak valid",3); return end
        task.spawn(function()
            local ok, err = fireEv("PlantCrop", pos)
            notif(ok and "Tanam ✅" or "Tanam ❌",
                ok and string.format("X=%.1f Z=%.1f",pos.X,pos.Z) or tostring(err), 3)
        end)
    end})

-- ══════════════════════════════════════════
-- TAB LAHAN
-- ══════════════════════════════════════════
TabLahan:CreateSection("🌾 Scan & Cache Lahan")

TabLahan:CreateParagraph({Title="Info Lahan Config (dari scan map)",
    Content="Prefix: AreaTanamBesar\n"
        .."Total: 32 area\n"
        .."Harga: 100,000 💰\n"
        .."Prompt Distance: 12 studs"})

local LahanInfoPara = TabLahan:CreateParagraph({Title="Cache Status", Content="Belum scan"})

TabLahan:CreateButton({Name="🔍 SCAN LAHAN SEKARANG",
    Callback=function()
        LahanCacheTime = 0
        local lahans = scanLahan()
        LahanInfoPara:Set({Title="Cache Status",
            Content=#lahans.." plot ditemukan\n"
                ..(#lahans>0 and "✅ Siap tanam!" or "❌ Tidak ada lahan\nPastikan ada di area lahan!")})
        notif("Scan ✅", #lahans.." plot ditemukan", 3)
    end})

TabLahan:CreateButton({Name="📊 Lihat Posisi Lahan",
    Callback=function()
        if #LahanCache == 0 then notif("❌","Scan dulu!",3); return end
        local txt = #LahanCache.." plot:\n"
        for i, pos in ipairs(LahanCache) do
            if i > 10 then txt=txt.."... dan "..(#LahanCache-10).." lainnya"; break end
            txt = txt..string.format("#%d X=%.0f Z=%.0f\n", i, pos.X, pos.Z)
        end
        notif("Posisi Lahan", txt, 8)
    end})

TabLahan:CreateButton({Name="🗑 Reset Cache",
    Callback=function()
        LahanCache={}; LahanCacheTime=0
        notif("Reset ✅","Cache lahan dihapus",2)
    end})

TabLahan:CreateSection("🏞 Beli Lahan (LahanUpdate)")

local LAHAN_LIST = {
    {partName="AreaTanam Besar2", price=100000, label="Lahan Besar 2"},
    {partName="AreaTanam Besar3", price=200000, label="Lahan Besar 3"},
    {partName="AreaTanam Sawit1", price=150000, label="Lahan Sawit 1"},
    {partName="AreaTanam Sawit2", price=300000, label="Lahan Sawit 2"},
}

TabLahan:CreateParagraph({Title="Info",
    Content="LahanUpdate:FireServer('CONFIRM_BUY', {PartName, Price})\n"
        .."Aktifkan Auto Confirm di Tab 👤 Player\nagar tidak perlu konfirmasi manual"})

for _, l in ipairs(LAHAN_LIST) do
    local ll = l
    TabLahan:CreateButton({Name="🏞 Beli "..ll.label.." | "..ll.price.."💰",
        Callback=function()
            task.spawn(function()
                local ok, err = fireEv("LahanUpdate", "CONFIRM_BUY",
                    {["PartName"]=ll.partName, ["Price"]=ll.price})
                notif(ok and "Beli Lahan ✅" or "Gagal ❌",
                    ok and ll.label or tostring(err), 4)
            end)
        end})
end

-- ══════════════════════════════════════════
-- TAB HUJAN
-- ══════════════════════════════════════════
TabHujan:CreateSection("🌧 Summon Rain")

TabHujan:CreateParagraph({Title="Kegunaan",
    Content="RainConfig: GrowthSpeedMultiplier = 1.5x\n"
        .."Tanaman tumbuh 50% LEBIH CEPAT saat hujan!\n\n"
        .."Duration: 120–180 detik\n"
        .."Remote: SummonRain:FireServer()"})

TabHujan:CreateButton({Name="🌧 SUMMON RAIN SEKARANG",
    Callback=function()
        task.spawn(function()
            local ok, err = summonRain()
            notif(ok and "🌧 Hujan! ✅" or "Gagal ❌",
                ok and "Tanaman 1.5x lebih cepat! 🔥" or tostring(err), 4)
        end)
    end})

TabHujan:CreateSlider({Name="Auto Rain Interval (s)", Range={30,600}, Increment=30, CurrentValue=150,
    Callback=function(v) rainInterval=v end})

TabHujan:CreateToggle({Name="🌧 Auto Rain Loop", CurrentValue=false,
    Callback=function(v)
        _G.AutoRain = v
        if v then
            task.spawn(function()
                while _G.AutoRain do
                    local ok = pcall(summonRain)
                    if ok then notif("🌧 Rain!", "1.5x growth aktif!", 3) end
                    task.wait(rainInterval)
                end
            end)
            notif("Auto Rain ON ✅", "Interval "..rainInterval.."s", 3)
        else
            notif("Auto Rain OFF", "", 2)
        end
    end})

TabHujan:CreateSection("🧼 Tools Anti Petir")

TabHujan:CreateParagraph({Title="Payung (dari RequestToolShop)",
    Content="☂️ Payung — 100 💰\nEffect: Anti Petir\nHarus dipegang saat hujan\n\n"
        .."Atau gunakan tab ⚡ Petir untuk auto evade!"})

TabHujan:CreateButton({Name="☂️ Beli Payung (100 💰)",
    Callback=function()
        task.spawn(function()
            -- RequestToolShop dengan arg nama tool
            local ok, result = invokeRF("RequestToolShop", "Payung")
            if ok then
                local data=(type(result)=="table" and result[1]) and result[1] or result
                notif(data and data.Success and "Beli ✅" or "Beli ❌",
                    data and (data.Message or tostring(ok)) or "Gagal", 3)
            else
                notif("Gagal ❌", tostring(result), 3)
            end
        end)
    end})

-- ══════════════════════════════════════════
-- TAB PETIR
-- ══════════════════════════════════════════
TabPetir:CreateSection("⚡ Penangkal Petir")

TabPetir:CreateParagraph({Title="Cara Kerja",
    Content="Intercept LightningStrike.OnClientEvent\n"
        .."Data: {Position=Vector3, Hit=true, Reason='EXPOSED'}\n\n"
        .."Saat event diterima → langsung TP ke Safe Pos\n"
        .."sebelum damage terhitung!\n\n"
        .."⚠️ Set Safe Pos dulu (di dalam bangunan/atap)"})

TabPetir:CreateButton({Name="📍 SET SAFE POSITION",
    Callback=function()
        local p = getPos()
        if p then
            SafePos = p
            notif("Safe Pos ✅", string.format("X=%.1f Y=%.1f Z=%.1f", p.X,p.Y,p.Z), 4)
        end
    end})

TabPetir:CreateToggle({Name="⚡ Penangkal Petir AKTIF", CurrentValue=false,
    Callback=function(v)
        _G.PenangkalPetir = v
        notif("Penangkal Petir", v and "ON ✅" or "OFF", 2)
    end})

TabPetir:CreateButton({Name="🗑 Reset Counter",
    Callback=function() lightningHits=0; notif("Reset ✅","",2) end})

-- ══════════════════════════════════════════
-- TAB ESP
-- ══════════════════════════════════════════
TabESP:CreateSection("👁 ESP")

TabESP:CreateParagraph({Title="Warna",
    Content="🔵 Biru = Lahan Sawah\n🟩 Hijau Muda = Lahan Sawit\n"
        .."🟢 Hijau = Tanaman\n🟡 Kuning = NPC\n🟠 Oranye = Ternak"})

TabESP:CreateToggle({Name="👁 ESP Aktif", CurrentValue=false,
    Callback=function(v)
        _G.ESP = v
        if v then updateESP(); notif("ESP ON ✅", #ESPObjects.." obj", 2)
        else clearESP(); notif("ESP OFF","",2) end
    end})

TabESP:CreateButton({Name="🔄 Refresh ESP",
    Callback=function()
        if _G.ESP then updateESP(); notif("Refresh ✅", #ESPObjects.." obj", 3)
        else notif("ESP","Aktifkan dulu!",3) end
    end})

TabESP:CreateButton({Name="🗑 Clear ESP",
    Callback=function() clearESP(); _G.ESP=false; notif("Cleared","",2) end})

-- ══════════════════════════════════════════
-- TAB SETTING
-- ══════════════════════════════════════════
TabSet:CreateSection("⚙ Setting")

TabSet:CreateSlider({Name="Delay PlantCrop (s)", Range={0.1,3}, Increment=0.1, CurrentValue=0.5,
    Callback=function(v) dTanam=v end})
TabSet:CreateSlider({Name="Tunggu Panen (s)", Range={10,300}, Increment=5, CurrentValue=60,
    Callback=function(v) waitPanen=v end})
TabSet:CreateSlider({Name="Auto Rain Interval (s)", Range={30,600}, Increment=30, CurrentValue=150,
    Callback=function(v) rainInterval=v end})

TabSet:CreateSection("📍 Info")

TabSet:CreateButton({Name="📍 Koordinat Saya",
    Callback=function()
        local p = getPos()
        if p then notif("Posisi", string.format("X=%.2f\nY=%.2f\nZ=%.2f",p.X,p.Y,p.Z), 5) end
    end})

TabSet:CreateSection("🛑 Emergency")
TabSet:CreateButton({Name="🛑 STOP SEMUA AUTO", Callback=function() stopSemua() end})

-- ══════════════════════════════════════════
-- TAB TEST REMOTE
-- ══════════════════════════════════════════
TabTest:CreateSection("🔥 Fire Remote Manual")

local testName = ""
local testArg1 = ""

TabTest:CreateInput({Name="Nama Remote", PlaceholderText="contoh: RequestSell",
    RemoveTextAfterFocusLost=false, Callback=function(v) testName=v end})
TabTest:CreateInput({Name="Arg 1 (opsional)", PlaceholderText="string/number/bool",
    RemoveTextAfterFocusLost=false, Callback=function(v) testArg1=v end})

TabTest:CreateButton({Name="🔥 INVOKE / FIRE",
    Callback=function()
        if testName=="" then notif("❌","Masukkan nama remote!",3); return end
        task.spawn(function()
            local args = {}
            if testArg1 ~= "" then
                local n = tonumber(testArg1)
                if n then table.insert(args,n)
                elseif testArg1=="true"  then table.insert(args,true)
                elseif testArg1=="false" then table.insert(args,false)
                else table.insert(args,testArg1) end
            end

            local r = getRemote(testName)
            if not r then notif("❌","Remote '"..testName.."' tidak ditemukan",3); return end

            if r:IsA("RemoteFunction") then
                local ok, res = invokeRF(testName, table.unpack(args))
                notif(ok and "InvokeServer ✅" or "❌",
                    "Result: "..tostring(res), 5)
                if ok and type(res)=="table" then
                    -- print lengkap ke console
                    for k,v in pairs((type(res[1])=="table" and res[1]) or res) do
                        print("[XKID RESULT] "..tostring(k).." = "..tostring(v))
                    end
                end
            else
                local ok, err = fireEv(testName, table.unpack(args))
                notif(ok and "FireServer ✅" or "❌",
                    ok and "Fired!" or tostring(err), 3)
            end
        end)
    end})

TabTest:CreateSection("⚡ Quick Test (semua remote dikonfirmasi)")

local quickList = {
    -- RemoteFunction
    {"SyncData",        "👤 SyncData → data player"},
    {"RequestSell",     "💰 RequestSell → jual/data inventori"},
    {"RequestShop",     "🛒 RequestShop → data bibit"},
    {"RequestToolShop", "🔧 RequestToolShop → data tools"},
    {"RequestLahan",    "🏞 RequestLahan"},
    -- RemoteEvent
    {"SummonRain",      "🌧 SummonRain → panggil hujan"},
    {"SkipTutorial",    "📖 SkipTutorial"},
    {"RefreshShop",     "🔄 RefreshShop"},
}

for _, qt in ipairs(quickList) do
    local q = qt
    TabTest:CreateButton({Name=q[2],
        Callback=function()
            task.spawn(function()
                local r = getRemote(q[1])
                if not r then notif("❌",q[1].." tidak ada",3); return end
                if r:IsA("RemoteFunction") then
                    local ok, res = invokeRF(q[1])
                    notif(q[1], ok and "OK → lihat console" or "❌ "..tostring(res), 4)
                    if ok and type(res)=="table" then
                        local d=(type(res[1])=="table" and res[1]) or res
                        for k,v in pairs(d) do
                            print("[XKID "..q[1].."] "..tostring(k).." = "..tostring(v))
                        end
                    end
                else
                    local ok,err = fireEv(q[1])
                    notif(q[1], ok and "Fired ✅" or "❌ "..tostring(err), 3)
                end
            end)
        end})
end

-- ══════════════════════════════════════════
-- INIT
-- ══════════════════════════════════════════

setupIntercepts()

-- Auto sync + scan saat load
task.spawn(function()
    task.wait(3)
    -- Sync data player
    syncData()
    -- Scan lahan otomatis
    scanLahan()
    if #LahanCache > 0 then
        notif("Scan ✅", #LahanCache.." lahan ditemukan otomatis!", 4)
    end
end)

notif("🌾 SAWAH INDO v10.0", "Welcome "..LocalPlayer.Name.."! 🔥", 5)
task.wait(1.2)
notif("✅ Full Spy Edition",
    "Beli:  GetBibit(0,false)\n"
    .."Tanam: PlantCrop(Vector3)\n"
    .."Jual:  RequestSell() → auto!", 7)
task.wait(1.5)
notif("🌧 Tips", "Aktifkan Auto Rain dulu\nagar tanaman 1.5x lebih cepat!", 5)

print(string.rep("═",50))
print("  🌾 SAWAH INDO v10.0 ULTIMATE — XKID HUB")
print("  Full Remote Spy Edition")
print("  PlantCrop(V3) + RequestSell() + SummonRain")
print("  Player: "..LocalPlayer.Name)
print(string.rep("═",50))
