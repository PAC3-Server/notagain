hook.Add("PlayerInitialSpawn", "player_collision", function(ply)
	ply:SetNoCollideWithTeammates(true)
	ply:SetAvoidPlayers(false)
end)