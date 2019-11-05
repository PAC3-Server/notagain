local jhud = _G.jhud or {}
_G.jhud = jhud

local draw_rect = requirex("draw_skewed_rect")
local prettytext = requirex("pretty_text")

local gradient = CreateMaterial(tostring({}), "UnlitGeneric", {
	["$BaseTexture"] = "gui/center_gradient",
	["$BaseTextureTransform"] = "center .5 .5 scale 1 1 rotate 90 translate 0 0",
	["$VertexAlpha"] = 1,
	["$VertexColor"] = 1,
	["$Additive"] = 0,
})
local border = CreateMaterial(tostring({}), "UnlitGeneric", {
	["$BaseTexture"] = "props/metalduct001a",
	["$VertexAlpha"] = 1,
	["$VertexColor"] = 1,
})

local smoothers = {}
local function smooth(var, id)
	smoothers[id] = smoothers[id] or var
	smoothers[id] = smoothers[id] + ((var - smoothers[id]) * FrameTime() * 5)
	return smoothers[id]
end
local last_hp_timer = 0
local border_size = 2
local skew = 20
local health_height = 14
local no_texture = Material("vgui/white")

function jhud.DrawBar(x,y,w,h,cur,max,border_size, r,g,b, a)
	local skew = skew/1.5

	render.SetColorModulation(0,0,0)
	render.SetBlend(0.980)
	render.SetMaterial(no_texture)
	draw_rect(x,y,w,h, skew)

	render.SetColorModulation(r,g,b)
	render.SetMaterial(gradient)
	render.SetBlend(1)
	draw_rect(x,y,w * (cur/max),h, skew, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())

	render.SetMaterial(border)
	render.SetColorModulation(1,1,1)
	render.SetBlend(1)
	draw_rect(x,y,w,h, skew, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)
end

local width = 100
local spacing = 3
local color_white = Color(255, 255, 255, 255)
function jhud.DrawInfoSmall(ply, x, y, alpha, color, no_avatar, width_override)
	local S = ScrW() / 1920
	local width = 100*S
	local spacing = 3*S
	S = S * 0.9

	if width_override then
		width = width_override*S
	end

	alpha = alpha or 1
	color = color or color_white

	if not no_avatar then
	surface.DisableClipping(true)
	render.ClearStencil()
	render.SetStencilEnable(true)
	render.SetStencilWriteMask(255)
	render.SetStencilTestMask(255)
	render.SetStencilReferenceValue(15)
	render.SetStencilFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
	render.SetBlend(0)
	surface.SetDrawColor(0,0,0,1)
	draw.NoTexture()
	surface.DrawRect(x-width-100*S,y-width, width + 200*S, width+70*S)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
	end
	surface.SetAlphaMultiplier(alpha)
	if not no_avatar then
		local cur = ply:Health()
		local max = ply:GetMaxHealth()
		local critical = (cur/max)
		if critical < 0.5 then
			critical = critical + math.sin(os.clock() * (2/critical))*0.5+0.5
			critical = critical ^ 0.5
		else
			critical = 1
		end
		local lost = 0
		if smoothers["health"..ply:EntIndex()] then
			lost = math.max(smoothers["health"..ply:EntIndex()] - math.max(ply:Health(), 0), 0)
		end
		lost = lost + 1
		x = x + math.Rand(-1,1) * (lost-1)
		y = y + math.Rand(-1,1) * (lost-1)
		surface.SetDrawColor(255,critical*255/lost,critical*255/lost,255)
		avatar.Draw(ply, x-80*S,y+15*S, width/1.5)
	end
	local health_height = 8
	x = x - 50
	y = y + 20
	local c = color or team.GetColor(TEAM_FRIENDS)
	c.r = c.r/3
	c.g = c.g/3
	c.b = c.b/3
	c.a = 255
	local name = jrpg and jrpg.GetFriendlyName(ply) or (string.gsub(ply:Nick(),"<.->",""))
	prettytext.Draw(name,x + 10,y,"Square721 BT",20,0,3,Color(255,255,255,255*alpha),c,nil,-0.25)
	y = y + 15
	surface.SetAlphaMultiplier(alpha)
	do
		local real_cur = ply:Health()
		local cur = smooth(math.max(real_cur, 0), "health"..ply:EntIndex())
		local max = ply:GetMaxHealth()
		jhud.DrawBar(x, y, width,health_height,cur,max,border_size, 0.19607843137254902, 0.6274509803921568, 0.19607843137254902, alpha)
		y = y + health_height + spacing
		x = x + skew/4
	end
	if jattributes and jrpg.IsEnabled(ply) and ply:HasMana() then
		local real_cur = math.Round(ply:GetMana())
		local cur = smooth(real_cur, "mana"..ply:EntIndex())
		local max = ply:GetMaxMana()
		jhud.DrawBar(x,y,width,health_height,cur,max,border_size, 0.1960784313725490, 0.19607843137254902, 0.68627450980392157, alpha)
		y = y + health_height + spacing
		x = x + skew/4
	end
	if jattributes and jrpg.IsEnabled(ply) and ply:HasStamina() then
		local real_cur = ply:GetStamina()
		local cur = smooth(real_cur, "stamina"..ply:EntIndex())
		local max = ply:GetMaxStamina()
		jhud.DrawBar(x,y,width,health_height,cur,max,border_size, 0.5882352941176470, 0.58823529411764708, 0.19607843137254902, alpha)
		y = y + health_height + spacing
		x = x + skew/4
	end

	surface.SetAlphaMultiplier(1)
	if not no_avatar then
	surface.DisableClipping(false)
	render.SetStencilEnable(false)
