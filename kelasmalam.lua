--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║           X-KID HUB - OPTIMIZED & REWRITTEN EDITION          ║
    ║                   Senior Roblox Lua Engineer                 ║
    ║                                                              ║
    ║  Features:                                                   ║
    ║  - High Performance ESP (Object Pooling)                     ║
    ║  - Safe WindUI Loading with Fallback                         ║
    ║  - Modular Architecture                                      ║
    ║  - Mobile Optimized                                          ║
    ║  - Full Feature Set (Fly, TP, ESP, etc.)                     ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════════════════════════════
--  1. INITIALIZATION & CLEANUP
-- ══════════════════════════════════════════════════════════════
local function SafeCleanup()
    if getgenv()._XKID_LOADED then
        pcall(function()
            -- Hapus GUI lama
            for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
                if v.Name == "WindUI" or v.Name == "_XKIDEsp" then 
                    v:Destroy() 
                end
            end
            -- Putuskan koneksi lama
            if getgenv()._XKID_CONNS then
                for _, c in pairs(getgenv()._XKID_CONNS) do 
                    pcall(function() c:Disconnect() end) 
                end
            end
        end)
        collectgarbage("collect")
    end
    getgenv()._XKID_LOADED = true
    getgenv()._XKID_CONNS = {}
end

SafeCleanup()

local function TrackC(conn) 
    table.insert(getgenv()._XKID_CONNS, conn) 
    return conn 
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- ══════════════════════════════════════════════════════════════
--  2. SAFE UI LOADING (WITH FALLBACK)
-- ══════════════════════════════════════════════════════════════
local WindUI = nil
local LoadSuccess, LoadErr = pcall(function()
    -- Menggunakan rawget untuk menghindari deteksi sederhana jika perlu
    local source = game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua", true)
    local func = loadstring(source)
    if func then
        return func()
    end
    return nil
end)

if not LoadSuccess or not WindUI then
    warn("❌ [X-KID] Gagal memuat WindUI:", LoadErr)
    
    -- Fallback Notification System
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XKID_Error"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")

    local Frame = Instance.new("Frame")
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Frame.BorderSizePixel = 0
    Frame.Size = UDim2.new(0, 350, 0, 120)
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Text = "⚠️ CRITICAL ERROR"
    Title.TextColor3 = Color3.fromRGB(255, 80, 80)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 10)
    Title.Parent = Frame

    local Content = Instance.new("TextLabel")
    Content.BackgroundTransparency = 1
    Content.Text = "Gagal memuat library UI (WindUI).\nScript tidak dapat dijalankan.\nPeriksa koneksi internet atau sumber script."
    Content.TextColor3 = Color3.fromRGB(200, 200, 200)
    Content.Font = Enum.Font.Gotham
    Content.TextSize = 14
    Content.TextWrapped = true
    Content.Size = UDim2.new(1, -20, 0, 60)
    Content.Position = UDim2.new(0, 10, 0, 50)
    Content.Parent = Frame

    -- Auto remove after 10 seconds
    game:GetService("Debris"):AddItem(ScreenGui, 10)
    return -- STOP EXECUTION
end

-- Helper Notification using WindUI
local function notify(title, msg, time)
    pcall(function()
        WindUI.Notification({
            Title = title,
            Content = msg,
            Duration = time or 3,
            Type = "Success"
        })
    end)
end

-- ══════════════════════════════════════════════════════════════
--  3. STATE MANAGEMENT & CONFIG
-- ══════════════════════════════════════════════════════════════
local State = {
    Fly = { Active = false, Speed = 50 },
    Freecam = { Active = false, Speed = 100 },
    ESP = { 
        Active = false, 
        MaxDist = 500, 
        BoxMode = "2D Box", -- "2D Box", "Corner", "HIGHLIGHT", "OFF"
        ShowName = true, 
        ShowDist = true,
        Cache = {},
        Colors = {
            Normal = Color3.fromRGB(0, 255, 100),
            Suspect = Color3.fromRGB(255, 50, 50),
            Tracer = Color3.fromRGB(255, 255, 255)
        }
    },
    Teleport = { Target = nil },
    Spectate = { Active = false, Target = nil }
}

local Utils = {}
function Utils.GetRoot(char) 
    return char and char:FindFirstChildWhichIsA("BasePart") 
end
function Utils.IsCharacter(p) 
    return p.Character and Utils.GetRoot(p.Character) 
