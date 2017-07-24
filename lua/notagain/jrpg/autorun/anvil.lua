AddCSLuaFile()

local ENT = {}

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.ClassName = "anvil"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Category = "JRPG"


if CLIENT then
	function ENT:Initialize()
		self.WeaponModel = ClientsideModel( "models/props_junk/cardboard_box004a_gib01.mdl" )
		self.WeaponModel:SetRenderMode(RENDERMODE_TRANSCOLOR)
	end
	
	function ENT:Think()
		if IsValid( self.WeaponModel ) then
			self.WeaponModel:SetPos( self:GetPos() + self:GetUp() * 40 )
			self.WeaponModel:SetModel( self:GetNWString( "model", "models/props_junk/cardboard_box004a_gib01.mdl" ) )
			
			local ang = self.WeaponModel:GetAngles()
			ang:RotateAroundAxis( ang:Up(), 5 )
			self.WeaponModel:SetAngles( ang )
			
			local size = math.cos( CurTime() * 4 ) * 1 + 1.2 + 0.5
			local mat = Matrix()
			mat:Scale( Vector( size, size, size ) )
			self.WeaponModel:EnableMatrix( "RenderMultiply", mat )
			
			if self:GetNWInt( "status", 0 ) == 0 then
				self.WeaponModel:SetColor( Color( 255, 255, 255, 0 ) )
			else
				self.WeaponModel:SetColor( Color( 255, 255, 255, 255 ) )
			end
		end
	end

	function ENT:OnRemove()
		self.WeaponModel:Remove()
	end
	
	function ENT:Draw()
		self:DrawModel()
	end
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/props_wasteland/kitchen_counter001b.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( MOVETYPE_VPHYSICS )
		self:PhysWake()
		
		self.Status = 0
		self.Time = 0
	end

	function ENT:Touch( ent )
		if ent:IsWeapon() and ent != nil and self.Status == 0 then
			if ent.wepstats != nil then
				return
			end

			self.Time = CurTime() + 11
			self:SetWeapon( ent )
			
			ent:Remove()
			ent = nil
		end
	end
	
	function ENT:Think()
		if self.Status == 1 then
			if self.Time <= CurTime() then
				self:ProcessWeapon()
				self:SetStatus( 0 )
			end
		end
	end
	
	function ENT:SetStatus( status )
		self.Status = status
		self:SetNWInt( "status", status )
	end
	
	function ENT:SetWeapon( ent )
		self:SetStatus( 1 )
		self:EmitSound( "dond/information.mp3" )
		self:EmitSound( "dond/gooddeal.mp3" )
	
		local class = ent:GetClass()
		local model = ent:GetModel()

		self:SetNWString( "class", class )
		self:SetNWString( "model", model )
	end
	
	function ENT:ProcessWeapon()
		if ( math.random() < 0.3 ) then
			local e = ents.Create( 'env_explosion' )
			e:SetPos( self:GetPos() )
			e:SetKeyValue( 'iMagnitude', '150' )
			e:Spawn()
			e:Fire( 'Explode', 0, 0 )
		else
			local ent = ents.Create( self:GetNWString( "class" ) )
			ent:SetPos( self:GetPos() + self:GetUp() * 40 )
			wepstats.AddToWeapon( ent )
			ent:Spawn()
			
			self:EmitSound( "dond/case_good.mp3" )
		end
	end
end

scripted_ents.Register(ENT, ENT.ClassName, true)
