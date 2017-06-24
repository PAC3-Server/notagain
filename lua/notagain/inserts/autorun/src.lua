function src(...)
    if type(...) ~= "function" then return end

    local info = debug.getinfo(...)
    if info.what == "C" then return end

    local dir
    if file.Exists(info.short_src, "LUA") then
        dir = "LUA"
    elseif file.Exists(info.short_src, "GAME") then
        dir = "GAME"
    end
    if not dir then return end 

    local lines = string.Split((file.Read(info.short_src, loc)), "\n")
    MsgC(Color(220, 204, 82), "@"..tostring(info.short_src).." "..info.linedefined.." - "..info.lastlinedefined.."\n")
    for i=info.linedefined,info.lastlinedefined do
        MsgC(Color(244,167,66),lines[i].."\n")
    end
end

local metatable = debug.getmetatable(function() end) or {}
local index = metatable.__index or metatable
metatable.__index = metatable.__index or index 

index.src = src

debug.setmetatable(function() end,index)
