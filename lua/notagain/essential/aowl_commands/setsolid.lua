AddCSLuaFile()

hook.Add("ShouldCollide","PlayerNonSolidToggle", function(a, b)
	if a:IsPlayer() and a:GetInfoNum("cl_solid_mode",1) == 0 or b:IsPlayer() and b:GetInfoNum("cl_solid_mode",1) == 0 then
        return false
    end
end)

if CLIENT then
	CreateClientConVar("cl_solid_mode", "1", true, true, "Set to 0 to stop yourself from colliding with anything.")
end

if SERVER then
    aowl.AddCommand("setsolid|solid|notsolid", function(ply, line)
        if ply:GetInfoNum("cl_solid_mode",1) == 1 then
			ply:ConCommand("cl_solid_mode 0")
			ply:SetCustomCollisionCheck(true)
			ply:ChatPrint("You no longer collide with anything!")
		else
			ply:ConCommand("cl_solid_mode 1")
			ply:SetCustomCollisionCheck(false)
			ply:ChatPrint("You are now solid!")
		end
    end)
end
