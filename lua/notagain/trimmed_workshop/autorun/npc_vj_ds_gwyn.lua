local ENT = {}
ENT.ClassName = "npc_vj_ds_gwyn"

game.AddParticles("particles/ds_artorias_fx.pcf")

local particlename = {
	"dskart_ambient",
	"dskart_ambient_heat",
	"dskart_ambient_shadows",
	"dskart_ambient_shadows_2",
	"dskart_aura",
	"dskart_aura_feet",
	"dskart_aura_feet_heat",
	"dskart_aura_feet_swirls",
	"dskart_aura_feet_xy",
	"dskart_blade_hit",
	"dskart_blade_hit_lightning",
	"dskart_blade_hit_lightning_xy",
	"dskart_blade_hit_sparks_0",
	"dskart_blade_hit_sparks_1",
	"dskart_fw_charge",
	"dskart_fw_charge_abyss",
	"dskart_fw_charge_abyss_2",
	"dskart_fw_charge_finish_splat",
	"dskart_slam",
	"dskart_slam_impact",
	"dskart_slam_impact_2",
	"dskart_slam_impact_dirt",
	"dskart_slam_impact_dirt_2",
	"dskart_slam_impact_smoke",
	"dskart_swordtrail",
	"dskart_trail",
	"dskart_charge",
	"dskart_charge_noflux",
	"dskart_postcharge",
	"dskart_death"
}
for _,v in ipairs(particlename) do PrecacheParticleSystem(v) end

ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Gwyn"
ENT.Author 			= "Mayhem"
ENT.Contact 		= "http://vrejgaming.webs.com/"
ENT.Purpose 		= "Let it eat you."
ENT.Instructions	= "Click on it to spawn it."
ENT.Category		= "Dark Souls"

if (CLIENT) then
	local Name = "Gwyn"
	local LangName = "npc_vj_ds_gwyn"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color ( 255, 80, 0, 255 ) )
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color ( 255, 80, 0, 255 ) )
end

