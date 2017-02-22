
AddCSLuaFile() 

local scrW, scrH = ScrW(), ScrH()
local ResolutionScale = math.Min(scrW/1600 , scrH/900)

ActiveAlert = nil

surface.CreateFont( "JFont", { font = "arial.ttf" , size = 18 , weight = 600 } )

local ALERT = {
	Init = function( self )
			
		self:SetTextColor(color_white)
		self:SetFont("JFont")
		self:SetSize(256, 30)
		self:SetContentAlignment(5)
		self:SetExpensiveShadow(1, Color(0, 0, 0, 150))

	end,

	Paint = function( self , w , h )
		local Poly = {
	        { x = (25/ ResolutionScale),  y = h }, --100/200
	        { x = 0,                      y = 0 }, --100/100
	        { x = w, 					  y = 0 }, --200/100
	        { x = w-(25/ ResolutionScale),y = h }, --200/200
	    }

	    draw.NoTexture()
		surface.SetDrawColor( math.abs(math.sin(CurTime()*3)*255), 0, math.abs(math.sin(CurTime()*3)*255)/4, 200)
		surface.DrawPoly(Poly)

	end,
}

vgui.Register( "DAlert" , ALERT , "DLabel" )

function Alert( message , time )
	
	RemoveAlert() --So we don't have overlaping alerts
	
	local JAlert = vgui.Create( "DAlert" )
	JAlert:SetText( message )
	JAlert:SizeToContentsX()
	JAlert:SetWide((JAlert:GetWide() + 64/ResolutionScale > 800) and JAlert:GetWide() + 64/ResolutionScale or 800 )
	JAlert:SetPos( scrW/2-JAlert:GetWide()/2, -JAlert:GetTall() ) 
	JAlert:MoveTo( JAlert.x , 0 , 0.35, 0.3)
	JAlert.Removal = CurTime()+150 --150s max time

	JAlert.Think = function() -- ermergency removal
		if JAlert.Removal <= CurTime() then
			JAlert:MoveTo( JAlert.x , -JAlert:GetTall(), 0.35, 0.3, nil, function() JAlert:Remove() end)
			ActiveAlert = nil
		end
	end
	
	ActiveAlert = JAlert

	timer.Simple(time or 10,RemoveAlert)

	
end

function RemoveAlert()
	if IsValid(ActiveAlert) then
		local temp = ActiveAlert
		ActiveAlert = nil
		temp:MoveTo( temp.x , -temp:GetTall(), 0.35, 0.3, nil, function() temp:Remove() end)
	end
end

