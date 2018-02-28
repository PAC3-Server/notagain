AddCSLuaFile()

jrpg = jrpg or {}

jrpg.added_hooks = jrpg.added_hooks or {}
jrpg.timers = jrpg.timers or {}

function jrpg.AddHook(name, id, func)
	id = "jrpg_" .. id

	jrpg.added_hooks[name .. id] = {name, id, func}

	if jrpg.IsEnabled() then
		hook.Add(name, id, func)
	end
end

function jrpg.AddPlayerHook(name, id, func)
	jrpg.AddHook(name, id, function(ply, ...)
		if jrpg.IsEnabled(ply) then
			return func(ply, ...)
		end
	end)
end

function jrpg.CreateTimer(id, rate, reps, func)
	id = "jrpg_" .. id

	jrpg.timers[id] = {id, rate, reps, func}

	if jrpg.IsEnabled() then
		timer.Create(id, rate, reps, func)
	end
end

function jrpg.RemoveTimer(id)
	id = "jrpg_" .. id

	jrpg.timers[id] = nil

	timer.Remove(id)
end

function jrpg.RemoveHook(name, id)
	id = "jrpg_" .. id

	jrpg.added_hooks[name .. id] = nil

	hook.Remove(name, id, func)
end

function jrpg.IsEnabled(ent)
	if ent then
		return ent.GetNWBool and ent:GetNWBool("jrpg", false)
	end

	return jrpg.enabled
end


function jrpg.SetRPG(ply, b, cheat)

	if SERVER then
		ply:SetNWBool("jrpg", b)

		if b then
			if engine.ActiveGamemode() == "sandbox" then
				jrpg.Loadout(ply)
			end

			jattributes.SetTable(ply)
			jlevel.LoadStats(ply)

			ply:SetHealth(ply:GetMaxHealth())

			jattributes.SetMana(ply, jattributes.GetMaxMana(ply))
			jattributes.SetStamina(ply, jattributes.GetMaxStamina(ply))

			if ply.SetSuperJumpMultiplier then
				ply:SetSuperJumpMultiplier(1)
			end

			hook.Run("OnRPGEnabled", ply, cheat)
			ply:SendLua([[jrpg.SetRPG(LocalPlayer(), true)]])
		else
			jattributes.Disable(ply)

			ply:SetHealth(100) -- fix to no health after removing rpg
			ply:SetMaxHealth(100)

			if ply.SetSuperJumpMultiplier then
				ply:SetSuperJumpMultiplier(1.5)
			end

			hook.Run("OnRPGDisabled", ply)
			ply:SendLua([[jrpg.SetRPG(LocalPlayer(), false)]])
		end

		ply.rpg_cheat = cheat
	end

	if CLIENT then
		jrpg.enabled = b

		if engine.ActiveGamemode() == "sandbox" then
			if b then
				if battlecam and not battlecam.IsEnabled() then
					battlecam.Enable()
				end
			else
				if battlecam and battlecam.IsEnabled() then
					battlecam.Disable()
				end
			end
		end
	end

	if b then
		for k,v in pairs(jrpg.added_hooks) do
			hook.Add(v[1], v[2], v[3])
		end

		for k,v in pairs(jrpg.timers) do
			timer.Create(v[1], v[2], v[3], v[4])
		end

		jrpg.enabled = true
	else
		if SERVER then
			for k,v in ipairs(player.GetAll()) do
				if jrpg.IsEnabled(v) then
					return
				end
			end
		end

		for k,v in pairs(jrpg.added_hooks) do
			hook.Remove(v[1], v[2])
		end

		for k,v in pairs(jrpg.timers) do
			timer.Remove(v[1])
		end

		jrpg.enabled = false
	end
end

FindMetaTable("Player").SetRPG = jrpg.SetRPG

if CLIENT then
	function jrpg.SafeDraw(pre, post, draw)
		return function(...)
			pre()
			xpcall(draw, ErrorNoHalt, ...)
			post()
		end
	end
end

function jrpg.IsActorAlive(ent)
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

jrpg.AddHook("OnEntityCreated", "jrpg_isalive", function(ent)
	if ent.GetRagdollOwner and ent:GetRagdollOwner() and ent:GetRagdollOwner():IsValid() then
		ent:GetRagdollOwner().jrpg_rag_ent = ent
	end
end)



if SERVER then

	function jrpg.Loadout(ply)
		ply:Give("weapon_shield_soldiers")
		ply:Give("potion_health")
		ply:Give("potion_mana")
		ply:Give("potion_stamina")
		ply:Give("weapon_magic")
		ply:Give("weapon_jsword_virtuouscontract")

		ply:SelectWeapon("weapon_jsword_virtuouscontract")

		ply:SetWalkSpeed(100)
		ply:SetRunSpeed(200)
		ply:SetDuckSpeed(0.5)
		ply:SetUnDuckSpeed(0.5)
	end

	jrpg.AddPlayerHook("PlayerLoadout", "loadout", function(ply)
		jrpg.Loadout(ply)
	end)
end

if engine.ActiveGamemode() == "sandbox" then
	jrpg.AddPlayerHook("PlayerSpawn", "rpg_loadout", function(ply)
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
	["npc_furniture"] = true,
}

function jrpg.IsActor(ent)
	if not ent or not ent:IsValid() then return false end

	if ent:GetClass() == "mount_base" then return true end

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
	mount_base = true,
}

function jrpg.GetRoomSize(pos, filter)
	local is_player
	if type(pos) == "Player" then
		if jrpg.last_room_size_time and jrpg.last_room_size_time > RealTime() then
			return jrpg.last_room_size or 30
		end
		filter = ents.FindInSphere(pos:WorldSpaceCenter(), pos:BoundingRadius()/2)
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
		if jrpg.IsActor(b) and (IsFriendEntityName(b:GetClass()) or friendly_npcs[b:GetClass()]) then
			return true
		end

		return a:IsFriend(b)
	end
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

FindMetaTable("Player").IsRPG = jrpg.IsEnabled

return jrpg
