local help = [[0 = off, 1 = on, 2 = world damage, 3 = non-friend damage, 4 = self damage
 -- You may combine variables for diffrent results for example 23, means god against world damage, and non-friend damage.
 -- Note, that 0 disables everything, and 1 enables full godmode.]]

if CLIENT then
	CreateClientConVar("cl_godmode", "0", true, true, help)

	cvars.AddChangeCallback("cl_godmode", function(name, old, new)
		net.Start("cl_godmode")
		net.SendToServer()
	end)
else
	util.AddNetworkString("cl_godmode")
	net.Receive("cl_godmode", function(len, ply)
		if ply:GetInfo("cl_godmode") == "1" then
			ply:GodEnable()
		else
			ply:GodDisable()
		end
	end)

	hook.Add("EntityTakeDamage", "cl_godmode", function(ply, dmginfo)
		if IsValid(ply) then
			local infoTable = {}
			local block = false

			do
				local actor = dmginfo:GetAttacker() or dmginfo:GetInflictor()
				local infoStr = ply.GetInfo and ply:GetInfo("cl_godmode") or "[no info]"

				if infoStr == "0" then
					return
				elseif infoStr == "1" then
					block = true
					return
				end

				string.gsub(infoStr, ".", function(char) table.insert(infoTable, char) end)

				for _,v in next, infoTable do
					if actor == game.GetWorld() and v == "2" then
						block = true
					elseif actor.CanAlter and ( not actor:CanAlter(ply) ) and v == "3" then
						block = true
					elseif actor == ply and v == "4" then
						block = true
					end
				end
			end

			if block then
				return true
			end
		end
	end)

	hook.Add("PlayerSpawn", "cl_godmode", function(ply)
		timer.Simple(0.3, function()
			if IsValid(ply) and ply.GetInfo and ply:GetInfo("cl_godmode") == "1" then
				ply:GodEnable()
			else
				ply:GodDisable()
			end
		end)
	end)
end
