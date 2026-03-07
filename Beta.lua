-- 🌾 SAWAH INDO v5.2 — XKID HUB
-- Support: Android + Delta Executor
-- Fix: Simpan posisi lahan manual by koordinat

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO v5.2 💸",
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

local savedLahanPos = nil
local lahanRadius = 50

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

local function tpCoord(x, y, z)
    local root = getRoot()
    if not root then return false end
    root.CFrame = CFrame.new(x, y + 4, z)
    task.wait(0.5)
    return true
end

local function cari(nama)
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower() == nama:lower() then return v end
    end
    return nil
end

local function getAllLahan()
    local lahans = {}
    if savedLahanPos then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n = v.Name:lower()
                if n:find("tanah") or n:find("lahan") or n:find("plot") or n:find("sawah") then
                    if (v.Position - savedLahanPos).Magnitude <= lahanRadius then
                        lahans[#lahans+1] = v
                    end
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

local TabBibit = Window:CreateTab("🛒 Beli Bibit", nil)
local TabFarm  = Window:CreateTab("🤖 Auto Farm",  nil)
local TabTP    = Window:CreateTab("📍 Teleport",   nil)
local TabLahan = Window:CreateTab("🌾 Lahan",      nil)
local TabTools = Window:CreateTab("🛠 Tools",      nil)

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
                autoBeliBibit()
            end)
        end
    })
end
TabBibit:CreateSection("🔁 Auto Beli")
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
                while _G.AutoBeli do autoBeliBibit(); task.wait(autoBibitDelay) end
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
TabFarm:CreateSlider({Name="⏳ Tunggu Panen", Range={3,120},Increment=1,   CurrentValue=10,  Callback=function(v) dPanen=v end})
TabFarm:CreateSection("🤖 Auto Farm Full")
TabFarm:CreateToggle({
    Name = "🌾 AUTO FARM — Beli > Tanam > Panen > Jual",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoFarm = v
        if v then
            if not savedLahanPos then
                notif("Simpan Lahan Dulu!", "Ke tab Lahan > Simpan Posisi Lahan!", 5)
                _G.AutoFarm = false
                return
            end
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
                    for _, lahan in ipairs(lahans) do
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
                    for _, lahan in ipairs(getAllLahan()) do
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
    {icon="🛒", name="npcbibit",        label="Beli Bibit"},
    {icon="💰", name="npcpenjual",       label="Jual Hasil"},
    {icon="🔧", name="npcalat",          label="Beli Alat"},
    {icon="🥚", name="NPCPedagangTelur", label="Jual Telur"},
    {icon="🌴", name="NPCPedagangSawit", label="Jual Sawit"},
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
        if savedLahanPos then
            tpCoord(savedLahanPos.X, savedLahanPos.Y, savedLahanPos.Z)
            notif("Teleport", "Di lahan kamu!", 2)
        else
            notif("Error", "Simpan posisi lahan dulu!", 3)
        end
    end
})

-- TAB LAHAN
TabLahan:CreateSection("💾 Simpan Posisi Lahan Kamu")
TabLahan:CreateLabel("Berdiri di tengah LAHAN KAMU lalu tekan Simpan!")
TabLahan:CreateButton({
    Name = "💾 SIMPAN POSISI LAHAN SEKARANG",
    Callback = function()
        local root = getRoot()
        if root then
            savedLahanPos = root.Position
            local p = savedLahanPos
            notif("Tersimpan!", ("X=%.1f Y=%.1f Z=%.1f"):format(p.X, p.Y, p.Z), 5)
            task.wait(0.5)
            local n = #getAllLahan()
            notif("Lahan Ketemu", n.." lahan di radius "..lahanRadius.." stud", 4)
        else
            notif("Error", "Karakter belum ready!", 3)
        end
    end
})
TabLahan:CreateButton({
    Name = "📋 Lihat Posisi & Jumlah Lahan",
    Callback = function()
        if savedLahanPos then
            local p = savedLahanPos
            local n = #getAllLahan()
            notif("Posisi Lahan", ("X=%.1f Y=%.1f Z=%.1f | %d lahan"):format(p.X, p.Y, p.Z, n), 5)
        else
            notif("Belum Simpan", "Berdiri di lahan lalu tekan Simpan!", 4)
        end
    end
})
TabLahan:CreateSlider({
    Name = "📏 Radius Pencarian Lahan (stud)",
    Range = {10, 200}, Increment = 10, CurrentValue = 50,
    Callback = function(v) lahanRadius = v end
})
TabLahan:CreateButton({
    Name = "🔄 Reset Posisi Lahan",
    Callback = function()
        savedLahanPos = nil
        notif("Reset", "Posisi lahan dihapus", 2)
    end
})
TabLahan:CreateSection("🔍 Debug")
TabLahan:CreateButton({
    Name = "🔍 Scan Object Sekitar (radius 30)",
    Callback = function()
        local root = getRoot()
        if not root then return end
        local found = {}
        for _, v in pairs(workspace:GetDescendants()) do
            local pos
            if v:IsA("BasePart") then pos = v.Position
            elseif v:IsA("Model") and v.PrimaryPart then pos = v.PrimaryPart.Position end
            if pos and (pos - root.Position).Magnitude < 30 and not found[v.Name] then
                found[v.Name] = true
                print("OBJ: "..v.Name.." | "..v.ClassName)
                for a, b in pairs(v:GetAttributes()) do
                    print("  ATTR: "..a.."="..tostring(b))
                end
            end
        end
        notif("Scan", "Selesai! Cek console Delta", 4)
    end
})
TabLahan:CreateButton({
    Name = "🔍 Scan PP Sekitar (radius 20)",
    Callback = function()
        local root = getRoot()
        if not root then return end
        local n = 0
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                local par = v.Parent
                if par and par:IsA("BasePart") then
                    local d = (par.Position - root.Position).Magnitude
                    if d < 20 then
                        n = n + 1
                        print("PP: ["..v.ActionText.."] dist="..math.floor(d).." path="..v:GetFullName())
                    end
                end
            end
        end
        notif("Scan PP", n.." PP ketemu dalam 20 stud", 4)
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
            notif(r and "Toko Terbuka!" or "Gagal", r and "Berhasil!" or "PP kagak ketemu", 4)
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

print("SAWAH INDO v5.2 | "..myName)
notif("SAWAH INDO v5.2", "Halo "..myName.."! Ke tab Lahan > Simpan Posisi dulu!", 6)