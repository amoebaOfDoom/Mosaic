local type = t:type(0,0)
local bts = t:bts(0,0)
local gfx = t:gfx_tile(0,0)

-- door caps
if (gfx <= 0x43) or (gfx >= 0x60 and gfx <= 0x63) then
  return true
end

-- door tubes
if gfx == 0x82 or gfx == 0x83 or gfx == 0x84 or gfx == 0xA2 then
  return true
end

-- vileplumes
if (gfx >= 0x3B8 and gfx <= 0x3BF) or (gfx >= 0x3D8 and gfx <= 0x3DF) then
  return true
end

-- save station
if (gfx >= 0x59 and gfx <= 0x5C) then
  return true
end

-- refill stations
if gfx == 0xA1 or (gfx >= 0xA3 and gfx <= 0xA9) or (gfx >= 0xC1 and gfx <= 0xC9) then
  return true
end

t:set_gfx(0x0FF, false, false)
return true