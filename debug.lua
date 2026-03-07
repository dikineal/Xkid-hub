local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⚡ XKID SUPER EPIC HUB ⚡",
    LoadingTitle = "LOADING SUPER EPIC...",
    LoadingSubtitle = "by XKID | Version 9000",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKidSuperEpic",
        FileName = "Config"
    },
    KeySystem = false
})--[[
    DEBUG MASTER - DETEKSI SELURUH MAP
    Tambahkan ini di hub lo
]]

-- ========== DEBUG TAB ==========
local DebugTab = Window:CreateTab("🐞 DEBUG MASTER", nil)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Variabel debug
_G.Debug = {
    scanning = false,
    tracking = false,
    trackedObject = nil,
    scanResults = {},
    objectCount = 0
}

-- Fungsi untuk mendapatkan posisi object
local function getObjectPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        if obj:FindFirstChild("HumanoidRootPart") then
            return obj.HumanoidRootPart.Position
        elseif obj:FindFirstChild("Head") then
            return obj.Head.Position
        elseif obj:FindFirstChild("Torso") then
            return obj.Torso.Position
        else
            -- Coba cari part pertama
            for _, child in pairs(obj:GetChildren()) do
                if child:IsA("BasePart") then
                    return child.Position
                end
            end
        end
    end
    return nil
end

