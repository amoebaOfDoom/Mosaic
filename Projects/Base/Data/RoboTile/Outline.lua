require("edges")

local type = t:type(0,0)
local bts = t:bts(0,0)
local gfx = t:gfx_tile(0,0)

if (gfx <= 0x43) or (gfx >= 0x60 and gfx <= 0x63) or gfx == 0x82 or gfx == 0x83 or gfx == 0xA2 then
  return true
end

if gfx == 0x3D7 then
  return true
end

if (gfx >= 0x3B8 and gfx <= 0x3BF) or (gfx >= 0x3D8 and gfx <= 0x3DF)  then
  return true
end

if type == 0x9 then
  t:set_gfx(0x2A3, false, false)
  return
elseif type == 0x3 then
  if (bts == 0x08 or bts == 0x09) then
    t:set_gfx(0x0FF, false, false)
  elseif bts == 0x85 then
    t:set_gfx(0x3F5, false, false)
  end
  return true
elseif type == 0xA then
  if bts == 0x0E then
    t:set_gfx(0x2A0, false, false)
  elseif bts == 0x0F then
    t:set_gfx(0x2A1, false, false)
  elseif bts > 0x00 then
    t:set_gfx(0x2A2, false, not solid(t,0,-1))
  elseif (t:type(-1,0) == 0xA or t:type(1,0) == 0xA) then
    t:set_gfx(0x056, false, not solid(t,0,1))
  elseif (t:type(0,-1) == 0xA or t:type(0,1) == 0xA) then
    t:set_gfx(0x09C, not solid(t,1,0), false)
  else
    t:set_gfx(0x056, false, not solid(t,0,1))
  end
  return true
elseif type == 0x2 then
  if bts == 02 then
    t:set_gfx(0x2A2, false, not solid(t,0,-1))
  end
  return
elseif type == 0x0B then
  if(bts == 0x0E or bts == 0x0F or bts == 0x84) then
    t:set_gfx(0x0B6, false, false)
  elseif(bts == 0x0B) then
    t:set_gfx(0x2A1, false, false)
  else
    t:set_gfx(0x0BC, false, false)
  end
  return true
elseif type == 0x0C then
  if bts == 0x00 or bts == 0x04 then
    t:set_gfx(0x052, false, false)
  elseif bts == 0x01 or bts == 0x05 then
      t:set_gfx(0x052, false, false)
  elseif bts == 0x02 or bts == 0x06 then
      t:set_gfx(0x052, false, false)
  elseif bts == 0x03 or bts == 0x07 then
      t:set_gfx(0x052, false, false)
  elseif bts == 0x08 or bts == 0x09 then
      t:set_gfx(0x057, false, false)
  elseif bts == 0x0A or bts == 0x0B then
      t:set_gfx(0x09F, false, false)
  else
    t:set_gfx(0x2FF, false, false)
  end
  return true
elseif type == 0x0E then
  if bts == 0x00 then
    t:set_gfx(0x09B, false, false)
  else
    t:set_gfx(0x0B7, false, false)
  end
  return true
elseif type == 0x0F then
  t:set_gfx(0x058, false, false)
  return true
end

function flip_offset(flip)
  return flip and -1 or 1
end

function inner_corner_tile(t, xflip, yflip)
  local th = t:type(-1, 0)
  local bh = t:bts(-1, 0) & 0x1F

  local tv = t:type(0, -1)
  local bv = t:bts(0, -1) & 0x1F

  if (xflip) then
    th = t:type(1, 0)
    bh = t:bts(1, 0) & 0x1F
  end

  if (yflip) then
    tv = t:type(0, 1)
    bv = t:bts(0, 1) & 0x1F
  end

  t:print(bv)
  t:print(bv)

  if ((tv == 1 and bv == 0x12) and (th == 1 and bh == 0x12)) or 
     ((tv == 1 and bv == 0x12) and solid(t, flip_offset(xflip), 0)) or 
     (solid(t, 0, flip_offset(yflip)) and (th == 1 and bh == 0x12)) then
    t:set_gfx(0x22D, xflip, yflip)
  elseif ((tv == 1 and bv == 0x16) and (th == 1 and bh == 0x1B)) or 
         ((tv == 1 and bv == 0x1C) and (th == 1 and bh == 0x17)) then
    t:set_gfx(0x22D, xflip, yflip)
  elseif ((tv == 1 and bv == 0x16) and (th == 1 and bh == 0x17)) or 
         ((tv == 1 and bv == 0x16) and solid(t, flip_offset(xflip), 0)) then
    t:set_gfx(0x266, xflip, yflip)
  elseif ((tv == 1 and bv == 0x1C) and (th == 1 and bh == 0x1B)) or 
         (solid(t, 0, flip_offset(yflip)) and (th == 1 and bh == 0x1B)) then
    t:set_gfx(0x249, xflip, yflip)
  else
    t:set_gfx(0x205, xflip, yflip)
  end
