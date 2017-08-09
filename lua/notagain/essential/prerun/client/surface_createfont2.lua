local font_names = {}

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

	local temp = file.Find("resource/fonts/*", "GAME")

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
		local f = file.Open("resource/fonts/" .. file_name, "rb", "GAME")
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
								--print(name_table.string_length)
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

		f:Close()
	end
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

local function font_from_family(family, weight, italic, extended)
	weight = weight or 0

	local weights = {}
	local done = {}

	for _, name in ipairs(weight_names) do
		for sub_family, info in pairs(family) do
			for _, name2 in ipairs(sub_family:Split(" ")) do

				if name2 ~= "italic" then
					if not weight_translate[name2] then
						print(name2 .. " is not a recognizable flag (" .. sub_family .. ")")
						name2 = "regular"
					else
						name2 = weight_translate[name2]
					end
				end

				if name == name2 and not done[sub_family] then
					table.insert(weights, sub_family)
					done[sub_family] = true
					break
				end
			end
		end
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


concommand.Add("surfacex_dump_fonts", function()
	for k,v in pairs(family_lookup) do
		MsgN(k)

		for k,v in pairs(v) do
			MsgN("\t" .. k)
			for k,v in pairs(v) do
				MsgN("\t\t" .. k .. " = " .. v)
			end
		end
	end
end)

function surface.CreateFont2(name, tbl, ...)
	local copy = {}
	for k,v in pairs(tbl) do copy[k] = v end
	tbl = copy

	local font_name = tbl.font

	tbl.font = nil

	if font_name then
		font_name = font_name:lower()

		local font

		if full_name_lookup[font_name] then
			font = full_name_lookup[font_name]
		else
			font = font_from_family(family_lookup[font_name], tbl.weight, tbl.italic)
		end

		if tbl.outline and system.IsLinux() then
			tbl.size = tbl.size + 2
		end

		if font then
			if system.IsWindows() then
				tbl.font = font.full_name
			else
				tbl.font = font.path
			end
		end

		tbl.weight = 0
		tbl.italic = false
	end

	if not tbl.font then
		error("font " .. font_name .. " could not be found", 2)
	end

	return surface.CreateFont(name, tbl, ...)
end

if LocalPlayer() == me or LocalPlayer() == server then
	for i = 0, 10 do
		local weight = i
		surface.CreateFont2("bold_test_" .. i, {
			font = "Roboto Bold",
			size = 10,
			antialias = false,
			--weight = i*100,
			outline = i > 5,
			--antialias = true,
			--extended = true,
			--additive = true,
			--outline = true,
			--blursize = 1,

			--[[
			extended = false,
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
			]]

			scanlines = false,
		})
	end

	hook.Add("HUDPaint", "", function()
		surface.SetDrawColor(255,0,0,255)
		surface.DrawRect(0,0,500,350)
		surface.SetTextColor(255, 255, 255, 255)
		for i = 0 , 10 do
			surface.SetFont("bold_test_" .. i)
			local _, h = surface.GetTextSize("|")
			for _ = 1, 1 do
			surface.SetTextPos(50, 50 + (i*h))
			surface.DrawText("The quick brown fox jumps over the lazy dog")
			end
		end
	end)
end