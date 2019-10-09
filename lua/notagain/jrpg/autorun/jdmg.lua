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
		function META:GetAmount()
			local target = self.entity:GetNWFloat("jdmg_status_" .. META.Name, 0)

			if SERVER then
				return target
			end

			if target == 0 then return target end

			self.smooth_amount = self.smooth_amount or target
			self.smooth_amount = self.smooth_amount + ((target - self.smooth_amount) * FrameTime() * 5)

			return self.smooth_amount
		end
		function META:SetAmount(amt) return self.entity:SetNWFloat("jdmg_status_" .. META.Name, amt) end
		function META:AddAmount(amt) self:SetAmount(self:GetAmount() + amt) end

		jdmg.statuses[META.Name] = META
	end

	function jdmg.GetStatuses(ent)
		ent.jdmg_statuses = ent.jdmg_statuses or {}
		return ent.jdmg_statuses
	end

	jdmg.active_status = jdmg.active_status or {}

	local function set_status(ent, status, userdata, b)
		if not jdmg.statuses[status] then ErrorNoHalt("unknown status type " .. status) return end

		ent.jdmg_statuses = ent.jdmg_statuses or {}

		if not b and ent.jdmg_statuses[status] then
			if ent.jdmg_statuses[status].OnStop then
				ent.jdmg_statuses[status]:OnStop(ent)
			end
			ent.jdmg_statuses[status] = nil
			return
		end

		ent.jdmg_statuses[status] = setmetatable(userdata, jdmg.statuses[status])
		ent.jdmg_statuses[status].entity = ent

		table.insert(jdmg.active_status, ent)

		if CLIENT then
			hook.Add("RenderScreenspaceEffects", "jdmg_status_overlay", jrpg.SafeDraw(cam.Start3D, cam.End3D, function()
				for i = #jdmg.active_status, 1, -1 do
					local ent = jdmg.active_status[i]
					if ent:IsValid() and ent.jdmg_statuses and next(ent.jdmg_statuses) then
						for key, status in pairs(ent.jdmg_statuses) do
							if status.DrawOverlay then
								status:DrawOverlay(ent)
							end
						end
					else
						table.remove(jdmg.active_status, i)

						if not jdmg.active_status[1] then
							hook.Remove("RenderScreenspaceEffects", "jdmg_status_overlay")
						end
					end
				end
			end))
		end
		local next_think = 0
		hook.Add("Think", "jdmg_status_update", function()
			local time = RealTime()
			if next_think < time then

				for i = #jdmg.active_status, 1, -1 do
					local ent = jdmg.active_status[i]
					if ent:IsValid() and ent.jdmg_statuses and next(ent.jdmg_statuses) then

						for key, status in pairs(ent.jdmg_statuses) do
							if SERVER then
								if status:GetAmount() < 0.001 then
									status:SetAmount(0)

									if status.OnStop then
										status:OnStop(ent)
									end

									ent.jdmg_statuses[key] = nil

									net.Start("jdmg_status")
										net.WriteEntity(ent)
										net.WriteString(status.Name)
										net.WriteBool(false)
										net.WriteTable({})
									net.Broadcast()

									return
								end
							end

							if not status.started then
								if status.OnStart then
									status:OnStart(ent)
								end
								status.started = true
							end

							if status.Think then
								if not status.last_run or status.last_run < time then
									status:Think(ent, status:GetAmount())
									status.last_run = time + (status.Rate or 0)
								end
							end

							if SERVER then
								status:SetAmount(status:GetAmount() - FrameTime() * 0.5)
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
			local b = net.ReadBool()
			local userdata = net.ReadTable()

			set_status(ent, status, userdata, b)
		end)
	end

	if SERVER then
		util.AddNetworkString("jdmg_status")

		function jdmg.SetStatus(ent, status, amt, userdata)
			userdata = userdata or {}

			net.Start("jdmg_status")
				net.WriteEntity(ent)
				net.WriteString(status)
				net.WriteBool(true)
				net.WriteTable(userdata)
			net.Broadcast()

			set_status(ent, status, userdata, true)

			if jdmg.GetStatuses(ent)[status] then
				jdmg.GetStatuses(ent)[status]:SetAmount(amt)
			end
		end

		function jdmg.ClearStatus(ent)
			for k,v in pairs(jdmg.GetStatuses(ent)) do
				v:SetAmount(0)
			end
		end

		hook.Add("PlayerSpawn", "jdmg_clearstatus", function(ply)
			jdmg.ClearStatus(ply)
		end)

		function jdmg.AddStatus(ent, status, amt, userdata)

			if not jdmg.GetStatuses(ent)[status] then
				userdata = userdata or {}

				net.Start("jdmg_status")
					net.WriteEntity(ent)
					net.WriteString(status)
					net.WriteBool(true)
					net.WriteTable(userdata)
				net.Broadcast()

				set_status(ent, status, userdata, true)
			end

			jdmg.GetStatuses(ent)[status]:AddAmount(amt)
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
		local time = RealTime()
		for i = #active, 1, -1 do
			local data = active[i]

			local f = (data.time - time) / data.duration

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

				local body = jrpg.GetActorBody(data.ent)
				data.type.draw(body, f, data.strength, time + data.time_offset)
			end
		end

		render.SetColorModulation(1,1,1)
		render.ModelMaterialOverride()
		render.SetBlend(1)

		if not active[1] then
			hook.Remove("RenderScreenspaceEffects", "jdmg")
		end
	end

	local lowhealth_mat = jfx.CreateOverlayMaterial("models/effects/portalfunnel2_sheet")

	local function render_lowhealth()
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

		if not low_health[1] then
			hook.Remove("RenderScreenspaceEffects", "jdmg_lowhealth")
		end
	end

	if low_health[1] then
		hook.Add("RenderScreenspaceEffects", "jdmg_lowhealth", jrpg.SafeDraw(cam.Start3D, cam.End3D, render_lowhealth))
	end

	local emitter = ParticleEmitter(vector_origin)

	function jdmg.DamageEffect(ent, type, duration, strength, pos, dir, normal)
		type = jdmg.types[type] or jdmg.types.generic
		duration = duration or 1
		strength = strength or 1
		if type == jdmg.types.generic then
			--debugoverlay.Axis(pos, dir:Angle(), strength+1, 5, true)
			--debugoverlay.Line(pos, pos + normal * strength, 5, Color(255, 255, 255, 255), true)

			jrpg.AddScreenShake(math.min(strength*2, 5), 1, duration*0.5)
			math.randomseed(CurTime())

			jrpg.ImpactEffect(pos, normal, dir, math.Clamp(strength*4, 0.5, 1.25), type.color)
		end

		if type ~= jdmg.types.generic then
			jrpg.ImpactEffect(pos, normal, dir, math.Clamp(strength*4, 0.5, 1.25), type.color)

			local active = {}
			for i = 1, math.random(3,5) do

				local p = emitter:Add("particle/fire", pos)
				p:SetStartSize(0)
				p:SetEndSize(0)
				p:SetCollide(true)
				p:SetVelocity(normal*100 + VectorRand()*40)
				p:SetGravity(VectorRand()*100)
				p:SetLifeTime(0)
				p:SetDieTime((math.Rand(0.1,0.75)^5) * 5)
				active[i] = {p = p, size=math.Rand(2.5,6)*math.max(strength, 5), ent = ClientsideModel("models/XQM/Rails/gumball_1.mdl")}
				local e = active[i].ent
				e:SetModelScale(0)
			end
			local key = tostring({})
			hook.Add("RenderScreenspaceEffects", key, function()
				math.randomseed(CurTime())
				cam.Start3D()

				local ok = false
				for i,v in ipairs(active) do
					local f = math.Clamp(-(v.p:GetLifeTime() / v.p:GetDieTime())+1, 0, 1)

					if f > 0 then
						ok = true
						v.ent:SetPos(v.p:GetPos())

						type.draw_projectile(v.ent, v.size*f, false)

					else
						SafeRemoveEntity(v.ent)
					end
				end
				cam.End3D()
				if not ok then
					hook.Remove("RenderScreenspaceEffects", key)
				end
			end)
		end

		if false then
			if ent.jrpg_freeze_frame then
				ent.jrpg_freeze_frame()
			end

			local dummy = ClientsideModel(ent:GetModel())
			dummy:SetPos(ent:GetPos())
			dummy:SetAngles(ent:GetAngles())
			dummy:SetSequence(ent:GetSequence())
			dummy:SetCycle(ent:GetCycle())
			local pos = dummy:GetPos()
			local t = duration*0.25
			dummy.RenderOverride = function(s)
				t = t - FrameTime()
				math.randomseed(CurTime())
				render.SetColorModulation(1000,1000,1000)
				s:SetRenderOrigin(pos + VectorRand() * strength * 0.15 * t)
				s:SetupBones()
				s:DrawModel()
			end

			local old = ent.RenderOverride
			ent.RenderOverride = function() end
			ent.jrpg_freeze_frame = function()
				SafeRemoveEntity(dummy)
				ent.RenderOverride = old
			end

			timer.Simple(duration*0.25, ent.jrpg_freeze_frame)
		end


		table.insert(active, {
			ent = ent,
			type = type,
			duration = duration,
			strength = strength,
			time = RealTime() + duration,
			time_offset = math.random(),
		})

		if #active == 1 then
			hook.Add("RenderScreenspaceEffects", "jdmg", jrpg.SafeDraw(cam.Start3D, cam.End3D, render_jdmg))
		end

		if ent:IsValid() and ent.Health and ent:Health() / ent:GetMaxHealth() < 0.25 then
			table.insert(low_health, ent)

			if low_health[1] then
				hook.Add("RenderScreenspaceEffects", "jdmg_lowhealth", jrpg.SafeDraw(cam.Start3D, cam.End3D, render_lowhealth))
			end
		end
	end

	net.Receive("jdmg", function()
		local ent = net.ReadEntity() -- todo use enums lol
		local type = net.ReadString()
		local duration = net.ReadFloat()
		local strength = net.ReadFloat()
		local pos = net.ReadVector()
		local dir = net.ReadVector()
		local normal = net.ReadVector()

		jdmg.DamageEffect(ent, type, duration, strength, pos, dir, normal)
	end)
