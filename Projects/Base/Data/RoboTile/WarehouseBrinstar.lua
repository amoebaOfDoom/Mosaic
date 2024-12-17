require("Common")

tile_air = 0x0FF
tile_unknown = 0x0DF
tile_unknown_solid = 0x5F
tile_interior = 0x131
tile_bottom_edge = 0x111
tile_right_edge = 0x130
tile_bottom_right_outside_corner = 0x110
tile_bottom_right_inside_corner = 0x1B2

tile_half_bottom_edge = 0x21D

tile_half_right_edge = 0x21A

tile_bottom_right_45_slope = 0x21B
tile_under_bottom_right_45_slope = 0x23B

tile_bottom_right_45_small_slope = 0x1FB
tile_bottom_right_45_large_slope = 0x1FD

tile_bottom_right_gentle_slope_small = 0x239
tile_bottom_right_gentle_slope_large = 0x23A
tile_under_bottom_right_gentle_slope_small = 0x259

tile_bottom_left_steep_slope_small = 0x27C
tile_bottom_left_steep_slope_large = 0x29C
tile_beside_bottom_left_steep_slope_small = 0x27B

tile_platform_middle = 0x2DC
tile_platform_left = 0x2DB

tile_column = 0x18C
tile_column_cap = 0x18E

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
        t:set_gfx(tile_bottom_right_45_slope, bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_bottom_right_45_small | 0x80 then
        t:set_gfx(tile_bottom_right_45_small_slope, bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_bottom_right_45_large | 0x80 then
        t:set_gfx(tile_bottom_right_45_large_slope, bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_bottom_right_steep_small then
        t:set_gfx(tile_bottom_left_steep_slope_small, not bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_steep_small | 0x80 then
        t:set_gfx(tile_bottom_left_steep_slope_small, not bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_bottom_right_steep_large then
        t:set_gfx(tile_bottom_left_steep_slope_large, not bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_steep_large | 0x80 then
        t:set_gfx(tile_bottom_left_steep_slope_large, not bts_hflip(0, 0), true)
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
        t:set_gfx(tile_bottom_right_gentle_slope_small, bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_bottom_right_gentle_large | 0x80 then
        t:set_gfx(tile_bottom_right_gentle_slope_large, bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_whole_bottom_edge and air(0, -1) then
        t:set_gfx(tile_bottom_edge, false, false)
        return true
    end
    if bts == bts_slope_whole_bottom_edge | 0x80 and air(0, 1) then
        t:set_gfx(tile_bottom_edge, false, true)
        return true
    end    
    if (bts == bts_slope_half_bottom_edge_1 or bts == bts_slope_half_bottom_edge_2) and solid(0, 1) then
        t:set_gfx(tile_half_bottom_edge, false, false)
        return true
    end
    if (bts == bts_slope_half_bottom_edge_1 | 0x80 or bts == bts_slope_half_bottom_edge_2 | 0x80) and solid(0, -1) then
        t:set_gfx(tile_half_bottom_edge, false, true)
        return true
    end
    if bts & 0x3F == bts_slope_half_right_edge then
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
    if inside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) and inside_bottom(0, -1) then
        t:set_gfx(tile_bottom_edge, false, true)
        return true
    end

    -- Slope adjacent:
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_bottom_right_steep_small and inside_left(1, 0) then
        t:set_gfx(tile_beside_bottom_left_steep_slope_small, true, bts_vflip(-1, 0))
        return true
    end
    if t:type(1, 0) == 1 and (t:bts(1, 0) & 0x7F) == (bts_slope_bottom_right_steep_small | 0x40) and inside_right(-1, 0) then
        t:set_gfx(tile_beside_bottom_left_steep_slope_small, false, bts_vflip(1, 0))
        return true
    end
    
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_bottom_right_gentle_small and inside_top(0, 1) then
        t:set_gfx(tile_under_bottom_right_gentle_slope_small, bts_hflip(0, -1), false)
        return true
    end
    if t:type(0, 1) == 1 and t:bts(0, 1) & 0xBF == bts_slope_bottom_right_gentle_small | 0x80 and inside_bottom(0, -1) then
        t:set_gfx(tile_under_bottom_right_gentle_slope_small, bts_hflip(0, 1), true)
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

    if inside_right(-1, 0) and inside_left(1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        -- Inside corners:
        if outside_bottom_right(-1, -1) and not air(1, -1) and not air(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_bottom_right_inside_corner, false, false)
            return true
        end
        if not air(-1, -1) and outside_bottom_left(1, -1) and not air(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_bottom_right_inside_corner, true, false)
            return true
        end
        if not air(-1, -1) and not air(1, -1) and outside_top_right(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_bottom_right_inside_corner, false, true)
            return true
        end
        if not air(-1, -1) and not air(1, -1) and not air(-1, 1) and outside_top_left(1, 1) then
            t:set_gfx(tile_bottom_right_inside_corner, true, true)
            return true
        end
    end    

    -- Platforms:
    if inside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) and outside_bottom(0, -1) then
        t:set_gfx(tile_platform_middle, false, false)
        return true
    end
    if inside_right(-1, 0) and outside_left(1, 0) and outside_top(0, 1) and outside_bottom(0, -1) then
        t:set_gfx(tile_platform_left, true, false)
        return true
    end
    if outside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) and outside_bottom(0, -1) then
        t:set_gfx(tile_platform_left, false, false)
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

    if inside_right(-1, 0) and inside_left(1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        -- Interior
        t:set_gfx(tile_interior, false, false)
        return true
    end    

    -- Other solid tiles: fall back to CRE block (to be easy to spot for manual editing)
    t:set_gfx(tile_unknown_solid, false, false)
    return true
end

-- Other tiles: mark as unknown (X's)
t:set_gfx(tile_unknown, false, false)
