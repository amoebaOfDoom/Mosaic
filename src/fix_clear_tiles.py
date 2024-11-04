import os
import xml.etree.ElementTree as xml
import glob

path_glob = "Projects/*/Export/Rooms/*.xml"

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
            if 0x8E <= gfx <= 0x95:
                new_tile = 0xFF
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
    modified_cnt = 0
    states = tree.findall("./States/State")
    for state_node in states:
        for screen in state_node.findall("./LevelData/Layer2/Screen"):
            modified_cnt += fix_screen(screen)
        if "CERES" not in room_path:
            for screen in state_node.findall("./LevelData/Layer1/Screen"):
                modified_cnt += fix_screen(screen)

    if modified_cnt > 0:
        print("Fixed {} errors in {}".format(modified_cnt, room_path))
        tree.write(room_path)
