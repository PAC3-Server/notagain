-- epoe api functions --
-- function api.Msg(...)
-- function api.MsgC(...)
-- function api.MsgN(...)
-- function api.print(...)
-- function api.MsgAll(...)
-- function api.ClientLuaError(str)
-- function api.ErrorNoHalt(...)
-- function api.error(...)

-- todo: clientside

local IsOnGithub =  -- todo automate ??????
{
    ["notagain"] = true,
    ["gm-http-discordrelay"] = true,
    ["easychat"] = true
}

local function TryGithub(src, line, start, last)
    local addon = src:match("addons/(.-)/lua/")
    local path = src:match("/(lua/.+)")
    if (addon and path) and IsOnGithub[string.lower(addon)] then
        if start and last then
            return "Function: https://github.com/PAC3-Server/" .. addon .. "/tree/master/" .. path .. "#L" .. start .. "-L" .. last, "At: https://github.com/PAC3-Server/" .. addon .. "/tree/master/" .. path .. "#L" .. line
        else
            return "At: https://github.com/PAC3-Server/" .. addon .. "/tree/master/" .. path .. "#L" .. line
        end
    else
        return "in " .. src .. " at line: " .. line
    end
end

if SERVER then
    local old_error = debug.getregistry()[1]

    debug.getregistry()[1] = function(...)

        local info = debug.getinfo(2)
        local fname = info["name"]
        local src = {TryGithub(info["short_src"], info["currentline"], info["linedefined"], info["lastlinedefined"])}
        local i = 1
        local lcls = {}
        while true do
            local n, v = debug.getlocal(2,i)
            if ( n == nil ) then break end
            n = (n == "(*temporary)") and ">>>>>>>>>>" or n
            lcls[n] = v
            i = i + 1
        end
        local locals = table.ToString(lcls,"Locals",true)
        local trace = debug.traceback()

        if epoe then
            local api = epoe.api
            api.MsgC(Color(255,0,0),"-- [ERROR from ")
            api.Msg(fname)
            api.MsgC(Color(255,0,0)," ] --")
            api.Msg("\n")
            api.MsgC(Color(0,128,255),src[1])
            if src[2] then
                api.Msg("\n")
                api.MsgC(Color(0,128,255),src[2])
            end
            api.Msg("\n")
            api.MsgN(locals)
            api.error(trace)
            api.MsgC(Color(255,0,0),"-- [ ] --")
            api.Msg("\n")

        else
            print(fname,"\n",src,"\n",locals,"\n",trace) -- fallback????
        end

        hook.Run("LuaError", {info = info, locals = locals, trace = trace})

        old_error(...) -- compat??
    end
end