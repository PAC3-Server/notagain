local luadata = requirex("luadata")

local userdata = {}
userdata.players = {}
userdata.known = {}

local function encode(val)
    return luadata.Encode({value = val})
end

local function decode(str)
    return luadata.Decode(str).value
end

local function save(key, val)
    cookie.Set("userdata_" .. key, encode(val))
end

local function load(key)
    local str = cookie.GetString("userdata_" .. key)
    if str then
        return decode(str)
    end
end

function userdata.SetupConVar(key, default, callback)
    userdata.known[key] = {
        default = default,
        cvar = CreateClientConVar(key, default, true, false, help),
        callback = callback,
    }

    if CLIENT then
        cvars.AddChangeCallback(key, function(_, old, new)
            net.Start("userdata")
                net.WriteString(key)
                net.WriteType(new)
            net.SendToServer()
        end, "userdata_" .. key)

        net.Start("userdata")
            net.WriteString(key)
            net.WriteType(userdata.known[key]:GetString())
        net.SendToServer()

        if userdata.known[key].callback then
            userdata.known[key].callback(ply, new)
        end
    end
end

function userdata.Setup(key, default, callback)
    userdata.known[key] = {
        default = default,
        callback = callback,
    }

    if CLIENT then
        if
            not load(key) or
            not pcall(function()
                assert(load(key) ~= nil)
            end)
        then
            save(key, default)
        end

        local val = load(key)

        if userdata.known[key].callback then
            local ok, err = pcall(userdata.known[key].callback, LocalPlayer(), val)
            if not ok then
                print("error setting up userdata due to callback error, defaulting to default value")
                print(err)
                save(key, defaulting)
                val = default
            end
        end

        net.Start("userdata")
            net.WriteString(key)
            net.WriteType(load(key))
        net.SendToServer()

        local uid = LocalPlayer():UniqueID()
        userdata.players[uid] = userdata.players[uid] or {}
        userdata.players[uid][key] = val
    end
end

if CLIENT then
    function userdata.Set(key, val)
        local data = userdata.known[key]
        if not data then return end

        if type(data) == "ConVar" then
            userdata.known[key]:SetString(val)
        else
            if data.callback then
                local ok, err = pcall(data.callback, LocalPlayer(), val)
                if not ok then
                    print("userdata error: " .. err)
                    return
                end
            end

            save(key, val)

            local uid = LocalPlayer():UniqueID()
            userdata.players[uid] = userdata.players[uid] or {}
            userdata.players[uid][key] = val

            net.Start("userdata")
                net.WriteString(key)
                net.WriteType(load(key))
            net.SendToServer()
        end
    end

    function userdata.Get(ply, key, default)
        if not userdata.known[key] then return default end

        local data = userdata.players[ply:UniqueID()]

        if not data then
            return userdata.known[key].default or default
        end

        return data[key]
    end

    net.Receive("userdata_broadcast", function(len)
        local ply = net.ReadEntity()
        local key = net.ReadString()
        local val = net.ReadType()

        if userdata.known[key].callback then
            local ok, err = pcall(userdata.known[key].callback, ply, val)
            if not ok then
                print("userdata error: " .. err)
            end
        end

        local uid = ply:UniqueID()
        userdata.players[uid] = userdata.players[uid] or {}
        userdata.players[uid][key] = val
    end)
end

if SERVER then
    util.AddNetworkString("userdata")
    util.AddNetworkString("userdata_broadcast")

    net.Receive("userdata", function(len, ply)
        local key = net.ReadString()
        if not userdata.known[key] then return end

        local val = net.ReadType()

        if userdata.known[key].callback then
            local ok, err = pcall(userdata.known[key].callback, ply, val)
            if not ok then
                print("userdata error: ", err)
            end
        end

        userdata.players[ply:UniqueID()] = userdata.players[ply:UniqueID()] or {}
        userdata.players[ply:UniqueID()][key] = val

        net.Start("userdata_broadcast")
            net.WriteEntity(ply)
            net.WriteString(key)
            net.WriteType(val)
        net.SendOmit(ply)
    end)

    hook.Add("PlayerFullLoad", "userdata", function(ply)
        userdata.players[ply:UniqueID()] = userdata.players[ply:UniqueID()] or {}

        for _, other in pairs(player.GetAll()) do
            if ply == other then continue end

            userdata.players[other:UniqueID()] = userdata.players[other:UniqueID()] or {}

            local data = userdata.players[other:UniqueID()]
            for key, val in pairs(data) do
                net.Start("userdata_broadcast")
                    net.WriteEntity(other)
                    net.WriteString(key)
                    net.WriteType(val)
                net.Send(ply)
            end
        end
    end)

    hook.Add("EntityRemoved", "userdata", function(ply)
        if not ply:IsValid() or not ply:IsPlayer() then return end

        userdata.players[ply:UniqueID()] = nil
    end)

    for _, ply in ipairs(player.GetAll()) do
        userdata.players[ply:UniqueID()] = {}
    end
end

return userdata