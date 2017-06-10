local pfind = "aowl_pfind"

if SERVER then
    util.AddNetworkString(pfind)

    aowl.AddCommand({"p","find"},function(ply,line,search,a,b,c,d,e,f,g)
        if search then
            PFind(search,a or "",b or "",c or "",d or "",e or "",f or "",g or "")
        end
    end)

    aowl.AddCommand({"mp","mfind"},function(ply,line,search,a,b,c,d,e,f,g)
        if search then
            net.Start(pfind)
            net.WriteString(search)
            net.WriteString(a or "")
            net.WriteString(b or "")
            net.WriteString(c or "")
            net.WriteString(d or "")
            net.WriteString(e or "")
            net.WriteString(f or "")
            net.WriteString(g or "")
            net.Send(ply)
        end
    end)
end

if CLIENT then

    net.Receive(pfind,function()
        local search = net.ReadString()
        local a = net.ReadString()
        local b = net.ReadString()
        local c = net.ReadString()
        local d = net.ReadString()
        local e = net.ReadString()
        local f = net.ReadString()
        local g = net.ReadString()

        PFind(search,a,b,c,d,e,f,g)
    end)

end
