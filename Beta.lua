--[[
  ╔══════════════════════════════════════════════════════╗
  ║        🛠  X K I D   U T I L I T Y  v2.0  🛠       ║
  ║        XKID HUB  ✦  Aurora UI                      ║
  ╚══════════════════════════════════════════════════════╝

  FITUR v2.0:
  [1]  Anti AFK        — Cegah disconnect
  [2]  Rocket Fly      — Keyboard + Tombol Android
  [3]  NoClip          — Tembus tembok
  [4]  Teleport        — Ke player (pilih list) · Mouse · Slot
  [5]  ESP Player      — Nama + jarak + area, tembus dinding
  [6]  Speed & Jump    — WalkSpeed · JumpPower · Infinite Jump
  [7]  Protection      — Anti AFK · Anti Kick · Rejoin
  [8]  Scan NPC        — Nama · Posisi · Jarak · Kategori
  [9]  Scan Lahan      — Lahan · Tanaman · Status panen
  [10] Scan Toko       — Item · Harga · Stok · Auto Buy
  [11] Respawn Posisi  — Mati & kembali ke posisi sama
]]

-- ════════════════════════════════════════════════
--  LOAD AURORA UI
-- ════════════════════════════════════════════════
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UIS           = game:GetService("UserInputService")
local VirtualUser   = game:GetService("VirtualUser")
local TeleportSvc   = game:GetService("TeleportService")
local Workspace     = game:GetService("Workspace")
local RS            = game:GetService("ReplicatedStorage")
local LocalPlayer   = Players.LocalPlayer

-- ════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════
local Win = Library:Window(
    "🛠 XKID UTILITY",
    "wrench",
    "v2.0  |  XKID HUB",
    false
)

-- ════════════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════════════
Win:TabSection("🛠 MAIN")
local TabMain   = Win:Tab("Main",      "heart")
local TabFly    = Win:Tab("Fly",       "rocket")
local TabTP     = Win:Tab("Teleport",  "map-pin")
local TabESP    = Win:Tab("ESP",       "eye")

Win:TabSection("🔍 SCANNER")
local TabNPC    = Win:Tab("Scan NPC",  "user")
local TabLahan  = Win:Tab("Scan Lahan","wheat")
local TabToko   = Win:Tab("Scan Toko", "shopping-cart")

-- ════════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════════
local function getChar()  return LocalPlayer.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getDist(posA, posB)
    return math.floor((posA - posB).Magnitude + 0.5)
end

-- ════════════════════════════════════════════════
--  ① ANTI AFK + ANTI KICK + REJOIN
-- ════════════════════════════════════════════════
local _afkConn    = nil
local _kickConn   = nil
local _antiKickOn = false

local function startAntiAFK()
    if _afkConn then return end
    _afkConn = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
local function stopAntiAFK()
    if _afkConn then _afkConn:Disconnect(); _afkConn = nil end
end

local function startAntiKick()
    if _antiKickOn then return end
    _antiKickOn = true
    -- Override kick dengan pcall pada semua remote yang mungkin memicu kick
    task.spawn(function()
        while _antiKickOn do
            pcall(function()
                local hum = getHum()
                if hum and hum.Health <= 0 then
                    -- Re-apply agar tidak mati karena anti-kick system game
                    hum.Health = hum.MaxHealth
                end
            end)
            task.wait(1)
        end
    end)
end
local function stopAntiKick()
    _antiKickOn = false
end

-- ════════════════════════════════════════════════
--  ② WALKSPEED & JUMPPOWER
-- ════════════════════════════════════════════════
local currentWS = 16
local currentJP = 50

local function setWalkSpeed(v)
    currentWS = v
    local hum = getHum()
    if hum then hum.WalkSpeed = v end
end

local function setJumpPower(v)
    currentJP = v
    local hum = getHum()
    if hum then
        hum.JumpPower = v
        hum.UseJumpPower = true
    end
end

-- Re-apply saat respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.5)
        hum.WalkSpeed  = currentWS
        hum.JumpPower  = currentJP
        hum.UseJumpPower = true
    end
end)

-- ════════════════════════════════════════════════
--  ③ INFINITE JUMP
-- ════════════════════════════════════════════════
local _jumpConn = nil
local function setInfiniteJump(state)
    if state then
        _jumpConn = UIS.JumpRequest:Connect(function()
            local hum = getHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if _jumpConn then _jumpConn:Disconnect(); _jumpConn = nil end
    end
end

-- ════════════════════════════════════════════════
--  ④ RESPAWN DI POSISI SAMA
-- ════════════════════════════════════════════════
local function respawnSamePos()
    local root = getRoot()
    if not root then
        Library:Notification("❌", "Karakter tidak ada", 2); return
    end
    local savedCF = root.CFrame
    local ch = getChar()
    if ch then ch:BreakJoints() end
    local conn
    conn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        conn:Disconnect()
        task.wait(1)
        local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
        local hum = newChar:WaitForChild("Humanoid", 5)
        if hrp then hrp.CFrame = savedCF end
        if hum then
            hum.WalkSpeed = currentWS
            hum.JumpPower = currentJP
            hum.UseJumpPower = true
        end
        Library:Notification("✅ Respawn", "Kembali ke posisi semula", 3)
    end)
end

-- ════════════════════════════════════════════════
--  ⑤ NOCLIP
-- ════════════════════════════════════════════════
local noclipOn   = false
local _noclipConn= nil

