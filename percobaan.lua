----------------------------------------------------
-- WINDUI LOADER
----------------------------------------------------
local _version = "1.6.63"
local WindUI

do
    local maxTries = 3
    for i = 1, maxTries do
        local ok, result = pcall(function()
            local src = game:HttpGet(
                "https://github.com/Footagesus/WindUI/releases/download/"
                .. _version .. "/main.lua"
            )
            if #src < 1000 then error("Incomplete download") end
            return loadstring(src)()
        end)
        if ok and result then WindUI = result break end
        warn("[Sodium] WindUI attempt " .. i .. " failed: " .. tostring(result))
        if i < maxTries then task.wait(2) end
    end
    if not WindUI then error("[Sodium] Failed to load WindUI") end
end

=
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local StatsService       = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService    = game:GetService("TeleportService")
local UserInputService   = game:GetService("UserInputService")
local SoundService       = game:GetService("SoundService")
local HttpService        = game:GetService("HttpService")
local VirtualUser        = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local isMobile    = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled


local fileSupported = (
    type(isfolder)   == "function" and
    type(isfile)     == "function" and
    type(makefolder) == "function" and
    type(readfile)   == "function" and
    type(writefile)  == "function"
)


local configFolder = "SodiumHub"
local configFile   = configFolder .. "/config.json"

local defaultConfig = {
    background     = "",
    logo           = "102502086334580",
    theme          = "Dark",
    buttonsType    = "Mac",
    customPfp      = "",
    customName     = "",
    customSubName  = "",
    anonymous      = false,
    selectedSound  = "107004225739474",
    customSounds   = {},
    execPoints     = 0,
    webhookUrl     = "",
    webhookEnabled = false,
    cooldownTime   = 60,
}

local function loadConfig()
    if not fileSupported then
        local f = {} for k,v in pairs(defaultConfig) do f[k]=v end return f
    end
    if not isfolder(configFolder) then makefolder(configFolder) end
    if isfile(configFile) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(configFile))
        end)
        if ok and data then
            for k,v in pairs(defaultConfig) do
                if data[k] == nil then data[k] = v end
            end
            return data
        end
    end
    local fresh = {} for k,v in pairs(defaultConfig) do fresh[k]=v end return fresh
end

local function saveConfig(cfg)
    if not fileSupported then return end
    if not isfolder(configFolder) then makefolder(configFolder) end
    writefile(configFile, HttpService:JSONEncode(cfg))
end

local config = loadConfig()
config.execPoints = (config.execPoints or 0) + 1
saveConfig(config)


local WebhookURL     = config.webhookUrl     or ""
local WebhookEnabled = config.webhookEnabled or false
local CooldownTime   = config.cooldownTime   or 60

----------------------------------------------------
-- THEME GRADIENT MAP
----------------------------------------------------
local ThemeGradients = {
    Dark             = { a="#888888", b="#333333", c="#0a0a0a" },
    Light            = { a="#ffffff", b="#cccccc", c="#aaaaaa" },
    Rose             = { a="#ff8fa3", b="#ff4d6d", c="#000000" },
    Plant            = { a="#95d5b2", b="#52b788", c="#000000" },
    Red              = { a="#ff6b6b", b="#e63946", c="#000000" },
    Indigo           = { a="#a5b4fc", b="#6366f1", c="#000000" },
    Sky              = { a="#7dd3fc", b="#38bdf8", c="#000000" },
    Violet           = { a="#c4b5fd", b="#8b5cf6", c="#000000" },
    Amber            = { a="#fcd34d", b="#f59e0b", c="#000000" },
    Emerald          = { a="#6ee7b7", b="#10b981", c="#000000" },
    Midnight         = { a="#334155", b="#1e293b", c="#0f172a" },
    Crimson          = { a="#fb7185", b="#e11d48", c="#000000" },
}

local function getThemeAccent(themeName)
    local g = ThemeGradients[themeName] or ThemeGradients["Dark"]
    return Color3.fromHex(g.b)
end


local darkShapeThemes = {
    Rose=true, Plant=true, Red=true,   Indigo=true,
    Sky=true,  Violet=true, Amber=true, Emerald=true,
    Crimson=true,
}

local function getTabIconColor(themeName)
    if darkShapeThemes[themeName] then
        return Color3.fromHex("#0a0a0a") 
    end
    return getThemeAccent(themeName)
end

local function makeThemeGradient(themeName)
    local g = ThemeGradients[themeName] or ThemeGradients["Dark"]
    return WindUI:Gradient({
        [0]   = { Color=Color3.fromHex(g.a), Transparency=0 },
        [50]  = { Color=Color3.fromHex(g.b), Transparency=0 },
        [100] = { Color=Color3.fromHex(g.c), Transparency=0 },
    }, { Rotation=45 })
end

local function makeOpenButtonColor(themeName)
    local g = ThemeGradients[themeName] or ThemeGradients["Dark"]
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromHex(g.a)),
        ColorSequenceKeypoint.new(0.5, Color3.fromHex(g.b)),
        ColorSequenceKeypoint.new(1,   Color3.fromHex(g.c)),
    })
end

----------------------------------------------------
-- THEME IMAGE MAP
----------------------------------------------------
local ThemeImages = {
    Dark             = { img="136481007766661" },
    Amber            = { img="95128033219028"  },
    Light            = { img="103289004814551" },
    Rose             = { img="128965390137681" },
    Red              = { img="128965390137681" },
    Crimson          = { img="128965390137681" },
    Sky              = { img="115965625673091" },
    Midnight         = { img="115965625673091" },
    Indigo           = { img="100706133773186" },
    Violet           = { img="100706133773186" },
    Emerald          = { img="72882008403843"  },
    Plant            = { img="72882008403843"  },
}

