local META = {}
META.Name = "fire"
META.Negative = true

if CLIENT then
	local jfx = requirex("jfx")

	META.Icon = jfx.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "http://wow.zamimg.com/images/wow/icons/large/inv_summerfest_firespirit.jpg",
		VertexAlpha = 1,
		VertexColor = 1,
	})
end

if SERVER then
	function META:Think(ent)
		ent:Ignite(0.1)
	end
end

jdmg.RegisterStatusEffect(META)