local font_names = util.JSONToTable(file.Read("surface_createfont2_cache.txt") or "") or {}

do
	local ULONG_MAX = 4294967295
	local USHORT_MAX = 65535

	local function swap_endian(num, size)
		local result = 0
		for shift = 0, size - 8, 8 do
			result = bit.bor(bit.lshift(result, 8), bit.band(bit.rshift(num, shift), 0xff))
		end
		return result
	end

	local name_ids = {
		[1] = "family",
		[2] = "subfamily",
		[4] = "full_name",

	}

	local function read_unsigned_short(f)
		return swap_endian(f:ReadShort() + USHORT_MAX + 1, 16)
	end

	local function read_unsigned_long(f)
		return swap_endian(f:ReadLong() + ULONG_MAX + 1, 32)
	end

	local function parse_file(f, file_name)
		local offset_table = {}

		offset_table.major_version = read_unsigned_short(f)
		offset_table.minor_version = read_unsigned_short(f)
		offset_table.num_tables = read_unsigned_short(f)
		offset_table.search_range = read_unsigned_short(f)
		offset_table.entry_selector = read_unsigned_short(f)
		offset_table.range_shift = read_unsigned_short(f)

		if offset_table.major_version == 1 and offset_table.minor_version == 0 then
			if offset_table.num_tables > 5000 then error("uh oh " .. offset_table.num_tables) end
			for i = 1, offset_table.num_tables do
				local tbl_dir = {}
				tbl_dir.sz_tag = f:Read(4)
				tbl_dir.checksum = read_unsigned_long(f)
				tbl_dir.offset = read_unsigned_long(f)
				tbl_dir.length = read_unsigned_long(f)

				if tbl_dir.sz_tag == "name" then
					f:Seek(tbl_dir.offset)
					local name_table_header = {}

					name_table_header.format_selector = read_unsigned_short(f)
					name_table_header.name_record_count = read_unsigned_short(f)
					name_table_header.storage_offset = read_unsigned_short(f)

					for i = 1, name_table_header.name_record_count do
						local name_table = {}
						name_table.platform_id = read_unsigned_short(f)
						name_table.encoding_id = read_unsigned_short(f)
						name_table.language_id = read_unsigned_short(f)
						name_table.name_id = read_unsigned_short(f)
						name_table.string_length = read_unsigned_short(f)
						name_table.string_offset = read_unsigned_short(f)

						local key = name_ids[name_table.name_id]

						if key then
							if name_table.string_length > 0 then
								local pos = f:Tell()
								f:Seek(tbl_dir.offset + name_table.string_offset + name_table_header.storage_offset)
								local name = f:Read(name_table.string_length)
								if #name > 0 then
									local temp = ""
									for i = 1, #name do
										local char = name:sub(i, i)
										if char:byte() > 0 then
											temp = temp .. char
										end
									end
									name = temp

									font_names[file_name] = font_names[file_name] or {}
									font_names[file_name][key] = name:lower()
								end
								f:Seek(pos)
							end
						end
					end
				end
			end
		end
	end

	for _, dir in ipairs({"resource/fonts/", "resource/"}) do
		local temp = file.Find(dir .. "*.ttf", "GAME")

		local files = {}
		local done = {}
		for k,v in ipairs(temp) do
			if v:EndsWith(".ttf") then
				if not done[v:lower()] then
					table.insert(files, v)
					done[v:lower()] = true
				end
			end
		end

		for _, file_name in ipairs(files) do
			if not font_names[dir..file_name] then
				local f = file.Open(dir .. file_name, "rb", "GAME")
				parse_file(f, dir .. file_name)
				f:Close()
			end
		end
	end

	file.Write("surface_createfont2_cache.txt", util.TableToJSON(font_names))
end

local full_name_lookup = {}
local family_lookup = {}

for k,v in pairs(font_names) do
	v.path = k
	full_name_lookup[v.full_name] = v
	family_lookup[v.family] = family_lookup[v.family] or {}
	family_lookup[v.family][v.subfamily] = v
end

local weight_names = {
	"thin",
	"extra light",
	"light",
	"regular",
	"medium",
	"semi bold",
	"bold",
	"extra bold",
	"black",
}

local weight_translate = {
	normal = "regular",
}

for k,v in pairs(weight_names) do
	weight_translate[v] = v
end

local blacklist = {
	italic = true,
	roman = true,
}

