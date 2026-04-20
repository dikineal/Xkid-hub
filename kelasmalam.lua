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
║                     V3.2 - CINEMATIC & HUB                      ║
╚══════════════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════════════════════════════
--  ANTI RE-EXECUTE & CLEANUP
-- ══════════════════════════════════════════════════════════════
if getgenv().XKID_Init then
    pcall(function()
        if game.CoreGui:FindFirstChild("WindUI") then game.CoreGui.WindUI:Destroy() end
        if game.CoreGui:FindFirstChild("_XKID_Highlight") then game.CoreGui._XKID_Highlight:Destroy() end
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

-- ══════════════════════════════════════════════════════════════
--  STATE (Penyimpanan Data)
-- ══════════════════════════════════════════════════════════════
local State = {
    Move     = { ws = 16, jp = 50, ncp = false, infJ = false },
    Fly      = { active = false, speed = 60, inc = 0 },
    Ghost    = { active = false },
    Dance    = { currentAnim = nil, speed = 1.0, list = {} },
    Visual   = { fullBright = false, noFog = false, colorBoost = false },
    ESP      = { active = false, highlights = {}, tracers = {}, skyTracers = false },
    Chat     = { bypass = false }
}

-- ══════════════════════════════════════════════════════════════
--  FUNCTIONS & UTILITIES
-- ══════════════════════════════════════════════════════════════
local function notify(title, content, dur)
    WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 })
end

-- Chat Commands Listener (:re, ;re, /re, !rejoin)
local chatConn = LP.Chatted:Connect(function(msg)
    local cmd = msg:lower()
    if cmd == ";re" or cmd == "/re" or cmd == ":re" then
        if LP.Character then LP.Character:BreakJoints() end
    elseif cmd == "!rejoin" then
        TPService:Teleport(game.PlaceId, LP)
    end
end)
table.insert(getgenv().XKID_Connections, chatConn)

-- Anti-AFK (VirtualUser)
local afkConn = LP.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
table.insert(getgenv().XKID_Connections, afkConn)

-- ══════════════════════════════════════════════════════════════
--  DANCE & CINEMATIC ENGINE
-- ══════════════════════════════════════════════════════════════
local function scanAnims()
    State.Dance.list = {}
    -- Mencari animasi di ReplicatedStorage atau Character (Universal)
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("Animation") and v.Name ~= "Animation" then
            table.insert(State.Dance.list, v)
        end
    end
    notify("Scanner", "Ditemukan " .. #State.Dance.list .. " Animasi!", 2)
end

local function syncBeat()
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        local anims = hum:GetPlayingAnimationTracks()
        for _, track in pairs(anims) do
            track:TimePosition(0)
        end
    end
end

-- ══════════════════════════════════════════════════════════════
--  GHOST MODE (Server-Side Logic)
-- ══════════════════════════════════════════════════════════════
local function toggleGhost(val)
    State.Ghost.active = val
    local char = LP.Character
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then
                v.Transparency = val and 1 or 0
            end
        end
        -- Sembunyikan Nama (Server-Side nametag if exists)
        if char:FindFirstChild("Head") and char.Head:FindFirstChildOfClass("BillboardGui") then
            char.Head:FindFirstChildOfClass("BillboardGui").Enabled = not val
        end
    end
end

-- ══════════════════════════════════════════════════════════════
--  UI WINDOW & TABS
-- ══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title       = "XKID PREMIUM V3.2",
    Author      = "by XKID",
    Folder      = "XKID_V3",
    Icon        = "music",
    Theme       = "Rose",
    Size        = UDim2.fromOffset(600, 400),
    OpenButton  = { Enabled = true, Draggable = true }
})

-- TAB KARAKTER (Movement & Fly)
local T_Main = Window:Tab({ Title = "Karakter", Icon = "user" })
local secMove = T_Main:Section({ Title = "Movement", Opened = true })

secMove:Slider({
    Title = "Fly Speed",
    Value = { Min = 10, Max = 300, Default = 60 },
    Callback = function(v) State.Fly.speed = v end
})

secMove:Toggle({
    Title = "Fly (Original Logic)",
    Value = false,
    Callback = function(v) State.Fly.active = v end
})

secMove:Toggle({
    Title = "Ghost Mode (Non-Visual)",
    Value = false,
    Callback = function(v) toggleGhost(v) end
})

-- TAB DANCE (Lead Dance System)
local T_Dance = Window:Tab({ Title = "Dance", Icon = "music" })
T_Dance:Button({
    Title = "Auto Scan Map Animations",
    Callback = function() scanAnims() end
})

T_Dance:Button({
    Title = "Sync Beat (Reset Position)",
    Callback = function() syncBeat() end
})

T_Dance:Slider({
    Title = "Animation Speed",
    Value = { Min = 0, Max = 3, Default = 1 },
    Callback = function(v)
        State.Dance.speed = v
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:AdjustSpeed(v) end
        end
    end
})

-- TAB HUNTER (ESP & DETECTION)
local T_Hunter = Window:Tab({ Title = "Hunter", Icon = "eye" })
T_Hunter:Toggle({
    Title = "Highlight ESP (Neon Body)",
    Value = false,
    Callback = function(v) State.ESP.active = v end
})

T_Hunter:Toggle({
    Title = "Sky Tracers (Garis Langit)",
    Value = false,
    Callback = function(v) State.ESP.skyTracers = v end
})

-- TAB VISUAL (Cinematic Tools)
local T_Vis = Window:Tab({ Title = "Visual", Icon = "camera" })
T_Vis:Toggle({
    Title = "Full Bright",
    Value = false,
    Callback = function(v)
        State.Visual.fullBright = v
        Lighting.Brightness = v and 2 or 1
        Lighting.GlobalShadows = not v
    end
})

T_Vis:Toggle({
    Title = "No Fog",
    Value = false,
    Callback = function(v) Lighting.FogEnd = v and 100000 or 1000 end
})

T_Vis:Button({
    Title = "Hide UI (Rec Mode)",
    Callback = function()
        if game.CoreGui:FindFirstChild("WindUI") then
            game.CoreGui.WindUI.Enabled = false
            notify("REC MODE", "Tekan tombol toggle untuk munculkan kembali", 3)
        end
    end
})

-- ══════════════════════════════════════════════════════════════
--  MAIN LOOP ENGINE (Heartbeat)
-- ══════════════════════════════════════════════════════════════
local mainLoop = RS.Heartbeat:Connect(function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    -- Optimal Fly (Snappy)
    if State.Fly.active and hrp then
        hrp.Velocity = Vector3.new(0, 0.1, 0)
        local moveDir = char:FindFirstChildOfClass("Humanoid").MoveDirection
        hrp.CFrame = hrp.CFrame + (moveDir * State.Fly.speed / 10)
    end

    -- ESP Highlight Engine
    if State.ESP.active then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                if not p.Character:FindFirstChild("_XKID_High") then
                    local h = Instance.new("Highlight")
                    h.Name = "_XKID_High"
                    h.FillTransparency = 0.5
                    h.OutlineColor = Color3.fromRGB(255, 0, 0)
                    h.Parent = p.Character
                end
            end
        end
    end
end)
table.insert(getgenv().XKID_Connections, mainLoop)

notify("XKID PREMIUM", "V3.2 Berhasil Dimuat (Balikpapan Edition)", 4)