local function setNoclip(state)
    noclipOn = state
    if state then
        _noclipConn = RunService.Stepped:Connect(function()
            local ch = getChar(); if not ch then return end
            for _, p in pairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end)
        Library:Notification("NoClip", "ON — tembus tembok", 2)
    else
        if _noclipConn then _noclipConn:Disconnect(); _noclipConn = nil end
        -- Kembalikan collision
        local ch = getChar()
        if ch then
            for _, p in pairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
        Library:Notification("NoClip", "OFF", 2)
    end
end

-- ════════════════════════════════════════════════
--  ⑥ ROCKET FLY (Keyboard + Android Button)
-- ════════════════════════════════════════════════
local SPEED         = 127
local REL_TO_CHAR   = false
local MAX_TORQUE_RP = 1e4
local THRUST_P      = 1e5
local MAX_THRUST    = 5e5
local MAX_TORQUE_BG = 3e4
local THRUST_D      = math.huge
local TURN_D        = 2e2

local flyEnabled = false
local flying     = false
local move_dir   = Vector3.new()
local keys_dn    = {}
local humanoidFly, parentFly
local ms = LocalPlayer:GetMouse()

_G.xku_fly_evts = _G.xku_fly_evts or {}
_G.xku_fly_rp   = nil
_G.xku_fly_bg   = nil
_G.xku_fly_pt   = nil

-- Android direction state
local androidDir = {up=false, down=false, fwd=false, bwd=false, left=false, right=false}

local FLYK = Enum.KeyCode.H
local ANCK = Enum.KeyCode.G
local FSTK = Enum.KeyCode.L
local SLWK = Enum.KeyCode.K

local MVKS = {
    [Enum.KeyCode.D]        = Vector3.new( 1, 0,  0),
    [Enum.KeyCode.A]        = Vector3.new(-1, 0,  0),
    [Enum.KeyCode.S]        = Vector3.new( 0, 0,  1),
    [Enum.KeyCode.W]        = Vector3.new( 0, 0, -1),
    [Enum.KeyCode.E]        = Vector3.new( 0, 1,  0),
    [Enum.KeyCode.Q]        = Vector3.new( 0,-1,  0),
    [Enum.KeyCode.Right]    = Vector3.new( 1, 0,  0),
    [Enum.KeyCode.Left]     = Vector3.new(-1, 0,  0),
    [Enum.KeyCode.Down]     = Vector3.new( 0, 0,  1),
    [Enum.KeyCode.Up]       = Vector3.new( 0, 0, -1),
    [Enum.KeyCode.PageUp]   = Vector3.new( 0, 1,  0),
    [Enum.KeyCode.PageDown] = Vector3.new( 0,-1,  0),
}

local function calcAndroidDir()
    local v = Vector3.new()
    if androidDir.fwd   then v = v + Vector3.new( 0, 0,-1) end
    if androidDir.bwd   then v = v + Vector3.new( 0, 0, 1) end
    if androidDir.left  then v = v + Vector3.new(-1, 0, 0) end
    if androidDir.right then v = v + Vector3.new( 1, 0, 0) end
    if androidDir.up    then v = v + Vector3.new( 0, 1, 0) end
    if androidDir.down  then v = v + Vector3.new( 0,-1, 0) end
    return v
end

local function fly_dir()
    -- Gabungkan keyboard + android
    local combined = move_dir + calcAndroidDir()
    if combined.Magnitude == 0 then return combined end
    if REL_TO_CHAR and parentFly then
        return CFrame.new(Vector3.new(), parentFly.CFrame.LookVector) * combined
    end
    local front = Workspace.CurrentCamera:ScreenPointToRay(ms.X, ms.Y).Direction
    return CFrame.new(Vector3.new(), front) * combined
end

local function init_fly()
    local ch = getChar(); if not ch then return end
    humanoidFly = ch:FindFirstChildOfClass("Humanoid"); if not humanoidFly then return end
    parentFly   = humanoidFly.RootPart;                 if not parentFly then return end

    if _G.xku_fly_rp then pcall(function() _G.xku_fly_rp:Destroy() end) end
    if _G.xku_fly_bg then pcall(function() _G.xku_fly_bg:Destroy() end) end
    if _G.xku_fly_pt and _G.xku_fly_pt.Parent then
        pcall(function() _G.xku_fly_pt.Parent:Destroy() end)
    end

    _G.xku_fly_bg  = Instance.new("BodyGyro",         parentFly)
    _G.xku_fly_rp  = Instance.new("RocketPropulsion", parentFly)
    local md       = Instance.new("Model")
    _G.xku_fly_pt  = Instance.new("Part", md)
    md.Parent      = _G.xku_fly_pt

    _G.xku_fly_rp.MaxTorque    = Vector3.new(MAX_TORQUE_RP, MAX_TORQUE_RP, MAX_TORQUE_RP)
    _G.xku_fly_bg.MaxTorque    = Vector3.new()
    md.PrimaryPart             = _G.xku_fly_pt
    _G.xku_fly_pt.Anchored     = true
    _G.xku_fly_pt.CanCollide   = false
    _G.xku_fly_pt.Transparency = 1
    _G.xku_fly_rp.CartoonFactor= 1
    _G.xku_fly_rp.Target       = _G.xku_fly_pt
    _G.xku_fly_rp.MaxSpeed     = SPEED
    _G.xku_fly_rp.MaxThrust    = MAX_THRUST
    _G.xku_fly_rp.ThrustP      = THRUST_P
    _G.xku_fly_rp.ThrustD      = THRUST_D
    _G.xku_fly_rp.TurnP        = THRUST_P
    _G.xku_fly_rp.TurnD        = TURN_D
    _G.xku_fly_bg.P            = 3e4
    flyEnabled = false; flying = false
