local prettytext = requirex("pretty_text")
local glare_mat = Material("sprites/light_ignorez")
local warp_mat = Material("particle/warp2_warp")

local shiny = CreateMaterial(tostring({}) .. os.clock(), "VertexLitGeneric", {
	["$Additive"] = 1,
	--["$Translucent"] = 1,
	--["$VertexAlpha"] = 1,
	--["$VertexColor"] = 1,

	["$Phong"] = 1,
	["$PhongBoost"] = 6,
	["$PhongExponent"] = 5,
	["$PhongFresnelRange"] = Vector(0,0.5,1),
	["$PhongTint"] = Vector(1,1,1),


	["$Rimlight"] = 1,
	["$RimlightBoost"] = 10,
	["$RimlightExponent"] = 5,

	["$BaseTexture"] = "models/debug/debugwhite",
	["$BumpMap"] = "dev/bump_normal",

	Proxies = {
		Equals = {
			SrcVar1 = "$color",
			ResultVar = "$phongtint",
		},
	},
})

local smoke_mat = CreateMaterial(tostring{}, "UnlitGeneric", {
	["$BaseTexture"] = "particle/particle_smokegrenade",
	["$Additive"] = 1,
	["$Translucent"] = 1,
	["$VertexColor"] = 1,
	["$VertexAlpha"] = 1,
	["$IgnoreZ"] = 1,

})

local smoke2_mat = CreateMaterial(tostring{}, "UnlitGeneric", {
	["$BaseTexture"] = "effects/blood_core",
	["$Additive"] = 1,
	["$Translucent"] = 1,
	["$VertexColor"] = 1,
	["$VertexAlpha"] = 1,
	["$IgnoreZ"] = 1,
})

local glare2_mat = CreateMaterial(tostring{}, "UnlitGeneric", {
	["$BaseTexture"] = "particle/fire",
	["$Additive"] = 1,
	["$VertexColor"] = 1,
	["$VertexAlpha"] = 1,
})

local fire_mat = CreateMaterial(tostring{}, "UnlitGeneric", {
	["$BaseTexture"] = "particle/water/watersplash_001a",
	["$Additive"] = 1,
	["$Translucent"] = 1,
	["$VertexColor"] = 1,
	["$VertexAlpha"] = 1,
})

local render_ModelMaterialOverride = render.ModelMaterialOverride
local render_SetColorModulation = render.SetColorModulation	local def = Vector(67,67,67)

local function get_color(ent)
	if not LocalPlayer():GetNWBool("rpg") then
		return Vector(100, 100, 100)
	end

	local color = ent:GetNWVector("wepstats_color", def)

	if color.r < 0 then
		color = color * 1
		local c = HSVToColor((os.clock()*200)%360, 1, 1)
		color.r = c.r
		color.g = c.g
		color.b = c.b
	end

	return color
end

local emitter2d = ParticleEmitter(vector_origin)

local entities = {}
local done = {}

local function add_ent(ent)
	if not done[ent] then
		table.insert(entities, ent)

		function ent:RenderOverride(...)
			local color = get_color(self)
			render_ModelMaterialOverride()
			render_SetColorModulation(1,1,1)
			self:DrawModel()
			render_ModelMaterialOverride(shiny)
			render_SetColorModulation(color.r/700, color.g/700, color.b/700)
			self:DrawModel()
			render_ModelMaterialOverride()
		end

		done[ent] = true
	end
end

local function remove_ent(ent)
	if done[ent] then
		done[ent] = nil
		for i, v in ipairs(entities) do
			if v == ent then
				table.remove(entities, i)
				break
			end
		end
	end
end

hook.Add("OnEntityCreated", "jrpg_items", function(ent)
	if ent:IsWeapon() then
		add_ent(ent)
	end
end)

hook.Add("EntityRemoved", "jrpg_items", remove)

local gradient = Material("gui/center_gradient")


local temp_color = Color(255, 255, 255, 255)

local function TempColor(r,g,b,a)
	temp_color.r = math.min(r, 255)
	temp_color.g = math.min(g, 255)
	temp_color.b = math.min(b, 255)
	temp_color.a = a

	return temp_color
end