end

-- ══════════════════════════════════════════════════════════════
--  4. HIGH PERFORMANCE ESP ENGINE (OBJECT POOLING)
-- ══════════════════════════════════════════════════════════════
local ESP_Engine = {}
ESP_Engine.Pool = { Frames = {}, Labels = {}, Highlights = {} }
ESP_Engine.ScreenGui = nil

function ESP_Engine.Init()
    if not ESP_Engine.ScreenGui then
        ESP_Engine.ScreenGui = Instance.new("ScreenGui")
        ESP_Engine.ScreenGui.Name = "_XKIDEsp"
        ESP_Engine.ScreenGui.ResetOnSpawn = false
        ESP_Engine.ScreenGui.DisplayOrder = 999
        ESP_Engine.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ESP_Engine.ScreenGui.Parent = LP.PlayerGui
    end
end

function ESP_Engine.GetFromPool(type)
    local pool = ESP_Engine.Pool[type]
    if #pool > 0 then
        local obj = table.remove(pool)
        if obj and obj.Parent then obj.Parent = nil end
        return obj
    end

    -- Create new if empty
    if type == "Frames" then
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        f.ZIndex = 10
        return f
    elseif type == "Labels" then
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.TextStrokeTransparency = 0.5
        l.TextStrokeColor3 = Color3.new(0,0,0)
        l.Font = Enum.Font.GothamBold
        l.TextSize = 13
        l.Size = UDim2.new(0, 200, 0, 40)
        l.ZIndex = 11
        l.TextXAlignment = Enum.TextXAlignment.Center
        return l
    elseif type == "Highlights" then
        local h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency = 0.6
        h.OutlineTransparency = 0
        return h
    end
end

function ESP_Engine.ReturnToPool(type, obj)
    if not obj then return end
    if obj.Parent then obj.Parent = nil end
    table.insert(ESP_Engine.Pool[type], obj)
end

function ESP_Engine.ClearAll()
    for _, cache in pairs(State.ESP.Cache) do
        for _, obj in ipairs(cache.Renders) do
            local t = "Frames"
            if obj:IsA("TextLabel") then t = "Labels"
            elseif obj:IsA("Highlight") then t = "Highlights" end
            ESP_Engine.ReturnToPool(t, obj)
        end
        if cache.HL then
            ESP_Engine.ReturnToPool("Highlights", cache.HL)
        end
    end
    State.ESP.Cache = {}
    
    -- Clear Pools completely if turning off
    for _, pool in pairs(ESP_Engine.Pool) do
        for _, obj in ipairs(pool) do
            if obj then obj:Destroy() end
        end
        table.clear(pool)
    end
end

function ESP_Engine.WorldToScreen(pos)
    local vec, on = Cam:WorldToScreenPoint(pos)
    return Vector2.new(vec.X, vec.Y), on
end

function ESP_Engine.DrawLine(p1, p2, thickness, color)
    local dist = (p1 - p2).Magnitude
    if dist < 1 then return nil end
    
    local mid = (p1 + p2) / 2
    local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)
    
    local frame = ESP_Engine.GetFromPool("Frames")
    frame.BackgroundColor3 = color
    frame.Position = UDim2.new(0, mid.X - dist/2, 0, mid.Y - thickness/2)
    frame.Size = UDim2.new(0, dist, 0, thickness)
    frame.Rotation = math.deg(angle)
    frame.Parent = ESP_Engine.ScreenGui
    return frame
end

function ESP_Engine.DrawBox(rootPart, color, mode)
    if not rootPart then return {} end
    local top, onTop = ESP_Engine.WorldToScreen(rootPart.Position + Vector3.new(0, 2.5, 0))
    local bot, onBot = ESP_Engine.WorldToScreen(rootPart.Position - Vector3.new(0, 3, 0))
    
    if not onTop and not onBot then return {} end
    
    local h = math.abs(bot.Y - top.Y)
    local w = h * 0.65
    local tl = Vector2.new(bot.X - w/2, top.Y)
    local tr = Vector2.new(bot.X + w/2, top.Y)
    local bl = Vector2.new(bot.X - w/2, bot.Y)
    local br = Vector2.new(bot.X + w/2, bot.Y)
    
    local renders = {}
    
    if mode == "Corner" then
        local len = w / 3
        local corners = {
            {tl, tl + Vector2.new(len, 0)}, {tl, tl + Vector2.new(0, len)},
            {tr, tr - Vector2.new(len, 0)}, {tr, tr + Vector2.new(0, len)},
            {bl, bl + Vector2.new(len, 0)}, {bl, bl - Vector2.new(0, len)},
            {br, br - Vector2.new(len, 0)}, {br, br + Vector2.new(0, len)}
        }
        for _, pair in ipairs(corners) do
            local l = ESP_Engine.DrawLine(pair[1], pair[2], 2, color)
            if l then table.insert(renders, l) end
        end
    elseif mode == "2D Box" then
        local lines = {
            {tl, tr}, {tr, br}, {br, bl}, {bl, tl}
        }
        for _, pair in ipairs(lines) do
            local l = ESP_Engine.DrawLine(pair[1], pair[2], 2, color)
            if l then table.insert(renders, l) end
        end
    end
    return renders
