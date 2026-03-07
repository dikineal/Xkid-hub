-- SCRIPT DEBUG RAYFIELD UNTUK SAWAH INDO

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

local Window = Rayfield:CreateWindow({
    Name = "🔍 DEBUG SAWAH INDO",
    LoadingTitle = "DEBUG MODE",
    LoadingSubtitle = "Cari Semua Object",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local Tab = Window:CreateTab("📡 Scanner", nil)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DebugOutput"
ScreenGui.Parent = game:GetService("CoreGui")

local OutputFrame = Instance.new("Frame")
OutputFrame.Size = UDim2.new(0, 400, 0, 300)
OutputFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
OutputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OutputFrame.BackgroundTransparency = 0.2
OutputFrame.BorderSizePixel = 0
OutputFrame.Parent = ScreenGui
OutputFrame.Active = true
OutputFrame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.Text = "📋 HASIL SCAN"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = OutputFrame

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -10, 1, -40)
TextBox.Position = UDim2.new(0, 5, 0, 35)
TextBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TextBox.TextColor3 = Color3.new(0, 1, 0)
TextBox.Font = Enum.Font.Code
TextBox.TextSize = 12
TextBox.TextWrapped = true
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.TextYAlignment = Enum.TextYAlignment.Top
TextBox.MultiLine = true
TextBox.ClearTextOnFocus = false
TextBox.TextEditable = false
TextBox.Parent = OutputFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = OutputFrame
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local function log(text)
    TextBox.Text = TextBox.Text .. "\n" .. text
    print(text)
end

local function clearLog()
    TextBox.Text = ""
end

Tab:CreateButton({
    Name = "🔍 SCAN OBJECT DI SEKITAR",
    Callback = function()

        clearLog()
        log("=== MULAI SCAN ===")

        local plr = game:GetService("Players").LocalPlayer
        if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            log("ERROR: Character tidak ditemukan")
            return
        end

        local myPos = plr.Character.HumanoidRootPart.Position
        log("Posisi saya: " .. tostring(myPos))
        log("")

        local keywords = {"toko","buy","sell","jual","beli","npc","merchant","farmer","petani","egg","telur","tool","alat","bibit","seed","tanah","lahan","sawit","palm"}
        local found = {}

        for _, obj in pairs(workspace:GetDescendants()) do

            local objPos = nil

            if obj:IsA("BasePart") then
                objPos = obj.Position

            elseif obj:IsA("Model") then

                if obj:FindFirstChild("HumanoidRootPart") then
                    objPos = obj.HumanoidRootPart.Position

                elseif obj:FindFirstChild("Head") then
                    objPos = obj.Head.Position

                elseif obj:FindFirstChild("Torso") then
                    objPos = obj.Torso.Position
                end
            end

            if objPos then

                local dist = (myPos - objPos).Magnitude

                if dist < 150 then

                    table.insert(found,{
                        name = obj.Name,
                        class = obj.ClassName,
                        dist = dist,
                        pos = objPos
                    })

                end
            end
        end

        table.sort(found,function(a,b)
            return a.dist < b.dist
        end)

        log("50 OBJECT TERDEKAT:")

        for i = 1, math.min(50,#found) do
            log(string.format("%d. [%s] %s (%.1f stud)",i,found[i].class,found[i].name,found[i].dist))
        end

        log("")
        log("=== PENCARIAN KEYWORD ===")

        for _,kw in ipairs(keywords) do

            log("Keyword: "..kw)

            local count = 0

            for _,obj in ipairs(found) do

                if obj.name:lower():find(kw) then
                    count = count + 1
                    log(string.format("  - %s (%.1f stud)",obj.name,obj.dist))
                end

            end

            if count == 0 then
                log("  (Tidak ditemukan)")
            end

            log("")
        end

        log("=== SCAN SELESAI ===")

    end
})

log("✅ DEBUG READY")
log("Klik tombol SCAN untuk mulai")
