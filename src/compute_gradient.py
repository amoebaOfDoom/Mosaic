import os
import sys
import fileinput
from pathlib import Path
import re
from PIL import Image, ImageDraw

def convertToRGB(c):
  r = (c & 0x001F)
  g = (c & 0x03E0) >> 5
  b = (c & 0x7C00) >> 10
  return (r << 3, g << 3, b << 3)

def convertFromRGB(c):
  r = c[0] >> 3
  g = c[1] >> 3
  b = c[2] >> 3
  return r | (g << 5) | ( b << 10)

class Palette:
  def __init__(self, name, eq, *colors):
    self.name = name
    self.colors = [convertToRGB(int(re.sub(r'[^0-9A-Fa-f]', '', c), 16)) for c in colors]

asm = (Path(__file__).parent.parent / "Projects" / "Base" / "ASM" / "GlowData.def").resolve()
palettes = [Palette(*line[0:-1].split()) for line in open(asm) if re.search(r'^!', line) != None]

prefix = sys.argv[1]
suffix = None
if(len(sys.argv) > 2):
  suffix = sys.argv[2]
  prefix = prefix + " - " + suffix
print(prefix)

q = ''
start = None
end = None

for p_i, p in enumerate(palettes):
  r = p.name[1:10]
  if(suffix != None):
    r = r + " - " + p.name[-1]
  if(q != r):
    if(r == prefix):
      start = p_i
    q = r
  if(q == prefix):
    end = p_i

steps = (end - start)
step = [((r1-r2)/steps, (g1-g2)/steps, (b1-b2)/steps) for (r1, g1, b1), (r2, g2, b2) in zip(palettes[end].colors, palettes[start].colors)] 
print(step)
print()

print(0, palettes[start].colors)
for i in range(1, steps):
  p = [(int(r1+(r2*i)), int(g1+(g2*i)), int(b1+(b2*i))) for (r1, g1, b1), (r2, g2, b2) in zip(palettes[start].colors, step)]
  print(i, p)
  palettes[start + i].colors = p
print(steps, palettes[end].colors)

q = ''
area = 0

with open(asm, "w") as f:
  for p_i, p in enumerate(palettes):
    r = p.name[1:9]
    if(q != r):
      print(file=f)
      print("; " + r + " colors", file=f)
      q = r
      area = 0
    a = int(p.name[9])
    if (a != area):
      print(file=f)
      area = a
    colors = []
    for c_i, c in enumerate(p.colors):
      c = convertFromRGB(c)
      colors.append("${:04X}".format(c))
    print(p.name + " = " + ', '.join(colors), file=f)
