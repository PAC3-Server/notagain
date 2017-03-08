local ENT = {}
ENT.ClassName = "npc_vj_ds_artorias"

game.AddParticles("particles/ds_artorias_fx.pcf")
game.AddParticles("particles/mh_scream_fx.pcf")

local particlename = {
	"mh_monster_scream_large",
	"dskart_ambient",
	"dskart_ambient_flux",
	"dskart_ambient_flux_oriented",
	"dskart_ambient_heat",
	"dskart_ambient_shadows",
	"dskart_ambient_shadows_2",
	"dskart_ambient_shadows_2_oriented",
	"dskart_ambient_shadows_3",
	"dskart_ambient_shadows_3_oriented",
	"dskart_ambient_shadows_oriented",
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
for _,v in ipairs(particlename) do
	PrecacheParticleSystem(v)
end

ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Artorias"
ENT.Author 			= "Mayhem"
ENT.Contact 		= "http://vrejgaming.webs.com/"
ENT.Purpose 		= "Let it eat you."
ENT.Instructions	= "Click on it to spawn it."
ENT.Category		= "Dark Souls"

if (CLIENT) then
	local Name = "Artorias"
	local LangName = "npc_vj_ds_artorias"
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
	ENT.Model = {"models/dark_souls/enemies/giants/artorias.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
	ENT.StartHealth = 3750
	ENT.MoveType = MOVETYPE_STEP
	ENT.HullType = HULL_LARGE
	ENT.VJ_IsHugeMonster = true
	---------------------------------------------------------------------------------------------------------------------------------------------
	ENT.HasBloodDecal = false
	ENT.HasBloodParticle = false
	ENT.HasMeleeAttack = true
	ENT.MeleeAttackDamageType = DMG_SLASH
	ENT.Immune_Dissolve = true -- Immune to Dissolving | Example: Combine Ball
	ENT.Immune_AcidPoisonRadiation = true -- Immune to Acid, Poison and Radiation
	ENT.Immune_Electricity = true -- Immune to Electrical
	ENT.Immune_Physics = true -- Immune to Physics
	ENT.HasDeathAnimation = true
	ENT.AnimTbl_Death = {"Death"}
	ENT.DeathAnimationTime = 7
	ENT.HasDeathRagdoll = false
	ENT.HasSoundTrack = false -- Currently disabled for workshop version of VjBase
	ENT.ConstantlyFaceEnemy = false -- Should it face the enemy constantly?
	ENT.MeleeAttackDistance = 700

		-- ====== Sound File Paths ====== --
	-- Leave blank if you don't want any sounds to play
	ENT.SoundTbl_MeleeAttack = {
	"artorias/c4100_damage1.ogg",
	"artorias/c4100_damage2.ogg",
	"artorias/c4100_damage3.ogg"
	}

	ENT.SoundTbl_Breath = {
	"artorias/c4100_breath.ogg"
	}

	ENT.BreathSoundLevel = 75
	ENT.BreathSoundPitch1 = 80
	ENT.BreathSoundPitch2 = 80

	--Custom Moves
	ENT.Atk1 = false
	ENT.Atk2 = false
	ENT.Atk3 = false
	ENT.Atk4 = false
	ENT.Atk5 = false
	ENT.Atk6 = false
	ENT.Atk7 = false
	ENT.Atk8 = false
	ENT.Atk9 = false
	ENT.Atk10 = false
	ENT.Atk11 = false
	ENT.Atk12 = false
	ENT.Atk13 = false
	ENT.Atk14 = false
	ENT.Artorias_Taunt = false
	ENT.buffval = 1
	ENT.Buff = false
	ENT.CantBuff = false
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnInitialize()
		self.NextMoveTime = 0
		self.NextDodgeTime = 0
		self.NextMoveAroundTime = 0
		self.NextBlockTime = 0
		self.onfire = false
		self.UsingMagic = false
	if !IsValid(self.AbyssLight) then

	local att = self:LookupAttachment("glow1")
	if(att != 0) then
	self.AbyssLight = ents.Create("light_dynamic")
	self.AbyssLight:SetKeyValue("_light","147 112 219 200")
	self.AbyssLight:SetKeyValue("brightness","0")
	self.AbyssLight:SetKeyValue("distance","400")
	self.AbyssLight:SetKeyValue("style","0")
	self.AbyssLight:SetPos(self:GetPos())
	self.AbyssLight:SetParent(self)
	self.AbyssLight:Spawn()
	self.AbyssLight:Activate()
	self.AbyssLight:Fire("SetParentAttachment","glow1")
	self.AbyssLight:Fire("TurnOn","",0)
	self.AbyssLight:DeleteOnRemove(self)
	end

	end

		self:SetCollisionBounds(Vector(40, 40, 110), -Vector(40, 40, 0))
		//ParticleEffectAttach("ghost_glow",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("origin"))
		//ParticleEffectAttach("dskart_ambient_flux_oriented",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("glow3"))
		ParticleEffectAttach("dskart_ambient",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("glow2"))
		//ParticleEffectAttach("mh_monster_scream_large",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("glow3"))

	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnPriorToKilled(dmginfo,hitgroup)
	timer.Simple(4.7,function() if self:IsValid(self.DeathGlow) then

	local att = self:LookupAttachment("glow1")
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
	self.DeathGlow:Fire("SetParentAttachment","glow1")
	self.DeathGlow:Fire("TurnOn","",0)
	self.DeathGlow:DeleteOnRemove(self)
	end

	end
	end)
		timer.Simple(4.7,function() if self:IsValid() then ParticleEffectAttach("dskart_death",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("origin")) end end)
	end

	function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo,hitgroup)
		if self.Buff == true then
			dmginfo:ScaleDamage(0.2)
			elseif self.Buff == false then
			dmginfo:ScaleDamage(1)
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnAlert()
		self:VJ_ACT_PLAYACTIVITY(ACT_ARM,true,2.5,false)
		timer.Simple(1,function() if self:IsValid() then util.ScreenShake(self:GetPos(),12,100,2,450) end end)
		timer.Simple(2.3,function() if self:IsValid() && self.Buff == false then self:StopParticles() end end)
		timer.Simple(1,function() if self:IsValid() && self.Buff == false then ParticleEffectAttach("mh_monster_scream_large",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("roar")) end end)
		timer.Simple(2.31,function() if self:IsValid() && self.Buff == false then ParticleEffectAttach("dskart_ambient",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("glow2")) end end)
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:MultipleMeleeAttacks()
		local EnemyDistance = self:VJ_GetNearestPointToEntityDistance(self:GetEnemy(),self:GetPos():Distance(self:GetEnemy():GetPos()))
		if EnemyDistance > 0 && EnemyDistance < 150 then
			local randattack_close = math.random(1,5)
			self.MeleeAttackDistance = 150
			if randattack_close == 1 then
				self.AnimTbl_MeleeAttack = {"Attack0"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.1
				self.NextAnyAttackTime_Melee = 2.3
				self.MeleeAttackDamage = 23*self.buffval
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = true
				self.Atk2 = false
				self.Atk3 = false
				self.Atk4 = false
				self.Atk5 = false
				self.Atk6 = false
				self.Atk7 = false
				self.Atk8 = false
				self.Atk9 = false
				self.Atk10 = false
				self.Atk11 = false
				self.Atk12 = false
				self.Atk13 = false
				self.Atk14 = false
			elseif randattack_close == 2  then
				self.AnimTbl_MeleeAttack = {"Attack10"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.1
				self.NextAnyAttackTime_Melee = 1.3
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = 15*self.buffval
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = false
				self.Atk2 = false
				self.Atk3 = false
				self.Atk4 = false
				self.Atk5 = false
				self.Atk6 = false
				self.Atk7 = false
				self.Atk8 = true
				self.Atk9 = false
				self.Atk10 = false
				self.Atk11 = false
				self.Atk12 = false
				self.Atk13 = false
				self.Atk14 = false
			elseif randattack_close == 3  then
				self.AnimTbl_MeleeAttack = {"Attack9"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.1
				self.NextAnyAttackTime_Melee = 0.95
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = 21*self.buffval
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = false
				self.Atk2 = false
				self.Atk3 = false
				self.Atk4 = false
				self.Atk5 = false
				self.Atk6 = false
				self.Atk7 = false
				self.Atk8 = false
				self.Atk9 = true
				self.Atk10 = false
				self.Atk11 = false
				self.Atk12 = false
				self.Atk13 = false
				self.Atk14 = false
			elseif randattack_close == 4  then
				self.AnimTbl_MeleeAttack = {"Attack12"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.1
				self.NextAnyAttackTime_Melee = 2.1
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = 29*self.buffval
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = false
				self.Atk2 = false
				self.Atk3 = false
				self.Atk4 = false
				self.Atk5 = false
				self.Atk6 = false
				self.Atk7 = false
				self.Atk8 = false
				self.Atk9 = false
				self.Atk10 = false
				self.Atk11 = false
				self.Atk12 = true
				self.Atk13 = false
				self.Atk14 = false
			elseif randattack_close == 5  then
				self.AnimTbl_MeleeAttack = {"Attack1"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1
				self.NextAnyAttackTime_Melee = 1.9
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = 27*self.buffval
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = false
				self.Atk2 = false
				self.Atk3 = false
				self.Atk4 = false
				self.Atk5 = false
				self.Atk6 = false
				self.Atk7 = false
				self.Atk8 = false
				self.Atk9 = false
				self.Atk10 = false
				self.Atk11 = true
				self.Atk12 = false
				self.Atk13 = false
				self.Atk14 = false
			end
		end
		if EnemyDistance > 100 && EnemyDistance < 200 then
				self.MeleeAttackDistance = 200
				local randattack_midrange = math.random(1,2)
			if randattack_midrange == 1  then
				self.AnimTbl_MeleeAttack = {"Attack2"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false -- Should it shake the world when it misses during melee attack?
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.4
				self.NextAnyAttackTime_Melee = 1.8
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = 38*self.buffval
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = false
				self.Atk2 = true
				self.Atk3 = false
				self.Atk4 = false
				self.Atk5 = false
				self.Atk6 = false
				self.Atk7 = false
				self.Atk8 = false
				self.Atk9 = false
				self.Atk10 = false
				self.Atk11 = false
				self.Atk12 = false
				self.Atk13 = false
				self.Atk14 = false
			elseif randattack_midrange == 2  then
				self.AnimTbl_MeleeAttack = {"Attack13"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1
				self.NextAnyAttackTime_Melee = 1.4
				self.MeleeAttackDamage = 33*self.buffval
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = false
				self.Atk2 = false
				self.Atk3 = false
				self.Atk4 = false
				self.Atk5 = false
				self.Atk6 = false
				self.Atk7 = false
				self.Atk8 = false
				self.Atk9 = false
				self.Atk10 = false
				self.Atk11 = false
				self.Atk12 = false
				self.Atk13 = false
				self.Atk14 = true
			end
		end
		if EnemyDistance > 250 && EnemyDistance < 350 then
			self.MeleeAttackDistance = 350
			local randattack_far = math.random(1,4)
			if randattack_far == 1  then
				self.AnimTbl_MeleeAttack = {"Attack3"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.45
				self.NextAnyAttackTime_Melee = 1.5
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = 49*self.buffval
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = false
				self.Atk2 = false
				self.Atk3 = true
				self.Atk4 = false
				self.Atk5 = false
				self.Atk6 = false
				self.Atk7 = false
				self.Atk8 = false
				self.Atk9 = false
				self.Atk10 = false
				self.Atk11 = false
				self.Atk12 = false
				self.Atk13 = false
				self.Atk14 = false
			elseif randattack_far == 4 && self.Buff == false && self.CantBuff == false then
				self.AnimTbl_MeleeAttack = {ACT_DISARM}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageAngleRadius = 180 -- What is the damage angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 300
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 5.7
				self.NextAnyAttackTime_Melee = 2
				self.MeleeAttackDamage = 45
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = false
				self.Atk2 = false
				self.Atk3 = false
				self.Atk4 = false
				self.Atk5 = false
				self.Atk6 = false
				self.Atk7 = false
				self.Atk8 = false
				self.Atk9 = false
				self.Atk10 = false
				self.Atk11 = false
				self.Atk12 = false
				self.Atk13 = true
				self.Atk14 = false
			elseif randattack_far == 2  then
				self.AnimTbl_MeleeAttack = {"Attack4"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.6
				self.NextAnyAttackTime_Melee = 1.7
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = 43*self.buffval
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = false
				self.Atk2 = false
				self.Atk3 = false
				self.Atk4 = true
				self.Atk5 = false
				self.Atk6 = false
				self.Atk7 = false
				self.Atk8 = false
				self.Atk9 = false
				self.Atk10 = false
				self.Atk11 = false
				self.Atk12 = false
				self.Atk13 = false
				self.Atk14 = false
			elseif randattack_far == 3  then
				self.AnimTbl_MeleeAttack = {"Attack6"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = false
				self.MeleeAttackKnockBack_Forward1 = 300 -- How far it will push you forward | First in math.random
				self.MeleeAttackKnockBack_Forward2 = 350 -- How far it will push you forward | Second in math.random
				self.MeleeAttackKnockBack_Up1 = 300 -- How far it will push you up | First in math.random
				self.MeleeAttackKnockBack_Up2 = 350 -- How far it will push you up | Second in math.random
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 1.65
				self.NextAnyAttackTime_Melee = 2.2
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = 47*self.buffval
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = false
				self.Atk2 = false
				self.Atk3 = false
				self.Atk4 = false
				self.Atk5 = false
				self.Atk6 = true
				self.Atk7 = false
				self.Atk8 = false
				self.Atk9 = false
				self.Atk10 = false
				self.Atk11 = false
				self.Atk12 = false
				self.Atk13 = false
				self.Atk14 = false
			end
		end
		if EnemyDistance > 550 && EnemyDistance < 900 then
			self.MeleeAttackDistance = 900
			local randattack_leap = math.random(1,1)
			if randattack_leap == 1  then
				self.AnimTbl_MeleeAttack = {"Attack5"}
				self.MeleeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
				self.MeleeAttackDamageDistance = 0
				self.HasMeleeAttackKnockBack = false
				self.MeleeAttackWorldShakeOnMiss = true -- Should it shake the world when it misses during melee attack?
				self.MeleeAttackWorldShakeOnMissAmplitude = 16 -- How much the screen will shake | From 1 to 16, 1 = really low 16 = really high
				self.MeleeAttackWorldShakeOnMissRadius = 1000 -- How far the screen shake goes, in world units
				self.MeleeAttackWorldShakeOnMissDuration = 1 -- How long the screen shake will last, in seconds
				self.MeleeAttackWorldShakeOnMissFrequency = 100 -- Just leave it to 100
				self.MeleeAttackExtraTimers = {}
				self.TimeUntilMeleeAttackDamage = 2.73
				self.NextAnyAttackTime_Melee = 2
				self.MeleeAttackReps = 1
				self.MeleeAttackDamage = 57*self.buffval
				self.MeleeAttackDamageType = DMG_SLASH
				self.Atk1 = false
				self.Atk2 = false
				self.Atk3 = false
				self.Atk4 = false
				self.Atk5 = true
				self.Atk6 = false
				self.Atk7 = false
				self.Atk8 = false
				self.Atk9 = false
				self.Atk10 = false
				self.Atk11 = false
				self.Atk12 = false
				self.Atk13 = false
				self.Atk14 = false
			end
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:SwordBox(vStndDmg)
	vStndDmg = vStndDmg or 1
	local attackthev = ents.FindInSphere(self:GetAttachment(1).Pos, 80)
	for _,v in pairs(attackthev) do
	if (v:IsNPC()) && (self:Disposition(v) == 1 or self:Disposition(v) == 2) && (v != self) && (v:GetClass() != self:GetClass()) or v:GetClass() == "prop_physics" or v:GetClass() == "func_breakable_surf" or table.HasValue(self.EntitiesToDestroyClass,v:GetClass()) or v.VJ_AddEntityToSNPCAttackList == true then
	 local doactualdmg = DamageInfo()
	 doactualdmg:SetDamage(vStndDmg)
	 doactualdmg:SetInflictor(self)
	 doactualdmg:SetDamageType(self.MeleeAttackDamageType)
	 doactualdmg:SetAttacker(self)
	 v:TakeDamageInfo(doactualdmg, self)
	 v:EmitSound("artorias/c4100_damage"..math.random(1,3)..".ogg", 80, 80, 1)

	elseif ((v:IsPlayer() && v:Alive())) && (self:Disposition(v) == 1 or self:Disposition(v) == 2) && (v != self) && (v:GetClass() != self:GetClass()) or v:GetClass() == "prop_physics" or v:GetClass() == "func_breakable_surf" or table.HasValue(self.EntitiesToDestroyClass,v:GetClass()) or v.VJ_AddEntityToSNPCAttackList == true then
	local doactualdmg = DamageInfo()
	 doactualdmg:SetDamage(vStndDmg)
	 doactualdmg:SetInflictor(self)
	 doactualdmg:SetDamageType(self.MeleeAttackDamageType)
	 doactualdmg:SetAttacker(self)
	 v:TakeDamageInfo(doactualdmg, self)
	 v:EmitSound("artorias/c4100_damage"..math.random(1,3)..".ogg", 80, 80, 1)
	 v:ViewPunch( Angle( math.random(-50, 50), math.random(-50, 50), math.random(30, -30) ) )
	end
	end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnThink_AIEnabled()
	 local ent = self:GetEnemy()
	 local y_enemy = 0
	 local x_enemy = 0

	 if(IsValid(ent)) then
	  local self_pos = self:GetPos() + self:OBBCenter()
	  local enemy_pos = ent:GetPos() + ent:OBBCenter()
	  local self_ang = self:GetAngles()
	  local enemy_ang = (enemy_pos - self_pos):Angle()

	  x_enemy = math.AngleDifference(enemy_ang.p,self_ang.p)
	  y_enemy = math.AngleDifference(enemy_ang.y,self_ang.y)
	 end

	 local self_aim_y = self:GetPoseParameter("aim_yaw")
	 self:SetPoseParameter("aim_yaw",math.ApproachAngle(self_aim_y,y_enemy,5))

	 local self_aim_x = self:GetPoseParameter("aim_pitch")
	 self:SetPoseParameter("aim_pitch",math.ApproachAngle(self_aim_x,x_enemy,5))
		if self.Buff == false then
		self.buffval = 1
		elseif self.Buff == true then
		self.buffval = 5
		end

		if self:GetEnemy() != nil then
			local attackthev = ents.FindInSphere(self:GetPos(),500)
			for _,v in pairs(attackthev) do
				local EnemyDistance = self:GetPos():Distance(v:GetPos())
				if EnemyDistance < 500 && math.random(1,10) == 1 && CurTime() > self.NextMoveTime && self:CanDodge("normal") then -- Random movement
					local Evade = self:VJ_CheckAllFourSides(500)
					self:StopAttacks(true)
					if Evade.Right == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL2,true,1,false) -- Left dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(0.6,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						timer.Simple(1.2,function() if self:IsValid() then self.GodMode = false end end)
						timer.Simple(0.1,function() if self:IsValid() then self:EmitSound("artorias/c4100_jump.ogg", 65, 80, 1) end end)
						timer.Simple(0.4,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.5,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.6,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						self:SetCollisionGroup(1)
						timer.Simple(0.5, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)

					elseif Evade.Left == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL1,true,1,false) -- Right dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(0.6,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						timer.Simple(1.2,function() if self:IsValid() then self.GodMode = false end end)
						timer.Simple(0.1,function() if self:IsValid() then self:EmitSound("artorias/c4100_jump.ogg", 65, 80, 1) end end)
						timer.Simple(0.4,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.5,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.6,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						self:SetCollisionGroup(1)
						timer.Simple(0.5, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)

					elseif Evade.Forward == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL3,true,1,false) -- Back dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(0.6,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						timer.Simple(1.2,function() if self:IsValid() then self.GodMode = false end end)
						timer.Simple(0.1,function() if self:IsValid() then self:EmitSound("artorias/c4100_jump.ogg", 65, 80, 1) end end)
						timer.Simple(0.4,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.5,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.6,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						self:SetCollisionGroup(1)
						timer.Simple(0.5, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)
					elseif Evade.Backward == false then
					end
					self.NextMoveTime = CurTime() +math.random(4,7)
				elseif EnemyDistance < 300 && math.random(1,5) == 1 && CurTime() > self.NextDodgeTime && self:CanDodge("player") then -- Dodge attack
					local Evade = self:VJ_CheckAllFourSides(500)
					self:StopAttacks(true)
					if Evade.Right == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL2,true,1,false) -- Left dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(0.6,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						timer.Simple(1.2,function() if self:IsValid() then self.GodMode = false end end)
						timer.Simple(0.1,function() if self:IsValid() then self:EmitSound("artorias/c4100_jump.ogg", 65, 80, 1) end end)
						timer.Simple(0.4,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.5,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.6,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						self:SetCollisionGroup(1)
						timer.Simple(0.5, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)
					elseif Evade.Left == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL1,true,1,false) -- Right dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(0.6,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						timer.Simple(1.2,function() if self:IsValid() then self.GodMode = false end end)
						timer.Simple(0.1,function() if self:IsValid() then self:EmitSound("artorias/c4100_jump.ogg", 65, 80, 1) end end)
						timer.Simple(0.4,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.5,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.6,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						self:SetCollisionGroup(1)
						timer.Simple(0.5, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)
					elseif Evade.Forward == false then
						self:VJ_ACT_PLAYACTIVITY(ACT_SIGNAL3,true,1,false) -- Back dodge anim
						timer.Simple(0.3,function() if self:IsValid() then self.ConstantlyFaceEnemy = true end end)
						timer.Simple(0.6,function() if self:IsValid() then self.ConstantlyFaceEnemy = false end end)
						timer.Simple(1.2,function() if self:IsValid() then self.GodMode = false end end)
						timer.Simple(0.1,function() if self:IsValid() then self:EmitSound("artorias/c4100_jump.ogg", 65, 80, 1) end end)
						timer.Simple(0.4,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.5,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
						timer.Simple(0.6,function() if self:IsValid() then self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 65, 70, 1) end end)
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
		if self:IsOnGround() && self.Atk1 == true then
		self.MeleeAttackAnimationFaceEnemy = true
		timer.Simple(1.2,function() if self:IsValid()  && self.Dead == false then util.ScreenShake(self:GetPos(),6,100,1,400) end end)
		timer.Simple(0.8,function() if self:IsValid()  && self.Dead == false then util.ScreenShake(self:GetPos(),4,100,0.5,300) end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self:IsOnGround() && self.Atk14 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = true end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self:IsOnGround() &&  self.Atk13 == true then
		self.Buff = true
		self.CantBuff = true
		self.MeleeAttackAnimationFaceEnemy = false
		timer.Simple(38.2,function() if self:IsValid() && self.Dead == false then self.Buff = false end end)
		timer.Simple(98.2,function() if self:IsValid() && self.Dead == false then self.CantBuff = false end end)
		timer.Simple(38.2,function() if self:IsValid() && self.Dead == false then self:StopParticles() end end)
		timer.Simple(38.21,function() if self:IsValid() && self.Dead == false then ParticleEffectAttach("dskart_ambient",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("glow2")) end end)

		elseif self:IsOnGround() && self.Atk11 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = true end end)
		timer.Simple(0,function() if self:IsValid() && self.Dead == false then self.HasMeleeAttackKnockBack = true end end)
		timer.Simple(0,function() if self:IsValid() && self.Dead == false then self.MeleeAttackKnockBack_Forward1 = 350 end end)
		timer.Simple(0,function() if self:IsValid() && self.Dead == false then self.MeleeAttackKnockBack_Forward2 = 200	end end)
		timer.Simple(0,function() if self:IsValid() && self.Dead == false then self.MeleeAttackKnockBack_Up1 = 350 end end)
		timer.Simple(0,function() if self:IsValid() && self.Dead == false then self.MeleeAttackKnockBack_Up2 = 300 end end)
		timer.Simple(0,function() if self:IsValid() && self.Dead == false then self.MeleeAttackKnockBack_Right1 = 0 end end)
		timer.Simple(0,function() if self:IsValid() && self.Dead == false then self.MeleeAttackKnockBack_Right2 = 0 end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self.Atk10 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)
		timer.Simple(1.2,function() if self:IsValid() && self.Dead == false then util.ScreenShake(self:GetPos(),6,100,1,400) end end)
		timer.Simple(0.8,function() if self:IsValid() && self.Dead == false then util.ScreenShake(self:GetPos(),4,100,0.5,300) end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self:IsOnGround() && self.Atk12 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = true end end)
		timer.Simple(1.2,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam", self:LocalToWorld(Vector(170,0,0)), self:GetAngles(), self) end end)
		timer.Simple(1.2,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact", self:LocalToWorld(Vector(120,0,0)), self:GetAngles(), self) end end)
		timer.Simple(1.2,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact_2", self:LocalToWorld(Vector(120,0,0)), self:GetAngles(), self) end end)
		timer.Simple(1.5, function() if self:IsValid() && self.Dead == false then self:EmitSound("artorias/c4100sfx1.ogg", 80, 80, 1) end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self:IsOnGround() && self.Atk2 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = true end end)
		timer.Simple(1.4,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam", self:LocalToWorld(Vector(180,20,0)), self:GetAngles(), self) end end)
		timer.Simple(1.4,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact", self:LocalToWorld(Vector(120,20,0)), self:GetAngles(), self) end end)
		timer.Simple(1.4,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact_2", self:LocalToWorld(Vector(120,20,0)), self:GetAngles(), self) end end)
		timer.Simple(1.6, function() if self:IsValid() && self.Dead == false then self:EmitSound("artorias/c4100sfx1.ogg", 80, 80, 1) end end)
		timer.Simple(1.4,function() if self:IsValid() && self.Dead == false then util.ScreenShake(self:GetPos(),12,100,1,400) end end)
		timer.Simple(0.9,function() if self:IsValid() && self.Dead == false then util.ScreenShake(self:GetPos(),4,100,0.5,400) end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self:IsOnGround() && self.Atk3 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = true end end)
		timer.Simple(1.7, function() if self:IsValid() && self.Dead == false then self:EmitSound("artorias/c4100sfx1.ogg", 80, 80, 1) end end)
		timer.Simple(1.5,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam", self:LocalToWorld(Vector(200,0,0)), self:GetAngles(), self) end end)
		timer.Simple(1.5,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact", self:LocalToWorld(Vector(230,0,0)), self:GetAngles(), self) end end)
		timer.Simple(1.5,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact_2", self:LocalToWorld(Vector(230,0,0)), self:GetAngles(), self) end end)
		timer.Simple(1.5,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact", self:LocalToWorld(Vector(150,0,0)), self:GetAngles(), self) end end)
		timer.Simple(1.5,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact_2", self:LocalToWorld(Vector(150,0,0)), self:GetAngles(), self) end end)
		timer.Simple(1.5,function() if self:IsValid() && self.Dead == false then util.ScreenShake(self:GetPos(),16,100,1,500) end end)
		timer.Simple(0.7,function() if self:IsValid() && self.Dead == false then util.ScreenShake(self:GetPos(),4,100,0.7,400) end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self:IsOnGround() && self.Atk4 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = true end end)
		timer.Simple(0.5,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)
		timer.Simple(1.1,function() if self:IsValid() && self.Dead == false then util.ScreenShake(self:GetPos(),4,100,1,400) end end)
		timer.Simple(1.8, function() if self:IsValid() && self.Dead == false then self:EmitSound("artorias/c4100sfx1.ogg", 80, 80, 1) end end)
		timer.Simple(1,function() if self:IsValid() && self.Dead == false then ParticleEffectAttach("dskart_aura",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("default")) end end)
		timer.Simple(1,function() if self:IsValid() && self.Dead == false then ParticleEffectAttach("dskart_fw_charge_abyss",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("default")) end end)
		timer.Simple(1,function() if self:IsValid() && self.Dead == false then ParticleEffectAttach("dskart_fw_charge_abyss_2",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("default")) end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self.Atk5 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = true end end)
		timer.Simple(0.5,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)
		timer.Simple(2.73,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact", self:LocalToWorld(Vector(220,0,0)), self:GetAngles(), self) end end)
		timer.Simple(2.73,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact_2", self:LocalToWorld(Vector(220,0,0)), self:GetAngles(), self) end end)
		timer.Simple(2.73,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact_smoke", self:LocalToWorld(Vector(220,0,0)), self:GetAngles(), self) end end)
		timer.Simple(2.73,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact", self:LocalToWorld(Vector(160,0,0)), self:GetAngles(), self) end end)
		timer.Simple(2.73,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact_2", self:LocalToWorld(Vector(160,0,0)), self:GetAngles(), self) end end)
		timer.Simple(2.73,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact", self:LocalToWorld(Vector(160,0,0)), self:GetAngles(), self) end end)
		timer.Simple(2.73,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_slam_impact_2", self:LocalToWorld(Vector(160,0,0)), self:GetAngles(), self) end end)
		timer.Simple(2.6,function() if self:IsValid() then ParticleEffect("hammer_impact_button", self:LocalToWorld(Vector(250,0,0)), self:GetAngles(), self) end end)
		timer.Simple(1.6,function() if self:IsValid() && self.Dead == false then self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE) end end)
		timer.Simple(2.73,function() if self:IsValid() && self.Dead == false then self:SetCollisionGroup(COLLISION_GROUP_NPC) end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self:IsOnGround() && self.Atk6 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = true end end)
		timer.Simple(0.5,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)
		timer.Simple(2,function() if self:IsValid() && self.Dead == false then util.ScreenShake(self:GetPos(),12,100,1,350) end end)
		timer.Simple(1.7,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_blade_hit", self:LocalToWorld(Vector(-90,-70,0)), self:GetAngles(), self) end end)
		timer.Simple(1.72,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_blade_hit", self:LocalToWorld(Vector(-70,-85,0)), self:GetAngles(), self) end end)
		timer.Simple(1.74,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_blade_hit", self:LocalToWorld(Vector(-50,-105,0)), self:GetAngles(), self) end end)
		timer.Simple(1.76,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_blade_hit", self:LocalToWorld(Vector(-30,-120,0)), self:GetAngles(), self) end end)
		timer.Simple(1.78,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_blade_hit", self:LocalToWorld(Vector(-10,-135,0)), self:GetAngles(), self) end end)
		timer.Simple(1.8,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_blade_hit", self:LocalToWorld(Vector(10,-150,0)), self:GetAngles(), self) end end)
		timer.Simple(2.2,function() if self:IsValid() && self.Dead == false then ParticleEffect("dskart_blade_hit", self:LocalToWorld(Vector(55,-125,0)), self:GetAngles(), self) end end)
		timer.Simple(1,function() if self:IsValid() && self.Dead == false then ParticleEffectAttach("dskart_aura",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("default")) end end)
		timer.Simple(1,function() if self:IsValid() && self.Dead == false then ParticleEffectAttach("dskart_fw_charge_abyss_2",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("default")) end end)
		timer.Simple(1,function() if self:IsValid() && self.Dead == false then ParticleEffectAttach("dskart_fw_charge_abyss",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("default")) end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self:IsOnGround() && self.Atk7 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = true end end)
		timer.Simple(0.5,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)
		timer.Simple(1,function() if self:IsValid() && self.Dead == false then util.ScreenShake(self:GetPos(),4,100,0.7,400) end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self:IsOnGround() && self.Atk8 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = true end end)
		timer.Simple(0.5,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = false end end)
		timer.Simple(0.9,function() if self:IsValid() && self.Dead == false then util.ScreenShake(self:GetPos(),5,100,1.3,400) end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)
		timer.Simple(1.4,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		elseif self:IsOnGround() && self.Atk9 == true then
		timer.Simple(0,function() if self:IsValid() then self.MeleeAttackAnimationFaceEnemy = true end end)
		timer.Simple(1,function() if self:IsValid() && self.Dead == false then util.ScreenShake(self:GetPos(),4,100,0.7,400) end end)
		timer.Simple(self.TimeUntilMeleeAttackDamage,function() if self:IsValid() && self.Dead == false then self:SwordBox(self.MeleeAttackDamage) end end)

		end
	end

	ENT.AcceptableWeaponsTbl = {"gmod_camera","gmod_tool","weapon_physgun","weapon_physcannon"}
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CanDodge(dodgetype)
		if dodgetype == "normal" then
			if self.UsingMagic == false && self.MeleeAttacking == false && self.onfire == false && self.Flinching == false && self:GetEnemy():IsNPC() && ((self:GetEnemy().MeleeAttacking && self:GetEnemy().MeleeAttacking == true) or (self:GetEnemy().cpt_atkAttacking && self:GetEnemy().cpt_atkAttacking == true)) then
				return true
			else
				return false
			end
		elseif dodgetype == "player" then
			if self.UsingMagic == false && self.MeleeAttacking == false && self.onfire == false && self.Flinching == false && self:GetEnemy():IsPlayer() && self:GetEnemy():GetActiveWeapon() != nil && !table.HasValue(self.AcceptableWeaponsTbl,self:GetEnemy():GetActiveWeapon():GetClass()) && (self:GetEnemy():KeyPressed(IN_ATTACK) or self:GetEnemy():KeyPressed(IN_ATTACK2) or self:GetEnemy():KeyReleased(IN_ATTACK) or self:GetEnemy():KeyReleased(IN_ATTACK2) or self:GetEnemy():KeyDown(IN_ATTACK) or self:GetEnemy():KeyDown(IN_ATTACK2)) then
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
				self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 80, 80, 1)
				self:EmitSound("artorias/c4100_foot"..math.random(1,2)..".ogg", 80, 100, 1)

			elseif(arg1 == "Whoosh") then
				self:EmitSound("artorias/c4100_swing.ogg", 80, 100, 1)

			elseif(arg1 == "ImpactLight") then
				self:EmitSound("artorias/c4100_weapon_land.ogg", 80, 100, 1)
				self.MeleeAttackAnimationFaceEnemy = false
				util.ScreenShake(self:GetPos(),12,100,1,350)
				--ParticleEffectAttach("rock_impact_stalactite",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("fire"))

			elseif(arg1 == "Armor") then
				self:EmitSound("artorias/c4100_movement"..math.random(1,4)..".ogg", 80, 80, 1)

			elseif(arg1 == "Hit") then

			elseif(arg1 == "Land") then
				self:EmitSound("artorias/c4100_land.ogg", 80, 100, 1)

			elseif(arg1 == "Jump") then
				self:EmitSound("artorias/c4100_jump.ogg", 80, 100, 1)

			elseif(arg1 == "Aggrovate") then
				self:EmitSound("artorias/c4100_v_ikaku.ogg", 80, 100, 1)

			elseif(arg1 == "Die") then
				//self:EmitSound("artorias/Artorias_Charge_Unrelenting.ogg", 100, 100, 1)
				self:EmitSound("artorias/c4100_v_dead.ogg", 100, 55, 1)
				self:EmitSound("artorias/dialogue/grunt_long_02.ogg", 100, 120, 1)

			elseif(arg1 == "Zimen") then
				self:EmitSound("artorias/c4100_weapon_zimen.ogg", 80, 100, 1)

			elseif(arg1 == "OutCry") then
				ParticleEffectAttach("dskart_ambient_flux_oriented",PATTACH_POINT_FOLLOW,self,self:LookupAttachment("glow3"))
				//self:EmitSound("artorias/Artorias_Charge_Unrelenting.ogg", 130, 100, 1)
				self:EmitSound("artorias/c4100_bomb.ogg", 80, 100, 1)
				ParticleEffect("dskart_postcharge", self:LocalToWorld(Vector(0,0,0)), self:GetAngles(), self)

			elseif(arg1 == "ChargeUp") then
				self:EmitSound("artorias/c4100_charge.ogg", 80, 100, 1)
				ParticleEffect("dskart_charge", self:LocalToWorld(Vector(0,0,0)), self:GetAngles(), self)

			elseif(arg1 == "BreatheIn") then

			elseif(arg1 == "BreatheOut") then

			elseif(arg1 == "StepRunLeft") then
				//ParticleEffect("halloween_boss_foot_impact", self:LocalToWorld(Vector(0,10,0)), self:GetAngles(), self)
				ParticleEffect("water_splash_01", self:LocalToWorld(Vector(0,10,0)), self:GetAngles(), self)
				ParticleEffect("water_splash_01_refract", self:LocalToWorld(Vector(0,10,0)), self:GetAngles(), self)

			elseif(arg1 == "StepRunRight") then
				//ParticleEffect("halloween_boss_foot_impact", self:LocalToWorld(Vector(0,-10,0)), self:GetAngles(), self)
				ParticleEffect("water_splash_01", self:LocalToWorld(Vector(0,-10,0)), self:GetAngles(), self)
				ParticleEffect("water_splash_01_refract", self:LocalToWorld(Vector(0,10,0)), self:GetAngles(), self)

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