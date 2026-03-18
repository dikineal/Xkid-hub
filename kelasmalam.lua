-- XKID HUB MOBILE FINAL - FLY FIXED WITH JOYSTICK CONTROL
-- Kontrol: Joystick = arah horizontal, Kamera Atas = Naik, Kamera Bawah = Turun

local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TpService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")
local LP = Players.LocalPlayer

--------------------------------------------------
-- HELPERS
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
-- SAVE LAST POSITION
--------------------------------------------------

local lastPos = nil

RunService.Stepped:Connect(function()
    local root = getRoot()
    if root then
        lastPos = root.CFrame
    end
end)

--------------------------------------------------
-- WINDOW
--------------------------------------------------

local Win = Library:Window("🌟 XKID HUB", "star", "Mobile Final", false)

Win:TabSection("🛠 HUB")

local TabTP = Win:Tab("📍 Teleport","map-pin")
local TabPl = Win:Tab("👤 Player","user")
local TabProt = Win:Tab("🛡 Protect","shield")

--------------------------------------------------
-- TELEPORT PLAYER
--------------------------------------------------

local TPage = TabTP:Page("Teleport Player","map-pin")
local TL = TPage:Section("Players","Left")

local function refreshPlayerList()
    TL:Clear()
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            TL:Button(p.Name,"Teleport",function()
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
-- PLAYER FEATURES
--------------------------------------------------

local Page = TabPl:Page("Player","user")
local Left = Page:Section("Movement","Left")

--------------------------------------------------
-- SPEED
--------------------------------------------------

local speed = 16

RunService.RenderStepped:Connect(function()
    local hum = getHum()
    if hum then
        hum.WalkSpeed = speed
    end
end)

Left:Slider("Speed","speed",16,80,16,function(v)
    speed = v
end)

--------------------------------------------------
-- NOCLIP
--------------------------------------------------

local noclip = false

RunService.Stepped:Connect(function()
    if noclip then
        local char = getChar()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

Left:Toggle("NoClip","noclip",false,function(v)
    noclip = v
end)

--------------------------------------------------
-- INFINITE JUMP
--------------------------------------------------

local infJump = false

UIS.JumpRequest:Connect(function()
    if infJump then
        local hum = getHum()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

Left:Toggle("Infinite Jump","jump",false,function(v)
    infJump = v
end)

--------------------------------------------------
-- FIXED FLY SYSTEM - Joystick Control
-- Joystick = arah horizontal
-- Kamera Atas = Naik
-- Kamera Bawah = Turun
--------------------------------------------------

local flying = false
local flySpeed = 60
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

-- Fungsi untuk mendapatkan arah kamera (atas/bawah)
local function getCameraTilt()
    local cam = Workspace.CurrentCamera
    if not cam then return 0 end
    
    -- Dapatkan look vector kamera
    local lookVector = cam.CFrame.LookVector
    -- Hitung tilt (nilai positif = kamera melihat ke bawah, negatif = ke atas)
    return -lookVector.Y -- Dibalik: positif = kamera atas, negatif = kamera bawah
end

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
    end
end

local function startFly()
    local root = getRoot()
    local hum = getHum()
    
    if not root or not hum then
        return false
    end
    
    stopFly()
    flying = true
    
    -- Buat BodyVelocity
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0,0,0)
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.P = 1250
    bodyVelocity.Parent = root
    
    -- Buat BodyGyro untuk stabilisasi
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
    bodyGyro.P = 1000
    bodyGyro.D = 50
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root
    
    hum.PlatformStand = true
    
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not root or not hum then
            stopFly()
            return
        end
        
        local cam = Workspace.CurrentCamera
        if not cam then return end
        
        -- Dapatkan move direction dari joystick/humanoid
        local moveDir = hum.MoveDirection
        
        -- Dapatkan arah kamera
        local cameraCF = cam.CFrame
        local forward = cameraCF.LookVector * Vector3.new(1,0,1) -- Flat forward (XZ only)
        local right = cameraCF.RightVector * Vector3.new(1,0,1) -- Flat right (XZ only)
        
        -- Normalisasi
        if forward.Magnitude > 0 then
            forward = forward.Unit
        end
        if right.Magnitude > 0 then
            right = right.Unit
        end
        
        -- Hitung velocity horizontal dari joystick
        local targetVelocity = Vector3.new()
        
        -- Joystick control: maju/mundur (Z) dan kiri/kanan (X)
        if moveDir.Z ~= 0 then
            targetVelocity = targetVelocity + (forward * moveDir.Z * flySpeed)
        end
        if moveDir.X ~= 0 then
            targetVelocity = targetVelocity + (right * moveDir.X * flySpeed)
        end
        
        -- Kontrol naik/turun berdasarkan kamera
        local cameraTilt = getCameraTilt()
        
        -- Threshold untuk menghindari noise
        if math.abs(cameraTilt) > 0.1 then
            -- Kamera atas (tilt positif) = naik
            -- Kamera bawah (tilt negatif) = turun
            local verticalSpeed = cameraTilt * flySpeed * 1.5 -- Scale factor untuk responsif
            targetVelocity = targetVelocity + Vector3.new(0, verticalSpeed, 0)
        end
        
        -- Apply velocity
        if bodyVelocity then
            bodyVelocity.Velocity = targetVelocity
        end
        
        -- Stabilisasi rotasi
        if bodyGyro then
            -- Buat rotasi yang smooth mengikuti arah gerak
            if targetVelocity.Magnitude > 0.1 then
                local lookDirection = targetVelocity.Unit
                bodyGyro.CFrame = CFrame.new(root.Position, root.Position + lookDirection)
            else
                -- Jika diam, pertahankan rotasi terakhir
                bodyGyro.CFrame = bodyGyro.CFrame
            end
        end
    end)
    
    return true
end

Left:Toggle("Fly (Joystick)","fly",false,function(v)
    if v then
        local success = startFly()
        if not success then
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

Left:Button("Stop Fly","Matikan mode terbang",function()
    stopFly()
end)

--------------------------------------------------
-- SIMPLE ESP - Hanya Nama dan Jarak
--------------------------------------------------

local espEnabled = false
local espObjects = {}
local espConnections = {}

local function clearESP()
    for _, obj in pairs(espObjects) do
        pcall(function() obj:Destroy() end)
    end
    espObjects = {}
    
    for _, conn in pairs(espConnections) do
        conn:Disconnect()
    end
    espConnections = {}
end

local function createESP(player)
    if player == LP then return end
    
    local function addESP(char)
        if not espEnabled then return end
        
        -- Tunggu head
        local head = char:WaitForChild("Head", 5)
        if not head then return end
        
        -- Buat BillboardGui sederhana
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "XKID_ESP"
        billboard.Size = UDim2.new(0, 150, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = head
        billboard.Parent = head
        
        -- Text label untuk nama dan jarak
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextSize = 14
        textLabel.TextScaled = true
        textLabel.Parent = billboard
        
        table.insert(espObjects, billboard)
        
        -- Update jarak setiap frame
        local conn = RunService.RenderStepped:Connect(function()
            if not espEnabled or not billboard or not billboard.Parent then
                conn:Disconnect()
                return
            end
            
            local myRoot = getRoot()
            if myRoot and char and char:FindFirstChild("HumanoidRootPart") then
                local targetRoot = char.HumanoidRootPart
                local distance = (targetRoot.Position - myRoot.Position).Magnitude
                textLabel.Text = string.format("%s [%.1fm]", player.Name, distance)
            else
                textLabel.Text = player.Name .. " [?m]"
            end
        end)
        
        table.insert(espConnections, conn)
    end
    
    if player.Character then
        addESP(player.Character)
    end
    
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        if espEnabled then
            addESP(char)
        end
    end)
end

Left:Toggle("ESP (Nama + Jarak)","esp",false,function(v)
    espEnabled = v
    
    if v then
        clearESP()
        for _, player in pairs(Players:GetPlayers()) do
            createESP(player)
        end
    else
        clearESP()
    end
end)

--------------------------------------------------
-- PROTECTION
--------------------------------------------------

local PPage = TabProt:Page("Protection","shield")
local PL = PPage:Section("Safety","Left")

-- Anti AFK
PL:Toggle("Anti AFK","afk",false,function(v)
    if v then
        LP.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- Respawn
PL:Button("Respawn","Respawn ke posisi terakhir",function()
    local saved = lastPos
    local char = LP.Character
    
    if char then
        char:BreakJoints()
    end
    
    LP.CharacterAdded:Connect(function(newChar)
        task.wait(1.5)
        local hrp = newChar:WaitForChild("HumanoidRootPart", 10)
        if hrp and saved then
            hrp.CFrame = saved
        end
    end)
end)

-- Rejoin
PL:Button("Rejoin","Rejoin Server",function()
    TpService:Teleport(game.PlaceId, LP)
end)

-- Reset Character
PL:Button("Reset Character","Respawn di tempat",function()
    local char = LP.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Health = 0
    end
end)

Library:Notification("XKID HUB","✓ Fly: Joystick = horizontal, Kamera Atas = Naik, Kamera Bawah = Turun\n✓ ESP: Nama + Jarak",8)
Library:ConfigSystem(Win)

-- Cleanup
game:BindToClose(function()
    stopFly()
    clearESP()
end)