local scrW, scrH = ScrW(), ScrH()
local ResolutionScale = math.Min(scrW/1600 , scrH/900)
local JAlert = {}
_G.JAlert = JAlert

surface.CreateFont("JAlertFont",{
    font      = "Square721 BT",
    extended  = true,
    size      = 17,
    weight    = 500,
    shadow    = true,
})

local ALERT = {
	Init = function( self )
		self:SetTextColor(color_white)
		self:SetFont("JAlertFont")
		self:SetSize(256, 30)
		self:SetContentAlignment(5)
		self:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	end,

	Paint = function( self , w , h )
		local Poly = {
	        { x = (25/ ResolutionScale),  y = h },
	        { x = 0,                      y = 0 },
	        { x = w, 					  y = 0 },
	        { x = w-(25/ ResolutionScale),y = h },
	    }
	    draw.NoTexture()
		surface.SetDrawColor( math.abs(math.sin(CurTime()*3)*255), 0, math.abs(math.sin(CurTime()*3)*255)/4, 200)
		surface.DrawPoly(Poly)
	end,
}

vgui.Register("DAlert",ALERT,"DLabel" )

JAlert.ActiveAlert = NULL
JAlert.DoAlert = function(message,time)
    if not message or type(message) ~= "string" then return end
	JAlert.RemoveAlert()

	local alert = vgui.Create("DAlert")
	alert:SetText(message)
	alert:SizeToContentsX()
	alert:SetWide((alert:GetWide() + 64/ResolutionScale > 800) and alert:GetWide() + 64/ResolutionScale or 800)
	alert:SetPos(scrW/2-alert:GetWide()/2, -alert:GetTall())
	alert:MoveTo(alert.x,0,0.35,0.3)

    local time = time or 10
    if time <= 0 then
        time = 10
    elseif time >= 30 then
        time = 30
    end

    JAlert.ActiveAlert = alert
    alert.Removal = CurTime() + time
    alert.Think = function(self)
		if self.Removal <= CurTime() then
			self:MoveTo(self.x,-self:GetTall(),0.35,0.3,nil,function() self:Remove() end)
			JAlert.ActiveAlert = NULL
		end
	end

end

JAlert.RemoveAlert = function()
	if IsValid(JAlert.ActiveAlert) then
		local temp = JAlert.ActiveAlert
		JAlert.ActiveAlert = NULL
		temp:MoveTo(temp.x ,-temp:GetTall(),0.35,0.3,nil,function() temp:Remove() end)
	end
end
