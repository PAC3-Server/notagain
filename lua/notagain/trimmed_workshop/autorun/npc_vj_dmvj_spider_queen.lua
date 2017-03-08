local ENT = {}
ENT.ClassName = "npc_vj_dmvj_spider_queen"

ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Spider Queen"
ENT.Author 			= "DrVrej"
ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
ENT.Purpose 		= "She's your mother!"
ENT.Instructions 	= "Click to spawn it."
ENT.Category		= "Dark Messiah"

if (CLIENT) then
local Name = "Spider Queen"
local LangName = "npc_vj_dmvj_spider_queen"
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
	ENT.Model = {"models/VJ_DARKMESSIAH/spider_queen.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
	ENT.StartHealth = GetConVarNumber("vj_dm_spiderqueen_h")
	ENT.HullType = HULL_LARGE
	ENT.VJ_IsHugeMonster = true -- Is this a huge monster?
	---------------------------------------------------------------------------------------------------------------------------------------------
	ENT.VJ_NPC_Class = {"CLASS_DARK_MESSIAH"} -- NPCs with the same class with be allied to each other
	ENT.BloodColor = "Red" -- The blood type, this will determine what it should use (decal, particle, etc.)
	ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
	ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1} -- First animation of the Melee Attack
	ENT.MeleeAttackAnimationDecreaseLengthAmount = 0.2 -- This will decrease the time until starts chasing again. Use it to fix animation pauses until it chases the enemy.
	ENT.MeleeAttackAnimationFaceEnemy = false -- Should it face the enemy while playing the melee attack animation?
	ENT.MeleeAttackDistance = 85 -- How close does it have to be until it attacks?
	ENT.MeleeAttackDamageDistance = 360 -- How far does the damage go?
	ENT.TimeUntilMeleeAttackDamage = 1.4 -- This counted in seconds | This calculates the time until it hits something
	ENT.NextAnyAttackTime_Melee = 2.4 -- How much time until it can use any attack again? | Counted in Seconds
	ENT.MeleeAttackDamage = GetConVarNumber("vj_dm_spiderqueen_d_single")
	ENT.Immune_AcidPoisonRadiation = true -- Makes the SNPC not get damage from Acid, posion, radiation
	ENT.Immune_Physics = true -- If set to true, the SNPC won't take damage from props
	ENT.HasRangeAttack = true -- Should the SNPC have a range attack?
	ENT.AnimTbl_RangeAttack = {"vjseq_attack_poison"} -- Range Attack Animations
	ENT.RangeAttackAnimationDecreaseLengthAmount = 0 -- This will decrease the time until starts chasing again. Use it to fix animation pauses until it chases the enemy.
	ENT.RangeAttackEntityToSpawn = "obj_dm_spidergas" -- The entity that is spawned when range attacking
	ENT.RangeDistance = 9000 -- This is how far away it can shoot
	ENT.RangeToMeleeDistance = 800 -- How close does it have to be until it uses melee?
	ENT.TimeUntilRangeAttackProjectileRelease = 1.3 -- How much time until the projectile code is ran?
	ENT.NextRangeAttackTime = 4 -- How much time until it can use a range attack?
	ENT.NextAnyAttackTime_Range = 1.4 -- How much time until it can use any attack again? | Counted in Seconds
	ENT.MeleeAttackWorldShakeOnMiss = true -- Should it shake the world when it misses during melee attack?
	ENT.MeleeAttackWorldShakeOnMissAmplitude = 16 -- How much the screen will shake | From 1 to 16, 1 = really low 16 = really high
	ENT.MeleeAttackWorldShakeOnMissRadius = 2000 -- How far the screen shake goes, in world units
	ENT.MeleeAttackWorldShakeOnMissDuration = 1 -- How long the screen shake will last, in seconds
	ENT.MeleeAttackWorldShakeOnMissFrequency = 100 -- Just leave it to 100
	ENT.HasSoundTrack = false -- Does the SNPC have a sound track?
	ENT.EntitiesToNoCollide = {"npc_vj_dmvj_spider"}
	ENT.HasDeathNotice = false -- Set to true if you want it show a message after it dies
	ENT.HasMeleeAttackKnockBack = true -- If true, it will cause a knockback to its enemy
	ENT.MeleeAttackKnockBack_Forward1 = 700 -- How far it will push you forward | First in math.random
	ENT.MeleeAttackKnockBack_Forward2 = 730 -- How far it will push you forward | Second in math.random
	ENT.MeleeAttackKnockBack_Up1 = 500 -- How far it will push you up | First in math.random
	ENT.MeleeAttackKnockBack_Up2 = 530 -- How far it will push you up | Second in math.random
	ENT.HasDeathAnimation = true -- Does it play an animation when it dies?
	ENT.AnimTbl_Death = {ACT_DIESIMPLE} -- Death Animations
	ENT.DeathAnimationTime = 4 -- Time until the SNPC spawns its corpse and gets removed
	ENT.UsesDamageForceOnDeath = false -- Disables the damage force on death | Useful for SNPCs with Death Animations
	ENT.HasWorldShakeOnMove = true -- Should the world shake when it's moving?
	ENT.NextWorldShakeOnRun = 0.4 -- How much time until the world shakes while it's running
	ENT.NextWorldShakeOnWalk = 1 -- How much time until the world shakes while it's walking
	ENT.WorldShakeOnMoveAmplitude = 10 -- How much the screen will shake | From 1 to 16, 1 = really low 16 = really high
	ENT.WorldShakeOnMoveRadius = 1000 -- How far the screen shake goes, in world units
	ENT.WorldShakeOnMoveDuration = 0.4 -- How long the screen shake will last, in seconds
	ENT.WorldShakeOnMoveFrequency = 100 -- Just leave it to 100
	ENT.DisableWorldShakeOnMoveWhileWalking = true -- It will not shake the world when it's walking
	ENT.FootStepTimeRun = 0.3 -- Next foot step sound when it is running
	ENT.FootStepTimeWalk = 0.5 -- Next foot step sound when it is walking
	ENT.DisableFootStepOnWalk = true -- It will not play the footstep sound when walking
	ENT.HasExtraMeleeAttackSounds = true -- Set to true to use the extra melee attack sounds
		-- ====== Flinching Code ====== --
	ENT.CanFlinch = 2 -- 0 = Don't flinch | 1 = Flinch at any damage | 2 = Flinch only from certain damages
	ENT.FlinchChance = 7 -- Chance of it flinching from 1 to x | 1 will make it always flinch
	ENT.AnimTbl_Flinch = {ACT_BIG_FLINCH} -- If it uses normal based animation, use this
		-- ====== Sound File Paths ====== --
	-- Leave blank if you don't want any sounds to play
	ENT.SoundTbl_FootStep = {"vj_dm_spidermonster/hit1.wav","vj_dm_spidermonster/hit2.wav","vj_dm_spidermonster/hit3.wav"}
	ENT.SoundTbl_Idle = {"vj_dm_spidermonster/spidermonster_misc0.wav","vj_dm_spidermonster/spidermonster_misc1.wav","vj_dm_spidermonster/spidermonster_misc2.wav"}
	ENT.SoundTbl_Alert = {"vj_dm_spidermonster/spidermonster_entrance_end.wav","vj_dm_spidermonster/spidermonster_threat0.wav","vj_dm_spidermonster/spidermonster_threat1.wav","vj_dm_spidermonster/spidermonster_threat2.wav"}
	ENT.SoundTbl_MeleeAttack = {"vj_dm_spidermonster/spidermonster_striking0.wav","vj_dm_spidermonster/spidermonster_striking1.wav","vj_dm_spidermonster/spidermonster_striking2.wav"}
	ENT.SoundTbl_MeleeAttackMiss = {"vj_dm_spidermonster/spidermonster_foothit0.wav","vj_dm_spidermonster/spidermonster_foothit1.wav","vj_dm_spidermonster/spidermonster_foothit2.wav","vj_dm_spidermonster/spidermonster_foothit3.wav"}
	ENT.SoundTbl_RangeAttack = {"vj_dm_spidermonster/spidermonster_hail0.wav","vj_dm_spidermonster/spidermonster_hail1.wav","vj_dm_spidermonster/spidermonster_hail2.wav"}
	ENT.SoundTbl_Pain = {"vj_dm_spidermonster/spidermonster_ouch_strong0.wav","vj_dm_spidermonster/spidermonster_ouch_strong1.wav","vj_dm_spidermonster/spidermonster_ouch_strong2.wav","vj_dm_spidermonster/spidermonster_ouch0.wav","vj_dm_spidermonster/spidermonster_ouch1.wav","vj_dm_spidermonster/spidermonster_ouch2.wav"}
	ENT.SoundTbl_Death = {"vj_dm_spidermonster/spidermonster_dying0.wav","vj_dm_spidermonster/spidermonster_dying1.wav","vj_dm_spidermonster/spidermonster_dying2.wav"}

	ENT.FootStepSoundLevel = 100
	ENT.AlertSoundLevel = 100
	ENT.IdleSoundLevel = 100
	ENT.MeleeAttackSoundLevel = 100
	ENT.RangeAttackSoundLevel = 100
	ENT.MeleeAttackMissSoundLevel = 150
	ENT.BeforeLeapAttackSoundLevel = 100
	ENT.PainSoundLevel = 100
	ENT.DeathSoundLevel = 100

	-- Custom
	//ENT.NextBabySpawn = 40
	ENT.SpiderQueen_PoisonAttack = false
	ENT.SpiderQueen_AllowedToSpawnSpiders = true
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnInitialize()
		//self:SetCollisionBounds(Vector(100, 130, 210), Vector(-100, -130, 0))
		self:SetCollisionBounds(Vector(190, 190, 210), -Vector(190, 190, 0))
		if GetConVarNumber("vj_dm_nobabyspawn") == 0 then self.SpiderQueen_AllowedToSpawnSpiders = false end
		self.SpiderQueen_NextBirthT = 0
		self.SpiderQueen_NextBirthTime = GetConVarNumber("vj_dm_nextbaby")
		/*local limit = GetConVarNumber("vj_dm_babyspawnlimit")
		local func = math.ceil
		if limit % 2 == 0 then func = math.ceil else func = math.floor end
		self.SpiderQueen_SpiderLimit = func((limit/3))*3*/
		self.SpiderQueen_SpiderLimit = VJ_RoundToMultiple(GetConVarNumber("vj_dm_babyspawnlimit"),3)
		self.SpiderQueen_BabySpidersTbl = {}
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	/*function ENT:CustomOnThink()
		if GetConVarNumber("vj_npc_noidleparticle") == 0 then
			ParticleEffectAttach("antlion_gib_02_gas",PATTACH_POINT_FOLLOW,self,2)
		end
	end*/
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnThink_AIEnabled()
		if self.SpiderQueen_AllowedToSpawnSpiders == true && self:GetEnemy() != nil && CurTime() > self.SpiderQueen_NextBirthT then
			babytbl = self.SpiderQueen_BabySpidersTbl
			for k,v in ipairs(babytbl) do
				if !IsValid(v) then table.remove(babytbl,k) continue end
			end
			if (#babytbl % 3 == 0) && #babytbl < self.SpiderQueen_SpiderLimit then
				util.ScreenShake(self:GetPos(),100,200,5,3000)
				VJ_EmitSound(self,{"vj_dm_spider/spider_victory0.wav","vj_dm_spider/spider_victory1.wav"},100,math.random(80,100))
				local effectdata = EffectData()
				effectdata:SetOrigin(self:GetPos())
				effectdata:SetScale(1000)
				util.Effect("ThumperDust",effectdata)

				-- Baby 1
				local BabySpider1 = ents.Create("npc_vj_dmvj_spider")
				BabySpider1:SetPos(self:LocalToWorld(Vector(0,120,0)))
				BabySpider1:SetAngles(self:GetAngles())
				BabySpider1.Spider_AlwaysPlayDigOutAnim = true
				BabySpider1:Spawn()
				BabySpider1:Activate()
				BabySpider1:SetOwner(self)
				table.insert(self.SpiderQueen_BabySpidersTbl,BabySpider1)

				-- Baby 2
				local BabySpider2 = ents.Create("npc_vj_dmvj_spider")
				BabySpider2:SetPos(self:LocalToWorld(Vector(0,-120,0)))
				BabySpider2:SetAngles(self:GetAngles())
				BabySpider2.Spider_AlwaysPlayDigOutAnim = true
				BabySpider2:Spawn()
				BabySpider2:Activate()
				BabySpider2:SetOwner(self)
				table.insert(self.SpiderQueen_BabySpidersTbl,BabySpider2)

				-- Baby 3
				local BabySpider3 = ents.Create("npc_vj_dmvj_spider")
				BabySpider3:SetPos(self:LocalToWorld(Vector(0,0,0)))
				BabySpider3:SetAngles(self:GetAngles())
				BabySpider3.Spider_AlwaysPlayDigOutAnim = true
				BabySpider3:Spawn()
				BabySpider3:Activate()
				BabySpider3:SetOwner(self)
				table.insert(self.SpiderQueen_BabySpidersTbl,BabySpider3)
				self.SpiderQueen_NextBirthT = CurTime() + self.SpiderQueen_NextBirthTime
			end
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnAlert()
		if self.VJ_IsBeingControlled == true then return end
		//self:VJ_ACT_PLAYACTIVITY(ACT_IDLE_ANGRY,true,2.8,true)
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:MultipleMeleeAttacks()
		local randattack = math.random(1,5)
		if randattack == 1 then
			self.AnimTbl_MeleeAttack = {"vjseq_Attack_3"}
			self.MeleeAttackDistance = 85
			self.MeleeAttackDamageDistance = 360
			self.TimeUntilMeleeAttackDamage = 1.82
			self.NextAnyAttackTime_Melee = 2.25
			self.MeleeAttackExtraTimers = {}
			self.MeleeAttackDamage = GetConVarNumber("vj_dm_spiderqueen_d_single")
			self.MeleeAttackDamageType = DMG_SLASH
			self.SoundTbl_MeleeAttackMiss = {"vj_dm_spidermonster/spidermonster_foothit0.wav","vj_dm_spidermonster/spidermonster_foothit1.wav","vj_dm_spidermonster/spidermonster_foothit2.wav","vj_dm_spidermonster/spidermonster_foothit3.wav"}
			self.SpiderQueen_PoisonAttack = false
		elseif randattack == 2 then
			self.AnimTbl_MeleeAttack = {"vjseq_Attack_1"}
			self.MeleeAttackDistance = 85
			self.MeleeAttackDamageDistance = 360
			self.TimeUntilMeleeAttackDamage = 1.65
			self.NextAnyAttackTime_Melee = 2.3
			self.MeleeAttackExtraTimers = {}
			self.MeleeAttackDamage = GetConVarNumber("vj_dm_spiderqueen_d_single")
			self.MeleeAttackDamageType = DMG_SLASH
			self.SoundTbl_MeleeAttackMiss = {"vj_dm_spidermonster/spidermonster_foothit0.wav","vj_dm_spidermonster/spidermonster_foothit1.wav","vj_dm_spidermonster/spidermonster_foothit2.wav","vj_dm_spidermonster/spidermonster_foothit3.wav"}
			self.SpiderQueen_PoisonAttack = false
		elseif randattack == 3 then
			self.AnimTbl_MeleeAttack = {"vjseq_Attack_2","vjseq_Attack_4"}
			self.MeleeAttackDistance = 85
			self.MeleeAttackDamageDistance = 360
			self.TimeUntilMeleeAttackDamage = 1.5
			self.NextAnyAttackTime_Melee = 2.3
			self.MeleeAttackExtraTimers = {}
			self.MeleeAttackDamage = GetConVarNumber("vj_dm_spiderqueen_d_single")
			self.MeleeAttackDamageType = DMG_SLASH
			self.SoundTbl_MeleeAttackMiss = {"vj_dm_spidermonster/spidermonster_foothit0.wav","vj_dm_spidermonster/spidermonster_foothit1.wav","vj_dm_spidermonster/spidermonster_foothit2.wav","vj_dm_spidermonster/spidermonster_foothit3.wav"}
			self.SpiderQueen_PoisonAttack = false
		elseif randattack == 4 then
			self.AnimTbl_MeleeAttack = {"vjseq_Attack_dual"}
			self.MeleeAttackDistance = 85
			self.MeleeAttackDamageDistance = 360
			self.TimeUntilMeleeAttackDamage = 1
			self.NextAnyAttackTime_Melee = 2.4
			self.MeleeAttackExtraTimers = {1.5}
			self.MeleeAttackDamage = GetConVarNumber("vj_dm_spiderqueen_d_dual")
			self.MeleeAttackDamageType = DMG_SLASH
			self.SoundTbl_MeleeAttackMiss = {"vj_dm_spidermonster/spidermonster_foothit0.wav","vj_dm_spidermonster/spidermonster_foothit1.wav","vj_dm_spidermonster/spidermonster_foothit2.wav","vj_dm_spidermonster/spidermonster_foothit3.wav"}
			self.SpiderQueen_PoisonAttack = false
		elseif randattack == 5 then
			self.AnimTbl_MeleeAttack = {"vjseq_Attack_belly"}
			self.MeleeAttackDistance = 85
			self.MeleeAttackDamageDistance = 360
			self.TimeUntilMeleeAttackDamage = 1.2
			self.NextAnyAttackTime_Melee = 2.2
			self.MeleeAttackExtraTimers = {}
			self.MeleeAttackDamage = GetConVarNumber("vj_dm_spiderqueen_d_poison")
			self.MeleeAttackDamageType = DMG_POISON
			self.SoundTbl_MeleeAttackMiss = {"vj_dm_spidermonster/spidermonster_whoosh0.wav","vj_dm_spidermonster/spidermonster_whoosh1.wav","vj_dm_spidermonster/spidermonster_whoosh2.wav","vj_dm_spidermonster/spidermonster_whoosh3.wav","vj_dm_spidermonster/spidermonster_whoosh4.wav"}
			self.SpiderQueen_PoisonAttack = true
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnMeleeAttack_Miss()
		if self:IsOnGround() && self.SpiderQueen_PoisonAttack == false then
			for dust = 1,3 do
				local effectdata = EffectData()
				effectdata:SetOrigin(self:GetPos()+self:GetForward()*200)
				effectdata:SetScale(1000)
				util.Effect("ThumperDust",effectdata)
			end
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:RangeAttackCode_GetShootPos(TheProjectile)
		return (self:GetEnemy():GetPos()-self:LocalToWorld(Vector(0,0,math.random(20,20))))*2 +self:GetUp()*250 +self:GetForward()*900
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomDeathAnimationCode(dmginfo,hitgroup)
		util.ScreenShake(self:GetPos(),100,200,5,3000)
	end
	/*-----------------------------------------------
		*** Copyright (c) 2012-2017 by DrVrej, All rights reserved. ***
		No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
		without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
	-----------------------------------------------*/
end

scripted_ents.Register(ENT, ENT.ClassName)