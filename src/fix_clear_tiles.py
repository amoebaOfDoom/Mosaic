import os
import xml.etree.ElementTree as xml
import glob

path_glob = "Projects/*/Export/Rooms/*.xml"

for room_path in glob.glob(path_glob):
    tree = xml.parse(room_path)
    modified_cnt = 0
    states = tree.findall("./States/State")
    for state_node in states:
        layer2_screens = state_node.findall("./LevelData/Layer2/Screen")
        for layer2_screen in layer2_screens:
            layer2_list = layer2_screen.text.split()
            rows = []
            for y in range(16):
                cell_list = []
                for x in range(16):
                    i = y * 16 + x
                    layer2_tile = int(layer2_list[i], 16)
                    layer2_gfx = layer2_tile & 0x3FF
                    if 0x8E <= layer2_gfx <= 0x95:
                        new_tile = 0xFF
                        modified_cnt += 1
                    else:
                        new_tile = layer2_tile

                    cell = "{:04X}".format(new_tile)
                    cell_list.append(cell)
                rows.append("        " + " ".join(cell_list))
            data = "\n" + "\n".join(rows) + "\n      "
            layer2_screen.text = data
    if modified_cnt > 0:
        print("Fixed {} errors in {}".format(modified_cnt, room_path))
        tree.write(room_path)
