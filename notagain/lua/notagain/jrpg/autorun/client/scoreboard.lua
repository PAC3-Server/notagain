local prettytext = requirex("pretty_text")
local draw_rect = requirex("draw_skewed_rect")

local scrW, scrH = ScrW(), ScrH()
local resolutionScale = math.Min(scrW/1600 , scrH/900)
local mainMenuSize = {
    w = scrW * .75,
    h = scrH * .8
}
local line_height = 70
local color_blue = Color(60, 127, 255, 255)
local color_red = Color(255, 70, 0, 255)

local gradient = CreateMaterial(tostring({}), "UnlitGeneric", {
    ["$BaseTexture"] = "gui/center_gradient",
    ["$BaseTextureTransform"] = "center .5 .5 scale 1 1 rotate 90 translate 0 0",
    ["$VertexAlpha"] = 1,
    ["$VertexColor"] = 1,
    ["$Additive"] = 1,
})

local border = CreateMaterial(tostring({}), "UnlitGeneric", {
    ["$BaseTexture"] = "props/metalduct001a",
    ["$VertexAlpha"] = 1,
    ["$VertexColor"] = 1,
})

local sprite = Material("particle/fire")

local background = Material("gui/gradient")

hook.Add("PreRender", "ScoreboardCheckResolutionChange", function()
    if (ScrW() != scrW or ScrH() != scrH) then
        scrW, scrH = ScrW(), ScrH()
        mainMenuSize.w = mainMenuSize.w / resolutionScale
        mainMenuSize.h = mainMenuSize.h / resolutionScale
        resolutionScale = math.Min(scrW/1600 , scrH/900 )
        mainMenuSize.w = mainMenuSize.w * resolutionScale
        mainMenuSize.h = mainMenuSize.h * resolutionScale
    end
end)


surface.CreateFont( "InfoFont", {
    font      = "Arial",
    size      = 21,
    weight    = 600,
    shadow    = true
} )

surface.CreateFont( "Sfont", {
    font      = "Arial",
    size      = 17,
    weight    = 600,
    antialias = true,
    additive  = true,
    shadow    = true
} )

surface.CreateFont( "ScoreboardDefaultTitle", {
    font    = "Arial",
    size    = 32,
    weight  = 800,
    shadow  = true
} )

local function formatTime (time)
  local ttime = time or 0
  ttime = math.floor(ttime / 60)
  local m = ttime % 60
  ttime = math.floor(ttime / 60)
  local h = ttime % 24
  ttime = math.floor( ttime / 24 )
  local d = ttime % 7
  local w = math.floor(ttime / 7)
  local str = ""
  str = (w>0 and w.."w " or "")..(d>0 and d.."d " or "")

  return string.format( str.."%02ih %02im", h, m )
end

local function cinputs( command, mode )

--[[
Result in LocalPlayer:ConCommand( command..(Vars from selected modes) )

Modes:
1 - Number
2 - Text

Example:
Text and Number input:
    Mode = 3 (1+2)
Number only input:
    Mode = 1
--]]

    local main = vgui.Create("DFrame")
        main:SetSize(300,150)
        main:SetPos(ScrW()/2-main:GetWide()/2,ScrH()/2-main:GetTall()/2)
        main:SetTitle("Menu")
        main:SetVisible(true)
        main:SetDraggable(true)
        main:ShowCloseButton(true)
        main:SetVisible(true)
        main:MakePopup()
        main.OnClose = function()
            main:SetVisible(false)
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

local ScoreEntries = {}

