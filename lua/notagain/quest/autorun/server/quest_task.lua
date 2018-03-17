if not SERVER then return end

local task = {
    Execute = function(task,ply)
        if task.IsFaulted then return true end

        if not task.Started[ply:SteamID()] then
            local s,e = task.OnStart and pcall(task.OnStart,ply) or true,nil
            if not s then
                task.IsFaulted = true
                Quest.Print("Task[" .. task.Name .. "] OnStart method generated error:\n" ..
                    e .. "\n /!\\ This task is now faulted and wont be ran anymore /!\\",true)
                return true
            end
            task.Started[ply:SteamID()] = true
        end

        local s,ret = pcall(task.OnRun,ply)
        if not s then
            task.IsFaulted = true
            Quest.Print("Task[" .. task.Name .. "] OnRun method generated error:\n" ..
                ret .. "\n /!\\ This task is now faulted and wont be ran anymore /!\\",true)
            return true
        else
            ret = ret ~= nil and ret or false
            if ret then
                local s,e = task.OnFinish and pcall(task.OnFinish,ply) or true,nil
                if not s then
                    task.IsFaulted = true
                    Quest.Print("Task[" .. task.Name .. "] OnFinish method generated error:\n" ..
                        e .. "\n /!\\ This task is now faulted and wont be ran anymore /!\\",true)
                    return true
                else
                    return ret
                end
            else
                return false
            end
        end
    end
}

task.__index = task

return function(quest,printname,description,onrun,onstart,onfinish)
    return setmetatable({
        Started = {},
        Quest = quest.Name or "Undefined",
        Name = printname or "Undefined",
        Description = description or "Undefined",
        OnStart = onstart or function(ply) end,
        OnFinish = onfinish or function(ply) end,
        OnRun = onrun or function(ply) return true end,
        IsFaulted = false,
    },task)
end
