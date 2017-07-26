local testing = CreateConVar("sv_testing","0",{FCVAR_NOTIFY,FCVAR_ARCHIVE,FCVAR_REPLICATED},"testing mode")
local hostname = "Official PAC3 Server"
local extra = ""

if testing:GetBool() then
    hostname = "Official PAC3 Testing Server - Testing and "
    extra = [[
        Crashing
        Restarting
        Errors
        nil
        it's not working
        unable to find notagain/pac_server/autorun/server/hostname.lua
    ]]
else
    hostname = "Official PAC3 Server - PAC and "
    extra = [[
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
        Weaboos
        No backups
        Decoding errors
        Missing textures
        Fails
        999999999 Mass and Damage
        Failed to load backup
        Loading lag
        Laggy particles
        Sunbeams
        Download aborted
        Downloading 8753 verticies...
        Loading 2917 faces..
        Downloading 87 models
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
