import os
from argparse import ArgumentParser
from pathlib import Path
import xml.etree.ElementTree as xml
import json

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
      level_data = state_node.findall("./LevelData")[0]
      width = int(level_data.attrib['Width'], 16)
      height = int(level_data.attrib['Height'], 16)
      state = [[None for x in range(height)] for y in range(width)]

      bts_nodes = state_node.findall("./LevelData/BTS/Screen")
      for bts_node in bts_nodes:
        x = int(bts_node.attrib['X'], 16)
        y = int(bts_node.attrib['Y'], 16)
        bts = [int(b, 16) for b in bts_node.text.split()]
        state[x][y] = bts
      
      layer1_nodes = state_node.findall("./LevelData/Layer1/Screen")
      for layer1_node in layer1_nodes:
        x = int(layer1_node.attrib['X'], 16)
        y = int(layer1_node.attrib['Y'], 16)
        tiles = [(int(t, 16) & 0xF000) for t in layer1_node.text.split()]
        for i, tile in enumerate(tiles):
          state[x][y][i] |= tiles[i]

      self.states.append(state)

  def include(self):
    return (self.flags & 0x80) == 0x80


class Style:
  def __init__(self, path):
    self.room_path = os.path.relpath(str(path / "Export" / "Rooms"))
    self.name = str(path.name)
    self.rooms = {x : {} for x in range(8)}

    room_files = Path(self.room_path).glob('*.xml')

    for room_file in room_files:
      room = Room(room_file)
      if room.include() or self.name == "Base":
        self.rooms[room.area][room.index] = room

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

valid = 0

for name, style in styles.items():
  if name == "Base":
    next

  for a_i, area in style.rooms.items():
    for r_i, room in area.items():
      for s_i, state in enumerate(room.states):
        for c_i, column in enumerate(state):
          for n_i, screen in enumerate(column):
            for b_i, bts in enumerate(screen):
              base_bts = base.rooms[a_i][r_i].states[s_i][c_i][n_i][b_i]
              if(base_bts & 0xFF != bts & 0xFF):
                print(f"Bad bts in file: {room.path} State<{s_i}>Screen({c_i},{n_i})[{b_i}]. Should be {(base_bts & 0xFF):02X} but was {(bts & 0xFF):02X}")
                valid = 1
              if(base_bts & 0xF000 != bts & 0xF000):
                print(f"Bad tile type in file: {room.path} State<{s_i}>Screen({c_i},{n_i})[{b_i}]. Should be {(base_bts & 0xF000):04X} but was {(bts & 0xF000):04X}")
                valid = 1

exit(valid)
