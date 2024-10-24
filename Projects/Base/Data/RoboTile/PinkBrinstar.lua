require("Common")

tile_black = 0x081
tile_air = 0x0FF
tile_unknown = 0x0DF
tile_unknown_solid = 0x1BD
tile_interior = tile_black

tile_bottom_edge_1 = 0x307
tile_bottom_edge_2 = 0x308
tile_under_bottom_edge_1 = 0x327
tile_under_bottom_edge_2 = 0x328

tile_left_edge = 0x350
tile_bottom_left_outside_corner = 0x317
tile_top_right_inside_corner_1 = 0x307
tile_top_right_inside_corner_2 = 0x308

tile_half_bottom_edge_1 = 0x31A
tile_half_bottom_edge_2 = 0x31B
tile_under_half_bottom_edge_1 = 0x33A
tile_under_half_bottom_edge_2 = 0x33B

tile_half_left_edge = 0x37F
tile_beside_half_left_edge = 0x37E

tile_bottom_left_45_slope = 0x309
tile_under_bottom_right_45_slope = 0x307
tile_under_under_bottom_right_45_slope = 0x329

tile_bottom_left_45_small_slope = tile_unknown
tile_bottom_left_45_large_slope = 0x34D

tile_bottom_left_gentle_slope_small = 0x392
tile_bottom_left_gentle_slope_large = 0x391
tile_under_bottom_right_gentle_slope_small = tile_black
tile_under_bottom_right_gentle_slope_large = tile_black
tile_under_under_bottom_right_gentle_slope_small = tile_black

