if not file.Exists("autorun/vj_base_autorun.lua","LUA") then return end

local AddConvars = {}


AddConvars["vj_allosaurus_h"] = 460
AddConvars["vj_allosaurus_d"] = 65

AddConvars["vj_scar_m_h"] = 20000
AddConvars["vj_scar_m_d"] = 210

AddConvars["vj_hadro_h"] = 560
AddConvars["vj_hadro_d"] = 45

AddConvars["vj_carno_h"] = 890
AddConvars["vj_carno_d"] = 70

AddConvars["vj_cerato_h"] = 135
AddConvars["vj_cerato_d"] = 48

AddConvars["vj_trex_l2_h"] = 2300
AddConvars["vj_trex_l2_d"] = 120

AddConvars["vj_trex_h"] = 2010
AddConvars["vj_trex_d"] = 150

AddConvars["vj_triceratops_h"] = 820
AddConvars["vj_triceratops_d"] = 60

AddConvars["vj_dilop_h"] = 320
AddConvars["vj_dilop_d"] = 50

AddConvars["vj_gigantosaur_h"] = 2320
AddConvars["vj_gigantosaur_d"] = 135

AddConvars["vj_trex_jp_h"] = 3200
AddConvars["vj_trex_jp_d"] = 175

AddConvars["vj_carha_h"] = 2400
AddConvars["vj_carha_d"] = 90

AddConvars["vj_droma_h"] = 70
AddConvars["vj_droma_d"] = 20

AddConvars["vj_spino_jp_h"] = 3500
AddConvars["vj_spino_jp_d"] = 165

AddConvars["vj_raptor_jp_h"] = 150
AddConvars["vj_raptor_jp_d"] = 35

AddConvars["vj_rugops_h"] = 350
AddConvars["vj_rugops_d"] = 60

AddConvars["vj_trex_huge_h"] = 2800
AddConvars["vj_trex_huge_d"] = 110

AddConvars["vj_raptor_t_h"] = 60
AddConvars["vj_raptor_t_d"] = 30

AddConvars["vj_brah_h"] = 9200


for k, v in pairs(AddConvars) do
	if !ConVarExists( k ) then CreateConVar( k, v, {FCVAR_NONE} ) end
end

