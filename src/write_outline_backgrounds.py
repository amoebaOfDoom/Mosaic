import os
import xml.etree.ElementTree as xml

root_path = "Projects/Outline/Export/Rooms"

bts_slope_half_bottom_edge_1 = 0x00
bts_slope_half_bottom_edge_2 = 0x07
bts_slope_whole_bottom_edge = 0x13
bts_slope_half_right_edge = 0x01
bts_slope_bottom_right_45 = 0x12
bts_slope_bottom_right_45_small = 0x14
bts_slope_bottom_right_45_large = 0x15
bts_slope_bottom_right_steep_small = 0x1B
bts_slope_bottom_right_steep_large = 0x1C
bts_slope_bottom_right_gentle_small = 0x16
bts_slope_bottom_right_gentle_large = 0x17
bts_slope_bottom_right_step_small = 0x02
bts_slope_bottom_right_step_large = 0x03
bts_slope_broken = 0x0F  # The broken slopes used in Tourian Escape Room 3

base_tile_idx = 0x113
hflip = 0x40
vflip = 0x80
parity_offset = 5
air_offset = 0x00
solid_offset = 0x24
slope_bts_tile_offset_dict = {
    bts_slope_half_bottom_edge_1: 0x01,
    bts_slope_half_bottom_edge_1 | hflip: 0x01,
    bts_slope_half_bottom_edge_1 | vflip: 0x02,
    bts_slope_half_bottom_edge_1 | hflip | vflip: 0x02,
    bts_slope_half_bottom_edge_2: 0x01,
    bts_slope_half_bottom_edge_2 | hflip: 0x01,
    bts_slope_half_bottom_edge_2 | vflip: 0x02,
    bts_slope_half_bottom_edge_2 | hflip | vflip: 0x02,
    bts_slope_whole_bottom_edge: 0x24,
    bts_slope_whole_bottom_edge | hflip: 0x24,
    bts_slope_whole_bottom_edge | vflip: 0x24,
    bts_slope_whole_bottom_edge | hflip | vflip: 0x24,
    bts_slope_half_right_edge: 0x03,
    bts_slope_half_right_edge | hflip: 0x04,
    bts_slope_half_right_edge | vflip: 0x03,
    bts_slope_half_right_edge | hflip | vflip: 0x04,
    bts_slope_bottom_right_45: 0x63,
    bts_slope_bottom_right_45 | hflip: 0xA3,
    bts_slope_bottom_right_45 | vflip: 0xC3,
    bts_slope_bottom_right_45 | hflip | vflip: 0x83,
    bts_slope_bottom_right_45_small: 0x64,
    bts_slope_bottom_right_45_small | hflip: 0xA4,
    bts_slope_bottom_right_45_small | vflip: 0xC4,
    bts_slope_bottom_right_45_small | hflip | vflip: 0x84,
    bts_slope_bottom_right_45_large: 0x60,
    bts_slope_bottom_right_45_large | hflip: 0xA0,
    bts_slope_bottom_right_45_large | vflip: 0xC0,
    bts_slope_bottom_right_45_large | hflip | vflip: 0x80,
    bts_slope_bottom_right_steep_small: 0x64,
    bts_slope_bottom_right_steep_small | hflip: 0xA4,
    bts_slope_bottom_right_steep_small | vflip: 0xC4,
    bts_slope_bottom_right_steep_small | hflip | vflip: 0x84,
    bts_slope_bottom_right_steep_large: 0x61,
    bts_slope_bottom_right_steep_large | hflip: 0xA1,
    bts_slope_bottom_right_steep_large | vflip: 0xC1,
    bts_slope_bottom_right_steep_large | hflip | vflip: 0x81,
    bts_slope_bottom_right_gentle_small: 0x64,
    bts_slope_bottom_right_gentle_small | hflip: 0xA4,
    bts_slope_bottom_right_gentle_small | vflip: 0xC4,
    bts_slope_bottom_right_gentle_small | hflip | vflip: 0x84,
    bts_slope_bottom_right_gentle_large: 0x62,
    bts_slope_bottom_right_gentle_large | hflip: 0xA2,
    bts_slope_bottom_right_gentle_large | vflip: 0xC2,
    bts_slope_bottom_right_gentle_large | hflip | vflip: 0x82,
    bts_slope_bottom_right_step_small: 0x20,
    bts_slope_bottom_right_step_small | hflip: 0x23,
    bts_slope_bottom_right_step_small | vflip: 0x21,
    bts_slope_bottom_right_step_small | hflip | vflip: 0x22,
    bts_slope_bottom_right_step_large: 0x40,
    bts_slope_bottom_right_step_large | hflip: 0x42,
    bts_slope_bottom_right_step_large | vflip: 0x41,
    bts_slope_bottom_right_step_large | hflip | vflip: 0x43,
    bts_slope_broken: 0x64,
}

