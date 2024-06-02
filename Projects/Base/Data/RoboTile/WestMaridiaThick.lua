require("Common")

tile_air = 0x0FF
tile_unknown = 0x0DF
tile_unknown_solid = 0x05F
tile_interior = 0x11D
tile_bottom_edge_1 = 0x180
tile_bottom_edge_2 = 0x1A0
tile_bottom_edge_3 = 0x183
tile_bottom_edge_4 = 0x199

tile_right_edge_1 = 0x186
tile_right_edge_2 = 0x18D
tile_right_edge_3 = 0x1A9
tile_right_edge_4 = 0x19A
tile_bottom_right_outside_corner = 0x18C
tile_bottom_right_inside_corner = 0x188

tile_half_bottom_edge_1 = 0x181
tile_half_bottom_edge_2 = 0x1A1
tile_half_bottom_edge_3 = 0x184
tile_under_half_bottom_edge_1 = 0x182
tile_under_half_bottom_edge_2 = 0x1A2
tile_under_half_bottom_edge_3 = 0x185

tile_half_right_edge_1 = 0x187
tile_half_right_edge_2 = 0x18E
tile_half_right_edge_3 = 0x1AA
tile_beside_half_right_edge_1 = 0x1A8
tile_beside_half_right_edge_2 = 0x18F
tile_beside_half_right_edge_3 = 0x1AB

tile_bottom_right_45_slope = 0x1A7
tile_above_top_right_45_slope = 0x195

tile_top_right_45_small_slope = tile_unknown
tile_top_right_45_large_slope_hflip = tile_unknown

tile_bottom_right_gentle_slope_large = 0x1A5
tile_below_bottom_right_gentle_slope_large = 0x1A6

tile_bottom_right_gentle_slope_small = 0x1A3
tile_below_bottom_right_gentle_slope_small = 0x1A4

tile_top_right_steep_slope_small = 0x192
tile_beside_top_right_steep_slope_small = 0x193

