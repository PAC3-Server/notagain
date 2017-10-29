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


if CLIENT then
    local old_error = debug.getregistry()[1]
    debug.getregistry()[1] = function(...)
        local info = debug.getinfo(2)
        local info2 = debug.getinfo(3)
        -- hack
        info["func"] = nil
        info2["func"] = nil
        --
        local src = {TryGithub(info["short_src"], info["currentline"], info["linedefined"], info["lastlinedefined"])}
        local i = 1
        local lcls = {}
        local NIL = {}
        while true do
            local n, v = debug.getlocal(2,i)
            if ( n == nil ) then break end
            n = (n == "(*temporary)") and "error>>>>>>>>>>" or n
            lcls[n] = v == nil and NIL or v
            i = i + 1
        end
        local locals = table.ToString(lcls,"Locals",true)
        local trace = debug.traceback("",2)
        local tbl = {
            info = {info, info2},
            src = src,
            locals = locals,
            trace = trace
        }
        net.Start("ClientError")
            net.WriteUInt(tonumber(util.CRC(trace)) ,32)
            net.WriteTable(tbl)
        net.SendToServer()
    end
    old_error(...) -- compat??
end

if SERVER then
    util.AddNetworkString("ClientError")
    local old_error = debug.getregistry()[1]

    debug.getregistry()[1] = function(...)
        local info = debug.getinfo(2)
        local info2 = debug.getinfo(3)
        local fname = info["name"]
        local src = {TryGithub(info["short_src"], info["currentline"], info["linedefined"], info["lastlinedefined"])}
        local i = 1
        local lcls = {}
        local NIL = {}
        while true do
            local n, v = debug.getlocal(2,i)
            if ( n == nil ) then break end
            n = (n == "(*temporary)") and "error>>>>>>>>>>" or n
            lcls[n] = v == nil and NIL or v
            i = i + 1
        end
        local locals = table.ToString(lcls,"Locals",true)
        local trace = debug.traceback("",2)

        if epoe then
            local api = epoe.api
            api.MsgC(Color(255,0,0),"-- [ ERROR BY FUNCTION ")
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
            api.MsgC(Color(255,0,0),"--   --")
            api.Msg("\n")

        else
            print(fname,"\n",src,"\n",locals,"\n",trace) -- fallback????
        end

        hook.Run("LuaError", {info, info2}, locals, trace)
    end

    old_error(...) -- compat??

    local last
    local ids = {}
    net.Receive("ClientError", function(len, ply)
        local now = RealTime()
        local id = net.ReadUInt(32)
        if ids[id] then return end
        local payload = net.ReadTable()
        local info = payload["info"][1]
        local info2 = payload["info"][2]
        local fname = info["name"]
        local src = payload["src"]
        local locals = payload["locals"]
        local trace = payload["trace"]

        if epoe then
            local api = epoe.api
            api.MsgC(Color(255,0,0),"-- [ CLIENT ERROR BY FUNCTION ")
            api.Msg(fname)
            api.MsgC(Color(255,0,0)," FROM ")
            api.Msg(ply and ply:Nick() or "???")
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
            api.MsgC(Color(255,0,0),"--   --")
            api.Msg("\n")

        else
            print(fname,"\n",src,"\n",locals,"\n",trace) -- fallback????
        end
        hook.Run("ClientLuaError", ply, {info, info2}, locals, trace)
        ids[id] = true
    end)
end