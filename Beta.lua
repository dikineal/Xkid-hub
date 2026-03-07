-- TEST LOAD RAYFIELD
print("Step 1: Mulai load...")

local ok, result = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not ok then
    print("❌ GAGAL load Rayfield!")
    print("Error: " .. tostring(result))
    
    -- Coba link alternatif
    print("Coba link alternatif...")
    local ok2, result2 = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusHub/Rayfield/main/source.lua'))()
    end)
    
    if not ok2 then
        print("❌ Link alternatif juga gagal: " .. tostring(result2))
    else
        print("✅ Link alternatif BERHASIL!")
    end
else
    print("✅ Rayfield berhasil load!")
    
    -- Test buat window kecil
    local Window = result:CreateWindow({
        Name = "✅ TEST BERHASIL",
        LoadingTitle = "Test",
        LoadingSubtitle = "Cek koneksi OK!",
        ConfigurationSaving = { Enabled = false },
        KeySystem = false
    })
    
    local Tab = Window:CreateTab("Test", nil)
    Tab:CreateLabel("✅ Script jalan normal!")
    Tab:CreateButton({
        Name = "✅ Tombol Test",
        Callback = function()
            print("Tombol diklik! Script 100% jalan!")
        end
    })
    
    print("✅ UI berhasil dibuat!")
end
