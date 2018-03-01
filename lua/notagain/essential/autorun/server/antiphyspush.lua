local function IsPlayer(ent)
	return IsValid(ent) and ent:GetClass() == "player" or false
end

local hooks = {
	"PlayerSpawnedEffect",  "PlayerSpawnedNPC",  "PlayerSpawnedProp",
	"PlayerSpawnedRagdoll", "PlayerSpawnedSENT", "PlayerSpawnedSWEP", 
	"PlayerSpawnedVehicle",
}

local function PlayerSpawnedObject(ply, model, ent)
	local ent = ent

	if isentity(model) then
		ent = model
	end

	timer.Simple(0.01, function()
		if IsValid(ent) then
			ent:AddCallback('PhysicsCollide', function(ent, data)
				local ply = data.HitEntity
				local canmove = IsValid(data.PhysObject) and data.PhysObject:IsMotionEnabled() or false

				if canmove then
					if IsPlayer(ply) and ( ply.CanAlter and not ply:CanAlter(ent) ) then
						ent:ForcePlayerDrop()
						ent.PhysgunDisabled = true
						ent.IsPushing = true

						ply:SetVelocity(ply:GetVelocity()*-1)
						ent:SetAbsVelocity(ent:GetAbsVelocity()*-2)

						timer.Simple(FrameTime(), function()
							if IsValid(ply) then
								ply:SetVelocity(ply:GetVelocity()*-1)
							end
						end)

						timer.Simple(FrameTime()*2, function()
							if IsValid(ent) and ent.IsPushing then
								ent:ForcePlayerDrop()
								ent.PhysgunDisabled = nil
								ent.IsPushing = nil
							end
						end)
					end
				end
			end)
		end
	end)
end

for _,h in next, hooks do
	hook.Add(h, "antiphyspush", PlayerSpawnedObject)
end
