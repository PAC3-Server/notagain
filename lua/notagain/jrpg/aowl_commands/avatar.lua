aowl.AddCommand("avatar=string,number[0],number[0],number[1]", function(ply, _, url, center_x, center_y, scale)
	if url == "reset" then
		avatar.SetPlayer(ply)
		return
	end

	avatar.SetPlayer(ply, url, center_x, center_y, scale)
end)
