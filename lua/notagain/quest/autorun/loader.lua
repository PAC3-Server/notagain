QUESTS_PATH = "notagain/quest/quests/"

local colgood = Color(0,160,220)
local colbad  = Color(255,127,127)
local coldef  = Color(244,167,66)

local Good = function(name,filename,where)
	MsgC(coldef,"[Quest - " .. where .. "] >> ",colgood,filename .. " loaded\n")
end

local Bad = function(filename,err,where)
	MsgC(coldef,"[Quest - " .. where .. "] >> ",colbad,"Couldn't load " .. filename .. "\n " .. err .. "\n")
end

return function(path)
	local path    = path or QUESTS_PATH
	local pline   = ("-"):rep(30) .. "\n"

	MsgC(coldef,"- Quest -\n")
	MsgC(coldef,pline)

	for _,filename in pairs((file.Find(path.."*.lua","LUA"))) do
		AddCSLuaFile(path..filename)
		local quest = CompileFile(path..filename)
		local succ,err = pcall(quest)
		if succ then
			Good(err,filename,"SH")
		else
			Bad(filename,err,"SH")
		end
	end

	if SERVER then
		for _,filename in pairs((file.Find(path.."server/*.lua","LUA"))) do
			local quest = CompileFile(path.."server/"..filename)
			local succ,err = pcall(quest)
            if succ then
                Good(err,filename,"SV")
            else
                Bad(filename,err,"SV")
            end
		end

		for _,filename in pairs((file.Find(path.."client/*.lua","LUA"))) do
			AddCSLuaFile(path.."client/"..filename)
		end
	end

	if CLIENT then
		for _,filename in pairs((file.Find(path.."client/*.lua","LUA"))) do
			local quest = CompileFile(path.."client/"..filename)
			local succ,err = pcall(quest)
            if succ then
                Good(err,filename,"CL")
            else
                Bad(filename,err,"CL")
            end
		end
	end

	MsgC(coldef,pline)
end