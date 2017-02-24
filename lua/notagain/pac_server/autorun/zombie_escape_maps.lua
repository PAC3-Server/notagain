if not game.GetMap():lower():StartWith("ze_") then return end

hook.Add("InitPostEntity", "fixmap", function()
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

if SERVER then
	
	hook.Add( "KeyPress", "OpenDoors", function( ply, key )
		if ( key == IN_USE ) then

			local ToOpen = {
				func_door = true,
				func_door_rotating = true,
				func_movelinear = true,
			}
			local tr = ply:GetEyeTrace()

			if ToOpen[tr.Entity:GetClass()] and tr.HitPos:Distance(ply:GetPos()) <= 100 then
				tr.Entity:Fire("Open")
			end
		end
	end )
	
end
