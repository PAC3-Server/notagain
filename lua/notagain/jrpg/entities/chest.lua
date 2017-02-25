AddCSLuaFile()

local ENT = {}
local ChestItems = {
	"weapon_357",
	"weapon_ar2",
	"weapon_crossbow",
	"weapon_frag",
}

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.ClassName = "chest"

ENT.Spread = 50

if CLIENT then
	function ENT:Initialize()
		self.angle = -90
		self.Side = {}
	
		self.Side[1] = ClientsideModel( "models/hunter/plates/plate1x2.mdl" )
		self.Side[2] = ClientsideModel( "models/hunter/plates/plate1x1.mdl" )
		self.Side[3] = ClientsideModel( "models/hunter/plates/plate1x1.mdl" )
		self.Side[4] = ClientsideModel( "models/hunter/plates/plate1x2.mdl" )
		self.Side[5] = ClientsideModel( "models/hunter/plates/plate1x2.mdl" )
		self.Side[6] = ClientsideModel( "models/hunter/tubes/tube2x2x4c.mdl" )
		self.Side[7] = ClientsideModel( "models/hunter/tubes/circle2x2c.mdl" )
		self.Side[8] = ClientsideModel( "models/hunter/tubes/circle2x2c.mdl" )
		self.Side[9] = ClientsideModel( "models/props_c17/pulleywheels_small01.mdl" )
		
		self.Axis = ClientsideModel( "models/hunter/blocks/cube025x075x025.mdl" )
		self.Axis:SetRenderMode(RENDERMODE_TRANSCOLOR)
		
		self.Side[6]:SetParent( self.Axis )
		self.Side[7]:SetParent( self.Axis )
		self.Side[8]:SetParent( self.Axis )
		
		for i = 1, #self.Side do
			if ( i == 9 ) then break end
			self.Side[i]:SetMaterial( "models/props_wasteland/wood_fence01a" )
		end
	end
	
	function ENT:Think()
		self.angle = Lerp( 0.05, self.angle, ( self:GetNWInt( "status" ) == 1 ) and 0 or -90 )
	
		// Side 1
		local pos = self:GetPos() + self:GetForward() * 23.5 + self:GetUp() * 4
		self.Side[1]:SetPos( pos )
		
		local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		self.Side[1]:SetAngles( ang )
		
		// Side 2
		pos = self:GetPos() + self:GetForward() * -20 + self:GetUp() * 23.5
		self.Side[2]:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Right(), 90 )
		self.Side[2]:SetAngles( ang )
		
		// Side 3
		pos = self:GetPos() + self:GetForward() * 68 + self:GetUp() * 23.5
		self.Side[3]:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Right(), 90 )
		self.Side[3]:SetAngles( ang )
		
		// Side 4
		pos = self:GetPos() + self:GetForward() * 23.5 + self:GetUp() * 23.5 + self:GetRight() * 21
		self.Side[4]:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Up(), 90 )
		self.Side[4]:SetAngles( ang )
		
		// Side 5
		pos = self:GetPos() + self:GetForward() * 23.5 + self:GetUp() * 23.5 + self:GetRight() * -20
		self.Side[5]:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Up(), 90 )
		self.Side[5]:SetAngles( ang )
		
		// Side 6 Axis
		pos = self:GetPos() + self:GetForward() * 23.5 + self:GetUp() * 45 + self:GetRight() * 20
		self.Axis:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang:RotateAroundAxis( ang:Right(), self.angle )
		
		self.Axis:SetAngles( ang )
		self.Axis:SetColor( Color( 0, 0, 0, 0 ) )
		
		// Side 6
		pos = self.Axis:GetPos() + self.Axis:GetUp() * 20
		self.Side[6]:SetPos( pos )
		
		ang = self.Axis:GetAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		self.Side[6]:SetAngles( ang )
		
		local mat = Matrix()
		mat:Scale( Vector( 0.5, 0.5, 0.5 ) )
		self.Side[6]:EnableMatrix( "RenderMultiply", mat )
		
		// Side 7
		pos = self.Axis:GetPos() + self.Axis:GetUp() * 20 + self.Axis:GetRight() * 46
		self.Side[7]:SetPos( pos )
		
		ang = self.Axis:GetAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		self.Side[7]:SetAngles( ang )
		
		local mat = Matrix()
		mat:Scale( Vector( 0.5, 0.5, 0.5 ) )
		self.Side[7]:EnableMatrix( "RenderMultiply", mat )
		
		// Side 8
		pos = self.Axis:GetPos() + self.Axis:GetUp() * 20 + self.Axis:GetRight() * -46
		self.Side[8]:SetPos( pos )
		
		ang = self.Axis:GetAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		self.Side[8]:SetAngles( ang )
		
		local mat = Matrix()
		mat:Scale( Vector( 0.5, 0.5, 0.5 ) )
		self.Side[8]:EnableMatrix( "RenderMultiply", mat )
		
		// Side 9
		pos = self:GetPos() + self:GetForward() * 23.5 + self:GetRight() * -25 + self:GetUp() * 45
		self.Side[9]:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang:RotateAroundAxis( ang:Forward(), ( self:GetNWInt( "status" ) == 1 ) and CurTime() or 90 )
		self.Side[9]:SetAngles( ang )
		
		local mat = Matrix()
		mat:Scale( Vector( 0.75, 0.75, 0.75 ) )
		self.Side[9]:EnableMatrix( "RenderMultiply", mat )
	end

	function ENT:Draw()
		self:DrawModel()
		
		for i = 1, #self.Side do
			self.Side[i]:DrawModel()
		end
	end
	
	function ENT:OnRemove()
		for i = 1, #self.Side do
			self.Side[i]:Remove()
		end
		
		self.Axis:Remove()
	end

	function GenerateEffect( pos, type )
		if type == 0 then
			local pm = ParticleEmitter( pos )

			for i=1, 25 do
				 local part = pm:Add( "sprites/light_glow02_add", pos )
				 if part then
					  part:SetColor(math.random(255), math.random(255), math.random(255), math.random(255))
					  part:SetVelocity(Vector(math.random(-1,1),math.random(-1,1),math.random(0,1)):GetNormal() * math.random(100, 200))
					  part:SetDieTime(1)
					  part:SetLifeTime(0)
					  part:SetStartSize(100)
					  part:SetEndSize(0)
				 end
			end
			pm:Finish()
		elseif type == 1 then
			local pm = ParticleEmitter( pos )

			for i=1, 25 do
				 local part = pm:Add( "sprites/light_glow02_add", pos )
				 if part then
					  part:SetColor(0, 127, 31, 255)
					  part:SetVelocity(Vector(math.random(-1,1),math.random(-1,1),math.random(0,1)):GetNormal() * math.random(100, 200))
					  part:SetDieTime(1)
					  part:SetLifeTime(0)
					  part:SetStartSize(100)
					  part:SetEndSize(0)
				 end
			end
			pm:Finish()
		end
	end

	net.Receive("s2c_chesteffect", function()
		local pos = net.ReadVector()
		local type = net.ReadInt( 4 )
		
		GenerateEffect( pos, type )
	end)
