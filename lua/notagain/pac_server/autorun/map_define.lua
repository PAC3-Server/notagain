local MapDefine = {}
_G.MapDefine = MapDefine

MapDefine.Areas = {}
MapDefine.Logs = false

MapDefine.IsExistingArea = function(area)
	return MapDefine.Areas[area] and true or false
end

MapDefine.IsInArea = function(ent,area)
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

FindMetaTable("Entity").IsInArea = MapDefine.IsInArea

MapDefine.GetCurrentAreas = function(ent)
	local areas = {}
	for area,_ in pairs(MapDefine.Areas) do
		local a = tostring(area)
		if MapDefine.IsInArea(ent,a) then
			areas[a] = a
		end
	end
	return areas
end

FindMetaTable("Entity").GetCurrentAreas = MapDefine.GetCurrentAreas

--logs--
hook.Add("MD_OnAreaInit","MapDefineLogAreaInit",function(area)
	if MapDefine.Logs then
		print("[MapDefine]: Area "..area.." has been initialized")
	end
end)

hook.Add("MD_OnAreaEntered","MapDefineLogEntered",function(ent,area)
	if MapDefine.Logs then
		local a = (ent:IsPlayer() and ent:GetName() or ent:GetClass())
		print("[MapDefine]: "..a.." entered "..area)
	end
end)

hook.Add("MD_OnAreaLeft","MapDefineLogLeft",function(ent,area)
	if MapDefine.Logs then
		local a = (ent:IsPlayer() and ent:GetName() or ent:GetClass())
		print("[MapDefine]: "..a.." left "..area)
	end
end)

hook.Add("MD_OnOverWorldEntered","MapDefineLogOWEntered",function(ent)
	if MapDefine.Logs then
		local a = (ent:IsPlayer() and ent:GetName() or ent:GetClass())
		print("[MapDefine]: "..a.." entered OverWorld")
	end
end)

hook.Add("MD_OnOverWorldLeft","MapDefineLogOWLeft",function(ent)
	if MapDefine.Logs then
		local a = (ent:IsPlayer() and ent:GetName() or ent:GetClass())
		print("[MapDefine]: "..a.." left OverWorld")
	end
end)

