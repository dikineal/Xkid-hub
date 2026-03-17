--[[
  ╔══════════════════════════════════════════════════════╗
  ║         🌿  X K I D . H U B  v5.1  🌿             ║
  ║         Aurora UI  ✦  Farming Edition               ║
  ╚══════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════
--  LOAD LIBRARY
-- ═══════════════════════════════════════
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

-- ═══════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService   = game:GetService("TeleportService")
local Lighting    = game:GetService("Lighting")
local LP          = Players.LocalPlayer
local RS          = game:GetService("ReplicatedStorage")

-- ═══════════════════════════════════════
--  REMOTE HELPER (lazy - tidak blocking)
-- ═══════════════════════════════════════
local function getTut()
    local rem = RS:FindFirstChild("Remotes")
    return rem and rem:FindFirstChild("TutorialRemotes")
end
local function getDN()
    local rem = RS:FindFirstChild("Remotes")
    return rem and rem:FindFirstChild("DayNightRemotes")
end
local function safefire(parent, name)
    local r = parent and parent:FindFirstChild(name)
    if r then pcall(function() r:FireServer() end) end
end
local function safeinvoke(parent, name)
    local r = parent and parent:FindFirstChild(name)
    if r then pcall(function() r:InvokeServer() end) end
end

-- ═══════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getDist(a, b)
    return math.floor((a - b).Magnitude + 0.5)
end

-- ═══════════════════════════════════════
--  STATE
-- ═══════════════════════════════════════
local curWS        = 16
local curJP        = 50
local flyOn        = false
local flySpeed     = 60
local flyBV        = nil
local flyBG        = nil
local flyConn      = nil
local noclipOn     = false
local noclipConn   = nil
local espOn        = false
local espBills     = {}
local espConns     = {}
local afkConn      = nil
local antiKickOn   = false
local slots        = {}
local autoFarmConn = nil
local autoFarmDelay= 1
local lightConn    = nil
local PITCH_UP     =  0.3
local PITCH_DOWN   = -0.3

-- ═══════════════════════════════════════
--  RE-APPLY ON RESPAWN
-- ═══════════════════════════════════════
LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    task.wait(0.5)
    hum.WalkSpeed    = curWS
    hum.JumpPower    = curJP
    hum.UseJumpPower = true
    if flyOn then
        task.wait(0.3)
        local r2 = char:FindFirstChild("HumanoidRootPart")
        if r2 then
            if flyBV then pcall(function() flyBV:Destroy() end) end
            if flyBG then pcall(function() flyBG:Destroy() end) end
            flyBV = Instance.new("BodyVelocity", r2)
            flyBV.Velocity = Vector3.new()
            flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
            flyBG = Instance.new("BodyGyro", r2)
            flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
            flyBG.P = 1e4; flyBG.D = 100
            flyBG.CFrame = r2.CFrame
            hum.PlatformStand = true
        end
    end
end)

-- ═══════════════════════════════════════
--  INFER PLAYER
-- ═══════════════════════════════════════
local function infer_plr(ref)
    if typeof(ref) ~= "string" then return ref end
    local best, min = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local nv = math.huge
            if p.Name:find("^"..ref)             then nv = 1.0*(#p.Name-#ref)
            elseif p.DisplayName:find("^"..ref)  then nv = 1.5*(#p.DisplayName-#ref)
            elseif p.Name:lower():find("^"..ref:lower())        then nv = 2.0*(#p.Name-#ref)
            elseif p.DisplayName:lower():find("^"..ref:lower()) then nv = 2.5*(#p.DisplayName-#ref)
            end
            if nv < min then best = p; min = nv end
        end
    end
    return best
end

-- ═══════════════════════════════════════
--  TELEPORT
-- ═══════════════════════════════════════
local function tpToPlayer(ref)
    if not ref or ref == "" then
        Library:Notification("Kebun", "Ketik nama dulu!", 2); return
    end
    local pl = infer_plr(ref)
    if not pl then Library:Notification("Kebun", "Player tidak ditemukan!", 3); return end
    if not pl.Character then Library:Notification("Kebun", pl.Name.." tidak ada karakter", 2); return end
    local part = pl.Character:FindFirstChild("HumanoidRootPart")
              or pl.Character:FindFirstChild("Torso")
    if not part then Library:Notification("Kebun", "Karakter tidak valid", 2); return end
    local c = getChar()
    if c then
        c:PivotTo(part.CFrame * CFrame.new(0,3,0))
        Library:Notification("Teleport", "Ke "..pl.Name, 2)
    end
end

local function tpToMouse()
    local mouse = LP:GetMouse()
    if mouse and mouse.Hit then
        local r = getRoot()
        if r then
            r.CFrame = mouse.Hit * CFrame.new(0,3,0)
            Library:Notification("Teleport", "Ke posisi tap", 2)
        end
    end
end

local function quickRespawn()
    local r = getRoot()
    if not r then Library:Notification("Kebun", "Karakter tidak ada", 2); return end
    local cf = r.CFrame; local ws = curWS; local jp = curJP
    local c = getChar(); if c then c:BreakJoints() end
    local conn
    conn = LP.CharacterAdded:Connect(function(nc)
        conn:Disconnect(); task.wait(0.8)
        local hr = nc:WaitForChild("HumanoidRootPart", 5)
        local hm = nc:WaitForChild("Humanoid", 5)
        if hr then hr.CFrame = cf end
        if hm then hm.WalkSpeed = ws; hm.JumpPower = jp; hm.UseJumpPower = true end
        Library:Notification("Respawn", "Kembali ke posisi!", 2)
    end)
end

-- ═══════════════════════════════════════
--  FLY
-- ═══════════════════════════════════════
local function startFly()
    local root = getRoot(); if not root then return end
    local hum  = getHum();  if not hum  then return end
    if flyBV   then pcall(function() flyBV:Destroy()      end) end
    if flyBG   then pcall(function() flyBG:Destroy()      end) end
    if flyConn then pcall(function() flyConn:Disconnect() end) end
    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Velocity = Vector3.new(); flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyBG.P = 1e4; flyBG.D = 100; flyBG.CFrame = root.CFrame
    hum.PlatformStand = true
    flyConn = RunService.Heartbeat:Connect(function()
        local r2 = getRoot(); if not r2 or not flyBV then return end
        local h2 = getHum();  if not h2 then return end
        local cam    = game:GetService("Workspace").CurrentCamera
        local camCF  = cam.CFrame
        local camFwd = Vector3.new(camCF.LookVector.X,0,camCF.LookVector.Z)
        local camRgt = Vector3.new(camCF.RightVector.X,0,camCF.RightVector.Z)
        if camFwd.Magnitude>0 then camFwd=camFwd.Unit end
        if camRgt.Magnitude>0 then camRgt=camRgt.Unit end
        local md = h2.MoveDirection
        local horiz = Vector3.new()
        if md.Magnitude>0.05 then
            horiz = camFwd*md:Dot(camFwd) + camRgt*md:Dot(camRgt)
            if horiz.Magnitude>1 then horiz=horiz.Unit end
        end
        local py = camCF.LookVector.Y
        local vert = Vector3.new()
        if py>PITCH_UP then
            vert = Vector3.new(0, math.min((py-PITCH_UP)/(1-PITCH_UP),1), 0)
        elseif py<PITCH_DOWN then
            vert = Vector3.new(0,-math.min((-py+PITCH_DOWN)/(1+PITCH_DOWN),1),0)
        end
        local dir = horiz+vert
        if dir.Magnitude>0 then
            flyBV.Velocity = (dir.Magnitude>1 and dir.Unit or dir)*flySpeed
            if horiz.Magnitude>0.05 then flyBG.CFrame=CFrame.new(Vector3.new(),horiz) end
        else
            flyBV.Velocity = Vector3.new()
        end
        h2.PlatformStand = true
    end)
end

local function stopFly()
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn=nil end
    if flyBV   then pcall(function() flyBV:Destroy()      end); flyBV=nil   end
    if flyBG   then pcall(function() flyBG:Destroy()      end); flyBG=nil   end
    local hum = getHum(); if hum then hum.PlatformStand=false end
end

-- ═══════════════════════════════════════
--  NOCLIP
-- ═══════════════════════════════════════
local function setNoclip(state)
    noclipOn = state
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local c = getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        local c = getChar()
        if c then
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=true end
            end
        end
    end
end

-- ═══════════════════════════════════════
--  ESP
-- ═══════════════════════════════════════
local function clearESP()
    for _,b in ipairs(espBills) do pcall(function() b:Destroy()    end) end
    for _,c in ipairs(espConns) do pcall(function() c:Disconnect() end) end
    espBills={}; espConns={}
end

local function getArea(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return "?" end
    for _,v in pairs(game:GetService("Workspace"):GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if (n:find("room") or n:find("area") or n:find("zone")
            or n:find("vip") or n:find("priv")) then
                if (v.Position-root.Position).Magnitude<25 then return v.Name end
            end
        end
    end
    return "Kebun"
end

local function makeESP(player)
    if player==LP then return end
    local function onChar(char)
        if not espOn then return end
        task.wait(0.5)
        local head = char:FindFirstChild("Head"); if not head then return end
        local bill = Instance.new("BillboardGui")
        bill.Size=UDim2.new(0,180,0,50); bill.StudsOffset=Vector3.new(0,3,0)
        bill.AlwaysOnTop=true; bill.Adornee=head; bill.Parent=char
        local bg = Instance.new("Frame", bill)
        bg.Size=UDim2.new(1,0,1,0)
        bg.BackgroundColor3=Color3.fromRGB(15,30,15)
        bg.BackgroundTransparency=0.3; bg.BorderSizePixel=0
        Instance.new("UICorner",bg).CornerRadius=UDim.new(0,8)
        local lbl = Instance.new("TextLabel", bg)
        lbl.Size=UDim2.new(1,-6,1,-4); lbl.Position=UDim2.new(0,3,0,2)
        lbl.BackgroundTransparency=1
        lbl.TextColor3=Color3.fromRGB(150,255,100)
        lbl.TextStrokeTransparency=0.2
        lbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
        lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold
        lbl.TextXAlignment=Enum.TextXAlignment.Center
        local upd = RunService.Heartbeat:Connect(function()
            if not bill or not bill.Parent then return end
            local myR = getRoot()
            local d = myR and getDist(head.Position,myR.Position) or 0
            lbl.Text = string.format("🌿 %s\n%dm | %s", player.Name, d, getArea(char))
        end)
        table.insert(espConns,upd); table.insert(espBills,bill)
    end
    if player.Character then onChar(player.Character) end
    table.insert(espConns, player.CharacterAdded:Connect(onChar))
end

local function toggleESP(state)
    espOn=state; clearESP()
    if state then
        for _,p in pairs(Players:GetPlayers()) do makeESP(p) end
        table.insert(espConns, Players.PlayerAdded:Connect(makeESP))
    end
    Library:Notification("ESP", state and "ON" or "OFF", 2)
end

-- ═══════════════════════════════════════
--  PROTECTION
-- ═══════════════════════════════════════
local function startAntiAFK()
    if afkConn then return end
    afkConn = LP.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
local function stopAntiAFK()
    if afkConn then afkConn:Disconnect(); afkConn=nil end
end
local function startAntiKick()
    if antiKickOn then return end
    antiKickOn = true
    task.spawn(function()
        while antiKickOn do
            pcall(function()
                local hum = getHum()
                if hum and hum.Health>0 and hum.Health<hum.MaxHealth*0.1 then
                    hum.Health = hum.MaxHealth
                end
            end)
            task.wait(0.5)
        end
    end)
end
local function stopAntiKick() antiKickOn=false end

-- ═══════════════════════════════════════════════════════
--  WINDOW
-- ═══════════════════════════════════════════════════════
local Win = Library:Window("XKID.HUB", "leaf", "Farming v5.1", false)

Win:TabSection("MAIN")
local TabTP    = Win:Tab("Teleport",   "map-pin")
local TabFly   = Win:Tab("Fly",        "rocket")
local TabESP   = Win:Tab("ESP",        "eye")
local TabSpeed = Win:Tab("Speed",      "zap")
local TabProt  = Win:Tab("Protection", "shield")
local TabFarm  = Win:Tab("Farming",    "leaf")
local TabShop  = Win:Tab("Shop",       "shopping-cart")
local TabWorld = Win:Tab("World",      "sun")

-- ═══════════════════════════════════════
--  UI — TELEPORT
-- ═══════════════════════════════════════
local TPage = TabTP:Page("Teleport", "map-pin")
local TL    = TPage:Section("Cari Player", "Left")
local TR    = TPage:Section("Slot Posisi", "Right")

TL:Button("Lihat Player Online", "Tampilkan semua player",
    function()
        local list, n = "", 0
        for _,p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                local r2 = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local myR = getRoot()
                local d = (r2 and myR) and getDist(r2.Position,myR.Position) or "?"
                n=n+1; list=list..string.format("• %s — %sm\n", p.Name, tostring(d))
            end
        end
        Library:Notification(n.." Player Online", n>0 and list or "Tidak ada player lain", 8)
    end)

local tpInput = ""
TL:TextBox("Nama / Prefix", "TPInput", "",
    function(v) tpInput=v end, "Ketik 1-2 huruf nama player")

TL:Button("Teleport ke Player", "Cari dan TP",
    function() tpToPlayer(tpInput) end)

TL:Button("Teleport ke Mouse", "TP ke posisi tap",
    function() tpToMouse() end)

TL:Button("Respawn Cepat", "Mati lalu spawn di tempat sama",
    function() quickRespawn() end)

TR:Label("Simpan & Load Posisi")
for i=1,5 do
    local idx=i
    TR:Button("Simpan Slot "..idx, "Simpan posisi saat ini",
        function()
            local r=getRoot(); if not r then Library:Notification("Kebun","Karakter tidak ada",2); return end
            slots[idx]=r.CFrame
            local p=r.Position
            Library:Notification("Slot "..idx, string.format("X=%.0f Y=%.0f Z=%.0f",p.X,p.Y,p.Z), 3)
        end)
    TR:Button("Load Slot "..idx, "TP ke slot "..idx,
        function()
            if not slots[idx] then Library:Notification("Kebun","Slot "..idx.." kosong",2); return end
            local r=getRoot()
            if r then
                r.CFrame=slots[idx]
                local p=slots[idx].Position
                Library:Notification("Slot "..idx, string.format("X=%.0f Y=%.0f Z=%.0f",p.X,p.Y,p.Z), 3)
            end
        end)
end

-- ═══════════════════════════════════════
--  UI — FLY
-- ═══════════════════════════════════════
local FPage = TabFly:Page("Fly & NoClip", "rocket")
local FL    = FPage:Section("Fly", "Left")
local FR    = FPage:Section("NoClip", "Right")

FL:Toggle("Fly Mode", "FlyToggle", false, "Aktifkan terbang",
    function(v)
        flyOn=v
        if v then startFly() else stopFly() end
        Library:Notification("Fly", v and "ON" or "OFF", 2)
    end)

FL:Slider("Kecepatan Fly", "FlySpeed", 5, 300, 60,
    function(v) flySpeed=v end, "Default 60")

FL:Slider("Sensitivitas Pitch", "PitchSlider", 1, 9, 3,
    function(v) PITCH_UP=v*0.1; PITCH_DOWN=-v*0.1 end, "Naik/turun kamera")

FL:Paragraph("Cara Terbang",
    "ON kan Fly\n\nGERAK: Joystick\nNAIK: Kamera ke atas\nTURUN: Kamera ke bawah\nMELAYANG: Lepas joystick")

FR:Toggle("NoClip", "NoclipToggle", false, "Tembus semua dinding",
    function(v)
        setNoclip(v)
        Library:Notification("NoClip", v and "ON" or "OFF", 2)
    end)

-- ═══════════════════════════════════════
--  UI — ESP
-- ═══════════════════════════════════════
local EPage = TabESP:Page("ESP Player", "eye")
local EL    = EPage:Section("ESP", "Left")
local ER    = EPage:Section("Info", "Right")

EL:Toggle("ESP Player", "ESPToggle", false, "Lihat player tembus dinding",
    function(v) toggleESP(v) end)

EL:Button("Refresh ESP", "Perbarui ESP",
    function()
        if espOn then
            clearESP(); task.wait(0.2)
            for _,p in pairs(Players:GetPlayers()) do makeESP(p) end
            Library:Notification("ESP", "Refreshed", 2)
        end
    end)

ER:Paragraph("Info ESP",
    "Tampil per player:\nNama player\nJarak (meter)\nArea / lokasi\n\nTembus semua dinding")

-- ═══════════════════════════════════════
--  UI — SPEED
-- ═══════════════════════════════════════
local SPage = TabSpeed:Page("Speed & Jump", "zap")
local SL    = SPage:Section("Speed", "Left")
local SR    = SPage:Section("Jump", "Right")

SL:Slider("Walk Speed", "WSSlider", 1, 500, 16,
    function(v)
        curWS=v; local hum=getHum(); if hum then hum.WalkSpeed=v end
    end, "Default 16")

SL:Button("Reset Speed", "Kembalikan ke 16",
    function()
        curWS=16; local hum=getHum()
        if hum then hum.WalkSpeed=16 end
        Library:Notification("Speed", "Reset ke 16", 2)
    end)

SR:Slider("Jump Power", "JPSlider", 1, 500, 50,
    function(v)
        curJP=v; local hum=getHum()
        if hum then hum.JumpPower=v; hum.UseJumpPower=true end
    end, "Default 50")

SR:Button("Reset Jump", "Kembalikan ke 50",
    function()
        curJP=50; local hum=getHum()
        if hum then hum.JumpPower=50; hum.UseJumpPower=true end
        Library:Notification("Jump", "Reset ke 50", 2)
    end)

SR:Toggle("Infinite Jump", "InfJumpToggle", false, "Lompat terus di udara",
    function(v)
        if v then
            _G.xkid_ij = UIS.JumpRequest:Connect(function()
                local hum=getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if _G.xkid_ij then _G.xkid_ij:Disconnect(); _G.xkid_ij=nil end
        end
        Library:Notification("Inf Jump", v and "ON" or "OFF", 2)
    end)

-- ═══════════════════════════════════════
--  UI — PROTECTION
-- ═══════════════════════════════════════
local PPage = TabProt:Page("Protection", "shield")
local PL    = PPage:Section("Perlindungan", "Left")
local PR    = PPage:Section("Info", "Right")

PL:Toggle("Anti AFK", "AntiAFKToggle", false, "Cegah disconnect otomatis",
    function(v)
        if v then startAntiAFK() else stopAntiAFK() end
        Library:Notification("Anti AFK", v and "ON" or "OFF", 2)
    end)

PL:Toggle("Anti Kick", "AntiKickToggle", false, "Jaga HP dari kick",
    function(v)
        if v then startAntiKick() else stopAntiKick() end
        Library:Notification("Anti Kick", v and "ON" or "OFF", 2)
    end)

PL:Button("Rejoin Server", "Koneksi ulang ke server",
    function()
        Library:Notification("Rejoin", "Menghubungkan ulang...", 3)
        task.wait(1); TpService:Teleport(game.PlaceId, LP)
    end)

PL:Button("Posisi Saya", "Lihat koordinat sekarang",
    function()
        local r=getRoot()
        if r then
            local p=r.Position
            Library:Notification("Posisi",
                string.format("X=%.1f\nY=%.1f\nZ=%.1f",p.X,p.Y,p.Z), 6)
        end
    end)

PR:Paragraph("Keterangan",
    "Anti AFK:\nCegah kick saat idle\n\nAnti Kick:\nJaga HP tetap penuh\n\nRejoin:\nKoneksi ulang cepat")

-- ═══════════════════════════════════════
--  UI — FARMING
-- ═══════════════════════════════════════
local FarmPage = TabFarm:Page("Farming", "leaf")
local FarmL    = FarmPage:Section("Auto Farm", "Left")
local FarmR    = FarmPage:Section("Manual", "Right")

FarmL:Toggle("Auto Farm", "AutoFarmToggle", false,
    "Loop tanam + harvest otomatis",
    function(v)
        if autoFarmConn then autoFarmConn:Disconnect(); autoFarmConn=nil end
        if v then
            autoFarmConn = RunService.Heartbeat:Connect(function()
                task.wait(autoFarmDelay)
                local t = getTut()
                if t then
                    pcall(function() t.PlantCrop:FireServer() end)
                    pcall(function() t.ToggleAutoHarvest:FireServer() end)
                    pcall(function() t.LahanUpdate:FireServer() end)
                end
            end)
        end
        Library:Notification("Auto Farm", v and "ON" or "OFF", 2)
    end)

FarmL:Slider("Delay Farm", "FarmDelay", 1, 10, 1,
    function(v) autoFarmDelay=v end, "Jeda antar loop (detik)")

FarmL:Toggle("Penangkal Petir", "LightningToggle", false,
    "WeatherSync tiap 2 detik",
    function(v)
        if lightConn then lightConn:Disconnect(); lightConn=nil end
        if v then
            lightConn = RunService.Heartbeat:Connect(function()
                task.wait(2)
                local t=getTut()
                if t then
                    pcall(function() t.WeatherSync:FireServer() end)
                    pcall(function() t.HygieneSync:FireServer() end)
                end
            end)
        end
        Library:Notification("Penangkal Petir", v and "ON" or "OFF", 2)
    end)

FarmR:Button("Tanam Tanaman", "PlantCrop",
    function()
        safefire(getTut(), "PlantCrop")
        Library:Notification("Farm", "PlantCrop dikirim!", 2)
    end)

FarmR:Button("Auto Harvest", "ToggleAutoHarvest",
    function()
        safefire(getTut(), "ToggleAutoHarvest")
        Library:Notification("Farm", "AutoHarvest dikirim!", 2)
    end)

FarmR:Button("Ambil Bibit", "GetBibit",
    function()
        safefire(getTut(), "GetBibit")
        Library:Notification("Farm", "GetBibit dikirim!", 2)
    end)

FarmR:Button("Update Lahan", "LahanUpdate",
    function()
        safefire(getTut(), "LahanUpdate")
        Library:Notification("Farm", "LahanUpdate dikirim!", 2)
    end)

FarmR:Button("Buka Storage", "RequestStorage",
    function()
        safeinvoke(getTut(), "RequestStorage")
        Library:Notification("Farm", "RequestStorage dikirim!", 2)
    end)

-- ═══════════════════════════════════════
--  UI — SHOP
-- ═══════════════════════════════════════
local ShopPage = TabShop:Page("Shop", "shopping-cart")
local ShopL    = ShopPage:Section("Toko", "Left")
local ShopR    = ShopPage:Section("Jual & Hadiah", "Right")

ShopL:Button("Buka Toko", "RequestShop",
    function()
        safeinvoke(getTut(), "RequestShop")
        Library:Notification("Shop", "RequestShop dikirim!", 2)
    end)

ShopL:Button("Buka Toko Alat", "RequestToolShop",
    function()
        safeinvoke(getTut(), "RequestToolShop")
        Library:Notification("Shop", "RequestToolShop dikirim!", 2)
    end)

ShopL:Button("Refresh Toko", "RefreshShop",
    function()
        safefire(getTut(), "RefreshShop")
        Library:Notification("Shop", "RefreshShop dikirim!", 2)
    end)

ShopR:Button("Jual Item", "RequestSell",
    function()
        safeinvoke(getTut(), "RequestSell")
        Library:Notification("Shop", "RequestSell dikirim!", 2)
    end)

ShopR:Button("Request Hadiah", "RequestGift",
    function()
        safeinvoke(getTut(), "RequestGift")
        Library:Notification("Shop", "RequestGift dikirim!", 2)
    end)

ShopR:Button("Konfirm Hadiah", "GiftPurchaseDone",
    function()
        safefire(getTut(), "GiftPurchaseDone")
        Library:Notification("Shop", "GiftPurchaseDone dikirim!", 2)
    end)

-- ═══════════════════════════════════════
--  UI — WORLD
-- ═══════════════════════════════════════
local WorldPage = TabWorld:Page("World", "sun")
local WorldL    = WorldPage:Section("Cuaca", "Left")
local WorldR    = WorldPage:Section("Lingkungan", "Right")

WorldL:Button("Panggil Hujan", "SummonRain",
    function()
        safefire(getTut(), "SummonRain")
        Library:Notification("World", "SummonRain dikirim!", 2)
    end)

WorldL:Button("Sync Cuaca", "WeatherSync",
    function()
        safefire(getTut(), "WeatherSync")
        Library:Notification("World", "WeatherSync dikirim!", 2)
    end)

WorldL:Button("Ganti Siang/Malam", "PhaseChanged",
    function()
        safefire(getDN(), "PhaseChanged")
        Library:Notification("World", "PhaseChanged dikirim!", 2)
    end)

WorldR:Toggle("Fullbright", "FullbrightToggle", false, "Terang penuh",
    function(v)
        pcall(function()
            Lighting.Ambient        = v and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,70,70)
            Lighting.OutdoorAmbient = v and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,140,140)
            Lighting.Brightness     = v and 10 or 2
        end)
        Library:Notification("Fullbright", v and "ON" or "OFF", 2)
    end)

WorldR:Slider("Jam", "TimeSlider", 0, 24, 14,
    function(v) pcall(function() Lighting.ClockTime=v end) end, "0-24 jam")

WorldR:Slider("Gravitasi", "GravSlider", 0, 400, 196,
    function(v) pcall(function() game:GetService("Workspace").Gravity=v end) end, "Default 196")

-- ═══════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════
Library:Notification("XKID.HUB", "Farming Edition v5.1 siap!", 4)
Library:ConfigSystem(Win)

print("[XKID.HUB] v5.1 Farming Edition loaded - "..LP.Name)
