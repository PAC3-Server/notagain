jdmg = jdmg or {}

local jfx

if CLIENT then
	jfx = requirex("jfx")
end

jdmg.statuses = {}

do
	do
		jdmg.statuses.error = {}
		if CLIENT then
			jdmg.statuses.error.icon = jfx.CreateMaterial({
				Shader = "UnlitGeneric",
				BaseTexture = "error",
				VertexAlpha = 1,
				VertexColor = 1,
				Additive = 1,
				BaseTextureTransform = "center .5 .5 scale 0.7 0.5 rotate 90 translate 0 0",
			})
		end
	end

	do
		jdmg.statuses.poison = {}
		jdmg.statuses.poison.negative = true
		if CLIENT then
			jdmg.statuses.poison.icon = jfx.CreateMaterial({
				Shader = "UnlitGeneric",
				BaseTexture = "sprites/greenspit1",
				VertexAlpha = 1,
				VertexColor = 1,
				Additive = 1,
				BaseTextureTransform = "center .5 .5 scale 0.7 0.7 rotate 0 translate 0 0",
			})
		end
	end

	do
		jdmg.statuses.fire = {}
		jdmg.statuses.fire.negative = true
		if CLIENT then
			jdmg.statuses.fire.icon = jfx.CreateMaterial({
				Shader = "UnlitGeneric",
				BaseTexture = "editor/env_fire",
				VertexAlpha = 1,
				VertexColor = 1,
				BaseTextureTransform = "center 0.45 .1 scale 0.75 0.75 rotate 0 translate 0 0",
			})
		end
	end

	do
		jdmg.statuses.confused = {}
		jdmg.statuses.confused.negative = true
		if CLIENT then
			jdmg.statuses.confused.icon = jfx.CreateMaterial({
				Shader = "UnlitGeneric",
				BaseTexture = "editor/choreo_manager",
				VertexAlpha = 1,
				VertexColor = 1,
				BaseTextureTransform = "center 0.45 .1 scale 0.9 0.9 rotate 0 translate 0 -0.05",
			})
		end
	end

	do
		jdmg.statuses.lightning = {}
		jdmg.statuses.lightning.negative = true
		if CLIENT then
			jdmg.statuses.lightning.icon = jfx.CreateMaterial({
				Shader = "UnlitGeneric",
				BaseTexture = "editor/choreo_manager",
				VertexAlpha = 1,
				VertexColor = 1,
				BaseTextureTransform = "center 0.45 .1 scale 0.9 0.9 rotate 0 translate 0 -0.05",
			})
		end
	end

	do
		jdmg.statuses.frozen = {}
		jdmg.statuses.frozen.negative = true
		if CLIENT then
			jdmg.statuses.frozen.icon = jfx.CreateMaterial({
				Shader = "UnlitGeneric",
				BaseTexture = "editor/env_particles",
				VertexAlpha = 1,
				VertexColor = 1,
				BaseTextureTransform = "center 0.45 .1 scale 0.9 0.9 rotate 0 translate 0 -0.05",
			})

			jdmg.statuses.frozen.on_set = function(self, ent, b)
				if ent ~= LocalPlayer() then return end
				local t = RealTime()
				if b then
					local time = 0
					hook.Add("RenderScreenspaceEffects", "jdmg_decay", function()
						time = time + FrameTime()
						local f = math.min(time, 1) ^ 0.5
						if f ~= 1 then return end

						local hm = math.abs(math.sin(RealTime())^50)
						DrawMaterialOverlay("models/shadertest/shader4", hm*0.02)
					end)
					local played = false
					local function setup_fog()
						local f = math.min(time, 1) ^ 0.5

						render.FogMode(1)
						render.FogStart(-7000*f)
						render.FogEnd(500*f)
						render.FogMaxDensity(0.995*f)
						local hm = Lerp(f, 100, math.abs(math.sin(time + 0.3)^50*100))

						if hm > 50 then
							if not played then
								ent:EmitSound("npc/strider/strider_step4.wav", 75, 70)
								played = true
							end
						else
							played = false
						end

						render.FogColor(hm,hm,hm)

						return true
					end

					self.old_hooks_world = {}
					if hook.GetTable().SetupWorldFog then
						for k,v in pairs(hook.GetTable().SetupWorldFog) do self.old_hooks_world[k] = v hook.Remove("SetupWorldFog", k,v) end
					end

					self.old_hooks_skybox = {}
					if hook.GetTable().SetupSkyboxFog then
						for k,v in pairs(hook.GetTable().SetupSkyboxFog) do self.old_hooks_skybox[k] = v hook.Remove("SetupSkyboxFog", k,v) end
					end

					hook.Add("SetupWorldFog", "jdmg_decay", setup_fog)
					hook.Add("SetupSkyboxFog", "jdmg_decay", setup_fog)
				else
					hook.Remove("RenderScreenspaceEffects", "jdmg_decay")
					hook.Remove("SetupWorldFog", "jdmg_decay")
					hook.Remove("SetupSkyboxFog", "jdmg_decay")

					for k, v in pairs(self.old_hooks_world) do hook.Add("SetupWorldFog", k, v) end
					for k, v in pairs(self.old_hooks_skybox) do hook.Add("SetupSkyboxFog", k, v) end
				end
			end
		end
	end
