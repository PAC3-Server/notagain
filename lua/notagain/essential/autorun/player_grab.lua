local tag = "player_grab"

do -- meta
	local PLAYER = FindMetaTable("Player")

	function PLAYER:IsBeingPhysgunned()
		local pl = self._is_being_physgunned
		if pl then
			if isentity(pl) and not IsValid(pl) then
				return false
			end
			return true
		end
	end

	function PLAYER:SetPhysgunImmune(bool)
		self._physgun_immune = bool
	end

	function PLAYER:IsPhysgunImmune()
		return self._physgun_immune == true
	end
end

if CLIENT then
	CreateClientConVar(tag .. "_dont_touch_me", "0", true, true)
end

hook.Add("PhysgunPickup", tag, function(ply, ent)
	local canphysgun = ent:IsPlayer() and not ent:IsPhysgunImmune() and not ent:IsBeingPhysgunned()
	if not canphysgun then return end

	if ply.CanAlter then
		canphysgun = ply:CanAlter(ent)
	else
		canphysgun = ply:IsAdmin()
	end

	canphysgun = canphysgun or ( ent.IsBanned and ent:IsBanned())

	if not canphysgun then return end

	if IsValid(ent._is_being_physgunned) then
		if ent._is_being_physgunned~=ply then return end
	end

	ent._is_being_physgunned = ply

	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetOwner(ply)

	return true
end)

local nnoo = {
	"chatsounds/autoadd/ssbb_peach/noooo.ogg",
	"chatsounds/autoadd/ssbb_pit/huaaa.ogg",
	"vo/halloween_merasmus/sf12_defeated12.mp3",
	"vo/halloween_merasmus/sf12_defeated11.mp3",
	"vo/halloween_merasmus/sf12_defeated11.mp3",
	--"player/survivor/voice/manager/fall01.wav",
	--"player/survivor/voice/manager/fall02.wav",
	"player/survivor/voice/manager/fall03.wav",
	"chatsounds/autoadd/instagib/aaaaa.ogg",
	"chatsounds/autoadd/hotd2_npcs/noooo/noooo.ogg",
	"vo/outland_12a/launch/al_launch_noooo.wav",
}

hook.Add("PhysgunDrop", tag, function(ply, ent)
	if ent:IsPlayer() and ent._is_being_physgunned==ply then
		ent._pos_velocity = {}
		ent._is_being_physgunned = false

		ent:SetMoveType(ply:KeyDown(IN_ATTACK2) and ply:CheckUserGroupLevel("moderators") and MOVETYPE_NOCLIP or MOVETYPE_WALK)
		ent:SetOwner()
		hook.Run("PhysgunThrowPlayer", ply, ent)

		return true
	end
end)

-- attempt to stop suicides during physgun
hook.Add("CanPlayerSuicide", tag, function(ply)
	if ply:IsBeingPhysgunned() then
		return false
	end
end)

hook.Add("PlayerDeath", tag, function(ply)
	if ply:IsBeingPhysgunned() then
		return false
	end
end)

hook.Add("PlayerNoClip", tag, function(ply)
	if ply:IsBeingPhysgunned() then
		return false
	end
end)

do -- throw
	local function GetAverage(tbl)
		if #tbl == 1 then return tbl[1] end

		local average = vector_origin

		for key, vec in pairs(tbl) do
			average = average + vec
		end

		return average / #tbl
	end

	local function CalcVelocity(self, pos)
		self._pos_velocity = self._pos_velocity or {}

		if #self._pos_velocity > 10 then
			table.remove(self._pos_velocity, 1)
		end

		table.insert(self._pos_velocity, pos)

		return GetAverage(self._pos_velocity)
	end

	hook.Add("Move", tag, function(ply, data)

		if ply:IsBeingPhysgunned() then
			local vel = CalcVelocity(ply, data:GetOrigin())
			if vel:Length() > 10 then
				data:SetVelocity((data:GetOrigin() - vel) * 8)
			end

			local owner = ply:GetOwner()

			if owner:IsPlayer() then
				if owner:KeyDown(IN_USE) then
					local ang = ply:GetAngles()
					ply:SetEyeAngles(Angle(ang.p, ang.y, 0))
				end
			end
		end

	end)
end