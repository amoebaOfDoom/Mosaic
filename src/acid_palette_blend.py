import os
import xml.etree.ElementTree as xml
import glob

path_glob = "Projects/*/Export/Rooms/*.xml"

for room_path in glob.glob(path_glob):
    tree = xml.parse(room_path)
    states = tree.findall("./States/State")
    modified = False
    for state_node in states:
        for fx in state_node.findall("./FX1s/FX1"):
            fx_type = int(fx.findall("type")[0].text, 16)
            if fx_type == 4:
                # Acid FX: use palette blend 8 (unused in vanilla)
                fx.findall("paletteblend")[0].text = "08"
                modified = True
    if modified:
        print("Updated {}".format(room_path))
        tree.write(room_path)
