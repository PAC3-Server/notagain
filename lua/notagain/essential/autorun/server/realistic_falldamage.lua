local function GetFallDamage(ply, len)
	ply.fdmg_read = true
	return hook.Run("GetFallDamage", ply, len) 
end

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
				local fall_damage = GetFallDamage(ply, len) -- Prepare Override & Check Expected Fall Damage
				if fall_damage <= 0 then return end

				local pos = data:GetOrigin()
				local info = DamageInfo()
				info:SetDamagePosition(pos)
				info:SetDamage(dmg)
				info:SetDamageType(DMG_FALL)
				info:SetAttacker(Entity(0))
				info:SetInflictor(Entity(0))
				info:SetDamageForce(ply.fdmg_last_vel)

				if hook.Run("RealisticFallDamage", ply, info, len, dmg, fall_damage, res, params) ~= true then
					ply:TakeDamageInfo(info)
				end
			end
		end
	end

	ply.fdmg_last_vel = vel
end)

hook.Add("EntityTakeDamage", "realistic_falldamage", function(ply, di)
	if di:IsFallDamage() then
		if ply.fdmg_read then
			ply.fdmg_read = nil
		else
			return true
		end
	end
end)
