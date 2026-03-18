--[[
🔌 XKID REMOTE SPY FINAL + PLAYER SCANNER

FITUR:
📡 Remote Spy Stabil
📊 Usage Tracker
🔍 Param Detector
👤 Player Scanner (Workspace)
📋 Safe Copy System
]]

local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Win = Library:Window(
"🔌 XKID SPY FINAL",
"cpu",
"Remote + Player Analyzer",
false
)

-- SERVICES
local Players = game:GetService("Players")

-- TABS
local TabRemote = Win:Tab("📡 REMOTE","radio")
local TabUsage = Win:Tab("📊 USAGE","bar-chart-2")
local TabParam = Win:Tab("🔍 PARAM","search")
local TabPlayer = Win:Tab("👤 PLAYERS","user")
local TabLog = Win:Tab("📋 RESULT","file-text")
local TabSetting = Win:Tab("⚙️ SETTING","settings")

-- STATE
local remoteLog = {}
local remoteUsage = {}
local remoteParams = {}
local playerLog = {}

local totalRemoteCalls = 0
local remoteActive = false
local hook = nil

-- SAFE COPY
local function safeCopy(text)
pcall(function()
setclipboard(text)
end)
end

-- COPY REMOTE LOG (ANTI CRASH)
local function copyLogSafe()

local max = math.min(40,#remoteLog)
local text = "REMOTE LOG\n\n"

for i=1,max do
text = text .. remoteLog[i] .. "\n"
end

safeCopy(text)

Library:Notification("📋","Log dicopy ("..max.." baris)",3)

end

-- ADD LOG
local function addLog(entry)

table.insert(remoteLog,1,entry)

if #remoteLog > 50 then
table.remove(remoteLog)
end

end

-- ===============================
-- REMOTE HOOK (STABLE)
-- ===============================
local function setupHook()

if hook then return end

local old

old = hookmetamethod(game,"__namecall",function(self,...)

local method = getnamecallmethod()

if method ~= "FireServer" then
return old(self,...)
end

if not self:IsA("RemoteEvent") then
return old(self,...)
end

local name = self.Name
local args = {...}

totalRemoteCalls += 1

if not remoteUsage[name] then
remoteUsage[name] = {count = 0}
end

remoteUsage[name].count += 1

if not remoteParams[name] then
remoteParams[name] = {count = #args}
end

if remoteActive then

local entry =
"["..os.date("%H:%M:%S").."] "..name..
" | Args:"..#args

addLog(entry)

end

return old(self,...)

end)

hook = old

Library:Notification("✅","Hook aktif",2)

end

-- START STOP
local function start()

setupHook()

remoteActive = true
remoteLog = {}

Library:Notification("📡","Remote Spy ON",2)

end

local function stop()

remoteActive = false

Library:Notification("📡","Remote Spy OFF",2)

end

-- ===============================
-- PLAYER SCANNER
-- ===============================
local function scanPlayers()

playerLog = {}

for _,plr in ipairs(Players:GetPlayers()) do

local char = plr.Character

if char then

local entry =
"PLAYER : "..plr.Name..
"\nPATH : "..char:GetFullName()

table.insert(playerLog,entry)

end

end

Library:Notification(
"👤 Player Scan",
#playerLog.." player ditemukan",
3)

end

local function copyPlayers()

if #playerLog == 0 then
Library:Notification("❌","Belum scan player",2)
return
end

local text = "=== PLAYER SCAN ===\n\n"

for _,v in ipairs(playerLog) do
text = text .. v .. "\n\n"
end

safeCopy(text)

Library:Notification("📋","Player dicopy",3)

end

-- ===============================
-- REMOTE TAB
-- ===============================
local RemotePage = TabRemote:Page("📡 REMOTE","radio")
local RemoteLeft = RemotePage:Section("Control","Left")

RemoteLeft:Toggle("Enable Spy","RemoteToggle",false,
"Track remote",
function(v)
if v then start() else stop() end
end)

RemoteLeft:Button("Clear Log","Clear",function()
remoteLog = {}
end)

RemoteLeft:Button("Copy Log","Copy",function()
copyLogSafe()
end)

-- ===============================
-- USAGE TAB
-- ===============================
local UsagePage = TabUsage:Page("📊 USAGE","bar-chart-2")
local UsageLeft = UsagePage:Section("Stats","Left")

UsageLeft:Button("Show Stats","Show",function()

local text = "REMOTE USAGE\n\n"

for n,d in pairs(remoteUsage) do
text = text .. n .. " : " .. d.count .. "x\n"
end

Library:Notification("📊 USAGE",text,10)

end)

UsageLeft:Button("Copy Usage","Copy",function()

local text = "REMOTE USAGE\n\n"

for n,d in pairs(remoteUsage) do
text = text .. n .. " : " .. d.count .. "x\n"
end

safeCopy(text)

end)

-- ===============================
-- PARAM TAB
-- ===============================
local ParamPage = TabParam:Page("🔍 PARAM","search")
local ParamLeft = ParamPage:Section("Data","Left")

ParamLeft:Button("Show Params","Scan",function()

local text = "REMOTE PARAMETERS\n\n"

for n,d in pairs(remoteParams) do
text = text .. n .. " | Args:" .. d.count .. "\n"
end

Library:Notification("🔍 PARAM",text,15)

end)

-- ===============================
-- PLAYER TAB
-- ===============================
local PlayerPage = TabPlayer:Page("👤 PLAYERS","user")
local PlayerLeft = PlayerPage:Section("Scanner","Left")

PlayerLeft:Button("Scan Players","Scan",function()
scanPlayers()
end)

PlayerLeft:Button("Copy Players","Copy",function()
copyPlayers()
end)

-- ===============================
-- RESULT TAB
-- ===============================
local LogPage = TabLog:Page("📋 RESULT","file-text")
local LogLeft = LogPage:Section("Export","Left")

LogLeft:Button("Copy All Scan","Copy",function()

local text="=== XKID SCAN RESULT ===\n\n"

text=text.."REMOTE USAGE\n"

for n,d in pairs(remoteUsage) do
text=text..n.." : "..d.count.."x\n"
end

text=text.."\nREMOTE LOG\n"

local max = math.min(40,#remoteLog)

for i=1,max do
text=text..remoteLog[i].."\n"
end

text=text.."\nPLAYER SCAN\n"

for _,v in ipairs(playerLog) do
text=text..v.."\n"
end

safeCopy(text)

Library:Notification("📋","Semua hasil dicopy",3)

end)

-- ===============================
-- SETTINGS
-- ===============================
local SettingPage = TabSetting:Page("⚙️ SETTING","settings")
local SettingLeft = SettingPage:Section("Reset","Left")

SettingLeft:Button("Reset Data","Reset",function()

remoteUsage={}
remoteParams={}
remoteLog={}
playerLog={}
totalRemoteCalls=0

Library:Notification("🔄","Data reset",2)

end)

Library:ConfigSystem(Win)