end

jdmg.types = {}

if CLIENT then
	for k,v in pairs(jdmg.types) do
		if not v.draw_projectile then
			v.draw_projectile = jdmg.types.generic.draw_projectile
		end
	end
end

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
	for name, status in pairs(jdmg.statuses) do
		status.name = name
		status.__index = status
	end

	for _, ent in pairs(ents.GetAll()) do
		if ent.jdmg_statuses then
			for i, v in ipairs(ent.jdmg_statuses) do
				if ent.jdmg_statuses[i].on_set then
					ent.jdmg_statuses[i]:on_set(ent, false)
				end
				ent.jdmg_statuses[i] = setmetatable({}, jdmg.statuses[v.name])

				if ent.jdmg_statuses[i].on_set then
					ent.jdmg_statuses[i]:on_set(ent, true)
				end
			end
		end
	end

	function jdmg.GetStatuses(ent)
		ent.jdmg_statuses = ent.jdmg_statuses or {}
		return ent.jdmg_statuses
	end

	if CLIENT then
		net.Receive("jdmg_status", function()
			local ent = net.ReadEntity()
			if not ent:IsValid() then return end
			local status = net.ReadString()
			local b = net.ReadBool()

			ent.jdmg_statuses = ent.jdmg_statuses or {}

			if b then
				for i, v in ipairs(ent.jdmg_statuses) do
					if v.name == status then
						return
					end
				end

				local status = jdmg.statuses[status]
				if status then
					status.__index = status
					status = setmetatable({}, status)

					if status.on_set then
						status:on_set(ent, true)
					end

					table.insert(ent.jdmg_statuses, status)
				end
			else
				for i, v in ipairs(ent.jdmg_statuses) do
					if v.name == status then
						if v.on_set then
							v:on_set(ent, false)
						end
						table.remove(ent.jdmg_statuses, i)
						break
					end
				end
			end
		end)
	end

	if SERVER then
		util.AddNetworkString("jdmg_status")

		function jdmg.SetStatus(ent, status, b)

			net.Start("jdmg_status", true)
				net.WriteEntity(ent)
				net.WriteString(status)
				net.WriteBool(b)
			net.Broadcast()
		end
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
		type = jdmg.types[type] or types.generic
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
		data.draw_projectile = META.DrawProjectile and function(...) META:DrawProjectile(...) end
	end

	if SERVER then
		wepstats.AddBasicElemental(META.Name, META.OnDamage and function(...) META:OnDamage(...) end, META.Adjectives, META.Names, META.DontCopy)
	end

	jdmg.BuildEnums()
end

local dir = "notagain/jrpg/autorun/damage_types/"
for _, name in pairs((file.Find(dir .. "*.lua", "LUA"))) do
	local path = dir .. name

	timer.Simple(0, function() include(path) end)

	if SERVER then
		AddCSLuaFile(path)
	end
end