local MapDefine = {}
_G.MapDefine = MapDefine

MapDefine.Areas = {}

MapDefine.IsExistingArea = function(area)
	return MapDefine.Areas[area] and true or false
end

MapDefine.IsInArea = function(area,ent)
	if not IsValid(ent) or not MapDefine.IsExistingArea(area) then return false end

	local area  = MapDefine.Areas[area]
	local refs  = area.Refs
	local pos   = ent:WorldSpaceCenter()
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
			areas[a] = a
		end
	end
	return areas
end

if SERVER then 

	util.AddNetworkString("MapDefineSyncAreas")
	util.AddNetworkString("MapDefineOnAreaEntered")
	util.AddNetworkString("MapDefineOnAreaLeft")

	local ENT = {
		Base = "base_brush",
		Type = "brush",
		ClassName = "AREA_TRIGGER",
		VecMin = Vector(0,0,0),
		VecMax = Vector(0,0,0),
		AreaName = "Default",
		Initialize = function( self )
			self:SetSolid(SOLID_BBOX)
			self:SetCollisionBoundsWS(self.VecMin,self.VecMax)
			self:SetTrigger(true)
		end,
		StartTouch = function( self , ent )
			if IsValid(ent) and ent:IsPlayer() then
				if ply.precleanupareas and ply.precleanupareas[self.AreaName] then
					ply.precleanupareas[self.AreaName] = nil 
					if table.Count(ply.precleanupareas) = 0 then
						ply.precleanupareas = nil 
					end
				else
					hook.Run("MD_OnAreaEntered",ent,self.AreaName) 
					net.Start("MapDefineOnAreaEntered")
					net.WriteEntity(ent)
					net.WriteString(self.AreaName)
					net.Broadcast()
				end
			end
		end,
		EndTouch = function( self , ent)
			if IsValid( ent ) and ent:IsPlayer() then
				if ply.precleanupareas and ply.precleanupareas[self.AreaName] then
					ply.precleanupareas = nil
					ply.precleanupareas[self.AreaName] = nil 
					if table.Count(ply.precleanupareas) = 0 then
						ply.precleanupareas = nil 
					end
				else
					hook.Run("MD_OnAreaLeft",ent,self.AreaName) 
					net.Start("MapDefineOnAreaLeft")
					net.WriteEntity(ent)
					net.WriteString(self.AreaName)
					net.Broadcast()
				end
			end
		end,
	}

	scripted_ents.Register(ENT,"AREA_TRIGGER")
	
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
			["minworldbound"] = minvec,
			["maxworldbound"] = maxvec,
		}

		MapDefine.Areas[name] = {}
		MapDefine.Areas[name].Points = points
		MapDefine.Areas[name].Refs   = refs
		MapDefine.Areas[name].Map    = game.GetMap()

		net.Start("MapDefineSyncAreas")
		net.WriteTable(MapDefine.Areas)
		net.Broadcast()

		local trigger = ents.Create("AREA_TRIGGER")
		trigger.VecMin,trigger.VecMax = minvec,maxvec
		trigger.AreaName = name
		trigger:Spawn()

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

			local trigger = ents.Create("AREA_TRIGGER")
			trigger.VecMin,trigger.VecMax = tbl.Points.minworldbound,tbl.Points.maxworldbound
			trigger.AreaName = tbl.Name
			trigger:Spawn()

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

	MapDefine.ResetAreas = function()
		for _,ent in pairs(ents.FindByClass("AREA_TRIGGER")) do
			SafeRemoveEntity(ent)
		end
		
		for name,area in pairs(MapDefine.Areas) do
			local trigger = ents.Create("AREA_TRIGGER")
			trigger.VecMin,trigger.VecMax = area.Points.minworldbound,area.Points.maxworldbound
			trigger.AreaName = name
			trigger:Spawn()
		end
	end

	local blyadcleanup = function()
		for k,v in pairs(player.GetAll()) do
			if IsValid(v) then
				local areas = MapDefine.GetCurrentAreas(ply)
				if table.Count(areas) > 0 then
					ply.precleanupareas = areas 
				end
			end
		end
	end

	hook.Add("PlayerInitialSpawn","MapDefineAreasSync",MapDefine.ClientSync)
	hook.Add("Initialize","MapDefineLoadAreas",MapDefine.LoadAreas)
	hook.Add("PreCleanupMap","MapDefineYOUREALLYAREGONNAFUCKITALL",blyadcleanup)
	hook.Add("PostCleanupMap","MapDefineDONOTDELETEMYTRIGGERSYOUBLYAD",MapDefine.ResetAreas)

end

if CLIENT then

	net.Receive("MapDefineSyncAreas",function()
		local tbl = net.ReadTable()
		MapDefine.Areas = tbl
	end)

	net.Receive("MapDefineOnAreaEntered",function()
		local ent = net.ReadEntity()
		local area = net.ReadString()
		hook.Run("MD_OnAreaEntered",ent,area)
	end)

	net.Receive("MapDefineOnAreaLeft",function()
		local ent = net.ReadEntity()
		local area = net.ReadString()
		hook.Run("MD_OnAreaLeft",ent,area)
	end)

end

return MapDefine