end

if edge_up(t) then
  if air_adj_downleft(t,0,0) then
    if air_adj_downright(t,0,0) then
      t:set_gfx(0x20A, false, false)
    else
      t:set_gfx(0x209, true, false)
    end
  else
    if air_adj_downright(t,0,0) then
      t:set_gfx(0x209, false, false)
    else
      t:set_gfx(0x201, false, false)
    end
  end
elseif edge_down(t) then
  if air_adj_upleft(t,0,0) then
    if air_adj_upright(t,0,0) then
      t:set_gfx(0x20A, false, true)
    else
      t:set_gfx(0x209, true, true)
    end
  else
    if air_adj_upright(t,0,0) then
      t:set_gfx(0x209, false, true)
    else
      t:set_gfx(0x201, false, true)
    end
  end
elseif edge_right(t) then
  if air_adj_downleft(t,0,0) then
    if air_adj_upleft(t,0,0) then
      t:set_gfx(0x22A, true, false)
    else
      t:set_gfx(0x228, true, false)
    end
  else
    if air_adj_upleft(t,0,0) then
      t:set_gfx(0x228, true, true)
    else
      t:set_gfx(0x220, true, false)
    end
  end
elseif edge_left(t) then
  if air_adj_downright(t,0,0) then
    if air_adj_upright(t,0,0) then
      t:set_gfx(0x22A, false, false)
    else
      t:set_gfx(0x228, false, false)
    end
  else
    if air_adj_upright(t,0,0) then
      t:set_gfx(0x228, false, true)
    else
      t:set_gfx(0x220, false, false)
    end
  end

elseif corner_upright(t) then
  if air_adj_downleft(t,0,0) then
    t:set_gfx(0x208, true, false)
  else
    t:set_gfx(0x200, true, false)
  end
elseif corner_downright(t) then
  if air_adj_upleft(t,0,0) then
    t:set_gfx(0x208, true, true)
  else
    t:set_gfx(0x200, true, true)
  end
elseif corner_upleft(t) then
  if air_adj_downright(t,0,0) then
    t:set_gfx(0x208, false, false)
  else
    t:set_gfx(0x200, false, false)
  end
elseif corner_downleft(t) then
  if air_adj_upright(t,0,0) then
    t:set_gfx(0x208, false, true)
  else
    t:set_gfx(0x200, false, true)
  end

elseif innercorner_upright(t) then
  inner_corner_tile(t, true, false)
elseif innercorner_downright(t) then
  inner_corner_tile(t, true, true)
elseif innercorner_upleft(t) then
  inner_corner_tile(t, false, false)
elseif innercorner_downleft(t) then
  inner_corner_tile(t, false, true)

elseif end_right(t) then
  t:set_gfx(0x203, true, false)
elseif end_left(t) then
  t:set_gfx(0x203, false, false)
elseif end_up(t) then
  t:set_gfx(0x202, false, false)
elseif end_down(t) then
  t:set_gfx(0x202, false, true)
elseif beam_h(t) then
  t:set_gfx(0x204, true, false)
elseif beam_v(t) then
  t:set_gfx(0x222, false, false)

elseif double_innercorner_up(t) then
  t:set_gfx(0x206, false, false)
elseif double_innercorner_down(t) then
  t:set_gfx(0x206, false, true)
elseif double_innercorner_left(t) then
  t:set_gfx(0x225, false, false)
elseif double_innercorner_right(t) then
  t:set_gfx(0x225, true, false)
elseif double_innercorner_diagonaldown(t) then
  t:set_gfx(0x226, false, false)
elseif double_innercorner_diagonalup(t) then
  t:set_gfx(0x226, false, true)
elseif triple_innercorner_upright(t) then
  t:set_gfx(0x207, false, true)
elseif triple_innercorner_downright(t) then
  t:set_gfx(0x207, false, false)
elseif triple_innercorner_upleft(t) then
  t:set_gfx(0x207, true, true)
elseif triple_innercorner_downleft(t) then
  t:set_gfx(0x207, true, false)
elseif quad_innercorner_downleft(t) then
  t:set_gfx(0x227, false, false)

elseif solid_float(t) then
  t:set_gfx(0x221, false, false)


