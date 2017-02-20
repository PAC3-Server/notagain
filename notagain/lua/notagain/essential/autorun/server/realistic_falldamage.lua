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

			local z = math.abs(res.HitNormal.z)

			if res.Hit and (z < 0.1 or z > 0.9) then
				local fall_damage = hook.Run("GetFallDamage", ply, len)
				if fall_damage ~= 0 then
					local dmg = (len - 500) / 4

					if fall_damage < dmg then
						local info = DamageInfo()
						info:SetDamagePosition(data:GetOrigin())
						info:SetDamage(dmg - fall_damage)
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

	ply.fdmg_last_vel = vel
end)