--[[
  ╔══════════════════════════════════════════════════════╗
  ║          🌟  X K I D . H U B  v4.0  🌟             ║
  ║          Aurora UI  ✦  Mobile Optimized             ║
  ╚══════════════════════════════════════════════════════╝
  Fly    : Joystick = maju/mundur/kiri/kanan
           Kamera atas = naik · Kamera bawah = turun
  Teleport: Tabel player langsung ada tombol TP
  Respawn Cepat · ESP · Speed · Protection
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
local LP          = Players.LocalPlayer

-- ════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════
local Win = Library:Window("🌟 XKID.HUB", "star", "v4.0 Mobile", false)

-- ════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════
Win:TabSection("MAIN")
local TabTP    = Win:Tab("Teleport",   "map-pin")
local TabFly   = Win:Tab("Fly",        "rocket")
local TabESP   = Win:Tab("ESP",        "eye")
local TabSpeed = Win:Tab("Speed",      "zap")
local TabProt  = Win:Tab("Protection", "shield")

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

-- Pitch threshold: seberapa miring kamera untuk naik/turun
-- 0.25 = cukup sedikit lihat atas/bawah sudah naik/turun
local PITCH_UP   =  0.25
local PITCH_DOWN = -0.25

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
    -- Re-init fly jika masih aktif
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
--  ① FLY — BodyVelocity
--
--  Joystick kiri  → maju/mundur/kiri/kanan
--                   (mengikuti arah kamera horizontal)
--  Slide kamera ke ATAS  → karakter NAIK
--  Slide kamera ke BAWAH → karakter TURUN
--  Lepas semua → melayang diam
-- ════════════════════════════════════════
local function startFly()
    local root = getRoot(); if not root then return end
    local hum  = getHum();  if not hum  then return end

    -- Cleanup
    if flyBV   then pcall(function() flyBV:Destroy()      end) end
    if flyBG   then pcall(function() flyBG:Destroy()      end) end
    if flyConn then pcall(function() flyConn:Disconnect() end) end

    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Velocity = Vector3.new()
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)

    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 1e4
    flyBG.D = 100
    flyBG.CFrame = root.CFrame

    hum.PlatformStand = true

    flyConn = RunService.Heartbeat:Connect(function()
        local root2 = getRoot(); if not root2 or not flyBV then return end
        local hum2  = getHum();  if not hum2  then return end

        local cam   = Workspace.CurrentCamera
        local camCF = cam.CFrame

        -- ── HORIZONTAL dari MoveDirection (joystick) ──
        -- MoveDirection sudah di world space, tapi kita
        -- proyeksikan ulang ke arah kamera agar maju
        -- selalu ke arah yang dilihat kamera
        local md = hum2.MoveDirection

        local camFwd   = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z)
        local camRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)

        -- Normalisasi sumbu kamera
        if camFwd.Magnitude   > 0 then camFwd   = camFwd.Unit   end
        if camRight.Magnitude > 0 then camRight = camRight.Unit end

        local horizontal = Vector3.new()
        if md.Magnitude > 0.05 then
            -- Proyeksikan MoveDirection ke sumbu kamera
            -- md sudah dalam world space dari Roblox
            -- Kita ambil komponen relatif kamera
            local fwdAmt   = md:Dot(camFwd)
            local rightAmt = md:Dot(camRight)
            horizontal = camFwd * fwdAmt + camRight * rightAmt
            if horizontal.Magnitude > 1 then
                horizontal = horizontal.Unit
            end
        end

        -- ── VERTICAL dari pitch kamera ──
        -- LookVector.Y:
        --   positif (+)  = kamera lihat ke atas  → naik
        --   negatif (-)  = kamera lihat ke bawah → turun
        local pitchY   = camCF.LookVector.Y
        local vertical = Vector3.new()

        if pitchY > PITCH_UP then
            -- Makin tinggi lihat ke atas, makin cepat naik
            local str = math.min(
                (pitchY - PITCH_UP) / (1 - PITCH_UP), 1)
            vertical = Vector3.new(0, str, 0)

        elseif pitchY < PITCH_DOWN then
            -- Makin rendah lihat ke bawah, makin cepat turun
            local str = math.min(
                (-pitchY - math.abs(PITCH_DOWN)) / (1 - math.abs(PITCH_DOWN)), 1)
            vertical = Vector3.new(0, -str, 0)
        end

        -- ── Gabungkan horizontal + vertical ──
        local finalDir = horizontal + vertical

        if finalDir.Magnitude > 0 then
            local normDir = finalDir.Magnitude > 1
                and finalDir.Unit or finalDir
            flyBV.Velocity = normDir * flySpeed

            -- Rotasi karakter ikut arah horizontal
            if horizontal.Magnitude > 0.05 then
                flyBG.CFrame = CFrame.new(Vector3.new(), horizontal)
            end
        else
            -- Diam melayang — velocity nol, tidak jatuh
            flyBV.Velocity = Vector3.new()
        end

        -- Selalu paksa PlatformStand agar tidak jatuh
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
--  ② NOCLIP
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
--  ③ ESP
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
                if (v.Position - pos).Magnitude < 25 then
                    return v.Name
                end
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
--  ④ TELEPORT
-- ════════════════════════════════════════
local function tpToPlayerByName(name)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Name == name then
            if p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local root = getRoot()
                    if root then
                        root.CFrame = hrp.CFrame * CFrame.new(0, 3, 0)
                        Library:Notification("📍 TP", "→ "..name, 2)
                        return
                    end
                end
            end
            Library:Notification("❌", name.." tidak ada karakter", 2)
            return
        end
    end
    Library:Notification("❌", "Player tidak ditemukan", 2)
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
--  ⑤ RESPAWN CEPAT
-- ════════════════════════════════════════
local function quickRespawn()
    local root = getRoot()
    if not root then
        Library:Notification("❌", "Karakter tidak ada", 2); return
    end
    local savedCF = root.CFrame
    local savedWS = curWS
    local savedJP = curJP
    local c = getChar()
    if c then c:BreakJoints() end
    local conn
    conn = LP.CharacterAdded:Connect(function(newChar)
        conn:Disconnect()
        task.wait(0.8)
        local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
        local hum = newChar:WaitForChild("Humanoid", 5)
        if hrp then hrp.CFrame = savedCF end
        if hum then
            hum.WalkSpeed    = savedWS
            hum.JumpPower    = savedJP
            hum.UseJumpPower = true
        end
        Library:Notification("✅ Respawn", "Kembali ke posisi semula", 2)
    end)
