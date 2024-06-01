import os
from argparse import ArgumentParser
from pathlib import Path
import xml.etree.ElementTree as xml
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

class Room:
  def __init__(self, path):
    self.path = os.path.relpath(str(path))

    def get_int(subtree, selector):
      nodes = subtree.findall(selector)
      if(len(nodes) > 0):
        return int(nodes[0].text, 16)
      else:
        return 0

    tree = xml.parse(self.path).getroot()
    self.area = get_int(tree, "./area")
    self.index = get_int(tree, "./index")
    self.flags = get_int(tree, "./specialGFX")
    states = tree.findall("./States/State")
    self.states = []

    for state_node in states:
      state = {}

      level_data = state_node.findall("./LevelData")[0]
      width = int(level_data.attrib['Width'], 16)
      height = int(level_data.attrib['Height'], 16)
      state['level_data'] = [[None for _ in range(height)] for _ in range(width)]
      state['layer2_type'] = state_node.findall("layer2_type")[0].text

      bts_nodes = state_node.findall("./LevelData/BTS/Screen")
      for bts_node in bts_nodes:
        x = int(bts_node.attrib['X'], 16)
        y = int(bts_node.attrib['Y'], 16)
        bts = [[int(b, 16)] for b in bts_node.text.split()]
        state['level_data'][x][y] = bts
      
      layer1_nodes = state_node.findall("./LevelData/Layer1/Screen")
      for layer1_node in layer1_nodes:
        x = int(layer1_node.attrib['X'], 16)
        y = int(layer1_node.attrib['Y'], 16)
        tiles = [int(t, 16) for t in layer1_node.text.split()]
        for i, tile in enumerate(tiles):
          state['level_data'][x][y][i].append(tiles[i])

      layer2_nodes = state_node.findall("./LevelData/Layer2/Screen")
      for layer2_node in layer2_nodes:
        x = int(layer2_node.attrib['X'], 16)
        y = int(layer2_node.attrib['Y'], 16)
        tiles = [int(t, 16) for t in layer2_node.text.split()]
        for i, tile in enumerate(tiles):
          state['level_data'][x][y][i].append(tiles[i])

      fx_nodes = state_node.findall("./FX1s/FX1")

      if(len(fx_nodes) == 0):
        fx_list = [{
          "heated": False,
          "water": False,
          "lava": False,
          "acid": False,
        }]
      else:
        fx_list = []
        for f_i, fx_node in enumerate(fx_nodes):
          fx = {}
          palette_flags = get_int(fx_node, "./paletteflags")
          fx_type = get_int(fx_node, "type")
          liquid_flags = get_int(fx_node, "liquidflags_C")
          surface_start = get_int(fx_node, "surfacestart")
          surface_new = get_int(fx_node, "surfacenew")
          off_screen_liquid = surface_start > 256 * height and surface_new > 256 * height
          fx['heated'] =  palette_flags & 0x80 != 0
          fx['lava'] = fx_type == 2 and not off_screen_liquid
          fx['acid'] = fx_type == 4 and not off_screen_liquid
          fx['water'] = fx_type == 6 and liquid_flags & 0x04 == 0
          if fx['water']:
            fx['liquidflags'] = get_int(fx_node, "liquidflags") & 0xC4
            fx['surfacestart'] = get_int(fx_node, "surfacestart")
            fx['surfacenew'] = get_int(fx_node, "surfacenew")
            fx['surfacespeed'] = get_int(fx_node, "surfacespeed")
            fx['surfacedelay'] = get_int(fx_node, "surfacedelay")
          fx_list.append(fx)

      state['fx'] = fx_list
      self.states.append(state)

  def include(self):
    return (self.flags & 0x80) == 0x80


class Style:
  def __init__(self, path):
    self.room_path = os.path.relpath(str(path / "Export" / "Rooms"))
    self.name = str(path.name)
    self.rooms = {x : {} for x in range(8)}
    self.excluded = {x : {} for x in range(8)}

    room_files = Path(self.room_path).glob('*.xml')

    for room_file in room_files:
      room = Room(room_file)
      self.rooms[room.area][room.index] = room
      if not room.include() and self.name != "Base":
        self.excluded[room.area][room.index] = room