end

if SERVER then
	util.AddNetworkString( "s2c_chesteffect" )

	function ENT:Initialize()
		self:SetModel( "models/props_phx/construct/metal_wire1x1x2b.mdl" )
		self:SetMaterial( "models/props_wasteland/wood_fence01a" )
		
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( MOVETYPE_VPHYSICS )
		self:PhysWake()
		self:SetUseType( SIMPLE_USE )
		
		self:SetNWInt( "status", 0 )
	end
	
	function ENT:Use()
		if self:GetNWInt( "status" ) == 0 then
			local rand = math.random( 1, 100 )
			
			if ( rand > 20 ) then
				local e = ents.Create( 'env_explosion' )
				e:SetPos( self:GetPos() )
				e:SetKeyValue( 'iMagnitude', '100' )
				e:Spawn()
				e:Fire( 'Explode', 0, 0 )
				
				net.Start( "s2c_chesteffect" )
					net.WriteVector( self:GetPos() + self:GetForward() * 20 )
					net.WriteInt( 1, 4 )
				net.Broadcast()
			else
				for i = 1, math.random( 4 ) do
					self:SpawnChestItem( table.Random( ChestItems ) )
				end
			
				net.Start( "s2c_chesteffect" )
					net.WriteVector( self:GetPos() + self:GetForward() * 20 )
					net.WriteInt( 0, 4 )
				net.Broadcast()
			end
			
			self:SetNWInt( "status", 1 )
		end
	end
	
	function ENT:SpawnChestItem( ent )
		local ent = ents.Create( ent )
		ent:SetPos( self:GetPos() + self:GetForward() * 20 )
		ent:Spawn()
		// wepstats.AddToWeapon( ents )
		
		local phys = ent:GetPhysicsObject()
		phys:SetVelocity( ent:GetUp() * 400 + ent:GetRight() * ( math.random( -self.Spread, self.Spread ) ) + ent:GetForward() * ( math.random( -self.Spread, self.Spread ) ) )
	end
	
	// EMF.AddEnt( ENT.ClassName )
end

scripted_ents.Register(ENT, ENT.ClassName, true)
