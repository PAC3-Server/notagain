if not SERVER then end
local Tag = "Quest"

local entity = {
    IsSpawned = function(ent)
        return ent.Instance:IsValid()
    end,
    Spawn = function(ent)
        if ent:IsSpawned() then
            ent.Instance.IsQuestEntity = false
            ent.Instance:Remove()
        end

        local inst = ents.Create(ent.Class)
        inst:SetModel(ent.Model)
        inst:SetPos(ent.SpawnPosition)
        inst:Spawn()
        inst.IsQuestEntity = true
        inst.QuestEntityName = ent.Name
        ent.Instance = inst

        return inst
    end,
}

entity.__index = entity

--[[
Called on KeyPress hook
    ply: The player pressing the key
    ent: They key being pressed
Returns void
]]--
local OnKeyPress = function(ply,key)
    if key == IN_USE then
        local tr = util.TraceLine({
            start = ply:EyePos(),
            endpos = ply:EyePos() + ply:EyeAngles():Forward() * 100,
            filter = function(ent)
                if ent.IsQuestEntity then
                    return true
                end
            end
        })

        if tr.Entity:IsValid() then
            local active = Quest.ActiveQuest
            if active.Players[ply] then
                local qent = active.Entities[tr.Entity.QuestEntityName]
                local s,e = pcall(qent.OnUse,ply)
                if not s then
                    Quest.Print("Entity[" .. qent.Name .. "] OnUse method generated error:\n" ..
                        e .. "\n /!\\ This method is now faulted and wont be ran anymore /!\\",true)
                    qent.OnUse = function() end
                end
                qent.Interacted[ply] = true
            end
        end
    end
end

--[[
Called on EntityRemoved hook
    ent: The ent being removed
Returns void
]]--
local OnEntityRemoved = function(ent)
    if ent.IsQuestEntity then
        local qname = Quest.ActiveQuest.Name
        local active = Quest.ActiveQuest
        local qent = active.Entities[ent.QuestEntityName]
        timer.Simple(Quest.EntityRespawnDelay,function()
            if active.Name == qname then
                Quest.SpawnEntity(qent)
            end
        end)
    end
end

--[[
Called OnNPCKilled hook
    npc: The NPC being killed
    attacker: The attacker
    inflictor: The inflictor
Returns void
]]--
local OnNPCKilled = function(npc,attacker,inflictor)
    if not attacker:IsPlayer() then return end
    local active = Quest.ActiveQuest
    if npc.IsQuestEntity and active.Players[attacker] then
        local qent = active.Entities[npc.QuestEntityName]
        qent.Killed[attacker] = true
    end
end

hook.Add("KeyPress",Tag,OnKeyPress)
hook.Add("EntityRemoved",Tag,OnEntityRemoved)
hook.Add("OnNPCKilled",Tag,OnNPCKilled)

return function(quest,name,class,model,isnpc,spawnpoint,onuse)
    return setmetatable({
        Name = name or "Undefined",
        Class = class or "prop_physics",
        Model = model or "",
        OnUse = onuse or function(ply) end,
        IsNPC = isnpc or false,
        SpawnPosition = spawnpoint or Vector(0,0,0),
        Instance = NULL,
        Interacted = {},
        Killed = {},
    },entity)
end