parser = ArgumentParser(prog="generate_manifest")
parser.add_argument('-r',  dest="root_path")
args = parser.parse_args()
root_path = args.root_path

if root_path is None:
  root_path = (Path(__file__).parent.parent / "Projects").resolve()
else:
  root_path = Path(root_path).resolve()

styles = {y.name : y for y in [Style(x) for x in root_path.iterdir() if x.is_dir()]}

base = styles["Base"]

invalid = 0

filterd_rooms = [
  (0,  4), #CRATERIA SAVE ROOM
  (0,  8), #ELEVATOR TO MARIDIA
  (0, 15), #ELEVATOR TO RED BRINSTAR
  (0, 20), #ELEVATOR TO BLUE BRINSTAR
  (0, 25), #ELEVATOR TO GREEN BRINSTAR
  (0, 27), #CRATERIA MAP ROOM
  (0, 21), #SILVER TORIZO BOSS ROOM
  (0, 51), #STATUE ROOM

  (1,  7), #BRINSTAR MISSILE STATION
  (1, 11), #SPORE SPAWN BOSS ROOM
  (1, 21), #DACHORA ENERGY STATION
  (1, 27), #PINK BRINSTAR SAVE ROOM
  (1, 30), #GREEN BRINSTAR SAVE ROOM
  (1, 31), #ETECOON SAVE ROOM
  (1, 47), #KRAID BOSS ROOM
  (1, 49), #RED BRINSTAR ENERGY STATION
  (1,  5), #BRINSTAR MAP ROOM
  (1, 50), #KRAID REFILL ROOM
  (1, 54), #KRAID SAVE ROOM
  (1, 55), #RED BRINSTAR SAVE ROOM

  (2, 10), #CROCOMIRE BOSS ROOM
  (2, 15), #POST CROCOMIRE SAVE ROOM
  (2, 43), #UPPER NORFAIR ENERGY STATION
  (2, 46), #NORFAIR MAP ROOM
  (2, 47), #BUBBLE MOUNTIAN SAVE ROOM
  (2, 50), #ROCKY NORFAIR SAVE ROOM
  (2, 51), #PRE CROCOMIRE SAVE ROOM
  (2, 52), #RIDLEY HIDEOUT SAVE ROOM
  (2, 55), #GOLD TORIZO BOSS ROOM
  (2, 57), #GOLDEN TORIZO ENERGY STATION
  (2, 58), #RIDLEY BOSS ROOM
  (2, 76), #RED KEYHUNTER SAVE ROOM

  (3,  9), #WRECKED SHIP MAP ROOM
  (3, 10), #PHANTOON BOSS ROOM
  (3, 15), #WRECKED SHIP SAVE ROOM

  (4,  0), #WEST MARIDIA SAVE ROOM
  (4, 22), #MARIDIA MAP ROOM
  (4, 23), #EAST MARIDIA SAVE ROOM
  (4, 41), #MARIDIA AQUEDUCT SAVE ROOM
  (4, 44), #DRAYGON SAVE ROOM
  (4, 45), #MARIDIA MISSILE REFILL ROOM
  (4, 50), #BOTWOON BOSS ROOM
  (4, 52), #DRAYGON ENERGY REFILL
  (4, 55), #DRAYGON BOSS ROOM

  (5,  9), #TOURIAN RECHARGE ROOM
  (5, 10), #MOTHER BRAIN BOSS ROOM
  (5, 13), #MOTHER BRAIN SAVE ROOM
  (5, 18), #TOURIAN ELEVATOR SAVE ROOM
]

# Dust Torizo needs to use BGData, otherwise graphics will get messed up in the room.
required_bg_data_rooms = [
  (5, 6),  #DUST TORIZO
]