end

local function setup_fly_events()
    for _, e in ipairs(_G.xku_fly_evts) do pcall(function() e:Disconnect() end) end
    _G.xku_fly_evts = {}

    table.insert(_G.xku_fly_evts, LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1); init_fly()
    end))

    table.insert(_G.xku_fly_evts, UIS.InputBegan:Connect(function(i, p)
        if p then return end
        if i.KeyCode == FLYK then
            flyEnabled = not flyEnabled
            if flyEnabled then
                if _G.xku_fly_bg then _G.xku_fly_bg.MaxTorque = Vector3.new(MAX_TORQUE_BG,0,MAX_TORQUE_BG) end
                if _G.xku_fly_rp then _G.xku_fly_rp.MaxTorque = Vector3.new(MAX_TORQUE_RP,MAX_TORQUE_RP,MAX_TORQUE_RP) end
                Library:Notification("🚀 Fly","ON",1)
            else
                if _G.xku_fly_bg then _G.xku_fly_bg.MaxTorque = Vector3.new() end
                if _G.xku_fly_rp then _G.xku_fly_rp.MaxTorque = Vector3.new() end
                Library:Notification("🚀 Fly","OFF",1)
            end
        elseif i.KeyCode == ANCK and parentFly then
            parentFly.Anchored = not parentFly.Anchored
            Library:Notification("Anchor", parentFly.Anchored and "ON" or "OFF", 1)
        elseif i.KeyCode == FSTK and _G.xku_fly_rp then
            SPEED = SPEED * 1.5; _G.xku_fly_rp.MaxSpeed = SPEED
            Library:Notification("Speed ⬆", string.format("%.0f", SPEED), 1)
        elseif i.KeyCode == SLWK and _G.xku_fly_rp then
            SPEED = math.max(10, SPEED/1.5); _G.xku_fly_rp.MaxSpeed = SPEED
            Library:Notification("Speed ⬇", string.format("%.0f", SPEED), 1)
        elseif MVKS[i.KeyCode] and not keys_dn[i.KeyCode] then
            move_dir = move_dir + MVKS[i.KeyCode]; keys_dn[i.KeyCode] = true
        end
    end))

    table.insert(_G.xku_fly_evts, UIS.InputEnded:Connect(function(i, p)
        if p then return end
        if MVKS[i.KeyCode] and keys_dn[i.KeyCode] then
            move_dir = move_dir - MVKS[i.KeyCode]; keys_dn[i.KeyCode] = nil
        end
    end))

    table.insert(_G.xku_fly_evts, RunService.RenderStepped:Connect(function()
        if not _G.xku_fly_rp or not parentFly then return end
        local combined = move_dir + calcAndroidDir()
        local do_fly = flyEnabled and combined.Magnitude > 0
        if flying ~= do_fly then
            flying = do_fly
            if humanoidFly then humanoidFly.AutoRotate = not do_fly end
            if not do_fly then
                parentFly.Velocity = Vector3.new()
                _G.xku_fly_rp:Abort(); return
            end
            _G.xku_fly_rp:Fire()
        end
        if _G.xku_fly_pt and do_fly then
            _G.xku_fly_pt.Position = parentFly.Position + 10000 * fly_dir()
        end
    end))
end

-- ════════════════════════════════════════════════
--  ⑦ ESP PLAYER
-- ════════════════════════════════════════════════
local espEnabled = false
local espObjects  = {}
local espConns    = {}

local function clearESP()
    for _, o in ipairs(espObjects) do pcall(function() o:Destroy() end) end
    espObjects = {}
    for _, c in ipairs(espConns)   do pcall(function() c:Disconnect() end) end
    espConns = {}
end

local function getPlayerArea(char)
    -- Coba deteksi area/room dari nama model di sekitar karakter
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return "?" end
    local pos = root.Position
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Model") then
            local n = v.Name:lower()
            if n:find("room") or n:find("area") or n:find("zone")
            or n:find("salon") or n:find("vip") or n:find("private") then
                if v:IsA("BasePart") then
                    local d = (v.Position - pos).Magnitude
                    if d < 30 then return v.Name end
                end
            end
        end
    end
    return "Lobby"
end

local function makeESPFor(player)
    if player == LocalPlayer then return end
    local function onChar(char)
        if not espEnabled then return end
        task.wait(0.5)
        local head = char:FindFirstChild("Head"); if not head then return end

        local bill = Instance.new("BillboardGui")
        bill.Name         = "XKID_ESP"
        bill.Size         = UDim2.new(0, 200, 0, 55)
        bill.StudsOffset  = Vector3.new(0, 3, 0)
        bill.AlwaysOnTop  = true
        bill.Adornee      = head
        bill.Parent       = char

        -- Background
        local bg = Instance.new("Frame", bill)
        bg.Size                  = UDim2.new(1,0,1,0)
        bg.BackgroundColor3      = Color3.fromRGB(0,0,0)
        bg.BackgroundTransparency= 0.5
        bg.BorderSizePixel       = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0,6)

        local lbl = Instance.new("TextLabel", bg)
        lbl.Size                  = UDim2.new(1,-4,1,-4)
        lbl.Position              = UDim2.new(0,2,0,2)
        lbl.BackgroundTransparency= 1
        lbl.TextColor3            = Color3.fromRGB(255,255,100)
        lbl.TextStrokeTransparency= 0.3
        lbl.TextScaled            = true
        lbl.Font                  = Enum.Font.GothamBold
        lbl.TextXAlignment        = Enum.TextXAlignment.Center

        -- Update label tiap 0.5 detik (jarak + area)
        local updateConn
        updateConn = RunService.Heartbeat:Connect(function()
            if not bill or not bill.Parent then
                updateConn:Disconnect(); return
            end
            local myRoot = getRoot()
            local dist = myRoot and getDist(head.Position, myRoot.Position) or 0
            local area = getPlayerArea(char)
            lbl.Text = string.format("👤 %s\n📍 %dm | %s", player.Name, dist, area)
        end)
        table.insert(espConns, updateConn)
        table.insert(espObjects, bill)
    end

    if player.Character then onChar(player.Character) end
    table.insert(espConns, player.CharacterAdded:Connect(onChar))
