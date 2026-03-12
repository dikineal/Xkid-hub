-- 🌾 INDO FARMER — AFK ONLY VERSION

-- LOAD UI
local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Win = Library:Window(
    "Indo Farmer",
    "sprout",
    "AFK ONLY",
    false
)

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- FLAG
_G.AntiAFK = false
local antiAFKConn

-- CHARACTER
local function getHum()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ANTI AFK LOOP
local function startAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect() end

    local last = tick()

    antiAFKConn = RunService.Heartbeat:Connect(function()
        if not _G.AntiAFK then
            antiAFKConn:Disconnect()
            antiAFKConn = nil
            return
        end

        if tick() - last >= 120 then
            last = tick()

            local hum = getHum()
            if hum then
                hum.Jump = true
            end
        end
    end)
end

-- UI
Win:TabSection("Utility")
local TabAFK = Win:Tab("AFK", "clock")

local Page = TabAFK:Page("Anti AFK", "clock")
local Sec = Page:Section("AFK System", "Left")

Sec:Toggle("Anti AFK", "AntiAFKToggle", false,
"Jump setiap 2 menit agar tidak kick",
function(v)
    _G.AntiAFK = v

    if v then
        startAntiAFK()
        Library:Notification("AFK", "Anti AFK ON", 3)
    else
        Library:Notification("AFK", "Anti AFK OFF", 3)
    end
end)

-- INIT
Library:Notification("Indo Farmer", "AFK Mode Loaded", 5)
Library:ConfigSystem(Win)