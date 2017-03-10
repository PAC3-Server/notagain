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

	local side = mv:GetSideSpeed()
	local forward = mv:GetForwardSpeed()

	if side  == 0 then
		ply.movement_smooth_side = 0
	elseif (side > 0 and ply.movement_smooth_side < 0) or (side < 0 and ply.movement_smooth_side > 0) then
		ply.movement_smooth_side = 0
	end

	if forward == 0 then
		ply.movement_smooth_forward = 0
	elseif (forward > 0 and ply.movement_smooth_forward < 0) or (forward < 0 and ply.movement_smooth_forward > 0) then
		ply.movement_smooth_forward = 0
	end

	do
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

	ply.movement_smooth_side = ply.movement_smooth_side + ((side - ply.movement_smooth_side) * FrameTime() / 5)
	ply.movement_smooth_forward = ply.movement_smooth_forward + ((forward - ply.movement_smooth_forward) * FrameTime() / 5)

	mv:SetForwardSpeed(ply.movement_smooth_forward)
	mv:SetSideSpeed(ply.movement_smooth_side)

	if jattributes.HasStamina(ply) and jattributes.GetStamina(ply) == 0 or ply:GetNWBool("drinking_potion") then
		local speed = ply:GetWalkSpeed()
		mv:SetForwardSpeed(math.Clamp(ply.movement_smooth_forward, -speed, speed))
		mv:SetSideSpeed(math.Clamp(ply.movement_smooth_side, -speed, speed))
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