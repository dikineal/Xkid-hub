--====================================================================--
--     XKID SAWAH INDO HUB - VERSION FIX (PASTI JALAN)
--====================================================================--

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 XKID SAWAH INDO FIX",
    LoadingTitle = "SAWAH INDO",
    LoadingSubtitle = "Version Fix",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

-- Notifikasi
local function Notif(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "XKID HUB",
        Text = msg,
        Duration = 2
    })
end

--====================================================================--
--                    TAB MENU
--====================================================================--
local TeleportTab = Window:CreateTab("📍 TELEPORT", nil)
local ManualTab = Window:CreateTab("🖐️ MANUAL", nil)  -- GANTI AUTO FARM JADI MANUAL DULU
local PlayerTab = Window:CreateTab("👤 PLAYER", nil)
local UtilityTab = Window:CreateTab("⚙ UTILITY", nil)

--====================================================================--
--                    DATABASE NPC (DARI DEBUG LO)
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

-- Fungsi dapat posisi (SEDERHANA)
local function GetPos(obj)
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

-- Fungsi teleport (SUDAH BEKERJA)
local function Teleport(nama)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == nama then
            local pos = GetPos(obj)
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

-- Fungsi interaksi (SEDERHANA - PAKAI TOUCH SAJA)
local function Touch(obj)
    if not obj or not LocalPlayer.Character then return end
    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
    wait(0.1)
    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
end

--====================================================================--
--                    TELEPORT TAB (SUDAH BEKERJA)
--====================================================================--
TeleportTab:CreateButton({ Name = "🛒 " .. NPC.bibit, Callback = function() Teleport(NPC.bibit) end })
TeleportTab:CreateButton({ Name = "💰 " .. NPC.penjual, Callback = function() Teleport(NPC.penjual) end })
TeleportTab:CreateButton({ Name = "🔧 " .. NPC.alat, Callback = function() Teleport(NPC.alat) end })
TeleportTab:CreateButton({ Name = "🥚 " .. NPC.telur, Callback = function() Teleport(NPC.telur) end })
TeleportTab:CreateButton({ Name = "🌴 " .. NPC.sawit, Callback = function() Teleport(NPC.sawit) end })

--====================================================================--
--                    MANUAL TAB (GANTI AUTO FARM)
--====================================================================--

-- Tombol untuk TEST interaksi
ManualTab:CreateButton({
    Name = "🖐️ TEST INTERAKSI (Touch)",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        -- Cari object di depan player
        local ray = Ray.new(
            LocalPlayer.Character.Head.Position,
            LocalPlayer.Character.Head.CFrame.LookVector * 10
        )
        local hit, pos = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
        
        if hit then
            print("Menyentuh: " .. hit.Name)
            Touch(hit)
            Notif("Menyentuh " .. hit.Name)
        else
            Notif("Tidak ada object di depan")
        end
    end
})

-- Tombol untuk cari lahan terdekat
ManualTab:CreateButton({
    Name = "🌾 CARI LAHAN TERDEKAT",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local terdekat = nil
        local jarakTerdekat = 999999
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "Tanah" and obj:IsA("BasePart") then
                local jarak = (myPos - obj.Position).Magnitude
                if jarak < jarakTerdekat then
                    jarakTerdekat = jarak
                    terdekat = obj
                end
            end
        end
        
        if terdekat then
            print("Lahan terdekat: " .. terdekat.Name .. " - jarak: " .. math.floor(jarakTerdekat))
            Notif("Lahan ditemukan, jarak " .. math.floor(jarakTerdekat))
            
            -- Tanya mau teleport?
            print("Klik tombol TELEPORT KE LAHAN untuk pergi ke sana")
        else
            Notif("Tidak ada lahan")
        end
    end
})

-- Tombol teleport ke lahan
ManualTab:CreateButton({
    Name = "📍 TELEPORT KE LAHAN TERDEKAT",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local terdekat = nil
        local jarakTerdekat = 999999
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "Tanah" and obj:IsA("BasePart") then
                local jarak = (myPos - obj.Position).Magnitude
                if jarak < jarakTerdekat then
                    jarakTerdekat = jarak
                    terdekat = obj
                end
            end
        end
        
        if terdekat then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(terdekat.Position.X, terdekat.Position.Y + 3, terdekat.Position.Z)
            Notif("Teleport ke lahan")
        end
    end
})

