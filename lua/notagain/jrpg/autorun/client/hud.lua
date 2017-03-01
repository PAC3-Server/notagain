if LocalPlayer() ~= me and LocalPlayer() ~= immo then return end

local draw_rect = requirex("draw_skewed_rect")

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

local last_hp = 0
local last_hp_timer = 0
local hide_time = 5

hook.Add("HUDPaint", "jhud", function()
	local ply = LocalPlayer()

	local offset = 0

	if jattributes.HasMana(ply) then
		offset = offset + 16
	end

	if jattributes.HasStamina(ply) then
		offset = offset + 16
	end

	local x = 50
	local y = ScrH() - 50 - offset
	local border_size = 2
	local h = 15

	do
		local fade = math.Clamp(last_hp_timer - RealTime(), 0, 1) ^ 0.5

		local cur = smooth(math.max(ply:Health(), 0), "health")
		local max = ply:GetMaxHealth()

		if last_hp ~= ply:Health() then
			last_hp_timer = RealTime() + hide_time
			last_hp = ply:Health()
		end

		local w = math.Clamp(max, 100, 1000)

		surface.SetDrawColor(255,255,255,10*fade)
		surface.SetMaterial(gradient)
		draw_rect(x,y,w,h, 0, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())

		surface.SetDrawColor(175,50,50,255*fade)
		surface.SetMaterial(gradient)
		draw_rect(x,y,w * (cur/max),h, 0, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())

		surface.SetMaterial(border)
		surface.SetDrawColor(255,255,175,255*fade)
		draw_rect(x,y,w,h, 0, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)

		y = y + h + 2
	end


	if jattributes.HasMana(ply) then
		local cur = smooth(jattributes.GetMana(ply), "mana")
		local max = jattributes.GetMaxMana(ply)

		local w = math.Clamp(max, 100, 1000)


		surface.SetDrawColor(255,255,255,10)
		surface.SetMaterial(gradient)
		draw_rect(x,y,w,h, 0, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())

		surface.SetDrawColor(50,50,175,255)
		surface.SetMaterial(gradient)
		draw_rect(x,y,w * (cur/max),h, 0, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())

		surface.SetMaterial(border)
		surface.SetDrawColor(255,255,175,255)
		draw_rect(x,y,w,h, 0, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)

		y = y + h + 2

		last_hp_timer = math.huge
	end

		if jattributes.HasStamina(ply) then
		local cur = smooth(jattributes.GetStamina(ply), "stamina")
		local max = jattributes.GetMaxStamina(ply)

		local w = math.Clamp(max, 100, 1000)


		surface.SetDrawColor(255,255,255,10)
		surface.SetMaterial(gradient)
		draw_rect(x,y,w,h, 0, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())

		surface.SetDrawColor(50,150,50,255)
		surface.SetMaterial(gradient)
		draw_rect(x,y,w * (cur/max),h, 0, 0, 20, 0, gradient:GetTexture("$BaseTexture"):Width())

		surface.SetMaterial(border)
		surface.SetDrawColor(255,255,175,255)
		draw_rect(x,y,w,h, 0, 0, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)

		last_hp_timer = math.huge
	end
end)

hook.Add("HUDShouldDraw", "jhud", function(what)
	if what == "CHudHealth" or what == "CHudBattery" or what == "CHudAmmo" or what == "CHudSecondaryAmmo" then
		return false
	end
end)