local white = surface.GetTextureID("vgui/white")

return function(x1,y1, x2,y2, w, skip_tex)
	w = w or 1
	if not skip_tex then surface.SetTexture(white) end

	local dx,dy = x1-x2, y1-y2
	local ang = math.atan2(dx, dy)
	local dst = math.sqrt((dx * dx) + (dy * dy))

	x1 = x1 - dx * 0.5
	y1 = y1 - dy * 0.5

	surface.DrawTexturedRectRotated(x1, y1, w, dst, math.deg(ang))
end