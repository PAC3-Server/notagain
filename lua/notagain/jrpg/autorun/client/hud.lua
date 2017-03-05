local draw_rect = requirex("draw_skewed_rect")
local prettytext = requirex("pretty_text")

local gradient = CreateMaterial(tostring({}), "UnlitGeneric", {
	["$BaseTexture"] = "gui/center_gradient",
	["$BaseTextureTransform"] = "center .5 .5 scale 1 1 rotate 90 translate 0 0",
	["$VertexAlpha"] = 1,
	["$VertexColor"] = 1,
	["$Additive"] = 0,
})

local gradient_up = CreateMaterial(tostring({}), "UnlitGeneric", {
	["$BaseTexture"] = "vgui/gradient_up",

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

local foreground_glow = CreateMaterial(tostring({}), "UnlitGeneric", {
	["$BaseTexture"] = "particle/particle_glow_05",
	["$VertexAlpha"] = 1,
	["$VertexColor"] = 1,
	["$Additive"] = 1,
})

local background_wing = Material("materials/pac_server/jrpg/wing.png", "smooth")
local foreground_line = Material("materials/pac_server/jrpg/line.png", "smooth")

local smoothers = {}

local function smooth(var, id)
	smoothers[id] = smoothers[id] or var
	smoothers[id] = smoothers[id] + ((var - smoothers[id]) * FrameTime() * 5)

	return smoothers[id]
end

local last_hp = 0
local last_hp_timer = 0
local hide_time = 5

local border_size = 2
local skew = -40
local health_height = 18
local spacing = 2

local function draw_bar(x,y,w,h,cur,max,border_size, r,g,b, txt, real_cur, center_number)
	surface.SetMaterial(border)
	surface.SetDrawColor(255,255,255,255)
	--draw_rect(x,y,w,h, skew, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)
	draw_rect(x-5,y,w+10,h, skew, 0, 70, border_size*3, border:GetTexture("$BaseTexture"):Width(), false)

	surface.SetDrawColor(0,0,0,250)
	draw.NoTexture()
	draw_rect(x,y,w,h, skew)

	surface.SetDrawColor(r,g,b,255)
	surface.SetMaterial(gradient)
	draw_rect(x,y,w * (cur/max),h, skew, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())

	surface.SetMaterial(border)
	surface.SetDrawColor(255,255,255,255)
	draw_rect(x,y,w,h, skew, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)

	prettytext.Draw(real_cur, center_number and x+w/2 or (x + w), center_number and y+h/2 or y, "gabriola", health_height*3.5 * (center_number and 0.7 or 1), 1, 2, Color(255, 255, 255, 150), Color(r/2,g/2,b/2,100), center_number and -0.5 or 0.5, center_number and -0.55 or -0.4)
	prettytext.Draw(txt, x, y, "gabriola", health_height*2, 0, 5, Color(255, 255, 255, 150), Color(r/5,g/5,b/5,255), -1.3, -0.3)
end

hook.Add("HUDPaint", "jhud", function()
	local ply = LocalPlayer()

	local offset = 0

	if jattributes.HasMana(ply) then
		offset = offset + 16
	end

	if jattributes.HasStamina(ply) then
		offset = offset + 16
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

			avatar.Draw(LocalPlayer(), x,y, height)
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
		c.r = c.r/3
		c.g = c.g/3
		c.b = c.b/3
		c.a = 100
		prettytext.Draw(ply:Nick(), x + 210, y - offset, "gabriola", 55, 00, 6, Color(255, 255, 255, 200), c)

		x = x + 200
		prettytext.Draw("Lv. " .. ply:GetNWInt("jlevel_level", 0), x + math.Clamp(ply:GetMaxHealth()*3, 50, 1000),  y - offset, "gabriola", 55, 00, 6, Color(200, 50, 255, 200), c, -1)
		y = y + height / 2 - offset


		do
			local real_cur = ply:Health()
			local cur = smooth(math.max(real_cur, 0), "health")
			local max = ply:GetMaxHealth()

			local w = math.Clamp(max*3, 50, 1000)

			draw_bar(x,y,w,health_height,cur,max,border_size, 50,160,50, "HP", real_cur)

			y = y + health_height + spacing
			x = x + skew/2.5
		end

		if jattributes.HasMana(ply) then
			local real_cur = math.Round(jattributes.GetMana(ply))
			local cur = smooth(real_cur, "mana")
			local max = jattributes.GetMaxMana(ply)

			local w = math.Clamp(max*3, 50, 1000)

			draw_bar(x,y,w,health_height,cur,max,border_size, 50,50,175, "MP", real_cur)

			y = y + health_height + spacing

			last_hp_timer = math.huge
			x = x + skew/2.5
		end

		if jattributes.HasStamina(ply) then
			local real_cur = jattributes.GetStamina(ply)
			local cur = smooth(real_cur, "stamina")
			local max = jattributes.GetMaxStamina(ply)

			local w = math.Clamp(max*3, 50, 1000)

			draw_bar(x,y,w,health_height,cur,max,border_size, 150,150,50, "SP", real_cur)

			last_hp_timer = math.huge

			y = y + health_height + spacing
			x = x + skew/2.5
		end

		do
			local real_cur = math.Round(ply:GetNWInt("jlevel_xp", 0))
			local cur = smooth(real_cur, "xp")
			local max = ply:GetNWInt("jlevel_next_level", 0)

			draw_bar(x, y, 300-5, 8, cur, max, 1, 100,0,255, "XP", real_cur, true)
		end
	end

	surface.DisableClipping(false)
	render.SetStencilEnable(false)

	surface.SetMaterial(foreground_line)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(x-45,y+60,foreground_line:Width()*0.25,foreground_line:Height()*0.3)
end)

hook.Add("HUDShouldDraw", "jhud", function(what)
	if what == "CHudHealth" or what == "CHudBattery" or what == "CHudAmmo" or what == "CHudSecondaryAmmo" then
		return false
	end
end)