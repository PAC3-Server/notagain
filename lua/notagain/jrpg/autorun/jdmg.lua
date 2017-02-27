jdmg = jdmg or {}

local magic = 2523
local i = 0

local ENUM = function(name)
	jdmg["DMG_" .. name] = magic + i
	i = i + 1
end

ENUM("GENERIC")
ENUM("POISON")
ENUM("ICE")
ENUM("WATER")
ENUM("DARK")
ENUM("HOLY")
ENUM("HEAL")
ENUM("FIRE")
ENUM("LIGHTNING")

jdmg.dmg_lookup = {}
for k,v in pairs(jdmg) do
	if k:StartWith("DMG_") then
		jdmg.dmg_lookup[v] = k:sub(5):lower()
	end
end

PrintTable(jdmg.dmg_lookup)

if CLIENT then
	local function create_material(data)
		if type(data) == "string" then
			return Material(data)
		end

		local name = (data.Name or "") .. tostring({})
		local shader = data.Shader
		data.Name = nil
		data.Shader = nil

		local params = {}

		for k, v in pairs(data) do
			if k == "Proxies" then
				params[k] = v
			else
				params["$" .. k] = v
			end
		end

		return CreateMaterial(name, shader, params)
	end

	local types = {}

	do
		--[[
			models/weapons/v_smg1/noise
			particle/particle_smokegrenade
			effects/filmscan256
			effects/splash2
			effects/combineshield/comshieldwall
			models/brokenglass/glassbroken_piece1_mask
			models/alyx/emptool_glow
			models/effects/dust01
			models/effects/portalfunnel2_sheet
			models/effects/comball_sphere
			models/effects/com_shield001a
			models/effects/splode_sheet
			models/player/player_chrome1
			models/props_combine/pipes01
			models/props_combine/introomarea_glassmask
			models/props_combine/tprings_globe_dx70
			models/props_combine/stasisshield_dx7
			models/props_lab/warp_sheet
		]]
		local emitter = ParticleEmitter(vector_origin)

		local function create_mat(tex, override)
			override = override or {}
			return create_material(table.Merge({
				Name = "fire",
				Shader = "VertexLitGeneric",
				Additive = 1,
				Translucent = 1,

				Phong = 1,
				PhongBoost = 0.5,
				PhongExponent = 0.4,
				PhongFresnelRange = Vector(0,0.5,1),
				PhongTint = Vector(1,1,1),


				Rimlight = 1,
				RimlightBoost = 50,
				RimlightExponent = 5,
				BaseTexture = tex,


				BaseTextureTransform = "center .5 .5 scale 0.25 0.25 rotate 90 translate 0 0",

				Proxies = {

					Equals = {
						SrcVar1 = "$color",
						ResultVar = "$phongtint",
					},
				},

				BumpMap = "dev/bump_normal",
			}, override))
		end

		do
			local mat = create_mat("models/effects/portalfunnel2_sheet")

			types.generic = {
				draw = function(ent, f, s, t)
					render.ModelMaterialOverride(mat)
					render.SetColorModulation(s,s,s)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*0.15)
					m:Translate(Vector(1,1,1)*t/5)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end


		do
			local mat = create_mat("effects/filmscan256", {Additive = 0, RimlightBoost = 1})

			types.dark = {
				draw = function(ent, f, s, t)
					if math.random() > 0.5 then
						ent:EmitSound("hl1/fvox/buzz.wav", 75, math.Rand(175,255), f)
					end

					local m = Matrix()
					m:Scale(Vector(1,1,1) + (VectorRand()*0.1) * f)
					ent:EnableMatrix("RenderMultiply", m)

					render.ModelMaterialOverride(mat)
					render.SetColorModulation(-s,-s,-s)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*0.15)
					m:Translate(Vector(1,1,1)*t/5)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()

					ent:DisableMatrix("RenderMultiply")
				end,
			}
		end

		do
			local mat = create_mat("effects/splash2", {Additive = 0, RimlightBoost = 1})

			local sounds = {
				"ambient/levels/coast/coastbird4.wav",
				"ambient/levels/coast/coastbird5.wav",
				"ambient/levels/coast/coastbird6.wav",
				"ambient/levels/coast/coastbird7.wav",
			}

			types.holy = {
				draw = function(ent, f, s, t)
					if math.random() > 0.95 then
						ent:EmitSound(table.Random(sounds), 75, math.Rand(100,120), f)
						ent:EmitSound("friends/friend_join.wav", 75, 255, f)
					end

					render.ModelMaterialOverride(mat)
					render.SetColorModulation(s*6,s*6,s*6)
					render.SetBlend(f)

					ent:DrawModel()
				end,
			}
		end

		do
			local mat = create_mat("models/props_lab/cornerunit_cloud")
			local flames ={}

			for i = 1, 5 do
				table.insert(flames, create_material({
					Shader = "UnlitGeneric",
					BaseTexture = "sprites/flamelet" .. i,
					VertexAlpha = 1,
					VertexColor = 1,
					Additive = 1,
					NoCull = 1,
				}))
			end

			local smoke = {
				"particle/smokesprites0001",
				"particle/smokesprites0067",
				"particle/smokesprites0133",
				"particle/smokesprites0199",
				"particle/smokesprites0265",
				"particle/smokesprites0331",
			}
			for i, path in ipairs(smoke) do
				smoke[i] = create_material({
					Shader = "UnlitGeneric",
					BaseTexture = path,
					VertexAlpha = 1,
					VertexColor = 1,
				})
			end

			types.fire = {
				draw = function(ent, f, s, t)
					if math.random() > 0.98 then
						ent:EmitSound("ambient/fire/mtov_flame2.wav", 75, math.Rand(50,100), f)
					end

					for i = 1, 1 do
						local pos
						local mat = ent:GetBoneMatrix(math.random(1, ent:GetBoneCount()))

						if mat then
							pos = mat:GetTranslation()
						else
							pos = ent:NearestPoint(ent:WorldSpaceCenter()+VectorRand()*100)
						end

						local p = emitter:Add(table.Random(flames), pos)
						p:SetStartSize(math.Rand(5,20))
						p:SetEndSize(math.Rand(5,20))
						p:SetStartAlpha(255*f)
						p:SetEndLength(math.Rand(p:GetEndSize(),20))
						p:SetEndAlpha(0)
						p:SetColor(math.Rand(230,255),math.Rand(230,255),math.Rand(230,255))
						p:SetGravity(physenv.GetGravity()*-0.25)
						p:SetRoll(math.random()*360)
						p:SetAirResistance(5)
						p:SetLifeTime(0.25)
						p:SetDieTime(math.Rand(0.25,0.75))

						if math.random() > 0.95 then
							local p = emitter:Add(table.Random(smoke), pos + VectorRand())
							p:SetStartSize(0)
							p:SetEndSize(math.Rand(50,200))
							p:SetStartAlpha(255*f)
							p:SetEndAlpha(0)
							p:SetVelocity(VectorRand()*5)
							p:SetGravity(physenv.GetGravity()*-0.1)
							p:SetColor(20, 20, 20)
							--p:SetLighting(true)
							p:SetRoll(math.random()*360)
							p:SetAirResistance(100)
							p:SetLifeTime(1)
							p:SetDieTime(math.Rand(0.3,1.5)*5)
						end
					end


					render.ModelMaterialOverride(mat)
					render.SetColorModulation(2*s,1*s,0.5)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*1.5)
					m:Translate(Vector(1,1,1)*t/5)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end

		do
			local mat = create_mat("sprites/lgtning")

			types.lightning = {
				draw = function(ent, f, s, t)
					if math.random() > 0.95 then
						ent:EmitSound("ambient/energy/zap"..math.random(1, 3)..".wav", 75, math.Rand(150,255), f)
					end

					f = 0.1 * f + (f * math.random() ^ 5)

					--t = t + math.Rand(0,0.25)
					f = f + math.Rand(0,1)*f
					s = s + math.Rand(0,1)*f
					t = t + math.Rand(0, 0.25)

					render.ModelMaterialOverride(mat)
					render.SetColorModulation(1*s,1*s,1*s)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*math.Rand(5,20))
					m:Translate(Vector(1,1,1)*t/5)
					m:Rotate(VectorRand():Angle())
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end

		do
			local mat = create_mat("effects/filmscan256")

			types.poison = {
				draw = function(ent, f, s, t)
					if math.random() > 0.95 then
						ent:EmitSound("ambient/levels/canals/toxic_slime_sizzle"..math.random(2, 4)..".wav", 75, math.Rand(120,170), f)
					end

					local pos = ent:GetBoneMatrix(math.random(1, ent:GetBoneCount()))
					if pos then
						pos = pos:GetTranslation()

						local p = emitter:Add("effects/splash1", pos + VectorRand() * 20)
						p:SetStartSize(30)
						p:SetEndSize(30)
						p:SetStartAlpha(50*f)
						p:SetEndAlpha(0)
						p:SetVelocity(VectorRand()*20)
						p:SetGravity(VectorRand()*10)
						p:SetColor(0, 150, 0)
						--p:SetLighting(true)
						p:SetRoll(math.random()*360)
						p:SetAirResistance(100)
						p:SetLifeTime(1)
						p:SetDieTime(math.Rand(0.75,1.5)*2)
					end

					render.ModelMaterialOverride(mat)
					render.SetColorModulation(0,1*s,0)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*0.05)
					m:Translate(Vector(1,1,1)*t/20)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end

		do
			local mat = create_mat("effects/filmscan256")

			local water = {
				"particle/particle_noisesphere",
				"effects/splash1",
				"effects/splash2",
				"effects/splash4",
				"effects/blood",

			}

			types.water = {
				draw = function(ent, f, s, t)
					if math.random() > 0.8 then
						ent:EmitSound("ambient/water/wave"..math.random(1,6)..".wav", 75, math.Rand(200,255), f)
					end

					local pos = ent:GetBoneMatrix(math.random(1, ent:GetBoneCount()))
					if pos then
						pos = pos:GetTranslation()

						local p = emitter:Add(table.Random(water), pos + VectorRand() * 5)
						p:SetStartSize(20)
						p:SetEndSize(20)
						p:SetStartAlpha(50*f)
						p:SetEndAlpha(0)
						p:SetVelocity(VectorRand()*10)
						p:SetGravity(physenv.GetGravity()*0.025)
						p:SetColor(100, 200, 255)
						--p:SetLighting(true)
						p:SetRoll(math.random())
						p:SetRollDelta(math.random()*2-1)
						p:SetLifeTime(1)
						p:SetDieTime(math.Rand(0.75,1.5)*2)
					end

					render.ModelMaterialOverride(mat)
					render.SetColorModulation(0.5,0.75,1*s)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*0.05)
					m:Translate(Vector(1,1,1)*t/20)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end

		do
			local mat = create_mat("effects/filmscan256")

			types.ice = {
				draw = function(ent, f, s, t)
					local pos = ent:NearestPoint(ent:WorldSpaceCenter()+VectorRand()*100)

					local p = emitter:Add("effects/splash1", pos + VectorRand() * 20)
					p:SetStartSize(1)
					p:SetEndSize(0)
					p:SetStartAlpha(50*f)
					p:SetEndAlpha(0)
					p:SetVelocity(VectorRand()*5)
					p:SetGravity(VectorRand()*10)
					p:SetColor(255, 255, 255)
					--p:SetLighting(true)
					p:SetRoll(math.random()*360)
					p:SetGravity(physenv.GetGravity()*0.1)
					p:SetAirResistance(100)
					p:SetLifeTime(1)
					p:SetDieTime(math.Rand(0.75,1.5)*2)


					render.ModelMaterialOverride(mat)
					render.SetColorModulation(0.5,0.75, 1*s)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*0.05)
					m:Translate(Vector(1,1,1)*t/20)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end


		do
			local mat = create_mat("effects/filmscan256")

			types.heal = {
				draw = function(ent, f, s, t)
					if math.random() > 0.99 then
						ent:EmitSound("items/smallmedkit1.wav", 75, math.Rand(230,235), f)
					end

					render.ModelMaterialOverride(mat)
					render.SetColorModulation(0.75, 1*s, 0.75)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*0.05)
					m:Translate(Vector(1,1,1)*t/20)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end
	end

	local active = {}

	local function render_jdmg()
		cam.Start3D()
		local time = RealTime()
		for i = #active, 1, -1 do
			local data = active[i]

			local f = (data.time - time) / data.duration
			f = f ^ data.pow

			if f <= 0 or not data.ent:IsValid()  then
				table.remove(active, i)
			else
				data.type.draw(data.ent, f, data.strength, time + data.time_offset)
			end
		end

		render.SetColorModulation(1,1,1)
		render.ModelMaterialOverride()
		render.SetBlend(1)

		if not active[1] then
			hook.Remove("RenderScreenspaceEffects", "jdmg")
		end
		cam.End3D()
	end

	function jdmg.DamageEffect(ent, type, duration, strength, pow)
		type = types[type] or types.generic
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
	end

	net.Receive("jdmg", function()
		local ent = net.ReadEntity() -- todo use enums lol
		local type = net.ReadString()
		local duration = net.ReadFloat()
		local strength = net.ReadFloat()

		jdmg.DamageEffect(ent, type, duration, strength)
	end)
