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

			ply:SendLua([[jrpg.SetRPG(LocalPlayer(), true)]])
		else
			jattributes.Disable(ply)

			ply:SetHealth(100) -- fix to no health after removing rpg
			ply:SetMaxHealth(100)

			if ply.SetSuperJumpMultiplier then
				ply:SetSuperJumpMultiplier(1.5)
			end

			ply:SendLua([[jrpg.SetRPG(LocalPlayer(), false)]])

			jrpg.Unloadout(ply)
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
		hook.Run("OnRPGEnabled", ply, cheat)
	else
		hook.Run("OnRPGDisabled", ply)
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

	if ent:GetMaxHealth() <= 1 then
		return true
	end

	return ent:Health() > 0
end

hook.Add("CreateClientsideRagdoll", "jrpg_isalive", function(ent, rag)
	ent.jrpg_rag_ent = rag
end)

hook.Add("OnEntityCreated", "jrpg_isalive", function(ent)
	if ent.GetRagdollOwner and ent:GetRagdollOwner() and ent:GetRagdollOwner():IsValid() then
		ent:GetRagdollOwner().jrpg_rag_ent = ent
	end
end)

function jrpg.GetActorBody(ent)
	if not jrpg.IsActorAlive(ent) then
		if ent:IsPlayer() then
			local rag = ent:GetRagdollEntity()
			if IsValid(rag) then
				return rag
			end
		elseif ent:IsNPC() and IsValid(ent.jrpg_rag_ent) then
			return ent.jrpg_rag_ent
		end
	end

	return ent
end


if SERVER then

	function jrpg.Loadout(ply)
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) then
			ply.jrpg_last_weapon = wep:GetClass()
		end

		ply:Give("weapon_shield_dark_silver")
		ply:Give("potion_health")
		ply:Give("potion_mana")
		ply:Give("potion_stamina")
		for k,v in pairs(jdmg.types) do
			ply:Give("weapon_magic_" .. k)
		end
		ply:Give("weapon_jsword_virtuouscontract")

		ply:SelectWeapon("weapon_jsword_virtuouscontract")

		ply.jrpg_old_speeds = {
			WalkSpeed = ply:GetWalkSpeed(),
			RunSpeed = ply:GetRunSpeed(),
			DuckSpeed = ply:GetDuckSpeed(),
			UnDuckSpeed = ply:GetUnDuckSpeed(),
		}

		ply:SetWalkSpeed(100)
		ply:SetRunSpeed(200)
		ply:SetDuckSpeed(0.5)
		ply:SetUnDuckSpeed(0.5)
	end

	function jrpg.Unloadout(ply)
		SafeRemoveEntity(ply:GetWeapon("weapon_shield_dark_silver"))
		SafeRemoveEntity(ply:GetWeapon("potion_health"))
		SafeRemoveEntity(ply:GetWeapon("potion_mana"))
		SafeRemoveEntity(ply:GetWeapon("potion_stamina"))
		for k,v in pairs(jdmg.types) do
			SafeRemoveEntity(ply:GetWeapon("weapon_magic_" .. k))
		end
		SafeRemoveEntity(ply:GetWeapon("weapon_jsword_virtuouscontract"))

		if ply.jrpg_old_speeds then
			for k,v in pairs(ply.jrpg_old_speeds) do
				ply["Set" .. k](ply, v)
			end
			ply.jrpg_old_speeds = nil
		end

		if ply.jrpg_last_weapon then
			ply:SelectWeapon(ply.jrpg_last_weapon)
			ply.jrpg_last_weapon = nil
		end
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

	if ent:GetMaxHealth() > 0 and ent:Health() > 0 then return true end

	if ent:GetModel() == "models/props_c17/furniturefridge001a.mdl" then return true end
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

function jrpg.IsPhysical(ent)
	if not ent or not ent:IsValid() then return false end
	local class = ent:GetClass()

	if class:StartWith("func_") then
		return false
	end

	return true
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
	function jrpg.IsFriend(_, ent)
		if ent:IsPlayer() and engine.ActiveGamemode() == "lambda" then
			return true
		end

		if ent:GetModel() == "models/props_c17/furniturestove001a.mdl" then
			return true
		end

		if ent == LocalPlayer() then
			return true
		end

		if ent.CanAlter then
			return ent:CanAlter(LocalPlayer())
		end

		if IsFriendEntityName(ent:GetClass()) then
			return true
		end

		if friendly_npcs[ent:GetClass()] then
			return true
		end

		return false
	end
end

if SERVER then
	function jrpg.IsFriend(a, b)
		if jrpg.IsActor(b) and (IsFriendEntityName(b:GetClass()) or friendly_npcs[b:GetClass()]) then
			return true
		end

		return a.IsFriend and a:IsFriend(b)
	end
end

jrpg.FindHeadPos = requirex("find_head_pos")


function jrpg.Get2DBoundingBox(v)
	local min, max = v:OBBMins(), v:OBBMaxs()

	local corners = {
		Vector(min.x, min.y, min.z),
		Vector(min.x, min.y, max.z),
		Vector(min.x, max.y, min.z),
		Vector(min.x, max.y, max.z),
		Vector(max.x, min.y, min.z),
		Vector(max.x, min.y, max.z),
		Vector(max.x, max.y, min.z),
		Vector(max.x, max.y, max.z)
	}

	local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge

	for _, corner in ipairs(corners) do
		local screen = v:LocalToWorld(corner):ToScreen()
		minx,miny = math.min(minx, screen.x),math.min(miny, screen.y)
		maxx,maxy = math.max(maxx, screen.x),math.max(maxy, screen.y)
	end

	return minx, miny, maxx, maxy;
end


FindMetaTable("Player").IsRPG = jrpg.IsEnabled

return jrpg
