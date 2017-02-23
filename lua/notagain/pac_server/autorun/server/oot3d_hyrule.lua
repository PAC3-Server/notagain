if game.GetMap() ~= "oot3d_hyrule" then return end

hook.Add("InitPostEntity", "fixmap", function()
	for _, ent in ipairs(ents.FindByClass("env_sound*")) do
		ent:Remove()
	end
	hook.Remove("InitPostEntity", "fixmap")
end)
