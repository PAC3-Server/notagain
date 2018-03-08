local FISH = {}

FISH.ClassName = "heavy"
FISH.Model = "models/props_junk/popcan01a.mdl"
FISH.MaxSpawned = 30
FISH.Rareness = 0

function FISH:SetupDataTables()
	self:DTVar("Entity", 0, "Heavy")
end

if SERVER then
	function FISH:PostInit()
		timer.Simple(0.1, function()
			local ent = ents.Create("prop_ragdoll")
				ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
				ent:SetModel("models/player/heavy.mdl")
				ent:SetPos(self:GetPos())
				ent:Spawn()
			self.dt.Heavy = ent
		end)
		
		self:SetPlayer(Entity(1))
		
		self:SetParent(ent)
	end
		
	function FISH:SetPlayer(player)
	
		local heavy = self.dt.Heavy
		
		local number = math.random(17)
		if number < 10 then number = "0" .. number end
		self:PlaySound("vo/heavy_sandwichtaunt"..number..".wav")
		
		self.target = player
		heavy.owner = player
		
		if heavy.CPPISetOwner then 
			heavy:CPPISetOwner(player) 
		end
	end
	
	function FISH:PlaySound(path)
		if not self.busysound then
			self:EmitSound(path, 100, math.random(90,110))
			self.busysound = true
		end
		timer.Simple(SoundDuration(path), function()
			if not IsValid(self) then return end
			self.busysound = false
		end)
	end	
	
	function FISH:PreMove()
		return false
	end

	function FISH:PreMove()
		local heavy = self.dt.Heavy
		
		print(heavy)
		
		if not IsValid(heavy.owner) then
			for key, ply in pairs(player.GetAll()) do
				if ply.InFTS and ply:GetPos():Distance(self:GetPos()) < 1000 then
					self:SetPlayer(ply)
				end
			end
		else
			local enemy = self.Enemy or NULL
						
			if enemy:IsValid() then
				self.target = enemy
				local handpos = heavy:GetBonePosition(heavy:LookupBone("bip_hand_l"))
				local distance = enemy:GetPos():Distance(handpos)
				
				if distance < 60 then
					local data = DamageInfo()
					data:SetAttacker(heavy.owner)
					data:SetDamageType(DMG_BULLET)
					data:SetDamage(10)
					self.target:OnTakeDamage(data)
				end					
			end
		end
		
		if not IsValid(self.target) then 
			self.target = heavy.owner 
		end
	
		local target = self.target
		
		if IsValid(target) then			
			for i=0, heavy:GetFlexNum() do
				heavy:SetFlexWeight(i, math.random()*0.4)
			end
			
			if math.random() > 0.999 then
				self:PlaySound("vo/heavy_positivevocalization0"..math.random(5)..".wav")
			end
		
			local head = heavy:GetPhysicsObjectNum(14)
			local lefthand = heavy:GetPhysicsObjectNum(11)
			local righthand = heavy:GetPhysicsObjectNum(13)
			local rightfoot = heavy:GetPhysicsObjectNum(15)
			local leftfoot = heavy:GetPhysicsObjectNum(5)
			local pelvis = heavy:GetPhysicsObjectNum(0)
			
			local velocity = (target:IsPlayer() and target:GetShootPos() or target:GetPos()) - heavy:GetPos()
			
			if target:IsPlayer() and target:GetShootPos():Distance(heavy:GetPos()) < 200 then
				velocity = Vector(0)
				
				constraint.RemoveAll(heavy)
			end
			
			if target:GetClass() == "fishing_seagull" then velocity = velocity:Normalize() * 1000 end
			
			local gravity = Vector(0,0,-20)
			
			head:AddVelocity(velocity)
			lefthand:AddVelocity(velocity)
			righthand:AddVelocity(velocity)
			
			head:AddAngleVelocity(Vector(-100,0,0))
			-- leftfoot:AddVelocity(gravity)
			
			local phys = heavy:GetPhysicsObject()
			phys:EnableGravity(false)
			
			for i = 0,15 do				
				local phys = heavy:GetPhysicsObjectNum(i)
				phys:EnableGravity(false)
				if self.target:GetClass() ~= "fishing_seagull" then 
					phys:AddVelocity(phys:GetVelocity()*-0.1) 
				end
			end
			
			--rightfoot:AddVelocity(gravity)
			--leftfoot:AddVelocity(gravity)
		end		
		return false
	end
	
	function FISH:OnRemove()
		if IsValid(self.dt.Heavy) then self.dt.Heavy:Remove() end
	end

else
	function FISH:PostInit()
		self.emitter = ParticleEmitter(self:GetPos())
	end

	local bones = 
	{
		"bip_foot_r",
		"bip_foot_l",
	}
	
	function FISH:OnThink()
		if self.dt.dead then return end
		
		local heavy = self.dt.Heavy
		
		for key, bone in pairs(bones) do
			local position = heavy:GetBonePosition(heavy:LookupBone(bone))
			
			local particle = self.emitter:Add( "effects/yellowflare", position )
			particle:SetVelocity( VectorRand() * 10 )
			particle:SetDieTime( 5 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 4 )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -360, 360 ) )
			particle:SetRollDelta( math.Rand( -30, 30 ) )
			particle:SetBounce( 1.0 )
		end
	end
end

fishing.RegisterFish(FISH)