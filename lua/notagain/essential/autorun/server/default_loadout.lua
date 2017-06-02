local weps = {
	"weapon_physgun",
	"weapon_physcannon",
	"gmod_camera",
	"gmod_tool",
	"none",
	"weapon_medkit",
}

hook.Add("PlayerLoadout", "default_loadout", function(ply)
	for _, name in ipairs(weps) do
		ply:Give(name)
	end
	return true
end)
