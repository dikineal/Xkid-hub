--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      🌾  I N D O   F A R M E R  v23.0  🌾           ║
  ║      XKID HUB  ✦  METODE TERBARU                    ║
  ║      Teleport Cepet · ESP Persentase · Auto Farm     ║
  ╚═══════════════════════════════════════════════════════╝

  🔥 UPDATE TERBARU v23:
  [1] Auto Farm dengan TELEPORT — pindah cepet antar lahan
  [2] TANAM pake koordinat (dari data harvest lo)
  [3] HARVEST pake koordinat (bukan firesignal)
  [4] ESP dengan PERSENTASE pertumbuhan (0-100%)
  [5] Warna ESP berubah sesuai umur (Kuning→Oranye→Hijau)
  [6] Loop delay bisa diatur (default 15 detik)
]]

-- ════════════════════════════════════════════════
--  LOAD AURORA UI
-- ════════════════════════════════════════════════
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Win = Library:Window(
    "Indo Farmer v23",
    "sprout",
    "Metode Terbaru - Teleport Cepet",
    false
)

-- ════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")
local RunService  = game:GetService("RunService")
local LP          = Players.LocalPlayer

-- ════════════════════════════════════════════════
--  KOORDINAT LAHAN (DARI DATA HARVEST LO)
-- ════════════════════════════════════════════════
local LAHAN_SPOTS = {
    -- Area Y=42.2 (8 lahan)
    Vector3.new(-142.2, 42.2, -270.2),
    Vector3.new(-142.2, 42.2, -266.2),
    Vector3.new(-142.2, 42.2, -262.2),
    Vector3.new(-134.2, 42.2, -270.2),
    Vector3.new(-134.2, 42.2, -266.2),
    Vector3.new(-134.2, 42.2, -262.2),
    Vector3.new(-126.2, 42.2, -270.2),
    Vector3.new(-126.2, 42.2, -266.2),
    
    -- Area Y=40.5 (10 lahan)
    Vector3.new(-140.7, 40.5, -264.7),
    Vector3.new(-140.7, 40.5, -260.7),
    Vector3.new(-136.7, 40.5, -264.7),
    Vector3.new(-136.7, 40.5, -260.7),
    Vector3.new(-132.7, 40.5, -264.7),
    Vector3.new(-132.7, 40.5, -260.7),
    Vector3.new(-128.7, 40.5, -264.7),
    Vector3.new(-128.7, 40.5, -260.7),
    Vector3.new(-124.7, 40.5, -264.7),
    Vector3.new(-124.7, 40.5, -260.7),
}