local function getThemeImgs(themeName)
    return ThemeImages[themeName] or ThemeImages["Dark"]
end

----------------------------------------------------
-- PLAYER INFO HELPERS
----------------------------------------------------
local function getExecRole(pts)
    if pts <= 10  then return "Explore Time"   end
    if pts <= 50  then return "Sodium Enjoyer" end
    return "Sodium Lover"
end

local devList = { "lost_metamofuruze" }

local function getPlayerRole()
    local name = LocalPlayer.Name:lower()
    for _, dev in ipairs(devList) do
        if name == dev:lower() then return "⚙ Dev" end
    end
    return "★ User"
end

local function getExecutorName()
    if type(identifyexecutor) == "function" then
        local ok, n = pcall(identifyexecutor)
        if ok and n then return tostring(n) end
    end
    if type(getexecutorname) == "function" then
        local ok, n = pcall(getexecutorname)
        if ok and n then return tostring(n) end
    end
    if syn         then return "Synapse X" end
    if KRNL_LOADED then return "Krnl"      end
    return "Unknown"
end

local function getDeviceType()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Handheld"
    end
    return "Desktop"
end

local function color3ToHex(c)
    return string.format("#%02x%02x%02x",
        math.clamp(math.floor(c.R*255),0,255),
        math.clamp(math.floor(c.G*255),0,255),
        math.clamp(math.floor(c.B*255),0,255)
    )
end

local function buildPlayerDesc(anon, themeName)
    local dot = ' <font color="'..color3ToHex(getThemeAccent(themeName or config.theme))..'">◈</font> '
    if anon then
        local a = "<b><i>Anonymous</i></b>"
        return
            dot.."Display Name : "..a..
            "\n"..dot.."Account Age  : "..a..
            "\n"..dot.."Executor     : "..a..
            "\n"..dot.."Device       : "..a..
            "\n"..dot.."Exec Points  : "..a..
            "\n"..dot.."Role         : "..a
    end
    local pts = config.execPoints or 1
    return
        dot.."Display Name : <b>"..LocalPlayer.DisplayName.."</b>"..
        "\n"..dot.."Account Age  : <b>"..LocalPlayer.AccountAge.." days</b>"..
        "\n"..dot.."Executor     : <b>"..getExecutorName().."</b>"..
        "\n"..dot.."Device       : <b>"..getDeviceType().."</b>"..
        "\n"..dot.."Exec Points  : <b>"..pts.."  ("..getExecRole(pts)..")</b>"..
        "\n"..dot.."Role         : <b>"..getPlayerRole().."</b>"
end

local gameName = game.Name
task.spawn(function()
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and info and info.Name then gameName = info.Name end
end)

----------------------------------------------------
-- THUMBNAIL CACHE
----------------------------------------------------
local cachedHeadshot    = nil
local cachedDevHeadshot = nil

task.spawn(function()
    local ok, hs = pcall(function()
        return Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)
    if ok and hs then cachedHeadshot = hs end
end)

