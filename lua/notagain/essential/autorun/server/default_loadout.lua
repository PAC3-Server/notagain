if engine.ActiveGamemode() ~= "sandbox" then return end

local weps = {
	"weapon_crowbar",
	"weapon_physgun",
	"weapon_physcannon",
	"gmod_camera",
	"gmod_tool",
	"none",
	"weapon_medkit",
	"weapon_slap",
}

hook.Add("PlayerLoadout", "default_loadout", function(ply)
	for _, name in ipairs(weps) do
		ply:Give(name)
	end
	ply:SelectWeapon("none")
	return true
end)
