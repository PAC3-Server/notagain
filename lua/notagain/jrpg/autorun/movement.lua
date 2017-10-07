hook.Add("CalcMainActivity", "movement", function(ply)
	if not ply:GetNWBool("rpg") then return end
	local vel = ply:GetVelocity()

	if ply:IsOnGround() then
		if vel:Length() > 300 then
			local seq = ply:LookupSequence("run_all_02")
			if seq > 1 then
				return seq, seq
			end
		end
	else
		ply.m_bJumping = true
		ply.m_flJumpStartTime = 0
		ply.m_fGroundTime = 0

		if ply:Crouching() then
			local holdtype = "all"
			local wep = ply:GetActiveWeapon()

			if wep:IsValid() then
				holdtype = wep:GetHoldType()
			end

			-- airduck
			local seq = ply:LookupSequence("cidle_" .. holdtype)
			if seq < 1 then seq = ply:LookupSequence("cidle_all") end

			if seq > 1 then
				return seq, seq
			end
		elseif vel:Length() > 750 then
			ply:SetCycle(0.57)

			local holdtype = "all"
			local wep = ply:GetActiveWeapon()

			if wep:IsValid() then
				holdtype = wep:GetHoldType()
			end

			local seq = ply:LookupSequence("swimming_" .. holdtype)

			if seq < 1 then
				seq = ply:LookupSequence("swimming_all")
			end

			return -1, seq
		end
	end
end)

hook.Add("Move", "movement", function(ply, mv)
	if not ply:GetNWBool("rpg") then return end

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

if CLIENT then

	local function manip_angles(ply, id, ang)
		if pac then
			pac.ManipulateBoneAngles(ply, id, ang)
		else
			ply:ManipulateBoneAngles(id, ang)
		end
	end

	local function manip_pos(ply, id, pos)
		if pos:IsZero() then
			ply:DisableMatrix("RenderMultiply")
			return
		end

		local m = Matrix()
		m:Translate(pos)
		ply:EnableMatrix("RenderMultiply", m)
	end

	local function calc_duck(ply)
		if ply:Crouching() then
			if not ply.airduck_crouched then
				ply.airduck_duck_time = CurTime() + ply:GetDuckSpeed()
				ply.airduck_crouched = true
				ply.airduck_reset_duck = false
			end
		else
			if ply.airduck_crouched then
				ply.airduck_unduck_time = CurTime() + ply:GetUnDuckSpeed()
				ply.airduck_crouched = false
				ply.airduck_reset_unduck = false
			end
		end

		local duck_lerp
		local unduck_lerp

		if ply.airduck_duck_time then
			local f = ply.airduck_duck_time - CurTime()
			if f >= 0 then
				duck_lerp = f * (1/ply:GetDuckSpeed())
			end
		end

		if ply.airduck_unduck_time then
			local f = ply.airduck_unduck_time - CurTime()
			if f >= 0 then
				unduck_lerp = f * (1/ply:GetUnDuckSpeed())
			end
		end

		if not ply:IsOnGround() then
			if duck_lerp and ply:Crouching() then
				local _, max = ply:GetHullDuck()
				manip_pos(ply, 0, Vector(0,0,max.z*-duck_lerp+1))
			elseif unduck_lerp and not ply:Crouching() then
				local _, max = ply:GetHullDuck()
				manip_pos(ply, 0, Vector(0,0,max.z*unduck_lerp))
			end
		end

		if not duck_lerp then
			if not ply.airduck_reset_duck then
				manip_pos(ply, 0, Vector(0,0,0))
				ply.airduck_reset_duck = true
			end
		end

		if not unduck_lerp then
			if not ply.airduck_reset_unduck then
				manip_pos(ply, 0, Vector(0,0,0))
				ply.airduck_reset_unduck = true
			end
		end
	end

	hook.Add("UpdateAnimation", "movement", function(ply)
		if not ply:GetNWBool("rpg") then return end

		if ply:OnGround() then
			local ang = ply:EyeAngles()
			local vel = ply:GetVelocity()

			local dot = ang:Right():Dot(vel)

			if ang:Forward():Dot(vel) > 200 then
				manip_angles(ply, 0, Angle(0,math.Clamp(dot*-0.15, -15, 15),0))
			else
				manip_angles(ply, 0, Angle(0,0,0))
			end
		else
			manip_angles(ply, 0, Angle(0,0,0))
		end


		local vel = ply:GetVelocity()
		if not ply:IsOnGround() and vel:Length() > 750 then
			ply:SetPoseParameter("move_x", vel:Dot(ply:GetForward())/1000)
			ply:SetPoseParameter("move_y", vel:Dot(ply:GetRight())/1000)
		end

		return calc_duck(ply)
	end)
end

if SERVER then
	hook.Add("PlayerLoadout", "movement", function(ply)
		if ply:GetNWBool("rpg",false) then
			ply:SetRunSpeed(300)
			ply:SetDuckSpeed(0.5)
			ply:SetUnDuckSpeed(0.5)
		end
	end)
end
