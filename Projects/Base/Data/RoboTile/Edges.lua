function solid(t,a,b)
  return ((t:type(a,b) == 8) or
   ((t:type(a,b) == 1) and (t:bts(a,b) & 0x1F) == 0x13))
end

function air(t,a,b)
  return ((t:type(a,b) == 0) or (t:type(a,b) == 2))
end

function slope(t,a,b)
  return ((t:type(a,b) == 1) and (t:bts(a,b) & 0x1F) ~= 0x13)
end

function solid_adj_up(t,a,b)
	local p = t:props(a+0,b-1)
	if (p.type == p.type.Mix) then return false end
	return (p.bottom.left == 1) or (p.bottom.right == 1)
end

function solid_adj_down(t,a,b)
	local p = t:props(a+0,b+1)
	if (p.type == p.type.Mix) then return false end
	return (p.top.left == 1) or (p.top.right == 1)
end

function solid_adj_right(t,a,b)
	local p = t:props(a+1,b+0)
	if (p.type == p.type.Mix) then return false end
	return (p.left.top == 1) or (p.left.bottom == 1)
end

function solid_adj_left(t,a,b)
	local p = t:props(a-1,b+0)
	if (p.type == p.type.Mix) then return false end
	return (p.right.top == 1) or (p.right.bottom == 1)
end


function air_adj_up(t,a,b)
	local p = t:props(a+0,b-1)
	if (p.type == p.type.Mix) then return true end
	return (p.bottom.left == 0) and (p.bottom.right == 0)
end

function air_adj_down(t,a,b)
	local p = t:props(a+0,b+1)
	if (p.type == p.type.Mix) then return true end
	return (p.top.left == 0) and (p.top.right == 0)
end

function air_adj_right(t,a,b)
	local p = t:props(a+1,b+0)
	if (p.type == p.type.Mix) then return true end
	return (p.left.top == 0) and (p.left.bottom == 0)
end

function air_adj_left(t,a,b)
	local p = t:props(a-1,b+0)
	if (p.type == p.type.Mix) then return true end
	return (p.right.top == 0) and (p.right.bottom == 0)
end


function air_adj_upright(t,a,b)
	local p = t:props(a+1,b-1)
	if ((p.bottom.left == 0) and (p.bottom.right == 0)) or
		((p.left.top == 0) and (p.left.bottom == 0)) then
		return true
	end

	p = t:props(a+0,b-1)
	if ((p.right.top == 0) and (p.right.bottom == 0)) then
		return true
	end

	p = t:props(a+1,b-0)
	if ((p.top.left == 0) and (p.top.right == 0)) then
		return true
	end

	return false
end

function air_adj_downright(t,a,b)
	local p = t:props(a+1,b+1)
	if ((p.top.left == 0) and (p.top.right == 0)) or
		((p.left.top == 0) and (p.left.bottom == 0)) then
		return true
	end

	p = t:props(a+0,b+1)
	if ((p.left.top == 0) and (p.left.bottom == 0)) then
		return true
	end

	p = t:props(a+1,b-0)
	if ((p.bottom.left == 0) and (p.bottom.right == 0)) then
		return true
	end

	return false
end

function air_adj_upleft(t,a,b)
	local p = t:props(a-1,b-1)
	if ((p.bottom.left == 0) and (p.bottom.right == 0)) or
		((p.right.top == 0) and (p.right.bottom == 0)) then
		return true
	end

	p = t:props(a-0,b-1)
	if ((p.left.top == 0) and (p.left.bottom == 0)) then
		return true
	end

	p = t:props(a-1,b-0)
	if ((p.top.left == 0) and (p.top.right == 0)) then
		return true
	end

	return false
end

function air_adj_downleft(t,a,b)
	local p = t:props(a-1,b+1)
	if ((p.top.left == 0) and (p.top.right == 0)) or
		((p.right.top == 0) and (p.right.bottom == 0)) then
		return true
	end

	p = t:props(a-0,b+1)
	if ((p.left.top == 0) and (p.left.bottom == 0)) then
		return true
	end

	p = t:props(a-1,b+0)
	if ((p.bottom.left == 0) and (p.bottom.right == 0)) then
		return true
	end

	return false
