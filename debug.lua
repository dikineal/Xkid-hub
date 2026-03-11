--====================================================
-- XKID HUB | SAWAH INDO ULTIMATE v4.0
-- Dengan ProximityPrompt Lengkap!
--====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO ULTIMATE 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "v4.0 | ProximityPrompt Edition",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XKIDHub",
        FileName = "SawahConfig"
    },
    KeySystem = false
})

--====================================================
-- SERVICES & GLOBAL
--====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInput = game:GetService("VirtualInputManager")

-- Remote Path
local Remotes = RS:FindFirstChild("Remotes")
local TutorialRemotes = Remotes and Remotes:FindFirstChild("TutorialRemotes")

-- ClientBoot Path
local ClientBoot = LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("ClientBoot")

--====================================================
-- PROXIMITY PROMPT PATHS (DARI LO!)
--====================================================
local PROMPTS = {
    Bibit = Workspace:FindFirstChild("NPCs") and Workspace.NPCs:FindFirstChild("NPC_Bibit") and Workspace.NPCs.NPC_Bibit:FindFirstChild("npcbibit") and Workspace.NPCs.NPC_Bibit.npcbibit:FindFirstChild("ProximityPrompt"),
    Alat = Workspace:FindFirstChild("NPCs") and Workspace.NPCs:FindFirstChild("NPC_Alat") and Workspace.NPCs.NPC_Alat:FindFirstChild("npcalat") and Workspace.NPCs.NPC_Alat.npcalat:FindFirstChild("ProximityPrompt"),
    Sawit = Workspace:FindFirstChild("NPCs") and Workspace.NPCs:FindFirstChild("NPC_PedagangSawit") and Workspace.NPCs.NPC_PedagangSawit:FindFirstChild("NPCPedagangSawit") and Workspace.NPCs.NPC_PedagangSawit.NPCPedagangSawit:FindFirstChild("ProximityPrompt"),
    Telur = Workspace:FindFirstChild("NPCs") and Workspace.NPCs:FindFirstChild("NPCPedagangTelur") and Workspace.NPCs.NPCPedagangTelur:FindFirstChild("NPCPedagangTelur") and Workspace.NPCs.NPCPedagangTelur.NPCPedagangTelur:FindFirstChild("ProximityPrompt"),
    CoopPlot = Workspace:FindFirstChild("CoopPlots") and Workspace.CoopPlots:FindFirstChild("CoopPlot_1") and Workspace.CoopPlots.CoopPlot_1:FindFirstChild("ProximityPrompt"),
    BikeMount = Workspace:FindFirstChild("Seat") and Workspace.Seat:FindFirstChild("BikeMountPrompt"),
}

--====================================================
-- SETTINGS
--====================================================
local Settings = {
    AutoFarm = false,
    AutoSell = false,
    AutoBuy  = false,
    AutoPlant = false,
    AutoHarvest = false,
    LightningProtection = true,
    AntiAFK  = true,
}

local SeedName = "Bibit Padi"
local JumlahBeli = 1
local LahanList = {}
local LahanPos = nil

--====================================================
-- UTILITY FUNCTIONS
--====================================================
local function notif(judul, isi, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = judul,
            Text = isi,
            Duration = dur or 3
        })
    end)
end

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPos()
    local r = getRoot()
    return r and r.Position
end

local function tp(obj)
    if not obj then return false end
    local root = getRoot()
    if not root then return false end
    
    local pos
    if obj:IsA("BasePart") then
        pos = obj.Position
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            pos = obj.PrimaryPart.Position
        elseif obj:FindFirstChild("HumanoidRootPart") then
            pos = obj.HumanoidRootPart.Position
        elseif obj:FindFirstChild("Head") then
            pos = obj.Head.Position
        end
    end
    
    if not pos then return false end
    root.CFrame = CFrame.new(pos.X, pos.Y+5, pos.Z)
    task.wait(0.3)
    return true
