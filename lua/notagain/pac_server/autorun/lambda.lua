if gmod.GetGamemode().Name ~= "Lambda" then return end

hook.Add("PlayerSpawn", "pac_server_lambda", function(ply)
	timer.Simple(0, function()
		if ply:IsValid() then
			SafeRemoveEntity(ply.TrackerEntity)
		end
	end)
end)