elseif (type == 1) then

  local xflip = (bts & 0x40) ~= 0
  local yflip = (bts & 0x80) ~= 0
  local slope = (bts & 0x1F)

  if (slope == 0x12) then
    t:set_gfx(0x20D, xflip, yflip)
  elseif (slope == 0x14) then
    t:set_gfx(0x20E, xflip, yflip)
  elseif (slope == 0x15) then
    local tv = t:type(0, -flip_offset(yflip))
    local th = t:type(-flip_offset(xflip), 0)

    if (tv == 0) then
      if (th == 0) then
        t:set_gfx(0x230, xflip, yflip)
      else
        t:set_gfx(0x24F, xflip, yflip)
      end
    else
      if (th == 0) then
        t:set_gfx(0x211, xflip, yflip)
      else
        t:set_gfx(0x20F, xflip, yflip)
      end
    end
  elseif (slope == 0x16) then
    t:set_gfx(0x246, xflip, yflip)
  elseif (slope == 0x17) then
    t:set_gfx(0x247, xflip, yflip)
  elseif (slope == 0x1B) then
    t:set_gfx(0x248, xflip, yflip)
  elseif (slope == 0x1C) then
    t:set_gfx(0x268, xflip, yflip)
  elseif (slope == 0x00) then
    local tr = t:type(1, 0)
    local tl = t:type(-1, 0)
    local tv = t:type(0, flip_offset(yflip))

    if (tv == 0) then
      if (tr == 0) then
        if (tl == 0) then
          t:set_gfx(0x28D, false, yflip)
        else
          t:set_gfx(0x26B, true, yflip)
        end
      else
        if (tl == 0) then
          t:set_gfx(0x26B, false, yflip)
        else
          t:set_gfx(0x26C, false, yflip)
        end
      end
    else
      if (tr == 0) then
        if (tl == 0) then
          t:set_gfx(0x242, false, yflip)
        else
          t:set_gfx(0x262, true, yflip)
        end
      else
        if (tl == 0) then
          t:set_gfx(0x262, false, yflip)
        else
          t:set_gfx(0x241, false, yflip)
        end
      end
    end
  elseif (slope == 0x07) then
    local tr = t:type(1, 0)
    local tl = t:type(-1, 0)

    if (tr == 0) then
      if (tl == 0) then
        t:set_gfx(0x242, false, yflip)
      else
        t:set_gfx(0x262, true, yflip)
      end
    else
      if (tl == 0) then
        t:set_gfx(0x262, false, yflip)
      else
        t:set_gfx(0x241, false, yflip)
      end
    end
  elseif (slope == 0x01) then
    local tu = t:type(0, -1)
    local td = t:type(0, 1)
    local th = t:type(flip_offset(xflip), 0)

    if th == 0 then
      if (tu == 0) then
        if (td == 0) then
          t:set_gfx(0x2AD, not xflip, false)
        else
          t:set_gfx(0x2AE, not xflip, true)
        end
      else
        if (td == 0) then
          t:set_gfx(0x2AE, not xflip, false)
        else
          t:set_gfx(0x28E, not xflip, false)
        end
      end
    else
      if (tu == 0) then
        if (td == 0) then
          t:set_gfx(0x243, xflip, false)
        else
          t:set_gfx(0x263, xflip, false)
        end
      else
        if (td == 0) then
          t:set_gfx(0x263, xflip, true)
        else
          t:set_gfx(0x260, xflip, false)
        end
      end
    end
  elseif (slope == 0x02) then
    local tv = t:type(0, flip_offset(yflip))
    local th = t:type(flip_offset(xflip), 0)

    if (tv == 0) then
      if (th == 0) then
        t:set_gfx(0x26F, xflip, yflip)
      else
        t:set_gfx(0x26D, not xflip, yflip)
      end
    else
      if (th == 0) then
        t:set_gfx(0x26E, not xflip, yflip)
      else
        t:set_gfx(0x240, xflip, yflip)
      end
    end
  elseif (slope == 0x03) then
    t:set_gfx(0x261, xflip, yflip)
  elseif (slope == 0x13) then
    t:set_gfx(0x0FF, false, false)
  else
    -- Unknown. Defaulting to X tile
    t:set_gfx(0x0DF, false, false)
  end

elseif true_center(t) then
  local td = t:type(0, 1)
  local bd = t:bts(0, 1)
  local xflipd = (bd & 0x40) ~= 0
  local yflipd = (bd & 0x80) ~= 0
  bd = bd & 0x1F

  local tu = t:type(0, -1)
  local bu = t:bts(0, -1)
  local xflipu = (bu & 0x40) ~= 0
  local yflipu = (bu & 0x80) ~= 0
  bu = bu & 0x1F

  if (td == 1 and bd == 0x12) then
    t:set_gfx(0x22D, xflipd, yflipd)
  elseif (tu == 1 and bu == 0x12) then
    t:set_gfx(0x22D, xflipu, yflipu)
  else
    t:set_gfx(0x0FF, true, false)
  end
elseif air(t,0,0) then
  t:set_gfx(0x0FF, false, false)
else
  -- Unknown. Defaulting to X tile
  t:set_gfx(0x2FF, false, false)
end
return true