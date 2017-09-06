if _G.SCOREBOARD and IsValid(_G.SCOREBOARD) then
	_G.SCOREBOARD:Remove()
end

--micro opti?
local Surface = _G.surface

Surface.CreateFont("scoreboard_title_b",{
	font = "Square721 BT",
	size = 30,
	outline = true,
	additive = false,
	weight = 700,
	antialias = true,
})

Surface.CreateFont("scoreboard_title_m",{
	font = "Square721 BT",
	size = 20,
	outline = true,
	additive = false,
	weight = 700,
	antialias = true,
})

Surface.CreateFont("scoreboard_desc",{
	font = "Square721 BT",
	size = 15,
	outline = true,
	additive = false,
	weight = 700,
	antialias = true,
})

Surface.CreateFont("scoreboard_line",{
	font = "Square721 BT",
	size = 18,
	additive = false,
	weight = 700,
	--outline = true,
	antialias = true,
})

Surface.CreateFont("scoreboard_achiev",{
	font = "Square721 BT",
	size = 15,
	additive = false,
	weight = 700,
	--outline = true,
	antialias = true,
})

local ScrW = _G.ScrW()
local ScrH = _G.ScrH()
local selected_player = LocalPlayer()
local ply_lines = {}

local gr_dw_id = Surface.GetTextureID("gui/gradient_down")
local gr_up_id = Surface.GetTextureID("gui/gradient_up")
local gr_id = Surface.GetTextureID("gui/gradient")
local gr_ct_id = Surface.GetTextureID("gui/center_gradient")
--models/props_combine/portalball001_sheet maybe for selected line?

local metal = CreateMaterial(tostring({}), "UnlitGeneric", {
	["$BaseTextureTransform"] = "center .2 0 scale .5 1 rotate 150 translate 0 0",
	["$BaseTexture"] = "models/weapons/flare/shellside",
	["$VertexAlpha"] = 1,
	["$VertexColor"] = 1,
})

local text_color = Color(200,200,200,255)
local scale_coef = 8

local pacicon = Material("icon64/pac3.png")
if pacicon:IsError() then
	pacicon = Material("icon16/package.png")
end

