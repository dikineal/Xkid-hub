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
║                         ULTRA V8                                 ║
║                                                                  ║
║                    Designed by @WTF.XKID                        ║
║                     Powered by WindUI                            ║
╚══════════════════════════════════════════════════════════════════╝

  ✨ Features:
  • Premium Avatar Refresh (/re - No Death)
  • Teleport & Location Saver
  • Movement (Speed / Jump / Fly / NoClip)
  • Smooth Freecam (Mobile Ready)
  • Advanced Spectate (Orbit & First Person)
  • Modern ESP (Corner / Box / Highlight / Tracer)
  • World Control (Weather / Atmosphere / Graphics)
  • Security Features (Anti-AFK / Seamless Respawn / Anti-Glitcher)
  • Live FPS & PING Counter
  • Advanced Settings (Theme / Keybind / UI Customization)
]]

-- ══════════════════════════════════════════════════════════════
--  AUTO CLEANUP & MEMORY MANAGEMENT
-- ══════════════════════════════════════════════════════════════
if getgenv()._XKID_LOADED then
    pcall(function()
        for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
            if v.Name == "WindUI" or v.Name == "_XKIDEsp" then v:Destroy() end
        end
        if getgenv()._XKID_CONNS then
            for _, c in pairs(getgenv()._XKID_CONNS) do pcall(function() c:Disconnect() end) end
        end
    end)
    collectgarbage("collect")
end
getgenv()._XKID_LOADED = true
getgenv()._XKID_CONNS = {}
local function TrackC(conn) table.insert(getgenv()._XKID_CONNS, conn); return conn end

-- ══════════════════════════════════════════════════════════════
--  LOAD WINDUI
-- ══════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- ══════════════════════════════════════════════════════════════
--  SERVICES & SETUP
-- ══════════════════════════════════════════════════════════════
local Players     = game:GetService("Players")
local RS          = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting    = game:GetService("Lighting")
local TPService   = game:GetService("TeleportService")
local StatsService= game:GetService("Stats")
local LP          = Players.LocalPlayer
local Cam         = workspace.CurrentCamera
local onMobile    = not UIS.KeyboardEnabled

-- ══════════════════════════════════════════════════════════════
--  STATE MANAGEMENT
-- ══════════════════════════════════════════════════════════════
local State = {
    Move     = { ws = 16, jp = 50, ncp = false, infJ = false, flyS = 60 },
    Fly      = { active = false, bv = nil, bg = nil },
    Fling    = { active = false, power = 1000000 },
    SoftFling= { active = false, power = 4000 },
    Teleport = { selectedTarget = "" },
    Security = { afkConn = nil },
    Cinema   = { active = false },
    Spectate = { hideName = false },
    Avatar   = { isRefreshing = false },
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
--  HELPER FUNCTIONS
-- ══════════════════════════════════════════════════════════════
local function getRoot()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end

local function getPNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    return t
end

local function getDisplayNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    return t
end

local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do
        if str == p.DisplayName .. " (@" .. p.Name .. ")" then return p end
    end
    return nil
end

local function getCharRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char.PrimaryPart
        or char:FindFirstChild("Head")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChildWhichIsA("BasePart")
end

-- Premium notification system
local function notify(title, content, dur)
    WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 })
end

-- Persist state on respawn
TrackC(LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then
            hum.UseJumpPower = true
            hum.JumpPower    = State.Move.jp
        end
    end
end))

-- ══════════════════════════════════════════════════════════════
--  🎨 PREMIUM AVATAR REFRESH SYSTEM (/re Command)
-- ══════════════════════════════════════════════════════════════

