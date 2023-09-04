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
    def get_str(subtree, selector):
      nodes = subtree.findall(selector)
      if(len(nodes) > 0):
        return nodes[0].text
      else:
        return ''

    tree = xml.parse(self.path).getroot()
    self.area = get_int(tree, "./area")
    self.index = get_int(tree, "./index")
    self.flags = get_int(tree, "./specialGFX")
    states = tree.findall("./States/State")
    self.states = []

    for state_node in states:
      state = {}
      bgpointer = get_str(state_node, "./layer2_type") == 'BGData'
      if bgpointer:
        bgdata = state_node.findall("./BGData/Data")
        if (len(bgdata) != 1):
          state['bgpointer_mode'] = None
        else:
          if(bgdata[0].attrib['Type'] != 'DECOMP'):
            state['bgpointer_mode'] = None
          else:
            state['bgdata'] = hash(tuple(int(x, 16) for x in get_str(bgdata[0], "./SOURCE").split()))
            state['bgpointer_mode'] = True
      else:
        state['bgpointer_mode'] = False
      
      self.states.append(state)

  def include(self):
    return (self.flags & 0x80) == 0x80

class Style:
  base = None

  def __init__(self, path):
    self.room_path = os.path.relpath(str(path / "Export" / "Rooms"))
    self.name = str(path.name)
    self.rooms = {x : {} for x in range(8)}

  def load(self, base=None):
    if self is base:
      return

    room_files = Path(self.room_path).glob('*.xml')

    if base is None:
      for room_file in room_files:
        room = Room(room_file)
        self.rooms[room.area][room.index] = [room]
      base = self
    else:
      for room_file in room_files:
        room = Room(room_file)
        if base.rooms[room.area][room.index] is None:
          next

        if room.include():
          self.rooms[room.area][room.index] = [room]

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
base.load()

for name, style in styles.items():
  style.load(base)

