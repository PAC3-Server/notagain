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
	hook.Add("PlayerDeath", "serverside_ragdoll", function(ply)
		SafeRemoveEntity(ply:GetRagdollEntity())
		for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
			if ent:GetOwner() == ply then
				ent:Remove()
			end
		end

		timer.Simple(0.1, function()
			for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
				if ent:GetOwner() == ply then
					ply:SetNWEntity("serverside_ragdoll", ent)
					break
				end
			end
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
		SafeRemoveEntity(ply:GetNWEntity("serverside_ragdoll"))
	end)
end