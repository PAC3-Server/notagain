if SERVER then
	timer.Create("juse", 0.5, 0, function()
		for _, ply in ipairs(player.GetAll()) do
			ply:SetNWEntity("juse_ent", NULL)
			if (ply:GetInfoNum("ctp_enabled", 0) == 1 or ply:GetInfoNum("battlecam_enabled", 0) == 1) and jrpg.IsEnabled(ply) then
				local found = {}
				for _, ent in pairs(ents.FindInSphere(ply:EyePos(), 70)) do
					if ent ~= ply then
						local name = ent:GetClass()
						if ent ~= ply then
							local val
							local savetable = ent:GetSaveTable()
							if jrpg.IsActor(ent) then
								if jrpg.IsFriend(ply, ent) then
									val = ent
								end
							elseif
								name ~= "trigger_push" and
								(
									name:find("button") or
									name:find("door") or
									name == "func_movelinear" or
									savetable.m_toggle_state or
									savetable.m_eDoorState or
									name == "item_healthcharger" or
									name == "item_suitcharger"
								)
							then
								val = ent
							end

							if val then
								local dist = ent:NearestPoint(ply:EyePos()):Distance(ply:EyePos())
								-- this means we're inside which can be confusing for invisible triggers
								if dist == 0 then
									dist = 9999
								end

								table.insert(found, {ent = val, dist = dist})
							end
						end
					end
				end
				if found[1] then
					table.sort(found, function(a, b) return a.dist < b.dist end)
					local ent = found[1].ent

					ply:SetNWEntity("juse_ent", ent)

					local text = "examine"

					if jrpg.IsActor(ent) then
						text = "talk"
					else
						local savetable = ent:GetSaveTable()

						if savetable.m_toggle_state then
							if savetable.m_toggle_state == 0 then
								text = "close"
							else
								text = "open"
							end
						elseif savetable.m_eDoorState then
							if savetable.m_eDoorState ~= 0 then
								text = "close"
							else
								text = "open"
							end
						else
							text = "use"
						end
					end

					ply:SetNWString("juse_text", text)
				end
			end
		end
	end)

	hook.Add("KeyPress", "juse", function(ply, key)
		if key ~= IN_USE then return end
		local button = ply:GetNWEntity("juse_ent")
		if button:IsValid() then
			local savetable = button:GetSaveTable()

			if savetable.m_toggle_state then
				if savetable.m_toggle_state == 0 then
					button:Fire("close")
				else
					button:Fire("open")
				end
			elseif savetable.m_eDoorState then
				if savetable.m_toggle_state ~= 0 then
					button:Fire("close")
				else
					button:Fire("open")
				end
			else
				button:Use(ply, ply, USE_TOGGLE, 1)
				button:Use(ply, ply, USE_ON, 1)
			end
			ply:SetEyeAngles(((button:IsNPC() and button:EyePos() or button:WorldSpaceCenter()) - ply:EyePos()):Angle())

			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence("gesture_item_" .. (ply.GetActiveWeapon and "wave" or "give")) , 0.5, true)

			net.Start("juse")
				net.WriteEntity(ply)
				net.WriteEntity(button)
			net.Broadcast()
		end
	end)

	hook.Add("PlayerUse", "juse", function(ply, ent)
		if ply:GetNWEntity("juse_ent") == ent then
			if ent:GetClass() == "item_suitcharger" or ent:GetClass() == "item_healthcharger" then return end
			return false
		end
	end)

	util.AddNetworkString("juse")
end

if CLIENT then
	net.Receive("juse", function()
		local ply = net.ReadEntity()
		local ent = net.ReadEntity()

		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence("gesture_item_" .. (ply.GetActiveWeapon and "wave" or "give")) , 0.5, true)

		if ply:IsValid() and ent:IsValid() then
			hook.Run("PlayerUsedEntity", ply, ent)
		end
	end)



	local prettytext = requirex("pretty_text")
	local jfx = requirex("jfx")
	local gradient = Material("gui/center_gradient")
	local crosshair = jfx.CreateMaterial({
			Shader = "UnlitGeneric",
			BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/crosshair.png",
			VertexColor = 1,
			VertexAlpha = 1,
			Additive = 1,
	})

	local fade_in_time
	local fade_out_time
	local last_pos
	local last_str

	hook.Add("HUDPaint", "juse", function()
		if jtarget.GetEntity(LocalPlayer()):IsValid() then return end
		if jchat.IsActive() then return end

		local ent = LocalPlayer():GetNWEntity("juse_ent")

		if ent:IsPlayer() or ent:IsNPC() then
			healthbars.ShowHealth(ent)
		end

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

		local txt_size = 35
		local border = 20
		local x = ScrW()/2
		local y = ScrH()/3
		local key = input.LookupBinding("+use"):upper() or input.LookupBinding("+use")
		local str = LocalPlayer():GetNWString("juse_text", "examine"):upper()
		last_str = str
		local w,h = prettytext.GetTextSize(str, "Square721 BT", txt_size, 0, 3)
		local key_width, key_height = prettytext.GetTextSize(key or "E", "Square721 BT", txt_size, 0, 3)
		local bg_width = w + 100

		surface.SetDrawColor(0,0,0,200*fade_out)
		surface.SetMaterial(gradient)
		surface.DrawTexturedRect(x - bg_width, y - 8/2, bg_width * 2, h + 8)

		surface.SetDrawColor(255,255,255,255*fade_out)
		draw.RoundedBox(4, x - key_width*2 - w/2 - key_width*0.25, y + border-16, key_width*1.5, key_height/1.3, Color(25,25,25,255*fade_out))

		prettytext.Draw(str, x - w / 2, y, "Square721 BT", txt_size, 0, 3, Color(255, 255, 255, 255*fade_out))
		prettytext.Draw(key, x - key_width*2 - w/2, y, "Square721 BT", txt_size, 0, 3, Color(255, 255, 255, 255*fade_out))

	end)
end