local colorstring = function(str,x,y)
	local pattern = "<(.-)=(.-)>"
	local parts = string.Explode(pattern,str,true)
	local index = 1
	local x,y = (x or 0),(y or 0)
	for tag,values in string.gmatch(str,pattern) do
		Surface.DrawText(string.upper(parts[index]))
		index = index + 1
		if tag == "color" then
			local r,g,b
			string.gsub(values,"(%d+),(%d+),(%d+)",function(sr,sg,sb)
				r = tonumber(sr)
				g = tonumber(sg)
				b = tonumber(sb)
				return ""
			end)
			if r and g and b then
				Surface.SetTextColor(r,g,b,255)
			end
		end
	end
	Surface.DrawText(string.upper(parts[#parts]))
	Surface.SetTextColor(255,255,255)
end

local clamp = function(input,min,max) --fuck math clamp i guess lol
	if max and input >= max then
		input = max
	elseif min and input <= min then
		input = min
	end
	return input
end

local function cinputs(command,mode)
    local main = vgui.Create("DFrame")
	main:SetSize(300,150)
	main:SetPos(_G.ScrW()/2-main:GetWide()/2,_G.ScrH()/2-main:GetTall()/2)
	main:SetTitle("BANNI")
	print(main.btnMaxim)
	main.btnMaxim:Hide()
	main.btnMinim:Hide()
	main.lblTitle:SetFont("scoreboard_line")
	main:SetDraggable(true)
	main:ShowCloseButton(true)
	main:MakePopup()
	main.Paint = function(self,w,h)
		Surface.SetMaterial(metal)
		Surface.SetDrawColor(75,75,75,255)
		Surface.DrawTexturedRect(0,0,w,h)
		Surface.SetDrawColor(0,0,0)
		Surface.DrawOutlinedRect(0,0,w,h)
		Surface.DrawRect(0,0,w,25)
	end

    local textentry = vgui.Create("DTextEntry",main)
	textentry:SetText("reason")
	textentry:SetPos(main:GetWide()/20,main:GetTall()/2.75)
	textentry:SetSize(main:GetWide()/2,22)

    local wang = vgui.Create("DNumberWang",main)
	wang:SetMinMax( 0, 99999 )
	wang:SetDecimals( 0 )
	wang:SetPos(main:GetWide()/1.625,main:GetTall()/2.75)
	wang:SetSize(main:GetWide()/3,22)
    if mode == 1 then wang:SetVisible( false ) end

    local button = vgui.Create("DButton",main)
	button:SetText("Go")
	button:SetPos(main:GetWide()/4,main:GetTall()/1.35)
	button:SetSize(main:GetWide()/2-8,22)
	button.DoClick = function()
		if mode == 2 then command = command..[[ "]]..wang:GetValue()..[[" ]] end
		command = command..[[ "]]..textentry:GetValue()..[[" ]]
		LocalPlayer():ConCommand(command)
		main:Remove()
	end
end

local player_line = {
	Init = function(self)
		self.Player = NULL
		self.PlayerInit = false
		self.Color = Color(255,255,255)
		self:SetTall(30)
		self:DockMargin(0,1,0,1)
		local parent = self

		self.av = self:Add("AvatarImage")
		self.av:SetSize(60,60)
		self.av:SetPos(20,-15)
		self.av:SetZPos(10)

		local btnav = self:Add("DButton")
		btnav:SetSize(self.av:GetWide(),self.av:GetTall())
		btnav:SetPos(self.av:GetPos())
		btnav:SetText("")
		btnav.DoClick = function(self)
			parent.Player:ShowProfile()
		end
		btnav.Paint = function() end
		btnav:SetZPos(11)

		self.btn = self:Add("DButton")
		self.btn:SetText("")
		self.btn.OnMousePressed = function(self,num) -- this part is highly trash
			local PlayerID = tostring(parent.Player:UniqueID())

			if num == MOUSE_RIGHT then

				self.Menu = vgui.Create("DMenu")
				self.Menu:SetPos(gui.MouseX,gui.MouseY)
				self.Menu:SetAutoDelete(true)

				if aowl then
					if PlayerID ~= tostring( LocalPlayer():UniqueID() ) then
						local goto_ = self.Menu:AddOption("Goto", function()
							RunConsoleCommand( "aowl", "goto", PlayerID )
						end)

						goto_:SetImage("icon16/arrow_right.png")

						local bring = goto_:AddSubMenu( "Bring" )
						bring:AddOption("Bring",function() RunConsoleCommand( "aowl", "bring", PlayerID  ) end):SetImage("icon16/arrow_in.png")
					end

					local SubAdmin,pic = self.Menu:AddSubMenu("Staff")
					pic:SetImage("icon16/shield.png")
					SubAdmin:AddOption( "Kick",function() cinputs( "aowl kick "..PlayerID  , 1) end):SetImage("icon16/door_in.png")
					SubAdmin:AddOption( "Ban",function() cinputs( "aowl ban "..PlayerID  , 2) end):SetImage("icon16/stop.png")
					SubAdmin:AddOption( "Cleanup",function() RunConsoleCommand( "aowl", "cleanup", PlayerID) end):SetImage("icon16/arrow_rotate_clockwise.png")
					SubAdmin:AddSpacer()
					SubAdmin:AddOption( "Reconnect",function() RunConsoleCommand( "aowl", "cexec", PlayerID , "retry") end):SetImage("icon16/arrow_refresh.png")


					self.Menu:AddSpacer()
				end

				if pac then
					local SubPac,Image = self.Menu:AddSubMenu("PAC3")
					Image.PaintOver = function(self,w,h) -- little bit hacky but cant resize images with setimage
						Surface.SetMaterial(pacicon)
						Surface.SetDrawColor(255,255,255,255)
						Surface.DrawTexturedRect(2,1,20,20)
					end

					SubPac:AddOption(parent.Player.pac_ignored and "Unignore" or "Ignore",function() if parent.Player.pac_ignored then pac.UnIgnoreEntity(parent.Player) else pac.IgnoreEntity(parent.Player) end end):SetImage(parent.Player.pac_ignored and "icon16/accept.png" or "icon16/cancel.png")

					self.Menu:AddSpacer()
				end

				self.Menu:AddOption("Copy SteamID",function() SetClipboardText(parent.Player:SteamID()) chat.AddText(Color(255,255,255),"You copied "..parent.Player:Nick().."'s SteamID") end):SetImage("icon16/tab_edit.png")
				self.Menu:AddOption("Open Profile",function() parent.Player:ShowProfile() end):SetImage("icon16/world.png")
				self.Menu:AddOption(parent.Player:IsMuted() and "Unmute" or "Mute",function() parent.Player:SetMuted(not parent.Player:IsMuted()) end):SetImage(parent.Player:IsMuted() and "icon16/sound_add.png" or "icon16/sound_mute.png")


				RegisterDermaMenuForClose( self.Menu )
				self.Menu:Open()

			elseif num == MOUSE_LEFT then
				if selected_player == parent.Player then
					RunConsoleCommand( "aowl", "goto", PlayerID )
				end
				ply_lines[selected_player:SteamID()].Selected = false
				selected_player = parent.Player
			end
		end

		self.btn.Paint = function(self,w,h)
			if not IsValid(parent.Player) then return end
			Surface.SetTexture(gr_up_id)
			Surface.SetDrawColor(0,0,0,255)
			Surface.DrawTexturedRect(0,0,w,h)
			if self:IsHovered() then
				Surface.SetDrawColor(127,255,127)
			elseif not parent.Player:Alive() then
				Surface.SetDrawColor(255,127,127)
			else
				Surface.SetDrawColor(parent.Color)
			end
			Surface.DrawLine(0,0,w,0)
			--Surface.DrawOutlinedRect(0,0,w,h)
			--draw.NoTexture()
			Surface.DrawPoly({
				{ x = 0,      y = 0 },
				{ x = w*2/3,  y = 0 },
				{ x = w*1.9/3,y = h },
				{ x = 0,      y = h },
			})

			Surface.SetFont("scoreboard_line")
			Surface.SetTextPos(w/scale_coef,5)
			colorstring(parent.Player:Nick())

			Surface.SetTextPos(w*3/scale_coef,5)
			local jlevel = _G.jlevel
			Surface.DrawText(jlevel and jlevel.GetStats(parent.Player).level or 0)

		 	local formattedtime = parent.Player.GetNiceTotalTime and parent.Player:GetNiceTotalTime() or {h = 0,m = 0,s = 0}
            local time = formattedtime.h >= 1 and formattedtime.h or formattedtime.m
            local unit = formattedtime.h >= 1 and "h" or "min"
			Surface.SetTextPos(w-w*2/scale_coef,5)
			Surface.DrawText(time..unit)

			Surface.SetTextPos(w-w/scale_coef,5)
			local ping = parent.Player:Ping()
			if ping >= 100 then
				Surface.SetTextColor(220,140,0)
			end
			if ping >= 200 then
				Surface.SetTextColor(255,127,127)
			end
			Surface.DrawText(parent.Player:Ping())

			if parent.Selected then
				Surface.SetTextPos(2,-5)
				Surface.SetFont("DermaLarge")
				Surface.SetTextColor(255,255,255)
				Surface.DrawText("⮞")
			end
		end
	end,
	Think = function(self)
		if self.PlayerInit and not IsValid(self.Player) then
			self:Remove()
			ply_lines[self.SteamID] = nil
			if self.Selected then
				selected_player = player.GetAll()[math.random(1,player.GetCount())]
			end
		end
		self.btn:SetSize(self:GetWide(),self:GetTall())
	end,
	Paint = function(self,w,h)
	end,
	Setup = function(self,ply)
		self.Player = ply
		self.PlayerInit = true
		self.Color = team.GetColor(ply:Team())
		self.av:SetPlayer(ply,100)
		self.SteamID = ply:SteamID()
	end,
}

vgui.Register("ScoreboardPlayerLine",player_line,"DPanel")

local scoreboard = {
	Init = function(self)
		self:SetSize(ScrW,ScrH-ScrH*1.2/3)
		self:SetPos(ScrW/2-self:GetWide()/2,ScrH/2-self:GetTall()/2)

		-- title
		local title = self:Add("DPanel")
		title:Dock(TOP)
		title:SetTall(50)
		title:DockMargin(100,0,100,10)
		title.Paint = function(self,w,h)
			Surface.SetDrawColor(0,0,0,0)
			Surface.DrawRect(0,0,w,h)
			Surface.SetDrawColor(text_color)
			Surface.DrawLine(0,h-5,w,h-5)
			Surface.SetFont("scoreboard_title_b")
			local hostname = string.gsub(GetHostName(),"Official%sPAC3%sServer%s%-%s","")
			local x,y = Surface.GetTextSize(hostname)
			Surface.SetTextPos(w/2-x/2,h/2-y/2)
			Surface.SetTextColor(text_color)
			Surface.DrawText(hostname)
		end

		-- players
		local ply_scale = self:GetWide()*5/scale_coef
		local dplayers = self:Add("DPanel")
		dplayers:SetPos(20,60)
		dplayers:SetSize(ply_scale,20)
		dplayers.Paint = function(self,w,h)
			Surface.SetTextColor(text_color)

			Surface.SetFont("scoreboard_title_m")
			Surface.SetTextPos(0,0)
			Surface.DrawText("Players - "..player.GetCount())
			Surface.SetDrawColor(text_color)
			Surface.DrawLine(0,19,w*2/scale_coef,19)
		end

		local playersort = self:Add("DPanel")
		playersort:SetPos(20,90)
		playersort:SetSize(ply_scale,20)
		playersort.Paint = function(self,w,h)
			Surface.SetTexture(gr_dw_id)
			Surface.SetDrawColor(0,0,0,255)
			Surface.DrawTexturedRect(0,0,w,20)
			Surface.SetDrawColor(100,100,100,200)
			Surface.DrawOutlinedRect(0,0,w,20)
		end

		local namesort = playersort:Add("DButton")
		namesort:SetPos(ply_scale/scale_coef,2)
		namesort:SetSize(40,20)
		namesort.Paint = function(self,w,h)
			Surface.SetFont("scoreboard_desc")

			Surface.SetTextPos(0,0)
			if self:IsHovered() then
				if self.Depressed then
					Surface.SetTextColor(64,64,164)
				else
					Surface.SetTextColor(64,92,192)
				end
			end
			Surface.DrawText("Name")
			Surface.SetTextColor(text_color)

			return true
		end
		namesort.DoClick = function(self)
			local tbl = {}
			for k, v in pairs(ply_lines) do
				tbl[#tbl + 1] = {k = k, v = v.Player:Nick():gsub("(<color=[%d,]+>)", "")}
			end
			if not self.counter then
				table.sort(tbl, function(a, b)
					return a.v < b.v
				end)
			else
				table.sort(tbl, function(a, b)
					return a.v > b.v
				end)
			end
			for k, v in pairs(tbl) do
				local ply = ply_lines[v.k].Player
				ply_lines[v.k]:SetZPos(k - (game.MaxPlayers() * (ply:Team() - 1)))
			end
			self.counter = not self.counter
		end

		local lvlsort = playersort:Add("DButton")
		lvlsort:SetPos(ply_scale*3/scale_coef - 6,2)
		lvlsort:SetSize(40,20)
		lvlsort.Paint = function(self,w,h)
			Surface.SetFont("scoreboard_desc")

			Surface.SetTextPos(0,0)
			if self:IsHovered() then
				if self.Depressed then
					Surface.SetTextColor(64,64,164)
				else
					Surface.SetTextColor(64,92,192)
				end
			end
			Surface.DrawText("LVL")
			Surface.SetTextColor(text_color)

			return true
		end
		lvlsort.DoClick = function(self)
			local tbl = {}
			for k, v in pairs(ply_lines) do
				tbl[#tbl + 1] = {k = k, v = jlevel.GetStats(v.Player).level}
			end
			if self.counter then
				table.sort(tbl, function(a, b)
					return a.v < b.v
				end)
			else
				table.sort(tbl, function(a, b)
					return a.v > b.v
				end)
			end
			for k, v in pairs(tbl) do
				local ply = ply_lines[v.k].Player
				ply_lines[v.k]:SetZPos(k - (game.MaxPlayers() * (ply:Team() - 1)))
			end
			self.counter = not self.counter
		end

		local timesort = playersort:Add("DButton")
		timesort:SetPos(ply_scale-ply_scale*2/scale_coef - 12,2)
		timesort:SetSize(80,20)
		timesort.Paint = function(self,w,h)
			Surface.SetFont("scoreboard_desc")

			Surface.SetTextPos(0,0)
			if self:IsHovered() then
				if self.Depressed then
					Surface.SetTextColor(64,64,164)
				else
					Surface.SetTextColor(64,92,192)
				end
			end
			Surface.DrawText("Playtime")
			Surface.SetTextColor(text_color)

			return true
		end
		timesort.DoClick = function(self)
			local tbl = {}
			for k, v in pairs(ply_lines) do
				tbl[#tbl + 1] = {k = k, v = v.Player:GetTotalTime()}
			end
			if self.counter then
				table.sort(tbl, function(a, b)
					return a.v < b.v
				end)
			else
				table.sort(tbl, function(a, b)
					return a.v > b.v
				end)
			end
			for k, v in pairs(tbl) do
				local ply = ply_lines[v.k].Player
				ply_lines[v.k]:SetZPos(k - (game.MaxPlayers() * (ply:Team() - 1)))
			end
			self.counter = not self.counter
		end

		local pingsort = playersort:Add("DButton")
		pingsort:SetPos(ply_scale-ply_scale/scale_coef - 12,2)
		pingsort:SetSize(40,20)
		pingsort.Paint = function(self,w,h)
			Surface.SetFont("scoreboard_desc")

			Surface.SetTextPos(0,0)
			if self:IsHovered() then
				if self.Depressed then
					Surface.SetTextColor(64,64,164)
				else
					Surface.SetTextColor(64,92,192)
				end
			end
			Surface.DrawText("Ping")
			Surface.SetTextColor(text_color)

			return true
		end
		pingsort.DoClick = function(self)
			local tbl = {}
			for k, v in pairs(ply_lines) do
				tbl[#tbl + 1] = {k = k, v = v.Player:Ping()}
			end
			if self.counter then
				table.sort(tbl, function(a, b)
					return a.v < b.v
				end)
			else
				table.sort(tbl, function(a, b)
					return a.v > b.v
				end)
			end
			for k, v in pairs(tbl) do
				local ply = ply_lines[v.k].Player
				ply_lines[v.k]:SetZPos(k - (game.MaxPlayers() * (ply:Team() - 1)))
			end
			self.counter = not self.counter
		end

		local players = self:Add("DScrollPanel")
		players:SetPos(20,110)
		players:SetSize(ply_scale,self:GetTall()-150)
		players.Think = function(self)
			for k,v in pairs(player.GetAll()) do
				if not ply_lines[v:SteamID()] then
					local line = self:Add("ScoreboardPlayerLine")
					line:Dock(TOP)
					line:Setup(v)
					ply_lines[v:SteamID()] = line
				end
			end
			if IsValid(selected_player) and not ply_lines[selected_player:SteamID()].Selected then
				ply_lines[selected_player:SteamID()].Selected = true
			end
		end

		--selected players jrpg infos
		local info_scale = self:GetWide()*3/scale_coef
		local dinfos = self:Add("DPanel")
		dinfos:SetPos(dplayers:GetWide()+40,60)
		dinfos:SetSize(info_scale-40,50)
		dinfos.Paint = function(self,w,h)
			Surface.SetTextColor(text_color)

			Surface.SetFont("scoreboard_title_m")
			Surface.SetTextPos(0,0)
			Surface.DrawText("JRPG Infos")
			Surface.SetDrawColor(text_color)
			Surface.DrawLine(0,19,w*4/scale_coef,19)
		end

		local infos = self:Add("DPanel")
		infos:SetPos(dplayers:GetWide()+40,90)
		infos:SetSize(info_scale-60,self:GetTall()-130)

		local pacx,pacy = infos:LocalToScreen(dplayers:GetWide()+40,ScrH/2-self:GetTall()/2+90)
		infos.Paint = function(self,w,h)
			if not IsValid(selected_player) then return end

			Surface.SetTexture(gr_up_id)
			Surface.SetDrawColor(30,30,30,200)
			Surface.DrawTexturedRect(0,0,w/3,h)
			Surface.SetDrawColor(100,100,100,200)
			Surface.DrawOutlinedRect(0,0,w/3,h)

			if pac then
				local ent = selected_player
				local head_pos = jrpg and jrpg.FindHeadPos(ent) or (ent:GetPos()+Vector(0,0,60))
				local eye_ang = ent:EyeAngles()

				eye_ang = Angle(0, eye_ang.y + 180, eye_ang.r)
				local pos = LocalToWorld(head_pos, ent:GetAngles(), Vector(0,0,-ent:BoundingRadius()/4), Angle())
				pos = pos - eye_ang:Forward() * ent:BoundingRadius() * 35

				pac.DrawEntity2D(ent, pacx, pacy, w/3, h, pos, eye_ang, 1, 500)
			end

			local b_max_wide = w*2/3-80
			local b_x = w/3+10
			local txt_offset = w*0.25/3

			local dsr_margin = clamp(w*0.95/3,nil,200)

			local jhud = _G.jhud
			if jhud and jattributes then
				draw.NoTexture()
				Surface.DisableClipping(true)
				Surface.SetTextColor(text_color)

				local chealth = jattributes.Colors.Health
				local health_y = h/20
				local health = clamp(selected_player:Health(),0,selected_player:GetMaxHealth())
				jhud.DrawBar(dsr_margin+b_x,health_y,b_max_wide,25,health,selected_player:GetMaxHealth(),5,chealth.r,chealth.g,chealth.b)
				Surface.SetFont("scoreboard_title_m")
				Surface.SetTextPos(b_x+txt_offset,health_y-15)
				Surface.DrawText("HP\t"..clamp(selected_player:Health(),0).."/"..selected_player:GetMaxHealth())

				local cmana = jattributes.Colors.Mana
				local mana_y = h/20 + 30
				local mana = clamp(selected_player:GetMana(),0,selected_player:GetMaxMana())
				jhud.DrawBar(dsr_margin+b_x,mana_y,b_max_wide*0.85,15,mana,selected_player:GetMaxMana(),3,cmana.r,cmana.g,cmana.b)
				Surface.SetFont("scoreboard_desc")
				Surface.SetTextPos(b_x+txt_offset,mana_y-10)
				Surface.DrawText("MP\t"..clamp(selected_player:GetMana(),0).."/"..selected_player:GetMaxMana())

				local cstamina = jattributes.Colors.Stamina
				local stamina_y = h/20 + 50
				local stamina = clamp(selected_player:GetStamina(),0,selected_player:GetMaxStamina())
				jhud.DrawBar(dsr_margin+b_x,stamina_y,b_max_wide*0.85,15,stamina,selected_player:GetMaxStamina(),3,cstamina.r,cstamina.g,cstamina.b)
				Surface.SetFont("scoreboard_desc")
				Surface.SetTextPos(b_x+txt_offset,stamina_y-10)
				Surface.DrawText("SP\t"..clamp(selected_player:GetStamina(),0).."/"..selected_player:GetMaxStamina())

				local cexpe = jattributes.Colors.XP
				local experience_y = h/20 + 75
				local xp = clamp(selected_player:GetXP(),0,selected_player:GetXPToNextLevel())
				jhud.DrawBar(dsr_margin+b_x,experience_y,b_max_wide*0.75,10,xp,selected_player:GetXPToNextLevel(),2,cexpe.r,cexpe.g,cexpe.b)
				Surface.SetFont("scoreboard_desc")
				Surface.SetTextPos(b_x+txt_offset,experience_y-10)
				Surface.DrawText("XP\t"..math.ceil(clamp(selected_player:GetXP(),0)).."/"..math.ceil(selected_player:GetXPToNextLevel()))

				Surface.DisableClipping(false)
			end

			Surface.SetFont("scoreboard_title_m")
			Surface.SetTextColor(text_color)
			Surface.SetTextPos(b_x+txt_offset,h/20+100)
			Surface.DrawText("Achievements Completed")
		end

		local achievs = self:Add("DListView")
		local a_margin_top = infos:GetTall()/20+130
		achievs:SetPos(dplayers:GetWide()+60+infos:GetWide()/3+10,90+a_margin_top)
		achievs:SetSize(infos:GetWide()*2/3-40,infos:GetTall()-(a_margin_top))
		achievs:AddColumn("Achievement")
		achievs:SetHideHeaders(true)
		achievs.Paint = function() end

		achievs.Think = function(self)
			if not PCTasks then return end
			if selected_player ~= self.Player then
				self.Player = selected_player
				self:Clear()
				for k,v in pairs(PCTasks.GetCompleted(self.Player)) do
					local line = self:AddLine("")
					local str = string.upper(k)
					line.Paint = function(self,w,h)
						Surface.SetTexture(gr_ct_id)
						Surface.SetDrawColor(100,100,100,175)
						Surface.DrawTexturedRect(0,2,w,h-4)
						Surface.SetFont("scoreboard_achiev")
						local ach_x,ach_y = Surface.GetTextSize(str)
						Surface.SetTextColor(text_color)
						Surface.SetTextPos(w/2-ach_x/2,h/2-ach_y/2)
						Surface.DrawText(str)
					end
				end
			end
		end
	end,

	Paint = function(self,w,h)
		Surface.SetMaterial(metal)
		Surface.SetDrawColor(75,75,75,253)
		Surface.DrawTexturedRect(0,0,w,h)
		Surface.SetDrawColor(0,0,0)
		Surface.SetTexture(gr_up_id)
		Surface.DrawTexturedRect(0,0,w,10)
		Surface.SetTexture(gr_dw_id)
		Surface.DrawTexturedRect(0,h-10,w,10)

		Surface.SetTexture(gr_id)
		Surface.SetDrawColor(30,30,30,255)
		Surface.DrawTexturedRect(0,h-35,700,20)
		Surface.SetFont("scoreboard_achiev")
		Surface.SetTextColor(text_color)
		local str = "Server Uptime: "..string.NiceTime(CurTime())
		Surface.SetTextPos(20,h-32.5)
		Surface.DrawText(str)
	end,
}

vgui.Register("Scoreboard",scoreboard,"EditablePanel")

local cv_scoreboard = CreateConVar("rpg_scoreboard","1",FCVAR_ARCHIVE,"Enable or disable the rpg scoreboard")
local cv_scoreboard_mouse = CreateConVar("rpg_scoreboard_mouse_on_open","1",FCVAR_ARCHIVE,"Enables cursor on scoreboard opening or not")
cvars.AddChangeCallback("rpg_scoreboard",function(name,old,new)
	if old ~= "0" and IsValid(_G.SCOREBOARD) then
		_G.SCOREBOARD:Remove()
	end
end)

hook.Add("ScoreboardShow","rpg_scoreboard",function()
	if cv_scoreboard:GetBool() then
		if not IsValid(_G.SCOREBOARD) then
			selected_player = LocalPlayer()
			ply_lines = {}
			local sc = vgui.Create("Scoreboard")
			_G.SCOREBOARD = sc
		end
		_G.SCOREBOARD:Show()
		if cv_scoreboard_mouse:GetBool() then
			gui.EnableScreenClicker(true)
		end
		return false
	end
end)

hook.Add("ScoreboardHide","rpg_scoreboard",function()
	if cv_scoreboard:GetBool() and IsValid(_G.SCOREBOARD) then
		_G.SCOREBOARD:Hide()
		CloseDermaMenus()
		gui.EnableScreenClicker(false)
	end
end)

hook.Add("KeyRelease","rpg_scoreboard",function(_,key)
	if not IsValid(_G.SCOREBOARD) or not _G.SCOREBOARD:IsVisible() then return end
	if not cv_scoreboard_mouse:GetBool() and key == IN_ATTACK2 then
		gui.EnableScreenClicker(true)
	end
end)

hook.Add("PreRender", "rpg_scoreboard", function()
    if ScrW ~= _G.ScrW() or ScrH ~= _G.ScrH() then
		ScrW = _G.ScrW()
		ScrH = _G.ScrH()
		if _G.SCOREBOARD and IsValid(_G.SCOREBOARD) then
			_G.SCOREBOARD:Remove()
			selected_player = LocalPlayer()
			ply_lines = {}
			local sc = vgui.Create("Scoreboard")
			_G.SCOREBOARD = sc
			sc:Hide()
		end
	end
end)
