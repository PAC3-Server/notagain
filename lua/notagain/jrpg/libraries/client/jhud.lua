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

return jhud
