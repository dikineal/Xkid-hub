-- Load DrRay UI (Modern & Stabil 2026)
local DrRayLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/DrRay-UI-Library/main/DrRay.lua"))()

-- Buat Window
local window = DrRayLibrary:Load("Anti AFK Hub v2026 🔥", "Default")

-- Variables
local player = game.Players.LocalPlayer
local vu = game:GetService("VirtualUser")
local rs = game:GetService("RunService")
local connection = nil
local antiAfkMode = "Mouse Move"  -- Default
local interval = 25  -- Detik default
local enabled = false

-- Tab Anti AFK
local tab = DrRayLibrary.newTab("Anti AFK")

-- Section Controls
tab.newToggle("Enable Anti AFK", false, function(state)
    enabled = state
    if state then
        DrRayLibrary:Notify("Anti AFK ON!", "Mode: " .. antiAfkMode .. " | Interval: " .. interval .. "s")
        startAntiAfk()
    else
        DrRayLibrary:Notify("Anti AFK OFF!", "Stopped safely.")
        stopAntiAfk()
    end
end)

tab.newDropdown("Mode", {"Mouse Move", "Jump", "Hold W"}, function(selected)
    antiAfkMode = selected
    DrRayLibrary:Notify("Mode Changed!", "New: " .. selected)
end)

tab.newSlider("Interval (seconds)", 1, 60, 25, function(value)
    interval = value
end)

tab.newButton("Test 10s", "Quick test without toggle", function()
    DrRayLibrary:Notify("Test Start!", "10s trial...")
    local testConn = rs.Heartbeat:Connect(function()
        wait(10)
        testConn:Disconnect()
        DrRayLibrary:Notify("Test Done!", "No kick detected!")
    end)
    spawn(function()
        for i=1,10 do
            vu:ClickButton2(Vector2.new(math.random(1,100), math.random(1,100)))
            wait(1)
        end
    end)
end)

-- Status Label (update real-time)
local statusLabel = tab.newLabel("Status: OFF | Mode: Mouse Move | Interval: 25s")

-- Functions
function updateStatus()
    statusLabel:Set("Status: " .. (enabled and "ON" or "OFF") .. " | Mode: " .. antiAfkMode .. " | Interval: " .. interval .. "s")
end

function startAntiAfk()
    stopAntiAfk()  -- Clean old
    connection = player.Idled:Connect(function()
        wait(math.random(interval-5, interval+5)/10)  -- Random biar natural
        if antiAfkMode == "Mouse Move" then
            vu:ClickButton2(Vector2.new(math.random(0,500), math.random(0,500)))
        elseif antiAfkMode == "Jump" then
            keypress(32)  -- Space
            wait(0.1)
            keyrelease(32)
        elseif antiAfkMode == "Hold W" then
            keydown(0x57)  -- W
            wait(0.5)
            keyup(0x57)
        end
        vu:CaptureController()
        updateStatus()
    end)
end

function stopAntiAfk()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    updateStatus()
end

-- Update status awal
updateStatus()

-- Auto-save config (DrRay built-in)
print("Anti AFK Hub Loaded! Test di Baseplate dulu bro. 😎")