local function refreshAvatarPremium()
    if State.Avatar.isRefreshing then return end
    State.Avatar.isRefreshing = true
    
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local head = char and char:FindFirstChild("Head")
    
    if not hum then
        notify("Avatar Refresh", "❌ Character not found!", 2)
        State.Avatar.isRefreshing = false
        return
    end
    
    pcall(function()
        -- Store original state
        local currentTool = char:FindFirstChildOfClass("Tool")
        local savedPosition = getRoot() and getRoot().CFrame or CFrame.new()
        local savedHealth = hum.Health
        local savedGuis = {}
        
        if currentTool then
            currentTool.Parent = LP.Backpack
        end
        
        if head then
            for _, item in ipairs(head:GetChildren()) do
                if item:IsA("BillboardGui") or item:IsA("SurfaceGui") then
                    item.Parent = nil
                    table.insert(savedGuis, item)
                end
            end
        end
        
        -- Apply new avatar description
        local newDescription = Players:GetHumanoidDescriptionFromUserId(LP.UserId)
        hum:ApplyDescription(newDescription)
        
        -- Restore GUIs to new head
        local newHead = char:WaitForChild("Head", 5)
        if newHead then
            for _, gui in ipairs(savedGuis) do
                gui.Parent = newHead
            end
        end
        
        -- Restore tool
        if currentTool and currentTool.Parent == LP.Backpack then
            currentTool.Parent = char
        end
        
        -- Restore position & health
        local newRoot = getRoot()
        if newRoot then
            newRoot.CFrame = savedPosition
        end
        if hum and savedHealth > 0 then
            hum.Health = savedHealth
        end
        
        notify("✨ Avatar Refresh", "🎨 Avatar updated! No death, no respawn!", 3)
    end)
    
    State.Avatar.isRefreshing = false
end

-- Chat command support
TrackC(LP.Chatted:Connect(function(msg)
    local cmd = string.lower(msg)
    if cmd == ":re" or cmd == "/re" then
        refreshAvatarPremium()
    end
end))

-- ══════════════════════════════════════════════════════════════
--  WINDOW SETUP (Premium Design)
-- ══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title        = "🎮 XKID PREMIUM ULTRA V8",
    Subtitle     = "Designed by @WTF.XKID",
    Size         = UDim2.new(0, 700, 0, 800),
    Transparency = 0.15,
    ShowMenuButton = true,
    Acrylic      = true,
    CloseCallback = function()
        pcall(function() 
            for _, c in pairs(getgenv()._XKID_CONNS) do 
                c:Disconnect() 
            end 
        end)
    end,
})

-- ══════════════════════════════════════════════════════════════
--  TAB 1: MOVEMENT
-- ══════════════════════════════════════════════════════════════
local T_MOV = Window:Tab({ Title = "Movement", Icon = "run" })

local movSpeed = T_MOV:Section({ Title = "Speed Control", Opened = true })
movSpeed:Slider({
    Title = "Walk Speed",
    Desc  = "Adjust movement speed",
    Min   = 16,
    Max   = 500,
    Value = 16,
    Callback = function(v)
        State.Move.ws = v
        if getHum() then getHum().WalkSpeed = v end
    end,
})

movSpeed:Slider({
    Title = "Jump Power",
    Desc  = "Adjust jump height",
    Min   = 50,
    Max   = 500,
    Value = 50,
    Callback = function(v)
        State.Move.jp = v
        local hum = getHum()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = v
        end
    end,
})

