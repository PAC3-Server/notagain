local old = surface.SetFont
local last

function surface.SetFont(name)
	if name ~= last then
		old(name)
		last = name
	end
end
