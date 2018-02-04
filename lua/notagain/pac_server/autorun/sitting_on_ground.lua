if engine.ActiveGamemode() ~= "sandbox" then return end

local tag = "groundSit"

if SERVER then
	concommand.Add("ground_sit", function(ply)
		if not ply.LastSit or ply.LastSit < CurTime() then
			ply:SetNWBool(tag, not ply:GetNWBool(tag))
			ply.LastSit = CurTime() + 1
		end
	end)
end

local sitting = 0
if CLIENT then
	surface.CreateFont(tag, {
		font = "Roboto Bk",
		size = 48,
		weight = 800,
	})

	hook.Add("HUDPaint", tag, function()
		if sitting <= 0 then return end

		local mult = math.min(sitting, 1)

		local txt = "Sitting down..."
		surface.SetFont(tag)
		local txtW, txtH = surface.GetTextSize(txt)
		surface.SetTextPos(ScrW() * 0.5 - txtW * 0.5 + 3, ScrH() * 0.25 + txtW * (0.075 * mult) + 3)
		surface.SetTextColor(Color(0, 0, 0, 127 * mult))
		surface.DrawText(txt)

		surface.SetTextPos(ScrW() * 0.5 - txtW * 0.5, ScrH() * 0.25 + txtW * (0.075 * mult))
		surface.SetTextColor(Color(199 - 64 * mult, 210, 213 - 64 * mult, 192 * mult))
		surface.DrawText(txt)
	end)
end

local time, speed = 1.5, 1.25
hook.Add("SetupMove", tag, function(ply, mv)
	local butts = mv:GetButtons()

	if not ply:GetNWBool(tag) then
		if SERVER then return end

		local walking = bit.band(butts, IN_WALK) == IN_WALK
		local using = bit.band(butts, IN_USE) == IN_USE
		local wantSit = walking and using
		if mv:GetAngles().p >= 80 and wantSit then
			sitting = math.Clamp(sitting + FrameTime() * speed, 0, time)
		else
			sitting = math.Clamp(sitting - FrameTime() * speed, 0, time)
		end
		if sitting >= time then
			ply:ConCommand("ground_sit")
		end

		return
	end

	if CLIENT then
		sitting = math.Clamp(sitting - FrameTime() * speed, 0, time)
	end

	local getUp = bit.band(butts, IN_JUMP) == IN_JUMP or ply:GetMoveType() ~= MOVETYPE_WALK or ply:InVehicle() or not ply:Alive()

	if getUp then
		ply:SetNWBool(tag, false)
	end

	local move = bit.band(butts, IN_DUCK) == IN_DUCK -- do we want to move by ducking

	butts = bit.bor(butts, bit.bor(IN_JUMP, IN_DUCK)) -- enable ducking

	butts = bit.bxor(butts, IN_JUMP) -- disable jumpng

	if move then
		butts = bit.bor(butts, IN_WALK) -- enable walking

		butts = bit.bor(butts, IN_SPEED)
		butts = bit.bxor(butts, IN_SPEED) -- disable sprinting

		mv:SetButtons(butts)
		return
	end

	mv:SetButtons(butts)
	mv:SetSideSpeed(0)
	mv:SetForwardSpeed(0)
	mv:SetUpSpeed(0)
end)

hook.Add("CalcMainActivity", tag, function(ply, vel)
	local seq = ply:LookupSequence("pose_ducking_02")
	if ply:GetNWBool(tag) and seq and vel:Length2DSqr() < 1 then
		return ACT_MP_SWIM, seq
	else
		return
	end
end)
