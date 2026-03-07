-- 🌾 SAWAH INDO v5.3 — XKID HUB
-- Support: Android + Delta Executor

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🌾 SAWAH INDO v5.3 💸",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "auto cuan 🔥",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local myName = LocalPlayer.Name

_G.AutoTanam = false
_G.AutoPanen = false
_G.AutoJual  = false
_G.AutoFarm  = false
_G.AutoBeli  = false

local dTanam  = 0.8
local dPanen  = 0.8
local dJual   = 0.8
local dTunggu = 30
local savedLahanPos = nil
local lahanRadius = 80
local selectedBibit = "Padi"
local jumlahBeli = 1

local function notif(judul, isi, dur)
    pcall(function()
        Rayfield:Notify({Title=judul, Content=isi, Duration=dur or 3, Image=4483362458})
    end)
end

local function getRemote(name)
    for _, v in pairs(RS:GetDescendants()) do
        if v.Name == name then return v end
    end
    return nil
end

local function fire(name, ...)
    local r = getRemote(name)
    if not r then return false, "tidak ketemu" end
    local ok, err = pcall(function()
        if r:IsA("RemoteEvent") then r:FireServer(...)
        else r:InvokeServer(...) end
    end)
    return ok, tostring(err)
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
    if obj:IsA("BasePart") then pos = obj.Position
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

local function klikGUI(tombol)
    if not tombol then return end
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
    task.wait(0.1)
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- ACTIONS
local function doTanam()
    fire("PlantCrop")
    task.wait(0.1)
    fire("PlantLahanCrop")
end

local function doPanen()
    fire("HarvestCrop")
end

local function doJual()
    local npc = cari("npcpenjual")
    if npc then tp(npc); task.wait(0.5) end
    fire("SellCrop")
    task.wait(0.1)
    fire("Request Sell")
end

local function doBeli()
    local npc = cari("npcbibit")
    if not npc then return end
    tp(npc)
    task.wait(0.5)
    local pp = getPPDekat(15)
    if pp then firePrompt(pp) end
    task.wait(1)
    local gui = LocalPlayer.PlayerGui
    if jumlahBeli > 1 then
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and v.Text == "+" and v.Visible then
                for i = 1, jumlahBeli - 1 do klikGUI(v); task.wait(0.07) end
                break
            end
        end
        task.wait(0.2)
    end
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and (v.Text:lower() == "beli" or v.Text:lower() == "buy") and v.Visible then
            klikGUI(v); break
        end
    end
    task.wait(0.5)
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and (v.Text:lower() == "tutup" or v.Text:lower() == "close") and v.Visible then
            klikGUI(v); break
        end
    end
end

-- TABS
local TabMain = Window:CreateTab("🎮 Main",   nil)
local TabSet  = Window:CreateTab("⚙ Setting", nil)
local TabTP   = Window:CreateTab("📍 TP",     nil)
local TabTest = Window:CreateTab("🧪 Test",   nil)
local TabLog  = Window:CreateTab("📋 Log",    nil)

-- LOG SYSTEM
local logCount = 0
TabLog:CreateSection("Hasil Response Remote")
TabLog:CreateLabel("Log muncul otomatis setelah test!")

local function addLog(teks)
    logCount = logCount + 1
    TabLog:CreateLabel("["..logCount.."] "..teks)
end

-- Hook response remote penting
local hookList = {"PlantCrop","PlantLahanCrop","HarvestCrop","SellCrop","GetBibit","RequestShop","Request Sell","LahanUpdate","RequestLahan","ConfirmAction"}
for _, name in ipairs(hookList) do
    local r = getRemote(name)
    if r and r:IsA("RemoteEvent") then
        r.OnClientEvent:Connect(function(a, b, c)
            local msg = "←"..name..": "..tostring(a)
            if b ~= nil then msg = msg.." | "..tostring(b) end
            if c ~= nil then msg = msg.." | "..tostring(c) end
            addLog(msg)
        end)
    end
end

-- TAB MAIN
TabMain:CreateSection("💾 Lahan")
TabMain:CreateButton({
    Name = "💾 Simpan Posisi Lahan (berdiri di lahan dulu!)",
    Callback = function()
        local root = getRoot()
        if root then
            savedLahanPos = root.Position
            local n = #getAllLahan()
            notif("Tersimpan!", n.." lahan ketemu di radius "..lahanRadius, 4)
        end
    end
})

