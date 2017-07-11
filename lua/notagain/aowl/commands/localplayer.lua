AddCSLuaFile()

if CLIENT then
	aowl.AddCommand("fakedie=string[],string[],boolean", function(pl, cmd, killer, icon, swap)
		local victim = pl:Name()
		local killer_team = -1
		local victim_team = pl:Team()

		if swap then
			victim, killer = killer, victim
			victim_team, killer_team = killer_team, victim_team
		end

		GAMEMODE:AddDeathNotice(killer, killer_team, icon, victim, victim_team)
	end)

	aowl.AddCommand("ctp|thirdperson|view|3p", function(ply, line)
		if ply ~= LocalPlayer() then return end

		if ctp.Enabled then
			ctp.Disable()
		else
			ctp.Enable()
		end
	end, "localplayer")

	aowl.AddCommand("g|search", function(ply, line)
		local parts = string.Explode(" ", line)
		gui.OpenURL("https://www.google.com/#q="..table.concat( parts, "+", 1, #parts ))
	end, "localplayer")

	aowl.AddCommand("cmd|console", function(ply, line, cmd)
		LocalPlayer():ConCommand(line)
	end, "localplayer")

	aowl.AddCommand("decals|cleardecals", function(ply, line)
		ply:ConCommand("r_cleardecals")
	end, "localplayer")

	do -- ignore players
		local ref = 0

		aowl.AddCommand("ignore|undraw=player",function(ply, line, ent)
			if ply ~= LocalPlayer() then return end

			ent.ignore_draw = true

			if pac and pace then
				pac.IgnoreEntity(ent)
			end

			ref = ref + 1

			hook.Add("PrePlayerDraw", "ignore_draw", function(ply)
				if ply.ignore_draw then
					ply:SetNoDraw(true)
					ply:SetNotSolid(true)
					return true
				end
			end)

			hook.Add("pac_OnWoreOutfit", "ignore_draw", function(_, ply)
				if ply.ignore_draw then
					pac.IgnoreEntity(ply)
				end
			end)
		end)

		aowl.AddCommand("unignore|draw=player",function(ply, line, ent)
			if ply ~= LocalPlayer() then return end

			if ent.ignore_draw then
				ent.ignore_draw = nil

				ent:SetNoDraw(false)
				ent:SetNotSolid(false)

				if pac and pace then
					pac.UnIgnoreEntity(ent)
				end

				ref = ref - 1
			end

			if ref <= 0 then
				hook.Remove("PrePlayerDraw", "ignore_draw")
				hook.Remove("pac_OnWoreOutfit", "ignore_draw")
			end
		end)
	end

end
