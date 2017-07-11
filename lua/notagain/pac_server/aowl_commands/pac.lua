AddCSLuaFile()

local Tag1 = "aowlpacignore"
local Tag2 = "aowlpacunignore"

if SERVER then
	util.AddNetworkString(Tag1)
	util.AddNetworkString(Tag2)

	aowl.AddCommand("fixpac", function(ply)
		if pace then
			ply.pac_requested_outfits = false
			pace.RequestOutfits(ply)
		end
	end)

	aowl.AddCommand("wear=string", function(ply, line, file)
		ply:ConCommand("pac_wear_parts \"" .. file.."\"")
	end)

	aowl.AddCommand("clear", function(ply, line)
		ply:ConCommand("pac_clear_parts")
	end)

	aowl.AddCommand("ignorepac=player", function(ply,line,target)
		net.Start(Tag1)
			net.WriteEntity(target)
		net.Send(ply)
	end)

	aowl.AddCommand("unignorepac=player", function(ply, line, target)
		net.Start(Tag2)
		net.WriteEntity(target)
		net.Send(ply)
	end)
end

if CLIENT then
	net.Receive(Tag1,function()
		pac.IgnoreEntity(net.ReadEntity())
	end)

	net.Receive(Tag2,function()
		pac.UnIgnoreEntity(net.ReadEntity())
	end)
end
