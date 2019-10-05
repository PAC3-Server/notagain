if CLIENT then
	local icons = {
		oot3d_hyrule = "https://steamuserimages-a.akamaihd.net/ugc/257091088006490512/1ED65707DD3904B69FA9E0BAC577CD23988E93A1/?interpolation=lanczos-none&output-format=jpeg&output-quality=95&fit=inside%7C637%3A358&composite-to=*,*%7C637%3A358&background-color=black",
		trade_clocktown_v1a = "https://teamwork.tf/images/map_context/trade_clocktown/spectator_0.jpg",
		ze_ashen_keep_v0_3 = "https://i.imgur.com/CF2ObBT.jpg",
		ze_ffvii_cosmo_canyon_v4fix = "https://files.gamebanana.com/img/ss/maps/530-90_571365c6a3b9e.jpg",
		ze_ffxii_westersand_v6_7 = "https://files.gamebanana.com/img/ss/maps/5172586c518ea.jpg",
		ze_dark_souls_b5 = "https://files.gamebanana.com/img/ss/maps/530-90_57135e89181d8.jpg",
	}

	local maps = {}
	local votestate = g_mapvote_state or {}
	local panel = NULL

	g_mapvote_state = votestate

	function ShowMapVote()
		if panel:IsValid() then
			panel:Remove()
		end

		panel = vgui.Create("DFrame")
		panel:SetTitle("mapvote")
		panel:SetSize(ScrW(), ScrH())
		panel:Center()
		panel:MakePopup()
		panel:SetSizable(true)

		local scroll = panel:Add("DScrollPanel")
		scroll:Dock(FILL)

		local map_list = scroll:Add("DIconLayout")
		map_list:Dock(FILL)
		map_list:SetSpaceX(5)
		map_list:SetSpaceY(5)

		for i,v in ipairs(maps) do
			local icon = map_list:Add("DButton")
			icon:SetText("")

			local e = requirex("goluwa").env
			local tex = e.render.CreateTextureFromPath(icons[v] or ("https://image.gametracker.com/images/maps/160x120/garrysmod/"..v..".jpg"))
			icon.Paint = function(_,w,h)
				local x, y = icon:LocalToScreen(0,0)
				e.gfx.DrawRect(x,y,w,h,tex)
			end
			icon:SetSize(200, 200)
			local search = icon:Add("DImageButton")
			search:SetImage("icon16/find.png")
			search:SetSize(16,16)
			search.DoClick = function() gui.OpenURL("https://www.google.no/search?q="..v.."&tbm=isch") end
			search:AlignTop()
			search:AlignLeft()

			local check = icon:Add("DCheckBox")
			check:AlignTop()
			check:AlignRight()
			check:SetChecked(votestate[v])
			check.OnChange = function(_, b)
				votestate[v] = b
				RunConsoleCommand("mapvote", v, b and "1" or "0")
			end

			icon.DoClick = function() check:Toggle() end

			local label = icon:Add("DLabel")
			label:SetText(v)
			label:SizeToContents()
			label:AlignBottom(2)
			label:CenterHorizontal()
			label:SetExpensiveShadow(1, Color(0,0,0,255))
			label:NoClipping(true)
			label.Paint = function(_,w,h) surface.SetDrawColor(0,0,0,250)surface.DrawRect(0-5,0,w+10,h) end
		end
	end

	net.Receive("mapvote_maps", function()
		maps = net.ReadTable()

		if panel:IsValid() then
			ShowMapVote()
		end
	end)
end

if SERVER then

	local blacklist = {
		spacial_bullshit = true,
		gm_eochaid_packed = true,
	}

	util.AddNetworkString("mapvote_maps")

	local maps = {}
	local maps2 = {}

	local files = table.Add(file.Find("maps/*.bsp", "MOD"), file.Find("maps/*.bsp", "THIRDPARTY"))

	for _, name in pairs(files) do
		name = name:match("(.+)%.bsp")
		if not blacklist[name] then
			table.insert(maps, name)
			maps2[name] = true
		end
	end

	local votes = {}

	hook.Add("PlayerInitialSpawn", "mapvote", function(ply)
		net.Start("mapvote_maps")
			net.WriteTable(maps)
		net.Send(ply)
	end)

	concommand.Add("mapvote", function(ply, _, args)
		local name = args[1]
		local b = args[2] == "1"
		if maps2[name] then
			ply.mapvotes = ply.mapvotes or {}
			ply.mapvotes[name] = b
			if b then
				PrintMessage(HUD_PRINTTALK, ply:Nick() .. " map voted for " .. name)
			else
				PrintMessage(HUD_PRINTTALK, ply:Nick() .. " map unvoted " .. name)
			end
		end
	end)

	function GetMapVotes()
		local list = {}

		for _, name in ipairs(maps) do
			list[name] = {score = 0, players = {}}
		end

		for _, ply in ipairs(player.GetAll()) do
			if ply.mapvotes then
				for name, vote in pairs(ply.mapvotes) do
					if vote then
						list[name].score = list[name].score + 1
						table.insert(list[name].players, ply)
					end
				end
			end
		end

		local sorted = {}

		for name, data in pairs(list) do
			table.insert(sorted, {
				name = name,
				players = data.players,
				score = (data.score / player.GetCount()) * 100
			})
		end

		table.sort(sorted, function(a, b)
			return a.score > b.score
		end)

		return sorted
	end

	timer.Create("mapvote", 1, 0, function()
		local map_info = GetMapVotes()[1]
		if map_info.score >= 70 then
			timer.Pause("mapvote")
			vote.Start(map_info.score .. "% has voted for "..map_info.name..". Change map?", {"yes", "no"}, 20, function(res)
				if res == "yes" then
					aowl.CountDown(10, "CHANGING MAP TO " .. map_info.name, function()
						cookie.Set("mapvote_lastmap", map_info.name)
						game.ConsoleCommand("changelevel " .. map_info.name .. "\n")
					end)
				else
					for _, ply in ipairs(player.GetAll()) do
						ply.mapvotes = nil
					end
					BroadcastLua("table.Empty(g_mapvote_state)")
				end
				timer.UnPause("mapvote")
			end)
		end
	end)

	aowl.AddCommand("mapvote|votemap", function(ply)
		ply:SendLua("ShowMapVote()")
	end)

	local voted_map = cookie.GetString("mapvote_lastmap", game.GetMap())
	if game.GetMap() ~= voted_map then
		cookie.Set("mapvote_lastmap", voted_map)
		game.ConsoleCommand("changelevel " .. voted_map .. "\n")
	end

	for _, ply in ipairs(player.GetAll()) do
		hook.GetTable().PlayerInitialSpawn.mapvote(ply)
		--ply.mapvotes = nil
	end
end
