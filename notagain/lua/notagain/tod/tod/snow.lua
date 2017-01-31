local textures = requirex("textures")

local snow_density = 0.05

local config =
{
	["fog_start"] = 0,
	["fog_end"] = 7000,
	["fog_max_density"] = 0.25,
	["fog_color"] = Vector(255,255,255)*0.8,
	["start_intensity"] = 0,
	["sky_topcolor"] = Vector(1,1,1)*0.5,
	["sky_bottomcolor"] = Vector(1,1,1)*0.5,
	["sky_starfade"] = 0,
	["sky_duskintensity"] = 0,
}

tod.AddOverrideConfig("snow", config, 0.5)

if SERVER then
	hook.Add("PlayerFootstep", "snow", function(ply, pos, foot, sound, volume, rf)
		sound = sound:lower()
		if sound:find("grass", nil, true) or sound:find("dirt", nil, true) then
			ply:EmitSound(("player/footsteps/snow%s.wav"):format(math.random(6)), 60, math.random(95,105))
			return true
		end
	end)
end

if CLIENT then
	-- emit the particles from points
	local emt = ParticleEmitter(EyePos(), false)

	hook.Add("Think", "tod_snow", function()
		local g = physenv.GetGravity().z
		local b = tod.GetWeatherChance(0.5)

		tod.EnableSectorThink(b)

		for k,v in pairs(player.GetAll()) do
			if math.sin(RealTime() * 2.5 + v:UniqueID()) > 0.5 then
				local i = v:LookupAttachment("mouth")
				if i ~= 0 then
					local mouth = v:GetAttachment(i)

					local up = mouth.Ang:Up()
					local p = emt:Add("particle/snow", mouth.Pos + up + VectorRand()*0.25)
					p:SetVelocity((up+VectorRand()*0.25)*-math.random()*30)
					p:SetDieTime(2)
					p:SetStartAlpha(6)
					p:SetStartSize(0)
					p:SetEndSize(math.random(2, 4))
					p:SetAirResistance(300)
					p:SetGravity(VectorRand()*0.1)
					p:SetLighting(true)
					p:SetAngles(Angle(math.random(360), math.random(360), math.random(360)))
				end
			end
		end

		if not b then return end

		for _, point in pairs(tod.GetOutsideSectors()) do
			if math.random() > snow_density then continue end

			local pos = point + VectorRand() * 50

			local p = emt:Add("particle/snow", pos)
			p:SetVelocity(VectorRand() * 100 * Vector(1,1,0))
			p:SetAngles(Angle(math.random(360), math.random(360), math.random(360)))
			p:SetLifeTime(0)
			p:SetDieTime(10)
			p:SetStartAlpha(255)
			p:SetEndAlpha(0)
			p:SetStartSize(0)
			p:SetEndSize(3)
			p:SetGravity(Vector(0,0,math.Rand(-10, -200)))
			p:SetCollide(true)
		--	p:SetLighting(true)]]
		end
	end)

	hook.Add("TOD_ReplaceGrassTexture", "tod_snow", function(path)
		path = path:lower()
		if path:find("grass") or path:find("mud") or path:find("sand") then
			textures.ReplaceTexture("tod", path, "nature/snowfloor002a")
			textures.SetColor("tod", path, Vector(1,1,1)*0.3)
		end
	end)
end