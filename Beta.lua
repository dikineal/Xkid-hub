-- 🌾 SAWAH INDO v5.1 — XKID HUB
-- github.com/dikineal/Xkid-hub
-- Support: Android + Delta Executor

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO v5.1 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "auto cuan, no cap 🔥",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local myName = LocalPlayer.Name

_G.AutoFarm = false
_G.AutoBeli = false
_G.AutoTanam = false
_G.AutoJual = false

local lahanOwnerAttr = nil
local lahanNamaObj = nil

local function notif(judul, isi, dur)
    pcall(function()
        Rayfield:Notify({Title=judul, Content=isi, Duration=dur or 3, Image=4483362458})
    end)
    print("[XKID] "..judul.." - "..isi)
end

local function getRoot()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char and char:WaitForChild("HumanoidRootPart", 3)
end

local function tp(obj)
    if not obj then return false end
    local root = getRoot()
    if not root then return false end
    local pos
    if obj:IsA("BasePart") then
        pos = obj.Position
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then pos = obj.PrimaryPart.Position
        elseif obj:FindFirstChild("HumanoidRootPart") then pos = obj.HumanoidRootPart.Position
        elseif obj:FindFirstChild("Head") then pos = obj.Head.Position end
    end
    if not pos then return false end
    root.CFrame = CFrame.new(pos.X, pos.Y + 4, pos.Z)
    task.wait(0.5)
    return true
end

local function cari(nama)
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower() == nama:lower() then return v end
    end
    return nil
end

local function scanLahan()
    local keywords = {"tanah","lahan","plot","farm","sawah"}
    local attrList = {"Owner","owner","PlayerName","Username","username","Player","OwnedBy"}
    for _, v in pairs(workspace:GetDescendants()) do
        local namaLower = v.Name:lower()
        local isLahan = false
        for i = 1, #keywords do
            if namaLower:find(keywords[i]) then isLahan = true; break end
        end
        if isLahan and (v:IsA("BasePart") or v:IsA("Model")) then
            for i = 1, #attrList do
                local val = v:GetAttribute(attrList[i])
                if val and tostring(val):lower() == myName:lower() then
                    lahanOwnerAttr = attrList[i]
                    lahanNamaObj = v.Name
                    return true
                end
            end
            if v.Name:lower():find(myName:lower()) then
                lahanNamaObj = v.Name
                return true
            end
        end
    end
    return false
end

