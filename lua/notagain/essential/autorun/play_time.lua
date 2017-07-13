local META = FindMetaTable("Player")

function META:GetTotalTime()
    return self:GetNWInt("TotalTime",0) + self:GetSessionTime()
end

function META:GetNiceTotalTime()
    return string.FormattedTime(self:GetTotalTime())
end

function META:GetSessionTime()
    return CurTime() - self:GetNWInt("StartTimeSession", 0)
end

function META:GetNiceSessionTime()
    return string.FormattedTime(self:GetSessionTime())
end

if SERVER then
    hook.Add("PlayerInitialSpawn", "play_time", function(ply)
        ply:SetNWInt("StartTimeSession", CurTime())
        ply:SetNWInt("TotalTime", tonumber(ply:GetPData("TimeOnServer",0)))
    end)


    hook.Add("PlayerDisconnected", "play_time", function(ply)
        ply:SetPData("TimeOnServer",ply:GetTotalTime())
    end)
end