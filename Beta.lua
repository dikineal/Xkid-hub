--[[
  ╔══════════════════════════════════════════════════════╗
  ║        🛠  X K I D   U T I L I T Y  v1.0  🛠       ║
  ║        XKID HUB  ✦  Aurora UI                      ║
  ╚══════════════════════════════════════════════════════╝

  FITUR:
  [1] Anti AFK       — Cegah disconnect otomatis
  [2] Rocket Fly     — H=Toggle · G=Anchor · L=Fast · K=Slow
  [3] Teleport       — TP ke player (simple & advanced)
  [4] Respawn Posisi — Mati & kembali ke tempat yang sama
  [5] WalkSpeed      — Atur kecepatan jalan
  [6] Infinite Jump  — Lompat tanpa batas di udara
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
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- ════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════
local Win = Library:Window(
    "🛠 XKID UTILITY",
    "wrench",
    "v1.0  |  XKID HUB",
    false
)

-- ════════════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════════════
Win:TabSection("🛠 UTILITY")
local TabMain = Win:Tab("Main",     "heart")
local TabFly  = Win:Tab("Fly",      "rocket")
local TabTP   = Win:Tab("Teleport", "map-pin")

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

-- ════════════════════════════════════════════════
--  ① ANTI AFK
-- ════════════════════════════════════════════════
-- Sambungkan sekali saja, toggle via flag
local _afkConn = nil
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

-- ════════════════════════════════════════════════
--  ② WALKSPEED
-- ════════════════════════════════════════════════
local defaultWS = 16
local function setWalkSpeed(v)
    local hum = getHum()
    if hum then hum.WalkSpeed = v end
    -- Simpan untuk respawn
    defaultWS = v
end

-- Re-apply walkspeed saat respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.5)
        hum.WalkSpeed = defaultWS
    end
end)

-- ════════════════════════════════════════════════
--  ③ INFINITE JUMP
-- ════════════════════════════════════════════════
local infiniteJump = false
local _jumpConn    = nil

local function setInfiniteJump(state)
    infiniteJump = state
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
        Library:Notification("❌ Error", "Karakter tidak ditemukan", 3)
        return
    end

    -- Simpan posisi & speed sebelum mati
    local savedCF = root.CFrame
    local savedWS = defaultWS

    -- Matikan karakter
    local ch = getChar()
    if ch then ch:BreakJoints() end

    -- Saat karakter baru spawn, kembalikan ke posisi
    local conn
    conn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        conn:Disconnect()
        task.wait(1)
        local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
        local hum = newChar:WaitForChild("Humanoid", 5)
        if hrp then hrp.CFrame = savedCF end
        if hum then hum.WalkSpeed = savedWS end
        Library:Notification("✅ Respawn", "Kembali ke posisi semula", 3)
    end)
end

-- ════════════════════════════════════════════════
--  ⑤ ROCKET FLY
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

_G.xkid_fly_evts = _G.xkid_fly_evts or {}
_G.xkid_fly_rp   = nil
_G.xkid_fly_bg   = nil
_G.xkid_fly_pt   = nil

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

local function fly_dir()
    if REL_TO_CHAR and parentFly then
        return CFrame.new(Vector3.new(), parentFly.CFrame.LookVector) * move_dir
    end
    local front = game.Workspace.CurrentCamera:ScreenPointToRay(ms.X, ms.Y).Direction
    return CFrame.new(Vector3.new(), front) * move_dir
end

