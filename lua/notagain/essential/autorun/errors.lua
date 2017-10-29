-- epoe api functions --
-- function api.Msg(...)
-- function api.MsgC(...)
-- function api.MsgN(...)
-- function api.print(...)
-- function api.MsgAll(...)
-- function api.ClientLuaError(str)
-- function api.ErrorNoHalt(...)
-- function api.error(...)

-- todo: formatting and clientside
if SERVER then
    local old_error = debug.getregistry()[1]

    debug.getregistry()[1] = function(...)
        if epoe then
            epoe.api.error(debug.traceback())
        end
        old_error(...)
    end -- barebones just so we have something

end