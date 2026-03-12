--[[
  ╔══════════════════════════════════════════════════════╗
  ║          🌟  X K I D . H U B  v2.0  🌟             ║
  ║          Aurora UI  ✦  Mobile Optimized             ║
  ╚══════════════════════════════════════════════════════╝
  Fly: BodyVelocity · Teleport: Daftar Player
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
local Win = Library:Window("🌟 XKID.HUB", "star", "v2.0 Mobile", false)

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
local function getChar()  return LP.Character end
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

-- ════════════════════════════════════════
--  RE-APPLY STATS ON RESPAWN
-- ════════════════════════════════════════
LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    task.wait(0.5)
    hum.WalkSpeed    = curWS
    hum.JumpPower    = curJP
    hum.UseJumpPower = true
    -- Re-init fly jika masih on
    if flyOn then
        task.wait(0.5)
        -- startFly dipanggil dari bawah (forward ref ok karena CharacterAdded async)
        local root2 = char:WaitForChild("HumanoidRootPart", 5)
        if root2 then
            if flyBV then pcall(function() flyBV:Destroy() end) end
            if flyBG then pcall(function() flyBG:Destroy() end) end
            flyBV = Instance.new("BodyVelocity", root2)
            flyBV.Velocity = Vector3.new()
            flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBG = Instance.new("BodyGyro", root2)
            flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            flyBG.P = 1e4
            flyBG.D = 100
            flyBG.CFrame = root2.CFrame
            hum.PlatformStand = true
        end
    end
end)

-- ════════════════════════════════════════
--  ① FLY — BodyVelocity
--  Mobile: Analog joystick karakter
--  gerak horizontal, naik/turun via
--  tombol UI (Naik / Turun)
-- ════════════════════════════════════════
-- Android fly arah
local flyUp   = false
local flyDown = false

local function startFly()
    local root = getRoot(); if not root then return end
    local hum  = getHum();  if not hum  then return end

    -- Cleanup dulu
    if flyBV then pcall(function() flyBV:Destroy() end) end
    if flyBG then pcall(function() flyBG:Destroy() end) end
    if flyConn then pcall(function() flyConn:Disconnect() end) end

    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Velocity = Vector3.new()
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)

    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P         = 1e4
    flyBG.D         = 100
    flyBG.CFrame    = root.CFrame

    hum.PlatformStand = true

    flyConn = RunService.Heartbeat:Connect(function()
        local root2 = getRoot()
        if not root2 or not flyBV then return end

        local hum2   = getHum(); if not hum2 then return end
        local cam    = Workspace.CurrentCamera
        local camCF  = cam.CFrame

        -- Ambil arah dari MoveDirection karakter
        -- (ini yang digerakkan analog/joystick mobile)
        local md = hum2.MoveDirection

        -- Komponen horizontal dari kamera
        local camRight   = Vector3.new(camCF.RightVector.X,   0, camCF.RightVector.Z)
        local camForward = Vector3.new(camCF.LookVector.X,    0, camCF.LookVector.Z)

        -- Konversi MoveDirection ke arah kamera
        local horizontal = Vector3.new()
        if md.Magnitude > 0.1 then
            -- Proyeksikan md ke sumbu kamera
            local fwdDot   = md:Dot(Vector3.new(0,0,-1))
            local rightDot = md:Dot(Vector3.new(1,0,0))
            horizontal = (camForward * fwdDot + camRight * rightDot)
            if horizontal.Magnitude > 0 then
                horizontal = horizontal.Unit
            end
        end

        -- Vertical dari tombol UI
        local vertical = Vector3.new()
        if flyUp   then vertical = Vector3.new(0,  1, 0) end
        if flyDown then vertical = Vector3.new(0, -1, 0) end

        -- PC keyboard fallback
        local pcUp   = UIS:IsKeyDown(Enum.KeyCode.Space)
        local pcDown = UIS:IsKeyDown(Enum.KeyCode.C)
                    or UIS:IsKeyDown(Enum.KeyCode.LeftControl)
        if pcUp   then vertical = Vector3.new(0,  1, 0) end
        if pcDown then vertical = Vector3.new(0, -1, 0) end

        local finalDir = horizontal + vertical
        if finalDir.Magnitude > 0 then
            flyBV.Velocity = finalDir.Unit * flySpeed
            -- Arahkan karakter ke arah gerak
            if horizontal.Magnitude > 0 then
                flyBG.CFrame = CFrame.new(Vector3.new(), horizontal)
            end
        else
            flyBV.Velocity = Vector3.new()
        end

        -- Cegah karakter jatuh/mati saat fly
        hum2.PlatformStand = true
    end)