end

if SERVER then
	function jdmg.DamageEffect(ent, type, duration, strength)
		type = type or "generic"
		duration = duration or 1
		strength = strength or 1

		net.Start("jdmg", true)
			net.WriteEntity(ent)
			net.WriteString(type)
			net.WriteFloat(duration)
			net.WriteFloat(strength)
		net.Broadcast()
	end

	util.AddNetworkString("jdmg")

	local lookup = {}
	local enums = {}

	for key, val in pairs(_G) do
		if type(key) == "string" and key:StartWith("DMG_") and type(val) == "number" then
			lookup[val] = key:match("^DMG_(.+)"):lower()
			enums[key] = val
		end
	end

	lookup[DMG_BURN] = "fire"
	lookup[DMG_SLOWBURN] = "fire"
	lookup[DMG_SHOCK] = "lightning"
	lookup[DMG_ACID] = "poison"
	lookup[DMG_DROWN] = "water"
	lookup[DMG_ENERGYBEAM] = "lightning"
	lookup[DMG_NERVEGAS] = "poison"
	lookup[DMG_RADIATION] = "poison"

	hook.Add("EntityTakeDamage", "jdmg", function(ent, dmginfo)
		local type = dmginfo:GetDamageType()
		local dmg = dmginfo:GetDamage()
		local max_health = math.max(ent:GetMaxHealth(), 1)
		local fraction = dmg/max_health

		local duration = math.Clamp(fraction^0.25, 0.5, 2)
		local strength = math.max((fraction^0.5) * 2, 0.5)

		local override = jdmg.dmg_lookup[dmginfo:GetDamageCustom()]

		if override then
			print(ent, override, duration, strength)
			jdmg.DamageEffect(ent, override, duration, strength)
		else
			local done = {}
			for k, v in pairs(enums) do
				if bit.band(type, v) > 0 and not done[lookup[v]] then
					local str = lookup[v]
					jdmg.DamageEffect(ent, str, duration, strength)
					done[str] = true
				end
			end
		end
	end)
end