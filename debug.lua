--====================================================================--
--     XKID SAWAH INDO - VERSION KHUSUS (BERDASARKAN SCREENSHOT)
--====================================================================--

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO XKID NGANTUK",
    LoadingTitle = "SAWAH INDO",
    LoadingSubtitle = "BELUM TIDUR",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

-- Notifikasi
local function Notif(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "SAWAH INDO",
        Text = msg,
        Duration = 2
    })
end

--====================================================================--
--                    TAB MENU
--====================================================================--
local TeleportTab = Window:CreateTab("📍 TELEPORT", nil)
local PanenTab = Window:CreateTab("🌾 PANEN", nil)
local TanamTab = Window:CreateTab("🌱 TANAM", nil)
local InfoTab = Window:CreateTab("ℹ️ INFO", nil)

--====================================================================--
--                    DATABASE NPC (DARI DEBUG SEBELUMNYA)
--====================================================================--
local NPC = {
    bibit = "npcbibit",
    penjual = "npcpenjual",
    alat = "npcalat",
    telur = "NPCPedagangTelur",
    sawit = "NPCPedagangSawit"
}

--====================================================================--
--                    FUNGSI DASAR
--====================================================================--

-- Fungsi teleport (SUDAH BEKERJA)
local function Teleport(nama)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == nama then
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
            if pos and LocalPlayer.Character then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
                Notif("Teleport ke " .. nama)
                return true
            end
        end
    end
    Notif(nama .. " tidak ditemukan")
    return false
end

-- Fungsi klik GUI (PENTING! Ini untuk klik tombol Panen)
local function KlikTombolPanen()
    -- Cari di PlayerGui
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    -- Cari semua tombol
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextButton") then
            local text = obj.Text or ""
            -- Cari tombol dengan teks "Panen"
            if text:find("Panen") then
                print("Menemukan tombol Panen: " .. obj.Name)
                obj:Click() -- Klik tombol
                return true
            end
        end
    end
    return false
end

-- Fungsi klik tombol Beli/Tanam
local function KlikTombolTanam()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextButton") then
            local text = obj.Text or ""
            if text:find("Tanam") or text:find("Beli") then
                obj:Click()
                return true
            end
        end
    end
    return false
end

--====================================================================--
--                    TELEPORT TAB (YANG SUDAH BEKERJA)
--====================================================================--
TeleportTab:CreateButton({ Name = "🛒 " .. NPC.bibit, Callback = function() Teleport(NPC.bibit) end })
TeleportTab:CreateButton({ Name = "💰 " .. NPC.penjual, Callback = function() Teleport(NPC.penjual) end })
TeleportTab:CreateButton({ Name = "🔧 " .. NPC.alat, Callback = function() Teleport(NPC.alat) end })
TeleportTab:CreateButton({ Name = "🥚 " .. NPC.telur, Callback = function() Teleport(NPC.telur) end })
TeleportTab:CreateButton({ Name = "🌴 " .. NPC.sawit, Callback = function() Teleport(NPC.sawit) end })

--====================================================================--
--                    PANEN TAB (FOKUS UTAMA)
--====================================================================--

-- AUTO PANEN CEPAT
_G.AutoPanen = false
local PanenLoop = nil

local function StartAutoPanen()
    if PanenLoop then PanenLoop:Disconnect() end
    if not _G.AutoPanen then return end
    
    PanenLoop = RunService.Heartbeat:Connect(function()
        if not _G.AutoPanen then return end
        
        -- Method 1: Klik GUI Panen
        local berhasil = KlikTombolPanen()
        
        -- Method 2: Cari object tanaman (jika ada)
        if not berhasil then
            local tanamanList = {"Padi", "Tomat", "Jagung", "Strawberry", "Terong", "Durian", "Sawit"}
            for _, nama in ipairs(tanamanList) do
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name:find(nama) then
                        if obj:IsA("BasePart") then
                            local jarak = (LocalPlayer.Character.HumanoidRootPart.Position - obj.Position).Magnitude
                            if jarak < 10 then
                                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
                                wait(0.1)
                                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
                            end
                        end
                        break
                    end
                end
            end
        end
        
        wait(0.5) -- Cek setiap 0.5 detik
    end)
