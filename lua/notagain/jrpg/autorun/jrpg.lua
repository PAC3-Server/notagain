jrpg = jrpg or {}

if CLIENT then
	function jrpg.IsFriend(ent)
		return ent == LocalPlayer() or ent:IsPlayer() and ent:GetFriendStatus() == "friend" or IsFriendEntityName(ent:GetClass())
	end
end

if SERVER then
	function jrpg.IsFriend(a, b)
		if b:IsNPC() and IsFriendEntityName(b:GetClass()) then
			return true
		end

		return a:IsFriend(b)
	end
end

function jrpg.FindHeadPos(ent)
	if not ent.bc_head or ent.bc_last_mdl ~= ent:GetModel() then
		for i = 0, ent:GetBoneCount() do
			local name = ent:GetBoneName(i):lower()
			if name:find("head") then
				ent.bc_head = i
				ent.bc_last_mdl = ent:GetModel()
				break
			end
		end
	end

	if ent.bc_head then
		local m = ent:GetBoneMatrix(ent.bc_head)
		if m then
			local pos = m:GetTranslation()
			if pos ~= ent:GetPos() then
				return pos
			end
		end
	end

	return ent:EyePos(), ent:EyeAngles()
end