TabMain:CreateSection("🔁 Toggle Auto")
TabMain:CreateToggle({
    Name = "🛒 Auto Beli Bibit",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoBeli = v
        if v then
            notif("Auto Beli ON", selectedBibit.." x"..jumlahBeli, 3)
            task.spawn(function()
                while _G.AutoBeli do doBeli(); task.wait(3) end
            end)
        else notif("Auto Beli", "Off", 2) end
    end
})
TabMain:CreateToggle({
    Name = "🌱 Auto Tanam",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoTanam = v
        if v then
            notif("Auto Tanam ON", "FireServer PlantCrop~", 3)
            task.spawn(function()
                while _G.AutoTanam do doTanam(); task.wait(dTanam) end
            end)
        else notif("Auto Tanam", "Off", 2) end
    end
})
TabMain:CreateToggle({
    Name = "🌿 Auto Panen",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoPanen = v
        if v then
            notif("Auto Panen ON", "FireServer HarvestCrop~", 3)
            task.spawn(function()
                while _G.AutoPanen do doPanen(); task.wait(dPanen) end
            end)
        else notif("Auto Panen", "Off", 2) end
    end
})
TabMain:CreateToggle({
    Name = "💰 Auto Jual",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoJual = v
        if v then
            notif("Auto Jual ON", "FireServer SellCrop~", 3)
            task.spawn(function()
                while _G.AutoJual do doJual(); task.wait(dJual) end
            end)
        else notif("Auto Jual", "Off", 2) end
    end
})

TabMain:CreateSection("🚀 Auto Farm Full")
TabMain:CreateSlider({
    Name = "⏳ Tunggu Panen (detik)",
    Range = {5, 120}, Increment = 5, CurrentValue = 30,
    Callback = function(v) dTunggu = v end
})
TabMain:CreateToggle({
    Name = "🌾 AUTO FARM — Tanam > Tunggu > Panen > Jual",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoFarm = v
        if v then
            notif("AUTO FARM ON", "Gas brooo! 💸", 4)
            task.spawn(function()
                local siklus = 0
                while _G.AutoFarm do
                    siklus = siklus + 1
                    print("SIKLUS #"..siklus)
                    doBeli()
                    if not _G.AutoFarm then break end
                    task.wait(0.5)
                    doTanam()
                    if not _G.AutoFarm then break end
                    notif("Nunggu Panen", dTunggu.."s...", dTunggu)
                    task.wait(dTunggu)
                    if not _G.AutoFarm then break end
                    doPanen()
                    task.wait(0.5)
                    doJual()
                    task.wait(0.5)
                    notif("Siklus #"..siklus, "Done! Loop lagi 🔁", 3)
                    task.wait(1)
                end
                notif("AUTO FARM", "Distop", 3)
            end)
        else notif("AUTO FARM", "Off", 2) end
    end
})

TabMain:CreateSection("🔴 Stop")
TabMain:CreateButton({
    Name = "⛔ STOP SEMUA",
    Callback = function()
        _G.AutoFarm=false; _G.AutoBeli=false
        _G.AutoTanam=false; _G.AutoPanen=false; _G.AutoJual=false
        notif("STOP", "Semua auto dimatiin!", 3)
    end
})

