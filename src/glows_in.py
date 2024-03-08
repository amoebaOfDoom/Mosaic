import os
from pathlib import Path
import re
from PIL import Image

def convertFromRGB(c):
  r = c[0] >> 3
  g = c[1] >> 3
  b = c[2] >> 3
  return r | (g << 5) | ( b << 10)

class Palette:
  def __init__(self, name, eq, *colors):
    self.name = name
    self.colors = [re.sub(r'[^0-9A-Fa-f]', '', c) for c in colors]

asm = (Path(__file__).parent.parent / "Projects" / "Base" / "ASM" / "GlowData.def").resolve()
palettes = [Palette(*line[0:-1].split()) for line in open(asm) if re.search(r'^!', line) != None]

w = 16
margin = 64
im = Image.open("glows.png")
px = im.load()

prefix = ''
area = 0

with open(asm, "w") as f:
  for p_i, p in enumerate(palettes):
    r = p.name[1:9]
    if(prefix != r):
      print(file=f)
      print("; " + prefix + " colors", file=f)
      prefix = r
      area = 0
    a = int(p.name[9])
    if (a != area):
      print(file=f)
      area = a
    colors = []
    for c_i, _ in enumerate(p.colors):
      x = (c_i * w) + (w / 2) + margin
      y = (p_i * w) + (w / 2)
      c = convertFromRGB(px[x , y])
      colors.append("${:04X}".format(c))
    print(p.name + " = " + ', '.join(colors), file=f)