end
end

local S = 1

local background_glow = CreateMaterial(tostring({}), "UnlitGeneric", {
	["$BaseTexture"] = "particle/particle_glow_01",
	["$VertexAlpha"] = 1,
	["$VertexColor"] = 1,
	["$Additive"] = 0,
})

local background_wing = Material("materials/pac_server/jrpg/wing.png", "smooth")
local foreground_line = Material("materials/pac_server/jrpg/line.png", "smooth")
local surface = surface

local function DrawBar(x,y,w,h,cur,max,border_size, r,g,b, txt, real_cur, center_number)
	local skew = skew
	if not txt then
		skew = skew / 1.5
	end
--
--
	render.SetMaterial(border)
	render.SetBlend(1)
	render.SetColorModulation(1,1,1)

	if txt then
		--draw_rect(x,y,w,h, skew, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)
		draw_rect(x-5,y,w+10,h, -skew, 0, 70, border_size*3, border:GetTexture("$BaseTexture"):Width(), false)
	end

	render.OverrideBlend(true, BLEND_ONE, BLEND_DST_COLOR, BLENDFUNC_ADD)
	render.SetBlend(0.980)
	render.SetColorModulation(0,0,0)
	render.SetMaterial(no_texture)
	draw_rect(x,y,w,h, -skew)
	render.OverrideBlend(false)

	render.SetBlend(1)
	render.SetMaterial(gradient)
	render.SetColorModulation(r/255,g/255,b/255)
	draw_rect(x,y,w * math.min(cur/max, 1),h, -skew, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())

	render.SetMaterial(border)
	render.SetColorModulation(1,1,1)
	draw_rect(x,y,w,h, -skew, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)

	if real_cur then
		prettytext.DrawText({
			text = real_cur,
			x = center_number and x+w/2 or (x + w),
			y = center_number and y+h/2 or y,
			font = "gabriola",
			size = health_height*1.25 * (center_number and 0.7 or 1)*S * 3,
			weight = 1000,
			blur_size = 4,
			blur_overdraw = 3,
			foreground_color_r = 230,
			foreground_color_g = 230,
			foreground_color_b = 230,
			foreground_color_a = 255,

			background_color_r = r/2,
			background_color_g = g/2,
			background_color_b = b/2,
			background_color_a = 255,
			x_align = center_number and -0.5 or 0.2,
			y_align = center_number and -0.5 or -0.45,
		})
	end

	if txt then
		prettytext.DrawText({
			text = txt,
			x = x,
			y = y,
			font = "gabriola",
			size = health_height*1.25*S * 2.5,
			weight = 0,
			blur_size = 4,
			blur_overdraw = 3,
			foreground_color_r = 230,
			foreground_color_g = 230,
			foreground_color_b = 230,
			foreground_color_a = 255,
			background_color_r = r/5,
			background_color_g = g/5,
			background_color_b = b/5,
			background_color_a = 255,
			x_align = -1,
			y_align = -0.45,
		})
	end
