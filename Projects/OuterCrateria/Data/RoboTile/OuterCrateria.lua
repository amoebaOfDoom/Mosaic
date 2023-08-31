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
bts_slope_step_small = 0x02
bts_slope_step_large = 0x03

tile_number_air = 0x0FF
tile_number_interior = 0x3FF
tile_number_unknown = 0x0FE
tile_number_outside_corner = 0x10D
tile_number_horizontal_edge = 0x10F
tile_number_vertical_edge = 0x110
tile_number_outside_corner_opaque = 0x116
tile_number_horizontal_edge_opaque = 0x118
tile_number_vertical_edge_opaque = 0x119
tile_number_inside_corner = 0x114
tile_number_solid_block = 0x2B8

tile_number_slope_half_floor = 0x1DC
tile_number_under_slope_half_floor = 0x1FC
tile_number_slope_half_wall = 0x21A
tile_number_beside_slope_half_wall = 0x21B
tile_number_slope_normal = 0x10E
tile_number_slope_steep_small = 0x1D8
tile_number_slope_steep_large = 0x1F8
tile_number_beside_slope_steep_small = 0x1D9
tile_number_beside_slope_steep_large = 0x1F9
tile_number_slope_gentle_small = 0x1D5
tile_number_slope_gentle_large = 0x1D6
tile_number_under_slope_gentle_small = 0x1F5
tile_number_under_slope_gentle_large = 0x1F6
tile_number_slope_step_small = 0x14E
tile_number_slope_step_large = 0x16F

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
function foreign(x, y)
    -- Tiles to treat as not belonging to the walls being formed, not including air.
    -- Walls next to these will use opaque (black) edges rather than transparent.
    return not air(x, y) and invariant(x, y)
