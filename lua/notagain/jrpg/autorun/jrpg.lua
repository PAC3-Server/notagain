jrpg = jrpg or {}

function jrpg.IsAlive(ent)
	if ent.Alive then
		if ent:IsPlayer() then
			return ent:Alive()
		end
	end

	if ent:IsNPC() and IsValid(ent.jrpg_rag_ent) then
		return false
	end

	return ent:Health() > 0
end

hook.Add("OnEntityCreated", "jrpg_isalive", function(ent)
	if ent.GetRagdollOwner and ent:GetRagdollOwner() and ent:GetRagdollOwner():IsValid() then
		ent:GetRagdollOwner().jrpg_rag_ent = ent
	end
end)

function jrpg.Loadout(ply)
	ply:Give("weapon_shield_soldiers")
	ply:Give("potion_health")
	ply:Give("potion_mana")
	ply:Give("potion_stamina")
	ply:Give("weapon_jsword_virtuouscontract")
	ply:Give("magic")

	ply:SelectWeapon("weapon_jsword_virtuouscontract")
end

if engine.ActiveGamemode() == "sandbox" then
	hook.Add("PlayerSpawn", "rpg_loadout", function(ply)
		if not ply:GetNWBool("rpg") then return end
		timer.Simple(0.1, function()
			jrpg.Loadout(ply)
		end)
	end)
end

do
	local male_bbox = Vector(22.291288, 20.596443, 72.959808)
	local female_bbox = Vector(21.857199, 20.744711, 71.528900)

	function jrpg.GetGender(ent)
		if not ent:GetModel() then return end

		local seq = ent:LookupSequence("walk_all")

		if seq and seq > 0 then
			local info = ent:GetSequenceInfo(seq)
			if info.bbmax == male_bbox then
				return "male"
			elseif info.bbmax == female_bbox then
				return "female"
			end
		end

		if
			ent:GetModel():lower():find("female") or
			ent:LookupBone("ValveBiped.Bip01_R_Pectoral") or
			ent:LookupBone("ValveBiped.Bip01_R_Latt") or
			ent:LookupBone("ValveBiped.Bip01_L_Pectoral") or
			ent:LookupBone("ValveBiped.Bip01_L_Latt")
		then
			return "female"
		end

		return "male"
	end
end

function jrpg.GetFriendlyName(ent)
	local name

	if ent:IsPlayer() then
		name = (string.gsub(ent:Nick(),"<.->",""))
	else
		name = ent:GetClass()

		local npcs = ents.FindByClass(name)

		if npcs[2] then
			for i, other in ipairs(npcs) do
				other.jrpg_name_letter = string.char(64 + i%26)
			end
		end

		if language.GetPhrase(name) then
			name = language.GetPhrase(name)
		end

		if ent.jrpg_name_letter then
			name = name .. " " .. ent.jrpg_name_letter
		end
	end

	return name
end

local blacklist = {
	["class C_HL2MPRagdoll"] = true,
}

function jrpg.IsActor(ent)
	if not ent or not ent:IsValid() then return false end

	if blacklist[ent:GetClass()] then return end
	if ent:EntIndex() == -1 then return end
	if ent:IsWeapon() then return false end
	if ent:GetParent():IsPlayer() or ent:GetOwner():IsPlayer() then return false end
	if ent:GetParent():IsNPC() or ent:GetOwner():IsNPC() then return false end

	if ent:IsNPC() or ent:IsPlayer() then
		return true
	end

	local bone_count = ent:GetBoneCount() or 0

	if bone_count > 1 then

		local found = false

		for i = 0, bone_count do
			local name = ent:GetBoneName(i)
			if name then
				name = name:lower()
				if name:find("head", nil, true) or name:find("neck", nil, true) then
					found = true
					break
				end
			end
		end

		return found
	end

	if ent:GetMaxHealth() < 1 then
		return false
	end

	return false
end

local friendly_npcs = {
	monster_scientist = true,
	monster_barney = true,
}

