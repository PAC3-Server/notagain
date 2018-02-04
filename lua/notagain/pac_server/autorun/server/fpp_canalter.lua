timer.Simple(0.5, function()
	if not FindMetaTable("Player").CanAlter or not _G.FPP then return end

	FPP._OLD_plyCanTouchEnt = FPP._OLD_plyCanTouchEnt or FPP.plyCanTouchEnt
	function FPP.plyCanTouchEnt(ply, ent, ...)

		if not ent:IsPlayer() then
			local ent = ent:CPPIGetOwner()
			if ent and ply:CanAlter(ent) then
				return 11
			end
		end

		return FPP._OLD_plyCanTouchEnt(ply, ent, ...)
	end

	if hook.GetTable().InitPostEntity and hook.GetTable().InitPostEntity.e2lib then
		hook.GetTable().InitPostEntity.e2lib()
	end

	timer.Create("fpp_getbuddies", 0, 1, function()
		for _, ply in pairs(player.GetAll()) do
			ply.Buddies = {}
		end
		for _, a in pairs(player.GetAll()) do
		for _, b in pairs(player.GetAll()) do
			if a:CanAlter(b) then
				b.Buddies[a] = {
					EntityDamage = true,
					Gravgun = true,
					Physgun = true,
					PlayerUse = true,
					Toolgun = true,
				}
			end
		end
		end
	end)
end)