-- epoe api functions --
-- function api.Msg(...)
-- function api.MsgC(...)
-- function api.MsgN(...)
-- function api.print(...)
-- function api.MsgAll(...)
-- function api.ClientLuaError(str)
-- function api.ErrorNoHalt(...)
-- function api.error(...)

local github = {
        ["pac3"] = {
            ["url"] = "https://github.com/CapsAdmin/pac3/tree/master/"
        },
        ["notagain"] = {
            ["url"] = "https://github.com/PAC3-Server/notagain/tree/master/"
        },
        ["easychat"] = {
            ["url"] = "https://github.com/PAC3-Server/EasyChat/tree/master/"
        },
        ["gm-http-discordrelay"] = {
            ["url"] = "https://github.com/PAC3-Server/gm-http-discordrelay/tree/master/"
        },
        ["includes"] = { -- garry stuff
            ["url"] = "https://github.com/Facepunch/garrysmod/tree/master/garrysmod/"
        }
    }
    github["vgui"] = github["includes"]
    github["weapons"] = github["includes"]
    github["entities"] = github["includes"]
    github["derma"] = github["includes"]
    github["menu"] = github["includes"]
    github["vgui"] = github["includes"]
    github["weapons"] = github["includes"]

if CLIENT then

    hook.Add("EPOEAddLinkPatterns", "Clickable Errors", function(t)
        table.insert(t,"(lua/.-):(%d+):?")
    end)

    hook.Add("EPOEOpenLink", "Clickable Errors", function(l)
        if not l then return end
        local yes = false
        l = l:gsub("(lua/.-):(%d+):?", function(l, n)
            local n = n or ""
            local addon = l:match("lua/(.-)/")
            if addon and github[addon] then
                yes = true
                return github[addon].url .. l .. "#L" .. n
            end
            return "???"
        end)
        if yes then
            gui.OpenURL(l)
        end
        return true
    end)

    --local old_error = debug.getregistry()[1]
    debug.getregistry()[1] = function(...)
        local info = debug.getinfo(2)
        local info2 = debug.getinfo(3)
        -- hack
        info["func"] = nil
        info2["func"] = nil
        --
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
            locals = locals,
            trace = trace
        }
        net.Start("ClientError")
            net.WriteUInt(tonumber(util.CRC(trace)) ,32)
            net.WriteTable(tbl)
        net.SendToServer()

       -- old_error(...) -- compat??
    end
end

if SERVER then
    util.AddNetworkString("ClientError")
    --local old_error = debug.getregistry()[1]

    debug.getregistry()[1] = function(...)
        local info = debug.getinfo(2)
        local info2 = debug.getinfo(3)
        local fname = info["name"]
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
            api.MsgN(locals)
            api.error(trace)
            api.MsgC(Color(255,0,0),"--   --")
            api.Msg("\n")

        else
            print(fname,"\n",src,"\n",locals,"\n",trace) -- fallback????
        end

        hook.Run("LuaError", {info, info2}, locals, trace)

       -- old_error(...) -- compat??
    end

    local ids = {}
    net.Receive("ClientError", function(len, ply)
        local id = net.ReadUInt(32)
        if ids[id] then return end
        local payload = net.ReadTable()
        local info = payload["info"][1]
        local info2 = payload["info"][2]
        local fname = info["name"]
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