resource.AddWorkshop("546392647") -- Media Player

do
	local map_content = {
		ze_ffvii_mako_reactor_v5_3 = {"307755108"},
		gm_bluehills_test3 = {"243902601"},
	}

	local map = game.GetMap():lower()
	
	if map_content[map] and not file.Exists("maps/" .. map .. ".bz2", "GAME") then
		for _, id in ipairs(map_content[map]) do
			resource.AddWorkshop(id)
		end
	end
end

