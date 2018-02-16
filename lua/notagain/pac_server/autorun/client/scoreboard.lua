if _G.SCOREBOARD and IsValid(_G.SCOREBOARD) then
	_G.SCOREBOARD:Remove()
end

local blur_size = 4
blur_overdraw = 2

local prettytext = requirex("pretty_text")

surface.CreateFont("scoreboard_line",{
	font = "Square721 BT",
	size = 18,
	additive = false,
	weight = 700,
	--outline = true,
	antialias = true,
})

local screen_width = _G.ScrW()
local screen_height = _G.ScrH()
local selected_player = LocalPlayer()
local ply_lines = {}

local gr_dw_id = surface.GetTextureID("gui/gradient_down")
local gr_up_id = surface.GetTextureID("gui/gradient_up")
local gr_id = surface.GetTextureID("gui/gradient")
local gr_ct_id = surface.GetTextureID("gui/center_gradient")
--models/props_combine/portalball001_sheet maybe for selected line?

local metal = CreateMaterial(tostring({}), "UnlitGeneric", {
	["$BaseTextureTransform"] = "center .2 0 scale .5 1 rotate 150 translate 0 0",
	["$BaseTexture"] = "models/weapons/flare/shellside",
	["$VertexAlpha"] = 1,
	["$VertexColor"] = 1,
})

local text_color = Color(255,255,255,255)
local scale_coef = 8

local pacicon = Material("icon64/pac3.png")
if pacicon:IsError() then
	pacicon = Material("icon16/package.png")
end