hook.Add("HUDPaint", "jrpg_items", function()
	for _, ent in ipairs(entities) do
		if not ent:IsValid() then
			remove_ent(ent)
			break
		end

		if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then continue end

		local pos = ent:WorldSpaceCenter() + Vector(0,0,math.min(ent:BoundingRadius()*1.5, 20))
		local dist = pos:Distance(EyePos())
		pos = pos:ToScreen()
		if pos.visible and dist < 200 then
			surface.SetAlphaMultiplier((-(dist/200) + 1) ^ 0.25)

			local color = get_color(ent)
			color = color * 1.5

			local name = LocalPlayer():GetNWBool("rpg") and ent:GetNWString("wepstats_name", ent:GetClass()) or ent:GetClass()
			local class_name = ent:GetClass()

			if language.GetPhrase(class_name) and language.GetPhrase(class_name) ~= class_name then
				name = name:Replace("CLASSNAME", language.GetPhrase(class_name))
			elseif ent.PrintName and language.GetPhrase(ent.PrintName) and language.GetPhrase(ent.PrintName) ~= ent.PrintName then
				name = name:Replace("CLASSNAME", language.GetPhrase(ent.PrintName))
			elseif ent.PrintName then
				name = name:Replace("CLASSNAME", ent.PrintName)
			else
				class_name = class_name:Replace("weapon_", "")
				class_name = class_name:sub(0, 1):upper() .. class_name:sub(2)
				name = name:Replace("CLASSNAME", class_name)
			end

			local w,h = prettytext.GetTextSize(name, "gabriola", 40, 800, 3)
			local bg_width = w + 100
			surface.SetDrawColor(0,0,0,100)
			surface.SetMaterial(gradient)
			surface.DrawTexturedRect(pos.x - bg_width, pos.y, bg_width * 2, h)

			prettytext.Draw(name, pos.x - w / 2, pos.y, "gabriola", 40, 800, 3, TempColor(color.r, color.g, color.b, 255), true)

			local border = 20
			local x = pos.x
			local y = pos.y + 40
			local key = input.LookupBinding("+use"):upper() or input.LookupBinding("+use")
			local str = key .. "  TAKE"
			local w,h = prettytext.GetTextSize(str, "gabriola", 40, 800, 3)
			local key_width = prettytext.GetTextSize(key, "gabriola", 40, 800, 3)
			local bg_width = w + 100

			surface.SetDrawColor(255,255,255,255)
			draw.RoundedBox(4, x - 27 - border / 2, y + border / 2, border, border, TempColor(25,25,25,255))
			prettytext.Draw(str, x - w / 2, y, "gabriola", 40, 800, 3)

			surface.SetDrawColor(0,0,0,100)
			surface.SetMaterial(gradient)
			surface.DrawTexturedRect(x - bg_width, y, bg_width * 2, h)

			surface.SetAlphaMultiplier(1)
		end
	end
end)

local temp_vec = Vector()
local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite
local render_DrawSprite = render.DrawSprite
local cam_IgnoreZ = cam.IgnoreZ

local render_StartBeam = render.StartBeam
local render_EndBeam = render.EndBeam
local render_AddBeam = render.AddBeam
local math_sin = math.sin
local math_abs = math.abs
local math_random = math.random
local math_abs = math.abs
local math_min = math.min
local math_pi = math.pi
local util_PixelVisible = util.PixelVisible
local CurTime = CurTime

local VectorRand = function()
	temp_vec.x = math_random()*2-1
	temp_vec.y = math_random()*2-1
	temp_vec.z = math_random()*2-1
	return temp_vec
end
local MOVETYPE_VPHYSICS = MOVETYPE_VPHYSICS

local last_frame = 0

