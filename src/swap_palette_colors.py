# switch tileset graphics on palette 1 to use color $8 for black instead of color $F.
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
    for tileset in os.listdir(sce_path):
        pal_path = sce_path + tileset + "/palette.snes"
        if os.path.islink(pal_path):
            continue
        pal_data = list(open(pal_path, "rb").read())
        pal_data[0x30] = 0
        pal_data[0x31] = 0
        open(pal_path, "wb").write(bytes(pal_data))

# update graphics:
sce_path = root_path + "Base/Export/Tileset/SCE/"
tileset_paths = [sce_path + x for x in os.listdir(sce_path)
                 if x not in ["11", "12", "13", "14"]]  # skip mode 7 Ceres tilesets
tileset_paths.append(root_path + "Base/Export/Tileset/CRE/00")
used_tiles = set()
for tileset_path in tileset_paths:
    print(tileset_path)
    tile_table_path = tileset_path + "/16x16tiles.ttb"
    tile_table_data = list(open(tile_table_path, "rb").read())
    tile_usage_dict = {}
    for i in range(0, len(tile_table_data), 2):
        tile_idx = tile_table_data[i] | ((tile_table_data[i + 1] & 3) << 8)
        used_tiles.add(tile_idx)
        if tileset_path.endswith("CRE/00"):
            tile_idx -= 0x280
        pal = (tile_table_data[i + 1] >> 2) & 7
        if (tile_idx, pal) not in tile_usage_dict:
            tile_usage_dict[(tile_idx, pal)] = []
        tile_usage_dict[(tile_idx, pal)].append(i // 8)

    gfx_path = tileset_path + "/8x8tiles.gfx"
    gfx_data = list(open(gfx_path, "rb").read())

    for tile_idx in range(len(gfx_data) // 32):
        for y in range(8):
            for x in range(8):
                # parse input color
                i = tile_idx * 32 + y * 2
                c0 = (gfx_data[i] >> x) & 1
                c1 = (gfx_data[i + 1] >> x) & 1
                c2 = (gfx_data[i + 16] >> x) & 1
                c3 = (gfx_data[i + 17] >> x) & 1
                c = c0 | (c1 << 1) | (c2 << 2) | (c3 << 3)
                
                d = c
                if c == 15:
                    if (tile_idx, 1) in tile_usage_dict:
                        d = 8
                        # for p in range(8):
                        #     if p == 1:
                        #         continue
                        #     if (tile_idx, p) in tile_usage_dict:
                        #         print("{:03x}".format(tile_idx), p)
                        # # print("{:03x}: {}".format(tile_idx, ["{:03x}".format(x) for x in tile_usage_dict[(tile_idx, 1)]]))

                # store output color
                if d != c:
                    d0 = d & 1
                    d1 = (d >> 1) & 1
                    d2 = (d >> 2) & 1
                    d3 = (d >> 3) & 1
                    
                    gfx_data[i] = (gfx_data[i] & ~(1 << x)) | (d0 << x)
                    gfx_data[i + 1] = (gfx_data[i + 1] & ~(1 << x)) | (d1 << x)
                    gfx_data[i + 16] = (gfx_data[i + 16] & ~(1 << x)) | (d2 << x)
                    gfx_data[i + 17] = (gfx_data[i + 17] & ~(1 << x)) | (d3 << x)

    open(gfx_path, "wb").write(bytes(gfx_data))