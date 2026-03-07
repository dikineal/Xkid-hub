-- === SCRIPT DEBUG SEDERHANA - PASTI JALAN === --
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⚡ DEBUG SIMPLE ⚡",
    LoadingTitle = "DEBUG MODE",
    LoadingSubtitle = "by XKID",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

-- Buat tab debug
local Tab = Window:CreateTab("🐞 DEBUG", nil)

-- Variable untuk menyimpan hasil
local HasilScan = {}
local ObjectTerakhir = nil

-- Fungsi sederhana untuk dapat posisi
local function DapatPosisi(obj)
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

-- TOMBOL 1: SCAN SEMUA
Tab:CreateButton({
    Name = "🔍 SCAN SEMUA OBJECT",
    Callback = function()
        HasilScan = {}
        print("===== MULAI SCAN =====")
        
        local player = game.Players.LocalPlayer
        if not player.Character then
            print("ERROR: Karakter tidak ada")
            return
        end
        
        local myPos = player.Character.HumanoidRootPart.Position
        print("Posisi saya: " .. tostring(myPos))
        print("")
        
        local count = 0
        for _, obj in pairs(workspace:GetDescendants()) do
            local pos = DapatPosisi(obj)
            if pos then
                local jarak = (myPos - pos).Magnitude
                if jarak < 200 then
                    count = count + 1
                    print(count .. ". " .. obj.Name .. " (" .. obj.ClassName .. ") - jarak: " .. math.floor(jarak))
                    
                    -- Simpan yang penting
                    if obj.Name:lower():find("npc") or obj.Name:lower():find("toko") or obj.Name:lower():find("tanah") then
                        table.insert(HasilScan, {obj = obj, nama = obj.Name, jarak = jarak})
                    end
                end
            end
        end
        
        print("===== SELESAI =====")
        print("Total object: " .. count)
    end
})

-- TOMBOL 2: SCAN NPC
Tab:CreateButton({
    Name = "👥 SCAN NPC",
    Callback = function()
        print("===== SCAN NPC =====")
        
        local player = game.Players.LocalPlayer
        if not player.Character then return end
        
        local myPos = player.Character.HumanoidRootPart.Position
        local found = 0
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= player.Character then
                local pos = DapatPosisi(obj)
                if pos then
                    local jarak = (myPos - pos).Magnitude
                    if jarak < 200 then
                        found = found + 1
                        print(found .. ". " .. obj.Name .. " - jarak: " .. math.floor(jarak))
                    end
                end
            end
        end
        
        print("Total NPC: " .. found)
    end
})

-- TOMBOL 3: SCAN TOKO
Tab:CreateButton({
    Name = "🏪 SCAN TOKO",
    Callback = function()
        print("===== SCAN TOKO =====")
        
        local player = game.Players.LocalPlayer
        if not player.Character then return end
        
        local myPos = player.Character.HumanoidRootPart.Position
        local keywords = {"toko", "shop", "buy", "sell", "jual", "beli"}
        local found = 0
        
        for _, obj in pairs(workspace:GetDescendants()) do
            local nama = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if nama:find(kw) then
                    local pos = DapatPosisi(obj)
                    if pos then
                        local jarak = (myPos - pos).Magnitude
                        if jarak < 200 then
                            found = found + 1
                            print(found .. ". " .. obj.Name .. " - jarak: " .. math.floor(jarak))
                        end
                    end
                    break
                end
            end
        end
        
        print("Total Toko: " .. found)
    end
})

-- TOMBOL 4: SCAN LAHAN
Tab:CreateButton({
    Name = "🌾 SCAN LAHAN",
    Callback = function()
        print("===== SCAN LAHAN =====")
        
        local player = game.Players.LocalPlayer
        if not player.Character then return end
        
        local myPos = player.Character.HumanoidRootPart.Position
        local keywords = {"tanah", "lahan", "field", "soil"}
        local found = 0
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local nama = obj.Name:lower()
                for _, kw in ipairs(keywords) do
                    if nama:find(kw) then
                        local jarak = (myPos - obj.Position).Magnitude
                        if jarak < 200 then
                            found = found + 1
                            print(found .. ". " .. obj.Name .. " - jarak: " .. math.floor(jarak))
                            table.insert(HasilScan, {obj = obj, nama = obj.Name, jarak = jarak})
                        end
                        break
                    end
                end
            end
        end
        
        print("Total Lahan: " .. found)
    end
})

-- TOMBOL 5: CARI OBJECT
Tab:CreateInput({
    Name = "🔎 CARI OBJECT",
    PlaceholderText = "Ketik nama object...",
    Callback = function(input)
        if input == "" then return end
        
        print("===== MENCARI: " .. input .. " =====")
        
        local player = game.Players.LocalPlayer
        if not player.Character then return end
        
        local myPos = player.Character.HumanoidRootPart.Position
        local found = 0
        ObjectTerakhir = nil
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:lower():find(input:lower()) then
                local pos = DapatPosisi(obj)
                if pos then
                    local jarak = (myPos - pos).Magnitude
                    found = found + 1
                    print(found .. ". " .. obj.Name .. " - jarak: " .. math.floor(jarak))
                    
                    if found == 1 then
                        ObjectTerakhir = obj
                    end
                end
            end
        end
        
        print("Ditemukan: " .. found)
        if found > 0 then
            print("Ketik 'tp' untuk teleport ke object pertama")
        end
    end
})

-- TOMBOL 6: TELEPORT
Tab:CreateButton({
    Name = "🚀 TELEPORT KE OBJECT TERAKHIR",
    Callback = function()
        if not ObjectTerakhir then
            print("Tidak ada object terakhir")
            return
        end
        
        local player = game.Players.LocalPlayer
        if not player.Character then return end
        
        local pos = DapatPosisi(ObjectTerakhir)
        if pos then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
            print("Teleport ke: " .. ObjectTerakhir.Name)
        end
    end
})

-- TOMBOL 7: POSISI SAYA
Tab:CreateButton({
    Name = "📍 POSISI SAYA",
    Callback = function()
        local player = game.Players.LocalPlayer
        if player.Character then
            local pos = player.Character.HumanoidRootPart.Position
            print("Posisi: " .. string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z))
        end
    end
})

-- TOMBOL 8: RESET
Tab:CreateButton({
    Name = "🔄 RESET",
    Callback = function()
        HasilScan = {}
        ObjectTerakhir = nil
        print("Semua data di-reset")
    end
})

print("=== DEBUG SEDERHANA SIAP ===")
print("Klik tombol-tombol di atas untuk scan")
