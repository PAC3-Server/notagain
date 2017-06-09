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
        else
             MsgC(Color(102, 217, 239),tab..tostring(k).." ⮞⮞ "..tostring(v).."\n")
        end
    end
end

PFind = function(search,vars,funcs,tables,hooks,timers,entities,fonts)
    local search     = string.lower(search)
    local results    = {}
    results.Funcs    = {}
    results.Vars     = {}
    results.Tables   = {}
    results.Hooks    = {}
    results.Timers   = {}
    results.Entities = {}

    if CLIENT then
        results.Fonts = {}
        results.Fonts = Font.Find(search)
    end

    results.Funcs,results.Vars,results.Tables = find(search,_G)
    results.Entities = matchents(search,ents.GetAll())
    results.Hooks    = hook.Find(search)
    results.Timers   = timer.Find(search)

    if vars     ~= nil and not vars     then results.Vars     = {} end
    if funcs    ~= nil and not funcs    then results.Funcs    = {} end
    if tables   ~= nil and not tables   then results.Tables   = {} end
    if hooks    ~= nil and not hooks    then results.Hooks    = {} end
    if timers   ~= nil and not timers   then results.Timers   = {} end
    if entities ~= nil and not entities then results.Entities = {} end
    if fonts    ~= nil and not fonts    then results.Fonts    = {} end

    local cfunc   = table.Count(results.Funcs)
    local cvars   = table.Count(results.Vars)
    local ctables = table.Count(results.Tables)
    local chooks  = table.Count(results.Hooks)
    local ctimer  = table.Count(results.Timers)
    local total   = cfunc + cvars + ctables + chooks + ctimer

    if CLIENT then
        local cfont = table.Count(results.Fonts)
        total = total + cfont
    end

    if total <= 120 then
        reccolor(results)
    else
        MsgC(Color(225,40,40),"Terrible idea!! (too many results)")
    end

end
