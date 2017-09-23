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
local background_glow = CreateMaterial(tostring({}), "UnlitGeneric", {
	["$BaseTexture"] = "particle/particle_glow_01",
	["$VertexAlpha"] = 1,
	["$VertexColor"] = 1,
	["$Additive"] = 0,
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
local spacing = 2
function jhud.DrawBar(x,y,w,h,cur,max,border_size, r,g,b)
	local skew = skew/1.5
	surface.SetMaterial(border)
	surface.SetDrawColor(255,255,255,255)
	surface.SetDrawColor(0,0,0,250)
	draw.NoTexture()
	draw_rect(x,y,w,h, skew)
	surface.SetDrawColor(r,g,b,255)
	surface.SetMaterial(gradient)
	draw_rect(x,y,w * (cur/max),h, skew, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())
	surface.SetMaterial(border)
	surface.SetDrawColor(255,255,255,255)
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
		jhud.DrawBar(x, y, width,health_height,cur,max,border_size, 50,160,50)
		y = y + health_height + spacing
		x = x + skew/4
	end
	if jattributes and ply:GetNWBool("rpg",false) and ply:HasMana() then
		local real_cur = math.Round(ply:GetMana())
		local cur = smooth(real_cur, "mana"..ply:EntIndex())
		local max = ply:GetMaxMana()
		jhud.DrawBar(x,y,width,health_height,cur,max,border_size, 50,50,175)
		y = y + health_height + spacing
		x = x + skew/4
	end
	if jattributes and ply:GetNWBool("rpg",false) and ply:HasStamina() then
		local real_cur = ply:GetStamina()
		local cur = smooth(real_cur, "stamina"..ply:EntIndex())
		local max = ply:GetMaxStamina()
		jhud.DrawBar(x,y,width,health_height,cur,max,border_size, 150,150,50)
		y = y + health_height + spacing
		x = x + skew/4
	end
	surface.SetAlphaMultiplier(1)
	surface.DisableClipping(false)
	render.SetStencilEnable(false)
end


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

local background_glow = CreateMaterial(tostring({}), "UnlitGeneric", {
	["$BaseTexture"] = "particle/particle_glow_01",
	["$VertexAlpha"] = 1,
	["$VertexColor"] = 1,
	["$Additive"] = 0,
})

local background_wing = Material("materials/pac_server/jrpg/wing.png", "smooth")
local foreground_line = Material("materials/pac_server/jrpg/line.png", "smooth")


local function DrawBar(x,y,w,h,cur,max,border_size, r,g,b, txt, real_cur, center_number)
	local skew = skew
	if not txt then
		skew = skew / 1.5
	end
	surface.SetMaterial(border)
	surface.SetDrawColor(255,255,255,255)

	if txt then
		--draw_rect(x,y,w,h, skew, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)
		draw_rect(x-5,y,w+10,h, skew, 0, 70, border_size*3, border:GetTexture("$BaseTexture"):Width(), false)
	end

	surface.SetDrawColor(0,0,0,250)
	draw.NoTexture()
	draw_rect(x,y,w,h, skew)

	surface.SetDrawColor(r,g,b,255)
	surface.SetMaterial(gradient)
	draw_rect(x,y,w * (cur/max),h, skew, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())

	surface.SetMaterial(border)
	surface.SetDrawColor(255,255,255,255)
	draw_rect(x,y,w,h, skew, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)

	if real_cur then
		prettytext.DrawText({
			text = real_cur,
			x = center_number and x+w/2 or (x + w),
			y = center_number and y+h/2 or y,
			font = "Square721 BT",
			size = health_height*1.4 * (center_number and 0.7 or 1),
			weight = 1000,
			blur_size = 4,
			blur_overdraw = 3,
			foreground_color = Color(230, 230, 230, 255),
			background_color = Color(r/2,g/2,b/2,255),
			x_align = center_number and -0.5 or 0.25,
			y_align = center_number and -0.5 or -0.2,
		})
	end

	if txt then
		prettytext.DrawText({
			text = txt,
			x = x,
			y = y,
			font = "Square721 BT",
			size = health_height*1.4,
			weight = 0,
			blur_size = 4,
			blur_overdraw = 3,
			foreground_color = Color(230, 230, 230, 255),
			background_color = Color(r/5,g/5,b/5,255),
			x_align = -1,
			y_align = -0.15,
		})
	end
end



hook.Add("HUDPaint", "jhud", function()
	if hook.Run("HUDShouldDraw", "JHUD") == false then return end

	local ply = LocalPlayer()

	local offset = 0

	if ply:GetNWBool("rpg") then
		offset = offset + 32
	else
		if ply:Health() == ply:GetMaxHealth() then return end
		offset = offset - 16
	end

	local width = 100000
	local height = 100

	local x = 100
	local y = ScrH() - height - 20

	do
		local x = x
		local y = y

		do
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

		surface.SetMaterial(background_wing)
		surface.SetDrawColor(255,255,255,255)
		surface.DrawTexturedRect(x-120,y-100,background_wing:Width()*0.75,background_wing:Height()*0.75)

		do
			local x = x + 100
			local y = y + 10
			local w = 500
			local h = 500
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

		do
			surface.SetMaterial(background_glow)
			surface.SetDrawColor(0,0,0,100)
			local size = 300
			local x = x + 120
			local y = y + height + 20
			surface.DrawTexturedRect(x-size*2/2,y-size/2,size*2,size)
		end

		local c = team.GetColor(TEAM_FRIENDS)
		c.r = c.r/5
		c.g = c.g/5
		c.b = c.b/5
		c.a = 255


		local name_width = prettytext.DrawText({
			text = (jrpg and jrpg.GetFriendlyName(ply) or ply:Nick()),
			x = x + 210,
			y = y - offset - 8,
			font = "Square721 BT",
			size = 40,
			blur_size = 4,
			blur_overdraw = 3,
			weight = 1000,
			foreground_color = Color(230, 230, 230, 255),
			background_color = c,
			y_align = 0.5,
		})

		x = x + 200
		if ply:GetNWBool("rpg") then
			prettytext.DrawText({
				text = "Lv. " .. ply:GetNWInt("jlevel_level", 0),
				x = x + math.Clamp(85 + name_width, 50, ScrW()/3),
				y = y - offset + 4,
				font = "Square721 BT",
				size = 30,
				blur_size = 4,
				blur_overdraw = 3,
				weight = 1000,
				foreground_color = Color(200, 100, 255, 255),
				background_color = c,
				y_align = 0.5,
				x_align = -1,

			})
		end
		y = y + height / 2 - offset


		do
			local real_cur = ply:Health()
			local cur = smooth(math.max(real_cur, 0), "health")
			local max = ply:GetMaxHealth()

			local w = math.Clamp(max*2, 50, ScrW()/3)

			DrawBar(x,y,w,health_height,cur,max,border_size, 50,160,50, "HP", real_cur)

			y = y + health_height + spacing
			x = x + skew/2.5
		end

		if jattributes.HasMana(ply) then
			local real_cur = math.Round(jattributes.GetMana(ply))
			local cur = smooth(real_cur, "mana")
			local max = jattributes.GetMaxMana(ply)

			local w = math.Clamp(max*2, 50, ScrW()/3)

			DrawBar(x,y,w,health_height,cur,max,border_size, 50,50,175, "MP", real_cur)

			y = y + health_height + spacing

			last_hp_timer = math.huge
			x = x + skew/2.5
		end

		if jattributes.HasStamina(ply) then
			local real_cur = jattributes.GetStamina(ply)
			local cur = smooth(real_cur, "stamina")
			local max = jattributes.GetMaxStamina(ply)

			local w = math.Clamp(max*2, 50, ScrW()/3)

			DrawBar(x,y,w,health_height,cur,max,border_size, 150,150,50, "SP", math.Round(real_cur))

			last_hp_timer = math.huge

			y = y + health_height + spacing
			x = x + skew/2.75
		end

		if ply:GetNWBool("rpg") then
			local real_cur = math.Round(ply:GetNWInt("jlevel_xp", 0))
			local cur = smooth(real_cur, "xp")
			local max = ply:GetNWInt("jlevel_next_level", 0)
			local w = math.Clamp(jattributes.GetMaxStamina(ply)*2, 50, ScrW()/3)

			DrawBar(x, y, w, 8, cur, max, 1, 100,0,255, "XP", real_cur, true)
		end
	end

	surface.DisableClipping(false)
	render.SetStencilEnable(false)

	surface.SetMaterial(foreground_line)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(x-45,y+60,foreground_line:Width()*0.25,foreground_line:Height()*0.3)

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
end)

hook.Add("HUDShouldDraw", "jhud", function(what)
	if what == "CHudHealth"  then
		return false
	end

	if LocalPlayer():GetNWBool("rpg") and (what == "CHudBattery" or what == "CHudAmmo" or what == "CHudSecondaryAmmo") then
		return false
	end
end)