aowl.AddCommand("fixpac", function(ply)
	if IsValid(ply) and pace then
		ply.pac_requested_outfits = false
		pace.RequestOutfits(ply)
	end
end)

aowl.AddCommand("wear", function(ply,line,file)
	if IsValid(ply) and file then
		ply:ConCommand("pac_wear_parts \"" .. file.."\"")
	end
end)