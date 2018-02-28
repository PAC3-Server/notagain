vote = vote or {}

if CLIENT then
	local prettytext = requirex("pretty_text")

	function vote.Start(title, options, time, length)
		local P = 20
		local blur_size = 6
		vote.casted = nil
		hook.Add("HUDPaint", "vote", function()
			local Y = 150
			local w, h = prettytext.DrawText({
				font = "Roboto Black",
				text = title,
				x = P,
				y = Y,
				size = 30,
				blur_size = blur_size,
				x_align = 0.5,
			})

			Y = Y + h + 10

			for i,v in ipairs(options) do
				local w, h = prettytext.DrawText({
					font = "Roboto Medium",
					text = i .. ". " .. v,
					x = P,
					y = Y,
					size = 20,
					blur_size = blur_size,
					background_color = vote.GetPlayerVote(LocalPlayer()) == i and Color(0,255,0,255) or Color(0,0,0,255),
				})
				Y = Y + h + 5

				local votes = {}
				local size = h / 1.25

				for _, ply in ipairs(player.GetAll()) do
					if vote.GetPlayerVote(ply) == i then
						votes[i] = (votes[i] or 0) + 1
						avatar.Draw(ply, P + w + (votes[i]*size)+(votes[i]-1)*8, Y - size/2 - 5, size, nil,nil,nil, 3)
					end
				end
			end

			Y = Y + 10

			if not vote.GetPlayerVote(LocalPlayer()) then
				local w, h = prettytext.DrawText({
					text = "hold CTRL and press the number you want to vote",
					x = P,
					y = Y,
					size = 14,
					blur_size = blur_size,
				})
			end

			if input.IsControlDown() then
				for i,v in ipairs(options) do
					if input.IsKeyDown(KEY_0 + i) then
						vote.Cast(i)
					end
				end
			end
		end)
	end

	function vote.Stop()
		vote.stopped = true
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
		vote.started = true
	end)

	net.Receive("vote_stop", function()
		vote.started = false
		timer.Simple(3, function()
			hook.Remove("HUDPaint", "vote")
		end)
	end)

	if LocalPlayer() == me then

	end
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

		timer.Simple(time, function()
			vote.Stop()
		end)

		vote.started = true
		vote.options = options
		vote.callback = callback
	end

	function vote.Stop()
		net.Start("vote_stop")
		net.Broadcast()

		vote.started = false

		local score = {}
		for _, ply in ipairs(player.GetAll()) do
			local num = vote.GetPlayerVote(ply)
			if num then
				score[num] = score[num] or {count = 0, score = num}
				score[num].count = score[num].count + 1
			end
		end

		local list = {}
		for _,v in pairs(score) do
			table.insert(list, v)
		end

		table.sort(list, function(a, b) return a.count > b.count end)

		vote.callback(vote.options[list[1].score], list)
	end
end