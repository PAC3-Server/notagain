AddCSLuaFile()

local ENT = {}

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.ClassName = "chest"
ENT.Category = "JRPG"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.Spread = 20

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/Items/ammocrate_smg1.mdl" )
		self:SetMaterial( "models/props_wasteland/wood_fence01a" )

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_VPHYSICS )

		self:SetUseType( SIMPLE_USE )

		self.ChestItems = {}

		for _, info in ipairs(weapons.GetList()) do
			if info.Spawnable then
				table.insert(self.ChestItems, info.ClassName)
			end
		end
	end

	function ENT:Use()
		if not self.opened then
			if ( math.random() < 0.10 ) then
				local e = ents.Create( 'env_explosion' )
				e:SetPos( self:GetPos() )
				e:SetKeyValue( 'iMagnitude', '100' )
				e:Spawn()
				e:Fire( 'Explode', 0, 0 )
			else
				for i = 1, math.random( 6 ) do
					timer.Simple(math.random(), function()
						if not self:IsValid() then return end
						self:SpawnChestItem( table.Random( self.ChestItems ) )
					end)
				end
			end

			self:EmitSound( "gasmaskon.wav" )
			self:SetSequence(self:LookupSequence("Open"))
			self:SetPlaybackRate(1)

			SafeRemoveEntityDelayed(self, 2.5)

			self.opened = true
		end
	end

	function ENT:SpawnChestItem( ent )
		local ent = ents.Create( ent )
		ent:SetPos( self:GetPos() )
		ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
		ent:Spawn()
		ent:SetOwner(self)
		wepstats.AddToWeapon( ent )

		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetVelocity( (ent:GetUp() * math.Rand(50,300)) + (ent:GetForward() * 100) + ent:GetRight() * ( math.random( -self.Spread, self.Spread ) ) + ent:GetForward() * ( math.random( -self.Spread, self.Spread ) ) )
		end
	end

end

scripted_ents.Register(ENT, ENT.ClassName, true)
