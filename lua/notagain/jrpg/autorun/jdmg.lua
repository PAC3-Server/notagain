jdmg = jdmg or {}

jdmg.types = jdmg.types or {}

local jfx = CLIENT and requirex("jfx")

function jdmg.BuildEnums()
	local magic = 2523

	local list = {}
	for k,v in pairs(jdmg.types) do
		table.insert(list, k)
	end

	jdmg.enums = {}
	jdmg.enums_lookup = {}

	for i, name in ipairs(list) do
		local val = magic + i - 1
		jdmg.enums[name] = val
		jdmg.enums_lookup[val] = name
		_G["JDMG_" .. name:upper()] = val
	end
end

function jdmg.GetDamageType(dmginfo)
	return jdmg.enums_lookup[dmginfo:GetDamageCustom()]
end

do -- status
	jdmg.statuses = {}

	function jdmg.RegisterStatusEffect(META)
		META.__index = META

		function META:GetAttacker() return self.attacker or NULL end
		function META:GetWeapon() return self.weapon or NULL end

		jdmg.statuses[META.Name] = META
	end

	function jdmg.GetStatuses(ent)
		ent.jdmg_statuses = ent.jdmg_statuses or {}
		return ent.jdmg_statuses
	end

	jdmg.active_status = jdmg.active_status or {}

	local function set_status(ent, status, time, userdata)
		if not jdmg.statuses[status] then ErrorNoHalt("unknown status type " .. status) return end

		ent.jdmg_statuses = ent.jdmg_statuses or {}

		local obj = setmetatable(userdata, jdmg.statuses[status])
		obj.duration = time

		ent.jdmg_statuses[status] = {
			stop_time = RealTime() + time,
			duration = time,
			status = obj,
		}

		table.insert(jdmg.active_status, ent)

		local next_think = 0
		hook.Add("RenderScreenspaceEffects", "jdmg_status_overlay", function()
			cam.Start3D()
			for i = #jdmg.active_status, 1, -1 do
				local ent = jdmg.active_status[i]
				if ent:IsValid() and ent.jdmg_statuses and next(ent.jdmg_statuses) then
					for key, info in pairs(ent.jdmg_statuses) do
						if info.status.DrawOverlay then
							info.status:DrawOverlay(ent, (info.stop_time - RealTime()) / info.duration)
						end
					end
				else
					table.remove(jdmg.active_status, i)

					if not jdmg.active_status[1] then
						hook.Remove("Think", "jdmg_status_update")
					end
				end
			end

			cam.End3D()
		end)

		hook.Add("Think", "jdmg_status_update", function()
			local time = RealTime()
			if next_think < time then

				for i = #jdmg.active_status, 1, -1 do
					local ent = jdmg.active_status[i]
					if ent:IsValid() and ent.jdmg_statuses and next(ent.jdmg_statuses) then

						for key, info in pairs(ent.jdmg_statuses) do
							if info.stop_time < time then
								if info.status.OnStop then
									info.status:OnStop(ent)
								end

								ent.jdmg_statuses[key] = nil
							else
								if not info.status.started then
									if info.status.OnStart then
										info.status:OnStart(ent)
									end
									info.status.started = true
								end

								if info.status.Think then
									if not info.status.last_run or info.status.last_run < time then
										info.status:Think(ent, (info.stop_time - time) / info.duration, info.stop_time - time)
										info.status.last_run = time + (info.status.Rate or 0)
									end
								end
							end
						end

					else
						table.remove(jdmg.active_status, i)

						if not jdmg.active_status[1] then
							hook.Remove("Think", "jdmg_status_update")
						end
					end
				end

				next_think = time + 0.05
			end
		end)
	end

	if CLIENT then
		net.Receive("jdmg_status", function()
			local ent = net.ReadEntity()
			if not ent:IsValid() then return end
			local status = net.ReadString()
			local time = net.ReadDouble()
			local userdata = net.ReadTable()

			set_status(ent, status, time, userdata)
		end)
	end

	if SERVER then
		util.AddNetworkString("jdmg_status")

		function jdmg.SetStatus(ent, status, time, userdata)
			userdata = userdata or {}

			net.Start("jdmg_status")
				net.WriteEntity(ent)
				net.WriteString(status)
				net.WriteDouble(time)
				net.WriteTable(userdata)
			net.Broadcast()

			set_status(ent, status, time, userdata)
		end
	end

	do
		local META = {}
		META.Name = "error"
		META.Negative = true

		if CLIENT then
			local jfx = requirex("jfx")

			META.Icon = jfx.CreateMaterial({
				Shader = "UnlitGeneric",
				BaseTexture = "error",
				VertexAlpha = 1,
				VertexColor = 1,
				Additive = 1,
				BaseTextureTransform = "center .5 .5 scale 0.7 0.5 rotate 90 translate 0 0",
			})
		end

		jdmg.RegisterStatusEffect(META)
	end
