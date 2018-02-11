local META = {}
META.Name = "poison"
META.Negative = true

if CLIENT then
	local jfx = requirex("jfx")

	META.Icon = jfx.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "sprites/greenspit1",
		VertexAlpha = 1,
		VertexColor = 1,
		Additive = 1,
		BaseTextureTransform = "center .5 .5 scale 0.7 0.7 rotate 0 translate 0 0",
	})
end

META.Rate = 1

if SERVER then
	function META:Think(target)
		local dmginfo = DamageInfo()
		dmginfo:SetDamage(self.potency or 1)
		dmginfo:SetDamageCustom(JDMG_POISON)
		dmginfo:SetDamagePosition(target:WorldSpaceCenter())

		local attacker = self:GetAttacker()
		if attacker:IsValid() then
			dmginfo:SetInflictor(attacker)
			dmginfo:SetAttacker(attacker)
		end

		wepstats.TakeDamageInfo(target, dmginfo)
	end
end

jdmg.RegisterStatusEffect(META)