# Update palettes in utility tilesets where energy refill stations are used,
# to allow the refill station tiles to be drawn using palette 7 instead of palette 0.
# This allows the palette to fade during transition (e.g. for Map Rando,
# where the orange colors in palette 0 don't fade).
import os

projects = [
    "Base",
    "CrateriaPalette",
    "BrinstarPalette",
    "NorfairPalette",
    "WreckedShipPalette",
    "MaridiaPalette",
    "TourianPalette"
]

# update palettes:
root_path = "Projects/"
for project in projects:
    sce_path = root_path + project + "/Export/Tileset/SCE/"
    for tileset in ["17", "18"]:
        pal_path = sce_path + tileset + "/palette.snes"
        if os.path.islink(pal_path):
            continue
        pal_data = list(open(pal_path, "rb").read())

        # copy colors 1 through 7 from palette 0 to palette 7:
        for i in range(2, 16):
            pal_data[0xE0 + i] = pal_data[i]
            
        open(pal_path, "wb").write(bytes(pal_data))