local function draw_glow(ent, time, distance, radius, vis, color, vm, wm)
	ent.jrpg_items_random = ent.jrpg_items_random or {}
	ent.jrpg_items_random.rotation = ent.jrpg_items_random.rotation or math_random()*360

	local time = time + ent.jrpg_items_random.rotation

	if not vm then
		cam_IgnoreZ(true)
	end

	local r = radius/8
	local pos = ent:GetBonePosition(1) or ent:GetBonePosition(0) or ent:WorldSpaceCenter()

	if vm then
		pos = vector_origin
	end

	render_SetMaterial(warp_mat)
	render_DrawSprite(pos, 50, 50, TempColor(color.r*2, color.g*2, color.b*2, vis*20), ent.jrpg_items_random.rotation)

	local glow = math_sin(time*5)*0.5+0.5
	render_SetMaterial(glare2_mat)
	render_DrawSprite(pos, r*10, r*10, TempColor(color.r, color.g, color.b, vis*170*glow))
	render_DrawSprite(pos, r*20, r*20, TempColor(color.r, color.g, color.b, vis*170*(glow+0.25)))
	render_DrawSprite(pos, r*30, r*30, TempColor(color.r, color.g, color.b, vis*120*(glow+0.5)))

	if not vm then
		cam_IgnoreZ(false)
	end

	render_SetMaterial(glare_mat)
	render_DrawSprite(pos, r*180, r*50, TempColor(color.r, color.g, color.b, vis*20))

	if distance < 1500 then

		if not ent.jrpg_items_next_emit2 or ent.jrpg_items_next_emit2 < time then
			local emitted = 1
			local attachments = ent:GetAttachments()
			if not attachments then return end
			for _, atch in ipairs(attachments) do
				local pos = ent:GetAttachment(atch.id).Pos

				if vm then
					pos = vector_origin
				else
					if not pos or pos == ent:GetPos() then continue end
				end

				local p = emitter2d:Add(glare2_mat, pos + (VectorRand()*radius*0.5))
				p:SetDieTime(math.Rand(2,4))
				p:SetLifeTime(1)

				p:SetStartSize(math.Rand(2,4))
				p:SetEndSize(0)

				p:SetStartAlpha(0)
				p:SetEndAlpha(255)

				p:SetColor(color.r, color.g, color.b)

				p:SetVelocity(VectorRand()*5)
				p:SetGravity(Vector(0,0,3))
				p:SetAirResistance(30)

				local intensity = color:Length()/100

				if math_random() > 0.2 then
					local p = emitter2d:Add(glare2_mat, pos + (VectorRand()*radius*0.5))
					p:SetDieTime(math.Rand(1,3))
					p:SetLifeTime(1)

					p:SetStartSize(math.Rand(2,4))
					p:SetEndSize(0)

					p:SetStartAlpha(255)
					p:SetEndAlpha(255)

					p:SetVelocity(VectorRand()*3)
					p:SetGravity(Vector(0,0,math.Rand(3,5)))
					p:SetAirResistance(30)

					p:SetNextThink(CurTime())

					local seed = math_random()
					local seed2 = math.Rand(-4,4)

					p:SetThinkFunction(function(p)
						p:SetStartSize(math_abs(math_sin(seed+time*seed2)*3*intensity+math.Rand(0,2)))
						p:SetColor(math.Rand(200/intensity, 255), math.Rand(200/intensity, 255), math.Rand(200/intensity, 255))
						p:SetNextThink(CurTime())
					end)

					if vm then break end
				end
				emitted = emitted + 1
			end
			ent.jrpg_items_next_emit2 = time + (0.1 * emitted) + (vm and 0.4 or 0)
		end

		if not ent.jrpg_items_next_emit or ent.jrpg_items_next_emit < time then
			local attachments = ent:GetAttachments()
			if not attachments then return end
			local emitted = 1
			for _, atch in ipairs(attachments) do
				local pos = ent:GetAttachment(atch.id).Pos
				if vm then
					pos = vector_origin
				else
					if not pos or pos == ent:GetPos() then continue end
				end

				local p = emitter2d:Add(math_random() > 0.5 and smoke_mat or smoke2_mat, pos)
				p:SetDieTime(3)
				p:SetLifeTime(1)

				p:SetStartSize(1)
				p:SetEndSize(15 * (vm and 0.4 or 1))

				p:SetStartAlpha(255*vis)
				p:SetEndAlpha(0)

				p:SetColor(color.r, color.g, color.b)

				p:SetVelocity(VectorRand()*3)

				p:SetRoll(math_random()*360)

				p:SetAirResistance(30)
				emitted = emitted + 1

				if vm then break end
			end
			ent.jrpg_items_next_emit = time + (0.2 * emitted) + (vm and 0.4 or 0)
		end
	end

	if vm or wm then return end

	render_SetMaterial(fire_mat)

	ent.jrpg_item_fade = ent.jrpg_item_fade or 0
	ent.jrpg_item_random = ent.jrpg_item_random or math.Rand(0.5, 1)

	local vel = ent:GetVelocity()
	local fade = 1

	if vel:Length() < 100 then
		vel:Zero()
		fade = math_min(time - ent.jrpg_item_fade, 1) ^ 0.5
	else
		ent.jrpg_item_fade = time
	end

	local ang = vel:Angle()
	local up = ang:Up()
	local right = ang:Right()
	local forward = ang:Forward()

	local max_inner = 5
	local max_outter = 3

	if distance > 1000 then
		max_outter = 1
		max_inner = 2
	end

	for i2 = 1, max_outter do
		ent.jrpg_items_random[i2] = ent.jrpg_items_random[i2] or math.Rand(-1,1)
		local f2 = i2/4
		f2=f2*5+ent.jrpg_items_random[i2]

		render_StartBeam(max_inner)
			for i = 1, max_inner do
				local f = i/max_inner
				local s = math_sin(f*math_pi*2)

				local offset = pos

				if i ~= 1 then
					offset = pos +
					(
						up * -math_sin(f2+time+s*30/max_inner*ent.jrpg_items_random[i2]) +
						right * -math_sin(f2+time+s*30/max_inner*ent.jrpg_items_random[i2]) +
						forward * -(radius/13)*math_abs(math_sin(f2 + time/5)*100)*f*0.5 / (1+vel:Length()/100)
					) * fade * ent.jrpg_item_random
				end

				render_AddBeam(
					offset,
					(-f+1)*radius,
					(f*0.3-time*0.1 + ent.jrpg_items_random[i2]),
					TempColor(color.r, color.g, color.b, 255*f)
				)
			end
		render_EndBeam()
	end
