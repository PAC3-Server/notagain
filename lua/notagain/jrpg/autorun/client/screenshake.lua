local jfx = requirex("jfx")
local ease = requirex("ease")
local queue = {}
local temp = Vector()

local function calc_screenshake(eye_pos)
	local real_time = RealTime()
	temp:Zero()
	local pos = temp

	for i = #queue, 1, -1 do
		local info = queue[i]

		local time = info.time - real_time

		local f = time / info.length

		local x,y,z = jfx.GetRandomOffset(eye_pos, real_time, info.freq)
		f = ease.inOutCubic(f, 0, 1, 1)
		x = x * info.amp * f
		y = y * info.amp * f
		z = z * info.amp * f

		temp.x = temp.x + x
		temp.y = temp.y + y
		temp.z = temp.z + z

		if time < 0 then
			table.remove(queue, i)
		end
	end

	return pos
end

function jrpg.CalcScreenShake(pos, ang)
	local offset = calc_screenshake(pos)

	ang.r = ang.r + offset.z

	return pos + (ang:Right() * offset.x) + (ang:Up() * offset.y), ang
end

function jrpg.AddScreenShake(amplitude, frequency, length)
	table.insert(queue, {
		amp = amplitude,
		freq = frequency,
		length = length,
		time = RealTime() + length,
	})
end
