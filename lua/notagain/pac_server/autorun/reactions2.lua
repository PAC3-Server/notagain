--
react = {}

if SERVER then
	util.AddNetworkString("R2_sendlist")
	util.AddNetworkString("R2_requestlist")
	util.AddNetworkString("R2_reaction")

	local dat = util.JSONToTable(file.Read("addons/misc/lua/autorun/reactions.json","GAME"))
	net.Receive("R2_requestlist",function(_,ply)
		net.Start("R2_sendlist")
		net.WriteTable(dat)
		net.Send(ply)
	end)
	net.Receive("R2_reaction",function(_,ply)
		local url = net.ReadString()
		local web = net.ReadBool()
		if(url == nil or web == nil)then
			return
		end
		net.Start("R2_reaction")
		net.WriteString(url)
		net.WriteBool(web)
		net.WriteEntity(ply)
		net.Broadcast()
	end)
end

if CLIENT then

	react.Reactions = {}

	react.CreateMenu = function()
		react.Menu = vgui.Create("DFrame")
		react.Menu:SetTitle("")
		react.Menu:SetSize(300,300)
		react.Menu:SetDeleteOnClose(false)
		react.Menu:SetScreenLock(true)
		react.Menu:ShowCloseButton(false)
		react.Menu:SetPos(0,ScrH()-react.Menu:GetTall())
		react.Menu:Hide()
		react.Menu.Paint = function()
			draw.RoundedBoxEx(4,0,0,react.Menu:GetWide(),react.Menu:GetTall(),Color(100,100,255,255),true,true,false,false)
			surface.SetDrawColor(100,100,100,255)
			surface.DrawRect(4,25,react.Menu:GetWide()-8,react.Menu:GetTall()-29)
			draw.SimpleText("Reactions","R2Font2",(react.Menu:GetWide()/2)+2,7,Color(0,0,0,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
			draw.SimpleText("Reactions","R2Font2",react.Menu:GetWide()/2,5,Color(255,255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
		end
	end

	net.Receive("R2_sendlist",function()
		react.Emotes = net.ReadTable()
		react.PopulateMenu()
	end)

	net.Receive("R2_reaction",function()
		local path = net.ReadString()
		local web = net.ReadBool()
		local ply = net.ReadEntity()
		if web then
			path = react.WebMaterial(path)
		end
		react.Reactions[ply] = {path = path,web = web,time = SysTime()}
		timer.Create(ply:SteamID(),7,1,function()
			react.Reactions[ply] = nil
		end)
	end)

	local magicNumbers = {
		png = string.char(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A),
		jpg = string.char(0xFF, 0xD8, 0xFF, 0xDB)
	}

	react.WebMaterial = function(url)
		local filename = url:Split('/')
		filename = filename[#filename]:match('(.*)%.') .. '.png'
		if(!file.Exists("webmaterial/" .. filename,"DATA"))then
			file.CreateDir('webmaterial')
			http.Fetch(url, function(body, len, headers, code)
				if not body:match('^' .. magicNumbers.png) and not body:match('^' .. magicNumbers.jpg) then return end
				if code < 200 or code >= 400 then return end
				file.Write('webmaterial/' .. filename, body)
			end)
		end
		return "../data/webmaterial/"..filename
	end

	surface.CreateFont("R2Font",{
		font = "Roboto Bk",
		size = 14
	})
	surface.CreateFont("R2Font2",{
		font = "Roboto Bk",
		size = 18
	})

	react.GetButtonPaint = function(path,web,panel)
		return function()
			draw.RoundedBox(4,4,4,panel:GetWide()-8,panel:GetTall()-8,Color(100,100,255,255))
			surface.SetDrawColor(255,255,255,255)
			surface.DrawRect(8,8,panel:GetWide()-16,panel:GetTall()-16)
			local mat
			if(web)then
				mat = Material(react.WebMaterial(path))
			else
				mat = Material(path)
			end
			surface.SetMaterial(mat)
			surface.DrawTexturedRect((panel:GetWide()/2)-panel:GetWide()/4,(panel:GetTall()/2)-panel:GetWide()/4,panel:GetWide()/2,panel:GetTall()/2)
		end
	end

	react.PopulateMenu = function()
		if(!IsValid(react.Menu))then
			react.CreateMenu()
		end

		local CategoryTabs = vgui.Create("DPropertySheet",react.Menu)
		CategoryTabs:Dock(FILL)
		CategoryTabs:SetFadeTime(0)
		CategoryTabs.Paint = function()
			draw.RoundedBoxEx(4,0,20,CategoryTabs:GetWide(),CategoryTabs:GetTall(),Color(255,255,255,255),true,true,false,false)
		end

		local size = (react.Menu:GetWide()/5)-5
		for k,v in pairs(react.Emotes) do
			local x = 0
			local y = 0
			local ScrollPanel = vgui.Create("DScrollPanel",CategoryTabs)
			ScrollPanel:Dock(FILL)
			if(v.files != nil)then
				for k,v in pairs(v.files)do
					local butt = ScrollPanel:Add("DButton")
					butt:SetText("")
					butt:SetSize(size,size)
					butt:SetPos(x,y)
					butt.Paint = react.GetButtonPaint(v,false,butt)
					butt.DoClick = function()
						react.SendReaction(v,false)
					end
					x=x+size
					if(x==react.Menu:GetWide()-25)then
						x=0
						y=y+size
					end
				end
			end
			if(v.urls != nil)then
				for k,v in pairs(v.urls)do
					local butt = ScrollPanel:Add("DButton")
					butt:SetText("")
					butt:SetSize(size,size)
					butt:SetPos(x,y)
					butt.Paint = react.GetButtonPaint(v,true,butt)
					butt.DoClick = function()
						react.SendReaction(v,true)
					end
					x=x+size
					if(x==react.Menu:GetWide()-25)then
						x=0
						y=y+size
					end
				end
			end
			local tab = CategoryTabs:AddSheet(string.rep(" ",string.len(k)*2),ScrollPanel).Tab
			tab.Paint = function()
				draw.RoundedBoxEx(4,0,0,tab:GetWide(),20,Color(100,100,255,255),true,true,false,false)
				surface.SetDrawColor(255,255,255,255)
				surface.DrawRect(1,4,tab:GetWide()-2,tab:GetTall())
				draw.SimpleText(string.Replace(k,"_"," "),"R2Font",tab:GetWide()/2,5,Color(0,0,0,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
			end
		end
	end

	react.SendReaction = function(path,web)
		net.Start("R2_reaction")
		net.WriteString(path)
		net.WriteBool(web)
		net.SendToServer()
	end

	hook.Add("PostDrawTranslucentRenderables", "Reactions", function()
		for k,v in pairs(react.Reactions) do
			render.SetMaterial(Material(v.path))
			local timeex = SysTime()-v.time
			local ltimeex = math.Clamp(((math.sin(timeex*(math.pi/5))*10)*64)-64,-64,0)
			if(k == LocalPlayer())then
				cam.Start2D()
				render.DrawScreenQuadEx( ltimeex, (ScrH()/2)-16, 64, 64 )
				cam.End2D()
			end
			local bone = k:LookupBone("ValveBiped.Bip01_Head1")
			if(bone != nil)then
				local spos,ang = k:GetBonePosition(bone)
				ang2 = ang:Right():Angle():Forward()
				render.DrawQuadEasy(((ang:Forward()*3)+(ang2*7)+spos),ang2, 8, 8, Color(255, 255, 255, math.Clamp(255-(timeex-4)*255,0,255)),180)
			else
				spos = k:GetPos()+Vector(0,0,80+math.sin(timeex*3)*2)
				render.DrawQuadEasy(spos,Angle(0,timeex*180,0):Forward(), 8, 8, Color(255, 255, 255, math.Clamp(255-(timeex-4)*255,0,255)),180)
				render.DrawQuadEasy(spos,-Angle(0,timeex*180,0):Forward(), 8, 8, Color(255, 255, 255, math.Clamp(255-(timeex-4)*255,0,255)),180)
			end
		end
	end)
	hook.Add("OnContextMenuOpen", "ReactionMenuOpen", function()
		if(!IsValid(react.Menu))then
			react.CreateMenu()
			net.Start("R2_requestlist")
			net.SendToServer()
		end
		react.Menu:Show()
		react.Menu:MakePopup()
	end)

	hook.Add("OnContextMenuClose", "ReactionMenuClose", function()
		react.Menu:Hide()
	end)
end
