require("Common")

tile_air = 0x0FF
tile_unknown = 0x0DF
tile_unknown_solid = 0x14C
tile_interior = 0x10E          -- gray
tile_deep_interior = 0x10D     -- black
tile_bottom_edge_1 = 0x11C
tile_bottom_edge_2 = 0x11D
tile_under_bottom_edge = 0x113

tile_top_edge = 0x10C
tile_left_edge_1 = 0x105
tile_left_edge_2 = 0x107
tile_beside_right_edge = 0x114
tile_bottom_left_outside_corner = 0x106
tile_top_left_outside_corner = 0x102
tile_top_left_inside_corner = 0x108
tile_bottom_right_inside_corner_1 = tile_bottom_edge_1
tile_bottom_right_inside_corner_2 = tile_bottom_edge_2

tile_half_bottom_edge_1 = 0x128
tile_half_bottom_edge_2 = 0x129
tile_under_half_bottom_edge = tile_interior

tile_half_top_edge = 0x103
tile_above_half_top_edge_vflip = 0x113

tile_half_left_edge = 0x12A
tile_beside_half_right_edge = 0x135

tile_bottom_left_45_slope = 0x124
tile_under_bottom_left_45_slope_hflip = 0x11D
tile_under_under_bottom_left_45_slope = 0x113

tile_top_right_45_slope = 0x125
tile_above_top_right_45_slope = 0x125

tile_top_right_45_small_slope = 0x33F
tile_top_right_45_large_slope_hflip = 0x102

tile_bottom_left_gentle_slope_small = 0x121
tile_bottom_left_gentle_slope_large = 0x120
tile_under_bottom_left_gentle_slope_small = 0x11C
tile_under_bottom_left_gentle_slope_large_hflip = 0x11A
tile_under_under_bottom_left_gentle_slope_small = 0x113

tile_top_right_gentle_slope_small = 0x122
tile_above_top_right_gentle_slope_small_hflip = 0x108
tile_above_above_top_right_gentle_slope_small_hflip = 0x108

tile_top_right_gentle_slope_large = 0x123

tile_bottom_left_steep_slope_small = 0x11E
tile_bottom_left_steep_slope_large = 0x13E
tile_beside_bottom_left_steep_slope_small_vflip = 0x108
tile_beside_bottom_left_steep_slope_large = 0x11A
tile_beside_beside_bottom_left_steep_slope_small = 0x114

tile_top_right_steep_slope_small = 0x13F
tile_beside_top_right_steep_slope_small = 0x108

tile_top_right_steep_slope_large = 0x11F
tile_beside_top_right_steep_slope_small = tile_interior

tile_platform_middle = 0x101
tile_platform_right = 0x102

tile_column = 0x127
tile_column_cap = 0x126

tile_hanging_hflip = 0x10A
tile_below_hanging_hflip = 0x10B

-- Invariant tiles (non-black CRE tiles): leave them unchanged
if invariant(0, 0) then
    return true
end

-- Air tiles: blank them out:
if air(0, 0) then
    if solid(0, -1) and not inside_right(-1, -1) and not inside_left(1, -1) and inside_bottom(0, -2) then
        -- Below single tile hanging from ceiling
        t:set_gfx(tile_below_hanging_hflip, true, false)
        return true
    end

    t:set_gfx(tile_number_air, false, false)
    return true
end

