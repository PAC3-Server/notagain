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

if CLIENT then
	net.Receive("serverside_ragdoll", function()
		local b = net.ReadBool()
		if b then
			hook.Add("CalcView", "serverside_ragdoll", function(ply, origin, angles)
				local ent = ply:GetNWEntity("serverside_ragdoll")
				if ent:IsValid() then
					ent.serverside_ragdoll_origin = ent.serverside_ragdoll_origin or origin
					local pos = ent.serverside_ragdoll_origin
					local dir = ent:GetPos() - pos
					local dist = dir:Length()

					return {
						origin = pos,
						angles = dir:Angle(),
						fov = math.max((-math.min(dist / 1000, 1)+1) * 70, 5)
					}
				else
					ent.serverside_ragdoll_origin = nil
				end
			end, -100)
		else
			hook.Remove("CalcView", "serverside_ragdoll")
		end
	end)
end

if SERVER then
	util.AddNetworkString("serverside_ragdoll")

	hook.Add("DoPlayerDeath", "serverside_ragdoll", function(ply, attacker, dmginfo)
		if not dmginfo:GetDamageForce():IsZero() then
			local force = dmginfo:GetDamageForce()
			local length = force:Length()
			force:Normalize()

			ply.serverside_ragdoll_vel = force * math.min(length, 500)
		end
	end)

	hook.Add("PlayerDeath", "serverside_ragdoll", function(ply)
		SafeRemoveEntity(ply:Old_GetRagdollEntity())

		for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
			if ent:GetOwner() == ply then
				ent:Remove()
			end
		end

		timer.Simple(0.1, function() 
			if ply:IsValid() then 
				ply:SetMoveType(MOVETYPE_FLYGRAVITY) 
			end 
		end) --0 does weird things

		
		hook.Add("OnEntityCreated", "serverside_ragdoll", function(ent)
			hook.Remove("OnEntityCreated", "serverside_ragdoll")
			if not ply:IsValid() then return end
			if ent:GetClass() ~= "prop_ragdoll" then print("not a ragdoll") return end
			timer.Simple(0, function() 
				if not ent:IsValid() then print("no longer valid") return end
				if ent:GetPos():Distance(ply:WorldSpaceCenter()) > 10 then print("ragdoll too far away") return end

				if ent.CPPISetOwner then
					ent:CPPISetOwner(ply)
				end
				ply:SetNWEntity("serverside_ragdoll", ent)
				for i = 1, ent:GetPhysicsObjectCount() - 1 do
					local phys = ent:GetPhysicsObjectNum(i)
					phys:SetVelocity(ply.serverside_ragdoll_vel or ply:GetVelocity())
				end
				net.Start("serverside_ragdoll")
					net.WriteBool(true)
				net.Send(ply)
				ply.serverside_ragdoll_vel = nil
			end)
		end)
	end)

	hook.Add("PlayerSpawn", "serverside_ragdoll", function(ply)
		for _, ent in pairs(ents.FindByClass("prop_ragdoll")) do
			if ent:GetOwner() == ply then
				ent:Remove()
			end
		end
		ply:SetShouldServerRagdoll(true)
		net.Start("serverside_ragdoll")
			net.WriteBool(false)
		net.Send(ply)
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