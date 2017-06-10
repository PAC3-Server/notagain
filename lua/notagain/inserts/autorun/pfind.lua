local function find(search,tbl,rec)
    local rec = rec or 1
    local max = 5
    local funcs,vars,tables = {},{},{}
    for k,v in pairs(tbl) do
        local kstr = tostring(k)
        if string.find(kstr,search,1,true) or string.find(tostring(v),search,1,true) then
            if type(v) == "function" then
                funcs[kstr] = v
            elseif type(v) == "table" then
                tables[kstr] = v
                if rec <= max then
                    local f,v,t = find(search,v,resulttbl,rec+1)
                    table.Add(funcs,f)
                    table.Add(vars,v)
                    table.Add(tables,t)
                end
            else
                vars[kstr] = v
            end
        end
    end
    return funcs,vars,tables
end

local matchents = function(search,tbl)
    local found = {}
    for k,v in pairs(tbl) do
        if not v:IsPlayer() then
            if string.find(v:GetClass(),search,1,true) then
                found[k] = v
            end
        end
    end
    return found
end

local showfunc = function(tab,func)
    if type(func) ~= "function" then
        MsgC(Color(225,40,40),"Terrible idea!! (not a function)")
        return
    end

    local info = debug.getinfo(func)
    if info.what == "C" then
        MsgC(Color(225,40,40),"Terrible idea!! (function is internal)")
        return
    end

    local dir
    if file.Exists(info.short_src, "LUA") then
        dir = "LUA"
    elseif file.Exists(info.short_src, "GAME") then
        dir = "GAME"
    end
    if not dir then
        MsgC(Color(225,40,40),"Terrible idea!! (can't be reaed)")
        return
    end

    local lines = string.Split((file.Read(info.short_src, dir)), "\n")
    if info.lastlinedefined < info.linedefined + 30 then
        for i = info.linedefined,info.lastlinedefined do
            MsgC(Color(50, 186, 140),tab..lines[i].."\n")
        end
    else
        MsgC(Color(50, 186, 140),tab..tostring(func).."[too long]\n")
    end
end

local function reccolor(tbl,rank) -- hi caps
    local rank = rank  or 1
    local tab  = string.rep("\t",rank)

    for k,v in pairs(tbl) do
        if type(v) == "table" then
            if table.Count(v) > 0 then
                MsgC(Color(75, 175, 239),tab..tostring(k)..[[⇊]].."\n")
                reccolor(v,rank+1)
            else
                MsgC(Color(102, 217, 239),tab..tostring(k).." ∅\n")
            end
        elseif type(v) == "function" then
            MsgC(Color(102, 217, 239),tab..tostring(k)..": \n")
            showfunc(tab,v)
        else
            MsgC(Color(102, 217, 239),tab..tostring(k).." ⮞⮞ "..tostring(v).."\n")
        end
    end
end

PFind = function(search,...)
    local args     = { ... }
    local vars     = false
    local tables   = false
    local funcs    = false
    local hooks    = false
    local timers   = false
    local fonts    = false
    local entities = false

    for _,arg in pairs(args) do
        local a = string.lower(arg)
        if string.match(a,"var") then
            vars = true
        elseif string.match(a,"table") then
            tables = true
        elseif string.match(a,"func") then
            funcs = true
        elseif string.match(a,"hook") then
            hooks = true
        elseif string.match(a,"timer") then
            timers = true
        elseif string.match(a,"font") then
            fonts = true
        elseif string.match(a,"ent") then
            entities = true
        end
    end

    --[[local mode = 0

    if string.match(search,"%[\".+\"%]") or string.match(search,"%[%'.+%'%]") then
        mode = 1
    elseif string.match(search,".+%..+") then
        mode = 2
    end]]--

    local search     = string.lower(search)
    local results    = {}
    results.Funcs    = {}
    results.Vars     = {}
    results.Tables   = {}
    results.Hooks    = {}
    results.Timers   = {}
    results.Entities = {}
    results.Fonts    = {}

    results.Funcs,results.Vars,results.Tables = find(search,_G)
    results.Entities = matchents(search,ents.GetAll())
    results.Hooks    = hook.Find(search)
    results.Timers   = timer.Find(search)

    if CLIENT then
        results.Fonts = Font.Find(search)
    end

    if not vars     then results.Vars     = {} end
    if not funcs    then results.Funcs    = {} end
    if not tables   then results.Tables   = {} end
    if not hooks    then results.Hooks    = {} end
    if not timers   then results.Timers   = {} end
    if not entities then results.Entities = {} end
    if not fonts    then results.Fonts    = {} end

    local cfunc   = table.Count(results.Funcs)
    local cvars   = table.Count(results.Vars)
    local ctables = table.Count(results.Tables)
    local chooks  = table.Count(results.Hooks)
    local ctimer  = table.Count(results.Timers)
    local cfont = table.Count(results.Fonts)
    local total   = cfunc + cvars + ctables + chooks + ctimer + cfont

    if total <= 120 then
        reccolor(results)
    else
        MsgC(Color(225,40,40),"Terrible idea!! (too many results)")
    end

end