end
function foreign_air(x, y)
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
    if bts == bts_slope_steep_small then
        t:set_gfx(tile_number_slope_steep_small, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end
    if bts == bts_slope_steep_large then
        t:set_gfx(tile_number_slope_steep_large, bts_hflip(0, 0), bts_vflip(0, 0))
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
    if (t:bts(0, 0) == bts_slope_half_floor & 0xBF or t:bts(0, 0) & 0xBF == bts_slope_half_platform) and solid(0, 1) then
        t:set_gfx(tile_number_slope_half_floor, false, false)
        return true
    end
    if (t:bts(0, 0) == bts_slope_half_floor & 0xBF | 0x80 or t:bts(0, 0) & 0xBF == bts_slope_half_platform | 0x80) and solid(0, -1) then
        t:set_gfx(tile_number_slope_half_floor, false, true)
        return true
    end
    if t:bts(0, 0) & 0x3F == bts_slope_half_wall then
        t:set_gfx(tile_number_slope_half_wall, bts_hflip(0, 0), false)
        return true
    end    
    if t:bts(0, 0) & 0x3F == bts_slope_step_small then
        t:set_gfx(tile_number_slope_step_small, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end    
    if t:bts(0, 0) & 0x3F == bts_slope_step_large then
        t:set_gfx(tile_number_slope_step_large, bts_hflip(0, 0), bts_vflip(0, 0))
        return true
    end    
end

-- Solid tiles: look at neighboring edges
if solid(0, 0) then
    -- Outside corners (opaque):
    if foreign(-1, 0) and solid_left(1, 0) and foreign(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_outside_corner_opaque, false, false)
        return true
    end
    if foreign(1, 0) and solid_right(-1, 0) and foreign(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_outside_corner_opaque, true, false)
        return true
    end
    if foreign(-1, 0) and solid_left(1, 0) and foreign(0, 1) and solid_bottom(0, -1) then
        t:set_gfx(tile_number_outside_corner_opaque, false, true)
        return true
    end
    if foreign(1, 0) and solid_right(-1, 0) and foreign(0, 1) and solid_bottom(0, -1) then
        t:set_gfx(tile_number_outside_corner_opaque, true, true)
        return true
    end

    -- Outside corners (with transparency):
    if foreign_air(-1, 0) and solid_left(1, 0) and foreign_air(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_outside_corner, false, false)
        return true
    end
    if foreign_air(1, 0) and solid_right(-1, 0) and foreign_air(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_outside_corner, true, false)
        return true
    end
    if foreign_air(-1, 0) and solid_left(1, 0) and foreign_air(0, 1) and solid_bottom(0, -1) then
        t:set_gfx(tile_number_outside_corner, false, true)
        return true
    end
    if foreign_air(1, 0) and solid_right(-1, 0) and foreign_air(0, 1) and solid_bottom(0, -1) then
        t:set_gfx(tile_number_outside_corner, true, true)
        return true
    end

    -- Horizontal/vertical edges (transparent):
    if air(-1, 0) and solid_left(1, 0) and solid_bottom(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_vertical_edge, false, false)
        return true
    end
    if air(1, 0) and solid_right(-1, 0) and solid_bottom(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_vertical_edge, true, false)
        return true
    end
    if solid_right(-1, 0) and solid_left(1, 0) and air(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_horizontal_edge, false, false)
        return true
    end
    if solid_right(-1, 0) and solid_left(1, 0) and air(0, 1) and solid_bottom(0, -1) then
        t:set_gfx(tile_number_horizontal_edge, false, true)
        return true
    end

    -- Horizontal/vertical edges (opaque):
    if foreign(-1, 0) and solid_left(1, 0) and solid_bottom(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_vertical_edge_opaque, false, false)
        return true
    end
    if foreign(1, 0) and solid_right(-1, 0) and solid_bottom(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_vertical_edge_opaque, true, false)
        return true
    end
    if solid_right(-1, 0) and solid_left(1, 0) and foreign(0, -1) and solid_top(0, 1) then
        t:set_gfx(tile_number_horizontal_edge_opaque, false, false)
        return true
    end
    if solid_right(-1, 0) and solid_left(1, 0) and foreign(0, 1) and solid_bottom(0, -1) then
        t:set_gfx(tile_number_horizontal_edge_opaque, false, true)
        return true
    end

    -- Slope adjacent:
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_steep_small and solid_left(1, 0) then
        t:set_gfx(tile_number_beside_slope_steep_small, false, bts_vflip(-1, 0))
        return true
    end
    if t:type(-1, 0) == 1 and t:bts(-1, 0) & 0x7F == bts_slope_steep_large and solid_left(1, 0) then
        t:set_gfx(tile_number_beside_slope_steep_large, false, bts_vflip(-1, 0))
        return true
    end
    if t:type(1, 0) == 1 and t:bts(1, 0) & 0x7F == bts_slope_steep_small | 0x40 and solid_right(-1, 0) then
        t:set_gfx(tile_number_beside_slope_steep_small, true, bts_vflip(1, 0))
        return true
    end
    if t:type(1, 0) == 1 and t:bts(1, 0) & 0x7F == bts_slope_steep_large | 0x40 and solid_right(-1, 0) then
        t:set_gfx(tile_number_beside_slope_steep_large, true, bts_vflip(1, 0))
        return true
    end
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_gentle_small and solid_top(0, 1) then
        t:set_gfx(tile_number_under_slope_gentle_small, bts_hflip(0, -1), false)
        return true
    end
    if t:type(0, -1) == 1 and t:bts(0, -1) & 0xBF == bts_slope_gentle_large and solid_top(0, 1) then
        t:set_gfx(tile_number_under_slope_gentle_large, bts_hflip(0, -1), false)
        return true
    end
    if t:type(0, 1) == 1 and t:bts(0, 1) & 0xBF == bts_slope_gentle_small | 0x80 and solid_bottom(0, -1) then
        t:set_gfx(tile_number_under_slope_gentle_small, bts_hflip(0, 1), true)
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
        if (air(-1, -1) or foreign(-1, -1)) and not air(1, -1) and not air(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_number_inside_corner, false, false)
            return true
        end
        if not air(-1, -1) and (air(1, -1) or foreign(1, -1)) and not air(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_number_inside_corner, true, false)
            return true
        end
        if not air(-1, -1) and not air(1, -1) and (air(-1, 1) or foreign(-1, 1)) and not air(1, 1) then
            t:set_gfx(tile_number_inside_corner, false, true)
            return true
        end
        if not air(-1, -1) and not air(1, -1) and not air(-1, 1) and (air(1, 1) or foreign(1, 1)) then
            t:set_gfx(tile_number_inside_corner, true, true)
            return true
        end

        -- Interior
        if not air(-1, -1) and not air(1, -1) and not air(-1, 1) and not air(1, 1) then
            t:set_gfx(tile_number_interior, false, false)
            return true
        end
    end

    -- Other solid tiles: fall back to metal block (to be easy to spot for manual editing)
    t:set_gfx(tile_number_solid_block, false, false)
    return true
end

-- Other tiles: mark as unknown (X's)
t:set_gfx(tile_number_unknown, false, false) 