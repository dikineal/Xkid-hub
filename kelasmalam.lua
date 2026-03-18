--[[
  ╔══════════════════════════════════════════════════════╗
  ║         🌟  X K I D  H U B  v2.0  🌟               ║
  ║         Aurora UI  ✦  Fixed Edition                 ║
  ╚══════════════════════════════════════════════════════╝
  Fix v2.0:
  [1] NoClip  — toggle bersih, cleanup saat OFF
  [2] Inf Jump — connection di-disconnect saat OFF
  [3] Fly     — hum di-refresh tiap frame, cleanup benar
  [4] ESP     — tidak buat ulang tiap frame, cleanup saat OFF
]]

-- ════════════════════════════════════════
--  LOAD AURORA UI
-- ════════════════════════════════════════
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local VirtualUser= game:GetService("VirtualUser")
local TpService  = game:GetService("TeleportService")
local Workspace  = game:GetService("Workspace")
local LP         = Players.LocalPlayer

-- ════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ════════════════════════════════════════
--  SAVE LAST POSITION
-- ════════════════════════════════════════
local lastPos

RunService.Heartbeat:Connect(function()
    local root = getRoot()
    if root then lastPos = root.CFrame end
end)

-- ════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════
local Win = Library:Window("XKID HUB", "star", "v2.0 Fixed", false)

Win:TabSection("HUB")
local TabTP   = Win:Tab("Teleport",  "map-pin")
local TabPl   = Win:Tab("Player",    "user")
local TabProt = Win:Tab("Protect",   "shield")

-- ════════════════════════════════════════
--  TAB TELEPORT
-- ════════════════════════════════════════
local TPage = TabTP:Page("Teleport Player", "map-pin")
local TL    = TPage:Section("Players Online", "Left")
local TR    = TPage:Section("Info", "Right")

local playerButtons = {}

local function addPlayer(p)
    if p == LP then return end
    local btn = TL:Button(p.Name, "Klik untuk teleport ke "..p.Name,
        function()
            local root = getRoot()
            if not root then return end
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                Library:Notification("TP", "Teleport ke "..p.Name, 2)
            else
                Library:Notification("TP", p.Name.." tidak ada karakter", 2)
            end
        end)
    playerButtons[p] = btn
end

for _, p in pairs(Players:GetPlayers()) do addPlayer(p) end
Players.PlayerAdded:Connect(addPlayer)

TR:Paragraph("Cara Pakai",
    "Player online otomatis\nmuncul di kiri.\n\nKlik nama player\nuntuk langsung TP!")

-- ════════════════════════════════════════
--  TAB PLAYER
-- ════════════════════════════════════════
local Page  = TabPl:Page("Player", "user")
local Left  = Page:Section("Movement", "Left")
local Right = Page:Section("Visual", "Right")

-- ════════════════════════════════
--  SPEED
-- ════════════════════════════════
local speed = 16

RunService.RenderStepped:Connect(function()
    local hum = getHum()
    if hum then hum.WalkSpeed = speed end
end)

Left:Slider("Walk Speed", "speed", 16, 500, 16,
    function(v) speed = v end,
    "Default 16")

-- ════════════════════════════════
--  NOCLIP (FIXED)
--  Masalah lama: syntax toggle salah (kurang 1 param)
--  Fix: tambah description param, cleanup CanCollide=true saat OFF
-- ════════════════════════════════
local noclip    = false
local noclipConn = nil

Left:Toggle("NoClip", "noclip", false,
    "Tembus semua dinding",   -- <-- param description yang hilang sebelumnya
    function(v)
        noclip = v
        if v then
            -- Buat connection baru
            if noclipConn then noclipConn:Disconnect() end
            noclipConn = RunService.Stepped:Connect(function()
                local char = getChar(); if not char then return end
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end)
        else
            -- Disconnect dan kembalikan collision
            if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
            local char = getChar()
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
        Library:Notification("NoClip", v and "ON" or "OFF", 2)
    end)

-- ════════════════════════════════
--  INFINITE JUMP (FIXED)
--  Masalah lama: connection tidak pernah di-disconnect saat OFF
--  Fix: simpan connection, disconnect saat toggle OFF
-- ════════════════════════════════
local infJump    = false
local jumpConn   = nil

