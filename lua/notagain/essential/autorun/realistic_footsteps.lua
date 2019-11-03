hook.Add("PlayerFootstep", "realistic_footsteps", function(ply, pos, foot, sound, volume, rf)
	if ply:GetMoveType() ~= MOVETYPE_WALK or not ply:OnGround() then return end
	return true
end)

hook.Add("PlayerStepSoundTime", "realistic_footsteps", function(ply, type, walking)
	if ply:GetMoveType() ~= MOVETYPE_WALK or not ply:OnGround() then return end
	return 9999
end)

if CLIENT then
	local extra = {
		{
			find = {
				"combine",
				"soldier",
				"gasmask",
				"swat",
				"guerilla",
				"urban",
			},
			sounds = {
				"npc/combine_soldier/gear1.wav",
				"npc/combine_soldier/gear2.wav",
				"npc/combine_soldier/gear3.wav",
				"npc/combine_soldier/gear4.wav",
				"npc/combine_soldier/gear5.wav",
				"npc/combine_soldier/gear6.wav",
			},
		},
		{
			find = {
				"police",
				"riot",
				"leet",
				"dod_german",
				"arctic",
				"phoenix",
			},
			sounds = {
				"npc/metropolice/gear1.wav",
				"npc/metropolice/gear2.wav",
				"npc/metropolice/gear3.wav",
				"npc/metropolice/gear4.wav",
				"npc/metropolice/gear5.wav",
				"npc/metropolice/gear6.wav",
			},
		},
		{
			find = {
				"kleiner",
				"magnusson",
				"breen",
				"gman",
			},
			sounds = {
				"npc/footsteps/softshoe_generic6.wav"
			},
		},
		{
			find = {
				"group0%d",
				"hostage",
			},
			sounds = {
				"npc/footsteps/hardboot_generic1.wav",
				"npc/footsteps/hardboot_generic2.wav",
				"npc/footsteps/hardboot_generic3.wav",
				"npc/footsteps/hardboot_generic4.wav",
				"npc/footsteps/hardboot_generic5.wav",
				"npc/footsteps/hardboot_generic6.wav",
				"npc/footsteps/hardboot_generic8.wav",
			},
		},
		{
			find = {
				"eli"
			},
			sounds = {
				"npc/stalker/stalker_footstep_left1.wav",
				"npc/stalker/stalker_footstep_left2.wav",
				"npc/stalker/stalker_footstep_right1.wav",
				"npc/stalker/stalker_footstep_right2.wav",
			},
			play_only = "left",
		},
		{
			find = {
				"eli"
			},
			sounds = {
				"physics/wood/wood_furniture_impact_soft1.wav",
				"physics/wood/wood_furniture_impact_soft2.wav",
				"physics/wood/wood_furniture_impact_soft3.wav",
			},
			pitch = 125,
			random_pitch = 0,
			play_only = "left",
		},
		{
			find = {
				"skeleton"
			},
			sounds = {
				"physics/wood/wood_furniture_impact_soft1.wav",
				"physics/wood/wood_furniture_impact_soft2.wav",
				"physics/wood/wood_furniture_impact_soft3.wav",
			},
			pitch = 175,
			random_pitch = 0.25,
		},
		{
			find = {
				"chell"
			},
			sounds = {
				"npc/stalker/stalker_footstep_left1.wav",
				"npc/stalker/stalker_footstep_left2.wav",
				"npc/stalker/stalker_footstep_right1.wav",
				"npc/stalker/stalker_footstep_right2.wav",
			},
		},
		{
			find = {
				"zombie",
			},
			sounds = {
				"npc/zombie/foot1.wav",
				"npc/zombie/foot2.wav",
				"npc/zombie/foot3.wav",
				"npc/fast_zombie/foot1.wav",
				"npc/fast_zombie/foot2.wav",
				"npc/fast_zombie/foot3.wav",
			},
		}
	}

	local sounds = util.JSONToTable(file.Read("realistic_footsteps_cache.txt") or "") or {}
	if not next(sounds) then
		for _, name in pairs(sound.GetTable()) do
			if name:EndsWith("StepLeft") or name:EndsWith("StepRight") then
				local data = sound.GetProperties(name)

				if type(data.sound) == "string" then
					data.sound = {data.sound}
				end

				local friendly = name:match("(.+)%."):lower()

				sounds[friendly] = sounds[friendly] or {sounds = {}, done = {}, pitch = data.pitch, level = data.level, volume = data.volume}

				for _, path in ipairs(data.sound) do
					path = path:lower()
					if not sounds[friendly].done[path] then
						table.insert(sounds[friendly].sounds, path)
						sounds[friendly].done[path] = true
					end
				end
			end
		end
		file.Write("realistic_footsteps_cache.txt", util.TableToJSON(sounds))
	end

	local feet = {"left", "right"}

	hook.Add("Think", "realistic_footsteps", function()
		for _, ply in ipairs(player.GetAll()) do
			if ply:GetMoveType() ~= MOVETYPE_WALK or not ply:OnGround() or ply:GetVelocity():IsZero() then continue end
			for _, which in ipairs(feet) do
				ply.realistic_footsteps = ply.realistic_footsteps or {}
				ply.realistic_footsteps[which] = ply.realistic_footsteps[which] or {}


				ply:SetupBones()
				local toes = true
				local id = ply:LookupBone(which == "right" and "valvebiped.bip01_r_toe0" or "valvebiped.bip01_l_toe0")

				if not id then
					toes = false
				end
				id = ply:LookupBone(which == "right" and "valvebiped.bip01_r_foot" or "valvebiped.bip01_l_foot")
				toes = false


				if not id then continue end

				local m = ply:GetBoneMatrix(id)

				if not m then continue end
				local scale = ply:GetModelScale() or 1
				local pos = m:GetTranslation()

				local vel = (ply.realistic_footsteps[which].last_pos or pos) - pos
				ply.realistic_footsteps[which].smooth_vel = ply.realistic_footsteps[which].smooth_vel or vel
				ply.realistic_footsteps[which].smooth_vel = ply.realistic_footsteps[which].smooth_vel + ((vel - ply.realistic_footsteps[which].smooth_vel) * math.Clamp(FrameTime() * 5, 0.0001, 1))
				vel = ply.realistic_footsteps[which].smooth_vel

				do -- hack to prevent crazy velocites
					local l = ply.realistic_footsteps[which].smooth_vel:Length()
					if l + 0 ~= l then
						ply.realistic_footsteps[which].smooth_vel:Zero()
					end
				end

				local dir = Vector(0,0,-50)

				local trace = util.TraceLine({start = pos - dir*0.25, endpos = pos + dir, filter = {ply}})

				if trace.HitTexture == "TOOLS/TOOLSNODRAW" or trace.HitTexture == "**empty**" then
					trace.Hit = false
				end

				-- if dir is -50 this is required to check if the foot is actualy above player pos
				if toes then
					if pos.z - ply:GetPos().z > scale*2.5 then
						trace.Hit = false
					end
				else
					if pos.z - ply:GetPos().z > scale*7.5 then
						trace.Hit = false
					end
				end
				local volume = math.Clamp(vel:Length2D()/20, 0, 1)

				if volume == 0 then
					trace.Hit = false
				end

				if ply.realistic_footsteps[which].hit and ply.realistic_footsteps[which].hit > CurTime() then
					trace.Hit = false
				end

				--debugoverlay.Cross(trace.HitPos, 1, 1)
				--debugoverlay.Line(trace.StartPos, trace.HitPos, 0.25, trace.Hit and Color(255,0,0,255) or Color(255,255,255,255), true)
				--debugoverlay.Line(trace.HitPos, pos + dir, 0.25, Color(0,255,0,255), true)

				if trace.Hit then
					ply.realistic_footsteps[which].hit = CurTime() + 0.25

					--debugoverlay.Cross(trace.HitPos, 5, 1, which == "left" and Color(0,255,255) or Color(255,0,255))
					local data

					if bit.band(util.PointContents(trace.HitPos), CONTENTS_WATER) == CONTENTS_WATER then
						data = sounds.water
					elseif trace.SurfaceProps ~= -1 then
						local name = util.GetSurfacePropName(trace.SurfaceProps)
						data = sounds[name]
						if not data then
							for k,v in pairs(sounds) do
								if k:find(name) then
									data = v
									break
								end
							end
						end

						if not data then
							data = sounds.default
						end
					end

					if data then
						if ply.realistic_footsteps_last_foot ~= which and (not ply.realistic_footsteps[which].next_play or ply.realistic_footsteps[which].next_play < RealTime()) then
							local mute = false

							local path = table.Random(data.sounds)
							for name, func in pairs(hook.GetTable().PlayerFootstep) do
								if name ~= "realistic_footsteps" then
									local ret = func(ply, pos, path, volume)
									if ret == true then
										mute = true
										break
									end
								end
							end

							if mute then continue end

							local pitch = data.pitch

							if type(pitch) == "table" then
								pitch = math.Rand(pitch[1], pitch[2])
							end

							EmitSound(path, pos, ply:EntIndex(), CHAN_BODY, data.volume * volume, 60 or data.level, SND_NOFLAGS, math.Clamp((pitch / scale) + math.Rand(-10,10), 0, 255))
							ply.realistic_footsteps[which].next_play = RealTime() + 0.1
							ply.realistic_footsteps_last_foot = which

							local mdl = ply:GetModel()
							for _, info in pairs(extra) do
								for _, pattern in ipairs(info.find) do
									if mdl:find(pattern) then
										if not info.play_only or info.play_only == which then

											local pitch = info.pitch or data.pitch

											if type(pitch) == "table" then
												pitch = math.Rand(pitch[1], pitch[2])
											end

											EmitSound(
												table.Random(info.sounds),
												pos,
												ply:EntIndex(),
												CHAN_BODY,
												data.volume * volume,
												data.level,
												SND_NOFLAGS,
												math.Clamp((pitch / scale) + math.Rand(-10,10) * (info.random_pitch or 1), 0, 255)
											)
										end
									end
								end
							end
						end
					end
				end

				ply.realistic_footsteps[which].last_pos = pos
			end
		end
	end)
end
