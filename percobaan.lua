-- ══════════════════════════════════════════════════════════════
--  FAST RESPAWN /re - STANDALONE TEST SCRIPT
--  By @WTF.XKID
--  Ketik /re di chat atau klik button di UI
-- ══════════════════════════════════════════════════════════════

-- Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")

-- ══════════════════════════════════════════════════════════════
--  LOAD WINDUI
-- ══════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- ══════════════════════════════════════════════════════════════
--  STATE
-- ══════════════════════════════════════════════════════════════
local RespawnState = {
    isRespawning = false,
    lastRespawn = 0,
    cooldown = 2,
    detectedRemotes = {},
    selectedMethod = "Auto",
    log = {},
}

-- ══════════════════════════════════════════════════════════════
--  HELPER
-- ══════════════════════════════════════════════════════════════
local function notify(title, content, dur)
    pcall(function() WindUI:Notify({ Title = title, Content = content, Duration = dur or 2 }) end)
end

local function addLog(msg)
    table.insert(RespawnState.log, "[" .. os.date("%H:%M:%S") .. "] " .. msg)
    if #RespawnState.log > 20 then table.remove(RespawnState.log, 1) end
end

-- ══════════════════════════════════════════════════════════════
--  DETEKSI SISTEM RESET
-- ══════════════════════════════════════════════════════════════
local function scanForResetRemotes()
    local found = {}
    
    -- Scan semua RemoteEvent di ReplicatedStorage
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("reset") or name:find("respawn") or name:find("reborn") or name:find("re/") then
                local fullPath = obj:GetFullName()
                table.insert(found, {
                    name = obj.Name,
                    path = fullPath,
                    type = obj.ClassName,
                    object = obj,
                })
            end
        end
    end
    
    -- Scan folder umum
    local commonFolders = {"Remotes", "Events", "Functions", "RemoteEvents", "RemoteFunctions"}
    for _, folderName in ipairs(commonFolders) do
        local folder = RS:FindFirstChild(folderName)
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local name = obj.Name:lower()
                    if name:find("reset") or name:find("respawn") then
                        local alreadyAdded = false
                        for _, f in ipairs(found) do
                            if f.object == obj then alreadyAdded = true; break end
                        end
                        if not alreadyAdded then
                            table.insert(found, {
                                name = obj.Name,
                                path = obj:GetFullName(),
                                type = obj.ClassName,
                                object = obj,
                            })
                        end
                    end
                end
            end
        end
    end
    
    RespawnState.detectedRemotes = found
    
    -- Log hasil
    addLog("Scan selesai: " .. #found .. " remote ditemukan")
    for _, r in ipairs(found) do
        addLog("  📡 " .. r.type .. ": " .. r.name)
    end
    
    return found
end

-- ══════════════════════════════════════════════════════════════
--  EKSEKUSI RESET
-- ══════════════════════════════════════════════════════════════
local function executeReset()
    -- Cek cooldown
    if RespawnState.isRespawning then
        notify("Respawn", "Masih proses... ⏳", 1.5)
        return
    end
    
    if tick() - RespawnState.lastRespawn < RespawnState.cooldown then
        local rem = math.ceil(RespawnState.cooldown - (tick() - RespawnState.lastRespawn))
        notify("Respawn", "Tunggu " .. rem .. " detik ⏳", 1.5)
        return
    end
    
    RespawnState.isRespawning = true
    RespawnState.lastRespawn = tick()
    
    local method = RespawnState.selectedMethod
    addLog("Execute reset | Method: " .. method)
    
    -- ⭐ METHOD 1: AUTO (pakai remote yang ditemukan)
    if method == "Auto" then
        if #RespawnState.detectedRemotes > 0 then
            local remote = RespawnState.detectedRemotes[1] -- Ambil pertama
            
            if remote.type == "RemoteEvent" then
                local success = pcall(function()
                    remote.object:FireServer()
                end)
                if success then
                    notify("Respawn", "✅ Reset via " .. remote.name, 2)
                    addLog("Success: " .. remote.name)
                else
                    notify("Respawn", "❌ Gagal fire " .. remote.name, 2)
                    addLog("Failed: " .. remote.name)
                    -- Fallback ke manual
                    manualReset()
                end
                
            elseif remote.type == "RemoteFunction" then
                local success = pcall(function()
                    remote.object:InvokeServer()
                end)
                if success then
                    notify("Respawn", "✅ Reset via " .. remote.name, 2)
                    addLog("Success: " .. remote.name)
                else
                    notify("Respawn", "❌ Gagal invoke " .. remote.name, 2)
                    addLog("Failed: " .. remote.name)
                    manualReset()
                end
            end
        else
            -- Gak ada remote, pakai manual
            notify("Respawn", "Gak ada remote, pakai manual 🔧", 2)
            addLog("No remote found, using manual")
            manualReset()
        end
    
    -- ⭐ METHOD 2: MANUAL (Health = 0 atau LoadCharacter)
    elseif method == "Manual" then
        manualReset()
    
    -- ⭐ METHOD 3: LOAD CHARACTER
    elseif method == "LoadCharacter" then
        pcall(function()
            LP:LoadCharacter()
        end)
        notify("Respawn", "✅ LoadCharacter()", 2)
        addLog("Manual: LoadCharacter()")
    
    -- ⭐ METHOD 4: HEALTH TRICK
    elseif method == "HealthTrick" then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                pcall(function()
                    hum.Health = 0
                end)
                notify("Respawn", "✅ Health = 0", 2)
                addLog("Manual: Health = 0")
            else
                pcall(function() LP:LoadCharacter() end)
                notify("Respawn", "✅ LoadCharacter()", 2)
                addLog("Manual: Fallback LoadCharacter()")
            end
        else
            pcall(function() LP:LoadCharacter() end)
            notify("Respawn", "✅ LoadCharacter()", 2)
            addLog("Manual: LoadCharacter() (no char)")
        end
    end
    
    -- Reset state setelah delay
    task.delay(1.5, function()
        RespawnState.isRespawning = false
    end)
end

-- ⭐ MANUAL RESET
local function manualReset()
    local char = LP.Character
    
    if not char then
        pcall(function() LP:LoadCharacter() end)
        notify("Respawn", "✅ Spawn karakter baru", 2)
        addLog("Manual: LoadCharacter()")
        return
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if hum and hum.Health > 0 then
        -- Coba health trick dulu
        pcall(function()
            hum.Health = 0
        end)
        
        -- Fallback setelah 0.5 detik
        task.delay(0.5, function()
            pcall(function()
                if char and char.Parent and hum and hum.Health > 0 then
                    -- Paksa break joints
                    char:BreakJoints()
                end
            end)
        end)
        
        -- Fallback terakhir
        task.delay(1, function()
            pcall(function()
                if char and char.Parent and hum and hum.Health > 0 then
                    LP:LoadCharacter()
                end
            end)
        end)
        
        notify("Respawn", "✅ Health trick + fallback", 2)
        addLog("Manual: Multi-stage reset")
    else
        pcall(function() LP:LoadCharacter() end)
        notify("Respawn", "✅ LoadCharacter()", 2)
        addLog("Manual: LoadCharacter() (dead)")
    end
end

-- ══════════════════════════════════════════════════════════════
--  CHAT COMMAND /re
-- ══════════════════════════════════════════════════════════════
local function isResetCommand(msg)
    local clean = msg:lower():gsub("%s+", "") -- Hapus semua spasi
    return clean == "/re" or clean == "/reset" or clean == "/respawn" or clean == "re" or clean == "reset"
end

local function setupChatCommand()
    -- TextChatService (Roblox baru)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            TextChatService.SendingMessage:Connect(function(message)
                local text = message.Text or message.Message or ""
                if isResetCommand(text) then
                    task.wait(0.1)
                    executeReset()
                end
            end)
            addLog("Chat: TextChatService mode")
        end
    end)
    
    -- Legacy Chat (Roblox lama)
    pcall(function()
        LP.Chatted:Connect(function(msg)
            if isResetCommand(msg) then
                task.wait(0.1)
                executeReset()
            end
        end)
        addLog("Chat: Legacy mode")
    end)
