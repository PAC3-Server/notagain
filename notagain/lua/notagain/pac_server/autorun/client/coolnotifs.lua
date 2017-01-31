surface.CreateFont( "NoticeFont", {
	font = "DermaDefault", 
	size = 20,
	weight = 2000,
	antialias = true
} )


local PANEL = {}

function PANEL:Init()
	self:SetSize(256, 30)
	self:SetContentAlignment(5)
	self:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	self:SetFont("NoticeFont")
	self:SetTextColor(color_white)
end

function PANEL:Paint(w, h)

	surface.SetDrawColor(230, 230, 230, 10)
	surface.DrawRect(0, 0, w, h)

	if (self.start) then
		local w2 = math.TimeFraction(self.start, self.endTime, CurTime()) * w

		surface.SetDrawColor(Color( 0, 0, 0, 230 ))
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(Color(255,255,255))
		surface.DrawRect(w2, h-2, w - w2, 2)
	end

	surface.SetDrawColor(0, 0, 0, 45)
	surface.DrawOutlinedRect(0, 0, w, h)
end

vgui.Register("DNotice", PANEL, "DLabel")

notices = notices or {}

function CoolNotify(message,delay)
	local i = #notices+1
	local scrW = ScrW()
	local notice = vgui.Create("DNotice")
	
	notices[i] = notice
	notice.id = i
	
	notice:SetText(message)
	notice:SetPos(ScrW(), ScrH() - (notice.id - 1) * (notice:GetTall() + 4 	) + 4)
	notice:SizeToContentsX()
	notice:SetWide(notice:GetWide() + 64)
	notice.start = CurTime() + 0.25
	notice.endTime = CurTime() + delay	
	notice.OnRemove = function() 
		notices[notice.id] = nil
	end

	local function OrganizeNotices()
		for k, v in ipairs(notices) do
			if IsValid(v) then
				v:MoveTo(scrW - (v:GetWide()), ScrH() - 40 - ( k - notice.id ) * ( v:GetTall() + 12 ) - notice.id * ( v:GetTall() + 12 ), 0.15, (k / #notices) * 0.25, nil)
			end
		end
	end

	OrganizeNotices()
	
	local function RemoveNotices()
		
		for k,v in pairs(notices) do --Removing NULL panels the hard way
			if not IsValid(v) then
				notices[k] = nil
			end
		end
		
		if IsValid(notice) then		
			notice:MoveTo(ScrW(), notice.y, 0.15, 0.1, nil, function(tbl,pa) pa:Remove() end)
			OrganizeNotices()
		end
		
	end
		
	timer.Simple(delay,RemoveNotices)
end

function notification.AddLegacy(message,type,delay)
	CoolNotify(message,delay)
end

function notification.AddProgress(id,message)
	CoolNotify(message,3)
end

function notification.Kill(id)
	if IsValid(notices[id]) then
		notices[id]:Remove()
	end
end
