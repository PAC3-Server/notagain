local META = {}
META.Name = "fire"
META.Negative = true

if CLIENT then
	local jfx = requirex("jfx")

	META.Icon = jfx.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "editor/env_fire",
		VertexAlpha = 1,
		VertexColor = 1,
		BaseTextureTransform = "center 0.45 .1 scale 0.75 0.75 rotate 0 translate 0 0",
	})
end

if SERVER then
	function META:Think(ent)
		ent:Ignite(0.1)
	end
end

jdmg.RegisterStatusEffect(META)