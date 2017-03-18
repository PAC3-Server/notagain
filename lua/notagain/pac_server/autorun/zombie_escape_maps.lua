if not game.GetMap():lower():StartWith("ze_") then return end

timer.Simple(0.1, function()
	if SERVER then
		local remove_these = {
			point_teleport = true,
			info_teleport_destination = true,
			func_physbox_multiplayer = true,
			info_particle_system = true,
			game_text = true,
			func_wall_toggle = true,
			func_clip_vphysics = true,
		}

		for _, ent in pairs(ents.GetAll()) do
			local class = ent:GetClass()

			if remove_these[ent:GetClass()] or ent:GetClass():find("trigger_", nil, true) then
				ent:Remove()
			end
		end
	end

	if CLIENT then
		RunConsoleCommand("mat_colorcorrection", "0")
	end
end)