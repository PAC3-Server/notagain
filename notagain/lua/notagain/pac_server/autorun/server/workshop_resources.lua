resource.AddWorkshop("546392647") -- Media Player
resource.AddWorkshop("131759821") -- VJ NPC Base
resource.AddWorkshop("111626188") -- Dark Messiah NPCS

do
	local map_content = {
		ze_ffvii_mako_reactor_v5_3 = {"307755108"},
		gm_bluehills_test3 = {"243902601"},
		gm_abstraction_extended = {"734919940"},
	}

	local map = game.GetMap():lower()
	
	if map_content[map] and not file.Exists("maps/" .. map .. ".bz2", "GAME") then
		for _, id in ipairs(map_content[map]) do
			resource.AddWorkshop(id)
		end
	end
end

