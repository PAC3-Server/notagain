local easylua = requirex("easylua")
local luadev = requirex("luadev")

local insession = false
hook.Add("LuaDevProcess","easylua",function(stage,script,info,extra,func)
	if stage==luadev.STAGE_PREPROCESS then

		if insession then
			insession=false
			easylua.End()
		end

		if not IsValid(extra.sender) or extra.easylua == false then
			return
		end

		insession = true
		easylua.Start(extra.sender)

		local t={}
		for key, value in pairs(easylua.vars or {}) do
			t[#t+1]=key
		end
		if #t>0 then
			script=' local '..table.concat(t,", ")..' = '..table.concat(t,", ")..' ; '..script
		end

		return script
	elseif stage == luadev.STAGE_COMPILED then

		if not istable(extra) or not IsValid(extra.sender) or not isfunction(func) or extra.easylua==false then
			if insession then
				insession=false
				easylua.End()
			end
			return
		end

		if insession then
			local env = getfenv(func)
			if not env or env==_G then
				setfenv(func, easylua.EnvMeta)
			end
		end

	elseif stage == luadev.STAGE_POST and insession then
		insession=false
		easylua.End()
	end
end)