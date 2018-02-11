local META = {}
META.Name = "confused"
META.Negative = true

if CLIENT then
	local jfx = requirex("jfx")

	META.Icon = jfx.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "http://wow.zamimg.com/images/wow/icons/large/ability_monk_blackoutkick.jpg",
		VertexAlpha = 1,
		VertexColor = 1,
	})
end

function META:Think(ent)
	local wep = ent:GetActiveWeapon()
	if wep and wep:IsValid() then
		local f = self:GetAmount()
		local t = CurTime()
		wep:SetNextPrimaryFire(t + math.random() * f)
		wep:SetNextSecondaryFire(t + math.random() * f)
	end
end

if CLIENT then

end

jdmg.RegisterStatusEffect(META)