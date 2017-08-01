if _G.SCOREBOARD and IsValid(_G.SCOREBOARD) then
	_G.SCOREBOARD:Remove()
end

surface.CreateFont("scoreboard_title_b",{
	font = "DermaDefaultBold",
	size = 30,
	outline = true,
	additive = false,
	weight = 700,
})

surface.CreateFont("scoreboard_title_m",{
	font = "DermaDefaultBold",
	size = 20,
	outline = true,
	additive = false,
	weight = 700,
})

surface.CreateFont("scoreboard_desc",{
	font = "DermaDefaultBold",
	size = 15,
	outline = true,
	additive = false,
	weight = 700,
})

surface.CreateFont("scoreboard_line",{
	font = "Roboto",
	size = 18,
	additive = false,
	weight = 600,
	--shadow = true,
})

local ScrW = _G.ScrW()
local ScrH = _G.ScrH()
local selected_player = LocalPlayer()
local ply_lines = {}

local gr_dw_id = surface.GetTextureID("gui/gradient_down")
local gr_up_id = surface.GetTextureID("gui/gradient_up")
--models/props_combine/portalball001_sheet maybe for selected line?

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
		surface.DrawText(parts[index])
		index = index + 1
		if tag == "color" then -- maybe more tags to support but heh
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
	surface.DrawText(parts[#parts])
	surface.SetTextColor(255,255,255)
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
		self.av:SetPos(15,-15)
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
			surface.SetTexture(gr_up_id)
			surface.SetDrawColor(0,0,0,255)
			surface.DrawTexturedRect(0,0,w,h)
			if self:IsHovered() then
				surface.SetDrawColor(127,255,127)
			elseif not parent.Player:Alive() then
				surface.SetDrawColor(255,127,127)
			else
				surface.SetDrawColor(parent.Color)
			end
			surface.DrawLine(0,0,w,0)
			--surface.DrawOutlinedRect(0,0,w,h)
			--draw.NoTexture()
			surface.DrawPoly({
				{ x = 0,      y = 0 },
				{ x = w*2/3,  y = 0 },
				{ x = w*1.9/3,y = h },
				{ x = 0,      y = h },
			})

			surface.SetFont("scoreboard_line")
			surface.SetTextPos(w/scale_coef,5)
			colorstring(parent.Player:Nick())

			surface.SetTextPos(w*3/scale_coef,5)
			surface.DrawText(jlevel and jlevel.GetStats(parent.Player).level or 0)

		 	local formattedtime = parent.Player:GetNiceTotalTime() or {h = 0,m = 0,s = 0}
            local time = formattedtime.h >= 1 and formattedtime.h or formattedtime.m
            local unit = formattedtime.h >= 1 and "h" or "min"
			surface.SetTextPos(w-w*2/scale_coef,5)
			surface.DrawText(time..unit)

			surface.SetTextPos(w-w/scale_coef,5)
			surface.DrawText(parent.Player:Ping())

			if parent.Selected then
			surface.SetTextPos(1.75,5)
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
		self:SetTitle("")
		self:SetSize(ScrW,ScrH-ScrH/2)
		self:SetPos(ScrW/2-self:GetWide()/2,ScrH/2-self:GetTall()/2)
		self.btnClose:SetZPos(999)
		self.btnClose:Hide()
		self.btnMaxim:Hide()
		self.btnMinim:Hide()

		-- title
		local title = self:Add("DPanel")
		title:Dock(TOP)
		title:SetTall(50)
		title:DockMargin(100,-30,100,10)
		title.Paint = function(self,w,h)
			surface.SetDrawColor(0,0,0,0)
			surface.DrawRect(0,0,w,h)
			surface.SetDrawColor(text_color)
			surface.DrawLine(0,h-5,w,h-5)
			surface.SetFont("scoreboard_title_b")
			local hostname = string.gsub(GetHostName(),"Official%sPAC3%sServer%s%-%s","")
			local x,y = surface.GetTextSize(hostname)
			surface.SetTextPos(w/2-x/2,h/2-y/2)
			surface.SetTextColor(text_color)
			surface.DrawText(hostname)
		end

		-- players
		local ply_scale = self:GetWide()*5/scale_coef
		local dplayers = self:Add("DPanel")
		dplayers:SetPos(20,60)
		dplayers:SetSize(ply_scale,50)
		dplayers.Paint = function(self,w,h)
			surface.SetTextColor(text_color)

			surface.SetFont("scoreboard_title_m")
			surface.SetTextPos(0,0)
			surface.DrawText("Players - "..player.GetCount())
			surface.SetDrawColor(text_color)
			surface.DrawLine(0,19,w*2/scale_coef,19)

			surface.SetTexture(gr_dw_id)
			surface.SetDrawColor(0,0,0,255)
			surface.DrawTexturedRect(0,30,w,20)
			surface.SetDrawColor(100,100,100,200)
			surface.DrawOutlinedRect(0,30,w,20)

			surface.SetFont("scoreboard_desc")

			surface.SetTextPos(w/scale_coef,32)
			surface.DrawText("Name")

			surface.SetTextPos(w-w*2/scale_coef,32)
			surface.DrawText("Playtime")

			surface.SetTextPos(w*3/scale_coef,32)
			surface.DrawText(".LVL")

			surface.SetTextPos(w-w/scale_coef,32)
			surface.DrawText("Ping")
		end

		local players = self:Add("DScrollPanel")
		players:SetPos(20,110)
		players:SetSize(ply_scale,self:GetTall()-210)
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
		--[[players.Paint = function(self,w,h)
			surface.SetDrawColor(100,100,100,200)
			surface.DrawOutlinedRect(0,0,w,h)
		end]]--

		--selected players jrpg infos
		local info_scale = self:GetWide()*3/scale_coef
		local dinfos = self:Add("DPanel")
		dinfos:SetPos(dplayers:GetWide()+40,60)
		dinfos:SetSize(info_scale-40,50)
		dinfos.Paint = function(self,w,h)
			surface.SetTextColor(text_color)

			surface.SetFont("scoreboard_title_m")
			surface.SetTextPos(0,0)
			surface.DrawText("JRPG Infos")
			surface.SetDrawColor(text_color)
			surface.DrawLine(0,19,w*4/scale_coef,19)
		end

		local infos = self:Add("DPanel")
		infos:SetPos(dplayers:GetWide()+40,90)
		infos:SetSize(info_scale-60,self:GetTall()-190)
		local ix,iy = infos:LocalToScreen(dplayers:GetWide()+40,ScrH/2-self:GetTall()/2+90)
		infos.Paint = function(self,w,h)
			if not IsValid(selected_player) then return end
			surface.SetTexture(gr_up_id)
			surface.SetDrawColor(30,30,30,200)
			surface.DrawTexturedRect(0,0,w/3,h)
			surface.SetDrawColor(100,100,100,200)
			surface.DrawOutlinedRect(0,0,w/3,h)
			if pac then
				pac.DrawEntity2D(selected_player,ix,iy,w/3,h,nil,nil,40)
			end
			--[[local health_max_wide = w*2/3-20
			draw.RoundedBox(10,w/3+10,12.5,health_max_wide,15,Color(120,120,120))
			draw.RoundedBox(5,w/3+15,15,health_max_wide*(selected_player:Health() >= selected_player:GetMaxHealth() and selected_player:GetMaxHealth() or selected_player:Health()/selected_player:GetMaxHealth())-10,10,Color(127,255,127))
			]]--
		end

	end,

	Paint = function(self,w,h)
		surface.SetDrawColor(0,0,0,173)
		surface.DrawRect(0,0,w,h)
		Derma_DrawBackgroundBlur(self,0)
	end,
}

vgui.Register("Scoreboard",scoreboard,"DFrame")

local sc = vgui.Create("Scoreboard")
_G.SCOREBOARD = sc
sc:Hide()

local cv_scoreboard = CreateConVar("rpg_scoreboard","1",FCVAR_ARCHIVE,"Enable or disable the rpg scoreboard")
local cv_scoreboard_mouse = CreateConVar("rpg_scoreboard_mouse_on_open","1",FCVAR_ARCHIVE,"Enables cursor on scoreboard opening or not")
cvars.AddChangeCallback("rpg_scoreboard",function(name,old,new)
	if old ~= "0" and sc:IsVisible() then
		sc:Hide()
	end
end)

hook.Add("ScoreboardShow","rpg_scoreboard",function()
	if cv_scoreboard:GetBool() then
		sc:Show()
		if cv_scoreboard_mouse:GetBool() then
			gui.EnableScreenClicker(true)
		end
		return false
	end
end)

hook.Add("ScoreboardHide","rpg_scoreboard",function()
	if cv_scoreboard:GetBool() then
		sc:Hide()
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
			local board = vgui.Create("Scoreboard")
			_G.SCOREBOARD = board
			board:MakePopup()
			board:Hide()
		end
	end
end)
