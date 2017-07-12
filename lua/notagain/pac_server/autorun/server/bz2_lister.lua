timer.Simple(0,function()
	local stringtable = requirex("stringtables")

	if not stringtable then return end

	local data={}
	local first=true
	local nc,c,i=0,0,0
	Msg"[FastDL] "

	local tbl = {}

	local dl = stringtable.Get("downloadables")

	for i = 0, dl:Count() - 1 do
		tbl[dl:GetString(i)] = true
	end

	local startt=SysTime()

	for downloadable,_ in pairs(tbl) do
		i=i+1
		if	downloadable:find("^data.*") or
			downloadable:find("%.ztmp$") or
			downloadable:find("%.bz2$") or
			downloadable:find("%.ain$") or
			downloadable:find("%.nav$") or
			downloadable:find("%.gma$")
		then continue end
		c=c+1
		table.insert(data,downloadable)
		first=false
	end
	if file.Open then
		local fh=file.Open("bz2.txt",'wb','DATA')
		local first=true
		for k,v in pairs(data)do
			if first then
				first=false
			else
				fh:Write"\n"
			end
			fh:Write(v:gsub("\\","/"))
		end
		fh:Close()
	else
		file.Write("bz2.txt",table.concat(data,"\n"))
	end



	local sz=0
	local szc=0
	local bz2s=0
	local vmfs=0
	local function proc(c)
		local szz=file.Size(c,'GAME')
		szz=szz>0 and szz

		local fs=szz or 0
		if szz and szz>0 then vmfs=vmfs+1 end

		local compsz=file.Size(c..'.bz2','GAME')
		compsz=compsz>0 and compsz

		if compsz and compsz>0 then bz2s=bz2s+1 end

		local fsc=compsz or fs

		if not fs then return end
		sz=sz+fs
		szc=szc+fsc
	end

	for k,v in pairs(tbl) do proc(k) end
	local stopt=SysTime()
	 print(string.NiceSize(sz)..' in '..vmfs..' files'..(vmfs~=i and ' (out of '..i..')' or '')
			..', '
			..string.NiceSize(szc)..' with bz2 substitution '
			..'('..bz2s..' bz2 files found'..(bz2s~=c and ' out of '..c..' TO BE compressed' or '')..')'
			..' ('..string.NiceTime(stopt-startt)..')')

end)