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
local skew = -40
local health_height = 18
local no_texture = Material("vgui/white")

function jhud.DrawBar(x,y,w,h,cur,max,border_size, r,g,b)
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
function jhud.DrawInfoSmall(ply, x, y, alpha, color)
	alpha = alpha or 1
	color = color or color_white
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
	surface.DrawRect(x-width-100,y-width, width + 200, width+70)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
	surface.SetAlphaMultiplier(alpha)
	do
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
		avatar.Draw(ply, x-80,y+15, width/1.5)
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
		jhud.DrawBar(x, y, width,health_height,cur,max,border_size, 0.19607843137254902, 0.6274509803921568, 0.19607843137254902)
		y = y + health_height + spacing
		x = x + skew/4
	end
	if jattributes and ply:GetNWBool("rpg",false) and ply:HasMana() then
		local real_cur = math.Round(ply:GetMana())
		local cur = smooth(real_cur, "mana"..ply:EntIndex())
		local max = ply:GetMaxMana()
		jhud.DrawBar(x,y,width,health_height,cur,max,border_size, 0.1960784313725490, 0.19607843137254902, 0.68627450980392157)
		y = y + health_height + spacing
		x = x + skew/4
	end
	if jattributes and ply:GetNWBool("rpg",false) and ply:HasStamina() then
		local real_cur = ply:GetStamina()
		local cur = smooth(real_cur, "stamina"..ply:EntIndex())
		local max = ply:GetMaxStamina()
		jhud.DrawBar(x,y,width,health_height,cur,max,border_size, 0.5882352941176470, 0.58823529411764708, 0.19607843137254902)
		y = y + health_height + spacing
		x = x + skew/4
	end
	surface.SetAlphaMultiplier(1)
	surface.DisableClipping(false)
	render.SetStencilEnable(false)
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

	render.SetMaterial(border)
	render.SetBlend(1)
	render.SetColorModulation(1,1,1)

	if txt then
		--draw_rect(x,y,w,h, skew, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)
		draw_rect(x-5,y,w+10,h, skew, 0, 70, border_size*3, border:GetTexture("$BaseTexture"):Width(), false)
	end

	render.SetBlend(0.980)
	render.SetColorModulation(0,0,0)
	render.SetMaterial(no_texture)
	draw_rect(x,y,w,h, skew)

	render.SetBlend(1)
	render.SetMaterial(gradient)
	render.SetColorModulation(r/255,g/255,b/255)
	draw_rect(x,y,w * math.min(cur/max, 1),h, skew, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())

	render.SetMaterial(border)
	render.SetColorModulation(1,1,1)
	draw_rect(x,y,w,h, skew, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)

	if real_cur then
		prettytext.DrawText({
			text = real_cur,
			x = center_number and x+w/2 or (x + w),
			y = center_number and y+h/2 or y,
			font = "korataki",
			size = health_height*1.25 * (center_number and 0.7 or 1)*S,
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
			x_align = center_number and -0.5 or 0.25,
			y_align = center_number and -0.5 or -0.2,
		})
	end

	if txt then
		prettytext.DrawText({
			text = txt,
			x = x,
			y = y,
			font = "korataki",
			size = health_height*1.25*S,
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
			y_align = -0.15,
		})
	end
end

hook.Add("HUDPaint", "jhud", function()
	if hook.Run("HUDShouldDraw", "JHUD") == false then return end

	S = ScrW() / 1920

	local ply = LocalPlayer()

	local offset = 0

	if ply:GetNWBool("rpg") then
		offset = offset + 32
	else
		if ply:Health() == ply:GetMaxHealth() then return end
		offset = offset - 16
	end

	local width = 100000
	local height = 100*S

	local x = 110*S
	local y = ScrH() - 140*S

	do
		local x = x
		local y = y

		if true then
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
				surface.DrawRect(x-500,y-500, width+500, height+500)
			render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
		end

		do
			local w, h = background_wing:GetInt("$realwidth"), background_wing:GetInt("$realheight")
			if w and h then
				surface.SetMaterial(background_wing)
				surface.SetDrawColor(255,255,255,255)
				surface.DrawTexturedRect(x-130*S,y-150*S,w*S,h*S)
			end
		end


		if true then
			local x = x + 125*S
			local y = y + 25*S
			local w = 500*S
			local h = 500*S
			surface.SetMaterial(background_glow)
			surface.SetDrawColor(0,0,0,50)
			surface.DrawTexturedRect(x-w/2,y-h/2,w,h)

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

			if smoothers.health then
				lost = math.max(smoothers.health - math.max(ply:Health(), 0), 0)
			end

			lost = lost + 1
			x = x + math.Rand(-1,1) * (lost-1)
			y = y + math.Rand(-1,1) * (lost-1)

			surface.SetDrawColor(255,critical*255/lost,critical*255/lost,255)

			if avatar.Draw then -- this is sometimes nil
				avatar.Draw(LocalPlayer(), x,y, height)
			end
		end

		if true then
			surface.SetMaterial(background_glow)
			surface.SetDrawColor(0,0,0,200)
			local size = 300*S
			local x = x + 120
			local y = y + height + 20*S
			surface.DrawTexturedRect(x-size*2/2,y-size/2,size*2,size)
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
				font = "Square721 BT",
				size = 40*S,
				blur_size = 4,
				blur_overdraw = 3,
				weight = 1000,
				foreground_color = Color(230, 230, 230, 255),
				background_color = c,
				y_align = 0.5,
			})

			x = x + 200*S

			if ply:GetNWBool("rpg") then
				prettytext.DrawText({
					text = "Lv. " .. ply:GetNWInt("jlevel_level", 0),
					x = x + math.Clamp(70*S + name_width, 50, ScrW()/3),
					y = y - offset*S + 4*S,
					font = "Square721 BT",
					size = 30*S,
					blur_size = 4,
					blur_overdraw = 3,
					weight = 1000,
					foreground_color = Color(200, 100, 255, 255),
					background_color = c,
					y_align = 0.5,
					x_align = -1,

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

		if ply:GetNWBool("rpg") then
			local real_cur = math.Round(ply:GetNWInt("jlevel_xp", 0))
			local cur = smooth(real_cur, "xp")
			local max = ply:GetNWInt("jlevel_next_level", 0)
			local w = math.Clamp(jattributes.GetMaxStamina(ply)*2, 50, ScrW()/3)

			DrawBar(x, y, w*S, 8*S, cur, max, 1, 100,0,255, "XP", real_cur, true)
		end
	end

	surface.DisableClipping(false)
	render.SetStencilEnable(false)

	do
		local w, h = foreground_line:GetInt("$realwidth"), foreground_line:GetInt("$realheight")
		if w and h then
			surface.SetMaterial(foreground_line)
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(x-90*S,y+65*S,w*S,h*S)
		end
	end

	local i = 0

	if ply:GetNWBool("rpg") then
		for _, ply in ipairs(player.GetAll()) do
			if jrpg.IsFriend(ply) and ply ~= LocalPlayer() and ply:GetNWBool("rpg") and ply:GetPos():Distance(LocalPlayer():GetPos()) < 1000 then
				local x = ScrW() - 200 * i - 75
				local y = ScrH() - 100

				jhud.DrawInfoSmall(ply, x, y)

				i = i + 1
			end
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
		draw_rect(x+w-size,y+h,size*status:GetAmount(),size)

		x = x - size - 5
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