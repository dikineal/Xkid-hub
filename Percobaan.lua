-- MINIMAL TEST: Load Library Dulu
local success, lib = pcall(function()
    -- URL 1 (Paling Stabil 2026)
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/sol"))()
end)

if not success then
    -- URL 2 Backup
    success, lib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/z4gs/scripts/master/solarisUI.lua"))()
    end)
end

if not success then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Error"; Text = "Solaris Lib Gagal Load! Coba Update Executor."; Duration = 5
    })
    return -- Stop script
end

print("Solaris Loaded! 🔥") -- Kalau ini muncul di console = SUCCESS

-- Buat Window (Sama kayak template sebelumnya)
local win = lib:New({
    Name = "My Hub v2 - FIXED", 
    FolderToSave = "MyHubSave"
})

local tab = win:Tab("Test Tab")
local sec = tab:Section("Test Section")

sec:Button("Test Button", function()
    lib:Notification("WOW!", "Berhasil Execute! 🎉")
end)

sec:Toggle("Test Toggle", false, function(state)
    print("Toggle:", state)
end)

-- Auto save config pas close (built-in)
