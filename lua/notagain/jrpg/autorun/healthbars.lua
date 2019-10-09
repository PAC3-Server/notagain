local healthbars = {}

if CLIENT then
    local prettytext = requirex("pretty_text")
	local draw_line = requirex("draw_line")
	local draw_rect = requirex("draw_skewed_rect")

    local line_mat = Material("particle/Particle_Glow_04")

	local line_width = 12
	local line_height = -10
	local max_bounce = 2
	local bounce_plane_height = 0

	local life_time = 3
	local hitmarks = {}
	local height_offset = 0

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

    local health_bars = {}

	hook.Add("HUDDrawTargetID", "healthbars", function()
		return false
	end)

    hook.Add("HUDPaint", "healthbars", function()
        if hook.Run("HUDShouldDraw", "Jhealthbars") == false then
            return
        end

        local ply = LocalPlayer()
        local boss_bar_y = 0

        for i = #health_bars, 1, -1 do
            local data = health_bars[i]
            local ent = data.ent

            if ent:IsValid() then
                local name = jrpg.GetFriendlyName(ent)
                ent = jrpg.GetActorBody(ent)

                local t = RealTime()
                local fraction = (data.time - t) / life_time * 2

                local world_pos = (ent:NearestPoint(ent:EyePos() + Vector(0,0,100000)) + Vector(0,0,2))
                local pos = world_pos:ToScreen()
                local dist = world_pos:Distance(EyePos())

                local x,y,x2,y2 = jrpg.Get2DBoundingBox(ent)
                pos.x = x + (x2-x)*0.5
                pos.y = y - 20

                local scale = ent:GetModelScale() and ent:GetModelScale() or 1
                local radius = ent:BoundingRadius() * 5
                local max_distance = scale * radius
                fraction = fraction * ((-(dist / max_distance)+1) ^ 2)

                --ent.hm_pixvis = ent.hm_pixvis or util.GetPixelVisibleHandle()
                --ent.hm_pixvis_vis = util.PixelVisible(world_pos, ent:BoundingRadius()/5, ent.hm_pixvis)
                local vis = 1--ent.hm_pixvis_vis
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
                        --width = math.Clamp(width + (max - 50), 0, 500)
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
    end)


	timer.Create("healthbars", 0.25, 0, function()
		local ply = LocalPlayer()
		if not ply:IsValid() or not ply:GetEyeTrace() then return end

		local data = ply:GetEyeTrace()
		local ent = data.Entity
		if ent:IsNPC() or (jrpg.IsEnabled(ply) and ent:IsPlayer()) then
			healthbars.ShowHealth(ent)
		end
	end)


    function healthbars.ShowHealth(ent, focus)
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
end

_G.healthbars = healthbars