local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

local Window = Fluent:CreateWindow({
    Title = "📚 XKID_HUB",
    SubTitle = "by Diki | Auto Chain + KBBI",
    TabWidth = 160,
    Size = UDim2.fromOffset(650, 500),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--====================================================================--
--                    DATABASE KBBI SEDERHANA
--====================================================================--
-- Ini adalah database kata bahasa Indonesia (bisa ditambah sendiri)
local KBBI = {
    -- Kata dengan 1 huruf
    ["a"] = {"aku", "air", "anak", "angin", "alam", "akar", "atap", "asing", "awal", "akhir"},
    ["b"] = {"buku", "bola", "batu", "bunga", "bulan", "bumi", "bayi", "babi", "baru", "besar"},
    ["c"] = {"cabe", "cinta", "cacing", "capung", "coklat", "cermin", "cincin", "cabai", "candi"},
    ["d"] = {"dunia", "daun", "daging", "dasi", "dadu", "dara", "dosa", "duri", "dana", "damai"},
    ["e"] = {"ekor", "emas", "enak", "esok", "elang", "enam", "erat", "eksis", "ekstrim", "empat"},
    ["f"] = {"foto", "fakta", "faham", "fajar", "fikir", "fisik", "formulir", "fosil", "fundamental"},
    ["g"] = {"gula", "gigi", "gajah", "garam", "gambar", "gamis", "ganti", "garis", "gas", "gaun"},
    ["h"] = {"hujan", "hati", "hitam", "hidung", "harimau", "harga", "harum", "helai", "hewan"},
    ["i"] = {"ikan", "ibu", "ilmu", "indah", "intan", "isap", "istri", "isyarat", "irit", "irama"},
    ["j"] = {"jalan", "jari", "jantung", "jagung", "jambu", "janda", "janji", "jasa", "jawab"},
    ["k"] = {"kaki", "kucing", "kertas", "kamar", "kakak", "kabut", "kacang", "kadal", "kain"},
    ["l"] = {"lari", "laut", "langit", "lampu", "lalat", "lambat", "lamin", "lancar", "landak"},
    ["m"] = {"mata", "makan", "minum", "mobil", "motor", "mawar", "malam", "mimpi", "mungkin"},
    ["n"] = {"nasi", "nama", "naga", "nafas", "nahas", "naik", "najis", "nangka", "napas", "narkoba"},
    ["o"] = {"obat", "orang", "otak", "otot", "ombak", "omong", "ongkos", "operasi", "oplos"},
    ["p"] = {"padi", "pintu", "pohon", "piring", "payung", "pacul", "padam", "padat", "pagar"},
    ["q"] = {"qasidah", "qori", "qasar", "qiam", "qiraah"}, -- Kata langka
    ["r"] = {"rumah", "roti", "rantai", "rambut", "raja", "racun", "radar", "radio", "rahang"},
    ["s"] = {"sapi", "susu", "sawah", "sayur", "sabun", "sabar", "sabuk", "sadar", "safir"},
    ["t"] = {"tangan", "tulang", "tanah", "teman", "tikus", "tabir", "tabel", "tabrak", "tadah"},
    ["u"] = {"ular", "udang", "ubur", "udara", "ukir", "ukur", "ulang", "ulas", "ulat", "ultra"},
    ["v"] = {"vaksin", "vampir", "vanili", "variasi", "vas", "vegetarian", "vena", "ventilasi"},
    ["w"] = {"wajah", "waktu", "warna", "wanita", "warga", "waris", "warna", "warta", "wastafel"},
    ["x"] = {"xenon", "xenofobia", "xilem", "xilofon"}, -- Kata langka
    ["y"] = {"yakin", "yatim", "yoga", "yogurt", "yudisium", "yuridis", "yute", "yuvenil"},
    ["z"] = {"zakat", "zaman", "zamrud", "zat", "zebra", "zenith", "zeolit", "zigzag", "zina"},
    
    -- Kata dengan 2 huruf terakhir
    ["ka"] = {"kaki", "kamar", "kakak", "kabut", "kacang", "kadal", "kain", "kait", "kajang"},
    ["ki"] = {"kita", "kiri", "kismis", "kijang", "kikuk", "kilat", "kilau", "kimia", "kipas"},
    ["ku"] = {"kuku", "kucing", "kudis", "kue", "kukus", "kuliah", "kulit", "kumis", "kumpul"},
    ["ke"] = {"kecil", "kepala", "keras", "kerang", "kertas", "kerbau", "kereta", "kering"},
    ["ko"] = {"kotor", "koki", "koko", "kolam", "kolom", "komik", "kompor", "kondisi", "kontak"},
    
    ["ta"] = {"tangan", "tanah", "taman", "tamu", "tampan", "tanda", "tani", "tanta", "tanya"},
    ["ti"] = {"tikus", "tiga", "tidak", "tirta", "titi", "tindak", "tinggi", "tinju", "tipis"},
    ["tu"] = {"tulang", "tujuh", "tua", "tudung", "tugas", "tukang", "tulis", "tulung", "tumbuk"},
    ["te"] = {"teman", "telur", "telinga", "tembak", "tempat", "tempur", "tenaga", "tenda"},
    ["to"] = {"tomat", "toko", "topi", "topeng", "total", "tower", "toxic", "traktor", "transaksi"},
    
    -- Kata dengan 3 huruf terakhir (contoh)
    ["ang"] = {"angin", "angkat", "anggur", "angka", "angker", "angklung", "anggrek", "anggun"},
    ["ing"] = {"ingat", "ingin", "ingus", "ingkar", "inggris", "ingin", "ingat", "ingusan"},
    ["ung"] = {"ungu", "unggas", "ungkap", "ungkit", "ungsu", "ungu", "unggun", "unggut"},
    ["eng"] = {"enggan", "engsel", "engkau", "engkol", "engkus", "engil", "enggak"},
    ["ong"] = {"ongkos", "ongkang", "onggok", "ongol", "ongok", "ongsor"},
    
    ["kan"] = {"kantin", "kanker", "kancing", "kanda", "kandidat", "kandil", "kandang"},
    ["lan"] = {"lancar", "landak", "langit", "lantai", "lanjut", "lanun", "lanskap"},
    ["man"] = {"mancung", "mandi", "mandul", "mangga", "mangkok", "manis", "manusia"},
    
    ["bar"] = {"barang", "barat", "barbar", "barbel", "barbur", "barel", "baret", "barik"},
    ["car"] = {"cari", "cara", "carang", "caran", "carat", "carter", "carik", "carub"},
}

--====================================================================--
--                    FUNGSI UTAMA
--====================================================================--

-- Fungsi untuk mendapatkan kata berdasarkan awalan (bisa 1,2,3 huruf)
local function CariKata(awalan)
    if not awalan or awalan == "" then return nil end
    
    -- Cek di database KBBI
    local kemungkinan = KBBI[awalan]
    if kemungkinan and #kemungkinan > 0 then
        -- Pilih kata random dari daftar
        return kemungkinan[math.random(1, #kemungkinan)]
    end
    
    -- Kalau tidak ada, coba dengan awalan yang lebih pendek
    if #awalan > 1 then
        return CariKata(awalan:sub(2)) -- Coba tanpa huruf pertama
    end
    
    return nil
end

-- Fungsi untuk mendeteksi kata terakhir yang muncul di layar
local function DeteksiKataTerakhir()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    local kataTerakhir = nil
    local posisiTerakhir = nil
    
    -- Cari semua TextLabel yang mungkin berisi kata
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel") and #obj.Text > 1 then
            local teks = obj.Text:lower():gsub("[^%a]", "") -- Hanya huruf
            
            -- Cek apakah ini kata terakhir (biasanya di posisi tertentu)
            if teks and #teks > 1 then
                -- Simpan sebagai kandidat
                kataTerakhir = teks
                posisiTerakhir = Vector2.new(obj.AbsolutePosition.X, obj.AbsolutePosition.Y)
            end
        end
    end
    
    return kataTerakhir, posisiTerakhir
end

-- Fungsi untuk mengklik jawaban
local function KlikJawaban(jawaban)
    if not jawaban then return false end
    
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    -- Cari tombol yang berisi jawaban
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextButton") then
            local teks = obj.Text:lower():gsub("[^%a]", "")
            if teks == jawaban then
                -- Klik tombol
                obj:Click()
                
                -- Efek visual (opsional)
                local originalSize = obj.Size
                obj.Size = originalSize * 1.2
                wait(0.1)
                obj.Size = originalSize
                
                return true
            end
        end
    end
    return false
end

--====================================================================--
--                    UI FLUENT
--====================================================================--
local Tabs = {
    Main = Window:AddTab({ Title = "🎮 MAIN", Icon = "gamepad" }),
    KBBI = Window:AddTab({ Title = "📚 KBBI", Icon = "book" }),
    Settings = Window:AddTab({ Title = "⚙ SETTINGS", Icon = "settings" })
}

--====================================================================--
--                    MAIN TAB
--====================================================================--
local MainSection = Tabs.Main:AddSection("Auto Sambung Kata")

-- Status
local StatusLabel = MainSection:AddLabel("Status: Siap")

-- Toggle Auto Chain
_G.AutoChain = false
local ChainToggle = MainSection:AddToggle("AutoChain", {
    Title = "🔄 AUTO CHAIN",
    Description = "Otomatis nyambungin kata (1/2/3 huruf)",
    Default = false
})

ChainToggle:OnChanged(function()
    _G.AutoChain = Fluent.Options.AutoChain.Value
    StatusLabel:SetText("Status: " .. (_G.AutoChain and "AKTIF 🔥" or "MATI"))
end)

-- Informasi aturan
MainSection:AddLabel("📌 Aturan yang didukung:")
MainSection:AddLabel("   • 1 huruf terakhir (a→apel)")
MainSection:AddLabel("   • 2 huruf terakhir (ka→kaki)")
MainSection:AddLabel("   • 3 huruf terakhir (ang→angin)")

-- Button Manual
MainSection:AddButton({
    Title = "🎯 CEK KATA TERAKHIR",
    Description = "Lihat kata terakhir yang terdeteksi",
    Callback = function()
        local kata, pos = DeteksiKataTerakhir()
        if kata then
            Fluent:Notify({
                Title = "Kata Terakhir",
                Content = "📝 " .. kata:upper(),
                Duration = 3
            })
            
            -- Coba cari jawaban untuk berbagai kemungkinan
            print("\n=== KEMUNGKINAN JAWABAN ===")
            for i = 1, 3 do
                if #kata >= i then
                    local akhiran = kata:sub(-i)
                    local jawaban = CariKata(akhiran)
                    if jawaban then
                        print(i .. " huruf (" .. akhiran .. ") → " .. jawaban)
                    end
                end
            end
        else
            Fluent:Notify({
                Title = "Error",
                Content = "Tidak ada kata terdeteksi",
                Duration = 2
            })
        end
    end
})

-- Button Test Manual
MainSection:AddButton({
    Title = "✍️ TEST MANUAL",
    Description = "Masukkan kata untuk diuji",
    Callback = function()
        Fluent:Notify({
            Title = "Test Manual",
            Content = "Lihat console untuk hasil",
            Duration = 2
        })
        
        -- Simulasi dengan beberapa kata
        local testWords = {"kaki", "makan", "tidur", "jalan", "buku"}
        for _, kata in ipairs(testWords) do
            print("\nKata: " .. kata)
            for i = 1, 3 do
                if #kata >= i then
                    local akhiran = kata:sub(-i)
                    local jawaban = CariKata(akhiran)
                    if jawaban then
                        print("  " .. i .. " huruf (" .. akhiran .. ") → " .. jawaban)
                    end
                end
            end
        end
    end
})

--====================================================================--
--                    AUTO CHAIN LOOP
--====================================================================--
spawn(function()
    while true do
        wait(2) -- Cek setiap 2 detik
        
        if _G.AutoChain and LocalPlayer.Character then
            local kataTerakhir, posisi = DeteksiKataTerakhir()
            
            if kataTerakhir then
                local berhasil = false
                
                -- Coba 3 huruf terakhir, lalu 2, lalu 1
                for i = 3, 1, -1 do
                    if #kataTerakhir >= i then
                        local akhiran = kataTerakhir:sub(-i)
                        local jawaban = CariKata(akhiran)
                        
                        if jawaban then
                            print(string.format("🔗 %s (%d huruf: %s) → %s", 
                                kataTerakhir, i, akhiran, jawaban))
                            
                            -- Klik jawaban
                            if KlikJawaban(jawaban) then
                                berhasil = true
                                break
                            end
                        end
                    end
                end
                
                if berhasil then
                    StatusLabel:SetText("Status: Nyambung! 🔗")
                end
            end
        end
    end
end)

--====================================================================--
--                    KBBI TAB (LIHAT DATABASE)
--====================================================================--
local KBBISection = Tabs.KBBI:AddSection("Database KBBI")

-- Info jumlah kata
local totalKata = 0
for _, list in pairs(KBBI) do
    totalKata = totalKata + #list
end

KBBISection:AddLabel("📊 Total kata: " .. totalKata)
KBBISection:AddLabel("📌 Prefix yang tersedia: " .. #KBBI)

-- Dropdown untuk lihat per huruf
local hurufList = {}
for huruf, _ in pairs(KBBI) do
    table.insert(hurufList, huruf)
end
table.sort(hurufList)

local HurufDropdown = KBBISection:AddDropdown("PilihHuruf", {
    Title = "🔤 Pilih Awalan",
    Values = hurufList,
    Multi = false,
    Default = 1,
})

HurufDropdown:OnChanged(function()
    local selected = Fluent.Options.PilihHuruf.Value
    if selected and #selected > 0 then
        local awalan = selected[1]
        local kataList = KBBI[awalan]
        
        if kataList then
            local msg = "Kata dengan awalan '" .. awalan .. "':\n"
            for i, kata in ipairs(kataList) do
                msg = msg .. kata
                if i % 5 == 0 then msg = msg .. "\n" else msg = msg .. ", " end
            end
            print(msg)
            
            Fluent:Notify({
                Title = "KBBI - " .. awalan,
                Content = #kataList .. " kata ditemukan",
                Duration = 3
            })
        end
    end
end)

-- Tombol tambah kata
KBBISection:AddInput("TambahKata", {
    Title = "➕ Tambah Kata ke KBBI",
    Description = "Format: awalan:kata1,kata2",
    Placeholder = "contoh: z:zebra,zakat",
    Callback = function(input)
        if input and #input > 0 then
            local awalan, kataList = input:match("([^:]+):(.+)")
            if awalan and kataList then
                local katas = {}
                for kata in kataList:gmatch("[^,]+") do
                    table.insert(katas, kata:lower())
                end
                
                if not KBBI[awalan] then
                    KBBI[awalan] = {}
                end
                
                for _, kata in ipairs(katas) do
                    table.insert(KBBI[awalan], kata)
                end
                
                Fluent:Notify({
                    Title = "Berhasil",
                    Content = "Ditambahkan ke awalan '" .. awalan .. "'",
                    Duration = 2
                })
            end
        end
    end
})

--====================================================================--
--                    SETTINGS TAB
--====================================================================--
local SettingsSection = Tabs.Settings:AddSection("Pengaturan")

-- Kecepatan auto chain
local SpeedSlider = SettingsSection:AddSlider("ChainSpeed", {
    Title = "⚡ Kecepatan Auto Chain",
    Description = "Delay antar cek (detik)",
    Default = 2,
    Min = 0.5,
    Max = 5,
    Rounding = 1
})

SpeedSlider:OnChanged(function()
    -- Akan digunakan di loop
end)

-- Pilihan prioritas
local PriorityDropdown = SettingsSection:AddDropdown("Priority", {
    Title = "🎯 Prioritas Jawaban",
    Description = "Utamakan berapa huruf?",
    Values = {"3 huruf dulu", "2 huruf dulu", "1 huruf dulu", "Acak"},
    Multi = false,
    Default = 1
})

--====================================================================--
--                    NOTIFIKASI START
--====================================================================--
Fluent:Notify({
    Title = "SAMBUNG KATA MASTER",
    Content = "Database KBBI: " .. totalKata .. " kata siap!",
    Duration = 5
})

Window:SelectTab(1)

print("=== SAMBUNG KATA MASTER LOADED ===")
print("📚 Total kata di KBBI: " .. totalKata)
print("🎯 Fitur: Auto chain 1/2/3 huruf")
print("💡 Aktifkan AUTO CHAIN di tab MAIN")
