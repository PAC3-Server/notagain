if not file.Exists("autorun/vj_base_autorun.lua","LUA") then return end

local function AddConVar(cName,cValue,cFlags)
	if !ConVarExists(cName) then
		local cFlags = cFlags or {FCVAR_NONE}
		CreateConVar(cName,cValue,cFlags)
	end
end

AddConVar("vj_dm_spiderqueen_h",10000)
AddConVar("vj_dm_spiderqueen_d_single",85)
AddConVar("vj_dm_spiderqueen_d_dual",47)
AddConVar("vj_dm_spiderqueen_d_poison",96)

AddConVar("vj_dm_spider_h",200)
AddConVar("vj_dm_spider_d_reg",30)
AddConVar("vj_dm_spider_d_slow",37)
AddConVar("vj_dm_spider_d_slowdual",21)

AddConVar("vj_dm_facehugger_h",100)
AddConVar("vj_dm_facehugger_d_reg",25)
AddConVar("vj_dm_facehugger_d_bite",30)
AddConVar("vj_dm_facehugger_d_slow",38)

AddConVar("vj_dm_worm_h",8000)
AddConVar("vj_dm_worm_d",80)

-- Menu --
local AddConvars = {}
AddConvars["vj_dm_nobabyspawn"] = 1 -- Spawn Baby Spiders?
AddConvars["vj_dm_nextbaby"] = 40 -- Next Baby Spawn
AddConvars["vj_dm_babyspawnlimit"] = 9 -- Baby spawn limit
for k, v in pairs(AddConvars) do
	if !ConVarExists( k ) then CreateConVar( k, v, {FCVAR_ARCHIVE} ) end
end

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
	ENT.Category		= "VJ Base"
	ENT.AdminOnly		= true

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
	list.Set("NPC",ENT.ClassName,{
		Name = ENT.ClassName,
		Class = ENT.ClassName,
		Category = "VJ Base",
	})
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

do
	local ENT = {}
	ENT.ClassName = "npc_vj_dmvj_spider"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Spider"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spider!"
	ENT.Instructions 	= "Click to spawn it."
	ENT.AdminOnly		= true

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
	list.Set("NPC",ENT.ClassName,{
		Name = ENT.ClassName,
		Class = ENT.ClassName,
		Category = "VJ Base",
	})
end

do
	local ENT = {}
	ENT.ClassName = "obj_dm_spidergas"

	ENT.Type 			= "anim"
	ENT.Base 			= "obj_vj_projectile_base"
	ENT.PrintName		= "Spider Gas"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Information		= "Projectiles for my addons"
	ENT.Category		= "Projectiles"

	if (CLIENT) then
		local Name = "Spider Gas"
		local LangName = "obj_dm_spidergas"
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
		ENT.RadiusDamageRadius = 100 -- How far the damage go? The farther away it's from its enemy, the less damage it will do | Counted in world units
		ENT.RadiusDamage = 20 -- How much damage should it deal? Remember this is a radius damage, therefore it will do less damage the farther away the entity is from its enemy
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

do
	local ENT = {}
	ENT.ClassName = "npc_vj_dmvj_spider_queen"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Spider Queen"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "She's your mother!"
	ENT.Instructions 	= "Click to spawn it."
	ENT.AdminOnly		= true

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
	list.Set("NPC",ENT.ClassName,{
		Name = ENT.ClassName,
		Class = ENT.ClassName,
		Category = "VJ Base",
	})
end
