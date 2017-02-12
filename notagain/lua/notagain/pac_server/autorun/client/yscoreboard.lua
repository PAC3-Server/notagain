AddCSLuaFile()

local scrW, scrH = ScrW(), ScrH()
local resolutionScale = math.Min(scrW/1600 , scrH/900)
local mainMenuSize = {
    w = scrW * .65,
    h = scrH * .85
}

local prettytext = requirex("pretty_text")

local draw_rect = requirex("draw_skewed_rect")

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
        self:Dock( TOP )
        self:SetHeight( 70 )
		self:SetPaintedManually(true)
    end,

    Setup = function( self, pl )
        self.Player = pl
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

	Paint = function(self, w, h)
		--cam.PushModelMatrix(m)
		local player = self.Player
		local x, y = self:LocalToScreen(0, 20)

		if ( !IsValid( player ) ) then
			return
		end
		local w = w / 2
		local h = h / 2
		local ent = player
		local skew = 30


		do
			local y = y - h
			local w = w / 4
			local h = h * 1.5

			surface.SetDrawColor(25, 25, 25, 230)
			draw.NoTexture()
			draw_rect(x,y,w,h, skew, 0)

			border:SetFloat("$additive", 1)
			surface.SetDrawColor(255, 255, 255, 150)
			surface.SetMaterial(border)
			draw_rect(x,y,w,h, skew, 0, 128, 7, border:GetTexture("$BaseTexture"):Width(), true)

			prettytext.Draw(ent:EntIndex(), x+w/6, y, "Candara", 80, 800, 3, Color(230, 230, 230, 80), Color(0,0,0,80), -0.5, -0.2)
		end

		surface.SetDrawColor(25, 25, 25, 230)
		draw.NoTexture()
		draw_rect(x,y,w,h, skew)

		surface.SetMaterial(gradient)

		surface.SetDrawColor((ent:GetFriendStatus() == "friend" or ent == LocalPlayer()) and Color(30, 50, 255, 255) or Color(255, 50, 30, 255) )

		for _ = 1, 2 do
			draw_rect(x, y, w/ent:GetMaxHealth() * (ent:Health() > 100 and 100 or (ent:Health() < 0 and 0 or ent:Health())) , h , skew, 0, 70, 5, gradient:GetTexture("$BaseTexture"):Width())
		end

		prettytext.Draw(ent:Nick(), x+w/2, y+h/2, "Arial", 26, 800, 3, Color(230, 230, 230, 255), Color(25,70,100,255), -0.5, -0.5)

		surface.SetDrawColor(255, 255, 255, 15)
		surface.SetMaterial(gradient)
		draw_rect(x,y,w,h, skew, 0, 70, 10, gradient:GetTexture("$BaseTexture"):Width())


		border:SetFloat("$additive", 0)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(border)

		for _ = 1, 2 do
			draw_rect(x,y,w,h, skew, 0, 64, 5, border:GetTexture("$BaseTexture"):Width(), true)
		end

		prettytext.Draw(ent:Health().."/"..ent:GetMaxHealth(), x + w/10 , y + h/2 , "Arial", 23, 900, 4, Color(230, 230, 230, 255), Color(25,70,100,255),0,-0.5)
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
        self.Header = self:Add( "Panel" )
        self.Header:Dock( TOP )
        self.Header:SetHeight( 70 )
        self.Header.Paint = function()
            local w,h = self.Header:GetWide(),self.Header:GetTall()

            surface.SetDrawColor(255, 255, 255, 255)
            draw.NoTexture()
            surface.DrawRect(0,h-30,w,2)
        end

        self.Name = self.Header:Add( "Panel" )
        self.Name:Dock( TOP )
        self.Name:SetHeight( 150 )
		self.Name.Paint = function()
			prettytext.Draw(self.Name.hostname or "aaaaaaaaaaaa", 0, 0, "Arial", 30, 800, 3, nil, nil, 0, 0)
		end

        self.Footer = self:Add( "Panel" )
        self.Footer:Dock( TOP )
        self.Footer:SetHeight( 30 )

        self.Footer.Fps = self.Footer:Add( "DLabel" )
        self.Footer.Fps:SetFont( "Sfont" )
        self.Footer.Fps:SetTextColor( Color( 255, 255, 255, 255 ) )
        self.Footer.Fps:Dock( RIGHT )
        self.Footer.Fps:DockMargin( 0, 0, 120, 0 )
        self.Footer.Fps:SetWidth( 35 )
        self.Footer.Fps:SetContentAlignment( 3 )

        self.Footer.FpsName = self.Footer:Add( "DLabel" )
        self.Footer.FpsName:SetFont( "Sfont" )
        self.Footer.FpsName:SetTextColor( Color( 255, 255, 255, 255 ) )
        self.Footer.FpsName:Dock( RIGHT )
        self.Footer.FpsName:DockMargin( 0, 0, 0, 0 )
        self.Footer.FpsName:SetWidth( 50 )
        self.Footer.FpsName:SetText( "FPS: " )
        self.Footer.FpsName:SetContentAlignment( 3 )

        self.Footer.Time = self.Footer:Add( "DLabel" )
        self.Footer.Time:SetFont( "Sfont" )
        self.Footer.Time:SetTextColor( Color( 255, 255, 255, 255 ) )
        self.Footer.Time:Dock( RIGHT )
        self.Footer.Time:DockMargin( 0, 0, 20, 0 )
        self.Footer.Time:SetWidth( 90 )
        self.Footer.Time:SetContentAlignment( 3 )

        self.Footer.TimeName = self.Footer:Add( "DLabel" )
        self.Footer.TimeName:SetFont( "Sfont" )
        self.Footer.TimeName:SetTextColor( Color( 255, 255, 255, 255 ) )
        self.Footer.TimeName:Dock( RIGHT )
        self.Footer.TimeName:DockMargin( 0, 0, 0, 0 )
        self.Footer.TimeName:SetWidth( 120 )
        self.Footer.TimeName:SetText( "Current time: " )
        self.Footer.TimeName:SetContentAlignment( 3 )



        self.Scores = self:Add( "DScrollPanel" )
        self.Scores:Dock( FILL )

    end,

    PerformLayout = function( self )

        self:SetSize( mainMenuSize.w, mainMenuSize.h )
        self:Center()

    end,

    Think = function( self, w, h )

        self.Footer.Time:SetText( os.date("%X") )
        self.Footer.Fps:SetText( math.Round( 1/FrameTime() ) )
        self.Name.hostname = GetHostName()

        for id, pl in pairs( player.GetAll() ) do

            if ( IsValid( ScoreEntries[pl:EntIndex()] ) ) then continue end

            ScoreEntries[pl:EntIndex()] = vgui.CreateFromTable( PLAYER_LINE )
            ScoreEntries[pl:EntIndex()]:Setup( pl )

            self.Scores:AddItem( ScoreEntries[pl:EntIndex()] )
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
            w_Scoreboard:Show()
            w_Scoreboard:SetKeyboardInputEnabled( false )
            w_Scoreboard:SetMouseInputEnabled( true )
        end

        w_Scoreboard:MakePopup()
        w_Scoreboard:SetKeyboardInputEnabled( false )

		hook.Add("HUDPaint", "scoreboard", function()
			for _, pnl in ipairs(w_Scoreboard.Scores:GetCanvas():GetChildren()) do
				pnl:Paint(pnl:GetWide(), pnl:GetTall())
			end
		end)

        return false
    end

end

local function YScoreboardHide()
    if ysc_convar:GetInt() == 1 then
        if ( IsValid( w_Scoreboard ) ) then
            w_Scoreboard:SetMouseInputEnabled( false )
            w_Scoreboard:Hide()

            hook.Remove("HUDPaint","scoreboard")
        end
        CloseDermaMenus()
    end
end

hook.Add("ScoreboardShow","YScoreboardShow",YScoreboardShow)
hook.Add("ScoreboardHide","YScoreboardHide",YScoreboardHide)
