--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                 ✦ MY SCRIPT HUB - FULL VERSION ✦             ║
    ║                      Complete Features                        ║
    ║                   Press [RightShift] to toggle                ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

-- LOAD WINDUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TPService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GLOBAL STATE
local State = {
    Move = {ws = 16, jp = 50, ncp = false},
    Fly = {active = false, speed = 60},
    ESP = {active = false, cache = {}, color = Color3.fromRGB(0, 255, 150)},
    Teleport = {target = ""},
}

-- HELPERS
local function getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

local function getPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

-- PERSISTENT MOVEMENT
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = State.Move.ws
        hum.JumpPower = State.Move.jp
        hum.UseJumpPower = true
    end
end)

-- ========== FLY SYSTEM ==========
local flyActive = false
local flyBV = nil
local flyBG = nil
local flyKeys = {}

local function startFly()
    local hrp = getRoot()
    local hum = getHum()
    if not hrp or not hum then return false end
    
    hum.PlatformStand = true
    
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Parent = hrp
    
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.P = 1e5
    flyBG.Parent = hrp
    
    flyKeys = {}
    
    local function handleInput(inp, isDown)
        if not flyActive then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then
            flyKeys[k] = isDown
        end
    end
    
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        handleInput(inp, true)
    end)
    
    UserInputService.InputEnded:Connect(function(inp)
        handleInput(inp, false)
    end)
    
    RunService.RenderStepped:Connect(function()
        if not flyActive or not hrp or hrp.Parent == nil then return end
        local camCF = Camera.CFrame
        local speed = State.Fly.speed
        local move = Vector3.zero
        
        if flyKeys[Enum.KeyCode.W] then move = move + camCF.LookVector end
        if flyKeys[Enum.KeyCode.S] then move = move - camCF.LookVector end
        if flyKeys[Enum.KeyCode.D] then move = move + camCF.RightVector end
        if flyKeys[Enum.KeyCode.A] then move = move - camCF.RightVector end
        if flyKeys[Enum.KeyCode.E] then move = move + Vector3.new(0, 1, 0) end
        if flyKeys[Enum.KeyCode.Q] then move = move - Vector3.new(0, 1, 0) end
        
        if move.Magnitude > 0 then move = move.Unit * speed end
        flyBV.Velocity = move
        flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
    end)
    
    return true
end

local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local hum = getHum()
    if hum then
        hum.PlatformStand = false
        hum.WalkSpeed = State.Move.ws
    end
end

local function toggleFly(v)
    flyActive = v
    if v then
        if startFly() then
            WindUI:Notify({Title = "Fly", Content = "✈️ Fly ON (WASD+QE)", Duration = 2})
        else
            WindUI:Notify({Title = "Error", Content = "Gagal aktifkan fly!", Duration = 2})
            flyActive = false
        end
    else
        stopFly()
        WindUI:Notify({Title = "Fly", Content = "✈️ Fly OFF", Duration = 2})
    end
end

-- ========== ESP HIGHLIGHT ==========
local function clearESP()
    for _, cache in pairs(State.ESP.cache) do
        if cache.highlight then pcall(function() cache.highlight:Destroy() end) end
    end
    State.ESP.cache = {}
end

local function updateESP()
    if not State.ESP.active then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            if not State.ESP.cache[player] then
                State.ESP.cache[player] = {highlight = nil}
            end
            local cache = State.ESP.cache[player]
            
            if not cache.highlight or cache.highlight.Parent ~= char then
                if cache.highlight then pcall(function() cache.highlight:Destroy() end) end
                local hl = Instance.new("Highlight")
                hl.Parent = char
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                cache.highlight = hl
            end
            
            pcall(function()
                cache.highlight.FillColor = State.ESP.color
                cache.highlight.OutlineColor = Color3.new(1, 1, 1)
                cache.highlight.FillTransparency = 0.5
                cache.highlight.OutlineTransparency = 0
                cache.highlight.Enabled = true
            end)
        end
    end
end

RunService.RenderStepped:Connect(function()
    if State.ESP.active then
        pcall(updateESP)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if State.ESP.cache[player] then
        if State.ESP.cache[player].highlight then
            pcall(function() State.ESP.cache[player].highlight:Destroy() end)
        end
        State.ESP.cache[player] = nil
    end
end)