function jrpg.GetRoomSize(pos, filter)
	local is_player
	if type(pos) == "Player" then
		if jrpg.last_room_size_time and jrpg.last_room_size_time > RealTime() then
			return jrpg.last_room_size or 30
		end
		filter = pos
		pos = pos:EyePos()
		is_player = true
	end

	local samples = 100
	local t = {}
	t.start = pos
	t.filter = filter

	local dist = 0

	for i = 1, samples do
		t.endpos = pos + VectorRand() * 1000
		local res = util.TraceLine(t)
		dist = dist + res.HitPos:Distance(pos)
	end

	dist = dist / samples

	if is_player then
		jrpg.last_room_size = dist
		jrpg.last_room_size_time = RealTime() + 1
	end

	return dist
end

if CLIENT then
	function jrpg.IsFriend(ent)
		if ent:IsPlayer() and engine.ActiveGamemode() == "lambda" then
			return true
		end

		return ent == LocalPlayer() or ent:IsPlayer() and (ent.CanAlter and (LocalPlayer():CanAlter(ent) and ent:CanAlter(LocalPlayer()))) or IsFriendEntityName(ent:GetClass()) or friendly_npcs[ent:GetClass()]
	end
end

if SERVER then
	function jrpg.IsFriend(a, b)
		if b:IsNPC() and (IsFriendEntityName(b:GetClass()) or friendly_npcs[b:GetClass()]) then
			return true
		end

		return a:IsFriend(b)
	end

	function jrpg.SetRPG(ply, b, cheat)
		ply:SetNWBool("rpg", b)
		if b then
			hook.Run("OnRPGEnabled",ply,cheat)
		else
			hook.Run("OnRPGDisabled",ply)
		end
		if ply:GetNWBool("rpg") then
			jattributes.SetTable(ply, {mana = 75, stamina = 25, health = 100})
			jlevel.LoadStats(ply)
			ply:SetHealth(ply:GetMaxHealth())
			jattributes.SetMana(ply, jattributes.GetMaxMana(ply))
			jattributes.SetStamina(ply, jattributes.GetMaxStamina(ply))

			if engine.ActiveGamemode() == "sandbox" then
				jrpg.Loadout(ply)
				ply:SendLua([[if battlecam and not battlecam.IsEnabled() then battlecam.Enable() end]])
				ply:ChatPrint("RPG: Enabled")
			end

			if ply.SetSuperJumpMultiplier then
				ply:SetSuperJumpMultiplier(1)
			end
		else
			jattributes.Disable(ply)
			ply:SetHealth(100) -- fix to no health after removing rpg
			ply:SetMaxHealth(100)
			ply:SendLua([[if battlecam and battlecam.IsEnabled() then battlecam.Disable() end]])
			ply:ChatPrint("RPG: Disabled")
			if ply.SetSuperJumpMultiplier then
				ply:SetSuperJumpMultiplier(1.5)
			end
		end

		ply.rpg_cheat = cheat
	end
	FindMetaTable("Player").SetRPG = jrpg.SetRPG
end

function jrpg.FindHeadPos(ent)
	if not ent.bc_head or ent.bc_last_mdl ~= ent:GetModel() then
		for i = 0, ent:GetBoneCount() or 0 do
			local name = ent:GetBoneName(i):lower()
			if name:find("head", nil, true) then
				ent.bc_head = i
				ent.bc_last_mdl = ent:GetModel()
				break
			end
		end
	end

	if ent.bc_head then
		local m = ent:GetBoneMatrix(ent.bc_head)
		if m then
			local pos = m:GetTranslation()
			if pos ~= ent:GetPos() then
				return pos, m:GetAngles()
			end
		end
	end

	return ent:EyePos(), ent:EyeAngles()
end

function jrpg.IsRPG(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	return ply:GetNWBool("rpg",false)
end

FindMetaTable("Player").IsRPG = jrpg.IsRPG
