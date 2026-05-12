-- ══════════════════════════════════════════════════════════════
--  FAST RESPAWN /re - AGGRESSIVE SCANNER
--  Scan semua cara reset yang ada di game
-- ══════════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")
local WS = game:GetService("Workspace")
local SG = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- State
local State = {
    isRespawning = false,
    lastRespawn = 0,
    cooldown = 2,
    foundMethods = {},
    selectedMethod = "Auto",
    log = {},
}

local function notify(title, content, dur)
    pcall(function() WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 }) end)
end

local function addLog(msg)
    table.insert(State.log, "[" .. os.date("%H:%M:%S") .. "] " .. msg)
    if #State.log > 30 then table.remove(State.log, 1) end
    print("[RESPAWN]", msg)
end

-- ══════════════════════════════════════════════════════════════
--  SCANNER SUPER AGRESIF
-- ══════════════════════════════════════════════════════════════
local function aggressiveScan()
    local methods = {}
    
    addLog("🔍 Scanning all reset methods...")
    
    -- ===== 1. RemoteEvent dengan kata kunci reset =====
    local keywords = {"reset", "respawn", "reborn", "re/", "die", "kill", "suicide", "revive", "spawn", "loadchar"}
    
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
            local name = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if name:find(kw) then
                    table.insert(methods, {
                        name = obj.Name,
                        type = obj.ClassName,
                        object = obj,
                        method = "Fire",
                        priority = name:find("reset") and 1 or 3,
                    })
                    break
                end
            end
        end
    end
    
    -- ===== 2. ProximityPrompt / ClickDetector =====
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parentName = obj.Parent and obj.Parent.Name:lower() or ""
            if parentName:find("reset") or parentName:find("respawn") or parentName:find("die") then
                table.insert(methods, {
                    name = "ProximityPrompt: " .. obj.Parent.Name,
                    type = "ProximityPrompt",
                    object = obj,
                    method = "Prompt",
                    priority = 2,
                })
            end
        elseif obj:IsA("ClickDetector") then
            local parentName = obj.Parent and obj.Parent.Name:lower() or ""
            if parentName:find("reset") or parentName:find("respawn") then
                table.insert(methods, {
                    name = "ClickDetector: " .. obj.Parent.Name,
                    type = "ClickDetector",
                    object = obj,
                    method = "Click",
                    priority = 2,
                })
            end
        end
    end
    
    -- ===== 3. GUI Button (ScreenGui / SurfaceGui) =====
    for _, player in ipairs(Players:GetPlayers()) do
        local gui = player:FindFirstChild("PlayerGui")
        if gui then
            for _, screen in ipairs(gui:GetDescendants()) do
                if screen:IsA("TextButton") or screen:IsA("ImageButton") then
                    local text = screen:IsA("TextButton") and screen.Text:lower() or ""
                    local name = screen.Name:lower()
                    if text:find("reset") or text:find("respawn") or text:find("menu") or
                       name:find("reset") or name:find("respawn") or name:find("menu") then
                        table.insert(methods, {
                            name = "Button: " .. screen.Name,
                            type = "GuiButton",
                            object = screen,
                            method = "Click",
                            priority = 4,
                        })
                    end
                end
            end
        end
    end
    
    -- ===== 4. CoreGui reset button =====
    pcall(function()
        local resetButton = SG:FindFirstChild("ResetButton")
        if resetButton then
            table.insert(methods, {
                name = "CoreGui ResetButton",
                type = "CoreGui",
                object = resetButton,
                method = "CoreGui",
                priority = 3,
            })
        end
    end)
    
    -- ===== 5. Method client-side universal =====
    -- Ini selalu work di semua game
    table.insert(methods, {
        name = "Health = 0 (Universal)",
        type = "Universal",
        object = nil,
        method = "HealthTrick",
        priority = 5,
    })
    
    table.insert(methods, {
        name = "LoadCharacter (Universal)",
        type = "Universal",
        object = nil,
        method = "LoadChar",
        priority = 6,
    })
    
    -- Sort by priority
    table.sort(methods, function(a, b) return a.priority < b.priority end)
    
    State.foundMethods = methods
    
    addLog("✅ Found " .. #methods .. " methods total")
    for _, m in ipairs(methods) do
        addLog("  📡 [" .. m.priority .. "] " .. m.type .. ": " .. m.name)
    end
    
    return methods
end

-- ══════════════════════════════════════════════════════════════
--  EKSEKUSI RESET
-- ══════════════════════════════════════════════════════════════
local function executeReset(forceMethod)
    if State.isRespawning then return end
    if tick() - State.lastRespawn < State.cooldown then
        notify("Cooldown", "Tunggu sebentar... ⏳", 1.5)
        return
    end
    
    State.isRespawning = true
    State.lastRespawn = tick()
    
    local method = forceMethod or State.selectedMethod
    
    addLog("⚡ Execute: " .. method)
    
    -- ⭐ AUTO: Coba semua method berurutan
    if method == "Auto" then
        if #State.foundMethods == 0 then aggressiveScan() end
        
        for i, m in ipairs(State.foundMethods) do
            addLog("  Trying [" .. i .. "/" .. #State.foundMethods .. "] " .. m.name)
            
            local success = false
            
            if m.type == "RemoteEvent" then
                success = pcall(function() m.object:FireServer() end)
            elseif m.type == "RemoteFunction" then
                success = pcall(function() m.object:InvokeServer() end)
            elseif m.type == "BindableEvent" then
                success = pcall(function() m.object:Fire() end)
            elseif m.type == "BindableFunction" then
                success = pcall(function() m.object:Invoke() end)
            elseif m.type == "ProximityPrompt" then
                success = pcall(function() fireproximityprompt(m.object) end)
            elseif m.type == "ClickDetector" then
                success = pcall(function() fireclickdetector(m.object) end)
            elseif m.type == "GuiButton" then
                -- Simulate click pakai VirtualInputManager
                success = pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    -- Kirim mouse click ke posisi button
                    local pos = m.object.AbsolutePosition + m.object.AbsoluteSize / 2
                    vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                    vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                end)
            elseif m.type == "Universal" then
                if m.method == "HealthTrick" then
                    success = healthTrickReset()
                elseif m.method == "LoadChar" then
                    success = pcall(function() LP:LoadCharacter() end)
                end
            end
            
            if success then
                notify("Reset", "✅ " .. m.name, 2)
                addLog("  ✅ SUCCESS: " .. m.name)
                task.delay(1.5, function() State.isRespawning = false end)
                return
            else
                addLog("  ❌ FAILED: " .. m.name)
            end
            
            task.wait(0.3) -- Jeda antar attempt
        end
        
        -- Kalau semua gagal, pakai universal
        addLog("  🔧 Fallback ke Universal...")
        healthTrickReset()
    
    -- ⭐ MANUAL: Health trick + fallback
    elseif method == "Manual" then
        healthTrickReset()
    
    -- ⭐ LOADCHAR: Langsung LoadCharacter
    elseif method == "LoadCharacter" then
        pcall(function() LP:LoadCharacter() end)
        notify("Reset", "✅ LoadCharacter()", 2)
        addLog("  ✅ LoadCharacter")
    
    -- ⭐ HEALTH TRICK: Health = 0
    elseif method == "HealthTrick" then
        healthTrickReset()
    end
    
    task.delay(2, function() State.isRespawning = false end)
end

-- ⭐ HEALTH TRICK (Multi-stage fallback)
local function healthTrickReset()
    local char = LP.Character
    
    if not char then
        pcall(function() LP:LoadCharacter() end)
        return true
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        pcall(function() LP:LoadCharacter() end)
        return true
    end
    
    if hum.Health <= 0 then
        -- Udah mati, tunggu respawn natural
        pcall(function() LP:LoadCharacter() end)
        return true
    end
    
    -- Stage 1: Health = 0
    pcall(function() hum.Health = 0 end)
    
    -- Stage 2: BreakJoints (0.3 detik)
    task.delay(0.3, function()
        pcall(function()
            if char and char.Parent and hum and hum.Health > 0 then
                char:BreakJoints()
            end
        end)
    end)
    
    -- Stage 3: Parent nil + LoadCharacter (0.6 detik)
    task.delay(0.6, function()
        pcall(function()
            if char and char.Parent and hum and hum.Health > 0 then
                char.Parent = nil
                LP:LoadCharacter()
            end
        end)
    end)
    
    notify("Reset", "⚡ Multi-stage reset...", 2)
    return true
end

-- ══════════════════════════════════════════════════════════════
--  CHAT COMMAND
-- ══════════════════════════════════════════════════════════════
local function isResetCommand(msg)
    local clean = msg:lower():gsub("%s+", "")
    return clean == "/re" or clean == "/reset" or clean == "/respawn" or clean == "re" or clean == "reset"
end

-- TextChatService
pcall(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.SendingMessage:Connect(function(msg)
            local text = msg.Text or msg.Message or ""
            if isResetCommand(text) then
                task.wait(0.1)
                executeReset()
            end
        end)
        addLog("Chat: TextChatService mode")
    end
end)

-- Legacy Chat
pcall(function()
    LP.Chatted:Connect(function(msg)
        if isResetCommand(msg) then
            task.wait(0.1)
            executeReset()
        end
    end)
    addLog("Chat: Legacy mode")
end)

-- ══════════════════════════════════════════════════════════════
--  UI WINDOW
-- ══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title = "XKID", Subtitle = "Respawn /re", Author = "by XKID",
    Icon = "rotate-cw", Theme = "Crimson",
    Acrylic = true, Transparent = true,
    Size = UDim2.fromOffset(520, 450),
    ToggleKey = Enum.KeyCode.RightShift,
})

