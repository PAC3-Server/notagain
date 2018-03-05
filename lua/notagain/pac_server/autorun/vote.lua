vote = vote or {}

if CLIENT then
	local prettytext = requirex("pretty_text")

	function vote.Start(title, options, time, length)
		local P = 20
		local blur_size = 4
		local blur_overdraw = 6
		vote.fade_time = nil
		vote.winner = nil
		vote.fail_reason = nil
		hook.Add("HUDPaint", "vote", function()
			local f = 1
			local time_left = math.max(math.Round(-(CurTime() - time) + length), 0)

			if vote.fade_time then
				time_left = 0

				f = math.Clamp((vote.fade_time - RealTime()) / 3 + 0.5, 0, 1)
				f = f ^ 0.5

				if f == 0 then
					hook.Remove("HUDPaint", "vote")
					return
				end
			end

			surface.SetAlphaMultiplier(f)

			local Y = 150
			local w, h = prettytext.DrawText({
				font = "Roboto Black",
				text = title,
				x = P,
				y = Y,
				size = 30,
				blur_size = blur_size,
				blur_overdraw = blur_overdraw,
			})
			Y = Y + h + 10
			local max_width = 0
			local votes = {}

			for i,v in ipairs(options) do
				votes[i] = votes[i] or {count = 0}
				local key = i
				if key > 9 then
					key = string.char(64 + key - 9)
				end
				local w, h = prettytext.DrawText({
					font = "Roboto Medium",
					text = key .. ". " .. v,
					x = P,
					y = Y,
					size = 20,
					blur_size = blur_size,
					background_color =
					(vote.winner == i and Color(0,255,0,255)) or
					vote.GetPlayerVote(LocalPlayer()) == i and Color(150,150,0,255) or Color(0,0,0,255),
					blur_overdraw = blur_overdraw,
				})
				Y = Y + h + 5
				votes[i].y = Y

				max_width = math.max(max_width, w)
			end

			local size = h / 1.25

			for i,v in ipairs(options) do
				for _, ply in ipairs(player.GetAll()) do
					if vote.GetPlayerVote(ply) == i then
						votes[i].count = votes[i].count + 1
						avatar.Draw(ply, P + max_width + (votes[i].count*size)+(votes[i].count-1)*8, votes[i].y - size/2 - 5, size, nil,nil,nil, 3)
					end
				end
			end

			if vote.fade_time then
				local w, h = prettytext.DrawText({
					text = vote.fail_reason or "the voting has ended",
					x = P,
					y = Y,
					size = 14,
					blur_size = blur_size,
					background_color = Color(255,0,0,255),
					blur_overdraw = blur_overdraw,
				})
				Y = Y + h + 10
			elseif not vote.GetPlayerVote(LocalPlayer()) then
				local w, h = prettytext.DrawText({
					font = "Roboto Black",
					text = "CTRL + *NUMBER* to vote",
					x = P,
					y = Y,
					size = 20,
					blur_size = blur_size*2,
					blur_overdraw = blur_overdraw*2,
					background_color = input.IsControlDown() and Color(0,0,255, 255) or Color(0,0,255,(math.sin(RealTime()*20)*0.5+0.5) * 55),
				})
				Y = Y + h + 10
			end

			if time_left > 0 then
				local w, h = prettytext.DrawText({
					font = "Roboto Black",
					text = time_left .. " seconds left",
					x = P,
					y = Y,
					size = 30,
					blur_size = blur_size,
					blur_overdraw = blur_overdraw,
				})
				Y = Y + h + 10
			end

			if input.IsControlDown() then
				for i,v in ipairs(options) do
					if input.IsKeyDown(KEY_0 + i) then
						vote.Cast(i)
					end
				end
			end

			surface.SetAlphaMultiplier(1)
		end)
		vote.started = true
	end

	function vote.Stop(winner)
		vote.winner = winner
		vote.started = false
		vote.fade_time = RealTime() + 3
	end

	function vote.Cast(i)
		RunConsoleCommand("vote_cast", i)
	end

	net.Receive("vote_start", function()
		local title = net.ReadString()
		local options = net.ReadTable()
		local time = net.ReadFloat()
		local length = net.ReadFloat()

		vote.Start(title, options, time, length)
	end)

	net.Receive("vote_stop", function()
		local result = net.ReadInt(8)
		local ok = net.ReadBool()
		local err = net.ReadString()
		if not ok then vote.fail_reason = err end
		vote.Stop(result)
	end)
end

function vote.GetPlayerVote(ply)
	local vote = ply:GetNW2Int("vote_cast", -1)
	if vote ~= -1 then
		return vote
	end
end

if SERVER then
	util.AddNetworkString("vote_start")
	util.AddNetworkString("vote_stop")

	concommand.Add("vote_cast", function(ply, _, args)
		if not vote.started then return end
		local num = tonumber(args[1])

		ply:SetNW2Int("vote_cast", num)
	end)

	function vote.Start(title, options, time, callback)
		for _, ply in ipairs(player.GetAll()) do
			ply:SetNW2Int("vote_cast", -1)
		end

		net.Start("vote_start")
			net.WriteString(title)
			net.WriteTable(options)
			net.WriteFloat(CurTime())
			net.WriteFloat(time)
		net.Broadcast()

		timer.Create("voting", time, 1, function()
			vote.Stop()
		end)

		vote.started = true
		vote.options = options
		vote.callback = callback
	end

	function vote.Stop()
		vote.started = false

		local score = {}
		local voter_count = 0
		for _, ply in ipairs(player.GetAll()) do
			local num = vote.GetPlayerVote(ply)
			if num then
				score[num] = score[num] or {count = 0, score = num}
				score[num].count = score[num].count + 1
				voter_count = voter_count + 1
			end
		end

		local list = {}
		for _,v in pairs(score) do
			table.insert(list, v)
		end

		table.sort(list, function(a, b) return a.count > b.count end)

		local ok, msg = vote.callback(list[1] and vote.options[list[1].score], voter_count, (voter_count/player.GetCount())*100, list)

		if ok == nil then ok = true end

		net.Start("vote_stop")
			net.WriteInt(list[1] and list[1].score or -1, 8)
			net.WriteBool(ok)
			if msg then
				net.WriteString(msg)
			end
		net.Broadcast()
	end

	if me then
	--	vote.Start("which noodles do you like the most?", {"udon", "soba", "somen", "egg noodles", "rice noodles", "cellophane noodles"}, 15, print)
	end

	aowl.AddCommand("votekick=player,string",function(_,line, ply, reason)
		vote.Start("kick " .. ply:Nick() .. "? (" .. reason .. ")", {"yes", "no"}, 15, function(res, voter_count, percent)
			if percent < 60 then
				return false, "need more than 60% of players voting"
			end

			if res == "yes" then
				ply:Kick("votekicked")
			else

			end
		end)
	end)
end