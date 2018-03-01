local tag = "TakeDamageX"
local GM = GM or GAMEMODE
local physpick = false

local function IsPlayer(ent)
	return IsValid(ent) and ent:GetClass() == "player" or false
end

hook.Add("PhysgunPickup", tag, function(ply, ent)
	if IsValid(ply) and IsValid(ent) and not physpick then
		physpick = true
		local can_touch = hook.Run('PhysgunPickup', ply, ent)
		if can_touch then
			ent.droppedby = false -- Indicate that this entity was picked up, and that this variable is ready to be filled.
		end
		physpick = false
	end
end)

hook.Add("PhysgunDrop", tag, function(ply, ent)
	if IsValid(ply) and IsValid(ent) and ent.droppedby == false then
		ent.droppedby = {ply = ply, when = CurTime()}
	end
end)

GM.OldEntityTakeDamage = GM.OldEntityTakeDamage or GM.EntityTakeDamage
GM.OldDoPlayerDeath = GM.OldDoPlayerDeath or GM.DoPlayerDeath

function GM:EntityTakeDamage(ply, dmginfo)
	local inflictor = dmginfo:GetInflictor()
	local attacker  = dmginfo:GetAttacker()

	local actor  = attacker or inflictor
	local picker = actor.droppedby

	if picker and IsPlayer(picker.ply) and not IsPlayer(actor) then
		if (picker.when + 7) > CurTime() then
			actor = picker.ply -- Update `actor` variable.
			dmginfo:SetAttacker(actor)
			dmginfo:SetInflictor(attacker)
		end
	end

	ply.lastHurtBy = {ply = actor, when = CurTime()}
	return self:OldEntityTakeDamage(ply, dmginfo)
end

function GM:DoPlayerDeath(ply, attacker, dmginfo)
	if IsValid(ply) then
		if ply.lastHurtBy and ( (ply.lastHurtBy.when + 5) > CurTime() ) then
			attacker = ply.lastHurtBy.ply
			dmginfo:SetAttacker(attacker)
		end
	end
	return self:OldDoPlayerDeath(ply, attacker, dmginfo)
end