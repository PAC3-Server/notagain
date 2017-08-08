AddCSLuaFile()

if SERVER then
	util.AddNetworkString("aowl_achievements")

	aowl.AddCommand("achievements|tasks=player", function(ply, line,target)
		local target = target or ply
		net.Start("aowl_achievements")
		net.WriteEntity(target)
		net.Send(ply)
	end)
end

if CLIENT then
	net.Receive("aowl_achievements",function()
		local target = net.ReadEntity()
		local panel = vgui.Create("PCTasksPanel")
    panel:MakePopup()
    panel:Setup(target)
	end)
end
