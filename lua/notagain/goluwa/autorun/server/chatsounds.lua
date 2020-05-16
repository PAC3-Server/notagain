util.AddNetworkString("chatsounds_subscriptions_broadcast")
util.AddNetworkString("chatsounds_subscriptions")

net.Receive("chatsounds_subscriptions", function(len, ply)
    local count = net.ReadInt(32)

    if not (count >= 1 and count <= 5) then
        return
    end

    local subs = {}

    for i = 1, count do
        subs[i] = net.ReadString()
    end

    net.Start("chatsounds_subscriptions_broadcast")
        net.WriteEntity(ply)
        net.WriteTable(subs)
    net.SendOmit(ply)
end)