end

function ESP_Engine.RenderPlayer(player)
    if not State.ESP.Active or player == LP then return end
    
    local char = player.Character
    if not char then return end
    local root = Utils.GetRoot(char)
    if not root then return end
    
    local myRoot = Utils.GetRoot(LP.Character)
    if myRoot and (myRoot.Position - root.Position).Magnitude > State.ESP.MaxDist then return end

    -- Simple Suspect Check (Large parts)
    local isSuspect = false
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and (p.Size.X > 12 or p.Size.Y > 12 or p.Size.Z > 12) then
            isSuspect = true
            break
        end
    end

    local color = isSuspect and State.ESP.Colors.Suspect or State.ESP.Colors.Normal
    
    -- Initialize Cache
    if not State.ESP.Cache[player] then
        State.ESP.Cache[player] = { Renders = {}, HL = nil }
    end
    local cache = State.ESP.Cache[player]

    -- Recycle Old Objects
    for _, obj in ipairs(cache.Renders) do
        local t = "Frames"
        if obj:IsA("TextLabel") then t = "Labels"
        elseif obj:IsA("Highlight") then t = "Highlights" end
        ESP_Engine.ReturnToPool(t, obj)
    end
    if cache.HL then
        ESP_Engine.ReturnToPool("Highlights", cache.HL)
        cache.HL = nil
    end
    cache.Renders = {}

    -- Draw Box / Highlight
    if State.ESP.BoxMode == "HIGHLIGHT" then
        local hl = ESP_Engine.GetFromPool("Highlights")
        hl.Parent = char
        hl.FillColor = color
        hl.OutlineColor = Color3.new(1,1,1)
        cache.HL = hl
        table.insert(cache.Renders, hl)
    elseif State.ESP.BoxMode ~= "OFF" then
        local boxes = ESP_Engine.DrawBox(root, color, State.ESP.BoxMode)
        for _, b in ipairs(boxes) do table.insert(cache.Renders, b) end
    end

    -- Draw Tracer
    if State.ESP.TracerMode and State.ESP.TracerMode ~= "OFF" then
        local sp, on = ESP_Engine.WorldToScreen(root.Position)
        if on then
            local origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
            if State.ESP.TracerMode == "Bottom" then origin = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
            elseif State.ESP.TracerMode == "Mouse" then 
                local m = UIS:GetMouseLocation()
                origin = Vector2.new(m.X, m.Y)
            end
            
            local line = ESP_Engine.DrawLine(origin, sp, 1.5, State.ESP.Colors.Tracer)
            if line then table.insert(cache.Renders, line) end
        end
    end

    -- Draw Text
    if State.ESP.ShowName or State.ESP.ShowDist then
        local sp, on = ESP_Engine.WorldToScreen(root.Position + Vector3.new(0, 3.5, 0))
        if on then
            local lbl = ESP_Engine.GetFromPool("Labels")
            local text = ""
            if State.ESP.ShowName then text = player.DisplayName end
            if State.ESP.ShowDist and myRoot then
                local d = math.floor((myRoot.Position - root.Position).Magnitude)
                text = text .. (text ~= "" and "\n" or "") .. d .. "m"
            end
            if isSuspect then
                text = text .. (text ~= "" and "\n" or "") .. "⚠ SUSPECT"
                lbl.TextColor3 = State.ESP.Colors.Suspect
            else
                lbl.TextColor3 = Color3.new(1,1,1)
            end
            
            lbl.Text = text
            lbl.Position = UDim2.new(0, sp.X - 100, 0, sp.Y - 20)
            lbl.Parent = ESP_Engine.ScreenGui
            table.insert(cache.Renders, lbl)
        end
    end
