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

hook.Add( "KeyPress", "antiphyspush", function( ply, key )
    if IsValid(ply) and key == IN_ATTACK then
        ply._appHasInAttack = true
    end
end)

for _, hookTo in next, {"PhysgunPickup", "GravGunPunt"} do
    hook.Add(hookTo, "antiphyspush", function(ply, ent)
        local trace = ply:GetEyeTraceNoCursor()
        wait(function()
            if ( IsValid(ent) and ply._appHasInAttack and NotWorld(ent) ) and ent:IsPlayerHolding() then
                if trace.Entity == ent then
                    ent.pickedby = ply
                end
            end
            ply._appHasInAttack = nil
        end, 3)
    end)
end

hook.Add("OnEntityCreated", "antiphyspush", function(ent)
    wait(function()
        if not IsValid(ent) then return end
        local ply = ( ent.CPPIGetOwner and ent:CPPIGetOwner() or ent:GetOwner() )
        local isWorld = (ent == Entity(0)) or ent:IsWorld()

        if ( IsPlayer(ply) and not isWorld ) and not ent.PushProtected then
            ent:AddCallback('PhysicsCollide', function(ent, data)
                if ent.IsPushing then
                    data.PhysObject:Sleep()
                    data.PhysObject:EnableMotion(false)
                    return
                end

                local ply = data.HitEntity

                local canMove = IsValid(data.PhysObject) and data.PhysObject:IsMotionEnabled() or false
                local cantAlter = ( not CanPush(ent, ply) )

                if NotWorld(ply) and ( canMove and cantAlter ) then
                    local picker = ent.pickedby
                    local pos = ply:GetPos()

                    ent.IsPushing = true

                    if picker and IsPlayer(ply) and tobool( ply:GetInfo("cl_godmode_reflect") ) then
                        picker:SetMoveType(MOVETYPE_WALK)
                        picker:SetVelocity((data.OurOldVelocity*-1) + data.HitNormal*-600)
                    end

                    ent:SetPos(ent:GetPos())

                    data.HitObject:SetVelocityInstantaneous(data.HitObject:GetVelocity()*-1)
                    data.HitObject:AddAngleVelocity(data.HitObject:GetAngleVelocity()*-1)
                    data.HitObject:Sleep()

                    data.PhysObject:Sleep()
                    data.PhysObject:EnableMotion(false)
                    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

                    wait(function()
                        if IsValid(ply) then
                            ply:SetVelocity(ply:GetVelocity()*-1)
                            ply:SetPos(pos)
                        end
                        if IsValid(ent) and ent.IsPushing then
                            ent.IsPushing = nil
                        end
                    end, 2)
                end

                return false
            end)

            ent.PushProtected = true
        end
    end)
end)
