AddCSLuaFile()

local tag = "aowl_dance"

local function is_dancing(ply)
	return ply:GetNWBool(tag)
end

local function set_dancing(ply, b)
	ply:SetNWBool(tag, b)

	if SERVER then
		if b then
			hook.Add("PlayerDeath", tag, function(ply)
				if is_dancing(ply) then
					set_dancing(ply, false)
				end
			end)

			net.Start(tag)
				net.WriteBool(true)
			net.Broadcast()
		else
			for k,v in ipairs(player.GetAll()) do
				if v:GetNWBool(tag) then
					return
				end
			end

			net.Start(tag)
				net.WriteBool(false)
			net.Broadcast()
			hook.Remove("PlayerDeath", tag)
		end
	end
end

if CLIENT then
	local bpm = CreateClientConVar(tag .. "_bpm", 120, true, true)

	net.Receive(tag, function()
		local b = net.ReadBool()

		if b then
			hook.Add("ShouldDrawLocalPlayer", tag, function(ply)
				if is_dancing(ply) then
					return true
				end
			end)

			hook.Add("CalcView", tag, function(ply, pos)
				if not is_dancing(ply) then return end

				local pos = pos + ply:GetAimVector() * -100
				local ang = (ply:EyePos() - pos):Angle()

				return {
					origin = pos,
					angles = ang,
				}
			end)

			local beats = {}
			local suppress = false
			local last

			hook.Add("CreateMove", tag, function(cmd)
				if is_dancing(LocalPlayer()) then
					if cmd:KeyDown(IN_JUMP) then
						if not suppress then
							local time = RealTime()
							last = last or time
							table.insert(beats, time - last)
							last = time

							local temp = 0
							for k,v in pairs(beats) do temp = temp + v end
							temp = temp / #beats
							temp = 1 / temp

							if #beats > 5 then
								table.remove(beats, 1)
							end

							RunConsoleCommand(tag .. "_bpm", (temp * 60))
							RunConsoleCommand(tag .. "_setrate", bpm:GetInt())

							suppress = true
						end
					else
						suppress = false
					end
					cmd:SetButtons(0)
				end
			end)

			hook.Add("CalcMainActivity", tag, function(ply)
				if is_dancing(ply) then
					local bpm = (ply:GetNWBool(tag .. "_bpm") or 120) / 94
					local time = (RealTime() / 10) * bpm
					time = time%2
					if time > 1 then
						time = -time + 2
					end

					time = time * 0.8
					time = time + 0.11

					ply:SetCycle(time)

					return 0, ply:LookupSequence("taunt_dance")
				end
			end)
		else
			hook.Remove("CalcMainActivity", tag)
			hook.Remove("CreateMove", tag)
			hook.Remove("CalcView", tag)
			hook.Remove("ShouldDrawLocalPlayer", tag)
		end
	end)
end

if SERVER then
	util.AddNetworkString(tag)

	concommand.Add(tag .. "_setrate", function(ply, _, args)
		ply:SetNWBool(tag .. "_bpm", tonumber(args[1]))
	end)

	aowl.AddCommand("dance", function(ply)
		if not is_dancing(ply) then
			aowl.Message(ply, "Dance mode enabled. Tap space to the beat!")
			set_dancing(ply, true)
		else
			aowl.Message(ply, "Dance mode disabled.")
			set_dancing(ply, false)
		end
	end)
end