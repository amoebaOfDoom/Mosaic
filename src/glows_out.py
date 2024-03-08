import os
from pathlib import Path
import re
from PIL import Image, ImageDraw

def convertToRGB(c):
  r = (c & 0x001F)
  g = (c & 0x03E0) >> 5
  b = (c & 0x7C00) >> 10
  return (r << 3, g << 3, b << 3)

class Palette:
  def __init__(self, name, eq, *colors):
    self.name = name
    self.colors = [convertToRGB(int(re.sub(r'[^0-9A-Fa-f]', '', c), 16)) for c in colors]

asm = (Path(__file__).parent.parent / "Projects" / "Base" / "ASM" / "Area Palette Glows.asm").resolve()
palettes = [Palette(*line[0:-1].split()) for line in open(asm) if re.search(r'^!', line) != None]

w = 16
im = Image.new("RGB", (16 * w, len(palettes) * w), "#6495ED")
g = ImageDraw.Draw(im)

for p_i, p in enumerate(palettes):
  for c_i, c in enumerate(p.colors):
    x = c_i * w
    y = p_i * w
    g.rectangle([(x, y), (x + w, y + w)], fill=c)

im.save("glows.png")