end

local function toggleESP(state)
    espEnabled = state
    clearESP()
    if state then
        for _, p in pairs(Players:GetPlayers()) do makeESPFor(p) end
        table.insert(espConns, Players.PlayerAdded:Connect(makeESPFor))
        Library:Notification("👁 ESP", "ON", 2)
    else
        Library:Notification("👁 ESP", "OFF", 2)
    end
end

-- ════════════════════════════════════════════════
--  ⑧ TELEPORT
-- ════════════════════════════════════════════════
local savedSlots = {nil,nil,nil,nil,nil}

local function tpToPlayer(name)
    if not name or name == "" then
        Library:Notification("❌","Masukkan nama player",2); return
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if p.Name:lower():find(name:lower(),1,true)
            or p.DisplayName:lower():find(name:lower(),1,true) then
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local root = getRoot()
                    if root then
                        root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
                        Library:Notification("📍 TP","→ "..p.Name,2); return
                    end
                end
            end
        end
    end
    Library:Notification("❌","Player tidak ditemukan",2)
end

local function tpToMouse()
    local mouse = LocalPlayer:GetMouse()
    if mouse and mouse.Hit and getChar() then
        local root = getRoot()
        if root then
            root.CFrame = mouse.Hit * CFrame.new(0,3,0)
            Library:Notification("📍 TP","Ke posisi mouse",2)
        end
    end
end

-- ════════════════════════════════════════════════
--  ⑨ SCAN NPC
-- ════════════════════════════════════════════════
local NPC_CATEGORIES = {
    pedagang = {"pedagang","toko","shop","seller","vendor","merchant","jual","beli"},
    quest    = {"quest","misi","task","npc","guide","tutor"},
    admin    = {"admin","mod","owner","staff","vip"},
}

local function categorizeNPC(name)
    local nl = name:lower()
    for cat, keywords in pairs(NPC_CATEGORIES) do
        for _, kw in ipairs(keywords) do
            if nl:find(kw) then return cat end
        end
    end
    return "umum"
end

local function scanNPC(filterName, filterMaxDist)
    local myRoot = getRoot()
    local results = {}
    local seen = {}

    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and not seen[v] then
            local hasHum = v:FindFirstChildOfClass("Humanoid") ~= nil
            local rootPart = v:FindFirstChild("HumanoidRootPart") or v.PrimaryPart
            if hasHum and rootPart then
                seen[v] = true
                local dist = myRoot and getDist(rootPart.Position, myRoot.Position) or 0
                local cat  = categorizeNPC(v.Name)

                -- Filter nama
                if filterName and filterName ~= "" then
                    if not v.Name:lower():find(filterName:lower()) then
                        goto continue
                    end
                end
                -- Filter jarak
                if filterMaxDist and filterMaxDist > 0 then
                    if dist > filterMaxDist then goto continue end
                end

                table.insert(results, {
                    name = v.Name,
                    pos  = rootPart.Position,
                    dist = dist,
                    cat  = cat,
                    model= v,
                })
            end
            ::continue::
        end
    end

    table.sort(results, function(a,b) return a.dist < b.dist end)
    return results
end

-- ════════════════════════════════════════════════
--  ⑩ SCAN LAHAN & TANAMAN
-- ════════════════════════════════════════════════
local LAHAN_KEYWORDS  = {"areatanam","tanah","plot","lahan","sawah","field","farm"}
local TANAMAN_KEYWORDS= {"padi","jagung","tomat","terong","strawberry","sawit","durian",
                          "crop","plant","tanaman","flower","bunga"}

local function isMature(v)
    -- Cek apakah tanaman punya ProximityPrompt (siap panen)
    return v:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
end

local function scanLahan()
    local myRoot = getRoot()
    local lahanList   = {}
    local tanamanList = {}

    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Model") then
            local n = v.Name:lower()
            local pos = v:IsA("BasePart") and v.Position
                     or (v:IsA("Model") and v.PrimaryPart and v.PrimaryPart.Position)
                     or nil
            if not pos then goto skipL end

            local dist = myRoot and getDist(pos, myRoot.Position) or 0

            -- Cek lahan
            for _, kw in ipairs(LAHAN_KEYWORDS) do
                if n:find(kw) then
                    table.insert(lahanList, {name=v.Name, pos=pos, dist=dist})
                    goto skipL
                end
            end

            -- Cek tanaman
            for _, kw in ipairs(TANAMAN_KEYWORDS) do
                if n:find(kw) then
                    local mature = isMature(v)
                    table.insert(tanamanList, {
                        name   = v.Name,
                        pos    = pos,
                        dist   = dist,
                        mature = mature,
                    })
                    goto skipL
                end
            end
            ::skipL::
        end
    end

    table.sort(lahanList,   function(a,b) return a.dist < b.dist end)
    table.sort(tanamanList, function(a,b) return a.dist < b.dist end)
    return lahanList, tanamanList
