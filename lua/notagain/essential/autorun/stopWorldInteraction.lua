local whitelist = {
	["camera"] = 1,
	["advdupe2"] = 1
}

hook.Add("PhysgunPickup", "stopWorldInteraction", function(ply, ent)
	if ent.CPPIGetOwner and ( not ent:IsPlayer() ) then
		if ({ent:CPPIGetOwner()})[1] == nil then 
			return false 
		end
	end
end)

local function checkClass(class)
	if string.find( class, "func_" ) then return true end
	if string.find( class, "prop_" ) then return true end
	if string.find( class, "gmod_" ) then return true end
	return false
end

hook.Add("CanTool", "stopWorldInteraction", function(ply, tr, tool)
	local ent = tr.Entity
	if ( ent and ent.CPPIGetOwner ) and not whitelist[tool] then
		local class = ent.GetClass and ent:GetClass()
		if class and checkClass(class) then
			if ({ent:CPPIGetOwner()})[1] == nil then
				return ply:IsSuperAdmin()
			end
		end
	end
end)