end

local selected_i
local selected_list
local select_stage = "categories"
local next_key_check = {}
local last_weapon = NULL

local function check_key(code)
	if input.IsKeyDown(code) then
		if not next_key_check[code] or next_key_check[code] < os.clock() then
			next_key_check[code] = os.clock() + 0.2
			return true
		end
	else
		next_key_check[code] = 0
	end
	return false
end

local function reset()
	selected_list = nil
	selected_i = 1
	select_stage = "categories"
	jtarget.StopSelection()
	jhud.scanner_frame = 1
end

local sort_order = {
	skill = 1,
	magic = 2,
	items = 3,
}

local function get_weapons()
	local categories = {}
	local category_list = {}

	for i,info in pairs(jskill.GetAll()) do
		if not info.Weapon or LocalPlayer():HasWeapon(info.Weapon) then
			local category = info.Category or "skill"
			local color

			if category == "magic" then
				color = Color(25,50,50)
			elseif category == "items" then
				color = Color(50,50,50)
			else
				color = Color(50,40,25)
			end

			if not categories[category] then
				categories[category] = {}
				table.insert(category_list, {
					Name = category,
					list = categories[category],
					sort = sort_order[category] or -1,
					color = color,
				})
			end

			info.color = color

			table.insert(categories[category], info)
		end
	end

	table.sort(category_list, function(a, b)
		return a.sort < b.sort
	end)

	return category_list
end

local selected_category_i = 0
local selected_weapon_i = {}

local function advance(i, num)
	return i + num
end

