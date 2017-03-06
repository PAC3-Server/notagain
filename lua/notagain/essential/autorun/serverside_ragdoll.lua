if CLIENT then
	local META = FindMetaTable("Player")
	META.Old_GetRagdollEntity = META.Old_GetRagdollEntity or META.GetRagdollEntity

	function META:GetRagdollEntity(...)
		local ent = self:GetNWEntity("serverside_ragdoll")
		if ent:IsValid() then
			return ent
		end
		return META.Old_GetRagdollEntity(self, ...)
	end

	local META = FindMetaTable("Entity")
	META.Old_GetRagdollOwner = META.Old_GetRagdollOwner or META.GetRagdollOwner

	function META:GetRagdollOwner(...)
		local ply = self:GetOwner()
		if ply:IsValid() and ply:IsPlayer() and ply:GetRagdollEntity() == self then
			return ply
		end
		return META.Old_GetRagdollOwner(self, ...)
	end

	function META:GetRagdollEntity(...)
		local ent = ply:GetNWEntity("serverside_ragdoll")
		if ent:IsValid() then
			return ent
		end
		return META.Old_GetRagdollEntity(self, ...)
	end

	hook.Add("CalcView", "serverside_ragdoll", function(ply, origin, angles)
		local ent = ply:GetNWEntity("serverside_ragdoll")
		if ent:IsValid() then
			return {
				origin = util.QuickTrace(ent:GetPos(), angles:Forward() * -100, ent).HitPos
			}
		end
	end)
end

if SERVER then
	hook.Add("DoPlayerDeath", "serverside_ragdoll", function(ply, attacker, dmginfo)
		if not dmginfo:GetDamageForce():IsZero() then
			local force = dmginfo:GetDamageForce()
			local length = force:Length()
			force:Normalize()

			ply.serverside_ragdoll_vel = force * math.min(length, 500)
		end
	end)

	hook.Add("PlayerDeath", "serverside_ragdoll", function(ply)
		SafeRemoveEntity(ply:GetRagdollEntity())
		for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
			if ent:GetOwner() == ply then
				ent:Remove()
			end
		end

		timer.Simple(0, function() if ply:IsValid() then ply:SetMoveType(MOVETYPE_FLYGRAVITY) end end)

		hook.Add("OnEntityCreated", "serverside_ragdoll", function(ent)
			if ply:IsValid()  then
				if ent:GetOwner() == ply then
					ply:SetNWEntity("serverside_ragdoll", ent)
					for i = 1, ent:GetPhysicsObjectCount() - 1 do
						local phys = ent:GetPhysicsObjectNum(i)
						phys:SetVelocity(ply.serverside_ragdoll_vel or ply:GetVelocity())
					end
				end
				ply.serverside_ragdoll_vel = nil
			end
			hook.Remove("OnEntityCreated", "serverside_ragdoll")
		end)
	end)

	hook.Add("PlayerSpawn", "serverside_ragdoll", function(ply)
		for _, ent in pairs(ents.FindByClass("prop_ragdoll")) do
			if ent:GetOwner() == ply then
				ent:Remove()
			end
		end
		ply:SetShouldServerRagdoll(true)
	end)

	hook.Add("PlayerDisconnected", "serverside_ragdoll", function(ply)
		ply:Kill()
		local rag = ply:GetNWEntity("serverside_ragdoll")
		rag.serverside_ragdoll_disconnected = ply:UniqueID()
		rag.serverside_ragdoll_eyeangles = ply:EyeAngles()
		SafeRemoveEntityDelayed(rag, 120)
	end)

	hook.Add("PlayerInitialSpawn", "serverside_ragdoll", function(ply)
		timer.Simple(0, function()
			if not ply:IsValid() then return end
			for _, ent in pairs(ents.FindByClass("prop_ragdoll")) do
				if ent.serverside_ragdoll_disconnected == ply:UniqueID() then
					ply:SetPos(ent:GetPos())
					ply:SetEyeAngles(ent.serverside_ragdoll_eyeangles)
					ent:Remove()
					break
				end
			end
		end)
	end)
end