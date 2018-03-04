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

	local draw_line = requirex("draw_line")
	local draw_rect = requirex("draw_skewed_rect")
	local prettytext = requirex("pretty_text")

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
	local function draw_health_bar(ent, x,y, w,h, health, last_health, fade, border_size, skew, r,g,b, is_health)
		render.SetColorModulation(0.1, 0.1, 0.1)
		render.SetBlend(fade)
		render.SetMaterial(no_texture)
		draw_rect(x,y,w,h, skew)

		render.SetMaterial(gradient)
		render.SetBlend(fade)
		render.SetColorModulation(is_health and 0.784 or 0.20, 0.20, 0.20)

		for _ = 1, 2 do
			draw_rect(x,y,w*last_health,h, skew, 0, 70, 5, gradient:GetTexture("$BaseTexture"):Width())
		end

		render.SetColorModulation(r/255,g/255,b/255)
		render.SetBlend(fade)
		for _ = 1, 2 do
			draw_rect(x,y,w*health,h, skew, 0, 70, 5, gradient:GetTexture("$BaseTexture"):Width())
		end

		render.SetColorModulation(0.588, 0.588, 0.588)
		render.SetBlend(fade)
		render.SetMaterial(border)

		for _ = 1, 2 do
			draw_rect(x,y,w,h, skew, 1, 64,border_size, border:GetTexture("$BaseTexture"):Width(), true)
		end

		local size = 24
		x = x + 16
		y = y + 5
		if is_health then
			local statuses = jdmg.GetStatuses and jdmg.GetStatuses(ent) or {}

			for _, status in pairs(statuses) do
				local fade = fade * status:GetAmount()
				fade = fade ^ 0.25

				if status.Negative then
					render.SetColorModulation(0.588, 0, 0)
					render.SetBlend(fade)
				elseif status.Positive then
					render.SetColorModulation(0, 0, 0.588)
					render.SetBlend(fade)
				else
					render.SetColorModulation(0, 0, 0)
					render.SetBlend(fade)
				end
				render.SetMaterial(no_texture)
				draw_rect(x+w-size,y+h,size,size)

				render.SetColorModulation(1, 1, 1)
				render.SetBlend(fade)
				render.SetMaterial(border)
				draw_rect(x+w-size,y+h,size,size, 0, 1, 64,border_size/1.5, border:GetTexture("$BaseTexture"):Width(), true)

				render.SetColorModulation(1, 1, 1)
				render.SetBlend(fade)
				render.SetMaterial(status.Icon)
				draw_rect(x+w-size,y+h,size,size)
				draw_rect(x+w-size,y+h,size,size)

				render.SetColorModulation(0, 0, 0)
				render.SetBlend(0.78)
				render.SetMaterial(no_texture)
				draw_rect(x+w-size,y+h,size*status:GetAmount(),size)

				x = x - 24 - 5
			end
		end
	end


	local gradient = Material("gui/gradient_down")
	local border = CreateMaterial(tostring({}), "UnlitGeneric", {
		["$BaseTexture"] = "props/metalduct001a",
		["$VertexAlpha"] = 1,
		["$VertexColor"] = 1,
		["$Additive"] = 1,
	})

	local function draw_weapon_info(x,y, w,h, color, fade)
		local skew = 0
		render.SetColorModulation(0.098, 0.098, 0.098)
		render.SetBlend(0.78*fade)
		render.SetMaterial(no_texture)
		draw_rect(x,y,w,h, skew)

		render.SetMaterial(gradient)
		render.SetColorModulation(color.r/255, color.g/255, color.b/255)
		render.SetBlend((color.a/255) * fade)

		for _ = 1, 2 do
			draw_rect(x,y,w,h, skew)
		end

		render.SetColorModulation(0.78, 0.78, 0.78)
		render.SetMaterial(border)
		render.SetBlend(fade)

		for _ = 1, 2 do
			draw_rect(x,y,w,h, skew, 3, 64,3, border:GetTexture("$BaseTexture"):Width(), true)
		end
	end

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

	local function find_head_pos(ent)
		if not ent.bc_head or ent.bc_last_mdl ~= ent:GetModel() then
			for i = 0, ent:GetBoneCount() do
				local name = ent:GetBoneName(i):lower()
				if name:find("head") then
					ent.bc_head = i
					ent.bc_last_mdl = ent:GetModel()
					break
				end
			end
		end

		if ent.bc_head then
			return ent:GetBonePosition(ent.bc_head)
		end

		return ent:EyePos(), ent:EyeAngles()
	end

	local line_mat = Material("particle/Particle_Glow_04")

	local line_width = 12
	local line_height = -10
	local max_bounce = 2
	local bounce_plane_height = 0

	local life_time = 3
	local hitmarks = {}
	local height_offset = 0

	local health_bars = {}
	local weapon_info = {}

	hook.Add("HUDDrawTargetID", "hitmarks", function()
		return false
	end)

	local function surface_DrawTexturedRectRotatedPoint( x, y, w, h, rot)

		x = math.ceil(x)
		y = math.ceil(y)
		w = math.ceil(w)
		h = math.ceil(h)

		local y0 = -h/2
		local x0 = -w/2

		local c = math.cos( math.rad( rot ) )
		local s = math.sin( math.rad( rot ) )

		local newx = y0 * s - x0 * c
		local newy = y0 * c + x0 * s

		surface.DrawTexturedRectRotated( x + newx, y + newy, w, h, rot )

	end

	-- close enough
	local function draw_RoundedBoxOutlined(border_size, x, y, w, h, color )
		x = math.ceil(x)
		y = math.ceil(y)
		w = math.ceil(w)
		h = math.ceil(h)
		border_size = border_size/2
		surface.SetDrawColor(color)
		surface.DrawRect(x, y, border_size*2, h, color)
		surface.DrawRect(x+border_size*2, y, w-border_size*4, border_size*2)

		surface.DrawRect(x+w-border_size*2, y, border_size*2, h)
		surface.DrawRect(x+border_size*2, y+h-border_size*2, w-border_size*4, border_size*2)
	end

	hook.Add("HUDPaint", "hitmarks", function()
		if hook.Run("HUDShouldDraw", "JHitmarkers") == false then
			return
		end

		local ply = LocalPlayer()
		local boss_bar_y = 0

		for i = #health_bars, 1, -1 do
			local data = health_bars[i]
			local ent = data.ent

			if ent:IsValid() then
				local t = RealTime()
				local fraction = (data.time - t) / life_time * 2

				local name = jrpg.GetFriendlyName(ent)

				local world_pos = (ent:NearestPoint(ent:EyePos() + Vector(0,0,100000)) + Vector(0,0,2))
				local pos = world_pos:ToScreen()
				local dist = world_pos:Distance(EyePos())
				local scale = (ent:GetModelScale() and ent:GetModelScale()*2 or 2)
				local radius = ent:BoundingRadius() * 7
				local max_distance = scale * radius
				fraction = fraction * ((-(dist / max_distance)+1) ^ 2)

				ent.hm_pixvis = ent.hm_pixvis or util.GetPixelVisibleHandle()
				ent.hm_pixvis_vis = util.PixelVisible(world_pos, ent:BoundingRadius(), ent.hm_pixvis)
				local vis = ent.hm_pixvis_vis
				local selected_target = jtarget.GetEntity(LocalPlayer()) == ent

				if selected_target then
					vis = 1
					fraction = 1
				end

				if pos.visible and dist < max_distance and fraction > 0 or selected_target then
					local cur = ent.hm_cur_health or ent:Health()
					local max = ent.hm_max_health or ent:GetMaxHealth()
					local last = ent.hm_last_health or max

					if max == 0 or cur > max then
						max = 100
						cur = 100
					end

					if not ent.hm_last_health_time or ent.hm_last_health_time < CurTime() then
						last = cur
					end

					data.cur_health_smooth = data.cur_health_smooth or cur
					data.last_health_smooth = data.last_health_smooth or last

					data.cur_health_smooth = data.cur_health_smooth + ((cur - data.cur_health_smooth) * FrameTime() * 5)
					data.last_health_smooth = data.last_health_smooth + ((last - data.last_health_smooth) * FrameTime() * 5)

					local cur = data.cur_health_smooth
					local last = data.last_health_smooth

					local fade = math.Clamp(fraction ^ 0.25, 0, 1)
					fade = fade * vis

					local w, h = prettytext.GetTextSize(name, "candara", 20, 30, 2)

					local height = 10
					local border_size = 3
					local skew = -30
					local width = math.Clamp(radius * scale, w * 1.5 + 100,  ScrW()/2)

					if max > 1000 then
						height = 35
						height = 35
						pos.x = ScrW() / 2
						pos.y = 50 + boss_bar_y
						width = ScrW() / 1.1
						skew = 30
						border_size = 10
						boss_bar_y = boss_bar_y + height + 20
					else
						width = math.Clamp(width + (max - 50), 0, 500)
					end

					local width2 = width/2
					local text_x_offset = 15
					local y = pos.y-height/2
					local x = pos.x - width2
                    local health_color
                    local mana_color
                    local stamina_color

                    if jattributes then
                        health_color  = jattributes.Colors.Health
                        mana_color    = jattributes.Colors.Mana
                        stamina_color = jattributes.Colors.Stamina
                    else
                        health_color  = Color(0,200,100)
                        mana_color    = Color(0,0,255)
                        stamina_color = Color(255,255,0)
                    end

					draw_health_bar(ent, x, pos.y-height/2, width, height, math.Clamp(cur / max, 0, 1), math.Clamp(last / max, 0, 1), fade, border_size, -12,health_color.r,health_color.g,health_color.b, true)

					y = y + math.ceil(height + border_size / 2)

					local height = height
					local border_size = border_size / 2

					do
						local cur = ent:GetNWFloat("jattributes_mana", -1)
						if jrpg.IsEnabled(ent) and cur ~= -1 then
							local max = ent:GetNWFloat("jattributes_max_mana", 100)
							local width = math.Clamp(max*3, 0, 500)

							draw_health_bar(ent, x, y, width, height/2, math.Clamp(cur / max, 0, 1), 1, fade, border_size, -12,mana_color.r,mana_color.g,mana_color.b,false)
							y = y + height-border_size
						end
					end


					do
						local cur = ent:GetNWFloat("jattributes_stamina", -1)
						if jrpg.IsEnabled(ent) and cur ~= -1 then
							local max = ent:GetNWFloat("jattributes_max_stamina", 100)
							local width = math.Clamp(max*3, 0, 500)

							draw_health_bar(ent, x, y, width, height/2, math.Clamp(cur / max, 0, 1), 1, fade, border_size, -12,stamina_color.r,stamina_color.g,stamina_color.b,false)
						end
					end

					prettytext.Draw(name, x - text_x_offset, pos.y - 5, "Square721 BT", 24, 1, 5, Color(230, 230, 230, 255 * fade), (ent:IsPlayer() and team.GetColor(ent:Team()) or nil), 0, -1)

					if jrpg.IsEnabled(ent) then
						prettytext.Draw("Lv. " .. ent:GetNWInt("jlevel_level"), x + width, pos.y - 5, "Square721 BT", 20, 1000, 5, Color(230, 230, 230, 255 * fade), nil, -1, -1)
					end
				end

				if fraction <= 0 then
					table.remove(health_bars, i)
				end
			end
		end

		for i = #weapon_info, 1, -1 do
			local data = weapon_info[i]
			local ent = data.ent

			if not ent:IsValid() then
				table.remove(weapon_info, i)
				continue
			end

			local pos = (ent:NearestPoint(ent:EyePos() + Vector(0,0,100000)) + Vector(0,0,2)):ToScreen()
			local vis = ent.hm_pixvis_vis or ent == LocalPlayer() and 1 or 0

			if pos.visible then
				local y_offset = 0
				if ent == LocalPlayer() then y_offset = 50 end

				local time = RealTime()

				if data.time > time then
					local fade = math.min(((data.time - time) / data.length) + 0.75, 1)
					fade = fade * vis
					local w, h = prettytext.GetTextSize(data.name, "Square721 BT", 25, 1000, 2)

					local x, y = pos.x, pos.y
					x = x - w / 2
					y = y - h * 3

					local bg
					local fg

					if ent == ply or jrpg.IsFriend(ent) then
						fg = Color(255, 255, 255, 220 * fade)
						bg = Color(25, 100, 130, 50 * fade)
					else
						fg = Color(255, 255, 255, 220 * fade)
						bg = Color(150, 50, 50, 50)
					end

					local border = 15
					local scale_h = 0.2

					local border = border
					draw_weapon_info(x - border, y - border*scale_h + y_offset, w + border*2, h + border*2*scale_h, bg, fade)

					prettytext.Draw(data.name, x, y + y_offset + 1, "Square721 BT", 25, 1000, 3, fg, bg)
				else
					table.remove(weapon_info, i)
				end
			end
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

	function hitmarkers.ShowHealth(ent, focus)
		if focus then
			table.Empty(health_bars)
		else
			for i, data in ipairs(health_bars) do
				if data.ent == ent then
					table.remove(health_bars, i)
					break
				end
			end
		end
		table.insert(health_bars, {ent = ent, time = focus and math.huge or (RealTime() + life_time * 2)})
	end

	function hitmarkers.ShowAttack(ent, name)
		for i, data in ipairs(weapon_info) do
			if data.ent == ent then
				table.remove(weapon_info, i)
				break
			end
		end

		local length = 2
		table.insert(weapon_info, {name = name, ent = ent, time = RealTime() + length, length = length})
	end

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
			hitmarkers.ShowHealth(ent)
		end
	end

	jrpg.CreateTimer("hitmark", 0.25, 0, function()
		local ply = LocalPlayer()
		if not ply:IsValid() or not ply:GetEyeTrace() then return end

		local data = ply:GetEyeTrace()
		local ent = data.Entity
		if ent:IsNPC() or ent:IsPlayer() then
			hitmarkers.ShowHealth(ent)
		end

		for _, ent in pairs(ents.FindInSphere(ply:GetPos(), 1000)) do
			if ent:IsNPC() or ent:IsPlayer() then
				local wep = ent:GetActiveWeapon()
				local name

				if wep:IsValid() and wep:GetClass() ~= ent.hm_last_wep then
					name = wep:GetClass()
					ent.hm_last_wep = name
				end

				if ent:IsNPC() then
					local seq_name = ent:GetSequenceName(ent:GetSequence()):lower()

					if not seq_name:find("idle") and not seq_name:find("run") and not seq_name:find("walk") then
						local fixed = seq_name:gsub("shoot", "")
						fixed = fixed:gsub("attack", "")
						fixed = fixed:gsub("loop", "")

						if fixed:Trim() == "" or not fixed:find("[a-Z]") then
							name = seq_name
						else
							name = fixed
						end

						name = name:gsub("_", " ")
						name = name:gsub("%d", "")
						name = name:gsub("^%l", function(s) return s:upper() end)
						name = name:gsub(" %l", function(s) return s:upper() end)
						name = name:Trim()

						if name == "" then
							name = seq_name
						end
					end
				end

				if name then
					if language.GetPhrase(name) then
						name = language.GetPhrase(name)
					end

					hitmarkers.ShowAttack(ent, name)
				end
			end
		end
	end)

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

	net.Receive("hitmark_attack", function()
		local ent = net.ReadEntity()
		local str = net.ReadString()

		if language.GetPhrase(str) then
			str = language.GetPhrase(str)
		end

		str = str:gsub("^%l", function(s) return s:upper() end)
		str = str:gsub(" %l", function(s) return s:upper() end)
		str = str:Trim()

		hitmarkers.ShowAttack(ent, str)
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

	function hitmarkers.ShowAttack(ent, str, filter)
		filter = filter or player.GetAll()

		net.Start("hitmark_attack", true)
			net.WriteEntity(ent)
			net.WriteString(str)
		net.Send(filter)
	end

	util.AddNetworkString("hitmark_attack")

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

		jrpg.CreateTimer(tostring(ent).."_hitmarker", 0, 1, function()
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

	jrpg.CreateTimer("hitmarker", 1, 0, function()
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

--if LocalPlayer():IsValid() then hitmarkers.ShowAttack(me, "Blitz") end

return hitmarkers