do
	local ENT = {}
	ENT.ClassName = "npc_dino_allosaurus"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Allosaurus"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Allosaurus"
	local LangName = "npc_dino_allosaurus"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/allosaurus.mdl"
		ENT.StartHealth = GetConVarNumber("vj_allosaurus_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.MeleeAttackDistance = 85 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 260 -- How far the damage goes
		ENT.MeleeDistanceB = 85 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.Immune_CombineBall = true
		ENT.MeleeAttackHitTime = 0.6 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_allosaurus_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.4 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 0.8 -- Next foot step sound when it is walking
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex_jp/step1.ogg","t-rex_jp/step2.ogg","t-rex_jp/step3.ogg"}
		ENT.SoundTbl_Idle = {"carno/idle1.ogg","carno/idle2.ogg"}
		ENT.SoundTbl_Alert = {"carno/roar1.ogg","carno/roar2.ogg","carno/roar3.ogg","carno/roar4.ogg",}
		ENT.SoundTbl_MeleeAttack = {"carno/bite1.ogg","carno/bite2.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"carno/roar1.ogg"}
		ENT.SoundTbl_Death = {"carno/die1.ogg"}

		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(150, 50, 150), Vector(-50, -50, 0))
		end

		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
	end
	scripted_ents.Register(ENT, ENT.ClassName)
end
do
	local ENT = {}
	ENT.ClassName = "npc_dino_brah"

	ENT.Base 			= "npc_vj_animal_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Brachiosaurus"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.Category		= "Dinosaurs"

	if (CLIENT) then
	local Name = "Brachiosaurus"
	local LangName = "npc_dino_brah"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/npcs/dinosaurs/brachiosaurus/brachiosaurus.mdl"
		ENT.StartHealth = GetConVarNumber("vj_brah_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		ENT.IsHugeMonster = true
		---------------------------------------------------------------------------------------------------------------------------------------------
		ENT.VJ_FriendlyNPCsSingle = {"npc_dino_triceratops","npc_dino_hadrosaur","npc_dino_brah"}
		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the nuumber is the more chance is has to spawn | 500 is a good number | Make the number smaller if you are using big decal like Antlion Splat
		ENT.HasCustomBloodPoolParticle = true -- Should the SNPC have custom blood pool particle?
		ENT.CustomBloodPoolParticle = "vj_bleedout_red_small" -- The custom blood pool particle
		ENT.ZombieFriendly = true -- Makes the SNPC friendly to the HL2 Zombies
		ENT.AntlionFriendly = true -- Makes the SNPC friendly to the Antlions
		ENT.CombineFriendly = true -- Makes the SNPC friendly to the Combine
		ENT.PlayerFriendly = true -- When true, this will make it friendly to rebels and characters like that
		ENT.BrokenBloodSpawnUp = 10 -- Positive Number = Up | Negative Number = Down
		ENT.Immune_CombineBall = true
		ENT.Immune_Physics = true
		ENT.HasDeathRagdoll = false
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 1 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 2.3 -- Next foot step sound when it is walking
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex_jp/step1.ogg","t-rex_jp/step2.ogg","t-rex_jp/step3.ogg"}
		ENT.SoundTbl_Idle = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_Alert = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_MeleeAttack = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_Pain = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_Death = {"Triceratops/TricCall03.ogg"}

		ENT.FootStepSoundLevel = 100
		ENT.AlertSoundLevel = 150
		ENT.PainSoundLevel = 150
		ENT.DeathSoundLevel = 150
		ENT.IdleSoundLevel = 150
		ENT.MeleeAttackSoundLevel = 150
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(170, 109, 795), -Vector(150, 100, 0))
		end


		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_carcharodontosaurus"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Carcharodontosaurus"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Carcharodontosaurus"
	local LangName = "npc_dino_carcharodontosaurus"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/carcharodontosaurus/carcharodontosaurus.mdl"
		ENT.StartHealth = GetConVarNumber("vj_carha_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.ZombieFriendly = false -- Makes the SNPC friendly to the HL2 Zombies
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.Immune_CombineBall = true
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1} -- Melee Attack Animations
		ENT.MeleeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
		ENT.MeleeAttackDistance = 105 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 330 -- How far the damage goes
		ENT.MeleeDistanceB = 105 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.MeleeAttackHitTime = 0.3 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.3 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_carha_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.4 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 1.3 -- Next foot step sound when it is walking
		-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex_jp/step1.ogg","t-rex_jp/step2.ogg","t-rex_jp/step3.ogg"}
		ENT.SoundTbl_Idle = {"Carcha/idle1.ogg","Carcha/idle2.ogg"}
		ENT.SoundTbl_Alert = {"Carcha/angry1.ogg"}
		ENT.SoundTbl_MeleeAttack = {"Carcha/biteh2.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"Carcha/roar3.ogg","Carcha/roar4.ogg"}
		ENT.SoundTbl_Death = {"Carcha/die1.ogg"}

		ENT.FootStepSoundLevel = 100
		ENT.AlertSoundLevel = 150
		ENT.PainSoundLevel = 150
		ENT.DeathSoundLevel = 150
		ENT.IdleSoundLevel = 150
		ENT.MeleeAttackSoundLevel = 150
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(180, 60, 210), -Vector(140, 60, 0))
		end

		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_carnotaurus"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Carnotaurus"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Carnotaurus"
	local LangName = "npc_dino_carnotaurus"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/animals/carnotaurus_npc.mdl"
		ENT.StartHealth = GetConVarNumber("vj_carno_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.MeleeAttackDistance = 115 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 330 -- How far the damage goes
		ENT.Immune_CombineBall = true
		ENT.Immune_Physics = true
		ENT.MeleeAttackHitTime = 0.6 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_carno_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 1 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 1 -- Next foot step sound when it is walking
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"stalker/creature/giant/giant_hit.ogg"}
		ENT.SoundTbl_Idle = {"carnotaurus/idle1.ogg","carnotaurus/idle2.ogg"}
		ENT.SoundTbl_Alert = {"carnotaurus/roar.ogg"}
		ENT.SoundTbl_MeleeAttack = {"carnotaurus/idle1.ogg"}
		ENT.SoundTbl_Pain = {"t-rex/pain1.ogg"}
		ENT.SoundTbl_Death = {"stalker/creature/giant/die_0.ogg","stalker/creature/giant/die_1.ogg"}

		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(190, 50, 150), Vector(-50, -50, 0))
		end

		function ENT:CustomOnAlert()
			self:VJ_ACT_PLAYACTIVITY(ACT_FLINCH_PHYSICS,true,1,false)
		end

		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_cerato"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Ceratosaurus"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Ceratosaurus"
	local LangName = "npc_dino_cerato"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/ceratosaurus/ceratosaurus.mdl"
		ENT.StartHealth = GetConVarNumber("vj_cerato_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.ZombieFriendly = false -- Makes the SNPC friendly to the HL2 Zombies
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.MeleeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
		ENT.MeleeAttackDistance = 45 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 170 -- How far the damage goes
		ENT.MeleeDistanceB = 45 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.Immune_CombineBall = true
		ENT.MeleeAttackHitTime = 0.6 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_cerato_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.5 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 1.4 -- Next foot step sound when it is walking
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex_jp/step1.ogg","t-rex_jp/step2.ogg","t-rex_jp/step3.ogg"}
		ENT.SoundTbl_Idle = {"carno/idle1.ogg","carno/idle2.ogg"}
		ENT.SoundTbl_Alert = {"carno/roar1.ogg","carno/roar2.ogg","carno/roar3.ogg","carno/roar4.ogg",}
		ENT.SoundTbl_MeleeAttack = {"carno/bite1.ogg","carno/bite2.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"carno/roar1.ogg"}
		ENT.SoundTbl_Death = {"carno/die1.ogg"}


		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(70, 5, 80), -Vector(80, 5, 0))
		end

		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_dilophosaurus"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Dilophosaurus"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Dilophosaurus"
	local LangName = "npc_dino_dilophosaurus"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/dilophosaurus.mdl"
		ENT.StartHealth = GetConVarNumber("vj_dilop_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.MeleeAttackDistance = 65 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 190 -- How far the damage goes
		ENT.MeleeDistanceB = 65 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.Immune_CombineBall = true
		ENT.MeleeAttackHitTime = 0.4 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 1 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_dilop_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.4 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 0.4 -- Next foot step sound when it is walking
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex_jp/step1.ogg","t-rex_jp/step2.ogg","t-rex_jp/step3.ogg"}
		ENT.SoundTbl_Alert = {"dilophosaurus/growl1.ogg","dilophosaurus/growl2.ogg","dilophosaurus/growl3.ogg","dilophosaurus/growl4.ogg"}
		ENT.SoundTbl_MeleeAttack = {"dilophosaurus/bite1.ogg","dilophosaurus/bite2.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"dilophosaurus/pain1.ogg","dilophosaurus/pain2.ogg","dilophosaurus/pain3.ogg"}
		ENT.SoundTbl_Death = {"dilophosaurus/death1.ogg"}

		ENT.FootStepSoundLevel = 100
		ENT.AlertSoundLevel = 150
		ENT.PainSoundLevel = 150
		ENT.DeathSoundLevel = 150
		ENT.IdleSoundLevel = 150
		ENT.MeleeAttackSoundLevel = 150

		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(120, 5, 145), -Vector(80, 5, 0))
		end

		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_gigano"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Giganotosaurus"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Giganotosaurus"
	local LangName = "npc_dino_gigano"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/giganotosaurus.mdl"
		ENT.StartHealth = GetConVarNumber("vj_gigantosaur_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.MeleeAttackDistance = 115 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 260 -- How far the damage goes

		ENT.Immune_CombineBall = true
		ENT.MeleeAttackHitTime = 0.6 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_gigantosaur_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.6 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 1.4 -- Next foot step sound when it is walking
		ENT.HasWorldShakeOnMove = true -- Should the world shake when it's moving?
		ENT.NextWorldShakeOnRun = 0.6 -- How much time until the world shakes while it's running
		ENT.NextWorldShakeOnWalk = 1.4 -- How much time until the world shakes while it's walking
		ENT.WorldShakeOnMoveRadius = 2500 -- How far the screen shake goes, in world units
		ENT.WorldShakeOnMoveDuration = 0.3 -- How long the screen shake will last, in seconds
		ENT.WorldShakeOnMoveFrequency = 100 -- Just leave it to 100
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex/step1.ogg","t-rex/step2.ogg"}
		ENT.SoundTbl_Idle = {"carno/idle1.ogg","carno/idle2.ogg"}
		ENT.SoundTbl_Alert = {"carno/roar1.ogg","carno/roar2.ogg","carno/roar3.ogg","carno/roar4.ogg"}
		ENT.SoundTbl_MeleeAttack = {"carno/bite1.ogg","carno/bite2.ogg","carno/bite3.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"carno/biteh1.ogg","carno/angry1.ogg"}
		ENT.SoundTbl_Death = {"carno/die1.ogg"}

		ENT.FootStepSoundLevel = 100
		ENT.AlertSoundLevel = 150
		ENT.PainSoundLevel = 150
		ENT.DeathSoundLevel = 150
		ENT.IdleSoundLevel = 150
		ENT.MeleeAttackSoundLevel = 150
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(120, 90, 150), -Vector(120, 90, 0))
		end

		function ENT:CustomOnAlert()

			self:VJ_ACT_PLAYACTIVITY(ACT_RANGE_ATTACK1,true,1,false)


		end
		-----

		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_hadrosaur"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Hadrosaur"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Hadrosaur"
	local LangName = "npc_dino_hadrosaur"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/hadrosaur.mdl"
		ENT.StartHealth = GetConVarNumber("vj_hadro_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------
		ENT.VJ_FriendlyNPCsSingle = {"npc_dino_triceratops","npc_dino_hadrosaur","npc_dino_brah"}
		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.Immune_CombineBall = true
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1} -- Melee Attack Animations
		ENT.MeleeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
		ENT.MeleeAttackDistance = 75 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 210 -- How far the damage goes
		ENT.MeleeDistanceB = 75 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.MeleeAttackHitTime = 0.7 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_hadro_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.PlayerFriendly = true -- When true, it will still attack If you attack to much, also this will make it friendly to rebels and characters like that
		ENT.BecomeEnemyToPlayer = true -- Should the friendly SNPC become enemy towards the player if it's damaged by a player?
		ENT.BecomeEnemyToPlayerLevel = 4 -- How many times does the player have to hit the SNPC for it to become enemy?
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.5 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 0.7 -- Next foot step sound when it is walking
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex_jp/step1.ogg","t-rex_jp/step2.ogg","t-rex_jp/step3.ogg"}
		ENT.SoundTbl_Idle = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_Alert = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_MeleeAttack = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_Pain = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_Death = {"Triceratops/TricCall03.ogg"}
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(120, 60, 150), -Vector(120, 60, 0))
		end


		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_raptor_jp"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Raptor (Jurassic park)"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Raptor (Jurassic park)"
	local LangName = "npc_dino_raptor_jp"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/animals/raptor_npc.mdl"
		ENT.StartHealth = GetConVarNumber("vj_raptor_jp_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.ZombieFriendly = false -- Makes the SNPC friendly to the HL2 Zombies
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.MeleeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
		ENT.MeleeAttackDistance = 55 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 170 -- How far the damage goes
		ENT.MeleeDistanceB = 55 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.MeleeAttackHitTime = 0.6 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_raptor_jp_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 1 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 1 -- Next foot step sound when it is walking

			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"raptor_jp/step1.ogg","raptor_jp/step2.ogg"}
		ENT.SoundTbl_Idle = {"raptor_jp/idle1.ogg","raptor_jp/idle2.ogg"}
		ENT.SoundTbl_Alert = {"raptor_jp/roar1.ogg"}
		ENT.SoundTbl_MeleeAttack = {"raptor_jp/attack1.ogg","raptor_jp/attack2.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"raptor_jp/hurt1.ogg"}
		ENT.SoundTbl_Death = {"raptor_jp/die1.ogg"}

		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(70, 5, 80), -Vector(80, 5, 0))
		end

		function ENT:CustomOnAlert()
			self:VJ_ACT_PLAYACTIVITY(ACT_FLINCH_PHYSICS,true,1,false)
		end

		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_raptor_t"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Raptor"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Raptor"
	local LangName = "npc_dino_raptor_t"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/raptor.mdl"
		ENT.StartHealth = GetConVarNumber("vj_raptor_t_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_HUMAN
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_FASTZOMBIE_BIG_SLASH, ACT_MELEE_ATTACK1}
		ENT.MeleeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
		ENT.MeleeAttackDistance = 45 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 160 -- How far the damage goes
		ENT.MeleeDistanceB = 45 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.MeleeAttackHitTime = 0.4 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_raptor_t_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 1 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 1 -- Next foot step sound when it is walking

			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"raptor_jp/step1.ogg","raptor_jp/step2.ogg"}
		ENT.SoundTbl_Idle = {"raptor/idle1.ogg","raptor/idle2.ogg","raptor/idle3.ogg","raptor/idle4.ogg","raptor/idle5.ogg","raptor/idle6.ogg","raptor/idle7.ogg","raptor/idle8.ogg"}
		ENT.SoundTbl_Alert = {"raptor/raptor_alert1.ogg","raptor/raptor_alert2.ogg","raptor/raptor_alert3.ogg","raptor/raptor_alert4.ogg"}
		ENT.SoundTbl_MeleeAttack = {"raptor/raptor_attack1.ogg","raptor/raptor_attack2.ogg","raptor/raptor_attack3.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"raptor/raptor_hurt1.ogg","raptor/raptor_hurt2.ogg"}
		ENT.SoundTbl_Death = {"raptor/raptor_die1.ogg","raptor/raptor_die2.ogg","raptor/raptor_die3.ogg","raptor/raptor_die4.ogg"}


		function ENT:LeapForceCode()
			local jumpyaw
			local jumpcode = (self:GetEnemy():GetPos() -self:GetPos()):GetNormal() *1000 +self:GetUp() *180 +self:GetForward() *4000
			jumpyaw = jumpcode:Angle().y
			self:SetLocalVelocity(jumpcode)
		end

		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_rugops"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Rugops"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Rugogps"
	local LangName = "npc_dino_rugops"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/rugops/rugops.mdl"
		ENT.StartHealth = GetConVarNumber("vj_rugops_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		ENT.IsHugeMonster = false
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.MeleeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
		ENT.MeleeAttackDistance = 75 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 190 -- How far the damage goes
		ENT.MeleeDistanceB = 75 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.Immune_CombineBall = true
		ENT.MeleeAttackHitTime = 0.6 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_rugops_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.3 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 0.6 -- Next foot step sound when it is walking
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex_jp/step1.ogg","t-rex_jp/step2.ogg","t-rex_jp/step3.ogg"}
		ENT.SoundTbl_Idle = {"carno/idle1.ogg","carno/idle2.ogg"}
		ENT.SoundTbl_Alert = {"carno/roar1.ogg","carno/roar2.ogg","carno/roar3.ogg","carno/roar4.ogg",}
		ENT.SoundTbl_MeleeAttack = {"carno/bite1.ogg","carno/bite2.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"carno/roar1.ogg"}
		ENT.SoundTbl_Death = {"carno/die1.ogg"}
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(110, 20, 90), -Vector(110, 20, 0))
		end


		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_scarface_momma"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Scarface Momma"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Scarface Momma"
	local LangName = "npc_dino_scarface_momma"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/turok/scarface/scarfacemomma.mdl"
		ENT.StartHealth = GetConVarNumber("vj_scar_m_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		ENT.SightDistance = 30000
		ENT.IsHugeMonster = true

		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number s_mommaaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1,ACT_MELEE_ATTACK2,ACT_MELEE_ATTACK3} -- Melee Attack Animations
		ENT.MeleeAttackDistance = 225 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 730 -- How far the damage goes

		ENT.MeleeAttackHitTime = 0.4 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.6 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_scar_m_d")
		ENT.HasExtraMeleeAttackSounds = true
		ENT.Immune_CombineBall = true -- Immune to Combine Ball
		ENT.GetDamageFromIsHugeMonster = true
		ENT.BrokenBloodSpawnUp = 200 -- Positive Number = Up | Negative Number = Down
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 1.2 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 3.4 -- Next foot step sound when it is walking
		ENT.HasWorldShakeOnMove = true -- Should the world shake when it's moving?
		ENT.NextWorldShakeOnRun = 1.2 -- How much time until the world shakes while it's running
		ENT.NextWorldShakeOnWalk = 3.4 -- How much time until the world shakes while it's walking
		ENT.WorldShakeOnMoveRadius = 5600 -- How far the screen shake goes, in world units
		ENT.WorldShakeOnMoveDuration = 1 -- How long the screen shake will last, in seconds
		ENT.WorldShakeOnMoveFrequency = 100 -- Just leave it to 100
		ENT.HasSoundTrack = false -- Does the SNPC have a sound track?
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_s_mommaALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"smom/step.ogg"}
		ENT.SoundTbl_Idle = {"smom/trexbreathing1.ogg","smom/trexhissbreathe.ogg"}
		ENT.SoundTbl_Alert = {"smom/trexroar.ogg"}
		ENT.SoundTbl_MeleeAttack = {"smom/trexbitehiss.ogg"}
		ENT.SoundTbl_Pain = {"smom/pain1.ogg"}
		ENT.SoundTbl_Death = {"smom/die.ogg"}

		ENT.FootStepSoundLevel = 100
		ENT.AlertSoundLevel = 150
		ENT.PainSoundLevel = 150
		ENT.DeathSoundLevel = 150
		ENT.IdleSoundLevel = 150
		ENT.MeleeAttackSoundLevel = 150
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(189, 100, 530), Vector(-170, -100, 0))
		end

		function ENT:CustomOnAlert()
			self:VJ_ACT_PLAYACTIVITY(ACT_IDLE_ANGRY,true,1,false)
		end

		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_spino"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Spinosaurus"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Spinosaurus"
	local LangName = "npc_dino_spino"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/spinosaurus/spinosaurus.mdl"
		ENT.StartHealth = GetConVarNumber("vj_spino_jp_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		ENT.SightDistance = 15000
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.MeleeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
		ENT.MeleeAttackDistance = 135 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 475 -- How far the damage goes
		ENT.MeleeDistanceB = 135 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.Immune_CombineBall = true
		ENT.Immune_Physics = true
		ENT.BrokenBloodSpawnUp = 200 -- Positive Number = Up | Negative Number = Down
		ENT.MeleeAttackHitTime = 0.8 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.9 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_spino_jp_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.5 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 0.9 -- Next foot step sound when it is walking
		ENT.HasWorldShakeOnMove = true -- Should the world shake when it's moving?
		ENT.NextWorldShakeOnRun = 0.5 -- How much time until the world shakes while it's running
		ENT.NextWorldShakeOnWalk = 0.9 -- How much time until the world shakes while it's walking
		ENT.WorldShakeOnMoveRadius = 2600 -- How far the screen shake goes, in world units
		ENT.WorldShakeOnMoveDuration = 0.5 -- How long the screen shake will last, in seconds
		ENT.WorldShakeOnMoveFrequency = 100 -- Just leave it to 100
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex_jp/step1.ogg","t-rex_jp/step2.ogg","t-rex_jp/step3.ogg"}
		ENT.SoundTbl_Idle = {"spino/idle1.ogg","spino/idle2.ogg"}
		ENT.SoundTbl_Alert = {"spino/roar.ogg"}
		ENT.SoundTbl_MeleeAttack = {"spino/idle1.ogg","spino/idle2.ogg"}
		ENT.SoundTbl_Pain = {"spino/idle1.ogg"}
		ENT.SoundTbl_Death = {"spino/idle2.ogg"}


		ENT.FootStepSoundLevel = 100
		ENT.AlertSoundLevel = 150
		ENT.PainSoundLevel = 150
		ENT.DeathSoundLevel = 150
		ENT.IdleSoundLevel = 150
		ENT.MeleeAttackSoundLevel = 150
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(350, 50, 300), Vector(-350, -50, 0))
		end


		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_spino_jp"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Spinosaurus (Jurassic park)"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Spinosaurus (Jurassic park)"
	local LangName = "npc_dino_spino_jp"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/animals/spino_npc.mdl"
		ENT.StartHealth = GetConVarNumber("vj_spino_jp_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		ENT.SightDistance = 15000
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.MeleeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
		ENT.MeleeAttackDistance = 185 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 525 -- How far the damage goes
		ENT.MeleeDistanceB = 185 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.Immune_CombineBall = true
		ENT.Immune_Physics = true
		ENT.BrokenBloodSpawnUp = 200 -- Positive Number = Up | Negative Number = Down
		ENT.MeleeAttackHitTime = 0.8 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.9 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_spino_jp_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.5 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 0.9 -- Next foot step sound when it is walking
		ENT.HasWorldShakeOnMove = true -- Should the world shake when it's moving?
		ENT.NextWorldShakeOnRun = 0.5 -- How much time until the world shakes while it's running
		ENT.NextWorldShakeOnWalk = 0.9 -- How much time until the world shakes while it's walking
		ENT.WorldShakeOnMoveRadius = 2600 -- How far the screen shake goes, in world units
		ENT.WorldShakeOnMoveDuration = 0.5 -- How long the screen shake will last, in seconds
		ENT.WorldShakeOnMoveFrequency = 100 -- Just leave it to 100
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex_jp/step1.ogg","t-rex_jp/step2.ogg","t-rex_jp/step3.ogg"}
		ENT.SoundTbl_Idle = {"spino/idle1.ogg","spino/idle2.ogg"}
		ENT.SoundTbl_Alert = {"spino/roar.ogg"}
		ENT.SoundTbl_MeleeAttack = {"spino/idle1.ogg","spino/idle2.ogg"}
		ENT.SoundTbl_Pain = {"spino/idle1.ogg"}
		ENT.SoundTbl_Death = {"spino/idle2.ogg"}

		ENT.FootStepSoundLevel = 100
		ENT.AlertSoundLevel = 150
		ENT.PainSoundLevel = 150
		ENT.DeathSoundLevel = 150
		ENT.IdleSoundLevel = 150
		ENT.MeleeAttackSoundLevel = 150
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(350, 50, 300), Vector(-350, -50, 0))
		end

		function ENT:CustomOnAlert()
			self:VJ_ACT_PLAYACTIVITY(ACT_FLINCH_PHYSICS,true,1,false)
		end

		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_trex"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "T-Rex"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "T-Rex"
	local LangName = "npc_dino_trex"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/Dinosaurs/trex.mdl"
		ENT.StartHealth = GetConVarNumber("vj_trex_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1} -- Melee Attack Animations
		ENT.MeleeAttackDistance = 85 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 240 -- How far the damage goes
		ENT.MeleeDistanceB = 85 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.TimeUntilMeleeAttackDamage  = 1.2 -- This counted in seconds | This calculates the time until it hits something
		ENT.NextAnyAttackTime_Melee = 1.4 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_trex_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.Immune_CombineBall = true
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 1 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 1 -- Next foot step sound when it is walking
		ENT.HasWorldShakeOnMove = true -- Should the world shake when it's moving?
		ENT.NextWorldShakeOnRun = 1 -- How much time until the world shakes while it's running
		ENT.NextWorldShakeOnWalk = 1 -- How much time until the world shakes while it's walking
		ENT.WorldShakeOnMoveRadius = 2600 -- How far the screen shake goes, in world units
		ENT.WorldShakeOnMoveDuration = 0.4 -- How long the screen shake will last, in seconds
		ENT.WorldShakeOnMoveFrequency = 100 -- Just leave it to 100
		ENT.HasDeathAnimation = true -- Does it play an animation when it dies?
		ENT.AnimTbl_Death = {"ACT_DIESIMPLE"} -- Death Animations
		ENT.DeathAnimationTime = 10 -- Time until the SNPC spawns its corpse and gets removed
		ENT.HasDeathRagdoll = true
		-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = { SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex/step1.ogg","t-rex/step2.ogg"}
		ENT.SoundTbl_Idle = {"t-rex/idle1.ogg","t-rex/idle2.ogg","t-rex/idle3.ogg","t-rex/idle4.ogg"}
		ENT.SoundTbl_Alert = {"t-rex/angry1.ogg","t-rex/angry2.ogg"}
		ENT.SoundTbl_MeleeAttack = {"t-rex/angry2.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"t-rex/pain1.ogg"}
		ENT.SoundTbl_Death = {"t-rex/die.ogg"}

		ENT.FootStepSoundLevel = 100
		ENT.AlertSoundLevel = 150
		ENT.PainSoundLevel = 150
		ENT.DeathSoundLevel = 150
		ENT.IdleSoundLevel = 150
		ENT.MeleeAttackSoundLevel = 150
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(140, 60, 200), -Vector(140, 60, 0))
		end

		function ENT:CustomOnAlert()
			self:VJ_ACT_PLAYACTIVITY(ACT_TREX_ROAR,true,1.5,false)
		end

		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_trex_huge"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Kung Fu T-Rex"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Kung Fu T-Rex"
	local LangName = "npc_dino_trex_huge"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/creatures/trex.mdl"
		ENT.StartHealth = GetConVarNumber("vj_trex_huge_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		ENT.IsHugeMonster = false
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.ZombieFriendly = false -- Makes the SNPC friendly to the HL2 Zombies
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.CallForBackUpOnDamageAnimation = ACT_ALERT
		ENT.MeleeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
		ENT.MeleeAttackDistance = 95 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 410 -- How far the damage goes
		ENT.MeleeDistanceB = 95 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.Immune_CombineBall = true
		ENT.Immune_Physics = true
		ENT.MeleeAttackHitTime = 0.6 -- This counted in seconds | This calculates the time until it hits something
		ENT.UntilNextAttack_Melee = 0.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_trex_huge_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.7 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 1 -- Next foot step sound when it is walking
		ENT.HasWorldShakeOnMove = true -- Should the world shake when it's moving?
		ENT.NextWorldShakeOnRun = 0.7 -- How much time until the world shakes while it's running
		ENT.NextWorldShakeOnWalk = 1 -- How much time until the world shakes while it's walking
		ENT.WorldShakeOnMoveRadius = 2100 -- How far the screen shake goes, in world units
		ENT.WorldShakeOnMoveDuration = 0.6 -- How long the screen shake will last, in seconds
		ENT.WorldShakeOnMoveFrequency = 100 -- Just leave it to 100
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex/step1.ogg","t-rex/step2.ogg"}
		ENT.SoundTbl_Idle = {"t-rex/idle1.ogg","t-rex/idle2.ogg","t-rex/idle3.ogg","t-rex/idle4.ogg"}
		ENT.SoundTbl_Alert = {"t-rex/angry1.ogg","t-rex/angry2.ogg"}
		ENT.SoundTbl_MeleeAttack = {"t-rex/angry2.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"t-rex/pain1.ogg"}
		ENT.SoundTbl_Death = {"t-rex/die.ogg"}
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(220, 90, 280), -Vector(120, 90, 0))
		end


		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_trex_jp"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "T-Rex (Jurassic park)"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "T-Rex (Jurassic park)"
	local LangName = "npc_dino_trex_jp"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/animals/trexy_npc.mdl"
		ENT.StartHealth = GetConVarNumber("vj_trex_jp_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		ENT.SightDistance = 15000
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.MeleeAttackDistance = 125 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 370 -- How far the damage goes
		ENT.MeleeDistanceB = 125 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.Immune_CombineBall = true
		ENT.Immune_Physics = true
		ENT.TimeUntilMeleeAttackDamage = 0.6 -- This counted in seconds | This calculates the time until it hits something
		ENT.NextAnyAttackTime_Melee = 0.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_trex_jp_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.GetDamageFromIsHugeMonster = true
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.4 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 0.9 -- Next foot step sound when it is walking
		ENT.HasWorldShakeOnMove = true -- Should the world shake when it's moving?
		ENT.NextWorldShakeOnRun = 0.4 -- How much time until the world shakes while it's running
		ENT.NextWorldShakeOnWalk = 0.9 -- How much time until the world shakes while it's walking
		ENT.WorldShakeOnMoveRadius = 2600 -- How far the screen shake goes, in world units
		ENT.WorldShakeOnMoveDuration = 0.5 -- How long the screen shake will last, in seconds
		ENT.WorldShakeOnMoveFrequency = 100 -- Just leave it to 100
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS

		function ENT:CustomOnAlert()
			self:VJ_ACT_PLAYACTIVITY(ACT_FLINCH_PHYSICS,true,1,false)
		end

			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex_jp/step1.ogg","t-rex_jp/step2.ogg","t-rex_jp/step3.ogg"}
		ENT.SoundTbl_Idle = {"t-rex_jp/idle1.ogg","t-rex_jp/idle2.ogg"}
		ENT.SoundTbl_Alert = {"t-rex_jp/roar.ogg"}
		ENT.SoundTbl_MeleeAttack = {"t-rex_jp/idle1.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"t-rex/pain1.ogg"}
		ENT.SoundTbl_Death = {"stalker/creature/giant/die_0.ogg","stalker/creature/giant/die_1.ogg"}

		ENT.FootStepSoundLevel = 100
		ENT.AlertSoundLevel = 150
		ENT.PainSoundLevel = 150
		ENT.DeathSoundLevel = 150
		ENT.IdleSoundLevel = 150
		ENT.MeleeAttackSoundLevel = 150
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(200, 50, 260), -Vector(200, 50, 0))
		end



		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_trex_l2"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "T-Rex (Lineage 2)"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "T-Rex (Lineage 2)"
	local LangName = "npc_dino_trex_l2"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/l2trex.mdl"
		ENT.StartHealth = GetConVarNumber("vj_trex_l2_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		ENT.SightDistance = 10000
		---------------------------------------------------------------------------------------------------------------------------------------------

		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
		ENT.MeleeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
		ENT.MeleeAttackDistance = 95 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 240 -- How far the damage goes
		ENT.MeleeDistanceB = 95 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.Immune_CombineBall = true
		ENT.TimeUntilMeleeAttackDamage = 0.5 -- This counted in seconds | This calculates the time until it hits something
		ENT.NextAnyAttackTime_Melee = 0.5 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_trex_l2_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 0.5 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 0.5 -- Next foot step sound when it is walking
		ENT.HasWorldShakeOnMove = true -- Should the world shake when it's moving?
		ENT.NextWorldShakeOnRun = 0.5 -- How much time until the world shakes while it's running
		ENT.NextWorldShakeOnWalk = 0.5 -- How much time until the world shakes while it's walking
		ENT.WorldShakeOnMoveRadius = 2600 -- How far the screen shake goes, in world units
		ENT.WorldShakeOnMoveDuration = 0.4 -- How long the screen shake will last, in seconds
		ENT.WorldShakeOnMoveFrequency = 100 -- Just leave it to 100
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"carno/trex_step.ogg","carno/trex_step1.ogg","carno/trex_step2.ogg"}
		ENT.SoundTbl_Idle = {"carno/idle1.ogg","carno/idle2.ogg"}
		ENT.SoundTbl_Alert = {"carno/roar1.ogg","carno/roar2.ogg","carno/roar3.ogg","carno/roar4.ogg"}
		ENT.SoundTbl_MeleeAttack = {"carno/bite1.ogg","carno/bite2.ogg","carno/bite3.ogg"}
		ENT.SoundTbl_MeleeAttackMiss = {"misses/miss1.ogg","misses/miss2.ogg","misses/miss3.ogg","misses/miss4.ogg"}
		ENT.SoundTbl_Pain = {"carno/biteh1.ogg","carno/angry1.ogg"}
		ENT.SoundTbl_Death = {"carno/die1.ogg"}
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(120, 90, 150), -Vector(120, 90, 0))
		end


		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
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
	ENT.ClassName = "npc_dino_triceratops"

	ENT.Base 			= "npc_vj_creature_base"
	ENT.Type 			= "ai"
	ENT.PrintName 		= "Triceratops"
	ENT.Author 			= "DrVrej"
	ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
	ENT.Purpose 		= "Spawn it and fight with it!"
	ENT.Instructions 	= "Click on the spawnicon to spawn it."
	ENT.AdminOnly		= true

	if (CLIENT) then
	local Name = "Triceratops"
	local LangName = "npc_dino_triceratops"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
	end
	if SERVER then

		--AddCSLuaFile("shared.lua")
		--include('shared.lua')
		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
		ENT.Model = "models/dinosaurs/triceratops.mdl"
		ENT.StartHealth = GetConVarNumber("vj_triceratops_h")
		ENT.MoveType = MOVETYPE_STEP
		ENT.HullType = HULL_LARGE
		---------------------------------------------------------------------------------------------------------------------------------------------
		ENT.VJ_FriendlyNPCsSingle = {"npc_dino_triceratops","npc_dino_hadrosaur","npc_dino_brah"}
		ENT.Bleeds = true -- Does the SNPC bleed? (Blood decal, particle and etc.)
		ENT.BloodParticle = "blood_impact_red_01" -- Particle that the SNPC spawns when it's damaged
		ENT.BloodDecal = "Blood" -- (Red = Blood) (Yellow Blood = YellowBlood) | Leave blank for none
		ENT.BloodDecalRate = 1000 -- The more the number is the more chance is has to spawn | 1000 is a good number for yellow blood, for red blood 500 is good | Make the number smaller if you are using big decal like Antlion Splat, Which 5 or 10 is a really good number for this stuff
		ENT.HasMeleeAttack = true -- Should the SNPC have a melee attack?
		ENT.Immune_CombineBall = true
		ENT.Immune_Physics = true
		ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1} -- Melee Attack Animations
		ENT.MeleeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
		ENT.MeleeAttackDistance = 85 -- How close does it have to be until it attacks?
		ENT.MeleeAttackDamageDistance = 180 -- How far the damage goes
		ENT.MeleeDistanceB = 85 -- Sometimes 45 is a good number but Sometimes needs a change
		ENT.TimeUntilMeleeAttackDamage = 0.8 -- This counted in seconds | This calculates the time until it hits something
		ENT.NextAnyAttackTime_Melee = 0.7 -- How much time until it can use a attack again? | Counted in Seconds
		ENT.MeleeAttackDamage = GetConVarNumber("vj_triceratops_d")
		ENT.MeleeAttackDamageType = DMG_SLASH -- Type of Damage
		ENT.HasFootStepSound = true -- Should the SNPC make a footstep sound when it's moving?
		ENT.FootStepTimeRun = 1 -- Next foot step sound when it is running
		ENT.FootStepTimeWalk = 1 -- Next foot step sound when it is walking
		ENT.PlayerFriendly = true -- When true, it will still attack If you attack to much, also this will make it friendly to rebels and characters like that
		ENT.BecomeEnemyToPlayer = true -- Should the friendly SNPC become enemy towards the player if it's damaged by a player?
		ENT.BecomeEnemyToPlayerLevel = 4 -- How many times does the player have to hit the SNPC for it to become enemy?
			-- ====== Flinching Code ====== --
		ENT.Flinches = 0 -- 0 = No Flinch | 1 = Flinches at any damage | 2 = Flinches only from certain damages
		ENT.FlinchingChance = 14 -- chance of it flinching from 1 to x | 1 will make it always flinch
		ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS} -- If self.FlinchUseACT is false the it uses this | Common: SCHED_BIG_FLINCH, SCHED_SMALL_FLINCH, SCHED_FLINCH_PHYSICS
			-- ====== Sound File Paths ====== --
		-- Leave blank if you don't want any sounds to play
		ENT.SoundTbl_FootStep = {"t-rex_jp/step1.ogg","t-rex_jp/step2.ogg","t-rex_jp/step3.ogg"}
		ENT.SoundTbl_Idle = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_Alert = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_MeleeAttack = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_Pain = {"Triceratops/TricCall01.ogg"}
		ENT.SoundTbl_Death = {"Triceratops/TricCall03.ogg"}
		---------------------------------------------------------------------------------------------------------------------------------------------
		function ENT:CustomInitialize()
			self:SetCollisionBounds(Vector(120, 40, 80), -Vector(50, 40, 0))
		end


		--[[-----------------------------------------------
			*** Copyright (c) 2012-2015 by DrVrej, All rights reserved. ***
			No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
			without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
		----------------------------------------------- ]]
	end
	scripted_ents.Register(ENT, ENT.ClassName)
	list.Set("NPC",ENT.ClassName,{
		Name = ENT.ClassName,
		Class = ENT.ClassName,
		Category = "VJ Base",
	})
end
