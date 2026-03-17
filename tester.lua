--[[
  ╔══════════════════════════════════════════════════════╗
  ║          🌟  X K I D . H U B  v5.0  🌟             ║
  ║          Aurora UI  ✦  Mobile Optimized             ║
  ╚══════════════════════════════════════════════════════╝
  Teleport : Ketik 1-2 huruf → otomatis cari player
  Fly      : Joystick = arah · Kamera = naik/turun
  ESP · Speed · NoClip · Protection
  Farm · Shop · World · Carry · Boat · Sync
]]

-- ════════════════════════════════════════
--  AURORA UI
-- ════════════════════════════════════════
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService   = game:GetService("TeleportService")
local Workspace   = game:GetService("Workspace")
local Lighting    = game:GetService("Lighting")
local LP          = Players.LocalPlayer

-- ════════════════════════════════════════
--  REMOTE SHORTCUTS (lazy - safe)
-- ════════════════════════════════════════
local RS = game:GetService("ReplicatedStorage")
local function getTut()  return RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("TutorialRemotes") end
local function getDN()   return RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("DayNightRemotes") end
local function getCarry() return RS:FindFirstChild("Carry") end
local function getSync()  return RS:FindFirstChild("Syncing") end
local function getBoat()  return RS:FindFirstChild("RemotesBoat") end
local function fire(fn, ...)   pcall(function() fn:FireServer(...) end) end
local function invoke(fn, ...) pcall(function() fn:InvokeServer(...) end) end

-- ════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════
local Win = Library:Window("🌟 XKID.HUB", "star", "v5.0 Mobile", false)

-- ════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════
Win:TabSection("MAIN")
local TabTP    = Win:Tab("Teleport",   "map-pin")
local TabFly   = Win:Tab("Fly",        "rocket")
local TabESP   = Win:Tab("ESP",        "eye")
local TabSpeed = Win:Tab("Speed",      "zap")
local TabProt  = Win:Tab("Protection", "shield")

local TabFarm  = Win:Tab("Farming",    "leaf")
local TabShop  = Win:Tab("Shop",       "shopping-cart")
local TabWorld = Win:Tab("World",      "globe")
local TabCarry = Win:Tab("Carry",      "users")
local TabBoat  = Win:Tab("Boat",       "anchor")
local TabSync  = Win:Tab("Sync",       "refresh-cw")

-- ════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════
local function getChar()
    return LP.Character
end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getDist(a, b)
    return math.floor((a - b).Magnitude + 0.5)
end

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local curWS      = 16
local curJP      = 50
local flyOn      = false
local flySpeed   = 60
local flyBV      = nil
local flyBG      = nil
local flyConn    = nil
local noclipOn   = false
local noclipConn = nil
local espOn      = false
local espBills   = {}
local espConns   = {}
local afkConn    = nil
local antiKickOn = false
local slots      = {}
local PITCH_UP   =  0.3
local PITCH_DOWN = -0.3

-- Auto Farm state
local autoFarmConn   = nil
local autoFarmDelay  = 1
local lightningConn  = nil

-- ════════════════════════════════════════
--  RE-APPLY ON RESPAWN
-- ════════════════════════════════════════
LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    task.wait(0.5)
    hum.WalkSpeed    = curWS
    hum.JumpPower    = curJP
    hum.UseJumpPower = true
    if flyOn then
        task.wait(0.3)
        local root2 = char:FindFirstChild("HumanoidRootPart")
        if root2 then
            if flyBV then pcall(function() flyBV:Destroy() end) end
            if flyBG then pcall(function() flyBG:Destroy() end) end
            flyBV = Instance.new("BodyVelocity", root2)
            flyBV.Velocity = Vector3.new()
            flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBG = Instance.new("BodyGyro", root2)
            flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            flyBG.P = 1e4; flyBG.D = 100
            flyBG.CFrame = root2.CFrame
            hum.PlatformStand = true
        end
    end
end)