end


function edge_up(t)
    return (solid(t,0,0) and
      air_adj_up(t,0,0) and
      solid_adj_down(t,0,0) and
      solid_adj_right(t,0,0) and
      solid_adj_left(t,0,0))
end

function edge_down(t)
    return (solid(t,0,0) and
      solid_adj_up(t,0,0) and
      air_adj_down(t,0,0) and
      solid_adj_right(t,0,0) and
      solid_adj_left(t,0,0))
end

function edge_right(t)
    return (solid(t,0,0) and
      solid_adj_up(t,0,0) and
      solid_adj_down(t,0,0) and
      air_adj_right(t,0,0) and
      solid_adj_left(t,0,0))
end

function edge_left(t)
    return (solid(t,0,0) and
      solid_adj_up(t,0,0) and
      solid_adj_down(t,0,0) and
      solid_adj_right(t,0,0) and
      air_adj_left(t,0,0))
end


function corner_upright(t)
    return (solid(t,0,0) and
      air_adj_up(t,0,0) and
      solid_adj_down(t,0,0) and
      air_adj_right(t,0,0) and
      solid_adj_left(t,0,0))
end

function corner_downright(t)
    return (solid(t,0,0) and
      solid_adj_up(t,0,0) and
      air_adj_down(t,0,0) and
      air_adj_right(t,0,0) and
      solid_adj_left(t,0,0))
end

function corner_upleft(t)
    return (solid(t,0,0) and
      air_adj_up(t,0,0) and
      solid_adj_down(t,0,0) and
      solid_adj_right(t,0,0) and
      air_adj_left(t,0,0))
end

function corner_downleft(t)
    return (solid(t,0,0) and
      solid_adj_up(t,0,0) and
      air_adj_down(t,0,0) and
      solid_adj_right(t,0,0) and
      air_adj_left(t,0,0))
end


function end_up(t)
    return (solid(t,0,0) and
      air_adj_up(t,0,0) and
      solid_adj_down(t,0,0) and
      air_adj_right(t,0,0) and
      air_adj_left(t,0,0))
end

function end_down(t)
    return (solid(t,0,0) and
      solid_adj_up(t,0,0) and
      air_adj_down(t,0,0) and
      air_adj_right(t,0,0) and
      air_adj_left(t,0,0))
end

function end_right(t)
    return (solid(t,0,0) and
      air_adj_up(t,0,0) and
      air_adj_down(t,0,0) and
      air_adj_right(t,0,0) and
      solid_adj_left(t,0,0))
end

function end_left(t)
    return (solid(t,0,0) and
      air_adj_up(t,0,0) and
      air_adj_down(t,0,0) and
      solid_adj_right(t,0,0) and
      air_adj_left(t,0,0))
end


function beam_h(t)
    return (solid(t,0,0) and
      air_adj_up(t,0,0) and
      air_adj_down(t,0,0) and
      solid_adj_right(t,0,0) and
      solid_adj_left(t,0,0))
end

function beam_v(t)
    return (solid(t,0,0) and
      solid_adj_up(t,0,0) and
      solid_adj_down(t,0,0) and
      air_adj_right(t,0,0) and
      air_adj_left(t,0,0))
end

function solid_float(t)
    return (solid(t,0,0) and
      air_adj_up(t,0,0) and
      air_adj_down(t,0,0) and
      air_adj_right(t,0,0) and
      air_adj_left(t,0,0))
end


function center(t)
    return (solid(t,0,0) and
      solid_adj_up(t,0,0) and
      solid_adj_down(t,0,0) and
      solid_adj_right(t,0,0) and
      solid_adj_left(t,0,0))
end


function innercorner_upright(t)
    return (center(t,0,0) and
    	air_adj_upright(t,0,0) and
    	not air_adj_downright(t,0,0) and
    	not air_adj_upleft(t,0,0) and
    	not air_adj_downleft(t,0,0))
