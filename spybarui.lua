--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🔌  X K I D   M I N I M A L   T R A C K E R    ║
  ║              KHUSUS DELTA - PASTI WORK               ║
  ╚═══════════════════════════════════════════════════════╝
]]

-- ============================================
--  UI SEDERHANA (PASTI WORK DI DELTA)
-- ============================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()
local Win = Library:Window("🔍 XKID MINI", "cpu", "Khusus Delta", false)

-- ============================================
--  TABS
-- ============================================
local TabScan   = Win:Tab("📡 SCAN", "search")
local TabMove   = Win:Tab("🚶 MOVE", "activity")
local TabObj    = Win:Tab("📦 OBJEK", "package")

-- ============================================
--  SERVICES
-- ============================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- ============================================
--  STATE
-- ============================================
local allRemotes = {}
local moveLog = {}
local objLog = {}
local trackMove = false
local trackObj = false
local moveConn = nil
local objAddedConn = nil
local objRemovedConn = nil

-- ============================================
--  SCAN FUNCTIONS
-- ============================================
local function scanAll()
    local results = {}
    local places = {
        game:GetService("ReplicatedStorage"),
        Workspace,
        LP:FindFirstChild("PlayerGui"),
        LP:FindFirstChild("Backpack")
    }
    
    for _, place in ipairs(places) do
        if place then
            for _, obj in ipairs(place:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    table.insert(results, {
                        name = obj.Name,
                        path = obj:GetFullName(),
                        type = obj.ClassName
                    })
                end
            end
        end
    end
    return results
end

-- ============================================
--  MOVEMENT TRACKER (PASTI WORK)
-- ============================================
local function startMoveTrack()
    if trackMove then return end
    moveLog = {}
    local lastPos = nil
    
    moveConn = RunService.Heartbeat:Connect(function()
        if not trackMove then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local pos = hrp.Position
        if lastPos and (pos - lastPos).Magnitude > 2 then
            local entry = string.format(
                "[%s] 🚶 Pindah ke (%.1f, %.1f, %.1f)",
                os.date("%H:%M:%S"),
                pos.X, pos.Y, pos.Z
            )
            table.insert(moveLog, 1, entry)
            if #moveLog > 50 then table.remove(moveLog, #moveLog) end
        end
        lastPos = pos
    end)
    
    trackMove = true
    Library:Notification("✅", "Movement tracking ON", 2)
end

local function stopMoveTrack()
    if moveConn then moveConn:Disconnect() end
    trackMove = false
    Library:Notification("✅", "Movement tracking OFF", 2)
end

-- ============================================
--  OBJECT TRACKER (PASTI WORK)
-- ============================================
local function startObjTrack()
    if trackObj then return end
    objLog = {}
    
    objAddedConn = Workspace.DescendantAdded:Connect(function(obj)
        if not trackObj then return end
        if obj:IsA("BasePart") and #obj.Name > 1 then
            local entry = string.format(
                "[%s] ➕ %s muncul di (%.1f, %.1f)",
                os.date("%H:%M:%S"),
                obj.Name,
                obj.Position.X,
                obj.Position.Z
            )
            table.insert(objLog, 1, entry)
            if #objLog > 50 then table.remove(objLog, #objLog) end
        end
    end)
    
    objRemovedConn = Workspace.DescendantRemoving:Connect(function(obj)
        if not trackObj then return end
        if obj:IsA("BasePart") and #obj.Name > 1 then
            local entry = string.format(
                "[%s] ➖ %s hilang",
                os.date("%H:%M:%S"),
                obj.Name
            )
            table.insert(objLog, 1, entry)
            if #objLog > 50 then table.remove(objLog, #objLog) end
        end
    end)
    
    trackObj = true
    Library:Notification("✅", "Object tracking ON", 2)
end

local function stopObjTrack()
    if objAddedConn then objAddedConn:Disconnect() end
    if objRemovedConn then objRemovedConn:Disconnect() end
    trackObj = false
    Library:Notification("✅", "Object tracking OFF", 2)
end

-- ============================================
--  BUILD UI - SCAN TAB
-- ============================================
local ScanPage = TabScan:Page("SCAN", "search")
local ScanLeft = ScanPage:Section("🔍 CONTROL", "Left")
local ScanRight = ScanPage:Section("📋 RESULTS", "Right")

ScanLeft:Button("🔍 SCAN REMOTE", "Scan semua remote", function()
    task.spawn(function()
        Library:Notification("⏳", "Scanning...", 1)
        allRemotes = scanAll()
        Library:Notification("✅", "Ditemukan " .. #allRemotes .. " remote", 3)
    end)
end)

ScanLeft:Button("🗑️ CLEAR", "Hapus hasil", function()
    allRemotes = {}
    Library:Notification("✅", "Cleared", 1)
end)

ScanRight:Button("📋 LIST REMOTE", "Tampilkan remote", function()
    if #allRemotes == 0 then
        Library:Notification("❌", "Scan dulu!", 2)
        return
    end
    local text = "📡 REMOTE:\n\n"
    for i, r in ipairs(allRemotes) do
        text = text .. i .. ". " .. r.name .. "\n"
        if i >= 15 then 
            text = text .. "...dan " .. (#allRemotes-15) .. " lainnya"
            break 
        end
    end
    Library:Notification("📋 HASIL", text, 8)
end)

-- ============================================
--  BUILD UI - MOVE TAB
-- ============================================
local MovePage = TabMove:Page("MOVEMENT", "activity")
local MoveLeft = MovePage:Section("🎮 CONTROL", "Left")
local MoveRight = MovePage:Section("📋 LOG", "Right")

MoveLeft:Toggle("🚶 TRACK MOVE", "MoveToggle", false, "Track pergerakan", function(v)
    if v then startMoveTrack() else stopMoveTrack() end
end)

MoveLeft:Button("🗑️ CLEAR LOG", "Hapus log", function()
    moveLog = {}
    Library:Notification("✅", "Log cleared", 1)
end)

MoveRight:Button("📋 LIHAT LOG", "Tampilkan log", function()
    if #moveLog == 0 then
        Library:Notification("❌", "Belum ada log", 2)
        return
    end
    local text = "🚶 MOVEMENT LOG:\n\n"
    for i = 1, math.min(10, #moveLog) do
        text = text .. moveLog[i] .. "\n\n"
    end
    Library:Notification("📋 LOG", text, 10)
end)

-- ============================================
--  BUILD UI - OBJEK TAB
-- ============================================
local ObjPage = TabObj:Page("OBJEK", "package")
local ObjLeft = ObjPage:Section("🎮 CONTROL", "Left")
local ObjRight = ObjPage:Section("📋 LOG", "Right")

ObjLeft:Toggle("📦 TRACK OBJEK", "ObjToggle", false, "Track objek baru/hilang", function(v)
    if v then startObjTrack() else stopObjTrack() end
end)

ObjLeft:Button("🗑️ CLEAR LOG", "Hapus log", function()
    objLog = {}
    Library:Notification("✅", "Log cleared", 1)
end)

ObjRight:Button("📋 LIHAT LOG", "Tampilkan log", function()
    if #objLog == 0 then
        Library:Notification("❌", "Belum ada log", 2)
        return
    end
    local text = "📦 OBJEK LOG:\n\n"
    for i = 1, math.min(10, #objLog) do
        text = text .. objLog[i] .. "\n\n"
    end
    Library:Notification("📋 LOG", text, 10)
end)

-- ============================================
--  STARTUP
-- ============================================
Library:Notification("✅ XKID MINI", "Siap! Pilih tab:", 3)

print("╔══════════════════════════════════════╗")
print("║   🔌 XKID MINI - KHUSUS DELTA       ║")
print("║                                      ║")
print("║   FITUR:                             ║")
print("║   ✓ SCAN remote                       ║")
print("║   ✓ TRACK pergerakan                   ║")
print("║   ✓ TRACK objek baru/hilang             ║")
print("║                                      ║")
print("║   CARA PAKAI:                         ║")
print("║   1. SCAN remote (tab SCAN)            ║")
print("║   2. AKTIFKAN TRACK MOVE & OBJEK       ║")
print("║   3. JALANKAN auto farm orang          ║")
print("║   4. LIHAT log di tab MOVE & OBJEK     ║")
print("║                                      ║")
print("╚══════════════════════════════════════╝")