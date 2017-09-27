local speed = 1
local threshold = 30

local roll_time = 0.75/speed
local roll_speed = 1*speed
local function is_rolling(ply)
	if CLIENT and ply ~= LocalPlayer() then
		return ply:GetNW2Float("roll_time", CurTime()) > CurTime()
	end
	return ply.roll_time and ply.roll_time > CurTime()
end

local function vel_to_dir(ang, vel)
	ang.p = 0
	local dot = ang:Forward():Dot(vel)
	if dot > 100*roll_speed then
		return "forward"
	elseif dot < -100*roll_speed then
		return "backward"
	end

	local dot = ang:Right():Dot(vel)
	if dot > 0 then
		return "right"
	else
		return "left"
	end
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
	return (ply:IsValid() and ply:GetNWBool("rpg") and not is_rolling(ply) and ply:Alive() and ply:OnGround() and ply:GetMoveType() == MOVETYPE_WALK and not ply:InVehicle()) or ply.roll_landed
end

hook.Add("UpdateAnimation", "roll", function(ply, velocity)
	if velocity:Length2D() < threshold then
		ply.roll_time = nil
		return
	end

	if is_rolling(ply) then
		local dir = vel_to_dir(ply:EyeAngles(), velocity)

		if dir == "forward" or dir == "backward" then
			ply.roll_back_cycle = (ply.roll_back_cycle or 0) + (ply:GetVelocity():Length() * FrameTime() / 275)
		else
			ply.roll_back_cycle = (ply.roll_back_cycle or 0) + (ply:GetVelocity():Length() * FrameTime() / 275)
		end

		local f = math.Clamp(ply.roll_back_cycle*(1/roll_time)/roll_speed,0,1)

		if dir == "forward" then
			ply:SetCycle(Lerp(f, 0.1, 0.9))
		elseif dir == "backward" then
			ply:SetCycle(Lerp(f, 0.9, 0))
		elseif dir == "left" or dir == "right" then
			ply:SetCycle(Lerp(f, 0.25, 1))
		end

		ply:SetPlaybackRate(0)

		return true
	else
		ply.roll_back_cycle = nil
	end
end)

hook.Add("OnPlayerHitGround", "roll", function(ply)
	if ply:KeyDown(IN_DUCK)	then
		ply.roll_landed = true
	end
end)

hook.Add("CalcMainActivity", "roll", function(ply)
	if ply:GetVelocity():Length2D() < threshold then
		return
	end

	if is_rolling(ply) then
		local dir = vel_to_dir(ply:EyeAngles(), ply:GetVelocity())

		local seq = ""

		if dir == "forward" or dir == "backward" then
			seq = "roll_forward"
		elseif dir == "left" then
			seq = "roll_left"
		elseif dir == "right" then
			seq = "roll_right"
		end

		local seqid = ply:LookupSequence(seq)

		if seqid > 1 then
			return seqid, seqid
		end
	end
end)

hook.Add("Move", "roll", function(ply, mv, ucmd)
	if not ply:GetNWBool("rpg") then return end

	--[[local landed

	if not ply:OnGround() then
		ply.roll_in_air = CurTime()
	else
		local diff = (CurTime() - ply.roll_in_air)

		if diff > 0 and diff < 0.1 then
			landed = true
		end
	end
	]]

	if can_roll(ply) then
		if mv:KeyPressed(IN_DUCK) or ply.roll_landed then

			ply.roll_landed = nil

			local stamina = jattributes.GetStamina(ply)
			if stamina < 30 then return end

			if mv:KeyDown(IN_BACK) or mv:KeyDown(IN_MOVELEFT) or mv:KeyDown(IN_MOVERIGHT) or mv:KeyDown(IN_FORWARD) then
				ply.roll_ang = mv:GetAngles()
				ply.roll_time = CurTime() + roll_time
			end

			if ply.roll_time then
				if mv:GetForwardSpeed() > 0 then
					ply.roll_dir = "forward"
				elseif mv:GetForwardSpeed() < 0 then
					ply.roll_dir = "backward"
				end

				if not ply.roll_dir then
					if mv:GetSideSpeed() > 0 then
						ply.roll_dir = "right"
					else
						ply.roll_dir = "left"
					end
				end

				ply:AnimRestartMainSequence()

				if SERVER then
					ply:SetNW2Float("roll_time", ply.roll_time)

					jattributes.SetStamina(ply, stamina - 15)
				end
			end
		else
			ply.roll_ang = nil
			ply.roll_time = nil
			ply.roll_dir = nil
		end
	end

	if is_rolling(ply) and mv:GetVelocity():Length2D() > 30 then
		local dir

		local ang = ply.roll_ang * 1
		ang.p = 0

		local dir = ply.roll_dir
		local f = math.Clamp((ply.roll_time - CurTime()) * (1/roll_time), 0, 1)

		local mult = (math.sin(f*math.pi) + 0.5) * roll_speed

		mv:SetMaxSpeed(200*mult)
		mv:SetMaxClientSpeed(200*mult)

		if dir == "forward" then
			mv:SetForwardSpeed(10000)
		elseif dir == "backward" then
			mv:SetForwardSpeed(-10000)
		elseif dir == "left" then
			mv:SetSideSpeed(-10000)
		elseif dir == "right" then
			mv:SetSideSpeed(10000)
		end
	else
		ply.roll_forward_speed = nil
		ply.roll_side_speed = nil
	end
end)


