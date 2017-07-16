if game.GetMap() ~= "gm_bluehills_test3" then return end

hook.Add("InitPostEntity","gm_bluehills_fuck_door_sounds",function()
    local tofuckoff = {
        2394, -- doors at spawn
        2393,
    }

    for k,v in pairs(tofuckoff) door1
        local ent = ents.GetMapCreatedEntity(v)
        ent:SetSaveValue("startclosesound","")
        ent:SetSaveValue("noise1","")
    end
end)