end

-- ════════════════════════════════════════
--  ⑥ PROTECTION
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
--  Tabel player: 1 page per player
--  Di-generate saat tombol Scan ditekan
-- ════════════════════════════════════════

-- Page utama Teleport (tombol Scan + Slot)
local TPageMain  = TabTP:Page("Teleport", "map-pin")
local TMainLeft  = TPageMain:Section("👥 Scan Player", "Left")
local TMainRight = TPageMain:Section("📍 Slot & Lainnya", "Right")

-- Tabel menyimpan nama player hasil scan
local scannedPlayers = {}

TMainLeft:Button("🔍 SCAN PLAYER", "Cari semua player online sekarang",
    function()
        scannedPlayers = {}
        local count = 0
        local notifText = ""

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                count = count + 1
                local root2  = p.Character
                    and p.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = getRoot()
                local d = (root2 and myRoot)
                    and getDist(root2.Position, myRoot.Position)
                    or  999
                table.insert(scannedPlayers, {
                    name = p.Name,
                    disp = p.DisplayName,
                    dist = d,
                })
                notifText = notifText
                    ..string.format("[%d] %s — %dm\n", count, p.Name, d)
            end
        end

        if count == 0 then
            Library:Notification("👥 Scan", "Tidak ada player lain", 3)
            return
        end

        -- Sort berdasarkan jarak terdekat
        table.sort(scannedPlayers, function(a, b)
            return a.dist < b.dist
        end)

        -- Rebuild notif setelah sort
        notifText = ""
        for i, pl in ipairs(scannedPlayers) do
            notifText = notifText
                ..string.format("[%d] %s — %dm\n", i, pl.name, pl.dist)
        end

        Library:Notification(
            "✅ " .. count .. " Player Ditemukan",
            notifText .. "\n📋 Buka tab [1]~["..count.."] di bawah",
            10)
    end)

TMainLeft:Paragraph("Cara Pakai",
    "1. Tekan SCAN PLAYER\n"..
    "2. Lihat notifikasi —\n"..
    "   nama + jarak muncul\n"..
    "3. Buka tab player di\n"..
    "   bagian bawah tab ini\n"..
    "4. Tekan TP di tab player")