end

if SERVER then
	function jdmg.DamageEffect(ent, type, duration, strength, pos, dir, normal)
		type = type or "generic"
		duration = duration or 1
		strength = strength or 1

		local filter = {}
		for k,v in pairs(player.GetAll()) do
			if jrpg.IsEnabled(v) and v:GetPos():Distance(ent:GetPos()) < 1500 * (ent:GetModelScale() or 1) then
				table.insert(filter, v)
			end
		end

		if false and ent:GetPhysicsObject():IsValid() then
			timer.Simple(0, function()
			local phys = ent:GetPhysicsObject()
			local vel = phys:GetVelocity()
			local velang = phys:GetAngleVelocity()

			phys:Sleep()
			phys:EnableMotion(false)
			timer.Simple(duration*0.5, function()
				phys:EnableMotion(true)
				phys:Wake()
				phys:SetVelocity(vel)
				phys:AddAngleVelocity(velang)
			end)
		end)
		end

		net.Start("jdmg", true)
			net.WriteEntity(ent)
			net.WriteString(type)
			net.WriteFloat(duration)
			net.WriteFloat(strength)
			net.WriteVector(pos or vector_origin)
			net.WriteVector(dir or vector_origin)
			net.WriteVector(normal or vector_origin)
		net.Send(filter)
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

		local pos = dmginfo:GetDamagePosition()
		local dir = dmginfo:GetDamageForce()

		local t = {
			start = pos - dir:GetNormalized() * 10,
			endpos = pos + dir:GetNormalized() * 10,
		}
		local t = util.TraceLine(t)

		local normal
		if t.Entity == ent and not t.HitNormal:IsZero() then
			normal = t.HitNormal
		else
			normal = dir:GetNormalized()
		end

		--debugoverlay.Line(t.start, t.endpos, 5, Color(255, 255, 0,255))

		local type = dmginfo:GetDamageType()
		local dmg = dmginfo:GetDamage()
		local max_health = math.max(ent:GetMaxHealth(), 1)
		local fraction = math.abs(dmg)/max_health

		local duration = math.Clamp(math.abs(dmg)/50, 0.5, 4)
		local strength = math.max((fraction^0.5) * 2, 0.5)

		local override = jdmg.GetDamageType(dmginfo)

		if override then
			jdmg.DamageEffect(ent, override, duration, strength, pos, dir, normal)
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

					jdmg.DamageEffect(ent, jdmg_name, duration, strength, pos, dir, normal)

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

local function register_elemental(what)
	local SWEP = {}
	SWEP.Base = "weapon_magic"
	SWEP.ClassName = "weapon_magic_" .. what
	SWEP.PrintName = what
	SWEP.Spawnable = true

	if SERVER then
		function SWEP:Initialize()
			self.BaseClass.Initialize(self)
			wepstats.AddToWeapon(self, nil,nil, what)
		end
	end

	weapons.Register(SWEP, SWEP.ClassName)
end

timer.Simple(0.1, function()
	for k,v in pairs(jdmg.types) do
		register_elemental(k)
	end
end)