local function init_fly()
    local ch = getChar(); if not ch then return end
    humanoidFly = ch:FindFirstChildOfClass("Humanoid"); if not humanoidFly then return end
    parentFly   = humanoidFly.RootPart;                 if not parentFly then return end

    -- Cleanup lama
    if _G.xkid_fly_rp then pcall(function() _G.xkid_fly_rp:Destroy() end) end
    if _G.xkid_fly_bg then pcall(function() _G.xkid_fly_bg:Destroy() end) end
    if _G.xkid_fly_pt and _G.xkid_fly_pt.Parent then
        pcall(function() _G.xkid_fly_pt.Parent:Destroy() end)
    end

    -- Buat baru
    _G.xkid_fly_bg  = Instance.new("BodyGyro",        parentFly)
    _G.xkid_fly_rp  = Instance.new("RocketPropulsion", parentFly)
    local md        = Instance.new("Model")
    _G.xkid_fly_pt  = Instance.new("Part", md)
    md.Parent       = _G.xkid_fly_pt

    _G.xkid_fly_rp.MaxTorque   = Vector3.new(MAX_TORQUE_RP, MAX_TORQUE_RP, MAX_TORQUE_RP)
    _G.xkid_fly_bg.MaxTorque   = Vector3.new()
    md.PrimaryPart             = _G.xkid_fly_pt
    _G.xkid_fly_pt.Anchored    = true
    _G.xkid_fly_pt.CanCollide  = false
    _G.xkid_fly_pt.Transparency= 1
    _G.xkid_fly_rp.CartoonFactor = 1
    _G.xkid_fly_rp.Target      = _G.xkid_fly_pt
    _G.xkid_fly_rp.MaxSpeed    = SPEED
    _G.xkid_fly_rp.MaxThrust   = MAX_THRUST
    _G.xkid_fly_rp.ThrustP     = THRUST_P
    _G.xkid_fly_rp.ThrustD     = THRUST_D
    _G.xkid_fly_rp.TurnP       = THRUST_P
    _G.xkid_fly_rp.TurnD       = TURN_D
    _G.xkid_fly_bg.P           = 3e4
    flyEnabled = false
    flying     = false
end

local function setup_fly_events()
    for _, e in ipairs(_G.xkid_fly_evts) do pcall(function() e:Disconnect() end) end
    _G.xkid_fly_evts = {}

    table.insert(_G.xkid_fly_evts, LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1); init_fly()
    end))

    table.insert(_G.xkid_fly_evts, UIS.InputBegan:Connect(function(i, p)
        if p then return end

        if i.KeyCode == FLYK then
            flyEnabled = not flyEnabled
            if flyEnabled then
                if _G.xkid_fly_bg then
                    _G.xkid_fly_bg.MaxTorque = Vector3.new(MAX_TORQUE_BG, 0, MAX_TORQUE_BG)
                end
                if _G.xkid_fly_rp then
                    _G.xkid_fly_rp.MaxTorque = Vector3.new(MAX_TORQUE_RP, MAX_TORQUE_RP, MAX_TORQUE_RP)
                end
                Library:Notification("🚀 Fly", "ON  (H = toggle)", 2)
            else
                if _G.xkid_fly_bg then _G.xkid_fly_bg.MaxTorque = Vector3.new() end
                if _G.xkid_fly_rp then _G.xkid_fly_rp.MaxTorque = Vector3.new() end
                Library:Notification("🚀 Fly", "OFF", 2)
            end

        elseif i.KeyCode == ANCK and parentFly then
            parentFly.Anchored = not parentFly.Anchored
            Library:Notification("Anchor", parentFly.Anchored and "ON" or "OFF", 1)

        elseif i.KeyCode == FSTK and _G.xkid_fly_rp then
            SPEED = SPEED * 1.5
            _G.xkid_fly_rp.MaxSpeed = SPEED
            Library:Notification("Speed ⬆", string.format("%.0f", SPEED), 1)

        elseif i.KeyCode == SLWK and _G.xkid_fly_rp then
            SPEED = math.max(10, SPEED / 1.5)
            _G.xkid_fly_rp.MaxSpeed = SPEED
            Library:Notification("Speed ⬇", string.format("%.0f", SPEED), 1)

        elseif MVKS[i.KeyCode] and not keys_dn[i.KeyCode] then
            move_dir = move_dir + MVKS[i.KeyCode]
            keys_dn[i.KeyCode] = true
        end
    end))

    table.insert(_G.xkid_fly_evts, UIS.InputEnded:Connect(function(i, p)
        if p then return end
        if MVKS[i.KeyCode] and keys_dn[i.KeyCode] then
            move_dir = move_dir - MVKS[i.KeyCode]
            keys_dn[i.KeyCode] = nil
        end
    end))

    table.insert(_G.xkid_fly_evts, RunService.RenderStepped:Connect(function()
        if not _G.xkid_fly_rp or not parentFly then return end
        local do_fly = flyEnabled and move_dir.Magnitude > 0
        if flying ~= do_fly then
            flying = do_fly
            if humanoidFly then humanoidFly.AutoRotate = not do_fly end
            if not do_fly then
                parentFly.Velocity = Vector3.new()
                _G.xkid_fly_rp:Abort()
                return
            end
            _G.xkid_fly_rp:Fire()
        end
        if _G.xkid_fly_pt then
            _G.xkid_fly_pt.Position = parentFly.Position + 10000 * fly_dir()
        end
    end))
