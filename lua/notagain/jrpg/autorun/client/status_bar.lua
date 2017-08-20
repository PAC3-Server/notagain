local gr_dw_id = surface.GetTextureID("gui/gradient_down")

surface.CreateFont("hud_status_font",{
	font = "Square721 BT",
	outline = true,
	weight = 700,
	size = 16,
	additive = false,
	extended = true,
})

if IsValid(_G.STATUS) then
	_G.STATUS:Remove()
end

local spacing = 15
local fps = 1
timer.Create("status_update_fps,",1,0,function()
	fps = math.ceil(1/RealFrameTime())
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
		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(0,0,w,h)
		surface.SetTexture(gr_dw_id)
		surface.SetDrawColor(60,60,60,255)
		surface.DrawTexturedRect(0,0,w,h)
		surface.SetDrawColor(130,130,130,255)
		surface.DrawLine(0,0,w,0)

		--draw.NoTexture()
		surface.SetFont("hud_status_font")
		surface.SetTextColor(200,200,200,255) --omg i forgot that

		--playtime
		local formattedtime = ply.GetNiceTotalTime and ply:GetNiceTotalTime() or {h = 0,m = 0,s = 0}
		local time = formattedtime.h >= 1 and formattedtime.h or formattedtime.m
		local unit = formattedtime.h >= 1 and "h" or "min"
		local str = "⏰ "..time..unit

		local play_w,play_h = surface.GetTextSize(str)
		local text_y = h/2-play_h/2
		local text_x = spacing
		surface.SetTextPos(text_x,text_y)
		surface.DrawText(str)

		--lvl
		str = "~Lvl."..(ply.GetLevel and ply:GetLevel() or 0)
		text_x = text_x + play_w + spacing
		surface.SetTextPos(text_x,text_y)
		surface.DrawText(str)
		local lvl_w = (surface.GetTextSize(str))

		--ping
		str = "@ "..ply:Ping().."ms"
		text_x = text_x + lvl_w + spacing
		surface.SetTextPos(text_x,text_y)
		surface.DrawText(str)
		local ping_w = (surface.GetTextSize(str))

		--fps
		str = "	↺ "..fps.."fps"
		text_x = text_x + ping_w
		surface.SetTextPos(text_x,text_y)
		surface.DrawText(str)
		local fps_w = (surface.GetTextSize(str))

		str = "⌛ "..os.date("%H:%M:%S")
		local time_w = (surface.GetTextSize(str))
		text_x = w - spacing - time_w
		surface.SetTextPos(text_x,text_y)
		surface.DrawText(str)
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

local convar = CreateConVar("rpg_status_bar","1",FCVAR_ARCHIVE,"Enable or disable the rpg status bar")
cvars.AddChangeCallback("rpg_status_bar",function(name,old,new)
	if convar:GetBool() then
		if not IsValid(_G.STATUS) then
			_G.STATUS = vgui.Create("status_panel")
		end
	else
		if IsValid(_G.STATUS) then
			_G.STATUS:Remove()
		end
	end
end)

hook.Add("InitPostEntity","ShowStatusPanel",function()
	if convar:GetBool() then
		_G.STATUS = vgui.Create("status_panel")
	end
end)
