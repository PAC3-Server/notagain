hook.Add("PhysgunPickup", "propkill_dmginfo", function(ply, ent)
	ent.propkill_dmginfo_pickup = ply
end)

hook.Add("GravGunPickupAllowed", "propkill_dmginfo", function(ply, ent)
	ent.propkill_dmginfo_pickup = ply
end)

hook.Add("PhysgunDrop", "propkill_dmginfo", function(ply, ent)
	if IsValid(ent.propkill_dmginfo_pickup) then
		ent.propkill_dmginfo_dropdata = {ply = ply, when = CurTime() + 3}
	end

	ent.propkill_dmginfo_pickup = nil
end)

hook.Add("EntityTakeDamage", "propkill_dmginfo", function(ply, dmginfo)
	local attacker  = dmginfo:GetAttacker()

	if attacker.propkill_dmginfo_dropdata then
		local real_attacker = attacker.propkill_dmginfo_dropdata.ply
		if IsValid(real_attacker) and attacker.propkill_dmginfo_dropdata.when > CurTime() then
			dmginfo:SetAttacker(real_attacker)
			dmginfo:SetInflictor(attacker)
		end
	end
end, -math.huge)
