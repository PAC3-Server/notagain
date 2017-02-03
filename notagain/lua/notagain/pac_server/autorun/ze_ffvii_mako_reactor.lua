if not game.GetMap():lower():find("ze_ffvii_mako_reactor") then return end

hook.Add("InitPostEntity", "fixmap", function()
	if SERVER then
		local remove_these = {
			trigger_teleport = true,
			point_teleport = true,
			info_teleport_destination = true,
			func_physbox_multiplayer = true,
			trigger_once = true,
			info_particle_system = true,
			trigger_hurt = true,
		}

		for _, ent in pairs(ents.GetAll()) do
			local class = ent:GetClass()

			if remove_these[ent:GetClass()] then
				ent:Remove()
			end
		end
	end

	if CLIENT then
		RunConsoleCommand("mat_colorcorrection", "0")
	end

	hook.Remove("InitPostEntity", "fixmap")
end)