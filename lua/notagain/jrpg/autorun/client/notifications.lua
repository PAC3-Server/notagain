surface.CreateFont( "NoticeFont", {
    font      = "Square721 BT",
    extended  = true,
    size      = 17,
    weight    = 500,
    shadow    = true,
} )

local scrW, scrH = ScrW(), ScrH()
local resolutionScale = math.Min(scrW/1600 , scrH/900)

local PANEL = {

	Init = function( self )
		self:SetSize(256, 30)
		self:SetContentAlignment(5)
		self:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		self:SetFont("NoticeFont")
		self:SetTextColor(color_white)
	end,

	Paint = function ( self , w , h)

		local PolyOutter = {
	        { x = (25/ resolutionScale),y = h }, --100/200
	        { x = 0,                    y = 0 }, --100/100
	        { x = w, 					y = 0 }, --200/100
	        { x = w,                    y = h }, --200/200
	    }
        local PolyInner = {
	        { x = (25/ resolutionScale),   	y = h }, --100/200
	        { x = 5,                        y = 5 }, --100/100
	        { x = w, 					    y = 5 }, --200/100
	        { x = w,                        y = h }, --200/200
	    }
	    draw.NoTexture()
		surface.SetDrawColor(0,0,0,175)
		surface.DrawPoly(PolyOutter)
        surface.SetDrawColor(43,43,43,200)
		surface.DrawPoly(PolyInner)

		if (self.start) then
			local w2 = math.TimeFraction(self.start, self.endTime, CurTime()) * w
			surface.SetDrawColor(225,225,225)
			surface.DrawRect(w2,h-4,w - w2,4)
		end

	end

}

vgui.Register("DNotice", PANEL, "DLabel")

local notices = {}

local CoolNotify = function(message,delay)
	local scrW = ScrW()
	local notice = vgui.Create("DNotice")
	notice.id = #notices + 1
	table.insert(notices,notice.id,notice)
	notice:SetText(message)
	notice:SetPos(ScrW(), ScrH() - (notice.id - 1) * (notice:GetTall() + 4 	) + 4)
	notice:SizeToContentsX()
	notice:SetWide(notice:GetWide() + 64)
	notice.start = CurTime()
	notice.endTime = CurTime() + delay

    local OrganizeNotices = function()
        for k, v in ipairs(notices) do
            if IsValid(v) then
                v:MoveTo(scrW - (v:GetWide()), ScrH() - 40 - ( k - notice.id ) * ( v:GetTall() + 12 ) - notice.id * ( v:GetTall() + 12 ), 0.15, (k / #notices) * 0.25, nil)
            end
        end
    end

    OrganizeNotices()

	notice.Think = function(self)
        if CurTime() >= self.endTime then
            table.remove(notices,self.id)
            self:MoveTo(ScrW(), notice.y, 0.15, 0.1, nil, function() self:Remove() end)
            OrganizeNotices()
        end
    end
end

notification.old_AddLegacy = notification.old_AddLegacy or notification.AddLegacy
notification.old_AddProgress = notification.old_AddProgress or notification.AddProgress
notification.old_Kill = notification.old_Kill or notification.Kill

notification.AddLegacy = function(message,type,delay)
	CoolNotify(message,delay)
end

notification.AddProgress = function(id,message)
	CoolNotify(message,3)
end

notification.Kill = function(id)
	if IsValid(notices[id]) then
		notices[id]:MoveTo(ScrW(),notices[id].y, 0.15, 0.1, nil, function() notices[id]:Remove() end)
        table.remove(notices,id)
	end
end

notification.GetActives = function()
    return notices
end
