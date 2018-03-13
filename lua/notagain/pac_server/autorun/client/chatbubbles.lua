local circle = { mat=Material("sgm/playercircle") }
local speaker = { mat=Material("gmod/recording.png") }

hook.Add("PlayerStartVoice", "tBubbles_VoicePanel", function()
    -- InitPostEntity was not working here. :(
    if IsValid(g_VoicePanelList) then
        g_VoicePanelList:SetVisible(false)
    end
    print("Attempting to hide g_VoicePanelList...")
    hook.Remove("PlayerStartVoice", "tBubbles_VoicePanel")
end)

hook.Add( "PrePlayerDraw", "tBubbles", function( ply )
    if not IsValid(ply) then return end
    if ply == LocalPlayer() then return end

    circle.colour = GAMEMODE:GetTeamColor(ply) or Color(127,159,255,255)

    ply.speaker_fade = ply.speaker_fade or 0

    if ply.is_talking then
        if ply.speaker_fade < 1 then
            ply.speaker_fade = ply.speaker_fade + FrameTime()
        else
            ply.speaker_fade = 1
        end
    else
        if ply.speaker_fade > 0 then
            ply.speaker_fade = ply.speaker_fade - (FrameTime() * 2)
        else
            ply.speaker_fade = 0
        end
    end

    circle.colour.a = Lerp(ply.speaker_fade, 0, 255)

    if circle.colour.a > 0 then
        local radius = {min = ply:OBBMins(), max = ply:OBBMaxs()}
        radius = radius.min:Distance(Vector(radius.max.x,radius.max.y,radius.min.z)) * 0.75

        local trace = {}
        trace.start = ply:GetPos() + Vector(0,0,50)
        trace.endpos = trace.start + Vector(0,0,-135)
        trace.filter = ply

        local tr = util.TraceLine(trace)
        circle.size = (radius + (ply:VoiceVolume() * 20)) * (1 - (tr.Fraction <= 0.4 and 0 or tr.Fraction >= 0.8 and 1 or tr.Fraction))

        if not tr.HitWorld then
            tr.HitPos = ply:GetPos()
            tr.HitNormal = Vector(0,0,1)
            circle.size = (radius + (ply:VoiceVolume() * 20))
            circle.colour.a = circle.colour.a - 150
        end

        render.SetMaterial(circle.mat)
        render.DrawQuadEasy(tr.HitPos + tr.HitNormal, tr.HitNormal, circle.size, circle.size, circle.colour)
        render.DrawQuadEasy(tr.HitPos + tr.HitNormal, tr.HitNormal*-1, circle.size, circle.size, circle.colour)
    end
end)

local IsTalking = false
local RecFade = 0
local RecBounce = 0

hook.Add("HUDPaint", "tBubbles", function()
    local size = 128
    local x = ScrW() - (size * 2)
    local y = ScrH() - (size + 50)

    if IsTalking then
        RecBounce = (RecBounce + FrameTime())%360
        if RecFade < 1 then
            RecFade = RecFade + (FrameTime() * 2)
        else
            RecFade = 1
        end
    else
        if RecFade > 0 then
            RecFade = RecFade - (FrameTime() * 2)
        else
            RecFade = 0
        end
    end

    local alpha = Lerp(RecFade, 0, 255)

    if alpha > 0 then
        surface.SetDrawColor( 255, 255, 255, alpha )
        surface.SetMaterial( speaker.mat )
        surface.DrawTexturedRect( x, y - ( math.abs(math.sin(RecBounce*4))*40 ), size * 2, size )
    end
end)

hook.Add( "PlayerStartVoice", "tBubbles", function(ply)
    if LocalPlayer() == ply then
        IsTalking = true
    end

    ply.is_talking = true
end)

hook.Add( "PlayerEndVoice", "tBubbles", function(ply)
    if LocalPlayer() == ply then
        IsTalking = false
    end

    ply.is_talking = false
end)
