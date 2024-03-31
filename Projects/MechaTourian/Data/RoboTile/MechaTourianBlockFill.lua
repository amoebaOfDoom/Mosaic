require("Common")

tile_air = 0x0FF
tile_solid = 0x02E3
tile_unknown = 0x06A

if invariant(0, 0) then
    return true
end

if air(0, 0) then
    t:set_gfx(tile_number_air, false, false)
    return true
end

if solid(0, 0) then
    t:set_gfx(tile_solid, false, false)
    return true
end

t:set_gfx(tile_unknown, false, false) 