TMainLeft:Button("🖱 TP ke Mouse", "Teleport ke posisi tap layar",
    function() tpToMouse() end)

TMainLeft:Button("💀 Respawn Cepat", "Mati & spawn di posisi sama",
    function() quickRespawn() end)

-- Save / Load slot posisi
TMainRight:Label("💾 Save & Load Posisi")
for i = 1, 5 do
    local idx = i
    TMainRight:Button("💾 Save Slot " .. idx, "Simpan posisi ke slot " .. idx,
        function()
            local root = getRoot()
            if not root then
                Library:Notification("❌", "Karakter tidak ada", 2); return
            end
            slots[idx] = root.CFrame
            local p = root.Position
            Library:Notification("💾 Slot " .. idx,
                string.format("X=%.0f  Y=%.0f  Z=%.0f", p.X, p.Y, p.Z), 3)
        end)
    TMainRight:Button("🚀 Load Slot " .. idx, "TP ke posisi slot " .. idx,
        function()
            if not slots[idx] then
                Library:Notification("❌", "Slot "..idx.." kosong", 2); return
            end
            local root = getRoot()
            if root then
                root.CFrame = slots[idx]
                local p = slots[idx].Position
                Library:Notification("📍 Slot " .. idx,
                    string.format("X=%.0f  Y=%.0f  Z=%.0f", p.X, p.Y, p.Z), 3)
            end
        end)
end

-- ── Buat 10 tab slot player ──
-- Setiap tab punya 1 player info + tombol TP
-- Di-update isinya saat Scan ditekan lagi
-- Aurora tidak bisa hapus tab, jadi kita pre-buat 10 tab
-- dan isi dengan data scan

local playerTabPages = {}  -- simpan referensi section

Win:TabSection("👥 PLAYERS")
for i = 1, 10 do
    local idx  = i
    local pTab = Win:Tab("P" .. idx, "user")

    -- Buat page untuk tab ini
    local pPage    = pTab:Page("Player " .. idx, "user")
    local pSection = pPage:Section("👤 Info & Teleport", "Left")
    local pRight   = pPage:Section("📊 Detail", "Right")

    -- Tombol TP (selalu ada, nama update lewat closure)
    pSection:Button("📍 TP ke Player " .. idx,
        "Teleport ke player slot " .. idx,
        function()
            if not scannedPlayers[idx] then
                Library:Notification("❌",
                    "Scan player dulu!\nSlot "..idx.." kosong", 3)
                return
            end
            tpToPlayerByName(scannedPlayers[idx].name)
        end)

    pSection:Button("🔄 Lihat Info Player " .. idx,
        "Tampilkan info terbaru player ini",
        function()
            if not scannedPlayers[idx] then
                Library:Notification("❌",
                    "Scan player dulu!\nTekan SCAN PLAYER di tab Teleport", 4)
                return
            end
            local pl = scannedPlayers[idx]
            -- Hitung jarak terbaru
            local target = nil
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name == pl.name then target = p; break end
            end
            local freshDist = pl.dist
            if target and target.Character then
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = getRoot()
                if hrp and myRoot then
                    freshDist = getDist(hrp.Position, myRoot.Position)
                end
            end
            Library:Notification(
                "👤 Player " .. idx,
                string.format(
                    "Nama: %s\nDisplay: %s\nJarak: %dm\n\nTekan TP untuk teleport",
                    pl.name, pl.disp, freshDist),
                6)
        end)

    pRight:Paragraph("Slot " .. idx,
        "Tekan SCAN PLAYER\ndi tab Teleport\n\nLalu buka tab ini\nuntuk TP ke player\n\n"..
        "Urutan = jarak terdekat\nke terjauh")

    table.insert(playerTabPages, { section = pSection, right = pRight })
end

-- ════════════════════════════════════════
--  BUILD UI — TAB FLY
-- ════════════════════════════════════════
Win:TabSection("TOOLS")
local FPage = TabFly:Page("Fly & NoClip", "rocket")
local FL    = FPage:Section("🚀 Fly", "Left")
local FR    = FPage:Section("🚶 NoClip", "Right")

FL:Toggle("Fly Mode", "FlyToggle", false,
    "Aktifkan terbang",
    function(v)
        flyOn = v
        if v then startFly() else stopFly() end
        Library:Notification("🚀 Fly", v and "ON" or "OFF", 2)
    end)

FL:Slider("Kecepatan Fly", "FlySpeedSlider", 5, 300, 60,
    function(v) flySpeed = v end,
    "Kecepatan terbang (default 60)")

