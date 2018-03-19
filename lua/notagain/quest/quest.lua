local Tag = "Quest"
local Quest = {}
_G.Quest = Quest

--[[
This loads every quest script in "quest_core/quests/"
Returns void
]]--
Quest.Load = include("loader.lua")
Quest.Print = function(txt,isbad)
    local col = isbad and Color(200,100,0) or Color(0,100,200)
    MsgC(Color(255,255,255),"[",col,"Quest",Color(255,255,255),"] >> " .. txt)
end

include("npc.lua")

if CLIENT then
    include("main_panel.lua")
    
    surface.CreateFont("QuestDialogFont",{
        font = "Arial",
        extended = true,
        size = 18,
        weight = 600,
        antialias = true,
        italic = true,
        shadow = true,
        additive = true,
    })

    local width = ScrW() - 20
    local height = 100
    local xpos = 10
    local ypos = ScrH() - 110
    local textmargin = 5

    Quest.CurrentDialog = {
        Components = {},
        Authors = {},
        CurrentIndex = 1,
        CurrentChar = 1,
        Next = 0,
        Display = false,
        OnFinish = function() end,
    }

    local WordWrap = function(str,maxwidth)
        if not str then return "" end
        local lines    = {}
        local strlen   = string.len(str)
        local strstart = 1
        local strend   = 1

        while (strend < strlen) do
            strend = strend + 1
            local width,_ = surface.GetTextSize(string.sub(str,strstart,strend))

            if width and width > maxwidth then
                local n = string.sub(str,strend,strend)
                local I = 0

                for i = 1, 15 do
                    I = i

                    if (n ~= " " and n ~= "," and n ~= "." and n ~= "\n") then
                        strend = strend - 1
                        n = string.sub(str,strend,strend)
                    else
                        break
                    end
                end

                if (I == 15) then
                    strend = strend + 14
                end

                local finalstr = string.Trim(string.sub(str,strstart,strend))
                table.insert(lines,finalstr)
                strstart = strend + 1
            end
        end

        table.insert(lines,string.sub(str,strstart,strend))

        return table.concat(lines,"\n")
    end

    --[[
        Shows a panel with choices to the localplayer
            msg: The message to display
            title: The title of the panel
            choicex: The name of the choice
            callbackx: The callback to be executed for the choice corresponding
        Returns the query panel object
    ]]--
    Quest.Query = function(msg,title,choice1,callback1,choice2,callback2,choice3,callback3,choice4,callback4)
        local panel = Derma_Query(msg,title,choice1,callback1,choice2,callback2,choice3,callback3,choice4,callback4)
        panel.Paint = function(self,w,h)
            surface.SetDrawColor(0,0,0,200)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(0,0,0,220)
            surface.DrawRect(0,0,w,25)
            surface.SetDrawColor(100,100,100,255)
            surface.DrawOutlinedRect(0,0,w,h)
            surface.DrawLine(0,25,w,25)
        end
        for _,obj in pairs(panel:GetChildren()[6]:GetChildren()) do
            if obj:GetName() == "DButton" then
            obj:SetTextColor(Color(255,255,255))
                obj.Paint = function(self,w,h)
                    surface.SetDrawColor(75,75,75,200)
                    surface.DrawRect(0,0,w,h)
                    surface.SetDrawColor(200,200,200,255)
                    surface.DrawOutlinedRect(0,0,w,h)
                end
            end
        end

        return panel
    end

    local tblequals = function(tbl1,tbl2)
        for k,v in pairs(tbl1) do
            if tbl2[k] ~= v then
                return false
            end
        end

        return true
    end

    --[[
        Shows a RPGish dialog box on the localplayer screen
            components: A table of strings that compose the whole dialog
            onfinish: The function to be called on the dialog end
                signature is "void function()"
        Returns void
    ]]--
    Quest.ShowDialog = function(components,authors,onfinish)
        if Quest.CurrentDialog.Display and not tblequals(components,Quest.CurrentDialog.Components) then
            local inserteds = {}
            Quest.CurrentDialog.Components = Quest.CurrentDialog.Components or {}
            for _,str in pairs(components) do
                local wrapped = WordWrap(str,width - textmargin*2)
                local i = table.insert(Quest.CurrentDialog.Components,wrapped)
                table.insert(inserteds,i)
            end
            Quest.CurrentDialog.Authors = Quest.CurrentDialog.Authors or {}
            if type(authors) == "string" then
                for _,v in pairs(inserteds) do
                    Quest.CurrentDialog.Authors[v] = authors
                end
            else
                local i = 1
                for _,v in pairs(inserteds) do
                    Quest.CurrentDialog.Authors[v] = authors[i]
                    i = i + 1
                end
            end
        else
            Quest.CurrentDialog.Components = {}
            for _,str in pairs(components) do
                local wrapped = WordWrap(str,width - textmargin*2)
                table.insert(Quest.CurrentDialog.Components,wrapped)
            end
            Quest.CurrentDialog.Authors = {}
            if type(authors) == "string" then
                for k,_ in pairs(Quest.CurrentDialog.Components) do
                    table.insert(Quest.CurrentDialog.Authors,k,authors)
                end
            else
                Quest.CurrentDialog.Authors = authors
            end
            Quest.CurrentDialog.CurrentIndex = 1
            Quest.CurrentDialog.CurrentChar = 1
            Quest.CurrentDialog.Display = true
            Quest.Next = CurTime() + 1
        end
        Quest.CurrentDialog.OnFinish = onfinish
    end

    net.Receive("QUEST_DIALOG",function()
        local comps = net.ReadTable()
        local authors = net.ReadTable()
        local i = net.ReadInt(32)
        Quest.ShowDialog(comps,authors,function()
            net.Start("QUEST_DIALOG")
            net.WriteInt(i,32)
            net.SendToServer()
        end)
    end)

    local fix = 0
    --[[
        Called on each call of KeyRelease hook
            ply: The player that released the key (Always localplayer)
            key: A key enum corresponding to the key released
        Returns void
    ]]--
    local OnKeyRelease = function(ply,key)
        if Quest.CurrentDialog.Display then
            if key == IN_ATTACK or key == IN_USE then
                fix = fix + 1
                if fix > 2 and CurTime() > Quest.CurrentDialog.Next then
                    Quest.CurrentDialog.CurrentIndex = Quest.CurrentDialog.CurrentIndex + 1
                    Quest.CurrentDialog.CurrentChar = 1
                    Quest.CurrentDialog.Next = CurTime() + 1
                    fix = 0
                end
            end
        end
    end

    local blockeds =
    {
        ["CHudHealth"] = true,
	    ["CHudBattery"] = true,
        ["CHudAmmo"] = true,
    }
    --[[
        Called on each call of HUDShouldDraw hook
            element: The hud element name
        Returns false if internal conditions are met
    ]]--
    local OnShouldDraw = function(element)
        if Quest.CurrentDialog.Display and blockeds[element] then
            return false
        end
    end

    --[[
        Called on each call of HUDPaint hook
        Returns void
    ]]--
    local OnPaint = function()
        if Quest.CurrentDialog.Display then
            surface.SetDrawColor(0,0,0,200)
            surface.DrawRect(xpos,ypos,width,height)
            surface.SetDrawColor(100,100,100,200)
            surface.DrawOutlinedRect(xpos,ypos,width,height)
            surface.SetTextColor(Color(255,255,255))
            surface.SetFont("QuestDialogFont")
            local display = "Press MOUSE1 or USE to continue"
            local x,y = surface.GetTextSize(display)
            surface.SetTextPos(width - x, ypos - y - textmargin)
            surface.DrawText(display)
            local cur = Quest.CurrentDialog.Components[Quest.CurrentDialog.CurrentIndex]
            if not cur then
                Quest.CurrentDialog.Display = false
                local s,e = Quest.CurrentDialog and pcall(Quest.CurrentDialog.OnFinish) or true,nil
                if not s then
                    Quest.Print("The current dialog OnFinish method generated an error:\n" .. e,true)
                end
            else
                Quest.CurrentDialog.CurrentChar = Quest.CurrentDialog.CurrentChar + 1
                local authors = Quest.CurrentDialog.Authors or {} --Dunno why but this can be nil
                local author = authors[Quest.CurrentDialog.CurrentIndex]
                if author then
                    local ax,ay = surface.GetTextSize(author)
                    local x,y = xpos + 30,ypos - 25
                    local w,h = ax + 20,26
                    surface.SetDrawColor(0,0,0,200)
                    surface.DrawRect(x,y,w,h)
                    surface.SetDrawColor(100,100,100,200)
                    surface.DrawOutlinedRect(x,y,w,h)
                    surface.SetTextPos(x + 10,y + 5)
                    surface.DrawText(author)
                end
                for k,v in pairs(string.Explode("\n",string.sub(cur,1,Quest.CurrentDialog.CurrentChar))) do
                    local i = ypos + textmargin + ((k - 1) * 15)
                    surface.SetTextPos(xpos + textmargin, i)
                    surface.DrawText(v)
                end
            end
        end
    end

    hook.Add("KeyRelease",Tag,OnKeyRelease)
    hook.Add("PostDrawHUD",Tag,OnPaint)
    hook.Add("HUDShouldDraw",Tag,OnShouldDraw)
