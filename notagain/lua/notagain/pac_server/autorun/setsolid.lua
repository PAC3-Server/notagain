local solidvar = CreateClientConVar("solidmode", "1", true, true, "Solid Mode.  Set to 0 to stop yourself from colliding with anything." )

local function PlayerNonSolid(ent1,ent2)
	if (ent1:IsPlayer() && ent1:GetInfoNum("solidmode",1) == 0) || (ent2:IsPlayer() && ent2:GetInfoNum("solidmode",1) == 0) then return false end
end

hook.Add("ShouldCollide","PlayerNonSolidToggle",PlayerNonSolid)
	
if SERVER then

	local function ToggleCollisions(ply)
		if ply:GetInfoNum("solidmode",1) == 1 then 
			ply:ConCommand("solidmode 0")
			ply:SetCustomCollisionCheck(true)
			ply:PrintMessage(HUD_PRINTTALK,"You no longer collide with anything!")
		else 
			ply:ConCommand("solidmode 1")
			ply:SetCustomCollisionCheck(false)
			ply:PrintMessage(HUD_PRINTTALK,"You are now solid!")
		end	
	end
	
	local function PlayerCollisionChat(ply,txt,teamchat)
		local lowerText = string.lower(txt)
		local subText = string.sub(lowerText,1,string.len(lowerText))
		if subText == "!setsolid" then 
			ToggleCollisions(ply)
			return false 
		end
	end
	
	hook.Add("PlayerSay", "PlayerCollisionChat", PlayerCollisionChat)

	local function CC_PlayerCollisions(sender, command, arguments)
		if !IsValid(sender) then return end
		ToggleCollisions(sender)
	end

	concommand.Add("setsolid", CC_PlayerCollisions)

end
