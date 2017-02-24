hook.Add("PlayerInitialSpawn", "player_collision", function(ply)
	ply:SetNoCollideWithTeammates(false)
	ply:SetAvoidPlayers(false)
end)