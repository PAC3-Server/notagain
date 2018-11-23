if CLIENT then
	local ShakeList = {}
	
	function jrpg.AddShake(pos, amp, freq, dur, rad)
		table.insert(ShakeList, {
            pos = pos,
            amp = amp,
            freq = freq,
            dur = dur,
            endtime = dur + CurTime(),
            rad = rad,
            nextshake = 0,
            offset = vector_origin,
            angle = 0
		})
	end
	
	net.Receive("jrpg_screenshake", function(msg)
		local pos = net.ReadVector()
		local amp = net.ReadFloat()
		local freq = net.ReadFloat()
		local dur = net.ReadFloat()
		local rad = net.ReadFloat()
		
		jrpg.AddShake(pos, amp, freq, dur, rad)		
	end)
	
	local function CalcShake()
		local count = #ShakeList
		
		if count == 0 then
			return false
		end
		
		local ct = CurTime()
		
		local totalOffset = vector_origin
		local totalAngle = 0
		
		for i = count, 1, -1 do
			local shake = ShakeList[ i ]
			if shake.endtime > 0 then
				if ct > shake.endtime or shake.dur <= 0 or shake.amp <= 0 or shake.freq <= 0 then
					table.remove(ShakeList, i)
				else
					if ct > shake.nextshake then
						shake.nextshake = ct + (1.0 / shake.freq)
						for j = 1, 3 do
							shake.offset[ j ] = math.random(shake.amp * -100, shake.amp * 100) / 100
						end
						shake.angle = math.random(-shake.amp * 25, shake.amp * 25) / 100
					end
					
					local frac = (shake.endtime - ct) / shake.dur
					
					local freq
					if frac > 0 then
						freq = shake.freq / frac
					else
						freq = 0
					end
					
					frac = frac * frac
					
					local ang = ct * freq
					if ang > 1e8 then
						ang = 1e8
					end
					frac = frac * math.sin(ang)
					
					totalOffset = totalOffset + (shake.offset * frac)
					totalAngle = totalAngle + (shake.angle * frac)
					shake.amp = shake.amp - (shake.amp * (FrameTime() / (shake.dur * shake.freq)))
				end
			end
		end
		
		return totalOffset, totalAngle
	end
	
	function jrpg.ApplyShake(origin, angles, factor)
		local totalOffset, totalAngle = CalcShake()
		
		if totalOffset == false then
			return origin, angles
		end

		local o = origin + (factor * totalOffset)
		local a = angles.Roll + (totalAngle * factor)
		
		return o, angles + Angle(a,a,a)
	end
end

if SERVER then
    util.AddNetworkString("jrpg_screenshake")
end

local function ComputeShakeAmplitude(center, shakept, amp, rad)
	if rad <= 0 then
		return amp
	end
	
	local localAmp = -1
	local delta = center - shakept
	local dist = delta:Length()
	
	if dist < rad then
		local perc = 1.0 - (dist / rad)
		localAmp = amp * perc
	end

	return localAmp
end

function jrpg.ScreenShake(pos, amp, freq, dur, rad)
	amp = math.min(16, amp)
	
	if CLIENT then
		local localAmp = ComputeShakeAmplitude(pos, LocalPlayer():GetPos(), amp, rad)
		
		if localAmp > 0 then
			util.AddShake(pos, localAmp, freq, dur, rad)
		end

		return
	end
	
	for _, pl in ipairs(player.GetAll()) do
		local localAmp = ComputeShakeAmplitude(pos, pl:GetPos(), amp, rad)
		
		if localAmp > 0 then
			net.Start("jrpg_screenshake", true)
				net.WriteVector(pos)
				net.WriteFloat(localAmp)
				net.WriteFloat(freq)
				net.WriteFloat(dur)
				net.WriteFloat(rad)
			net.Send(pl)
		end
	end
end