require("Common")

tile_black = 0x081
tile_air = 0x0FF
tile_unknown = 0x0FE
tile_unknown_solid = 0x17D
tile_interior = 0x16E
tile_bottom_edge = 0x16B
tile_under_bottom_edge = 0x18F

tile_top_edge = 0x178
tile_left_edge = 0x16F
tile_bottom_right_outside_corner = 0x16A
tile_top_left_outside_corner = 0x179

tile_half_bottom_edge = 0x22F
tile_under_half_bottom_edge = 0x24F

tile_half_top_edge = 0x18D

tile_half_left_edge = 0x292
tile_beside_half_left_edge = 0x291

tile_bottom_right_45_slope = 0x237
tile_under_bottom_right_45_slope = 0x257
tile_under_under_bottom_right_45_slope = 0x277

tile_top_right_45_slope = 0x177
tile_top_right_45_small_slope = 0x197
tile_top_right_45_large_slope = 0x1D7

tile_bottom_right_gentle_slope_small = 0x234
tile_bottom_right_gentle_slope_large = 0x235
tile_under_bottom_right_gentle_slope_small = 0x254
tile_under_bottom_right_gentle_slope_large = 0x255
tile_under_under_bottom_right_gentle_slope_small = 0x274

tile_top_right_gentle_slope_small = 0x197
tile_top_right_gentle_slope_large = 0x177

tile_bottom_left_steep_slope_small = 0x23B
tile_bottom_left_steep_slope_large = 0x25B
tile_beside_bottom_left_steep_slope_small = 0x23A
tile_beside_bottom_left_steep_slope_large = 0x25A
tile_beside_beside_bottom_left_steep_slope_small = 0x239

