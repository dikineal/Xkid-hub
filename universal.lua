-- XKID Universal Reset + WindUI template created.
-- Uses WindUI loader requested by user and adds Reset Finder UI.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/source.lua"))()
local Window = Library:CreateWindow({
    Title = "XKID Reset Hub",
    Icon = "refresh-cw",
    Folder = "XKIDReset",
    Size = UDim2.fromOffset(520, 420),
    Transparent = true,
    Theme = "Dark"
})

local Tab = Window:Tab({ Title = "Reset", Icon = "rotate-ccw" })

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local setclip = setclipboard or toclipboard or set_clipboard
local foundRemote

local function notify(txt)
    pcall(function() Library:Notify({Title="XKID", Content=txt, Duration=3}) end)
end

local function scan()
    for _,obj in ipairs(game:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            local n = obj.Name:lower()
            if n:find("reset") or n:find("respawn") or n:find("revive") then
                foundRemote = obj
                if setclip then setclip(obj:GetFullName()) end
                notify("Remote found & copied")
                return
            end
        end
    end
    notify("No remote found")
end

local function fallback()
    local c = lp.Character or lp.CharacterAdded:Wait()
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
        if ok then notify("Reset fired") return end
    end
    fallback()
    notify("Fallback reset used")
end

Tab:Button({Title="Scan Reset Remote", Callback=scan})
Tab:Button({Title="Reset Now", Callback=resetNow})
Tab:Button({Title="Copy Remote Path", Callback=function()
    if foundRemote and setclip then setclip(foundRemote:GetFullName()) notify("Copied") end
end})
Tab:Paragraph({Title="Chat Command", Desc="Type /re in chat after injecting if you add your own listener."})

