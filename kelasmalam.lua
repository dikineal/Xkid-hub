--[[
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║                    @WTF.XKID                                 ║
║                    Modern Script                             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
]]

-- ════════════════════════════════════════════════════════════
--  AUTO CLEANUP & MEMORY MANAGEMENT
-- ════════════════════════════════════════════════════════════
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

-- ════════════════════════════════════════════════════════════
--  LOAD WINDUI
-- ════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- ════════════════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════════════════
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

-- ════════════════════════════════════════════════════════════
--  STATE MANAGEMENT
-- ════════════════════════════════════════════════════════════
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

-- ════════════════════════════════════════════════════════════
--  HELPER FUNCTIONS
-- ════════════════════════════════════════════════════════════
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

local function notify(title, content, dur)
    WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 })
end

-- Persistent stats on respawn
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

-- ════════════════════════════════════════════════════════════
--  AVATAR REFRESH
-- ════════════════════════════════════════════════════════════

local function refreshAvatarPremium()
    if State.Avatar.isRefreshing then return end
    
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = getRoot()
    local head = char and char:FindFirstChild("Head")

    if not hum or not hrp then
        notify("Avatar", "Character not found")
        return 
    end

    State.Avatar.isRefreshing = true
    notify("Avatar", "Refreshing...")
    
    local savedCF = hrp.CFrame
    local savedVel = hrp.AssemblyLinearVelocity
    local savedCamCF = Cam.CFrame
    
    local savedGuis = {}
    if head then
        for _, item in ipairs(head:GetChildren()) do
            if item:IsA("BillboardGui") or item:IsA("SurfaceGui") then
                table.insert(savedGuis, item:Clone())
            end
        end
    end

    Cam.CameraType = Enum.CameraType.Scriptable
    Cam.CFrame = savedCamCF
    hum.Health = 0

    task.spawn(function()
        local newChar = LP.CharacterAdded:Wait()
        local newHrp = newChar:WaitForChild("HumanoidRootPart", 5)
        local newHum = newChar:WaitForChild("Humanoid", 5)
        local newHead = newChar:WaitForChild("Head", 5)
        
        RS.RenderStepped:Wait()

        if newHrp then
            newHrp.CFrame = savedCF
            newHrp.AssemblyLinearVelocity = savedVel
        end

        if newHead then
            for _, gui in ipairs(savedGuis) do
                gui.Parent = newHead
            end
        end
        
        Cam.CameraType = Enum.CameraType.Custom
        
        State.Avatar.isRefreshing = false
        notify("Avatar", "Refreshed")
    end)
end

TrackC(LP.Chatted:Connect(function(msg)
    if msg:lower() == "/re" then
        refreshAvatarPremium()
    end
end))

-- ════════════════════════════════════════════════════════════
--  FLY SYSTEM
-- ════════════════════════════════════════════════════════════

local function toggleFly(active)
    if active then
        if not getRoot() then return end
        
        State.Fly.active = true
        local root = getRoot()
        local hum = getHum()
        
        State.Fly.bv = Instance.new("BodyVelocity")
        State.Fly.bv.Velocity = Vector3.new(0, 0, 0)
        State.Fly.bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        State.Fly.bv.Parent = root
        
        State.Fly.bg = Instance.new("BodyGyro")
        State.Fly.bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        State.Fly.bg.CFrame = root.CFrame
        State.Fly.bg.Parent = root
        
        hum.PlatformStand = true
        notify("Flight", "Enabled")
    else
        State.Fly.active = false
        if State.Fly.bv then State.Fly.bv:Destroy(); State.Fly.bv = nil end
        if State.Fly.bg then State.Fly.bg:Destroy(); State.Fly.bg = nil end
        local hum = getHum()
        if hum then hum.PlatformStand = false end
        notify("Flight", "Disabled")
    end
end

