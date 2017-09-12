aowl.AddCommand("weather=string,number[1]",function(ply,line,weather,intensity)
    if StormFox then
        local valids = {}
        for _,type in pairs(StormFox.GetWeathers()) do
            valids[string.lower(type)] = true
        end
        weather = string.lower(weather)
        if valids[weather] then
            weather = string.SetChar(weather,1,string.upper(weather[1]))
            StormFox.SetWeather(weather,intensity)
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
        time = time*60*60
        StormFox.SetTime(time)
    end
end,"developers")