local function font_from_family(family, options)
	local weight = options.weight or 0
	local italic = options.italic

	local weights = {}
	local done = {}

	for _, name in ipairs(weight_names) do
		for sub_family, info in pairs(family) do
			for _, name2 in ipairs(sub_family:Split(" ")) do
				if weight_translate[name2] then
					name2 = weight_translate[name2]
				end

				if name == name2 and not done[sub_family] then
					table.insert(weights, sub_family)
					done[sub_family] = true
					break
				end
			end
		end
	end

	-- if nothing was found just return the first
	if #weights == 0 then
		if options.weight and options.weight > 550 then
			table.insert(options.warnings, "weight is above 550 but no bold fonts were found")
		end

		if italic then
			table.insert(options.warnings, "italic is set to true but no italic fonts were found")
		end

		if table.Count(family) == 1 then
			local _, font = next(family)
			return font
		end

		return
	end

	for i = #weights, 1, -1 do
		if italic then
			if not weights[i]:find("italic") then
				table.remove(weights, i)
			end
		else
			if weights[i]:find("italic") then
				table.remove(weights, i)
			end
		end
	end

	return family[weights[math.Clamp(math.ceil(weight/100), 1, #weights)]]
end

surface.created_fonts = surface.created_fonts or {}

surface.old_CreateFont = surface.old_CreateFont or surface.CreateFont
function surface.CreateFont(id, tbl, ...)
	if id:StartWith("Expression") then
		print(id)
		return surface.old_CreateFont(id, tbl, ...)
	end

	local copy = {}
	for k,v in pairs(tbl) do copy[k] = v end
	tbl = copy

	local font_name = tbl.font

	tbl.font = nil
	tbl.warnings = {}

	if font_name then
		local font_name = font_name:lower()

		local font

		if full_name_lookup[font_name] then
			font = full_name_lookup[font_name]
		elseif family_lookup[font_name] then
			font = font_from_family(family_lookup[font_name], tbl)
			if not font then
				ErrorNoHalt("font " .. font_name .. " was recognized as a font family but no font in the family could be found\n")
				PrintTable(tbl)
			end
		end

		if tbl.antialias == false then
			table.insert(tbl.warnings, "tried to set antialias to false but this is not supported on linux")
		end

		if tbl.size and tbl.size > 126 then
			table.insert(tbl.warnings, "size is above 126. max size is 128 but because of outline size differences it needs to be 126")
			tbl.size = 126
		end

		if font then
			if system.IsWindows() then
				tbl.font = font.full_name
			else
				if font.path:StartWith("resource/fonts/") then
					tbl.font = font.path:match(".+/(.+)")
				else
					tbl.font = font.full_name
				end
			end
			tbl.real_font = font
		end
	end

	if not tbl.font then
		tbl.invalid = true
		tbl.stack_trace = debug.traceback()
	end

	tbl.original_font_name = font_name

	surface.created_fonts[id] = tbl

	return surface.old_CreateFont(id, {
		font = tbl.font,
		extended = tbl.extended,
		size = tbl.size,
		blursize = tbl.blursize,
		scanlines = tbl.scanlines,
		symbol = tbl.symbol,
		rotary = tbl.rotary,
		shadow = tbl.shadow,
		additive = tbl.additive,
		outline = tbl.outline,

		antialias = true,
		weight = 0,
		underline = false,
		italic = false,
		strikeout = false,
	}, ...)
end

function surface.GetFonts()
	local out = {}

	for k,v in pairs(full_name_lookup) do
		table.insert(out, k)
	end

	return out
end

local function display_chunk(str, pattern)
	if pattern then
		local start, stop = str:find(pattern)
		if start then
			local str_start = str:sub(0, start-1)
			local str_stop = str:sub(stop+1)
			Msg(str_start) MsgC(Color(255, 100, 100, 255), pattern) Msg(str_stop)
			MsgN(("="):rep(30))
		end
	else
		Msg(str)
		MsgN(("="):rep(30))
	end
end

concommand.Add("dump_font_families", function(_,_,_,pattern)
	for k,v in pairs(family_lookup) do
		local str = ""
		str = str .. k .. "\n"

		for k,v in pairs(v) do
			str = str .. "\t" .. k .. "\n"
			for k,v in pairs(v) do
				str = str .. "\t\t" .. k .. " = " .. v .. "\n"
			end
		end

		display_chunk(str, pattern)
	end
end)

concommand.Add("dump_font_names", function(_,_,_,pattern)
	for k,v in pairs(full_name_lookup) do
		local str = ""
		str = str .. k .. "\n"

		for k,v in pairs(v) do
			str = str .. "\t" .. k .. " = " .. v .. "\n"
		end

		display_chunk(str, pattern)
	end
end)

local defaults = {
	extended = false,
	size = 13,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
}

concommand.Add("dump_fonts_created", function(_,_,_,search)
	for k,v in pairs(surface.created_fonts) do
		if not v.invalid then
			local str = ""

			str = str .. k .. "\n"
			for k,v in pairs(v) do
				if k ~= "invalid" and k ~= "original_font_name" and k ~= "real_font" and k ~= "font" and k ~= "warnings" and v ~= defaults[k] then
					str = str .. "\t" .. k .. " = " .. tostring(v) .. "\n"
				end
			end
			str = str .. "\tfont = " .. v.real_font.full_name .. ":" .. "\n"
			for k,v in pairs(v.real_font) do
				if k ~= "full_name" then
					str = str .. "\t\t" .. k .. " = " .. v .. "\n"
				end
			end

			if v.warnings[1] then
				str = str .. "\twarnings:\n"
				for k,v in pairs(v.real_font) do
					str = str .. v .. "\n"
				end
			end

			display_chunk(str, search)
		end
	end
end)

concommand.Add("dump_invalid_fonts", function(_,_,_,search)
	for k, v in pairs(surface.created_fonts) do
		if v.invalid then
			local str = ""
			str = str .. k .. "\n"
			str = str .. "\tinvalid_font = " ..  v.original_font_name .. "\n"
			for k,v in pairs(v) do
				if k ~= "stack_trace" and k ~= "invalid" and k ~= "original_font_name" and v ~= defaults[k] then
					str = str .. "\t" .. k .. " = " .. tostring(v) .. "\n"
				end
			end
			for i, line in ipairs(v.stack_trace:Split("\n"))  do
				if i == 1 then
					str = str .. "\t" .. line:Trim() .. "\n"
				else
					str = str .. "\t\t" .. line:Trim() .. "\n"
				end
			end
			display_chunk(str, search)
		end
	end
end)

if system.IsLinux() then
	local current_font

	surface.old_SetFont = surface.old_SetFont or surface.SetFont
	function surface.SetFont(name, ...)
		current_font = surface.created_fonts[name]
		return surface.old_SetFont(name, ...)
	end

	surface.old_SetTextPos = surface.old_SetTextPos or surface.SetTextPos
	function surface.SetTextPos(x, ...)
		if current_font and current_font.outline then
			x = x + 1
		end
		return surface.old_SetTextPos(x, ...)
	end
end