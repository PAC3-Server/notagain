if game.GetMap() ~= "gm_bluehills_test3" then return end

local fuckoff = function()
    local tofuckoff = {
        2394, -- doors at spawn
        2393,
    }

    for k,v in pairs(tofuckoff) do
        local ent = ents.GetMapCreatedEntity(v)
        ent:SetSaveValue("startclosesound","")
        ent:SetSaveValue("noise1","")
    end
end

hook.Add("InitPostEntity","gm_bluehills_fuck_door_sounds",fuckoff)
hook.Add("PostCleanupMap","gm_bluehills_fuck_door_sounds",fuckoff)