end

function innercorner_downright(t)
    return (center(t,0,0) and
    	not air_adj_upright(t,0,0) and
    	air_adj_downright(t,0,0) and
    	not air_adj_upleft(t,0,0) and
    	not air_adj_downleft(t,0,0))
end

function innercorner_upleft(t)
    return (center(t,0,0) and
    	not air_adj_upright(t,0,0) and
    	not air_adj_downright(t,0,0) and
    	air_adj_upleft(t,0,0) and
    	not air_adj_downleft(t,0,0))
end

function innercorner_downleft(t)
    return (center(t,0,0) and
    	not air_adj_upright(t,0,0) and
    	not air_adj_downright(t,0,0) and
    	not air_adj_upleft(t,0,0) and
    	air_adj_downleft(t,0,0))
end

function double_innercorner_up(t)
    return (center(t,0,0) and
    	air_adj_upright(t,0,0) and
    	not air_adj_downright(t,0,0) and
    	air_adj_upleft(t,0,0) and
    	not air_adj_downleft(t,0,0))
end

function double_innercorner_down(t)
    return (center(t,0,0) and
    	not air_adj_upright(t,0,0) and
    	air_adj_downright(t,0,0) and
    	not air_adj_upleft(t,0,0) and
    	air_adj_downleft(t,0,0))
end

function double_innercorner_left(t)
    return (center(t,0,0) and
    	not air_adj_upright(t,0,0) and
    	not air_adj_downright(t,0,0) and
    	air_adj_upleft(t,0,0) and
    	air_adj_downleft(t,0,0))
end

function double_innercorner_right(t)
    return (center(t,0,0) and
    	air_adj_upright(t,0,0) and
    	air_adj_downright(t,0,0) and
    	not air_adj_upleft(t,0,0) and
    	not air_adj_downleft(t,0,0))
end

function double_innercorner_diagonaldown(t)
    return (center(t,0,0) and
    	not air_adj_upright(t,0,0) and
    	air_adj_downright(t,0,0) and
    	air_adj_upleft(t,0,0) and
    	not air_adj_downleft(t,0,0))
end

function double_innercorner_diagonalup(t)
    return (center(t,0,0) and
    	air_adj_upright(t,0,0) and
    	not air_adj_downright(t,0,0) and
    	not air_adj_upleft(t,0,0) and
    	air_adj_downleft(t,0,0))
end

function triple_innercorner_upright(t)
    return (center(t,0,0) and
    	not air_adj_upright(t,0,0) and
    	air_adj_downright(t,0,0) and
    	air_adj_upleft(t,0,0) and
    	air_adj_downleft(t,0,0))
end

function triple_innercorner_downright(t)
    return (center(t,0,0) and
    	air_adj_upright(t,0,0) and
    	not air_adj_downright(t,0,0) and
    	air_adj_upleft(t,0,0) and
    	air_adj_downleft(t,0,0))
end

function triple_innercorner_upleft(t)
    return (center(t,0,0) and
    	air_adj_upright(t,0,0) and
    	air_adj_downright(t,0,0) and
    	not air_adj_upleft(t,0,0) and
    	air_adj_downleft(t,0,0))
end

function triple_innercorner_downleft(t)
    return (center(t,0,0) and
    	air_adj_upright(t,0,0) and
    	air_adj_downright(t,0,0) and
    	air_adj_upleft(t,0,0) and
    	not air_adj_downleft(t,0,0))
end

function quad_innercorner_downleft(t)
    return (center(t,0,0) and
    	air_adj_upright(t,0,0) and
    	air_adj_downright(t,0,0) and
    	air_adj_upleft(t,0,0) and
    	air_adj_downleft(t,0,0))
end


function true_center(t)
    return (center(t,0,0) and
    	not air_adj_upright(t,0,0) and
    	not air_adj_downright(t,0,0) and
    	not air_adj_upleft(t,0,0) and
    	not air_adj_downleft(t,0,0))
end

function cre(t)
    return (t:gfx_tile(0,0) < 0xFE)
end