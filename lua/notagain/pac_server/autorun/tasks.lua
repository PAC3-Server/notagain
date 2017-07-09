local tag = "Task"
local Tasks = {}
_G.Tasks = Tasks
Tasks.Store = {}

local taskfinish = "TASK_FINISH"
local tasksend   = "TASK_SEND"

Tasks.Exists = function(name)
    if Tasks.Store[name] then
        return true
    else
        return false
    end
end

Tasks.IsCompleted = function(ply,name)
    if not IsValid(ply) then return false end
    return ply:GetNWBool("Task_"..name,false)
end

if SERVER then

    util.AddNetworkString(tasksend)
    util.AddNetworkString(taskfinish)

    Tasks.InitPassed = false

    Tasks.Send = function(ply)
        net.Start(tasksend)
        net.WriteTable(Tasks.Store)
        net.Send(ply)
        for name,_ in pairs(Tasks.Store) do
            ply:SetNWBool("Task_"..name,ply:GetPData("Task_"..name,false))
        end
    end

    Tasks.UpdateClients = function()
        for k,v in pairs(player.GetAll()) do
            if v.Tasks_Init_Passed then
                Tasks.Send(v)
            end
        end
    end

    Tasks.Add = function(name,desc)
        if Tasks.Exists(name) then return end
        local desc = desc or name
        Tasks.Store[name] = desc
        Tasks.UpdateClients() --realtime task additions
    end

    Tasks.Complete = function(ply,name)
        if IsValid(ply) and Tasks.Exists(name) and not Tasks.IsCompleted(ply,name) then
            ply:SetPData("Task_"..name,true)
            ply:SetNWBool("Task_"..name,true)
            net.Start(taskfinish)
            net.WriteEntity(ply)
            net.WriteString(name)
            net.Broadcast()
            hook.Run("OnTaskCompleted",ply,name)
        end
    end

    hook.Add("PlayerInitialSpawn",tag,function(ply)
        Tasks.Send(ply)
        ply.Tasks_Init_Passed = true
    end)

end


if CLIENT then

    net.Receive(tasksend,function()
        local tbl = net.ReadTable()
        Tasks.Store = tbl
    end)

    net.Receive(taskfinish,function()
        local ply = net.ReadEntity()
        local name = net.ReadString()
        hook.Run("OnTaskCompleted",ply,name)
    end)

    hook.Add("OnTaskCompleted",tag,function(ply,task)
        if ply ~= LocalPlayer() then
            chat.AddText(ply,Color(200,200,200)," completed [",Color(244, 167, 66),task,Color(200,200,200),"]")
        else
            chat.AddText(team.GetColor(LocalPlayer():Team()),"You",Color(200,200,200)," completed [",Color(244, 167, 66),task,Color(200,200,200),"]")
        end
    end)
end

----------------------------------------------------------------------------
--[[PAC Tasks]]--

local taskpac1 = "TASKS_PAC_FIRST_TIME_OPENED"
if SERVER then
    util.AddNetworkString(taskpac1)

    Tasks.Add("Open PAC Editor","Open the Player Appearance Customizer editor for the first time")

    net.Receive(taskpac1,function(len,ply)
        Tasks.Complete(ply,"Open PAC Editor")
    end)
end

if CLIENT then
    hook.Add("Think","task_pac_open_editor",function()
        if Tasks.Exists("Open PAC Editor") and not Tasks.IsCompleted(LocalPlayer(),"Open PAC Editor") and pace and pace.IsActive() then
            net.Start(taskpac1)
            net.SendToServer()
            hook.Remove("Think","task_pac_open_editor")
        end
    end)
end