end

--====================================================
-- FUNGSI INTERAKSI PROXIMITY PROMPT (PASTI JALAN!)
--====================================================
local function firePrompt(prompt)
    if not prompt then return false end
    
    -- Method 1: fireproximityprompt (built-in)
    local success = pcall(function()
        fireproximityprompt(prompt)
    end)
    
    -- Method 2: Simulasi tekan E
    if not success then
        pcall(function()
            VirtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.1)
            VirtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
    end
    
    return true
end

--====================================================
-- FUNGSI INTERAKSI NPC
--====================================================
local function interactNPC(nama)
    local prompt = PROMPTS[nama]
    if not prompt then
        notif("Error", "Prompt "..nama.." tidak ditemukan", 3)
        return false
    end
    
    -- Cari parent object untuk teleport
    local parent = prompt.Parent
    if parent then
        tp(parent)
        task.wait(1)
        firePrompt(prompt)
        notif("Interaksi", "Dengan "..nama, 2)
        return true
    end
    return false
end

--====================================================
-- REMOTE FUNCTIONS
--====================================================

-- Plant Crop (Tanam)
local function PlantCrop(posisi)
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("PlantCrop") then
        return false
    end
    
    if not posisi then
        local root = getRoot()
        if not root then return false end
        posisi = root.Position
    end
    
    pcall(function()
        TutorialRemotes.PlantCrop:FireServer(posisi)
    end)
    return true
end

-- Harvest Crop (Panen)
local function HarvestCrop(jenis, jumlah)
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("HarvestCrop") then
        return false
    end
    
    jenis = jenis or "Padi"
    jumlah = jumlah or 1
    
    pcall(function()
        TutorialRemotes.HarvestCrop:FireServer(jenis, jumlah, jenis)
    end)
    return true
end

-- Request Lahan Data
local function RequestLahan()
    if not TutorialRemotes or not TutorialRemotes:FindFirstChild("RequestLahan") then
        return nil
    end
    
    local success, result = pcall(function()
        return TutorialRemotes.RequestLahan:InvokeServer(ClientBoot)
    end)
    
    return success and result
end

