local function canHear(listener, talker)
    local lShootPos = listener:GetShootPos()
    local tShootPos = talker:GetShootPos()

    local distance = lShootPos:DistToSqr(tShootPos)
    local wallDepth = 0

    if distance > 360000 then return false end

    local trA = util.TraceLine({
        start = listener:GetShootPos(),
        endpos = talker:GetShootPos(),
        mask = MASK_SHOT
    })

    local trB = {}

    if trA.Entity == talker then
        return true
    end

    if distance > 40000 then return false end

    trB = util.TraceLine({
        start = talker:GetShootPos(),
        endpos = trA.HitPos,
        filter = talker,
        mask = MASK_VISIBLE
    })

    if trB.Entity == listener then
        return true
    end

    wallDepth = trA.HitPos:DistToSqr(trB.HitPos)
    return ( wallDepth < 100 )
end

local function calcPlyCanHearPlayerVoice(listener)
    listener.CanHear = listener.CanHear or {}
    local shootPos = listener:GetShootPos()

    for _, talker in ipairs( player.GetAll() ) do
        local talkerShootPos = talker:GetShootPos()
        listener.CanHear[talker] = canHear(listener, talker)
    end
end

local lastDelay = 0
local playerCount = player.GetCount()

local function timerFunction()
    for _,v in ipairs( player.GetAll() ) do
        calcPlyCanHearPlayerVoice(v)
    end
end

local function scaleDelay()
    playerCount = player.GetCount()
    local scale = playerCount/10

    if scale < 1 and lastDelay ~= 0.1 then
        timer.Remove("PlayerVoiceCalc")
        timer.Create("PlayerVoiceCalc", 0.1, 0, timerFunction)

        lastDelay = 0.1
        print("[3dVoice] Delay Scaled to "..lastDelay)
    elseif scale > 1 and scale < 3 and lastDelay ~= 0.25 then
        timer.Remove("PlayerVoiceCalc")
        timer.Create("PlayerVoiceCalc", 0.25, 0, timerFunction)

        lastDelay = 0.25
        print("[3dVoice] Delay Scaled to "..lastDelay)
    elseif scale > 3 and lastDelay ~= 0.5 then
        timer.Remove("PlayerVoiceCalc")
        timer.Create("PlayerVoiceCalc", 0.5, 0, timerFunction)

        lastDelay = 0.5
        print("[3dVoice] Delay Scaled to "..lastDelay)
    end
end

scaleDelay()

hook.Add("PlayerInitialSpawn", "PlayerVoiceCalc", function()
    scaleDelay()
end)

hook.Add("PlayerDisconnected", "PlayerVoiceCalc", function(ply)
    if not ply.CanHear then return end
    for _, v in ipairs( player.GetAll() ) do
        if not v.CanHear then continue end
        v.CanHear[ply] = nil
    end

    scaleDelay()
end)

hook.Add("PlayerCanHearPlayersVoice", "voice_chat_3d", function(listener, talker)
    local canHear = (listener.CanHear and listener.CanHear[talker])
    return canHear, true
end)