if SERVER then

	/*-----------------------------------------------
		*** Copyright (c) 2012-2015 by Mayhem, All rights reserved. ***
		No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
		without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
	-----------------------------------------------*/
	ENT.Model = {"models/darksouls/gwyn/gwyn.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
	ENT.StartHealth = 5975
	ENT.MoveType = MOVETYPE_STEP
	ENT.HullType = HULL_LARGE
	ENT.SightDistance = 10000 -- How far it can see
	ENT.VJ_IsHugeMonster = true
	---------------------------------------------------------------------------------------------------------------------------------------------
	ENT.HasBloodDecal = false
	ENT.HasBloodParticle = false
	ENT.HasMeleeAttack = true
	ENT.MeleeAttackDamageType = DMG_SLASH
	ENT.Immune_CombineBall = true
	ENT.Immune_AcidPoisonRadiation = true
	ENT.Immune_Physics = true
	ENT.HasDeathAnimation = true
	ENT.AnimTbl_Death = {"Die"}
	ENT.DeathAnimationTime = 9
	ENT.HasDeathRagdoll = false
	ENT.HasSoundTrack = false -- Currently disabled for workshop version of VjBase
		-- ====== Sound File Paths ====== --
	-- Leave blank if you don't want any sounds to play
	ENT.SoundTbl_MeleeAttack = {
	"gwyn/c5370_damage1.ogg",
	"gwyn/c5370_damage2.ogg",
	"gwyn/c5370_damage3.ogg"
	}

	--Custom Moves
	ENT.Atk0 = false
	ENT.Atk1 = false
	ENT.Atk3 = false
	ENT.Atk4 = false
	ENT.Atk5 = false
	ENT.Atk8 = false
	ENT.Atk10 = false
	ENT.Atk11 = false
	ENT.Atk12 = false
	ENT.Atk13 = false
	ENT.Atk14 = false
	ENT.Atk15 = false
	ENT.Atk16 = false
	ENT.Atk17 = false
	ENT.Atk18 = false
	ENT.Atk19 = false
	ENT.Atk20 = false
	ENT.Atk21 = false
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnInitialize()
		self.NextMoveTime = 0
		self.NextDodgeTime = 0
		self.NextMoveAroundTime = 0
		self.NextBlockTime = 0
		self.onfire = false
		self.UsingMagic = false
	if !IsValid(self.Glow1) then

	local att = self:LookupAttachment("glow")
	if(att != 0) then
	self.Glow1 = ents.Create("light_dynamic")
	self.Glow1:SetKeyValue("_light","255 69 0 200")
	self.Glow1:SetKeyValue("brightness","5")
	self.Glow1:SetKeyValue("distance","130")
	self.Glow1:SetKeyValue("style","1")
	self.Glow1:SetPos(self:GetPos())
	self.Glow1:SetParent(self)
	self.Glow1:Spawn()
	self.Glow1:Activate()
	self.Glow1:Fire("SetParentAttachment","glow")
	self.Glow1:Fire("TurnOn","",0)
	self.Glow1:DeleteOnRemove(self)
	end

	end
	if !IsValid(self.Glow2) then

	local att = self:LookupAttachment("fire2")
	if(att != 0) then
	self.Glow2 = ents.Create("light_dynamic")
	self.Glow2:SetKeyValue("_light","255 69 0 200")
	self.Glow2:SetKeyValue("brightness","5")
	self.Glow2:SetKeyValue("distance","130")
	self.Glow2:SetKeyValue("style","1")
	self.Glow2:SetPos(self:GetPos())
	self.Glow2:SetParent(self)
	self.Glow2:Spawn()
	self.Glow2:Activate()
	self.Glow2:Fire("SetParentAttachment","fire2")
	self.Glow2:Fire("TurnOn","",0)
	self.Glow2:DeleteOnRemove(self)
	end

	end
		self:SetCollisionBounds(Vector(40, 40, 110), -Vector(40, 40, 0))
		ParticleEffectAttach("fire_medium_03",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("fire"))
		ParticleEffectAttach("fire_medium_03",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("fire1"))
		ParticleEffectAttach("fire_medium_03",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("fire2"))
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:SwordBox(vStndDmg)
	vStndDmg = vStndDmg or 1
	local attackthev = ents.FindInSphere(self:GetAttachment(1).Pos, 110)
	for _,v in pairs(attackthev) do
	if (v:IsNPC()) && (self:Disposition(v) == 1 or self:Disposition(v) == 2) && (v != self) && (v:GetClass() != self:GetClass()) or v:GetClass() == "prop_physics" or v:GetClass() == "func_breakable_surf" or table.HasValue(self.EntitiesToDestroyClass,v:GetClass()) or v.VJ_AddEntityToSNPCAttackList == true then
	 local doactualdmg = DamageInfo()
	 doactualdmg:SetDamage(vStndDmg)
	 doactualdmg:SetInflictor(self)
	 doactualdmg:SetDamageType(self.MeleeAttackDamageType)
	 //doactualdmg:SetDamagePosition(attackthev)
	 doactualdmg:SetAttacker(self)
	 v:TakeDamageInfo(doactualdmg, self)
	 v:EmitSound("gwyn/c5370_damage"..math.random(1,3).. ".ogg", 80, 80, 1)
	 //v:ViewPunch( Angle( math.random(-50, 50), math.random(-50, 50), math.random(30, -30) ) )
	elseif ((v:IsPlayer() && v:Alive())) && (self:Disposition(v) == 1 or self:Disposition(v) == 2) && (v != self) && (v:GetClass() != self:GetClass()) or v:GetClass() == "prop_physics" or v:GetClass() == "func_breakable_surf" or table.HasValue(self.EntitiesToDestroyClass,v:GetClass()) or v.VJ_AddEntityToSNPCAttackList == true then
	local doactualdmg = DamageInfo()
	 doactualdmg:SetDamage(vStndDmg)
	 doactualdmg:SetInflictor(self)
	 doactualdmg:SetDamageType(self.MeleeAttackDamageType)
	 //doactualdmg:SetDamagePosition(attackthev)
	 doactualdmg:SetAttacker(self)
	 v:TakeDamageInfo(doactualdmg, self)
	 v:EmitSound("gwyn/c5370_damage"..math.random(1,3).. ".ogg", 80, 80, 1)
	 v:ViewPunch( Angle( math.random(-50, 50), math.random(-50, 50), math.random(30, -30) ) )
	end
	end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnPriorToKilled(dmginfo,hitgroup)
		//timer.Simple(2.6,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		timer.Simple(6.7,function() if self:IsValid() then ParticleEffectAttach("dskart_death",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("origin")) end end)
		timer.Simple(6.7,function() if self:IsValid(self.DeathGlow) then

		local att = self:LookupAttachment("Glow1")
		if(att != 0) then
		self.DeathGlow = ents.Create("light_dynamic")
		self.DeathGlow:SetKeyValue("_light","255 255 255 200")
		self.DeathGlow:SetKeyValue("brightness","5")
		self.DeathGlow:SetKeyValue("distance","100")
		self.DeathGlow:SetKeyValue("style","1")
		self.DeathGlow:SetPos(self:GetPos())
		self.DeathGlow:SetParent(self)
		self.DeathGlow:Spawn()
		self.DeathGlow:Activate()
		self.DeathGlow:Fire("SetParentAttachment","Glow1")
		self.DeathGlow:Fire("TurnOn","",0)
		self.DeathGlow:DeleteOnRemove(self)
		end

		end
	end)
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnThink()
		self:RemoveAllDecals()
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:MultipleMeleeAttacks()
		local EnemyDistance = self:VJ_GetNearestPointToEntityDistance(self:GetEnemy(),self:GetPos():Distance(self:GetEnemy():GetPos()))
		if EnemyDistance > 0 && EnemyDistance < 100 then
			local randattack_close = math.random(1,13)
			self.MeleeAttackDistance = 100
			if randattack_close == 1 then
				self.AnimTbl_MeleeAttack = {"Attack0"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 0.65
				self.NextAnyAttackTime_Melee = 1.2 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk0 = true self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 2 then
				self.AnimTbl_MeleeAttack = {"Attack1"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 0.67
				self.NextAnyAttackTime_Melee = 1.5 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = true self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 3 then
				self.AnimTbl_MeleeAttack = {"Attack3"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 0.95
				self.NextAnyAttackTime_Melee = 1.3 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = true self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 4 then
				self.AnimTbl_MeleeAttack = {"Attack4"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 0.85
				self.NextAnyAttackTime_Melee = 1.6 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = true self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 5 then
				self.AnimTbl_MeleeAttack = {"Attack5"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 0.9
				self.NextAnyAttackTime_Melee = 1.5 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = true self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 6 then
				self.AnimTbl_MeleeAttack = {"Attack11"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.15
				self.NextAnyAttackTime_Melee = 1.6 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = true self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 7 then
				self.AnimTbl_MeleeAttack = {"Attack12"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.15
				self.NextAnyAttackTime_Melee = 1.3 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = true self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 8 then
				self.AnimTbl_MeleeAttack = {"Attack13"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 0.8
				self.NextAnyAttackTime_Melee = 1.7 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = true self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 9 then
				self.AnimTbl_MeleeAttack = {"Attack14"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.3
				self.NextAnyAttackTime_Melee = 1.4 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = true self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 10 then
				self.AnimTbl_MeleeAttack = {"Attack15"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 0.8
				self.NextAnyAttackTime_Melee = 1.1 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = true self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 11 then
				self.AnimTbl_MeleeAttack = {"Attack16"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 0.92
				self.NextAnyAttackTime_Melee = 1.7 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = true self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 12 then
				self.AnimTbl_MeleeAttack = {"Attack20"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 0.9
				self.NextAnyAttackTime_Melee = 1.8 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = true self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_close == 13 then
				self.AnimTbl_MeleeAttack = {"Attack21"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1
				self.NextAnyAttackTime_Melee = 1.8 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(25,50)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = true self.Atk21 = false

			end
		end
		if EnemyDistance > 100 && EnemyDistance < 300 then
				self.MeleeAttackDistance = 300
				local randattack_midrange = math.random(1,3)
			if randattack_midrange == 1 then
				self.AnimTbl_MeleeAttack = {"Attack8"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false -- Should it shake the world when it misses during melee attack?
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.05
				self.NextAnyAttackTime_Melee = 1.3 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(35,60)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = true self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_midrange == 2 then
				self.AnimTbl_MeleeAttack = {"Attack10"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = true
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1
				self.NextAnyAttackTime_Melee = 1.3 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(35,60)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = true self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = false self.Atk20 = false self.Atk21 = false

			elseif randattack_midrange == 3 then
				self.AnimTbl_MeleeAttack = {"Attack18"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = true
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.1
				self.NextAnyAttackTime_Melee = 1.6 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(35,60)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = true self.Atk19 = false self.Atk20 = false self.Atk21 = false

			end
		end
		if EnemyDistance > 400 && EnemyDistance < 600 then
			self.MeleeAttackDistance = 600
			local randattack_far = math.random(1,1)
			if randattack_far == 1 then
				self.AnimTbl_MeleeAttack = {"Attack19"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPCself.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = true
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.3
				self.NextAnyAttackTime_Melee = 1.8 -- How much time until it can use a attack again? | Counted in Seconds
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = math.random(45,60)
				self.MeleeAttackDamageType = DMG_SLASH
				self.SoundTbl_MeleeAttackMiss = {}
				self.Atk0 = false self.Atk1 = false self.Atk3 = false self.Atk4 = false self.Atk5 = false self.Atk8 = false self.Atk10 = false self.Atk11 = false self.Atk12 = false self.Atk13 = false self.Atk14 = false self.Atk15 = false self.Atk16 = false self.Atk17 = false self.Atk18 = false self.Atk19 = true self.Atk20 = false self.Atk21 = false
			end
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CanDodge(dodgetype)
		if dodgetype == "normal" then
			if self.UsingMagic == false && self.MeleeAttacking == false && self.onfire == false && self.Flinching == false && self:GetEnemy():IsNPC() && ((self:GetEnemy().MeleeAttacking && self:GetEnemy().MeleeAttacking == true) or (self:GetEnemy().cpt_atkAttacking && self:GetEnemy().cpt_atkAttacking == true)) then
				return true
			else
				return false
			end
		elseif dodgetype == "player" then
			if self.UsingMagic == false && self.onfire == false && self.Flinching == false && self:GetEnemy():IsPlayer() && self:GetEnemy():GetActiveWeapon() != nil && !table.HasValue(self.AcceptableWeaponsTbl,self:GetEnemy():GetActiveWeapon():GetClass()) && (self:GetEnemy():KeyPressed(IN_ATTACK) or self:GetEnemy():KeyPressed(IN_ATTACK2) or self:GetEnemy():KeyReleased(IN_ATTACK) or self:GetEnemy():KeyReleased(IN_ATTACK2) or self:GetEnemy():KeyDown(IN_ATTACK) or self:GetEnemy():KeyDown(IN_ATTACK2)) then
				return true
			else
				return false
			end
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:FindSeq(seq)
		return self:GetSequenceActivity(self:LookupSequence(seq))
	end

	ENT.AcceptableWeaponsTbl = {"gmod_camera","gmod_tool","weapon_physgun","weapon_physcannon"}

	function ENT:CustomOnThink_AIEnabled()
		if self:GetEnemy() != nil then
			local attackthev = ents.FindInSphere(self:GetPos(),500)
			for _,v in pairs(attackthev) do
				local EnemyDistance = self:GetPos():Distance(v:GetPos())
				if EnemyDistance < 500 && math.random(1,10) == 1 && CurTime() > self.NextMoveTime && self:CanDodge("normal") then -- Random movement
					local Evade = self:VJ_CheckAllFourSides(500)
					self:StopAttacks(true)
					if Evade.Right == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL2,true,1.5,false) -- Left dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(1,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						self:SetCollisionGroup(1)
						timer.Simple(0.5, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)

					elseif Evade.Left == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL1,true,1.5,false) -- Right dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(1,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						self:SetCollisionGroup(1)
						timer.Simple(0.5, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)

					elseif Evade.Forward == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL3,true,1.5,false) -- Back dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(1,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						self:SetCollisionGroup(1)
						timer.Simple(0.5, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)

					elseif Evade.Backward == false then
					end
					self.NextMoveTime = CurTime() +math.random(4,7)
				elseif EnemyDistance < 300 && math.random(1,30) == 1 && CurTime() > self.NextDodgeTime && self:CanDodge("player") then -- Dodge attack
					local Evade = self:VJ_CheckAllFourSides(500)
					self:StopAttacks(true)
					if Evade.Right == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL2,true,1.5,false) -- Left dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(1,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						self:SetCollisionGroup(1)
						timer.Simple(0.5, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)

					elseif Evade.Left == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL1,true,1.5,false) -- Right dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(1,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						self:SetCollisionGroup(1)
						timer.Simple(0.5, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)

					elseif Evade.Forward == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL3,true,1.5,false) -- Back dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(1,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						self:SetCollisionGroup(1)
						timer.Simple(0.5, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)

					end
					self.NextDodgeTime = CurTime() +math.random(2,4.5)
				end
			end
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnMeleeAttack_BeforeStartTimer()
		if self:IsOnGround() && self.Atk0 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk1 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk3 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk4 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk5 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk8 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk10 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk11 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk12 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk13 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk14 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk15 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk16 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk17 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(3,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk18 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk19 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)
		self:SetCollisionGroup(1)
		timer.Simple(self.TimeUntilMeleeAttackDamage, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)

		elseif self:IsOnGround() && self.Atk20 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		elseif self:IsOnGround() && self.Atk21 == true then
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self:SwordBox(self.MeleeAttackDamage) end end)
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)

		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	local arguements = {}
	function ENT:art_DetectEvents(inputevent)
		local stringpercent = string.find(inputevent,"%s")
		local eventend = stringpercent || string.find(inputevent,"$")
		local event = string.Left(inputevent,eventend -1)
		local args
		if(stringpercent) then
			args = string.sub(inputevent,stringpercent +1)
			args = string.Explode(",",args)
		else
			args = arguements
		end
		//print(event,(args && ("('" .. table.concat(args,"','") .. "')") || ""))
		if(event == "mattack" || event == "rattack") then
			-- print(event)
			if(!self:art_HandleEvents(event,unpack(args))) then
				MsgN("Unhandled animation event '" .. event .. "'" .. (args && ("('" .. table.concat(args,"','") .. "')") || "") .. " for " .. tostring(self) .. ".")
			end
		elseif(event == "emit") then
			if(!self:art_HandleFootEvents(event,unpack(args))) then
				MsgN("Unhandled sound event '" .. event .. "'" .. (args && ("('" .. table.concat(args,"','") .. "')") || "") .. " for " .. tostring(self) .. ".")
			end
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:art_HandleEvents(...)
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:art_HandleFootEvents(...)
		local event = select(1,...)
		local arg1 = select(2,...)
		if(event == "emit") then
			if(arg1 == "Step") then
				self:EmitSound("gwyn/c5370_foot_hard.ogg", 80, 100, 1)

			elseif(arg1 == "StepLight") then
				self:EmitSound("gwyn/c5370_foot"..math.random(2,3)..".ogg", 80, 100, 1)

			elseif(arg1 == "Swing") then
				self:EmitSound("gwyn/c5370_weapon_swing.ogg", 80, 100, 1)

			elseif(arg1 == "Land") then
				self:EmitSound("gwyn/c5370_down.ogg", 80, 100, 1)

			elseif(arg1 == "Jump") then
				self:EmitSound("artorias/c4100_jump.ogg", 80, 100, 1)
			end
			return true
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:AcceptInput(input,activator,caller,data)
			if(activator == self && string.Left(input,6) == "event_") then
				self:art_DetectEvents(string.sub(input,7))
				return true
			end
	end
	/*-----------------------------------------------
		*** Copyright (c) 2012-2015 by Mayhem, All rights reserved. ***
		No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
		without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
	-----------------------------------------------*/
end

scripted_ents.Register(ENT, ENT.ClassName)