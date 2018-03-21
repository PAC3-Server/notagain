local function traceFromTo(listener, talker)
    local tr = util.TraceLine({
        start = listener:GetShootPos(),
        endpos = talker:GetShootPos(),
        mask = MASK_SHOT
    })

    return tr.Entity == talker
end

local function calcPlyCanHearPlayerVoice(listener)
    if not IsValid(listener) then return end

    listener.CanHear = listener.CanHear or {}
    local shootPos = listener:GetShootPos()

    for _, talker in ipairs( player.GetAll() ) do
        local talkerShootPos = talker:GetShootPos()
        listener.CanHear[talker] = (shootPos:DistToSqr(talkerShootPos) < 360000 and traceFromTo(listener, talker))
    end
end

timer.Create("PlayerVoiceCalc", 0.5, 0, function()
    for _,v in ipairs( player.GetAll() ) do
        calcPlyCanHearPlayerVoice(v)
    end
end)

hook.Add("PlayerDisconnected", "PlayerVoiceCalc", function(ply)
    if not ply.CanHear then return end
    for _, v in ipairs( player.GetAll() ) do
        if not v.CanHear then continue end
        v.CanHear[ply] = nil
    end
end)

hook.Add("PlayerCanHearPlayersVoice", "voice_chat_3d", function(listener, talker)
    local canHear = (listener.CanHear and listener.CanHear[talker])
    return canHear, true
end)
