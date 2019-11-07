if not game.GetMap():lower():StartWith("ze_") then return end

local function fix_map()
	if SERVER then
		local remove_these = {
			point_teleport = true,
			info_teleport_destination = true,
			func_physbox_multiplayer = true,
			info_particle_system = true,
			game_text = true,
			func_wall_toggle = true,
			func_clip_vphysics = true,
			filter_activator_team = true,
		}

		for _, ent in pairs(ents.GetAll()) do
			local class = ent:GetClass()

			if remove_these[ent:GetClass()] or ent:GetClass():find("trigger_", nil, true) then
				ent:Remove()
			end

			ent:Fire("unlock")
		end
	end

	if CLIENT then
		RunConsoleCommand("mat_colorcorrection", "0")
	end
end

timer.Simple(0.1, fix_map)

hook.Add("PostCleanupMap", "zombie_escape_maps", fix_map)