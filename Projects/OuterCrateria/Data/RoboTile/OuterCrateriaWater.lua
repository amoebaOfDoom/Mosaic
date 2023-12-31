bts_slope_half_platform = 0x00
bts_slope_half_floor = 0x07
bts_slope_whole_floor = 0x13
bts_slope_half_wall = 0x01
bts_slope_normal = 0x12        -- 45-degree angle slope
bts_slope_offset_small = 0x14  -- 45-degree angle slope, offset by half tile
bts_slope_offset_large = 0x15  -- 45-degree angle slope, offset by half tile
bts_slope_steep_small = 0x1B
bts_slope_steep_large = 0x1C
bts_slope_gentle_small = 0x16
bts_slope_gentle_large = 0x17

tile_number_air = 0x0FF
tile_number_interior = 0x113
tile_number_deep_interior = 0x3FF
tile_number_unknown = 0x0FE
tile_number_outside_corner = 0x305
tile_number_horizontal_edge = 0x2A5
tile_number_vertical_edge = 0x2A2
tile_number_inside_corner = 0x2E5
tile_number_solid_block = 0x2B8

tile_number_slope_half_floor = 0x1CD
tile_number_under_slope_half_floor = 0x1ED
tile_number_slope_half_wall = 0x20B
tile_number_beside_slope_half_wall = 0x20C
tile_number_slope_normal = 0x2C5
tile_number_under_slope_normal = 0x2E5
tile_number_slope_offset_small = 0x22E
tile_number_slope_offset_large = 0x24E
tile_number_slope_steep_small = 0x1D0
tile_number_slope_steep_large = 0x1F0
tile_number_beside_slope_steep_small = 0x1CF
tile_number_beside_slope_steep_large = 0x1EF
tile_number_slope_gentle_small = 0x1D2
tile_number_slope_gentle_large = 0x1D3
tile_number_under_slope_gentle_small = 0x1F2
tile_number_under_slope_gentle_large = 0x1F3

function invariant(x, y)
    -- Tiles to leave intact: CRE tiles except for black
    local tile = t:gfx_tile(x, y)
    return tile < 0x100 and tile ~= 0x81
end
function air(x, y) 
    return t:type(x, y) == 0
end
function solid(x, y) 
    return t:type(x, y) == 8 or (t:type(x, y) == 1 and t:bts(x, y) & 0x3F == bts_slope_whole_floor)
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
function solid_left(x, y)
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
function solid_right(x, y)
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
function solid_top(x, y)
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
function solid_bottom(x, y)
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
function outside(x, y)
    -- Tiles to treat as not belonging to the walls being formed, including air.
    return air(x, y) or invariant(x, y)
end
function bts_vflip(x, y)
    return t:bts(x, y) & 0x80 ~= 0
end
function bts_hflip(x, y)
    return t:bts(x, y) & 0x40 ~= 0