end

local function stopFly()
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn = nil end
    if flyBV   then pcall(function() flyBV:Destroy() end);      flyBV   = nil end
    if flyBG   then pcall(function() flyBG:Destroy() end);      flyBG   = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
    flyUp   = false
    flyDown = false
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
    for _, b in ipairs(espBills) do pcall(function() b:Destroy() end) end
    espBills = {}
    for _, c in ipairs(espConns) do pcall(function() c:Disconnect() end) end
    espConns = {}
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
            local d      = myRoot and getDist(head.Position, myRoot.Position) or 0
            local area   = getArea(char)
            lbl.Text = string.format("👤 %s\n📍 %dm  |  %s", player.Name, d, area)
        end)
        table.insert(espConns, upd)
        table.insert(espBills, bill)
    end

    if player.Character then onChar(player.Character) end
    table.insert(espConns, player.CharacterAdded:Connect(onChar))
end

local function toggleESP(state)
    espOn = state
    clearESP()
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
                        Library:Notification("📍 TP", "→ " .. p.Name, 2)
                        return
                    end
                end
            end
            Library:Notification("❌", p.Name .. " tidak ada karakternya", 2)
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
    -- Simpan semua state
    local savedCF = root.CFrame
    local savedWS = curWS
    local savedJP = curJP

    -- Mati
    local c = getChar()
    if c then c:BreakJoints() end

    -- Spawn & kembalikan
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
local function stopAntiKick()
    antiKickOn = false
end

-- ════════════════════════════════════════
--  BUILD UI — TAB TELEPORT
-- ════════════════════════════════════════
local TPage = TabTP:Page("Teleport", "map-pin")
local TL    = TPage:Section("👥 Daftar Player", "Left")
local TR    = TPage:Section("📍 Slot & Lainnya", "Right")

-- Fungsi build daftar player (dipanggil saat refresh)
local playerButtons = {}

local function buildPlayerList()
    -- Hapus tombol lama
    -- Aurora tidak support remove button,
    -- jadi kita pakai Dropdown sebagai list player
end

-- Dropdown player list
local playerNames = {"[Refresh dulu]"}
local selectedPlayer = ""

local playerDropdown = TL:Dropdown(
    "Pilih Player", "PlayerDropdown",
    playerNames,
    function(val)
        selectedPlayer = val
    end)

TL:Button("🔄 Refresh Daftar Player", "Perbarui daftar player online",
    function()
        local names = {}
        local count = 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                table.insert(names, p.Name)
                count = count + 1
            end
        end
        if count == 0 then
            Library:Notification("👥", "Tidak ada player lain", 3)
            return
        end
        -- Update dropdown
        playerDropdown:Refresh(names)
        Library:Notification("🔄 Refresh", count .. " player online", 3)
    end)

TL:Button("📍 Teleport ke Player Dipilih", "TP ke player yang dipilih di dropdown",
    function()
        if selectedPlayer == "" or selectedPlayer == "[Refresh dulu]" then
            Library:Notification("❌", "Pilih player dulu!\nTekan Refresh → pilih nama", 3)
            return
        end
        tpToPlayerByName(selectedPlayer)
    end)

TL:Button("🖱 Teleport ke Mouse", "TP ke posisi kursor / tap layar",
    function() tpToMouse() end)

TL:Button("💀 Respawn Cepat di Posisi Sama", "Mati & langsung spawn di tempat yang sama",
    function() quickRespawn() end)

