jrpg = jrpg or {}

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

if CLIENT then
	function jrpg.IsFriend(ent)
		return ent == LocalPlayer() or ent:IsPlayer() and ent:GetFriendStatus() == "friend" or IsFriendEntityName(ent:GetClass())
	end
end

if SERVER then
	function jrpg.IsFriend(a, b)
		if b:IsNPC() and IsFriendEntityName(b:GetClass()) then
			return true
		end

		return a:IsFriend(b)
	end
	
	local function loadout(ply)
		ply:Give("weapon_shield_scanner")
		ply:Give("magic")
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
			loadout(ply)
			ply:SendLua([[if battlecam and not battlecam.IsEnabled() then battlecam.Enable() end]])
			ply:ChatPrint("RPG: Enabled")
		else
			jattributes.Disable(ply)
			ply:SendLua([[if battlecam and battlecam.IsEnabled() then battlecam.Disable() end]])
			ply:ChatPrint("RPG: Disabled")
		end

		ply.rpg_cheat = cheat
	end
	FindMetaTable("Player").SetRPG = jrpg.SetRPG
end

function jrpg.FindHeadPos(ent)
	if not ent.bc_head or ent.bc_last_mdl ~= ent:GetModel() then
		for i = 0, ent:GetBoneCount() or 0 do
			local name = ent:GetBoneName(i):lower()
			if name:find("head") then
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
				return pos
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
