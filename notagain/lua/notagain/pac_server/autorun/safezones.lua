AddCSLuaFile()

--TODO:
--remove field and add plant gen on ground
--Remove think and make it on touch

local SAFE_ZONE_BASE = {}
local SAFE_ZONE_SPHERE = {}

SAFE_ZONE_BASE.Base 	 = "base_anim"
SAFE_ZONE_BASE.Type 	 = "anim"
SAFE_ZONE_BASE.PrintName = "Safe Zone"
SAFE_ZONE_BASE.Author	 = "Yara"
SAFE_ZONE_BASE.Spawnable = true
SAFE_ZONE_BASE.AdminOnly = true

SAFE_ZONE_SPHERE.Base 	 = "base_anim"
SAFE_ZONE_SPHERE.Type 	 = "anim"

if CLIENT then

	surface.CreateFont( "SZFont" , {
    	font      = "Arial",
    	size      = 18,
    	weight    = 600,
	} )
	
	local scrW, scrH = ScrW(), ScrH()
	local resolutionScale = math.Min(scrW/1600 , scrH/900)
	local LastSafeZoneRadius = 0
	local ChatTag = "[SafeZone]:"

	local r,g,b = 0,0.1,0
	local GlareMat = Material("sprites/light_ignorez")
	local WarpMat = Material("particle/warp2_warp")
	local Emitter2D = ParticleEmitter(vector_origin)
	Emitter2D:SetNoDraw(true)

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

	local PANEL = { -- Probably will have to redo UI since it looks a bit ugly
		
		Init = function( self )
			self.Header = self:Add( "Panel" )
        	self.Header:Dock( TOP )
        	self.Header:SetHeight( 40 )
       		self.Header.Paint = function()
            	local w,h = self.Header:GetWide(),self.Header:GetTall()

            	surface.SetDrawColor( 255 , 255 , 255 , 255 )
           		draw.NoTexture()
            	surface.DrawRect( 0 , h - 2 , w , 2)
        	end

        	self.Title = self.Header:Add( "DLabel" )
	        self.Title:SetFont( "DermaLarge" )
	        self.Title:SetTextColor( Color( 255, 255, 255, 255 ) )
	        self.Title:Dock( TOP )
	        self.Title:SetHeight( 40 )
	        self.Title:SetContentAlignment( 2 )
	        self.Title:SetText( "Safe Zone" )

	        self.Radius = self:Add( "Panel" )
	        self.Radius:Dock( TOP )
	        self.Radius:DockMargin( 0 , 10 , 0 , 0 )
	        self.Radius:SetHeight( 30 )
	        self.Radius:SetWide( self:GetWide() )
	        self.Radius.Paint = function()
	        	local w,h = self.Radius:GetWide(),self.Radius:GetTall()
	            local Poly = {
		            { x = ( 20 / resolutionScale ),   y = h }, --100/200
		            { x = 0,					      y = 0 }, --100/100
		            { x = w-( 20 / resolutionScale ), y = 0 }, --200/100
		            { x = w,                          y = h }, --200/200
		        }
	        	
	        	surface.SetDrawColor( Color( 0 , 97 , 155 , 220 ) )
	        	draw.NoTexture()
	        	surface.DrawPoly(Poly)
	        end

	        self.RName = self.Radius:Add( "DLabel" )
	        self.RName:SetFont( "SZFont" )
	        self.RName:SetTextColor( Color( 255, 255, 255, 255 ) )
	        self.RName:Dock( LEFT )
	        self.RName:SetContentAlignment( 5 )
	        self.RName:DockMargin( 25 , 0 , 0 , 0 )
	        self.RName:SetText( "Radius:" )

	        self.RSlider = self.Radius:Add( "DNumSlider" )
	        self.RSlider:Dock( RIGHT)
	        self.RSlider:SetContentAlignment( 5 )
	        self.RSlider:DockMargin( 0 , 0 , 90 , 0 )
	        self.RSlider:SetSize( 350, 20 )
	        self.RSlider:SetMin( 0 )
	        self.RSlider:SetMax( 1000 )
	        self.RSlider:SetDecimals( 0 )
	        self.RSlider.OnValueChanged = function( _ , int )
	        	int = int > 1000 and 1000 or int 
	        	int = int < 0 and 0 or int
	        	LastSafeZoneRadius = math.Round( int )
	        end


	        self.RSet = self.Radius:Add( "DButton" )
	        self.RSet:Dock( LEFT )
	        self.RSet:SetContentAlignment( 5 )
	        self.RSet:DockMargin( 205 , 0 , 0 , 0 )
	        self.RSet:SetTextColor( Color( 255 , 255 , 255 ) )
	        self.RSet:SetText( "Set" )
	        self.RSet:SetWide( 80 )

	        self.RSet.Paint = function()
	        	local w,h = self.RSet:GetWide(),self.RSet:GetTall()
	        	draw.NoTexture()
	        	surface.SetDrawColor( Color( 100 , 175 , 175 , 225 ) )
	        	surface.DrawRect( 3 , 3 , w-6 , h-6 )
	    	end

	    	self.RSet.DoClick = function()
	    		net.Start( "SafeZoneSetRadius" )
	    		net.WriteString( tostring( LastSafeZoneRadius ) )
	    		net.SendToServer()
	    		chat.AddText( Color( 255 , 255 , 255 ) , ChatTag .. " radius set to "..LastSafeZoneRadius )
	    	end

	        self.Players = self:Add( "Panel" )
	        self.Players:Dock( TOP )
	        self.Players:DockMargin( 0 , 10 , 0 , 0 )
	        self.Players:SetHeight( 30 )
	        self.Players:SetWide( self:GetWide() )
	        self.Players.Paint = function()
	        	local w,h = self.Players:GetWide(),self.Players:GetTall()
	            local Poly = {
		            { x = ( 20 / resolutionScale ),   y = h }, --100/200
		            { x = 0,					      y = 0 }, --100/100
		            { x = w-( 20 / resolutionScale ), y = 0 }, --200/100
		            { x = w,                          y = h }, --200/200
		        }
	        	
	        	surface.SetDrawColor( Color( 0 , 97 , 155 , 220 ) )
	        	draw.NoTexture()
	        	surface.DrawPoly(Poly)
	        end

	        self.PName = self.Players:Add( "DLabel" )
	        self.PName:SetFont( "SZFont" )
	        self.PName:SetTextColor( Color( 255, 255, 255, 255 ) )
	        self.PName:Dock( LEFT )
	        self.PName:SetContentAlignment( 6 )
	        self.PName:DockMargin( 30 , 0 , 0 , 0 )
	        self.PName:SetText( "Players:" )

	        self.PList = self.Players:Add( "DComboBox" )
	        self.PList:Dock( LEFT )
	        self.PList:DockMargin( 10 , 0 , 0 , 0 )
	        self.PList:SetValue( "-------------" )
	        self.PList:SetWide( 100 )
	        self.PList:SetTextColor( Color( 255 , 255 , 255 ) )
	        
	        for k,v in ipairs(player.GetAll()) do
	        	self.PList:AddChoice( v:EntIndex().." -- "..v:Nick():gsub("<(.+)=(.+)>","") )
	        end
	        
	        self.PList.Paint = function()
	        	local w,h = self.PList:GetWide(),self.PList:GetTall()
	        	draw.NoTexture()
	        	surface.SetDrawColor( Color( 100 , 175 , 175 , 225 ) )
	        	surface.DrawRect( 3 , 3 , w-6 , h-6 )
	        end

	        self.PAdd = self.Players:Add( "DButton" )
	        self.PAdd:Dock( LEFT )
	        self.PAdd:DockMargin( 5 , 0 , 0 , 0 )
	        self.PAdd:SetTextColor( Color( 255 , 255 , 255 ) )
	        self.PAdd:SetText( "Allow" )
	        self.PAdd:SetWide( 80 )
	        
	        self.PAdd.Paint = function()
	        	local w,h = self.PAdd:GetWide(),self.PAdd:GetTall()
	        	draw.NoTexture()
	        	surface.SetDrawColor( Color( 100 , 175 , 175 , 225 ) )
	        	surface.DrawRect( 3 , 3 , w-6 , h-6 )
	    	end
	    	
	    	self.PAdd.DoClick = function()
	    		local str,_ = self.PList:GetSelected() 
	    		local plindex = string.Split( str , " -- "  )[1]
	    		net.Start( "SafeZoneAllowPlayer" )
	    		net.WriteString( plindex )
	    		net.SendToServer()
	    		chat.AddText( Color( 255 , 255 , 255 ) , ChatTag.." "..Entity(plindex):Nick():gsub("<(.+)=(.+)>","").." was added to trusted players" )

	    	end

	    	self.PRemove = self.Players:Add( "DButton" )
	        self.PRemove:Dock( LEFT )
	        self.PRemove:DockMargin( 5 , 0 , 0 , 0 )
	        self.PRemove:SetTextColor( Color( 255 , 255 , 255 ) )
	        self.PRemove:SetText( "Disallow" )
	        self.PRemove:SetWide( 80 )
	        
	        self.PRemove.Paint = function()
	        	local w,h = self.PRemove:GetWide(),self.PRemove:GetTall()
	        	draw.NoTexture()
	        	surface.SetDrawColor( Color( 100 , 175 , 175 , 225 ) )
	        	surface.DrawRect( 3 , 3 , w-6 , h-6 )
	    	end
	    	
	    	self.PRemove.DoClick = function()
	    		local str,_ = self.PList:GetSelected() 
	    		local plindex = string.Split( str , " -- "  )[1]
	    		net.Start( "SafeZoneDisallowPlayer" )
	    		net.WriteString( plindex )
	    		net.SendToServer()
	    		chat.AddText( Color( 255 , 255 , 255 ) , ChatTag.." "..Entity(plindex):Nick():gsub("<(.+)=(.+)>","").." was removed from trusted players" )

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

	function SAFE_ZONE_SPHERE:Draw()
		self:DrawModel()
	end

	net.Receive( "SafeZonePanel" , function()

		local SafeZonePanel = vgui.CreateFromTable( SAFE_ZONE_PANEL )
		SafeZonePanel:SetSize( 400 , 200 )
		SafeZonePanel:SetPos( scrW/2-SafeZonePanel:GetWide()/2 , scrH/2-SafeZonePanel:GetTall()/2 )
		SafeZonePanel:MakePopup()

		timer.Simple( 5 , function() SafeZonePanel:Remove() end )
	
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

 	function SafeZonePickup( ply , ent )
		if ent:GetClass() == "safe_zone" then
			return false
		end
	end

	function SAFE_ZONE_BASE:SpawnFunction( ply , tr )
	   	
		if !tr.Hit or ply.SafeZone then return end 
		
		local SpawnPos = tr.HitPos --+ tr.HitNormal  

		for k,v in pairs(ents.FindInSphere(	SpawnPos,1000)) do
			if v:IsPlayer() and v != ply then
				return
			end
		end

		
		local ent = ents.Create( "safe_zone" )
		ent:SetPos( SpawnPos ) 
		ent:SetModel("models/props_combine/CombineThumper002.mdl")
		ent:SetModelScale(0.4)
		ent:Spawn()
		ent:Activate() 

		ent.PlayersAllowed = {}
		ent.PlayersAllowed[ply:EntIndex()] = ply
		ent.Radius = 200
		ply.LastSafeZone = ent
		ply.SafeZone = true

		local sphere = ents.Create( "prop_physics" )
		sphere:SetModel("models/XQM/Rails/gumball_1.mdl")
		sphere:SetMaterial("models/props_combine/portalball001_sheet")
		sphere:SetPos(ent:GetPos())
		sphere:SetParent( ent )
		sphere:SetColor( Color(150,255,150,255) )
		sphere:SetAngles(Angle(90,0,0))
		sphere:Spawn()
		sphere:Activate()
		sphere:DrawShadow(false)
		sphere.Protected = true

		local sphere2 = ents.Create( "prop_physics" )
		sphere2:SetModel("models/XQM/Rails/gumball_1.mdl")
		sphere2:SetMaterial("models/props_combine/portalball001_sheet")
		sphere2:SetPos(ent:GetPos())
		sphere2:SetParent( ent )
		sphere2:SetColor( Color(150,255,150,255) )
		sphere2:SetAngles(Angle(-90,0,0))
		sphere2:Spawn()
		sphere2:Activate()
		sphere2:DrawShadow(false)
		sphere2.Protected = true
		
		timer.Create("SafeZoneModelScale"..ent:EntIndex(),1,0,function() 
			sphere:SetModelScale(ent.Radius*2*sphere:GetModelScale()/sphere:BoundingRadius(),1)
			sphere2:SetModelScale(ent.Radius*2*sphere2:GetModelScale()/sphere2:BoundingRadius(),1)
		end)

		return ent 
		
	end

	function SAFE_ZONE_BASE:Initialize()
	
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		
		self:SetUnFreezable( true )

	end

	
	function SAFE_ZONE_BASE:Use( activator , caller )
		if self:IsAllowed( caller ) or caller:IsAdmin() then
			caller.LastSafeZone = self
			net.Start("SafeZonePanel")
			net.Send(caller)
		end

	end
	 
	function SAFE_ZONE_BASE:Think() --stays like this for now
		
		for k,v in pairs(ents.FindInSphere(self:GetPos(),self.Radius)) do

			if v:CPPIGetOwner() then
				
				if v:GetClass() != "safe_zone" and !self:IsAllowed( v:CPPIGetOwner() ) and !v:CPPIGetOwner():IsAdmin() then
					v:Dissolve()
				end
			
			elseif v:IsPlayer() and !self:IsAllowed( v ) and !v:IsAdmin() then 

					local dif = v:GetPos() - self:GetPos()
					
					v:SetPos( self:GetPos() + dif/self.Radius * (self.Radius +  v:GetPos():Distance(self:GetPos()))  )

			end
		
		end

		self:NextThink( CurTime() + 0.1 )
		
		return true

	end

	function SAFE_ZONE_BASE:OnRemove()
		if self:CPPIGetOwner() then
			self:CPPIGetOwner().SafeZone = false
		end
		
		timer.Destroy( "SafeZoneModelScale"..self:EntIndex() )
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
	
	hook.Add( "PhysgunPickup" , "SafeZoneAntiPickup" , SafeZonePickup )

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
		local int = net.ReadString()

		if IsValid( ply ) and ply:IsPlayer() and ply.LastSafeZone and ply.LastSafeZone:GetClass() == "safe_zone" and ply.LastSafeZone:IsAllowed( ply ) then
			ply.LastSafeZone.Radius = tonumber( int ) 
		end

	end )


end

scripted_ents.Register( SAFE_ZONE_BASE , "safe_zone" )
