local AddConvars = {}

AddConvars["vj_hellion_h"] = 50
AddConvars["vj_hellion_d"] = 20
AddConvars["vj_hellion_leap"] = 25

AddConvars["vj_hellionguard_h"] = 1200
AddConvars["vj_hellionguard_d"] = 95

AddConvars["vj_thunderlionguard_h"] = 2000
AddConvars["vj_thunderlionguard_d"] = 80

AddConvars["vj_thunderlion_h"] = 80
AddConvars["vj_thunderlion_d"] = 25

AddConvars["vj_frostlion_h"] = 40
AddConvars["vj_frostlion_d"] = 15

AddConvars["vj_frostlionguard_h"] = 800
AddConvars["vj_frostlionguard_d"] = 65

for k, v in pairs(AddConvars) do
	if !ConVarExists( k ) then CreateConVar( k, v, {FCVAR_NONE} ) end
end

do
	local ENT = {}
	ENT.ClassName = "npc_vj_frostlion"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Frostlion"
	ENT.Author 			= "Norpa"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.Category		= "Antlions"

	if (CLIENT) then
	local Name = "Frostlion"
	local LangName = "npc_vj_frostlion"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		/*-----------------------------------------------
			*** Copyright (c) 2012-2016 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/
		ENT.Model = "models/AntLio2.mdl"
		ENT.StartHealth = GetConVarNumber("vj_frostlion_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE

		---------------------------------------------------------------------------------------------------------------------------------------------
		ENT.VJ_NPC_Class = {"CLASS_ANTLION"} -- NPCs with the same class will be friendly to each other | Combine: CLASS_COMBINE, Zombie: CLASS_ZOMBIE, Antlions = CLASS_ANTLION
		ENT.CustomBlood_Particle = {"striderbuster_smoke"} -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = {"YellowBlood"} -- Leave blank for none | Commonly used: Red = Blood, Yellow Blood = YellowBlood
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack =  {ACT_MELEE_ATTACK1} -- Melee Attack Animations
		ENT.MeleeAttackDistance = 45 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 120 -- How far does the damage go?
		ENT.TimeUntilMeleeAttackDamage = 0.8 -- This counted in seconds | This calculates the time until it hits something
		ENT.NextAnyAttackTime_Melee = 0.8 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_frostlion_d")
		ENT.MeleeAttackDamageType = DMG_PLASMA -- Type of Damage
		ENT.NextAnyAttackTime_Range = 0.6 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.Immune_CombineBall = false
		ENT.HasDeathAnimation = false -- Does it play an animation when it dies?
		ENT.HasExtraMeleeAttackSounds = true-- Set to true to use the extra melee attack sounds
		ENT.SlowPlayerOnMeleeAttack = true -- If true, then the player will slow down
		ENT.SlowPlayerOnMeleeAttack_WalkSpeed = 50 -- Walking Speed when Slow Player is on
		ENT.SlowPlayerOnMeleeAttack_RunSpeed = 70 -- Running Speed when Slow Player is on
		ENT.SlowPlayerOnMeleeAttackTime = 10
		ENT.FootStepTimeRun = 0.2
		ENT.FootStepTimeWalk = 0.4
		ENT.HasLeapAttack = true
		ENT.AnimTbl_LeapAttack = {ACT_JUMP}
		ENT.StopLeapAttackAfterFirstHit = true
		ENT.LeapAttackAnimationDelay = 0
		ENT.LeapDistance = 8000 -- The distance of the leap, for example if it is set to 500, when the SNPC is 500 Unit away, it will jump
		ENT.LeapToMeleeDistance = 10 -- How close does it have to be until it uses melee?
		ENT.TimeUntilLeapAttackDamage = 1 -- How much time until it runs the leap damage code?
		ENT.NextLeapAttackTime = 5 -- How much time until it can use a leap attack?
		ENT.NextAnyAttackTime_Leap = 0
		ENT.LeapAttackAnimationDecreaseLengthAmount = 0
		ENT.LeapAttackDamageDistance = 100 -- How far does the damage go?
		ENT.LeapAttackDamageType = DMG_PLASMA
		ENT.LeapAttackDamage = GetConVarNumber("vj_hellion_leap")
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 12 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"npc/antlion/foot1.wav","npc/antlion/foot2.wav","npc/antlion/foot3.wav","npc/antlion/foot4.wav"}
		ENT.SoundTbl_Idle = {"npc/antlion/idle1.wav","npc/antlion/idle2.wav","npc/antlion/idle3.wav","npc/antlion/idle4.wav","npc/antlion/idle5.wav"}
		ENT.SoundTbl_Alert = {"npc/antlion/attack_double1.wav","npc/antlion/attack_double2.wav","npc/antlion/attack_double3.wav"}
		ENT.SoundTbl_MeleeAttackMiss = {""}
		ENT.SoundTbl_MeleeAttack = {"npc/antlion/attack_double1.wav"}
		ENT.SoundTbl_Pain = {"npc/antlion/pain1.wav"}
		ENT.SoundTbl_Death = {"npc/antlion/pain1.wav","npc/antlion/pain2.wav"}
		ENT.SoundTbl_LeapAttack = {"npc/antlion/fly.wav"}
		ENT.SoundTbl_Impact = {"npc/antlion/shell_impact1.wav","npc/antlion/shell_impact2.wav","npc/antlion/shell_impact3.wav","npc/antlion/shell_impact4.wav"}

		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnInitialize()
		self:SetMaterial("materials/models/AntLio2/antlionhigh_sheet")
		   local randomstartskin = math.random(1,4)
			if randomstartskin == 1 then self:SetSkin(0) else
			if randomstartskin == 2 then self:SetSkin(1) end
			if randomstartskin == 3 then self:SetSkin(2) end
		    if randomstartskin == 0 then self:SetSkin(3) end
			end
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
	ENT.ClassName = "npc_vj_frostlionguard"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Frostlion Guard"
	ENT.Author 			= "Norpa"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click to spawn it."
	ENT.Category		= "Antlions"

	if (CLIENT) then
	local Name = "Frostlion Guard"
	local LangName = "npc_vj_frostlionguard"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		/*-----------------------------------------------
			*** Copyright (c) 2012-2016 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/
		ENT.Model = {"models/mallion_guard.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
		ENT.StartHealth = GetConVarNumber("vj_frostlionguard_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------
		ENT.VJ_NPC_Class = {"CLASS_ANTLION"} -- NPCs with the same class will be friendly to each other | Combine: CLASS_COMBINE, Zombie: CLASS_ZOMBIE, Antlions = CLASS_ANTLION
		ENT.CustomBlood_Particle = {"striderbuster_smoke"} -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = {"YellowBlood"} -- Leave blank for none | Commonly used: Red = Blood, Yellow Blood = YellowBlood
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack =  {ACT_MELEE_ATTACK1} -- Melee Attack Animations
		ENT.MeleeAttackDistance = 65 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 150 -- How far does the damage go?
		ENT.TimeUntilMeleeAttackDamage = 0.8 -- This counted in seconds | This calculates the time until it hits something
		ENT.NextAnyAttackTime_Melee = 1.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_frostlionguard_d")
		ENT.MeleeAttackDamageType = DMG_PLASMA -- Type of Damage
		ENT.HasRangeAttack = true -- Should the SNPC have a range attack?
		ENT.AnimTbl_RangeAttack = {ACT_RANGE_ATTACK1} -- Range Attack Animations
		ENT.RangeAttackEntityToSpawn = "obj_frostlion_iceball" -- The entity that is spawned when range attacking
		ENT.RangeDistance = 1500 -- This is how far away it can shoot
		ENT.RangeToMeleeDistance = 500 -- How close does it have to be until it uses melee?
		ENT.TimeUntilRangeAttackProjectileRelease = 0.7 -- How much time until the projectile code is ran?
		ENT.NextRangeAttackTime = 4 -- How much time until it can use a range attack?
		ENT.NextAnyAttackTime_Range = 0.6 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.AllowIgnition = false
		ENT.Immune_CombineBall = true
		ENT.HasDeathAnimation = true -- Does it play an animation when it dies?
		ENT.AnimTbl_Death = {ACT_DIESIMPLE} -- Death Animations
		ENT.DeathAnimationTime = 3.5 -- Time until the SNPC spawns its corpse and gets removed
		ENT.UsesDamageForceOnDeath = false -- Disables the damage force on death | Useful for SNPCs with Death Animations
		ENT.HasExtraMeleeAttackSounds = true-- Set to true to use the extra melee attack sounds
		ENT.HasMeleeAttackKnockBack = true -- If true, it will cause a knockback to its enemy
		ENT.MeleeAttackKnockBack_Forward1 = 350 -- How far it will push you forward | First in math.random
		ENT.MeleeAttackKnockBack_Forward2 = 350 -- How far it will push you forward | Second in math.random
		ENT.MeleeAttackKnockBack_Up1 = 350 -- How far it will push you up | First in math.random
		ENT.MeleeAttackKnockBack_Up2 = 360
		ENT.FootStepTimeRun = 0.3
		ENT.FootStepTimeWalk = 0.5
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 16 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_BIG_FLINCH} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS

			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_Idle = {"npc/antlion_guard/growl_idle.wav"}
		ENT.SoundTbl_Alert = {"npc/antlion_guard/angry1.wav","npc/antlion_guard/angry2.wav","npc/antlion_guard/angry3.wav"}
		ENT.SoundTbl_MeleeAttack = {"npc/antlion_guard/shove1.wav"}
		ENT.SoundTbl_MeleeAttackMiss = {""}
		ENT.SoundTbl_RangeAttack = {"npc/antlion_guard/angry1.wav"}
		ENT.SoundTbl_Pain = {""}
		ENT.SoundTbl_Death = {"npc/antlion_guard/antlion_guard_die1.wav","npc/antlion_guard/antlion_guard_die2.wav"}
		ENT.SoundTbl_FootStep = {"npc/antlion_guard/foot_heavy1.wav","npc/antlion_guard/foot_heavy2.wav"}

		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnInitialize()

		ParticleEffectAttach("striderbuster_smoke", PATTACH_POINT_FOLLOW, self, 1)
		ParticleEffectAttach("striderbuster_smoke", PATTACH_POINT_FOLLOW, self, 2)
		ParticleEffectAttach("striderbuster_smoke", PATTACH_POINT_FOLLOW, self, 3)
		ParticleEffectAttach("striderbuster_smoke", PATTACH_POINT_FOLLOW, self, 4)
		end

		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:RangeAttackCode_GetShootPos(TheProjectile)
			return (self:GetEnemy():GetPos() - self:LocalToWorld(Vector(0,0,math.random(20,20))))*2 + self:GetUp()*220
		end

		function ENT:MultipleMeleeAttacks()
			local attack = 1
			if attack == 1 then
				self.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
				self.MeleeAttackDistance = 70
				self.MeleeAttackDamageDistance = 210
				self.TimeUntilMeleeAttackDamage = 0.8
				self.NextAnyAttackTime_Melee = 0.8
				self.MeleeAttackDamage = GetConVarNumber("vj_frostlionguard_d")
				self.MeleeAttackDamageType = DMG_PLASMA
				self.MeleeAttackKnockBack_Forward1 = 550
				self.MeleeAttackKnockBack_Forward2 = 550
				self.MeleeAttackKnockBack_Up1 = 280
				self.MeleeAttackKnockBack_Up2 = 280
				self.MeleeAttackWorldShakeOnMiss = false
				self.SoundTbl_MeleeAttack = {"npc/antlion_guard/shove1.wav"}

				end
				end

				function ENT:CustomOnTakeDamage_BeforeGetDamage(dmginfo,hitgroup)
			local panis = dmginfo:GetDamageType()
			if (panis == DMG_BUCKSHOT or panis == DMG_BULLET or panis == DMG_GENERIC or panis == DMG_CLUB) && dmginfo:GetDamage() >= 5  && dmginfo:GetAttacker().IsHugeMonster != true then
			dmginfo:ScaleDamage(0.1)
			dmginfo:SetDamage(dmginfo:GetDamage() /1)
			end



			local panis = dmginfo:GetDamageType()
			if (panis == DMG_BUCKSHOT or panis == DMG_BULLET or panis == DMG_GENERIC or panis == DMG_CLUB) && dmginfo:GetDamage() >= 4  && dmginfo:GetAttacker().IsHugeMonster != true then
			dmginfo:ScaleDamage(0.1)
			dmginfo:SetDamage(dmginfo:GetDamage() /1)
			end


			local panis = dmginfo:GetDamageType()
			if (panis == DMG_BUCKSHOT or panis == DMG_BULLET or panis == DMG_GENERIC or panis == DMG_CLUB) && dmginfo:GetDamage() >= 40 && dmginfo:GetAttacker().IsHugeMonster != true then
			dmginfo:ScaleDamage(0.1)
			dmginfo:SetDamage(dmginfo:GetDamage() /1)
			end
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
	ENT.ClassName = "npc_vj_hellion"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Hellion"
	ENT.Author 			= "Norpa"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.Category		= "Antlions"

	if (CLIENT) then
	local Name = "Hellion"
	local LangName = "npc_vj_hellion"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		/*-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/
		ENT.Model = "models/AntLio1.mdl"
		ENT.StartHealth = GetConVarNumber("vj_hellion_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE

		---------------------------------------------------------------------------------------------------------------------------------------------
		ENT.VJ_NPC_Class = {"CLASS_ANTLION"} -- NPCs with the same class will be friendly to each other | Combine: CLASS_COMBINE, Zombie: CLASS_ZOMBIE, Antlions = CLASS_ANTLION
		ENT.CustomBlood_Particle = {"blood_advisor_puncture_withdraw"} -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = {"YellowBlood"} -- Leave blank for none | Commonly used: Red = Blood, Yellow Blood = YellowBlood
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack =  {ACT_MELEE_ATTACK1} -- Melee Attack Animations
		ENT.MeleeAttackDistance = 45 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 120 -- How far does the damage go?
		ENT.TimeUntilMeleeAttackDamage = 0.8 -- This counted in seconds | This calculates the time until it hits something
		ENT.NextAnyAttackTime_Melee = 0.8 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_hellion_d")
		ENT.MeleeAttackDamageType = DMG_BURN -- Type of Damage
		ENT.NextAnyAttackTime_Range = 0.6 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.Immune_CombineBall = false
		ENT.HasDeathAnimation = false -- Does it play an animation when it dies?
		ENT.HasExtraMeleeAttackSounds = true-- Set to true to use the extra melee attack sounds
		ENT.HasLeapAttack = true
		ENT.AnimTbl_LeapAttack = {ACT_JUMP}
		ENT.StopLeapAttackAfterFirstHit = true
		ENT.LeapAttackAnimationDelay = 0
		ENT.LeapDistance = 8000 -- The distance of the leap, for example if it is set to 500, when the SNPC is 500 Unit away, it will jump
		ENT.LeapToMeleeDistance = 10 -- How close does it have to be until it uses melee?
		ENT.TimeUntilLeapAttackDamage = 1 -- How much time until it runs the leap damage code?
		ENT.NextLeapAttackTime = 5 -- How much time until it can use a leap attack?
		ENT.NextAnyAttackTime_Leap = 0
		ENT.LeapAttackAnimationDecreaseLengthAmount = 0
		ENT.LeapAttackDamageDistance = 100 -- How far does the damage go?
		ENT.LeapAttackDamageType = DMG_BURN
		ENT.LeapAttackDamage = GetConVarNumber("vj_hellion_leap")
		ENT.FootStepTimeRun = 0.2
		ENT.FootStepTimeWalk = 0.4
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 12 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"npc/antlion/foot1.wav","npc/antlion/foot2.wav","npc/antlion/foot3.wav","npc/antlion/foot4.wav"}
		ENT.SoundTbl_Idle = {"npc/antlion/idle1.wav","npc/antlion/idle2.wav","npc/antlion/idle3.wav","npc/antlion/idle4.wav","npc/antlion/idle5.wav"}
		ENT.SoundTbl_Alert = {"npc/antlion/attack_double1.wav","npc/antlion/attack_double2.wav","npc/antlion/attack_double3.wav"}
		ENT.SoundTbl_MeleeAttackMiss = {""}
		ENT.SoundTbl_MeleeAttack = {"npc/antlion/attack_double1.wav"}
		ENT.SoundTbl_Pain = {"npc/antlion/pain1.wav"}
		ENT.SoundTbl_Death = {"npc/antlion/pain1.wav","npc/antlion/pain2.wav"}
		ENT.SoundTbl_LeapAttack = {"npc/antlion/fly.wav"}
		ENT.SoundTbl_Impact = {"npc/antlion/shell_impact1.wav","npc/antlion/shell_impact2.wav","npc/antlion/shell_impact3.wav","npc/antlion/shell_impact4.wav"}
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnInitialize()
			self:SetSkin(1)

		ParticleEffectAttach("fire_jet_01_flame",PATTACH_POINT_FOLLOW, self, 3)
		ParticleEffectAttach("fire_jet_01_flame",PATTACH_POINT_FOLLOW, self, 4)
		end


		/*-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/

end
	scripted_ents.Register(ENT, ENT.ClassName)
end
do
	local ENT = {}
	ENT.ClassName = "npc_vj_hellionguard"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Hellion Guard"
	ENT.Author 			= "Norpa"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click to spawn it."
	ENT.Category		= "Antlions"

	if (CLIENT) then
	local Name = "Hellion Guard"
	local LangName = "npc_vj_hellionguard"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		/*-----------------------------------------------
			*** Copyright (c) 2012-2016 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/
		ENT.Model = {"models/hellion_guard.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
		ENT.StartHealth = GetConVarNumber("vj_hellionguard_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------
		ENT.VJ_NPC_Class = {"CLASS_ANTLION"} -- NPCs with the same class will be friendly to each other | Combine: CLASS_COMBINE, Zombie: CLASS_ZOMBIE, Antlions = CLASS_ANTLION
		ENT.CustomBlood_Particle = {"blood_advisor_puncture_withdraw"} -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = {"YellowBlood"} -- Leave blank for none | Commonly used: Red = Blood, Yellow Blood = YellowBlood
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack =  {ACT_MELEE_ATTACK1} -- Melee Attack Animations
		ENT.MeleeAttackDistance = 65 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 150 -- How far does the damage go?
		ENT.TimeUntilMeleeAttackDamage = 0.8 -- This counted in seconds | This calculates the time until it hits something
		ENT.NextAnyAttackTime_Melee = 1.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_hellionguard_d")
		ENT.MeleeAttackDamageType = DMG_BURN -- Type of Damage
		ENT.HasRangeAttack = true -- Should the SNPC have a range attack?
		ENT.AnimTbl_RangeAttack = {ACT_RANGE_ATTACK1} -- Range Attack Animations
		ENT.RangeAttackEntityToSpawn = "obj_hellion_fireball" -- The entity that is spawned when range attacking
		ENT.RangeDistance = 1500 -- This is how far away it can shoot
		ENT.RangeToMeleeDistance = 500 -- How close does it have to be until it uses melee?
		ENT.TimeUntilRangeAttackProjectileRelease = 0.7 -- How much time until the projectile code is ran?
		ENT.NextRangeAttackTime = 4 -- How much time until it can use a range attack?
		ENT.NextAnyAttackTime_Range = 0.6 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.AllowIgnition = false
		ENT.Immune_CombineBall = true
		ENT.HasDeathAnimation = true -- Does it play an animation when it dies?
		ENT.AnimTbl_Death = {ACT_DIESIMPLE} -- Death Animations
		ENT.DeathAnimationTime = 3.5 -- Time until the SNPC spawns its corpse and gets removed
		ENT.UsesDamageForceOnDeath = false -- Disables the damage force on death | Useful for SNPCs with Death Animations
		ENT.HasExtraMeleeAttackSounds = true-- Set to true to use the extra melee attack sounds
		ENT.HasMeleeAttackKnockBack = true -- If true, it will cause a knockback to its enemy
		ENT.MeleeAttackKnockBack_Forward1 = 350 -- How far it will push you forward | First in math.random
		ENT.MeleeAttackKnockBack_Forward2 = 350 -- How far it will push you forward | Second in math.random
		ENT.MeleeAttackKnockBack_Up1 = 350 -- How far it will push you up | First in math.random
		ENT.MeleeAttackKnockBack_Up2 = 360
		ENT.MeleeAttackSetEnemyOnFireTime = 3
		ENT.FootStepTimeRun = 0.3
		ENT.FootStepTimeWalk = 0.5
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 16 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_BIG_FLINCH} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS

			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_Idle = {"npc/antlion_guard/growl_idle.wav"}
		ENT.SoundTbl_Alert = {"npc/antlion_guard/angry1.wav","npc/antlion_guard/angry2.wav","npc/antlion_guard/angry3.wav"}
		ENT.SoundTbl_MeleeAttack = {"npc/antlion_guard/shove1.wav"}
		ENT.SoundTbl_MeleeAttackMiss = {""}
		ENT.SoundTbl_RangeAttack = {"npc/antlion_guard/angry1.wav"}
		ENT.SoundTbl_Pain = {""}
		ENT.SoundTbl_Death = {"npc/antlion_guard/antlion_guard_die1.wav","npc/antlion_guard/antlion_guard_die2.wav"}
		ENT.SoundTbl_FootStep = {"npc/antlion_guard/foot_heavy1.wav","npc/antlion_guard/foot_heavy2.wav"}
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnInitialize()


		ParticleEffectAttach("fire_jet_01_flame",PATTACH_POINT_FOLLOW, self, 3)
		ParticleEffectAttach("fire_jet_01_flame",PATTACH_POINT_FOLLOW, self, 4)
		end

		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:RangeAttackCode_GetShootPos(TheProjectile)
			return (self:GetEnemy():GetPos() - self:LocalToWorld(Vector(0,0,math.random(20,20))))*2 + self:GetUp()*220
		end

		function ENT:MultipleMeleeAttacks()
			local attack = 1
			if attack == 1 then
				self.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
				self.MeleeAttackDistance = 70
				self.MeleeAttackDamageDistance = 210
				self.TimeUntilMeleeAttackDamage = 0.8
				self.NextAnyAttackTime_Melee = 0.8
				self.MeleeAttackDamage = GetConVarNumber("vj_hellionguard_d")
				self.MeleeAttackDamageType = DMG_BURN
				self.MeleeAttackKnockBack_Forward1 = 550
				self.MeleeAttackKnockBack_Forward2 = 550
				self.MeleeAttackKnockBack_Up1 = 280
				self.MeleeAttackKnockBack_Up2 = 280
				self.MeleeAttackWorldShakeOnMiss = false
				self.SoundTbl_MeleeAttack = {"npc/antlion_guard/shove1.wav"}

				end
				end

						function ENT:CustomOnTakeDamage_BeforeGetDamage(dmginfo,hitgroup)
			local panis = dmginfo:GetDamageType()
			if (panis == DMG_BUCKSHOT or panis == DMG_BULLET or panis == DMG_GENERIC or panis == DMG_CLUB) && dmginfo:GetDamage() >= 5  && dmginfo:GetAttacker().IsHugeMonster != true then
			dmginfo:ScaleDamage(0.1)
			dmginfo:SetDamage(dmginfo:GetDamage() /1)
			end



			local panis = dmginfo:GetDamageType()
			if (panis == DMG_BUCKSHOT or panis == DMG_BULLET or panis == DMG_GENERIC or panis == DMG_CLUB) && dmginfo:GetDamage() >= 4  && dmginfo:GetAttacker().IsHugeMonster != true then
			dmginfo:ScaleDamage(0.1)
			dmginfo:SetDamage(dmginfo:GetDamage() /1)
			end


			local panis = dmginfo:GetDamageType()
			if (panis == DMG_BUCKSHOT or panis == DMG_BULLET or panis == DMG_GENERIC or panis == DMG_CLUB) && dmginfo:GetDamage() >= 40 && dmginfo:GetAttacker().IsHugeMonster != true then
			dmginfo:ScaleDamage(0.1)
			dmginfo:SetDamage(dmginfo:GetDamage() /1)
			end
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
	ENT.ClassName = "npc_vj_thunderlion"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Thunderlion"
	ENT.Author 			= "Norpa"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.Category		= "Antlions"

	if (CLIENT) then
	local Name = "Thunderlion"
	local LangName = "npc_vj_thunderlion"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		/*-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/
		ENT.Model = "models/AntLio1.mdl"
		ENT.StartHealth = GetConVarNumber("vj_thunderlion_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE

		---------------------------------------------------------------------------------------------------------------------------------------------
		ENT.VJ_NPC_Class = {"CLASS_ANTLION"} -- NPCs with the same class will be friendly to each other | Combine: CLASS_COMBINE, Zombie: CLASS_ZOMBIE, Antlions = CLASS_ANTLION
		ENT.CustomBlood_Particle = {"electrical_arc_01_parent"} -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = {"YellowBlood"} -- Leave blank for none | Commonly used: Red = Blood, Yellow Blood = YellowBlood
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack =  {ACT_MELEE_ATTACK1} -- Melee Attack Animations
		ENT.MeleeAttackDistance = 45 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 120 -- How far does the damage go?
		ENT.TimeUntilMeleeAttackDamage = 0.8 -- This counted in seconds | This calculates the time until it hits something
		ENT.NextAnyAttackTime_Melee = 0.8 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_thunderlion_d")
		ENT.MeleeAttackDamageType = DMG_SHOCK -- Type of Damage
		ENT.NextAnyAttackTime_Range = 0.6 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.Immune_CombineBall = false
		ENT.HasDeathAnimation = false -- Does it play an animation when it dies?
		ENT.HasExtraMeleeAttackSounds = true-- Set to true to use the extra melee attack sounds
		ENT.HasLeapAttack = true
		ENT.AnimTbl_LeapAttack = {ACT_JUMP}
		ENT.StopLeapAttackAfterFirstHit = true
		ENT.LeapAttackAnimationDelay = 0
		ENT.LeapDistance = 8000 -- The distance of the leap, for example if it is set to 500, when the SNPC is 500 Unit away, it will jump
		ENT.LeapToMeleeDistance = 10 -- How close does it have to be until it uses melee?
		ENT.TimeUntilLeapAttackDamage = 1 -- How much time until it runs the leap damage code?
		ENT.NextLeapAttackTime = 5 -- How much time until it can use a leap attack?
		ENT.NextAnyAttackTime_Leap = 0
		ENT.LeapAttackAnimationDecreaseLengthAmount = 0
		ENT.LeapAttackDamageDistance = 100 -- How far does the damage go?
		ENT.LeapAttackDamageType = DMG_SHOCK
		ENT.LeapAttackDamage = GetConVarNumber("vj_hellion_leap")
		ENT.FootStepTimeRun = 0.2
		ENT.FootStepTimeWalk = 0.4

			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 12 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"npc/antlion/foot1.wav","npc/antlion/foot2.wav","npc/antlion/foot3.wav","npc/antlion/foot4.wav"}
		ENT.SoundTbl_Idle = {"npc/antlion/idle1.wav","npc/antlion/idle2.wav","npc/antlion/idle3.wav","npc/antlion/idle4.wav","npc/antlion/idle5.wav"}
		ENT.SoundTbl_Alert = {"npc/antlion/attack_double1.wav","npc/antlion/attack_double2.wav","npc/antlion/attack_double3.wav"}
		ENT.SoundTbl_MeleeAttackMiss = {""}
		ENT.SoundTbl_MeleeAttack = {"npc/antlion/attack_double1.wav"}
		ENT.SoundTbl_Pain = {"npc/antlion/pain1.wav"}
		ENT.SoundTbl_Death = {"npc/antlion/pain1.wav","npc/antlion/pain2.wav"}
		ENT.SoundTbl_LeapAttack = {"npc/antlion/fly.wav"}
		ENT.SoundTbl_Impact = {"npc/antlion/shell_impact1.wav","npc/antlion/shell_impact2.wav","npc/antlion/shell_impact3.wav","npc/antlion/shell_impact4.wav"}
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnInitialize()

		ParticleEffectAttach("electrical_arc_01_system",PATTACH_POINT_FOLLOW,self,1)

		end

		/*-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/

end
	scripted_ents.Register(ENT, ENT.ClassName)
end
do
	local ENT = {}
	ENT.ClassName = "npc_vj_thunderlionguard"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Thunderlion Guard"
	ENT.Author 			= "Norpa"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click to spawn it."
	ENT.Category		= "Antlions"

	if (CLIENT) then
	local Name = "Thunderlion Guard"
	local LangName = "npc_vj_thunderlionguard"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		/*-----------------------------------------------
			*** Copyright (c) 2012-2016 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		-----------------------------------------------*/
		ENT.Model = {"models/metlion_guard.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
		ENT.StartHealth = GetConVarNumber("vj_thunderlionguard_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------
		ENT.VJ_NPC_Class = {"CLASS_ANTLION"} -- NPCs with the same class will be friendly to each other | Combine: CLASS_COMBINE, Zombie: CLASS_ZOMBIE, Antlions = CLASS_ANTLION
		ENT.CustomBlood_Particle = {"electrical_arc_01_parent"} -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = {"YellowBlood"} -- Leave blank for none | Commonly used: Red = Blood, Yellow Blood = YellowBlood
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack =  {ACT_MELEE_ATTACK1} -- Melee Attack Animations
		ENT.MeleeAttackDistance = 65 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 210 -- How far does the damage go?
		ENT.TimeUntilMeleeAttackDamage = 0.8 -- This counted in seconds | This calculates the time until it hits something
		ENT.NextAnyAttackTime_Melee = 1.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_thunderlionguard_d")
		ENT.MeleeAttackDamageType = DMG_SHOCK -- Type of Damage
		ENT.HasRangeAttack = false -- Should the SNPC have a range attack?
		ENT.AnimTbl_RangeAttack = {ACT_RANGE_ATTACK1} -- Range Attack Animations
		ENT.RangeAttackEntityToSpawn = "" -- The entity that is spawned when range attacking
		ENT.RangeDistance = 1500 -- This is how far away it can shoot
		ENT.RangeToMeleeDistance = 500 -- How close does it have to be until it uses melee?
		ENT.TimeUntilRangeAttackProjectileRelease = 0.7 -- How much time until the projectile code is ran?
		ENT.NextRangeAttackTime = 4 -- How much time until it can use a range attack?
		ENT.NextAnyAttackTime_Range = 0.6 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.AllowIgnition = false
		ENT.Immune_CombineBall = true
		ENT.HasDeathAnimation = true -- Does it play an animation when it dies?
		ENT.AnimTbl_Death = {ACT_DIESIMPLE} -- Death Animations
		ENT.DeathAnimationTime = 3.5 -- Time until the SNPC spawns its corpse and gets removed
		ENT.UsesDamageForceOnDeath = false -- Disables the damage force on death | Useful for SNPCs with Death Animations
		ENT.HasExtraMeleeAttackSounds = true-- Set to true to use the extra melee attack sounds
		ENT.HasMeleeAttackKnockBack = true -- If true, it will cause a knockback to its enemy
		ENT.MeleeAttackKnockBack_Forward1 = 350 -- How far it will push you forward | First in math.random
		ENT.MeleeAttackKnockBack_Forward2 = 350 -- How far it will push you forward | Second in math.random
		ENT.MeleeAttackKnockBack_Up1 = 350 -- How far it will push you up | First in math.random
		ENT.MeleeAttackKnockBack_Up2 = 360
		ENT.FootStepTimeRun = 0.3
		ENT.FootStepTimeWalk = 0.5
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 16 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_BIG_FLINCH} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS

			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_Idle = {"npc/antlion_guard/growl_idle.wav"}
		ENT.SoundTbl_Alert = {"npc/antlion_guard/angry1.wav","npc/antlion_guard/angry2.wav","npc/antlion_guard/angry3.wav"}
		ENT.SoundTbl_MeleeAttack = {"npc/antlion_guard/shove1.wav"}
		ENT.SoundTbl_MeleeAttackMiss = {""}
		ENT.SoundTbl_RangeAttack = {"npc/antlion_guard/angry1.wav"}
		ENT.SoundTbl_Pain = {""}
		ENT.SoundTbl_Death = {"npc/antlion_guard/antlion_guard_die1.wav","npc/antlion_guard/antlion_guard_die2.wav"}
		ENT.SoundTbl_FootStep = {"npc/antlion_guard/foot_heavy1.wav","npc/antlion_guard/foot_heavy2.wav"}
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomOnInitialize()

		ParticleEffectAttach("electrical_arc_01_parent", PATTACH_POINT_FOLLOW, self, 8)
		ParticleEffectAttach("electrical_arc_01_parent", PATTACH_POINT_FOLLOW, self, 7)
		ParticleEffectAttach("electrical_arc_01_parent", PATTACH_POINT_FOLLOW, self, 6)
		ParticleEffectAttach("electrical_arc_01_parent", PATTACH_POINT_FOLLOW, self, 5)
		ParticleEffectAttach("electrical_arc_01_parent", PATTACH_POINT_FOLLOW, self, 4)
		ParticleEffectAttach("electrical_arc_01_parent", PATTACH_POINT_FOLLOW, self, 3)
		ParticleEffectAttach("electrical_arc_01_parent", PATTACH_POINT_FOLLOW, self, 2)
		ParticleEffectAttach("electrical_arc_01_parent", PATTACH_POINT_FOLLOW, self, 1)
		end

		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:RangeAttackCode_GetShootPos(TheProjectile)
			return (self:GetEnemy():GetPos() - self:LocalToWorld(Vector(0,0,math.random(20,20))))*2 + self:GetUp()*220
		end

		function ENT:MultipleMeleeAttacks()
			local attack = 1
			if attack == 1 then
				self.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
				self.MeleeAttackDistance = 80
				self.MeleeAttackDamageDistance = 240
				self.TimeUntilMeleeAttackDamage = 0.8
				self.NextAnyAttackTime_Melee = 0.8
				self.MeleeAttackDamage = GetConVarNumber("vj_hellionguard_d")
				self.MeleeAttackDamageType = DMG_SHOCK
				self.MeleeAttackKnockBack_Forward1 = 750
				self.MeleeAttackKnockBack_Forward2 = 750
				self.MeleeAttackKnockBack_Up1 = 380
				self.MeleeAttackKnockBack_Up2 = 380
				self.MeleeAttackWorldShakeOnMiss = false
				self.SoundTbl_MeleeAttack = {"npc/antlion_guard/shove1.wav"}

				end
				end

						function ENT:CustomOnTakeDamage_BeforeGetDamage(dmginfo,hitgroup)
			local panis = dmginfo:GetDamageType()
			if (panis == DMG_BUCKSHOT or panis == DMG_BULLET or panis == DMG_GENERIC or panis == DMG_CLUB) && dmginfo:GetDamage() >= 5  && dmginfo:GetAttacker().IsHugeMonster != true then
			dmginfo:ScaleDamage(0.1)
			dmginfo:SetDamage(dmginfo:GetDamage() /1)
			end



			local panis = dmginfo:GetDamageType()
			if (panis == DMG_BUCKSHOT or panis == DMG_BULLET or panis == DMG_GENERIC or panis == DMG_CLUB) && dmginfo:GetDamage() >= 4  && dmginfo:GetAttacker().IsHugeMonster != true then
			dmginfo:ScaleDamage(0.1)
			dmginfo:SetDamage(dmginfo:GetDamage() /1)
			end


			local panis = dmginfo:GetDamageType()
			if (panis == DMG_BUCKSHOT or panis == DMG_BULLET or panis == DMG_GENERIC or panis == DMG_CLUB) && dmginfo:GetDamage() >= 40 && dmginfo:GetAttacker().IsHugeMonster != true then
			dmginfo:ScaleDamage(0.1)
			dmginfo:SetDamage(dmginfo:GetDamage() /1)
			end
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
	ENT.ClassName = "obj_frostlion_iceball"


	ENT.Type 			= "anim"
	ENT.Base 			= "base_gmodentity"
	ENT.PrintName		= "Frostlion Guard"
	ENT.Author			= "Norpa"
	ENT.Information		= ""
	ENT.Category		= ""

	ENT.Spawnable			= false
	ENT.AdminSpawnable		= true

	if SERVER then

		--AddCSLuaFile("shared.lua")
		--AddCSLuaFile("cl_init.lua")
		--include("shared.lua")

		function ENT:Initialize()
		//SMALL BLUE BANGY THINGY\\
		self:SetModel("models/props_junk/watermelon01_chunk02c.mdl")
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetOwner( self:GetOwner() )
		self:SetColor(0, 0, 255)
			local phys = self.Entity:GetPhysicsObject()
			if (phys:IsValid()) then
				phys:Wake()
			end
		end

		function ENT:PhysicsCollide()
		self:EmitSound("ents/RandIceball/iceball_expld.wav")
		local pos = self:GetPos()
		local physical = ents.FindInSphere(pos, 1)
		for k, v in pairs (physical) do
		if v:IsValid() or v:IsWorld() then
		for i, x in pairs (ents.FindInSphere(pos, 63)) do
		local damage = DamageInfo()
		damage:SetDamage( 20 )
		damage:SetDamageType( DMG_PLASMA )
		damage:SetAttacker(self)
		damage:SetInflictor(self)
		x:TakeDamageInfo(damage, self)
		self:Remove()
					end
				end
			end
		end

		function ENT:Think()
		if self:IsValid() then
		ParticleEffectAttach("striderbuster_smoke", PATTACH_ABSORIGIN_FOLLOW, self, 0)
		end
		if self:GetOwner() != NULL then
		self:SetOwner(self)
			end
		end

end
	scripted_ents.Register(ENT, ENT.ClassName)
end
do
	local ENT = {}
	ENT.ClassName = "obj_hellion_fireball"


	ENT.Type 			= "anim"
	ENT.Base 			= "base_gmodentity"
	ENT.PrintName		= "Hellion Guard"
	ENT.Author			= "Norpa"
	ENT.Information		= ""
	ENT.Category		= ""

	ENT.Spawnable			= false
	ENT.AdminSpawnable		= true

	if SERVER then

		--AddCSLuaFile("shared.lua")
		--AddCSLuaFile("cl_init.lua")
		--include("shared.lua")

		function ENT:Initialize()
		//SMALL BLUE BANGY THINGY\\
		self:SetModel("models/props_junk/watermelon01_chunk02c.mdl")
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetColor(255, 255, 255, 0)
		self:SetOwner(self:GetOwner())
			local phys = self.Entity:GetPhysicsObject()
			if (phys:IsValid()) then
				phys:Wake()
			end
		end

		function ENT:PhysicsCollide()
		self:EmitSound("ents/RandFireball/fireball_expld.wav")
		local pos = self:GetPos()
		local physical = ents.FindInSphere(pos, 1)
		for k, v in pairs (physical) do
		if v:IsValid() or v:IsWorld() then
		for i, x in pairs (ents.FindInSphere(pos, 63)) do
		local damage = DamageInfo()
		damage:SetDamage( 35 )
		damage:SetDamageType( DMG_BURN )
		damage:SetAttacker(self)
		damage:SetInflictor(self)
		x:TakeDamageInfo(damage, self)
		self:Remove()
					end
				end
			end
		end

		function ENT:Think()
		if self:IsValid() then
		ParticleEffectAttach("fire_jet_01_flame", PATTACH_ABSORIGIN_FOLLOW, self, 0)
		 end
		end

	end
	scripted_ents.Register(ENT, ENT.ClassName)
end
