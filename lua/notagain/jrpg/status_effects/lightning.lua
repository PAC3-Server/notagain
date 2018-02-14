local META = {}
META.Name = "lightning"
META.Negative = true

if CLIENT then
	local jfx = requirex("jfx")

	META.Icon = jfx.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "http://wow.zamimg.com/images/wow/icons/large/spell_nature_lightning.jpg",
		VertexAlpha = 1,
		VertexColor = 1,
	})
end

function META:Think(ent)
	local f = self:GetAmount()

	local wep = ent.GetActiveWeapon and ent:GetActiveWeapon()
	if wep and wep:IsValid() then
		local t = CurTime()
		wep:SetNextPrimaryFire(t + math.random() * f)
		wep:SetNextSecondaryFire(t + math.random() * f)
	end

	if math.random() ^ f > 0.8 then
		f = f * 15
		if ent:IsPlayer() then
			local rand_ang = Angle(math.Rand(-1,1)*f, math.Rand(-1,1)*f, 0)
			ent:SetEyeAngles(ent:EyeAngles() + rand_ang)
		else
			if CLIENT then
				ent:SetCycle((ent:GetCycle() or 0) + math.random()*f)
			end
		end

		if SERVER then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(1 + math.ceil(self:GetAmount() * 2))
			dmginfo:SetDamageCustom(JDMG_LIGHTNING)
			dmginfo:SetDamagePosition(ent:WorldSpaceCenter())

			local attacker = self:GetAttacker()
			if attacker:IsValid() then
				dmginfo:SetInflictor(attacker)
			end

			local wep = self:GetWeapon()
			if wep:IsValid() then
				dmginfo:SetInflictor(wep)
			end

			if self:GetAmount() > 0.75 then
				for _, ent in ipairs(ents.FindInSphere(ent:GetPos(), ent:BoundingRadius() * 3)) do
					if ent ~= ent and jrpg.IsActor(ent) then
						wepstats.TakeDamageInfo(ent, dmginfo)
					end
				end
			end

			wepstats.TakeDamageInfo(ent, dmginfo)

			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:AddAngleVelocity(VectorRand() * dmginfo:GetDamage() * f * 50)
			end
		end
	end
end

if CLIENT then

end

jdmg.RegisterStatusEffect(META)