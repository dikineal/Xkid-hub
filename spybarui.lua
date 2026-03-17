--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   S U P E R   L I T E              ║
  ║          VERSI PALING SEDERHANA - PASTI WORK         ║
  ╚═══════════════════════════════════════════════════════╝
]]

-- ============================================
--  LOAD UI YANG PALING RINGAN
-- ============================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()

-- ============================================
--  BUAT WINDOW SEDERHANA
-- ============================================
local Win = Library:Window("XKID LITE", "cpu", "Untuk Delta", false)

-- ============================================
--  TABS
-- ============================================
local Tab1 = Win:Tab("📡 REMOTE", "search")
local Tab2 = Win:Tab("🚶 MOVE", "activity")
local Tab3 = Win:Tab("📦 OBJEK", "package")
local Tab4 = Win:Tab("📋 LOG", "file-text")

-- ============================================
--  SERVICES
-- ============================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- ============================================
--  DATA
-- ============================================
local allRemotes = {}
local moveLog = {}
local objLog = {}

-- ============================================
--  FUNGSI COPY (PASTI WORK)
-- ============================================
local function copyText(text)
    pcall(function() setclipboard(text) end)
    Library:Notification("✅", "Copied!", 1)
end

-- ============================================
--  SCAN REMOTE
-- ============================================
local function scanRemotes()
    allRemotes = {}
    local places = {RS, Workspace}
    
    for _, place in ipairs(places) do
        if place then
            for _, obj in ipairs(place:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    table.insert(allRemotes, obj.Name .. " | " .. obj.ClassName)
                end
            end
        end
    end
end

-- ============================================
--  TAB 1: REMOTE
-- ============================================
local Page1 = Tab1:Page("REMOTE", "search")
local Left1 = Page1:Section("KONTROL", "Left")
local Right1 = Page1:Section("LIST", "Right")

Left1:Button("🔍 SCAN", "Scan semua remote", function()
    scanRemotes()
    Library:Notification("✅", "Ditemukan " .. #allRemotes .. " remote", 2)
end)

Left1:Button("🗑️ CLEAR", "Hapus", function()
    allRemotes = {}
    Library:Notification("✅", "Cleared", 1)
end)

Right1:Button("📋 LIST", "Tampilkan remote", function()
    if #allRemotes == 0 then
        Library:Notification("❌", "Scan dulu", 1)
        return
    end
    
    local text = "REMOTE:\n"
    for i = 1, math.min(15, #allRemotes) do
        text = text .. i .. ". " .. allRemotes[i] .. "\n"
    end
    Library:Notification("📋 LIST", text, 8)
end)

Right1:Button("📋 COPY", "Copy ke clipboard", function()
    if #allRemotes == 0 then return end
    copyText(table.concat(allRemotes, "\n"))
end)

-- ============================================
--  TAB 2: MOVE TRACKER
-- ============================================
local Page2 = Tab2:Page("MOVE", "activity")
local Left2 = Page2:Section("KONTROL", "Left")
local Right2 = Page2:Section("LOG", "Right")

local moveActive = false
local moveConn = nil

Left2:Toggle("🚶 TRACK", "MoveToggle", false, "Track pergerakan", function(v)
    moveActive = v
    
    if v then
        moveLog = {}
        local lastPos = nil
        
        moveConn = RunService.Heartbeat:Connect(function()
            if not moveActive then return end
            
            local char = LP.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            local pos = hrp.Position
            if lastPos and (pos - lastPos).Magnitude > 3 then
                local entry = string.format("[%s] (%.1f,%.1f,%.1f)", 
                    os.date("%H:%M:%S"), pos.X, pos.Y, pos.Z)
                table.insert(moveLog, 1, entry)
                if #moveLog > 20 then table.remove(moveLog) end
            end
            lastPos = pos
        end)
        
        Library:Notification("✅", "Move ON", 1)
    else
        if moveConn then
            moveConn:Disconnect()
            moveConn = nil
        end
        Library:Notification("✅", "Move OFF", 1)
    end
end)

Left2:Button("🗑️ CLEAR", "Hapus log", function()
    moveLog = {}
    Library:Notification("✅", "Cleared", 1)
end)

Right2:Button("📋 LIHAT", "Lihat log", function()
    if #moveLog == 0 then
        Library:Notification("❌", "Kosong", 1)
        return
    end
    
    local text = "MOVE LOG:\n"
    for i = 1, math.min(10, #moveLog) do
        text = text .. moveLog[i] .. "\n"
    end
    Library:Notification("📋 LOG", text, 6)
end)

Right2:Button("📋 COPY", "Copy log", function()
    if #moveLog == 0 then return end
    copyText(table.concat(moveLog, "\n"))
end)

-- ============================================
--  TAB 3: OBJEK TRACKER
-- ============================================
local Page3 = Tab3:Page("OBJEK", "package")
local Left3 = Page3:Section("KONTROL", "Left")
local Right3 = Page3:Section("LOG", "Right")

local objActive = false
local objAdded = nil
local objRemoved = nil

Left3:Toggle("📦 TRACK", "ObjToggle", false, "Track objek", function(v)
    objActive = v
    
    if v then
        objLog = {}
        
        objAdded = Workspace.DescendantAdded:Connect(function(obj)
            if not objActive then return end
            if obj:IsA("BasePart") and #obj.Name > 1 then
                local entry = string.format("[%s] + %s", os.date("%H:%M:%S"), obj.Name)
                table.insert(objLog, 1, entry)
                if #objLog > 20 then table.remove(objLog) end
            end
        end)
        
        objRemoved = Workspace.DescendantRemoving:Connect(function(obj)
            if not objActive then return end
            if obj:IsA("BasePart") and #obj.Name > 1 then
                local entry = string.format("[%s] - %s", os.date("%H:%M:%S"), obj.Name)
                table.insert(objLog, 1, entry)
                if #objLog > 20 then table.remove(objLog) end
            end
        end)
        
        Library:Notification("✅", "Objek ON", 1)
    else
        if objAdded then objAdded:Disconnect() end
        if objRemoved then objRemoved:Disconnect() end
        Library:Notification("✅", "Objek OFF", 1)
    end
end)

Left3:Button("🗑️ CLEAR", "Hapus log", function()
    objLog = {}
    Library:Notification("✅", "Cleared", 1)
end)

Right3:Button("📋 LIHAT", "Lihat log", function()
    if #objLog == 0 then
        Library:Notification("❌", "Kosong", 1)
        return
    end
    
    local text = "OBJEK LOG:\n"
    for i = 1, math.min(10, #objLog) do
        text = text .. objLog[i] .. "\n"
    end
    Library:Notification("📋 LOG", text, 6)
end)

Right3:Button("📋 COPY", "Copy log", function()
    if #objLog == 0 then return end
    copyText(table.concat(objLog, "\n"))
end)

-- ============================================
--  TAB 4: GABUNGAN LOG
-- ============================================
local Page4 = Tab4:Page("LOG", "file-text")
local Left4 = Page4:Section("KONTROL", "Left")
local Right4 = Page4:Section("GABUNGAN", "Right")

Left4:Button("🗑️ CLEAR ALL", "Hapus semua", function()
    moveLog = {}
    objLog = {}
    Library:Notification("✅", "All cleared", 1)
end)

Right4:Button("📋 LIHAT", "Lihat gabungan", function()
    local all = {}
    for _, v in ipairs(moveLog) do table.insert(all, "[MOVE] " .. v) end
    for _, v in ipairs(objLog) do table.insert(all, "[OBJ] " .. v) end
    
    if #all == 0 then
        Library:Notification("❌", "Kosong", 1)
        return
    end
    
    local text = "SEMUA LOG:\n"
    for i = 1, math.min(15, #all) do
        text = text .. all[i] .. "\n"
    end
    Library:Notification("📋 LOG", text, 8)
end)

Right4:Button("📋 COPY", "Copy semua", function()
    local all = {}
    for _, v in ipairs(moveLog) do table.insert(all, "[MOVE] " .. v) end
    for _, v in ipairs(objLog) do table.insert(all, "[OBJ] " .. v) end
    
    if #all == 0 then return end
    copyText(table.concat(all, "\n"))
end)

-- ============================================
--  START
-- ============================================
Library:Notification("✅ XKID LITE", "Siap! Pilih tab:", 3)

print("╔══════════════════════════════════════╗")
print("║   🔌 XKID SUPER LITE                ║")
print("║   PALING RINGAN - PASTI WORK        ║")
print("║                                      ║")
print("║   CARA PAKAI:                        ║")
print("║   1. SCAN remote (tab REMOTE)        ║")
print("║   2. TRACK MOVE & OBJEK               ║")
print("║   3. LIHAT LOG & COPY                  ║")
print("╚══════════════════════════════════════╝")