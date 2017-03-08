local ENT = {}
ENT.ClassName = "npc_vj_dmvj_spider_queen"

ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Spider"
ENT.Author 			= "DrVrej"
ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
ENT.Purpose 		= "Spider!"
ENT.Instructions 	= "Click to spawn it."
ENT.Category		= "Dark Messiah"

if (CLIENT) then
local Name = "Spider"
local LangName = "npc_vj_dmvj_spider"
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
	ENT.Model = {"models/VJ_DARKMESSIAH/spider_regular.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
	ENT.StartHealth = GetConVarNumber("vj_dm_spider_h")
	ENT.HullType = HULL_TINY
	---------------------------------------------------------------------------------------------------------------------------------------------
	ENT.VJ_NPC_Class = {"CLASS_DARK_MESSIAH"} -- NPCs with the same class with be allied to each other
	ENT.BloodColor = "Red" -- The blood type, this will determine what it should use (decal, particle, etc.)
	ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
	ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1} -- Melee Attack Animations
	ENT.MeleeAttackDistance = 45 -- How close does it have to be until it attacks?
	ENT.MeleeAttackDamageDistance = 100 -- How far does the damage go?
	ENT.TimeUntilMeleeAttackDamage = 0.8 -- This counted in seconds | This calculates the time until it hits something
	ENT.NextAnyAttackTime_Melee = 0.5 -- How much time until it can use any attack again? | Counted in Seconds
	ENT.MeleeAttackDamage = GetConVarNumber("vj_dm_spider_d_reg")
	ENT.HasRangeAttack = true -- Should the SNPC have a range attack?
	ENT.AnimTbl_RangeAttack = {ACT_RANGE_ATTACK1} -- Range Attack Animations
	ENT.RangeAttackEntityToSpawn = "obj_dm_spidergas" -- The entity that is spawned when range attacking
	ENT.RangeDistance = 800 -- This is how far away it can shoot
	ENT.RangeToMeleeDistance = 300 -- How close does it have to be until it uses melee?
	ENT.TimeUntilRangeAttackProjectileRelease = 0.7 -- How much time until the projectile code is ran?
	ENT.NextRangeAttackTime = 4 -- How much time until it can use a range attack?
	ENT.NextAnyAttackTime_Range = 0.6 -- How much time until it can use any attack again? | Counted in Seconds
	ENT.EntitiesToNoCollide = {"npc_vj_dmvj_spider_queen"}
	ENT.HasDeathAnimation = true -- Does it play an animation when it dies?
	ENT.AnimTbl_Death = {ACT_DIESIMPLE} -- Death Animations
	ENT.DeathAnimationTime = 1.5 -- Time until the SNPC spawns its corpse and gets removed
	ENT.UsesDamageForceOnDeath = false -- Disables the damage force on death | Useful for SNPCs with Death Animations
	ENT.HasExtraMeleeAttackSounds = true -- Set to true to use the extra melee attack sounds
	ENT.Immune_AcidPoisonRadiation = true -- Immune to Acid, Poison and Radiation
		-- ====== Flinching Code ====== --
	ENT.CanFlinch = 1 -- 0 = Don't flinch | 1 = Flinch at any damage | 2 = Flinch only from certain damages
	ENT.AnimTbl_Flinch = {ACT_BIG_FLINCH} -- If it uses normal based animation, use this
		-- ====== Sound File Paths ====== --
	-- Leave blank if you don't want any sounds to play
	ENT.SoundTbl_Idle = {"vj_dm_spider/spider_misc0.wav","vj_dm_spider/spider_misc2.wav","vj_dm_spider/spider_misc3.wav","vj_dm_spider/spider_hail0.wav","vj_dm_spider/spider_hail1.wav","vj_dm_spider/spider_hail2.wav"}
	ENT.SoundTbl_Alert = {"vj_dm_spider/spider_misc1.wav","vj_dm_spider/spider_threat0.wav","vj_dm_spider/spider_guardmode0.wav","vj_dm_spider/spider_guardmode1.wav","vj_dm_spider/spider_guardmode2.wav"}
	ENT.SoundTbl_MeleeAttack = {"vj_dm_spider/spider_striking0.wav","vj_dm_spider/spider_striking1.wav","vj_dm_spider/spider_striking2.wav","vj_dm_spider/spider_striking3.wav"}
	ENT.SoundTbl_MeleeAttackMiss = {"npc/zombie/claw_miss1.wav","npc/zombie/claw_miss2.wav"}
	ENT.SoundTbl_RangeAttack = {"vj_dm_spider/spider_threat3.wav","vj_dm_spider/spider_threat4.wav"}
	ENT.SoundTbl_Pain = {"vj_dm_spider/spider_ouch_strong0.wav","vj_dm_spider/spider_ouch_strong1.wav","vj_dm_spider/spider_ouch_strong2.wav","vj_dm_spider/spider_ouch0.wav","vj_dm_spider/spider_ouch1.wav","vj_dm_spider/spider_ouch2.wav"}
	ENT.SoundTbl_Death = {"vj_dm_spider/spider_dying0.wav","vj_dm_spider/spider_dying1.wav","vj_dm_spider/spider_dying2.wav"}

	-- Custom
	ENT.Spider_AlwaysPlayDigOutAnim = false
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnInitialize()
		self:SetCollisionBounds(Vector(30, 30, 25), Vector(-30, -30, 0))
		if GetConVarNumber("ai_disabled") == 0 && (math.random(1,2) == 1 or self.Spider_AlwaysPlayDigOutAnim == true) then
			self:SetNoDraw(true)
			timer.Simple(0.05,function() if IsValid(self) then self:VJ_ACT_PLAYACTIVITY(ACT_ARM,true,2,true) end end)
			timer.Simple(0.5,function() if IsValid(self) then self:SetNoDraw(false) end end)
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:MultipleMeleeAttacks()
		local randattack = math.random(1,3)
		if randattack == 1 then
			self.AnimTbl_MeleeAttack = {"vjseq_Attack_1","vjseq_Attack_4"}
			self.MeleeAttackAnimationDecreaseLengthAmount = 0.2
			self.TimeUntilMeleeAttackDamage = 0.8
			self.NextAnyAttackTime_Melee = 0.9
			self.MeleeAttackExtraTimers = {}
			self.MeleeAttackDamage = GetConVarNumber("vj_dm_spider_d_reg")
		elseif randattack == 2 then
			self.AnimTbl_MeleeAttack = {"vjseq_Attack_2"}
			self.MeleeAttackAnimationDecreaseLengthAmount = 0.2
			self.TimeUntilMeleeAttackDamage = 1.2
			self.NextAnyAttackTime_Melee = 0.8
			self.MeleeAttackExtraTimers = {}
			self.MeleeAttackDamage = GetConVarNumber("vj_dm_spider_d_slow")
		elseif randattack == 3 then
			self.AnimTbl_MeleeAttack = {"vjseq_Attack_3"}
			self.MeleeAttackAnimationDecreaseLengthAmount = 0
			self.TimeUntilMeleeAttackDamage = 0.9
			self.NextAnyAttackTime_Melee = 2.2
			self.MeleeAttackExtraTimers = {1.7}
			self.MeleeAttackDamage = GetConVarNumber("vj_dm_spider_d_slowdual")
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:CustomOnKilled(dmginfo,hitgroup)
		self:SetLocalPos(Vector(self:GetPos().x,self:GetPos().y,self:GetPos().z +30))
	end
	---------------------------------------------------------------------------------------------------------------------------------------------
	function ENT:RangeAttackCode_GetShootPos(TheProjectile)
		return (self:GetEnemy():GetPos() - self:LocalToWorld(Vector(0,0,math.random(20,20))))*2 + self:GetUp()*220
	end
	/*-----------------------------------------------
		*** Copyright (c) 2012-2017 by DrVrej, All rights reserved. ***
		No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
		without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
	-----------------------------------------------*/
end

scripted_ents.Register(ENT, ENT.ClassName)