TrackC(RS.RenderStepped:Connect(function()
    if State.Fly.active and getRoot() then
        local root = getRoot()
        local moveDir = Vector3.new(0, 0, 0)
        
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + (Cam.CFrame.LookVector) end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - (Cam.CFrame.RightVector) end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - (Cam.CFrame.LookVector) end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + (Cam.CFrame.RightVector) end
        
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
        end
        
        if State.Fly.bv then
            State.Fly.bv.Velocity = moveDir * State.Move.flyS
        end
        
        if State.Fly.bg then
            State.Fly.bg.CFrame = Cam.CFrame
        end
    end
end))

-- ════════════════════════════════════════════════════════════
--  FREECAM SYSTEM
-- ════════════════════════════════════════════════════════════

local freecamPos = nil
local freecamRotation = nil

local function toggleFreecam(active)
    if active then
        State.Freecam = { active = true, speed = 100 }
        local root = getRoot()
        if root then
            freecamPos = root.Position
            freecamRotation = Cam.CFrame
        end
        Cam.CameraType = Enum.CameraType.Scriptable
        notify("Freecam", "Enabled")
    else
        State.Freecam = { active = false, speed = 100 }
        Cam.CameraType = Enum.CameraType.Custom
        notify("Freecam", "Disabled")
    end
end

TrackC(RS.RenderStepped:Connect(function()
    if State.Freecam and State.Freecam.active then
        local moveDir = Vector3.new(0, 0, 0)
        
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + (Cam.CFrame.LookVector) end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - (Cam.CFrame.RightVector) end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - (Cam.CFrame.LookVector) end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + (Cam.CFrame.RightVector) end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        if moveDir.Magnitude > 0 then
            freecamPos = freecamPos + (moveDir.Unit * State.Freecam.speed * 0.016)
        end
        
        Cam.CFrame = CFrame.new(freecamPos) * Cam.CFrame - Cam.CFrame.Position
    end
end))

-- ════════════════════════════════════════════════════════════
--  TELEPORT SYSTEM
-- ════════════════════════════════════════════════════════════

local SavedLocations = {}

local function teleportToPlayer(player)
    if not player or not player.Character then return end
    local targetRoot = getCharRoot(player.Character)
    local myRoot = getRoot()
    
    if targetRoot and myRoot then
        myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 5, 0)
        notify("Teleport", "Moved to " .. player.Name)
    end
end

local function teleportToCoord(x, y, z)
    local myRoot = getRoot()
    if myRoot then
        myRoot.CFrame = CFrame.new(x, y, z)
        notify("Teleport", "Moved")
    end
end

local function saveLocation(name)
    local root = getRoot()
    if root then
        SavedLocations[name] = root.Position
        notify("Location", "Saved")
    end
end

local function loadLocation(name)
    if SavedLocations[name] then
        teleportToCoord(SavedLocations[name].X, SavedLocations[name].Y, SavedLocations[name].Z)
        notify("Location", "Loaded")
    end
end

-- ════════════════════════════════════════════════════════════
--  FLING SYSTEMS
-- ════════════════════════════════════════════════════════════

local function toggleFling(brutal)
    if brutal then
        State.Fling.active = not State.Fling.active
        if State.Fling.active then
            notify("Fling", "Active")
        else
            notify("Fling", "Inactive")
        end
    else
        State.SoftFling.active = not State.SoftFling.active
        if State.SoftFling.active then
            notify("Soft Fling", "Active")
        else
            notify("Soft Fling", "Inactive")
        end
    end
end

-- ════════════════════════════════════════════════════════════
--  ESP SYSTEM
-- ════════════════════════════════════════════════════════════

local function createESP(player)
    if not State.ESP.active or player == LP or not player.Character then return end
    
    local char = player.Character
    local root = getCharRoot(char)
    if not root then return end
    
    if State.ESP.cache[player] then
        return State.ESP.cache[player]
    end
    
    local espHolder = Instance.new("Folder")
    espHolder.Name = "_ESP_" .. player.Name
    espHolder.Parent = player.Character
    
    if State.ESP.boxMode ~= "None" then
        local box = Instance.new("Part")
        box.Shape = Enum.PartType.Block
        box.Material = Enum.Material.Neon
        box.CanCollide = false
        box.CFrame = root.CFrame
        box.Transparency = 0.3
        box.Color = State.ESP.boxColor_N
        box.Parent = espHolder
        
        if not State.ESP.cache[player] then
            State.ESP.cache[player] = {}
        end
        State.ESP.cache[player].box = box
    end
    
    return State.ESP.cache[player]
