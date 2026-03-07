local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Geometry Hub",
    Icon = "box",
    Author = "By geometry",
    Folder = "GeosHub2",
    
    -- ↓ This all is Optional. You can remove it.
    Size = UDim2.fromOffset(400, 360),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    
    -- ↓ Optional. You can remove it.
    --[[ You can set 'rbxassetid://' or video to Background.
        'rbxassetid://':
            Background = "rbxassetid://", -- rbxassetid
        Video:
            Background = "video:YOUR-RAW-LINK-TO-VIDEO.webm", -- video 
    --]]

WindUI:Popup({
    Title = "Hub was made keyless on 21/8/25 11:32pm",
    Icon = "info",
    Content = "Popup content",
    Buttons = {
        {
            Title = "Continue",
            Icon = "arrow-right",
            Callback = function() end,
            Variant = "Primary",
        }
    }
})
WindUI:Notify({
    Title = "Ran!",
    Content = "CREDITS TO ALL THE SCRIPT OWNERS IN THIS HUB.",
    Duration = 3, -- 3 seconds
    Icon = "bell",
})
local Tab = Window:Tab({
    Title = "Scripts",
    Icon = "scroll",
    Locked = false,
})
local Button = Tab:Button({
    Title = "SEDJM CurrentAngle",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Abdi1515/a/refs/heads/main/Sedjm.lua"))()
    end
})
local Button = Tab:Button({
    Title = "EKDV1",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sparezirt/Script/refs/heads/main/.github/workflows/JustABaseplate.txt"))()
    end
})
local Button = Tab:Button({
    Title = "Ultra UTG",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sparezirt/Script/refs/heads/main/.github/workflows/JustABaseplate.txt"))()
    end
})
local Button = Tab:Button({
    Title = "TIAPT2 Trolling GUI",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Rawbr10/Roblox-Scripts/refs/heads/main/Trolling%20Is%20A%20Pinning%20Tower%202%20Script"))()
    end
})
local Button = Tab:Button({
    Title = "Kill Bot V2",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gObl00x/Pendulum-Fixed-AND-Others-Scripts/refs/heads/main/Killbot%20V2"))()
    end
})
local Button = Tab:Button({
    Title = "AquaMatrix",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Catimate-Hub-32236"))()
    end
})
local Button = Tab:Button({
    Title = "Krystal Tool Dance",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Just-a-baseplate.-Krystal-Tool-Dance-V3-By-Theo-45046"))()
    end
})
local Button = Tab:Button({
    Title = "Epik R6 Dancezz",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Just-a-baseplate.-Krystal-Tool-Dance-V3-By-Theo-45046"))()
    end
})
local Button = Tab:Button({
    Title = "Caducus",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/XJeBNe0s"))()
    end
})
local Tab = Window:Tab({
    Title = "Hubs",
    Icon = "brain",
    Locked = false,
})
local Button = Tab:Button({
    Title = "Ghost Hub",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/GhostHub'))()
    end
})
local Tab = Window:Tab
    Title = "Fun",
    Icon = "ferris-wheel",
    Locked = false,
})
local Button = Tab:Button({
    Title = "goofy ah",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/UQhaBfEZ"))()
    end
})
local Button = Tab:Button({
    Title = "Head Fling",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Abdi1515/a/refs/heads/main/anan.lua"))()
    end
})
local Tab = Window:Tab({
    Title = "Only For JAB",
    Icon = "x",
    Locked = false,
})
local Button = Tab:Button({
    Title = "Immortality Lord",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Abdi1515/a/refs/heads/main/IL2"))()
    end
})
local Button = Tab:Button({
    Title = "xDLOL",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Abdi1515/a/refs/heads/main/xdlol.txt"))()
    end
})
local Button = Tab:Button({
    Title = "Achromatic",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Abdi1515/a/refs/heads/main/achromatic.lua"))()
    end
})
local Button = Tab:Button({
    Title = "Soul Reaper",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Abdi1515/a/refs/heads/main/soulreaper.lua"))()
    end
})
local Button = Tab:Button({
    Title = "Dubstep Cannon",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Abdi1515/a/refs/heads/main/DubstepCannon.lua"))()
    end
})
local Button = Tab:Button({
    Title = "Melon FE True SS Convert",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet(('https://raw.githubusercontent.com/C00LMelon/True-SS-Hub/main/Protected.lua%20(4).txt'),true))()
        loadstring("\105\102\32\110\111\116\32\103\97\109\101\58\71\101\116\83\101\114\118\105\99\101\40\34\82\101\112\108\105\99\97\116\101\100\83\116\111\114\97\103\101\34\41\58\70\105\110\100\70\105\114\115\116\67\104\105\108\100\40\34\48\49\95\115\101\114\118\101\114\34\41\32\116\104\101\110\32\114\101\116\117\114\110\32\103\97\109\101\58\71\101\116\83\101\114\118\105\99\101\40\34\84\101\108\101\112\111\114\116\83\101\114\118\105\99\101\34\41\58\84\101\108\101\112\111\114\116\40\49\55\53\55\52\54\49\56\57\53\57\44\32\103\97\109\101\58\71\101\116\83\101\114\118\105\99\101\40\34\80\108\97\121\101\114\115\34\41\46\76\111\99\97\108\80\108\97\121\101\114\41\32\101\110\100\10")()
    end
})
local Button = Tab:Button({
    Title = "Giant EKDV1",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/U28NEr9s/raw"))()
    end
})
local Tab = Window:Tab({
    Title = "Reanimates",
    Icon = "person-standing",
    Locked = false,
})
local Button = Tab:Button({
    Title = "CurrentAngle V2",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-CurrentAngle-V2-Full-axis-reanimate-43351"))()
    end
})
local Button = Tab:Button({
    Title = "JAB Reanimate",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/nicolasbarbosa43243/john-doe/refs/heads/main/Just_A_Baseplate_Working_Reanimation.txt"))()
    end
})
local Tab = Window:Tab({
    Title = "Chat Bypassers",
    Icon = "key-round",
    Locked = false,
})
local Button = Tab:Button({
    Title = "AnnaBypasser",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/AnnaRoblox/AnnaBypasser/refs/heads/main/AnnaBypasser.lua",true))()
    end
})
local Button = Tab:Button({
    Title = "Not Better Bypass",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Gazer-Ha/Gaze-stuff/refs/heads/main/Not%20Better%20Bypass"))()
    end
})
local Tab = Window:Tab({
    Title = "Forsaken Reanimation Scripts",
    Icon = "disc",
    Locked = false,
})
local Button = Tab:Button({
    Title = "Guest",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/CyberNinja103/brodwa/refs/heads/main/Guestlimb"))()
    end
})
local Button = Tab:Button({
    Title = "Noli",
    Desc = "Script",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/CyberNinja103/brodwa/refs/heads/main/NoliLimb"))()
    end
})