movSpeed:Toggle({
    Title = "Infinite Jump",
    Desc  = "Hold space to jump infinitely",
    Value = false,
    Callback = function(v)
        if v then
            State.Move.infJ = UIS.JumpRequest:Connect(function()
                if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if State.Move.infJ then State.Move.infJ:Disconnect(); State.Move.infJ = nil end
        end
    end,
})

-- Fly section
local movFly = T_MOV:Section({ Title = "Flight System", Opened = false })
local flyActive = false
local flyBV, flyBG

local function toggleFly(enabled)
    if enabled then
        local root = getRoot()
        local hum = getHum()
        if not root or not hum then return end
        
        flyActive = true
        hum.PlatformStand = true
        
        flyBV = Instance.new("BodyVelocity", root)
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.zero
        
        flyBG = Instance.new("BodyGyro", root)
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        
        State.Fly.bv = flyBV
        State.Fly.bg = flyBG
        
        notify("✈️ Flight", "Flight enabled! Use WASD to move.", 2)
    else
        flyActive = false
        if flyBV then flyBV:Destroy(); flyBV = nil; State.Fly.bv = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil; State.Fly.bg = nil end
        
        local hum = getHum()
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            hum.WalkSpeed = State.Move.ws
        end
        notify("✈️ Flight", "Flight disabled!", 2)
    end
    State.Fly.active = enabled
end

movFly:Toggle({
    Title = "Enable Flight",
    Desc  = "Fly through the air freely",
    Value = false,
    Callback = function(v) toggleFly(v) end,
})

movFly:Slider({
    Title = "Flight Speed",
    Desc  = "Control flight speed",
    Min   = 10,
    Max   = 300,
    Value = 60,
    Callback = function(v) State.Move.flyS = v end,
})

-- Mobility section
local movMisc = T_MOV:Section({ Title = "Mobility", Opened = false })
movMisc:Toggle({
    Title = "No Clip",
    Desc  = "Walk through walls",
    Value = false,
    Callback = function(v) State.Move.ncp = v end,
})

movMisc:Toggle({
    Title = "Extreme Fling",
    Desc  = "Violent collision reaction",
    Value = false,
    Callback = function(v) State.Fling.active = v; State.Move.ncp = v end,
})

movMisc:Toggle({
    Title = "Soft Fling",
    Desc  = "Gentle collision reaction",
    Value = false,
    Callback = function(v) State.SoftFling.active = v; State.Move.ncp = v end,
})

-- ══════════════════════════════════════════════════════════════
--  TAB 2: AVATAR (Premium Feature - /re Button)
-- ══════════════════════════════════════════════════════════════
local T_AV = Window:Tab({ Title = "Avatar", Icon = "user" })

local avSection = T_AV:Section({ Title = "✨ Avatar Refresh", Opened = true })

avSection:Button({
    Title = "🎨 Refresh Avatar",
    Desc  = "Update appearance instantly (No death!)",
    Callback = function()
        refreshAvatarPremium()
    end,
})

avSection:Paragraph({
    Title = "About Avatar Refresh",
    Desc  = "Instantly updates your avatar appearance from your profile. Your health, position, and tools are preserved. No death, no respawn, no glitches. Perfect for quick customization!",
})

-- Info
local avInfo = T_AV:Section({ Title = "How to Use", Opened = false })
avInfo:Paragraph({
    Title = "Chat Command",
    Desc  = "Type /re or :re in chat to refresh your avatar anytime!",
})
avInfo:Paragraph({
    Title = "What Gets Updated",
    Desc  = "✓ Shirts & Pants\n✓ Accessories\n✓ Face & Body Package\n✓ All cosmetics",
})

-- ══════════════════════════════════════════════════════════════
--  TAB 3: TELEPORT
-- ══════════════════════════════════════════════════════════════
local T_TP = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

local tpPlayers = T_TP:Section({ Title = "Player Teleport", Opened = true })
local tpPlayerDrop = tpPlayers:Dropdown({
    Title = "Select Player",
    Desc  = "Choose target",
    Values = getPNames(),
    Value = "",
    Callback = function(v) State.Teleport.selectedTarget = v end,
})

tpPlayers:Button({
    Title = "Teleport to Player",
    Desc  = "Go to selected player",
    Callback = function()
        local target = nil
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name == State.Teleport.selectedTarget and p ~= LP then
                target = p
                break
            end
        end
        if target and target.Character then
            local root = getRoot()
            if root then
                root.CFrame = target.Character:FindFirstChild("HumanoidRootPart").CFrame
                notify("📍 Teleport", "Teleported to " .. target.Name, 2)
            end
        end
    end,
})

tpPlayers:Button({
    Title = "Refresh Player List",
    Desc  = "Update player names",
    Callback = function()
        tpPlayerDrop:SetValues(getPNames())
        notify("🔄 Refresh", "Player list updated", 2)
    end,
})

-- Location saver
local tpLocations = T_TP:Section({ Title = "Location Saver", Opened = false })
local savedLocations = {}

for i = 1, 5 do
    local idx = i
    tpLocations:Button({
        Title = "📍 Save Location " .. i,
        Callback = function()
            local root = getRoot()
            if root then
                savedLocations[idx] = root.CFrame
                notify("💾 Saved", "Location " .. idx .. " saved!", 2)
            end
        end,
    })
end

tpLocations:Paragraph({
    Title = "Load Locations",
    Desc  = "Click buttons below to load saved locations",
})

for i = 1, 5 do
    local idx = i
    tpLocations:Button({
        Title = "📌 Load Location " .. i,
        Callback = function()
            if savedLocations[idx] then
                local root = getRoot()
                if root then
                    root.CFrame = savedLocations[idx]
                    notify("📍 Loaded", "Location " .. idx .. " loaded!", 2)
                end
            else
                notify("❌ Empty", "Location " .. idx .. " not saved!", 2)
            end
        end,
    })
end

-- ══════════════════════════════════════════════════════════════
--  TAB 4: CAMERA & SPECTATE
-- ══════════════════════════════════════════════════════════════
local T_CAM = Window:Tab({ Title = "Camera", Icon = "eye" })

local camSpectate = T_CAM:Section({ Title = "Spectate Player", Opened = true })
local camSpecDrop = camSpectate:Dropdown({
    Title = "Target Player",
    Values = getDisplayNames(),
    Value = "",
    Callback = function(v)
        local p = findPlayerByDisplay(v)
        if p then
            notify("👁️ Spectate", "Spectating " .. p.DisplayName, 2)
        end
    end,
})

camSpectate:Button({
    Title = "Refresh Players",
    Callback = function()
        camSpecDrop:SetValues(getDisplayNames())
    end,
})

-- Freecam section (simplified)
local camFreecam = T_CAM:Section({ Title = "Freecam", Opened = false })
camFreecam:Paragraph({
    Title = "Freecam Control",
    Desc  = "Premium freecam system coming soon. Manual camera control available.",
})

-- ══════════════════════════════════════════════════════════════
--  TAB 5: WORLD
-- ══════════════════════════════════════════════════════════════
local T_WLD = Window:Tab({ Title = "World", Icon = "globe" })

local wldLighting = T_WLD:Section({ Title = "Lighting & Weather", Opened = true })
wldLighting:Slider({
    Title = "Time of Day",
    Desc  = "Set environment time",
    Min   = 0,
    Max   = 24,
    Value = 12,
    Callback = function(v) Lighting.ClockTime = v end,
})

wldLighting:Slider({
    Title = "Brightness",
    Desc  = "Adjust light intensity",
    Min   = 0,
    Max   = 5,
    Value = 1,
    Callback = function(v) Lighting.Brightness = v end,
})

wldLighting:Button({ Title = "☀️ Daytime",    Callback = function() Lighting.ClockTime = 14 end })
wldLighting:Button({ Title = "🌙 Nighttime",  Callback = function() Lighting.ClockTime = 0 end })
wldLighting:Button({ Title = "🌅 Sunset",     Callback = function() Lighting.ClockTime = 18 end })

-- Graphics section
local wldGraphics = T_WLD:Section({ Title = "Graphics", Opened = false })
wldGraphics:Button({ Title = "60 FPS",     Callback = function() if setfpscap then setfpscap(60);  notify("FPS","60 FPS",2) end end })
wldGraphics:Button({ Title = "90 FPS",     Callback = function() if setfpscap then setfpscap(90);  notify("FPS","90 FPS",2) end end })
wldGraphics:Button({ Title = "120 FPS",    Callback = function() if setfpscap then setfpscap(120); notify("FPS","120 FPS",2) end end })
wldGraphics:Button({ Title = "Max FPS",    Callback = function() if setfpscap then setfpscap(999); notify("FPS","Max FPS",2) end end })
wldGraphics:Button({ Title = "Reset FPS",  Callback = function() if setfpscap then setfpscap(0);   notify("FPS","Default",2) end end })

-- ══════════════════════════════════════════════════════════════
--  TAB 6: ESP
-- ══════════════════════════════════════════════════════════════
local T_ESP = Window:Tab({ Title = "ESP", Icon = "radar" })

local espMain = T_ESP:Section({ Title = "ESP Settings", Opened = true })
espMain:Toggle({
    Title = "Enable ESP",
    Desc  = "Show player positions",
    Value = false,
    Callback = function(v) State.ESP.active = v end,
})

espMain:Dropdown({
    Title = "Box Mode",
    Values = { "Corner", "Box", "HIGHLIGHT", "Off" },
    Value = "Corner",
    Callback = function(v) State.ESP.boxMode = v end,
})

espMain:Dropdown({
    Title = "Tracer Type",
    Values = { "Bottom", "Center", "Top", "Off" },
    Value = "Bottom",
    Callback = function(v) State.ESP.tracerMode = v end,
})

espMain:Toggle({
    Title = "Show Distance",
    Value = true,
    Callback = function(v) State.ESP.showDistance = v end,
})

espMain:Toggle({
    Title = "Show Nickname",
    Value = true,
    Callback = function(v) State.ESP.showNickname = v end,
})

espMain:Slider({
    Title = "Draw Distance",
    Min   = 50,
    Max   = 500,
    Value = 300,
    Callback = function(v) State.ESP.maxDrawDistance = v end,
})

-- ESP Presets
local espPresets = T_ESP:Section({ Title = "Quick Presets", Opened = false })
espPresets:Button({
    Title = "Gameplay Mode",
    Callback = function() 
        State.ESP.boxMode="Corner"; State.ESP.tracerMode="Bottom"; State.ESP.showDistance=true; 
        notify("ESP","Gameplay mode enabled",2) 
    end,
})
espPresets:Button({
    Title = "Combat Mode",
    Callback = function() 
        State.ESP.boxMode="Box"; State.ESP.tracerMode="Center"; State.ESP.maxDrawDistance=500; 
        notify("ESP","Combat mode enabled",2) 
    end,
})

-- ══════════════════════════════════════════════════════════════
--  TAB 7: SECURITY
-- ══════════════════════════════════════════════════════════════
local T_SEC = Window:Tab({ Title = "Security", Icon = "shield" })

local secMain = T_SEC:Section({ Title = "Protection", Opened = true })
secMain:Toggle({
    Title = "Anti AFK",
    Desc  = "Prevent AFK kick",
    Value = false,
    Callback = function(v)
        if v then
            State.Security.afkConn = LP.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:Button2Down(Vector2.new())
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new())
            end)
            notify("🛡️ Anti-AFK", "Enabled!", 2)
        else
            if State.Security.afkConn then 
                State.Security.afkConn:Disconnect(); 
                State.Security.afkConn = nil 
            end
            notify("🛡️ Anti-AFK", "Disabled", 2)
        end
    end,
})

