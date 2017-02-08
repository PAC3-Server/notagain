aowl.AddCommand("fixpac", function(ply)
	if IsValid(ply) and pace then
		ply.pac_requested_outfits = false
		pace.RequestOutfits(ply)
	end
end)

aowl.AddCommand("wear", function(ply,_,filename)
	if IsValid(ply) then
		ply:ConCommand("pac_wear_parts " .. filename)
	end
end)
