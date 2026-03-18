--[[
🔌 XKID REMOTE SPY FINAL + WORKSPACE SCANNER

FITUR:
📡 Remote Spy
📊 Usage Tracker
🔍 Param Detector
📋 Copy Semua Hasil Scan
🌍 Workspace Scanner
]]

local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Win = Library:Window(
"🔌 XKID SPY + SCANNER",
"cpu",
"Remote & Workspace Analyzer",
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

local PAGE_SIZE = 10
local page = 1

-- UTIL
local function copy(text)
pcall(function()
setclipboard(text)
end)
end

local function serialize(v)

local t = typeof(v)

if t=="string" then
return '"'..v..'"'
elseif t=="number" then
return tostring(v)
elseif t=="boolean" then
return tostring(v)
elseif t=="Vector3" then
return string.format("V3(%.1f,%.1f,%.1f)",v.X,v.Y,v.Z)
elseif t=="Instance" then
return "["..v.Name.."]"
else
return "["..t.."]"
end

end

local function formatArgs(args)

if #args==0 then return "(no args)" end

local t={}

for i,v in ipairs(args) do
table.insert(t,"["..i.."]="..serialize(v))
end

return table.concat(t," ")

end

local function argTypes(args)

local t={}

for _,v in ipairs(args) do
table.insert(t,typeof(v))
end

return table.concat(t,", ")

end

local function addLog(entry)

table.insert(remoteLog,1,entry)

if #remoteLog>200 then
table.remove(remoteLog)
end

end

-- HOOK REMOTE
local function setupHook()

if hook then return end

local old

old=hookmetamethod(game,"__namecall",function(self,...)

local method=getnamecallmethod()
local args={...}

local isRemote=false
local name="Unknown"

pcall(function()

if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
isRemote=true
name=self.Name
end

end)

if isRemote and (method=="FireServer" or method=="InvokeServer") then

totalRemoteCalls+=1

if not remoteUsage[name] then
remoteUsage[name]={count=0}
end

remoteUsage[name].count+=1

if not remoteParams[name] then
remoteParams[name]={
count=#args,
types=argTypes(args),
sample=formatArgs(args)
}
end

if remoteActive then

local entry=
"["..os.date("%H:%M:%S").."] "..name..
"\nARGS: "..formatArgs(args)

addLog(entry)

end

end

return old(self,...)

end)

hook=old

Library:Notification("✅","Hook aktif",2)

end

-- START STOP
local function start()

setupHook()

remoteActive=true
remoteLog={}

Library:Notification("📡","Remote Spy ON",2)

end

local function stop()

remoteActive=false

Library:Notification("📡","Remote Spy OFF",2)

end

-- WORKSPACE SCAN
local function scanWorkspace(keyword)

workspaceLog={}

for _,obj in ipairs(Workspace:GetDescendants()) do

local name=obj.Name
local path=obj:GetFullName()

if keyword=="" or string.find(string.lower(name),string.lower(keyword)) then

local entry=name.." | "..obj.ClassName.."\n"..path

table.insert(workspaceLog,entry)

end

end

Library:Notification("🌍 Scan selesai",
#workspaceLog.." object ditemukan",
4)

end

local function copyWorkspace()

if #workspaceLog==0 then
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

-- REMOTE TAB
local RemotePage=TabRemote:Page("📡 REMOTE","radio")
local Left=RemotePage:Section("Control","Left")

Left:Toggle("Enable","RemoteToggle",false,
"Track remote",
function(v)
if v then start() else stop() end
end)

Left:Button("Clear Log","Clear",function()
remoteLog={}
end)

Left:Button("Copy Log","Copy",function()
copy(table.concat(remoteLog,"\n\n"))
end)

-- USAGE TAB
local UsagePage=TabUsage:Page("📊 USAGE","bar-chart-2")
local UsageLeft=UsagePage:Section("Stats","Left")

UsageLeft:Button("Show Stats","Top remote",function()

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

-- PARAM TAB
local ParamPage=TabParam:Page("🔍 PARAM","search")
local ParamLeft=ParamPage:Section("Data","Left")

ParamLeft:Button("Scan Params","Show",function()

local text="REMOTE PARAMETERS\n\n"

for n,d in pairs(remoteParams) do

text=text..n.."\n"
text=text.."Args: "..d.count.."\n"
text=text.."Types: "..d.types.."\n"
text=text.."Sample: "..d.sample.."\n\n"

end

Library:Notification("🔍 PARAM",text,15)

end)

ParamLeft:Button("Copy Params","Copy",function()

local text="REMOTE PARAMETERS\n\n"

for n,d in pairs(remoteParams) do
text=text..n.." | "..d.types.."\n"
end

copy(text)

end)

-- WORKSPACE TAB
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

-- RESULT TAB
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
text=text..n.." | "..d.types.." | "..d.sample.."\n"
end

text=text.."\nREMOTE LOG\n"

for _,v in ipairs(remoteLog) do
text=text..v.."\n"
end

copy(text)

Library:Notification("📋","Semua hasil dicopy",3)

end)

-- SETTINGS
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