if SERVER then

	util.AddNetworkString("MapDefineSyncAreas")
	util.AddNetworkString("MapDefineOnAreaInit")
	util.AddNetworkString("MapDefineOnAreaEntered")
	util.AddNetworkString("MapDefineOnAreaLeft")
	util.AddNetworkString("MapDefineOnOverWorldEntered")
	util.AddNetworkString("MapDefineOnOverWorldLeft")

	local ENT = {
		Base = "base_brush",
		Type = "brush",
		ClassName = "area_trigger",
		VecMin = Vector(0,0,0),
		VecMax = Vector(0,0,0),
		AreaName = "Default",
		Initialize = function( self )
			self:SetSolid(SOLID_BBOX)
			self:SetCollisionBoundsWS(self.VecMin,self.VecMax)
			self:SetTrigger(true)
			hook.Run("MD_OnAreaInit",self.AreaName)
			net.Start("MapDefineOnAreaInit")
			net.WriteString(self.AreaName)
			net.Broadcast()
		end,
		StartTouch = function( self , ent )
			if IsValid(ent) then
				if ent.precleanupareas and ent.precleanupareas[self.AreaName] then
					ent.precleanupareas[self.AreaName] = nil
					if table.Count(ent.precleanupareas) == 0 then
						ent.precleanupareas = nil
					end
				else
					if ent.InOverWorld then
						ent.InOverWorld = false
						hook.Run("MD_OnOverWorldLeft",ent)
						net.Start("MapDefineOnOverWorldLeft")
						net.WriteEntity(ent)
						net.Broadcast()
					end
					hook.Run("MD_OnAreaEntered",ent,self.AreaName)
					net.Start("MapDefineOnAreaEntered")
					net.WriteEntity(ent)
					net.WriteString(self.AreaName)
					net.Broadcast()
				end
			end
		end,
		EndTouch = function( self , ent)
			if IsValid( ent ) then
				if ent.precleanupareas and ent.precleanupareas[self.AreaName] then
					ent.precleanupareas[self.AreaName] = nil
					if table.Count(ent.precleanupareas) == 0 then
						ent.precleanupareas = nil
					end
				else
					hook.Run("MD_OnAreaLeft",ent,self.AreaName)
					net.Start("MapDefineOnAreaLeft")
					net.WriteEntity(ent)
					net.WriteString(self.AreaName)
					net.Broadcast()
					if table.Count(MapDefine.GetCurrentAreas(ent)) == 0 then
						ent.InOverWorld = true
						hook.Run("MD_OnOverWorldEntered",ent)
						net.Start("MapDefineOnOverWorldEntered")
						net.WriteEntity(ent)
						net.Broadcast()
					else
						ent.InOverWorld = false
					end
				end
			end
		end,
	}

	scripted_ents.Register(ENT,"area_trigger")

	MapDefine.CreateArea = function(name,minvec,maxvec)
		local x1,y1,z1 = minvec.x,minvec.y,minvec.z
		local x2,y2,z2 = maxvec.x,maxvec.y,maxvec.z
		local refs = {}

		refs.XMax = math.max(x1,x2)
		refs.XMin = math.min(x1,x2)
		refs.YMax = math.max(y1,y2)
		refs.YMin = math.min(y1,y2)
		refs.ZMax = math.max(z1,z2)
		refs.ZMin = math.min(z1,z2)

		local points = {
			MinWorldBound = minvec,
			MaxWorldBound = maxvec,
		}

		local trigger = ents.Create("area_trigger")
		trigger.VecMin,trigger.VecMax = minvec,maxvec
		trigger.AreaName = name
		trigger:Spawn()

		MapDefine.Areas[name]         = {}
		MapDefine.Areas[name].Points  = points
		MapDefine.Areas[name].Refs    = refs
		MapDefine.Areas[name].Map     = game.GetMap()
		MapDefine.Areas[name].Trigger = trigger

		net.Start("MapDefineSyncAreas")
		net.WriteTable(MapDefine.Areas)
		net.Broadcast()

	end

	MapDefine.SaveArea = function(area)
		if not MapDefine.IsExistingArea(area) then return end

		local tbl   = MapDefine.Areas[area]
		tbl.Trigger = nil
		tbl.Name    = area
		local json  = util.TableToJSON( tbl )

		file.CreateDir( "mapsavedareas" )
		file.CreateDir( "mapsavedareas/"..tbl.Map)
		file.Write( "mapsavedareas/"..tbl.Map.."/"..area..".txt", json )
	end

	MapDefine.DeleteArea = function(area,map)
		local map = map or game.GetMap()
		file.Delete("mapsavedareas/"..map.."/"..area..".txt")
		if map == game.GetMap() and MapDefine.IsExistingArea(area) then
			MapDefine.Areas[area].Trigger:Remove()
			MapDefine.Areas[area] = nil
			net.Start("MapDefineSyncAreas")
			net.WriteTable(MapDefine.Areas)
			net.Broadcast()
		end
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

		for _,file_name in ipairs((file.Find(path.."*","DATA"))) do
			local tbl = util.JSONToTable(file.Read(path..file_name,"DATA"))
			local trigger = ents.Create("area_trigger")
			trigger.VecMin,trigger.VecMax = tbl.Points.MinWorldBound,tbl.Points.MaxWorldBound
			trigger.AreaName = tbl.Name
			trigger:Spawn()

			tbl.Trigger          = trigger
			areas[tbl.Name]      = tbl
			areas[tbl.Name].Name = nil
		end

		MapDefine.Areas = areas
	end

	MapDefine.PrintSavedAreas = function(map)
		local map = map or game.GetMap()
		PrintTable((file.Find("mapsavedareas/"..map.."/*","DATA")))
	end

	MapDefine.ClientSync = function(client)
		net.Start("MapDefineSyncAreas")
		net.WriteTable(MapDefine.Areas)
		net.Send(client)
	end

	MapDefine.ResetAreas = function()
		for _,ent in pairs(ents.FindByClass("area_trigger")) do
			SafeRemoveEntity(ent)
		end

		for name,area in pairs(MapDefine.Areas) do
			local trigger = ents.Create("area_trigger")
			trigger.VecMin,trigger.VecMax = area.Points.MinWorldBound,area.Points.MaxWorldBound
			trigger.AreaName = name
			trigger:Spawn()
		end
	end

	hook.Add("PreCleanupMap","MapDefineYOUREALLYAREGONNAFUCKITALL",function()
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) then
				local areas = MapDefine.GetCurrentAreas(ply)
				if table.Count(areas) > 0 then
					ply.precleanupareas = areas
				end
			end
		end
	end)

	hook.Add("PlayerInitialSpawn","MapDefineAreasSync",MapDefine.ClientSync)
	hook.Add("InitPostEntity","MapDefineLoadAreas",MapDefine.LoadAreas)
	hook.Add("PostCleanupMap","MapDefineDONOTDELETEMYTRIGGERSYOUBLYAD",MapDefine.ResetAreas)

end

if CLIENT then

	net.Receive("MapDefineSyncAreas",function()
		local tbl = net.ReadTable()
		MapDefine.Areas = tbl
	end)

	net.Receive("MapDefineOnAreaInit",function()
		local area = net.ReadString()
		hook.Run("MD_OnAreaInit",area)
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

	net.Receive("MapDefineOnOverWorldEntered",function()
		local ent = net.ReadEntity()
		hook.Run("MD_OnOverWorldEntered",ent)
	end)

	net.Receive("MapDefineOnOverWorldLeft",function()
		local ent = net.ReadEntity()
		hook.Run("MD_OnOverWorldLeft",ent)
	end)

end

return MapDefine
