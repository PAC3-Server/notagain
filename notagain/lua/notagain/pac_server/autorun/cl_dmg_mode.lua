local dmgvar = CreateClientConVar("cl_dmg_mode", "1", true, true)

if SERVER then

	local function DamageMode(pl,dmginfo)
		if (IsValid(pl) && pl:IsPlayer() && pl:GetInfoNum("cl_dmg_mode",1) == 1) 
		|| (IsValid(pl) && pl:IsPlayer() && IsValid(dmginfo:GetAttacker()) && (dmginfo:GetAttacker().DroppedByGod || (dmginfo:GetAttacker():IsPlayer() && dmginfo:GetAttacker():GetInfoNum("cl_dmg_mode",1) == 1))) then
			dmginfo:SetDamage(0)
			dmginfo:SetDamageForce(vector_origin)
			return false
		end
	end

	hook.Add("EntityTakeDamage","DamageMode",DamageMode)
	
	local function PassGoddedVarToPhysChild(data,physobj)
		if IsValid(data.Entity) && !data.Entity:IsWorld() && IsValid(data.Entity:GetPhysicsObject()) then
			if !data.Entity.DroppedByGod then
				data.Entity.DroppedByGod = true
				local phys = data.Entity:GetPhysicsObject()
				if IsValid(data.Entity) then
					phys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
					data.Entity:AddCallback("PhysicsCollide",PassGoddedVarToPhysChild)
				end
			end
		end
	end

	local function PreventGoddedPropKills(pl,ent)
		if IsValid(pl) && IsValid(ent) && pl:GetInfoNum("cl_dmg_mode",1) == 1 then
			if !ent.DroppedByGod then
				ent.DroppedByGod = true
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					phys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
					ent:AddCallback("PhysicsCollide",PassGoddedVarToPhysChild)
				end
			end
		elseif IsValid(pl) && IsValid(ent) && pl:GetInfoNum("cl_dmg_mode",1) == 1 then
			if ent.DroppedByGod then
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					phys:ClearGameFlag(FVPHYSICS_NO_IMPACT_DMG)
				end
				ent.DroppedByGod = false
			end
		end
	end

	hook.Add("PhysgunPickup","PreventGoddedPropKills",PreventGoddedPropKills)	
	hook.Add("PhysgunDrop","PreventGoddedPropKills",PreventGoddedPropKills)
	hook.Add("PlayerSpawnedSENT","AddGoddedVarToSpawnedSENT",PreventGoddedPropKills)
	hook.Add("PlayerSpawnedVehicle","AddGoddedVarToSpawnedVehicle",PreventGoddedPropKills)
	
	local function AddGoddedVarToSpawnedProps(pl,mdl,ent)
		if IsValid(pl) && IsValid(ent) && pl:GetInfoNum("cl_dmg_mode",1) == 1 then
			if !ent.DroppedByGod then
				ent.DroppedByGod = true
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					phys:ClearGameFlag(FVPHYSICS_NO_IMPACT_DMG)
					ent:AddCallback("PhysicsCollide",PassGoddedVarToPhysChild)
				end
			end
		end
	end	
	
	hook.Add("PlayerSpawnedProp","AddGoddedVarToSpawnedProp",AddGoddedVarToSpawnedProps)
	hook.Add("PlayerSpawnedRagdoll","AddGoddedVarToSpawnedRagdoll",AddGoddedVarToSpawnedProps)
	hook.Add("PlayerSpawnedSWEP","AddGoddedVarToSpawnedSWEP",AddGoddedVarToSpawnedProps)

end
