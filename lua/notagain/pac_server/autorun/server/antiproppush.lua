local function IsPlayer(ent)
    return ent:GetClass() == "player" or false
end

local function NotWorld(ent)
    if IsPlayer(ent) then return true end

    if ent == Entity(0) or ent:IsWorld() then
        return false
    end

    return true
end

local function CanPush(ent, ply)
    if not IsValid(ent) then return false end

    local owner = ent.pickedby or ( ent.CPPIGetOwner and ent:CPPIGetOwner() ) or nil
    local canAlter = false

    if IsValid(owner) then
        canAlter = ( owner.CanAlter and owner:CanAlter(ply) )
    else
        canAlter = ( ent.CanAlter and ent:CanAlter(ply) )
    end

    return canAlter
end

local function wait(callback, frames)
    local delay = FrameTime() * ( frames or 1 )
    local function throw(msg, ...)
        ErrorNoHalt("L"..(debug.traceback()).." "..msg..(...))
    end
    timer.Simple(delay, function() 
        xpcall(callback, throw)
    end)
end

local ShouldCollideCache = {}

hook.Add("ShouldCollide", "antiphyspush", function(entA, entB)
    if entA and entB then
        if entA.PushProtected then
            local id = entA._ShouldCollideID
            local cache = ShouldCollideCache[id]
            local compare = NotWorld(entB) and entB or "world"

            if cache and cache.compare == compare then
                return false
            end

            if not CanPush(entA, entB) then
                entA._ShouldCollideID = CurTime()
                ShouldCollideCache[id] = {compare = compare, when = CurTime()}
                return false
            end
        end
    end
end)

timer.Create("antiphyspush", 2, 0, function()
    for key, data in next, ShouldCollideCache do
        if (CurTime() - data.when) < 2 then
            ShouldCollideCache[key] = nil
        end
    end
end)

hook.Add("OnEntityCreated", "antiphyspush", function(ent)
    wait(function()
        if not IsValid(ent) then return end
        local ply = ( ent.CPPIGetOwner and ent:CPPIGetOwner() or ent:GetOwner() )
        local isWorld = (ent == Entity(0)) or ent:IsWorld()

        if ( IsPlayer(ply) and not isWorld ) and not ent.PushProtected then
            ent:SetCustomCollisionCheck(true)
            ent.PushProtected = true
        end
    end)
end)

hook.Add("KeyPress", "antiphyspush", function(ply, key)
    if ply and key == IN_ATTACK then
        ply._appHasInAttack = true
    end
end)

hook.Add("KeyRelease", "antiphyspush", function(ply, key) 
    if ply and key == IN_ATTACK then
        ply._appHasInAttack = nil
    end
end)

for _, hookTo in next, {"PhysgunPickup", "GravGunPunt"} do
    hook.Add(hookTo, "antiphyspush", function(ply, ent)
        local trace = ply:GetEyeTraceNoCursor()
        if not ply._appHasInAttack then return false end -- Attempted to pickup prop without pressing Attack Key.
        wait(function()
            if ( IsValid(ent) and NotWorld(ent) ) and ent:IsPlayerHolding() then
                if trace.Entity == ent then
                    ent.pickedby = ply
                end
            end
        end, 3)
    end)
end
