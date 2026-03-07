-- 🧪 TEST REMOTE — XKID HUB v2.0
-- Support: Android + Delta/Arceus/Fluxus

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🧪 Test Remote v2.0",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "Remote Debugger",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- ============================================
-- NOTIFIKASI
-- ============================================
local function notif(judul, isi, dur)
    pcall(function()
        Rayfield:Notify({
            Title = judul, 
            Content = isi, 
            Duration = dur or 3, 
            Image = 4483362458
        })
    end)
end

-- ============================================
-- CARI REMOTE (REKURSIF + WORKSPACE)
-- ============================================
local function getRemote(name)
    -- Cari di ReplicatedStorage
    for _, v in pairs(RS:GetDescendants()) do
        if v.Name == name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            return v
        end
    end
    -- Cari di Workspace (kadang remote di sini)
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            return v
        end
    end
    return nil
end

-- ============================================
-- FIRE REMOTE (DENGAN ERROR HANDLING)
-- ============================================
local function fireRemote(name, ...)
    local r = getRemote(name)
    if not r then 
        return false, "❌ Remote tidak ditemukan: "..name 
    end
    
    local ok, result = pcall(function(...)
        if r:IsA("RemoteEvent") then
            r:FireServer(...)
            return "Fired (no return)"
        else
            return r:InvokeServer(...)
        end
    end, ...)
    
    if ok then
        return true, "✅ Success: "..tostring(result)
    else
        return false, "❌ Error: "..tostring(result)
    end
end

-- ============================================
-- TABS
-- ============================================
local TabTest = Window:CreateTab("🧪 Test", nil)
local TabLog = Window:CreateTab("📋 Log", nil)
local TabList = Window:CreateTab("📜 List", nil)
local TabAuto = Window:CreateTab("🤖 Auto", nil)

-- ============================================
-- LOG SYSTEM (FIXED)
-- ============================================
local Logs = {}
local MaxLogs = 20

local LogSection = TabLog:CreateSection("Log Terbaru")