tile_top_right_steep_slope_small = 0x197
tile_top_left_steep_slope_large = 0x1D9

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
    bts = t:bts(0, 0) & 0xBF
    if bts == bts_slope_bottom_right_45 then
        t:set_gfx(tile_bottom_right_45_slope, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_45 | 0x80 then
        t:set_gfx(tile_top_right_45_slope, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_45_small | 0x80 then
        t:set_gfx(tile_top_right_45_small_slope, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_45_large | 0x80 then
        t:set_gfx(tile_top_right_45_large_slope, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_steep_small then
        t:set_gfx(tile_bottom_left_steep_slope_small, not bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_steep_small | 0x80 then
        t:set_gfx(tile_top_right_steep_slope_small, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_steep_large then
        t:set_gfx(tile_bottom_left_steep_slope_large, not bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_steep_large | 0x80 then
        t:set_gfx(tile_top_left_steep_slope_large, not bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_gentle_small then
        t:set_gfx(tile_bottom_right_gentle_slope_small, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_gentle_large then
        t:set_gfx(tile_bottom_right_gentle_slope_large, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_gentle_small | 0x80 then
        t:set_gfx(tile_top_right_gentle_slope_small, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_gentle_large | 0x80 then
        t:set_gfx(tile_top_right_gentle_slope_large, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_whole_bottom_edge and air(0, -1) then
        t:set_gfx(tile_bottom_edge, false, false)
        return true
    end
    if bts == bts_slope_whole_bottom_edge | 0x80 and air(0, 1) then
        t:set_gfx(tile_top_edge, false, false)
        return true
    end    
    if (bts == bts_slope_half_bottom_edge_1 or bts == bts_slope_half_bottom_edge_2) and solid(0, 1) then
        t:set_gfx(tile_half_bottom_edge, false, false)
        return true
    end
    if (bts == bts_slope_half_bottom_edge_1 | 0x80 or bts == bts_slope_half_bottom_edge_2 | 0x80) and solid(0, -1) then
        t:set_gfx(tile_half_top_edge, false, false)
        return true
    end
    if bts & 0x3F == bts_slope_half_right_edge then
        t:set_gfx(tile_half_left_edge, not bts_hflip(0, 0), false)
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
        t:set_gfx(tile_top_left_outside_corner, true, false)
        return true
    end
    if outside_left(1, 0) and inside_right(-1, 0) and outside_top(0, 1) and inside_bottom(0, -1) then
        t:set_gfx(tile_top_left_outside_corner, false, false)
        return true
    end

    -- Horizontal/vertical edges:
    if outside_right(-1, 0) and inside_left(1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        t:set_gfx(tile_left_edge, true, false)
        return true
    end
    if outside_left(1, 0) and inside_right(-1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        t:set_gfx(tile_left_edge, false, false)
        return true
    end
    if inside_right(-1, 0) and inside_left(1, 0) and outside_bottom(0, -1) and inside_top(0, 1) then
        t:set_gfx(tile_bottom_edge, false, false)
        return true
    end
    if inside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) then
        t:set_gfx(tile_top_edge, false, false)
        return true
    end

    -- under horizontal edges:
    if inside_right(-1, 0) and inside_left(1, 0) and outside_bottom(0, -2) and solid(0, -1) then
        t:set_gfx(tile_under_bottom_edge, t:abs_x() % 2 == 0, false)
        return true
    end    

    -- Slope adjacent:
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_bottom_right_steep_small and inside_left(1, 0) then
        if not bts_vflip(-1, 0) then
            t:set_gfx(tile_beside_bottom_left_steep_slope_small, true, false)
        else
            -- t:set_gfx(tile_beside_top_left_steep_slope_small, true, false)
        end
        return true
    end
    if t:type(1, 0) == 1 and t:bts(1, 0) & 0x7F == bts_slope_bottom_right_steep_small | 0x40 and inside_right(-1, 0) then
        if not bts_vflip(1, 0) then
            t:set_gfx(tile_beside_bottom_left_steep_slope_small, false, false)
            return true
        else
            -- t:set_gfx(tile_beside_top_left_steep_slope_small, false, false)
        end
    end
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_bottom_right_gentle_small and inside_top(0, 1) then
        t:set_gfx(tile_under_bottom_right_gentle_slope_small, bts_hflip(0, -1), false)
        return true
    end
    if t:type(0, 1) == 1 and t:bts(0, 1) & 0xBF == bts_slope_bottom_right_gentle_small | 0x80 and inside_bottom(0, -1) then
        -- t:set_gfx(tile_under_bottom_right_gentle_slope_small, bts_hflip(0, 1), true)
        -- return true
    end
    if t:type(0, -1) == 1 and (t:bts(0, -1) & 0xBF == bts_slope_half_bottom_edge_1 or t:bts(0, -1) & 0xBF == bts_slope_half_bottom_edge_2) and inside_top(0, 1) then
        t:set_gfx(tile_under_half_bottom_edge, false, false)
        return true
    end
    --if t:type(0, 1) == 1 and (t:bts(0, 1) & 0xBF == bts_slope_half_bottom_edge_1 | 0x80 or t:bts(0, 1) & 0xBF == bts_slope_half_bottom_edge_2 | 0x80) and inside_bottom(0, -1) then
        --t:set_gfx(tile_above_half_top_edge, false, false)
        --return true
    --end
    if t:type(-1, 0) == 1 and (t:bts(-1, 0) & 0x7F == bts_slope_half_right_edge) then
        t:set_gfx(tile_beside_half_left_edge, true, false)
        return true
    end
    if t:type(1, 0) == 1 and (t:bts(1, 0) & 0x7F == bts_slope_half_right_edge | 0x40) then
        t:set_gfx(tile_beside_half_left_edge, false, false)
        return true
    end
    if t:type(0, -1) == 1 and (t:bts(0, -1) & 0xBF == bts_slope_bottom_right_45) then
        t:set_gfx(tile_under_bottom_right_45_slope, bts_hflip(0, -1), false)
        return true
    end
    --if t:type(0, 1) == 1 and (t:bts(0, 1) & 0xBF == bts_slope_bottom_right_45 | 0x80) then
    --    t:set_gfx(tile_under_bottom_right_45_slope, bts_hflip(0, 1), true)
    --    return true
    --end
    if t:type(0, -2) == 1 and (t:bts(0, -2) & 0xBF == bts_slope_bottom_right_45) and solid(0, -1) then
        t:set_gfx(tile_under_under_bottom_right_45_slope, bts_hflip(0, -2), false)
        return true
    end

    if inside_right(-1, 0) and inside_left(1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        -- Interior
        -- t:set_gfx(tile_interior, false, false)
        t:set_gfx(tile_black, false, false)
        return true
    end

    -- Other solid tiles: fall back to metal block (to be easy to spot for manual editing)
    t:set_gfx(tile_unknown_solid, false, false)
    return true
end

-- Other tiles: mark as unknown (X's)
t:set_gfx(tile_unknown, false, false)