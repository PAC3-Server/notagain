local where = (debug.getinfo(1, "S")).short_src
where = string.Explode("/",where)

for i=1,4 do
	where[#where] = nil -- Directory treversal in Lua what?
end

where = table.concat(where,"/")

local path = "notagain/gmafiles/"
local gma_path = where.."/gmafiles/"

local files,dirs = file.Find(path.."*", "LUA")
for _,file in next, files do
	print("Attempting to mount...", file)
	local success = game.MountGMA(gma_path..file)
	print(file,success and " Has been mounted." or " !!! Mounting Failed!")
	if success then 
		local id = string.match(file,"([0-9]+)%.gma")
		resource.AddWorkshop(id)
	end
end