end

local function updateESP()
    if not State.ESP.active then return end
    
    for player, espData in pairs(State.ESP.cache) do
        if player and player.Character then
            local root = getCharRoot(player.Character)
            if root and espData.box then
                local dist = (root.Position - getRoot().Position).Magnitude
                if dist < State.ESP.maxDrawDistance then
                    espData.box.CFrame = root.CFrame
                    espData.box.Transparency = 0.3
                else
                    espData.box.Transparency = 1
                end
            end
        end
    end
end

TrackC(RS.RenderStepped:Connect(function()
    updateESP()
end))

-- ════════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ════════════════════════════════════════════════════════════

local Window = WindUI:CreateWindow({
    Title       = "@WTF.XKID",
    Author      = "Modern Script",
    Folder      = "XKIDScript",
    Icon        = "zap",
    Theme       = "Rose",
    Acrylic     = true,
    Transparent = true,
    Size        = UDim2.fromOffset(720, 520),
})

-- ════════════════════════════════════════════════════════════
--  TAB: HOME
-- ════════════════════════════════════════════════════════════

local T_HOME = Window:Tab({ Title = "Home", Icon = "home" })

local homeWelcome = T_HOME:Section({ Title = "Welcome", Opened = true })
homeWelcome:Paragraph({
    Title = "@WTF.XKID",
    Desc  = "Modern script. Simple. Powerful.",
})

-- ════════════════════════════════════════════════════════════
--  TAB: MOVEMENT
-- ════════════════════════════════════════════════════════════

local T_MOV = Window:Tab({ Title = "Movement", Icon = "move" })

local movSpeed = T_MOV:Section({ Title = "Speed & Jump", Opened = true })
movSpeed:Slider({
    Title    = "Walk Speed",
    Min      = 0,
    Max      = 200,
    Value    = 16,
    Step     = 1,
    Callback = function(v)
        State.Move.ws = v
        local hum = getHum()
        if hum then hum.WalkSpeed = v end
    end,
})

movSpeed:Slider({
    Title    = "Jump Power",
    Min      = 0,
    Max      = 200,
    Value    = 50,
    Step     = 1,
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
    Title    = "Infinite Jump",
    Value    = false,
    Callback = function(v)
        State.Move.infJ = v
    end,
})

TrackC(UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Space and State.Move.infJ then
        local hum = getHum()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = State.Move.jp
            hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
            task.wait(0.1)
            hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
        end
    end
end))

local movFlight = T_MOV:Section({ Title = "Flight", Opened = false })
movFlight:Toggle({
    Title    = "Flight",
    Value    = false,
    Callback = function(v) toggleFly(v) end,
})

movFlight:Slider({
    Title    = "Speed",
    Min      = 10,
    Max      = 500,
    Value    = 60,
    Step     = 5,
    Callback = function(v) State.Move.flyS = v end,
})

local movAdvanced = T_MOV:Section({ Title = "Advanced", Opened = false })
movAdvanced:Toggle({
    Title    = "Noclip",
    Value    = false,
    Callback = function(v)
        State.Move.ncp = v
    end,
})

movAdvanced:Toggle({
    Title    = "Freecam",
    Value    = false,
    Callback = function(v) toggleFreecam(v) end,
})

movAdvanced:Slider({
    Title    = "Freecam Speed",
    Min      = 10,
    Max      = 500,
    Value    = 100,
    Step     = 10,
    Callback = function(v) 
        if not State.Freecam then State.Freecam = {} end
        State.Freecam.speed = v 
    end,
})

-- ════════════════════════════════════════════════════════════
--  TAB: AVATAR
-- ════════════════════════════════════════════════════════════

