local function tostringx(obj)
	local t = type(obj)

	if obj == NULL then
		return t .. "(NULL)"
	elseif t == "string" then
		if obj:find("\n", nil, true) then
			obj = obj:gsub("\n", "\\n"):sub(0,50) .. "..."
		end

		return '"' .. obj .. '"'
	elseif t == "Player" then
		return "Player("..obj:UserID()..") -- " .. obj:Nick() .. " / " .. obj:SteamID64()
	elseif t == "Entity" then
		return "Entity("..obj:EntIndex()..")"
	elseif t == "function" then
		local info = debug.getinfo(obj)

		if info.source == "=[C]" then
			return "function() end -- C function"
		else
			local params = {}

			for i = 1, math.huge do
				local key = debug.getlocal(obj, i)
				if key then
					table.insert(params, key)
				else
					break
				end
			end

			return "function(" .. table.concat(params, ", ") .. ") end" -- " .. info.source .. ":" .. info.linedefined
		end
	end

	local ok, str = pcall(tostring, obj)

	if not ok then
		return "tostring error: " .. str
	end

	return str
end

local function line_from_info(info, line)
	local lua
	if info.source:find("<", nil, true) then
		lua = file.Read(info.source:match("%<(.-)%>"), "MOD") -- luadata
	elseif info.source:sub(1,1) == "@" then
		lua = file.Read(info.source:sub(2), "LUA") or file.Read(info.source:sub(2), "MOD")
	end

	if lua then
		local lines = lua:Split("\n")
		return lines[line]
	end
end


local function func_line_from_info(info, line_override, fallback_info)
	if info.namewhat == "metamethod" then
		if info.name == "__add" then
			print(debug.getlocal(info.func, 0), "!")
			print(debug.getlocal(info.func, 1), "!")
			return "+"
		end
	end

	if info.source then
		local line = line_from_info(info, line_override or info.linedefined)
		if line and line:find("%b()") then
			return line:Trim() .. " -- inlined function " .. (info.name or fallback_info or "__UNKNOWN__")
		end
	end

	if info.source == "=[C]" then
		return "function " .. (info.name or fallback_info or "__UNKNOWN__") .. "(=[C])"
	end

	local str = "function " .. (info.name or fallback_info or "__UNKNOWN__")

	str = str .. "("

	local arg_line = {}

	if info.isvararg then
		table.insert(arg_line, "...")
	else
		for i = 1, info.nparams do
			local key, val = debug.getlocal(info.func, i)

			if not key then break end

			if key == "(*temporary)" then
				table.insert(arg_line, tostringx(val))
			elseif key:sub(1, 1) ~= "(" then
				table.insert(arg_line, key)
			end
		end
	end

	str = str .. table.concat(arg_line, ", ")

	str = str .. ")"

	return str
end


return function(offset, check_level)
	offset = offset or 0
	local str = ""

	local max_level = 0
	local min_level = offset

	for level = min_level, math.huge do
		local info = debug.getinfo(level)
		if not info then break end
		max_level = level
	end

	local extra_indent = 3
	local for_loop
	local for_gen
	local generator

	do
		local info = debug.getinfo(max_level)
		extra_indent = extra_indent + 1
		str = str .. (max_level-min_level+1) .. ": "
		str = str .. func_line_from_info(info) .. "\n"
	end

	for level = max_level, min_level, -1 do
		local info = debug.getinfo(level - 1)
		if not info then break end

		if check_level and check_level(info, level) ~= nil then break end

		local t = (" "):rep(-level + max_level + extra_indent)

		for i = 1, math.huge do
			local key, val = debug.getlocal(level, i)
			if not key then break end

			if key == "(for generator)" then
				for_gen = ""
				generator = val
			elseif key == "(for state)" then
			elseif key == "(for control)" then

			elseif key == "(for index)" then
				for_loop = ""
			elseif key == "(for limit)" then
				for_loop = for_loop .. val .. ", "
			elseif key == "(for step)" then
				for_loop = for_loop .. val .. " do"
			elseif key ~= "(*temporary)" then
				if for_loop then
					str = str .. t .. "for " .. key .. " = " .. val .. ", " .. for_loop .. "\n"

					extra_indent = extra_indent + 1
					t = (" "):rep(-level + max_level + extra_indent)

					for_loop = nil
				else

					if for_gen then
						if for_gen == "" then
							for_gen = "for " .. key .. " = " .. tostringx(val) .. ", "
						else
							for_gen = for_gen .. key .. " = " .. tostringx(val) .. " in ??? do"

							str = str .. t .. for_gen .. "\n"

							extra_indent = extra_indent + 1
							t = (" "):rep(-level + max_level + extra_indent)

							generator = nil
							for_gen = nil
						end
					else
						str = str .. t .. key .. " = " .. tostringx(val) .. "\n"
					end
				end
			end
		end

		if not info.name then
			if level == max_level then
				info.name = "main"
			end
		end

		str = str .. (level-min_level) .. ": "
		t = t:sub(4)
		str = str .. t .. func_line_from_info(info)

		str = str .. "\n"
	end

	do
		local level = min_level - 1
		local t = (" "):rep(-level + max_level + extra_indent - 2)

		local info = debug.getinfo(level)
		str = str .. ">>" .. t .. func_line_from_info(info, info.currentline) .. " <<\n"
	end

	return str
end