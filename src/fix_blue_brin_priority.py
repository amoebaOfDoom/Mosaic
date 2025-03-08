# Low priority tiles:
# $1AA -> $164
# $193 -> $1B3
# $194 -> $1B4
# $195 -> $214
# $196 -> $215
# $197 -> $216
# $1BD -> $198 or $1B5
# $1BE -> $199 or $1B6

import os
import xml.etree.ElementTree as xml
import glob

path_glob = "Projects/BlueBrinstar/Export/Rooms/*.xml"

tile_mapping = {
    0x1AA: 0x164,
    0x193: 0x1B3,
    0x194: 0x1B4,
    0x195: 0x214,
    0x196: 0x215,
    0x197: 0x216,
    0x1BD: 0x198,
    0x1BE: 0x199,
}

excluded_rooms = [
    # (1, 0x24),  # "CATAPILLAR ROOM"
    # (1, 0x34),  # "KRAID HIDEOUT ENTRANCE"
]

def fix_screen(screen):
    word_list = screen.text.split()
    rows = []
    modified_cnt = 0
    for y in range(16):
        cell_list = []
        for x in range(16):
            i = y * 16 + x
            tile = int(word_list[i], 16)
            gfx = tile & 0x3FF
            if gfx in tile_mapping:
                new_gfx = tile_mapping[gfx]
                new_tile = (tile & 0xFC00) | new_gfx
                modified_cnt += 1
            else:
                new_tile = tile

            cell = "{:04X}".format(new_tile)
            cell_list.append(cell)
        rows.append("        " + " ".join(cell_list))
    data = "\n" + "\n".join(rows) + "\n      "
    screen.text = data
    return modified_cnt

for room_path in glob.glob(path_glob):
    tree = xml.parse(room_path)
    area = int(tree.findall("./area")[0].text, 16)
    index = int(tree.findall("./index")[0].text, 16)
    if (area, index) in excluded_rooms:
        continue
    modified_cnt = 0
    states = tree.findall("./States/State")
    for state_node in states:
        tileset_idx = int(state_node.findall("GFXset")[0].text, 16)
        if tileset_idx != 8:
            continue
        for screen in state_node.findall("./LevelData/Layer2/Screen"):
            modified_cnt += fix_screen(screen)
        for screen in state_node.findall("./LevelData/Layer1/Screen"):
            modified_cnt += fix_screen(screen)

    if modified_cnt > 0:
        print("Fixed {} errors in {} ({:x}, {:x})".format(modified_cnt, room_path, area, index))
        tree.write(room_path)
