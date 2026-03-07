--====================================================================--
--     XKID SAWAH INDO - PANEN SUPER CEPAT
--====================================================================--

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⚡ SAWAH INDO PANEN CEPAT",
    LoadingTitle = "PANEN CEPAT",
    LoadingSubtitle = "Auto Klik + No Delay",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")

-- Notifikasi
local function Notif(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "PANEN CEPAT",
        Text = msg,
        Duration = 1.5
    })
end

--====================================================================--
--                    TAB MENU
--====================================================================--
local TeleportTab = Window:CreateTab("📍 TELEPORT", nil)
local PanenTab = Window:CreateTab("⚡ PANEN CEPAT", nil)
local SpeedTab = Window:CreateTab("🚀 SPEED HACK", nil)

--====================================================================--
--                    DATABASE NPC
--====================================================================--
local NPC = {
    bibit = "npcbibit",
    penjual = "npcpenjual",
    alat = "npcalat",
    telur = "NPCPedagangTelur",
    sawit = "NPCPedagangSawit"
}

--====================================================================--
--                    FUNGSI TELEPORT (YANG SUDAH JALAN)
--====================================================================--
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
                return true
            end
        end
    end
    return false
end

TeleportTab:CreateButton({ Name = "🛒 " .. NPC.bibit, Callback = function() Teleport(NPC.bibit) Notif("Ke " .. NPC.bibit) end })
TeleportTab:CreateButton({ Name = "💰 " .. NPC.penjual, Callback = function() Teleport(NPC.penjual) Notif("Ke " .. NPC.penjual) end })
TeleportTab:CreateButton({ Name = "🔧 " .. NPC.alat, Callback = function() Teleport(NPC.alat) Notif("Ke " .. NPC.alat) end })
TeleportTab:CreateButton({ Name = "🥚 " .. NPC.telur, Callback = function() Teleport(NPC.telur) Notif("Ke " .. NPC.telur) end })
TeleportTab:CreateButton({ Name = "🌴 " .. NPC.sawit, Callback = function() Teleport(NPC.sawit) Notif("Ke " .. NPC.sawit) end })

--====================================================================--
--                    PANEN SUPER CEPAT (INTI)
--====================================================================--

-- 1. AUTO KLIK TOMBOL PANEN (SUPER CEPAT)
_G.AutoKlikPanen = false
local KlikLoop = nil

local function KlikSemuaTombolPanen()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local klikCount = 0
    
    -- Cari SEMUA tombol yang berhubungan dengan panen
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextButton") then
            local text = obj.Text or ""
            -- Cek berbagai kemungkinan teks tombol
            if text:find("Panen") or text:find("panen") or text:find("PANEN") or 
               text:find("Petik") or text:find("petik") or 
               text:find("Ambil") or text:find("ambil") then
                
                -- KLICK CEPAT (simulasi klik)
                obj:Click()
                klikCount = klikCount + 1
                
                -- Klik juga pakai VirtualUser (alternatif)
                VirtualUser:ClickButton1(Vector2.new(obj.AbsolutePosition.X + 10, obj.AbsolutePosition.Y + 10))
            end
        end
    end
    
    return klikCount
end

PanenTab:CreateToggle({
    Name = "⚡ AUTO KLIK PANEN (SUPER CEPAT)",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoKlikPanen = v
        if v then
            if KlikLoop then KlikLoop:Disconnect() end
            Notif("Auto Klik AKTIF - 10x/detik")
            
            KlikLoop = RunService.Heartbeat:Connect(function()
                if _G.AutoKlikPanen then
                    local jumlah = KlikSemuaTombolPanen()
                    if jumlah > 0 then
                        -- Notif setiap 10 kali klik (biar tidak spam)
                        if math.random(1,10) == 1 then
                            Notif("Mengklik " .. jumlah .. " tombol")
                        end
                    end
                end
            end)
        else
            if KlikLoop then KlikLoop:Disconnect() end
            Notif("Auto Klik MATI")
        end
    end
})

-- 2. KLIK MANUAL CEPAT (untuk test)
PanenTab:CreateButton({
    Name = "👆 KLIK PANEN SEKARANG (10x)",
    Callback = function()
        Notif("Mengklik 10x...")
        for i = 1, 10 do
            KlikSemuaTombolPanen()
            wait(0.05) -- 50ms antar klik
        end
        Notif("Selesai klik 10x")
    end
})

