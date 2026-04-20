--[[
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      ██╗  ██╗██╗  ██╗██╗██████╗     ███████╗ ██████╗           ║
║      ╚██╗██╔╝██║ ██╔╝██║██╔══██╗    ██╔════╝██╔════╝           ║
║       ╚███╔╝ █████╔╝ ██║██║  ██║    ███████╗██║                 ║
║       ██╔██╗ ██╔═██╗ ██║██║  ██║    ╚════██║██║                 ║
║      ██╔╝ ██╗██║  ██╗██║██████╔╝    ███████║╚██████╗           ║
║      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═════╝     ╚══════╝ ╚═════╝           ║
║                                                                  ║
║                  P R E M I U M   E D I T I O N                  ║
║                     Powered by WindUI                            ║
╚══════════════════════════════════════════════════════════════════╝

  Optimasi v3.1:
  • Anti Re-Execute (Mencegah UI Ganda)
  • Manajemen Koneksi (Mencegah Lag Akumulatif)
  • Peningkatan Validasi Karakter & Humanoid
]]

-- ══════════════════════════════════════════════════════════════
--  ANTI RE-EXECUTE & CLEANUP (Mencegah duplikasi sistem)
-- ══════════════════════════════════════════════════════════════
if getgenv().XKID_Init then
    pcall(function()
        if game.CoreGui:FindFirstChild("WindUI") then game.CoreGui.WindUI:Destroy() end
        if game.Players.LocalPlayer.PlayerGui:FindFirstChild("_XKIDEsp") then game.Players.LocalPlayer.PlayerGui._XKIDEsp:Destroy() end
        for _, conn in pairs(getgenv().XKID_Connections or {}) do conn:Disconnect() end
    end)
end
getgenv().XKID_Init = true
getgenv().XKID_Connections = {}

-- ══════════════════════════════════════════════════════════════
--  LOAD & SERVICES
-- ══════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players     = game:GetService("Players")
local RS          = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting    = game:GetService("Lighting")
local TPService   = game:GetService("TeleportService")
local LP          = Players.LocalPlayer
local Cam         = workspace.CurrentCamera
local onMobile    = not UIS.KeyboardEnabled

-- ══════════════════════════════════════════════════════════════
--  STATE
-- ══════════════════════════════════════════════════════════════
local State = {
    Move     = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly      = { active = false, bv = nil, bg = nil, _keys = {} },
    Fling    = { active = false, power = 1000000 },
    SoftFling= { active = false, power = 4000 },
    Teleport = { selectedTarget = "" },
    Security = { afkConn = nil },
    Cinema   = { active = false },
    Spectate = { hideName = false },
    ESP = {
        active          = false,
        cache           = {},
        boxMode         = "Corner",
        tracerMode      = "Bottom",
        maxDrawDistance = 300,
        showDistance    = true,
        showNickname    = true,
        boxColor_N      = Color3.fromRGB(0, 255, 150),
        boxColor_S      = Color3.fromRGB(255, 0, 100),
        tracerColor_N   = Color3.fromRGB(0, 200, 255),
        tracerColor_S   = Color3.fromRGB(255, 50, 50),
        nameColor       = Color3.fromRGB(255, 255, 255),
    },
}

-- ══════════════════════════════════════════════════════════════
--  HELPERS (Ditambahkan proteksi nil-check)
-- ══════════════════════════════════════════════════════════════
local function getRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function notify(title, content, dur)
    WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 })
end

-- ══════════════════════════════════════════════════════════════
--  ESP ENGINE (Optimal & Clean)
-- ══════════════════════════════════════════════════════════════
local function getESPGui()
    local sg = LP.PlayerGui:FindFirstChild("_XKIDEsp")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name            = "_XKIDEsp"
        sg.ResetOnSpawn    = false
        sg.DisplayOrder    = 999
        sg.Parent          = LP.PlayerGui
    end
    return sg
end

