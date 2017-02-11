gameevent.Listen("player_connect")
hook.Add("player_connect","SetIPAddress",function(data)
    util.SetPData(data.networkid,"IP",string.Split(data.address,":")[1]) -- well it works
end)

FindMetaTable("Player").IP = function(ply)
    return ply:GetPData("IP",nil)
end