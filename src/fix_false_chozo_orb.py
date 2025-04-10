# In the original game, there's a chozo orb in the level data at the
# Gauntlet Energy Tank item, in spite of the fact that the item is
# not in a chozo orb. This discrepancy isn't normally noticeable
# because the tile gets overwritten by the item PLM before it
# would be visible, but it's noticeable in Map Rando because
# the orange Chozo orb colors don't fade and so are visible while
# scrolling into the room from the right door. Therefore we get rid
# of the chozo orb from the level data.

import os
import xml.etree.ElementTree as xml
import glob

path_glob = "Projects/*/Export/Rooms/CRATERIA GAUNTLET.xml"

for room_path in glob.glob(path_glob):
    tree = xml.parse(room_path)
    modified_cnt = 0
    states = tree.findall("./States/State")
    for state_node in states:
        for screen in state_node.findall("./LevelData/Layer1/Screen"):
            x = int(screen.attrib['X'], 16)
            if x != 5:
                continue
            word_list = screen.text.split()
            rows = []
            for y in range(16):
                cell_list = []
                for x in range(16):
                    i = y * 16 + x
                    tile = int(word_list[i], 16)                    
                    if (x, y) == (3, 8):
                        # put air tile at position (3, 8) 
                        tile = 0x00FF
                    cell = "{:04X}".format(tile)
                    cell_list.append(cell)
                rows.append("        " + " ".join(cell_list))
            data = "\n" + "\n".join(rows) + "\n      "
            screen.text = data

    print("Fixed {}".format(room_path))
    tree.write(room_path)