tile_bottom_left_steep_slope_small = 0x374
tile_bottom_left_steep_slope_large = 0x394
tile_beside_bottom_left_steep_slope_small = tile_black
tile_beside_bottom_left_steep_slope_large = tile_black
tile_beside_beside_bottom_left_steep_slope_small = tile_black

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
        t:set_gfx(tile_bottom_left_45_slope, not bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_45 | 0x80 then
        t:set_gfx(tile_bottom_left_45_slope, not bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_bottom_right_45_small | 0x80 then
        t:set_gfx(tile_bottom_left_45_small_slope, not bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_bottom_right_45_large | 0x80 then
        t:set_gfx(tile_bottom_left_45_large_slope, not bts_hflip(0, 0), true)
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
        t:set_gfx(tile_bottom_left_gentle_slope_small, not bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_gentle_large then
        t:set_gfx(tile_bottom_left_gentle_slope_large, not bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_gentle_small | 0x80 then
        t:set_gfx(tile_bottom_left_gentle_slope_small, not bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_bottom_right_gentle_large | 0x80 then
        t:set_gfx(tile_bottom_left_gentle_slope_large, not bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_whole_bottom_edge and air(0, -1) then
        if (t:abs_x() + t:abs_y())  % 2 == 0 then
            t:set_gfx(tile_bottom_edge_1, false, false)
        else
            t:set_gfx(tile_bottom_edge_2, false, false)
        end
        return true
    end
    if bts == bts_slope_whole_bottom_edge | 0x80 and air(0, 1) then
        if (t:abs_x() + t:abs_y())  % 2 == 0 then
            t:set_gfx(tile_bottom_edge_1, false, true)
        else
            t:set_gfx(tile_bottom_edge_2, false, true)
        end
        return true
    end    
    if (bts == bts_slope_half_bottom_edge_1 or bts == bts_slope_half_bottom_edge_2) and solid(0, 1) then
        if (t:abs_x() + t:abs_y())  % 2 == 0 then
            t:set_gfx(tile_half_bottom_edge_1, false, false)
        else
            t:set_gfx(tile_half_bottom_edge_2, false, false)
        end
        return true
    end
    if (bts == bts_slope_half_bottom_edge_1 | 0x80 or bts == bts_slope_half_bottom_edge_2 | 0x80) and solid(0, -1) then
        if (t:abs_x() + t:abs_y())  % 2 == 0 then
            t:set_gfx(tile_half_bottom_edge_1, false, true)
        else
            t:set_gfx(tile_half_bottom_edge_2, false, true)
        end
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
        t:set_gfx(tile_bottom_left_outside_corner, true, true)
        return true
    end
    if outside_left(1, 0) and inside_right(-1, 0) and outside_top(0, 1) and inside_bottom(0, -1) then
        t:set_gfx(tile_bottom_left_outside_corner, false, true)
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
        if (t:abs_x() + t:abs_y())  % 2 == 0 then
            t:set_gfx(tile_bottom_edge_1, false, false)
        else
            t:set_gfx(tile_bottom_edge_2, false, false)
        end
        return true
    end
    if inside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) then
        if (t:abs_x() + t:abs_y())  % 2 == 0 then
            t:set_gfx(tile_bottom_edge_1, false, true)
        else
            t:set_gfx(tile_bottom_edge_2, false, true)
        end
        return true
    end
    
    -- under horizontal edges:
    if inside_right(-1, 0) and inside_left(1, 0) and outside_bottom(0, -2) and solid(0, -1) then
        if (t:abs_x() + t:abs_y())  % 2 == 0 then
            t:set_gfx(tile_under_bottom_edge_2, false, false)
        else
            t:set_gfx(tile_under_bottom_edge_1, false, false)
        end
        return true
    end    

    -- above horizontal edges:
    if inside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 2) and solid(0, 1) then
        if (t:abs_x() + t:abs_y())  % 2 == 0 then
            t:set_gfx(tile_under_bottom_edge_2, false, true)
        else
            t:set_gfx(tile_under_bottom_edge_1, false, true)
        end
        return true
    end    

    -- Slope adjacent:
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_bottom_right_steep_small and inside_left(1, 0) then
        if not bts_vflip(-1, 0) then
            t:set_gfx(tile_beside_bottom_left_steep_slope_small, true, false)
        else
            t:set_gfx(tile_beside_bottom_left_steep_slope_small, true, true)
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
    if t:type(0, -2) == 1 and t:bts(0, -2) & 0xBF == bts_slope_bottom_right_gentle_small and solid(0, -1) then
        t:set_gfx(tile_under_under_bottom_right_gentle_slope_small, bts_hflip(0, -2), false)
        return true
    end
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_bottom_right_gentle_large and inside_top(0, 1) then
        t:set_gfx(tile_under_bottom_right_gentle_slope_large, bts_hflip(0, -1), false)
        return true
    end


    if t:type(0, -1) == 1 and (t:bts(0, -1) & 0xBF == bts_slope_half_bottom_edge_1 or t:bts(0, -1) & 0xBF == bts_slope_half_bottom_edge_2) and inside_top(0, 1) then
        if (t:abs_x() + t:abs_y())  % 2 == 0 then
            t:set_gfx(tile_under_half_bottom_edge_1, false, false)
        else
            t:set_gfx(tile_under_half_bottom_edge_2, false, false)
        end
        return true
    end
    if t:type(0, 1) == 1 and (t:bts(0, 1) & 0xBF == bts_slope_half_bottom_edge_1 | 0x80 or t:bts(0, 1) & 0xBF == bts_slope_half_bottom_edge_2 | 0x80) and inside_bottom(0, -1) then
        if (t:abs_x() + t:abs_y())  % 2 == 0 then
            t:set_gfx(tile_under_half_bottom_edge_2, false, true)
        else
            t:set_gfx(tile_under_half_bottom_edge_1, false, true)
        end
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
        -- Inside corners:
        if outside_bottom_right(-1, -1) and not air(1, -1) and not air(-1, 1) and not air(1, 1) then
            if (t:abs_x() + t:abs_y()) % 2 == 0 then
                t:set_gfx(tile_top_right_inside_corner_1, false, true)
            else
                t:set_gfx(tile_top_right_inside_corner_2, false, true)
            end
            return true
        end
        if not air(-1, -1) and outside_bottom_left(1, -1) and not air(-1, 1) and not air(1, 1) then
            if (t:abs_x() + t:abs_y()) % 2 == 0 then
                t:set_gfx(tile_top_right_inside_corner_1, true, true)
            else
                t:set_gfx(tile_top_right_inside_corner_2, true, true)
            end
            return true
        end
        if not air(-1, -1) and not air(1, -1) and outside_top_right(-1, 1) and not air(1, 1) then
            if (t:abs_x() + t:abs_y()) % 2 == 0 then
                t:set_gfx(tile_top_right_inside_corner_1, false, true)
            else
                t:set_gfx(tile_top_right_inside_corner_2, false, true)
            end
            return true
        end
        if not air(-1, -1) and not air(1, -1) and not air(-1, 1) and outside_top_left(1, 1) then
            if (t:abs_x() + t:abs_y()) % 2 == 0 then
                t:set_gfx(tile_top_right_inside_corner_1, true, true)
            else
                t:set_gfx(tile_top_right_inside_corner_2, true, true)
            end
            return true
        end
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