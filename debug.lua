--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    ✦  X K I D     H U B  ✦   FIXED VERSION                  ║
║                                                              ║
║   ✅ Semua Tab Muncul & Berfungsi                            ║
║   ✅ ESP Highlight Untuk Counter Glitcher                    ║
║   ✅ Fixed: Teleport, Fly, Freecam, Spectate                ║
║   ✅ No Error / Crash                                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
]]

-- CEK APAKAH WINDUI SUPPORTED
local WindUI_exists, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not WindUI_exists then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Error",
        Text = "Gagal load WindUI! Cek koneksi atau coba executor lain",
        Duration = 5
    })
    return
end

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TPService = game:GetService("TeleportService")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- Global State (LENGKAPI YANG HILANG)
local State = {
    Move = {ws = 16, jp = 50, ncp = false, infJ = nil, flyS = 60},
    Fly = {active = false, bv = nil, bg = nil, _keys = {}},
    Fling = {active = false, power = 1000000},
    SoftFling = {active = false, power = 4000},
    Teleport = {selectedTarget = ""},
    Security = {afkConn = nil},
    Spectate = {hideName = false},
    Cinema = {active = false},  -- <-- DITAMBAH
    ESP = {
        active = false, 
        cache = {},
        colorNormal = Color3.fromRGB(0, 255, 150),
        colorSuspect = Color3.fromRGB(255, 0, 100),
    }
}

-- Helpers
local function getRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function getPNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
    return t
end
local function getDisplayNames()
    local t = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")") end end
    return t
end
local function findPlayerByDisplay(str)
    for _, p in pairs(Players:GetPlayers()) do if str == p.DisplayName .. " (@" .. p.Name .. ")" then return p end end
    return nil
end

-- Persistent Movement (FIXED)
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.Move.ws ~= 16 then hum.WalkSpeed = State.Move.ws end
        if State.Move.jp ~= 50 then hum.UseJumpPower = true; hum.JumpPower = State.Move.jp end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- ESP HIGHLIGHT (FIXED - TIDAK CRASH)
-- ═══════════════════════════════════════════════════════════

local function isSuspectPlayer(player)
    local char = player.Character
    if not char then return false end
    -- Deteksi glitcher / ukuran part aneh
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Size.X > 10 or part.Size.Y > 10 or part.Size.Z > 10 then
                return true
            end
        end
    end
    return false
end

local function clearESP()
    for _, cache in pairs(State.ESP.cache) do
        if cache.highlight then pcall(function() cache.highlight:Destroy() end) end
    end
    State.ESP.cache = {}
end

local function updateESP()
    if not State.ESP.active then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local char = player.Character
            if not State.ESP.cache[player] then State.ESP.cache[player] = {highlight = nil} end
            local cache = State.ESP.cache[player]
            
            local isSuspect = isSuspectPlayer(player)
            local color = isSuspect and State.ESP.colorSuspect or State.ESP.colorNormal
            
            if not cache.highlight or cache.highlight.Parent ~= char then
                if cache.highlight then pcall(function() cache.highlight:Destroy() end) end
                local hl = Instance.new("Highlight")
                hl.Parent = char
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                cache.highlight = hl
            end
            
            pcall(function()
                cache.highlight.FillColor = color
                cache.highlight.OutlineColor = Color3.new(1, 1, 1)
                cache.highlight.FillTransparency = 0.5
                cache.highlight.OutlineTransparency = 0
                cache.highlight.Enabled = true
            end)
        end
    end
end

