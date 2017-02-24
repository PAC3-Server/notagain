hook.Add("PlayerInitialSpawn", "player_collision", function(ply)
	ent:SetNoCollideWithTeammates(true)
end)