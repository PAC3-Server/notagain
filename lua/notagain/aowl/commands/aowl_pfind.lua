local pfind = "aowl_pfind"
local bl = {
    ["false"] = false,
    ["true"]  = true,
    ["yes"]   = true,
    ["no"]    = false,
    ["_"]     = true,
    ["nil"]   = true,
}

if SERVER then
    util.AddNetworkString(pfind)

    aowl.AddCommand({"p","find"},function(ply,line,search,a,b,c,d,e,f,g)
        if search then 
            PFind(search,bl[a],bl[b],bl[c],bl[d],bl[e],bl[f],bl[g])
        end
    end)

    aowl.AddCommand({"mp","mfind"},function(ply,line,search,a,b,c,d,e,f,g)
        if search then 
            net.Start(pfind)
            net.WriteString(search)
            net.WriteBool(bl[a] or true)
            net.WriteBool(bl[b] or true)
            net.WriteBool(bl[c] or true)
            net.WriteBool(bl[d] or true)
            net.WriteBool(bl[e] or true)
            net.WriteBool(bl[f] or true)
            net.WriteBool(bl[g] or true)
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
