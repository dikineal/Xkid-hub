-- AURORA UI ROBLOX GAME SCANNER
-- Requires: Aurora UI Library (loadstring from GitHub)

local AuroraUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/AuroraUI.lua"))()

-- Create Window
local Window = AuroraUI:CreateWindow({
    Title = "🔍 Game Scanner",
    Subtitle = "Universal Roblox Scanner",
    Theme = "Dark",
    Size = UDim2.new(0, 550, 0, 600),
})

-- Create Tabs
local ScanTab = Window:CreateTab("Scanner", "rbxassetid://7733658504")
local ResultsTab = Window:CreateTab("Results", "rbxassetid://7733715400")
local SettingsTab = Window:CreateTab("Settings", "rbxassetid://7733960981")

-- ========================
-- SCANNER TAB
-- ========================

ScanTab:CreateLabel("⚡ Universal Game Scanner v1.0")
ScanTab:CreateDivider()

-- Stats display
local remoteLabel = ScanTab:CreateLabel("📡 RemoteEvents/Functions: 0")
local promptLabel = ScanTab:CreateLabel("🖱️ Interactions Found: 0")
local farmLabel   = ScanTab:CreateLabel("🌾 Farm Objects Found: 0")
local statusLabel = ScanTab:CreateLabel("🔴 Status: Idle")

ScanTab:CreateDivider()

-- Scan Results Storage
local scanResults = {
    remotes = {},
    interactions = {},
    farmObjects = {}
}

-- ========================
-- MAIN SCAN FUNCTION
-- ========================
local function RunScan()
    statusLabel:SetText("🟡 Status: Scanning...")
    
    -- Reset
    scanResults.remotes = {}
    scanResults.interactions = {}
    scanResults.farmObjects = {}

    local remoteCount = 0
    local promptCount = 0
    local farmCount = 0

    for _, v in pairs(game:GetDescendants()) do

        -- Scan RemoteEvents
        if v:IsA("RemoteEvent") then
            remoteCount += 1
            table.insert(scanResults.remotes, "[RemoteEvent] " .. v:GetFullName())
        end

        -- Scan RemoteFunctions
        if v:IsA("RemoteFunction") then
            remoteCount += 1
            table.insert(scanResults.remotes, "[RemoteFunction] " .. v:GetFullName())
        end

        -- Scan Interactions
        if v:IsA("ProximityPrompt") or v:IsA("ClickDetector") then
            promptCount += 1
            table.insert(scanResults.interactions, "[" .. v.ClassName .. "] " .. v:GetFullName())
        end

        -- Scan Farm Objects
        local name = string.lower(v.Name)
        if string.find(name, "plant")
        or string.find(name, "farm")
        or string.find(name, "seed")
        or string.find(name, "crop")
        or string.find(name, "harvest") then
            farmCount += 1
            table.insert(scanResults.farmObjects, "[FarmObject] " .. v:GetFullName())
        end
    end

    -- Update Labels
    remoteLabel:SetText("📡 RemoteEvents/Functions: " .. remoteCount)
    promptLabel:SetText("🖱️ Interactions Found: " .. promptCount)
    farmLabel:SetText("🌾 Farm Objects Found: " .. farmCount)
    statusLabel:SetText("🟢 Status: Scan Complete!")

    -- Print to console
    print("========== AURORA SCAN COMPLETE ==========")
    print("Remotes Found:", remoteCount)
    print("Interactions Found:", promptCount)
    print("Farm Objects Found:", farmCount)

    -- Print details
    for _, r in ipairs(scanResults.remotes) do print(r) end
    for _, i in ipairs(scanResults.interactions) do print(i) end
    for _, f in ipairs(scanResults.farmObjects) do print(f) end

    return remoteCount, promptCount, farmCount
end

-- ========================
-- SCANNER BUTTONS
-- ========================

ScanTab:CreateButton({
    Name = "🚀 Start Full Scan",
    Callback = function()
        RunScan()
        AuroraUI:Notify({
            Title = "Scan Complete!",
            Content = "Check Results tab for details.",
            Duration = 4
        })
    end
})