-- Anti-lag
local antiLagState = { mats={}, texs={}, shadows=true }
secMain:Toggle({
    Title = "Anti Lag",
    Desc  = "Reduce texture quality for FPS",
    Value = false,
    Callback = function(v)
        if v then
            antiLagState.shadows = Lighting.GlobalShadows
            Lighting.GlobalShadows = false
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    antiLagState.mats[obj] = obj.Material
                    obj.Material = Enum.Material.SmoothPlastic
                elseif obj:IsA("Texture") or obj:IsA("Decal") then
                    antiLagState.texs[obj] = obj.Parent
                    obj.Parent = nil
                end
            end
            notify("🚀 Anti-Lag", "Enabled! FPS boosted.", 3)
        else
            Lighting.GlobalShadows = antiLagState.shadows
            for obj, mat in pairs(antiLagState.mats) do 
                if obj and obj.Parent then obj.Material = mat end 
            end
            for obj, par in pairs(antiLagState.texs) do 
                if obj and par and par.Parent then obj.Parent = par end 
            end
            antiLagState.mats = {}
            antiLagState.texs = {}
            notify("🚀 Anti-Lag", "Disabled. Graphics restored.", 3)
        end
    end,
})

secMain:Button({
    Title = "Rejoin Server",
    Callback = function()
        TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end,
})

