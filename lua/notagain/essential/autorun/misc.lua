-- Commands that don't deserve their own file.

local META = FindMetaTable("Player")

function META:LookAt(pos)
	if isentity(pos) and IsValid(pos) then
		if pos:IsPlayer() or pos:IsNPC() then
			pos = pos:EyePos()
		end
	end

	self:SetEyeAngles( (pos - self:EyePos()):Angle() )
end
