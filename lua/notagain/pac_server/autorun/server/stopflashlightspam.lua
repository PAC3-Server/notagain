local spammers = {}
local complete = function() end

if PCTasks and PCTasks.Add and PCTasks.Complete then
	PCTasks.Add("The Illuminator","Be the shining beacon no one needs or wants.",3)
	complete = function(ply)
		PCTasks.Complete(ply,"The Illuminator")
	end
end

hook.Add("PlayerSwitchFlashlight", "flashlight-spam", function(ply, enabled)
	if ply:CanUseFlashlight() and enabled then
		spammers[tostring(ply:UserID())] = spammers[tostring(ply:UserID())] or {}
		local key = spammers[tostring(ply:UserID())]

		key.times = key.times and key.times + 1 or 1
		key.when = key.when or CurTime()

		if key.when+0.55 < CurTime() then
			if key.times > 3 then
				ply:Ignite(3,0)

				local can = ply:CanUseFlashlight()
				ply:AllowFlashlight(false)
				ply:EmitSound('buttons/button10.wav')

				timer.Simple(4, function()
					if IsValid(ply) then
						ply:AllowFlashlight(can)
						spammers[tostring(ply:UserID())] = nil
						complete(ply)
					end
				end)
			end
			spammers[tostring(ply:UserID())] = nil
		end
	end
end)
