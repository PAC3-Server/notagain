local weps = {
	"weapon_physgun",
	"weapon_physcannon",
	"gmod_camera",
	"gmod_tool",
	"none",
}

hook.Add("PlayerLoadout","ReplaceDefault",function(pl)
	for _,w in pairs(weps) do
		pl:Give(w)
	end
	return true
end)