# These rooms need to use Layer2 so that the randomizer can edit their backgrounds to insert the Transit Tube.
required_layer2_rooms = [
  (0, 0),  #LANDING SITE
  (0, 2),  #PARLOR AND ALCATRAZ
  (0, 5),  #WEST OCEAN
  (0, 9),  #EAST OCEAN
  (0, 14), #CRATERIA LAKE
  (1, 3),  #EARLY SUPER ROOM
  (1, 12), #PINK BRINSTAR POWER BOMB ROOM
  (1, 15), #CONSTRUCTION ZONE
  (1, 19), #ETECOON ENERGY TANK ROOM
  (1, 25), #PINK BRINSTAR HOPPER ROOM
  (1, 37), #BETA POWER BOMB ROOM
  (1, 40), #BELOW SPAZER
  (1, 46), #KRAID BOSS DOOR
  (1, 52), #KRAID HIDEOUT ENTRANCE
  (2, 1),  #CATHEDRAL ENTRANCE
  (2, 2),  #CATHEDRAL
  (2, 7),  #ICE BEAM SNAKE ROOM
  (2, 8),  #CRUMBLE SHAFT
  (2, 12), #CROCOMIRE ESCAPE
  (2, 14), #POST CROCOMIRE FARMING ROOM
  (2, 20), #GRAPPLE JUMP CAVERN
  (2, 21), #GRAPPLE TUTORIAL ROOM 2
  (2, 23), #GRAPPLE BEAM ROOM
  (2, 26), #BUBBLE MOUNTAIN
  (2, 29), #SINGLE CHAMBER
  (2, 30), #DOUBLE CHAMBER
  (2, 33), #VOLCANO ROOM
  (2, 34), #KRONIC BOOST ROOM
  (2, 37), #LAVA DIVE ROOM
  (2, 45), #BUBBLE MOUNTIAN BAT ROOM
  (2, 60), #FAST PILLARS SETUP ROOM
  (2, 62), #MICKEY MOUSE
  (2, 65), #THE WORST ROOM IN THE GAME
  (2, 66), #AMPHITHEATRE
  (2, 67), #LOWER NORFAIR MAZE ROOM
  (2, 69), #RED KEYHUNTER SHAFT
  (2, 70), #WASTELAND
  (2, 72), #THREE MUSKATEERS ROOM
  (2, 74), #SCREW ATTACK ROOM
  (3, 0),  #BOWLING ALLEY
  (3, 6),  #ELECTRIC DEATH ROOM
  (3, 7),  #WRECKED SHIP ENERGY TANK ROOM
  (4, 5),  #FISH TANK
  (4, 6),  #TURTLE FAMILY ROOM
  (4, 8),  #PUFFER MOUNTIAN
  (4, 10), #WATERING HOLE
  (4, 11), #NORTHWEST MARIDIA BUG ROOM
  (4, 13), #PSEUDO PLASMA SPARK ROOM
  (4, 14), #CRAB HOLE
  (4, 17), #PLASMA BEAM ROOM
  (4, 20), #PLASMA SPARK ROOM
  (4, 21), #PLASMA CLIMB
  (4, 33), #MARIDIA AQUEDUCT
  (4, 36), #PANTS ROOM
  (4, 37), #EAST PANT ROOM
  (4, 42), #DRAYGON BOSS DOOR
  (4, 53), #WEST CACTUS ALLEY
  (5, 2),  #METROID ROOM 2
  (5, 8),  #TOURIAN SEAWEED ROOM
  (5, 12), #RINKA SHAFT
  (5, 16), #TOURIAN HORIZONTAL ESCAPE
  (5, 17), #TOURIAN VERTICAL ESCAPE
]

ignored_styles = [
  "CrateriaPalette",
  "BrinstarPalette",
  "NorfairPalette",
  "WreckedShipPalette",
  "MaridiaPalette",
  "TourianPalette",
]

