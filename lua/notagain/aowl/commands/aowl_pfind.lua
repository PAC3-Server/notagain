local pfind = "aowl_pfind"

if SERVER then
    util.AddNetworkString(pfind)

    aowl.AddCommand({"p","find"},function(ply,line,search,a,b,c,d,e,f,g)
        if search then 
            PFind(search,a,b,c,d,e,f,g)
        end
    end)

    aowl.AddCommand({"mp","mfind"},function(ply,line,search,a,b,c,d,e,f,g)
        if search then 
            net.Start(pfind)
            net.WriteString(search)
            net.WriteBool(a)
            net.WriteBool(b)
            net.WriteBool(c)
            net.WriteBool(d)
            net.WriteBool(e)
            net.WriteBool(f)
            net.WriteBool(g)
            net.Send(ply)
        end
    end)
end

if CLIENT then

    net.Receive(pfind,function()
        local search = net.ReadString()
        local a = net.ReadBool()
        local b = net.ReadBool()
        local c = net.ReadBool() 
        local d = net.ReadBool() 
        local e = net.ReadBool() 
        local f = net.ReadBool() 
        local g = net.ReadBool()

        PFind(search,a,b,c,d,e,f,g)
    end)

end
