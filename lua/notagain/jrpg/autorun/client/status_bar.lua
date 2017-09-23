do
	local gr_dw_id = surface.GetTextureID("gui/gradient_down")

	if IsValid(_G.STATUS) then
		_G.STATUS:Remove()
	end

	local spacing = 15
	local fps = 1
	timer.Create("status_update_fps,",1,0,function()
		self.fps = math.ceil(1/RealFrameTime())
	end)

	local status = {
		ScrW = ScrW(),
		ScrH = ScrH(),
		Init = function(self)
			self:SetSize(self.ScrW,30)
			self:SetPos(0,self.ScrH-30)
			self:SetZPos(-999)
		end,
		Paint = function(self,w,h)
			local ply = LocalPlayer()
			if ply.IsRPG and not ply:IsRPG() then return end

			surface.SetDrawColor(0,0,0,255)
			surface.DrawRect(0,0,w,h)
			surface.SetTexture(gr_dw_id)
			surface.SetDrawColor(60,60,60,255)
			surface.DrawTexturedRect(0,0,w,h)
			surface.SetDrawColor(130,130,130,255)
			surface.DrawLine(0,0,w,0)


			--playtime
			local formattedtime = ply.GetNiceTotalTime and ply:GetNiceTotalTime() or {h = 0,m = 0,s = 0}
			local time = formattedtime.h >= 1 and formattedtime.h or formattedtime.m
			local unit = formattedtime.h >= 1 and "h" or "min"
			local str = "⏰ "..time..unit

			local text_y = h/2
			local text_x = spacing
			local play_w = prettytext.DrawText({
				text = str,
				size = 16,
				blur_size = 4,
				blur_overdraw = 3,
				x = text_x,
				y = text_y,
				y_align = -0.5,
			})

			--lvl
			str = "~Lvl."..(ply.GetLevel and ply:GetLevel() or 0)
			text_x = text_x + play_w + spacing
			local lvl_w = prettytext.DrawText({
				text = str,
				size = 16,
				blur_size = 4,
				blur_overdraw = 3,
				x = text_x,
				y = text_y,
				y_align = -0.5,
			})
			--ping
			str = "@ "..ply:Ping().."ms"
			text_x = text_x + lvl_w + spacing
			local ping_w = prettytext.DrawText({
				text = str,
				size = 16,
				blur_size = 4,
				blur_overdraw = 3,
				x = text_x,
				y = text_y,
				y_align = -0.5,
			})

			--fps
			str = "	↺ "..fps.."fps"
			text_x = text_x + ping_w
			local fps_w = prettytext.DrawText({
				text = str,
				size = 16,
				blur_size = 4,
				blur_overdraw = 3,
				x = text_x,
				y = text_y,
				y_align = -0.5,
			})

			str = "⌛ "..os.date("%H:%M:%S")
			text_x = text_x + fps_w + spacing
			prettytext.DrawText({
				text = str,
				size = 16,
				blur_size = 4,
				blur_overdraw = 3,
				x = text_x,
				y = text_y,
				y_align = -0.5,
			})
		end,
		Think = function(self)
			if self.ScrW ~= ScrW() or self.ScrH ~= ScrH() then
				self.ScrH = ScrH()
				self.ScrW = ScrW()
				self:Init()
			end
		end,
	}

	vgui.Register("status_panel",status,"DPanel")
end
