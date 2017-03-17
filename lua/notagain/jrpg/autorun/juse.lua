if SERVER then
	timer.Create("juse", 0.5, 0, function()
		for _, ply in pairs(player.GetAll()) do
			ply:SetNWEntity("juse_ent", NULL)
			if ply:GetInfoNum("ctp_enabled", 0) == 1 or ply:GetInfoNum("battlecam_enabled", 0) == 1 then
				local found = {}
				for _, ent in pairs(ents.FindInSphere(ply:EyePos(), 70)) do
					local name = ent:GetClass()
					if name:find("button") or name == "func_movelinear" then
						table.insert(found, {ent = ent, dist = ent:NearestPoint(ply:EyePos()):Distance(ply:EyePos())})
					end
				end
				if found[1] then
					table.sort(found, function(a, b) return a.dist < b.dist end)
					ply:SetNWEntity("juse_ent", found[1].ent)
				end
			end
		end
	end)

	hook.Add("KeyPress", "juse", function(ply, key)
		if key ~= IN_USE then return end
		local button = ply:GetNWEntity("juse_ent")
		if button:IsValid() then
			button:Use(ply, ply, USE_TOGGLE, 1)
			button:Use(ply, ply, USE_ON, 1)
			ply:SetEyeAngles((button:WorldSpaceCenter() - ply:EyePos()):Angle())
		end
	end)

	hook.Add("PlayerUse", "juse", function(ply, ent)
		if ply:GetNWEntity("juse_ent") == ent then
			return false
		end
	end)
end

if CLIENT then
	local prettytext = requirex("pretty_text")
	local jfx = requirex("jfx")
	local gradient = Material("gui/center_gradient")
	local crosshair = jfx.CreateMaterial({
			Shader = "UnlitGeneric",
			BaseTexture = "https://cdn.discordapp.com/attachments/273575417401573377/292078741830762496/crosshair.png",
			VertexColor = 1,
			VertexAlpha = 1,
			Additive = 1,
	})

	local fade_in_time
	local fade_out_time
	local last_pos

	hook.Add("HUDPaint", "juse", function()
		local ent = LocalPlayer():GetNWEntity("juse_ent")
		if not ent:IsValid() then
			fade_in_time = nil
			fade_out_time = fade_out_time or (RealTime() + 1)
		else
			fade_out_time = nil
			fade_in_time = fade_in_time or (RealTime() + 1)
		end

		local fade_in = fade_in_time and math.max(fade_in_time - RealTime(), 0) or 0
		local fade_out = fade_out_time and math.max(fade_out_time - RealTime(), 0) or 1

		if fade_out_time and (fade_out == 0 or not last_pos) then
			return
		end

		fade_in = fade_in ^ 10
		fade_out = fade_out ^ 5

		local wpos = ent:IsValid() and ent:WorldSpaceCenter() or last_pos
		last_pos = wpos

		local pos = wpos:ToScreen()
		local size = 120+(fade_in*50)
		if fade_out_time then
			size = size + (-fade_out+1)*50
		end
		surface.SetDrawColor(255, 255, 255, 255*fade_out)
		surface.SetMaterial(crosshair)
		surface.DrawTexturedRectRotated(pos.x, pos.y, size,size, os.clock()*-90)

		local txt_size = 70
		local border = 20
		local x = ScrW()/2
		local y = ScrH()/3
		local key = input.LookupBinding("+use"):upper() or input.LookupBinding("+use")
		local str = "EXAMINE"
		local w,h = prettytext.GetTextSize(str, "gabriola", txt_size, 0, 3)
		local key_width, key_height = prettytext.GetTextSize(key, "gabriola", txt_size, 0, 3)
		local bg_width = w + 100

		surface.SetDrawColor(0,0,0,200*fade_out)
		surface.SetMaterial(gradient)
		surface.DrawTexturedRect(x - bg_width, y + h/8, bg_width * 2, h/1.3)

		surface.SetDrawColor(255,255,255,255*fade_out)
		draw.RoundedBox(4, x - key_width*2 - w/2 - key_width*0.25, y + border, key_width*1.5, key_height/2.2, Color(25,25,25,255*fade_out))
		prettytext.Draw(str, x - w / 2, y, "gabriola", txt_size, 0, 3, Color(255, 255, 255, 255*fade_out))

		prettytext.Draw(key, x - key_width*2 - w/2, y, "gabriola", txt_size, 0, 3, Color(255, 255, 255, 255*fade_out))

	end)
end