--[[
  ╔══════════════════════════════════════════════════════╗
  ║          🌟  X K I D . H U B  v1.0  🌟             ║
  ║          Aurora UI  ✦  Universal Script             ║
  ╚══════════════════════════════════════════════════════╝
  Fitur: ESP · Teleport · Fly · NoClip · Speed · Protection
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
local Win = Library:Window("🌟 XKID.HUB", "star", "v1.0", false)

-- ════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════
Win:TabSection("MAIN")
local TabESP   = Win:Tab("ESP",        "eye")
local TabTP    = Win:Tab("Teleport",   "map-pin")
local TabFly   = Win:Tab("Fly",        "rocket")
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
local function dist(a, b)
    return math.floor((a - b).Magnitude + 0.5)
end

-- ════════════════════════════════════════
--  VARIABLES
-- ════════════════════════════════════════
-- Speed & Jump
local curWS = 16
local curJP = 50

-- Fly
local flyOn    = false
local flySpeed = 50
local flyConns = {}
local flyBV, flyBG

-- NoClip
local noclipOn   = false
local noclipConn = nil

-- ESP
local espOn      = false
local espBills   = {}
local espConns   = {}

-- Protection
local afkConn    = nil
local antiKickOn = false
local antiKickLoop = nil

-- Saved positions
local slots = {}

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
end)

-- ════════════════════════════════════════
--  ① FLY SYSTEM
--  WASD = gerak · Space = naik · C/Ctrl = turun
-- ════════════════════════════════════════
local function cleanFly()
    for _, c in ipairs(flyConns) do pcall(function() c:Disconnect() end) end
    flyConns = {}
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
end

local function startFly()
    cleanFly()
    local root = getRoot(); if not root then return end
    local hum  = getHum();  if not hum  then return end

    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Velocity       = Vector3.new()
    flyBV.MaxForce       = Vector3.new(1e5, 1e5, 1e5)

    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque      = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P              = 1e4
    flyBG.D              = 100
    flyBG.CFrame         = root.CFrame

    hum.PlatformStand    = true

    table.insert(flyConns, RunService.Heartbeat:Connect(function()
        local root2 = getRoot(); if not root2 or not flyBV then return end
        local cam   = Workspace.CurrentCamera
        local cf    = cam.CFrame

        local fwd  = UIS:IsKeyDown(Enum.KeyCode.W)
        local bwd  = UIS:IsKeyDown(Enum.KeyCode.S)
        local lft  = UIS:IsKeyDown(Enum.KeyCode.A)
        local rgt  = UIS:IsKeyDown(Enum.KeyCode.D)
        local up   = UIS:IsKeyDown(Enum.KeyCode.Space)
        local dn   = UIS:IsKeyDown(Enum.KeyCode.C)
                  or UIS:IsKeyDown(Enum.KeyCode.LeftControl)

        local dir = Vector3.new()
        if fwd  then dir = dir + cf.LookVector end
        if bwd  then dir = dir - cf.LookVector end
        if rgt  then dir = dir + cf.RightVector end
        if lft  then dir = dir - cf.RightVector end
        if up   then dir = dir + Vector3.new(0,1,0) end
        if dn   then dir = dir - Vector3.new(0,1,0) end

        if dir.Magnitude > 0 then
            flyBV.Velocity = dir.Unit * flySpeed
            flyBG.CFrame   = CFrame.new(Vector3.new(), dir)
        else
            flyBV.Velocity = Vector3.new()
        end
    end))
end

local function stopFly()
    cleanFly()
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

-- Re-init fly on respawn if still on
LP.CharacterAdded:Connect(function()
    task.wait(1)
    if flyOn then startFly() end
end)

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
            if (n:find("room") or n:find("area") or n:find("zone")
            or  n:find("vip")  or n:find("priv") or n:find("salon")) then
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

        -- BillboardGui
        local bill = Instance.new("BillboardGui")
        bill.Size         = UDim2.new(0, 180, 0, 50)
        bill.StudsOffset  = Vector3.new(0, 3, 0)
        bill.AlwaysOnTop  = true
        bill.Adornee      = head
        bill.Parent       = char

        -- Background frame
        local bg = Instance.new("Frame", bill)
        bg.Size                   = UDim2.new(1,0,1,0)
        bg.BackgroundColor3       = Color3.fromRGB(0,0,0)
        bg.BackgroundTransparency = 0.45
        bg.BorderSizePixel        = 0
        local corner = Instance.new("UICorner", bg)
        corner.CornerRadius       = UDim.new(0, 6)

        -- Text label
        local lbl = Instance.new("TextLabel", bg)
        lbl.Size                   = UDim2.new(1,-6,1,-4)
        lbl.Position               = UDim2.new(0,3,0,2)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3             = Color3.fromRGB(255, 230, 80)
        lbl.TextStrokeTransparency = 0.3
        lbl.TextStrokeColor3       = Color3.fromRGB(0,0,0)
        lbl.TextScaled             = true
        lbl.Font                   = Enum.Font.GothamBold
        lbl.TextXAlignment         = Enum.TextXAlignment.Center

        -- Update loop
        local upd = RunService.Heartbeat:Connect(function()
            if not bill or not bill.Parent then return end
            local myRoot = getRoot()
            local d      = myRoot and dist(head.Position, myRoot.Position) or 0
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
local function tpToPlayer(name)
    if not name or name == "" then
        Library:Notification("❌", "Masukkan nama player", 2); return
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local match = p.Name:lower():find(name:lower(), 1, true)
                       or p.DisplayName:lower():find(name:lower(), 1, true)
            if match and p.Character then
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
--  ⑤ PROTECTION
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
    antiKickLoop = task.spawn(function()
        while antiKickOn do
            pcall(function()
                -- Prevent death from anti-kick systems
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
--  BUILD UI — TAB ESP
-- ════════════════════════════════════════
local EPage = TabESP:Page("ESP Player", "eye")
local EL    = EPage:Section("👁 Controls", "Left")
local ER    = EPage:Section("ℹ Info", "Right")

EL:Toggle("ESP Player", "ESPToggle", false,
    "Lihat semua player tembus dinding",
    function(v) toggleESP(v) end)

EL:Button("🔄 Refresh ESP", "Perbarui ESP untuk semua player",
    function()
        if espOn then
            toggleESP(false)
            task.wait(0.3)
            toggleESP(true)
            Library:Notification("👁 ESP", "Refreshed", 2)
        end
    end)

ER:Paragraph("Info ESP",
    "Menampilkan:\n"..
    "• Nama player\n"..
    "• Jarak (meter)\n"..
    "• Area / room\n\n"..
    "AlwaysOnTop = tembus\nsemua dinding & objek")

-- ════════════════════════════════════════
--  BUILD UI — TAB TELEPORT
-- ════════════════════════════════════════
local TPage = TabTP:Page("Teleport", "map-pin")
local TL    = TPage:Section("👤 Ke Player", "Left")
local TR    = TPage:Section("📍 Slot & Mouse", "Right")

-- Daftar player
TL:Button("🔄 Lihat Player Online", "Tampilkan semua player di server",
    function()
        local list, n = "", 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                list = list .. "• " .. p.Name
                if p.DisplayName ~= p.Name then
                    list = list .. " (" .. p.DisplayName .. ")"
                end
                list = list .. "\n"
                n = n + 1
            end
        end
        Library:Notification(
            "👥 " .. n .. " Player Online",
            n > 0 and list or "Tidak ada player lain",
            8)
    end)

local tpName = ""
TL:TextBox("Nama Player", "TPNameBox", "",
    function(v) tpName = v end,
    "Ketik nama / display name")

TL:Button("📍 Teleport ke Player", "TP ke player yang dicari",
    function() tpToPlayer(tpName) end)

TL:Button("🖱 Teleport ke Mouse", "TP ke posisi kursor",
    function() tpToMouse() end)

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
                string.format("X=%.1f Y=%.1f Z=%.1f", p.X, p.Y, p.Z), 3)
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
                    string.format("X=%.1f Y=%.1f Z=%.1f", p.X, p.Y, p.Z), 3)
            end
        end)
end

-- ════════════════════════════════════════
--  BUILD UI — TAB FLY
-- ════════════════════════════════════════
local FPage = TabFly:Page("Fly & NoClip", "rocket")
local FL    = FPage:Section("🚀 Fly", "Left")
local FR    = FPage:Section("🚶 NoClip", "Right")

FL:Toggle("Fly Mode", "FlyToggle", false,
    "Terbang bebas dengan WASD + Space/C",
    function(v)
        flyOn = v
        if v then startFly() else stopFly() end
        Library:Notification("🚀 Fly", v and "ON" or "OFF", 2)
    end)

FL:Slider("Kecepatan Fly", "FlySpeedSlider", 5, 300, 50,
    function(v)
        flySpeed = v
    end, "Kecepatan terbang (default 50)")

FL:Paragraph("Kontrol Fly",
    "W / S  — Maju / Mundur\n"..
    "A / D  — Kiri / Kanan\n"..
    "Space  — Naik\n"..
    "C / Ctrl — Turun\n\n"..
    "Gerak mengikuti arah kamera")

FR:Toggle("NoClip", "NoclipToggle", false,
    "Tembus dinding & masuk private room",
    function(v)
        setNoclip(v)
        Library:Notification("🚶 NoClip", v and "ON — Tembus dinding" or "OFF", 2)
    end)

FR:Paragraph("Info NoClip",
    "Matikan collision karakter\n"..
    "Bisa masuk:\n"..
    "• Private room\n"..
    "• Area VIP\n"..
    "• Area terlarang\n\n"..
    "Gunakan bersama Fly\nuntuk akses penuh")

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

SL:Button("🔁 Reset Speed (16)", "Kembalikan ke normal",
    function()
        curWS = 16
        local hum = getHum()
        if hum then hum.WalkSpeed = 16 end
        Library:Notification("Speed", "Reset ke 16", 2)
    end)

SL:Button("💀 Respawn di Posisi Sama", "Mati & kembali ke posisi sekarang",
    function()
        local root = getRoot()
        if not root then return end
        local savedCF = root.CFrame
        local c = getChar()
        if c then c:BreakJoints() end
        local conn
        conn = LP.CharacterAdded:Connect(function(newChar)
            conn:Disconnect()
            task.wait(1)
            local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
            if hrp then hrp.CFrame = savedCF end
            Library:Notification("✅ Respawn", "Kembali ke posisi semula", 3)
        end)
    end)

SR:Slider("JumpPower", "JPSlider", 1, 500, 50,
    function(v)
        curJP = v
        local hum = getHum()
        if hum then
            hum.JumpPower    = v
            hum.UseJumpPower = true
        end
    end, "Kekuatan lompat (default 50)")

SR:Button("🔁 Reset Jump (50)", "Kembalikan ke normal",
    function()
        curJP = 50
        local hum = getHum()
        if hum then
            hum.JumpPower    = 50
            hum.UseJumpPower = true
        end
        Library:Notification("Jump", "Reset ke 50", 2)
    end)

SR:Toggle("Infinite Jump", "InfJumpToggle", false,
    "Lompat terus di udara tanpa batas",
    function(v)
        if v then
            _G.xkid_ijConn = UIS.JumpRequest:Connect(function()
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if _G.xkid_ijConn then
                _G.xkid_ijConn:Disconnect()
                _G.xkid_ijConn = nil
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

PL:Button("🔄 Rejoin Server", "Koneksi ulang ke server yang sama",
    function()
        Library:Notification("🔄 Rejoin", "Menghubungkan ulang...", 3)
        task.wait(1)
        TpService:Teleport(game.PlaceId, LP)
    end)

PL:Button("📍 Print Posisi Saya", "Cetak koordinat ke notif",
    function()
        local root = getRoot()
        if root then
            local p = root.Position
            Library:Notification("📍 Posisi",
                string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 6)
            print(string.format("[ XKID 📍 ] X=%.3f  Y=%.3f  Z=%.3f", p.X, p.Y, p.Z))
        end
    end)

PR:Paragraph("Info Protection",
    "Anti AFK:\nCegah auto-disconnect\n\n"..
    "Anti Kick:\nJaga HP agar tidak mati\nkarena sistem game\n\n"..
    "Rejoin:\nKoneksi ulang ke server\ntanpa tutup game")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("🌟 XKID.HUB", "Semua fitur siap! v1.0", 4)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════╗")
print("║   🌟  XKID.HUB  v1.0               ║")
print("║   ESP · TP · Fly · Speed · Prot     ║")
print("║   Player: " .. LP.Name)
print("╚══════════════════════════════════════╝")
