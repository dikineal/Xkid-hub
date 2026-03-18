-- XKID HUB MOBILE FINAL - FIXED VERSION
-- Semua fitur telah diperbaiki: Fly, Noclip, Infinite Jump

local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

--------------------------------------------------
-- FIXED HELPERS
--------------------------------------------------

local function getChar()
    return LP.Character
end

local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

--------------------------------------------------
-- FIXED SAVE LAST POSITION
--------------------------------------------------

local lastPos = nil

-- Gunakan Stepped agar lebih stabil
RunService.Stepped:Connect(function()
    local root = getRoot()
    if root then
        lastPos = root.CFrame
    end
end)

--------------------------------------------------
-- WINDOW
--------------------------------------------------

local Win = Library:Window("🌟 XKID HUB FIXED", "star", "Mobile Final", false)

Win:TabSection("🛠 HUB FIXED")

local TabTP = Win:Tab("📍 Teleport","map-pin")
local TabPl = Win:Tab("👤 Player","user")
local TabProt = Win:Tab("🛡 Protect","shield")

--------------------------------------------------
-- FIXED TELEPORT PLAYER
--------------------------------------------------

local TPage = TabTP:Page("Teleport Player","map-pin")
local TL = TPage:Section("Players","Left")

-- Refresh player list
local function refreshPlayerList()
    TL:Clear()
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            TL:Button(p.Name,"Teleport ke "..p.Name,function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local root = getRoot()
                    if root then
                        root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,5,0)
                    end
                end
            end)
        end
    end
end

refreshPlayerList()

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

--------------------------------------------------
-- FIXED PLAYER FEATURES
--------------------------------------------------

local Page = TabPl:Page("Player","user")
local Left = Page:Section("Movement","Left")

--------------------------------------------------
-- FIXED SPEED
--------------------------------------------------

local speed = 16
local speedConnection

local function updateSpeed()
    local hum = getHum()
    if hum then
        hum.WalkSpeed = speed
    end
end

speedConnection = RunService.RenderStepped:Connect(updateSpeed)

Left:Slider("Speed","speed",16,80,16,function(v)
    speed = v
    updateSpeed()
end)

--------------------------------------------------
-- FIXED NOCLIP
--------------------------------------------------

local noclip = false
local noclipConnection

local function noclipHandler()
    if noclip then
        local char = getChar()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end

noclipConnection = RunService.Stepped:Connect(noclipHandler)

Left:Toggle("NoClip","noclip",false,function(v)
    noclip = v
    if not v then
        -- Reset collision saat dimatikan
        local char = getChar()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end)

--------------------------------------------------
-- FIXED INFINITE JUMP
--------------------------------------------------

local infJump = false

-- Fix Infinite Jump dengan metode yang lebih reliable
UIS.JumpRequest:Connect(function()
    if infJump then
        local hum = getHum()
        if hum and hum.Health > 0 then
            -- Gunakan ChangeState untuk jump yang lebih stabil
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            -- Tambahan untuk memastikan jump terjadi
            task.wait()
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

Left:Toggle("Infinite Jump","infjump",false,function(v)
    infJump = v
end)

--------------------------------------------------
-- FIXED FLY SYSTEM - Complete rewrite
--------------------------------------------------

local flying = false
local flySpeed = 60
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

local function stopFly()
    flying = false
    
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    
    local hum = getHum()
    if hum then
        hum.PlatformStand = false
        -- Kembalikan physics normal
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    local root = getRoot()
    if root and root:FindFirstChildOfClass("BodyVelocity") then
        root:FindFirstChildOfClass("BodyVelocity"):Destroy()
    end
    if root and root:FindFirstChildOfClass("BodyGyro") then
        root:FindFirstChildOfClass("BodyGyro"):Destroy()
    end
end

local function startFly()
    local root = getRoot()
    local hum = getHum()
    
    if not root or not hum then
        warn("Cannot fly: No character or root part")
        return false
    end
    
    -- Bersihkan yang lama dulu
    stopFly()
    
    -- Set flying true dulu
    flying = true
    
    -- Buat BodyVelocity baru
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0,0,0)
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.P = 1250
    bodyVelocity.Parent = root
    
    -- Buat BodyGyro untuk kontrol rotasi
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
    bodyGyro.P = 1000
    bodyGyro.D = 50
    bodyGyro.Parent = root
    
    -- Set platform stand
    hum.PlatformStand = true
    
    -- Connection untuk update fly
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not root or not hum then
            stopFly()
            return
        end
        
        local cam = Workspace.CurrentCamera
        if not cam then return end
        
        -- Dapatkan input movement
        local moveDir = hum.MoveDirection
        
        -- Hitung arah terbang berdasarkan kamera
        local cameraCF = cam.CFrame
        local forward = cameraCF.LookVector * Vector3.new(1,0,1)
        local right = cameraCF.RightVector * Vector3.new(1,0,1)
        local up = Vector3.new(0,1,0)
        
        -- Normalisasi forward vector
        if forward.Magnitude > 0 then
            forward = forward.Unit
        end
        
        -- Hitung velocity
        local targetVelocity = Vector3.new()
        
        -- Movement horizontal
        if moveDir.Z ~= 0 then
            targetVelocity = targetVelocity + (forward * moveDir.Z * flySpeed)
        end
        if moveDir.X ~= 0 then
            targetVelocity = targetVelocity + (right * moveDir.X * flySpeed)
        end
        
        -- Vertical movement (Space untuk naik, Ctrl untuk turun)
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            targetVelocity = targetVelocity + (up * flySpeed)
        elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.C) then
            targetVelocity = targetVelocity - (up * flySpeed)
        end
        
        -- Apply velocity
        if bodyVelocity then
            bodyVelocity.Velocity = targetVelocity
        end
        
        -- Maintain rotation sesuai kamera
        if bodyGyro then
            bodyGyro.CFrame = CFrame.new(root.Position, root.Position + cameraCF.LookVector)
        end
    end)
    
    return true
