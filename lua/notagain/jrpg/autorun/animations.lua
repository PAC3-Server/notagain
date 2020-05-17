do
	local META = FindMetaTable("Weapon")
	META.jrpg_GetHoldType = META.jrpg_GetHoldType or META.GetHoldType

	function META:GetHoldType(...)
		if type(self:GetOwner().jrpg_holdtype) == "string" then
			return self:GetOwner().jrpg_holdtype
		end
		return META.jrpg_GetHoldType(self, ...)
	end
end

function jrpg.PlayGestureAnimation(ent, info)
	ent.jrpg_gesture_animations = ent.jrpg_gesture_animations or {}

--	if SERVER then
		ent.jrpg_gesture_animations = {}
--	end

	local data = {}
	data.seq = ent:LookupSequence(info.seq)
	data.start = info.start or 0
	data.stop = info.stop or 1
	data.speed = info.speed or 0
	data.slot = info.slot or math.Clamp(#ent.jrpg_gesture_animations, 0, 1)
	data.duration = ent:SequenceDuration(data.seq)
	data.weight = info.weight or 1
	data.callback = info.callback
	data.done = info.done

	data.time = CurTime() + (data.duration / data.speed)

	table.insert(ent.jrpg_gesture_animations, data)
end

local function calc_gesture_animations(ply)
	for i = #ply.jrpg_gesture_animations, 1, -1 do
		local data = ply.jrpg_gesture_animations[i]

		if data.speed_mult then
			data.time = data.time - FrameTime() * data.speed_mult
		end

		local f = (data.time - (data.frozen_time or CurTime())) / (data.duration / data.speed)

		if f > 0 and f <= 1 then
			local f = -f + 1

			local res = data.callback and data.callback(f,data)
			if res then
				data.frozen_time = data.frozen_time or CurTime()
				f = res
			elseif data.frozen_time then
				data.time = CurTime() - (data.frozen_time - data.time)
				data.frozen_time = nil
			end

			ply:SetPlaybackRate(0)
			ply:AddVCDSequenceToGestureSlot(data.slot, data.seq, Lerp(f, data.start, data.stop), true)

			local weight = math.EaseInOut(f, 0, 1)
			if weight > 0.5 then
				weight = -weight + 1
			end
			weight = math.Clamp(weight * 4, 0, 1)
			weight = weight ^ 0.4
			weight = weight * data.weight

			ply:AnimSetGestureWeight(data.slot, weight)
		end

		if f <= 0 then
			table.remove(ply.jrpg_gesture_animations, i)
			if data.done then
				data.done(f)
			end
		end
	end
		--local fade = (math.sin(f*math.pi) * 2 - 1) * 0.5 + 0.5
		--ply:AnimSetGestureWeight(info.slot, fade)
end

local function manip_angles(ply, id, ang)
	if CLIENT then
		ply:InvalidateBoneCache()
	end
	if pac and pac.ManipulateBoneAngles then
		pac.ManipulateBoneAngles(ply, id, ang)
	else
		ply:ManipulateBoneAngles(id, ang)
	end
end

hook.Add("HandlePlayerJumping", "movement", function(ply)

end)

hook.Add("CalcMainActivity", "movement", function(ply)
	if not jrpg.IsEnabled(ply) then return end
	if jrpg.IsActorRolling(ply) or jrpg.IsActorDodging(ply) then return end

	local vel = ply:GetVelocity()

	if ply:IsOnGround() then
		local id = ply:LookupBone("ValveBiped.Bip01_Spine1")

		if id and vel:Length() > 175 then
			ply.sprint_lean = ply.sprint_lean or CurTime() + 2

			if ply.sprint_lean > CurTime() then
				local lean = (ply.sprint_lean - CurTime()) / 2
				lean = math.sin((lean^2)*math.pi)*30
				ply.jrpg_last_sprint_lean = lean
				manip_angles(ply, id, Angle(0, lean, 0))
			end

			local seq = ply:LookupSequence("run_all_02")
			if seq > 1 then
				return seq, seq
			end
		else
			if ply.jrpg_jumped then
				local seq = ply:LookupSequence("wos_bs_shared_jump_land")
				if seq > 1 then
					ply:SetSequence(seq)
				end
				ply.jrpg_jumped = false
			end

			if ply.sprint_lean then
				if ply.jrpg_last_sprint_lean then
					ply.jrpg_sprint_lean_fadeout = ply.jrpg_sprint_lean_fadeout or CurTime() + 1
					local f = ply.jrpg_sprint_lean_fadeout - CurTime()
					f = math.Clamp(f, 0, 1) ^ 5
					manip_angles(ply, id, Angle(0, ply.jrpg_last_sprint_lean * f, 0))
					if f == 0 then
						manip_angles(ply, id, Angle(0, 0, 0))
						ply.sprint_lean = nil
						ply.jrpg_sprint_lean_fadeout = nil
						ply.jrpg_last_sprint_lean = nil
					end
				end
			end
		end
	else
		ply.m_bJumping = true
		ply.m_flJumpStartTime = 0
		ply.m_fGroundTime = 0

		local holdtype = "all"
		local wep = ply:GetActiveWeapon()

		if wep:IsValid() then
			holdtype = wep:GetHoldType()
		end

		if ply:Crouching() then
			-- airduck
			local seq = ply:LookupSequence("cidle_" .. holdtype)
			if seq < 1 then seq = ply:LookupSequence("cidle_all") end

			if seq > 1 then
				return seq, seq
			end
		elseif vel:Length() > 750 then
			ply:SetCycle(0.57)

			local seq = ply:LookupSequence("swimming_" .. holdtype)

			if seq < 1 then
				seq = ply:LookupSequence("swimming_all")
			end

			return -1, seq
		else
			local seq = ply:LookupSequence("wos_bs_shared_jump")

			ply.jrpg_jumped = true

			if seq > 1 then
				--return seq, seq
			end
		end
	end
end)

local function manip_origin(ply, pos)
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
			manip_origin(ply, Vector(0,0,max.z*-duck_lerp+1))
		elseif unduck_lerp and not ply:Crouching() then
			local _, max = ply:GetHullDuck()
			manip_origin(ply, Vector(0,0,max.z*unduck_lerp))
		end
	end

	if not duck_lerp then
		if not ply.airduck_reset_duck then
			manip_origin(ply, Vector(0,0,0))
			ply.airduck_reset_duck = true
		end
	end

	if not unduck_lerp then
		if not ply.airduck_reset_unduck then
			manip_origin(ply, Vector(0,0,0))
			ply.airduck_reset_unduck = true
		end
	end
end

local function manip_pos(ply, id, pos)
	if pac and pac.ManipulateBonePosition then
		pac.ManipulateBonePosition(ply, id, pos)
	else
		ply:ManipulateBonePosition(id, pos)
	end
end


local find = {
	"wos_bs_",
	"phalanx_",
	"ryoku_",
	"vanguard_",
}

local translate = {
	["ValveBiped.Bip01_Spine"] = Vector(0,1.25,0),
	["ValveBiped.Bip01_Spine1"] = Vector(-1,1,0),
	["ValveBiped.Bip01_Spine4"] = Vector(-1,0,0),
	["ValveBiped.Bip01_R_Clavicle"] = Vector(1, 0, 1),
	["ValveBiped.Bip01_L_Clavicle"] = Vector(1, 0, -1),
	["ValveBiped.Bip01_L_UpperArm"] = Vector(-1,0,0),
	["ValveBiped.Bip01_R_UpperArm"] = Vector(-1,0,0),

}

local function reset_pose(ply)
	if ply.jrpg_female_anim then
		for k,v in pairs(translate) do
			manip_pos(ply, ply:LookupBone(k), Vector(0,0,0))
		end
		ply.jrpg_female_anim = nil
	end
end

local function male2female_animations(ply)
	if jrpg.GetGender(ply) ~= "female" then
		reset_pose(ply)
		return
	end

	--[[if not ply:KeyDown(IN_DUCK) then
		ply:SetSequence(ply:LookupSequence("reference"))
		ply:AddVCDSequenceToGestureSlot(0, ply:LookupSequence("reference"), 0, true)
		ply:AnimSetGestureWeight(0, 1)
		reset_pose(ply)
	else
		ply:SetSequence(ply:LookupSequence("wos_phalanx_reference"))
		ply:AddVCDSequenceToGestureSlot(0, ply:LookupSequence("wos_phalanx_reference"), 0, true)
		ply:AnimSetGestureWeight(0, 1)
	end]]

	local seq = ply:GetSequence()
	local name = ply:GetSequenceName(seq)

	if name then
		local ok = false
		for _, str in ipairs(find) do
			if name:find(str, nil, true) then
				ok = true
				break
			end
		end

		if not ok and ply.jrpg_gesture_animations then
			for _, info in ipairs(ply.jrpg_gesture_animations) do
				local name = ply:GetSequenceName(info.seq)
				for _, str in ipairs(find) do
					if name:find(str, nil, true) then
						ok = true
						break
					end
				end
				if ok then
					break
				end
			end
		end

		if ok then
			for k,v in pairs(translate) do
				manip_pos(ply, ply:LookupBone(k), v)
			end
			ply.jrpg_female_anim = true
		else
			reset_pose(ply)
		end
	end
end

hook.Add("UpdateAnimation", "movement", function(ply)
	if not jrpg.IsEnabled(ply) then return end

	if ply.jrpg_gesture_animations then
		calc_gesture_animations(ply)
	end

	if ply:OnGround() then
		local ang = ply:EyeAngles()
		local vel = ply:GetVelocity()

		local dot = ang:Right():Dot(vel)

		if ang:Forward():Dot(vel) > 100 then
			manip_angles(ply, 0, Angle(0,math.Clamp(dot*-0.25, -15, 15),0))
		else
			manip_angles(ply, 0, Angle(0,0,0))
		end
	else
		manip_angles(ply, 0, Angle(0,0,0))
	end

	if jtarget.GetEntity(ply):IsValid() and not jrpg.IsWieldingShield(ply) and not ply:GetNW2Bool("jrpg_sword_charge") then
		ply.jrpg_bounce_anim_seed = ply.jrpg_bounce_anim_seed or math.random()
		if (CurTime() + ply.jrpg_bounce_anim_seed)%0.5 < 0.25 then
			if not ply.jrpg_bounce_anim then
				ply:AnimResetGestureSlot(GESTURE_SLOT_VCD)
				ply:AnimRestartGesture(GESTURE_SLOT_VCD,  ply:GetSequenceActivity(ply:LookupSequence("jump_land")), true)
				ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM,  ply:GetSequenceActivity(ply:LookupSequence("flinch_stomach_02")), true)
				ply:AnimSetGestureWeight(GESTURE_SLOT_VCD, math.Rand(0.2,0.35))
				ply:AnimSetGestureWeight(GESTURE_SLOT_CUSTOM, math.Rand(0.2,0.35))
				ply.jrpg_bounce_anim = true
			end
		elseif ply.jrpg_bounce_anim then
			ply.jrpg_bounce_anim = false
		end
	end

	local vel = ply:GetVelocity()
	if not ply:IsOnGround() and vel:Length() > 750 then
		ply:SetPoseParameter("move_x", vel:Dot(ply:GetForward())/1000)
		ply:SetPoseParameter("move_y", vel:Dot(ply:GetRight())/1000)
	end

	if CLIENT then
		calc_duck(ply)


		if ply:IsOnGround() then
			ply.jrpg_smooth_ground_z = ply.jrpg_smooth_ground_z or ply:GetPos().z
			ply.jrpg_smooth_ground_z = ply.jrpg_smooth_ground_z + ((ply:GetPos().z - ply.jrpg_smooth_ground_z) * (FrameTime() * 10))

			manip_origin(ply, Vector(0,0,ply.jrpg_smooth_ground_z-ply:GetPos().z))
		else
			ply.jrpg_smooth_ground_z = ply:GetPos().z
		end
	end

	male2female_animations(ply)
end)