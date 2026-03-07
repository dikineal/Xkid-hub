-- 🧪 TEST REMOTE — XKID HUB
-- Support: Android + Delta Executor

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🧪 Test Remote",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "test & log",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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
    if not r then return "❌ Tidak ketemu: "..name end
    local ok, err = pcall(function()
        if r:IsA("RemoteEvent") then r:FireServer(...)
        else r:InvokeServer(...) end
    end)
    if ok then return "✅ Fired: "..name
    else return "❌ Error: "..tostring(err) end
end

local TabTest = Window:CreateTab("🧪 Test", nil)
local TabLog  = Window:CreateTab("📋 Log",  nil)
local TabList = Window:CreateTab("📜 List", nil)

-- LOG SYSTEM
local logCount = 0
local logSection = TabLog:CreateSection("Hasil Log")
TabLog:CreateLabel("Log muncul otomatis di sini!")

local function addLog(teks)
    logCount = logCount + 1
    TabLog:CreateLabel("["..logCount.."] "..teks)
end

-- Hook response remote penting
local hooks = {"PlantCrop","PlantLahanCrop","HarvestCrop","SellCrop","GetBibit","RequestShop","Request Sell","LahanUpdate","RequestLahan","ConfirmAction"}
for _, name in ipairs(hooks) do
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

-- TAB TEST
TabTest:CreateSection("🌱 Tanam")
TabTest:CreateLabel("Berdiri di lahan sebelum test!")
TabTest:CreateButton({Name="🌱 PlantCrop", Callback=function()
    local h = fire("PlantCrop"); addLog(h); notif("PlantCrop", h, 3)
end})
TabTest:CreateButton({Name="🌱 PlantLahanCrop", Callback=function()
    local h = fire("PlantLahanCrop"); addLog(h); notif("PlantLahanCrop", h, 3)
end})

TabTest:CreateSection("🌿 Panen")
TabTest:CreateButton({Name="🌿 HarvestCrop", Callback=function()
    local h = fire("HarvestCrop"); addLog(h); notif("HarvestCrop", h, 3)
end})

TabTest:CreateSection("💰 Jual")
TabTest:CreateButton({Name="💰 SellCrop", Callback=function()
    local h = fire("SellCrop"); addLog(h); notif("SellCrop", h, 3)
end})
TabTest:CreateButton({Name="💰 Request Sell", Callback=function()
    local h = fire("Request Sell"); addLog(h); notif("Request Sell", h, 3)
end})

TabTest:CreateSection("🛒 Beli")
TabTest:CreateButton({Name="🛒 GetBibit", Callback=function()
    local h = fire("GetBibit"); addLog(h); notif("GetBibit", h, 3)
end})
TabTest:CreateButton({Name="🛒 RequestShop", Callback=function()
    local h = fire("RequestShop"); addLog(h); notif("RequestShop", h, 3)
end})

TabTest:CreateSection("🌾 Lahan")
TabTest:CreateButton({Name="🌾 RequestLahan", Callback=function()
    local h = fire("RequestLahan"); addLog(h); notif("RequestLahan", h, 3)
end})
TabTest:CreateButton({Name="✅ ConfirmAction", Callback=function()
    local h = fire("ConfirmAction"); addLog(h); notif("ConfirmAction", h, 3)
end})

-- TAB LIST
TabList:CreateSection("Semua Remote (49 total)")
local allRemotes = {
    "UpdateStep","PlantCrop","HarvestCrop","SellCrop","GetBibit",
    "Notification","UpdateLevel","Skip Tutorial","RainSync","PromptGamepassRemote",
    "Lightning Strike","SummonRain","WeatherSync","LahanUpdate","PlantLahanCrop",
    "TransferPromptOpen","KiteEvent","HygieneSync","Admin SendMessage","Admin ShowMessage",
    "BikeRemote","Toggle AutoHarvest","SyncData","RequestShop","Request Sell",
    "Request ToolShop","RequestGamepass","RequestLahan","RequestTransfer","ConfirmAction",
    "Chewy","RefreshShop","RequestGift","GiftNotify","AdminSetTitle",
    "Admin Remove Title","AdminIsAdmin","Admin TitleStats","PromptDonation",
    "RequestDonation","Bike Sound","RefreshEvent","Sync","UnSync",
    "PromptCarry","RespondToCarry","UpdateStatus","RequestCarry","Notify","StopCarry"
}
for _, name in ipairs(allRemotes) do
    local r = getRemote(name)
    TabList:CreateLabel((r and "✅ " or "❌ ")..name)
end

notif("Test Remote", "Ke tab Test, berdiri di lahan lalu test!", 4)