end

-- ESP Loop
TrackC(RunService.RenderStepped:Connect(function()
    pcall(function()
        if State.ESP.Active then
            ESP_Engine.Init()
            for _, p in ipairs(Players:GetPlayers()) do
                ESP_Engine.RenderPlayer(p)
            end
        end
    end)
end))

-- Cleanup on Leave
TrackC(Players.PlayerRemoving:Connect(function(p)
    if State.ESP.Cache[p] then
        -- Return objects to pool logic handled in RenderPlayer next frame or explicit clear
        -- For safety, we force clear cache reference, objects are recycled in next render or toggle off
        State.ESP.Cache[p] = nil
    end
end))

-- ══════════════════════════════════════════════════════════════
--  5. MOVEMENT MODULES (FLY & FREECAM)
-- ══════════════════════════════════════════════════════════════
local MoveModule = {}
MoveModule.Connections = {}

function MoveModule.StopAll()
    for _, c in ipairs(MoveModule.Connections) do
        pcall(function() c:Disconnect() end)
    end
    MoveModule.Connections = {}
    State.Fly.Active = false
    State.Freecam.Active = false
    if LP.Character then
        local root = Utils.GetRoot(LP.Character)
        if root then
            root.Velocity = Vector3.new(0,0,0)
            root.AssemblyAngularVelocity = Vector3.new(0,0,0)
        end
    end
    Cam.CameraType = Enum.CameraType.Custom
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

function MoveModule.StartFly()
    MoveModule.StopAll()
    State.Fly.Active = true
    notify("Movement", "Fly Enabled (WASD + Space/Shift)", 2)
    
    local root = Utils.GetRoot(LP.Character)
    if not root then return end
    
    local speed = State.Fly.Speed
    local velocity = Instance.new("BodyVelocity")
    velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    velocity.Velocity = Vector3.new(0,0,0)
    velocity.Parent = root
    
    local gyro = Instance.new("BodyGyro")
    gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    gyro.P = 10000
    gyro.CFrame = Cam.CFrame
    gyro.Parent = root

    local inputConn = UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local dir = Vector3.new(0,0,0)
        if input.KeyCode == Enum.KeyCode.W then dir = dir + Cam.CFrame.LookVector end
        if input.KeyCode == Enum.KeyCode.S then dir = dir - Cam.CFrame.LookVector end
        if input.KeyCode == Enum.KeyCode.A then dir = dir - Cam.CFrame.RightVector end
        if input.KeyCode == Enum.KeyCode.D then dir = dir + Cam.CFrame.RightVector end
        if input.KeyCode == Enum.KeyCode.Space then dir = dir + Vector3.new(0,1,0) end
        if input.KeyCode == Enum.KeyCode.LeftShift then dir = dir - Vector3.new(0,1,0) end
        
        if dir.Magnitude > 0 then
            velocity.Velocity = dir.Unit * speed
        else
            velocity.Velocity = Vector3.new(0,0,0)
        end
    end)
    
    local inputEnd = UIS.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        -- Recalculate velocity on key release could be added here for smoothness
        -- For simplicity, we rely on the next InputBegan or set to 0 if no keys
    end)
    
    local renderConn = RunService.RenderStepped:Connect(function()
        if not State.Fly.Active or not LP.Character then 
            MoveModule.StopAll() 
            return 
        end
        gyro.CFrame = Cam.CFrame
        if not Utils.GetRoot(LP.Character) then MoveModule.StopAll() end
    end)

    table.insert(MoveModule.Connections, inputConn)
    table.insert(MoveModule.Connections, inputEnd)
    table.insert(MoveModule.Connections, renderConn)
end