-- 3. KLIK TERUS SAMPAI BERHENTI
PanenTab:CreateButton({
    Name = "🔥 KLIK TERUS (STOP DI EXECUTOR)",
    Callback = function()
        Notif("MULAI KLIK TERUS... (close script to stop)")
        while true do
            KlikSemuaTombolPanen()
            wait(0.1) -- 10x per detik
        end
    end
})

--====================================================================--
--                    SPEED HACK (HILANGKAN ANIMASI)
--====================================================================--

-- Speed hack untuk mempercepat animasi game
_G.SpeedHack = false
local SpeedLoop = nil

local function ApplySpeedHack()
    -- Coba percepat semua animasi
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- Percepat animasi pada part
        if obj:IsA("BasePart") then
            -- Tidak ada property langsung untuk speed, tapi kita bisa manipulasi
        end
        
        -- Percepat pada humanoid
        if obj:IsA("Humanoid") then
            -- Ini akan mempercepat gerakan karakter, bukan animasi panen
        end
    end
end

SpeedTab:CreateToggle({
    Name = "🚀 SPEED HACK GLOBAL",
    CurrentValue = false,
    Callback = function(v)
        _G.SpeedHack = v
        if v then
            Notif("Speed Hack AKTIF (coba percepat)")
            -- Set game speed (kalau ada)
            if game:FindFirstChild("RunService") then
                -- Tidak bisa langsung, tapi kita bisa loop cepat
            end
        else
            Notif("Speed Hack MATI")
        end
    end
})

-- Percepat klik dengan loop sendiri
SpeedTab:CreateButton({
    Name = "⚡ KLIK 50x PER DETIK",
    Callback = function()
        Notif("KLIK 50x PER DETIK - BERBAHAYA!")
        local count = 0
        while count < 500 do
            KlikSemuaTombolPanen()
            count = count + 1
            wait(0.02) -- 50x per detik
        end
        Notif("Selesai 500 klik")
    end
})

--====================================================================--
--                    SPEED UP ANIMASI (TRICK)
--====================================================================--

-- Trick untuk mempercepat game dengan mengubah time scale
-- (Tidak semua game mengizinkan)
local function SetTimeScale(scale)
    -- Coba berbagai cara
    pcall(function()
        game:GetService("RunService"):SetTimeScale(scale)
    end)
    
    pcall(function()
        Workspace:FindFirstChild("Terrain").TimeScale = scale
    end)
end

SpeedTab:CreateButton({
    Name = "⏩ SET TIME SCALE 2x",
    Callback = function()
        SetTimeScale(2)
        Notif("Time Scale 2x (jika didukung)")
    end
})

SpeedTab:CreateButton({
    Name = "⏪ RESET TIME SCALE",
    Callback = function()
        SetTimeScale(1)
        Notif("Time Scale normal")
    end
})

--====================================================================--
--                    AUTO PANEN PINTAR (COBA DETEKSI)
--====================================================================--

_G.AutoPanenPintar = false
local PintarLoop = nil

local function DeteksiDanPanen()
    -- Method 1: Cari GUI
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, obj in pairs(playerGui:GetDescendants()) do
            if obj:IsA("TextButton") and (obj.Text or ""):find("Panen") then
                obj:Click()
                return true
            end
        end
    end
    
    -- Method 2: Cari object di workspace (jika ada)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:find("Padi") or obj.Name:find("padi") then
            if obj:IsA("BasePart") then
                local jarak = (LocalPlayer.Character.HumanoidRootPart.Position - obj.Position).Magnitude
                if jarak < 15 then
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
                    wait(0.05)
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
                end
            end
        end
    end
    
    return false
end

PanenTab:CreateToggle({
    Name = "🧠 AUTO PANEN PINTAR",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoPanenPintar = v
        if v then
            if PintarLoop then PintarLoop:Disconnect() end
            Notif("Auto Panen Pintar AKTIF")
            
            PintarLoop = RunService.Heartbeat:Connect(function()
                if _G.AutoPanenPintar then
                    DeteksiDanPanen()
                end
            end)
        else
            if PintarLoop then PintarLoop:Disconnect() end
            Notif("Auto Panen Pintar MATI")
        end
    end
})

--====================================================================--
--                    STARTUP
--====================================================================--
Notif("PANEN CEPAT READY - Teleport & Auto Klik")
print("✅ SCRIPT PANEN CEPAT")
print("📌 Fitur:")
print("   - Teleport (bekerja)")
print("   - Auto Klik Panen (coba aktifkan)")
print("   - Speed Hack (eksperimental)")