task.spawn(function()
    local ok, hs = pcall(function()
        return Players:GetUserThumbnailAsync(
            7312846416,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)
    if ok and hs then cachedDevHeadshot = hs end
end)

local function getHeadshot()
    if cachedHeadshot then return cachedHeadshot end
    local ok, hs = pcall(function()
        return Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)
    if ok and hs then cachedHeadshot = hs end
    return cachedHeadshot
end

local function getDevHeadshot()
    if cachedDevHeadshot then return cachedDevHeadshot end
    local ok, hs = pcall(function()
        return Players:GetUserThumbnailAsync(
            7312846416,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)
    if ok and hs then cachedDevHeadshot = hs end
    return cachedDevHeadshot
end

----------------------------------------------------
-- DISCORD API
----------------------------------------------------
local DISCORD_INVITE = "cf9YcdtEYM"

local function fetchDiscordData(code)
    local ok, raw = pcall(function()
        return game:HttpGet(
            "https://discord.com/api/v10/invites/"..code.."?with_counts=true"
        )
    end)
    if not ok then return nil, raw end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not ok2 then return nil, data end
    return data, nil
end

local function getDiscordIconUrl(guild)
    if not guild then return nil end
    if not guild.id or not guild.icon then return nil end
    if RunService:IsStudio() then return nil end
    return "https://cdn.discordapp.com/icons/"
        .. guild.id .. "/" .. guild.icon .. ".png?size=256"
end

local function getDiscordBannerUrl(guild)
    if not guild or not guild.id then return nil end
    if guild.banner and guild.banner ~= "" then
        return "https://cdn.discordapp.com/banners/"..guild.id.."/"..guild.banner..".png?size=512"
    end
    return nil
end

local function setDiscordParagraphImage(iconUrl)
    if not iconUrl or RunService:IsStudio() then return end
    task.spawn(function()
        pcall(function()
            if not isfolder("SodiumHub") then makefolder("SodiumHub") end
            if not isfolder("SodiumHub/assets") then makefolder("SodiumHub/assets") end
            local iconPath = "SodiumHub/assets/discord_icon.png"
            if isfile(iconPath) then delfile(iconPath) end
            local imgData = game:HttpGet(iconUrl)
            writefile(iconPath, imgData)
            local customAsset = getcustomasset(iconPath)
            if customAsset and parDiscord and parDiscord.SetImage then
                parDiscord:SetImage(customAsset)
            end
        end)
    end)
end

----------------------------------------------------
-- HELPERS
----------------------------------------------------
local function resolveAsset(id)
    if id == nil or id == "" then return nil end
    local s = tostring(id):gsub("%s+",""):gsub("rbxassetid://","")
    if s == "" then return nil end
    return "rbxassetid://"..s
end

local _cachedUIF = nil
local _cachedNF  = nil

local function getUserIconFrame()
    if _cachedUIF and _cachedUIF.Parent then return _cachedUIF end
    _cachedUIF, _cachedNF = nil, nil
    local ok, result = pcall(function()
        local mf = Window.UIElements.Main.Main
        for _, child in ipairs(mf:GetChildren()) do
            if child:IsA("TextButton") then
                for _, inner in ipairs(child:GetChildren()) do
                    if inner:IsA("ImageLabel") and inner.Name == "UserIcon" then
                        return inner
                    end
                end
            end
        end
        return nil
    end)
    if ok and result then
        _cachedUIF = result
        _cachedNF  = result:FindFirstChildOfClass("Frame")
    end
    return _cachedUIF
end

local function getNameFrame()
    if _cachedNF and _cachedNF.Parent then return _cachedNF end
    local uif = getUserIconFrame()
    if uif then _cachedNF = uif:FindFirstChildOfClass("Frame") end
    return _cachedNF
end

local function applyCustomProfile()
    if config.anonymous then return end
    local uif = getUserIconFrame()
    if not uif then return end
    for _, child in ipairs(uif:GetChildren()) do
        if child:IsA("ImageLabel") and child.Name ~= "Outline" then
            if config.customPfp ~= "" then
                child.Image = "rbxassetid://"..config.customPfp
            else
                local hs = getHeadshot()
                if hs then child.Image = hs end
            end
            break
        end
    end
    local nf = getNameFrame()
    if nf then
        local d = nf:FindFirstChild("DisplayName")
        local u = nf:FindFirstChild("UserName")
        if d then d.Text = config.customName ~= "" and config.customName or LocalPlayer.DisplayName end
        if u then u.Text = config.customSubName ~= "" and config.customSubName or LocalPlayer.Name end
    end
end

local function resetProfileUI()
    local uif = getUserIconFrame()
    if not uif then return end
    for _, child in ipairs(uif:GetChildren()) do
        if child:IsA("ImageLabel") and child.Name ~= "Outline" then
            local hs = getHeadshot()
            if hs then child.Image = hs end
            break
        end
    end
    local nf = getNameFrame()
    if nf then
        local d = nf:FindFirstChild("DisplayName")
        local u = nf:FindFirstChild("UserName")
        if d then d.Text = LocalPlayer.DisplayName end
        if u then u.Text = LocalPlayer.Name end
    end
end

----------------------------------------------------
-- WINDOW SIZE
----------------------------------------------------
local windowSize, minSize, maxSize
if isMobile then
    windowSize = UDim2.fromOffset(420, 320)
    minSize    = Vector2.new(600, 300)
    maxSize    = Vector2.new(650, 400)
else
    windowSize = UDim2.fromOffset(580, 460)
    minSize    = Vector2.new(600, 350)
    maxSize    = Vector2.new(850, 560)
end

----------------------------------------------------
-- CREATE WINDOW
-- FIX: resolveAsset untuk logo, Theme dari config,
-- Background dari config
----------------------------------------------------
local windowParams = {
    Title        = "Sodium <font color='#0089EB'>\u{E000}</font>",
    Icon         = resolveAsset(config.logo) or "rbxassetid://102502086334580",
    Author       = "By RaffleW_Dev",
    Folder       = "SodiumHub",
    Size         = windowSize,
    MinSize      = minSize,
    MaxSize      = maxSize,
    Transparent  = false,
    NewElements  = true,
    Resizable    = true,
    SideBarWidth = 200,
    HideSearchBar    = false,
    ScrollBarEnabled = true,
    User = {
        Enabled   = true,
        Anonymous = config.anonymous,
        Callback  = function() end,
    },
    Topbar = {
        Height      = 44,
        ButtonsType = config.buttonsType or "Mac",
    },
}

local bgAsset = resolveAsset(config.background)
if bgAsset then windowParams.Background = bgAsset end

local Window = WindUI:CreateWindow(windowParams)

-- WindUI Config Manager untuk tab Config
local SodiumConfig = Window.ConfigManager:Config("SodiumHubConfig")

task.spawn(function()
    task.wait(0.3)
    pcall(applyCustomProfile)
end)

----------------------------------------------------
-- NOTIFY SOUND
-- FIX: notify() tidak akan muncul sama sekali
-- sebelum startupComplete = true
-- Jadi notif hanya muncul kalau user beneran
-- nyentuh/trigger fungsinya sendiri
----------------------------------------------------
local NotifySound = Instance.new("Sound")
NotifySound.SoundId            = "rbxassetid://" .. (config.selectedSound or "107004225739474")
NotifySound.Volume             = 0
NotifySound.RollOffMaxDistance = 0
NotifySound.Parent             = SoundService

local startupComplete = false

local function notify(title, content, icon, duration)
    -- GUARD: skip total jika masih startup
    if not startupComplete then return end
    pcall(function() NotifySound:Play() end)
    WindUI:Notify({
        Title=title, Content=content,
        Icon=icon or "info", Duration=duration or 3,
    })
end

-- Startup notif khusus, bypass guard
local function notifyStartup(title, content, icon, duration)
    WindUI:Notify({
        Title=title, Content=content,
        Icon=icon or "info", Duration=duration or 4,
    })
end

----------------------------------------------------
-- TABS
----------------------------------------------------
local TabInfo = Window:Tab({
    Title="Information", Desc="Script information & credits",
    Icon="info", IconColor=getTabIconColor(config.theme),
    IconShape="Circle", IconThemed=false,
    Locked=false, ShowTabTitle=true, Border=true,
})


local TabSettings = Window:Tab({
    Title="Settings", Desc="Script configuration",
    Icon="settings-2", IconColor=getTabIconColor(config.theme),
    IconShape="Circle", IconThemed=false,
    Locked=false, ShowTabTitle=true, Border=true,
})

-- Config tab paling bawah
local TabConfig = Window:Tab({
    Title="Config", Desc="Save and load configurations",
    Icon="database", IconColor=getTabIconColor(config.theme),
    IconShape="Circle", IconThemed=false,
    Locked=false, ShowTabTitle=true, Border=true,
})

local function syncTabIconColors(themeName)
    local acc = getTabIconColor(themeName)
    pcall(function()
        for _, tab in ipairs({ TabInfo, TabMisc, TabWebhook, TabSettings, TabConfig }) do
            local icon = tab.UIElements and tab.UIElements.Icon
            if icon and icon.ImageLabel then
                icon.ImageLabel.ImageColor3 = acc
            end
        end
    end)
end

----------------------------------------------------
-- TAB INFO
----------------------------------------------------
local url1 = "https://www.tiktok.com/@aryarillsigma"
local url2 = "https://www.tiktok.com/@rafflews"
local TIKTOK_LOGO = "rbxassetid://133722988273482"
local PFX = "rbxassetid://"

local parPlayerCard = nil
local parDiscord    = nil
local parTiktok     = nil
local parDev        = nil

local function updatePlayerCard(themeName)
    if not parPlayerCard then return end
    pcall(function()
        if parPlayerCard.SetDesc then
            parPlayerCard:SetDesc(buildPlayerDesc(config.anonymous, themeName))
        end
        if parPlayerCard.SetImageColor then
            parPlayerCard:SetImageColor(getThemeAccent(themeName or config.theme))
        end
    end)
end

local function buildInfoParagraphs(themeName)
    local imgs = getThemeImgs(themeName)
    local acc  = getThemeAccent(themeName)

    if parPlayerCard then
        updatePlayerCard(themeName)
        return
    end

    -- 1. PLAYER CARD
    local playerImg = getHeadshot() or (PFX.."118704968198375")
    parPlayerCard = TabInfo:Paragraph({
        Title       = config.anonymous and "Anonymous" or LocalPlayer.DisplayName,
        Desc        = buildPlayerDesc(config.anonymous, themeName),
        Image       = playerImg,
        ImageSize   = 60,
        ImageColor  = acc,
        Transparent = true,
        Buttons     = {}
    })

    -- 2. DISCORD PLACEHOLDER
    parDiscord = TabInfo:Paragraph({
        Title       = "Discord Server",
        Desc        = " <font color='#5865F2'>◈</font> Fetching server info...",
        Image       = PFX.."88876696246404",
        ImageSize   = 52,
        Transparent = true,
        Buttons     = {{
            Title="Copy Invite", Icon="link",
            Callback=function()
                if setclipboard then
                    setclipboard("https://discord.gg/"..DISCORD_INVITE)
                    notify("Discord","Link copied!","link",3)
                end
            end
        }, {
            Title="Refresh", Icon="refresh-cw",
            Callback=function()
                local updated = fetchDiscordData(DISCORD_INVITE)
                if updated and updated.guild then
                    local descStr =
                        ' <font color="#5865F2">◈</font> <b>'..(updated.guild.name or "Discord Server")..'</b>'..
                        '\n <font color="#52525b">●</font> Members : <b>'..tostring(updated.approximate_member_count)..'</b>'..
                        '\n <font color="#16a34a">●</font> Online   : <b>'..tostring(updated.approximate_presence_count)..'</b>'
                    pcall(function()
                        if parDiscord.SetDesc then parDiscord:SetDesc(descStr) end
                    end)
                    local iconUrl = getDiscordIconUrl(updated.guild)
                    if iconUrl then
                        setDiscordParagraphImage(iconUrl)
                    end
                    notify("Discord","Server info refreshed.","refresh-cw",2)
                else
                    notify("Discord","Failed to refresh info.","alert-circle",3)
                end
            end
        }}
    })

    task.spawn(function()
        local data = fetchDiscordData(DISCORD_INVITE)
        if not data or not data.guild then return end

        local guild = data.guild
        local mc    = tostring(data.approximate_member_count  or "?")
        local oc    = tostring(data.approximate_presence_count or "?")

        local descStr =
            ' <font color="#5865F2">◈</font> <b>'..(guild.name or "Sodium Hub")..'</b>'..
            '\n <font color="#a1a1aa">●</font> Members : <b>'..mc..'</b>'..
            '\n <font color="#23a55a">●</font> Online   : <b>'..oc..'</b>'

        -- Update desc dulu
        pcall(function()
            if parDiscord.SetDesc then parDiscord:SetDesc(descStr) end
        end)

        -- Download icon dulu, baru set image
        local iconUrl = getDiscordIconUrl(guild)
        if iconUrl and not RunService:IsStudio() then
            task.spawn(function()
                pcall(function()
                    if not isfolder("SodiumHub") then makefolder("SodiumHub") end
                    if not isfolder("SodiumHub/assets") then makefolder("SodiumHub/assets") end

                    local iconPath = "SodiumHub/assets/discord_icon.png"
                    if not isfile(iconPath) then
                        local imgData = game:HttpGet(iconUrl)
                        writefile(iconPath, imgData)
                    end

                    local customAsset = getcustomasset(iconPath)
                    if customAsset and parDiscord and parDiscord.SetImage then
                        parDiscord:SetImage(customAsset)
                    end
                end)
            end)
        end
    end)

    -- 3. TIKTOK — Logo TikTok di Image, theme wallpaper di Thumbnail
    parTiktok = TabInfo:Paragraph({
        Title         = "Our TikTok Account!",
        Desc          = "Main: @Rafflews\nSigma: @LandOfsigma\nCheck us out for updates!",
        Image         = TIKTOK_LOGO,
        ImageSize     = 60,
        Thumbnail     = PFX..imgs.img,
        ThumbnailSize = 120,
        Transparent   = true,
        Buttons = {
            { Title="Copy Main", Callback=function()
                if setclipboard then setclipboard(url1) end
            end },
            { Title="Copy Dev",  Callback=function()
                if setclipboard then setclipboard(url2) end
            end },
        }
    })

    -- 4. DEV PROFILE
    local devImg = getDevHeadshot() or (PFX.."118704968198375")
    parDev = TabInfo:Paragraph({
        Title       = "Dev Profile",
        Desc        = "RaffleW_Dev\nStatus: Student\nDevice: Laptop",
        Image       = devImg,
        ImageSize   = 60,
        Transparent = true,
        Buttons = {{
            Icon="link", Title="Copy Profile",
            Callback=function()
                if setclipboard then
                    setclipboard("https://www.roblox.com/users/7312846416/profile")
                end
                notify("Profile","Link copied!","link",2)
            end
        }}
    })
end

buildInfoParagraphs(config.theme)

local HttpService = game:GetService("HttpService")

-- CONFIG: Ganti URL di bawah sesuai channel Discord lu
local URL_WEBHOOK_BUG = "fill this with your bug report webhook URL"
local URL_WEBHOOK_SUGGEST = "Fill this with your suggestion webhook URL"

-- Cooldown Logic
local bugCooldown = 0
local suggestCooldown = 0
local COOLDOWN_TIME = 900 -- 15 Menit dalam detik

-- Filter Kata (Banned Words)
local bannedWords = {
    "anjing", "bangsat", "bajingan", "sialan", "keparat", "brengsek", "kampret",
    "goblok", "tolol", "dungu", "bodoh", "idiot", "kontol", "memek", "ngentot", 
    "jancok", "tai", "pelacur", "sundal", "babi", "setan", "iblis",
    "fuck", "shit", "damn", "hell", "ass", "bitch", "bastard", "moron", 
    "dumbass", "jerk", "dick", "pussy", "slut", "whore", "motherfucker", "cunt"
}

-- Fungsi Filter Cerdas (Konteks Hewan & Script aman)
local function checkProfanity(text)
    local lowerText = text:lower()
    local safeContext = {"pet", "hewan", "anjing", "babi", "script", "code", "local", "function"}
    
    -- Kalau ada kata kunci aman, langsung return true (lolos)
    for _, safe in pairs(safeContext) do
        if lowerText:find(safe) then return true end
    end

    -- Cek apakah ada kata kasar
    for _, word in pairs(bannedWords) do
        if lowerText:find(word) then return false end
    end
    return true
end

-- Fungsi Kirim Webhook
local function postToDiscord(url, title, color, message)
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = message,
            ["color"] = color,
            ["footer"] = {["text"] = "Sodium System • " .. os.date("%X")}
        }}
    }
    local success, res = pcall(function()
        local requestFunc = syn and syn.request or http_request or request or HttpPost
        requestFunc({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
    return success
end

-- 1️⃣ INPUT REPORT BUG
local BugInput = TabInfo:Input({
    Title = "Report Bug",
    Desc = "Found a bug? Let us know!",
    Icon = "bug",
    Type = "Textarea",
    Placeholder = "Describe the bug you found...",
    Callback = function(text)
        if text == "" then return end
        
        -- Cooldown Check
        if tick() - bugCooldown < COOLDOWN_TIME then
            local remaining = math.ceil(COOLDOWN_TIME - (tick() - bugCooldown))
            return WindUI:Notify({Title = "Cooldown", Content = "Wait " .. math.ceil(remaining/60) .. " more minutes before reporting again!", Icon = "clock"})
        end
        
        if not checkProfanity(text) then
            return WindUI:Notify({Title = "Filter Active", Content = "Your message contains inappropriate content.", Icon = "shield-alert"})
        end

        local content = string.format("- **Reported By:** `%s`\n\n- **Bug:**\n```\n%s\n```", game.Players.LocalPlayer.Name, text)
        local sent = postToDiscord(URL_WEBHOOK_BUG, "🐛 New Bug Reported", 16711680, content)
        
        if sent then
            bugCooldown = tick() -- Start Cooldown
            notify("Sent!", "Bug has been reported successfully!", "bug")
        end
    end
})

-- 2️⃣ INPUT SUGGESTION
local SuggestionInput = TabInfo:Input({
    Title = "Suggestion",
    Desc = "Make Your Idea Heard!",
    Icon = "lightbulb",
    Type = "Textarea",
    Placeholder = "Share your suggestion here...",
    Callback = function(text)
        if text == "" then return end

        -- Cooldown Check
        if tick() - suggestCooldown < COOLDOWN_TIME then
            local remaining = math.ceil(COOLDOWN_TIME - (tick() - suggestCooldown))
            return WindUI:Notify({Title = "Cooldown", Content = "Wait " .. math.ceil(remaining/60) .. " more minutes before suggesting again!", Icon = "clock"})
        end

        if not checkProfanity(text) then
            return WindUI:Notify({Title = "Filter Active", Content = "Your suggestion contains inappropriate content.", Icon = "shield-alert"})
        end

        local content = string.format("- **Suggestion By:** `%s`\n\n- **Suggestions:**\n%s", game.Players.LocalPlayer.Name, text)
        local sent = postToDiscord(URL_WEBHOOK_SUGGEST, "💡 New Suggestion", 65535, content)
        
        if sent then
            suggestCooldown = tick() -- Start Cooldown
            notify("Sent!", "Your suggestion has been sent successfully!", "lightbulb")
        end
    end
})








----------------------------------------------------
-- TAB SETTINGS
----------------------------------------------------
local SolsTag
local FpsTag

TabSettings:Section({ Title="Appearance" })

local themeList = {
    "Dark","Light","Rose","Plant","Red",
    "Indigo","Sky","Violet","Amber","Emerald",
    "Midnight","Crimson",
}

local function buildThemeDropdownValues()
    local values = {}
    for _, name in ipairs(themeList) do
        table.insert(values, {
            Title=name, Desc=name.." theme", Icon="palette",
            Callback=function()
                config.theme = name
                saveConfig(config)
                pcall(function() WindUI:SetTheme(name) end)
                local ng = makeThemeGradient(name)
                if SolsTag and SolsTag.SetColor then SolsTag:SetColor(ng) end
                if FpsTag  and FpsTag.SetColor  then FpsTag:SetColor(ng)  end
                syncTabIconColors(name)
                pcall(function()
                    Window:EditOpenButton({
                        Title="Sodium", Icon="atom",
                        CornerRadius=UDim.new(0,12), StrokeThickness=2,
                        Color=makeOpenButtonColor(name),
                        OnlyMobile=false, Enabled=true, Draggable=true,
                    })
                end)
                updatePlayerCard(name)
                notify("Theme","Set to \""..name.."\".", "palette",4)
            end
        })
    end
    return values
end

TabSettings:Dropdown({
    Title="UI Theme", Desc="Changes theme, tags & open button",
    Values=buildThemeDropdownValues(),
})

TabSettings:Dropdown({
    Title="Window Button Style", Desc="Topbar button style",
    Values={
        { Title="Mac",     Desc="Colored circle buttons", Icon="circle",
          Callback=function() config.buttonsType="Mac"     saveConfig(config) notify("Button Style","Re-execute to apply.","circle",4) end },
        { Title="Default", Desc="Standard icon buttons",  Icon="square",
          Callback=function() config.buttonsType="Default" saveConfig(config) notify("Button Style","Re-execute to apply.","square",4) end },
    },
})

TabSettings:Section({ Title="Window Style" })

TabSettings:Input({
    Title="Background ID", Desc="Window background image ID",
    Icon="wallpaper", Type="Default", Placeholder="e.g. 1234567890",
    Value=config.background, Flag="custom_background",
    Callback=function(text)
        config.background = text:gsub("%s+",""):gsub("rbxassetid://","")
        saveConfig(config)
        notify("Background Saved","Re-execute to apply.","image",4)
    end
})

TabSettings:Input({
    Title="Logo ID", Desc="Window logo image ID",
    Icon="aperture", Type="Default", Placeholder="e.g. 102502086334580",
    Value=config.logo, Flag="custom_logo",
    Callback=function(text)
        config.logo = text:gsub("%s+",""):gsub("rbxassetid://","")
        saveConfig(config)
        notify("Logo Saved","Re-execute to apply.","aperture",4)
    end
})

TabSettings:Button({
    Title="Reset Window Style", Desc="Restore default background and logo",
    Icon="rotate-ccw", Color=Color3.fromRGB(200,50,50),
    Callback=function()
        config.background = defaultConfig.background
        config.logo       = defaultConfig.logo
        saveConfig(config)
        notify("Reset","Restored. Re-execute to apply.","rotate-ccw",4)
    end
})

TabSettings:Section({ Title="Custom Profile" })

TabSettings:Toggle({
    Title="Anonymous Mode", Desc="Show as Anonymous in sidebar",
    Icon="eye-off", Value=config.anonymous, Flag="anon_mode",
    Callback=function(state)
        config.anonymous = state
        saveConfig(config)
        pcall(function() Window.User:SetAnonymous(state) end)
        if not state then
            task.delay(0.1, function() pcall(applyCustomProfile) end)
        end
        task.delay(0.15, function() updatePlayerCard(config.theme) end)
        notify(state and "Anonymous On" or "Anonymous Off",
            state and "Identity hidden." or "Profile visible.", "eye-off",3)
    end
})

TabSettings:Input({
    Title="Display Name", Desc="Custom sidebar display name",
    Icon="user", Type="Default", Placeholder="e.g. RaffleW",
    Value=config.customName, Flag="custom_name",
    Callback=function(text)
        config.customName = text
        saveConfig(config)
        if not config.anonymous then
            pcall(function()
                local nf = getNameFrame() if not nf then return end
                local lbl = nf:FindFirstChild("DisplayName")
                if lbl then lbl.Text = text ~= "" and text or LocalPlayer.DisplayName end
            end)
        end
        notify("Display Name", text ~= "" and "Set to \""..text.."\"." or "Reverted.","user",3)
    end
})

TabSettings:Input({
    Title="Username", Desc="Custom sidebar username",
    Icon="at-sign", Type="Default", Placeholder="e.g. @rafflew",
    Value=config.customSubName, Flag="custom_subname",
    Callback=function(text)
        config.customSubName = text
        saveConfig(config)
        if not config.anonymous then
            pcall(function()
                local nf = getNameFrame() if not nf then return end
                local lbl = nf:FindFirstChild("UserName")
                if lbl then lbl.Text = text ~= "" and text or LocalPlayer.Name end
            end)
        end
        notify("Username", text ~= "" and "Set to \""..text.."\"." or "Reverted.","at-sign",3)
    end
})

TabSettings:Input({
    Title="Profile Picture ID", Desc="Custom profile picture asset ID",
    Icon="image", Type="Default", Placeholder="e.g. 1234567890",
    Value=config.customPfp, Flag="custom_pfp",
    Callback=function(text)
        local cleaned = text:gsub("%s+",""):gsub("rbxassetid://","")
        config.customPfp = cleaned
        saveConfig(config)
        if not config.anonymous then
            pcall(function()
                local uif = getUserIconFrame() if not uif then return end
                for _, child in ipairs(uif:GetChildren()) do
                    if child:IsA("ImageLabel") and child.Name ~= "Outline" then
                        if cleaned ~= "" then
                            child.Image = "rbxassetid://"..cleaned
                        else
                            local hs = getHeadshot()
                            if hs then child.Image = hs end
                        end
                        break
                    end
                end
            end)
        end
        notify("Profile Picture", cleaned ~= "" and "Applied!" or "Reverted.","image",3)
    end
})

TabSettings:Button({
    Title="Reset Profile", Desc="Revert to Roblox account info",
    Icon="rotate-ccw", Color=Color3.fromRGB(200,50,50),
    Callback=function()
        config.customName="" config.customSubName="" config.customPfp="" config.anonymous=false
        saveConfig(config)
        pcall(function() Window.User:SetAnonymous(false) end)
        task.delay(0.1, function()
            pcall(resetProfileUI)
            updatePlayerCard(config.theme)
        end)
        notify("Profile Reset","Reverted to Roblox account.","rotate-ccw",3)
    end
})

TabSettings:Section({ Title="Notification Sound" })

local presetSounds = {
    { name="Samsung",   id="107004225739474" },
    { name="Apple Pay", id="138740832528048" },
    { name="Discord",   id="135272730546427" },
    { name="FTF",       id="110872490887215" },
    { name="Apple",     id="73722479618078"  },
}

config.customSounds  = config.customSounds  or {}
config.selectedSound = config.selectedSound or "107004225739474"

local NotifSoundDropdown

local function buildNotifDropdownValues()
    local values = {{ Type="Divider" }}
    for _, p in ipairs(presetSounds) do
        local pid, pname = p.id, p.name
        table.insert(values,{
            Title=pname, Desc="Preset sound", Icon="music",
            Callback=function()
                config.selectedSound=pid
                NotifySound.SoundId="rbxassetid://"..pid
                saveConfig(config)
                notify("Sound","Set to "..pname,"music",3)
            end,
        })
    end
    if #config.customSounds > 0 then
        table.insert(values,{ Type="Divider" })
        for _, c in ipairs(config.customSounds) do
            local cid, cname = c.id, c.name
            table.insert(values,{
                Title=cname, Desc="Custom sound", Icon="music-2",
                Callback=function()
                    config.selectedSound=cid
                    NotifySound.SoundId="rbxassetid://"..cid
                    saveConfig(config)
                    notify("Sound","Set to "..cname,"music-2",3)
                end,
            })
        end
    end
    return values
end

NotifSoundDropdown = TabSettings:Dropdown({
    Title="Notification Sound", Desc="Choose notification sound",
    Values=buildNotifDropdownValues(),
})

TabSettings:Input({
    Title="Add Custom Sound", Desc="Sound asset ID to add",
    Icon="plus-circle", Type="Default", Placeholder="e.g. 1234567890", Value="",
    Callback=function(text)
        local cleaned = text:gsub("%s+",""):gsub("rbxassetid://","")
        if cleaned=="" then notify("Error","Enter a valid asset ID.","alert-circle",3) return end
        for _,c in ipairs(config.customSounds) do
            if c.id==cleaned then notify("Duplicate","ID already added.","alert-circle",3) return end
        end
        local cname="Custom Notif "..(#config.customSounds+1)
        table.insert(config.customSounds,{name=cname,id=cleaned})
        saveConfig(config)
        pcall(function() NotifSoundDropdown:Update({Values=buildNotifDropdownValues()}) end)
        notify("Sound Added",cname.." added!","plus-circle",3)
    end,
})

TabSettings:Button({
    Title="Delete All Custom Sounds", Desc="Remove all custom sounds",
    Icon="trash-2", Color=Color3.fromRGB(200,50,50),
    Callback=function()
        if #config.customSounds==0 then notify("Empty","No custom sounds.","info",3) return end
        config.customSounds={}
        local isPreset=false
        for _,p in ipairs(presetSounds) do
            if p.id==config.selectedSound then isPreset=true break end
        end
        if not isPreset then
            config.selectedSound="107004225739474"
            NotifySound.SoundId="rbxassetid://107004225739474"
        end
        saveConfig(config)
        pcall(function() NotifSoundDropdown:Update({Values=buildNotifDropdownValues()}) end)
        notify("Deleted","All custom sounds removed.","trash-2",3)
    end,
})

TabSettings:Slider({
    Title="Volume", Desc="Notification sound volume",
    Value={Min=0,Max=1,Default=0.6}, Step=0.05, Flag="notif_volume",
    Callback=function(v) NotifySound.Volume=v end,
})

TabSettings:Toggle({
    Title="Mute Notifications", Desc="Silence notification sounds",
    Icon="volume-x", Value=false, Flag="notif_mute",
    Callback=function(state) NotifySound.Volume=state and 0 or 0.6 end,
})

TabSettings:Button({
    Title="Test Notification", Desc="Preview notification sound",
    Icon="bell",
    Callback=function()
        notify("Test","This is what your notifications sound like!","bell",3)
    end,
})

TabSettings:Section({ Title="Keybind" })

TabSettings:Keybind({
    Title="Toggle UI", Desc="Keybind to open/close the window",
    Value="RightControl", Flag="ui_keybind",
    Callback=function(v)
        local key = typeof(v) == "EnumItem" and v or Enum.KeyCode[tostring(v)]
        if key then Window:SetToggleKey(key) end
    end
})

----------------------------------------------------
-- TAB CONFIG
-- Menggunakan WindUI ConfigManager untuk save/load
-- semua elemen yang punya Flag
----------------------------------------------------
TabConfig:Section({ Title="Configuration Manager" })

TabConfig:Paragraph({
    Title       = "How it works",
    Desc        = "Save stores all flagged settings.\nLoad restores them.\nDelete removes the saved file.",
    Transparent = true,
    Buttons     = {}
})

TabConfig:Button({
    Title="Save Config",
    Desc="Save all current settings to file",
    Icon="save",
    Color=Color3.fromRGB(34, 139, 34),
    Callback=function()
        local ok, err = pcall(function()
            SodiumConfig:Save()
        end)
        if ok then
            notify("Config","Configuration saved successfully!","save",3)
        else
            notify("Config","Save failed: "..tostring(err),"alert-circle",4)
        end
    end
})

TabConfig:Button({
    Title="Load Config",
    Desc="Load and apply saved settings",
    Icon="folder-open",
    Color=Color3.fromRGB(30, 100, 200),
    Callback=function()
        local ok, err = pcall(function()
            SodiumConfig:Load()
        end)
        if ok then
            notify("Config","Configuration loaded successfully!","folder-open",3)
        else
            notify("Config","Load failed: "..tostring(err),"alert-circle",4)
        end
    end
})

TabConfig:Button({
    Title="Delete Config",
    Desc="Delete the saved configuration file",
    Icon="trash-2",
    Color=Color3.fromRGB(200,50,50),
    Callback=function()
        local ok, err = pcall(function()
            SodiumConfig:Delete()
        end)
        if ok then
            notify("Config","Configuration deleted.","trash-2",3)
        else
            notify("Config","Delete failed: "..tostring(err),"alert-circle",4)
        end
    end
})

----------------------------------------------------
-- OPEN BUTTON
----------------------------------------------------
Window:EditOpenButton({
    Title="Sodium", Icon="atom",
    CornerRadius=UDim.new(0,12), StrokeThickness=2,
    Color=makeOpenButtonColor(config.theme),
    OnlyMobile=false, Enabled=true, Draggable=true,
})

----------------------------------------------------
-- TOPBAR TAGS
----------------------------------------------------
SolsTag = Window:Tag({
    Title="Universal",
    Color=makeThemeGradient(config.theme),
})

FpsTag = Window:Tag({
    Title="Fps: ... | Ping: ...",
    Color=makeThemeGradient(config.theme),
})

----------------------------------------------------
-- FPS / PING LOOP
----------------------------------------------------
task.spawn(function()
    local lastTime   = os.clock()
    local frameCount = 0
    RunService.RenderStepped:Connect(function() frameCount+=1 end)
    while task.wait(1) do
        pcall(function()
            local now  = os.clock()
            local fps  = math.floor(frameCount/(now-lastTime)+0.5)
            frameCount = 0
            lastTime   = now
            local ping = 0
            pcall(function()
                ping = math.floor(
                    StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
                )
            end)
            if FpsTag and FpsTag.SetTitle then
                FpsTag:SetTitle(string.format("Fps:%d | Ping:%d",fps,ping))
            end
        end)
    end
end)

----------------------------------------------------
-- INIT
----------------------------------------------------
TabInfo:Select()
Window:SetIconSize(47)
WindUI:SetTheme(config.theme)
syncTabIconColors(config.theme)

task.delay(2.5, function()
    startupComplete = true
    NotifySound.Volume = 0.6
    notifyStartup("Sodium has Loaded","Loaded in "..gameName,"atom",5)
end)