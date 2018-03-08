if SERVER then

	local function add_dir(dir)
		local files = file.Find("notagain/fishingmod/"..dir.."*", "LUA")
		for _, file_name in pairs(files) do
			AddCSLuaFile("notagain/fishingmod/"..dir .. file_name)
		end
	end

	add_dir("/")
	add_dir("client/")
	add_dir("client/pac_outfits/")
	add_dir("bait/")
	add_dir("fish/")
end

fishing = fishing or {}fishing.LineTension = 0include("utilities.lua")include("stats.lua")include("inventory.lua")include("restrictions.lua")if CLIENT then	--include("client/hud.lua")	include("client/camera.lua")	include("client/rod_screen.lua")endif SERVER then	include("server/spawning.lua")	include("server/inventory.lua")endinclude("base_entity.lua")include("base_bait.lua")include("base_fish.lua")include("seagulls.lua")function fishing.IncludeAllFiles(dir)	local files = file.Find("notagain/fishingmod/"..dir.."/*", "LUA")	for _, file_name in pairs(files) do
		include("notagain/fishingmod/"..dir.."/" .. file_name)	endend

hook.Add("pac_Initialized", "fishingmod", function()
	include("notagain/fishingmod/rod.lua")
	fishing.IncludeAllFiles("bait")	fishing.IncludeAllFiles("fish")
	hook.Remove("pac_Initialized", "fishingmod")
end)if SERVER then	concommand.Add("fishing_test", function(ply)		if ply ~= player.GetByUniqueID(--[[CapsAdmin]] "1416729906") then return end		ply:Give("weapon_fishing")		fishing.SetPlayerItemCount(ply, "chinese", math.random(50))		fishing.SetPlayerItemCount(ply, "melon", math.random(50))		fishing.SetPlayerItemCount(ply, "hula flyer", math.random(50))		local stats = fishing.GetStats(ply)		stats.rod_length = math.Rand(0.25, 0.5)		stats.string_max_tension = 20		stats.string_length = 5000	end)endreturn fishing