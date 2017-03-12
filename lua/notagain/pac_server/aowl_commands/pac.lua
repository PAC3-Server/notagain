local easylua = requirex("easylua")

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

aowl.AddCommand("ignorepac",function(ply,line,target)
	target = easylua.FindEntity(target)

	if target and IsValid(target) and Isvalid(ply) and target:IsPlayer() then

		ply:SendLua([[pac.IgnoreEntity(]]..target..[[)]])

	end

end)

aowl.AddCommand("unignorepac",function(ply,line,target)
	target = easylua.FindEntity(target)

	if target and IsValid(target) and IsValid(ply) and target:IsPlayer() then

		ply:SendLua([[pac.UnIgnoreEntity(]]..target..[[)]])

	end

end)