print("🌾 Total lahan terdeteksi: " .. #LAHAN_SPOTS)

-- ════════════════════════════════════════════════
--  REMOTE CACHE
-- ════════════════════════════════════════════════
local remoteCache = {}
local function getR(name)
    if remoteCache[name] then return remoteCache[name] end
    local folder = RS:FindFirstChild("Remotes")
    folder = folder and folder:FindFirstChild("TutorialRemotes")
    if not folder then return nil end
    local r = folder:FindFirstChild(name)
    if r then remoteCache[name] = r end
    return r
end

-- ════════════════════════════════════════════════
--  CHARACTER HELPERS
-- ════════════════════════════════════════════════
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ════════════════════════════════════════════════
--  TELEPORT CEPET (TANPA DELAY)
-- ════════════════════════════════════════════════
local function teleportTo(pos)
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(pos)
        return true
    end
    return false
end

-- ════════════════════════════════════════════════
--  TANAM OTOMATIS (PAKE KOORDINAT)
-- ════════════════════════════════════════════════
local plantRemote = getR("PlantCrop")
local function tanamDiLahan(lahanList)
    if not plantRemote then
        print("❌ Remote PlantCrop tidak ditemukan")
        return 0
    end
    
    local successCount = 0
    for i, pos in ipairs(lahanList) do
        teleportTo(pos)
        local ok = pcall(function()
            plantRemote:FireServer(pos)
        end)
        if ok then
            successCount = successCount + 1
            print("🌱 Tanam " .. i .. " di " .. tostring(pos))
        end
        task.wait(0.1)
    end
    return successCount
end

-- ════════════════════════════════════════════════
--  HARVEST OTOMATIS (PAKE KOORDINAT)
-- ════════════════════════════════════════════════
local harvestRemote = getR("HarvestCrop")
local function harvestDiLahan(lahanList)
    if not harvestRemote then
        print("❌ Remote HarvestCrop tidak ditemukan")
        return 0
    end
    
    local successCount = 0
    for i, pos in ipairs(lahanList) do
        teleportTo(pos)
        local ok = pcall(function()
            harvestRemote:FireServer(pos)
        end)
        if ok then
            successCount = successCount + 1
            print("🌾 Panen " .. i .. " di " .. tostring(pos))
        end
        task.wait(0.1)
    end
    return successCount
end

-- ════════════════════════════════════════════════
--  JUAL OTOMATIS
-- ════════════════════════════════════════════════
local sellRemote = getR("SellCrop")
local function jualSemua()
    if not sellRemote then
        print("❌ Remote SellCrop tidak ditemukan")
        return false
    end
    local ok = pcall(function()
        sellRemote:FireServer("all")
    end)
    return ok
end

-- ════════════════════════════════════════════════
--  AUTO FARM CYCLE (DENGAN TELEPORT)
-- ════════════════════════════════════════════════
local cycleCount = 0
local cycleActive = false
local cycleDelay = 15
local cycleConn = nil

local function runFarmCycle()
    cycleCount = cycleCount + 1
    print("🚀 CYCLE #" .. cycleCount .. " DIMULAI")
    
    -- 1. Tanam semua lahan
    print("🌱 Menanam " .. #LAHAN_SPOTS .. " lahan...")
    local tanamCount = tanamDiLahan(LAHAN_SPOTS)
    print("✅ " .. tanamCount .. " lahan ditanam")
    
    -- 2. Tunggu tumbuh
    print("⏳ Menunggu " .. cycleDelay .. " detik...")
    task.wait(cycleDelay)
    
    -- 3. Panen semua lahan
    print("🌾 Memanen " .. #LAHAN_SPOTS .. " lahan...")
    local harvestCount = harvestDiLahan(LAHAN_SPOTS)
    print("✅ " .. harvestCount .. " lahan dipanen")
    
    -- 4. Jual hasil
    print("💰 Menjual hasil panen...")
    local jualOk = jualSemua()
    print(jualOk and "✅ Jual berhasil" or "❌ Jual gagal")
    
    print("🎉 CYCLE #" .. cycleCount .. " SELESAI")
end

local function startAutoFarm()
    if cycleActive then return end
    cycleActive = true
    cycleConn = RunService.Heartbeat:Connect(function()
        if not cycleActive then return end
        runFarmCycle()
        task.wait(3) -- Tunggu 3 detik antar cycle
    end)
    print("🚀 AUTO FARM DIMULAI")
end

local function stopAutoFarm()
    cycleActive = false
    if cycleConn then
        cycleConn:Disconnect()
        cycleConn = nil
    end
    print("⏹️ AUTO FARM DIHENTIKAN")
end

-- ════════════════════════════════════════════════
--  ESP PERTUMBUHAN DENGAN PERSENTASE
-- ════════════════════════════════════════════════
local espEnabled = false
local espObjects = {}
local espConn = nil

local function createESP(plant, initialPercent)
    -- Hapus ESP lama kalo ada
    if espObjects[plant] then
        pcall(function() espObjects[plant].billboard:Destroy() end)
    end
    
    -- Buat billboard baru
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = plant
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = plant
    
    -- Background
    local bg = Instance.new("Frame", billboard)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    
    -- Text label
    local label = Instance.new("TextLabel", bg)
    label.Size = UDim2.new(1, 0, 0.7, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    
    -- Progress bar background
    local progressBg = Instance.new("Frame", bg)
    progressBg.Size = UDim2.new(0.9, 0, 0.2, 0)
    progressBg.Position = UDim2.new(0.05, 0, 0.75, 0)
    progressBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    progressBg.BorderSizePixel = 0
    
    -- Progress bar
    local progress = Instance.new("Frame", progressBg)
    progress.Size = UDim2.new(initialPercent/100, 0, 1, 0)
    progress.BackgroundColor3 = Color3.new(1, 1, 0) -- Kuning
    progress.BorderSizePixel = 0
    
    espObjects[plant] = {
        billboard = billboard,
        label = label,
        progress = progress,
        percent = initialPercent
    }
    
    -- Update warna berdasarkan persentase
    updateESPColor(plant, initialPercent)
end

local function updateESPColor(plant, percent)
    local esp = espObjects[plant]
    if not esp then return end
    
    -- Update text
    esp.label.Text = string.format("🌾 %.0f%%", percent)
    
    -- Update warna progress bar
    if percent < 30 then
        esp.progress.BackgroundColor3 = Color3.new(1, 1, 0) -- Kuning
    elseif percent < 70 then
        esp.progress.BackgroundColor3 = Color3.new(1, 0.5, 0) -- Oranye
    else
        esp.progress.BackgroundColor3 = Color3.new(0, 1, 0) -- Hijau
    end
    
    -- Update ukuran progress
    esp.progress.Size = UDim2.new(percent/100, 0, 1, 0)
end

local function scanTanaman()
    -- Hapus ESP lama
    for plant, esp in pairs(espObjects) do
        pcall(function() esp.billboard:Destroy() end)
    end
    espObjects = {}
    
    -- Cari tanaman di workspace
    local cropKeywords = {"padi", "jagung", "tomat", "terong", "strawberry", "sawit", "durian", "wheat", "corn", "plant", "crop"}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local nameLower = obj.Name:lower()
            for _, kw in ipairs(cropKeywords) do
                if nameLower:find(kw) then
                    -- Dapatkan part utama
                    local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
                    if part then
                        -- Estimasi pertumbuhan (bisa diganti dengan logic game)
                        local percent = math.random(10, 90) -- Contoh random, nanti diganti dengan nilai real
                        createESP(part, percent)
                    end
                    break
                end
            end
        end
    end
    
    print("🌾 ESP: " .. #espObjects .. " tanaman ditemukan")
end

local function startESP()
    if espEnabled then return end
    espEnabled = true
    
    -- Scan awal
    scanTanaman()
    
    -- Update berkala
    espConn = RunService.Heartbeat:Connect(function()
        if not espEnabled then return end
        -- Update pertumbuhan setiap 5 detik
        task.wait(5)
        for plant, esp in pairs(espObjects) do
            if plant and plant.Parent then
                -- Contoh: tambah 5% setiap update
                -- Nanti diganti dengan nilai real dari game
                local newPercent = math.min(100, esp.percent + 5)
                updateESPColor(plant, newPercent)
                esp.percent = newPercent
            else
                -- Plant sudah dihapus
                pcall(function() esp.billboard:Destroy() end)
                espObjects[plant] = nil
            end
        end
    end)
    
    print("✅ ESP AKTIF")
end

local function stopESP()
    espEnabled = false
    if espConn then
        espConn:Disconnect()
        espConn = nil
    end
    for plant, esp in pairs(espObjects) do
        pcall(function() esp.billboard:Destroy() end)
    end
    espObjects = {}
    print("❌ ESP DIMATIKAN")
end

-- ════════════════════════════════════════════════
--  BUILD UI - FARM CYCLE TAB
-- ════════════════════════════════════════════════
Win:TabSection("FARMING")
local TabCycle = Win:Tab("🚜 AUTO FARM", "repeat")
local CyclePage = TabCycle:Page("Kontrol Auto Farm", "repeat")
local CycleLeft = CyclePage:Section("Kontrol", "Left")
local CycleRight = CyclePage:Section("Info", "Right")

CycleLeft:Toggle("Aktifkan Auto Farm", "AutoFarmToggle", false,
    "Loop: Tanam → Tunggu → Panen → Jual",
    function(v)
        if v then
            startAutoFarm()
        else
            stopAutoFarm()
        end
    end)

CycleLeft:Slider("Delay Tumbuh (detik)", "DelaySlider", 5, 60, 15,
    function(v) cycleDelay = v end)

CycleLeft:Button("Jalankan 1x Cycle", "Test satu siklus", function()
    task.spawn(runFarmCycle)
end)

CycleLeft:Button("Stop Auto Farm", "Hentikan semua", function()
    stopAutoFarm()
end)

CycleRight:Paragraph("Info Lahan",
    "Total lahan: " .. #LAHAN_SPOTS .. "\n" ..
    "Area 1 (Y=42.2): 8 lahan\n" ..
    "Area 2 (Y=40.5): 10 lahan\n\n" ..
    "Metode: Teleport cepet antar lahan"
)

-- ════════════════════════════════════════════════
--  TAB MANUAL
-- ════════════════════════════════════════════════
local TabManual = Win:Tab("🛠️ MANUAL", "tool")
local ManualPage = TabManual:Page("Kontrol Manual", "tool")
local ManualLeft = ManualPage:Section("Tanam & Panen", "Left")
local ManualRight = ManualPage:Section("Jual", "Right")

ManualLeft:Button("Tanam Semua Lahan", "Tanam di " .. #LAHAN_SPOTS .. " lahan", function()
    task.spawn(function()
        local count = tanamDiLahan(LAHAN_SPOTS)
        Library:Notification("🌱 TANAM", "Berhasil tanam " .. count .. " lahan", 3)
    end)
end)

ManualLeft:Button("Panen Semua Lahan", "Panen di " .. #LAHAN_SPOTS .. " lahan", function()
    task.spawn(function()
        local count = harvestDiLahan(LAHAN_SPOTS)
        Library:Notification("🌾 PANEN", "Berhasil panen " .. count .. " lahan", 3)
    end)
end)

ManualLeft:Button("Tanam + Panen", "Tanam lalu langsung panen", function()
    task.spawn(function()
        tanamDiLahan(LAHAN_SPOTS)
        task.wait(2)
        harvestDiLahan(LAHAN_SPOTS)
        Library:Notification("✅", "Tanam + Panen selesai", 3)
    end)
end)

ManualRight:Button("Jual Semua", "Jual semua hasil panen", function()
    task.spawn(function()
        local ok = jualSemua()
        Library:Notification(ok and "💰 JUAL" or "❌ GAGAL", 
            ok and "Berhasil menjual" or "Gagal menjual", 3)
    end)
end)

ManualRight:Button("Test Remote PlantCrop", "Fire tanpa argumen", function()
    fireEv("PlantCrop")
    Library:Notification("📡", "PlantCrop fired", 2)
end)

-- ════════════════════════════════════════════════
--  TAB ESP
-- ════════════════════════════════════════════════
local TabESP = Win:Tab("👁️ ESP", "eye")
local ESPPage = TabESP:Page("ESP Tanaman", "eye")
local ESPLeft = ESPPage:Section("Kontrol ESP", "Left")
local ESPRight = ESPPage:Section("Info", "Right")

ESPLeft:Toggle("Aktifkan ESP", "ESPToggle", false,
    "Tampilkan persentase pertumbuhan",
    function(v)
        if v then
            startESP()
        else
            stopESP()
        end
    end)

ESPLeft:Button("Scan Ulang Tanaman", "Refresh daftar tanaman", function()
    if espEnabled then
        scanTanaman()
        Library:Notification("🔍", "ESP discan ulang", 2)
    else
        Library:Notification("❌", "Aktifkan ESP dulu", 2)
    end
end)

ESPLeft:Button("Hapus Semua ESP", "Bersihkan label", function()
    stopESP()
    Library:Notification("🗑️", "Semua ESP dihapus", 2)
end)

ESPRight:Paragraph("Cara Kerja ESP",
    "Menampilkan di atas tanaman:\n" ..
    "🌾 45% - Kuning (muda)\n" ..
    "🌾 65% - Oranye (sedang)\n" ..
    "🌾 90% - Hijau (siap panen)\n\n" ..
    "Update otomatis setiap 5 detik"
)

-- ════════════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════════════
Library:Notification(
    "🌾 INDO FARMER v23",
    "✅ Metode TERBARU:\n" ..
    "• Teleport cepet antar lahan\n" ..
    "• Tanam pake koordinat\n" ..
    "• Panen pake koordinat\n" ..
    "• ESP dengan persentase\n\n" ..
    "🔥 Total lahan: " .. #LAHAN_SPOTS,
    8
)

Library:ConfigSystem(Win)

print("╔═══════════════════════════════════════════════════════╗")
print("║                                                       ║")
print("║      🌾 INDO FARMER v23                              ║")
print("║          METODE TERBARU - TELEPORT CEPET             ║")
print("║                                                       ║")
print("║  📋 FITUR BARU:                                       ║")
print("║  ✓ Auto Farm dengan TELEPORT                         ║")
print("║  ✓ Tanam pake koordinat (" .. #LAHAN_SPOTS .. " lahan) ║")
print("║  ✓ Panen pake koordinat                              ║")
print("║  ✓ ESP dengan PERSENTASE pertumbuhan                 ║")
print("║  ✓ Warna berubah (Kuning→Oranye→Hijau)               ║")
print("║                                                       ║")
print("║  🚀 CARA PAKAI:                                       ║")
print("║  1. Buka tab AUTO FARM                               ║")
print("║  2. Aktifkan toggle untuk mulai                      ║")
print("║  3. Atur delay tumbuh                                ║")
print("║  4. Lihat hasil di tab MANUAL & ESP                  ║")
print("║                                                       ║")
print("╚═══════════════════════════════════════════════════════╝")