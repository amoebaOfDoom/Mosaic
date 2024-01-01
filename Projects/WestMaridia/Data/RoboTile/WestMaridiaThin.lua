require("Common")

tile_air = 0x0FF
tile_unknown = 0x0DF
tile_unknown_solid = 0x05F
tile_interior = 0x11D
tile_bottom_edge = 0x12D

tile_right_edge = 0x122
tile_bottom_right_outside_corner = 0x123
tile_bottom_right_inside_corner = 0x121

tile_half_bottom_edge = 0x130
tile_half_right_edge = 0x12F

tile_bottom_right_45_slope = 0x120
tile_below_bottom_right_45_slope = 0x121

tile_bottom_right_45_small_slope = 0x127
tile_bottom_right_45_large_slope = 0x133

tile_bottom_right_gentle_slope_large = 0x125
tile_below_bottom_right_gentle_slope_large = tile_interior

tile_bottom_right_gentle_slope_small = 0x124
tile_below_bottom_right_gentle_slope_small = 0x126

tile_bottom_right_steep_slope_small = 0x12A
tile_beside_bottom_right_steep_slope_small = 0x12C

tile_bottom_right_steep_slope_large = 0x12B
tile_beside_bottom_right_steep_slope_large = tile_interior

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
    bts = t:bts(0, 0) & 0x3F
    if bts == bts_slope_bottom_right_45 then
        t:set_gfx(tile_bottom_right_45_slope, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_bottom_right_45_small then
        t:set_gfx(tile_bottom_right_45_small_slope, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_bottom_right_45_large then
        t:set_gfx(tile_bottom_right_45_large_slope_hflip, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_bottom_right_steep_small then
        t:set_gfx(tile_bottom_right_steep_slope_small, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_bottom_right_steep_large then
        t:set_gfx(tile_bottom_right_steep_slope_large, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_bottom_right_gentle_small then
        t:set_gfx(tile_bottom_right_gentle_slope_small, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_bottom_right_gentle_large then
        t:set_gfx(tile_bottom_right_gentle_slope_large, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if t:bts(0, 0) & 0xBF == bts_slope_whole_bottom_edge and air(0, -1) then
        t:set_gfx(tile_bottom_edge, false, false)
    end
    if t:bts(0, 0) & 0xBF == bts_slope_whole_bottom_edge | 0x80 and air(0, 1) then
        t:set_gfx(tile_bottom_edge, false, true)
        return true
    end    
    if (t:bts(0, 0) & 0xBF == bts_slope_half_bottom_edge_1 or t:bts(0, 0) & 0xBF == bts_slope_half_bottom_edge_2) and solid(0, 1) then
        t:set_gfx(tile_half_bottom_edge, false, false)
        return true
    end
    if (t:bts(0, 0) & 0xBF == bts_slope_half_bottom_edge_1 | 0x80 or t:bts(0, 0) & 0xBF == bts_slope_half_bottom_edge_2 | 0x80) and solid(0, -1) then
        t:set_gfx(tile_half_bottom_edge, false, true)
        return true
    end
    if bts == bts_slope_half_right_edge then
        t:set_gfx(tile_half_right_edge, bts_hflip(0, 0), false)
        return true
    end
end

-- Solid tiles: look at neighboring edges
if solid(0, 0) then
    -- Outside corners (opaque):
    if outside_right(-1, 0) and inside_left(1, 0) and outside_bottom(0, -1) and inside_top(0, 1) then
        t:set_gfx(tile_bottom_right_outside_corner, false, false)
        return true
    end
    if outside_left(1, 0) and inside_right(-1, 0) and outside_bottom(0, -1) and inside_top(0, 1) then
        t:set_gfx(tile_bottom_right_outside_corner, true, false)
        return true
    end
    if outside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) and inside_bottom(0, -1) then
        t:set_gfx(tile_bottom_right_outside_corner, false, true)
        return true
    end
    if outside_left(1, 0) and inside_right(-1, 0) and outside_top(0, 1) and inside_bottom(0, -1) then
        t:set_gfx(tile_bottom_right_outside_corner, true, true)
        return true
    end

    -- Horizontal/vertical edges:
    if outside_right(-1, 0) and inside_left(1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        t:set_gfx(tile_right_edge, false, false)
        return true
    end
    if outside_left(1, 0) and inside_right(-1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        t:set_gfx(tile_right_edge, true, false)
        return true
    end
    if inside_right(-1, 0) and inside_left(1, 0) and outside_bottom(0, -1) and inside_top(0, 1) then
        t:set_gfx(tile_bottom_edge, false, false)
        return true
    end
    if inside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) then
        t:set_gfx(tile_bottom_edge, false, true)
        return true
    end

    -- Slope adjacent:
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_bottom_right_steep_small and inside_left(1, 0) then
        t:set_gfx(tile_beside_bottom_right_steep_slope_small, false, bts_vflip(-1, 0))
        return true
    end
    if t:type(1, 0) == 1 and t:bts(1, 0) & 0x7F == bts_slope_bottom_right_steep_small | 0x40 and inside_right(-1, 0) then
        t:set_gfx(tile_beside_bottom_right_steep_slope_small, true, bts_vflip(1, 0))
        return true
    end
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_bottom_right_steep_large and inside_left(1, 0) then
        t:set_gfx(tile_beside_bottom_right_steep_slope_large, false, bts_vflip(-1, 0))
        return true
    end
    if t:type(1, 0) == 1 and t:bts(1, 0) & 0x7F == bts_slope_bottom_right_steep_large | 0x40 and inside_right(-1, 0) then
        t:set_gfx(tile_beside_bottom_right_steep_slope_large, true, bts_vflip(1, 0))
        return true
    end
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_bottom_right_gentle_large and inside_top(0, 1) then
        t:set_gfx(tile_below_bottom_right_gentle_slope_large, bts_hflip(0, -1), false)
        return true
    end
    if t:type(0, 1) == 1 and t:bts(0, 1) & 0xBF == bts_slope_bottom_right_gentle_large | 0x80 and inside_bottom(0, -1) then
        t:set_gfx(tile_below_bottom_right_gentle_slope_large, bts_hflip(0, 1), true)
        return true
    end
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_bottom_right_gentle_small and inside_top(0, 1) then
        t:set_gfx(tile_below_bottom_right_gentle_slope_small, bts_hflip(0, -1), false)
        return true
    end
    if t:type(0, 1) == 1 and t:bts(0, 1) & 0xBF == bts_slope_bottom_right_gentle_small | 0x80 and inside_bottom(0, -1) then
        t:set_gfx(tile_below_bottom_right_gentle_slope_small, bts_hflip(0, 1), true)
        return true
    end

    if t:type(0, -1) == 1 and (t:bts(0, -1) & 0xBF == bts_slope_bottom_right_45) then
        t:set_gfx(tile_below_bottom_right_45_slope, bts_hflip(0, -1), false)
        return true
    end
    if t:type(0, 1) == 1 and (t:bts(0, 1) & 0xBF == bts_slope_bottom_right_45 | 0x80) then
       t:set_gfx(tile_below_bottom_right_45_slope, bts_hflip(0, 1), true)
       return true
    end

    if inside_right(-1, 0) and inside_left(1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        -- Inside corners:
        if air(-1, -1) and not air(1, -1) and not air(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_bottom_right_inside_corner, false, false)
            return true
        end
        if not air(-1, -1) and air(1, -1) and not air(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_bottom_right_inside_corner, true, false)
            return true
        end
        if not air(-1, -1) and not air(1, -1) and air(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_bottom_right_inside_corner, false, true)
            return true
        end
        if not air(-1, -1) and not air(1, -1) and not air(-1, 1) and air(1, 1) then
            t:set_gfx(tile_bottom_right_inside_corner, true, true)
            return true
        end
    end    

    if inside_right(-1, 0) and inside_left(1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        -- Interior
        t:set_gfx(tile_interior, false, false)
        return true
    end    

    -- Other solid tiles: fall back to metal block (to be easy to spot for manual editing)
    t:set_gfx(tile_unknown_solid, false, false)
    return true
end

-- Other tiles: mark as unknown (X's)
t:set_gfx(tile_unknown, false, false)
