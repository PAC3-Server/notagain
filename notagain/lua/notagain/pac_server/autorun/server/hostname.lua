local testing = CreateConVar("sv_testing","0",{FCVAR_NOTIFY,FCVAR_ARCHIVE,FCVAR_REPLICATED},"testing mode")
local hostname = "Official PAC 3 Server - PAC and "
local extra = [[
    Chill
    Black Triangles
    Prop Pushers
    Errors
    Pain
    Crashes
    Lag
    Minges
    Invalid Proxy Expressions
    34.21 ms
    TimerX frustration
    MEGALOVANIA
]]

if testing:GetBool() then
extra = [[
    Crashing
    Errors
    nil
    Testing
    TODO
    unable to find notagain/pac_server/autorun/server/hostname.lua
]]
end


extra = string.Explode("\n",extra)

do -- get rid of the spaces and last empty key
    local _e = {}
    for i=1,#extra do
        local word = extra[i]:Trim()
        if word:len() >1 then
            table.insert( _e, word )
        end
    end
    extra = _e
end

local function RandomHostname()
    if istable(extra) then
        RunConsoleCommand("hostname",hostname .. extra[math.random(#extra)])
    end
end

timer.Create("RandomHostname",10,0,RandomHostname)