ScanTab:CreateButton({
    Name = "📋 Copy Results to Clipboard",
    Callback = function()
        local output = "=== AURORA GAME SCANNER RESULTS ===\n"
        output = output .. "\n[REMOTES]\n"
        for _, v in ipairs(scanResults.remotes) do output = output .. v .. "\n" end
        output = output .. "\n[INTERACTIONS]\n"
        for _, v in ipairs(scanResults.interactions) do output = output .. v .. "\n" end
        output = output .. "\n[FARM OBJECTS]\n"
        for _, v in ipairs(scanResults.farmObjects) do output = output .. v .. "\n" end

        setclipboard(output)
        AuroraUI:Notify({
            Title = "Copied!",
            Content = "Results copied to clipboard.",
            Duration = 3
        })
    end
})

ScanTab:CreateButton({
    Name = "🔄 Reset Scanner",
    Callback = function()
        scanResults = { remotes = {}, interactions = {}, farmObjects = {} }
        remoteLabel:SetText("📡 RemoteEvents/Functions: 0")
        promptLabel:SetText("🖱️ Interactions Found: 0")
        farmLabel:SetText("🌾 Farm Objects Found: 0")
        statusLabel:SetText("🔴 Status: Idle")
    end
})

-- ========================
-- RESULTS TAB
-- ========================

ResultsTab:CreateLabel("📊 Scan Results Viewer")
ResultsTab:CreateDivider()

local filterToggle = {
    showRemotes = true,
    showInteractions = true,
    showFarm = true
}

ResultsTab:CreateToggle({
    Name = "📡 Show Remotes",
    CurrentValue = true,
    Callback = function(val)
        filterToggle.showRemotes = val
    end
})

ResultsTab:CreateToggle({
    Name = "🖱️ Show Interactions",
    CurrentValue = true,
    Callback = function(val)
        filterToggle.showInteractions = val
    end
})

ResultsTab:CreateToggle({
    Name = "🌾 Show Farm Objects",
    CurrentValue = true,
    Callback = function(val)
        filterToggle.showFarm = val
    end
})

ResultsTab:CreateDivider()

ResultsTab:CreateButton({
    Name = "📤 Print Filtered Results",
    Callback = function()
        print("===== FILTERED RESULTS =====")
        if filterToggle.showRemotes then
            print("[REMOTES - " .. #scanResults.remotes .. "]")
            for _, v in ipairs(scanResults.remotes) do print(v) end
        end
        if filterToggle.showInteractions then
            print("[INTERACTIONS - " .. #scanResults.interactions .. "]")
            for _, v in ipairs(scanResults.interactions) do print(v) end
        end
        if filterToggle.showFarm then
            print("[FARM OBJECTS - " .. #scanResults.farmObjects .. "]")
            for _, v in ipairs(scanResults.farmObjects) do print(v) end
        end
        AuroraUI:Notify({
            Title = "Printed!",
            Content = "Filtered results printed to console.",
            Duration = 3
        })
    end
})

-- ========================
-- SETTINGS TAB
-- ========================

SettingsTab:CreateLabel("⚙️ Scanner Settings")
SettingsTab:CreateDivider()

SettingsTab:CreateToggle({
    Name = "🔔 Auto-Notify on Scan",
    CurrentValue = true,
    Callback = function(val)
        print("Auto-Notify:", val)
    end
})

SettingsTab:CreateToggle({
    Name = "🖨️ Print to Console",
    CurrentValue = true,
    Callback = function(val)
        print("Console Print:", val)
    end
})

SettingsTab:CreateSlider({
    Name = "⏱️ Scan Delay (ms)",
    Range = {0, 500},
    Increment = 10,
    CurrentValue = 0,
    Callback = function(val)
        print("Scan Delay set to:", val .. "ms")
    end
})

SettingsTab:CreateDivider()

SettingsTab:CreateButton({
    Name = "❌ Destroy UI",
    Callback = function()
        AuroraUI:Destroy()
    end
})

-- Startup Notification
AuroraUI:Notify({
    Title = "Aurora Scanner Ready",
    Content = "Press 'Start Full Scan' to begin.",
    Duration = 5
})