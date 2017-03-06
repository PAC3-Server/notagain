aowl.AddCommand("avatar", function(ply, _, url,cx,cy,s)
	if not url then
		avatar.SetPlayer(ply)
		return
	end

	if not cx then
		return false, "usage: !avatar url, center_x, center_y, scale"
	end

	cx = tonumber(cx) or 0
	cy = tonumber(cy) or 0
	s = tonumber(s) or 1

	avatar.SetPlayer(ply, url,cx,cy,s)
end)