-- ========== SCAN FULL MAP ==========
DebugTab:CreateButton({
    Name = "🔍 SCAN FULL MAP (1000 stud)",
    Callback = function()
        _G.Debug.scanning = true
        _G.Debug.scanResults = {}
        
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            print("❌ Character tidak ditemukan")
            _G.Debug.scanning = false
            return
        end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        print("\n" .. string.rep("=", 60))
        print("🔍 SCAN FULL MAP DIMULAI")
        print("📍 Posisi saya: " .. string.format("(%.1f, %.1f, %.1f)", myPos.X, myPos.Y, myPos.Z))
        print(string.rep("=", 60))
        
        local categories = {
            ["🌾 FARMING"] = {"tanah", "lahan", "bibit", "seed", "crop", "plant", "farm", "sawah", "padi", "tomat", "jagung", "terong", "strawberry", "durian", "sawit"},
            ["👥 NPC"] = {"npc", "pedagang", "penjual", "petani", "merchant", "farmer", "guard", "king", "quest"},
            ["🏪 TOKO"] = {"toko", "shop", "buy", "sell", "jual", "beli", "market"},
            ["🥚 COLLECT"] = {"egg", "telur", "coin", "money", "crystal", "gem", "diamond"},
            ["🌳 OBJECT"] = {"tree", "pohon", "rock", "batu", "flower", "bunga"}
        }
        
        local totalObjects = 0
        local foundObjects = {}
        
        -- Inisialisasi kategori
        for catName, _ in pairs(categories) do
            foundObjects[catName] = {}
        end
        foundObjects["❓ LAINNYA"] = {}
        
        -- Scan semua object
        for _, obj in pairs(Workspace:GetDescendants()) do
            totalObjects = totalObjects + 1
            
            local objName = obj.Name:lower()
            local objPos = getObjectPosition(obj)
            if not objPos then goto continue end
            
            local dist = (myPos - objPos).Magnitude
            if dist > 1000 then goto continue end -- Batasi radius 1000 stud
            
            local categorized = false
            
            -- Cek kategori
            for catName, keywords in pairs(categories) do
                for _, kw in ipairs(keywords) do
                    if objName:find(kw) then
                        table.insert(foundObjects[catName], {
                            name = obj.Name,
                            class = obj.ClassName,
                            pos = objPos,
                            dist = dist,
                            obj = obj
                        })
                        categorized = true
                        break
                    end
                end
                if categorized then break end
            end
            
            if not categorized then
                table.insert(foundObjects["❓ LAINNYA"], {
                    name = obj.Name,
                    class = obj.ClassName,
                    pos = objPos,
                    dist = dist,
                    obj = obj
                })
            end
            
            ::continue::
        end
        
        -- Urutkan berdasarkan jarak
        for catName, list in pairs(foundObjects) do
            table.sort(list, function(a, b) return a.dist < b.dist end)
        end
        
        -- Tampilkan hasil
        print("\n📊 HASIL SCAN:")
        for catName, list in pairs(foundObjects) do
            print(string.format("%s: %d object", catName, #list))
        end
        
        print("\n" .. string.rep("=", 60))
        
        -- Tampilkan detail per kategori
        for catName, list in pairs(foundObjects) do
            if #list > 0 then
                print("\n" .. catName .. " (" .. #list .. "):")
                for i = 1, math.min(20, #list) do -- Tampilkan max 20 per kategori
                    local obj = list[i]
                    print(string.format("  %d. [%s] %s - jarak: %.1f stud", 
                        i, obj.class, obj.name, obj.dist))
                end
                if #list > 20 then
                    print("  ... dan " .. (#list - 20) .. " lainnya")
                end
            end
        end
        
        print("\n" .. string.rep("=", 60))
        print("✅ SCAN SELESAI! Total object: " .. totalObjects)
        print("📌 Object terdeteksi: " .. (#foundObjects["🌾 FARMING"] + #foundObjects["👥 NPC"] + #foundObjects["🏪 TOKO"] + #foundObjects["🥚 COLLECT"] + #foundObjects["🌳 OBJECT"] + #foundObjects["❓ LAINNYA"]))
        
        _G.Debug.scanResults = foundObjects
        _G.Debug.scanning = false
        _G.Debug.objectCount = totalObjects
    end
})

-- ========== EXPORT KOORDINAT ==========
DebugTab:CreateButton({
    Name = "📥 EXPORT KOORDINAT NPC",
    Callback = function()
        if not _G.Debug.scanResults or not _G.Debug.scanResults["👥 NPC"] then
            print("❌ Jalankan SCAN FULL MAP dulu")
            return
        end
        
        print("\n📋 DAFTAR KOORDINAT NPC:")
        for i, npc in ipairs(_G.Debug.scanResults["👥 NPC"]) do
            print(string.format("%d. %s: (%.1f, %.1f, %.1f)", 
                i, npc.name, npc.pos.X, npc.pos.Y, npc.pos.Z))
        end
        
        -- Simpan ke file (jika executor support)
        local success, result = pcall(function()
            local fileContent = "-- DAFTAR NPC\n"
            for i, npc in ipairs(_G.Debug.scanResults["👥 NPC"]) do
                fileContent = fileContent .. string.format('["%s"] = CFrame.new(%.1f, %.1f, %.1f),\n', 
                    npc.name, npc.pos.X, npc.pos.Y, npc.pos.Z)
            end
            writefile("NPC_Coordinates.txt", fileContent)
            return true
        end)
        
        if success then
            print("✅ File NPC_Coordinates.txt tersimpan")
        end
    end
})

DebugTab:CreateButton({
    Name = "📥 EXPORT KOORDINAT FARMING",
    Callback = function()
        if not _G.Debug.scanResults or not _G.Debug.scanResults["🌾 FARMING"] then
            print("❌ Jalankan SCAN FULL MAP dulu")
            return
        end
        
        print("\n📋 DAFTAR KOORDINAT FARMING:")
        for i, farm in ipairs(_G.Debug.scanResults["🌾 FARMING"]) do
            print(string.format("%d. %s: (%.1f, %.1f, %.1f)", 
                i, farm.name, farm.pos.X, farm.pos.Y, farm.pos.Z))
        end
        
        local success, result = pcall(function()
            local fileContent = "-- DAFTAR FARMING\n"
            for i, farm in ipairs(_G.Debug.scanResults["🌾 FARMING"]) do
                fileContent = fileContent .. string.format('["%s"] = CFrame.new(%.1f, %.1f, %.1f),\n', 
                    farm.name, farm.pos.X, farm.pos.Y, farm.pos.Z)
            end
            writefile("Farming_Coordinates.txt", fileContent)
            return true
        end)
        
        if success then
            print("✅ File Farming_Coordinates.txt tersimpan")
        end
    end
})

-- ========== TRACK OBJECT ==========
DebugTab:CreateInput({
    Name = "🎯 TRACK OBJECT (ketik nama)",
    PlaceholderText = "Contoh: npcbibit",
    Callback = function(input)
        if input == "" then return end
        
        _G.Debug.tracking = true
        _G.Debug.trackedObject = nil
        
        -- Cari object dengan nama mengandung keyword
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find(input:lower()) then
                _G.Debug.trackedObject = obj
                break
            end
        end
        
        if _G.Debug.trackedObject then
            print("🎯 Melacak: " .. _G.Debug.trackedObject.Name)
            
            -- Loop tracking
            spawn(function()
                while _G.Debug.tracking do
                    local pos = getObjectPosition(_G.Debug.trackedObject)
                    if pos and LocalPlayer.Character then
                        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
                        local dist = (myPos - pos).Magnitude
                        print(string.format("📍 %s - posisi: (%.1f, %.1f, %.1f) | jarak: %.1f stud", 
                            _G.Debug.trackedObject.Name, pos.X, pos.Y, pos.Z, dist))
                    else
                        print("❌ Object hilang")
                        _G.Debug.tracking = false
                    end
                    wait(2)
                end
            end)
        else
            print("❌ Object dengan nama '" .. input .. "' tidak ditemukan")
        end
    end
})

DebugTab:CreateButton({
    Name = "⏹️ STOP TRACKING",
    Callback = function()
        _G.Debug.tracking = false
        print("🛑 Tracking dihentikan")
    end
})

-- ========== DETEKSI OBJECT BERGERAK ==========
DebugTab:CreateButton({
    Name = "🔄 DETEKSI OBJECT BERGERAK",
    Callback = function()
        print("\n🔍 Mencari object bergerak...")
        
        local moving = {}
        local checkPositions = {}
        
        -- Simpan posisi awal
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or (obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart")) then
                local pos = getObjectPosition(obj)
                if pos then
                    checkPositions[obj] = pos
                end
            end
        end
        
        wait(1) -- Tunggu 1 detik
        
        -- Cek perubahan posisi
        for obj, oldPos in pairs(checkPositions) do
            local newPos = getObjectPosition(obj)
            if newPos and (oldPos - newPos).Magnitude > 1 then -- Bergerak lebih dari 1 stud
                table.insert(moving, {
                    name = obj.Name,
                    class = obj.ClassName,
                    oldPos = oldPos,
                    newPos = newPos,
                    distance = (oldPos - newPos).Magnitude
                })
            end
        end
        
        print("\n📊 OBJECT BERGERAK DITEMUKAN: " .. #moving)
        for i, obj in ipairs(moving) do
            print(string.format("%d. %s [%s] - bergerak %.1f stud", 
                i, obj.name, obj.class, obj.distance))
        end
    end
})

-- ========== PETA SEDERHANA ==========
DebugTab:CreateButton({
    Name = "🗺️ TAMPILKAN PETA 2D",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local mapSize = 200 -- Ukuran peta 200x200 stud
        
        print("\n🗺️ PETA LOKASI (X-Z axis)")
        print("📍 Kamu di posisi: " .. string.format("(%.1f, %.1f)", myPos.X, myPos.Z))
        print(string.rep("-", 50))
        
        -- Buat grid sederhana
        for z = -mapSize/2, mapSize/2, 20 do
            local line = ""
            for x = -mapSize/2, mapSize/2, 20 do
                local worldX = myPos.X + x
                local worldZ = myPos.Z + z
                
                -- Cek object di sekitar
                local found = false
                for _, obj in ipairs(_G.Debug.scanResults["👥 NPC"] or {}) do
                    if math.abs(obj.pos.X - worldX) < 10 and math.abs(obj.pos.Z - worldZ) < 10 then
                        line = line .. "👥"
                        found = true
                        break
                    end
                end
                if not found then
                    for _, obj in ipairs(_G.Debug.scanResults["🏪 TOKO"] or {}) do
                        if math.abs(obj.pos.X - worldX) < 10 and math.abs(obj.pos.Z - worldZ) < 10 then
                            line = line .. "🏪"
                            found = true
                            break
                        end
                    end
                end
                if not found then
                    if math.abs(x) < 5 and math.abs(z) < 5 then
                        line = line .. "🔴" -- Posisi player
                    else
                        line = line .. "⬜"
                    end
                end
            end
            print(line)
        end
        print(string.rep("-", 50))
    end
})

-- ========== STATISTIK MAP ==========
DebugTab:CreateButton({
    Name = "📊 STATISTIK MAP",
    Callback = function()
        print("\n" .. string.rep("=", 60))
        print("📊 STATISTIK MAP")
        print(string.rep("=", 60))
        
        print("📍 Posisi player: " .. (LocalPlayer.Character and tostring(LocalPlayer.Character.HumanoidRootPart.Position) or "Unknown"))
        print("👥 Jumlah player: " .. #Players:GetPlayers())
        print("🌍 Nama game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
        print("🆔 Place ID: " .. game.PlaceId)
        print("⏰ Job ID: " .. game.JobId)
        
        if _G.Debug.scanResults then
            print("\n📦 OBJECT TERDETEKSI:")
            for catName, list in pairs(_G.Debug.scanResults) do
                print(string.format("  %s: %d", catName, #list))
            end
        end
        
        print(string.rep("=", 60))
    end
})

-- ========== FIND NEAREST ==========
DebugTab:CreateInput({
    Name = "🎯 CARI OBJECT TERDEKAT",
    PlaceholderText = "Nama object...",
    Callback = function(input)
        if input == "" or not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local nearest = nil
        local nearestDist = math.huge
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find(input:lower()) then
                local pos = getObjectPosition(obj)
                if pos then
                    local dist = (myPos - pos).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = obj
                    end
                end
            end
        end
        
        if nearest then
            local pos = getObjectPosition(nearest)
            print(string.format("✅ %s ditemukan - jarak: %.1f stud", nearest.Name, nearestDist))
            print(string.format("📍 Koordinat: (%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z))
            
            -- Tawarkan teleport
            print("📌 Ketik 'teleport' untuk pergi ke object ini")
            _G.LastFoundObject = nearest
        else
            print("❌ Object tidak ditemukan")
        end
    end
})

DebugTab:CreateButton({
    Name = "🚀 TELEPORT KE OBJECT TERAKHIR",
    Callback = function()
        if _G.LastFoundObject and LocalPlayer.Character then
            local pos = getObjectPosition(_G.LastFoundObject)
            if pos then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
                print("✅ Teleport ke " .. _G.LastFoundObject.Name)
            end
        else
            print("❌ Tidak ada object terakhir")
        end
    end
})

-- ========== RESET DEBUG ==========
DebugTab:CreateButton({
    Name = "🔄 RESET DEBUG",
    Callback = function()
        _G.Debug.scanning = false
        _G.Debug.tracking = false
        _G.Debug.trackedObject = nil
        _G.Debug.scanResults = {}
        _G.LastFoundObject = nil
        print("✅ Debug di-reset")
    end
})

print("🐞 DEBUG MASTER LOADED - Gunakan tab DEBUG MASTER")
