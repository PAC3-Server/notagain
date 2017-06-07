AddCSLuaFile()

local Tag="search"

if SERVER then
	util.AddNetworkString(Tag)
	
	aowl.AddCommand({"g","search"}, function( player , line , search )
		if search then
			net.Start(Tag)
			net.WriteString(search)
			net.Send(player)
		end
	end)
end

if CLIENT then
	net.Receive(Tag,function()
		local parts = string.Explode(" ",net.ReadString())
		gui.OpenURL("https://www.google.com/#q="..table.concat( parts, "+", 1, #parts ))
	end)
end