local PLAYER_LINE = {
    Init = function( self )
        --self:Dock( TOP )
        self:SetSize(0, line_height)
		self:SetPaintedManually(true)
		self:SetCursor("hand")
    end,

    Setup = function( self, pl, friend )
        self.Player = pl
		self.Friend = friend

		local pnl = self:Add("AvatarImage")
		pnl:SetPaintedManually(true)
		pnl:SetPlayer(pl, 184)
		self.Avatar = pnl

        self:Think( self )
    end,

    Think = function( self )
        self:DockMargin( 0, 10, 0, 0 )

        if ( !IsValid( self.Player ) ) then
            self:SetZPos( 9999 ) -- Causes a rebuild
            self:Remove()
            return
        end

        self:SetZPos( self.Player:EntIndex() ) --Sort by Ranks

	end,

	HUDPaint = function(self, w, h)
		local player = self.Player
		local x, y = self:LocalToScreen(0, 0)

		if ( !IsValid( player ) ) then
			return
		end

		self.hover_fade = self.hover_fade or 1

		if self:IsHovered() then
			self.hover_fade = math.min(self.hover_fade + FrameTime() * 10, 1)
		else
			self.hover_fade = math.max(self.hover_fade - FrameTime() * 10, 0)
		end

		local hover = self.hover_fade
		local open_fade = math.min(RealTime() - w_Scoreboard.scoreboard_open_time - (player:EntIndex()/30), 1)

		local ent = player
		local dir = self.Friend and 1 or -1
		local skew = 30 * dir
		--skew = skew * math.sin(os.clock()*5)
		local size_div = 1.2
		local spacing = 8
		local border_size = 10

		h = h - border_size - spacing

		local color = self.Friend and color_blue or color_red
		local text_blur_color = Color(color.r*0.6, color.g*0.6, color.b*0.6, 150)

		if dir < 0 then
			x = x + w - w / size_div
		end

		w = w / size_div

		do
			surface.DisableClipping(true)
			render.ClearStencil()
			render.SetStencilEnable(true)
			render.SetStencilWriteMask(255)
			render.SetStencilTestMask(255)
			render.SetStencilReferenceValue(15)
			render.SetStencilFailOperation(STENCILOPERATION_KEEP)
			render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
			render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
			render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
			render.SetBlend(0)
				surface.SetDrawColor(0,0,0,1)
				draw.NoTexture()
				draw_rect(x,y,w,h, skew, border_size-1)
			render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
		end


		do -- background
			surface.SetDrawColor(25, 25, 25, 230)
			draw.NoTexture()
			draw_rect(x,y,w,h, skew)
		end

		do -- health gradient
			surface.SetMaterial(gradient)
			surface.SetDrawColor(color)

			draw_rect(x, y, w/ent:GetMaxHealth() * (ent:Health() > 100 and 100 or (ent:Health() < 0 and 0 or ent:Health())) , h , skew, 0, 70, 5, gradient:GetTexture("$BaseTexture"):Width())
		end

		do -- name
			local text = ent:Nick()
			local font = "Arial"
			local size = 17
			local weight = 800
			local blursize = 2
			local text_border = 5

			local str_w, str_h = prettytext.GetTextSize(text, font, size, weight, blursize)

			local y = y + 10

			surface.SetDrawColor(0,0,0,230)
			surface.DrawRect(x-20,y,w+40,str_h + text_border)

			local x = x + w/2 + 30*dir
			local y = y + text_border/2
			prettytext.Draw(text, x, y, font, size, weight, blursize, Color(255, 255, 255, 200), nil, -0.5)
		end

		do -- ping
			local bar_height = 12
			local w = w
			local x = x
			local y = y + h - bar_height
			local h = bar_height

			local font = "Gabriola"
			local size = 34
			local weight = 800
			local blursize = 1

			surface.SetDrawColor(0,0,0,100)
			surface.DrawRect(x-40,y,w+80, h)

			local ping = string.format("%03d", player:Ping())

			local str1_w = prettytext.GetTextSize("PING", font, size, weight, blursize)
			local str2_w = prettytext.GetTextSize(ping, "Sylfaen", size*1.1, 1, blursize*5)

			if dir > 0 then
				x = x + w - str1_w - str2_w - 20 - 15
			else
				x = x + 20
			end



			prettytext.Draw("PING", x, y + 2.5, font, size, weight, blursize, Color(255, 255, 255, 200), nil, 0, -0.5)
			prettytext.Draw(ping, x + 45, y, "Sylfaen", size*0.9, 1, blursize, Color(255, 255, 255, 200), nil, 0, -0.5)
			prettytext.Draw("ms", x + str1_w + str2_w + 10, y + 2.5, font, size, weight, blursize, Color(255, 255, 255, 200), nil, 0, -0.5)
		end

		do
			local size = h * 1.15
			local x = x - size / 2
			local y = y - size / 2

			y = y + h / 2
			x = x + (size/3.7 * dir)

			if dir < 0 then
				x = x + w
			end

			--cam.PushModelMatrix

			self.Avatar:SetSize(size,size)
			self.Avatar:PaintAt(x, y)
		end

		do -- frame
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(border)

			for _ = 1, 2 do
				draw_rect(x,y,w,h, skew, 9, 128, border_size - 1, border:GetTexture("$BaseTexture"):Width(), true)
			end
		end

		render.SetStencilEnable(false)
		surface.DisableClipping(false)

		do -- top gloss
			local hover = hover ^ 0.5

			surface.SetDrawColor(Lerp(hover, color.r, color.r*3.5), Lerp(hover, color.g, color.g*3.5), Lerp(hover, color.b, color.b*3.5), Lerp(hover, 30, 40))
			surface.SetMaterial(gradient)
			gradient:SetFloat("$additive", 1)
			draw_rect(x,y,w,h, skew, Lerp(hover, 9, 40), 4, 10, gradient:GetTexture("$BaseTexture"):Width())
		end
	end,

    OnMousePressed = function( self, num )
        local PlayerID = tostring(self.Player:UniqueID())

        if num == MOUSE_RIGHT then

            self.Menu = self:Add( "DMenu" )
            self.Menu:SetAutoDelete( true )

            if aowl then
                local goto = self.Menu:AddOption("Goto", function()
                    RunConsoleCommand( "aowl", "goto", PlayerID )
                end)

                goto:SetImage("icon16/arrow_right.png")

                local bring = goto:AddSubMenu( "Bring" )
                bring:AddOption("Bring",function() RunConsoleCommand( "aowl", "bring", PlayerID  ) end):SetImage("icon16/arrow_in.png")

                local SubAdmin,pic = self.Menu:AddSubMenu("Staff")
                pic:SetImage("icon16/shield.png")
                SubAdmin:AddOption( "Kick",function() cinputs( "aowl kick "..PlayerID  , 1) end):SetImage("icon16/door_in.png")
                SubAdmin:AddOption( "Ban",function() cinputs( "aowl ban "..PlayerID  , 2) end):SetImage("icon16/stop.png")
                SubAdmin:AddSpacer()
                SubAdmin:AddOption( "Reconnect",function() RunConsoleCommand( "aowl", "cexec", PlayerID , "retry") end):SetImage("icon16/arrow_refresh.png")


                self.Menu:AddSpacer()
            end

            if pac then
                local SubPac = self.Menu:AddSubMenu("PAC3")

                SubPac:AddOption( "Ignore",function() pac.IgnoreEntity(self.Player) end)
                SubPac:AddOption( "Unignore",function() pac.UnIgnoreEntity(self.Player) end)

                self.Menu:AddSpacer()
            end

            self.Menu:AddOption("Copy SteamID",function() SetClipboardText(self.Player:SteamID()) chat.AddText(Color(255,255,255),"You copied "..self.Player:Nick().."'s SteamID") end):SetImage("icon16/tab_edit.png")

            RegisterDermaMenuForClose( self.Menu )
            self.Menu:Open()

        elseif num == MOUSE_LEFT then
            RunConsoleCommand( "aowl", "goto", PlayerID )
        end

    end,

}

