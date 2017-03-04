aowl.AddCommand("avatar", function(ply, _, url,w,h,cx,cy,s)
	if not url then
		avatar.SetPlayer(ply)
		return
	end

	if not w then
		return false, "usage: !avatar url, width, height, center_x, center_y, scale"
	end

	w = tonumber(w)
	h = tonumber(h) or w
	cx = tonumber(cx) or w/2
	cy = tonumber(cy) or h/2
	s = tonumber(s) or 1

	avatar.SetPlayer(ply, url,w,h,cx,cy,s)
end)