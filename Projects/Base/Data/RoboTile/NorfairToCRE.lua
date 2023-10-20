-- Replace specialized Norfair CRE-like tiles with regular CRE tiles

if t:gfx_tile(0, 0) == 0x144 then
    t:set_gfx(0x5F, false, false)
end
if t:gfx_tile(0, 0) == 0x147 then
    t:set_gfx(0x9E, false, false)
end
if t:gfx_tile(0, 0) == 0x148 or t:gfx_tile(0, 0) == 0x146 then
    t:set_gfx(0xBE, false, false)
end
