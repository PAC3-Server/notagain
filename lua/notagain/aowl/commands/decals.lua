AddCSLuaFile()

local Tag="decals"

if SERVER then
	util.AddNetworkString(Tag)
	
	aowl.AddCommand({"decals","cleardecals"}, function( player , line )
		if IsValid(player) then
			player:ConCommand("r_cleardecals")
		end
	end)
end
