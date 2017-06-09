local old_createfont = surface.CreateFont
local Font = _G.Font or {}
_G.Font = Font

local all = {}

surface.CreateFont = function(name,table)
    all[name] = table
    old_createfont(name,table)
end

Font.GetAll = function()
    return all
end

Font.Find = function(name)
    local results = {}
    local name = string.lower(name)
    for font,tbl in pairs(all) do
        if string.match(font,name) then
            results[font] = tbl
        end
    end
    return results
end

Font.GetProperties = function(name)
    return all[name] and all[name] or { font = "this font doesnt exist!" }
end

Font.SetProperty = function(name,field,value)
    local font = all[name]
    if font[field] then
        font[field] = value
        return true
    else
        return false
    end 
end

Font.GetProperty = function(name,field)
    if all[name] then
        return all[name][field]
    else
        return nil
    end
end

Font.Redefine = function(name,tbl)
    if not all[name] then return false end

    local oldtbl = all[name]

    for field,value in pairs(tbl) do
        oldtbl[field] = value
    end

    return true
end
