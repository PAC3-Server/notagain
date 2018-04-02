if SERVER then 

	util.AddNetworkString("SanitizeSpawn")
	
	local sanitizeCvar = CreateConVar("sanitize_prop_spawn", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Prevents spawning props at a blocked area.")
	
	-- NOTE: We add a slight offset so stacking will remain functional.
	local stackingOffset = Vector(0, 0, 0.01)
	
	local function CheckSpawnedObject(ply, mdl, ent)
		
		local trace = 
		{ 
			start = ent:GetPos() + stackingOffset, 
			endpos = ent:GetPos() + stackingOffset, 
			filter = ent,
		}

		local tr = util.TraceEntity( trace, ent )		
		return tr.Hit
		
	end

	hook.Add("PlayerSpawnedProp", "SanitizeSpawn", function(ply, mdl, ent)

		if sanitizeCvar:GetBool() == false then 
			return 
		end 
			
		if CheckSpawnedObject(ply, mdl, ent) == true then 
			ent:Remove()
			net.Start("SanitizeSpawn")
			net.Send(ply)
		end 
		
	end)	
	
else 

	net.Receive("SanitizeSpawn", function(len)
		notification.AddLegacy( "Bad placement position", NOTIFY_ERROR, 3 )
		surface.PlaySound( "buttons/button10.wav" )
	end)
	
end 