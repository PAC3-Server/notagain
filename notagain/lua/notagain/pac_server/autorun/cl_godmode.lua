local dmgvar = CreateClientConVar("cl_godmode", "1", true, true)

hook.Add("PlayerTraceAttack", "cl_godmode", function(ply, dmginfo)
	if SERVER then
		ply:SetNWBool("cl_godmode", ply:GetInfoNum("cl_godmode", 1))
	end

	if ply:GetNWBool("cl_godmode", 1) == 1  then
		ply.damage_mode_bleed_color = ply:GetBloodColor()
		ply:SetBloodColor(DONT_BLEED)
		timer.Simple(0, function() ply:RemoveAllDecals() end)
		return false
	elseif ply.damage_mode_bleed_color then
		ply:SetBloodColor(ply.damage_mode_bleed_color)
		ply.damage_mode_bleed_color = nil
	end
end)

if SERVER then
	RunConsoleCommand("sbox_godmode", "0")

	hook.Add("EntityTakeDamage", "cl_godmode", function(ply, dmginfo)
		local attacker = dmginfo:GetAttacker()
		if
			ply:IsPlayer() and
			(
				ply:GetInfoNum("cl_godmode", 1) == 1 or
				attacker:IsValid() and (attacker.cl_godmode_dropped or (attacker:IsPlayer() and attacker:GetInfoNum("cl_godmode", 1) == 1))
			)
		then
			dmginfo:SetDamage(0)
			dmginfo:SetDamageForce(vector_origin)

			return false
		end
	end)

	local function PassGoddedVarToPhysChild(data, physobj)
		if IsValid(data.Entity) and not data.Entity:IsWorld() and IsValid(data.Entity:GetPhysicsObject()) and not data.Entity.cl_godmode_dropped then
			data.Entity.cl_godmode_dropped = true
			local phys = data.Entity:GetPhysicsObject()
			if phys:IsValid() then
				phys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
				data.Entity:AddCallback("PhysicsCollide", PassGoddedVarToPhysChild)
			end
		end
	end

	local function PreventGoddedPropKills(ply,ent)
		if ply:GetInfoNum("cl_godmode", 1) == 1 then
			if not ent.cl_godmode_dropped then
				ent.cl_godmode_dropped = true
				local phys = ent:GetPhysicsObject()
				if phys:IsValid() then
					phys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
					ent:AddCallback("PhysicsCollide", PassGoddedVarToPhysChild)
				end
			elseif ent.cl_godmode_dropped then
				local phys = ent:GetPhysicsObject()
				if phys:IsValid() then
					phys:ClearGameFlag(FVPHYSICS_NO_IMPACT_DMG)
				end
				ent.cl_godmode_dropped = false
			end
		end
	end

	local function AddGoddedVarToSpawnedProps(ply, mdl, ent)
		if ply:GetInfoNum("cl_godmode",1) == 1 then
			if !ent.cl_godmode_dropped then
				ent.cl_godmode_dropped = true
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					phys:ClearGameFlag(FVPHYSICS_NO_IMPACT_DMG)
					ent:AddCallback("PhysicsCollide", PassGoddedVarToPhysChild)
				end
			end
		end
	end

	hook.Add("PhysgunPickup", "cl_godmode", PreventGoddedPropKills)
	hook.Add("PhysgunDrop", "cl_godmode", PreventGoddedPropKills)
	hook.Add("PlayerSpawnedSENT", "cl_godmode", PreventGoddedPropKills)
	hook.Add("PlayerSpawnedVehicle", "cl_godmode", PreventGoddedPropKills)
	hook.Add("PlayerSpawnedProp", "cl_godmode", AddGoddedVarToSpawnedProps)
	hook.Add("PlayerSpawnedRagdoll", "cl_godmode", AddGoddedVarToSpawnedProps)
	hook.Add("PlayerSpawnedSWEP", "cl_godmode", AddGoddedVarToSpawnedProps)

end