Left:Toggle("Infinite Jump", "jump", false,
    "Lompat terus di udara",
    function(v)
        infJump = v
        if v then
            -- Buat connection baru
            if jumpConn then jumpConn:Disconnect() end
            jumpConn = UIS.JumpRequest:Connect(function()
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            -- Disconnect saat OFF
            if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
        end
        Library:Notification("Inf Jump", v and "ON" or "OFF", 2)
    end)

-- ════════════════════════════════
--  FLY (FIXED)
--  Masalah lama:
--  1. hum di-capture sekali → nil setelah respawn
--  2. stopFly tidak set bv/bg = nil → error kalau dipanggil 2x
--  3. hum.PlatformStand tidak di-set
--  Fix:
--  1. getHum() dipanggil tiap frame di dalam loop
--  2. stopFly set semua variabel = nil dengan benar
--  3. PlatformStand dikelola dengan benar
-- ════════════════════════════════
local flying  = false
local flySpeed = 60
local bv, bg, flyConn = nil, nil, nil

local function stopFly()
    flying = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if bv      then pcall(function() bv:Destroy() end); bv = nil end
    if bg      then pcall(function() bg:Destroy() end); bg = nil end
    -- Kembalikan PlatformStand
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

local function startFly()
    local root = getRoot()
    if not root then return end

    -- Bersihkan yang lama dulu
    stopFly()
    flying = true

    -- Buat BodyVelocity dan BodyGyro baru
    bv = Instance.new("BodyVelocity", root)
    bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity  = Vector3.new()

    bg = Instance.new("BodyGyro", root)
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P         = 1e4
    bg.D         = 100
    bg.CFrame    = root.CFrame

    -- Set PlatformStand
    local hum = getHum()
    if hum then hum.PlatformStand = true end

    flyConn = RunService.Heartbeat:Connect(function()
        if not flying then return end

        -- FIX: getHum() tiap frame, bukan capture sekali
        local h    = getHum()
        local r    = getRoot()
        if not h or not r or not bv or not bg then return end

        local cam   = Workspace.CurrentCamera
        local cf    = cam.CFrame
        local look  = cf.LookVector
        local right = cf.RightVector
        local move  = h.MoveDirection

        -- Horizontal dari joystick
        local horiz = Vector3.new()
        if move.Magnitude > 0.05 then
            local fwd = Vector3.new(look.X, 0, look.Z)
            local rgt = Vector3.new(right.X, 0, right.Z)
            if fwd.Magnitude  > 0 then fwd = fwd.Unit  end
            if rgt.Magnitude  > 0 then rgt = rgt.Unit  end
            horiz = fwd * move:Dot(fwd) + rgt * move:Dot(rgt)
            if horiz.Magnitude > 1 then horiz = horiz.Unit end
        end

        -- Vertical dari pitch kamera
        local py   = look.Y
        local vert = Vector3.new()
        if py > 0.3 then
            vert = Vector3.new(0, math.min((py - 0.3) / 0.7, 1), 0)
        elseif py < -0.3 then
            vert = Vector3.new(0, -math.min((-py - 0.3) / 0.7, 1), 0)
        end

        local dir = horiz + vert
        if dir.Magnitude > 0 then
            bv.Velocity = (dir.Magnitude > 1 and dir.Unit or dir) * flySpeed
            if horiz.Magnitude > 0.05 then
                bg.CFrame = CFrame.new(Vector3.new(), horiz)
            end
        else
            bv.Velocity = Vector3.new()
        end

        h.PlatformStand = true
    end)
end

-- Re-apply fly setelah respawn
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if flying then
        task.wait(0.3)
        startFly()
    end
    -- Re-apply noclip connection setelah respawn
    if noclip and not noclipConn then
        noclipConn = RunService.Stepped:Connect(function()
            local c = getChar(); if not c then return end
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end
end)

Left:Toggle("Fly", "fly", false,
    "Terbang bebas | Joystick+Kamera",
    function(v)
        if v then startFly() else stopFly() end
        Library:Notification("Fly", v and "ON" or "OFF", 2)
    end)

Left:Slider("Fly Speed", "flyspd", 10, 300, 60,
    function(v) flySpeed = v end,
    "Kecepatan terbang")

Left:Paragraph("Cara Fly",
    "Joystick = arah gerak\nKamera atas = naik\nKamera bawah = turun\nLepas joystick = melayang")

-- ════════════════════════════════
--  ESP PLAYER (FIXED)
--  Masalah lama:
--  1. BillboardGui dibuat ulang tiap Heartbeat frame → sangat boros
--  2. Tidak ada cleanup saat ESP OFF
--  3. TextLabel dicari ulang setiap frame padahal sudah ada
--  Fix:
--  1. Buat billboard SEKALI per player, simpan referensi
--  2. Update hanya text/posisi tiap frame
--  3. Cleanup benar saat OFF
-- ════════════════════════════════
local esp       = false
local espData   = {}  -- player → { bill, txt }
local espConn   = nil

local function makeESPFor(p)
    if p == LP then return end
    if not p.Character then return end
    local head = p.Character:FindFirstChild("Head")
    if not head then return end
    if espData[p] then return end  -- sudah ada, skip

    local bill = Instance.new("BillboardGui")
    bill.Name        = "XKID_ESP"
    bill.Size        = UDim2.new(0, 180, 0, 45)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true
    bill.Adornee     = head
    bill.Parent      = head

    -- Background
    local bg = Instance.new("Frame", bill)
    bg.Size                   = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.4
    bg.BorderSizePixel        = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

    local txt = Instance.new("TextLabel", bg)
    txt.Size                   = UDim2.new(1, -6, 1, -4)
    txt.Position               = UDim2.new(0, 3, 0, 2)
    txt.BackgroundTransparency = 1
    txt.TextColor3             = Color3.fromRGB(255, 230, 80)
    txt.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    txt.TextStrokeTransparency = 0.3
    txt.TextScaled             = true
    txt.Font                   = Enum.Font.GothamBold
    txt.TextXAlignment         = Enum.TextXAlignment.Center
    txt.Text                   = p.Name

    espData[p] = { bill = bill, txt = txt }
end

local function cleanESPFor(p)
    if espData[p] then
        pcall(function() espData[p].bill:Destroy() end)
        espData[p] = nil
    end
end

local function clearAllESP()
    for p, _ in pairs(espData) do
        cleanESPFor(p)
    end
    espData = {}
end

local function startESP()
    -- Buat ESP untuk semua player yang sudah ada
    for _, p in pairs(Players:GetPlayers()) do
        makeESPFor(p)
    end

    -- Update text tiap frame (bukan buat ulang!)
    espConn = RunService.Heartbeat:Connect(function()
        if not esp then return end
        local myRoot = getRoot()
        for p, data in pairs(espData) do
            -- Cek apakah masih valid
            if not data.bill or not data.bill.Parent then
                espData[p] = nil
            else
                -- Update text saja
                if myRoot and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor(
                        (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
                    )
                    data.txt.Text = p.Name.."\n"..dist.."m"
                else
                    data.txt.Text = p.Name
                end
            end
        end
        -- Tambah ESP untuk player baru yang characternya baru muncul
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and not espData[p] then
                makeESPFor(p)
            end
        end
    end)
end

local function stopESP()
    if espConn then espConn:Disconnect(); espConn = nil end
    clearAllESP()
end

-- Cleanup kalau player keluar
Players.PlayerRemoving:Connect(function(p)
    cleanESPFor(p)
end)

-- Cleanup kalau karakter respawn
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if esp then makeESPFor(p) end
    end)
end)
for _, p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if esp then makeESPFor(p) end
    end)