local function addLog(teks)
    table.insert(Logs, 1, "["..os.date("%H:%M:%S").."] "..teks)
    if #Logs > MaxLogs then
        table.remove(Logs, #Logs)
    end
    
    -- Update display (Rayfield tidak support dynamic label, pakai paragraph)
    local display = ""
    for i = 1, math.min(10, #Logs) do
        display = display .. Logs[i] .. "\n"
    end
    
    -- Buat paragraph baru (workaround)
    pcall(function()
        TabLog:CreateParagraph({
            Title = "Log #"..#Logs,
            Content = teks
        })
    end)
end

-- Clear log button
TabLog:CreateButton({
    Name = "🗑 Clear Log",
    Callback = function()
        Logs = {}
        notif("Log", "Cleared!", 2)
    end
})

-- ============================================
-- AUTO HOOK REMOTE RESPONSE
-- ============================================
local HookedRemotes = {
    "PlantCrop","PlantLahanCrop","HarvestCrop","SellCrop",
    "GetBibit","RequestShop","Request Sell","LahanUpdate",
    "RequestLahan","ConfirmAction","UpdateStep","Notification"
}

for _, name in ipairs(HookedRemotes) do
    local r = getRemote(name)
    if r and r:IsA("RemoteEvent") then
        r.OnClientEvent:Connect(function(...)
            local args = {...}
            local msg = "← "..name.." | "
            for i, v in ipairs(args) do
                msg = msg .. "["..i.."]="..tostring(v):sub(1, 30) .. " "
            end
            addLog(msg)
        end)
    end
end

-- ============================================
-- TAB TEST (DENGAN ARGUMENT INPUT)
-- ============================================
TabTest:CreateSection("🎯 Remote + Arguments")

local SelectedRemote = ""
local Arg1 = ""
local Arg2 = ""

TabTest:CreateInput({
    Name = "Remote Name",
    PlaceholderText = "contoh: PlantCrop",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        SelectedRemote = text
    end
})

TabTest:CreateInput({
    Name = "Argument 1 (opsional)",
    PlaceholderText = "string/number/bool",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        Arg1 = text
    end
})

TabTest:CreateInput({
    Name = "Argument 2 (opsional)",
    PlaceholderText = "string/number/bool",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        Arg2 = text
    end
})

TabTest:CreateButton({
    Name = "🔥 FIRE REMOTE",
    Callback = function()
        if SelectedRemote == "" then
            notif("Error", "Masukkan nama remote!", 3)
            return
        end
        
        -- Parse arguments
        local args = {}
        if Arg1 ~= "" then
            -- Coba parse sebagai number
            local num = tonumber(Arg1)
            if num then
                table.insert(args, num)
            elseif Arg1 == "true" then
                table.insert(args, true)
            elseif Arg1 == "false" then
                table.insert(args, false)
            else
                table.insert(args, Arg1)
            end
        end
        
        if Arg2 ~= "" then
            local num = tonumber(Arg2)
            if num then
                table.insert(args, num)
            elseif Arg2 == "true" then
                table.insert(args, true)
            elseif Arg2 == "false" then
                table.insert(args, false)
            else
                table.insert(args, Arg2)
            end
        end
        
        -- Fire
        local success, msg = fireRemote(SelectedRemote, unpack(args))
        addLog(msg)
        notif("Fire Remote", msg, 3)
    end
})

-- ============================================
-- QUICK BUTTONS (REMOTE POPULER)
-- ============================================
TabTest:CreateSection("⚡ Quick Fire (Tanpa Argumen)")

local QuickRemotes = {
    {Name = "🌱 PlantCrop", Remote = "PlantCrop"},
    {Name = "🌿 HarvestCrop", Remote = "HarvestCrop"},
    {Name = "💰 SellCrop", Remote = "SellCrop"},
    {Name = "🛒 GetBibit", Remote = "GetBibit"},
    {Name = "📦 RequestShop", Remote = "RequestShop"},
    {Name = "🏞 RequestLahan", Remote = "RequestLahan"},
    {Name = "✅ ConfirmAction", Remote = "ConfirmAction"},
    {Name = "🔄 UpdateStep", Remote = "UpdateStep"},
}

for _, btn in ipairs(QuickRemotes) do
    TabTest:CreateButton({
        Name = btn.Name,
        Callback = function()
            local success, msg = fireRemote(btn.Remote)
            addLog(msg)
            notif(btn.Remote, msg, 2)
        end
    })
end

-- ============================================
-- TAB LIST (DROPDOWN + SEARCH)
-- ============================================
TabList:CreateSection("📜 Cari Remote")

local AllRemotes = {}
local function scanAllRemotes()
    AllRemotes = {}
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(AllRemotes, v.Name)
        end
    end
    -- Remove duplicates
    local seen = {}
    local unique = {}
    for _, name in ipairs(AllRemotes) do
        if not seen[name] then
            seen[name] = true
            table.insert(unique, name)
        end
    end
    AllRemotes = unique
    table.sort(AllRemotes)
end

scanAllRemotes()

TabList:CreateLabel("Total: "..#AllRemotes.." unique remotes")

TabList:CreateDropdown({
    Name = "Pilih Remote",
    Options = AllRemotes,
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(option)
        SelectedRemote = option[1]
        notif("Selected", option[1], 2)
    end
})

TabList:CreateButton({
    Name = "🔄 Refresh List",
    Callback = function()
        scanAllRemotes()
        notif("Refresh", "Found "..#AllRemotes.." remotes", 2)
    end
})

-- ============================================
-- TAB AUTO (AUTO FARM TEST)
-- ============================================
TabAuto:CreateSection("🤖 Auto Farm Test")

_G.AutoFarm = false

TabAuto:CreateToggle({
    Name = "Auto Plant → Harvest → Sell",
    CurrentValue = false,
    Callback = function(v)
        _G.AutoFarm = v
        
        if v then
            task.spawn(function()
                while _G.AutoFarm do
                    -- Plant
                    local ok1, msg1 = fireRemote("PlantCrop")
                    addLog(msg1)
                    task.wait(0.5)
                    
                    -- Harvest
                    local ok2, msg2 = fireRemote("HarvestCrop")
                    addLog(msg2)
                    task.wait(0.5)
                    
                    -- Sell
                    local ok3, msg3 = fireRemote("SellCrop")
                    addLog(msg3)
                    task.wait(1)
                end
            end)
        end
    end
})

TabAuto:CreateSlider({
    Name = "Delay (detik)",
    Range = {0.5, 5},
    Increment = 0.5,
    CurrentValue = 1,
    Callback = function(v)
        _G.AutoDelay = v
    end
})

-- ============================================
-- INIT
-- ============================================
notif("Test Remote v2.0", "Ready! Pilih remote di tab List atau Test", 4)
addLog("System initialized")
addLog("Found "..#AllRemotes.." remotes")
