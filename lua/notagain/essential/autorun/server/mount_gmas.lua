local path = "notagain/gmafiles/"
local files,dirs = file.Find(path.."*", "LUA")
for _,file in next, files do
   print("Attempting to mount...", path..file)
   local success, info = game.MountGMA(path..file)
   print(path..file,success and " Has been mounted." or " !!! Mounting Failed!")
   if success then PrintTable(info) end
end