end

-- ══════════════════════════════════════════════════════════════
--  UI WINDOW
-- ══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title = "XKID", Subtitle = "Respawn Tester", Author = "by XKID",
    Icon = "rotate-cw", Theme = "Crimson",
    Acrylic = true, Transparent = true,
    Size = UDim2.fromOffset(500, 400),
    MinSize = Vector2.new(400, 300),
    ToggleKey = Enum.KeyCode.RightShift,
})

local T_MAIN = Window:Tab({ Title = "Respawn", Icon = "rotate-cw" })

-- ══════════════════════════════════════════════════════════════
--  SECTION: STATUS
-- ══════════════════════════════════════════════════════════════
local secStatus = T_MAIN:Section({ Title = "Status", Opened = true })
local statusLabel = secStatus:Paragraph({ Title = "System", Desc = "Ready..." })
local remoteLabel = secStatus:Paragraph({ Title = "Remotes Found", Desc = "Scanning..." })

-- Update status
task.spawn(function()
    while true do
        task.wait(1)
        local status = RespawnState.isRespawning and "🔄 RESPAWNING..." or "✅ Ready"
        pcall(function() statusLabel:SetDesc(status) end)
        pcall(function() remoteLabel:SetDesc(#RespawnState.detectedRemotes .. " remote(s) terdeteksi") end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  SECTION: METHOD SELECTOR
-- ══════════════════════════════════════════════════════════════
local secMethod = T_MAIN:Section({ Title = "Reset Method", Opened = true })

secMethod:Dropdown({
    Title = "Select Method",
    Values = {"Auto", "Manual", "LoadCharacter", "HealthTrick"},
    Value = "Auto",
    Callback = function(v)
        RespawnState.selectedMethod = v
        addLog("Method changed: " .. v)
        notify("Method", "Dipilih: " .. v, 2)
    end
})

secMethod:Paragraph({ 
    Title = "💡 Tips", 
    Desc = "Auto = Pakai remote game\nManual = Multi-stage reset\nLoadCharacter = Langsung spawn\nHealthTrick = Health = 0" 
})

-- ══════════════════════════════════════════════════════════════
--  SECTION: DETECTED REMOTES
-- ══════════════════════════════════════════════════════════════
local secRemotes = T_MAIN:Section({ Title = "Detected Remotes", Opened = true })
local remoteListLabel = secRemotes:Paragraph({ Title = "List", Desc = "Belum di-scan..." })

secRemotes:Button({ 
    Title = "🔍 Scan Remotes", 
    Callback = function()
        notify("Scanner", "Scanning... 🔍", 2)
        local remotes = scanForResetRemotes()
        
        if #remotes == 0 then
            pcall(function() remoteListLabel:SetDesc("❌ Gak ketemu remote reset!") end)
            notify("Scanner", "Gak ketemu remote! ⚠️", 3)
        else
            local text = ""
            for i, r in ipairs(remotes) do
                text = text .. string.format("[%d] %s\n    📍 %s\n\n", i, r.name, r.path:gsub("game%.ReplicatedStorage%.", ""))
            end
            pcall(function() remoteListLabel:SetDesc(text) end)
            notify("Scanner", "Ketemu " .. #remotes .. " remote! ✅", 2)
        end
    end 
})

-- ══════════════════════════════════════════════════════════════
--  SECTION: EXECUTE
-- ══════════════════════════════════════════════════════════════
local secExec = T_MAIN:Section({ Title = "Execute", Opened = true })

secExec:Button({ 
    Title = "⚡ RESPAWN NOW", 
    Callback = function()
        executeReset()
    end 
})

secExec:Paragraph({ 
    Title = "⌨️ Chat Command", 
    Desc = "Ketik /re di chat untuk reset" 
})

secExec:Slider({ 
    Title = "Cooldown (detik)", 
    Step = 0.5, 
    Value = { Min = 0, Max = 10, Default = 2 },
    Callback = function(v)
        RespawnState.cooldown = v
        addLog("Cooldown: " .. v .. " detik")
    end 
})

-- ══════════════════════════════════════════════════════════════
--  SECTION: LOG
-- ══════════════════════════════════════════════════════════════
local secLog = T_MAIN:Section({ Title = "Log", Opened = true })
local logLabel = secLog:Paragraph({ Title = "Activity", Desc = "Menunggu..." })

-- Update log realtime
task.spawn(function()
    while true do
        task.wait(0.5)
        local logText = table.concat(RespawnState.log, "\n")
        if #logText == 0 then logText = "Menunggu..." end
        pcall(function() logLabel:SetDesc(logText) end)
    end
end)

secLog:Button({ 
    Title = "🗑️ Clear Log", 
    Callback = function()
        RespawnState.log = {}
        addLog("Log cleared")
    end 
})

-- ══════════════════════════════════════════════════════════════
--  SECTION: PLAYER INFO
-- ══════════════════════════════════════════════════════════════
local secInfo = T_MAIN:Section({ Title = "Player Info", Opened = true })
secInfo:Paragraph({ Title = "Name", Desc = LP.DisplayName .. " (@" .. LP.Name .. ")" })
secInfo:Paragraph({ Title = "UserId", Desc = tostring(LP.UserId) })
secInfo:Paragraph({ Title = "PlaceId", Desc = tostring(game.PlaceId) })
secInfo:Paragraph({ Title = "JobId", Desc = game.JobId:sub(1, 12) .. "..." })

-- ══════════════════════════════════════════════════════════════
--  STARTUP
-- ══════════════════════════════════════════════════════════════
scanForResetRemotes()
setupChatCommand()

notify("Ready", "Ketik /re atau klik button! ⚡", 3)
addLog("Script loaded")
addLog("Remotes: " .. #RespawnState.detectedRemotes .. " terdeteksi")

print("=" .. string.rep("=", 50))
print("  XKID RESPAWN TESTER - READY")
print("  Ketik /re di chat!")
print("  " .. #RespawnState.detectedRemotes .. " remote(s) found")
print("=" .. string.rep("=", 50))