end

local emitter_viewmodel = ParticleEmitter(vector_origin)
emitter_viewmodel:SetNoDraw(true)

hook.Add("RenderScreenspaceEffects", "jrpg_items", function()
	if not LocalPlayer():GetNWBool("rpg") then return end

	render.UpdateScreenEffectTexture()
	local time = RealTime()

	cam.Start3D()
	for _, ent in ipairs(entities) do
		if not ent:IsValid() then
			remove_ent(ent)
			break
		end

		local color = get_color(ent)

		local wm = false

		if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then
			local ply = ent:GetOwner()
			if ply:IsValid() then
				if ply:GetActiveWeapon() ~= ent or (ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer()) then
					continue
				end
			end
			wm = true
		end

		local pos = ent:WorldSpaceCenter()

		ent.jrpg_items_pixvis = ent.jrpg_items_pixvis or util.GetPixelVisibleHandle()
		ent.jrpg_items_pixvis2 = ent.jrpg_items_pixvis2 or util.GetPixelVisibleHandle()

		local radius = ent:BoundingRadius()
		local vis = util_PixelVisible(pos, radius*0.5, ent.jrpg_items_pixvis)

		if vis == 0 and util_PixelVisible(pos, radius*5, ent.jrpg_items_pixvis2) == 0 then continue end

		local distance = pos:Distance(EyePos())
		draw_glow(ent, time, distance, wm and 5 or radius, vis * (wm and 0.25 or 1), color, nil, wm)
	end

	render.SetColorModulation(1,1,1)
	render.ModelMaterialOverride()
	cam.End3D()
end)


local suppress = false
hook.Add("PreDrawPlayerHands", "jrpg_items", function(hands, ent, ply, wep)
	if not LocalPlayer():GetNWBool("rpg") then return end
	render.ModelMaterialOverride()
end)
hook.Add("PreDrawViewModel", "jrpg_items", function(ent, ply, wep)
	if not LocalPlayer():GetNWBool("rpg") then return end
	if not wep then return end
	if suppress then return end

	suppress = true
	ent:DrawModel()
	suppress = false
	local time = RealTime()

	local color = get_color(wep)
	shiny:SetVector("$color2", Vector(color.r/255,color.g/255,color.b/255) * 0.5)

	shiny:SetFloat("$RimlightBoost", 1)

	local old = emitter2d
	emitter2d = emitter_viewmodel

	render.ModelMaterialOverride(shiny)
	suppress = true
	ent:DrawModel()
	suppress = false

	draw_glow(ent, time, 0, 10, 0.2, color, true)

	for i, atch in ipairs(ent:GetAttachments()) do
		local atch = ent:GetAttachment(atch.id)
		local pos, ang = atch.Pos, atch.Ang
		if pos then
			ent.item_highlight_vm_rand_ang = ent.item_highlight_vm_rand_ang or {}
			ent.item_highlight_vm_rand_ang[i] = ent.item_highlight_vm_rand_ang[i] or VectorRand():Angle()

			cam.Start3D(WorldToLocal(EyePos(), EyeAngles(), pos, ang + ent.item_highlight_vm_rand_ang[i]))
			emitter_viewmodel:Draw()
			cam.End3D()
		end
	end

	emitter2d = old

	render.ModelMaterialOverride()
	suppress = false
	shiny:SetFloat("$RimlightBoost", 10)
	shiny:SetVector("$color2", Vector(1,1,1))

	return true
end)

if LocalPlayer():IsValid() then
	for k,v in pairs(ents.GetAll()) do
		if v:IsWeapon() then
			add_ent(v)
		end
	end
end