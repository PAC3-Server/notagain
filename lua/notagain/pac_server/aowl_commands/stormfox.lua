aowl.AddCommand("weather=string,number[1]",function(ply,line,weather,intensity)
    if StormFox then
        local valids = {}
        for _,type in ipairs(StormFox.GetWeathers()) do
            valids[type] = true
        end
        weather = string.lower(weather)
        if valids[weather] then
            StormFox.SetWeather(weather,intensity or 1)
        else
            return false,"Not a valid weather type"
        end
    end
end,"developers")

aowl.AddCommand("daytime|tod=number[12]",function(ply,line,time)
    if StormFox then
        if time > 24 or time < 0 then 
            return false,"Invalid day time"
        end
        time = time*60
        StormFox.SetTime(time)
    end
end,"developers")

aowl.AddCommand("temp|temperature=number[15]",function(ply,line,temp)
    if StormFox then
        StormFox.SetNetworkData("Temperature",temp)
    end
end,"developers")
