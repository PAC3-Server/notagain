if not SERVER then return end

local MapDefine = {}
_G.MapDefine = MapDefine

MapDefine.Areas = {}

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
		
		["FrontBottomRight"] = Vector(refs.XMin,refs.YMin,refs.ZMin),
		["FrontBottomLeft"]  = Vector(refs.XMax,refs.YMin,refs.ZMin),
		["BackBottomRight"]  = Vector(refs.XMax,refs.YMax,refs.ZMin),
		["BackBottomLeft"]   = Vector(refs.XMin,refs.YMax,refs.ZMin),
		["FrontTopRight"]    = Vector(refs.XMin,refs.YMin,refs.ZMax),
		["FrontTopLeft"]     = Vector(refs.XMax,refs.YMin,refs.ZMax),
		["BackTopRight"]     = Vector(refs.XMax,refs.YMax,refs.ZMax),
		["BackTopLeft"]      = Vector(refs.XMin,refs.YMax,refs.ZMax),
	
	}

	MapDefine.Areas[name] = {}
	MapDefine.Areas[name].Points = points
	MapDefine.Areas[name].Refs   = refs
	MapDefine.Areas[name].Map    = game.GetMap()

	return refs,points
end

MapDefine.IsExistingArea = function(area)
	return MapDefine.Areas[area] and true or false
end

MapDefine.IsInArea = function(area,ent)
	if not IsValid(ent) or not MapDefine.IsExistingArea(area) then return false end

	local area = MapDefine.Areas[area]
	local refs = area.Refs
	local pos  = ent:GetPos()
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

MapDefine.GetCurrentArea = function(ent)
	for area,_ in pairs(MapDefine.Areas) do
		if MapDefine.IsInArea(tostring(area),ent) then 
			return area
		end
	end
	return "none"
end

MapDefine.SaveArea = function(area)
	if not MapDefine.IsExistingArea(area) then return end
	tbl = MapDefine.Areas[area]
	tbl.Name = area
	local json = util.TableToJSON( tbl ) 
	file.CreateDir( "MapSavedAreas" ) 
	file.Write( "MapSavedAreas/"..tbl.Map.."/"..area..".txt", json ) 
end

MapDefine.LoadAreas = function()
	local path = "MapSavedAreas/"..game.GetMap().."/"
	for _,file_name in ipairs(file.Find(path.."*.txt","DATA")) do
		local tbl = util.JSONToTable(file.Read(path..file_name,"DATA"))
		MapDefine.Areas[tbl.Name] = tbl
		MapDefine.Areas[tbl.Name].Name = nil
	end
end

hook.Add("Initialize","LoadMapDefineAreas",MapDefine.LoadAreas)

return MapDefine