-- Tombol TEST tanam manual
ManualTab:CreateButton({
    Name = "🌱 TEST TANAM (di lahan terdekat)",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "Tanah" and obj:IsA("BasePart") then
                local jarak = (myPos - obj.Position).Magnitude
                if jarak < 10 then
                    print("Menanam di " .. obj.Name)
                    Touch(obj)
                    Notif("Mencoba menanam...")
                    return
                end
            end
        end
        Notif("Tidak ada lahan di dekat sini")
    end
})

-- Tombol TEST panen manual
ManualTab:CreateButton({
    Name = "🌽 TEST PANEN",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        local tanamanList = {"Tomat", "Jagung", "Padi", "Strawberry", "Terong", "Durian", "Sawit"}
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        
        for _, nama in ipairs(tanamanList) do
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name:find(nama) then
                    local pos = GetPos(obj)
                    if pos then
                        local jarak = (myPos - pos).Magnitude
                        if jarak < 10 then
                            print("Memanen " .. obj.Name)
                            Touch(obj)
                            Notif("Mencoba memanen...")
                            return
                        end
                    end
                end
            end
        end
        Notif("Tidak ada tanaman di dekat sini")
    end
})

-- Tombol TEST jual manual
ManualTab:CreateButton({
    Name = "💰 TEST JUAL (ke npcpenjual)",
    Callback = function()
        local penjual = nil
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "npcpenjual" then
                penjual = obj
                break
            end
        end
        
        if penjual then
            local pos = GetPos(penjual)
            if pos then
                local jarak = (LocalPlayer.Character.HumanoidRootPart.Position - pos).Magnitude
                if jarak < 10 then
                    print("Mencoba jual ke npcpenjual")
                    Touch(penjual)
                    Notif("Mencoba menjual...")
                else
                    Notif("Terlalu jauh, teleport dulu")
                end
            end
        else
            Notif("npcpenjual tidak ditemukan")
        end
    end
})

--====================================================================--
--                    PLAYER TAB (SEDERHANA)
--====================================================================--
PlayerTab:CreateSlider({
    Name = "🚶 WALK SPEED",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
})

PlayerTab:CreateToggle({
    Name = "🔄 INFINITE JUMP",
    CurrentValue = false,
    Callback = function(v)
        _G.InfiniteJump = v
        if v then
            UIS.JumpRequest:Connect(function()
                if _G.InfiniteJump and LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        end
    end
})

--====================================================================--
--                    UTILITY TAB
--====================================================================--
UtilityTab:CreateButton({
    Name = "📍 CEK POSISI SAYA",
    Callback = function()
        if LocalPlayer.Character then
            local pos = LocalPlayer.Character.HumanoidRootPart.Position
            print(string.format("Posisi: X=%.1f, Y=%.1f, Z=%.1f", pos.X, pos.Y, pos.Z))
            Notif("Posisi: " .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z))
        end
    end
})

UtilityTab:CreateButton({
    Name = "🔍 SCAN OBJECT DI SEKITAR",
    Callback = function()
        if not LocalPlayer.Character then return end
        
        print("\n===== SCAN (radius 50) =====")
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local count = 0
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local jarak = (myPos - obj.Position).Magnitude
                if jarak < 50 then
                    count = count + 1
                    print(count .. ". " .. obj.Name .. " - jarak: " .. math.floor(jarak))
                end
            end
        end
        
        print("Total: " .. count)
        Notif("Scan selesai, lihat console")
    end
})

UtilityTab:CreateButton({
    Name = "💀 RESET CHARACTER",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end
})

--====================================================================--
--                    STARTUP
--====================================================================--
Notif("XKID HUB FIX - Teleport siap")
print("✅ XKID SAWAH INDO FIX LOADED")
print("📌 Teleport: Bekerja 100%")
print("📌 Manual: Coba TEST satu per satu")