local T_MAIN = Window:Tab({ Title = "Respawn", Icon = "rotate-cw" })

-- Status
T_MAIN:Section({ Title = "Status", Opened = true })
    :Paragraph({ Title = "Command", Desc = "Ketik /re di chat ✨" })
    :Paragraph({ Title = "Cooldown", Desc = "2 detik" })

-- Methods Display
local methodsLabel
local secMethods = T_MAIN:Section({ Title = "Methods Found", Opened = true })
methodsLabel = secMethods:Paragraph({ Title = "Available", Desc = "Belum di-scan..." })

secMethods:Button({ 
    Title = "🔍 RE-SCAN", 
    Callback = function()
        aggressiveScan()
        local text = ""
        for i, m in ipairs(State.foundMethods) do
            text = text .. string.format("[%d] %s (%s)\n", i, m.name, m.type)
        end
        pcall(function() methodsLabel:SetDesc(text) end)
    end 
})

-- Execute Button
T_MAIN:Section({ Title = "Execute", Opened = true })
    :Button({ 
        Title = "⚡ RESPAWN NOW", 
        Callback = function() executeReset() end 
    })

-- Method Selector
T_MAIN:Section({ Title = "Override Method", Opened = true })
    :Dropdown({
        Title = "Force Method",
        Values = {"Auto", "Manual", "LoadCharacter", "HealthTrick"},
        Value = "Auto",
        Callback = function(v) State.selectedMethod = v end
    })
    :Slider({
        Title = "Cooldown (detik)",
        Step = 0.5,
        Value = { Min = 0, Max = 10, Default = 2 },
        Callback = function(v) State.cooldown = v end
    })

