if engine.ActiveGamemode() ~= "lambda" then return end

hook.Add("PlayerSpawn", "pac_server_lambda", function(ply)
	if SERVER then
		jrpg.SetRPG(ply, true)
	end

	timer.Simple(0, function()
		if ply:IsValid() then
			SafeRemoveEntity(ply.TrackerEntity)
		end
	end)
end)