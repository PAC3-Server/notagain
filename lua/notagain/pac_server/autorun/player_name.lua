local META = FindMetaTable("Player")

function META:GetProperName()
	if not IsValid(self) then return nil end
	local name,_ = string.gsub(self:GetName(),"(%^%d+)","")
	name,_ = string.gsub(name,"(<.->)","")
	name,_ = string.gsub(name,"(%(.*%))","")
	name,_ = string.gsub(name,"(%[.*%])","")
	return name
end

function player.FindByName(name)
	local name = string.lower(string.PatternSafe(name))
	local nlen = string.len(name)

	for _,v in pairs(player.GetAll()) do
		local curname = string.PatternSafe(v:GetProperName())
		local match = string.match(curname,name)

		if match and string.len(match) / nlen >= 0.5 then
			return v 
		end

	end

	return nil 
end
