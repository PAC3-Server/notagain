
do -- spots
	fishing.SampledSpots = fishing.SampledSpots or {}
	fishing.SearchedSpots = fishing.SearchedSpots or {{{}}}

	fishing.FishSpots = --[[fishing.FishSpots or]] {{{}}}

	function fishing.SampleSpots()
		for key, ent in pairs(ents.FindByClass("weapon_fishing")) do
			if ent.Owner:IsValid() and ent.dt.hook:IsValid() and ent.dt.hook:WaterLevel() > 0 then
				local real_pos = ent.dt.hook:GetPos()
				local pos = ent.dt.hook:GetPos()

				pos = pos / 128

				pos.x = math.ceil(pos.x)
				pos.y = math.ceil(pos.y)
				pos.z = math.ceil(pos.z)

				pos = pos * 128

				fishing.SearchedSpots[pos.x] = fishing.SearchedSpots[pos.x] or {}
				fishing.SearchedSpots[pos.x][pos.y] = fishing.SearchedSpots[pos.x][pos.y] or {}

				if not fishing.SearchedSpots[pos.x][pos.y][pos.z] then
					table.insert(fishing.SampledSpots, util.QuickTrace(real_pos, Vector(0,0,-1000), ent.dt.hook).HitPos)
					fishing.SearchedSpots[pos.x][pos.y][pos.z] = true
				end
			end
		end

		for key, _pos in pairs(fishing.SampledSpots) do

			local pos = _pos * 1 -- copy

			pos = pos / 1500

			pos.x = math.ceil(pos.x)
			pos.y = math.ceil(pos.y)
			pos.z = math.ceil(pos.z)

			pos = pos * 1500

			fishing.FishSpots[pos.x] = fishing.FishSpots[pos.x] or {}
			fishing.FishSpots[pos.x][pos.y] = fishing.FishSpots[pos.x][pos.y] or {}

			if not fishing.FishSpots[pos.x][pos.y][pos.z] or fishing.FishSpots[pos.x][pos.y][pos.z].time < CurTime() then
				local classes = fishing.GetAllFishClasses()
				local class = classes[math.random(#classes)]

				local tr_up = util.TraceHull({
					start = _pos,
					endpos = _pos + Vector(0, 0, 32000),
					mins = Vector(1, 1, 1) * -64,
					maxs = Vector(1, 1, 1) * 64,
					filter = ents.FindInSphere(pos, 1500),
					mask = MASK_SOLID_BRUSHONLY,
				})

				local tr_dn = util.TraceHull({
					start = tr_up.HitPos,
					endpos = tr_up.HitPos + Vector(0, 0, -32000),
					mins = Vector(1, 1, 1) * -64,
					maxs = Vector(1, 1, 1) * 64,
					filter = ents.FindInSphere(pos, 1500),
					mask = MASK_WATER,
				})

				local depth = tr_dn.HitPos:Distance(_pos)

				fishing.FishSpots[pos.x][pos.y][pos.z] = {class = class, time = CurTime() + 1200, depth = depth}
			end
		end
	end

	timer.Create("fishing_spot_sampler", 0.25, 0, fishing.SampleSpots)

	function  fishing.GetSpotDataFromPos(pos)
		local pos = pos * 1 -- copy

		pos = pos / 1500

		pos.x = math.ceil(pos.x)
		pos.y = math.ceil(pos.y)
		pos.z = math.ceil(pos.z)

		pos = pos * 1500

		fishing.FishSpots[pos.x] = fishing.FishSpots[pos.x] or {}
		fishing.FishSpots[pos.x][pos.y] = fishing.FishSpots[pos.x][pos.y] or {}

		return fishing.FishSpots[pos.x][pos.y][pos.z] and fishing.FishSpots[pos.x][pos.y][pos.z]
	end

	function fishing.GetRandomSpot()
		for key, pos in RandomPairs(fishing.SampledSpots) do
			return pos
		end
	end

	function fishing.GetRandomGroundPos()

	end
end
 
do -- fish spawning
	function fishing.CalcFishSpawner()
		if not fishing.IsSomeoneFishing() then return end

		local pos = fishing.GetRandomSpot()

		if pos then
			local data = fishing.GetSpotDataFromPos(pos)

			if data then
				local FISH = scripted_ents.Get(data.class.real)
				if not FISH.Rareness or not FISH.MaxSpawned then print(data.class.real) end
				if #ents.FindByClass(data.class.real) < FISH.MaxSpawned and math.random() > FISH.Rareness then
					local ent = fishing.CreateFish(data.class.short, pos, (-(data.depth / 3200) + 1) * 15)

					ent:DelayRemove(100)
				end
			end
		end
	end

	timer.Create("fishing_fish_spawner", 1, 0, fishing.CalcFishSpawner)
end