hook.Add("EntityEmitSound", "gm_bluehills_mute_map", function(data)
    if data.Entity:MapCreationID() == 2393 or data.Entity:MapCreationID() == 2394 then
        return false
    end
end)