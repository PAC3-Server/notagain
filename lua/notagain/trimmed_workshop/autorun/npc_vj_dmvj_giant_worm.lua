do
	local ENT = {}
	ENT.ClassName = "npc_vj_dmvj_giant_worm"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Giant Worm"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Have Worm Sex."
	ENT.Instructions 	= "Click on it to spawn it."
	ENT.Category		= "Dark Messiah"

	if (CLIENT) then
		local Name = "Giant Worm"
		local LangName = "npc_vj_dmvj_giant_worm"
		language.Add(LangName, Name)
		killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
		language.Add("#"..LangName, Name)
		killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end

	if SERVER then
		/*-----------------------------------------------
			*** Copyright (c) 2012-2017 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/
		ENT.Model = {"models/VJ_DARKMESSIAH/giantworm.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
		ENT.StartHealth = GetConVarNumber("vj_dm_worm_h")
		ENT.HullType = HULL_LARGE
		ENT.VJ_IsHugeMonster = true -- Is this a huge monster?
		ENT.MovementType = VJ_MOVETYPE_STATIONARY -- How does the SNPC move?
		---------------------------------------------------------------------------------------------------------------------------------------------
		ENT.VJ_NPC_Class = {"CLASS_DARK_MESSIAH"} -- NPCs with the same class with be allied to each other
		ENT.BloodColor = "Red" -- The blood type, this will determine what it should use (decal, particle, etc.)
		ENT.HasBloodPool = false -- Does it have a blood pool?
		ENT.Immune_AcidPoisonRadiation = true -- Makes the SNPC not get damage from Acid, posion, radiation
		ENT.Immune_Physics = true -- If set to true, the SNPC won't take damage from props
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_RELOAD} -- Melee Attack Animations
		ENT.MeleeAttackDistance = 800 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 1100 -- How far does the damage go?
		ENT.TimeUntilMeleeAttackDamage = 2.1 -- This counted in seconds | This calculates the time until it hits something
		ENT.NextAnyAttackTime_Melee = 2.4 -- How much time until it can use any attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_dm_worm_d")
		ENT.HasMeleeAttackKnockBack = true -- If true, it will cause a knockback to its enemy
		ENT.MeleeAttackKnockBack_Forward1 = 700 -- How far it will push you forward | First in math.random
		ENT.MeleeAttackKnockBack_Forward2 = 730 -- How far it will push you forward | Second in math.random
		ENT.MeleeAttackKnockBack_Up1 = 500 -- How far it will push you up | First in math.random
		ENT.MeleeAttackKnockBack_Up2 = 530 -- How far it will push you up | Second in math.random
		ENT.MeleeAttackWorldShakeOnMiss = true -- Should it shake the world when it misses during melee attack?
		ENT.MeleeAttackWorldShakeOnMissAmplitude = 16 -- How much the screen will shake | From 1 to 16, 1 = really low 16 = really high
		ENT.MeleeAttackWorldShakeOnMissRadius = 2000 -- How far the screen shake goes, in world units
		ENT.MeleeAttackWorldShakeOnMissDuration = 1 -- How long the screen shake will last, in seconds
		ENT.MeleeAttackWorldShakeOnMissFrequency = 100 -- Just leave it to 100
		ENT.HasRangeAttack = true -- Should the SNPC have a range attack?
		ENT.AnimTbl_RangeAttack = {ACT_COWER} -- Range Attack Animations
		ENT.RangeAttackEntityToSpawn = "obj_dm_wormgas" -- The entity that is spawned when range attacking
		ENT.RangeDistance = 10000 -- This is how far away it can shoot
		ENT.RangeToMeleeDistance = 1000 -- How close does it have to be until it uses melee?
		ENT.RangeUseAttachmentForPos = true -- Should the projectile spawn on a attachment?
		ENT.RangeUseAttachmentForPosID = "poison" -- The attachment used on the range attack if RangeUseAttachmentForPos is set to true
		ENT.NextRangeAttackTime = 4 -- How much time until it can use a range attack?
		ENT.NextAnyAttackTime_Range = 1.5 -- How much time until it can use any attack again? | Counted in Seconds
		ENT.TimeUntilRangeAttackProjectileRelease = 1.8 -- How much time until the projectile code is ran?
		ENT.HasDeathRagdoll = false -- If set to false, it will not spawn the regular ragdoll of the SNPC
		ENT.HasDeathNotice = true -- Set to true if you want it show a message after it dies
		ENT.DeathNoticePosition = HUD_PRINTCENTER -- Were you want the message to show. Examples: HUD_PRINTCENTER, HUD_PRINTCONSOLE, HUD_PRINTTALK
		ENT.DeathNoticeWriting = "A Giant Worm Has Been Defeated!" -- Message that will appear
		ENT.HasDeathAnimation = true -- Does it play an animation when it dies?
		ENT.AnimTbl_Death = {"worm_die"} -- Death Animations
		ENT.DeathAnimationTime = 5.5 -- Time until the SNPC spawns its corpse and gets removed
		ENT.FadeCorpse = true
		ENT.FadeCorpseTime = 4 -- This is counted in seconds
		ENT.HasSoundTrack = false -- Does the SNPC have a sound track?
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_Idle = {"vj_dm_giantworm/worm_strafe0.wav","vj_dm_giantworm/worm_strafe1.wav","vj_dm_giantworm/worm_strafe2.wav","vj_dm_giantworm/worm_strafe3.wav","vj_dm_giantworm/worm_idle0.wav","vj_dm_giantworm/worm_idle1.wav","vj_dm_giantworm/worm_idle2.wav","vj_dm_giantworm/worm_idlegrowl0.wav","vj_dm_giantworm/worm_idlegrowl1.wav"}
		ENT.SoundTbl_Alert = {"vj_dm_giantworm/worm_in_quick.wav","vj_dm_giantworm/worm_idlegrowl2.wav","vj_dm_giantworm/worm_idlegrowl3.wav"}
		ENT.SoundTbl_MeleeAttack = {"vj_dm_giantworm/worm_striking0.wav","vj_dm_giantworm/worm_striking1.wav","vj_dm_giantworm/worm_striking2.wav"}
		ENT.SoundTbl_MeleeAttackMiss = {"vj_dm_giantworm/worm_whoosh0.wav","vj_dm_giantworm/worm_whoosh1.wav","vj_dm_giantworm/worm_whoosh2.wav"}
		ENT.SoundTbl_RangeAttack = {"vj_dm_giantworm/worm_strikingpoison0.wav","vj_dm_giantworm/worm_strikingpoison1.wav","vj_dm_giantworm/worm_strikingpoison2.wav"}
		ENT.SoundTbl_Pain = {"vj_dm_giantworm/worm_ouch0.wav","vj_dm_giantworm/worm_ouch1.wav","vj_dm_giantworm/worm_ouch2.wav","vj_dm_giantworm/worm_ouch3.wav"}
		ENT.SoundTbl_Death = {"vj_dm_giantworm/worm_dying.wav"}

		ENT.AlertSoundLevel = 100
		ENT.IdleSoundLevel = 100
		ENT.MeleeAttackSoundLevel = 100
		ENT.ExtraMeleeAttackSoundLevel = 100
		ENT.MeleeAttackMissSoundLevel = 100
		ENT.PainSoundLevel = 100
		ENT.DeathSoundLevel = 100
		ENT.RangeAttackSoundLevel = 100
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnInitialize()
			self:SetCollisionBounds(Vector(185, 185, 2000), Vector(-185, -185, 0))
		end
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnThink()
			if GetConVarNumber("vj_npc_noidleparticle") == 0 then
				ParticleEffectAttach("antlion_gib_02_gas",PATTACH_POINT_FOLLOW,self,2)
			end
		end
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnAlert()
			if self.VJ_IsBeingControlled == true then return end
			self:VJ_ACT_PLAYACTIVITY(VJ_PICKRANDOMTABLE({"vjseq_worm_taunt_01","vjseq_worm_taunt_02"}),true,4.5,true)
		end
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:RangeAttackCode_GetShootPos(TheProjectile)
			///local EnemyDistance = self:GetPos():Distance(self:GetEnemy():GetPos())
			//if EnemyDistance < 3500 then
				//print("close distance")
				return (self:GetEnemy():GetPos() -self:GetAttachment(self:LookupAttachment("poison")).Pos) + self:GetUp()*350
			//end
			//if EnemyDistance > 3500 then
			//	return (self:GetEnemy():GetPos() -self:GetAttachment(self:LookupAttachment("poison")).Pos) + self:GetUp()*350
			//end
		end
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomDeathAnimationCode(dmginfo,hitgroup)
			util.ScreenShake(self:GetPos(),100,200,5.5,3000)
			timer.Simple(2.5,function()
				if IsValid(self) then
					local effectdatat = EffectData()
					effectdatat:SetOrigin(self:GetPos()+Vector(0,0,0)) -- the vector of were you want the effect to spawn
					//effectdatat:SetScale( 1000 ) -- how big the particles are, can even be 0.1 or 0.6
					util.Effect("VJ_Medium_Dust1",effectdatat) -- Add as many as you want
					if self.HasSounds == true && self.HasDeathSounds == true then
					self.giantwormrocksound1 = CreateSound(self,"building_rubble5.wav") self.giantwormrocksound1:SetSoundLevel(100)
					self.giantwormrocksound1:PlayEx(1,self:VJ_DecideSoundPitch(self.DeathSoundPitch1,self.DeathSoundPitch2)) end
				end
			end)
		end
		/*-----------------------------------------------
			*** Copyright (c) 2012-2017 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/
	end

	scripted_ents.Register(ENT, ENT.ClassName)
end

do
	local ENT = {}
	ENT.ClassName = "obj_dm_wormgas"

	ENT.Type 			= "anim"
	ENT.Base 			= "obj_vj_projectile_base"
	ENT.PrintName		= "Worm Gas"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Information		= "Projectiles for my addons"
	ENT.Category		= "Projectiles"

	if (CLIENT) then
		local Name = "Worm Gas"
		local LangName = "obj_dm_wormgas"
		language.Add(LangName, Name)
		killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
		language.Add("#"..LangName, Name)
		killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end

	if SERVER then
		/*-----------------------------------------------
			*** Copyright (c) 2012-2017 by DrVrej, All rights reserved. ***
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
			*** Copyright (c) 2012-2017 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/
	end

	scripted_ents.Register(ENT, ENT.ClassName)
end