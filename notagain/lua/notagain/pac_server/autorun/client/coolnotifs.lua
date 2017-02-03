surface.CreateFont( "NoticeFont", {
    font      = "Arial",
    size      = 18,
    weight    = 600,
} )

local scrW, scrH = ScrW(), ScrH()
local resolutionScale = math.Min(scrW/1600 , scrH/900)
local PANEL = {}

function PANEL:Init()
	self:SetSize(256, 30)
	self:SetContentAlignment(5)
	self:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	self:SetFont("NoticeFont")
	self:SetTextColor(color_white)
end

function PANEL:Paint(w, h)

	local Poly = {
        { x = 0,   					y = h }, --100/200
        { x = (25/ resolutionScale),y = 0 }, --100/100
        { x = w, 					y = 0 }, --200/100
        { x = w,                    y = h }, --200/200
    }
    draw.NoTexture()
	surface.SetDrawColor(0, 97, 155, 225)
	surface.DrawPoly(Poly)

	if (self.start) then
		local w2 = math.TimeFraction(self.start, self.endTime, CurTime()) * w
		surface.SetDrawColor(255,255,255)
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
