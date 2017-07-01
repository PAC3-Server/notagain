local tag = "TimeSaver"
local META = FindMetaTable("Player")

if SERVER then

    META.RefreshTime = function(self)
        if not self.StartTimeSession then
            self.StartTimeSession = CurTime()
        end
        local data = self:GetPData("TimeOnServer",0)
        local sessiontime = CurTime() - self.StartTimeSession
        self:SetPData("TimeOnServer",data + sessiontime)
        self:SetNWInt("TotalTime",tonumber(self:GetPData("TimeOnServer",0)))
    end

    META.GetTotalTime = function(self)
        self:RefreshTime()
        return tonumber(self:GetPData("TimeOnServer",0))
    end

    META.GetNiceTotalTime = function(self)
        return string.FormattedTime(self:GetPlayerTime())
    end

    META.GetSessionTime = function(self)
        return CurTime()-self:GetNWInt("StartTimeSession",0)
    end

    META.GetNiceSessionTime = function(self)
        return string.FormattedTime(self:GetSessionTime())
    end

    hook.Add("PlayerInitialSpawn",tag,function(ply)
        ply:RefreshTime()
    end)


    hook.Add("PlayerDisconnected",tag,function(ply)
        ply:RefreshTime()
    end)
end

if CLIENT then

    META.GetTotalTime = function(self)
        return self:GetNWInt("TotalTime",0) + CurTime()
    end

    META.GetNiceTotalTime = function(self)
        return string.FormattedTime(self:GetPlayerTime())
    end

    META.GetSessionTime = function(self)
        return CurTime()
    end

    META.GetNiceSessionTime = function(self)
        return string.FormattedTime(self:GetSessionTime())
    end

end