local T_AVA = Window:Tab({ Title = "Avatar", Icon = "user" })

local avaRefresh = T_AVA:Section({ Title = "Refresh", Opened = true })
avaRefresh:Button({
    Title    = "Refresh Avatar",
    Callback = function() refreshAvatarPremium() end,
})

avaRefresh:Paragraph({
    Title = "Tip",
    Desc  = "Type /re in chat",
})

-- ════════════════════════════════════════════════════════════
--  TAB: TELEPORT
-- ════════════════════════════════════════════════════════════

local T_TELE = Window:Tab({ Title = "Teleport", Icon = "arrow-up-right" })

local telePlayers = T_TELE:Section({ Title = "Player", Opened = true })
telePlayers:Dropdown({
    Title    = "Select",
    Values   = getDisplayNames(),
    Value    = "",
    Callback = function(v) State.Teleport.selectedTarget = v end,
})

telePlayers:Button({
    Title    = "Go",
    Callback = function()
        if State.Teleport.selectedTarget == "" then return end
        local target = findPlayerByDisplay(State.Teleport.selectedTarget)
        if target then teleportToPlayer(target) end
    end,
})

local teleCoords = T_TELE:Section({ Title = "Coordinates", Opened = false })
teleCoords:TextBox({
    Title    = "X",
    Value    = "0",
    Callback = function(v) _G.TeleX = tonumber(v) or 0 end,
})

teleCoords:TextBox({
    Title    = "Y",
    Value    = "0",
    Callback = function(v) _G.TeleY = tonumber(v) or 0 end,
})

teleCoords:TextBox({
    Title    = "Z",
    Value    = "0",
    Callback = function(v) _G.TeleZ = tonumber(v) or 0 end,
})

teleCoords:Button({
    Title    = "Go",
    Callback = function()
        teleportToCoord(_G.TeleX or 0, _G.TeleY or 0, _G.TeleZ or 0)
    end,
})

local teleSave = T_TELE:Section({ Title = "Saved", Opened = false })
teleSave:TextBox({
    Title    = "Name",
    Value    = "Location",
    Callback = function(v) _G.SaveName = v end,
})

teleSave:Button({
    Title    = "Save",
    Callback = function()
        if _G.SaveName then saveLocation(_G.SaveName) end
    end,
})

teleSave:Button({
    Title    = "Load",
    Callback = function()
        if _G.SaveName then loadLocation(_G.SaveName) end
    end,
})

-- ════════════════════════════════════════════════════════════
--  TAB: VISION
-- ════════════════════════════════════════════════════════════

local T_ESP = Window:Tab({ Title = "Vision", Icon = "eye" })

local espMain = T_ESP:Section({ Title = "ESP", Opened = true })
espMain:Toggle({
    Title    = "Enable",
    Value    = false,
    Callback = function(v)
        State.ESP.active = v
        if v then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then createESP(player) end
            end
            notify("ESP", "On")
        else
            for _, data in pairs(State.ESP.cache) do
                if data.box then pcall(function() data.box:Destroy() end) end
            end
            State.ESP.cache = {}
            notify("ESP", "Off")
        end
    end,
})

espMain:Slider({
    Title    = "Distance",
    Min      = 50,
    Max      = 1000,
    Value    = 300,
    Step     = 50,
    Callback = function(v) State.ESP.maxDrawDistance = v end,
})

local espColor = T_ESP:Section({ Title = "Colors", Opened = false })
local colorPicker_N = Color3.fromRGB(0, 255, 150)
local colorPicker_S = Color3.fromRGB(255, 0, 100)
local colorPicker_T = Color3.fromRGB(0, 200, 255)

espColor:ColorPicker({
    Title    = "Normal",
    Value    = colorPicker_N,
    Callback = function(v) 
        State.ESP.boxColor_N = v
        colorPicker_N = v
    end,
})

espColor:ColorPicker({
    Title    = "Suspicious",
    Value    = colorPicker_S,
    Callback = function(v) 
        State.ESP.boxColor_S = v
        colorPicker_S = v
    end,
})

