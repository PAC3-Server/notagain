local solidvar = CreateClientConVar("cl_solid_mode", "1", true, true, "Set to 0 to stop yourself from colliding with anything." )

local function PlayerNonSolid(ent1,ent2)
	if ent1:IsPlayer() and ent1:GetInfoNum("cl_solid_mode",1) == 0 or ent2:IsPlayer() and ent2:GetInfoNum("cl_solid_mode",1) == 0 then
        return false
    end
end

hook.Add("ShouldCollide","PlayerNonSolidToggle",PlayerNonSolid)

if SERVER then

	local function ToggleCollisions(ply)
		if ply:GetInfoNum("cl_solid_mode",1) == 1 then
			ply:ConCommand("cl_solid_mode 0")
			ply:SetCustomCollisionCheck(true)
			ply:PrintMessage(HUD_PRINTTALK,"You no longer collide with anything!")
		else
			ply:ConCommand("cl_solid_mode 1")
			ply:SetCustomCollisionCheck(false)
			ply:PrintMessage(HUD_PRINTTALK,"You are now solid!")
		end
	end

	local function CC_PlayerCollisions(sender, command, arguments)
		if !IsValid(sender) then return end
		ToggleCollisions(sender)
	end

	concommand.Add("setsolid",CC_PlayerCollisions)

    aowl.AddCommand({"setsolid","solid","notsolid"},function(ply,line)
        if not IsValid(ply) then return end
        ply:ConCommand("setsolid")
    end,"players",true)

end
