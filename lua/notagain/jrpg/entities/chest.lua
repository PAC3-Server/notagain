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
		self.CModel = {}
	
		self.CModel[1] = ClientsideModel( "models/hunter/plates/plate1x2.mdl" )
		self.CModel[2] = ClientsideModel( "models/hunter/plates/plate1x1.mdl" )
		self.CModel[3] = ClientsideModel( "models/hunter/plates/plate1x1.mdl" )
		self.CModel[4] = ClientsideModel( "models/hunter/plates/plate1x2.mdl" )
		self.CModel[5] = ClientsideModel( "models/hunter/plates/plate1x2.mdl" )
		self.CModel[6] = ClientsideModel( "models/hunter/tubes/tube2x2x4c.mdl" )
		self.CModel[7] = ClientsideModel( "models/hunter/tubes/circle2x2c.mdl" )
		self.CModel[8] = ClientsideModel( "models/hunter/tubes/circle2x2c.mdl" )
		self.CModel[9] = ClientsideModel( "models/props_c17/pulleywheels_small01.mdl" )
		
		self.CModel[10] = ClientsideModel( "models/hunter/blocks/cube025x075x025.mdl" )
		self.CModel[10]:SetRenderMode(RENDERMODE_TRANSCOLOR)
		self.CModel[10]:SetColor( Color( 0, 0, 0, 0 ) )
		
		self.CModel[6]:SetParent( self.CModel[10] )
		self.CModel[7]:SetParent( self.CModel[10] )
		self.CModel[8]:SetParent( self.CModel[10] )
		
		for i = 1, #self.CModel do
			if ( i == 9 ) then break end
			self.CModel[i]:SetMaterial( "models/props_wasteland/wood_fence01a" )
		end
	end
	
	function ENT:Think()
		self.angle = Lerp( 0.05, self.angle, ( self:GetNWInt( "status" ) == 1 ) and 0 or -90 )
	
		for i = 1, #self.CModel do
			if ( !IsValid( self.CModel[i] ) ) then
				return
			end
		end
	
		// Model 1
		local pos = self:GetPos() + self:GetForward() * 23.5 + self:GetUp() * 4
		self.CModel[1]:SetPos( pos )
		
		local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		self.CModel[1]:SetAngles( ang )
		
		// Model 2
		pos = self:GetPos() + self:GetForward() * -20 + self:GetUp() * 23.5
		self.CModel[2]:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Right(), 90 )
		self.CModel[2]:SetAngles( ang )
		
		// Model 3
		pos = self:GetPos() + self:GetForward() * 68 + self:GetUp() * 23.5
		self.CModel[3]:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Right(), 90 )
		self.CModel[3]:SetAngles( ang )
		
		// Model 4
		pos = self:GetPos() + self:GetForward() * 23.5 + self:GetUp() * 23.5 + self:GetRight() * 21
		self.CModel[4]:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Up(), 90 )
		self.CModel[4]:SetAngles( ang )
		
		// Model 5
		pos = self:GetPos() + self:GetForward() * 23.5 + self:GetUp() * 23.5 + self:GetRight() * -20
		self.CModel[5]:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Up(), 90 )
		self.CModel[5]:SetAngles( ang )
		
		// Model 10
		local axis = self.CModel[10]
		
		pos = self:GetPos() + self:GetForward() * 23.5 + self:GetUp() * 45 + self:GetRight() * 20
		axis:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang:RotateAroundAxis( ang:Right(), self.angle )
		
		axis:SetAngles( ang )
		
		// Model 6
		pos = axis:GetPos() + axis:GetUp() * 20
		self.CModel[6]:SetPos( pos )
		
		ang = axis:GetAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		self.CModel[6]:SetAngles( ang )
		
		local mat = Matrix()
		mat:Scale( Vector( 0.5, 0.5, 0.5 ) )
		self.CModel[6]:EnableMatrix( "RenderMultiply", mat )
		
		// Model 7
		pos = axis:GetPos() + axis:GetUp() * 20 + axis:GetRight() * 46
		self.CModel[7]:SetPos( pos )
		
		ang = axis:GetAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		self.CModel[7]:SetAngles( ang )
		
		local mat = Matrix()
		mat:Scale( Vector( 0.5, 0.5, 0.5 ) )
		self.CModel[7]:EnableMatrix( "RenderMultiply", mat )
		
		// Model 8
		pos = axis:GetPos() + axis:GetUp() * 20 + axis:GetRight() * -46
		self.CModel[8]:SetPos( pos )
		
		ang = axis:GetAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		self.CModel[8]:SetAngles( ang )
		
		local mat = Matrix()
		mat:Scale( Vector( 0.5, 0.5, 0.5 ) )
		self.CModel[8]:EnableMatrix( "RenderMultiply", mat )
		
		// Model 9
		pos = self:GetPos() + self:GetForward() * 23.5 + self:GetRight() * -25 + self:GetUp() * 45
		self.CModel[9]:SetPos( pos )
		
		ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang:RotateAroundAxis( ang:Forward(), 90 )
		self.CModel[9]:SetAngles( ang )
		
		local mat = Matrix()
		mat:Scale( Vector( 0.75, 0.75, 0.75 ) )
		self.CModel[9]:EnableMatrix( "RenderMultiply", mat )
	end

	function ENT:Draw()
		self:DrawModel()
	end
	
	function ENT:OnRemove()
		for i = 1, #self.CModel do
			self.CModel[i]:Remove()
		end
	end
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/props_phx/construct/metal_wire1x1x2b.mdl" )
		self:SetMaterial( "models/props_wasteland/wood_fence01a" )

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_VPHYSICS )
		
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
			else
				for i = 1, math.random( 4 ) do
					self:SpawnChestItem( table.Random( ChestItems ) )
				end
			end
			
			self:SetNWInt( "status", 1 )
			self:EmitSound( "gasmaskon.wav" )
		
			timer.Simple( 1.5, function()
				self:Remove()
			end )
		end
	end
	
	function ENT:SpawnChestItem( ent )
		local ent = ents.Create( ent )
		ent:SetPos( self:GetPos() + self:GetForward() * 20 )
		ent:Spawn()
		wepstats.AddToWeapon( ent )
		
		local phys = ent:GetPhysicsObject()
		phys:SetVelocity( ent:GetUp() * 400 + ent:GetRight() * ( math.random( -self.Spread, self.Spread ) ) + ent:GetForward() * ( math.random( -self.Spread, self.Spread ) ) )
	end
	
	EMF.AddEnt( ENT.ClassName )
end

scripted_ents.Register(ENT, ENT.ClassName, true)