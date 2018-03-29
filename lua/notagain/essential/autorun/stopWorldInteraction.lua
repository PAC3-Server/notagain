hook.Add("PhysgunPickup", "stopWorldInteraction", function(ply, ent)
	if ent and ent.CPPIGetOwner and ({ent:CPPIGetOwner()})[1] == nil then 
		return false 
	end
end)

hook.Add("CanTool", "stopWorldInteraction", function(ply, tr, tool)
	local ent = tr.Entity
	if ent and ent.CPPIGetOwner and tool ~= "camera" then
		if ({ent:CPPIGetOwner()})[1] == nil then
			return ply:IsSuperAdmin()
		end
	end
end)