local function drawLine(p1, p2, thick, color)
    local dist = (p1 - p2).Magnitude
    if dist < 1 then return nil end
    local f = Instance.new("Frame")
    f.BackgroundColor3 = color
    f.BorderSizePixel  = 0
    f.Position  = UDim2.new(0, (p1.X + p2.X)/2 - dist/2, 0, (p1.Y + p2.Y)/2 - thick/2)
    f.Size      = UDim2.new(0, dist, 0, thick)
    f.Rotation  = math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X))
    f.ZIndex    = 10
    f.Parent    = getESPGui()
    return f
end

local function renderESP(player)
    if not State.ESP.active or player == LP then return end
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local myRoot = getRoot()
    if not myRoot then return end
    if (myRoot.Position - hrp.Position).Magnitude > State.ESP.maxDrawDistance then return end

    local sp, on = Cam:WorldToViewportPoint(hrp.Position)
    if not on then return end

    if not State.ESP.cache[player] then
        State.ESP.cache[player] = { renders = {} }
    end
    local cache = State.ESP.cache[player]

    -- Hapus render lama
    for _, r in pairs(cache.renders) do if r.Parent then r:Destroy() end end
    cache.renders = {}

    -- Logika Box & Text Sederhana (Untuk Performa)
    if State.ESP.boxMode ~= "OFF" then
        local top = Cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
        local bot = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local h = math.abs(top.Y - bot.Y)
        local w = h * 0.6
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 200, 0, 20)
        label.Position = UDim2.new(0, sp.X - 100, 0, sp.Y - (h/2) - 20)
        label.BackgroundTransparency = 1
        label.TextColor3 = State.ESP.nameColor
        label.Text = State.ESP.showNickname and player.DisplayName or ""
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.Parent = getESPGui()
        table.insert(cache.renders, label)
    end
end

-- ══════════════════════════════════════════════════════════════
--  WINDOW & TABS
-- ══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title       = "XKID PREMIUM V3.1",
    Author      = "by XKID",
    Folder      = "XKID_V3",
    Icon        = "shield",
    Theme       = "Rose",
    Size        = UDim2.fromOffset(650, 450),
    OpenButton  = { Enabled = true, Draggable = true }
})

local T_PL = Window:Tab({ Title = "Karakter", Icon = "user" })
local secMov = T_PL:Section({ Title = "Pergerakan", Opened = true })

secMov:Slider({
    Title = "Kecepatan Jalan",
    Value = { Min = 16, Max = 500, Default = 16 },
    Callback = function(v)
        State.Move.ws = v
        local hum = getHum()
        if hum then hum.WalkSpeed = v end
    end,
})

secMov:Toggle({
    Title = "Noclip",
    Desc = "Tembus objek/tembok",
    Value = false,
    Callback = function(v) State.Move.ncp = v end
})

-- ══════════════════════════════════════════════════════════════
--  BACKEND LOOPS (Pusat Logika)
-- ══════════════════════════════════════════════════════════════

-- Loop Pergerakan & Fisika
local mainLoop = RS.Heartbeat:Connect(function()
    local char = LP.Character
    local hum = getHum()
    local hrp = getRoot()

    if hum and hrp then
        -- Konsistensi Speed
        if hum.WalkSpeed ~= State.Move.ws then hum.WalkSpeed = State.Move.ws end
        
        -- Noclip
        if State.Move.ncp then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        
        -- Fling Logic (Hanya jika aktif)
        if State.Fling.active then
            hrp.AssemblyAngularVelocity = Vector3.new(0, State.Fling.power, 0)
        end
    end
end)
table.insert(getgenv().XKID_Connections, mainLoop)

-- Loop ESP
local espLoop = RS.RenderStepped:Connect(function()
    if State.ESP.active then
        for _, p in pairs(Players:GetPlayers()) do
            renderESP(p)
        end
    end
end)
table.insert(getgenv().XKID_Connections, espLoop)

-- Anti-AFK
local antiAfk = LP.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
table.insert(getgenv().XKID_Connections, antiAfk)

-- ══════════════════════════════════════════════════════════════
--  FINISH
-- ══════════════════════════════════════════════════════════════
notify("XKID SCRIPT", "Optimasi v3.1 Berhasil Dimuat!", 3)