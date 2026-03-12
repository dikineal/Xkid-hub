--[[
  ╔══════════════════════════════════════════════════════╗
  ║          🌟  X K I D . H U B  v5.0  🌟             ║
  ║          Aurora UI  ✦  Mobile Optimized             ║
  ╚══════════════════════════════════════════════════════╝
  Teleport : Ketik 1-2 huruf → otomatis cari player
  Fly      : Joystick = arah · Kamera = naik/turun
  ESP · Speed · NoClip · Protection
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
--  Ketik prefix nama → cari player paling cocok
--  Bobot: username exact (1.0) > display (1.5)
--         > username CI (2.0) > display CI (2.5)
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

            if nv < min then
                to_pl = p
                min   = nv
            end
        end
    end
    return to_pl
end

-- ════════════════════════════════════════
--  ② TELEPORT ke PLAYER
-- ════════════════════════════════════════
local function tpToPlayer(ref)
    if not ref or ref == "" then
        Library:Notification("❌", "Ketik nama dulu!", 2)
        return
    end

    local to_pl = infer_plr(ref)

    if not to_pl then
        Library:Notification("❌", "Player tidak ditemukan\nCoba huruf lain", 3)
        return
    end

    if not to_pl.Character then
        Library:Notification("❌", to_pl.Name .. " tidak ada karakter", 2)
        return
    end

    local hrp  = to_pl.Character:FindFirstChild("HumanoidRootPart")
    local trs  = to_pl.Character:FindFirstChild("Torso")
    local part = hrp or trs

    if not part then
        Library:Notification("❌", "Karakter " .. to_pl.Name .. " tidak valid", 2)
        return
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
--  ④ FLY — BodyVelocity
--  Joystick  → maju/mundur/kiri/kanan
--  Kamera ↑  → naik
--  Kamera ↓  → turun
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

        -- Horizontal dari joystick (MoveDirection)
        local md = hum2.MoveDirection
        local horizontal = Vector3.new()
        if md.Magnitude > 0.05 then
            local fwdAmt   = md:Dot(camFwd)
            local rightAmt = md:Dot(camRgt)
            horizontal = camFwd * fwdAmt + camRgt * rightAmt
            if horizontal.Magnitude > 1 then
                horizontal = horizontal.Unit
            end
        end

        -- Vertical dari pitch kamera
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
                if hum and hum.Health > 0
                and hum.Health < hum.MaxHealth * 0.1 then
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

-- Lihat player online
TLeft:Button("👥 Lihat Player Online", "Tampilkan semua player di server",
    function()
        local list, n = "", 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                local root2  = p.Character
                    and p.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = getRoot()
                local d = (root2 and myRoot)
                    and getDist(root2.Position, myRoot.Position) or "?"
                n    = n + 1
                list = list .. string.format(
                    "• %s (%s) — %sm\n",
                    p.Name, p.DisplayName, tostring(d))
            end
        end
        Library:Notification(
            "👥 " .. n .. " Player Online",
            n > 0 and list or "Tidak ada player lain",
            10)
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

-- TextBox + Tombol TP
local tpInput = ""
TLeft:TextBox("Nama / Prefix Player", "TPInput", "",
    function(v) tpInput = v end,
    "Ketik 1-2 huruf pertama nama")

TLeft:Button("📍 Teleport ke Player", "Cari & TP ke player",
    function()
        tpToPlayer(tpInput)
    end)

TLeft:Button("🖱 Teleport ke Mouse", "TP ke posisi tap layar",
    function() tpToMouse() end)

TLeft:Button("💀 Respawn Cepat", "Mati & spawn di posisi sama",
    function() quickRespawn() end)

-- Save / Load slot
TRight:Label("💾 Save & Load Posisi")
for i = 1, 5 do
    local idx = i
    TRight:Button("💾 Save Slot " .. idx, "Simpan posisi ke slot " .. idx,
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
    TRight:Button("🚀 Load Slot " .. idx, "TP ke posisi slot " .. idx,
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

-- ════════════════════════════════════════
--  BUILD UI — TAB FLY
-- ════════════════════════════════════════
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

FL:Slider("Kecepatan", "FlySpeedSlider", 5, 300, 60,
    function(v) flySpeed = v end,
    "Kecepatan terbang (default 60)")

FL:Slider("Sensitivitas Naik/Turun", "PitchSlider", 1, 9, 3,
    function(v)
        PITCH_UP   =  v * 0.1
        PITCH_DOWN = -v * 0.1
    end, "1=Sangat sensitif · 9=Perlu miring banyak")

FL:Paragraph("🎮 Cara Pakai",
    "Toggle Fly → ON\n\n"..
    "GERAK:\n"..
    "Joystick kiri seperti jalan\n\n"..
    "NAIK:\n"..
    "Slide kamera ke atas\n"..
    "(geser layar ke bawah)\n\n"..
    "TURUN:\n"..
    "Slide kamera ke bawah\n"..
    "(geser layar ke atas)\n\n"..
    "DIAM MELAYANG:\n"..
    "Lepas joystick +\n"..
    "kamera lurus ke depan")

FR:Toggle("NoClip", "NoclipToggle", false,
    "Tembus semua dinding",
    function(v)
        setNoclip(v)
        Library:Notification("🚶 NoClip",
            v and "ON — Tembus dinding" or "OFF", 2)
    end)

FR:Paragraph("Fly + NoClip",
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
    "Tembus semua dinding")

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
    "Anti Kick:\nJaga HP dari kick\n\n"..
    "Rejoin:\nKoneksi ulang cepat")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("🌟 XKID.HUB v5.0",
    "Ketik prefix nama → TP otomatis!", 5)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════╗")
print("║   🌟  XKID.HUB  v5.0  Mobile       ║")
print("║   TP: Prefix → infer_plr            ║")
print("║   Fly: Joystick + Kamera Pitch      ║")
print("║   Player: " .. LP.Name)
print("╚══════════════════════════════════════╝")