end

-- Toggle Fly dengan handling yang lebih baik
Left:Toggle("Fly","fly",false,function(v)
    if v then
        local success = startFly()
        if not success then
            -- Coba lagi setelah character spawn
            LP.CharacterAdded:Once(function()
                task.wait(1)
                startFly()
            end)
        end
    else
        stopFly()
    end
end)

Left:Slider("Fly Speed","flyspeed",10,200,60,function(v)
    flySpeed = v
end)

-- Tambahkan button untuk stop fly manual
Left:Button("Stop Fly","Matikan mode terbang",function()
    stopFly()
    -- Update toggle state
    for _,toggle in pairs(Left:GetChildren()) do
        if toggle:IsA("Toggle") and toggle.Title == "Fly" then
            toggle:Set(false)
            break
        end
    end
end)

--------------------------------------------------
-- FIXED ESP
--------------------------------------------------

local espEnabled = false
local espList = {}
local espConnections = {}

local function clearESP()
    for _, v in pairs(espList) do
        pcall(function() v:Destroy() end)
    end
    espList = {}
    
    for _, conn in pairs(espConnections) do
        conn:Disconnect()
    end
    espConnections = {}
end

local function createESP(plr)
    if plr == LP then return end
    
    local function setupESP(char)
        if not espEnabled then return end
        
        local head = char:WaitForChild("Head", 5)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        
        if not head or not root or not hum then return end
        
        -- Create BillboardGui
        local gui = Instance.new("BillboardGui")
        gui.Size = UDim2.new(0, 200, 0, 50)
        gui.StudsOffset = Vector3.new(0, 3, 0)
        gui.AlwaysOnTop = true
        gui.Adornee = head
        gui.Parent = head
        
        -- Name Label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextScaled = true
        nameLabel.Text = plr.Name
        nameLabel.Parent = gui
        
        -- Health Label
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
        healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
        healthLabel.BackgroundTransparency = 1
        healthLabel.TextColor3 = Color3.new(0, 1, 0)
        healthLabel.TextStrokeTransparency = 0
        healthLabel.Font = Enum.Font.SourceSans
        healthLabel.TextScaled = true
        healthLabel.Parent = gui
        
        table.insert(espList, gui)
        
        -- Update health dan distance
        local conn = RunService.Heartbeat:Connect(function()
            if not espEnabled or not gui or not gui.Parent then 
                conn:Disconnect()
                return 
            end
            
            if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local myRoot = LP.Character.HumanoidRootPart
                local dist = (root.Position - myRoot.Position).Magnitude
                
                -- Update health color based on health percentage
                local healthPercent = hum.Health / hum.MaxHealth
                healthLabel.TextColor3 = Color3.new(1 - healthPercent, healthPercent, 0)
                healthLabel.Text = string.format("[%.1f❤️] %.1fm", hum.Health, dist)
            end
        end)
        
        table.insert(espConnections, conn)
    end
    
    if plr.Character then
        setupESP(plr.Character)
    end
    
    plr.CharacterAdded:Connect(function(char)
        task.wait(1)
        if espEnabled then
            setupESP(char)
        end
    end)
end

Left:Toggle("ESP Player","esp",false,function(v)
    espEnabled = v
    
    if v then
        clearESP()
        for _, p in pairs(Players:GetPlayers()) do
            createESP(p)
        end
    else
        clearESP()
    end
end)

--------------------------------------------------
-- FIXED PROTECTION
--------------------------------------------------

local PPage = TabProt:Page("Protection","shield")
local PL = PPage:Section("Safety","Left")

-- Fixed Anti AFK
local antiAfk = false
local antiAfkConnection

PL:Toggle("Anti AFK","afk",false,function(v)
    antiAfk = v
    
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end
    
    if v then
        antiAfkConnection = LP.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- Fixed Respawn
PL:Button("Respawn","Respawn ke posisi terakhir",function()
    local saved = lastPos
    local char = LP.Character
    
    if char then
        char:BreakJoints()
    end
    
    LP.CharacterAdded:Connect(function(newChar)
        task.wait(1.5) -- Tunggu loading
        
        local hrp = newChar:WaitForChild("HumanoidRootPart", 10)
        if hrp and saved then
            hrp.CFrame = saved
        end
    end)
end)

-- Fixed Rejoin
PL:Button("Rejoin","Rejoin Server",function()
    TpService:Teleport(game.PlaceId, LP)
end)

-- Tambahan: Button Reset Character
PL:Button("Reset Character","Respawn di tempat",function()
    local char = LP.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Health = 0
    end
end)

Library:Notification("XKID HUB FIXED","Semua fitur telah diperbaiki! ✓",5)
Library:ConfigSystem(Win)

-- Cleanup saat script berhenti
game:BindToClose(function()
    stopFly()
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
    end
    if speedConnection then
        speedConnection:Disconnect()
    end
    if noclipConnection then
        noclipConnection:Disconnect()
    end
    clearESP()
end)