end

PanenTab:CreateToggle({
    Name = "⚡ AUTO PANEN CEPAT",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoPanen = v
        if v then
            StartAutoPanen()
            Notif("Auto Panen AKTIF")
        else
            if PanenLoop then PanenLoop:Disconnect() end
            Notif("Auto Panen MATI")
        end
    end
})

PanenTab:CreateButton({
    Name = "👆 KLIK PANEN MANUAL (LANGSUNG)",
    Callback = function()
        if KlikTombolPanen() then
            Notif("Tombol Panen diklik!")
        else
            Notif("Tidak ada tombol Panen")
        end
    end
})

--====================================================================--
--                    TANAM TAB
--====================================================================--

-- AUTO TANAM
_G.AutoTanam = false
local TanamLoop = nil

local function StartAutoTanam()
    if TanamLoop then TanamLoop:Disconnect() end
    if not _G.AutoTanam then return end
    
    TanamLoop = RunService.Heartbeat:Connect(function()
        if not _G.AutoTanam then return end
        
        -- Cari lahan (mungkin bukan "Tanah", tapi object lain)
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:find("Tanah") or obj.Name:find("Lahan") or obj.Name:find("Soil")) then
                local jarak = (LocalPlayer.Character.HumanoidRootPart.Position - obj.Position).Magnitude
                if jarak < 10 then
                    -- Coba interaksi
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
                    wait(0.1)
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
                    wait(0.5)
                    
                    -- Klik tombol Tanam/Beli
                    KlikTombolTanam()
                end
            end
        end
        wait(1)
    end)
end

TanamTab:CreateToggle({
    Name = "🌱 AUTO TANAM",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoTanam = v
        if v then
            StartAutoTanam()
            Notif("Auto Tanam AKTIF")
        else
            if TanamLoop then TanamLoop:Disconnect() end
            Notif("Auto Tanam MATI")
        end
    end
})

--====================================================================--
--                    INFO TAB (UNTUK DEBUG)
--====================================================================--
InfoTab:CreateButton({
    Name = "🔍 SCAN OBJECT DI SEKITAR",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        -- Tampilkan di NOTIF, bukan di console
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local hasil = {}
        local count = 0
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local jarak = (myPos - obj.Position).Magnitude
                if jarak < 30 then
                    count = count + 1
                    table.insert(hasil, obj.Name)
                end
            end
        end
        
        -- Tampilkan 5 object pertama di notif
        local msg = "Ditemukan " .. count .. " object\n"
        for i = 1, math.min(5, #hasil) do
            msg = msg .. hasil[i] .. "\n"
        end
        
        Notif(msg)
    end
})

InfoTab:CreateButton({
    Name = "🌾 CARI LAHAN",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local found = false
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:find("Tanah") or obj.Name:find("Lahan") or obj.Name:find("Soil")) then
                local jarak = (myPos - obj.Position).Magnitude
                Notif("Lahan: " .. obj.Name .. " jarak " .. math.floor(jarak))
                found = true
                break
            end
        end
        
        if not found then
            Notif("Tidak ada lahan")
        end
    end
})

InfoTab:CreateButton({
    Name = "🌽 CARI TANAMAN",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        local tanamanList = {"Padi", "Tomat", "Jagung", "Strawberry", "Terong", "Durian", "Sawit"}
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local found = false
        
        for _, nama in ipairs(tanamanList) do
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name:find(nama) then
                    if obj:IsA("BasePart") then
                        local jarak = (myPos - obj.Position).Magnitude
                        Notif("Tanaman: " .. obj.Name .. " jarak " .. math.floor(jarak))
                        found = true
                        break
                    end
                end
            end
            if found then break end
        end
        
        if not found then
            Notif("Tidak ada tanaman")
        end
    end
})

InfoTab:CreateButton({
    Name = "👆 TEST KLIK PANEN",
    Callback = function()
        if KlikTombolPanen() then
            Notif("Berhasil klik Panen")
        else
            Notif("Tidak ada tombol Panen")
        end
    end
})

--====================================================================--
--                    STARTUP
--====================================================================--
Notif("XKID SAWAH INDO READY")
print("✅ SCRIPT SIAP - FOKUS PANEN")