end

Right:Toggle("ESP Player", "esp", false,
    "Tampilkan nama + jarak player lain",
    function(v)
        esp = v
        if v then startESP() else stopESP() end
        Library:Notification("ESP", v and "ON" or "OFF", 2)
    end)

Right:Paragraph("ESP Info",
    "Tampil per player:\nNama player\nJarak (meter)\n\nUpdate real-time\nTidak boros performa\nCleanup saat OFF")

-- ════════════════════════════════════════
--  TAB PROTECTION
-- ════════════════════════════════════════
local PPage = TabProt:Page("Protection", "shield")
local PL    = PPage:Section("Safety", "Left")
local PR    = PPage:Section("Info", "Right")

-- Anti AFK (FIXED: simpan connection)
local afkConn = nil
PL:Toggle("Anti AFK", "afk", false,
    "Cegah disconnect saat idle",
    function(v)
        if v then
            if afkConn then afkConn:Disconnect() end
            afkConn = LP.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            if afkConn then afkConn:Disconnect(); afkConn = nil end
        end
        Library:Notification("Anti AFK", v and "ON" or "OFF", 2)
    end)

-- Respawn ke posisi terakhir
PL:Button("Respawn di Posisi Ini", "Mati lalu spawn di posisi terakhir",
    function()
        local saved = lastPos
        local char  = LP.Character
        if char then char:BreakJoints() end

        local conn
        conn = LP.CharacterAdded:Connect(function(newChar)
            conn:Disconnect()
            task.wait(1)
            local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
            if hrp and saved then
                hrp.CFrame = saved
                Library:Notification("Respawn", "Kembali ke posisi!", 3)
            end
        end)
    end)

-- Rejoin
PL:Button("Rejoin Server", "Koneksi ulang ke server",
    function()
        Library:Notification("Rejoin", "Menghubungkan ulang...", 3)
        task.wait(1)
        TpService:Teleport(game.PlaceId, LP)
    end)

-- Posisi
PL:Button("Posisi Saya", "Lihat koordinat sekarang",
    function()
        local root = getRoot()
        if root then
            local p = root.Position
            Library:Notification("Posisi",
                string.format("X=%.1f\nY=%.1f\nZ=%.1f", p.X, p.Y, p.Z), 6)
            print(string.format("[ XKID ] X=%.4f Y=%.4f Z=%.4f", p.X, p.Y, p.Z))
        end
    end)

PR:Paragraph("Anti AFK",
    "Cegah auto-disconnect\ndengan simulasi input\nsaat idle terdeteksi")

PR:Paragraph("Respawn",
    "Simpan posisi terakhir\notomatis tiap frame.\nMati lalu kembali\nke posisi yang sama.")

-- ════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════
Library:Notification("XKID HUB", "v2.0 Fixed — NoClip · Fly · ESP · InfJump", 5)
Library:ConfigSystem(Win)

print("[ XKID HUB ] v2.0 loaded — " .. LP.Name)
