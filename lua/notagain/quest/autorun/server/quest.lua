if not SERVER then return end

local taskctor = include("quest_core/server/quest_task.lua")
local entctor = include("quest_core/server/quest_entity.lua")

local quest = {
    --[[
    Adds a player to a quest
        quest: The quest table to add the player to
        ply: The player to add
    Returns void
    ]]--
    AddPlayer = function(quest,ply)
        if quest.Blacklist[ply:SteamID()] then return end
        if not quest.Players[ply] then
            quest.Players[ply] = 1
            local s,e = quest.OnStart and pcall(quest.OnStart,ply) or true,nil
            if not s then
                Quest.Print("Quest[" .. quest.PrintName .. "] OnStart method generated error:\n" ..
                    e .. "\n /!\\ This method is now faulted and wont be ran anymore /!\\",true)
                quest.OnFinish = function() end --No more errors here
            end
        end
    end,

    --[[
    Removes a player from a quest
        quest: The quest table to add the player to
        ply: The player to add
    Returns void
    ]]--
    RemovePlayer = function(quest,ply)
        if quest.Players[ply] then
            quest.Players[ply] = nil
        end
    end,

    --[[
    Blacklists a player from a quest
        quest: The quest to blacklist the player from
        ply: The player to blacklist
    Returns void
    ]]--
    SetBlacklist = function(quest,ply)
        if not quest.Blacklist[ply:SteamID()] then
            quest.Blacklist[ply:SteamID()] = true
        end
    end,

    --[[
    Creates a task table and assign it to the quest specified
        quest: The quest to assign this task to
        printname: The name of the task to be displayed in UIs
        description: The description of the task to be displayed in UIs
        onrun: A function of signature "bool function(Player ply)"
            where bool indicates wether or not the task has been completed by the player
        onstart: A function of signature "void function(ply)" that will be run on start of the task
        onfinish: A function of signature "void function(ply)" that will be run on end of the task
    Returns a new task table corresponding to arguments passed
    ]]--
    AddTask = function(quest,printname,description,onrun,onstart,onfinish)
        local t = taskctor(quest,printname,description,onrun,onstart,onfinish)
        table.insert(quest.Tasks,t)

        return t
    end,

    --[[
    A wrapper around Quest.AddTask that adds a task to the specified quest,
    the player should reach the specified pos to complete the task
        quest: The quest to assign this task to
        locname: The location name that will be used in UIs
        locpos: The position to be reached to complete the task
        onstart: A function of signature "void function(ply)" that will be run on start of the task
        onfinish: A function of signature "void function(ply)" that will be run on end of the task
    Returns a new task table
    ]]--
    AddLocationTask = function(quest,locname,locpos,onstart,onfinish)
        local t = quest:AddTask("Reach " .. locname,"Go and find the place called \"" .. locname .. "\"!",
        function(ply)
            return ply:GetPos():Distance(locpos) < 150
        end,onstart,onfinish)

        return t
    end,

    --[[
    A wrapper around Quest.AddTask that adds a task to the specified quest,
    the player should talk to a specified entity to complete the task
        quest: The quest to assign this task to
        entprintname: The entity name that will be used in UIs
        entname: The entity name that was used to add the entity to the quest
        ent: The entity to talk to complete the task
        onstart: A function of signature "void function(ply)" that will be run on start of the task
        onfinish: A function of signature "void function(ply)" that will be run on end of the task
    Returns a new task table
    ]]--
    AddUseTask = function(quest,entprintname,entname,onstart,onfinish)
        local t = quest:AddTask(entprintname,"Interact with " .. entprintname,
        function(ply)
            return quest.Entities[entname].Interacted[ply]
        end,onstart,onfinish)

        return t
    end,

    --[[
    A wrapper around Quest.AddTask that adds a task to the specified quest,
    the player should kill a specified entity to complete the task
        quest: The quest to assign this task to
        entprintname: The entity name that will be used in UIs
        entname: The entity name that was used to add the entity to the quest
        ent: The entity to kill complete the task
        onstart: A function of signature "void function(ply)" that will be run on start of the task
        onfinish: A function of signature "void function(ply)" that will be run on end of the task
    Returns a new task table
    ]]--
    AddKillTask = function(quest,entprintname,entname,onstart,onfinish)
        local t = quest:AddTask(entprintname,"Get rid of " .. entprintname,
        function(ply)
            return quest.Entities[entname].Killed[ply]
        end,onstart,onfinish)

        return t
    end,

    --[[
    Add an entity to a quest so it can be used in tasks
        quest: The quest table to assign the entity to
        name: String, The name of the entity
        class: String, The class that the entity should have
        model: String, The model that the entity should have
        isnpc: Boolean, Is the entity a npc?
        spawnpoint: Vector, The position at which the entity spawns
        onuse: void function(Player ply), The function that will
            be fired when a player press use on the entity
    Returns the entity table created
    ]]--
    AddEntity = function(quest,name,class,model,isnpc,spawnpoint,onuse)
        local ent = entctor(quest,name,class,model,isnpc,spawnpoint,onuse)
        quest.Entities[name] = ent

        return ent
    end,

    --[[
    Spawns a quest entity according to the ent table passed
        ent: The quest entity table
    Returns the newly created instance of the quest entity
    ]]--
    SpawnEntity = function(quest,name)
        local ent = quest.Entities[name]
        if not ent then return NULL end

        return ent:Spawn()
    end,
}

quest.__index = quest

return function(name,printname,description,onstart,onfinish)
    return setmetatable({
        Name = name or "Undefined",
        PrintName = printname or "Undefined",
        Description = description or "Undefined",
        OnStart = onstart or function(ply) end,
        OnFinish = onfinish or function(ply) end,
        Tasks = {},
        Entities = {},
        Players = {},
        Blacklist = {},
    },quest)
end