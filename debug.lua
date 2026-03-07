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
})

-- ========== Mulai Script Debug ==========
local DebugTab = Window:CreateTab("🐞 DEBUG MAP", nil)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

-- Fungsi untuk mendapatkan posisi object
local function getPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        if obj:FindFirstChild("HumanoidRootPart") then
            return obj.HumanoidRootPart.Position
        elseif obj:FindFirstChild("Head") then
            return obj.Head.Position
        end
    end
    return nil
end

-- Fungsi untuk menampilkan hasil di console
local function printResult(title, data)
    print("\n" .. string.rep("=", 60))
    print(title)
    print(string.rep("=", 60))
    for i, line in ipairs(data) do
        print(line)
    end
    print(string.rep("=", 60) .. "\n")
end

-- ========== SCAN LENGKAP ==========
DebugTab:CreateButton({
    Name = "🔍 SCAN SEMUA OBJECT",
    Callback = function()
        if not LocalPlayer.Character then
            print("❌ Tunggu karakter muncul")
            return
        end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local results = {}
        local categories = {
            NPC = {},
            Toko = {},
            Lahan = {},
            Tanaman = {},
            Lainnya = {}
        }
        
        print("\n🔍 MULAI SCAN...")
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            local pos = getPosition(obj)
            if pos and (myPos - pos).Magnitude < 500 then
                local name = obj.Name:lower()
                local dist = (myPos - pos).Magnitude
                
                -- Kategorisasi
                if name:find("npc") or obj:FindFirstChild("Humanoid") then
                    table.insert(categories.NPC, {name = obj.Name, dist = dist, pos = pos})
                elseif name:find("toko") or name:find("shop") or name:find("buy") or name:find("sell") or name:find("jual") or name:find("beli") then
                    table.insert(categories.Toko, {name = obj.Name, dist = dist, pos = pos})
                elseif name:find("tanah") or name:find("lahan") or name:find("field") or name:find("soil") then
                    table.insert(categories.Lahan, {name = obj.Name, dist = dist, pos = pos})
                elseif name:find("tomat") or name:find("jagung") or name:find("padi") or name:find("terong") or name:find("strawberry") or name:find("durian") or name:find("sawit") then
                    table.insert(categories.Tanaman, {name = obj.Name, dist = dist, pos = pos})
                elseif (myPos - pos).Magnitude < 20 then
                    table.insert(categories.Lainnya, {name = obj.Name, class = obj.ClassName, dist = dist})
                end
            end
        end
        
        -- Urutkan berdasarkan jarak
        for cat, list in pairs(categories) do
            table.sort(list, function(a, b) return a.dist < b.dist end)
        end
        
        -- Tampilkan hasil
        local output = {}
        table.insert(output, "📍 POSISI SAYA: " .. string.format("%.1f, %.1f, %.1f", myPos.X, myPos.Y, myPos.Z))
        table.insert(output, "")
        table.insert(output, "📊 HASIL SCAN (radius 500 stud):")
        table.insert(output, string.format("👥 NPC: %d", #categories.NPC))
        table.insert(output, string.format("🏪 TOKO: %d", #categories.Toko))
        table.insert(output, string.format("🌾 LAHAN: %d", #categories.Lahan))
        table.insert(output, string.format("🌽 TANAMAN: %d", #categories.Tanaman))
        table.insert(output, string.format("📦 LAINNYA: %d", #categories.Lainnya))
        table.insert(output, "")
        
        -- Detail NPC
        if #categories.NPC > 0 then
            table.insert(output, "👥 DAFTAR NPC:")
            for i, npc in ipairs(categories.NPC) do
                table.insert(output, string.format("  %d. %s - %.1f stud", i, npc.name, npc.dist))
            end
            table.insert(output, "")
        end
        
        -- Detail Toko
        if #categories.Toko > 0 then
            table.insert(output, "🏪 DAFTAR TOKO:")
            for i, toko in ipairs(categories.Toko) do
                table.insert(output, string.format("  %d. %s - %.1f stud", i, toko.name, toko.dist))
            end
            table.insert(output, "")
        end
        
        printResult("🔍 HASIL SCAN LENGKAP", output)
    end
})

-- ========== SCAN NPC ONLY ==========
DebugTab:CreateButton({
    Name = "👥 SCAN NPC SAJA",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local npcs = {}
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= LocalPlayer.Character then
                local pos = getPosition(obj)
                if pos then
                    local dist = (myPos - pos).Magnitude
                    table.insert(npcs, {name = obj.Name, dist = dist, pos = pos})
                end
            end
        end
        
        table.sort(npcs, function(a, b) return a.dist < b.dist end)
        
        local output = {}
        table.insert(output, "📍 POSISI SAYA: " .. tostring(myPos))
        table.insert(output, "")
        table.insert(output, "👥 TOTAL NPC: " .. #npcs)
        table.insert(output, "")
        
        for i, npc in ipairs(npcs) do
            table.insert(output, string.format("%d. %s - %.1f stud", i, npc.name, npc.dist))
        end
        
        printResult("👥 DAFTAR NPC", output)
    end
})

-- ========== SCAN TOKO ==========
DebugTab:CreateButton({
    Name = "🏪 SCAN TOKO/SELL/BUY",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local toko = {}
        local keywords = {"toko", "shop", "buy", "sell", "jual", "beli", "merchant"}
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            local name = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if name:find(kw) then
                    local pos = getPosition(obj)
                    if pos then
                        local dist = (myPos - pos).Magnitude
                        table.insert(toko, {name = obj.Name, dist = dist, pos = pos})
                        break
                    end
                end
            end
        end
        
        table.sort(toko, function(a, b) return a.dist < b.dist end)
        
        local output = {}
        table.insert(output, "📍 POSISI SAYA: " .. tostring(myPos))
        table.insert(output, "")
        table.insert(output, "🏪 TOTAL TOKO: " .. #toko)
        table.insert(output, "")
        
        for i, t in ipairs(toko) do
            table.insert(output, string.format("%d. %s - %.1f stud", i, t.name, t.dist))
        end
        
        printResult("🏪 DAFTAR TOKO", output)
    end
})

-- ========== SCAN LAHAN ==========
DebugTab:CreateButton({
    Name = "🌾 SCAN LAHAN/TANAH",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local lahan = {}
        local keywords = {"tanah", "lahan", "field", "soil", "farm"}
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                for _, kw in ipairs(keywords) do
                    if name:find(kw) then
                        local dist = (myPos - obj.Position).Magnitude
                        table.insert(lahan, {name = obj.Name, dist = dist, pos = obj.Position})
                        break
                    end
                end
            end
        end
        
        table.sort(lahan, function(a, b) return a.dist < b.dist end)
        
        local output = {}
        table.insert(output, "📍 POSISI SAYA: " .. tostring(myPos))
        table.insert(output, "")
        table.insert(output, "🌾 TOTAL LAHAN: " .. #lahan)
        table.insert(output, "")
        
        for i, l in ipairs(lahan) do
            table.insert(output, string.format("%d. %s - %.1f stud", i, l.name, l.dist))
        end
        
        printResult("🌾 DAFTAR LAHAN", output)
    end
})

-- ========== SCAN TANAMAN ==========
DebugTab:CreateButton({
    Name = "🌽 SCAN TANAMAN",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local tanaman = {}
        local keywords = {"tomat", "jagung", "padi", "terong", "strawberry", "durian", "sawit", "plant", "crop"}
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            local name = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if name:find(kw) then
                    local pos = getPosition(obj)
                    if pos then
                        local dist = (myPos - pos).Magnitude
                        table.insert(tanaman, {name = obj.Name, dist = dist, pos = pos})
                        break
                    end
                end
            end
        end
        
        table.sort(tanaman, function(a, b) return a.dist < b.dist end)
        
        local output = {}
        table.insert(output, "📍 POSISI SAYA: " .. tostring(myPos))
        table.insert(output, "")
        table.insert(output, "🌽 TOTAL TANAMAN: " .. #tanaman)
        table.insert(output, "")
        
        for i, t in ipairs(tanaman) do
            table.insert(output, string.format("%d. %s - %.1f stud", i, t.name, t.dist))
        end
        
        printResult("🌽 DAFTAR TANAMAN", output)
    end
})

-- ========== CARI OBJECT ==========
DebugTab:CreateInput({
    Name = "🔎 CARI OBJECT (ketik nama)",
    PlaceholderText = "Contoh: npc, toko, tanah",
    Callback = function(input)
        if input == "" or not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local found = {}
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find(input:lower()) then
                local pos = getPosition(obj)
                if pos then
                    local dist = (myPos - pos).Magnitude
                    table.insert(found, {name = obj.Name, class = obj.ClassName, dist = dist, pos = pos, obj = obj})
                end
            end
        end
        
        table.sort(found, function(a, b) return a.dist < b.dist end)
        
        local output = {}
        table.insert(output, "📍 POSISI SAYA: " .. tostring(myPos))
        table.insert(output, "")
        table.insert(output, "🔎 PENCARIAN: '" .. input .. "'")
        table.insert(output, "📦 DITEMUKAN: " .. #found)
        table.insert(output, "")
        
        for i, f in ipairs(found) do
            table.insert(output, string.format("%d. [%s] %s - %.1f stud", i, f.class, f.name, f.dist))
        end
        
        if #found > 0 then
            table.insert(output, "")
            table.insert(output, "📌 Ketik 'tp' di chat untuk teleport ke object pertama")
            _G.LastFound = found[1].obj
        end
        
        printResult("🔎 HASIL PENCARIAN", output)
    end
})

-- ========== TELEPORT KE OBJECT TERAKHIR ==========
DebugTab:CreateButton({
    Name = "🚀 TELEPORT KE OBJECT TERAKHIR",
    Callback = function()
        if _G.LastFound and LocalPlayer.Character then
            local pos = getPosition(_G.LastFound)
            if pos then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
                print("✅ Teleport ke " .. _G.LastFound.Name)
            end
        else
            print("❌ Tidak ada object terakhir")
        end
    end
})

-- ========== EKSPOR KOORDINAT ==========
DebugTab:CreateButton({
    Name = "📥 EKSPOR KOORDINAT NPC",
    Callback = function()
        local npcs = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= LocalPlayer.Character then
                local pos = getPosition(obj)
                if pos then
                    table.insert(npcs, {name = obj.Name, pos = pos})
                end
            end
        end
        
        local output = "-- DAFTAR NPC\n"
        for _, npc in ipairs(npcs) do
            output = output .. string.format('["%s"] = CFrame.new(%.1f, %.1f, %.1f),\n', 
                npc.name, npc.pos.X, npc.pos.Y, npc.pos.Z)
        end
        
        print("\n📋 KOORDINAT NPC (" .. #npcs .. "):")
        print(output)
        
        -- Simpan ke file
        pcall(function()
            writefile("NPC_Coords.txt", output)
            print("✅ File NPC_Coords.txt tersimpan")
        end)
    end
})

-- ========== INFO GAME ==========
DebugTab:CreateButton({
    Name = "ℹ️ INFO GAME",
    Callback = function()
        local output = {}
        table.insert(output, "🎮 Nama Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
        table.insert(output, "🆔 Place ID: " .. game.PlaceId)
        table.insert(output, "⏰ Job ID: " .. game.JobId)
        table.insert(output, "👥 Player: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
        table.insert(output, "📍 Posisi: " .. (LocalPlayer.Character and tostring(LocalPlayer.Character.HumanoidRootPart.Position) or "Unknown"))
        
        printResult("ℹ️ INFORMASI GAME", output)
    end
})

-- ========== NOTIFIKASI ==========
print("🐞 DEBUG MAP TELAH DITAMBAHKAN")
