local path = "notagain/gmafiles/"
local gma_path = "addons/notagain/lua/"..path

local files,dirs = file.Find(path.."*", "LUA")
for _,file in next, files do
	print("Attempting to mount...", path..file)
	local success = game.MountGMA(gma_path..file)
	print(path..file,success and " Has been mounted." or " !!! Mounting Failed!")
	if success then 
		local id = string.match(file,"([0-9]+)%.gma")
		resource.AddWorkshop(id)
	end
end