tile_top_right_steep_slope_large = 0x190
tile_beside_top_right_steep_slope_large = 0x191

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
        t:set_gfx(tile_top_right_45_small_slope, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_45_large | 0x80 then
        t:set_gfx(tile_top_right_45_large_slope_hflip, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_steep_small then
        t:set_gfx(tile_top_right_steep_slope_small, bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_bottom_right_steep_small | 0x80 then
        t:set_gfx(tile_top_right_steep_slope_small, bts_hflip(0, 0), false)
        return true
    end
    if bts == bts_slope_bottom_right_steep_large then
        t:set_gfx(tile_top_right_steep_slope_large, bts_hflip(0, 0), true)
        return true
    end
    if bts == bts_slope_bottom_right_steep_large | 0x80 then
        t:set_gfx(tile_top_right_steep_slope_large, bts_hflip(0, 0), false)
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
        if (t:abs_x() + t:abs_y()) % 2 == 0 then
            t:set_gfx(tile_bottom_edge_1, false, false)
        else
            if (t:abs_x() + t:abs_y()) % 4 < 2 then
                t:set_gfx(tile_bottom_edge_3, false, false)
            else
                if (t:abs_x() + t:abs_y()) % 8 < 4 then
                    t:set_gfx(tile_bottom_edge_2, false, false)
                else
                    t:set_gfx(tile_bottom_edge_4, false, false)
                end
            end
        end
        return true
    end
    if bts == bts_slope_whole_bottom_edge | 0x80 and air(0, 1) then
        if (t:abs_x() + t:abs_y()) % 2 == 0 then
            t:set_gfx(tile_bottom_edge_1, false, true)
        else
            if (t:abs_x() + t:abs_y()) % 4 < 2 then
                t:set_gfx(tile_bottom_edge_3, false, true)
            else
                if (t:abs_x() + t:abs_y()) % 8 < 4 then
                    t:set_gfx(tile_bottom_edge_2, false, true)
                else
                    t:set_gfx(tile_bottom_edge_4, false, true)
                end
            end
        end
        return true
    end    
    if (bts == bts_slope_half_bottom_edge_1 or bts == bts_slope_half_bottom_edge_2) and solid(0, 1) then
        if t:abs_x() % 2 == 0 then
            t:set_gfx(tile_half_bottom_edge_1, false, false)
        else
            if t:abs_x() % 4 < 2 then
                t:set_gfx(tile_half_bottom_edge_2, false, false)
            else
                t:set_gfx(tile_half_bottom_edge_3, false, false)
            end
        end
        return true
    end
    if (bts == bts_slope_half_bottom_edge_1 | 0x80 or bts == bts_slope_half_bottom_edge_2 | 0x80) and solid(0, -1) then
        if t:abs_x() % 2 == 0 then
            t:set_gfx(tile_half_bottom_edge_1, false, true)
        else
            if t:abs_x() % 4 < 2 then
                t:set_gfx(tile_half_bottom_edge_2, false, true)
            else
                t:set_gfx(tile_half_bottom_edge_3, false, true)
            end
        end
        return true
    end
    if bts & 0x3F == bts_slope_half_right_edge then
        if t:abs_y() % 2 == 0 then
            t:set_gfx(tile_half_right_edge_1, bts_hflip(0, 0), false)
        else
            if t:abs_y() % 4 < 2 then
                t:set_gfx(tile_half_right_edge_2, bts_hflip(0, 0), false)
            else
                t:set_gfx(tile_half_right_edge_3, bts_hflip(0, 0), false)
            end
        end
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
        if (t:abs_x() + t:abs_y()) % 2 == 0 then
            t:set_gfx(tile_right_edge_1, false, false)
        else
            if (t:abs_x() + t:abs_y()) % 4 < 2 then
                t:set_gfx(tile_right_edge_3, false, false)
            else
                if (t:abs_x() + t:abs_y()) % 8 < 5 then
                    t:set_gfx(tile_right_edge_2, false, false)
                else
                    t:set_gfx(tile_right_edge_4, false, false)
                end
            end
        end
        return true
    end
    if outside_left(1, 0) and inside_right(-1, 0) and inside_bottom(0, -1) and inside_top(0, 1) then
        if (t:abs_x() + t:abs_y()) % 2 == 0 then
            t:set_gfx(tile_right_edge_1, true, false)
        else
            if (t:abs_x() + t:abs_y()) % 4 < 2 then
                t:set_gfx(tile_right_edge_3, true, false)
            else
                if (t:abs_x() + t:abs_y()) % 8 < 4 then
                    t:set_gfx(tile_right_edge_2, true, false)
                else
                    t:set_gfx(tile_right_edge_4, true, false)
                end
            end
        end
        return true
    end
    if inside_right(-1, 0) and inside_left(1, 0) and outside_bottom(0, -1) and inside_top(0, 1) then
        if (t:abs_x() + t:abs_y()) % 2 == 0 then
            t:set_gfx(tile_bottom_edge_1, false, false)
        else
            if (t:abs_x() + t:abs_y()) % 4 < 2 then
                t:set_gfx(tile_bottom_edge_3, false, false)
            else
                if (t:abs_x() + t:abs_y()) % 8 < 4 then
                    t:set_gfx(tile_bottom_edge_2, false, false)
                else
                    t:set_gfx(tile_bottom_edge_4, false, false)
                end
            end
        end
        return true
    end
    if inside_right(-1, 0) and inside_left(1, 0) and outside_top(0, 1) then
        if (t:abs_x() + t:abs_y()) % 2 == 0 then
            t:set_gfx(tile_bottom_edge_1, false, true)
        else
            if (t:abs_x() + t:abs_y()) % 4 < 2 then
                t:set_gfx(tile_bottom_edge_3, false, true)
            else
                if (t:abs_x() + t:abs_y()) % 8 < 4 then
                    t:set_gfx(tile_bottom_edge_2, false, true)
                else
                    t:set_gfx(tile_bottom_edge_4, false, true)
                end
            end
        end
        return true
    end

    -- Slope adjacent:
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_bottom_right_steep_small and inside_left(1, 0) then
        t:set_gfx(tile_beside_top_right_steep_slope_small, false, not bts_vflip(-1, 0))
        return true
    end
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_bottom_right_steep_large and inside_left(1, 0) then
        t:set_gfx(tile_beside_top_right_steep_slope_large, false, not bts_vflip(-1, 0))
        return true
    end
    if t:type(1, 0) == 1 and t:bts(1, 0) & 0x7F == bts_slope_bottom_right_steep_small | 0x40 and inside_right(-1, 0) then
        t:set_gfx(tile_beside_top_right_steep_slope_small, true, not bts_vflip(1, 0))
        return true
    end
    if t:type(1, 0) == 1 and t:bts(1, 0) & 0x7F == bts_slope_bottom_right_steep_large | 0x40 and inside_right(-1, 0) then
        t:set_gfx(tile_beside_top_right_steep_slope_large, true, not bts_vflip(1, 0))
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
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_bottom_right_gentle_large and inside_top(0, 1) then
        t:set_gfx(tile_below_bottom_right_gentle_slope_large, bts_hflip(0, -1), false)
        return true
    end
    if t:type(0, 1) == 1 and t:bts(0, 1) & 0xBF == bts_slope_bottom_right_gentle_large | 0x80 and inside_bottom(0, -1) then
        t:set_gfx(tile_below_bottom_right_gentle_slope_large, bts_hflip(0, 1), true)
        return true
    end

    if t:type(0, -1) == 1 and (t:bts(0, -1) & 0xBF == bts_slope_half_bottom_edge_1 or t:bts(0, -1) & 0xBF == bts_slope_half_bottom_edge_2) and inside_top(0, 1) then
        if t:abs_x() % 2 == 0 then
            t:set_gfx(tile_under_half_bottom_edge_1, false, false)
        else
            if t:abs_x() % 4 < 2 then
                t:set_gfx(tile_under_half_bottom_edge_2, false, false)
            else
                t:set_gfx(tile_under_half_bottom_edge_3, false, false)
            end
        end
        return true
    end
    if t:type(0, 1) == 1 and (t:bts(0, 1) & 0xBF == bts_slope_half_bottom_edge_1 | 0x80 or t:bts(0, 1) & 0xBF == bts_slope_half_bottom_edge_2 | 0x80) and inside_bottom(0, -1) then
        if t:abs_x() % 2 == 0 then
            t:set_gfx(tile_under_half_bottom_edge_1, false, true)
        else
            if t:abs_x() % 4 < 2 then
                t:set_gfx(tile_under_half_bottom_edge_2, false, true)
            else
                t:set_gfx(tile_under_half_bottom_edge_3, false, true)
            end
        end
        return true
    end
    if t:type(-1, 0) == 1 and (t:bts(-1, 0) & 0x7F == bts_slope_half_right_edge) then
        if t:abs_y() % 2 == 0 then
            t:set_gfx(tile_beside_half_right_edge_1, false, false)
        else
            if t:abs_y() % 4 < 2 then
                t:set_gfx(tile_beside_half_right_edge_2, false, false)
            else
                t:set_gfx(tile_beside_half_right_edge_3, false, false)
            end
        end
        return true
    end
    if t:type(1, 0) == 1 and (t:bts(1, 0) & 0x7F == bts_slope_half_right_edge | 0x40) then
        if t:abs_y() % 2 == 0 then
            t:set_gfx(tile_beside_half_right_edge_1, true, false)
        else
            if t:abs_y() % 4 < 2 then
                t:set_gfx(tile_beside_half_right_edge_2, true, false)
            else
                t:set_gfx(tile_beside_half_right_edge_3, true, false)
            end
        end
        return true
    end
    if t:type(0, -1) == 1 and (t:bts(0, -1) & 0xBF == bts_slope_bottom_right_45) then
        t:set_gfx(tile_above_top_right_45_slope, bts_hflip(0, -1), true)
        return true
    end
    if t:type(0, 1) == 1 and (t:bts(0, 1) & 0xBF == bts_slope_bottom_right_45 | 0x80) then
       t:set_gfx(tile_above_top_right_45_slope, bts_hflip(0, 1), false)
       return true
    end

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
