hook.Add("Move", "movement", function(ply, mv)
	if not jrpg.IsEnabled(ply) then return end

	ply.movement_smooth_side = ply.movement_smooth_side or 0
	ply.movement_smooth_forward = ply.movement_smooth_forward or 0

	local side = mv:GetSideSpeed()
	local forward = mv:GetForwardSpeed()

	side = math.Clamp(side, -500, 500)
	forward = math.Clamp(forward, -500, 500)

	do -- drunk
		local hp = ply:GetNWFloat("hp_overload", 0)
		local mp = ply:GetNWFloat("mp_overload", 0)
		local sp = ply:GetNWFloat("sp_overload", 0)

		local factor = hp+mp+sp

		if factor > 10 then
			local p = mv:GetOrigin()/1000
			forward = forward + math.sin(os.clock()+p.x) * factor * 10000
			side = side + math.cos(os.clock()+p.y) * factor * 10000
		end
	end


	--[[
	if ply == me then
		if mv:GetForwardSpeed() == 0 and mv:GetSideSpeed() == 0 and ply.movement_cooldown_done then
			ply.movement_startup = nil
			ply.movement_cooldown = ply.movement_cooldown or CurTime() + 1
			local time = math.max(ply.movement_cooldown - CurTime(), 0)

			if time ~= 0 then
				mv:SetForwardSpeed(ply.movement_last_forward * time)
				mv:SetSideSpeed(ply.movement_last_side * time)
				ply.movement_cooldown_done = true
			end
		else
			ply.movement_cooldown_done = true
			ply.movement_cooldown = nil
			ply.movement_startup = ply.movement_startup or CurTime()
			local time = math.min(CurTime() - ply.movement_startup, 1)
			mv:SetMaxClientSpeed(time * 500)

			ply.movement_last_side = side
			ply.movement_last_forward = forward
		end

		return
	end

	mv:SetForwardSpeed(forward)
	mv:SetSideSpeed(side)
	]]

	if jattributes.HasStamina(ply) and jattributes.GetStamina(ply) == 0 or ply:GetNWBool("drinking_potion") then
		local speed = ply:GetWalkSpeed()
		mv:SetForwardSpeed(math.Clamp(forward, -speed, speed))
		mv:SetSideSpeed(math.Clamp(side, -speed, speed))
		local wep = ply:GetActiveWeapon()
		if wep:IsValid() then
			wep:SetNextPrimaryFire(CurTime() + 0.1)
			wep:SetNextSecondaryFire(CurTime() + 0.1)
		end
	end
end)