AddCSLuaFile()

local Tag="decals"

if SERVER then
	util.AddNetworkString(Tag)
	
	aowl.AddCommand({"decals","cleardecals"}, function( player , line )
		if IsValid(player) then
			net.Start(Tag)
			net.Send(player)
		end
	end)
end

if CLIENT then
	net.Receive(Tag,function()
		RunConsoleCommand("r_cleardecals")
	end)
end
