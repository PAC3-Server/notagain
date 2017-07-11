aowl.AddCommand("avatar=string,number[0],number[0],number[1]", function(ply, _, url,cx,cy,s)
	if url == "reset" then
		avatar.SetPlayer(ply)
		return
	end

	avatar.SetPlayer(ply, url, cx, cy, s)
end)