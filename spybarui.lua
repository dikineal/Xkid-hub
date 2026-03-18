--[[
🔌 XKID REMOTE SPY FINAL (ANTI CRASH)

FITUR:
📡 Remote Spy Stabil
📊 Usage Tracker
🔍 Param Detector (ringan)
🌍 Workspace Scanner
📋 Copy Semua Hasil Scan
]]

local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Win = Library:Window(
"🔌 XKID SPY FINAL",
"cpu",
"Remote Analyzer",
false
)

-- SERVICES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- TABS
local TabRemote = Win:Tab("📡 REMOTE","radio")
local TabUsage = Win:Tab("📊 USAGE","bar-chart-2")
local TabParam = Win:Tab("🔍 PARAM","search")
local TabWorkspace = Win:Tab("🌍 WORKSPACE","box")
local TabLog = Win:Tab("📋 RESULT","file-text")
local TabSetting = Win:Tab("⚙️ SETTING","settings")

-- STATE
local remoteLog = {}
local remoteUsage = {}
local remoteParams = {}
local workspaceLog = {}

local totalRemoteCalls = 0
local remoteActive = false
local hook = nil

-- UTIL
local function copy(text)
pcall(function()
setclipboard(text)
end)
end

local function addLog(entry)

table.insert(remoteLog,1,entry)

if #remoteLog > 50 then
table.remove(remoteLog)
end

end

-- ===============================
-- STABLE REMOTE HOOK
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
remoteParams[name] = {
count = #args
}
end

if remoteActive then

local entry =
"["..os.date("%H:%M:%S").."] "..name..
" | Args: "..#args

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
-- WORKSPACE SCANNER
-- ===============================
local function scanWorkspace(keyword)

workspaceLog = {}

for _,obj in ipairs(Workspace:GetDescendants()) do

local name = obj.Name
local path = obj:GetFullName()

if keyword == "" or string.find(string.lower(name),string.lower(keyword)) then

local entry =
name.." | "..obj.ClassName..
"\n"..path

table.insert(workspaceLog,entry)

end

end

Library:Notification(
"🌍 Scan selesai",
#workspaceLog.." object ditemukan",
4)

end

local function copyWorkspace()

if #workspaceLog == 0 then
Library:Notification("❌","Belum ada hasil scan",2)
return
end

local text="=== WORKSPACE SCAN ===\n\n"

for _,v in ipairs(workspaceLog) do
text=text..v.."\n\n"
end

copy(text)

Library:Notification("📋","Workspace dicopy",3)

end

-- ===============================
-- REMOTE TAB
-- ===============================
local RemotePage=TabRemote:Page("📡 REMOTE","radio")
local RemoteLeft=RemotePage:Section("Control","Left")

RemoteLeft:Toggle("Enable Spy","RemoteToggle",false,
"Track remote",
function(v)
if v then start() else stop() end
end)

RemoteLeft:Button("Clear Log","Clear",function()
remoteLog={}
end)

RemoteLeft:Button("Copy Log","Copy",function()
copy(table.concat(remoteLog,"\n"))
end)

-- ===============================
-- USAGE TAB
-- ===============================
local UsagePage=TabUsage:Page("📊 USAGE","bar-chart-2")
local UsageLeft=UsagePage:Section("Stats","Left")

UsageLeft:Button("Show Stats","Show",function()

local text="REMOTE USAGE\n\n"

for n,d in pairs(remoteUsage) do
text=text..n.." : "..d.count.."x\n"
end

Library:Notification("📊 USAGE",text,10)

end)

UsageLeft:Button("Copy Usage","Copy",function()

local text="REMOTE USAGE\n\n"

for n,d in pairs(remoteUsage) do
text=text..n.." : "..d.count.."x\n"
end

copy(text)

end)

-- ===============================
-- PARAM TAB
-- ===============================
local ParamPage=TabParam:Page("🔍 PARAM","search")
local ParamLeft=ParamPage:Section("Data","Left")

ParamLeft:Button("Show Params","Scan",function()

local text="REMOTE PARAMETERS\n\n"

for n,d in pairs(remoteParams) do
text=text..n.." | Args: "..d.count.."\n"
end

Library:Notification("🔍 PARAM",text,15)

end)

ParamLeft:Button("Copy Params","Copy",function()

local text="REMOTE PARAMETERS\n\n"

for n,d in pairs(remoteParams) do
text=text..n.." | Args: "..d.count.."\n"
end

copy(text)

end)

-- ===============================
-- WORKSPACE TAB
-- ===============================
local WorkspacePage=TabWorkspace:Page("🌍 SCAN","box")
local WSLeft=WorkspacePage:Section("Scanner","Left")

local search=""

WSLeft:TextBox("Keyword","Search","",
function(v)
search=v
end,
"Kosong = scan semua"
)

WSLeft:Button("Scan Workspace","Scan",function()
scanWorkspace(search)
end)

WSLeft:Button("Copy Result","Copy",function()
copyWorkspace()
end)

-- ===============================
-- RESULT TAB
-- ===============================
local LogPage=TabLog:Page("📋 RESULT","file-text")
local LogLeft=LogPage:Section("Export","Left")

LogLeft:Button("Copy All Scan","Copy",function()

local text="=== XKID SCAN RESULT ===\n\n"

text=text.."REMOTE USAGE\n"
for n,d in pairs(remoteUsage) do
text=text..n.." : "..d.count.."x\n"
end

text=text.."\nREMOTE PARAMS\n"
for n,d in pairs(remoteParams) do
text=text..n.." | Args: "..d.count.."\n"
end

text=text.."\nREMOTE LOG\n"
for _,v in ipairs(remoteLog) do
text=text..v.."\n"
end

text=text.."\nWORKSPACE SCAN\n"
for _,v in ipairs(workspaceLog) do
text=text..v.."\n"
end

copy(text)

Library:Notification("📋","Semua hasil dicopy",3)

end)

-- ===============================
-- SETTINGS
-- ===============================
local SettingPage=TabSetting:Page("⚙️ SETTING","settings")
local SettingLeft=SettingPage:Section("Reset","Left")

SettingLeft:Button("Reset Data","Reset",function()

remoteUsage={}
remoteParams={}
remoteLog={}
workspaceLog={}
totalRemoteCalls=0

Library:Notification("🔄","Data reset",2)

end)

Library:ConfigSystem(Win)