--====================================================
-- SCAN LAHAN DARI REQUESTLAHAN
--====================================================
local function ScanLahan()
    local data = RequestLahan()
    if not data or not data.Success then
        notif("Gagal", "Tidak bisa ambil data lahan", 3)
        return
    end
    
    LahanList = {}
    for lahanName, _ in pairs(data.Statuses or {}) do
        local obj = Workspace:FindFirstChild(lahanName)
        if obj and obj:IsA("BasePart") then
            table.insert(LahanList, obj)
        end
    end
    
    notif("Scan Lahan", string.format("%d lahan ditemukan", #LahanList), 3)
    return LahanList
end

--====================================================
-- AUTO TANAM
--====================================================
local function AutoPlantAll()
    if #LahanList == 0 then ScanLahan() end
    
    local count = 0
    for _, lahan in ipairs(LahanList) do
        if lahan:IsA("BasePart") then
            PlantCrop(lahan.Position)
            count = count + 1
            task.wait(0.2)
        end
    end
    notif("Auto Plant", "Menanam di "..count.." lahan", 3)
end

--====================================================
-- TABS
--====================================================
local MainTab     = Window:CreateTab("🌾 Main", 4483362458)
local InteractTab = Window:CreateTab("🤝 Interaksi", 4483362458)
local TeleportTab = Window:CreateTab("📍 Teleport", 4483362458)

--====================================================
-- 🌾 MAIN TAB
--====================================================
MainTab:CreateSection("🌱 Farming")

MainTab:CreateButton({
    Name = "🔍 Scan Lahan",
    Callback = ScanLahan
})

MainTab:CreateButton({
    Name = "🌱 Tanam di Semua Lahan",
    Callback = AutoPlantAll
})

MainTab:CreateButton({
    Name = "🌽 Panen Padi",
    Callback = function() HarvestCrop("Padi", 1) end
})

MainTab:CreateButton({
    Name = "🌽 Panen Jagung",
    Callback = function() HarvestCrop("Jagung", 1) end
})

MainTab:CreateButton({
    Name = "🌽 Panen Tomat",
    Callback = function() HarvestCrop("Tomat", 1) end
})

MainTab:CreateButton({
    Name = "🌽 Panen Sawit",
    Callback = function() HarvestCrop("Sawit", 1) end
})

--====================================================
-- 🤝 INTERAKSI TAB (FITUR BARU!)
--====================================================
InteractTab:CreateSection("🤝 Interaksi NPC via ProximityPrompt")

InteractTab:CreateButton({
    Name = "🌱 NPC Bibit (Beli)",
    Callback = function() interactNPC("Bibit") end
})

InteractTab:CreateButton({
    Name = "🔧 NPC Alat (Beli Tools)",
    Callback = function() interactNPC("Alat") end
})

InteractTab:CreateButton({
    Name = "🌴 NPC Pedagang Sawit",
    Callback = function() interactNPC("Sawit") end
})

InteractTab:CreateButton({
    Name = "🥚 NPC Pedagang Telur",
    Callback = function() interactNPC("Telur") end
})

InteractTab:CreateSection("🏞 Lahan Kerjasama")

InteractTab:CreateButton({
    Name = "🤝 Coop Plot 1",
    Callback = function()
        if PROMPTS.CoopPlot then
            tp(PROMPTS.CoopPlot.Parent)
            task.wait(1)
            firePrompt(PROMPTS.CoopPlot)
        end
    end
})

InteractTab:CreateSection("🚲 Kendaraan")

InteractTab:CreateButton({
    Name = "🚲 Naik Sepeda",
    Callback = function()
        if PROMPTS.BikeMount then
            tp(PROMPTS.BikeMount.Parent)
            task.wait(1)
            firePrompt(PROMPTS.BikeMount)
        end
    end
})

--====================================================
-- 📍 TELEPORT TAB
--====================================================
TeleportTab:CreateSection("🏪 Teleport ke NPC")

TeleportTab:CreateButton({
    Name = "🌱 NPC Bibit",
    Callback = function()
        if PROMPTS.Bibit then tp(PROMPTS.Bibit.Parent) end
    end
})

TeleportTab:CreateButton({
    Name = "🔧 NPC Alat",
    Callback = function()
        if PROMPTS.Alat then tp(PROMPTS.Alat.Parent) end
    end
})

TeleportTab:CreateButton({
    Name = "🌴 NPC Sawit",
    Callback = function()
        if PROMPTS.Sawit then tp(PROMPTS.Sawit.Parent) end
    end
})

TeleportTab:CreateButton({
    Name = "🥚 NPC Telur",
    Callback = function()
        if PROMPTS.Telur then tp(PROMPTS.Telur.Parent) end
    end
})

TeleportTab:CreateButton({
    Name = "📍 Simpan Posisi Lahan",
    Callback = function()
        LahanPos = getPos()
        notif("Posisi tersimpan", "", 2)
    end
})

TeleportTab:CreateButton({
    Name = "🌾 Teleport ke Lahan",
    Callback = function()
        if LahanPos and getRoot() then
            getRoot().CFrame = CFrame.new(LahanPos.X, LahanPos.Y+5, LahanPos.Z)
        end
    end
})

--====================================================
-- ANTI AFK
--====================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

--====================================================
-- INIT
--====================================================
notif("🌾 XKID HUB v4.0", "ProximityPrompt Edition Loaded! 🔥", 4)

print("=== XKID HUB v4.0 ===")
print("✅ ProximityPrompt ditemukan:")
for nama, prompt in pairs(PROMPTS) do
    if prompt then
        print("   - " .. nama .. ": ✅")
    else
        print("   - " .. nama .. ": ❌")
    end
end
