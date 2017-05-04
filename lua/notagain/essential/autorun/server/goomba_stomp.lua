local function bounce(ent,vel)
	timer.Simple(0, function() -- Attempted Multiple Methods, this one seems to work the best.
		if not IsValid(ent) then return end
		ent:SetVelocity(Vector(vel.x,vel.y,vel.z*-0.7))
	end)
end

hook.Add("RealisticFallDamage", "goomba_stomp", function(ply, info, dmg, _, _, trace)
	local vel = ply.fdmg_last_vel or info:GetDamageForce()
	if trace.HitNormal.z == 1 and vel.z < 0 then
		if not trace.HitWorld and IsValid(trace.Entity) then
			trace.Entity.fdmg_read = true -- Sadly due to the nature of our modifications we have to apply this variable.

			local info = DamageInfo()
			info:SetDamagePosition(tr.HitPos)
			info:SetDamage(dmg)
			info:SetDamageType(DMG_FALL)
			info:SetAttacker(ply)
			info:SetInflictor(ply)
			info:SetDamageForce(vel)
			tr.Entity:TakeDamageInfo(info)

			local sndindex = math.random(0,7)
			ply:EmitSound("phx/epicmetal_hard"..(sndindex == 0 and "" or sndindex)..".wav", 45, 100) -- Play a funny sound when we stomp somone!

			bounce(ply,vel)
			return true
		end
	end
end)
