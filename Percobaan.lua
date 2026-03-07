-- LOAD UI LIBRARY
local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

-- SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- WAIT CHARACTER
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

-- WINDOW
local Window = Fluent:CreateWindow({
    Title = "DIKI PROJECT",
    SubTitle = "Premium",
    TabWidth = 160,
    Size = UDim2.fromOffset(580,460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- TABS
local Tabs = {
    Player = Window:AddTab({Title="Player",Icon="user"}),
    Troll = Window:AddTab({Title="Troll",Icon="zap"}),
    Misc = Window:AddTab({Title="Misc",Icon="box"})
}

------------------------------------------------
-- WALK SPEED
------------------------------------------------

Tabs.Player:AddSlider("Speed",{
    Title="WalkSpeed",
    Default=16,
    Min=16,
    Max=200,
    Rounding=1,

    Callback=function(v)

        local char=getChar()
        local hum=char:FindFirstChildOfClass("Humanoid")

        if hum then
            hum.WalkSpeed=v
        end

    end
})

------------------------------------------------
-- JUMP POWER
------------------------------------------------

Tabs.Player:AddSlider("Jump",{
    Title="JumpPower",
    Default=50,
    Min=50,
    Max=200,
    Rounding=1,

    Callback=function(v)

        local char=getChar()
        local hum=char:FindFirstChildOfClass("Humanoid")

        if hum then
            hum.JumpPower=v
        end

    end
})

------------------------------------------------
-- INFINITE JUMP
------------------------------------------------

local InfJump=false

Tabs.Player:AddToggle("InfJump",{Title="Infinite Jump"}):OnChanged(function(v)
    InfJump=v
end)

UIS.JumpRequest:Connect(function()

    if InfJump then

        local char=getChar()
        local hum=char:FindFirstChildOfClass("Humanoid")

        if hum then
            hum:ChangeState("Jumping")
        end

    end

end)

------------------------------------------------
-- NOCLIP
------------------------------------------------

local noclip=false

Tabs.Player:AddToggle("Noclip",{Title="Noclip"}):OnChanged(function(v)
    noclip=v
end)

RunService.Stepped:Connect(function()

    if noclip then

        for _,v in pairs(getChar():GetDescendants()) do

            if v:IsA("BasePart") then
                v.CanCollide=false
            end

        end

    end

end)

------------------------------------------------
-- FLY
------------------------------------------------

local flying=false

Tabs.Player:AddToggle("Fly",{Title="Fly"}):OnChanged(function(v)

    flying=v

    if flying then

        local char=getChar()
        local hrp=char:WaitForChild("HumanoidRootPart")

        local bv=Instance.new("BodyVelocity")
        bv.MaxForce=Vector3.new(9e9,9e9,9e9)
        bv.Parent=hrp

        local bg=Instance.new("BodyGyro")
        bg.MaxTorque=Vector3.new(9e9,9e9,9e9)
        bg.Parent=hrp

        spawn(function()

            while flying do

                local cam=workspace.CurrentCamera

                bg.CFrame=cam.CFrame
                bv.Velocity=cam.CFrame.LookVector*80

                task.wait()

            end

            bv:Destroy()
            bg:Destroy()

        end)

    end

end)

------------------------------------------------
-- FLING PLAYER
------------------------------------------------

Tabs.Troll:AddInput("FlingPlayer",{
    Title="Fling Player",
    Placeholder="Player Name",

    Callback=function(name)

        local target=nil

        for _,v in pairs(Players:GetPlayers()) do

            if string.find(string.lower(v.Name),string.lower(name)) then
                target=v
            end

        end

        if target then

            local char=getChar()
            local hrp=char:WaitForChild("HumanoidRootPart")

            local thrp=target.Character:WaitForChild("HumanoidRootPart")

            local bav=Instance.new("BodyAngularVelocity")
            bav.AngularVelocity=Vector3.new(999999,999999,999999)
            bav.MaxTorque=Vector3.new(999999,999999,999999)
            bav.Parent=hrp

            hrp.CFrame=thrp.CFrame

            task.wait(1)

            bav:Destroy()

        end

    end
})

------------------------------------------------
-- ANTI AFK
------------------------------------------------

Tabs.Misc:AddButton({
    Title="Anti AFK",

    Callback=function()

        local vu=game:GetService("VirtualUser")

        LocalPlayer.Idled:Connect(function()

            vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)

        end)

        Fluent:Notify({
            Title="Anti AFK",
            Content="Activated",
            Duration=3
        })

    end
})

------------------------------------------------
-- NOTIFY
------------------------------------------------

Fluent:Notify({
    Title="DIKI PROJECT",
    Content="Loaded Successfully",
    Duration=5
})

Window:SelectTab(1)