-- ========== NOCLIP LOOP ==========
RunService.Stepped:Connect(function()
    if State.Move.ncp and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

-- ========== CREATE WINDOW ==========
local Window = WindUI:CreateWindow({
    Title   = "✦ MY SCRIPT HUB ✦",
    Author  = "by you",
    Folder  = "myhub",
    Icon    = "paint-bucket",
    Theme   = "Dark",
    Acrylic = true,
    Transparent = true,
    Size    = UDim2.fromOffset(680, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey  = Enum.KeyCode.RightShift,
    Resizable  = true,
    AutoScale  = true,
    NewElements = true,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    SideBarWidth = 200,
    Topbar = {
        Height      = 44,
        ButtonsType = "Default",
    },
    OpenButton = {
        Title = "My Hub",
        Icon = "zap",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 1,
        Color = ColorSequence.new(
            Color3.fromHex("#ff3366"),
            Color3.fromHex("#ff6633")
        ),
    },
    User = {
        Enabled  = true,
        Anonymous = false,
        Callback = function()
            print("user panel clicked")
        end,
    },
})

-- ==================== TAB 1: MAIN ====================
local MainTab = Window:Tab({ Title = "Main", Icon = "house" })

-- Player Section
local PlayerSection = MainTab:Section({ Title = "Player", Side = 1 })

PlayerSection:Slider({
    Title = "🏃 WalkSpeed",
    Min = 16, Max = 500, Value = 16,
    Callback = function(v)
        State.Move.ws = v
        local hum = getHum()
        if hum then hum.WalkSpeed = v end
    end
})

PlayerSection:Slider({
    Title = "🦘 JumpPower",
    Min = 50, Max = 500, Value = 50,
    Callback = function(v)
        State.Move.jp = v
        local hum = getHum()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = v
        end
    end
})

-- Infinite Jump
local infJumpConn = nil
PlayerSection:Toggle({
    Title = "∞ Infinite Jump",
    Value = false,
    Callback = function(v)
        if v then
            infJumpConn = UserInputService.JumpRequest:Connect(function()
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
        end
    end
})

PlayerSection:Toggle({
    Title = "✈️ Fly Mode",
    Value = false,
    Callback = toggleFly
})

PlayerSection:Slider({
    Title = "✈️ Fly Speed",
    Min = 10, Max = 300, Value = 60,
    Callback = function(v) State.Fly.speed = v end
})

PlayerSection:Toggle({
    Title = "👻 NoClip (Tembus Tembok)",
    Value = false,
    Callback = function(v) State.Move.ncp = v end
})

-- Teleport Section
local TeleportSection = MainTab:Section({ Title = "Teleport", Side = 2 })

TeleportSection:TextBox({
    Title = "Search Player",
    Callback = function(v) State.Teleport.target = v end
})

TeleportSection:Button({
    Title = "🚀 Teleport To Target",
    Callback = function()
        local snippet = State.Teleport.target
        if snippet == "" then
            WindUI:Notify({Title = "Error", Content = "Masukkan nama player!", Duration = 2})
            return
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and (string.find(string.lower(p.Name), string.lower(snippet)) or string.find(string.lower(p.DisplayName), string.lower(snippet))) then
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and getRoot() then
                    getRoot().CFrame = p.Character.HumanoidRootPart.CFrame
                    WindUI:Notify({Title = "Teleport", Content = "Ke " .. p.Name, Duration = 2})
                    return
                end
            end
        end
        WindUI:Notify({Title = "Error", Content = "Player tidak ditemukan!", Duration = 2})
    end
})

local playerDropdown = TeleportSection:Dropdown({
    Title = "Player List",
    Values = getPlayerList(),
    Value = "",
    Callback = function(v)
        State.Teleport.target = v
        if getRoot() then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name == v and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    getRoot().CFrame = p.Character.HumanoidRootPart.CFrame
                    WindUI:Notify({Title = "Teleport", Content = "Ke " .. v, Duration = 2})
                    break
                end
            end
        end
    end
})

TeleportSection:Button({
    Title = "🔄 Refresh Player List",
    Callback = function()
        pcall(function() playerDropdown:Refresh(getPlayerList()) end)
    end
})

-- Save Locations
local savedLocs = {}
for i = 1, 3 do
    TeleportSection:Button({
        Title = "💾 Save Location " .. i,
        Callback = function()
            local r = getRoot()
            if r then
                savedLocs[i] = r.CFrame
                WindUI:Notify({Title = "Saved", Content = "Location " .. i, Duration = 1})
            end
        end
    })
    TeleportSection:Button({
        Title = "📍 Load Location " .. i,
        Callback = function()
            if savedLocs[i] and getRoot() then
                getRoot().CFrame = savedLocs[i]
                WindUI:Notify({Title = "Loaded", Content = "Location " .. i, Duration = 1})
            end
        end
    })
end

-- ==================== TAB 2: ESP ====================
local EspTab = Window:Tab({ Title = "ESP", Icon = "eye" })

EspTab:Toggle({
    Title = "🎯 ESP Highlight ON/OFF",
    Value = false,
    Callback = function(v)
        State.ESP.active = v
        if not v then clearESP() end
    end
})

EspTab:Dropdown({
    Title = "🎨 Highlight Color",
    Values = {"Green", "Red", "Blue", "Yellow", "Purple", "White"},
    Value = "Green",
    Callback = function(v)
        local colors = {
            Green = Color3.fromRGB(0, 255, 150),
            Red = Color3.fromRGB(255, 50, 50),
            Blue = Color3.fromRGB(0, 150, 255),
            Yellow = Color3.fromRGB(255, 255, 0),
            Purple = Color3.fromRGB(150, 0, 255),
            White = Color3.fromRGB(255, 255, 255)
        }
        State.ESP.color = colors[v] or Color3.fromRGB(0, 255, 150)
    end
})

EspTab:Label("Info: Highlight akan muncul di semua player lain")
EspTab:Label("Gunakan untuk mendeteksi glitcher / player usil")

-- ==================== TAB 3: WORLD ====================
local WorldTab = Window:Tab({ Title = "World", Icon = "globe" })

WorldTab:Button({
    Title = "☀️ Set Time: Day",
    Callback = function()
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
        Lighting.FogStart = 1000
        Lighting.FogEnd = 10000
    end
})

WorldTab:Button({
    Title = "🌃 Set Time: Night",
    Callback = function()
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.3
        Lighting.FogStart = 2000
        Lighting.FogEnd = 20000
    end
})

WorldTab:Slider({
    Title = "🕐 Clock Time",
    Min = 0, Max = 24, Value = 14,
    Callback = function(v) Lighting.ClockTime = v end
})

WorldTab:Slider({
    Title = "☀️ Brightness",
    Min = 0, Max = 3, Value = 2,
    Callback = function(v) Lighting.Brightness = v end
})

WorldTab:Button({
    Title = "🚀 Unlock FPS (999)",
    Callback = function()
        if setfpscap then setfpscap(999) end
        WindUI:Notify({Title = "FPS", Content = "Unlocked to 999", Duration = 2})
    end
})

-- Anti Lag
local antiLagActive = false
WorldTab:Toggle({
    Title = "🗑️ Anti Lag Mode",
    Value = false,
    Callback = function(v)
        antiLagActive = v
        if v then
            Lighting.GlobalShadows = false
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Decal") then
                    pcall(function() obj.Enabled = false end)
                end
            end
        else
            Lighting.GlobalShadows = true
        end
    end
})

-- ==================== TAB 4: SECURITY ====================
local SecurityTab = Window:Tab({ Title = "Security", Icon = "shield" })

local afkConn = nil
SecurityTab:Toggle({
    Title = "🛡️ Anti AFK",
    Value = false,
    Callback = function(v)
        if v then
            afkConn = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            pcall(function()
                for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
                    conn:Disable()
                end
            end)
            WindUI:Notify({Title = "Anti AFK", Content = "Active", Duration = 2})
        else
            if afkConn then afkConn:Disconnect(); afkConn = nil end
            pcall(function()
                for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
                    conn:Enable()
                end
            end)
        end
    end
})

SecurityTab:Button({
    Title = "🔄 Rejoin Server",
    Callback = function()
        TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

-- Fast Respawn
local lastPosition = nil
task.spawn(function()
    while true do
        task.wait(1)
        local r = getRoot()
        if r then lastPosition = r.CFrame end
    end
end)

SecurityTab:Button({
    Title = "💀 Fast Respawn",
    Callback = function()
        local savedPos = lastPosition
        local hum = getHum()
        if hum then hum.Health = 0 end
        task.spawn(function()
            local char = LocalPlayer.CharacterAdded:Wait()
            task.wait(0.5)
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and savedPos then
                hrp.CFrame = savedPos
            end
        end)
    end
})

-- ==================== TAB 5: SETTINGS ====================
local ThemeTab = Window:Tab({ Title = "Settings", Icon = "settings" })

ThemeTab:Dropdown({
    Title  = "Theme",
    Values = (function()
        local names = {}
        if WindUI.GetThemes then
            for name in pairs(WindUI:GetThemes()) do
                table.insert(names, name)
            end
        else
            names = {"Dark", "Light", "Dracula"}
        end
        table.sort(names)
        return names
    end)(),
    Value = "Dark",
    Callback = function(selected)
        if WindUI.SetTheme then WindUI:SetTheme(selected) end
    end,
})

ThemeTab:Toggle({
    Title = "Acrylic Mode",
    Value = true,
    Callback = function(state)
        if WindUI.ToggleAcrylic then
            WindUI:ToggleAcrylic(not WindUI.Window.Acrylic)
        end
    end,
})

ThemeTab:Toggle({
    Title = "Transparent Background",
    Value = true,
    Callback = function(state)
        Window:ToggleTransparency(state)
    end
})

local currentKey = Enum.KeyCode.RightShift
ThemeTab:Keybind({
    Title = "Toggle UI Key",
    Value = currentKey,
    Callback = function(v)
        currentKey = (typeof(v) == "EnumItem") and v or Enum.KeyCode[v]
        Window:SetToggleKey(currentKey)
    end,
})

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == currentKey then
        Window:Toggle()
    end
end)

-- ==================== NOTIFICATION ====================
WindUI:Notify({
    Title = "My Script Hub",
    Content = "Welcome! Press RightShift to toggle menu",
    Duration = 5
})

WindUI:SetNotificationLower(true)

print("✅ My Script Hub - Fully Loaded!")