# Certain tiles we want to be drawn in the background like air even though they may have solid parts:
room_air_tile_overrides = {
    # Landing Site: Ship
    (0, 0): [(x, y) for y in range(0x45, 0x4A) for x in range(0x42, 0x4E)],
    # Right-side map station rooms: Crateria, Maridia
    (0, 27): [(x, y) for y in [9, 10, 11] for x in [9, 10, 11, 12]],
    (4, 22): [(x, y) for y in [9, 10, 11] for x in [9, 10, 11, 12]],
    (5, 18): [(x, y) for y in [9, 10, 11] for x in [9, 10, 11, 12]],
    # Left-side map station rooms: Brinstar, Norfair, Wrecked Ship
    (1, 5): [(x, y) for y in [9, 10, 11] for x in [3, 4, 5, 6]],
    (2, 46): [(x, y) for y in [9, 10, 11] for x in [3, 4, 5, 6]],
    (3, 9): [(x, y) for y in [9, 10, 11] for x in [3, 4, 5, 6]],
    # Left-side refill station
    (1, 7): [(x, y) for y in [9, 10, 11] for x in [3, 4, 5]],
    (1, 21): [(x, y) for y in [9, 10, 11] for x in [3, 4, 5]],
    (1, 49): [(x, y) for y in [9, 10, 11] for x in [3, 4, 5]],
    # Right-side refill station
    (2, 57): [(x, y) for y in [9, 10, 11] for x in [7, 8, 9]],
    (4, 45): [(x, y) for y in [9, 10, 11] for x in [7, 8, 9]],
    (4, 52): [(x, y) for y in [9, 10, 11] for x in [7, 8, 9]],
    # Left-side double refill station
    (5, 9):  [(x, y) for y in [9, 10, 11] for x in [5, 6, 7, 8, 9]],
    # Right-side double refill station
    (1, 50): [(x, y) for y in [9, 10, 11] for x in [6, 7, 8, 9, 10]],
    # Center refill station
    (2, 43): [(x, y) for y in [9, 10, 11] for x in [6, 7, 8]],
    # Left-side save stations:
    (0, 4): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [5, 6]],
    (1, 27): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [5, 6]],
    (1, 30): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [5, 6]],
    (1, 31): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [5, 6]],
    (2, 47): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [5, 6]],
    (2, 52): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [5, 6]],
    (4, 41): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [5, 6]],
    (5, 13): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [5, 6]],
    # Right-side save stations:
    (1, 54): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [7, 8]],
    (1, 55): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [7, 8]],
    (2, 15): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [7, 8]],
    (2, 51): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [7, 8]],
    (2, 76): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [7, 8]],
    (3, 15): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [7, 8]],
    (4, 0): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [7, 8]],
    (4, 23): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [7, 8]],
    # Center save stations:
    (2, 50): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [7, 8]],
    (4, 44): [(x, y) for y in [6, 7, 8, 9, 10, 11] for x in [7, 8]],
    # Glass tunnel:
    (4, 1): [(x, 0x15) for x in range(3, 13)] + [(x, 0x1A) for x in range(4, 12)],
    # Spore Spawn's Room
    (1, 11): [(x, y) for y in [0x1E, 0x1F] for x in [7, 8]],
    # Items hidden in scenery:
    (0, 5): [(0x1C, 0x03)],  # West Ocean
    (1, 4): [(0x1E, 0x07)],  # Brinstar Reserve Tank Room
    (1, 16): [(0x1C, 0x22)],  # Blue Brinstar Energy Tank Room
    (1, 29): [(5, 12)],  # Billy Mays Room
    (1, 43): [(5, 4)],  # Warehouse Energy Tank Room
    (2, 1): [(0x22, 0x1C)],  # Cathedral
    (2, 8): [(1, 8)],  # Crumble Shaft
    (2, 24): [(7, 11)],  # Norfair Reserve Tank Room
    (2, 27): [(0xBC, 0x13)],  # Speedbooster Hall
    (2, 55): [(0x15, 0x08)],  # Golden Torizo's Room
    (2, 73): [(14, 11)],  # Ridley Tank Room
    (4, 6): [(0x2C, 0x1D)],  # Mama Turtle Room
    (4, 42): [(0x1C, 0x06)],  # Precious Room
}

