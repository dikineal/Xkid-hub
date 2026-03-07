-- SCRIPT SAWAH INDO - DENGAN LINK SIRIUS.MENU
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO HUB (FIXED)",
    LoadingTitle = "SAWAH INDO",
    LoadingSubtitle = "Berdasarkan Data Asli",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local TeleportTab = Window:CreateTab("📍 TELEPORT", nil)
local NPCTab = Window:CreateTab("👥 NPC", nil)
local LahanTab = Window:CreateTab("🌱 LAHAN", nil)
local AutoTab = Window:CreateTab("⚙ AUTO", nil)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Fungsi teleport
local function teleportTo(name, obj)
    if not obj then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v.Name == name then
                obj = v
                break
            end
        end
    end
    
    if obj and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = nil
        if obj:IsA("BasePart") then
            pos = obj.Position
        elseif obj:IsA("Model") then
            if obj:FindFirstChild("HumanoidRootPart") then
                pos = obj.HumanoidRootPart.Position
            elseif obj:FindFirstChild("Head") then
                pos = obj.Head.Position
            end
        end
        
        if pos then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
            return true
        end
    end
    return false
end

-- ========== TELEPORT TAB ==========
TeleportTab:CreateButton({
    Name = "🛒 npcbibit (BELI BIBIT)",
    Callback = function()
        if teleportTo("npcbibit") then
            print("✅ Teleport ke npcbibit")
        else
            print("❌ npcbibit tidak ditemukan")
        end
    end
})

TeleportTab:CreateButton({
    Name = "💰 npcpenjual (JUAL HASIL)",
    Callback = function()
        if teleportTo("npcpenjual") then
            print("✅ Teleport ke npcpenjual")
        else
            print("❌ npcpenjual tidak ditemukan")
        end
    end
})

TeleportTab:CreateButton({
    Name = "🔧 npcalat (BELI ALAT)",
    Callback = function()
        if teleportTo("npcalat") then
            print("✅ Teleport ke npcalat")
        else
            print("❌ npcalat tidak ditemukan")
        end
    end
})

TeleportTab:CreateButton({
    Name = "🥚 NPCPedagangTelur",
    Callback = function()
        if teleportTo("NPCPedagangTelur") then
            print("✅ Teleport ke Pedagang Telur")
        else
            print("❌ NPCPedagangTelur tidak ditemukan")
        end
    end
})

TeleportTab:CreateButton({
    Name = "🌴 NPCPedagangSawit",
    Callback = function()
        if teleportTo("NPCPedagangSawit") then
            print("✅ Teleport ke Pedagang Sawit")
        else
            print("❌ NPCPedagangSawit tidak ditemukan")
        end
    end
})

-- ========== NPC TAB ==========
NPCTab:CreateButton({
    Name = "📋 DAFTAR SEMUA NPC",
    Callback = function()
        print("=== DAFTAR NPC ===")
        local npcs = {"npcbibit", "npcpenjual", "npcalat", "NPCPedagangTelur", "NPCPedagangSawit"}
        for _, npcName in ipairs(npcs) do
            local found = false
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == npcName then
                    found = true
                    break
                end
            end
            print(npcName .. ": " .. (found and "✅ ADA" or "❌ TIDAK ADA"))
        end
    end
})

NPCTab:CreateButton({ Name = "👨‍🌾 npcbibit", Callback = function() teleportTo("npcbibit") end })
NPCTab:CreateButton({ Name = "👨‍💼 npcpenjual", Callback = function() teleportTo("npcpenjual") end })
NPCTab:CreateButton({ Name = "👨‍🔧 npcalat", Callback = function() teleportTo("npcalat") end })
NPCTab:CreateButton({ Name = "🥚 NPCPedagangTelur", Callback = function() teleportTo("NPCPedagangTelur") end })
NPCTab:CreateButton({ Name = "🌴 NPCPedagangSawit", Callback = function() teleportTo("NPCPedagangSawit") end })

-- ========== LAHAN TAB ==========
LahanTab:CreateButton({
    Name = "🌾 CARI SEMUA LAHAN (Tanah)",
    Callback = function()
        print("=== DAFTAR LAHAN ===")
        local count = 0
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "Tanah" and obj:IsA("BasePart") then
                count = count + 1
                print(string.format("Lahan %d: posisi (%.1f, %.1f, %.1f)", count, obj.Position.X, obj.Position.Y, obj.Position.Z))
            end
        end
        print("Total lahan ditemukan: " .. count)
    end
})

LahanTab:CreateButton({
    Name = "📍 TELEPORT KE LAHAN PERTAMA",
    Callback = function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "Tanah" and obj:IsA("BasePart") then
                teleportTo(nil, obj)
                break
            end
        end
    end
})

LahanTab:CreateButton({
    Name = "📍 TELEPORT KE LAHAN SAWIT",
    Callback = function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:find("Palm_tree") and obj:IsA("MeshPart") then
                teleportTo(nil, obj)
                break
            end
        end
    end
})

-- ========== AUTO TAB ==========
AutoTab:CreateToggle({
    Name = "🔄 AUTO TELEPORT KE SEMUA NPC",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoNPC = v
        if v then
            spawn(function()
                local npcs = {"npcbibit", "npcpenjual", "npcalat", "NPCPedagangTelur", "NPCPedagangSawit"}
                local index = 1
                while _G.AutoNPC do
                    teleportTo(npcs[index])
                    index = index + 1
                    if index > #npcs then index = 1 end
                    wait(3)
                end
            end)
        end
    end
})

AutoTab:CreateButton({
    Name = "📍 KOORDINAT SAYA",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local pos = LocalPlayer.Character.HumanoidRootPart.Position
            print(string.format("📍 Posisi: X=%.1f, Y=%.1f, Z=%.1f", pos.X, pos.Y, pos.Z))
        end
    end
})

AutoTab:CreateButton({
    Name = "🔄 RESET CHARACTER",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
            print("🔄 Character di-reset")
        end
    end
})

print("✅ SCRIPT SIAP DIGUNAKAN!")
print("📌 Daftar NPC yang ditemukan:")
print("   - npcbibit (Beli Bibit)")
print("   - npcpenjual (Jual Hasil)") 
print("   - npcalat (Beli Alat)")
print("   - NPCPedagangTelur (Jual Telur)")
print("   - NPCPedagangSawit (Jual Sawit)")
print("🌾 Lahan: Tanah (banyak)")
