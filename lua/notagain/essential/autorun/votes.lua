local votes = _G.votes or {}
_G.votes = votes

local tag         = "votes"
local netcreate   = "VOTES_CREATE"
local netend      = "VOTES_END"
local netplvote   = "VOTES_PLY_VOTE"
local netplunvote = "VOTES_PLY_UNVOTE"

if SERVER then

    util.AddNetworkString(netcreate)
    util.AddNetworkString(netend)
    util.AddNetworkString(netplvote)
    util.AddNetworkString(netplunvote)

    votes.ActiveVote = {}

    votes.IsOnGoing = function()
        if votes.ActiveVote.Question then
            return true
        else
            return false
        end
    end

    votes.Create = function(title,delay,choices,callback)
        local choices = choices or {}
        if votes.IsOnGoing() or not title or #choices < 2 then return end
        votes.ActiveVote = {}
        votes.ActiveVote.Question = title
        votes.ActiveVote.Duration = CurTime() + delay
        votes.ActiveVote.Choices = {}
        for _,v in pairs(choices) do
            votes.ActiveVote.Choices[v] = {}
        end
        net.Start(netcreate)
        net.WriteTable(votes.ActiveVote)
        net.Broadcast()
        votes.ActiveVote.Callback = callback or (function() end)
    end

    local PLAYER = FindMetaTable("Player")
    local plyvotes = {}
    votes.PlayerVote = function(ply,choice)
        if not IsValid(ply) or not votes.ActiveVote.Choices[choice] or plyvotes[ply:SteamID()] then return end
        votes.ActiveVote.Choices[choice][ply:SteamID()] = ply
        plyvotes[ply:SteamID()] = choice
        net.Start(netplvote)
        net.WriteEntity(ply)
        net.WriteString(choice)
        net.Broadcast()
    end
    PLAYER.Vote = votes.PlayerVote

    votes.PlayerUnVote = function(ply)
        if not IsValid(ply) or not plyvotes[ply:SteamID()] then return end
        local choice = plyvotes[ply:SteamID()]
        net.Start(netplunvote)
        net.WriteEntity(ply)
        net.WriteString(choice)
        net.Broadcast()
        votes.ActiveVote.Choices[choice][ply:SteamID()] = nil
        plyvotes[ply:SteamID()] = nil
    end
    PLAYER.UnVote = votes.PlayerUnVote

    local GetMost = function()
        local most = 0
        local results = {}
        for _,v in pairs(votes.ActiveVote.Choices) do
            local count = table.Count(v)
            if count > most then
                most = count
            end
        end
        for k,v in pairs(votes.ActiveVote.Choices) do
            if table.Count(v) == most then
                table.insert(results,k)
            end
        end
        return results
    end

    votes.End = function()
        if not votes.IsOnGoing() then return end
        net.Start(netend)
        net.WriteTable(GetMost())
        net.Broadcast()
        votes.ActiveVote.Callback(GetMost())
        votes.ActiveVote = {}
        plyvotes = {}
    end

    hook.Add("Think",tag,function()
        if not votes.IsOnGoing() then return end
        if CurTime() >= votes.ActiveVote.Duration then
            votes.End()
        end
    end)

    hook.Add("PlayerButtonUp",tag,function(ply,btn)
        --print(ply,btn)
        if not votes.IsOnGoing() then return end
        if plyvotes[ply:SteamID()] then
            ply:UnVote()
        else
            if btn > 0 and btn <= 10 then
                local choice = btn - 1
                local i = 1
                for k,v in pairs(votes.ActiveVote.Choices) do
                    if i == choice then
                        ply:Vote(k)
                        break
                    end
                    i = i + 1
                end
            end
        end
    end)

end

if CLIENT then
    local voteui = {

        Init = function(self)
            self.Question = ""
            self.Choices = {}
            self.ChoiceColors = {}
            self.Duration = 0
            self:SetWide(300)
            self:SetPos(ScrW()-300,ScrH()/2-100)
            self:SetTitle("")
            self:ShowCloseButton(false)
        end,

        Paint = function(self,w,h)
            surface.SetDrawColor(62,62,62,173)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(104,104,104,103)
            surface.DrawOutlinedRect(0,0,w,h)

            surface.SetTextColor(255,255,255)
            surface.SetFont("DermaDefault")
            local x,y = surface.GetTextSize(self.Question)
            surface.SetTextPos(w/2-x/2,5)
            surface.DrawText(self.Question)

            local i = 1
            for k,v in pairs(self.Choices) do
                surface.SetDrawColor(self.ChoiceColors[k])
                local ypos = 35+i*35
                surface.DrawRect(15,ypos,(w-30)*table.Count(v)/player.GetCount(),30)
                surface.SetDrawColor(74,72,72,255)
                surface.DrawOutlinedRect(15,ypos,w-30,30)
                local cx,cy = surface.GetTextSize(i..". "..k)
                surface.SetTextPos(30,ypos+cy/2)
                surface.DrawText(i..". "..k)
                i = i + 1
            end
            self:SetTall(50+i*35+10)
            surface.SetTextPos(15,h-20)
            surface.DrawText(string.FormattedTime(self.Duration - CurTime(),"%02i:%02i:%02i"))
        end,

        Setup = function(self,quest,choices,dura)
            self.Question = quest
            self.Choices = choices
            self.Duration = dura
            for k,v in pairs(choices) do
                self.ChoiceColors[k] = Color(math.random(50,200),math.random(50,200),math.random(50,200))
            end
        end,

        AddVote = function(self,ply,choice)
            if not IsValid(ply) or not choice or not self.Choices[choice] then return end
            self.Choices[choice][ply:SteamID()] = ply
        end,

        RemoveVote = function(self,ply,choice)
            if not IsValid(ply) or not choice or not self.Choices[choice] then return end
            self.Choices[choice][ply:SteamID()] = nil
        end,
    }

    vgui.Register("DVote",voteui,"DFrame")

    local ACTIVE_VOTE = {}
    local VOTE_PANEL = NULL
    net.Receive(netcreate,function()
        local tbl = net.ReadTable()
        ACTIVE_VOTE = tbl
        VOTE_PANEL = vgui.Create("DVote")
        VOTE_PANEL:Setup(tbl.Question,tbl.Choices,tbl.Duration)
    end)

    net.Receive(netend,function()
        local winners = net.ReadTable()
        if #winners == 1 then
            notification.AddLegacy("Most votes went to ''"..winners[1].."'",NOTIFY_GENERIC,5)
        else
            notification.AddLegacy("Most votes went to ''"..table.concat(winners,"'' and ''"),NOTIFY_GENERIC,5)
        end
        ACTIVE_VOTE = {}
        VOTE_PANEL:Remove()
        VOTE_PANEL = NULL
    end)

    net.Receive(netplvote,function()
        if ACTIVE_VOTE.Question and IsValid(VOTE_PANEL) then
            local ply = net.ReadEntity()
            local choice = net.ReadString()
            VOTE_PANEL:AddVote(ply,choice)
            notification.AddLegacy(ply:Nick().." voted "..choice,NOTIFY_GENERIC,5)
        end
    end)

    net.Receive(netplunvote,function()
        if ACTIVE_VOTE.Question and IsValid(VOTE_PANEL) then
            local ply = net.ReadEntity()
            local choice = net.ReadString()
            VOTE_PANEL:RemoveVote(ply,choice)
        end
    end)

end