-- TAB SETTING
TabSet:CreateSection("🌱 Bibit")
local BIBIT = {
    {name="Padi",emoji="⚡",minLv=1},
    {name="Jagung",emoji="🌽",minLv=20},
    {name="Tomat",emoji="🍅",minLv=40},
    {name="Terong",emoji="🍆",minLv=60},
    {name="Strawberry",emoji="🍓",minLv=80},
    {name="Sawit",emoji="🌴",minLv=80},
    {name="Durian",emoji="🟢",minLv=120},
}
local opsi = {}
for _, b in ipairs(BIBIT) do opsi[#opsi+1] = b.emoji.." "..b.name.." Lv."..b.minLv end
TabSet:CreateDropdown({
    Name = "Pilih Bibit",
    Options = opsi, CurrentOption = {opsi[1]},
    Callback = function(v)
        for _, b in ipairs(BIBIT) do
            if v[1]:find(b.name) then selectedBibit = b.name; notif("Bibit", b.name, 2); break end
        end
    end
})
TabSet:CreateSlider({Name="Jumlah Beli", Range={1,50}, Increment=1, CurrentValue=1, Callback=function(v) jumlahBeli=v end})
TabSet:CreateSection("⏱ Delay")
TabSet:CreateSlider({Name="Delay Tanam", Range={1,10}, Increment=1, CurrentValue=1, Callback=function(v) dTanam=v end})
TabSet:CreateSlider({Name="Delay Panen", Range={1,10}, Increment=1, CurrentValue=1, Callback=function(v) dPanen=v end})
TabSet:CreateSlider({Name="Delay Jual",  Range={1,10}, Increment=1, CurrentValue=1, Callback=function(v) dJual=v  end})
TabSet:CreateSlider({Name="Radius Lahan",Range={10,300},Increment=10,CurrentValue=80,Callback=function(v) lahanRadius=v end})

-- TAB TP
TabTP:CreateSection("NPC")
local npcList = {
    {icon="🛒",name="npcbibit",label="Beli Bibit"},
    {icon="💰",name="npcpenjual",label="Jual Hasil"},
    {icon="🔧",name="npcalat",label="Beli Alat"},
    {icon="🥚",name="NPCPedagangTelur",label="Jual Telur"},
    {icon="🌴",name="NPCPedagangSawit",label="Jual Sawit"},
}
for _, npc in ipairs(npcList) do
    TabTP:CreateButton({
        Name = npc.icon.." "..npc.name.." - "..npc.label,
        Callback = function()
            local o = cari(npc.name)
            if o then tp(o); notif("TP", npc.name.." OK", 2)
            else notif("Error", npc.name.." kagak ada", 3) end
        end
    })
end
TabTP:CreateSection("Lahan")
TabTP:CreateButton({
    Name = "🌾 Teleport ke Lahan",
    Callback = function()
        if savedLahanPos then
            local root = getRoot()
            if root then root.CFrame = CFrame.new(savedLahanPos.X, savedLahanPos.Y+4, savedLahanPos.Z) end
            notif("TP", "Di lahan kamu!", 2)
        else notif("Error", "Simpan posisi lahan dulu!", 3) end
    end
})

-- TAB TEST
TabTest:CreateSection("🌱 Tanam")
TabTest:CreateLabel("Berdiri di lahan sebelum test!")
TabTest:CreateButton({Name="🌱 Test PlantCrop", Callback=function()
    local ok, err = fire("PlantCrop")
    local h = ok and "✅ PlantCrop fired!" or "❌ "..err
    addLog(h); notif("PlantCrop", h, 3)
end})
TabTest:CreateButton({Name="🌱 Test PlantLahanCrop", Callback=function()
    local ok, err = fire("PlantLahanCrop")
    local h = ok and "✅ PlantLahanCrop fired!" or "❌ "..err
    addLog(h); notif("PlantLahanCrop", h, 3)
end})
TabTest:CreateSection("🌿 Panen")
TabTest:CreateButton({Name="🌿 Test HarvestCrop", Callback=function()
    local ok, err = fire("HarvestCrop")
    local h = ok and "✅ HarvestCrop fired!" or "❌ "..err
    addLog(h); notif("HarvestCrop", h, 3)
end})
TabTest:CreateSection("💰 Jual")
TabTest:CreateButton({Name="💰 Test SellCrop", Callback=function()
    local ok, err = fire("SellCrop")
    local h = ok and "✅ SellCrop fired!" or "❌ "..err
    addLog(h); notif("SellCrop", h, 3)
end})
TabTest:CreateButton({Name="💰 Test Request Sell", Callback=function()
    local ok, err = fire("Request Sell")
    local h = ok and "✅ Request Sell fired!" or "❌ "..err
    addLog(h); notif("Request Sell", h, 3)
end})
TabTest:CreateSection("🛒 Beli")
TabTest:CreateButton({Name="🛒 Test GetBibit", Callback=function()
    local ok, err = fire("GetBibit")
    local h = ok and "✅ GetBibit fired!" or "❌ "..err
    addLog(h); notif("GetBibit", h, 3)
end})
TabTest:CreateButton({Name="🛒 Test RequestShop", Callback=function()
    local ok, err = fire("RequestShop")
    local h = ok and "✅ RequestShop fired!" or "❌ "..err
    addLog(h); notif("RequestShop", h, 3)
end})
TabTest:CreateSection("🌾 Lahan")
TabTest:CreateButton({Name="🌾 Test RequestLahan", Callback=function()
    local ok, err = fire("RequestLahan")
    local h = ok and "✅ RequestLahan fired!" or "❌ "..err
    addLog(h); notif("RequestLahan", h, 3)
end})
TabTest:CreateButton({Name="✅ Test ConfirmAction", Callback=function()
    local ok, err = fire("ConfirmAction")
    local h = ok and "✅ ConfirmAction fired!" or "❌ "..err
    addLog(h); notif("ConfirmAction", h, 3)
end})

print("SAWAH INDO v5.3 | "..myName)
notif("SAWAH INDO v5.3", "Halo "..myName.."! Simpan posisi lahan dulu!", 5)