FL:Slider("Sensitivitas Naik/Turun", "PitchSlider", 1, 9, 3,
    function(v)
        -- v=1 → threshold=0.1 (sangat sensitif)
        -- v=5 → threshold=0.5 (butuh miring banyak)
        PITCH_UP   =  v * 0.1
        PITCH_DOWN = -v * 0.1
    end,
    "1=Sangat sensitif · 5=Perlu miring banyak")

FL:Paragraph("🎮 Cara Pakai Fly",
    "✅ Toggle Fly → ON\n\n"..
    "GERAK HORIZONTAL:\n"..
    "  Joystick kiri seperti\n"..
    "  biasa jalan\n\n"..
    "NAIK:\n"..
    "  Geser kamera ke ATAS\n"..
    "  (slide layar ke bawah)\n\n"..
    "TURUN:\n"..
    "  Geser kamera ke BAWAH\n"..
    "  (slide layar ke atas)\n\n"..
    "DIAM MELAYANG:\n"..
    "  Lepas joystick +\n"..
    "  kamera lurus ke depan")

FR:Toggle("NoClip", "NoclipToggle", false,
    "Tembus semua dinding",
    function(v)
        setNoclip(v)
        Library:Notification("🚶 NoClip",
            v and "ON — Tembus dinding" or "OFF", 2)
    end)

FR:Paragraph("Fly + NoClip = OP",
    "Aktifkan dua-duanya:\n\n"..
    "✅ Fly ON\n"..
    "✅ NoClip ON\n\n"..
    "→ Masuk private room\n"..
    "→ Tembus semua tembok\n"..
    "→ Akses area terlarang")

-- ════════════════════════════════════════
--  BUILD UI — TAB ESP
-- ════════════════════════════════════════
local EPage = TabESP:Page("ESP Player", "eye")
local EL    = EPage:Section("👁 Controls", "Left")
local ER    = EPage:Section("ℹ Info", "Right")

EL:Toggle("ESP Player", "ESPToggle", false,
    "Lihat semua player tembus dinding",
    function(v) toggleESP(v) end)

EL:Button("🔄 Refresh ESP", "Perbarui ESP",
    function()
        if espOn then
            clearESP()
            task.wait(0.2)
            for _, p in pairs(Players:GetPlayers()) do makeESP(p) end
            Library:Notification("👁 ESP", "Refreshed", 2)
        end
    end)

ER:Paragraph("Info ESP",
    "Per player tampil:\n"..
    "• Nama\n"..
    "• Jarak (meter)\n"..
    "• Area / room\n\n"..
    "AlwaysOnTop =\ntembus semua dinding")

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

SR:Toggle("Infinite Jump", "InfJumpToggle", false,
    "Lompat terus di udara",
    function(v)
        if v then
            _G.xkid_ij = UIS.JumpRequest:Connect(function()
                local hum = getHum()
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if _G.xkid_ij then
                _G.xkid_ij:Disconnect()
                _G.xkid_ij = nil
            end
        end
        Library:Notification("Inf Jump", v and "ON" or "OFF", 2)
    end)

-- ════════════════════════════════════════
--  BUILD UI — TAB PROTECTION
-- ════════════════════════════════════════
local PPage = TabProt:Page("Protection", "shield")
local PL    = PPage:Section("🛡 Controls", "Left")
local PR    = PPage:Section("ℹ Info", "Right")

PL:Toggle("Anti AFK", "AntiAFKToggle", false,
    "Cegah disconnect otomatis",
    function(v)
        if v then startAntiAFK() else stopAntiAFK() end
        Library:Notification("Anti AFK", v and "ON" or "OFF", 2)
    end)

PL:Toggle("Anti Kick", "AntiKickToggle", false,
    "Cegah dikeluarkan dari server",
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
    "Anti Kick:\nJaga HP dari sistem\nkick game\n\n"..
    "Rejoin:\nKoneksi ulang tanpa\ntutup game")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("🌟 XKID.HUB v4.0",
    "Mobile Ready!\nScan Player → tab P1~P10", 5)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════╗")
print("║   🌟  XKID.HUB  v4.0  Mobile       ║")
print("║   Fly: Joystick + Kamera Pitch      ║")
print("║   TP: Scan → Tab P1~P10             ║")
print("║   Player: " .. LP.Name)
print("╚══════════════════════════════════════╝")
