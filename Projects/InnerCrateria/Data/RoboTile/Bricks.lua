require("Common")

tile_air = 0x0FF
tile_solid_1 = 0x2B6
tile_solid_2 = 0x2B8
tile_unknown = 0x0FE

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
    if (t:abs_x() + t:abs_y()) % 2 == 0 then
        t:set_gfx(tile_solid_1, false, false)
    else
        t:set_gfx(tile_solid_2, false, false)        
    end
    return true
end

-- Other tiles: mark as unknown (X's)
t:set_gfx(tile_unknown, false, false) 