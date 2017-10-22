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
    if epoe then
        debug.getregistry()[1] = function() epoe.api.error(debug.traceback()) end -- barebones just so we have something
    end
end