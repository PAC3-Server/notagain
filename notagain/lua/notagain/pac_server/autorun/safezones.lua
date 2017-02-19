AddCSLuaFile()

local SAFE_ZONE_BASE = {}

SAFE_ZONE_BASE.Base 	 = "base_anim"
SAFE_ZONE_BASE.Type 	 = "anim"
SAFE_ZONE_BASE.PrintName = "Safe Zone"
SAFE_ZONE_BASE.Author	 = "Yara"
SAFE_ZONE_BASE.Spawnable = true
SAFE_ZONE_BASE.AdminOnly = false -- Lets see what happens

if CLIENT then

	surface.CreateFont( "SZFont" , {
    	font      = "Arial",
    	size      = 18,
    	weight    = 600,
	} )
	
	local scrW, scrH = ScrW(), ScrH()
	local resolutionScale = math.Min(scrW/1600 , scrH/900)
	local LastSafeZoneRadius = 0
	local PanelOpened = false
	local ChatTag = "[SafeZone]:"

	local r,g,b = 0,0.1,0
	local GlareMat = Material("sprites/light_ignorez")
	local WarpMat = Material("particle/warp2_warp")
	local Emitter2D = ParticleEmitter(vector_origin)
	Emitter2D:SetNoDraw(true)


	local WarnMat = CreateMaterial(tostring{}, "UnlitGeneric", {
		["$BaseTexture"] = "phoenix_storms/stripes",

	})
	
	local Shiny = CreateMaterial(tostring({}) .. os.clock(), "VertexLitGeneric", {
		["$Additive"] = 1,
		["$Translucent"] = 1,

		["$Phong"] = 1,
		["$PhongBoost"] = 10,
		["$PhongExponent"] = 5,
		["$PhongFresnelRange"] = Vector(0,0.5,1),
		["$PhongTint"] = Vector(1,1,1),


		["$Rimlight"] = 1,
		["$RimlightBoost"] = 50,
		["$RimlightExponent"] = 5,

		["$BaseTexture"] = "models/debug/debugwhite",
		["$BumpMap"] = "dev/bump_normal",
	})

	local SmokeMat = CreateMaterial(tostring{}, "UnlitGeneric", {
		["$BaseTexture"] = "particle/particle_smokegrenade",
		["$Additive"] = 1,
		["$Translucent"] = 1,
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
		["$IgnoreZ"] = 1,

	})

	local Smoke2Mat = CreateMaterial(tostring{}, "UnlitGeneric", {
		["$BaseTexture"] = "effects/blood_core",
		["$Additive"] = 1,
		["$Translucent"] = 1,
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
		["$IgnoreZ"] = 1,
	})

	local Glare2Mat = CreateMaterial(tostring{}, "UnlitGeneric", {
		["$BaseTexture"] = "particle/fire",
		["$Additive"] = 1,
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
	})

	local FireMat = CreateMaterial(tostring{}, "UnlitGeneric", {
		["$BaseTexture"] = "particle/water/watersplash_001a",
		["$Additive"] = 1,
		["$Translucent"] = 1,
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
	})

	local PANEL = {
	 	
	 	Init = function( self )
	 		
	 		self.Frame = self:Add( "DFrame" )
	 		self.Frame:SetSize( 400 , 175 )
	 		self.Frame:SetPos( scrW / 2 - self.Frame:GetWide() / 2 , scrH / 2 - self.Frame:GetTall() / 2 )
	 		self.Frame:ShowCloseButton( false )
	 		self.Frame:SetDraggable( true )
	 		self.Frame:SetTitle( "Safe Zone Settings" )
	 		self.Frame:MakePopup()
	 		
	 		self.Frame.Paint = function()
	 			surface.SetDrawColor( 255 , 255 , 255 )
	 			surface.SetMaterial(WarnMat)
	 			surface.DrawTexturedRect(0,0,self.Frame:GetWide(),self.Frame:GetTall())
	 			surface.SetDrawColor(0,0,0)
	 			surface.DrawOutlinedRect(0,0,self.Frame:GetWide(),self.Frame:GetTall())
	 			surface.DrawRect(0,0,self.Frame:GetWide(),25)
	 		end

	 		self.RSlider = self.Frame:Add( "DNumSlider" )
	        self.RSlider:SetSize( 400 , 50 )
	        self.RSlider:SetPos( 60 - self.RSlider:GetWide() / 2 , 50 - self.RSlider:GetTall() / 2 )
	        self.RSlider:SetMin( 0 )
	        self.RSlider:SetMax( 500 )
	        self.RSlider:SetDecimals( 0 )
	        self.RSlider.OnValueChanged = function( _ , int )
	        	LastSafeZoneRadius = math.Round( int )
	        end

	        self.RSlider.Paint = function()
	        	surface.SetDrawColor( 255 , 255 , 255 )
	        	surface.DrawRect(165,13,self.RSlider:GetWide()-185,self.RSlider:GetTall()-20)
	        	surface.SetDrawColor( 0 , 0 , 0 )
	        	surface.DrawOutlinedRect(165,13,self.RSlider:GetWide()-185,self.RSlider:GetTall()-20)
	    	end

	    	self.RSet = self.Frame:Add( "DButton" )
	        self.RSet:SetTextColor( Color( 255 , 255 , 255 ) )
	        self.RSet:SetText( "Set" )
	        self.RSet:SetWide( 125 )
	        self.RSet:SetPos( 315 - self.RSet:GetWide() / 2 , 50 - self.RSet:GetTall() / 2 )
	        self.RSet.Paint = function()
    			surface.SetDrawColor(0,0,0)
    			surface.DrawRect(0,0,self.RSet:GetWide(),self.RSet:GetTall())
    			surface.SetDrawColor( 255 , 255 , 255 )
    			surface.DrawOutlinedRect(0,0,self.RSet:GetWide(),self.RSet:GetTall())
	    	end

	    	self.RSet.DoClick = function()
	    		net.Start( "SafeZoneSetRadius" )
	    		net.WriteString( tostring( LastSafeZoneRadius ) )
	    		net.SendToServer()
	    		chat.AddText( Color( 255 , 255 , 255 ) , ChatTag .. " radius set to "..LastSafeZoneRadius )
	    	end

			self.PList = self.Frame:Add( "DComboBox" )
	        self.PList:SetValue( "-------------" )
	        self.PList:SetWide( 200 )
	        self.PList:SetPos( 125 - self.PList:GetWide() / 2 , 100 - self.PList:GetTall() / 2 )
	        
	        for k,v in pairs(player.GetAll()) do
	        	self.PList:AddChoice( v:EntIndex().." -- "..v:Nick():gsub("<(.+)=(.+)>","") )
	        end


	        self.PAdd = self.Frame:Add( "DButton" )
	        self.PAdd:SetTextColor( Color( 255 , 255 , 255 ) )
	        self.PAdd:SetText( "Allow" )
	        self.PAdd:SetWide( 50 )
	        self.PAdd:SetPos( 275 - self.PAdd:GetWide() / 2 , 100 - self.PAdd:GetTall() / 2 )
	        self.PAdd.Paint = function()
    			surface.SetDrawColor(0,0,0)
    			surface.DrawRect(0,0,self.PAdd:GetWide(),self.PAdd:GetTall())
    			surface.SetDrawColor( 255 , 255 , 255 )
    			surface.DrawOutlinedRect(0,0,self.PAdd:GetWide(),self.PAdd:GetTall())
	    	end
	    	
	    	self.PAdd.DoClick = function()
	    		local str,_ = self.PList:GetSelected() 
	    		local plindex = string.Split( str , " -- "  )[1]
	    		net.Start( "SafeZoneAllowPlayer" )
	    		net.WriteString( plindex )
	    		net.SendToServer()
	    		chat.AddText( Color( 255 , 255 , 255 ) , ChatTag.." "..Entity(plindex):Nick():gsub("<(.+)=(.+)>","").." was added to trusted players" )

	    	end

	    	self.PRemove = self.Frame:Add( "DButton" )
	        self.PRemove:SetTextColor( Color( 255 , 255 , 255 ) )
	        self.PRemove:SetText( "Disallow" )
	        self.PRemove:SetWide( 50 )
	        self.PRemove:SetPos( 350 - self.PRemove:GetWide() / 2 , 100 - self.PRemove:GetTall() / 2 )
	        self.PRemove.Paint = function()
    			surface.SetDrawColor(0,0,0)
    			surface.DrawRect(0,0,self.PRemove:GetWide(),self.PRemove:GetTall())
    			surface.SetDrawColor( 255 , 255 , 255 )
    			surface.DrawOutlinedRect(0,0,self.PRemove:GetWide(),self.PRemove:GetTall())
	    	end
	    
	    	self.PRemove.DoClick = function()
	    		local str,_ = self.PList:GetSelected() 
	    		local plindex = string.Split( str , " -- "  )[1]
	    		net.Start( "SafeZoneDisallowPlayer" )
	    		net.WriteString( plindex )
	    		net.SendToServer()
	    		chat.AddText( Color( 255 , 255 , 255 ) , ChatTag.." "..Entity(plindex):Nick():gsub("<(.+)=(.+)>","").." was removed from trusted players" )

	    	end


	    	self.Exit = self.Frame:Add( "DButton" )
	        self.Exit:SetTextColor( Color( 255 , 255 , 255 ) )
	        self.Exit:SetText( "Exit" )
	        self.Exit:SetWide( 100 )
	        self.Exit:SetPos( 200 - self.Exit:GetWide() / 2 , 150 - self.Exit:GetTall() / 2 )
	       	self.Exit.Paint = function()
    			surface.SetDrawColor(0,0,0)
    			surface.DrawRect(0,0,self.Exit:GetWide(),self.Exit:GetTall())
    			surface.SetDrawColor( 255 , 255 , 255 )
    			surface.DrawOutlinedRect(0,0,self.Exit:GetWide(),self.Exit:GetTall())
	    	end
	    	
	    	self.Exit.DoClick = function()
	    		self.Frame:Close()
	    		PanelOpened = false
	    	end
	 	
	 	end,

	}
	
	SAFE_ZONE_PANEL = vgui.RegisterTable( PANEL , "EditablePanel" )

	function SAFE_ZONE_BASE:AddEffect()
		
		render.SetColorModulation(r, g, b)
		render.MaterialOverride(Shiny)

		local Pos = self:WorldSpaceCenter() + Vector(0,0,50)
		
		self.PixelVisible = self.PixelVisible or util.GetPixelVisibleHandle()
		self.PixelVisible2 = self.PixelVisible2 or util.GetPixelVisibleHandle()
		
		local Radius = self:BoundingRadius()
		local Visi = util.PixelVisible(Pos, Radius*0.5, self.PixelVisible)
		local Time = RealTime()
		local Glow = math.abs(math.sin(Time))
		local r = Radius/8

		cam.IgnoreZ(true)

		render.SetMaterial(WarpMat)
		render.DrawSprite(Pos, 25, 25, Color(r*255*2, g*255*2, b*255*2, Visi*20))
		render.SetMaterial(Glare2Mat)
		render.DrawSprite(Pos, r*10, r*10, Color(200, 255, 200, Visi*255*Glow+3))
		render.DrawSprite(Pos, r*15, r*15, Color(150, 255, 150, Visi*255*(Glow+3.25)))
		render.DrawSprite(Pos, r*20, r*20, Color(100, 200, 100, Visi*150*(Glow+3.50)))
		render.SetMaterial(GlareMat)
		
		cam.IgnoreZ(false)

		self:DrawModel()

		if not self.NextEmit2 or self.NextEmit2 < Time then

			local p = Emitter2D:Add(Glare2Mat, Pos + (VectorRand()*Radius*0.5))
			
			p:SetDieTime(math.Rand(2,4))
			p:SetLifeTime(1)

			p:SetStartSize(math.Rand(16,32))
			p:SetEndSize(0)

			p:SetStartAlpha(0)
			p:SetEndAlpha(255)

			p:SetColor(150, 225, 150)

			p:SetVelocity(VectorRand()*5)
			p:SetGravity(Vector(0,0,3))
			p:SetAirResistance(30)

			self.NextEmit2 = Time + 0.1

			if math.random() > 0.2 then
				
				local p = Emitter2D:Add(Glare2Mat, Pos + (VectorRand()*Radius*0.5))
				
				p:SetDieTime(math.Rand(1,3))
				p:SetLifeTime(1)

				p:SetStartSize(math.Rand(16,32))
				p:SetEndSize(0)

				p:SetStartAlpha(255)
				p:SetEndAlpha(255)

				p:SetVelocity(VectorRand()*3)
				p:SetGravity(Vector(0,0,math.Rand(3,5)))
				p:SetAirResistance(30)

				p:SetNextThink(CurTime())

				local Seed = math.random()
				local Seed2 = math.Rand(-4,4)

				p:SetThinkFunction(function(p)
					
					p:SetStartSize(math.abs(math.sin(Seed+Time*Seed2)*3+math.Rand(0,2)))
					p:SetColor(math.Rand(200, 255), math.Rand(200, 255), math.Rand(200, 255))
					p:SetNextThink(CurTime())
				
				end)

			end
		
		end

		Emitter2D:Draw()

		render.SetColorModulation(1,1,1)
		render.MaterialOverride()
	end

	function SAFE_ZONE_BASE:Initialize()
		hook.Add("PostDrawTranslucentRenderables", "SafeZone"..self:EntIndex() , function() self:AddEffect() end )
	end

	function SAFE_ZONE_BASE:OnRemove()
		hook.Remove( "PostDrawTranslucentRenderables", "SafeZone"..self:EntIndex() )
	end

	net.Receive( "SafeZonePanel" , function()
		
		if PanelOpened then return end 
		
		vgui.CreateFromTable( SAFE_ZONE_PANEL )
		PanelOpened = true
	
	end)

