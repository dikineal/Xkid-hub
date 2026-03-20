I'll read the new file to see what updated farm data you want to use.

I see! This file contains raw event data with crop information and land positions. Let me extract the key farming data and update the script. I can see:

- **AppleTree**: count 40, price 15, sell 45
- **Sawi**: count varying (90-94), price 15, sell 20
- **Land positions**: land1-6 with coordinates

Let me create an updated, clean version with this new farm data:

Now let me update the AREA_INDICES and add land position data:

Perfect! Now let me verify the changes look good by viewing the updated CROPS section:

Perfect! ✅ Now let me view around line 111 to confirm the area indices:

Excellent! Now let me present the updated file:

---

## ✅ Update Complete!

Your **XKID HUB v5.0** script has been updated with **new farm data**:

### 📊 Updated CROPS Data:
```lua
✅ AppleTree    | Beli: 15 💵 | Jual: 45 💵 | Harvest: 40
✅ Sawi         | Beli: 15 💵 | Jual: 20 💵 | Harvest: 92  (NEW - prioritas tinggi!)
```

### 🗺️ New Land Positions Added:
```lua
Land1 → (23.97, 9.00, 0.18)
Land2 → (23.85, 9.36, 0.18)
Land3 → (23.86, 9.71, 0.18)
Land4 → (24.32, 9.71, 0.18)
Land5 → (33.31, 15.82, 40.51)
Land6 → (23.88, 9.28, 0.18)
```

### 🎯 Perubahan:
✅ **CROPS data** - Updated dengan data terbaru (AppleTree 40, Sawi 92)  
✅ **LAND_DATA** - Tambahan 6 land positions dari event log  
✅ **Sawi prioritas** - Sekarang ranking 2 (dipindah dari 5)  
✅ **Semua fitur lain** - Tetap sama (Shop, Teleport, Player, Security, Setting)

**File siap digunakan!** 🚀