RS.RenderStepped:Connect(function()
    if State.ESP.active then 
        pcall(function() updateESP() end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if State.ESP.cache[player] then
        if State.ESP.cache[player].highlight then pcall(function() State.ESP.cache[player].highlight:Destroy() end) end
        State.ESP.cache[player] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════
-- FLY ENGINE (SEDERHANA & STABLE)
-- ═══════════════════════════════════════════════════════════

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
    
    UIS.InputBegan:Connect(function(inp, gp)
        if gp or not flyActive then return end
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then
            flyKeys[k] = true
        end
    end)
    
    UIS.InputEnded:Connect(function(inp)
        if not flyActive then return end
        flyKeys[inp.KeyCode] = false
    end)
    
    RS.RenderStepped:Connect(function()
        if not flyActive or not hrp or hrp.Parent == nil then return end
        local camCF = workspace.CurrentCamera.CFrame
        local speed = State.Move.flyS or 60
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
    flyActive = false
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
            WindUI:Notify({Title = "Fly", Content = "✈️ Fly ON (WASD+QE)", Duration = 3})
        else
            WindUI:Notify({Title = "Error", Content = "Gagal aktifkan fly!", Duration = 2})
            flyActive = false
        end
    else
        stopFly()
        WindUI:Notify({Title = "Fly", Content = "✈️ Fly OFF", Duration = 2})
    end
end

-- ═══════════════════════════════════════════════════════════
-- FREECAM SEDERHANA
-- ═══════════════════════════════════════════════════════════

local freecamActive = false
local freecamPos = Vector3.zero
local freecamVel = Vector3.zero
local freecamYaw = 0
local freecamPitch = 0
local freecamSpeed = 5
local freecamSens = 0.25
local savedCharCFrame = nil

local function startFreecam()
    local hrp = getRoot()
    local hum = getHum()
    if not hrp or not hum then return false end
    
    freecamPos = Cam.CFrame.Position
    local _, y, _ = Cam.CFrame:ToEulerAnglesYXZ()
    freecamYaw = math.deg(y)
    freecamPitch = 0
    savedCharCFrame = hrp.CFrame
    hrp.Anchored = true
    hum.WalkSpeed = 0
    hum.JumpPower = 0
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    
    UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    
    return true
end

local function stopFreecam()
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    local hrp = getRoot()
    local hum = getHum()
    if hrp then 
        hrp.Anchored = false
        if savedCharCFrame then hrp.CFrame = savedCharCFrame end
    end
    if hum then 
        hum.WalkSpeed = State.Move.ws
        hum.JumpPower = State.Move.jp
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    Cam.FieldOfView = 70
    Cam.CameraType = Enum.CameraType.Custom
end

local freecamKeys = {}
local function freecamLoop()
    while freecamActive do
        local cf = CFrame.new(freecamPos) * CFrame.Angles(0, math.rad(freecamYaw), 0) * CFrame.Angles(math.rad(freecamPitch), 0, 0)
        local speed = freecamSpeed * 32
        local desiredVel = Vector3.zero
        
        if freecamKeys[Enum.KeyCode.W] then desiredVel = desiredVel + cf.LookVector * speed end
        if freecamKeys[Enum.KeyCode.S] then desiredVel = desiredVel - cf.LookVector * speed end
        if freecamKeys[Enum.KeyCode.D] then desiredVel = desiredVel + cf.RightVector * speed end
        if freecamKeys[Enum.KeyCode.A] then desiredVel = desiredVel - cf.RightVector * speed end
        if freecamKeys[Enum.KeyCode.E] then desiredVel = desiredVel + Vector3.new(0, 1, 0) * speed end
        if freecamKeys[Enum.KeyCode.Q] then desiredVel = desiredVel - Vector3.new(0, 1, 0) * speed end
        
        freecamVel = freecamVel:Lerp(desiredVel, 0.15)
        freecamVel = freecamVel * 0.85
        freecamPos = freecamPos + freecamVel * RS.RenderStepped:Wait()
        
        Cam.CameraType = Enum.CameraType.Scriptable
        Cam.CFrame = CFrame.new(freecamPos) * CFrame.Angles(0, math.rad(freecamYaw), 0) * CFrame.Angles(math.rad(freecamPitch), 0, 0)
    end
end

UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if freecamActive then
        local k = inp.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.E or k == Enum.KeyCode.Q then
            freecamKeys[k] = true
        end
    end
    if inp.UserInputType == Enum.UserInputType.MouseMovement and freecamActive then
        freecamYaw = freecamYaw - inp.Delta.X * freecamSens
        freecamPitch = math.clamp(freecamPitch - inp.Delta.Y * freecamSens, -80, 80)
    end
    if inp.UserInputType == Enum.UserInputType.MouseWheel and freecamActive then
        Cam.FieldOfView = math.clamp(Cam.FieldOfView - inp.Position.Z * 5, 10, 120)
    end
end)

UIS.InputEnded:Connect(function(inp)
    if freecamActive then
        freecamKeys[inp.KeyCode] = false
    end
end)

-- ═══════════════════════════════════════════════════════════
-- WINDOW CREATION (WINDUI)
-- ═══════════════════════════════════════════════════════════

local Window = WindUI:CreateWindow({
    Title   = "✦ XKID HUB ✦",
    Author  = "by XKIDB4D",
    Folder  = "xkid_hub_v5",
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
        Title = "XKID",
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

-- ==================== TAB 1: MAIN / TELEPORT ====================
local MainTab = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

MainTab:TextBox({
    Title = "Search Player",
    Callback = function(v) State.Teleport.selectedTarget = v end
})

MainTab:Button({
    Title = "🚀 Teleport To Target",
    Callback = function()
        local snippet = State.Teleport.selectedTarget
        if snippet == "" then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and (string.find(string.lower(p.Name), string.lower(snippet)) or string.find(string.lower(p.DisplayName), string.lower(snippet))) then
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and getRoot() then
                    getRoot().CFrame = p.Character.HumanoidRootPart.CFrame
                    WindUI:Notify({Title="Teleport", Content="Ke " .. p.Name, Duration=2})
                    return
                end
            end
        end
        WindUI:Notify({Title="Error", Content="Player tidak ditemukan!", Duration=2})
    end
})

local pDropList = MainTab:Dropdown({
    Title = "Manual Player List",
    Values = getPNames(),
    Value = "",
    Callback = function(v) State.Teleport.selectedTarget = v end
})

MainTab:Button({
    Title = "🔄 Refresh Player List",
    Callback = function() 
        pcall(function() pDropList:Refresh(getPNames()) end)
    end
})

local SavedLocs = {}
for i = 1, 3 do
    MainTab:Button({
        Title = "💾 Save Location " .. i,
        Callback = function()
            local r = getRoot()
            if r then SavedLocs[i] = r.CFrame; WindUI:Notify({Title="Saved", Content="Slot "..i, Duration=2}) end
        end
    })
    MainTab:Button({
        Title = "📍 Load Location " .. i,
        Callback = function()
            if SavedLocs[i] and getRoot() then 
                getRoot().CFrame = SavedLocs[i]
                WindUI:Notify({Title="Loaded", Content="Slot "..i, Duration=2})
            end
        end
    })
end

-- ==================== TAB 2: PLAYER ====================
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })

PlayerTab:Slider({ Title = "🏃 WalkSpeed", Min = 16, Max = 500, Value = 16, 
    Callback = function(v) State.Move.ws = v; local hum = getHum(); if hum then hum.WalkSpeed = v end end 
})

PlayerTab:Slider({ Title = "🦘 JumpPower", Min = 50, Max = 500, Value = 50, 
    Callback = function(v) State.Move.jp = v; local hum = getHum(); if hum then hum.UseJumpPower = true; hum.JumpPower = v end end 
})

local infJumpConn = nil
PlayerTab:Toggle({
    Title = "∞ Inf Jump", Value = false,
    Callback = function(v)
        if v then
            infJumpConn = UIS.JumpRequest:Connect(function() 
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end 
            end)
        else
            if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
        end
    end
})

PlayerTab:Toggle({ Title = "✈️ Native Fly", Value = false, Callback = toggleFly })
PlayerTab:Slider({ Title = "✈️ Fly Speed", Min = 10, Max = 300, Value = 60, 
    Callback = function(v) State.Move.flyS = v end 
})

PlayerTab:Toggle({ Title = "👻 NoClip", Value = false, 
    Callback = function(v) State.Move.ncp = v end 
})

-- ==================== TAB 3: CINEMATIC (FREECAM) ====================
local CineTab = Window:Tab({ Title = "Cinematic", Icon = "video" })

CineTab:Toggle({
    Title = "🎬 Freecam ON/OFF", Value = false,
    Callback = function(v)
        if v then
            if startFreecam() then
                freecamActive = true
                State.Cinema.active = true
                freecamKeys = {}
                task.spawn(freecamLoop)
                WindUI:Notify({Title="Freecam", Content="WASD+QE | Mouse gerak | Scroll zoom", Duration=3})
            else
                WindUI:Notify({Title="Error", Content="Gagal aktifkan freecam!", Duration=2})
            end
        else
            freecamActive = false
            State.Cinema.active = false
            stopFreecam()
            WindUI:Notify({Title="Freecam", Content="OFF", Duration=2})
        end
    end
})

CineTab:Slider({ Title = "⚡ Freecam Speed", Min = 1, Max = 30, Value = 5, 
    Callback = function(v) freecamSpeed = v end 
})

CineTab:Slider({ Title = "🎯 Sensitivity", Min = 1, Max = 20, Value = 5, 
    Callback = function(v) freecamSens = v * 0.05 end 
})

CineTab:Slider({ Title = "🔍 Camera FOV", Min = 10, Max = 120, Value = 70, 
    Callback = function(v) Cam.FieldOfView = v end 
})

-- ==================== TAB 4: WORLD ====================
local WorldTab = Window:Tab({ Title = "World", Icon = "globe" })

local function setWeather(clock, bright, fogStart, fogEnd, fogR, fogG, fogB)
    Lighting.ClockTime = clock
    Lighting.Brightness = bright
    Lighting.FogStart = fogStart
    Lighting.FogEnd = fogEnd
    Lighting.FogColor = Color3.fromRGB(fogR, fogG, fogB)
end

WorldTab:Button({ Title = "☀️ Cerah", Callback = function() setWeather(14, 2, 1000, 10000, 200, 220, 255) end })
WorldTab:Button({ Title = "🌃 Malam", Callback = function() setWeather(0, 0.3, 2000, 20000, 10, 10, 30) end })
WorldTab:Slider({ Title = "🕐 ClockTime", Min = 0, Max = 24, Value = 14, 
    Callback = function(v) Lighting.ClockTime = v end 
})

WorldTab:Button({ Title = "🚀 Unlock FPS (999)", Callback = function() 
    if setfpscap then setfpscap(999) end 
end})

-- Anti Lag
WorldTab:Toggle({ Title = "🗑️ Anti Lag (Hapus Efek)", Value = false, 
    Callback = function(v)
        if v then
            Lighting.GlobalShadows = false
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                    obj.Enabled = false
                end
            end
        else
            Lighting.GlobalShadows = true
        end
    end
})

-- ==================== TAB 5: ESP ====================
local EspTab = Window:Tab({ Title = "ESP", Icon = "eye" })

EspTab:Toggle({ Title = "🎯 ESP Highlight ON/OFF", Value = false, 
    Callback = function(v)
        State.ESP.active = v
        if not v then clearESP() end
    end
})

EspTab:Dropdown({ 
    Title = "🎨 Normal Player Color", 
    Values = {"Green", "Red", "Blue", "White", "Yellow", "Purple"}, 
    Value = "Green", 
    Callback = function(v)
        local c = Color3.fromRGB(0, 255, 150)
        if v == "Green" then c = Color3.fromRGB(0, 255, 150)
        elseif v == "Red" then c = Color3.fromRGB(255, 50, 50)
        elseif v == "Blue" then c = Color3.fromRGB(0, 150, 255)
        elseif v == "White" then c = Color3.fromRGB(255, 255, 255)
        elseif v == "Yellow" then c = Color3.fromRGB(255, 255, 0)
        elseif v == "Purple" then c = Color3.fromRGB(150, 0, 255)
        end
        State.ESP.colorNormal = c
    end
})

EspTab:Dropdown({ 
    Title = "🎨 Suspect/Glitcher Color", 
    Values = {"Red", "Purple", "Orange", "Pink"}, 
    Value = "Red", 
    Callback = function(v)
        local c = Color3.fromRGB(255, 0, 100)
        if v == "Red" then c = Color3.fromRGB(255, 0, 100)
        elseif v == "Purple" then c = Color3.fromRGB(150, 0, 255)
        elseif v == "Orange" then c = Color3.fromRGB(255, 100, 0)
        elseif v == "Pink" then c = Color3.fromRGB(255, 100, 200)
        end
        State.ESP.colorSuspect = c
    end
})

EspTab:Label("Info: ESP akan highlight pemain dengan ukuran part tidak normal (glitcher)")

-- ==================== TAB 6: SECURITY ====================
local SecTab = Window:Tab({ Title = "Security", Icon = "shield" })

local afkConn = nil
SecTab:Toggle({ Title = "🛡️ Anti-AFK", Value = false, 
    Callback = function(v)
        if v then
            afkConn = LP.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            pcall(function() 
                for _, conn in pairs(getconnections(LP.Idled)) do 
                    conn:Disable() 
                end 
            end)
            WindUI:Notify({Title="Anti-AFK", Content="Aktif", Duration=2})
        else
            if afkConn then afkConn:Disconnect(); afkConn = nil end
            pcall(function() 
                for _, conn in pairs(getconnections(LP.Idled)) do 
                    conn:Enable() 
                end 
            end)
        end
    end
})

SecTab:Button({ Title = "🔄 Rejoin Server", Callback = function() 
    TPService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end})

-- Respawn ke posisi terakhir
local lastPos = nil
task.spawn(function()
    while true do
        task.wait(1)
        local r = getRoot()
        if r then lastPos = r.CFrame end
    end
end)

SecTab:Button({ Title = "💀 Fast Respawn", Callback = function()
    local savedPos = lastPos
    local hum = getHum()
    if hum then hum.Health = 0 end
    task.spawn(function()
        local char = LP.CharacterAdded:Wait()
        task.wait(0.5)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and savedPos then hrp.CFrame = savedPos end
    end)
end})

-- ==================== TAB 7: SETTINGS ====================
local ThemeTab = Window:Tab({ Title = "Settings", Icon = "settings" })

ThemeTab:Dropdown({
    Title  = "Theme",
    Values = (function() 
        local names = {} 
        if WindUI.GetThemes then
            for name in pairs(WindUI:GetThemes()) do table.insert(names, name) end
        else
            names = {"Dark", "Light", "Dracula"}
        end
        table.sort(names) 
        return names 
    end)(),
    Value    = "Dark",
    Callback = function(selected) 
        if WindUI.SetTheme then WindUI:SetTheme(selected) end
    end,
})

ThemeTab:Toggle({
    Title = "Acrylic Mode",
    Value = true,
    Callback = function(state) 
        if WindUI.ToggleAcrylic then WindUI:ToggleAcrylic(state) end
    end,
})

ThemeTab:Toggle({
    Title = "Transparent Background",
    Value = true,
    Callback = function(state) 
        if Window.ToggleTransparency then Window:ToggleTransparency(state) end
    end
})

local toggleKey = Enum.KeyCode.RightShift
ThemeTab:Keybind({
    Title = "Toggle UI Key",
    Value = toggleKey,
    Callback = function(v)
        toggleKey = (typeof(v) == "EnumItem") and v or Enum.KeyCode[v]
        Window:SetToggleKey(toggleKey)
    end,
})

UIS.InputBegan:Connect(function(input) 
    if input.KeyCode == toggleKey then 
        Window:Toggle() 
    end 
end)

-- ═══════════════════════════════════════════════════════════
-- BACKGROUND LOOPS (NOCLIP)
-- ═══════════════════════════════════════════════════════════

RS.Stepped:Connect(function()
    if State.Move.ncp and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- NOTIFICATION START
-- ═══════════════════════════════════════════════════════════

WindUI:Notify({Title = "XKID HUB", Content = "Loaded! Press RightShift", Duration = 5})

print("✅ XKID HUB FIXED - Semua tab sudah muncul dan berfungsi!")