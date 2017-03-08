do
	local ENT = {}
	ENT.ClassName = "npc_vj_mass_thresher"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Thresher Maw"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and let it maul you."
	ENT.Instructions 	= "Click on it to spawn it."
	ENT.Category		= "Mass Effect 3"
	
	if (CLIENT) then
	local Name = "Thresher Maw"
	local LangName = "npc_vj_m3_thresher"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		/*-----------------------------------------------
			*** Copyright (c) 2012-2016 by Mayhem, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/
		ENT.Model = {"models/me3/threshermaw/threshermaw.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
		ENT.StartHealth = 7500
		ENT.HullType = HULL_LARGE
		ENT.VJ_IsHugeMonster = true -- Is this a huge monster?
		ENT.MovementType = VJ_MOVETYPE_STATIONARY -- How does the SNPC move?
		---------------------------------------------------------------------------------------------------------------------------------------------
		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle, etc.)
		ENT.BloodColor = "Blue" -- The blood type, this will detemine what it should use (decal, particle, etc.)
		ENT.Immune_AcidPoisonRadiation = true -- Makes the SNPC not get damage from Acid, posion, radiation
		ENT.Immune_Physics = true -- If set to true, the SNPC won't take damage from props
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.HasRangeAttack = true -- Should the SNPC have a range attack?
		ENT.HasDeathRagdoll = false -- If set to false, it will not spawn the regular ragdoll of the SNPC
		ENT.HasDeathAnimation = true -- Does it play an animation when it dies?
		ENT.AnimTbl_Death = {"Death"} -- Death Animations
		ENT.DeathAnimationTime = 5.5 -- Time until the SNPC spawns its corpse and gets removed
		ENT.FadeCorpse = true
		ENT.FadeCorpseTime = 4 -- This is counted in seconds
		ENT.HasSoundTrack = false -- Does the SNPC have a sound track?
		ENT.MeleeAttackDistance = 1000
		ENT.MeleeAttackAnimationFaceEnemy = false -- Should it face the enemy while playing the melee attack animation?
		
			-- ====== Flinching Code ====== --
		ENT.CanFlinch = 2 -- 0 = Don't flinch | 1 = Flinch at any damage | 2 = Flinch only from certain damages
		ENT.FlinchDamageTypes = {DMG_BLAST} -- If it uses damage-based flinching, which types of damages should it flinch from?
		ENT.FlinchChance = 1 -- Chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.NextMoveAfterFlinchTime = 3 -- How much time until it can move, attack, etc. | Use this for schedules or else the base will set the time 0.6 if it sees it's a schedule!
		ENT.FlinchAnimation_UseSchedule = false -- false = SCHED_ | true = ACT_
		ENT.AnimTbl_Flinch = {ACT_BIG_FLINCH} -- If it uses normal based animation, use this
		ENT.HitGroupFlinching_DefaultWhenNotHit = true -- If it uses hitgroup flinching, should it do the regular flinch if it doesn't hit any of the specified hitgroups?
		
		ENT.AnimTbl_RangeAttack = {"Atk_2"} -- Range Attack Animations
		ENT.RangeDistance = 3100
		ENT.RangeAttackEntityToSpawn = "obj_tm_spit" -- The entity that is spawned when range attacking
		ENT.RangeToMeleeDistance = 1000 -- How close does it have to be until it uses melee?
		ENT.RangeUseAttachmentForPos = true -- Should the projectile spawn on a attachment?
		ENT.RangeUseAttachmentForPosID = "spit" -- The attachment used on the range attack if RangeUseAttachmentForPos is set to true
		ENT.NextRangeAttackTime = 5 -- How much time until it can use a range attack?
		ENT.NextAnyAttackTime_Range = 1 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.RangeAttackExtraTimers = {1.35, 1.4, 1.45, 1.5} -- Extra range attack timers | it will run the projectile code after the given amount of seconds
		ENT.TimeUntilRangeAttackProjectileRelease = 1.3 -- How much time until the projectile code is ran?
		
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_Pain = {
		"tm/ss_maw_hit1.mp3",
		"tm/ss_maw_hit2.mp3",
		"tm/ss_maw_hit3.mp3",
		"tm/ss_maw_hit4.mp3",
		"tm/ss_maw_hit5.mp3",
		"tm/ss_maw_hit6.mp3"
		}
		ENT.SoundTbl_Death = {
		"tm/ss_maw_dead1.mp3",
		"tm/ss_maw_dead2.mp3",
		"tm/ss_maw_dead3.mp3"
		}
		ENT.Atk1 = false
		ENT.AlertSoundLevel = 100
		ENT.IdleSoundLevel = 100
		ENT.MeleeAttackSoundLevel = 100
		ENT.ExtraMeleeAttackSoundLevel = 100
		ENT.MeleeAttackMissSoundLevel = 100
		ENT.PainSoundLevel = 100
		ENT.DeathSoundLevel = 100
		ENT.RangeAttackSoundLevel = 100
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnAlert()
			self:VJ_ACT_PLAYACTIVITY(ACT_COVER,true,2.5,false)
			timer.Simple(0.4,function() if self:IsValid() then self:EmitSound("tm/ss_maw_alert"..math.random(1,2)..".mp3", 100, 100, 1) end end)
		end
		
		function ENT:MultipleMeleeAttacks()
		local EnemyDistance = self:VJ_GetNearestPointToEntityDistance(self:GetEnemy(),self:GetPos():Distance(self:GetEnemy():GetPos()))
			if EnemyDistance > 0 && EnemyDistance < 1000 then
				local randattack = math.random(1,1)
				self.MeleeAttackDistance = 1000
				if	randattack == 1 then
					self.AnimTbl_MeleeAttack = {"Atk_1"}
					self.MeleeAttackDamageDistance = 2000
					self.MeleeAttackAngleRadius = 20 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
					self.MeleeAttackDamageAngleRadius = 20 -- What is the damage angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
					self.HasMeleeAttackKnockBack = true
					self.MeleeAttackKnockBack_Forward1 = 300 -- How far it will push you forward | First in math.random
					self.MeleeAttackKnockBack_Forward2 = 350 -- How far it will push you forward | Second in math.random
					self.MeleeAttackKnockBack_Up1 = 400 -- How far it will push you up | First in math.random
					self.MeleeAttackKnockBack_Up2 = 450 -- How far it will push you up | Second in math.random
					self.MeleeAttackWorldShakeOnMiss = true -- Should it shake the world when it misses during melee attack?
					self.MeleeAttackWorldShakeOnMissAmplitude = 16 -- How much the screen will shake | From 1 to 16, 1 = really low 16 = really high
					self.MeleeAttackWorldShakeOnMissRadius = 2500 -- How far the screen shake goes, in world units
					self.MeleeAttackWorldShakeOnMissDuration = 1 -- How long the screen shake will last, in seconds
					self.MeleeAttackWorldShakeOnMissFrequency = 100 -- Just leave it to 100
					self.MeleeAttackExtraTimers = {}
					self.TimeUntilMeleeAttackDamage = 1
					self.NextMeleeAttackTime = 2.3
					self.NextAnyAttackTime_Melee = 2.3 -- How much time until it can use a attack again? | Counted in Seconds
					self.MeleeAttackReps = 1
					self.MeleeAttackDamage = 31
					self.MeleeAttackDamageType = DMG_SLASH
					self.Atk1 = true
				end
			end
		end
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnMeleeAttack_BeforeStartTimer()
			if self:IsOnGround() && self.Atk1 == true then
			//timer.Simple(1.2,function() if self:IsValid() then self:EmitSound("artorias/c4100_weapon_land.mp3", 80, 100, 1) end end)
			timer.Simple(0.6,function() if self:IsValid() then self:EmitSound("tm/ss_maw_atk"..math.random(1,6)..".mp3", 100, 100, 1) end end)
			end
		end
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(500, 500, 600), Vector(-500, -500, 0))
		end
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:RangeAttackCode_GetShootPos(TheProjectile)
			return (self:GetEnemy():GetPos()+self:GetEnemy():OBBCenter()-self:GetAttachment(self:LookupAttachment(self.RangeUseAttachmentForPosID)).Pos):GetNormal()*5000+self:GetRight()*math.Rand(-300,300)+self:GetUp()*math.Rand(-0,500)
		end
		/*-----------------------------------------------
			*** Copyright (c) 2012-2016 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/	

end
	scripted_ents.Register(ENT, ENT.ClassName)
end
do
	local ENT = {}
	ENT.ClassName = "obj_tm_spit"

	ENT.Type 			= "anim"
	ENT.Base 			= "obj_vj_projectile_base"
	ENT.PrintName		= "Spit"
	ENT.Author 			= "Mayhem"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Information		= "Projectiles for my addons"
	ENT.Category		= "Projectiles"
	
	if (CLIENT) then
		local Name = "Spit"
		local LangName = "obj_tm_spit"
		language.Add(LangName, Name)
		killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
		language.Add("#"..LangName, Name)
		killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include("shared.lua")
		/*-----------------------------------------------
			*** Copyright (c) 2012-2016 by Mayhem, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/
		ENT.Model = {"models/spitball_medium.mdl"} -- The models it should spawn with | Picks a random one from the table
		ENT.DoesRadiusDamage = true -- Should it do a blast damage when it hits something?
		ENT.RadiusDamageRadius = 200 -- How far the damage go? The farther away it's from its enemy, the less damage it will do | Counted in world units
		ENT.RadiusDamage = 30 -- How much damage should it deal? Remember this is a radius damage, therefore it will do less damage the farther away the entity is from its enemy
		ENT.RadiusDamageUseRealisticRadius = true -- Should the damage decrease the farther away the enemy is from the position that the projectile hit?
		ENT.RadiusDamageType = DMG_POISON -- Damage type
		//ENT.DecalTbl_DeathDecals = {"BeerSplash"}
		ENT.SoundTbl_Idle = {"vj_acid/acid_idle1.wav"}
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomPhysicsObjectOnInitialize(phys)
			phys:Wake()
			phys:EnableDrag(false)
			phys:SetBuoyancyRatio(0)
		end
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnInitialize()
			self:SetNoDraw(true)
			ParticleEffectAttach("antlion_spit_trail", PATTACH_ABSORIGIN_FOLLOW, self, 0)
		end
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnThink()
			ParticleEffectAttach("antlion_gib_02_gas", PATTACH_ABSORIGIN_FOLLOW, self, 0)
		end
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:DeathEffects(data,phys)
			ParticleEffect("antlion_gib_02_gas", data.HitPos, Angle(0,0,0), nil)
			ParticleEffect("antlion_gib_02_gas", data.HitPos, Angle(0,0,0), nil)
			ParticleEffect("antlion_gib_02_gas", data.HitPos, Angle(0,0,0), nil)
		end
		/*-----------------------------------------------
			*** Copyright (c) 2012-2016 by Mayhem, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/	

end
	scripted_ents.Register(ENT, ENT.ClassName)
end
