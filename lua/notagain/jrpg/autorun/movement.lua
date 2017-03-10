hook.Add("CalcMainActivity", "movement", function(ply)
	if not ply:GetNWBool("rpg") then return end
	local vel = ply:GetVelocity()

	if ply:IsOnGround() and vel:Length() > 300 then
		local seq = ply:LookupSequence("run_all_02")
		if seq > 1 then
			return seq, seq
		end
	end
end)

hook.Add("Move", "movement", function(ply, mv)
	if not ply:GetNWBool("rpg") then return end

	ply.movement_smooth_side = ply.movement_smooth_side or 0
	ply.movement_smooth_forward = ply.movement_smooth_forward or 0

	if mv:GetSideSpeed()  == 0 then
		ply.movement_smooth_side = 0
	end

	if mv:GetForwardSpeed()  == 0 then
		ply.movement_smooth_forward = 0
	end

	ply.movement_smooth_side = ply.movement_smooth_side + ((mv:GetSideSpeed() - ply.movement_smooth_side) * FrameTime() / 15)
	ply.movement_smooth_forward = ply.movement_smooth_forward + ((mv:GetForwardSpeed() - ply.movement_smooth_forward) * FrameTime() / 15)

	mv:SetForwardSpeed(ply.movement_smooth_forward)
	mv:SetSideSpeed(ply.movement_smooth_side)

	if jattributes.HasStamina(ply) and jattributes.GetStamina(ply) == 0 then
		local speed = ply:GetWalkSpeed()
		mv:SetForwardSpeed(math.Clamp(mv:GetForwardSpeed(), -speed, speed))
		mv:SetSideSpeed(math.Clamp(mv:GetSideSpeed(), -speed, speed))
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

	hook.Add("UpdateAnimation", "movement", function(ply)
		if not ply:GetNWBool("rpg") then return end
		local ang = ply:EyeAngles()
		local vel = ply:GetVelocity()

		local dot = ang:Right():Dot(vel)

		if ang:Forward():Dot(vel) > 200 then
			manip_angles(ply, 0, Angle(0,dot*-0.15,0))
		else
			manip_angles(ply, 0, Angle(0,0,0))
		end
	end)
end

if SERVER then
	hook.Add("PlayerLoadout", "movement", function(ply)
		if not ply:GetNWBool("rpg") then return end
		ply:SetRunSpeed(300)
	end)
end