-- Log
local logLabel
local secLog = T_MAIN:Section({ Title = "Log", Opened = true })
logLabel = secLog:Paragraph({ Title = "Activity", Desc = "Menunggu..." })

task.spawn(function()
    while true do
        task.wait(0.3)
        local text = table.concat(State.log, "\n")
        if #text == 0 then text = "Menunggu..." end
        pcall(function() logLabel:SetDesc(text) end)
    end
end)

secLog:Button({ Title = "🗑️ Clear Log", Callback = function() State.log = {} end })

-- ══════════════════════════════════════════════════════════════
--  STARTUP
-- ══════════════════════════════════════════════════════════════
aggressiveScan()

-- Update UI methods
local text = ""
for i, m in ipairs(State.foundMethods) do
    text = text .. string.format("[%d] %s (%s)\n", i, m.name, m.type)
end
pcall(function() methodsLabel:SetDesc(text) end)

notify("Ready", "Ketik /re atau klik button! ⚡\n" .. #State.foundMethods .. " methods found", 4)
print("=" .. string.rep("=", 50))
print("  XKID RESPAWN - AGGRESSIVE MODE")
print("  " .. #State.foundMethods .. " methods terdeteksi")
print("  Ketik /re di chat!")
print("=" .. string.rep("=", 50))