-- Slope tiles: use a matching shape
if t:type(0, 0) == 1 then
    bts = t:bts(0, 0) & 0xBF
    if bts == bts_slope_bottom_right_45 then
        t:set_gfx(tile_bottom_left_45_slope, not bts_hflip(0, 0), false)
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
        t:set_gfx(tile_top_right_45_large_slope_hflip, not bts_hflip(0, 0), false)
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
        t:set_gfx(tile_top_right_steep_slope_large, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_gentle_small then
        t:set_gfx(tile_bottom_left_gentle_slope_small, not bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_gentle_large then
        t:set_gfx(tile_bottom_left_gentle_slope_large, not bts_hflip(0, 0), false)
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
        if (t:abs_x() + t:abs_y())  % 2 == 0 then
            t:set_gfx(tile_bottom_edge_1, false, false)
        else
            t:set_gfx(tile_bottom_edge_2, false, false)
        end
    end
    if bts == bts_slope_whole_bottom_edge | 0x80 and air(0, 1) then
        t:set_gfx(tile_top_edge, false, false)
        return true
    end    
    if (bts == bts_slope_half_bottom_edge_1 or bts == bts_slope_half_bottom_edge_2) and solid(0, 1) then
        if (t:abs_x() + t:abs_y()) % 2 == 0 then
            t:set_gfx(tile_half_bottom_edge_1, false, false)
        else
            t:set_gfx(tile_half_bottom_edge_2, false, false)
        end
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
        t:set_gfx(tile_bottom_left_outside_corner, true, false)
        return true
    end
    if outside_left(1, 0) and inside_right(-1, 0) and outside_bottom(0, -1) and inside_top(0, 1) then
        t:set_gfx(tile_bottom_left_outside_corner, false, false)
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
        if (t:abs_x() + t:abs_y()) % 2 == 0 then
            t:set_gfx(tile_left_edge_1, true, false)
        else
            t:set_gfx(tile_left_edge_2, true, false)
        end
        return true
    end
    if outside_left(1, 0) and inside_right(-1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        if (t:abs_x() + t:abs_y()) % 2 == 0 then
            t:set_gfx(tile_left_edge_1, false, false)
        else
            t:set_gfx(tile_left_edge_2, false, false)
        end
        return true
    end
    if inside_right(-1, 0) and inside_left(1, 0) and outside_bottom(0, -1) and inside_top(0, 1) then
        if (t:abs_x() + t:abs_y()) % 2 == 0 then
            t:set_gfx(tile_bottom_edge_1, false, false)
        else
            t:set_gfx(tile_bottom_edge_2, false, false)
        end
        return true
    end
    if inside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) then
        t:set_gfx(tile_top_edge, false, false)
        return true
    end

    -- Slope adjacent:
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_bottom_right_steep_small and inside_left(1, 0) then
        if not bts_vflip(-1, 0) then
            t:set_gfx(tile_beside_bottom_left_steep_slope_small_vflip, true, true)
        else
            -- t:set_gfx(tile_beside_top_left_steep_slope_small, true, false)
        end
        return true
    end
    if t:type(1, 0) == 1 and t:bts(1, 0) & 0x7F == bts_slope_bottom_right_steep_small | 0x40 and inside_right(-1, 0) then
        if not bts_vflip(1, 0) then
            t:set_gfx(tile_beside_bottom_left_steep_slope_small_vflip, false, true)
            return true
        else
            -- t:set_gfx(tile_beside_top_left_steep_slope_small, false, false)
        end
    end
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_bottom_right_gentle_small and inside_top(0, 1) then
        t:set_gfx(tile_under_bottom_left_gentle_slope_small, not bts_hflip(0, -1), false)
        return true
    end
    if t:type(0, 1) == 1 and t:bts(0, 1) & 0xBF == bts_slope_bottom_right_gentle_small | 0x80 and inside_bottom(0, -1) then
        t:set_gfx(tile_above_top_right_gentle_slope_small_hflip, not bts_hflip(0, 1), false)
        return true
    end
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_bottom_right_gentle_large and inside_top(0, 1) then
        t:set_gfx(tile_under_bottom_left_gentle_slope_large_hflip, bts_hflip(0, -1), false)
        return true
    end

    if t:type(0, -1) == 1 and (t:bts(0, -1) & 0xBF == bts_slope_half_bottom_edge_1 or t:bts(0, -1) & 0xBF == bts_slope_half_bottom_edge_2) and inside_top(0, 1) then
        t:set_gfx(tile_under_half_bottom_edge, false, false)
        return true
    end
    if t:type(0, 1) == 1 and (t:bts(0, 1) & 0xBF == bts_slope_half_bottom_edge_1 | 0x80 or t:bts(0, 1) & 0xBF == bts_slope_half_bottom_edge_2 | 0x80) and inside_bottom(0, -1) then
        t:set_gfx(tile_above_half_top_edge_vflip, false, true)
        return true
    end
    if t:type(-1, 0) == 1 and (t:bts(-1, 0) & 0x7F == bts_slope_half_right_edge) then
        t:set_gfx(tile_beside_half_left_edge, true, false)
        return true
    end
    if t:type(1, 0) == 1 and (t:bts(1, 0) & 0x7F == bts_slope_half_right_edge | 0x40) then
        t:set_gfx(tile_beside_half_left_edge, false, false)
        return true
    end
    if t:type(0, -1) == 1 and (t:bts(0, -1) & 0xBF == bts_slope_bottom_right_45) then
        t:set_gfx(tile_under_bottom_left_45_slope_hflip, bts_hflip(0, -1), false)
        return true
    end

    --if t:type(0, 1) == 1 and (t:bts(0, 1) & 0xBF == bts_slope_bottom_right_45 | 0x80) then
    --    t:set_gfx(tile_under_bottom_right_45_slope, bts_hflip(0, 1), true)
    --    return true
    --end

    if inside_right(-1, 0) and inside_left(1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        -- Inside corners:
        if outside_bottom_right(-1, -1) and not air(1, -1) and not air(-1, 1) and not air(1, 1) then
            if (t:abs_x() + t:abs_y()) % 2 == 0 then
                t:set_gfx(tile_bottom_right_inside_corner_1, false, false)
            else
                t:set_gfx(tile_bottom_right_inside_corner_2, false, false)
            end
            return true
        end
        if not air(-1, -1) and outside_bottom_left(1, -1) and not air(-1, 1) and not air(1, 1) then
            if (t:abs_x() + t:abs_y()) % 2 == 0 then
                t:set_gfx(tile_bottom_right_inside_corner_1, true, false)
            else
                t:set_gfx(tile_bottom_right_inside_corner_2, true, false)
            end
            return true
        end
        if not air(-1, -1) and not air(1, -1) and outside_top_right(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_top_left_inside_corner, true, false)
            return true
        end
        if not air(-1, -1) and not air(1, -1) and not air(-1, 1) and outside_top_left(1, 1) then
            t:set_gfx(tile_top_left_inside_corner, false, false)
            return true
        end
    end    

    -- Platforms:
    if inside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) and outside_top(0, 1) then
        t:set_gfx(tile_platform_middle, false, false)
        return true
    end
    if inside_right(-1, 0) and outside_left(1, 0) and outside_top(0, 1) and outside_top(0, 1) then
        t:set_gfx(tile_platform_right, false, false)
        return true
    end
    if outside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) and outside_top(0, 1) then
        t:set_gfx(tile_platform_right, true, false)
        return true
    end

    if not inside_right(-1, 0) and not inside_left(1, 0) and not inside_bottom(0, -1) and inside_top(0, 1) then
        -- Top of single-tile-wide pillar
        t:set_gfx(tile_column_cap, false, false)
        return true
    end

    if not inside_right(-1, 0) and not inside_left(1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        -- Middle of single-tile-wide pillar
        t:set_gfx(tile_column, false, false)
        return true
    end

    if not inside_right(-1, 0) and not inside_left(1, 0) and inside_bottom(0, -1) and not inside_top(0, 1) then
        -- Single tile hanging from ceiling
        t:set_gfx(tile_hanging_hflip, true, false)
        return true
    end

    -- Low-priority rules:
    
    -- below/above horizontal edges:
    if inside_right(-1, 0) and inside_left(1, 0) and outside_bottom(0, -2) and solid(0, -1) then
        t:set_gfx(tile_under_bottom_edge, false, false)
        return true
    end
    if inside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 2) and solid(0, 1) then
        t:set_gfx(tile_under_bottom_edge, false, true)
        return true
    end
    
    -- behind vertical edges:
    if outside_right(-2, 0) and inside_left(0, 0) and inside_bottom(-1, -1) and inside_top(-1, 1) then
        t:set_gfx(tile_beside_right_edge, false, false)
        return true
    end
    if outside_left(2, 0) and inside_right(0, 0) and inside_bottom(1, -1) and inside_top(1, 1) then
        t:set_gfx(tile_beside_right_edge, true, false)
        return true
    end

    if t:type(0, -2) == 1 and (t:bts(0, -2) & 0xBF == bts_slope_bottom_right_45) and solid(0, -1) then
        t:set_gfx(tile_under_under_bottom_left_45_slope, not bts_hflip(0, -2), false)
        return true
    end
    if t:type(0, -2) == 1 and t:bts(0, -2) & 0xBF == bts_slope_bottom_right_gentle_small and solid(0, -1) then
        t:set_gfx(tile_under_under_bottom_left_gentle_slope_small, not bts_hflip(0, -2), false)
        return true
    end

    if inside_right(-1, 0) and inside_left(1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        -- Interior
        t:set_gfx(tile_deep_interior, false, false)
        return true
    end    

    -- Other solid tiles: fall back to metal block (to be easy to spot for manual editing)
    t:set_gfx(tile_unknown_solid, false, false)
    return true
end

-- Other tiles: mark as unknown (X's)
t:set_gfx(tile_unknown, false, false)