require("stringtable")

GetAllStringTables = stringtable.GetNames
StringTable = stringtable.Find

local stringtable_Get = stringtable.Get
function stringtable.Get(id)
	if isstring(id) then
		return stringtable.Find(id)
	end

	return stringtable_Get(id)
end

local META = FindMetaTable("stringtable")
if META ~= nil then
	META.Count = META.GetNumStrings
	META.GetTableStrings = META.GetStrings
	META.GetTableData = META.GetStringsUserData
	META.GetTableID = META.GetID
	META.SetData = META.SetStringUserData
	META.GetData = META.GetStringUserData

	function META:GetBool(index)
		local userdata = self:GetStringUserData(index)
		return #userdata >= 1 and string.byte(userdata) == 1
	end

	function META:GetNumber(index)
		local userdata = self:GetStringUserData(index)
		if #userdata >= 4 then
			local b1, b2, b3, b4 = string.byte(userdata, 1, 4)
			return b1 + b2 * 2^8 + b3 * 2^16 + bit.band(b4, 0x7F) * 2^24 - bit.band(b4, 0x80) * 2^24
		end
	end

	META.GetInteger = META.GetNumber

	function META:GetUnsignedInteger(index)
		local userdata = self:GetStringUserData(index)
		if #userdata >= 4 then
			local b1, b2, b3, b4 = string.byte(userdata, 1, 4)
			return b1 + b2 * 2^8 + b3 * 2^16 + b4 * 2^24
		end
	end
end

return stringtable