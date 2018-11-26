if CLIENT then
    net.Receive("attack_announce", function()
        local ent = net.ReadEntity()
        local str = net.ReadString()

        if language.GetPhrase(str) then
            str = language.GetPhrase(str)
        end

        str = str:gsub("^%l", function(s) return s:upper() end)
        str = str:gsub(" %l", function(s) return s:upper() end)
        str = str:Trim()

        jrpg.ShowAttack(ent, str)
    end)

    local prettytext = requirex("pretty_text")
	local no_texture = Material("vgui/white")
	local draw_rect = requirex("draw_skewed_rect")

	local gradient = Material("gui/gradient_down")
	local border = CreateMaterial(tostring({}), "UnlitGeneric", {
		["$BaseTexture"] = "props/metalduct001a",
		["$VertexAlpha"] = 1,
		["$VertexColor"] = 1,
		["$Additive"] = 1,
	})
    local weapon_info = {}

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

	hook.Add("HUDPaint", "attack_announcer", function()
		if hook.Run("HUDShouldDraw", "Jjrpg") == false then
			return
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

			local x,y,x2,y2 = jrpg.Get2DBoundingBox(ent)
			pos.x = x + (x2-x)*0.5
			pos.y = y - 20

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

					if ent == ply or jrpg.IsFriend(LocalPlayer(), ent) then
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
    end)

    function jrpg.ShowAttack(ent, name)
        for i, data in ipairs(weapon_info) do
            if data.ent == ent then
                table.remove(weapon_info, i)
                break
            end
        end

        local length = 2
        table.insert(weapon_info, {name = name, ent = ent, time = RealTime() + length, length = length})
    end
    
    timer.Create("attack_announce", 0.25, 0, function()
        local ply = LocalPlayer()
		if not ply:IsValid() then return end

        for _, ent in pairs(ents.FindInSphere(ply:GetPos(), 1000)) do
            if ent:IsNPC() or ent:IsPlayer() then
                local name

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

                    jrpg.ShowAttack(ent, name)
                end
            end
        end
    end)
end

if SERVER then
    function jrpg.ShowAttack(ent, str, filter)
        filter = filter or player.GetAll()

        net.Start("attack_announce", true)
            net.WriteEntity(ent)
            net.WriteString(str)
        net.Send(filter)
    end

    util.AddNetworkString("attack_announce")
end
