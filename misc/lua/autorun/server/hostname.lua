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
]]

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