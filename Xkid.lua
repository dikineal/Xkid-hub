local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🔥 XKID HUB MOBILE v2.0 🔥",
    LoadingTitle = "XKID HUB",
    LoadingSubtitle = "Stable Edition",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local MainTab = Window:CreateTab("🏠 Main", nil)
local PlayerTab = Window:CreateTab("👤 Player", nil)
local TPTab = Window:CreateTab("🏝 Teleport", nil)
local MiscTab = Window:CreateTab("🎲 Misc", nil)

Rayfield:Notify({
    Title = "XKID HUB",
    Content = "Stable v2.0 Loaded",
    Duration = 5
})

------------------------------------------------
-- ✅ ANTI AFK (STABIL)
------------------------------------------------
_G.AntiAFK = false

MainTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Callback = function(v)
        _G.AntiAFK = v
    end
})

LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end
end)

------------------------------------------------
-- ✅ INFINITE JUMP (STABIL)
------------------------------------------------
_G.InfiniteJump = false

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        _G.InfiniteJump = v
    end
})

UIS.JumpRequest:Connect(function()
    if _G.InfiniteJump then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

------------------------------------------------
-- ✅ FLY MOBILE (FIXED - STABIL)
------------------------------------------------
_G.Flying = false
_G.FlySpeed = 3
local FlyBV = nil

MainTab:CreateSlider({
    Name = "Fly Speed",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 3,
    Callback = function(v)
        _G.FlySpeed = v
    end
})

MainTab:CreateToggle({
    Name = "Fly (Mobile)",
    CurrentValue = false,
    Callback = function(v)
        _G.Flying = v
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        if v then
            FlyBV = Instance.new("BodyVelocity")
            FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            FlyBV.Parent = hrp
        else
            if FlyBV then
                FlyBV:Destroy()
                FlyBV = nil
            end
        end
    end
})

RunService.RenderStepped:Connect(function()
    if _G.Flying and FlyBV and LocalPlayer.Character then
        local char = LocalPlayer.Character
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local moveDir = humanoid.MoveDirection
            FlyBV.Velocity = moveDir * (40 * _G.FlySpeed)
        end
    end
end)

------------------------------------------------
-- ✅ NOCLIP (OPTIMIZED - STABIL)
------------------------------------------------
_G.Noclip = false

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        _G.Noclip = v
    end
})

RunService.Stepped:Connect(function()
    if _G.Noclip and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

------------------------------------------------
-- ✅ ESP PLAYER (FIXED - AUTO UPDATE)
------------------------------------------------
_G.ESP = false
local ESPHighlights = {}

local function AddESP(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "XKIDESP"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Parent = player.Character
    ESPHighlights[player] = highlight
end

local function RemoveESP(player)
    if ESPHighlights[player] then
        ESPHighlights[player]:Destroy()
        ESPHighlights[player] = nil
    end
end

MainTab:CreateToggle({
    Name = "ESP Player",
    CurrentValue = false,
    Callback = function(v)
        _G.ESP = v
        if v then
            for _, p in pairs(Players:GetPlayers()) do
                AddESP(p)
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                RemoveESP(p)
            end
        end
    end
})

Players.PlayerAdded:Connect(function(player)
    if _G.ESP then
        player.CharacterAdded:Connect(function()
            wait(1)
            AddESP(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

------------------------------------------------
-- ✅ WALKSPEED & JUMPPOWER (STABIL)
------------------------------------------------
PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
})

PlayerTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 200},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v end
        end
    end
})

------------------------------------------------
-- ✅ TELEPORT & SPECTATE (FIXED - BUTTON BASED)
------------------------------------------------
local SelectedPlayer = nil

TPTab:CreateInput({
    Name = "Player Name",
    PlaceholderText = "Type exact name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        SelectedPlayer = text
    end
})

TPTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if not SelectedPlayer then return end
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
        end
    end
})

TPTab:CreateButton({
    Name = "Spectate Player",
    Callback = function()
        if not SelectedPlayer then return end
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character then
            workspace.CurrentCamera.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid")
        end
    end
})

TPTab:CreateButton({
    Name = "Stop Spectate",
    Callback = function()
        if LocalPlayer.Character then
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
    end
})

------------------------------------------------
-- ✅ INFINITE YIELD (STABIL)
------------------------------------------------
MiscTab:CreateButton({
    Name = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})

------------------------------------------------
-- ✅ FREECAM MOBILE (STABIL)
------------------------------------------------
_G.Freecam = false

MiscTab:CreateToggle({
    Name = "Freecam Mobile",
    CurrentValue = false,
    Callback = function(v)
        _G.Freecam = v
        local cam = workspace.CurrentCamera
        
        if v then
            cam.CameraType = Enum.CameraType.Scriptable
            RunService:BindToRenderStep("Freecam", 0, function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        cam.CFrame = cam.CFrame + hum.MoveDirection * 2
                    end
                end
            end)
        else
            RunService:UnbindFromRenderStep("Freecam")
            cam.CameraType = Enum.CameraType.Custom
            if LocalPlayer.Character then
                cam.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            end
        end
    end
})

------------------------------------------------
-- ✅ REJOIN & SERVER HOP (STABIL)
------------------------------------------------
MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end
})

MiscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local Http = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local servers = Http:JSONDecode(game:HttpGet(url))
        
        for _, s in pairs(servers.data) do
            if s.playing < s.maxPlayers then
                TPS:TeleportToPlaceInstance(game.PlaceId, s.id)
                break
            end
        end
    end
})

------------------------------------------------
-- ✅ FULL BRIGHT (STABIL)
------------------------------------------------
MiscTab:CreateButton({
    Name = "Full Bright",
    Callback = function()
        local L = game.Lighting
        L.Brightness = 2
        L.ClockTime = 14
        L.FogEnd = 100000
        L.GlobalShadows = false
    end
})

------------------------------------------------
-- ✅ RESET CHARACTER
------------------------------------------------
MiscTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end
})

print("XKID HUB MOBILE v2.0 STABLE LOADED")
