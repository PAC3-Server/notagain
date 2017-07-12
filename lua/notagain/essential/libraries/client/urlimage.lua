local urlimage = {}

local function dbg(...) Msg"[UrlImg] "print(...) end
local function DBG(...) Msg"[UrlImg] "print(...) end

-- no debug anymore
dbg=function()end

FindMetaTable"IMaterial".ReloadTexture = function(self,name)
	self:GetTexture(name or "$basetexture"):Download()
end


if string.IsPNG then return end

local function unpack_msb_uint32(s)
  local a,b,c,d = s:byte(1,#s)
  local num = (((a*256) + b) * 256 + c) * 256 + d
  return num
end
local function unpack_msb_uint32_r(s)
  local d,c,b,a = s:byte(1,#s)
  local num = (((a*256) + b) * 256 + c) * 256 + d
  return num
end

local function read_msb_uint32(fh)
  return unpack_msb_uint32(fh:Read(4))
end

local function read_byte(fh)
  return fh:Read(1):byte()
end


local function parse_zlib(fh, len)
  local byte1 = read_byte(fh)
  local byte2 = read_byte(fh)

  local compression_method = byte1 % 16
  local compression_info = math.floor(byte1 / 16)

  local fcheck = byte2 % 32
  local fdict = math.floor(byte2 / 32) % 1
  local flevel = math.floor(byte2 / 64)


  fh:Read(len - 6)

  local checksum = read_msb_uint32(fh)

end

local function parse_IHDR(tbl,fh, len)
  assert(len == 13, 'format error')
  local width = read_msb_uint32(fh)
  local height = read_msb_uint32(fh)
  local bit_depth = read_byte(fh)
  local color_type = read_byte(fh)
  local compression_method = read_byte(fh)
  local filter_method = read_byte(fh)
  local interlace_method = read_byte(fh)

  tbl.width= width
  tbl.height= height
  tbl.bit_depth= bit_depth
  tbl.color_type= color_type
  tbl.compression_method= compression_method
  tbl.filter_method= filter_method
  tbl.interlace_method= interlace_method

  return compression_method
end

local function parse_sRGB(tbl,fh, len)
  assert(len == 1, 'format error')
  local rendering_intent = read_byte(fh)
  tbl.rendering_intent= rendering_intent
end

local function parse_gAMA(tbl,fh, len)
  assert(len == 4, 'format error')
  local rendering_intent = read_msb_uint32(fh)
 tbl.rendering_intent= rendering_intent
end

local function parse_cHRM(tbl,fh, len)
  assert(len == 32, 'format error')

  local white_x = read_msb_uint32(fh)
  local white_y = read_msb_uint32(fh)
  local red_x = read_msb_uint32(fh)
  local red_y = read_msb_uint32(fh)
  local green_x = read_msb_uint32(fh)
  local green_y = read_msb_uint32(fh)
  local blue_x = read_msb_uint32(fh)
  local blue_y = read_msb_uint32(fh)

end

local function parse_IDAT(tbl,fh, len, compression_method)
  if compression_method == 0 then
    -- fh:Read(len)
    parse_zlib(fh, len)
  else

  end
end

local function ParsePNG(fh)
  if isstring(fh) then
  	fh = file.Open(fh,'rb','GAME')

  end
  if not fh then error"Invalid file" end

  local tbl = {}

  -- parse PNG header
  local bytes = fh:Read(8)
  local expect = "\137\080\078\071\013\010\026\010"
  if bytes ~= expect then
    error 'not a PNG file'
  end

  -- parse chunks
  local compression_method
  while 1 do
    local len = read_msb_uint32(fh)
    local stype = fh:Read(4)

    if stype == 'IHDR' then
      compression_method = parse_IHDR(tbl,fh, len)
      break
    elseif stype == 'sRGB' then
      parse_sRGB(tbl,fh, len)
    elseif stype == 'gAMA' then
      parse_gAMA(tbl,fh, len)
    elseif stype == 'cHRM' then
      parse_cHRM(tbl,fh, len)
    elseif stype == 'IDAT' then
      parse_IDAT(tbl,fh, len, compression_method)
    --else
      --local data = fh:Read(len)
      --print("data=", len == 0 and "(empty)" or "(not displayed)")
    end

---	local crc = read_msb_uint32(fh)

    if stype == 'IEND' then
      break
    end
  end
  return tbl
end

local function ParseJPG(file)
	local dimheader = {  }
	local foundheader = 0
	local endofjpg = file:Tell(file:Seek(file:Size()))
	local width = 0
	local height = 0
	local seek = {  }

	file:Seek(0)

	dimheader[1] = string.char(255) .. string.char(192)
	dimheader[2] = string.char(255) .. string.char(194)
	local validjpg = string.char(255) .. string.char(216)
	if file:Read(2) == validjpg then
		while foundheader == 0 do
			local readheader
			if file:Tell() + 2 < endofjpg then
				readheader = file:Read(2)
			else
				print("Reached end of file", 0)
				foundheader = 1
			end

			if readheader == dimheader[1] or readheader == dimheader[2] then
				if file:Tell() + 3 < endofjpg then
					file:Seek(file:Tell() + 3)
					height = string.byte(file:Read(1)) * 256 + string.byte(file:Read(1))
					width = string.byte(file:Read(1)) * 256 + string.byte(file:Read(1))
					foundheader = 1
				end

			else
				if file:Tell() + 2 < endofjpg then
					seek[1] = string.byte(file:Read(1)) * 256
					seek[2] = string.byte(file:Read(1))
					seek[3] = seek[1] + seek[2] - 2
					if file:Tell() + seek[3] < endofjpg then
						file:Seek(file:Tell() + seek[3])
					else
						error("Reached end of file", 0)
						foundheader = 1
					end

				else
					error("Reached end of file", 0)
					foundheader = 1
				end

			end

		end

	else
		error("Error reading JPG", 0)
	end

	--file:Close()
	return {width=width,height=height}

end

local function IsPowerOfTwo(n)
	return bit.band(n,n-1)==0
end
local function ushort(str)
	return string.byte(str,1)+string.byte(str,2)*256
end
local ID_VTF = "VTF\000"
local function ParseVTF(file)
	--should we check for vtf?
	if file:Read(4)~=ID_VTF then return nil,'not vtf' end
	local ver1,ver2 = unpack_msb_uint32_r(file:Read(4)),unpack_msb_uint32_r(file:Read(4))
	local headerSize = unpack_msb_uint32_r(file:Read(4))
	if ver1>100 or ver2>900 then return nil,'invalid version' end
	local w,h = ushort(file:Read(2)),ushort(file:Read(2))
	if not (IsPowerOfTwo(w)) or w==0 then return nil,"invalid power" end
	if not (IsPowerOfTwo(h)) or h==0 then return nil,"invalid power" end
	return {width=w,height=h,version = {ver1,ver2},headerSize = headerSize}
end


local ID_JPG = string.char(255) .. string.char(216)
local ID_PNG = "\137\080\078\071\013\010\026\010"


local function IsPNG(bytes) return bytes:sub(1,8)==ID_PNG end
local function IsJPG(bytes) return bytes:sub(1,2)==ID_JPG end
local function IsVTF(bytes) return bytes:sub(1,4)==ID_VTF end



--PrintTable(file.ParseVTF(file.Open("materials/point.vtf",'rb','GAME')))

--https://gist.github.com/Python1320/eec8cdc84828a8261b00

AddCSLuaFile()

local sql=sql

-- http://www.sqlite.org/lang_corefunc.html#last_insert_rowid
function sql.LastRowID()
	local ret = sql.Query("SELECT last_insert_rowid() as x")[1].x
	return ret
end

setmetatable(sql,{__call=function(self,query,...)
	local t = {}

	for i = 1, select("#", ...) do
		local v = select(i, ...)

		if isstring(v) then
			v = sql.SQLStr(v)
		end

		t[i] = tostring(v)
	end

	query = query..';'

	if t[1] then
		query = query:format(unpack(t))
	end

	local ret = sql.Query(query)

	assert(ret~=true,'uuuhoh')
	if ret == false then
		return nil,sql.LastError()..' (Query: '..query..')'
	elseif ret == nil then
		return true
	else
		return ret
	end
end})

-- http://www.tutorialspoint.com/sqlite/sqlite_date_time.htm
local escape=sql.SQLStr
local function gen_datefunc(fname)
	local beginning = "SELECT "..fname.."("
	local function func(...)

		local mods = {...}
		for k,v in next,mods do
			mods[k]=isnumber(v) and v or escape(v)
		end
		local q=beginning..table.concat(mods,",")..") as x;"

		local ret = sql.Query(q)
		ret = ret and ret[1]
		ret = ret and ret.x
		ret = ret and ret~="NULL" and ret

		return ret

	end

	sql[fname]=func
end

gen_datefunc 'date'
gen_datefunc 'time'
gen_datefunc 'datetime'
gen_datefunc 'julianday'
gen_datefunc 'strftime'






local mt = {}
function mt:create(infos,after,...)
	local name = getmetatable(self).name
	assert(name)
	if not sql.TableExists(name) then
		MsgN("Creating ",name)
		assert(sql(("CREATE TABLE %%s (%s) %s"):format(infos,after or ""),name,...))
	end
	return self
end

function mt:coerce(kv)
	getmetatable(self).coerce = kv
	return self
end

function mt:drop()
	local name = getmetatable(self).name
	if sql.TableExists(name) then
		assert(sql(("DROP TABLE %s"):format(name)))
	end
	return self
end
function mt:insert(kv,or_replace)
	local name = getmetatable(self).name

	local keys,values={},{}
	local i=0
	for k,v in pairs(kv) do
		i=i+1
		keys[i] = sql.SQLStr(k)
		values[i] = (isnumber(v)) and tostring(v)
		or v==true and 1
		or v==false and 0
		or isstring(v) and sql.SQLStr(v)
		or error"Invalid input"
	end

	local a,b = sql(("INSERT %sINTO %s (%s) VALUES (%s)"):format(or_replace and "OR REPLACE " or "",name,table.concat(keys,", "),table.concat(values,", ")))
	if a==true then
		return tonumber(sql.LastRowID())
	end
	return a,b
end

function mt:coercer(a,...)
	local coerce = getmetatable(self).coerce
	if coerce and a and a~=true then
		for i=1,#a do
			local t = a[i]
			for k,v in next,t do
				local coercer = coerce[k]
				if coercer then
					t[k] = coercer(v)
				end
			end
		end
	end
	return a,...
end
function mt:select(vals,extra,...)
	local name = getmetatable(self).name

	return self:coercer(self:sql(("SELECT %s FROM %s %s"):format(vals,name,extra or ""),...))
end

local function return_changes(a,...)
	if a==true then
		local changes = tonumber(sql'SELECT changes() as changes'[1].changes)
		return changes
	end
	return a,...
end
function mt:update(extra,...)
	local name = getmetatable(self).name
	local query = ("UPDATE %s SET %s"):format(name,extra)
	return return_changes( self:sql( query ,...) )
end

function mt:delete(extra,...)
	local name = getmetatable(self).name
	local query = ("DELETE FROM %s WHERE %s"):format(name,extra)
	return return_changes( self:sql( query ,...) )
end

local function firstval(a,...)
	if a and a~=true then assert(not a[2]) return a[1] end
	return a,...
end
function mt:select1(...) return firstval(self:select(...)) end


function mt:sql(a,...)
	local t = {...}
	local name = getmetatable(self).name

	for k,v in next,t do
		local mt = istable(v) and getmetatable(v)
		if mt and mt.name then t[k] = mt.name end
	end

	return sql(a,unpack(t))
end
function mt:sql1(...) return firstval(self:sql(...)) end

local function columns(a,b)
	if a then
		return a[1].name
	end
	return a,b
end
function mt:columns()
	local name = getmetatable(self).name
	if sql.TableExists(name) then
		return columns(sql("PRAGMA table_info(%s)",name))
	end
	return nil,'no such table'
end


local function sql_obj(name)
	return setmetatable({name=name},{name=name,__index=mt})
end



--
local db = assert(sql_obj("urlimage")
	--:drop()
	:create([[
		`url`		TEXT NOT NULL CHECK(url <> '') UNIQUE,
		`ext`		TEXT NOT NULL CHECK(ext = 'vtf' OR ext = 'png' OR ext = 'jpg'),
		`last_used`	INTEGER NOT NULL DEFAULT 0,
		`fetched`	INTEGER NOT NULL DEFAULT (cast(strftime('%%s', 'now') as int) - 1477777422),
		`locked`	BOOLEAN NOT NULL DEFAULT 1,
		`w`			INTEGER(2) NOT NULL DEFAULT 0,
		`h`			INTEGER(2) NOT NULL DEFAULT 0,
		`fileid`	INTEGER PRIMARY KEY AUTOINCREMENT]])
	:coerce{last_used=tonumber, fileid=tonumber,w=tonumber,h=tonumber, locked=function(l) return l=='1' end })

local l = assert(db:update("locked = 0 WHERE locked != 0"))

if l>0 then dbg("unlocked entries: ",l) end

-- print(db:columns())

--  Msg"insert " 		print(assert(		db:insert{url = "http://asd.com/0", last_used = os.time()}))
--  Msg"replace " 		print(				db:insert({url = "http://asd.com/0", last_used = 1337},true))
--  Msg"insert " 		print(assert(		db:insert{url = "http://asd.com/1", last_used = os.time()-123}))
--  Msg"count " 		print(tonumber(		db:select1"count(*) as count".count))
--  Msg"Delete none " 	PrintTable(assert(	db:delete("url = %s",'derp')))
--  Msg"count " 		print(tonumber(		db:select1"count(*) as count".count))
--  Msg"list "			PrintTable(			db:select("*","WHERE URL != %s","http://asd.co"))
--  Msg"update "		PrintTable(			db:update("locked = 1 WHERE fileid=%d",123))
--  Msg"list"			PrintTable(			db:select("*","WHERE URL != %s","http://asd.co"))
--  Msg"raw"			PrintTable(assert(	db:sql1("select * from %s limit %d",db,1)))
--  Msg"Delete all " 	print(assert(		db:delete("url != %s",'derp')))
--do return end
---------------

local MAX_ENTRIES = 128
local function find_purgeable()
	dbg("find_purgeable()")
	local a,b = db:select('*','WHERE locked != 1 ORDER BY last_used LIMIT(select max(0,count(*) -%d) from %s)',MAX_ENTRIES,db)
	return a,b
end

local function update_dimensions(fileid,w,h)
	dbg("update_dimensions()",fileid,w,h)
	assert(tonumber(fileid))
	return db:update("w = %d, h=%d WHERE fileid=%d",w,h,fileid)
end

local function record_use(fileid,nolock)
	dbg("record_use()",fileid,nolock)
	assert(tonumber(fileid))
	nolock = nolock and "" or ", locked = 1"
	return db:update("last_used = (cast(strftime('%%s', 'now') as int) - 1477777422)"..nolock.." WHERE fileid=%d",fileid)
end

local function get_record(urlid)
	dbg("get_record()",urlid)
	local record = assert(db:select1('*',isnumber(urlid) and "WHERE fileid = %d" or "WHERE url = %s",urlid))
	return record~=true and record
end



local function new_record(url,ext)
	dbg("new_record()",url,ext)
	local fileid = assert(db:insert{url = url,ext = ext})
	return fileid
end

--print(update_last_used(db:insert{url = "f"}))
--db:insert{url = "http://asd.com/1",last_used = 1}
--db:insert{url = "http://asd.com/2",ext="jpg"}
--db:insert{url = "http://asd.com/3",last_used = 3}
--db:insert{url = "http://asd.com/4"}
--Msg"list "			PrintTable(			db:select("*","WHERE URL != %s","http://asd.co"))

urlimage.BASE = "cache/uimg"
file.CreateDir("cache",'DATA')
file.CreateDir(urlimage.BASE,'DATA')
local function FPATH(a,ext,open_as)
	--Msg(("FPATH %q %q %q -> "):format(a or "",ext or "",tostring(open_as or "")))
	if ext=="vmt" then
		a=a..'_vmt'
		ext="txt"
	end

	local ret =("%s/%s%s%s%s%s"):format(urlimage.BASE,tostring(a),
		ext and "." or "",
		ext or "",
		open_as and "\n." or "",
		open_as or "")
	--print(ret)
	return ret
end

local function FPATH_R(...)
	return ("../data/%s"):format(FPATH(...))
end

local function record_validate(r)
	if not istable(r) then r = get_record(r) end
	dbg("record_validate()",r,r and r.url or r.fileid)
	if not r or not r.w or r.w==0 then return false end

	return r and file.Exists(FPATH(r.fileid,r.ext),'DATA') and r
end

function urlimage.Material(fileid,ext,...)
	dbg("Material()",fileid,ext,...)
	local path = FPATH_R(fileid,ext )
	local a,b

	if ext == 'vtf' then
		path = FPATH_R(fileid)
		dbg("_G.CreateMaterial()",("%q"):format(path))
		a,b = CreateMaterial("uimgg"..fileid,'UnlitGeneric',{
			["$vertexcolor"] = "1",
			["$vertexalpha"] = "1",
			["$nolod"      ] = "1",
			["$basetexture"] = path
		})
	else
		dbg("_G.Material()",("%q"):format(path))
		a,b = _G.Material(path, "smooth")
	end

	-- should no longer be needed, if it even works
	--if a then a:ReloadTexture() end

	return a,b,path
end

local function fwrite(fileid,ext,data)
	dbg("fwrite()",fileid,ext,#data)
	local path = FPATH(fileid,ext)
	file.Write(path,data)
	return path
end
local function fopen(fileid,ext)
	dbg("fopen()",fileid,ext)
	return file.Open(FPATH(fileid,ext),'rb','DATA')
end

local delete_record delete_record = function(record)
	dbg("delete_record()",record)
	if istable(record) then

		if next(record)==nil then return 0 end

		if record[1] then
			local aggr = 0
			for _,record in next,record do
				aggr = aggr + assert(delete_record(record))
			end
			return aggr
		else
			return delete_record(record.fileid or record.fileid)
		end
	elseif isnumber(record) then
		return db:delete('fileid = %d',record)
	elseif isstring(record) then
		return db:delete('url = %s',record)
	else error"wtf" end
end

--TODO: Purge on start and live
local purgeable = assert(find_purgeable())
if purgeable~=true then
	dbg("LRU Purge: ",#purgeable)
end


local function data_format(bytes)
	if 		IsJPG(bytes) then return 'jpg'
	elseif 	IsPNG(bytes) then return 'png'
	elseif 	IsVTF(bytes) then return 'vtf'
	end
	dbg("data_format()","FAILURE",("%q"):format(bytes))
end

local mw,mh = 	render.MaxTextureWidth(),render.MaxTextureHeight()
mw=mw>2048 and 2048 mh=mh>2048 and 2048
local function read_image_dimensions(fh,fmt)
	dbg("read_image_dimensions()",fh,fmt)
	local reader = fmt=='png' and ParsePNG or fmt=='jpg' and ParseJPG or fmt=='vtf' and ParseVTF
	if not reader then return nil,'No reader for format: '..tostring(fmt) end

	local w,h
	local t = reader(fh)

	w = t.width
	h = t.height
	if not w or not h then
		return nil,'invalid file'
	end
	if w>mw or h>mh then
		return nil,'excessive dimensions'
	end
	return w,h
end

local function record_to_material(r)
	dbg("record_to_material()",r and r.fileid)
	if not r.used then
		assert(record_use(r.fileid))
		r.used = true
	end
	return urlimage.Material(r.fileid,r.ext),r.w,r.h
end

local function remove_error(cached,...)
	cached.error = nil
	return ...
end

urlimage.cache = urlimage.cache or {}
local cache = urlimage.cache

local fastdl = GetConVarString"sv_downloadurl":gsub("/$","")..'/'

local function FixupURL(url)
	if not url:sub(3,10):find("://",1,true) then
		url = fastdl..url
	else

		url = url:gsub([[^http%://onedrive%.live%.com/redir?]],[[https://onedrive.live.com/download?]])
		url = url:gsub( "pastebin.com/([a-zA-Z0-9]*)$", "pastebin.com/raw.php?i=%1")
		url = url:gsub( "github.com/([a-zA-Z0-9_]+)/([a-zA-Z0-9_]+)/blob/", "github.com/%1/%2/raw/")

		if url:find("dropbox",1,true) then
			url = url:gsub([[^http%://dl%.dropboxusercontent%.com/]],[[https://dl.dropboxusercontent.com/]])
			url = url:gsub([[^https?://www.dropbox.com/s/(.+)%?dl%=[01]$]],[[https://dl.dropboxusercontent.com/s/%1]])
		end

	end

	return url
end

-- Returns: mat,w,h
-- Returns: false = processing, nil = error
function urlimage.GetURLImage(url)

	url = FixupURL(url)

	local cached = cache[url]
	if cached then
		if cached.processing then
			return false
		elseif cached.error then
			return nil,cached.error
		elseif cached.record then
			return record_to_material(cached.record)
		else
			cached.error = "invalid cache state"
			error(cached.error)
		end
	end

	-- find if record exists --

	cached = {error = "failure"}
	cache[url] = cached

	local cached_record = get_record(url)
	if cached_record then

		assert(next(cached_record)~=nil)

		if record_validate(url) then
			record_use(cached_record.fileid)
			cached.record = cached_record
			return remove_error(cached, record_to_material(cached_record) )
		else
			DBG("INVALID RECORD","DELETING",url)
			assert(delete_record(url))
		end
	end

	-- it's a new url --
	dbg("Fetching",url)

	local function fail(err)
		delete_record(url)
		cached.processing = false
		cached.error = tostring(err)
		dbg("Fetch failed for",url,": "..cached.error)
	end

	local function fetched(data,len,hdr,code)

		dbg("fetched()",len,code)

		if code~=200 then
			return fail(code)
		end
		if len<=8 or len>16778216 then -- 4*2048*2048 + 1kb
			return fail'invalid filesize'
		end

		local ext = data_format(data)
		if not ext then
			return fail'unknown format'
		end

		-- build a new record --

		local fileid = new_record(url,ext)

		fwrite(fileid,ext,data) data = nil
		local fh = fopen(fileid,ext)

		local w,h = read_image_dimensions(fh,ext)
		fh:Close()
		if not w then return fail(h) end

		update_dimensions(fileid,w,h)


		-- We don't have to build the record manually, we can just get it again
		cached.record = get_record(url)

		if not record_validate(cached.record) then
			return fail'record_validate()'
		end

		-- we now have some sort of record, so let's use it so it's top of LRU
		record_use(fileid,true) -- maybe remove?

		cached.processing = false
		remove_error(cached)


	end

	http.Fetch(url,fetched,fail)

	cached.processing = true

	return false

end


function urlimage.URLMaterial(url)
	local mat,w,h = urlimage.GetURLImage(url)
	local function setmat()
		surface.SetMaterial(mat)
		return w,h,mat
	end

	if mat then
		dbg("URLImage",url,"instant mat",mat)
		return setmat
	end

	local trampoline trampoline = function()
		mat,w,h = urlimage.GetURLImage(url)
		if not mat then
			if mat==nil then
				trampoline = function() end
				DBG("URLImage failed for ",url,": ",w,h)
			end

			return
		end
		trampoline = setmat
		return setmat()
	end

	return function()
		return trampoline()
	end

end

return urlimage