other_overrides = {
    # Dragon Rock scroll PLM blocks:
    (2, 75, 0x0F, 0x06): 0x2C2,
    (2, 75, 0x0F, 0x07): 0x2C1,
    (2, 75, 0x0F, 0x08): 0x2C2,
    (2, 75, 0x0F, 0x09): 0x2C1,
    (2, 75, 0x14, 0x0B): 0x2C3,
    (2, 75, 0x15, 0x0B): 0x2C1,
    (2, 75, 0x16, 0x0B): 0x2C2,
    (2, 75, 0x17, 0x0B): 0x2C1,
    (2, 75, 0x18, 0x0B): 0x2C2,
    (2, 75, 0x19, 0x0B): 0x2C1,
    (2, 75, 0x1A, 0x0B): 0x2C2,
    (2, 75, 0x1B, 0x0B): 0x2C4,
    (2, 75, 0x1F, 0x36): 0x2C2,
    (2, 75, 0x1F, 0x37): 0x2C1,
    (2, 75, 0x1F, 0x38): 0x2C2,
    (2, 75, 0x2B, 0x39): 0x2C1,
    (2, 75, 0x2C, 0x39): 0x2C2,
    (2, 75, 0x2D, 0x39): 0x2C1,
}

def get_int(subtree, selector):
    nodes = subtree.findall(selector)
    if(len(nodes) > 0):
        return int(nodes[0].text, 16)
    else:
        return 0

for room_filename in os.listdir(root_path):
    room_path = os.path.join(root_path, room_filename)
    print(room_path)
    tree = xml.parse(room_path)
    room_area = get_int(tree, "./area")
    room_index = get_int(tree, "./index")
    states = tree.findall("./States/State")
    for state_node in states:
        gfx_set = get_int(state_node, "GFXset")
        if gfx_set != 0x20:
            continue
        layer1_screens = state_node.findall("./LevelData/Layer1/Screen")
        layer2_screens = state_node.findall("./LevelData/Layer2/Screen")
        bts_screens = state_node.findall("./LevelData/BTS/Screen")
        for layer1_screen, layer2_screen, bts_screen in zip(layer1_screens, layer2_screens, bts_screens):
            screen_x = int(layer1_screen.attrib['X'], 16)
            screen_y = int(layer1_screen.attrib['Y'], 16)
            layer1_list = layer1_screen.text.split()
            bts_list = bts_screen.text.split()
            layer2_list = []
            rows = []
            for y in range(16):
                cell_list = []
                for x in range(16):
                    i = y * 16 + x
                    layer1_tile = int(layer1_list[i], 16)
                    bts_tile = int(bts_list[i], 16)
                    tile = base_tile_idx
                    block_type = layer1_tile >> 12

                    if block_type == 8:
                        tile += solid_offset
                    elif block_type == 1 and bts_tile in slope_bts_tile_offset_dict:
                        tile += slope_bts_tile_offset_dict[bts_tile]
                    else:
                        tile += air_offset

                    room_x = screen_x * 16 + x
                    room_y = screen_y * 16 + y
                    if (room_area, room_index) in room_air_tile_overrides:                        
                        if (room_x, room_y) in room_air_tile_overrides[(room_area, room_index)]:
                            tile = base_tile_idx + air_offset
                    
                    parity = (i & 1) ^ ((i >> 4) & 1)
                    if parity == 1:
                        tile += parity_offset

                    if (room_area, room_index, room_x, room_y) in other_overrides:
                        tile = other_overrides[(room_area, room_index, room_x, room_y)]

                    cell = "{:04X}".format(tile)
                    cell_list.append(cell)
                rows.append("        " + " ".join(cell_list))
            data = "\n" + "\n".join(rows) + "\n      "
            layer2_screen.text = data
    tree.write(room_path)
