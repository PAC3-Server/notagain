if SERVER then 

	util.AddNetworkString("SanitizeSpawn")
	
	local sanitizeCvar = CreateConVar("sanitize_prop_spawn", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Prevents spawning props at a blocked area.")
	
	-- NOTE: We add a slight offset so stacking will remain functional.
	local stackingOffset = Vector(0, 0, 0.01)
	
	local function CheckSpawnedObject(ply, mdl, ent)
				
		-- Ignore props that are frozen.
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then 
			if phys:IsMotionEnabled() == false then 
				return false 
			end 
		end 
		
		local trace = 
		{ 
			start = ent:GetPos() + stackingOffset, 
			endpos = ent:GetPos() + stackingOffset, 
			filter = ent,
		}

		local tr = util.TraceEntity( trace, ent )		
		if tr.Hit == true and IsValid(tr.Entity) then 
			-- Ignore intersecting objects that spawned the same frame.
			local t = math.abs(tr.Entity:GetCreationTime() - ent:GetCreationTime())
			if t == 0 then 
				return false 
			end 
		end 
		
		return tr.Hit
		
	end

	hook.Add("PlayerSpawnedProp", "SanitizeSpawn", function(ply, mdl, ent)

		if sanitizeCvar:GetBool() == false then 
			return 
		end 
		-- Check next frame.
		timer.Simple(0, function()
			if not IsValid(ent) then 
				return 
			end 
			if CheckSpawnedObject(ply, mdl, ent) == true then 
				ent:Remove()
				net.Start("SanitizeSpawn")
				net.Send(ply)
			end 
		end)
		
	end)	
	
else 

	net.Receive("SanitizeSpawn", function(len)
		notification.AddLegacy( "Bad placement position", NOTIFY_ERROR, 3 )
		surface.PlaySound( "buttons/button10.wav" )
	end)
	
end 