end

if CLIENT then
	local low_health = jdmg.lowhealth_entities or {}
	local active = jdmg.active_entities or {}

	jdmg.lowhealth_entities = low_health
	jdmg.active_entities = active

	local function render_jdmg()
		cam.Start3D()
		local time = RealTime()
		for i = #active, 1, -1 do
			local data = active[i]

			local f = (data.time - time) / data.duration
			f = f ^ data.pow

			if f <= 0 or not data.ent:IsValid() then
				table.remove(active, i)
			else
				if data.type.think then
					data.type.think(data.ent, f, data.strength, time + data.time_offset)
				end

				if data.ent.pac_parts then
					for k,v in pairs(data.ent.pac_parts) do
						for _, part in ipairs(v:GetChildrenList()) do
							if part.ClassName == "model" and not part:IsHidden() and part:GetEntity():IsValid() then
								data.type.draw(part:GetEntity(), f, data.strength, time + data.time_offset)
							end
						end
					end
				end

				if not jrpg.IsAlive(data.ent) then
					if data.ent:IsPlayer() then
						local rag = data.ent:GetRagdollEntity()
						if IsValid(rag) then
							data.type.draw(rag, f, data.strength, time + data.time_offset)
						end
					elseif data.ent:IsNPC() and IsValid(data.ent.jrpg_rag_ent) then
						data.type.draw(data.ent.jrpg_rag_ent, f, data.strength, time + data.time_offset)
					else
						data.type.draw(data.ent, f, data.strength, time + data.time_offset)
					end
				else
					data.type.draw(data.ent, f, data.strength, time + data.time_offset)
				end
			end
		end

		render.SetColorModulation(1,1,1)
		render.ModelMaterialOverride()
		render.SetBlend(1)

		cam.End3D()

		if not active[1] then
			hook.Remove("RenderScreenspaceEffects", "jdmg")
		end
	end

	local lowhealth_mat = jfx.CreateOverlayMaterial("models/effects/portalfunnel2_sheet")

	local function render_lowhealth()
		cam.Start3D()

		for i = #low_health, 1, -1 do
			local ent = low_health[i]

			if not ent:IsValid() then
				table.remove(low_health, i)
				break
			end

			local f = (ent:Health() / ent:GetMaxHealth())

			if f > 0.25 or f <= 0 then
				table.remove(low_health, i)
				break
			end

			f = f*4
			local rate = ((-f+1) * 10) + 1

			local t = RealTime()*rate%1
			t = -t + 1
			t = t ^ 0.5
			local s = t

			render.SetColorModulation(s*4,s,s)
			render.SetBlend(s)

			jfx.DrawModel(ent)

		end

		cam.End3D()

		if not low_health[1] then
			hook.Remove("RenderScreenspaceEffects", "jdmg_lowhealth")
		end
	end

	if low_health[1] then
		hook.Add("RenderScreenspaceEffects", "jdmg_lowhealth", render_lowhealth)
	end

	function jdmg.DamageEffect(ent, type, duration, strength, pow)
		type = jdmg.types[type] or jdmg.types.generic
		duration = duration or 1
		strength = strength or 1
		pow = pow or 3

		table.insert(active, {
			ent = ent,
			type = type,
			duration = duration,
			strength = strength,
			pow = pow,
			time = RealTime() + duration,
			time_offset = math.random(),
		})

		if #active == 1 then
			hook.Add("RenderScreenspaceEffects", "jdmg", render_jdmg)
		end

		if ent:IsValid() and ent.Health and ent:Health() / ent:GetMaxHealth() < 0.25 then
			table.insert(low_health, ent)

			if low_health[1] then
				hook.Add("RenderScreenspaceEffects", "jdmg_lowhealth", render_lowhealth)
			end
		end
	end

	net.Receive("jdmg", function()
		local ent = net.ReadEntity() -- todo use enums lol
		local type = net.ReadString()
		local duration = net.ReadFloat()
		local strength = net.ReadFloat()
		local pos = net.ReadVector()

		if ent:IsPlayer() and type ~= "heal" then
			local name = "flinch_stomach_0" .. math.random(2)
			local bone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Neck")

			if bone and pos:Distance(ent:WorldToLocal(ent:GetBonePosition(bone))) < 20 or pos:Distance(ent:WorldToLocal(ent:EyePos())) < 20 then
				name = "flinch_head_0" .. math.random(2)
			elseif strength > 0.5 then
				name = "flinch_phys_0" .. math.random(2)
			end

			local seq = ent:GetSequenceActivity(ent:LookupSequence(name))
			ent:AnimRestartGesture(GESTURE_SLOT_FLINCH, seq, true)
		end

		jdmg.DamageEffect(ent, type, duration, strength)
	end)