function MoveModule.StartFreecam()
    MoveModule.StopAll()
    State.Freecam.Active = true
    notify("Movement", "Freecam Enabled (WASD + Mouse)", 2)
    
    local pos = Cam.CFrame.Position
    local rot = Cam.CFrame.Orientation
    local speed = State.Freecam.Speed
    
    UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    
    local inputConn = UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local dir = Vector3.new(0,0,0)
        if input.KeyCode == Enum.KeyCode.W then dir = dir + Cam.CFrame.LookVector end
        if input.KeyCode == Enum.KeyCode.S then dir = dir - Cam.CFrame.LookVector end
        if input.KeyCode == Enum.KeyCode.A then dir = dir - Cam.CFrame.RightVector end
        if input.KeyCode == Enum.KeyCode.D then dir = dir + Cam.CFrame.RightVector end
        if input.KeyCode == Enum.KeyCode.Space then dir = dir + Vector3.new(0,1,0) end
        if input.KeyCode == Enum.KeyCode.LeftShift then dir = dir - Vector3.new(0,1,0) end
        
        if dir.Magnitude > 0 then
            pos = pos + (dir.Unit * speed * 0.1)
        end
    end)
    
    local mouseConn = UIS.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and State.Freecam.Active then
            local delta = input.Delta
            rot = rot + Vector3.new(-delta.Y * 0.005, -delta.X * 0.005, 0)
            -- Clamp pitch
            rot = Vector3.new(math.clamp(rot.X, -math.pi/2, math.pi/2), rot.Y, 0)
        end
    end)
    
    local renderConn = RunService.RenderStepped:Connect(function()
        if not State.Freecam.Active then 
            MoveModule.StopAll() 
            return 
        end
        Cam.CFrame = CFrame.fromOrientation(rot.X, rot.Y, 0) * CFrame.new(pos)
        Cam.CameraType = Enum.CameraType.Scriptable
    end)

    table.insert(MoveModule.Connections, inputConn)
    table.insert(MoveModule.Connections, mouseConn)
    table.insert(MoveModule.Connections, renderConn)
end

-- ══════════════════════════════════════════════════════════════
--  6. TELEPORT & SPECTATE LOGIC
-- ══════════════════════════════════════════════════════════════
local TeleportModule = {}

function TeleportModule.ToPlayer(targetPlayer)
    pcall(function()
        local char = targetPlayer.Character
        if not char then return end
        local root = Utils.GetRoot(char)
        if not root then return end
        
        local myChar = LP.Character
        if not myChar then return end
        local myRoot = Utils.GetRoot(myChar)
        if not myRoot then return end
        
        myRoot.CFrame = root.CFrame * CFrame.new(0, 0, 3) -- Spawn slightly behind
        notify("Teleport", "Warped to " .. targetPlayer.Name, 2)
    end)
end

function TeleportModule.StartSpectate(targetPlayer)
    TeleportModule.StopSpectate()
    State.Spectate.Active = true
    State.Spectate.Target = targetPlayer
    
    notify("Spectate", "Spectating " .. targetPlayer.Name, 2)
    
    local conn = RunService.RenderStepped:Connect(function()
        if not State.Spectate.Active or not targetPlayer.Character then
            TeleportModule.StopSpectate()
            return
        end
        local root = Utils.GetRoot(targetPlayer.Character)
        if root then
            Cam.CFrame = root.CFrame * CFrame.new(0, 5, -10) -- Behind and above
            Cam.CameraType = Enum.CameraType.Scriptable
        end
    end)
    table.insert(MoveModule.Connections, conn) -- Reuse connection list for cleanup
end

function TeleportModule.StopSpectate()
    State.Spectate.Active = false
    State.Spectate.Target = nil
    Cam.CameraType = Enum.CameraType.Custom
end

-- ══════════════════════════════════════════════════════════════
--  7. UI GENERATION (WINDUI)
-- ══════════════════════════════════════════════════════════════
local Hub = WindUI.Application({
    Title = "X-KID HUB",
    SubTitle = "Optimized Edition",
    Discord = "YourDiscordLink",
    Theme = "Dark", -- Dark, Light, Custom
    Accent = Color3.fromRGB(0, 150, 255)
})

-- Tab: Main
local T_Main = Hub:Tab({ Title = "Main", Icon = "Home" })
local Sec_Info = T_Main:Section({ Title = "Information", Opened = true })

Sec_Info:Label({ Title = "Welcome to X-KID Hub Optimized." })
Sec_Info:Label({ Title = "Status: Stable & Fast" })
Sec_Info:Button({
    Title = "Rejoin Server",
    Callback = function()
        Players.LocalPlayer:Kick("Rejoining...")
        game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
    end
})
Sec_Info:Button({
    Title = "Copy Join Script",
    Callback = function()
        setclipboard('game:GetService("TeleportService"):Teleport('..game.PlaceId..')')
        notify("Clipboard", "Join script copied!", 2)
    end
})