-- Save & Load 5 slot
TR:Label("💾 Save & Load Posisi")
for i = 1, 5 do
    local idx = i
    TR:Button("💾 Save Slot " .. idx, "Simpan posisi ke slot " .. idx,
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
    TR:Button("🚀 Load Slot " .. idx, "TP ke slot " .. idx,
        function()
            if not slots[idx] then
                Library:Notification("❌", "Slot " .. idx .. " kosong", 2); return
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

-- ════════════════════════════════════════
--  BUILD UI — TAB FLY
-- ════════════════════════════════════════
local FPage = TabFly:Page("Fly & NoClip", "rocket")
local FL    = FPage:Section("🚀 Fly Mobile", "Left")
local FR    = FPage:Section("🚶 NoClip", "Right")

FL:Toggle("Fly Mode", "FlyToggle", false,
    "Aktifkan terbang — gerak pakai analog",
    function(v)
        flyOn = v
        if v then startFly() else stopFly() end
        Library:Notification("🚀 Fly", v and "ON — Gerak pakai analog!" or "OFF", 3)
    end)

FL:Slider("Kecepatan Fly", "FlySpeedSlider", 5, 300, 60,
    function(v) flySpeed = v end,
    "Kecepatan terbang (default 60)")

-- Tombol Naik & Turun untuk Android
FL:Button("🔼 NAIK (Tahan)", "Terbang ke atas",
    function()
        if not flyOn then
            Library:Notification("❌", "Aktifkan Fly dulu", 2); return
        end
        flyUp = true
        task.delay(0.5, function() flyUp = false end)
    end)

FL:Button("🔽 TURUN (Tahan)", "Terbang ke bawah",
    function()
        if not flyOn then
            Library:Notification("❌", "Aktifkan Fly dulu", 2); return
        end
        flyDown = true
        task.delay(0.5, function() flyDown = false end)
    end)

FL:Button("⬆ NAIK TERUS (2 detik)", "Naik selama 2 detik",
    function()
        if not flyOn then
            Library:Notification("❌", "Aktifkan Fly dulu", 2); return
        end
        flyUp = true
        task.delay(2, function() flyUp = false end)
        Library:Notification("🔼", "Naik 2 detik", 2)
    end)

FL:Button("⬇ TURUN TERUS (2 detik)", "Turun selama 2 detik",
    function()
        if not flyOn then
            Library:Notification("❌", "Aktifkan Fly dulu", 2); return
        end
        flyDown = true
        task.delay(2, function() flyDown = false end)
        Library:Notification("🔽", "Turun 2 detik", 2)
    end)

FL:Paragraph("Cara Pakai Fly",
    "1. Toggle Fly → ON\n"..
    "2. Gerak pakai analog/joystick game\n"..
    "   seperti biasa jalan\n"..
    "3. Tekan NAIK / TURUN untuk\n"..
    "   atur ketinggian\n\n"..
    "Karakter mengikuti arah kamera!")

FR:Toggle("NoClip", "NoclipToggle", false,
    "Tembus semua dinding & objek",
    function(v)
        setNoclip(v)
        Library:Notification("🚶 NoClip", v and "ON — Tembus dinding" or "OFF", 2)
    end)

FR:Paragraph("Tips NoClip + Fly",
    "Aktifkan keduanya:\n"..
    "✅ Fly ON\n"..
    "✅ NoClip ON\n\n"..
    "→ Bisa masuk private room\n"..
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
            task.wait(0.3)
            for _, p in pairs(Players:GetPlayers()) do makeESP(p) end
            Library:Notification("👁 ESP", "Refreshed", 2)
        end
    end)

ER:Paragraph("Info ESP",
    "Tampilkan per player:\n"..
    "• Nama\n"..
    "• Jarak dalam meter\n"..
    "• Area / room mereka\n\n"..
    "AlwaysOnTop = tembus\nsemua dinding")

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
    end, "Kecepatan jalan (default 16)")

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
    end, "Kekuatan lompat (default 50)")

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

PL:Toggle("Anti AFK", "AntiAFKToggle", false,
    "Cegah disconnect karena tidak aktif",
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

PL:Button("🔄 Rejoin Server", "Koneksi ulang ke server",
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
                string.format("X = %.1f\nY = %.1f\nZ = %.1f", p.X, p.Y, p.Z), 6)
        end
    end)

PR:Paragraph("Info Protection",
    "Anti AFK:\nCegah auto-disconnect\n\n"..
    "Anti Kick:\nJaga HP dari sistem game\n\n"..
    "Rejoin:\nKoneksi ulang tanpa\ntutup game")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("🌟 XKID.HUB v2.0", "Mobile Ready! Semua fitur aktif", 4)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════╗")
print("║   🌟  XKID.HUB  v2.0  Mobile       ║")
print("║   TP: Dropdown · Fly: Analog        ║")
print("║   ESP · Speed · NoClip · Prot       ║")
print("║   Player: " .. LP.Name)
print("╚══════════════════════════════════════╝")