espColor:ColorPicker({
    Title    = "Tracer",
    Value    = colorPicker_T,
    Callback = function(v) 
        State.ESP.tracerColor_N = v
        colorPicker_T = v
    end,
})

-- ════════════════════════════════════════════════════════════
--  TAB: COMBAT
-- ════════════════════════════════════════════════════════════

local T_COM = Window:Tab({ Title = "Combat", Icon = "zap" })

local comFling = T_COM:Section({ Title = "Fling", Opened = true })
comFling:Toggle({
    Title    = "Brutal",
    Value    = false,
    Callback = function(v) 
        State.Fling.active = v 
    end,
})

comFling:Slider({
    Title    = "Power",
    Min      = 100000,
    Max      = 5000000,
    Value    = 1000000,
    Step     = 100000,
    Callback = function(v) State.Fling.power = v end,
})

comFling:Toggle({
    Title    = "Soft",
    Value    = false,
    Callback = function(v)
        State.SoftFling.active = v
    end,
})

comFling:Slider({
    Title    = "Soft Power",
    Min      = 500,
    Max      = 10000,
    Value    = 4000,
    Step     = 500,
    Callback = function(v) State.SoftFling.power = v end,
})

-- ════════════════════════════════════════════════════════════
--  TAB: WORLD
-- ════════════════════════════════════════════════════════════

local T_WOR = Window:Tab({ Title = "World", Icon = "globe" })

local worLight = T_WOR:Section({ Title = "Lighting", Opened = true })
worLight:Slider({
    Title    = "Brightness",
    Min      = 0,
    Max      = 2,
    Value    = Lighting.Brightness,
    Step     = 0.1,
    Callback = function(v) Lighting.Brightness = v end,
})

worLight:Button({
    Title    = "Day",
    Callback = function()
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
    end,
})

worLight:Button({
    Title    = "Night",
    Callback = function()
        Lighting.Brightness = 0.3
        Lighting.Ambient = Color3.fromRGB(50, 50, 80)
    end,
})

-- ════════════════════════════════════════════════════════════
--  TAB: SECURITY
-- ════════════════════════════════════════════════════════════

local T_SEC = Window:Tab({ Title = "Security", Icon = "shield" })

local secProt = T_SEC:Section({ Title = "Protection", Opened = true })
secProt:Toggle({
    Title    = "Anti-AFK",
    Value    = false,
    Callback = function(v)
        if v then
            State.Security.afkConn = TrackC(LP.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                task.wait(1)
            end))
            notify("Anti-AFK", "On")
        else
            if State.Security.afkConn then State.Security.afkConn:Disconnect(); State.Security.afkConn=nil end
            notify("Anti-AFK", "Off")
        end
    end,
})

secProt:Button({
    Title    = "Rejoin",
    Callback = function() TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end,
})

local antiGlitchConn = nil
secProt:Toggle({
    Title    = "Anti-Glitch",
    Value    = false,
    Callback = function(v)
        if v then
            antiGlitchConn = TrackC(RS.Heartbeat:Connect(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        for _, part in pairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") and (part.Size.X > 50 or part.Size.Y > 50 or part.Size.Z > 50) then
                                part:Destroy() 
                            end
                        end
                    end
                end
            end))
            notify("Anti-Glitch", "On")
        else
            if antiGlitchConn then antiGlitchConn:Disconnect(); antiGlitchConn=nil end
            notify("Anti-Glitch", "Off")
        end
    end,
})

local antiLag = { mats={}, texs={}, shadows=true }
secProt:Toggle({
    Title    = "Anti-Lag",
    Value    = false,
    Callback = function(v)
        if v then
            antiLag.shadows=Lighting.GlobalShadows; Lighting.GlobalShadows=false
            for _,obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    antiLag.mats[obj]=obj.Material; obj.Material=Enum.Material.SmoothPlastic
                elseif obj:IsA("Texture") or obj:IsA("Decal") then
                    antiLag.texs[obj]=obj.Parent; obj.Parent=nil
                end
            end
            notify("Anti-Lag", "On")
        else
            Lighting.GlobalShadows=antiLag.shadows
            for obj,mat in pairs(antiLag.mats) do if obj and obj.Parent then obj.Material=mat end end
            for obj,par in pairs(antiLag.texs) do if obj and par and par.Parent then obj.Parent=par end end
            antiLag.mats={}; antiLag.texs={}
            notify("Anti-Lag", "Off")
        end
    end,
})

