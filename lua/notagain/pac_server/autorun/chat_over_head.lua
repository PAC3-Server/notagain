if SERVER then
	util.AddNetworkString("coh")

	net.Receive("coh", function(len, ply)
		net.Start("coh", true)
			local str = net.ReadString()
			if #str > 300 then
				str = str:sub(0,300) .. "..."
			end
			net.WriteEntity(ply)
			net.WriteString(str)
			net.WriteBool(net.ReadBool())
			net.WriteBool(net.ReadBool())
		net.Broadcast()
	end)
end

if CLIENT then
	local background_color = Color(20,20,20,250)
	local border_color = Color(150,150,150,255)
	local border_size = 10
	local text_width_border = 150
	local roundness = 5

	local prettytext = requirex("pretty_text")
	local font = "Square721 BT"
	local size = 500
	local bold = 0
	local blursize = 6
	local shadow_size = 10

	local function DrawChatOverHead()
		if hook.Run("HUDShouldDraw", "ChatOverHead") == false then return end

		local ok = false

		for _, ply in ipairs(player.GetAll()) do
			if ply.coh_text_history and ply.coh_text_history[1] and (ply ~= LocalPlayer() or ply:ShouldDrawLocalPlayer()) then
				--for i, data in ipairs(ply.coh_text_history) do

				ok = true
				local Y = 0
				for i, data in ipairs(ply.coh_text_history) do
					local text = data.str
					if text == "" then text = ("."):rep(math.ceil(os.clock()%3)) end

					local f = data.time == 0 and 1 or -math.min(RealTime() - data.time, 0)

					local alpha = math.min(f * 4, 1)

					if alpha == 0 then
						table.remove(ply.coh_text_history, i)
					end

					local dot = math.max(-EyeVector():Dot(ply:GetAimVector()), 0)*2
					local redline_alpha = alpha * dot

					if ply == LocalPlayer() and ply:ShouldDrawLocalPlayer() then
						alpha = alpha * dot
					end

					background_color.a = math.min(255*alpha, 255)

					surface.SetAlphaMultiplier(alpha)

					local pos, ang

					if ply.pac_editor_camera then
						pos, ang = ply.pac_editor_camera:GetPos(), ply.pac_editor_camera:GetAngles()
					else
						pos, ang = jrpg.FindHeadPos(ply)

						ang = ply:EyeAngles()
					end

					ang.p = 0
					ang.y = ang.y + 90
					ang.r = ang.r + 90

					render.PushFilterMag(TEXFILTER.ANISOTROPIC)
					local scale = ply:GetModelScale() or 1
					cam.Start3D2D(pos + (ang:Right() * -12 * scale), ang, 0.025 * scale)
					local w, h = prettytext.GetTextSize(text, font, size, bold, blursize)
					w = w + text_width_border*2

					local x = -w/2
					local y = Y + -h - 10
					x = x + i * 50

					Y = y

					draw.RoundedBox(roundness, x - border_size + shadow_size, y + -border_size + shadow_size, w + border_size*2, h + border_size*2, Color(0,0,0,50))
					draw.RoundedBox(roundness, x - border_size, y + -border_size, w + border_size*2, h + border_size*2, border_color)

					draw.RoundedBox(roundness, x - border_size, y+ h /2, w + border_size*2, h + border_size - h/2, Color(0,0,0, 150))

					local border_size = border_size * 2
					draw.RoundedBox(roundness, x, y, w, h, background_color)
					draw.RoundedBox(roundness, x + border_size, y+h/2, w - border_size*2, h-h/2 - border_size, Color(0,0,0, 50))
					border_size = border_size / 2

					local y_offset = 0
					for i, line in ipairs(text:Split("\n")) do
						local _, h_ = prettytext.Draw(
							line,
							x + text_width_border,
							y + y_offset,
							font,
							size,
							bold,
							blursize,
							Color(255,255,255,255*alpha),
							Color(200, 200, 200, 255)
						)
						y_offset = y_offset + h_

						if not data.entered and data.time ~= 0 then
							surface.SetDrawColor(150, 0, 0, 230*alpha*redline_alpha)
							surface.DrawRect(x + text_width_border, y + y_offset - h_/2, w-text_width_border*2, 10)
						end

					end

					local width = 50
					local xpos = x + 20
					local x = 200
					local xpos = 0
					local w = 0

					if i == 1 then
						surface.SetDrawColor(0, 0, 0, 50*alpha/2)
						draw.NoTexture()
						surface.DrawPoly({
							{ x = x + shadow_size + w - xpos + border_size, y = y + h + shadow_size + border_size},
							{ x = x + shadow_size + w - xpos - width - border_size*0.75, y = y + (h+100 + border_size*4) + shadow_size},
							{ x = x + shadow_size + w - xpos - width - border_size, y = y + h + shadow_size + border_size}
						})

						surface.SetDrawColor(border_color.r/1.5, border_color.g/1.5, border_color.b/1.5, 255*alpha)
						draw.NoTexture()
						surface.DrawPoly({
							{ x = x + w - xpos + border_size, y = y + h},
							{ x = x + w - xpos - width - border_size*0.75, y = y + h+100 + border_size*4},
							{ x = x + w - xpos - width - border_size, y = y + h}
						})

						surface.SetDrawColor(background_color)
						draw.NoTexture()
						surface.DrawPoly({
							{ x = x + w - xpos, y = y + h },
							{ x = x + w - xpos - width, y = y + h+100 },
							{ x = x + w - xpos - width, y = y + h }
						})
					end
					--surface.SetDrawColor(255,255,255,255)
					--surface.SetMaterial(gradient)
					--draw_rect(x,y, w, h, 0, border_size, 5, 0, gradient:GetTexture("$BaseTexture"):Width())

					cam.End3D2D()
					render.PopFilterMag(TEXFILTER.ANISOTROPIC)

					surface.SetAlphaMultiplier(1)
				end
			end
		end

		if not ok then
			hook.Remove("PostDrawTranslucentRenderables", "coh")
		end
	end


	local history_time = 8

	local function add_text(ply, str, change, entered)
		ply.coh_text_history = ply.coh_text_history or {}

		if #ply.coh_text_history > 10 then
			table.remove(ply.coh_text_history)
		end

		if change then
			if ply.coh_text_history[1] and ply.coh_text_history[1].time ~= 0 then
				table.insert(ply.coh_text_history, 1, {str = str, time = 0})
			end
			ply.coh_text_history[1] = {str = str, time = 0}
		elseif str == "" then
			table.remove(ply.coh_text_history, 1)
		else
			table.remove(ply.coh_text_history, 1)
			table.insert(ply.coh_text_history, 1, {str = str, time = RealTime() + history_time, entered = entered})
		end


		hook.Add("PostDrawTranslucentRenderables", "coh", DrawChatOverHead)
	end

	net.Receive("coh",function(len)
		local ply = net.ReadEntity()
		if ply:IsValid() then
			local str = net.ReadString()
			local change = net.ReadBool()
			local entered = net.ReadBool()

			add_text(ply, str, change, entered)
		end
	end)

	local function send_text(str, change, entered)
		net.Start("coh", true)
			net.WriteString(str)
			net.WriteBool(change)
			net.WriteBool(entered)
		net.SendToServer()
	end

	local wrote = ""

	hook.Add("StartChat", "coh", function()
		send_text("", true)
		wrote = ""
	end)

	hook.Add("FinishChat", "coh", function()
		send_text(wrote, false, input.IsKeyDown(KEY_ENTER) or input.IsKeyDown(KEY_PAD_ENTER))
		wrote = ""
	end)

	hook.Add("ChatAutoCompleteChanged", "coh", function(res)
		send_text(res, true)
		wrote = res
	end)

	hook.Add("ChatTextChanged", "coh", function(text)
		if #text <= 1 then
			send_text(wrote, false, false)
		end
		wrote = text
		send_text(text, true)
	end)
end
