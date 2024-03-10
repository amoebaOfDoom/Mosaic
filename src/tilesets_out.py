import os
from pathlib import Path
import re
from PIL import Image, ImageDraw

def convertToRGB(low, hi):
  c = (hi << 8) | low
  r = (c & 0x001F)
  g = (c & 0x03E0) >> 5
  b = (c & 0x7C00) >> 10
  return (r << 3, g << 3, b << 3)

class Palette:
  def __init__(self, path):
    self.colors = []
    row = []
    file = os.path.relpath(str(path / "palette.snes" ))
    with open(file, "rb") as f:
      while (bytes := f.read(2)):
        c = convertToRGB(*bytes)
        row.append(c)
        if(len(row) == 16):
          self.colors.append(row)
          row = []

class Style:
  def __init__(self, path):
    self.sce_path = Path(os.path.relpath(str(path / "Export" / "Tileset" / "SCE" )))
    self.name = re.sub(r'Palette', '', path.name)

    self.palettes = [Palette(x) for x in self.sce_path.iterdir() if x.is_dir()]

root_path = (Path(__file__).parent.parent / "Projects").resolve()
styles = {y.name : y for y in [Style(x) for x in root_path.iterdir() if x.is_dir() and ("Palette" in x.name or x.name == "Base")]}

w = 16
margin = 64

for name, style in styles.items():
  im = Image.new("RGB", ((16 * w) + margin, len(style.palettes) * 9 * w), "#6495ED")
  g = ImageDraw.Draw(im)
  
  prefix = ''
  for p_i, p in enumerate(style.palettes):
    g.text((margin - 8, ((p_i * 9) * w) + 4), "{} {:02X}".format(name , p_i), align='right', anchor='rt', fill=(0,0,0))
    for r_i, r in enumerate(p.colors):
      for c_i, c in enumerate(r):
        x = (c_i * w) + margin
        y = ((p_i * 9) + r_i) * w
        g.rectangle([(x, y), (x + w, y + w)], fill=c)
  
  im.save(name + ".png")
