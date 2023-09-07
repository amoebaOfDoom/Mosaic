bts_slope_half_bottom_edge_1 = 0x00
bts_slope_half_bottom_edge_2 = 0x07
bts_slope_whole_bottom_edge = 0x13
bts_slope_half_right_edge = 0x01
bts_slope_bottom_right_45 = 0x12
bts_slope_bottom_right_45_small = 0x14
bts_slope_bottom_right_45_large = 0x15
bts_slope_bottom_right_steep_small = 0x1B
bts_slope_bottom_right_steep_large = 0x1C
bts_slope_bottom_right_gentle_small = 0x16
bts_slope_bottom_right_gentle_large = 0x17
bts_slope_bottom_right_step_small = 0x02
bts_slope_bottom_right_step_large = 0x03

tile_number_air = 0x0FF
tile_number_unknown = 0x0FE

function invariant(x, y)
    -- Tiles to leave intact: CRE tiles except for black
    local tile = t:gfx_tile(x, y)
    return tile < 0xFF and tile ~= 0x81 and tile ~= 0x44
end
function air(x, y) 
    return t:type(x, y) == 0
end
function solid(x, y) 
    return t:type(x, y) == 8 or (t:type(x, y) == 1 and t:bts(x, y) & 0x3F == bts_slope_whole_bottom_edge)
end
function outside(x, y)
    -- Tiles to treat as not belonging to the walls being formed, including air.
    -- Walls next to these will use opaque (black) edges rather than transparent.
    return air(x, y) or invariant(x, y)
end
function bts_vflip(x, y)
    return t:bts(x, y) & 0x80 ~= 0
end
function bts_hflip(x, y)
    return t:bts(x, y) & 0x40 ~= 0
end
function solid_slope_left(bts)
    return bts == 0x13
end
function solid_slope_right(bts)
    return bts == 0x13 or bts == 0x12 or bts == 0x15 or bts == 0x1B or bts == 0x1C or bts == 0x17
end
function solid_slope_top(bts)
    return bts == 0x13
end
function solid_slope_bottom(bts)
    return bts == 0x00 or bts == 0x07 or bts == 0x13 or bts == 0x12 or bts == 0x15 or bts == 0x16 or bts == 0x17 or bts == 0x1C
end
function inside_left(x, y)
    if invariant(x, y) then
        return false
    end
    if t:type(x, y) == 8 then
        return true
    end
    if t:type(x, y) == 1 then
        if t:bts(x, y) & 0x40 == 0 then
            return solid_slope_left(t:bts(x, y) & 0x3F)
        else
            return solid_slope_right(t:bts(x, y) & 0x3F)        
        end
    end
    return false
end
function inside_right(x, y)
    if invariant(x, y) then
        return false
    end
    if t:type(x, y) == 8 then
        return true
    end
    if t:type(x, y) == 1 then
        if t:bts(x, y) & 0x40 == 0 then
            return solid_slope_right(t:bts(x, y) & 0x3F)
        else
            return solid_slope_left(t:bts(x, y) & 0x3F)        
        end
    end
    return false
end
function inside_top(x, y)
    if invariant(x, y) then
        return false
    end
    if t:type(x, y) == 8 then
        return true
    end
    if t:type(x, y) == 1 then
        if t:bts(x, y) & 0x80 == 0 then
            return solid_slope_top(t:bts(x, y) & 0x3F)
        else
            return solid_slope_bottom(t:bts(x, y) & 0x3F)        
        end
    end
    return false
end
function inside_bottom(x, y)
    if invariant(x, y) then
        return false
    end
    if t:type(x, y) == 8 then
        return true
    end
    if t:type(x, y) == 1 then
        if t:bts(x, y) & 0x80 == 0 then
            return solid_slope_bottom(t:bts(x, y) & 0x3F)
        else
            return solid_slope_top(t:bts(x, y) & 0x3F)        
        end
    end
    return false
end
function outside_left(x, y)
    return not inside_left(x,y)
end
function outside_right(x, y)
    return not inside_right(x,y)
end
function outside_top(x, y)
    return not inside_top(x,y)
end
function outside_bottom(x, y)
    return not inside_bottom(x,y)
end
function outside_bottom_left(x, y)
    return outside_bottom(x, y) or outside_left(x, y)
end
function outside_bottom_right(x, y)
    return outside_bottom(x, y) or outside_right(x, y)
end
function outside_top_left(x, y)
    return outside_top(x, y) or outside_left(x, y)
end
function outside_top_right(x, y)
    return outside_top(x, y) or outside_right(x, y)
end