local function getAllLahan()
    local lahans = {}
    if lahanNamaObj then
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == lahanNamaObj and (v:IsA("BasePart") or v:IsA("Model")) then
                if lahanOwnerAttr then
                    local val = v:GetAttribute(lahanOwnerAttr)
                    if val and tostring(val):lower() == myName:lower() then
                        lahans[#lahans+1] = v
                    end
                else
                    lahans[#lahans+1] = v
                end
            end
        end
    end
    if #lahans == 0 then
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "Tanah" and v:IsA("BasePart") then
                lahans[#lahans+1] = v
            end
        end
    end
    return lahans
end

local function klikBeli(tombol)
    if not tombol then return false end
    pcall(function() tombol.MouseButton1Click:Fire() end)
    task.wait(0.05)
    pcall(function()
        local p = tombol.AbsolutePosition + (tombol.AbsoluteSize / 2)
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
    end)
    task.wait(0.1)
    return true
end

local function getPPDekat(radius)
    radius = radius or 15
    local root = getRoot()
    if not root then return nil end
    local best, bestD = nil, radius
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local par = v.Parent
            if par and par:IsA("BasePart") then
                local d = (par.Position - root.Position).Magnitude
                if d < bestD then best = v; bestD = d end
            end
        end
    end
    return best
end

local function firePrompt(prompt)
    if not prompt then return end
    pcall(function() fireproximityprompt(prompt) end)
    task.wait(0.15)
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.15)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

local function bukaToko(npcName, delay)
    local npc = cari(npcName)
    if not npc then notif("NPC", npcName.." kagak ketemu!", 3); return false end
    tp(npc)
    task.wait(0.8)
    local prompt = nil
    local searchIn = npc:IsA("Model") and npc or (npc.Parent or npc)
    for _, v in pairs(searchIn:GetDescendants()) do
        if v:IsA("ProximityPrompt") then prompt = v; break end
    end
    if not prompt then prompt = getPPDekat(15) end
    if not prompt then notif("PP", "ProximityPrompt kagak ketemu!", 3); return false end
    firePrompt(prompt)
    task.wait(delay or 1.5)
    return true
end

local selectedBibit = "Padi"
local jumlahBeli = 1

local function autoBeliBibit()
    if not bukaToko("npcbibit", 1.5) then return false end
    if jumlahBeli > 1 then
        local gui = LocalPlayer.PlayerGui
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and v.Text == "+" and v.Visible then
                for i = 1, jumlahBeli - 1 do klikBeli(v); task.wait(0.08) end
                break
            end
        end
        task.wait(0.2)
    end
    local gui = LocalPlayer.PlayerGui
    local berhasil = false
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and (v.Text:lower() == "beli" or v.Text:lower() == "buy") and v.Visible then
            klikBeli(v); berhasil = true; break
        end
    end
    task.wait(0.5)
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and (v.Text:lower() == "tutup" or v.Text:lower() == "close") and v.Visible then
            klikBeli(v); break
        end
    end
    return berhasil
end

local function autoJual()
    if not bukaToko("npcpenjual", 1.5) then return false end
    local gui = LocalPlayer.PlayerGui
    task.wait(0.3)
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local t = v.Text:lower()
            if (t:find("jual") or t:find("sell")) and not t:find("tutup") then
                klikBeli(v); task.wait(0.2)
            end
        end
    end
    task.wait(0.3)
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and (v.Text:lower() == "tutup" or v.Text:lower() == "close") and v.Visible then
            klikBeli(v); break
        end
    end
    return true
end

local function interakLahan(lahanObj, delay)
    delay = delay or 1.5
    if not lahanObj then return false end
    tp(lahanObj)
    task.wait(delay)
    local prompt = getPPDekat(10)
    if prompt then firePrompt(prompt) end
    task.wait(0.3)
    local gui = LocalPlayer.PlayerGui
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local t = v.Text:lower()
            if t:find("tanam") or t:find("plant") then klikBeli(v); break end
        end
    end
    return true
end

local BIBIT = {
    {name="Padi",       emoji="⚡", minLv=1,   harga=5},
    {name="Jagung",     emoji="🌽", minLv=20,  harga=15},
    {name="Tomat",      emoji="🍅", minLv=40,  harga=25},
    {name="Terong",     emoji="🍆", minLv=60,  harga=40},
    {name="Strawberry", emoji="🍓", minLv=80,  harga=60},
    {name="Sawit",      emoji="🌴", minLv=80,  harga=1000},
    {name="Durian",     emoji="🟢", minLv=120, harga=2000},
}

-- TABS
local TabBibit = Window:CreateTab("🛒 Beli Bibit", nil)
local TabFarm  = Window:CreateTab("🤖 Auto Farm",  nil)
local TabTP    = Window:CreateTab("📍 Teleport",   nil)
local TabScan  = Window:CreateTab("🔍 Scan",       nil)
local TabTools = Window:CreateTab("🛠 Tools",      nil)

-- ==================== BAGIAN 2 ====================
-- Sambung di bawah Bagian 1

-- TAB BELI BIBIT
TabBibit:CreateSection("🌱 Pilih Bibit")
local opsi = {}
for _, b in ipairs(BIBIT) do
    opsi[#opsi+1] = b.emoji.." "..b.name.." | Lv."..b.minLv.." | "..b.harga.."/bibit"
end
TabBibit:CreateDropdown({
    Name = "🌱 Pilih Jenis Bibit",
    Options = opsi,
    CurrentOption = {opsi[1]},
    Callback = function(v)
        for _, b in ipairs(BIBIT) do
            if v[1]:find(b.name) then
                selectedBibit = b.name
                notif("Dipilih", b.emoji.." "..b.name, 2)
                break
            end
        end
    end
})
TabBibit:CreateSlider({
    Name = "🔢 Jumlah Beli",
    Range = {1, 50}, Increment = 1, CurrentValue = 1,
    Callback = function(v) jumlahBeli = v end
})
TabBibit:CreateSection("🚀 Aksi Beli")
TabBibit:CreateButton({
    Name = "🛒 BELI SEKARANG",
    Callback = function()
        task.spawn(function()
            notif("Beli", "Gas beli "..jumlahBeli.."x "..selectedBibit.."!", 2)
            if autoBeliBibit() then
                notif("Berhasil!", jumlahBeli.."x "..selectedBibit.." sukses 🎉", 3)
            end
        end)
    end
})
TabBibit:CreateSection("⚡ Beli Cepat")
for _, b in ipairs(BIBIT) do
    TabBibit:CreateButton({
        Name = b.emoji.." "..b.name.." | Lv."..b.minLv.." | "..b.harga.." coin",
        Callback = function()
            task.spawn(function()
                selectedBibit = b.name
                notif("Beli", "Gas "..jumlahBeli.."x "..b.name.."!", 2)
                autoBeliBibit()
            end)
        end
    })
end
TabBibit:CreateSection("🔁 Auto Beli Loop")
local autoBibitDelay = 3
TabBibit:CreateSlider({
    Name = "⏱ Delay Auto Beli (detik)",
    Range = {2, 15}, Increment = 1, CurrentValue = 3,
    Callback = function(v) autoBibitDelay = v end
})
TabBibit:CreateToggle({
    Name = "🔁 Auto Beli Terus",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoBeli = v
        if v then
            notif("Auto Beli ON", "Loop beli "..selectedBibit.."~", 3)
            task.spawn(function()
                while _G.AutoBeli do
                    autoBeliBibit()
                    task.wait(autoBibitDelay)
                end
            end)
        else notif("Auto Beli", "Off", 2) end
    end
})

-- TAB AUTO FARM
TabFarm:CreateSection("⚙ Setting Delay")
local dBeli = 1.2
local dTanam = 1.5
local dJual = 2
local dPanen = 10
TabFarm:CreateSlider({Name="⏱ Delay Beli",   Range={1,6},  Increment=0.5, CurrentValue=1.2, Callback=function(v) dBeli=v  end})
TabFarm:CreateSlider({Name="⏱ Delay Tanam",  Range={1,5},  Increment=0.5, CurrentValue=1.5, Callback=function(v) dTanam=v end})
TabFarm:CreateSlider({Name="⏱ Delay Jual",   Range={1,6},  Increment=0.5, CurrentValue=2,   Callback=function(v) dJual=v  end})
TabFarm:CreateSlider({Name="⏳ Tunggu Panen", Range={3,60}, Increment=1,   CurrentValue=10,  Callback=function(v) dPanen=v end})
TabFarm:CreateSection("🤖 Auto Farm Full")
TabFarm:CreateToggle({
    Name = "🌾 AUTO FARM — Beli > Tanam > Panen > Jual",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoFarm = v
        if v then
            notif("AUTO FARM ON", "Gas brooo! Cuan incoming 💸", 4)
            task.spawn(function()
                local siklus = 0
                while _G.AutoFarm do
                    siklus = siklus + 1
                    print("SIKLUS #"..siklus)
                    autoBeliBibit()
                    if not _G.AutoFarm then break end
                    task.wait(0.5)
                    local lahans = getAllLahan()
                    local ok2 = 0
                    for i, lahan in ipairs(lahans) do
                        if not _G.AutoFarm then break end
                        if interakLahan(lahan, dTanam) then ok2 = ok2 + 1 end
                        task.wait(0.2)
                    end
                    print("Tanam "..ok2.."/"..#lahans)
                    if not _G.AutoFarm then break end
                    notif("Nunggu Panen", dPanen.."s...", dPanen)
                    task.wait(dPanen)
                    if not _G.AutoFarm then break end
                    autoJual()
                    task.wait(0.5)
                    notif("Siklus #"..siklus, "Done! Loop lagi 🔁", 3)
                    task.wait(1)
                end
                notif("AUTO FARM", "Distop 😴", 3)
            end)
        else notif("AUTO FARM", "Off!", 2) end
    end
})
TabFarm:CreateSection("🎛 Auto Satuan")
TabFarm:CreateToggle({
    Name = "🌱 Auto Tanam Lahan Sendiri",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoTanam = v
        if v then
            task.spawn(function()
                while _G.AutoTanam do
                    local lahans = getAllLahan()
                    for _, lahan in ipairs(lahans) do
                        if not _G.AutoTanam then break end
                        interakLahan(lahan, dTanam)
                    end
                    task.wait(3)
                end
            end)
            notif("Auto Tanam ON", "Loop tanam lahan sendiri~", 3)
        else notif("Auto Tanam", "Off", 2) end
    end
})
TabFarm:CreateToggle({
    Name = "💰 Auto Jual Aja",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoJual = v
        if v then
            task.spawn(function()
                while _G.AutoJual do autoJual(); task.wait(dJual+1) end
            end)
            notif("Auto Jual ON", "Selling machine 🤑", 3)
        else notif("Auto Jual", "Off", 2) end
    end
})
TabFarm:CreateSection("🔴 Kill Switch")
TabFarm:CreateButton({
    Name = "⛔ STOP SEMUA",
    Callback = function()
        _G.AutoFarm=false; _G.AutoBeli=false; _G.AutoTanam=false; _G.AutoJual=false
        notif("STOP", "Semua auto dimatiin!", 3)
    end
})

-- TAB TELEPORT
TabTP:CreateSection("NPC")
local npcList = {
    {icon="🛒", name="npcbibit",         label="Beli Bibit"},
    {icon="💰", name="npcpenjual",        label="Jual Hasil"},
    {icon="🔧", name="npcalat",           label="Beli Alat"},
    {icon="🥚", name="NPCPedagangTelur",  label="Jual Telur"},
    {icon="🌴", name="NPCPedagangSawit",  label="Jual Sawit"},
}
for _, npc in ipairs(npcList) do
    TabTP:CreateButton({
        Name = npc.icon.." "..npc.name.." - "..npc.label,
        Callback = function()
            local o = cari(npc.name)
            if o then tp(o); notif("Teleport", npc.name.." OK", 2)
            else notif("Error", npc.name.." kagak ada", 3) end
        end
    })
end
TabTP:CreateSection("Lahan")
TabTP:CreateButton({
    Name = "🌾 Teleport ke Lahan Kamu",
    Callback = function()
        local lahans = getAllLahan()
        if #lahans > 0 then tp(lahans[1]); notif("Teleport", "Di lahan kamu!", 2)
        else notif("Error", "Scan lahan dulu!", 3) end
    end
})

-- TAB SCAN
TabScan:CreateSection("Scan Lahan Milik Kamu")
TabScan:CreateLabel("Berdiri di LAHAN KAMU dulu sebelum scan!")
TabScan:CreateButton({
    Name = "🔍 SCAN LAHAN SEKARANG",
    Callback = function()
        notif("Scanning...", "Nyari lahan milik "..myName.."...", 3)
        task.spawn(function()
            local found = scanLahan()
            if found then
                notif("Ketemu!", "Lahan: "..(lahanNamaObj or "?").." siap! Auto Farm hanya ke lahan kamu 🎉", 6)
            else
                notif("Belum Ketemu", "Jalan ke lahan kamu dulu lalu scan lagi!", 6)
            end
        end)
    end
})
TabScan:CreateButton({
    Name = "📋 Lihat Hasil Scan",
    Callback = function()
        notif("Hasil Scan", "Lahan: "..(lahanNamaObj or "belum scan").." | Attr: "..(lahanOwnerAttr or "-"), 6)
    end
})
TabScan:CreateButton({
    Name = "🌾 Hitung Lahan Kamu",
    Callback = function()
        notif("Lahan", #getAllLahan().." lahan ditemukan", 4)
    end
})
TabScan:CreateButton({
    Name = "🔍 Scan ProximityPrompt",
    Callback = function()
        local n = 0
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                n = n + 1
                print("PP: ["..v.ActionText.."] "..v:GetFullName())
            end
        end
        notif("Scan PP", n.." ProximityPrompt ketemu!", 4)
    end
})

-- TAB TOOLS
TabTools:CreateSection("Utilitas")
TabTools:CreateButton({
    Name = "📍 Koordinat Gue",
    Callback = function()
        local r = getRoot()
        if r then
            local p = r.Position
            notif("Posisi", ("X=%.1f Y=%.1f Z=%.1f"):format(p.X, p.Y, p.Z), 5)
        end
    end
})
TabTools:CreateButton({
    Name = "🔄 Reset Karakter",
    Callback = function()
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.Health = 0; notif("Reset", "Respawn~", 2) end
    end
})
TabTools:CreateButton({
    Name = "🧪 Test Buka Toko Bibit",
    Callback = function()
        task.spawn(function()
            local r = bukaToko("npcbibit", 1.5)
            notif(r and "Toko Terbuka!" or "Gagal", r and "Berhasil buka toko!" or "PP kagak ketemu", 4)
        end)
    end
})
TabTools:CreateButton({
    Name = "🧪 Test Jual Manual",
    Callback = function()
        task.spawn(function()
            local r = autoJual()
            notif(r and "Jual OK!" or "Gagal Jual", "", 4)
        end)
    end
})

print("SAWAH INDO v5.1 | User: "..myName)
notif("SAWAH INDO v5.1", "Halo "..myName.."! Scan lahan dulu di tab Scan ya!", 5)