-- ════════════════════════════════════════════════════════════
--  TAB: SETTINGS
-- ════════════════════════════════════════════════════════════

local T_SET = Window:Tab({ Title = "Settings", Icon = "settings" })

local secInfo = T_SET:Section({ Title = "Stats", Opened = true })
local statsLabel = secInfo:Paragraph({
    Title = "Performance",
    Desc  = "Loading...",
})

local fpsSamples = {}
TrackC(RS.RenderStepped:Connect(function(dt)
    table.insert(fpsSamples, dt)
    if #fpsSamples > 30 then table.remove(fpsSamples,1) end
end))

task.spawn(function()
    while true do
        task.wait(0.5)
        if #fpsSamples > 0 then
            local avg = 0
            for _,s in ipairs(fpsSamples) do avg=avg+s end
            avg = avg / #fpsSamples
            local fps = math.floor(1/avg)
            
            local ping = 0
            pcall(function() 
                ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) 
            end)
            
            if statsLabel then
                pcall(function()
                    statsLabel:SetDesc("FPS: " .. fps .. " | Ping: " .. ping .. "ms")
                end)
            end
        end
    end
end)

local secTheme = T_SET:Section({ Title = "Theme", Opened = true })
secTheme:Dropdown({
    Title    = "Color",
    Values   = (function()
        local names={}
        for name in pairs(WindUI:GetThemes()) do table.insert(names,name) end
        table.sort(names); return names
    end)(),
    Value    = "Rose",
    Callback = function(selected) WindUI:SetTheme(selected) end,
})

secTheme:Toggle({
    Title    = "Blur",
    Value    = true,
    Callback = function()
        local isOn=WindUI.Window.Acrylic
        WindUI:ToggleAcrylic(not isOn)
    end,
})

local currentKey = Enum.KeyCode.RightShift
secTheme:Keybind({
    Title    = "Toggle",
    Value    = currentKey,
    Callback = function(v)
        currentKey = (typeof(v)=="EnumItem") and v or Enum.KeyCode[v]
        Window:SetToggleKey(currentKey)
    end,
})

-- ════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS
-- ════════════════════════════════════════════════════════════

task.spawn(function()
    while true do
        if (State.Fling.active or State.SoftFling.active) and getRoot() then
            local r=getRoot()
            local brutal=State.Fling.active
            local pwr=brutal and State.Fling.power or State.SoftFling.power
            pcall(function()
                r.AssemblyAngularVelocity=Vector3.new(0,pwr,0)
                if brutal then r.AssemblyLinearVelocity=Vector3.new(pwr,pwr,pwr) end
            end)
        end
        RS.RenderStepped:Wait()
    end
end)

TrackC(RS.Stepped:Connect(function()
    if (State.Move.ncp or State.Fling.active or State.SoftFling.active) and LP.Character then
        for _,v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide=false end
        end
    end
end))

TrackC(Players.PlayerAdded:Connect(function(player)
    if State.ESP.active and player ~= LP then
        createESP(player)
    end
end))

TrackC(Players.PlayerRemoving:Connect(function(player)
    if State.ESP.cache[player] then
        pcall(function()
            if State.ESP.cache[player].box then
                State.ESP.cache[player].box:Destroy()
            end
        end)
        State.ESP.cache[player] = nil
    end
end))

-- ════════════════════════════════════════════════════════════
--  STARTUP
-- ════════════════════════════════════════════════════════════

WindUI:SetNotificationLower(true)

WindUI:Notify({
    Title   = "@WTF.XKID",
    Content = "Ready to go.",
    Duration = 3,
})

print("✓ @WTF.XKID loaded")