end

if SERVER then

	util.AddNetworkString( "SafeZonePanel" )
	util.AddNetworkString( "SafeZoneAllowPlayer" )
	util.AddNetworkString( "SafeZoneDisallowPlayer" )
	util.AddNetworkString( "SafeZoneSetRadius" )
	
	local META = FindMetaTable("Entity")

	function META:Dissolve()
		
		if IsValid( self ) then 

			self:SetName( "dissolve_target" )
			
			local Effect = ents.Create( "env_entity_dissolver" )
			Effect:SetKeyValue( "target" , "dissolve_target" )
			Effect:SetKeyValue( "dissolvetype", "3" )
			Effect:SetKeyValue( "magnitude" , "200" )
			Effect:SetColor( Color( 50 , 255 ,50 ) )
			Effect:Spawn()
			Effect:Activate()
			Effect:Fire( "Dissolve" , "dissolve_target", 0 )
			
			SafeRemoveEntity( Effect )

		end
	
	end

 	function SafeZoneBlackList( ply , ent )
		if ent:GetClass() == "safe_zone" then
			return false
		end
	end

	function SAFE_ZONE_BASE:SpawnFunction( ply , tr )
	   	
		if !tr.Hit or ply.SafeZone then return end 
		
		local SpawnPos = tr.HitPos 

		for k,v in pairs(ents.FindInSphere(	SpawnPos + Vector( 0 , 0 , 50 ) , 500 ) ) do
			if v:IsPlayer() and v != ply then
				return
			end
		end

		
		local ent = ents.Create( "safe_zone" )
		ent:SetPos( SpawnPos ) 
		ent:SetModel( "models/props_combine/CombineThumper002.mdl" )
		ent:SetModelScale( 0.4 )
		ent:Spawn()
		ent:Activate() 

		ent.PlayersAllowed = {}
		ent.PlayersAllowed[ply:EntIndex()] = ply
		ent.Radius = 200
		ply.LastSafeZone = ent
		ply.SafeZone = true

		local Sphere = ents.Create( "prop_physics" )
		Sphere:SetModel( "models/XQM/Rails/gumball_1.mdl" )
		Sphere:SetMaterial( "models/props_combine/portalball001_sheet" )
		Sphere:SetPos( ent:WorldSpaceCenter() + Vector( 0 , 0 , 50 ) )
		Sphere:SetParent( ent )
		Sphere:SetColor( Color( 150 , 255 , 150 , 100 ) )
		Sphere:SetAngles( Angle( 90 , 0 , 0 ) )
		Sphere:Spawn()
		Sphere:Activate()
		Sphere:DrawShadow( false )
		Sphere.Protected = true

		local Sphere2 = ents.Create( "prop_physics" )
		Sphere2:SetModel( "models/XQM/Rails/gumball_1.mdl" )
		Sphere2:SetMaterial( "models/props_combine/portalball001_sheet" )
		Sphere2:SetPos( ent:WorldSpaceCenter() + Vector( 0 , 0 , 50 ) )
		Sphere2:SetParent( ent )
		Sphere2:SetColor( Color( 150 , 255 , 150 , 100 ) )
		Sphere2:SetAngles( Angle( -90 , 0 , 0 ) )
		Sphere2:Spawn()
		Sphere2:Activate()
		Sphere2:DrawShadow( false )
		Sphere2.Protected = true

		ent.Sphere = Sphere 
		ent.Sphere2 = Sphere2
		ent.TempRadius = 0

		return ent 
		
	end

	function SAFE_ZONE_BASE:Initialize()
	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_VPHYSICS )
		
		self:SetUnFreezable( true )

	end

	
	function SAFE_ZONE_BASE:Use( activator , caller )
		if self:IsAllowed( caller ) then
			caller.LastSafeZone = self
			net.Start( "SafeZonePanel" )
			net.Send( caller )
		end

	end
	 
	function SAFE_ZONE_BASE:Think() --stays like this for now


		local scale = self.Sphere:GetModelScale() / self.Sphere:BoundingRadius()

		self.Sphere:SetModelScale( self.Radius * 2 * scale , 0 )
		self.Sphere2:SetModelScale( self.Radius * 2 * scale , 0 )
		
		for _,v in pairs( ents.FindInSphere( self:WorldSpaceCenter() + Vector( 0 , 0 , 50 ) , self.Radius ) ) do

			if v:CPPIGetOwner() then
				
				if v:GetClass() != "safe_zone" and !self:IsAllowed( v:CPPIGetOwner() ) and !v:CPPIGetOwner():IsAdmin() then
					v:Dissolve()
				end
			
			elseif v:IsPlayer() and !self:IsAllowed( v ) and !v:IsAdmin() then 

					local dif = v:GetPos() - self:GetPos()
					
					v:SetPos( self:GetPos() + dif / self.Radius * ( self.Radius +  v:GetPos():Distance( self:GetPos() ) ) )

			end
		
		end

		self:NextThink( CurTime() )
		
		return true

	end

	function SAFE_ZONE_BASE:OnRemove()
		if self:CPPIGetOwner() then
			self:CPPIGetOwner().SafeZone = false
		end
		
	end

	function SAFE_ZONE_BASE:AllowPlayer( ply )
		if IsValid( ply ) and ply:IsPlayer() then
			self.PlayersAllowed[ply:EntIndex()] = ply 
		end
	end

	function SAFE_ZONE_BASE:DisallowPlayer( ply )
		if IsValid( ply ) and ply:IsPlayer() then
			self.PlayersAllowed[ply:EntIndex()] = nil 
		end
	end

	function SAFE_ZONE_BASE:IsAllowed( ply )
		if IsValid( ply ) and ply:IsPlayer() then
			return self.PlayersAllowed[ply:EntIndex()] and true or false
		else
			return nil
		end
	end
	
	hook.Add( "PhysgunPickup" , "SafeZoneAntiPickup" , SafeZoneBlackList )
	hook.Add( "CanDrive" , "SafeZoneAntiDrive" , SafeZoneBlackList )

	net.Receive( "SafeZoneAllowPlayer" , function( len , ply )
		local index = net.ReadString()
		local rply = Entity( tonumber( index ) )

		if IsValid( ply ) and ply:IsPlayer() and ply.LastSafeZone and ply.LastSafeZone:GetClass() == "safe_zone" and ply.LastSafeZone:IsAllowed( ply ) then
			ply.LastSafeZone:AllowPlayer( rply )
		end
	end )

	net.Receive( "SafeZoneDisallowPlayer" , function( len , ply )
		local index = net.ReadString()
		local rply = Entity( tonumber( index ) )

		if IsValid( ply ) and ply:IsPlayer() and ply.LastSafeZone and ply.LastSafeZone:GetClass() == "safe_zone" and ply.LastSafeZone:IsAllowed( ply ) then
			ply.LastSafeZone:DisallowPlayer( rply )
		end
	end )

	net.Receive( "SafeZoneSetRadius" , function( len , ply )
		local int = tonumber(net.ReadString())
		
		int = int > 500 and 500 or int --Clamping like a pro or not
	    int = int < 0 and 0 or int

		if IsValid( ply ) and ply:IsPlayer() and ply.LastSafeZone and ply.LastSafeZone:GetClass() == "safe_zone" and ply.LastSafeZone:IsAllowed( ply ) then
			ply.LastSafeZone.Radius = int
		end

	end )


end

scripted_ents.Register( SAFE_ZONE_BASE , "safe_zone" )
