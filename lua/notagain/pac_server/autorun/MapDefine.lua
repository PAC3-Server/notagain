local MapDefine = {}
_G.MapDefine = MapDefine

MapDefine.Areas = {}

MapDefine.IsExistingArea = function(area)
	return MapDefine.Areas[area] and true or false
end

MapDefine.IsInArea = function(area,ent)
	if not IsValid(ent) or not MapDefine.IsExistingArea(area) then return false end

	local area = MapDefine.Areas[area]
	local refs = area.Refs
	local pos  = ent:WorldSpaceCenter()
	local x,y,z = pos.x,pos.y,pos.z 

	if x >= refs.XMax or x <= refs.XMin then
		return false 
	elseif y >= refs.YMax or y <= refs.YMin then
		return false 
	elseif z >= refs.ZMax or z <= refs.ZMin then
		return false 
	else
		return true 
	end

end

MapDefine.GetCurrentAreas = function(ent)
	local areas = {}
	for area,_ in pairs(MapDefine.Areas) do
		local a = tostring(area)
		if MapDefine.IsInArea(a,ent) then 
			table.insert(areas,a)
		end
	end
	return areas
end

hook.Add("Think","MapDefineOnChangedArea",function() 
	local nextcall = CurTime()
	if CurTime() > nextcall then
		nextcall = CurTime() + 1
		for _,ply in pairs(player.GetAll()) do
			if not ply.Pos or ply.Pos ~= ply:GetPos() then
				ply.Pos = ply:GetPos()
				local areas = MapDefine.GetCurrentAreas(ply)
				if ply.Areas and ply.Areas ~= areas then
					if #ply.Areas > areas then
						for area,_ in pairs(ply.Areas) do
							if not areas[area] then
								hook.Run("MD_OnAreaLeft",ply,area)
								break 
							end
						end
					elseif #ply.Areas < areas then
						for area,_ in pairs(area) do
							if not ply.Areas[area] then
								hook.Run("MD_OnAreaEntered",ply,area)
								break 
							end
						end
					end
				end
				ply.Areas = areas
			end
		end
	end
end)

if SERVER then 

	util.AddNetworkString("MapDefineSyncAreas")
	
	MapDefine.CreateArea = function(name,minvec,maxvec)
		local x1,y1,z1 = minvec.x,minvec.y,minvec.z 
		local x2,y2,z2 = maxvec.x,maxvec.y,maxvec.z 
		local refs = {}

		-- x's --
		do
			local bigger,smaller 
			if x1 > x2 then
				bigger  = x1 
				smaller = x2
			else
				bigger  = x2 
				smaller = x1
			end

			refs.XMax = bigger 
			refs.XMin = smaller

		end

		-- y's -- 
		do
			local bigger,smaller 
			if y1 > y2 then
				bigger  = y1
				smaller = y2
			else
				bigger  = y2
				smaller = y1
			end

			refs.YMax = bigger 
			refs.YMin = smaller
		end

		-- z's --
		do
			local bigger,smaller 
			if z1 > z2 then
				bigger  = z1
				smaller = z2
			else
				bigger  = z2
				smaller = z1
			end

			refs.ZMax = bigger 
			refs.ZMin = smaller
		end

		local points = {
			
			["1"] = Vector(refs.XMin,refs.YMin,refs.ZMin),
			["2"] = Vector(refs.XMax,refs.YMin,refs.ZMin),
			["3"] = Vector(refs.XMax,refs.YMax,refs.ZMin),
			["4"] = Vector(refs.XMin,refs.YMax,refs.ZMin),
			["5"] = Vector(refs.XMin,refs.YMin,refs.ZMax),
			["6"] = Vector(refs.XMax,refs.YMin,refs.ZMax),
			["7"] = Vector(refs.XMax,refs.YMax,refs.ZMax),
			["8"] = Vector(refs.XMin,refs.YMax,refs.ZMax),
		
		}

		MapDefine.Areas[name] = {}
		MapDefine.Areas[name].Points = points
		MapDefine.Areas[name].Refs   = refs
		MapDefine.Areas[name].Map    = game.GetMap()

		net.Start("MapDefineSyncAreas")
		net.WriteTable(MapDefine.Areas)
		net.Broadcast()

		return refs,points
	end

	MapDefine.SaveArea = function(area)
		if not MapDefine.IsExistingArea(area) then return end
		tbl = MapDefine.Areas[area]
		tbl.Name = area
		local json = util.TableToJSON( tbl ) 
		file.CreateDir( "mapsavedareas" ) 
		file.CreateDir( "mapsavedareas/"..tbl.Map)
		file.Write( "mapsavedareas/"..tbl.Map.."/"..area..".txt", json ) 
	end

	MapDefine.DeleteArea = function(area,map)
		local map = map or game.GetMap()
		file.Delete("mapsavedareas/"..map.."/"..area..".txt")
	end

	MapDefine.SaveAll = function()
		for area,_ in pairs(MapDefine.Areas) do
			MapDefine.SaveArea(tostring(area))
		end
	end

	MapDefine.DeleteAll = function(all)
		if all then 
			for _,map in pairs(select(2,file.Find("mapsavedareas/*","DATA"))) do
				for _,area in pairs((file.Find("mapsavedareas/"..map.."/*.txt","DATA"))) do
					file.Delete("mapsavedareas/"..map.."/"..area)
				end
				file.Delete("mapsavedareas/"..map)
			end
		else 
			for area,_ in pairs(MapDefine.Areas) do
				MapDefine.DeleteArea(tostring(area))
			end
		end
	end

	MapDefine.LoadAreas = function()
		local path = "mapsavedareas/"..game.GetMap().."/"
		local areas = {}
		for _,file_name in ipairs((file.Find(path.."*.txt","DATA"))) do
			local tbl = util.JSONToTable(file.Read(path..file_name,"DATA"))
			areas[tbl.Name] = tbl
			areas[tbl.Name].Name = nil
		end
		
		MapDefine.Areas = areas
	
	end

	MapDefine.ClientSync = function(client)
		net.Start("MapDefineSyncAreas")
		net.WriteTable(areas)
		net.Send(client)
	end

	hook.Add("PlayerInitialSpawn","MapDefineAreasSync",MapDefine.ClientSync)
	hook.Add("Initialize","MapDefineLoadAreas",MapDefine.LoadAreas)

end

if CLIENT then

	net.Receive("MapDefineSyncAreas",function()
		local tbl = net.ReadTable()
		MapDefine.Areas = tbl
		LocalPlayer().Areas = MapDefine.GetCurrentAreas(LocalPlayer())
	end)

end

return MapDefine