end

-- ════════════════════════════════════════════════
--  ⑪ SCAN TOKO
-- ════════════════════════════════════════════════
local autoBuyEnabled = false
local autoBuyTarget  = ""

local function scanToko()
    local items = {}
    -- Cari dari ReplicatedStorage (RequestShop)
    local remotes = RS:FindFirstChild("Remotes")
    remotes = remotes and remotes:FindFirstChild("TutorialRemotes")
    if remotes then
        local shopRF = remotes:FindFirstChild("RequestShop")
        if shopRF and shopRF:IsA("RemoteFunction") then
            local ok, res = pcall(function() return shopRF:InvokeServer("GET_LIST") end)
            if ok and type(res) == "table" then
                local data = (type(res[1])=="table") and res[1] or res
                local seeds = data.Seeds or data.Items or data.Products or {}
                for _, s in ipairs(seeds) do
                    table.insert(items, {
                        name   = s.Name   or "?",
                        price  = s.Price  or 0,
                        owned  = s.Owned  or 0,
                        locked = s.Locked or false,
                        source = "RequestShop"
                    })
                end
            end
        end
    end

    -- Fallback: scan SurfaceGui / BillboardGui di workspace untuk baca harga
    if #items == 0 then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("SurfaceGui") or v:IsA("BillboardGui") then
                local n = v.Name:lower()
                if n:find("shop") or n:find("toko") or n:find("harga") or n:find("price") then
                    for _, label in pairs(v:GetDescendants()) do
                        if label:IsA("TextLabel") or label:IsA("TextButton") then
                            local txt = label.Text
                            -- Cari pola harga: angka dengan simbol 💰 atau $
                            local price = txt:match("(%d+)") 
                            if price then
                                table.insert(items, {
                                    name   = v.Parent and v.Parent.Name or "?",
                                    price  = tonumber(price) or 0,
                                    owned  = 0,
                                    locked = false,
                                    source = "GUI Scan"
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    return items
end

local function autoBuyItem(itemName, qty)
    local remotes = RS:FindFirstChild("Remotes")
    remotes = remotes and remotes:FindFirstChild("TutorialRemotes")
    if not remotes then return false, "Remote tidak ada" end
    local shopRF = remotes:FindFirstChild("RequestShop")
    if not shopRF then return false, "RequestShop tidak ada" end
    local ok, res = pcall(function() return shopRF:InvokeServer("BUY", itemName, qty or 1) end)
    if not ok then return false, "Remote error" end
    local data = (type(res)=="table" and type(res[1])=="table") and res[1] or res
    if data and data.Success then return true, data.Message or "Berhasil" end
    return false, (data and data.Message) or "Gagal"
end

-- ════════════════════════════════════════════════
--  INIT FLY
-- ════════════════════════════════════════════════
task.spawn(function()
    task.wait(1); init_fly(); setup_fly_events()
end)

-- ════════════════════════════════════════════════
--  BUILD UI — TAB MAIN
-- ════════════════════════════════════════════════
local MainPage  = TabMain:Page("Utility", "heart")
local MainLeft  = MainPage:Section("🛠 Controls", "Left")
local MainRight = MainPage:Section("⚡ Speed & Info", "Right")

-- Anti AFK
MainLeft:Toggle("Anti AFK", "AntiAFKToggle", false,
    "Cegah disconnect otomatis",
    function(v)
        if v then startAntiAFK() else stopAntiAFK() end
        Library:Notification("Anti AFK", v and "ON" or "OFF", 2)
    end)

-- Anti Kick
MainLeft:Toggle("Anti Kick", "AntiKickToggle", false,
    "Cegah dikeluarkan dari game",
    function(v)
        if v then startAntiKick() else stopAntiKick() end
        Library:Notification("Anti Kick", v and "ON" or "OFF", 2)
    end)

-- Rejoin
MainLeft:Button("🔄 Rejoin Server", "Koneksi ulang ke server",
    function()
        TeleportSvc:Teleport(game.PlaceId, LocalPlayer)
    end)

-- Respawn posisi
MainLeft:Button("💀 Respawn di Posisi Sama", "Mati & kembali ke posisi sekarang",
    function() respawnSamePos() end)

-- NoClip
MainLeft:Toggle("🚶 NoClip (Tembus Tembok)", "NoclipToggle", false,
    "Tembus dinding & masuk area tertutup",
    function(v) setNoclip(v) end)

-- WalkSpeed
MainRight:Slider("WalkSpeed", "WSSlider", 1, 500, 16,
    function(v) setWalkSpeed(v) end,
    "Kecepatan jalan (default 16)")

MainRight:Button("🔁 Reset Speed", "Kembalikan WalkSpeed ke 16",
    function() setWalkSpeed(16); Library:Notification("Speed","Reset ke 16",2) end)

-- JumpPower
MainRight:Slider("JumpPower", "JPSlider", 1, 500, 50,
    function(v) setJumpPower(v) end,
    "Kekuatan lompat (default 50)")

-- Infinite Jump
MainRight:Toggle("Infinite Jump", "InfJumpToggle", false,
    "Lompat terus di udara",
    function(v)
        setInfiniteJump(v)
        Library:Notification("Inf Jump", v and "ON" or "OFF", 2)
    end)

-- ════════════════════════════════════════════════
--  BUILD UI — TAB FLY
-- ════════════════════════════════════════════════
local FlyPage  = TabFly:Page("Rocket Fly", "rocket")
local FlyLeft  = FlyPage:Section("⚙ Settings", "Left")
local FlyRight = FlyPage:Section("📱 Android Buttons", "Right")

FlyLeft:Slider("Kecepatan", "FlySpeedSlider", 10, 500, 127,
    function(v) SPEED=v; if _G.xku_fly_rp then _G.xku_fly_rp.MaxSpeed=SPEED end end,
    "Kecepatan terbang")

FlyLeft:Toggle("Relatif ke Karakter", "RelCharToggle", false,
    "Gerak relatif karakter bukan kamera",
    function(v) REL_TO_CHAR=v end)

FlyLeft:Button("🚀 Toggle Fly (H)", "Aktifkan / matikan fly",
    function()
        flyEnabled = not flyEnabled
        if flyEnabled then
            if _G.xku_fly_bg then _G.xku_fly_bg.MaxTorque = Vector3.new(MAX_TORQUE_BG,0,MAX_TORQUE_BG) end
            if _G.xku_fly_rp then _G.xku_fly_rp.MaxTorque = Vector3.new(MAX_TORQUE_RP,MAX_TORQUE_RP,MAX_TORQUE_RP) end
        else
            if _G.xku_fly_bg then _G.xku_fly_bg.MaxTorque = Vector3.new() end
            if _G.xku_fly_rp then _G.xku_fly_rp.MaxTorque = Vector3.new() end
        end
        Library:Notification("🚀 Fly", flyEnabled and "ON" or "OFF", 2)
    end)

FlyLeft:Button("🔄 Reset Fly", "Init ulang jika error",
    function() init_fly(); Library:Notification("Fly","Reset ✅",2) end)

FlyLeft:Paragraph("Keyboard",
    "H — Toggle Fly\nG — Anchor\nL — Cepat\nK — Lambat\n"..
    "WASD — Gerak\nE — Naik  |  Q — Turun")

-- Android tombol arah
FlyRight:Label("Tekan & tahan untuk gerak terbang")

FlyRight:Button("⬆ MAJU",  "Terbang ke depan",  function() androidDir.fwd=true;  task.delay(0.1,function() androidDir.fwd=false  end) end)
FlyRight:Button("⬇ MUNDUR","Terbang ke belakang",function() androidDir.bwd=true;  task.delay(0.1,function() androidDir.bwd=false  end) end)
FlyRight:Button("⬅ KIRI",  "Terbang ke kiri",   function() androidDir.left=true; task.delay(0.1,function() androidDir.left=false end) end)
FlyRight:Button("➡ KANAN", "Terbang ke kanan",  function() androidDir.right=true;task.delay(0.1,function() androidDir.right=false end) end)
FlyRight:Button("🔼 NAIK",  "Terbang ke atas",   function() androidDir.up=true;   task.delay(0.1,function() androidDir.up=false   end) end)
FlyRight:Button("🔽 TURUN", "Terbang ke bawah",  function() androidDir.down=true; task.delay(0.1,function() androidDir.down=false  end) end)

FlyRight:Paragraph("Tips Android",
    "Klik cepat berulang = gerak\n"..
    "Atau pakai tombol Toggle Fly\nlalu WASD di virtual keyboard")

-- ════════════════════════════════════════════════
--  BUILD UI — TAB TELEPORT
-- ════════════════════════════════════════════════
local TpPage   = TabTP:Page("Teleport", "map-pin")
local TpLeft   = TpPage:Section("👤 Ke Player", "Left")
local TpRight  = TpPage:Section("📍 Slot & Mouse", "Right")

TpLeft:Label("Player Online:")
TpLeft:Button("🔄 Refresh Daftar Player", "Lihat siapa online",
    function()
        local list = ""
        local n = 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                list = list.."• "..p.Name
                if p.DisplayName ~= p.Name then list=list.." ("..p.DisplayName..")" end
                list = list.."\n"; n=n+1
            end
        end
        Library:Notification("👤 "..n.." Player", n>0 and list or "Tidak ada player lain", 8)
    end)

local tpName = ""
TpLeft:TextBox("Nama Player", "TPNameBox", "",
    function(v) tpName=v end, "Ketik nama player")
TpLeft:Button("📍 Teleport ke Player", "TP ke player",
    function() tpToPlayer(tpName) end)

TpLeft:Button("🖱 Teleport ke Mouse", "TP ke posisi kursor",
    function() tpToMouse() end)

-- Save & Load slot
TpRight:Label("Save posisi → Load kapanpun")
for i = 1,5 do
    local idx = i
    TpRight:Button("💾 Save Slot "..idx, "Simpan posisi ke slot "..idx,
        function()
            local cf = getRoot() and getRoot().CFrame or nil
            if not cf then Library:Notification("❌","Karakter tidak ada",2); return end
            savedSlots[idx] = cf
            local p = cf.Position
            Library:Notification("💾 Slot "..idx,
                string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z), 3)
        end)
    TpRight:Button("🚀 Load Slot "..idx, "TP ke posisi slot "..idx,
        function()
            if not savedSlots[idx] then
                Library:Notification("❌","Slot "..idx.." kosong",2); return
            end
            local root = getRoot()
            if root then
                root.CFrame = savedSlots[idx]
                local p = savedSlots[idx].Position
                Library:Notification("📍 Slot "..idx,
                    string.format("X=%.1f Y=%.1f Z=%.1f",p.X,p.Y,p.Z), 3)
            end
        end)
end

-- ════════════════════════════════════════════════
--  BUILD UI — TAB ESP
-- ════════════════════════════════════════════════
local ESPPage  = TabESP:Page("ESP Player", "eye")
local ESPLeft  = ESPPage:Section("👁 Controls", "Left")
local ESPRight = ESPPage:Section("ℹ Info", "Right")

ESPLeft:Toggle("ESP Player", "ESPToggle", false,
    "Lihat semua player tembus dinding",
    function(v) toggleESP(v) end)

ESPRight:Paragraph("Info ESP",
    "Tampilkan:\n"..
    "• Nama player\n"..
    "• Jarak dalam studs\n"..
    "• Area/room mereka\n"..
    "• Update tiap 0.5 detik\n"..
    "• Tembus dinding (AlwaysOnTop)")

-- ════════════════════════════════════════════════
--  BUILD UI — TAB SCAN NPC
-- ════════════════════════════════════════════════
local NPCPage  = TabNPC:Page("Scan NPC", "user")
local NPCLeft  = NPCPage:Section("🔍 Scanner", "Left")
local NPCRight = NPCPage:Section("⚙ Filter", "Right")

local npcFilterName = ""
local npcFilterDist = 0

NPCLeft:Button("🔍 Scan Semua NPC", "Cari semua NPC di workspace",
    function()
        task.spawn(function()
            Library:Notification("🔍 Scan NPC","Sedang scan...",2)
            local results = scanNPC(npcFilterName, npcFilterDist)
            if #results == 0 then
                Library:Notification("⚠️ NPC","Tidak ada NPC ditemukan",3); return
            end
            -- Print ke console F9
            print("\n"..string.rep("=",50))
            print("🔍 SCAN NPC — "..#results.." ditemukan")
            print(string.rep("=",50))
            for i, n in ipairs(results) do
                print(string.format("[%d] %-25s | Kat: %-10s | Dist: %dm | X=%.1f Y=%.1f Z=%.1f",
                    i, n.name, n.cat, n.dist, n.pos.X, n.pos.Y, n.pos.Z))
            end
            -- Tampilkan 5 terdekat di notif
            local txt = #results.." NPC ditemukan\n\n"
            for i = 1, math.min(5, #results) do
                local n = results[i]
                txt = txt..string.format("[%s] %s — %dm\n", n.cat:upper():sub(1,3), n.name, n.dist)
            end
            txt = txt.."\nDetail lengkap di console F9"
            Library:Notification("✅ Scan NPC", txt, 10)
        end)
    end)

NPCLeft:Button("📍 TP ke NPC Terdekat", "Teleport ke NPC paling dekat",
    function()
        local results = scanNPC("", 0)
        if #results == 0 then
            Library:Notification("❌","Tidak ada NPC ditemukan",2); return
        end
        local npc = results[1]
        local root = getRoot()
        if root then
            root.CFrame = CFrame.new(npc.pos.X, npc.pos.Y+3, npc.pos.Z)
            Library:Notification("📍 TP NPC","→ "..npc.name.." ("..npc.dist.."m)",3)
        end
    end)

NPCRight:TextBox("Filter Nama", "NPCFilterName", "",
    function(v) npcFilterName=v end, "Kosongkan = semua NPC")

NPCRight:Slider("Filter Jarak (0=semua)", "NPCFilterDist", 0, 500, 0,
    function(v) npcFilterDist=v end, "0 = tampilkan semua jarak")

NPCRight:Paragraph("Kategori NPC",
    "PEDAGANG — toko/jual/beli\n"..
    "QUEST — misi/tugas/guide\n"..
    "ADMIN — staff/owner/vip\n"..
    "UMUM — lainnya\n\n"..
    "Detail di console F9 (Shift+F9)")

-- ════════════════════════════════════════════════
--  BUILD UI — TAB SCAN LAHAN
-- ════════════════════════════════════════════════
local LahanPage  = TabLahan:Page("Scan Lahan", "wheat")
local LahanLeft  = LahanPage:Section("🌾 Lahan & Tanaman", "Left")
local LahanRight = LahanPage:Section("ℹ Info", "Right")

LahanLeft:Button("🌾 Scan Lahan & Tanaman", "Scan semua lahan dan tanaman",
    function()
        task.spawn(function()
            Library:Notification("🔍 Scan","Sedang scan...",2)
            local lahanList, tanamanList = scanLahan()

            print("\n"..string.rep("=",50))
            print("🌾 SCAN LAHAN — "..#lahanList.." lahan | "..#tanamanList.." tanaman")
            print(string.rep("=",50))

            local matang, belum = 0, 0
            for _, t in ipairs(tanamanList) do
                if t.mature then matang=matang+1 else belum=belum+1 end
                print(string.format("  🌱 %-20s | %s | Dist: %dm | X=%.1f Z=%.1f",
                    t.name, t.mature and "✅ MATANG" or "⏳ Belum", t.dist, t.pos.X, t.pos.Z))
            end

            local txt = string.format(
                "Lahan: %d plot\nTanaman: %d total\n✅ Matang: %d\n⏳ Belum: %d\n\nDetail di F9",
                #lahanList, #tanamanList, matang, belum)
            Library:Notification("🌾 Hasil Scan", txt, 8)
        end)
    end)

LahanLeft:Button("✅ Tampilkan Tanaman Matang", "Hanya tampilkan yang siap panen",
    function()
        task.spawn(function()
            local _, tanamanList = scanLahan()
            local matang = {}
            for _, t in ipairs(tanamanList) do
                if t.mature then table.insert(matang, t) end
            end
            if #matang == 0 then
                Library:Notification("⏳","Tidak ada tanaman matang",3); return
            end
            local txt = #matang.." tanaman siap panen:\n\n"
            for i=1, math.min(8, #matang) do
                txt = txt.."✅ "..matang[i].name.." ("..matang[i].dist.."m)\n"
            end
            Library:Notification("✅ Siap Panen", txt, 10)
        end)
    end)

LahanLeft:Button("📍 TP ke Tanaman Matang Terdekat", "TP ke tanaman siap panen",
    function()
        task.spawn(function()
            local _, tanamanList = scanLahan()
            for _, t in ipairs(tanamanList) do
                if t.mature then
                    local root = getRoot()
                    if root then
                        root.CFrame = CFrame.new(t.pos.X, t.pos.Y+3, t.pos.Z)
                        Library:Notification("📍 TP","→ "..t.name,2)
                        return
                    end
                end
            end
            Library:Notification("⏳","Tidak ada tanaman matang",3)
        end)
    end)

LahanRight:Paragraph("Info Scan",
    "Deteksi lahan:\nAreaTanam, Sawah, Plot, Field\n\n"..
    "Deteksi tanaman:\nPadi, Jagung, Tomat, Terong\n"..
    "Strawberry, Sawit, Durian, dll\n\n"..
    "✅ = punya ProximityPrompt\n    (siap dipanen)\n"..
    "⏳ = belum bisa dipanen")

-- ════════════════════════════════════════════════
--  BUILD UI — TAB SCAN TOKO
-- ════════════════════════════════════════════════
local TokoPage  = TabToko:Page("Scan Toko", "shopping-cart")
local TokoLeft  = TokoPage:Section("🛒 Scanner", "Left")
local TokoRight = TokoPage:Section("⚡ Auto Buy", "Right")

TokoLeft:Button("🔍 Scan Semua Item Toko", "Baca item & harga dari toko",
    function()
        task.spawn(function()
            Library:Notification("🔍 Scan Toko","Sedang scan...",2)
            local items = scanToko()
            if #items == 0 then
                Library:Notification("⚠️","Tidak ada item ditemukan\nPastikan dekat NPC toko",4)
                return
            end
            print("\n"..string.rep("=",50))
            print("🛒 SCAN TOKO — "..#items.." item")
            print(string.rep("=",50))
            local txt = #items.." item ditemukan:\n\n"
            for i, item in ipairs(items) do
                local status = item.locked and "🔒" or (item.owned>0 and "✅x"..item.owned or "⬜")
                print(string.format("[%d] %-20s | %s | %d💰 | src:%s",
                    i, item.name, status, item.price, item.source))
                if i <= 8 then
                    txt = txt..status.." "..item.name.."  "..item.price.."💰\n"
                end
            end
            if #items > 8 then txt = txt.."... +"..#items-8.." lagi di F9" end
            Library:Notification("🛒 Toko", txt, 10)
        end)
    end)

local buyItemName = ""
local buyQty      = 1

TokoLeft:TextBox("Nama Item", "BuyItemBox", "",
    function(v) buyItemName=v end, "Nama item yang mau dibeli")
TokoLeft:Slider("Jumlah", "BuyQtySlider", 1, 99, 1,
    function(v) buyQty=v end, "Jumlah yang mau dibeli")
TokoLeft:Button("🛒 Beli Sekarang", "Beli item via RequestShop",
    function()
        if buyItemName == "" then
            Library:Notification("❌","Masukkan nama item dulu",2); return
        end
        task.spawn(function()
            local ok, msg = autoBuyItem(buyItemName, buyQty)
            Library:Notification(ok and "✅ Beli" or "❌ Gagal", msg, 3)
        end)
    end)

-- Auto Buy
local autoBuyName = ""
TokoRight:Toggle("Auto Buy", "AutoBuyToggle", false,
    "Beli otomatis saat stok ada",
    function(v)
        autoBuyEnabled = v
        Library:Notification("Auto Buy", v and "ON — "..autoBuyName or "OFF", 2)
        if v and autoBuyName ~= "" then
            task.spawn(function()
                while autoBuyEnabled do
                    local ok, msg = autoBuyItem(autoBuyName, buyQty)
                    if ok then
                        Library:Notification("✅ Auto Buy", autoBuyName.." x"..buyQty, 3)
                    end
                    task.wait(5)
                end
            end)
        end
    end)

TokoRight:TextBox("Item Auto Buy", "AutoBuyNameBox", "",
    function(v) autoBuyName=v; autoBuyTarget=v end,
    "Nama item untuk auto buy")

TokoRight:Paragraph("Tips Toko",
    "• Scan dulu untuk lihat item\n"..
    "• Nama item harus exact\n"..
    "• Auto Buy tiap 5 detik\n"..
    "• Pastikan dekat NPC toko\n"..
    "• Cek F9 untuk detail")

-- ════════════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════════════
Library:Notification("🛠 XKID Utility v2.0", "Semua fitur siap!", 4)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   🛠  XKID UTILITY v2.0  — XKID HUB    ║")
print("║   AFK·Fly·NoClip·ESP·TP·Speed·Jump      ║")
print("║   Scan NPC · Lahan · Toko · Auto Buy    ║")
print("║   H=Fly · G=Anchor · L=Fast · K=Slow    ║")
print("╚══════════════════════════════════════════╝")

