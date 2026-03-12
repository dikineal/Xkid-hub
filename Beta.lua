-- XKID EXPLOIT LITE - PASTI JALAN DI DELTA
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Aurora.lua"))()
local Win = Library:Window("XKID EXPLOIT", "skull", "Lite v1.0", false)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Notifikasi
local function notif(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "XKID",
            Text = msg,
            Duration = 3
        })
    end)
end

notif("Loader berhasil!")

-- ============================================
-- UNIVERSAL EXPLOITS (PASTI JALAN)
-- ============================================

-- Noclip
local noclip = false
local noclipConn = nil

-- Fly
local fly = false
local flyConn = nil
local flyVel = nil

-- Speed
local speed = 16

-- ============================================
-- UI
-- ============================================
local MainTab = Win:Tab("Main", "zap")
local MainPage = MainTab:Page("Exploits", "zap")
local MainLeft = MainPage:Section("Movement", "Left")
local MainRight = MainPage:Section("Info", "Right")

-- Noclip toggle
MainLeft:Toggle("Noclip", "noclipToggle", false, "Tembus dinding", function(v)
    noclip = v
    if noclipConn then noclipConn:Disconnect() end
    if v then
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        notif("Noclip ON")
    else
        notif("Noclip OFF")
    end
end)

-- Fly toggle
MainLeft:Toggle("Fly", "flyToggle", false, "Terbang (WASD + Spasi/Ctrl)", function(v)
    fly = v
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyVel then flyVel:Destroy(); flyVel = nil end
    
    if v and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            flyVel = Instance.new("BodyVelocity")
            flyVel.Velocity = Vector3.new(0, 0, 0)
            flyVel.MaxForce = Vector3.new(4000, 4000, 4000)
            flyVel.Parent = root
            
            flyConn = RunService.Heartbeat:Connect(function()
                if not fly or not LocalPlayer.Character then return end
                local move = Vector3.new()
                local cam = Workspace.CurrentCamera
                
                if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
                
                if move.Magnitude > 0 then
                    flyVel.Velocity = move.Unit * 50
                else
                    flyVel.Velocity = Vector3.new(0, 0, 0)
                end
            end)
        end
        notif("Fly ON")
    else
        notif("Fly OFF")
    end
end)

-- Speed slider
MainLeft:Slider("WalkSpeed", "speedSlider", 16, 500, 16, function(v)
    speed = v
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)

-- Jump slider
MainLeft:Slider("JumpPower", "jumpSlider", 50, 500, 50, function(v)
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
end)

-- Infinite jump
local infJump = false
MainLeft:Toggle("Infinite Jump", "infJumpToggle", false, "Lompat di udara", function(v)
    infJump = v
    if v then
        UIS.JumpRequest:Connect(function()
            if infJump and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
        notif("Infinite Jump ON")
    else
        notif("Infinite Jump OFF")
    end
end)

-- Teleport ke mouse
MainLeft:Button("📍 Teleport ke Mouse", "Pindah ke posisi kursor", function()
    local mouse = LocalPlayer:GetMouse()
    if mouse and mouse.Hit and LocalPlayer.Character then
        LocalPlayer.Character:SetPrimaryPartCFrame(mouse.Hit + Vector3.new(0, 3, 0))
        notif("Teleport")
    end
end)

-- Info
MainRight:Paragraph("Info", "XKID EXPLOIT LITE\n\nFitur:\n✅ Noclip\n✅ Fly\n✅ Speed\n✅ Jump\n✅ Infinite Jump\n✅ Teleport Mouse\n\nPastikan karakter sudah spawn!")

-- ============================================
-- REMOTE SCANNER (OPSIONAL)
-- ============================================
local RemoteTab = Win:Tab("Remote", "radio")
local RemotePage = RemoteTab:Page("Scanner", "radio")
local RemoteLeft = RemotePage:Section("Scan", "Left")
local RemoteRight = RemotePage:Section("Hasil", "Right")

RemoteLeft:Button("🔍 Scan Remote", "Cari semua remote", function()
    local count = 0
    print("=== REMOTE DI REPLICATEDSTORAGE ===")
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            print(v.ClassName .. ": " .. v.Name)
            count = count + 1
        end
    end
    notif("Ditemukan " .. count .. " remote (cek console)")
end)

RemoteLeft:Button("📋 Cek ReplicatedStorage", "Lihat isi folder", function()
    print("=== ISI REPLICATEDSTORAGE ===")
    for _, v in pairs(RS:GetChildren()) do
        print(v.Name .. " (" .. v.ClassName .. ")")
    end
end)

-- ============================================
-- CREDITS
-- ============================================
notif("XKID EXPLOIT LITE", "Siap digunakan!")

Library:ConfigSystem(Win)