end

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
    if bts == bts_slope_normal then
        t:set_gfx(tile_number_slope_normal, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_offset_small then
        t:set_gfx(tile_number_slope_offset_small, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_offset_large then
        t:set_gfx(tile_number_slope_offset_large, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_steep_small then
        t:set_gfx(tile_number_slope_steep_small, not bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_steep_large then
        t:set_gfx(tile_number_slope_steep_large, not bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_gentle_small then
        t:set_gfx(tile_number_slope_gentle_small, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_gentle_large then
        t:set_gfx(tile_number_slope_gentle_large, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if t:bts(0, 0) == bts_slope_whole_floor and air(0, -1) then
        t:set_gfx(tile_number_horizontal_edge, false, false)
        return true
    end
    if t:bts(0, 0) == bts_slope_whole_floor | 0x80 and air(0, 1) then
        t:set_gfx(tile_number_horizontal_edge, false, true)
        return true
    end    
    if (t:bts(0, 0) & 0xBF == bts_slope_half_floor or t:bts(0, 0) & 0xBF == bts_slope_half_platform) and solid(0, 1) then
        t:set_gfx(tile_number_slope_half_floor, false, false)
        return true
    end
    if (t:bts(0, 0) & 0xBF == bts_slope_half_floor | 0x80 or t:bts(0, 0) & 0xBF == bts_slope_half_platform | 0x80) and solid(0, -1) then
        t:set_gfx(tile_number_slope_half_floor, false, true)
        return true
    end
    if t:bts(0, 0) & 0x3F == bts_slope_half_wall then
        t:set_gfx(tile_number_slope_half_wall, bts_hflip(0, 0), false)
        return true
    end
end

-- Solid tiles: look at neighboring edges
if solid(0, 0) then
    -- Outside corners:
    if outside(-1, 0) and solid_left(1, 0) and outside(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_outside_corner, false, false)
        return true
    end
    if outside(1, 0) and solid_right(-1, 0) and outside(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_outside_corner, true, false)
        return true
    end
    if outside(-1, 0) and solid_left(1, 0) and outside(0, 1) and solid_bottom(0, -1) then
        t:set_gfx(tile_number_outside_corner, false, true)
        return true
    end
    if outside(1, 0) and solid_right(-1, 0) and outside(0, 1) and solid_bottom(0, -1) then
        t:set_gfx(tile_number_outside_corner, true, true)
        return true
    end

    -- Horizontal/vertical edges:
    if outside(-1, 0) and solid_left(1, 0) and solid_bottom(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_vertical_edge, false, false)
        return true
    end
    if outside(1, 0) and solid_right(-1, 0) and solid_bottom(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_vertical_edge, true, false)
        return true
    end
    if solid_right(-1, 0) and solid_left(1, 0) and outside(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_horizontal_edge, false, false)
        return true
    end
    if solid_right(-1, 0) and solid_left(1, 0) and outside(0, 1) and solid_bottom(0, -1) then
        t:set_gfx(tile_number_horizontal_edge, false, true)
        return true
    end

    -- Slope adjacent:
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_steep_small and solid_left(1, 0) then
        t:set_gfx(tile_number_beside_slope_steep_small, true, bts_vflip(-1, 0))
        return true
    end
    if t:type(1, 0) == 1 and t:bts(1, 0) & 0x7F == bts_slope_steep_small | 0x40 and solid_right(-1, 0) then
        t:set_gfx(tile_number_beside_slope_steep_small, false, bts_vflip(1, 0))
        return true
    end
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_steep_large and solid_left(1, 0) then
        t:set_gfx(tile_number_beside_slope_steep_large, true, bts_vflip(-1, 0))
        return true
    end
    if t:type(1, 0) == 1 and t:bts(1, 0) & 0x7F == bts_slope_steep_large | 0x40 and solid_right(-1, 0) then
        t:set_gfx(tile_number_beside_slope_steep_large, false, bts_vflip(1, 0))
        return true
    end
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_gentle_small and solid_top(0, 1) then
        t:set_gfx(tile_number_under_slope_gentle_small, bts_hflip(0, -1), false)
        return true
    end
    if t:type(0, 1) == 1 and t:bts(0, 1) & 0xBF == bts_slope_gentle_small | 0x80 and solid_bottom(0, -1) then
        t:set_gfx(tile_number_under_slope_gentle_small, bts_hflip(0, 1), true)
        return true
    end
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_gentle_large and solid_top(0, 1) then
        t:set_gfx(tile_number_under_slope_gentle_large, bts_hflip(0, -1), false)
        return true
    end
    if t:type(0, 1) == 1 and t:bts(0, 1) & 0xBF == bts_slope_gentle_large | 0x80 and solid_bottom(0, -1) then
        t:set_gfx(tile_number_under_slope_gentle_large, bts_hflip(0, 1), true)
        return true
    end
    if t:type(0, -1) == 1 and (t:bts(0, -1) & 0xBF == bts_slope_half_floor or t:bts(0, -1) & 0xBF == bts_slope_half_platform) and solid_top(0, 1) then
        t:set_gfx(tile_number_under_slope_half_floor, bts_hflip(0, 1), false)
        return true
    end
    if t:type(0, 1) == 1 and (t:bts(0, 1) & 0xBF == bts_slope_half_floor | 0x80 or t:bts(0, 1) & 0xBF == bts_slope_half_platform | 0x80) and solid_bottom(0, -1) then
        t:set_gfx(tile_number_under_slope_half_floor, bts_hflip(0, 1), true)
        return true
    end
    if t:type(-1, 0) == 1 and (t:bts(-1, 0) & 0x7F == bts_slope_half_wall) then
        t:set_gfx(tile_number_beside_slope_half_wall, false, false)
        return true
    end
    if t:type(1, 0) == 1 and (t:bts(1, 0) & 0x7F == bts_slope_half_wall | 0x40) then
        t:set_gfx(tile_number_beside_slope_half_wall, true, false)
        return true
    end

    if solid_right(-1, 0) and solid_left(1, 0) and solid_bottom(0, -1) and solid_top(0, 1) then
        -- Inside corners:
        if outside(-1, -1) and not air(1, -1) and not air(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_number_inside_corner, false, false)
            return true
        end
        if not air(-1, -1) and outside(1, -1) and not air(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_number_inside_corner, true, false)
            return true
        end
        if not air(-1, -1) and not air(1, -1) and outside(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_number_inside_corner, false, true)
            return true
        end
        if not air(-1, -1) and not air(1, -1) and not air(-1, 1) and outside(1, 1) then
            t:set_gfx(tile_number_inside_corner, true, true)
            return true
        end

        -- Interior
        if not air(-1, -1) and not air(1, -1) and not air(-1, 1) and not air(1, 1) then
            if (outside(-2, -1) or outside(-2, 0) or outside(-2, 1) or
                   outside(2, -1) or outside(2, 0) or outside(2, 1) or 
                   outside(-1, -2) or outside(0, -2) or outside(1, -2) or 
                   outside(-1, 2) or outside(0, 2) or outside(1, 2)) then
                t:set_gfx(tile_number_interior, false, false)
                return true
            end
            t:set_gfx(tile_number_deep_interior, false, false)
            return true
        end
    end
end

-- Other tiles: mark as unknown (X's)
t:set_gfx(tile_number_unknown, false, false) 