-- ════════════════════════════════════════
--  ① INFER PLAYER
-- ════════════════════════════════════════
local function infer_plr(pl_ref)
    if typeof(pl_ref) ~= "string" then return pl_ref end
    local to_pl, min = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local nv = math.huge
            local un = p.Name
            local dn = p.DisplayName
            if un:find("^" .. pl_ref) then
                nv = 1.0 * (#un - #pl_ref)
            elseif dn:find("^" .. pl_ref) then
                nv = 1.5 * (#dn - #pl_ref)
            elseif un:lower():find("^" .. pl_ref:lower()) then
                nv = 2.0 * (#un - #pl_ref)
            elseif dn:lower():find("^" .. pl_ref:lower()) then
                nv = 2.5 * (#dn - #pl_ref)
            end
            if nv < min then to_pl = p; min = nv end
        end
    end
    return to_pl
end

-- ════════════════════════════════════════
--  ② TELEPORT ke PLAYER
-- ════════════════════════════════════════
local function tpToPlayer(ref)
    if not ref or ref == "" then
        Library:Notification("❌", "Ketik nama dulu!", 2); return
    end
    local to_pl = infer_plr(ref)
    if not to_pl then
        Library:Notification("❌", "Player tidak ditemukan\nCoba huruf lain", 3); return
    end
    if not to_pl.Character then
        Library:Notification("❌", to_pl.Name .. " tidak ada karakter", 2); return
    end
    local hrp  = to_pl.Character:FindFirstChild("HumanoidRootPart")
    local trs  = to_pl.Character:FindFirstChild("Torso")
    local part = hrp or trs
    if not part then
        Library:Notification("❌", "Karakter " .. to_pl.Name .. " tidak valid", 2); return
    end
    local myChar = getChar()
    if myChar then
        myChar:PivotTo(part.CFrame * CFrame.new(0, 3, 0))
        Library:Notification("📍 TP", "→ " .. to_pl.Name, 2)
    end
end

local function tpToMouse()
    local mouse = LP:GetMouse()
    if mouse and mouse.Hit then
        local root = getRoot()
        if root then
            root.CFrame = mouse.Hit * CFrame.new(0, 3, 0)
            Library:Notification("📍 TP", "Ke posisi mouse", 2)
        end
    end
end

-- ════════════════════════════════════════
--  ③ RESPAWN CEPAT
-- ════════════════════════════════════════
local function quickRespawn()
    local root = getRoot()
    if not root then Library:Notification("❌", "Karakter tidak ada", 2); return end
    local savedCF = root.CFrame
    local savedWS = curWS
    local savedJP = curJP
    local c = getChar()
    if c then c:BreakJoints() end
    local conn
    conn = LP.CharacterAdded:Connect(function(newChar)
        conn:Disconnect()
        task.wait(0.8)
        local hrp2 = newChar:WaitForChild("HumanoidRootPart", 5)
        local hum2 = newChar:WaitForChild("Humanoid", 5)
        if hrp2 then hrp2.CFrame = savedCF end
        if hum2 then
            hum2.WalkSpeed    = savedWS
            hum2.JumpPower    = savedJP
            hum2.UseJumpPower = true
        end
        Library:Notification("✅ Respawn", "Kembali ke posisi semula", 2)
    end)
end

-- ════════════════════════════════════════
--  ④ FLY
-- ════════════════════════════════════════
local function startFly()
    local root = getRoot(); if not root then return end
    local hum  = getHum();  if not hum  then return end
    if flyBV   then pcall(function() flyBV:Destroy()      end) end
    if flyBG   then pcall(function() flyBG:Destroy()      end) end
    if flyConn then pcall(function() flyConn:Disconnect() end) end
    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Velocity = Vector3.new()
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 1e4; flyBG.D = 100
    flyBG.CFrame = root.CFrame
    hum.PlatformStand = true
    flyConn = RunService.Heartbeat:Connect(function()
        local root2 = getRoot(); if not root2 or not flyBV then return end
        local hum2  = getHum();  if not hum2 then return end
        local cam    = Workspace.CurrentCamera
        local camCF  = cam.CFrame
        local camFwd = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z)
        local camRgt = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
        if camFwd.Magnitude > 0 then camFwd = camFwd.Unit end
        if camRgt.Magnitude > 0 then camRgt = camRgt.Unit end
        local md = hum2.MoveDirection
        local horizontal = Vector3.new()
        if md.Magnitude > 0.05 then
            local fwdAmt   = md:Dot(camFwd)
            local rightAmt = md:Dot(camRgt)
            horizontal = camFwd * fwdAmt + camRgt * rightAmt
            if horizontal.Magnitude > 1 then horizontal = horizontal.Unit end
        end
        local pitchY   = camCF.LookVector.Y
        local vertical = Vector3.new()
        if pitchY > PITCH_UP then
            local str = math.min((pitchY - PITCH_UP) / (1 - PITCH_UP), 1)
            vertical  = Vector3.new(0, str, 0)
        elseif pitchY < PITCH_DOWN then
            local str = math.min((-pitchY + PITCH_DOWN) / (1 + PITCH_DOWN), 1)
            vertical  = Vector3.new(0, -str, 0)
        end
        local finalDir = horizontal + vertical
        if finalDir.Magnitude > 0 then
            local norm = finalDir.Magnitude > 1 and finalDir.Unit or finalDir
            flyBV.Velocity = norm * flySpeed
            if horizontal.Magnitude > 0.05 then
                flyBG.CFrame = CFrame.new(Vector3.new(), horizontal)
            end
        else
            flyBV.Velocity = Vector3.new()
        end
        hum2.PlatformStand = true
    end)
end

local function stopFly()
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn = nil end
    if flyBV   then pcall(function() flyBV:Destroy()      end); flyBV   = nil end
    if flyBG   then pcall(function() flyBG:Destroy()      end); flyBG   = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

-- ════════════════════════════════════════
--  ⑤ NOCLIP
-- ════════════════════════════════════════
local function setNoclip(state)
    noclipOn = state
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local c = getChar(); if not c then return end
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local c = getChar()
        if c then
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

-- ════════════════════════════════════════
--  ⑥ ESP
-- ════════════════════════════════════════
local function clearESP()
    for _, b in ipairs(espBills) do pcall(function() b:Destroy()    end) end
    for _, c in ipairs(espConns) do pcall(function() c:Disconnect() end) end
    espBills = {}; espConns = {}
end

local function getArea(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return "?" end
    local pos = root.Position
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("room") or n:find("area") or n:find("zone")
            or n:find("vip")  or n:find("priv") or n:find("salon") then
                if (v.Position - pos).Magnitude < 25 then return v.Name end
            end
        end
    end
    return "Lobby"
end

local function makeESP(player)
    if player == LP then return end
    local function onChar(char)
        if not espOn then return end
        task.wait(0.5)
        local head = char:FindFirstChild("Head")
        if not head then return end
        local bill = Instance.new("BillboardGui")
        bill.Size        = UDim2.new(0, 180, 0, 50)
        bill.StudsOffset = Vector3.new(0, 3, 0)
        bill.AlwaysOnTop = true
        bill.Adornee     = head
        bill.Parent      = char
        local bg = Instance.new("Frame", bill)
        bg.Size                   = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency = 0.45
        bg.BorderSizePixel        = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", bg)
        lbl.Size                   = UDim2.new(1,-6,1,-4)
        lbl.Position               = UDim2.new(0,3,0,2)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3             = Color3.fromRGB(255, 230, 80)
        lbl.TextStrokeTransparency = 0.3
        lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        lbl.TextScaled             = true
        lbl.Font                   = Enum.Font.GothamBold
        lbl.TextXAlignment         = Enum.TextXAlignment.Center
        local upd = RunService.Heartbeat:Connect(function()
            if not bill or not bill.Parent then return end
            local myRoot = getRoot()
            local d = myRoot and getDist(head.Position, myRoot.Position) or 0
            lbl.Text = string.format("👤 %s\n📍 %dm  |  %s",
                player.Name, d, getArea(char))
        end)
        table.insert(espConns, upd)
        table.insert(espBills, bill)
    end
    if player.Character then onChar(player.Character) end
    table.insert(espConns, player.CharacterAdded:Connect(onChar))
end

local function toggleESP(state)
    espOn = state; clearESP()
    if state then
        for _, p in pairs(Players:GetPlayers()) do makeESP(p) end
        table.insert(espConns, Players.PlayerAdded:Connect(makeESP))
    end
    Library:Notification("👁 ESP", state and "ON" or "OFF", 2)
end

-- ════════════════════════════════════════
--  ⑦ PROTECTION
-- ════════════════════════════════════════
local function startAntiAFK()
    if afkConn then return end
    afkConn = LP.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
local function stopAntiAFK()
    if afkConn then afkConn:Disconnect(); afkConn = nil end
end
local function startAntiKick()
    if antiKickOn then return end
    antiKickOn = true
    task.spawn(function()
        while antiKickOn do
            pcall(function()
                local hum = getHum()
                if hum and hum.Health > 0 and hum.Health < hum.MaxHealth * 0.1 then
                    hum.Health = hum.MaxHealth
                end
            end)
            task.wait(0.5)
        end
    end)
end
local function stopAntiKick() antiKickOn = false end

-- ════════════════════════════════════════
--  BUILD UI — TAB TELEPORT
-- ════════════════════════════════════════
local TPage  = TabTP:Page("Teleport", "map-pin")
local TLeft  = TPage:Section("📍 Teleport ke Player", "Left")
local TRight = TPage:Section("💾 Slot Posisi", "Right")

TLeft:Button("👥 Lihat Player Online", "Tampilkan semua player di server",
    function()
        local list, n = "", 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                local root2  = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = getRoot()
                local d = (root2 and myRoot) and getDist(root2.Position, myRoot.Position) or "?"
                n    = n + 1
                list = list .. string.format("• %s (%s) — %sm\n", p.Name, p.DisplayName, tostring(d))
            end
        end
        Library:Notification("👥 " .. n .. " Player Online", n > 0 and list or "Tidak ada player lain", 10)
    end)

TLeft:Paragraph("Cara Pakai",
    "1. Lihat Player Online\n"..
    "   → catat nama/prefix\n\n"..
    "2. Ketik 1-2 huruf\n"..
    "   pertama nama player\n\n"..
    "3. Tekan Teleport\n"..
    "   → langsung TP!\n\n"..
    "Contoh:\n"..
    "Ada player 'XKIDTest'\n"..
    "Ketik 'XK' → langsung\n"..
    "teleport ke XKIDTest")

local tpInput = ""
TLeft:TextBox("Nama / Prefix Player", "TPInput", "",
    function(v) tpInput = v end,
    "Ketik 1-2 huruf pertama nama")

TLeft:Button("📍 Teleport ke Player", "Cari & TP ke player",
    function() tpToPlayer(tpInput) end)

TLeft:Button("🖱 Teleport ke Mouse", "TP ke posisi tap layar",
    function() tpToMouse() end)

TLeft:Button("💀 Respawn Cepat", "Mati & spawn di posisi sama",
    function() quickRespawn() end)

TRight:Label("💾 Save & Load Posisi")
for i = 1, 5 do
    local idx = i
    TRight:Button("💾 Save Slot " .. idx, "Simpan posisi ke slot " .. idx,
        function()
            local root = getRoot()
            if not root then Library:Notification("❌", "Karakter tidak ada", 2); return end
            slots[idx] = root.CFrame
            local p = root.Position
            Library:Notification("💾 Slot " .. idx,
                string.format("X=%.0f  Y=%.0f  Z=%.0f", p.X, p.Y, p.Z), 3)
        end)
    TRight:Button("🚀 Load Slot " .. idx, "TP ke posisi slot " .. idx,
        function()
            if not slots[idx] then Library:Notification("❌", "Slot "..idx.." kosong", 2); return end
            local root = getRoot()
            if root then
                root.CFrame = slots[idx]
                local p = slots[idx].Position
                Library:Notification("📍 Slot " .. idx,
                    string.format("X=%.0f  Y=%.0f  Z=%.0f", p.X, p.Y, p.Z), 3)
            end
        end)
end

-- ════════════════════════════════════════
--  BUILD UI — TAB FLY
-- ════════════════════════════════════════
local FPage = TabFly:Page("Fly & NoClip", "rocket")
local FL    = FPage:Section("🚀 Fly", "Left")
local FR    = FPage:Section("🚶 NoClip", "Right")

FL:Toggle("Fly Mode", "FlyToggle", false, "Aktifkan terbang",
    function(v)
        flyOn = v
        if v then startFly() else stopFly() end
        Library:Notification("🚀 Fly", v and "ON" or "OFF", 2)
    end)

FL:Slider("Kecepatan", "FlySpeedSlider", 5, 300, 60,
    function(v) flySpeed = v end, "Kecepatan terbang (default 60)")

FL:Slider("Sensitivitas Naik/Turun", "PitchSlider", 1, 9, 3,
    function(v) PITCH_UP = v * 0.1; PITCH_DOWN = -v * 0.1 end,
    "1=Sangat sensitif · 9=Perlu miring banyak")

FL:Paragraph("🎮 Cara Pakai",
    "Toggle Fly → ON\n\n"..
    "GERAK:\nJoystick kiri seperti jalan\n\n"..
    "NAIK:\nSlide kamera ke atas\n\n"..
    "TURUN:\nSlide kamera ke bawah\n\n"..
    "DIAM MELAYANG:\nLepas joystick + kamera lurus")

FR:Toggle("NoClip", "NoclipToggle", false, "Tembus semua dinding",
    function(v)
        setNoclip(v)
        Library:Notification("🚶 NoClip", v and "ON — Tembus dinding" or "OFF", 2)
    end)

FR:Paragraph("Fly + NoClip",
    "✅ Fly ON\n✅ NoClip ON\n\n"..
    "→ Masuk private room\n"..
    "→ Tembus semua tembok\n"..
    "→ Akses area terlarang")

-- ════════════════════════════════════════
--  BUILD UI — TAB ESP
-- ════════════════════════════════════════
local EPage = TabESP:Page("ESP Player", "eye")
local EL    = EPage:Section("👁 Controls", "Left")
local ER    = EPage:Section("ℹ Info", "Right")

EL:Toggle("ESP Player", "ESPToggle", false, "Lihat semua player tembus dinding",
    function(v) toggleESP(v) end)

EL:Button("🔄 Refresh ESP", "Perbarui ESP",
    function()
        if espOn then
            clearESP(); task.wait(0.2)
            for _, p in pairs(Players:GetPlayers()) do makeESP(p) end
            Library:Notification("👁 ESP", "Refreshed", 2)
        end
    end)

ER:Paragraph("Info ESP",
    "Per player tampil:\n• Nama\n• Jarak (meter)\n• Area / room\n\nTembus semua dinding")

-- ════════════════════════════════════════
--  BUILD UI — TAB SPEED
-- ════════════════════════════════════════
local SPage = TabSpeed:Page("Speed & Jump", "zap")
local SL    = SPage:Section("⚡ Speed", "Left")
local SR    = SPage:Section("🦘 Jump", "Right")

SL:Slider("WalkSpeed", "WSSlider", 1, 500, 16,
    function(v)
        curWS = v
        local hum = getHum()
        if hum then hum.WalkSpeed = v end
    end, "Default 16")

SL:Button("🔁 Reset Speed", "Kembalikan ke 16",
    function()
        curWS = 16
        local hum = getHum()
        if hum then hum.WalkSpeed = 16 end
        Library:Notification("Speed", "Reset → 16", 2)
    end)

SR:Slider("JumpPower", "JPSlider", 1, 500, 50,
    function(v)
        curJP = v
        local hum = getHum()
        if hum then hum.JumpPower = v; hum.UseJumpPower = true end
    end, "Default 50")

SR:Button("🔁 Reset Jump", "Kembalikan ke 50",
    function()
        curJP = 50
        local hum = getHum()
        if hum then hum.JumpPower = 50; hum.UseJumpPower = true end
        Library:Notification("Jump", "Reset → 50", 2)
    end)

SR:Toggle("Infinite Jump", "InfJumpToggle", false, "Lompat terus di udara",
    function(v)
        if v then
            _G.xkid_ij = UIS.JumpRequest:Connect(function()
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if _G.xkid_ij then _G.xkid_ij:Disconnect(); _G.xkid_ij = nil end
        end
        Library:Notification("Inf Jump", v and "ON" or "OFF", 2)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB PROTECTION
-- ════════════════════════════════════════
local PPage = TabProt:Page("Protection", "shield")
local PL    = PPage:Section("🛡 Controls", "Left")
local PR    = PPage:Section("ℹ Info", "Right")

PL:Toggle("Anti AFK", "AntiAFKToggle", false, "Cegah disconnect otomatis",
    function(v)
        if v then startAntiAFK() else stopAntiAFK() end
        Library:Notification("Anti AFK", v and "ON" or "OFF", 2)
    end)

PL:Toggle("Anti Kick", "AntiKickToggle", false, "Cegah dikeluarkan dari server",
    function(v)
        if v then startAntiKick() else stopAntiKick() end
        Library:Notification("Anti Kick", v and "ON" or "OFF", 2)
    end)

PL:Button("🔄 Rejoin Server", "Koneksi ulang",
    function()
        Library:Notification("🔄 Rejoin", "Menghubungkan ulang...", 3)
        task.wait(1)
        TpService:Teleport(game.PlaceId, LP)
    end)

PL:Button("📍 Posisi Saya", "Lihat koordinat sekarang",
    function()
        local root = getRoot()
        if root then
            local p = root.Position
            Library:Notification("📍 Posisi",
                string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 6)
        end
    end)

PR:Paragraph("Info",
    "Anti AFK:\nCegah auto-disconnect\n\n"..
    "Anti Kick:\nJaga HP dari kick\n\n"..
    "Rejoin:\nKoneksi ulang cepat")

-- ════════════════════════════════════════
--  BUILD UI — TAB FARMING 🌱
-- ════════════════════════════════════════
local FarmPage = TabFarm:Page("Farming", "leaf")
local FarmL    = FarmPage:Section("🌾 Auto Farm", "Left")
local FarmR    = FarmPage:Section("🌱 Manual", "Right")

FarmL:Toggle("Auto Farm", "AutoFarmToggle", false,
    "Loop PlantCrop + AutoHarvest + LahanUpdate",
    function(v)
        if autoFarmConn then autoFarmConn:Disconnect(); autoFarmConn = nil end
        if v then
            autoFarmConn = RunService.Heartbeat:Connect(function()
                task.wait(autoFarmDelay)
                local _r=getTut(); if _r then pcall(function() _r.PlantCrop:FireServer() end) end
                local _r=getTut(); if _r then pcall(function() _r.ToggleAutoHarvest:FireServer() end) end
                local _r=getTut(); if _r then pcall(function() _r.LahanUpdate:FireServer() end) end
            end)
        end
        Library:Notification("🌾 Auto Farm", v and "ON" or "OFF", 2)
    end)

FarmL:Slider("Delay Auto Farm", "AutoFarmDelay", 1, 10, 1,
    function(v) autoFarmDelay = v end, "Detik antar loop (default 1)")

FarmL:Toggle("⚡ Penangkal Petir", "LightningToggle", false,
    "Auto WeatherSync tiap 2 detik",
    function(v)
        if lightningConn then lightningConn:Disconnect(); lightningConn = nil end
        if v then
            lightningConn = RunService.Heartbeat:Connect(function()
                task.wait(2)
                local _r=getTut(); if _r then pcall(function() _r.WeatherSync:FireServer() end) end
                local _r=getTut(); if _r then pcall(function() _r.HygieneSync:FireServer() end) end
            end)
        end
        Library:Notification("⚡ Penangkal Petir", v and "ON" or "OFF", 2)
    end)

FarmR:Button("🌱 PlantCrop", "Tanam tanaman",
    function()
        local _r=getTut(); if _r then pcall(function() _r.PlantCrop:FireServer() end) end
        Library:Notification("🌱", "PlantCrop dikirim!", 2)
    end)

FarmR:Button("🔄 ToggleAutoHarvest", "Aktifkan auto harvest",
    function()
        local _r=getTut(); if _r then pcall(function() _r.ToggleAutoHarvest:FireServer() end) end
        Library:Notification("🔄", "ToggleAutoHarvest dikirim!", 2)
    end)

FarmR:Button("🌾 GetBibit", "Ambil bibit",
    function()
        local _r=getTut(); if _r then pcall(function() _r.GetBibit:FireServer() end) end
        Library:Notification("🌾", "GetBibit dikirim!", 2)
    end)

FarmR:Button("🗺 LahanUpdate", "Update kondisi lahan",
    function()
        local _r=getTut(); if _r then pcall(function() _r.LahanUpdate:FireServer() end) end
        Library:Notification("🗺", "LahanUpdate dikirim!", 2)
    end)

FarmR:Button("📦 RequestStorage", "Buka storage",
    function()
        local _r=getTut(); if _r then pcall(function() _r.RequestStorage:InvokeServer() end) end
        Library:Notification("📦", "RequestStorage dikirim!", 2)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB SHOP 🛒
-- ════════════════════════════════════════
local ShopPage = TabShop:Page("Shop & Economy", "shopping-cart")
local ShopL    = ShopPage:Section("🛒 Shop", "Left")
local ShopR    = ShopPage:Section("🎁 Gift & Donasi", "Right")

ShopL:Button("🛒 Request Shop", "Buka toko",
    function()
        local _r=getTut(); if _r then pcall(function() _r.RequestShop:InvokeServer() end) end
        Library:Notification("🛒", "RequestShop dikirim!", 2)
    end)

ShopL:Button("🔧 Request Tool Shop", "Buka toko alat",
    function()
        local _r=getTut(); if _r then pcall(function() _r.RequestToolShop:InvokeServer() end) end
        Library:Notification("🔧", "RequestToolShop dikirim!", 2)
    end)

ShopL:Button("🔁 Refresh Shop", "Refresh isi toko",
    function()
        local _r=getTut(); if _r then pcall(function() _r.RefreshShop:FireServer() end) end
        Library:Notification("🔁", "RefreshShop dikirim!", 2)
    end)

ShopL:Button("💰 Request Sell", "Jual item",
    function()
        local _r=getTut(); if _r then pcall(function() _r.RequestSell:InvokeServer() end) end
        Library:Notification("💰", "RequestSell dikirim!", 2)
    end)

ShopL:Button("🎮 Request Gamepass", "Buka gamepass",
    function()
        local _r=getTut(); if _r then pcall(function() _r.RequestGamepass:InvokeServer() end) end
        Library:Notification("🎮", "RequestGamepass dikirim!", 2)
    end)

ShopR:Button("🎁 Request Gift", "Request hadiah",
    function()
        local _r=getTut(); if _r then pcall(function() _r.RequestGift:InvokeServer() end) end
        Library:Notification("🎁", "RequestGift dikirim!", 2)
    end)

ShopR:Button("✅ Gift Purchase Done", "Konfirmasi pembelian hadiah",
    function()
        local _r=getTut(); if _r then pcall(function() _r.GiftPurchaseDone:FireServer() end) end
        Library:Notification("✅", "GiftPurchaseDone dikirim!", 2)
    end)

ShopR:Button("🔔 Gift Notify", "Kirim notifikasi hadiah",
    function()
        local _r=getTut(); if _r then pcall(function() _r.GiftNotify:FireServer() end) end
        Library:Notification("🔔", "GiftNotify dikirim!", 2)
    end)

ShopR:Button("💸 Request Donation", "Buka donasi",
    function()
        local _r=getTut(); if _r then pcall(function() _r.RequestDonation:InvokeServer() end) end
        Library:Notification("💸", "RequestDonation dikirim!", 2)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB WORLD 🌍
-- ════════════════════════════════════════
local WorldPage = TabWorld:Page("World & Cuaca", "globe")
local WorldL    = WorldPage:Section("🌤 Cuaca", "Left")
local WorldR    = WorldPage:Section("🌍 Lighting", "Right")

WorldL:Button("🌧 Summon Rain", "Panggil hujan",
    function()
        local _r=getTut(); if _r then pcall(function() _r.SummonRain:FireServer() end) end
        Library:Notification("🌧", "SummonRain dikirim!", 2)
    end)

WorldL:Button("🌤 Weather Sync", "Sinkronisasi cuaca",
    function()
        local _r=getTut(); if _r then pcall(function() _r.WeatherSync:FireServer() end) end
        Library:Notification("🌤", "WeatherSync dikirim!", 2)
    end)

WorldL:Button("🌙 Phase Changed", "Ganti fase siang/malam",
    function()
        local _r=getDN(); if _r then pcall(function() _r.PhaseChanged:FireServer() end) end
        Library:Notification("🌙", "PhaseChanged dikirim!", 2)
    end)

WorldL:Button("😴 Sleep Notify", "Notifikasi tidur",
    function()
        local _r=getDN(); if _r then pcall(function() _r.SleepNotify:FireServer() end) end
        Library:Notification("😴", "SleepNotify dikirim!", 2)
    end)

WorldR:Toggle("Fullbright", "FullbrightToggle", false, "Terang penuh",
    function(v)
        pcall(function()
            Lighting.Ambient        = v and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,70,70)
            Lighting.OutdoorAmbient = v and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,140,140)
            Lighting.Brightness     = v and 10 or 2
        end)
        Library:Notification("💡 Fullbright", v and "ON" or "OFF", 2)
    end)

WorldR:Slider("Time of Day", "TimeSlider", 0, 24, 14,
    function(v)
        pcall(function() Lighting.ClockTime = v end)
    end, "Jam 0-24")

WorldR:Slider("Gravity", "GravitySlider", 0, 400, 196,
    function(v)
        pcall(function() workspace.Gravity = v end)
    end, "Default 196")

-- ════════════════════════════════════════
--  BUILD UI — TAB CARRY 🤝
-- ════════════════════════════════════════
local CarryPage = TabCarry:Page("Carry System", "users")
local CarryL    = CarryPage:Section("🤝 Carry", "Left")
local CarryR2   = CarryPage:Section("📊 Status", "Right")

CarryL:Button("📩 Request Carry", "Minta digendong",
    function()
        local _r=getCarry(); if _r then pcall(function() _r.RequestCarry:FireServer() end) end
        Library:Notification("📩", "RequestCarry dikirim!", 2)
    end)

CarryL:Button("💬 Prompt Carry", "Prompt carry ke player lain",
    function()
        local _r=getCarry(); if _r then pcall(function() _r.PromptCarry:FireServer() end) end
        Library:Notification("💬", "PromptCarry dikirim!", 2)
    end)

CarryL:Button("✅ Respond to Carry", "Jawab request carry",
    function()
        local _r=getCarry(); if _r then pcall(function() _r.RespondToCarry:FireServer() end) end
        Library:Notification("✅", "RespondToCarry dikirim!", 2)
    end)

CarryL:Button("🛑 Stop Carry", "Berhenti carry",
    function()
        local _r=getCarry(); if _r then pcall(function() _r.StopCarry:FireServer() end) end
        Library:Notification("🛑", "StopCarry dikirim!", 2)
    end)

CarryR2:Button("📊 Update Status", "Update status carry",
    function()
        local _r=getCarry(); if _r then pcall(function() _r.UpdateStatus:FireServer() end) end
        Library:Notification("📊", "UpdateStatus dikirim!", 2)
    end)

CarryR2:Button("🔔 Carry Notify", "Kirim notifikasi carry",
    function()
        local _r=getCarry(); if _r then pcall(function() _r.Notify:FireServer() end) end
        Library:Notification("🔔", "Carry Notify dikirim!", 2)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB BOAT ⛵
-- ════════════════════════════════════════
local BoatPage = TabBoat:Page("Boat Control", "anchor")
local BoatL    = BoatPage:Section("⛵ Boat", "Left")
local BoatR2   = BoatPage:Section("🔧 Misc", "Right")

BoatL:Button("🚢 Boat Control", "Kendalikan perahu",
    function()
        local _r=getBoat(); if _r then pcall(function() _r.BoatControl:FireServer() end) end
        Library:Notification("🚢", "BoatControl dikirim!", 2)
    end)

BoatL:Button("📯 Horn (Klakson)", "Bunyikan klakson perahu",
    function()
        local _r=getBoat(); if _r then pcall(function() _r.HornRemote:FireServer() end) end
        Library:Notification("📯", "HornRemote dikirim!", 2)
    end)

BoatL:Button("👥 Assign Boat Group", "Assign grup perahu",
    function()
        local _r=RS:FindFirstChild("AssignBoatGroup"); if _r then pcall(function() _r:FireServer() end) end
        Library:Notification("👥", "AssignBoatGroup dikirim!", 2)
    end)

BoatR2:Button("🎮 Kite Event", "Event layang-layang",
    function()
        local _r=getTut(); if _r then pcall(function() _r.KiteEvent:FireServer() end) end
        Library:Notification("🎮", "KiteEvent dikirim!", 2)
    end)

BoatR2:Button("🚲 Bike Remote", "Kendali sepeda",
    function()
        local _r=getTut(); if _r then pcall(function() _r.BikeRemote:FireServer() end) end
        Library:Notification("🚲", "BikeRemote dikirim!", 2)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB SYNC 🔄
-- ════════════════════════════════════════
local SyncPage = TabSync:Page("Sync & Data", "refresh-cw")
local SyncL    = SyncPage:Section("🔄 Sync", "Left")
local SyncR2   = SyncPage:Section("📋 Tutorial", "Right")

SyncL:Button("🔄 Sync", "Mulai sinkronisasi",
    function()
        local _r=getSync(); if _r then pcall(function() _r.Sync:FireServer() end) end
        Library:Notification("🔄", "Sync dikirim!", 2)
    end)

SyncL:Button("X UnSync", "Stop sinkronisasi",
    function()
        local _r=getSync(); if _r then pcall(function() _r.UnSync:FireServer() end) end
        Library:Notification("X", "UnSync dikirim!", 2)
    end)

SyncL:Button("📡 Sync Data", "Sinkronisasi data pemain",
    function()
        local _r=getTut(); if _r then pcall(function() _r.SyncData:InvokeServer() end) end
        Library:Notification("📡", "SyncData dikirim!", 2)
    end)

SyncL:Button("🔃 Refresh Event", "Refresh event game",
    function()
        local _r=RS:FindFirstChild("RefreshEvent"); if _r then pcall(function() _r:FireServer() end) end
        Library:Notification("🔃", "RefreshEvent dikirim!", 2)
    end)

SyncL:Button("<<>> Request Transfer", "Transfer data/item",
    function()
        local _r=getTut(); if _r then pcall(function() _r.RequestTransfer:InvokeServer() end) end
        Library:Notification("<<>>", "RequestTransfer dikirim!", 2)
    end)

SyncL:Button("🪟 Transfer Prompt Open", "Buka prompt transfer",
    function()
        local _r=getTut(); if _r then pcall(function() _r.TransferPromptOpen:FireServer() end) end
        Library:Notification("🪟", "TransferPromptOpen dikirim!", 2)
    end)

SyncL:Button("✅ Confirm Action", "Konfirmasi aksi",
    function()
        local _r=getTut(); if _r then pcall(function() _r.ConfirmAction:InvokeServer() end) end
        Library:Notification("✅", "ConfirmAction dikirim!", 2)
    end)

SyncR2:Button("⏩ Skip Tutorial", "Lewati tutorial",
    function()
        local _r=getTut(); if _r then pcall(function() _r.SkipTutorial:FireServer() end) end
        Library:Notification("⏩", "SkipTutorial dikirim!", 2)
    end)

SyncR2:Button("📈 Update Step", "Update step tutorial",
    function()
        local _r=getTut(); if _r then pcall(function() _r.UpdateStep:FireServer() end) end
        Library:Notification("📈", "UpdateStep dikirim!", 2)
    end)

SyncR2:Button("[UP] Update Level", "Update level pemain",
    function()
        local _r=getTut(); if _r then pcall(function() _r.UpdateLevel:FireServer() end) end
        Library:Notification("[UP]", "UpdateLevel dikirim!", 2)
    end)

SyncR2:Button("🔔 Storage Notify", "Notifikasi storage",
    function()
        local _r=getTut(); if _r then pcall(function() _r.StorageNotify:FireServer() end) end
        Library:Notification("🔔", "StorageNotify dikirim!", 2)
    end)

SyncR2:Button("🚿 Hygiene Sync", "Sinkronisasi kebersihan",
    function()
        local _r=getTut(); if _r then pcall(function() _r.HygieneSync:FireServer() end) end
        Library:Notification("🚿", "HygieneSync dikirim!", 2)
    end)

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("🌟 XKID.HUB v5.0",
    "Loaded! Farm · Shop · World · Carry · Boat · Sync", 5)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════╗")
print("║   🌟  XKID.HUB  v5.0  Mobile       ║")
print("║   TP · Fly · ESP · Speed · Prot     ║")
print("║   Farm · Shop · World · Carry       ║")
print("║   Boat · Sync                       ║")
print("║   Player: " .. LP.Name)
print("╚══════════════════════════════════════╝")