end

if SERVER then
	function jdmg.DamageEffect(ent, type, duration, strength, pos)
		type = type or "generic"
		duration = duration or 1
		strength = strength or 1

		net.Start("jdmg", true)
			net.WriteEntity(ent)
			net.WriteString(type)
			net.WriteFloat(duration)
			net.WriteFloat(strength)
			net.WriteVector(pos or vector_origin)
		net.Broadcast()

		if type ~= "heal" and ent.AddGesture then
			ent:AddGesture(ACT_GESTURE_FLINCH_BLAST)
		end
	end

	util.AddNetworkString("jdmg")

	local lookup = {}
	local enums = {}

	for key, val in pairs(_G) do
		if type(key) == "string" and key:StartWith("DMG_") and type(val) == "number" then
			lookup[val] = key
			enums[key] = val
		end
	end

	hook.Add("EntityTakeDamage", "jdmg", function(ent, dmginfo)
		if ent:GetNoDraw() then return end

		local pos = ent:WorldToLocal(dmginfo:GetDamagePosition())
		local type = dmginfo:GetDamageType()
		local dmg = dmginfo:GetDamage()
		local max_health = math.max(ent:GetMaxHealth(), 1)
		local fraction = math.abs(dmg)/max_health

		local duration = math.Clamp(math.abs(dmg)/50, 0.5, 4)
		local strength = math.max((fraction^0.5) * 2, 0.5)

		local override = jdmg.GetDamageType(dmginfo)

		if override then
			jdmg.DamageEffect(ent, override, duration, strength, pos)
			if override == "lightning" then
				dmginfo:SetDamageType(DMG_DISSOLVE)
			end
		else
			local done = {}
			for k, v in pairs(enums) do
				if bit.band(type, v) > 0 and not done[lookup[v]] then
					local hl2_name = lookup[v]
					local jdmg_name = "generic"

					for name, info in pairs(jdmg.types) do
						if info.translate and info.translate[hl2_name] then
							jdmg_name = name
							break
						end
					end

					jdmg.DamageEffect(ent, jdmg_name, duration, strength, pos)

					done[hl2_name] = true
				end
			end
		end
	end)
end

function jdmg.RegisterDamageType(META)
	local data = {}
	jdmg.types[META.Name] = data

	data.translate = META.DamageTranslate

	if CLIENT then
		data.sounds = META.Sounds
		data.think = META.SoundThink and function(...) META:SoundThink(...) end
		data.draw = META.DrawOverlay and function(...) META:DrawOverlay(...) end
		data.color = META.Color
		data.draw_projectile = function(...) (META.DrawProjectile or jdmg.types.generic.DrawProjectile)(META, ...) end
	end

	if SERVER then
		wepstats.AddBasicElemental(META.Name, META.OnDamage and function(...) META:OnDamage(...) end, META.Adjectives, META.Names, META.DontCopy)
	end

	jdmg.BuildEnums()
end

do
	local dir = "notagain/jrpg/damage_types/"
	for _, name in pairs((file.Find(dir .. "*.lua", "LUA"))) do
		local path = dir .. name

		timer.Simple(0, function() include(path) end)

		if SERVER then
			AddCSLuaFile(path)
		end
	end

	if CLIENT then
		notagain.extra_reload_directories = notagain.extra_reload_directories or {}

		table.insert(notagain.extra_reload_directories, {
			dir = "notagain/jrpg/damage_types/",
			type = "shared",
		})
	end
end

do
	local dir = "notagain/jrpg/status_effects/"
	for _, name in pairs((file.Find(dir .. "*.lua", "LUA"))) do
		local path = dir .. name

		timer.Simple(0, function() include(path) end)

		if SERVER then
			AddCSLuaFile(path)
		end
	end

	if CLIENT then
		notagain.extra_reload_directories = notagain.extra_reload_directories or {}

		table.insert(notagain.extra_reload_directories, {
			dir = "notagain/jrpg/status_effects/",
			type = "shared",
		})
	end
end