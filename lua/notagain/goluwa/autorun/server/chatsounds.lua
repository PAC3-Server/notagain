util.AddNetworkString("chatsounds_subscriptions_broadcast")
util.AddNetworkString("chatsounds_subscriptions")

net.Receive("chatsounds_subscriptions", function(len, ply)
    local count = net.ReadInt(32)

    if not (count >= 1 and count <= 5) then
        ply.chatsounds_subscriptions = {}

        net.Start("chatsounds_subscriptions_broadcast")
            net.WriteEntity(ply)
        net.SendOmit(ply)

        return
    end

    local subs = {}

    for i = 1, count do
        subs[i] = net.ReadString()
    end

    ply.chatsounds_subscriptions = subs

    net.Start("chatsounds_subscriptions_broadcast")
        net.WriteEntity(ply)
        net.WriteTable(subs)
    net.SendOmit(ply)
end)

hook.Add("PlayerInitialSpawn", "chatsounds_subscriptions", function(ply)
    for _, other in ipairs(player.GetAll()) do
        net.Start("chatsounds_subscriptions_broadcast")
            net.WriteEntity(other)
            net.WriteTable(other.chatsounds_subscriptions)
        net.SendOmit(ply)
    end
end)