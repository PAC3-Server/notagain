local tag = "PCTask"
local PCTasks = {}
_G.PCTasks = PCTasks
PCTasks.Store = {}

local PCTasksFinish = "PC_TASK_FINISH"
local PCTasksSend   = "PC_TASK_SEND"

PCTasks.Exists = function(name)
    if PCTasks.Store[name] then
        return true
    else
        return false
    end
end

PCTasks.IsCompleted = function(ply,name)
    if not IsValid(ply) then return false end
    return ply:GetNWBool("PCTask_"..name,false)
end

if SERVER then

    util.AddNetworkString(PCTasksSend)
    util.AddNetworkString(PCTasksFinish)

    PCTasks.Send = function(ply)
        net.Start(PCTasksSend)
        net.WriteTable(PCTasks.Store)
        net.Send(ply)
        for name,_ in pairs(PCTasks.Store) do
            ply:SetNWBool("PCTask_"..name,ply:GetPData("PCTask_"..name,false))
        end
    end

    PCTasks.UpdateClients = function()
        for k,v in pairs(player.GetAll()) do
            if v.PCTasks_Init_Passed then
                PCTasks.Send(v)
            end
        end
    end

    PCTasks.Add = function(name,desc)
        if PCTasks.Exists(name) then return end
        local desc = desc or name
        PCTasks.Store[name] = desc
        PCTasks.UpdateClients() --realtime task additions
    end

    PCTasks.Complete = function(ply,name)
        if IsValid(ply) and PCTasks.Exists(name) and not PCTasks.IsCompleted(ply,name) then
            ply:SetPData("PCTask_"..name,true)
            ply:SetNWBool("PCTask_"..name,true)
            net.Start(PCTasksFinish)
            net.WriteEntity(ply)
            net.WriteString(name)
            net.Broadcast()
            hook.Run("OnPCTaskCompleted",ply,name)
        end
    end

    hook.Add("PlayerInitialSpawn",tag,function(ply)
        PCTasks.Send(ply)
        ply.PCTasks_Init_Passed = true
    end)

end


if CLIENT then

    net.Receive(PCTasksSend,function()
        local tbl = net.ReadTable()
        PCTasks.Store = tbl
    end)

    net.Receive(PCTasksFinish,function()
        local ply = net.ReadEntity()
        local name = net.ReadString()
        hook.Run("OnPCTaskCompleted",ply,name)
    end)

    hook.Add("OnPCTaskCompleted",tag,function(ply,task)
        if ply ~= LocalPlayer() then
            chat.AddText(ply,Color(200,200,200)," completed [",Color(244, 167, 66),task,Color(200,200,200),"]")
        else
            chat.AddText(team.GetColor(LocalPlayer():Team()),"You",Color(200,200,200)," completed [",Color(244, 167, 66),task,Color(200,200,200),"]")
        end
    end)
end

----------------------------------------------------------------------------
--[[PAC PCTasks]]--

local taskpac1 = "PC_TASKS_PAC_FIRST_TIME_OPENED"
if SERVER then
    util.AddNetworkString(taskpac1)

    PCTasks.Add("Open PAC Editor","Open the Player Appearance Customizer editor for the first time")

    net.Receive(taskpac1,function(len,ply)
        PCTasks.Complete(ply,"Open PAC Editor")
    end)
end

if CLIENT then
    timer.Create("task_pac_open_editor",1,0,function()
        if PCTasks.Exists("Open PAC Editor") and pace and pace.IsActive() then
            net.Start(taskpac1)
            net.SendToServer()
            timer.Remove("task_pac_open_editor")
        end
    end)
end