end

if SERVER then
    AddCSLuaFile("main_panel.lua")
    
    local questctor = include("ctor.lua")

    util.AddNetworkString("QUEST_DIALOG")

    Quest.Quests = {}
    Quest.Count = 0
    Quest.EntityRespawnDelay = 30
    Quest.ActiveQuest = questctor()

    --[[
    Creates a quest object and registers it
        name: The name of the quest
        printname: The name that will be used for this quest in UIs
        description: The quest description to be displayed in UIs
        onstart: The callback to be executed on completion of the quest. Signature is "void function(Player ply)"
        onfinish: The callback to be executed on completion of the quest. Signature is "void function(Player ply)"
    Returns a new quest table corresponding to arguments passed
    ]]--
    Quest.CreateQuest = function(name,printname,description,onstart,onfinish)
        local quest = questctor(name,printname,description,onstart,onfinish)
        Quest.Quests[name] = quest
        Quest.Count = Quest.Count + 1

        return quest
    end

    local receivers = {}
    local rcallbacks = {}
    Quest.ShowDialog = function(ply,components,authors,onfinish)
        net.Start("QUEST_DIALOG")
        net.WriteTable(components)
        authors = authors or {}
        if type(authors) == "string" then
            local t = {}
            for k,_ in pairs(components) do
                t[k] = authors
            end
            net.WriteTable(t)
        else
            net.WriteTable(authors)
        end

        onfinish = onfinish or function() end
        if rcallbacks[onfinish] then
            net.WriteInt(rcallbacks[onfinish],32)
        else
            local i = table.insert(receivers,onfinish)
            rcallbacks[onfinish] = i
            net.WriteInt(i,32)
        end
        net.Send(ply)
    end

    net.Receive("QUEST_DIALOG",function(_,ply)
        local i = net.ReadInt(32)
        local s,e = pcall(receivers[i],ply)
        if not s then
            Quest.Print("Dialog[" .. i .."] OnFinish method generated error:\n" ..
                e .. "\n /!\\ This method is now faulted and wont be ran anymore /!\\",true)
            receivers[i] = function() end
        end
    end)

    --[[
    Sets the passed quest as active quest
        quest: The quest table to set as active
    Returns void
    ]]--
    Quest.SetActiveQuest = function(quest)
        for _,ent in pairs(Quest.ActiveQuest.Entities) do
            if ent:IsSpawned() then
                ent.Instance.IsQuestEntity = false
                ent.Instance:Remove()
            end
        end
        Quest.ActiveQuest = quest
        for _,ent in pairs(Quest.ActiveQuest.Entities) do
            Quest.ActiveQuest:SpawnEntity(ent)
        end
    end

    --[[
    Called when a player disconnects
        ply: The player entity disconnecting
    Returns void
    ]]--
    local OnDisconnect = function(ply)
        if Quest.ActiveQuest.Players[ply] then
            Quest.ActiveQuest:RemovePlayer(ply)
        end
    end

    --[[
    Called each time Think hook is fired
    Returns void
    ]]--
    local OnThink = function()
        local active = Quest.ActiveQuest
        for ply,state in pairs(active.Players) do
            if ply:IsValid() then
                local finished = #active.Tasks > 0 and active.Tasks[state]:Execute(ply)
                finished = finished == nil and true or finished
                if finished then
                    local nextstate = state + 1
                    active.Players[ply] = nextstate
                    if nextstate > #active.Tasks then
                        local s,e = active.OnFinish and pcall(active.OnFinish,ply) or true,nil
                        if s then
                            active:RemovePlayer(ply)
                            active:SetBlacklist(ply)
                            local name = _G.UndecorateNick and (_G.UndecorateNick(ply:Nick())) or ply:Nick()
                            Quest.Print(name .. "[" .. ply:SteamID() .. "] completed quest <" .. active.PrintName .. ">")
                        else
                            Quest.Print("Quest[" .. active.PrintName .. "] OnFinish method generated error:\n" ..
                                e .. "\n /!\\ This method is now faulted and wont be ran anymore /!\\",true)
                            active.OnFinish = function() end -- Remove the function so it doesnt spam errors
                        end
                    end
                end
            end
        end
    end

    --[[
    Essentially spawns the npc giving the daily quest
    Returns void
    ]]--
    local OnInitPostEntity = function()
        local spanwpoint = Vector (1270.031616,-929.007080,128.031250)
        local angles = Angle(0,-90,0)

        local ent = ents.Create("lua_npc_quest")
        ent:SetPos(spanwpoint)
        ent:SetAngles(angles)
        ent:Spawn()
        --ent:StartActivity(ACT_IDLE)
    end

    hook.Add("PlayerDisconnected",Tag,OnDisconnect)
    hook.Add("PlayerConnect",Tag,OnConnect)
    hook.Add("Think",Tag,OnThink)
    hook.Add("InitPostEntity",Tag,OnInitPostEntity)
end

--[[
This is called on quest initialization
Returns void
]]--
local OnInitialize = function()
    Quest.Load()
    if SERVER then
        if Quest.Count > 0 then
            local index = math.random(1,Quest.Count)
            Quest.SetActiveQuest(Quest.Quests[index])
        end
    end
end

hook.Add("Initialize",Tag,OnInitialize)

return Quest
