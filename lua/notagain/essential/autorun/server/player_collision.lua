if engine.ActiveGamemode() ~= "sandbox" then return end

hook.Add("PlayerSpawn", "player_collision", function(ply)
	timer.Simple(0, function()
		ply:SetNoCollideWithTeammates(false)
		ply:SetAvoidPlayers(false)
	end)
end)