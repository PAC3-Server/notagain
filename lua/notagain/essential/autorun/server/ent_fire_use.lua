hook.Add( "KeyPress", "OpenDoors", function( ply, key )
	if key == IN_USE then

		local ToOpen = {
			func_door = true,
			func_door_rotating = true,
			func_movelinear = true,
		}
		local tr = ply:GetEyeTrace()

		if ToOpen[tr.Entity:GetClass()] and tr.HitPos:Distance(ply:GetPos()) <= 100 then
			if tr.Entity.ent_fire_use_open then
				tr.Entity:Fire("close")
				tr.Entity.ent_fire_use_open = false
			else
				tr.Entity:Fire("open")
				tr.Entity.ent_fire_use_open = true
			end
		end
	end
end)