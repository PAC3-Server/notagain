local META = {}
META.Name = "lightning"
META.Negative = true

if CLIENT then
	local jfx = requirex("jfx")

	META.Icon = jfx.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "editor/choreo_manager",
		VertexAlpha = 1,
		VertexColor = 1,
		BaseTextureTransform = "center 0.45 .1 scale 0.9 0.9 rotate 0 translate 0 -0.05",
	})
end

jdmg.RegisterStatusEffect(META)