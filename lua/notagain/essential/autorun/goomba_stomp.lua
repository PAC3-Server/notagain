hook.Add("RealisticFallDamage", "goomba_stomp", function(ply, info, _, _, trace,_, mov)
	local vel = ply.fdmg_last_vel or info:GetDamageForce()
	if trace.HitNormal.z == 1 and vel.z < 0 then
		if not trace.HitWorld and IsValid(trace.Entity) then

			if SERVER then
				local info = DamageInfo()
				info:SetDamagePosition(trace.HitPos)
				info:SetDamage(info:GetDamage())
				info:SetDamageType(DMG_CRUSH)
				info:SetAttacker(ply)
				info:SetInflictor(ply)
				info:SetDamageForce(vel)
				trace.Entity:TakeDamageInfo(info)
			end

			local sndindex = math.random(0,7)
			ply:EmitSound("phx/epicmetal_hard"..(sndindex == 0 and "" or sndindex)..".wav", 45, 100) -- Play a funny sound when we stomp somone!

			mov:SetVelocity(mov:GetVelocity() + Vector(vel.x,vel.y,vel.z*-0.7))
			
			return true
		end
	end
end)
