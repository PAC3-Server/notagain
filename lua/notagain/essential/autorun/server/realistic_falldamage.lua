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

			if not res.HitWorld and res.Entity:IsValid() then
				local info = DamageInfo()
				info:SetDamagePosition(data:GetOrigin())
				info:SetDamage(dmg)
				info:SetDamageType(DMG_FALL)
				info:SetAttacker(ply)
				info:SetInflictor(ply)
				info:SetDamageForce(ply.fdmg_last_vel)
				res.Entity:TakeDamageInfo(info)
			end

			local z = math.abs(res.HitNormal.z)

			if res.Hit and (z < 0.1 or z > 0.9) then
				local fall_damage = hook.Run("GetFallDamage", ply, len)
				if fall_damage ~= 0 then
					if fall_damage < dmg then
						dmg = dmg - fall_damage
						local pos = data:GetOrigin()
						if hook.Run("RealisticFallDamage", ply, pos, dmg, len, res, params) ~= true then
							local info = DamageInfo()
							info:SetDamagePosition(pos)
							info:SetDamage(dmg)
							info:SetDamageType(DMG_FALL)
							info:SetAttacker(Entity(0))
							info:SetInflictor(Entity(0))
							info:SetDamageForce(ply.fdmg_last_vel)
							ply:TakeDamageInfo(info)
						end
					end
				end
			end
		end
	end

	ply.fdmg_last_vel = vel
end)