function jhud.UpdateMenu()
	if vgui.CursorVisible() then return end
	local categories = get_weapons()

	selected_list = selected_list or categories

	selected_weapon_i[selected_category_i] = selected_weapon_i[selected_category_i] or 1

	if check_key(KEY_DOWN) then
		if select_stage == "categories" then
			selected_category_i = selected_category_i + 1
		else
			selected_weapon_i[selected_category_i] = selected_weapon_i[selected_category_i] + 1
		end
	elseif check_key(KEY_UP) then
		if select_stage == "categories" then
			selected_category_i = selected_category_i - 1
		else
			selected_weapon_i[selected_category_i] = selected_weapon_i[selected_category_i] - 1
		end
	elseif check_key(KEY_BACKSPACE) then
		reset()
	elseif check_key(KEY_ENTER) and (not chat.last_closed or chat.last_closed+0.2 < CurTime()) then
		jhud.scanner_frame = 0
		if select_stage == "categories" then
			local category = selected_list[(selected_category_i % #selected_list) + 1]
			if category then
				if category.Name == "attack" then

					if jtarget.GetEntity(LocalPlayer()):IsValid() then
						reset()
						jskill.Execute("attack")
					else
						jtarget.StartSelection()
						if not jtarget.GetEntity(LocalPlayer()):IsValid() then
							jskill.Execute("attack")
						else
							reset()
							select_stage = "target"
						end
					end
				else
					selected_list = category.list
					select_stage = "weapons"
				end
			end
		elseif select_stage == "weapons" then
			local skill = selected_list[(selected_weapon_i[selected_category_i] % #selected_list) + 1]
			local current_target = jtarget.GetEntity(LocalPlayer())

			if current_target:IsValid() then
				reset()
				jskill.Execute(skill.ClassName)
			else
				jtarget.StartSelection(not not skill.Friendly)
				if not jtarget.GetEntity(LocalPlayer()):IsValid() then
					jskill.Execute(skill.ClassName)
					reset()
				else
					select_stage = "target"
				end
			end
		elseif select_stage == "target" then
			local skill = selected_list[(selected_weapon_i[selected_category_i] % #selected_list) + 1]
			local current_target = jtarget.GetEntity(LocalPlayer())
			jtarget.StopSelection()
			reset()
			jskill.Execute(skill.ClassName)
		end
	end

	selected_list = selected_list or categories
end

function jhud.DrawSelection(x, y)
	--if select_stage == "target" then return end
	if not selected_list then return end

	local i = 0
	--for i, data in ipairs(selected_list) do

	local selected_i = 0
	if select_stage == "categories" then
		selected_i = selected_category_i
	elseif select_stage == "weapons" then
		selected_i = selected_weapon_i[selected_category_i]
	end

	jhud.DrawList(selected_list, selected_i, x, y, selected_list[selected_i%#selected_list + 1].color)
end

local last_aiment = NULL
local next_aim = 0

hook.Add("Think", "jhud", function()
	if jrpg.IsEnabled(ply) then
		jhud.UpdateMenu()
	end
end)

hook.Add("HUDPaint", "jhud", function()
	if hook.Run("HUDShouldDraw", "JHUD") == false then return end

	local ply = LocalPlayer()

	if not jrpg.IsEnabled(ply) then
		local ent = ply:GetEyeTrace().Entity

		if ent:IsPlayer() then
			last_aiment = ent
			next_aim = RealTime() + 2
		elseif next_aim < RealTime() then
			last_aiment = NULL
		end

		if last_aiment:IsValid() then
			local f = (next_aim - RealTime()) / 2

			if ent:IsValid() then f = 1 end

			local x = ScrW() - 75
			local y = ScrH() - 70

			jhud.DrawInfoSmall(last_aiment, x, y, (f^0.75)*1.5)
		end
	end

	chat.pos_y = nil

	local offset = 0

	if jrpg.IsEnabled(ply) then
		offset = offset + 32
	else
		if ply:Health() == ply:GetMaxHealth() then return end
		offset = offset - 16
	end

	chat.pos_y = math.Round(ScrH()/2.7)

	S = ScrW() / 1920

	local width = 100000
	local height = 100*S

	local x = 160*S
	local y = ScrH() - 90*S

	if jrpg.IsEnabled(ply) then
		--render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE_MINUS_DST_ALPHA, BLENDFUNC_REVERSE_SUBTRACT)

		surface.SetMaterial(background_glow)
		surface.SetDrawColor(0,0,0,200)
		local size = 500*S
		local x = x + 30
		local y = y + height - 70*S
		surface.DrawTexturedRect(x-size*2/2,y-size/2,size*3,size)

		--render.OverrideBlend(false, BLEND_SRC_ALPHA, BLEND_ONE_MINUS_DST_ALPHA, BLENDFUNC_REVERSE_SUBTRACT)
	end


	if jrpg.IsEnabled(ply) then
		jhud.Draw3DModels(x, y)
		jhud.UpdateMenu()
		jhud.DrawSelection(x, y)
	end

	do
		local x = x - 0
		local y = y - 20

		if not jrpg.IsEnabled(ply) then
			x = x - 220
			y = y + 10
		end

		local c = team.GetColor(TEAM_FRIENDS)
		c.r = c.r/5
		c.g = c.g/5
		c.b = c.b/5
		c.a = 255

		if true then
			local name_width = prettytext.DrawText({
				text = (jrpg and jrpg.GetFriendlyName(ply) or ply:Nick()),
				x = x + 200*S,
				y = y - offset*S - 8*S,
				font = "Gabriola",
				size = 40*S * 2.5,
				blur_size = 4,
				blur_overdraw = 3,
				weight = 1000,
				foreground_color = Color(230, 230, 230, 255),
				background_color = c,
				y_align = -0.15,
			})

			x = x + 200*S

			if jrpg.IsEnabled(ply) then
				prettytext.DrawText({
					text = "Lv. " .. ply:GetNWInt("jlevel_level", 0),
					x = x + math.Clamp(70*S + name_width, 50, ScrW()/3),
					y = y - offset*S + 4*S,
					font = "gabriola",
					size = 30*S * 2,
					blur_size = 4,
					blur_overdraw = 3,
					weight = 1000,
					foreground_color = Color(200, 100, 255, 255),
					background_color = c,
					y_align = -0.05,
					x_align = -1.1,

				})
			end
		end

		local health_height = health_height * S
		local border_size = border_size * S

		y = y + height / 2 - (offset*S)

		do
			local real_cur = ply:Health()
			local cur = smooth(math.max(real_cur, 0), "health")
			local max = ply:GetMaxHealth()

			local w = math.Clamp(max*2, 50, ScrW()/3)*S

			DrawBar(x,y,w,health_height,cur,max,border_size, 50,160,50, "HP", real_cur)

			y = y + health_height + spacing
			x = x - skew/2.5
		end

		if jattributes.HasMana(ply) then
			local real_cur = math.Round(jattributes.GetMana(ply))
			local cur = smooth(real_cur, "mana")
			local max = jattributes.GetMaxMana(ply)

			local w = math.Clamp(max*2, 50, ScrW()/3)*S

			DrawBar(x,y,w,health_height,cur,max,border_size, 50,50,175, "MP", real_cur)

			y = y + health_height + spacing

			last_hp_timer = math.huge
			x = x - skew/2.5
		end

		if jattributes.HasStamina(ply) then
			local real_cur = jattributes.GetStamina(ply)
			local cur = smooth(real_cur, "stamina")
			local max = jattributes.GetMaxStamina(ply)

			local w = math.Clamp(max*2, 50, ScrW()/3)*S

			DrawBar(x,y,w,health_height,cur,max,border_size, 150,150,50, "SP", math.Round(real_cur))

			last_hp_timer = math.huge

			y = y + health_height + spacing
			x = x - skew/2.75
		end

		if jrpg.IsEnabled(ply) then
			local real_cur = math.Round(ply:GetNWInt("jlevel_xp", 0))
			local cur = smooth(real_cur, "xp")
			local max = ply:GetNWInt("jlevel_next_level", 0)
			local w = math.Clamp(jattributes.GetMaxStamina(ply)*2, 50, ScrW()/3)

			DrawBar(x, y, w*S, 8*S, cur, max, 1, 100,0,255, "XP", real_cur, true)
		end
	end

	local size = 16
	local fade = 1
	local h = 72
	local w = 190
	local statuses = jdmg.GetStatuses and jdmg.GetStatuses(ply) or {}
	for _, status in pairs(statuses) do
		local fade = fade * status:GetAmount()
		fade = fade ^ 0.25

		render.SetBlend(fade)
		if status.Negative then
			render.SetColorModulation(0.58, 0, 0)
		elseif status.Positive then
			render.SetColorModulation(0, 0, 0.58)
		else
			render.SetColorModulation(0, 0, 0)
		end
		render.SetMaterial(no_texture)
		draw_rect(x+w-size,y+h,size,size)

		render.SetBlend(fade)
		render.SetColorModulation(1,1,1)
		render.SetMaterial(border)
		draw_rect(x+w-size,y+h,size,size, 0, 1, 64,border_size/1.5, border:GetTexture("$BaseTexture"):Width(), true)

		render.SetBlend(fade)
		render.SetColorModulation(1,1,1)
		render.SetMaterial(status.Icon)
		draw_rect(x+w-size,y+h,size,size)
		draw_rect(x+w-size,y+h,size,size)

		render.SetBlend(0.784)
		render.SetColorModulation(0, 0, 0)
		render.SetMaterial(no_texture)
		draw_rect(x+w-size,y+h,math.min(size*status:GetAmount(), size),size)

		x = x - size - 5
	end

	if jrpg.IsEnabled(ply) then
		local i = 1

		local temp = {}
		for _, ent in ipairs(ents.FindInSphere(ply:EyePos(), 1000)) do
			if jrpg.IsFriend(LocalPlayer(), ent) and ent ~= LocalPlayer() then
				temp[i] = ent
				i = i + 1
			end
		end

		table.sort(temp, function(a, b) return jrpg.GetFriendlyName(a) > jrpg.GetFriendlyName(b) end)

		for i = 1, #temp do
			local ent = temp[i]

			local x = 75
			local y = -25 + (i * 50)

			jhud.DrawInfoSmall(ent, x, y, nil, nil, true, 300)
		end
	end

end)

hook.Add("HUDShouldDraw", "jhud", function(what)
	if what == "CHudHealth"  then
		return false
	end

	if jrpg.enabled and (what == "CHudBattery" or what == "CHudAmmo" or what == "CHudSecondaryAmmo") then
		return false
	end
end)














do
	jhud.entities = jhud.entities or {}

	local function create_ent(path, ang, scale, tex)
		local ent = ClientsideModel(path)
		ent:SetNoDraw(true)
		ent:SetAngles(ang)

		if type(scale) == "Vector" then
			local m = Matrix()
			m:Scale(Vector(scale))
			ent.matrix = m
			ent:EnableMatrix("RenderMultiply", m)
		else
			ent:SetModelScale(scale or 1)
		end
		ent:SetLOD(0)

		local mat

		if tex then
			mat = CreateMaterial("jhud_" .. path ..tostring({}), "VertexLitGeneric", {["$basetexture"] = tex})
		else
			mat = CreateMaterial("jhud_" .. path ..tostring({}), "VertexLitGeneric")
			mat:SetTexture("$basetexture", Material(ent:GetMaterials()[1]):GetTexture("$basetexture"))
		end

		function ent:RenderOverride()
			render.MaterialOverride(mat)
			ent:SetupBones()
			ent:DrawModel()
			render.MaterialOverride()
		end

		table.insert(jhud.entities, ent)

		return ent
	end

	jhud.combine_scanner_ent = nil
	jhud.suit_charger_ent = nil
	jhud.scanner_frame = 1

	function jhud.Draw3DModels(x, y)
		local sx = ScrW() / 1920
		local sy = ScrH() / 1080

		x = x - 35.5
		y = y - 48

		if not jhud.combine_scanner_ent then
			jhud.combine_scanner_ent = create_ent("models/combine_scanner.mdl", Angle(-90,-90-45,0), 9)
			jhud.combine_scanner_ent:SetSequence(jhud.combine_scanner_ent:LookupSequence("alert"))
		end
		if not jhud.suit_charger_ent then
			jhud.suit_charger_ent = create_ent("models/props_combine/suit_charger001.mdl", Angle(-90 + 25,-45, 45), 9)
		end

		local ply = LocalPlayer()

		local hp = smooth(jhud.scanner_frame, "scanner_frame") ^ 0.5
		local mp = smooth(ply:GetMana()/ply:GetMaxMana(), "mana"..ply:EntIndex())

		jhud.combine_scanner_ent:SetPos(Vector(x,y,-200))
		jhud.suit_charger_ent:SetPos(Vector(x+150,y+10,-400))

		jhud.combine_scanner_ent:SetCycle(-hp+1)
		jhud.suit_charger_ent:SetCycle(-mp+1)

		jhud.combine_scanner_ent:SetupBones()

		render.ModelMaterialOverride()
		render.SetColorModulation(1, 1, 1)
		render.SetBlend(1)
		render.SuppressEngineLighting(true)

		cam.StartOrthoView(0,0,ScrW(),ScrH())
			render.CullMode(MATERIAL_CULLMODE_CW)
				jhud.suit_charger_ent:DrawModel()
				jhud.combine_scanner_ent:DrawModel()
			render.CullMode(MATERIAL_CULLMODE_CCW)
		cam.EndOrthoView()

		render.SuppressEngineLighting(false)
	end

	do
		local jfx = requirex("jfx")

		local glyph_disc = jfx.CreateMaterial({
			Shader = "UnlitGeneric",
			BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/disc.png",
			VertexColor = 1,
			VertexAlpha = 1,
		})

		local ring = jfx.CreateMaterial({
			Shader = "UnlitGeneric",
			BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/ring2.png",
			VertexColor = 1,
			VertexAlpha = 1,
		})


		local hand = jfx.CreateMaterial({
			Shader = "UnlitGeneric",

			BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/clock_hand.png",
			Additive = 0,
			VertexColor = 1,
			VertexAlpha = 1,
			BaseTextureTransform = "center .5 .5 scale 1 5 rotate 0 translate 0 1.25",
		})

		function jhud.DrawList(list, selected_i, x,y, color)
			color = color or Color(45, 45, 45)

			jhud.smooth_color = jhud.smooth_color or Vector(color.r, color.g, color.b)
			jhud.smooth_color = jhud.smooth_color + ((Vector(color.r, color.g, color.b) - jhud.smooth_color) * FrameTime() * 10)
			local color = jhud.smooth_color

			jhud.smooth_scrolls = jhud.smooth_scrolls or {}

			surface.DisableClipping(true)

			x = x - 31
			y = y - 43

			local ring_size = 1000
			surface.SetDrawColor(0, 0, 0, 200)
			surface.SetMaterial(background_glow)
			surface.DrawTexturedRect(x-ring_size/2, y-ring_size/2, ring_size, ring_size)

			surface.SetDrawColor(color.r/2, color.g/2, color.b/2, 255)
			surface.SetMaterial(hand)
			local max = 8
			for i = 1, max do
				local m = Matrix()
				m:Translate(Vector(x,y,0))
				m:Rotate(Angle(0,(i/max) * 360 + (jhud.smooth_scrolls[8] or 0) * 22.5,0))
				m:Translate(Vector(-20,-220,0))
				cam.PushModelMatrix(m)
				surface.DrawTexturedRect(0,0,40,500)
				cam.PopModelMatrix()
			end


			local ring_size = 350
			surface.SetDrawColor(color.r, color.g, color.b, 255)
			surface.SetMaterial(glyph_disc)
			surface.DrawTexturedRectRotated(x, y, ring_size, ring_size, jhud.smooth_scrolls[2] or 0)

			local max = #list
			while max < 32 do
				max = max + #list
			end
			for i = 1, max do
				local i2 = i - selected_i
				local i3 = i % #list + 1
				local wep = list[i3]

				wep.color = wep.color or color

				jhud.smooth_scrolls[i] = jhud.smooth_scrolls[i] or 0
				jhud.smooth_scrolls[i] = jhud.smooth_scrolls[i] + ((i2 - jhud.smooth_scrolls[i]) * FrameTime() * 10)
				local smooth_i = jhud.smooth_scrolls[i]

				local s = math.sin((((smooth_i)/max)%1) * math.pi * 2 - math.pi/2) * 0.5 + 0.5
				s = s ^ 0.25
				s = -s + 1

				if s > 0.1 then
					local m = Matrix()
					m:Translate(Vector(x,y,0))
					m:Rotate(Angle(0,smooth_i/max * 360,0))
					m:Translate(Vector(90,0,0))
					m:Scale(Vector(1,1,1)*0.4)

					cam.PushModelMatrix(m)
						prettytext.DrawText({
							text = (wep.Name or "?"):upper(),
							x = 0,
							y = 0,
							font = "gabriola",
							size = 100,
							x_align = 0,
							y_align = -0.5,

							blur_size = 10,
							blur_overdraw = 2,

							foreground_color_r = 255*s,
							foreground_color_g = 255*s,
							foreground_color_b = 255*s,
							foreground_color_a = 255*s,

							background_color_r = wep.color.r*2,
							background_color_g = wep.color.g*2,
							background_color_b = wep.color.b*2,
							background_color_a = 255,
						})
					cam.PopModelMatrix()
				end
			end
		end
		surface.DisableClipping(false)
	end
end