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

PCTasks.GetCompleted = function(ply) 
    local results = {} 
    if not IsValid(ply) then return results end
    for k,v in pairs(PCTasks.Store) do 
        if ply:GetNWBool("PCTask_"..k) then 
            results[k] = v 
        end 
    end 
    return results 
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

    PCTasks.Add = function(name,desc,xp)
        if PCTasks.Exists(name) then return end
        local desc = desc or name
        local xp = xp or 1000
        PCTasks.Store[name] = {}
        PCTasks.Store[name].desc = desc
        PCTasks.Store[name].XP = xp
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
            if jlevel then
                jlevel.GiveXP(ply,PCTasks.Store[name].XP)
            end
        end
    end

    hook.Add("PlayerInitialSpawn","pctasks",function(ply)
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

    hook.Add("OnPCTaskCompleted","pctasks",function(ply,task)
        if ply ~= LocalPlayer() then
            chat.AddText(ply,Color(200,200,200)," completed [",Color(244, 167, 66),task,Color(200,200,200),"]")
        else
            chat.AddText(team.GetColor(LocalPlayer():Team()),"You",Color(200,200,200)," completed [",Color(244, 167, 66),task,Color(200,200,200),"]")
        end
    end)
end

----------------------------------------------------------------------------
--[[PCTasks]]--

local taskpac1 = "PC_TASKS_PAC_FIRST_TIME_OPENED"
local tasklag  = "PC_TASKS_LAG"
local taskownrisks = "PC_TASKS_OWN_RISKS"
local taskosx = "PC_TASKS_OSX"
local tasklinux = "PC_TASKS_LINUX"

if SERVER then
    util.AddNetworkString(taskpac1)
    util.AddNetworkString(tasklag)
    util.AddNetworkString(taskownrisks)
    util.AddNetworkString(taskosx)
    util.AddNetworkString(tasklinux)

    PCTasks.Add("An important discovery","Open the Player Appearance Customizer editor for the first time",150)
    PCTasks.Add("What a PAC","Wear an outfit made with PAC",200)
    PCTasks.Add("Faster than light","Break the laws of physics",500)
    PCTasks.Add("Bad example","Watch someone get throwed out of the server",3000)
    PCTasks.Add("Otherworld","Have a look from the otherworld",1000)
    PCTasks.Add("Better than RPGS","Activate the RPG mode",500)
    PCTasks.Add("Infinite power","Cheat in RPG mode",1000)
    PCTasks.Add("Murderer","Be a murderer",120)
    PCTasks.Add("First words","Communicate with the world",50)
    PCTasks.Add("Slower than my old windows 2000","Experience huge server lag",300)
    PCTasks.Add("Distracted","Be AFK on the server",100)
    PCTasks.Add("A message from the stars","Communicate with the 'stars'",300)
    PCTasks.Add("At your own risks","Run GMod on low battery power",5000)
    PCTasks.Add("Apple time","Run GMod on OSX",1000)
    PCTasks.Add("Hipster","Run GMod on Linux",1000)
    PCTasks.Add("Friendly neighbourhood","Play with 4 friends on the server",1200)

    net.Receive(taskpac1,function(len,ply)
        PCTasks.Complete(ply,"An important discovery")
    end)

    net.Receive(tasklag,function(len,ply)
        PCTasks.Complete(ply,"Slower than my old windows 2000")
    end)

    net.Receive(taskownrisks,function(len,ply)
        PCTasks.Complete(ply,"At your own risks")
    end)

    net.Receive(taskosx,function(len,ply)
        PCTasks.Complete(ply,"Apple time")
    end)

    net.Receive(tasklinux,function(len,ply)
        PCTasks.Complete(ply,"Hipster")
    end)

    hook.Add("PrePACConfigApply","pc_task_pac_wore_first_time",function(ply)
        PCTasks.Complete(ply,"What a PAC")
    end)

    hook.Add("Move","pc_task_faster_than_light",function(ply)
        if ply:GetVelocity():Length() >= 2000 then
            PCTasks.Complete(ply,"Faster than light")
        end
    end)

    hook.Add("AowlCommand","pc_task_notice_kickban",function(_,type,_,_)
        if type == "kick" or type == "ban" then
            for k,v in pairs(player.GetAll()) do
                PCTasks.Complete(v,"Bad example")
            end
        end
    end)

    hook.Add("PlayerDeath","pc_task_otherworld",function(ply,_,ent)
        if ply:GetNWBool("jrpg",false) then
            PCTasks.Complete(ply,"Otherworld")
        end
        if ent:IsPlayer() and ent ~= ply then
            PCTasks.Complete(ent,"Murderer")
        end
    end)

    hook.Add("OnRPGEnabled","pc_task_better_than_rpgs",function(ply,cheat)
        PCTasks.Complete(ply,"Better than RPGS")
        if cheat then
            PCTasks.Complete(ply,"Infinite power")
        end
    end)

    hook.Add("PlayerSay","pc_task_first_words",function(ply)
        PCTasks.Complete(ply,"First words")
    end)

    hook.Add("OnPlayerAFK","pc_task_distracted",function(ply,state)
        if not state then
            PCTasks.Complete(ply,"Distracted")
        end
    end)

    hook.Add("DiscordRelayMessage","pc_task_message_from_the_stars",function(input)
        for k,v in pairs(player.GetAll()) do
            PCTasks.Complete(v,"A message from the stars")
        end
    end)

end

if CLIENT then
    local system_BatteryPower = system.BatteryPower
    local system_IsLinux      = system.IsLinux
    local system_IsOSX        = system.IsOSX

    if not PCTasks.IsCompleted(LocalPlayer(),"An important discovery") then
        hook.Add("PrePACEditorOpen","pc_task_pac_editor_first_time",function()
            net.Start(taskpac1)
            net.SendToServer()
            hook.Remove("PrePACEditorOpen","pc_task_pac_editor_first_time")
        end)
    end

    if not PCTasks.IsCompleted(LocalPlayer(),"Slower than my old windows 2000") then
        hook.Add("Think","pc_task_lag",function()
            if ( 1/RealFrameTime() ) < 10 and system.HasFocus() then
                net.Start(tasklag)
                net.SendToServer()
                hook.Remove("Think","pc_task_lag")
            end
        end)
    end

    if not PCTasks.IsCompleted(LocalPlayer(),"At your own risks") then
        timer.Create("pc_task_at_your_own_risks",60,0,function()
            if system_BatteryPower() <= 20 then
                net.Start(taskownrisks)
                net.SendToServer()
                timer.Remove("pc_task_at_your_own_risks")
            end
        end)
    end

    hook.Add("InitPostEntity","pc_task_os",function()
        if system_IsLinux() then
            net.Start(tasklinux)
            net.SendToServer()
        elseif system_IsOSX() then
            net.Start(taskosx)
            net.SendToServer()
        end
    end)
end
