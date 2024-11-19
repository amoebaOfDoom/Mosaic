require("Common")

tile_solid = 0x141
tile_interior = 0x81
tile_top_right_45_slope = 0x146
tile_top_left_45_slope = 0x147

-- Invariant tiles (non-black CRE tiles): leave them unchanged
if invariant(0, 0) then
    return true
end

-- Air tiles: blank them out:
if air(0, 0) then
    t:set_gfx(tile_number_air, false, false)
    return true
end

-- Slope tiles: use a matching shape
if t:type(0, 0) == 1 then
    bts = t:bts(0, 0) & 0x7F
    if bts == bts_slope_bottom_right_45 then
        t:set_gfx(tile_top_right_45_slope, false, not bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_bottom_right_45 | 0x40 then
        t:set_gfx(tile_top_left_45_slope, false, not bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_whole_bottom_edge and air(0, -1) then
        t:set_gfx(tile_solid, false, false)
        return true
    end
    if bts == bts_slope_whole_bottom_edge | 0x80 and air(0, 1) then
        t:set_gfx(tile_solid, false, true)
        return true
    end    
end

if solid(0, 0) then
    -- Outside corners (opaque):
    if outside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) and inside_bottom(0, -1) then
        t:set_gfx(tile_solid, false, true)
        return true
    end
    if outside_left(1, 0) and inside_right(-1, 0) and outside_top(0, 1) and inside_bottom(0, -1) then
        t:set_gfx(tile_solid, false, true)
        return true
    end

    -- Horizontal/vertical edges:
    if inside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) and inside_bottom(0, -1) then
        t:set_gfx(tile_solid, false, true)
        return true
    end

    if inside_right(-1, 0) and inside_left(1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        -- Interior
        t:set_gfx(tile_interior, false, false)
        return true
    end

    t:set_gfx(tile_solid, false, false)
    return true
end

-- Other tiles: mark as unknown (X's)
t:set_gfx(tile_number_unknown, false, false)
