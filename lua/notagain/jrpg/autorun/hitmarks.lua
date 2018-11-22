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

	local hitmark_fonts = {
		{
			min = 0,
			max = 0.25,
			font = "korataki",
			blur_size = 8,
			weight = 50,
			size = 20,
			color = Color(0, 0, 0, 255),
		},
		{
			min = 0.25,
			max = 0.5,
			font = "korataki",
			blur_size = 8,
			weight = 50,
			size = 26,
			color = Color(150, 150, 50, 255),
		},
		{
			min = 0.5,
			max = 1,
			font = "korataki",
			blur_size = 8,
			weight = 50,
			size = 30,
			color = Color(200, 50, 50, 255),
		},
		{
			min = 1,
			max = math.huge,
			font = "korataki",
			blur_size = 8,
			weight = 120,
			size = 40,
			--color = Color(200, 50, 50, 255),
		},
	}

	local line_mat = Material("particle/Particle_Glow_04")

	local line_width = 12
	local line_height = -10
	local max_bounce = 2
	local bounce_plane_height = 0

	local life_time = 3
	local hitmarks = {}
	local height_offset = 0

	hook.Add("HUDPaint", "hitmarks", function()
		if hook.Run("HUDShouldDraw", "JHitmarkers") == false then
			return
		end

		if hitmarks[1] then
			local d = FrameTime()

			for i = #hitmarks, 1, -1 do
				local data = hitmarks[i]

				local pos = data.real_pos
				local vis = 1

				if data.ent:IsValid() then
					if data.ent == LocalPlayer() and not data.ent:ShouldDrawLocalPlayer() then
						continue
					end

					pos = LocalToWorld(data.real_pos, Angle(0,0,0), data.ent:GetPos(), data.first_angle)
					data.last_pos = pos

					vis = data.ent.hm_pixvis_vis or vis
				else
					pos = data.last_pos or pos
				end

				local t = RealTime() + data.offset

				local fraction =  (data.life - t) / life_time

				local fade = math.Clamp(fraction ^ 0.25, 0, 1)

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


					local w, h = prettytext.GetTextSize(txt, font_info.font, font_info.size, font_info.weight, font_info.blur_size)
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
						x - w, hoffset + y + h + line_height,
						x - w + w * 3, hoffset + y + h + line_height,
						line_width,
						true
					)

					prettytext.Draw(txt, x, hoffset + y, font_info.font, font_info.size, font_info.weight, font_info.blur_size, Color(255, 255, 255, 255), font_info.color)

					surface.SetAlphaMultiplier(1)
				end

				if fraction <= 0 then
					table.remove(hitmarks, i)
				end
			end
		end
	end)

	function hitmarkers.ShowDamage(ent, dmg, pos, xp)
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

		table.insert(
			hitmarks,
			{
				ent = ent,
				str = str,
				first_angle = ent:IsValid() and ent:GetAngles() or Angle(0,0,0),
				real_pos = pos,
				dmg = dmg,
				max_health = ent.hm_max_health or dmg,

				life = RealTime() + offset + life_time + math.random(),
				dir = vel,
				pos = Vector(),
				vel = vel,
				rec = rec,

				offset = offset,
				height_offset = height_offset,
				xp = xp,

				bounced = 0
			}
		)

		if ent ~= LocalPlayer() then
			healthbars.ShowHealth(ent)
		end
	end

	net.Receive("hitmark", function()
		local ent = net.ReadEntity()
		local dmg = math.Round(net.ReadFloat())
		local pos = net.ReadVector()
		local cur = math.Round(net.ReadFloat())
		local max = math.Round(net.ReadFloat())

		if not ent.hm_last_health_time or ent.hm_last_health_time < CurTime() then
			ent.hm_last_health = ent.hm_cur_health or max
		end

		ent.hm_last_health_time = CurTime() + 3

		ent.hm_cur_health = cur
		ent.hm_max_health = max

		if ent == LocalPlayer() and dmg ~= 0 and dmg ~= -1 then
			return
		end

		hitmarkers.ShowDamage(ent, dmg, pos)
	end)

	net.Receive("hitmark_custom", function()
		local ent = net.ReadEntity()
		local str = net.ReadString()
		local pos = net.ReadVector()
		local cur = math.Round(net.ReadFloat())
		local max = math.Round(net.ReadFloat())

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
	function hitmarkers.ShowDamage(ent, dmg, pos, filter)
		ent = ent or NULL
		dmg = dmg or 0
		pos = pos or ent:EyePos()
		filter = filter or player.GetAll()

		net.Start("hitmark", true)
			net.WriteEntity(ent)
			net.WriteFloat(dmg)
			net.WriteVector(pos)
			net.WriteFloat(ent:Health())
			net.WriteFloat(ent:GetMaxHealth())
		net.Send(filter)

		-- to prevent the timer from showing damage as well
		ent.hm_last_health = ent:Health()
	end

	util.AddNetworkString("hitmark")

	function hitmarkers.ShowDamageCustom(ent, str, pos, filter)
		ent = ent or NULL
		pos = pos or ent:EyePos()
		filter = filter or player.GetAll()

		net.Start("hitmark_custom", true)
			net.WriteEntity(ent)
			net.WriteString(str)
			net.WriteVector(pos)
			net.WriteFloat(ent:Health())
			net.WriteFloat(ent:GetMaxHealth())
		net.Send(filter)
	end

	util.AddNetworkString("hitmark_custom")

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
		if not (dmg:GetAttacker():IsNPC() or dmg:GetAttacker():IsPlayer()) then return end
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
			hitmarkers.ShowDamageCustom(ent, "BLOCK", pos, filter)
			return
		end

		local pos = dmg:GetDamagePosition()

		if pos == vector_origin then
			pos = ent:GetPos()
		end

		timer.Create(tostring(ent).."_hitmarker", 0, 1, function()
			if ent:IsValid() then

				if damage > 0 then
					if last_health == ent:Health() then
						if ent:IsNPC() or ent:IsPlayer() then
							damage = 0
						else
							return
						end
					elseif (ent:Health() - last_health) ~= damage then
						damage = last_health - ent:Health()
					end
				end

				if damage == 0 and not jrpg.IsActorAlive(ent) then return end

				hitmarkers.ShowDamage(ent, -damage, pos, filter)
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
						jdmg.DamageEffect(ent, "heal")
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
