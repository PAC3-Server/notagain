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

	net.Receive("teamrocket", function(len)
		local origin = net.ReadVector()

		local mat = Material("sprites/light_ignorez")
		local mat2 = CreateMaterial("teamrocket_" .. os.clock(), "UnlitGeneric", {
			["$BaseTexture"] = "particle/particle_glow_09",
			["$VertexColor"] = 1,
			["$VertexAlpha"] = 1,
			["$Additive"] = 1,
		})
		local duration = 1
		local delay = 3.75
		local max_speed = 5000
		local sound_played = false
		local start = RealTime()

		LocalPlayer():EmitSound("chatsounds/autoadd/capsadmin/jtechsfx/asdasd.ogg", 75, math.random(130, 150), 0.5)
		local id = "teamrocket_"..tostring({})

		hook.Add("HUDPaint", id, function()
			local time = RealTime()
			local delta = time - start

			if delta > duration then
				hook.Remove("HUDPaint", id)
				return
			end

			local size = math.sin((delta / duration) * math.pi) * 0.7
			local rotation = time * 100

			rotation = rotation ^ ((-(delta / duration)+1) * 0.5)

			local pos = origin:ToScreen()

			if pos.visible then
				surface.SetMaterial(mat2)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRectRotated(pos.x, pos.y, size * 128, size * 128, rotation)

				size = size * 6

				surface.SetMaterial(mat)
				surface.SetDrawColor(255, 255, 255, 255)
				local max = 8
				for i = 1, max do
					surface.DrawTexturedRectRotated(pos.x, pos.y, 10, size * 50 * math.sin(i), rotation + ((i / max) * math.pi * 2) * 360)
				end

				local max = 2
				for i = 1, max do
					surface.DrawTexturedRectRotated(pos.x, pos.y, 10, size * 50, -rotation - ((i / max) * math.pi * 2) * 360 - 45)
				end

				DrawSunbeams(0.3, math.abs(size)*0.025, 0.06, pos.x / ScrW(), pos.y / ScrH())
			end
		end)
	end)
end

if SERVER then
	util.AddNetworkString("teamrocket")
end

hook.Add("PhysgunPickup", tag, function(ply, ent)
	local canphysgun = ent:IsPlayer() and not ent:IsPhysgunImmune() and not ent:IsBeingPhysgunned()
	if not canphysgun then return end

	if ply.CanAlter then
		canphysgun = ply:CanAlter(ent)
	else
		canphysgun = ply:IsAdmin()
	end

	canphysgun = canphysgun or ent:IsBot()
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
}

hook.Add("PhysgunDrop", tag, function(ply, ent)
	if ent:IsPlayer() and ent._is_being_physgunned==ply then
		ent._pos_velocity = {}
		ent._is_being_physgunned = false

		ent:SetMoveType(ply:KeyDown(IN_ATTACK2) and ply:CheckUserGroupLevel("moderators") and MOVETYPE_NOCLIP or MOVETYPE_WALK)
		ent:SetOwner()

		if SERVER then
			local res = util.TraceLine({start = ent:GetPos(), endpos = ent:GetPos() + ent:GetVelocity() * 100, filter = ent})

			if res.HitSky then

				local info = DamageInfo()
				info:SetDamagePosition(ent:GetPos())
				info:SetDamage(ent:Health())
				info:SetDamageType(DMG_FALL)
				info:SetAttacker(Entity(0))
				info:SetInflictor(Entity(0))
				info:SetDamageForce(Vector(0,0,0))
				ent:TakeDamageInfo(info)

				local rag = ent:GetNWEntity("serverside_ragdoll")
				if rag:IsValid() then
					local snd = CreateSound(rag, table.Random(nnoo))
					snd:SetSoundLevel(85)
					snd:SetDSP(21)
					snd:Play()
					rag:CallOnRemove("teamrocket_stop_sound", function() snd:Stop() end)
					local phys = rag:GetPhysicsObject()
					if phys:IsValid() then

						rag:AddCallback("PhysicsCollide", function(ent, data)
							if data.HitEntity == Entity(0) then
								net.Start("teamrocket") net.WriteVector(data.HitPos) net.Broadcast()
								rag:Remove()
							end
						end)

						for i = 1, rag:GetPhysicsObjectCount() - 1 do
							local phys = rag:GetPhysicsObjectNum(i)
							phys:SetDamping(0, 0)
							phys:EnableGravity(false)
						end

						phys:SetDamping(0, 0)
						phys:EnableGravity(false)

						local dir = ent:GetVelocity():GetNormalized()
						local id = "team_rocket_" ..rag:EntIndex()
						hook.Add("Think", id, function()
							if phys:IsValid() then
								ent:SetMoveType(MOVETYPE_NONE)
								ent:SetPos(phys:GetPos())
								phys:AddAngleVelocity(Vector(0,0,300))
								phys:AddVelocity(dir * 400)
								phys:AddVelocity(phys:GetAngles():Right() * 150)
							else
								hook.Remove("Think", id)
							end
						end)
					end
				end
			end
		end

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