local easylua = requirex("easylua")
local Tag1 = "aowlpacignore"
local Tag2 = "aowlpacunignore"

if SERVER then
	util.AddNetworkString(Tag1)
	util.AddNetworkString(Tag2)
	
	aowl.AddCommand({"fixpac"}, function(ply)
		if IsValid(ply) and pace then
			ply.pac_requested_outfits = false
			pace.RequestOutfits(ply)
		end
	end)

	aowl.AddCommand({"wear"}, function(ply,line,file)
		if IsValid(ply) and file then
			ply:ConCommand("pac_wear_parts \"" .. file.."\"")
		end
	end)
	
	aowl.AddCommand({"clear"}, function(ply,line,file)
		if IsValid(ply) then
			ply:ConCommand("pac_clear_parts")
		end
	end)

	aowl.AddCommand({"ignorepac"},function(ply,line,target)
		if not target then return end
		local target = easylua.FindEntity(target)
		if IsValid(target) and IsValid(ply) and target:IsPlayer() then
			net.Start(Tag1)
			net.WriteEntity(target)
			net.Send(ply)
		end
	end)
	
	aowl.AddCommand({"unignorepac"},function(ply,line,target)
		if not target then return end
		local target = easylua.FindEntity(target)
		if IsValid(target) and IsValid(ply) and target:IsPlayer() then
			net.Start(Tag2)
			net.WriteEntity(target)
			net.Send(ply)
		end
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