end

-- ════════════════════════════════════════════════
--  ⑥ TELEPORT KE PLAYER
-- ════════════════════════════════════════════════
local function teleportToPlayer(name)
    if not name or name == "" then
        Library:Notification("❌ Error", "Masukkan nama player", 2); return
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if p.Name:lower():find(name:lower(), 1, true)
            or p.DisplayName:lower():find(name:lower(), 1, true) then
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local root = getRoot()
                    if root then
                        root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                        Library:Notification("📍 TP", "→ " .. p.Name, 3)
                        return
                    end
                end
            end
        end
    end
    Library:Notification("❌ Error", "Player tidak ditemukan", 2)
end

-- Advanced: prefix matching dengan scoring
local function infer_plr(ref)
    if typeof(ref) ~= "string" then return ref end
    local best, min = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local nv = math.huge
            if     p.Name:find("^"..ref)                       then nv = 1.0*(#p.Name-#ref)
            elseif p.DisplayName:find("^"..ref)                then nv = 1.5*(#p.DisplayName-#ref)
            elseif p.Name:lower():find("^"..ref:lower())       then nv = 2.0*(#p.Name-#ref)
            elseif p.DisplayName:lower():find("^"..ref:lower())then nv = 2.5*(#p.DisplayName-#ref)
            end
            if nv < min then best=p; min=nv end
        end
    end
    return best
end

local function teleportAdvanced(ref)
    local p = infer_plr(ref)
    if not p or not p.Character then
        Library:Notification("❌ Error", "Player tidak ditemukan", 2); return
    end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
           or p.Character:FindFirstChild("Torso")
    if hrp and getChar() then
        getChar():PivotTo(hrp.CFrame * CFrame.new(0, 3, 0))
        Library:Notification("📍 TP Advanced", "→ " .. p.Name, 3)
    end
end

-- ════════════════════════════════════════════════
--  INIT FLY (setelah semua fungsi defined)
-- ════════════════════════════════════════════════
task.spawn(function()
    task.wait(1)
    init_fly()
    setup_fly_events()
end)

-- ════════════════════════════════════════════════
--  BUILD UI
-- ════════════════════════════════════════════════

-- ── TAB: MAIN ─────────────────────────────────
local MainPage = TabMain:Page("Utility", "heart")
local LeftSec  = MainPage:Section("🛠 Controls", "Left")
local RightSec = MainPage:Section("ℹ️ Info", "Right")

-- Anti AFK
LeftSec:Toggle("Anti AFK", "AntiAFKToggle", false,
    "Cegah disconnect otomatis",
    function(v)
        if v then startAntiAFK() else stopAntiAFK() end
        Library:Notification("Anti AFK", v and "ON" or "OFF", 2)
    end)

-- WalkSpeed
LeftSec:Slider("WalkSpeed", "WSSlider", 1, 500, 16,
    function(v)
        setWalkSpeed(v)
    end, "Kecepatan jalan (default 16)")

LeftSec:Button("🔁 Reset WalkSpeed", "Kembalikan ke 16",
    function()
        setWalkSpeed(16)
        Library:Notification("WalkSpeed", "Reset ke 16", 2)
    end)

-- Infinite Jump
LeftSec:Toggle("Infinite Jump", "InfJumpToggle", false,
    "Lompat terus menerus di udara",
    function(v)
        setInfiniteJump(v)
        Library:Notification("Infinite Jump", v and "ON" or "OFF", 2)
    end)

-- Respawn di posisi sama
LeftSec:Button("💀 Respawn di Posisi Sama", "Mati dan kembali ke posisi sekarang",
    function()
        respawnSamePos()
    end)

RightSec:Paragraph("Info",
    "Anti AFK: Cegah kick otomatis\n\n"..
    "WalkSpeed: Atur kecepatan jalan\nDefault = 16, Max = 500\n\n"..
    "Infinite Jump: Lompat di udara\n\n"..
    "Respawn: Mati & balik ke\nposisi yang sama")

-- ── TAB: FLY ──────────────────────────────────
local FlyPage  = TabFly:Page("Rocket Fly", "rocket")
local FlyLeft  = FlyPage:Section("⚙ Settings", "Left")
local FlyRight = FlyPage:Section("🎮 Keybinds", "Right")

FlyLeft:Slider("Kecepatan Fly", "FlySpeedSlider", 10, 500, 127,
    function(v)
        SPEED = v
        if _G.xkid_fly_rp then _G.xkid_fly_rp.MaxSpeed = SPEED end
    end, "Kecepatan terbang")

FlyLeft:Toggle("Relatif ke Karakter", "RelCharToggle", false,
    "Gerak relatif karakter, bukan kamera",
    function(v) REL_TO_CHAR = v end)

FlyLeft:Button("🔄 Reset Fly", "Init ulang jika error",
    function()
        init_fly()
        Library:Notification("Fly", "Reset ✅", 2)
    end)

FlyRight:Paragraph("Keybinds",
    "H  — Toggle Fly ON/OFF\n"..
    "G  — Toggle Anchor\n"..
    "L  — Speed ×1.5\n"..
    "K  — Speed ÷1.5\n\n"..
    "W A S D  — Maju/Mundur/Kiri/Kanan\n"..
    "E  — Naik\n"..
    "Q  — Turun")

-- ── TAB: TELEPORT ─────────────────────────────
local TpPage   = TabTP:Page("Teleport", "map-pin")
local TpLeft   = TpPage:Section("👤 Ke Player", "Left")
local TpRight  = TpPage:Section("📋 Info", "Right")

-- Daftar player online
TpLeft:Label("Teleport ke Player Online")

local tpNameSimple = ""
TpLeft:TextBox("Nama Player", "TPSimple", "",
    function(v) tpNameSimple = v end,
    "Ketik nama atau display name")

TpLeft:Button("📍 Teleport (Biasa)", "TP ke player",
    function() teleportToPlayer(tpNameSimple) end)

local tpNameAdv = ""
TpLeft:TextBox("Nama Player (Advanced)", "TPAdv", "",
    function(v) tpNameAdv = v end,
    "Cukup ketik prefix nama")

TpLeft:Button("📍 Teleport (Advanced)", "TP dengan prefix matching",
    function() teleportAdvanced(tpNameAdv) end)

-- Tombol cepat per player online
TpLeft:Button("🔄 Refresh Daftar Player", "Lihat player online di notif",
    function()
        local list = ""
        local count = 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                list = list .. "• " .. p.Name
                if p.DisplayName ~= p.Name then
                    list = list .. " (" .. p.DisplayName .. ")"
                end
                list = list .. "\n"
                count = count + 1
            end
        end
        if count == 0 then
            Library:Notification("👤 Player", "Tidak ada player lain", 3)
        else
            Library:Notification("👤 " .. count .. " Player Online", list, 8)
        end
    end)

TpRight:Paragraph("Cara Pakai",
    "Biasa: Cari nama/display name\n"..
    "Advanced: Cukup prefix\n\n"..
    "Contoh:\n"..
    "'XK' → akan TP ke 'XKID123'\n\n"..
    "TP 3 stud di atas target\n"..
    "Refresh untuk lihat siapa online")

-- ════════════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════════════
Library:Notification("🛠 XKID Utility", "Semua fitur siap!", 4)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   🛠  XKID UTILITY v1.0  — XKID HUB    ║")
print("║   Anti AFK · Fly · Teleport             ║")
print("║   WalkSpeed · Infinite Jump · Respawn   ║")
print("║   H=Fly · G=Anchor · L=Fast · K=Slow    ║")
print("╚══════════════════════════════════════════╝")