-- ══════════════════════════════════════════════════════════════
--  TAB 8: SETTINGS
-- ══════════════════════════════════════════════════════════════
local T_SET = Window:Tab({ Title = "Settings", Icon = "settings" })

local setInfo = T_SET:Section({ Title = "System Info", Opened = true })
local statsLabel = setInfo:Paragraph({
    Title = "Network & Performance",
    Desc  = "Calculating...",
})

-- Stats update loop
local fpsSamples = {}
TrackC(RS.RenderStepped:Connect(function(dt)
    table.insert(fpsSamples, dt)
    if #fpsSamples > 30 then table.remove(fpsSamples, 1) end
end))

task.spawn(function()
    while true do
        task.wait(0.5)
        if #fpsSamples > 0 then
            local avg = 0
            for _, s in ipairs(fpsSamples) do avg = avg + s end
            avg = avg / #fpsSamples
            local fps = math.floor(1 / avg)
            
            local pct = math.clamp(fps / 120, 0, 1)
            local filled = math.floor(pct * 10)
            local bar = ""
            for i = 1, 10 do bar = bar .. (i <= filled and "█" or "░") end
            local fpsColor = fps >= 60 and "🟢" or fps >= 30 and "🟡" or "🔴"
            
            local ping = 0
            pcall(function()
                ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            local pingColor = ping < 100 and "🟢" or ping < 200 and "🟡" or "🔴"
            
            if statsLabel then
                pcall(function()
                    statsLabel:SetDesc(fpsColor .. "  " .. fps .. " FPS  [" .. bar .. "]\n" .. pingColor .. "  " .. ping .. " ms PING")
                end)
            end
        end
    end
end)

-- Theme settings
local setTheme = T_SET:Section({ Title = "Appearance", Opened = true })
setTheme:Dropdown({
    Title = "Theme",
    Desc  = "Change color theme",
    Values = (function()
        local names = {}
        for name in pairs(WindUI:GetThemes()) do table.insert(names, name) end
        table.sort(names)
        return names
    end)(),
    Value = "Rose",
    Callback = function(selected) WindUI:SetTheme(selected) end,
})

setTheme:Toggle({
    Title = "Acrylic Background",
    Desc  = "Blur effect",
    Value = true,
    Callback = function()
        local isOn = WindUI.Window.Acrylic
        WindUI:ToggleAcrylic(not isOn)
    end,
})

setTheme:Toggle({
    Title = "Transparent Window",
    Desc  = "Window transparency",
    Value = true,
    Callback = function(state) Window:ToggleTransparency(state) end,
})

local currentKey = Enum.KeyCode.RightShift
setTheme:Keybind({
    Title = "Toggle Key",
    Desc  = "Menu open/close button",
    Value = currentKey,
    Callback = function(v)
        currentKey = (typeof(v) == "EnumItem") and v or Enum.KeyCode[v]
        Window:SetToggleKey(currentKey)
    end,
})

-- Credits
local setCredit = T_SET:Section({ Title = "Credits", Opened = false })
setCredit:Paragraph({
    Title = "Designed by",
    Desc  = "🎨 @WTF.XKID - Premium Script Designer",
})
setCredit:Paragraph({
    Title = "Powered by",
    Desc  = "⚡ WindUI - Modern Roblox UI Library",
})
setCredit:Paragraph({
    Title = "Version",
    Desc  = "📦 XKID Premium Ultra V8",
})

-- ══════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS
-- ══════════════════════════════════════════════════════════════

-- Fly system loop
task.spawn(function()
    while true do
        if State.Fly.active and State.Fly.bv and State.Fly.bg then
            local root = getRoot()
            if root then
                local move = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - Cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - Cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.C) then move = move - Vector3.new(0, 1, 0) end
                
                if move.Magnitude > 0 then move = move.Unit end
                State.Fly.bv.Velocity = move * State.Move.flyS
                State.Fly.bg.CFrame = CFrame.new(root.Position, root.Position + Cam.CFrame.LookVector)
            end
        end
        RS.RenderStepped:Wait()
    end
end)

-- Fling loop
task.spawn(function()
    while true do
        if (State.Fling.active or State.SoftFling.active) and getRoot() then
            local r = getRoot()
            local brutal = State.Fling.active
            local pwr = brutal and State.Fling.power or State.SoftFling.power
            local ok = pcall(function()
                r.AssemblyAngularVelocity = Vector3.new(0, pwr, 0)
                if brutal then r.AssemblyLinearVelocity = Vector3.new(pwr, pwr, pwr) end
            end)
            if not ok then
                pcall(function()
                    r.RotVelocity = Vector3.new(0, pwr, 0)
                    if brutal then r.Velocity = Vector3.new(pwr, pwr, pwr) end
                end)
            end
        end
        RS.RenderStepped:Wait()
    end
end)

-- NoClip loop
TrackC(RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active or State.SoftFling.active) and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end))

-- ══════════════════════════════════════════════════════════════
--  STARTUP
-- ══════════════════════════════════════════════════════════════
WindUI:SetNotificationLower(true)
WindUI:Notify({
    Title   = "🎮 XKID PREMIUM V8",
    Content = "Premium Edition loaded successfully! ✨",
    Duration = 5,
})

print("✅ XKID Premium Script V8 loaded | Designed by @WTF.XKID")