vanilla_bgpointers = {
#rooms.SelectMany(
#    room => statelist
#    .Where(state.layer2_type == 1)
#    .SelectMany(sc => sc.state.BGData
#        .Select(
#        string.Format("  ({1}, 0x{2:X2}) : 0x{0:X},",
#            sc.state.BGData[0].address.GetShortAddressSNES(),
#            room.area,
#            room.index
#        ))
#    )
#).OrderBy(s => s).Distinct()
#Query Completed:
  (0, 0x00) : 0xB76A,
  (0, 0x01) : 0xB899,
  (0, 0x02) : 0xB8B4,
  (0, 0x03) : 0xB8B4,
  (0, 0x05) : 0xB7AE,
  (0, 0x06) : 0xB899,
  (0, 0x07) : 0xB8B4,
  (0, 0x08) : 0xB93B,
  (0, 0x09) : 0xB7F2,
  (0, 0x0A) : 0xB87E,
  (0, 0x0B) : 0xB8B4,
  (0, 0x0C) : 0xB87E,
  (0, 0x0E) : 0xB8B4,
  (0, 0x0F) : 0xB93B,
  (0, 0x10) : 0xB899,
  (0, 0x11) : 0xB80A,
  (0, 0x12) : 0xB905,
  (0, 0x13) : 0xB905,
  (0, 0x15) : 0xB905,
  (0, 0x16) : 0xB8EA,
  (0, 0x17) : 0xB920,
  (0, 0x18) : 0xB8CF,
  (0, 0x1A) : 0xB8CF,
  (0, 0x1C) : 0xB956,
  (0, 0x1D) : 0xB905,
  (0, 0x1E) : 0xB956,
  (0, 0x1F) : 0xB905,
  (0, 0x30) : 0xBCA4,
  (0, 0x33) : 0xBB60,
  (1, 0x01) : 0xBABE,
  (1, 0x02) : 0xBA88,
  (1, 0x03) : 0xBAA3,
  (1, 0x04) : 0xBA6D,
  (1, 0x09) : 0xBB45,
  (1, 0x0A) : 0xBA52,
  (1, 0x0C) : 0xBAA3,
  (1, 0x0D) : 0xBAD9,
  (1, 0x0E) : 0xBAF4,
  (1, 0x0F) : 0xBABE,
  (1, 0x10) : 0xBAF4,
  (1, 0x11) : 0xBA52,
  (1, 0x12) : 0xBA52,
  (1, 0x13) : 0xBA52,
  (1, 0x14) : 0xBA52,
  (1, 0x17) : 0xBAA3,
  (1, 0x18) : 0xBABE,
  (1, 0x19) : 0xBAA3,
  (1, 0x1C) : 0xBAF4,
  (1, 0x1D) : 0xBAF4,
  (1, 0x20) : 0xBB7B,
  (1, 0x22) : 0xBC38,
  (1, 0x23) : 0xBBCC,
  (1, 0x25) : 0xBBE7,
  (1, 0x26) : 0xBCEC,
  (1, 0x27) : 0xBBE7,
  (1, 0x28) : 0xBC02,
  (1, 0x29) : 0xBCEC,
  (1, 0x2D) : 0xBC6E,
  (1, 0x2F) : 0xB815,
  (1, 0x2F) : 0xB840,
  (1, 0x34) : 0xBC53,
  (2, 0x00) : 0xBE3F,
  (2, 0x03) : 0xBEE1,
  (2, 0x04) : 0xBE5A,
  (2, 0x05) : 0xBE3F,
  (2, 0x06) : 0xBE5A,
  (2, 0x07) : 0xBE5A,
  (2, 0x08) : 0xBEE1,
  (2, 0x09) : 0xBE5A,
  (2, 0x0A) : 0xB84D,
  (2, 0x0A) : 0xB858,
  (2, 0x0B) : 0xBE3F,
  (2, 0x10) : 0xBEC6,
  (2, 0x11) : 0xBEE1,
  (2, 0x12) : 0xBEC6,
  (2, 0x13) : 0xBE5A,
  (2, 0x15) : 0xBEE1,
  (2, 0x16) : 0xBEC6,
  (2, 0x17) : 0xBEE1,
  (2, 0x18) : 0xBF68,
  (2, 0x19) : 0xBF83,
  (2, 0x1A) : 0xBF83,
  (2, 0x1B) : 0xBE5A,
  (2, 0x1C) : 0xBE3F,
  (2, 0x1F) : 0xBEC6,
  (2, 0x20) : 0xBEC6,
  (2, 0x23) : 0xBEC6,
  (2, 0x24) : 0xBF68,
  (2, 0x25) : 0xBE5A,
  (2, 0x26) : 0xBEC6,
  (2, 0x28) : 0xBEC6,
  (2, 0x29) : 0xBEC6,
  (2, 0x2A) : 0xBEC6,
  (2, 0x2C) : 0xBF68,
  (2, 0x30) : 0xBE3F,
  (2, 0x31) : 0xBEE1,
  (2, 0x35) : 0xBF32,
  (2, 0x36) : 0xBF17,
  (2, 0x38) : 0xBF17,
  (2, 0x3A) : 0xBF32,
  (2, 0x3B) : 0xBF4D,
  (2, 0x3C) : 0xBEAB,
  (2, 0x3E) : 0xBF68,
  (2, 0x3F) : 0xBF17,
  (2, 0x40) : 0xBF4D,
  (2, 0x41) : 0xBEFC,
  (2, 0x42) : 0xBE5A,
  (2, 0x43) : 0xBF68,
  (2, 0x44) : 0xBF32,
  (2, 0x45) : 0xBE5A,
  (2, 0x46) : 0xBF32,
  (2, 0x47) : 0xBF4D,
  (2, 0x48) : 0xBF68,
  (2, 0x49) : 0xBF32,
  (2, 0x4A) : 0xBF32,
  (3, 0x01) : 0xE117,
  (3, 0x02) : 0xE168,
  (3, 0x03) : 0xE1B9,
  (3, 0x04) : 0xE19E,
  (3, 0x05) : 0xE14D,
  (3, 0x06) : 0xE19E,
  (3, 0x08) : 0xE14D,
  (3, 0x0A) : 0xE0FD,
  (3, 0x0A) : 0xE113,
  (3, 0x0B) : 0xE183,
  (3, 0x0C) : 0xE183,
  (3, 0x0D) : 0xE183,
  (3, 0x0D) : 0xE19E,
  (3, 0x0E) : 0xE183,
  (4, 0x07) : 0xE248,
  (4, 0x1A) : 0xE25A,
  (4, 0x1C) : 0xE25A,
  (4, 0x37) : 0xE108,
  (4, 0x37) : 0xE113,
  (5, 0x00) : 0xE3E8,
  (5, 0x01) : 0xE403,
  (5, 0x02) : 0xE3E8,
  (5, 0x03) : 0xE403,
  (5, 0x04) : 0xE3E8,
  (5, 0x05) : 0xE41E,
  (5, 0x06) : 0xE41E,
  (5, 0x07) : 0xE41E,
  (5, 0x08) : 0xE41E,
  (5, 0x0A) : 0xE48A,
  (5, 0x0B) : 0xE41E,
  (5, 0x0C) : 0xE454,
  (5, 0x0E) : 0xE439,
  (5, 0x0F) : 0xE454,
  (5, 0x10) : 0xE46F,
  (5, 0x11) : 0xE46F,
  (6, 0x01) : 0xE4A5,
  (6, 0x02) : 0xE4A5,
  (6, 0x04) : 0xE4A5,
  (7, 0x00) : 0xE117,
}

hashed_bgpointers = {}

for _, area in base.rooms.items():
  for _, room in area.items():
    for state in room[0].states:
      if state['bgpointer_mode'] is True:
        if state['bgdata'] not in hashed_bgpointers:
          hashed_bgpointers[state['bgdata']] = vanilla_bgpointers[(room[0].area, room[0].index)]

for _, style in styles.items():
  for _, area in style.rooms.items():
    for _, rooms in area.items():
      for room in rooms:
        for state in room.states:
          if state['bgpointer_mode'] is True:
            if state['bgdata'] in hashed_bgpointers:
              state['bgpointer'] = hashed_bgpointers[state['bgdata']]
            else:
              print('Room is using non-vanilla bgpointer', room.path)
          elif state['bgpointer_mode'] is None:
            state['bgpointer'] = vanilla_bgpointers[(room.area, room.index)]

print(json.dumps(styles, default=vars, indent=2))
