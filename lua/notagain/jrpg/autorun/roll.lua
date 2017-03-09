local function is_rolling(ply)
	if CLIENT and ply ~= LocalPlayer() then
		return ply:GetNW2Float("roll_time", CurTime()) > CurTime()
	end
	return ply.roll_time and ply.roll_time > CurTime()
end

if SERVER then
	util.AddNetworkString("roll")

	hook.Add("EntityTakeDamage", "roll", function(ent, dmginfo)
		if is_rolling(ent) and (bit.band(dmginfo:GetDamageType(), DMG_CRUSH) > 0 or bit.band(dmginfo:GetDamageType(), DMG_SLASH) > 0) then
			dmginfo:ScaleDamage(0)
			ent:ChatPrint("dodge!")
			return true
		end
	end)
end

if CLIENT then
	hook.Add("CalcView", "roll", function(ply, pos, ang)
		if is_rolling(ply) and ply:Alive() and not ply:InVehicle() and not ply:ShouldDrawLocalPlayer() then
			local eyes = ply:GetAttachment(ply:LookupAttachment("eyes"))

			return {
				origin = eyes.Pos,
				angles = eyes.Ang,
			}
		end
	end)

	hook.Add("CalcViewModelView", "roll", function(wep, viewmodel, oldEyePos, oldEyeAngles, eyePos, eyeAngles)
		if not wep or not wep:IsValid() then return end
		local ply = LocalPlayer()

		if is_rolling(ply) and ply:Alive() and not ply:InVehicle() and not ply:ShouldDrawLocalPlayer() then
			local eyes = ply:GetAttachment(ply:LookupAttachment("eyes"))

			return eyes.Pos, eyes.Ang
		end
	end)
end

local function can_roll(ply)
	return ply:IsValid() and ply:GetNWBool("rpg") and not is_rolling(ply) and ply:Alive() and ply:OnGround() and ply:GetMoveType() == MOVETYPE_WALK and not ply:InVehicle()
end

hook.Add("UpdateAnimation", "roll", function(ply, velocity)
	if is_rolling(ply) then
		ply.roll_back_cycle = (ply.roll_back_cycle or 0) + FrameTime()

		if ply.roll_dir == "forward" then
			ply:SetCycle(ply.roll_back_cycle)
		elseif ply.roll_dir == "backward" then
			if ply.roll_back_cycle > 1 then
				ply:SetCycle(0)
			else
				ply:SetCycle(math.max((-ply.roll_back_cycle+1)-0.1, 0))
			end
		elseif ply.roll_dir == "left" or ply.roll_dir == "right" then
			ply:SetCycle((ply.roll_back_cycle * 0.8) + 0.15)
		end

		if ply.roll_back_cycle then
			local dir = ply.roll_dir
			if
				(dir == "forward" and ply.roll_back_cycle < 0.8) or
				(dir == "backward" and ply.roll_back_cycle < 1.1) or
				((dir == "left" or dir == "right") and ply.roll_back_cycle < 1)
			then
				return true
			end
		end
	else
		ply.roll_back_cycle = nil
	end
end)

hook.Add("CalcMainActivity", "roll", function(ply)
	if is_rolling(ply) then

		if ply.roll_back_cycle then
			local dir = ply.roll_dir
			if dir == "forward" and ply.roll_back_cycle > 0.8 then
				return
			elseif dir == "backward" and ply.roll_back_cycle > 1.1 then
				return
			elseif (dir == "left" or dir == "right") and ply.roll_back_cycle > 1 then
				return
			end
		end

		local seq = ""
		if ply.roll_dir == "forward" or ply.roll_dir == "backward" then
			seq = "roll_forward"
		elseif ply.roll_dir == "left" then
			seq = "roll_left"
		elseif ply.roll_dir == "right" then
			seq = "roll_right"
		end

		local seqid = ply:LookupSequence(seq)

		if seqid > 1 then
			return seqid, seqid
		end

	end
end)

hook.Add("Move", "roll", function(ply, mv, ucmd)
	if can_roll(ply) then
		if mv:KeyPressed(IN_DUCK) then

			if mv:KeyDown(IN_BACK) then
				ply.roll_dir = "backward"
				ply.roll_time = CurTime() + 0.9
			elseif mv:KeyDown(IN_MOVELEFT) then
				ply.roll_dir = "left"
				ply.roll_time = CurTime() + 0.8
			elseif mv:KeyDown(IN_MOVERIGHT) then
				ply.roll_dir = "right"
				ply.roll_time = CurTime() + 0.8
			elseif mv:KeyDown(IN_FORWARD) then
				ply.roll_dir = "forward"
				ply.roll_time = CurTime() + 0.9
			end

			if ply.roll_time then
				ply:AnimRestartMainSequence()

				if SERVER then
					ply:SetNW2Float("roll_time", ply.roll_time)
				end
			end
		else
			ply.roll_dir = nil
			ply.roll_time = nil
		end
	end

	if is_rolling(ply) then
		local dir
		local ang = mv:GetAngles()

		if ply.roll_dir == "forward" then
			dir = ang:Forward()*300
		elseif ply.roll_dir == "backward" then
			dir = ang:Forward()*-300
		elseif ply.roll_dir == "left" then
			dir = ang:Right()*-300
		elseif ply.roll_dir == "right" then
			dir = ang:Right()*300
		end

		if dir then
			mv:SetVelocity(dir)
		end
	end
end)


