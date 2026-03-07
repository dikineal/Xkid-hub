-- SCRIPT SAWAH INDO v3.0 - AUTO FARM PROXIMITY PROMPT
-- Support: Android + Delta Executor
-- Sistem: ProximityPrompt trigger otomatis

local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not ok or not Rayfield then
    warn("❌ Gagal load Rayfield.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO BY:XKID ",
    LoadingTitle = "SAWAH INDO",
    LoadingSubtitle = "Auto Farm ProximityPrompt Edition",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- ========== SERVICES ==========
local Players       = game:GetService("Players")
local LocalPlayer   = Players.LocalPlayer

-- ========== FLAGS ==========
_G.AutoFarm    = false
_G.AutoJual    = false
_G.AutoBeli    = false
_G.StopAll     = false

-- ========== UTILITY ==========
local function notify(title, content, duration)
    pcall(function()
        Rayfield:Notify({
            Title    = title,
            Content  = content,
            Duration = duration or 3,
            Image    = 4483362458
        })
    end)
    print("[SAWAH] " .. title .. ": " .. content)
end

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Teleport ke posisi
local function teleportTo(obj)
    local root = getRoot()
    if not root or not obj then return false end
    local pos
    if obj:IsA("BasePart") then
        pos = obj.Position
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then pos = obj.PrimaryPart.Position
        elseif obj:FindFirstChild("HumanoidRootPart") then pos = obj.HumanoidRootPart.Position
        elseif obj:FindFirstChild("Head") then pos = obj.Head.Position
        end
    end
    if not pos then return false end
    root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    return true
end

-- Cari object by nama (case-insensitive)
local function findObj(name)
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower() == name:lower() then return v end
    end
    return nil
end

-- ========== CORE: TRIGGER PROXIMITY PROMPT ==========
-- Cara paling andal trigger ProximityPrompt tanpa tap layar
local function fireProximityPrompt(prompt)
    -- Method 1: FireProximityPrompt (executor method, Delta support)
    local ok1 = pcall(function()
        fireclickdetector(prompt)
    end)
    -- Method 2: Trigger langsung via internal
    local ok2 = pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    -- Method 3: Fire ProximityPrompt Triggered langsung
    local ok3 = pcall(function()
        local PP = game:GetService("ProximityPromptService")
        PP:PromptTriggered(prompt, LocalPlayer)
    end)
    -- Method 4: Paling reliable - fire remote prompt
    pcall(function()
        fireproximityprompt(prompt)
    end)
end

-- Cari semua ProximityPrompt di dalam object/model
local function getPrompts(obj)
    local prompts = {}
    if not obj then return prompts end
    -- Cari di parent model juga
    local target = obj
    if obj:IsA("BasePart") then
        target = obj.Parent or obj
    end
    for _, v in pairs(target:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            table.insert(prompts, v)
        end
    end
    -- Cek di object itu sendiri juga
    if obj:IsA("ProximityPrompt") then
        table.insert(prompts, obj)
    end
    return prompts
end

-- Teleport ke NPC lalu trigger semua prompt-nya
local function interactWithNPC(npcName, waitTime)
    waitTime = waitTime or 2
    local obj = findObj(npcName)
    if not obj then
        notify("❌", npcName .. " tidak ditemukan!", 3)
        return false
    end

    -- Teleport deket NPC
    teleportTo(obj)
    task.wait(waitTime)

    -- Cari & trigger ProximityPrompt
    local prompts = getPrompts(obj)
    if #prompts == 0 then
        -- Coba cari di sekitar posisi NPC (radius 10 stud)
        local root = getRoot()
        if root then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    local pp = v.Parent
                    if pp and pp:IsA("BasePart") then
                        if (pp.Position - root.Position).Magnitude < 15 then
                            table.insert(prompts, v)
                        end
                    end
                end
            end
        end
    end

    if #prompts > 0 then
        for _, prompt in ipairs(prompts) do
            fireProximityPrompt(prompt)
            task.wait(0.5)
        end
        print("✅ Interaksi dengan " .. npcName .. " (" .. #prompts .. " prompt)")
        return true
    else
        -- Fallback: kirim keypress E
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.3)
            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
        print("⚠️ Prompt tidak ditemukan di " .. npcName .. ", coba keypress E")
        return false
    end
end

-- Interact dengan lahan (Tanah)
local function interactWithLahan(lahanObj, waitTime)
    waitTime = waitTime or 1.5
    if not lahanObj then return false end
    teleportTo(lahanObj)
    task.wait(waitTime)

    local prompts = getPrompts(lahanObj)

    -- Cari juga di sekitar posisi lahan
    if #prompts == 0 then
        local root = getRoot()
        if root then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    local pp = v.Parent
                    if pp and pp:IsA("BasePart") then
                        if (pp.Position - root.Position).Magnitude < 10 then
                            table.insert(prompts, v)
                        end
                    end
                end
            end
        end
    end

    if #prompts > 0 then
        for _, prompt in ipairs(prompts) do
            fireProximityPrompt(prompt)
            task.wait(0.5)
        end
        return true
    else
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.3)
            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
        return false
    end
end

-- ========== KUMPULKAN SEMUA LAHAN ==========
local function getAllLahan()
    local lahans = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Tanah" and obj:IsA("BasePart") then
            table.insert(lahans, obj)
        end
    end
    return lahans
end

-- ========== TABS ==========
local TeleportTab = Window:CreateTab("📍 TELEPORT", nil)
local AutoTab     = Window:CreateTab("🤖 AUTO FARM", nil)
local ScanTab     = Window:CreateTab("🔍 SCAN", nil)
local ToolTab     = Window:CreateTab("🛠 TOOLS", nil)

-- ========== TELEPORT TAB ==========
TeleportTab:CreateSection("Teleport NPC")

local npcList = {
    { icon = "🛒", name = "NPC BIBIT"          },
    { icon = "💰", name = "NPC PENJUAL"         },
    { icon = "🔧", name = "NPC ALAT"            },
    { icon = "🥚", name = "NPC PEDAGANG TELUR"   },
    { icon = "🌴", name = "NPC PEDAGANG SAWIT"   },
}

for _, npc in ipairs(npcList) do
    TeleportTab:CreateButton({
        Name = npc.icon .. " Teleport → " .. npc.name,
        Callback = function()
            local obj = findObj(npc.name)
            if obj then
                teleportTo(obj)
                notify("📍", "Teleport ke " .. npc.name, 2)
            else
                notify("❌", npc.name .. " tidak ditemukan", 3)
            end
        end
    })
end

TeleportTab:CreateSection("Teleport Lahan")

TeleportTab:CreateButton({
    Name = "🌾 Teleport ke Lahan Pertama",
    Callback = function()
        local lahans = getAllLahan()
        if #lahans > 0 then
            teleportTo(lahans[1])
            notify("📍", "Teleport ke lahan pertama", 2)
        else
            notify("❌", "Lahan tidak ditemukan", 3)
        end
    end
})

-- ========== AUTO FARM TAB ==========
AutoTab:CreateSection("⚙ Pengaturan Delay")

local delayBeli  = 2
local delayTanam = 1.5
local delayJual  = 2

AutoTab:CreateSlider({
    Name = "⏱ Delay Beli Bibit (detik)",
    Range = {1, 6},
    Increment = 0.5,
    CurrentValue = 2,
    Callback = function(v) delayBeli = v end
})

AutoTab:CreateSlider({
    Name = "⏱ Delay Tanam per Lahan (detik)",
    Range = {1, 5},
    Increment = 0.5,
    CurrentValue = 1.5,
    Callback = function(v) delayTanam = v end
})

AutoTab:CreateSlider({
    Name = "⏱ Delay Jual (detik)",
    Range = {1, 6},
    Increment = 0.5,
    CurrentValue = 2,
    Callback = function(v) delayJual = v end
})

AutoTab:CreateSection("🤖 Auto Farm Lengkap")

AutoTab:CreateToggle({
    Name = "🌾 AUTO FARM (Beli → Tanam → Jual)",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoFarm = v
        _G.StopAll  = not v
        if v then
            notify("✅ AUTO FARM", "Dimulai! Beli → Tanam → Jual", 4)
            task.spawn(function()
                local cycle = 0
                while _G.AutoFarm do
                    cycle = cycle + 1
                    print("🔄 Siklus Auto Farm #" .. cycle)

                    -- STEP 1: Beli bibit
                    print("  [1/3] Beli bibit...")
                    interactWithNPC("npcbibit", delayBeli)
                    task.wait(delayBeli)

                    if not _G.AutoFarm then break end

                    -- STEP 2: Tanam di semua lahan
                    print("  [2/3] Tanam di lahan...")
                    local lahans = getAllLahan()
                    local tanam = 0
                    for _, lahan in ipairs(lahans) do
                        if not _G.AutoFarm then break end
                        if interactWithLahan(lahan, delayTanam) then
                            tanam = tanam + 1
                        end
                        task.wait(0.3)
                    end
                    print("  ✅ Tanam selesai di " .. tanam .. " lahan")

                    if not _G.AutoFarm then break end

                    -- STEP 3: Tunggu panen (opsional, bisa ubah waktu tunggu)
                    print("  ⏳ Tunggu panen 5 detik...")
                    task.wait(5)

                    if not _G.AutoFarm then break end

                    -- STEP 4: Jual hasil
                    print("  [3/3] Jual hasil...")
                    interactWithNPC("npcpenjual", delayJual)
                    task.wait(delayJual)

                    print("  ✅ Siklus #" .. cycle .. " selesai!")
                    task.wait(1)
                end
                notify("⛔ AUTO FARM", "Dihentikan", 2)
            end)
        else
            _G.StopAll = true
            notify("⛔ AUTO FARM", "Dimatikan", 2)
        end
    end
})

AutoTab:CreateSection("Auto Terpisah")

AutoTab:CreateToggle({
    Name = "🛒 Auto Beli Bibit Saja",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoBeli = v
        if v then
            task.spawn(function()
                while _G.AutoBeli do
                    interactWithNPC("npcbibit", delayBeli)
                    task.wait(delayBeli + 1)
                end
            end)
            notify("✅ Auto Beli", "Loop beli bibit aktif", 3)
        else
            notify("⛔ Auto Beli", "Dimatikan", 2)
        end
    end
})

AutoTab:CreateToggle({
    Name = "💰 Auto Jual Saja",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoJual = v
        if v then
            task.spawn(function()
                while _G.AutoJual do
                    interactWithNPC("npcpenjual", delayJual)
                    task.wait(delayJual + 1)
                end
            end)
            notify("✅ Auto Jual", "Loop jual aktif", 3)
        else
            notify("⛔ Auto Jual", "Dimatikan", 2)
        end
    end
})

AutoTab:CreateToggle({
    Name = "🌱 Auto Tanam Semua Lahan",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoTanam = v
        if v then
            task.spawn(function()
                while _G.AutoTanam do
                    local lahans = getAllLahan()
                    for _, lahan in ipairs(lahans) do
                        if not _G.AutoTanam then break end
                        interactWithLahan(lahan, delayTanam)
                    end
                    task.wait(3)
                end
            end)
            notify("✅ Auto Tanam", "Loop tanam semua lahan aktif", 3)
        else
            notify("⛔ Auto Tanam", "Dimatikan", 2)
        end
    end
})

AutoTab:CreateSection("Kontrol")

AutoTab:CreateButton({
    Name = "⛔ STOP SEMUA AUTO",
    Callback = function()
        _G.AutoFarm  = false
        _G.AutoJual  = false
        _G.AutoBeli  = false
        _G.AutoTanam = false
        _G.StopAll   = true
        notify("⛔ STOP", "Semua auto dimatikan!", 3)
    end
})

-- ========== SCAN TAB ==========
ScanTab:CreateSection("Scan ProximityPrompt")

ScanTab:CreateButton({
    Name = "🔍 Scan Semua ProximityPrompt",
    Callback = function()
        local count = 0
        local found = {}
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                count = count + 1
                local info = v:GetFullName() .. " | Action: " .. v.ActionText
                table.insert(found, info)
                print(info)
            end
        end
        notify("🔍 Scan PP", "Ditemukan " .. count .. " ProximityPrompt (cek console F9)", 5)
    end
})

ScanTab:CreateButton({
    Name = "🔍 Scan NPC di Map",
    Callback = function()
        local found = {}
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
                if not found[v.Name] then
                    found[v.Name] = true
                    print("NPC: " .. v.Name .. " | Path: " .. v:GetFullName())
                end
            end
        end
        notify("🔍 Scan NPC", "Selesai! Cek console (F9)", 4)
    end
})

ScanTab:CreateButton({
    Name = "🔍 Scan RemoteEvent",
    Callback = function()
        local RS = game:GetService("ReplicatedStorage")
        local count = 0
        for _, v in pairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                count = count + 1
                print(v.ClassName .. ": " .. v:GetFullName())
            end
        end
        notify("🔍 Remote", "Ditemukan " .. count .. " remote (cek console)", 4)
    end
})

ScanTab:CreateButton({
    Name = "🔍 Scan Lahan (Tanah)",
    Callback = function()
        local lahans = getAllLahan()
        notify("🌾 Lahan", "Ditemukan " .. #lahans .. " lahan Tanah", 4)
        print("Total lahan Tanah: " .. #lahans)
    end
})

-- ========== TOOLS TAB ==========
ToolTab:CreateSection("Utilitas")

ToolTab:CreateButton({
    Name = "📍 Posisi Saya",
    Callback = function()
        local root = getRoot()
        if root then
            local p = root.Position
            notify("📍 Posisi", string.format("X=%.1f Y=%.1f Z=%.1f", p.X, p.Y, p.Z), 5)
        end
    end
})

ToolTab:CreateButton({
    Name = "🔄 Reset Character",
    Callback = function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
})

ToolTab:CreateButton({
    Name = "🧪 Test Trigger E (Posisi Ini)",
    Callback = function()
        -- Cari PP terdekat dan fire
        local root = getRoot()
        if not root then return end
        local nearest, dist = nil, 20
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                local pp = v.Parent
                if pp and pp:IsA("BasePart") then
                    local d = (pp.Position - root.Position).Magnitude
                    if d < dist then
                        nearest = v
                        dist = d
                    end
                end
            end
        end
        if nearest then
            fireProximityPrompt(nearest)
            notify("🧪 Test", "Trigger PP terdekat: " .. nearest:GetFullName(), 3)
        else
            notify("⚠️ Test", "Tidak ada PP dalam radius 20 stud", 3)
        end
    end
})

-- ========== INIT ==========
print("╔══════════════════════════════════╗")
print("║  🌾 SAWAH INDO v3.0 AUTO FARM    ║")
print("║  ProximityPrompt Edition          ║")
print("║  Support: Android + Delta         ║")
print("╚══════════════════════════════════╝")

notify("🌾 SAWAH INDO v3.0", "Script siap! Auto Farm ProximityPrompt aktif.", 5)
