if game.GetMap():match("gm_*") then return end

hook.Add("InitPostEntity", "fixmap", function()
	if SERVER then
		local remove_these = {
			point_teleport = true,
			info_teleport_destination = true,
			func_physbox_multiplayer = true,
			info_particle_system = true,
		}

		for _, ent in pairs(ents.GetAll()) do
			local class = ent:GetClass()

			if remove_these[ent:GetClass()] or ent:GetClass():match("trigger_*") then
				ent:Remove()
			end
		end
	end

	if CLIENT then
		RunConsoleCommand("mat_colorcorrection", "0")
	end

	hook.Remove("InitPostEntity", "fixmap")
end)