local SCORE_BOARD = {
    Init = function( self )
		--self:DockMargin(5,5,5,5)
        self.Header = self:Add( "Panel" )
        self.Header:Dock( TOP )
        self.Header:SetHeight( 100 )
        self.Header:DockMargin( 0,0,0,15)
		self.Header.Paint = function(_, w, h)
			local maxw, maxh = 0,0

			--local w, h = prettytext.Draw("FPS: " .. math.Round(1 / FrameTime()), 0, 0, "Arial", 30, 800, 3)
			--maxw = math.max(maxh, w)
			--maxh = math.max(maxh, h)

			--local w, h = prettytext.Draw("TIME: " .. os.date("%X"), 0, 0, "Arial", 30, 800, 3)
			--maxw = math.max(maxh, w)
			--maxh = math.max(maxh, h)



			prettytext.Draw(GetHostName(), w/2, 0, "Gabriola", 120, 800, 10, Color(255, 255, 255, 200), Color(75,75, 75, 50), -0.5)
		end

        self.Scroll = self:Add( "DScrollPanel" )
        self.Scroll:Dock( FILL )

		self.ScoresLeft = self.Scroll:Add("DListLayout")
		self.ScoresLeft:Dock(LEFT)
		self.ScoresLeft:DockPadding(40,0,0,0)

		self.ScoresRight = self.Scroll:Add("DListLayout")
		self.ScoresRight:Dock(RIGHT)
		self.ScoresRight:DockPadding(0,0,40,0)

		self.Scroll:AddItem(self.ScoresLeft)
		self.Scroll:AddItem(self.ScoresRight)
    end,

    PerformLayout = function( self )

        self:SetSize( mainMenuSize.w, mainMenuSize.h )
		self.ScoresLeft:SetWide(mainMenuSize.w/2)
		self.ScoresRight:SetWide(mainMenuSize.w/2)
		self.ScoresRight:SetTall(select(2, self.ScoresRight:ChildrenSize()))
		self.ScoresLeft:SetTall(select(2, self.ScoresLeft:ChildrenSize()))
        self:Center()

    end,

    Think = function( self, w, h )
        for id, pl in pairs( player.GetAll() ) do

            if ( IsValid( ScoreEntries[pl:UniqueID()] ) ) then continue end

            local line = vgui.CreateFromTable( PLAYER_LINE )
            line:Setup( pl, pl:GetFriendStatus() == "friend" or pl == LocalPlayer() )

			if line.Friend then
				self.ScoresLeft:Add( line )
			else
				self.ScoresRight:Add( line )
			end

			ScoreEntries[pl:UniqueID()] = line
        end
	end
}

