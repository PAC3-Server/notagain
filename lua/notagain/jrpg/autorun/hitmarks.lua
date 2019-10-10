local hitmarkers = _G.hitmarkers or {}
_G.hitmarkers = hitmarkers

if CLIENT then
	local function set_blend_mode(how)
		if not render.OverrideBlendFunc then return end

		if how == "additive" then
			render.OverrideBlendFunc(true, BLEND_SRC_ALPHA, BLEND_ONE, BLEND_SRC_ALPHA, BLEND_ONE)
		elseif how == "multiplicative" then
			render.OverrideBlendFunc(true, BLEND_DST_COLOR, BLEND_ZERO, BLEND_DST_COLOR, BLEND_ZERO)
		else
			render.OverrideBlendFunc(false)
		end
	end

	local prettytext = requirex("pretty_text")
	local draw_line = requirex("draw_line")
	local draw_rect = requirex("draw_skewed_rect")

	local gradient = CreateMaterial(tostring({}), "UnlitGeneric", {
		["$BaseTexture"] = "gui/center_gradient",
		["$BaseTextureTransform"] = "center .5 .5 scale 1 1 rotate 90 translate 0 0",
		["$VertexAlpha"] = 1,
		["$VertexColor"] = 1,
		["$Additive"] = 0,
	})

	local border = CreateMaterial(tostring({}), "UnlitGeneric", {
		["$BaseTexture"] = "props/metalduct001a",
		["$VertexAlpha"] = 1,
		["$VertexColor"] = 1,
	})

	local no_texture = Material("vgui/white")

	local gradient = Material("gui/gradient_down")
	local border = CreateMaterial(tostring({}	), "UnlitGeneric", {
		["$BaseTexture"] = "props/metalduct001a",
		["$VertexAlpha"] = 1,
		["$VertexColor"] = 1,
		["$Additive"] = 1,
	})

	local size_mult = 1

	local hitmark_fonts = {
		{
			min = 0,
			max = 0.25,
			font = "korataki",
			blur_size = 8,
			weight = 50,
			size = 20*size_mult,
			color = Color(0, 0, 0, 255),
		},
		{
			min = 0.25,
			max = 0.5,
			font = "korataki",
			blur_size = 8,
			weight = 50,
			size = 26*size_mult,
			color = Color(150, 150, 50, 255),
		},
		{
			min = 0.5,
			max = 1,
			font = "korataki",
			blur_size = 8,
			weight = 50,
			size = 30*size_mult,
			color = Color(200, 50, 50, 255),
		},
		{
			min = 1,
			max = math.huge,
			font = "korataki",
			blur_size = 8,
			weight = 120,
			size = 40*size_mult,
			--color = Color(200, 50, 50, 255),
		},
	}

	local line_mat = Material("particle/Particle_Glow_04")

	local line_width = 12
	local line_height = -10
	local max_bounce = 2
	local bounce_plane_height = 0

	local hitmarks = {}
	local height_offset = 0

	hook.Add("HUDPaint", "hitmarks", function()
		if hook.Run("HUDShouldDraw", "JHitmarkers") == false then
			return
		end

		if hitmarks[1] then
			local d = FrameTime()
			local time = RealTime()
			local t = time

			for i = 1, #hitmarks do
				local data = hitmarks[i]

				local pos = data.real_pos

				local vis = 1
				if data.ent:IsValid() then
					if data.ent == LocalPlayer() and not data.ent:ShouldDrawLocalPlayer() then
						continue
					end

					if data.move_me then
						local min, max = data.ent:OBBMins(),data.ent:OBBMaxs()
						data.real_pos2 = data.real_pos2 or Vector(math.Rand(min.x, max.x), math.Rand(min.y, max.y), math.Rand(min.z, max.z))
						data.move_pos_timer = data.move_pos_timer or RealTime()+1
						local f = data.move_pos_timer - RealTime()
						f = math.Clamp(f, 0,1)
						pos = LerpVector(f^20, data.real_pos2, data.real_pos)
					end

					pos = LocalToWorld(pos, Angle(0,0,0), data.ent:GetPos(), data.first_angle)
					data.last_pos = pos

					vis = data.ent.hm_pixvis_vis or vis
				else
					pos = data.last_pos or pos
				end

				local fraction =  (time - data.start_time) / data.time_length
				fraction = -fraction + 1
				local fade = math.Clamp(fraction ^ 0.25, 0, 1)

				local size_mult = data.attacker == LocalPlayer() and fraction > 0.8 and 2 or 1

				if data.bounced < max_bounce then
					data.vel = data.vel + Vector(0,0,-0.25)
					data.vel = data.vel * 0.99
				else
					data.vel = data.vel * 0.85
				end

				if data.pos.z < -bounce_plane_height and data.bounced < max_bounce then
					data.vel.z = -data.vel.z * 0.5
					data.pos.z = -bounce_plane_height

					data.bounced = data.bounced + 1

					if data.bounced == max_bounce then
						data.vel.z = data.vel.z * -1
					end
				end

				data.pos = data.pos + data.vel * d * 25

				pos = (pos + data.pos + Vector(0, 0, bounce_plane_height)):ToScreen()

				local txt = math.Round(Lerp(math.Clamp(fraction-0.95, 0, 1), data.dmg, 0))

				if data.str then
					txt = data.str
				elseif data.xp then
					txt = "xp +" .. txt
				elseif data.dmg == 0 then
					txt = "MISS"
				elseif data.dmg > 0 then
					txt = "+" .. txt
				end

				if pos.visible then

					local x = pos.x + data.pos.x
					local y = pos.y + data.pos.y

					if fade < 0.5 then
						y = y + (fade-0.5)*150
					end

					local hm = (i/#hitmarks)
					vis = vis * hm

					fade = fade * vis

					surface.SetAlphaMultiplier(fade)

					local fraction = -data.dmg / data.max_health

					local font_info = hitmark_fonts[1]

					for _, info in ipairs(hitmark_fonts) do
						if fraction >= info.min and fraction <= info.max then
							font_info = info
							break
						end
					end

					if fraction >= 1 then
						font_info.color = HSVToColor((t*500)%360, 0.75, 1)
					end

					local w, h = prettytext.GetTextSize(txt, font_info.font, font_info.size * size_mult, font_info.weight, font_info.blur_size)
					local hoffset = data.height_offset * -h

					if data.xp then
						surface.SetDrawColor(100, 0, 255, 255)
					elseif data.dmg == 0 then
						surface.SetDrawColor(255, 255, 255, 255)
					elseif data.rec then
						surface.SetDrawColor(100, 255, 100, 255)
					else
						surface.SetDrawColor(255, 100, 100, 255)
					end

					surface.SetMaterial(line_mat)

					draw_line(
						x - w*1.5,
						y + h/2.5,

						x - w*-1.5,
						y + h/2.5,
						line_width * (font_info.size/30) * size_mult,
						true
					)

					prettytext.DrawText({
						text = txt,
						font = font_info.font,
						weight = font_info.weight,
						size = font_info.size * size_mult,
						x = x,
						y = y,
						blur_size = font_info.blur_size+size_mult*5,
						blur_overdraw = 3 + ((size_mult-1)*5),
						x_align = -0.5,
						y_align = -0.5,
						background_color = font_info.color,
					})

					surface.SetAlphaMultiplier(1)
				end

				if fraction <= 0 then
					data.remove_me = true
				end
			end

			for i = #hitmarks, 1, -1 do
				if hitmarks[i].remove_me then
					table.remove(hitmarks, i)
				end
			end
		end
	end)

	function hitmarkers.ShowDamage(ent, dmg, pos, xp, attacker)
		ent = ent or NULL
		dmg = dmg or 0
		pos = pos or ent:EyePos()

		local str
		if type(dmg) == "string" then
			str = dmg
			dmg = 0
		end

		if ent:IsValid() then
			pos = ent:WorldToLocal(pos)
		end

		local rec = dmg > 0

		local vel = VectorRand()
		local offset = math.random() * 5

		height_offset = (height_offset + 1)%5

		for i,v in ipairs(hitmarks) do
			if v.ent:IsValid() and v.attacker == LocalPlayer() then
				if not v.move_me then
					v.move_me = true
				end
			end
		end

		table.insert(hitmarks, {
			ent = ent,
			attacker = attacker,
			str = str,
			first_angle = ent:IsValid() and ent:GetAngles() or Angle(0,0,0),
			real_pos = pos,
			dmg = dmg,
			max_health = ent.hm_max_health or dmg,

			start_time = RealTime(),
			time_length = math.random() + 0.5,

			dir = vel,
			pos = Vector(),
			vel = vel,
			rec = rec,

			offset = offset,
			height_offset = height_offset,
			xp = xp,

			bounced = 0
		})

		if ent ~= LocalPlayer() then
			healthbars.ShowHealth(ent)
		end
	end

	net.Receive("jrpg_hitmarks", function()
		local ent = net.ReadEntity()
		local dmg = math.Round(net.ReadFloat())
		local pos = net.ReadVector()
		local cur = math.Round(net.ReadFloat())
		local max = math.Round(net.ReadFloat())
		local attacker = net.ReadEntity()

		if not jrpg.IsEnabled(LocalPlayer()) then
			if not attacker:IsPlayer() or not jrpg.IsEnabled(attacker) then
				return
			end
		end

		if not ent.hm_last_health_time or ent.hm_last_health_time < CurTime() then
			ent.hm_last_health = ent.hm_cur_health or max
		end

		ent.hm_last_health_time = CurTime() + 3

		ent.hm_cur_health = cur
		ent.hm_max_health = max

		if ent == LocalPlayer() and (dmg > 0) then
			return
		end

		hitmarkers.ShowDamage(ent, dmg, pos, nil, attacker)
	end)

	net.Receive("jrpg_hitmarks_custom", function()
		local ent = net.ReadEntity()
		local str = net.ReadString()
		local pos = net.ReadVector()
		local cur = math.Round(net.ReadFloat())
		local max = math.Round(net.ReadFloat())

		if not jrpg.IsEnabled(LocalPlayer()) then
			return
		end


		if not ent.hm_last_health_time or ent.hm_last_health_time < CurTime() then
			ent.hm_last_health = ent.hm_cur_health or max
		end

		ent.hm_last_health_time = CurTime() + 3

		ent.hm_cur_health = cur
		ent.hm_max_health = max

		hitmarkers.ShowDamage(ent, str, pos)
	end)

	net.Receive("hitmark_xp", function()
		local ent = net.ReadEntity()
		local xp = math.Round(net.ReadFloat())
		local pos = net.ReadVector()

		hitmarkers.ShowDamage(ent, xp, pos, true)
	end)
end

if SERVER then
	function hitmarkers.ShowDamage(ent, dmg, pos, filter, attacker)
		ent = ent or NULL
		dmg = dmg or 0
		pos = pos or ent:EyePos()
		filter = filter or player.GetAll()

		net.Start("jrpg_hitmarks", true)
			net.WriteEntity(ent)
			net.WriteFloat(dmg)
			net.WriteVector(pos)
			net.WriteFloat(ent:Health())
			net.WriteFloat(ent:GetMaxHealth())
			net.WriteEntity(attacker)
		net.Send(filter)

		-- to prevent the timer from showing damage as well
		ent.hm_last_health = ent:Health()
	end

	util.AddNetworkString("jrpg_hitmarks")

	function hitmarkers.ShowDamageCustom(ent, str, pos, filter)
		ent = ent or NULL
		pos = pos or ent:EyePos()
		filter = filter or player.GetAll()

		net.Start("jrpg_hitmarks_custom", true)
			net.WriteEntity(ent)
			net.WriteString(str)
			net.WriteVector(pos)
			net.WriteFloat(ent:Health())
			net.WriteFloat(ent:GetMaxHealth())
		net.Send(filter)
	end

	util.AddNetworkString("jrpg_hitmarks_custom")

	function hitmarkers.ShowXP(ent, xp, pos, filter)
		ent = ent or NULL
		xp = xp or 0
		pos = pos or ent:EyePos()
		filter = filter or player.GetAll()

		net.Start("hitmark_xp", true)
			net.WriteEntity(ent)
			net.WriteFloat(xp)
			net.WriteVector(pos)
		net.Send(filter)
	end

	util.AddNetworkString("hitmark_xp")

	hook.Add("EntityTakeDamage", "hitmarker", function(ent, dmg)
		if not jrpg.IsActor(ent) then return end

		local filter = {}
		for k,v in pairs(player.GetAll()) do
			if v:GetPos():Distance(ent:GetPos()) < 1500 * (ent:GetModelScale() or 1) then
				table.insert(filter, v)
			end
		end

		--if jdmg.GetDamageType(dmg) == "heal" then return end

		local last_health = ent:Health()
		local damage = dmg:GetDamage()

		if damage == -1 then
			hitmarkers.ShowDamageCustom(ent, "BLOCK", pos, filter, dmg:GetAttacker())
			return
		end

		local pos = dmg:GetDamagePosition()

		if pos == vector_origin then
			pos = ent:WorldSpaceCenter()
		end

		if ent:WorldSpaceCenter():Distance(pos) > ent:BoundingRadius() then
			pos = ent:NearestPoint(pos)
		end

		local attacker = dmg:GetAttacker()

		timer.Create(tostring(ent).."_hitmarker", 0, 1, function()
			if ent:IsValid() then

				if damage > 0 then
					if last_health == ent:Health() then
						damage = 0
					elseif (ent:Health() - last_health) ~= damage then
						damage = last_health - ent:Health()
					end
				end

				hitmarkers.ShowDamage(ent, -damage, pos, filter, attacker)
			end
		end)
	end)

	timer.Create("hitmarker", 1, 0, function()
		for _, ent in ipairs(ents.GetAll()) do
			if ent.GetMaxHealth then
				if ent.hm_last_health ~= ent:Health() then
					local diff = ent:Health() - (ent.hm_last_health or 0)
					if diff > 0 then
						hitmarkers.ShowDamage(ent, diff)
						jdmg.DamageEffect(ent, "heal", math.min(diff, 1), math.min(diff, 1), ent:WorldSpaceCenter())
					elseif diff < 0 then
						hitmarkers.ShowDamage(ent, diff)
					end
					ent.hm_last_health = ent:Health()
				end

				if ent.hm_last_max_health ~= ent:GetMaxHealth() then
					if ent.hm_last_max_health then
						hitmarkers.ShowDamage(ent, 0)
					end
					ent.hm_last_max_health = ent:GetMaxHealth()
				end
			end
		end
	end)
end

return hitmarkers
