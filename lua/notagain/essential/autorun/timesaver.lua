local tag = "TimeSaver"
local META = FindMetaTable("Player")

if SERVER then

    hook.Add("PlayerInitialSpawn",tag,function(ply)
        self:SetNWInt("StartTimeSession",CurTime())
        self:SetNWInt("TotalTime",tonumber(self:GetPData("TimeOnServer",0)))
    end)


    hook.Add("PlayerDisconnected",tag,function(ply)
        self:SetPData("TimeOnServer",ply:GetTotalTime())
    end)
end

META.GetTotalTime = function(self)
    return self:GetNWInt("TotalTime",0) + self:GetSessionTime()
end

META.GetNiceTotalTime = function(self)
    return string.FormattedTime(self:GetPlayerTime())
end

META.GetSessionTime = function(self)
    return CurTime() - self:GetNWInt("StartTimeSession",0)
end

META.GetNiceSessionTime = function(self)
    return string.FormattedTime(self:GetSessionTime())
end
