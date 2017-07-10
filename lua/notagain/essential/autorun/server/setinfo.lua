local META = FindMetaTable("Player")

function META:SetInfo(key, val)
	self.infonum_override = self.infonum_override or {}
	self.infonum_override[key] = val
end

META.OldGetInfoNum = META.OldGetInfoNum or META.GetInfoNum

function META:GetInfoNum(key, def, ...)
	if self.infonum_override and self.infonum_override[key] then
		return tonumber(self.infonum_override[key])
	end

	return self:OldGetInfoNum(key, def, ...)
end

META.OldGetInfo = META.OldGetInfo or META.GetInfo

function META:GetInfo(key, ...)
	if self.infonum_override and self.infonum_override[key] then
		return self.infonum_override[key]
	end

	return self:OldGetInfo(key, ...)
end