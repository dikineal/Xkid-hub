-- XKID HUB v2.0 | Compact | Crimson-Pink Gradient | GitHub Icon
local VERSION = "2.0.0"

-- Auto Update Check (minimal)
pcall(function()
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local res = req({Url = "https://raw.githubusercontent.com/XKID/HUB/main/version.txt", Method = "GET"})
        if res.StatusCode == 200 and res.Body:gsub("%s+","") ~= VERSION then
            print("[XKID] Update available. Restart to apply.")
        end
    end
end)

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Services
local Rs, Pl, Ui, Lp, Cam, Cg = game:GetService("RunService"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("Players").LocalPlayer, workspace.CurrentCamera, game:GetService("CoreGui")

-- State
local S = {ws=16,jp=50,flyS=60,fly=false,ncp=false,esp=false,shiftLock=false,afk=false}

-- Helpers
local root = function() return Lp.Character and Lp.Character:FindFirstChild("HumanoidRootPart") end
local hum = function() return Lp.Character and Lp.Character:FindFirstChildOfClass("Humanoid") end

-- ===== THEME: CRIMSON TO PINK GRADIENT =====
WindUI:AddTheme({
    Name = "XKID_Pink",
    Background = Color3.fromRGB(16,16,16),
    Dialog = Color3.fromRGB(22,22,22),
    Text = Color3.new(1,1,1),
    Icon = Color3.fromRGB(200,200,200),
    Accent = WindUI:Gradient({
        ["0"] = {Color = Color3.fromRGB(220,20,60)},
        ["50"] = {Color = Color3.fromRGB(255,50,120)},
        ["100"] = {Color = Color3.fromRGB(255,130,180)},
    }, {Rotation = 45}),
})
WindUI:SetTheme("XKID_Pink")

-- Main Window
local Win = WindUI:CreateWindow({Title="XKID HUB", Icon="github", Author="WTF.XKID", Folder="XKID", Size=UDim2.fromOffset(360,320), SideBarWidth=140})

-- Open Button with GitHub Icon
Win:EditOpenButton({Title="XKID", Icon="github", CornerRadius=UDim.new(1,0), StrokeThickness=2, StrokeColor=Color3.fromRGB(255,80,140), Scale=0.72})

-- ===== TABS & FEATURES =====
local T = {
    Char = Win:Tab({Title="Char", Icon="user"}),
    Vis = Win:Tab({Title="Vis", Icon="eye"}),
    Misc = Win:Tab({Title="Misc", Icon="settings"}),
}

-- CHARACTER TAB
local secMove = T.Char:Section({Title="Movement", Box=true})
secMove:Slider({Title="WalkSpeed", Min=16, Max=500, Default=16, Callback=function(v) S.ws=v; if hum() then hum().WalkSpeed=v end end})
secMove:Slider({Title="JumpPower", Min=50, Max=500, Default=50, Callback=function(v) S.jp=v; local h=hum(); if h then h.UseJumpPower=true; h.JumpPower=v end end})
secMove:Toggle({Title="Infinite Jump", Callback=function(v) if v then local c; c=Ui.JumpRequest:Connect(function() if hum() then hum():ChangeState(Enum.HumanoidStateType.Jumping) end end); else pcall(function() c:Disconnect() end) end end})
secMove:Toggle({Title="NoClip", Callback=function(v) S.ncp=v; local c; if v then c=Rs.Heartbeat:Connect(function() if S.ncp and Lp.Character then for _,p in pairs(Lp.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end) else if c then c:Disconnect() end end end})

local secFly = T.Char:Section({Title="Flight", Box=true})
secFly:Toggle({Title="Fly", Callback=function(v)
    S.fly=v
    if v then
        local hrp, h = root(), hum()
        if hrp and h then
            h.PlatformStand=true
            local bv=Instance.new("BodyVelocity",hrp); bv.MaxForce=Vector3.new(9e9,9e9,9e9)
            local bg=Instance.new("BodyGyro",hrp); bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.P=50000
            local vel=Vector3.zero
            local keys={}
            local down, up = Ui.InputBegan:Connect(function(i) keys[i.KeyCode]=true end), Ui.InputEnded:Connect(function(i) keys[i.KeyCode]=nil end)
            Rs:BindToRenderStep("XKIDFly", 200, function()
                if not S.fly then return end
                local cf=Cam.CFrame
                local move=Vector3.new()
                if keys[Enum.KeyCode.W] then move=move+cf.LookVector end
                if keys[Enum.KeyCode.S] then move=move-cf.LookVector end
                if keys[Enum.KeyCode.D] then move=move+cf.RightVector end
                if keys[Enum.KeyCode.A] then move=move-cf.RightVector end
                if keys[Enum.KeyCode.E] then move=move+Vector3.new(0,1,0) end
                if keys[Enum.KeyCode.Q] then move=move-Vector3.new(0,1,0) end
                if move.Magnitude>0 then vel=vel:Lerp(move.Unit*S.flyS,0.15) else vel=vel:Lerp(Vector3.zero,0.08) end
                if bv and bv.Parent then bv.Velocity=vel end
                if bg and bg.Parent then bg.CFrame=CFrame.new(hrp.Position, hrp.Position+cf.LookVector) end
            end)
        end
    else
        Rs:UnbindFromRenderStep("XKIDFly")
        local h=hum()
        if h then h.PlatformStand=false; h.WalkSpeed=S.ws end
    end
end})
secFly:Slider({Title="Fly Speed", Min=10, Max=300, Default=60, Callback=function(v) S.flyS=v end})

-- VISUALS TAB
local secESP = T.Vis:Section({Title="ESP", Box=true})
secESP:Toggle({Title="Enable ESP", Callback=function(v) S.esp=v end})
-- (ESP simplified - full ESP from original can be added)

local secFilter = T.Vis:Section({Title="Filter", Box=true})
secFilter:Dropdown({Title="Preset", Values={"Default","Crimson Pink","Night","Full Bright"}, Callback=function(sel)
    if sel=="Crimson Pink" then
        local cc=Instance.new("ColorCorrectionEffect",game:GetService("Lighting"))
        cc.TintColor=Color3.fromRGB(255,130,180)
        cc.Saturation=0.15
    elseif sel=="Night" then
        game:GetService("Lighting").ClockTime=1
    elseif sel=="Full Bright" then
        game:GetService("Lighting").Brightness=3
        game:GetService("Lighting").ClockTime=14
    else
        for _,v in pairs(game:GetService("Lighting"):GetChildren()) do if v:IsA("ColorCorrectionEffect") then v:Destroy() end end
        game:GetService("Lighting").Brightness=1
        game:GetService("Lighting").ClockTime=14
    end
end})

-- MISC TAB
local secProt = T.Misc:Section({Title="Protection", Box=true})
secProt:Toggle({Title="Anti AFK", Callback=function(v)
    S.afk=v
    local thread
    if v then
        thread = task.spawn(function()
            while S.afk do
                pcall(function()
                    if game:GetService("VirtualUser") then
                        game:GetService("VirtualUser"):ClickButton2(Vector2.new(0,0))
                    else
                        Cam.CFrame = Cam.CFrame * CFrame.Angles(0,0.05,0)
                        task.wait(0.1)
                        Cam.CFrame = Cam.CFrame * CFrame.Angles(0,-0.05,0)
                    end
                end)
                for i=1,55 do if not S.afk then break end task.wait(1) end
            end
        end)
    else
        if thread then task.cancel(thread) end
    end
end})
secProt:Button({Title="Server Hop", Callback=function()
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local res = req({Url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100", Method="GET"})
        if res.StatusCode==200 then
            local data = HttpService:JSONDecode(res.Body)
            for _,v in pairs(data.data) do
                if v.playing < v.maxPlayers and v.id ~= game.JobId then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, Lp)
                    break
                end
            end
        end
    end
end})

secProt:Toggle({Title="Shift Lock", Callback=function(v)
    S.shiftLock=v
    local gyro
    if v then
        gyro=Instance.new("BodyGyro", root())
        gyro.MaxTorque=Vector3.new(9e9,9e9,9e9)
        gyro.P=50000
        Rs:BindToRenderStep("XKIDShiftLock", 201, function()
            if not S.shiftLock or not gyro.Parent then return end
            local flat = Vector3.new(Cam.CFrame.LookVector.X, 0, Cam.CFrame.LookVector.Z)
            if flat.Magnitude>0.01 then
                gyro.CFrame = CFrame.new(root().Position, root().Position+flat)
            end
        end)
    else
        Rs:UnbindFromRenderStep("XKIDShiftLock")
        if gyro then gyro:Destroy() end
    end
end})

-- Info display
local infoSec = T.Misc:Section({Title="Info", Box=true})
infoSec:Paragraph({Title="Status", Desc="XKID HUB v"..VERSION.."\nCrimson Pink Theme\nGitHub Icon"})

print("[XKID] Loaded v"..VERSION)