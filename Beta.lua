-- SCRIPT SAWAH INDO FIXED - SIRIUS.MENU
-- Versi: 2.0 FIXED ALL FEATURES

local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not ok or not Rayfield then
    warn("❌ Gagal load Rayfield. Coba lagi.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO HUB v2.0",
    LoadingTitle = "SAWAH INDO",
    LoadingSubtitle = "Script Fixed - All Features Active",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- ========== SERVICES ==========
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local LocalPlayer   = Players.LocalPlayer

-- ========== GLOBAL FLAGS ==========
_G.AutoNPC      = false
_G.AutoCollect  = false
_G.AutoJual     = false
_G.AutoFarm     = false

-- ========== UTILITY ==========
local function notify(title, content, duration)
    pcall(function()
        Rayfield:Notify({
            Title   = title,
            Content = content,
            Duration = duration or 3,
            Image   = 4483362458
        })
    end)
    print("[SAWAH INDO] " .. title .. ": " .. content)
end

local function getChar()
    return LocalPlayer.Character
end

local function getRootPart()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Cari object di workspace dengan berbagai nama
local function findObject(name)
    if not name then return nil end
    -- Cari exact match dulu
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == name then
            return v
        end
    end
    -- Cari case-insensitive
    local lower = name:lower()
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower() == lower then
            return v
        end
    end
    return nil
end

-- Cari posisi dari object (Model atau BasePart)
local function getPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        -- Prioritas: PrimaryPart > HumanoidRootPart > Head > GetPivot
        if obj.PrimaryPart then
            return obj.PrimaryPart.Position
        elseif obj:FindFirstChild("HumanoidRootPart") then
            return obj.HumanoidRootPart.Position
        elseif obj:FindFirstChild("Head") then
            return obj.Head.Position
        else
            local ok2, pivot = pcall(function() return obj:GetPivot().Position end)
            if ok2 then return pivot end
        end
    end
    return nil
end

-- Teleport utama
local function teleportTo(name, obj)
    local root = getRootPart()
    if not root then
        notify("❌ Error", "Character belum spawn!", 3)
        return false
    end

    -- Jika obj tidak diberikan, cari by name
    if not obj and name then
        obj = findObject(name)
    end

    if not obj then
        notify("❌ Tidak Ditemukan", (name or "Object") .. " tidak ada di map!", 3)
        return false
    end

    local pos = getPos(obj)
    if not pos then
        notify("❌ Error", "Gagal ambil posisi " .. (name or "object"), 3)
        return false
    end

    -- Teleport dengan offset Y agar tidak nyangkut di tanah
    root.CFrame = CFrame.new(pos.X, pos.Y + 4, pos.Z)
    notify("✅ Teleport", "Berhasil ke " .. (name or obj.Name), 2)
    return true
end

-- ========== TABS ==========
local TeleportTab = Window:CreateTab("📍 TELEPORT", nil)
local NPCTab      = Window:CreateTab("👥 NPC", nil)
local LahanTab    = Window:CreateTab("🌱 LAHAN", nil)
local AutoTab     = Window:CreateTab("⚙ AUTO FARM", nil)
local InfoTab     = Window:CreateTab("ℹ INFO", nil)

-- ========== TELEPORT TAB ==========
TeleportTab:CreateSection("Toko & Pedagang")

local npcList = {
    { icon = "🛒", name = "npcbibit",          label = "npcbibit — Beli Bibit"        },
    { icon = "💰", name = "npcpenjual",         label = "npcpenjual — Jual Hasil"      },
    { icon = "🔧", name = "npcalat",            label = "npcalat — Beli Alat"          },
    { icon = "🥚", name = "NPCPedagangTelur",   label = "NPCPedagangTelur — Jual Telur"},
    { icon = "🌴", name = "NPCPedagangSawit",   label = "NPCPedagangSawit — Jual Sawit"},
}

for _, npc in ipairs(npcList) do
    TeleportTab:CreateButton({
        Name     = npc.icon .. " " .. npc.label,
        Callback = function()
            teleportTo(npc.name)
        end
    })
end

TeleportTab:CreateSection("Lokasi Khusus")

TeleportTab:CreateButton({
    Name     = "🏠 Spawn / Awal",
    Callback = function()
        local spawns = {"SpawnLocation", "Spawn", "SpawnPoint"}
        local found = false
        for _, sname in ipairs(spawns) do
            if teleportTo(sname) then
                found = true
                break
            end
        end
        if not found then
            notify("❌", "Spawn tidak ditemukan", 3)
        end
    end
})

-- ========== NPC TAB ==========
NPCTab:CreateSection("Scan & Teleport NPC")

NPCTab:CreateButton({
    Name     = "🔍 SCAN SEMUA NPC DI MAP",
    Callback = function()
        local targets = {
            "npcbibit","npcpenjual","npcalat",
            "NPCPedagangTelur","NPCPedagangSawit",
            "NPC","Pedagang","Penjual","Petani"
        }
        local result = {}
        for _, tname in ipairs(targets) do
            local obj = findObject(tname)
            table.insert(result, tname .. ": " .. (obj and "✅ ADA" or "❌ TIDAK ADA"))
        end
        -- Juga cari NPC yang tidak terdaftar
        local extra = {}
        for _, v in pairs(workspace:GetDescendants()) do
            if (v:IsA("Model") or v:IsA("NPC")) and v:FindFirstChildOfClass("Humanoid") then
                local isKnown = false
                for _, tname in ipairs(targets) do
                    if v.Name == tname then isKnown = true; break end
                end
                if not isKnown and not extra[v.Name] then
                    extra[v.Name] = true
                    table.insert(result, "🆕 NPC Baru: " .. v.Name)
                end
            end
        end
        for _, line in ipairs(result) do
            print(line)
        end
        notify("🔍 Scan Selesai", "Lihat output di console (F9)", 4)
    end
})

for _, npc in ipairs(npcList) do
    NPCTab:CreateButton({
        Name     = npc.icon .. " " .. npc.name,
        Callback = function()
            teleportTo(npc.name)
        end
    })
end

-- ========== LAHAN TAB ==========
LahanTab:CreateSection("Lahan Pertanian")

LahanTab:CreateButton({
    Name     = "🌾 Scan Semua Lahan (Tanah)",
    Callback = function()
        local count = 0
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Tanah" and obj:IsA("BasePart") then
                count = count + 1
            end
        end
        notify("🌾 Scan Lahan", "Ditemukan " .. count .. " lahan Tanah", 4)
        print("Total lahan Tanah: " .. count)
    end
})

LahanTab:CreateButton({
    Name     = "📍 Teleport ke Lahan Pertama",
    Callback = function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Tanah" and obj:IsA("BasePart") then
                teleportTo(nil, obj)
                return
            end
        end
        notify("❌", "Lahan Tanah tidak ditemukan", 3)
    end
})

LahanTab:CreateButton({
    Name     = "🌴 Teleport ke Pohon Sawit",
    Callback = function()
        local keywords = {"Palm_tree","PalmTree","Sawit","palm"}
        for _, keyword in ipairs(keywords) do
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:lower():find(keyword:lower()) and obj:IsA("BasePart") then
                    teleportTo(nil, obj)
                    return
                end
            end
        end
        notify("❌", "Pohon Sawit tidak ditemukan", 3)
    end
})

LahanTab:CreateButton({
    Name     = "📋 Daftar Semua Tanaman",
    Callback = function()
        local found = {}
        local keywords = {"Tanah","Padi","Sawit","Jagung","Palm","Crop","Plant","Farm"}
        for _, obj in pairs(workspace:GetDescendants()) do
            for _, kw in ipairs(keywords) do
                if obj.Name:lower():find(kw:lower()) then
                    if not found[obj.Name] then
                        found[obj.Name] = 0
                    end
                    found[obj.Name] = found[obj.Name] + 1
                    break
                end
            end
        end
        print("=== DAFTAR OBJEK PERTANIAN ===")
        for name, count in pairs(found) do
            print(name .. ": " .. count .. " buah")
        end
        notify("📋 Selesai", "Cek console (F9) untuk detail", 4)
    end
})

-- ========== AUTO FARM TAB ==========
AutoTab:CreateSection("Auto Rotasi NPC")

AutoTab:CreateToggle({
    Name         = "🔄 Auto Teleport NPC (Semua)",
    CurrentValue = false,
    Callback     = function(v)
        _G.AutoNPC = v
        if v then
            notify("✅ Auto NPC", "Aktif! Rotasi tiap 4 detik", 3)
            task.spawn(function()
                local idx = 1
                while _G.AutoNPC do
                    teleportTo(npcList[idx].name)
                    idx = idx % #npcList + 1
                    task.wait(4)
                end
            end)
        else
            notify("⛔ Auto NPC", "Dimatikan", 2)
        end
    end
})

AutoTab:CreateToggle({
    Name         = "💰 Auto Jual (Loop ke npcpenjual)",
    CurrentValue = false,
    Callback     = function(v)
        _G.AutoJual = v
        if v then
            notify("✅ Auto Jual", "Aktif! Teleport ke penjual tiap 5 detik", 3)
            task.spawn(function()
                while _G.AutoJual do
                    teleportTo("npcpenjual")
                    task.wait(5)
                end
            end)
        else
            notify("⛔ Auto Jual", "Dimatikan", 2)
        end
    end
})

AutoTab:CreateToggle({
    Name         = "🌾 Auto Farm (Beli Bibit → Lahan → Jual)",
    CurrentValue = false,
    Callback     = function(v)
        _G.AutoFarm = v
        if v then
            notify("✅ Auto Farm", "Aktif! Siklus: Bibit → Lahan → Jual", 3)
            task.spawn(function()
                while _G.AutoFarm do
                    -- Step 1: ke bibit
                    teleportTo("npcbibit")
                    task.wait(3)
                    -- Step 2: ke lahan pertama
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj.Name == "Tanah" and obj:IsA("BasePart") then
                            teleportTo(nil, obj)
                            break
                        end
                    end
                    task.wait(5)
                    -- Step 3: jual
                    teleportTo("npcpenjual")
                    task.wait(3)
                end
            end)
        else
            notify("⛔ Auto Farm", "Dimatikan", 2)
        end
    end
})

AutoTab:CreateSection("Utilitas")

AutoTab:CreateButton({
    Name     = "📍 Koordinat Saya Sekarang",
    Callback = function()
        local root = getRootPart()
        if root then
            local p = root.Position
            local msg = string.format("X=%.1f | Y=%.1f | Z=%.1f", p.X, p.Y, p.Z)
            notify("📍 Posisi", msg, 5)
            print("📍 " .. msg)
        else
            notify("❌", "Character tidak ditemukan", 3)
        end
    end
})

AutoTab:CreateButton({
    Name     = "🔄 Reset Character",
    Callback = function()
        local char = getChar()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = 0
                notify("🔄 Reset", "Character di-reset!", 2)
            end
        end
    end
})

AutoTab:CreateButton({
    Name     = "⛔ STOP SEMUA AUTO",
    Callback = function()
        _G.AutoNPC     = false
        _G.AutoCollect = false
        _G.AutoJual    = false
        _G.AutoFarm    = false
        notify("⛔ STOP", "Semua auto feature dimatikan!", 3)
    end
})

-- ========== INFO TAB ==========
InfoTab:CreateSection("Info Script")

InfoTab:CreateLabel("Script: SAWAH INDO HUB v2.0")
InfoTab:CreateLabel("GUI: Rayfield via sirius.menu")
InfoTab:CreateLabel("Status: Fixed & All Active ✅")

InfoTab:CreateSection("NPC Terdaftar")
for _, npc in ipairs(npcList) do
    InfoTab:CreateLabel(npc.icon .. " " .. npc.name)
end

InfoTab:CreateSection("Tips")
InfoTab:CreateLabel("Gunakan SCAN di tab NPC untuk cek NPC aktif")
InfoTab:CreateLabel("F9 = Console untuk melihat log detail")
InfoTab:CreateLabel("STOP SEMUA AUTO jika lag")

-- ========== INIT ==========
print("╔══════════════════════════════╗")
print("║  🌾 SAWAH INDO HUB v2.0      ║")
print("║  Status: ✅ AKTIF SEMUA      ║")
print("╚══════════════════════════════╝")
print("NPC Terdaftar:")
for _, npc in ipairs(npcList) do
    print("  " .. npc.icon .. " " .. npc.name)
end

notify("🌾 SAWAH INDO", "Script v2.0 berhasil dimuat! Semua fitur aktif.", 5)