for name, style in styles.items():
  if name in ignored_styles:
    continue
  excluded_count_list = [len(style.excluded[a_i]) for a_i in range(6)]
  print(f"{name} unready room count: {excluded_count_list}")

  filtered_excluded_list = [sorted([(a_i, r_i, Path(r.path).stem) for r_i, r in style.excluded[a_i].items() if (a_i, r_i) not in filterd_rooms]) for a_i in range(6)]
  print(f"{name} Rooms TODO:")
  for area in filtered_excluded_list:
    for (a_i, r_i, r) in area:
      print(f"  ({a_i}, {r_i:2}), #{r}")

  for a_i, area in style.rooms.items():
    for r_i, room in area.items():
      for s_i, state in enumerate(room.states):
        if (a_i, r_i) in required_bg_data_rooms and state['layer2_type'] != 'BGData':
          print(f"🔴 {room.path} State<{s_i}> expected to have BGData (to prevent graphical glitches), but has {state['layer2_type']}")
          invalid = 1
          
        if (a_i, r_i) in required_layer2_rooms and state['layer2_type'] != 'Layer2':
          print(f"🔴 {room.path} State<{s_i}> expected to have Layer2 (to support Transit Tube passing through), but has {state['layer2_type']}")
          invalid = 1

        if (a_i, r_i) == (2, 48):
          # Check that top two rows of SPEEDBOOSTER RUBBLE HALLWAY match vanilla,
          # since otherwise the shot block PLM overload strats may not work.
          match = True
          for c_i, column in enumerate(state['level_data']):
            for n_i, screen in enumerate(column):
              for b_i, tile_data in list(enumerate(screen))[:32]:
                base_tile_data = base.rooms[a_i][r_i].states[s_i]['level_data'][c_i][n_i][b_i]
                if tile_data != base_tile_data:
                  match = False
          if not match:
              print(f"🔴 {room.path} Top two rows of tiles should match vanilla, for shot block PLM overload strat to work")
              invalid = 1
                
        for c_i, column in enumerate(state['level_data']):
          for n_i, screen in enumerate(column):
            for b_i, tile_data in enumerate(screen):
              bts = tile_data[0]
              tile = tile_data[1]
              layer2 = tile_data[2] if len(tile_data) >= 3 else None
              context_str = f"{room.path} State<{s_i}>Screen({c_i},{n_i})[{b_i:X}]."

              # Check for bad black tiles (ones that may get overwritten by item PLMs)
              # These sometimes come from BGData -> Layer2 conversion.
              if layer2 is not None and 0x8E <= (layer2 & 0x3FF) <= 0x95:
                  print(f"🔴 {context_str} Bad black tile (overwritable by item PLM) in layer 2: {layer2:04X}")
                  invalid = 1

              if name == "Base":
                continue

              if name == "TransitTube":
                base_room = base.rooms[4][0x18]
              else:
                base_room = base.rooms[a_i][r_i]
              tiletype = tile >> 12
              
              base_tile_data = base_room.states[s_i]['level_data'][c_i][n_i][b_i]
              base_bts = base_tile_data[0]
              base_tile = base_tile_data[1]
              base_tiletype = base_tile >> 12

              base_tiletype_bts_str = f"({base_tiletype:X}, {base_bts:02X})"
              tiletype_bts_str = f"({tiletype:X}, {bts:02X})"

              # Basic check on tile type and BTS match:
              if (base_tiletype, base_bts) != (tiletype, bts):
                print(f"🔴 {context_str} Should be {base_tiletype_bts_str} but was {tiletype_bts_str}")
                invalid = 1

              # Grapple block check:
              if tiletype == 0xE and tile & 0xF7FF != base_tile & 0xF7FF:
                print(f"🔴 {context_str} Wrong tile for grapple block: should be {base_tile:04X} but was {tile:04X}")
                invalid = 1

              # Check for background tiles in wrong layer (excluding KRAID BOSS ROOM which has this in vanilla):
              if name == "OuterCrateria" and (a_i, r_i) != (1, 47):
                if tile & 0x3FF in [0x13D, 0x13E, 0x13F]:
                  print(f"🔴 {context_str} Background tile in layer 1: {tile:04X}")
                  invalid = 1

        if name == "TransitTube":
          # Skip FX checks for TransitTube as they would have no effect.
          continue

        base_state = base.rooms[a_i][r_i].states[s_i]
        if len(state['fx']) != len(base_state['fx']):
          print(f"🔴 {room.path} State<{s_i}> Different amount of non-default FX entries")
          invalid = 1
        else:
          for f_i, fx in enumerate(state['fx']):
            base_fx = base.rooms[a_i][r_i].states[s_i]['fx'][f_i]
            context_str = f"{room.path} State<{s_i}>FX({f_i})"
            keys = set(fx.keys()).union(base_fx.keys())
            for key in keys:
              fx_val = fx.get(key)
              base_val = base_fx.get(key)
              if fx_val != base_val:
                print(f"🔴 {context_str} '{key}' is {fx_val} compared to {base_val} in Base")
                invalid = 1

if invalid:
  print("🔴 FAILED")
else:
  print("🟢 PASSED")
exit(invalid)
