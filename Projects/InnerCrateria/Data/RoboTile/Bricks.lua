require("Common")

tile_air = 0x0FF
tile_solid_1 = 0x2B6
tile_solid_2 = 0x2B7
tile_solid_3 = 0x2B8
tile_unknown = 0x0FE

normal_solid = {tile_solid_1, tile_solid_2, tile_solid_3}

-- Invariant tiles (non-black CRE tiles): leave them unchanged
if invariant(0, 0) then
    return true
end

-- Air tiles: blank them out:
if air(0, 0) then
    t:set_gfx(tile_air, false, false)
    return true
end

-- Solid tiles: use brick pattern
if solid(0, 0) then
    t:set_gfx(normal_solid[((t:abs_x() + t:abs_y()) % 3) + 1], false, false)
    return true
end

-- Other tiles: mark as unknown (X's)
t:set_gfx(tile_unknown, false, false) 