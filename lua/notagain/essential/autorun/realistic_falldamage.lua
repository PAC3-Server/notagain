hook.Add("Move", "realistic_falldamage", function(ply, data)
	local vel = data:GetVelocity()

	if ply.fdmg_last_vel and ply:GetMoveType() == MOVETYPE_WALK then
		local diff = vel - ply.fdmg_last_vel
		local len = diff:Length()

		if len > 500 then
			local params = {}
			params.start = data:GetOrigin() + ply:OBBCenter()
			params.endpos = params.start - diff:GetNormalized() * ply:BoundingRadius()
			params.filter = ply
			params.mins = ply:OBBMins()
			params.maxs = ply:OBBMaxs()
			local res = util.TraceHull(params)

			local dmg = (len - 500) / 4
			local z = math.abs(res.HitNormal.z)

			if res.Hit and (z < 0.1 or z > 0.9) then
				local fall_damage = hook.Run("GetFallDamage", ply, len) or 1 -- Prepare Override & Check Expected Fall Damage

				if fall_damage > 0 then
					dmg = math.max(dmg, 0)

					local world = game.GetWorld()
					local pos = data:GetOrigin()
					local info = DamageInfo()

					info:SetDamagePosition(pos)
					info:SetDamage(dmg)
					info:SetDamageType(DMG_FALL)
					info:SetAttacker(world)
					info:SetInflictor(world)
					info:SetDamageForce(ply.fdmg_last_vel)

					if hook.Run("RealisticFallDamage", ply, info, len, fall_damage, res, params, data) ~= true then
						
						if SERVER then
							ply:TakeDamageInfo(info)
						end

						hook.Run("PostRealisticFallDamage", ply, info, len, fall_damage, res, params, data)
					end
				end
			end
		end
	end

	ply.fdmg_last_vel = vel
end)

if SERVER then
	--- Supress Engine Fall Damage

	hook.Add("EntityTakeDamage", "realistic_falldamage", function(ply, dmginfo)
		if dmginfo:IsFallDamage() then
			local dbug = debug.getinfo(3)
			if (not dbug) or dbug.what ~= "C" then
				return true
			end
		end
	end)
end