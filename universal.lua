--[[ XKID Reset Hub - Rebuilt for provided WindUI base ]]
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer

local Window = WindUI:CreateWindow({
    Title   = "My Script Hub",
    Author  = "by you",
    Folder  = "myhub",
    Icon    = "house",
    Theme   = "Dark",
    Size    = UDim2.fromOffset(680, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey  = Enum.KeyCode.RightShift,
    Resizable  = true,
    AutoScale  = true,
    NewElements = true,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    SideBarWidth = 200,
    Topbar = {Height = 44, ButtonsType = "Mac"},
    OpenButton = {Title = "Open Hub", Enabled = true, Draggable = true},
    User = {Enabled = true, Anonymous = false, Callback = function() print("user panel clicked") end},
})

-- fallback in case tab APIs differ by version
local Tab = (Window.Tab and Window:Tab({Title="Reset",Icon="refresh-cw"})) or (Window.CreateTab and Window:CreateTab("Reset","refresh-cw")) or Window

local setclip = setclipboard or toclipboard or set_clipboard
local foundRemote

local function notify(msg)
    pcall(function()
        if WindUI.Notify then WindUI:Notify({Title="XKID", Content=msg, Duration=3}) end
    end)
    print("[XKID]", msg)
end

local function scan()
    for _,v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n=v.Name:lower()
            if n:find("reset") or n:find("respawn") or n:find("revive") then
                foundRemote=v
                if setclip then pcall(function() setclip(v:GetFullName()) end) end
                notify("Found: "..v.Name)
                return
            end
        end
    end
    notify("No reset remote found")
end

local function fallbackReset()
    local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then h.Health = 0 end
    task.wait(0.2)
    pcall(function() c:BreakJoints() end)
end

local function resetNow()
    if foundRemote then
        local ok = pcall(function()
            if foundRemote:IsA("RemoteEvent") then foundRemote:FireServer() else foundRemote:InvokeServer() end
        end)
        if ok then notify("Remote fired") return end
    end
    fallbackReset()
    notify("Fallback reset")
end

local function addButton(container, title, cb)
    if container.Button then return container:Button({Title=title, Callback=cb}) end
    if container.CreateButton then return container:CreateButton({Title=title, Callback=cb}) end
end

addButton(Tab, "Scan Reset Remote", scan)
addButton(Tab, "Reset Now", resetNow)
addButton(Tab, "Copy Remote Path", function()
    if foundRemote and setclip then setclip(foundRemote:GetFullName()) notify("Copied path") end
end)

pcall(function()
    LocalPlayer.Chatted:Connect(function(msg)
        msg = tostring(msg):lower()
        if msg == "/re" or msg == "re" then resetNow() end
    end)
end)

pcall(function()
    if TextChatService and TextChatService.SendingMessage then
        TextChatService.SendingMessage:Connect(function(m)
            local t = (m.Text or m.Message or ""):lower()
            if t == "/re" or t == "re" then resetNow() end
        end)
    end
end)

notify("Loaded")
