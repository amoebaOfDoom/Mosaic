REM For area-themed palettes, create symlinks for tilesets that aren't themed.
for %%p in ("CrateriaPalette" "BrinstarPalette" "NorfairPalette" "WreckedShipPalette" "MaridiaPalette" "TourianPalette") do (
  for %%t in (15 16 17 18 19 20) do (
    rd /s /q "Projects\%%p\Export\Tileset\SCE\%%t"
    mklink /D "Projects\%%p\Export\Tileset\SCE\%%t" "..\..\..\..\Base\Export\Tileset\SCE\%%t"
  )
)