local colorstring = function(str,x,y)
	local pattern = "<(.-)=(.-)>"
	local parts = string.Explode(pattern,str,true)
	local index = 1
	for tag,values in string.gmatch(str,pattern) do
		surface.DrawText(string.upper(parts[index]))
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
				surface.SetTextColor(r,g,b,255)
			end
		end
	end

	prettytext.DrawText({
		text = string.upper(parts[#parts]),
		x = x,
		y = y,
		font = "Square721 BT",
		size = 18,
		weight = 1000,
		blur_size = blur_size,
		blur_overdraw = blur_overdraw,
		--background_color = color2,
	})
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
		surface.SetMaterial(metal)
		surface.SetDrawColor(75,75,75,255)
		surface.DrawTexturedRect(0,0,w,h)
		surface.SetDrawColor(0,0,0)
		surface.DrawOutlinedRect(0,0,w,h)
		surface.DrawRect(0,0,w,25)
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
				self.Menu:SetPos(gui.MouseX(),gui.MouseY())
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
						surface.SetMaterial(pacicon)
						surface.SetDrawColor(255,255,255,255)
						surface.DrawTexturedRect(2,1,20,20)
					end

					SubPac:AddOption(parent.Player.pac_ignored and "Unignore" or "Ignore",function() if parent.Player.pac_ignored then pac.UnIgnoreEntity(parent.Player) else pac.IgnoreEntity(parent.Player) end end):SetImage(parent.Player.pac_ignored and "icon16/accept.png" or "icon16/cancel.png")

					self.Menu:AddSpacer()
				end

				self.Menu:AddOption("Copy SteamID",function() SetClipboardText(parent.Player:SteamID()) chat.AddText(Color(255,255,255),"You copied "..parent.Player:Nick().."'s SteamID") end):SetImage("icon16/tab_edit.png")
				self.Menu:AddOption("Open Profile",function() parent.Player:ShowProfile() end):SetImage("icon16/world.png")
				self.Menu:AddOption(parent.Player:IsMuted() and "Unmute" or "Mute",function() parent.Player:SetMuted(not parent.Player:IsMuted()) end):SetImage(parent.Player:IsMuted() and "icon16/sound_add.png" or "icon16/sound_mute.png")

				if friends then
					self.Menu:AddOption(LocalPlayer():IsFriend(parent.Player) and "untrust" or "trust", function()
						if LocalPlayer():IsFriend(parent.Player) then
							RunConsoleCommand("friends_set", parent.Player:UniqueID(), "remove")
						else
							RunConsoleCommand("friends_set", parent.Player:UniqueID(), "add")
						end
					end):SetImage(LocalPlayer():IsFriend(parent.Player) and "icon16/user_delete.png" or "icon16/user_add.png")
				end


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

			surface.SetDrawColor(50,50,50,255)
			surface.DrawRect(0,0, w,h)

			surface.SetTexture(gr_up_id)
			surface.SetDrawColor(0,0,0,255)
			surface.DrawTexturedRect(0,0,w,h)
			if self:IsHovered() then
				surface.SetDrawColor(127,255,127)
			elseif not parent.Player:Alive() then
				surface.SetDrawColor(127,127,127)
			else
				surface.SetDrawColor(parent.Color)
			end
			surface.DrawLine(0,0,w,0)
			--Surface.DrawOutlinedRect(0,0,w,h)
			--draw.NoTexture()
			surface.DrawPoly({
				{ x = 0,      y = 0 },
				{ x = w*2/3,  y = 0 },
				{ x = w*1.9/3,y = h },
				{ x = 0,      y = h },
			})

			colorstring(parent.Player:Nick(), w/scale_coef,5)

			prettytext.DrawText({
				text = jlevel and jlevel.GetStats(parent.Player).level or 0,
				x = w*3/scale_coef,
				y = 5,
				font = "Square721 BT",
				size = 18,
				weight = 1000,
				blur_size = blur_size,
				blur_overdraw = blur_overdraw,
				--background_color = color2,
			})

		 	local formattedtime = parent.Player.GetNiceTotalTime and parent.Player:GetNiceTotalTime() or {h = 0,m = 0,s = 0}
            local time = formattedtime.h >= 1 and formattedtime.h or formattedtime.m
            local unit = formattedtime.h >= 1 and "h" or "min"

			prettytext.DrawText({
				text = time..unit,
				x = w-w*2/scale_coef-scale_coef,
				y = 5,
				font = "Square721 BT",
				size = 18,
				weight = 1000,
				blur_size = blur_size,
				blur_overdraw = blur_overdraw,
				--background_color = color2,
			})

			local ping = parent.Player:Ping()

			prettytext.DrawText({
				text = parent.Player:Ping(),
				x = w-w*1/scale_coef-scale_coef,
				y = 5,
				font = "Square721 BT",
				size = 18,
				weight = 1000,
				blur_size = blur_size,
				blur_overdraw = blur_overdraw,
				--background_color = color2,
				foreground_color = ping >= 100 and Color(220, 140, 0) or ping >= 200 and Color(255, 127, 127) or Color(255, 255, 255)
			})

			if parent.Selected then
				surface.SetTextPos(2,-5)
				surface.SetFont("DermaLarge")
				surface.SetTextColor(255,255,255)
				surface.DrawText("⮞")
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
		self:SetSize(screen_width/1.5,screen_height-screen_height*1.2/3)
		self:SetPos(screen_width/2-self:GetWide()/2,screen_height/2-self:GetTall()/2)

		-- title
		local title = self:Add("DPanel")
		title:Dock(TOP)
		title:SetTall(50)
		title:DockMargin(100,0,100,10)
		title.Paint = function(self,w,h)
			surface.SetDrawColor(0,0,0,0)
			surface.DrawRect(0,0,w,h)
			surface.SetDrawColor(text_color)
			surface.DrawLine(0,h-5,w,h-5)

			prettytext.DrawText({
				text = string.gsub(GetHostName(),"Official%sPAC3%sServer%s%-%s",""),
				x = w/2,
				y = h/2,
				font = "Square721 BT",
				size = 55,
				weight = 1000,
				blur_size = 7,
				blur_overdraw = 5,
				foreground_color = text_color,
				--background_color = color2,
				x_align = -0.5,
				y_align = -0.5,
			})
		end

		-- players
		local ply_scale = self:GetWide()-50
		local dplayers = self:Add("DPanel")
		dplayers:SetPos(20,60)
		dplayers:SetSize(ply_scale,20)
		dplayers.Paint = function(self,w,h)
			surface.SetDrawColor(text_color)
			surface.DrawLine(0,19,w*2/scale_coef,19)

			prettytext.DrawText({
				text = "Players - "..player.GetCount(),
				x = 0,
				y = 0,
				font = "Square721 BT",
				size = 20,
				weight = 1000,
				blur_size = 2,
				blur_overdraw = blur_overdraw*2,
				foreground_color = text_color,
				--background_color = color2,
			})
		end

		local function sort_paint(text)
			return function(self,w,h)
				prettytext.DrawText({
					text = text,
					font = "Square721 BT",
					size = 15,
					weight = 700,
					blur_size = blur_size,
					blur_overdraw = blur_overdraw,
					foreground_color = self.Depressed and Color(150, 150, 150) or Color(255, 255, 255),
					--background_color = color2,
				})

				return true
			end
		end

		local playersort = self:Add("DPanel")
		playersort:SetPos(20,90)
		playersort:SetSize(ply_scale,20)
		playersort.Paint = function(self,w,h)
			surface.SetDrawColor(50,50,50,255)
			surface.DrawRect(0,0, w,20)

			surface.SetTexture(gr_dw_id)
			surface.SetDrawColor(0,0,0,255)
			surface.DrawTexturedRect(0,0,w,20)
			surface.SetDrawColor(100,100,100,255)
			surface.DrawOutlinedRect(0,0,w,20)
		end

		local function sort_rows(val)
			return function(self)
				local tbl = {}
				for k, v in pairs(ply_lines) do
					tbl[#tbl + 1] = {k = k, v = val(v)}
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
		end

		local namesort = playersort:Add("DButton")
		namesort:SetPos(ply_scale/scale_coef,2)
		namesort:SetSize(40,20)
		namesort.Paint = sort_paint("Name")
		namesort.DoClick = sort_rows(function(v) return v.Player:Nick():gsub("(<color=[%d,]+>)", "") end)

		local lvlsort = playersort:Add("DButton")
		lvlsort:SetPos(ply_scale*3/scale_coef - 6,2)
		lvlsort:SetSize(40,20)
		lvlsort.Paint = sort_paint("LVL")
		lvlsort.DoClick = sort_rows(function(v) return jlevel.GetStats(v.Player).level end)

		local timesort = playersort:Add("DButton")
		timesort:SetPos(ply_scale-ply_scale*2/scale_coef - 12,2)
		timesort:SetSize(80,20)
		timesort.Paint = sort_paint("Playtime")
		timesort.DoClick = sort_rows(function(v) return v.Player:GetTotalTime() end)

		local pingsort = playersort:Add("DButton")
		pingsort:SetPos(ply_scale-ply_scale/scale_coef - 12,2)
		pingsort:SetSize(40,20)
		pingsort.Paint = sort_paint("Ping")
		pingsort.DoClick = sort_rows(function(v) return v.Player:Ping() end)

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

				ply_lines[v:SteamID()].Color = team.GetColor(v:Team())
			end

			if IsValid(selected_player) and not ply_lines[selected_player:SteamID()].Selected then
				ply_lines[selected_player:SteamID()].Selected = true
			end
		end
	end,

	Paint = function(self,w,h)
	end,
}

vgui.Register("Scoreboard",scoreboard,"EditablePanel")

do
	local gr_dw_id = surface.GetTextureID("gui/gradient_down")

	if IsValid(_G.STATUS) then
		_G.STATUS:Remove()
	end

	local spacing = 15
	local fps = 1
	timer.Create("scoreboard_status_update_fps,",1,0,function()
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
			surface.SetDrawColor(0,0,0,255)
			surface.DrawRect(0,0,w,h)
			surface.SetTexture(gr_dw_id)
			surface.SetDrawColor(60,60,60,255)
			surface.DrawTexturedRect(0,0,w,h)
			surface.SetDrawColor(130,130,130,255)
			surface.DrawLine(0,0,w,0)

			local ply = LocalPlayer()

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

	vgui.Register("scoreboard_status_panel",status,"DPanel")
end


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

		if _G.STATUS and _G.STATUS:IsValid() then
			_G.STATUS:Remove()
		end

		_G.STATUS = vgui.Create("scoreboard_status_panel")

		return false
	end

	hook.Add("KeyRelease","rpg_scoreboard",function(_,key)
		if not IsValid(_G.SCOREBOARD) or not _G.SCOREBOARD:IsVisible() then return end
		if not cv_scoreboard_mouse:GetBool() and key == IN_ATTACK2 then
			gui.EnableScreenClicker(true)
		end
	end)

	hook.Add("PreRender", "rpg_scoreboard", function()
		if screen_width ~= _G.ScrW() or screen_height ~= _G.ScrH() then
			screen_width = _G.ScrW()
			screen_height = _G.ScrH()
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

end)

hook.Add("ScoreboardHide","rpg_scoreboard",function()
	if cv_scoreboard:GetBool() and IsValid(_G.SCOREBOARD) then
		_G.SCOREBOARD:Hide()
		CloseDermaMenus()
		gui.EnableScreenClicker(false)

		if _G.STATUS and _G.STATUS:IsValid() then
			_G.STATUS:Remove()
		end
	end

	hook.Remove("KeyRelease", "rpg_scoreboard")
	hook.Remove("PreRender", "rpg_scoreboard")
end)