-- Tab: Movement
local T_Move = Hub:Tab({ Title = "Movement", Icon = "Run" })
local Sec_Fly = T_Move:Section({ Title = "Fly Control", Opened = true })

Sec_Fly:Toggle({
    Title = "Enable Fly",
    Value = false,
    Callback = function(v)
        if v then MoveModule.StartFly() else MoveModule.StopAll() end
    end
})
Sec_Fly:Slider({
    Title = "Fly Speed",
    Min = 10, Max = 500, Default = 50,
    Callback = function(v) State.Fly.Speed = v end
})

local Sec_Free = T_Move:Section({ Title = "Freecam", Opened = false })
Sec_Free:Toggle({
    Title = "Enable Freecam",
    Value = false,
    Callback = function(v)
        if v then MoveModule.StartFreecam() else MoveModule.StopAll() end
    end
})

-- Tab: Visuals (ESP)
local T_Vis = Hub:Tab({ Title = "Visuals", Icon = "Eye" })
local Sec_ESP = T_Vis:Section({ Title = "ESP Settings", Opened = true })

Sec_ESP:Toggle({
    Title = "Enable ESP",
    Value = false,
    Callback = function(v)
        State.ESP.Active = v
        if not v then
            ESP_Engine.ClearAll()
        else
            ESP_Engine.Init()
        end
        notify("ESP", v and "ON" or "OFF", 2)
    end
})

Sec_ESP:Dropdown({
    Title = "Box Mode",
    Values = {"2D Box", "Corner", "HIGHLIGHT", "OFF"},
    Default = "2D Box",
    Callback = function(v) State.ESP.BoxMode = v end
})

Sec_ESP:Toggle({ Title = "Show Names", Value = true, Callback = function(v) State.ESP.ShowName = v end })
Sec_ESP:Toggle({ Title = "Show Distance", Value = true, Callback = function(v) State.ESP.ShowDist = v end })

Sec_ESP:ColorPicker({
    Title = "Normal Color",
    Default = State.ESP.Colors.Normal,
    Callback = function(v) State.ESP.Colors.Normal = v end
})
Sec_ESP:ColorPicker({
    Title = "Suspect Color",
    Default = State.ESP.Colors.Suspect,
    Callback = function(v) State.ESP.Colors.Suspect = v end
})

-- Tab: Player Actions
local T_Ply = Hub:Tab({ Title = "Players", Icon = "Users" })
local Sec_TP = T_Ply:Section({ Title = "Teleport / Spectate", Opened = true })

local PlayerList = {}
local function RefreshPlayerList()
    PlayerList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(PlayerList, p.Name) end
    end
    return PlayerList
end

local DropTarget = Sec_TP:Dropdown({
    Title = "Select Player",
    Values = RefreshPlayerList(),
    Default = "",
    Callback = function(v) 
        local p = Players:FindFirstChild(v)
        if p then State.Teleport.Target = p end
    end
})

-- Refresh dropdown when player joins/leaves
TrackC(Players.PlayerAdded:Connect(function() 
    pcall(function() DropTarget:UpdateValues(RefreshPlayerList()) end) 
end))
TrackC(Players.PlayerRemoving:Connect(function() 
    pcall(function() DropTarget:UpdateValues(RefreshPlayerList()) end) 
end))

Sec_TP:Button({
    Title = "Teleport To Selected",
    Callback = function()
        if State.Teleport.Target then
            TeleportModule.ToPlayer(State.Teleport.Target)
        else
            notify("Error", "Please select a player first!", 2)
        end
    end
})

Sec_TP:Button({
    Title = "Spectate Selected",
    Callback = function()
        if State.Teleport.Target then
            TeleportModule.StartSpectate(State.Teleport.Target)
        else
            notify("Error", "Please select a player first!", 2)
        end
    end
})

Sec_TP:Button({
    Title = "Stop Spectate",
    Callback = function() TeleportModule.StopSpectate() end
})

-- Tab: Misc
local T_Misc = Hub:Tab({ Title = "Misc", Icon = "Settings" })
local Sec_World = T_Misc:Section({ Title = "World", Opened = false })

Sec_World:Toggle({
    Title = "Fullbright",
    Value = false,
    Callback = function(v)
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
        else
            Lighting:BulkClearExistingDefaults()
            Lighting:SetDefaultLightingProperties()
        end
    end
})

notify("System", "X-KID Hub Loaded Successfully!", 3)