PLAYER_LINE = vgui.RegisterTable( PLAYER_LINE, "DPanel" )
SCORE_BOARD = vgui.RegisterTable( SCORE_BOARD, "EditablePanel" )

local ysc_convar = CreateClientConVar( "yscoreboad_show", "1", true, false )
ysc_convar:SetInt(1)

if IsValid(w_Scoreboard) then
	w_Scoreboard:Remove()
end

w_Scoreboard = nil

local function YScoreboardShow()
    if ysc_convar:GetInt() == 1 then

        if ( !IsValid( w_Scoreboard ) ) then
            w_Scoreboard = vgui.CreateFromTable( SCORE_BOARD )
        end

        if ( IsValid( w_Scoreboard ) ) then
			w_Scoreboard.scoreboard_open_time = RealTime()
            w_Scoreboard:Show()
            w_Scoreboard:SetKeyboardInputEnabled( false )
            w_Scoreboard:SetMouseInputEnabled( true )
			w_Scoreboard.Scroll:InvalidateLayout()
        end

        w_Scoreboard:MakePopup()
        w_Scoreboard:SetKeyboardInputEnabled( false )

		hook.Add("HUDDrawScoreBoard", "scoreboard", function()
			if false then
				local x, y = 0, 0
				local w, h = ScrW(), ScrH()
				surface.SetMaterial(gradient)

				surface.SetAlphaMultiplier(0.05)
				surface.SetDrawColor(color_red)
				surface.DrawTexturedRectRotated(x + w,y,w,h*10,0)
				surface.SetDrawColor(color_blue)
				surface.DrawTexturedRectRotated(x,y,w,h*10,180)
				surface.SetAlphaMultiplier(1)
			end


			do
				local x, y = w_Scoreboard:GetPos()
				local w, h = w_Scoreboard:GetSize()

				surface.SetDrawColor(255, 255, 255, 255)

				y = select(2, w_Scoreboard.Header:LocalToScreen()) + w_Scoreboard.Header:GetTall()
				x = x + w / 2

				surface.SetMaterial(sprite)
				local size = w * 1.5
				surface.DrawTexturedRect(x - size / 2, y, size, 6)
				surface.DrawTexturedRect(x - size / 2, y, size, 6)
			end

			local x,y = w_Scoreboard.Scroll:LocalToScreen()
			local w,h = w_Scoreboard.Scroll:GetSize()
			x = x - 100
			w = w + 200
			y = y - 50
			h = h + 50
			render.SetScissorRect(x,y,x+w,y+h, true)

			for _, pnl in ipairs(w_Scoreboard.ScoresLeft:GetChildren()) do
				pnl:HUDPaint(pnl:GetWide(), pnl:GetTall())
			end

			for _, pnl in ipairs(w_Scoreboard.ScoresRight:GetChildren()) do
				pnl:HUDPaint(pnl:GetWide(), pnl:GetTall())
			end

			render.SetScissorRect(0,0,0,0, false)
		end)

        return false
    end

end

local function YScoreboardHide()
    if ysc_convar:GetInt() == 1 then
        if ( IsValid( w_Scoreboard ) ) then
            w_Scoreboard:SetMouseInputEnabled( false )
            w_Scoreboard:Hide()

            hook.Remove("HUDDrawScoreBoard","scoreboard")
        end
        CloseDermaMenus()
    end
end

hook.Add("ScoreboardShow","YScoreboardShow",YScoreboardShow)
hook.Add("ScoreboardHide","YScoreboardHide",YScoreboardHide)
